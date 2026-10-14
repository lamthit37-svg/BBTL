local g_FengYun_JianJiTopList_Frame_UnifiedPosition = nil
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


function FengYun_JianJiTopList_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("OPEN_FYJCPVP_GR_RANK", true)
    this:RegisterEvent("OBJECT_CARED_EVENT", true)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
end

function FengYun_JianJiTopList_OnLoad()
    g_FengYun_JianJiTopList_Frame_UnifiedPosition = FengYun_JianJiTopList_Frame:GetProperty("UnifiedPosition")
end

function FengYun_JianJiTopList_OnEvent(event)
    if event == "OPEN_FYJCPVP_GR_RANK" then
        g_NpcId = tonumber(arg0)
        g_objCared = DataPool:GetNPCIDByServerID(g_NpcId) 
        FengYun_JianJiTopList_BeginCareObject(g_objCared)
        FengYun_JianJiTopList_OnShow()
    elseif (event == "ADJEST_UI_POS") then
        FengYun_JianJiTopList_On_ResetPos()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        FengYun_JianJiTopList_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        FengYun_JianJiTopList_Close_Clicked()
    elseif ( event == "OBJECT_CARED_EVENT" and this : IsVisible() ) then
        if( tonumber(arg0) ~= g_NpcId ) then
			return
		end
       	--- 如果和NPC的距离大于一定的距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > g_OBJ_DISTANCE or arg1=="destroy") then
			FengYun_JianJiTopList_Close_Clicked()
		end 
    end
end

function FengYun_JianJiTopList_On_ResetPos()
    FengYun_JianJiTopList_Frame:SetProperty("UnifiedPosition", g_FengYun_JianJiTopList_Frame_UnifiedPosition)
end

function FengYun_JianJiTopList_OnShow()
    FengYun_JianJiTopList_ListFrame:Clear()

    -- 显示排行
    local nDataCount = DataPool:lua_GetFYJCGRRankItemCount()
    local szSelfGuid = GetSelfGUID()

    if nDataCount < 1 then
        local ItemBar = FengYun_JianJiTopList_ListFrame:AddChild("FengYun_JianJiTopList_AItem")
        ItemBar:GetSubItem("FengYun_JianJiTopList_AItem_None"):Show()
        ItemBar:GetSubItem("FengYun_JianJiTopList_AItem_Rank"):Hide()
        ItemBar:GetSubItem("FengYun_JianJiTopList_AItem_Name"):Hide()
        ItemBar:GetSubItem("FengYun_JianJiTopList_AItem_Server"):Hide()
        ItemBar:GetSubItem("FengYun_JianJiTopList_AItem_School"):Hide()
        ItemBar:GetSubItem("FengYun_JianJiTopList_AItem_Score"):Hide()
    end

    local myRankInDaily = -1
    for i = 0, nDataCount - 1 do
        local nRank, name, worldname, nmenpai,npoint,nguid = DataPool:lua_GetFYJCGRRankItemInfo(i)
        if nRank >= 0 then
            if Player:GetGUID() == nguid then
                myRankInDaily = i
            end

            local ItemBar = FengYun_JianJiTopList_ListFrame:AddChild("FengYun_JianJiTopList_AItem")

            ItemBar:GetSubItem("FengYun_JianJiTopList_AItem_None"):Hide()
            
            local rankstr = ScriptGlobal_Format("#{FYPVP_260106_107}", nRank+1)
            ItemBar:GetSubItem("FengYun_JianJiTopList_AItem_Rank"):SetText(rankstr)
    
            local namestr = ScriptGlobal_Format("#{FYPVP_260106_107}", name)
            ItemBar:GetSubItem("FengYun_JianJiTopList_AItem_Name"):SetText(namestr)
    
            local worldnamestr = ScriptGlobal_Format("#{FYPVP_260106_107}", worldname)
            ItemBar:GetSubItem("FengYun_JianJiTopList_AItem_Server"):SetText(worldnamestr)
    
            if g_MenPaiName[nmenpai] ~= nil then
                local menpaistr = ScriptGlobal_Format("#{FYPVP_260106_107}", g_MenPaiName[nmenpai])
                ItemBar:GetSubItem("FengYun_JianJiTopList_AItem_School"):SetText(menpaistr)
            else
                ItemBar:GetSubItem("FengYun_JianJiTopList_AItem_School"):SetText("")
            end
            local pointstr = ScriptGlobal_Format("#{FYPVP_260106_107}", npoint)
            ItemBar:GetSubItem("FengYun_JianJiTopList_AItem_Score"):SetText(pointstr)
        end
    end

    g_MyRank = myRankInDaily

    local nMyLevel = Player:GetLevel();
    local myname = Player:GetName();
    local selfzoneid = DataPool:GetSelfZoneWorldID()

    -- 我的显示的地方
    if myRankInDaily ~= -1 then
        local nRank, name, worldname, nmenpai,npoint,nguid = DataPool:lua_GetFYJCGRRankItemInfo(myRankInDaily)

        FengYun_JianJiTopList_My_Rank:SetText(nRank+1)
        FengYun_JianJiTopList_My_Name:SetText(name)
        FengYun_JianJiTopList_My_Server:SetText(worldname)

        if g_MenPaiName[nmenpai] ~= nil then
            FengYun_JianJiTopList_My_School:SetText(g_MenPaiName[nmenpai])
        else
            FengYun_JianJiTopList_My_School:SetText("")
        end
        FengYun_JianJiTopList_My_Score:SetText(npoint)
    else
        local nresult, name, worldname, nmenpai,npoint = DataPool: lua_GetFYJMyInfo()
        if nresult > 0 then
            FengYun_JianJiTopList_My_Rank:SetText("#{FYPVP_260106_108}")
            FengYun_JianJiTopList_My_Name:SetText(name)
            FengYun_JianJiTopList_My_Server:SetText(worldname)
    
            if g_MenPaiName[nmenpai] ~= nil then
                FengYun_JianJiTopList_My_School:SetText(g_MenPaiName[nmenpai])
            else
                FengYun_JianJiTopList_My_School:SetText("")
            end
            FengYun_JianJiTopList_My_Score:SetText(npoint)
        else
            FengYun_JianJiTopList_My_Rank:SetText("")
            FengYun_JianJiTopList_My_Name:SetText("")
            FengYun_JianJiTopList_My_Server:SetText("#{FYPVP_260106_108}")
            FengYun_JianJiTopList_My_School:SetText("")
            FengYun_JianJiTopList_My_Score:SetText("")
        end

        if nDataCount == 0 then

        end
    end
    this:Show()
end


function FengYun_JianJiTopList_Close_Clicked()
    FengYun_JianJiTopList_StopCareObject()
    this:Hide()
end

function FengYun_JianJiTopList_Hide()
    FengYun_JianJiTopList_StopCareObject()
    this:Hide()
end

function FengYun_JianJiTopList_Help_Clicked()

end

--=========================================================
--开始关心NPC
--=========================================================
function FengYun_JianJiTopList_BeginCareObject(objCaredId)
    if g_objCared ~= -1 then
        this:CareObject(objCaredId, 0, "FengYun_JianJiTopList");
    end
    g_objCared = objCaredId
    this:CareObject(g_objCared, 1, "FengYun_JianJiTopList")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function FengYun_JianJiTopList_StopCareObject()
    if g_objCared ~= -1 then
        this:CareObject(g_objCared, 0, "FengYun_JianJiTopList");
        g_objCared = -1
    end
end
