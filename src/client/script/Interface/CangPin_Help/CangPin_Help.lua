--CangPin_Help
--!!!reloadscript =CangPin_Help

local g_CangPin_Help_Frame_UnifiedPosition = ""

local g_CurClass = 0
local g_CurSet = 0

function CangPin_Help_PreLoad()
--	this:RegisterEvent("CANGPIN_SHOW_CLASS_EFFECT", true)
--	this:RegisterEvent("CANGPIN_SHOW_SET_EFFECT", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
end

function CangPin_Help_OnLoad()
	g_CangPin_Help_Frame_UnifiedPosition = CangPin_Help_Frame:GetProperty("UnifiedPosition")
end

function CangPin_Help_OnEvent(event)

	if event == "CANGPIN_SHOW_CLASS_EFFECT" then
		g_CurClass = tonumber(arg0)
		CangPin_Help_Update_ClassEffect()
		this:Activate()
		this:Show()		
		return
	end
	
	if event == "CANGPIN_SHOW_SET_EFFECT" then
		g_CurSet = tonumber(arg0)
		CangPin_Help_Update_SetEffect()
		this:Activate()
		this:Show()
		return
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		CangPin_Help_Frame_On_ResetPos()
	end
end

function CangPin_Help_Update_ClassEffect()
	--CangPin_Help_Title:SetText("")
	CangPin_HelpList:ClearAllElement()
	
	if tonumber(g_CurClass) ~= nil then
		local collect_val = DataPool:LuaFnGetCangPinClassCollectValue(g_CurClass)
		local collect_level, _, _ = LuaFnGetCangPinClassLevel(collect_val)
		local strClassEffect = LuaFnGetCangPinClassEffectDesc(g_CurClass, collect_level)
		CangPin_HelpList:AddTextElement(tostring(strClassEffect))
	end
end

function CangPin_Help_Update_SetEffect()
	--CangPin_Help_Title:SetText("")
	CangPin_HelpList:ClearAllElement()
	
	CangPin_HelpList:AddTextElement("#{CPSJ_260112_19}")

	local set_lv = DataPool:LuaFnGetCangPinSetEffectLevel(g_CurSet)
	
	local lv_str = {"#{CPSJ_260112_133}", "#{CPSJ_260112_134}", "#{CPSJ_260112_135}", "#{CPSJ_260112_136}", "#{CPSJ_260112_137}"}
	if tonumber(g_CurSet) ~= nil then
		for i = 1, 5 do
			local set_effect_desc = LuaFnGetCangPinSetEffectDesc(g_CurSet, i)
			local strTmp = ScriptGlobal_Format(lv_str[i], tostring(set_effect_desc))  
			if set_lv == i then
				CangPin_HelpList:AddTextElement("#G"..tostring(strTmp))
			else
				CangPin_HelpList:AddTextElement("#W"..tostring(strTmp))
			end
		end
	end
end

function CangPin_Help_CleanUp()

end

function CangPin_Help_CloseClicked()
	this:Hide()
end

function CangPin_Help_OnHidden()
	CangPin_Help_CleanUp()
end

function CangPin_Help_Frame_On_ResetPos()
	if g_CangPin_Help_Frame_UnifiedPosition ~= nil then
		CangPin_Help_Frame:SetProperty("UnifiedPosition", g_CangPin_Help_Frame_UnifiedPosition)
	end
end

