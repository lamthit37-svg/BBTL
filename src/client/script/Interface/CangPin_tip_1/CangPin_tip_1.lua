--CangPin_tip_1
--!!!reloadscript =CangPin_tip_1

local g_CangPinId = 0

local g_bIsChip = 0
local g_TipType = 0
local g_MaxStar = 9
local g_MaxQualUpLevel = 4

local g_ClassStr = {
	"#{CPSJ_260112_102}",
	"#{CPSJ_260112_104}",
	"#{CPSJ_260112_103}",
	"#{CPSJ_260112_105}",
}

local g_CangPinStar = 1
local g_QualUpLevel = 0

function CangPin_tip_1_PreLoad()
	this:RegisterEvent("OPEN_CANGPIN_TIP", true)
	this:RegisterEvent("SHOW_SUPERTOOLTIP", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

function CangPin_tip_1_OnLoad()

end

function CangPin_tip_1_OnEvent(event)	
	if event == "OPEN_CANGPIN_TIP" then
		g_CangPinId = tonumber(arg0)
		g_bIsChip = tonumber(arg5)
		g_TipType = tonumber(arg6)
		CangPin_tip_1_Update()
		CangPin_tip_1:PositionSelf(arg1, arg2, arg3, arg4)	
		this:Show()
		return
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "SHOW_SUPERTOOLTIP" then
		this:Hide()
		return
	end
end

function CangPin_tip_1_Update()
	if g_CangPinId > 0 then
		
		if g_bIsChip == 1 then
		--	CangPin_tip_1_Update_Chip()
			return
		end
		
		if g_TipType == 1 then
			CangPin_tip_1_Update_Other()
			return
		end
		
		local strTemp = ""
		local strName = DataPool:LuaFnGetCangPinData(g_CangPinId, "Name")
		local nUnLocked = DataPool:LuaFnGetCangPinData(g_CangPinId, "UnLocked")
		local nStar = DataPool:LuaFnGetCangPinData(g_CangPinId, "Star")
		local nQuality = DataPool:LuaFnGetCangPinData(g_CangPinId, "Quality")
		local strIcon = DataPool:LuaFnGetCangPinData(g_CangPinId, "Icon")
		local nClass = DataPool:LuaFnGetCangPinData(g_CangPinId, "Class")
		local set_id = DataPool:LuaFnGetCangPinData(g_CangPinId, "SetId")
		local have_set_effect = LuaFnIsCangPinSetHaveEffect(set_id)
		local nQualUpLevel = DataPool:LuaFnGetCangPinData(g_CangPinId, "QualUpLevel")
		local have_set_xj_effect = LuaFnIsCangPinSetHaveXianJieEffect(set_id)
		local xj_level = DataPool:LuaFnGetCangPinSetXianJieLevel(set_id)
		
		if g_TipType == 2 then
			if nStar < g_MaxStar then
				nStar = nStar + 1
			end
		end
		
		if g_TipType == 3 then
			if nQualUpLevel < g_MaxQualUpLevel then
				nQualUpLevel = nQualUpLevel + 1
			end
			xj_level = DataPool:LuaFnGetCangPinSetTempXianJieLevel(set_id, g_CangPinId, nQualUpLevel)
		elseif g_TipType == 4 then
			nQualUpLevel = 0
			xj_level = DataPool:LuaFnGetCangPinSetTempXianJieLevel(set_id, g_CangPinId, nQualUpLevel)
		end
		
		local nQualUpRate = LuaFnGetCangPinQualUpRate(g_CangPinId, nQualUpLevel)
		
		local toDisplay = ""
		toDisplay = toDisplay.."CangPin_tip_1_PageHeader"
		toDisplay = toDisplay..";CangPin_tip_1_BaseTitle"
		toDisplay = toDisplay..";CangPin_tip_1_Base"
		if have_set_effect == 1 then
			toDisplay = toDisplay..";CangPin_tip_1_TaoZhuangTitle"
			toDisplay = toDisplay..";CangPin_tip_1_TaoZhuang"
		end
		
		if have_set_xj_effect == 1 then
			toDisplay = toDisplay..";CangPin_tip_1_ZhuHunTitle"
			toDisplay = toDisplay..";CangPin_tip_1_ZhuHun"
		end
		
		CangPin_tip_1:SetProperty("PageElements", toDisplay)
		
		if nQualUpLevel == g_MaxQualUpLevel then
			strName = DataPool:LuaFnGetCangPinData(g_CangPinId, "QualUpName")
			strIcon = DataPool:LuaFnGetCangPinData(g_CangPinId, "QualUpIcon")
		end
		
		strTemp = ScriptGlobal_Format("#{CPSJ_260112_55}", tostring(strName))
		CangPin_tip_1_Title:SetText(tostring(strTemp))		
		CangPin_tip_1_Icon:SetImage(tostring(strIcon))
		
		if nUnLocked ~= 1 then
			CangPin_tip_1_Level:SetText("#{CPSJ_260112_56}")
		else
			strTemp = ScriptGlobal_Format("#{CPSJ_260112_57}", tostring(nStar))
			CangPin_tip_1_Level:SetText(tostring(strTemp))
		end
		
		if nQuality == 1 then
			CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_58}")
			CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Green")
		elseif nQuality == 2 then
			CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_59}")
			CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Blue")
		elseif nQuality == 3 then
			CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_60}")
			CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Purple")
		elseif nQuality == 4 then
			if nQualUpLevel == 0 then
				CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_200}")
				CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Yellow")
			elseif nQualUpLevel == g_MaxQualUpLevel then
				CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_202}")
				CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Red")
			else
				strTemp = ScriptGlobal_Format("#{CPSJ_260112_201}", tostring(nQualUpLevel))
				CangPin_tip_1_PinZhi:SetText(strTemp)
				CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Yellow")
			end
		elseif nQuality == 5 then
			CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_80}")
			CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Red")
		else
			CangPin_tip_1_PinZhi:SetText("")
		end
		
		local set_name = LuaFnGetCangPinSetName(set_id)
		strTemp = ScriptGlobal_Format("#{CPSJ_260112_62}", tostring(g_ClassStr[nClass + 1]), tostring(set_name))
		CangPin_tip_1_Type:SetText(tostring(strTemp))
		
		if nStar == 0 then
			nStar = 1
		end
		CangPin_tip_1_BaseTitle:SetText("#{CPSJ_260112_63}")
		
		local strAttr = SuperTooltips:LuaFnGetCangPinAttr(g_CangPinId, nStar, nQualUpLevel)
		CangPin_tip_1_Base:SetText(strAttr)
		
		if have_set_effect == 1 then
			local set_lv = DataPool:LuaFnGetCangPinSetEffectLevel(set_id)
			if nStar == 0 or set_lv == 0 then
				set_lv = 1
			end
			local set_effect_desc = LuaFnGetCangPinSetEffectDesc(set_id, set_lv)
			CangPin_tip_1_TaoZhuang:SetText(tostring(set_effect_desc))
		end
		
		if have_set_xj_effect == 1 then
			if xj_level == 0 then
				xj_level = 1
			end
			local xj_effect_desc = LuaFnGetCangPinSetXianJieEffectDesc(set_id, xj_level)
			strTemp = ScriptGlobal_Format("#{CPSJ_260112_204}", tostring(xj_effect_desc))
			CangPin_tip_1_ZhuHun:SetText(tostring(strTemp))
		end
	end
