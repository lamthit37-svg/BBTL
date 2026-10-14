local g_CurSelInfantIndex= 0
local g_MaxInfantCount = 1
local g_targetId = -1

local g_CardCompose_Frame_UnifiedXPosition;
local g_CardCompose_Frame_UnifiedYPosition;

local g_SrcCard = -1
local g_DestCard = -1

local g_SrcBagIndex = -1
local g_DestBagIndex = -1

local g_NotifyBind = 1

local g_MoneyCost = 10000

local g_SuccRate = {
	[1] = 65,
	[2] = 45,
	[3] = 35,
	[4] = 100,
}

function CardCompose_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	this:RegisterEvent("UPDATE_INFANT_CARD_COMPOSE");
	this:RegisterEvent("INFANT_CARD_COMPOSE_CONFIRM")
	this:RegisterEvent("INFANT_CARD_COMPOSE_CONFIRM_OK")
	-- this:RegisterEvent("TOGGLE_UPDATE_INFANT");
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function CardCompose_OnLoad()
	-- 保存界面的默认相对位置
	g_CardCompose_Frame_UnifiedXPosition	= CardCompose_Frame:GetProperty("UnifiedXPosition");
	g_CardCompose_Frame_UnifiedYPosition	= CardCompose_Frame:GetProperty("UnifiedYPosition");
	g_SrcCard = CardCompose_Object1
	g_DestCard = CardCompose_Object2
end

function CardCompose_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 2013111801 then
		local xx = Get_XParam_INT(0);
		g_targetId = DataPool : GetNPCIDByServerID(xx);
		if g_targetId == -1 then
			return
		end
		CardCompose_BeginCareObject()
		CardCompose_UpdateInfo(-1, -1)
		this:Show()
	elseif (event=="UPDATE_INFANT_CARD_COMPOSE") then

		if (tonumber(arg1) ~= 0) then
			local srcQual = -1
			local destQual = -1
			if (tonumber(arg1)) == 1 then
				srcQual = PlayerPackage:GetInfantCard_Qual(tonumber(arg0))
				destQual = PlayerPackage:GetInfantCard_Qual(g_DestBagIndex)
			elseif (tonumber(arg1)) == 2 then
				srcQual = PlayerPackage:GetInfantCard_Qual(g_SrcBagIndex)
				destQual = PlayerPackage:GetInfantCard_Qual(tonumber(arg0))
			end
			if srcQual ~= -1 and destQual ~= -1 and srcQual ~= destQual then
				PushDebugMessage("#{KPWFS_131112_15}")
				return
			end

			--物品是否已经加锁
			if PlayerPackage:IsLock(tonumber(arg0)) == 1 then
				PushDebugMessage("#{KPWFS_131112_16}")
				return
			end

			--有研读等级的卡牌无法合成
			local enhanceLevel = PlayerPackage:GetInfantCard_EnhanceLevel(tonumber(arg0))
			if enhanceLevel >=1 then
				PushDebugMessage("#{KPWFS_131112_17}")
				PushDebugMessage("#{KPWFS_131112_18}")
				return
			end
			CardCompose_UpdateInfo(tonumber(arg0), tonumber(arg1))
		else  --右键点击的情况
			local srcQual = -1
			local destQual = -1
			if g_SrcBagIndex == -1 then --进入左侧
				if g_DestBagIndex ~= -1 then
					srcQual = PlayerPackage:GetInfantCard_Qual(tonumber(arg0))
					destQual = PlayerPackage:GetInfantCard_Qual(g_DestBagIndex)
					if srcQual ~= destQual then
						PushDebugMessage("#{KPWFS_131112_15}")
						return 
					end
				end
			else --进入右侧
				srcQual = PlayerPackage:GetInfantCard_Qual(g_SrcBagIndex)
				destQual = PlayerPackage:GetInfantCard_Qual(tonumber(arg0))
				if srcQual ~= destQual then
					PushDebugMessage("#{KPWFS_131112_15}")
					return 
				end
			end

			--物品是否已经加锁
			if PlayerPackage:IsLock(tonumber(arg0)) == 1 then
				PushDebugMessage("#{KPWFS_131112_16}")
				return
			end

			--有研读等级的卡牌无法合成
			local enhanceLevel = PlayerPackage:GetInfantCard_EnhanceLevel(tonumber(arg0))
			if enhanceLevel >=1 then
				PushDebugMessage("#{KPWFS_131112_17}")
				PushDebugMessage("#{KPWFS_131112_18}")
				return
			end

			if g_SrcBagIndex == -1 then --进入左侧
				CardCompose_UpdateInfo(tonumber(arg0), 1)
			else --进入右侧
				if g_DestBagIndex ~= -1 then
					LifeAbility:Lock_Packet_Item(g_DestBagIndex, 0)
				end
				CardCompose_UpdateInfo(tonumber(arg0), 2)
			end
		end
	elseif (event == "INFANT_CARD_COMPOSE_CONFIRM_OK") and this:IsVisible() then
		g_NotifyBind = 0
	-- elseif (event=="TOGGLE_UPDATE_INFANT") then
	-- 	CardCompose_UpdateInfo();
	elseif (event=="PACKAGE_ITEM_CHANGED_EX") and this:IsVisible() then
		if not arg0 or tonumber( arg0 ) == -1 then
			return
		end
		if g_SrcBagIndex == tonumber(arg0) then
			CardCompose_Resume_Gem(21)
		end
		if g_DestBagIndex == tonumber(arg0) then
			CardCompose_Resume_Gem(22)
		end
	elseif (event == "RESUME_ENCHASE_GEM_EX") then
		if arg0 then
			if tonumber(arg0) == 21 then
				CardCompose_Resume_Gem( 21 )
			elseif tonumber(arg0) == 22 then
				CardCompose_Resume_Gem( 22 )
			end
			
		end
	elseif (event=="MONEY_CHANGE_EX") then
		CardCompose_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif (event=="MONEYJZ_CHANGE_EX") then
		CardCompose_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	elseif( event == "ADJEST_UI_POS" ) then
		CardCompose_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		CardCompose_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		CardCompose_OnHiden()
	end
