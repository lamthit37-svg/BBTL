-- 凤鸣城战替换玩法（限制人数玩法）帮会成员以及助战成员UI
local NewBangHuiBZTX_Candidate_IsDebug = 0
-- 当前排序模式
local NewBangHuiBZTX_Candidate_MemberSortMode = -1
-- 是否开启轮换玩法（玩法模式）
local NewBangHuiBZTX_Candidate_TCWLServerOpenFlag = 0
local NewBangHuiBZTX_Candidate_TCWLOpenWeekFlag = 0
-- 当前周数
local NewBangHuiBZTX_Candidate_CurWeekCount = 0
-- 本帮成员已经分配资格的人数
local NewBangHuiBZTX_Candidate_AssignedMemberCount = 0
local NewBangHuiBZTX_Candidate_AssignedMemberOnlineCount = 0
local NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 = 0
local NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 = 0
-- 助战玩家人数
local NewBangHuiBZTX_Candidate_AssistPlayerNum = 0 
local NewBangHuiBZTX_Candidate_AssistPlayerOnlineNum = 0 
local NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1 = 0
local NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2 = 0
-- 最大参战人数（本帮成员+助战玩家）
local NewBangHuiBZTX_Candidate_MaxPlayerCount = 60
-- 每组最大人数
local NewBangHuiBZTX_Candidate_GroupPlayerMaxCount = 60
-- 上一次操作时间
local NewBangHuiBZTX_Candidate_LastOpTime = 0
local NewBangHuiBZTX_Candidate_LastAssistOpTime = 0
-- 操作CD（秒）
local NewBangHuiBZTX_Candidate_OpCDTime = 6
local NewBangHuiBZTX_Candidate_RemoveAssistCDTime = 1
-- 参与名单变化标记
local NewBangHuiBZTX_Candidate_Changed = 0
-- 数据初始化标记
local NewBangHuiBZTX_Candidate_PlayerListInitFlag = 0
-- 当前选中的页签
local NewBangHuiBZTX_Candidate_CurPlayerListTab = 0
-- 列表控件项目条数
local NewBangHuiBZTX_Candidate_ListItemNum = 0
-- 禁止参与资格分配操作的时间
local NewBangHuiBZTX_Candidate_AssignForbiddenTime =
{
    weekday = 6,
    mintime = {202000, 213000},
} -- end NewBangHuiBZTX_Candidate_AssignForbiddenTime
-- 助战操作时间
local NewBangHuiBZTX_Candidate_AssistOpTime =
{
    [1] = {weekday = 5, begintime = 213000},
    [2] = {weekday = 6, endtime = 202000},
} -- end NewBangHuiBZTX_Candidate_AssistOpTime
-- 页签类型
local NewBangHuiBZTX_Candidate_TabType =
{
    default = 0,
    guildmember = 1,        -- 本帮成员
    assistplayer = 2,       -- 助战成员
} -- end NewBangHuiBZTX_Candidate_TabType
-- 助战玩家分组
local NewBangHuiBZTX_Candidate_GroupId =
{
    group0 = 0,             -- 无分组
    group1 = 1,             -- 分组1
    group2 = 2,             -- 分组2
} -- end NewBangHuiBZTX_Candidate_GroupId
-- 参与名额分配结果
local NewBangHuiBZTX_Candidate_OperateResult =
{
    null = -100,
	toofast = -99,			-- 操作过于频繁
	poserror = -98,			-- 不是帮主或副帮主
    notintime_member = -97,	-- 不在操作时间
    notintime_assist = -96,	-- 不在操作时间
    notopensvr = -95,       -- 不是开启服务器
    guilderror = -94,       -- 帮会没有参战资格
	failed = 0,				-- 失败
	success = 1,			-- 成功
} -- end NewBangHuiBZTX_Candidate_OperateResult
-- 关闭类型
local NewBangHuiBZTX_Candidate_ExitType =
{
    cygl = 1,       -- 打开成员管理
    bhxx = 2,       -- 打开帮会信息
    bhtm = 3,       -- 打开帮会同盟
    bhxz = 4,       -- 打开帮会宣战
    bhjz = 5,       -- 打开帮会建筑介绍
    bhhb = 6,       -- 打开帮会红包
    yxzk = 7,       -- 打开浴血战况
    bhpm = 8,       -- 打开帮会拍卖
    close = 9,      -- 正常关闭

    bztx_guildmember = 11,      -- 本帮成员页签
    bztx_assistplayer = 12,     -- 助战成员页签
} -- end NewBangHuiBZTX_Candidate_ExitType
-- 门派
local NewBangHuiBZTX_Candidate_MenPaiNameList =
{
	[0] = "#{XQ_MP_1}",    		--少林
	[1] = "#{XQ_MP_2}",    		--明教
	[2] = "#{XQ_MP_3}",    		--丐帮
	[3] = "#{XQ_MP_4}",    		--武当
	[4] = "#{XQ_MP_5}",    		--峨眉
	[5] = "#{XQ_MP_6}",    		--星宿
	[6] = "#{XQ_MP_7}",    		--天龙
	[7] = "#{XQ_MP_8}",    		--天山
	[8] = "#{XQ_MP_9}",    		--逍遥
	[9] = "#{GCQH_240429_141}", --无门派
	[10] = "#{XQ_MP_10}",		--慕容
	[11] = "#{XQ_MP_13}",  		--唐门
	[12] = "#{XQ_MP_14}",  		--鬼谷
    [13] = "#{XQ_MP_15}",  		--桃花岛
	[14] = "#{XQ_MP_16}", 		--绝情谷
	[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}",	-- 恶人谷
} -- end NewBangHuiBZTX_Candidate_MenPaiNameList
-- 帮会职务
local NewBangHuiBZTX_Candidate_PositionInfo =
{
	"#{GCQH_240429_132}",       -- 待批准
	"#{GCQH_240429_133}",       -- 帮众
	"#{GCQH_240429_134}",       -- 精英
	"#{GCQH_240429_135}",       -- 商人
	"#{GCQH_240429_136}",       -- 弘化使
	"#{GCQH_240429_137}",       -- 工务使
	"#{GCQH_240429_138}",       -- 内务使
	"#{GCQH_240429_139}",       -- 副帮主
	"#{GCQH_240429_140}",       -- 帮主
} -- end NewBangHuiBZTX_Candidate_PositionInfo

-- 保存UI默认位置
local NewBangHuiBZTX_Candidate_UnifiedPosition = nil
-- 缓存要移除的助战玩家数据 用于二次确认返回后校验
local NewBangHuiBZTX_Candidate_RemoveAssistCache = nil

local g_NewBangHuiBZTX_Candidate_SelfGroup = 0


function NewBangHuiBZTX_Candidate_PreLoad()
    -- this:RegisterEvent("TCITYWARLIMIT_OPENCANDIDATE")
    -- this:RegisterEvent("TCITYWARLIMIT_ASSIGNCONFIRMRESULT")
    -- this:RegisterEvent("TCITYWARLIMIT_CANCELCONFIRMRESULT")
    -- this:RegisterEvent("TCITYWARLIMIT_SAVECONFIRMRESULT")
    -- this:RegisterEvent("TCITYWARLIMIT_REFRESHCONFIRMRESULT")
    -- this:RegisterEvent("TCITYWARLIMIT_EXITCONFIRMRESULT")
    -- this:RegisterEvent("TCITYWARLIMIT_OPERATERESULT")
    -- this:RegisterEvent("TCITYWARLIMIT_ESCCLOSE")
    -- this:RegisterEvent("TCITYWARLIMIT_REMOVEASSISTCONFIRMRESULT")
    -- this:RegisterEvent("TCITYWARLIMIT_MYSELFASSISTDATA")
    -- this:RegisterEvent("TCITYWARLIMIT_CANCELASSISTCONFIRMRESULT")
    -- this:RegisterEvent("TCITYWARLIMIT_UPDATEREDPOINTTIPS")
    -- this:RegisterEvent("GUILD_MEMBERINFO_BZTX")
    -- this:RegisterEvent("GUILD_ASSISTPLAYERINFO_BZTX")
	-- this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
    -- this:RegisterEvent("ADJEST_UI_POS",false)
    -- this:RegisterEvent("GUILD_BIDDING_SHOWLIST")
    -- this:RegisterEvent("GUILD_SHOW_MEMBERINFO")
	-- this:RegisterEvent("GUILD_SHOW_DETAILINFO")
	-- this:RegisterEvent("ZHANTUAN_LIST_DATA")
	-- this:RegisterEvent("OPEN_BUILD_INTRODUCE")
	-- this:RegisterEvent("GUILD_LEAGUE_INFO")
	-- this:RegisterEvent("GUILD_SHOW_ENEMYLIST")
	-- this:RegisterEvent("OPEN_GUILD_GIFT")
end -- end func NewBangHuiBZTX_Candidate_PreLoad()

function NewBangHuiBZTX_Candidate_OnLoad()
    NewBangHuiBZTX_Candidate_UnifiedPosition = NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition")
    
    -- 初始化控件
    NewBangHuiBZTX_Candidate_InitCtril()
end -- end func NewBangHuiBZTX_Candidate_OnLoad()

function NewBangHuiBZTX_Candidate_OnEvent(event)
    -- if event == "TCITYWARLIMIT_OPENCANDIDATE" then
    --     if (Player:GetData("TCWLSvrOpenFlag") < 0) then
    --         PushDebugMessage("#{GCQH_240429_161}")
    --         return
    --     elseif (Player:GetData("TCWLSvrOpenFlag") == 0) then
    --         PushDebugMessage("#{GCQH_240429_154}")
    --         return
    --     end

    --     --NewBangHuiBZTX_Candidate_On_ResetPos()

    --     local selfGuildClanUnionPos = Variable:GetVariable("SelfGuildClanUnionPos")
    --     if (selfGuildClanUnionPos ~= nil) then
    --         NewBangHuiBZTX_Candidate_Frame:SetProperty("UnifiedPosition", selfGuildClanUnionPos)
    --     end

    --     -- 默认打开显示本帮成员页签内容
    --     NewBangHuiBZTX_Candidate_InitPlayerListTab(NewBangHuiBZTX_Candidate_TabType.default)
    --     NewBangHuiBZTX_Candidate_PlayerListInitFlag = 0
    --     NewBangHuiBZTX_Candidate_InitPlayerNum()

    --     -- 每次打开UI都去请求一下最新的帮会成员列表数据
    --     NewBangHuiBZTX_Candidate_DoRefreshAll()

    --     local szName = Guild:GetMyGuildName("Name")
    --     local title = ScriptGlobal_Format("#{BHJM_140520_01}", szName)
    --     NewBangHuiBZTX_Candidate_PageHeader:SetText(title)

    --     modeText = ScriptGlobal_Format("#{GCQH_240429_42}", " ")
    --     NewBangHuiBZTX_Candidate_InfoText:SetText(modeText)

    --     -- 更新参与资格成员数量计数显示信息
    --     NewBangHuiBZTX_Candidate_UpdateMemberAssignedInfo()
    --     -- 更新帮会成员计数显示信息
    --     NewBangHuiBZTX_Candidate_UpdateMemberInfo()
    --     -- 更新助战玩家计数显示信息
    --     NewBangHuiBZTX_Candidate_UpdateAssistPlayerInfo()

    --     -- 设置排序模式默认选项
    --     if (NewBangHuiBZTX_Candidate_MemberSortMode <= 0) then
    --         NewBangHuiBZTX_Candidate_SearchMode:SetCurrentSelect(0)
    --         NewBangHuiBZTX_Candidate_MemberSortMode = 1
    --         Guild:PrepareMembersInfomation(NewBangHuiBZTX_Candidate_MemberSortMode)
    --     else
    --         NewBangHuiBZTX_Candidate_SearchMode:SetCurrentSelect(NewBangHuiBZTX_Candidate_MemberSortMode - 1)
    --         Guild:PrepareMembersInfomation(NewBangHuiBZTX_Candidate_MemberSortMode)
    --     end
    --     -- 设置左侧霸者天下按钮选中状态
    --     NewBangHuiBZTX_Candidate_BZTX:SetCheck(1)

    --     NewBangHuiBZTX_Candidate_Changed = 0

    --     NewBangHuiBZTX_Candidate_Show()
    -- elseif event == "TCITYWARLIMIT_ASSIGNCONFIRMRESULT" then
    --     -- 一键分配确认结果返回
    --     NewBangHuiBZTX_Candidate_ConfirmResult_Assign(tonumber(arg0))
    -- elseif event == "TCITYWARLIMIT_CANCELCONFIRMRESULT" then
    --     -- 一键取消确认结果返回
    --     NewBangHuiBZTX_Candidate_ConfirmResult_AssignCancel(tonumber(arg0))
    -- elseif event == "TCITYWARLIMIT_SAVECONFIRMRESULT" then
    --     -- 保存确认结果返回
    --     NewBangHuiBZTX_Candidate_ConfirmResult_Save(tonumber(arg0))
    -- elseif event == "TCITYWARLIMIT_REFRESHCONFIRMRESULT" then
    --     -- 分配结果未保存直接刷新确认结果返回
    --     NewBangHuiBZTX_Candidate_ConfirmResult_Refresh(tonumber(arg0))
    -- elseif event == "TCITYWARLIMIT_EXITCONFIRMRESULT" then
    --     -- 分配结果未保存直接关闭确认结果返回
    --     NewBangHuiBZTX_Candidate_ConfirmResult_Exit(tonumber(arg0), tonumber(arg1))
    -- elseif event == "TCITYWARLIMIT_OPERATERESULT" then
    --     -- 服务器返回帮会成员参赛资格分配操作的结果
    --     NewBangHuiBZTX_Candidate_DealOperateResult(tonumber(arg0))
    -- elseif event == "TCITYWARLIMIT_ESCCLOSE" then
    --     -- esc关闭
    --     NewBangHuiBZTX_Candidate_Hide(1)
    -- elseif event == "TCITYWARLIMIT_REMOVEASSISTCONFIRMRESULT" then
    --     -- 移除助战玩家二次确认返回结果
    --     NewBangHuiBZTX_Candidate_ConfirmResult_RemoveAssistPlayer(tonumber(arg0), tonumber(arg1), tonumber(arg2))
    -- elseif event == "TCITYWARLIMIT_MYSELFASSISTDATA" then
    --     -- 玩家自己的助战信息
    --     NewBangHuiBZTX_Candidate_UpdateMyselfAssistInfo()
    -- elseif event == "TCITYWARLIMIT_CANCELASSISTCONFIRMRESULT" then
    --     -- 玩家退出助战二次确认返回结果
    --     local result = tonumber(arg0)
    --     if (result > 0) then
    --         NewBangHuiBZTX_Candidate_LeaveBtnClicked(0)
    --     end
    -- elseif event == "TCITYWARLIMIT_UPDATEREDPOINTTIPS" then
    --     -- 更新小红点
    --     NewBangHuiBZTX_Candidate_UpdateRedPointTips()
    -- elseif event == "GUILD_MEMBERINFO_BZTX" then
    --     -- 服务器同步下来的帮会成员列表
    --     NewBangHuiBZTX_Candidate_TCWLServerOpenFlag = tonumber(arg0)
    --     NewBangHuiBZTX_Candidate_TCWLOpenWeekFlag = tonumber(arg1)
    --     NewBangHuiBZTX_Candidate_CurWeekCount = tonumber(arg2)
    --     NewBangHuiBZTX_Candidate_MaxPlayerCount = tonumber(arg3)

    --     -- 设置排序模式默认选项
    --     if (NewBangHuiBZTX_Candidate_MemberSortMode <= 0) then
    --         NewBangHuiBZTX_Candidate_SearchMode:SetCurrentSelect(0)
    --         NewBangHuiBZTX_Candidate_MemberSortMode = 1
    --         Guild:PrepareMembersInfomation(NewBangHuiBZTX_Candidate_MemberSortMode)
    --     else
    --         NewBangHuiBZTX_Candidate_SearchMode:SetCurrentSelect(NewBangHuiBZTX_Candidate_MemberSortMode - 1)
    --         Guild:PrepareMembersInfomation(NewBangHuiBZTX_Candidate_MemberSortMode)
    --     end

    --     -- 更新成员列表
    --     NewBangHuiBZTX_Candidate_UpdateGuildMemberList()
    -- elseif event == "GUILD_ASSISTPLAYERINFO_BZTX" then
    --     -- 服务器同步下来的助战玩家列表
    --     NewBangHuiBZTX_Candidate_TCWLServerOpenFlag = tonumber(arg0)
    --     NewBangHuiBZTX_Candidate_TCWLOpenWeekFlag = tonumber(arg1)
    --     NewBangHuiBZTX_Candidate_CurWeekCount = tonumber(arg2)

    --     NewBangHuiBZTX_Candidate_UpdateAssistPlayerList()
	-- elseif event == "VIEW_RESOLUTION_CHANGED" then
	-- 	NewBangHuiBZTX_Candidate_On_ResetPos()
	-- elseif event == "ADJEST_UI_POS" then
	-- 	NewBangHuiBZTX_Candidate_On_ResetPos()
	-- elseif event == "HIDE_ON_SCENE_TRANSED" then
    --     NewBangHuiBZTX_Candidate_Hide(0)
    -- elseif event == "GUILD_BIDDING_SHOWLIST" then
    --     NewBangHuiBZTX_Candidate_Hide(0)
    -- elseif event == "GUILD_SHOW_MEMBERINFO" then
    --     NewBangHuiBZTX_Candidate_Hide(0)
    -- elseif event == "GUILD_SHOW_DETAILINFO" then
    --     NewBangHuiBZTX_Candidate_Hide(0)
    -- elseif event == "ZHANTUAN_LIST_DATA" then
    --     NewBangHuiBZTX_Candidate_Hide(0)
    -- elseif event == "OPEN_BUILD_INTRODUCE" then
    --     NewBangHuiBZTX_Candidate_Hide(0)
    -- elseif event == "GUILD_LEAGUE_INFO" then
    --     NewBangHuiBZTX_Candidate_Hide(0)
    -- elseif event == "GUILD_SHOW_ENEMYLIST" then
    --     NewBangHuiBZTX_Candidate_Hide(0)
    -- elseif event == "OPEN_GUILD_GIFT" then
    --     NewBangHuiBZTX_Candidate_Hide(0)
	-- end
