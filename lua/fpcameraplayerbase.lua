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
	local current_lean = TacticalLean:GetLeanDirection()
	local exiting_lean = TacticalLean:IsExitingLean()
	local lean_direction = current_lean or exiting_lean
	if current_lean or exiting_lean then
		local lean_angle = TacticalLean:GetLeanAngle(lean_direction)
		local lerp = TacticalLean:GetLeanLerp()
		
		local target_tilt = self._camera_properties.target_tilt or 0
		self._camera_properties.current_tilt = target_tilt + (lerp * lean_angle)
		--[[
		--todo add to current tilt interp
		if self._camera_properties.current_tilt ~= self._camera_properties.target_tilt then
			self._camera_properties.current_tilt = math.step(self._camera_properties.current_tilt, self._camera_properties.target_tilt, 150 * dt) + (dt * lerp * lean_angle)
		elseif self._camera_properties.target_tilt then
			self._camera_properties.current_tilt = self._camera_properties.target_tilt + (lerp * lean_angle)
		end
		--]]
	elseif self._camera_properties.current_tilt ~= self._camera_properties.target_tilt then
		self._camera_properties.current_tilt = math.step(self._camera_properties.current_tilt, self._camera_properties.target_tilt, 150 * dt)
	end
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
	
	self:set_position(new_shoulder_pos)
	self:set_rotation(new_shoulder_rot)
	Hooks:Call("FPCameraPlayerBase_updatemovement",self,t,dt,...)
end

Hooks:Register("FPCameraPlayerBase_update_rot")
local orig_upd_rot = FPCameraPlayerBase._update_rot
function FPCameraPlayerBase:_update_rot(axis, unscaled_axis,...)
	local player_state = managers.player:current_state()
	if not TacticalLean.STATE_WHITELIST[player_state] then 
		return orig_upd_rot(self,axis,unscaled_axis,...)
	end
	
	--//changed
	local lean_lerp = TacticalLean:GetLeanLerp()
	local lean_distance = TacticalLean:GetLeanDistance()
	local lean_direction = TacticalLean:IsExitingLean() or TacticalLean:GetLeanDirection()
	local lean_angle = TacticalLean:GetLeanAngle(lean_direction)

	local lean_fwd = self:eye_rotation():y()
	local lean_vec = lean_fwd:cross(Vector3(0,0,1)):normalized()
	local vec_lean_right = lean_distance * lean_lerp * math.sign(lean_angle) * lean_vec
	--//end changed
--	Console:SetTrackerValue("trackerd",string.format("%0.2f",TacticalLean:GetLeanLerp()))

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
	--changed this one line below (adds positional offset to both the camera and the viewmodel)
	new_head_pos = new_head_pos + vec_lean_right
	
--	TacticalLean.previous_raycast_from = new_head_pos
	
	mvector3.add(new_head_pos, self._head_stance.translation)

	self._input.look = axis
	self._input.look_multiplier = self._parent_unit:base():controller():get_setup():get_connection("look"):get_multiplier()
	local stick_input_x, stick_input_y = self._look_function(axis, self._input.look_multiplier, dt, unscaled_axis)
	local look_polar_spin = data.spin - stick_input_x
	local look_polar_pitch = math.clamp(data.pitch + stick_input_y, -85, 85)

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
	Hooks:Call("FPCameraPlayerBase_update_rot",self,axis,unscaled_axis,...)
end