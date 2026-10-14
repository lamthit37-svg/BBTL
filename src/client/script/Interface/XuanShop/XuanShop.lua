local TOTALFITTINGKIND_NUM = 10;
local XUAN_GOODS_BUTTONS_NUM = 24;
local XUAN_GOODS_BUTTONS = {};
local XUAN_GOODS_DESCS = {};
local XUAN_GOOD_BAD    = {};
local g_XuanShop_Dress = {};
local LAST_XUAN_TAG = 1;

local GOODS_BUTTONS_JiYuan_NUM = 6;
local GOODS_JiYuan_BUTTONS = {};
local GOODS_JiYuan_BUTTONS_Buy = {};
local GOODS_JiYuan_DESCS = {};
local GOODS_JiYuan_BAD    = {};

local XUAN_GOODS_BUTTONS_ICON = {};
local GOODS_JiYuan_BUTTONS_ICON = {};
--设置经典版对应的图标资源
local IconTable = {
	["H"] = "set:CommonFrame20 image:Item_Hot",
	["S"] = "set:CommonFrame20 image:Item_Special",
	["A"] = "set:CommonFrame20 image:Item_Activity",
	["D"] = "set:CommonFrame20 image:Item_Discount",
	["N"] = "set:CommonFrame20 image:Item_New",
	["L"] = "set:CommonFrame20 image:Item_Limit",
}
--标签页索引值
local XuanShopTabIdx = {
	YuanBao 	= 0,	--元宝商店
	Bind		= 1,	--绑定元宝商店
	GiftToken	= 2,	--返券商店
	IMDress		= 3,	--炫装商城
	Show 		= 6,  	--秀场商店
}

local XuanShopFittingDefaultInfo =
{
	Male	= {},
	Female	= {},
}
local g_nTargetID = -1
XuanShopFittingDefaultInfo.Male[0] = nil;
XuanShopFittingDefaultInfo.Male[1] = "Base_M_DownBody";
XuanShopFittingDefaultInfo.Male[2] = "Base_M_UpBody";
XuanShopFittingDefaultInfo.Male[3] = "Base_M_Head";
XuanShopFittingDefaultInfo.Male[4] = nil;
XuanShopFittingDefaultInfo.Male[5] = nil;

XuanShopFittingDefaultInfo.Female[0] = nil;
XuanShopFittingDefaultInfo.Female[1] = "Base_F_DownBody";
XuanShopFittingDefaultInfo.Female[2] = "Base_F_UpBody";
XuanShopFittingDefaultInfo.Female[3] = "Base_F_Head";
XuanShopFittingDefaultInfo.Female[4] = nil;
XuanShopFittingDefaultInfo.Female[5] = nil;

local XuanShopFittingInfo =
{
	Male	= {},
	Female	= {},
}

local XuanShopFittingInfoBackup =
{
	Male	= {},
	Female	= {},
}

local XuanShopDressedItemID =
{
	Male	= {},
	Female	= {},
}

local XuanShopDressedItemID_BackUp =
{
	Male	= {},
	Female	= {},
}

local XUAN_SHOP_LIST_A = {};
local XUAN_SHOP_LIST_B = {};
local XUAN_SHOP_SEARCH_LIST ={};

local nXuanPageNum = 1;
local maxXuanPage = 1;
local XuanCurPage = 0
local XuanObjCared = -1;
local XuanLastA = 1
local XuanLastB = 1
local XuanLastSelect = 0

local XuanIsCareObj = 0

--存储随机排序的索引值
local	g_XuanOrderPool	= {};
--当前商店的商品数量
local	g_XuanTotalNum	= 0;

local	g_XuanChangeTabFlag	= 0;
local	g_XuanTabIndex	= 0;		-- 0表示元宝 --1表示绑定元宝

local g_XuanShop_Frame_UnifiedXPosition;
local g_XuanShop_Frame_UnifiedYPosition;

local g_XuanShop_DressPoint = {
	BackGround	= 0,
	Leg		= 1,
	Body		= 2,
	Head		= 3,
	Front		= 4,
	Suit		= 5,
}
local g_PlayCard_Image = {
	[1] = "set:adpic1 image:adpic1_1",
	[2] = "set:adpic1 image:adpic1_2",
	[3] = "set:adpic2 image:adpic2_1",
	[4] = "set:adpic2 image:adpic2_2",
}
local g_PlayCard_CtlButton = {}
local g_PlayCard_URL = {
	[1] = "WEB_YBSDGUANGGAO_1", --"WEB_GUANWANG" ,
	[2] = "WEB_YBSDGUANGGAO_2", --"WEB_LUNTAN",
	[3] = "WEB_YBSDGUANGGAO_3", --"WEB_JIANYI",
	[4] = "WEB_YBSDGUANGGAO_4", --"WEB_VIPJIESHAO",
}
local g_PlayCard_CurPage = 0
local g_PlayCard_MaxPage = 4
--当前商店是 炫装商城 还是 赠送商店
local	g_XuanShopName = "XuanShop"
--如果是赠送商店需要记录好友guid、性别、组、索引
local g_Friendguid = ""
local g_FriendRace = -1
local g_Friendgroup = 0
local g_Friendindex = -1
local g_IsMyFriend = -1
local g_IsEnableFanQuanShop = 1--关闭返券商店功能的开关，在YuanBaoShop、XuanShop、ShowShop界面中有这个开关，必须保持一致
function XuanShop_PreLoad()

	this:RegisterEvent("OPEN_IMDRESS_YUANBAOSHOP");
	this:RegisterEvent("PLAYER_ENTERING_WORLD");
	this:RegisterEvent("UPDATE_BOOTH");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("CLOSE_BOOTH");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
	this:RegisterEvent("UPDATE_YUANBAO");
	this:RegisterEvent("UPDATE_BIND_YUANBAO");
	this:RegisterEvent("UPDATE_GIFTTOKEN");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_MYSELF_IMDRESS")
	this:RegisterEvent("UPDATE_FRIEND_IMDRESS")
	this:RegisterEvent("IMDRESS_CLEAN_SHOP_SELECTED")
	this:RegisterEvent("OPEN_IMDRESSPRESENT_YUANBAOSHOP")
	this:RegisterEvent("GAMELOGIN_OPEN_SELECT_CHARACTOR")
	this:RegisterEvent("OPEN_JIYUAN_BOOTH")
	this:RegisterEvent("TOGGLE_XUANSHOP")
end

