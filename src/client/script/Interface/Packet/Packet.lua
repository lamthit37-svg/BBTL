local nTheTabIndex = 0;
local PACKAGE_BUTTONS_NUM = 60;
local PACKAGE_BUTTONS = {};
local PACKAGE_BUTTON_BACK={};
local PACKAGE_EXTBAG_NUM = 10;
local PACKAGE_EXTBAG = {};
local PACKAGE_TAB = {};
local PACKAGE_TAB_TEXT = {};
local PACKAGE_NUM_PER_LINE = 10;
local Lock_Flag = 0;
local g_MaxLine = 0;
local g_PackageHeight={};
g_PackageHeight["title"] = { 0, 25, };
g_PackageHeight["page"]  = { 25, 20, };
g_PackageHeight["bag"]	 = { 42, 36, };
g_PackageHeight["money"] = { 0, 50,};

-- 背包界面的默认位置
local g_Packet_Frame_UnifiedXPosition;
local g_Packet_Frame_UnifiedYPosition;

local g_NeedTipItem = -1
local g_NeedTipID = -1
local g_NeedTipText = -1
local g_NeedTipMission = -1

local g_ShopGuidePos = -1

local g_TabIndexBeforeHide = 0
local g_TemBankState = -1

function Packet_PreLoad()
	this:RegisterEvent("TOGLE_CONTAINER", true);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false);
	this:RegisterEvent("MONEY_CHANGE_EX", false);
	this:RegisterEvent("OPEN_EXCHANGE_FRAME", true);
	this:RegisterEvent("TOGLE_BANK", true);
	this:RegisterEvent("TOGLE_BIGBANK", true);
	this:RegisterEvent("OPEN_BOOTH", true);
	this:RegisterEvent("LOCK_WORK_Item", false);
	this:RegisterEvent("REPLY_MISSION", true);
	this:RegisterEvent("CLOSE_MISSION_REPLY", false);
	this:RegisterEvent("OPEN_STALL_SALE", true);
	this:RegisterEvent("OPEN_ITEM_COFFER", true);
	this:RegisterEvent("PS_OPEN_MY_SHOP", true);
	this:RegisterEvent("RESET_EXT_BAG",true);
	this:RegisterEvent("UPDATE_YUANBAO",false);
	this:RegisterEvent("UPDATE_BIND_YUANBAO", false);
	this:RegisterEvent("UPDATE_GIFTTOKEN", false);
	this:RegisterEvent("UPDATE_ZENGDIAN",false);
	this:RegisterEvent("CITY_SHOW_SHOP", true);

	-- 开始整理和结束整理
	this:RegisterEvent("BEGIN_PACKUP_PACKET", false);
	this:RegisterEvent("END_PACKUP_PACKET", false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	this:RegisterEvent("OPEN_RECYCLESHOP_BUYER",true);
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false);
	this:RegisterEvent("OPEN_WINDOW", true)

	-- 注册等级
	this:RegisterEvent("UNIT_LEVEL", false)

	-- 激活界面事件
	this:RegisterEvent("UI_COMMAND", true)

	this:RegisterEvent("OPEN_UP_ITEM", true)

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("YIGUI_OPEN", true)
	this:RegisterEvent("FASHION_DEPOT_OP", true)
	--更新装备
	this:RegisterEvent("REFRESH_EQUIP1", true);
	this:RegisterEvent("NOTIFY_POP_UITIP", false);
	this:RegisterEvent("UPDATE_LIJIN", false);
	this:RegisterEvent("CLOSE_TEMBANK",true)
	this:RegisterEvent("OPEN_TEMBANK",false)
end