end
--bagIndex为背包中的索引号，type 1为左侧卡牌 2为右侧卡牌
function CardCompose_UpdateInfo(bagIndex, type)
	g_NotifyBind = 1

	g_SrcCard:SetActionItem(-1)
	g_DestCard:SetActionItem(-1)
		
	if bagIndex ~= -1 or type ~= -1 then
		if type == 1 then
			LifeAbility : Lock_Packet_Item( g_SrcBagIndex, 0 )
			g_SrcBagIndex = bagIndex
		elseif type == 2 then
			LifeAbility : Lock_Packet_Item( g_DestBagIndex, 0 )
			g_DestBagIndex = bagIndex
		end
	end
	if g_SrcBagIndex == -1 or g_DestBagIndex == -1 then

		CardCompose_Info1:SetText("#{KPWFS_131112_11}")
		CardCompose_Money:SetProperty("MoneyNumber", tostring(0));
	else
		local qual = PlayerPackage:GetInfantCard_Qual(g_SrcBagIndex)
		CardCompose_Info1:SetText("#G成功率："..g_SuccRate[qual+1].."%")
		CardCompose_Money:SetProperty("MoneyNumber", tostring(g_MoneyCost));
	end
	
	local srcCard = -1
	local destCard = -1
	if g_SrcBagIndex ~= -1 then
		srcCard = EnumAction(g_SrcBagIndex, "packageitem")
		g_SrcCard:SetActionItem(srcCard:GetID())
		LifeAbility : Lock_Packet_Item( g_SrcBagIndex, 1 )
	end
	if g_DestBagIndex ~= -1 then
		destCard = EnumAction(g_DestBagIndex, "packageitem")
		g_DestCard:SetActionItem(destCard:GetID())
		LifeAbility : Lock_Packet_Item( g_DestBagIndex, 1 )
	end

	CardCompose_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	CardCompose_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));

	if g_SrcBagIndex == -1 or g_DestBagIndex == -1 then
		CardCompose_OK:Disable()
	else
		CardCompose_OK:Enable()
	end