function XuanShop_OnLoad()
	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图标资源为唯美版对应的资源
		IconTable = {
			["H"] = "set:WM_CommonFrame1 image:Re",
			["S"] = "set:WM_CommonFrame1 image:Te",
			["A"] = "set:WM_CommonFrame1 image:Huo",
			["D"] = "set:WM_CommonFrame1 image:Zhe",
			["N"] = "set:WM_CommonFrame1 image:Xin",
			["L"] = "set:WM_CommonFrame1 image:Xian",
		}
	end

	GOODS_JiYuan_BUTTONS[1] = XuanShop_ExItem1;
	GOODS_JiYuan_BUTTONS[2] = XuanShop_ExItem2;
	GOODS_JiYuan_BUTTONS[3] = XuanShop_ExItem3;
	GOODS_JiYuan_BUTTONS[4] = XuanShop_ExItem4;
	GOODS_JiYuan_BUTTONS[5] = XuanShop_ExItem5;
	GOODS_JiYuan_BUTTONS[6] = XuanShop_ExItem6;

	GOODS_JiYuan_BUTTONS_Buy[1] = XuanShop_ExItemInfo1_Buy
	GOODS_JiYuan_BUTTONS_Buy[2] = XuanShop_ExItemInfo2_Buy
	GOODS_JiYuan_BUTTONS_Buy[3] = XuanShop_ExItemInfo3_Buy
	GOODS_JiYuan_BUTTONS_Buy[4] = XuanShop_ExItemInfo4_Buy
	GOODS_JiYuan_BUTTONS_Buy[5] = XuanShop_ExItemInfo5_Buy
	GOODS_JiYuan_BUTTONS_Buy[6] = XuanShop_ExItemInfo6_Buy

	GOODS_JiYuan_BUTTONS_ICON[1] = XuanShop_ExItemIcon_1
	GOODS_JiYuan_BUTTONS_ICON[2] = XuanShop_ExItemIcon_2
	GOODS_JiYuan_BUTTONS_ICON[3] = XuanShop_ExItemIcon_3
	GOODS_JiYuan_BUTTONS_ICON[4] = XuanShop_ExItemIcon_4
	GOODS_JiYuan_BUTTONS_ICON[5] = XuanShop_ExItemIcon_5
	GOODS_JiYuan_BUTTONS_ICON[6] = XuanShop_ExItemIcon_6

	GOODS_JiYuan_DESCS[1] = XuanShop_ExItemInfo1_Text;
	GOODS_JiYuan_DESCS[2] = XuanShop_ExItemInfo2_Text;
	GOODS_JiYuan_DESCS[3] = XuanShop_ExItemInfo3_Text;
	GOODS_JiYuan_DESCS[4] = XuanShop_ExItemInfo4_Text;
	GOODS_JiYuan_DESCS[5] = XuanShop_ExItemInfo5_Text;
	GOODS_JiYuan_DESCS[6] = XuanShop_ExItemInfo6_Text;

	GOODS_JiYuan_BAD[1] = XuanShop_ExItemInfo1_GB;
	GOODS_JiYuan_BAD[2] = XuanShop_ExItemInfo2_GB;
	GOODS_JiYuan_BAD[3] = XuanShop_ExItemInfo3_GB;
	GOODS_JiYuan_BAD[4] = XuanShop_ExItemInfo4_GB;
	GOODS_JiYuan_BAD[5] = XuanShop_ExItemInfo5_GB;
	GOODS_JiYuan_BAD[6] = XuanShop_ExItemInfo6_GB;

	g_XuanShop_Dress[0] = XuanShop_fitting_BK
	g_XuanShop_Dress[1] = XuanShop_fitting_DownBody
	g_XuanShop_Dress[2] = XuanShop_fitting_UpBody
	g_XuanShop_Dress[3] = XuanShop_fitting_Head
	g_XuanShop_Dress[4] = XuanShop_fitting_FK
	g_XuanShop_Dress[5] = XuanShop_fitting_Suit

	XUAN_GOODS_BUTTONS[1] = XuanShop_Item1;
	XUAN_GOODS_BUTTONS[2] = XuanShop_Item2;
	XUAN_GOODS_BUTTONS[3] = XuanShop_Item3;
	XUAN_GOODS_BUTTONS[4] = XuanShop_Item4;
	XUAN_GOODS_BUTTONS[5] = XuanShop_Item5;
	XUAN_GOODS_BUTTONS[6] = XuanShop_Item6;
	XUAN_GOODS_BUTTONS[7] = XuanShop_Item7;
	XUAN_GOODS_BUTTONS[8] = XuanShop_Item8;
	XUAN_GOODS_BUTTONS[9] = XuanShop_Item9;
	XUAN_GOODS_BUTTONS[10]= XuanShop_Item10;
	XUAN_GOODS_BUTTONS[11]= XuanShop_Item11;
	XUAN_GOODS_BUTTONS[12]= XuanShop_Item12;
	XUAN_GOODS_BUTTONS[13]= XuanShop_Item13;
	XUAN_GOODS_BUTTONS[14]= XuanShop_Item14;
	XUAN_GOODS_BUTTONS[15]= XuanShop_Item15;
	XUAN_GOODS_BUTTONS[16]= XuanShop_Item16;
	XUAN_GOODS_BUTTONS[17]= XuanShop_Item17;
	XUAN_GOODS_BUTTONS[18]= XuanShop_Item18;
	XUAN_GOODS_BUTTONS[19]= XuanShop_Item19;
	XUAN_GOODS_BUTTONS[20]= XuanShop_Item20;
	XUAN_GOODS_BUTTONS[21]= XuanShop_Item21;
	XUAN_GOODS_BUTTONS[22]= XuanShop_Item22;
	XUAN_GOODS_BUTTONS[23]= XuanShop_Item23;
	XUAN_GOODS_BUTTONS[24]= XuanShop_Item24;

	XUAN_GOODS_BUTTONS_ICON[1] = XuanShop_ItemIcon_1
	XUAN_GOODS_BUTTONS_ICON[2] = XuanShop_ItemIcon_2
	XUAN_GOODS_BUTTONS_ICON[3] = XuanShop_ItemIcon_3
	XUAN_GOODS_BUTTONS_ICON[4] = XuanShop_ItemIcon_4
	XUAN_GOODS_BUTTONS_ICON[5] = XuanShop_ItemIcon_5
	XUAN_GOODS_BUTTONS_ICON[6] = XuanShop_ItemIcon_6
	XUAN_GOODS_BUTTONS_ICON[7] = XuanShop_ItemIcon_7
	XUAN_GOODS_BUTTONS_ICON[8] = XuanShop_ItemIcon_8
	XUAN_GOODS_BUTTONS_ICON[9] = XuanShop_ItemIcon_9
	XUAN_GOODS_BUTTONS_ICON[10]= XuanShop_ItemIcon_10
	XUAN_GOODS_BUTTONS_ICON[11]= XuanShop_ItemIcon_11
	XUAN_GOODS_BUTTONS_ICON[12]= XuanShop_ItemIcon_12
	XUAN_GOODS_BUTTONS_ICON[13]= XuanShop_ItemIcon_13
	XUAN_GOODS_BUTTONS_ICON[14]= XuanShop_ItemIcon_14
	XUAN_GOODS_BUTTONS_ICON[15]= XuanShop_ItemIcon_15
	XUAN_GOODS_BUTTONS_ICON[16]= XuanShop_ItemIcon_16
	XUAN_GOODS_BUTTONS_ICON[17]= XuanShop_ItemIcon_17
	XUAN_GOODS_BUTTONS_ICON[18]= XuanShop_ItemIcon_18
	XUAN_GOODS_BUTTONS_ICON[19]= XuanShop_ItemIcon_19
	XUAN_GOODS_BUTTONS_ICON[20]= XuanShop_ItemIcon_20
	XUAN_GOODS_BUTTONS_ICON[21]= XuanShop_ItemIcon_21
	XUAN_GOODS_BUTTONS_ICON[22]= XuanShop_ItemIcon_22
	XUAN_GOODS_BUTTONS_ICON[23]= XuanShop_ItemIcon_23
	XUAN_GOODS_BUTTONS_ICON[24]= XuanShop_ItemIcon_24

	XUAN_GOODS_DESCS[1] = XuanShop_ItemInfo1_Text;
	XUAN_GOODS_DESCS[2] = XuanShop_ItemInfo2_Text;
	XUAN_GOODS_DESCS[3] = XuanShop_ItemInfo3_Text;
	XUAN_GOODS_DESCS[4] = XuanShop_ItemInfo4_Text;
	XUAN_GOODS_DESCS[5] = XuanShop_ItemInfo5_Text;
	XUAN_GOODS_DESCS[6] = XuanShop_ItemInfo6_Text;
	XUAN_GOODS_DESCS[7] = XuanShop_ItemInfo7_Text;
	XUAN_GOODS_DESCS[8] = XuanShop_ItemInfo8_Text;
	XUAN_GOODS_DESCS[9] = XuanShop_ItemInfo9_Text;
	XUAN_GOODS_DESCS[10]= XuanShop_ItemInfo10_Text;
	XUAN_GOODS_DESCS[11]= XuanShop_ItemInfo11_Text;
	XUAN_GOODS_DESCS[12]= XuanShop_ItemInfo12_Text;
	XUAN_GOODS_DESCS[13]= XuanShop_ItemInfo13_Text;
	XUAN_GOODS_DESCS[14]= XuanShop_ItemInfo14_Text;
	XUAN_GOODS_DESCS[15]= XuanShop_ItemInfo15_Text;
	XUAN_GOODS_DESCS[16]= XuanShop_ItemInfo16_Text;
	XUAN_GOODS_DESCS[17]= XuanShop_ItemInfo17_Text;
	XUAN_GOODS_DESCS[18]= XuanShop_ItemInfo18_Text;
	XUAN_GOODS_DESCS[19]= XuanShop_ItemInfo19_Text;
	XUAN_GOODS_DESCS[20]= XuanShop_ItemInfo20_Text;
	XUAN_GOODS_DESCS[21]= XuanShop_ItemInfo21_Text;
	XUAN_GOODS_DESCS[22]= XuanShop_ItemInfo22_Text;
	XUAN_GOODS_DESCS[23]= XuanShop_ItemInfo23_Text;
	XUAN_GOODS_DESCS[24]= XuanShop_ItemInfo24_Text;

	XUAN_GOOD_BAD[1]  =     XuanShop_ItemInfo1_GB;
	XUAN_GOOD_BAD[2]  =     XuanShop_ItemInfo2_GB;
	XUAN_GOOD_BAD[3]  =     XuanShop_ItemInfo3_GB;
	XUAN_GOOD_BAD[4]  =     XuanShop_ItemInfo4_GB;
	XUAN_GOOD_BAD[5]  =     XuanShop_ItemInfo5_GB;
	XUAN_GOOD_BAD[6]  =     XuanShop_ItemInfo6_GB;
	XUAN_GOOD_BAD[7]  =     XuanShop_ItemInfo7_GB;
	XUAN_GOOD_BAD[8]  =     XuanShop_ItemInfo8_GB;
	XUAN_GOOD_BAD[9]  =     XuanShop_ItemInfo9_GB;
	XUAN_GOOD_BAD[10] =     XuanShop_ItemInfo10_GB;
	XUAN_GOOD_BAD[11] =     XuanShop_ItemInfo11_GB;
	XUAN_GOOD_BAD[12] =     XuanShop_ItemInfo12_GB;
	XUAN_GOOD_BAD[13] =     XuanShop_ItemInfo13_GB;
	XUAN_GOOD_BAD[14] =     XuanShop_ItemInfo14_GB;
	XUAN_GOOD_BAD[15] =     XuanShop_ItemInfo15_GB;
	XUAN_GOOD_BAD[16] =     XuanShop_ItemInfo16_GB;
	XUAN_GOOD_BAD[17] =     XuanShop_ItemInfo17_GB;
	XUAN_GOOD_BAD[18] =     XuanShop_ItemInfo18_GB;
	XUAN_GOOD_BAD[19] =     XuanShop_ItemInfo19_GB;
	XUAN_GOOD_BAD[20] =     XuanShop_ItemInfo20_GB;
	XUAN_GOOD_BAD[21] =     XuanShop_ItemInfo21_GB;
	XUAN_GOOD_BAD[22] =     XuanShop_ItemInfo22_GB;
	XUAN_GOOD_BAD[23] =     XuanShop_ItemInfo23_GB;
	XUAN_GOOD_BAD[24] =     XuanShop_ItemInfo24_GB;

	--热卖炫装
	XUAN_SHOP_LIST_A[1] = {btn = XuanShop_Button1 , shoplist = {}}
	XUAN_SHOP_LIST_A[1].shoplist[1] = ""	--"";

	--新品推荐
	XUAN_SHOP_LIST_A[2] = {btn = XuanShop_Button2 , shoplist = {}}
	XUAN_SHOP_LIST_A[2].shoplist[1] = ""	--"";

	--脸型
	XUAN_SHOP_LIST_A[3] = {btn = XuanShop_Button3 , shoplist = {}}
	XUAN_SHOP_LIST_A[3].shoplist[1] = ""	--"";

	--上装
	XUAN_SHOP_LIST_A[4] = {btn = XuanShop_Button4 , shoplist = {}}
	XUAN_SHOP_LIST_A[4].shoplist[1] = ""	--"";

	--下装
	XUAN_SHOP_LIST_A[5] = {btn = XuanShop_Button5 , shoplist = {}}
	XUAN_SHOP_LIST_A[5].shoplist[1] = ""	--

	--背景
	XUAN_SHOP_LIST_A[6] = {btn = XuanShop_Button6 , shoplist = {}}
	XUAN_SHOP_LIST_A[6].shoplist[1] = ""	--"";

	--前景
	XUAN_SHOP_LIST_A[7] = {btn = XuanShop_Button7 , shoplist = {}}
	XUAN_SHOP_LIST_A[7].shoplist[1] = ""	--"";

	--套装
	XUAN_SHOP_LIST_A[8] = {btn = XuanShop_Button8 , shoplist = {}}
	XUAN_SHOP_LIST_A[8].shoplist[1] = ""	--"";

	if XuanLastA ~= nil and XuanLastA > 0 and XuanLastA < 9 then
		XUAN_SHOP_LIST_A[XuanLastA].btn:SetCheck(1)
	end

	g_XuanShop_Frame_UnifiedXPosition	= XuanShop_Frame:GetProperty("UnifiedXPosition");
	g_XuanShop_Frame_UnifiedYPosition	= XuanShop_Frame:GetProperty("UnifiedYPosition");

	if g_IsEnableFanQuanShop == 0 then
		XuanShop_GiftToken:Hide()
	end
	--广告牌
	g_PlayCard_CtlButton[1] = XuanShop_ExButton1
	g_PlayCard_CtlButton[2] = XuanShop_ExButton2
	g_PlayCard_CtlButton[3] = XuanShop_ExButton3
	g_PlayCard_CtlButton[4] = XuanShop_ExButton4
	--XuanShop_Text:Hide()
	--XuanShop_Exgoumaiqueren:Hide()
	--XuanShop_Exgoumaiqueren_Text:Hide()

