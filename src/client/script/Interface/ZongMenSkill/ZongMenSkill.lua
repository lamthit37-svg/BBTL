
--宗门天赋
local g_ZongMenSkill_Frame_UnifiedPosition
local g_ZongMenSkill_NormalSkillUI = {}
local g_ZongMenSkill_CoreSkillUI = {}
local g_ZongMenSkill_MaxLevel = 5 --所有天赋的最大等级都暂定为5

local g_ZongMenSkill_SelectedId = -1
local g_ZongMenSkill_CurType = 1 --1普通 2核心 3装备带技能的
local g_ZongMenSkill_CurIndex = 1
local g_ZongMenSkill_isShowEffect = 0
local g_ZongMenSkill_NewNormalSectRequiredLevel = 120
local g_ZongMenSkill_NewCoreSectRequiredLevel = 129
local g_ZongMenSkill_RequiredPlayerLevel = 120

local g_ZongMenSkill_DefaultSectName=
{
	[0] = "#{ZMTFBC_230920_10}",
	[1] = "#{ZMTFBC_230920_11}",
	[2] = "#{ZMTFBC_230920_12}",
	[3] = "#{ZMTFBC_230920_13}",
	[4] = "#{ZMTFBC_230920_14}",
}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_ZongMenSkill_Page = {
	[1] = {Text = "#e010101".."#{INTERFACE_XML_494}",	NeedCheck = 0, Tip = ""},
	[2] = {Text = "#e010101".."#{INTERFACE_XML_448}",	NeedCheck = 0, Tip = ""},
	[3] = {Text = "#e010101".."#{JBGXW_150526_215}",	NeedCheck = 0, Tip = ""},
	[4] = {Text = "#e010101".."#{INTERFACE_XML_635}",	NeedCheck = 0, Tip = ""},
	[5] = {Text = "#e010101".."#{ZDZD_200724_08}",		NeedCheck = 0, Tip = ""},
	[6] = {Text = "#e010101#Y".."#{ZMTF_230628_20}",	NeedCheck = 0, Tip = ""},
}
local g_ZongMenSkill_PageButton = {}
local g_ZongMenSkill_PageOrder = {}
local g_PageTipsPos = {}

-- local g_ZongMenSkill_CurLevelPageIndex = 1  --左右按钮查询技能信息的标识索引
function ZongMenSkill_PreLoad()
	this:RegisterEvent("TOGGLE_SECT_PAGE", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("UPDATE_SECT_PAGE",false)
	this:RegisterEvent("ZONGMEN_DIZILEVEL_UPDATE",false)
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("REFRESH_EQUIP", false)
	this:RegisterEvent("GEM_CONTAINER_REFRESH", false)
	this:RegisterEvent("SECT_UPDATE_COMBOLIST", false)
	this:RegisterEvent("SECT_MODIFYTOSAVE", false)
	this:RegisterEvent("CLOSE_SECT_PAGE", false)
	this:RegisterEvent("CLOSE_SKILL_BOOK",false)
	this:RegisterEvent("OPEN_ZONGMEN_SKILL_GUIDE", true)
end

function ZongMenSkill_GetName(index)
	-- local res,nSectName = DataPool:GetSectNameByIndex(index)
	-- if res>0 then
	-- 	return nSectName
	-- else
	return g_ZongMenSkill_DefaultSectName[index]
	-- end
end

function ZongMenSkill_InitCombo()
	local nUseIndex, nSelectedIndex = DataPool:GetZMSectUsePlanIndex()
	for i = 1, 2 do
		if (i-1) == nUseIndex then
			ZongMenSkill_Talent_ComboList:ComboBoxAddItem("#G"..ZongMenSkill_GetName(i-1).."#{ZMTFBC_230920_62}", i - 1)
		else
			ZongMenSkill_Talent_ComboList:ComboBoxAddItem(ZongMenSkill_GetName(i-1), i - 1)
		end
	 end
	 ZongMenSkill_Talent_ComboList:SetCurrentSelect(nUseIndex)
	 DataPool:ChangeSectSelectedIndex(nUseIndex)
end

function ZongMenSkill_ComboList_SelectChanged()
	local planName, nIndex = ZongMenSkill_Talent_ComboList:GetCurrentSelect()
	-- PushDebugMessage("planName:"..tostring(planName))
	local nUseIndex, nSelectedIndex = DataPool:GetZMSectUsePlanIndex()
	--如果选择的方案和缓存中的一致 不走下面的逻辑
	if nIndex == nSelectedIndex then
		return
	end
	ZongMenSkill_UpdateComboList()
	if DataPool:GetSectIsModify(nSelectedIndex, 0) == 1 then
		PushEvent("SECT_LEAVE_WITHOUT_SAVE", nSelectedIndex, nIndex)
	else
		DataPool:ChangeSectSelectedIndex(nIndex)
		ZongMenSkill_UpdateComboList()
		ZongMenSkill_Update()
		if g_ZongMenSkill_CurType == 1 then
			ZongMenSkill_TalentTreeClicked(g_ZongMenSkill_CurIndex)
		elseif g_ZongMenSkill_CurType == 2 then
			ZongMenSkill_CoreTalentTreeClicked(g_ZongMenSkill_CurIndex)
		elseif g_ZongMenSkill_CurType == 3 then
			ZongMenSkill_TalentEquip_SkillClicked()
		end
	end


end

function ZongMenSkill_Talent_Save_Clicked()
	
	local planName, nIndex = ZongMenSkill_Talent_ComboList:GetCurrentSelect()
	if DataPool:GetSectIsModify(nIndex, 0) == 0 then
		PushDebugMessage("#{ZMTFBC_230920_26}")
		return
	end
--	PushDebugMessage("nIndex:"..tostring(nIndex))
	if DataPool:GetSectIsBackLevel(nIndex, 0) == 1 then
		-- PushDebugMessage("nIndex:"..tostring(nIndex))
		PushEvent("SECT_SAVEPLAN_CONFIRM", nIndex, 0)
	else
		Player:Lua_AskSectOper(1,nIndex)
	end
end

function ZongMenSkill_Talent_Use_Clicked()
	local planName, nIndex = ZongMenSkill_Talent_ComboList:GetCurrentSelect()
	
	if DataPool:GetSectIsModify(nIndex, 0) == 1 then
		PushDebugMessage("#{ZMTFBC_230920_82}")
		return
	end

	Player:Lua_AskSectOper(3,nIndex)
end

function ZongMenSkill_Talent_Share_Clicked()
	local ActionEquip = EnumAction(23, "equip")
	if ActionEquip:GetID() > 0 then
		local planName, nIndex = ZongMenSkill_Talent_ComboList:GetCurrentSelect()
		local isModify = DataPool:GetSectIsModify(nIndex, 0)
		if isModify == 1 then
			PushDebugMessage("#{ZMTFBC_230920_79}")
		end
		local res = DataPool:SectCreateShareHyperLink(nIndex)
		if res == 1 and isModify ~= 1 then
			PushDebugMessage("#{ZMTFBC_230920_80}")
		end
	else
		PushDebugMessage("#{ZMTFBC_230920_18}")
	end
end

function ZongMenSkill_Talent_Edit_Clicked()
	-- local planName, nIndex = ZongMenSkill_Talent_ComboList:GetCurrentSelect()
	-- PushEvent( "OPEN_ZONGMEN_EDIT", nIndex)
end

function ZongMenSkill_OnEvent(event)
	if event == "TOGGLE_SECT_PAGE" then
		local selfUnionPos = Variable:GetVariable("SkillUnionPos");
		if(selfUnionPos ~= nil) then
			ZongMenSkill_Frame:SetProperty("UnifiedPosition", selfUnionPos);
		end
		
		ZongMenSkill_Open()
	elseif event == "UPDATE_SECT_PAGE" then
		g_ZongMenSkill_isShowEffect = tonumber(arg0)
		local planName, nIndex = ZongMenSkill_Talent_ComboList:GetCurrentSelect()
		DataPool:ChangeSectSelectedIndex(nIndex)
		ZongMenSkill_Update()
		if g_ZongMenSkill_CurType == 1 then
			ZongMenSkill_TalentTreeClicked(g_ZongMenSkill_CurIndex)
		elseif g_ZongMenSkill_CurType == 2 then
			ZongMenSkill_CoreTalentTreeClicked(g_ZongMenSkill_CurIndex)
		elseif g_ZongMenSkill_CurType == 3 then
			ZongMenSkill_TalentEquip_SkillClicked()
		end
	elseif event == "SECT_UPDATE_COMBOLIST" then
		ZongMenSkill_UpdateComboList()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ZongMenSkill_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		ZongMenSkill_On_ResetPos()
	elseif ( event == "CLOSE_SKILL_BOOK" ) then
		ZongMenSkill_OnClose()
	elseif ( event == "OPEN_ZONGMEN_SKILL_GUIDE" ) then
		if tonumber(arg0)==13 then
			local fX, fY = this:GetChildOffset("ZongMenSkill_TalentBtn15")
			fX = fX + ZongMenSkill_TalentBtn15:GetProperty("AbsoluteWidth") / 2
			fY = fY + 20
			OpenFreshManGuide(1, 282, fX, fY, "ZongMenSkill", "northwest")
		elseif tonumber(arg0)==14 then
			local fX, fY = this:GetChildOffset("ZongMenSkill_TalentBtn16")
			fX = fX + ZongMenSkill_TalentBtn16:GetProperty("AbsoluteWidth") / 2
			fY = fY + 20
			OpenFreshManGuide(1, 282, fX, fY, "ZongMenSkill", "northwest")
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "CLOSE_SECT_PAGE" then
		ZongMenSkill_OnClose()
	elseif event == "SECT_MODIFYTOSAVE" then
		if arg0 ~= nil then
			if tonumber(arg0)>=0 then
				DataPool:ChangeSectSelectedIndex(tonumber(arg0))
				ZongMenSkill_UpdateComboList()
				ZongMenSkill_Update()
				if g_ZongMenSkill_CurType == 1 then
					ZongMenSkill_TalentTreeClicked(g_ZongMenSkill_CurIndex)
				elseif g_ZongMenSkill_CurType == 2 then
					ZongMenSkill_CoreTalentTreeClicked(g_ZongMenSkill_CurIndex)
				elseif g_ZongMenSkill_CurType == 3 then
					ZongMenSkill_TalentEquip_SkillClicked()
				end
			else
				if tonumber(arg1)==0 then
					this:Hide()
				elseif tonumber(arg1)==1 then
					ZongMenSkill_OnPageClicked(1, 1)
				elseif tonumber(arg1)==2 then
					ZongMenSkill_OnPageClicked(2, 1)
				elseif tonumber(arg1)==3 then
					ZongMenSkill_OnPageClicked(3, 1)
				elseif tonumber(arg1)==4 then
					ZongMenSkill_OnPageClicked(4, 1)
				elseif tonumber(arg1)==5 then
					ZongMenSkill_OnPageClicked(5, 1)
				end
			end
		end
	elseif event == "ZONGMEN_DIZILEVEL_UPDATE" then
		if arg0 == "exp" then
			if this:IsVisible() then
				ZongMenSkill_DiZiExp_Update()
			end
		end
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998633007) then	--服务端传数据
	
		local bIsShowHotPoint = Get_XParam_INT(0)	
		if bIsShowHotPoint == 1 then
			ZongMenSkill_PataBtn_Tips:Show()
			ZongMenSkill_ZongMenSkill_Tips:Show()
		else
			ZongMenSkill_PataBtn_Tips:Hide()
			ZongMenSkill_ZongMenSkill_Tips:Hide()
		end
		
	end
	
	if event == "REFRESH_EQUIP" and this:IsVisible() then
		local planName, nIndex = ZongMenSkill_Talent_ComboList:GetCurrentSelect()
		DataPool:ChangeSectSelectedIndex(nIndex)
		ZongMenSkill_Update()
		-- ZongMenSkill_UpdateEquip()
	end
	
	if event == "GEM_CONTAINER_REFRESH" then
		ZongMenSkill_UpdateEquip()
	end
