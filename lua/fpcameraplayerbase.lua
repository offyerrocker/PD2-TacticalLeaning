if _G.IS_VR then 
	return
end

local mrot1 = Rotation()
local mrot2 = Rotation()
local mrot3 = Rotation()
local mrot4 = Rotation()
local mvec1 = Vector3()
local mvec2 = Vector3()
local mvec3 = Vector3()
local mvec4 = Vector3()

local bezier_values = {
	0,
	0,
	1,
	1
}

Hooks:Register("FPCameraPlayerBase_updatemovement")
local orig_upd_movement = FPCameraPlayerBase._update_movement
function FPCameraPlayerBase:_update_movement(t, dt,...)
	if _G.IS_VR then 
		return orig_upd_movement(self,t,dt,...)
	end
	
	
	local data = self._camera_properties
	local new_head_pos = mvec2
	local new_shoulder_pos = mvec1
	local new_shoulder_rot = mrot1
	local new_head_rot = mrot2

	self._parent_unit:m_position(new_head_pos)

	mvector3.add(new_head_pos, self._head_stance.translation)

	local stick_input_x = 0
	local stick_input_y = 0
	local aim_assist_x, aim_assist_y = self:_get_aim_assist(t, dt, self._tweak_data.aim_assist_snap_speed, self._aim_assist)
	stick_input_x = stick_input_x + self:_horizonatal_recoil_kick(t, dt) + aim_assist_x
	stick_input_y = stick_input_y + self:_vertical_recoil_kick(t, dt) + aim_assist_y
	local look_polar_spin = data.spin - stick_input_x
	local look_polar_pitch = math.clamp(data.pitch + stick_input_y, -85, 85)

	if not self._limits or not self._limits.spin then
		look_polar_spin = look_polar_spin % 360
	end

	local look_polar = Polar(1, look_polar_pitch, look_polar_spin)
	local look_vec = look_polar:to_vector()
	local cam_offset_rot = mrot3

	mrotation.set_look_at(cam_offset_rot, look_vec, math.UP)
	mrotation.set_zero(new_head_rot)
	mrotation.multiply(new_head_rot, self._head_stance.rotation)
	mrotation.multiply(new_head_rot, cam_offset_rot)

	data.pitch = look_polar_pitch
	data.spin = look_polar_spin
	self._output_data.rotation = new_head_rot or self._output_data.rotation

--//changed
-- [[
	local current_lean = TacticalLean:GetLeanDirection()
	local exiting_lean = TacticalLean:IsExitingLean()
	local lean_direction = current_lean or exiting_lean
	if current_lean or exiting_lean then --use custom tilt interpolation 
		local lean_angle = TacticalLean:GetLeanAngle(lean_direction)
		local lerp = TacticalLean:GetLeanLerp()
--		local lean_duration = TacticalLean:GetLeanDuration()
		--[[
		if _t - lean_timer <= lean_duration then 
			Console:SetTrackerValue("trackerb",string.format("%0.2f <= %0.2f",_t - lean_timer,lean_duration))
			local lerp = math.max(0,_t - lean_timer) / lean_duration --smooth
			if exiting_lean then 
				lerp = 1 - lerp
			end
			--]]
--			local lean_remaining = TacticalLean.lean_remaining
--			local delta = math.sign(lean_remaining) * math.max(math.abs(lean_remaining) - dt,0)
--			TacticalLean.lean_remaining = TacticalLean.lean_remaining - delta
--			self._camera_properties.current_tilt = self._camera_properties.current_tilt + delta
			self._camera_properties.current_tilt = lerp * lean_angle
--		else
--			Console:SetTrackerValue("trackerb",string.format("%0.2f > %0.2f",_t -lean_timer,lean_duration))
--			self._camera_properties.current_tilt = lean_angle
--		end
	elseif self._camera_properties.current_tilt ~= self._camera_properties.target_tilt then
		self._camera_properties.current_tilt = math.step(self._camera_properties.current_tilt, self._camera_properties.target_tilt, 150 * dt)
	end
	--]]
	--[[
	local lean_duration = TacticalLean:GetLeanDuration()
	local lean_timer = TacticalLean:GetTimer()
	local lean_time_remaining = math.max(Application:time() - (lean_timer + lean_duration),0)
	local lean_time_lerp = lean_time_remaining / lean_duration
	if self._camera_properties.lean_position then 
	
	end	
	if self._camera_properties.lean_rotation then
		
	end
	if self._camera_properties.current_tilt ~= self._camera_properties.target_tilt then
		self._camera_properties.current_tilt = math.step(self._camera_properties.current_tilt, self._camera_properties.target_tilt, 150 * dt)
	end
	--]]
