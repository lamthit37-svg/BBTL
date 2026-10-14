local g_FengYun_JianJiTeamInfo_Frame_UnifiedPosition = nil
local g_NpcId = -1

local g_objCared = -1
local g_OBJ_DISTANCE = 5.0
local g_TeamCount = 6

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

local g_FYJCTeameName = {}  -- 名字
local g_FYJCTeameMenPai = {}  -- 门派
local g_FYJCTeameLevel = {}  -- 等级
local g_FYJCTeameScore = {}  -- 积分


function FengYun_JianJiTeamInfo_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("OPEN_FYJCPVP_TD_TEAM_INFO", true)
    this:RegisterEvent("OBJECT_CARED_EVENT", true)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
end

function FengYun_JianJiTeamInfo_OnLoad()
    g_FengYun_JianJiTeamInfo_Frame_UnifiedPosition = FengYun_JianJiTeamInfo_Frame:GetProperty("UnifiedPosition")

    g_FYJCTeameName[1] = FengYun_JianJiTeamInfo_Team1_List1_1
    g_FYJCTeameName[2] = FengYun_JianJiTeamInfo_Team1_List2_1
    g_FYJCTeameName[3] = FengYun_JianJiTeamInfo_Team1_List3_1
    g_FYJCTeameName[4] = FengYun_JianJiTeamInfo_Team1_List4_1
    g_FYJCTeameName[5] = FengYun_JianJiTeamInfo_Team1_List5_1
    g_FYJCTeameName[6] = FengYun_JianJiTeamInfo_Team1_List6_1

    g_FYJCTeameMenPai[1] = FengYun_JianJiTeamInfo_Team1_List1_2
    g_FYJCTeameMenPai[2] = FengYun_JianJiTeamInfo_Team1_List2_2
    g_FYJCTeameMenPai[3] = FengYun_JianJiTeamInfo_Team1_List3_2
    g_FYJCTeameMenPai[4] = FengYun_JianJiTeamInfo_Team1_List4_2
    g_FYJCTeameMenPai[5] = FengYun_JianJiTeamInfo_Team1_List5_2
    g_FYJCTeameMenPai[6] = FengYun_JianJiTeamInfo_Team1_List6_2

    g_FYJCTeameLevel[1] = FengYun_JianJiTeamInfo_Team1_List1_3
    g_FYJCTeameLevel[2] = FengYun_JianJiTeamInfo_Team1_List2_3
    g_FYJCTeameLevel[3] = FengYun_JianJiTeamInfo_Team1_List3_3
    g_FYJCTeameLevel[4] = FengYun_JianJiTeamInfo_Team1_List4_3
    g_FYJCTeameLevel[5] = FengYun_JianJiTeamInfo_Team1_List5_3
    g_FYJCTeameLevel[6] = FengYun_JianJiTeamInfo_Team1_List6_3

    g_FYJCTeameScore[1] = FengYun_JianJiTeamInfo_Team1_List1_4
    g_FYJCTeameScore[2] = FengYun_JianJiTeamInfo_Team1_List2_4
    g_FYJCTeameScore[3] = FengYun_JianJiTeamInfo_Team1_List3_4
    g_FYJCTeameScore[4] = FengYun_JianJiTeamInfo_Team1_List4_4
    g_FYJCTeameScore[5] = FengYun_JianJiTeamInfo_Team1_List5_4
    g_FYJCTeameScore[6] = FengYun_JianJiTeamInfo_Team1_List6_4

end

function FengYun_JianJiTeamInfo_OnEvent(event)
    if event == "OPEN_FYJCPVP_TD_TEAM_INFO" then
        g_NpcId = tonumber(arg0)
        g_objCared = DataPool:GetNPCIDByServerID(g_NpcId) 
        FengYun_JianJiTeamInfo_BeginCareObject(g_objCared)

        FengYun_JianJiTeamInfo_OnShow(tonumber(arg1))
    elseif (event == "ADJEST_UI_POS") then
        FengYun_JianJiTeamInfo_On_ResetPos()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        FengYun_JianJiTeamInfo_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        FengYun_JianJiTeamInfo_CloseClicked()
    elseif ( event == "OBJECT_CARED_EVENT" and this : IsVisible() ) then
        if( tonumber(arg0) ~= g_NpcId ) then
			return
		end
       	--- 如果和NPC的距离大于一定的距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > g_OBJ_DISTANCE or arg1=="destroy") then
			FengYun_JianJiTeamInfo_CloseClicked()
        end 
    end
end

function FengYun_JianJiTeamInfo_On_ResetPos()
    FengYun_JianJiTeamInfo_Frame:SetProperty("UnifiedPosition", g_FengYun_JianJiTeamInfo_Frame_UnifiedPosition)
end

function FengYun_JianJiTeamInfo_OnShow(nIndex)

    for i = 0, g_TeamCount - 1 do
        local nRank, worldname, pointCount, charName,nmenpai,nelvel,nequip = DataPool:lua_GetFYJCTDTeamInfo(nIndex,i)
        if pointCount ~= nil then

            g_FYJCTeameName[i+1]:SetText(charName)

            if g_MenPaiName[nmenpai] ~= nil then
                local menpaistr = ScriptGlobal_Format("#{FYBM_260108_34}", g_MenPaiName[nmenpai])
                g_FYJCTeameMenPai[i+1]:SetText(menpaistr)
            else
                g_FYJCTeameMenPai[i+1]:SetText("")
            end
    
            g_FYJCTeameLevel[i+1]:SetText(nelvel)
            g_FYJCTeameScore[i+1]:SetText(nequip)

        end
    end

    this:Show()
end


function FengYun_JianJiTeamInfo_CloseClicked()
    FengYun_JianJiTeamInfo_StopCareObject()
    this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function FengYun_JianJiTeamInfo_BeginCareObject(objCaredId)
    if g_objCared ~= -1 then
        this:CareObject(objCaredId, 0, "FengYun_JianJiTeamInfo");
    end
    g_objCared = objCaredId
    this:CareObject(g_objCared, 1, "FengYun_JianJiTeamInfo")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function FengYun_JianJiTeamInfo_StopCareObject()
    if g_objCared ~= -1 then
        this:CareObject(g_objCared, 0, "FengYun_JianJiTeamInfo");
        g_objCared = -1
    end
end

