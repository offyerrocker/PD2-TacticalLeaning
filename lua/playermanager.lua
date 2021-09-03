if _G.IS_VR then 
	return
end

Hooks:PostHook(PlayerManager,"update","PlayerManagerUpdate_TacticalLean",function(self,_t,dt)
	if not alive(self:local_player()) then 
		return
	end
	local t = Application:time()
	
	local lean_duration = TacticalLean:GetLeanDuration()
	local lean_timer = TacticalLean:GetTimer()
--	local lean_time_remaining = math.max(t - (lean_timer + lean_duration),0)
--	local lean_time_lerp = lean_time_remaining / lean_duration
	
	if t - lean_timer > lean_duration then 
		if TacticalLean:IsExitingLean() then 
			TacticalLean:OnLeanStopped()
		end
	end


	if TacticalLean:IsToggleModeEnabled() then
		return
	end
	
	local current_lean = TacticalLean:GetCurrentLean()
	local new_lean_direction
	if HoldTheKey:Keybind_Held(TacticalLean.KEYBIND_LEAN_LEFT)then
		new_lean_direction = "left"
		if current_lean ~= new_lean_direction then
			TacticalLean:StartLean(new_lean_direction)
		end
	end
	if HoldTheKey:Keybind_Held(TacticalLean.KEYBIND_LEAN_RIGHT) then
		new_lean_direction = "right"
		if current_lean ~= new_lean_direction then
			TacticalLean:StartLean(new_lean_direction)
		end
	end
	local exiting_lean = TacticalLean:IsExitingLean()
	if not new_lean_direction and TacticalLean:GetCurrentLean() and not exiting_lean then
		TacticalLean:StopLean()
	end
	--[[
	elseif exiting_lean then 
		if t - TacticalLean:GetTimer() > lean_duration then 
			TacticalLean:OnLeanStopped()
		end
	end
	--]]
	
	Console:SetTrackerValue("trackere","leaning " .. tostring(new_lean_direction) .. ", exiting_lean " .. tostring(TacticalLean:IsExitingLean()))
end)