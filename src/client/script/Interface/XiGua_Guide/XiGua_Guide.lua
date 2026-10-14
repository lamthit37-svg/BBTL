
local g_XiGua_Guide_Frame_UnifiedPosition

--端午节
local g_XiGua_Guide_Event = {
	[1] = {begtime=20260723,endtime =20260802,btntips_unbeg="",btntips_doing="#{XGSD_200609_08}",btntips_end="#{XGSD_200609_05}",},		--蒲雪饮冰 
	[2] = {begtime=20260723,endtime =20260802,btntips_unbeg="",btntips_doing="#{XGJSD_230526_02}",btntips_end="#{XGSD_200609_05}",},		--奇珍集市 
	[3] = {begtime=20260723,endtime =20260802,btntips_unbeg="",btntips_doing="#{XGSD_200609_12}",btntips_end="#{XGSD_200609_05}",},		--清泉茗茶 
	[4] = {begtime=20260723,endtime =20260806,btntips_unbeg="",btntips_doing="#{XGJHD_220427_81}",btntips_end="#{XGSD_200609_05}",},		--新增代币结算 
	[5] = {begtime=20260723,endtime =20260802,btntips_unbeg="",btntips_doing="#{XGZH_200628_06}",btntips_end="#{XGSD_200609_05}",},		--节日礼包 
};

local g_Button_Guide_StateTemp = {1, 1, 1, 1, 1,}
local g_Tips_Guide_StateTemp = {0, 0, 0, 0, 0,}

local g_XiGua_Guide_Button ={
}

local g_XiGua_Guide_Tip = {
}

function XiGua_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)

end

function XiGua_Guide_OnLoad()

	XiGua_Guide_LoadControl()
	
	g_XiGua_Guide_Frame_UnifiedPosition = XiGua_Guide_Frame:GetProperty("UnifiedPosition")

end

--=========
-- 装载控件
--=========
function XiGua_Guide_LoadControl()

	g_XiGua_Guide_Button[1] 	= XiGua_Guide_Btn1;
	g_XiGua_Guide_Button[2] 	= XiGua_Guide_Btn2;
	g_XiGua_Guide_Button[3] 	= XiGua_Guide_Btn3;
	g_XiGua_Guide_Button[4] 	= XiGua_Guide_Btn4;
	g_XiGua_Guide_Button[5] 	= XiGua_Guide_Reward_Button;

	g_XiGua_Guide_Tip[1] 		= XiGua_Guide_Btn1_Tips;
	g_XiGua_Guide_Tip[2] 		= XiGua_Guide_Btn2_Tips;
	g_XiGua_Guide_Tip[3] 		= XiGua_Guide_Btn3_Tips;
	g_XiGua_Guide_Tip[4] 		= XiGua_Guide_Btn4_Tips;
	g_XiGua_Guide_Tip[5] 		= XiGua_Guide_InsButton_Tips;

end

--=========
-- Event
--=========
function XiGua_Guide_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88808101) then
		
		if this:IsVisible() then
			XiGua_Guide_Close()
			return
		end
		
		-- 同步服务器时间
		AskServerTimeAgain()
		
		XiGua_Guide_Open()
		this:Show()
			
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 88809701) then	--节日礼包特写
	
		local bShow = Get_XParam_INT(0)
		if bShow == 2 then
			g_XiGua_Guide_Button[5]:Hide()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		XiGua_Guide_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		XiGua_Guide_Close()

	elseif event == "ADJEST_UI_POS" then

		XiGua_Guide_On_ResetPos()

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 88808102) then --显示小红点

		for index = 1, table.getn(g_XiGua_Guide_Button)  do
			 local TipsState = Get_XParam_INT(index-1)
			 g_Tips_Guide_StateTemp[index]  = TipsState
		end
		XiGua_Guide_ShowButtonTips()
		
	end

end

