local g_Timers = 0
local g_Seconds = 1

local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function BS_GMRecord_PreLoad()
    this:RegisterEvent("TXBW_SHOW_MATCHLIST_VIDEO")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function BS_GMRecord_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BS_GMRecord_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BS_GMRecord_Frame:GetProperty("UnifiedYPosition");

end

function BS_GMRecord_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		BS_GMRecord_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BS_GMRecord_ResetPos()
	elseif( event == "TXBW_SHOW_MATCHLIST_VIDEO" ) then
		BS_GMRecord_FillListData()
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function BS_GMRecord_ClearItemList()
	BS_GMRecord_ListInfo:RemoveAllItem()
end

function BS_GMRecord_FillListData()
	--BS_GMRecord_ListInfo:RemoveAllItem()
	BS_GMRecord_ClearItemList()
	local nCount = BWDH2018:GetFightPairCount()
	if nCount <= 0 then
		PushDebugMessage("暂无比赛可以录制")
		return
	end
	
	BS_GMRecord_ListInfo:SetProperty("SortDirection", "None")
	for i=0, nCount-1 do
		local nSceneID,nRedCorpID,nBlueCorpID,RedCorpName,BlueCorpName = BWDH2018:GetFightPairInfoByIdx(i)
		if nSceneID == nil then
			break
		end
		BS_GMRecord_ListInfo:AddNewItem(tostring(i+1),0,i)
		BS_GMRecord_ListInfo:AddNewItem(tostring(nRedCorpID),1,i)
		BS_GMRecord_ListInfo:AddNewItem(RedCorpName,2,i)
		BS_GMRecord_ListInfo:AddNewItem(tostring(nBlueCorpID),3,i)
		BS_GMRecord_ListInfo:AddNewItem(BlueCorpName,4,i)
	end
	this:Show()
end

function BS_GMRecord_List_On_SelectionChanged()

end

function BS_GMRecord_CloseClicked()
    this:Hide()
end

function BS_GMRecord_Renew_Clicked()
	if not BS_GMRecord_PassTime(g_Seconds) then
		PushDebugMessage("#{ZYPT_081127_2}");
		return
	end

	--this:Hide()
	BS_GMRecord_ClearItemList()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnRefreshMatchList")
		Set_XSCRIPT_ScriptID(339002)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function BS_GMRecord_Enter_Clicked()
	local nIndex = BS_GMRecord_ListInfo:GetSelectItem()
	if nIndex == -1 then
		PushDebugMessage("请选择一组战队")
		return
	end
	local nSceneID,nRedCorpID,nBlueCorpID,_,_ = BWDH2018:GetFightPairInfoByIdx(nIndex)
	local nPro_Final_Flag = BWDH2018:GetFightPairFlag()
	if nSceneID == nil or nSceneID < 0 then
		return
	end
	Clear_XSCRIPT()

		if nPro_Final_Flag == 1 then
			Set_XSCRIPT_Function_Name("OnEnterBattleFieldForFinal")
			Set_XSCRIPT_ScriptID(339003)		
		else
			Set_XSCRIPT_Function_Name("OnEnterBattleField")
			Set_XSCRIPT_ScriptID(339002)
		end

		Set_XSCRIPT_Parameter(0,nSceneID)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BS_GMRecord_ResetPos()
	BS_GMRecord_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BS_GMRecord_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BS_GMRecord_PassTime(iSeconds)
   local iCur = FindFriendDataPool:GetTickCount()
   if ( iCur - g_Timers < iSeconds * 1000) then
      return false;
   else
      g_Timers = iCur;
   	  return true;
   end
end

function BS_GMRecord_ListInfo_On_SelectionChanged()
    
end
