local g_CurSelInfantIndex= 0
local g_MaxInfantCount = 1
local g_targetId = -1

local g_SrcCard = -1
local g_DestCard = -1

local g_SrcBagIndex = -1
local g_DestBagIndex = -1

local g_NotifyBind = 1

local g_MoneyCost = 10000

local g_CardTransfer_Frame_UnifiedXPosition;
local g_CardTransfer_Frame_UnifiedYPosition;

local g_Stars_1
local g_Stars_2

function CardTransfer_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	this:RegisterEvent("UPDATE_INFANT_CARD_TRANSFER");
	this:RegisterEvent("INFANT_CARD_TRANSFER_CONFIRM_OK");
	-- this:RegisterEvent("TOGGLE_UPDATE_INFANT");
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function CardTransfer_OnLoad()
	-- 保存界面的默认相对位置
	g_CardTransfer_Frame_UnifiedXPosition	= CardTransfer_Frame:GetProperty("UnifiedXPosition");
	g_CardTransfer_Frame_UnifiedYPosition	= CardTransfer_Frame:GetProperty("UnifiedYPosition");

	g_SrcCard = CardTransfer_Object1;
	g_DestCard = CardTransfer_Object2;

	g_Stars_1={
			CardTransfer_StaticPart1_Star1,
			CardTransfer_StaticPart1_Star2,
			CardTransfer_StaticPart1_Star3,
			CardTransfer_StaticPart1_Star4,
			CardTransfer_StaticPart1_Star5,
			CardTransfer_StaticPart1_Star6,
			CardTransfer_StaticPart1_Star7,
			CardTransfer_StaticPart1_Star8,
			CardTransfer_StaticPart1_Star9,
	};
	for i=1,9 do
		g_Stars_1[i]:Hide();
	end;

		g_Stars_2={
			CardTransfer_StaticPart2_Star1,
			CardTransfer_StaticPart2_Star2,
			CardTransfer_StaticPart2_Star3,
			CardTransfer_StaticPart2_Star4,
			CardTransfer_StaticPart2_Star5,
			CardTransfer_StaticPart2_Star6,
			CardTransfer_StaticPart2_Star7,
			CardTransfer_StaticPart2_Star8,
			CardTransfer_StaticPart2_Star9,
	};
	for i=1,9 do
		g_Stars_2[i]:Hide();
	end;
end

