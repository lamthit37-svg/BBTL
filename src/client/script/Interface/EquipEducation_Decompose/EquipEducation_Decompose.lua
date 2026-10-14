
local g_EquipEducation_Decompose_Frame_UnifiedPosition =nil;
local g_EquipEducation_Decompose_NPCID = -1;
local g_EquipEducation_Decompose_objCared = -1;
local g_EquipEducation_Decompose_OBJDISTANCE =3.0;
local g_EquipEducation_Decompose_ActionButton;
local g_EquipEducation_Decompose_ItemPos = -1;
local g_EquipEducation_Decompose_Confirm = -1;

local g_Decompose_ItemX = 20700063
local g_Decompose_ITemA = 20700057
local g_Decompose_ItemB = 20700059
local g_Decompose_ITemC = 20700061


function EquipEducation_Decompose_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("SHOUGONG_ATTRATTA")
	this:RegisterEvent("EQUIP_DECOMPOSE_SENDMSG")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	
end


function EquipEducation_Decompose_OnLoad()
	g_EquipEducation_Decompose_ActionButton = EquipEducation_Decompose_InputIcon;
	g_EquipEducation_Decompose_Frame_UnifiedPosition = EquipEducation_Decompose_Frame:GetProperty("UnifiedPosition")
end


function EquipEducation_Decompose_OnEvent(event)
	if(event == "UI_COMMAND") and (tonumber(arg0) == 20130522) then
		g_EquipEducation_Decompose_NPCID = Get_XParam_INT(0);
		g_EquipEducation_Decompose_objCared = DataPool:GetNPCIDByServerID(g_EquipEducation_Decompose_NPCID);
		EquipEducation_Decompose_BeginCareObject(g_EquipEducation_Decompose_objCared)
		EquipEducation_Decompose_InitData()
		this:Show();
	elseif (event == "ADJEST_UI_POS") then
		EquipEducation_Decompose_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipEducation_Decompose_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCaredId) then
			return;
		end
		
		if(arg1 == "distance" and tonumber(arg2) > g_EquipEducation_Decompose_OBJDISTANCE or arg1=="destroy" ) then
			EquipEducation_Decompose_OnHiden()
		end
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		EquipEducation_Decompose_HaveNum:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		EquipEducation_Decompose_HaveGoldNum:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif ( event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		EquipEducation_Decompose_HaveGoldNum:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		EquipEducation_Decompose_HaveNum:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	elseif ( event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		EquipEducation_Decompose_HaveNum:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		EquipEducation_Decompose_HaveGoldNum:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif (event == "SHOUGONG_ATTRATTA") and this:IsVisible() then
		if arg0 ~= nil then
			EquipEducation_Decompose_SetData(tonumber(arg0))
		end
	elseif (event == "EQUIP_DECOMPOSE_SENDMSG") then
		g_EquipEducation_Decompose_Confirm = 1;
	elseif (event == "RESUME_ENCHASE_GEM_EX") then
		EquipEducation_Decompose_DataClean()
		--EquipEducation_Decompose_SendMsg()
	end
end

function EquipEducation_Decompose_SetData(pos)
	if(g_EquipEducation_Decompose_ItemPos >= 0 ) then  --如果已经有数据了
	
		EquipEducation_Decompose_DataClean()	
	end
	local pos_packet = tonumber(pos)
	local theAction = EnumAction(pos_packet, "packageitem")
	local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)
	g_EquipEducation_Decompose_ActionButton:SetActionItem(theAction:GetID())
	LifeAbility:Lock_Packet_Item(pos_packet,1);
	g_EquipEducation_Decompose_ItemPos = pos_packet;	
	local const, XItemNum, AItemNum, BItemNum, CItemNum = theAction:GetEquipDecompose()
	--PushDebugMessage("AItemNum="..AItemNum..",BItemNum="..BItemNum..",CItemNum"..CItemNum)
	local str = ""
	if( math.floor(AItemNum/10000) > 0 ) then	
		str = ScriptGlobal_Format("#{ZBSX_130625_20}", XItemNum,PlayerPackage:GetItemName(tonumber(20700063)))
	elseif( math.floor(BItemNum/10000) > 0 ) then
		str = ScriptGlobal_Format("#{ZBSX_130625_20}", XItemNum,PlayerPackage:GetItemName(tonumber(20700063)))
	elseif( math.floor(CItemNum/10000) > 0 ) then
		str = ScriptGlobal_Format("#{ZBSX_130625_20}", XItemNum,PlayerPackage:GetItemName(tonumber(20700063)))
	else	
		str = ScriptGlobal_Format("#{ZBSX_130625_20}", XItemNum,PlayerPackage:GetItemName(tonumber(20700063)))
	end
	--PushDebugMessage("str="..str)
	EquipEducation_Decompose_WantNum:SetProperty("MoneyNumber", tostring(const));
	EquipEducation_Decompose_OutputItem:SetText(str)
	EquipEducation_Decompose_OK:SetProperty("Disabled", "False");

end

function EquipEducation_Decompose_OnHiden()
	EquipEducation_Decompose_DataClean()
	this:Hide()
end

function EquipEducation_Decompose_DataClean()
	if(this:IsVisible()) then
		if(g_EquipEducation_Decompose_ItemPos ~= -1) then
			LifeAbility : Lock_Packet_Item(g_EquipEducation_Decompose_ItemPos,0)
			g_EquipEducation_Decompose_ItemPos = -1
		end

	end
	g_EquipEducation_Decompose_ActionButton:SetActionItem(-1)
	EquipEducation_Decompose_OK:SetProperty("Disabled", "True");
	g_EquipEducation_Decompose_Confirm = -1;
	EquipEducation_Decompose_WantNum:SetProperty("MoneyNumber", 0);
	EquipEducation_Decompose_OutputItem:SetText("");
	
end

function EquipEducation_Decompose_ResetPos()
	EquipEducation_Decompose_Frame:SetProperty("UnifiedPosition",g_EquipEducation_Decompose_Frame_UnifiedPosition)
end

function EquipEducation_Decompose_BeginCareObject(objCaredId)
	g_Object = objCaredId;
	this:CareObject(g_Object, 1, "EquipEducation_Decompose");
end

function EquipEducation_Decompose_InitData()
	EquipEducation_Decompose_OutputItem:SetText("");
	EquipEducation_Decompose_HaveNum:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	EquipEducation_Decompose_HaveGoldNum:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	EquipEducation_Decompose_OK:SetProperty("Disabled", "True");
	g_EquipEducation_Decompose_Confirm = -1
end

function EquipEducation_Decompose_Buttons_Clicked()

	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZBSX_130625_62}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end		
	
	--判断是否有物品放进来
	if g_EquipEducation_Decompose_ItemPos < 0 then
		PushDebugMessage("#{ZBSX_130625_65}")
		return
	end
	
	if PlayerPackage:IsLock(g_EquipEducation_Decompose_ItemPos) == 1 then
		PushDebugMessage("#{ZBSX_130625_61}")
		return
	end
	
	
	local theAction = EnumAction(g_EquipEducation_Decompose_ItemPos, "packageitem")
	local const = theAction:GetEquipDecompose()
	if const > tonumber(Player:GetData("MONEY")+tonumber(Player:GetData("MONEY_JZ"))) then
		PushDebugMessage("#{ZBSX_130625_76}")
		return
	end
	
	
	
	if theAction:EquipCanDecompose() == 1 then		--里面检测了其他判断条件
			local equiplock = PlayerPackage:IsEquipLocked(g_EquipEducation_Decompose_ItemPos);
			local GetStrengthenLevel = PlayerPackage:GetStrengthenLevel(g_EquipEducation_Decompose_ItemPos);
			local IsHaveAttaProperty = PlayerPackage:IsHaveAttaProperty(g_EquipEducation_Decompose_ItemPos);
			local zzType = PlayerPackage:Lua_GetBagEquipHandMakeType(g_EquipEducation_Decompose_ItemPos)
			local zzLevel = PlayerPackage:Lua_GetBagEquipHandMakeLevel(g_EquipEducation_Decompose_ItemPos)
			local bHaveSL = 0
			
			if zzLevel > 0 or zzType > 0 then
				bHaveSL = 1
			end
			
			if g_EquipEducation_Decompose_Confirm == 1 then
				EquipEducation_Decompose_SendMsg();
			elseif( tonumber(equiplock) <= 0 and tonumber(GetStrengthenLevel) <= 0 and tonumber(IsHaveAttaProperty) <= 0 and tonumber(bHaveSL) <= 0)  then
				EquipEducation_Decompose_SendMsg();
			else
				--PushDebugMessage("equiplock="..equiplock..",GetStrengthenLevel="..GetStrengthenLevel..",IsHaveAttaProperty="..IsHaveAttaProperty)
				PushEvent("EQUIP_DECOMPOSE_CONFIRM", tonumber(equiplock), tonumber(GetStrengthenLevel), tonumber(IsHaveAttaProperty),tonumber(bHaveSL));
			end
	end
end




function EquipEducation_Decompose_SendMsg()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("EquipTojingshi");
		Set_XSCRIPT_ScriptID(890088);
		Set_XSCRIPT_Parameter(0,g_EquipEducation_Decompose_ItemPos);		
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
	
	EquipEducation_Decompose_DataClean()  
	--EquipEducation_Decompose_OnHiden()
end
--右键点击
function EquipEducation_Decompose_CleanData()
	EquipEducation_Decompose_DataClean()
end