-- 新比武（6v6）季后赛 奖励展示UI
-- 关注NPC
local HuaShanLunJian2_Award_CareObjId = -1
local HuaShanLunJian2_Award_CareObjSvrId = -1
local HuaShanLunJian2_Award_MAX_OBJ_DISTANCE = 5.0
-- 默认位置
local HuaShanLunJian2_Award_UnifiedPosition = nil
-- 奖励展示控件列表
local HuaShanLunJian2_Award_CtrlList = nil
-- 奖励信息
local HuaShanLunJian2_Award_AwardInfo =
{
    -- 冠军奖励
    [1] =
    {
        [1] = {id = 38008738, num = 1},
        [2] = {id = 10101145, num = 1},
        [3] = {id = 20502015, num = 5},
        [4] = {id = 20501009, num = 5},
        [5] = {id = 20502004, num = 5},
        [6] = {id = 20501004, num = 5},
    },
    -- 亚军奖励
    [2] =
    {
        [1] = {id = 38008737, num = 1},
        [2] = {id = 10101144, num = 1},
        [3] = {id = 20502015, num = 3},
        [4] = {id = 20501009, num = 3},
        [5] = {id = 20502004, num = 3},
        [6] = {id = 20501004, num = 3},
    },
    -- 季军奖励（3、4名并列）
    [3] =
    {
        [1] = {id = 38008737, num = 1},
        [2] = {id = 10101143, num = 1},
        [3] = {id = 20502015, num = 2},
        [4] = {id = 20501009, num = 2},
        [5] = {id = 20502004, num = 2},
        [6] = {id = 20501004, num = 2},
    },
    -- 8强
    [4] =
    {
        [1] = {id = 38008737, num = 1},
        [2] = {id = 20502015, num = 1},
        [3] = {id = 20501009, num = 1},
        [4] = {id = 20502003, num = 5},
        [5] = {id = 20501003, num = 5},
    },
    -- 16强
    [5] =
    {
        [1] = {id = 38008737, num = 1},
        [2] = {id = 20502003, num = 5},
        [3] = {id = 20501003, num = 5},
    },
    -- 32强
    [6] =
    {
        [1] = {id = 38008737, num = 1},
        [2] = {id = 20502003, num = 3},
        [3] = {id = 20501003, num = 3},
    },
    -- 64强
    [7] =
    {
        [1] = {id = 38008737, num = 1},
        [2] = {id = 20502003, num = 2},
        [3] = {id = 20501003, num = 2},
    },
    -- 128强
    [8] =
    {
        [1] = {id = 38008737, num = 1},
    },
    -- 原服晋级奖励
    [9] =
    {
        [1] = {id = 38008798, num = 1},
    },
    -- 参赛奖励
    [10] =
    {
        [1] = {id = 20502003, num = 2},
        [2] = {id = 20501003, num = 2},
    },
} -- end HuaShanLunJian2_Award_AwardInfo