function Packet_OnLoad()
	PACKAGE_BUTTONS =	{	
		Packet_Space_Line1_Row1_button,Packet_Space_Line1_Row2_button,Packet_Space_Line1_Row3_button,Packet_Space_Line1_Row4_button,Packet_Space_Line1_Row5_button,
		Packet_Space_Line1_Row6_button,Packet_Space_Line1_Row7_button,Packet_Space_Line1_Row8_button,Packet_Space_Line1_Row9_button,Packet_Space_Line1_Row10_button,
		Packet_Space_Line2_Row1_button,Packet_Space_Line2_Row2_button,Packet_Space_Line2_Row3_button,Packet_Space_Line2_Row4_button,Packet_Space_Line2_Row5_button,
		Packet_Space_Line2_Row6_button,Packet_Space_Line2_Row7_button,Packet_Space_Line2_Row8_button,Packet_Space_Line2_Row9_button,Packet_Space_Line2_Row10_button,
		Packet_Space_Line3_Row1_button,Packet_Space_Line3_Row2_button,Packet_Space_Line3_Row3_button,Packet_Space_Line3_Row4_button,Packet_Space_Line3_Row5_button,
		Packet_Space_Line3_Row6_button,Packet_Space_Line3_Row7_button,Packet_Space_Line3_Row8_button,Packet_Space_Line3_Row9_button,Packet_Space_Line3_Row10_button,
		Packet_Space_Line4_Row1_button,Packet_Space_Line4_Row2_button,Packet_Space_Line4_Row3_button,Packet_Space_Line4_Row4_button,Packet_Space_Line4_Row5_button,
		Packet_Space_Line4_Row6_button,Packet_Space_Line4_Row7_button,Packet_Space_Line4_Row8_button,Packet_Space_Line4_Row9_button,Packet_Space_Line4_Row10_button,
		Packet_Space_Line5_Row1_button,Packet_Space_Line5_Row2_button,Packet_Space_Line5_Row3_button,Packet_Space_Line5_Row4_button,Packet_Space_Line5_Row5_button,
		Packet_Space_Line5_Row6_button,Packet_Space_Line5_Row7_button,Packet_Space_Line5_Row8_button,Packet_Space_Line5_Row9_button,Packet_Space_Line5_Row10_button,
		Packet_Space_Line6_Row1_button,Packet_Space_Line6_Row2_button,Packet_Space_Line6_Row3_button,Packet_Space_Line6_Row4_button,Packet_Space_Line6_Row5_button,
		Packet_Space_Line6_Row6_button,Packet_Space_Line6_Row7_button,Packet_Space_Line6_Row8_button,Packet_Space_Line6_Row9_button,Packet_Space_Line6_Row10_button,
		Packet_Space_Line7_Row1_button,Packet_Space_Line7_Row2_button,Packet_Space_Line7_Row3_button,Packet_Space_Line7_Row4_button,Packet_Space_Line7_Row5_button,
		Packet_Space_Line7_Row6_button,Packet_Space_Line7_Row7_button,Packet_Space_Line7_Row8_button,Packet_Space_Line7_Row9_button,Packet_Space_Line7_Row10_button,
		Packet_Space_Line8_Row1_button,Packet_Space_Line8_Row2_button,Packet_Space_Line8_Row3_button,Packet_Space_Line8_Row4_button,Packet_Space_Line8_Row5_button,
		Packet_Space_Line8_Row6_button,Packet_Space_Line8_Row7_button,Packet_Space_Line8_Row8_button,Packet_Space_Line8_Row9_button,Packet_Space_Line8_Row10_button,
		Packet_Space_Line9_Row1_button,Packet_Space_Line9_Row2_button,Packet_Space_Line9_Row3_button,Packet_Space_Line9_Row4_button,Packet_Space_Line9_Row5_button,
		Packet_Space_Line9_Row6_button,Packet_Space_Line9_Row7_button,Packet_Space_Line9_Row8_button,Packet_Space_Line9_Row9_button,Packet_Space_Line9_Row10_button,
		Packet_Space_Line10_Row1_button,Packet_Space_Line10_Row2_button,Packet_Space_Line10_Row3_button,Packet_Space_Line10_Row4_button,Packet_Space_Line10_Row5_button,
		Packet_Space_Line10_Row6_button,Packet_Space_Line10_Row7_button,Packet_Space_Line10_Row8_button,Packet_Space_Line10_Row9_button,Packet_Space_Line10_Row10_button,
						};

	PACKAGE_EXTBAG  = {
						Packet_Space_Line1;
						Packet_Space_Line2;
						Packet_Space_Line3;
						Packet_Space_Line4;
						Packet_Space_Line5;
						Packet_Space_Line6;
						Packet_Space_Line7;
						Packet_Space_Line8;
						Packet_Space_Line9;
						Packet_Space_Line10;
						}

	PACKAGE_TAB_TEXT = {
		[0] = "道具",
		"材料",
		"任务",
	};

	PACKAGE_TAB = {
		[0] = Packet_Material,
		[1] = Packet_Stall,
		[2] = Packet_Mission,
		};

	Packet_Pet:Enable();

	--Packet_Lock:Disable();

	-- 保存背包界面的默认相对位置
	g_Packet_Frame_UnifiedXPosition	= Packet_Frame:GetProperty("UnifiedXPosition");
	g_Packet_Frame_UnifiedYPosition	= Packet_Frame:GetProperty("UnifiedYPosition");
	g_TemBankState = -1
end

function Packet_Open()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	Packet_ResetExtBag();
	this:Show();
	NotifyPacketStatus(1)
	--背包界面与真元转换界面互斥
	CloseWindow("ZhenYuanConvert",true)
	if(IsWindowShow("Packet_Temporary")) then
		Packet_SetPacketTempory_BtnState(1)
	else
		Packet_SetPacketTempory_BtnState(0)
	end
end

