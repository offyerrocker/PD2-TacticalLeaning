if _G.IS_VR then 
	return
end

local hard_block = false --whether or not to instantly stop leaning when invalid lean position; i don't like it
local orig_set_cam_pos = PlayerCamera.set_position --not really needed
function PlayerCamera:set_position(pos,...)
	local player = managers.player and managers.player:player_unit()
	if not player then
		return orig_set_cam_pos(self,pos)
	end	

	local _lean = TacticalLean.current_lean
	local _exit = TacticalLean.exiting_lean
	local duration = TacticalLean:get_lean_duration()
	local angle = TacticalLean:get_angle(_lean)
	local sign = angle < 0 and -1 or 1
	local distance = math.cos(angle) * 100 --TacticalLean:get_distance()
	local vertical_distance = math.sin(-math.abs(angle)) * 100 --TacticalLean.VERTICAL_DISTANCE
	local start_t = TacticalLean.move_anim_t
	
	local raw_headpos = player:movement():m_head_pos()
	local raw_headrot = player:movement():m_head_rot()
	
	local new_pos = Vector3()
	mvector3.set(new_pos,pos)
	if _lean then 
		local fwd = raw_headrot:y()
		local lean_vec = fwd:cross(Vector3(0,0,1)):normalized()
		local up = fwd:cross(lean_vec):normalized()
		local lean_vel = (sign * lean_vec * distance) + (-up * vertical_distance)
		
		Draw:brush(Color.red):line(pos + (fwd * 200),(fwd * 200) + (up * distance) + pos)
		Draw:brush(Color.green):line(pos + (fwd * 200),(fwd * 200) + (sign * lean_vec * distance) + pos)
		
		
		if TacticalLean:collision_check_enabled() then 
			local ray = World:raycast("ray",raw_headpos,raw_headpos + lean_vel,"slot_mask",managers.slot:get_mask("world_geometry"))
			if ray then 
				
				TacticalLean:stop_lean()
				if hard_block then return orig_set_cam_pos(self,pos) end --would snap back instantly... gross
			end
		end
		
		local elapsed_t = Application:time() -  start_t
		local progress_smooth = 1
		
		if duration < elapsed_t then 
			TacticalLean.current_lean = (not _exit) and _lean
			--on completion: if exiting, set "current_lean" to false
			--else, keep "current_lean" value
			TacticalLean.exiting_lean = false
			--either way, done exiting lean
		else
			local progress = math.min(elapsed_t / duration)
			if progress >= 1 then 
				progress_smooth = 1
			else
				progress_smooth = math.bezier({	0,	0,	1,	1},progress) --linear interpolation is for chumps
			end
		end
		
		if _exit then 
			progress_smooth = 1 - progress_smooth
		end
		mvector3.add(new_pos,lean_vel * progress_smooth)
		
	--[[
		local headrot = raw_headrot:y() * distance * sign --was x()
		if TacticalLean:collision_check_enabled() then 
--			local check_pos = Vector3()
			local check_pos = pos + headrot

--			mvector3.set(check_pos,pos)
--			mvector3.add(check_pos,headrot)
			local ray = World:raycast("ray",pos,check_pos,"slot_mask",managers.slot:get_mask("world_geometry"))
			if ray then 
				TacticalLean:stop_lean()
				if hard_block then return orig_set_cam_pos(self,pos) end --would snap back instantly... gross
			end
		end
		
		local elapsed_t = Application:time() -  start_t
		local progress_smooth = 1
		
		if duration < elapsed_t then 
			TacticalLean.current_lean = (not _exit) and _lean
			--on completion: if exiting, set "current_lean" to false
			--else, keep "current_lean" value
			TacticalLean.exiting_lean = false
			--either way, done exiting lean
		else
			local progress = elapsed_t / duration
			progress_smooth = math.bezier({	0,	0,	1,	1},progress) --linear interpolation is for chumps
		end
		
		if _exit then 
			progress_smooth = 1 - progress_smooth
		end
		
		headrot = headrot * progress_smooth
		
		mvector3.add(new_pos,headrot)
		--]]
	end

	self._camera_controller:set_camera(new_pos)
	mvector3.set(self._m_cam_pos, new_pos)	
end

