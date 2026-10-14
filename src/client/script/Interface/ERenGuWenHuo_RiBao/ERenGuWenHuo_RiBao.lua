-- 2024Q3版本稳活活动
-- 江湖日报界面
--!!!reloadscript =ERenGuWenHuo_RiBao

local g_Frame_Pos = nil

local g_BadNum = 0
local g_GoodNum = 0
local g_Count = 0
local g_UICount = 3
local g_UIIndex = {0,0,0}--显示的任务索引
local g_UIState = {0,0,0}--是否显示任务按钮
local g_UIString = {"","",""}

local g_CtrlListText = {}
local g_CtrlListBtn = {}
local g_CtrlListImage = {}

local g_AutoNpcList =
{
	[1] = {x=236,z=360,sid=0,name="郑仁"},
	[2] = {x=307,z=313,sid=0,name="商会大使"},
	[3] = {x=381,z=212,sid=0,name="吴琐蔚"},
}

--=========
-- PreLoad
--=========
function ERenGuWenHuo_RiBao_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
end

--=========
-- OnLoad
--=========
function ERenGuWenHuo_RiBao_OnLoad()
	g_Frame_Pos = ERenGuWenHuo_RiBao_Frame:GetProperty("UnifiedPosition")
 	g_CtrlListText = {ERenGuWenHuo_RiBao_MissionText_1,ERenGuWenHuo_RiBao_MissionText_2,ERenGuWenHuo_RiBao_MissionText_3}
	g_CtrlListBtn = {ERenGuWenHuo_RiBao_MissionBtn_1,ERenGuWenHuo_RiBao_MissionBtn_2,ERenGuWenHuo_RiBao_MissionBtn_3}
	g_CtrlListImage = {ERenGuWenHuo_RiBao_MissionBtn_1_Finish,ERenGuWenHuo_RiBao_MissionBtn_2_Finish,ERenGuWenHuo_RiBao_MissionBtn_3_Finish}
end

--=========
-- OnEvent
--=========
function ERenGuWenHuo_RiBao_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99942201 )  then
		local flag = Get_XParam_INT(0)
		if flag == nil or flag <= 0 then
			ERenGuWenHuo_RiBao_Close()
		else
			g_BadNum = tonumber(Get_XParam_INT(1))
			g_GoodNum = tonumber(Get_XParam_INT(2))
			g_Count = tonumber(Get_XParam_INT(3))
			for i=1,table.getn(g_UIIndex) do
				g_UIIndex[i] = Get_XParam_INT(i+3)
			end
			for i=1,table.getn(g_UIState) do
				g_UIState[i] = Get_XParam_INT(i+6)
			end
			for i=1,table.getn(g_UIString) do
				g_UIString[i] = Get_XParam_STR(i-1)
			end			
			if flag == 1 then
				--显示界面
				this:Show()
				ERenGuWenHuo_RiBao_Open()
			elseif flag == 2 then
				--刷新界面
				if( this:IsVisible() ) then
					ERenGuWenHuo_RiBao_Open()
				end
			end
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99942803 )  then 
		--自动寻路
		local nIndex = tonumber(Get_XParam_INT(0))
		if nIndex ~= nil and nIndex > 0 then
			local tNpc = g_AutoNpcList[nIndex]
			if tNpc ~= nil then
				AutoRuntoTargetExWithName(tNpc.x,tNpc.z,tNpc.sid,tNpc.name)
			end
		end
	elseif event == "ADJEST_UI_POS" then
		ERenGuWenHuo_RiBao_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ERenGuWenHuo_RiBao_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ERenGuWenHuo_RiBao_Close()
	end
end

--=========
-- 重置
--=========
function ERenGuWenHuo_RiBao_On_ResetPos()
	ERenGuWenHuo_RiBao_Frame:SetProperty("UnifiedPosition", g_Frame_Pos)
end

--=========
-- 打开
--=========
function ERenGuWenHuo_RiBao_Open()
	--
	ERenGuWenHuo_RiBao_ShuaXinText:SetText(ScriptGlobal_Format("#{ERWH_240719_96}", g_Count))
	--
	for i=1,table.getn(g_UIString) do
		g_CtrlListText[i]:SetText(g_UIString[i])
		g_CtrlListBtn[i]:Hide()
		g_CtrlListImage[i]:Hide()
	end
	--
	local bShow = 0
	for i=1,g_UICount do
		if g_UIState[i] > 0 then
			g_CtrlListBtn[i]:Show()
			g_CtrlListImage[i]:Hide()
		else
			g_CtrlListBtn[i]:Hide()
			g_CtrlListImage[i]:Show()
			bShow = 1
		end
	end
	ERenGuWenHuo_ShowImage(bShow)
end

--=========
-- 显示善恶值
--=========
function ERenGuWenHuo_ShowImage(bShow)
	if bShow == 1 then
		if g_GoodNum == g_BadNum then--中立
			ERenGuWenHuo_RiBao_XiaNianProcess_ZhongLi:Show()
			ERenGuWenHuo_RiBao_XiaNianProcess_Shan:Hide()
			ERenGuWenHuo_RiBao_XiaNianProcess_E:Hide()
		elseif g_GoodNum > g_BadNum then--好
			ERenGuWenHuo_RiBao_XiaNianProcess_ZhongLi:Hide()
			ERenGuWenHuo_RiBao_XiaNianProcess_Shan:Show()
			ERenGuWenHuo_RiBao_XiaNianProcess_E:Hide()
		elseif g_BadNum > g_GoodNum then--坏
			ERenGuWenHuo_RiBao_XiaNianProcess_ZhongLi:Hide()
			ERenGuWenHuo_RiBao_XiaNianProcess_Shan:Hide()
			ERenGuWenHuo_RiBao_XiaNianProcess_E:Show()
		end
	else
		ERenGuWenHuo_RiBao_XiaNianProcess_ZhongLi:Hide()
		ERenGuWenHuo_RiBao_XiaNianProcess_Shan:Hide()
		ERenGuWenHuo_RiBao_XiaNianProcess_E:Hide()
	end
end

--=========
-- 关闭
--=========
function ERenGuWenHuo_RiBao_Close()
	this:Hide()
end

--=========
-- 点击前往按钮
--=========
function ERenGuWenHuo_RiBao_MissionBtn_Clicked(nIndex)
	if nIndex == nil then
		return
	end
	local mIndex = g_UIIndex[nIndex]
	if mIndex == nil or mIndex <= 0 then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AutoAccept")
		Set_XSCRIPT_ScriptID(999428)
		Set_XSCRIPT_Parameter(0,mIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	ERenGuWenHuo_RiBao_Close()
end
