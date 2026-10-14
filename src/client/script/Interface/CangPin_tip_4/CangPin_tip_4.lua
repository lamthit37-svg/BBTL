--CangPin_tip_4
--!!!reloadscript =CangPin_tip_4

local g_CangPinId = 0

function CangPin_tip_4_PreLoad()
	this:RegisterEvent("OPEN_CANGPIN_ITEM_TIP", true)
	this:RegisterEvent("SHOW_SUPERTOOLTIP", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

function CangPin_tip_4_OnLoad()

end

function CangPin_tip_4_OnEvent(event)	
	if event == "OPEN_CANGPIN_ITEM_TIP" then
		g_CangPinId = tonumber(arg0)
		SuperTooltips:SendAskItemInfoMsg()
		CangPin_tip_4_Update()
		CangPin_tip_4:PositionSelf(arg1, arg2, arg3, arg4)
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

function CangPin_tip_4_Update()
	
	if g_CangPinId > 0 then
		
		local strTemp = ""
		local strName = DataPool:LuaFnGetCangPinData(g_CangPinId, "Name")
		local nUnLocked = DataPool:LuaFnGetCangPinData(g_CangPinId, "UnLocked")
		local nStar = DataPool:LuaFnGetCangPinData(g_CangPinId, "Star")
		local nQuality = DataPool:LuaFnGetCangPinData(g_CangPinId, "Quality")
		local strIcon = DataPool:LuaFnGetCangPinData(g_CangPinId, "Icon")
		local nClass = DataPool:LuaFnGetCangPinData(g_CangPinId, "Class")
		local set_id = DataPool:LuaFnGetCangPinData(g_CangPinId, "SetId")
		local have_set_effect = LuaFnIsCangPinSetHaveEffect(set_id)
		local bind_status = SuperTooltips:LuaFnGetItemBindStatus()
		local have_set_xj_effect = LuaFnIsCangPinSetHaveXianJieEffect(set_id)
		
		local nMoney1, szMoneyDesc1 = SuperTooltips:GetMoney1()
		local nUnit = SuperTooltips:GetMoney1Type()
		local isShowJiaoZi = SuperTooltips:GetIsShowJiaoZi()
		
		local toDisplay = ""
		toDisplay = toDisplay.."CangPin_tip_4_PageHeader"
		if bind_status == 1 or bind_status == 2 then
			toDisplay = toDisplay..";CangPin_tip_4_BangDingTitle"
		end
		
		--金钱1
		if nMoney1 ~= nil then
			if isShowJiaoZi == 1 then --交子
				toDisplay = toDisplay .. ";CangPin_tip_4_MoneyTitle"
			else
				toDisplay = toDisplay .. ";CangPin_tip_4_MoneyTitle_2"
			end
		end
		
		toDisplay = toDisplay..";CangPin_tip_4_BaseTitle"
		toDisplay = toDisplay..";CangPin_tip_4_Base"
		--toDisplay = toDisplay..";CangPin_tip_4_TeShuTitle"
		--toDisplay = toDisplay..";CangPin_tip_4_TeShu"
		if have_set_effect == 1 then
			toDisplay = toDisplay..";CangPin_tip_4_TaoZhuangTitle"
			toDisplay = toDisplay..";CangPin_tip_4_TaoZhuang"
		end
		
		if have_set_xj_effect == 1 then
			toDisplay = toDisplay..";CangPin_tip_4_ZhuHunTitle"
			toDisplay = toDisplay..";CangPin_tip_4_ZhuHun"
		end
		
		toDisplay = toDisplay..";CangPin_tip_4_Explain"
		
		CangPin_tip_4:SetProperty("PageElements", toDisplay)

		CangPin_tip_4_Level:SetText(tostring(SuperTooltips:GetDesc1()))
		CangPin_tip_4_PinZhi:SetText(tostring(SuperTooltips:GetDesc3()))
		
		CangPin_tip_4_Icon:SetImage(SuperTooltips:GetIconName())
		
		strTemp = ScriptGlobal_Format("#{CPSJ_260112_55}", tostring(SuperTooltips:GetTitle()))
		CangPin_tip_4_Title:SetText(strTemp)

		if bind_status == 1 then
			CangPin_tip_4_BangDingText:SetText("#{CPSJ_260112_139}")
		elseif bind_status == 2 then
			CangPin_tip_4_BangDingText:SetText("#{CPSJ_260112_140}")
		else
			CangPin_tip_4_BangDingText:SetText("")
		end
		
		if nMoney1 ~= nil then
			if isShowJiaoZi == 1 then --交子
				CangPin_tip_4_MoneyTitle_Text:SetText(szMoneyDesc1)
				CangPin_tip_4_MoneyTitle_Text2:SetProperty("MoneyNumber", tostring(nMoney1))
			else
				CangPin_tip_4_MoneyTitle_2_Text:SetText(szMoneyDesc1)
				CangPin_tip_4_MoneyTitle_2_Text2:SetProperty("MoneyNumber", tostring(nMoney1))
			end
		end
		
		local qual_str = ""
		if nQuality == 1 then
			qual_str = "#{CPSJ_260112_58}"
			CangPin_tip_4_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Green")
		elseif nQuality == 2 then
			qual_str = "#{CPSJ_260112_59}"
			CangPin_tip_4_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Blue")
		elseif nQuality == 3 then
			qual_str = "#{CPSJ_260112_60}"
			CangPin_tip_4_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Purple")
		elseif nQuality == 4 then
			qual_str = "#{CPSJ_260112_61}"
			CangPin_tip_4_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Yellow")
		elseif nQuality == 5 then
			qual_str = "#{CPSJ_260112_80}"
			CangPin_tip_4_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Red")			
		end
		
		local set_name = LuaFnGetCangPinSetName(set_id)
		CangPin_tip_4_Type:SetText(SuperTooltips:GetTypeDesc())
		
		if nStar == 0 then
			nStar = 1
		end

		CangPin_tip_4_BaseTitle:SetText("#{CPSJ_260112_63}")
		local strAttr = SuperTooltips:LuaFnGetCangPinAttr(g_CangPinId, nStar, 0)
		CangPin_tip_4_Base:SetText(strAttr)
		
		if have_set_effect == 1 then
			local set_lv = DataPool:LuaFnGetCangPinSetEffectLevel(set_id)
			if nStar == 0 or set_lv == 0 then
				set_lv = 1
			end
			
			CangPin_tip_4_TaoZhuangTitle:SetText("#{CPSJ_260112_65}")
			local set_effect_desc = LuaFnGetCangPinSetEffectDesc(set_id, set_lv)
			CangPin_tip_4_TaoZhuang:SetText(tostring(set_effect_desc))
		end
		
		if have_set_xj_effect == 1 then
			local xj_level = DataPool:LuaFnGetCangPinSetXianJieLevel(set_id)
			if xj_level == 0 then
				xj_level = 1
			end
			
			local xj_effect_desc = LuaFnGetCangPinSetXianJieEffectDesc(set_id, xj_level)
			strTemp = ScriptGlobal_Format("#{CPSJ_260112_204}", tostring(xj_effect_desc))
			CangPin_tip_4_ZhuHun:SetText(tostring(strTemp))
		end
		
		local szExplain = SuperTooltips:GetExplain()
		CangPin_tip_4_Explain:SetText(tostring(szExplain))
	end
end

function CangPin_tip_4_CleanUp()

end

function CangPin_tip_4_OnHidden()
	CangPin_tip_4_CleanUp()
end



