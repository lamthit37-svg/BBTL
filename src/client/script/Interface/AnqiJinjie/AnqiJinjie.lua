--暗器金翅翎羽进阶界面逻辑（客户端）
local MAX_OBJ_DISTANCE = 3.0
local objCared = -1
local g_Object = -1
local g_CommandType = 1
local g_Dark_Bag_Index = -1
local g_Mainitem = 10155002
local g_ToLingYuCost = 4000000
local g_ServerTargetID = -1

function AnqiJinjie_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("UPDATE_ANQIJINJIE")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function AnqiJinjie_OnLoad()
end

function AnqiJinjie_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 800034) then
		
		if this:IsVisible() then									-- 如果界面开着，则不处理
			AnqiJinjie_Close()
		end

		objCared = -1;
		g_ServerTargetID= Get_XParam_INT(1);
		objCared = DataPool : GetNPCIDByServerID(g_ServerTargetID);

		if objCared == -1 then
			PushDebugMessage("异常数据，请稍后再试！")
			return
		end
		
		AnqiJinjie_BeginCareObject(objCared)

		g_CommandType = Get_XParam_INT(0)
		if g_CommandType == 10 then
			AnqiJinjie_InitDlg()
		end
	elseif (event == "UPDATE_ANQIJINJIE" and this:IsVisible()) then
		if arg0~= nil then
			AnqiJinjie_Update(arg0)
		end
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end

		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			AnqiJinjie_Close()
		end
	elseif( (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and this:IsVisible()) then
		AnqiJinjie_UpdateMoneyDisp()
	elseif(event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible())then
		if(tonumber(arg0) == 173) then
			AnqiJinjie_Resume()
		end
	elseif(event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil then
			if (g_Dark_Bag_Index == tonumber(arg0)) then
				AnqiJinjie_Resume()	
			end
		end
	end
end

function AnqiJinjie_UpdateMoneyDisp()
	if g_Dark_Bag_Index ~= -1 then
		local playerMoney = Player:GetData("MONEY");
		local playerMoneyJZ = Player:GetData("MONEY_JZ");
		AnqiJinjie_NeedMoney:SetProperty("MoneyNumber", g_ToLingYuCost);
		AnqiJinjie_SelfJiaozi:SetProperty("MoneyNumber", playerMoneyJZ);
		AnqiJinjie_SelfMoney:SetProperty("MoneyNumber", playerMoney);
	end
end

function AnqiJinjie_InitDlg()
	--重洗暗器技能
	AnqiJinjie_Reset()
	AnqiJinjie_Info:SetText("#{AQJJ_160127_11}")
	AnqiJinjie_Text:SetText("#{AQJJ_160127_12}")
	AnqiJinjie_NeedMoney:SetProperty("MoneyNumber", 0)
	AnqiJinjie_SelfJiaozi:SetProperty("MoneyNumber", 0)
	AnqiJinjie_SelfMoney:SetProperty("MoneyNumber", 0)
	this:Show()
end

--确认进阶按钮回调
function AnqiJinjie_OK_Clicked() 

	--请先放入暗器。
	if (g_Dark_Bag_Index == -1) then
		PushDebugMessage("#{CXYH_140813_16}")
		return
	end

	local EquipPoint = LifeAbility : Get_Equip_Point(g_Dark_Bag_Index)
	if (EquipPoint ~= 17) then
		PushDebugMessage("#{FBSJ_081209_37}")
		return
	end
	
	--暗器进阶
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("Shenzhen2LingyuConfim")
		Set_XSCRIPT_ScriptID(260001)
		Set_XSCRIPT_Parameter(0,g_Dark_Bag_Index)
		Set_XSCRIPT_Parameter(1,g_ServerTargetID)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--取消按钮回调
function AnqiJinjie_Cancel_Clicked()
	AnqiJinjie_Close()
end

--关闭界面按钮回调
function AnqiJinjie_CloseUI_Clicked()
	AnqiJinjie_Close()
end

--界面Hide回调
function AnqiJinjie_Clear()
	AnqiJinjie_Reset()
	AnqiJinjie_StopCareObject()
end

function AnqiJinjie_Update(Item_index)
	local i_index = tonumber(Item_index)
	local theAction = EnumAction(i_index, "packageitem");

	if theAction:GetID() ~= 0 then
		if PlayerPackage : GetItemTableIndex( i_index ) ~= g_Mainitem then
			PushDebugMessage("#{AQJJ_160127_15}")
			return
		end
		
		local darkLv = PlayerPackage : GetBagItemDarkLevel(i_index)
		if darkLv < 90 then
			PushDebugMessage("#{AQJJ_160127_15}")
			return
		end
		
		if i_index == g_Dark_Bag_Index then
			return
		end

		--界面清空
		AnqiJinjie_Reset()
		--设置ActionItem
		AnqiJinjie_Item:SetActionItem(theAction:GetID());
		g_Dark_Bag_Index = i_index
		LifeAbility : Lock_Packet_Item(i_index,1)
		AnqiJinjie_OK:Enable()
		AnqiJinjie_UpdateMoneyDisp()
	end

end

function AnqiJinjie_Reset()
	AnqiJinjie_Item:SetActionItem(-1);
	LifeAbility : Lock_Packet_Item(g_Dark_Bag_Index,0);
	g_Dark_Bag_Index = -1
	AnqiJinjie_OK:Disable()
end

function AnqiJinjie_Close()
	AnqiJinjie_Reset()
	AnqiJinjie_StopCareObject()
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function AnqiJinjie_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "AnqiJinjie");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "AnqiJinjie")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function AnqiJinjie_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "AnqiJinjie");
		g_Object = -1;
	end
end

function AnqiJinjie_Resume()
	AnqiJinjie_Reset()
	AnqiJinjie_NeedMoney:SetProperty("MoneyNumber", 0)
	AnqiJinjie_SelfJiaozi:SetProperty("MoneyNumber", 0)
	AnqiJinjie_SelfMoney:SetProperty("MoneyNumber", 0)			
end
