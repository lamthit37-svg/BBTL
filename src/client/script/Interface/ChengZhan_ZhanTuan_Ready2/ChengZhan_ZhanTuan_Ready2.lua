--!!!reloadscript =ChengZhan_ZhanTuan_Ready2

local g_ChengZhan_ZhanTuan_Ready2_Frame_UnifiedXPosition
local g_ChengZhan_ZhanTuan_Ready2_Frame_UnifiedYPosition

local MAX_OBJ_DISTANCE = 5.0;
local objCared = -1;
local g_Object = -1;

local g_ChengZhan_ZhanTuan_Ready2_nOpen = 1
local g_ChengZhan_ZhanTuan_Ready2_nChoice = 0
local g_ChengZhan_ZhanTuan_Ready2_nSelect = 0
local g_ChengZhan_ZhanTuan_Ready2_targetId = 0

--local m_UICheckButton = {};
local g_ChengZhan_ZhanTuan_Ready2_Select = {};
local g_ChengZhan_ZhanTuan_Ready2_SelectH = {};
local g_ChengZhan_ZhanTuan_Ready2_BaoMing = {};

local g_ChengZhan_ZhanTuan_Ready2_ItemId = 
{
	[1] = { [1] = 39925384, [2] = 39925385, [3] = 39925369, [4] = 39925383, [5] = 39925371, [6] = 39925382 },
	[2] = { [1] = 39925449, [2] = 39925451, [3] = 39925441, [4] = 39925447, [5] = 39925443, [6] = 39925445 },
	[3] = { [1] = 39925450, [2] = 39925452, [3] = 39925442, [4] = 39925448, [5] = 39925444, [6] = 39925446 },
}

local g_ChengZhan_ZhanTuan_Ready2_LF = {};
local g_ChengZhan_ZhanTuan_Ready2_JT = {};
local g_ChengZhan_ZhanTuan_Ready2_CJ = {};