end

function ZongMenSkill_DiZiExp_Update()
	
	local zmexp = Player:GetData("ZONGMENEXP")
	local zmhexp = Player:GetData("ZONGMENHIGHEXP")
	local zmlevel = Player:GetData("ZONGMENLEVEL")
	local zmnexp = Player:GetData("ZONGMENNEEDEXP")
	local zmdizistr = Player:GetData("ZONGMENDIZISTR")

	ZongMenSkill_SufferBK_Jindu:SetProgress( tonumber(zmexp), tonumber(zmnexp) )
	if zmlevel >= 50 then
		ZongMenSkill_SufferBK_Jindu:SetProgress( 10, 10 )
		ZongMenSkill_SufferBK_Jindu:SetToolTip("#{ZMDZ_230703_179}")
		ZongMenSkill_SufferText:Hide()
	else
		ZongMenSkill_SufferBK_Jindu:SetToolTip(ScriptGlobal_Format("#{ZMDZ_230703_19}",tostring(zmexp),tostring(zmnexp)))
		if Player:GetData("Is2606S") == 1 then
			ZongMenSkill_SufferText:SetText(ScriptGlobal_Format("#{QXDZJY_260707_10}",tostring(zmhexp)))
			ZongMenSkill_SufferText:SetToolTip("#{QXDZJY_260707_01}")
		else
			ZongMenSkill_SufferText:SetText(ScriptGlobal_Format("#{ZMDZ_230703_20}",tostring(zmhexp)))
			ZongMenSkill_SufferText:SetToolTip("#{ZMDZ_230703_21}")
		end
		ZongMenSkill_SufferText:Show()
	end

	ZongMenSkill_LevelText:SetText(tostring(zmdizistr))
end

function ZongMenSkill_UpdateComboList()
	-- ZongMenSkill_Talent_ComboList:ResetList()
	local nUseIndex, nSelectedIndex = DataPool:GetZMSectUsePlanIndex()
	for i = 1, 2 do
		if (i-1) == nUseIndex then
			-- ZongMenSkill_Talent_ComboList:SetTextItemText( i - 1,tostring(i).."xtc")
			ZongMenSkill_Talent_ComboList:SetTextItemText( i - 1,"#G"..ZongMenSkill_GetName(i-1).."#{ZMTFBC_230920_62}")
		else
			-- ZongMenSkill_Talent_ComboList:SetTextItemText(i - 1,tostring(i))
			ZongMenSkill_Talent_ComboList:SetTextItemText(i - 1,ZongMenSkill_GetName(i-1))
		end
	end
	-- for i = 1, 5 do
	-- 	if (i-1) == nUseIndex then
	-- 		ZongMenSkill_Talent_ComboList:ComboBoxAddItem(tostring(i).."xtc", i - 1)
	-- 	else
	-- 		ZongMenSkill_Talent_ComboList:ComboBoxAddItem(tostring(i), i - 1)
	-- 	end
	--  end
	 ZongMenSkill_Talent_ComboList:SetCurrentSelect(nSelectedIndex)
end


