--六博装备升级界面脚本
local g_objCared = -1
local MAX_OBJ_DISTANCE = 3.0
local g_uiEquipPos = -1
local g_LastEquip = -1

function Songliao_EquipUp_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("PROGRESSBAR_SHOW")
	this:RegisterEvent("OPEN_STALL_SALE")
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("UPDATE_LIUBOEQUIP_LEVELUP")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)--这个为了把物品从UI上拖下来：CUISystem::OnDragEnd
end

function Songliao_EquipUp_OnLoad()
	g_objCared = -1
	g_uiEquipPos = -1
	g_LastEquip = -1
end


function Songliao_EquipUp_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0)==5020232) then
		this:Show()
		Songliao_EquipUp_Clear()
		g_objCared = -1
		local param = Get_XParam_INT(0)
		g_objCared = DataPool : GetNPCIDByServerID(param)
		if g_objCared == -1 then				
				return;
		end
		
		--关心NPC
		Songliao_EquipUp_BeginCareNPC(g_objCared)
		return
	elseif (event == "MONEY_CHANGE_EX") then
		Songliao_EquipUp_SelfMoney:SetProperty("MoneyNumber",  tostring(Player:GetData("MONEY")))
		return
		
	elseif (event == "MONEYJZ_CHANGE_EX") then
		Songliao_EquipUp_SelfJiaozi:SetProperty("MoneyNumber",  tostring(Player:GetData("MONEY_JZ")))		
		return
		
	elseif(event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= g_objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			Songliao_EquipUp_Close()
		end
		return
	elseif(event == "UPDATE_LIUBOEQUIP_LEVELUP") then
		Songliao_EquipUp_Update(tonumber(arg0), tonumber(arg1))
		return 
	elseif(event == "RESUME_ENCHASE_GEM_EX") then
		if(arg0~=nil and tonumber(arg0) == 31) then
			Songliao_EquipUp_Resume(tonumber(arg0))
		end
		return
	end
end

function Songliao_EquipUp_BeginCareNPC(npcId)
	g_objCared = npcId
	this:CareObject(npcId, 1, "Songliao_EquipUp")
end


function Songliao_EquipUp_Cancel_Clicked()
	Songliao_EquipUp_Clear()
	this:Hide()
end

function Songliao_EquipUp_OK_Clicked()
	if(g_uiEquipPos ==-1) then
		PushDebugMessage("#{SLDZ_100805_96}")
		return
	end
	
	if PlayerPackage:Lua_GetBagEquipNeedLevel(g_uiEquipPos) == 90 then
		PushDebugMessage("#{LBYH_170213_01}")
		return
	end
	
	local notify = 0
	if g_LastEquip ~= g_uiEquipPos then
		g_LastEquip = g_uiEquipPos
		notify = 1
	end

	if notify == 1 then
		DressEnchasing:Dress_EnchaseShowInfo("SLDZ_100805_219")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnLiuboEquipLevelup")
		Set_XSCRIPT_ScriptID(502024)
		Set_XSCRIPT_Parameter(0,g_uiEquipPos)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
		
	Songliao_EquipUp_Clear()
end

function Songliao_EquipUp_Close()
	Songliao_EquipUp_Clear()
	this:CareObject(g_objCared, 0, "Songliao_EquipUp")
	g_objCared = -1
	this:Hide()
end

function Songliao_EquipUp_Update(uiIndex, ItemPos)
	local theActionItem = EnumAction(ItemPos, "packageitem")
	local needMoney = 0
	local isLiuboEquip = 0
	
	local itemIndex = PlayerPackage : GetItemTableIndex( ItemPos )
	isLiuboEquip, needMoney, materialNum1 = CSongliaoWarData:GetLiuboEquipInfo(itemIndex)
	if isLiuboEquip~=nil and isLiuboEquip==1 and needMoney~=nil then
		if g_uiEquipPos~=-1 then
			--将原来的物品解锁
			LifeAbility : Lock_Packet_Item(g_uiEquipPos,0);
		end
		g_uiEquipPos = ItemPos
		LifeAbility : Lock_Packet_Item(ItemPos,1)
		Songliao_EquipUp_Object1:SetActionItem(theActionItem:GetID())
		Songliao_EquipUp_OK:Enable()
		Songliao_EquipUp_NeedMoney:SetProperty("MoneyNumber", needMoney)
		
		local equipevel = math.mod(math.floor(itemIndex/100),10)
		if(equipevel < 9) then
			local msg = "#{SLDZ_100805_95}".. tostring(materialNum1) .. "#{SLDZ_100805_177}"
			Songliao_EquipUp_Text2:SetText(msg)
		else
			Songliao_EquipUp_Text2:SetText("#{SLDZ_100805_181}")
		end
	else
		PushDebugMessage("#{SLDZ_100805_97}")
	end
end


function Songliao_EquipUp_Clear()
	if g_uiEquipPos~=-1 then
		--将原来的物品解锁
		LifeAbility : Lock_Packet_Item(g_uiEquipPos,0);
		g_uiEquipPos = -1
	end
	Songliao_EquipUp_Object1:SetActionItem(-1)
	Songliao_EquipUp_OK:Disable()
	Songliao_EquipUp_NeedMoney:SetProperty("MoneyNumber", 0)
	Songliao_EquipUp_Text2:SetText("")
	g_LastEquip = -1
end

function Songliao_EquipUp_Resume(index)
	if index ~= 31 then
		return
	end
	
	if this:IsVisible() then
		if g_uiEquipPos~=-1 then
			Songliao_EquipUp_Clear()
		end
	end
end

function Songliao_EquipUp_OnShown()
	Songliao_EquipUp_Clear()
	Songliao_EquipUp_SelfMoney:SetProperty("MoneyNumber",  tostring(Player:GetData("MONEY")))
	Songliao_EquipUp_SelfJiaozi:SetProperty("MoneyNumber",  tostring(Player:GetData("MONEY_JZ")))		
end
