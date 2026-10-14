--******************
--帮会活动定时开启
--******************

local g_BangHuiFuLi_Frame_UnifiedXPosition = 0
local g_BangHuiFuLi_Frame_UnifiedYPosition = 0

local g_Fuben_Grade = {
{str="#{DSKQ_141110_28}", CostMoney=20000000},
{str="#{DSKQ_141110_29}", CostMoney=30000000},
{str="#{DSKQ_141110_30}", CostMoney=40000000},
{str="#{DSKQ_141110_31}", CostMoney=50000000},
{str="#{DSKQ_141110_32}", CostMoney=60000000},
}

function BangHuiFuLi_PreLoad()
	this:RegisterEvent("OPEN_BANGHUIFULI")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function BangHuiFuLi_OnLoad()
	g_BangHuiFuLi_Frame_UnifiedXPosition = BangHuiFuLi_Frame:GetProperty("UnifiedXPosition")
	g_BangHuiFuLi_Frame_UnifiedYPosition = BangHuiFuLi_Frame:GetProperty("UnifiedYPosition")
end

function BangHuiFuLi_OnEvent(event)
	if (event == "OPEN_BANGHUIFULI") then
		BangHuiFuLi_Update()
		this:Show()

	elseif (event == "ADJEST_UI_POS" ) then
		BangHuiFuLi_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BangHuiFuLi_Frame_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	end
end

function BangHuiFuLi_Update()
	local IsFubenOnTime = Guild:GetMyGuildDetailInfo("IsFubenOnTime")
	local FubenOnTimeHour = Guild:GetMyGuildDetailInfo("FubenOnTimeHour")
	local FubenOnTimeMin = Guild:GetMyGuildDetailInfo("FubenOnTimeMin")
	local FubenOnTimeGrade = Guild:GetMyGuildDetailInfo("FubenOnTimeGrade")
	
	BangHuiFuLi_Frame_ShenBingGe_Open_Btn:SetCheck(IsFubenOnTime)
	
	if IsFubenOnTime == 1 then
		BangHuiFuLi_Frame_ShenBingGe_TimeNow_Text2:SetText("#cfff263"..FubenOnTimeHour.." #{DSKQ_141110_19} "..FubenOnTimeMin.." #{DSKQ_141110_20}")
	else
		BangHuiFuLi_Frame_ShenBingGe_TimeNow_Text2:SetText("#{DSKQ_141110_17}")
	end
	
	BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:ResetList()
	for i = 1,15 do
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:AddTextItem( i+7, i )
	end
	
	BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:ResetList()
	for i = 1,4 do
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:AddTextItem( (i-1) * 15, i )
	end
	
	BangHuiFuLi_Frame_ShenBingGe_Level_Select:ResetList()
	for i = 1,5 do
		BangHuiFuLi_Frame_ShenBingGe_Level_Select:AddTextItem( g_Fuben_Grade[i].str, i )
	end
	

	if IsFubenOnTime == 1 then
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:Enable()
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:Enable()
		BangHuiFuLi_Frame_ShenBingGe_Level_Select:Enable()
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:SetCurrentSelect( FubenOnTimeHour - 8 )
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:SetCurrentSelect( math.floor(FubenOnTimeMin/15) )
		BangHuiFuLi_Frame_ShenBingGe_Level_Select:SetCurrentSelect( FubenOnTimeGrade -1 )
		BangHuiFuLi_Frame_ShenBingGe_XiaoHao_Text2:SetProperty("MoneyNumber", tostring(g_Fuben_Grade[FubenOnTimeGrade].CostMoney))
	else
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:Disable()
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:Disable()
		BangHuiFuLi_Frame_ShenBingGe_Level_Select:Disable()
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:SetCurrentSelect( 0 )
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:SetCurrentSelect( 0 )
		BangHuiFuLi_Frame_ShenBingGe_Level_Select:SetCurrentSelect( 0 )
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:SetText( "" )
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:SetText( "" )
		BangHuiFuLi_Frame_ShenBingGe_Level_Select:SetText( "" )
		BangHuiFuLi_Frame_ShenBingGe_XiaoHao_Text2:SetProperty("MoneyNumber", tostring(0))
	end

end



