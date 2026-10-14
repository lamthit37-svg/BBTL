--ZongMen_Guide

local g_ZongMen_Guide_Event = {
	[1] = {begtime=20231027, endtime =20231108, level =30, btntips_unbeg="#{ZMHD_230801_20}", btntips_doing="#{ZMHD_230801_19}", btntips_end="#{ZMHD_230801_21}",},-- 宗门版本交互活动
	[2] = {begtime=20231027, endtime =20231108, level =30, btntips_unbeg="#{ZNLSG_230215_11}", btntips_doing="#{ZNLSG_230215_10}", btntips_end="#{ZNLSG_230215_12}",},-- 宗门版本活动
	[3] = {begtime=20231027, endtime =20231108, level =30, btntips_unbeg="#{ZNQYJ_220215_04}", btntips_doing="#{ZNQYJ_220215_122}", btntips_end="#{ZNQYJ_220215_123}",},-- 时装兑换
	[4] = {begtime=20231027, endtime =20231108, level =30, btntips_unbeg="", btntips_doing="", btntips_end="",},--  节日礼包
};

local g_ZongMen_Guide_Frame_UnifiedPosition
local g_Button_Guide_StateTemp = {1,1,1,1}
local g_Tips_Guide_StateTemp = {0,0,0,0}

local g_ZongMen_Guide_Button ={
}

local g_ZongMen_Guide_Tip = {
}


function ZongMen_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	
end

function ZongMen_Guide_OnLoad()
	ZongMen_Guide_LoadControl()
	g_ZongMen_Guide_Frame_UnifiedPosition = ZongMen_Guide_Frame:GetProperty("UnifiedPosition") 
	
end
--=========
-- 装载控件
--=========
function ZongMen_Guide_LoadControl()

	g_ZongMen_Guide_Button[1] 	= ZongMen_Guide_Activity1;
	g_ZongMen_Guide_Button[2] 	= ZongMen_Guide_Activity2;
	g_ZongMen_Guide_Button[3] 	= ZongMen_Guide_Activity3;
	g_ZongMen_Guide_Button[4] 	= ZongMen_Guide_BaoXiang; 

	g_ZongMen_Guide_Tip[1] 		= ZongMen_Guide_Activity1_Tips;
	g_ZongMen_Guide_Tip[2] 		= ZongMen_Guide_Activity2_Tips;
	g_ZongMen_Guide_Tip[3] 		= ZongMen_Guide_Activity3_Tips;
	g_ZongMen_Guide_Tip[4] 		= ZongMen_Guide_Baoxiang_Tips;

end
--=========
-- Event
--=========
function ZongMen_Guide_OnEvent(event) 
	if(event == "UI_COMMAND" and tonumber(arg0) == 99884201) then
		if this:IsVisible() then
			ZongMen_Guide_Close()
			return
		end
		AskServerTimeAgain() 
		local bShowJieRiLiBao = Get_XParam_INT(4)
		ZongMen_Guide_Open(bShowJieRiLiBao)
		this:Show()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 99884301) then -- 特写礼包领完 button隐藏
		
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			g_ZongMen_Guide_Button[4]:Disable()
			ZongMen_Guide_Baoxiang_RewardBtnOK:Show()
		end

	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ZongMen_Guide_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		ZongMen_Guide_Close()

	elseif event == "ADJEST_UI_POS" then

		ZongMen_Guide_On_ResetPos()

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 99884202) then --显示小红点

		for index=1,table.getn(g_ZongMen_Guide_Button)  do
			 local TipsState = Get_XParam_INT(index-1)
			 g_Tips_Guide_StateTemp[index]  = TipsState
		end
		ZongMen_Guide_ShowButtonTips()  
		
	end

end
 
