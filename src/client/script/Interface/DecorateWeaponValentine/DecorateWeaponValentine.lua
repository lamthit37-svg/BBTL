
local g_DecorateWeaponValentine_Frame_UnifiedPosition;
local g_DestDecoWeaponLevelId = {}
local g_DecorateWeaponValentine_CheckButton = {}
local g_DecorateWeaponValentine_CurCheck = 1
local g_DecorateWeaponName = {};
local g_DecorateWeaponID = 
{
	[0] = {ID = 10102395,IsShow = 0},
	[1] = {ID = 10102410,IsShow = 0},
	[2] = {ID = 10102430,IsShow = 0},
	[3] = {ID = 10102463,IsShow = 1},
	[4] = {ID = 10102475,IsShow = 1},
};

local g_DecorateWeaponIDNew = 
{
	[0] = {ID = 10102420,IsShow = 1},
	[1] = {ID = 10102385,IsShow = 1},
	[2] = {ID = 10104102,IsShow = 1},
	[3] = {ID = 10104114,IsShow = 1},
	
};

local g_DecorateWeaponID_2018 = 
{
	[0] = {ID = 10102395,IsShow = 0},
	[1] = {ID = 10102410,IsShow = 0},
	[2] = {ID = 10102430,IsShow = 0},
	[3] = {ID = 10102463,IsShow = 1},
	[4] = {ID = 10102475,IsShow = 1},
	[5] = {ID = 10107018,IsShow = 1},	
};

local g_DecorateWeaponIDLSYJ_2018 = 
{
	[0] = {ID = 10105018,IsShow = 1},
	[1] = {ID = 10102420,IsShow = 1},
	[2] = {ID = 10102385,IsShow = 1},
	[3] = {ID = 10104102,IsShow = 1},
	[4] = {ID = 10104114,IsShow = 1},
};

local g_DecorateWeaponID_2019 = 
{
	[0] = {ID = 10102395,IsShow = 0},
	[1] = {ID = 10102410,IsShow = 0},
	[2] = {ID = 10102430,IsShow = 0},
	[3] = {ID = 10102463,IsShow = 1},
	[4] = {ID = 10102475,IsShow = 1},
	[5] = {ID = 10107018,IsShow = 1},	
	[6] = {ID = 10102652,IsShow = 1},		
};

local g_DecorateWeaponID_2021 = 
{
	[0] = {ID = 10102395,IsShow = 0},
	[1] = {ID = 10102410,IsShow = 0},
	[2] = {ID = 10102430,IsShow = 0},
	[3] = {ID = 10102463,IsShow = 1},
	[4] = {ID = 10102475,IsShow = 1},
	[5] = {ID = 10107018,IsShow = 1},	
	[6] = {ID = 10102652,IsShow = 1},		
	[7] = {ID = 10102753,IsShow = 1},
};

local g_DecorateWeaponID_2022 = 
{
	[0] = {ID = 10102395,IsShow = 0},
	[1] = {ID = 10102410,IsShow = 0},
	[2] = {ID = 10102430,IsShow = 0},
	[3] = {ID = 10102463,IsShow = 1},
	[4] = {ID = 10102475,IsShow = 1},
	[5] = {ID = 10107018,IsShow = 1},	
	[6] = {ID = 10102652,IsShow = 1},		
	[7] = {ID = 10102753,IsShow = 1},
	[8] = {ID = 10102872,IsShow = 1},
};

local g_DecorateWeaponID_2023 = 
{
	[0] = {ID = 10102395,IsShow = 0},
	[1] = {ID = 10102410,IsShow = 0},
	[2] = {ID = 10102430,IsShow = 0},
	[3] = {ID = 10102463,IsShow = 1},
	[4] = {ID = 10102475,IsShow = 1},
	[5] = {ID = 10107018,IsShow = 1},	
	[6] = {ID = 10102652,IsShow = 1},		
	[7] = {ID = 10102753,IsShow = 1},
	[8] = {ID = 10102872,IsShow = 1},
	[9] = {ID = 10102949,IsShow = 1},
};

