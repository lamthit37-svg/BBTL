-- 风云联动
-- 默认位置
local FengYun_PVE_Backpack_UnifiedPosition = nil
local FengYun_PVE_Backpack_Max = 18
local FengYun_PVE_Backpack_ItemList = {}
function FengYun_PVE_Backpack_PreLoad()
	this:RegisterEvent("FYPVE_BAGOPEN", true)
	this:RegisterEvent("FYPVE_CLOSEBAG", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func FengYun_PVE_Backpack_PreLoad()

function FengYun_PVE_Backpack_OnEvent(event)
    if (event == "HIDE_ON_SCENE_TRANSED") then
		FengYun_PVE_Backpack_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_PVE_Backpack_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		FengYun_PVE_Backpack_UnifiedPos()
	elseif (event == "FYPVE_BAGOPEN") then
		FengYun_PVE_Backpack_Show()
	elseif (event == "FYPVE_CLOSEBAG") then
		FengYun_PVE_Backpack_Hide()
	end
end -- end func FengYun_PVE_Backpack_OnEvent()

function FengYun_PVE_Backpack_OnLoad()
	FengYun_PVE_Backpack_ItemList = {
		{action=FengYun_PVE_Backpack_Equip_Item1,lock=FengYun_PVE_Backpack_Equip_Item1_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item2,lock=FengYun_PVE_Backpack_Equip_Item2_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item3,lock=FengYun_PVE_Backpack_Equip_Item3_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item4,lock=FengYun_PVE_Backpack_Equip_Item4_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item5,lock=FengYun_PVE_Backpack_Equip_Item5_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item6,lock=FengYun_PVE_Backpack_Equip_Item6_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item7,lock=FengYun_PVE_Backpack_Equip_Item7_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item8,lock=FengYun_PVE_Backpack_Equip_Item8_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item9,lock=FengYun_PVE_Backpack_Equip_Item9_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item10,lock=FengYun_PVE_Backpack_Equip_Item10_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item11,lock=FengYun_PVE_Backpack_Equip_Item11_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item12,lock=FengYun_PVE_Backpack_Equip_Item12_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item13,lock=FengYun_PVE_Backpack_Equip_Item13_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item14,lock=FengYun_PVE_Backpack_Equip_Item14_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item15,lock=FengYun_PVE_Backpack_Equip_Item15_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item16,lock=FengYun_PVE_Backpack_Equip_Item16_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item17,lock=FengYun_PVE_Backpack_Equip_Item17_Mask,},
		{action=FengYun_PVE_Backpack_Equip_Item18,lock=FengYun_PVE_Backpack_Equip_Item18_Mask,},
	}
	FengYun_PVE_Backpack_UnifiedPosition = FengYun_PVE_Backpack_Frame:GetProperty("UnifiedPosition")
end -- end func FengYun_PVE_Backpack_OnLoad()

-- 界面默认位置
function FengYun_PVE_Backpack_UnifiedPos()
	if (FengYun_PVE_Backpack_UnifiedPosition ~= nil) then
		FengYun_PVE_Backpack_Frame:SetProperty("UnifiedPosition", FengYun_PVE_Backpack_UnifiedPosition)
	end
end -- end func FengYun_PVE_Backpack_UnifiedPos()

function FengYun_PVE_Backpack_Show()
	for i=1, FengYun_PVE_Backpack_Max do
		local itemUI = FengYun_PVE_Backpack_ItemList[i]
		if itemUI ~= nil then
			local theAction = FYPVE:CreateFYPVEItemAction(1, i-1)
			if theAction ~= nil and theAction:GetID() ~= 0 then
				itemUI.action:SetActionItem(theAction:GetID())
				itemUI.lock:Hide()
			else
				itemUI.action:SetActionItem(-1)
				local unlock,_,_ = FYPVE:GetBattleBagItemData(i-1)
				if unlock == nil or unlock < 1 then 
					itemUI.lock:Show()
				else
					itemUI.lock:Hide()
				end
			end
		end
	end

    this:Show()
end -- end func FengYun_PVE_Backpack_Show()

function FengYun_PVE_Backpack_Hide()
    this:Hide()
end -- end func FengYun_PVE_Backpack_Hide()

function FengYun_PVE_Backpack_Hide_OnClick()
	FengYun_PVE_Backpack_Hide()
end

function FengYun_PVE_Backpack_Equip_Item_Click(index, click)

end