--预加载函数，可以而且只能在这里注册脚本关心的事件
function ChengZhan_ZhanTuan_Ready2_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function ChengZhan_ZhanTuan_Ready2_OnLoad()
	-- 保存界面的默认相对位置
	g_ChengZhan_ZhanTuan_Ready2_Frame_UnifiedXPosition	= ChengZhan_ZhanTuan_Ready2_Frame:GetProperty("UnifiedXPosition");
	g_ChengZhan_ZhanTuan_Ready2_Frame_UnifiedYPosition	= ChengZhan_ZhanTuan_Ready2_Frame:GetProperty("UnifiedYPosition");

	-- m_UICheckButton[1] = ChengZhan_ZhanTuan_Ready2_Tips1
	-- m_UICheckButton[2] = ChengZhan_ZhanTuan_Ready2_Tips2
	-- m_UICheckButton[3] = ChengZhan_ZhanTuan_Ready2_Tips3

	g_ChengZhan_ZhanTuan_Ready2_Select[1] = ChengZhan_ZhanTuan_Ready2_BK1;
	g_ChengZhan_ZhanTuan_Ready2_Select[2] = ChengZhan_ZhanTuan_Ready2_BK2;
	g_ChengZhan_ZhanTuan_Ready2_Select[3] = ChengZhan_ZhanTuan_Ready2_BK3;

	g_ChengZhan_ZhanTuan_Ready2_SelectH[1] = ChengZhan_ZhanTuan_Ready2_BK1_H;
	g_ChengZhan_ZhanTuan_Ready2_SelectH[2] = ChengZhan_ZhanTuan_Ready2_BK2_H;
	g_ChengZhan_ZhanTuan_Ready2_SelectH[3] = ChengZhan_ZhanTuan_Ready2_BK3_H;

	g_ChengZhan_ZhanTuan_Ready2_BaoMing[1] = ChengZhan_ZhanTuan_Ready2_BaoMing1;
	g_ChengZhan_ZhanTuan_Ready2_BaoMing[2] = ChengZhan_ZhanTuan_Ready2_BaoMing2;
	g_ChengZhan_ZhanTuan_Ready2_BaoMing[3] = ChengZhan_ZhanTuan_Ready2_BaoMing3;

	g_ChengZhan_ZhanTuan_Ready2_LF[1] = ChengZhan_ZhanTuan_Ready2_LF_Item01;
	g_ChengZhan_ZhanTuan_Ready2_LF[2] = ChengZhan_ZhanTuan_Ready2_LF_Item02;
	g_ChengZhan_ZhanTuan_Ready2_LF[3] = ChengZhan_ZhanTuan_Ready2_LF_Item03;
	g_ChengZhan_ZhanTuan_Ready2_LF[4] = ChengZhan_ZhanTuan_Ready2_LF_Item04;
	g_ChengZhan_ZhanTuan_Ready2_LF[5] = ChengZhan_ZhanTuan_Ready2_LF_Item05;
	g_ChengZhan_ZhanTuan_Ready2_LF[6] = ChengZhan_ZhanTuan_Ready2_LF_Item06;

	g_ChengZhan_ZhanTuan_Ready2_CJ[1] = ChengZhan_ZhanTuan_Ready2_CJ_Item01;
	g_ChengZhan_ZhanTuan_Ready2_CJ[2] = ChengZhan_ZhanTuan_Ready2_CJ_Item02;
	g_ChengZhan_ZhanTuan_Ready2_CJ[3] = ChengZhan_ZhanTuan_Ready2_CJ_Item03;
	g_ChengZhan_ZhanTuan_Ready2_CJ[4] = ChengZhan_ZhanTuan_Ready2_CJ_Item04;
	g_ChengZhan_ZhanTuan_Ready2_CJ[5] = ChengZhan_ZhanTuan_Ready2_CJ_Item05;
	g_ChengZhan_ZhanTuan_Ready2_CJ[6] = ChengZhan_ZhanTuan_Ready2_CJ_Item06;

	g_ChengZhan_ZhanTuan_Ready2_JT[1] = ChengZhan_ZhanTuan_Ready2_JT_Item01;
	g_ChengZhan_ZhanTuan_Ready2_JT[2] = ChengZhan_ZhanTuan_Ready2_JT_Item02;
	g_ChengZhan_ZhanTuan_Ready2_JT[3] = ChengZhan_ZhanTuan_Ready2_JT_Item03;
	g_ChengZhan_ZhanTuan_Ready2_JT[4] = ChengZhan_ZhanTuan_Ready2_JT_Item04;
	g_ChengZhan_ZhanTuan_Ready2_JT[5] = ChengZhan_ZhanTuan_Ready2_JT_Item05;
	g_ChengZhan_ZhanTuan_Ready2_JT[6] = ChengZhan_ZhanTuan_Ready2_JT_Item06;

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ChengZhan_ZhanTuan_Ready2_ResetPos()
	ChengZhan_ZhanTuan_Ready2_Frame:SetProperty("UnifiedXPosition", g_ChengZhan_ZhanTuan_Ready2_Frame_UnifiedXPosition);
	ChengZhan_ZhanTuan_Ready2_Frame:SetProperty("UnifiedYPosition", g_ChengZhan_ZhanTuan_Ready2_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function ChengZhan_ZhanTuan_Ready2_OnEvent(event)
	if event == "UI_COMMAND" and (tonumber(arg0) == 90002601) then

		g_ChengZhan_ZhanTuan_Ready2_targetId = Get_XParam_INT(0);
		g_ChengZhan_ZhanTuan_Ready2_nChoice = Get_XParam_INT(1);
		g_ChengZhan_ZhanTuan_Ready2_nOpen = Get_XParam_INT(2);

		objCared = -1;
		objCared = DataPool : GetNPCIDByServerID(g_ChengZhan_ZhanTuan_Ready2_targetId);
		if objCared == -1 then
			PushDebugMessage("异常数据，请稍后再试！")
			return
		end

		ChengZhan_ZhanTuan_Ready2_BeginCareObject(objCared)

		if (this:IsVisible()) then
			ChengZhan_ZhanTuan_Ready2_Update()
			return
		end

		--打开界面
		ChengZhan_ZhanTuan_Ready2_Show()
		ChengZhan_ZhanTuan_Ready2_Update()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 90002602) then
		if (this:IsVisible()) then
			g_ChengZhan_ZhanTuan_Ready2_nChoice = Get_XParam_INT(0);
			g_ChengZhan_ZhanTuan_Ready2_nOpen = Get_XParam_INT(1);
			ChengZhan_ZhanTuan_Ready2_Update()
			return
		end
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end

		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			ChengZhan_ZhanTuan_Ready2_OnHide()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ChengZhan_ZhanTuan_Ready2_OnHide()
	elseif event == "ADJEST_UI_POS" then
		ChengZhan_ZhanTuan_Ready2_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ChengZhan_ZhanTuan_Ready2_ResetPos()
	end
end

--显示UI
function ChengZhan_ZhanTuan_Ready2_Show()
	this:Show()
end

--隐藏UI
function ChengZhan_ZhanTuan_Ready2_OnHide()
	ChengZhan_ZhanTuan_Ready2_StopCareObject()
	this:Hide()
end

