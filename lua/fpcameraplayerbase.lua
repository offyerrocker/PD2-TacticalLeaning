if _G.IS_VR then return end

local function tl_post(self)
	local state = managers.player:current_state()
	if not TacticalLean.STATE_WHITELIST[state] then return end

	local dir = TacticalLean:IsExitingLean() or TacticalLean:GetLeanDirection()
	if not dir then return end

	local out = self._output_data
	local angle = TacticalLean:GetLeanAngle(dir)
	local lerp = TacticalLean:GetLeanLerp()

	local right = out.rotation:y():cross(Vector3(0, 0, 1)):normalized()
	local head_pos = out.position + right * (TacticalLean:GetLeanDistance() * lerp * math.sign(angle))
	local head_rot = Rotation(out.rotation:yaw(), out.rotation:pitch(), out.rotation:roll() + lerp * angle)

	local sh_pos = self._shoulder_stance.translation + self._vel_overshot.translation
	mvector3.rotate_with(sh_pos, head_rot)
	sh_pos = sh_pos + head_pos
	local sh_rot = head_rot * self._shoulder_stance.rotation * self._vel_overshot.rotation

	self:set_position(sh_pos)
	self:set_rotation(sh_rot)
	self._parent_unit:camera():set_position(head_pos)
	self._parent_unit:camera():set_rotation(head_rot)

	TacticalLean.previous_raycast_from = mvector3.copy(head_pos)
end

Hooks:PostHook(FPCameraPlayerBase, "_update_rot", "tl_update_rot", tl_post)