end

function XuanShop_OnEvent(event)

	if ( event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LEAVE_WORLD" or event == "TOGGLE_XUANSHOP") then
		IMDressCleanUpPayBox()
		XuanShop_Close_Clicked()
	end

	if event == "OPEN_IMDRESSPRESENT_YUANBAOSHOP" then
		if IsTBFinalServer() >= 1 then
			--总决赛特殊服务器不允许进行该操作
			PushDebugMessage("#{BHKF_150323_61}")
			return
		end	
		if (GetSceneID() == 77 or GetSceneID() == 578) then
			PushDebugMessage("#{IMXZ_20100919_104}")
			return;
		end
		if (Player:GetData("LEVEL") < 15) then
			PushDebugMessage("#{IMXZ_20100919_103}")
			return;
		end

		g_XuanTotalNum	= 0;
		local check  = tonumber(NpcShop:GetNotPayNotice());
		if(check>=1)then
			XuanShop_Notice1:SetCheck(1);
		else
			XuanShop_Notice1:SetCheck(0);
		end

		local check_PD = tonumber(NpcShop:GetPresentXuanDirectly());
		if( check_PD >= 1)then
			XuanShop_Notice2:SetCheck(1);
		else
			XuanShop_Notice2:SetCheck(0);
		end

		if( this:IsVisible() == false ) then
			--YubanbaoShop_ADRandom()
			if (IsWindowShow("YbMarket")) then
				CloseWindow("YbMarket", true);
			end
			if(IsWindowShow("DressClosetFrame")) then
				CloseWindow("DressClosetFrame", true);
			end

			if g_XuanShopName == "XuanShop" then
				local yuanbao_pos	= XuanShop_YuanBaoShop:GetProperty("AbsolutePosition");
				local bindyuanbao_pos	= XuanShop_BindYuanbaoShop:GetProperty("AbsolutePosition");
				local xuan_pos	= XuanShop_Xuanzhuang:GetProperty("AbsolutePosition");
				XuanShop_YuanBaoShop:SetProperty("AbsolutePosition", xuan_pos)
				XuanShop_Xuanzhuang:SetProperty("AbsolutePosition", yuanbao_pos)
				XuanShop_Xuanzhuang:SetProperty("AbsoluteSize", "w:120.000000 h:25.000000")
				XuanShop_Xuanzhuang:SetText("#{ZSGN_101129_39}")
			end

			XuanShop_Text:SetText("#{ZSGN_101129_04}")
			--XuanShop_Dis2:SetText("#{ZSGN_101129_05}")
			--XuanShop_Dis2:SetToolTip("#{ZSGN_101129_06}")
			XuanShop_PayBtn:SetText("#{ZSGN_101129_25}")
			XuanShop_VIP:Hide()
			XuanShop_Lijin:Hide()
		  XuanShop_YuanBaoShop:Hide()
			XuanShop_BindYuanbaoShop:Hide()
			XuanShop_GiftToken:Hide()
			XuanShop_Notice2:Show()
			XuanShop_Notice2:SetToolTip("#{ZSGN_101129_26}")
			XuanShop_Notice2_Text:Show()
			XuanShop_Present:Hide()

			g_XuanShopName = "PresentShop"
			NpcShop:SetIsXuanShopType(0)

			if arg0 ~= nil then
				g_Friendguid = arg0
				NpcShop:SetFriendID_PS(g_Friendguid)

				--判断不是好友
				local ret = IsMyFriend(g_Friendguid)
				if ret == -1 then
					PushDebugMessage("#{ZSGN_101129_24}");
					return
				end

				if g_Friendguid == "" then
					PushDebugMessage("#{ZSGN_101129_24}")
					return
				end

				g_Friendgroup, g_Friendindex = DataPool:GetFriendByGUID(g_Friendguid);
				if g_Friendgroup == nil or g_Friendindex == nil then
					PushDebugMessage("#{ZSGN_101129_24}")
					return
				end

				if g_Friendgroup == 0 or g_Friendindex == -1 then
					PushDebugMessage("#{ZSGN_101129_24}")
					return
				end

				g_FriendRace = DataPool:GetFriend( g_Friendgroup, g_Friendindex, "FACERACE"  )
				if g_FriendRace == -1 then
					PushDebugMessage("#{ZSGN_101129_24}")
					return
				end
			end

			XuanShop_Show();
			XuanShop_ADRandom();

			-- 在先打开NPC商店，后打开元宝商店的时候，存在一个问题
			-- 元宝商店在打开时会关闭已经打开的NPC商店，而关闭这个操作会将是否打开商店这个状态只为假，从而导致购买相关的逻辑出现错误
			-- 目前的解决办法是在Show的地方，设置是否打开商店的状态为真。
			OpenBooth();
		end

		--关心商人Obj
		XuanObjCared = NpcShop:GetNpcId();
		this:CareObject(XuanObjCared, 1, "XuanShop");

		NpcShop:CloseConfirm();
		PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
		--XuanShop_UpdatePage(1);

		if(IsWindowShow("Shop_Fitting")) then
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
			CloseWindow("Shop_Fitting", true);
		end
		if(IsWindowShow("Shop_Fitting2")) then
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
			CloseWindow("Shop_Fitting2", true);
		end
		SetDefaultMouse();
	end


	if event == "OPEN_IMDRESS_YUANBAOSHOP" then
		--PushDebugMessage("OPEN_IMDRESS_YUANBAOSHOP");
		if (GetSceneID() == 77 or GetSceneID() == 578) then
			PushDebugMessage("#{IMXZ_20100919_104}")
			return;
		end
		if (Player:GetData("LEVEL") < 15) then
			PushDebugMessage("#{IMXZ_20100919_103}")
			return;
		end

		g_XuanTotalNum	= 0;
		local check  = tonumber(NpcShop:GetNotPayNotice());
		if(check>=1)then
			XuanShop_Notice1:SetCheck(1);
		else
			XuanShop_Notice1:SetCheck(0);
		end
		--XuanShop_UpdateList(LAST_XUAN_TAG)
		if( this:IsVisible() == false ) then
			--YubanbaoShop_ADRandom()

			if (IsWindowShow("YbMarket")) then
				CloseWindow("YbMarket", true);
			end
			if(IsWindowShow("DressClosetFrame")) then
				CloseWindow("DressClosetFrame", true);
			end
			if(IsWindowShow("DuanWu_JiFenShop")) then
				CloseWindow("DuanWu_JiFenShop", true);
			end
			if (arg0 and arg0 == "3") then
				if (arg1 and arg2) then
					XuanShop_Frame:SetProperty("UnifiedXPosition", arg1);
					XuanShop_Frame:SetProperty("UnifiedYPosition", arg2);
				end
			end

			if g_XuanShopName == "PresentShop" then
				local yuanbao_pos	= XuanShop_YuanBaoShop:GetProperty("AbsolutePosition");
				local bindyuanbao_pos	= XuanShop_BindYuanbaoShop:GetProperty("AbsolutePosition");
				local xuan_pos	= XuanShop_Xuanzhuang:GetProperty("AbsolutePosition");
				XuanShop_YuanBaoShop:SetProperty("AbsolutePosition", xuan_pos)
				XuanShop_Xuanzhuang:SetProperty("AbsolutePosition", yuanbao_pos)
				XuanShop_Xuanzhuang:SetProperty("AbsoluteSize", "w:90.000000 h:25.000000")
				XuanShop_Xuanzhuang:SetText("#{IMXZ_20100813_07}")
			end

			XuanShop_Text:SetText("#{IMXZ_20100813_06}")
			--XuanShop_Dis2:SetText("#{IMXZ_20100813_33}")
			--XuanShop_Dis2:SetProperty("Tooltip", "");
			XuanShop_PayBtn:SetText("#{IMXZ_20100813_36}");
			XuanShop_YuanBaoShop:Show()
			XuanShop_VIP:Show()
			XuanShop_Lijin:Show()
			XuanShop_BindYuanbaoShop:Show()
			if g_IsEnableFanQuanShop == 1 then
				XuanShop_GiftToken:Show()
			end
			XuanShop_Notice2:Hide()
			XuanShop_Notice2_Text:Hide()
			XuanShop_Present:Show()

			g_XuanShopName = "XuanShop"
			NpcShop:SetIsXuanShopType(1)

			XuanShop_Show();
			XuanShop_ADRandom();

			-- 在先打开NPC商店，后打开元宝商店的时候，存在一个问题
			-- 元宝商店在打开时会关闭已经打开的NPC商店，而关闭这个操作会将是否打开商店这个状态只为假，从而导致购买相关的逻辑出现错误
			-- 目前的解决办法是在Show的地方，设置是否打开商店的状态为真。
			OpenBooth();
		end

		--关心商人Obj
		XuanObjCared = NpcShop:GetNpcId();
		this:CareObject(XuanObjCared, 1, "XuanShop");

		NpcShop:CloseConfirm();
		PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
		XuanShop_UpdatePage(1);

		if(IsWindowShow("Shop_Fitting")) then
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
			CloseWindow("Shop_Fitting", true);
		end
		if(IsWindowShow("Shop_Fitting2")) then
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
			CloseWindow("Shop_Fitting2", true);
		end
		SetDefaultMouse();
	elseif ( event == "UPDATE_BOOTH" ) then
		XuanShop_UpdatePage(nXuanPageNum);
	elseif (event == "CLOSE_BOOTH") then
		XuanShop_Close_Clicked()
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible() and g_XuanTabIndex == XuanShopTabIdx.IMDress) then
		XuanShop_YBNum : SetText( "#{YBSD_081225_068}"..tostring(Player:GetData("YUANBAO")))
