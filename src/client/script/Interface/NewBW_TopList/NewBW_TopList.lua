-- NewBW_TopList
-- 默认位置
local g_NewBW_TopList_UnifiedPosition = nil
local g_NewBW_TopList_UICommandShow = 89289702
local g_NewBW_TopList_SvrScriptId = 892897
local g_NewBW_TopList_CareObjId = -1
local g_NewBW_TopList_CareObjSvrId = -1
-- 锁定战队榜标记
local g_NewBW_TopList_LockedTeamFlag = 0
-- 切换普通榜还是锁定战队榜操作CD时间（秒）
local g_NewBW_TopList_ChangeRankOpMinTime = 5
-- 上一次切换普通榜还是锁定战队榜的操作时间
local g_NewBW_TopList_LastChangeRankOpTime = 0

-- 初始化
local g_init_List = 0
-- 上一次的页签选择
local g_tab_lastselect = 0
local g_cur_selIndex = 0
local g_cur_page = 0
local g_cur_pagemax = 0
-- 单页的最大数量
local g_team_max = 10
local g_ui_barList = {}
local g_ui_sel_TabBtnList = {}

local g_TeamRankStage = {
	null = -1,		
	begin = 0,		
	yingyang = 1,	-- 鹰扬（1 - 69）
	huxiao = 2,		-- 虎啸（70 - 89）
	longwei = 3,	-- 龙威（90 - 119）
    wudi = 4,       -- 无敌（120 - 129）
	max = 5,		
}

-- 资源相关
local g_rank_Image = {
    [1] = {image = "set:Ach1 image:WDTXPMBtn_1_Normal"},
    [2] = {image = "set:Ach1 image:WDTXPMBtn_2_Normal"},
    [3] = {image = "set:Ach1 image:WDTXPMBtn_3_Normal"},
}
function NewBW_TopList_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("XBW_TEAMRANK_UPDATE", true)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end

function NewBW_TopList_OnEvent(event)
    if (event == "UI_COMMAND" and tonumber(arg0) == g_NewBW_TopList_UICommandShow) then
        g_NewBW_TopList_LockedTeamFlag = 1
        NewBW_TopList_BeginCareObject()
        NewBW_TopList_ResetUIInfo()
        local selectIdx = Get_XParam_INT(1)
        NewBW_TopList_LevelSelect(selectIdx)
        this:Show()
    elseif (event == "XBW_TEAMRANK_UPDATE") then
        NewBW_TopList_Show(tonumber(arg0))
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        NewBW_TopList_Close()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        NewBW_TopList_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        NewBW_TopList_UnifiedPos()
    end
end

function NewBW_TopList_OnLoad()
    g_ui_sel_TabBtnList = {
        NewBW_TopList_CheckBox_Yeqian1,
        NewBW_TopList_CheckBox_Yeqian2,
        NewBW_TopList_CheckBox_Yeqian3,
        NewBW_TopList_CheckBox_Yeqian4,
    }

    g_NewBW_TopList_UnifiedPosition = NewBW_TopList_Frame:GetProperty("UnifiedPosition")
end


-- 界面默认位置
function NewBW_TopList_UnifiedPos()
    if (g_NewBW_TopList_UnifiedPosition ~= nil) then
        NewBW_TopList_Frame:SetProperty("UnifiedPosition", g_NewBW_TopList_UnifiedPosition)
    end
end

function NewBW_TopList_Show(isLockedTeam)
    if (isLockedTeam ~= nil and isLockedTeam > 0) then
        -- 锁定战队榜
        NewBW_TopList_CheckBox_Buttontab01:SetCheck(1)
        NewBW_TopList_CheckBox_Buttontab02:SetCheck(0)

        g_NewBW_TopList_LockedTeamFlag = 1
    else
        -- 普通榜（非所动战队榜）
        NewBW_TopList_CheckBox_Buttontab01:SetCheck(0)
        NewBW_TopList_CheckBox_Buttontab02:SetCheck(1)

        g_NewBW_TopList_LockedTeamFlag = 0
    end

    g_NewBW_TopList_LastChangeRankOpTime = 0

    -- 初始化
    NewBW_TopList_InitList()
    -- 进行内容的显示
    NewBW_TopList_ListShow()
    -- 进行一些页签的内容的显示
    NewBW_TopList_OtherShow()


    if (g_NewBW_TopList_LockedTeamFlag == 1) then
        -- 锁定战队榜
      	--卡级服
		local kjtype   = KaJi:LuaFnGetKaJiType(28)
		if kjtype == 1 then
            NewBW_TopList_TextInfo:SetText("#{SJPM_241125_85}")
        else
            NewBW_TopList_TextInfo:SetText("#{SJPM_241125_07}")
        end
    else
        -- 普通榜（非所动战队榜）
       	--卡级服
		local kjtype   = KaJi:LuaFnGetKaJiType(28)
		if kjtype == 1 then
            NewBW_TopList_TextInfo:SetText("#{SJPM_241125_71}")
        else
            NewBW_TopList_TextInfo:SetText("#{SJPM_241125_08}")
        end
    end

    --NewBW_TopList_SetPosition()
    this:Show()
