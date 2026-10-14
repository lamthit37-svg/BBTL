--!!!reloadscript =Rune_Stars_Cardtip4

local g_SkillCardID = 0
local g_Other = 0

local g_QualColorText = {"#{XZJC_200309_325}", "#{XZJC_200309_326}", "#{XZJC_200309_327}", "#{XZJC_200309_328}"}
local g_QualText = {"#{XZJC_200309_344}", "#{XZJC_200309_345}", "#{XZJC_200309_346}", "#{XZJC_200309_347}"}

function Rune_Stars_Cardtip4_PreLoad()
	this:RegisterEvent("SHOW_SUPERTOOLTIP",false)
	this:RegisterEvent("SHOW_XINGJUAN_TIPS",false)
	this:RegisterEvent("SHOW_XINGJUAN_CHIP_TIPS",false)
	this:RegisterEvent("SHOW_SKILL_CARD_TIPS",true)
	
end

function Rune_Stars_Cardtip4_OnLoad()	
	g_left = 0
	g_top  = 0
	g_right = 0
	g_bottom = 0
end										

function Rune_Stars_Cardtip4_OnEvent(event)

	if event == "SHOW_SUPERTOOLTIP" then
		this:Hide()
		return
	end
	
	if event == "SHOW_XINGJUAN_TIPS" then
		this:Hide()
		return
	end
	
	if event == "SHOW_XINGJUAN_CHIP_TIPS" then
		this:Hide()
		return
	end
	
	if event == "SHOW_SKILL_CARD_TIPS" then
		g_SkillCardID = tonumber(arg0)
		g_Other = tonumber(arg5)
		Rune_Stars_Cardtip4_Update()
		Rune_Stars_Cardtip4:PositionSelf(arg1, arg2, arg3, arg4)
		this:Show()
	end
	
end

function Rune_Stars_Cardtip4_Update()

	if g_Other == 1 then
		Rune_Stars_Cardtip4_UpdateOther()
		return
	end
	
	if g_SkillCardID > 0 then
	
		local nLevel = DataPool:LuaFnGetSkillCardInfo(g_SkillCardID, "Level")
		local nUnLocked = DataPool:LuaFnGetSkillCardInfo(g_SkillCardID, "UnLocked")
		local strName = DataPool:LuaFnGetSkillCardInfo(g_SkillCardID, "Name")
		local nQuality = DataPool:LuaFnGetSkillCardInfo(g_SkillCardID, "Quality")
		local strIcon = DataPool:LuaFnGetSkillCardInfo(g_SkillCardID, "Icon")
		local nSlot = DataPool:LuaFnGetSkillCardInfo(g_SkillCardID, "Slot")
		
		local toDisplay = ""
		toDisplay = toDisplay.."Rune_Stars_Cardtip4_PageHeader"
		toDisplay = toDisplay..";Rune_Stars_Cardtip4_Explain"
		toDisplay = toDisplay..";Rune_Stars_Cardtip4_Trigger"
		toDisplay = toDisplay..";Rune_Stars_Cardtip4_SkillExplain"		
		Rune_Stars_Cardtip4:SetProperty("PageElements", toDisplay)
		
		if nQuality == 1 then
			Rune_Stars_Cardtip4_Title:SetText("#G"..strName)
		elseif nQuality == 2 then
				Rune_Stars_Cardtip4_Title:SetText("#B"..strName)
		elseif nQuality == 3 then
			Rune_Stars_Cardtip4_Title:SetText("#cbe38ff"..strName)
		elseif nQuality == 4 then
			Rune_Stars_Cardtip4_Title:SetText("#cfff965"..strName)
		else
			Rune_Stars_Cardtip4_Title:SetText(strName)
		end
		Rune_Stars_Cardtip4_Icon:SetImage(strIcon)
		
		if nUnLocked == 0 then
			Rune_Stars_Cardtip4_Level:SetText("#{XZJC_200309_275}")
		else
			local strTemp = ScriptGlobal_Format("#{XZJC_200309_274}" , tostring(nLevel))
			Rune_Stars_Cardtip4_Level:SetText(strTemp)
		end		
		
		Rune_Stars_Cardtip4_LevelInfo:Show()
		if g_QualText[nQuality] then
			Rune_Stars_Cardtip4_LevelInfo:SetText(g_QualText[nQuality])
		else
			Rune_Stars_Cardtip4_LevelInfo:SetText("")
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
		if nSlot > 0 then
			local nXingJuanID = DataPool:LuaFnGetActivedXingJuanID(nSlot)
			if nXingJuanID > 0 then
				nOrderExtra = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
			end		
		end
		
		if nLevel == 0 then
			local strDesc, strSource, _ = DataPool:LuaFnSkillCardDesc(g_SkillCardID, 1, 0)		
			Rune_Stars_Cardtip4_Explain:SetText("#{XZJC_200309_329}#r"..strDesc)		
			Rune_Stars_Cardtip4_SkillExplain:SetText(strSource.."#r"..strSlotInfo)	
		else
			local strDesc, strSource, _ = DataPool:LuaFnSkillCardDesc(g_SkillCardID, nLevel, 0)		
			Rune_Stars_Cardtip4_Explain:SetText("#{XZJC_200309_329}#r"..strDesc)		
			Rune_Stars_Cardtip4_SkillExplain:SetText(strSource.."#r"..strSlotInfo)	
		end		
		
		
		local strExtraDesc = DataPool:LuaFnSkillCardExtraDesc(g_SkillCardID, nOrderExtra)
		if nOrderExtra > 0 then
			Rune_Stars_Cardtip4_Trigger:SetText("#{XZJC_200309_330}#r#G"..strExtraDesc)
		else
			Rune_Stars_Cardtip4_Trigger:SetText("#{XZJC_200309_330}#r"..strExtraDesc)	
		end
	end
	