function BangHuiFuLi_Frame_ShenBingGe_Open_Btn_Clicked()
	local IsFubenOnTimeCheck = BangHuiFuLi_Frame_ShenBingGe_Open_Btn:GetCheck()
	local IsFubenOnTime = Guild:GetMyGuildDetailInfo("IsFubenOnTime")
	local FubenOnTimeHour = Guild:GetMyGuildDetailInfo("FubenOnTimeHour")
	local FubenOnTimeMin = Guild:GetMyGuildDetailInfo("FubenOnTimeMin")
	local FubenOnTimeGrade = Guild:GetMyGuildDetailInfo("FubenOnTimeGrade")
	local ShenbinggeLevel = Guild:GetMyGuildDetailInfo("shenbinglevel")
	local szMsg = Guild:GetMyGuildDetailInfo("CityName")
	local ShenbinggeExist = tonumber(Guild:GetMyGuildDetailInfo("shenbinggeexist"))
	
	if IsFubenOnTimeCheck == 1 then
		if(szMsg == "-1") then
			PushDebugMessage( "#{DSKQ_141110_38}" )
			BangHuiFuLi_Frame_ShenBingGe_Open_Btn:SetCheck(0)
			return
		end
		if ShenbinggeLevel < 0 or ShenbinggeExist <= 0 then
			PushDebugMessage( "#{DSKQ_141110_39}" )
			BangHuiFuLi_Frame_ShenBingGe_Open_Btn:SetCheck(0)
			return
		end
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:Enable()
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:Enable()
		BangHuiFuLi_Frame_ShenBingGe_Level_Select:Enable()
		
		if IsFubenOnTime == 1 then
			BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:SetCurrentSelect( FubenOnTimeHour - 8 )
			BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:SetCurrentSelect( math.floor(FubenOnTimeMin/15) )
			BangHuiFuLi_Frame_ShenBingGe_Level_Select:SetCurrentSelect( FubenOnTimeGrade - 1 )
			BangHuiFuLi_Frame_ShenBingGe_XiaoHao_Text2:SetProperty("MoneyNumber", tostring(g_Fuben_Grade[FubenOnTimeGrade].CostMoney))
		else
			BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:SetCurrentSelect( 0 )
			BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:SetCurrentSelect( 0 )
			BangHuiFuLi_Frame_ShenBingGe_Level_Select:SetCurrentSelect( 0 )
			BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:SetText( "" )
			BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:SetText( "" )
			BangHuiFuLi_Frame_ShenBingGe_Level_Select:SetText( "" )
			BangHuiFuLi_Frame_ShenBingGe_XiaoHao_Text2:SetProperty("MoneyNumber", tostring(0))
		end
	else
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:Disable()
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:Disable()
		BangHuiFuLi_Frame_ShenBingGe_Level_Select:Disable()
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:SetCurrentSelect( 0 )
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:SetCurrentSelect( 0 )
		BangHuiFuLi_Frame_ShenBingGe_Level_Select:SetCurrentSelect( 0 )
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:SetText( "" )
		BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:SetText( "" )
		BangHuiFuLi_Frame_ShenBingGe_Level_Select:SetText( "" )
		BangHuiFuLi_Frame_ShenBingGe_XiaoHao_Text2:SetProperty("MoneyNumber", tostring(0))
	end
	
	
end


function BangHuiFuLi_Frame_ShenBingGe_Level_Select_SelectChanged()
	local FubenOnTimeGrade_Old = Guild:GetMyGuildDetailInfo("FubenOnTimeGrade")
	local _, FubenOnTimeGrade = BangHuiFuLi_Frame_ShenBingGe_Level_Select:GetCurrentSelect()
	local ShenbinggeLevel = Guild:GetMyGuildDetailInfo("shenbinggelevel")

	if FubenOnTimeGrade > ShenbinggeLevel then
		local str = ScriptGlobal_Format( "#{DSKQ_141110_40}", FubenOnTimeGrade, g_Fuben_Grade[FubenOnTimeGrade].str )
		PushDebugMessage( str )
		BangHuiFuLi_Frame_ShenBingGe_Level_Select:SetCurrentSelect( 0 )
		BangHuiFuLi_Frame_ShenBingGe_Level_Select:SetText( "" )
		BangHuiFuLi_Frame_ShenBingGe_XiaoHao_Text2:SetProperty("MoneyNumber", tostring(0))
		return
	end
	
	BangHuiFuLi_Frame_ShenBingGe_XiaoHao_Text2:SetProperty("MoneyNumber", tostring(g_Fuben_Grade[FubenOnTimeGrade].CostMoney))
end

function BangHuiFuLi_Buttons_Clicked()
	local FubenOnTime_Old = Guild:GetMyGuildDetailInfo("FubenOnTime")
	local FubenOnTime = 0
	local IsFubenOnTime = BangHuiFuLi_Frame_ShenBingGe_Open_Btn:GetCheck()
	local FubenOnTimeHour, _ = BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:GetCurrentSelect()
	local FubenOnTimeMin, _ = BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:GetCurrentSelect()
	local _, FubenOnTimeGrade = BangHuiFuLi_Frame_ShenBingGe_Level_Select:GetCurrentSelect()
	

	
	if IsFubenOnTime == 1 and ( BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetHour:GetText() == "" or BangHuiFuLi_Frame_ShenBingGe_TimeNew_SetMin:GetText() == "" ) then
		PushDebugMessage( "#{DSKQ_141110_45}" )
		return
	end
	
	if IsFubenOnTime == 1 and BangHuiFuLi_Frame_ShenBingGe_Level_Select:GetText() == "" then
		PushDebugMessage( "#{DSKQ_141110_47}" )
		return
	end
	
	
	if IsFubenOnTime == 0 then
		FubenOnTime = 0
	else
		FubenOnTime = IsFubenOnTime * 100000 + FubenOnTimeHour * 1000 + FubenOnTimeMin * 10 + FubenOnTimeGrade
	end
	
--	if JubaopenOnTime ~= JubaopenOnTime_Old or
	if	FubenOnTime ~= FubenOnTime_Old
	 then
		Guild:SetGuildOnTime(FubenOnTime)
	else
		PushDebugMessage( "#{DSKQ_141110_74}" )
		return
	end
	
end

function BangHuiFuLi_Cancel_Clicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BangHuiFuLi_Frame_On_ResetPos()
	BangHuiFuLi_Frame : SetProperty("UnifiedXPosition", g_BangHuiFuLi_Frame_UnifiedXPosition);
	BangHuiFuLi_Frame : SetProperty("UnifiedYPosition", g_BangHuiFuLi_Frame_UnifiedYPosition);
end
