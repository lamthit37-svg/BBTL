local g_NewBangHui_PersonalRaceActivition_Frame_UnifiedPosition
local g_nObjCaredIDClient
local MAX_OBJ_DISTANCE = 5
local g_nServerObjID = -1

function NewBangHui_PersonalRaceActivition_PreLoad()
    this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OBJECT_CARED_EVENT", false)

	this:RegisterEvent("ON_SCENE_TRANS")
	this:RegisterEvent("PLAYER_LEAVE_WORLD")
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")

end

--注册onLoad事件
function NewBangHui_PersonalRaceActivition_OnLoad()
    g_NewBangHui_PersonalRaceActivition_Frame_UnifiedPosition = NewBangHui_PersonalRaceActivition_Frame:GetProperty("UnifiedPosition")
	NewBangHui_PersonalRaceActivition_Frame:SetEvent("Hidden", "NewBangHui_PersonalRaceActivition_Frame_Close()")
end

--OnEvent
function NewBangHui_PersonalRaceActivition_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0)==99887601) then
		if( this:IsVisible() ) then
			return 0
		else
			local nServerObjID 	= Get_XParam_INT(0)
			if nServerObjID ~= nil or nServerObjID > 0 then
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				NewBangHui_PersonalRaceActivition_beginCare()
				this:Show()
			end
		end
	elseif(event == "UI_COMMAND" and tonumber(arg0)==99887602) then
		if( this:IsVisible() ) then
			NewBangHui_PersonalRaceActivition_Frame_Close()
		end
	elseif ( event == "OBJECT_CARED_EVENT" )  then
		if(tonumber(arg0) ~= g_nObjCaredIDClient) then
			return 0
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			StopCareObject_Anniversary_ExMarket_stopCare()
			NewBangHui_PersonalRaceActivition_Frame_Close()
		end

	--游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		NewBangHui_PersonalRaceActivition_Frame_On_ResetPos()
	--游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewBangHui_PersonalRaceActivition_Frame_On_ResetPos()
    elseif (event == "ON_SCENE_TRANS") or (event == "PLAYER_LEAVE_WORLD") then
        NewBangHui_PersonalRaceActivition_Frame_Close()
	end
end


--点击确认
function NewBangHui_PersonalRaceActivition_Yes_Clicked()
    local szContent = NewBangHui_PersonalRaceActivition_Input:GetText()

	if( string.len(szContent) < 12 ) then
		PushDebugMessage("#{BHZH_230912_12}")
		return 0
	end


	for i=1, 12 do
		if string.byte(szContent,i) >= 97 and string.byte(szContent,i)  <= 122 then
			PushDebugMessage("#{BHZH_230912_10}")
			return 0
		end
	end

	Lua_Sende2023ActivationCDK(g_nServerObjID,szContent)
end


function NewBangHui_PersonalRaceActivition_beginCare()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "NewBangHui_PersonalRaceActivition")
end

function StopCareObject_Anniversary_ExMarket_stopCare()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "NewBangHui_PersonalRaceActivition")
	end
end


--恢复界面的默认相对位置
function NewBangHui_PersonalRaceActivition_Frame_On_ResetPos()
    NewBangHui_PersonalRaceActivition_Frame:SetProperty("UnifiedPosition", g_NewBangHui_PersonalRaceActivition_Frame_UnifiedPosition)
end

--关闭
function NewBangHui_PersonalRaceActivition_Frame_Close()
	NewBangHui_PersonalRaceActivition_Input:SetText("")
	g_nObjCaredIDClient = -1
	g_nServerObjID = -1
    this:Hide()
end