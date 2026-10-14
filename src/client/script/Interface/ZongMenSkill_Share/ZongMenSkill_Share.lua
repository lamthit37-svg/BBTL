local g_ZongMenSkill_Share_Frame_UnifiedPosition
local g_ZongMenSkill_Share_NormalSkillUI = {}
local g_ZongMenSkill_Share_CoreSkillUI = {}
local g_ZongMenSkill_Share_MaxLevel = 5 

local g_ZongMenSkill_Share_DefaultSectName=
{
	[0] = "#{ZMTFBC_230920_10}",
	[1] = "#{ZMTFBC_230920_11}",
	[2] = "#{ZMTFBC_230920_12}",
	[3] = "#{ZMTFBC_230920_13}",
	[4] = "#{ZMTFBC_230920_14}",
}

function ZongMenSkill_Share_PreLoad()
	this:RegisterEvent("OPEN_SHARESECT", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("SECT_UPDATE_COMBOLIST", false)
end

									

function ZongMenSkill_Share_OnEvent(event)
	if event == "OPEN_SHARESECT" then
		if this:IsVisible() then
			ZongMenSkill_Share_OnClose()
		end
		ZongMenSkill_Share_Open()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ZongMenSkill_Share_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		ZongMenSkill_Share_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ZongMenSkill_Share_OnClose()
	elseif event == "SECT_UPDATE_COMBOLIST" then
		local nUseIndex, nSelectedIndex = DataPool:GetZMSectUsePlanIndex()
		for i = 1, 2 do
			if (i-1) == nUseIndex then
				ZongMenSkill_Share_ComboList:SetTextItemText( i - 1,"#G"..ZongMenSkill_Share_GetName(i-1).."#{ZMTFBC_230920_62}")
			else
				ZongMenSkill_Share_ComboList:SetTextItemText(i - 1,ZongMenSkill_Share_GetName(i-1))
			end
		end
		local planName, nIndex = ZongMenSkill_Share_ComboList:GetCurrentSelect()
		ZongMenSkill_Share_ComboList:SetCurrentSelect(nIndex)
	end
			
end

function ZongMenSkill_Share_Save_Clicked()
	local planName, nIndex = ZongMenSkill_Share_ComboList:GetCurrentSelect()
	local nUseIndex, nSelectedIndex = DataPool:GetZMSectUsePlanIndex()

	local nEquipSectId, nEquipSectLevel, nEquipSubTalentType, nShareSectItemTableIndex, nShareMenpai, nDiziLevel, nMenpai, nShareName = DataPool:GetShareSectEquipSkill()
	if nMenpai ~= nShareMenpai then
		PushDebugMessage("#{ZMTFBC_230920_52}")
		return
	end

	-- if nIndex == nUseIndex then
	-- 	PushDebugMessage("#{ZMTFBC_230920_70}")
	-- 	return
	-- end

	if DataPool:GetSectIsModify(nIndex, 1) == 0 then
		PushDebugMessage("#{ZMTFBC_230920_26}")
		return
	end
	if DataPool:GetSectIsBackLevel(nIndex, 1) == 1 then
		PushEvent("SECT_SAVEPLAN_CONFIRM", nIndex, 1)
	else
		Player:SaveShareSect(nIndex)
	end
end

function ZongMenSkill_Share_InitCombo()
	local nUseIndex,nSelectedIndex = DataPool:GetZMSectUsePlanIndex()
	for i = 1, 2 do
		if (i-1) == nUseIndex then
			ZongMenSkill_Share_ComboList:ComboBoxAddItem("#G"..tostring(i-1).."#{ZMTFBC_230920_62}", i - 1)
		else
			ZongMenSkill_Share_ComboList:ComboBoxAddItem(tostring(i-1), i - 1);
		end
	 end
	--  ZongMenSkill_Share_ComboList:SetCurrentSelect(0)
end

function ZongMenSkill_Share_ComboList_SelectChanged()
end

function ZongMenSkill_Share_GetName(index)
	-- local res,nSectName = DataPool:GetSectNameByIndex(index)
	-- if res>0 then
	-- 	return nSectName
	-- else
	return g_ZongMenSkill_Share_DefaultSectName[index]
	-- end
end

function ZongMenSkill_Share_UpdateComboList()
	local nUseIndex, nSelectedIndex = DataPool:GetZMSectUsePlanIndex()
	for i = 1, 2 do
		if (i-1) == nUseIndex then
			ZongMenSkill_Share_ComboList:SetTextItemText( i - 1,"#G"..ZongMenSkill_Share_GetName(i-1).."#{ZMTFBC_230920_62}")
		else
			ZongMenSkill_Share_ComboList:SetTextItemText(i - 1,ZongMenSkill_Share_GetName(i-1))
		end
	end

	-- ZongMenSkill_Share_ComboList:SetCurrentSelect(nSelectedIndex)
	ZongMenSkill_Share_ComboList:SetCurrentSelect(0)
end

function ZongMenSkill_Share_Open()
	this:Show()
	ZongMenSkill_Share_InitCombo()
	ZongMenSkill_Share_UpdateComboList()


	local nEquipXWLevel = DataPool:GetShareEquipXinWuLevel()
	local nEquipSectId, nEquipSectLevel, nEquipSubTalentType, nShareSectItemTableIndex, nShareMenpai, nDiziLevel, nMenpai, nShareName = DataPool:GetShareSectEquipSkill()
	DataPool:InitShareSectSkillList(nShareMenpai)


	local coreSkillCount = DataPool:GetShareZMCoreDataCount()

	for i = 1,table.getn(g_ZongMenSkill_Share_CoreSkillUI) do
		
		local nSectId = DataPool:GetShareZongMenTalentData(i-1, 0, "SectId")
		
		local curSkillLevel, requireTalentPoint = DataPool:GetShareZongMenTalentData(i-1, 0, "ShareSectCurLevel")
		
		local nSubTalentType = DataPool:GetShareZongMenTalentData(i-1, 0, "SubTalentType")
		local nRequiredEquipLevel = DataPool:GetShareZongMenTalentData(i-1, 0, "RequiredEquipLevel")
		local nLogicType = DataPool:GetShareZongMenTalentData(i-1, 0, "LogicType")
		local nAddSkill = DataPool:GetShareZongMenTalentData(i-1, 0, "AddSkill")
	
		g_ZongMenSkill_Share_CoreSkillUI[i].TalentTypeIcon:Show()
		-- PushDebugMessage( "curSkillLevel:"..tostring(curSkillLevel) )
		for j = 1,6 do 
			if nSubTalentType == j then
				_G["ZongMenSkill_Share_TalentAttr"..(i+10).."_"..j]:Show()
			else
				_G["ZongMenSkill_Share_TalentAttr"..(i+10).."_"..j]:Hide()
			end
		end
		
		g_ZongMenSkill_Share_CoreSkillUI[i].TalentLabel:SetText(tostring(curSkillLevel).."/"..tostring(g_ZongMenSkill_Share_MaxLevel))

		g_ZongMenSkill_Share_CoreSkillUI[i].ActionItem:SetProperty("DraggingEnabled","False")

		
		local action = DataPool:Lua_CreateSectInfoAction(nSectId,curSkillLevel)
		if action then
			g_ZongMenSkill_Share_CoreSkillUI[i].ActionItem:SetActionItem(action:GetID())
		end
		

		if nEquipXWLevel <=0 then
			
			g_ZongMenSkill_Share_CoreSkillUI[i].LockMask:Show()
			g_ZongMenSkill_Share_CoreSkillUI[i].IconLockMask:Show()
		else
			if nEquipXWLevel < nRequiredEquipLevel then
				
				g_ZongMenSkill_Share_CoreSkillUI[i].LockMask:Show()
				g_ZongMenSkill_Share_CoreSkillUI[i].IconLockMask:Show()
			else
				g_ZongMenSkill_Share_CoreSkillUI[i].LockMask:Hide()
				if curSkillLevel > 0 then
					g_ZongMenSkill_Share_CoreSkillUI[i].IconLockMask:Hide()
				else
					g_ZongMenSkill_Share_CoreSkillUI[i].IconLockMask:Show()
				end

			end
		end

	end

	local normalSkillCount = DataPool:GetShareZMNormalDataCount()

	for i = 1,table.getn(g_ZongMenSkill_Share_NormalSkillUI) do
		
		local nSectId = DataPool:GetShareZongMenTalentData(i-1, 1, "SectId")
		local curSkillLevel, requireTalentPoint = DataPool:GetShareZongMenTalentData(i-1, 1, "ShareSectCurLevel")

		local nSubTalentType = DataPool:GetShareZongMenTalentData(i-1, 1, "SubTalentType")
		local nRequiredEquipLevel = DataPool:GetShareZongMenTalentData(i-1, 1, "RequiredEquipLevel")
		local nLogicType = DataPool:GetShareZongMenTalentData(i-1, 1, "LogicType")
		local nAddSkill = DataPool:GetShareZongMenTalentData(i-1, 1, "AddSkill")
	
		g_ZongMenSkill_Share_NormalSkillUI[i].TalentTypeIcon:Show()
		-- PushDebugMessage( "curSkillLevel:"..tostring(curSkillLevel) )
		for j = 1,6 do 
			if nSubTalentType == j then
				_G["ZongMenSkill_Share_TalentAttr"..i.."_"..j]:Show()
			else
				_G["ZongMenSkill_Share_TalentAttr"..i.."_"..j]:Hide()
			end
		end
		
		g_ZongMenSkill_Share_NormalSkillUI[i].TalentLabel:SetText(tostring(curSkillLevel).."/"..tostring(g_ZongMenSkill_Share_MaxLevel))

		g_ZongMenSkill_Share_NormalSkillUI[i].ActionItem:SetProperty("DraggingEnabled","False")
		
		local action = DataPool:Lua_CreateSectInfoAction(nSectId,curSkillLevel)
		if action then
			g_ZongMenSkill_Share_NormalSkillUI[i].ActionItem:SetActionItem(action:GetID())
		end

		if nEquipXWLevel <=0 then
			
			g_ZongMenSkill_Share_NormalSkillUI[i].LockMask:Show()
			g_ZongMenSkill_Share_NormalSkillUI[i].IconLockMask:Show()
		else
			if nEquipXWLevel < nRequiredEquipLevel then
			
				g_ZongMenSkill_Share_NormalSkillUI[i].LockMask:Show()
				g_ZongMenSkill_Share_NormalSkillUI[i].IconLockMask:Show()
			else
				g_ZongMenSkill_Share_NormalSkillUI[i].LockMask:Hide()
				if curSkillLevel > 0 then
					g_ZongMenSkill_Share_NormalSkillUI[i].IconLockMask:Hide()
				else
					g_ZongMenSkill_Share_NormalSkillUI[i].IconLockMask:Show()
				end

			end
		end

	end

	if nEquipXWLevel > 0 then
		ZongMenSkill_Share_TalentEquip_SkillIconLock:Hide()
		ZongMenSkill_Share_TalentEquip_SkillLock:Hide()
	else
		ZongMenSkill_Share_TalentEquip_SkillIconLock:Show()
		ZongMenSkill_Share_TalentEquip_SkillLock:Show()
	end

	if nEquipSectId>0 then
		
		ZongMenSkill_Share_TalentEquip_SkillNum:SetText(tostring(nEquipSectLevel).."/"..tostring(g_ZongMenSkill_Share_MaxLevel))
		for j = 1,6 do 
			if nEquipSubTalentType == j then
				_G["ZongMenSkill_Share_TalentEquip_Skill_"..j]:Show()
			else
				_G["ZongMenSkill_Share_TalentEquip_Skill_"..j]:Hide()
			end
		end

		local action = DataPool:Lua_CreateSectInfoAction(nEquipSectId,nEquipSectLevel)
		if action then
			ZongMenSkill_Share_TalentEquip_SkillIcon:SetActionItem(action:GetID())
		end
	end
	local strIcon = DataPool:LuaFnGetItemIconByTableIndex(nShareSectItemTableIndex)
	local strImage = GetIconFullName(strIcon)
	ZongMenSkill_Share_TalentEquip:SetProperty("Image", strImage)


	ZongMenSkill_Share_DragTitle:SetText(ScriptGlobal_Format("#{ZMTFBC_230920_38}",nShareName))

	ZongMenSkill_Share_LevelText:SetText(ScriptGlobal_Format("#{ZMTFBC_230920_64}",tostring(nDiziLevel)))

	ZongMenSkill_Share_MenPaiText:SetText(ScriptGlobal_Format("#{ZMTFBC_230920_40}",ZongMenSkill_Share_GetMenpaiName(nShareMenpai)))

	ZongMenSkill_Share_TalentPoint1:SetText(ScriptGlobal_Format("#{ZMTFBC_230920_42}",tostring(DataPool:GetShareSectRequiredNormalPoint())))
	ZongMenSkill_Share_TalentPoint2:SetText(ScriptGlobal_Format("#{ZMTFBC_230920_45}",tostring(DataPool:GetShareSectRequiredCorePoint())))


end

function ZongMenSkill_Share_On_ResetPos()
	ZongMenSkill_Share_Frame:SetProperty("UnifiedPosition", g_ZongMenSkill_Share_Frame_UnifiedPosition)

end

function ZongMenSkill_Share_OnHidden()
	g_ZongMenSkill_Share_SelectedId = -1
	ZongMenSkill_Share_ComboList:ResetList()

end

function ZongMenSkill_Share_OnClose()
	this:Hide()
end

function ZongMenSkill_Share_TalentTreeClicked(index)
end
function ZongMenSkill_Share_CoreTalentTreeClicked(index)
end
function ZongMenSkill_Share_GetMenpaiName(menpai)
	local strMenPai = ""
	if(0 == menpai) then
		strMenPai = "少林";
	elseif(1 == menpai) then
		strMenPai = "明教";
	elseif(2 == menpai) then
		strMenPai = "丐帮";
	elseif(3 == menpai) then
		strMenPai = "武当";
	elseif(4 == menpai) then
		strMenPai = "峨嵋";
	elseif(5 == menpai) then
		strMenPai = "星宿";
	elseif(6 == menpai) then
		strMenPai = "天龙";
	elseif(7 == menpai) then
		strMenPai = "天山";
	elseif(8 == menpai) then
		strMenPai = "逍遥";
	elseif(10 == menpai) then
		strMenPai = "慕容";
	elseif(11 == menpai) then
		strMenPai = "唐门";
	elseif(12 == menpai) then
		strMenPai = "鬼谷";
	elseif(13 == menpai) then
		strMenPai = "#{XQ_MP_15}"; --桃花岛
	elseif(14 == menpai) then
		strMenPai = "#{XMPHM_210604_01}"; 
	elseif(15 == menpai) then--menpai15 mptodo
		strMenPai = "#{GMGameInterface_Script_DataPool_Info_ERenGu}"; 
	else
		strMenPai = "无门派";
	end
	return strMenPai
end


function ZongMenSkill_Share_OnLoad()	
	g_ZongMenSkill_Share_Frame_UnifiedPosition = ZongMenSkill_Share_Frame:GetProperty("UnifiedPosition")

	g_ZongMenSkill_Share_CoreSkillUI = 
	{
		[1] = {
			ActionItem = ZongMenSkill_Share_TalentIcon11,
			NameLabel = ZongMenSkill_Share_TalentName11,
			TalentLabel = ZongMenSkill_Share_TalentNum11,
			LockMask = ZongMenSkill_Share_TalentLock11,
			IconLockMask = ZongMenSkill_Share_TalentIconLock11,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame11,
		},
		[2] = {
			ActionItem = ZongMenSkill_Share_TalentIcon12,
			NameLabel = ZongMenSkill_Share_TalentName12,
			TalentLabel = ZongMenSkill_Share_TalentNum12,
			LockMask = ZongMenSkill_Share_TalentLock12,
			IconLockMask = ZongMenSkill_Share_TalentIconLock12,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame12,
		},
		[3] = {
			ActionItem = ZongMenSkill_Share_TalentIcon13,
			NameLabel = ZongMenSkill_Share_TalentName13,
			TalentLabel = ZongMenSkill_Share_TalentNum13,
			LockMask = ZongMenSkill_Share_TalentLock13,
			IconLockMask = ZongMenSkill_Share_TalentIconLock13,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame13,
		},
		[4] = {
			ActionItem = ZongMenSkill_Share_TalentIcon14,
			NameLabel = ZongMenSkill_Share_TalentName14,
			TalentLabel = ZongMenSkill_Share_TalentNum14,
			LockMask = ZongMenSkill_Share_TalentLock14,
			IconLockMask = ZongMenSkill_Share_TalentIconLock14,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame14,
		},
		[5] = {
			ActionItem = ZongMenSkill_Share_TalentIcon16,
			NameLabel = ZongMenSkill_Share_TalentName16,
			TalentLabel = ZongMenSkill_Share_TalentNum16,
			LockMask = ZongMenSkill_Share_TalentLock16,
			IconLockMask = ZongMenSkill_Share_TalentIconLock16,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame16,
		},
	}

	g_ZongMenSkill_Share_NormalSkillUI=
	{
		[1] = {
			ActionItem = ZongMenSkill_Share_TalentIcon1,
			NameLabel = ZongMenSkill_Share_TalentName1,
			TalentLabel = ZongMenSkill_Share_TalentNum1,
			LockMask = ZongMenSkill_Share_TalentLock1,
			IconLockMask = ZongMenSkill_Share_TalentIconLock1,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame1,
		},
		[2] = {
			ActionItem = ZongMenSkill_Share_TalentIcon2,
			NameLabel = ZongMenSkill_Share_TalentName2,
			TalentLabel = ZongMenSkill_Share_TalentNum2,
			LockMask = ZongMenSkill_Share_TalentLock2,
			IconLockMask = ZongMenSkill_Share_TalentIconLock2,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame2,
		},
		[3] = {
			ActionItem = ZongMenSkill_Share_TalentIcon3,
			NameLabel = ZongMenSkill_Share_TalentName3,
			TalentLabel = ZongMenSkill_Share_TalentNum3,
			LockMask = ZongMenSkill_Share_TalentLock3,
			IconLockMask = ZongMenSkill_Share_TalentIconLock3,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame3,
		},
		[4] = {
			ActionItem = ZongMenSkill_Share_TalentIcon4,
			NameLabel = ZongMenSkill_Share_TalentName4,
			TalentLabel = ZongMenSkill_Share_TalentNum4,
			LockMask = ZongMenSkill_Share_TalentLock4,
			IconLockMask = ZongMenSkill_Share_TalentIconLock4,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame4,
		},
		[5] = {
			ActionItem = ZongMenSkill_Share_TalentIcon5,
			NameLabel = ZongMenSkill_Share_TalentName5,
			TalentLabel = ZongMenSkill_Share_TalentNum5,
			LockMask = ZongMenSkill_Share_TalentLock5,
			IconLockMask = ZongMenSkill_Share_TalentIconLock5,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame5,
		},
		[6] = {
			ActionItem = ZongMenSkill_Share_TalentIcon6,
			NameLabel = ZongMenSkill_Share_TalentName6,
			TalentLabel = ZongMenSkill_Share_TalentNum6,
			LockMask = ZongMenSkill_Share_TalentLock6,
			IconLockMask = ZongMenSkill_Share_TalentIconLock6,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame6,
		},
		[7] = {
			ActionItem = ZongMenSkill_Share_TalentIcon7,
			NameLabel = ZongMenSkill_Share_TalentName7,
			TalentLabel = ZongMenSkill_Share_TalentNum7,
			LockMask = ZongMenSkill_Share_TalentLock7,
			IconLockMask = ZongMenSkill_Share_TalentIconLock7,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame7,
		},
		[8] = {
			ActionItem = ZongMenSkill_Share_TalentIcon8,
			NameLabel = ZongMenSkill_Share_TalentName8,
			TalentLabel = ZongMenSkill_Share_TalentNum8,
			LockMask = ZongMenSkill_Share_TalentLock8,
			IconLockMask = ZongMenSkill_Share_TalentIconLock8,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame8,
		},
		[9] = {
			ActionItem = ZongMenSkill_Share_TalentIcon9,
			NameLabel = ZongMenSkill_Share_TalentName9,
			TalentLabel = ZongMenSkill_Share_TalentNum9,
			LockMask = ZongMenSkill_Share_TalentLock9,
			IconLockMask = ZongMenSkill_Share_TalentIconLock9,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame9,
		},
		[10] = {
			ActionItem = ZongMenSkill_Share_TalentIcon10,
			NameLabel = ZongMenSkill_Share_TalentName10,
			TalentLabel = ZongMenSkill_Share_TalentNum10,
			LockMask = ZongMenSkill_Share_TalentLock10,
			IconLockMask = ZongMenSkill_Share_TalentIconLock10,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame10,
		},
		[11] = {
			ActionItem = ZongMenSkill_Share_TalentIcon15,
			NameLabel = ZongMenSkill_Share_TalentName15,
			TalentLabel = ZongMenSkill_Share_TalentNum15,
			LockMask = ZongMenSkill_Share_TalentLock15,
			IconLockMask = ZongMenSkill_Share_TalentIconLock15,
			TalentTypeIcon = ZongMenSkill_Share_TalentFrame15,
		},
	}

end	