function Packet_CloseFunction()
	g_TabIndexBeforeHide = nTheTabIndex
	nTheTabIndex = 0;
	PACKAGE_TAB[nTheTabIndex]:SetCheck(1);

	--关闭界面时，向Server请求背包同步
	--AskMyBagList函数本身有计时控制
	DataPool:AskMyBagList();
	NotifyPacketStatus(0)

	if "Packet" == GetFreshManGuideOwner() then
        	CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
    	end

	local nProcess = DataPool:GetCurrentFreshManGuideItemValue()
	if nProcess > 0 then
		--NotifyPopUITip("MissionTrack", 1, 9)	--	初涉江湖引导
		DataPool:SetCurrentFreshManGuideItemValue(0)
	end
	--关闭临时背包
	CloseWindow("Packet_Temporary",true)
	g_TemBankState = -1
end

function Packet_OnMoved()
    if "Packet" == GetFreshManGuideOwner() then --当引导ui指向本界面,才需要响应
        OpenFreshManGuide(2, -1, -1, -1)
    end
  local UnifiedXPosition=Packet_Frame:GetProperty("UnifiedXPosition");
  local UnifiedYPosition=Packet_Frame:GetProperty("UnifiedYPosition");
  Variable:SetVariable("PacketUnionXPos", UnifiedXPosition, 1);
  Variable:SetVariable("PacketUnionYPos", UnifiedYPosition, 1);
--	PushDebugMessage("move UnifiedXPosition="..UnifiedXPosition)
end

