local g_CurSelInfantIndex= 0
local g_MaxInfantCount = 1
local g_targetId = -1

local g_BagIndex = -1
local g_Card = -1
local g_MoneyCost =10000

local g_NotifyBind = 1

local g_CardStrengthen_Frame_UnifiedXPosition;
local g_CardStrengthen_Frame_UnifiedYPosition;

local g_Stars

local g_ItemID_1 = 38000807 --绑定
local g_ItemID_2 = 38000808 --非绑定

local g_CardStrengthen_YuanBaoPay = 1

local BaseValueString = {
	[0] = "毒攻击",
	[1] = "玄攻击",
	[2] = "火攻击",
	[3] = "冰攻击",
	[4] = "体力",
	[5] = "身法",
	[6] = "闪避",
	[7] = "会心",
	[8] = "命中",
}

local SteppedUp_Yuanbao = {
	[0] = 39432,
	[1] = 39332,
	[2] = 39166,
	[3] = 38916,
	[4] = 38250,
	[5] = 37000,
	[6] = 35000,
	[7] = 30000,
	[8] = 20000,
}

function CardStrengthen_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	this:RegisterEvent("UPDATE_INFANT_CARD_STRENGTH");
	this:RegisterEvent("INFANT_CARD_STRENGTH_CONFIRM");
	this:RegisterEvent("INFANT_CARD_STRENGTH_CONFIRM_OK");
	-- this:RegisterEvent("TOGGLE_UPDATE_INFANT");
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function CardStrengthen_OnLoad()
	-- 保存界面的默认相对位置
	g_CardStrengthen_Frame_UnifiedXPosition	= CardStrengthen_Frame:GetProperty("UnifiedXPosition");
	g_CardStrengthen_Frame_UnifiedYPosition	= CardStrengthen_Frame:GetProperty("UnifiedYPosition");

	g_Card = CardStrengthen_Object

	g_Stars={
			CardStrengthen_StaticPart_Star1,
			CardStrengthen_StaticPart_Star2,
			CardStrengthen_StaticPart_Star3,
			CardStrengthen_StaticPart_Star4,
			CardStrengthen_StaticPart_Star5,
			CardStrengthen_StaticPart_Star6,
			CardStrengthen_StaticPart_Star7,
			CardStrengthen_StaticPart_Star8,
			CardStrengthen_StaticPart_Star9,
	};
	for i=1,9 do
		g_Stars[i]:Hide();
	end;
	
	g_CardStrengthen_YuanBaoPay = 1;
	CardStrengthen_YuanBaoPay:SetCheck(g_CardStrengthen_YuanBaoPay)
end

function CardStrengthen_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 2013111802 then
		local xx = Get_XParam_INT(0);
		g_targetId = DataPool : GetNPCIDByServerID(xx);
		if g_targetId == -1 then
			return
		end
		CardStrengthen_BeginCareObject()
		CardStrengthen_UpdateInfo(g_BagIndex)
		
		if g_CardStrengthen_YuanBaoPay == 1 or g_CardStrengthen_YuanBaoPay == 0 then
			CardStrengthen_YuanBaoPay:SetCheck(g_CardStrengthen_YuanBaoPay)
		end
		this:Show()
	elseif event == "UPDATE_INFANT_CARD_STRENGTH" and this:IsVisible() then
		local enhancelevel = PlayerPackage:GetInfantCard_EnhanceLevel(tonumber(arg0))
		if enhancelevel >=9 then
			PushDebugMessage("#{KPWFS_131112_45}")
			return
		end

		if g_BagIndex ~= -1 then
			LifeAbility:Lock_Packet_Item(g_BagIndex, 0)
		end

		CardStrengthen_UpdateInfo(tonumber(arg0))
	elseif event == "INFANT_CARD_STRENGTH_CONFIRM_OK" and this:IsVisible() then
		g_NotifyBind = 0; 
	-- elseif (event=="TOGGLE_UPDATE_INFANT") then
	-- 	CardStrengthen_UpdateInfo();
	elseif (event=="PACKAGE_ITEM_CHANGED_EX") then
		if( arg0~= nil and -1 == tonumber(arg0)) then
			return;
		end
		if g_BagIndex == tonumber(arg0) then
			local enhancelevel = PlayerPackage:GetInfantCard_EnhanceLevel(g_BagIndex)
			if enhancelevel >= 9 then
				CardStrengthen_Resume_Gem(21)
			else
				CardStrengthen_UpdateInfo(g_BagIndex)
			end
			
		end
	elseif (event=="RESUME_ENCHASE_GEM_EX") then
		if arg0 then
			if tonumber(arg0) == 31 then
				CardStrengthen_Resume_Gem( 21 )
			end
			
		end
	elseif (event=="MONEY_CHANGE_EX") then
		CardStrengthen_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif (event=="MONEYJZ_CHANGE_EX") then
		CardStrengthen_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	elseif( event == "ADJEST_UI_POS" ) then
		CardStrengthen_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		CardStrengthen_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		CardStrengthen_OnHiden()
	end
