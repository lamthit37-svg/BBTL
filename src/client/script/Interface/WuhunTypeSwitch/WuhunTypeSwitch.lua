
local m_creation_Frame_UnifiedPosition;
local m_ObjCared = -1
local m_isComfirmed = 0
local m_bagPos = -1

local m_WuHunTypeExchaneData = 
{
	[10156002] = {ItemId=10156001, NeedMoney=1000000},
	[10156004] = {ItemId=10156003, NeedMoney=1000000},
	[10156001] = {ItemId=10156002, NeedMoney=1000000},
	[10156003] = {ItemId=10156004, NeedMoney=1000000},
}

local m_Timer_Step = 500		-- 多少时间(毫秒)模拟一次 Click 操作
local m_isStartExe = 0
local m_tick = 0
--PreLoad
function WuhunTypeSwitch_PreLoad()
	this:RegisterEvent("WUHUN_TYPE_EXCHANGE");
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
end

--Onload
function WuhunTypeSwitch_OnLoad()
	m_creation_Frame_UnifiedPosition = WuhunTypeSwitch_Frame:GetProperty("UnifiedPosition");
end

--OnEvent
function WuhunTypeSwitch_OnEvent(event)
	--PushDebugMessage(event)
	if event == "WUHUN_TYPE_EXCHANGE" then
		local opType = tonumber(arg0)
		if opType == 1 then--打开界面
			WuhunTypeSwitch_BeginCareObj(tonumber(arg1))
			WuhunTypeSwitch_Init()
			WuhunTypeSwitch_Show()
		elseif opType == 2 then --关闭界面
			WuhunTypeSwitch_Hide()
		elseif opType == 3 then --返回二次确认框
			local bagPos = tonumber(arg1)
			local itemId = tonumber(arg2)
			local exchangeItemId = tonumber(arg3)
			local itemName = DataPool:Lua_GetItemNameByIndex(itemId)
			local exchangeitemName = DataPool:Lua_GetItemNameByIndex(exchangeItemId)
			if nil ~= itemName and exchangeitemName ~= nil then
				local str = ScriptGlobal_Format("#{ZMPWH_180728_25}",itemName, exchangeitemName)
				PopComfirm_Alpha0(str)
				m_isComfirmed = 1
			end
		elseif opType == 4 then --转换成功
			WuhunTypeSwitch_Update(-1)
		elseif opType == 5 then --拖拽背包中的物品到该界面内
			if arg1 ~= nil then
				WuhunTypeSwitch_Update( tonumber(arg1) )
			end
		end
	elseif (event == "MONEY_CHANGE_EX") then
		WuhunTypeSwitch_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	
	elseif (event == "MONEYJZ_CHANGE_EX") then 
		WuhunTypeSwitch_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	
	elseif (event == "PACKAGE_ITEM_CHANGED_EX") then
		if arg0 ~= nil and tonumber(arg0) == m_bagPos then
			WuhunTypeSwitch_Update(m_bagPos)
		end 
	elseif event == "ADJEST_UI_POS"  then
		WuhunTypeSwitch_Frame_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then-- 游戏分辨率发生了变化
		WuhunTypeSwitch_Frame_On_ResetPos()
	end
end
--清除数据
function WuhunTypeSwitch_ClearData()
	
end
--初始化UI
function WuhunTypeSwitch_Init()
	
end
--显示UI
function WuhunTypeSwitch_Show()
	this:Show()
	WuhunTypeSwitch_Update(-1)
	WuhunTypeSwitch_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"));
	WuhunTypeSwitch_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ")); 
	WuhunTypeSwitch_DemandMoney : SetProperty("MoneyNumber", 0)

	SetTimer("WuhunTypeSwitch", "WuhunTypeSwitch_Timer()", m_Timer_Step)
end
--隐藏UI
function WuhunTypeSwitch_Hide()
	KillTimer("WuhunTypeSwitch_Timer()")
	m_isStartExe = 0
	m_tick = 0
	WuhunTypeSwitch_Object:SetActionItem(-1)	
	LifeAbility : Lock_Packet_Item(m_bagPos,0)
	m_bagPos = -1
	m_isComfirmed = 0
	this:Hide()
end
--定时器
function WuhunTypeSwitch_Timer()
	if 1 ~= m_isStartExe then
		return
	end
	if m_tick >= 4 then --2秒后可以在次点击
		m_isStartExe = 0
		m_tick = 0
	end
	m_tick = m_tick + 1
end
--更新UI
function WuhunTypeSwitch_Update(bagPos)
	m_isComfirmed = 0
	local needMoney = 0
	local theAction = EnumAction(bagPos, "packageitem")
	if theAction:GetID() ~= 0 then
		local itemIndex =  PlayerPackage:GetItemTableIndex(bagPos)
		if m_WuHunTypeExchaneData[itemIndex] == nil then
			PushDebugMessage("#{ZMPWH_180728_14}") -- 此处只能放入武魂。
			return
		end
		needMoney = m_WuHunTypeExchaneData[itemIndex].NeedMoney
		if PlayerPackage:IsLock(bagPos) == 1 then
			PushDebugMessage("#{ZMPWH_180728_15}") -- 
			return
		end
		if m_bagPos ~= -1 then
			LifeAbility : Lock_Packet_Item(m_bagPos,0);
		end
		WuhunTypeSwitch_Object:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(bagPos,1);
		m_bagPos = bagPos
	else
		WuhunTypeSwitch_Object:SetActionItem(-1)	
		LifeAbility : Lock_Packet_Item(m_bagPos,0)
		m_bagPos = -1
	end
	if m_bagPos < 0 then
		WuhunTypeSwitch_OK:Disable()
		WuhunTypeSwitch_DemandMoney : SetProperty("MoneyNumber", 0)
	else
		WuhunTypeSwitch_DemandMoney : SetProperty("MoneyNumber", needMoney)
		WuhunTypeSwitch_OK:Enable()
	end
end
--###############点击事件####################
function WuhunTypeSwitch_Close()
	WuhunTypeSwitch_Hide()
end
function WuhunTypeSwitch_Resume_Equip()
	WuhunTypeSwitch_Update(-1)
end
function WuhunTypeSwitch_OK_Clicked()
	if m_isStartExe == 1 then
		PushDebugMessage("#{ZMPWH_180728_57}")
		return
	end

	if m_bagPos < 0 then
		PushDebugMessage("#{ZMPWH_180728_20}")
		return
	end
	local itemIndex =  PlayerPackage:GetItemTableIndex(m_bagPos)
	if m_WuHunTypeExchaneData[itemIndex] == nil then
		PushDebugMessage("#{ZMPWH_180728_17}") -- 此处只能放入武魂。
		return
	end
	local needMoney = m_WuHunTypeExchaneData[itemIndex].NeedMoney

	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	
	if selfMoney < needMoney then
		PushDebugMessage("#{ZMPWH_180728_24}")   --对不起，你身上金钱不足，无法继续进行。
		return
	end
	if m_isComfirmed == 1 then
		m_tick = 0
		m_isStartExe = 1
		PlayerPackage:Kfs_Op_Do(14 , m_bagPos , 0);
	else
		PlayerPackage:Kfs_Op_Do(14 , m_bagPos , 1)
	end
end
--###########################################
--Care Obj
function WuhunTypeSwitch_BeginCareObj(obj_id)
	
	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1);
end

-- 重置界面的位置
function WuhunTypeSwitch_Frame_On_ResetPos()
  WuhunTypeSwitch_Frame:SetProperty("UnifiedPosition", m_creation_Frame_UnifiedPosition);
end