--
--
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_Timers = 0
local g_Seconds = 1

function BT_CreatTeam_List_Lb_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("DFS_SHOW_MATCHLIST_GM")
end

function BT_CreatTeam_List_Lb_InitData()

	BT_CreatTeam_List_Lb_items:RemoveAllItem()

end

function BT_CreatTeam_List_Lb_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BT_CreatTeam_List_Lb_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BT_CreatTeam_List_Lb_Frame:GetProperty("UnifiedYPosition");

end

function BT_CreatTeam_List_Lb_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BT_CreatTeam_List_Lb_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BT_CreatTeam_List_Lb_ResetPos()

	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		BT_CreatTeam_List_Lb_Hide()

	elseif (event == "DFS_SHOW_MATCHLIST_GM") then
		BT_CreatTeam_List_Lb_InitData()
		BT_CreatTeam_List_LbFrame_FullFill_Data()

	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function BT_CreatTeam_List_Lb_ResetPos()
	BT_CreatTeam_List_Lb_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BT_CreatTeam_List_Lb_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BT_CreatTeam_List_Lb_Hide()
	BT_CreatTeam_List_Lb_InitData()
	this:Hide()
end

function BT_CreatTeam_List_Lb_RefreshClicked()
	--回调服务器脚本
	if not BT_CreatTeam_List_Lb_PassTime(g_Seconds) then
		PushDebugMessage("#{ZYPT_081127_2}");
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnRefreshMatchList")
		Set_XSCRIPT_ScriptID(291514)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

function BT_CreatTeam_List_Lb_PassTime(iSeconds)
   local iCur = FindFriendDataPool:GetTickCount()
   if ( iCur - g_Timers < iSeconds * 1000) then
      return false;
   else
      g_Timers = iCur;
   	  return true;
   end
end

--================================================
-- 填充数据
--================================================
function BT_CreatTeam_List_LbFrame_FullFill_Data()
	BT_CreatTeam_List_Lb_items:SetProperty("SortDirection", "None")
	for i=0, 6 do
		local nWTeamId, nCount, nWTeamName = DFS:GetRoomWTeamInfoByIdx(i)
		if nWTeamId == nil or nWTeamId <= 0 then
			break
		else
			BT_CreatTeam_List_Lb_items:AddNewItem(tostring(nWTeamId), 0, i)
			BT_CreatTeam_List_Lb_items:AddNewItem(tostring(nWTeamName), 1, i)
			BT_CreatTeam_List_Lb_items:AddNewItem(tostring(nCount), 2, i)
		end
	end
	this:Show()
end