--	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 888902) then
--		g_nTargetID = Get_XParam_INT( 0 )
--		if Get_XParam_INT( 1 ) ~= 0 and Get_XParam_INT( 2 ) ~= 0 then
--			XuanLastA = Get_XParam_INT( 1 )
--			XuanLastB = Get_XParam_INT( 2 )
--		end
--		XuanShop_Show()
	elseif( event == "ADJEST_UI_POS" ) then
		XuanShop_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		XuanShop_ResetPos()
	elseif( event == "UPDATE_MYSELF_IMDRESS" ) then
		XuanShop_ShowMyDress();
	elseif( event == "UPDATE_FRIEND_IMDRESS" ) then
		if arg0 ~= nil then
			XuanShop_ShowFriendDress(arg0);
		end
	elseif( event == "IMDRESS_CLEAN_SHOP_SELECTED" ) then
		--先清空所有的选中状态
		for _, item in XUAN_GOODS_BUTTONS do
			item:SetPushed(0);
		end
		for i = 0, 5 do
			XuanShopDressedItemID.Male[i] = -1;
			XuanShopDressedItemID.Female[i] = -1;

			XuanShopDressedItemID_BackUp.Male[i] = -1;
			XuanShopDressedItemID_BackUp.Female[i] = -1;
		end
	elseif (event == "GAMELOGIN_OPEN_SELECT_CHARACTOR") then
		XuanShop_ResetInfo()
	elseif ( event == "OPEN_JIYUAN_BOOTH" ) then
		XuanShop_UpdateJiYuanBooth()
	end
end
--更新机缘秘宝货架
function XuanShop_UpdateJiYuanBooth()
	local i = 1;
	while i <= GOODS_BUTTONS_JiYuan_NUM do
		local theAction = EnumAction(i - 1, "boothjiyuanitem");
		if theAction:GetID() ~= 0 then
			local IconKey = theAction:GetItemIconInShop_JiYuan()
			if IconKey ~= nil and IconKey ~= "" and IconTable[IconKey] ~= nil then
				GOODS_JiYuan_BUTTONS_ICON[i]:SetProperty("Image" , IconTable[IconKey])
			else
				GOODS_JiYuan_BUTTONS_ICON[i]:SetProperty("Image" , "")
			end

			GOODS_JiYuan_BUTTONS[i]:SetActionItem(theAction:GetID());
			if theAction:GetMaxNum() > 0 then
				GOODS_JiYuan_BUTTONS_Buy[i] : Show()
			else
				GOODS_JiYuan_BUTTONS_Buy[i] : Hide()
			end
			local	nPrice	= NpcShop:EnumItemPriceJiYuanBooth( i - 1 )
			GOODS_JiYuan_BAD[i]:SetText("#{YBSD_081225_101}" .. tostring(nPrice))

			if(theAction:GetItemColorInShop_JiYuan()~="") then
				GOODS_JiYuan_DESCS[i]:SetText( theAction:GetItemColorInShop_JiYuan()..theAction:GetName() );
			else
				GOODS_JiYuan_DESCS[i]:SetText( theAction:GetName() );
			end
			i = i+1;
		else
			GOODS_JiYuan_BUTTONS_ICON[i]:SetProperty("Image" , "")
			GOODS_JiYuan_BUTTONS[i]:SetActionItem(-1);
			GOODS_JiYuan_BUTTONS_Buy[i] : Hide()
			GOODS_JiYuan_DESCS[i]:SetText("");
			GOODS_JiYuan_BAD[i]:SetText("");
			i = i+1;
		end
	end
end
--==================
--打开商店
function XuanShop_Show()
	if IsZbsSpeicalServer() >= 1 then
		--争霸赛特殊服务器不允许进行该操作
		PushDebugMessage("#{ZBS16_170726_506}")
		return
	end
	
	if IsZbs2018SpeicalServer() >= 1 then
		--2018争霸赛特殊服务器不允许进行该操作
		PushDebugMessage("#{WCBS_180307_20}")
		return
	end

	if IsDfsSpeicalServer() >= 1 then
		PushDebugMessage("#{SJDF_190603_01}")
		return
	end
	
	if (IsWindowShow("YuanbaoShop")) then
		CloseWindow("YuanbaoShop", true);
	end
	--if XuanLastA < 1 or XuanLastA > 8 then
		XuanLastA = LAST_XUAN_TAG;
	--end
