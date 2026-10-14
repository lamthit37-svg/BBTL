local g_Bank_Frame_UnifiedPosition;

--功能按钮
local COMMAND_BUTTONS_NUM = 3;
local COMMAND_BUTTONS = {}

--页签及其编号
local PACK_BUTTONS_NUM = 5;
local PACK_BUTTONS = {};
local PACK_TIPS_BUTTON = {};
local ACCESS_PACK_BUTTONS = {};

--格子及其编号
local GRID_BUTTONS_NUM = 20;
local GRID_BUTTONS = {};

--当前打开的租赁箱
local g_CurrentRentBox = 1;
--权限界面页签
local g_CurrentAccessPage = 1;

local MAX_OBJ_DISTANCE = 3.0
local objCared = -1;

local ShowItemList = 0
local ShowAccessSet = 0
local ShowRecordList = 0

-- 每页显示的数量
local MESSAGE_EACH_PAGE = 10;
--记录当前页数
local g_CurrentRecordPage = 1;
-- 记录全部的页数
local g_AllRecordPage = 1;

--存权限
local SetAccess = 
{
	{ 0, 0, 0, 0, 0, 0, 0},
	{ 0, 0, 0, 0, 0, 0, 0},
	{ 0, 0, 0, 0, 0, 0, 0},
	{ 0, 0, 0, 0, 0, 0, 0},
	{ 0, 0, 0, 0, 0, 0, 0},
}

--取权限
local GetAccess = 
{
	{ 0, 0, 0, 0, 0, 0, 0},
	{ 0, 0, 0, 0, 0, 0, 0},
	{ 0, 0, 0, 0, 0, 0, 0},
	{ 0, 0, 0, 0, 0, 0, 0},
	{ 0, 0, 0, 0, 0, 0, 0},
}

local SetAccessCheckBox = {}
local GetAccessCheckBox	= {}
--===============================================
-- OnLoad()
--===============================================
function Banghui_Bank_PreLoad()

	this:RegisterEvent("OPEN_CITY_BANK")
	this:RegisterEvent("UPDATE_CITY_BANK")
	this:RegisterEvent("UPDATE_CITY_BANK_RECORD")
	this:RegisterEvent("UPDATE_CITY_BANK_ACCESS")
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
end
	
