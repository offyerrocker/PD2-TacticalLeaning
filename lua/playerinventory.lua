if _G.IS_VR then 
	return
end

local orig_equip_selection = PlayerInventory.equip_selection
function PlayerInventory:equip_selection(...)
	local result = {orig_equip_selection(self,...)}
	if TacticalLean:GetCurrentLean() and result[1] then --and managers.player and alive(managers.player:local_player()) and result and Utils:IsInHeist() then 
		TacticalLean:SetLeanStanceTransition()
	end
	return unpack(result)
end