end

-- 初始化列表
function NewBW_TopList_InitList()
    NewBW_TopList_List:Clear()
    for i = 1, g_team_max do
        local bar = NewBW_TopList_List:AddChild("NewBW_TopList_Item")
        g_ui_barList[i] = bar	
        bar:SetEvent( "MouseLButtonDown", string.format("NewBW_TopList_ItemClicked(%d)", i))
    end

    g_cur_selIndex = 0
    g_cur_page = 0
    g_cur_pagemax = 0
end

function NewBW_TopList_ListShow()
    -- 先看看显示了多少内容
    local count = NewXBW:GetRankBaseInfo("Count")
    --PushDebugMessage("count"..count)
    for i, ui in (g_ui_barList or {}) do
        NewBW_TopList_SetItem(i, count)
    end

    NewBW_TopList_List:RefreshLayout()
    NewBW_TopList_List:SetScrollPosition4Index(0)
end

function NewBW_TopList_SetItem(index, max_count)
    local bar = g_ui_barList[index]
    if bar == nil then
        return
    end

    if index > max_count then
        bar:Hide()
        return
    end

    local data = NewXBW:GetRankTeamInfo(index-1)
    if data == nil or type(data) ~= "table" then
        bar:Hide()
        return
    end

    bar:Show()

    -- 排名
    local rankTxt = bar:GetSubItem("NewBW_TopList_Number")
    if rankTxt ~= nil then
        rankTxt:SetText("#cfff263"..data.rank)
    end
    -- 排名图标
    local rankImage = bar:GetSubItem("NewBW_TopList_NumberImage")
    if rankImage ~= nil then
        if g_rank_Image[data.rank] ~= nil then
            rankImage:SetProperty("Image", g_rank_Image[data.rank].image)
            rankImage:Show()
            if rankTxt ~= nil then
                rankTxt:SetText("")
            end
        else
            rankImage:Hide()
        end
    end

    -- 总分
    local rankScore = bar:GetSubItem("NewBW_TopList_WinNum")
    if rankScore ~= nil then
        rankScore:SetText("#cfff263"..data.star)
    end
    -- 战队名字
    local rankName = bar:GetSubItem("NewBW_TopList_Name")
    if rankName ~= nil then
        rankName:SetText("#cfff263"..data.name.."@"..DataPool:GetServerName(data.worldid))
    end
end

function NewBW_TopList_OtherShow()
    -- 进行页签的显示
    local selectStage = NewXBW:GetRankBaseInfo("Stage")
    NewBW_TopList_LevelSelect(selectStage)
    -- 进行页签底部内容显示

    local curPage = 0
    local total = NewXBW:GetRankBaseInfo("Total")
    if total > 0 then
        g_cur_page = NewXBW:GetRankBaseInfo("Page")
        g_cur_pagemax = NewXBW:GetRankBaseInfo("PageMax")

        curPage = g_cur_page + 1
    end

    local szPage = tostring(curPage).."/"..tostring(g_cur_pagemax)
	NewBW_TopList_CurrentlyPage:SetText(szPage)

    NewBW_TopList_DownPage:Disable()
    NewBW_TopList_UpPage:Disable()

	-- 有页可翻
	if g_cur_pagemax > 1 then
		if curPage <= 1 then
			NewBW_TopList_DownPage:Enable()
		elseif curPage == g_cur_pagemax then
			NewBW_TopList_UpPage:Enable()
		else
			NewBW_TopList_UpPage:Enable()
			NewBW_TopList_DownPage:Enable()
		end
    end
    
    if g_cur_selIndex > 0 then
        NewBW_TopList_Info:Enable()
    else
        NewBW_TopList_Info:Disable()
    end
end

function NewBW_TopList_LevelSelect(selectIdx)
    if selectIdx >= 5 and selectIdx <= 8 then
        selectIdx = selectIdx - 4
    elseif selectIdx >= 9 and selectIdx <= 12 then
        selectIdx = selectIdx - 8
    end
    
    for i, ui in (g_ui_sel_TabBtnList or {}) do
        --ui:SetCheck(0)
    end

    for i, ui in (g_ui_sel_TabBtnList or {}) do
        if i == selectIdx then
            ui:SetProperty("Selected", "True")
        else
            ui:SetProperty("Selected", "False")
        end
    end

    g_tab_lastselect = selectIdx
