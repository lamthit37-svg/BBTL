local TOTALFITTINGKIND_NUM = 10;
local GOODS_BUTTONS_JiYuan_NUM = 6;
local GOODS_JiYuan_BUTTONS = {};
local GOODS_JiYuan_BUTTONS_Buy = {};
local GOODS_JiYuan_DESCS = {};
local GOODS_JiYuan_BAD    = {};

local GOODS_BUTTONSRECENTLY_NUM = 5;
local GOODSRECENTLY_BUTTONS = {};
local GOODSRECENTLY_DESCS = {};
local GOODSRECENTLY_BAD    = {};

local GOODS_BUTTONS_NUM = 18;
local GOODS_BUTTONS = {};
local GOODS_DESCS = {};
local GOOD_BAD    = {};
local LAST_FENYE = 0;
local LAST_TAG   = 1;
local LAST_SHOP  = 1;
local g_nTargetID = -1
--标签页索引值
local ShopTabIdx = {
	YuanBao 	= 0,	--元宝商店
	Bind		= 1,	--绑定元宝商店
	GiftToken	= 2,	--返券商店
	IMDress		= 3,
	VipShop		= 4,
	Lijin     = 5,  --通宝商店
	Xiuchang	=6,		--秀场商店
}
local GOODS_BUTTONS_ICON = {}
local GOODS_JiYuan_BUTTONS_ICON = {};
--设置经典版使用的图标资源
local IconTable = {
	["H"] = "set:CommonFrame20 image:Item_Hot",
	["S"] = "set:CommonFrame20 image:Item_Special",
	["A"] = "set:CommonFrame20 image:Item_Activity",
	["D"] = "set:CommonFrame20 image:Item_Discount",
	["N"] = "set:CommonFrame20 image:Item_New",
	["L"] = "set:CommonFrame20 image:Item_Limit",
}
local g_Max_Vip_Level = 9
local g_Min_ShowBaoShiGe_VipLevel = -1 --策划改了需求，任何vip等级都可以看到了

local SHOP_LIST_A = {};
local SHOP_LIST_B = {};
local SHOP_SEARCH_LIST ={};

local SHOP_LIST_A_BIND = {};
local SHOP_LIST_B_BIND = {};
local SHOP_SEARCH_LIST_BIND ={};

local SHOP_LIST_A_GIFTTOKEN = {};		--货币类型下的一级菜单 如 大卖场 宝石商城等
local SHOP_LIST_B_GIFTTOKEN = {};		--货币类型下的二级菜单 如 新品上架 等
local SHOP_SEARCH_LIST_GIFTTOKEN ={};		--搜索菜单

local SHOP_LIST_A_VIP = {};
local SHOP_LIST_B_VIP = {};
local SHOP_SEARCH_LIST_VIP ={};
local g_nDistanceBBtnY = 0;

local SHOP_LIST_A_LIJIN = {};		--通宝挪过来了
local SHOP_LIST_B_LIJIN = {};
local SHOP_SEARCH_LIST_LIJIN ={};

local nPageNum = 1;
local maxPage = 1;
local objCared = -1;
local lastA = 0			--打开页面元宝商店下最后点击的tag
local lastB = 0			--打开页面元宝商店下最后点击的shop
local lastA_Bind = 0	--打开页面绑定元宝商店最后点击的tag
local lastB_Bind = 0	--打开页面绑定元宝商店最后点击的shop
local lastSelect = 0
local lastSelect_Bind = 0

local lastA_GiftToken = 0
local lastB_GiftToken = 0
local lastSelect_GiftToken = 0

local lastA_VIP = 0
local lastB_VIP = 0

local lastA_Lijin = 0  --通宝
local lastB_Lijin = 0

local maxChildShop = 8
local isCareObj = 0

--存储随机排序的索引值
local	g_tOrderPool	= {};
--当前商店的商品数量
local	g_nTotalNum		= 0;

local	g_changeTabFlag	= 0;
local	g_tabIndex	= 0;		-- 0表示元宝 --1表示绑定元宝
local	g_jumpToShopTabIndex = 0;--从炫装商店转跳回其他商店时，用这个来记录转跳到哪个商店

local g_YuanbaoShop_Frame_UnifiedXPosition = 0;
local g_YuanbaoShop_Frame_UnifiedYPosition = 0;
local g_IsEnableFanQuanShop = 1 --关闭返券商店功能的开关，在YuanBaoShop、XuanShop、ShowShop界面中有这个开关，必须保持一致

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

local g_LiJinDisCountMD = 1561
local g_LiJinDisMaxCnt = 2

function YuanbaoShop_PreLoad()

	this:RegisterEvent("OPEN_YUANBAOSHOP");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UPDATE_BOOTH");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("CLOSE_BOOTH");
	this:RegisterEvent("TOGGLE_YUANBAOSHOP");
	this:RegisterEvent("UPDATE_YUANBAO",false);
	this:RegisterEvent("UPDATE_BIND_YUANBAO",false);
	this:RegisterEvent("UPDATE_GIFTTOKEN",false);
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("GAMELOGIN_OPEN_SELECT_CHARACTOR")
	this:RegisterEvent("OPEN_YUANBAOSHOP_RECENTLY")
	this:RegisterEvent("OPEN_JIYUAN_BOOTH")
	this:RegisterEvent("UPDATE_VIP_INFO", false)

	this:RegisterEvent("OPEN_LIJINSHOP")  --通宝
	this:RegisterEvent("UPDATE_LIJIN",false)
	this:RegisterEvent("FAKE_SWTICH_YUANBAO_SHOP")
	-- this:RegisterEvent("OPEN_SHOWCREDITSHOP")
	this:RegisterEvent("LIJIN_DISCNT_CONFIRMRES")
	this:RegisterEvent("ZBS_SPECIALSERVER_2018")
	
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

end

