
--!!!reloadscript =Nianshou_HuanyuUp

local m_UI_NUM = 880055006	--年兽幻玉浣颜

local m_ObjCared = -1
local m_needMoney = 1000000
local m_BindComfirmed = 0
local m_ItemBagIndex = -1

local g_Nianshou_HuanyuUp_Frame_UnifiedPosition

local g_HuanYu_ItemId = {
	38002710,	--		平明风格【普通】
	38002711,	--		平明风格【普通】绑
	38002684,	--		摇影红风格【高级】
	38002685,	--		摇影红风格【高级】绑
	38002704,	--		沧浪崖风格【高级】
	38002705,	--		沧浪崖风格【高级】绑
	38002686,	--		枕黄粱风格【高级】
	38002687,	--		枕黄粱风格【高级】绑
	38002706,	--		秋水剑风格【高级】
	38002707,	--		秋水剑风格【高级】绑
	38002688,	--		风波起风格【高级】
	38002689,	--		风波起风格【高级】绑
	38002708,	--		霄龙吟风格【稀有】
	38002709,	--		霄龙吟风格【稀有】绑
	38002692,	--		昆凤音风格【稀有】
	38002693,	--		昆凤音风格【稀有】绑
	38002690,	--		霄龙吟风格 新春限定【稀有】
	38002691,	--		霄龙吟风格 新春限定【稀有】绑
	38002712,	--		昆凤音风格 新春限定【稀有】	
	38002713,	--		昆凤音风格 新春限定【稀有】绑

}

local g_HuanYu_Rare_ItemId = {
	38002708,	--		霄龙吟风格【稀有】
	38002709,	--		霄龙吟风格【稀有】绑
	38002692,	--		昆凤音风格【稀有】
	38002693,	--		昆凤音风格【稀有】绑
}

function Nianshou_HuanyuUp_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("MONEY_CHANGE_EX")
	this:RegisterEvent("MONEYJZ_CHANGE_EX")	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	
	this:RegisterEvent("NIANSHOU_HUANYUUP_PUTIN_ITEM",false)
	this:RegisterEvent("NIANSHOU_HUANYUUP_REMOVE_ITEM",false)
	this:RegisterEvent("NIANSHOU_HUANYUUP_RCLICK",false)
	
	this:RegisterEvent("NIANSHOU_HUANYUUP_BIND_CONFIRMED",false)
	
	this:RegisterEvent("OPEN_STALL_SALE",false)
end

function Nianshou_HuanyuUp_OnLoad()

	g_Nianshou_HuanyuUp_Frame_UnifiedPosition = Nianshou_HuanyuUp_Frame:GetProperty("UnifiedPosition")
end

function Nianshou_HuanyuUp_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber( arg0 ) == m_UI_NUM then
		
		if this:IsVisible() then
			return
		end

		Nianshou_HuanyuUp_BeginCareObj( Get_XParam_INT(0) )
		Nianshou_HuanyuUp_CleanUp()
		this:Show()
		OpenWindow("Packet")
		Nianshou_HuanyuUp_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		Nianshou_HuanyuUp_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	elseif	event == "UI_COMMAND" and tonumber(arg0) == 880055003 then
			
		Nianshou_HuanyuUp_CleanUp()
		return
	elseif	event == "UI_COMMAND" and tonumber(arg0) == 880055009 then
			
		Pet:Lua_NianShouHuanYuUpBindConfirm()
		return
	elseif event == "NIANSHOU_HUANYUUP_PUTIN_ITEM"  and this:IsVisible() then
		if tonumber(arg0) ~= nil then
			Nianshou_HuanyuUp_OnItemDragedDropFromBag( tonumber(arg0) )
		end
		return
	elseif event == "NIANSHOU_HUANYUUP_RCLICK"  and this:IsVisible() then
		if tonumber(arg0) ~= nil then
			Nianshou_HuanyuUp_OnBagItemRClicked( tonumber(arg0) )
		end
		return
	elseif event == "NIANSHOU_HUANYUUP_REMOVE_ITEM" then
		Nianshou_HuanyuUp_NoItem()
		return 
	elseif event == "NIANSHOU_HUANYUUP_BIND_CONFIRMED" then
		m_BindComfirmed = 1
		return
	elseif (event == "MONEY_CHANGE_EX" and this : IsVisible()) then
		Nianshou_HuanyuUp_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	elseif (event == "MONEYJZ_CHANGE_EX" and this : IsVisible()) then
		Nianshou_HuanyuUp_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	elseif event == "ADJEST_UI_POS" then
		Nianshou_HuanyuUp_Frame_On_ResetPos()	 
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Nianshou_HuanyuUp_Frame_On_ResetPos()	
	elseif event == "OPEN_STALL_SALE" then
		this:Hide()
	end

