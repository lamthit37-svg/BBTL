
local m_Text_EnchanceSetAttr_Attack_Level
local m_Text_EnchanceSetAttr_Defence_Level 


local m_Text_EnchanceSetAttr_Attack_Name = {}
local m_Text_EnchanceSetAttr_Attack_Value = {}
local m_Text_EnchanceSetAttr_Attack_NextValue = {}

local m_Text_EnchanceSetAttr_Defence_Name = {}
local m_Text_EnchanceSetAttr_Defence_Value = {}
local m_Text_EnchanceSetAttr_Defence_NextValue = {}

local m_Text_EnchanceSetAttr_Attack_Label
local m_Text_EnchanceSetAttr_Defence_Label

local m_Text_EnchanceSetAttr_Attack_NextTip
local m_Text_EnchanceSetAttr_Defence_NextTip

local m_AttackAttrName = { "#{QHTZ_140808_10}" , "#{QHTZ_140808_11}" ,"#{QHTZ_140808_12}" ,"#{QHTZ_140808_13}" }
local m_AttackAttrName_Null = { "#{QHTZ_140808_14}" , "#{QHTZ_140808_15}" ,"#{QHTZ_140808_16}" ,"#{QHTZ_140808_17}" }
local m_AttackAttrNextValue_Null = { "#{QHTZ_140808_28}" , "#{QHTZ_140808_29}" ,"#{QHTZ_140808_30}" ,"#{QHTZ_140808_31}" }

local m_DefenceAttrName = { "#{QHTZ_140808_18}" , "#{QHTZ_140808_19}" ,"#{QHTZ_140808_20}" ,"#{QHTZ_140808_21}" }
local m_DefenceAttrName_Null = { "#{QHTZ_140808_22}" , "#{QHTZ_140808_23}" ,"#{QHTZ_140808_24}" ,"#{QHTZ_140808_25}" }
local m_DefenceAttrNextValue_Null = { "#{QHTZ_140808_32}" , "#{QHTZ_140808_33}" ,"#{QHTZ_140808_34}" ,"#{QHTZ_140808_35}" }

local m_StrTail = {"" , "" , "" ,"%"}

local m_Level =  { 30 , 40 , 50 , 60}

function EquipEffectSelfTips_PreLoad()

	this:RegisterEvent("OPEN_ENCHANCESET")
	this:RegisterEvent("CLOSE_ENCHANCESET")
	
end

function EquipEffectSelfTips_OnLoad()

	m_Text_EnchanceSetAttr_Attack_Level  =  EquipEffectSelfTips_UpTXT1_1
	m_Text_EnchanceSetAttr_Defence_Level  =  EquipEffectSelfTips_DownTXT1_1
	
	m_Text_EnchanceSetAttr_Attack_Name[1] = EquipEffectSelfTips_UpTXT2
	m_Text_EnchanceSetAttr_Attack_Name[2] = EquipEffectSelfTips_UpTXT3
	m_Text_EnchanceSetAttr_Attack_Name[3] = EquipEffectSelfTips_UpTXT4
	m_Text_EnchanceSetAttr_Attack_Name[4] = EquipEffectSelfTips_UpTXT5
	
	m_Text_EnchanceSetAttr_Attack_Value[1]	= EquipEffectSelfTips_UpTXT6
	m_Text_EnchanceSetAttr_Attack_Value[2]	= EquipEffectSelfTips_UpTXT7
	m_Text_EnchanceSetAttr_Attack_Value[3]	= EquipEffectSelfTips_UpTXT8
	m_Text_EnchanceSetAttr_Attack_Value[4]	= EquipEffectSelfTips_UpTXT9
	
	m_Text_EnchanceSetAttr_Attack_NextValue[1]	= EquipEffectSelfTips_UpTXT10
	m_Text_EnchanceSetAttr_Attack_NextValue[2]	= EquipEffectSelfTips_UpTXT11
	m_Text_EnchanceSetAttr_Attack_NextValue[3]	= EquipEffectSelfTips_UpTXT12
	m_Text_EnchanceSetAttr_Attack_NextValue[4]	= EquipEffectSelfTips_UpTXT13
	
	
	m_Text_EnchanceSetAttr_Defence_Name[1] = EquipEffectSelfTips_DownTXT2
	m_Text_EnchanceSetAttr_Defence_Name[2] = EquipEffectSelfTips_DownTXT3
	m_Text_EnchanceSetAttr_Defence_Name[3] = EquipEffectSelfTips_DownTXT4
	m_Text_EnchanceSetAttr_Defence_Name[4] = EquipEffectSelfTips_DownTXT5
	
	m_Text_EnchanceSetAttr_Defence_Value[1]	= EquipEffectSelfTips_DownTXT6
	m_Text_EnchanceSetAttr_Defence_Value[2]	= EquipEffectSelfTips_DownTXT7
	m_Text_EnchanceSetAttr_Defence_Value[3]	= EquipEffectSelfTips_DownTXT8
	m_Text_EnchanceSetAttr_Defence_Value[4]	= EquipEffectSelfTips_DownTXT9
	
	m_Text_EnchanceSetAttr_Defence_NextValue[1]	= EquipEffectSelfTips_DownTXT10
	m_Text_EnchanceSetAttr_Defence_NextValue[2]	= EquipEffectSelfTips_DownTXT11
	m_Text_EnchanceSetAttr_Defence_NextValue[3]	= EquipEffectSelfTips_DownTXT12
	m_Text_EnchanceSetAttr_Defence_NextValue[4]	= EquipEffectSelfTips_DownTXT13
	
	m_Text_EnchanceSetAttr_Attack_Label = EquipEffectSelfTips_UpTXT1_2
	m_Text_EnchanceSetAttr_Defence_Label = EquipEffectSelfTips_DownTXT1_2
	
	m_Text_EnchanceSetAttr_Attack_NextTip = EquipEffectSelfTips_TXT_Up
	m_Text_EnchanceSetAttr_Defence_NextTip = EquipEffectSelfTips_TXT_Down
	
	
