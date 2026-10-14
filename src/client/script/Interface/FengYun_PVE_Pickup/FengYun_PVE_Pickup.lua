-- 风云联动
-- 默认位置
local FengYun_PVE_Pickup_UnifiedPosition = nil
local FengYun_PVE_Pickup_ItemMax = 6
local FengYun_PVE_Pickup_ItemList= {}
local FengYun_PVE_Pickup_ScriptId = 335927
local FengYun_PVE_Pickup_CareObjId = -1
local FengYun_PVE_Pickup_CareObjSvrId = -1
function FengYun_PVE_Pickup_PreLoad()
	this:RegisterEvent("FYPVE_DROPBAGOPEN", true)
	this:RegisterEvent("FYPVE_CLOSEDROPBAG", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func FengYun_PVE_Pickup_PreLoad()

function FengYun_PVE_Pickup_OnEvent(event)
	if (event == "FYPVE_DROPBAGOPEN") then
		FengYun_PVE_Pickup_Show(tonumber(arg0))
	elseif (event == "FYPVE_CLOSEDROPBAG") then
		FengYun_PVE_Pickup_Hide()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FengYun_PVE_Pickup_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_PVE_Pickup_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		FengYun_PVE_Pickup_UnifiedPos()
	end
end -- end func FengYun_PVE_Pickup_OnEvent()

function FengYun_PVE_Pickup_OnLoad()
	FengYun_PVE_Pickup_ItemList = {
		FengYun_PVE_Pickup_Equip_Item1,
		FengYun_PVE_Pickup_Equip_Item2,
		FengYun_PVE_Pickup_Equip_Item3,
		FengYun_PVE_Pickup_Equip_Item4,
		FengYun_PVE_Pickup_Equip_Item5,
		FengYun_PVE_Pickup_Equip_Item6
	}
	FengYun_PVE_Pickup_UnifiedPosition = FengYun_PVE_Pickup_Frame:GetProperty("UnifiedPosition")
end -- end func FengYun_PVE_Pickup_OnLoad()

-- 界面默认位置
function FengYun_PVE_Pickup_UnifiedPos()
	if (FengYun_PVE_Pickup_UnifiedPosition ~= nil) then
		FengYun_PVE_Pickup_Frame:SetProperty("UnifiedPosition", FengYun_PVE_Pickup_UnifiedPosition)
	end
end -- end func FengYun_PVE_Pickup_UnifiedPos()

function FengYun_PVE_Pickup_Show(npcId)
	for i=1, FengYun_PVE_Pickup_ItemMax do
		local itemUI = FengYun_PVE_Pickup_ItemList[i]
		if itemUI ~= nil then
			local theAction = FYPVE:CreateFYPVEItemAction(2, i-1)
			if theAction ~= nil and theAction:GetID() ~= 0 then
				itemUI:SetActionItem(theAction:GetID())
			else
				itemUI:SetActionItem(-1)
			end
		end
	end

	FengYun_PVE_Pickup_BeginCareObject(npcId)
    this:Show()
end -- end func FengYun_PVE_Pickup_Show()

function FengYun_PVE_Pickup_Hide()
	FengYun_PVE_Pickup_StopCareObject()
    this:Hide()
end -- end func FengYun_PVE_Pickup_Hide()


function FengYun_PVE_Pickup_Hide_OnClick()
	FengYun_PVE_Pickup_Hide()
end -- end func FengYun_PVE_Pickup_Hide_OnClick()

function FengYun_PVE_Pickup_Equip_Item_Click(index, click)
	if index < 1 or index > FengYun_PVE_Pickup_ItemMax then
		return 
	end

	local action = FengYun_PVE_Pickup_ItemList[index]
	if action:GetActionItem() < 1 then
		return 
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PickItem")
		Set_XSCRIPT_ScriptID(FengYun_PVE_Pickup_ScriptId)
		Set_XSCRIPT_Parameter(0, FengYun_PVE_Pickup_CareObjSvrId)
		Set_XSCRIPT_Parameter(1, index-1)
		Set_XSCRIPT_Parameter(2, -1)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end -- end func FengYun_PVE_Pickup_Hide_OnClick()

function FengYun_PVE_Pickup_Equip_ALLBtn_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PickAllItem")
		Set_XSCRIPT_ScriptID(FengYun_PVE_Pickup_ScriptId)
		Set_XSCRIPT_Parameter(0, FengYun_PVE_Pickup_CareObjSvrId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func FengYun_PVE_Pickup_Equip_ALLBtn_Clicked()

function FengYun_PVE_Pickup_BeginCareObject(objSvrId)
	FengYun_PVE_Pickup_CareObjSvrId = tonumber(objSvrId)
	FengYun_PVE_Pickup_CareObjId = DataPool:GetNPCIDByServerID(objSvrId)
    if (FengYun_PVE_Pickup_CareObjId >= 0) then
		this:CareObject(FengYun_PVE_Pickup_CareObjId, 1, "FengYun_PVE_Pickup")
	end
end -- end func FengYun_PVE_Pickup_BeginCareObject()

function FengYun_PVE_Pickup_StopCareObject()
	if (FengYun_PVE_Pickup_CareObjId >= 0) then
		this:CareObject(FengYun_PVE_Pickup_CareObjId, 0, "FengYun_PVE_Pickup")
		FengYun_PVE_Pickup_CareObjId = -1
		FengYun_PVE_Pickup_CareObjSvrId = -1
	end
end -- end func FengYun_PVE_Pickup_StopCareObject()