function ZongMenSkill_Update()
	ZongMenSkill_TalentPoint1:SetText(ScriptGlobal_Format("#{ZMTF_230628_112}", DataPool:GetSectNormalPoint()))
	ZongMenSkill_TalentPoint2:SetText(ScriptGlobal_Format("#{ZMTF_230628_114}", DataPool:GetSectCorePoint()))
	
	-- ZongMenSkill_Talent_ComboList:ResetText()

	-- local nUseIndex = DataPool:GetZMSectUsePlanIndex()
	-- for i = 1, 5 do
	-- 	if (i-1) == nUseIndex then
	-- 		-- ZongMenSkill_Talent_ComboList:ComboBoxAddItem(tostring(i).."xtc", i - 1)
	-- 		ZongMenSkill_Talent_ComboList:SetTextItemText( i - 1,tostring(i).."xtc")
	-- 	else
	-- 		-- ZongMenSkill_Talent_ComboList:ComboBoxAddItem(tostring(i), i - 1)
	-- 		ZongMenSkill_Talent_ComboList:SetTextItemText(i - 1,tostring(i))
	-- 	end
	--  end
	
	local nEquipXWLevel = DataPool:GetEquipXinWuLevel()
	-- PushDebugMessage("nEquipXWLevel:"..tostring(nEquipXWLevel))
	-- local menpai = Player:GetData("MEMPAI")
	local coreSkillCount = DataPool:GetZMCoreDataCount()
	for i = 1,table.getn(g_ZongMenSkill_CoreSkillUI) do
		if i > coreSkillCount then
			g_ZongMenSkill_CoreSkillUI[i].CheckBtn:Hide()
		else
			if g_ZongMenSkill_isShowEffect == 1 and i == g_ZongMenSkill_CurIndex and g_ZongMenSkill_CurType == 2 then 
				g_ZongMenSkill_CoreSkillUI[i].Animate:Play(true)
			else
				g_ZongMenSkill_CoreSkillUI[i].Animate:Play(false)
			end
			g_ZongMenSkill_CoreSkillUI[i].CheckBtn:Show()
			local nSectId = DataPool:GetZongMenTalentCoreData(i-1,"SectId")
			local curSkillLevel, requireTalentPoint = DataPool:GetZongMenTalentCoreData(i-1,"CurLevel")
			g_ZongMenSkill_CoreSkillUI[i].NameLabel:SetText(DataPool:GetZongMenTalentCoreData(i-1,"Name"))
			
			local nSubTalentType = DataPool:GetZongMenTalentCoreData(i-1,"SubTalentType")
			local nRequiredEquipLevel = DataPool:GetZongMenTalentCoreData(i-1,"RequiredEquipLevel")

			local nLogicType = DataPool:GetZongMenTalentCoreData(i-1,"LogicType")
			local nAddSkill = DataPool:GetZongMenTalentCoreData(i-1,"AddSkill")
			g_ZongMenSkill_CoreSkillUI[i].TalentTypeIcon:Show()

			local nRequiredXinFaLevel = DataPool:GetZongMenTalentCoreData(i-1,"RequiredXinFaLevel")
			if nRequiredXinFaLevel == g_ZongMenSkill_NewCoreSectRequiredLevel then
				if Player:GetLevel()>=g_ZongMenSkill_RequiredPlayerLevel then
					g_ZongMenSkill_CoreSkillUI[i].LevelLock:Hide()
				else
					g_ZongMenSkill_CoreSkillUI[i].LevelLock:Show()
				end

				for j = 1,6 do 
					if nSubTalentType == j then
						_G["ZongMenSkill_TalentAttr16".."_"..j]:Show()
					else
						_G["ZongMenSkill_TalentAttr16".."_"..j]:Hide()
					end
				end
			else
				for j = 1,6 do 
					if nSubTalentType == j then
						_G["ZongMenSkill_TalentAttr"..(i+10).."_"..j]:Show()
					else
						_G["ZongMenSkill_TalentAttr"..(i+10).."_"..j]:Hide()
					end
				end
			end

			

			
			g_ZongMenSkill_CoreSkillUI[i].TalentLabel:SetText(tostring(curSkillLevel).."/"..tostring(g_ZongMenSkill_MaxLevel))

			g_ZongMenSkill_CoreSkillUI[i].ActionItem:SetProperty("DraggingEnabled","False")

			if nLogicType == 5 and curSkillLevel>0 then
			
				local nSumSkill = GetActionNum("skill")
			
				for j=1, nSumSkill do
					local theAction = EnumAction(j-1, "skill")
					
					if theAction:GetDefineID() == nAddSkill then	
					
						g_ZongMenSkill_CoreSkillUI[i].ActionItem:SetProperty("DraggingEnabled","True")
						g_ZongMenSkill_CoreSkillUI[i].ActionItem:SetActionItem(theAction:GetID())
					
					end
				end
			else
				local action = DataPool:Lua_CreateSectInfoAction(nSectId,curSkillLevel)
				if action then
					g_ZongMenSkill_CoreSkillUI[i].ActionItem:SetActionItem(action:GetID())
				end
			end
			
			if nEquipXWLevel <=0 then
				--未装备
				g_ZongMenSkill_CoreSkillUI[i].LockMask:Show()
				g_ZongMenSkill_CoreSkillUI[i].IconLockMask:Show()
			else
				if nEquipXWLevel < nRequiredEquipLevel then
					--装备的阶不符合技能所需解锁的条件
					g_ZongMenSkill_CoreSkillUI[i].LockMask:Show()
					g_ZongMenSkill_CoreSkillUI[i].IconLockMask:Show()
				else
					g_ZongMenSkill_CoreSkillUI[i].LockMask:Hide()
					if curSkillLevel > 0 then
						g_ZongMenSkill_CoreSkillUI[i].IconLockMask:Hide()
					else
						g_ZongMenSkill_CoreSkillUI[i].IconLockMask:Show()
					end

				end
			end

			-- if curSkillLevel > 0 then
			-- 	g_ZongMenSkill_CoreSkillUI[i].LockMask:Hide()
			-- 	g_ZongMenSkill_CoreSkillUI[i].IconLockMask:Hide()
			-- else
			-- 	g_ZongMenSkill_CoreSkillUI[i].LockMask:Show()
			-- 	g_ZongMenSkill_CoreSkillUI[i].IconLockMask:Show()
			-- end
		end
	end

	local normalSkillCount = DataPool:GetZMNormalDataCount()
	-- PushDebugMessage( "normalSkillCount:"..tostring(normalSkillCount) )
	for i = 1,table.getn(g_ZongMenSkill_NormalSkillUI) do
		if i > normalSkillCount then
			g_ZongMenSkill_NormalSkillUI[i].CheckBtn:Hide()
		else
			if g_ZongMenSkill_isShowEffect == 1 and i == g_ZongMenSkill_CurIndex and g_ZongMenSkill_CurType == 1 then 
				g_ZongMenSkill_NormalSkillUI[i].Animate:Play(true)
			else
				g_ZongMenSkill_NormalSkillUI[i].Animate:Play(false)
			end
			g_ZongMenSkill_NormalSkillUI[i].CheckBtn:Show()

			local nSectId = DataPool:GetZongMenTalentNormalData(i-1,"SectId")
			local curSkillLevel, requireTalentPoint = DataPool:GetZongMenTalentNormalData(i-1,"CurLevel")

			g_ZongMenSkill_NormalSkillUI[i].NameLabel:SetText(DataPool:GetZongMenTalentNormalData(i-1,"Name"))

			local nSubTalentType = DataPool:GetZongMenTalentNormalData(i-1,"SubTalentType")
			local nRequiredEquipLevel = DataPool:GetZongMenTalentNormalData(i-1,"RequiredEquipLevel")

			local nLogicType = DataPool:GetZongMenTalentNormalData(i-1,"LogicType")
			local nAddSkill = DataPool:GetZongMenTalentNormalData(i-1,"AddSkill")
			g_ZongMenSkill_NormalSkillUI[i].TalentTypeIcon:Show()

			local nRequiredXinFaLevel = DataPool:GetZongMenTalentNormalData(i-1,"RequiredXinFaLevel")
			if nRequiredXinFaLevel == g_ZongMenSkill_NewNormalSectRequiredLevel then
				if Player:GetLevel()>=g_ZongMenSkill_RequiredPlayerLevel then
					g_ZongMenSkill_NormalSkillUI[i].LevelLock:Hide()
				else
					g_ZongMenSkill_NormalSkillUI[i].LevelLock:Show()
				end
				for j = 1,6 do 
					if nSubTalentType == j then
						_G["ZongMenSkill_TalentAttr15".."_"..j]:Show()
					else
						_G["ZongMenSkill_TalentAttr15".."_"..j]:Hide()
					end
				end
			else
				for j = 1,6 do 
					if nSubTalentType == j then
						_G["ZongMenSkill_TalentAttr"..i.."_"..j]:Show()
					else
						_G["ZongMenSkill_TalentAttr"..i.."_"..j]:Hide()
					end
				end
			end

			g_ZongMenSkill_NormalSkillUI[i].TalentLabel:SetText(tostring(curSkillLevel).."/"..tostring(g_ZongMenSkill_MaxLevel))
			g_ZongMenSkill_NormalSkillUI[i].ActionItem:SetProperty("DraggingEnabled","False")

			if nLogicType == 5 and curSkillLevel>0 then
			
				local nSumSkill = GetActionNum("skill")
			
				for j=1, nSumSkill do
					local theAction = EnumAction(j-1, "skill")
					
					if theAction:GetDefineID() == nAddSkill then	
					
						g_ZongMenSkill_NormalSkillUI[i].ActionItem:SetProperty("DraggingEnabled","True")
						g_ZongMenSkill_NormalSkillUI[i].ActionItem:SetActionItem(theAction:GetID())
					
					end
				end
			else
				local action = DataPool:Lua_CreateSectInfoAction(nSectId,curSkillLevel)
				if action then
					g_ZongMenSkill_NormalSkillUI[i].ActionItem:SetActionItem(action:GetID())
				end
			end

			if nEquipXWLevel <=0 then
				--未装备
				g_ZongMenSkill_NormalSkillUI[i].LockMask:Show()
				g_ZongMenSkill_NormalSkillUI[i].IconLockMask:Show()
			else
				if nEquipXWLevel < nRequiredEquipLevel then
					--装备的阶不符合技能所需解锁的条件
					g_ZongMenSkill_NormalSkillUI[i].LockMask:Show()
					g_ZongMenSkill_NormalSkillUI[i].IconLockMask:Show()
				else
					g_ZongMenSkill_NormalSkillUI[i].LockMask:Hide()
					if curSkillLevel > 0 then
						g_ZongMenSkill_NormalSkillUI[i].IconLockMask:Hide()
					else
						g_ZongMenSkill_NormalSkillUI[i].IconLockMask:Show()
					end

				end
			end
			-- if curSkillLevel > 0 then
			-- 	g_ZongMenSkill_NormalSkillUI[i].LockMask:Hide()
			-- 	g_ZongMenSkill_NormalSkillUI[i].IconLockMask:Hide()
			-- else
			-- 	g_ZongMenSkill_NormalSkillUI[i].LockMask:Show()
			-- 	g_ZongMenSkill_NormalSkillUI[i].IconLockMask:Show()
			-- end

		end
	end

	ZongMenSkill_DiZiExp_Update()
	
	ZongMenSkill_UpdateEquip()
end

function ZongMenSkill_Open()
	this:Show()
	
	-- ZongMenSkill_Talent_ShareBtn:Hide()
	-- ZongMenSkill_Talent_SaveBtn:Hide()
	
	if Player:GetData("Is2606S") == 1 then
		ZongMenSkill_PataBtn:Hide()
	else
		ZongMenSkill_PataBtn:Show()
	end

	ZongMenSkill_InitCombo()
	ZongMenSkill_UpdateComboList()
	ZongMenSkill_Update()

	ZongMenSkill_TalentTreeClicked(1)
	
	ZongMenSkill_ShowPage()
end

function ZongMenSkill_TalentInfo_Effect_Clicked()
	-- PushDebugMessage("g_ZongMenSkill_CurType:"..tonumber(g_ZongMenSkill_CurType))
	-- 	PushDebugMessage("g_ZongMenSkill_CurIndex:"..tonumber(g_ZongMenSkill_CurIndex))
	PushEvent( "OPEN_ZONGMENSKILL_INFO", g_ZongMenSkill_CurType, g_ZongMenSkill_CurIndex)

end

-- function ZongMenSkill_TalentInfo_EffectLeft_Clicked()
-- 	local nCurLevel = 1
-- 	if g_ZongMenSkill_CurType == 1 then
-- 		local curSkillLevel, requireTalentPoint = DataPool:GetZongMenTalentNormalData(g_ZongMenSkill_CurIndex-1,"CurLevel")
-- 		nCurLevel = curSkillLevel

-- 	elseif g_ZongMenSkill_CurType == 2 then
-- 		local curSkillLevel, requireTalentPoint = DataPool:GetZongMenTalentCoreData(g_ZongMenSkill_CurIndex-1,"CurLevel")
-- 		nCurLevel = curSkillLevel
		
-- 	elseif g_ZongMenSkill_CurType == 3 then
-- 		local nSectId, nLogicType, nAddSkill, nSectLevel, nName, nSubTalentType = DataPool:GetSectEquipSkill()
-- 		nCurLevel = nSectLevel

-- 	end

-- 	if g_ZongMenSkill_CurLevelPageIndex > 1 then
-- 		g_ZongMenSkill_CurLevelPageIndex = g_ZongMenSkill_CurLevelPageIndex - 1 
-- 	end
	
-- 	if g_ZongMenSkill_CurLevelPageIndex == 1 or g_ZongMenSkill_CurLevelPageIndex <= nCurLevel + 1 then
-- 		ZongMenSkill_TalentInfo_EffectLeftBtn:Disable()
-- 	end

-- 	if g_ZongMenSkill_CurLevelPageIndex < g_ZongMenSkill_MaxLevel then
-- 		ZongMenSkill_TalentInfo_EffectRightBtn:Enable()
-- 	end

-- 	local color = "#cFFF263"
-- 	ZongMenSkill_TalentInfo_EffectTitle2:SetText(ScriptGlobal_Format("#{ZMTF_230628_126}", g_ZongMenSkill_CurLevelPageIndex))
-- 	if g_ZongMenSkill_CurType == 1 then
-- 		ZongMenSkill_TalentInfo_EffectText2:SetText(color..DataPool:Lua_GetSectDesc(g_ZongMenSkill_CurIndex-1,g_ZongMenSkill_CurLevelPageIndex-1, 0))
-- 	elseif g_ZongMenSkill_CurType == 2 then
-- 		ZongMenSkill_TalentInfo_EffectText2:SetText(color..DataPool:Lua_GetSectDesc(g_ZongMenSkill_CurIndex-1,g_ZongMenSkill_CurLevelPageIndex-1, 1))
-- 	elseif g_ZongMenSkill_CurType == 3 then
-- 		ZongMenSkill_TalentInfo_EffectText2:SetText(color..DataPool:Lua_GetSectDesc(0,g_ZongMenSkill_CurLevelPageIndex-1, 2))
-- 	end