end -- end func NewBangHuiBZTX_Candidate_OnEvent()

function NewBangHuiBZTX_Candidate_On_ResetPos()
    NewBangHuiBZTX_Candidate_Frame:SetProperty("UnifiedPosition", NewBangHuiBZTX_Candidate_UnifiedPosition)
end -- end func NewBangHuiBZTX_Candidate_On_ResetPos()

function NewBangHuiBZTX_Candidate_Show()
    -- 更新小红点
    NewBangHuiBZTX_Candidate_UpdateRedPointTips()

    this:Show()
end -- end func NewBangHuiBZTX_Candidate_Show()

function NewBangHuiBZTX_Candidate_Hide(needConfirm)
    if (needConfirm ~= nil and needConfirm > 0) then
        if (NewBangHuiBZTX_Candidate_Changed > 0) then
            -- 二次确认
            PushEvent("TCITYWARLIMIT_EXITCONFIRM", NewBangHuiBZTX_Candidate_ExitType.close)
        else
            this:Hide()
        end
    else
        this:Hide()
    end
end -- end func NewBangHuiBZTX_Candidate_Hide()

function NewBangHuiBZTX_Candidate_UpdateRedPointTips()
    -- 霸者天下小红点
    local bztxApplyNum = DataPool:TCWLGetAssistApplyNum()
    local bztxIsInTime = NewBangHuiBZTX_Candidate_Check_AssistEnrollTime()
    if (bztxIsInTime > 0) then
        if (bztxApplyNum <= 0) then
            NewBangHuiBZTX_Candidate_BZTX_Tips:Hide()
            NewBangHuiBZTX_Candidate_HelpPeopleBtn_Tips:Hide()
        else
            local isChiefOrAss = Guild:IsChieforAss()
            if (isChiefOrAss ~= 1) then
                NewBangHuiBZTX_Candidate_BZTX_Tips:Hide()
                NewBangHuiBZTX_Candidate_HelpPeopleBtn_Tips:Hide()
            else
                NewBangHuiBZTX_Candidate_BZTX_Tips:Show()
                NewBangHuiBZTX_Candidate_HelpPeopleBtn_Tips:Show()
            end
        end
    else
        NewBangHuiBZTX_Candidate_BZTX_Tips:Hide()
        NewBangHuiBZTX_Candidate_HelpPeopleBtn_Tips:Hide()
    end
end -- end func NewBangHuiBZTX_Candidate_UpdateRedPointTips()

--*************************************************************************************************
--*************************************************************************************************
--*************************************************************************************************
--*************************************************************************************************

--*****************************************************************************
-- 成员管理
--*****************************************************************************
function NewBangHuiBZTX_Candidate_Hygl_Clicked(needConfirm)
    if (needConfirm == nil or needConfirm > 0) then
        if (NewBangHuiBZTX_Candidate_Changed > 0) then
            -- 二次确认
            PushEvent("TCITYWARLIMIT_EXITCONFIRM", NewBangHuiBZTX_Candidate_ExitType.cygl)
        else
            Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
            Guild:ToggleGuildDetailInfo()
        end
    else
        Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
        Guild:ToggleGuildDetailInfo()
    end
end -- end func NewBangHuiBZTX_Candidate_Hygl_Clicked()

--*****************************************************************************
-- 帮会信息
--*****************************************************************************
function NewBangHuiBZTX_Candidate_Bhxx_Clicked(needConfirm)
    if (needConfirm == nil or needConfirm > 0) then
        if (NewBangHuiBZTX_Candidate_Changed > 0) then
            -- 二次确认
            PushEvent("TCITYWARLIMIT_EXITCONFIRM", NewBangHuiBZTX_Candidate_ExitType.bhxx)
        else
            Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
            Guild:AskGuildDetailInfo()
            Guild:CloseKickGuildBox()
        end
    else
        Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
        Guild:AskGuildDetailInfo()
        Guild:CloseKickGuildBox()
    end
end -- end func NewBangHuiBZTX_Candidate_Bhxx_Clicked()

--*****************************************************************************
-- 帮会同盟
--*****************************************************************************
function NewBangHuiBZTX_Candidate_Tmxx_Clicked(needConfirm)
    if KVKInterface:IsInKVKServer() == 1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
		PushDebugMessage("#{KVKBH_140124_66}")
		return
	end
    local id=Player:GetData("GUILDLEAGUE")
	if id == nil or id < 0 then
        PushDebugMessage( "#{KVKSL_110628_305}" )
        return
    end
    
    if (needConfirm == nil or needConfirm > 0) then
        if (NewBangHuiBZTX_Candidate_Changed > 0) then
            -- 二次确认
            PushEvent("TCITYWARLIMIT_EXITCONFIRM", NewBangHuiBZTX_Candidate_ExitType.bhtm)
        else
            Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
            GuildLeague:ShowInfoWindow()
        end
    else
        Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
        GuildLeague:ShowInfoWindow()
    end
end -- end func NewBangHuiBZTX_Candidate_Tmxx_Clicked()

--*****************************************************************************
-- 帮会宣战
--*****************************************************************************
function NewBangHuiBZTX_Candidate_Bhxz_Clicked(needConfirm)
    if (needConfirm == nil or needConfirm > 0) then
        if (NewBangHuiBZTX_Candidate_Changed > 0) then
            -- 二次确认
            PushEvent("TCITYWARLIMIT_EXITCONFIRM", NewBangHuiBZTX_Candidate_ExitType.bhxz)
        else
            Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
            City:OpenNewGuildWarDlg()
            Guild:CloseKickGuildBox()
        end
    else
        Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
        City:OpenNewGuildWarDlg()
        Guild:CloseKickGuildBox()
    end
end -- end func NewBangHuiBZTX_Candidate_Bhxz_Clicked()

--*****************************************************************************
-- 建筑介绍
--*****************************************************************************
function NewBangHuiBZTX_Candidate_JZWJS_Clicked(needConfirm)
    if (needConfirm == nil or needConfirm > 0) then
        if (NewBangHuiBZTX_Candidate_Changed > 0) then
            -- 二次确认
            PushEvent("TCITYWARLIMIT_EXITCONFIRM", NewBangHuiBZTX_Candidate_ExitType.bhjz)
        else
            Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
            Guild:ShowCityBuildIntroduce()
        end
    else
        Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
        Guild:ShowCityBuildIntroduce()
    end
end -- end func NewBangHuiBZTX_Candidate_JZWJS_Clicked()

--*****************************************************************************
-- 帮会红包
--*****************************************************************************
function NewBangHuiBZTX_Candidate_HB_Clicked(needConfirm)
    if (needConfirm == nil or needConfirm > 0) then
        if (NewBangHuiBZTX_Candidate_Changed > 0) then
            -- 二次确认
            PushEvent("TCITYWARLIMIT_EXITCONFIRM", NewBangHuiBZTX_Candidate_ExitType.bhhb)
        else
            Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
            Guild:OpentGuildGiftUI()
        end
    else
        Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
        Guild:OpentGuildGiftUI()
    end
end -- end func NewBangHuiBZTX_Candidate_HB_Clicked()

--*****************************************************************************
-- 浴血战况
--*****************************************************************************
function NewBangHuiBZTX_Candidate_YXSS_Clicked(needConfirm)
    if (needConfirm == nil or needConfirm > 0) then
        if (NewBangHuiBZTX_Candidate_Changed > 0) then
            -- 二次确认
            PushEvent("TCITYWARLIMIT_EXITCONFIRM", NewBangHuiBZTX_Candidate_ExitType.yxzk)
        else
            Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
            Guild:AskGuildYXSSInfo()
        end
    else
        Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
        Guild:AskGuildYXSSInfo()
    end
end -- end func NewBangHuiBZTX_Candidate_YXSS_Clicked()

--*****************************************************************************
-- 帮会拍卖
--*****************************************************************************
function NewBangHuiBZTX_Candidate_Auction_Clicked(needConfirm)
    if GetSceneID() ~= 850 then
        PushDebugMessage("#{SCBHPM_20220815_02}")
        return
    end
        
    if Player:GetLevel() < 85 then
        PushDebugMessage("#{SCBHPM_20220815_03}")
        return
    end
        
    if( -1 == Player:GetData("GUILD")) then
        PushDebugMessage("#{SCBHPM_20220815_04}")
        return
    end

    if (needConfirm == nil or needConfirm > 0) then
        if (NewBangHuiBZTX_Candidate_Changed > 0) then
            -- 二次确认
            PushEvent("TCITYWARLIMIT_EXITCONFIRM", NewBangHuiBZTX_Candidate_ExitType.bhpm)
        else
            Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
            Guild:AskGuildBiddingInfo(0, 1, -1)
        end
    else
        Variable:SetVariable("SelfGuildClanUnionPos", NewBangHuiBZTX_Candidate_Frame:GetProperty("UnifiedPosition"), 1)
        Guild:AskGuildBiddingInfo(0, 1, -1)
    end
end -- end func NewBangHuiBZTX_Candidate_Auction_Clicked()

--*************************************************************************************************
--*************************************************************************************************
--*************************************************************************************************
--*************************************************************************************************

function NewBangHuiBZTX_Candidate_OnHiden()
    -- 通知助战申请列表一起关闭
    PushEvent("GUILD_CLOSEASSISTAPPLY_BZTX")
end -- end func NewBangHuiBZTX_Candidate_OnHiden()

function NewBangHuiBZTX_Candidate_CloseClicked()
    NewBangHuiBZTX_Candidate_Hide(1)
end -- end func NewBangHuiBZTX_Candidate_CloseClicked()

--*****************************************************************************
-- 霸者天下
--*****************************************************************************
function NewBangHuiBZTX_Candidate_BZTX_Clicked()
end -- end func NewBangHuiBZTX_Candidate_BZTX_Clicked()

--*****************************************************************************
-- 本帮成员页签按钮点击事件
--*****************************************************************************
function NewBangHuiBZTX_Candidate_PageBtn1_Clicked(needConfirm)
    if (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.guildmember) then
        return
    end

    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    if (needConfirm == nil or needConfirm > 0) then
        if (NewBangHuiBZTX_Candidate_Changed > 0) then
            -- 二次确认
            PushEvent("TCITYWARLIMIT_EXITCONFIRM", NewBangHuiBZTX_Candidate_ExitType.bztx_guildmember)
            return
        end
    end

    NewBangHuiBZTX_Candidate_InitPlayerListTab(NewBangHuiBZTX_Candidate_TabType.guildmember)

    -- 刷新帮会成员列表
    NewBangHuiBZTX_Candidate_UpdateGuildMemberList()
end -- end func NewBangHuiBZTX_Candidate_PageBtn1_Clicked()

