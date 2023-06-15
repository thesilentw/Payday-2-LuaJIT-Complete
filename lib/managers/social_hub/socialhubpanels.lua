local MOUSEOVER_COLOR = tweak_data.screen_colors.button_stage_2
local BUTTON_COLOR = tweak_data.screen_colors.button_stage_3
SocialHubUserItem = SocialHubUserItem or class(ListItem)
SocialHubUserItem.type = {
	default = {
		margin = 5,
		layer = 100,
		font = tweak_data.menu.pd2_medium_font,
		font_size = tweak_data.menu.pd2_medium_font_size
	}
}

function SocialHubUserItem:init(parent, data)
	self.data = data or {}
	self.type = data.type or "default"
	self.type_config = SocialHubUserItem.type[self.type]

	SocialHubUserItem.super.init(self, parent, {
		input = false,
		h = self.type_config.font_size + self.type_config.margin * 4
	})

	self._content_panel = self._panel:panel({
		x = self.type_config.margin,
		w = parent:w() - self.type_config.margin * 2
	})
	self._select_panel = self._panel:panel({
		visible = false
	})
	self._unselected_color = 0.9

	self:setup_panel()
	self:set_selected(false)
	self:set_item_selected(1)
end

function SocialHubUserItem:setup_panel()
	BoxGuiObject:new(self._select_panel, {
		layer = 100,
		sides = {
			2,
			2,
			2,
			2
		}
	})

	self.friend_data = managers.socialhub:get_user(self.data.id)

	if not self.friend_data then
		return
	end

	self._unselected_color = self.friend_data.state == "offline" and 0.7 or self._unselected_color
	local left_y_placer = self.type_config.margin
	local icon_texture = self.friend_data.platform == Idstring("STEAM") and "guis/dlcs/shub/textures/steam_player_icon" or self.friend_data.platform == Idstring("EPIC") and "guis/dlcs/shub/textures/epic_player_icon" or "guis/dlcs/shub/textures/generic_player_icon"
	local icon = self._content_panel:bitmap({
		h = 32,
		w = 32,
		layer = 100,
		texture = icon_texture,
		x = left_y_placer,
		y = self._content_panel:h() / 2 - 16
	})
	left_y_placer = icon:right() + self.type_config.margin
	local text_data = clone(self.type_config)
	text_data.text = self.friend_data.name
	self._name_text = self._content_panel:text(text_data)

	ExtendedPanel.make_fine_text(self._name_text)
	self._name_text:set_center_y(self._content_panel:center_y())
	self._name_text:set_x(left_y_placer)

	left_y_placer = self._name_text:right() + self.type_config.margin
	self._right_side_panel = self._content_panel:panel({})

	if self.data.right_display == "status" then
		text_data.text = utf8.to_upper(self.friend_data.state)
		self._state_text = self._right_side_panel:text(text_data)

		ExtendedPanel.make_fine_text(self._state_text)
		self._state_text:set_center_y(self._right_side_panel:center_y())
		self._state_text:set_right(self._right_side_panel:right() - self.type_config.margin)
	elseif self.data.right_display == "icon" then
		local display_icon = self._right_side_panel:bitmap({
			layer = 100,
			texture = self.data.right_display_icon,
			w = self._right_side_panel:h() - 10,
			h = self._right_side_panel:h() - 10
		})

		display_icon:set_right(self._right_side_panel:right() - 5)
		display_icon:set_center_y(self._right_side_panel:center_y())
	end

	self._buttons_panel = self._select_panel:panel({
		layer = 100
	})
	self._buttons = {}
	local right_placer_x = self._buttons_panel:right()

	for index, item in ipairs(self.data.buttons or {}) do
		local button = self._buttons_panel:panel({})

		button:rect({
			name = "bg",
			visible = false,
			alpha = 0.3,
			layer = 100,
			color = MOUSEOVER_COLOR
		})

		local text = button:text({
			name = "text",
			layer = 100,
			font = tweak_data.menu.pd2_medium_font,
			font_size = tweak_data.menu.pd2_medium_font_size,
			color = BUTTON_COLOR,
			text = item.text or "UNFRIEND"
		})

		ExtendedPanel.make_fine_text(text)
		button:set_w(text:w() + 10)
		text:set_center_y(button:center_y())
		text:set_center_x(button:center_x())
		button:set_right(right_placer_x)

		right_placer_x = button:left()

		table.insert(self._buttons, button)
	end
