
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
TacticalLean.DIRECTION_RIGHT = "right"
TacticalLean.DIRECTION_LEFT = "left"
TacticalLean.input_cache = {} --only used for toggle mode
TacticalLean.output_cache = {} --only used for toggle mode

--you can play with the below variables if you like, but be careful!

TacticalLean.LEAN_DURATION = 0.10
TacticalLean.EXIT_DURATION = 0.15
TacticalLean.CHECK_COLLISION = false --not functional atm

TacticalLean.previous_raycast_from = nil --will contain a Vector3 representing the position of the player's camera/head in the world, whether leaning or not

TacticalLean.KEYBIND_LEAN_LEFT = "keybindid_taclean_left" --these are blt keybind ids
TacticalLean.KEYBIND_LEAN_RIGHT = "keybindid_taclean_right"

--these are no longer used
--also that typo in "btn_meleet_state" is not mine
TacticalLean.CONTROLLER_LEAN_LEFT = "btn_run_state"
TacticalLean.CONTROLLER_LEAN_RIGHT = "btn_meleet_state"

TacticalLean.settings = {
	lean_distance = 30, --in cm
	lean_angle = 10, --in degrees
	toggle_lean = false,
	controller_mode = false,
	controller_auto_unlean = false,
	compatibility_mode_playermanager = false,
	controller_bind_lean_left = "run",
	controller_bind_lean_right = "melee"
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

--returns the time it takes for one lean start to complete
function TacticalLean:GetLeanDuration()
	return self.LEAN_DURATION
end

--returns the time it takes for one lean exit to complete
function TacticalLean:GetExitDuration()
	return self.EXIT_DURATION
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

function TacticalLean:IsPMUpdateCompatibilityModeEnabled()
	return self.settings.compatibility_mode_playermanager
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
	
	--todo remove this if it's redundant
	if self:IsToggleModeEnabled() and lr and self:GetLeanDirection() == lr then
--		TacticalLean:StopLean()
--		return
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
	self.input_cache.left_input = false
	self.input_cache.right_input = false
	self.output_cache.left_input = false
	self.output_cache.right_input = false
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

function TacticalLean:GetControllerBindLeanLeft()
	return self.settings.controller_bind_lean_left
end

function TacticalLean:GetControllerBindLeanRight()
	return self.settings.controller_bind_lean_right
end

function TacticalLean:Update(_t,dt)

	local player = managers.player:local_player()
	if not alive(player) then 
		return
	end
	local state = player:movement():current_state()
	local t = Application:time()
	--local __t = string.format("%0.2f",t)
	
	local exiting_lean = self:IsExitingLean()
	local current_lean = self:GetLeanDirection()
	local lean_duration = self:GetLeanDuration()
	local exit_duration = self:GetExitDuration()
	local current_lerp = self:GetLeanLerp()
	local new_lean_direction = false
	local pressed_any
	local left_input,right_input 
	
	if exiting_lean then
		if current_lerp > 0 then 
			current_lerp = math.max(current_lerp - (dt / exit_duration),0)
			self:SetLeanLerp(current_lerp)
--			Console:SetTrackerValue("trackerc","Exiting " .. __t)
		end
		if current_lerp <= 0 then
--			Console:SetTrackerValue("trackerc","Done exiting " .. __t)
			self:OnLeanStopped()
			current_lean = false
			exiting_lean = false
		end
	end
	
	if state and not state:running() then 
		if not managers.hud._chat_focus then 
			if self:IsControllerModeEnabled() then
				if state:in_steelsight() then
					local controller = state._controller
					--this doesn't necessarily mean a literal controller/gamepad
					--it's just the wrapper for the current input device (M+KB, XBOX/PS controller, USB controller, DDR pad, etc.)
					
					right_input = controller:get_input_bool(self.settings.controller_bind_right)
					left_input = controller:get_input_bool(self.settings.controller_bind_left)
					
				--this causes 45deg sights not to activate while in ADS with controllers specifically for whatever reason
				--so we can't use that anymore
--					local all_input = state:_get_input(_t,dt,Application:paused())
--					left_input = all_input[self.CONTROLLER_LEAN_LEFT]
--					right_input = all_input[self.CONTROLLER_LEAN_RIGHT]
				end
			else
				left_input = HoldTheKey:Keybind_Held(self.KEYBIND_LEAN_LEFT)
				right_input = HoldTheKey:Keybind_Held(self.KEYBIND_LEAN_RIGHT)
			end
		end
		
		if self:IsToggleModeEnabled() then
			local input_cache = self.input_cache
			local output_cache = self.output_cache
			local left_cached = input_cache.left_input
			local right_cached = input_cache.right_input
			
			input_cache.left_input = left_input
			input_cache.right_input = right_input
			
			if not left_cached then 
				if left_input then 
					--on first left press...
					if current_lean then 
						--...while leaning, stop leaning
						self:StopLean() --this also clears input/output caches
						exiting_lean = true
					else
						--...while not leaning, start leaning
						output_cache.left_input = true
					end
				end
			else
				if left_input then 
					--if continuously held, do nothing
				else
					--if released, do nothing
				end
			end
			
			if not right_cached then 
				if right_input then 
					--on first right press...
					if current_lean then 
						--...while leaning, stop leaning
						self:StopLean() --this also clears input/output caches
					else
						--...while not leaning, start leaning
						output_cache.right_input = true
					end
				end
			else
				if right_input then 
					--if continuously held, do nothing
				else
					--if released, do nothing
				end
			end
			
			left_input = output_cache.left_input
			right_input = output_cache.right_input
		else
			--disable double-inputs
			if left_input and right_input then 
				left_input = false
				right_input = false
			end
		end
		
	--	Console:SetTrackerValue("trackerb",string.format("%0.2f / %0.2f",TacticalLean:GetLeanLerp() or 0,lean_duration))

		
		if left_input then
			pressed_any = true
			if current_lean ~= self.DIRECTION_LEFT then
				new_lean_direction = self.DIRECTION_LEFT
			end
		end
		if right_input then
			pressed_any = true
			if current_lean ~= self.DIRECTION_RIGHT then
				new_lean_direction = self.DIRECTION_RIGHT
			end
		end
		
		
		--refresh values in case input segment has changed desired lean direction
		if pressed_any then 
			if new_lean_direction then 
				--if user wants to switch lean sides, 
				if current_lean then 
					--...then stop leaning first
					self:StopLean()
					exiting_lean = true
				else
					--...and then start the new lean
					self:StartLean(new_lean_direction)
					current_lean = new_lean_direction
				end
			elseif exiting_lean then 
				--pressed same button to cancel exit; un-cancel!
				exiting_lean = false
				self.exiting_lean = false
			end
		elseif current_lean then
			--if no lean input, and currently leaning,
			--then stop leaning
			self:StopLean()
			exiting_lean = true
		end
	else
		self:StopLean()
	end
	
	
	--do start lean calculations
	if current_lean and not exiting_lean then
		if current_lerp < 1 then
			current_lerp = math.min(current_lerp + (dt / lean_duration),1)
			self:SetLeanLerp(current_lerp)
--			Console:SetTrackerValue("trackerc","Starting " .. __t)
--		else
--			Console:SetTrackerValue("trackerc","Holding " .. __t)
		end
	end
--	Console:SetTrackerValue("trackerd",string.format("%0.2f",current_lerp))
--	Console:SetTrackerValue("trackere","leaning " .. tostring(new_lean_direction) .. ", exiting_lean " .. tostring(TacticalLean:IsExitingLean()))
end

function TacticalLean:RemoveUpdators()
	Hooks:RemovePostHook("PlayerManagerUpdate_TacticalLean")
	if BeardLib then 
		BeardLib:RemoveUpdater("BeardLibUpdate_TacticalLean")
	end
	if managers.hud then 
		managers.hud:remove_updator("HUDManagerUpate_TacticalLean")
	end
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


Hooks:Add("BaseNetworkSessionOnLoadComplete","NetworkLoadComplete_TacticalLeaning",function() --PlayerManager_on_internal_load
	if TacticalLean:IsPMUpdateCompatibilityModeEnabled() then
		TacticalLean:RemoveUpdators()
		
		local pm = managers.player
		if pm then 
			pm:register_message(Message.OnWeaponSwitch, "onplayerweaponswitched_tacticallean",function()
				TacticalLean:StopLean()
			end)
		end
		--unhook just to be safe
		local cb = callback(TacticalLean,TacticalLean,"Update")
		if BeardLib then 
			BeardLib:AddUpdater("BeardLibUpdate_TacticalLean",cb)
		elseif managers.hud then 
			managers.hud:add_updator("HUDManagerUpate_TacticalLean",cb)
		end
	end
end)