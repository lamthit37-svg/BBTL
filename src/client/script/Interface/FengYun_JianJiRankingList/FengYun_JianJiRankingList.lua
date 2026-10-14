local g_FengYun_JianJiRankingList_Frame_UnifiedPosition = nil
local g_NpcId = -1

local g_MyRank = -1
local g_objCared = -1
local g_OBJ_DISTANCE = 5.0

local g_MenPaiName = {
    [0] = "#{FYPVP_260106_192}",    --少林
    [1] = "#{FYPVP_260106_193}",    --明教
    [2] = "#{FYPVP_260106_194}",    --丐帮
    [3] = "#{FYPVP_260106_195}",    --武当
    [4] = "#{FYPVP_260106_196}",    --峨眉
    [5] = "#{FYPVP_260106_197}",    --星宿
    [6] = "#{FYPVP_260106_198}",    --天龙
    [7] = "#{FYPVP_260106_199}",    --天山
    [8] = "#{FYPVP_260106_200}",    --逍遥
	[9] = "无门派",	--无门派
	[10] = "#{FYPVP_260106_201}",	--慕容	
	[11] = "#{FYPVP_260106_202}",	--唐门
	[12] = "#{FYPVP_260106_203}",	--鬼谷
	[13] = "#{FYPVP_260106_206}",	    --桃花岛
	[14] = "#{FYPVP_260106_204}",	    --绝情谷
	[15] = "#{FYPVP_260106_205}",		--恶人谷
}


function FengYun_JianJiRankingList_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("OPEN_FYJCPVP_TD_RANK", true)
    this:RegisterEvent("OBJECT_CARED_EVENT", true)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
end

function FengYun_JianJiRankingList_OnLoad()
    g_FengYun_JianJiRankingList_Frame_UnifiedPosition = FengYun_JianJiRankingList_Frame:GetProperty("UnifiedPosition")
end

function FengYun_JianJiRankingList_OnEvent(event)
    if event == "OPEN_FYJCPVP_TD_RANK" then
        g_NpcId = tonumber(arg0)
        g_objCared = DataPool:GetNPCIDByServerID(g_NpcId) 
        FengYun_JianJiRankingList_BeginCareObject(g_objCared)
        FengYun_JianJiRankingList_OnShow()
    elseif (event == "ADJEST_UI_POS") then
        FengYun_JianJiRankingList_On_ResetPos()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        FengYun_JianJiRankingList_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        FengYun_JianJiRankingList_CloseClicked()
    elseif ( event == "OBJECT_CARED_EVENT" and this : IsVisible() ) then
        if( tonumber(arg0) ~= g_NpcId ) then
			return
		end
       	--- 如果和NPC的距离大于一定的距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > g_OBJ_DISTANCE or arg1=="destroy") then
			FengYun_JianJiRankingList_CloseClicked()
		end 
    end
end

function FengYun_JianJiRankingList_On_ResetPos()
    FengYun_JianJiRankingList_Frame:SetProperty("UnifiedPosition", g_FengYun_JianJiRankingList_Frame_UnifiedPosition)
end