local g_DecorateWeaponID_2024 = 
{
	[0] = {ID = 10102395,IsShow = 0},
	[1] = {ID = 10102410,IsShow = 0},
	[2] = {ID = 10102430,IsShow = 0},
	[3] = {ID = 10102463,IsShow = 1},
	[4] = {ID = 10102475,IsShow = 1},
	[5] = {ID = 10107018,IsShow = 1},	
	[6] = {ID = 10102652,IsShow = 1},		
	[7] = {ID = 10102753,IsShow = 1},
	[8] = {ID = 10102872,IsShow = 1},
	[9] = {ID = 10102949,IsShow = 1},
	[10] = {ID = 10192059,IsShow = 1},
};

local g_DecorateWeaponID_2019qixi = 
{
	[0] = {ID = 10102420,IsShow = 1},
	[1] = {ID = 10102385,IsShow = 1},
	[2] = {ID = 10104102,IsShow = 1},
	[3] = {ID = 10104114,IsShow = 1},
	[4] = {ID = 10102621,IsShow = 1},	
	[5] = {ID = 10105018,IsShow = 1},	
};

local g_DecorateWeaponID_2020qixi = 
{
	[0] = {ID = 10102420,IsShow = 1},
	[1] = {ID = 10102385,IsShow = 1},
	[2] = {ID = 10104102,IsShow = 1},
	[3] = {ID = 10104114,IsShow = 1},
	[4] = {ID = 10102621,IsShow = 1},	
	[5] = {ID = 10105018,IsShow = 1},	
	[6] = {ID = 10102720,IsShow = 1},	
};

local g_DecorateWeaponID_2021qixi = 
{
	[0] = {ID = 10102420,IsShow = 1},
	[1] = {ID = 10102385,IsShow = 1},
	[2] = {ID = 10104102,IsShow = 1},
	[3] = {ID = 10104114,IsShow = 1},
	[4] = {ID = 10102621,IsShow = 1},	
	[5] = {ID = 10105018,IsShow = 1},	
	[6] = {ID = 10102720,IsShow = 1},	
	[7] = {ID = 10102816,IsShow = 1},	
};

local g_DecorateWeaponID_2022qixi = 
{
	[0] = {ID = 10102420,IsShow = 1},
	[1] = {ID = 10102385,IsShow = 1},
	[2] = {ID = 10104102,IsShow = 1},
	[3] = {ID = 10104114,IsShow = 1},
	[4] = {ID = 10102621,IsShow = 1},	
	[5] = {ID = 10105018,IsShow = 1},	
	[6] = {ID = 10102720,IsShow = 1},	
	[7] = {ID = 10102816,IsShow = 1},	
	[8] = {ID = 10102921,IsShow = 1},	
};

local g_DecorateWeaponID_2023qixi = 
{
	[0] = {ID = 10102420,IsShow = 1},
	[1] = {ID = 10102385,IsShow = 1},
	[2] = {ID = 10104102,IsShow = 1},
	[3] = {ID = 10104114,IsShow = 1},
	[4] = {ID = 10102621,IsShow = 1},	
	[5] = {ID = 10105018,IsShow = 1},	
	[6] = {ID = 10102720,IsShow = 1},	
	[7] = {ID = 10102816,IsShow = 1},	
	[8] = {ID = 10102921,IsShow = 1},	
	[9] = {ID = 10102991,IsShow = 1},	
};

local g_DecorateWeaponID_2023qixiEx = 
{	
	[0] = {ID = 10102921,IsShow = 1},	
	[1] = {ID = 10102991,IsShow = 1},	
};

local g_DecorateWeaponIDCur = {}

local g_DecorateWeaponValentine_CameraLevel = 0
local g_DecorateWeaponValentine_CameraPosition =
{
	[0] = {fHeight = 0.9, fDistance = 6, },
	[1] = {fHeight = 0.9, fDistance = 8, },
	[2] = {fHeight = 0.9, fDistance = 10, }, 
}

