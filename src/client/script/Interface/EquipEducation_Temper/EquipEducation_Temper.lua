
local MAX_OBJ_DISTANCE = 3.0
local g_CaredNpc = -1
local g_EquipEducation_Temper_Item = -1
local g_EquipEducation_Temper_IsBind = 0
local g_EquipEducation_Temper_HaveGoldNum = 0
local g_EquipEducation_Temper_Confirm = -1
local g_EquipEducation_Temper_QueRenConfirm = -1
local g_EquipEducation_Temper_QueRenConfirmState = 0 
local g_EquipEducation_Temper_binditem = 20700063
local g_EquipEducation_Temper_unbinditem = 20700062
local g_ItemNeed = 20700062
local g_LockState = {}
local g_IsHaveAttaPro = 0
local g_QuerenLockState = {}


local g_EquipEducation_Temper_Frame_UnifiedPosition;

local g_ETemper_Attr = {};

--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function EquipEducation_Temper_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("SHOUGONG_FUZHUO")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)

	this:RegisterEvent("CONFIRM_EquipEducation_Temper")
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("EQUIP_TEMPER_SENDMSG")
	this:RegisterEvent("EQUIP_TEMPER_QUERENSENDMSG")
end

--=========================================================
-- 载入初始化
--=========================================================
function EquipEducation_Temper_OnLoad()
	g_EquipEducation_Temper_Item = -1
	g_EquipEducation_Temper_HaveGoldNum = 0
	EquipEducation_Temper_HaveGoldNum:SetProperty("MoneyNumber", tostring(g_EquipEducation_Temper_HaveGoldNum))

	-- 始终可以点击 OK 按钮, 为了方便提示玩家信息
	EquipEducation_Temper_OK:Enable()
	
	g_EquipEducation_Temper_Frame_UnifiedPosition=EquipEducation_Temper_Frame:GetProperty("UnifiedPosition");
	g_ETemper_Attr[1] = EquipEducation_Temper_AttrFirstText
	g_ETemper_Attr[2] = EquipEducation_Temper_AttrSecondText
	g_ETemper_Attr[3] = EquipEducation_Temper_AttrThirdText
	
	g_LockState[1] = {Button = EquipEducation_Temper_AttrFirstButton, State = 0}	--未锁定状态
	g_LockState[2] = {Button = EquipEducation_Temper_AttrSecondButton, State = 0}
	g_LockState[3] = {Button = EquipEducation_Temper_AttrThirdButton, State = 0}
	g_QuerenLockState[1] = {Button = EquipEducation_Temper_Queren,State = 0}
	
	--默认设置勾选与其他功能分离
	g_QuerenLockState[1].Button:SetCheck(1)
	g_QuerenLockState[1].State = 1
end

--=========================================================
-- 事件处理
--=========================================================
function EquipEducation_Temper_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 20130604) then
		local xx = Get_XParam_INT(0)
		g_CaredNpc = DataPool:GetNPCIDByServerID(xx)
		if g_CaredNpc == -1 then
			PushDebugMessage("server传过来的数据有问题。")
			return
		end
		BeginCareObject_EquipEducation_Temper()
		EquipEducation_Temper_Clear()
		EquipEducation_Temper_UpdateBasic()
		this:Show()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 20130724 and this:IsVisible()) then
		--淬炼成功刷新属性
		local bagIndex = Get_XParam_INT(0)
		BeginCareObject_EquipEducation_Temper()
		EquipEducation_Temper_UpdateBasic()
		EquipEducation_Temper_Update(tonumber(bagIndex))
		g_EquipEducation_Temper_QueRenConfirmState = 0;
		g_EquipEducation_Temper_QueRenConfirm = -1
		this:Show()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if (tonumber(arg0) ~= g_CaredNpc) then
			return
		end
		if ((arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE) or arg1=="destroy") then
			EquipEducation_Temper_Close()
		end
	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
			EquipEducation_Temper_UpdateBasic()
	elseif (event == "SHOUGONG_FUZHUO") then
		if arg0 ~= nil then
			EquipEducation_Temper_Update(arg0)
			EquipEducation_Temper_UpdateBasic()
		end
	elseif (event == "MONEY_CHANGE_EX" or event =="MONEYJZ_CHANGE_EX") then
		EquipEducation_Temper_UpdateBasic()
	elseif (event == "CONFIRM_EquipEducation_Temper") then
		EquipEducation_Temper_OK_Clicked(1)
		
	elseif (event == "ADJEST_UI_POS" ) then
		EquipEducation_Temper_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipEducation_Temper_Frame_On_ResetPos()
	elseif (event == "RESUME_ENCHASE_GEM_EX") then
		EquipEducation_Temper_Clear()
	elseif (event == "EQUIP_TEMPER_SENDMSG") then
		g_EquipEducation_Temper_Confirm = 1;
	elseif (event == "EQUIP_TEMPER_QUERENSENDMSG") then
		g_EquipEducation_Temper_QueRenConfirm = 1;
	end