--//end changed

	if self._camera_properties.current_tilt ~= 0 then
		self._output_data.rotation = Rotation(self._output_data.rotation:yaw(), self._output_data.rotation:pitch(), self._output_data.rotation:roll() + self._camera_properties.current_tilt)
	end
	

	self._output_data.position = new_head_pos


	mvector3.set(new_shoulder_pos, self._shoulder_stance.translation)
	mvector3.add(new_shoulder_pos, self._vel_overshot.translation)
	mvector3.rotate_with(new_shoulder_pos, self._output_data.rotation)
	mvector3.add(new_shoulder_pos, new_head_pos)
	mrotation.set_zero(new_shoulder_rot)
	mrotation.multiply(new_shoulder_rot, self._output_data.rotation)
	mrotation.multiply(new_shoulder_rot, self._shoulder_stance.rotation)
	mrotation.multiply(new_shoulder_rot, self._vel_overshot.rotation)
	--[[
	local current_lean = TacticalLean:GetCurrentLean() 
	if current_lean then 
		local lean_angle = TacticalLean:GetLeanAngle(current_lean)
		local lean_distance = TacticalLean:GetLeanDistance()
		local sign = math.sign(lean_angle)
		Console:SetTrackerValue("trackera",tostring(t))
--		local vec_right = mvector3.cross(self:eye_rotation():x(),Vector3(0,1,0),math.UP):normalized()
--		mvector3.add(sign * lean_distance * vec_right,new_head_pos)
		new_shoulder_pos = new_shoulder_pos + (sign * lean_distance * Vector3(0,100,0))
	end
	--]]
	self:set_position(new_shoulder_pos)
	self:set_rotation(new_shoulder_rot)
	Hooks:Call("FPCameraPlayerBase_updatemovement",t,dt,...)
end

do return end

