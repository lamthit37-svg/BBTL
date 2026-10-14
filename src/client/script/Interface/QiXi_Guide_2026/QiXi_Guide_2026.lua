
--QiXi_Guide_2026.lua
local g_QiXi_Guide_2026_Frame_UnifiedPosition
local g_QiXi_Guide_2026_Event = {
	--begtime-endtime 活动总持续时间 只是用来计算悬浮提示用的
	--btntips_unbeg   活动暂未开启的按钮悬浮提示
	--btntips_doing   点击后可参与活动的按钮悬浮提示
	--btntips_end     活动已结束的按钮悬浮提示
	[1] = { begtime = 20260813, endtime = 20260909, btntips_unbeg = "#{QXZH_250528_07}", btntips_doing = "#{QXZH_250528_08}", btntips_end = "#{QXZH_250528_09}", }, --七夕商店
	[2] = { begtime = 20260813, endtime = 20260902, btntips_unbeg = "#{QXZH_250528_07}", btntips_doing = "#{QXZH_250528_08}", btntips_end = "#{QXZH_250528_09}", }, --情寄虞兮//种花
	[3] = { begtime = 20260813, endtime = 20260902, btntips_unbeg = "#{QXZH_250528_07}", btntips_doing = "#{QXZH_250528_08}", btntips_end = "#{QXZH_250528_09}", }, --霸王别姬颂千年//戏曲
	[4] = { begtime = 20260813, endtime = 20260902, btntips_unbeg = "#{QXFB_260529_297}", btntips_doing = "#{QXFB_260529_298}", btntips_end = "#{QXFB_260529_299}", }, --PVE副本
	[5] = { begtime = 20260813, endtime = 20260902, btntips_unbeg = "#{QXZH_250528_07}", btntips_doing = "#{QXZH_250528_08}", btntips_end = "#{QXZH_250528_09}", }, --PVP
	[6] = { begtime = 20260813, endtime = 20260902, btntips_unbeg = "#{QXZH_250528_07}", btntips_doing = "#{QXZH_250528_08}", btntips_end = "#{QXZH_250528_09}", }, --红线相忆礼随心//结婚回馈
	[7] = { begtime = 20260813, endtime = 20260902, btntips_unbeg = "#{QXZH_250528_07}", btntips_doing = "#{QXZH_250528_08}", btntips_end = "#{QXZH_250528_09}", }, --
}

local g_QiXi_Guide_2026_Button_Guide = { 1, 1, 1, 1, 1, 1, 1, }
local g_QiXi_Guide_2026_Tips_Guide = { 0, 0, 0, 0, 0, 0, 0, }

local g_QiXi_Guide_2026_Button = {}
local g_QiXi_Guide_2026_Tip = {}

local g_QiXi_Guide_2026_UICOM = 89377601
local g_QiXi_Guide_2026_QuickEnterId = 89

local g_QiXi_Guide_2026_Process_Goto = {}
local g_QiXi_Guide_2026_Process_Finished = {}
local g_QiXi_Guide_2026_Process_GotoTips = {}
local g_QiXi_Guide_2026_Process_Locked = {}

local g_QiXi_Guide_2026_Process = {}
local g_QiXi_Guide_2026_ProcessTips = {0,0,0,0}
local g_QiXi_Guide_2026_Flag = 0
local g_QiXi_Guide_2026_Tips = 0
local g_QiXi_Guide_2026_DaiBiLimit = 0
local g_QiXi_Guide_2026_Libao = 0
local g_QiXi_Guide_2026_State = 0
local g_QiXi_Guide_2026_ProcessFlags = {0,0,0,0}
local g_QiXi_Guide_2026_NpcList = {
[1] = { SceneResId = 1075, posX = 205, posZ = 187, name = "工匠"},
[2] = { SceneResId = 1075, posX = 177, posZ = 137, name = "乐师"},
[3] = { SceneResId = 1075, posX = 121, posZ = 137, name = "卖花女"},
[4] = { SceneResId = 1075, posX = 112, posZ = 47, name = "史官"},
}

function QiXi_Guide_2026_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)

end

function QiXi_Guide_2026_OnLoad()

	QiXi_Guide_2026_LoadControl()
	g_QiXi_Guide_2026_Frame_UnifiedPosition = QiXi_Guide_2026_Frame:GetProperty("UnifiedPosition")
	