function FengYun_JianJiRankingList_OnShow()
    FengYun_JianJiRankingList_ListInfo:Clear()

    -- 显示排行
    local nDataCount = DataPool:lua_GetFYJCTDTeamCount()
    local szSelfGuid = GetSelfGUID()
    if nDataCount < 1 then
        local ItemBar = FengYun_JianJiRankingList_ListInfo:AddChild("FengYun_JianJiRankingList_AItem")
        ItemBar:GetSubItem("FengYun_JianJiRankingList_AItem_Rank"):Hide()
        ItemBar:GetSubItem("FengYun_JianJiRankingList_AItem_Sever"):Hide()
        ItemBar:GetSubItem("FengYun_JianJiRankingList_AItem_Name"):Hide()
        ItemBar:GetSubItem("FengYun_JianJiRankingList_AItem_RankNum"):Hide()
    end

    for i = 0, nDataCount - 1 do
        local nRank, worldname, pointCount, charName,nmenpai,nelvel,nequip = DataPool:lua_GetFYJCTDTeamInfo(i,0)
        if nRank >= 0 then
    
            local ItemBar = FengYun_JianJiRankingList_ListInfo:AddChild("FengYun_JianJiRankingList_AItem")

            local rankstr = ScriptGlobal_Format("#{FYBM_260108_56}",i+1)
            ItemBar:GetSubItem("FengYun_JianJiRankingList_AItem_Rank"):SetText(rankstr)
    
            local namestr = ScriptGlobal_Format("#{FYBM_260108_56}", charName)
            ItemBar:GetSubItem("FengYun_JianJiRankingList_AItem_Name"):SetText(namestr)
    
            local worldnamestr = ScriptGlobal_Format("#{FYBM_260108_56}", worldname)
            ItemBar:GetSubItem("FengYun_JianJiRankingList_AItem_Sever"):SetText(worldnamestr)
    
            local pointstr = ScriptGlobal_Format("#{FYBM_260108_56}", pointCount)
            ItemBar:GetSubItem("FengYun_JianJiRankingList_AItem_RankNum"):SetText(pointstr)

            ItemBar:GetSubItem("FengYun_JianJiRankingList_AItem"):SetEvent("MouseLClick", string.format("FengYun_JianJiRankingList_ShowTeamInfo(%d)", i)) 
            ItemBar:GetSubItem("FengYun_JianJiRankingList_AItem"):SetEvent("MouseRClick", string.format("FengYun_JianJiRankingList_ShowTeamInfo(%d)", i)) 
        end
    end

    local mystate,myrank,zonename,mypoint,charName = DataPool:lua_GetFYJCTDMyRankInfo()
    if mystate == 0 then -- 未报名
        FengYun_JianJiRankingList_AItem_MyRank:SetText("#{FYBM_260108_57}")
        FengYun_JianJiRankingList_AItem_MyRank:Show()
        FengYun_JianJiRankingList_AItem_MySever:Hide()
        FengYun_JianJiRankingList_AItem_MyName:Hide()
        FengYun_JianJiRankingList_AItem_MyRankNum:Hide()
    elseif mystate == 1 then -- 未锁定
        FengYun_JianJiRankingList_AItem_MyRank:SetText("#{FYBM_260108_58}")
        FengYun_JianJiRankingList_AItem_MyRank:Show()
        FengYun_JianJiRankingList_AItem_MySever:Hide()
        FengYun_JianJiRankingList_AItem_MyName:Hide()
        FengYun_JianJiRankingList_AItem_MyRankNum:Hide()

    elseif mystate == 2 then -- 锁定
        FengYun_JianJiRankingList_AItem_MyRank:SetText(myrank)
        FengYun_JianJiRankingList_AItem_MyRank:Show()
        FengYun_JianJiRankingList_AItem_MySever:SetText(zonename)
        FengYun_JianJiRankingList_AItem_MySever:Show()
        FengYun_JianJiRankingList_AItem_MyName:SetText(charName)
        FengYun_JianJiRankingList_AItem_MyName:Show()
        FengYun_JianJiRankingList_AItem_MyRankNum:SetText(mypoint)
        FengYun_JianJiRankingList_AItem_MyRankNum:Show()
    end
   
    this:Show()
end


function FengYun_JianJiRankingList_CloseClicked()
    FengYun_JianJiRankingList_StopCareObject()
    this:Hide()
end


-- 点击事件
function FengYun_JianJiRankingList_ShowTeamInfo(nIndex)
    PushEvent("OPEN_FYJCPVP_TD_TEAM_INFO", g_objCared,nIndex)
end

--=========================================================
--开始关心NPC
--=========================================================
function FengYun_JianJiRankingList_BeginCareObject(objCaredId)
    if g_objCared ~= -1 then
        this:CareObject(objCaredId, 0, "FengYun_JianJiRankingList");
    end
    g_objCared = objCaredId
    this:CareObject(g_objCared, 1, "FengYun_JianJiRankingList")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function FengYun_JianJiRankingList_StopCareObject()
    if g_objCared ~= -1 then
        this:CareObject(g_objCared, 0, "FengYun_JianJiRankingList");
        g_objCared = -1
    end
end