function Banghui_Bank_OnLoad()
	COMMAND_BUTTONS[1] = Banghui_Bank_QuChu;
	COMMAND_BUTTONS[2] = Banghui_Bank_Jilu;
	COMMAND_BUTTONS[3] = Banghui_Bank_Shezhi;
	
	GRID_BUTTONS[1]  = Banghui_Bank_Item1;
	GRID_BUTTONS[2]  = Banghui_Bank_Item2;
	GRID_BUTTONS[3]  = Banghui_Bank_Item3;
	GRID_BUTTONS[4]  = Banghui_Bank_Item4;
	GRID_BUTTONS[5]  = Banghui_Bank_Item5;
	GRID_BUTTONS[6]  = Banghui_Bank_Item6;
	GRID_BUTTONS[7]  = Banghui_Bank_Item7;
	GRID_BUTTONS[8]  = Banghui_Bank_Item8;
	GRID_BUTTONS[9]  = Banghui_Bank_Item9;
	GRID_BUTTONS[10] = Banghui_Bank_Item10;
	GRID_BUTTONS[11] = Banghui_Bank_Item11;
	GRID_BUTTONS[12] = Banghui_Bank_Item12;
	GRID_BUTTONS[13] = Banghui_Bank_Item13;
	GRID_BUTTONS[14] = Banghui_Bank_Item14;
	GRID_BUTTONS[15] = Banghui_Bank_Item15;
	GRID_BUTTONS[16] = Banghui_Bank_Item16;
	GRID_BUTTONS[17] = Banghui_Bank_Item17;
	GRID_BUTTONS[18] = Banghui_Bank_Item18;
	GRID_BUTTONS[19] = Banghui_Bank_Item19;
	GRID_BUTTONS[20] = Banghui_Bank_Item20;
										 
	PACK_BUTTONS[1]  = Banghui_Bank_patulousBox_1;
	PACK_BUTTONS[2]  = Banghui_Bank_patulousBox_2;
	PACK_BUTTONS[3]  = Banghui_Bank_patulousBox_3;
	PACK_BUTTONS[4]  = Banghui_Bank_patulousBox_4;
	PACK_BUTTONS[5]  = Banghui_Bank_patulousBox_5;
	
	PACK_TIPS_BUTTON[1] = Banghui_Bank_patulousBox1_bkTips
	PACK_TIPS_BUTTON[2] = Banghui_Bank_patulousBox2_bkTips
	PACK_TIPS_BUTTON[3] = Banghui_Bank_patulousBox3_bkTips
	PACK_TIPS_BUTTON[4] = Banghui_Bank_patulousBox4_bkTips
	PACK_TIPS_BUTTON[5] = Banghui_Bank_patulousBox5_bkTips
	
	SetAccessCheckBox[1] = Banghui_BankInstall_DX14
	SetAccessCheckBox[2] = Banghui_BankInstall_DX13
	SetAccessCheckBox[3] = Banghui_BankInstall_DX12
	SetAccessCheckBox[4] = Banghui_BankInstall_DX11
	SetAccessCheckBox[5] = Banghui_BankInstall_DX10
	SetAccessCheckBox[6] = Banghui_BankInstall_DX9
	SetAccessCheckBox[7] = Banghui_BankInstall_DX8
	
	GetAccessCheckBox[1] = Banghui_BankInstall_DX7
	GetAccessCheckBox[2] = Banghui_BankInstall_DX6
	GetAccessCheckBox[3] = Banghui_BankInstall_DX5
	GetAccessCheckBox[4] = Banghui_BankInstall_DX4
	GetAccessCheckBox[5] = Banghui_BankInstall_DX3
	GetAccessCheckBox[6] = Banghui_BankInstall_DX2
	GetAccessCheckBox[7] = Banghui_BankInstall_DX1
	
	ACCESS_PACK_BUTTONS[1] = Banghui_BankInstall_YE1
	ACCESS_PACK_BUTTONS[2] = Banghui_BankInstall_YE2
	ACCESS_PACK_BUTTONS[3] = Banghui_BankInstall_YE3
	ACCESS_PACK_BUTTONS[4] = Banghui_BankInstall_YE4
	ACCESS_PACK_BUTTONS[5] = Banghui_BankInstall_YE5
	
  g_Bank_Frame_UnifiedPosition=Banghui_Bank_Frame:GetProperty("UnifiedPosition");
  Banghui_Bank_Shezhi:Hide()
  Banghui_Bank_Xianshiqu:Hide()
end										


--===============================================
-- OnEvent
--===============================================
function Banghui_Bank_OnEvent(event)

	if(event == "OPEN_CITY_BANK") then
	
		this:Show();
		--关心NPC
		objCared = CityBank:GetNpcId();
		this:CareObject(objCared, 1, "CityBank");

		Banghui_Bank_Open()
		Banghui_Bank_QuChu_Clicked(0)
		
	elseif (event == "UPDATE_CITY_BANK") then
		if( ShowItemList and Banghui_Bank_Frame:IsVisible()) then
			Banghui_Bank_UpdateFrame(g_CurrentRentBox)
		end
		
	elseif (event == "UPDATE_CITY_BANK_RECORD") then
		if( ShowRecordList and Banghui_Bank_Frame:IsVisible()) then 
			g_CurrentRecordPage = tonumber(arg0) + 1
			Banghui_Bank_Update_Record()
		end
		
	elseif (event == "UPDATE_CITY_BANK_ACCESS") then
		if( ShowAccessSet and Banghui_Bank_Frame:IsVisible() ) then 
			Banghui_Bank_Shezhi_Click()
		end
	
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			Banghui_Bank_Close_Clicked()
		end
		
		-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		Banghui_Bank_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Banghui_Bank_Frame_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Banghui_Bank_Close_Clicked()
	end
end

function Banghui_Bank_Open()
		ShowItemList = 0
		ShowAccessSet = 0
		ShowRecordList = 0
		
		g_CurrentRentBox = 1;
		g_CurrentAccessPage = 1;
		g_CurrentRecordPage = 1;
end

