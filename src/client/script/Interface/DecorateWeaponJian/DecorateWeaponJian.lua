
local g_DecorateWeaponJian_Frame_UnifiedPosition;
local g_DestDecoWeaponLevelId = {}
local g_DecorateWeaponJian_CheckButton = {}
local g_DecorateWeaponIndex = {}
local g_DecorateWeaponJian_CurCheck = 1

local g_DecorateWeaponJian_CameraLevel = 0
local g_DecorateWeaponJian_CameraPosition =
{
	[0] = {fHeight = 0.9, fDistance = 6, },
	[1] = {fHeight = 0.9, fDistance = 8, },
	[2] = {fHeight = 0.9, fDistance = 10, }, 
}
--	门派
local g_DecorateWeaponJian_g_MenPaiList = 
{
	[0] = { id = 0,    name = "#{GMItem_4}" },    --少林
	[1] = { id = 1,    name = "#{GMItem_5}" },    --明教
	[2] = { id = 2,    name = "#{GMItem_6}" },    --丐帮
	[3] = { id = 3,    name = "#{GMItem_7}" },    --武当
	[4] = { id = 4,    name = "#{GMItem_8}" },    --峨眉
	[5] = { id = 5,    name = "#{GMItem_9}" },    --星宿
	[6] = { id = 6,    name = "#{GMItem_10}" },    --天龙
	[7] = { id = 7,    name = "#{GMItem_11}" },    --天山
	[8] = { id = 8,    name = "#{GMItem_12}" },    --逍遥
        [9] = { id = 9,   name = "" },         		--无门派
	[10] = { id = 10,  name = "#{GMItem_17}" },  --慕容
	[11] = { id = 11,  name = "#{XMPTM_130123_01}" },  --唐门
	[12] = { id = 12,  name = "#{XMPGG_160524_02}" },  --鬼谷
	[13] = { id = 13,  name = "#{THDXG_190705_04}" },  --桃花岛
	[14] = { id = 14,  name = "#{XMPHM_210604_01}" },
	[15] = { id = 15,  name = "#{GMGameInterface_Script_DataPool_Info_ERenGu}" },--menpai15 mptodo
}
function DecorateWeaponJian_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
	this:RegisterEvent("FAKEOBJ_MYSELFEQUIP_CHANGE", false)
end

function DecorateWeaponJian_OnLoad() 
	g_DecorateWeaponJian_Frame_UnifiedPosition = DecorateWeaponJian_Frame:GetProperty("UnifiedPosition");
	
	for i=1, 5 do
		g_DestDecoWeaponLevelId[i] = -1
	end
	
	g_DecorateWeaponJian_CheckButton[1] = DecorateWeaponJian_Button1
	g_DecorateWeaponJian_CheckButton[2] = DecorateWeaponJian_Button2
	g_DecorateWeaponJian_CheckButton[3] = DecorateWeaponJian_Button3
	g_DecorateWeaponJian_CheckButton[4] = DecorateWeaponJian_Button4
	g_DecorateWeaponJian_CheckButton[5] = DecorateWeaponJian_Button5
	
end

function DecorateWeaponJian_OnEvent(event) 

	if event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 891789 then	
		if this:IsVisible() then									-- 如果界面开着，则不处理
			return
		end
		
		if IsWindowShow("DecorateWeaponValentine") then
			CloseWindow("DecorateWeaponValentine", true)
		end
			
		local npcObjId = Get_XParam_INT(0)
		g_clientNpcId = DataPool : GetNPCIDByServerID(npcObjId)
		if g_clientNpcId == -1 then
			PushDebugMessage("未发现 NPC")
			DecorateWeaponJian_OnHiden()
			return
		end
		
		this:CareObject( g_clientNpcId, 1, "DecorateWeaponJian" )
		
		DecorateWeaponJian_FakeObject:AttachWindowEx("DecoWeapon_Player")
		SetFakeObjDataEx("DecoWeapon_Player")
			
		DecorateWeaponJian_Init()
		this:Show()
	
	elseif (event == "ADJEST_UI_POS" ) then
		DecorateWeaponJian_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DecorateWeaponJian_Frame_On_ResetPos()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		DecorateWeaponJian_OnHiden()
		
	elseif (event == "FAKEOBJ_MYSELFEQUIP_CHANGE") then
		SetFakeObjDataEx("DecoWeapon_Player")
		DecoWeaponUI:DecoWeaponAvatarChangeWeapon(g_DestDecoWeaponLevelId[g_DecorateWeaponJian_CurCheck])
	end