--=========
-- 重置
--=========
function ZongMen_Guide_On_ResetPos()

	ZongMen_Guide_Frame:SetProperty("UnifiedPosition", g_ZongMen_Guide_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function ZongMen_Guide_Close() 
	this:Hide()
end

--=========
-- 打开
--=========
function ZongMen_Guide_Open(bShowJieRiLiBao) 
	for index=1,table.getn(g_ZongMen_Guide_Tip) do 
		g_ZongMen_Guide_Tip[index]:Hide()
		g_ZongMen_Guide_Button[index]:Hide()
	end

	for index=1,table.getn(g_ZongMen_Guide_Tip)  do
		 local TipsState = Get_XParam_INT(index-1) 
		 g_Tips_Guide_StateTemp[index] 	    = TipsState
	end

	local curDay = DataPool:GetServerDayTime()
	--local buttonId = 1
	for index=1,table.getn(g_ZongMen_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   	= g_Tips_Guide_StateTemp[index]
		local event  			= g_ZongMen_Guide_Event[index]

		if isButtonShow == 1 then 
			g_ZongMen_Guide_Button[index]:Show()
			if curDay < event.begtime then
				g_ZongMen_Guide_Button[index]:SetToolTip(event.btntips_unbeg)
			elseif curDay >= event.begtime and curDay <= event.endtime then
				g_ZongMen_Guide_Button[index]:SetToolTip(event.btntips_doing)
			elseif curDay > event.endtime then
				g_ZongMen_Guide_Button[index]:SetToolTip(event.btntips_end)
			end
		end
	end 	  
	
	--礼包tips
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(141) > 0 then
		ZongMen_Guide_BaoXiang:SetToolTip("#{ZMBB_230809_13}")
	else
		ZongMen_Guide_BaoXiang:SetToolTip("#{ZMBB_230809_05}")
	end
	
	-- 如果领过节日礼包
	if bShowJieRiLiBao == 1 then
		g_ZongMen_Guide_Button[4]:Disable()
		ZongMen_Guide_Baoxiang_RewardBtnOK:Show()
	else
		g_ZongMen_Guide_Button[4]:Enable()
		ZongMen_Guide_Baoxiang_RewardBtnOK:Hide()
	end
	
	
	--设置小红点
	ZongMen_Guide_ShowButtonTips()
end

--===============================================
-- 设置Button 小红点
--===============================================
function ZongMen_Guide_ShowButtonTips()

	local buttonId = 1
	for index=1,table.getn(g_ZongMen_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   = g_Tips_Guide_StateTemp[index]
		if isButtonShow == 1 then
			if isTipsShow == 1 then
				g_ZongMen_Guide_Tip[index]:Show()
			else
				g_ZongMen_Guide_Tip[index]:Hide()
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

	Lua_ShowQuickEnterPointTip(51, IsShowMiniMapPoint)

end

--===============================================
-- 打开各个功能界面
--===============================================
function ZongMen_Guide_ActivityOnClick( clickId )
	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenWindowRequest" )
			Set_XSCRIPT_ScriptID( 998830 )
		Send_XSCRIPT()

	elseif clickId == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenMainUI")
			Set_XSCRIPT_ScriptID(290400) 
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 3 then
		if IsInTServer() == 1 then
			--T服不允许操作
			PushDebugMessage("#{ZNQYJ_220215_120}")
			return
		end

		if Player:GetLevel() < 30 then
			PushDebugMessage("#{ZNQYJ_220215_02}")
			return
		end
		
		local curDay = DataPool:GetServerDayTime()
		if curDay < g_ZongMen_Guide_Event[clickId].begtime or curDay > g_ZongMen_Guide_Event[clickId].endtime then
			PushDebugMessage("#{ZNQYJ_220215_03}")
			return
		end

		--领取时装
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnAskOpenDressUI")
			Set_XSCRIPT_ScriptID(998823)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()

	elseif clickId == 4 then
		-- 节日礼包 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetPrize" )
			Set_XSCRIPT_ScriptID( 998843 )
		Send_XSCRIPT()
	end 

end
