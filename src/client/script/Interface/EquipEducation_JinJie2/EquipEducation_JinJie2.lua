local g_EquipEducation_JinJie2_Frame_UnifiedPosition = nil 

local m_ActionButton_Equip
local m_EquipBagIndex = -1
local m_Button_OK
local m_StaticText_NeedMoney

local g_ObjServerID = -1

local m_StaticText_HaveMoney
local m_StaticText_HaveJZ

local m_ItemIndex_Bind = 20800031	--紫薇灵魄（绑定）
local m_ItemIndex = 20800032	--紫薇灵魄
local m_EquipEducation_JinJie2_type = 1
local m_EquipEducation_JinJie2_Times = 0

local m_ItemZWSP = 38005387		--紫薇神魄

function EquipEducation_JinJie2_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT")
	this:RegisterEvent("ZHIZUN_EQUIP_UPGRADE_V2",true)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("ZHIZUN2_EQUIP_UPGRADE_RCLICK",false)
	this:RegisterEvent("ZHIZUN2_EQUIP_UPGRADE_PUTIN_EQUIP",false)
	this:RegisterEvent("ZHIZUN2_EQUIP_UPGRADE_REMOVE_EQUIP",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	
	this:RegisterEvent("ZHIZUN_EQUIP_UPGRADE_DONE") 

end 

-- EquipEducation_JinJie2_Close => TLBB_ButtonClose
-- EquipEducation_JinJie2_DragTitle => TLBB_DragTitle
-- EquipEducation_JinJie2_Client => DefaultWindow
function EquipEducation_JinJie2_OnLoad()
	g_EquipEducation_JinJie2_Frame_UnifiedPosition = EquipEducation_JinJie2_Frame:GetProperty("UnifiedPosition");
	

	m_ActionButton_Equip = EquipEducation_JinJie2_Icon
	m_Button_OK = EquipEducation_JinJie2_OK
	m_StaticText_NeedMoney = EquipEducation_JinJie2_DemandMoney

	m_StaticText_HaveMoney = EquipEducation_JinJie2_SelfMoney
	m_StaticText_HaveJZ = EquipEducation_JinJie2_SelfJiaozi
end

function EquipEducation_JinJie2_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		EquipEducation_JinJie2_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		EquipEducation_JinJie2_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		EquipEducation_JinJie2_OnHiden()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		EquipEducation_JinJie2_CareObj()
	elseif (event == "ZHIZUN_EQUIP_UPGRADE_V2") then
		g_ObjServerID = tonumber( arg0 )
		m_EquipEducation_JinJie2_type = tonumber( arg1 )
		m_EquipEducation_JinJie2_Times = tonumber( arg2 )
		EquipEducation_JinJie2_Init()	
		this:Show()
		
		if IsWindowShow("Packet") == false then
			ToggleContainer()
		end
		-- PushDebugMessage("g_ObjServerID="..g_ObjServerID)
		EquipEducation_JinJie2_BeginCareObject(g_ObjServerID)
	elseif (event == "PACKAGE_ITEM_CHANGED_EX") then
		if arg0 ~= nil and tonumber(arg0) == m_EquipBagIndex then
			EquipEducation_JinJie2_Refresh()
		end 
		
		local item_count = PlayerPackage:CountAvailableItemByIDTable(m_ItemIndex)
		local item_count_bind = PlayerPackage:CountAvailableItemByIDTable(m_ItemIndex_Bind)
		local zwsp_count = PlayerPackage:Lua_GetUnLockItemCount(m_ItemZWSP)
	
		local string_zw = "#G"..tostring(item_count + item_count_bind)
		if item_count + item_count_bind < 50 then
			string_zw = "#cFF0000"..tostring(item_count + item_count_bind)
		end
	
		local string_sp = "#G"..tostring(zwsp_count)
		if zwsp_count < 1 then
			string_sp = "#cFF0000"..tostring(zwsp_count)
		end
		
		local strTemp = ScriptGlobal_Format("#{ZZZB_151105_10}", string_sp, string_zw)		
		EquipEducation_JinJie2_ZWLPHold_Text:SetText(strTemp)

		return
	elseif (event == "ZHIZUN2_EQUIP_UPGRADE_RCLICK") then
		if arg0 ~= nil then
			EquipEducation_JinJie2_OnBagItemRClicked( tonumber(arg0) )
		end
		return
	elseif (event == "ZHIZUN2_EQUIP_UPGRADE_PUTIN_EQUIP") then
		if arg0 ~= nil then
			EquipEducation_JinJie2_OnItemDragedDropFromBag( tonumber(arg0) )
		end
		return	
	elseif (event == "ZHIZUN2_EQUIP_UPGRADE_REMOVE_EQUIP") then
		EquipEducation_JinJie2_OnItemDragedDropAway()
		return		
	end
	
	if (event == "MONEY_CHANGE_EX" and this:IsVisible() ) then
		m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		return
	end
	
	if (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end
	
	if event == "ZHIZUN_EQUIP_UPGRADE_DONE" and this:IsVisible() then
		m_EquipEducation_JinJie2_Times = tonumber( arg0 )
		EquipEducation_JinJie2_UpdateText()
		return
	end
	
end

function EquipEducation_JinJie2_UpdateText()
	
	if m_EquipEducation_JinJie2_type == 2 then	
		EquipEducation_JinJie2_DragTitle:SetText("#{ZZZB_200805_20}")	
			
		EquipEducation_JinJie2_Page1:Hide()
		EquipEducation_JinJie2_Page2:Show()
		
		local guildID, _ = DataPool:GetGuildClanID()
		if guildID < 0 then
			EquipEducation_JinJie2_Info1:SetText("#{ZZZB_200805_13}")
		else
			local ZhiZunOpen = Guild:GetMyGuildDetailInfo( "zhizunopen" )
			if ZhiZunOpen == 1 then
				local ZhiZunTimes, nTips = Guild:GetMyGuildDetailInfo( "zhizunday" )	
				local nStr = ScriptGlobal_Format("#{ZZZB_200805_49}", ZhiZunTimes)
				if m_EquipEducation_JinJie2_Times == 1 then
					nStr = ScriptGlobal_Format("#{ZZZB_200805_11}", ZhiZunTimes)
				end
				EquipEducation_JinJie2_Info1:SetText( nStr )
			else
				EquipEducation_JinJie2_Info1:SetText( "#{ZZZB_200805_12}" )
			end
		end
		
	else	
		EquipEducation_JinJie2_DragTitle:SetText("#{ZZZB_150811_25}")
		
		EquipEducation_JinJie2_Page1:Show()
		EquipEducation_JinJie2_Page2:Hide()
		
		if m_EquipEducation_JinJie2_Times == 1 then
			EquipEducation_JinJie2_Info1:SetText( "#{ZZZB_150811_26}" )
		else
			EquipEducation_JinJie2_Info1:SetText( "#{ZZZB_200805_48}" )
		end
		
	end
	
end

function EquipEducation_JinJie2_CareObj()
	if(tonumber(arg0) ~= g_objCareID) then
		return;
	end
	-- PushDebugMessage("666666666666=")
	--如果和NPC的距离大于一定距离或者被删除，自动关闭
	if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
		--取消关心
		EquipEducation_JinJie2_StopCareObject(g_objCareID)
		EquipEducation_JinJie2_OnHiden()
	end		
end

function EquipEducation_JinJie2_StopCareObject(objCaredId)
	this:CareObject(objCaredId, 0, "EquipEducation_JinJie2");
	g_objCareID = -1;
end

function EquipEducation_JinJie2_BeginCareObject(objid)
	local nID = DataPool : GetNPCIDByServerID( objid )
	g_Object = nID
	this:CareObject(g_Object, 1);
end

function EquipEducation_JinJie2_On_ResetPos()
	EquipEducation_JinJie2_Frame:SetProperty("UnifiedPosition", g_EquipEducation_JinJie2_Frame_UnifiedPosition)
end



function EquipEducation_JinJie2_OnHiden()
	EquipEducation_JinJie2_CleanUp()
	this:Hide()
end

function EquipEducation_JinJie2_OnCloseClicked()
	EquipEducation_JinJie2_CleanUp()
	this:Hide()
end


function EquipEducation_JinJie2_Init()
	EquipEducation_JinJie2_CleanUp()

	m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	
	local item_count = PlayerPackage:CountAvailableItemByIDTable(m_ItemIndex)
	local item_count_bind = PlayerPackage:CountAvailableItemByIDTable(m_ItemIndex_Bind)
	
	local zwsp_count = PlayerPackage:Lua_GetUnLockItemCount(m_ItemZWSP)
	
	local string_zw = "#G"..tostring(item_count + item_count_bind)
	if item_count + item_count_bind < 50 then
		string_zw = "#cFF0000"..tostring(item_count + item_count_bind)
	end
	
	local string_sp = "#G"..tostring(zwsp_count)
	if zwsp_count < 1 then
		string_sp = "#cFF0000"..tostring(zwsp_count)
	end
	
	local strTemp = ScriptGlobal_Format("#{ZZZB_151105_10}", string_sp, string_zw)
	
	EquipEducation_JinJie2_ZWLPHold_Text:SetText(strTemp)
	
	EquipEducation_JinJie2_UpdateText()
	
end

function EquipEducation_JinJie2_CleanUp()
	       
	if m_EquipEducation_JinJie2_type == 2 then
		EquipEducation_JinJie2_Object2_Icon:SetActionItem(-1)
	else
		m_ActionButton_Equip:SetActionItem(-1)
	end
	
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	m_EquipBagIndex = -1
	m_Button_OK:Disable()
	
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")


end


--从背包内右键点击
function EquipEducation_JinJie2_OnBagItemRClicked( iBagIndex )

	if Player:GetData("LEVEL") < 85 then
		PushDebugMessage("#{ZZZB_200805_5}")	--角色等级
		return
	end
	
	if PlayerPackage:Lua_IsBagItemBelongZZType( iBagIndex ) ~= 1 then
		PushDebugMessage("#{FMYZ_180529_33}")	--不属于可升灵装备
		return
	end
	
	if m_EquipEducation_JinJie2_type == 2 then
		-- 是否王权
		if PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) ~= 1 then
			PushDebugMessage("#{ZZZB_200805_14}")	--至尊装备不能进阶了
			return
		end
	else
		-- 是否王权
		if PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) == 1 then
			PushDebugMessage("#{ZZZB_200805_6}")	--至尊装备不能进阶了
			return
		end
		-- 是否天道
		if PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) == 2 then
			PushDebugMessage("#{ZZZB_150811_269}")	--至尊装备不能进阶了
			return
		end
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeLevel(iBagIndex) < 9 then
		PushDebugMessage("#{FMYZ_180529_35}")	--升灵未到满级
		return
	end	
	
	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	EquipEducation_JinJie2_NoEqup()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	EquipEducation_JinJie2_Refresh()