end

function DecorateWeaponJian_Frame_On_ResetPos()
  DecorateWeaponJian_Frame:SetProperty("UnifiedPosition", g_DecorateWeaponJian_Frame_UnifiedPosition);
end

function DecorateWeaponJian_OnHiden()
	this:CareObject( g_clientNpcId, 0, "DecorateWeaponJian" )
	DecorateWeaponJian_FakeObject:DetachWindowEx("DecoWeapon_Player")
	g_clientNpcId = -1
	
	for i=1, 5 do
		g_DestDecoWeaponLevelId[i] = -1
	end
	
	g_DecorateWeaponJian_CurCheck = 1
	this:Hide() 
end

function DecorateWeaponJian_Init()
	DecorateWeaponJian_List:RemoveAllItem();
	
	DecoWeaponUI:GetEquipBaseDecoWeaponData()
	g_DecorateWeaponIndex = {}
	local ActionNum = 0
	
	local num = DecoWeaponUI:GetDecoWeaponNum()
	for i=0, num - 1 do
		local szDecoWeaponName, index = DecoWeaponUI:EnumDecoWeapon(i);
		
		g_DecorateWeaponIndex[i] = index
		ActionNum = DecoWeaponUI:GetDecoWeapActionNum(g_DecorateWeaponIndex[i])	
		if(ActionNum > 0) then
			if index == 10102493 or index == 10102499 then
				DecorateWeaponJian_List:AddItemPic(12, 0, i, 1)
			else
				DecorateWeaponJian_List:AddItemPic(11, 0, i, 1)
			end
		else
			DecorateWeaponJian_List:AddItemPic(11, 0, i, 0)
		end
		
		DecorateWeaponJian_List:AddListboxItem( tostring(szDecoWeaponName), 1, i )
		--DecorateWeaponJian_List:AddItem(szDecoWeaponName, i);
		--DecorateWeaponJian_List:SetItemUserData(i, LevelId);
	end
	
	DecorateWeaponJian_List:SetSelectItem(0)
	DecorateWeaponJian_Selected()
end

function DecorateWeaponJian_Selected()
	local nSelIndex = DecorateWeaponJian_List:GetSelectItem();
	local LevelId = g_DecorateWeaponIndex[nSelIndex];

	local WeaponName = {}
	local nMyMenpai = Player:GetData("MEMPAI")
	 local menpailimitflag = Lua_GetMenpaiLimitFlag(LevelId)
	if menpailimitflag ~= -1 then
		DecorateWeaponJian_MenPai:Show()
		local menpainame = g_DecorateWeaponJian_g_MenPaiList[menpailimitflag].name
		if nMyMenpai ~= menpailimitflag then
			local text = ScriptGlobal_Format("#{HWMP_200619_09}", menpainame)
			DecorateWeaponJian_MenPai:SetText(text)
		else
			local text = ScriptGlobal_Format("#{HWMP_200619_08}", menpainame)
			DecorateWeaponJian_MenPai:SetText(text)			
		end
		
	else
		DecorateWeaponJian_MenPai:Hide()
	end
	

	
	g_DestDecoWeaponLevelId[1], WeaponName[1], g_DestDecoWeaponLevelId[2], WeaponName[2], 
	g_DestDecoWeaponLevelId[3], WeaponName[3], g_DestDecoWeaponLevelId[4], WeaponName[4],
	g_DestDecoWeaponLevelId[5], WeaponName[5]= DecoWeaponUI:GetDecoWeaponLevelInfo(LevelId)
	
	g_DecorateWeaponJian_CheckButton[g_DecorateWeaponJian_CurCheck]:SetCheck(1)
	DecorateWeaponJian_OnCheck(g_DecorateWeaponJian_CurCheck)
	
	if LevelId == 10107018 then
		g_DecorateWeaponJian_CameraPosition =
		{
			[0] = {fHeight = 1.1, fDistance = 7, },
			[1] = {fHeight = 1.1, fDistance = 9, },
			[2] = {fHeight = 1.1, fDistance = 11, }, 
		}		
	else
		g_DecorateWeaponJian_CameraPosition =
		{
			[0] = {fHeight = 0.9, fDistance = 6, },
			[1] = {fHeight = 0.9, fDistance = 8, },
			[2] = {fHeight = 0.9, fDistance = 10, }, 
		}		
	end
		
	g_DecorateWeaponJian_CameraLevel = 0
	DecorateWeaponJian_SetCameraPosition()
	DecorateWeaponJian_UpdateZoomButton()
