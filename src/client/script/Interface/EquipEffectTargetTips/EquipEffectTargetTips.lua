
local m_Text_EnchanceSetAttr_Attack_Level
local m_Text_EnchanceSetAttr_Defence_Level 

local m_Text_EnchanceSetAttr_Attack_Name = {}
local m_Text_EnchanceSetAttr_Attack_Value = {}

local m_Text_EnchanceSetAttr_Defence_Name = {}
local m_Text_EnchanceSetAttr_Defence_Value = {}

local m_AttackAttrName = { "#{QHTZ_140808_10}" , "#{QHTZ_140808_11}" ,"#{QHTZ_140808_12}" ,"#{QHTZ_140808_13}" }
local m_AttackAttrName_Null = { "#{QHTZ_140808_14}" , "#{QHTZ_140808_15}" ,"#{QHTZ_140808_16}" ,"#{QHTZ_140808_17}" }

local m_DefenceAttrName = { "#{QHTZ_140808_18}" , "#{QHTZ_140808_19}" ,"#{QHTZ_140808_20}" ,"#{QHTZ_140808_21}" }
local m_DefenceAttrName_Null = { "#{QHTZ_140808_22}" , "#{QHTZ_140808_23}" ,"#{QHTZ_140808_24}" ,"#{QHTZ_140808_25}" }

local m_StrTail = {"" , "" , "" ,"%"}

local m_Level =  { 30 , 40 , 50 , 60}


function EquipEffectTargetTips_PreLoad()

	this:RegisterEvent("OPEN_OTHER_ENCHANCESET")
	this:RegisterEvent("CLOSE_OTHER_ENCHANCESET")
	
end

function EquipEffectTargetTips_OnLoad()

	m_Text_EnchanceSetAttr_Attack_Level  =  EquipEffectTargetTips_UpTXT1_1
	m_Text_EnchanceSetAttr_Defence_Level  =  EquipEffectTargetTips_DownTXT1_1

	m_Text_EnchanceSetAttr_Attack_Name[1] = EquipEffectTargetTips_UpTXT2
	m_Text_EnchanceSetAttr_Attack_Name[2] = EquipEffectTargetTips_UpTXT3
	m_Text_EnchanceSetAttr_Attack_Name[3] = EquipEffectTargetTips_UpTXT4
	m_Text_EnchanceSetAttr_Attack_Name[4] = EquipEffectTargetTips_UpTXT5
	
	m_Text_EnchanceSetAttr_Attack_Value[1] = EquipEffectTargetTips_UpTXT6
	m_Text_EnchanceSetAttr_Attack_Value[2] = EquipEffectTargetTips_UpTXT7
	m_Text_EnchanceSetAttr_Attack_Value[3] = EquipEffectTargetTips_UpTXT8
	m_Text_EnchanceSetAttr_Attack_Value[4] = EquipEffectTargetTips_UpTXT9
	
	m_Text_EnchanceSetAttr_Defence_Name[1] = EquipEffectTargetTips_DownTXT2
	m_Text_EnchanceSetAttr_Defence_Name[2] = EquipEffectTargetTips_DownTXT3
	m_Text_EnchanceSetAttr_Defence_Name[3] = EquipEffectTargetTips_DownTXT4
	m_Text_EnchanceSetAttr_Defence_Name[4] = EquipEffectTargetTips_DownTXT5
	
	m_Text_EnchanceSetAttr_Defence_Value[1] = EquipEffectTargetTips_DownTXT6
	m_Text_EnchanceSetAttr_Defence_Value[2] = EquipEffectTargetTips_DownTXT7
	m_Text_EnchanceSetAttr_Defence_Value[3] = EquipEffectTargetTips_DownTXT8
	m_Text_EnchanceSetAttr_Defence_Value[4] = EquipEffectTargetTips_DownTXT9
	
end

