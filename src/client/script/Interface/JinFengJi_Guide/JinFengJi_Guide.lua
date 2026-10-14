--JinFengJi
local g_JinFengJi_Guide_Event = {
	[1] = {begtime=20230831, endtime =20230913, level =30, btntips_unbeg="", btntips_doing="#{JFMZ_200814_97}", btntips_end="#{JFMZ_200814_98}",},	 	-- 金枫秘藏
	[2] = {begtime=20200903, endtime =20200916, level =30, btntips_unbeg="", btntips_doing="#{DHDK_200723_04}", btntips_end="#{DHDK_200723_05}",},		-- 敦煌莫高窟打卡丝绸之路
	[3] = {begtime=20230831, endtime =20230913, level =30, btntips_unbeg="#{QFGS_180807_48}", btntips_doing="#{QFGS_180807_48}", btntips_end="#{QFGS_210720_01}",},		-- 	秋枫共赏
	[4] = {begtime=20230831, endtime =20230913, level =30, btntips_unbeg="#{JFLZ_200803_02}", btntips_doing="#{JFLZ_200803_02}", btntips_end="#{FLSQ_210722_01}",},		--  bt4
	[5] = {begtime=20230831, endtime =20230913, level =30, btntips_unbeg="#{JFHD_180803_67}", btntips_doing="#{JFHD_180803_67}", btntips_end="#{JFHD_180803_82}",},		--  掷骰子
	[6] = {begtime=20230831, endtime =20230913, level =30, btntips_unbeg="#{JFZH_200721_05}", btntips_doing="#{JFZH_200721_05}", btntips_end="#{JFZH_200721_05}",},		--  节日礼包
	[7] = {begtime=20230831, endtime =20230913, level =30, btntips_unbeg="#{JFZH_200721_08}", btntips_doing="#{JFZH_200721_08}", btntips_end="#{JFZH_200721_08}",},		--  节日攻略
	[8] = {begtime=20210823, endtime =20210829, level =30, btntips_unbeg="#{JFH5_210706_02}", btntips_doing="#{JFH5_210706_02}", btntips_end="#{JFH5_210706_03}",},		--  登高揽秋光活动
	[9] = {begtime=20210823, endtime =20210908, level =30, btntips_unbeg="#{ZNYR_201019_02}", btntips_doing="#{ZNYR_201019_02}", btntips_end="#{ZNYR_201019_02}",},		--  曲流觞
	[10] = {begtime=20210830, endtime =20210908, level =30, btntips_unbeg="#{FBQF_201019_01}", btntips_doing="#{FBQF_201019_02}", btntips_end="#{FBQF_201019_02}",},		--  答鱼歌
};

local g_JinFengJi_Guide_Frame_UnifiedPosition
local g_Button_Guide_StateTemp = {1,0,1,1,1,1,1,0,0,0,}
local g_Tips_Guide_StateTemp = {0,0,0,0,0,0,0,0,0,0,}

local g_JinFengJi_Guide_Button ={
}

local g_JinFengJi_Guide_Tip = {
}

local g_JinFengJi_Guide_BeginTime = 20230831
local g_JinFengJi_Guide_EndTime = 20230913
--local g_JinFengJi_Guide_GongLueTimeSP1 = 20200831 --节日攻略按钮特殊tip开始时间
--local g_JinFengJi_Guide_GongLueTimeSP2 = 20200902 --节日攻略按钮特殊tip结束时间

function JinFengJi_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	
end

function JinFengJi_Guide_OnLoad()
	JinFengJi_Guide_LoadControl()
	g_JinFengJi_Guide_Frame_UnifiedPosition = JinFengJi_Guide_Frame:GetProperty("UnifiedPosition") 
	