end

function CangPin_tip_1_Update_Other()
	if g_CangPinId > 0 then

		local strTemp = ""
		local strName = DataPool:LuaFnGetOtherCangPinData(g_CangPinId, "Name")
		local nUnLocked = DataPool:LuaFnGetOtherCangPinData(g_CangPinId, "UnLocked")
		local nStar = DataPool:LuaFnGetOtherCangPinData(g_CangPinId, "Star")
		local nQuality = DataPool:LuaFnGetOtherCangPinData(g_CangPinId, "Quality")
		local strIcon = DataPool:LuaFnGetOtherCangPinData(g_CangPinId, "Icon")
		local nClass = DataPool:LuaFnGetOtherCangPinData(g_CangPinId, "Class")
		local set_id = DataPool:LuaFnGetOtherCangPinData(g_CangPinId, "SetId")		
		local have_set_effect = LuaFnIsCangPinSetHaveEffect(set_id)
		local nQualUpLevel = DataPool:LuaFnGetOtherCangPinData(g_CangPinId, "QualUpLevel")
		local nQualUpRate = LuaFnGetCangPinQualUpRate(g_CangPinId, nQualUpLevel)
		local have_set_xj_effect = LuaFnIsCangPinSetHaveXianJieEffect(set_id)
		
		local toDisplay = ""
		toDisplay = toDisplay.."CangPin_tip_1_PageHeader"
		toDisplay = toDisplay..";CangPin_tip_1_BaseTitle"
		toDisplay = toDisplay..";CangPin_tip_1_Base"
		if have_set_effect == 1 then
			toDisplay = toDisplay..";CangPin_tip_1_TaoZhuangTitle"
			toDisplay = toDisplay..";CangPin_tip_1_TaoZhuang"
		end
		
		if have_set_xj_effect == 1 then
			toDisplay = toDisplay..";CangPin_tip_1_ZhuHunTitle"
			toDisplay = toDisplay..";CangPin_tip_1_ZhuHun"
		end
		
		CangPin_tip_1:SetProperty("PageElements", toDisplay)
		
		if nQualUpLevel == g_MaxQualUpLevel then
			strName = DataPool:LuaFnGetOtherCangPinData(g_CangPinId, "QualUpName")
			strIcon = DataPool:LuaFnGetCangPinData(g_CangPinId, "QualUpIcon")
		end
		strTemp = ScriptGlobal_Format("#{CPSJ_260112_55}", tostring(strName))
		CangPin_tip_1_Title:SetText(tostring(strTemp))		
		CangPin_tip_1_Icon:SetImage(tostring(strIcon))
		
		if nUnLocked ~= 1 then
			CangPin_tip_1_Level:SetText("#{CPSJ_260112_56}")
		else
			strTemp = ScriptGlobal_Format("#{CPSJ_260112_57}", tostring(nStar))
			CangPin_tip_1_Level:SetText(tostring(strTemp))
		end
		
		if nQuality == 1 then
			CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_58}")
			CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Green")
		elseif nQuality == 2 then
			CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_59}")
			CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Blue")
		elseif nQuality == 3 then
			CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_60}")
			CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Purple")
		elseif nQuality == 4 then
			if nQualUpLevel == 0 then
				CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_200}")
				CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Yellow")
			elseif nQualUpLevel == g_MaxQualUpLevel then
				CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_202}")
				CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Red")
			else
				strTemp = ScriptGlobal_Format("#{CPSJ_260112_201}", tostring(nQualUpLevel))
				CangPin_tip_1_PinZhi:SetText(strTemp)
				CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Yellow")
			end
		elseif nQuality == 5 then
			CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_80}")
			CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Red")
		else
			CangPin_tip_1_PinZhi:SetText("")
		end
		
		local set_name = LuaFnGetCangPinSetName(set_id)
		strTemp = ScriptGlobal_Format("#{CPSJ_260112_62}", tostring(g_ClassStr[nClass + 1]), tostring(set_name))
		CangPin_tip_1_Type:SetText(tostring(strTemp))
		
		if nStar == 0 then
			nStar = 1
		end
		CangPin_tip_1_BaseTitle:SetText("#{CPSJ_260112_63}")
		local strAttr = SuperTooltips:LuaFnGetCangPinAttr(g_CangPinId, nStar, nQualUpLevel)
		CangPin_tip_1_Base:SetText(strAttr)
		
		if have_set_effect == 1 then
			local set_lv = DataPool:LuaFnGetOtherCangPinSetEffectLevel(set_id)
			if nStar == 0 or set_lv == 0 then
				set_lv = 1
			end
			local set_effect_desc = LuaFnGetCangPinSetEffectDesc(set_id, set_lv)
			CangPin_tip_1_TaoZhuang:SetText(tostring(set_effect_desc))
		end
		
		if have_set_xj_effect == 1 then
			local xj_level = DataPool:LuaFnGetOtherCangPinSetXianJieLevel(set_id)
			if xj_level == 0 then
				xj_level = 1
			end
			local xj_effect_desc = LuaFnGetCangPinSetXianJieEffectDesc(set_id, xj_level)
			strTemp = ScriptGlobal_Format("#{CPSJ_260112_204}", tostring(xj_effect_desc))
			CangPin_tip_1_ZhuHun:SetText(tostring(strTemp))
		end
	end