function HuaShanLunJian2_Award_PreLoad()
	this:RegisterEvent("XBWJHS_SHOWAWARD", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func HuaShanLunJian2_Award_PreLoad()

function HuaShanLunJian2_Award_OnEvent(event)
	if (event == "XBWJHS_SHOWAWARD") then
        HuaShanLunJian2_Award_BeginCareObject(tonumber(arg0), tonumber(arg1))
        HuaShanLunJian2_Award_UpdateAwardInfo()
		HuaShanLunJian2_Award_Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		HuaShanLunJian2_Award_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HuaShanLunJian2_Award_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		HuaShanLunJian2_Award_UnifiedPos()
	end
end -- end func HuaShanLunJian2_Award_OnEvent()

function HuaShanLunJian2_Award_OnLoad()
	HuaShanLunJian2_Award_UnifiedPosition = HuaShanLunJian2_Award_Frame:GetProperty("UnifiedPosition")
end -- end func HuaShanLunJian2_Award_OnLoad()

-- 界面默认位置
function HuaShanLunJian2_Award_UnifiedPos()
	if (HuaShanLunJian2_Award_UnifiedPosition ~= nil) then
		HuaShanLunJian2_Award_Frame:SetProperty("UnifiedPosition", HuaShanLunJian2_Award_UnifiedPosition)
	end
end -- end func HuaShanLunJian2_Award_UnifiedPos()

function HuaShanLunJian2_Award_Show()
    this:Show()
end -- end func HuaShanLunJian2_Award_Show()

function HuaShanLunJian2_Award_Hide()
	HuaShanLunJian2_Award_StopCareObject()
    this:Hide()
end -- end func HuaShanLunJian2_Award_Hide()

-- 开启NPC关注
function HuaShanLunJian2_Award_BeginCareObject(objSvrId, objId)
	HuaShanLunJian2_Award_CareObjSvrId = objSvrId
	HuaShanLunJian2_Award_CareObjId = objId
	if (HuaShanLunJian2_Award_CareObjId >= 0) then
		this:CareObject(HuaShanLunJian2_Award_CareObjId, 1, "HuaShanLunJian2_Award")
	end
end -- end func HuaShanLunJian2_Award_BeginCareObject()

-- 取消NPC关注
function HuaShanLunJian2_Award_StopCareObject()
	if (HuaShanLunJian2_Award_CareObjId >= 0) then
		this:CareObject(HuaShanLunJian2_Award_CareObjId, 0, "HuaShanLunJian2_Award")
		HuaShanLunJian2_Award_CareObjId = -1
		HuaShanLunJian2_Award_CareObjSvrId = -1
	end
end -- end func HuaShanLunJian2_Award_StopCareObject()

-- 初始化控件
function HuaShanLunJian2_Award_InitCtrlList()
    if (HuaShanLunJian2_Award_CtrlList == nil) then
        HuaShanLunJian2_Award_CtrlList = {}
        -- 冠军奖励
        HuaShanLunJian2_Award_CtrlList[1] = {}
        HuaShanLunJian2_Award_CtrlList[1][1] = HuaShanLunJian2_Award_Icon1
        HuaShanLunJian2_Award_CtrlList[1][2] = HuaShanLunJian2_Award_Icon1_2
        HuaShanLunJian2_Award_CtrlList[1][3] = HuaShanLunJian2_Award_Icon1_3
        HuaShanLunJian2_Award_CtrlList[1][4] = HuaShanLunJian2_Award_Icon1_4
        HuaShanLunJian2_Award_CtrlList[1][5] = HuaShanLunJian2_Award_Icon1_5
        HuaShanLunJian2_Award_CtrlList[1][6] = HuaShanLunJian2_Award_Icon1_6
        -- 亚军奖励
        HuaShanLunJian2_Award_CtrlList[2] = {}
        HuaShanLunJian2_Award_CtrlList[2][1] = HuaShanLunJian2_Award_Icon2
        HuaShanLunJian2_Award_CtrlList[2][2] = HuaShanLunJian2_Award_Icon2_2
        HuaShanLunJian2_Award_CtrlList[2][3] = HuaShanLunJian2_Award_Icon2_3
        HuaShanLunJian2_Award_CtrlList[2][4] = HuaShanLunJian2_Award_Icon2_4
        HuaShanLunJian2_Award_CtrlList[2][5] = HuaShanLunJian2_Award_Icon2_5
        HuaShanLunJian2_Award_CtrlList[2][6] = HuaShanLunJian2_Award_Icon2_6
        -- 季军奖励（3、4名并列）
        HuaShanLunJian2_Award_CtrlList[3] = {}
        HuaShanLunJian2_Award_CtrlList[3][1] = HuaShanLunJian2_Award_Icon3
        HuaShanLunJian2_Award_CtrlList[3][2] = HuaShanLunJian2_Award_Icon3_2
        HuaShanLunJian2_Award_CtrlList[3][3] = HuaShanLunJian2_Award_Icon3_3
        HuaShanLunJian2_Award_CtrlList[3][4] = HuaShanLunJian2_Award_Icon3_4
        HuaShanLunJian2_Award_CtrlList[3][5] = HuaShanLunJian2_Award_Icon3_5
        HuaShanLunJian2_Award_CtrlList[3][6] = HuaShanLunJian2_Award_Icon3_6
        -- 8强奖励
        HuaShanLunJian2_Award_CtrlList[4] = {}
        HuaShanLunJian2_Award_CtrlList[4][1] = HuaShanLunJian2_Award_Icon4
        HuaShanLunJian2_Award_CtrlList[4][2] = HuaShanLunJian2_Award_Icon4_2
        HuaShanLunJian2_Award_CtrlList[4][3] = HuaShanLunJian2_Award_Icon4_3
        HuaShanLunJian2_Award_CtrlList[4][4] = HuaShanLunJian2_Award_Icon4_4
        HuaShanLunJian2_Award_CtrlList[4][5] = HuaShanLunJian2_Award_Icon4_5
        HuaShanLunJian2_Award_CtrlList[4][6] = HuaShanLunJian2_Award_Icon4_6
        -- 16强奖励
        HuaShanLunJian2_Award_CtrlList[5] = {}
        HuaShanLunJian2_Award_CtrlList[5][1] = HuaShanLunJian2_Award_Icon5
        HuaShanLunJian2_Award_CtrlList[5][2] = HuaShanLunJian2_Award_Icon5_2
        HuaShanLunJian2_Award_CtrlList[5][3] = HuaShanLunJian2_Award_Icon5_3
        HuaShanLunJian2_Award_CtrlList[5][4] = HuaShanLunJian2_Award_Icon5_4
        HuaShanLunJian2_Award_CtrlList[5][5] = HuaShanLunJian2_Award_Icon5_5
        HuaShanLunJian2_Award_CtrlList[5][6] = HuaShanLunJian2_Award_Icon5_6
        -- 32强奖励
        HuaShanLunJian2_Award_CtrlList[6] = {}
        HuaShanLunJian2_Award_CtrlList[6][1] = HuaShanLunJian2_Award_Icon6
        HuaShanLunJian2_Award_CtrlList[6][2] = HuaShanLunJian2_Award_Icon6_2
        HuaShanLunJian2_Award_CtrlList[6][3] = HuaShanLunJian2_Award_Icon6_3
        HuaShanLunJian2_Award_CtrlList[6][4] = HuaShanLunJian2_Award_Icon6_4
        HuaShanLunJian2_Award_CtrlList[6][5] = HuaShanLunJian2_Award_Icon6_5
        HuaShanLunJian2_Award_CtrlList[6][6] = HuaShanLunJian2_Award_Icon6_6
        -- 64强奖励
        HuaShanLunJian2_Award_CtrlList[7] = {}
        HuaShanLunJian2_Award_CtrlList[7][1] = HuaShanLunJian2_Award_Icon7
        HuaShanLunJian2_Award_CtrlList[7][2] = HuaShanLunJian2_Award_Icon7_2
        HuaShanLunJian2_Award_CtrlList[7][3] = HuaShanLunJian2_Award_Icon7_3
        HuaShanLunJian2_Award_CtrlList[7][4] = HuaShanLunJian2_Award_Icon7_4
        HuaShanLunJian2_Award_CtrlList[7][5] = HuaShanLunJian2_Award_Icon7_5
        HuaShanLunJian2_Award_CtrlList[7][6] = HuaShanLunJian2_Award_Icon7_6
        -- 128强奖励
        HuaShanLunJian2_Award_CtrlList[8] = {}
        HuaShanLunJian2_Award_CtrlList[8][1] = HuaShanLunJian2_Award_Icon8
        HuaShanLunJian2_Award_CtrlList[8][2] = HuaShanLunJian2_Award_Icon8_2
        HuaShanLunJian2_Award_CtrlList[8][3] = HuaShanLunJian2_Award_Icon8_3
        HuaShanLunJian2_Award_CtrlList[8][4] = HuaShanLunJian2_Award_Icon8_4
        HuaShanLunJian2_Award_CtrlList[8][5] = HuaShanLunJian2_Award_Icon8_5
        HuaShanLunJian2_Award_CtrlList[8][6] = HuaShanLunJian2_Award_Icon8_6
        -- 晋级奖励
        HuaShanLunJian2_Award_CtrlList[9] = {}
        HuaShanLunJian2_Award_CtrlList[9][1] = HuaShanLunJian2_Award_Icon9
        HuaShanLunJian2_Award_CtrlList[9][2] = HuaShanLunJian2_Award_Icon9_2
        HuaShanLunJian2_Award_CtrlList[9][3] = HuaShanLunJian2_Award_Icon9_3
        HuaShanLunJian2_Award_CtrlList[9][4] = HuaShanLunJian2_Award_Icon9_4
        HuaShanLunJian2_Award_CtrlList[9][5] = HuaShanLunJian2_Award_Icon9_5
        HuaShanLunJian2_Award_CtrlList[9][6] = HuaShanLunJian2_Award_Icon9_6
        -- 参赛奖励
        HuaShanLunJian2_Award_CtrlList[10] = {}
        HuaShanLunJian2_Award_CtrlList[10][1] = HuaShanLunJian2_Award_Icon10
        HuaShanLunJian2_Award_CtrlList[10][2] = HuaShanLunJian2_Award_Icon10_2
        HuaShanLunJian2_Award_CtrlList[10][3] = HuaShanLunJian2_Award_Icon10_3
        HuaShanLunJian2_Award_CtrlList[10][4] = HuaShanLunJian2_Award_Icon10_4
        HuaShanLunJian2_Award_CtrlList[10][5] = HuaShanLunJian2_Award_Icon10_5
        HuaShanLunJian2_Award_CtrlList[10][6] = HuaShanLunJian2_Award_Icon10_6
    end
end -- end func HuaShanLunJian2_Award_InitCtrlList()


--*************************************************************************************************
--*************************************************************************************************
--
--*************************************************************************************************
--*************************************************************************************************
function HuaShanLunJian2_Award_UpdateAwardInfo()
    HuaShanLunJian2_Award_InitCtrlList()

    if (HuaShanLunJian2_Award_CtrlList == nil) then
        return
    end
    if (HuaShanLunJian2_Award_AwardInfo == nil) then
        return
    end
    
    for i=1, table.getn(HuaShanLunJian2_Award_CtrlList), 1 do
        local ctrlList = HuaShanLunJian2_Award_CtrlList[i]
        local awardList = HuaShanLunJian2_Award_AwardInfo[i]
        if (ctrlList ~= nil) then
            for j=1, table.getn(ctrlList), 1 do
                if (awardList ~= nil and awardList[j] ~= nil) then
                    local theAction = DataPool:CreateBindActionItemForShow(awardList[j].id, awardList[j].num)
                    if (theAction:GetID() ~= 0) then
                        ctrlList[j]:Show()
                        ctrlList[j]:SetActionItem(theAction:GetID())
                    else
                        ctrlList[j]:SetActionItem(-1)
                        ctrlList[j]:Hide()
                    end
                else
                    ctrlList[j]:SetActionItem(-1)
                    ctrlList[j]:Hide()
                end
            end -- end for
        end
    end -- end for
end -- end func HuaShanLunJian2_Award_UpdateAwardInfo()