
local g_Frame_UnifiedPosition

local g_ZongMen_Fashion_Data = -1

local g_ZongMen_Fashion_DressChipID = 38006533
local g_ZongMen_Fashion_DressChipCount = 4
--local g_ZongMen_Fashion_DressItemID = 38006534
--local g_ZongMen_Fashion_LastStatus = 0
--=========
-- PreLoad
--=========
function ZongMen_Fashion_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false);

end

--=========
-- OnLoad
--=========
function ZongMen_Fashion_OnLoad()
	g_Frame_UnifiedPosition = ZongMen_Fashion_Frame:GetProperty("UnifiedPosition") 
end

--=========
-- OnEvent
--=========
function ZongMen_Fashion_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 9988231 then

		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			g_ZongMen_Fashion_Data = Get_XParam_INT(1)
			ZongMen_Fashion_Update(0)
			this:Show()
			CloseWindow("Anniversary_Gift",true)
		else
			ZongMen_Fashion_OnHiden()
		end
	elseif event == "PACKAGE_ITEM_CHANGED_EX" then

		ZongMen_Fashion_Update(1)

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		ZongMen_Fashion_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		ZongMen_Fashion_On_ResetPos()
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
	
		ZongMen_Fashion_OnHiden();

	end

end

--=========
-- 打开
--=========
function ZongMen_Fashion_Update(bAsk)
--	local theAction = DataPool:CreateActionItemForShow(g_ZongMen_Fashion_DressItemID, 1)
--	if theAction:GetID() ~= 0 then
--		ZongMen_Fashion_Cloth:SetActionItem(theAction:GetID());
--	end
	if g_ZongMen_Fashion_Data == 1 then
		--已领取
		ZongMen_Fashion_HaveText:SetText("")
		ZongMen_Fashion_FrameNULL_HaveTextBg:Hide()
		ZongMen_Fashion_OKBtn_Tip:Hide()
		ZongMen_Fashion_OKBtn_Got:Show()
		ZongMen_Fashion_OKBtn:Hide()
	else
		local chipCount = PlayerPackage:CountAvailableItemByIDTable(g_ZongMen_Fashion_DressChipID)
		if chipCount >= 4 then
			ZongMen_Fashion_HaveText:SetText( ScriptGlobal_Format("#{ZNQYJ_220215_15}", chipCount) )--("#G"..chipCount.."/4")
			ZongMen_Fashion_FrameNULL_HaveTextBg:Show()
			ZongMen_Fashion_OKBtn_Tip:Show()
		else
			ZongMen_Fashion_HaveText:SetText( ScriptGlobal_Format("#{ZNQYJ_220215_16}", chipCount) )--("#cff0000"..chipCount.."/4")
			ZongMen_Fashion_FrameNULL_HaveTextBg:Show()
			ZongMen_Fashion_OKBtn_Tip:Hide()
		end
		ZongMen_Fashion_OKBtn_Got:Hide()
		ZongMen_Fashion_OKBtn:Show()
	end
	if bAsk == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnLevelup" )
			Set_XSCRIPT_ScriptID(998842)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end

--=========
-- 关闭
--=========
function ZongMen_Fashion_OnHiden()
	this:Hide()
end

--=========
-- 重置
--=========
function ZongMen_Fashion_On_ResetPos()
	ZongMen_Fashion_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

function ZongMen_Fashion_Close()
	this:Hide()
end

function ZongMen_Fashion_ExChange()
	if g_ZongMen_Fashion_Data == 1 then
		PushDebugMessage("#{ZNQYJ_220215_33}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnExchangeDress")
		Set_XSCRIPT_ScriptID(998823)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
function ZongMen_Fashion_PreviewClk()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Parameter(0, 10127418)
		Set_XSCRIPT_Parameter(1, 210)--hairId
		Set_XSCRIPT_Parameter(2, 156)--faceid
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end