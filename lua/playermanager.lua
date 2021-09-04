if _G.IS_VR then 
	return
end

Hooks:PostHook(PlayerManager,"update","PlayerManagerUpdate_TacticalLean",function(self,_t,dt)
	local player = self:local_player()
	if not alive(player) then 
		return
	end
	local t = Application:time()
	--local __t = string.format("%0.2f",t)
	
	local current_lean = TacticalLean:GetLeanDirection()
	
	local left_input,right_input 
	if TacticalLean:IsControllerModeEnabled() then
		local state = player:movement():current_state()
		if state:in_steelsight() then 
			local all_input = state:_get_input(_t,dt,Application:paused())
			
			left_input = all_input[TacticalLean.CONTROLLER_LEAN_LEFT]
			right_input = all_input[TacticalLean.CONTROLLER_LEAN_RIGHT]
		end
	else
		left_input = HoldTheKey:Keybind_Held(TacticalLean.KEYBIND_LEAN_LEFT)
		right_input = HoldTheKey:Keybind_Held(TacticalLean.KEYBIND_LEAN_RIGHT)
	end
	

	if TacticalLean:IsToggleModeEnabled() then
		local input_cache = TacticalLean.input_cache
		local output_cache = TacticalLean.output_cache
		local left_cached = input_cache.left_input
		local right_cached = input_cache.right_input
		
		input_cache.left_input = left_input
		input_cache.right_input = right_input
		
		if not left_cached then 
			if left_input then 
				--on first left press...
				if current_lean then 
					--...while leaning, stop leaning
					TacticalLean:StopLean() --this also clears input/output caches
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
					TacticalLean:StopLean() --this also clears input/output caches
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
	
	
	local lean_duration = TacticalLean:GetLeanDuration()
	
	local current_lerp = TacticalLean:GetLeanLerp()
	if TacticalLean:IsExitingLean() then
		if current_lerp > 0 then 
			TacticalLean:SetLeanLerp(math.max(current_lerp - (dt / lean_duration),0))
--			Console:SetTrackerValue("trackerc","Exiting " .. __t)
		else
--			Console:SetTrackerValue("trackerc","Done exiting " .. __t)
			TacticalLean:OnLeanStopped()
		end
	elseif current_lean then
		if current_lerp < 1 then
			TacticalLean:SetLeanLerp(math.min(current_lerp + (dt / lean_duration),1))
--			Console:SetTrackerValue("trackerc","Starting " .. __t)
--		else
--			Console:SetTrackerValue("trackerc","Holding " .. __t)
		end
	end
--	Console:SetTrackerValue("trackerb",string.format("%0.2f / %0.2f",TacticalLean:GetLeanLerp() or 0,lean_duration))

	
	local new_lean_direction
	if left_input then
		new_lean_direction = "left"
		if current_lean ~= new_lean_direction then
			TacticalLean:StartLean(new_lean_direction)
		end
	end
	if right_input then
		new_lean_direction = "right"
		if current_lean ~= new_lean_direction then
			TacticalLean:StartLean(new_lean_direction)
		end
	end
	local exiting_lean = TacticalLean:IsExitingLean()
	if not new_lean_direction and current_lean and not exiting_lean then
		TacticalLean:StopLean()
	end
--	Console:SetTrackerValue("trackere","leaning " .. tostring(new_lean_direction) .. ", exiting_lean " .. tostring(TacticalLean:IsExitingLean()))
end)