end

-- 装载控件
function QiXi_Guide_2026_LoadControl()

	g_QiXi_Guide_2026_Button[1] = QiXi_Guide_2026_Action1
	g_QiXi_Guide_2026_Button[2] = QiXi_Guide_2026_Action2
	g_QiXi_Guide_2026_Button[3] = QiXi_Guide_2026_Action3
	g_QiXi_Guide_2026_Button[4] = QiXi_Guide_2026_Action4
	g_QiXi_Guide_2026_Button[5] = QiXi_Guide_2026_Action5
	g_QiXi_Guide_2026_Button[6] = QiXi_Guide_2026_Action6
	g_QiXi_Guide_2026_Button[7] = QiXi_Guide_2026_Action7

	g_QiXi_Guide_2026_Tip[1] = QiXi_Guide_2026_ActionTips1
	g_QiXi_Guide_2026_Tip[2] = QiXi_Guide_2026_ActionTips2
	g_QiXi_Guide_2026_Tip[3] = QiXi_Guide_2026_ActionTips3
	g_QiXi_Guide_2026_Tip[4] = QiXi_Guide_2026_ActionTips4
	g_QiXi_Guide_2026_Tip[5] = QiXi_Guide_2026_ActionTips5
	g_QiXi_Guide_2026_Tip[6] = QiXi_Guide_2026_ActionTips6
	g_QiXi_Guide_2026_Tip[7] = QiXi_Guide_2026_ActionTips7

	g_QiXi_Guide_2026_Process_Goto[1] = QiXi_Guide_2026_Stage_Goto1
	g_QiXi_Guide_2026_Process_Goto[2] = QiXi_Guide_2026_Stage_Goto2
	g_QiXi_Guide_2026_Process_Goto[3] = QiXi_Guide_2026_Stage_Goto3
	g_QiXi_Guide_2026_Process_Goto[4] = QiXi_Guide_2026_Stage_Goto4
	
	g_QiXi_Guide_2026_Process_Finished[1] = QiXi_Guide_2026_Stage_ItemFinished1
	g_QiXi_Guide_2026_Process_Finished[2] = QiXi_Guide_2026_Stage_ItemFinished2
	g_QiXi_Guide_2026_Process_Finished[3] = QiXi_Guide_2026_Stage_ItemFinished3
	g_QiXi_Guide_2026_Process_Finished[4] = QiXi_Guide_2026_Stage_ItemFinished4
	
	g_QiXi_Guide_2026_Process_Locked[1] = QiXi_Guide_2026_Stage_ItemLocked1
	g_QiXi_Guide_2026_Process_Locked[2] = QiXi_Guide_2026_Stage_ItemLocked2
	g_QiXi_Guide_2026_Process_Locked[3] = QiXi_Guide_2026_Stage_ItemLocked3
	g_QiXi_Guide_2026_Process_Locked[4] = QiXi_Guide_2026_Stage_ItemLocked4
	
	g_QiXi_Guide_2026_Process_GotoTips[1] = QiXi_Guide_2026_Stage_GotoTips1
	g_QiXi_Guide_2026_Process_GotoTips[2] = QiXi_Guide_2026_Stage_GotoTips2
	g_QiXi_Guide_2026_Process_GotoTips[3] = QiXi_Guide_2026_Stage_GotoTips3
	g_QiXi_Guide_2026_Process_GotoTips[4] = QiXi_Guide_2026_Stage_GotoTips4
	
end