end

function NewBW_TopList_ResetUIInfo()

    if (g_NewBW_TopList_LockedTeamFlag == 1) then
        -- 锁定战队榜

       	--卡级服
		local kjtype   = KaJi:LuaFnGetKaJiType(28)
		if kjtype == 1 then
            NewBW_TopList_TextInfo:SetText("#{SJPM_241125_85}")
        else
            NewBW_TopList_TextInfo:SetText("#{SJPM_241125_07}")
        end
        
        NewBW_TopList_CheckBox_Buttontab01:SetCheck(1)
        NewBW_TopList_CheckBox_Buttontab02:SetCheck(0)
    else
        -- 普通榜（非所动战队榜）
        
       	--卡级服
		local kjtype   = KaJi:LuaFnGetKaJiType(28)
		if kjtype == 1 then
            NewBW_TopList_TextInfo:SetText("#{SJPM_241125_71}")
        else
            NewBW_TopList_TextInfo:SetText("#{SJPM_241125_08}")
        end
        
        NewBW_TopList_CheckBox_Buttontab01:SetCheck(0)
        NewBW_TopList_CheckBox_Buttontab02:SetCheck(1)
    end

    for i = 1, g_team_max do
        if (g_ui_barList[i] ~= nil) then
            g_ui_barList[i]:Hide()
        end
    end -- end for

    NewBW_TopList_UpPage:Disable()
    NewBW_TopList_DownPage:Disable()
    NewBW_TopList_CurrentlyPage:SetText("0/0")
    NewBW_TopList_Info:Disable()
end

function NewBW_TopList_RankHelp()

end

-- 开启NPC关注
function NewBW_TopList_BeginCareObject()
    local objSvrId = Get_XParam_INT(0)
	g_NewBW_TopList_CareObjId = DataPool:GetNPCIDByServerID(objSvrId)
    if (g_NewBW_TopList_CareObjId >= 0) then
        g_NewBW_TopList_CareObjSvrId = tonumber(objSvrId)
		this:CareObject(g_NewBW_TopList_CareObjId, 1, "NewBW_TopList")
	end
end

-- 取消NPC关注
function NewBW_TopList_StopCareObject()
	if (g_NewBW_TopList_CareObjId >= 0) then
		this:CareObject(g_NewBW_TopList_CareObjId, 0, "NewBW_TopList")
		g_NewBW_TopList_CareObjId = -1
		g_NewBW_TopList_CareObjSvrId = -1
	end
end

function NewBW_TopList_Close()
    NewBW_TopList_SavePosition()
    this:Hide()
end

function NewBW_TopList_Hide()
    NewBW_TopList_StopCareObject()
    g_tab_lastselect = 0
    g_cur_selIndex = 0

    if(IsWindowShow("NewBW_TeamInfo")) then
        CloseWindow("NewBW_TeamInfo", true);
    end
end

-- 普通榜还是锁定战队榜页签点击事件
function NewBW_TopList_ChangeTopList(nIndex)
    if (nIndex == 0) then
        -- 锁定战队榜
        if (g_NewBW_TopList_LockedTeamFlag > 0) then
            return
        end

        if g_tab_lastselect <= g_TeamRankStage.begin or g_tab_lastselect >= g_TeamRankStage.max then
            g_tab_lastselect = g_TeamRankStage.yingyang
        end
        -- 请求一下新的排行榜数据
        Clear_XSCRIPT()
            Set_XSCRIPT_ScriptID(g_NewBW_TopList_SvrScriptId)
            Set_XSCRIPT_Function_Name("AskPlayerTeamRank")
            Set_XSCRIPT_Parameter(0, g_tab_lastselect)
            Set_XSCRIPT_Parameter(1, 0)
            Set_XSCRIPT_Parameter(2, 1)
            Set_XSCRIPT_ParamCount(3)
        Send_XSCRIPT()
    elseif (nIndex == 1) then
        -- 普通榜
        if (g_NewBW_TopList_LockedTeamFlag <= 0) then
            return
        end

        if g_tab_lastselect <= g_TeamRankStage.begin or g_tab_lastselect >= g_TeamRankStage.max then
            g_tab_lastselect = g_TeamRankStage.yingyang
        end
        -- 请求一下新的排行榜数据
        Clear_XSCRIPT()
            Set_XSCRIPT_ScriptID(g_NewBW_TopList_SvrScriptId)
            Set_XSCRIPT_Function_Name("AskPlayerTeamRank")
            Set_XSCRIPT_Parameter(0, g_tab_lastselect)
            Set_XSCRIPT_Parameter(1, 0)
            Set_XSCRIPT_Parameter(2, 0)
            Set_XSCRIPT_ParamCount(3)
        Send_XSCRIPT()
    else
        -- 按说不应该到这里的
    
    end