function Packet_OnEvent( event )
	if ( event == "TOGLE_CONTAINER" ) then
		if( this:IsVisible() ) then
	        this:Hide()
		else
			nTheTabIndex = g_TabIndexBeforeHide
			PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
			Packet_Open();
		end
	elseif ( event == "PS_OPEN_MY_SHOP" )  then
		Packet_Open();
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		Packet_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		Packet_ChangeTabIndex(nTheTabIndex);
	elseif ( event == "OPEN_EXCHANGE_FRAME" ) then
		Packet_Open();
	elseif ( event == "TOGLE_BANK" ) then
		Packet_Open();
	elseif ( event == "TOGLE_BIGBANK" ) then
		Packet_Open();
	elseif ( event == "OPEN_BOOTH" ) then
		Packet_Open();
	elseif ( event == "OPEN_WINDOW" ) then
		if( arg0 == "Packet") then
			Packet_Open();
		end
	--锁定正在操作的背包中的物品
	elseif ( event == "LOCK_PACKET_ITEM" ) then

	elseif ( event == "REPLY_MISSION" ) then
		Packet_Open();
	elseif ( event == "CLOSE_MISSION_REPLY" ) then
			this:Hide()
	elseif ( event == "OPEN_ITEM_COFFER" ) then

	elseif ( event == "OPEN_STALL_SALE" )  then
		Packet_Open();
	elseif ( event == "CITY_SHOW_SHOP" and arg0 == "open") then
		Packet_Open();
	elseif ( event == "RESET_EXT_BAG" ) then
		Packet_ResetExtBag();
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		Packet_YuanBao2:SetText("元宝："..tostring(Player:GetData("YUANBAO")));
	elseif (event == "UPDATE_BIND_YUANBAO" and this:IsVisible()) then
		Packet_BangdingYuanbao:SetText("#{BDYB_090714_01}"..tostring(Player:GetData("BIND_YUANBAO")));
	elseif (event == "UPDATE_GIFTTOKEN" and this:IsVisible()) then
		Packet_Fanquan:SetText("#{YBFQ_XML_1}"..tostring(Player:GetData("GIFTTOKEN")));
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		Packet_Jiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	elseif (event == "UPDATE_ZENGDIAN" and this:IsVisible()) then
		Packet_YuanBao:SetText("赠点："..tostring(Player:GetData("ZENGDIAN")));
	elseif (event == "UPDATE_LIJIN" and this:IsVisible()) then
		Packet_Tongbao:SetText("#{LJSD_120508_01}"..tostring(Player:GetData("LIJIN")));

	--锁定“整理按钮”
	elseif ( event == "BEGIN_PACKUP_PACKET" )   then
		Packet_Classify:Disable()

	--打开“整理按钮”
	elseif ( event == "END_PACKUP_PACKET" )	    then
		Packet_Classify:Enable()

	elseif(event == "HIDE_ON_SCENE_TRANSED" ) then
			this:Hide()

	elseif(event == "OPEN_RECYCLESHOP_BUYER") then
		Packet_Open();

	-- 等级
	elseif(event == "UNIT_LEVEL" and this:IsVisible()) then
		local result, money = Player:GetLevelMoneyLimit();
		if result then
  		Packet_Money:SetToolTip("#{money_tips} " ..  string.format("#{_MONEY%d}", money) );
  	end
	
	-- 材料快捷合成
  elseif ( event == "UI_COMMAND" and tonumber(arg0)== 920170825 ) then
  	nTheTabIndex = 1
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()
  	-- 宝石乾坤移
  elseif ( event == "UI_COMMAND" and tonumber(arg0)== 20110509 ) then
  	nTheTabIndex = 0
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()
  --2015 VIP随身移功能 By YuanPeiLong
  elseif ( event == "UI_COMMAND" and tonumber(arg0)== 98760001 ) then
  	nTheTabIndex = 0
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()
  --Start: Add By YPL, 宝石转换
  --宝石转换
  elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201302201 )then
	nTheTabIndex = 1
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()
  --End: Add By YPL, 宝石转换

  -- 宝石雕琢
  elseif ( event == "UI_COMMAND" and tonumber(arg0) == 112236 ) then
  	nTheTabIndex = 1
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()

  -- 宝石熔炼
  elseif ( event == "UI_COMMAND" and tonumber(arg0) == 112237 ) then
  	nTheTabIndex = 1
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()

  -- 宝石合成
  elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 23 ) then
  	nTheTabIndex = 1
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()
	-- 时装打孔
  elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20091027 ) then
  	nTheTabIndex = 0
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()

  --时装镶嵌
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20091029 ) then
  	nTheTabIndex = 0
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()

	--配饰合成
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 19860143 ) then
  	nTheTabIndex = 1
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()

	--配饰摘除
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 19851274 ) then
  	nTheTabIndex = 0
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()
	--门派进阶只打开背包
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 111011) then
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()

	elseif( event == "UI_COMMAND" and tonumber(arg0) == 5020231 ) then
  	nTheTabIndex = 0
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 5020232 ) then
  	nTheTabIndex = 0
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()
    elseif( event == "UI_COMMAND" and tonumber(arg0) == 20120222 ) then
  	Packet_Open()
    --- 缝绘蜜语金丝
    elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201207231 ) then
  	nTheTabIndex = 0
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()
    --- 清除缝绘蜜语金丝
    elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201207232 ) then
  	nTheTabIndex = 0
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()
    --- 万宝镶嵌
    elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2012081301 ) then
  	nTheTabIndex = 0
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()
  	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2013111801 ) then
  		nTheTabIndex = 0
  		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  		Packet_Open()
  	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2013111802 ) then
  	 	nTheTabIndex = 0
  		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  		Packet_Open()
  	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2013111803 ) then
 		nTheTabIndex = 0
 	 	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
 	 	Packet_Open()
 	 	
 	 	--配饰合成
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20151208 ) then
  	nTheTabIndex = 0
  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
  	Packet_Open()
  elseif ( event == "UI_COMMAND" and tonumber(arg0) == 19810313 ) then
		local sel_price = Get_XParam_INT(1);
		if sel_price==-1 then
	  	nTheTabIndex = 0
	  	PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
	  	Packet_Open()
  	end
  elseif ( event == "UI_COMMAND" and tonumber(arg0) == 1004 ) then
	  nTheTabIndex = 0
	  PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
	  Packet_Open()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20171003 ) then
		Packet_Open()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 893126004 ) then
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()
 	elseif (event == "OPEN_UP_ITEM" ) then
		if this:IsVisible()  then
			return
		end
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		Packet_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		Packet_Frame_On_ResetPos()

	elseif ( event == "YIGUI_OPEN" ) then
		Packet_Open();
	elseif ( event == "FASHION_DEPOT_OP" ) then
		local opType = tonumber(arg0)
		if opType == 1 then
			Packet_Open()
		end
	elseif( event == "REFRESH_EQUIP1") then
		Packet_RefreshEquip();
   	elseif event == "NOTIFY_POP_UITIP" then
		local nProcess = DataPool:GetCurrentFreshManGuideItemValue()
		if nProcess == 5 and this:IsVisible() then
			Packet_ShowFreshManGuide(nProcess)
			return
		end

        if "Packet" == arg0 then
			g_NeedTipText = tonumber(arg1)
			g_NeedTipItem = tonumber(arg2)
			g_NeedTipMission = tonumber(arg3)
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201208094 ) then	--	神器通灵
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201208093 ) then	--	神器契合
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201208092 ) then	--	神器进阶
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201208091 ) then	--	更换外观
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201208091 ) then	--	更换外观
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()
	elseif ( event == "UI_COMMAND" and ( tonumber(arg0) == 2017081201 or tonumber(arg0) == 2017082401 ) ) then	--	萌宠
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()
		
	elseif ( event == "UI_COMMAND" and (tonumber(arg0)==7020061 or tonumber(arg0)==7020062 or tonumber(arg0)==7020065) ) then
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()
	elseif ( event == "UI_COMMAND" and tonumber(arg0)==7020066 ) then
		local bFlag=Get_XParam_INT(0);
		if bFlag==1 then
			nTheTabIndex = 0
			PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
			Packet_Open()
		end
	  -- 宝石雕琢
	elseif ( event == "UI_COMMAND" and (tonumber(arg0) == 201210120 or  tonumber(arg0) == 201210121) ) then
		nTheTabIndex = 1
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 20130917) and Get_XParam_INT(0) == 002023 then
		local packetpos = PlayerPackage:GetBagPosByItemIndex(38000770)
		if packetpos == -1 then
			return
		else
			local theAction = EnumAction(packetpos, "packageitem")
			theAction:SetActionFlash(1)
			PACKAGE_BUTTONS[packetpos+1]:SetProperty("FlashAnimate", "BtnlightupAni")
			PACKAGE_BUTTONS[packetpos+1]:SetNewFlash()

			SetTimer("Packet", "Packet_ShopGuide()", 5000)
			g_ShopGuidePos = packetpos+1
			PushEvent("OPEN_FRESHMAN_NEWNPCCHAT",  6)
			OpenFreshManGuideNew(1, -99, -99, -99, -99, -99, -99, "Packet")	--只是为了挂上Packet界面，好同步关闭
			-- local nLine = math.floor(packetpos / PACKAGE_NUM_PER_LINE)
			-- local nColumn = math.mod(packetpos, PACKAGE_NUM_PER_LINE)
			-- PushDebugMessage("line="..nLine..",nColumn="..nColumn)
			-- local nPosX = tonumber(Packet_Frame:GetProperty("AbsoluteXPosition"))
			-- local nPosY = tonumber(Packet_Frame:GetProperty("AbsoluteYPosition"))
			-- local fX = 0
			-- local fY = 0
			-- fX, fY = this:GetChildOffset("Packet_Space_Line1_Row1_button")
			-- local fW = tonumber(Packet_Space_Line1_Row1_button:GetProperty("AbsoluteWidth"))
			-- local fH = tonumber(Packet_Space_Line1_Row1_button:GetProperty("AbsoluteHeight"))
			-- fX = math.floor(tonumber(fX + nPosX + (fW * 0.5) + (nColumn*37)))
			-- fY = tonumber(fY + nPosY + fH + 130 + (nLine*37))
			-- OpenFreshManGuideNew(1, fX, fY, fW, fH, 23, 0, "Packet")
		end
	elseif event == "UI_COMMAND" and (tonumber(arg0)) == 890878 then	--	武林风云录引导任务
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()
	elseif event == "UI_COMMAND" and (tonumber(arg0)) == 201408140 then
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 101526358 then--神器修理
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()
	--神器炼魂
	elseif event == "UI_COMMAND" and tonumber(arg0) == 19831114 then
		Packet_Open()
	--龙纹属性重洗
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20110727 then
		Packet_Open()
	--暗器技能重洗
	elseif event == "UI_COMMAND" and tonumber(arg0) == 800034 then
		Packet_Open()
	--重新鉴定装备资质
	elseif event == "UI_COMMAND" and tonumber(arg0) == 112233 then
		Packet_Open()
	--武魂扩展属性升级
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20090720 then
		Packet_Open()
	--武魂延寿
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20090721 then
		Packet_Open()
	--重洗武魂技能
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20090722 then
		Packet_Open()
	--武魂技能升级
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20090723 then
		Packet_Open()
	--重洗子女技能
	elseif event == "UI_COMMAND" and tonumber(arg0) == 89061 then
		Packet_Open()
	-- 【2017Q3】九星神器升星设计--神器DIY技能--同步打开背包
	--elseif event == "UI_COMMAND" and tonumber(arg0) == 89247101 then
		--Packet_Open()
	--打开装饰武器锻造界面
	elseif event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 891787 then
		if Get_XParam_INT(0) == 1 then
			Packet_Open()
		end
	--打开装饰武器升级界面
	elseif event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 891788 then
		if Get_XParam_INT(0) == 1 then       --打开界面
			Packet_Open()
		end
	--VIP随身修理
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 810208171 ) then
		nTheTabIndex = 0
		PACKAGE_TAB[nTheTabIndex]:SetCheck(1)
		Packet_Open()
	elseif (event=="CLOSE_TEMBANK") then
		Packet_SetPacketTempory_BtnState(0)
	elseif (event=="OPEN_TEMBANK") then
		Packet_SetPacketTempory_BtnState(1)
	end
