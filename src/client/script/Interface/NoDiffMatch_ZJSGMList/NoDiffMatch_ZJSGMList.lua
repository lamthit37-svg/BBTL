-- 32强列表
--
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_Timers = 0
local g_Seconds = 1

function NoDiffMatch_ZJSGMList_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("SHOW_FINAL_CORPS_LIST_2018")
end

function NoDiffMatch_ZJSGMList_InitData()

	NoDiffMatch_ZJSGMList_List:RemoveAllItem()

end

function NoDiffMatch_ZJSGMList_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_ZJSGMList_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_ZJSGMList_Frame:GetProperty("UnifiedYPosition");

	NoDiffMatch_ZJSGMList_InitData()
end

function NoDiffMatch_ZJSGMList_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_ZJSGMList_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		NoDiffMatch_ZJSGMList_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		NoDiffMatch_ZJSGMList_InitData()
		this:Hide()
	elseif (event == "SHOW_FINAL_CORPS_LIST_2018") then
		NoDiffMatch_ZJSGMList_InitData()
		NoDiffMatch_ZJSGMListFrame_FullFill_Data()
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_ZJSGMList_ResetPos()
	NoDiffMatch_ZJSGMList_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_ZJSGMList_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function NoDiffMatch_ZJSGMList_Close_Clicked()
	this:Hide()
end

function NoDiffMatch_ZJSGMList_RefreshClicked()
	--回调服务器脚本
	if not NoDiffMatch_ZJSGMList_PassTime(g_Seconds) then
		PushDebugMessage("#{ZYPT_081127_2}");
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnRefreshCorpsList")
		Set_XSCRIPT_ScriptID(892702)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

function NoDiffMatch_ZJSGMList_PassTime(iSeconds)
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
function NoDiffMatch_ZJSGMListFrame_FullFill_Data()
	NoDiffMatch_ZJSGMList_List:SetProperty("SortDirection", "None")
	for i=0,31 do
		local nCorpsID, nCount, nCorpsName = CorpsUI_2018:GetFinalCorpsInfoByIdx(i)
		if nCorpsID < 0 or nCorpsName == "" then
			break
		else
			NoDiffMatch_ZJSGMList_List:AddNewItem(tostring(nCorpsID),0,i)
			NoDiffMatch_ZJSGMList_List:AddNewItem(tostring(nCorpsName),1,i)
			NoDiffMatch_ZJSGMList_List:AddNewItem(tostring(nCount),2,i)
		end
	end
	this:Show()
end

function NoDiffMatch_ZJSGMList_List_On_SelectionChanged()

end
