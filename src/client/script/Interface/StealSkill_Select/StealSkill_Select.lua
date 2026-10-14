local g_StealSkill_Select_Frame_UnifiedPosition
local g_haveSkills = {}
local g_haveSkllNames = {}
local g_canSelectSkills = {}
local g_canSelectSkillNames = {}
local g_canSelectSkillIcon = {}
local g_canSelectSkillMasks = {}
local g_canSelectSkillLearnMasks = {}
local g_canSelectSkillSelectMaskS = {}
local g_canSelectSkillNum = 10
local g_haveSkillNum =3

local g_selectIndex = {-1, -1, -1}

--=========================================================
-- PreLoad
--=========================================================
function StealSkill_Select_PreLoad()
	  this:RegisterEvent("OPEN_STEAL_SKILL")
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) -- 离开场景
end

--=========================================================
-- OnLoad
--=========================================================
function StealSkill_Select_OnLoad()
    g_StealSkill_Select_Frame_UnifiedPosition = StealSkill_Select_Frame:GetProperty("UnifiedPosition")
    
    g_haveSkills[1] = StealSkill_Select_Selected_1
    g_haveSkills[2] = StealSkill_Select_Selected_2
    g_haveSkills[3] = StealSkill_Select_Selected_3
    
    g_haveSkllNames[1] = StealSkill_Select_Selected_1_info
    g_haveSkllNames[2] = StealSkill_Select_Selected_2_info
    g_haveSkllNames[3] = StealSkill_Select_Selected_3_info
    
    for i=1, g_canSelectSkillNum do 
    	g_canSelectSkills[i] = _G["StealSkill_Select_Skill"..i]
    	g_canSelectSkillMasks[i] = _G["StealSkill_Select_Skill"..i.."_Mask"]
    	g_canSelectSkillIcon[i] = _G["StealSkill_Select_Skill"..i.."_SpecialIcon"]
    	g_canSelectSkillNames[i] = _G["StealSkill_Select_Skill"..i.."_info"]
    	g_canSelectSkillLearnMasks[i] = _G["StealSkill_Select_Skill"..i.."_LearnedMask"]
    	g_canSelectSkillSelectMaskS[i] = _G["StealSkill_Select_Skill"..i.."_SelectedMask"]
  	end	
  
end

--=========================================================
-- OnEvent
--=========================================================
function StealSkill_Select_OnEvent(event)
		if event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
        StealSkill_Select_OnResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        StealSkill_Select_Hide()
    elseif event == "OPEN_STEAL_SKILL" then 
    		if tonumber(arg0) ~= -1 then
    			local objCared = Target:GetServerId2ClientId( tonumber(arg0))
    			this:CareObject(objCared, 1, "StealSkill_Select")
    		end
    		
     		StealSkill_Select_UpdateText()
     		StealSkill_Select_UpdateCanSelectSkills()
     		StealSkill_Select_UpdateHaveSkills()
     		this:Show()       
    end
end

function StealSkill_Select_UpdateText()
		local strText = ScriptGlobal_Format( "#{TXJN_250903_19}", GetNeedStealNum() )
		StealSkill_Select_WeekLearnNum:SetText( strText )
		
		strText = ScriptGlobal_Format( "#{TXJN_250903_17}", GetLastRestStealNum() )
		StealSkill_Select_ReLearnBtn:SetToolTip(strText)
end

function StealSkill_Select_UpdateCanSelectSkills()
	g_selectIndex = {-1, -1, -1}
	
	for i=1, g_canSelectSkillNum do
		g_canSelectSkills[i]:SetActionItem(-1)
		g_canSelectSkillNames[i]:SetText( "" )
		g_canSelectSkillIcon[i]:Hide()
		g_canSelectSkillMasks[i]:Hide()
		g_canSelectSkillLearnMasks[i]:Hide()
		g_canSelectSkillSelectMaskS[i]:Hide()
	end
	
	local canSelectSkillNum = GetCanSSIdListNum()
	local strName
	for i=1, canSelectSkillNum do 
		local actionId, isSameMenPai, skillName, isSpecial = GetCanSSIdInfo(i-1) 
		g_canSelectSkills[i]:SetActionItem(actionId)
		if isSpecial > 0 then
			g_canSelectSkillIcon[i]:Show()
		end
		
		if isSameMenPai > 0 then
			g_canSelectSkillMasks[i]:Show()
		end	
		
		if actionId ~= -1 then
			strName = ScriptGlobal_Format( "#{TXJN_250903_21}", skillName )
			g_canSelectSkillNames[i]:SetText( strName )
		end
	end
end	

function StealSkill_Select_UpdateHaveSkills()
	for i=1, g_haveSkillNum do
		g_haveSkills[i]:SetActionItem(-1)
		g_haveSkllNames[i]:SetText( "" )
	end
	
	local haveSkillNum = GetHaveSSIdListNum()
	local strName
	local index
	
	for i=1, haveSkillNum do 
		local actionId, skillName = GetHaveSSIdInfo(i-1) 
		g_haveSkills[i]:SetActionItem(actionId)
		
		if actionId ~= -1 then
			strName = ScriptGlobal_Format( "#{TXJN_250903_21}", skillName )
			g_haveSkllNames[i]:SetText( strName )
		end
		
		index = GetCanSSIdListIndexByHaveSSId(i-1)
		if index >= 0 and  index < g_canSelectSkillNum then
			g_canSelectSkillLearnMasks[index+1]:Show()
		end
	end