function FPCameraPlayerBase:_update_rot(axis, unscaled_axis)
	if self._animate_pitch then
		self:animate_pitch_upd()
	end

	local t = managers.player:player_timer():time()
	local dt = t - (self._last_rot_t or t)
	self._last_rot_t = t
	local data = self._camera_properties
	local new_head_pos = mvec2
	local new_shoulder_pos = mvec1
	local new_shoulder_rot = mrot1
	local new_head_rot = mrot2

	self._parent_unit:m_position(new_head_pos)
	mvector3.add(new_head_pos, self._head_stance.translation)

	self._input.look = axis
	self._input.look_multiplier = self._parent_unit:base():controller():get_setup():get_connection("look"):get_multiplier()
	local stick_input_x, stick_input_y = self._look_function(axis, self._input.look_multiplier, dt, unscaled_axis)
	local look_polar_spin = data.spin - stick_input_x
	local look_polar_pitch = math.clamp(data.pitch + stick_input_y, -85, 85)
	local player_state = managers.player:current_state()

	if self._limits then
		if self._limits.spin then
			local d = (look_polar_spin - self._limits.spin.mid) / self._limits.spin.offset
			d = math.clamp(d, -1, 1)
			look_polar_spin = data.spin - math.lerp(stick_input_x, 0, math.abs(d))
		end

		if self._limits.pitch then
			local d = math.abs((look_polar_pitch - self._limits.pitch.mid) / self._limits.pitch.offset)
			d = math.clamp(d, -1, 1)
			look_polar_pitch = data.pitch + math.lerp(stick_input_y, 0, math.abs(d))
			look_polar_pitch = math.clamp(look_polar_pitch, -85, 85)
		end
	end

	if not self._limits or not self._limits.spin then
		look_polar_spin = look_polar_spin % 360
	end

	local look_polar = Polar(1, look_polar_pitch, look_polar_spin)
	local look_vec = look_polar:to_vector()
	local cam_offset_rot = mrot3

	mrotation.set_look_at(cam_offset_rot, look_vec, math.UP)

	if self._animate_pitch == nil then
		mrotation.set_zero(new_head_rot)
		mrotation.multiply(new_head_rot, self._head_stance.rotation)
		mrotation.multiply(new_head_rot, cam_offset_rot)

		data.pitch = look_polar_pitch
		data.spin = look_polar_spin
	end

	self._output_data.position = new_head_pos

	if self._p_exit then
		self._p_exit = false
		self._output_data.rotation = self._parent_unit:movement().fall_rotation

		mrotation.multiply(self._output_data.rotation, self._parent_unit:camera():rotation())

		data.spin = self._output_data.rotation:y():to_polar().spin
	else
		self._output_data.rotation = new_head_rot or self._output_data.rotation
	end

	if self._camera_properties.current_tilt ~= self._camera_properties.target_tilt then
		self._camera_properties.current_tilt = math.step(self._camera_properties.current_tilt, self._camera_properties.target_tilt, 150 * dt)
	end

	if self._camera_properties.current_tilt ~= 0 then
		self._output_data.rotation = Rotation(self._output_data.rotation:yaw(), self._output_data.rotation:pitch(), self._output_data.rotation:roll() + self._camera_properties.current_tilt)
	end

	local equipped_weapon = self._parent_unit:inventory():equipped_unit()
	local bipod_weapon_translation = Vector3(0, 0, 0)

	if equipped_weapon and equipped_weapon:base() then
		local weapon_tweak_data = equipped_weapon:base():weapon_tweak_data()

		if weapon_tweak_data and weapon_tweak_data.bipod_weapon_translation then
			bipod_weapon_translation = weapon_tweak_data.bipod_weapon_translation
		end
	end

	local bipod_pos = Vector3(0, 0, 0)
	local bipod_rot = new_shoulder_rot

	mvector3.set(bipod_pos, bipod_weapon_translation)
	mvector3.rotate_with(bipod_pos, self._output_data.rotation)
	mvector3.add(bipod_pos, new_head_pos)
	mvector3.set(new_shoulder_pos, self._shoulder_stance.translation)
	mvector3.add(new_shoulder_pos, self._vel_overshot.translation)
	mvector3.rotate_with(new_shoulder_pos, self._output_data.rotation)
	mvector3.add(new_shoulder_pos, new_head_pos)
	mrotation.set_zero(new_shoulder_rot)
	mrotation.multiply(new_shoulder_rot, self._output_data.rotation)
	mrotation.multiply(new_shoulder_rot, self._shoulder_stance.rotation)
	mrotation.multiply(new_shoulder_rot, self._vel_overshot.rotation)

	if player_state == "driving" then
		self:_set_camera_position_in_vehicle()
	elseif player_state == "jerry1" or player_state == "jerry2" then
		mrotation.set_zero(cam_offset_rot)
		mrotation.multiply(cam_offset_rot, self._parent_unit:movement().fall_rotation)
		mrotation.multiply(cam_offset_rot, self._output_data.rotation)

		local shoulder_pos = mvec3
		local shoulder_rot = mrot4

		mrotation.set_zero(shoulder_rot)
		mrotation.multiply(shoulder_rot, cam_offset_rot)
		mrotation.multiply(shoulder_rot, self._shoulder_stance.rotation)
		mrotation.multiply(shoulder_rot, self._vel_overshot.rotation)
		mvector3.set(shoulder_pos, self._shoulder_stance.translation)
		mvector3.add(shoulder_pos, self._vel_overshot.translation)
		mvector3.rotate_with(shoulder_pos, cam_offset_rot)
		mvector3.add(shoulder_pos, self._parent_unit:position())
		self:set_position(shoulder_pos)
		self:set_rotation(shoulder_rot)
		self._parent_unit:camera():set_position(self._parent_unit:position())
		self._parent_unit:camera():set_rotation(cam_offset_rot)
	else
		self:set_position(new_shoulder_pos)
		self:set_rotation(new_shoulder_rot)
		self._parent_unit:camera():set_position(self._output_data.position)
		self._parent_unit:camera():set_rotation(self._output_data.rotation)
	end

	if player_state == "bipod" and not self._parent_unit:movement()._current_state:in_steelsight() then
		self:set_position(PlayerBipod._shoulder_pos or new_shoulder_pos)
		self:set_rotation(bipod_rot)
		self._parent_unit:camera():set_position(PlayerBipod._camera_pos or self._output_data.position)
	elseif not self._parent_unit:movement()._current_state:in_steelsight() then
		PlayerBipod:set_camera_positions(bipod_pos, self._output_data.position)
	end
end

function FPCameraPlayerBase:start_lean_transition_stance()
	
	
	
