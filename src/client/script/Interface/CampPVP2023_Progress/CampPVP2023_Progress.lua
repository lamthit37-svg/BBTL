-- 排行榜界面
local CampPVP2023_Progress_ServerScriptId = 998429

local CampPVP2023_Progress_Camp_Red = 1               -- red 阵营ID
local CampPVP2023_Progress_Camp_Blue = 2               -- blue 阵营ID
local g_RankListCD = 3
local g_LastSyncRankListTime = 0
local g_PreTime = 30
local g_EndTime = 1830
local g_ScoreLimit = 30

-- 保存UI默认位置
local CampPVP2023_Progress_UnifiedPosition = nil

local g_FightAnimList = {}
local g_FightAList = {}
local g_FightBList = {}
local g_FightImage = {}

local g_FlagPos = {
	[1] = {x=255, z=93}, --中间
	[2] = {x=196, z=92}, --左1
	[3] = {x=140, z=92}, --左2
	[4] = {x=314, z=92}, --右1
	[5] = {x=362, z=92}, --右2
}

function CampPVP2023_Progress_PreLoad()
    this:RegisterEvent("ZYPVP_UPDATA_RANKLIST", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ZYPVP_SHOW_BIG")
end -- end func CampPVP2023_Progress_PreLoad()

function CampPVP2023_Progress_OnLoad()
    CampPVP2023_Progress_UnifiedPosition = CampPVP2023_Progress_Frame:GetProperty("UnifiedPosition")
	g_FightAnimList[1] = CampPVP2023_Progress_Page_Lace1_Text
	g_FightAnimList[2] = CampPVP2023_Progress_Page_Lace2_Text
	g_FightAnimList[3] = CampPVP2023_Progress_Page_Lace3_Text
	g_FightAnimList[4] = CampPVP2023_Progress_Page_Lace4_Text
	g_FightAnimList[5] = CampPVP2023_Progress_Page_Lace5_Text
	
	-- g_FightAList[1] = CampPVP2023_Progress_Page_Lace1PlayerA
	-- g_FightAList[2] = CampPVP2023_Progress_Page_Lace2PlayerA
	-- g_FightAList[3] = CampPVP2023_Progress_Page_Lace3PlayerA
	-- g_FightAList[4] = CampPVP2023_Progress_Page_Lace4PlayerA
	-- g_FightAList[5] = CampPVP2023_Progress_Page_Lace5PlayerA
	
	-- g_FightBList[1] = CampPVP2023_Progress_Page_Lace1PlayerB
	-- g_FightBList[2] = CampPVP2023_Progress_Page_Lace2PlayerB
	-- g_FightBList[3] = CampPVP2023_Progress_Page_Lace3PlayerB
	-- g_FightBList[4] = CampPVP2023_Progress_Page_Lace4PlayerB
	-- g_FightBList[5] = CampPVP2023_Progress_Page_Lace5PlayerB
	
	g_FightImage[1] = CampPVP2023_Progress_Page_Lace1Item
	g_FightImage[2] = CampPVP2023_Progress_Page_Lace2Item
	g_FightImage[3] = CampPVP2023_Progress_Page_Lace3Item
	g_FightImage[4] = CampPVP2023_Progress_Page_Lace4Item
	g_FightImage[5] = CampPVP2023_Progress_Page_Lace5Item
	
end -- end func CampPVP2023_Progress_OnLoad()

function CampPVP2023_Progress_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        CampPVP2023_Progress_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        CampPVP2023_Progress_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        CampPVP2023_Progress_UnifiedPos()
	 elseif (event == "ZYPVP_SHOW_BIG") then
        this:Show()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998429004) then	--服务端传数据
		local nLeaveTime = Get_XParam_INT(0)	
		local nCurRand  = Get_XParam_INT(1) 
		local nRound1WinerCamp  = Get_XParam_INT(2) 
		local nRound2WinerCamp  = Get_XParam_INT(3) 
		local nRound3WinerCamp  = Get_XParam_INT(4) 
		local nRound4WinerCamp  = Get_XParam_INT(5) 
		local nRound5WinerCamp  = Get_XParam_INT(6) 
		local nRank  = Get_XParam_INT(7) 
		local nMySocre  = Get_XParam_INT(8) 
		local nTickTime = Get_XParam_INT(11) 
		local nNowGameState = math.mod(Get_XParam_INT(12),10) 
		local nCoolDownTime = math.floor(Get_XParam_INT(12)/10) 
		local nFlagCreatePosIndex =  Get_XParam_INT(13) 
		if nNowGameState == 1 then
			CampPVP2023_Progress_NowTimeText:Show()
			CampPVP2023_Progress_NowTime:Show()
			CampPVP2023_Progress_NowTimeText:SetText(ScriptGlobal_Format("#{ZYZC_220213_287}",g_FlagPos[nFlagCreatePosIndex].x, g_FlagPos[nFlagCreatePosIndex].z))
			CampPVP2023_Progress_NowTime:SetProperty("Timer", tostring(nCoolDownTime))
			CampPVP2023_Progress_TimeText3:Hide()
		elseif nNowGameState == 2 then
			CampPVP2023_Progress_TimeText3:Show()
			CampPVP2023_Progress_TimeText3:SetText(ScriptGlobal_Format("#{ZYZC_220213_288}",nCurRand))
			CampPVP2023_Progress_NowTimeText:Hide()
			CampPVP2023_Progress_NowTime:Hide()
		else
			CampPVP2023_Progress_NowTimeText:Hide()
			CampPVP2023_Progress_NowTime:Hide()
			CampPVP2023_Progress_TimeText3:Hide()
		end
		CampPVP2023_Progress_Show()
		CampPVP2023_Progress_Updata(nLeaveTime, nCurRand, nRound1WinerCamp, nRound2WinerCamp, nRound3WinerCamp, nRound4WinerCamp, nRound5WinerCamp, nRank, nMySocre, nTickTime)
    elseif event == "UI_COMMAND" and (tonumber(arg0) == 998429006) then	--比赛结束
		this:Hide()
	end
