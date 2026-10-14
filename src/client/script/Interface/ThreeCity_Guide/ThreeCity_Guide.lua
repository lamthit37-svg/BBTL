--ThreeCity_Guide

local g_ThreeCity_Guide_Event = {
	[1] = {begtime=20221104, endtime =20221116, level =30, btntips_unbeg="#{SJJX_220811_61}", btntips_doing="#{SJJX_220811_02}", btntips_end="#{SJJX_220811_03}",},-- 新天外应景活动
	[2] = {begtime=20221104, endtime =20221116, level =30, btntips_unbeg="#{ZJSS_220803_134}", btntips_doing="#{ZJSS_220803_5}", btntips_end="#{ZJSS_220803_6}",},-- 拯救树灵
	[3] = {begtime=20221104, endtime =20221116, level =30, btntips_unbeg="#{DBXH_220811_129}", btntips_doing="#{DBXH_220811_05}", btntips_end="#{DBXH_220811_101}",},-- 代币结算玩法
	[4] = {begtime=20221104, endtime =20221116, level =30, btntips_unbeg="#{TWFW_220802_03}", btntips_doing="#{TWFW_220802_02}", btntips_end="#{TWFW_220802_04}",},--新天外服务器进度活动
	[5] = {begtime=20221104, endtime =20221120, level =30, btntips_unbeg="#{ZNYR_201019_02}", btntips_doing="#{ZNYR_201019_02}", btntips_end="#{ZNYR_201019_02}",},--曲流觞
	[6] = {begtime=20221104, endtime =20221120, level =30, btntips_unbeg="#{FBQF_201019_01}", btntips_doing="#{FBQF_201019_02}", btntips_end="#{FBQF_201019_02}",},--答渔歌
	[7] = {begtime=20221104, endtime =20221120, level =30, btntips_unbeg="", btntips_doing="", btntips_end="",},--  节日礼包
};

local g_ThreeCity_Guide_Frame_UnifiedPosition
local g_Button_Guide_StateTemp = {1,1,1,1,1,1,1}
local g_Tips_Guide_StateTemp = {0,0,0,0,0,0,0}

local g_ThreeCity_Guide_Button ={
}

local g_ThreeCity_Guide_Tip = {
}


function ThreeCity_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	
end

function ThreeCity_Guide_OnLoad()
	ThreeCity_Guide_LoadControl()
	g_ThreeCity_Guide_Frame_UnifiedPosition = ThreeCity_Guide_FrameNULL:GetProperty("UnifiedPosition") 
	
end
--=========
-- 装载控件
--=========
function ThreeCity_Guide_LoadControl()

	g_ThreeCity_Guide_Button[1] 	= ThreeCity_Guide_Activity1;
	g_ThreeCity_Guide_Button[2] 	= ThreeCity_Guide_Activity2;
	g_ThreeCity_Guide_Button[3] 	= ThreeCity_Guide_Activity3;
	g_ThreeCity_Guide_Button[4] 	= ThreeCity_Guide_Activity4;
	g_ThreeCity_Guide_Button[5] 	= ThreeCity_Guide_Activity5; 
	g_ThreeCity_Guide_Button[6] 	= ThreeCity_Guide_Activity6; 
	g_ThreeCity_Guide_Button[7] 	= ThreeCity_Guide_Rewards; 


	g_ThreeCity_Guide_Tip[1] 		= ThreeCity_Guide_Activity1_Tips;
	g_ThreeCity_Guide_Tip[2] 		= ThreeCity_Guide_Activity2_Tips;
	g_ThreeCity_Guide_Tip[3] 		= ThreeCity_Guide_Activity3_Tips;
	g_ThreeCity_Guide_Tip[4] 		= ThreeCity_Guide_Activity4_Tips;
	g_ThreeCity_Guide_Tip[5] 		= ThreeCity_Guide_Activity5_Tips; 
	g_ThreeCity_Guide_Tip[6] 		= ThreeCity_Guide_Activity6_Tips; 
	g_ThreeCity_Guide_Tip[7] 		= ThreeCity_Guide_Rewards_Tips; 

end
--=========
-- Event
--=========
function ThreeCity_Guide_OnEvent(event) 
	if(event == "UI_COMMAND" and tonumber(arg0) == 99820401) then
		if this:IsVisible() then
			ThreeCity_Guide_Close()
			return
		end
		AskServerTimeAgain() 
		local bShowJieRiLiBao = Get_XParam_INT(7)
		ThreeCity_Guide_Open(bShowJieRiLiBao)
		this:Show()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 99820501) then -- 特写礼包领完 button隐藏
		
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			g_ThreeCity_Guide_Button[7]:Hide()
			ThreeCity_Guide_Rewards_Open:Show()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ThreeCity_Guide_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		ThreeCity_Guide_Close()

	elseif event == "ADJEST_UI_POS" then

		ThreeCity_Guide_On_ResetPos()

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 99820402) then --显示小红点

		for index=1,table.getn(g_ThreeCity_Guide_Button)  do
			 local TipsState = Get_XParam_INT(index-1)
			 g_Tips_Guide_StateTemp[index]  = TipsState
		end
		ThreeCity_Guide_ShowButtonTips()  
		
	end