--[[
	reset_pos = false --allowing reset_pos makes the gun warp more, so i'll investigate it later
	local wpn = managers.player:local_player():movement():current_state()._equipped_unit:base()
	local stance_name = wpn:get_stance_id() or "default"
	stance_name = tweak_data.player.stances[stance_name] and stance_name or "default"
	local default_stance = tweak_data.player.stances[stance_name].standard.shoulders.translation
	local steelsight_stance = tweak_data.player.stances[stance_name].steelsight.shoulders.translation
	local stance_mod = {translation = Vector3(0, 0, 0)}
	local is_steelsight = self._parent_unit:movement()._current_state:in_steelsight()
	if is_steelsight and wpn.stance_mod then
		stance_mod = wpn:stance_mod() or stance_mod
	end	
	
	local angle = TacticalLean:get_angle(TacticalLean.current_lean)
	local sign = math.sign(angle)
	local lean_dist = math.cos(sign * angle) * 100 -- TacticalLean:get_distance()
	local distance = TacticalLean:get_distance()
	local v_dist = -math.sin(sign * angle) * 100

--	local result = -2
--	angle / 2
	
	local tr_mod = Vector3(sign * lean_dist,0,0) --TacticalLean.VERTICAL_DISTANCE)
	
	--[[
	
	9, tan(9) = 7.4 = -0.452
	
	
	--]]
	local orig_shoulder_transition = self._shoulder_stance.transition
	self._shoulder_stance.transition = {
		start_translation = Vector3(0,0,0),
		end_translation = Vector3(0,0,0),
		absolute_progress = 0 or orig_shoulder_transition.absolute_progress
	}
	local transition = self._shoulder_stance.transition--{}

	transition.end_rotation = self._shoulder_stance.rotation
	
	transition.duration = TacticalLean:get_lean_duration() --not affected by steelsight enter time multipliers
	
	if reset_pos then 
		transition.start_translation = is_steelsight and steelsight_stance or default_stance
	else
		mvector3.set(transition.start_translation, self._shoulder_stance.translation or transition.start_translation)
	end
	transition.start_rotation = self._shoulder_stance.rotation
	transition.start_t = Application:time()
	if is_steelsight then 
		mvector3.set(transition.end_translation, steelsight_stance)
		if stance_mod then --todo fix bugged stance for leaning while transitioning while from 45 degree scope ADS to default ADS
			mvector3.add(transition.end_translation, stance_mod.translation)
		end
	else
		mvector3.set(transition.end_translation, default_stance)
	end

	if TacticalLean.current_lean and not TacticalLean.exiting_lean then 
		mvector3.add(transition.end_translation,tr_mod)
	end
	--]]
end

do return end

