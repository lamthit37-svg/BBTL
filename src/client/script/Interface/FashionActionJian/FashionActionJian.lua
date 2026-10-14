--FashionActionJian.lua
--2020 动作时装图鉴界面
local g_Frame_UnifiedPosition
local g_FashionActionJian_CameraLevel = 0
local g_FashionActionJian_CameraPosition =
{
	[0] = {fHeight = 0.9, fDistance = 6, },
	[1] = {fHeight = 0.9, fDistance = 8, },
	[2] = {fHeight = 0.9, fDistance = 10, }, 
}

local g_FashionWeaponIdArray = {}
local g_FashionVisualIdArray = {}
local g_FashionActionJian_EquipPoint = 16
local g_FashionActionJian_EquipID = 0
local g_FashionActionJian_VisualID = 0
local g_FashionActionJian_RaceID = 0

--===============================================
-- OnLoad()
--===============================================
function FashionActionJian_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
end
function FashionActionJian_OnLoad()
	g_Frame_UnifiedPosition = FashionActionJian_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function FashionActionJian_OnEvent(event)
if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		FashionActionJian_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		FashionActionJian_OnHiden()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15700001 ) then
		if this:IsVisible() then
			return
		end
		local npcObjId = Get_XParam_INT(0)
		g_clientNpcId = DataPool : GetNPCIDByServerID(npcObjId)
		if g_clientNpcId ~= -1 then
			this:CareObject( g_clientNpcId, 1, "FashionActionJian" )
		end
		FashionActionJian_OnShow()
	end
end
function FashionActionJian_OnHiden()
	this:Hide()
end
function FashionActionJian_OnShow()
	g_FashionActionJian_CameraLevel = 0
	FashionActionJian_FakeObject:AttachWindowEx("FashionAction_Player")
	SetFakeObjDataEx("FashionAction_Player")
	FashionActionJian_Init()
	FashionActionJian_SetCameraPosition()
	FashionActionJian_UpdateZoomButton()
	this:Show()
end
--===============================================
--===============================================
function FashionActionJian_Init()
	FashionActionJian_List:RemoveAllItem();
	FashionActionUI:InitEquipBaseFashionActionData()
	g_FashionActionJian_RaceID = GetMySelfRaceId()
	if g_FashionActionJian_RaceID == 0 then
		FashionActionJian_SexChange:SetText( "#{DZSZ_201203_14}" );
	else
		FashionActionJian_SexChange:SetText( "#{DZSZ_201203_13}" );
	end
	g_FashionWeaponIdArray = {}
	local ActionNum = 0
	
	local num = FashionActionUI:GetFashionActionDataNum()
	for i=0, num - 1 do
		local strEquipName, index = FashionActionUI:EnumFashionAction(i);
		g_FashionWeaponIdArray[i] = index
		FashionActionJian_List:AddListboxItem( tostring(strEquipName), 1, i )
	end

	FashionActionJian_List:SetSelectItem(0)
	FashionActionJian_DressSelected()
end
function FashionActionJian_DressSelected()
	local nSelIndex = FashionActionJian_List:GetSelectItem();
	g_FashionActionJian_EquipID = g_FashionWeaponIdArray[nSelIndex];
	if not g_FashionActionJian_EquipID then 
		PushDebugMessage("FashionActionJian_DressSelected Selected EquipID is nil:"..nSelIndex)
		FashionActionJian_ALLChoice:Disable()
		FashionActionJian_ActionOne:Hide()
		FashionActionJian_ActionTwo:Hide()
		FashionActionJian_ActionThree:Hide()
		return 
	end
	-- PushDebugMessage("FashionActionJian_DressSelected:"..nSelIndex..":"..(g_FashionActionJian_EquipID or "nil"))
	-- FashionActionUI:FashionActionAvatarStopAction()
	-- 策划要求镜头拉最近
	g_FashionActionJian_CameraLevel = 0
	FashionActionJian_SetCameraPosition()
	FashionActionJian_UpdateZoomButton()
	
	g_FashionVisualIdArray = {}
	if DressReplaceColor:DressIsCanColour(g_FashionActionJian_EquipID) == 1 then
		DressReplaceColor :StoreDressByIndex(g_FashionActionJian_EquipID);
		FashionActionJian_ALLChoice:SetText("#{YJRS_140613_03}")
		FashionActionJian_ALLChoice:Enable()
		FashionActionJian_ALLChoice:ResetList()  
		FashionActionJian_ALLChoice:AddTextItem("默认风格",1)
		for i=1 ,8 do
			local nVisualID,szDesc,nRate = DressReplaceColor:GetDressDesc(i-1)
			local DressNames =""
			if nRate == 23000 then
				DressNames = ScriptGlobal_Format("#{SZRSYH_120912_07}", szDesc);
			elseif nRate == 14000 then
				DressNames = ScriptGlobal_Format("#{SZRSYH_120912_08}", szDesc)
			elseif nRate == 1000 then
				DressNames = ScriptGlobal_Format("#{SZRSYH_120912_09}", szDesc)
			elseif nRate == -1 then
				DressNames = szDesc
			end

			FashionActionJian_ALLChoice:AddTextItem(DressNames ,i+1) 
			g_FashionVisualIdArray[i+1] = nVisualID
		end
	else
		FashionActionJian_ALLChoice:SetText("#{DZSZ_201203_7}")
		FashionActionJian_ALLChoice:Disable()
	end
	FashionActionJian_ColorListChanged()
