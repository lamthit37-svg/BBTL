-- T300 新天外 普通夺旗 排行榜详细信息

-- 帮会图标
-- 排行榜手动刷新还是自动刷新
local T3TopListDetailedDup_IsAutoFresh = 0
-- 手动刷新时上次刷新时间
local T3TopListDetailedDup_LastUpdateTime = 0
-- 手动刷新时间间隔
local T3TopListDetailedDup_UpdateInterval = 5
-- 排行榜人数最大值
local T3TopListDetailedDup_RankList_Num_Max = 150

-- 保存UI默认位置
local T3TopListDetailedDup_UnifiedPosition = nil

local g_Current_Type = 1;
local g_all_human_count = 260*3

-- 保存当前要显示的帮会索引
local T3TopListDetailedDup_RankListIndex = 0

function T3TopListDetailedDup_PreLoad()
    this:RegisterEvent("JLZD_UI_OPEN_RANKLISTDETAILED", true)
    this:RegisterEvent("JLZD_DATA_RANKLIST", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("T20DOMAINS_OPEN_TOPLIST")
	this:RegisterEvent("SCENE_TRANSED")
end -- end func T3TopListDetailedDup_PreLoad()

function T3TopListDetailedDup_OnLoad()

    T3TopListDetailedDup_UnifiedPosition = T3TopListDetailedDup_Frame:GetProperty("UnifiedPosition")
    g_Current_Type = 1

end -- end func T3TopListDetailedDup_OnLoad()

function T3TopListDetailedDup_OnEvent(event)

    if (event == "HIDE_ON_SCENE_TRANSED") then
        T3TopListDetailedDup_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        T3TopListDetailedDup_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        T3TopListDetailedDup_UnifiedPos()
    --比赛开始，如果小UI要显示了，你这个大的，就必须关了
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20200904 ) then
        T3TopListDetailedDup_OnHide()
	elseif (event == "T20DOMAINS_OPEN_TOPLIST" ) then
		local nType = tonumber(arg0)

		if nType == nil then
			nType = 0
		end

		if (this:IsVisible()) then
			T3TopListDetailedDup_RefreshData( nType )
		else
			if nType == 0 then
				T3TopListDetailedDup_ShowData( )

                if this:IsVisible() then
					T3TopListDetailedDup_RefreshData( nType )
				else
					local guildID, clanID = DataPool:GetGuildClanID()
					local selfZoneWorldID = DataPool:GetSelfZoneWorldID();
					local nIndex = T20DomainServerUI:GetGuildIndex(guildID,selfZoneWorldID)
					g_Current_Type = nIndex
					T3TopListDetailedDup_ShowData( )
					if (this:IsVisible()) then
					else
						T3TopListDetailedDup_TimerProc()
					end
					
					if (T3TopListDetailedDup_IsAutoFresh > 0) then
						SetTimer("T3TopListDetailedDup","T3TopListDetailedDup_TimerProc()", 5000)
					else
						T3TopListDetailedDup_LastUpdateTime =  DataPool:GetCurrentServerTime()
						T3TopListDetailedDup_TimerProc()
					end
			
					if g_Current_Type == 1 then
						T3TopListDetailedDup_Icon1:SetCheck(1)
						T3TopListDetailedDup_Icon2:SetCheck(0)
						T3TopListDetailedDup_Icon3:SetCheck(0)
					elseif g_Current_Type == 2 then
						T3TopListDetailedDup_Icon1:SetCheck(0)
						T3TopListDetailedDup_Icon2:SetCheck(1)
						T3TopListDetailedDup_Icon3:SetCheck(0)
					elseif g_Current_Type == 3 then
						T3TopListDetailedDup_Icon1:SetCheck(0)
						T3TopListDetailedDup_Icon2:SetCheck(0)
						T3TopListDetailedDup_Icon3:SetCheck(1)
					end

					

					this:Show()
                end
			end
		end
    elseif( event == "SCENE_TRANSED" ) then
        T3TopListDetailedDup_OnHide()
	end
end -- end func T3TopListDetailedDup_OnEvent()

-- 界面默认位置
function T3TopListDetailedDup_UnifiedPos()
    if (this:IsVisible()) then
        if (T3TopListDetailedDup_UnifiedPosition ~= nil) then
            T3TopListDetailedDup_Frame:SetProperty("UnifiedPosition", T3TopListDetailedDup_UnifiedPosition)
        end
    end
end -- end func T3TopListDetailedDup_UnifiedPos()


-- 关闭界面
function T3TopListDetailedDup_Hide()
    
    T3TopListDetailedDup_OnHide()
end -- end func T3TopListDetailedDup_Hide()

-- 关闭按钮事件
function T3TopListDetailedDup_Close_Clicked()
	T3TopListDetailedDup_Closed()
	T3TopListDetailedDup_Hide()
end -- end func T3TopListDetailedDup_Close_Clicked()