function FPCameraPlayerBase:_update_stance(t, dt)
	if self._shoulder_stance.transition then
		local trans_data = self._shoulder_stance.transition
		local elapsed_t = t - trans_data.start_t

		if trans_data.duration < elapsed_t then
			mvector3.set(self._shoulder_stance.translation, trans_data.end_translation)

			self._shoulder_stance.rotation = trans_data.end_rotation
			self._shoulder_stance.transition = nil
			local in_steelsight = self._parent_movement_ext._current_state:in_steelsight()

			if in_steelsight and not self._steelsight_swap_state then
				self:_set_steelsight_swap_state(true)
			elseif not in_steelsight and self._steelsight_swap_state then
				self:_set_steelsight_swap_state(false)
			end
		else
			local progress = elapsed_t / trans_data.duration
			local progress_smooth = math.bezier(bezier_values, progress)

			mvector3.lerp(self._shoulder_stance.translation, trans_data.start_translation, trans_data.end_translation, progress_smooth)

			self._shoulder_stance.rotation = trans_data.start_rotation:slerp(trans_data.end_rotation, progress_smooth)
			local in_steelsight = self._parent_movement_ext._current_state:in_steelsight()
			local absolute_progress = nil

			if in_steelsight then
				absolute_progress = (1 - trans_data.absolute_progress) * progress_smooth + trans_data.absolute_progress
			else
				absolute_progress = trans_data.absolute_progress * (1 - progress_smooth)
			end

			if in_steelsight and not self._steelsight_swap_state and trans_data.steelsight_swap_progress_trigger <= absolute_progress then
				self:_set_steelsight_swap_state(true)
			elseif not in_steelsight and self._steelsight_swap_state and absolute_progress < trans_data.steelsight_swap_progress_trigger then
				self:_set_steelsight_swap_state(false)
			end
		end
	end

	if self._head_stance.transition then
		local trans_data = self._head_stance.transition
		local elapsed_t = t - trans_data.start_t

		if trans_data.duration < elapsed_t then
			mvector3.set(self._head_stance.translation, trans_data.end_translation)

			self._head_stance.transition = nil
		else
			local progress = elapsed_t / trans_data.duration
			local progress_smooth = math.bezier(bezier_values, progress)

			mvector3.lerp(self._head_stance.translation, trans_data.start_translation, trans_data.end_translation, progress_smooth)
		end
	end

	if self._vel_overshot.transition then
		local trans_data = self._vel_overshot.transition
		local elapsed_t = t - trans_data.start_t

		if trans_data.duration < elapsed_t then
			self._vel_overshot.yaw_neg = trans_data.end_yaw_neg
			self._vel_overshot.yaw_pos = trans_data.end_yaw_pos
			self._vel_overshot.pitch_neg = trans_data.end_pitch_neg
			self._vel_overshot.pitch_pos = trans_data.end_pitch_pos

			mvector3.set(self._vel_overshot.pivot, trans_data.end_pivot)

			self._vel_overshot.transition = nil
		else
			local progress = elapsed_t / trans_data.duration
			local progress_smooth = math.bezier(bezier_values, progress)
			self._vel_overshot.yaw_neg = math.lerp(trans_data.start_yaw_neg, trans_data.end_yaw_neg, progress_smooth)
			self._vel_overshot.yaw_pos = math.lerp(trans_data.start_yaw_pos, trans_data.end_yaw_pos, progress_smooth)
			self._vel_overshot.pitch_neg = math.lerp(trans_data.start_pitch_neg, trans_data.end_pitch_neg, progress_smooth)
			self._vel_overshot.pitch_pos = math.lerp(trans_data.start_pitch_pos, trans_data.end_pitch_pos, progress_smooth)

			mvector3.lerp(self._vel_overshot.pivot, trans_data.start_pivot, trans_data.end_pivot, progress_smooth)
		end
	end

	self:_calculate_soft_velocity_overshot(dt)

	if self._fov.transition then
		local trans_data = self._fov.transition
		local elapsed_t = t - trans_data.start_t

		if trans_data.duration < elapsed_t then
			self._fov.fov = trans_data.end_fov
			self._fov.transition = nil
		else
			local progress = elapsed_t / trans_data.duration
			local progress_smooth = math.max(math.min(math.bezier(bezier_values, progress), 1), 0)
			self._fov.fov = math.lerp(trans_data.start_fov, trans_data.end_fov, progress_smooth)
		end

		self._fov.dirty = true
	end
end

local orig_update_camangle = FPCameraPlayerBase._update_movement
function FPCameraPlayerBase:_update_movement(t, dt,...)
--	if true then return orig_update_camangle(self,t,dt,...) end
	
	
	local data = self._camera_properties
	local new_head_pos = mvec2
	local new_shoulder_pos = mvec1
	local new_shoulder_rot = mrot1
	local new_head_rot = mrot2

	self._parent_unit:m_position(new_head_pos)
	mvector3.add(new_head_pos, self._head_stance.translation)

	local stick_input_x = 0
	local stick_input_y = 0
	local aim_assist_x, aim_assist_y = self:_get_aim_assist(t, dt, self._tweak_data.aim_assist_snap_speed, self._aim_assist)
	stick_input_x = stick_input_x + self:_horizonatal_recoil_kick(t, dt) + aim_assist_x
	stick_input_y = stick_input_y + self:_vertical_recoil_kick(t, dt) + aim_assist_y
	local look_polar_spin = data.spin - stick_input_x
	local look_polar_pitch = math.clamp(data.pitch + stick_input_y, -85, 85)

	if not self._limits or not self._limits.spin then
		look_polar_spin = look_polar_spin % 360
	end

	local look_polar = Polar(1, look_polar_pitch, look_polar_spin)
	local look_vec = look_polar:to_vector()
	local cam_offset_rot = mrot3

	mrotation.set_look_at(cam_offset_rot, look_vec, math.UP)
	mrotation.set_zero(new_head_rot)
	mrotation.multiply(new_head_rot, self._head_stance.rotation)
	mrotation.multiply(new_head_rot, cam_offset_rot)

	data.pitch = look_polar_pitch
	data.spin = look_polar_spin
	self._output_data.rotation = new_head_rot or self._output_data.rotation

	local lean_tilt = TacticalLean.lean_tilt
	if lean_tilt and TacticalLean.current_lean then --use custom tilt interpolation 
		local _t = Application:time() --the "t" time value passed to this function doesn't account properly for slow-motion,
		--causing levels such as hotline miami day 2, which have slowmotion mission sequences, to spaz out the rotate over time calcuation here
		lean_tilt = lean_tilt + self._camera_properties.target_tilt
		local anim_t = TacticalLean:anim_t()
		local anim_scale = math.min(1,_t - anim_t) * 2 --smooth
		local difference = (self._camera_properties.current_tilt - lean_tilt)
		local result = self._camera_properties.current_tilt - (difference * anim_scale)
		
		self._camera_properties.current_tilt = result
	elseif self._camera_properties.current_tilt ~= self._camera_properties.target_tilt then
		self._camera_properties.current_tilt = math.step(self._camera_properties.current_tilt, self._camera_properties.target_tilt, 150 * dt)
	end
	if self._camera_properties.current_tilt ~= 0 then
		self._output_data.rotation = Rotation(self._output_data.rotation:yaw(), self._output_data.rotation:pitch(), self._output_data.rotation:roll() + self._camera_properties.current_tilt)
	end
	self._output_data.position = new_head_pos

	mvector3.set(new_shoulder_pos, self._shoulder_stance.translation)
	mvector3.add(new_shoulder_pos, self._vel_overshot.translation)
	mvector3.rotate_with(new_shoulder_pos, self._output_data.rotation)

	mvector3.add(new_shoulder_pos, new_head_pos)
	mrotation.set_zero(new_shoulder_rot)
	mrotation.multiply(new_shoulder_rot, self._output_data.rotation)
	mrotation.multiply(new_shoulder_rot, self._shoulder_stance.rotation)
	mrotation.multiply(new_shoulder_rot, self._vel_overshot.rotation)
	self:set_position(new_shoulder_pos) -- these two don't seem to do anything? 
	self:set_rotation(new_shoulder_rot) -- not really sure why
