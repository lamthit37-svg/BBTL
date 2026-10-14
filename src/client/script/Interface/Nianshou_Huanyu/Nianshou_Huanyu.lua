
--!!!reloadscript =Nianshou_Huanyu

local m_UI_NUM = 880055004	--年兽幻玉洗练

local m_ObjCared = -1
local m_needMoney = 10000
local m_BindComfirmed = 0
local m_RareComfirmed = 0
local m_ItemBagIndex = -1

local g_Nianshou_Huanyu_Frame_UnifiedPosition

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

local g_HuanYu_SuperRare_ItemId = {
	38002690,	--		霄龙吟风格 新春限定【稀有】
	38002691,	--		霄龙吟风格 新春限定【稀有】绑
	38002712,	--		昆凤音风格 新春限定【稀有】	
	38002713,	--		昆凤音风格 新春限定【稀有】绑
}

function Nianshou_Huanyu_PreLoad()
	this:RegisterEvent( "UI_COMMAND" )
	this:RegisterEvent("MONEY_CHANGE_EX")
	this:RegisterEvent("MONEYJZ_CHANGE_EX")	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	
	this:RegisterEvent("NIANSHOU_HUANYU_PUTIN_ITEM",false)
	this:RegisterEvent("NIANSHOU_HUANYU_REMOVE_ITEM",false)
	this:RegisterEvent("NIANSHOU_HUANYU_RCLICK",false)
	
	this:RegisterEvent("NIANSHOU_HUANYU_RARE_CONFIRMED",false)
	this:RegisterEvent("NIANSHOU_HUANYU_BIND_CONFIRMED",false)
	
	this:RegisterEvent("OPEN_STALL_SALE",false)
end

function Nianshou_Huanyu_OnLoad()

	g_Nianshou_Huanyu_Frame_UnifiedPosition = Nianshou_Huanyu_Frame:GetProperty("UnifiedPosition")
end

function Nianshou_Huanyu_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber( arg0 ) == m_UI_NUM then
		
		if this:IsVisible() then
			return
		end

		Nianshou_Huanyu_BeginCareObj( Get_XParam_INT(0) )
		Nianshou_Huanyu_CleanUp()
		this:Show()
		OpenWindow("Packet")
		Nianshou_Huanyu_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		Nianshou_Huanyu_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	elseif	event == "UI_COMMAND" and tonumber(arg0) == 880055005 then
			
		Nianshou_Huanyu_CleanUp()
		local newIndex = Get_XParam_INT(0)
		m_ItemBagIndex = newIndex
		Nianshou_Huanyu_Refresh()

		return
		
	elseif	event == "UI_COMMAND" and tonumber(arg0) == 880055007 then
			
		local nItemBagIndex = Get_XParam_INT(0)
		Pet:Lua_NianShouHuanYuRareConfirm(nItemBagIndex)
		return
	elseif	event == "UI_COMMAND" and tonumber(arg0) == 880055008 then
			
		Pet:Lua_NianShouHuanYuBindConfirm()
		return	
	elseif event == "NIANSHOU_HUANYU_PUTIN_ITEM"  and this:IsVisible() then
		if tonumber(arg0) ~= nil then
			Nianshou_Huanyu_OnItemDragedDropFromBag( tonumber(arg0) )
		end
		return
	elseif event == "NIANSHOU_HUANYU_RCLICK"  and this:IsVisible() then
		if tonumber(arg0) ~= nil then
			Nianshou_Huanyu_OnBagItemRClicked( tonumber(arg0) )
		end
		return
	elseif event == "NIANSHOU_HUANYU_REMOVE_ITEM" then
		Nianshou_Huanyu_NoItem()
		return 
	elseif event == "NIANSHOU_HUANYU_RARE_CONFIRMED" then
		m_RareComfirmed = 1
		return
	elseif event == "NIANSHOU_HUANYU_BIND_CONFIRMED" then
		m_BindComfirmed = 1
		return
	elseif (event == "MONEY_CHANGE_EX" and this : IsVisible()) then
		Nianshou_Huanyu_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	elseif (event == "MONEYJZ_CHANGE_EX" and this : IsVisible()) then
		Nianshou_Huanyu_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	elseif event == "ADJEST_UI_POS" then
		Nianshou_Huanyu_Frame_On_ResetPos()	 
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Nianshou_Huanyu_Frame_On_ResetPos()	
	elseif event == "OPEN_STALL_SALE" then
		this:Hide()
	end

end

--从背包拖拽到UI
function Nianshou_Huanyu_OnItemDragedDropFromBag(iBagIndex)
	
	--不是幻玉
	local item_table_index = PlayerPackage:GetItemTableIndex(iBagIndex)
	if Nianshou_Huanyu_IsNianShouHuanYu(item_table_index) ~= 1 then
		PushDebugMessage("#{ZSWG_181211_59}")
		return		
	end
	
	--升级后的幻玉
	if Nianshou_Huanyu_IsNianShouHuanYuSuperRare(item_table_index) == 1 then
		PushDebugMessage("#{ZSWG_181211_59}")
		return		
	end
	
	--加锁
	if PlayerPackage:IsLock( iBagIndex ) == 1 then
		PushDebugMessage("#{ZSWG_181211_92}")	
		return
	end
		
	--释放原来的道具
	if m_ItemBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(m_ItemBagIndex,0)
	end
	
	m_ItemBagIndex = iBagIndex
	
	--刷新界面
	Nianshou_Huanyu_Refresh()	
	
end

--从背包内右键点击
function Nianshou_Huanyu_OnBagItemRClicked(iBagIndex)
	Nianshou_Huanyu_OnItemDragedDropFromBag(iBagIndex)
end

