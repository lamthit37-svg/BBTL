local g_unifiedposistion = nil
local g_InitList	= 0
local g_MaxBarNum	= 0
local g_opType		= 0
local g_PageType	= 0
local g_BarList		= {}
local g_configchange	= 0
--==================================下面为固定常量===============================================
local g_curpage = 5
local g_enType = {
	en_GiveUp	= 0,
	en_TemBank	= 1,
	en_All		= 2,

	en_State_InValid	= 0,
	en_State_Normal		= 1,
	en_State_Delete		= 2,
	en_State_Add		= 3,
}
--===================================固定常量END==========================================================

function AutoPickUp_PreLoad()
	this:RegisterEvent("QIANKUNPOT_SHOW")
	this:RegisterEvent("QIANKUNPOT_UPDATE",false)
	this:RegisterEvent("QIANKUNPOT_ERROR",false)
	this:RegisterEvent("QIANKUNPOT_CONFIG",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	--this:RegisterEvent("TOGLE_SKILL_BOOK",false)
	--this:RegisterEvent("TOGLE_LIFE_PAGE",false)
	--this:RegisterEvent("TOGLE_COMMONSKILL_PAGE",false)
	--this:RegisterEvent("OPEN_ZHENFAFREAM",false)
	--this:RegisterEvent("TRIGGER_ZIDONGZHANDOU",false)
	this:RegisterEvent("UI_COMMAND", true)
end

function AutoPickUp_OnLoad()
	g_unifiedposistion = AutoPickUp_Frame:GetProperty("UnifiedPosition")

	AutoPickUp_SetTabColor()
end

function AutoPickUp_OnEvent(event)
	if event == "QIANKUNPOT_SHOW" then
		AutoPickUp_OnShow()
	elseif event == "QIANKUNPOT_UPDATE" then
		AutoPickUp_UpdateItem(tonumber(arg0),tonumber(arg1))
	elseif event == "QIANKUNPOT_ERROR" then
		AutoPickUp_Error(tonumber(arg0))
	elseif event == "ADJEST_UI_POS"  then
		AutoPickUp_OnResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		AutoPickUp_OnResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		AutoPickUp_OnClose()
	elseif event == "QIANKUNPOT_CONFIG" and arg0 ~= "config" then
		AutoPickUp_PageChangeEvent(arg0,arg1,arg2)
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998633007) then	--服务端传数据
	
		local bIsShowHotPoint = Get_XParam_INT(0)	
		if bIsShowHotPoint == 1 then
			AutoPickUp_ZongMenSkill_Tips:Show()	
		else
			AutoPickUp_ZongMenSkill_Tips:Hide()		
		end
	end
end

function AutoPickUp_OnShow()
	AutoPickUp_CleanUp()
	AutoPickUp_SetPosition()
	AutoPickUp_InitList()
	AutoPickUp_UpdateList()
	AutoPickUp_SetTabColor()

	this:Show()
end

function AutoPickUp_InitList()
	if not IsWindowShow("Packet") then
		OpenWindow("Packet")
	end

	g_MaxBarNum = QianKunPotScript:GetQianKunPotMax()
	if g_InitList == 0 then
		for i = 1, g_MaxBarNum do
			local bar = AutoPickUp__Lace:AddChild("AutoPickUp_icon")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			bar:SetProperty("Empty", "False")
			bar:SetEvent("Clicked", string.format("AutoPickUp_ItemClicked(%d)", i))
			bar:SetEvent("RBClicked", string.format("AutoPickUp_ItemBtnClicked(%d)", i))
		
			bar:SetProperty("DraggingEnabled", "True")
			bar:SetProperty("UseDefaultTooltip", "True")
			--bar:GetSubItem("NewExterior_DressBox_SuperListItemActionTip"):Hide()
		
			table.insert(g_BarList, bar)
		end
		g_InitList = 1
	end

	QianKunPotScript:CopyData(g_PageType)
	QianKunPotScript:UpdateAction(g_PageType)
end

