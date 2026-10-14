-- 排行榜界面
local ZM_Boss_MiNi_ServerScriptId = 999029


local ZM_Boss_MiNi_CampPlayerNum_Max = 50        -- 阵营最大人数


-- 保存UI默认位置
local ZM_Boss_MiNi_UnifiedPosition = nil

local g_Text = {
	[0] = "#{ZMB_230124_36}",
	[1] = "#{ZMB_230124_37}",
	[2] = "#{ZMB_230124_38}",
}

local g_FenShuCoe = {
	
	[0] = 1.49,
	[1] = 1.45,
	[2] = 1.98,
	[3] = 1.91,
	[4] = 1.48,
	[5] = 1.63,
	[6] = 1.49,
	[7] = 1.50,
	[8] = 1,
	[9] = 1,
	[10] = 1.64,
	[11] = 1.25,
	[12] = 1.63,
	[13] = 1.21,
	[14] = 1.48,
	[15] = 1.10,--menpai15 mptodo

}

local g_BossCoe = {
	
	[1] = 1.28,
	[2] = 1,
	[3] = 1.69,
	
}

local g_FenShuLevel = {
	
	[1] = {nmin = 0, nmax = 1499, level = 0},
	[2] = {nmin = 1500, nmax = 3499, level = 1},
	[3] = {nmin = 3500, nmax = 4999, level = 2},
	[4] = {nmin = 5000, nmax = 5499, level = 3},
	[5] = {nmin = 5500, nmax = 6499, level = 4},
	[6] = {nmin = 6500, nmax = 999999999, level = 5},
	
}

local g_BossId = 0

function ZM_Boss_MiNi_PreLoad()
	this:RegisterEvent("ZMBOSS_UPDATA_RANKLIST")
	this:RegisterEvent("ZMBOSS_SHOW_MINI")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
end -- end func ZM_Boss_MiNi_PreLoad()

function ZM_Boss_MiNi_OnLoad()
    ZM_Boss_MiNi_UnifiedPosition = ZM_Boss_MiNi_Frame:GetProperty("UnifiedPosition")	
	g_BossId = 0
end -- end func ZM_Boss_MiNi_OnLoad()

function ZM_Boss_MiNi_OnEvent(event)
    if (event == "HIDE_ON_SCENE_TRANSED") then
        ZM_Boss_MiNi_Hide()
		
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        ZM_Boss_MiNi_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        ZM_Boss_MiNi_UnifiedPos()
	elseif (event == "ZMBOSS_SHOW_MINI") then
        ZM_Boss_MiNi_Show()
	elseif (event == "ZMBOSS_UPDATA_RANKLIST") then
         ZM_Boss_MiNi_UpdateRankList()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 999029006) then	--服务端传数据
		local nProcess = Get_XParam_INT(0)	
		local nLeaveTime = Get_XParam_INT(1)
		if g_Text[nProcess] ~= nil then
			ZM_Boss_MiNi_CountdownInfo:SetText(g_Text[nProcess])
			ZM_Boss_MiNi_CountdownInfo_Time:SetProperty("Timer", nLeaveTime)
		end
		g_BossId = Get_XParam_INT(2)
    end
end -- end func ZM_Boss_MiNi_OnEvent()

-- 界面默认位置
function ZM_Boss_MiNi_UnifiedPos()
    if (this:IsVisible()) then
        if (ZM_Boss_MiNi_UnifiedPosition ~= nil) then
            ZM_Boss_MiNi_Frame:SetProperty("UnifiedPosition", ZM_Boss_MiNi_UnifiedPosition)
        end
    end
end -- end func ZM_Boss_MiNi_UnifiedPos()

function ZM_Boss_MiNi_Show()
    if (not this:IsVisible()) then
        this:Show()
    end
end -- end func ZM_Boss_MiNi_Show()

function ZM_Boss_MiNi_Hide()
	g_BossId = 0
    this:Hide()
end -- end func ZM_Boss_MiNi_Hide()

-- 关闭按钮点击事件
function ZM_Boss_MiNi_Small_Clicked()
    --ZM_Boss_MiNi_Hide()
	this:Hide()
	PushEvent("ZMBOSS_SHOW_BIG")
end  -- end func ZM_Boss_MiNi_Close_Clicked()