end

function CardStrengthen_UpdateInfo(bagIndex)
	g_NotifyBind = 1
	g_Card:SetActionItem(-1)

	g_BagIndex = bagIndex

	if bagIndex == -1 then
		CardStrengthen_Info4:SetText("")
		CardStrengthen_Info6:SetText("#{KPWFS_131112_40}")
		CardStrengthen_Money:SetProperty("MoneyNumber", tostring(0));
		for i=1, 9 do
			g_Stars[i]:SetProperty("Animate", "Animate_Card_DarkStar");
			g_Stars[i]:Show();
		end
	else
		local rate = PlayerPackage:GetInfantCard_SuccRate(g_BagIndex) /10
		--成功率
		CardStrengthen_Info4:SetText(rate.."%")
		local curvalue = PlayerPackage:GetInfantCard_CurValue(g_BagIndex)
		local nextvalue = PlayerPackage:GetInfantCard_NextValue(g_BagIndex)
		local cardtype = PlayerPackage:GetInfatnCard_CardType(g_BagIndex)
		--数值提升
		CardStrengthen_Info6:SetText(BaseValueString[cardtype].."：+"..curvalue.."→".."#H+"..nextvalue)
		--花费金钱
		CardStrengthen_Money:SetProperty("MoneyNumber", tostring(g_MoneyCost));
		--星星
		local enhancelevel = PlayerPackage:GetInfantCard_EnhanceLevel(g_BagIndex)
		for i=1,enhancelevel do
			g_Stars[i]:SetProperty("Animate", "Animate_Card_NoFlashStar");
			g_Stars[i]:Show();
		end
		for i=enhancelevel+1, 9 do
			g_Stars[i]:SetProperty("Animate", "Animate_Card_DarkStar");
			g_Stars[i]:Show();
		end
	end


	local card = -1
	if bagIndex ~= -1 then
		card = EnumAction(bagIndex, "packageitem")
		g_Card:SetActionItem(card:GetID())
		LifeAbility : Lock_Packet_Item( bagIndex, 1 )
	end



	CardStrengthen_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	CardStrengthen_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));

	if g_BagIndex == -1 then
		CardStrengthen_OK:Disable()
		CardStrengthen_SteppedUp:Disable()
		CardStrengthen_SteppedUp_Animate:Play(false)
	else
		CardStrengthen_OK:Enable()
		CardStrengthen_SteppedUp:Enable()
		CardStrengthen_SteppedUp_Animate:Play(true)
	end
end
function CardStrengthen_Resume_Gem( index )
	if not this : IsVisible() then
		return
	end

	if index == 21 then
		LifeAbility : Lock_Packet_Item( g_BagIndex, 0 )
		g_Card:SetActionItem(-1)
		g_BagIndex = -1
	end

	CardStrengthen_UpdateInfo(g_BagIndex)

end

