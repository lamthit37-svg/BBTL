
local MAX_OBJ_DISTANCE = 3.0
local g_CaredNpc = -1
local g_DWHECHENG_Item = -1
local g_DWHECHENG_DemandMoney = 50000
local g_DWHECHENG_GRID_SKIP = 95

local g_DWHECHENG_Action_Type = 4
local g_DWHECHENG_RScript_ID = 809272
local g_DWHECHENG_RSCript_Name = "DoDiaowenAction"

local g_DWHecheng_Frame_UnifiedPosition;
local g_DWHecheng_Confirmed = 0

--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function DWHecheng_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_DWHECHENG")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)

	this:RegisterEvent("CONFIRM_DWHECHENG")
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--=========================================================
-- 载入初始化
--=========================================================
function DWHecheng_OnLoad()
	g_DWHECHENG_Item = -1
	g_DWHECHENG_DemandMoney = 50000
	g_DWHecheng_Confirmed = 0
	DWHecheng_OK:Enable()
	
	g_DWHecheng_Frame_UnifiedPosition=DWHecheng_Frame:GetProperty("UnifiedPosition");
end

--=========================================================
-- 事件处理
--=========================================================
function DWHecheng_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 1000156) then
		local xx = Get_XParam_INT(0)
		g_CaredNpc = DataPool:GetNPCIDByServerID(xx)
		if g_CaredNpc == -1 then
			PushDebugMessage("server传过来的数据有问题。")
			return
		end
		BeginCareObject_DWHecheng()
		DWHecheng_Clear()
		DWHecheng_UpdateBasic()
		this:Show()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if (tonumber(arg0) ~= g_CaredNpc) then
			return
		end
		if ((arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE) or arg1=="destroy") then
			DWHecheng_Close()
		end
	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if (arg0~= nil and -1 == tonumber(arg0)) then
			return
		end
		if (g_DWHECHENG_Item == tonumber(arg0)) then
			DWHecheng_Resume_Equip()
		end
	elseif (event == "UPDATE_DWHECHENG") then
		if arg0 ~= nil then
			DWHecheng_Update(arg0)
		end
		DWHecheng_UpdateBasic()
	elseif (event == "MONEY_CHANGE_EX" or event =="MONEYJZ_CHANGE_EX") then
		DWHecheng_UpdateBasic()
	elseif (event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == (g_DWHECHENG_GRID_SKIP + 1) then
			DWHecheng_Resume_Equip()
			DWHecheng_UpdateBasic()
		end
	elseif (event == "CONFIRM_DWHECHENG") then
		g_DWHecheng_Confirmed = 1
	
	elseif (event == "ADJEST_UI_POS" ) then
		DWHecheng_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DWHecheng_Frame_On_ResetPos()
	end
end

--=========================================================
-- 更新基本显示信息
--=========================================================
function DWHecheng_UpdateBasic()
	DWHecheng_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	DWHecheng_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))

	-- 计算所需金钱
	if g_DWHECHENG_Item == -1 then
		g_DWHECHENG_DemandMoney = 0
		DWHecheng_Cailiao_des:SetText("#{CZDYH_161128_15}")
	else
		local ret1, ret2 = PlayerPackage:GetDiaowenHechengMat(g_DWHECHENG_Item)
		if ret1 < 0 or ret2 < 0 then
			DWHecheng_Cailiao_des:SetText("#{CZDYH_161128_15}")
		end
		if ret2 == 0 then
			DWHecheng_Cailiao_des:SetText(ScriptGlobal_Format("#{CZDYH_161128_16}",ret1))
		else
			DWHecheng_Cailiao_des:SetText(ScriptGlobal_Format("#{CZDYH_161128_17}",ret1, ret2))
		end
		g_DWHECHENG_DemandMoney = 50000
	end
	DWHecheng_DemandMoney:SetProperty("MoneyNumber", tostring(g_DWHECHENG_DemandMoney))

	DWHecheng_OK:Enable()
end

--=========================================================
-- 重置界面
--=========================================================
function DWHecheng_Clear()
	if g_DWHECHENG_Item ~= -1 then
		DWHecheng_Object:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(g_DWHECHENG_Item, 0)
		g_DWHECHENG_Item = -1
	end

	g_DWHECHENG_DemandMoney = 50000
	g_DWHecheng_Confirmed = 0
	DWHecheng_UpdateBasic()
end

--=========================================================
-- 更新界面
--=========================================================
function DWHecheng_Update(itemIndex)
	local index = tonumber(itemIndex)
	local theAction = EnumAction(index, "packageitem")

	if theAction:GetID() ~= 0 then
		-- 判断是否为安全时间
		if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
			PushDebugMessage("#{JJTZ_090826_26}")
			return
		end

		-- 判断物品是否为雕纹图样
		if LifeAbility:IsDiaowenPic(index) == -1 then
			PushDebugMessage("#{ZBDW_091105_2}")
			return
		end

		-- 判断物品是否加锁(在这个逻辑之前程序已经判断了)
		if PlayerPackage:IsLock(index) == 1 then
			PushDebugMessage("#{ZBDW_091105_3}")
			return
		end
		
		-- 如果空格内已经有图样了, 替换之
		if g_DWHECHENG_Item ~= -1 then
			LifeAbility:Lock_Packet_Item(g_DWHECHENG_Item, 0)
		end
		DWHecheng_Object:SetActionItem(theAction:GetID())
		LifeAbility:Lock_Packet_Item(index, 1)
		g_DWHECHENG_Item = index

	else
		DWHecheng_Clear()
	end
end

