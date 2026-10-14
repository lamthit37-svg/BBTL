local g_FengYun_JianJiCreateManger_Frame_UnifiedPosition = nil
local g_NpcId = -1

local g_objCared = -1
local g_OBJ_DISTANCE = 5.0
local g_TeamCount = 6

local g_IsLeader = 0
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

local g_FYJCTeamPic ={}
local g_FYJCTeameName = {}  -- 名字
local g_FYJCTeameMenPai = {}  -- 门派
local g_FYJCTeameLevel = {}  -- 等级
local g_FYJCTeameScore = {}  -- 积分
local g_FYJCTeameTag = {}  -- 标记
local g_FYJCTeamInfo={}

function FengYun_JianJiCreateManger_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("OPEN_FYJCPVP_TD_JOIN_INFO", true)
    this:RegisterEvent("OBJECT_CARED_EVENT", true)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
end

function FengYun_JianJiCreateManger_OnLoad()
    g_FengYun_JianJiCreateManger_Frame_UnifiedPosition = FengYun_JianJiCreateManger_Frame:GetProperty("UnifiedPosition")

    
    g_FYJCTeamPic[1] = FengYun_JianJiCreateManger_List1_Pic
    g_FYJCTeamPic[2] = FengYun_JianJiCreateManger_List2_Pic
    g_FYJCTeamPic[3] = FengYun_JianJiCreateManger_List3_Pic
    g_FYJCTeamPic[4] = FengYun_JianJiCreateManger_List4_Pic
    g_FYJCTeamPic[5] = FengYun_JianJiCreateManger_List5_Pic
    g_FYJCTeamPic[6] = FengYun_JianJiCreateManger_List6_Pic

    g_FYJCTeameName[1] = FengYun_JianJiCreateManger_List1_1
    g_FYJCTeameName[2] = FengYun_JianJiCreateManger_List2_1
    g_FYJCTeameName[3] = FengYun_JianJiCreateManger_List3_1
    g_FYJCTeameName[4] = FengYun_JianJiCreateManger_List4_1
    g_FYJCTeameName[5] = FengYun_JianJiCreateManger_List5_1
    g_FYJCTeameName[6] = FengYun_JianJiCreateManger_List6_1

    g_FYJCTeameMenPai[1] = FengYun_JianJiCreateManger_List1_2
    g_FYJCTeameMenPai[2] = FengYun_JianJiCreateManger_List2_2
    g_FYJCTeameMenPai[3] = FengYun_JianJiCreateManger_List3_2
    g_FYJCTeameMenPai[4] = FengYun_JianJiCreateManger_List4_2
    g_FYJCTeameMenPai[5] = FengYun_JianJiCreateManger_List5_2
    g_FYJCTeameMenPai[6] = FengYun_JianJiCreateManger_List6_2

    g_FYJCTeameLevel[1] = FengYun_JianJiCreateManger_List1_3
    g_FYJCTeameLevel[2] = FengYun_JianJiCreateManger_List2_3
    g_FYJCTeameLevel[3] = FengYun_JianJiCreateManger_List3_3
    g_FYJCTeameLevel[4] = FengYun_JianJiCreateManger_List4_3
    g_FYJCTeameLevel[5] = FengYun_JianJiCreateManger_List5_3
    g_FYJCTeameLevel[6] = FengYun_JianJiCreateManger_List6_3

    g_FYJCTeameScore[1] = FengYun_JianJiCreateManger_List1_4
    g_FYJCTeameScore[2] = FengYun_JianJiCreateManger_List2_4
    g_FYJCTeameScore[3] = FengYun_JianJiCreateManger_List3_4
    g_FYJCTeameScore[4] = FengYun_JianJiCreateManger_List4_4
    g_FYJCTeameScore[5] = FengYun_JianJiCreateManger_List5_4
    g_FYJCTeameScore[6] = FengYun_JianJiCreateManger_List6_4

    g_FYJCTeamInfo[1] = FengYun_JianJiCreateManger_List1_Bk
    g_FYJCTeamInfo[2] = FengYun_JianJiCreateManger_List2_Bk
    g_FYJCTeamInfo[3] = FengYun_JianJiCreateManger_List3_Bk
    g_FYJCTeamInfo[4] = FengYun_JianJiCreateManger_List4_Bk
    g_FYJCTeamInfo[5] = FengYun_JianJiCreateManger_List5_Bk
    g_FYJCTeamInfo[6] = FengYun_JianJiCreateManger_List6_Bk 

end

