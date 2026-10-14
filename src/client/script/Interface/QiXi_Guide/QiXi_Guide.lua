--qixi
local g_QiXi_Guide_Event = {
	[1] = {begtime=20250821, endtime =20250903, level =30, btntips_unbeg="#{XQYJ_220527_03}", btntips_doing="#{XQYJ_220527_04}", btntips_end="#{XQYJ_220527_05}",},	 	-- 大破天门阵
	[2] = {begtime=20220729, endtime =20220814, level =30, btntips_unbeg="#{QXJSX_20220525_03}", btntips_doing="#{QXJSX_20220525_02}", btntips_end="#{QXJSX_20220525_04}",},--传书渡情
	[3] = {begtime=20230814, endtime =20230827, level =30, btntips_unbeg="#{QXHF_190620_09}", btntips_doing="#{QXHF_190620_09}", btntips_end="#{QXHF_190620_10}",},--华服嘉姻
	[4] = {begtime=20220729, endtime =20220817, level =30, btntips_unbeg="#{QXJCJ_20220523_03}", btntips_doing="#{QXJCJ_20220523_02}", btntips_end="#{QXJCJ_20220523_04}",},		--赐天缘 
	[5] = {begtime=20250821, endtime =20250903, level =30, btntips_unbeg="#{QXSD_190615_25}", btntips_doing="#{QXSD_190615_24}", btntips_end="#{QXSD_190615_25}",},		--  良缘会
	[6] = {begtime=20210802, endtime =20210822, level =30, btntips_unbeg="#{QXHF_190620_141}", btntips_doing="#{QXHF_190620_141}", btntips_end="#{QXHF_190620_142}",},		--  
	[7] = {begtime=20250821, endtime =20250903, level =30, btntips_unbeg="#{QXZH_200708_01}", btntips_doing="#{QXZH_200708_01}", btntips_end="#{QXZH_200708_01}",},		--  节日礼包
	[8] = {begtime=20210802, endtime =20210822, level =30, btntips_unbeg="#{QXZH_200708_02}", btntips_doing="#{QXZH_200708_02}", btntips_end="#{QXZH_200708_02}",},		--  活动攻略 ps2022年不开 但是留着这个按钮
	[9] = {begtime=20210729, endtime =20210828, level =30, btntips_unbeg="", btntips_doing="", btntips_end="",},		--  
	[10] = {begtime=20220729, endtime =20220814, level =30, btntips_unbeg="#{FBQY_220601_02}", btntips_doing="#{FBQY_220601_01}", btntips_end="#{FBQY_220601_03}",},		--  
	[11] = {begtime=20250821, endtime =20250903, level =30, btntips_unbeg="#{JHJL_220119_09}", btntips_doing="#{JHJL_220119_08}", btntips_end="#{JHJL_220119_10}",},	--红线相忆礼随心
};

local g_QiXi_Guide_Frame_UnifiedPosition
local g_Button_Guide_StateTemp = {1,1,1,1,1,1,1,1,1,1,1,}
local g_Tips_Guide_StateTemp = {0,0,0,0,0,0,0,0,0,0,0,}

local g_QiXi_Guide_Button ={
}

local g_QiXi_Guide_Tip = {
}

local g_QiXi_Guide_BeginTime = 20250821
local g_QiXi_Guide_EndTime = 20250903
local g_QiXi_Guide_GongLueTimeSP1 = 20210819 --节日攻略按钮特殊tip开始时间
local g_QiXi_Guide_GongLueTimeSP2 = 20210822 --节日攻略按钮特殊tip结束时间

function QiXi_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	
end

function QiXi_Guide_OnLoad()
	QiXi_Guide_LoadControl()
	g_QiXi_Guide_Frame_UnifiedPosition = QiXi_Guide_Frame:GetProperty("UnifiedPosition") 
	
end
--=========
-- 装载控件
--=========
function QiXi_Guide_LoadControl()

	g_QiXi_Guide_Button[1] 	= QiXi_Guide_Btn1; --
	g_QiXi_Guide_Button[2] 	= QiXi_Guide_Btn2; --
	g_QiXi_Guide_Button[3] 	= QiXi_Guide_Btn3;
	g_QiXi_Guide_Button[4] 	= QiXi_Guide_Btn4;
	g_QiXi_Guide_Button[5] 	= QiXi_Guide_Btn5; 
	g_QiXi_Guide_Button[6] 	= QiXi_Guide_Btn6; 
	g_QiXi_Guide_Button[7] 	= QiXi_Guide_Btn7; 
	g_QiXi_Guide_Button[8] 	= QiXi_Guide_Btn8; 
	g_QiXi_Guide_Button[9] 	= QiXi_Guide_Btn9; 
	g_QiXi_Guide_Button[10] = QiXi_Guide_Btn10; 
	g_QiXi_Guide_Button[11] = QiXi_Guide_Btn11; 

	g_QiXi_Guide_Tip[1] 		= QiXi_Guide_Btn1_Tips;
	g_QiXi_Guide_Tip[2] 		= QiXi_Guide_Btn2_Tips;
	g_QiXi_Guide_Tip[3] 		= QiXi_Guide_Btn3_Tips;
	g_QiXi_Guide_Tip[4] 		= QiXi_Guide_Btn4_Tips;
	g_QiXi_Guide_Tip[5] 		= QiXi_Guide_Btn5_Tips; 
	g_QiXi_Guide_Tip[6] 		= QiXi_Guide_Btn6_Tips; 
	g_QiXi_Guide_Tip[7] 		= QiXi_Guide_Btn7_Tips; 
	g_QiXi_Guide_Tip[8] 		= QiXi_Guide_Btn8_Tips; 
	g_QiXi_Guide_Tip[9] 		= QiXi_Guide_Btn9_Tips; 
	g_QiXi_Guide_Tip[10] 		= QiXi_Guide_Btn10_Tips; 
	g_QiXi_Guide_Tip[11] 		= QiXi_Guide_Btn11_Tips; 