function T3TopListDetailedDup_AccuKillInfo()

	T3TopListDetailedDup_ListFrame:Clear()
	
	local count = 0;
	for nIdx=0, g_all_human_count do
		local playerName,
			ScoreCnt,
			ZhanTuanID,
			WorldID,
			AccKillnum,
			KillCombo,
			FlagNum,
            score = T20DomainServerUI:GetAttackInfoByIdx(nIdx)		--改成伤害排名
            
        local nIndex = T20DomainServerUI:GetGuildIndex(ZhanTuanID,WorldID)

		if playerName == nil or playerName == "" then
			break
		end

		local strScoreCnt = tostring(ScoreCnt)
		if ScoreCnt > 10000 then
			strScoreCnt = math.floor(ScoreCnt/10000).."万"
		end

        if  g_Current_Type == nIndex then
            count = count + 1
			local uiPrefab = T3TopListDetailedDup_ListFrame:AddChild("T3TopListDetailedDup_AItem")

			uiPrefab:GetSubItem("T3TopListDetailedDup_AItem_Rank"):SetText( count )

			uiPrefab:GetSubItem("T3TopListDetailedDup_AItem_Name"):SetText( playerName)
			uiPrefab:GetSubItem("T3TopListDetailedDup_AItem_Score"):SetText( score)
			uiPrefab:GetSubItem("T3TopListDetailedDup_AItem_Kill"):SetText( AccKillnum)
			uiPrefab:GetSubItem("T3TopListDetailedDup_AItem_Damage"):SetText( ScoreCnt)
			uiPrefab:GetSubItem("T3TopListDetailedDup_AItem_Capture"):SetText( FlagNum)
		end
	end

	
    local rank,score =  T20DomainServerUI:GetAttackInfoByMyself()

	if rank == nil then
		rank = 0
	end
	if score == nil then
		score = 0
	end

	local playerName,
	ScoreCnt,
	ZhanTuanID,
	WorldID,
	AccKillnum,
	KillCombo,
	FlagNum,
	score =T20DomainServerUI:GetMyInfo()
	local nIndex = T20DomainServerUI:GetGuildIndex(ZhanTuanID,WorldID)
	if  g_Current_Type == nIndex then

		T3TopListDetailedDup_AItem_MyClient:Show()

		T3TopListDetailedDup_AItem_MyRank:SetText(rank)

		T3TopListDetailedDup_AItem_MyName:SetText(playerName)
		T3TopListDetailedDup_AItem_MyScore:SetText(score)
		T3TopListDetailedDup_AItem_MyKill:SetText(AccKillnum)
		T3TopListDetailedDup_AItem_MyDamage:SetText(ScoreCnt)
		T3TopListDetailedDup_AItem_MyCapture:SetText(FlagNum)
	else
		T3TopListDetailedDup_AItem_MyClient:Hide()
	end
	
end

--================================================
-- 填充数据
--================================================
function T3TopListDetailedDup_RefreshData( nType )

	if nType == 0 then
		return
	elseif nType == 1 then --//基本数据：双方帮会的组号、帮会名字
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

		local nWorld_R, nWorld_B, nWorld_G  = T20DomainServerUI:GetMemRecord2WorldID()
		if nWorld_R ~= -1 then
            szName_R = szName_R .. "@" .. DataPool:GetServerName(nWorld_R)
        else
			szName_R = "#{BHZD_140124_36}"
		end

		if nWorld_B ~= -1 then
			szName_B = szName_B .. "@" .. DataPool:GetServerName(nWorld_B)
		else
			szName_B = "#{BHZD_140124_36}"
        end
        
        if szName_G ~= -1 then
			szName_G = szName_G .. "@" .. DataPool:GetServerName(nWorld_B)
		else
			szName_G = "#{BHZD_140124_36}"
		end

		T3TopListDetailedDup_Banghui_Name1:SetText(szName_R)
        T3TopListDetailedDup_Banghui_Name2:SetText(szName_B)
        T3TopListDetailedDup_Banghui_Name3:SetText(szName_G)

	elseif nType == 2 then 
		--同步狙杀

		T3TopListDetailedDup_AccuKillInfo()

	elseif nType == 3 then --//针对断线重连的玩家
		T3TopListDetailedDup_ShowData()

	elseif nType == 4 then --//比赛结果    
		local nResult, winGuildId, winGuildWorldId, winGuildIndex = T20DomainServerUI:GetMemRecordResult()
		T3TopListDetailedDup_AccuKillInfo()
		if nResult > 0 then

            if nResult == 1 then
                T3TopListDetailedDup_Win1:Show()
                T3TopListDetailedDup_Win2:Hide()
                T3TopListDetailedDup_Win3:Hide()
            elseif nResult == 2 then
                T3TopListDetailedDup_Win1:Hide()
                T3TopListDetailedDup_Win2:Show()
                T3TopListDetailedDup_Win3:Hide()
            elseif nResult == 3 then
                T3TopListDetailedDup_Win1:Hide()
                T3TopListDetailedDup_Win2:Hide()
                T3TopListDetailedDup_Win3:Show()
            elseif nResult == 4 then
                T3TopListDetailedDup_Win1:Hide()
                T3TopListDetailedDup_Win2:Hide()
                T3TopListDetailedDup_Win3:Hide()
            end
		else
            T3TopListDetailedDup_Win1:Hide()
            T3TopListDetailedDup_Win2:Hide()
            T3TopListDetailedDup_Win3:Hide()
		end
	end

