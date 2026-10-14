--CangPin_tip_Show
--!!!reloadscript =CangPin_tip_Show

local g_CangPinId = 0

local g_FirstShow = 1

function CangPin_tip_Show_PreLoad()
	this:RegisterEvent("OPEN_CANGPIN_ITEM_TIP2", true)
	this:RegisterEvent("SHOW_SUPERTOOLTIP", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

function CangPin_tip_Show_OnLoad()

end

function CangPin_tip_Show_OnEvent(event)	
	if event == "OPEN_CANGPIN_ITEM_TIP2" then
		g_CangPinId = tonumber(arg0)
		SuperTooltips:SendAskItemInfoMsg()
		CangPin_tip_Show_Update()
		CangPin_tip_Show:PositionSelf(0, 0, 1, 1)
		local rH = CangPin_tip_Show:GetProperty("AbsoluteHeight")
		CangPin_tip_Show:SetProperty("AbsoluteXPosition", 0)
		CangPin_tip_Show:SetProperty("AbsoluteYPosition", 0)
		CangPin_tip_Show_Frame:SetProperty("AbsoluteHeight", tostring(rH + 5.0))
		
		if g_FirstShow == 1 then
			CangPin_tip_Show_Frame:CenterWindow()
			g_FirstShow = 0
		end
		
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

function CangPin_tip_Show_Update()
	
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
		local bind_status = SuperTooltips2:LuaFnGetItemBindStatus()
		local have_set_xj_effect = LuaFnIsCangPinSetHaveXianJieEffect(set_id)
		
		local nMoney1, szMoneyDesc1 = SuperTooltips2:GetMoney1()
		local nUnit = SuperTooltips2:GetMoney1Type()
		local isShowJiaoZi = SuperTooltips2:GetIsShowJiaoZi()
		
		local toDisplay = ""
		toDisplay = toDisplay.."CangPin_tip_Show_PageHeader"
		if bind_status == 1 or bind_status == 2 then
			toDisplay = toDisplay..";CangPin_tip_Show_BangDingTitle"
		end
		
		--金钱1
		if nMoney1 ~= nil then
			if isShowJiaoZi == 1 then --交子
				toDisplay = toDisplay .. ";CangPin_tip_Show_MoneyTitle"
			else
				toDisplay = toDisplay .. ";CangPin_tip_Show_MoneyTitle_2"
			end
		end
		
		toDisplay = toDisplay..";CangPin_tip_Show_BaseTitle"
		toDisplay = toDisplay..";CangPin_tip_Show_Base"
		--toDisplay = toDisplay..";CangPin_tip_Show_TeShuTitle"
		--toDisplay = toDisplay..";CangPin_tip_Show_TeShu"
		if have_set_effect == 1 then
			toDisplay = toDisplay..";CangPin_tip_Show_TaoZhuangTitle"
			toDisplay = toDisplay..";CangPin_tip_Show_TaoZhuang"
		end

		if have_set_xj_effect == 1 then
			toDisplay = toDisplay..";CangPin_tip_Show_ZhuHunTitle"
			toDisplay = toDisplay..";CangPin_tip_Show_ZhuHun"
		end
		
		toDisplay = toDisplay..";CangPin_tip_Show_Explain"
		
		CangPin_tip_Show:SetProperty("PageElements", toDisplay)

		CangPin_tip_Show_Level:SetText(tostring(SuperTooltips2:GetDesc1()))
		CangPin_tip_Show_PinZhi:SetText(tostring(SuperTooltips2:GetDesc3()))
		
		CangPin_tip_Show_Icon:SetImage(SuperTooltips2:GetIconName())
		
		strTemp = ScriptGlobal_Format("#{CPSJ_260112_55}", tostring(SuperTooltips2:GetTitle()))
		CangPin_tip_Show_Title:SetText(tostring(strTemp))
		
		if bind_status == 1 then
			CangPin_tip_Show_BangDingText:SetText("#{CPSJ_260112_139}")
		elseif bind_status == 2 then
			CangPin_tip_Show_BangDingText:SetText("#{CPSJ_260112_140}")
		else
			CangPin_tip_Show_BangDingText:SetText("")
		end
		
		if nMoney1 ~= nil then
			if isShowJiaoZi == 1 then --交子
				CangPin_tip_Show_MoneyTitle_Text:SetText(szMoneyDesc1)
				CangPin_tip_Show_MoneyTitle_Text2:SetProperty("MoneyNumber", tostring(nMoney1))
			else
				CangPin_tip_Show_MoneyTitle_2_Text:SetText(szMoneyDesc1)
				CangPin_tip_Show_MoneyTitle_2_Text2:SetProperty("MoneyNumber", tostring(nMoney1))
			end
		end

		local qual_str = ""
		if nQuality == 1 then
			qual_str = "#{CPSJ_260112_58}"
			CangPin_tip_Show_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Green")
		elseif nQuality == 2 then
			qual_str = "#{CPSJ_260112_59}"
			CangPin_tip_Show_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Blue")
		elseif nQuality == 3 then
			qual_str = "#{CPSJ_260112_60}"
			CangPin_tip_Show_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Purple")
		elseif nQuality == 4 then
			qual_str = "#{CPSJ_260112_61}"
			CangPin_tip_Show_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Yellow")
		elseif nQuality == 5 then
			qual_str = "#{CPSJ_260112_80}"
			CangPin_tip_Show_PageHeaderBK:SetProperty("Image", "set:CangPin image:CangPin_TipBK_Red")			
		end
		
		local set_name = LuaFnGetCangPinSetName(set_id)
		CangPin_tip_Show_Type:SetText(SuperTooltips2:GetTypeDesc())
		
		if nStar == 0 then
			nStar = 1
		end

		CangPin_tip_Show_BaseTitle:SetText("#{CPSJ_260112_63}")
		local strAttr = SuperTooltips2:LuaFnGetCangPinAttr(g_CangPinId, nStar, 0)
		CangPin_tip_Show_Base:SetText(strAttr)
		
		if have_set_effect == 1 then
			local set_lv = DataPool:LuaFnGetCangPinSetEffectLevel(set_id)
			if nStar == 0 or set_lv == 0 then
				set_lv = 1
			end
			
			CangPin_tip_Show_TaoZhuangTitle:SetText("#{CPSJ_260112_65}")
			local set_effect_desc = LuaFnGetCangPinSetEffectDesc(set_id, set_lv)
			CangPin_tip_Show_TaoZhuang:SetText(tostring(set_effect_desc))
		end
		
		if have_set_xj_effect == 1 then
			local xj_level = DataPool:LuaFnGetCangPinSetXianJieLevel(set_id)
			if xj_level == 0 then
				xj_level = 1
			end
			
			local xj_effect_desc = LuaFnGetCangPinSetXianJieEffectDesc(set_id, xj_level)
			strTemp = ScriptGlobal_Format("#{CPSJ_260112_204}", tostring(xj_effect_desc))
			CangPin_tip_Show_ZhuHun:SetText(tostring(strTemp))
		end
		
		local szExplain = SuperTooltips2:GetExplain()
		CangPin_tip_Show_Explain:SetText(tostring(szExplain))
	end
end

function CangPin_tip_Show_CleanUp()

end

function CangPin_tip_Show_OnHidden()
	CangPin_tip_Show_CleanUp()
end

function CangPin_tip_Show_CloseClicked()
	this:Hide()
end