end

--nState表示临时背包当前状态：1打开，0关闭
function Packet_SetPacketTempory_BtnState(nState)
	if g_TemBankState~=nState then
		if nState==1 then
			Packet_Temporary_Button:SetProperty("PushedImage","set:CommonFrame37 image:Packet_TemporaryOpen_Pushed")
			Packet_Temporary_Button:SetProperty("NormalImage","set:CommonFrame37 image:Packet_TemporaryOpen_Normal")
			Packet_Temporary_Button:SetProperty("HoverImage","set:CommonFrame37 image:Packet_TemporaryOpen_Hover")
			Packet_Temporary_Button:SetProperty("DisabledImage","set:CommonFrame37 image:Packet_TemporaryOpen_Disable")
		else
			Packet_Temporary_Button:SetProperty("PushedImage","set:CommonFrame37 image:Packet_TemporaryClose_Pushed")
			Packet_Temporary_Button:SetProperty("NormalImage","set:CommonFrame37 image:Packet_TemporaryClose_Normal")
			Packet_Temporary_Button:SetProperty("HoverImage","set:CommonFrame37 image:Packet_TemporaryClose_Hover")
			Packet_Temporary_Button:SetProperty("DisabledImage","set:CommonFrame37 image:Packet_TemporaryClose_Disable")
		end
	end