--*****************************************************************************
-- 助战成员页签按钮点击事件
--*****************************************************************************
function NewBangHuiBZTX_Candidate_PageBtn2_Clicked(needConfirm)
    if (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.assistplayer) then
        return
    end

    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    if (needConfirm == nil or needConfirm > 0) then
        if (NewBangHuiBZTX_Candidate_Changed > 0) then
            -- 二次确认
            PushEvent("TCITYWARLIMIT_EXITCONFIRM", NewBangHuiBZTX_Candidate_ExitType.bztx_assistplayer)
            return
        end
    end

    NewBangHuiBZTX_Candidate_InitPlayerListTab(NewBangHuiBZTX_Candidate_TabType.assistplayer)

    -- 刷新助战玩家列表
    NewBangHuiBZTX_Candidate_UpdateAssistPlayerList()
end -- end func NewBangHuiBZTX_Candidate_PageBtn2_Clicked()

--*****************************************************************************
-- 成员排序事件
--*****************************************************************************
function NewBangHuiBZTX_Candidate_SearchMode_Changed()
    if (NewBangHuiBZTX_Candidate_PlayerListInitFlag <= 0) then
        return
    end

    local _, selectIdx = NewBangHuiBZTX_Candidate_SearchMode:GetCurrentSelect()
    NewBangHuiBZTX_Candidate_MemberSortMode = selectIdx

    -- 成员列表排序
    Guild:PrepareMembersInfomation(NewBangHuiBZTX_Candidate_MemberSortMode)

    -- 刷新成员列表
    NewBangHuiBZTX_Candidate_UpdateGuildMemberList()
end -- end func NewBangHuiBZTX_Candidate_SearchMode_Changed()

--*****************************************************************************
-- 定位查找按钮事件
--*****************************************************************************
function NewBangHuiBZTX_Candidate_Dingwei_Clicked()
    if (NewBangHuiBZTX_Candidate_PlayerListInitFlag <= 0) then
        return
    end

    local totalNum = Guild:GetMembersNum(4)
	local i = 0
	while i < totalNum do
		local guildIdx = Guild:GetShowMembersIdx(i)
		local guid = Guild:GetMembersInfo(guildIdx, "GUID")
        if (Player:GetGUID() == guid) then
			NewBangHuiBZTX_Candidate_List:SetScrollPosition4Index(i)
        end
		i = i + 1
    end -- end while
end -- end func NewBangHuiBZTX_Candidate_Dingwei_Clicked()

--*****************************************************************************
-- 一键分配名额按钮事件
--*****************************************************************************
function NewBangHuiBZTX_Candidate_OnekeyAssignClicked()
    if (NewBangHuiBZTX_Candidate_PlayerListInitFlag <= 0) then
        return
    end

    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    -- 是否帮主或副帮主
    local isChiefOrAss = Guild:IsChieforAss()
    if (isChiefOrAss ~= 1) then
        PushDebugMessage("#{GCQH_240429_78}")
        return
    end

    -- 是否在允许操作的时间内
    local isInTime = NewBangHuiBZTX_Candidate_Check_AssignForbiddenTime()
    if (isInTime <= 0) then
        PushDebugMessage("#{GCQH_240429_79}")
        return
    end

    -- 是否还有可分配的参与资格
    local totalPlayerNum = NewBangHuiBZTX_Candidate_AssignedMemberCount + NewBangHuiBZTX_Candidate_AssistPlayerNum
    if (totalPlayerNum >= NewBangHuiBZTX_Candidate_MaxPlayerCount) then
        PushDebugMessage("#{GCQH_240429_80}")
        return
    end

    -- 二次确认
    PushEvent("TCITYWARLIMIT_ASSIGNCONFIRM")
end -- end func NewBangHuiBZTX_Candidate_OnekeyAssignClicked()

--*****************************************************************************
-- 一键取消名额按钮事件
--*****************************************************************************
function NewBangHuiBZTX_Candidate_OnekeyCancelClicked()
    if (NewBangHuiBZTX_Candidate_PlayerListInitFlag <= 0) then
        return
    end
    if (NewBangHuiBZTX_Candidate_AssignedMemberCount <= 0) then
        return
    end

    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    -- 是否帮主或副帮主
    local isChiefOrAss = Guild:IsChieforAss()
    if (isChiefOrAss ~= 1) then
        PushDebugMessage("#{GCQH_240429_78}")
        return
    end

    -- 是否在允许操作的时间内
    local isInTime = NewBangHuiBZTX_Candidate_Check_AssignForbiddenTime()
    if (isInTime <= 0) then
        PushDebugMessage("#{GCQH_240429_87}")
        return
    end

    -- 二次确认
    PushEvent("TCITYWARLIMIT_CANCELCONFIRM")
end -- end func NewBangHuiBZTX_Candidate_OnekeyCancelClicked()

-- --*****************************************************************************
-- -- 一键邀请按钮事件
-- --*****************************************************************************
-- function NewBangHuiBZTX_Candidate_InviteClicked()
-- end -- end func NewBangHuiBZTX_Candidate_InviteClicked()

-- --*****************************************************************************
-- -- 成员对比按钮事件
-- --*****************************************************************************
-- function NewBangHuiBZTX_Candidate_CampareClicked()
-- end -- end func NewBangHuiBZTX_Candidate_CampareClicked()

--*****************************************************************************
-- 保存按钮事件
--*****************************************************************************
function NewBangHuiBZTX_Candidate_SaveClicked()
    if (NewBangHuiBZTX_Candidate_PlayerListInitFlag <= 0) then
        return
    end

    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    local ret = NewBangHuiBZTX_Candidate_DoSave()
    if (ret <= 0) then
        return
    end

    if (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.guildmember) then
        -- 请求帮会成员列表 重新刷一下UI
        Guild:AskGuildMembersInfo_BZTX()
    elseif (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.assistplayer) then
        -- 请求助战玩家列表 重新刷一下UI
        TCWL:AskAssistPlayerInfo(1)
    end
end -- end func NewBangHuiBZTX_Candidate_SaveClicked()

--*****************************************************************************
-- 刷新按钮事件
--*****************************************************************************
function NewBangHuiBZTX_Candidate_RefreshClicked()
    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    if (NewBangHuiBZTX_Candidate_Check_OpCD() <= 0) then
        -- 操作频繁 稍微再试
        PushDebugMessage("#{GCQH_240429_142}")
        return
    end
    NewBangHuiBZTX_Candidate_LastOpTime = DataPool:GetCurrentServerTime()

    if (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.guildmember) then
        -- 本帮成员
        NewBangHuiBZTX_Candidate_PlayerListInitFlag = 0

        NewBangHuiBZTX_Candidate_List:Clear()
        NewBangHuiBZTX_Candidate_ListItemNum = 0

        Guild:AskGuildMembersInfo_BZTX()
    elseif (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.assistplayer) then
        -- 助战玩家
        NewBangHuiBZTX_Candidate_PlayerListInitFlag = 0

        NewBangHuiBZTX_Candidate_List:Clear()
        NewBangHuiBZTX_Candidate_ListItemNum = 0

        TCWL:AskAssistPlayerInfo(1)
    end
end -- end func NewBangHuiBZTX_Candidate_RefreshClicked()

--*****************************************************************************
-- 参与资格点击事件
--*****************************************************************************
function NewBangHuiBZTX_Candidate_SelectClicked(guildIdx, ctrlIdx)
    if (NewBangHuiBZTX_Candidate_PlayerListInitFlag <= 0) then
        return
    end

    if (guildIdx == nil or guildIdx < 0) then
        return
    end
    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    -- 是否帮主或副帮主
    local isChiefOrAss = Guild:IsChieforAss()
    if (isChiefOrAss ~= 1) then
        local child = NewBangHuiBZTX_Candidate_List:GetListItemAt(ctrlIdx)
        if (child ~= nil) then
            local ctrlItem = child:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Select")
            if (ctrlItem ~= nil) then
                local joinFlagTemp = Guild:GetMembersInfo(guildIdx, "TCWLJoinFlagTemp")
                if (joinFlagTemp ~= nil) then
                    if (ctrlItem:GetCheck() > 0) then
                        if (joinFlagTemp <= 0) then
                            ctrlItem:SetCheck(0)
                        end
                    else
                        if (joinFlagTemp > 0) then
                            ctrlItem:SetCheck(1)
                        end
                    end
                end
            end
        end

        PushDebugMessage("#{GCQH_240429_78}")
        return
    end

    -- 是否在允许操作的时间内
    local isInTime = NewBangHuiBZTX_Candidate_Check_AssignForbiddenTime()
    if (isInTime <= 0) then
        local child = NewBangHuiBZTX_Candidate_List:GetListItemAt(ctrlIdx)
        if (child ~= nil) then
            local ctrlItem = child:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Select")
            if (ctrlItem ~= nil) then
                local joinFlagTemp = Guild:GetMembersInfo(guildIdx, "TCWLJoinFlagTemp")
                if (joinFlagTemp ~= nil) then
                    if (ctrlItem:GetCheck() > 0) then
                        if (joinFlagTemp <= 0) then
                            ctrlItem:SetCheck(0)
                        end
                    else
                        if (joinFlagTemp > 0) then
                            ctrlItem:SetCheck(1)
                        end
                    end
                end
            end
        end

        PushDebugMessage("#{GCQH_240429_87}")
        return
    end

    -- 是否已有助战帮会
    local assistWeekCount = Guild:GetMembersInfo(guildIdx, "TCWLAssistWeek")
    local assistGuildId = Guild:GetMembersInfo(guildIdx, "TCWLAssistGuildId")
    if (assistWeekCount == NewBangHuiBZTX_Candidate_CurWeekCount) then
        -- 玩家已有助战信息了
        PushDebugMessage("#{GCQH_240429_203}")
        local child = NewBangHuiBZTX_Candidate_List:GetListItemAt(ctrlIdx)
        if (child ~= nil) then
            local ctrlItem = child:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Select")
            if (ctrlItem ~= nil) then
                if (ctrlItem:GetCheck() > 0) then
                    ctrlItem:SetCheck(0)
                end
            end
        end
        return
    end

    local totalPlayerNum = NewBangHuiBZTX_Candidate_AssignedMemberCount + NewBangHuiBZTX_Candidate_AssistPlayerNum
    local child = NewBangHuiBZTX_Candidate_List:GetListItemAt(ctrlIdx)
    if (child ~= nil) then
        local ctrlItem = child:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Select")
        if (ctrlItem ~= nil) then
            if (ctrlItem:GetCheck() > 0) then
                if (totalPlayerNum >= NewBangHuiBZTX_Candidate_MaxPlayerCount) then
                    ctrlItem:SetCheck(0)

                    PushDebugMessage("#{GCQH_240429_94}")
                    return
                end

                -- 防止快速点击控件连续触发事件导致计数不准确 如果已经处于选中状态就直接返回吧
                local joinFlagTemp = Guild:GetMembersInfo(guildIdx, "TCWLJoinFlagTemp")
                if (joinFlagTemp == nil or joinFlagTemp <= 0) then
                    -- 设置参战标记
                    local retGroup = NewBangHuiBZTX_Candidate_SetMemberJoinFlag(guildIdx, 1)
                    -- 更新分组显示
                    NewBangHuiBZTX_Candidate_UpdateGroupInfo(guildIdx, child, retGroup)
                    -- 更新分组切换按钮tooltip
                    NewBangHuiBZTX_Candidate_UpdateGroupChangeBtnToolTip()

                    ctrlItem:SetToolTip("#{GCQH_240429_123}")

                    PushDebugMessage("#{GCQH_240429_95}")
                end
            else
                -- 防止快速点击控件连续触发事件导致计数不准确 如果已经是非选中状态就直接返回吧
                local joinFlagTemp = Guild:GetMembersInfo(guildIdx, "TCWLJoinFlagTemp")
                if (joinFlagTemp == nil or joinFlagTemp > 0) then
                    -- 取消参战标记
                    local retGroup = NewBangHuiBZTX_Candidate_SetMemberJoinFlag(guildIdx, 0)
                    -- 更新分组显示
                    NewBangHuiBZTX_Candidate_UpdateGroupInfo(guildIdx, child, retGroup)
                    -- 更新分组切换按钮tooltip
                    NewBangHuiBZTX_Candidate_UpdateGroupChangeBtnToolTip()

                    ctrlItem:SetToolTip("#{GCQH_240429_91}")

                    PushDebugMessage("#{GCQH_240429_93}")
                end
            end

            -- 更新参与资格成员数量计数显示信息
            NewBangHuiBZTX_Candidate_UpdateMemberAssignedInfo()
        end
    end

    NewBangHuiBZTX_Candidate_Changed = 1
end -- end func NewBangHuiBZTX_Candidate_SelectClicked()

--*****************************************************************************
-- 编队切换按钮事件
--*****************************************************************************
function NewBangHuiBZTX_Candidate_ListItem_ChangeClicked(guildIdx, ctrlIdx)
    if (NewBangHuiBZTX_Candidate_PlayerListInitFlag <= 0) then
        return
    end

    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    -- 是否帮主或副帮主
    local isChiefOrAss = Guild:IsChieforAss()
    if (isChiefOrAss ~= 1) then
        PushDebugMessage("#{GCQH_240429_185}")
        return
    end

    if (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.guildmember) then
        -- 是否有参赛资格
        local joinFlagTemp = Guild:GetMembersInfo(guildIdx, "TCWLJoinFlagTemp")
        if (joinFlagTemp == nil or joinFlagTemp <= 0) then
            PushDebugMessage("#{GCQH_240429_186}")
            return
        end
    end

    local curGroup = 0
    if (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.guildmember) then
        curGroup = Guild:GetMembersInfo(guildIdx, "TCWLGroupTemp")
    elseif (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.assistplayer) then
        curGroup = TCWL:GetAssistPlayerInfo(guildIdx, "grouptemp")
    else
        return
    end

    local groupRet = NewBangHuiBZTX_Candidate_ChangePlayerAssistGroup(guildIdx)
    if (curGroup ~= groupRet) then
        -- 更新分组显示
        local child = NewBangHuiBZTX_Candidate_List:GetListItemAt(ctrlIdx)
        if (child ~= nil) then
            NewBangHuiBZTX_Candidate_UpdateGroupInfo(guildIdx, child, groupRet)
        end

        -- 更新分组切换按钮tooltip
        NewBangHuiBZTX_Candidate_UpdateGroupChangeBtnToolTip()

        NewBangHuiBZTX_Candidate_Changed = 1
    end
end -- end func NewBangHuiBZTX_Candidate_ListItem_ChangeClicked()

