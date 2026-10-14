
local g_unifiedposistion
local g_last_optime		= 1		-- 最后操作的时间
local g_op_cd			= 1000	-- 操作CD
local g_list_max		= 32	-- 最多一次显示32个

function ZBS_ZJSGMList_PreLoad()
    this:RegisterEvent("ZBS_REST_TEAMINFO_SHOW")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function ZBS_ZJSGMList_OnLoad()
	-- 保存界面的默认相对位置
	g_unifiedposistion = ZBS_ZJSGMList_Frame:GetProperty("UnifiedPosition")
end

function ZBS_ZJSGMList_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		ZBS_ZJSGMList_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ZBS_ZJSGMList_ResetPos()
	elseif( event == "ZBS_REST_TEAMINFO_SHOW" ) then
		ZBS_ZJSGMList_FillListData()
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function ZBS_ZJSGMList_ClearItemList()
	ZBS_ZJSGMList_List:RemoveAllItem()
end

function ZBS_ZJSGMList_FillListData()
	--ZBS_ZJSGMList_List:RemoveAllItem()
	ZBS_ZJSGMList_ClearItemList()
	
	ZBS_ZJSGMList_List:SetProperty("SortDirection", "None")
	for i=0, g_list_max-1 do
		local teamID,count,teamname = ZBS:GetRestTeamInfo(i)
		if teamID == nil or teamID <= 0 then
			break
		end
		ZBS_ZJSGMList_List:AddNewItem(tostring(teamID),0,i)
		ZBS_ZJSGMList_List:AddNewItem(tostring(teamname),1,i)
		ZBS_ZJSGMList_List:AddNewItem(tostring(count),2,i)
	end
	
	this:Show()
end

function ZBS_ZJSGMList_List_On_SelectionChanged()

end

function ZBS_ZJSGMList_CloseClicked()
    this:Hide()
end

function ZBS_ZJSGMList_RefreshClicked()
	-- 不让瞎点
	if ZBS_ZJSGMList_CheckOpCD() < 1 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnRefreshTeamList")
		Set_XSCRIPT_ScriptID(998577)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

-- function ZBS_ZJSGMList_EnterClicked()

-- 	local nIndex = ZBS_ZJSGMList_List:GetSelectItem()
-- 	if nIndex == -1 then
-- 		return
-- 	end
-- 	local teamID,teamname,count = ZBS:GetRestTeamInfo(nIndex)
-- 	if teamID == nil or teamID <= 0 then
-- 		return
-- 	end

-- 	Clear_XSCRIPT()
-- 		Set_XSCRIPT_Function_Name("OnRefreshTeamList")
-- 		Set_XSCRIPT_ScriptID(998577)
-- 		Set_XSCRIPT_ParamCount(0)
-- 	Send_XSCRIPT()
-- end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ZBS_ZJSGMList_ResetPos()
	ZBS_ZJSGMList_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function ZBS_ZJSGMList_CheckOpCD()
	local curTime = FindFriendDataPool:GetTickCount()
	if curTime - g_last_optime < g_op_cd then
		PushDebugMessage("#{WCBZ_220809_49}")
		return 0
	else
		g_last_optime = curTime
	end

	return 1
end