end

function CardCompose_Buttons_Clicked()

	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
		return
	end
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{KPWFS_131112_20}")
		return
	end
	--是否均已放入卡牌
	if g_SrcBagIndex == -1 or g_DestBagIndex == -1 then
		PushDebugMessage("#{KPWFS_131112_24}")
		return
	end
	-- 品质是否相同
	local srcQual = PlayerPackage:GetInfantCard_Qual(g_SrcBagIndex)
	local destQual = PlayerPackage:GetInfantCard_Qual(g_DestBagIndex)
	if srcQual ~= destQual then
		PushDebugMessage("#{KPWFS_131112_24}")
		return
	end

	--物品是否已经加锁
	if PlayerPackage:IsLock(g_SrcBagIndex) == 1 or PlayerPackage:IsLock(g_DestBagIndex) == 1 then
		PushDebugMessage("#{KPWFS_131112_25}")
		return
	end

	--有研读等级的卡牌无法合成
	local srcEnhanceLevel = PlayerPackage:GetInfantCard_EnhanceLevel(g_SrcBagIndex)
	local destEnhanceLevel = PlayerPackage:GetInfantCard_EnhanceLevel(g_DestBagIndex)

	if srcEnhanceLevel >=1 or destEnhanceLevel >= 1 then
		PushDebugMessage("#{KPWFS_131112_17}")
		PushDebugMessage("#{KPWFS_131112_18}")
		return
	end

	-- 检查身上的金钱是否足够
	local selfMoney = Player : GetData( "MONEY" ) + Player : GetData( "MONEY_JZ" )
	if selfMoney < g_MoneyCost then
		PushDebugMessage("#{KPWFS_131112_26}")
		return
	end

	--绑定判断
	local srcBindStatus = PlayerPackage:GetItemBindStatusByIndex(g_SrcBagIndex)
	local destBindStatus = PlayerPackage:GetItemBindStatusByIndex(g_DestBagIndex)

	if srcBindStatus ~= destBindStatus and g_NotifyBind == 1 then
		PushEvent( "INFANT_CARD_COMPOSE_CONFIRM", g_SrcBagIndex, g_DestBagIndex, g_targetId )	
		--ShowSystemInfo("KPWFS_131112_27")
		return
	end
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("CompositeBooks");
		Set_XSCRIPT_ScriptID(890630);
		Set_XSCRIPT_Parameter(0,g_SrcBagIndex);
		Set_XSCRIPT_Parameter(1,g_DestBagIndex);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end

function CardCompose_Resume_Gem(index)
	if not this : IsVisible() then
		return
	end

	if index == 21 then
		LifeAbility : Lock_Packet_Item( g_SrcBagIndex, 0 )
		g_SrcCard:SetActionItem(-1)
		g_SrcBagIndex = -1
		CardCompose_UpdateInfo(-1, 1)
	elseif index == 22 then
		LifeAbility : Lock_Packet_Item( g_DestBagIndex, 0 )
		g_DestCard:SetActionItem(-1)
		g_DestBagIndex = -1
		CardCompose_UpdateInfo(-1, 2)
	end

	
end

--================================================
-- 界面的默认相对位置
--================================================
function CardCompose_ResetPos()
	CardCompose_Frame:SetProperty("UnifiedXPosition", g_CardCompose_Frame_UnifiedXPosition);
	CardCompose_Frame:SetProperty("UnifiedYPosition", g_CardCompose_Frame_UnifiedYPosition);
end

function CardCompose_OnHiden()
	g_NotifyBind = 1
	CardCompose_StopCareObject()
	LifeAbility : Lock_Packet_Item( g_SrcBagIndex, 0 )
	LifeAbility : Lock_Packet_Item( g_DestBagIndex, 0 )
	g_SrcBagIndex = -1
	g_DestBagIndex = -1
	this:Hide();
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function CardCompose_BeginCareObject()
	this:CareObject(g_targetId, 1, "CardCompose")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function CardCompose_StopCareObject()
	this:CareObject(g_targetId, 0, "CardCompose")
end