-- Event
function QiXi_Guide_2026_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_QiXi_Guide_2026_UICOM then
		local nOperation = Get_XParam_INT(0)
		if nOperation == 0 then--关闭界面
			QiXi_Guide_2026_OnClose()
			return
		end
		
		local nProcess = Get_XParam_INT(1)
		g_QiXi_Guide_2026_Tips = Get_XParam_INT(2)
		g_QiXi_Guide_2026_Flag = Get_XParam_INT(3)
		local nValueMD = Get_XParam_INT(4)
		g_QiXi_Guide_2026_State = math.mod(nValueMD,10)
		nValueMD = math.floor(nValueMD/10)
		g_QiXi_Guide_2026_Libao = math.mod(nValueMD,10)
		g_QiXi_Guide_2026_DaiBiLimit = math.floor(nValueMD/10)
		
		for index = 1, table.getn(g_QiXi_Guide_2026_Button_Guide) do
			local DataState = Get_XParam_INT(index+4)
			local IsBtnShow = math.floor(DataState / 10)
			local IsTipsShow = math.mod(DataState, 10)
			g_QiXi_Guide_2026_Button_Guide[index] = IsBtnShow
			g_QiXi_Guide_2026_Tips_Guide[index] = IsTipsShow
		end
	
		if nOperation == 1 then --打开界面
			if this:IsVisible() then
				QiXi_Guide_2026_OnClose()
				return
			end
			QiXi_Guide_2026_Update()
			QiXi_Guide_2026_Stage_GotoTips( nProcess )
			this:Show()
		elseif nOperation == 3 then --刷新界面
			if this:IsVisible() then	
				QiXi_Guide_2026_Update()
				QiXi_Guide_2026_Stage_GotoTips( nProcess )
			end
		end
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89377701 ) then
	
		if this:IsVisible() and Get_XParam_INT(3) and Get_XParam_INT(3) > 0 then
			g_QiXi_Guide_2026_DaiBiLimit = Get_XParam_INT(3)
			QiXi_Guide_2026_Update_DaiBi()
		end
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89377602 ) then
		QiXi_Guide_2026_OnClose()
	
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		QiXi_Guide_2026_On_ResetPos()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		QiXi_Guide_2026_OnClose()
		
	elseif event == "ADJEST_UI_POS" then
		QiXi_Guide_2026_On_ResetPos()
		
	end

end

function QiXi_Guide_2026_Update_DaiBi()

	local nPStr = ScriptGlobal_Format("#{QXZH_250528_150}", g_QiXi_Guide_2026_DaiBiLimit)
	QiXi_Guide_2026_Shop_CurrencyText:SetText( nPStr )
	
end

-- 刷新界面
function QiXi_Guide_2026_Update()
	
	--按钮与红点
	for index = 1, table.getn(g_QiXi_Guide_2026_Button) do
		g_QiXi_Guide_2026_Button[index]:Hide()
		g_QiXi_Guide_2026_Tip[index]:Hide()
		
	end
	local curDay = DataPool:GetServerDayTime()
	local isTabeRedPoint = 0
	for index = 1, table.getn(g_QiXi_Guide_2026_Button) do
		--获取缓存的按钮状态
		local isButtonShow = g_QiXi_Guide_2026_Button_Guide[index]
		local isTipsShow = g_QiXi_Guide_2026_Tips_Guide[index]

		local event = g_QiXi_Guide_2026_Event[index]
		--悬浮提示
		if curDay < event.begtime then
			g_QiXi_Guide_2026_Button[index]:SetToolTip(event.btntips_unbeg)
		elseif curDay >= event.begtime and curDay <= event.endtime then
			g_QiXi_Guide_2026_Button[index]:SetToolTip(event.btntips_doing)
		elseif curDay > event.endtime then
			g_QiXi_Guide_2026_Button[index]:SetToolTip(event.btntips_end)
		end

		--按钮显隐
		if isButtonShow == 1 then --按钮状态标识显示
			g_QiXi_Guide_2026_Button[index]:Show()
			
			--红点
			if isTipsShow == 1 then
				g_QiXi_Guide_2026_Tip[index]:Show()
			end
			
		end

		--客户端也根据状态刷新显示一下快捷入口的红点 以免服务器忘记刷新了
		if isTipsShow == 1 then
			isTabeRedPoint = 1
		end
	end
	
	if g_QiXi_Guide_2026_Tips > 0 then
		isTabeRedPoint = 1
	end
	--快捷入口的红点
	Lua_ShowQuickEnterPointTip(g_QiXi_Guide_2026_QuickEnterId, isTabeRedPoint)
		
	QiXi_Guide_2026_Update_DaiBi()
	
	if g_QiXi_Guide_2026_State == 1 and g_QiXi_Guide_2026_Libao == 0  then
		QiXi_Guide_2026_HolidayGift:Show()	
		QiXi_Guide_2026_HolidayGift_Tips:Show()
	else
		QiXi_Guide_2026_HolidayGift:Hide()
		QiXi_Guide_2026_HolidayGift_Tips:Hide()
	end
	
end

-- 重置界面位置
function QiXi_Guide_2026_On_ResetPos()

	QiXi_Guide_2026_Frame:SetProperty("UnifiedPosition", g_QiXi_Guide_2026_Frame_UnifiedPosition)
	
