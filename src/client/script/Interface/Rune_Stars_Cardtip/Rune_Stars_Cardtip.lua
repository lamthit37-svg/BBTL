--!!!reloadscript =Rune_Stars_Cardtip

local g_XingJuanID = 0
local g_left, g_top, g_right, g_bottom
local g_Type = 0
local g_Other = 0

local g_QualText = {"#{XZJC_200309_344}", "#{XZJC_200309_345}", "#{XZJC_200309_346}", "#{XZJC_200309_347}"}

local g_QualBKImage = {
	"set:Rune_Star01 image:RuneTipsG",
	"set:Rune_Star01 image:RuneTipsB",
	"set:Rune_Star01 image:RuneTipsZ",
	"set:Rune_Star01 image:RuneTipsH",
}


function Rune_Stars_Cardtip_PreLoad()
	this:RegisterEvent("SHOW_SUPERTOOLTIP",false)
	this:RegisterEvent("SHOW_XINGJUAN_TIPS")
	this:RegisterEvent("SHOW_XINGJUAN_CHIP_TIPS")
	this:RegisterEvent("SHOW_SKILL_CARD_TIPS",false)
	
end

function Rune_Stars_Cardtip_OnLoad()	

end										

function Rune_Stars_Cardtip_OnEvent(event)

	if event == "SHOW_SUPERTOOLTIP" then
		this:Hide()
		return
	end
	
	if event == "SHOW_XINGJUAN_TIPS" then
		g_XingJuanID = tonumber(arg0)
		g_Type = 0
		g_Other = tonumber(arg5)
		Rune_Stars_Cardtip_Update()
		Rune_Stars_Cardtip:PositionSelf(arg1, arg2, arg3, arg4)	
		this:Show()
	end
	
	if event == "SHOW_XINGJUAN_CHIP_TIPS" then
		g_XingJuanID = tonumber(arg0)
		g_Type = 1
		g_Other = 0
		Rune_Stars_Cardtip_Update()
		Rune_Stars_Cardtip:PositionSelf(arg1, arg2, arg3, arg4)
		this:Show()
	end
	
	if event == "SHOW_SKILL_CARD_TIPS" then
		this:Hide()
		return
	end
	
end

function Rune_Stars_Cardtip_Update()
	
	if g_Other == 1 then
		Rune_Stars_Cardtip_UpdateOther()
		return
	end
	
	if g_Type == 1 then	
		Rune_Stars_Cardtip_UpdateChip()
		return
	end
	
	if g_XingJuanID > 0 then
	
		local strName = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Name")
		local nUnLocked = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "UnLocked")
		local nLevel = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Level")
		local nSlot = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Slot")
		local nOrder = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Order")
		local nQuality = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Quality")
		local strIcon = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Icon")
		
		local toDisplay = ""
		toDisplay = toDisplay.."Rune_Stars_Cardtip_PageHeader"
	
		toDisplay = toDisplay..";Rune_Stars_Cardtip_ExplainTitle"	
		toDisplay = toDisplay..";Rune_Stars_Cardtip_Explain"
		
		toDisplay = toDisplay..";Rune_Stars_Cardtip_TriggerTitle"
		toDisplay = toDisplay..";Rune_Stars_Cardtip_Trigger"

		toDisplay = toDisplay..";Rune_Stars_Cardtip_SkillExplain"		
		
		Rune_Stars_Cardtip:SetProperty("PageElements", toDisplay)
		
		if g_QualBKImage[nQuality] then
			Rune_Stars_Cardtip_PageHeaderBK:SetProperty("Image",g_QualBKImage[nQuality])
		end
		
		if nQuality == 1 then
			Rune_Stars_Cardtip_Title:SetText("#G"..strName)
		elseif nQuality == 2 then
				Rune_Stars_Cardtip_Title:SetText("#B"..strName)
		elseif nQuality == 3 then
			Rune_Stars_Cardtip_Title:SetText("#cbe38ff"..strName)
		elseif nQuality == 4 then
			Rune_Stars_Cardtip_Title:SetText("#cfff965"..strName)
		else
			Rune_Stars_Cardtip_Title:SetText(strName)
		end		
		
		Rune_Stars_Cardtip_Icon:SetImage(strIcon)
		if nUnLocked == 0 then
			Rune_Stars_Cardtip_Level:SetText("#{XZJC_200309_89}")
		elseif nOrder ~= 5 then	
			local strTemp = ScriptGlobal_Format("#{XZJC_200309_88}", tostring(nOrder), tostring(nLevel))
			Rune_Stars_Cardtip_Level:SetText(strTemp)
		else
			Rune_Stars_Cardtip_Level:SetText("#{XZJC_200309_342}")	
		end
		
		if g_QualText[nQuality] then
			Rune_Stars_Cardtip_LevelInfo:SetText(g_QualText[nQuality])	
		end
		
		Rune_Stars_Cardtip_TriggerTitleText:SetText("#{XZJC_200309_96}")
		local strAttr = SuperTooltips:Lua_GetXingJuanAttr(g_XingJuanID, nOrder, nLevel)
		Rune_Stars_Cardtip_Trigger:SetText(strAttr)
		
		Rune_Stars_Cardtip_ExplainTitleText:SetText("#{XZJC_200309_94}")
		local strSlotAttr = SuperTooltips:Lua_GetXingJuanSlotAttr(g_XingJuanID, nOrder, nLevel)
		Rune_Stars_Cardtip_Explain:SetText(strSlotAttr)
	
		Rune_Stars_Cardtip_SkillExplain:SetText("#{XZJC_200309_150}")		
	end
end