-- 		if IsInTServer() == 1 then
-- --			PushDebugMessage("#{BHKF_140909_327}")
-- 			return;
-- 		end	

	if (NpcShop:GetNotPayNotice() == 1) then
		XuanShop_Notice1:SetCheck(1)
	else
		XuanShop_Notice1:SetCheck(0)
	end

	local check_PD = tonumber(NpcShop:GetPresentXuanDirectly());
	if( check_PD >= 1)then
		XuanShop_Notice2:SetCheck(1);
	else
		XuanShop_Notice2:SetCheck(0);
	end

	g_XuanTabIndex = XuanShopTabIdx.IMDress;

	XuanLastSelect = 0;

	XUAN_SHOP_LIST_A[XuanLastA].btn:SetCheck(1)

	for i = 0, 5 do
		XuanShopFittingInfoBackup.Male[i] = XuanShopFittingDefaultInfo.Male[i]
		XuanShopFittingInfo.Male[i] = XuanShopFittingDefaultInfo.Male[i]

		XuanShopFittingInfoBackup.Female[i] = XuanShopFittingDefaultInfo.Female[i]
		XuanShopFittingInfo.Female[i] = XuanShopFittingDefaultInfo.Female[i]

		XuanShopDressedItemID.Male[i] = -1;
		XuanShopDressedItemID.Female[i] = -1;

		XuanShopDressedItemID_BackUp.Male[i] = -1;
		XuanShopDressedItemID_BackUp.Female[i] = -1;
	end


	local raceId
	--赠送炫装商城使用
	if g_XuanShopName == "PresentShop" then
		raceId = g_FriendRace;

		local fittingTable		= XuanShopFittingInfo.Female;
		local fittingTableBackup	= XuanShopFittingInfoBackup.Female;
		if raceId == 1 then
			fittingTable		= XuanShopFittingInfo.Male;
			fittingTableBackup	= XuanShopFittingInfoBackup.Male;
		end

		local anim = {};
		anim[0], anim[1], anim[2], anim[3], anim[4], anim[5] = DataPool:AskandGetFriendIMDress(g_Friendguid);
		for i = 0, 5 do
			if (anim[i] and anim[i] ~= "") then
				fittingTable[i]		= anim[i];
				fittingTableBackup[i]	= anim[i];
			end
		end

		for i = 0, 5 do
			if (fittingTable[i] and fittingTable[i] ~= "") then
				g_XuanShop_Dress[i]:SetProperty("Animate", fittingTable[i]);
				g_XuanShop_Dress[i]:Play(true);
			else
			 	g_XuanShop_Dress[i]:Play(false);
			end
		end

		--XuanShop_ShowFriendDress(g_Friendguid);
	else
		raceId = GetMySelfRaceId();

		local fittingTable		= XuanShopFittingInfo.Female;
		local fittingTableBackup	= XuanShopFittingInfoBackup.Female;
		if raceId == 1 then
			fittingTable		= XuanShopFittingInfo.Male;
			fittingTableBackup	= XuanShopFittingInfoBackup.Male;
		end

		local anim = {};
		anim[0], anim[1], anim[2], anim[3], anim[4], anim[5] = DataPool:GetMySelfIMDress();
		for i = 0, 5 do
			if (anim[i] and anim[i] ~= "") then
				fittingTable[i]		= anim[i];
				fittingTableBackup[i]	= anim[i];
			end
		end

		XuanShop_ShowMyDress();
	end

	IMDressCleanUpPayBox();

	if raceId == 0 then 	--female
		XuanLastB = 1;
		XuanShop_fittingFrame_Bt3:Hide();
		XuanShop_fittingFrame_Bt2:Show();
		XuanShop_UpdateShopItem( XuanLastA+300 , XuanLastB );
	else			--male
		XuanLastB = 2;
		XuanShop_fittingFrame_Bt2:Hide();
		XuanShop_fittingFrame_Bt3:Show();
		XuanShop_UpdateShopItem( XuanLastA+300 , XuanLastB )
	end

	XuanShop_YuanBaoShop : SetCheck(0)
	XuanShop_VIP : SetCheck(0)
	XuanShop_Lijin: SetCheck(0)
	XuanShop_BindYuanbaoShop : SetCheck(0)
	XuanShop_GiftToken : SetCheck(0)
	XuanShop_Xuanzhuang : SetCheck(1)
	--XuanShop_ChangeTabIndex( 0 )
	--广告牌，默认选择第一页
	XuanShop_PlayCardChangePage(1)
	--请求机缘秘宝商店
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OpenJiYuanShop");
		Set_XSCRIPT_ScriptID(888902);
		Set_XSCRIPT_Parameter(0,g_nTargetID);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
	this:Show();
end
--===============================
--刷新一页
function XuanShop_UpdatePage(thePage)

	XuanShop_YBNum : SetText( "#{YBSD_081225_068}"..tostring(Player:GetData("YUANBAO")) )

	for i=1, XUAN_GOODS_BUTTONS_NUM  do
		XUAN_GOOD_BAD[i]:Show()
	end

	local	i = 1;

	if g_XuanTotalNum == 0 or g_XuanTotalNum ~= GetActionNum("boothitem") then
		g_XuanTotalNum	= GetActionNum("boothitem");
		XuanShop_Order();
	end

	-- 计算总页数
	local	nTotalPage;
	if( g_XuanTotalNum < 1 ) then
		nTotalPage	= 1;
	else
		nTotalPage	= math.floor((g_XuanTotalNum-1)/XUAN_GOODS_BUTTONS_NUM)+1;
	end

	maxXuanPage = nTotalPage;

	if(thePage < 1 or thePage > nTotalPage) then
		return;
	end
	--HEQUIP_DRESS		=16,	//时装
	--HEQUIP_RIDER		=8,	//骑乘
	local bHaveRide=0;

	local dressedTable = XuanShopDressedItemID.Female;
	local raceId = XuanLastB - 1;
	if raceId == 1 then
		dressedTable = XuanShopDressedItemID.Male;
	end

	nXuanPageNum = thePage;
	XuanCurPage = thePage;

	local nStartIndex = (thePage-1)*XUAN_GOODS_BUTTONS_NUM;

	local nActIndex = nStartIndex;
	i = 1;
	while i <= XUAN_GOODS_BUTTONS_NUM do
		local	idx	= g_XuanOrderPool[nActIndex+1];
		if idx == nil then
			idx	= -1;
		end

		local theAction = EnumAction(idx, "boothitem");
		if theAction:GetID() ~= 0 then
			local IconKey = theAction:GetItemIconInShop()
			if IconKey ~= nil and IconKey ~= "" and  IconTable[IconKey] ~= nil then
				XUAN_GOODS_BUTTONS_ICON[i]:SetProperty("Image" , IconTable[IconKey])
			else
				XUAN_GOODS_BUTTONS_ICON[i]:SetProperty("Image" , "")
			end
			XUAN_GOODS_BUTTONS[i]:SetActionItem(theAction:GetID());
			if(theAction:GetItemColorInShop()~="") then
				XUAN_GOODS_DESCS[i]:SetText( theAction:GetItemColorInShop()..theAction:GetName() );
			else
				XUAN_GOODS_DESCS[i]:SetText( theAction:GetName() );
			end

			local	nPrice	= NpcShop:EnumItemPrice( idx )

			XUAN_GOOD_BAD[i]:SetText("#{YBSD_081225_101}" .. tostring(nPrice))

			XUAN_GOODS_BUTTONS[i]:SetPushed(0);

			local itemTableIndex = IMGetItemTableIndex(idx, "boothitem")
			for dsp = 0, table.getn(dressedTable) do
				--PushDebugMessage(""..dsp)
				if (dressedTable[dsp] and dressedTable[dsp] ~= -1 and dressedTable[dsp] == itemTableIndex) then
					XUAN_GOODS_BUTTONS[i]:SetPushed(1);
					--PushDebugMessage(""..i)
					break
				end
			end

			i = i+1;
		else
			XUAN_GOODS_BUTTONS_ICON[i]:SetProperty("Image" , "")
			XUAN_GOODS_BUTTONS[i]:SetActionItem(-1);
			XUAN_GOODS_DESCS[i]:SetText("");
			XUAN_GOOD_BAD[i]:SetText("");
			i = i+1;
		end
		nActIndex = nActIndex+1;
	end

	if( nTotalPage == 1 ) then
		XuanShop_UpPage:Hide();
		XuanShop_DownPage:Hide();
		XuanShop_CurrentlyPage:Hide();
	else
		XuanShop_UpPage:Show();
		XuanShop_DownPage:Show();
		XuanShop_CurrentlyPage:Show();

		XuanShop_UpPage:Enable();
		XuanShop_DownPage:Enable();

		if ( nXuanPageNum == nTotalPage ) then
			XuanShop_DownPage:Disable();
		end

		if ( nXuanPageNum == 1 ) then
			XuanShop_UpPage:Disable()
		end

		XuanShop_CurrentlyPage:SetText(tostring(nXuanPageNum) .. "/" .. tostring(nTotalPage) );
	end