function ChengZhan_ZhanTuan_Ready2_Update()

	-- for i=1, 3 do
	-- 	g_ChengZhan_ZhanTuan_Ready2_Select[i]:SetCheck(0);
	-- end
	for i=1,6 do
		g_ChengZhan_ZhanTuan_Ready2_LF[i]:SetActionItem(-1)
		local theAction = DataPool:CreateBindActionItemForShow(g_ChengZhan_ZhanTuan_Ready2_ItemId[1][i], 1)
		if theAction:GetID() ~= 0 then
			g_ChengZhan_ZhanTuan_Ready2_LF[i]:SetActionItem(theAction:GetID())
		end
	end
	for i=1,6 do
		g_ChengZhan_ZhanTuan_Ready2_CJ[i]:SetActionItem(-1)
		local theAction = DataPool:CreateBindActionItemForShow(g_ChengZhan_ZhanTuan_Ready2_ItemId[2][i], 1)
		if theAction:GetID() ~= 0 then
			g_ChengZhan_ZhanTuan_Ready2_CJ[i]:SetActionItem(theAction:GetID())
		end
	end
	for i=1,6 do
		g_ChengZhan_ZhanTuan_Ready2_JT[i]:SetActionItem(-1)
		local theAction = DataPool:CreateBindActionItemForShow(g_ChengZhan_ZhanTuan_Ready2_ItemId[3][i], 1)
		if theAction:GetID() ~= 0 then
			g_ChengZhan_ZhanTuan_Ready2_JT[i]:SetActionItem(theAction:GetID())
		end
	end


	if g_ChengZhan_ZhanTuan_Ready2_nChoice >= 1 and g_ChengZhan_ZhanTuan_Ready2_nChoice <= 3 then
		for i=1,3 do
			--g_ChengZhan_ZhanTuan_Ready2_Select[i]:Disable(); --置灰
			if i == g_ChengZhan_ZhanTuan_Ready2_nChoice then
				--m_UICheckButton[i]:Show()
				g_ChengZhan_ZhanTuan_Ready2_Select[i]:Hide()
				g_ChengZhan_ZhanTuan_Ready2_SelectH[i]:Show()
			else
				--m_UICheckButton[i]:Hide()
				g_ChengZhan_ZhanTuan_Ready2_Select[i]:Show()
				g_ChengZhan_ZhanTuan_Ready2_SelectH[i]:Hide()
			end
		end
		--ChengZhan_ZhanTuan_Ready2_BaoMing:Disable(); --置灰
	else
		for i=1,3 do
			--g_ChengZhan_ZhanTuan_Ready2_Select[i]:Enable();
			--m_UICheckButton[i]:Hide()
			g_ChengZhan_ZhanTuan_Ready2_Select[i]:Show()
			g_ChengZhan_ZhanTuan_Ready2_SelectH[i]:Hide()
		end
		--ChengZhan_ZhanTuan_Ready2_BaoMing:Enable();
	end

	if g_ChengZhan_ZhanTuan_Ready2_nOpen ~= 0 then
		g_ChengZhan_ZhanTuan_Ready2_BaoMing[1]:Enable();
		g_ChengZhan_ZhanTuan_Ready2_BaoMing[2]:Enable();
		g_ChengZhan_ZhanTuan_Ready2_BaoMing[3]:Enable();
	else
		g_ChengZhan_ZhanTuan_Ready2_BaoMing[1]:Disable(); --置灰
		g_ChengZhan_ZhanTuan_Ready2_BaoMing[2]:Disable(); --置灰
		g_ChengZhan_ZhanTuan_Ready2_BaoMing[3]:Disable(); --置灰
	end

end


function ChengZhan_ZhanTuan_Ready2_Close()
	ChengZhan_ZhanTuan_Ready2_OnHide()
end

-- function ChengZhan_ZhanTuan_Ready2_Clicked(nIndex)
-- 	-- 数据超过范围，返回
-- 	if(nIndex < 1 or nIndex > 3) then
-- 		return;
-- 	end

-- 	local i = 1;
-- 	for i=1, 3 do
-- 		if(i==nIndex) then
-- 			g_ChengZhan_ZhanTuan_Ready2_Select[i]:SetCheck(1);
-- 		else
-- 			g_ChengZhan_ZhanTuan_Ready2_Select[i]:SetCheck(0);
-- 		end
-- 	end

-- 	g_ChengZhan_ZhanTuan_Ready2_nSelect = nIndex
-- end

function ChengZhan_ZhanTuan_Ready2_BaoMing_Clicked(nIndex)
	-- 数据超过范围，返回
	if(nIndex < 1 or nIndex > 3) then
		return;
	end

	-- local i = 1;
	-- for i=1, 3 do
	-- 	if(i==nIndex) then
	-- 		g_ChengZhan_ZhanTuan_Ready2_Select[i]:SetCheck(1);
	-- 	else
	-- 		g_ChengZhan_ZhanTuan_Ready2_Select[i]:SetCheck(0);
	-- 	end
	-- end

	g_ChengZhan_ZhanTuan_Ready2_nSelect = nIndex

	Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "SignUp" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 900026 );											-- 脚本编号  
		Set_XSCRIPT_Parameter( 0, g_ChengZhan_ZhanTuan_Ready2_targetId );	
		Set_XSCRIPT_Parameter( 1, g_ChengZhan_ZhanTuan_Ready2_nSelect );			 
        Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数  
    Send_XSCRIPT()	
end

--=========================================================
--开始关心NPC
--=========================================================
function ChengZhan_ZhanTuan_Ready2_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "ChengZhan_ZhanTuan_Ready2");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "ChengZhan_ZhanTuan_Ready2")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function ChengZhan_ZhanTuan_Ready2_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "ChengZhan_ZhanTuan_Ready2");
		g_Object = -1;
	end
end

function ChengZhan_ZhanTuan_Ready2_Help()
	PushEvent("QUEST_HELPINFO", "#{ZTPVP_260515_267}")
end