end

function EquipEffectSelfTips_OnEvent(event)

	local SetX = tonumber(arg0)
	local SetY = tonumber(arg1)
	local SetWidth = tonumber(arg2)
	local SetHeight = tonumber(arg3)
	
	if( event == "OPEN_ENCHANCESET" ) then
		
		EquipEffectSelfTips_Update()
		EquipEffectSelfTips_AdjustPosition(SetX,SetY,SetWidth,SetHeight)
		this:Show()
		
	end
	if( event == "CLOSE_ENCHANCESET" ) then

		this:Hide()
		
	end
end

function EquipEffectSelfTips_Reset()
	
	m_Text_EnchanceSetAttr_Attack_Level:SetText("")
	m_Text_EnchanceSetAttr_Defence_Level:SetText("")
	
	for i = 1 , 4 do

		m_Text_EnchanceSetAttr_Attack_Name[ i ]:SetText("")
		m_Text_EnchanceSetAttr_Attack_Value[ i ]:SetText("")
		m_Text_EnchanceSetAttr_Attack_NextValue[ i ]:SetText("")
		m_Text_EnchanceSetAttr_Defence_Name[ i ]:SetText("")
		m_Text_EnchanceSetAttr_Defence_Value[ i ]:SetText("")
		m_Text_EnchanceSetAttr_Defence_NextValue[ i ]:SetText("")
		
	end
	
	m_Text_EnchanceSetAttr_Attack_Label:SetText("")
	m_Text_EnchanceSetAttr_Defence_Label:SetText("")
	
	m_Text_EnchanceSetAttr_Attack_NextTip:SetText("")
	m_Text_EnchanceSetAttr_Defence_NextTip:SetText("")

end