end	

function StealSkill_Select_Skill_Clicked(index)
	--已选过，未重置前， 不让选
	if GetHaveSSIdListNum() > 0 then
		return
	end
	
	if GetCanSSId(index - 1) == -1 then
		return
	end
	
	if index >= 1 and  index <= g_canSelectSkillNum then
		--蒙红的不让选
		if(g_canSelectSkillMasks[index]:IsVisible()) then
			return
		end
		
		local isSelect = 0
		for i = 1, g_haveSkillNum do
			if g_selectIndex[i] == index then
				isSelect = i
				break
			end
		end
		
		if isSelect ~= 0 then
			g_selectIndex[isSelect] = -1
			g_canSelectSkillSelectMaskS[index]:Hide()
			
			for i = 1, g_canSelectSkillNum do
				if i ~= index then
					if g_canSelectSkillMasks[i]:IsVisible() and IsSameMenPaiSSId(i-1) == 0 and IsSameGroupSSId(i-1, index-1) == 1 then 
						g_canSelectSkillMasks[i]:Hide()
					end
				end	
			end	
		else
			for i = 1, g_haveSkillNum do
				if g_selectIndex[i] == -1 then
					isSelect = i
					break
				end
			end
			
			--已选满
			if isSelect == 0 or isSelect > GetNeedStealNum()  then
				return
			end
			
			g_selectIndex[isSelect] = index
			g_canSelectSkillSelectMaskS[index]:Show()	
			for i = 1, g_canSelectSkillNum do
				if i ~= index then
					if not g_canSelectSkillMasks[i]:IsVisible() and IsSameGroupSSId(i-1, index-1) == 1 then 
						g_canSelectSkillMasks[i]:Show()
					end
				end
			end
			
		end	
	end	
end	

function StealSkill_Select_ReLearnBtn_OnClicked()
	if Player:InTeamFollowMode()  then
		PushDebugMessage("#{TXJN_250903_22}")
		return
	end
	
	if Player:IsOnHorse() == 2 or Player:IsOnHorse() == 3 then
		PushDebugMessage("#{TXJN_250903_23}")
		return
	end
	
	if( tonumber( IsInStall() ) == 1 ) then
		PushDebugMessage("#{TXJN_250903_24}")			--摆摊状态无法进行这种操作。
		return
	end
	
	if Player : GetPlayerChangeModel() > 0 then
		PushDebugMessage("#{TXJN_250903_25}")
		return
	end
	
	if DataPool:Lua_IsHaveMission(4021) > 0 then
		PushDebugMessage("#{TXJN_250903_26}")
		return
	end
	
	if GetHaveSSIdListNum() == 0 then
		PushDebugMessage("#{TXJN_250903_39}")
		return
	end
	
	if GetLastRestStealNum() == 0 then
		PushDebugMessage("#{TXJN_250903_40}")
		return
	end
	
	PushEvent("OPEN_PS_MESSAGE_FRAME", "rest_stealSkill")
end

function StealSkill_Select_LearnBtn_OnClicked()
	if Player:InTeamFollowMode()  then
		PushDebugMessage("#{TXJN_250903_22}")
		return
	end
	
	if Player:IsOnHorse() == 2 or Player:IsOnHorse() == 3 then
		PushDebugMessage("#{TXJN_250903_23}")
		return
	end
	
	if( tonumber( IsInStall() ) == 1 ) then
		PushDebugMessage("#{TXJN_250903_24}")			--摆摊状态无法进行这种操作。
		return
	end
	
	if Player : GetPlayerChangeModel() > 0 then
		PushDebugMessage("#{TXJN_250903_25}")
		return
	end
	
	if DataPool:Lua_IsHaveMission(4021) > 0 then
		PushDebugMessage("#{TXJN_250903_26}")
		return
	end
	
	if GetHaveSSIdListNum() > 0 then
		PushDebugMessage("#{TXJN_250903_30}")
		return
	end
	
	local selectNum = 0
	
	for i = 1, g_haveSkillNum do
		if g_selectIndex[i] ~= -1 then
			selectNum = selectNum + 1
		end
	end
	
	if selectNum == 0 then
		PushDebugMessage("#{TXJN_250903_27}")
		return
	end
	
	if selectNum ~= GetNeedStealNum() then
		local strText = ScriptGlobal_Format( "#{TXJN_250903_31}", GetNeedStealNum() )
		PushDebugMessage(strText)
		return
	end
	
	local skillId = {}
	for i = 1, g_haveSkillNum do
		if g_selectIndex[i] == -1 then
			skillId[i] = -1
		else
			skillId[i] = GetCanSSId(g_selectIndex[i] - 1)
		end
	end
	
	PushEvent("OPEN_PS_MESSAGE_FRAME", "stealSkill", skillId[1], skillId[2], skillId[3], selectNum)
end

function StealSkill_Select_HelpBtn_Clicked()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnClickGuideInterfaceHelp")
			Set_XSCRIPT_ScriptID(999755)
			Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end

--=========================================================
-- 界面隐藏
--=========================================================
function StealSkill_Select_Hide()
    this:Hide()
end

--=========================================================
-- 界面重置
--=========================================================
function StealSkill_Select_OnResetPos()
    StealSkill_Select_Frame:SetProperty("UnifiedPosition", g_StealSkill_Select_Frame_UnifiedPosition)
end