end
--=========
-- 装载控件
--=========
function JinFengJi_Guide_LoadControl()

	g_JinFengJi_Guide_Button[1] 	= JinFengJi_Guide_Btn1; --
	g_JinFengJi_Guide_Button[2] 	= JinFengJi_Guide_Btn2; --
	g_JinFengJi_Guide_Button[3] 	= JinFengJi_Guide_Btn3;
	g_JinFengJi_Guide_Button[4] 	= JinFengJi_Guide_Btn4;
	g_JinFengJi_Guide_Button[5] 	= JinFengJi_Guide_Btn5; 
	g_JinFengJi_Guide_Button[6] 	= JinFengJi_Guide_InsButton01; 
	g_JinFengJi_Guide_Button[7] 	= JinFengJi_Guide_InsButton02; 
	g_JinFengJi_Guide_Button[8] 	= JinFengJi_Guide_Btn6; 
	g_JinFengJi_Guide_Button[9] 	= JinFengJi_Guide_Btn7; 
	g_JinFengJi_Guide_Button[10] 	= JinFengJi_Guide_Btn8; 

	g_JinFengJi_Guide_Tip[1] 		= JinFengJi_Guide_Btn1_Tips;
	g_JinFengJi_Guide_Tip[2] 		= JinFengJi_Guide_Btn2_Tips;
	g_JinFengJi_Guide_Tip[3] 		= JinFengJi_Guide_Btn3_Tips;
	g_JinFengJi_Guide_Tip[4] 		= JinFengJi_Guide_Btn4_Tips;
	g_JinFengJi_Guide_Tip[5] 		= JinFengJi_Guide_Btn5_Tips; 
	g_JinFengJi_Guide_Tip[6] 		= JinFengJi_Guide_InsButton01_Tips; 
	g_JinFengJi_Guide_Tip[7] 		= JinFengJi_Guide_InsButton02_Tips; 
	g_JinFengJi_Guide_Tip[8] 		= JinFengJi_Guide_Btn6_Tips; 
	g_JinFengJi_Guide_Tip[9] 		= JinFengJi_Guide_Btn7_Tips; 
	g_JinFengJi_Guide_Tip[10] 		= JinFengJi_Guide_Btn8_Tips; 

end
--=========
-- Event
--=========
function JinFengJi_Guide_OnEvent(event) 
	if(event == "UI_COMMAND" and tonumber(arg0) == 88812701) then -- 
		if this:IsVisible() then
			JinFengJi_Guide_Close()
			return
		end
		AskServerTimeAgain() 
		local bShowJieRiLiBao = Get_XParam_INT(10)
		JinFengJi_Guide_Open(bShowJieRiLiBao)
		this:Show()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 88812901) then -- 特写礼包领完 button隐藏
		
		local bShow = Get_XParam_INT(0)
		if bShow == 2 then
			g_JinFengJi_Guide_Button[6]:Hide()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		JinFengJi_Guide_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		JinFengJi_Guide_Close()

	elseif event == "ADJEST_UI_POS" then

		JinFengJi_Guide_On_ResetPos()

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 88812702) then --显示小红点

		for index=1,table.getn(g_JinFengJi_Guide_Button)  do
			 local TipsState = Get_XParam_INT(index-1)
			 g_Tips_Guide_StateTemp[index]  = TipsState
		end
		JinFengJi_Guide_ShowButtonTips()  
		
	end

end
 
