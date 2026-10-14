
local g_unifiedposistion
local g_last_optime		= 1		-- 最后操作的时间
local g_op_cd			= 1000	-- 操作CD
local g_list_max		= 16	-- 最多一次显示16个

function ZBS_YXSFBList_PreLoad()
    this:RegisterEvent("ZBS_REST_BATTLEINFO_SHOW")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function ZBS_YXSFBList_OnLoad()
	-- 保存界面的默认相对位置
	g_unifiedposistion = ZBS_YXSFBList_Frame:GetProperty("UnifiedPosition")
end

function ZBS_YXSFBList_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		ZBS_YXSFBList_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ZBS_YXSFBList_ResetPos()
	elseif( event == "ZBS_REST_BATTLEINFO_SHOW" ) then
		ZBS_YXSFBList_FillListData()
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function ZBS_YXSFBList_ClearItemList()
	ZBS_YXSFBList_List:RemoveAllItem()
end

function ZBS_YXSFBList_FillListData()
	--ZBS_YXSFBList_List:RemoveAllItem()
	ZBS_YXSFBList_ClearItemList()
	
	ZBS_YXSFBList_List:SetProperty("SortDirection", "None")
	for i=0, g_list_max-1 do
		local sceneID,teamIDA,teamIDB,teamNameA,teamNameB = ZBS:GetRestBattleInfo(i)
		if sceneID == nil or sceneID <= 0 then
			break
		end
		ZBS_YXSFBList_List:AddNewItem(tostring(i+1),0,i)
		ZBS_YXSFBList_List:AddNewItem(tostring(teamIDA),1,i)
		ZBS_YXSFBList_List:AddNewItem(teamNameA,2,i)
		ZBS_YXSFBList_List:AddNewItem(tostring(teamIDB),3,i)
		ZBS_YXSFBList_List:AddNewItem(teamNameB,4,i)
	end
	this:Show()
end

function ZBS_YXSFBList_List_On_SelectionChanged()

end

function ZBS_YXSFBList_CloseClicked()
    this:Hide()
end

function ZBS_YXSFBList_RefreshClicked()
	-- 不让瞎点
	if ZBS_YXSFBList_CheckOpCD() < 1 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnRefreshMatchList")
		Set_XSCRIPT_ScriptID(998577)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ZBS_YXSFBList_EnterClicked()

	local nIndex = ZBS_YXSFBList_List:GetSelectItem()
	if nIndex == -1 then
		return
	end

	local sceneID,teamIDA,teamIDB,teamNameA,teamNameB = ZBS:GetRestBattleInfo(nIndex)
	if sceneID == nil or sceneID <= 0 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnEnterBattleField")
		Set_XSCRIPT_ScriptID(998577)
		Set_XSCRIPT_Parameter(0,sceneID)
		Set_XSCRIPT_Parameter(1,teamIDA)
		Set_XSCRIPT_Parameter(2,teamIDB)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ZBS_YXSFBList_ResetPos()
	ZBS_YXSFBList_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function ZBS_YXSFBList_CheckOpCD()
	local curTime = FindFriendDataPool:GetTickCount()
	if curTime - g_last_optime < g_op_cd then
		PushDebugMessage("#{WCBZ_220809_49}")
		return 0
	else
		g_last_optime = curTime
	end

	return 1
end
