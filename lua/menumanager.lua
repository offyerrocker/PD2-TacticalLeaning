
TacticalLean = _G.TacticalLean or {}

TacticalLean.path = ModPath
TacticalLean.save_path = SavePath .. "tactical_lean.txt"
TacticalLean.default_localization_path = ModPath .. "localization/english.json"
TacticalLean.options_menu_path = ModPath .. "menu/options.json"
TacticalLean.STATE_WHITELIST = {
	carry = true,
	clean = true,
	standard = true,
	mask_off = true
}
TacticalLean.STATE_BLOCKED_STRINGS = { --disabled for now, would probably be more annoying than helpful
	downed = false and "hud_taclean_state_blocked_downed"
}
TacticalLean.input_cache = {} --only used for toggle mode
TacticalLean.output_cache = {} --only used for toggle mode

--you can play with the below variables if you like, but be careful!

TacticalLean.LEAN_DURATION = 0.2
TacticalLean.CHECK_COLLISION = false

TacticalLean.KEYBIND_LEAN_LEFT = "keybindid_taclean_left" --these are blt keybind ids
TacticalLean.KEYBIND_LEAN_RIGHT = "keybindid_taclean_right"

--these are playerstandard input names (table keys technically but not the keyboard kind)
TacticalLean.CONTROLLER_LEAN_LEFT = "btn_run_state"
TacticalLean.CONTROLLER_LEAN_RIGHT = "btn_meleet_state"
--that typo is not on my side

TacticalLean.settings = {
	lean_distance = 30, --in cm
	lean_angle = 10, --in degrees
	toggle_lean = false,
	controller_mode = false,
	controller_auto_unlean = false
}

TacticalLean.lean_direction = false 
--can be "left" or "right" or boolean;
--describes the direction of the player's current lean, or if exiting lean, their prior lean state as the lean returns to 0

TacticalLean.lean_lerp = 0 
--number between 0 and 1, inclusive
--describes the percentage state of the current lean (eg 1 is fully leaning, 0 or false/nil is not leaning, 0.5 is halfway midlean)
--this number is adjusted as the lean updates

TacticalLean.exiting_lean = false
--boolean
--describes whether or not the player is exiting a lean



--==================== SETTINGS =====================

--returns the player's lean distance setting
function TacticalLean:GetLeanDistance()
	return self.settings.lean_distance
end

--returns the player's lean angle setting
function TacticalLean:GetLeanAngle(lr)
	local lean_lr = 0
	if lr == "left" then
		lean_lr = - self.settings.lean_angle
	elseif lr == "right" then
		lean_lr = self.settings.lean_angle
	end
	return lean_lr
end

--returns the time it takes for one lean action to complete
function TacticalLean:GetLeanDuration()
	return self.LEAN_DURATION
end

--returns whether or not collision checking for leaning is enabled
function TacticalLean:IsCollisionCheckEnabled()
	return self.CHECK_COLLISION
end

--returns whether or not the user setting for toggle lean is enabled
function TacticalLean:IsToggleModeEnabled()
	return self.settings.toggle_lean
end

--returns whether or not the user setting for controller mode is enabled
function TacticalLean:IsControllerModeEnabled()
	return self.settings.controller_mode
end

--returns whether or not the user setting for controller auto-un-lean is enabled
function TacticalLean:IsControllerAutoUnleanEnabled()
	return self.settings.controller_auto_unlean
end



--==================== LEANING =====================

--returns the direction ("left" or "right") of the current lean
function TacticalLean:GetLeanDirection()
	return self.lean_direction
end

--sets the direction ("left" or "right" or false) of the current lean
function TacticalLean:SetLeanDirection(lr)
	self.lean_direction = lr
end

--returns the progress of the current lean
function TacticalLean:GetLeanLerp()
	return self.lean_lerp
end

--sets the progress of the current lean
function TacticalLean:SetLeanLerp(f)
	self.lean_lerp = f
end

--returns the direction of the lean, if in the process of exiting a lean
function TacticalLean:IsExitingLean()
	return self.exiting_lean