end

--=========================================================
-- 更新基本显示信息
-- 在这里计算金钱并显示
--=========================================================
function EquipEducation_Temper_UpdateBasic()
	 EquipEducation_Temper_HaveGoldNum:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	 EquipEducation_Temper_HaveNum:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
end

--=========================================================
-- 重置界面
--=========================================================
function EquipEducation_Temper_Clear()
	if g_EquipEducation_Temper_Item ~= -1 then
		EquipEducation_Temper_InputIcon:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(g_EquipEducation_Temper_Item, 0)
		g_EquipEducation_Temper_Item = -1
	end

	g_EquipEducation_Temper_HaveGoldNum = 0
	for i=1,3 do
		g_ETemper_Attr[i]:SetText("")
		g_LockState[i].State = 0;
		g_LockState[i].Button:SetProperty("Selected", "False");
		--g_LockState[i].Button:SetProperty("Disabled", "True");
	end
	--g_QuerenLockState[1].Button:SetCheck(0)
	--g_QuerenLockState[1].State = 0
	g_IsHaveAttaPro = 0	
	EquipEducation_Temper_NeedItem:SetText("");	
	EquipEducation_Temper_WantNum:SetProperty("MoneyNumber", 0)
	EquipEducation_Temper_OK:SetProperty("Disabled", "True")
	
	g_EquipEducation_Temper_Confirm = -1
	g_EquipEducation_Temper_QueRenConfirm = -1
	g_EquipEducation_Temper_QueRenConfirmState = 0
	-- EquipEducation_Temper_NumericalValue:SetProperty("DefaultEditBox", "True")
	-- EquipEducation_Temper_NumericalValue:SetSelected(0, -1)
end

--=========================================================
-- 更新界面
--=========================================================
function EquipEducation_Temper_Update(itemIndex)
	local index = tonumber(itemIndex)
	local theAction = EnumAction(index, "packageitem")

	if theAction:GetID() ~= 0 then


		-- 如果空格内已经有对应物品了, 替换之
		if g_EquipEducation_Temper_Item ~= -1 and index ~= g_EquipEducation_Temper_Item then
			EquipEducation_Temper_Clear()
		end

		EquipEducation_Temper_InputIcon:SetActionItem(theAction:GetID())
		LifeAbility:Lock_Packet_Item(index, 1)
		g_EquipEducation_Temper_Item = index
		
		for i = 0, 2 do
			local pName, pLevel, pBValue, pPercent, pRValue = theAction:GetEquipAttaProperty(i);
			if(pLevel == nil or pLevel <= 0) then
				g_ETemper_Attr[i+1]:SetText("#{ZBSX_130625_14}")
			else
				--local perStr = ScriptGlobal_Format("#{ZBSX_130625_15}", pPercent, pRValue)
				local perStr = ScriptGlobal_Format("#{ZBSX_130625_127}", pLevel, pRValue,pBValue,pPercent)
				local szStr = "#cfff263#{"..pName.."}"..perStr;
				g_ETemper_Attr[i+1]:SetText(szStr)
				g_IsHaveAttaPro = 1
			end
		end
		
		g_EquipEducation_Temper_IsBind = GetItemBindStatus(g_EquipEducation_Temper_Item)	--获取绑定状态
		local LockedNum = 0
		for i=1,3 do
			if( g_LockState[i].Button:GetCheck() == 1) then
				LockedNum = LockedNum+1;
			end
		end	
		local itemneed,cost = DataPool:GetEquipChangerate(LockedNum);
		local  strInfo = ScriptGlobal_Format("#{ZBSX_130625_20}",itemneed,PlayerPackage:GetItemName(g_ItemNeed))
		EquipEducation_Temper_NeedItem:SetText(strInfo);
		EquipEducation_Temper_WantNum:SetProperty("MoneyNumber", cost)
		EquipEducation_Temper_OK:SetProperty("Disabled", "False")
		g_EquipEducation_Temper_Confirm = -1
		g_EquipEducation_Temper_QueRenConfirm = -1
		-- 设定 OK 为总是可以点击, 这样方便检验
		-- 判断物品是否满足要求来设定功能button
		-- EquipEducation_Temper_Check_AllItem()
	else
		EquipEducation_Temper_Clear()
	end