-- end

-- function ZongMenSkill_TalentInfo_EffectRight_Clicked()
-- 	local nCurLevel = 1
-- 	if g_ZongMenSkill_CurType == 1 then
-- 		local curSkillLevel, requireTalentPoint = DataPool:GetZongMenTalentNormalData(g_ZongMenSkill_CurIndex-1,"CurLevel")
-- 		nCurLevel = curSkillLevel

-- 	elseif g_ZongMenSkill_CurType == 2 then
-- 		local curSkillLevel, requireTalentPoint = DataPool:GetZongMenTalentCoreData(g_ZongMenSkill_CurIndex-1,"CurLevel")
-- 		nCurLevel = curSkillLevel
		
-- 	elseif g_ZongMenSkill_CurType == 3 then
-- 		local nSectId, nLogicType, nAddSkill, nSectLevel, nName, nSubTalentType = DataPool:GetSectEquipSkill()
-- 		nCurLevel = nSectLevel

-- 	end

-- 	if g_ZongMenSkill_CurLevelPageIndex < 5 then
-- 		g_ZongMenSkill_CurLevelPageIndex = g_ZongMenSkill_CurLevelPageIndex + 1 
-- 	end

-- 	if g_ZongMenSkill_CurLevelPageIndex >= g_ZongMenSkill_MaxLevel then
-- 		ZongMenSkill_TalentInfo_EffectRightBtn:Disable()
-- 	end

-- 	if g_ZongMenSkill_CurLevelPageIndex > 1 and g_ZongMenSkill_CurLevelPageIndex > nCurLevel + 1 then
-- 		ZongMenSkill_TalentInfo_EffectLeftBtn:Enable()
-- 	end

-- 	local color = "#cFFF263"
-- 	ZongMenSkill_TalentInfo_EffectTitle2:SetText(ScriptGlobal_Format("#{ZMTF_230628_126}", g_ZongMenSkill_CurLevelPageIndex))
-- 	if g_ZongMenSkill_CurType == 1 then
-- 		ZongMenSkill_TalentInfo_EffectText2:SetText(color..DataPool:Lua_GetSectDesc(g_ZongMenSkill_CurIndex-1,g_ZongMenSkill_CurLevelPageIndex-1, 0))
-- 	elseif g_ZongMenSkill_CurType == 2 then
-- 		ZongMenSkill_TalentInfo_EffectText2:SetText(color..DataPool:Lua_GetSectDesc(g_ZongMenSkill_CurIndex-1,g_ZongMenSkill_CurLevelPageIndex-1, 1))
-- 	elseif g_ZongMenSkill_CurType == 3 then
-- 		ZongMenSkill_TalentInfo_EffectText2:SetText(color..DataPool:Lua_GetSectDesc(0,g_ZongMenSkill_CurLevelPageIndex-1, 2))
-- 	end

-- end

function ZongMenSkill_TalentTreeClicked(index)

	if index<1 or index>11 then
		return
	end
	CloseFreshManGuide()
	PushEvent( "CLOSE_ZONGMENSKILL_INFO")

	g_ZongMenSkill_CurType = 1
	g_ZongMenSkill_CurIndex = index

	for i = 1,table.getn(g_ZongMenSkill_CoreSkillUI) do
		g_ZongMenSkill_CoreSkillUI[i].CheckBtn:SetCheck(0)
	end
	for i = 1,table.getn(g_ZongMenSkill_NormalSkillUI) do
		g_ZongMenSkill_NormalSkillUI[i].CheckBtn:SetCheck(0)
	end
	g_ZongMenSkill_NormalSkillUI[index].CheckBtn:SetCheck(1)
	ZongMenSkill_TalentEquip_Skill:SetCheck(0)
	ZongMenSkill_TalentInfo_LevelUpPoint:Show()
	ZongMenSkill_TalentInfo_LevelUpBtn:Show()
	ZongMenSkill_TalentEquip_LevelUp:Hide()
	local color = "#cFFF263"
	g_ZongMenSkill_SelectedId = DataPool:GetZongMenTalentNormalData(index-1,"SectId")
	local nSubTalentType = DataPool:GetZongMenTalentNormalData(index-1,"SubTalentType")
	local nSectName = DataPool:GetZongMenTalentNormalData(index-1,"Name")
	local curSkillLevel, requireTalentPoint = DataPool:GetZongMenTalentNormalData(index-1,"CurLevel")

	local nRequiredEquipLevel = DataPool:GetZongMenTalentNormalData(index-1,"RequiredEquipLevel")
	ZongMenSkill_TalentInfo_LevelUpCondition:Show()
	ZongMenSkill_TalentInfo_LevelUpCondition2:Show()
	ZongMenSkill_TalentInfo_LevelUpCondition:SetText(ScriptGlobal_Format("#{ZMTF_230628_127}", nRequiredEquipLevel))
	ZongMenSkill_TalentInfo_LevelUpCondition2:SetText("#{ZMTF_230628_172}")

	-- ZongMenSkill_TalentInfo_EffectLeftBtn:Disable()
	-- ZongMenSkill_TalentInfo_EffectRightBtn:Enable()
	-- g_ZongMenSkill_CurLevelPageIndex = curSkillLevel+1
	
	
	if curSkillLevel<=0 then
		ZongMenSkill_TalentInfo_EffectText1:Hide()
		ZongMenSkill_TalentInfo_EffectTitle1:SetText("#{ZMTF_230628_190}")
		-- g_ZongMenSkill_CurLevelPageIndex = 1
		ZongMenSkill_TalentInfo_LevelUpBtn:SetText("#{ZMTF_230628_215}")
	else
		ZongMenSkill_TalentInfo_EffectText1:Show()
		ZongMenSkill_TalentInfo_EffectText1:SetText(color..DataPool:Lua_GetSectDesc(index-1,curSkillLevel-1, 0))
		ZongMenSkill_TalentInfo_EffectTitle1:SetText(ScriptGlobal_Format("#{ZMTF_230628_125}", curSkillLevel))
		ZongMenSkill_TalentInfo_LevelUpBtn:SetText("#{ZMTF_230628_129}")
	end

	
	

	if curSkillLevel >= g_ZongMenSkill_MaxLevel then
		-- ZongMenSkill_TalentInfo_EffectTitle2:Hide()
		ZongMenSkill_TalentInfo_EffectTitle2:SetText("#{ZMTF_230628_191}")
		ZongMenSkill_TalentInfo_EffectText2:Hide()
		ZongMenSkill_TalentInfo_LevelUpPoint:Hide()
		ZongMenSkill_TalentInfo_LevelUpCondition:Hide()
		ZongMenSkill_TalentInfo_LevelUpCondition2:Hide()
		-- ZongMenSkill_TalentInfo_EffectRightBtn:Disable()
	else
		-- ZongMenSkill_TalentInfo_EffectTitle2:Show()
		ZongMenSkill_TalentInfo_EffectText2:Show()
		ZongMenSkill_TalentInfo_EffectText2:SetText(color..DataPool:Lua_GetSectDesc(index-1,curSkillLevel, 0))
		ZongMenSkill_TalentInfo_EffectTitle2:SetText(ScriptGlobal_Format("#{ZMTF_230628_126}", curSkillLevel+1))
		ZongMenSkill_TalentInfo_LevelUpPoint:Show()
		ZongMenSkill_TalentInfo_LevelUpPoint:SetText(ScriptGlobal_Format("#{ZMTF_230628_128}", requireTalentPoint))

	end

	local nRequiredXinFaLevel = DataPool:GetZongMenTalentNormalData(index-1,"RequiredXinFaLevel")
	if nRequiredXinFaLevel == g_ZongMenSkill_NewNormalSectRequiredLevel then
		if Player:GetLevel()<g_ZongMenSkill_RequiredPlayerLevel then
			ZongMenSkill_TalentInfo_EffectText1:Hide()
			ZongMenSkill_TalentInfo_EffectTitle1:SetText("#{XFSJ_20250814_6}")
			ZongMenSkill_TalentInfo_LevelUpBtn:SetText("#{ZMTF_230628_215}")
			ZongMenSkill_TalentInfo_LevelUpCondition:Show()
			ZongMenSkill_TalentInfo_LevelUpCondition:SetText("#{XFSJ_20250814_7}")
			ZongMenSkill_TalentInfo_LevelUpCondition2:Hide()
			ZongMenSkill_TalentInfo_LevelUpPoint:Hide()
		else
			if curSkillLevel < g_ZongMenSkill_MaxLevel then
				ZongMenSkill_TalentInfo_LevelUpCondition2:Show()
				ZongMenSkill_TalentInfo_LevelUpCondition2:SetText("#{XFSJ_20250814_8}")
			end
		end
	end

	local action = DataPool:Lua_CreateSectInfoAction(g_ZongMenSkill_SelectedId,curSkillLevel)
	if action then
		ZongMenSkill_TalentInfo_EffectItem:SetActionItem(action:GetID())
	end
	-- PushDebugMessage("nSubTalentType:"..tostring(nSubTalentType))
	for j = 1,6 do 
		if nSubTalentType == j then
			_G["ZongMenSkill_TalentInfo_EffectItem_"..j]:Show()
		else
			_G["ZongMenSkill_TalentInfo_EffectItem_"..j]:Hide()
		end
	end
	ZongMenSkill_TalentInfo_EffectItemText1:SetText(ScriptGlobal_Format("#{ZMDZ_230703_18}", nSectName))
	ZongMenSkill_TalentInfo_EffectItemText2:SetText(ScriptGlobal_Format("#{ZMTF_230628_170}", curSkillLevel))


end