function EquipEffectTargetTips_OnEvent(event)

	local SetX = tonumber(arg0)
	local SetY = tonumber(arg1)
	local SetWidth = tonumber(arg2)
	local SetHeight = tonumber(arg3)
	
	if( event == "OPEN_OTHER_ENCHANCESET" ) then
		
		EquipEffectTargetTips_Update()
		EquipEffectTargetTips_AdjustPosition(SetX,SetY,SetWidth,SetHeight)
		this:Show()
		
	end
	
	if( event == "CLOSE_OTHER_ENCHANCESET" ) then

		this:Hide()
		
	end
end

function EquipEffectTargetTips_Reset()

	m_Text_EnchanceSetAttr_Attack_Level:SetText("")
	m_Text_EnchanceSetAttr_Defence_Level:SetText("")
	
	for i = 1 , 4 do

		m_Text_EnchanceSetAttr_Attack_Name[ i ]:SetText("")
		m_Text_EnchanceSetAttr_Attack_Value[ i ]:SetText("")
		m_Text_EnchanceSetAttr_Defence_Name[ i ]:SetText("")
		m_Text_EnchanceSetAttr_Defence_Value[ i ]:SetText("")
		
	end

end

function EquipEffectTargetTips_Update()
	
	EquipEffectTargetTips_Reset()
	
	local nMinAttackLevel = CachedTarget:Lua_GetTargetEnchanceMinLevel(0)
	local nMinDefenceLevel = CachedTarget:Lua_GetTargetEnchanceMinLevel(1)

	for i = 1 , 4 do
		
		local nValue = DataPool:Lua_GetEnchanceSetInfo( 0 , i - 1, nMinAttackLevel )
		if nValue ~= nil and nValue > 0 then
			m_Text_EnchanceSetAttr_Attack_Name[ i ]:SetText(m_AttackAttrName[i])
			m_Text_EnchanceSetAttr_Attack_Value[ i ]:SetText("#G+"..tostring(nValue)..m_StrTail[i])
		else
			m_Text_EnchanceSetAttr_Attack_Name[ i ]:SetText(m_AttackAttrName_Null[i])
			m_Text_EnchanceSetAttr_Attack_Value[ i ]:SetText("#c8c8c8c+"..tostring(nValue)..m_StrTail[i])		
		end
	end
	
	for i = 1 , 4 do
		
		local nValue = DataPool:Lua_GetEnchanceSetInfo( 1 , i - 1, nMinDefenceLevel )
		if nValue ~=nil and nValue > 0 then
			m_Text_EnchanceSetAttr_Defence_Name[ i ]:SetText(m_DefenceAttrName[i])
			m_Text_EnchanceSetAttr_Defence_Value[ i ]:SetText("#G+"..tostring(nValue)..m_StrTail[i])
		else
			m_Text_EnchanceSetAttr_Defence_Name[ i ]:SetText(m_DefenceAttrName_Null[i])
			m_Text_EnchanceSetAttr_Defence_Value[ i ]:SetText("#c8c8c8c+"..tostring(nValue)..m_StrTail[i])		
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
function EquipEffectTargetTips_AdjustPosition(SetX,SetY,SetWidth,SetHeight)
	
	local TipsWidth = EquipEffectTargetTips_Frame:GetProperty("AbsoluteWidth")
	local TipsHeight = EquipEffectTargetTips_Frame:GetProperty("AbsoluteHeight")
	local ScreenWidth ,ScreenHeight = GetCurClientSize()
	
	if(SetX + SetWidth + TipsWidth > ScreenWidth) then
		EquipEffectTargetTips_Frame:SetProperty("AbsoluteXPosition",SetX - TipsWidth)
	else
		EquipEffectTargetTips_Frame:SetProperty("AbsoluteXPosition",SetX + SetWidth)
	end
	
	if(SetY + SetHeight + TipsHeight > ScreenHeight) then
		EquipEffectTargetTips_Frame:SetProperty("AbsoluteYPosition",SetY - TipsHeight)
	else
		EquipEffectTargetTips_Frame:SetProperty("AbsoluteYPosition",SetY + SetHeight)
	end
	
end