local g_CurCommand = 0

function DecorateWeaponValentine_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
	this:RegisterEvent("FAKEOBJ_MYSELFEQUIP_CHANGE", false)
end

function DecorateWeaponValentine_OnLoad() 
	g_DecorateWeaponValentine_Frame_UnifiedPosition = DecorateWeaponValentine_Frame:GetProperty("UnifiedPosition");
	
	for i=1, 5 do
		g_DestDecoWeaponLevelId[i] = -1
	end
	
	g_DecorateWeaponValentine_CheckButton[1] = DecorateWeaponValentine_Button1
	g_DecorateWeaponValentine_CheckButton[2] = DecorateWeaponValentine_Button2
	g_DecorateWeaponValentine_CheckButton[3] = DecorateWeaponValentine_Button3
	g_DecorateWeaponValentine_CheckButton[4] = DecorateWeaponValentine_Button4
	g_DecorateWeaponValentine_CheckButton[5] = DecorateWeaponValentine_Button5
	
end

function DecorateWeaponValentine_OnEvent(event) 

	if event == "UI_COMMAND" and arg0 ~= nil and (tonumber(arg0) == 892416 or tonumber(arg0) == 892666 or tonumber(arg0) == 892875
		or tonumber(arg0) == 893032 or tonumber(arg0) == 893133 or tonumber(arg0) == 888121 or tonumber(arg0) == 888379 or tonumber(arg0) == 888135 
		or tonumber(arg0) == 892758 or tonumber(arg0) == 998109 or tonumber(arg0) == 892763 or tonumber(arg0) == 998653 or tonumber(arg0) == 998664 
		or tonumber(arg0) == 892767 ) then
		g_CurCommand = tonumber(arg0)

		local ntype = Get_XParam_INT(0)	
		if ntype == 0 then
			if this:IsVisible() then
				DecorateWeaponValentine_OnHiden()
				return
			end
			
			if IsWindowShow("DecorateWeaponJian") then
				CloseWindow("DecorateWeaponJian", true)
			end
			
			if g_CurCommand == 892416 then
				DecorateWeaponValentine_DragTitle:SetText("#{MGCQ_161223_01}")
				DecorateWeaponValentine_Explain:SetText("#{MGCQ_161223_02}")
			elseif g_CurCommand == 892666 then
				DecorateWeaponValentine_DragTitle:SetText("#{MGCQ_180125_39}")
				DecorateWeaponValentine_Explain:SetText("#{MGCQ_180122_37}")	
			elseif g_CurCommand == 892875 then
				DecorateWeaponValentine_DragTitle:SetText("#{MGCQ_180126_45}")
				DecorateWeaponValentine_Explain:SetText("#{MGCQ_180126_44}")	
			elseif g_CurCommand == 893032 then
				DecorateWeaponValentine_DragTitle:SetText("#{MGCQ_180126_53}")
				DecorateWeaponValentine_Explain:SetText("#{MGCQ_180126_54}")	
			elseif g_CurCommand == 893133 then
				DecorateWeaponValentine_DragTitle:SetText("#{MGCQ_180126_48}")
				DecorateWeaponValentine_Explain:SetText("#{MGCQ_180126_49}")						
			elseif g_CurCommand == 888121 then
				DecorateWeaponValentine_DragTitle:SetText("#{QXLS_200723_04}")
				DecorateWeaponValentine_Explain:SetText("#{QXLS_200723_05}")						
			elseif g_CurCommand == 888379 then
				DecorateWeaponValentine_DragTitle:SetText("#{MGCQ_210107_07}")
				DecorateWeaponValentine_Explain:SetText("#{MGCQ_210107_08}")	
			elseif g_CurCommand == 888135 then
				DecorateWeaponValentine_DragTitle:SetText("#{QXLS_20210702_01}")
				DecorateWeaponValentine_Explain:SetText("#{QXLS_20210702_02}")						
			elseif g_CurCommand == 892758 then
				DecorateWeaponValentine_DragTitle:SetText("#{MGCQ_211130_78}")
				DecorateWeaponValentine_Explain:SetText("#{MGCQ_211130_79}")	
			elseif g_CurCommand == 998109 then
				DecorateWeaponValentine_DragTitle:SetText("#{QXLS_220517_91}")
				DecorateWeaponValentine_Explain:SetText("#{QXLS_220517_92}")	
			elseif g_CurCommand == 892763 then
				DecorateWeaponValentine_DragTitle:SetText("#{MGCQ_220128_29}")
				DecorateWeaponValentine_Explain:SetText("#{MGCQ_220128_30}")		
			elseif g_CurCommand == 998653 then
				DecorateWeaponValentine_DragTitle:SetText("#{QXLS_230724_35}")
				DecorateWeaponValentine_Explain:SetText("#{QXLS_230724_36}")		
			elseif g_CurCommand == 998664 then
				DecorateWeaponValentine_DragTitle:SetText("#{QXLS_230724_30}")
				DecorateWeaponValentine_Explain:SetText("#{QXLS_230724_31}")		
			elseif g_CurCommand == 892767 then
				DecorateWeaponValentine_DragTitle:SetText("#{MGCQ_231228_02}")
				DecorateWeaponValentine_Explain:SetText("#{MGCQ_231228_03}")		
			end
			
			DecorateWeaponValentine_FakeObject:AttachWindowEx("DecoWeapon_Player")
			SetFakeObjDataEx("DecoWeapon_Player")
			
			DecorateWeaponValentine_Init()
			this:Show()
		elseif ntype == 1 then
			DecorateWeaponValentine_OnHiden()
		end	
		
	elseif event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 892462 then 
		g_CurCommand = 892462
		--鸾凤礼盒
		local ntype = Get_XParam_INT(0)	
		if ntype == 0 then
			if this:IsVisible() then
				DecorateWeaponValentine_OnHiden()
				return
			end
			
			if IsWindowShow("DecorateWeaponJian") then
				CloseWindow("DecorateWeaponJian", true)
			end
			
			DecorateWeaponValentine_DragTitle:SetText("#{MGCQ_170804_32}")
			DecorateWeaponValentine_Explain:SetText("#{MGCQ_170807_33}")
			
			DecorateWeaponValentine_FakeObject:AttachWindowEx("DecoWeapon_Player")
			SetFakeObjDataEx("DecoWeapon_Player")
			
			DecorateWeaponValentine_Init()
			this:Show()
		elseif ntype == 1 then
			DecorateWeaponValentine_OnHiden()
		end
		
	elseif (event == "ADJEST_UI_POS" ) then
		DecorateWeaponValentine_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DecorateWeaponValentine_Frame_On_ResetPos()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		DecorateWeaponValentine_OnHiden()
	
	elseif (event == "FAKEOBJ_MYSELFEQUIP_CHANGE") then
		SetFakeObjDataEx("DecoWeapon_Player")
		DecoWeaponUI:DecoWeaponAvatarChangeWeapon(g_DestDecoWeaponLevelId[g_DecorateWeaponValentine_CurCheck])
	end