end
--点击一级标签
function XuanShop_UpdateList(nIndex)
	LAST_XUAN_TAG = nIndex
	--PushDebugMessage("XuanShop_UpdateList:"..nIndex);
	if nIndex <1 or nIndex > 8 or ( nIndex == XuanLastA and g_XuanChangeTabFlag == 0 ) then
		return
	end

	XuanLastA = nIndex
	XuanLastSelect = 0
	XUAN_SHOP_LIST_A[nIndex].btn:SetCheck(1)
	XuanShop_UpdateShopItem( XuanLastA+300 ,XuanLastB )
end

function XuanShop_ChangeRaceID(nIndex)
	if nIndex <1 or nIndex > 2 then
		return
	end
	if IsTBFinalServer() >= 1 then
		--总决赛特殊服务器不允许进行该操作
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end	
	XuanLastB = nIndex

	if XuanLastA > 0 and XuanLastA < 9 then
		XuanShop_UpdateShopItem( XuanLastA+300 , XuanLastB )
	else
		XuanShop_UpdateShopItem( 301 , XuanLastB)
	end

	local raceId = XuanLastB - 1;
	local tempTable = XuanShopFittingInfo.Female;
	if raceId == 1 then
		tempTable = XuanShopFittingInfo.Male;
	end

	for i = 0, 5 do
		if tempTable[i] ~= nil and tempTable[i] ~= "" then
			g_XuanShop_Dress[i]:SetProperty("Animate", tempTable[i]);
			g_XuanShop_Dress[i]:Play(true);
		else
			g_XuanShop_Dress[i]:Play(false);
		end
	end

	if raceId == 0 then
		--female
		XuanShop_fittingFrame_Bt3:Hide();
		XuanShop_fittingFrame_Bt2:Show();
	else
		--male
		XuanShop_fittingFrame_Bt2:Hide();
		XuanShop_fittingFrame_Bt3:Show();
	end
end

--设置菜单的显示属性
function XuanShop_UpdateVisiableProperty(shopAList, shopBList, searchList, XuanLastA, XuanLastB, XuanLastSelect)

	if (shopAList == nil or shopBList == nil or searchList == nil) then
		return
	end

	local findA = 0

	for i=1, table.getn(shopAList) do
		if (table.getn(shopAList[i].shoplist) > 0) then
			shopAList[i].btn : Show()
			if (i == XuanLastA) then
				findA = i
			end
		else
			shopAList[i].btn : Hide()
		end
	end
end

function XuanShop_ChangeTabIndex( nIndex )
	nIndex = nIndex - 1
	if (nIndex == XuanShopTabIdx.GiftToken and g_IsEnableFanQuanShop == 0) then --关闭返券商店
		return
	end

	if ( nIndex == XuanShopTabIdx.IMDress ) then
		return
	end
	
	if ( nIndex == XuanShopTabIdx.Show ) then
		return
	end
	
	local ret = IMDressLoadPayBox();
	if (ret and ret > 0) then
		if (NpcShop:GetNotPayNotice() == 1) then
			PushEvent("IMSHOP_NOTPAY_CONFIRM", "XuanShop" ,tostring(nIndex), XuanShop_Frame:GetProperty("UnifiedXPosition"), XuanShop_Frame:GetProperty("UnifiedYPosition"));
			XuanShop_YuanBaoShop : SetCheck(0)
			XuanShop_VIP : SetCheck(0)
			XuanShop_BindYuanbaoShop : SetCheck(0)
			XuanShop_GiftToken : SetCheck(0)
			XuanShop_Lijin:SetCheck(0)
			XuanShop_Xuanzhuang : SetCheck(1)
			return
		end
	end

	IMDressCleanUpPayBox();
	--XuanShop_Close_Clicked();
	XuanShop_OpenYuanbaoShop(nIndex);

end

--请求商店信息
function XuanShop_UpdateShopItem( shopA , shopB)

	--PushDebugMessage("shopA:"..shopA..",shopB:"..shopB );
	g_XuanChangeTabFlag = 0

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OpenYuanbaoShop");
		Set_XSCRIPT_ScriptID(888902);
		Set_XSCRIPT_Parameter(0,g_nTargetID);
		Set_XSCRIPT_Parameter(1,shopA);
		Set_XSCRIPT_Parameter(2,shopB);
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT();
end
--===============================================
-- Button_Clicked
--===============================================
function XuanShop_GoodButton_Clicked(nIndex)
	if(nIndex < 1 or nIndex > 24) then
		return;
	end
	local buttonIndex = nIndex;
	nIndex = nIndex + (nXuanPageNum-1)*XUAN_GOODS_BUTTONS_NUM
	local dressPoint, animate = IMDressGetDressInfo(nIndex-1, "boothitem")
	if dressPoint == nil or animate == nil or (dressPoint < 0 or dressPoint > table.getn(g_XuanShop_Dress)) then
		return
	end

	local tableIndex = IMGetItemTableIndex(nIndex-1, "boothitem")
	--根据性别获取缓存数据
	local dressedTable = XuanShopDressedItemID.Female;
	local tempTable = XuanShopFittingInfo.Female;
	local defaultTable = XuanShopFittingDefaultInfo.Female;

	local raceId = XuanLastB - 1;
	if raceId == 1 then
		dressedTable = XuanShopDressedItemID.Male;
		tempTable = XuanShopFittingInfo.Male;
		defaultTable = XuanShopFittingDefaultInfo.Male;
	end

	local ret = XuanShop_UpdageGoodButtonPushedState(dressPoint, tableIndex, dressedTable, buttonIndex)
	if (ret == -1) then
		return
	end

	if (ret == 1) then
		--穿上一件新的
		--判断是不是套装
		if (dressPoint == g_XuanShop_DressPoint.Suit) then
			--是套装，先清空所有身上的衣服
			XuanShop_ShowDefault();
			if ( g_XuanShopName == "XuanShop" and raceId == GetMySelfRaceId() ) or
				 ( g_XuanShopName == "PresentShop" and raceId == g_FriendRace   ) then
					IMDressCleanUpPayBoxOnly();
			end

			XuanShop_UpdageGoodButtonPushedState(dressPoint, tableIndex, dressedTable, buttonIndex);
		else
			--不是套装，隐藏套装的控件
			local suitPoint = g_XuanShop_DressPoint.Suit

			--脱掉套装
			g_XuanShop_Dress[suitPoint]:Play(false);
			if ( g_XuanShopName == "XuanShop" and raceId == GetMySelfRaceId() ) or
				 ( g_XuanShopName == "PresentShop" and raceId == g_FriendRace   ) then
					IMClearFromPayBox(suitPoint)
		  end

			tempTable[suitPoint] = ""
		end

		--执行换装逻辑
		g_XuanShop_Dress[dressPoint]:SetProperty("Animate", animate)
		g_XuanShop_Dress[dressPoint]:Play(true);

		tempTable[dressPoint] = animate;

		if ( g_XuanShopName == "XuanShop" and raceId == GetMySelfRaceId() ) or
			 ( g_XuanShopName == "PresentShop" and raceId == g_FriendRace   ) then
				local savePos = dressPoint;
				IMSaveToPayBox(savePos, nIndex-1, "boothitem");
		end
	elseif (ret == 0) then
		--脱掉一件旧的
		tempTable[dressPoint] = defaultTable[dressPoint];
		if (tempTable[dressPoint] == nil or tempTable[dressPoint] == "") then
			g_XuanShop_Dress[dressPoint]:Play(false);
		else
			g_XuanShop_Dress[dressPoint]:SetProperty("Animate", tempTable[dressPoint])
			g_XuanShop_Dress[dressPoint]:Play(true);
		end

		if ( g_XuanShopName == "XuanShop" and raceId == GetMySelfRaceId() ) or
			 ( g_XuanShopName == "PresentShop" and raceId == g_FriendRace   ) then
			IMClearFromPayBox(dressPoint);
		end
	end
end