end

function CangPin_tip_1_Update_Chip()
	if g_CangPinId > 0 then
		
		local strTemp = ""
		local strName = DataPool:LuaFnGetCangPinData(g_CangPinId, "ChipName")
		local nUnLocked = DataPool:LuaFnGetCangPinData(g_CangPinId, "UnLocked")
		local nStar = DataPool:LuaFnGetCangPinData(g_CangPinId, "Star")
		local nQuality = DataPool:LuaFnGetCangPinData(g_CangPinId, "Quality")
		local strIcon = DataPool:LuaFnGetCangPinData(g_CangPinId, "ChipIcon")
		local nClass = DataPool:LuaFnGetCangPinData(g_CangPinId, "Class")
		local set_id = DataPool:LuaFnGetCangPinData(g_CangPinId, "SetId")
		local nQualUpLevel = DataPool:LuaFnGetCangPinData(g_CangPinId, "QualUpLevel")
		local nQualUpRate = LuaFnGetCangPinQualUpRate(g_CangPinId, nQualUpLevel)
		
		local toDisplay = ""
		toDisplay = toDisplay.."CangPin_tip_1_PageHeader"
		toDisplay = toDisplay..";CangPin_tip_1_BaseTitle"
		toDisplay = toDisplay..";CangPin_tip_1_Base"
		toDisplay = toDisplay..";CangPin_tip_1_TaoZhuangTitle"
		toDisplay = toDisplay..";CangPin_tip_1_TaoZhuang"
		
		CangPin_tip_1:SetProperty("PageElements", toDisplay)
		
		strTemp = ScriptGlobal_Format("#{CPSJ_260112_55}", tostring(strName))
		CangPin_tip_1_Title:SetText(tostring(strTemp))
		
		CangPin_tip_1_Icon:SetImage(tostring(strIcon))
		
		CangPin_tip_1_Level:SetText("")
		
		if nQuality == 1 then
			CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_58}")
			CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Green")
		elseif nQuality == 2 then
			CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_59}")
			CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Blue")
		elseif nQuality == 3 then
			CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_60}")
			CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Purple")
		elseif nQuality == 4 then
			if nQualUpLevel == 0 then
				CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_200}")
				CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Yellow")
			elseif nQualUpLevel == g_MaxQualUpLevel then
				CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_202}")
				CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Red")
			else
				strTemp = ScriptGlobal_Format("#{CPSJ_260112_201}", tostring(nQualUpLevel))
				CangPin_tip_1_PinZhi:SetText(strTemp)
				CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Yellow")
			end
		elseif nQuality == 5 then
			CangPin_tip_1_PinZhi:SetText("#{CPSJ_260112_80}")
			CangPin_tip_1_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Red")
		else
			CangPin_tip_1_PinZhi:SetText("")
		end
		
		local set_name = LuaFnGetCangPinSetName(set_id)
		strTemp = ScriptGlobal_Format("#{CPSJ_260112_62}", tostring(set_name))
		CangPin_tip_1_Type:SetText(tostring(strTemp))
		
		CangPin_tip_1_BaseTitle:SetText("")
		CangPin_tip_1_Base:SetText("")
		--if nStar == 0 then
		--	nStar = 1
		--end
		--CangPin_tip_1_BaseTitle:SetText("#{CPSJ_260112_63}")
		--local strAttr = SuperTooltips:LuaFnGetCangPinAttr(g_CangPinId, nStar)
		--CangPin_tip_1_Base:SetText(strAttr)
	end
end

function CangPin_tip_1_CleanUp()

end

function CangPin_tip_1_OnHidden()
	CangPin_tip_1_CleanUp()
end