end

function DecorateWeaponValentine_Frame_On_ResetPos()
  DecorateWeaponValentine_Frame:SetProperty("UnifiedPosition", g_DecorateWeaponValentine_Frame_UnifiedPosition);
end

function DecorateWeaponValentine_OnHiden()
	DecorateWeaponValentine_FakeObject:DetachWindowEx("DecoWeapon_Player")
	
	for i=1, 5 do
		g_DestDecoWeaponLevelId[i] = -1
	end
	
	g_DecorateWeaponValentine_CurCheck = 1
	
	this:Hide() 
end

function DecorateWeaponValentine_Init()
	DecorateWeaponValentine_List:RemoveAllItem();
	
	DecoWeaponUI:GetEquipBaseDecoWeaponData()
	local num = DecoWeaponUI:GetDecoWeaponNum()
	
	local nindex = 0
	for i=0, num - 1 do
		local szDecoWeaponName, LevelId = DecoWeaponUI:EnumDecoWeapon(i);
		local weaptype = DecorateWeaponValentine_IsShow(LevelId);
		if weaptype == 1 then
			ActionNum = DecoWeaponUI:GetDecoWeapActionNum(LevelId)	
			if(ActionNum > 0) then
				DecorateWeaponValentine_List:AddItemPic(11,0,nindex,1)
			else
				DecorateWeaponValentine_List:AddItemPic(11,0,nindex,0)
			end
			-- 名称、列、行
			DecorateWeaponValentine_List:AddListboxItem(szDecoWeaponName, 1,nindex )
			g_DecorateWeaponName[nindex] = szDecoWeaponName
			g_DecorateWeaponIDCur[nindex] = LevelId
			nindex = nindex + 1
		end
	end
	
	DecorateWeaponValentine_List:SetSelectItem(0)
	DecorateWeaponValentine_Selected()