function FengYun_JianJiCreateManger_OnEvent(event)
    if event == "OPEN_FYJCPVP_TD_JOIN_INFO" then
        g_NpcId = tonumber(arg0)
        g_objCared = DataPool:GetNPCIDByServerID(g_NpcId) 
        FengYun_JianJiCreateManger_BeginCareObject(g_objCared)
        FengYun_JianJiCreateManger_OnShow()
    elseif (event == "ADJEST_UI_POS") then
        FengYun_JianJiCreateManger_On_ResetPos()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        FengYun_JianJiCreateManger_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        FengYun_JianJiCreateManger_CloseClicked()
    elseif ( event == "OBJECT_CARED_EVENT" and this : IsVisible() ) then
        if( tonumber(arg0) ~= g_NpcId or g_IsLeader ~= 1 ) then
			return
		end
       	--- 如果和NPC的距离大于一定的距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > g_OBJ_DISTANCE or arg1=="destroy") then
			FengYun_JianJiCreateManger_CloseClicked()
        end 
    elseif (event == "UI_COMMAND" and tonumber(arg0) == 50711501) then
        FengYun_JianJiCreateManger_CloseClicked()
    end
end

function FengYun_JianJiCreateManger_On_ResetPos()
    FengYun_JianJiCreateManger_Frame:SetProperty("UnifiedPosition", g_FengYun_JianJiCreateManger_Frame_UnifiedPosition)
end

function FengYun_JianJiCreateManger_OnShow()

    local myRankInDaily = 0
    g_IsLeader = 0
    for i = 0, g_TeamCount - 1 do
        local nguid, name, nmenpai, nlevel,npoint = DataPool:lua_GetFYJCTDJoinTeamInfo(i)
        if nmenpai ~= nil then
            -- 队长标识
            if i == 0 then
                if Player:GetGUID() == nguid then
                    myRankInDaily = 1
                    g_IsLeader = 1
                end
            end

            g_FYJCTeamPic[i+1]:Show()
            g_FYJCTeameName[i+1]:SetText(name) -- 名字

            if g_MenPaiName[nmenpai] ~= nil then
                local menpaistr = ScriptGlobal_Format("#{FYBM_260108_34}", g_MenPaiName[nmenpai])
                g_FYJCTeameMenPai[i+1]:SetText(menpaistr)
            else
                g_FYJCTeameMenPai[i+1]:SetText("")
            end

            g_FYJCTeameLevel[i+1]:SetText(nlevel)
            g_FYJCTeameScore[i+1]:SetText(npoint)
        end
    end

    if myRankInDaily == 0 then
        FengYun_JianJiCreateManger_AddMember:Hide()
        FengYun_JianJiCreateManger_Leave:Hide()
    else
        FengYun_JianJiCreateManger_Leave:Show()
        FengYun_JianJiCreateManger_AddMember:Show()
    end

    this:Show()
end


function FengYun_JianJiCreateManger_CloseClicked()

    if g_IsLeader == 1 then
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name("OnPlayerCancelJoin")
            Set_XSCRIPT_ScriptID(507115)
            Set_XSCRIPT_Parameter(0,g_NpcId); 
            Set_XSCRIPT_ParamCount(1)
         Send_XSCRIPT()
    end

    FengYun_JianJiCreateManger_StopCareObject()
    this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function FengYun_JianJiCreateManger_BeginCareObject(objCaredId)
    if g_objCared ~= -1 then
        this:CareObject(objCaredId, 0, "FengYun_JianJiCreateManger");
    end
    g_objCared = objCaredId
    this:CareObject(g_objCared, 1, "FengYun_JianJiCreateManger")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function FengYun_JianJiCreateManger_StopCareObject()
    if g_objCared ~= -1 then
        this:CareObject(g_objCared, 0, "FengYun_JianJiCreateManger");
        g_objCared = -1
    end
end

--取消
function FengYun_JianJiCreateManger_OutTeam_Clicked()
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("OnPlayerCancelJoin")
        Set_XSCRIPT_ScriptID(507115)
        Set_XSCRIPT_Parameter(0,g_NpcId); 
        Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()

    FengYun_JianJiCreateManger_StopCareObject()
    this:Hide()
end

-- 报名
function FengYun_JianJiCreateManger_Invite_Clicked(id)
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("OnPlayerJoin")
        Set_XSCRIPT_ScriptID(507115)
        Set_XSCRIPT_Parameter(0,g_NpcId); 
        Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()

    FengYun_JianJiCreateManger_StopCareObject()
    this:Hide()
end

function FengYun_JianJiCreateManger_ToggleMemberMenu(index)

end

function FengYun_JianJiCreateManger_Clicked(index)

end

function FengYun_JianJiCreateManger_DragStarted()

end