--ValentineAlbum

local g_ValentineAlbum_Frame_UnifiedPosition


local g_ValentineAlbum_Locked = {}
local g_ValentineAlbum_FinishImage = {}
local g_ValentineAlbum_Page = {}
local g_ValentineAlbum_Details= {}
local g_ValentineAlbum_LockImage = {}

local g_ValentineAlbum_GiftButton = {}
local g_ValentineAlbum_GiftTips = {}
local g_ValentineAlbum_GiftMask = {}
local g_ValentineAlbum_ShowMissionInfo = {}

local g_CurPage = 0
local g_IsBind = 0
local g_BindPartnerName = ""
local g_Stage = 0
local g_EventData = {0,0,0,0,0,0,0,0,0,0,0,0}
local g_PrizeFlag = {0,0,0,0}
local g_FinishCount = 0
local g_EventProcess = {3,6,9,12}
local g_Tips = {
	[1] = "#{QRJJN_221118_16}",
	[2] = "#{QRJJN_221118_17}",
	[3] = "#{QRJJN_221118_18}",
	[4] = "#{QRJJN_221118_19}",
}

function ValentineAlbum_PreLoad()
    this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function ValentineAlbum_OnLoad()

	for i = 1, 12 do
		g_ValentineAlbum_Locked[i] = "ValentineAlbum_TaskLocked"..i
		g_ValentineAlbum_FinishImage[i] = "ValentineAlbum_TaskFinished"..i
		g_ValentineAlbum_Details[i] = "ValentineAlbum_TaskDetails"..i
		g_ValentineAlbum_LockImage[i] = "ValentineAlbum_TaskUnLockedTimeBK"..i
	end
	
	for i = 1, 12 do
		g_ValentineAlbum_ShowMissionInfo[i] = {
			locked = _G[g_ValentineAlbum_Locked[i]],
			finish = _G[g_ValentineAlbum_FinishImage[i]],
			details = _G[g_ValentineAlbum_Details[i]],
			lockImage = _G[g_ValentineAlbum_LockImage[i]],
		}
	end
	
	g_ValentineAlbum_Page[1] = ValentineAlbum_Page1
	g_ValentineAlbum_Page[2] = ValentineAlbum_Page2
	g_ValentineAlbum_Page[3] = ValentineAlbum_Page3
	g_ValentineAlbum_Page[4] = ValentineAlbum_Page4
	
	g_ValentineAlbum_GiftButton[1] = ValentineAlbum_Gift1
	g_ValentineAlbum_GiftButton[2] = ValentineAlbum_Gift2
	g_ValentineAlbum_GiftButton[3] = ValentineAlbum_Gift3
	g_ValentineAlbum_GiftButton[4] = ValentineAlbum_Gift4
	
	g_ValentineAlbum_GiftTips[1] = ValentineAlbum_Gift_Tips1
	g_ValentineAlbum_GiftTips[2] = ValentineAlbum_Gift_Tips2
	g_ValentineAlbum_GiftTips[3] = ValentineAlbum_Gift_Tips3
	g_ValentineAlbum_GiftTips[4] = ValentineAlbum_Gift_Tips4
	
	g_ValentineAlbum_GiftMask[1] = ValentineAlbum_Gift_GetMark1
	g_ValentineAlbum_GiftMask[2] = ValentineAlbum_Gift_GetMark2
	g_ValentineAlbum_GiftMask[3] = ValentineAlbum_Gift_GetMark3
	g_ValentineAlbum_GiftMask[4] = ValentineAlbum_Gift_GetMark4
	
    g_ValentineAlbum_Frame_UnifiedPosition = ValentineAlbum_Frame:GetProperty("UnifiedPosition")

end

function ValentineAlbum_OnEvent(event)

	if ( event == "SCENE_TRANSED" ) then
		ValentineAlbum_Close()

	elseif (event == "ADJEST_UI_POS" ) then
		ValentineAlbum_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ValentineAlbum_On_ResetPos()
	
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 99835602) then
		local operator = Get_XParam_INT( 0 )
		g_IsBind = Get_XParam_INT( 1 )
		g_BindPartnerName = Get_XParam_STR(0)
		g_Stage = Get_XParam_INT( 2 )
		g_CurPage = Get_XParam_INT( 3 )
		if g_CurPage >= 1 and g_CurPage <= 4 then
			g_EventData[(g_CurPage-1)*3+1] = Get_XParam_INT( 4 )
			g_EventData[(g_CurPage-1)*3+2] = Get_XParam_INT( 5 )
			g_EventData[(g_CurPage-1)*3+3] = Get_XParam_INT( 6 )
		end
		for i = 1, 4 do
			g_PrizeFlag[i] = Get_XParam_INT( 6+i )
		end
		g_FinishCount = Get_XParam_INT( 11 )
		
		if operator == 1 then
			ValentineAlbum_Update()
		elseif operator == 2 then
			if this:IsVisible() then
				ValentineAlbum_Update()
			end
		end

	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 99835603 and this:IsVisible()) then
		local g_Stage = Get_XParam_INT( 0 )
		
		ValentineAlbum_Update()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99835605 then
		AutoRuntoTargetExWithName(176, 111, 164, "杰尼")
		ValentineAlbum_Close()
	end
end