end

function EquipEducation_JinJie2_OnActionItemRClicked()
	EquipEducation_JinJie2_NoEqup()
end

--UI没有装备的状态
function EquipEducation_JinJie2_NoEqup()

	if m_EquipEducation_JinJie2_type == 2 then
		EquipEducation_JinJie2_Object2_Icon:SetActionItem(-1)
	else
		m_ActionButton_Equip:SetActionItem(-1)
	end
	
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end

	m_EquipBagIndex = -1
	
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")

	m_Button_OK:Disable()
	
end


--刷新界面
function EquipEducation_JinJie2_Refresh()
	
	if m_EquipBagIndex == -1 then	
		EquipEducation_JinJie2_NoEqup()
		return
		
	end
	
	if PlayerPackage:Lua_IsBagItemBelongZZType( m_EquipBagIndex ) ~= 1 then
		EquipEducation_JinJie2_NoEqup()	--不属于可升灵装备
		return
	end
	
	if m_EquipEducation_JinJie2_type == 2 then
		EquipEducation_JinJie2_Page1:Hide()
		EquipEducation_JinJie2_Page2:Show()
		-- 是否王权
		if PlayerPackage:Lua_GetBagEquipHandMakeType( m_EquipBagIndex ) ~= 1 then
			EquipEducation_JinJie2_NoEqup()		--至尊装备不能进阶了
			return
		end
	else
		EquipEducation_JinJie2_Page1:Show()
		EquipEducation_JinJie2_Page2:Hide()
		-- 是否王权
		if PlayerPackage:Lua_GetBagEquipHandMakeType( m_EquipBagIndex ) == 1 then
			EquipEducation_JinJie2_NoEqup()		--至尊装备不能进阶了
			return
		end
		-- 是否天道
		if PlayerPackage:Lua_GetBagEquipHandMakeType( m_EquipBagIndex ) == 2 then
			EquipEducation_JinJie2_NoEqup()		--至尊装备不能进阶了
			return
		end
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeLevel(m_EquipBagIndex) < 9 then
		EquipEducation_JinJie2_NoEqup()	--升灵未到满级
		return
	end
	
	local theAction = EnumAction(m_EquipBagIndex, "packageitem")
	if theAction:GetID() == 0 then		
		EquipEducation_JinJie2_NoEqup()
		return
		
	end
	
	if m_EquipEducation_JinJie2_type == 2 then
		EquipEducation_JinJie2_Object2_Icon:SetActionItem(theAction:GetID())
	else
		m_ActionButton_Equip:SetActionItem(theAction:GetID())
	end
	
	LifeAbility : Lock_Packet_Item(m_EquipBagIndex,1)
	
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "500000")

	EquipEducation_JinJie2_ZWLPNeed_Text:SetText("#{ZZZB_151105_09}")

	m_Button_OK:Enable()
	