end

function Packet_ShopGuide()
	if g_ShopGuidePos > 0 and g_ShopGuidePos <= 30 then
		PACKAGE_BUTTONS[g_ShopGuidePos]:SetProperty("FlashAnimateEnable", 0)
	end
	KillTimer("Packet_ShopGuide()")

end

function Packet_ResetExtBag()
	Packet_OnUpdateShow();
	Packet_UpdateDragAcceptName();
end

function Packet_OnShow()
	Packet_ChangeTabIndex(nTheTabIndex);
end

function Packet_ChangeTabIndex(nTabIndex)
	if( nTabIndex < 0 or nTabIndex >=3) then
		return;
	end
	nTheTabIndex = nTabIndex;
	Packet_OnUpdateShow();
	Packet_UpdateDragAcceptName();
end

function Packet_UpdateBagLine( nMaxLine )

	g_MaxLine = nMaxLine;
	local i
	for i = 1, 10 do
		if( i <= g_MaxLine ) then
			PACKAGE_EXTBAG[ i ]:Show();
		else
			PACKAGE_EXTBAG[ i ]:Hide();
		end
	end
	local nWindowHeight;
	if 1 == SystemSetup:IsClassic() then
		nWindowHeight = g_MaxLine * 35 + 278;
	else
		nWindowHeight = g_MaxLine * 40 + 209 + 95;
	end
	Packet_Frame:SetProperty( "AbsoluteHeight",nWindowHeight );

end

function Packet_OnUpdateShow()
	local i=1;
	local szPacketName = "";
	local CurrNum = 20;
	local BaseNum = 20;
	local MaxNum = 60;
	Lock_Flag = 0;

	if(nTheTabIndex == 0) then
		szPacketName = "base";
		CurrNum = DataPool:GetBaseBag_Num();
		BaseNum = DataPool:GetBaseBag_BaseNum();
		MaxNum = DataPool:GetBaseBag_RealMaxNum();
	elseif(nTheTabIndex == 1) then
		szPacketName = "material";
		CurrNum = DataPool:GetMatBag_Num();
		BaseNum = DataPool:GetMatBag_BaseNum();
		MaxNum = DataPool:GetMatBag_RealMaxNum();
	elseif(nTheTabIndex == 2) then
		szPacketName = "quest";
		CurrNum = DataPool:GetTaskBag_Num();
		BaseNum = DataPool:GetTaskBag_BaseNum();
		MaxNum = DataPool:GetTaskBag_MaxNum();
	else
		return;
	end

	local nMaxLine = math.floor( MaxNum / PACKAGE_NUM_PER_LINE );
	--如果是整除了
	if( nMaxLine * PACKAGE_NUM_PER_LINE == MaxNum ) then
	else
		nMaxLine = nMaxLine + 1;
	end

	--如果超过当前显示的最大范围了，就更新包的行数
	Packet_UpdateBagLine( nMaxLine );
	local nMaxDisplayNumber = nMaxLine * PACKAGE_NUM_PER_LINE;
	for i=1, nMaxDisplayNumber do
		--如果是需要显示的
		if( i <= CurrNum ) then
			local theAction,bLocked = PlayerPackage:EnumItem(szPacketName, i-1);
			PACKAGE_BUTTONS[ i ]:Show();
			PACKAGE_BUTTONS[ i ]:SetProperty( "BackImage", "" )
			if theAction:GetID() ~= 0 then
				PACKAGE_BUTTONS[i]:SetActionItem(theAction:GetID());
				if nTheTabIndex == 0 and Player:GetData("LEVEL") < 10 and g_NeedTipItem == theAction:GetDefineID() then
				    g_NeedTipID = i
				    theAction:SetActionFlash(1)
				else
				    theAction:SetActionFlash(0)
				end
			else
				PACKAGE_BUTTONS[i]:SetActionItem(-1);
			end
			if bLocked == 1 then
				PACKAGE_BUTTONS[i]:Disable();
				Lock_Flag = 1
			else
				PACKAGE_BUTTONS[i]:Enable();
			end

		else  --这些是需要隐藏的
			PACKAGE_BUTTONS[ i ]:SetActionItem( -1 );
			PACKAGE_BUTTONS[ i ]:Show();
			PACKAGE_BUTTONS[ i ]:SetProperty( "BackImage", "set:CommonFrame38 image:ActionLock" )
		end
	end

	if Lock_Flag == 0 then
		Packet_Classify : Enable();
	else
		Packet_Classify : Disable();
	end

	--Money
	local result, money = Player:GetLevelMoneyLimit();
	if result then
  	Packet_Money:SetToolTip("#{money_tips} " ..  string.format("#{_MONEY%d}", money) );
  end
	Packet_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	--YuanBao
	Packet_YuanBao2:SetText("元宝："..tostring(Player:GetData("YUANBAO")));
	--BindYuanBao
	Packet_BangdingYuanbao:SetText("#{BDYB_090714_01}"..tostring(Player:GetData("BIND_YUANBAO")));
	--返券
	Packet_Fanquan:SetText("#{YBFQ_XML_1}"..tostring(Player:GetData("GIFTTOKEN")));
	if GameProduceLogin:IsWeGameClient() > 0 then
		Packet_Fanquan:SetToolTip("#{WEJR_230303_26}")
	else
		Packet_Fanquan:SetToolTip("#{FQ_101210_04}")
	end
	--ZengDian
	Packet_YuanBao:SetText("赠点："..tostring(Player:GetData("ZENGDIAN")));
	--礼金
	Packet_Tongbao:SetText("#{LJSD_120508_01}"..tostring(Player:GetData("LIJIN")));

	--Money_JZ
	Packet_Jiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));

    if g_NeedTipItem > 0 and g_NeedTipID > 0 then  --弹出新手引导ui
        g_NeedTipItem = -1 --确保只提示一次

        local nLine = math.floor(g_NeedTipID / PACKAGE_NUM_PER_LINE)
        if nLine == math.ceil(g_NeedTipID / PACKAGE_NUM_PER_LINE) then
            nLine = nLine - 1
        end
        local nColumn = g_NeedTipID - nLine * PACKAGE_NUM_PER_LINE
        local fX, fY = this:GetChildOffset("Packet_Space_Frame")
        fX = fX + PACKAGE_BUTTONS[1]:GetProperty("AbsoluteWidth") * (nColumn - 0.5)
        fY = fY + PACKAGE_EXTBAG[1]:GetProperty("AbsoluteHeight") * (nLine + 1)
        OpenFreshManGuide(1, g_NeedTipText, fX, fY, "Packet", "southwest")

        PACKAGE_BUTTONS[g_NeedTipID]:SetProperty("FlashAnimate", "BtnlightupAni")
        PACKAGE_BUTTONS[g_NeedTipID]:SetNewFlash()
    end

    local nProcess = DataPool:GetCurrentFreshManGuideItemValue()

    if nProcess == 2 then
	Packet_ShowFreshManGuide(nProcess)
    end