end

--从背包拖拽到UI
function Nianshou_HuanyuUp_OnItemDragedDropFromBag(iBagIndex)
	
	--不是幻玉
	local item_table_index = PlayerPackage:GetItemTableIndex(iBagIndex)
	if Nianshou_HuanyuUp_IsNianShouHuanYu(item_table_index) ~= 1 then
		PushDebugMessage("#{ZSWG_181211_88}")	
		return		
	end
	
	if Nianshou_HuanyuUp_IsNianShouHuanYuRare(item_table_index) ~= 1 then
		PushDebugMessage("#{ZSWG_181211_88}")	
		return		
	end	
		
	--加锁
	if PlayerPackage:IsLock( iBagIndex ) == 1 then
		PushDebugMessage("#{ZSWG_181211_91}")	
		return
	end
		
	--释放原来的道具
	if m_ItemBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(m_ItemBagIndex,0)
	end
	
	m_ItemBagIndex = iBagIndex
	
	--刷新界面
	Nianshou_HuanyuUp_Refresh()	
	
end

--从背包内右键点击
function Nianshou_HuanyuUp_OnBagItemRClicked(iBagIndex)
	Nianshou_HuanyuUp_OnItemDragedDropFromBag(iBagIndex)
end

--刷新界面
function Nianshou_HuanyuUp_Refresh()	
	
	--没有道具直接清空
	if m_ItemBagIndex == -1 then
		Nianshou_HuanyuUp_NoItem()
		return
	end
	
	--不是幻玉
	local item_table_index = PlayerPackage:GetItemTableIndex(m_ItemBagIndex)
	if Nianshou_HuanyuUp_IsNianShouHuanYu(item_table_index) ~= 1 then
		Nianshou_HuanyuUp_NoItem()
		return
	end
	
	if Nianshou_HuanyuUp_IsNianShouHuanYuRare(item_table_index) ~= 1 then
		Nianshou_HuanyuUp_NoItem()
		return		
	end	
	
	local theAction = EnumAction(m_ItemBagIndex, "packageitem")
	if theAction:GetID() == 0 then
		Nianshou_HuanyuUp_NoItem()
		return
	end
	
	Nianshou_HuanyuUp_Item:SetActionItem(theAction:GetID())
	LifeAbility:Lock_Packet_Item(m_ItemBagIndex,1)
	
	Nianshou_HuanyuUp_Money1:SetProperty("MoneyNumber", tostring(m_needMoney))
	
	local nHuanLingId = Pet:Lua_GetPetHuanLingIdByItem(item_table_index)
	if nHuanLingId >= 0 then
	
		Nianshou_HuanyuUp_FakeObject:SetFakeObject("")
		Pet:Lua_UpdateNianShouHuanYuModel(nHuanLingId)
		Nianshou_HuanyuUp_FakeObject:SetFakeObject("NianShouHuanYuPet")
		
		local strHuanLingName = Pet:Lua_GetPetHuanLingInfo(nHuanLingId,"Name")
		local strQualText = Pet:Lua_GetPetHuanLingInfo(nHuanLingId,"ExText")
		
		Nianshou_HuanyuUp_Style:SetText("#gFF0FA0"..strHuanLingName)
		Nianshou_HuanyuUp_Style1:SetText(strQualText)
	end
	
	m_BindComfirmed = 0