function CardStrengthen_SteppedUp_Clicked()

	if  Player:GetData("LEVEL") < 15 then
		PushDebugMessage("#{ZSJX_140707_04}") --当你的等级达到15级时，才能使用该功能。
		return
	end
	
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
		return
	end
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	
	--格子中是否有物品
	if g_BagIndex == -1 then
		PushDebugMessage("#{ZSJX_140707_05}")
		return
	end
	
		--强化等级是否已满
	local enhancelevel = PlayerPackage:GetInfantCard_EnhanceLevel(g_BagIndex)
	if enhancelevel >= 9 then
		PushDebugMessage("#{KPWFS_131112_45}")
		return
	end
	
	local needyuanbao = SteppedUp_Yuanbao[enhancelevel] 
	PushEvent( "INFANT_CARD_STEPUP_CONFIRM", g_BagIndex, enhancelevel,needyuanbao )	
	
end

function CardStrengthen_Buttons_Clicked()
	--格子中是否有物品
	if g_BagIndex == -1 then
		PushDebugMessage("#{KPWFS_131112_44}")
		return
	end
	--强化等级是否已满
	local enhancelevel = PlayerPackage:GetInfantCard_EnhanceLevel(g_BagIndex)
	if enhancelevel >= 9 then
		PushDebugMessage("#{KPWFS_131112_45}")
		return
	end
	--是否有典籍注解
	--local itemNum = PlayerPackage:CountAvailableItemByIDTable(g_ItemID_1) + PlayerPackage:CountAvailableItemByIDTable(g_ItemID_2)
	--if itemNum <= 0 then
	--	PushDebugMessage("#{KPWFS_131112_46}")
	--	return 
	--end
	-- 检查身上的金钱是否足够
	local selfMoney = Player : GetData( "MONEY" ) + Player : GetData( "MONEY_JZ" )
	if selfMoney < g_MoneyCost then
		PushDebugMessage("#{KPWFS_131112_26}")
		return
	end

	if PlayerPackage:CountAvailableItemByIDTable(g_ItemID_1) >= 1 and PlayerPackage:GetItemBindStatusByIndex(g_BagIndex) ~= 1 
		and g_NotifyBind == 1 then
		PushEvent( "INFANT_CARD_STRENGTH_CONFIRM", g_BagIndex, g_targetId )	
		--ShowSystemInfo("KPWFS_131112_49")
		return
	end
	
	local index, bindState = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(g_ItemID_2))
	if bindState == 1 and PlayerPackage:GetItemBindStatusByIndex(g_BagIndex) ~= 1 
		and g_NotifyBind == 1 then
		PushEvent( "INFANT_CARD_STRENGTH_CONFIRM", g_BagIndex, g_targetId )	
		--ShowSystemInfo("KPWFS_131112_49")
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("StudyBooks");
		Set_XSCRIPT_ScriptID(890630);
		Set_XSCRIPT_Parameter(0,g_BagIndex);
		Set_XSCRIPT_Parameter(1,tonumber(CardStrengthen_YuanBaoPay:GetCheck()));
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end

--================================================
-- 界面的默认相对位置
--================================================
function CardStrengthen_ResetPos()
	CardStrengthen_Frame:SetProperty("UnifiedXPosition", g_CardStrengthen_Frame_UnifiedXPosition);
	CardStrengthen_Frame:SetProperty("UnifiedYPosition", g_CardStrengthen_Frame_UnifiedYPosition);
end

function CardStrengthen_OnHiden()
	g_NotifyBind = 1
	LifeAbility : Lock_Packet_Item( g_BagIndex, 0 )
	for i=1,9 do
		g_Stars[i]:Hide();
	end;
	g_BagIndex = -1
	g_CardStrengthen_YuanBaoPay = CardStrengthen_YuanBaoPay:GetCheck();
	this:Hide();
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function CardStrengthen_BeginCareObject()
	this:CareObject(g_targetId, 1, "CardStrengthen")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function CardStrengthen_StopCareObject()
	this:CareObject(g_targetId, 0, "CardStrengthen")
end