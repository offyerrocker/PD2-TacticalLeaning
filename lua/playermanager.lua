if _G.IS_VR then 
	return
end

Hooks:PostHook(PlayerManager,"update","PlayerManagerUpdate_TacticalLean",function(t,dt)
	TacticalLean:Update(t,dt)
end
)