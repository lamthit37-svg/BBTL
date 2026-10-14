local g_MonthPVP_Message_Frame_UnifiedPosition

local g_MonthPVP_Message_StrTeamName =
{
	[1] = {str = "#{LLKC_240517_50}"},
	[2] = {str = "#{LLKC_240517_51}"},
    [3] = {str = "#{LLKC_240517_274}"}, --高级采集物
    [4] = {str = "#{LLKC_240517_275}"}, --小怪
    [5] = {str = "#{LLKC_240517_313}"}, --至尊宝预告
}

local g_MonthPVP_Message_StrPos =
{
	[1] = {str = "#{LLKC_240517_321}"},
	[2] = {str = "#{LLKC_240517_322}"},
    [3] = {str = "#{LLKC_240517_323}"},
}

function MonthPVP_Message_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end


function MonthPVP_Message_OnLoad()
	g_MonthPVP_Message_Frame_UnifiedPosition = MonthPVP_Message:GetProperty("UnifiedPosition")
end


function MonthPVP_Message_OnEvent(event)

	--打开界面
	if ( event == "UI_COMMAND" and tonumber(arg0) == 82003006) then
		if(not this:IsVisible() ) then
            local opType = Get_XParam_INT(0)
            if opType >= 6 then
                local nParamSTR0 = Get_XParam_STR(0)
                MonthPVP_Message_Text:SetText(nParamSTR0)
            else
                MonthPVP_Message_Text:SetText(g_MonthPVP_Message_StrTeamName[opType].str)
            end
            --计时器
            SetTimer("MonthPVP_Message", "MonthPVP_Message_Flashdown()",10*1000)
            this:Show()
        end
	elseif event=="HIDE_ON_SCENE_TRANSED" or event=="SCENE_TRANSED" or event=="PLAYER_LEAVE_WORLD"  then
		MonthPVP_Message_CloseClicked()
    end
	
	if this:IsVisible() then
        if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
			MonthPVP_Message_ResetPos()
        end
	end
	
end

function MonthPVP_Message_CloseClicked()
	MonthPVP_Message_CleanUp()	
	this:Hide()
end

function MonthPVP_Message_ResetPos()
    MonthPVP_Message:SetProperty("UnifiedPosition", g_MonthPVP_Message_Frame_UnifiedPosition)
end

function MonthPVP_Message_CleanUp()	
	--计时器
    KillTimer("MonthPVP_Message_Flashdown()")
end

function MonthPVP_Message_Flashdown()
	--计时器
    KillTimer("MonthPVP_Message_Flashdown()")
    if( this:IsVisible() ) then
        MonthPVP_Message_CleanUp()	
        this:Hide()
    end
end