end


--================================================
-- 填充数据
--================================================
function T3TopListDetailedDup_ShowData()
	
	local nResult 		= T20DomainServerUI:GetMemRecordResult()

	if nResult > 0 then

		if nResult == 1 then

			T3TopListDetailedDup_Win1:Show()
			T3TopListDetailedDup_Win2:Hide()
			T3TopListDetailedDup_Win3:Hide()
		elseif nResult == 2 then

			T3TopListDetailedDup_Win1:Hide()
			T3TopListDetailedDup_Win2:Show()
			T3TopListDetailedDup_Win3:Hide()
		elseif nResult == 3 then
			T3TopListDetailedDup_Win1:Hide()
			T3TopListDetailedDup_Win2:Hide()
			T3TopListDetailedDup_Win3:Show()
		elseif nResult == 4 then
			T3TopListDetailedDup_Win1:Hide()
			T3TopListDetailedDup_Win2:Hide()
			T3TopListDetailedDup_Win3:Hide()
		end
	else
        T3TopListDetailedDup_Win1:Hide()
        T3TopListDetailedDup_Win2:Hide()
        T3TopListDetailedDup_Win3:Hide()
	end
	

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
		szName_R = szName_R .. "@" .. DataPool:GetServerName(nWorld_R)
    else
		szName_R = "#{BHZD_140124_36}"
	end

	if nWorld_B ~= -1 then
		szName_B = szName_B .. "@" .. DataPool:GetServerName(nWorld_B)
	else
		szName_B = "#{BHZD_140124_36}"
    end
    
    if nWorld_G ~= -1 then
		szName_G = szName_G .. "@" .. DataPool:GetServerName(nWorld_B)
	else
		szName_G = "#{BHZD_140124_36}"
	end
		
    T3TopListDetailedDup_Banghui_Name1:SetText(szName_R)
    T3TopListDetailedDup_Banghui_Name2:SetText(szName_B)
    T3TopListDetailedDup_Banghui_Name3:SetText(szName_G)
	
	T3TopListDetailedDup_AccuKillInfo()
end

function T3TopListDetailedDup_FenYe_JishaPaiming_Click(nindex)
	g_Current_Type = nindex
	if nindex == 1 then
		T3TopListDetailedDup_Icon1:SetCheck(1)
		T3TopListDetailedDup_Icon2:SetCheck(0)
		T3TopListDetailedDup_Icon3:SetCheck(0)
	elseif nindex == 2 then
		T3TopListDetailedDup_Icon1:SetCheck(0)
		T3TopListDetailedDup_Icon2:SetCheck(1)
		T3TopListDetailedDup_Icon3:SetCheck(0)
	elseif nindex == 3 then
		T3TopListDetailedDup_Icon1:SetCheck(0)
		T3TopListDetailedDup_Icon2:SetCheck(0)
		T3TopListDetailedDup_Icon3:SetCheck(1)
	end
	T3TopListDetailedDup_AccuKillInfo()
	T20DomainServerUI:Lua_SendAskGuildInfo(3,g_Current_Type)
end

-- 奖励按钮事件
function T3TopListDetailedDup_Prize_Clicked()

	local nIndex = Lua_IsInTDomain20Server()
	PushEvent("JLZD_UI_OPEN_LISTPRIZE", nIndex)
end 


--计时
function T3TopListDetailedDup_TimerProc()
    T20DomainServerUI:Lua_SendAskGuildInfo(3,g_Current_Type)
end




function T3TopListDetailedDup_OnHide()
	if (T3TopListDetailedDup_IsAutoFresh > 0) then
		KillTimer("T3TopListDetailedDup_TimerProc()")
        end
	this:Hide()
end



function T3TopListDetailedDup_Closed()
	T3TopListDetailedDup_OnHide()
	PushEvent( "TDOMAIN20S_OPEN_MINI", 1 )
end



-- 手动刷新按钮事件
function T3TopListDetailedDup_FreshButtonClicked()
    local curTime =  DataPool:GetCurrentServerTime()
    if (curTime - T3TopListDetailedDup_LastUpdateTime >= T3TopListDetailedDup_UpdateInterval) then
	T3TopListDetailedDup_LastUpdateTime = curTime
        T3TopListDetailedDup_TimerProc()
    else
        -- 未到刷新间隔
        PushDebugMessage("#{JLDQZ_200814_183}")
    end
end -- end func T3TopListDetailedDup_FreshButtonClicked()