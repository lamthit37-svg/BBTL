local g_Timers = 0
local g_Seconds = 1

local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function NoDiffMatch_YXSFBList_PreLoad()
    this:RegisterEvent("SHOW_MATCHLIST_VIDEO_2018")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function NoDiffMatch_YXSFBList_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_YXSFBList_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_YXSFBList_Frame:GetProperty("UnifiedYPosition");

end

function NoDiffMatch_YXSFBList_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_YXSFBList_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NoDiffMatch_YXSFBList_ResetPos()
	elseif( event == "SHOW_MATCHLIST_VIDEO_2018" ) then
		NoDiffMatch_YXSFBList_FillListData()
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function NoDiffMatch_YXSFBList_ClearItemList()
	NoDiffMatch_YXSFBList_List:RemoveAllItem()
end

function NoDiffMatch_YXSFBList_FillListData()
	--NoDiffMatch_YXSFBList_List:RemoveAllItem()
	NoDiffMatch_YXSFBList_ClearItemList()
	local nCount = CorpsUI_2018:GetFightPairCount()
	if nCount <= 0 then
		PushDebugMessage("暂无比赛可以录制")
		return
	end
	
	NoDiffMatch_YXSFBList_List:SetProperty("SortDirection", "None")
	for i=0, nCount-1 do
		local nSceneID,nRedCorpID,nBlueCorpID,RedCorpName,BlueCorpName = CorpsUI_2018:GetFightPairInfoByIdx(i)
		if nSceneID == nil then
			break
		end
		NoDiffMatch_YXSFBList_List:AddNewItem(tostring(i+1),0,i)
		NoDiffMatch_YXSFBList_List:AddNewItem(tostring(nRedCorpID),1,i)
		NoDiffMatch_YXSFBList_List:AddNewItem(RedCorpName,2,i)
		NoDiffMatch_YXSFBList_List:AddNewItem(tostring(nBlueCorpID),3,i)
		NoDiffMatch_YXSFBList_List:AddNewItem(BlueCorpName,4,i)
	end
	this:Show()
end

function NoDiffMatch_YXSFBList_List_On_SelectionChanged()

end

function NoDiffMatch_YXSFBList_CloseClicked()
    this:Hide()
end

function NoDiffMatch_YXSFBList_RefreshClicked()
	if not NoDiffMatch_YXSFBList_PassTime(g_Seconds) then
		PushDebugMessage("#{ZYPT_081127_2}");
		return
	end

	--this:Hide()
	NoDiffMatch_YXSFBList_ClearItemList()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnRefreshMatchList")
		Set_XSCRIPT_ScriptID(892705)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function NoDiffMatch_YXSFBList_EnterClicked()

	local nIndex = NoDiffMatch_YXSFBList_List:GetSelectItem()
	if nIndex == -1 then
		PushDebugMessage("请选择一组战队")
		return
	end
	local nSceneID,nRedCorpID,nBlueCorpID,_,_ = CorpsUI_2018:GetFightPairInfoByIdx(nIndex)
	if nSceneID == nil or nSceneID < 0 then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnEnterBattleField")
		Set_XSCRIPT_ScriptID(892705)
		Set_XSCRIPT_Parameter(0,nSceneID)
		Set_XSCRIPT_Parameter(1,nRedCorpID)
		Set_XSCRIPT_Parameter(2,nBlueCorpID)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_YXSFBList_ResetPos()
	NoDiffMatch_YXSFBList_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_YXSFBList_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function NoDiffMatch_YXSFBList_PassTime(iSeconds)
   local iCur = FindFriendDataPool:GetTickCount()
   if ( iCur - g_Timers < iSeconds * 1000) then
      return false;
   else
      g_Timers = iCur;
   	  return true;
   end
end