--=========================================================
-- 取出窗口内放入的物品
--=========================================================
function DWHecheng_Resume_Equip()
	if this:IsVisible() then
		DWHecheng_Clear()
	end
end

--=========================================================
-- 判断是否所有物品都已放好
-- 只在点击 OK 按钮的时候调用这个函数
--=========================================================
function DWHecheng_Check_AllItem()
	DWHecheng_UpdateBasic()

	if g_DWHECHENG_Item == -1 then
		return 1
	end

	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if selfMoney < g_DWHECHENG_DemandMoney then
		return 44
	end

	return 0
end


local EB_FREE_BIND = 0;				-- 无绑定限制
local EB_BINDED = 1;				-- 已经绑定
local EB_GETUP_BIND =2			-- 拾取绑定
local EB_EQUIP_BIND =3			-- 装备绑定
--=========================================================
-- 确定执行功能
--=========================================================
function DWHecheng_OK_Clicked()
	local ret = DWHecheng_Check_AllItem()
	if ret == 1 then
		PushDebugMessage("#{ZBDW_091105_2}")
	elseif ret == 44 then
		PushDebugMessage("#{GMGameInterface_Script_PlayerMySelf_Info_Money_Not_Enough}")
	end

	if ret == 0 then
		-- 检查绑定情况
		local picBindState = PlayerPackage:GetItemBindStatusByIndex(g_DWHECHENG_Item)
		local isNeedConfirm = 0
		-- 得到玩家背包里的材料信息
		local matInfo = PlayerPackage:CheckDiaowenHechengMat(g_DWHECHENG_Item)
		--PushDebugMessage(picBindState)
		if picBindState ~= EB_BINDED then
			-- 根据雕纹图样, 判断玩家背包里是否存在可能用到的绑定的合成材料
			if matInfo == -2 then
				isNeedConfirm = 1
			end
		else
			isNeedConfirm = 1
		end

		-- 如果没有绑定的合成材料和合成符, 材料足够直接合成
		-- 如果是玩家点击了绑定提示信息的确认按钮, 直接合成
		if (isNeedConfirm ~= 1 and matInfo == 1) or (g_DWHecheng_Confirmed == 1) then
			-- 执行雕纹合成功能
			
			g_DWHecheng_Confirmed = 0
			
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name(g_DWHECHENG_RSCript_Name)
				Set_XSCRIPT_ScriptID(g_DWHECHENG_RScript_ID)
				Set_XSCRIPT_Parameter(0, g_DWHECHENG_Action_Type)
				Set_XSCRIPT_Parameter(1, g_DWHECHENG_Item)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		elseif g_DWHecheng_Confirmed == 0 then
			if matInfo == -1 then
				-- 如果材料不够, 提示信息
				PushDebugMessage("#{ZBDW_091105_4}")
			elseif matInfo == -3 then
				--丹青数量不够，元宝购买确认
				if DWHecheng_Blank_Queren:GetCheck() == 0 then
				--不提示 自动购买
				Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name("DWHechengBeginPay")
					Set_XSCRIPT_ScriptID(g_DWHECHENG_RScript_ID)
					Set_XSCRIPT_Parameter(0,g_DWHECHENG_Item)
					Set_XSCRIPT_Parameter(1,0)
					Set_XSCRIPT_ParamCount(2)
				Send_XSCRIPT()
			elseif DWHecheng_Blank_Queren:GetCheck() == 1 then
				Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name("DWHechengBeginPay")
					Set_XSCRIPT_ScriptID(g_DWHECHENG_RScript_ID)
					Set_XSCRIPT_Parameter(0,g_DWHECHENG_Item)
					Set_XSCRIPT_Parameter(1,1)
					Set_XSCRIPT_ParamCount(2)
				Send_XSCRIPT()
			end
		elseif isNeedConfirm == 1 then
				-- 如果材料足够, 但是有绑定材料, 显示确认窗口
				if LifeAbility:ConfirmDiaowenHecheng(0) < 0 then
					-- 出错了? 诡异事件, 暂时不予理会呃....
				end
			end
		end
	end
end

function DWHecheng_Blank_Queren_Clicked()
	if(NpcShop:GetDWHechengDirectly() == 0)then
		DWHecheng_Blank_Queren:SetCheck(0);
		NpcShop:SetDWHechengDirectly(1);
	else
		DWHecheng_Blank_Queren:SetCheck(1);
		NpcShop:SetDWHechengDirectly(0);
	end
end
--=========================================================
-- 关闭界面
--=========================================================
function DWHecheng_Close()
	this:Hide()
	return
end

--=========================================================
-- 界面隐藏
--=========================================================
function DWHecheng_OnHiden()
	StopCareObject_DWHecheng()
	DWHecheng_Clear()
	return
end

--=========================================================
-- 开始关心NPC，
-- 在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
-- 如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_DWHecheng()

	this:CareObject(g_CaredNpc, 1, "DWHecheng")
	return
end

--=========================================================
-- 停止对某NPC的关心
--=========================================================
function StopCareObject_DWHecheng()
	this:CareObject(g_CaredNpc, 0, "DWHecheng")
	g_CaredNpc = -1
	return
end

--=========================================================
-- 玩家金钱变化
--=========================================================
function DWHecheng_UserMoneyChanged()
	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	-- 判断金钱够不够
	if selfMoney < g_DWHECHENG_DemandMoney then
		return -1
	end
	return 1
end

function DWHecheng_Frame_On_ResetPos()
  DWHecheng_Frame:SetProperty("UnifiedPosition", g_DWHecheng_Frame_UnifiedPosition);
end