end
--=========================================================
-- 检查是否有两条相同的属性，并且未上锁
-- 返回相同属性数量数目，未上锁数目,属性名
--=========================================================
function EquipEducation_Temper_CheckSameProp()
	local AllProp = {}
	if(nil == g_EquipEducation_Temper_Item or -1 == g_EquipEducation_Temper_Item) then
		return -1
	end
	local theAction = EnumAction(g_EquipEducation_Temper_Item, "packageitem")
	for i = 0, 2 do
		local pName, pLevel, pBValue, pPercent, pRValue = theAction:GetEquipAttaProperty(i)
		if(pLevel ~= nil and pLevel > 0) then
			AllProp[i] = {name = pName,level = pLevel,bvalue = pBValue,percent = pPercent,rvalue = pRValue}
		end
	end
	for i = 0,2 do
		local nCount = 0
		local nSameCount = 1
		local ProName = ""
		for j = i + 1,2 do
			if(AllProp[i] ~= nil and AllProp[j] ~= nil) then
				if( AllProp[i].name == AllProp[j].name )then
					ProName = "#{"..AllProp[i].name.."}"
					nSameCount = nSameCount + 1
					if(g_LockState[j + 1].Button:GetCheck() ~= 1) then
						nCount = nCount + 1
					end
					--return nCount,"#{"..AllProp[i].name.."}"
				end
			end
		end
		if((nSameCount ~= 1) and (g_LockState[i + 1].Button:GetCheck() ~=1)) then
			nCount = nCount + 1
		end
		if(nCount ~= 0) then
			return nSameCount,nCount,ProName
		end
	end
	return 0,0,""
end


--=========================================================
-- 取出窗口内放入的物品
--=========================================================
function EquipEducation_Temper_Resume_Equip()
	if this:IsVisible() then
		if g_EquipEducation_Temper_Item ~= -1 then
			LifeAbility:Lock_Packet_Item(g_EquipEducation_Temper_Item, 0)
			EquipEducation_Temper_InputIcon:SetActionItem(-1)
			g_EquipEducation_Temper_Item = -1
		end
	end
end

--=========================================================
-- 判断是否所有物品都已放好
-- 只在点击 OK 按钮的时候调用这个函数
--=========================================================
function EquipEducation_Temper_Check_AllItem()
	EquipEducation_Temper_UpdateBasic()

	if g_EquipEducation_Temper_Item == -1 then
		g_EquipEducation_Temper_HaveGoldNum = 0
		EquipEducation_Temper_HaveGoldNum:SetProperty("MoneyNumber", tostring(g_EquipEducation_Temper_HaveGoldNum))
		return 1
	end

	-- 判断装备是否能够强化(没有蚀刻雕纹或者强化到顶级了返回 < 0)
	local ret = LifeAbility:CanEquipDiaowen_Enchase(g_EquipEducation_Temper_Item)
	if ret == -1 or ret == -2 then
		return 2
	end
	if ret < 0 then
		return 3
	end

	-- 判断金蚕丝数量, 输入的金蚕丝数量
	-- 在 Server 判断

	-- 判断金钱是否足够
	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if selfMoney < g_EquipEducation_Temper_HaveGoldNum then
		return 44
	end

	EquipEducation_Temper_OK:Enable()
	return 0