function Rune_Stars_Cardtip_UpdateChip()

	if g_XingJuanID > 0 then
	
		local strName = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Name")
		local nQuality = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Quality")
		local strIcon = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "ChipIcon")
		local nActiveNeedChipCount = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "ActiveNeedChipCount")
		
		local toDisplay = ""
		toDisplay = toDisplay.."Rune_Stars_Cardtip_PageHeader"
		toDisplay = toDisplay..";Rune_Stars_Cardtip_SkillExplain"		
		Rune_Stars_Cardtip:SetProperty("PageElements", toDisplay)
		
		if g_QualBKImage[nQuality] then
			Rune_Stars_Cardtip_PageHeaderBK:SetProperty("Image",g_QualBKImage[nQuality])
		end
		
		local strChipName = strName.."#{XZJC_200309_276}"
		local strXjName = strName
		if nQuality == 1 then
			strChipName = "#G"..strChipName
			strXjName = "#G"..strXjName
		elseif nQuality == 2 then
			strChipName = "#B"..strChipName
			strXjName = "#B"..strXjName
		elseif nQuality == 3 then
			strChipName = "#cbe38ff"..strChipName
			strXjName = "#cbe38ff"..strXjName
		elseif nQuality == 4 then
			strChipName = "#cfff965"..strChipName
			strXjName = "#cfff965"..strXjName
		end
		Rune_Stars_Cardtip_Title:SetText(strChipName)		
		
		Rune_Stars_Cardtip_Icon:SetImage(strIcon)
		
		if g_QualText[nQuality] then
			Rune_Stars_Cardtip_LevelInfo:SetText(g_QualText[nQuality])	
		end
		
		Rune_Stars_Cardtip_Level:SetText("")		
		local strTemp = ScriptGlobal_Format("#{XZJC_200309_107}" , tostring(nActiveNeedChipCount), strXjName)
		Rune_Stars_Cardtip_SkillExplain:SetText(strTemp)
	end
end

function Rune_Stars_Cardtip_UpdateOther()
	
	if g_XingJuanID > 0 then
	
		local strName = CachedTarget:LuaFnGetXingJuanInfo(g_XingJuanID, "Name")
		local nUnLocked = CachedTarget:LuaFnGetXingJuanInfo(g_XingJuanID, "UnLocked")
		local nLevel = CachedTarget:LuaFnGetXingJuanInfo(g_XingJuanID, "Level")
		local nOrder = CachedTarget:LuaFnGetXingJuanInfo(g_XingJuanID, "Order")
		local nQuality = CachedTarget:LuaFnGetXingJuanInfo(g_XingJuanID, "Quality")
		local strIcon = CachedTarget:LuaFnGetXingJuanInfo(g_XingJuanID, "Icon")
		
		local toDisplay = ""
		toDisplay = toDisplay.."Rune_Stars_Cardtip_PageHeader"
	
		toDisplay = toDisplay..";Rune_Stars_Cardtip_ExplainTitle"	
		toDisplay = toDisplay..";Rune_Stars_Cardtip_Explain"
		
		toDisplay = toDisplay..";Rune_Stars_Cardtip_TriggerTitle"
		toDisplay = toDisplay..";Rune_Stars_Cardtip_Trigger"

		toDisplay = toDisplay..";Rune_Stars_Cardtip_SkillExplain"		
		
		Rune_Stars_Cardtip:SetProperty("PageElements", toDisplay)
		
		if g_QualBKImage[nQuality] then
			Rune_Stars_Cardtip_PageHeaderBK:SetProperty("Image",g_QualBKImage[nQuality])
		end
		
		if nQuality == 1 then
			Rune_Stars_Cardtip_Title:SetText("#G"..strName)
		elseif nQuality == 2 then
				Rune_Stars_Cardtip_Title:SetText("#B"..strName)
		elseif nQuality == 3 then
			Rune_Stars_Cardtip_Title:SetText("#cbe38ff"..strName)
		elseif nQuality == 4 then
			Rune_Stars_Cardtip_Title:SetText("#cfff965"..strName)
		else
		Rune_Stars_Cardtip_Title:SetText(strName)
		end
		
		Rune_Stars_Cardtip_Icon:SetImage(strIcon)
		if nUnLocked == 0 then
			Rune_Stars_Cardtip_Level:SetText("#{XZJC_200309_89}")
		elseif nOrder ~= 5 then	
			local strTemp = ScriptGlobal_Format("#{XZJC_200309_88}", tostring(nOrder), tostring(nLevel))
			Rune_Stars_Cardtip_Level:SetText(strTemp)
		else
			Rune_Stars_Cardtip_Level:SetText("#{XZJC_200309_342}")	
		end
		
		if g_QualText[nQuality] then
			Rune_Stars_Cardtip_LevelInfo:SetText(g_QualText[nQuality])	
		end
		
		Rune_Stars_Cardtip_TriggerTitleText:SetText("#{XZJC_200309_96}")
		local strAttr = SuperTooltips:Lua_GetXingJuanAttr(g_XingJuanID, nOrder, nLevel)
		Rune_Stars_Cardtip_Trigger:SetText(strAttr)
		
		Rune_Stars_Cardtip_ExplainTitleText:SetText("#{XZJC_200309_94}")
		local strSlotAttr = SuperTooltips:Lua_GetXingJuanSlotAttr(g_XingJuanID, nOrder, nLevel)
		Rune_Stars_Cardtip_Explain:SetText(strSlotAttr)
		
		Rune_Stars_Cardtip_SkillExplain:SetText("#{XZJC_200309_150}")		
	end
end

function Rune_Stars_Cardtip_ClearText()

end

function Rune_Stars_Cardtip_OnHide()
	g_XingJuanID = 0
end
