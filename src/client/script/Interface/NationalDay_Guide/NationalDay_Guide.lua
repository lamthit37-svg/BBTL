--国庆系列

local g_NationalDay_Guide_Event = {
	--露华宴
	[1] = {begtime=20250925, endtime =20251019, level =30, btntips_unbeg="#{GQKJ_190722_07}", btntips_doing="#{GQKJ_190722_07}", btntips_end="#{GQKJ_190722_08}",},
	--戏龙醉花风
	[2] = {begtime=20250925, endtime =20251019, level =30, btntips_unbeg="#{GQKJ_190722_10}", btntips_doing="#{GQKJ_190722_10}", btntips_end="#{GQKJ_190722_11}",},	
	--国色生香
	[3] = {begtime=20251001, endtime =20251019, level =30, btntips_unbeg="#{GQKJ_190722_14}", btntips_doing="#{GQKJ_190722_15}", btntips_end="#{GQKJ_190722_16}",},
	--国庆签到活动
	[4] = {begtime=20221001, endtime =20221009, level =30, btntips_unbeg="#{GQKJ_190722_17}", btntips_doing="#{GQKJ_190722_18}", btntips_end="#{GQKJ_190722_19}",},
	--芙蓉商店
	[5] = {begtime=20230925, endtime =20231008, level =30, btntips_unbeg="#{GQKJ_190722_20}", btntips_doing="#{GQKJ_190722_20}", btntips_end="#{GQKJ_190722_21}",},
	--基金活动
	[6] = {begtime=20230925, endtime =20231008, level =30, btntips_unbeg="#{GQKJ_190722_24}", btntips_doing="#{GQKJ_190722_24}", btntips_end="#{GQKJ_190722_25}",},	
	--飞花藏宝阁
	[7] = {begtime=20250925, endtime =20251019, level =30, btntips_unbeg="#{GQKJ_190722_26}", btntips_doing="#{GQKJ_190722_27}", btntips_end="#{GQKJ_190722_27}",},	
	--H5线下活动
	[8] = {begtime=20251001, endtime =20251008, level =30, btntips_unbeg="#{QCJN_190809_13}", btntips_doing="#{GQKJ_190722_204}", btntips_end="#{GQKJ_190722_19}",},	
	--节日礼包
	[9] = {begtime=20250925, endtime =20251019, level =30, btntips_unbeg="#{GQZH_200714_05}", btntips_doing="#{GQZH_200714_05}", btntips_end="#{GQZH_200714_05}",},	
	--活动攻略
	[10] = {begtime=20250925, endtime =20251019, level =30, btntips_unbeg="#{GQZH_200714_08}", btntips_doing="#{GQZH_200714_08}", btntips_end="#{GQZH_200714_08}",},
	--双倍时间
	[11] = {begtime=20251011, endtime =20251019, level =30, btntips_unbeg="#{GQHY_220818_02}", btntips_doing="#{GQKJ_190722_221}", btntips_end="#{GQKJ_190722_221}",},
	--瑶华纳金缕
	[12] = {begtime=20210923, endtime =20211017, level =30, btntips_unbeg="#{ZQZH_200715_02}", btntips_doing="#{ZQZH_200715_01}", btntips_end="#{ZQZH_200715_02}",},
	--节日礼包(中秋)
	[13] = {begtime=20251006, endtime =20251019, level =30, btntips_unbeg="#{ZQZH_200715_01}", btntips_doing="#{ZQZH_200715_01}", btntips_end="#{ZQZH_200715_01}",},	
};
local g_NationalDay_Guide_Frame_UnifiedPosition
local g_Button_Guide_StateTemp = {1,1,1,0,0,0,1,1,1,1,1,0,1}
local g_Tips_Guide_StateTemp = {0,0,0,0,0,0,0,0,0,0,0,0,0}

local g_NationalDay_Guide_Button ={
}

local g_NationalDay_Guide_Tip = {
}

local g_NationalDay_Guide_BeginTime = 20250925
local g_NationalDay_Guide_EndTime = 20251019

function NationalDay_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	
end