end

function DecorateWeaponValentine_Selected()

	if IsWindowShow("MessageBox_Self")==true then
		CloseWindow( "MessageBox_Self", true );
	end
	local nSelIndex = DecorateWeaponValentine_List:GetSelectItem();
	--设置当前称号的解释
	local LevelId = g_DecorateWeaponIDCur[nSelIndex]
	
	local WeaponName = {}
	
	g_DestDecoWeaponLevelId[1], WeaponName[1], g_DestDecoWeaponLevelId[2], WeaponName[2], 
	g_DestDecoWeaponLevelId[3], WeaponName[3], g_DestDecoWeaponLevelId[4], WeaponName[4],
	g_DestDecoWeaponLevelId[5], WeaponName[5]= DecoWeaponUI:GetDecoWeaponLevelInfo(LevelId)
	
	g_DecorateWeaponValentine_CheckButton[g_DecorateWeaponValentine_CurCheck]:SetCheck(1)
	DecorateWeaponValentine_OnCheck(g_DecorateWeaponValentine_CurCheck)
	
	if LevelId == 10107018 then
		g_DecorateWeaponValentine_CameraPosition =
		{
			[0] = {fHeight = 1.1, fDistance = 7, },
			[1] = {fHeight = 1.1, fDistance = 9, },
			[2] = {fHeight = 1.1, fDistance = 11, }, 
		}		
	else
		g_DecorateWeaponValentine_CameraPosition =
		{
			[0] = {fHeight = 0.9, fDistance = 6, },
			[1] = {fHeight = 0.9, fDistance = 8, },
			[2] = {fHeight = 0.9, fDistance = 10, }, 
		}		
	end
	g_DecorateWeaponValentine_CameraLevel = 0
	DecorateWeaponValentine_SetCameraPosition()
	DecorateWeaponValentine_UpdateZoomButton()
end

function DecorateWeaponValentine_OnCheck(level)
	if level > 0 and level < 6 and g_DestDecoWeaponLevelId[level] ~= -1 then 
		g_DecorateWeaponValentine_CurCheck = level
		DecoWeaponUI:DecoWeaponAvatarChangeWeapon(g_DestDecoWeaponLevelId[level])
	end
	
	DecorateWeaponValentine_ActionOne:Hide()
	DecorateWeaponValentine_ActionTwo:Hide()
	DecorateWeaponValentine_Text:SetText("")
	local ActionNum = DecoWeaponUI:GetDecoWeapActionNum(g_DestDecoWeaponLevelId[level])
		
	if ActionNum == 1 then
		DecorateWeaponValentine_ActionOne:Show()
		DecorateWeaponValentine_Text:SetText("#{MGCQ_161223_21}")
	elseif ActionNum == 2 then
		DecorateWeaponValentine_ActionOne:Show()
		DecorateWeaponValentine_ActionTwo:Show()
		DecorateWeaponValentine_Text:SetText("#{MGCQ_161223_21}")
	end
		
