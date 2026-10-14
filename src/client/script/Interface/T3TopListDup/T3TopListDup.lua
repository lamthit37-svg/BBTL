
local g_Is_In_PKTIME = 0

-- 保存UI默认位置
local T3TopListDup_UnifiedPosition = nil

-- 倒计时类型
local T3TopListDup_CountdownType =
{
    begin = 1,      -- 比赛开始倒计时
    match = 2,      -- 比赛倒计时
} -- end T3TopListDup_CountdownType
function T3TopListDup_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
    this:RegisterEvent("RESET_ALLUI")
    this:RegisterEvent("TDOMAIN20S_DATA_FINISH", true)
    this:RegisterEvent("T20DOMAINS_OPEN_TOPLIST")
    this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("TDOMAIN20S_OPEN_MINI")
	this:RegisterEvent("TDOMAIN20S_FRESH_MAP_SCORE")	
	this:RegisterEvent("NORMAL_DATA_MATCHCOUNTDOWN", false)

end -- end func T3TopListDup_PreLoad()

function T3TopListDup_OnLoad()
	T3TopListDup_UnifiedPosition = T3TopListDup_Frame:GetProperty("UnifiedPosition")
	
end 
-- 界面默认值
function T3TopListDup_Default()
    T3TopListDup_Info2_Text:SetText("00:00")
    T3TopListDup_Info4_Text:SetText("0")
    T3TopListDup_Info6_Text:SetText("0")

    T3TopListDup_Name1_Text:SetText(" ")
    T3TopListDup_Name2_Text:SetText(" ")
    T3TopListDup_Name3_Text:SetText(" ")

    T3TopListDup_Kill1_Text:SetText(" ")
    T3TopListDup_Kill2_Text:SetText(" ")
    T3TopListDup_Kill3_Text:SetText(" ")
end -- end func T3TopListDup_Default()
-- 更新比赛倒计时
function T3TopListDup_UpdateMatchCountdown(countdown,countdownType)
    if (not this:IsVisible()) then
        T3MatchTime_Show()
    end
    
    local matchCountdown = tonumber(countdown)
    local matchCountdownType = tonumber(countdownType)
    -- 计算比赛倒计时时间（服务器传过来的是秒 解析成分：秒形式）
    local matchCountdownMin = math.floor(matchCountdown / 60)
    local strMatchCountdownMin = ""
    if (matchCountdownMin < 0) then
        strMatchCountdownMin = "00"
    elseif (matchCountdownMin >= 0 and matchCountdownMin < 10) then
        strMatchCountdownMin = string.format("0%d", matchCountdownMin)
    elseif (matchCountdownMin >= 10 and matchCountdownMin < 60) then
        strMatchCountdownMin = string.format("%d", matchCountdownMin)
    else
        strMatchCountdownMin = "59"
    end

    local matchCountdownSec = math.mod(matchCountdown, 60)
    local strMatchCountdownSec = ""
    if (matchCountdownSec < 0) then
        strMatchCountdownSec = "00"
    elseif (matchCountdownSec >= 0 and matchCountdownSec < 10) then
        strMatchCountdownSec = string.format("0%d", matchCountdownSec)
    elseif (matchCountdownSec >= 10 and matchCountdownSec < 60) then
        strMatchCountdownSec = string.format("%d", matchCountdownSec)
    else
        strMatchCountdownSec = "59"
    end

    local strMatchCountdown = strMatchCountdownMin .. ":" .. strMatchCountdownSec
    -- 设置比赛倒计时时间
    T3TopListDup_Info2_Text:SetText(strMatchCountdown)
    T3TopListDup_Info2_Text:Show()
    
    if (matchCountdownType == T3TopListDup_CountdownType.begin) then
        -- 比赛开始倒计时
        T3TopListDup_Info1_Text:SetText("#{JLDQZ_200814_163}")
    elseif (matchCountdownType == T3TopListDup_CountdownType.match) then
        -- 比赛倒计时
        T3TopListDup_Info1_Text:SetText("#{JLDQZ_200814_95}")
    end

end -- end func T3TopListDup_UpdateMatchCountdown()

function T3TopListDup_OnEvent(event)
	if (event == "VIEW_RESOLUTION_CHANGED") then
        T3TopListDup_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        T3TopListDup_UnifiedPos()
	elseif(event == "RESET_ALLUI") then
		g_Is_In_PKTIME = 0		
	elseif( event == "T20DOMAINS_OPEN_TOPLIST" ) then

		if  tonumber(arg0) == 4  then
			g_Is_In_PKTIME = 0
		end
		--只要有该时间，就刷积分
		T3TopListDup_ShowScore()
    elseif( event == "SCENE_TRANSED" ) then
        if (Lua_IsInTDomain20Server()  >= 1) then
			if g_Is_In_PKTIME > 0 then
				T3TopListDup_Show()
			end
		else
			T20DomainServerUI:ClearDomainServerUI()
			g_Is_In_PKTIME = 0
			
			KillTimer("T3TopListDup_TimerProc()")
			this:Hide()
        end
    elseif (event == "UI_COMMAND" and tonumber(arg0) == 20200904 ) then
		T3TopListDup_ShowScore()
		T3TopListDup_Show()
        g_Is_In_PKTIME = 1
    elseif (event == "TDOMAIN20S_OPEN_MINI" ) then
		T3TopListDup_ShowScore()
		T3TopListDup_Show()
    elseif (event == "TDOMAIN20S_FRESH_MAP_SCORE" ) then
		T3TopListDup_ShowScore()
	elseif (event == "NORMAL_DATA_MATCHCOUNTDOWN") then
        T3TopListDup_UpdateMatchCountdown(arg0, arg1)
    elseif (event == "TDOMAIN20S_DATA_FINISH") then
        T3TopListDup_MatchFinish()
    end