function YuanbaoShop_OnLoad()

	GOODS_JiYuan_BUTTONS[1] = YuanbaoShop_ExItem1;
	GOODS_JiYuan_BUTTONS[2] = YuanbaoShop_ExItem2;
	GOODS_JiYuan_BUTTONS[3] = YuanbaoShop_ExItem3;
	GOODS_JiYuan_BUTTONS[4] = YuanbaoShop_ExItem4;
	GOODS_JiYuan_BUTTONS[5] = YuanbaoShop_ExItem5;
	GOODS_JiYuan_BUTTONS[6] = YuanbaoShop_ExItem6;

	GOODS_JiYuan_BUTTONS_Buy[1] = YuanbaoShop_ExItemInfo1_Buy
	GOODS_JiYuan_BUTTONS_Buy[2] = YuanbaoShop_ExItemInfo2_Buy
	GOODS_JiYuan_BUTTONS_Buy[3] = YuanbaoShop_ExItemInfo3_Buy
	GOODS_JiYuan_BUTTONS_Buy[4] = YuanbaoShop_ExItemInfo4_Buy
	GOODS_JiYuan_BUTTONS_Buy[5] = YuanbaoShop_ExItemInfo5_Buy
	GOODS_JiYuan_BUTTONS_Buy[6] = YuanbaoShop_ExItemInfo6_Buy

	GOODS_JiYuan_BUTTONS_ICON[1] = YuanbaoShop_ExItemIcon_1
	GOODS_JiYuan_BUTTONS_ICON[2] = YuanbaoShop_ExItemIcon_2
	GOODS_JiYuan_BUTTONS_ICON[3] = YuanbaoShop_ExItemIcon_3
	GOODS_JiYuan_BUTTONS_ICON[4] = YuanbaoShop_ExItemIcon_4
	GOODS_JiYuan_BUTTONS_ICON[5] = YuanbaoShop_ExItemIcon_5
	GOODS_JiYuan_BUTTONS_ICON[6] = YuanbaoShop_ExItemIcon_6

	GOODS_JiYuan_DESCS[1] = YuanbaoShop_ExItemInfo1_Text;
	GOODS_JiYuan_DESCS[2] = YuanbaoShop_ExItemInfo2_Text;
	GOODS_JiYuan_DESCS[3] = YuanbaoShop_ExItemInfo3_Text;
	GOODS_JiYuan_DESCS[4] = YuanbaoShop_ExItemInfo4_Text;
	GOODS_JiYuan_DESCS[5] = YuanbaoShop_ExItemInfo5_Text;
	GOODS_JiYuan_DESCS[6] = YuanbaoShop_ExItemInfo6_Text;

	GOODS_JiYuan_BAD[1] = YuanbaoShop_ExItemInfo1_GB;
	GOODS_JiYuan_BAD[2] = YuanbaoShop_ExItemInfo2_GB;
	GOODS_JiYuan_BAD[3] = YuanbaoShop_ExItemInfo3_GB;
	GOODS_JiYuan_BAD[4] = YuanbaoShop_ExItemInfo4_GB;
	GOODS_JiYuan_BAD[5] = YuanbaoShop_ExItemInfo5_GB;
	GOODS_JiYuan_BAD[6] = YuanbaoShop_ExItemInfo6_GB;

	GOODS_BUTTONS[1] = YuanbaoShop_Item1;
	GOODS_BUTTONS[2] = YuanbaoShop_Item2;
	GOODS_BUTTONS[3] = YuanbaoShop_Item3;
	GOODS_BUTTONS[4] = YuanbaoShop_Item4;
	GOODS_BUTTONS[5] = YuanbaoShop_Item5;
	GOODS_BUTTONS[6] = YuanbaoShop_Item6;
	GOODS_BUTTONS[7] = YuanbaoShop_Item7;
	GOODS_BUTTONS[8] = YuanbaoShop_Item8;
	GOODS_BUTTONS[9] = YuanbaoShop_Item9;
	GOODS_BUTTONS[10]= YuanbaoShop_Item10;
	GOODS_BUTTONS[11]= YuanbaoShop_Item11;
	GOODS_BUTTONS[12]= YuanbaoShop_Item12;
	GOODS_BUTTONS[13]= YuanbaoShop_Item13;
	GOODS_BUTTONS[14]= YuanbaoShop_Item14;
	GOODS_BUTTONS[15]= YuanbaoShop_Item15;
	GOODS_BUTTONS[16]= YuanbaoShop_Item16;
	GOODS_BUTTONS[17]= YuanbaoShop_Item17;
	GOODS_BUTTONS[18]= YuanbaoShop_Item18;

	GOODS_BUTTONS_ICON[1] = YuanbaoShop_ItemIcon_1;
	GOODS_BUTTONS_ICON[2] = YuanbaoShop_ItemIcon_2;
	GOODS_BUTTONS_ICON[3] = YuanbaoShop_ItemIcon_3;
	GOODS_BUTTONS_ICON[4] = YuanbaoShop_ItemIcon_4;
	GOODS_BUTTONS_ICON[5] = YuanbaoShop_ItemIcon_5;
	GOODS_BUTTONS_ICON[6] = YuanbaoShop_ItemIcon_6;
	GOODS_BUTTONS_ICON[7] = YuanbaoShop_ItemIcon_7;
	GOODS_BUTTONS_ICON[8] = YuanbaoShop_ItemIcon_8;
	GOODS_BUTTONS_ICON[9] = YuanbaoShop_ItemIcon_9;
	GOODS_BUTTONS_ICON[10]= YuanbaoShop_ItemIcon_10;
	GOODS_BUTTONS_ICON[11]= YuanbaoShop_ItemIcon_11;
	GOODS_BUTTONS_ICON[12]= YuanbaoShop_ItemIcon_12;
	GOODS_BUTTONS_ICON[13]= YuanbaoShop_ItemIcon_13;
	GOODS_BUTTONS_ICON[14]= YuanbaoShop_ItemIcon_14;
	GOODS_BUTTONS_ICON[15]= YuanbaoShop_ItemIcon_15;
	GOODS_BUTTONS_ICON[16]= YuanbaoShop_ItemIcon_16;
	GOODS_BUTTONS_ICON[17]= YuanbaoShop_ItemIcon_17;
	GOODS_BUTTONS_ICON[18]= YuanbaoShop_ItemIcon_18;

	GOODSRECENTLY_BUTTONS[1] = YuanbaoShop_LastItem1;
	GOODSRECENTLY_BUTTONS[2] = YuanbaoShop_LastItem2;
	GOODSRECENTLY_BUTTONS[3] = YuanbaoShop_LastItem3;
	GOODSRECENTLY_BUTTONS[4] = YuanbaoShop_LastItem4;
	GOODSRECENTLY_BUTTONS[5] = YuanbaoShop_LastItem5;
	--GOODSRECENTLY_BUTTONS[6] = YuanbaoShop_LastItem6;

	GOODSRECENTLY_DESCS[1] = YuanbaoShop_LastItemInfo1_Text;
	GOODSRECENTLY_DESCS[2] = YuanbaoShop_LastItemInfo2_Text;
	GOODSRECENTLY_DESCS[3] = YuanbaoShop_LastItemInfo3_Text;
	GOODSRECENTLY_DESCS[4] = YuanbaoShop_LastItemInfo4_Text;
	GOODSRECENTLY_DESCS[5] = YuanbaoShop_LastItemInfo5_Text;
	--GOODSRECENTLY_DESCS[6] = YuanbaoShop_LastItemInfo6_Text;

	GOODSRECENTLY_BAD[1] = YuanbaoShop_LastItemInfo1_GB;
	GOODSRECENTLY_BAD[2] = YuanbaoShop_LastItemInfo2_GB;
	GOODSRECENTLY_BAD[3] = YuanbaoShop_LastItemInfo3_GB;
	GOODSRECENTLY_BAD[4] = YuanbaoShop_LastItemInfo4_GB;
	GOODSRECENTLY_BAD[5] = YuanbaoShop_LastItemInfo5_GB;
	--GOODSRECENTLY_BAD[6] = YuanbaoShop_LastItemInfo6_GB;

	GOODS_DESCS[1] = YuanbaoShop_ItemInfo1_Text;
	GOODS_DESCS[2] = YuanbaoShop_ItemInfo2_Text;
	GOODS_DESCS[3] = YuanbaoShop_ItemInfo3_Text;
	GOODS_DESCS[4] = YuanbaoShop_ItemInfo4_Text;
	GOODS_DESCS[5] = YuanbaoShop_ItemInfo5_Text;
	GOODS_DESCS[6] = YuanbaoShop_ItemInfo6_Text;
	GOODS_DESCS[7] = YuanbaoShop_ItemInfo7_Text;
	GOODS_DESCS[8] = YuanbaoShop_ItemInfo8_Text;
	GOODS_DESCS[9] = YuanbaoShop_ItemInfo9_Text;
	GOODS_DESCS[10]= YuanbaoShop_ItemInfo10_Text;
	GOODS_DESCS[11]= YuanbaoShop_ItemInfo11_Text;
	GOODS_DESCS[12]= YuanbaoShop_ItemInfo12_Text;
	GOODS_DESCS[13]= YuanbaoShop_ItemInfo13_Text;
	GOODS_DESCS[14]= YuanbaoShop_ItemInfo14_Text;
	GOODS_DESCS[15]= YuanbaoShop_ItemInfo15_Text;
	GOODS_DESCS[16]= YuanbaoShop_ItemInfo16_Text;
	GOODS_DESCS[17]= YuanbaoShop_ItemInfo17_Text;
	GOODS_DESCS[18]= YuanbaoShop_ItemInfo18_Text;

	GOOD_BAD[1]  =     YuanbaoShop_ItemInfo1_GB;
	GOOD_BAD[2]  =     YuanbaoShop_ItemInfo2_GB;
	GOOD_BAD[3]  =     YuanbaoShop_ItemInfo3_GB;
	GOOD_BAD[4]  =     YuanbaoShop_ItemInfo4_GB;
	GOOD_BAD[5]  =     YuanbaoShop_ItemInfo5_GB;
	GOOD_BAD[6]  =     YuanbaoShop_ItemInfo6_GB;
	GOOD_BAD[7]  =     YuanbaoShop_ItemInfo7_GB;
	GOOD_BAD[8]  =     YuanbaoShop_ItemInfo8_GB;
	GOOD_BAD[9]  =     YuanbaoShop_ItemInfo9_GB;
	GOOD_BAD[10] =     YuanbaoShop_ItemInfo10_GB;
	GOOD_BAD[11] =     YuanbaoShop_ItemInfo11_GB;
	GOOD_BAD[12] =     YuanbaoShop_ItemInfo12_GB;
	GOOD_BAD[13] =     YuanbaoShop_ItemInfo13_GB;
	GOOD_BAD[14] =     YuanbaoShop_ItemInfo14_GB;
	GOOD_BAD[15] =     YuanbaoShop_ItemInfo15_GB;
	GOOD_BAD[16] =     YuanbaoShop_ItemInfo16_GB;
	GOOD_BAD[17] =     YuanbaoShop_ItemInfo17_GB;
	GOOD_BAD[18] =     YuanbaoShop_ItemInfo18_GB;

	--大卖场
	SHOP_LIST_A[1] = {btn = YuanbaoShop_Button1 ,shopname="#{YBSD_081225_003}" ,tooltips="#{YBSD_081225_083}", shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A[1].shoplist[1] = "#{YBSD_081225_019}"	--"新品上架";
	SHOP_LIST_A[1].shoplist[2] = "#{YBSD_081225_020}"	--"热卖商店";
	SHOP_LIST_A[1].shoplist[3] = "#{YBSD_081225_021}"	--"特价商品";

	--宝石商城
	SHOP_LIST_A[2] = {btn = YuanbaoShop_Button2 ,shopname="#{YBSD_081225_004}" ,tooltips="#{YBSD_081225_084}", shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A[2].shoplist[1] = "#{YBSD_081225_023}"	--"三级宝石斋";
	SHOP_LIST_A[2].shoplist[2] = "#{YBSDTZ_130503_01}"	--"四级宝石斋";
	SHOP_LIST_A[2].shoplist[3] = "#{YBSDTZ_130503_02}"	--"五级宝石斋";
	SHOP_LIST_A[2].shoplist[4] = "#{YBSD_081225_024}"	--"六级宝石斋";
	SHOP_LIST_A[2].shoplist[5] = "#{YBSD_081225_025}"	--"宝石精华店";
	SHOP_LIST_A[2].shoplist[6] = "#{YBSD_081225_026}"	--"宝石加工坊";

	--珍兽商城
	SHOP_LIST_A[3] = {btn = YuanbaoShop_Button3 , shopname="#{YBSD_081225_005}" ,tooltips="#{YBSD_081225_085}", shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A[3].shoplist[1] = "#{YBSD_081225_027}"	--"稀有珍兽馆";
	SHOP_LIST_A[3].shoplist[2] = "#{YBSD_081225_028}"	--"普通技能馆";
	SHOP_LIST_A[3].shoplist[3] = "#{YBSD_081225_029}"	--"高级技能馆";
	SHOP_LIST_A[3].shoplist[4] = "#{YBSD_081225_030}"	--"珍兽灵药坊";

	--南北杂货
	SHOP_LIST_A[4] = {btn = YuanbaoShop_Button4 , shopname="#{YBSD_081225_006}" ,tooltips="#{YBSD_081225_086}", shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A[4].shoplist[1] = "#{YBSD_081225_091}"	--"仙丹灵药";
	SHOP_LIST_A[4].shoplist[2] = "#{YBSD_XML_3}"	--"天工开物";
	SHOP_LIST_A[4].shoplist[3] = "#{YBSD_081225_031}"	--"奇珍异宝";
	SHOP_LIST_A[4].shoplist[4] = "#{YBSD_081225_032}"	--"三清神符";

	--形象广场
	SHOP_LIST_A[5] = {btn = YuanbaoShop_Button5 ,shopname="#{YBSD_081225_007}" , tooltips="#{YBSD_081225_087}", shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A[5].shoplist[1] = "#{YBSD_XML_1}"	--久久时装店
	SHOP_LIST_A[5].shoplist[2] = "#{YBSD_XML_2}"	--时尚时装店
	SHOP_LIST_A[5].shoplist[3] = "#{YBSD_081225_034}"	--"如意变身斋";
	SHOP_LIST_A[5].shoplist[4] = "#{YBSD_081225_035}"	--"天扬发艺馆";
	SHOP_LIST_A[5].shoplist[5] = "#{YBSD_081225_036}"	--"兰雨美容坊";
	SHOP_LIST_A[5].shoplist[6] = "#{YBSD_081225_037}"	--"坐骑商城";
	SHOP_LIST_A[5].shoplist[7] = "#{YBSD_90624_1}"		--"天宫骑术阁";
	SHOP_LIST_A[5].shoplist[8] = "#{YBSD_171026_102}"		--"庄园装饰馆";	

	--花舞人间
	SHOP_LIST_A[6] = {btn = YuanbaoShop_Button6 ,shopname="#{YBSD_081225_008}" , tooltips="#{YBSD_081225_088}", shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A[6].shoplist[1] = "#{YBSD_081225_038}"	--"传统烟花";
	SHOP_LIST_A[6].shoplist[2] = "#{YBSD_081225_039}"	--"个性烟花";
	--likun
 	SHOP_LIST_A[6].shoplist[3] = "#{YBSD_XML_5}"	--"个性烟花";
	SHOP_LIST_A[6].shoplist[4] = "#{YBSD_081225_040}"	--"全场景烟花";
	SHOP_LIST_A[6].shoplist[5] = "#{YBSD_081225_041}"	--"鲜花";

	--武功秘籍
	SHOP_LIST_A[7] = {btn = YuanbaoShop_Button7 , shopname="#{YBSD_081225_009}" ,tooltips="#{YBSD_081225_089}", shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A[7].shoplist[1] = "#{YBSD_081225_042}"	--"还施水阁";
	SHOP_LIST_A[7].shoplist[2] = "#{YBSD_XML_4}"	--"琅嬛玉府";
	SHOP_LIST_A[7].shoplist[3] = "#{YBSD_XML_6}"	--"嵩阳书院";
	SHOP_LIST_A[7].shoplist[4] = "#{YBSD_XML_7}"	--"岳麓书院";
	
	--打造图
	SHOP_LIST_A[8] = {btn = YuanbaoShop_Button8 , shopname="#{YBSD_081225_010}" ,tooltips="#{YBSD_081225_090}", shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A[8].shoplist[1] = "#{YBSD_081225_102}"	--"刀斧和枪棒";
	--SHOP_LIST_A[8].shoplist[2] = "#{YBSD_081225_044}"	--"单短和双短";
	--SHOP_LIST_A[8].shoplist[3] = "#{YBSD_081225_045}"	--"扇和环";
	SHOP_LIST_A[8].shoplist[2] = "#{YBSD_081225_096}"	--"衣服和帽子";
	SHOP_LIST_A[8].shoplist[3] = "#{YBSD_081225_046}"	--"手套和鞋子";
	SHOP_LIST_A[8].shoplist[4] = "#{YBSD_081225_047}"	--"护腕和护肩";
	SHOP_LIST_A[8].shoplist[5] = "#{YBSD_081225_048}"	--"腰带和项链";
	SHOP_LIST_A[8].shoplist[6] = "#{YBSD_081225_049}"	--"戒指和护符";
	SHOP_LIST_A[8].shoplist[7] = nil
	SHOP_LIST_A[8].shoplist[8] = nil
	
	--二级商店
	SHOP_LIST_B[1] = YuanbaoShop_Button01
	SHOP_LIST_B[2] = YuanbaoShop_Button02
	SHOP_LIST_B[3] = YuanbaoShop_Button03
	SHOP_LIST_B[4] = YuanbaoShop_Button04
	SHOP_LIST_B[5] = YuanbaoShop_Button05
	SHOP_LIST_B[6] = YuanbaoShop_Button06
	SHOP_LIST_B[7] = YuanbaoShop_Button07
	SHOP_LIST_B[8] = YuanbaoShop_Button08


	if lastA ~= nil and lastA > 0 and lastA < 9 then
		SHOP_LIST_A[lastA].btn:SetCheck(1)
	end

	if lastB ~= nil and lastB > 0 and lastB < 9 then
		SHOP_LIST_B[lastB]:SetCheck(1)
	end

	for i =1 ,8 do
		SHOP_LIST_B[i]:Hide()
	end


	--我要更强大
	SHOP_SEARCH_LIST[1] = {}
	SHOP_SEARCH_LIST[1][1] = "#{YBSD_081225_023}"	--"三级宝石斋";
	SHOP_SEARCH_LIST[1][2] = "#{YBSD_081225_024}"	--"六级宝石斋";
	SHOP_SEARCH_LIST[1][3] = "#{YBSD_081225_025}"	--"宝石精华店";
	SHOP_SEARCH_LIST[1][4] = "#{FFSDGZ_120615_73}"	--"稀有珍兽馆";-->宝石加工坊
	SHOP_SEARCH_LIST[1][5] = "#{FFSDGZ_120615_74}"	--"仙丹灵药"; -->天工开物
	SHOP_SEARCH_LIST[1][6] = "#{YBSD_081225_027}"	--"稀有珍兽馆";-->宝石加工坊
	SHOP_SEARCH_LIST[1][7] = "#{YBSD_081225_091}"	--"仙丹灵药"; -->天工开物
	--我要更有魅力
	SHOP_SEARCH_LIST[2] = {}
	SHOP_SEARCH_LIST[2][1] = "#{YBSD_081225_037}"	--"坐骑商城";
	SHOP_SEARCH_LIST[2][2] = "#{FFSDGZ_120615_75}"	--天宫骑术阁
	SHOP_SEARCH_LIST[2][3] = "#{YBSD_XML_1}"		--久久时装店
	SHOP_SEARCH_LIST[2][4] = "#{YBSD_XML_2}"		--时尚时装店
	SHOP_SEARCH_LIST[2][5] = "#{YBSD_081225_034}"	--"如意变身斋";
	SHOP_SEARCH_LIST[2][6] = "#{YBSD_081225_035}"	--"天扬发艺馆";
	SHOP_SEARCH_LIST[2][7] = "#{YBSD_081225_036}"	--"兰雨美容坊";
	--我要打造极品装备
	SHOP_SEARCH_LIST[3] = {}
	SHOP_SEARCH_LIST[3][1] = "#{YBSD_081225_023}"	--"三级宝石斋";
	SHOP_SEARCH_LIST[3][2] = "#{YBSD_081225_024}"	--"六级宝石斋";
	SHOP_SEARCH_LIST[3][3] = "#{YBSD_081225_026}"	--"宝石加工坊";
	SHOP_SEARCH_LIST[3][4] = "#{YBSD_XML_3}"	--"天工开物";
	SHOP_SEARCH_LIST[3][5] = "#{YBSD_081225_031}"	--"奇珍异宝";
	--我要打造极品珍兽
	SHOP_SEARCH_LIST[4] = {}
	SHOP_SEARCH_LIST[4][1] = "#{YBSD_081225_027}"	--"稀有珍兽馆";
	SHOP_SEARCH_LIST[4][2] = "#{YBSD_081225_028}"	--"普通技能馆";
	SHOP_SEARCH_LIST[4][3] = "#{YBSD_081225_029}"	--"高级技能馆";
	SHOP_SEARCH_LIST[4][4] = "#{YBSD_081225_030}"	--"珍兽灵药坊";

	--我要移动的更快
	SHOP_SEARCH_LIST[5] = {}
	SHOP_SEARCH_LIST[5][1] = "#{YBSD_081225_037}"	--"坐骑商城";
	SHOP_SEARCH_LIST[5][2] = "#{YBSD_90624_1}"	--"天宫骑术阁";
	SHOP_SEARCH_LIST[5][3] = "#{FFSDGZ_120615_76}"	--"奇珍异宝";
	SHOP_SEARCH_LIST[5][4] = "#{YBSD_081225_032}"	--"三清神符";

	--我要向别人表白
	SHOP_SEARCH_LIST[6] = {}
	SHOP_SEARCH_LIST[6][1] = "#{FFSDGZ_120615_77}"	--"传统烟花";
	SHOP_SEARCH_LIST[6][2] = "#{YBSD_081225_039}"	--"个性烟花";
	SHOP_SEARCH_LIST[6][3] = "#{FFSDGZ_120615_78}"	--"节日烟花";
	SHOP_SEARCH_LIST[6][4] = "#{YBSD_081225_040}"	--"全场景烟花";
	SHOP_SEARCH_LIST[6][5] = "#{YBSD_081225_041}"	--春城百花

	--我要学习新技能
	SHOP_SEARCH_LIST[7] = {}
	SHOP_SEARCH_LIST[7][1] = "#{YBSD_081225_042}"	--"还施水阁";
	SHOP_SEARCH_LIST[7][2] = "#{YBSD_XML_4}"	--"还施水阁";
	SHOP_SEARCH_LIST[7][3] = "#{FFSDGZ_120615_79}"	--"嵩阳书院";
	SHOP_SEARCH_LIST[7][4] = "#{FFSDGZ_120615_80}"	--"岳麓书院";
	SHOP_SEARCH_LIST[7][5] = "#{YBSD_081225_028}"	--"普通技能馆";
	SHOP_SEARCH_LIST[7][6] = "#{YBSD_081225_029}"	--"高级技能馆";


	YuanbaoShop_SearchMode:AddTextItem("#{YBSD_081225_055}" ,1)	--我要更强大
	YuanbaoShop_SearchMode:AddTextItem("#{YBSD_081225_056}" ,2)	--"我要更有魅力"
	YuanbaoShop_SearchMode:AddTextItem("#{YBSD_081225_057}" ,3)	--"我要打造极品装备"
	YuanbaoShop_SearchMode:AddTextItem("#{YBSD_081225_058}",4)	--"我要打造极品珍兽"
	YuanbaoShop_SearchMode:AddTextItem("#{YBSD_081225_059}",5)	--"我要移动的更快"
	YuanbaoShop_SearchMode:AddTextItem("#{YBSD_081225_060}",6)	--"我要向别人表白"
	YuanbaoShop_SearchMode:AddTextItem("#{YBSD_081225_061}",7)	--"我要学习新技能"
	--YuanbaoShop_SearchMode:AddTextItem("#{YBSD_xml_XX(02)}",8)	--"查看最近购买的商品"


	-- 绑定元宝begin
	SHOP_LIST_A_BIND[1] = {btn = YuanbaoShop_Button1_Bind ,shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A_BIND[1].shoplist[1] = "#{YBSD_081225_019}"		--"";
	--SHOP_LIST_A_BIND[1].shoplist[1] = "#{YBSD_081225_020}"		--"";
	--SHOP_LIST_A_BIND[1].shoplist[3] = "#{YBSD_081225_021}"		--"";

	--
	SHOP_LIST_A_BIND[2] = {btn = YuanbaoShop_Button2_Bind , shoplist = {}, shoplisttips = {}}
	--SHOP_LIST_A_BIND[2].shoplist[1] = "#{YBSD_081225_022}"		--"";
	--SHOP_LIST_A_BIND[2].shoplist[1] = "#{YBSD_081225_023}"		--"";
	--SHOP_LIST_A_BIND[2].shoplist[2] = "#{YBSD_081225_024}"		--"";
	--SHOP_LIST_A_BIND[2].shoplist[3] = "#{YBSD_081225_025}"		--"";
	SHOP_LIST_A_BIND[2].shoplist[1] = "#{YBSD_081225_026}"		--"";

	--
	SHOP_LIST_A_BIND[3] = {btn = YuanbaoShop_Button3_Bind , shoplist = {}, shoplisttips = {}}
	--SHOP_LIST_A_BIND[3].shoplist[1] = "#{YBSD_081225_027}"		--"";
	--SHOP_LIST_A_BIND[3].shoplist[2] = "#{YBSD_081225_028}"		--"";
	--SHOP_LIST_A_BIND[3].shoplist[3] = "#{YBSD_081225_029}"		--"";
	SHOP_LIST_A_BIND[3].shoplist[1] = "#{YBSD_081225_030}"		--"";

	--
	SHOP_LIST_A_BIND[4] = {btn = YuanbaoShop_Button4_Bind , shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A_BIND[4].shoplist[1] = "#{YBSD_081225_091}"		--"";
	SHOP_LIST_A_BIND[4].shoplist[2] = "#{YBSD_081225_031}"		--"";
--	SHOP_LIST_A_BIND[4].shoplist[3] = "#{YBSD_101110_01}"		--"雕纹商店"
	SHOP_LIST_A_BIND[4].shoplist[3] = "#{YBSD_XML_8}"	    --"防具雕纹店"
	SHOP_LIST_A_BIND[4].shoplist[4] = "#{YBSD_XML_9}"	    --"武具雕纹店"
	SHOP_LIST_A_BIND[4].shoplist[5] = "#{SSXDW_140819_75}"	    --"武具雕纹坊"
	SHOP_LIST_A_BIND[4].shoplist[6] = "#{YBSD_XML_10}"	--"雕纹加工坊"

	--
	SHOP_LIST_A_BIND[5] = {btn = YuanbaoShop_Button5_Bind , shoplist = {}, shoplisttips = {}}
	--SHOP_LIST_A_BIND[5].shoplist[1] = "#{YBSD_081225_033}"		--"";
	--SHOP_LIST_A_BIND[5].shoplist[2] = "#{YBSD_081225_034}"		--"";
	--SHOP_LIST_A_BIND[5].shoplist[3] = "#{YBSD_081225_035}"		--"";
	--SHOP_LIST_A_BIND[5].shoplist[4] = "#{YBSD_081225_036}"		--"";
	--SHOP_LIST_A_BIND[5].shoplist[5] = "#{YBSD_081225_037}"		--"";
	--SHOP_LIST_A_BIND[5].shoplist[6] = "#{YBSD_90624_1}"			--"";

	--
	SHOP_LIST_A_BIND[6] = {btn = YuanbaoShop_Button6_Bind , shoplist = {}, shoplisttips = {}}
	--SHOP_LIST_A_BIND[6].shoplist[1] = "#{YBSD_081225_038}"		--"";
	--SHOP_LIST_A_BIND[6].shoplist[2] = "#{YBSD_081225_039}"		--"";
	--SHOP_LIST_A_BIND[6].shoplist[3] = "#{YBSD_081225_040}"		--"";
	--SHOP_LIST_A_BIND[6].shoplist[4] = "#{YBSD_081225_041}"		--"";

	--
	SHOP_LIST_A_BIND[7] = {btn = YuanbaoShop_Button7_Bind , shoplist = {}, shoplisttips = {}}
	--SHOP_LIST_A_BIND[7].shoplist[1] = "#{YBSD_081225_042}"		--"";

	--
	SHOP_LIST_A_BIND[8] = {btn = YuanbaoShop_Button8_Bind , shoplist = {}, shoplisttips = {}}
	--SHOP_LIST_A_BIND[8].shoplist[1] = "#{YBSD_081225_043}"		--"";
	--SHOP_LIST_A_BIND[8].shoplist[2] = "#{YBSD_081225_044}"		--"";
	--SHOP_LIST_A_BIND[8].shoplist[3] = "#{YBSD_081225_045}"		--"";
	--SHOP_LIST_A_BIND[8].shoplist[4] = "#{YBSD_081225_096}"		--"";
	--SHOP_LIST_A_BIND[8].shoplist[5] = "#{YBSD_081225_046}"		--"";
	--SHOP_LIST_A_BIND[8].shoplist[6] = "#{YBSD_081225_047}"		--"";
	--SHOP_LIST_A_BIND[8].shoplist[7] = "#{YBSD_081225_048}"		--"";
	--SHOP_LIST_A_BIND[8].shoplist[8] = "#{YBSD_081225_049}"		--"";

	--二级商店
	SHOP_LIST_B_BIND[1] = YuanbaoShop_Button01_Bind
	SHOP_LIST_B_BIND[2] = YuanbaoShop_Button02_Bind
	SHOP_LIST_B_BIND[3] = YuanbaoShop_Button03_Bind
	SHOP_LIST_B_BIND[4] = YuanbaoShop_Button04_Bind
	SHOP_LIST_B_BIND[5] = YuanbaoShop_Button05_Bind
	SHOP_LIST_B_BIND[6] = YuanbaoShop_Button06_Bind
	SHOP_LIST_B_BIND[7] = YuanbaoShop_Button07_Bind
	SHOP_LIST_B_BIND[8] = YuanbaoShop_Button08_Bind


	if lastA_Bind ~= nil and lastA_Bind > 0 and lastA_Bind < 9 then
		SHOP_LIST_A_BIND[ lastA_Bind ].btn : SetCheck(1)
	end

	if lastB_Bind ~= nil and lastB_Bind > 0 and lastB_Bind < 9 then
		SHOP_LIST_B_BIND[ lastB_Bind ] : SetCheck(1)
	end

	for i =1 ,8 do
		SHOP_LIST_B_BIND[i]:Hide()
	end

	--
	SHOP_SEARCH_LIST_BIND[1] = {}
	SHOP_SEARCH_LIST_BIND[1][1] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[1][2] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[1][3] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[1][4] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[1][5] = "BindSearch1"	--"";
	--
	SHOP_SEARCH_LIST_BIND[2] = {}
	SHOP_SEARCH_LIST_BIND[2][1] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[2][2] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[2][3] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[2][4] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[2][5] = "BindSearch1"	--"";
	--
	SHOP_SEARCH_LIST_BIND[3] = {}
	SHOP_SEARCH_LIST_BIND[3][1] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[3][2] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[3][3] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[3][4] = "BindSearch1"	--"";

	--
	SHOP_SEARCH_LIST_BIND[4] = {}
	SHOP_SEARCH_LIST_BIND[4][1] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[4][2] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[4][3] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[4][4] = "BindSearch1"	--"";

	--
	SHOP_SEARCH_LIST_BIND[5] = {}
	SHOP_SEARCH_LIST_BIND[5][1] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[5][2] = "BindSearch1"	--"";
	--
	SHOP_SEARCH_LIST_BIND[6] = {}
	SHOP_SEARCH_LIST_BIND[6][1] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[6][2] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[6][3] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[6][4] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[6][5] = "BindSearch1"	--"";
	--
	SHOP_SEARCH_LIST_BIND[7] = {}
	SHOP_SEARCH_LIST_BIND[7][1] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[7][2] = "BindSearch1"	--"";
	SHOP_SEARCH_LIST_BIND[7][3] = "BindSearch1"	--"";


	YuanbaoShop_SearchMode_Bind:AddTextItem("BindSearch1}" ,1)	--
	YuanbaoShop_SearchMode_Bind:AddTextItem("BindSearch2}" ,2)	--""
	YuanbaoShop_SearchMode_Bind:AddTextItem("BindSearch3}" ,3)	--""
	YuanbaoShop_SearchMode_Bind:AddTextItem("BindSearch4}",4)		--""
	YuanbaoShop_SearchMode_Bind:AddTextItem("BindSearch5}",5)		--""
	YuanbaoShop_SearchMode_Bind:AddTextItem("BindSearch6}",6)		--""
	YuanbaoShop_SearchMode_Bind:AddTextItem("BindSearch7}",7)		--""


	YuanbaoShop_Bk1_Bind : Hide();
	YuanbaoShop_Bk2_Bind : Hide();
	YuanbaoShop_SearchMode_Bind : Hide();
	YuanbaoShop_Text2_Bind : Hide();
	YuanbaoShop_Bk4 : Hide();
	-- 绑定元宝end

	------------------------------------------ 返券商店 -------------------------------------------------------
	--返券商店Begin
	if g_IsEnableFanQuanShop == 0 then
	    YuanbaoShop_Fanquan:Disable(); --关闭返券商店
	    YuanbaoShop_Fanquan:Hide();
	end

	--大卖场
	SHOP_LIST_A_GIFTTOKEN[1] = {btn = YuanbaoShop_Button1 , shopname="#{YBSD_081225_003}" ,tooltips="#{FQ_101210_19}", shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A_GIFTTOKEN[1].shoplist[1] = "#{YBSD_081225_019}"	--"新品上架";
	--SHOP_LIST_A_GIFTTOKEN[1].shoplist[2] = "#{YBSD_081225_020}"	--"热卖商店";


	--形象广场
	SHOP_LIST_A_GIFTTOKEN[2] = {btn = YuanbaoShop_Button2 , shopname="#{YBSD_081225_007}",tooltips="#{FQ_101210_20}", shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A_GIFTTOKEN[2].shoplist[1] = "#{YBSD_XML_2}"	--"时尚时装店";
	SHOP_LIST_A_GIFTTOKEN[2].shoplist[2] = "#{YBSD_081225_037}"	--"天宫御马监";
	--第三间
	SHOP_LIST_A_GIFTTOKEN[3] = {btn = YuanbaoShop_Button3 ,shopname="", shoplist = {}, shoplisttips = {}}

	--第四间
	SHOP_LIST_A_GIFTTOKEN[4] = {btn = YuanbaoShop_Button4 , shopname="",shoplist = {}, shoplisttips = {}}

	--第五间
	SHOP_LIST_A_GIFTTOKEN[5] = {btn = YuanbaoShop_Button5 , shopname="",shoplist = {}, shoplisttips = {}}

	--第六间
	SHOP_LIST_A_GIFTTOKEN[6] = {btn = YuanbaoShop_Button6 , shopname="",shoplist = {}, shoplisttips = {}}

	--第七间
	SHOP_LIST_A_GIFTTOKEN[7] = {btn = YuanbaoShop_Button7 , shopname="",shoplist = {}, shoplisttips = {}}

	--第八间
	SHOP_LIST_A_GIFTTOKEN[8] = {btn = YuanbaoShop_Button8 , shopname="",shoplist = {}, shoplisttips = {}}

	--二级商店
	SHOP_LIST_B_GIFTTOKEN[1] = YuanbaoShop_Button01
	SHOP_LIST_B_GIFTTOKEN[2] = YuanbaoShop_Button02
	SHOP_LIST_B_GIFTTOKEN[3] = YuanbaoShop_Button03
	SHOP_LIST_B_GIFTTOKEN[4] = YuanbaoShop_Button04
	SHOP_LIST_B_GIFTTOKEN[5] = YuanbaoShop_Button05
	SHOP_LIST_B_GIFTTOKEN[6] = YuanbaoShop_Button06
	SHOP_LIST_B_GIFTTOKEN[7] = YuanbaoShop_Button07
	SHOP_LIST_B_GIFTTOKEN[8] = YuanbaoShop_Button08


	if lastA ~= nil and lastA > 0 and lastA < table.getn(SHOP_LIST_A_GIFTTOKEN)+1 then
		SHOP_LIST_A_GIFTTOKEN[lastA].btn:SetCheck(1)
	end

	if lastB ~= nil and lastB > 0 and lastB < table.getn(SHOP_LIST_B_GIFTTOKEN)+1 then
		SHOP_LIST_B_GIFTTOKEN[lastB]:SetCheck(1)
	end

	for i =1 ,table.getn(SHOP_LIST_B_GIFTTOKEN) do
		SHOP_LIST_B_GIFTTOKEN[i]:Hide()
	end

	--搜索选择项
	SHOP_SEARCH_LIST_GIFTTOKEN[1] = {}

	-- Vip元宝商店begin
	SHOP_LIST_A_VIP[1] = {btn = YuanbaoShop_Button1 , shopname="", tooltips = "" ,shoplist = {}, shoplisttips = {}}
--	SHOP_LIST_A_VIP[1].shoplist[1] = "#{FFSDGZ_120615_06}"	--"至尊奇珍阁";
	SHOP_LIST_A_VIP[1].shoplist[1] = "#{FFSDGZ_120615_07}"	--"至尊宝石阁";
	SHOP_LIST_A_VIP[1].shoplist[2] = "#{FFSDGZ_120615_08}"	--"至尊珠玑阁";
--	SHOP_LIST_A_VIP[1].shoplisttips[1] = "#{FFSDGZ_120615_124}"	--"至尊奇珍阁";--改为至尊冥石阁
	SHOP_LIST_A_VIP[1].shoplisttips[1] = "#{FFSDGZ_120615_133}"	--"至尊宝石阁";--改为自尊奇石阁
	SHOP_LIST_A_VIP[1].shoplisttips[2] = "#{FFSDGZ_120615_125}"	--"至尊珠玑阁";
	--
	SHOP_LIST_A_VIP[2] = {btn = YuanbaoShop_Button2 , shoplist = {}, shoplisttips = {}}
	--
	SHOP_LIST_A_VIP[3] = {btn = YuanbaoShop_Button3 , shoplist = {}, shoplisttips = {}}
	--
	SHOP_LIST_A_VIP[4] = {btn = YuanbaoShop_Button4 , shoplist = {}, shoplisttips = {}}
	--
	SHOP_LIST_A_VIP[5] = {btn = YuanbaoShop_Button5 , shoplist = {}, shoplisttips = {}}
	--
	SHOP_LIST_A_VIP[6] = {btn = YuanbaoShop_Button6 , shoplist = {}, shoplisttips = {}}
	--
	SHOP_LIST_A_VIP[7] = {btn = YuanbaoShop_Button7 , shoplist = {}, shoplisttips = {}}
	--
	SHOP_LIST_A_VIP[8] = {btn = YuanbaoShop_Button8 , shoplist = {}, shoplisttips = {}}

	--二级商店
	SHOP_LIST_B_VIP[1] = YuanbaoShop_Button01
	SHOP_LIST_B_VIP[2] = YuanbaoShop_Button02
	SHOP_LIST_B_VIP[3] = YuanbaoShop_Button03
	SHOP_LIST_B_VIP[4] = YuanbaoShop_Button04
	SHOP_LIST_B_VIP[5] = YuanbaoShop_Button05
	SHOP_LIST_B_VIP[6] = YuanbaoShop_Button06
	SHOP_LIST_B_VIP[7] = YuanbaoShop_Button07
	SHOP_LIST_B_VIP[8] = YuanbaoShop_Button08
	if lastA ~= nil and lastA > 0 and lastA < table.getn(SHOP_LIST_A_VIP)+1 then
		SHOP_LIST_A_VIP[lastA].btn:SetCheck(1)
	end

	g_nDistanceBBtnY = YuanbaoShop_Button02 : GetProperty("AbsoluteYPosition") - YuanbaoShop_Button01 : GetProperty("AbsoluteYPosition");

	if lastB ~= nil and lastB > 0 and lastB < table.getn(SHOP_LIST_B_VIP)+1 then
		SHOP_LIST_B_VIP[lastB]:SetCheck(1)
	end

	for i =1 ,table.getn(SHOP_LIST_B_GIFTTOKEN) do
		SHOP_LIST_B_VIP[i]:Hide()
	end
	--广告牌
	g_PlayCard_CtlButton[1] = YuanbaoShop_ExButton1
	g_PlayCard_CtlButton[2] = YuanbaoShop_ExButton2
	g_PlayCard_CtlButton[3] = YuanbaoShop_ExButton3
	g_PlayCard_CtlButton[4] = YuanbaoShop_ExButton4
	--YuanbaoShop_FanquanRateInfo : Hide();
	--YuanbaoShop_UpPage_Fanquan : Hide()
	--YuanbaoShop_CurrentlyPage_Fanquan : Hide()
	--YuanbaoShop_DownPage_Fanquan : Hide()
	--YuanbaoShop_Try_Fanquan : Hide()
	YuanbaoShop_Bk1_Fanquan : Hide()
	--返券商店End

	--vip商店
	YuanbaoShop_Bk1_VIP:Hide()
	YuanbaoShop_Lace1:Hide()
	YuanbaoShop_Lace2:Hide()
	YuanbaoShop_Bk1_VIP_test2:SetText("#{FFSDGZ_120615_82}")
	--YuanbaoShop_Exgoumaiqueren:Hide()
	--YuanbaoShop_Exgoumaiqueren_Text:Hide()

	--通宝
	YuanbaoShop_Lijin_Load()

	g_YuanbaoShop_Frame_UnifiedXPosition	= YuanbaoShop_Frame:GetProperty("UnifiedXPosition");
	g_YuanbaoShop_Frame_UnifiedYPosition	= YuanbaoShop_Frame:GetProperty("UnifiedYPosition");
end

function YuanbaoShop_OnEvent(event)

	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		YuanbaoShop_Close()
	end

	if event == "FAKE_SWTICH_YUANBAO_SHOP" then
		YuanbaoShop_ChangeTabIndex(0)
		YuanbaoShop_UpdateList(5)
		--为了防止当前已经是4页不刷新。。。。
		YuanbaoShop_UpdateShop(3)
		YuanbaoShop_UpdateShop(4)
	end

	if ( event == "OPEN_YUANBAOSHOP"  or event == "OPEN_LIJINSHOP") then
		g_nTotalNum	= 0;
		local check  = tonumber(NpcShop:GetBuyDirectly());
		if(check>=1)then
			YuanbaoShop_querengoumai:SetCheck(0);
		else
			YuanbaoShop_querengoumai:SetCheck(1);
		end

		-- if IsInTServer() == 1 then
		-- 	PushDebugMessage("元宝商店——在这不让用")
		-- 	return;
		-- end

		if( this:IsVisible() == false ) then
			if TLCJ:IsInTLCJScene() > 0 then
				PushDebugMessage("#{TLCJ_20240709_69}")
				return 
			end
			YubanbaoShop_ADRandom()
			if (IsWindowShow("YbMarket")) then
				CloseWindow("YbMarket", true);
			end
			PushEvent( "CLOSE_DRESSPREVIEW") 
			PushEvent( "CLOSE_GEMEFFECTPREVIEW") 
			this:Show();
			if (IsWindowShow("XuanShop")) then
				CloseWindow("XuanShop", true);
			end

			YuanbaoShop_ChangeTabIndex(LAST_FENYE)		--之前有一步
			if(LAST_FENYE == ShopTabIdx.GiftToken) then
				YuanbaoShop_UpdateList_GiftToken(LAST_TAG)
				YuanbaoShop_UpdateShop_GiftToken(LAST_SHOP)
			elseif (LAST_FENYE == ShopTabIdx.Bind) then
				YuanbaoShop_UpdateList_Bind(LAST_TAG)
				YuanbaoShop_UpdateShop_Bind(LAST_SHOP)
			elseif (LAST_FENYE == ShopTabIdx.YuanBao) then
				YuanbaoShop_UpdateList(LAST_TAG)
				YuanbaoShop_UpdateShop(LAST_SHOP)
			elseif (LAST_FENYE == ShopTabIdx.VipShop) then
				YuanbaoShop_UpdateList_VIP(LAST_TAG)
				YuanbaoShop_UpdateShop_VIP(LAST_SHOP)
			elseif (LAST_FENYE == ShopTabIdx.Lijin) then
				YuanbaoShop_UpdateList_Lijin(LAST_TAG)
				YuanbaoShop_UpdateShop_Lijin(LAST_SHOP)
			end


			OpenWindow("Packet")
			-- 在先打开NPC商店，后打开元宝商店的时候，存在一个问题
			-- 元宝商店在打开时会关闭已经打开的NPC商店，而关闭这个操作会将是否打开商店这个状态只为假，从而导致购买相关的逻辑出现错误
			-- 目前的解决办法是在Show的地方，设置是否打开商店的状态为真。
			OpenBooth();
		end

		--关心商人Obj
		objCared = NpcShop:GetNpcId();
		if (event == "OPEN_YUANBAOSHOP") then
			this:CareObject(objCared, 1, "YuanbaoShop");
		end

		NpcShop:CloseConfirm();
		PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
		YuanbaoShop_UpdatePage(1);
	elseif ( event == "TOGGLE_YUANBAOSHOP") then
--		PushDebugMessage("TOGGLE_YUANBAOSHOP")
		if( this:IsVisible() ) then
			YuanbaoShop_Close();
		else
			if arg0 == "normal" then
				if LAST_FENYE < 0 or LAST_FENYE > 6 then
					LAST_FENYE = 0
				end
				g_jumpToShopTabIndex = LAST_FENYE
			else
				if (arg0 and arg0 == "1") then
					--证明是从其他商店跳过来的
					g_jumpToShopTabIndex = 1--转跳到绑定元宝商店
					if (arg1 and arg2 and arg1 ~= "-1" and arg2 ~= "-1" ) then
						YuanbaoShop_Frame:SetProperty("UnifiedXPosition", arg1);
						YuanbaoShop_Frame:SetProperty("UnifiedYPosition", arg2);
					end
				elseif (arg0 and arg0 == "0") then--转跳到元宝商店
					g_jumpToShopTabIndex = 0
					if (arg1 and arg2 and arg1 ~= "-1" and arg2 ~= "-1" ) then
						YuanbaoShop_Frame:SetProperty("UnifiedXPosition", arg1);
						YuanbaoShop_Frame:SetProperty("UnifiedYPosition", arg2);
					end
				elseif (arg0 and arg0 == "2") then--转跳到返券商店
					g_jumpToShopTabIndex = 2
					if (arg1 and arg2 and arg1 ~= "-1" and arg2 ~= "-1" ) then
						YuanbaoShop_Frame:SetProperty("UnifiedXPosition", arg1);
						YuanbaoShop_Frame:SetProperty("UnifiedYPosition", arg2);
					end
				elseif (arg0 and arg0 == "3") then--转跳到炫装商店
					g_jumpToShopTabIndex = 3
					if (arg1 and arg2 and arg1 ~= "-1" and arg2 ~= "-1" ) then
						YuanbaoShop_Frame:SetProperty("UnifiedXPosition", arg1);
						YuanbaoShop_Frame:SetProperty("UnifiedYPosition", arg2);
					end
				elseif (arg0 and arg0 == "4") then--转跳到至尊商店
					g_jumpToShopTabIndex = 4
					if (arg1 and arg2 and arg1 ~= "-1" and arg2 ~= "-1" ) then
						YuanbaoShop_Frame:SetProperty("UnifiedXPosition", arg1);
						YuanbaoShop_Frame:SetProperty("UnifiedYPosition", arg2);
					end
				elseif (arg0 and arg0 == "5") then--转跳到通宝商店
					g_jumpToShopTabIndex = 5
					if (arg1 and arg2 and arg1 ~= "-1" and arg2 ~= "-1" ) then
						YuanbaoShop_Frame:SetProperty("UnifiedXPosition", arg1);
						YuanbaoShop_Frame:SetProperty("UnifiedYPosition", arg2);
					end
				elseif (arg0 and arg0 == "6") then--转跳到秀场商店
					g_jumpToShopTabIndex = 6
					if (arg1 and arg2 and arg1 ~= "-1" and arg2 ~= "-1" ) then
						YuanbaoShop_Frame:SetProperty("UnifiedXPosition", arg1);
						YuanbaoShop_Frame:SetProperty("UnifiedYPosition", arg2);
					end
				end
				--lastA = 1;
				--lastB = 1;

				if( tonumber(arg0) ~= nil and tonumber(arg3) ~= nil and tonumber(arg4) ~= nil ) then
					if( tonumber(arg0) >= 0 and tonumber(arg0) <= 5
						and tonumber(arg3) >= 1 and tonumber(arg3) <= 8
						and tonumber(arg4) >= 1 and tonumber(arg4) <= 8 )
					then
						LAST_FENYE = tonumber(arg0)
						LAST_TAG = tonumber(arg3)
						LAST_SHOP = tonumber(arg4)
						lastA = 0
						lastB = 0
						lastA_Bind = 0
						lastB_Bind = 0
						lastA_VIP = 0
						lastB_VIP = 0
					end
				end
			end
			YuanbaoShop_Show()
		end
	elseif ( event == "UPDATE_BOOTH" ) then
		--PushDebugMessage("UPDATE_BOOTH")

		YuanbaoShop_UpdatePage(nPageNum);

	elseif (event == "CLOSE_BOOTH") then
		--PushDebugMessage("CLOSE_BOOTH")
		YuanbaoShop_Close()
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible() ) then
		--PushDebugMessage("UPDATE_YUANBAO")
		if g_tabIndex == ShopTabIdx.YuanBao or g_tabIndex == ShopTabIdx.VipShop then
			YuanbaoShop_Text2 : SetText( "#{YBSD_081225_068}"..tostring(Player:GetData("YUANBAO")))
		elseif g_tabIndex == ShopTabIdx.Bind then
			YuanbaoShop_Text2_Bind : SetText( "#{BDYB_XML_6}"..tostring( Player:GetData("BIND_YUANBAO")).."/"..tostring(Player:GetData("YUANBAO")) )
		end
	elseif (event == "UPDATE_BIND_YUANBAO" and this:IsVisible()) then
		YuanbaoShop_Text2_Bind : SetText( "#{BDYB_XML_6}"..tostring( Player:GetData("BIND_YUANBAO")).."/"..tostring(Player:GetData("YUANBAO")) )
	elseif (event == "UPDATE_GIFTTOKEN" and this:IsVisible() and g_tabIndex == ShopTabIdx.GiftToken) then
		YuanbaoShop_Text2 : SetText( "#{YBFQ_XML_4}"..tostring(Player:GetData("GIFTTOKEN")))
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 888902) then
		g_nTargetID = Get_XParam_INT( 0 )
		if Get_XParam_INT( 1 ) ~= 0 and Get_XParam_INT( 2 ) ~= 0 then
			lastA = Get_XParam_INT( 1 )
			lastB = Get_XParam_INT( 2 )
			LAST_TAG = lastA
			LAST_SHOP = lastB
			lastSelect = 0
			YuanbaoShop_ChangeTabIndex( 1 )
			YuanbaoShop_ChangeTabIndex( 0 )
		end
		YuanbaoShop_Show()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 20120508) then  --通宝商店
		g_nTargetID = Get_XParam_INT( 0 )
		if Get_XParam_INT( 1 ) ~= 0 and Get_XParam_INT( 2 ) ~= 0 then
			lastA = Get_XParam_INT( 1 )
			lastB = Get_XParam_INT( 2 )
			LAST_TAG = lastA
			LAST_SHOP = lastB
			lastSelect = 0
		end
		g_jumpToShopTabIndex=5  --默认通宝商店页
		YuanbaoShop_Show()
	elseif( event == "ADJEST_UI_POS" ) then
		YuanbaoShop_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		YuanbaoShop_ResetPos()
	elseif( event == "GAMELOGIN_OPEN_SELECT_CHARACTOR") then
		YuanbaoShop_ResetInfo()
	elseif( event == "OPEN_YUANBAOSHOP_RECENTLY" ) then
		YuanbaoShop_UpdateRecent()
	elseif ( event == "OPEN_JIYUAN_BOOTH" ) then
		YuanbaoShop_UpdateJiYuanBooth()
	elseif (event == "UPDATE_VIP_INFO") then
		YuanbaoShop_UpdateVipInfo()
	elseif (event == "UPDATE_LIJIN" and this:IsVisible()) then   --通宝数量显示
		YuanbaoShop_Lijin_Text2:SetText("#{LJSD_120508_08}"..tostring(Player:GetData("LIJIN")))
		YuanbaoShop_LijinDisCoutnMD()
	elseif (event == "LIJIN_DISCNT_CONFIRMRES" ) then 
		if tonumber(arg0) == 1 then
			local nIndex = tonumber(arg1)
			GOODS_BUTTONS[nIndex]:DoAction();
		elseif tonumber(arg0) == 2 then
			YuanbaoShop_UpdateList(5)
		end
		
	elseif event == "ZBS_SPECIALSERVER_2018" then
		--打造图
		SHOP_LIST_A[8] = {btn = YuanbaoShop_Button8 , shopname="#{WCBS_180522_352}" ,tooltips="#{WCBS_180522_359}", shoplist = {}, shoplisttips = {}}
		SHOP_LIST_A[8].shoplist[1] = "#{WCBS_180522_361}"	--"神品手记";
		SHOP_LIST_A[8].shoplist[2] = "#{WCBS_180522_362}"	--"珍品手记";
		SHOP_LIST_A[8].shoplist[3] = "#{WCBS_180522_363}"	--"精品手记";
		SHOP_LIST_A[8].shoplist[4] = "#{WCBS_180522_364}"	--"良品手记";
		SHOP_LIST_A[8].shoplist[5] = "#{WCBS_180522_357}"	--秘技
		SHOP_LIST_A[8].shoplist[6] = nil
		SHOP_LIST_A[8].shoplist[7] = nil 
		SHOP_LIST_A[8].shoplist[8] = nil
	end
end

function YuanbaoShop_UpdateJiYuanBooth()
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
			GOODS_JiYuan_DESCS[i]:SetText("");
			GOODS_JiYuan_BAD[i]:SetText("");
			GOODS_JiYuan_BUTTONS_Buy[i] : Hide()
			i = i+1;
		end
	end
	NpcShop:CloseConfirm();
end

function YuanbaoShop_UpdateRecent()
	local i = 1;
	while i <= GOODS_BUTTONSRECENTLY_NUM do
		local theAction = EnumAction(i - 1, "yuanbaorecently");
		if theAction:GetID() ~= 0 then
			local nEquipPoint = theAction:GetEquipPoint();


			GOODSRECENTLY_BUTTONS[i]:SetActionItem(theAction:GetID());

			local	nPrice	= NpcShop:EnumItemPriceRecently( i - 1 )
			if (g_tabIndex == ShopTabIdx.YuanBao or g_tabIndex == ShopTabIdx.VipShop) then
				GOODSRECENTLY_DESCS[i]:SetText("#cfff263".."#{YBSD_081225_101}")
			elseif (g_tabIndex == ShopTabIdx.Bind) then
				GOODSRECENTLY_DESCS[i]:SetText("#cfff263".."#{BDYB_090714_01}")
			elseif (g_tabIndex == ShopTabIdx.GiftToken) then
				GOODSRECENTLY_DESCS[i]:SetText("#cfff263".."#{YBFQ_XML_1}")
			end
			GOODSRECENTLY_BAD[i]:SetText("#cfff263"..tostring(nPrice))
			i = i+1;
		else
			GOODSRECENTLY_BUTTONS[i]:SetActionItem(-1);
			GOODSRECENTLY_DESCS[i]:SetText("");
			GOODSRECENTLY_BAD[i]:SetText("");
			i = i+1;
		end
	end
	NpcShop:CloseConfirm();
end

function YuanbaoShop_GoodRecent_Clicked(nIndex)
	if(nIndex < 1 or nIndex > 5) then
		return;
	end

	GOODSRECENTLY_BUTTONS[nIndex]:DoAction();
end
--机缘秘宝购买物品
function YuanbaoShop_JiYuanGood_Clicked(nIndex, nWhich)
	if(nIndex < 1 or nIndex > 6) then
		return;
	end
	local theAction = EnumAction(nIndex - 1, "boothjiyuanitem");
	if theAction:GetID() == 0 then
		return
	end
	--批量购买状态
	if Player :GetPlayerActionStatus() == 1 and nWhich == 0 then
		PushDebugMessage("#{FFSDGZ_120615_128}")
		return
	elseif Player :GetPlayerActionStatus() == 2 and nWhich == 0 then --试穿状态
		PushDebugMessage("#{FFSDGZ_120615_128}")
		return
	elseif Player :GetPlayerActionStatus() == 3 and nWhich == 0 then --试穿赠送状态
		PushDebugMessage("#{FFSDGZ_120615_128}")
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
--==================
--打开商店
function YuanbaoShop_Show()
	if lastA < 1 or lastA > maxChildShop then
		lastA = LAST_TAG;
		lastB = LAST_SHOP;
	end

	if lastB < 1 or lastB > maxChildShop then
		lastB = LAST_SHOP;
	end

	local kajiType = KaJi:LuaFnGetKaJiType(8)
	if kajiType == 1 then
		SHOP_LIST_A[7].shoplist[1] = "#{YBSD_081225_042}"	--"还施水阁";
		SHOP_LIST_A[7].shoplist[2] = nil
		SHOP_LIST_A[7].shoplist[3] = nil
		SHOP_LIST_A[7].shoplist[4] = nil
	elseif Player:GetData("Is2606S") == 1 then
		SHOP_LIST_A[7].shoplist[1] = "#{YBSD_081225_042}"	--"还施水阁";	
		SHOP_LIST_A[7].shoplist[2] = "#{YBSD_XML_4}"	--"琅嬛玉府";
		SHOP_LIST_A[7].shoplist[3] = nil
		SHOP_LIST_A[7].shoplist[4] = nil
	else
		SHOP_LIST_A[7].shoplist[1] = "#{YBSD_081225_042}"	--"还施水阁";	
		SHOP_LIST_A[7].shoplist[2] = "#{YBSD_XML_4}"	--"琅嬛玉府";
		SHOP_LIST_A[7].shoplist[3] = "#{YBSD_XML_6}"	--"嵩阳书院";
		SHOP_LIST_A[7].shoplist[4] = "#{YBSD_XML_7}"	--"岳麓书院";
	end 
	
	if Player:GetData("Is2606S") == 1 then
		SHOP_SEARCH_LIST[7][3] = "#{YBSD_081225_028}"	--"普通技能馆";
		SHOP_SEARCH_LIST[7][4] = "#{YBSD_081225_029}"	--"高级技能馆";
		SHOP_SEARCH_LIST[7][5] = nil
		SHOP_SEARCH_LIST[7][6] = nil
	else
		SHOP_SEARCH_LIST[7][3] = "#{FFSDGZ_120615_79}"	--"嵩阳书院";
		SHOP_SEARCH_LIST[7][4] = "#{FFSDGZ_120615_80}"	--"岳麓书院";
		SHOP_SEARCH_LIST[7][5] = "#{YBSD_081225_028}"	--"普通技能馆";
		SHOP_SEARCH_LIST[7][6] = "#{YBSD_081225_029}"	--"高级技能馆";
	end 
	
	if GameProduceLogin:IsWeGameServer() > 0 then
		YuanbaoShop_Xinyibi:Disable();
	else
		YuanbaoShop_Xinyibi:Enable();
	end

	lastSelect = 0;
	for i = 1 ,maxChildShop do
		SHOP_LIST_B[i]:Hide()
		if SHOP_LIST_A[lastA].shoplist[i] ~= nil then
			SHOP_LIST_B[i]:SetText(SHOP_LIST_A[lastA].shoplist[i])
			if SHOP_LIST_A[lastA].shoplisttips[i] ~= nil and SHOP_LIST_A[lastA].shoplisttips[i] ~= "" then
				SHOP_LIST_B[i]:SetToolTip(SHOP_LIST_A[lastA].shoplisttips[i])
			else
				SHOP_LIST_B[i]:SetToolTip("")
			end
			SHOP_LIST_B[i]:Show()
		end
	end
	SHOP_LIST_A[lastA].btn:SetCheck(1)
	SHOP_LIST_B[lastB]:SetCheck(1)


	--lastA_Bind = LAST_TAG;
	--lastB_Bind = LAST_SHOP;
	if lastA_Bind < 1 or lastA_Bind > maxChildShop then
		lastA_Bind = LAST_TAG
		lastB_Bind = LAST_SHOP
	end
	if lastB_Bind < 1 or lastB_Bind > maxChildShop then
		lastB_Bind = LAST_SHOP
	end

	lastSelect_Bind = 0;
	for i = 1 ,maxChildShop do
		SHOP_LIST_B_BIND[i]:Hide()
		if SHOP_LIST_A_BIND[lastA_Bind].shoplist[i] ~= nil then
			SHOP_LIST_B_BIND[i]:SetText(SHOP_LIST_A_BIND[lastA_Bind].shoplist[i])
			if SHOP_LIST_A_BIND[lastA_Bind].shoplisttips[i] ~= nil and SHOP_LIST_A_BIND[lastA_Bind].shoplisttips[i] ~= "" then
				SHOP_LIST_B_BIND[i]:SetToolTip(SHOP_LIST_A_BIND[lastA_Bind].shoplisttips[i])
			else
				SHOP_LIST_B_BIND[i]:SetToolTip("")
			end
			SHOP_LIST_B_BIND[i]:Show()
		end
	end
	SHOP_LIST_A_BIND[lastA_Bind].btn:SetCheck(1)
	SHOP_LIST_B_BIND[lastB_Bind]:SetCheck(1)

	SHOP_LIST_A_BIND[1].btn : SetCheck(1)
	if (g_jumpToShopTabIndex == 1) then
		YuanbaoShop_Yuanbao : SetCheck(0)
		YuanbaoShop_Gongzi : SetCheck(1)
		YuanbaoShop_Fanquan : SetCheck(0)
		YuanbaoShop_VIP : SetCheck(0)
		YuanbaoShop_Lijin : SetCheck(0)
		--切换到绑定元宝店
		YuanbaoShop_ChangeTabIndex( 1 )
		g_jumpToShopTabIndex = 0;
	elseif (g_jumpToShopTabIndex == 2 and g_IsEnableFanQuanShop == 1) then
		YuanbaoShop_Yuanbao : SetCheck(0)
		YuanbaoShop_Gongzi : SetCheck(0)
		YuanbaoShop_Fanquan : SetCheck(1)
		YuanbaoShop_VIP : SetCheck(0)
		YuanbaoShop_Lijin : SetCheck(0)
		--切换到返券商店
		YuanbaoShop_ChangeTabIndex( 2 )
		g_jumpToShopTabIndex = 0;
	elseif (g_jumpToShopTabIndex == 3) then
		YuanbaoShop_Yuanbao : SetCheck(0)
		YuanbaoShop_Gongzi : SetCheck(0)
		YuanbaoShop_Fanquan : SetCheck(0)
		YuanbaoShop_VIP : SetCheck(0)
		YuanbaoShop_Lijin : SetCheck(0)
		--切换到炫装
		YuanbaoShop_ChangeTabIndex( 3 )
		g_jumpToShopTabIndex = 0;
	elseif (g_jumpToShopTabIndex == 4) then
		YuanbaoShop_Yuanbao : SetCheck(0)
		YuanbaoShop_Gongzi : SetCheck(0)
		YuanbaoShop_Fanquan : SetCheck(0)
		YuanbaoShop_VIP : SetCheck(1)
		YuanbaoShop_Lijin : SetCheck(0)
		--切换到至尊商店
		YuanbaoShop_ChangeTabIndex( 4 )
		g_jumpToShopTabIndex = 0;
	elseif (g_jumpToShopTabIndex == 5) then
		YuanbaoShop_Yuanbao : SetCheck(0)
		YuanbaoShop_Gongzi : SetCheck(0)
		YuanbaoShop_Fanquan : SetCheck(0)
		YuanbaoShop_VIP : SetCheck(0)
		YuanbaoShop_Lijin : SetCheck(1)
		--切换到通宝商店
		YuanbaoShop_ChangeTabIndex( 5 )
		g_jumpToShopTabIndex = 0;
	elseif (g_jumpToShopTabIndex == 6) then
		YuanbaoShop_Yuanbao : SetCheck(0)
		YuanbaoShop_Gongzi : SetCheck(0)
		YuanbaoShop_Fanquan : SetCheck(0)
		YuanbaoShop_VIP : SetCheck(0)
		YuanbaoShop_Lijin : SetCheck(0)
		YuanbaoShop_Xinyibi :   SetCheck(1)
		--切换到秀场商店
		YuanbaoShop_ChangeTabIndex( 6 )
		g_jumpToShopTabIndex = 0;
	elseif (g_jumpToShopTabIndex == 0) then
		YuanbaoShop_Yuanbao : SetCheck(1)
		YuanbaoShop_Gongzi : SetCheck(0)
		YuanbaoShop_Fanquan : SetCheck(0)
		YuanbaoShop_VIP : SetCheck(0)
		YuanbaoShop_Lijin : SetCheck(0)
		--切换到元宝商店
		YuanbaoShop_ChangeTabIndex( 0 )
		g_jumpToShopTabIndex = 0;
	elseif ( 0 == g_tabIndex ) then
		UpdateShopItem( lastA , lastB )
	else
		YuanbaoShop_Yuanbao : SetCheck(1)
		YuanbaoShop_Gongzi : SetCheck(0)
		YuanbaoShop_Fanquan : SetCheck(0)
		YuanbaoShop_Lijin : SetCheck(0)
		--打开时默认切换到普通元宝店
		YuanbaoShop_ChangeTabIndex( 0 )
	end
	--请求机缘秘宝商店
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OpenJiYuanShop");
		Set_XSCRIPT_ScriptID(888902);
		Set_XSCRIPT_Parameter(0,g_nTargetID);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
	--广告牌 默认第一页
	YuanbaoShop_PlayCardChangePage(1)
end
--===============================
--刷新一页
function YuanbaoShop_UpdatePage(thePage)
	if (g_tabIndex == ShopTabIdx.YuanBao or g_tabIndex == ShopTabIdx.VipShop ) then
		YuanbaoShop_Text2:SetText ("#{YBSD_081225_068}"..tostring(Player:GetData("YUANBAO")))
	elseif (g_tabIndex == ShopTabIdx.GiftToken) then
		YuanbaoShop_Text2 : SetText( "#{YBFQ_XML_4}"..tostring(Player:GetData("GIFTTOKEN")))
	end
	YuanbaoShop_Text2_Bind : SetText( "#{BDYB_XML_6}"..tostring( Player:GetData("BIND_YUANBAO")).."/"..tostring(Player:GetData("YUANBAO")) )
	YuanbaoShop_LijinDisCoutnMD()
	for i=1, GOODS_BUTTONS_NUM  do
		GOOD_BAD[i]:Show()
	end

	local	i = 1;

	if g_nTotalNum == 0 or g_nTotalNum ~= GetActionNum("boothitem") then
		g_nTotalNum	= GetActionNum("boothitem");
		YuanbaoShop_Order();
	end

	-- 计算总页数
	local	nTotalPage;
	if( g_nTotalNum < 1 ) then
		nTotalPage	= 1;
	else
		nTotalPage	= math.floor((g_nTotalNum-1)/GOODS_BUTTONS_NUM)+1;
	end

	maxPage = nTotalPage;

	if(thePage < 1 or thePage > nTotalPage) then
		return;
	end
	--HEQUIP_DRESS		=16,	//时装
	--HEQUIP_RIDER		=8,	//骑乘

	nPageNum = thePage;

	local nStartIndex = (thePage-1)*GOODS_BUTTONS_NUM;

	local nActIndex = nStartIndex;
	i = 1;
	while i <= GOODS_BUTTONS_NUM do
		local	idx	= g_tOrderPool[nActIndex+1];
		if idx == nil then
			idx	= -1;
		end

		local theAction = EnumAction(idx, "boothitem");
		if theAction:GetID() ~= 0 then
			GOODS_BUTTONS[i]:SetActionItem(theAction:GetID());
			local IconKey = theAction:GetItemIconInShop()
			if IconKey ~= nil and IconKey ~= "" and IconTable[IconKey] ~= nil then
				GOODS_BUTTONS_ICON[i]:SetProperty("Image" , IconTable[IconKey])
			else
				GOODS_BUTTONS_ICON[i]:SetProperty("Image" , "")
			end
			if(theAction:GetItemColorInShop()~="") then
				GOODS_DESCS[i]:SetText( theAction:GetItemColorInShop()..theAction:GetName() );
			else
				GOODS_DESCS[i]:SetText( theAction:GetName() );
			end

			local	nPrice	= NpcShop:EnumItemPrice( idx )
			if (g_tabIndex == ShopTabIdx.YuanBao or g_tabIndex == ShopTabIdx.VipShop ) then
				GOOD_BAD[i]:SetText("#{YBSD_081225_101}" .. tostring(nPrice))
			elseif (g_tabIndex == ShopTabIdx.Bind) then
				GOOD_BAD[i]:SetText("#{BDYB_090714_01}" .. tostring(nPrice))
			elseif (g_tabIndex == ShopTabIdx.GiftToken) then
				GOOD_BAD[i]:SetText("#{YBFQ_XML_1}" .. tostring(nPrice))
			elseif (g_tabIndex == ShopTabIdx.Lijin) then
				GOOD_BAD[i]:SetText("#{LJSD_120508_38}"..tostring(nPrice))
			end

			i = i+1;
		else
			GOODS_BUTTONS_ICON[i]:SetProperty("Image" , "")
			GOODS_BUTTONS[i]:SetActionItem(-1);
			GOODS_DESCS[i]:SetText("");
			GOOD_BAD[i]:SetText("");
			i = i+1;
		end
		nActIndex = nActIndex+1;
	end

	if( nTotalPage == 1 ) then
		YuanbaoShop_UpPage:Hide();
		YuanbaoShop_DownPage:Hide();
		YuanbaoShop_CurrentlyPage:Hide();
		if (g_tabIndex == ShopTabIdx.GiftToken) then
			YuanbaoShop_BK_PS:Show()
			if GameProduceLogin:IsWeGameClient() > 0 then
				YuanbaoShop_BK_PS_Text:SetText("#{WEJR_230303_32}")
			else
				YuanbaoShop_BK_PS_Text:SetText("#{FQSD_130809_01}")
			end
			YuanbaoShop_BK_PS_Text:Show()
		end
	else
		YuanbaoShop_UpPage:Show();
		YuanbaoShop_DownPage:Show();
		YuanbaoShop_CurrentlyPage:Show();
		if (g_tabIndex == ShopTabIdx.GiftToken) then
			YuanbaoShop_BK_PS_Text:Hide()
			YuanbaoShop_BK_PS:Hide()
		end

		YuanbaoShop_UpPage:Enable();
		YuanbaoShop_DownPage:Enable();

		if ( nPageNum == nTotalPage ) then
			YuanbaoShop_DownPage:Disable();
		end

		if ( nPageNum == 1 ) then
			YuanbaoShop_UpPage:Disable()
		end

		YuanbaoShop_CurrentlyPage:SetText(tostring(nPageNum) .. "/" .. tostring(nTotalPage) );
	end
	if NpcShop:GetShopType("buymult") ~= nil and NpcShop:GetShopType("buymult") > 0 then
		YuanbaoShop_MBuy:Enable()
	else
		YuanbaoShop_MBuy:Disable()
	end
	if NpcShop:GetShopType("giveother") ~= nil and NpcShop:GetShopType("giveother") > 0 then
		YuanbaoShop_Gift:Enable()
	else
		YuanbaoShop_Gift:Disable()
	end
end
--点击一级标签
function YuanbaoShop_UpdateList(nIndex)
	if(IsWindowShow("Shop_MBuy")) then
		CloseWindow("Shop_MBuy", true);
	end
	if(IsWindowShow("Shop_MGift")) then
		CloseWindow("Shop_MGift", true);
	end
	--恢复二级按钮的位置
	local nLevel = DataPool:GetAccVipLevel()
	if g_tabIndex ~= ShopTabIdx.VipShop or nLevel >= g_Min_ShowBaoShiGe_VipLevel then
		for i = 3, table.getn(SHOP_LIST_B_VIP) do
			local y_pos = SHOP_LIST_B_VIP[i - 1] : GetProperty("AbsoluteYPosition");
			SHOP_LIST_B_VIP[i] : SetProperty("AbsoluteYPosition", y_pos + g_nDistanceBBtnY);
		end
	end
	if g_tabIndex == ShopTabIdx.GiftToken then
		YuanbaoShop_UpdateList_GiftToken(nIndex)
		return
	end
	if g_tabIndex == ShopTabIdx.VipShop then
		YuanbaoShop_UpdateList_VIP(nIndex)
		return
	end
	if g_tabIndex == ShopTabIdx.Lijin then
		YuanbaoShop_UpdateList_Lijin(nIndex)
		if nIndex == 5 or nIndex == 2 then
			YuanbaoShop_zhekougoumai_Text:Show();
			YuanbaoShop_zhekougoumai_Text:SetToolTip("#{LJSD_180312_02}")
		else
			YuanbaoShop_zhekougoumai_Text:Hide();
			YuanbaoShop_zhekougoumai_Text:SetToolTip("")			
		end
		YuanbaoShop_LijinDisCoutnMD()			
		return
	end
	LAST_TAG = nIndex
	SHOP_LIST_A[nIndex].btn:SetCheck(1)
	--PushDebugMessage("YuanbaoShop_UpdateList:"..nIndex);
	if (nIndex <1 or nIndex > 8 or ( nIndex == lastA and g_changeTabFlag == 0 )) and this:IsVisible()  then
		return
	end

	for i = 1 ,maxChildShop do
		SHOP_LIST_B[i]:Hide()
		if SHOP_LIST_A[nIndex].shoplist[i] ~= nil then
			SHOP_LIST_B[i]:SetText(SHOP_LIST_A[nIndex].shoplist[i])
			if SHOP_LIST_A[nIndex].shoplisttips[i] ~= nil and SHOP_LIST_A[nIndex].shoplisttips[i] ~= "" then
				SHOP_LIST_B[i]:SetToolTip(SHOP_LIST_A[nIndex].shoplisttips[i])
			else
				SHOP_LIST_B[i]:SetToolTip("")
			end
			SHOP_LIST_B[i]:Show()
		end
	end
	SHOP_LIST_B[1]:SetCheck(1)
	lastB = 1
	lastA = nIndex
	lastSelect = 0

	UpdateShopItem( lastA ,lastB )
end
--点击店铺
function YuanbaoShop_UpdateShop(nIndex)
	if(IsWindowShow("Shop_MBuy")) then
		CloseWindow("Shop_MBuy", true);
	end
	if(IsWindowShow("Shop_MGift")) then
		CloseWindow("Shop_MGift", true);
	end
	LAST_SHOP = nIndex;
	local bOpenZhuJiGe = DataPool : IsZhuJiVipShopOpen()
	if g_tabIndex == ShopTabIdx.VipShop and nIndex == 3 and bOpenZhuJiGe <= 0 then
		SetTimer("YuanbaoShop","YuanBaoShop_UpdateBthStatus()",5)
		PushDebugMessage("#{FFSDGZ_120615_99}");
		return
	end
	if nIndex < maxChildShop then
		SHOP_LIST_B[nIndex]:SetCheck(1)
	end
	if g_tabIndex == ShopTabIdx.GiftToken then
		YuanbaoShop_UpdateShop_GiftToken(nIndex)
		return
	end
	if g_tabIndex == ShopTabIdx.VipShop then
		YuanbaoShop_UpdateShop_VIP(nIndex)
		return
	end
	if g_tabIndex == ShopTabIdx.Lijin then
		YuanbaoShop_UpdateShop_Lijin(nIndex)
		return
	end
	if nIndex <1 or nIndex > maxChildShop or ( nIndex == lastB and g_changeTabFlag == 0 ) then
		return
	end

	lastB = nIndex
	LAST_TAG = lastA;
	if lastSelect > 0 and lastSelect <= table.getn(SHOP_SEARCH_LIST) then
		UpdateShopItem( lastSelect+8 , lastB )
	elseif lastA > 0 and lastA < 9 then
		if lastA <= 0 or lastA > table.getn(SHOP_LIST_A) then
			lastA = 1
		end
		if lastB <= 0 or lastB > table.getn(SHOP_LIST_B) then
			lastB = 1
		end
		UpdateShopItem( lastA , lastB )
	else
		UpdateShopItem( 1 , 1)
	end
end

function YuanBaoShop_UpdateBthStatus()
	SHOP_LIST_B_VIP[3]:SetCheck(0)
	SHOP_LIST_B_VIP[lastB_VIP]:SetCheck(1)
	KillTimer("YuanBaoShop_UpdateBthStatus()")
end
--查找
function YuanbaoShop_BeginSearch()

	if ( YuanbaoShop_SearchMode_Bind : IsVisible( ) ) then
		YuanbaoShop_BeginSearch_Bind();
		return;
	end

	local str , nIndex = YuanbaoShop_SearchMode:GetCurrentSelect()

	if nIndex <1 or nIndex > table.getn(SHOP_SEARCH_LIST) then
		return
	end

	for i = 1 ,maxChildShop do
		SHOP_LIST_B[i]:Hide()
		if SHOP_SEARCH_LIST[nIndex][i] ~= nil then
			SHOP_LIST_B[i]:SetText(SHOP_SEARCH_LIST[nIndex][i])
			SHOP_LIST_B[i]:Show()
		end
	end

	SHOP_LIST_B[1]:SetCheck(1)
	lastB = 1
	lastA = 0
	lastSelect = nIndex

	for i = 1 ,8 do
		SHOP_LIST_A[i].btn:SetCheck(0)
	end

	UpdateShopItem( nIndex+8 , 1 )
end

-- 绑定元宝 begin

--点击一级标签
function YuanbaoShop_UpdateList_Bind(nIndex)
	LAST_TAG = nIndex
	if nIndex < maxChildShop then
		SHOP_LIST_A_BIND[nIndex].btn:SetCheck(1)
	end
	--PushDebugMessage("YuanbaoShop_UpdateList_Bind:"..nIndex);
	if (nIndex < 1 or nIndex > 8 or ( nIndex == lastA_Bind and g_changeTabFlag == 0 )) and this:IsVisible() then
		return
	end

	for i = 1 , maxChildShop do
		SHOP_LIST_B_BIND[i]:Hide()
		if SHOP_LIST_A_BIND[nIndex].shoplist[i] ~= nil then
			SHOP_LIST_B_BIND[i]:SetText(SHOP_LIST_A_BIND[nIndex].shoplist[i])
			if SHOP_LIST_A_BIND[nIndex].shoplisttips[i] ~= nil and SHOP_LIST_A_BIND[nIndex].shoplisttips[i] ~= "" then
				SHOP_LIST_B_BIND[i]:SetToolTip(SHOP_LIST_A_BIND[nIndex].shoplisttips[i])
			else
				SHOP_LIST_B_BIND[i]:SetToolTip("")
			end
			SHOP_LIST_B_BIND[i]:Show()
		end
	end
	--恢复二级按钮的位置
	local nLevel = DataPool:GetAccVipLevel()
	if g_tabIndex ~= ShopTabIdx.VipShop or nLevel >= g_Min_ShowBaoShiGe_VipLevel then
		for i = 3, table.getn(SHOP_LIST_B_VIP) do
			local y_pos = SHOP_LIST_B_VIP[i - 1] : GetProperty("AbsoluteYPosition");
			SHOP_LIST_B_VIP[i] : SetProperty("AbsoluteYPosition", y_pos + g_nDistanceBBtnY);
		end
	end
	SHOP_LIST_B_BIND[1]:SetCheck(1)
	lastB_Bind = 1
	lastA_Bind = nIndex
	lastSelect_Bind = 0

	UpdateShopItem( lastA_Bind + 100 ,lastB_Bind )
end

--点击店铺
function YuanbaoShop_UpdateShop_Bind(nIndex)
	LAST_SHOP = nIndex;

	if (nIndex <1 or nIndex > maxChildShop or ( nIndex == lastB_Bind and g_changeTabFlag == 0 )) and this:IsVisible() then
		return
	end
	--PushDebugMessage("YuanbaoShop_UpdateShop_Bind:"..nIndex..",lastB_Bind:"..lastB_Bind..",g_changeTabFlag:"..g_changeTabFlag.."maxChildShop"..maxChildShop );
	SHOP_LIST_B_BIND[nIndex]:SetCheck(1)
	lastB_Bind = nIndex
	LAST_TAG = lastA_Bind;
	if lastSelect_Bind > 0 and lastSelect_Bind < 8 then
		UpdateShopItem( lastSelect_Bind + 108 , lastB_Bind )
	elseif lastA_Bind > 0 and lastA_Bind < 9 then
		UpdateShopItem( lastA_Bind + 100 , lastB_Bind )
	else
		UpdateShopItem( 1 , 1)
	end

end

--查找
function YuanbaoShop_BeginSearch_Bind()

	local str , nIndex = YuanbaoShop_SearchMode_Bind:GetCurrentSelect()

	if nIndex <1 or nIndex > 7 then
		return
	end

	for i = 1 ,maxChildShop do
		SHOP_LIST_B_BIND[i]:Hide()
		if SHOP_SEARCH_LIST_BIND[nIndex][i] ~= nil then
			SHOP_LIST_B_BIND[i]:SetText(SHOP_SEARCH_LIST_BIND[nIndex][i])
			SHOP_LIST_B_BIND[i]:Show()
		end
	end

	SHOP_LIST_B_BIND[1]:SetCheck(1)
	lastB_Bind = 1
	lastA_Bind = 0
	lastSelect_Bind = nIndex

	for i = 1 ,8 do
		SHOP_LIST_A_BIND[i].btn:SetCheck(0)
	end

	UpdateShopItem( nIndex + 108 , 1 )
end
---------------------------------------- 至尊商店 -------------------------------------------
--点击一级标签
function YuanbaoShop_UpdateList_VIP(nIndex)
	LAST_TAG = nIndex
	--SHOP_LIST_A_VIP[nIndex].btn:SetCheck(1)
	if nIndex <1 or nIndex > 8 or ( nIndex == lastA_VIP and g_changeTabFlag == 0 ) then
		return
	end

	for i = 1 ,maxChildShop do
		SHOP_LIST_B_VIP[i]:Hide()
		if SHOP_LIST_A_VIP[nIndex].shoplist[i] ~= nil then
			SHOP_LIST_B_VIP[i]:SetText(SHOP_LIST_A_VIP[nIndex].shoplist[i])
			if SHOP_LIST_A_VIP[nIndex].shoplisttips[i] ~= nil and SHOP_LIST_A_VIP[nIndex].shoplisttips[i] ~= "" then
				SHOP_LIST_B_VIP[i]:SetToolTip(SHOP_LIST_A_VIP[nIndex].shoplisttips[i])
			else
				SHOP_LIST_B_VIP[i]:SetToolTip("")
			end
			SHOP_LIST_B_VIP[i]:Show()
		end
	end

	--至尊商店只有g_Min_ShowBaoShiGe_VipLevel级以上vip才看到至尊宝石阁
	local nLevel = DataPool:GetAccVipLevel()
	if g_tabIndex == ShopTabIdx.VipShop and table.getn(SHOP_LIST_B_VIP) > 2 then
		if nLevel < g_Min_ShowBaoShiGe_VipLevel then
			--如果vip等级小于9，则隐藏第二个按钮，即至尊宝石阁
			SHOP_LIST_B_VIP[2]:Hide()
			for i = 1, table.getn(SHOP_LIST_B_VIP) - 2 do
				local nCurBtn = table.getn(SHOP_LIST_B_VIP) - (i - 1);
				local y_pos = SHOP_LIST_B_VIP[nCurBtn - 1] : GetProperty("AbsoluteYPosition");
				SHOP_LIST_B_VIP[nCurBtn] : SetProperty("AbsoluteYPosition", y_pos);
			end
		end
	end
	--恢复二级按钮的位置
	if g_tabIndex ~= ShopTabIdx.VipShop or nLevel >= g_Min_ShowBaoShiGe_VipLevel then
		for i = 3, table.getn(SHOP_LIST_B_VIP) do
			local y_pos = SHOP_LIST_B_VIP[i - 1] : GetProperty("AbsoluteYPosition");
			SHOP_LIST_B_VIP[i] : SetProperty("AbsoluteYPosition", y_pos + g_nDistanceBBtnY);
		end
	end
	SHOP_LIST_B_VIP[1]:SetCheck(1)
	lastB_VIP = 1
	lastA_VIP = nIndex

	UpdateShopItem( lastA_VIP + 400, lastB_VIP )
end
--点击店铺
function YuanbaoShop_UpdateShop_VIP(nIndex)
	if nIndex <1 or nIndex > maxChildShop or ( nIndex == lastB_VIP and g_changeTabFlag == 0 ) then
		return
	end

	lastB_VIP = nIndex
	LAST_SHOP = nIndex
	LAST_TAG = lastA_VIP;
	if lastA_VIP > 0 and lastA_VIP < table.getn(SHOP_LIST_A_VIP) then
		UpdateShopItem( lastA_VIP + 400, lastB_VIP )
	else
		UpdateShopItem(401 , 1)
	end
end
---------------------------------------- 返券商店 结束 -------------------------------------------

---------------------------------------- 返券商店 -------------------------------------------
--点击一级标签
function YuanbaoShop_UpdateList_GiftToken(nIndex)
	--PushDebugMessage("YuanbaoShop_UpdateListGiftToken:"..nIndex);
	LAST_TAG = nIndex
	SHOP_LIST_A_GIFTTOKEN[nIndex].btn:SetCheck(1)
	if nIndex <1 or nIndex > 8 or ( nIndex == lastA_GiftToken and g_changeTabFlag == 0 ) then
		return
	end

	for i = 1 ,maxChildShop do
		SHOP_LIST_B_GIFTTOKEN[i]:Hide()
		if SHOP_LIST_A_GIFTTOKEN[nIndex].shoplist[i] ~= nil then
			SHOP_LIST_B_GIFTTOKEN[i]:SetText(SHOP_LIST_A_GIFTTOKEN[nIndex].shoplist[i])
			if SHOP_LIST_A_GIFTTOKEN[nIndex].shoplisttips[i] ~= nil and SHOP_LIST_A_GIFTTOKEN[nIndex].shoplisttips[i] ~= "" then
				SHOP_LIST_B_GIFTTOKEN[i]:SetToolTip(SHOP_LIST_A_GIFTTOKEN[nIndex].shoplisttips[i])
			else
				SHOP_LIST_B_GIFTTOKEN[i]:SetToolTip("")
			end
			SHOP_LIST_B_GIFTTOKEN[i]:Show()
		end
	end
	--恢复二级按钮的位置
	local nLevel = DataPool:GetAccVipLevel()
	if g_tabIndex ~= ShopTabIdx.VipShop or nLevel >= g_Min_ShowBaoShiGe_VipLevel then
		for i = 3, table.getn(SHOP_LIST_B_VIP) do
			local y_pos = SHOP_LIST_B_VIP[i - 1] : GetProperty("AbsoluteYPosition");
			SHOP_LIST_B_VIP[i] : SetProperty("AbsoluteYPosition", y_pos + g_nDistanceBBtnY);
		end
	end
	SHOP_LIST_B_GIFTTOKEN[1]:SetCheck(1)
	lastB_GiftToken = 1
	lastA_GiftToken = nIndex
	lastSelec_GiftTokent = 0

	UpdateShopItem( lastA_GiftToken + 200, lastB_GiftToken )
end
--点击店铺
function YuanbaoShop_UpdateShop_GiftToken(nIndex)

	--PushDebugMessage("YuanbaoShop_UpdateShop:"..nIndex);
	if nIndex <1 or nIndex > maxChildShop or ( nIndex == lastB_GiftToken and g_changeTabFlag == 0 ) then
		return
	end

	lastB_GiftToken = nIndex
	LAST_TAG = lastA_GiftToken;
	LAST_SHOP = nIndex
	if lastSelect_GiftToken > 0 and lastSelect_GiftToken <= table.getn(SHOP_SEARCH_LIST_GIFTTOKEN) then
		UpdateShopItem( lastSelect_GiftToken+208 , lastB_GiftToken )
	elseif lastA_GiftToken > 0 and lastA_GiftToken < table.getn(SHOP_LIST_A_GIFTTOKEN) then
		UpdateShopItem( lastA_GiftToken + 200, lastB_GiftToken )
	else
		UpdateShopItem(201 , 1)
	end
end
--查找
function YuanbaoShop_BeginSearch_GiftToken()

	lastB_GiftToken = 1
	lastA_GiftToken = 0
	lastSelect_GiftToken = 0
end
---------------------------------------- 返券商店 结束 -------------------------------------------

---------------------------------------- 通宝商店 开始 -------------------------------------------

--点击一级目录
function YuanbaoShop_UpdateList_Lijin(nIndex)
	SHOP_LIST_A_LIJIN[nIndex].btn:SetCheck(1)
	LAST_TAG = nIndex
	if nIndex < 1 or nIndex > table.getn(SHOP_LIST_A_LIJIN) or nIndex == lastA_Lijin and g_changeTabFlag == 0 then
		return
	end


	for i = 1, table.getn(SHOP_LIST_B_LIJIN) do
		SHOP_LIST_B_LIJIN[i]:Hide()
		if SHOP_LIST_A_LIJIN[nIndex].shoplist[i] ~= nil then
			SHOP_LIST_B_LIJIN[i]:SetText(SHOP_LIST_A_LIJIN[nIndex].shoplist[i])
			SHOP_LIST_B_LIJIN[i]:Show()
		end
	end
	local nLevel = DataPool:GetAccVipLevel()
	if g_tabIndex ~= ShopTabIdx.VipShop or nLevel >= g_Min_ShowBaoShiGe_VipLevel then
		for i = 3, table.getn(SHOP_LIST_B_VIP) do
			local y_pos = SHOP_LIST_B_VIP[i - 1] : GetProperty("AbsoluteYPosition");
			SHOP_LIST_B_VIP[i] : SetProperty("AbsoluteYPosition", y_pos + g_nDistanceBBtnY);
		end
	end
	SHOP_LIST_B_LIJIN[1]:SetCheck(1)
	lastA_Lijin = nIndex
	lastB_Lijin = 1
	YuanbaoShop_UpdateItem_Lijin(lastA_Lijin, lastB_Lijin)


end

--点击二级目录
function YuanbaoShop_UpdateShop_Lijin(nIndex)
	LAST_SHOP = nIndex
	if nIndex < 1 or nIndex > table.getn(SHOP_LIST_B_LIJIN) or (lastB_Lijin == nIndex and g_changeTabFlag == 0) then
		return
	end

	if LAST_SHOP == 1 and (LAST_TAG == 2 or LAST_TAG == 5) then
		YuanbaoShop_zhekougoumai_Text:Show();
		YuanbaoShop_zhekougoumai_Text:SetToolTip("#{LJSD_180312_02}")		
		YuanbaoShop_LijinDisCoutnMD()		
	else
		YuanbaoShop_zhekougoumai_Text:Hide();
		YuanbaoShop_zhekougoumai_Text:SetToolTip("")
	end
	
	SHOP_LIST_B_LIJIN[nIndex]:SetCheck(1)

	lastB_Lijin = nIndex
	LAST_TAG = lastA_Lijin;

	if lastA_Lijin > 0 and lastA_Lijin <= table.getn(SHOP_LIST_A_LIJIN) then
		YuanbaoShop_UpdateItem_Lijin(lastA_Lijin, lastB_Lijin)
	else
		YuanbaoShop_UpdateItem_Lijin(1, 1)
	end
end

--请求商品信息
function YuanbaoShop_UpdateItem_Lijin(shopA, shopB)
	g_changeTabFlag = 0
	if shopA == 1 and shopB == 8 then
		OpenRecentBuyLiJinShop()
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenLijinShop")
		Set_XSCRIPT_ScriptID(889854)
		Set_XSCRIPT_Parameter(0, g_nTargetID)
		Set_XSCRIPT_Parameter(1, shopA)
		Set_XSCRIPT_Parameter(2, shopB)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	NpcShop:CloseConfirm();
end

---------------------------------------- 通宝商店 结束 -------------------------------------------

--设置菜单的显示属性
function YuanbaoShop_UpdateVisiableProperty(shopAList, shopBList, searchList, lastA, lastB, lastSelect)

	if (shopAList == nil or shopBList == nil or searchList == nil) then
		return
	end

	local findA = 0

	for i=1, table.getn(shopAList) do
		if (table.getn(shopAList[i].shoplist) > 0) then
			shopAList[i].btn : SetText(shopAList[i].shopname)
			shopAList[i].btn : SetToolTip(shopAList[i].tooltips)
			shopAList[i].btn : Show()
			if (i == lastA) then
				findA = i
			end
		else
			shopAList[i].btn : Hide()
		end
	end

	if (findA > 0) then
		shopAList[lastA].btn : SetCheck(1)
		for j = 1, table.getn(shopBList) do
			shopBList[j] : Hide()
			if shopAList[lastA].shoplist[j] ~= nil then
				shopBList[j] : SetText(shopAList[lastA].shoplist[j])
				if shopAList[lastA].shoplisttips[j] ~= nil and shopAList[lastA].shoplisttips[j] ~= "" then
					shopBList[j]:SetToolTip(shopAList[lastA].shoplisttips[j])
				else
					shopBList[j]:SetToolTip("")
				end
				shopBList[j] : Show()
				if j == lastB then
					shopBList[j] : SetCheck(1)
				end
			end
		end
	elseif lastSelect > 0 and lastSelect <= table.getn(searchList) then
		for i = 1 ,table.getn(shopAList) do
			shopAList[i].btn:SetCheck(0)
		end
		for i = 1 ,table.getn(shopBList) do
			shopBList[i]:Hide()
			if searchList[lastSelect][i] ~= nil then
				shopBList[i]:SetText(searchList[lastSelect][i])
				shopBList[i]:Show()
			end
		end
		shopBList[lastB]:SetCheck(1)
	end
	--至尊商店只有g_Min_ShowBaoShiGe_VipLevel级以上vip才看到至尊宝石阁
	local nLevel = DataPool:GetAccVipLevel()
	if g_tabIndex == ShopTabIdx.VipShop and table.getn(shopBList) > 2 then
		if nLevel < g_Min_ShowBaoShiGe_VipLevel then
			--如果vip等级小于9，则隐藏第二个按钮，即至尊宝石阁
			shopBList[2]:Hide()
			for i = 1, table.getn(shopBList) - 2 do
				local nCurBtn = table.getn(shopBList) - (i - 1);
				local y_pos = shopBList[nCurBtn - 1] : GetProperty("AbsoluteYPosition");
				shopBList[nCurBtn] : SetProperty("AbsoluteYPosition", y_pos);
			end
		end
	end
	if g_tabIndex ~= ShopTabIdx.VipShop or nLevel >= g_Min_ShowBaoShiGe_VipLevel then
		for i = 3, table.getn(shopBList) do
			local y_pos = shopBList[i - 1] : GetProperty("AbsoluteYPosition");
			shopBList[i] : SetProperty("AbsoluteYPosition", y_pos + g_nDistanceBBtnY);
		end
	end
end

function YuanbaoShop_ChangeTabIndex( nIndex )
	if g_IsEnableFanQuanShop == 0 then
		if (nIndex == ShopTabIdx.GiftToken) then --关闭返券商店
			return
		end
	end


	if ( nIndex == g_tabIndex  and this:IsVisible()) then
		return
	end

	if(IsWindowShow("Shop_MBuy")) then
		CloseWindow("Shop_MBuy", true);
	end
	if(IsWindowShow("Shop_MGift")) then
		CloseWindow("Shop_MGift", true);
	end
	if(IsWindowShow("Shop_Fitting")) then
		CloseWindow("Shop_Fitting", true);
	end
	if(IsWindowShow("Shop_Fitting2")) then
		CloseWindow("Shop_Fitting2", true);
	end
	if(IsWindowShow("ShopPet_Fitting")) then
		CloseWindow("ShopPet_Fitting", true);
	end
	if(IsWindowShow("Shop_InfantFitting")) then
		CloseWindow("Shop_InfantFitting", true);
	end
	if(IsWindowShow("HuanLing_Fitting")) then
		CloseWindow("HuanLing_Fitting", true);
	end
	if(IsWindowShow("DressClosetFrame")) then
		CloseWindow("DressClosetFrame", true);
	end
	if(IsWindowShow("DuanWu_JiFenShop")) then
		CloseWindow("DuanWu_JiFenShop", true);
	end
	RestoreShopFitting(TOTALFITTINGKIND_NUM);
	ClearCurFittingItemByType(TOTALFITTINGKIND_NUM)
	SetDefaultMouse();

	--设置选中状态
	if nIndex == 0 then
		YuanbaoShop_Yuanbao:SetCheck(1)
	elseif nIndex == 1 then
		YuanbaoShop_Gongzi:SetCheck(1)
	elseif nIndex == 3 then
		YuanbaoShop_XuanShop:SetCheck(1)
	elseif nIndex == 2 then
		YuanbaoShop_Fanquan:SetCheck(1)
	elseif nIndex == 5 then
		YuanbaoShop_Lijin:SetCheck(1)
	elseif nIndex == 6 then
		YuanbaoShop_Xinyibi:SetCheck(1)
	end

	g_changeTabFlag = 1
	g_tabIndex = nIndex
	LAST_FENYE = nIndex

	YuanbaoShop_Bk1_Bind : Hide();
	YuanbaoShop_Bk2_Bind : Hide();
	YuanbaoShop_SearchMode_Bind : Hide();
	YuanbaoShop_Bk1 : Hide();
	YuanbaoShop_Bk2 : Hide();
	YuanbaoShop_SearchMode : Hide();
	YuanbaoShop_Try : Disable()
	YuanbaoShop_MBuy : Disable()
	YuanbaoShop_Gift : Disable()
	YuanbaoShop_UpPage : Hide()
	YuanbaoShop_CurrentlyPage : Hide()
	YuanbaoShop_DownPage : Hide()

	YuanbaoShop_Text1 : Hide();
	YuanbaoShop_Begin : Hide();

	YuanbaoShop_Text2 : Hide();
	YuanbaoShop_Text2_Bind : Hide();

	YuanbaoShop_Bk3 : Hide();
	YuanbaoShop_Bk4 : Hide();

	YuanbaoShop_Bk1_VIP : Hide()
	YuanbaoShop_Bk1_Fanquan : Hide()
	YuanbaoShop_BK_PS_Text : Hide()
	YuanbaoShop_BK_PS : Hide()
	YuanbaoShop_Bk : Hide();

	YuanbaoShop_Lijin_Text2 : Hide();
	YuanbaoShop_Lijin_Text1 : Hide();
	YuanbaoShop_zhekougoumai_Text : Hide();
	YuanbaoShop_zhekougoumai_Text:SetToolTip("")
	YuanbaoShop_Lijin_bK : Hide();
	if SystemSetup:IsClassic() == 1 then	--	经典版
		YuanbaoShop_Text:SetText("#{YBSD_081225_073}")
	else
		YuanbaoShop_titleimage:SetProperty("Image", "set:WM_YBShop2 image:YuanBaoTitle_YBShop")
	end

	YuanbaoShop_Duihuan : Show()

	if( nIndex ==  ShopTabIdx.YuanBao ) then
		YuanbaoShop_Bk : Show();
		YuanbaoShop_Bk1 : Show();
		YuanbaoShop_Bk2 : Show();
		YuanbaoShop_SearchMode : Show();

		YuanbaoShop_Text1 : Show();
		YuanbaoShop_Begin : Show();

		YuanbaoShop_Text2 : Show();
		YuanbaoShop_Gift  : Enable();
		--YuanbaoShop_Dis : Show();
		--YuanbaoShop_Dis2 : SetText("#{YBSD_081225_072}");
		--YuanbaoShop_Dis2 : SetToolTip("#{YBSD_081225_097}");
		--YuanbaoShop_Dis2 : Show();
		--YuanbaoShop_Dis3 : Show();
		YuanbaoShop_Try : Enable()
		YuanbaoShop_MBuy : Enable()
		YuanbaoShop_UpPage : Show()
		YuanbaoShop_CurrentlyPage : Show()
		YuanbaoShop_DownPage : Show()


		YuanbaoShop_UpdateVisiableProperty(SHOP_LIST_A, SHOP_LIST_B, SHOP_SEARCH_LIST, lastA, lastB, lastSelect)
		YuanbaoShop_Bk3 : Show();
		local check  = tonumber(NpcShop:GetBuyDirectly());
		if(check>=1)then
			YuanbaoShop_querengoumai:SetCheck(0);
		else
			YuanbaoShop_querengoumai:SetCheck(1);
		end

		YuanbaoShop_UpdateShop( lastB );
		--付费商店改造
		OpenRecentBuyYuanbaoShop()
	elseif( nIndex ==  ShopTabIdx.Bind ) then
		YuanbaoShop_Bk : Show();
		YuanbaoShop_Bk1_Bind : Show();
		YuanbaoShop_Bk2_Bind : Show();

		YuanbaoShop_Text2_Bind : Show();

		YuanbaoShop_Bk4 : Show();
		YuanbaoShop_MBuy : Enable()
		--YuanbaoShop_Dis2 : SetText("#{YBSD_081225_072}");
		--YuanbaoShop_Dis2 : SetToolTip("#{YBSD_081225_097}");
		--YuanbaoShop_Dis2 : Show();

		local check  = tonumber(NpcShop:GetBuyDirectly());
		if(check>=1)then
			YuanbaoShop_querengoumaiBind:SetCheck(0);
		else
			YuanbaoShop_querengoumaiBind:SetCheck(1);
		end

		check  = tonumber(NpcShop:GetUseYBForBind());
		if(check>=1)then
			YuanbaoShop_querenzhifuBind:SetCheck(0);
		else
			YuanbaoShop_querenzhifuBind:SetCheck(1);
		end
		if ( (lastB_Bind == 0) or (SHOP_LIST_A_BIND[lastA_Bind].shoplist[lastB_Bind] == nil)) then
			YuanbaoShop_UpdateVisiableProperty(SHOP_LIST_A_BIND, SHOP_LIST_B_BIND, SHOP_SEARCH_LIST_BIND, 1, 1, 0)
			YuanbaoShop_UpdateList_Bind( 1 );
		else
			YuanbaoShop_UpdateVisiableProperty(SHOP_LIST_A_BIND, SHOP_LIST_B_BIND, SHOP_SEARCH_LIST_BIND, lastA_Bind, lastB_Bind, lastSelect_Bind)
			YuanbaoShop_UpdateShop_Bind( lastB_Bind );
		end
		OpenRecentBuyYuanbaoShop_Bind()
	elseif( nIndex ==  ShopTabIdx.GiftToken ) then
		YuanbaoShop_Bk1 : Show();
		YuanbaoShop_Bk2 : Show();
		YuanbaoShop_Text2 : Show();
		YuanbaoShop_Bk3 : Show();
		--付费商店改造
		YuanbaoShop_Bk : Show();
		YuanbaoShop_Try : Enable()
		YuanbaoShop_MBuy : Enable()
		local check  = tonumber(NpcShop:GetBuyDirectly());
		if(check>=1)then
			YuanbaoShop_querengoumai:SetCheck(0);
		else
			YuanbaoShop_querengoumai:SetCheck(1);
		end

		if ( (lastB_GiftToken == 0) or SHOP_LIST_A_GIFTTOKEN[lastA_GiftToken].shoplist[lastB_GiftToken] == nil ) then
			YuanbaoShop_UpdateVisiableProperty(SHOP_LIST_A_GIFTTOKEN, SHOP_LIST_B_GIFTTOKEN, SHOP_SEARCH_LIST_GIFTTOKEN, 1, 1, 0)
			YuanbaoShop_UpdateList_GiftToken( 1 );
		else
			YuanbaoShop_UpdateVisiableProperty(SHOP_LIST_A_GIFTTOKEN, SHOP_LIST_B_GIFTTOKEN, SHOP_SEARCH_LIST_GIFTTOKEN, lastA_GiftToken, lastB_GiftToken, lastSelect_GiftToken)
			YuanbaoShop_UpdateShop_GiftToken( lastB_GiftToken );
		end
		OpenRecentBuyGiftTokenShop()
	elseif( nIndex ==  ShopTabIdx.VipShop ) then
		YuanbaoShop_Bk1 : Hide();
		YuanbaoShop_Bk2 : Show();	--二级商店按钮
		YuanbaoShop_Text2 : Show();	-- 显示拥有元宝
		YuanbaoShop_Bk3 : Show();		--确认购买

		YuanbaoShop_Bk1_VIP : Show();
		--付费商店改造
		YuanbaoShop_Bk : Show();		--最近购买
		YuanbaoShop_Try : Enable();		--预览按钮
		YuanbaoShop_MBuy : Enable()
		local check  = tonumber(NpcShop:GetBuyDirectly());
		if(check>=1)then
			YuanbaoShop_querengoumai:SetCheck(0);
		else
			YuanbaoShop_querengoumai:SetCheck(1);
		end

		if ( (lastB_VIP == 0) or SHOP_LIST_A_VIP[lastA_VIP].shoplist[lastB_VIP] == nil ) then
			YuanbaoShop_UpdateVisiableProperty(SHOP_LIST_A_VIP, SHOP_LIST_B_VIP, SHOP_SEARCH_LIST_VIP, 1, 1, 0)
			YuanbaoShop_UpdateList_VIP( 1 );
		else
			YuanbaoShop_UpdateVisiableProperty(SHOP_LIST_A_VIP, SHOP_LIST_B_VIP, SHOP_SEARCH_LIST_VIP, lastA_VIP, lastB_VIP, 0)
			YuanbaoShop_UpdateShop_VIP( lastB_VIP );
		end
		OpenRecentBuyVipShop()
		YuanbaoShop_UpdateVipInfo()
	elseif (nIndex == ShopTabIdx.IMDress) then
		LAST_TAG = 1;  --跳到炫装页面上，不保留元宝商店的选项
		LAST_SHOP = 1;
		PushEvent("OPEN_IMDRESS_YUANBAOSHOP", tostring(nIndex), YuanbaoShop_Frame:GetProperty("UnifiedXPosition"), YuanbaoShop_Frame:GetProperty("UnifiedYPosition"))
	elseif (nIndex == ShopTabIdx.Lijin) then
		YuanbaoShop_Lijin_Show()
	-- elseif (nIndex == ShopTabIdx.Xiuchang) then
	-- 	LAST_TAG = 1;  
	-- 	LAST_SHOP = 1;
	-- 	PushEvent("OPEN_SHOWCREDITSHOP", tostring(nIndex), YuanbaoShop_Frame:GetProperty("UnifiedXPosition"), YuanbaoShop_Frame:GetProperty("UnifiedYPosition"))
	end

end
--更新vip信息
function YuanbaoShop_UpdateVipInfo()
	--vip等级显示
	local nAccCost , nAccNeedCost = DataPool:GetVipAccProgress()
	local nAccLevel = DataPool:GetAccVipLevel()
	if nAccLevel > g_Max_Vip_Level then
		return
	end
	YuanbaoShop_Bk1_VIPdis : Show()
	local szCurVipLevel = ScriptGlobal_Format("#{FFSDGZ_120615_30}",tostring(nAccLevel))
	YuanbaoShop_Bk1_VIP_test1:SetText(szCurVipLevel)
	if nAccLevel < g_Max_Vip_Level then
		if nAccNeedCost > 0 then
			YuanbaoShop_Bk1_VIPexp:SetProgress(tonumber(nAccCost) , nAccNeedCost)
			local nextleveltips = ScriptGlobal_Format("#{VIPTQ3_120517_14}", tostring(nAccNeedCost - nAccCost) , tostring(nAccLevel+1))
			YuanbaoShop_Bk1_VIPexp:SetToolTip(nextleveltips)
		else
			YuanbaoShop_Bk1_VIPexp:SetProgress(100,100)
			YuanbaoShop_Bk1_VIPexp:SetToolTip("")
		end
	elseif nAccLevel == g_Max_Vip_Level then
		YuanbaoShop_Bk1_VIPdis : Hide()
		YuanbaoShop_Bk1_VIPexp:SetProgress(0,100)
		local nextleveltips = ScriptGlobal_Format("#{VIPTQ3_120517_14}", tostring(nAccNeedCost - nAccCost) , tostring(nAccLevel+1))
		YuanbaoShop_Bk1_VIPexp:SetToolTip("#{FFSDGZ_120615_122}")
	end
	if nAccLevel > 0 then
		--这个玩家是vip，并且这个角色激活了vip
		YuanbaoShop_Bk1_VIP_test2:SetText("#{FFSDGZ_120615_82}")
	--elseif nAccLevel > 0 then
		--这个玩家是vip，但是这个角色没有激活
		--local szVipInfo = ScriptGlobal_Format("#{FFSDGZ_120615_117}", nAccLevel )
		--YuanbaoShop_Bk1_VIP_test2:SetText(szVipInfo)
	elseif nAccLevel <= 0 then
		--这个玩家不是天龙VIP
		YuanbaoShop_Bk1_VIP_test2:SetText("#{FFSDGZ_120615_115}")
	end
end
-- 绑定元宝 end
--批量购买
function YuanbaoShop_StartMultiBuy()
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
	if(IsWindowShow("Shop_MBuy")) then
		CloseWindow("Shop_MBuy", true);
	end
	if(IsWindowShow("Shop_MGift")) then
		CloseWindow("Shop_MGift", true);
	end
	if(IsWindowShow("Shop_Fitting")) then
		CloseWindow("Shop_Fitting", true);
	end
	if(IsWindowShow("Shop_Fitting2")) then
		CloseWindow("Shop_Fitting2", true);
	end
	if(IsWindowShow("ShopPet_Fitting")) then
		CloseWindow("ShopPet_Fitting", true);
	end
	if(IsWindowShow("HuanLing_Fitting")) then
		CloseWindow("HuanLing_Fitting", true);
	end
	if(IsWindowShow("Shop_InfantFitting")) then
		CloseWindow("Shop_InfantFitting", true);
	end
	NpcShop:CloseConfirm();
	PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
	PrepearBuyMult();
	SetNotifyTip("#{FFSDGZ_120615_94}");
end
--赠送
function YuanbaoShop_StartGiveGift()

	if IsZbs2018SpeicalServer() >= 1 then
		PushDebugMessage("#{WCBS_180307_20}")
		return
	end
	
	if IsDfsSpeicalServer() >= 1 then
		PushDebugMessage("#{SJDF_190603_01}")
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
	if (Player:GetData("LEVEL") < 50) then
		PushDebugMessage("#{FFSDGZ_120615_101}")
		return;
	end
	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	if(IsWindowShow("Shop_MBuy")) then
		CloseWindow("Shop_MBuy", true);
	end
	if(IsWindowShow("Shop_MGift")) then
		CloseWindow("Shop_MGift", true);
	end
	if(IsWindowShow("Shop_Fitting")) then
		CloseWindow("Shop_Fitting", true);
	end
	if(IsWindowShow("Shop_Fitting2")) then
		CloseWindow("Shop_Fitting2", true);
	end
	if(IsWindowShow("ShopPet_Fitting")) then
		CloseWindow("ShopPet_Fitting", true);
	end
	if(IsWindowShow("HuanLing_Fitting")) then
		CloseWindow("HuanLing_Fitting", true);
	end
	if(IsWindowShow("Shop_InfantFitting")) then
		CloseWindow("Shop_InfantFitting", true);
	end
	NpcShop:CloseConfirm();
	PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
	Booth_EnterGiveGift();
	SetNotifyTip("#{FFSDGZ_120615_100}");
end
--试穿
function YuanbaoShop_OpenFitting()
	if IsIdleLogic() ~= 1 and IsMoveLogic() ~= 1 then
		SetNotifyTip("#{YBSD_081225_100}");
		return 0;
	end
	StopMove();
	if(IsWindowShow("Shop_MBuy")) then
		CloseWindow("Shop_MBuy", true);
	end
	if(IsWindowShow("Shop_MGift")) then
		CloseWindow("Shop_MGift", true);
	end
	if(IsWindowShow("Shop_Fitting")) then
		CloseWindow("Shop_Fitting", true);
	end
	if(IsWindowShow("Shop_Fitting2")) then
		CloseWindow("Shop_Fitting2", true);
	end
	if(IsWindowShow("ShopPet_Fitting")) then
		CloseWindow("ShopPet_Fitting", true);
	end
	if(IsWindowShow("HuanLing_Fitting")) then
		CloseWindow("HuanLing_Fitting", true);
	end
	if(IsWindowShow("Shop_InfantFitting")) then
		CloseWindow("Shop_InfantFitting", true);
	end
	RestoreShopFitting(TOTALFITTINGKIND_NUM);
	ClearCurFittingItemByType(TOTALFITTINGKIND_NUM)
	MouseCmd_ShopFittingSet();
	PushEvent("YUANBAOSHOP_FITTING_RESET")
	SetNotifyTip("#{YBSD_081225_099}");
end
--请求商店信息
function UpdateShopItem( shopA , shopB)

	--PushDebugMessage("shopA:"..shopA..",shopB:"..shopB );
	g_changeTabFlag = 0

	-- 最近购买特殊处理
	if (shopA == 1 and shopB == 8) or (shopA == 16 and shopB == 1) then
		OpenRecentBuyYuanbaoShop();
		return;
	end

	if shopA == 101 and shopB == 8 then
		OpenRecentBuyYuanbaoShop_Bind();
		return;
	end
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OpenYuanbaoShop");
		Set_XSCRIPT_ScriptID(888902);
		Set_XSCRIPT_Parameter(0,g_nTargetID);
		Set_XSCRIPT_Parameter(1,shopA);
		Set_XSCRIPT_Parameter(2,shopB);
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT();
	NpcShop:CloseConfirm();
end
--===============================================
-- Button_Clicked
--===============================================
function YuanbaoShop_GoodButton_Clicked(nIndex)
	if(nIndex < 1 or nIndex > 18) then
		return;
	end
	local nMD = math.mod(DataPool:GetPlayerMission_DataRound(g_LiJinDisCountMD),10);
	if g_tabIndex == ShopTabIdx.Lijin and nMD < g_LiJinDisMaxCnt and lastA_Lijin == 2 and lastB_Lijin == 1 then
		PushEvent( "LIJIN_DISCNT_CONFIRM",nIndex,nMD)
	else
		GOODS_BUTTONS[nIndex]:DoAction();
	end
	
end
--===============================================
-- PageUp
--===============================================
function YuanbaoShop_PageUp()
	curPage = nPageNum - 1;
	if ( curPage >= maxPage ) then
		curPage = maxPage;
	end
	NpcShop:CloseConfirm();
	PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
	YuanbaoShop_UpdatePage( curPage );
end

--===============================================
-- PageDown
--===============================================
function YuanbaoShop_PageDown()
	curPage = nPageNum + 1;
	if ( curPage < 0 )  then
		curPage = 0;
	end
	NpcShop:CloseConfirm();
	PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
	YuanbaoShop_UpdatePage( curPage );
end

--===============================================
-- Close
--===============================================
function YuanbaoShop_Close()
	this:Hide();
end
--===============================================
-- onHiden
--===============================================
function YuanBao_OnHiden()
	g_nTargetID = -1
	objCared = -1
	this:CareObject(objCared, 0, "YuanbaoShop");
	if(IsWindowShow("Shop_Fitting")) then
		CloseWindow("Shop_Fitting", true);
	end
	if(IsWindowShow("Shop_Fitting2")) then
		CloseWindow("Shop_Fitting2", true);
	end
	if(IsWindowShow("ShopPet_Fitting")) then
		CloseWindow("ShopPet_Fitting", true);
	end
	if(IsWindowShow("HuanLing_Fitting")) then
		CloseWindow("HuanLing_Fitting", true);
	end
	if(IsWindowShow("YBShopReference")) then
		CloseWindow("YBShopReference",true)
	end
	if(IsWindowShow("Shop_MBuy")) then
		CloseWindow("Shop_MBuy", true);
	end
	if(IsWindowShow("Shop_MGift")) then
		CloseWindow("Shop_MGift", true);
	end
	if(IsWindowShow("Shop_Fitting2")) then
		CloseWindow("Shop_Fitting2", true);
	end
	if(IsWindowShow("Shop_InfantFitting")) then
		CloseWindow("Shop_InfantFitting", true);
	end
	SetDefaultMouse();
	CloseBooth();
	NpcShop:CloseConfirm();
	PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
	RestoreShopFitting(TOTALFITTINGKIND_NUM);
	ClearCurFittingItemByType(6)
	KillTimer("YuanbaoShop_PlayCardTimer()")
	if lastSelect > 0 then
		lastB = 1
		lastA = 1
		lastSelect = 0
	end
end

--随机排序
function YuanbaoShop_Order()
	local	max		= g_nTotalNum;
	local oldt	= {};
	g_tOrderPool= {};

	for i = 1, tonumber(max) do
	  oldt[i] = i-1;
	end

	if tonumber(NpcShop:GetIsShopReorder()) == 0 then
		g_tOrderPool		= oldt;
	else
		for i = 1, table.getn(oldt) do
		 local idx	= math.random(1, table.getn(oldt));
		 local val	= oldt[idx];
		 g_tOrderPool[i]= val;
		 table.remove(oldt, idx);
		end
	end
end

--确认按钮
function YuanbaoShop_querengoumai_Clicked()
	NpcShop:CloseConfirm();
	PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
	if(NpcShop:GetBuyDirectly() == 0)then
--		YuanbaoShop_querengoumai:SetCheck(0);
		NpcShop:SetBuyDirectly(1);
		NpcShop:SetLiJinBuyDirectly(1)
	else
--		YuanbaoShop_querengoumai:SetCheck(1);
		NpcShop:SetBuyDirectly(0);
		NpcShop:SetLiJinBuyDirectly(0)
	end

end

--确认按钮
function YuanbaoShop_querenzhifu_Clicked()
	if(NpcShop:GetUseYBForBind() == 0)then
		NpcShop:SetUseYBForBind(1)
	else
		NpcShop:SetUseYBForBind(0)
	end
end

--快速充值
--function YuanbaoShop_web_Clicked()
--	GameProduceLogin:OpenURL(GetWeblink("WEB_LOGON_MAIN"))
--end
--目录和查找说明
function YuanbaoShop_Dis_Clicked()
	OpenYBShopReference("#{YBSD_081225_070}")
end
--元宝商店使用说明
function YuanbaoShop_Dis2_Clicked()
    if g_tabIndex == ShopTabIdx.GiftToken then
    	if GameProduceLogin:IsWeGameClient() > 0 then
				OpenYBShopReference("#{WEJR_230303_27}")
			else
				OpenYBShopReference("#{FQ_101210_08}")
			end
    else
    	OpenYBShopReference("#{YBSD_081225_098}")
    end

end
--神秘商店使用说明
function YuanbaoShop_Dis3_Clicked()
	OpenYBShopReference("#{SMSD_100127_01}")
end

--滚动信息顺序随机排列
function YubanbaoShop_ADRandom()
	YuanbaoShop_ScrollInfo_Frame:ClearInfo()

	local ADInfo = {}
	ADInfo[1] = "#{YBSD_081225_093}"
	ADInfo[2] = "#{YBSD_081225_094}"
	ADInfo[3] = "#{YBSD_081225_095}"
	ADInfo[4] = "#{FQ_101210_25}"

	local today = tonumber(GetTime2Day())
	if today >= 20120308 and today <= 20120328 then
		ADInfo[5] = "#{BSLH_111128_08}"
	end

	local nADInfoNum = table.getn(ADInfo)

	for i = 0 ,nADInfoNum-2 do
		local idx = math.random(1 ,nADInfoNum - i)
		local str = ADInfo[idx]
		ADInfo[idx] = ADInfo[nADInfoNum - i]
		ADInfo[nADInfoNum - i] = str
	end

	for i = 1 ,nADInfoNum do
		YuanbaoShop_ScrollInfo_Frame:SetScrollInfoFixed(ADInfo[i],"1")
	end

end

function YuanbaoShop_ResetPos()
	YuanbaoShop_Frame:SetProperty("UnifiedXPosition", g_YuanbaoShop_Frame_UnifiedXPosition);
	YuanbaoShop_Frame:SetProperty("UnifiedYPosition", g_YuanbaoShop_Frame_UnifiedYPosition);
	local nWidth, nHeight = GetCurClientSize()
	local nCurXPos = YuanbaoShop_Frame:GetProperty("AbsoluteXPosition")
	if nWidth >= 1000 and nWidth <= 1048 and nHeight >= 758 and nHeight <= 778 then
		YuanbaoShop_Frame:SetProperty("AbsoluteXPosition", nCurXPos - 70);
	end
end

function YuanbaoShop_SuiShenExangeyuanbao()
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
function YuanbaoShop_ResetInfo()
	LAST_FENYE = 0;
	LAST_TAG   = 1;
	LAST_SHOP  = 1;
	LAST_TAG   = 1;
	LAST_SHOP  = 1;
	lastA = 0			--打开页面元宝商店下最后点击的tag
	lastB = 0			--打开页面元宝商店下最后点击的shop
	lastA_Bind = 0	--打开页面绑定元宝商店最后点击的tag
	lastB_Bind = 0	--打开页面绑定元宝商店最后点击的shop
	lastSelect = 0
	lastSelect_Bind = 0

	lastA_GiftToken = 0
	lastB_GiftToken = 0
	lastSelect_GiftToken = 0

	lastA_VIP = 0
	lastB_VIP = 0

	lastA_Lijin=0
	lastB_Lijin=0
end

function YuanbaoShop_PlayCardChangePage(nPageNum)
	g_PlayCard_CurPage = nPageNum
	if nPageNum <= 0 or nPageNum > g_PlayCard_MaxPage then
		return
	end
	YuanbaoShop_Image:SetProperty("NormalImage", g_PlayCard_Image[nPageNum])
	YuanbaoShop_Image:SetProperty("HoverImage", g_PlayCard_Image[nPageNum])
	YuanbaoShop_Image:SetProperty("DisabledImage", g_PlayCard_Image[nPageNum])
	YuanbaoShop_Image:SetProperty("PushedImage", g_PlayCard_Image[nPageNum])
	g_PlayCard_CtlButton[nPageNum]:SetCheck(1)
	KillTimer("YuanbaoShop_PlayCardTimer()")
	SetTimer("YuanbaoShop", "YuanbaoShop_PlayCardTimer()", 5000)
end

function YuanbaoShop_PlayCardTimer()
	g_PlayCard_CurPage = g_PlayCard_CurPage + 1
	if g_PlayCard_CurPage > g_PlayCard_MaxPage then
		g_PlayCard_CurPage = 1
	end
	YuanbaoShop_PlayCardChangePage(g_PlayCard_CurPage)
end

function YuanbaoShop_ImageClicked()
	if GameProduceLogin:IsWeGameClient() > 0 then
		return
	end
	if g_PlayCard_URL[g_PlayCard_CurPage] ~= nil then
		GameProduceLogin:OpenURL(GetWeblink(g_PlayCard_URL[g_PlayCard_CurPage]))
	end
end

function YuanbaoShop_HelpBtn_Clicked()
	if (g_tabIndex == ShopTabIdx.YuanBao) then
		OpenYBShopReference("yuanbao")
	elseif (g_tabIndex == ShopTabIdx.Bind) then
		OpenYBShopReference("yuanbao")
	elseif (g_tabIndex == ShopTabIdx.GiftToken) then
		if GameProduceLogin:IsWeGameClient() > 0 then
			OpenYBShopReference("#{WEJR_230303_27}")
		else
			OpenYBShopReference("#{FQ_101210_08}")
		end
	elseif (g_tabIndex == ShopTabIdx.VipShop) then
		OpenYBShopReference("#{FFSDGZ_120615_85}")
	elseif (g_tabIndex == ShopTabIdx.Lijin) then
		OpenYBShopReference("#{TBSD_130816_6}")
	end
end
function YuanbaoShop_web_Clicked()
	if IsZbs2018SpeicalServer() >= 1 then
		PushDebugMessage("#{WCBS_180307_20}")
		return
	end
	
	if IsDfsSpeicalServer() >= 1 then
		PushDebugMessage("#{SJDF_190603_01}")
		return
	end
	
	Chongzhi()
end

function YuanbaoShop_DuiHuanClicked()
	if IsZbs2018SpeicalServer() >= 1 then
		PushDebugMessage("#{WCBS_180307_20}")
		return
	end
	
	if IsDfsSpeicalServer() >= 1 then
		PushDebugMessage("#{SJDF_190603_01}")
		return
	end
	
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

function YuanbaoShop_Lijin_Load()
	--礼金大卖场
	SHOP_LIST_A_LIJIN[1] = {btn = YuanbaoShop_Button1, shopname="#{LJSD_120508_09}", tooltips="#{YBSD_081225_083}", shoplist={},shoplisttips = {}}
	SHOP_LIST_A_LIJIN[1].shoplist[1] = "#{LJSD_120508_10}"	--"新品上架"
	SHOP_LIST_A_LIJIN[1].shoplist[8] = "#{LJSD_120508_11}"	--"最近购买"

	--礼金宝石店
	SHOP_LIST_A_LIJIN[2] = {btn = YuanbaoShop_Button2, shopname="#{LJSD_120508_12}", tooltips="#{YBSD_081225_084}", shoplist={},shoplisttips = {}}
	SHOP_LIST_A_LIJIN[2].shoplist[1] = "#{LJSD_120508_13}"	--"三级通宝斋"
	SHOP_LIST_A_LIJIN[2].shoplist[2] = "#{TBSD_130816_1}"	--"四级通宝斋"
	SHOP_LIST_A_LIJIN[2].shoplist[3] = "#{TBSD_130816_2}"	--"五级通宝斋"
	SHOP_LIST_A_LIJIN[2].shoplist[4] = "#{TBSD_130816_3}"	--"六级通宝斋"
	--SHOP_LIST_A_LIJIN[2].shoplist[5] = "#{TBSD_130816_4}"	--"七级通宝斋"
	--SHOP_LIST_A_LIJIN[2].shoplist[6] = "#{LJSD_120508_14}"	--"宝石加工坊"
	SHOP_LIST_A_LIJIN[2].shoplist[5] = "#{LJSD_120508_14}"	--"宝石加工坊"

	--礼金珍兽店
	SHOP_LIST_A_LIJIN[3] = {btn = YuanbaoShop_Button3, shopname="#{LJSD_120508_19}", tooltips="#{YBSD_081225_085}", shoplist={},shoplisttips = {}}
	SHOP_LIST_A_LIJIN[3].shoplist[1] = "#{LJSD_120508_20}"	--"珍兽百宝箱"

	--礼金奇货店
	SHOP_LIST_A_LIJIN[4] = {btn = YuanbaoShop_Button4, shopname="#{LJSD_120508_15}", tooltips="#{YBSD_081225_086}", shoplist={},shoplisttips = {}}
	SHOP_LIST_A_LIJIN[4].shoplist[1] = "#{LJSD_120508_16}"	--"仙丹灵药"
	SHOP_LIST_A_LIJIN[4].shoplist[2] = "#{LJSD_120508_17}"	--"奇珍异宝"
	SHOP_LIST_A_LIJIN[4].shoplist[3] = "#{YBSD_XML_8}"	    --"防具雕纹店"
	SHOP_LIST_A_LIJIN[4].shoplist[4] = "#{YBSD_XML_9}"	    --"武具雕纹店"
	SHOP_LIST_A_LIJIN[4].shoplist[5] = "#{SSXDW_140819_75}"	    --"武具雕纹坊"
	SHOP_LIST_A_LIJIN[4].shoplist[6] = "#{YBSD_XML_10}"	    --"雕纹加工坊"

	--
	SHOP_LIST_A_LIJIN[5] = {btn = YuanbaoShop_Button5, shopname="#{LJSD_180312_03}", tooltips="#{LJSD_180312_02}", shoplist={},shoplisttips = {}}
	SHOP_LIST_A_LIJIN[5].shoplist[1] = "#{LJSD_180312_04}"	--"三级宝石斋"

	SHOP_LIST_A_LIJIN[6] = {btn = YuanbaoShop_Button6 , shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A_LIJIN[7] = {btn = YuanbaoShop_Button7 , shoplist = {}, shoplisttips = {}}
	SHOP_LIST_A_LIJIN[8] = {btn = YuanbaoShop_Button8 , shoplist = {}, shoplisttips = {}}

	--二级商店
	SHOP_LIST_B_LIJIN[1] = YuanbaoShop_Button01
	SHOP_LIST_B_LIJIN[2] = YuanbaoShop_Button02
	SHOP_LIST_B_LIJIN[3] = YuanbaoShop_Button03
	SHOP_LIST_B_LIJIN[4] = YuanbaoShop_Button04
	SHOP_LIST_B_LIJIN[5] = YuanbaoShop_Button05
	SHOP_LIST_B_LIJIN[6] = YuanbaoShop_Button06
	SHOP_LIST_B_LIJIN[7] = YuanbaoShop_Button07
	SHOP_LIST_B_LIJIN[8] = YuanbaoShop_Button08

	if lastA ~= nil and lastA > 0 and lastA < table.getn(SHOP_LIST_A_LIJIN)+1 then
		SHOP_LIST_A_LIJIN[lastA].btn:SetCheck(1)
	end

	if lastB ~= nil and lastB > 0 and lastB < table.getn(SHOP_LIST_B_LIJIN)+1 then
		SHOP_LIST_B_LIJIN[lastB]:SetCheck(1)
	end

	for i =1 ,table.getn(SHOP_LIST_B_LIJIN) do
		SHOP_LIST_B_LIJIN[i]:Hide()
	end

	SHOP_SEARCH_LIST_LIJIN[1] = {}
end

function YuanbaoShop_Lijin_Show()

		YuanbaoShop_Bk1 : Show();
		YuanbaoShop_Bk2 : Show();
		YuanbaoShop_Bk3 : Show();
		YuanbaoShop_Duihuan : Hide()


		local check  = tonumber(NpcShop:GetBuyDirectly());
		if(check>=1)then
			YuanbaoShop_querengoumai:SetCheck(0);
			NpcShop:SetLiJinBuyDirectly(1)
		else
			YuanbaoShop_querengoumai:SetCheck(1);
			NpcShop:SetLiJinBuyDirectly(0)
		end

		YuanbaoShop_Lijin_Text2 : Show();
		YuanbaoShop_Lijin_Text1 : Show();

		YuanbaoShop_Lijin_bK : Show();
		YuanbaoShop_Lijin_Text2:SetText("#{LJSD_120508_08}"..tostring(Player:GetData("LIJIN")))
		if SystemSetup:IsClassic() == 1 then	--	经典版
			YuanbaoShop_Text:SetText("#{TBSD_130816_7}")
		else	--	唯美
			YuanbaoShop_titleimage:SetProperty("Image", "set:WM_YBShop2 image:YuanBaoTitle_HongliShop")
		end

		if ( (lastB_Lijin == 0) or (SHOP_LIST_A_LIJIN[lastA_Lijin].shoplist[lastB_Lijin] == nil)) then
			YuanbaoShop_UpdateVisiableProperty(SHOP_LIST_A_LIJIN, SHOP_LIST_B_LIJIN, SHOP_SEARCH_LIST_LIJIN, 1, 1, 0)
			YuanbaoShop_UpdateList_Lijin( 1 );
		else
			YuanbaoShop_UpdateVisiableProperty(SHOP_LIST_A_LIJIN, SHOP_LIST_B_LIJIN, SHOP_SEARCH_LIST_LIJIN, lastA_Lijin, lastB_Lijin, 0)
		  YuanbaoShop_UpdateShop_Lijin( lastB_Lijin );
		end
		
		if LAST_SHOP == 1 and (LAST_TAG == 2 or LAST_TAG == 5) then
			YuanbaoShop_zhekougoumai_Text:Show();
			YuanbaoShop_zhekougoumai_Text:SetToolTip("#{LJSD_180312_02}")		
			YuanbaoShop_LijinDisCoutnMD()		
		else
			YuanbaoShop_zhekougoumai_Text:Hide();
			YuanbaoShop_zhekougoumai_Text:SetToolTip("")
		end		
end

function YuanbaoShop_LijinDisCoutnMD()
		local nMD = math.mod(DataPool:GetPlayerMission_DataRound(g_LiJinDisCountMD),10);
		if nMD < g_LiJinDisMaxCnt then
			YuanbaoShop_zhekougoumai_Text:SetText(ScriptGlobal_Format("#{LJSD_180312_01}", g_LiJinDisMaxCnt-nMD));
		else
			YuanbaoShop_zhekougoumai_Text:SetText("#{LJSD_180312_11}");
		end	
end