end

function DecorateWeaponValentine_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			DecorateWeaponValentine_FakeObject:RotateBeginEx("DecoWeapon_Player",-0.3);
		--向左旋转结束
		else
			DecorateWeaponValentine_FakeObject:RotateEndEx();
		end
	end
end

----------------------------------------------------------------------------------
function DecorateWeaponValentine_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			DecorateWeaponValentine_FakeObject:RotateBeginEx("DecoWeapon_Player", 0.3);
		--向右旋转结束
		else
			DecorateWeaponValentine_FakeObject:RotateEndEx();
		end
	end
end

function DecorateWeaponValentine_OK()
	local nSelIndex = DecorateWeaponValentine_List:GetSelectItem();
	--PushEvent("CONFIRM_ROSEWEAPON",ScriptGlobal_Format("#{MGCQ_161223_07}",g_DecorateWeaponName[nSelIndex]),nSelIndex)
	PushEvent("CONFIRM_ROSEWEAPON",ScriptGlobal_Format("#{MGCQ_161223_07}",g_DecorateWeaponName[nSelIndex]),nSelIndex,g_CurCommand,g_DecorateWeaponIDCur[nSelIndex])
end

function DecorateWeaponValentine_IsShow(weapid)
	if g_CurCommand == 892416 then
		for i=0,4 do
			if weapid == g_DecorateWeaponID[i].ID then
				return 1
			end
		end
	elseif g_CurCommand == 892462 then
		for i=0,table.getn(g_DecorateWeaponIDNew) do
			if weapid == g_DecorateWeaponIDNew[i].ID and g_DecorateWeaponIDNew[i].IsShow == 1 then
				return 1
			end
		end
	elseif g_CurCommand == 892666 then
		for i=0,5 do
			if weapid == g_DecorateWeaponID_2018[i].ID then
				return 1
			end
		end	
	elseif g_CurCommand == 892875 then
		for i=0,table.getn(g_DecorateWeaponIDLSYJ_2018) do
			if weapid == g_DecorateWeaponIDLSYJ_2018[i].ID and g_DecorateWeaponIDLSYJ_2018[i].IsShow == 1 then
				return 1
			end
		end
	elseif g_CurCommand == 893032 then
		for i=0,6 do
			if weapid == g_DecorateWeaponID_2019[i].ID then
				return 1
			end
		end	
	elseif g_CurCommand == 893133 then
		for i=0,table.getn(g_DecorateWeaponID_2019qixi) do
			if weapid == g_DecorateWeaponID_2019qixi[i].ID and g_DecorateWeaponID_2019qixi[i].IsShow == 1 then
				return 1
			end
		end
	elseif g_CurCommand == 888121 then
		for i=0,table.getn(g_DecorateWeaponID_2020qixi) do
			if weapid == g_DecorateWeaponID_2020qixi[i].ID and g_DecorateWeaponID_2020qixi[i].IsShow == 1 then
				return 1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
			end
		end
	elseif g_CurCommand == 888379 then
		for i=0,7 do
			if weapid == g_DecorateWeaponID_2021[i].ID then
				return 1
			end
		end	
	elseif g_CurCommand == 888135 then
		for i=0,table.getn(g_DecorateWeaponID_2021qixi) do
			if weapid == g_DecorateWeaponID_2021qixi[i].ID and g_DecorateWeaponID_2021qixi[i].IsShow == 1 then
				return 1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
			end
		end
	elseif g_CurCommand == 892758 then
		for i=0,8 do
			if weapid == g_DecorateWeaponID_2022[i].ID then
				return 1
			end
		end	
	elseif g_CurCommand == 998109 then
		for i=0,table.getn(g_DecorateWeaponID_2022qixi) do
			if weapid == g_DecorateWeaponID_2022qixi[i].ID and g_DecorateWeaponID_2022qixi[i].IsShow == 1 then
				return 1
			end
		end
	elseif g_CurCommand == 892763 then
		for i=0,9 do
			if weapid == g_DecorateWeaponID_2023[i].ID then
				return 1
			end
		end	
	elseif g_CurCommand == 998653 then
		for i=0,table.getn(g_DecorateWeaponID_2023qixi) do
			if weapid == g_DecorateWeaponID_2023qixi[i].ID and g_DecorateWeaponID_2023qixi[i].IsShow == 1 then
				return 1
			end
		end
	elseif g_CurCommand == 998664 then
		for i=0,table.getn(g_DecorateWeaponID_2023qixiEx) do
			if weapid == g_DecorateWeaponID_2023qixiEx[i].ID and g_DecorateWeaponID_2023qixiEx[i].IsShow == 1 then
				return 1
			end
		end
	elseif g_CurCommand == 892767 then
		for i=0,10 do
			if weapid == g_DecorateWeaponID_2024[i].ID then
				return 1
			end
		end	
	end
	return 0