function EquipEffectSelfTips_Update()
	
	EquipEffectSelfTips_Reset()
	
	local nMinAttackLevel = DataPool:Lua_GetEnchanceMinLevel(0)
	local nMinAttackNextLevel = DataPool:Lua_GetEnchanceSetNextLevel(0 ,nMinAttackLevel)
	
	local nMinDefenceLevel = DataPool:Lua_GetEnchanceMinLevel(1)
	local nMinDefenceNextLevel = DataPool:Lua_GetEnchanceSetNextLevel(1 , nMinDefenceLevel)

	--天锐
	if nMinAttackNextLevel ~= nil and nMinAttackNextLevel > 0 then
		
		m_Text_EnchanceSetAttr_Attack_Label:SetText("#{QHTZ_140808_03}")
		for i = 1 , 4 do
		
			local nValue = DataPool:Lua_GetEnchanceSetInfo( 0 , i - 1, nMinAttackNextLevel )
			if nValue ~= nil and nValue > 0 then
				m_Text_EnchanceSetAttr_Attack_NextValue[ i ]:SetText("#c8c8c8c+"..tostring(nValue)..m_StrTail[i])
			else
				m_Text_EnchanceSetAttr_Attack_NextValue[ i ]:SetText(m_AttackAttrNextValue_Null[i])
			end
			
		end
		
		if Player:GetData("Is2606S") == 1 then
			m_Text_EnchanceSetAttr_Attack_NextTip:SetText("#{QXF_260623_117}")
		else
		m_Text_EnchanceSetAttr_Attack_NextTip:SetText("#{QHTZ_140808_05}")
		end
	else
		m_Text_EnchanceSetAttr_Attack_Label:SetText("#{QHTZ_140808_04}")
		if Player:GetData("Is2606S") == 1 then
			m_Text_EnchanceSetAttr_Attack_NextTip:SetText("#{QXF_260623_117}")
		else
		m_Text_EnchanceSetAttr_Attack_NextTip:SetText("#{QHTZ_140808_06}")
		end
	end
	
	for i = 1 , 4 do
		
		local nValue= DataPool:Lua_GetEnchanceSetInfo( 0 , i - 1, nMinAttackLevel )

		if nValue ~= nil and nValue > 0 then
			m_Text_EnchanceSetAttr_Attack_Name[ i ]:SetText(m_AttackAttrName[i])
			m_Text_EnchanceSetAttr_Attack_Value[ i ]:SetText("#G+"..tostring(nValue)..m_StrTail[i])
		else
			m_Text_EnchanceSetAttr_Attack_Name[ i ]:SetText(m_AttackAttrName_Null[i])
			m_Text_EnchanceSetAttr_Attack_Value[ i ]:SetText("#{QHTZ_140808_27}")		
		end
	end
	
	local nAttackLevel = 0
	if nMinAttackLevel >= m_Level[4] then
		nAttackLevel = 4
	elseif nMinAttackLevel >= m_Level[3] then 
		nAttackLevel = 3
	elseif nMinAttackLevel >= m_Level[2] then 
		nAttackLevel = 2
	elseif nMinAttackLevel >= m_Level[1] then 
		nAttackLevel = 1
	end
	local strTextAttackLevel = ScriptGlobal_Format("#{QHTZ_140808_02}" ,tostring(nAttackLevel))
	m_Text_EnchanceSetAttr_Attack_Level:SetText(strTextAttackLevel)
	
	--地磐
	
	if nMinDefenceNextLevel ~= nil and nMinDefenceNextLevel > 0 then
		
		m_Text_EnchanceSetAttr_Defence_Label:SetText("#{QHTZ_140808_03}")
		for i = 1 , 4 do
		
			local nValue = DataPool:Lua_GetEnchanceSetInfo( 1 , i - 1, nMinDefenceNextLevel )
			if nValue ~= nil and nValue > 0 then
				m_Text_EnchanceSetAttr_Defence_NextValue[ i ]:SetText("#c8c8c8c+"..tostring(nValue)..m_StrTail[i])
			else
				m_Text_EnchanceSetAttr_Defence_NextValue[ i ]:SetText(m_DefenceAttrNextValue_Null[i])
			end
		end

		m_Text_EnchanceSetAttr_Defence_NextTip:SetText("#{QHTZ_140808_08}")
		
	else
		m_Text_EnchanceSetAttr_Defence_Label:SetText("#{QHTZ_140808_04}")
		m_Text_EnchanceSetAttr_Defence_NextTip:SetText("#{QHTZ_140808_09}")
	end
	
	for i = 1 , 4 do
		
		local nValue = DataPool:Lua_GetEnchanceSetInfo( 1 , i - 1, nMinDefenceLevel )
		if nValue ~=nil and nValue > 0 then
			m_Text_EnchanceSetAttr_Defence_Name[ i ]:SetText(m_DefenceAttrName[i])
			m_Text_EnchanceSetAttr_Defence_Value[ i ]:SetText("#G+"..tostring(nValue)..m_StrTail[i])
		else
			m_Text_EnchanceSetAttr_Defence_Name[ i ]:SetText(m_DefenceAttrName_Null[i])
			m_Text_EnchanceSetAttr_Defence_Value[ i ]:SetText("#{QHTZ_140808_27}")		
		end
	
	end
	
	local nDefenceLevel = 0
	if nMinDefenceLevel >= m_Level[4] then
		nDefenceLevel = 4
	elseif nMinDefenceLevel >= m_Level[3] then 
		nDefenceLevel = 3
	elseif nMinDefenceLevel >= m_Level[2] then 
		nDefenceLevel = 2
	elseif nMinDefenceLevel >= m_Level[1] then 
		nDefenceLevel = 1
	end
	local strTextDefence = ScriptGlobal_Format("#{QHTZ_140808_07}" ,tostring(nDefenceLevel))
	m_Text_EnchanceSetAttr_Defence_Level:SetText(strTextDefence)

end
--自动设置Tips位置
function EquipEffectSelfTips_AdjustPosition(SetX,SetY,SetWidth,SetHeight)
	
	local TipsWidth = EquipEffectSelfTips_Frame:GetProperty("AbsoluteWidth")
	local TipsHeight = EquipEffectSelfTips_Frame:GetProperty("AbsoluteHeight")
	local ScreenWidth ,ScreenHeight = GetCurClientSize()
	
	if(SetX + SetWidth + TipsWidth > ScreenWidth) then
		EquipEffectSelfTips_Frame:SetProperty("AbsoluteXPosition",SetX - TipsWidth)
	else
		EquipEffectSelfTips_Frame:SetProperty("AbsoluteXPosition",SetX + SetWidth)
	end
	
	if(SetY + SetHeight + TipsHeight > ScreenHeight) then
		EquipEffectSelfTips_Frame:SetProperty("AbsoluteYPosition",SetY - TipsHeight)
	else
		EquipEffectSelfTips_Frame:SetProperty("AbsoluteYPosition",SetY + SetHeight)
	end
	
end