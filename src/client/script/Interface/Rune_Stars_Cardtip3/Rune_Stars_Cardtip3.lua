--!!!reloadscript =Rune_Stars_Cardtip3

local g_left, g_top, g_right, g_bottom

local g_BaseStr = {	
	"#{XZJC_200309_313}",
	"#{XZJC_200309_314}",
	"#{XZJC_200309_315}",
	"#{XZJC_200309_316}",
	"#{XZJC_200309_317}",
}

local g_BaseStr_Green = {	
	"#{XZJC_200309_318}",
	"#{XZJC_200309_319}",
	"#{XZJC_200309_320}",
	"#{XZJC_200309_321}",
	"#{XZJC_200309_322}",
}

local g_SkillCardID = 0

function Rune_Stars_Cardtip3_PreLoad()
	this:RegisterEvent("OPEN_SKILLCARD_DETAIL",true)
	this:RegisterEvent("RUNE_STARS_TEXTINFO",true)
end

function Rune_Stars_Cardtip3_OnLoad()	
	g_left = 0
	g_top  = 0
	g_right = 0
	g_bottom = 0
end										

function Rune_Stars_Cardtip3_OnEvent(event)
	
	if event == "OPEN_SKILLCARD_DETAIL" then		
		g_SkillCardID = tonumber(arg0)
		Rune_Stars_Cardtip3_Update()
		this:Show()
		this:Activate()
	elseif event == "RUNE_STARS_TEXTINFO" then
		Rune_Stars_TextInfo(arg0, arg1, arg2)
	end
			
end

function Rune_Stars_Cardtip3_Update()

	Rune_Stars_Cardtip3_PageHeader:SetText("#{XZJC_200309_311}")
	Rune_Stars_Cardtip3List:ClearAllElement()
	Rune_Stars_Cardtip3List:AddTextElement("#{XZJC_200309_312}")
	
	local nLevel = DataPool:LuaFnGetSkillCardInfo(g_SkillCardID, "Level")
	
	local strDesc = ""
	for i = 1, 5 do
		--SkillData_V1 第5列
		_,_,strDesc = DataPool:LuaFnSkillCardDesc(g_SkillCardID, i, 0)
		if nLevel == i then
			local strTemp = ScriptGlobal_Format(g_BaseStr[i], tostring(strDesc))
			Rune_Stars_Cardtip3List:AddTextElement("#r"..strTemp.."#{XZJC_200309_354}")
		else
			local strTemp = ScriptGlobal_Format(g_BaseStr[i], tostring(strDesc))
			Rune_Stars_Cardtip3List:AddTextElement("#r"..strTemp)
		end		
	end
	
	Rune_Stars_Cardtip3List:AddTextElement("#r".."#{XZJC_200309_323}")
	
	local strExtraDesc = DataPool:LuaFnSkillCardExtraDesc(g_SkillCardID, 1)
	Rune_Stars_Cardtip3List:AddTextElement("#r#L"..strExtraDesc)
	strExtraDesc = DataPool:LuaFnSkillCardExtraDesc(g_SkillCardID, 3)
	Rune_Stars_Cardtip3List:AddTextElement("#r#L"..strExtraDesc)
	strExtraDesc = DataPool:LuaFnSkillCardExtraDesc(g_SkillCardID, 5)
	Rune_Stars_Cardtip3List:AddTextElement("#r#L"..strExtraDesc)
	
end

function Rune_Stars_Cardtip3_CloseClicked()
	this:Hide()
end

function Rune_Stars_Cardtip3_OnHide()

end

function Rune_Stars_TextInfo(strUIName, strTips, strTitle)
	if not strUIName or not strTips then 
		PushDebugMessage("Rune_Stars_HelpTextInfo Param No nil  UIName:"..(strUIName or "nil").." strTips:"..(strTips or "nil"));
	end
	if strTips == "" then this:Hide() return end
	this:Show()
	this:Activate()
	Rune_Stars_Cardtip3_PageHeader:SetText(strTitle or "")
	Rune_Stars_Cardtip3List:ClearAllElement();
	Rune_Stars_Cardtip3List:AddTextElement(strTips)
end