--===============================================
-- Banghui_Bank_UpdateFrame
--===============================================
function Banghui_Bank_UpdateFrame(nIndex)
		local i=1;
		CityBank:SetCurRentIndex(nIndex);
		for i=1, PACK_BUTTONS_NUM do
			if(i==nIndex) then
				PACK_BUTTONS[i]:SetPushed(1);
			else
				PACK_BUTTONS[i]:SetPushed(0);
			end
		end
		
		local GuildLevel = CityBank:GetCityLevel() + 1;
		
		if GuildLevel > PACK_BUTTONS_NUM then
			GuildLevel = PACK_BUTTONS_NUM
		end
	
		for i=1, GuildLevel do
			PACK_BUTTONS[i]:Enable()
		end
		
		for i=1, GRID_BUTTONS_NUM do
			GRID_BUTTONS[i]:SetActionItem(-1);
			GRID_BUTTONS[i]:Enable();
		end

	--从数据池中使用数据填入背包内的物品
	local nActIndex = 0
	
	for i=1, GRID_BUTTONS_NUM  do
		local theAction = CityBank:EnumItem(nActIndex);
		nActIndex = nActIndex+1;

		if theAction:GetID() ~= 0 then
			GRID_BUTTONS[i]:SetActionItem(theAction:GetID());
		else
			GRID_BUTTONS[i]:SetActionItem(-1);
		end
	end
end

--===============================================
-- 点击页签的操作 
--===============================================
function Banghui_Bank_patulousBox_Clicked(nIndex)
	if nIndex == g_CurrentRentBox then
		return
	end
	
	local i = 1
	for i=1, GRID_BUTTONS_NUM do
		GRID_BUTTONS[i]:SetActionItem(-1);
		GRID_BUTTONS[i]:Enable();
	end
	
	for i=1, PACK_BUTTONS_NUM do
		PACK_BUTTONS[i]:SetPushed(0);
		PACK_BUTTONS[i]:Disable();
	end
	g_CurrentRentBox = nIndex
	CityBank:AcquireList(nIndex);
end

--===============================================
--显示帮会物品信息
--===============================================
function Banghui_Bank_Show_ItemList(bShow)
	if bShow == 1 then
		ShowItemList = 1
		Banghui_Bank_Shuomingqu:Show()
		Banghui_Bank_Item_Set:Show()
		Banghui_Bank_Text2:Show()
		Banghui_Bank_patulousBox_Set:Show()
		Banghui_Bank_Guanbi:Show()
		if( 1 == SystemSetup:IsClassic() ) then
			Banghui_Bank_Blank:Show()
		else
			Banghui_Bank__Line:Show()
		end
		Banghui_Bank_Shuomingqu:SetText("#{BHYH_140808_17}")
	else
		ShowItemList = 0
		Banghui_Bank_Shuomingqu:Hide()
		Banghui_Bank_Item_Set:Hide()
		Banghui_Bank_Text2:Hide()
		Banghui_Bank_patulousBox_Set:Hide()
		Banghui_Bank_Guanbi:Hide()
		if( 1 == SystemSetup:IsClassic() ) then
			Banghui_Bank_Blank:Hide()
		else
			Banghui_Bank__Line:Hide()
		end
	end
end

--===============================================
--显示记录相关信息
--===============================================
function Banghui_Bank_Show_RecordList(bShow)
	if bShow == 1 then
		ShowRecordList = 1
		Banghui_BankRecord_JiLuqu:Show()
		Banghui_BankRecord_Page:Show()
		Banghui_BankRecord_JiLuquK:Show()
	else
		ShowRecordList = 0
		Banghui_BankRecord_JiLuqu:Hide()
		Banghui_BankRecord_Page:Hide()
		Banghui_BankRecord_JiLuquK:Hide()
	end
end

--==================================================
--显示权限相关信息
--==================================================
function Banghui_Bank_Show_AccessSet(bShow)
	if bShow == 1 then
		ShowAccessSet = 1
		Banghui_BankInstall_SheZhiQuYu:Show()
		Banghui_Bank_Retain:Show()
		Banghui_Bank_Guanbi:Show()
		Banghui_Bank_Shuomingqu:Show()
		if( 1 == SystemSetup:IsClassic() ) then
			Banghui_Bank_Blank:Show()
			Banghui_Bank_Blank1:Show()
		end
		Banghui_BankInstall_SheZhiQuK:Show()
		Banghui_Bank_Shuomingqu:SetText("#{BHYH_140808_51}")
	else
		ShowAccessSet = 0
		Banghui_BankInstall_SheZhiQuYu:Hide()
		Banghui_Bank_Retain:Hide()
		Banghui_Bank_Guanbi:Hide()
		Banghui_Bank_Shuomingqu:Hide()
		if( 1 == SystemSetup:IsClassic() ) then
			Banghui_Bank_Blank:Hide()
			Banghui_Bank_Blank1:Hide()
		end
		Banghui_BankInstall_SheZhiQuK:Hide()
	end