function AutoPickUp_BaseUIShow()
	AutoPickUp_Index1:SetCheck(1)
	AutoPickUp_Index2:SetCheck(0)

	if g_PageType == g_enType.en_GiveUp then
		AutoPickUp_Uninstall:SetToolTip("#{QKH_20220802_05}")
		AutoPickUp_Define:SetToolTip("#{QKH_20220802_05}")
	end

	if g_PageType ~= g_enType.en_TemBank then
		AutoPickUp_Uninstall:SetToolTip("#{QKH_20220802_08}")
		AutoPickUp_Define:SetToolTip("#{QKH_20220802_09}")
	end
end

function AutoPickUp_UpdateList()
	local count = QianKunPotScript:GetItemListMax(g_PageType)
	for i = 1, g_MaxBarNum do
		AutoPickUp_SetItem(i, count)
	end
end

function AutoPickUp_SetItem(index, max_count)
	if g_BarList[index] == nil then
		return
	end
	
	--if index > max_count then
	--	g_BarList[index]:Hide()
	--	return
	--end
	
	local bar = g_BarList[index]
	bar:Show()

	local ctrlAction = bar
	local theAction = QianKunPotScript:GetActionItem(g_PageType, index - 1)
	if theAction:GetID() ~= 0 then
		ctrlAction:SetActionItem(theAction:GetID())
	else
		ctrlAction:SetActionItem(-1)
	end
end

function AutoPickUp_UpdateItem(fromtype,itemid)
	--PushDebugMessage("fromtype :"..fromtype.."  itemid: "..itemid)
	if itemid  <= 0 then
		return
	end
	-- 添加标记
	if fromtype == g_enType.en_All then
		local isgpown = QianKunPotScript:IsOwn(g_enType.en_GiveUp, itemid)
		local istbown = QianKunPotScript:IsOwn(g_enType.en_TemBank, itemid)
		local isfull = QianKunPotScript:IsFull(g_PageType)
		if g_PageType == g_enType.en_GiveUp then
			if isgpown > 0 then
				PushDebugMessage("#{QKH_20220802_11}")
				return
			end
			if isfull > 0 then
				PushDebugMessage("#{QKH_20220802_14}")
				return
			end
			if istbown > 0 then
				PushDebugMessage("#{QKH_20220802_12}")
				return
			end
		end
	
		if g_PageType == g_enType.en_TemBank then
			if istbown > 0 then
				PushDebugMessage("#{QKH_20220802_16}")
				return
			end
			if isfull > 0 then
				PushDebugMessage("#{QKH_20220802_15}")
				return
			end
			if isgpown > 0 then
				PushDebugMessage("#{QKH_20220802_17}")
				return
			end
		end

		PushDebugMessage("#{QKH_20220802_13}")
	else
		-- 是否在清单内
		local isown = QianKunPotScript:IsOwn(g_PageType, itemid)
		if isown < 1 then
			PushDebugMessage("#{QKH_20220802_18}")
			return
		end
		PushDebugMessage("#{QKH_20220802_19}")
	end

	QianKunPotScript:AddStoreItem(itemid)
	QianKunPotScript:CompleteOp(g_PageType)

	AutoPickUp_UpdateList()

	g_configchange = 1
end

function AutoPickUp_Error(tips)
	PushDebugMessage("#{QKH_20220802_18}")
end

function AutoPickUp_ItemClicked(idx)
	if g_BarList[idx] == nil then
		return
	end

	g_BarList[idx]:DoSubAction()
end

function AutoPickUp_ItemBtnClicked(idx)
	local bar = g_BarList[idx]
	if bar == nil then
		return
	end

	local count = QianKunPotScript:GetItemListMax(g_PageType)
	if idx > count then
		return
	end


	local isaction = QianKunPotScript:IsEnterAction()
	if isaction > 0 then
		QianKunPotScript:LeaveQianKunPot()
		return
	end

	local theAction = QianKunPotScript:GetActionItem(g_PageType, idx - 1)
	if theAction:GetID() ~= 0 then
		QianKunPotScript:ClearStore()
		QianKunPotScript:SetStoreState(g_enType.en_State_Delete)
		AutoPickUp_UpdateItem(g_enType.en_GiveUp, tonumber(theAction:GetItemTableIndex()))
	end	