function ZongMenSkill_CoreTalentTreeClicked(index)
	if index<1 or index>5 then
		return
	end
	CloseFreshManGuide()
	PushEvent( "CLOSE_ZONGMENSKILL_INFO")

	g_ZongMenSkill_CurType = 2
	g_ZongMenSkill_CurIndex = index

	for i = 1,table.getn(g_ZongMenSkill_CoreSkillUI) do
		g_ZongMenSkill_CoreSkillUI[i].CheckBtn:SetCheck(0)
	end
	for i = 1,table.getn(g_ZongMenSkill_NormalSkillUI) do
		g_ZongMenSkill_NormalSkillUI[i].CheckBtn:SetCheck(0)
	end
	g_ZongMenSkill_CoreSkillUI[index].CheckBtn:SetCheck(1)
	ZongMenSkill_TalentEquip_Skill:SetCheck(0)
	ZongMenSkill_TalentInfo_LevelUpPoint:Show()
	ZongMenSkill_TalentInfo_LevelUpBtn:Show()
	ZongMenSkill_TalentEquip_LevelUp:Hide()
	local color = "#cFFF263"
	g_ZongMenSkill_SelectedId = DataPool:GetZongMenTalentCoreData(index-1,"SectId")
	local nSubTalentType = DataPool:GetZongMenTalentCoreData(index-1,"SubTalentType")
	local nSectName = DataPool:GetZongMenTalentCoreData(index-1,"Name")

	local curSkillLevel, requireTalentPoint = DataPool:GetZongMenTalentCoreData(index-1,"CurLevel")
	
	local nRequiredEquipLevel = DataPool:GetZongMenTalentCoreData(index-1,"RequiredEquipLevel")
	ZongMenSkill_TalentInfo_LevelUpCondition:Show()
	ZongMenSkill_TalentInfo_LevelUpCondition2:Show()
	ZongMenSkill_TalentInfo_LevelUpCondition:SetText(ScriptGlobal_Format("#{ZMTF_230628_127}", nRequiredEquipLevel))
	ZongMenSkill_TalentInfo_LevelUpCondition2:SetText("#{ZMTF_230628_172}")

	ZongMenSkill_TalentInfo_LevelUpPoint:SetText(ScriptGlobal_Format("#{ZMTF_230628_163}", requireTalentPoint))

	-- ZongMenSkill_TalentInfo_EffectLeftBtn:Disable()
	-- ZongMenSkill_TalentInfo_EffectRightBtn:Enable()
	-- g_ZongMenSkill_CurLevelPageIndex = curSkillLevel+1
	if curSkillLevel<=0 then
		-- ZongMenSkill_TalentInfo_EffectTitle1:Hide()
		ZongMenSkill_TalentInfo_EffectText1:Hide()
		ZongMenSkill_TalentInfo_EffectTitle1:SetText("#{ZMTF_230628_190}")
		-- g_ZongMenSkill_CurLevelPageIndex = 1
		ZongMenSkill_TalentInfo_LevelUpBtn:SetText("#{ZMTF_230628_215}")
	else
		-- ZongMenSkill_TalentInfo_EffectTitle1:Show()
		ZongMenSkill_TalentInfo_EffectText1:Show()
		ZongMenSkill_TalentInfo_EffectText1:SetText(color..DataPool:Lua_GetSectDesc(index-1,curSkillLevel-1, 1))
		ZongMenSkill_TalentInfo_EffectTitle1:SetText(ScriptGlobal_Format("#{ZMTF_230628_125}", curSkillLevel))
		ZongMenSkill_TalentInfo_LevelUpBtn:SetText("#{ZMTF_230628_129}")
	end

	if curSkillLevel >= g_ZongMenSkill_MaxLevel then
		-- ZongMenSkill_TalentInfo_EffectTitle2:Hide()
		ZongMenSkill_TalentInfo_EffectText2:Hide()
		ZongMenSkill_TalentInfo_LevelUpPoint:Hide()
		ZongMenSkill_TalentInfo_LevelUpCondition:Hide()
		ZongMenSkill_TalentInfo_LevelUpCondition2:Hide()
		ZongMenSkill_TalentInfo_EffectTitle2:SetText("#{ZMTF_230628_191}")
		-- ZongMenSkill_TalentInfo_EffectRightBtn:Disable()
	else
		-- ZongMenSkill_TalentInfo_EffectTitle2:Show()
		ZongMenSkill_TalentInfo_EffectText2:Show()
		ZongMenSkill_TalentInfo_EffectText2:SetText(color..DataPool:Lua_GetSectDesc(index-1,curSkillLevel, 1))
		ZongMenSkill_TalentInfo_EffectTitle2:SetText(ScriptGlobal_Format("#{ZMTF_230628_126}", curSkillLevel+1))
	end
	local nRequiredXinFaLevel = DataPool:GetZongMenTalentCoreData(index-1,"RequiredXinFaLevel")

	if nRequiredXinFaLevel == g_ZongMenSkill_NewCoreSectRequiredLevel then
		if Player:GetLevel()<g_ZongMenSkill_RequiredPlayerLevel then
			ZongMenSkill_TalentInfo_EffectText1:Hide()
			ZongMenSkill_TalentInfo_EffectTitle1:SetText("#{XFSJ_20250814_6}")
			ZongMenSkill_TalentInfo_LevelUpBtn:SetText("#{ZMTF_230628_215}")
			ZongMenSkill_TalentInfo_LevelUpCondition:Show()
			ZongMenSkill_TalentInfo_LevelUpCondition:SetText("#{XFSJ_20250814_7}")
			ZongMenSkill_TalentInfo_LevelUpCondition2:Hide()
			ZongMenSkill_TalentInfo_LevelUpPoint:Hide()
		else
			if curSkillLevel < g_ZongMenSkill_MaxLevel then
				ZongMenSkill_TalentInfo_LevelUpCondition2:Show()
				ZongMenSkill_TalentInfo_LevelUpCondition2:SetText("#{XFSJ_20250814_9}")
			end
		end
	end
	
	local action = DataPool:Lua_CreateSectInfoAction(g_ZongMenSkill_SelectedId,curSkillLevel)
	if action then
		ZongMenSkill_TalentInfo_EffectItem:SetActionItem(action:GetID())
	end
	-- PushDebugMessage("nSubTalentType:"..tostring(nSubTalentType))
	for j = 1,6 do 
		if nSubTalentType == j then
			_G["ZongMenSkill_TalentInfo_EffectItem_"..j]:Show()
		else
			_G["ZongMenSkill_TalentInfo_EffectItem_"..j]:Hide()
		end
	end
	ZongMenSkill_TalentInfo_EffectItemText1:SetText(ScriptGlobal_Format("#{ZMDZ_230703_18}", nSectName))
	ZongMenSkill_TalentInfo_EffectItemText2:SetText(ScriptGlobal_Format("#{ZMTF_230628_170}", curSkillLevel))


end

function ZongMenSkill_On_ResetPos()
	ZongMenSkill_Frame:SetProperty("UnifiedPosition", g_ZongMenSkill_Frame_UnifiedPosition)

end

function ZongMenSkill_OnHidden()
	Variable:SetVariable("SkillUnionPos", ZongMenSkill_Frame:GetProperty("UnifiedPosition"), 1)
	g_ZongMenSkill_SelectedId = -1
	g_ZongMenSkill_CurType = 1 
	g_ZongMenSkill_CurIndex = 1
	g_ZongMenSkill_isShowEffect = 0
	ZongMenSkill_Talent_ComboList:ResetList()
	-- ZongMenSkill_Talent_ComboList:SetCurrentSelect(0)
	-- DataPool:ChangeSectSelectedIndex(0)
end

function ZongMenSkill_OnClose()
	local nUseIndex, nSelectedIndex = DataPool:GetZMSectUsePlanIndex()
	if DataPool:GetSectIsModify(nSelectedIndex, 0) == 1 then
		ZongMenSkill_Frame:SetForce()
		PushEvent("SECT_LEAVE_WITHOUT_SAVE", nSelectedIndex , -1, 0)
	else
		this:Hide()
		
	end
end

--天赋加点升级
function ZongMenSkill_TalentInfo_LevelUp_Clicked()
	-- PushDebugMessage("g_ZongMenSkill_SelectedId:"..tostring(g_ZongMenSkill_SelectedId))
	-- Player:Lua_AskSectOper(0,g_ZongMenSkill_SelectedId)

	DataPool:SectSkillLevelUp(g_ZongMenSkill_SelectedId)
	ZongMenSkill_Update()
	if g_ZongMenSkill_CurType == 1 then
		ZongMenSkill_TalentTreeClicked(g_ZongMenSkill_CurIndex)
	elseif g_ZongMenSkill_CurType == 2 then
		ZongMenSkill_CoreTalentTreeClicked(g_ZongMenSkill_CurIndex)
	elseif g_ZongMenSkill_CurType == 3 then
		ZongMenSkill_TalentEquip_SkillClicked()
	end
end

--天赋重置
function ZongMenSkill_Talent_Reset_Clicked()
	--Player:Lua_AskSectOper(2,0)  --0代表第一次发 还需要二次确认

	local usedNormalPoint, usedCorePoint = DataPool:SectSkillReset()
	if usedNormalPoint>=0 then
		local msg = ScriptGlobal_Format("#{ZMTFBC_230920_32}", usedNormalPoint, usedCorePoint)
		PushDebugMessage(msg)
		ZongMenSkill_Update()
	end
end

--分享至聊天
-- function ZongMenSkill_Talent_Share_Clicked()

-- end


--其他界面切换

--普通
function ZongMenSkill_Common_Page_Switch(nPageNumber, isConfirm)
	local nUseIndex, nSelectedIndex = DataPool:GetZMSectUsePlanIndex()
	if DataPool:GetSectIsModify(nSelectedIndex, 0) == 1 and isConfirm == nil then
		PushEvent("SECT_LEAVE_WITHOUT_SAVE", nSelectedIndex ,-1, 1)
		if g_ZongMenSkill_PageButton[nPageNumber] ~= nil then
			g_ZongMenSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		ZongMenSkill_ClearPage()
	else
		OpenCommonSkillPage()
		this:Hide()
	end
	
end


