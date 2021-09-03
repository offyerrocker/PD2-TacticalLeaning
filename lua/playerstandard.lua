if _G.IS_VR then 
	return
end

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

local orig_check_jump = PlayerStandard._check_action_jump
function PlayerStandard:_check_action_jump(t,input,...)
	--prevent jumping if leaning
	--todo prevent leaning if midair?
	if TacticalLean:GetLeanDirection() then
		return orig_check_jump(self,t,input,...)
	end
end)