function ValentineAlbum_Update()
	--绑定
	if g_IsBind == 1 then
		ValentineAlbum_UnboundFrame:Hide()
		ValentineAlbum_BindedFrame:Show()
		local text = ScriptGlobal_Format("#{QRJJN_221118_11}",g_BindPartnerName)
		ValentineAlbum_BangdingInfo:SetText(text)
		ValentineAlbum_PageUpdate(g_CurPage)
	--未绑定
	else
		ValentineAlbum_UnboundFrame:Show()
		ValentineAlbum_BindedFrame:Hide()	
	end
	--进度
	local text = ScriptGlobal_Format("#{QRJJN_221118_23}", g_FinishCount)
	ValentineAlbum_Gift_ProgressNum:SetText(text)
	ValentineAlbum_Gift_Progress:SetProgress(tonumber(g_FinishCount), 12)

	--奖励
	for i = 1, 4 do
		if g_PrizeFlag[i] > 0 then
			g_ValentineAlbum_GiftButton[i]:Disable()
			g_ValentineAlbum_GiftMask[i]:Show()
			g_ValentineAlbum_GiftTips[i]:Hide()
		else
			g_ValentineAlbum_GiftButton[i]:Enable()
			g_ValentineAlbum_GiftMask[i]:Hide()
			if g_FinishCount >= g_EventProcess[i] then
				g_ValentineAlbum_GiftTips[i]:Show()
			else
				g_ValentineAlbum_GiftTips[i]:Hide()
			end
		end
	end
	this:Show()
end

function ValentineAlbum_PageUpdate(nPage)
	if nPage < 1 or nPage > 4 then
		return
	end
	
	--上下页
	ValentineAlbum_LeftArrow:Enable()
	ValentineAlbum_RightArrow:Enable()
	if nPage <= 1 then
		ValentineAlbum_LeftArrow:Disable()
	elseif nPage >= 4 then
		ValentineAlbum_RightArrow:Disable()
	end
	
	for i = 1, 4 do
		if nPage == i then
			g_ValentineAlbum_Page[i]:Show()
		else
			g_ValentineAlbum_Page[i]:Hide()
		end
	end
	
	--事件
	for i = 1, 3 do
		g_ValentineAlbum_ShowMissionInfo[(nPage-1)*3+i].details:SetToolTip("#{QRJJN_221118_20}")
		
		if nPage <= g_Stage then --解锁
			g_ValentineAlbum_ShowMissionInfo[(nPage-1)*3+i].lockImage:Hide()
		else
			g_ValentineAlbum_ShowMissionInfo[(nPage-1)*3+i].details:SetToolTip(g_Tips[nPage])
			g_ValentineAlbum_ShowMissionInfo[(nPage-1)*3+i].lockImage:Show()
		end
		
		if g_EventData[(nPage-1)*3+i] > 0 then --已完成
			g_ValentineAlbum_ShowMissionInfo[(nPage-1)*3+i].locked:Hide()
			g_ValentineAlbum_ShowMissionInfo[(nPage-1)*3+i].finish:Show()
			g_ValentineAlbum_ShowMissionInfo[(nPage-1)*3+i].details:SetToolTip("#{QRJJN_221118_21}")
		else
			g_ValentineAlbum_ShowMissionInfo[(nPage-1)*3+i].locked:Show()
			g_ValentineAlbum_ShowMissionInfo[(nPage-1)*3+i].finish:Hide()
		end		
	end
end

function ValentineAlbum_Gift_Clicked(index)
	if index < 1 or index > 4 then
		return
	end
	
	if g_CurPage < 1 or g_CurPage > 4 then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetReward" )
		Set_XSCRIPT_ScriptID( 998356 )
		Set_XSCRIPT_Parameter( 0, g_CurPage )
		Set_XSCRIPT_Parameter( 1, index )
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
end

--查看详情
function ValentineAlbum_TaskDetailsClicked(index)
	if index < 1 or index > 12 then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenDetailsUI" )
		Set_XSCRIPT_ScriptID( 998356 )
		Set_XSCRIPT_Parameter( 0, index )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
	
end

--上一页
function ValentineAlbum_PreClick()
	if g_CurPage <= 1 or g_CurPage > 4 then
		return
	end
	
	g_CurPage = g_CurPage-1
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RefreshUI" )
		Set_XSCRIPT_ScriptID( 998356 )
		Set_XSCRIPT_Parameter( 0, g_CurPage )
		Set_XSCRIPT_Parameter( 1, 2 )
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
end

--下一页
function ValentineAlbum_NextClick()
	if g_CurPage < 1 or g_CurPage >= 4 then
		return
	end
	
	g_CurPage = g_CurPage+1
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RefreshUI" )
		Set_XSCRIPT_ScriptID( 998356 )
		Set_XSCRIPT_Parameter( 0, g_CurPage )
		Set_XSCRIPT_Parameter( 1, 2 )
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
end

function ValentineAlbum_BangdingClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GotoBind" )
		Set_XSCRIPT_ScriptID( 998356 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--关闭
function ValentineAlbum_Close()
	if ( IsWindowShow( "ValentineAlbum_Diary" ) ) then
		CloseWindow( "ValentineAlbum_Diary", true );
	end 
	
	this:Hide()
end

function ValentineAlbum_On_ResetPos()
    ValentineAlbum_Frame:SetProperty("UnifiedPosition", g_ValentineAlbum_Frame_UnifiedPosition)
end


function ValentineAlbum_HelpClick()
	PushEvent("CCSHOP_HELP", 175)
end