--门派
function ZongMenSkill_Action_Page_Switch(nPageNumber, isConfirm)
	local nUseIndex, nSelectedIndex = DataPool:GetZMSectUsePlanIndex()
	if DataPool:GetSectIsModify(nSelectedIndex, 0) == 1 and isConfirm == nil then
		PushEvent("SECT_LEAVE_WITHOUT_SAVE", nSelectedIndex ,-1, 2)
		if g_ZongMenSkill_PageButton[nPageNumber] ~= nil then
			g_ZongMenSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		ZongMenSkill_ClearPage()
	else
		local menpai = Player:GetData("MEMPAI");
		if(menpai == 9) then 
			if g_ZongMenSkill_PageButton[nPageNumber] ~= nil then
				g_ZongMenSkill_PageButton[nPageNumber]:SetCheck(0)
			end
			ZongMenSkill_ClearPage()
			PushDebugMessage("你还没有拜入门派。");
			return; 
		end;
		OpenSkillBook();
		this:Hide()
	end

end

--阵法
function ZongMenSkill_Zhenfa_Page_Switch(nPageNumber, isConfirm)
	local nUseIndex, nSelectedIndex = DataPool:GetZMSectUsePlanIndex()
	if DataPool:GetSectIsModify(nSelectedIndex, 0) == 1 and isConfirm == nil then
		PushEvent("SECT_LEAVE_WITHOUT_SAVE", nSelectedIndex ,-1, 3)
		if g_ZongMenSkill_PageButton[nPageNumber] ~= nil then
			g_ZongMenSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		ZongMenSkill_ClearPage()
	else
		OpenZhenfaFream();
		this:Hide()
		
	end
	
end

--生活
function ZongMenSkill_Life_Page_Switch(nPageNumber, isConfirm)
	local nUseIndex, nSelectedIndex = DataPool:GetZMSectUsePlanIndex()
	if DataPool:GetSectIsModify(nSelectedIndex, 0) == 1 and isConfirm == nil then
		PushEvent("SECT_LEAVE_WITHOUT_SAVE", nSelectedIndex ,-1, 4)
		if g_ZongMenSkill_PageButton[nPageNumber] ~= nil then
			g_ZongMenSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		ZongMenSkill_ClearPage()
	else
		OpenLifePage();
		this:Hide()
		
	end

end

--战斗
function ZongMenSkill_AutoAttack_Page_Switch(nPageNumber, isConfirm)
	local nUseIndex, nSelectedIndex = DataPool:GetZMSectUsePlanIndex()
	if DataPool:GetSectIsModify(nSelectedIndex, 0) == 1 and isConfirm == nil then
		PushEvent("SECT_LEAVE_WITHOUT_SAVE", nSelectedIndex ,-1, 5)
		if g_ZongMenSkill_PageButton[nPageNumber] ~= nil then
			g_ZongMenSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		ZongMenSkill_ClearPage()
	else
		local myLevel = Player:GetData("LEVEL")
		local nMenpai = Player:GetData("MEMPAI")
		local nCanShow = 1
		if myLevel >= 50 and nMenpai ~= 9 then
			PushEvent("TRIGGER_ZIDONGZHANDOU","config")
			DataPool:Lua_SetLastSkill_UI(6)
			this:Hide()
		elseif myLevel < 50 then
			PushDebugMessage("#{ZDZD_200724_62}")
			nCanShow = 0
		else
			PushDebugMessage("#{ZDZD_200724_63}")
			nCanShow = 0
		end
		if nCanShow == 0 then
			if g_ZongMenSkill_PageButton[nPageNumber] ~= nil then
				g_ZongMenSkill_PageButton[nPageNumber]:SetCheck(0)
			end
			ZongMenSkill_ClearPage()
		end
	end

end


function ZongMenSkill_SetTabColor()
	local selColor = "#e010101#Y";
	local noselColor = "#e010101";
	local tab = {
								[0] = ZongMenSkill_CommonlySkill,
								ZongMenSkill_ActionSkill,
								ZongMenSkill_LifeSkill,
								ZongMenSkill_ZhenfaSkill,
								ZongMenSkill_AutoAttack,
								ZongMenSkill_ZongMenSkill,
							};

	local TAB_TEXT = {
		[0] = "普通",
		"门派",
		"生活",
		"#{JBGXW_150526_215}",
		"#{ZDZD_200724_08}",
		"#{ZMTF_230628_20}",
	};
	
	tab[0]:SetText(noselColor..TAB_TEXT[0])
	tab[1]:SetText(noselColor..TAB_TEXT[1])
	tab[2]:SetText(noselColor..TAB_TEXT[2])
	tab[3]:SetText(noselColor..TAB_TEXT[3])
	tab[4]:SetText(noselColor..TAB_TEXT[4])
	tab[5]:SetText(selColor..TAB_TEXT[5])
end

function ZongMenSkill_ShowPage()

	for i = 1, table.getn(g_ZongMenSkill_PageButton) do
		g_ZongMenSkill_PageButton[i]:Hide()
	end
	local nPageNumber = tonumber(Variable:GetVariable("SkillPageNumber"));
	ZongMenSkill_ClearPage()
	
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_ZongMenSkill_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_ZongMenSkill_PageButton) do
			if i ~= nPageNumber then
				g_ZongMenSkill_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_ZongMenSkill_PageOrder = {}
	local g_ZongMenSkill_PageCount = 0
	
	for i = 1, table.getn(g_ZongMenSkill_PageButton) do
		if ZongMenSkill_CheckPage(i) == 1 then
			g_ZongMenSkill_PageCount = g_ZongMenSkill_PageCount + 1
			g_ZongMenSkill_PageButton[g_ZongMenSkill_PageCount]:Show()
			g_ZongMenSkill_PageButton[g_ZongMenSkill_PageCount]:SetText(g_ZongMenSkill_Page[i].Text)	
			g_ZongMenSkill_PageOrder[g_ZongMenSkill_PageCount] = i
		end
	end
	
	for idx = 1, table.getn(g_ZongMenSkill_PageOrder) do
		if g_ZongMenSkill_PageOrder[idx] == 6 and g_PageTipsPos[idx] then -- 绝学
			local newpos = g_PageTipsPos[idx]
			ZongMenSkill_ZongMenSkill_Tips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
end

function ZongMenSkill_OnPageClicked(idx, isConfirm)

	Variable:SetVariable("SkillPageNumber", tostring(idx), 1);
	idx = g_ZongMenSkill_PageOrder[idx]
	local nPageNumber = tonumber(Variable:GetVariable("SkillPageNumber"));
	
	if idx == 1 then--普通
		ZongMenSkill_Common_Page_Switch(nPageNumber)
	elseif idx == 2 then--门派
		ZongMenSkill_Action_Page_Switch(nPageNumber)
	elseif idx == 3 then--阵法
		ZongMenSkill_Zhenfa_Page_Switch(nPageNumber)
	elseif idx == 4 then--生活
		ZongMenSkill_Life_Page_Switch(nPageNumber)
	elseif idx == 5 then--战斗
		ZongMenSkill_AutoAttack_Page_Switch(nPageNumber)
	elseif idx == 6 then --绝学
		ZongMenSkill_ClearPage()
	end
	
end

function ZongMenSkill_CheckPage(idx)
	if idx == 1 then--普通
		return 1
	elseif idx == 2 then--门派
		return 1
	elseif idx == 3 then--阵法
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 4 then--生活
		return 1
	elseif idx == 5 then--战斗
		return 1
	elseif idx == 6 then--绝学
		return 1
	end
	return 0
end

function ZongMenSkill_ClearPage()
	Variable:SetVariable("SkillPageNumber", tostring(0), 1)
end