function NationalDay_Guide_OnLoad()
	NationalDay_Guide_LoadControl()
	g_NationalDay_Guide_Frame_UnifiedPosition = NationalDay_Guide_Frame:GetProperty("UnifiedPosition") 
	
end

--=========
-- 装载控件
--=========
function NationalDay_Guide_LoadControl()

	g_NationalDay_Guide_Button[1] 	= NationalDay_Guide_Btn1
	g_NationalDay_Guide_Button[2] 	= NationalDay_Guide_Btn2 
	g_NationalDay_Guide_Button[3] 	= NationalDay_Guide_Btn3
	g_NationalDay_Guide_Button[4] 	= NationalDay_Guide_Btn4
	g_NationalDay_Guide_Button[5] 	= NationalDay_Guide_Btn5
	g_NationalDay_Guide_Button[6] 	= NationalDay_Guide_Btn6 
	g_NationalDay_Guide_Button[7] 	= NationalDay_Guide_Btn7
	g_NationalDay_Guide_Button[8] 	= NationalDay_Guide_Btn8
	g_NationalDay_Guide_Button[9] 	= NationalDay_Guide_BtnGift
	g_NationalDay_Guide_Button[10] 	= NationalDay_Guide_BtnAward
	g_NationalDay_Guide_Button[11] 	= NationalDay_Guide_Btn9
	g_NationalDay_Guide_Button[12] 	= NationalDay_Guide_Btn10
	g_NationalDay_Guide_Button[13] 	= NationalDay_Guide_BtnGift2
	
	g_NationalDay_Guide_Tip[1] 	= NationalDay_Guide_Btn1_Tips
	g_NationalDay_Guide_Tip[2] 	= NationalDay_Guide_Btn2_Tips
	g_NationalDay_Guide_Tip[3] 	= NationalDay_Guide_Btn3_Tips
	g_NationalDay_Guide_Tip[4] 	= NationalDay_Guide_Btn4_Tips
	g_NationalDay_Guide_Tip[5] 	= NationalDay_Guide_Btn5_Tips 
	g_NationalDay_Guide_Tip[6] 	= NationalDay_Guide_Btn6_Tips  
	g_NationalDay_Guide_Tip[7] 	= NationalDay_Guide_Btn7_Tips 
	g_NationalDay_Guide_Tip[8] 	= NationalDay_Guide_Btn8_Tips 
	g_NationalDay_Guide_Tip[9] 	= NationalDay_Guide_BtnGift_Tips 
	g_NationalDay_Guide_Tip[10] = NationalDay_Guide_BtnAward_Tips 
	g_NationalDay_Guide_Tip[11] = NationalDay_Guide_Btn9_Tips
	g_NationalDay_Guide_Tip[12] = NationalDay_Guide_Btn10_Tips
	g_NationalDay_Guide_Tip[13] = NationalDay_Guide_BtnGift2_Tips
end

--=========
-- Event
--=========
function NationalDay_Guide_OnEvent(event) 
	if(event == "UI_COMMAND" and tonumber(arg0) == 89315701) then -- 
		if this:IsVisible() then
			NationalDay_Guide_Close()
			return
		end
		
		AskServerTimeAgain() 
		local bShowJieRiLiBao = Get_XParam_INT(table.getn(g_NationalDay_Guide_Event))
		local bShowJieRiLiBao2 = Get_XParam_INT(table.getn(g_NationalDay_Guide_Event)+1)
		NationalDay_Guide_Open(bShowJieRiLiBao, bShowJieRiLiBao2)
		this:Show()

		-- 关闭shopshow界面
		PushEvent("UI_COMMAND", 89315806, 0)

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 88811501) then -- 特写礼包领完 button隐藏
		
		local bShow = Get_XParam_INT(0)
		if bShow == 2 then
			g_NationalDay_Guide_Button[9]:Hide()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		NationalDay_Guide_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		NationalDay_Guide_Close()

	elseif event == "ADJEST_UI_POS" then

		NationalDay_Guide_On_ResetPos()

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89315702) then --显示小红点

		for index=1,table.getn(g_NationalDay_Guide_Button)  do
			 local TipsState = Get_XParam_INT(index-1)
			 g_Tips_Guide_StateTemp[index] = TipsState
		end
		NationalDay_Guide_ShowButtonTips()  
		
	end