--=========
-- 重置
--=========
function JinFengJi_Guide_On_ResetPos()

	JinFengJi_Guide_Frame:SetProperty("UnifiedPosition", g_JinFengJi_Guide_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function JinFengJi_Guide_Close() 
	this:Hide()
end

--=========
-- 打开
--=========
function JinFengJi_Guide_Open(bShowJieRiLiBao) 
	for index=1,table.getn(g_JinFengJi_Guide_Tip) do 
		g_JinFengJi_Guide_Tip[index]:Hide()
		g_JinFengJi_Guide_Button[index]:Hide()
	end
	for index=1,table.getn(g_JinFengJi_Guide_Tip)  do
		 local TipsState = Get_XParam_INT(index-1) 
		 g_Tips_Guide_StateTemp[index] 	    = TipsState
	end
	local curDay = DataPool:GetServerDayTime()
	local buttonId = 1
	for index=1,table.getn(g_JinFengJi_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   	= g_Tips_Guide_StateTemp[index]
		local event  			= g_JinFengJi_Guide_Event[index]
		if isButtonShow == 1 then 
			g_JinFengJi_Guide_Button[buttonId]:Show()
			if curDay < event.begtime then
				g_JinFengJi_Guide_Button[buttonId]:SetToolTip(event.btntips_unbeg)
			elseif curDay >= event.begtime and curDay <= event.endtime then
				g_JinFengJi_Guide_Button[buttonId]:SetToolTip(event.btntips_doing)
			elseif curDay > event.endtime then
				g_JinFengJi_Guide_Button[buttonId]:SetToolTip(event.btntips_end)
			end
			if isTipsShow == 1 then
				g_JinFengJi_Guide_Tip[buttonId]:Show()
			end
			event.isShow = 1
			buttonId = buttonId+1
		else
			buttonId = buttonId+1
		end
	end 	  
	
	-- if g_JinFengJi_Guide_GongLueTimeSP1 <= curDay and curDay <= g_JinFengJi_Guide_GongLueTimeSP2 then
		-- g_JinFengJi_Guide_Button[8]:SetToolTip("#{QXZH_200708_03}")
	-- end
	-- 如果领过节日礼包 就不再主界面显示这个按钮了
	if bShowJieRiLiBao == 1 then
		g_JinFengJi_Guide_Tip[6]:Hide()
		g_JinFengJi_Guide_Button[6]:Hide()
	end
	--设置小红点
	JinFengJi_Guide_ShowButtonTips()
end

--===============================================
-- 设置Button 小红点
--===============================================
function JinFengJi_Guide_ShowButtonTips()

	local buttonId = 1
	for index=1,table.getn(g_JinFengJi_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   = g_Tips_Guide_StateTemp[index]
		if isButtonShow == 1 then
			if isTipsShow == 1 then
				g_JinFengJi_Guide_Tip[buttonId]:Show()
			else
				g_JinFengJi_Guide_Tip[buttonId]:Hide()
			end
			buttonId = buttonId+1
		else
			buttonId = buttonId+1
		end
	end

	local IsShowMiniMapPoint = 0
	for index=1,table.getn(g_Tips_Guide_StateTemp) do
		if g_Tips_Guide_StateTemp[index] == 1 then
			IsShowMiniMapPoint = 1
			break
		end
	end

	Lua_ShowQuickEnterPointTip(25, IsShowMiniMapPoint)

end

--===============================================
-- 打开各个功能界面
--===============================================
function JinFengJi_Guide_Clicked( clickId )
	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then 
		if curDay < g_JinFengJi_Guide_Event[clickId].begtime or curDay > g_JinFengJi_Guide_Event[clickId].endtime then
			PushDebugMessage("#{DHDK_200723_01}")
			return
		end
		if Player:GetLevel() < g_JinFengJi_Guide_Event[clickId].level then
			PushDebugMessage("#{DHDK_200723_02}")
			return
		end
		AutoRunToTargetEx(228,245,1)
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClickButton")
			Set_XSCRIPT_ScriptID(892881)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		PushDebugMessage("#{JFMZ_200814_144}")
		
	elseif clickId == 2 then 
		if curDay < g_JinFengJi_Guide_Event[clickId].begtime or curDay > g_JinFengJi_Guide_Event[clickId].endtime then
			PushDebugMessage("#{DHDK_200723_01}")
			return
		end
		if Player:GetLevel() < g_JinFengJi_Guide_Event[clickId].level then
			PushDebugMessage("#{DHDK_200723_02}")
			return
		end
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpenPictureScroll" )
			Set_XSCRIPT_ScriptID( 190000 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
--		JinFengJi_Guide_Close()
	elseif clickId == 3 then  		
		if curDay < g_JinFengJi_Guide_Event[clickId].begtime or curDay > g_JinFengJi_Guide_Event[clickId].endtime then
			PushDebugMessage("#{QFGS_180807_02}")
			return
		end
		if Player:GetLevel() < g_JinFengJi_Guide_Event[clickId].level then
			PushDebugMessage("#{QFGS_180807_03}")
			return
		end
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenFrostReWard" )
			Set_XSCRIPT_ScriptID( 891414 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	elseif clickId == 4 then  
		if curDay < g_JinFengJi_Guide_Event[4].begtime or curDay > g_JinFengJi_Guide_Event[4].endtime then
            PushDebugMessage("#{JFLZ_200803_03}")
            return
        end

        if Player:GetLevel() < g_JinFengJi_Guide_Event[4].level then
            PushDebugMessage("#{JFLZ_200803_04}")
            return
        end
		local bRet = AutoRuntoTargetExWithName(231, 186, 1, "金叶彤枫")
		if 0 == bRet then
			PushDebugMessage("无法自动寻路")
			return
		end
		PushDebugMessage("#{JFLZ_200803_05}")
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("HotPointClick")
			Set_XSCRIPT_ScriptID(892889)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 5 then   
		if curDay < g_JinFengJi_Guide_Event[5].begtime or curDay > g_JinFengJi_Guide_Event[5].endtime then
            PushDebugMessage("#{JFHD_180803_68}")
            return
        end

        if Player:GetLevel() < g_JinFengJi_Guide_Event[5].level then
            PushDebugMessage("#{JFHD_180803_69}")
            return
        end
		local bRet = AutoRuntoTargetExWithName(238, 186, 1, "枫凌")
		if 0 == bRet then
			PushDebugMessage("无法自动寻路")
			return
		end
		PushDebugMessage("#{JFHD_180803_70}")
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClickButton")
			Set_XSCRIPT_ScriptID(892890)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 6 then  
		if curDay < g_JinFengJi_Guide_Event[6].begtime or curDay > g_JinFengJi_Guide_Event[6].endtime then
            PushDebugMessage("#{JFZH_200721_06}")
            return
        end

        if Player:GetLevel() < g_JinFengJi_Guide_Event[6].level then
            PushDebugMessage("#{JFZH_200721_07}")
            return
        end
		
		-- 节日礼包 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID( 888129 )
		Send_XSCRIPT()
	elseif clickId == 7 then  
		if curDay < g_JinFengJi_Guide_Event[7].begtime or curDay > g_JinFengJi_Guide_Event[7].endtime then
            PushDebugMessage("#{JFZH_200721_09}")
            return
        end

        if Player:GetLevel() < g_JinFengJi_Guide_Event[7].level then
            PushDebugMessage("#{JFZH_200721_10}")
            return
        end
		
		-- 活动日程 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID( 888128 )
		Send_XSCRIPT()
	elseif clickId == 8 then  
		if curDay < g_JinFengJi_Guide_Event[8].begtime or curDay > g_JinFengJi_Guide_Event[8].endtime then
            PushDebugMessage("#{JFH5_210706_04}")
            return
        end

        if Player:GetLevel() < g_JinFengJi_Guide_Event[8].level then
            PushDebugMessage("#{JFH5_210706_05}")
            return
        end
		
		PushEvent("2020JQ_YUNYING")
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClickButton" )
			Set_XSCRIPT_ScriptID( 888145 )
		Send_XSCRIPT()
	elseif clickId == 9 then  
		-- 曲流殇		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenAnniversaryPre2020" )
			Set_XSCRIPT_ScriptID( 893401 )
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()		
	elseif clickId == 10 then  
		-- 答渔歌		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenQiFuUI" )
			Set_XSCRIPT_ScriptID( 893403 )
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()		
	end 

end