function ZongMenSkill_OnLoad()
	g_ZongMenSkill_Frame_UnifiedPosition = ZongMenSkill_Frame:GetProperty("UnifiedPosition")
	--ZongMenSkill_SetTabColor()
	-- ZongMenSkill_InitCombo()

	g_ZongMenSkill_CoreSkillUI = 
	{
		[1] = {
			CheckBtn = ZongMenSkill_TalentBtn11,
			ActionItem = ZongMenSkill_TalentIcon11,
			NameLabel = ZongMenSkill_TalentName11,
			TalentLabel = ZongMenSkill_TalentNum11,
			LockMask = ZongMenSkill_TalentLock11,
			IconLockMask = ZongMenSkill_TalentIconLock11,
			TalentTypeIcon = ZongMenSkill_TalentAttr11Frame,
			Animate = ZongMenSkill_TalentIconLevelUp11,
		},
		[2] = {
			CheckBtn = ZongMenSkill_TalentBtn12,
			ActionItem = ZongMenSkill_TalentIcon12,
			NameLabel = ZongMenSkill_TalentName12,
			TalentLabel = ZongMenSkill_TalentNum12,
			LockMask = ZongMenSkill_TalentLock12,
			IconLockMask = ZongMenSkill_TalentIconLock12,
			TalentTypeIcon = ZongMenSkill_TalentAttr12Frame,
			Animate = ZongMenSkill_TalentIconLevelUp12,
		},
		[3] = {
			CheckBtn = ZongMenSkill_TalentBtn13,
			ActionItem = ZongMenSkill_TalentIcon13,
			NameLabel = ZongMenSkill_TalentName13,
			TalentLabel = ZongMenSkill_TalentNum13,
			LockMask = ZongMenSkill_TalentLock13,
			IconLockMask = ZongMenSkill_TalentIconLock13,
			TalentTypeIcon = ZongMenSkill_TalentAttr13Frame,
			Animate = ZongMenSkill_TalentIconLevelUp13,
		},
		[4] = {
			CheckBtn = ZongMenSkill_TalentBtn14,
			ActionItem = ZongMenSkill_TalentIcon14,
			NameLabel = ZongMenSkill_TalentName14,
			TalentLabel = ZongMenSkill_TalentNum14,
			LockMask = ZongMenSkill_TalentLock14,
			IconLockMask = ZongMenSkill_TalentIconLock14,
			TalentTypeIcon = ZongMenSkill_TalentAttr14Frame,
			Animate = ZongMenSkill_TalentIconLevelUp14,
		},
		[5] = {
			CheckBtn = ZongMenSkill_TalentBtn16,
			ActionItem = ZongMenSkill_TalentIcon16,
			NameLabel = ZongMenSkill_TalentName16,
			TalentLabel = ZongMenSkill_TalentNum16,
			LockMask = ZongMenSkill_TalentLock16,
			IconLockMask = ZongMenSkill_TalentIconLock16,
			TalentTypeIcon = ZongMenSkill_TalentAttr16Frame,
			Animate = ZongMenSkill_TalentIconLevelUp16,
			LevelLock = ZongMenSkill_TalentLevelLock16,
		},
		
	}

	g_ZongMenSkill_NormalSkillUI =
	{
		[1] = {
			CheckBtn = ZongMenSkill_TalentBtn1,
			ActionItem = ZongMenSkill_TalentIcon1,
			NameLabel = ZongMenSkill_TalentName1,
			TalentLabel = ZongMenSkill_TalentNum1,
			LockMask = ZongMenSkill_TalentLock1,
			IconLockMask = ZongMenSkill_TalentIconLock1,
			TalentTypeIcon = ZongMenSkill_TalentAttr1Frame,
			Animate = ZongMenSkill_TalentIconLevelUp1,
		},
		[2] = {
			CheckBtn = ZongMenSkill_TalentBtn2,
			ActionItem = ZongMenSkill_TalentIcon2,
			NameLabel = ZongMenSkill_TalentName2,
			TalentLabel = ZongMenSkill_TalentNum2,
			LockMask = ZongMenSkill_TalentLock2,
			IconLockMask = ZongMenSkill_TalentIconLock2,
			TalentTypeIcon = ZongMenSkill_TalentAttr2Frame,
			Animate = ZongMenSkill_TalentIconLevelUp2,
		},
		[3] = {
			CheckBtn = ZongMenSkill_TalentBtn3,
			ActionItem = ZongMenSkill_TalentIcon3,
			NameLabel = ZongMenSkill_TalentName3,
			TalentLabel = ZongMenSkill_TalentNum3,
			LockMask = ZongMenSkill_TalentLock3,
			IconLockMask = ZongMenSkill_TalentIconLock3,
			TalentTypeIcon = ZongMenSkill_TalentAttr3Frame,
			Animate = ZongMenSkill_TalentIconLevelUp3,
		},
		[4] = {
			CheckBtn = ZongMenSkill_TalentBtn4,
			ActionItem = ZongMenSkill_TalentIcon4,
			NameLabel = ZongMenSkill_TalentName4,
			TalentLabel = ZongMenSkill_TalentNum4,
			LockMask = ZongMenSkill_TalentLock4,
			IconLockMask = ZongMenSkill_TalentIconLock4,
			TalentTypeIcon = ZongMenSkill_TalentAttr4Frame,
			Animate = ZongMenSkill_TalentIconLevelUp4,
		},
		[5] = {
			CheckBtn = ZongMenSkill_TalentBtn5,
			ActionItem = ZongMenSkill_TalentIcon5,
			NameLabel = ZongMenSkill_TalentName5,
			TalentLabel = ZongMenSkill_TalentNum5,
			LockMask = ZongMenSkill_TalentLock5,
			IconLockMask = ZongMenSkill_TalentIconLock5,
			TalentTypeIcon = ZongMenSkill_TalentAttr5Frame,
			Animate = ZongMenSkill_TalentIconLevelUp5,
		},
		[6] = {
			CheckBtn = ZongMenSkill_TalentBtn6,
			ActionItem = ZongMenSkill_TalentIcon6,
			NameLabel = ZongMenSkill_TalentName6,
			TalentLabel = ZongMenSkill_TalentNum6,
			LockMask = ZongMenSkill_TalentLock6,
			IconLockMask = ZongMenSkill_TalentIconLock6,
			TalentTypeIcon = ZongMenSkill_TalentAttr6Frame,
			Animate = ZongMenSkill_TalentIconLevelUp6,
		},
		[7] = {
			CheckBtn = ZongMenSkill_TalentBtn7,
			ActionItem = ZongMenSkill_TalentIcon7,
			NameLabel = ZongMenSkill_TalentName7,
			TalentLabel = ZongMenSkill_TalentNum7,
			LockMask = ZongMenSkill_TalentLock7,
			IconLockMask = ZongMenSkill_TalentIconLock7,
			TalentTypeIcon = ZongMenSkill_TalentAttr7Frame,
			Animate = ZongMenSkill_TalentIconLevelUp7,
		},
		[8] = {
			CheckBtn = ZongMenSkill_TalentBtn8,
			ActionItem = ZongMenSkill_TalentIcon8,
			NameLabel = ZongMenSkill_TalentName8,
			TalentLabel = ZongMenSkill_TalentNum8,
			LockMask = ZongMenSkill_TalentLock8,
			IconLockMask = ZongMenSkill_TalentIconLock8,
			TalentTypeIcon = ZongMenSkill_TalentAttr8Frame,
			Animate = ZongMenSkill_TalentIconLevelUp8,
		},
		[9] = {
			CheckBtn = ZongMenSkill_TalentBtn9,
			ActionItem = ZongMenSkill_TalentIcon9,
			NameLabel = ZongMenSkill_TalentName9,
			TalentLabel = ZongMenSkill_TalentNum9,
			LockMask = ZongMenSkill_TalentLock9,
			IconLockMask = ZongMenSkill_TalentIconLock9,
			TalentTypeIcon = ZongMenSkill_TalentAttr9Frame,
			Animate = ZongMenSkill_TalentIconLevelUp9,
		},
		[10] = {
			CheckBtn = ZongMenSkill_TalentBtn10,
			ActionItem = ZongMenSkill_TalentIcon10,
			NameLabel = ZongMenSkill_TalentName10,
			TalentLabel = ZongMenSkill_TalentNum10,
			LockMask = ZongMenSkill_TalentLock10,
			IconLockMask = ZongMenSkill_TalentIconLock10,
			TalentTypeIcon = ZongMenSkill_TalentAttr10Frame,
			Animate = ZongMenSkill_TalentIconLevelUp10,
		},
		[11] = {
			CheckBtn = ZongMenSkill_TalentBtn15,
			ActionItem = ZongMenSkill_TalentIcon15,
			NameLabel = ZongMenSkill_TalentName15,
			TalentLabel = ZongMenSkill_TalentNum15,
			LockMask = ZongMenSkill_TalentLock15,
			IconLockMask = ZongMenSkill_TalentIconLock15,
			TalentTypeIcon = ZongMenSkill_TalentAttr15Frame,
			Animate = ZongMenSkill_TalentIconLevelUp15,
			LevelLock = ZongMenSkill_TalentLevelLock15,
		},
	}


	g_ZongMenSkill_PageButton[1] = ZongMenSkill_CommonlySkill
	g_ZongMenSkill_PageButton[2] = ZongMenSkill_ActionSkill
	g_ZongMenSkill_PageButton[3] = ZongMenSkill_ZhenfaSkill
	g_ZongMenSkill_PageButton[4] = ZongMenSkill_LifeSkill
	g_ZongMenSkill_PageButton[5] = ZongMenSkill_AutoAttack
	g_ZongMenSkill_PageButton[6] = ZongMenSkill_ZongMenSkill
	
	g_PageTipsPos[1] = "{0.000000,28.000000}" 
	g_PageTipsPos[2] = "{0.000000,64.000000}" 
	g_PageTipsPos[3] = "{0.000000,100.000000}"
	g_PageTipsPos[4] = "{0.000000,136.000000}"
	g_PageTipsPos[5] = "{0.000000,172.000000}"
	g_PageTipsPos[6] = "{0.000000,208.000000}"
	
end


