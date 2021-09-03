if _G.IS_VR then 
	return
end

Hooks:PostHook(PlayerManager,"update","PlayerManagerUpdate_TacticalLean",function(self,t,dt)
--todo check if player is in valid state, ie. standing, jumping or crouching
	if TacticalLean.settings.toggle_lean or not alive(managers.player:local_player()) then
		return
	end
	local either
	local key_left = "keybindid_taclean_left"
	local key_right = "keybindid_taclean_right"
	if HoldTheKey:Keybind_Held(key_left)then
		either = true
		if TacticalLean.current_lean ~= ("left") then
			TacticalLean:start_lean("left")
		end
	end
	if HoldTheKey:Keybind_Held(key_right) then
		either = true
		if TacticalLean.current_lean ~= ("right") then
			TacticalLean:start_lean("right")
		end
	end
	if not either and TacticalLean.current_lean and not TacticalLean.exiting_lean then
		TacticalLean:stop_lean()
	end	
end)