end -- end func NewBW_TopList_ChangeTopList()

-- 点击查看信息
function NewBW_TopList_ItemClicked(nIndex)
    if nIndex > 0 then
        g_cur_selIndex = nIndex
        NewBW_TopList_Info:Enable()
    end
end

function NewBW_TopList_ChangeTabIndex(selectIdx)
    --NewBW_TopList_LevelSelect(selectIdx)
    if selectIdx == g_tab_lastselect then
        NewBW_TopList_LevelSelect(g_tab_lastselect)
        return
    end

   -- NewBW_TopList_LevelSelect(g_tab_lastselect)

    if selectIdx <= g_TeamRankStage.begin or selectIdx >= g_TeamRankStage.max then
        return
    end

    -- 重置UI 等排行榜数据下来再刷新
    --NewBW_TopList_ResetUIInfo()

    -- 请求一下新的信息
    Clear_XSCRIPT()
        Set_XSCRIPT_ScriptID(g_NewBW_TopList_SvrScriptId)
        Set_XSCRIPT_Function_Name("AskPlayerTeamRank")
        Set_XSCRIPT_Parameter(0, selectIdx)
        Set_XSCRIPT_Parameter(1, 0)
        Set_XSCRIPT_Parameter(2, g_NewBW_TopList_LockedTeamFlag)
        Set_XSCRIPT_ParamCount(3)
    Send_XSCRIPT()
end

-- 查看详情
function NewBW_TopList_ViewDetailsClick()

    if g_cur_selIndex < 1 then
        return
    end

    PushEvent("XBW_TEAMRANK_OPENTEAMUI", g_cur_selIndex, g_NewBW_TopList_CareObjSvrId)
end

-- 前一页
function NewBW_TopList_Pre_Click(selectIdx)

    if g_tab_lastselect <= g_TeamRankStage.begin or g_tab_lastselect >= g_TeamRankStage.max then
        return
    end

    g_cur_page = NewXBW:GetRankBaseInfo("Page")

    if g_cur_page <= 0 then
        return
    end

    -- 请求一下新的信息
    Clear_XSCRIPT()
        Set_XSCRIPT_ScriptID(g_NewBW_TopList_SvrScriptId)
        Set_XSCRIPT_Function_Name("AskPlayerTeamRank")
        Set_XSCRIPT_Parameter(0, g_tab_lastselect)
        Set_XSCRIPT_Parameter(1, g_cur_page-1)
        Set_XSCRIPT_Parameter(2, g_NewBW_TopList_LockedTeamFlag)
        Set_XSCRIPT_ParamCount(3)
    Send_XSCRIPT()


end

-- 下一页
function NewBW_TopList_Next_Click(selectIdx)

    if g_tab_lastselect <= g_TeamRankStage.begin or g_tab_lastselect >= g_TeamRankStage.max then
        return
    end

    g_cur_page = NewXBW:GetRankBaseInfo("Page")
    g_cur_pagemax = NewXBW:GetRankBaseInfo("PageMax")

    if (g_cur_page + 1) >= g_cur_pagemax then
        return
    end
    
    -- 请求一下新的信息
    Clear_XSCRIPT()
        Set_XSCRIPT_ScriptID(g_NewBW_TopList_SvrScriptId)
        Set_XSCRIPT_Function_Name("AskPlayerTeamRank")
        Set_XSCRIPT_Parameter(0, g_tab_lastselect)
        Set_XSCRIPT_Parameter(1, g_cur_page+1)
        Set_XSCRIPT_Parameter(2, g_NewBW_TopList_LockedTeamFlag)
        Set_XSCRIPT_ParamCount(3)
    Send_XSCRIPT()
end

function NewBW_TopList_SetPosition()
	local nExteriorUnionPos = Variable:GetVariable("XbwTopListUnionPos")
	if nExteriorUnionPos ~= nil then
		NewBW_TopList_Frame:SetProperty("UnifiedPosition", nExteriorUnionPos)
	end
end

function NewBW_TopList_SavePosition()
	Variable:SetVariable("XbwTopListUnionPos", NewBW_TopList_Frame:GetProperty("UnifiedPosition"), 1)
end