end 

-- 界面默认位置
function T3TopListDup_UnifiedPos()
    if (this:IsVisible()) then
        if (T3TopListDup_UnifiedPosition ~= nil) then
            T3TopListDup_Frame:SetProperty("UnifiedPosition", T3TopListDup_UnifiedPosition)
        end
    end
end 
-- 打开界面
function T3TopListDup_Show()
	if (this:IsVisible()) then
	else
		T3TopListDup_Default()
		T3TopListDup_TimerProc()
		SetTimer("T3TopListDup","T3TopListDup_TimerProc()", 5000)
	end
    this:Show()
end 
-- 关闭界面
function T3TopListDup_Hide()
	KillTimer("T3TopListDup_TimerProc()")
	this:Hide()
end
--================================================
-- 显示不断变化的积分
--================================================
function T3TopListDup_ShowScore()

    local rank,score,TotleAccRed,TotleAccBlue,TotleAccGreen =  T20DomainServerUI:GetAttackInfoByMyself()
	if rank == nil then
		rank = 0
	end
	if score == nil then
		score = 0
	end

    T3TopListDup_Info4_Text:SetText(score)

    T3TopListDup_Info6_Text:SetText(rank)
	
	T3TopListDup_Kill1_Text:SetText(TotleAccRed)
	T3TopListDup_Kill2_Text:SetText(TotleAccBlue)
    T3TopListDup_Kill3_Text:SetText(TotleAccGreen)
    

	local szName_R,szName_B,szName_G = T20DomainServerUI:GetMemRecordZhanTuanName()
	if szName_R == nil then
		szName_R = ""
	end

	if szName_B == nil then
		szName_B = ""
    end
    
    if szName_G == nil then
		szName_G = ""
    end
    


    local nWorld_R, nWorld_B, nWorld_G = T20DomainServerUI:GetMemRecord2WorldID()
    
    if nWorld_R ~= -1 then
        nWorld_R = DataPool:GetServerName(nWorld_R)
    else
        szName_R = "#{BHZD_140124_36}"
        nWorld_R = ""
    end

    if nWorld_B ~= -1 then
        nWorld_B = DataPool:GetServerName(nWorld_B)
    else
        szName_B = "#{BHZD_140124_36}"
        nWorld_B = ""
    end
    
    if nWorld_G ~= -1 then
	    nWorld_G = DataPool:GetServerName(nWorld_G)
    else
        szName_G = "#{BHZD_140124_36}"
        nWorld_G = ""
    end

    T3TopListDup_Name1_Text:SetText(szName_R)
    T3TopListDup_Name1_Text2:SetText(nWorld_R)

    T3TopListDup_Name2_Text:SetText(szName_B)
    T3TopListDup_Name2_Text2:SetText(nWorld_B)

    T3TopListDup_Name3_Text:SetText(szName_G)
    T3TopListDup_Name3_Text2:SetText(nWorld_G)

    local nGuild_R, nGuild_B, nGuild_G = T20DomainServerUI:GetMemRecord2ZhantuanID()

    local nResult, winGuildId, winGuildWorldId, winGuildIndex = T20DomainServerUI:GetMemRecordResult()
    if (nResult > 0 and winGuildId >= 0 and winGuildId == nGuild_R and winGuildWorldId == nWorld_R) then
        T3TopListDup_Name1_WinPic:Show()
    else
        T3TopListDup_Name1_WinPic:Hide()
    end
    if (nResult > 0 and winGuildId >= 0 and winGuildId == nGuild_B and winGuildWorldId == nWorld_B) then
        T3TopListDup_Name2_WinPic:Show()
    else
        T3TopListDup_Name2_WinPic:Hide()
    end
    if (nResult > 0 and winGuildId >= 0 and winGuildId == nGuild_G and winGuildWorldId == nWorld_G) then
        T3TopListDup_Name3_WinPic:Show()
    else
        T3TopListDup_Name3_WinPic:Hide()
    end

end

function T3TopListDup_OpenFame()
	T3TopListDup_ClearScore()
	--打开大的UI
	PushEvent("T20DOMAINS_OPEN_TOPLIST",  0 )
	KillTimer("T3TopListDup_TimerProc()")
	this:Hide()
end

function T3TopListDup_ClearScore()
	T3TopListDup_Default()
end

--计时
function T3TopListDup_TimerProc()
    T20DomainServerUI:Lua_SendAskGuildInfo(4,100)
end


-- 比赛结束
function T3TopListDup_MatchFinish()
    T3TopListDup_Info1_Text:SetText("#{JLDQZ_200814_176}")
    T3TopListDup_Info2_Text:Hide()
end -- end func T3TopListDup_MatchFinish()