end


local EB_FREE_BIND = 0;				-- 无绑定限制
local EB_BINDED = 1;				-- 已经绑定
local EB_GETUP_BIND =2			-- 拾取绑定
local EB_EQUIP_BIND =3			-- 装备绑定
--=========================================================
-- 确定执行功能
--=========================================================
function EquipEducation_Temper_OK_Clicked()
	local curTime = OSAPI:GetTickCount()
	--确认框没有返回的时候点击无效
	if g_EquipEducation_Temper_QueRenConfirmState ~= 0 and curTime - g_EquipEducation_Temper_QueRenConfirmState < 1000 then
		return
	end
	local lockstr = {}
	for i = 1,3 do
		if(g_LockState[i].Button:GetCheck() == 1) then
			lockstr[i] =1 
		else
			lockstr[i] =0 
		end		
	end
	
	local LockedNum = 0
	for i=1,3 do
		if( g_LockState[i].Button:GetCheck() == 1) then
			LockedNum = LockedNum+1;
		end
	end
	local itemneed,cost = DataPool:GetEquipChangerate(LockedNum);
	if PlayerPackage:CountAvailableItemByIDTable(g_EquipEducation_Temper_binditem) + PlayerPackage:CountAvailableItemByIDTable(g_EquipEducation_Temper_unbinditem) < itemneed then
		local Str = ScriptGlobal_Format("#{ZBSX_130625_91}", PlayerPackage:GetItemName(g_EquipEducation_Temper_binditem), PlayerPackage:GetItemName(g_EquipEducation_Temper_binditem))
		PushDebugMessage(Str)
		return
	end
	if g_QuerenLockState[1].State == 1 then
		local nSameCount,nCount,PropName = EquipEducation_Temper_CheckSameProp()
		if(nCount ~= 0 and g_EquipEducation_Temper_QueRenConfirm ~= 1) then --勾选淬炼确认
			PushEvent("EQUIP_TEMPER_QUERENCONFIRM",PropName,nCount,nSameCount)
			return
		end
	end
	if PlayerPackage:CountAvailableItemByIDTable(g_EquipEducation_Temper_binditem) > 0 then  --绑定的道具自己就够了
		if(PlayerPackage:GetItemBindStatusByIndex(g_EquipEducation_Temper_Item) == 1 ) then	--如果装备也是绑定的就不用提示了
			
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("EquipCuiLian");
				Set_XSCRIPT_ScriptID(890088);
				Set_XSCRIPT_Parameter(0,g_EquipEducation_Temper_Item);
				Set_XSCRIPT_Parameter(1,lockstr[1])
				Set_XSCRIPT_Parameter(2,lockstr[2])
				Set_XSCRIPT_Parameter(3,lockstr[3])
				Set_XSCRIPT_ParamCount(4);
				g_EquipEducation_Temper_QueRenConfirmState = OSAPI:GetTickCount()
			Send_XSCRIPT();	
		elseif g_EquipEducation_Temper_Confirm == 1 or PlayerPackage:IsChongLouItem(g_EquipEducation_Temper_Item) == 1 then
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("EquipCuiLian");
				Set_XSCRIPT_ScriptID(890088);
				Set_XSCRIPT_Parameter(0,g_EquipEducation_Temper_Item);
				Set_XSCRIPT_Parameter(1,lockstr[1])
				Set_XSCRIPT_Parameter(2,lockstr[2])
				Set_XSCRIPT_Parameter(3,lockstr[3])
				Set_XSCRIPT_ParamCount(4);
				g_EquipEducation_Temper_QueRenConfirmState = OSAPI:GetTickCount()
			Send_XSCRIPT();			
		else
			--悲剧开始，弹出提示
			PushEvent("EQUIP_TEMPER_CONFIRM");
		end
	else			--全部是非绑定的材料直接用
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("EquipCuiLian");
				Set_XSCRIPT_ScriptID(890088);
				Set_XSCRIPT_Parameter(0,g_EquipEducation_Temper_Item);
				Set_XSCRIPT_Parameter(1,lockstr[1])
				Set_XSCRIPT_Parameter(2,lockstr[2])
				Set_XSCRIPT_Parameter(3,lockstr[3])
				Set_XSCRIPT_ParamCount(4);
				g_EquipEducation_Temper_QueRenConfirmState = OSAPI:GetTickCount()
			Send_XSCRIPT();			
	end
	
	-- Clear_XSCRIPT();
		-- Set_XSCRIPT_Function_Name("EquipCuiLian");
		-- Set_XSCRIPT_ScriptID(890088);
		-- Set_XSCRIPT_Parameter(0,g_EquipEducation_Temper_Item);
		-- Set_XSCRIPT_Parameter(1,lockstr[1])
		-- Set_XSCRIPT_Parameter(2,lockstr[2])
		-- Set_XSCRIPT_Parameter(3,lockstr[3])
		-- Set_XSCRIPT_ParamCount(4);
	-- Send_XSCRIPT();

