--!!!reloadscript =ChengZhan_ZhanTuan_Ready

local g_ChengZhan_ZhanTuan_Ready_Frame_UnifiedXPosition
local g_ChengZhan_ZhanTuan_Ready_Frame_UnifiedYPosition
--local g_ChengZhan_ZhanTuan_Ready_Mini = 0

local m_UICheckButton = nil
local m_UITextButton = nil

local g_ChengZhan_ZhanTuan_Ready_Step = 0
local g_ChengZhan_ZhanTuan_Ready_nTick = 0
local g_ChengZhan_ZhanTuan_Ready_nChoice = 0

local g_ChengZhan_ZhanTuan_Ready_nZhanTuanID = {}	
local g_ChengZhan_ZhanTuan_Ready_nGuildName = {}	

local g_ChengZhan_ZhanTuan_Ready_ZhanTuanTips = 
{
	[1] = "#{ZTPVP_260515_15}", --1号战团
	[2] = "#{ZTPVP_260515_16}", --2号战团
	[3] = "#{ZTPVP_260515_17}", --3号战团
	[4] = "#{ZTPVP_260515_18}", --4号战团
	[5] = "#{ZTPVP_260515_19}", --5号战团
}
local g_ChengZhan_ZhanTuan_Ready_ChoiceTips = 
{
	[0] = "#{ZTPVP_260515_23}", --未选择
	[1] = "#{ZTPVP_260515_20}", --1号战团
	[2] = "#{ZTPVP_260515_21}", --2号战团
	[3] = "#{ZTPVP_260515_22}", --3号战团
}

local g_ChengZhan_ZhanTuan_Ready_ItemId = 
{
	[1] = { [1] = 39925384, [2] = 39925385, [3] = 39925369, [4] = 39925383, [5] = 39925371, [6] = 39925382 },
	[2] = { [1] = 39925449, [2] = 39925451, [3] = 39925441, [4] = 39925447, [5] = 39925443, [6] = 39925445 },
	[3] = { [1] = 39925450, [2] = 39925452, [3] = 39925442, [4] = 39925448, [5] = 39925444, [6] = 39925446 },
}

local g_ChengZhan_ZhanTuan_Ready_LF = {};
local g_ChengZhan_ZhanTuan_Ready_JT = {};
local g_ChengZhan_ZhanTuan_Ready_CJ = {};