--=========
-- 重置
--=========
function XiGua_Guide_On_ResetPos()

	XiGua_Guide_Frame:SetProperty("UnifiedPosition", g_XiGua_Guide_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function XiGua_Guide_Close()
		
	if(IsWindowShow("XiGua_Shop_Activity")) then
		CloseWindow("XiGua_Shop_Activity", true)
	end
	
	this:Hide()
	
end

--=========
-- 打开
--=========
function XiGua_Guide_Open()
	for index=1,table.getn(g_XiGua_Guide_Tip) do
		g_XiGua_Guide_Tip[index]:Hide()
		g_XiGua_Guide_Button[index]:Hide()
	end

	for index=1,table.getn(g_XiGua_Guide_Tip)  do
		 local TipsState = Get_XParam_INT(index-1)
		 g_Tips_Guide_StateTemp[index] 	    = TipsState
	end

	local curDay = DataPool:GetServerDayTime()
	for index=1,table.getn(g_XiGua_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   	= g_Tips_Guide_StateTemp[index]
		local event  			= g_XiGua_Guide_Event[index]

		if isButtonShow == 1 then
			g_XiGua_Guide_Button[index]:Show()
			if curDay < event.begtime then
				g_XiGua_Guide_Button[index]:SetToolTip(event.btntips_unbeg)
			elseif curDay >= event.begtime and curDay <= event.endtime then
				g_XiGua_Guide_Button[index]:SetToolTip(event.btntips_doing)
			elseif curDay > event.endtime then
				g_XiGua_Guide_Button[index]:SetToolTip(event.btntips_end)
			end
			if isTipsShow == 1 then
				g_XiGua_Guide_Tip[index]:Show()
			else
				g_XiGua_Guide_Tip[index]:Hide()
			end
			if index == 4 then
				if curDay >= 20260803 and curDay <= event.endtime then
					g_XiGua_Guide_Button[index]:SetToolTip("#{XGJHD_220427_82}")
				end
			end
			event.isShow = 1
		end
	end
		
	if Pneuma:GetMF(5557) == 1 then--节日礼包特写
		g_XiGua_Guide_Button[5]:Hide()
	end
	
	--设置小红点
	XiGua_Guide_ShowButtonTips()
end

--===============================================
-- 设置Button 小红点
--===============================================
function XiGua_Guide_ShowButtonTips()

	for index = 1, table.getn(g_XiGua_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   = g_Tips_Guide_StateTemp[index]
		if isButtonShow == 1 then
			if isTipsShow == 1 then
				g_XiGua_Guide_Tip[index]:Show()
			else
				g_XiGua_Guide_Tip[index]:Hide()
			end
		end
	end

	local IsShowMiniMapPoint = 0
	for index = 1, table.getn(g_Tips_Guide_StateTemp) do
		if g_Tips_Guide_StateTemp[index] == 1 then
			IsShowMiniMapPoint = 1
			break
		end
	end

	--PushEvent("UI_COMMAND", 88808103, IsShowMiniMapPoint)

	Lua_ShowQuickEnterPointTip(24, IsShowMiniMapPoint)

end

--===============================================
-- 打开各个功能界面
--===============================================
function XiGua_Guide_Clicked( clickId )
	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then
		local curDay = DataPool:GetServerDayTime()
		if curDay < g_XiGua_Guide_Event[clickId].begtime or curDay > g_XiGua_Guide_Event[clickId].endtime then
			PushDebugMessage("#{XGSD_200609_03}")
			return
		end
		
		local nLevel = Player:GetLevel();
		if nLevel < 30 then
			PushDebugMessage("#{XGSD_200609_02}")
			return
		end
			
		-- 蒲雪饮冰
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UpdateUI" )
			Set_XSCRIPT_ScriptID(891920)
		Send_XSCRIPT()
	
	elseif clickId == 2 then
		-- 奇珍集市
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(998574)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 3 then
		-- 清泉茗茶
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("GetRedPoint")
				Set_XSCRIPT_ScriptID(889861)
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()

			local nLevel = Player:GetLevel();
			if nLevel < 30 then
				PushDebugMessage("#{XGSD_200609_02}")
				return
			end

			local curDay = DataPool:GetServerDayTime()
			if curDay < g_XiGua_Guide_Event[clickId].begtime or curDay > g_XiGua_Guide_Event[clickId].endtime then
				PushDebugMessage("#{XGSD_200609_03}")
				return
			end
			local bRet = AutoRuntoTargetExWithName(296, 188, 1, "陆屿")
			if 0 == bRet then
				PushDebugMessage("无法自动寻路")
				return
			end
			PushDebugMessage("#{XGSD_200609_13}")	
	elseif clickId == 4 then
		-- 新增代币结算
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenChouJiangUI" )
			Set_XSCRIPT_ScriptID( 998017 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 5 then
		-- 节日礼包
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnOpenUI")
				Set_XSCRIPT_ScriptID(888097)
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()
	end

	--关闭本界面
	--改为互斥关闭
	--this:Hide()

end