end

function Packet_UpdateDragAcceptName()

	local nStartAcceptIndex = 0;

	if(nTheTabIndex == 0) then
		nStartAcceptIndex = 1;
	elseif(nTheTabIndex == 1) then
		nStartAcceptIndex = DataPool:GetBaseBag_MaxNum()+1;
	elseif(nTheTabIndex == 2) then
		nStartAcceptIndex = DataPool:GetBaseBag_MaxNum()+DataPool:GetMatBag_MaxNum()+1;
	else
		return;
	end

	local i=1;
	while i<=PACKAGE_BUTTONS_NUM do
		PACKAGE_BUTTONS[i]:SetProperty("DragAcceptName", "P"..tostring(nStartAcceptIndex));

		nStartAcceptIndex = nStartAcceptIndex+1;
		i = i+1;
	end

end

function Packet_ShowFreshManGuide(process)
	local nPosX = tonumber(Packet_Frame:GetProperty("AbsoluteXPosition"))
	local nPosY = tonumber(Packet_Frame:GetProperty("AbsoluteYPosition"))
	local fX = 0
	local fY = 0
	if process == 2 then		--	第一件武器装备后的玩意。。。
		fX, fY = this:GetChildOffset("Packet_Space_Line1_Row1_button")
		local fW = tonumber(Packet_Space_Line1_Row1_button:GetProperty("AbsoluteWidth"))
		local fH = tonumber(Packet_Space_Line1_Row1_button:GetProperty("AbsoluteHeight"))
		fX = math.floor(tonumber(fX + nPosX + (fW * 0.5)))
		fY = tonumber(fY + nPosY + fH + 130)
		OpenFreshManGuideNew(1, fX, fY, fW, fH, 3, 0, "Packet")
		DataPool:SetCurrentFreshManGuideItemValue(3)
		return
	elseif process == 5 then	--	初始武器装备后的关闭提示。。。
		fX, fY = this:GetChildOffset("Packet_Close")
		local fW = tonumber(Packet_Close:GetProperty("AbsoluteWidth"))
		local fH = tonumber(Packet_Close:GetProperty("AbsoluteHeight"))
		fX = math.floor(tonumber(fX + nPosX))
		fY = math.floor(tonumber(fY + nPosY + (fH * 0.5)))
		OpenFreshManGuideNew(1, fX, fY, fW, fH, 11, 2, "Packet")
		DataPool:SetCurrentFreshManGuideItemValue(6)
		return
	end
end

