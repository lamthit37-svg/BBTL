
local g_Wufang_Frame_UnifiedPosition;
local g_ItemID = -1
local g_ItemCnt = -1

function KVK_WuFangFuLi_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--=========
--OnLoad
--=========
function KVK_WuFangFuLi_OnLoad()
	
	g_Wufang_Frame_UnifiedPosition = KVK_WuFangFuLi_Frame:GetProperty("UnifiedPosition")
	
end
--=========
--OnEvent
--=========
function KVK_WuFangFuLi_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 20171023 then
		g_ItemID = tonumber(arg1)
		g_ItemCnt,g_MaxCnt = PlayerPackage:GetWuFangFuUseNum(g_ItemID) 

		if g_ItemCnt < 30 then
			KVK_WuFangFuLi_ShengYu:SetText(ScriptGlobal_Format("#{JXPVP_170814_205}", g_MaxCnt-g_ItemCnt,g_MaxCnt))
		else
			KVK_WuFangFuLi_ShengYu:SetText(ScriptGlobal_Format("#{JXPVP_170814_205}", 0,g_MaxCnt))
		end
		
		if g_MaxCnt == 30 then
			KVK_WuFangFuLi_Title:Hide()
			KVK_WuFangFuLi_TitleText:Show()		
		elseif g_MaxCnt == 10 then
			KVK_WuFangFuLi_Title:Show()
			KVK_WuFangFuLi_TitleText:Hide()		
		end
		this:Show()
		return
	elseif ( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
		return		
	elseif (event == "ADJEST_UI_POS" ) then
		KVK_WuFangFuLi_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		KVK_WuFangFuLi_On_ResetPos()		
	end
	
end


function KVK_WuFangFuLi_Click(nIndex)
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("AfterTransferConfirm");
		Set_XSCRIPT_ScriptID(892625);
		Set_XSCRIPT_Parameter(0,nIndex);
		Set_XSCRIPT_Parameter(1,g_ItemID);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
		
	PlayerPackage:UseItem(g_ItemID)	

	this:Hide()
end

function KVK_WuFangFuLi_CloseFrame()
	this:Hide()
end

function KVK_WuFangFuLi_On_ResetPos()
	KVK_WuFangFuLi_Frame:SetProperty("UnifiedPosition", g_Wufang_Frame_UnifiedPosition);
end