--*****************************************************************************
-- 移除助战按钮事件
--*****************************************************************************
function NewBangHuiBZTX_Candidate_ListItem_MoveBtnClicked(guildIdx, ctrlIdx)
    if (NewBangHuiBZTX_Candidate_PlayerListInitFlag <= 0) then
        return
    end

    if (guildIdx == nil or guildIdx < 0) then
        return
    end
    if (ctrlIdx == nil or ctrlIdx < 0) then
        return
    end

    if (NewBangHuiBZTX_Candidate_CurPlayerListTab ~= NewBangHuiBZTX_Candidate_TabType.assistplayer) then
        return
    end

    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    if (NewBangHuiBZTX_Candidate_Check_AssistOpCD() <= 0) then
        -- 操作频繁 稍微再试
        PushDebugMessage("#{GCQH_240429_142}")
        return
    end

    -- 是否帮主或副帮主
    local isChiefOrAss = Guild:IsChieforAss()
    if (isChiefOrAss ~= 1) then
        PushDebugMessage("#{GCQH_240429_196}")
        return
    end

    -- 是否助战申请操作时间内
    local isInTime = NewBangHuiBZTX_Candidate_Check_AssistEnrollTime()
    if (isInTime <= 0) then
        PushDebugMessage("#{GCQH_240429_197}")
        return
    end

    -- 缓存一下要移除的玩家信息 用于二次确认返回后校验
    local playerGUID = TCWL:GetAssistPlayerInfo(guildIdx, "guid")
    if (NewBangHuiBZTX_Candidate_RemoveAssistCache == nil) then
        NewBangHuiBZTX_Candidate_RemoveAssistCache = {}
    end
    NewBangHuiBZTX_Candidate_RemoveAssistCache[guildIdx] = playerGUID

    -- 置灰玩家对应的移除按钮 避免玩家重复点击
    local ctrlChild = NewBangHuiBZTX_Candidate_List:GetListItemAt(ctrlIdx)
    if (ctrlChild ~= nil) then
        local btnRemove = ctrlChild:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_MoveBtn")
        if (btnRemove ~= nil) then
            btnRemove:Disable()
        end
    end

    -- 重置CD
    NewBangHuiBZTX_Candidate_LastAssistOpTime = DataPool:GetCurrentServerTime()

    -- 二次确认
    PushEvent("TCITYWARLIMIT_REMOVEASSISTCONFIRM", guildIdx, ctrlIdx)
end -- end func NewBangHuiBZTX_Candidate_ListItem_MoveBtnClicked()

