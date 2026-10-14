
local g_Frame_UnifiedPosition

local g_Anniversary_Fashion_Data = -1

local g_Anniversary_Fashion_DressChipID = 38008355
local g_Anniversary_Fashion_DressChipCount = 4
local g_Anniversary_Fashion_DressItemID = 38008356 --时装礼盒
local g_Anniversary_Fashion_LastStatus = 0

local g_AG_SZLQ_MF = 5494	--19周年应景 时装领奖	

--=========
-- PreLoad
--=========
function Anniversary_Fashion_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false);

end

--=========
-- OnLoad
--=========
function Anniversary_Fashion_OnLoad()
	g_Frame_UnifiedPosition = Anniversary_Fashion_Frame:GetProperty("UnifiedPosition") 
end

--=========
-- OnEvent
--=========
function Anniversary_Fashion_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 8884831 then

		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			Anniversary_Fashion_Update(0)
			this:Show()
			CloseWindow("Anniversary_Gift",true)
		else
			Anniversary_Fashion_OnHiden()
		end
	elseif event == "PACKAGE_ITEM_CHANGED_EX" then

		Anniversary_Fashion_Update(1)

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		Anniversary_Fashion_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		Anniversary_Fashion_On_ResetPos()
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
	
		Anniversary_Fashion_OnHiden();

	end

end

--=========
-- 打开
--=========
function Anniversary_Fashion_Update(bAsk)
--	local theAction = DataPool:CreateActionItemForShow(g_Anniversary_Fashion_DressItemID, 1)
--	if theAction:GetID() ~= 0 then
--		Anniversary_Fashion_Cloth:SetActionItem(theAction:GetID());
--	end
	if Pneuma:GetMF(g_AG_SZLQ_MF) == 1 then
		--已领取
		Anniversary_Fashion_HaveText:SetText("")
		Anniversary_Fashion_OKBtn_Tip:Hide()
		Anniversary_Fashion_OKBtn_Got:Show()
		Anniversary_Fashion_OKBtn:Hide()
	else
		local chipCount = PlayerPackage:CountAvailableItemByIDTable(g_Anniversary_Fashion_DressChipID)
		if chipCount >= 4 then
			Anniversary_Fashion_HaveText:SetText( ScriptGlobal_Format("#{ZNQYJ_220215_15}", chipCount) )--("#G"..chipCount.."/4")
			Anniversary_Fashion_OKBtn_Tip:Show()
		else
			Anniversary_Fashion_HaveText:SetText( ScriptGlobal_Format("#{ZNQYJ_220215_16}", chipCount) )--("#cff0000"..chipCount.."/4")
			Anniversary_Fashion_OKBtn_Tip:Hide()
		end
		Anniversary_Fashion_OKBtn_Got:Hide()
		Anniversary_Fashion_OKBtn:Show()
	end
	if bAsk == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowButtonTips" )
			Set_XSCRIPT_ScriptID(232004)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end

--=========
-- 关闭
--=========
function Anniversary_Fashion_OnHiden()
	this:Hide()
end

--=========
-- 重置
--=========
function Anniversary_Fashion_On_ResetPos()
	Anniversary_Fashion_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

function Anniversary_Fashion_Close()
	this:Hide()
end

function Anniversary_Fashion_ExChange()
	if Pneuma:GetMF(g_AG_SZLQ_MF) == 1 then
		PushDebugMessage("#{ZNQYJ_220215_33}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnExchangeDress")
		Set_XSCRIPT_ScriptID(888483)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
function Anniversary_Fashion_PreviewClk()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Parameter(0, 10128682)
		Set_XSCRIPT_Parameter(1, 291)--hairId
		Set_XSCRIPT_Parameter(2, 212)--faceid
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end
function Anniversary_Fashion_HelpClk()
	PushEvent("QUEST_HELPINFO", "#{ZNQYJ_250228_04}")
end