end

-- 标记物品
function AutoPickUp_Uninstall_Click()
	QianKunPotScript:ClearStore()
	QianKunPotScript:SetStoreState(g_enType.en_State_Add)
	QianKunPotScript:EnterQianKunPot()
end

-- 放弃标记
function AutoPickUp_GiveUp_Click()
	--QianKunPotScript:ClearStore()
	--QianKunPotScript:SetStoreState(g_enType.en_State_Delete)
	--QianKunPotScript:EnterQianKunPotDel()
	if IsWindowShow("AutoPickUpSet") then
		return
	end

	local unifiedposx = AutoPickUp_Frame:GetProperty("UnifiedXPosition")
	local unifiedposy = AutoPickUp_Frame:GetProperty("UnifiedYPosition")
	local unifiedwidth = AutoPickUp_Frame:GetProperty("UnifiedWidth")
	local unifiedheight = AutoPickUp_Frame:GetProperty("UnifiedHeight")

	PushEvent("QIANKUNPOT_TYPE_SHOW", unifiedposx, unifiedposy, unifiedwidth, unifiedheight)
	
end

function AutoPickUp_TypePage_Switch(ntype, confirm)
	if ntype ~= g_enType.en_GiveUp and ntype ~= g_enType.en_TemBank then
		return
	end

	if ntype == g_PageType then
		return
	end
	
	-- if confirm < 1 then
	-- 	local ischange = QianKunPotScript:IsConfigChanged(g_PageType)
	-- 	if ischange > 0 then
	-- 		-- 弹二次确认
	-- 		PushEvent("QIANKUNPOT_CONFIG", "config", "typepage", ntype)
	-- 		return
	-- 	end
	-- end

	g_PageType = ntype
	AutoPickUp_UpdateList()

	--QianKunPotScript:CopyData(g_PageType)

	AutoPickUp_Index1:SetCheck(0)
	AutoPickUp_Index2:SetCheck(1)
end

function AutoPickUp_ChildPage_Switch(idx, confirm)
	if idx == 1 then
		local myLevel = Player:GetData("LEVEL")
		local nMenpai = Player:GetData("MEMPAI")
		if myLevel >= 50 and nMenpai ~= 9 then
			-- if confirm < 1 then
			-- 	local ischange = QianKunPotScript:IsConfigChanged(g_PageType)
			-- 	if ischange > 0 then
			-- 		-- 弹二次确认
			-- 		PushEvent("QIANKUNPOT_CONFIG", "config", "childpage", idx)
			-- 		return
			-- 	end
			-- end
			AutoPickUp_OnClose()
			PushEvent("TRIGGER_ZIDONGZHANDOU","config")
			DataPool:Lua_SetLastSkill_UI(6)
		elseif myLevel < 50 then
			PushDebugMessage("#{ZDZD_200724_62}")
		else
			PushDebugMessage("#{ZDZD_200724_63}")
		end
	end

	AutoPickUp_Index1:SetCheck(0)
	AutoPickUp_Index2:SetCheck(1)
end

function AutoPickUp_Page_Switch(idx, confirm)

	-- if confirm < 1 then
	-- 	local ischange = QianKunPotScript:IsConfigChanged(g_PageType)
	-- 	if ischange > 0 then
	-- 		-- 弹二次确认
	-- 		PushEvent("QIANKUNPOT_CONFIG", "config", "page", idx)
	-- 		return
	-- 	end
	-- end
	if idx == 5 then
		if DataPool:Lua_CheckOpenTalent() == 1 then
			ToggleTalentPage()
		else
			return
		end
	end
	-- 关闭
	AutoPickUp_OnClose()
	-- 打开各个界面
	if idx == 1 then
		OpenCommonSkillPage()
	elseif idx == 2 then
		local menpai = Player:GetData("MEMPAI")
		if menpai == g_invalidmenpai then 
			PushDebugMessage("#{ZDZD_200724_45}")
			return
		end
		OpenSkillBook()
	elseif idx == 3 then
		OpenZhenfaFream()
	elseif idx == 4 then
		OpenLifePage()
	end