end

function Banghui_Bank_QuChu_Clicked(bSend)
	if(ShowItemList == 0 ) then		
		Banghui_Bank_Show_RecordList(0)
		Banghui_Bank_Show_AccessSet(0)
		Banghui_Bank_Show_ItemList(1)
		
		local i=1;
		for i=1, PACK_BUTTONS_NUM do
			PACK_TIPS_BUTTON[i]:Show()
			PACK_BUTTONS[i]:Disable()
		end
		
		local GuildLevel = CityBank:GetCityLevel() + 1;
		
		if GuildLevel > PACK_BUTTONS_NUM then
			GuildLevel = PACK_BUTTONS_NUM
		end
	
		for i=1, GuildLevel do
			PACK_TIPS_BUTTON[i]:Hide()
			PACK_BUTTONS[i]:Enable()
		end
	
		if bSend == 1 then
			Banghui_Bank_patulousBox_Clicked(1)
		else
			g_CurrentRentBox = 1;
			Banghui_Bank_UpdateFrame(1);
		end
		
	end
end

function Banghui_Bank_Shezhi_Click()
	if ShowAccessSet == 0 then
		local i=1;
		for i=1, PACK_BUTTONS_NUM  do
			SetAccess[i][1], SetAccess[i][2], SetAccess[i][3], SetAccess[i][4], SetAccess[i][5], SetAccess[i][6], SetAccess[i][7] = CityBank:Get_SetAccess(i)
			GetAccess[i][1], GetAccess[i][2], GetAccess[i][3], GetAccess[i][4], GetAccess[i][5], GetAccess[i][6], GetAccess[i][7] = CityBank:Get_GetAccess(i)
		end
		
		Banghui_Bank_Show_RecordList(0)
		Banghui_Bank_Show_ItemList(0)
		Banghui_Bank_Show_AccessSet(1)
		
		Banghui_BankInstall_YE_Click(1)
	end
end

function Banghui_BankInstall_YE_Click(nIndex)
	if nIndex ~= g_CurrentAccessPage then
		--先保持下前一页的设置
		local i=1;
		for i = 1, 7 do
			SetAccess[g_CurrentAccessPage][i] = SetAccessCheckBox[i]:GetCheck()
			GetAccess[g_CurrentAccessPage][i] = GetAccessCheckBox[i]:GetCheck()
		end
	end
	
	g_CurrentAccessPage = nIndex
	Bankghui_Bank_UpdateAccess(nIndex)
end

function Bankghui_Bank_UpdateAccess(nIndex)
	if nIndex < 1 or nIndex > PACK_BUTTONS_NUM then
		return
	end
		
	local i=1;
	for i=1, PACK_BUTTONS_NUM do
		if(i==nIndex) then
				ACCESS_PACK_BUTTONS[i]:SetCheck(1);
		else
				ACCESS_PACK_BUTTONS[i]:SetCheck(0);
		end
	end
	
	for i=1, PACK_BUTTONS_NUM do
		ACCESS_PACK_BUTTONS[i]:Disable();
	end
		
	local GuildLevel = CityBank:GetCityLevel() + 1;
		
	if GuildLevel > PACK_BUTTONS_NUM then
		GuildLevel = PACK_BUTTONS_NUM
	end
	
	for i=1, GuildLevel do
		ACCESS_PACK_BUTTONS[i]:Enable();
	end
	
	for i = 1, 7 do
			SetAccessCheckBox[i]:SetCheck(SetAccess[nIndex][i])
			GetAccessCheckBox[i]:SetCheck(GetAccess[nIndex][i])
	end
	
	--策划要求的特写
	Banghui_BankInstall_DX1:SetCheck(1)
	Banghui_BankInstall_DX1:Disable()
	
	Banghui_BankInstall_DX2:SetCheck(1)
	Banghui_BankInstall_DX2:Disable()
	
	Banghui_BankInstall_DX7:SetCheck(0)
	Banghui_BankInstall_DX7:Disable()
	
	Banghui_BankInstall_DX8:SetCheck(1)
	Banghui_BankInstall_DX8:Disable()
	
	Banghui_BankInstall_DX9:SetCheck(1)
	Banghui_BankInstall_DX9:Disable()
	
	Banghui_BankInstall_DX14:SetCheck(0)
	Banghui_BankInstall_DX14:Disable()