end

function QiXi_Guide_2026_OnHidden()

	g_QiXi_Guide_2026_Flag = 0
	g_QiXi_Guide_2026_Tips = 0
	g_QiXi_Guide_2026_DaiBiLimit = 0
	g_QiXi_Guide_2026_Libao = 0
	g_QiXi_Guide_2026_State = 0
	
end

-- 关闭
function QiXi_Guide_2026_OnClose()

	this:Hide()
	
end

function QiXi_Guide_2026_HolidayGift_Clicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetQiXiGuideLiBao")
		Set_XSCRIPT_ScriptID(893776)
        Set_XSCRIPT_Parameter(0, 1)
        Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

-- 打开各个功能界面
function QiXi_Guide_2026_ActionClicked( clickId )

	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then --七夕商店
	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenQiXiGuideShop")
			Set_XSCRIPT_ScriptID(893777)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	
	elseif clickId == 2 then 

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(900031)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	
	elseif clickId == 3 then -- 稳活-戏曲联动

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("PlayerClickOpenUI")
			Set_XSCRIPT_ScriptID(510025)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		
	elseif clickId == 4 then 
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenGotoUI")
		Set_XSCRIPT_ScriptID(051238)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		
	elseif clickId == 5 then 
		-- 请求
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("PlayerClickButton")
			Set_XSCRIPT_ScriptID(507140)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 6 then 
		AutoRuntoTargetExWithName(139, 184, 0, "月老")
		QiXi_Guide_2026_OnClose()

	elseif clickId == 7 then 
		
	end

	--主动刷新红点
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowButtonTips")
		Set_XSCRIPT_ScriptID(893776)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

function QiXi_Guide_2026_Stage_GotoTips( nProcess )

	local nProcessIdx = math.mod(nProcess, 10)
	nProcess = math.floor(nProcess/10)
	local nPStr = ScriptGlobal_Format("#{QXZH_250528_11}", nProcess/100)
	QiXi_Guide_2026_Stage_ProgressTextNum:SetText(nPStr)

	for i = 1, table.getn(g_QiXi_Guide_2026_ProcessTips) do
		local ndivisor = math.pow(10, i - 1)
		g_QiXi_Guide_2026_ProcessTips[i] = math.mod(math.floor(g_QiXi_Guide_2026_Tips/ndivisor), 10)
		g_QiXi_Guide_2026_ProcessFlags[i] = math.mod(math.floor(g_QiXi_Guide_2026_Flag/ndivisor), 10)
		
		if g_QiXi_Guide_2026_ProcessTips[i] == 1 then
			g_QiXi_Guide_2026_Process_GotoTips[i]:Show()
		else
			g_QiXi_Guide_2026_Process_GotoTips[i]:Hide()
		end
			
		if g_QiXi_Guide_2026_ProcessFlags[i] == 1 then
			g_QiXi_Guide_2026_Process_Goto[i]:Hide()
			g_QiXi_Guide_2026_Process_Finished[i]:Show()
			g_QiXi_Guide_2026_Process_Locked[i]:Hide()
		else
			g_QiXi_Guide_2026_Process_Finished[i]:Hide()
				
			if i > nProcessIdx then
				g_QiXi_Guide_2026_Process_Goto[i]:Hide()
				g_QiXi_Guide_2026_Process_Locked[i]:Show()
			else
				g_QiXi_Guide_2026_Process_Goto[i]:Show()
				g_QiXi_Guide_2026_Process_Locked[i]:Hide()
			end
		end
	end
	
end

function QiXi_Guide_2026_Stage_GotoClicked( idx )
	if g_QiXi_Guide_2026_NpcList[idx] ~= nil then
		local resId = g_QiXi_Guide_2026_NpcList[idx].SceneResId
		local posx = g_QiXi_Guide_2026_NpcList[idx].posX
		local posz = g_QiXi_Guide_2026_NpcList[idx].posZ
		local name = g_QiXi_Guide_2026_NpcList[idx].name
		AutoRuntoTargetExWithName(posx, posz, resId, name)
		
		QiXi_Guide_2026_OnClose()
	end
end

function QiXi_Guide_2026_Stage_ProgressHelp_Clicked()

	PushEvent("QUEST_HELPINFO", "#{QXZH_250528_06}")
	
end