end
 
--=========
-- 重置
--=========
function NationalDay_Guide_On_ResetPos()

	NationalDay_Guide_Frame:SetProperty("UnifiedPosition", g_NationalDay_Guide_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function NationalDay_Guide_Close() 
	this:Hide()
end

--=========
-- 打开
--=========
function NationalDay_Guide_Open(bShowJieRiLiBao, bShowJieRiLiBao2) 

	for index = 1, table.getn(g_NationalDay_Guide_Tip) do 
		g_NationalDay_Guide_Tip[index]:Hide()
		g_NationalDay_Guide_Button[index]:Hide()
	end

	for index = 1, table.getn(g_NationalDay_Guide_Tip)  do
		 local TipsState = Get_XParam_INT(index-1) 
		 g_Tips_Guide_StateTemp[index] = TipsState
	end

	local curDay = DataPool:GetServerDayTime()
	local buttonId = 1
	for index = 1, table.getn(g_NationalDay_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow = g_Tips_Guide_StateTemp[index]
		local event = g_NationalDay_Guide_Event[index]

		if isButtonShow == 1 then 
			g_NationalDay_Guide_Button[buttonId]:Show()
			if curDay < event.begtime then
				g_NationalDay_Guide_Button[buttonId]:SetToolTip(event.btntips_unbeg)
			elseif curDay >= event.begtime and curDay <= event.endtime then
				g_NationalDay_Guide_Button[buttonId]:SetToolTip(event.btntips_doing)
			elseif curDay > event.endtime then
				g_NationalDay_Guide_Button[buttonId]:SetToolTip(event.btntips_end)
			end
			if isTipsShow == 1 then
				g_NationalDay_Guide_Tip[buttonId]:Show()
			end
			event.isShow = 1
			buttonId = buttonId + 1
		else
			buttonId = buttonId + 1
		end
	end 

	--签到特写
	local event = g_NationalDay_Guide_Event[4]
	if curDay < event.begtime then
		g_NationalDay_Guide_Button[4]:SetToolTip(event.btntips_unbeg)
	elseif curDay >= event.begtime and curDay <= event.endtime then
		g_NationalDay_Guide_Button[4]:SetToolTip(event.btntips_doing)
	elseif curDay > event.endtime and curDay <= 20191013 then
		g_NationalDay_Guide_Button[4]:SetToolTip("#{DQDL_180814_49}")
	elseif curDay > 20191013 then
		g_NationalDay_Guide_Button[4]:SetToolTip("#{GQKJ_190722_19}")
	end 
	
	--中秋节日礼包特写
	event = g_NationalDay_Guide_Event[13]
	if curDay < event.begtime or curDay > event.endtime or bShowJieRiLiBao2 == 1 then
		g_NationalDay_Guide_Button[13]:Hide()
		g_NationalDay_Guide_Tip[13]:Hide()
	end	
	
	-- 如果领过节日礼包 就不再主界面显示这个按钮了
	if bShowJieRiLiBao == 1 then
		g_NationalDay_Guide_Tip[9]:Hide()
		g_NationalDay_Guide_Button[9]:Hide()
	end
	
	--设置小红点
	NationalDay_Guide_ShowButtonTips()
end

--===============================================
-- 设置Button 小红点
--===============================================
function NationalDay_Guide_ShowButtonTips()

	local buttonId = 1
	for index = 1, table.getn(g_NationalDay_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow = g_Tips_Guide_StateTemp[index]
		if isButtonShow == 1 then
			if isTipsShow == 1 then
				g_NationalDay_Guide_Tip[buttonId]:Show()
			else
				g_NationalDay_Guide_Tip[buttonId]:Hide()
			end
			buttonId = buttonId + 1
		else
			buttonId = buttonId + 1
		end
	end

	local IsShowMiniMapPoint = 0
	for index = 1, table.getn(g_Tips_Guide_StateTemp) do
		if g_Tips_Guide_StateTemp[index] == 1 then
			IsShowMiniMapPoint = 1
			break
		end
	end
 
	Lua_ShowQuickEnterPointTip(19, IsShowMiniMapPoint)
end

--===============================================
-- 打开各个功能界面
--===============================================
function NationalDay_Guide_Clicked( clickId )
	local curDay = DataPool:GetServerDayTime()
	
	if clickId == 1 then 
        Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClickButton")
			Set_XSCRIPT_ScriptID(893148) 
			Set_XSCRIPT_Parameter( 0, 1 )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()

        if curDay < g_NationalDay_Guide_Event[1].begtime or curDay > g_NationalDay_Guide_Event[1].endtime then
            PushDebugMessage("#{GQKJ_190722_04}")
            return
        end

        if Player:GetLevel() < g_NationalDay_Guide_Event[1].level then
            PushDebugMessage("#{GQKJ_190722_05}")
            return
        end

        local ret = AutoRunToTargetEx(256, 288, 0)
        if 0 == ret then
			PushDebugMessage("#{GQKJ_190722_158}")
            return
        end
        PushDebugMessage("#{GQKJ_190722_09}")
       
        NationalDay_Guide_Close() 
		
	elseif clickId == 2 then 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClickButton")
			Set_XSCRIPT_ScriptID(893148) 
			Set_XSCRIPT_Parameter( 0, 2 )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()

		if curDay < g_NationalDay_Guide_Event[2].begtime or curDay > g_NationalDay_Guide_Event[2].endtime then
			PushDebugMessage("#{GQKJ_190722_04}")
			return
		end
      
		if Player:GetLevel() < g_NationalDay_Guide_Event[1].level then
			PushDebugMessage("#{GQKJ_190722_05}")
			return
		end
      
		local ret = AutoRuntoTargetExWithName(266, 255, 0, "苏曼卿")
		if 0 == ret then
			PushDebugMessage("#{GQKJ_190722_158}")
			return
		end
		PushDebugMessage("#{GQKJ_190722_12}")
	
		NationalDay_Guide_Close() 
	--芙蓉醉
	elseif clickId == 3 then 	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpenNatiaonalDay" )
			Set_XSCRIPT_ScriptID( 892911 )
			Set_XSCRIPT_Parameter(0,2)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT() 
	--签到
	elseif clickId == 4 then 
		if curDay < g_NationalDay_Guide_Event[4].begtime or curDay > g_NationalDay_Guide_Event[4].endtime then
            PushDebugMessage("#{GQKJ_190722_04}")
            return
		end
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpenNatiaonalDay" )
			Set_XSCRIPT_ScriptID( 892911 )
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()  

	elseif clickId == 5 then  
	   
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenNatiaonalShop")
			Set_XSCRIPT_ScriptID(893158) 
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		
	elseif clickId == 6 then
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpenNatiaonalFund" )
			Set_XSCRIPT_ScriptID( 893166 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()  
		
	elseif clickId == 7 then
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID( 893167 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		
	elseif clickId == 8 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClickButton")
			Set_XSCRIPT_ScriptID(893236)
			Set_XSCRIPT_ParamCount( 0 )
		Send_XSCRIPT()

	elseif clickId == 9 then
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID( 888115 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		
	elseif clickId == 10 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowClientUI")
			Set_XSCRIPT_ScriptID(888116) 
			Set_XSCRIPT_ParamCount( 0 )
		Send_XSCRIPT()
	elseif clickId == 11 then		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClickButton")
			Set_XSCRIPT_ScriptID(339015)
			Set_XSCRIPT_ParamCount( 0 )
		Send_XSCRIPT()	
		--PushEvent("OPEN_DOUBLEEXP_TEXT")
	elseif clickId == 12 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowClientUI")
			Set_XSCRIPT_ScriptID(505099)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		NationalDay_Guide_Close()
	elseif clickId == 13 then
		 -- 礼包
        Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID(888132)			
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end 

end