end

function Rune_Stars_Cardtip4_UpdateOther()
	
	if g_SkillCardID > 0 then
	
		local nLevel = CachedTarget:LuaFnGetSkillCardInfo(g_SkillCardID, "Level")
		local nUnLocked = CachedTarget:LuaFnGetSkillCardInfo(g_SkillCardID, "UnLocked")
		local strName = CachedTarget:LuaFnGetSkillCardInfo(g_SkillCardID, "Name")
		local nQuality = CachedTarget:LuaFnGetSkillCardInfo(g_SkillCardID, "Quality")
		local strIcon = CachedTarget:LuaFnGetSkillCardInfo(g_SkillCardID, "Icon")
		local nSlot = CachedTarget:LuaFnGetSkillCardInfo(g_SkillCardID, "Slot")
		
		local toDisplay = ""
		toDisplay = toDisplay.."Rune_Stars_Cardtip4_PageHeader"
		toDisplay = toDisplay..";Rune_Stars_Cardtip4_Explain"
		toDisplay = toDisplay..";Rune_Stars_Cardtip4_Trigger"
		toDisplay = toDisplay..";Rune_Stars_Cardtip4_SkillExplain"		
		Rune_Stars_Cardtip4:SetProperty("PageElements", toDisplay)
		
		if nQuality == 1 then
			Rune_Stars_Cardtip4_Title:SetText("#G"..strName)
		elseif nQuality == 2 then
				Rune_Stars_Cardtip4_Title:SetText("#B"..strName)
		elseif nQuality == 3 then
			Rune_Stars_Cardtip4_Title:SetText("#cbe38ff"..strName)
		elseif nQuality == 4 then
			Rune_Stars_Cardtip4_Title:SetText("#cfff965"..strName)
		else
			Rune_Stars_Cardtip4_Title:SetText(strName)
		end
		Rune_Stars_Cardtip4_Icon:SetImage(strIcon)
		
		Rune_Stars_Cardtip4_LevelInfo:Show()
		if g_QualText[nQuality] then
			Rune_Stars_Cardtip4_LevelInfo:SetText(g_QualText[nQuality])
		else
			Rune_Stars_Cardtip4_LevelInfo:SetText("")
		end
		
		local strSlotInfo = ""
		if g_QualColorText[nQuality] then
			if nQuality == 4 then
				strSlotInfo = "#{XZJC_200309_348}"
			else
				strSlotInfo = ScriptGlobal_Format("#{XZJC_200309_324}" , g_QualColorText[nQuality])
			end
		end
		
		if nUnLocked == 0 then
			Rune_Stars_Cardtip4_Level:SetText("#{XZJC_200309_275}")
		else
			local strTemp = ScriptGlobal_Format("#{XZJC_200309_274}" , tostring(nLevel))
			Rune_Stars_Cardtip4_Level:SetText(strTemp)
		end		
		
		local nOrderExtra = 0
		if nSlot > 0 then
			local nXingJuanID = CachedTarget:LuaFnGetActivedXingJuanID(nSlot)
			if nXingJuanID > 0 then
				nOrderExtra = CachedTarget:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
			end		
		end
		
		if nLevel == 0 then
			local strDesc, strSource, _ = DataPool:LuaFnSkillCardDesc(g_SkillCardID, 1, 0)		
			Rune_Stars_Cardtip4_Explain:SetText("#{XZJC_200309_329}#r"..strDesc)
			Rune_Stars_Cardtip4_SkillExplain:SetText(strSource.."#r"..strSlotInfo)	
		else
			local strDesc, strSource, _ = DataPool:LuaFnSkillCardDesc(g_SkillCardID, nLevel, 0)			
			Rune_Stars_Cardtip4_Explain:SetText("#{XZJC_200309_329}#r"..strDesc)		
			Rune_Stars_Cardtip4_SkillExplain:SetText(strSource.."#r"..strSlotInfo)	
		end		
		
		
		local strExtraDesc = DataPool:LuaFnSkillCardExtraDesc(g_SkillCardID, nOrderExtra)
		if nOrderExtra > 0 then
			Rune_Stars_Cardtip4_Trigger:SetText("#{XZJC_200309_330}#r#G"..strExtraDesc)
		else
			Rune_Stars_Cardtip4_Trigger:SetText("#{XZJC_200309_330}#r"..strExtraDesc)	
		end	
	end
	

end

function Rune_Stars_Cardtip4_ClearText()

end

function Rune_Stars_Cardtip4_OnHide()
	g_SkillCardID = 0
end