function XuanShop_UpdageGoodButtonPushedState(dressPoint, itemTableIndex, itemTable, buttonIndex)
	if itemTableIndex == nil or itemTableIndex < 0 then
		return -1
	end
	--判断是穿还是脱
	if (itemTable[dressPoint] ~= itemTableIndex) then
		--穿上一件新的
		--是不是套装
		if (dressPoint == g_XuanShop_DressPoint.Suit) then
			--先清空所有的选中状态
			for _, item in XUAN_GOODS_BUTTONS do
				item:SetPushed(0);
			end

			for i = 0, table.getn(itemTable) do
				if (i ~= g_XuanShop_DressPoint.Suit) then
					itemTable[i] = -1
				end
			end
		else
			--不是套装
			local bCleanUpSuit = 0
			local startIndex = (nXuanPageNum-1)*XUAN_GOODS_BUTTONS_NUM
			for i, item in XUAN_GOODS_BUTTONS do
				local tblIdx = IMGetItemTableIndex(i+startIndex-1, "boothitem")
				if (tblIdx) then
					--更新对应点的服装
					if (itemTable[dressPoint] ~= -1) then
						if (itemTable[dressPoint] == tblIdx) then
							item:SetPushed(0);
							itemTable[dressPoint] = -1;
						end
					end
					--更新套装
					local curSuit = itemTable[g_XuanShop_DressPoint.Suit];
					if (curSuit ~= -1) then
						if (curSuit == tblIdx) then
							item:SetPushed(0);
						end
						bCleanUpSuit = 1
					end
				end
			end

			if (bCleanUpSuit == 1) then
				itemTable[g_XuanShop_DressPoint.Suit] = -1
			end
		end
		--把新的穿上
		XUAN_GOODS_BUTTONS[buttonIndex]:SetPushed(1);
		itemTable[dressPoint] = itemTableIndex;
		return 1
	else
		--脱掉一个旧的
		XUAN_GOODS_BUTTONS[buttonIndex]:SetPushed(0);
		itemTable[dressPoint] = -1;
		return 0
	end
end
--===============================================
-- PageUp
--===============================================
function XuanShop_PageUp()
	XuanCurPage = nXuanPageNum - 1;
	if ( XuanCurPage < 0 )  then
		XuanCurPage = 0;
	end
	NpcShop:CloseConfirm();
	PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
	XuanShop_UpdatePage( XuanCurPage );
end

--===============================================
-- PageDown
--===============================================
function XuanShop_PageDown()
	XuanCurPage = nXuanPageNum + 1;
	if ( XuanCurPage >= maxXuanPage ) then
		XuanCurPage = maxXuanPage;
	end
	NpcShop:CloseConfirm();
	PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
	XuanShop_UpdatePage( XuanCurPage );
end

--===============================================
-- Close
--===============================================
function XuanShop_Close_Clicked()
	local ret = IMDressLoadPayBox();
	if (ret and ret > 0) then
		if (NpcShop:GetNotPayNotice() == 1) then
			if g_XuanShopName == "XuanShop" then
				PushEvent("IMSHOP_NOTPAY_CONFIRM", "XuanShop", "-1");
			end
			if g_XuanShopName == "PresentShop" then
				PushEvent("IMSHOP_NOTPAY_CONFIRM", "PresentShop", "-1", g_Friendguid);
			end
			return
		end
	end

	g_nTargetID = -1
	this:CareObject(XuanObjCared, 0, "XuanShop");
	if(IsWindowShow("Shop_Fitting")) then
		CloseWindow("Shop_Fitting", true);
	end
	if(IsWindowShow("Shop_Fitting2")) then
		RestoreShopFitting(TOTALFITTINGKIND_NUM);
		CloseWindow("Shop_Fitting2", true);
	end
	if(IsWindowShow("YBShopReference")) then
		CloseWindow("YBShopReference",true)
	end
	if(IsWindowShow("XuanPayed")) then
		CloseWindow("XuanPayed",true)
	end
	if (IsWindowShow("MessageBox_Other")) then
		CloseWindow("MessageBox_Other", true);
	end

	SetDefaultMouse();
	CloseBooth();
	NpcShop:CloseConfirm();
	PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
	RestoreShopFitting(TOTALFITTINGKIND_NUM);
	KillTimer("XuanShop_PlayCardTimer()")
	IMDressCleanUpPayBox();
	this:Hide();
end

--随机排序
function XuanShop_Order()
	local	max	= g_XuanTotalNum;
	local oldt	= {};
	g_XuanOrderPool= {};

	for i = 1, tonumber(max) do
	  oldt[i] = i-1;
	end

	if tonumber(NpcShop:GetIsShopReorder()) == 0 then
		g_XuanOrderPool		= oldt;
	else
		for i = 1, table.getn(oldt) do
		 local idx	= math.random(1, table.getn(oldt));
		 local val	= oldt[idx];
		 g_XuanOrderPool[i]= val;
		 table.remove(oldt, idx);
		end
	end
end

--确认按钮
function XuanShop_NotPayNotice_Clicked()
	if(NpcShop:GetNotPayNotice() < 1)then
		NpcShop:SetNotPayNotice(1);
--		XuanShop_Notice1:SetCheck(1);
	else
		NpcShop:SetNotPayNotice(0);
--		XuanShop_Notice1:SetCheck(0);
	end
end

--赠送商城购买提示按钮
function XuanShop_PresDirectly_Clicked()
	if(NpcShop:GetPresentXuanDirectly() < 1)then
		NpcShop:SetPresentXuanDirectly(1);
		--XuanShop_Notice2:SetCheck(1);
	else
		NpcShop:SetPresentXuanDirectly(0);
		--XuanShop_Notice2:SetCheck(0);
	end
end

--确认按钮
function XuanShop_querenzhifu_Clicked()
	if(NpcShop:GetUseYBForBind() == 0)then
		NpcShop:SetUseYBForBind(1)
	else
		NpcShop:SetUseYBForBind(0)
	end
end

--快速充值
function XuanShop_web_Clicked()
	Chongzhi()
	--GameProduceLogin:OpenURL(GetWeblink("WEB_LOGON_MAIN"))
end
--目录和查找说明
function XuanShop_Dis_Clicked()
	OpenYBShopReference("#{YBSD_081225_070}")
end
--炫装商店使用说明
function XuanShop_Dis2_Clicked()
 	if g_XuanShopName	== "PresentShop" then
 		OpenYBShopReference("#{ZSGN_101129_07}")
 	elseif g_XuanShopName	== "XuanShop" then
 		OpenYBShopReference("#{IMXZ_20100813_34}")
 	end
end
--神秘商店使用说明
function XuanShop_Dis3_Clicked()
	OpenYBShopReference("#{SMSD_100127_01}")
end

--滚动信息顺序随机排列
function XuanShop_ADRandom()
	XuanShop_ScrollInfo_Frame:ClearInfo()

	local ADInfo = {
				"#{YBSD_081225_093}",
				"#{YBSD_081225_094}",
				"#{YBSD_081225_095}",
			}
	local nADInfoNum = table.getn(ADInfo)
	if (nil == nADInfoNum or nADInfoNum < 1 or nADInfoNum > 3) then
		nADInfoNum = 3
	end

	for i = 0 ,1 do
		local idx = math.random(1 ,nADInfoNum - i)
		local str = ADInfo[idx]
		ADInfo[idx] = ADInfo[nADInfoNum - i]
		ADInfo[nADInfoNum - i] = str
	end

	for i = 1 ,nADInfoNum do
		XuanShop_ScrollInfo_Frame:SetScrollInfoFixed(ADInfo[i],"1")
	end

end

function XuanShop_ResetPos()
	XuanShop_Frame:SetProperty("UnifiedXPosition", g_XuanShop_Frame_UnifiedXPosition);
	XuanShop_Frame:SetProperty("UnifiedYPosition", g_XuanShop_Frame_UnifiedYPosition);

end

function XuanShop_OpenYuanbaoShop(index)
	--if ( index == XuanShopTabIdx.Show ) then
	--	PushEvent("OPEN_SHOWCREDITSHOP", tostring(index), XuanShop_Frame:GetProperty("UnifiedXPosition"), XuanShop_Frame:GetProperty("UnifiedYPosition"))
	--else
		PushEvent("TOGGLE_YUANBAOSHOP", tostring(index), XuanShop_Frame:GetProperty("UnifiedXPosition"), XuanShop_Frame:GetProperty("UnifiedYPosition"), -1 ,-1);
	--end
end

function IsMyFriend(Friendguid)
		--如果没有这个人
		if Friendguid == nil or Friendguid == "" then
			return -1
		end

		local Friendgroup, Friendindex = DataPool:GetFriendByGUID(Friendguid);
		if Friendgroup == nil or Friendindex == nil then
			return -1
		end

		if Friendgroup == 0 or Friendindex == -1 then
			return -1
		end

		--如果不是好友
		local friendRelationType = DataPool:GetFriend( Friendgroup, Friendindex, "RELATION_TYPE"  )
			--只有好友可以赠送
		if friendRelationType == 0  or friendRelationType == 4  or friendRelationType == 5 or
		   friendRelationType == 6  or friendRelationType == 9 then
			return -1
		end

		return 1
end

