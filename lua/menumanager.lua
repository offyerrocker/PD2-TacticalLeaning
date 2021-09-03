if _G.IS_VR then 
	return
end

--[[

managers.player:local_player():camera():camera_unit():base():set_pitch(90)

--]]

TacticalLean = _G.TacticalLean or {}

TacticalLean.path = ModPath
TacticalLean.save_path = SavePath .. "tactical_lean.txt"
TacticalLean.default_localization_path = ModPath .. "localization/english.json"
TacticalLean.options_menu_path = ModPath .. "menu/options.json"
TacticalLean.KEYBIND_LEAN_LEFT = "keybindid_taclean_left"
TacticalLean.KEYBIND_LEAN_RIGHT = "keybindid_taclean_right"
TacticalLean.LEAN_DURATION = 0.2
TacticalLean.CHECK_COLLISION = true

TacticalLean.lean_timer = 0
TacticalLean.current_lean = false
TacticalLean.exiting_lean = false
TacticalLean.STATE_WHITELIST = {
	carry = true,
	clean = true,
	standard = true,
	mask_off = true
}
TacticalLean.STATE_BLOCKED_STRINGS = {
	downed = "hud_taclean_state_blocked_downed"
}

TacticalLean.settings = {
	lean_distance = 30,
	toggle_lean = false,
	lean_angle = 10
}

function TacticalLean:GetTimer()
	return self.lean_timer or 0
end

function TacticalLean:SetTimer(t)
	self.lean_timer = t
end

function TacticalLean:GetLeanDistance()
	return self.settings.lean_distance
end

function TacticalLean:GetLeanAngle(lr)
	local lean_lr = 0
	if lr == "left" then
		lean_lr = - self.settings.lean_angle
	elseif lr == "right" then
		lean_lr = self.settings.lean_angle
	end
	return lean_lr
end

function TacticalLean:GetCurrentLean()
	return self.current_lean
end

function TacticalLean:SetCurrentLean(lr)
	self.current_lean = lr
end

function TacticalLean:GetLeanDuration()
	return self.LEAN_DURATION
end

function TacticalLean:IsCollisionCheckEnabled()
	return self.CHECK_COLLISION
end

function TacticalLean:IsExitingLean()
	return self.exiting_lean
end

function TacticalLean:IsToggleModeEnabled()
	return self.settings.toggle_lean
end

function TacticalLean:StartLean(lr)
	if self:IsExitingLean() then 
		return
	end
	local pm = managers.player
	local player = managers.player:local_player() 
	if not alive(player) then 
		return
	end
	local movement_ext = player:movement()
	local state = movement_ext:current_state()
	if state:running() then 
		--don't show a hint, too annoying
		return
	end
	local state_name = player:current_state()
	if self.STATE_WHITELIST[state_name] then 
		local blocked_str = self.STATE_BLOCKED_STRINGS[state_name]
		if blocked_str then 
			managers.hud:show_hint({text = managers.localization:text(blocked_str)})
		end
		
		return
	end
	--todo raycast check for collision
	if self:IsToggleModeEnabled() and lr and self:GetCurrentLean() == lr then
		TacLean:StopLean()
		return
	end
	self:SetCurrentLean(lr)
	self:SetTimer(Application:time())
--	self.lean_remaining = self:GetLeanAngle(lr)
	--self:SetLeanStanceTransition()
end

function TacticalLean:StopLean()
	if not self:IsExitingLean() then
		--prevent anim glitching by repeatedly stopping lean without starting lean in between
		self:SetTimer(Application:time())
		self.exiting_lean = self:GetCurrentLean()
--		self:SetLeanStanceTransition(true)
	end
--	self.lean_remaining = 0
end


function TacticalLean:OnLeanStopped()
--	self.lean_remaining = 0
	self:SetCurrentLean(false)
	self.exiting_lean = false
	self.lean_timer = 0
end

function TacticalLean:SetLeanStanceTransition()
	local player = managers.player:local_player()
	if alive(player) then