function ZongMenSkill_OpenPaTa()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenMainUI" )
		Set_XSCRIPT_ScriptID( 998633 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ZongMenSkill_TalentEquip_Clicked(flag)
	if flag == 1 then
		ZongMenSkill_TalentEquip:DoAction()
	else
		ZongMenSkill_TalentEquip:DoSubAction()
	end
end

function ZongMenSkill_UpdateGemContainer()

    ---当玩家未学会万宝随身互换时，装备位宝石查看按钮为灰态
    local gemSwitchSkillID = 278

	if Player:GetSkillInfo(gemSwitchSkillID, "learn") then
		--ZongMenSkill_TalentEquip_GemBK:Hide()
	else
		--ZongMenSkill_TalentEquip_GemRed:Hide()
		--ZongMenSkill_TalentEquip_GemGreen:Hide()
		--ZongMenSkill_TalentEquip_GemBK:Show()
		return
	end

    local ret = ZongMenSkill_Can_SwitchGem(18, 23)
    if ret == 1 then
		--正常态：玩家学会万宝随身互换，装备位上存在装备且所有装备位上的宝石都可以进行互换时
		--ZongMenSkill_TalentEquip_GemGreen:Enable()
		--ZongMenSkill_TalentEquip_GemGreen:Show()
		--ZongMenSkill_TalentEquip_GemGreen:SetToolTip("#{WBSS_120727_44}")
		--ZongMenSkill_TalentEquip_GemRed:Hide()
    else
		--异常态：玩家学会万宝随身互换，装备位上不存在装备或非所有装备位上的宝石都可以进行互换时
		--ZongMenSkill_TalentEquip_GemRed:Enable()
		--ZongMenSkill_TalentEquip_GemRed:Show()
		--ZongMenSkill_TalentEquip_GemRed:SetToolTip( "#{WBSS_120727_44}" )
		--ZongMenSkill_TalentEquip_GemGreen:Hide()
    end
end

function ZongMenSkill_TalentEquip_GemRed_Clicked()
	PushEvent("GEM_CONTAINER_CHECK", 19, 0)
end

function ZongMenSkill_TalentEquip_GemGreen_Clicked()
	PushEvent("GEM_CONTAINER_CHECK", 19, 0)
end

function ZongMenSkill_Can_SwitchGem(gem_con_index, equip_point)

    --得到装备上的宝石
    local equipTypeList = {}
    local isHaveEquip, gemIndex1, gemIndex2, gemIndex3, gemIndex4 = LifeAbility:SplitWearedEquipGem(equip_point)
    local gemIndexList  = {}
    gemIndexList[1] = gemIndex1
    gemIndexList[2] = gemIndex2
    gemIndexList[3] = gemIndex3
    gemIndexList[4] = gemIndex4
    if isHaveEquip == 1 then
        for i = 1, 4 do
            if gemIndexList[i] > 0 then
                equipTypeList[i] = SelfEquip_GetGemTypeByIndex(gemIndexList[i])
            else
                equipTypeList[i] = -1
            end
        end
    else
        --没有装备
        return 0
    end

    --其次得到装备位上的宝石类型
    local gemConTypeList = {}
    local bHaveGemCon = 0	--装备位上是否有宝石
    LifeAbility:GemContainer_Update()
    for i = 1, 4 do
        local nItemID, tmpGemType
        nItemID, _, tmpGemType = LifeAbility:GetGemContainer_Gem(gem_con_index, i - 1)
        if nItemID ~= -1 then
            gemConTypeList[i] = tmpGemType
            bHaveGemCon = 1
        else
            gemConTypeList[i] = -1
        end
    end

    if bHaveGemCon == 0 then
        return 0
    end

    --判断装备位上的所有宝石对应的当前装备上的孔位是否都存在宝石
    for i = 1, 4 do
        --如果装备位上有宝石
        if gemConTypeList[i] > 0 then
            --判断装备位上的所有宝石对应的当前装备上的孔位是否都存在宝石
            if equipTypeList[i] <= 0 then
                return 0
            end
            equipTypeList[i] = gemConTypeList[i]
        end
    end

    --- 判断互换后，当前装备前三孔是否会出现同类型宝石
    if equipTypeList[1] > 0 then
        if equipTypeList[1] == equipTypeList[2] or equipTypeList[1] == equipTypeList[3] then
            return 0
        end
    end

    if equipTypeList[2] > 0 then
        if equipTypeList[1] == equipTypeList[2] or equipTypeList[2] == equipTypeList[3] then
            return 0
        end
    end

    if equipTypeList[3] > 0 then
        if equipTypeList[1] == equipTypeList[3] or equipTypeList[2] == equipTypeList[3] then
            return 0
        end
    end

    return 1
end

function ZongMenSkill_UpdateEquip()
	ZongMenSkill_TalentEquip:SetActionItem(-1)
	local ActionEquip = EnumAction(23, "equip")
	ZongMenSkill_TalentEquip:SetActionItem(ActionEquip:GetID())
	
	ZongMenSkill_UpdateGemContainer()
	
	-- PushDebugMessage( "ActionEquip:"..tostring(ActionEquip:GetID()))
	--装备所带的技能刷新
	local nSectId, nLogicType, nAddSkill, nSectLevel, nName, nSubTalentType = DataPool:GetSectEquipSkill()
	--PushDebugMessage( "nSectLevel:"..tostring(nSectLevel))
	
	ZongMenSkill_TalentEquip_SkillIconLevelUp:Play(false)
	-- PushDebugMessage( "nSectId:"..tostring(nSectId))
	-- if ActionEquip:GetID() > 0 then
	-- ZongMenSkill_TalentEquip_SkillName:Show()
	ZongMenSkill_TalentEquip_SkillNum:Show()
	ZongMenSkill_TalentEquip_SkillName:SetText(nName)
	ZongMenSkill_TalentEquip_SkillNum:SetText(tostring(nSectLevel).."/"..tostring(g_ZongMenSkill_MaxLevel))
	for j = 1,6 do 
		if nSubTalentType == j then
			_G["ZongMenSkill_TalentEquip_Skill_"..j]:Show()
		else
			_G["ZongMenSkill_TalentEquip_Skill_"..j]:Hide()
		end
	end


	if nLogicType == 5 and nSectLevel>0 and ActionEquip:GetID() > 0 then
		
		local nSumSkill = GetActionNum("skill")
	
		for j=1, nSumSkill do
			local theAction = EnumAction(j-1, "skill")
			
			if theAction:GetDefineID() == nAddSkill then	
			
				ZongMenSkill_TalentEquip_SkillIcon:SetProperty("DraggingEnabled","True")
				ZongMenSkill_TalentEquip_SkillIcon:SetActionItem(theAction:GetID())
			
			end
		end
	else
		local action = DataPool:Lua_CreateSectInfoAction(nSectId,nSectLevel)
		if action then
			ZongMenSkill_TalentEquip_SkillIcon:SetActionItem(action:GetID())
		end
	end

	if ActionEquip:GetID() > 0 then
		ZongMenSkill_TalentEquip_SkillIconLock:Hide()
		ZongMenSkill_TalentEquip_SkillLock:Hide()
	else
		ZongMenSkill_TalentEquip_SkillIconLock:Show()
		ZongMenSkill_TalentEquip_SkillLock:Show()
	end
	-- else	
	-- 	ZongMenSkill_TalentEquip_SkillIcon:SetActionItem(-1)
	-- 	ZongMenSkill_TalentEquip_SkillName:Hide()
	-- 	ZongMenSkill_TalentEquip_SkillNum:Hide()
	-- 	for j = 1,6 do 
	-- 		_G["ZongMenSkill_TalentEquip_Skill_"..j]:Hide()
	-- 	end
	-- end

	if g_ZongMenSkill_CurType == 3 then
		ZongMenSkill_TalentEquip_SkillClicked()
	end


end

function ZongMenSkill_TalentEquip_SkillClicked()
	
	PushEvent( "CLOSE_ZONGMENSKILL_INFO")

	g_ZongMenSkill_CurType = 3

	for i = 1,table.getn(g_ZongMenSkill_CoreSkillUI) do
		g_ZongMenSkill_CoreSkillUI[i].CheckBtn:SetCheck(0)
	end
	for i = 1,table.getn(g_ZongMenSkill_NormalSkillUI) do
		g_ZongMenSkill_NormalSkillUI[i].CheckBtn:SetCheck(0)
	end
	ZongMenSkill_TalentEquip_Skill:SetCheck(1)
	local nSectId, nLogicType, nAddSkill, nSectLevel, nName, nSubTalentType = DataPool:GetSectEquipSkill()
	g_ZongMenSkill_SelectedId = nSectId
	local ActionEquip = EnumAction(23, "equip")

	-- if ActionEquip:GetID() > 0 then
	
	local color = "#cFFF263"

	-- ZongMenSkill_TalentInfo_EffectLeftBtn:Disable()
	-- ZongMenSkill_TalentInfo_EffectRightBtn:Enable()
	-- g_ZongMenSkill_CurLevelPageIndex = nSectLevel+1

	if nSectLevel<=0 then
		-- ZongMenSkill_TalentInfo_EffectTitle1:Hide()
		ZongMenSkill_TalentInfo_EffectText1:Hide()
		ZongMenSkill_TalentInfo_EffectTitle1:SetText("#{XWXT_230825_30}")
		-- g_ZongMenSkill_CurLevelPageIndex = 1
	else
		-- ZongMenSkill_TalentInfo_EffectTitle1:Show()
		ZongMenSkill_TalentInfo_EffectText1:Show()
		ZongMenSkill_TalentInfo_EffectText1:SetText(color..DataPool:Lua_GetSectDesc(0,nSectLevel-1, 2))
		ZongMenSkill_TalentInfo_EffectTitle1:SetText(ScriptGlobal_Format("#{ZMTF_230628_125}", nSectLevel))
	
	end

	if nSectLevel >= g_ZongMenSkill_MaxLevel then
		-- ZongMenSkill_TalentInfo_EffectTitle2:Hide()
		ZongMenSkill_TalentInfo_EffectText2:Hide()
		ZongMenSkill_TalentInfo_EffectTitle2:SetText("#{ZMTF_230628_191}")
		-- ZongMenSkill_TalentInfo_EffectRightBtn:Disable()
	
	else
		-- ZongMenSkill_TalentInfo_EffectTitle2:Show()
		ZongMenSkill_TalentInfo_EffectText2:Show()
		ZongMenSkill_TalentInfo_EffectText2:SetText(color..DataPool:Lua_GetSectDesc(0,nSectLevel, 2))
		ZongMenSkill_TalentInfo_EffectTitle2:SetText(ScriptGlobal_Format("#{ZMTF_230628_126}", nSectLevel+1))
	end


	local action = DataPool:Lua_CreateSectInfoAction(nSectId,nSectLevel)
	if action then
		ZongMenSkill_TalentInfo_EffectItem:SetActionItem(action:GetID())
	end
	for j = 1,6 do 
		if nSubTalentType == j then
			_G["ZongMenSkill_TalentInfo_EffectItem_"..j]:Show()
		else
			_G["ZongMenSkill_TalentInfo_EffectItem_"..j]:Hide()
		end
	end
	ZongMenSkill_TalentInfo_EffectItemText1:SetText(ScriptGlobal_Format("#{ZMDZ_230703_18}", nName))
	ZongMenSkill_TalentInfo_EffectItemText2:SetText(ScriptGlobal_Format("#{ZMTF_230628_170}", nSectLevel))

	-- else
	-- 	ZongMenSkill_TalentInfo_EffectItem:SetActionItem(-1)
	-- 	for j = 1,6 do 
	-- 		_G["ZongMenSkill_TalentInfo_EffectItem_"..j]:Hide()
	-- 	end
	-- 	ZongMenSkill_TalentInfo_EffectItemText1:SetText("")
	-- 	ZongMenSkill_TalentInfo_EffectItemText2:SetText("")

	-- 	ZongMenSkill_TalentInfo_EffectTitle1:Hide()
	-- 	ZongMenSkill_TalentInfo_EffectText1:Hide()

	-- 	ZongMenSkill_TalentInfo_EffectTitle2:Hide()
	-- 	ZongMenSkill_TalentInfo_EffectText2:Hide()

	-- 	--升级绝学按钮暂时不隐藏 测试用
		
	-- end
	ZongMenSkill_TalentEquip_LevelUp:Show()
	ZongMenSkill_TalentInfo_LevelUpPoint:Hide()
	ZongMenSkill_TalentInfo_LevelUpBtn:Hide()
	ZongMenSkill_TalentInfo_LevelUpCondition:Hide()
	ZongMenSkill_TalentInfo_LevelUpCondition2:Hide()
end

function ZongMenSkill_SufferHelp_Clicked()
	PushEvent("OPEN_SWEEPPAGE_QUEST", "ZongMenSkill_SufferHelp")
end