function CardTransfer_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 2013111803 then
		local xx = Get_XParam_INT(0);
		g_targetId = DataPool : GetNPCIDByServerID(xx);
		if g_targetId == -1 then
			return
		end
		CardTransfer_BeginCareObject()
		CardTransfer_UpdateInfo(-1, -1)
		this:Show()


	-- elseif (event=="TOGGLE_UPDATE_INFANT") then
	-- 	CardTransfer_UpdateInfo();
	elseif (event=="PACKAGE_ITEM_CHANGED_EX") then
		if( arg0~= nil and -1 == tonumber(arg0)) then
			return;
		end
		if g_SrcBagIndex == tonumber(arg0) then
			CardTransfer_Resume_Gem(21)
		end
		if g_DestBagIndex == tonumber(arg0) then
			CardTransfer_Resume_Gem(22)
		end
	elseif (event == "UPDATE_INFANT_CARD_TRANSFER") and this:IsVisible() then
		if (tonumber(arg1) ~= 0) then --拖拽
			if (tonumber(arg1) == 1 ) then--拖拽到左侧
				local srcEnhanceLevel = PlayerPackage:GetInfantCard_EnhanceLevel(tonumber(arg0))
				if srcEnhanceLevel <= 0 then
					PushDebugMessage("#{KPWFS_131112_56}")
					return
				end
				--物品是否已经加锁
				if PlayerPackage:IsLock(tonumber(arg0)) == 1 then
					PushDebugMessage("#{KPWFS_131112_57}")
					return
				end
			elseif (tonumber(arg1) == 2) then
				if g_SrcBagIndex == -1 then
					PushDebugMessage("#{KPWFS_131112_58}")
					return
				end
				local srcEnhanceLevel = PlayerPackage:GetInfantCard_EnhanceLevel(g_SrcBagIndex)
				local destEnhanceLevel = PlayerPackage:GetInfantCard_EnhanceLevel(tonumber(arg0))
				if srcEnhanceLevel <= destEnhanceLevel then
					PushDebugMessage("#{KPWFS_131112_59}")
					return
				end
			end
			CardTransfer_UpdateInfo(tonumber(arg0), tonumber(arg1));
		else--右键点击
			if g_SrcBagIndex == -1 then
				local srcEnhanceLevel = PlayerPackage:GetInfantCard_EnhanceLevel(tonumber(arg0))
				if srcEnhanceLevel <= 0 then
					PushDebugMessage("#{KPWFS_131112_58}")
					return
				end
				--物品是否已经加锁
				if PlayerPackage:IsLock(tonumber(arg0)) == 1 then
					PushDebugMessage("#{KPWFS_131112_57}")
					return
				end
				CardTransfer_UpdateInfo(tonumber(arg0), 1)
			else
				local srcEnhanceLevel = PlayerPackage:GetInfantCard_EnhanceLevel(g_SrcBagIndex)
				local destEnhanceLevel = PlayerPackage:GetInfantCard_EnhanceLevel(tonumber(arg0))
				if srcEnhanceLevel <= destEnhanceLevel then
					PushDebugMessage("#{KPWFS_131112_59}")
					return
				end
				if g_DestBagIndex ~= -1 then
					LifeAbility:Lock_Packet_Item(g_DestBagIndex, 0)
				end
				CardTransfer_UpdateInfo(tonumber(arg0), 2)
			end
		end
	elseif (event == "INFANT_CARD_TRANSFER_CONFIRM_OK") and this:IsVisible() then
		g_NotifyBind = 0;
	elseif (event == "RESUME_ENCHASE_GEM_EX") then
		if arg0 then
			if tonumber(arg0) == 41 then
				CardTransfer_Resume_Gem( 21 )
			elseif tonumber(arg0) == 42 then
				CardTransfer_Resume_Gem( 22 )
			end
		end	
	elseif (event=="MONEY_CHANGE_EX") then
		CardTransfer_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif (event=="MONEYJZ_CHANGE_EX") then
		CardTransfer_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	elseif( event == "ADJEST_UI_POS" ) then
		CardTransfer_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		CardTransfer_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		CardTransfer_OnHiden()
	end
end

function CardTransfer_UpdateInfo(bagIndex, type)
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
		CardTransfer_Money:SetProperty("MoneyNumber", tostring(0));
	else
		CardTransfer_Money:SetProperty("MoneyNumber", tostring(g_MoneyCost));
	end

	local srcCard = -1
	local destCard = -1
	if g_SrcBagIndex ~= -1 then
		srcCard = EnumAction(g_SrcBagIndex, "packageitem")
		g_SrcCard:SetActionItem(srcCard:GetID())
		LifeAbility : Lock_Packet_Item( g_SrcBagIndex, 1 )
		--星星
		local enhancelevel = PlayerPackage:GetInfantCard_EnhanceLevel(g_SrcBagIndex)
		for i=1,enhancelevel do
			g_Stars_1[i]:SetProperty("Animate", "Animate_Card_NoFlashStar");
			g_Stars_1[i]:Show();
		end
		for i=enhancelevel+1, 9 do
			g_Stars_1[i]:SetProperty("Animate", "Animate_Card_DarkStar");
			g_Stars_1[i]:Show();
		end
	else
		for i=1, 9 do
			g_Stars_1[i]:SetProperty("Animate", "Animate_Card_DarkStar");
			g_Stars_1[i]:Show();
		end
	end
	if g_DestBagIndex ~= -1 then
		destCard = EnumAction(g_DestBagIndex, "packageitem")
		g_DestCard:SetActionItem(destCard:GetID())
		LifeAbility : Lock_Packet_Item( g_DestBagIndex, 1 )
		--星星
		local enhancelevel = PlayerPackage:GetInfantCard_EnhanceLevel(g_DestBagIndex)
		for i=1,enhancelevel do
			g_Stars_2[i]:SetProperty("Animate", "Animate_Card_NoFlashStar");
			g_Stars_2[i]:Show();
		end
		for i=enhancelevel+1, 9 do
			g_Stars_2[i]:SetProperty("Animate", "Animate_Card_DarkStar");
			g_Stars_2[i]:Show();
		end
	else
		for i=1, 9 do
			g_Stars_2[i]:SetProperty("Animate", "Animate_Card_DarkStar");
			g_Stars_2[i]:Show();
		end		
	end

	CardTransfer_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	CardTransfer_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));

	if g_SrcBagIndex == -1 or g_DestBagIndex == -1 then
		CardTransfer_OK:Disable()
	else
		CardTransfer_OK:Enable()
	end
