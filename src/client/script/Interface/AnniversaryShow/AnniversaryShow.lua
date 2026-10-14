
local g_AnniversaryShow_Frame_UnifiedPosition
local g_AnniversaryShow_YuanbaoCost1 = 25000
local g_AnniversaryShow_YuanbaoCost2 = 20000
--是否已经购买
local g_AnniversaryShow_IfHaveBuyGift1 = 0 
local g_AnniversaryShow_IfHaveBuyGift2 = 0 
function AnniversaryShow_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- this:RegisterEvent("OPEN_ANNIVERSARY_SHOW", true)
	this:RegisterEvent("OPEN_ANNIVERSARY_BEFORE",false)	
end

function AnniversaryShow_OnLoad()

	g_AnniversaryShow_Frame_UnifiedPosition = AnniversaryShow_Frame_BK:GetProperty("UnifiedPosition")


end

function AnniversaryShow_Help()
	PushEvent("CCSHOP_HELP", 113)
end

function AnniversaryShow_OnEvent(event)

	-- if (event == "OPEN_ANNIVERSARY_SHOW")  then
	-- 	--打开2选1界面时关闭该界面
	-- 	if this:IsVisible() then
	-- 		AnniversaryShow_OnHide()
	-- 		return
	-- 	end
	-- 	AnniversaryShow_Open()
	-- 	this:Show()
	if(event == "UI_COMMAND" and tonumber(arg0) == 2020032604) then
		--打开2选1界面时关闭该界面
		-- if this:IsVisible() then
		-- 	AnniversaryShow_OnHide()
		-- 	return
		-- end
		g_AnniversaryShow_IfHaveBuyGift1 = Get_XParam_INT(0)
		g_AnniversaryShow_IfHaveBuyGift2 = Get_XParam_INT(1)
		AnniversaryShow_Open()
		this:Show()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		AnniversaryShow_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		AnniversaryShow_OnHide()
	elseif event == "ADJEST_UI_POS" then
		AnniversaryShow_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		AnniversaryShow_OnHide()
	end

end

function AnniversaryShow_On_ResetPos()
	AnniversaryShow_Frame_BK:SetProperty("UnifiedPosition", g_AnniversaryShow_Frame_UnifiedPosition)

end

function AnniversaryShow_OnHide()
	this:Hide()
end

function AnniversaryShow_Click(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenBuyFashion")
		Set_XSCRIPT_ScriptID(892595)
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

function AnniversaryShow_Open()
	PushEvent( "CLOSE_ANNIVERSARY_GUIDE" )
	
	AnniversaryShow_Pic_text2:SetText(ScriptGlobal_Format("#{XGSZ_200317_04}",g_AnniversaryShow_YuanbaoCost1))
	AnniversaryShow_Pic1_text2:SetText(ScriptGlobal_Format("#{XGSZ_200317_04}",g_AnniversaryShow_YuanbaoCost2))
	if g_AnniversaryShow_IfHaveBuyGift1 == 1 then
		AnniversaryShow_Pic_text1bk:Show()
		AnniversaryShow_Pic_Btn:Disable()
	else
		AnniversaryShow_Pic_text1bk:Hide()
		AnniversaryShow_Pic_Btn:Enable()
	end
	if g_AnniversaryShow_IfHaveBuyGift2 == 1 then
		AnniversaryShow_Pic1_text1bk:Show()
		AnniversaryShow_Pic1_Btn:Disable()
	else
		AnniversaryShow_Pic1_text1bk:Hide()
		AnniversaryShow_Pic1_Btn:Enable()
	end
end

function AnniversaryShow_OpenRuleLink()
	PushEvent("UI_COMMAND", 2020041101)
end