end
--=========
-- Event
--=========
function QiXi_Guide_OnEvent(event) 
	if(event == "UI_COMMAND" and tonumber(arg0) == 89312801) then -- 
		if this:IsVisible() then
			QiXi_Guide_Close()
			return
		end
		AskServerTimeAgain() 
		local bShowJieRiLiBao = Get_XParam_INT(11)
		QiXi_Guide_Open(bShowJieRiLiBao)
		this:Show()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 88811301) then -- 特写礼包领完 button隐藏
		
		local bShow = Get_XParam_INT(0)
		if bShow == 2 then
			g_QiXi_Guide_Button[7]:Hide()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		QiXi_Guide_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		QiXi_Guide_Close()

	elseif event == "ADJEST_UI_POS" then

		QiXi_Guide_On_ResetPos()

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89312802) then --显示小红点

		for index=1,table.getn(g_QiXi_Guide_Button)  do
			 local TipsState = Get_XParam_INT(index-1)
			 g_Tips_Guide_StateTemp[index]  = TipsState
		end
		QiXi_Guide_ShowButtonTips()  
		
	end

end
 
--=========
-- 重置
--=========
function QiXi_Guide_On_ResetPos()

	QiXi_Guide_Frame:SetProperty("UnifiedPosition", g_QiXi_Guide_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function QiXi_Guide_Close() 
	PushEvent("2019QIXI_CLOSE")
	this:Hide()
end

--=========
-- 打开
--=========
function QiXi_Guide_Open(bShowJieRiLiBao) 
	for index=1,table.getn(g_QiXi_Guide_Tip) do 
		g_QiXi_Guide_Tip[index]:Hide()
		g_QiXi_Guide_Button[index]:Hide()
	end

	for index=1,table.getn(g_QiXi_Guide_Tip)  do
		 local TipsState = Get_XParam_INT(index-1) 
		 g_Tips_Guide_StateTemp[index] 	    = TipsState
	end

	local curDay = DataPool:GetServerDayTime()
	local buttonId = 1
	for index=1,table.getn(g_QiXi_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   	= g_Tips_Guide_StateTemp[index]
		local event  			= g_QiXi_Guide_Event[index]

		if isButtonShow == 1 then 
			g_QiXi_Guide_Button[buttonId]:Show()
			if curDay < event.begtime then
				g_QiXi_Guide_Button[buttonId]:SetToolTip(event.btntips_unbeg)
			elseif curDay >= event.begtime and curDay <= event.endtime then
				g_QiXi_Guide_Button[buttonId]:SetToolTip(event.btntips_doing)
			elseif curDay > event.endtime then
				g_QiXi_Guide_Button[buttonId]:SetToolTip(event.btntips_end)
			end
			if isTipsShow == 1 then
				g_QiXi_Guide_Tip[buttonId]:Show()
			end
			event.isShow = 1
			buttonId = buttonId+1
		end
	end 	  
	
	if g_QiXi_Guide_GongLueTimeSP1 <= curDay and curDay <= g_QiXi_Guide_GongLueTimeSP2 then
		g_QiXi_Guide_Button[8]:SetToolTip("#{QXZH_200708_03}")
	end
	-- 如果领过节日礼包 就不再主界面显示这个按钮了
	if bShowJieRiLiBao == 1 then
		g_QiXi_Guide_Tip[7]:Hide()
		g_QiXi_Guide_Button[7]:Hide()
	end
	g_QiXi_Guide_Button[8]:Hide()
	g_QiXi_Guide_Button[6]:Hide()
	--设置小红点
	QiXi_Guide_ShowButtonTips()
end

--===============================================
-- 设置Button 小红点
--===============================================
function QiXi_Guide_ShowButtonTips()

	local buttonId = 1
	for index=1,table.getn(g_QiXi_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   = g_Tips_Guide_StateTemp[index]
		if isButtonShow == 1 then
			if isTipsShow == 1 then
				g_QiXi_Guide_Tip[buttonId]:Show()
			else
				g_QiXi_Guide_Tip[buttonId]:Hide()
			end
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

	--PushEvent("2019QIXI_TIPS",  IsShowMiniMapPoint)
	Lua_ShowQuickEnterPointTip(17, IsShowMiniMapPoint)
end

--===============================================
-- 打开各个功能界面
--===============================================
function QiXi_Guide_Clicked( clickId )
	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then 
        if curDay < g_QiXi_Guide_Event[1].begtime or curDay > g_QiXi_Guide_Event[1].endtime then
            PushDebugMessage("#{XQYJ_220527_01}")
            return
        end

        if Player:GetLevel() < g_QiXi_Guide_Event[1].level then
            PushDebugMessage("#{XQYJ_220527_02}")
            return
        end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenHuodongUI" )
			Set_XSCRIPT_ScriptID( 998120 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		QiXi_Guide_Close() 
	elseif clickId == 2 then 
		--七夕送信
		if curDay < g_QiXi_Guide_Event[2].begtime or curDay > g_QiXi_Guide_Event[2].endtime then
            PushDebugMessage("#{QXJSX_20220525_05}")
            return
        end

        if Player:GetLevel() < g_QiXi_Guide_Event[2].level then
            PushDebugMessage("#{QXJSX_20220525_06}")
            return
        end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenHuodongUI" )
			Set_XSCRIPT_ScriptID( 998115 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		QiXi_Guide_Close() 
	elseif clickId == 3 then  		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenAwardUI" )
			Set_XSCRIPT_ScriptID(893126)
			Set_XSCRIPT_Parameter(0, 3)					
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif clickId == 4 then
		if curDay < g_QiXi_Guide_Event[4].begtime or curDay > g_QiXi_Guide_Event[4].endtime then
            PushDebugMessage("#{QXJCJ_20220523_05}")
            return
        end

        if Player:GetLevel() < g_QiXi_Guide_Event[4].level then
            PushDebugMessage("#{QXJCJ_20220523_06}")
            return
		end		  
		PushEvent("OPEN_QIXICHOUJIANG")
	elseif clickId == 5 then   

        if curDay < g_QiXi_Guide_Event[5].begtime or curDay > g_QiXi_Guide_Event[5].endtime then
            PushDebugMessage("#{QXSD_190615_25}")
            return
        end

        if Player:GetLevel() < g_QiXi_Guide_Event[5].level then
            PushDebugMessage("#{QXSD_190615_26}")
            return
        end
		
		QiXi_Guide_Close() 
		
		-- 七夕商店 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpenShop" )
			Set_XSCRIPT_ScriptID( 892921 )
		Send_XSCRIPT()
	elseif clickId == 6 then  

		if curDay < g_QiXi_Guide_Event[6].begtime or curDay > g_QiXi_Guide_Event[6].endtime then
			PushDebugMessage("#{QXHF_190620_143}")
			return
		end
		  
		if Player:GetLevel() < g_QiXi_Guide_Event[6].level then
			PushDebugMessage("#{QXHF_190620_144}")
			return
		end
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenHunFuLevelUpUI" )
			Set_XSCRIPT_ScriptID( 893126 )
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif clickId == 7 then  
	
		if curDay < g_QiXi_Guide_Event[7].begtime or curDay > g_QiXi_Guide_Event[7].endtime then
            PushDebugMessage("#{QXZH_200708_08}")
            return
        end

        if Player:GetLevel() < g_QiXi_Guide_Event[7].level then
            PushDebugMessage("#{QXZH_200708_09}")
            return
        end
		
		-- 节日礼包 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID( 888113 )
		Send_XSCRIPT()
	
	elseif clickId == 8 then  

		if curDay < g_QiXi_Guide_Event[8].begtime or curDay > g_QiXi_Guide_Event[8].endtime then
            PushDebugMessage("#{QXZH_200708_10}")
            return
        end

        if Player:GetLevel() < g_QiXi_Guide_Event[7].level then
            PushDebugMessage("#{QXZH_200708_11}")
            return
        end
		
		-- 活动攻略 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID( 888112 )
		Send_XSCRIPT()
	elseif clickId == 9 then  
		if curDay < g_QiXi_Guide_Event[9].begtime or curDay > g_QiXi_Guide_Event[9].endtime then
            PushDebugMessage("#{QXTB_220610_03}")
            return
        end

        if Player:GetLevel() < g_QiXi_Guide_Event[9].level then
            PushDebugMessage("#{QXTB_220610_04}")
            return
        end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClickButton")
			Set_XSCRIPT_ScriptID(800996) 
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif clickId == 10 then  
		if curDay < g_QiXi_Guide_Event[10].begtime or curDay > g_QiXi_Guide_Event[10].endtime then
            PushDebugMessage("#{FBQY_220601_04}")
            return
        end

        if Player:GetLevel() < g_QiXi_Guide_Event[10].level then
            PushDebugMessage("#{FBQY_220601_05}")
            return
        end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClickButton")
			Set_XSCRIPT_ScriptID(800996) 
			Set_XSCRIPT_Parameter(0, 2)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif clickId == 11 then  
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnClick")
			Set_XSCRIPT_ScriptID(891738)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end 

end