end

function CardTransfer_Buttons_Clicked()
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
		return
	end
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{KPWFS_131112_61}")
		return
	end
	--左侧是否已放入卡牌
	if g_SrcBagIndex == -1 then
		PushDebugMessage("#{KPWFS_131112_58}")
		return
	end
	--是否有研读等级
	local srcEnhanceLevel = PlayerPackage:GetInfantCard_EnhanceLevel(g_SrcBagIndex)
	if srcEnhanceLevel <= 0 then
		PushDebugMessage("#{KPWFS_131112_65}")
		return
	end

	--物品是否已经加锁
	if PlayerPackage:IsLock(g_SrcBagIndex) == 1 then 
		PushDebugMessage("#{KPWFS_131112_66}")
		return
	end

	--右侧是否已放入卡牌
	if g_DestBagIndex == -1 then
		PushDebugMessage("#{KPWFS_131112_67}")
		return
	end
	--是否有研读等级
	local destEnhanceLevel = PlayerPackage:GetInfantCard_EnhanceLevel(g_DestBagIndex)
	if destEnhanceLevel >= srcEnhanceLevel then
		PushDebugMessage("#{KPWFS_131112_68}")
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
	if srcBindStatus == 1 and destBindStatus ~= 1 and g_NotifyBind == 1 then
		PushEvent( "INFANT_CARD_TRANSFER_CONFIRM", g_SrcBagIndex, g_DestBagIndex, g_targetId )	
		-- ShowSystemInfo("KPWFS_131112_70")
		return
	end
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("TransYandu");
		Set_XSCRIPT_ScriptID(890630);
		Set_XSCRIPT_Parameter(0,g_SrcBagIndex);	
		Set_XSCRIPT_Parameter(1,g_DestBagIndex);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end

function CardTransfer_Resume_Gem( index )
	if not this : IsVisible() then
		return
	end

	if index == 21 then
		LifeAbility : Lock_Packet_Item( g_SrcBagIndex, 0 )
		g_SrcCard:SetActionItem(-1)
		g_SrcBagIndex = -1
		CardTransfer_UpdateInfo(-1, 1)
	elseif index == 22 then
		LifeAbility : Lock_Packet_Item( g_DestBagIndex, 0 )
		g_DestCard:SetActionItem(-1)
		g_DestBagIndex = -1
		CardTransfer_UpdateInfo(-1, 2)
	end

	
end
--================================================
-- 界面的默认相对位置
--================================================
function CardTransfer_ResetPos()
	CardTransfer_Frame:SetProperty("UnifiedXPosition", g_CardTransfer_Frame_UnifiedXPosition);
	CardTransfer_Frame:SetProperty("UnifiedYPosition", g_CardTransfer_Frame_UnifiedYPosition);
end

function CardTransfer_OnHiden()
	g_NotifyBind = 1
	ICardTransfer_StopCareObject()
	LifeAbility : Lock_Packet_Item( g_SrcBagIndex, 0 )
	LifeAbility : Lock_Packet_Item( g_DestBagIndex, 0 )
	g_SrcBagIndex = -1
	g_DestBagIndex = -1
	for i=1,9 do
		g_Stars_1[i]:Hide();
	end
	for i=1,9 do
		g_Stars_2[i]:Hide();
	end;
	this:Hide();
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function CardTransfer_BeginCareObject()
	this:CareObject(g_targetId, 1, "CardTransfer")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function ICardTransfer_StopCareObject()
	this:CareObject(g_targetId, 0, "CardTransfer")
end