end
 
--=========
-- 重置
--=========
function ThreeCity_Guide_On_ResetPos()

	ThreeCity_Guide_FrameNULL:SetProperty("UnifiedPosition", g_ThreeCity_Guide_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function ThreeCity_Guide_Close() 
	this:Hide()
end

--=========
-- 打开
--=========
function ThreeCity_Guide_Open(bShowJieRiLiBao) 
	for index=1,table.getn(g_ThreeCity_Guide_Tip) do 
		g_ThreeCity_Guide_Tip[index]:Hide()
		g_ThreeCity_Guide_Button[index]:Hide()
	end

	for index=1,table.getn(g_ThreeCity_Guide_Tip)  do
		 local TipsState = Get_XParam_INT(index-1) 
		 g_Tips_Guide_StateTemp[index] 	    = TipsState
	end

	local curDay = DataPool:GetServerDayTime()
	--local buttonId = 1
	for index=1,table.getn(g_ThreeCity_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   	= g_Tips_Guide_StateTemp[index]
		local event  			= g_ThreeCity_Guide_Event[index]

		if isButtonShow == 1 then 
			g_ThreeCity_Guide_Button[index]:Show()
			if curDay < event.begtime then
				g_ThreeCity_Guide_Button[index]:SetToolTip(event.btntips_unbeg)
			elseif curDay >= event.begtime and curDay <= event.endtime then
				g_ThreeCity_Guide_Button[index]:SetToolTip(event.btntips_doing)
			elseif curDay > event.endtime then
				g_ThreeCity_Guide_Button[index]:SetToolTip(event.btntips_end)
			end
			if isTipsShow == 1 then
				g_ThreeCity_Guide_Tip[index]:Show()
			end
			event.isShow = 1
			--buttonId = buttonId+1
		end
	end 	  

	-- 如果领过节日礼包
	ThreeCity_Guide_Rewards_Open:Hide()	
	if bShowJieRiLiBao == 1 then
		g_ThreeCity_Guide_Button[7]:Hide()
		ThreeCity_Guide_Rewards_Open:Show()
	end
	
	g_ThreeCity_Guide_Button[7]:SetToolTip("#{TWHD_220803_12}")
	--设置小红点
	ThreeCity_Guide_ShowButtonTips()
end

--===============================================
-- 设置Button 小红点
--===============================================
function ThreeCity_Guide_ShowButtonTips()

	local buttonId = 1
	for index=1,table.getn(g_ThreeCity_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   = g_Tips_Guide_StateTemp[index]
		if isButtonShow == 1 then
			if isTipsShow == 1 then
				g_ThreeCity_Guide_Tip[index]:Show()
			else
				g_ThreeCity_Guide_Tip[index]:Hide()
			end
			--buttonId = buttonId+1
		end
	end

	local IsShowMiniMapPoint = 0
	for index=1,table.getn(g_Tips_Guide_StateTemp) do
		if g_Tips_Guide_StateTemp[index] == 1 then
			IsShowMiniMapPoint = 1
			break
		end
	end

	--PushEvent("NEWTIANWAI_TIPS",  IsShowMiniMapPoint)
	Lua_ShowQuickEnterPointTip(39, IsShowMiniMapPoint)

end

--===============================================
-- 打开各个功能界面
--===============================================
function ThreeCity_Guide_Clicked( clickId )
	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then
		--搜集军需
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpenUI" )
			Set_XSCRIPT_ScriptID( 998235 )
		Send_XSCRIPT()

	elseif clickId == 2 then
		--拯救树灵
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpenUI" )
			Set_XSCRIPT_ScriptID( 998225 )
		Send_XSCRIPT()
	elseif clickId == 3 then  		
		--剑指天荒
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpenJZTHUI" )
			Set_XSCRIPT_ScriptID( 998244 )
			Set_XSCRIPT_ParamCount( 0 )
		Send_XSCRIPT()
	elseif clickId == 4 then
		--新天外服务器进度活动
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpenUI" )
			Set_XSCRIPT_ScriptID( 888796 )
		Send_XSCRIPT()
	elseif clickId == 5 then   
		-- 曲流殇		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenAnniversaryPre2020" )
			Set_XSCRIPT_ScriptID( 893401 )
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif clickId == 6 then  
		-- 答渔歌		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenQiFuUI" )
			Set_XSCRIPT_ScriptID( 893403 )
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif clickId == 7 then  
	
		if curDay < g_ThreeCity_Guide_Event[7].begtime or curDay > g_ThreeCity_Guide_Event[7].endtime then
            PushDebugMessage("#{TWHD_220803_14}")
            return
        end

        if Player:GetLevel() < g_ThreeCity_Guide_Event[7].level then
            PushDebugMessage("#{TWHD_220803_15}")
            return
        end
		
		-- 节日礼包 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetPrize" )
			Set_XSCRIPT_ScriptID( 998205 )
		Send_XSCRIPT()
	
	
	end 

end