end

function DecorateWeaponJian_OnCheck(level)
	if level > 0 and level < 6 and g_DestDecoWeaponLevelId[level] ~= -1 then 
		g_DecorateWeaponJian_CurCheck = level
		DecoWeaponUI:DecoWeaponAvatarChangeWeapon(g_DestDecoWeaponLevelId[level])
		DecorateWeaponJian_ActionOne:Hide()
		DecorateWeaponJian_ActionTwo:Hide()
		local ActionNum = DecoWeaponUI:GetDecoWeapActionNum(g_DestDecoWeaponLevelId[level])
		
		if ActionNum == 1 then
			DecorateWeaponJian_ActionOne:Show()
		elseif ActionNum == 2 then
			DecorateWeaponJian_ActionTwo:Show()
		end
	end
end

function DecorateWeaponJian_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			DecorateWeaponJian_FakeObject:RotateBeginEx("DecoWeapon_Player", -0.3);
		--向左旋转结束
		else
			DecorateWeaponJian_FakeObject:RotateEndEx();
		end
	end
end

----------------------------------------------------------------------------------
function DecorateWeaponJian_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			DecorateWeaponJian_FakeObject:RotateBeginEx("DecoWeapon_Player", 0.3);
		--向右旋转结束
		else
			DecorateWeaponJian_FakeObject:RotateEndEx();
		end
	end
end

function DecorateWeaponJian_onAction(index)
	DecoWeaponUI:DecoWeaponAvatarPlayAction(g_DestDecoWeaponLevelId[g_DecorateWeaponJian_CurCheck], index)
end

function DecorateWeaponJian_onZoomIn()
	if g_DecorateWeaponJian_CameraLevel < 1  or g_DecorateWeaponJian_CameraLevel > 2then
		return
	end
	
	g_DecorateWeaponJian_CameraLevel = g_DecorateWeaponJian_CameraLevel - 1
	DecorateWeaponJian_SetCameraPosition()
	DecorateWeaponJian_UpdateZoomButton()
end

function DecorateWeaponJian_onZoomOut()
	if g_DecorateWeaponJian_CameraLevel < 0 or g_DecorateWeaponJian_CameraLevel > 1 then
		return
	end
	
	g_DecorateWeaponJian_CameraLevel = g_DecorateWeaponJian_CameraLevel + 1
	DecorateWeaponJian_SetCameraPosition()
	DecorateWeaponJian_UpdateZoomButton()
end


function DecorateWeaponJian_SetCameraPosition()
	if g_DecorateWeaponJian_CameraLevel > -1 and g_DecorateWeaponJian_CameraLevel < 3 then
		local fh, fd, fp = DecorateWeaponJian_FakeObject:GetCameraEx()
		DecorateWeaponJian_FakeObject:SetCameraEx(g_DecorateWeaponJian_CameraPosition[g_DecorateWeaponJian_CameraLevel].fHeight,g_DecorateWeaponJian_CameraPosition[g_DecorateWeaponJian_CameraLevel].fDistance,fp)
	end
end

function DecorateWeaponJian_UpdateZoomButton()
	DecorateWeaponJian_Model_ZoomIn:Enable()
	DecorateWeaponJian_Model_ZoomOut:Enable()
	
	DecorateWeaponJian_Model_ZoomIntips:Hide()
	DecorateWeaponJian_Model_ZoomOuttips:Hide()
	
	if g_DecorateWeaponJian_CameraLevel == 0 then 
		DecorateWeaponJian_Model_ZoomIn:Disable()
		DecorateWeaponJian_Model_ZoomIntips:Show()
	elseif g_DecorateWeaponJian_CameraLevel == 2 then
		DecorateWeaponJian_Model_ZoomOut:Disable()
		DecorateWeaponJian_Model_ZoomOuttips:Show()
	end
end