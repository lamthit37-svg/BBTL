local g_XSP_Frame_UnifiedXPosition
local g_XSP_Frame_UnifiedYPosition

local g_grandPrizeName

function Xuanshang_Prize_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

end


function Xuanshang_Prize_OnLoad()
	g_XSP_Frame_UnifiedXPosition	= Xuanshang_Prize_Frame_BK : GetProperty("UnifiedXPosition")
	g_XSP_Frame_UnifiedYPosition	= Xuanshang_Prize_Frame_BK : GetProperty("UnifiedYPosition")
		
end

function Xuanshang_Prize_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 5061001) then
		Xuanshang_Prize_Open()	
	elseif (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" ) then
		Xuanshang_Prize_On_ResetPos()
	elseif event == "UPDATE_REDPOINT_IN_UI" then
		Xuanshang_Prize_FlashUIRedPoint()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Xuanshang_Prize_OnHidden()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_Xuanshang_Prize_ClientObjid) then
			return
		end

		if arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy" then
			Xuanshang_Prize_Cancel_Clicked()
		end
	end
	
end

function Xuanshang_Prize_Open()	
	local nCurDay = DataPool:GetServerDayTime()
	local ds,dt,taskNum,itemID,displayID,forceBind,itemCount,uiSeq,precious = ZhanTuanInterface:GetBountyTaskInfo(nCurDay)
	
	if nCurDay == dt then
		local theAction = DataPool:CreateActionItemForShow(displayID, itemCount)
		if theAction:GetID() ~= 0 then
			Xuanshang_Prize_Pic:Show()
			Xuanshang_Prize_Pic:SetActionItem(theAction:GetID())
		end
	end
	
	local prizeDate = tonumber(Get_XParam_INT(0))
	if( prizeDate and prizeDate~= nCurDay) then
		Xuanshang_Prize_Award_Info1:SetText("#{XFXS_201231_11}")
		Xuanshang_Prize_Award_Info2:SetText("#{XFXS_201231_13}")
	else
		Xuanshang_Prize_Award_Info1:SetText("#{XFXS_201231_12}")
		if(Get_XParam_STR(0) == "") then
			Xuanshang_Prize_Award_Info2:SetText("#{XFXS_201231_14}")
		else
			Xuanshang_Prize_Award_Info2:SetText(tostring(Get_XParam_STR(0)))
		end
	end
	local nCurMinute = DataPool:GetServerMinuteTime()
	local nData2 = DataPool:GetPlayerMission_DataRound(2233)
	local nData3 = DataPool:GetPlayerMission_DataRound(2234)
	if nCurMinute > 213000 then
		Xuanshang_Prize_Page_Info:SetText("#{XFXS_201231_18}")
	else
		if nData2 == nCurDay*10+2 and math.mod(nData3,10) ~= 2 then
			Xuanshang_Prize_Page_Info:SetText("#{XFXS_201231_17}")
		else
			Xuanshang_Prize_Page_Info:SetText("#{XFXS_201231_16}")
		end
	end
	
	if nData2 == nCurDay*10+2 and math.mod(nData3,10) ~= 2 then
		Xuanshang_Prize_Award_Info3:SetText("#{XFXS_201231_260}")
	else
		Xuanshang_Prize_Award_Info3:SetText("#{XFXS_201231_259}")
	end
		
	this:Show()
end

function Xuanshang_Prize_On_ResetPos()
	Xuanshang_Prize_Frame_BK : SetProperty("UnifiedXPosition", g_XSP_Frame_UnifiedXPosition)
	Xuanshang_Prize_Frame_BK : SetProperty("UnifiedYPosition", g_XSP_Frame_UnifiedYPosition)
end

function Xuanshang_Prize_Cancel_Clicked()
	Xuanshang_Prize_OnHidden()
end

function Xuanshang_Prize_JoinClicked()
	AutoRuntoTargetExWithName(277,159, 0, "常发")
	PushDebugMessage("#{XFXS_201231_19}")
	--AutoRunToTargetEx(277,159,0)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Participate" )
		Set_XSCRIPT_ScriptID(506100)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	Xuanshang_Prize_OnHidden()
end

function Xuanshang_Prize_OnHidden()
	this:Hide()
end

function Xuanshang_Prize_PreviewClicked()
	PushEvent( "OPEN_BOUNTY_PREVIEW" )
end

function Xuanshang_Prize_GetClicked()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGrandPrize" )
		Set_XSCRIPT_ScriptID(506100)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	--Xuanshang_Prize_OnHidden()
end

function Xuanshang_Prize_FlashUIRedPoint()
	if DataPool:Lua_IsRedPointInUIShow( 34 ) == 1 then
		Xuanshang_Prize_JoinButton_RedDot:Show()
	else
		Xuanshang_Prize_JoinButton_RedDot:Hide()
	end
	
	if DataPool:Lua_IsRedPointInUIShow( 35 ) == 1 then
		Xuanshang_Prize_GetButton_RedDot:Show()
	else
		Xuanshang_Prize_GetButton_RedDot:Hide()
	end
end