end

function DecorateWeaponValentine_onAction(index)
	DecoWeaponUI:DecoWeaponAvatarPlayAction(g_DestDecoWeaponLevelId[g_DecorateWeaponValentine_CurCheck], index)
end

function DecorateWeaponValentine_ZoomIn()
	if g_DecorateWeaponValentine_CameraLevel < 1  or g_DecorateWeaponValentine_CameraLevel > 2then
		return
	end
	
	g_DecorateWeaponValentine_CameraLevel = g_DecorateWeaponValentine_CameraLevel - 1
	DecorateWeaponValentine_SetCameraPosition()
	DecorateWeaponValentine_UpdateZoomButton()
end

function DecorateWeaponValentine_ZoomOut()
	if g_DecorateWeaponValentine_CameraLevel < 0 or g_DecorateWeaponValentine_CameraLevel > 1 then
		return
	end
	
	g_DecorateWeaponValentine_CameraLevel = g_DecorateWeaponValentine_CameraLevel + 1
	DecorateWeaponValentine_SetCameraPosition()
	DecorateWeaponValentine_UpdateZoomButton()
end


function DecorateWeaponValentine_SetCameraPosition()
	if g_DecorateWeaponValentine_CameraLevel > -1 and g_DecorateWeaponValentine_CameraLevel < 3 then
		local fh, fd, fp = DecorateWeaponValentine_FakeObject:GetCameraEx()
		DecorateWeaponValentine_FakeObject:SetCameraEx(g_DecorateWeaponValentine_CameraPosition[g_DecorateWeaponValentine_CameraLevel].fHeight,g_DecorateWeaponValentine_CameraPosition[g_DecorateWeaponValentine_CameraLevel].fDistance,fp)
	end
end

function DecorateWeaponValentine_UpdateZoomButton()
	DecorateWeaponValentine_Model_ZoomIn:Enable()
	DecorateWeaponValentine_Model_ZoomOut:Enable()
	
	DecorateWeaponValentine_Model_ZoomIntips:SetToolTip("")
	DecorateWeaponValentine_Model_ZoomIntips:Hide()
	DecorateWeaponValentine_Model_ZoomOuttips:SetToolTip("")
	DecorateWeaponValentine_Model_ZoomOuttips:Hide()
	
	if g_DecorateWeaponValentine_CameraLevel == 0 then 
		DecorateWeaponValentine_Model_ZoomIn:Disable()
		DecorateWeaponValentine_Model_ZoomIntips:Show()
		DecorateWeaponValentine_Model_ZoomIntips:SetToolTip( "#{YBDYL_150703_01}" );
	elseif g_DecorateWeaponValentine_CameraLevel == 2 then
		DecorateWeaponValentine_Model_ZoomOut:Disable()
		DecorateWeaponValentine_Model_ZoomOuttips:Show()
		DecorateWeaponValentine_Model_ZoomOuttips:SetToolTip( "#{YBDYL_150703_03}" );
	end
end