end

function Banghui_Bank_Retain_Clicked()
	local i=1;
	for i = 1, 7 do
		SetAccess[g_CurrentAccessPage][i] = SetAccessCheckBox[i]:GetCheck()
		GetAccess[g_CurrentAccessPage][i] = GetAccessCheckBox[i]:GetCheck()
	end
	
	for i = 1, PACK_BUTTONS_NUM do
		CityBank:Set_SetAccess( i, SetAccess[i][1], SetAccess[i][2], SetAccess[i][3], SetAccess[i][4], SetAccess[i][5], SetAccess[i][6], SetAccess[i][7] )
		CityBank:Set_GetAccess( i, GetAccess[i][1], GetAccess[i][2], GetAccess[i][3], GetAccess[i][4], GetAccess[i][5], GetAccess[i][6], GetAccess[i][7] )
	end
	
	CityBank:SendAccess()
end

--===============================================
-- 点击关闭
--===============================================
function Banghui_Bank_Close_Clicked()
	this:CareObject(objCared, 0, "CityBank");
	this:Hide();
	CityBank:Close();
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Banghui_Bank_Frame_On_ResetPos()
  Banghui_Bank_Frame:SetProperty("UnifiedPosition", g_Bank_Frame_UnifiedPosition);
end

function Banghui_Bank_Jilu_Clicked()
	if ShowRecordList == 0 then
		Banghui_Bank_Show_AccessSet(0)
		Banghui_Bank_Show_ItemList(0)
		Banghui_Bank_Show_RecordList(1)
		
		g_CurrentRecordPage = 1
		CityBank:OpenRecord(g_CurrentRecordPage)
		
		Banghui_BankRecord_JiLuqu:ClearAllElement()
		Banghui_BankRecord_UpPage:Disable()
		Banghui_BankRecord_DownPage:Disable()
		
		Banghui_BankRecord_ShuzhiPage:SetText("1/1")
	end
end

function Banghui_Bank_Update_Record()
	Banghui_BankRecord_JiLuqu:ClearAllElement()
	local nMessageNum = CityBank:GetCurPageRecordNum();
	
	g_AllRecordPage = math.floor((CityBank:GetRecordNum()-1)/MESSAGE_EACH_PAGE)+1;
	
	--  每一页显示最多10个
	local szInfo;
	local i=1;
	for i=0, nMessageNum-1 do
		szInfo = CityBank:EnumMessage(i);
		Banghui_BankRecord_JiLuqu:AddTextElement(szInfo);
	end
	
	Banghui_BankRecord_UpPage:Enable();
	Banghui_BankRecord_DownPage:Enable();
	
	if( g_CurrentRecordPage == 1 )  then
		Banghui_BankRecord_UpPage:Disable();
	end
	
	if( g_CurrentRecordPage == g_AllRecordPage ) then
		Banghui_BankRecord_DownPage:Disable();
	end
	
	local strPageNum = string.format( "%d/%d", g_CurrentRecordPage, g_AllRecordPage )
	Banghui_BankRecord_ShuzhiPage:SetText(strPageNum)
end

function Banghui_BankRecord_UpPage_Clicked()
	Banghui_BankRecord_UpPage:Disable()
	Banghui_BankRecord_DownPage:Disable()
	CityBank:OpenRecord(g_CurrentRecordPage - 1)
end

function Banghui_BankRecord_DownPage_Clicked()
	Banghui_BankRecord_UpPage:Disable()
	Banghui_BankRecord_DownPage:Disable()
	CityBank:OpenRecord(g_CurrentRecordPage + 1)
end