end

function EquipEducation_JinJie2_OnOK()
	if m_EquipBagIndex == -1 then
		return
	end

	--判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZZZB_150811_15}")
		return
	end
	
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "CommonUpGrade" )
		Set_XSCRIPT_ScriptID( 880036 )
		Set_XSCRIPT_Parameter( 0, g_ObjServerID )
		Set_XSCRIPT_Parameter( 1, m_EquipBagIndex )       	--- 物品背包索引
		Set_XSCRIPT_Parameter( 2, m_EquipEducation_JinJie2_type )      --- 是否王权1 天道2
		Set_XSCRIPT_Parameter( 3, 1 )       				--- 是否需要绑定确认
		Set_XSCRIPT_ParamCount( 4 )
	Send_XSCRIPT()	
end


function EquipEducation_JinJie2_OnItemDragedDropFromBag(iBagIndex)
	if PlayerPackage:Lua_IsBagItemBelongZZType( iBagIndex ) ~= 1 then
		PushDebugMessage("#{FMYZ_180529_33}")	--不属于可升灵装备
		return
	end
	
	if m_EquipEducation_JinJie2_type == 2 then
		-- 是否王权
		if PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) ~= 1 then
			PushDebugMessage("#{ZZZB_200805_14}")	--至尊装备不能进阶了
			return
		end
	else
		-- 是否王权
		if PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) == 1 then
			PushDebugMessage("#{ZZZB_200805_6}")	--至尊装备不能进阶了
			return
		end
		-- 是否天道
		if PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) == 2 then
			PushDebugMessage("#{ZZZB_150811_269}")	--至尊装备不能进阶了
			return
		end
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeLevel(iBagIndex) < 9 then
		PushDebugMessage("#{FMYZ_180529_35}")	--升灵未到满级
		return
	end	
	
	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	EquipEducation_JinJie2_NoEqup()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	EquipEducation_JinJie2_Refresh()
end

function EquipEducation_JinJie2_OnItemDragedDropAway()
	EquipEducation_JinJie2_NoEqup()
end


function EquipEducation_JinJie2_OnCancelClicked()
	EquipEducation_JinJie2_OnCloseClicked()
end