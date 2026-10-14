--!!!reloadscript =Rune_Stars_Cardtip6

local g_SkillCardID = 0
local g_Level = 0
local g_QualColorText = {"#{XZJC_200309_325}", "#{XZJC_200309_326}", "#{XZJC_200309_327}", "#{XZJC_200309_328}"}
local g_QualText = {"#{XZJC_200309_344}", "#{XZJC_200309_345}", "#{XZJC_200309_346}", "#{XZJC_200309_347}"}
local g_FirstShow = 1

function Rune_Stars_Cardtip6_PreLoad()
	this:RegisterEvent("SHOW_SKILLCARD_HYPER_TIPS")	
end

function Rune_Stars_Cardtip6_OnLoad()

end										

function Rune_Stars_Cardtip6_OnEvent(event)

	if event == "SHOW_SKILLCARD_HYPER_TIPS" then
		g_SkillCardID = tonumber(arg0)
		g_Level = tonumber(arg4)
		Rune_Stars_Cardtip6_Update()
		Rune_Stars_Cardtip6:PositionSelf(0, 0, 1, 1)
		if g_FirstShow == 1 then 
			Rune_Stars_Cardtip6_Frame:CenterWindow()
			g_FirstShow = 0
		end	
		
		this:Show()
	end
	
end

function Rune_Stars_Cardtip6_Update()

	if g_SkillCardID > 0 then
	
		local nLevel = g_Level
		local nUnLocked = 0
		if g_Level > 0 then
			nUnLocked = 1
		end
		
		local strName = DataPool:LuaFnGetSkillCardInfo(g_SkillCardID, "Name")
		local nQuality = DataPool:LuaFnGetSkillCardInfo(g_SkillCardID, "Quality")
		local strIcon = DataPool:LuaFnGetSkillCardInfo(g_SkillCardID, "Icon")
		
		local toDisplay = ""
		toDisplay = toDisplay.."Rune_Stars_Cardtip6_PageHeader"
		toDisplay = toDisplay..";Rune_Stars_Cardtip6_Explain"
		toDisplay = toDisplay..";Rune_Stars_Cardtip6_Trigger"
		toDisplay = toDisplay..";Rune_Stars_Cardtip6_SkillExplain"		
		Rune_Stars_Cardtip6:SetProperty("PageElements", toDisplay)
		
		if nQuality == 1 then
			Rune_Stars_Cardtip6_Title:SetText("#G"..strName)
		elseif nQuality == 2 then
				Rune_Stars_Cardtip6_Title:SetText("#B"..strName)
		elseif nQuality == 3 then
			Rune_Stars_Cardtip6_Title:SetText("#cbe38ff"..strName)
		elseif nQuality == 4 then
			Rune_Stars_Cardtip6_Title:SetText("#cfff965"..strName)
		else
			Rune_Stars_Cardtip6_Title:SetText(strName)
		end
		Rune_Stars_Cardtip6_Icon:SetImage(strIcon)
		
		if nUnLocked == 0 then
			Rune_Stars_Cardtip6_Level:SetText("#{XZJC_200309_275}")
		else
			local strTemp = ScriptGlobal_Format("#{XZJC_200309_274}" , tostring(nLevel))
			Rune_Stars_Cardtip6_Level:SetText(strTemp)
		end		
		
		Rune_Stars_Cardtip6_LevelInfo:Show()
		if g_QualText[nQuality] then
			Rune_Stars_Cardtip6_LevelInfo:SetText(g_QualText[nQuality])
		else
			Rune_Stars_Cardtip6_LevelInfo:SetText("")
		end
		
		local strSlotInfo = ""
		if g_QualColorText[nQuality] then
			if nQuality == 4 then
				strSlotInfo = "#{XZJC_200309_348}"
			else
				strSlotInfo = ScriptGlobal_Format("#{XZJC_200309_324}" , g_QualColorText[nQuality])
			end
		end
		
		local nOrderExtra = 0
		
		if nLevel == 0 then
			local strDesc, strSource, _ = DataPool:LuaFnSkillCardDesc(g_SkillCardID, 1, 0)		
			Rune_Stars_Cardtip6_Explain:SetText("#{XZJC_200309_329}#r"..strDesc)
			Rune_Stars_Cardtip6_SkillExplain:SetText(strSource.."#r"..strSlotInfo)
		else
			local strDesc, strSource, _ = DataPool:LuaFnSkillCardDesc(g_SkillCardID, nLevel, 0)		
			Rune_Stars_Cardtip6_Explain:SetText("#{XZJC_200309_329}#r"..strDesc)
			Rune_Stars_Cardtip6_SkillExplain:SetText(strSource.."#r"..strSlotInfo)
		end		
		
		local strExtraDesc = DataPool:LuaFnSkillCardExtraDesc(g_SkillCardID, nOrderExtra)
		if nOrderExtra > 0 then
			Rune_Stars_Cardtip6_Trigger:SetText("#{XZJC_200309_330}#r#G"..strExtraDesc)
		else
			Rune_Stars_Cardtip6_Trigger:SetText("#{XZJC_200309_330}#r"..strExtraDesc)	
		end
	end
	
end

function Rune_Stars_Cardtip6_ClearText()

end

function Rune_Stars_Cardtip6_OnCloseClicked()
	this:Hide()
end

function Rune_Stars_Cardtip6_OnHide()
	g_SkillCardID = 0
end