--刷新界面
function Nianshou_Huanyu_Refresh()	
	
	--没有道具直接清空
	if m_ItemBagIndex == -1 then
		Nianshou_Huanyu_NoItem()
		return
	end
	
	--不是幻玉
	local item_table_index = PlayerPackage:GetItemTableIndex(m_ItemBagIndex)
	if Nianshou_Huanyu_IsNianShouHuanYu(item_table_index) ~= 1 then
		Nianshou_Huanyu_NoItem()
		return
	end
	
	if Nianshou_Huanyu_IsNianShouHuanYuSuperRare(item_table_index) == 1 then
		Nianshou_Huanyu_NoItem()
		return
	end
	
	local theAction = EnumAction(m_ItemBagIndex, "packageitem")
	if theAction:GetID() == 0 then
		Nianshou_Huanyu_NoItem()
		return
	end
	
	Nianshou_Huanyu_Item:SetActionItem(theAction:GetID())
	LifeAbility:Lock_Packet_Item(m_ItemBagIndex,1)
	
	Nianshou_Huanyu_Money1:SetProperty("MoneyNumber", tostring(m_needMoney))
	
	local nHuanLingId = Pet:Lua_GetPetHuanLingIdByItem(item_table_index)
	if nHuanLingId >= 0 then
	
		Nianshou_Huanyu_FakeObject:SetFakeObject("")
		Pet:Lua_UpdateNianShouHuanYuModel(nHuanLingId)
		Nianshou_Huanyu_FakeObject:SetFakeObject("NianShouHuanYuPet")
		
		local strHuanLingName = Pet:Lua_GetPetHuanLingInfo(nHuanLingId,"Name")
		local strQualText = Pet:Lua_GetPetHuanLingInfo(nHuanLingId,"ExText")
		
		Nianshou_Huanyu_Style:SetText("#gFF0FA0"..strHuanLingName)
		Nianshou_Huanyu_Style1:SetText(strQualText)
	end
	
	m_BindComfirmed = 0
	m_RareComfirmed = 0

end

--右键单击ActionItem
function Nianshou_Huanyu_OnActionItemRClicked()
	Nianshou_Huanyu_NoItem()
end

--Close
function Nianshou_Huanyu_Close()
	this:Hide()
end

--OK
function Nianshou_Huanyu_OK_Clicked()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "HuanYuXiLian" )
		Set_XSCRIPT_ScriptID( 880055 )
		Set_XSCRIPT_Parameter(0, m_ItemBagIndex)
		Set_XSCRIPT_Parameter(1, m_RareComfirmed)
		Set_XSCRIPT_Parameter(2, m_BindComfirmed)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function Nianshou_Huanyu_IsNianShouHuanYu(item_id)

	for i = 1 ,table.getn(g_HuanYu_ItemId) do
		if g_HuanYu_ItemId[i] == item_id then
			return 1
		end
	end
	
	return 0
end

function Nianshou_Huanyu_IsNianShouHuanYuRare(item_id)
	
	for i = 1 ,table.getn(g_HuanYu_Rare_ItemId) do
		if g_HuanYu_Rare_ItemId[i] == item_id then
			return 1
		end
	end
	
	return 0
end

function Nianshou_Huanyu_IsNianShouHuanYuSuperRare(item_id)
	
	for i = 1 ,table.getn(g_HuanYu_SuperRare_ItemId) do
		if g_HuanYu_SuperRare_ItemId[i] == item_id then
			return 1
		end
	end
	
	return 0
end

function Nianshou_Huanyu_NoItem()
	Nianshou_Huanyu_CleanUp()
end

function Nianshou_Huanyu_OnHidden()
	Nianshou_Huanyu_CleanUp()
	
	if IsWindowShow("HuanyuJian") then
		CloseWindow("HuanyuJian",true)
	end
end

function Nianshou_Huanyu_CleanUp()
	
	Nianshou_Huanyu_Item:SetActionItem(-1)
	
	if m_ItemBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(m_ItemBagIndex,0)
	end
	m_ItemBagIndex = -1
	
	Nianshou_Huanyu_FakeObject:SetFakeObject("")
	
	Nianshou_Huanyu_Style:SetText("")
	Nianshou_Huanyu_Style1:SetText("")
	Nianshou_Huanyu_Money1:SetProperty("MoneyNumber", "0")
	
--	Nianshou_Huanyu_OK:Disable()
	
--	Nianshou_Huanyu_Protect_Text:Hide()
	
--	Nianshou_Huanyu_Pet_Info:SetText("")
--	Nianshou_Huanyu_Quality_Text:SetText("")
	
	m_BindComfirmed = 0
	
	m_RareComfirmed = 0
	
end

function Nianshou_Huanyu_Pet_Modle_TurnLeft( start )
	
	--向左旋转开始
	if start == 1 then
		Nianshou_Huanyu_FakeObject:RotateBegin(-0.3)
	--向左旋转结束
	else
		Nianshou_Huanyu_FakeObject:RotateEnd()
	end

end

function Nianshou_Huanyu_Pet_Modle_TurnRight( start )
	--向右旋转开始
	if start == 1 then
		Nianshou_Huanyu_FakeObject:RotateBegin(0.3)
	--向右旋转结束
	else
		Nianshou_Huanyu_FakeObject:RotateEnd()
	end
end

function Nianshou_Huanyu_Jian()
	Pet:Lua_OpenNianShouHuanYuJian(0)
end
--Care Obj
function Nianshou_Huanyu_BeginCareObj(obj_id)
	
	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id)
	this:CareObject(m_ObjCared, 1)
end

function Nianshou_Huanyu_Frame_On_ResetPos()
  Nianshou_Huanyu_Frame:SetProperty("UnifiedPosition", g_Nianshou_Huanyu_Frame_UnifiedPosition)
end

--!!!reloadscript =Nianshou_Huanyu