end
--=========================================================
-- 关闭界面
--=========================================================
function EquipEducation_Temper_Close()
	this:Hide()
	g_EquipEducation_Temper_QueRenConfirm = -1
	return
end

--=========================================================
-- 界面隐藏
--=========================================================
function EquipEducation_Temper_OnHiden()
	StopCareObject_EquipEducation_Temper()
	EquipEducation_Temper_Clear()
	this:Hide()
	return
end

--=========================================================
-- 开始关心NPC，
-- 在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
-- 如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_EquipEducation_Temper()

	this:CareObject(g_CaredNpc, 1, "EquipEducation_Temper")
	return
end

--=========================================================
-- 停止对某NPC的关心
--=========================================================
function StopCareObject_EquipEducation_Temper()
	this:CareObject(g_CaredNpc, 0, "EquipEducation_Temper")
	g_CaredNpc = -1
	return
end

--=========================================================
-- 玩家金钱变化
--=========================================================
function EquipEducation_Temper_UserMoneyChanged()
	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	-- 判断金钱够不够
	if selfMoney < g_EquipEducation_Temper_HaveGoldNum then
		--EquipEducation_Temper_OK:Disable()
		return -1
	end
	return 1
end

function EquipEducation_Temper_Frame_On_ResetPos()
  EquipEducation_Temper_Frame:SetProperty("UnifiedPosition", g_EquipEducation_Temper_Frame_UnifiedPosition);
end

function EquipEducation_Temper_Lock_Attr(index)
	if(EquipEducation_Temper_InputIcon:GetActionItem() == -1) then

		g_LockState[index].Button:SetCheck(0);
	else
		if(g_IsHaveAttaPro == 0) then
			PushDebugMessage("#{ZBSX_130625_17}");
			g_LockState[index].Button:SetCheck(0);
		else
			local LockedNum = 0
			for i=1,3 do
				if( g_LockState[i].Button:GetCheck() == 1) then
					LockedNum = LockedNum+1;
				end
			end
			if(LockedNum == 3) then
				PushDebugMessage("#{ZBSX_130625_18}");
				g_LockState[index].Button:SetCheck(0);	
			else
				g_LockState[index].State = 1;
				local itemneed,cost = DataPool:GetEquipChangerate(LockedNum);
				local  strInfo = ScriptGlobal_Format("#{ZBSX_130625_20}",itemneed,PlayerPackage:GetItemName(g_ItemNeed))
				EquipEducation_Temper_NeedItem:SetText(strInfo);
				EquipEducation_Temper_WantNum:SetProperty("MoneyNumber", cost)
			end
		end
	end
	

end

function EquipEducation_Temper_AttrQueRenButton()
	if(0 == g_QuerenLockState[1].State) then
		g_QuerenLockState[1].Button:SetCheck(1)
		g_QuerenLockState[1].State = 1
	else
		g_QuerenLockState[1].Button:SetCheck(0)
		g_QuerenLockState[1].State = 0
	end
end