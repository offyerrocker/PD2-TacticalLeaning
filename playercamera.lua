local orig_set_cam_pos = PlayerCamera.set_position --not really needed
function PlayerCamera:set_position(pos)
	local player = managers.player and managers.player:player_unit()
	if not player then
		return orig_set_cam_pos(self,pos)
	end
--	local my_pos = player:camera():position() --not used

	local lean = TacticalLean.current_lean
	local exit_lean = TacticalLean.exiting_lean

	local raw_headrot = managers.player:local_player():movement():m_head_rot()
	local headrot = Vector3()
	local _t = Application:time()
	local anim_t = TacticalLean:anim_t() 
	local anim_scale = 1
	local check_pos = Vector3()
	if lean then --check for ray collision, but only when entering or in lean
		headrot = (raw_headrot:x() * (TacticalLean:get_distance()*1) * (TacticalLean:get_angle(lean) < 0 and -1 or 1))
		mvector3.set(check_pos,pos)
		mvector3.add(check_pos,headrot)
		local ray = World:raycast("ray",pos,check_pos,"slot_mask",managers.slot:get_mask("world_geometry"))
		if ray then
			TacticalLean:stop_lean()
		end
	end
	
	local new_pos = Vector3()
	mvector3.set(new_pos,pos)
	local is_steelsight = managers.player:player_unit():movement()._current_state:in_steelsight()

	if lean then --and not is_steelsight then
		if _t > anim_t + TacticalLean.move_anim_scale then
		--anim_scale = 1 already
			TacticalLean.current_lean = (not exit_lean) and TacticalLean.current_lean
			TacticalLean.exiting_lean = false
		else
			anim_scale = (_t - anim_t) / TacticalLean.move_anim_scale
		end
		if ray then 
			--
		elseif exit_lean then
			anim_scale = 1 - anim_scale
		end
		headrot = headrot * anim_scale
		mvector3.add(new_pos,headrot)

	end
	self._camera_controller:set_camera(new_pos)
	mvector3.set(self._m_cam_pos, new_pos)
	
end