end

function FPCameraPlayerBase:start_lean_transition_stance(reset_pos)

	reset_pos = false --allowing reset_pos makes the gun warp more, so i'll investigate it later
	local wpn = managers.player:local_player():movement():current_state()._equipped_unit:base()
	local stance_name = wpn:get_stance_id() or "default"
	stance_name = tweak_data.player.stances[stance_name] and stance_name or "default"
	local default_stance = tweak_data.player.stances[stance_name].standard.shoulders.translation
	local steelsight_stance = tweak_data.player.stances[stance_name].steelsight.shoulders.translation
	local stance_mod = {translation = Vector3(0, 0, 0)}
	local is_steelsight = self._parent_unit:movement()._current_state:in_steelsight()
	if is_steelsight and wpn.stance_mod then
		stance_mod = wpn:stance_mod() or stance_mod
	end	
	
	local angle = TacticalLean:get_angle(TacticalLean.current_lean)
	local sign = math.sign(angle)
	local lean_dist = math.cos(sign * angle) * 100 -- TacticalLean:get_distance()
	local distance = TacticalLean:get_distance()
	local v_dist = -math.sin(sign * angle) * 100

--	local result = -2
--	angle / 2
	
	local tr_mod = Vector3(sign * lean_dist,0,0) --TacticalLean.VERTICAL_DISTANCE)
	
	--[[
	
	9, tan(9) = 7.4 = -0.452
	
	
	--]]
	local orig_shoulder_transition = self._shoulder_stance.transition
	self._shoulder_stance.transition = {
		start_translation = Vector3(0,0,0),
		end_translation = Vector3(0,0,0),
		absolute_progress = 0 or orig_shoulder_transition.absolute_progress
	}
	local transition = self._shoulder_stance.transition--{}

	transition.end_rotation = self._shoulder_stance.rotation
	
	transition.duration = TacticalLean:get_lean_duration() --not affected by steelsight enter time multipliers
	
	if reset_pos then 
		transition.start_translation = is_steelsight and steelsight_stance or default_stance
	else
		mvector3.set(transition.start_translation, self._shoulder_stance.translation or transition.start_translation)
	end
	transition.start_rotation = self._shoulder_stance.rotation
	transition.start_t = Application:time()
	if is_steelsight then 
		mvector3.set(transition.end_translation, steelsight_stance)
		if stance_mod then --todo fix bugged stance for leaning while transitioning while from 45 degree scope ADS to default ADS
			mvector3.add(transition.end_translation, stance_mod.translation)
		end
	else
		mvector3.set(transition.end_translation, default_stance)
	end

	if TacticalLean.current_lean and not TacticalLean.exiting_lean then 
		mvector3.add(transition.end_translation,tr_mod)
	end
end