--*****************************************************************************
-- 助战申请按钮（打开助战申请列表）事件
--*****************************************************************************
function NewBangHuiBZTX_Candidate_HelpPeopleBtnClicked()
    if (NewBangHuiBZTX_Candidate_Check_OpCD() <= 0) then
        -- 操作频繁 稍微再试
        PushDebugMessage("#{GCQH_240429_142}")
        return
    end

    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_161}")
        return
    elseif (Player:GetData("TCWLSvrOpenFlag") == 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    -- 是否帮主或副帮主
    local isChiefOrAss = Guild:IsChieforAss()
    if (isChiefOrAss ~= 1) then
        PushDebugMessage("#{GCQH_240429_274}")
        return
    end

    -- 是否在允许操作的时间内
    local isInTime = NewBangHuiBZTX_Candidate_Check_AssistEnrollTime()
    if (isInTime <= 0) then
        PushDebugMessage("#{GCQH_240429_197}")
        return
    end

    -- 重置CD时间
    NewBangHuiBZTX_Candidate_LastOpTime = DataPool:GetCurrentServerTime()

    -- 请求助战申请列表
    TCWL:AskAssistApplyInfo()
end -- end func NewBangHuiBZTX_Candidate_HelpPeopleBtnClicked()

--*****************************************************************************
-- 离开助战帮会/申请助战按钮事件
--*****************************************************************************
function NewBangHuiBZTX_Candidate_LeaveBtnClicked(isNeedConfirm)
    -- 是否开启天外
    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_161}")
        return
    elseif (Player:GetData("TCWLSvrOpenFlag") == 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    if (isNeedConfirm == nil or isNeedConfirm > 0) then
        if (NewBangHuiBZTX_Candidate_Check_AssistOpCD() <= 0) then
            -- 操作频繁 稍微再试
            PushDebugMessage("#{GCQH_240429_142}")
            return
        end
        -- 重置CD
        NewBangHuiBZTX_Candidate_LastAssistOpTime = DataPool:GetCurrentServerTime()
    end

    local assistGuildId = TCWL:GetMyselfAssistInfo("assistguildid")
    if (assistGuildId >= 0) then
        -- 玩家有助战帮会 当前是“离开助战帮会”按钮
        if (isNeedConfirm == nil or isNeedConfirm > 0) then
            -- 弹二次确认
            PushEvent("TCITYWARLIMIT_CANCELASSISTCONFIRM")
            return
        end

        -- 取消自己的助战
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name("CCallBack_CancelAssist")
            Set_XSCRIPT_ScriptID(998224)
            Set_XSCRIPT_ParamCount(0)
        Send_XSCRIPT()
    else
        -- 玩家没有助战帮会 当前是“申请助战帮会”按钮
        -- 是否助战申请时间
        local isInTime = NewBangHuiBZTX_Candidate_Check_AssistEnrollTime()
        if (isInTime <= 0) then
            PushDebugMessage("#{GCQH_240429_173}")
            return
        end

        -- 等级
        if Player:GetLevel() < 85 then
            PushDebugMessage("#{GCQH_240429_168}")
            return
        end

        -- 打开报名帮会列表UI
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name("CCallBack_AskEnrollGuildList")
            Set_XSCRIPT_ScriptID(998224)
            Set_XSCRIPT_ParamCount(0)
        Send_XSCRIPT()
    end
end -- end func NewBangHuiBZTX_Candidate_LeaveBtnClicked()

--*************************************************************************************************
--*************************************************************************************************
--*************************************************************************************************
--*************************************************************************************************

--*****************************************************************************
-- 操作CD检查
--*****************************************************************************
function NewBangHuiBZTX_Candidate_Check_OpCD()
    if (NewBangHuiBZTX_Candidate_IsDebug > 0) then
        return 1
    end

    local curTime = DataPool:GetCurrentServerTime()
    local diffTime = curTime - NewBangHuiBZTX_Candidate_LastOpTime
    if (NewBangHuiBZTX_Candidate_OpCDTime > 0) then
        if (diffTime >= 0 and diffTime < NewBangHuiBZTX_Candidate_OpCDTime) then
            return -1
        end
    end

    return 1
end -- end func NewBangHuiBZTX_Candidate_Check_OpCD()

function NewBangHuiBZTX_Candidate_Check_AssistOpCD()
    if (NewBangHuiBZTX_Candidate_IsDebug > 0) then
        return 1
    end

    local curTime = DataPool:GetCurrentServerTime()
    local diffTime = curTime - NewBangHuiBZTX_Candidate_LastAssistOpTime
    if (NewBangHuiBZTX_Candidate_RemoveAssistCDTime > 0) then
        if (diffTime >= 0 and diffTime < NewBangHuiBZTX_Candidate_RemoveAssistCDTime) then
            return -1
        end
    end

    return 1
end -- end func NewBangHuiBZTX_Candidate_Check_AssistOpCD()

--*****************************************************************************
-- 是否在禁止参与资格分配的时间内
--*****************************************************************************
function NewBangHuiBZTX_Candidate_Check_AssignForbiddenTime()
    if (NewBangHuiBZTX_Candidate_IsDebug > 0) then
        return 1
    end

    local curWeekDay = DataPool:GetServerWeekDay()
    if (curWeekDay == NewBangHuiBZTX_Candidate_AssignForbiddenTime.weekday) then
        local curMinTime = DataPool:GetServerMinuteTime()
        local beginTime = NewBangHuiBZTX_Candidate_AssignForbiddenTime.mintime[1]
        local endTime = NewBangHuiBZTX_Candidate_AssignForbiddenTime.mintime[2]
        if (curMinTime >=beginTime and curMinTime <= endTime) then
            return -1
        end
    end

    return 1
end -- end func NewBangHuiBZTX_Candidate_Check_AssignForbiddenTime()

--*****************************************************************************
-- 是否在助战申请时间内
--*****************************************************************************
function NewBangHuiBZTX_Candidate_Check_AssistEnrollTime()
    if (NewBangHuiBZTX_Candidate_IsDebug > 0) then
        return 1
    end

	local curWeekDay = DataPool:GetServerWeekDay()
	if (curWeekDay == 0) then
		-- 星期天特殊处理一下
		curWeekDay = 7
	end

	local beginDay = NewBangHuiBZTX_Candidate_AssistOpTime[1].weekday
	local beginTime = NewBangHuiBZTX_Candidate_AssistOpTime[1].begintime
	local endDay = NewBangHuiBZTX_Candidate_AssistOpTime[2].weekday
	local endTime = NewBangHuiBZTX_Candidate_AssistOpTime[2].endtime

	if (curWeekDay >= beginDay and curWeekDay <= endDay) then
		local curMinTime = DataPool:GetServerMinuteTime()
		if (curWeekDay == beginDay) then
			if (curMinTime >= beginTime) then
				return 1
			else
				return -1
			end
		elseif (curWeekDay == endDay) then
			if (curMinTime < endTime) then
				return 1
			else
				return -1
			end
		else
			return 1
		end
	end

    return -1
end -- end func NewBangHuiBZTX_Candidate_Check_AssistEnrollTime()

--*****************************************************************************
-- 控件初始化
--*****************************************************************************
function NewBangHuiBZTX_Candidate_InitCtril()
    NewBangHuiBZTX_Candidate_SearchMode:ResetList()
    NewBangHuiBZTX_Candidate_SearchMode:AddTextItem("#{GCQH_240429_59}", 1)			-- 默认
    NewBangHuiBZTX_Candidate_SearchMode:AddTextItem("#{GCQH_240429_288}", 17)		-- 三城参与资格
    NewBangHuiBZTX_Candidate_SearchMode:AddTextItem("#{GCQH_240429_68}", 10)		-- 装备评分从高到低
    NewBangHuiBZTX_Candidate_SearchMode:AddTextItem("#{GCQH_240429_69}", 11)		-- 装备评分从低到高
    NewBangHuiBZTX_Candidate_SearchMode:AddTextItem("#{GCQH_240429_64}", 6)			-- 等级从高到低
    NewBangHuiBZTX_Candidate_SearchMode:AddTextItem("#{GCQH_240429_65}", 7)			-- 等级从低到高
    NewBangHuiBZTX_Candidate_SearchMode:AddTextItem("#{GCQH_240429_70}", 16)		-- 门派顺序
    --[[
    NewBangHuiBZTX_Candidate_SearchMode:AddTextItem("#{GCQH_240429_62}", 4)			-- 贡献度从大到小
	NewBangHuiBZTX_Candidate_SearchMode:AddTextItem("#{GCQH_240429_63}", 5)			-- 贡献度从小到大
    NewBangHuiBZTX_Candidate_SearchMode:AddTextItem("#{GCQH_240429_66}", 8)		    -- 周贡献度从大到小
	NewBangHuiBZTX_Candidate_SearchMode:AddTextItem("#{GCQH_240429_67}", 9)		    -- 周贡献度从小到大
	NewBangHuiBZTX_Candidate_SearchMode:AddTextItem("#{GCQH_240429_60}", 2)			-- 离线时间从近至远
    NewBangHuiBZTX_Candidate_SearchMode:AddTextItem("#{GCQH_240429_61}", 3)			-- 离线时间从远到近
    --]]
	NewBangHuiBZTX_Candidate_SearchMode:SetCurrentSelect(0)
end -- end func NewBangHuiBZTX_Candidate_InitCtril()

--*****************************************************************************
-- 初始化页签
--*****************************************************************************
function NewBangHuiBZTX_Candidate_InitPlayerListTab(tabType)
    if (tabType == NewBangHuiBZTX_Candidate_TabType.default) then
        -- 默认（显示本帮成员页签）
        NewBangHuiBZTX_Candidate_OnekeyAssign:Show()        -- 一键分配按钮
        NewBangHuiBZTX_Candidate_OnekeyCancel:Show()        -- 一键取消按钮
        NewBangHuiBZTX_Candidate_Invite:Show()              -- 一键邀请按钮
        NewBangHuiBZTX_Candidate_Campare:Show()             -- 成员对比按钮
        NewBangHuiBZTX_Candidate_Save:Show()                -- 保存按钮
        NewBangHuiBZTX_Candidate_Refresh:Show()             -- 刷新按钮
        NewBangHuiBZTX_Candidate_Paixu_Frame:Show()         -- 排序
        NewBangHuiBZTX_Candidate_Dingwei:Show()             -- 定位

        NewBangHuiBZTX_Candidate_PageBtn1:SetCheck(1)       -- 本帮成员
        NewBangHuiBZTX_Candidate_PageBtn2:SetCheck(0)       -- 助战成员

        NewBangHuiBZTX_Candidate_My_Text:Hide()
        NewBangHuiBZTX_Candidate_LeaveBtn:Hide()
        NewBangHuiBZTX_Candidate_HelpPeople:Hide()

        NewBangHuiBZTX_Candidate_RemoveAssistCache = nil

        NewBangHuiBZTX_Candidate_CurPlayerListTab = NewBangHuiBZTX_Candidate_TabType.guildmember
    elseif (tabType == NewBangHuiBZTX_Candidate_TabType.guildmember) then
        -- 本帮成员
        NewBangHuiBZTX_Candidate_OnekeyAssign:Show()        -- 一键分配按钮
        NewBangHuiBZTX_Candidate_OnekeyCancel:Show()        -- 一键取消按钮
        NewBangHuiBZTX_Candidate_Invite:Show()              -- 一键邀请按钮
        NewBangHuiBZTX_Candidate_Campare:Show()             -- 成员对比按钮
        NewBangHuiBZTX_Candidate_Save:Show()                -- 保存按钮
        NewBangHuiBZTX_Candidate_Refresh:Show()             -- 刷新按钮
        NewBangHuiBZTX_Candidate_Paixu_Frame:Show()         -- 排序
        NewBangHuiBZTX_Candidate_Dingwei:Show()             -- 定位

        NewBangHuiBZTX_Candidate_PageBtn1:SetCheck(1)       -- 本帮成员
        NewBangHuiBZTX_Candidate_PageBtn2:SetCheck(0)       -- 助战成员

        --NewBangHuiBZTX_Candidate_My_Text:Hide()
        --NewBangHuiBZTX_Candidate_LeaveBtn:Hide()
        NewBangHuiBZTX_Candidate_HelpPeople:Show()

        NewBangHuiBZTX_Candidate_RemoveAssistCache = nil

        NewBangHuiBZTX_Candidate_CurPlayerListTab = NewBangHuiBZTX_Candidate_TabType.guildmember
    elseif (tabType == NewBangHuiBZTX_Candidate_TabType.assistplayer) then
        -- 助战成员
        NewBangHuiBZTX_Candidate_OnekeyAssign:Hide()        -- 一键分配按钮
        NewBangHuiBZTX_Candidate_OnekeyCancel:Hide()        -- 一键取消按钮
        NewBangHuiBZTX_Candidate_Invite:Show()              -- 一键邀请按钮
        NewBangHuiBZTX_Candidate_Campare:Show()             -- 成员对比按钮
        NewBangHuiBZTX_Candidate_Save:Show()                -- 保存按钮
        NewBangHuiBZTX_Candidate_Refresh:Show()             -- 刷新按钮
        NewBangHuiBZTX_Candidate_Paixu_Frame:Hide()         -- 排序
        NewBangHuiBZTX_Candidate_Dingwei:Hide()             -- 定位

        NewBangHuiBZTX_Candidate_PageBtn1:SetCheck(0)       -- 本帮成员
        NewBangHuiBZTX_Candidate_PageBtn2:SetCheck(1)       -- 助战成员

        --NewBangHuiBZTX_Candidate_My_Text:Hide()
        --NewBangHuiBZTX_Candidate_LeaveBtn:Hide()
        NewBangHuiBZTX_Candidate_HelpPeople:Show()

        NewBangHuiBZTX_Candidate_RemoveAssistCache = {}

        NewBangHuiBZTX_Candidate_CurPlayerListTab = NewBangHuiBZTX_Candidate_TabType.assistplayer
    else
        -- 按说是不应该到这的
        NewBangHuiBZTX_Candidate_RemoveAssistCache = nil
    end

    -- 刷一下自己的助战信息
    --NewBangHuiBZTX_Candidate_UpdateMyselfAssistInfo()

    NewBangHuiBZTX_Candidate_List:Clear()
    NewBangHuiBZTX_Candidate_ListItemNum = 0
end -- end func NewBangHuiBZTX_Candidate_InitPlayerListTab()

--*****************************************************************************
-- 初始化人数计数
--*****************************************************************************
function NewBangHuiBZTX_Candidate_InitPlayerNum()
    -- 本帮成员
    NewBangHuiBZTX_Candidate_AssignedMemberCount, NewBangHuiBZTX_Candidate_AssignedMemberOnlineCount = Guild:GetTCWLAssignPlayerNum()
    NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 = Guild:GetTCWLAssignPlayerNumByGroup(NewBangHuiBZTX_Candidate_GroupId.group1)
    NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 = Guild:GetTCWLAssignPlayerNumByGroup(NewBangHuiBZTX_Candidate_GroupId.group2)

    -- 助战玩家
    NewBangHuiBZTX_Candidate_AssistPlayerNum, NewBangHuiBZTX_Candidate_AssistPlayerOnlineNum = TCWL:GetAssistPlayerNum()
    NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1 = TCWL:GetAssistPlayerNumByGroup(NewBangHuiBZTX_Candidate_GroupId.group1)
    NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2 = TCWL:GetAssistPlayerNumByGroup(NewBangHuiBZTX_Candidate_GroupId.group2)
end -- end func NewBangHuiBZTX_Candidate_InitPlayerNum()

--*****************************************************************************
-- 将玩家加入到助战分组中
--*****************************************************************************
function NewBangHuiBZTX_Candidate_AddPlayerToAssistGroup(guildIdx)
    if (guildIdx == nil or guildIdx < 0) then
        return -1
    end

    local groupTemp = Guild:GetMembersInfo(guildIdx, "TCWLGroupTemp")
    if (groupTemp == nil) then
        groupTemp = NewBangHuiBZTX_Candidate_GroupId.group0
        Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", groupTemp)
    end

    local groupPlayerNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 + NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1
    local groupPlayerNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 + NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2

    if (groupTemp == NewBangHuiBZTX_Candidate_GroupId.group0) then
        -- 玩家没有分组 选一个人没满的分组
        if (groupPlayerNum1 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
            -- 分组1还没满 可以加入分组1
            Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", NewBangHuiBZTX_Candidate_GroupId.group1)

            NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 + 1

            return NewBangHuiBZTX_Candidate_GroupId.group1
        elseif (groupPlayerNum2 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
            -- 分组1已经满了 加入分组2吧
            Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", NewBangHuiBZTX_Candidate_GroupId.group2)

            NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 + 1

            return NewBangHuiBZTX_Candidate_GroupId.group2
        else
            -- 分组1和分组2都满了
            return NewBangHuiBZTX_Candidate_GroupId.group0
        end
    elseif (groupTemp == NewBangHuiBZTX_Candidate_GroupId.group1) then
        -- 分组1
        if (groupPlayerNum1 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
            -- 分组1还没满 可以加入分组1
            Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", NewBangHuiBZTX_Candidate_GroupId.group1)

            NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 + 1

            return NewBangHuiBZTX_Candidate_GroupId.group1
        elseif (groupPlayerNum2 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
            -- 分组1已经满了 加入分组2吧
            Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", NewBangHuiBZTX_Candidate_GroupId.group2)

            NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 + 1

            return NewBangHuiBZTX_Candidate_GroupId.group2
        else
            -- 分组1和分组2都满了
            return NewBangHuiBZTX_Candidate_GroupId.group0
        end
    elseif (groupTemp == NewBangHuiBZTX_Candidate_GroupId.group2) then
        -- 分组2
        if (groupPlayerNum2 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
            -- 分组2没有满 可以加入分组2
            Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", NewBangHuiBZTX_Candidate_GroupId.group2)

            NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 + 1

            return NewBangHuiBZTX_Candidate_GroupId.group2
        elseif (groupPlayerNum1 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
            -- 分组2已经满了 加入分组1吧
            Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", NewBangHuiBZTX_Candidate_GroupId.group1)

            NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 + 1

            return NewBangHuiBZTX_Candidate_GroupId.group1
        else
            -- 分组1和分组2都满了
            return NewBangHuiBZTX_Candidate_GroupId.group0
        end
    else
        -- 分组有问题
        return NewBangHuiBZTX_Candidate_GroupId.group0
    end

    return 0
end -- end func NewBangHuiBZTX_Candidate_AddPlayerToAssistGroup()

--*****************************************************************************
-- 将玩家从助战分组中移除
--*****************************************************************************
function NewBangHuiBZTX_Candidate_RemovePlayerFromAssistGroup(guildIdx)
    if (guildIdx == nil or guildIdx < 0) then
        return -1
    end

    local groupTemp = Guild:GetMembersInfo(guildIdx, "TCWLGroupTemp")
    if (groupTemp == nil) then
        groupTemp = NewBangHuiBZTX_Candidate_GroupId.group0
        Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", groupTemp)
    end

    local groupPlayerNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 + NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1
    local groupPlayerNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 + NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2

    if (groupTemp == NewBangHuiBZTX_Candidate_GroupId.group1) then
        -- 从分组1中移除
        NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 - 1
        if (NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 < 0) then
            NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 = 0
        end
    elseif (groupTemp == NewBangHuiBZTX_Candidate_GroupId.group2) then
        -- 从分组2中移除
        NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 - 1
        if (NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 < 0) then
            NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 = 0
        end
    end

    Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", NewBangHuiBZTX_Candidate_GroupId.group0)

    return NewBangHuiBZTX_Candidate_GroupId.group0
end -- end func NewBangHuiBZTX_Candidate_RemovePlayerFromAssistGroup()

--*****************************************************************************
-- 改变玩家助战分组
--*****************************************************************************
function NewBangHuiBZTX_Candidate_ChangePlayerAssistGroup(guildIdx)
    if (guildIdx == nil or guildIdx < 0) then
        return -1
    end

    local groupPlayerNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 + NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1
    local groupPlayerNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 + NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2

    if (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.guildmember) then
        -- 本帮成员页签
        local groupTemp = Guild:GetMembersInfo(guildIdx, "TCWLGroupTemp")
        if (groupTemp == nil) then
            groupTemp = NewBangHuiBZTX_Candidate_GroupId.group0
            Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", groupTemp)
        end

        if (groupTemp == NewBangHuiBZTX_Candidate_GroupId.group0) then
            -- 玩家当前没有分组
            if (groupPlayerNum1 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
                -- 分组1人数没满 加入到分组1
                Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", NewBangHuiBZTX_Candidate_GroupId.group1)

                NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 + 1

                return NewBangHuiBZTX_Candidate_GroupId.group1
            elseif (groupPlayerNum2 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
                -- 分组2人数没满 加入到分组2
                Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", NewBangHuiBZTX_Candidate_GroupId.group2)

                NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 + 1

                return NewBangHuiBZTX_Candidate_GroupId.group2
            else
                -- 分组1和分组2人数都满了
                local msgTxt = ScriptGlobal_Format("#{GCQH_240429_282}", NewBangHuiBZTX_Candidate_GroupId.group1)
                PushDebugMessage(msgTxt)

                return NewBangHuiBZTX_Candidate_GroupId.group0
            end
        elseif (groupTemp == NewBangHuiBZTX_Candidate_GroupId.group1) then
            -- 当前分组1 切换到分组2
            if (groupPlayerNum2 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
                -- 分组2人没满 可以切过去
                Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", NewBangHuiBZTX_Candidate_GroupId.group2)

                -- 更新分组1玩家计数
                NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 - 1
                if (NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 < 0) then
                    NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 = 0
                end
                -- 更新分组2玩家计数
                NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 + 1

                return NewBangHuiBZTX_Candidate_GroupId.group2
            else
                -- 分组2人满了 切不过去
                local msgTxt = ScriptGlobal_Format("#{GCQH_240429_282}", NewBangHuiBZTX_Candidate_GroupId.group2)
                PushDebugMessage(msgTxt)

                return NewBangHuiBZTX_Candidate_GroupId.group1
            end
        elseif (groupTemp == NewBangHuiBZTX_Candidate_GroupId.group2) then
            -- 当前分组2 切换到分组1
            if (groupPlayerNum1 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
                -- 分组1人没满 可以切过去
                Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", NewBangHuiBZTX_Candidate_GroupId.group1)

                -- 更新分组2玩家计数
                NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 - 1
                if (NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 < 0) then
                    NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 = 0
                end
                -- 更新分组1玩家计数
                NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 + 1

                return NewBangHuiBZTX_Candidate_GroupId.group1
            else
                -- 分组1人满了 切不过去
                local msgTxt = ScriptGlobal_Format("#{GCQH_240429_282}", NewBangHuiBZTX_Candidate_GroupId.group1)
                PushDebugMessage(msgTxt)

                return NewBangHuiBZTX_Candidate_GroupId.group2
            end
        else
            -- 分组有问题
            local msgTxt = ScriptGlobal_Format("#{GCQH_240429_282}", NewBangHuiBZTX_Candidate_GroupId.group1)
            PushDebugMessage(msgTxt)
        end
    elseif (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.assistplayer) then
        -- 助战玩家页签
        local groupTemp = TCWL:GetAssistPlayerInfo(guildIdx, "grouptemp")
        if (groupTemp == nil) then
            groupTemp = NewBangHuiBZTX_Candidate_GroupId.group0
            TCWL:SetAssistPlayerInfo(guildIdx, "grouptemp", groupTemp)
        end

        if (groupTemp == NewBangHuiBZTX_Candidate_GroupId.group0) then
            -- 玩家当前没有分组
            if (groupPlayerNum1 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
                -- 分组1人数没满 加入到分组1
                TCWL:SetAssistPlayerInfo(guildIdx, "grouptemp", NewBangHuiBZTX_Candidate_GroupId.group1)

                NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 + 1

                return NewBangHuiBZTX_Candidate_GroupId.group1
            elseif (groupPlayerNum2 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
                -- 分组2人数没满 加入到分组2
                TCWL:SetAssistPlayerInfo(guildIdx, "grouptemp", NewBangHuiBZTX_Candidate_GroupId.group2)

                NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 + 1

                return NewBangHuiBZTX_Candidate_GroupId.group2
            else
                -- 分组1和分组2人数都满了
                local msgTxt = ScriptGlobal_Format("#{GCQH_240429_282}", NewBangHuiBZTX_Candidate_GroupId.group1)
                PushDebugMessage(msgTxt)

                return NewBangHuiBZTX_Candidate_GroupId.group0
            end
        elseif (groupTemp == NewBangHuiBZTX_Candidate_GroupId.group1) then
            -- 当前分组1 切换到分组2
            if (groupPlayerNum2 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
                -- 分组2人没满 可以切过去
                TCWL:SetAssistPlayerInfo(guildIdx, "grouptemp", NewBangHuiBZTX_Candidate_GroupId.group2)

                -- 更新分组1玩家计数
                NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1 = NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1 - 1
                if (NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1 < 0) then
                    NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1 = 0
                end
                -- 更新分组2玩家计数
                NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2 = NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2 + 1

                return NewBangHuiBZTX_Candidate_GroupId.group2
            else
                -- 分组2人满了 切不过去
                local msgTxt = ScriptGlobal_Format("#{GCQH_240429_282}", NewBangHuiBZTX_Candidate_GroupId.group2)
                PushDebugMessage(msgTxt)

                return NewBangHuiBZTX_Candidate_GroupId.group1
            end
        elseif (groupTemp == NewBangHuiBZTX_Candidate_GroupId.group2) then
            -- 当前分组2 切换到分组1
            if (groupPlayerNum1 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
                -- 分组1人没满 可以切过去
                TCWL:SetAssistPlayerInfo(guildIdx, "grouptemp", NewBangHuiBZTX_Candidate_GroupId.group1)

                -- 更新分组2玩家计数
                NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2 = NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2 - 1
                if (NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2 < 0) then
                    NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2 = 0
                end
                -- 更新分组1玩家计数
                NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1 = NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1 + 1

                return NewBangHuiBZTX_Candidate_GroupId.group1
            else
                -- 分组1人满了 切不过去
                local msgTxt = ScriptGlobal_Format("#{GCQH_240429_282}", NewBangHuiBZTX_Candidate_GroupId.group1)
                PushDebugMessage(msgTxt)

                return NewBangHuiBZTX_Candidate_GroupId.group2
            end
        else
            -- 分组有问题
            local msgTxt = ScriptGlobal_Format("#{GCQH_240429_282}", NewBangHuiBZTX_Candidate_GroupId.group1)
            PushDebugMessage(msgTxt)

            return NewBangHuiBZTX_Candidate_GroupId.group0
        end
    end

    return NewBangHuiBZTX_Candidate_GroupId.group0
end -- end func NewBangHuiBZTX_Candidate_ChangePlayerAssistGroup()

--*****************************************************************************
-- 设置/取消本帮成员参战资格标记
--*****************************************************************************
function NewBangHuiBZTX_Candidate_SetMemberJoinFlag(guildIdx, flagVal)
    if (guildIdx == nil or guildIdx < 0) then
        return -1
    end

    local retGroup = 0
    if (flagVal > 0) then
        -- 设置参战标记
        Guild:SetMembersInfo(guildIdx, "TCWLJoinFlagTemp", NewBangHuiBZTX_Candidate_CurWeekCount)

        -- 将玩家加入到分组中
        retGroup = NewBangHuiBZTX_Candidate_AddPlayerToAssistGroup(guildIdx)

        -- 更新分组切换按钮tooltip
        --NewBangHuiBZTX_Candidate_UpdateGroupChangeBtnToolTip()

        -- 更新本帮成员参战资格计数
        NewBangHuiBZTX_Candidate_AssignedMemberCount = NewBangHuiBZTX_Candidate_AssignedMemberCount + 1
        local memIsOnline = Guild:GetMembersInfo(guildIdx, "Online")
        if (memIsOnline > 0) then
            NewBangHuiBZTX_Candidate_AssignedMemberOnlineCount = NewBangHuiBZTX_Candidate_AssignedMemberOnlineCount + 1
        end
    else
        -- 取消参战标记
        Guild:SetMembersInfo(guildIdx, "TCWLJoinFlagTemp", 0)

        -- 将玩家从分组中移除
        retGroup = NewBangHuiBZTX_Candidate_RemovePlayerFromAssistGroup(guildIdx)

        -- 更新分组切换按钮tooltip
        --NewBangHuiBZTX_Candidate_UpdateGroupChangeBtnToolTip()

        -- 更新本帮成员参战资格计数
        NewBangHuiBZTX_Candidate_AssignedMemberCount = NewBangHuiBZTX_Candidate_AssignedMemberCount - 1
        if (NewBangHuiBZTX_Candidate_AssignedMemberCount < 0) then
            NewBangHuiBZTX_Candidate_AssignedMemberCount = 0
        end
        local memIsOnline = Guild:GetMembersInfo(guildIdx, "Online")
        if (memIsOnline > 0) then
            NewBangHuiBZTX_Candidate_AssignedMemberOnlineCount = NewBangHuiBZTX_Candidate_AssignedMemberOnlineCount - 1
            if (NewBangHuiBZTX_Candidate_AssignedMemberOnlineCount < 0) then
                NewBangHuiBZTX_Candidate_AssignedMemberOnlineCount = 0
            end
        end
    end

    return retGroup
end -- end func NewBangHuiBZTX_Candidate_SetMemberJoinFlag()

--*************************************************************************************************
--*************************************************************************************************

--*****************************************************************************
-- 一键分配返回确认结果
--*****************************************************************************
function NewBangHuiBZTX_Candidate_ConfirmResult_Assign(result)
    if (result <= 0) then
        -- 取消
    else
        -- 确认
        NewBangHuiBZTX_Candidate_DoOnekeyAssign()
    end
end -- end func NewBangHuiBZTX_Candidate_ConfirmResult_Assign()

--*****************************************************************************
-- 一键取消返回确认结果
--*****************************************************************************
function NewBangHuiBZTX_Candidate_ConfirmResult_AssignCancel(result)
    if (result <= 0) then
        -- 取消
    else
        -- 确认
        NewBangHuiBZTX_Candidate_DoOnekeyCancel()
    end
end -- end func NewBangHuiBZTX_Candidate_ConfirmResult_AssignCancel()

--*****************************************************************************
-- 保存分配返回确认结果
--*****************************************************************************
function NewBangHuiBZTX_Candidate_ConfirmResult_Save(result)
end -- end func NewBangHuiBZTX_Candidate_ConfirmResult_Save()

--*****************************************************************************
-- 分配结果未保存直接刷新返回确认结果
--*****************************************************************************
function NewBangHuiBZTX_Candidate_ConfirmResult_Refresh(result)
end -- end func NewBangHuiBZTX_Candidate_ConfirmResult_Refresh()

--*****************************************************************************
-- 分配结果未保存直接退出返回确认结果
--*****************************************************************************
function NewBangHuiBZTX_Candidate_ConfirmResult_Exit(result, exitType)
    if (result <= 0) then
        -- 取消
    else
        -- 确认
        NewBangHuiBZTX_Candidate_Changed = 0
        if (exitType == nil) then
            this:Hide()
        else
            if (exitType == NewBangHuiBZTX_Candidate_ExitType.cygl) then
                -- 成员管理
                NewBangHuiBZTX_Candidate_Hygl_Clicked(0)
            elseif (exitType == NewBangHuiBZTX_Candidate_ExitType.bhxx) then
                -- 帮会信息
                NewBangHuiBZTX_Candidate_Bhxx_Clicked(0)
            elseif (exitType == NewBangHuiBZTX_Candidate_ExitType.bhtm) then
                -- 帮会同盟
                NewBangHuiBZTX_Candidate_Tmxx_Clicked(0)
            elseif (exitType == NewBangHuiBZTX_Candidate_ExitType.bhxz) then
                -- 帮会宣战
                NewBangHuiBZTX_Candidate_Bhxz_Clicked(0)
            elseif (exitType == NewBangHuiBZTX_Candidate_ExitType.bhjz) then
                -- 帮会建筑
                NewBangHuiBZTX_Candidate_JZWJS_Clicked(0)
            elseif (exitType == NewBangHuiBZTX_Candidate_ExitType.bhhb) then
                -- 帮会红包
                NewBangHuiBZTX_Candidate_HB_Clicked(0)
            elseif (exitType == NewBangHuiBZTX_Candidate_ExitType.yxzk) then
                -- 浴血战况
                NewBangHuiBZTX_Candidate_YXSS_Clicked(0)
            elseif (exitType == NewBangHuiBZTX_Candidate_ExitType.bhpm) then
                -- 帮会拍卖
                NewBangHuiBZTX_Candidate_Auction_Clicked(0)
            elseif (exitType == NewBangHuiBZTX_Candidate_ExitType.close) then
                -- 普通关闭
                this:Hide()
            elseif (exitType == NewBangHuiBZTX_Candidate_ExitType.bztx_guildmember) then
                -- 切换到本帮成员页签
                NewBangHuiBZTX_Candidate_PageBtn1_Clicked(0)
            elseif (exitType == NewBangHuiBZTX_Candidate_ExitType.bztx_assistplayer) then
                -- 切换到助战成员页签
                NewBangHuiBZTX_Candidate_PageBtn2_Clicked(0)
            end
        end
    end
end -- end func NewBangHuiBZTX_Candidate_ConfirmResult_Exit()

--*****************************************************************************
-- 移除助战玩家二次确认返回结果
--*****************************************************************************
function NewBangHuiBZTX_Candidate_ConfirmResult_RemoveAssistPlayer(result, guildIdx, ctrlIdx)
    if (result == nil or result <= 0) then
        local ctrlChild = NewBangHuiBZTX_Candidate_List:GetListItemAt(ctrlIdx)
        if (ctrlChild ~= nil) then
            local btnRemove = ctrlChild:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_MoveBtn")
            if (btnRemove ~= nil) then
                btnRemove:Enable()
            end
        end
        return
    end
    if (guildIdx == nil or guildIdx < 0) then
        return
    end
    if (ctrlIdx == nil or ctrlIdx < 0) then
        return
    end

    if (NewBangHuiBZTX_Candidate_CurPlayerListTab ~= NewBangHuiBZTX_Candidate_TabType.assistplayer) then
        return
    end

    -- 校验一下要移除的玩家
    local playerGUID = TCWL:GetAssistPlayerInfo(guildIdx, "guid")
    if (NewBangHuiBZTX_Candidate_RemoveAssistCache == nil) then
        -- 没有缓存校验数据 按说不应该这样的 放弃本次移除操作 返回吧
        return
    end
    if (NewBangHuiBZTX_Candidate_RemoveAssistCache[guildIdx] == nil) then
        -- 没有对应的缓存校验数据 放弃本次移除操作 返回
        return
    end
    if (NewBangHuiBZTX_Candidate_RemoveAssistCache[guildIdx] ~= playerGUID) then
        -- 当前获取到的玩家和缓存校验数据里的玩家不一致 可能是助战玩家列表有变化 校验失败 放弃本次移除操作
        NewBangHuiBZTX_Candidate_RemoveAssistCache[guildIdx] = nil
        return
    end

    -- 到这里说明校验通过了 清除此条校验数据
    NewBangHuiBZTX_Candidate_RemoveAssistCache[guildIdx] = nil

    -- 删除助战玩家并通知服务器
    local ret = TCWL:RemoveAssistPlayer(guildIdx)
    if (ret > 0) then
        -- 这里需要重新刷新一下助战玩家列表 因为上面的TCWL:RemoveAssistPlayer会将这个玩家从列表中删除
        -- 如果服务器端删除失败 玩家可以重开UI活动点击刷新按钮来恢复助战玩家列表
        NewBangHuiBZTX_Candidate_List:Clear()
        NewBangHuiBZTX_Candidate_ListItemNum = 0

        NewBangHuiBZTX_Candidate_UpdateGuildMemberList()
        NewBangHuiBZTX_Candidate_UpdateAssistPlayerList(guildIdx)
    end
end -- end func NewBangHuiBZTX_Candidate_ConfirmResult_RemoveAssistPlayer()

--*************************************************************************************************
--*************************************************************************************************

--*****************************************************************************
-- 一键分配
--*****************************************************************************
function NewBangHuiBZTX_Candidate_DoOnekeyAssign()
    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    -- 是否帮主或副帮主
    local isChiefOrAss = Guild:IsChieforAss()
    if (isChiefOrAss ~= 1) then
        PushDebugMessage("#{GCQH_240429_78}")
        return
    end

    -- 是否在允许操作的时间内
    local isInTime = NewBangHuiBZTX_Candidate_Check_AssignForbiddenTime()
    if (isInTime <= 0) then
        PushDebugMessage("#{GCQH_240429_79}")
        return
    end

    -- 是否还有可分配的参与资格
    local totalPlayerNum = NewBangHuiBZTX_Candidate_AssignedMemberCount + NewBangHuiBZTX_Candidate_AssistPlayerNum
    if (totalPlayerNum >= NewBangHuiBZTX_Candidate_MaxPlayerCount) then
        PushDebugMessage("#{GCQH_240429_80}")
        return
    end

    -- 计算一键分配需要补充多少名帮会成员
    local validPlayerNum = NewBangHuiBZTX_Candidate_MaxPlayerCount - totalPlayerNum
    if (validPlayerNum <= 0) then
        return
    end
    -- 执行一键分配逻辑
    local assignedNum = 0
    local totalNum = Guild:GetMembersNum(4)
    for i=1, totalNum, 1 do
        local guildIdx = Guild:GetShowMembersIdx(i-1)
        local joinFlagTemp = Guild:GetMembersInfo(guildIdx, "TCWLJoinFlagTemp")
        if (joinFlagTemp <= 0) then
            local retGroup = NewBangHuiBZTX_Candidate_SetMemberJoinFlag(guildIdx, 1)
            local ctrlChild = NewBangHuiBZTX_Candidate_List:GetListItemAt(i)
            if (ctrlChild ~= nil) then
                local btnCheck = ctrlChild:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Select")
                if (btnCheck ~= nil) then
                    btnCheck:SetCheck(1)
                end

                -- 更新分组显示
                NewBangHuiBZTX_Candidate_UpdateGroupInfo(guildIdx, ctrlChild, retGroup)

                assignedNum = assignedNum + 1
                if (assignedNum >= validPlayerNum) then
                    break
                end
            end
        end
    end -- end for

    -- 更新分组切换按钮tooltip
    NewBangHuiBZTX_Candidate_UpdateGroupChangeBtnToolTip()
    -- 更新参与资格成员数量计数显示信息
    NewBangHuiBZTX_Candidate_UpdateMemberAssignedInfo()

    PushDebugMessage("#{GCQH_240429_84}")

    NewBangHuiBZTX_Candidate_Changed = 1
end -- end func NewBangHuiBZTX_Candidate_DoOnekeyAssign()

--*****************************************************************************
-- 一键取消
--*****************************************************************************
function NewBangHuiBZTX_Candidate_DoOnekeyCancel()
    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    -- 是否帮主或副帮主
    local isChiefOrAss = Guild:IsChieforAss()
    if (isChiefOrAss ~= 1) then
        PushDebugMessage("#{GCQH_240429_78}")
        return
    end

    -- 是否在允许操作的时间内
    local isInTime = NewBangHuiBZTX_Candidate_Check_AssignForbiddenTime()
    if (isInTime <= 0) then
        PushDebugMessage("#{GCQH_240429_87}")
        return
    end

    local totalNum = Guild:GetMembersNum(4)
    for i=1, totalNum, 1 do
        local guildIdx = Guild:GetShowMembersIdx(i-1)
        local joinFlagTemp = Guild:GetMembersInfo(guildIdx, "TCWLJoinFlagTemp")
        if (joinFlagTemp > 0) then
            local retGroup = NewBangHuiBZTX_Candidate_SetMemberJoinFlag(guildIdx, 0)
            local ctrlChild = NewBangHuiBZTX_Candidate_List:GetListItemAt(i)
            if (ctrlChild ~= nil) then
                local btnCheck = ctrlChild:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Select")
                if (btnCheck ~= nil) then
                    btnCheck:SetCheck(0)
                end

                -- 更新分组显示
                NewBangHuiBZTX_Candidate_UpdateGroupInfo(guildIdx, ctrlChild, retGroup)
            end
        end
    end -- end for

    NewBangHuiBZTX_Candidate_AssignedMemberCount = 0
    NewBangHuiBZTX_Candidate_AssignedOnlineCount = 0 

    -- 更新分组切换按钮tooltip
    NewBangHuiBZTX_Candidate_UpdateGroupChangeBtnToolTip()
    -- 更新参与资格成员数量计数显示信息
    NewBangHuiBZTX_Candidate_UpdateMemberAssignedInfo()

    PushDebugMessage("#{GCQH_240429_89}")

    NewBangHuiBZTX_Candidate_Changed = 1
end -- end func NewBangHuiBZTX_Candidate_DoOnekeyCancel()

--*****************************************************************************
-- 保存分配结果
--*****************************************************************************
function NewBangHuiBZTX_Candidate_DoSave()
    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return -1
    end

    if (NewBangHuiBZTX_Candidate_Check_OpCD() <= 0) then
        -- 操作频繁 稍微再试
        PushDebugMessage("#{GCQH_240429_142}")
        return -2
    end

    -- 是否帮主或副帮主
    local isChiefOrAss = Guild:IsChieforAss()
    if (isChiefOrAss ~= 1) then
        PushDebugMessage("#{GCQH_240429_78}")
        return -3
    end

    -- 是否在允许操作的时间内
    if (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.guildmember) then
        local isInTime = NewBangHuiBZTX_Candidate_Check_AssignForbiddenTime()
        if (isInTime <= 0) then
            PushDebugMessage("#{GCQH_240429_127}")
            return -4
        end
    elseif (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.assistplayer) then
        local isInTime = NewBangHuiBZTX_Candidate_Check_AssistEnrollTime()
        if (isInTime <= 0) then
            PushDebugMessage("#{GCQH_240429_197}")
            return -5
        end
    end

    -- 是否有修改操作
    if (NewBangHuiBZTX_Candidate_Changed <= 0) then
        -- 参与名单没有变化 什么也不做
        PushDebugMessage("#{GCQH_240429_126}")
        return -11
    end

    -- 重置CD时间
    NewBangHuiBZTX_Candidate_LastOpTime = DataPool:GetCurrentServerTime()

    NewBangHuiBZTX_Candidate_Changed = 0

    if (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.guildmember) then
        -- 保存本帮成员设置
        -- 遍历玩家列表 设置每个成员的资格分配标记
        local joinCount = 0
        local totalNum = Guild:GetMembersNum(4)
        for i=1, totalNum, 1 do
            local child = NewBangHuiBZTX_Candidate_List:GetListItemAt(i)
            if (child ~= nil) then
                local guildIdx = Guild:GetShowMembersIdx(i-1)
                local joinFlagTemp = Guild:GetMembersInfo(guildIdx, "TCWLJoinFlagTemp")
                local ctrlItem = child:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Select")
                if (ctrlItem ~= nil and
                    ctrlItem:GetCheck() > 0 and
                    joinFlagTemp > 0) then

                    Guild:SetMembersInfo(guildIdx, "TCWLJoinFlag", NewBangHuiBZTX_Candidate_CurWeekCount)
                    Guild:SetMembersInfo(guildIdx, "TCWLJoinFlagTemp", NewBangHuiBZTX_Candidate_CurWeekCount)

                    local groupTemp = Guild:GetMembersInfo(guildIdx, "TCWLGroupTemp")
                    Guild:SetMembersInfo(guildIdx, "TCWLGroup", groupTemp)
                else
                    Guild:SetMembersInfo(guildIdx, "TCWLJoinFlag", 0)
                    Guild:SetMembersInfo(guildIdx, "TCWLJoinFlagTemp", 0)

                    Guild:SetMembersInfo(guildIdx, "TCWLGroup", 0)
                end
            end
        end -- end for

        -- 向服务器发送设置好的参与资格名单
        Guild:TCWLSendJoinMemberList()
    elseif (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.assistplayer) then
        -- 保存助战玩家设置
        local assistPlayerNum = TCWL:GetAssistPlayerNum()
        for i=1, assistPlayerNum, 1 do
            local assistIdx = i - 1
            local playerGroupTemp = TCWL:GetAssistPlayerInfo(assistIdx, "grouptemp")
            TCWL:SetAssistPlayerInfo(assistIdx, "group", playerGroupTemp)
        end
        -- 向服务器发送助战玩家列表 主要用于更新分组
        TCWL:SendAssistPlayerList()
    else
        -- 按说不应该这样的
        return -100
    end
    
    return 1
end -- end func NewBangHuiBZTX_Candidate_DoSave()

--*****************************************************************************
-- 刷新
--*****************************************************************************
function NewBangHuiBZTX_Candidate_DoRefreshAll()
    if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    NewBangHuiBZTX_Candidate_PlayerListInitFlag = 0

    -- 请求自己的助战信息
    TCWL:AskMyselfAssistInfo()
    -- 请求助战玩家列表
    TCWL:AskAssistPlayerInfo(0)
    -- 请求帮会成员列表
    Guild:AskGuildMembersInfo_BZTX()
end -- end func NewBangHuiBZTX_Candidate_DoRefreshAll()

--*****************************************************************************
-- 服务器返回帮会成员参赛资格分配操作的结果
--*****************************************************************************
function NewBangHuiBZTX_Candidate_DealOperateResult(result)
    if (result == NewBangHuiBZTX_Candidate_OperateResult.toofast) then
		-- 操作过于频繁
        PushDebugMessage("#{GCQH_240429_142}")
	elseif (result == NewBangHuiBZTX_Candidate_OperateResult.poserror) then
		-- 没有帮会 或者不是帮主、副帮主
        PushDebugMessage("#{GCQH_240429_78}")
	elseif (result == NewBangHuiBZTX_Candidate_OperateResult.notintime_member) then
		-- 不在操作时间
        PushDebugMessage("#{GCQH_240429_127}")
    elseif (result == NewBangHuiBZTX_Candidate_OperateResult.notintime_assist) then
        -- 不在操作时间
        PushDebugMessage("#{GCQH_240429_197}")
    elseif (result == NewBangHuiBZTX_Candidate_OperateResult.notopensvr) then
        -- 不是开启服务器
        PushDebugMessage("#{GCQH_240429_154}")
    elseif (result == NewBangHuiBZTX_Candidate_OperateResult.guilderror) then
        -- 帮会没有参战资格
        PushDebugMessage("#{GCQH_240429_174}")
	elseif (result == NewBangHuiBZTX_Candidate_OperateResult.failed) then
		-- 失败
	elseif (result == NewBangHuiBZTX_Candidate_OperateResult.success) then
		-- 成功
        PushDebugMessage("#{GCQH_240429_128}")
	else
		-- 按说不应该这样的
	end
end -- end func NewBangHuiBZTX_Candidate_DealOperateResult()

--*************************************************************************************************
--*************************************************************************************************

--*****************************************************************************
-- 更新活动说明信息
--*****************************************************************************
function NewBangHuiBZTX_Candidate_UpdateInfoText()
    local tcwlServerOpenFlag = NewBangHuiBZTX_Candidate_TCWLServerOpenFlag
    local tcwlOpenWeekFlag = NewBangHuiBZTX_Candidate_TCWLOpenWeekFlag
    local curWeekCount = NewBangHuiBZTX_Candidate_CurWeekCount

    local modeText = ""
    if (tcwlOpenWeekFlag > 0) then
        modeText = ScriptGlobal_Format("#{GCQH_240429_42}", "#{GCQH_240429_6}")
    else
        modeText = ScriptGlobal_Format("#{GCQH_240429_42}", "#{GCQH_240429_5}")
    end
    NewBangHuiBZTX_Candidate_InfoText:SetText(modeText)
end -- end func NewBangHuiBZTX_Candidate_UpdateInfoText()

--*****************************************************************************
-- 更新变更分组按钮tooltips
--*****************************************************************************
function NewBangHuiBZTX_Candidate_UpdateGroupChangeBtnToolTip()
    -- 是否帮主或副帮主
    local isChiefOrAss = Guild:IsChieforAss()
    -- 是否在允许操作的时间内
    local isInTime = NewBangHuiBZTX_Candidate_Check_AssignForbiddenTime()

    local groupPlayerNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1 + NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1
    local groupPlayerNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2 + NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2
    local groupPlayerTips = ScriptGlobal_Format("#{GCQH_240429_184}", groupPlayerNum1, groupPlayerNum2)

    for i=1, NewBangHuiBZTX_Candidate_ListItemNum, 1 do
        local child = NewBangHuiBZTX_Candidate_List:GetListItemAt(i)
        if (child ~= nil) then
            local ctrlItem = nil
            if (isChiefOrAss == 1 and isInTime > 0) then
                ctrlItem = child:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Change")
            else
                ctrlItem = child:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_ChangeTips")
            end

            if (ctrlItem ~= nil) then
                ctrlItem:SetToolTip(groupPlayerTips)
            end
        end
    end -- end for
end -- end func NewBangHuiBZTX_Candidate_UpdateGroupChangeBtnToolTip()

--*****************************************************************************
-- 更新帮会参战成员计数信息
--*****************************************************************************
function NewBangHuiBZTX_Candidate_UpdateMemberAssignedInfo()
    -- 参与资格成员数量
    local playerCountTxt = ScriptGlobal_Format("#{GCQH_240429_72}", NewBangHuiBZTX_Candidate_AssignedMemberOnlineCount, NewBangHuiBZTX_Candidate_AssignedMemberCount)
    NewBangHuiBZTX_Candidate_ThreeCityPeople:SetText(playerCountTxt)
end -- end func NewBangHuiBZTX_Candidate_UpdateMemberAssignedInfo()

--*****************************************************************************
-- 更新帮会成员计数信息
--*****************************************************************************
function NewBangHuiBZTX_Candidate_UpdateMemberInfo()
    -- 帮会成员数量
    playerCountTxt = ScriptGlobal_Format("#{GCQH_240429_74}", Guild:GetMembersNum(3), Guild:GetMembersNum(1), Guild:GetMembersNum(2))
    NewBangHuiBZTX_Candidate_BangHuiPeople:SetText(playerCountTxt)
end -- end func NewBangHuiBZTX_Candidate_UpdateMemberInfo()

--*****************************************************************************
-- 更新助战玩家计数信息
--*****************************************************************************
function NewBangHuiBZTX_Candidate_UpdateAssistPlayerInfo()
    -- 助战玩家数量
    playerCountTxt = ScriptGlobal_Format("#{GCQH_240429_255}", NewBangHuiBZTX_Candidate_AssistPlayerOnlineNum, NewBangHuiBZTX_Candidate_AssistPlayerNum, NewBangHuiBZTX_Candidate_MaxPlayerCount)
    NewBangHuiBZTX_Candidate_HelpPeople:SetText(playerCountTxt)
    NewBangHuiBZTX_Candidate_HelpPeople:Show()
end -- end func NewBangHuiBZTX_Candidate_UpdateAssistPlayerInfo()

--*****************************************************************************
-- 更新分组显示
--*****************************************************************************
function NewBangHuiBZTX_Candidate_UpdateGroupInfo(guildIdx, ctrlChild, group)
    if (guildIdx == nil or guildIdx < 0) then
        return
    end
    if (ctrlChild == nil) then
        return
    end

    local groupCtrl = ctrlChild:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text6")
    if (groupCtrl ~= nil) then
        local color = "#cfff263"
        if (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.guildmember) then
            local myGUID = Player:GetGUID()
            local colorStr, strMemberTips = Guild:GetMembersInfo(guildIdx, "ShowColor")
            local memGUID = Guild:GetMembersInfo(guildIdx, "GUID")

            if (myGUID ~= memGUID) then
                color = colorStr
            else
                color = "#G"
            end
        else
            local playerOnlineFlag = TCWL:GetAssistPlayerInfo(guildIdx, "online")
            if (playerOnlineFlag <= 0) then
                color = "#c808080"
            end
        end

        if (group > 0) then
            groupCtrl:SetText(color .. tostring(group))
        else
            groupCtrl:SetText("#{GCQH_240429_190}")
        end
    end
end -- end func NewBangHuiBZTX_Candidate_UpdateGroupInfo()


--*************************************************************************************************
--*************************************************************************************************
--*************************************************************************************************
--*************************************************************************************************

--*****************************************************************************
-- 更新玩家自己的助战信息
--*****************************************************************************
function NewBangHuiBZTX_Candidate_UpdateMyselfAssistInfo()
    NewBangHuiBZTX_Candidate_My_Text:Show()
    NewBangHuiBZTX_Candidate_LeaveBtn:Show()
    
    local assistGuildId = TCWL:GetMyselfAssistInfo("assistguildid")
    if (assistGuildId >= 0) then
        local assistGuildName = TCWL:GetMyselfAssistInfo("assistguildname")
        local txtMsg = ScriptGlobal_Format("#{GCQH_240429_200}", assistGuildName)
        NewBangHuiBZTX_Candidate_My_Text:SetText(txtMsg)

        NewBangHuiBZTX_Candidate_LeaveBtn:SetText("#{GCQH_240429_201}")
    else
        local txtMsg = ScriptGlobal_Format("#{GCQH_240429_200}", "#{GCQH_240429_190}")
        NewBangHuiBZTX_Candidate_My_Text:SetText(txtMsg)

        NewBangHuiBZTX_Candidate_LeaveBtn:SetText("#{GCQH_240429_202}")
    end
end -- end func NewBangHuiBZTX_Candidate_UpdateMyselfAssistInfo()

--*****************************************************************************
-- 更新帮会成员列表
--*****************************************************************************
function NewBangHuiBZTX_Candidate_UpdateGuildMemberList()
    -- 初始化人数计数
    NewBangHuiBZTX_Candidate_InitPlayerNum()

    -- 更新UI上部说明信息
    NewBangHuiBZTX_Candidate_UpdateInfoText()
    -- 更新参与资格成员数量计数显示信息
    NewBangHuiBZTX_Candidate_UpdateMemberAssignedInfo()
    -- 更新帮会成员计数显示信息
    NewBangHuiBZTX_Candidate_UpdateMemberInfo()
    -- 更新助战玩家计数显示信息
    NewBangHuiBZTX_Candidate_UpdateAssistPlayerInfo()

    local isShowList = 0
    if (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.guildmember) then
        NewBangHuiBZTX_Candidate_PlayerListInitFlag = 1
        NewBangHuiBZTX_Candidate_Changed = 0
        isShowList = 1
    end

    if (isShowList > 0) then
        NewBangHuiBZTX_Candidate_List:Clear()
        NewBangHuiBZTX_Candidate_ListItemNum = 0
    end

    local assignGroupNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1
    local assignGroupNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2
    local assistGroupNum1 = NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1
    local assistGroupNum2 = NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2
    local groupPlayerNum1 = assignGroupNum1 + assistGroupNum1
    local groupPlayerNum2 = assignGroupNum2 + assistGroupNum2
    local groupPlayerTips = ScriptGlobal_Format("#{GCQH_240429_184}", groupPlayerNum1, groupPlayerNum2)
    
    -- 更新成员列表
    local isInTime = NewBangHuiBZTX_Candidate_Check_AssignForbiddenTime()
    local myGUID = Player:GetGUID()
    local isChiefOrAss = Guild:IsChieforAss()
    local totalNum = Guild:GetMembersNum(4)
    for i=1, totalNum, 1 do
        local guildIdx = Guild:GetShowMembersIdx(i-1)
        if (isShowList > 0) then
            -- 只有当前刷新的是本帮成员页签时才刷新成员列表 否则只计算成员资格分配、在线等数据
            local colorStr, strMemberTips = Guild:GetMembersInfo(guildIdx, "ShowColor")
            local memGUID = Guild:GetMembersInfo(guildIdx, "GUID")
            local memName = Guild:GetMembersInfo(guildIdx, "Name")
            local memPos = Guild:GetMembersInfo(guildIdx, "Position")
            local memLevel = Guild:GetMembersInfo(guildIdx, "Level")
            local memMenPai = Guild:GetMembersInfo(guildIdx, "MenPai")
            local memEquipPoint = Guild:GetMembersInfo(guildIdx, "EquipPoint")
            --local memWeekContri = Guild:GetMembersInfo(guildIdx, "ContriPerWeek")
            --local memMaxContri = Guild:GetMembersInfo(guildIdx, "MaxCon")
            --local memLastLogin = Guild:GetMembersInfo(guildIdx, "LastLoginTime")
            local memIsOnline = Guild:GetMembersInfo(guildIdx, "Online")
            local memTCWLJoinFlag = Guild:GetMembersInfo(guildIdx, "TCWLJoinFlag")
            Guild:SetMembersInfo(guildIdx, "TCWLJoinFlagTemp", memTCWLJoinFlag)
            local memGroup = Guild:GetMembersInfo(guildIdx, "TCWLGroup")
            local assistWeek = Guild:GetMembersInfo(guildIdx, "TCWLAssistWeek")
            local assistGuildName = Guild:GetMembersInfo(guildIdx, "TCWLAssistGuildName")
            if myGUID == memGUID and string.len(assistGuildName) == 0 then
                g_NewBangHuiBZTX_Candidate_SelfGroup = memGroup
            end
            -- 设置玩家默认分组
            if (memTCWLJoinFlag > 0) then
                if (memGroup < NewBangHuiBZTX_Candidate_GroupId.group1 or memGroup > NewBangHuiBZTX_Candidate_GroupId.group2) then
                    if (groupPlayerNum1 < NewBangHuiBZTX_Candidate_GroupPlayerMaxCount) then
                        memGroup = NewBangHuiBZTX_Candidate_GroupId.group1
                        groupPlayerNum1 = groupPlayerNum1 + 1
                    else
                        memGroup = NewBangHuiBZTX_Candidate_GroupId.group2
                        groupPlayerNum2 = groupPlayerNum2 + 1
                    end
                end
            else
                memGroup = 0
            end
            Guild:SetMembersInfo(guildIdx, "TCWLGroupTemp", memGroup)

            local bar = NewBangHuiBZTX_Candidate_List:AddChild("NewBangHuiBZTX_Candidate_ListItem")
            if (bar ~= nil) then
                NewBangHuiBZTX_Candidate_ListItemNum = NewBangHuiBZTX_Candidate_ListItemNum + 1 
                local selectBtn = bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Select")
                if (selectBtn ~= nil) then
                    selectBtn:SetEvent("MouseLClick", string.format("NewBangHuiBZTX_Candidate_SelectClicked(%d, %d)", guildIdx, NewBangHuiBZTX_Candidate_ListItemNum))
                    if (memTCWLJoinFlag > 0) then
                        selectBtn:SetCheck(1)
                        selectBtn:SetToolTip("#{GCQH_240429_123}")
                    else
                        selectBtn:SetCheck(0)
                        selectBtn:SetToolTip("#{GCQH_240429_91}")
                    end
                    if (isChiefOrAss == 1 and isInTime > 0) then
                        selectBtn:Enable()
                    else
                        selectBtn:Disable()
                    end
                end

                local color = ""
                if (myGUID ~= memGUID) then
                    color = colorStr
                else
                    color = "#G"
                end

                bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text1"):SetText(color .. NewBangHuiBZTX_Candidate_PositionInfo[memPos])
                bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text2"):SetText(color .. memName)
                bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text3"):SetText(color .. tostring(memLevel))
                bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text4"):SetText(color .. NewBangHuiBZTX_Candidate_MenPaiNameList[memMenPai])
                bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text5"):SetText(color .. tostring(memEquipPoint))
                if (memGroup > 0) then
                    bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text6"):SetText(color .. tostring(memGroup))
                else
                    bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text6"):SetText("#{GCQH_240429_190}")
                end
                local groupBtn = bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Change")
                local groupBtnTips = bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_ChangeTips")
                if (groupBtn ~= nil and groupBtnTips ~= nil) then
                    groupBtn:SetEvent("MouseLClick", string.format("NewBangHuiBZTX_Candidate_ListItem_ChangeClicked(%d, %d)", guildIdx, NewBangHuiBZTX_Candidate_ListItemNum))
                    if (isChiefOrAss == 1 and isInTime > 0) then
                        groupBtn:Enable()
                        groupBtn:SetToolTip(groupPlayerTips)
                        groupBtnTips:Hide()
                    else
                        groupBtn:Disable()
                        groupBtnTips:Show()
                        groupBtnTips:SetToolTip(groupPlayerTips)
                    end
                end

                -- 助战信息
                local assistGuildInfo = nil
                if (NewBangHuiBZTX_Candidate_CurWeekCount == tonumber(assistWeek)) then
                    assistGuildInfo = ScriptGlobal_Format("#{GCQH_240429_189}", assistGuildName)
                else
                    assistGuildInfo = "#{GCQH_240429_190}"
                end
                bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text7"):SetText(color .. assistGuildInfo)
                bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_MoveBtn"):Hide()

                bar:SetToolTip(strMemberTips)
            else
                local memTCWLJoinFlag = Guild:GetMembersInfo(guildIdx, "TCWLJoinFlag")
                Guild:SetMembersInfo(guildIdx, "TCWLJoinFlagTemp", memTCWLJoinFlag)
            end
        end
    end -- end for

    if (isShowList > 0) then
        if (isChiefOrAss == 1 and isInTime > 0) then
            NewBangHuiBZTX_Candidate_OnekeyAssign:Enable()
            NewBangHuiBZTX_Candidate_OnekeyCancel:Enable()
            NewBangHuiBZTX_Candidate_Save:Enable()
        else
            NewBangHuiBZTX_Candidate_OnekeyAssign:Disable()
            NewBangHuiBZTX_Candidate_OnekeyCancel:Disable()
            NewBangHuiBZTX_Candidate_Save:Disable()
        end

        if (NewBangHuiBZTX_Candidate_ListItemNum <= 0) then
            NewBangHuiBZTX_Candidate_Save:Disable()
        else
            NewBangHuiBZTX_Candidate_Save:Enable()
        end
    end
end -- end func NewBangHuiBZTX_Candidate_UpdateGuildMemberList()

--*************************************************************************************************
--*************************************************************************************************
--*************************************************************************************************
--*************************************************************************************************

--*****************************************************************************
-- 更新助战成员列表
--*****************************************************************************
function NewBangHuiBZTX_Candidate_UpdateAssistPlayerList(selectIdx)
    -- 初始化人数计数
    NewBangHuiBZTX_Candidate_InitPlayerNum()

    -- 更新UI上部说明信息
    NewBangHuiBZTX_Candidate_UpdateInfoText()
    -- 更新参与资格成员数量计数显示信息
    NewBangHuiBZTX_Candidate_UpdateMemberAssignedInfo()
    -- 更新帮会成员计数显示信息
    NewBangHuiBZTX_Candidate_UpdateMemberInfo()
    -- 更新助战玩家计数显示信息
    NewBangHuiBZTX_Candidate_UpdateAssistPlayerInfo()

    local isShowList = 0
    if (NewBangHuiBZTX_Candidate_CurPlayerListTab == NewBangHuiBZTX_Candidate_TabType.assistplayer) then
        NewBangHuiBZTX_Candidate_PlayerListInitFlag = 1
        NewBangHuiBZTX_Candidate_Changed = 0
        isShowList = 1
    end

    if (isShowList > 0) then
        NewBangHuiBZTX_Candidate_List:Clear()
        NewBangHuiBZTX_Candidate_ListItemNum = 0
    end

    local assignGroupNum1 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum1
    local assignGroupNum2 = NewBangHuiBZTX_Candidate_AssignedMemberGroupNum2
    local assistGroupNum1 = NewBangHuiBZTX_Candidate_AssistPlayerGroupNum1
    local assistGroupNum2 = NewBangHuiBZTX_Candidate_AssistPlayerGroupNum2
    local groupPlayerNum1 = assignGroupNum1 + assistGroupNum1
    local groupPlayerNum2 = assignGroupNum2 + assistGroupNum2
    local groupPlayerTips = ScriptGlobal_Format("#{GCQH_240429_184}", groupPlayerNum1, groupPlayerNum2)

    local isInTime = NewBangHuiBZTX_Candidate_Check_AssignForbiddenTime()
    local myGUID = Player:GetGUID()
    local isChiefOrAss = Guild:IsChieforAss()
    local assistPlayerNum = TCWL:GetAssistPlayerNum()
    for i=1, assistPlayerNum, 1 do
        local assistIdx = i - 1
        if (isShowList > 0) then
            local playerLevel = TCWL:GetAssistPlayerInfo(assistIdx, "level")
            local playerMenPai = TCWL:GetAssistPlayerInfo(assistIdx, "menpai")
            local playerEquipScore = TCWL:GetAssistPlayerInfo(assistIdx, "equipscore")
            local playerGroup = TCWL:GetAssistPlayerInfo(assistIdx, "group")
            local playerGroupTemp = TCWL:GetAssistPlayerInfo(assistIdx, "grouptemp")
            local playerOnlineFlag = TCWL:GetAssistPlayerInfo(assistIdx, "online")
            local playerName = TCWL:GetAssistPlayerInfo(assistIdx, "playername")
            local playerGuildName = TCWL:GetAssistPlayerInfo(assistIdx, "guildname")

            local bar = NewBangHuiBZTX_Candidate_List:AddChild("NewBangHuiBZTX_Candidate_ListItem")
            if (bar ~= nil) then
                NewBangHuiBZTX_Candidate_ListItemNum = NewBangHuiBZTX_Candidate_ListItemNum + 1 
                local selectBtn = bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Select")
                if (selectBtn ~= nil) then
                    selectBtn:SetCheck(1)
                    selectBtn:Disable()
                end
                local color = "#cfff263"
                if (playerOnlineFlag <= 0) then
                    color = "#c808080"
                end
                if (playerOnlineFlag <= 0) then
                    bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text1"):SetText("#{GCQH_240429_287}")
                else
                    bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text1"):SetText("#{GCQH_240429_179}")
                end
                bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text2"):SetText(color .. playerName)
                bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text3"):SetText(color .. tostring(playerLevel))
                bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text4"):SetText(color .. NewBangHuiBZTX_Candidate_MenPaiNameList[playerMenPai])
                bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text5"):SetText(color .. tostring(playerEquipScore))
                bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text6"):SetText(color .. tostring(playerGroup))
                local groupBtn = bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Change")
                local groupBtnTips = bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_ChangeTips")
                if (groupBtn ~= nil and groupBtnTips ~= nil) then
                    groupBtn:SetEvent("MouseLClick", string.format("NewBangHuiBZTX_Candidate_ListItem_ChangeClicked(%d, %d)", assistIdx, NewBangHuiBZTX_Candidate_ListItemNum))
                    if (isChiefOrAss == 1 and isInTime > 0) then
                        groupBtn:Enable()
                        groupBtn:SetToolTip(groupPlayerTips)
                        groupBtnTips:Hide()
                    else
                        groupBtn:Disable()
                        groupBtnTips:Show()
                        groupBtnTips:SetToolTip(groupPlayerTips)
                    end
                end
                bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_Text7"):Hide()
                local btnRemove = bar:GetSubItem("NewBangHuiBZTX_Candidate_ListItem_MoveBtn")
                if (btnRemove ~= nil) then
                    btnRemove:SetEvent("MouseLClick", string.format("NewBangHuiBZTX_Candidate_ListItem_MoveBtnClicked(%d, %d)", assistIdx, NewBangHuiBZTX_Candidate_ListItemNum))
                    btnRemove:SetToolTip("#{GCQH_240429_195}")
                end
                if (playerOnlineFlag <= 0) then
                    bar:SetToolTip("#{GCQH_240429_191}")
                end
            end
        end
    end -- end for

    if (isShowList > 0) then
        if (selectIdx ~= nil and selectIdx >= 0) then
            if (selectIdx >= NewBangHuiBZTX_Candidate_ListItemNum) then
                selectIdx = NewBangHuiBZTX_Candidate_ListItemNum - 1
            end
            if (selectIdx < 0) then
                selectIdx = 0
            end
            NewBangHuiBZTX_Candidate_List:SetScrollPosition4Index(selectIdx)
        end

        if (NewBangHuiBZTX_Candidate_ListItemNum <= 0) then
            NewBangHuiBZTX_Candidate_Save:Disable()
        else
            NewBangHuiBZTX_Candidate_Save:Enable()
        end
    end
end -- end func NewBangHuiBZTX_Candidate_UpdateAssistPlayerList()


function NewBangHuiBZTX_Candidate_CampareClicked()



    if g_NewBangHuiBZTX_Candidate_SelfGroup <= 0 then
        PushDebugMessage("#{GCQH_240429_228}")
        return
    end
    --是否有团队

    if Player:IsInRaid() == 1 then

        Guild:InviteBZTXMember(1)

    else
        PushDebugMessage("#{GCQH_240429_229}")        
    end

end


function NewBangHuiBZTX_Candidate_InviteClicked()

    if g_NewBangHuiBZTX_Candidate_SelfGroup <= 0 then
        PushDebugMessage("#{GCQH_240429_223}")
        return
    end

    --是否有团队

    if Player:IsInRaid() == 1 then
        if Player:IsRaidLeader() == 1 then
            PushEvent("UI_COMMAND", 20240826,g_NewBangHuiBZTX_Candidate_SelfGroup)
        else
            PushDebugMessage("#{GCQH_240429_239}")    
        end
        

    else
        PushDebugMessage("#{GCQH_240429_224}")        
    end
end