--		player:camera():camera_unit():base():start_lean_transition_stance(exiting) --experimental transition fix, promising but broken as hell
	end
end

function TacticalLean:RaycastCheck(lr)
--[[
	local my_pos = player:camera():position()	
	local raw_headrot = player:movement():m_head_rot()
	local headrot = Vector3()
	
	headrot = (raw_headrot:x() * (self:GetLeanDistance() * 1) * (self:GetLeanAngle(lr) < 0 and -1 or 1))
	
	local new_pos = Vector3()
	mvector3.set(new_pos,my_pos)
	mvector3.add(new_pos,headrot)
	
	local ray = World:raycast("ray",my_pos,new_pos,"slot_mask",managers.slot:get_mask("world_geometry"))
	if ray then
--		managers.hud:show_hint({text = managers.localization:text("hud_taclean_state_blocked_generic")})
		return
	end
	--]]
end

function TacticalLean:Load()
	local file = io.open(self.save_path, "r")
	if (file) then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.settings[k] = v
		end
		file:close()
	else
		self:Save()
	end
end

function TacticalLean:Save()
	self:SetTimer(0) --this global tends to glitch out so here's a free "reset" button
	local file = io.open(self.save_path,"w+")
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end
end



Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_TacticalLean", function( loc )
	if not BeardLib then 
		loc:load_localization_file(TacticalLean.default_localization_path)
	end
end)


Hooks:Add( "MenuManagerInitialize", "MenuManagerInitialize_TacticalLean", function(menu_manager)
	MenuCallbackHandler.callback_taclean_toggle_lean = function(self,item)
		local value = item:value() == "on"
		TacticalLean.settings.toggle_lean = value
		TacticalLean:Save()
	end
	MenuCallbackHandler.callback_taclean_slider_angle = function(self,item)
		TacticalLean.settings.lean_angle = tonumber(item:value())
		TacticalLean:Save()
	end
	MenuCallbackHandler.callback_taclean_slider_distance = function(self,item)
		TacticalLean.settings.lean_distance = tonumber(item:value())
		TacticalLean:Save()
	end	
	MenuCallbackHandler.taclean_keybind_func_left = function(self)
		if TacticalLean:IsToggleModeEnabled() then
			TacticalLean:StartLean("left")
		end
	end
	MenuCallbackHandler.taclean_keybind_func_right = function(self)
		if TacticalLean:IsToggleModeEnabled() then
			TacticalLean:StartLean("right")
		end
	end
	MenuCallbackHandler.callback_taclean_close = function(this)
		TacticalLean:Save()
	end
	TacticalLean:Load()
	MenuHelper:LoadFromJsonFile(TacticalLean.options_menu_path, TacticalLean, TacticalLean.settings)

	HoldTheKey:Add_Keybind("keybindid_taclean_left")
	HoldTheKey:Add_Keybind("keybindid_taclean_right")

end)

do return end

function TacLean:start_lean(lr)
	if TacLean.exiting_lean then --or (TacLean.current_lean and lr == TacLean.current_lean) then
		return
	end
	local player = managers.player and managers.player:player_unit()
	if not player then
		return
	end
	if player:movement():current_state():running() then
--		managers.hud:show_hint({text = "Cannot lean while running!"}) --hint is probably too annoying
		return
	end
	local state = managers.player:current_state() 
	--forbidden: 
		--freefall, parachuting, driving, bleedout, incap (cloaker/taser down), taser, cuffed, dead/custody 
	--well i ended up doing a whitelist for states anyway so whatever
	
	if state and not state_whitelist[state] then
		managers.hud:show_hint({text = "Cannot lean in " .. tostring(state) .. " state!"})
		return
	end

	
	TacLean.exiting_lean = false
	if TacLean.settings.toggle_lean and lr and TacLean.current_lean == lr then --
		TacLean:stop_lean()
		return
	end
	TacLean:anim_t(Application:time())
	TacLean.current_lean = lr
	local lean_lr = TacLean:get_angle(lr)
	TacticalLean.lean_tilt = lean_lr
	TacticalLean:update_lean_stance()
end