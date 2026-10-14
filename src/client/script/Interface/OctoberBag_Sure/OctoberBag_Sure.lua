
-- 2019国庆稳活跃抽奖
--!!!reloadscript =OctoberBag_Sure

local g_UnifiedPosition = nil

-- PreLoad
function OctoberBag_Sure_PreLoad()
	this:RegisterEvent("GQHYCHOUJIANG_BUYTOKENS", true)
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

-- OnLoad
function OctoberBag_Sure_OnLoad()	
	g_UnifiedPosition = OctoberBag_Sure_Frame:GetProperty("UnifiedPosition");
end

-- OnEvent
function OctoberBag_Sure_OnEvent(event)

	if event == "GQHYCHOUJIANG_BUYTOKENS" then
		
		if tonumber(arg0) == 1 then
			OctoberBag_Sure_UpdateButtonText()
			this:Show()
		else
			this:Hide()		
		end
		
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 89316703 then
		this:Hide()
	end

	
	if(event == "ADJEST_UI_POS") then
		OctoberBag_Sure_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		OctoberBag_Sure_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		OctoberBag_Sure_ClickClose()
	end

end

-- 重置
function OctoberBag_Sure_On_ResetPos()
	OctoberBag_Sure_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition)
end

-- 显示界面文字
function OctoberBag_Sure_UpdateButtonText()
	
	local strTemp = ScriptGlobal_Format( "#{GQHY_190723_46}", "10" )
	OctoberBag_Sure_Button:SetText(strTemp)
	
	local strTemp_1 = ScriptGlobal_Format( "#{GQHY_190723_47}", "95" )
	OctoberBag_Sure_Button1:SetText(strTemp_1)
end

-- 界面关闭
function OctoberBag_Sure_ClickClose()
	this:Hide()
end

-- 购买10代币按钮
function OctoberBag_Sure_ClickBuy10()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyTokens" )
		Set_XSCRIPT_ScriptID( 893167 )
		Set_XSCRIPT_Parameter(0,10)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
end

-- 购买100代币按钮
function OctoberBag_Sure_ClickBuy100()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyTokens" )
		Set_XSCRIPT_ScriptID( 893167 )
		Set_XSCRIPT_Parameter(0,100)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
end