function Packet_ItemBtnClicked( nLine, nRow )
	local nIndex = ( nLine - 1 ) * PACKAGE_NUM_PER_LINE + nRow;
	if(nIndex < 1 or nIndex > PACKAGE_BUTTONS_NUM) then
		return;
	end

	local nItemID = LifeAbility : Get_Equip_TableIndex(nIndex - 1)

	--local nProcess = DataPool:GetCurrentFreshManGuideItemValue()
	--if nProcess == 10141451 and nItemID == 10141451 then
		--PushEvent("OPEN_RIDE_PAGE")
		--DataPool:SetCurrentFreshManGuideItemValue(10)
	--NotifyPopUITip("MainMenuBar", 1, 8)
	--end

	if Player:GetLevel() <= 15 and nItemID == 10141517 then
		NotifyPopUITip("MainMenuBar", 1, 8)
	end

	PACKAGE_BUTTONS[nIndex]:DoAction()

	--一旦点击,清除引导ui
	if nIndex == g_NeedTipID then
    		g_NeedTipID = -1
--    	if "Packet" == GetFreshManGuideOwner() then
--            CloseFreshManGuide()
--        end
	--	现在改了。。。。一点就开角色界面。。。。


		if 210256 == g_NeedTipMission then --如是右击装备"第一件防具"的奖励装备
			NotifyPopUITip("MainMenuBar", 7, 2)  --通知主动作条：弹出ui引导
		end
	end

	if "Packet" == GetFreshManGuideOwner() then
            CloseFreshManGuide()
        end

	nProcess = DataPool:GetCurrentFreshManGuideItemValue()
	if nLine == 1 and nRow == 1 and nProcess == 3 then
--		Packet_ShowFreshManGuide(5)
--		DataPool:SetCurrentFreshManGuideItemValue(6)
--	以下为文档方式，先屏蔽，做特殊处理。本if内的上方语句为特殊处理，功能本身比较坑爹	--	lx
		--	打开角色界面。。。
		OpenEquip(1)
		DataPool:SetCurrentFreshManGuideItemValue(4)
	end
end

function Packet_ItemBtnSubClicked( nLine,nRow )
	local nIndex = ( nLine - 1 ) * PACKAGE_NUM_PER_LINE + nRow;
	if(nIndex < 1 or nIndex > PACKAGE_BUTTONS_NUM) then
		return;
	end
	PACKAGE_BUTTONS[nIndex]:DoSubAction()

	--一旦点击,清除引导ui
	if nIndex == g_NeedTipID then
    	g_NeedTipID = -1
    	if "Packet" == GetFreshManGuideOwner() then
            CloseFreshManGuide()
        end
    end
end

function Packet_RefreshEquip()
	--  清空按钮显示图标
	Packet_Equip_Bag:SetActionItem(-1);			--行囊
	Packet_Equip_Box:SetActionItem(-1);			--格箱

	local ActionBag 		= EnumAction(9 , "equip");
	local ActionBox 		= EnumAction(10, "equip");

	-- 显示人身上的武器装备
	Packet_Equip_Bag:SetActionItem(ActionBag:GetID());			--行囊
	Packet_Equip_Box:SetActionItem(ActionBox:GetID());			--格箱
end
-- 行囊点击事件
function Packet_Bag_Click()
	Packet_Equip_Bag:DoSubAction();	--行囊
end

-- 格箱点击事件
function Packet_Box_Click()
	Packet_Equip_Box:DoSubAction();	--格箱
end

--===============================================
-- 启动摆摊界面(在摆摊前会先确认摊位费)
--===============================================
function Packet_Sale_Clicked()
	PlayerPackage:OpenStallSaleFrame();
end

function Packet_PackUp_Clicked()
	PlayerPackage:PackUpPacket(nTheTabIndex);
end


--===============================================
-- 点击锁定
--===============================================
function Packet_Lock_Open()
	PlayerPackage:OpenLockFrame(nTheTabIndex);
end

function OpenSafeCenter()
	
	if IsTBFinalServer() >= 1 then
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end	
		
	OpenSafeScore();
end

--================================================
-- 恢复背包界面的默认相对位置
--================================================
function Packet_Frame_On_ResetPos()

	Packet_Frame:SetProperty("UnifiedXPosition", g_Packet_Frame_UnifiedXPosition);
	Packet_Frame:SetProperty("UnifiedYPosition", g_Packet_Frame_UnifiedYPosition);
--	PushDebugMessage("resetpos g_Packet_Frame_UnifiedXPosition="..g_Packet_Frame_UnifiedXPosition)

  Variable:SetVariable("PacketUnionXPos", g_Packet_Frame_UnifiedXPosition, 1);
  Variable:SetVariable("PacketUnionYPos", g_Packet_Frame_UnifiedYPosition, 1);
end
function Packet_Temporary_BtnClick()
	-- local isinT = Bank:CheckIsInTServer()

	-- if isinT == 1 then
	-- 	PushDebugMessage("#{SSCK_180821_22}")
	-- else
	if(IsWindowShow("Packet_Temporary")) then
		 CloseWindow("Packet_Temporary", true);
		 Packet_SetPacketTempory_BtnState(0)
	else
		Bank:AskTemBankList()
		Packet_SetPacketTempory_BtnState(1)
	end
--end
end