--预加载函数，可以而且只能在这里注册脚本关心的事件
function ChengZhan_ZhanTuan_Ready_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function ChengZhan_ZhanTuan_Ready_OnLoad()
	-- 保存界面的默认相对位置
	g_ChengZhan_ZhanTuan_Ready_Frame_UnifiedXPosition	= ChengZhan_ZhanTuan_Ready_Frame:GetProperty("UnifiedXPosition");
	g_ChengZhan_ZhanTuan_Ready_Frame_UnifiedYPosition	= ChengZhan_ZhanTuan_Ready_Frame:GetProperty("UnifiedYPosition");

	m_UICheckButton = {}
	m_UICheckButton[1] = ChengZhan_ZhanTuan_Ready_Tips1
	m_UICheckButton[2] = ChengZhan_ZhanTuan_Ready_Tips2
	m_UICheckButton[3] = ChengZhan_ZhanTuan_Ready_Tips3

	m_UITextButton = {}
	m_UITextButton[1] = ChengZhan_ZhanTuan_Ready_Text1
	m_UITextButton[2] = ChengZhan_ZhanTuan_Ready_Text2
	m_UITextButton[3] = ChengZhan_ZhanTuan_Ready_Text3

	g_ChengZhan_ZhanTuan_Ready_LF[1] = ChengZhan_ZhanTuan_Ready_LF_Item01;
	g_ChengZhan_ZhanTuan_Ready_LF[2] = ChengZhan_ZhanTuan_Ready_LF_Item02;
	g_ChengZhan_ZhanTuan_Ready_LF[3] = ChengZhan_ZhanTuan_Ready_LF_Item03;
	g_ChengZhan_ZhanTuan_Ready_LF[4] = ChengZhan_ZhanTuan_Ready_LF_Item04;
	g_ChengZhan_ZhanTuan_Ready_LF[5] = ChengZhan_ZhanTuan_Ready_LF_Item05;
	g_ChengZhan_ZhanTuan_Ready_LF[6] = ChengZhan_ZhanTuan_Ready_LF_Item06;

	g_ChengZhan_ZhanTuan_Ready_CJ[1] = ChengZhan_ZhanTuan_Ready_CJ_Item01;
	g_ChengZhan_ZhanTuan_Ready_CJ[2] = ChengZhan_ZhanTuan_Ready_CJ_Item02;
	g_ChengZhan_ZhanTuan_Ready_CJ[3] = ChengZhan_ZhanTuan_Ready_CJ_Item03;
	g_ChengZhan_ZhanTuan_Ready_CJ[4] = ChengZhan_ZhanTuan_Ready_CJ_Item04;
	g_ChengZhan_ZhanTuan_Ready_CJ[5] = ChengZhan_ZhanTuan_Ready_CJ_Item05;
	g_ChengZhan_ZhanTuan_Ready_CJ[6] = ChengZhan_ZhanTuan_Ready_CJ_Item06;

	g_ChengZhan_ZhanTuan_Ready_JT[1] = ChengZhan_ZhanTuan_Ready_JT_Item01;
	g_ChengZhan_ZhanTuan_Ready_JT[2] = ChengZhan_ZhanTuan_Ready_JT_Item02;
	g_ChengZhan_ZhanTuan_Ready_JT[3] = ChengZhan_ZhanTuan_Ready_JT_Item03;
	g_ChengZhan_ZhanTuan_Ready_JT[4] = ChengZhan_ZhanTuan_Ready_JT_Item04;
	g_ChengZhan_ZhanTuan_Ready_JT[5] = ChengZhan_ZhanTuan_Ready_JT_Item05;
	g_ChengZhan_ZhanTuan_Ready_JT[6] = ChengZhan_ZhanTuan_Ready_JT_Item06;
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ChengZhan_ZhanTuan_Ready_ResetPos()
	ChengZhan_ZhanTuan_Ready_Frame:SetProperty("UnifiedXPosition", g_ChengZhan_ZhanTuan_Ready_Frame_UnifiedXPosition);
	ChengZhan_ZhanTuan_Ready_Frame:SetProperty("UnifiedYPosition", g_ChengZhan_ZhanTuan_Ready_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function ChengZhan_ZhanTuan_Ready_OnEvent(event)
	if event == "UI_COMMAND" and (tonumber(arg0) == 90001601) then
		g_ChengZhan_ZhanTuan_Ready_Step = Get_XParam_INT(0);
		g_ChengZhan_ZhanTuan_Ready_nTick = Get_XParam_INT(1);
		g_ChengZhan_ZhanTuan_Ready_nChoice = Get_XParam_INT(2);
		g_ChengZhan_ZhanTuan_Ready_nZhanTuanID[1] = Get_XParam_INT(3);
		g_ChengZhan_ZhanTuan_Ready_nZhanTuanID[2] = Get_XParam_INT(4);
		g_ChengZhan_ZhanTuan_Ready_nZhanTuanID[3] = Get_XParam_INT(5);
		g_ChengZhan_ZhanTuan_Ready_nGuildName[1] = Get_XParam_STR(0);
		g_ChengZhan_ZhanTuan_Ready_nGuildName[2] = Get_XParam_STR(1);
		g_ChengZhan_ZhanTuan_Ready_nGuildName[3] = Get_XParam_STR(2);

		if g_ChengZhan_ZhanTuan_Ready_Step == -1 then
			ChengZhan_ZhanTuan_Ready_OnHide()
			return
		end

		if (this:IsVisible()) then
			ChengZhan_ZhanTuan_Ready_Update()
			return
		end
		--打开界面
		ChengZhan_ZhanTuan_Ready_Show()
		ChengZhan_ZhanTuan_Ready_Update()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ChengZhan_ZhanTuan_Ready_OnHide()
	elseif event == "ADJEST_UI_POS" then
		ChengZhan_ZhanTuan_Ready_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ChengZhan_ZhanTuan_Ready_ResetPos()
	end
end

--显示UI
function ChengZhan_ZhanTuan_Ready_Show()
	--g_ChengZhan_ZhanTuan_Ready_Mini = 0
	this:Show()
end

--隐藏UI
function ChengZhan_ZhanTuan_Ready_OnHide()
	this:Hide()
end

function ChengZhan_ZhanTuan_Ready_Update()

	for i=1,6 do
		g_ChengZhan_ZhanTuan_Ready_LF[i]:SetActionItem(-1)
		local theAction = DataPool:CreateBindActionItemForShow(g_ChengZhan_ZhanTuan_Ready_ItemId[1][i], 1)
		if theAction:GetID() ~= 0 then
			g_ChengZhan_ZhanTuan_Ready_LF[i]:SetActionItem(theAction:GetID())
		end
	end
	for i=1,6 do
		g_ChengZhan_ZhanTuan_Ready_CJ[i]:SetActionItem(-1)
		local theAction = DataPool:CreateBindActionItemForShow(g_ChengZhan_ZhanTuan_Ready_ItemId[2][i], 1)
		if theAction:GetID() ~= 0 then
			g_ChengZhan_ZhanTuan_Ready_CJ[i]:SetActionItem(theAction:GetID())
		end
	end
	for i=1,6 do
		g_ChengZhan_ZhanTuan_Ready_JT[i]:SetActionItem(-1)
		local theAction = DataPool:CreateBindActionItemForShow(g_ChengZhan_ZhanTuan_Ready_ItemId[3][i], 1)
		if theAction:GetID() ~= 0 then
			g_ChengZhan_ZhanTuan_Ready_JT[i]:SetActionItem(theAction:GetID())
		end
	end

	local nShowTips = 0
	for i=1,3 do
		if g_ChengZhan_ZhanTuan_Ready_nChoice == i then
			nShowTips = i
			m_UICheckButton[i]:Show()
		else
			m_UICheckButton[i]:Hide()
		end
	end
	for i=1,3 do
		local nZhanTuanID = g_ChengZhan_ZhanTuan_Ready_nZhanTuanID[i]
		if nZhanTuanID >= 1 and nZhanTuanID <= 5 then
			m_UITextButton[i]:SetText(ScriptGlobal_Format("#{ZTPVP_260515_14}",g_ChengZhan_ZhanTuan_Ready_nGuildName[i]))
		else
			m_UITextButton[i]:SetText("#{ZTPVP_260515_68}") --未选择
		end
	end
	local nTick = g_ChengZhan_ZhanTuan_Ready_nTick
	if nTick <= 0 then
		nTick = 0
	end
	if g_ChengZhan_ZhanTuan_Ready_Step == 1 then
		ChengZhan_ZhanTuan_Ready_Timer:SetText(ScriptGlobal_Format("#{ZTPVP_260515_66}",nTick)) --选择
	else
		ChengZhan_ZhanTuan_Ready_Timer:SetText(ScriptGlobal_Format("#{ZTPVP_260515_67}",nTick)) --进场
	end

	--ChengZhan_ZhanTuan_Ready_Mini_Point:SetText(g_ChengZhan_ZhanTuan_Ready_ChoiceTips[nShowTips]) --未选择

	-- if g_ChengZhan_ZhanTuan_Ready_Mini == 0 then
	-- 	ChengZhan_ZhanTuan_Ready_FrameBk:Show()
	-- 	FChengZhan_ZhanTuan_Ready_Mini_Frame:Hide()
	-- else
	-- 	ChengZhan_ZhanTuan_Ready_FrameBk:Hide()
	-- 	FChengZhan_ZhanTuan_Ready_Mini_Frame:Show()
	-- end
end


-- function ChengZhan_ZhanTuan_Ready_CloseClicked()
-- 	if g_ChengZhan_ZhanTuan_Ready_Mini == 0 then
-- 		g_ChengZhan_ZhanTuan_Ready_Mini = 1
-- 		ChengZhan_ZhanTuan_Ready_FrameBk:Hide()
-- 		FChengZhan_ZhanTuan_Ready_Mini_Frame:Show()
-- 	else
-- 		g_ChengZhan_ZhanTuan_Ready_Mini = 0
-- 		ChengZhan_ZhanTuan_Ready_FrameBk:Show()
-- 		FChengZhan_ZhanTuan_Ready_Mini_Frame:Hide()
-- 	end
-- end

function ChengZhan_ZhanTuan_Ready_Help()
	PushEvent("QUEST_HELPINFO", "#{ZTPVP_260515_267}")
end