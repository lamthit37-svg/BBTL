local m_Equip_Idx = -1

local g_ObjCared = -1
local g_UI_Command = 201405041
local g_NeedGcp_RlGradeUp = {200,300,400,500}	--令牌升阶需要的帮贡
local g_EquipLingPai_ShengJie_Frame_UnifiedPosition
local m_StaticText_NeedContri
local m_StaticText_HaveContri

function EquipLingPai_ShengJie_PreLoad()
		this:RegisterEvent("UI_COMMAND")
		this:RegisterEvent("RL_GRADEUP_PUTIN")
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
		this:RegisterEvent("ADJEST_UI_POS",false)
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false) 
		this:RegisterEvent("UPDATE_SELFGUILDCONTRI",false)
end

function EquipLingPai_ShengJie_OnLoad()
	g_EquipLingPai_ShengJie_Frame_UnifiedPosition = EquipLingPai_ShengJie_Frame:GetProperty( "UnifiedPosition" )
	
	m_StaticText_NeedContri = EquipLingPai_ShengJie_TextShuZhi
	m_StaticText_HaveContri = EquipLingPai_ShengJie_Text1ShuZhi
	
end

function EquipLingPai_ShengJie_OnEvent(event)
	    
	if ( event == "UI_COMMAND" ) and tonumber( arg0 ) == g_UI_Command then
		EquipLingPai_ShengJie_Reset()
		this:Show()
		g_ObjCared = -1
		local xx = Get_XParam_INT( 0 )
		g_ObjCared = DataPool : GetNPCIDByServerID( xx )
		if g_ObjCared == -1 then
			return
		end
		this:CareObject( g_ObjCared, 1)
		return
	end
	
	if (event == "RL_GRADEUP_PUTIN"  and this:IsVisible()) then
		if arg0 ~= nil then
			EquipLingPai_ShengJie_Update( tonumber(arg0) )
		end
		return
	end
	
	if (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
			EquipLingPai_ShengJie_Update(m_Equip_Idx)
		end 
		return
	end

	if event == "HIDE_ON_SCENE_TRANSED"  then
        EquipLingPai_ShengJie_Reset()
		this:Hide()
	elseif (event == "ADJEST_UI_POS" ) then
		EquipLingPai_ShengJie_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipLingPai_ShengJie_On_ResetPos()
	end
	
	if event == "UPDATE_SELFGUILDCONTRI" then
		local nGuildContri = Guild:GetGuildContri();
		m_StaticText_HaveContri:SetText(tostring(nGuildContri))
	end
	
end

function EquipLingPai_ShengJie_Reset()
	
	LifeAbility : Lock_Packet_Item(m_Equip_Idx,0)
	m_Equip_Idx = -1
	g_ObjCared = -1
	EquipLingPai_ShengJie_OK:Disable()
	EquipLingPai_ShengJie_Object:SetActionItem(-1)
	
	m_StaticText_NeedContri:SetText("")
	local nGuildContri = Guild:GetGuildContri();
	m_StaticText_HaveContri:SetText(tostring(nGuildContri))

end

function EquipLingPai_ShengJie_OnClosed()
	
	EquipLingPai_ShengJie_Reset()
	this:Hide()

end

function EquipLingPai_ShengJie_OnHiden()
	
	EquipLingPai_ShengJie_Reset()
	
end

function EquipLingPai_ShengJie_OnOK()
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	
	-- 判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	
	if m_Equip_Idx == -1 then
		
		PushDebugMessage("#{BHZB_140521_44}")
		return

	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name( "RlGradeLevelUp" );
		Set_XSCRIPT_ScriptID( 880001 );
		Set_XSCRIPT_Parameter( 0, m_Equip_Idx     );         --- 物品背包索引
		Set_XSCRIPT_ParamCount( 1 );
	Send_XSCRIPT();	

end

function EquipLingPai_ShengJie_Update(itemIdx)
	
	local theAction = EnumAction(itemIdx, "packageitem")
	if theAction:GetID() ~= 0 then
		
		if PlayerPackage:Lua_IsBagItemRL( itemIdx ) ~= 1 then
			PushDebugMessage("#{BHZB_140521_69}")	--此处只能放入符石传说。
			return
		end
		
		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0)
		end
		
		EquipLingPai_ShengJie_Object:SetActionItem(theAction:GetID())
		LifeAbility : Lock_Packet_Item(itemIdx,1)
		m_Equip_Idx = itemIdx
		
		local nGrade = PlayerPackage:Lua_GetBagItemRl_Grade( itemIdx ) 
		if nGrade > 0 and nGrade < 5 then
			m_StaticText_NeedContri:SetText(tostring(g_NeedGcp_RlGradeUp[nGrade]))
			EquipLingPai_ShengJie_OK:Enable()
		else
			m_StaticText_NeedContri:SetText("")
			EquipLingPai_ShengJie_OK:Disable()
		end
		
	else
		EquipLingPai_ShengJie_Object:SetActionItem(-1)			
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0)
		m_Equip_Idx = -1
		EquipLingPai_ShengJie_OK:Disable()
		m_StaticText_NeedContri:SetText("")
	end
end

function EquipLingPai_ShengJie_Resume_Equip()
	EquipLingPai_ShengJie_Update(-1)
end

function EquipLingPai_ShengJie_On_ResetPos()
    EquipLingPai_ShengJie_Frame:SetProperty( "UnifiedPosition", g_EquipLingPai_ShengJie_Frame_UnifiedPosition )
end
