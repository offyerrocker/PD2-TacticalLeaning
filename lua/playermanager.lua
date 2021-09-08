if _G.IS_VR then 
	return
end

Hooks:PostHook(PlayerManager,"init","PlayerManagerInit_TacticalLean",function(self)
	self:register_message(Message.OnSwitchWeapon, "onplayerweaponswitched_tacticallean",function()
		TacticalLean:StopLean()
	end)
end)

Hooks:PostHook(PlayerManager,"update","PlayerManagerUpdate_TacticalLean",function(self,t,dt)
	TacticalLean:Update(t,dt)
end)