end -- end func CampPVP2023_Progress_OnEvent()

function CampPVP2023_Progress_Updata(nLeaveTime, nCurRand, nRound1WinerCamp, nRound2WinerCamp, nRound3WinerCamp, nRound4WinerCamp, nRound5WinerCamp, nRank, nMySocre, nTickTime)
    
	if nTickTime >= g_EndTime then
		CampPVP2023_Progress_TimeText:Hide()
		CampPVP2023_Progress_Time:Hide()
		--CampPVP2023_Progress_Time:SetProperty("Timer", tostring(0))
		CampPVP2023_Progress_TimeText2:SetText("#{ZYZC_220213_274}")
		CampPVP2023_Progress_TimeText2:Show()
	elseif nTickTime >= g_PreTime then
		CampPVP2023_Progress_TimeText:SetText("#{ZYZC_220213_50}")
		CampPVP2023_Progress_Time:SetProperty("Timer", tostring(nLeaveTime))
		CampPVP2023_Progress_TimeText:Show()
		CampPVP2023_Progress_Time:Show()
		CampPVP2023_Progress_TimeText2:Hide()
	else
		CampPVP2023_Progress_TimeText:SetText("#{ZYZC_220213_170}")
		CampPVP2023_Progress_Time:SetProperty("Timer", tostring(g_PreTime-nTickTime))
		CampPVP2023_Progress_TimeText:Show()
		CampPVP2023_Progress_Time:Show()
		CampPVP2023_Progress_TimeText2:Hide()
	end
	local nRondWiner = {}
	nRondWiner[1] = nRound1WinerCamp
	nRondWiner[2] = nRound2WinerCamp
	nRondWiner[3] = nRound3WinerCamp
	nRondWiner[4] = nRound4WinerCamp
	nRondWiner[5] = nRound5WinerCamp
	for i = 1, table.getn(nRondWiner) do
		if i < nCurRand then
			if nRondWiner[i] == 1 then
				g_FightImage[i]:SetProperty("Image", "set:CampPVP2023_2 image:CampPVP2023_Progress_White")
			elseif nRondWiner[i] == 2 then
				g_FightImage[i]:SetProperty("Image", "set:CampPVP2023_2 image:CampPVP2023_Progress_Black")
			end
			g_FightAnimList[i]:SetText("#{ZYZC_220213_280}")
			--g_FightImage[i]:SetProperty("Image", "set:KVKLeague_UI19 image:MengYinSmash_Gray_Normal")
		elseif i == nCurRand then
			g_FightAnimList[i]:SetText("#{ZYZC_220213_51}")
			g_FightImage[i]:SetProperty("Image", "set:CampPVP2023_2 image:CampPVP2023_Progress_Fighting")
		else
			g_FightAnimList[i]:SetText("#{ZYZC_220213_52}")
			g_FightImage[i]:SetProperty("Image", "set:CampPVP2023_2 image:CampPVP2023_Progress_Normal")
		end
	end
	
	if nMySocre < g_ScoreLimit then
		CampPVP2023_Progress_InfoText2:SetText("#{ZYZC_220213_275}")
	else
		CampPVP2023_Progress_InfoText2:SetText(ScriptGlobal_Format("#{ZYZC_220213_54}",nRank))
	end
	CampPVP2023_Progress_InfoText3:Hide()
	CampPVP2023_Progress_InfoText4:SetText(ScriptGlobal_Format("#{ZYZC_220213_56}",nMySocre))
	
end -- end func CampPVP2023_Progress_Updata()


-- 界面默认位置
function CampPVP2023_Progress_UnifiedPos()
    if (this:IsVisible()) then
        if (CampPVP2023_Progress_UnifiedPosition ~= nil) then
            CampPVP2023_Progress_Frame:SetProperty("UnifiedPosition", CampPVP2023_Progress_UnifiedPosition)
        end
    end
end -- end func CampPVP2023_Progress_UnifiedPos()

function CampPVP2023_Progress_Show()
	if IsWindowShow("CampPVP2023_Progress_Mini") then
	
	else
		this:Show()
	end
    
end -- end func CampPVP2023_Progress_Show()

function CampPVP2023_Progress_Hide()
    this:Hide()
end -- end func CampPVP2023_Progress_Hide()

-- 关闭按钮点击事件
function CampPVP2023_Progress_Close_Clicked()
    PushEvent("ZYPVP_SHOW_MINI")
	CampPVP2023_Progress_Hide()
end  -- end func CampPVP2023_Progress_Close_Clicked()

function CampPVP2023_Progress_Help()
    PushEvent("CCSHOP_HELP", 181)
end -- end func CampPVP2023_Progress_Help()

-- 关闭按钮点击事件
function CampPVP2023_Progress_RankList_Clicked()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SyncRankList")
		Set_XSCRIPT_ScriptID(998429)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end  -- end func CampPVP2023_Progress_RankList_Clicked()