end

function FashionActionJian_ColorListChanged()
	local nEquipID = g_FashionActionJian_EquipID
	local _,nSelVisualIndex = FashionActionJian_ALLChoice:GetCurrentSelect()  
	if nSelVisualIndex < 1 then nSelVisualIndex = 1 end
	g_FashionActionJian_VisualID = g_FashionVisualIdArray[nSelVisualIndex];
	if not g_FashionActionJian_VisualID then 
		g_FashionActionJian_VisualID = FashionActionUI:GetFashionEquipVisual(nEquipID)
	end
	FashionActionUI:FashionActionAvatarChangeDress(g_FashionActionJian_EquipID, g_FashionActionJian_VisualID)
	FashionActionJian_ActionOne:Hide()
	FashionActionJian_ActionTwo:Hide()
	FashionActionJian_ActionThree:Hide()
	local ActionNum = FashionActionUI:GetFashionActionActionNum(g_FashionActionJian_EquipID, g_FashionActionJian_VisualID)
	-- PushDebugMessage("FashionActionJian_ColorListChanged:"..nSelVisualIndex..":"..ActionNum..":"..(g_FashionActionJian_EquipID or "nil")..":"..(g_FashionActionJian_VisualID or "nil"))
	if ActionNum == 0 then 
	elseif ActionNum == 1 then 
		FashionActionJian_ActionOne:Show()
	elseif ActionNum == 2 then 
		FashionActionJian_ActionTwo:Show()
	elseif ActionNum == 3 then 
		FashionActionJian_ActionThree:Show()
	else
		PushDebugMessage("FashionActionJian_DressSelected Out Of Index:"..(ActionNum or "nil"))
	end
	FashionActionUI:FashionActionAvatarStopAction()
end

function FashionActionJian_UpdateZoomButton()
	FashionActionJian_Model_ZoomIn:Enable()
	FashionActionJian_Model_ZoomOut:Enable()
	
	FashionActionJian_Model_ZoomIntips:Hide()
	FashionActionJian_Model_ZoomOuttips:Hide()
	
	if g_FashionActionJian_CameraLevel == 0 then 
		FashionActionJian_Model_ZoomIn:Disable()
		FashionActionJian_Model_ZoomIntips:Show()
	elseif g_FashionActionJian_CameraLevel == 2 then
		FashionActionJian_Model_ZoomOut:Disable()
		FashionActionJian_Model_ZoomOuttips:Show()
	end
end
function FashionActionJian_SetCameraPosition()
	if g_FashionActionJian_CameraLevel > -1 and g_FashionActionJian_CameraLevel < 3 then
		local fh, fd, fp = FashionActionJian_FakeObject:GetCameraEx()
		FashionActionJian_FakeObject:SetCameraEx(g_FashionActionJian_CameraPosition[g_FashionActionJian_CameraLevel].fHeight,g_FashionActionJian_CameraPosition[g_FashionActionJian_CameraLevel].fDistance,fp)
	end
end
function FashionActionJian_onZoomIn()
	if g_FashionActionJian_CameraLevel < 1  or g_FashionActionJian_CameraLevel > 2 then
		return
	end
	
	g_FashionActionJian_CameraLevel = g_FashionActionJian_CameraLevel - 1
	FashionActionJian_SetCameraPosition()
	FashionActionJian_UpdateZoomButton()
end
function FashionActionJian_onZoomOut()
	if g_FashionActionJian_CameraLevel < 0  or g_FashionActionJian_CameraLevel > 1 then
		return
	end
	
	g_FashionActionJian_CameraLevel = g_FashionActionJian_CameraLevel + 1
	FashionActionJian_SetCameraPosition()
	FashionActionJian_UpdateZoomButton()
end
function FashionActionJian_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			FashionActionJian_FakeObject:RotateBeginEx("FashionAction_Player", 0.3);
		--向右旋转结束
		else
			FashionActionJian_FakeObject:RotateEndEx();
		end
	end
end
function FashionActionJian_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			FashionActionJian_FakeObject:RotateBeginEx("FashionAction_Player", -0.3);
		--向左旋转结束
		else
			FashionActionJian_FakeObject:RotateEndEx();
		end
	end
end
function FashionActionJian_onAction(nIndex)
	if not g_FashionActionJian_EquipID or not g_FashionActionJian_VisualID or not nIndex then 
		return
	end
	FashionActionUI:FashionActionAvatarPlayAction(g_FashionActionJian_EquipID, g_FashionActionJian_VisualID, nIndex)
end
function FashionActionJian_OnSexChange()
	-- PushDebugMessage("FashionActionJian_OnSexChange:"..g_FashionActionJian_RaceID)
	if g_FashionActionJian_RaceID == 0 then 
		g_FashionActionJian_RaceID = 1
		FashionActionJian_SexChange:SetText( "#{DZSZ_201203_13}" );
		FashionActionUI:FashionActionAvatarChangeRaceID(1)
	else
		g_FashionActionJian_RaceID = 0
		FashionActionJian_SexChange:SetText( "#{DZSZ_201203_14}" );
		FashionActionUI:FashionActionAvatarChangeRaceID(0)
	end
	g_FashionActionJian_CameraLevel = 0
	FashionActionJian_SetCameraPosition()
	FashionActionJian_UpdateZoomButton()
end