-- 刷新排行榜
function ZM_Boss_MiNi_UpdateRankList()
 
    local myGuid = Player:GetGUID()
    local myRank = -1
	local menpaiID = Player : GetData("MEMPAI");	
    -- 获取阵营排行榜
    local listCount = 0
    local rankList = {}
    for i=1, ZM_Boss_MiNi_CampPlayerNum_Max, 1 do
        local ret, guid, name, damage= ZMBossGetScoreData(i-1)
        if (ret > 0) then
            listCount = listCount + 1
            rankList[listCount] = {}
			rankList[listCount].guid = guid
            rankList[listCount].name = name
            rankList[listCount].damage = damage
			local nBaseScore = 0
			local svrType   = KaJi:LuaFnGetKaJiType(147)
			local nKsJiCoe = 1
			if svrType == 1 then
				nKsJiCoe = 2.5
			end
			if g_BossCoe[g_BossId+1] ~= nil and g_FenShuCoe[menpaiID] ~= nil then
				nBaseScore = math.floor(damage*g_BossCoe[g_BossId+1]*g_FenShuCoe[menpaiID])*nKsJiCoe
			end	
            rankList[listCount].score = math.floor(10000*((nBaseScore/10000)/(nBaseScore/10000+7500)))
			if 1 == Player:GetData("Is2606S") then
				rankList[listCount].score =  rankList[listCount].score*3
			end
        end
    end -- end for
	
	for i = 1, listCount do
		for j = 1, listCount-i do
			local bIsExChange = 0
			if (rankList[j].score < rankList[j+1].score) then
				bIsExChange = 1
			elseif (rankList[j].score == rankList[j+1].score and rankList[j].damage < rankList[j+1].damage) then
				bIsExChange = 1
			end
			if bIsExChange == 1 then
				local tempguid = rankList[j].guid
				local tempname = rankList[j].name
				local tempscore = rankList[j].score
				local tempdamage = rankList[j].damage
				
				
				rankList[j].guid = rankList[j+1].guid
				rankList[j].name = rankList[j+1].name
				rankList[j].score = rankList[j+1].score
				rankList[j].damage = rankList[j+1].damage
				
				
				rankList[j+1].guid = tempguid
				rankList[j+1].name = tempname
				rankList[j+1].score = tempscore
				rankList[j+1].damage = tempdamage
				
			end
		end	
	end
	
	
	local myname = ""
	local myscore = 0
	local mydamage = 0
	local myrank = 0
	-- if myCamp == campId then
	for i = 1, listCount do 
		if rankList[i].guid == myGuid then
			myname = rankList[i].name
			myscore = rankList[i].score
			mydamage = rankList[i].damage
			myrank = i
			break
		end
	end

    -- 自己的积分数据
 

	
	for i = 1 , table.getn(g_FenShuLevel) do
		if myscore >= g_FenShuLevel[i].nmin and myscore <= g_FenShuLevel[i].nmax and i ~= table.getn(g_FenShuLevel) then
			ZM_Boss_MiNi_Rank_Num:SetText(ScriptGlobal_Format("#{ZMB_230124_46}", myscore, g_FenShuLevel[i+1].nmin))
			if g_FenShuLevel[i].level == 0 then
				ZM_Boss_MiNi_Count_Num:SetText("#{ZMB_230124_240}")
			else
				ZM_Boss_MiNi_Count_Num:SetText(ScriptGlobal_Format("#{ZMB_230124_241}", g_FenShuLevel[i].level))
			end
			break
		elseif myscore >= g_FenShuLevel[i].nmin and i == table.getn(g_FenShuLevel) then
			ZM_Boss_MiNi_Rank_Num:SetText(ScriptGlobal_Format("#{ZMB_230124_46}", myscore, g_FenShuLevel[i].nmin))
			if g_FenShuLevel[i].level == 0 then
				ZM_Boss_MiNi_Count_Num:SetText("#{ZMB_230124_240}")
			else
				ZM_Boss_MiNi_Count_Num:SetText(ScriptGlobal_Format("#{ZMB_230124_241}", g_FenShuLevel[i].level))
			end
			break
		end
	end
	
    
end -- end func ZM_Boss_MiNi_UpdateRankList()

function ZM_Boss_MiNi_Help_Clicked()
    PushEvent("CCSHOP_HELP", 206)
end -- end func CampPVP2023_Progress_Help()