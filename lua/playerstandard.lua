if _G.IS_VR then 
	return
end

Hooks:PostHook(PlayerStandard,"_end_action_steelsight","stopads_tacticallean",function(self,t)
	if TacticalLean:IsControllerModeEnabled() and TacticalLean:IsControllerAutoUnleanEnabled() then
		TacticalLean:StopLean()
	end
end)

local orig_check_bipod = PlayerStandard._check_action_deploy_bipod
function PlayerStandard:_check_action_deploy_bipod(t,input,...)
	if TacticalLean:GetLeanDirection() then
		--prevent bipodding if leaning
		return orig_check_bipod(self,t,input,...)	
	end
end

Hooks:PostHook(PlayerStandard,"_start_action_running","startrun_tacticallean",function(self,t)
	if TacticalLean:GetLeanDirection() then
		TacticalLean:StopLean()
	end
end)

--[[ reliably prevents leaning while running but results in jerky, instant lean exit on running start
Hooks:PostHook(PlayerStandard,"_update_running_timers","updaterun_tacticallean",function(self,t)
	if self:running() then
		TacticalLean:OnLeanStopped()
	end
end)
--]]

local orig_check_jump = PlayerStandard._check_action_jump
function PlayerStandard:_check_action_jump(t,input,...)
	if not TacticalLean:GetLeanDirection() then
		return orig_check_jump(self,t,input,...)
	end
end

local orig_check_melee = PlayerStandard._check_action_melee
function PlayerStandard:_check_action_melee(t,input,...)
	if TacticalLean:IsControllerModeEnabled() and TacticalLean:GetLeanDirection() then 
		return
	end
	return orig_check_melee(self,t,input,...)
end

local orig_check_run = PlayerStandard._check_action_run
function PlayerStandard:_check_action_run(t,input,...)
	if TacticalLean:IsControllerModeEnabled() and TacticalLean:GetLeanDirection() then 
		return
	end
	return orig_check_run(self,t,input,...)
end