end

function AutoPickUp_PageChangeEvent(sztype, optype, param)

	--PushDebugMessage("sztype="..sztype.." optype="..optype.."param: "..param)
	if sztype == "canel" then
		QianKunPotScript:ResetCopyData(g_PageType)
	end

	if optype == "page" then
		AutoPickUp_Page_Switch(tonumber(param), 1)
	elseif optype == "childpage" then
		AutoPickUp_ChildPage_Switch(tonumber(param), 1)
	elseif optype == "typepage" then
		AutoPickUp_TypePage_Switch(tonumber(param), 1)
	elseif optype == "close" then
		AutoPickUp_OnClose()
	end
end

function AutoPickUp_SetPosition()
	if not this:IsVisible() then
		local pos = Variable:GetVariable("SkillUnionPos")
		if pos ~= nil then
			AutoPickUp_Frame:SetProperty("UnifiedPosition", pos)
		end
	end
end

function AutoPickUp_OnResetPos()
	if g_unifiedposistion ~= nil then
		AutoPickUp_Frame:SetProperty("UnifiedPosition",g_unifiedposistion)
	end
end

function AutoPickUp_CleanUp()
	g_configchange = 0
	g_PageType = g_enType.en_GiveUp
	QianKunPotScript:ClearStore()
end

function AutoPickUp_OnConfirmClose()
	-- local ischange = QianKunPotScript:IsConfigChanged(g_PageType)
	-- if ischange > 0 then
	-- 	-- 弹二次确认
	-- 	PushEvent("QIANKUNPOT_CONFIG", "config", "close", 1)
	-- 	return
	-- end
	AutoPickUp_OnClose()
end

function AutoPickUp_OnClose()
	--if IsWindowShow("Packet") then
	--	CloseWindow("Packet", true)
	--end

	this:Hide()
end

function AutoPickUp_OnHide()
	AutoPickUp_ConfigChange()
	local unifiedpos = AutoPickUp_Frame:GetProperty("UnifiedPosition")
	Variable:SetVariable("SkillUnionPos", unifiedpos, 1)
	QianKunPotScript:LeaveQianKunPot()
	AutoPickUp_CleanUp()
	CloseWindow( "AutoPickUpSet" , true)
end

function AutoPickUp_SetTabColor()
	local selColor = "#e010101#Y";
	local noselColor = "#e010101";
	local tab = {
								[0] = AutoPickUp_CommonlySkill,
								AutoPickUp_ActionSkill,
								AutoPickUp_ZhenfaSkill,
								AutoPickUp_LifeSkill,
								AutoPickUp_AutoAttack,
								AutoPickUp_ZongMenSkill,
							};

	local TAB_TEXT = {
		[0] = "#{INTERFACE_XML_494}",
		"#{INTERFACE_XML_448}",
		"#{JBGXW_150526_215}",
		"#{INTERFACE_XML_635}",
		"#{ZDZD_200724_08}",
		"#{ZMTF_230628_20}",
	};
	
	tab[0]:SetText(noselColor..TAB_TEXT[0]);
	tab[1]:SetText(noselColor..TAB_TEXT[1]);
	tab[2]:SetText(noselColor..TAB_TEXT[2]);
	tab[3]:SetText(noselColor..TAB_TEXT[3]);
	tab[4]:SetText(selColor..TAB_TEXT[4]);
	tab[5]:SetText(noselColor..TAB_TEXT[5])

	for i, v in ipairs(tab or {}) do
		if g_curpage == i+1 then
			v:SetCheck(1)
		else
			v:SetCheck(0)
		end
	end
end

function AutoPickUp_ConfigChange()
	if g_configchange > 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("QKHConfigChange")
			Set_XSCRIPT_ScriptID(888851)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()

		g_configchange = 0
	end
end