end

function SocialHubUserItem:_selected_changed(state)
	SocialHubUserItem.super._selected_changed(self, state)

	if state then
		self:set_item_selected(1)
	end

	if alive(self._right_side_panel) then
		self._right_side_panel:set_visible(not state)
	end

	if alive(self._name_text) then
		self._name_text:set_alpha(state and 1 or self._unselected_color)
	end
end

function SocialHubUserItem:mouse_moved(button, x, y)
	for index, item in ipairs(self._buttons) do
		if alive(item) and item:inside(x, y) then
			self:set_item_selected(index)

			return true, "link"
		end
	end
end

function SocialHubUserItem:mouse_pressed(button, x, y)
	for index, item in ipairs(self._buttons) do
		if alive(item) and item:inside(x, y) then
			self.data.buttons[index].press_callback(self.data.id)
		end
	end
end

function SocialHubUserItem:move_left()
	self:move_button_selection(1)
end

function SocialHubUserItem:move_right()
	self:move_button_selection(-1)
end

function SocialHubUserItem:confirm_pressed()
	if #self._buttons > 0 then
		self.data.buttons[self._selected_index].press_callback(self.data.id)
	end
end

function SocialHubUserItem:move_button_selection(move)
	if #self._buttons > 0 then
		local new_index = self._selected_index + move
		new_index = math.clamp(new_index, 1, #self._buttons)

		self:set_item_selected(new_index)
	end
end

function SocialHubUserItem:set_item_selected(selected_index)
	if self._selected_index == selected_index then
		return
	end

	self._selected_index = selected_index

	for index, item in ipairs(self._buttons or {}) do
		local bg_state = index == selected_index and true or false
		local text_color = index == selected_index and MOUSEOVER_COLOR or BUTTON_COLOR
		local bg = item:child("bg")
		local text = item:child("text")

		bg:set_visible(bg_state)
		text:set_color(text_color)
	end
end

function SocialHubUserItem:get_status_prio()
	if self.friend_data.state == "offline" then
		return 5
	elseif self.friend_data.state == "away" then
		return 4
	elseif self.friend_data.state == "snooze" then
		return 3
	elseif self.friend_data.state == "online" then
		return 1
	end

	return 4
end

function SocialHubUserItem:get_name()
	return self.friend_data.name or ""
end

SocialHubLobbyItem = SocialHubLobbyItem or class(ListItem)

function SocialHubLobbyItem:init(parent, data)
	self.data = data or {}

	SocialHubLobbyItem.super.init(self, parent, {
		h = 65,
		input = false
	})

	self._content_panel = self._panel:panel({
		x = 5,
		layer = 100,
		w = parent:w() - 10
	})
	self._select_panel = self._panel:panel({
		layer = 100,
		visible = false
	})
	self._unselected_alpha = 0.9

	self:setup_panel()
	self:set_item_selected(2)
end

function SocialHubLobbyItem:setup_panel()
	BoxGuiObject:new(self._select_panel, {
		layer = 100,
		sides = {
			2,
			2,
			2,
			2
		}
	})

	local left_panel = self._content_panel:panel({
		layer = 100,
		w = self._content_panel:w() / 2
	})
	local left_x_placer = 20
	local top_y_placer = left_panel:h() / 4
	local bottom_y_placer = left_panel:h() / 4 * 3
	local heist_mode_icon = left_panel:bitmap({
		layer = 100,
		visible = false,
		color = Color.white,
		texture = "guis/textures/pd2/cn_playstyle_stealth" or "guis/textures/pd2/cn_playstyle_loud"
	})

	heist_mode_icon:set_center_x(left_x_placer)
	heist_mode_icon:set_center_y(top_y_placer)

	local lobby_marker = left_panel:bitmap({
		texture = "guis/textures/pd2/crimenet_marker_join",
		layer = 100,
		color = Color.white,
		texture_rect = {
			0,
			0,
			31,
			37
		}
	})

	lobby_marker:set_center_x(left_x_placer)
	lobby_marker:set_center_y(bottom_y_placer)

	for i = 1, self.data.NUM_PLAYERS or 4 do
		local peer_icon = left_panel:bitmap({
			texture = "guis/textures/pd2/crimenet_marker_peerflag",
			visible = true,
			layer = 100,
			color = Color.white,
			x = lobby_marker:x() + 3 + (i - 1) * 6,
			y = lobby_marker:y() + 8
		})
	end

	left_x_placer = lobby_marker:right() + 5
	self.data.JOB_ID = tonumber(self.data.JOB_ID)
	local job_name = tweak_data.narrative:get_job_name_from_index(self.data.JOB_ID)
	local job_data = tweak_data.narrative:job_data(job_name)
	local heist_name = left_panel:text({
		layer = 100,
		font = tweak_data.menu.pd2_medium_font,
		font_size = tweak_data.menu.pd2_medium_font_size,
		text = self.data.JOB_ID and job_data and managers.localization:text(job_data.name_id) or "UNKNOWN",
		x = left_x_placer
	})

	ExtendedPanel.make_fine_text(heist_name)
	heist_name:set_center_y(bottom_y_placer)

	local player_name = left_panel:text({
		layer = 100,
		font = tweak_data.menu.pd2_medium_font,
		font_size = tweak_data.menu.pd2_medium_font_size,
		text = self.data.OWNER_NAME or "",
		x = left_x_placer
	})

	ExtendedPanel.make_fine_text(player_name)
	player_name:set_center_y(top_y_placer)

	left_x_placer = heist_name:right() + 5

	for i = 1, self.data.DIFFICULTY and self.data.DIFFICULTY - 2 or 0 do
		local index = left_panel
		local skull_icon = left_panel.bitmap
		local item = {
			texture = "guis/textures/pd2/cn_miniskull",
			layer = 100
		}

		if true or not Color.black then
			slot18 = tweak_data.screen_colors.risk
		end

		item.color = slot18
		item.x = left_x_placer + 3 + (i - 1) * 11
		local skull_icon = slot15(index, item)

		skull_icon:set_center_y(bottom_y_placer)
	end

	local right_panel = self._content_panel:panel({
		x = self._content_panel:w() / 2,
		w = self._content_panel:w() / 2
	})
	self._lobby_setting_text = right_panel:text({
		text = "FRIENDS ONLY",
		visible = false,
		layer = 100,
		font = tweak_data.menu.pd2_medium_font,
		font_size = tweak_data.menu.pd2_medium_font_size
	})

	ExtendedPanel.make_fine_text(self._lobby_setting_text)
	self._lobby_setting_text:set_center_y(right_panel:center_y())
	self._lobby_setting_text:set_right(right_panel:w() - 5)

	self._buttons_panel = self._select_panel:panel({
		layer = 100
	})
	self._buttons = {}
	local right_placer_x = self._buttons_panel:right()

	for index, item in ipairs(self.data.buttons or {}) do
		local button = self._buttons_panel:panel({
			layer = 100
		})

		button:rect({
			name = "bg",
			visible = false,
			alpha = 0.3,
			layer = 100,
			color = MOUSEOVER_COLOR
		})

		local text = button:text({
			name = "text",
			layer = 100,
			font = tweak_data.menu.pd2_medium_font,
			font_size = tweak_data.menu.pd2_medium_font_size,
			color = BUTTON_COLOR,
			text = item.text or "UNFRIEND"
		})

		ExtendedPanel.make_fine_text(text)
		button:set_w(text:w() + 10)
		text:set_center_y(button:center_y())
		text:set_center_x(button:center_x())
		button:set_right(right_placer_x)

		right_placer_x = button:left()

		table.insert(self._buttons, button)
	end
end

function SocialHubLobbyItem:_selected_changed(state)
	SocialHubLobbyItem.super._selected_changed(self, state)
	self:set_item_selected(1)
end

function SocialHubLobbyItem:set_item_selected(selected_index)
	if self._selected_index == selected_index then
		return
	end

	self._selected_index = selected_index

	for index, item in ipairs(self._buttons) do
		local bg_state = index == selected_index and true or false
		local text_color = index == selected_index and MOUSEOVER_COLOR or BUTTON_COLOR
		local bg = item:child("bg")
		local text = item:child("text")

		bg:set_visible(bg_state)
		text:set_color(text_color)
	end
end

function SocialHubLobbyItem:mouse_moved(button, x, y)
	for index, item in ipairs(self._buttons) do
		if alive(item) and item:inside(x, y) then
			self:set_item_selected(index)

			return true, "link"
		end
	end
end

function SocialHubLobbyItem:mouse_pressed(button, x, y)
	for index, item in ipairs(self._buttons) do
		if alive(item) and item:inside(x, y) then
			self.data.buttons[index].press_callback(self.data.LOBBYID)
		end
	end
end

function SocialHubLobbyItem:move_left()
	self:move_button_selection(1)
end

function SocialHubLobbyItem:move_right()
	self:move_button_selection(-1)
end

function SocialHubLobbyItem:confirm_pressed()
	if #self._buttons > 0 then
		self.data.buttons[self._selected_index].press_callback(self.data.LOBBYID)
	end
end

function SocialHubLobbyItem:move_button_selection(move)
	if #self._buttons > 0 then
		local new_index = self._selected_index + move
		new_index = math.clamp(new_index, 1, #self._buttons)

		self:set_item_selected(new_index)
	end
end

SocialHubUserCategoryHeader = SocialHubUserCategoryHeader or class(ListItem)

function SocialHubUserCategoryHeader:init(parent, data)
	SocialHubUserCategoryHeader.super.init(self, parent, {
		input = false,
		h = tweak_data.menu.pd2_medium_font_size + 12,
		w = parent:w()
	})

	self._content_panel = self._panel:panel()
	self._bg = self._content_panel:rect({
		alpha = 0.1,
		layer = 100,
		color = BUTTON_COLOR
	})
	self.data = data
	local text = self._content_panel:text({
		name = "text",
		x = 5,
		layer = 100,
		font = tweak_data.menu.pd2_medium_font,
		font_size = tweak_data.menu.pd2_medium_font_size,
		color = BUTTON_COLOR,
		text = self.data.text
	})

	ExtendedPanel.make_fine_text(text)
	text:set_center_y(self._content_panel:center_y())

	local icon = self._content_panel:bitmap({
		texture = "guis/textures/scrollarrow",
		h = 24,
		w = 24,
		layer = 100,
		color = BUTTON_COLOR
	})

	icon:set_center_y(self._content_panel:center_y())
	icon:set_right(self._content_panel:right() - 5)
end

function SocialHubUserCategoryHeader:_selected_changed(state)
	SocialHubUserCategoryHeader.super._selected_changed(self, state)
	self._bg:set_alpha(state and 0.4 or 0.1)
end

function SocialHubUserCategoryHeader:mouse_moved(button, x, y)
	if self._content_panel:inside(x, y) then
		return true, "link"
	end
end

function SocialHubUserCategoryHeader:mouse_pressed(button, x, y)
	if self._content_panel:inside(x, y) then
		self.data.press_callback()
	end
end

function SocialHubUserCategoryHeader:confirm_pressed()
	self.data.press_callback()
end

SocialHubUserSeparator = SocialHubUserSeparator or class(ListItem)

function SocialHubUserSeparator:init(parent, data)
	SocialHubUserSeparator.super.init(self, parent, {
		h = 2,
		input = false,
		w = parent:w()
	})

	self._content_panel = self._panel:panel()

	self._content_panel:rect({
		alpha = 0.5,
		color = Color.white
	})
end

function SocialHubUserSeparator:skip_selection()
	return true
end

function SocialHubUserSeparator:get_status_prio()
	return 2.5
end

SocialHubTextHeader = SocialHubTextHeader or class(ListItem)

function SocialHubTextHeader:init(parent, data)
	SocialHubTextHeader.super.init(self, parent, {
		input = false,
		h = tweak_data.menu.pd2_medium_font_size,
		w = parent:w()
	})

	self._content_panel = self._panel:panel()
	local text = self._content_panel:text({
		name = "text",
		layer = 100,
		font = tweak_data.menu.pd2_medium_font,
		font_size = tweak_data.menu.pd2_medium_font_size,
		color = Color.white,
		text = data.text
	})

	ExtendedPanel.make_fine_text(text)
	text:set_center_x(self._content_panel:center_x())
end

function SocialHubTextHeader:skip_selection()
	return true
end

SocialHubUserSearchBox = SocialHubUserSearchBox or class(ListItem)

function SocialHubUserSearchBox:init(parent_panel, data)
	self._searchbox = SearchBoxGuiObject:new(parent_panel, data.ws)

	self._searchbox:register_callback(callback(data.caller, data.caller, data.callback))
	self._searchbox:register_disconnect_callback(callback(data.caller, data.caller, data.callback_disconnect))
	self._searchbox.panel:set_center_x(parent_panel:center_x())
end

function SocialHubUserSearchBox:search_box()
	return self._searchbox
end
