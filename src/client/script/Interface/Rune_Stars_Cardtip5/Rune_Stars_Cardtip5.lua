--!!!reloadscript =Rune_Stars_Cardtip5

local g_XingJuanID = 0
local g_Type = 0
local g_Order = 0
local g_Level = 0
local g_FirstShow = 1

local g_QualText = {"#{XZJC_200309_344}", "#{XZJC_200309_345}", "#{XZJC_200309_346}", "#{XZJC_200309_347}"}

local g_QualBKImage = {
	"set:Rune_Star01 image:RuneTipsG",
	"set:Rune_Star01 image:RuneTipsB",
	"set:Rune_Star01 image:RuneTipsZ",
	"set:Rune_Star01 image:RuneTipsH",
}

function Rune_Stars_Cardtip5_PreLoad()
	this:RegisterEvent("SHOW_XINGJUAN_HYPER_TIPS")
end

function Rune_Stars_Cardtip5_OnLoad()	
	
end										

function Rune_Stars_Cardtip5_OnEvent(event)

	if event == "SHOW_SUPERTOOLTIP" then
		this:Hide()
		return
	end
	
	if event == "SHOW_XINGJUAN_HYPER_TIPS" then
		g_XingJuanID = tonumber(arg0)
		g_Order = tonumber(arg3)
		g_Level = tonumber(arg4)
		g_Type = 0
		Rune_Stars_Cardtip5_Update()
		Rune_Stars_Cardtip5:PositionSelf(0, 0, 1, 1)
		
		if(g_FirstShow == 1) then 
			Rune_Stars_Cardtip5_Frame:CenterWindow()
			g_FirstShow = 0
		end	
		this:Show()
	end	
end

function Rune_Stars_Cardtip5_Update()

	if g_Type == 1 then	
		Rune_Stars_Cardtip5_UpdateChip()
		return
	end
	
	if g_XingJuanID > 0 then
	
		local strName = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Name")
		local nUnLocked = 0
		local nLevel = g_Level
		local nOrder = g_Order
		if nLevel > 0 or nOrder > 0 then
			nUnLocked = 1
		end
		
		local nQuality = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Quality")
		local strIcon = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Icon")
		
		local toDisplay = ""
		toDisplay = toDisplay.."Rune_Stars_Cardtip5_PageHeader"
		toDisplay = toDisplay..";Rune_Stars_Cardtip5_ExplainTitle"
		toDisplay = toDisplay..";Rune_Stars_Cardtip5_Explain"
		toDisplay = toDisplay..";Rune_Stars_Cardtip5_TriggerTitle"
		toDisplay = toDisplay..";Rune_Stars_Cardtip5_Trigger"
		toDisplay = toDisplay..";Rune_Stars_Cardtip5_SkillExplain"		
		Rune_Stars_Cardtip5:SetProperty("PageElements", toDisplay)
		
		if g_QualBKImage[nQuality] then
			Rune_Stars_Cardtip5_PageHeaderBK:SetProperty("Image",g_QualBKImage[nQuality])
		end		
		
		if nQuality == 1 then
			Rune_Stars_Cardtip5_Title:SetText("#G"..strName)
		elseif nQuality == 2 then
				Rune_Stars_Cardtip5_Title:SetText("#B"..strName)
		elseif nQuality == 3 then
			Rune_Stars_Cardtip5_Title:SetText("#cbe38ff"..strName)
		elseif nQuality == 4 then
			Rune_Stars_Cardtip5_Title:SetText("#cfff965"..strName)
		else
			Rune_Stars_Cardtip5_Title:SetText(strName)
		end		
		
		Rune_Stars_Cardtip5_Icon:SetImage(strIcon)
		if nUnLocked == 0 then
			Rune_Stars_Cardtip5_Level:SetText("#{XZJC_200309_89}")
		elseif nOrder ~= 5 then	
			local strTemp = ScriptGlobal_Format("#{XZJC_200309_88}", tostring(nOrder), tostring(nLevel))
			Rune_Stars_Cardtip5_Level:SetText(strTemp)
		else
			Rune_Stars_Cardtip5_Level:SetText("#{XZJC_200309_342}")	
		end
		
		if g_QualText[nQuality] then
			Rune_Stars_Cardtip5_LevelInfo:SetText(g_QualText[nQuality])	
		end
		
		Rune_Stars_Cardtip5_TriggerTitleText:SetText("#{XZJC_200309_96}")
		local strAttr = SuperTooltips:Lua_GetXingJuanAttr(g_XingJuanID, nOrder, nLevel)
		Rune_Stars_Cardtip5_Trigger:SetText(strAttr)
		
		Rune_Stars_Cardtip5_ExplainTitleText:SetText("#{XZJC_200309_94}")	
		local strSlotAttr = SuperTooltips:Lua_GetXingJuanSlotAttr(g_XingJuanID, nOrder, nLevel)
		Rune_Stars_Cardtip5_Explain:SetText(strSlotAttr)		
	
		Rune_Stars_Cardtip5_SkillExplain:SetText("#{XZJC_200309_150}")		
	end
end

function Rune_Stars_Cardtip5_UpdateChip()

	if g_XingJuanID > 0 then
	
		local strName = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Name")
		local nQuality = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Quality")
		local strIcon = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "ChipIcon")
		local nActiveNeedChipCount = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "ActiveNeedChipCount")
		
		local toDisplay = ""
		toDisplay = toDisplay.."Rune_Stars_Cardtip5_PageHeader"
		toDisplay = toDisplay..";Rune_Stars_Cardtip5_SkillExplain"		
		Rune_Stars_Cardtip5:SetProperty("PageElements", toDisplay)
		
		if g_QualBKImage[nQuality] then
			Rune_Stars_Cardtip5_PageHeaderBK:SetProperty("Image",g_QualBKImage[nQuality])
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
		Rune_Stars_Cardtip5_Title:SetText(strChipName)		
		
		Rune_Stars_Cardtip5_Icon:SetImage(strIcon)
		
		if g_QualText[nQuality] then
			Rune_Stars_Cardtip5_LevelInfo:SetText(g_QualText[nQuality])	
		end
		
		Rune_Stars_Cardtip5_Level:SetText("")		
		local strTemp = ScriptGlobal_Format("#{XZJC_200309_107}" , tostring(nActiveNeedChipCount), strXjName)
		Rune_Stars_Cardtip5_SkillExplain:SetText(strTemp)
	end
end

function Rune_Stars_Cardtip5_OnCloseClicked()
	this:Hide()
end

function Rune_Stars_Cardtip5_OnHide()
	g_XingJuanID = 0	
end