end

--begin the process of leaning in a given direction, after some state and sanity checks
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
	if state:running() or state:in_air() then 
		--don't show a hint, too annoying
		return
	end
	local state_name = movement_ext:current_state_name()
	if not self.STATE_WHITELIST[state_name] then 
		local blocked_str = self.STATE_BLOCKED_STRINGS[state_name]
		if blocked_str then 
			managers.hud:show_hint({text = managers.localization:text(blocked_str)})
		end
		
		return
	end
	
	if self:IsCollisionCheckEnabled() then 
		if self:RaycastCheck() then 
--		managers.hud:show_hint({text = managers.localization:text("hud_taclean_state_blocked_generic")})
			return
		end
	end
	
	if self:IsToggleModeEnabled() and lr and self:GetLeanDirection() == lr then
		TacticalLean:StopLean()
		return
	end
	self:SetLeanDirection(lr)
end

--reset some lean-related variables and start lean exit process
function TacticalLean:StopLean()
	if not self:IsExitingLean() then
		self.exiting_lean = self:GetLeanDirection()
		
		--for toggle mode only
		self.input_cache.left_input = false
		self.input_cache.right_input = false
		self.output_cache.left_input = false
		self.output_cache.right_input = false
	end
end

--reset final lean-related variables on lean exit completed
function TacticalLean:OnLeanStopped()
	self:SetLeanDirection(false)
	self.exiting_lean = false
	self:SetLeanLerp(0)
end

--perform raycheck in the given direction to see if leaning would result in world collision; returns ray if collision is present
function TacticalLean:RaycastCheck(lr)
	local player = managers.player:local_player()
	
	local my_pos = player:camera():position()
	local raw_headrot = player:camera():rotation()
--	local raw_headrot = player:movement():m_head_rot()
	local headrot = Vector3()
	
	local check_distance_lerp = self:GetLeanLerp()
	
	headrot = raw_headrot:x() * check_distance_lerp * self:GetLeanDistance() * math.sign(self:GetLeanAngle(lr))
	
	local new_pos = Vector3()
	mvector3.set(new_pos,my_pos)
	mvector3.add(new_pos,headrot)
	
	local ray = World:raycast("ray",my_pos,new_pos,"slot_mask",managers.slot:get_mask("world_geometry"))

	return ray
end



--==================== I/O =====================

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
	local file = io.open(self.save_path,"w+")
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end
end



--================= LOCALIZATION ===============

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_TacticalLean", function( loc )
	if not BeardLib then 
		loc:load_localization_file(TacticalLean.default_localization_path)
	end
end)



--==================== MENU ====================

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
	
	--due to adding the keybind via mod.txt, these callbacks are no longer used
	MenuCallbackHandler.taclean_keybind_func_left = function(self)
--		if TacticalLean:IsToggleModeEnabled() then
--			TacticalLean:StartLean("left")
--		end
	end
	MenuCallbackHandler.taclean_keybind_func_right = function(self)
--		if TacticalLean:IsToggleModeEnabled() then
--			TacticalLean:StartLean("right")
--		end
	end
	
	MenuCallbackHandler.callback_taclean_toggle_controller_mode = function(self,item)
		local value = item:value() == "on"
		TacticalLean.settings.controller_mode = value
		TacticalLean:Save()
	end
	MenuCallbackHandler.callback_taclean_toggle_autounlean = function(self,item)
		local value = item:value() == "on"
		TacticalLean.settings.controller_auto_unlean = value
		TacticalLean:Save()
	end
	
	MenuCallbackHandler.callback_taclean_close = function(this)
		TacticalLean:Save()
	end
	TacticalLean:Load()
	MenuHelper:LoadFromJsonFile(TacticalLean.options_menu_path, TacticalLean, TacticalLean.settings)

	HoldTheKey:Add_Keybind(TacticalLean.KEYBIND_LEAN_LEFT)
	HoldTheKey:Add_Keybind(TacticalLean.KEYBIND_LEAN_RIGHT)

end)