function XuanShop_PayMoney_Clicked()
	local raceId = XuanLastB - 1;
	if g_XuanShopName == "XuanShop" then
		if (raceId ~= GetMySelfRaceId()) then
			PushDebugMessage("#{IMXZ_20100813_38}");
			return
		end
	end

	if g_XuanShopName == "PresentShop" then

		local ret = IsMyFriend(g_Friendguid)
		if ret == -1 then
			PushDebugMessage("#{ZSGN_101129_24}");
			return
		end

		if (raceId ~= g_FriendRace) then
			PushDebugMessage("#{ZSGN_101129_22}");
			return
		end
	end

	local ret = IMDressLoadPayBox();
	if (ret and ret > 0) then
		if g_XuanShopName == "XuanShop" then
			PushEvent("OPEN_IMDRESS_PAYED","XuanShop")
		end
		if g_XuanShopName == "PresentShop" then
		  --发包赠送物品
      if(NpcShop:GetPresentXuanDirectly() == 1)then
        PushEvent("CONFIRM_IMDRESS_BUYTOOTHER","open", "PresentShop", g_Friendguid)
      	return
      end
			PushEvent("OPEN_IMDRESS_PAYED","PresentShop", g_Friendguid)
		end
	else
		PushDebugMessage("#{IMXZ_20100813_37}");
	end
end

function XuanShop_ShowDefault()

	local raceId = XuanLastB - 1;

	if raceId == 1 then
		--male
		for i = 0, 5 do
			XuanShopFittingInfo.Male[i] = XuanShopFittingDefaultInfo.Male[i]
			XuanShopDressedItemID.Male[i] = -1;
		end
	else
		--female
		for i = 0, 5 do
			XuanShopFittingInfo.Female[i] = XuanShopFittingDefaultInfo.Female[i]
			XuanShopDressedItemID.Female[i] = -1;
		end
	end

	local tempTable = XuanShopFittingInfo.Female;
	if raceId == 1 then
		tempTable = XuanShopFittingInfo.Male;
	end

	for i = 0, 5 do
		if tempTable[i] ~= nil and tempTable[i] ~= "" then
			g_XuanShop_Dress[i]:SetProperty("Animate", tempTable[i]);
			g_XuanShop_Dress[i]:Play(true);
		else
			g_XuanShop_Dress[i]:Play(false);
		end
	end

	if (raceId == GetMySelfRaceId()) then
		IMDressCleanUpPayBoxOnly();
	end

	XuanShop_UpdatePage(XuanCurPage);
end

function XuanShop_OpenIMDressChest()
	SendAskIMDressChestPacket()
end

function XuanShop_SaveFitting()
	local tempTable = XuanShopFittingInfo.Female;
	local tempTableBackup = XuanShopFittingInfoBackup.Female;
	local dressedTable = XuanShopDressedItemID.Female;
	local dressedTableBackup = XuanShopDressedItemID_BackUp.Female;

	local raceId = XuanLastB - 1;
	if raceId == 1 then
		tempTable = XuanShopFittingInfo.Male;
		tempTableBackup = XuanShopFittingInfoBackup.Male;
		dressedTable =  XuanShopDressedItemID.Male;
		dressedTableBackup = XuanShopDressedItemID_BackUp.Male;
	end

	for i = 0, 5 do
		tempTableBackup[i] = tempTable[i];
		dressedTableBackup[i] = dressedTable[i];
	end

	if raceId == GetMySelfRaceId() then
		IMDressSavePayBoxToBackup();
	end
end

function XuanShop_LoadFitting()
	local tempTable = XuanShopFittingInfo.Female;
	local tempTableBackup = XuanShopFittingInfoBackup.Female;
	local dressedTable = XuanShopDressedItemID.Female;
	local dressedTableBackup = XuanShopDressedItemID_BackUp.Female;

	local raceId = XuanLastB - 1;
	if raceId == 1 then
		tempTable = XuanShopFittingInfo.Male;
		tempTableBackup = XuanShopFittingInfoBackup.Male;
		dressedTable =  XuanShopDressedItemID.Male;
		dressedTableBackup = XuanShopDressedItemID_BackUp.Male;
	end

	for i = 0, 5 do
		tempTable[i] = tempTableBackup[i];
		dressedTable[i] = dressedTableBackup[i];

		g_XuanShop_Dress[i]:Play(false);
		if tempTable[i] ~= nil and tempTable[i] ~= "" then
			g_XuanShop_Dress[i]:SetProperty("Animate", tempTable[i]);
			g_XuanShop_Dress[i]:Play(true);
		end
	end

	if raceId == GetMySelfRaceId() then
		IMDressLoadPayBoxFromBackup();
	end

	XuanShop_UpdatePage( XuanCurPage );
end

function XuanShop_ShowMyDress()
	if g_XuanShopName ~= "XuanShop" then
		return
	end
	local anim = {};
	anim[0], anim[1], anim[2], anim[3], anim[4], anim[5] = DataPool:GetMySelfIMDress();

	for i = 0, 5 do
		if anim[i] ~= nil and anim[i] ~= "" then
			g_XuanShop_Dress[i]:SetProperty("Animate", anim[i]);
			g_XuanShop_Dress[i]:Play(true);
		else
			g_XuanShop_Dress[i]:Play(false);
		end
	end
end


function XuanShop_ShowFriendDress(FriendGuid)
	if g_XuanShopName ~= "PresentShop" or FriendGuid ~= g_Friendguid then
		return
	end
	local anim = {};
	anim[0], anim[1], anim[2], anim[3], anim[4], anim[5] = DataPool:GetFriendIMDress(FriendGuid);

	for i = 0, 5 do
		if anim[i] ~= nil and anim[i] ~= "" then
			g_XuanShop_Dress[i]:SetProperty("Animate", anim[i]);
			g_XuanShop_Dress[i]:Play(true);
		else
			g_XuanShop_Dress[i]:Play(false);
		end
	end
end

function XuanShop_Present_Clicked()
	if IsInTServer() == 1 then
		PushDebugMessage("#{BHKF_140909_327}")
		return
	end
	local ret = IMDressLoadPayBox();
	if (ret and ret > 0) then
		--如果购物车里有东西，并且需要提示
		if (NpcShop:GetNotPayNotice() == 1) then
			PushEvent("IMSHOP_NOTPAY_CONFIRM", "XuanShop", "XuanPresent_ChooseFriend");
			return
		end
	end
	CloseWindow("XuanShop",true)
	if IsWindowShow("XuanPresent_ChooseFriend") then
		CloseWindow("XuanPresent_ChooseFriend")
	end
	PushEvent("OPEN_XUANPRESENT_CHOOSEFRIEND", "XuanGift")
end

function XuanShop_ResetInfo()
	LAST_XUAN_TAG = 1;
end

--机缘秘宝购买物品
function XuanShop_JiYuanGood_Clicked(nIndex)
	if(nIndex < 1 or nIndex > 6) then
		return;
	end
	local theAction = EnumAction(nIndex - 1, "boothjiyuanitem");
	if theAction:GetID() == 0 then
		return
	end
	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	--if IsIdleLogic() ~= 1 then
	--	SetNotifyTip("#{YBSD_081225_100}");
	--	return 0;
	--end
	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	--if NpcShop:BuyItemWithOutConfirm() > 0 then
	--	NpcShop:BuyItemFromJiYuanShop(nIndex - 1, 1)
	--else
		PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "open", nIndex - 1)
	--end
end

function XuanShop_PlayCardChangePage(nPageNum)
	g_PlayCard_CurPage = nPageNum
	if nPageNum <= 0 or nPageNum > g_PlayCard_MaxPage then
		return
	end
	XuanShop_Image:SetProperty("NormalImage", g_PlayCard_Image[nPageNum])
	XuanShop_Image:SetProperty("HoverImage", g_PlayCard_Image[nPageNum])
	XuanShop_Image:SetProperty("DisabledImage", g_PlayCard_Image[nPageNum])
	XuanShop_Image:SetProperty("PushedImage", g_PlayCard_Image[nPageNum])
	g_PlayCard_CtlButton[nPageNum]:SetCheck(1)
	KillTimer("XuanShop_PlayCardTimer()")
	SetTimer("XuanShop", "XuanShop_PlayCardTimer()", 5000)
end

function XuanShop_PlayCardTimer()
	g_PlayCard_CurPage = g_PlayCard_CurPage + 1
	if g_PlayCard_CurPage > g_PlayCard_MaxPage then
		g_PlayCard_CurPage = 1
	end
	XuanShop_PlayCardChangePage(g_PlayCard_CurPage)
end

function XuanShop_ImageClicked()
	if g_PlayCard_URL[g_PlayCard_CurPage] ~= nil then
		GameProduceLogin:OpenURL(GetWeblink(g_PlayCard_URL[g_PlayCard_CurPage]))
	end
end

function XuanShop_DuiHuanClicked()
	local bflg =YuanbaoExange()
	if bflg~= 1 then
		return ;
	end
	Clear_XSCRIPT();
	Set_XSCRIPT_Function_Name("AskOpenDuihuanWindow");
	Set_XSCRIPT_ScriptID(181000);
	--Set_XSCRIPT_Parameter(2,shopB);
	Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end