end

--右键单击ActionItem
function Nianshou_HuanyuUp_OnActionItemRClicked()
	Nianshou_HuanyuUp_NoItem()
end

--Close
function Nianshou_HuanyuUp_Close()
	this:Hide()
end

--OK
function Nianshou_HuanyuUp_OK_Clicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "HuanYuUp" )
		Set_XSCRIPT_ScriptID( 880055 )
		Set_XSCRIPT_Parameter( 0, m_ItemBagIndex )
		Set_XSCRIPT_Parameter( 1, m_BindComfirmed )
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()
end

function Nianshou_HuanyuUp_IsNianShouHuanYu(item_id)

	for i = 1 ,table.getn(g_HuanYu_ItemId) do
		if g_HuanYu_ItemId[i] == item_id then
			return 1
		end
	end
	
	return 0
end

function Nianshou_HuanyuUp_IsNianShouHuanYuRare(item_id)
	
	for i = 1 ,table.getn(g_HuanYu_Rare_ItemId) do
		if g_HuanYu_Rare_ItemId[i] == item_id then
			return 1
		end
	end
	
	return 0
end

function Nianshou_HuanyuUp_NoItem()
	Nianshou_HuanyuUp_CleanUp()
end

function Nianshou_HuanyuUp_OnHidden()
	Nianshou_HuanyuUp_CleanUp()
	
	if IsWindowShow("HuanyuJian") then
		CloseWindow("HuanyuJian",true)
	end
end

function Nianshou_HuanyuUp_CleanUp()
	
	Nianshou_HuanyuUp_Item:SetActionItem(-1)
	
	if m_ItemBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(m_ItemBagIndex,0)
	end
	m_ItemBagIndex = -1
	
	Nianshou_HuanyuUp_FakeObject:SetFakeObject("")
	
	Nianshou_HuanyuUp_Style:SetText("")
	Nianshou_HuanyuUp_Style1:SetText("")
	Nianshou_HuanyuUp_Money1:SetProperty("MoneyNumber", "0")
	
--	Nianshou_HuanyuUp_OK:Disable()
	
--	Nianshou_HuanyuUp_Protect_Text:Hide()
	
--	Nianshou_HuanyuUp_Pet_Info:SetText("")
--	Nianshou_HuanyuUp_Quality_Text:SetText("")
	
	m_BindComfirmed = 0
	
end

function Nianshou_HuanyuUp_Pet_Modle_TurnLeft( start )
	
	--向左旋转开始
	if start == 1 then
		Nianshou_HuanyuUp_FakeObject:RotateBegin(-0.3)
	--向左旋转结束
	else
		Nianshou_HuanyuUp_FakeObject:RotateEnd()
	end

end

function Nianshou_HuanyuUp_Pet_Modle_TurnRight( start )
	--向右旋转开始
	if start == 1 then
		Nianshou_HuanyuUp_FakeObject:RotateBegin(0.3)
	--向右旋转结束
	else
		Nianshou_HuanyuUp_FakeObject:RotateEnd()
	end
end

function Nianshou_HuanyuUp_Jian()
	Pet:Lua_OpenNianShouHuanYuJian(1)
end
--Care Obj
function Nianshou_HuanyuUp_BeginCareObj(obj_id)
	
	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id)
	this:CareObject(m_ObjCared, 1)
end

function Nianshou_HuanyuUp_Frame_On_ResetPos()
  Nianshou_HuanyuUp_Frame:SetProperty("UnifiedPosition", g_Nianshou_HuanyuUp_Frame_UnifiedPosition)
end

--!!!reloadscript =Nianshou_HuanyuUp