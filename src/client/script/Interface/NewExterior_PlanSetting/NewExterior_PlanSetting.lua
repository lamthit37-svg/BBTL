
--!!!reloadscript =NewExterior_PlanSetting
local g_NewExterior_PlanSetting_UnifiedPosition = ""

local g_NewExterior_PlanSetting_FangAn_Max = 5
local g_PlanSetting_CurSelShareStyleIdx = 0

local g_PlanSetting_CurName = ""

--===============================================
-- OnLoad()
--===============================================
function NewExterior_PlanSetting_PreLoad()

	this:RegisterEvent("SET_SHARESTYLE_NAME");
	
	this:RegisterEvent("ON_SCENE_TRANS",false)
	this:RegisterEvent("ON_SERVER_TRANS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("ADJEST_UI_POS",false)	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	
end

function NewExterior_PlanSetting_OnLoad()

	g_NewExterior_PlanSetting_UnifiedPosition = NewExterior_PlanSetting_Frame:GetProperty("UnifiedPosition")
	
end

--===============================================
-- OnEvent()
--===============================================
function NewExterior_PlanSetting_OnEvent( event )
	if event == "SET_SHARESTYLE_NAME" then
		if arg0 and tonumber(arg0) > 0 and tonumber(arg0) <= g_NewExterior_PlanSetting_FangAn_Max then
		
			g_PlanSetting_CurSelShareStyleIdx = tonumber(arg0)
			
			NewExterior_PlanSetting_OnShow()
			
		else
		
			NewExterior_PlanSetting_CloseClick()
			
		end
	end
	
	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
	
		NewExterior_PlanSetting_CloseClick()
		return
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 80081701 ) then
		if this:IsVisible() then
			NewExterior_PlanSetting_CloseClick()
			return
		end
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		NewExterior_PlanSetting_Frame_On_ResetPos()	
		return 
	end
	
end

function NewExterior_PlanSetting_OnShow()

	g_PlanSetting_CurName = Exterior:LuaFnGetExteriorShareInfo(g_PlanSetting_CurSelShareStyleIdx-1, "NAME")
	NewExterior_PlanSetting_Price_NameText:SetText(g_PlanSetting_CurName)

	NewExterior_PlanSetting_InputName:SetText("最长12个字符")
	NewExterior_PlanSetting_InputName:SetProperty("DefaultEditBox", "True");
	NewExterior_PlanSetting_InputName:SetSelected(0, -1)
		
	this:Show()
	
end

--esc
function NewExterior_PlanSetting_OnHidden()

	NewExterior_PlanSetting_InputName:SetProperty("DefaultEditBox", "False");
	
end

function NewExterior_PlanSetting_CloseClick()
	this:Hide()
end

function NewExterior_PlanSetting_OnMouseClick()

	NewExterior_PlanSetting_InputName:SetSelected(0,-1)	
	
end

function NewExterior_PlanSetting_ClickOK()

	local name = NewExterior_PlanSetting_InputName:GetText()	
	if name == nil or name == "" then
		PushDebugMessage("您没有输入新名字")
		return
	end
	
	if g_PlanSetting_CurName == name then
		PushDebugMessage("名字相同")
		return
	end

	Exterior:LuaFnSetExteriorShareName(g_PlanSetting_CurSelShareStyleIdx-1, name)
	
end

function NewExterior_PlanSetting_Frame_On_ResetPos()

	NewExterior_PlanSetting_Frame:SetProperty("UnifiedPosition", g_PlanSetting_Frame_UnifiedPosition)
  
end

--!!!reloadscript =NewExterior_PlanSetting
