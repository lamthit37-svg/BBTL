
local g_YuanXiao_Shop_UnifiedPosition;

local g_YuanXiao_Shop_ButtonCDTime = 500
local g_YuanXiao_Shop_LastClickTime = 0

local g_YuanXiao_Shop_List = {};
local g_YuanXiao_Shop_AnimateList = {};
local g_YuanXiao_Shop_NameList = {};
local g_YuanXiao_Shop_DiscountPic = {};

local g_YuanXiao_nContentButton = {}

local g_YuanXiao_Shop_CurPage = 1
local g_YuanXiao_Shop_CurSelect = 0
local g_YuanXiao_Shop_CurSelectItem = 0
local g_YuanXiao_Shop_BuyConfirm = 0
local g_YuanXiao_Shop_RefershConfirm = 0
local g_YuanXiao_Shop_ChooseItem = {};

local g_YuanXiao_Shop_ReFreshNum = -1;
local g_YuanXiao_Shop_DBCount = -1;
local g_YuanXiao_Shop_IsHaveBuy = 1;
local g_YuanXiao_Shop_DescChange = 0;
local g_YuanXiao_Shop_IsCanAllot = 0;
local g_YuanXiao_Shop_ShopCost = 0;
local g_YuanXiao_Shop_ShowPoint = 0;

local g_YuanXiao_Shop_Item = "";
local g_YuanXiao_Shop_Coupon = 0;
local g_YuanXiao_Shop_Daibi = 0;
local g_YuanXiao_Shop_Refresh = 0;

local g_YuanXiao_Shop_LastPos = 0;

local g_YuanXiao_Shop_Getfanli = {0,0,0,0,0,0,0,0}

local g_YuanXiao_Shop_ItemList = {
[1] = {39920085, 2, 60, 2, 0, 8.6, 1, 1, 1, 0}, 
[2] = {39920089, 1, 85, 5, 0, 8.5, 1, 1, 1, 0}, 
[3] = {39921313, 2, 170, 17, 0, 8.5, 1, 1, 1, 0}, 
[4] = {39920163, 20, 140, 40, 0, 7.0, 1, 1, 1, 0},
[5] = {39920085, 2, 60, 2, 0, 8.6, 1, 1, 1, 0}, 
[6] = {39920089, 1, 85, 5, 0, 8.5, 1, 1, 1, 0}, 
[7] = {39921313, 2, 170, 17, 0, 8.5, 1, 1, 1, 0}, 
[8] = {39920163, 20, 140, 40, 0, 7.0, 1, 1, 1, 0},
}
local g_YuanXiao_Shop_MAX = 8

local g_YuanXiao_Shop_OnwerId = 1

local g_YuanXiao_Shop_OnwerPic = {
[1] = "set:Spring8 image:YuanXiaoMan2", 	--老爷爷 
[2] = "set:Spring8 image:YuanXiaoMan1", 	--掌柜 
[3] = "set:Spring9 image:YuanXiaoMan4", 	--老板娘
[4] = "set:Spring9 image:YuanXiaoMan3", 	--侠客
[5] = "set:Spring10 image:YuanXiaoMan5", 	--小女孩
}

--初见可以砍价 --初见已砍价
--购买成功1 --购买成功2 --购买成功3
--4分配代金券成功 --5再次尝试分配代金券 --6购买过尝试分配代金券 --7没有代金券尝试分配 --8分配代金券过量
--卖完
local g_YuanXiao_Shop_Onwer = {
[1] = { chujian = "#{MHSD_181126_28}", chujian2 = "#{MHSD_181126_154}", 
		change = {  "#{MHSD_181126_29}", "#{MHSD_181126_155}", "#{MHSD_181126_156}", 
					"#{MHSD_181126_30}", "#{MHSD_181126_31}", "#{MHSD_181126_32}", "#{MHSD_181126_33}", "#{MHSD_181126_34}"},
		maiwan = "#{MHSD_181126_35}"},
[2] = { chujian = "#{MHSD_181126_36}", chujian2 = "#{MHSD_181126_157}", 
		change = {  "#{MHSD_181126_37}", "#{MHSD_181126_158}", "#{MHSD_181126_159}", 
					"#{MHSD_181126_38}", "#{MHSD_181126_39}", "#{MHSD_181126_40}", "#{MHSD_181126_41}", "#{MHSD_181126_42}"}, 
		maiwan = "#{MHSD_181126_43}"},
[3] = { chujian = "#{MHSD_181126_20}", chujian2 = "#{MHSD_181126_151}", 
		change = {  "#{MHSD_181126_21}", "#{MHSD_181126_152}", "#{MHSD_181126_153}", 
					"#{MHSD_181126_22}", "#{MHSD_181126_23}", "#{MHSD_181126_24}", "#{MHSD_181126_25}", "#{MHSD_181126_26}"}, 
		maiwan = "#{MHSD_181126_27}"},
[4] = { chujian = "#{MHSD_181126_138}", chujian2 = "#{MHSD_181126_139}", 
		change = {  "#{MHSD_181126_140}", "#{MHSD_181126_141}", "#{MHSD_181126_142}", 
					"#{MHSD_181126_143}", "#{MHSD_181126_144}", "#{MHSD_181126_145}", "#{MHSD_181126_146}", "#{MHSD_181126_147}"}, 
		maiwan = "#{MHSD_181126_148}"},
[5] = { chujian = "#{MHSD_181126_12}", chujian2 = "#{MHSD_181126_177}", 
		change = {  "#{MHSD_181126_13}", "#{MHSD_181126_149}", "#{MHSD_181126_150}", 
					"#{MHSD_181126_14}", "#{MHSD_181126_15}", "#{MHSD_181126_16}", "#{MHSD_181126_17}", "#{MHSD_181126_18}"}, 
		maiwan = "#{MHSD_181126_19}"},
}

local g_YuanXiao_vip_Shop_Onwer = {
[1] = { chujian = "#{MHSD_231017_50}", chujian2 = "#{MHSD_231017_51}", 
		change = {  "#{MHSD_231017_52}", "#{MHSD_231017_53}", "#{MHSD_231017_54}", 
					"#{MHSD_231017_55}", "#{MHSD_231017_56}", "#{MHSD_231017_57}", "#{MHSD_231017_58}", "#{MHSD_231017_59}"},
		maiwan = "#{MHSD_231017_60}"},
[2] = { chujian = "#{MHSD_231017_61}", chujian2 = "#{MHSD_231017_62}", 
		change = {  "#{MHSD_231017_63}", "#{MHSD_231017_64}", "#{MHSD_231017_65}", 
					"#{MHSD_231017_66}", "#{MHSD_231017_67}", "#{MHSD_231017_68}", "#{MHSD_231017_69}", "#{MHSD_231017_70}"}, 
		maiwan = "#{MHSD_231017_71}"},
[3] = { chujian = "#{MHSD_231017_39}", chujian2 = "#{MHSD_231017_40}", 
		change = {  "#{MHSD_231017_41}", "#{MHSD_231017_42}", "#{MHSD_231017_43}", 
					"#{MHSD_231017_44}", "#{MHSD_231017_45}", "#{MHSD_231017_46}", "#{MHSD_231017_47}", "#{MHSD_231017_48}"}, 
		maiwan = "#{MHSD_231017_49}"},
[4] = { chujian = "#{MHSD_231017_72}", chujian2 = "#{MHSD_231017_73}", 
		change = {  "#{MHSD_231017_74}", "#{MHSD_231017_75}", "#{MHSD_231017_76}", 
					"#{MHSD_231017_77}", "#{MHSD_231017_78}", "#{MHSD_231017_79}", "#{MHSD_231017_80}", "#{MHSD_231017_81}"}, 
		maiwan = "#{MHSD_231017_82}"},
[5] = { chujian = "#{MHSD_231017_28}", chujian2 = "#{MHSD_231017_29}", 
		change = {  "#{MHSD_231017_30}", "#{MHSD_231017_31}", "#{MHSD_231017_32}", 
					"#{MHSD_231017_33}", "#{MHSD_231017_34}", "#{MHSD_231017_35}", "#{MHSD_231017_36}", "#{MHSD_231017_37}"}, 
		maiwan = "#{MHSD_231017_38}"},
}

local g_YuanXiao_Shop_FanLi = {
[1] = { costnum = 1000, imageshow = "set:Spring24 image:1", saveidx = 0,
		itemid = { 	{id = 39921576, cnt = 100,}, {id = 0, cnt = 0,},  --固定奖励
					{id = 0, cnt = 0,}, 
					{id = 0, cnt = 0, showpic = 0, picID = 0},  --可选奖励
					{id = 0, cnt = 0, showpic = 0, picID = 0},
					} 
		},
[2] = { costnum = 3000, imageshow = "set:Spring24 image:2", saveidx = 0,
		itemid = { {id = 39921576, cnt = 200,}, {id = 0, cnt = 0,},  --固定奖励 
					{id = 0, cnt = 0,}, 
					{id = 0, cnt = 0, showpic = 0, picID = 0}, --可选奖励
					{id = 0, cnt = 0, showpic = 0, picID = 0},
					} 
		},
[3] = { costnum = 5000, imageshow = "set:Spring24 image:3", saveidx = 0,
		itemid = { {id = 39921576, cnt = 400,}, {id = 0, cnt = 0,},   --固定奖励 
					{id = 0, cnt = 0,}, 
					{id = 0, cnt = 0, showpic = 0, picID = 0},  --可选奖励
					{id = 0, cnt = 0, showpic = 0, picID = 0},
					} 
		},
[4] = { costnum = 7000, imageshow = "set:Spring24 image:4", saveidx = 0,
		itemid = { {id = 39921576, cnt = 600,}, {id = 0, cnt = 0,},   --固定奖励 
					{id = 0, cnt = 0,}, 
					{id = 0, cnt = 0, showpic = 0, picID = 0},  --可选奖励
					{id = 0, cnt = 0, showpic = 0, picID = 0}, -- 可选奖励预览
					} 
		},
[5] = { costnum = 10000, imageshow = "set:Spring24 image:5",  saveidx = 0,
		itemid = { {id = 39921576, cnt = 1000,}, {id = 0, cnt = 0,},   --固定奖励 
					{id = 0, cnt = 0,}, 
					{id = 0, cnt = 0, showpic = 0, picID = 0},  --可选奖励
					{id = 0, cnt = 0, showpic = 0, picID = 0}, -- 可选奖励预览
					} 
		},
[6] = { costnum = 20000, imageshow = "set:Spring24 image:6", saveidx = 0,
		itemid = { {id = 39921576, cnt = 2000,}, {id = 39925124, cnt = 1,},   --固定奖励 
					{id = 0, cnt = 0,}, 
					{id = 0, cnt = 0, showpic = 0, picID = 0},  --可选奖励
					{id = 0, cnt = 0, showpic = 0, picID = 0}, -- 可选奖励预览
					} 
		},
[7] = { costnum = 30000, imageshow = "set:Spring24 image:7", saveidx = 1,
		itemid = { {id = 39921576, cnt = 4000,}, {id = 0, cnt = 0,},   --固定奖励 
					{id = 39924793, cnt = 1,}, 
					{id = 39922083, cnt = 1, showpic = 0, picID = 0},  --可选奖励
					{id = 39923223, cnt = 1, showpic = 0, picID = 0}, -- 可选奖励预览
					} 
		},
[8] = { costnum = 50000, imageshow = "set:Spring24 image:8", saveidx = 2,
		itemid = { {id = 39921576, cnt = 6000,}, {id = 10100083, cnt = 1,},   --固定奖励 
					{id = 39924795, cnt = 1,}, 
					{id = 39922084, cnt = 1, showpic = 0, picID = 0},  --可选奖励
					{id = 39923225, cnt = 1, showpic = 0, picID = 0}, -- 可选奖励预览
					} 
		},
[9] = { costnum = 70000, imageshow = "set:Spring24 image:9", saveidx = 3,
		itemid = { {id = 39921576, cnt = 8000,}, {id = 0, cnt = 0,},    --固定奖励 
					{id = 39924794, cnt = 1,}, 
					{id = 39922082, cnt = 1, showpic = 0, picID = 0}, --可选奖励
					{id = 39923224, cnt = 1, showpic = 0, picID = 0},  -- 可选奖励预览
					} 
		},
[10] = { costnum = 100000, imageshow = "set:Spring24 image:10", saveidx = 6,
		itemid = { {id = 39921576, cnt = 10000,}, {id = 0, cnt = 0,},    --固定奖励 
					{id = 0, cnt = 0,}, 
					{id = 39922089, cnt = 1, showpic = 1, picID = 1},  --可选奖励
					{id = 38008342, cnt = 1, showpic = 1, picID = 2}, -- 可选奖励预览
					} 
		},
[11] = { costnum = 150000, imageshow = "set:Spring24 image:11", saveidx = 4,
		itemid = { {id = 39921576, cnt = 10000,}, {id = 0, cnt = 0,},    --固定奖励 
					{id = 39921139, cnt = 15, }, 
					{id = 39920490, cnt = 30, showpic = 0, picID = 0},  --可选奖励
					{id = 39920311, cnt = 25, showpic = 0, picID = 0}, -- 可选奖励预览
					}
		},
[12] = { costnum = 200000, imageshow = "set:Spring24 image:12", saveidx = 5,
		itemid = { {id = 39921576, cnt = 20000,}, {id = 0, cnt = 0,},    --固定奖励 
					{id = 39924002, cnt = 25, }, 
					{id = 39921047, cnt = 10, showpic = 0, picID = 0},  --可选奖励
					{id = 39922767, cnt = 30, showpic = 0, picID = 0}, 
					}
		},
[13] = { costnum = 400000, imageshow = "set:Spring24 image:13", saveidx = 0,
		itemid = { {id = 0, cnt = 0,}, {id = 10147793, cnt = 1,},    --固定奖励 
					{id = 0, cnt = 0, },   --可选奖励
					{id = 0, cnt = 0, showpic = 0, picID = 0},
					{id = 0, cnt = 0, showpic = 0, picID = 0}, 
					}
		},
}

local g_YuanXiao_Shop_FanLiSJ = {
[12] = { costnum = 200000, imageshow = "set:Spring24 image:12", saveidx = 5,
		itemid = { {id = 39921576, cnt = 20000,}, {id = 0, cnt = 0,},    --固定奖励 
					{id = 20700055, cnt = 200, }, 
					{id = 30008130, cnt = 10, showpic = 0, picID = 0},  --可选奖励
					{id = 20800039, cnt = 50, showpic = 0, picID = 0}, 
					}
		},
}

local g_YuanXiao_Shop_FanLiKJ = {
[11] = { costnum = 150000, imageshow = "set:Spring24 image:11", saveidx = 4,
		itemid = { {id = 39921576, cnt = 10000,}, {id = 0, cnt = 0, }, 
					{id = 39921051, cnt = 30, }, 
					{id = 39920490, cnt = 30, showpic = 0, picID = 0}, 
					{id = 39920311, cnt = 25, showpic = 0, picID = 0}, 
				}  
		},
[12] = { costnum = 200000, imageshow = "set:Spring24 image:12", saveidx = 5,
		itemid = { {id = 39921576, cnt = 20000,}, {id = 0, cnt = 0,},    --固定奖励 
					{id = 39920267, cnt = 20, }, 
					{id = 39920235, cnt = 20, showpic = 0, picID = 0},  --可选奖励
					{id = 39920334, cnt = 25, showpic = 0, picID = 0}, 
					}  
		},
[13] = { costnum = 400000, imageshow = "set:Spring24 image:13", saveidx = 0,
		itemid = { {id = 0, cnt = 0,}, {id = 10147793, cnt = 1,},    --固定奖励 
					{id = 0, cnt = 0, },   --可选奖励
					{id = 0, cnt = 0, showpic = 0, picID = 0},
					{id = 0, cnt = 0, showpic = 0, picID = 0}, 
					}  
		},
}

local g_YuanXiao_Shop_Reward = { 
	"YuanXiao_Shop_Reward_BasicItem1", 
	"YuanXiao_Shop_Reward_BasicItem2", 
	"YuanXiao_Shop_Reward_BasicItem3", 
	"YuanXiao_Shop_Reward_BasicItem4", 
	"YuanXiao_Shop_Reward_BasicItem5",
}

local g_YuanXiao_Shop_RewardLace = {
	[3] = "YuanXiao_Shop_Reward_BasicItem3_Mask", 
	[4] = "YuanXiao_Shop_Reward_BasicItem4_Mask", 
	[5] = "YuanXiao_Shop_Reward_BasicItem5_Mask", 
}

local g_BigFairShop_MAX = 5
local g_BigFairShop_ContentButton = {}
local g_BigFairShop_ItemList = {}
local g_BigFairShop_DescChange = 0;
local g_BigFairShop_LastIdx = 0;
local g_BigFairShop_OnwerId = 1


function YuanXiao_Shop_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	
	this:RegisterEvent("UPDATE_YUANBAO")
	
	this:RegisterEvent("OPEN_BIGFAIRSHOP")
end

function YuanXiao_Shop_OnLoad()
	g_YuanXiao_Shop_UnifiedPosition = YuanXiao_Shop:GetProperty("UnifiedPosition")
	
	g_YuanXiao_Shop_AnimateList[1] = YuanXiao_Shop_Item1_Animate
	g_YuanXiao_Shop_AnimateList[2] = YuanXiao_Shop_Item2_Animate
	g_YuanXiao_Shop_AnimateList[3] = YuanXiao_Shop_Item3_Animate
	g_YuanXiao_Shop_AnimateList[4] = YuanXiao_Shop_Item4_Animate
	g_YuanXiao_Shop_AnimateList[5] = YuanXiao_Shop_Item5_Animate
	g_YuanXiao_Shop_AnimateList[6] = YuanXiao_Shop_Item6_Animate
	g_YuanXiao_Shop_AnimateList[7] = YuanXiao_Shop_Item7_Animate
	g_YuanXiao_Shop_AnimateList[8] = YuanXiao_Shop_Item8_Animate
	
	g_YuanXiao_Shop_NameList[1] = YuanXiao_Shop_Item1_ItemName
	g_YuanXiao_Shop_NameList[2] = YuanXiao_Shop_Item2_ItemName
	g_YuanXiao_Shop_NameList[3] = YuanXiao_Shop_Item3_ItemName
	g_YuanXiao_Shop_NameList[4] = YuanXiao_Shop_Item4_ItemName
	g_YuanXiao_Shop_NameList[5] = YuanXiao_Shop_Item5_ItemName
	g_YuanXiao_Shop_NameList[6] = YuanXiao_Shop_Item6_ItemName
	g_YuanXiao_Shop_NameList[7] = YuanXiao_Shop_Item7_ItemName
	g_YuanXiao_Shop_NameList[8] = YuanXiao_Shop_Item8_ItemName
	
	g_YuanXiao_Shop_DiscountPic[1] = YuanXiao_Shop_Item1_DiscountPic
	g_YuanXiao_Shop_DiscountPic[2] = YuanXiao_Shop_Item2_DiscountPic
	g_YuanXiao_Shop_DiscountPic[3] = YuanXiao_Shop_Item3_DiscountPic
	g_YuanXiao_Shop_DiscountPic[4] = YuanXiao_Shop_Item4_DiscountPic
	g_YuanXiao_Shop_DiscountPic[5] = YuanXiao_Shop_Item5_DiscountPic
	g_YuanXiao_Shop_DiscountPic[6] = YuanXiao_Shop_Item6_DiscountPic
	g_YuanXiao_Shop_DiscountPic[7] = YuanXiao_Shop_Item7_DiscountPic
	g_YuanXiao_Shop_DiscountPic[8] = YuanXiao_Shop_Item8_DiscountPic
	
	g_YuanXiao_Shop_List[1] = {
			[1] = YuanXiao_Shop_Item1, 
			[2] = YuanXiao_Shop_Item1_Icon, 
			[3] = YuanXiao_Shop_Item1_Icon_Mask,
			[4] = YuanXiao_Shop_Item1_Unbind,
			[5] = YuanXiao_Shop_Item1_DiscountBK,
			[6] = YuanXiao_Shop_Item1_Discount,
			[7] = YuanXiao_Shop_Item1_Text,
			[8] = YuanXiao_Shop_Item1_CardText, 
			[9] = YuanXiao_Shop_Item1_YuanBaoText, 
			[10] = YuanXiao_Shop_Item1_MoneyIcon1,
			[11] = YuanXiao_Shop_Item1_MoneyIcon2,
			[12] = YuanXiao_Shop_Item1_DiscountAnimate,
			[13] = YuanXiao_Shop_Item1_Plus,
		}
	
	g_YuanXiao_Shop_List[2] = {
			[1] = YuanXiao_Shop_Item2, 
			[2] = YuanXiao_Shop_Item2_Icon, 
			[3] = YuanXiao_Shop_Item2_Icon_Mask,
			[4] = YuanXiao_Shop_Item2_Unbind,  
			[5] = YuanXiao_Shop_Item2_DiscountBK, 
			[6] = YuanXiao_Shop_Item2_Discount,  
			[7] = YuanXiao_Shop_Item2_Text,
			[8] = YuanXiao_Shop_Item2_CardText, 
			[9] = YuanXiao_Shop_Item2_YuanBaoText,  
			[10] = YuanXiao_Shop_Item2_MoneyIcon1,
			[11] = YuanXiao_Shop_Item2_MoneyIcon2,
			[12] = YuanXiao_Shop_Item2_DiscountAnimate,
			[13] = YuanXiao_Shop_Item2_Plus,
		}
								
	g_YuanXiao_Shop_List[3] = {
			[1] = YuanXiao_Shop_Item3, 
			[2] = YuanXiao_Shop_Item3_Icon,  
			[3] = YuanXiao_Shop_Item3_Icon_Mask,
			[4] = YuanXiao_Shop_Item3_Unbind,  
			[5] = YuanXiao_Shop_Item3_DiscountBK,  
			[6] = YuanXiao_Shop_Item3_Discount,
			[7] = YuanXiao_Shop_Item3_Text,
			[8] = YuanXiao_Shop_Item3_CardText,
			[9] = YuanXiao_Shop_Item3_YuanBaoText,  
			[10] = YuanXiao_Shop_Item3_MoneyIcon1,
			[11] = YuanXiao_Shop_Item3_MoneyIcon2,
			[12] = YuanXiao_Shop_Item3_DiscountAnimate,
			[13] = YuanXiao_Shop_Item3_Plus,
		}
								
	g_YuanXiao_Shop_List[4] = {
			[1] = YuanXiao_Shop_Item4, 
			[2] = YuanXiao_Shop_Item4_Icon,  
			[3] = YuanXiao_Shop_Item4_Icon_Mask,
			[4] = YuanXiao_Shop_Item4_Unbind,  
			[5] = YuanXiao_Shop_Item4_DiscountBK,  
			[6] = YuanXiao_Shop_Item4_Discount,
			[7] = YuanXiao_Shop_Item4_Text,
			[8] = YuanXiao_Shop_Item4_CardText,
			[9] = YuanXiao_Shop_Item4_YuanBaoText,  
			[10] = YuanXiao_Shop_Item4_MoneyIcon1,
			[11] = YuanXiao_Shop_Item4_MoneyIcon2,
			[12] = YuanXiao_Shop_Item4_DiscountAnimate,
			[13] = YuanXiao_Shop_Item4_Plus,
		}
	
	g_YuanXiao_Shop_List[5] = {
			[1] = YuanXiao_Shop_Item5, 
			[2] = YuanXiao_Shop_Item5_Icon,  
			[3] = YuanXiao_Shop_Item5_Icon_Mask,
			[4] = YuanXiao_Shop_Item5_Unbind,  
			[5] = YuanXiao_Shop_Item5_DiscountBK,  
			[6] = YuanXiao_Shop_Item5_Discount,
			[7] = YuanXiao_Shop_Item5_Text,
			[8] = YuanXiao_Shop_Item5_CardText, 
			[9] = YuanXiao_Shop_Item5_YuanBaoText,  
			[10] = YuanXiao_Shop_Item5_MoneyIcon1,
			[11] = YuanXiao_Shop_Item5_MoneyIcon2,
			[12] = YuanXiao_Shop_Item5_DiscountAnimate,
			[13] = YuanXiao_Shop_Item5_Plus,
		}
	
	g_YuanXiao_Shop_List[6] = {
			[1] = YuanXiao_Shop_Item6, 
			[2] = YuanXiao_Shop_Item6_Icon, 
			[3] = YuanXiao_Shop_Item6_Icon_Mask,
			[4] = YuanXiao_Shop_Item6_Unbind,  
			[5] = YuanXiao_Shop_Item6_DiscountBK, 
			[6] = YuanXiao_Shop_Item6_Discount,
			[7] = YuanXiao_Shop_Item6_Text,
			[8] = YuanXiao_Shop_Item6_CardText, 
			[9] = YuanXiao_Shop_Item6_YuanBaoText,  
			[10] = YuanXiao_Shop_Item6_MoneyIcon1,
			[11] = YuanXiao_Shop_Item6_MoneyIcon2,
			[12] = YuanXiao_Shop_Item6_DiscountAnimate,
			[13] = YuanXiao_Shop_Item6_Plus,
		}
	
	g_YuanXiao_Shop_List[7] = {
			[1] = YuanXiao_Shop_Item7, 
			[2] = YuanXiao_Shop_Item7_Icon, 
			[3] = YuanXiao_Shop_Item7_Icon_Mask,  
			[4] = YuanXiao_Shop_Item7_Unbind,  
			[5] = YuanXiao_Shop_Item7_DiscountBK, 
			[6] = YuanXiao_Shop_Item7_Discount,
			[7] = YuanXiao_Shop_Item7_Text,
			[8] = YuanXiao_Shop_Item7_CardText, 
			[9] = YuanXiao_Shop_Item7_YuanBaoText,  
			[10] = YuanXiao_Shop_Item7_MoneyIcon1,
			[11] = YuanXiao_Shop_Item7_MoneyIcon2,
			[12] = YuanXiao_Shop_Item7_DiscountAnimate,
			[13] = YuanXiao_Shop_Item7_Plus,
		}
	
	g_YuanXiao_Shop_List[8] = {
			[1] = YuanXiao_Shop_Item8, 
			[2] = YuanXiao_Shop_Item8_Icon,  
			[3] = YuanXiao_Shop_Item8_Icon_Mask,  
			[4] = YuanXiao_Shop_Item8_Unbind,  
			[5] = YuanXiao_Shop_Item8_DiscountBK, 
			[6] = YuanXiao_Shop_Item8_Discount,
			[7] = YuanXiao_Shop_Item8_Text, 
			[8] = YuanXiao_Shop_Item8_CardText, 
			[9] = YuanXiao_Shop_Item8_YuanBaoText, 
			[10] = YuanXiao_Shop_Item8_MoneyIcon1,
			[11] = YuanXiao_Shop_Item8_MoneyIcon2,
			[12] = YuanXiao_Shop_Item8_DiscountAnimate,
			[13] = YuanXiao_Shop_Item8_Plus,
		}
	
end

function YuanXiao_Shop_OnEvent(event)

	-- 打开 商店
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89071301 ) then
		local ret = Get_XParam_INT(0)
		if ret == 0 then
			YuanXiao_Shop_Close()
			return
		end
		g_YuanXiao_Shop_Daibi = Get_XParam_INT(1)
		g_YuanXiao_Shop_Coupon = Get_XParam_INT(2) 
		g_YuanXiao_Shop_Refresh = Get_XParam_INT(3) 
		g_YuanXiao_Shop_OnwerId = Get_XParam_INT(4) 
		g_YuanXiao_Shop_IsCanAllot = Get_XParam_INT(5) 
		g_YuanXiao_Shop_ShopCost = Get_XParam_INT(6) 
		g_YuanXiao_Shop_ShowPoint = Get_XParam_INT(7) 
		g_YuanXiao_Shop_Item = Get_XParam_STR(0)
		
		g_YuanXiao_Shop_DescChange = 0
		
		YuanXiao_Shop_ConfirmUpdate()
				
		YuanXiao_Shop_PageSet( 1 )
	
		YuanXiao_Shop_Init()
		
		this:Show()
	
	elseif ( event == "OPEN_BIGFAIRSHOP") then
		-- 大商店
		if tonumber(arg0) == 1 then
			
			if IsWindowShow("YuanXiao_ShopBuy") then
				CloseWindow("YuanXiao_ShopBuy", true)
			end
			
			if IsWindowShow("YuanXiao_ShopCard") then
				CloseWindow("YuanXiao_ShopCard", true)
			end
			
			if IsWindowShow("XiGua_Fashion") then
				CloseWindow("XiGua_Fashion", true)
			end
			
			g_BigFairShop_DescChange = tonumber(arg1)
			g_BigFairShop_LastIdx = tonumber(arg2)
		
			g_YuanXiao_Shop_Coupon = tonumber(arg3)
			YuanXiao_Shop_CouponUpdate()
			
			g_YuanXiao_Shop_Daibi = tonumber(arg4)
			YuanXiao_Shop_DaiBiUpdate()
			
			g_YuanXiao_Shop_Refresh = tonumber(arg5)
			
			g_YuanXiao_Shop_ShowPoint = math.floor(tonumber(arg6) /10)
			
			g_BigFairShop_OnwerId = math.mod(tonumber(arg6),10)
		
			YuanXiao_Shop_ConfirmUpdate()
			
			YuanXiao_Shop_PageSet( 3 )
			
			YuanXiao_Shop_Init()
			
		else
		
			YuanXiao_Shop_Close()
			return
			
		end
		
	-- 刷新 返利界面
	elseif( event == "UI_COMMAND" 
			and tonumber(arg0) == 89071311
			and IsWindowShow("YuanXiao_Shop") ) then
		local ret = Get_XParam_INT(0)
		if ret == 0 then
			YuanXiao_Shop_Close()
			return
		end
		
		if IsWindowShow("YuanXiao_ShopBuy") then
			CloseWindow("YuanXiao_ShopBuy", true)
		end
			
		if IsWindowShow("YuanXiao_ShopCard") then
			CloseWindow("YuanXiao_ShopCard", true)
		end
			
		if IsWindowShow("XiGua_Fashion") then
			CloseWindow("XiGua_Fashion", true)
		end
			
		g_YuanXiao_Shop_ShowPoint = Get_XParam_INT(1) 
		g_YuanXiao_Shop_ShopCost = Get_XParam_INT(2) 
		
		YuanXiao_Shop_ChooseStr( Get_XParam_STR(0) )
		
		YuanXiao_Shop_PageSet( 2 )
		
		for i = 1, table.getn(g_YuanXiao_Shop_FanLi) do
			g_YuanXiao_Shop_Getfanli[i] = Get_XParam_INT(i+2)
		end
		
		YuanXiao_Shop_Init()
	    
	-- 刷新 商店
	elseif( event == "UI_COMMAND" 
			and tonumber(arg0) == 89071304 
			and IsWindowShow("YuanXiao_Shop") ) then
			
		if IsWindowShow("YuanXiao_ShopBuy") then
			CloseWindow("YuanXiao_ShopBuy", true)
		end
		
		if IsWindowShow("YuanXiao_ShopCard") then
			CloseWindow("YuanXiao_ShopCard", true)
		end
		
		if IsWindowShow("XiGua_Fashion") then
			CloseWindow("XiGua_Fashion", true)
		end
		
		g_YuanXiao_Shop_Daibi = Get_XParam_INT(0)
		g_YuanXiao_Shop_Coupon = Get_XParam_INT(1) 
		g_YuanXiao_Shop_Refresh = Get_XParam_INT(2) 
		g_YuanXiao_Shop_OnwerId = Get_XParam_INT(3) 
		g_YuanXiao_Shop_DescChange = Get_XParam_INT(4) 
		g_YuanXiao_Shop_IsCanAllot = Get_XParam_INT(5) 
		g_YuanXiao_Shop_ShopCost = Get_XParam_INT(6) 
		g_YuanXiao_Shop_ShowPoint = Get_XParam_INT(7) 
		g_YuanXiao_Shop_Item = Get_XParam_STR(0)
		
		YuanXiao_Shop_PageSet( 1 )
	
		YuanXiao_Shop_Init()
		
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 89071305 and IsWindowShow("YuanXiao_Shop") ) then
		g_YuanXiao_Shop_Daibi = Get_XParam_INT(0)
		YuanXiao_Shop_DaiBiUpdate()
		 
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 89071306 and IsWindowShow("YuanXiao_Shop") ) then
		g_YuanXiao_Shop_Coupon = Get_XParam_INT(0)
		YuanXiao_Shop_CouponUpdate()
		
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 89071314 and IsWindowShow("YuanXiao_Shop") ) then
		local ShowAnimateIdx = Get_XParam_INT(0)
		YuanXiao_Shop_ShowAnimate( ShowAnimateIdx )
		
	elseif (event == "ADJEST_UI_POS" ) then
		YuanXiao_Shop_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		YuanXiao_Shop_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		YuanXiao_Shop_Close()
		
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		YuanXiao_Shop_YuanbaoUpdate()
	end

end

--=========================================================
--刷新确认 & 购买确认
--=========================================================
function YuanXiao_Shop_ConfirmUpdate()
							
	local bConfirm = Variable:GetVariable("YuanXiaoShopBuyConfirm")
	if bConfirm == nil then
		Variable:SetVariable("YuanXiaoShopBuyConfirm","1",0)
		bConfirm = 1
	end
			
	local mark = tonumber(bConfirm)
	if mark == 1 then
		YuanXiao_Shop_BuyConfirm_Button:SetCheck(1)
	else
		YuanXiao_Shop_BuyConfirm_Button:SetCheck(0)
	end
	g_YuanXiao_Shop_BuyConfirm = YuanXiao_Shop_BuyConfirm_Button : GetCheck()
			
	local bRefershConfirm = Variable:GetVariable("YuanXiaoShopRefershConfirm")
	if bRefershConfirm == nil then
		Variable:SetVariable("YuanXiaoShopRefershConfirm","1",0)
		bRefershConfirm = 1
	end
	mark = tonumber(bRefershConfirm)
	if mark == 1 then
		YuanXiao_Shop_RefershConfirm_Button:SetCheck(1)
	else
		YuanXiao_Shop_RefershConfirm_Button:SetCheck(0)
	end
	g_YuanXiao_Shop_RefershConfirm = YuanXiao_Shop_RefershConfirm_Button : GetCheck()
		
	if KaJi:LuaFnGetKaJiType(39) == 1 then
		YuanXiao_Shop_RefershConfirm_Button:SetToolTip("#{MHSD_260109_14}")
		YuanXiao_Shop_RefershConfirm_Text:SetToolTip("#{MHSD_260109_14}")
	elseif Player:GetData("IsOriginalJD") == 1 then
		YuanXiao_Shop_RefershConfirm_Button:SetToolTip("#{MHSD_260109_15}")
		YuanXiao_Shop_RefershConfirm_Text:SetToolTip("#{MHSD_260109_15}")
	else
		YuanXiao_Shop_RefershConfirm_Button:SetToolTip("#{MHSD_231017_3}")
		YuanXiao_Shop_RefershConfirm_Text:SetToolTip("#{MHSD_231017_3}")
	end
end

--=========================================================
--元宝刷新
--=========================================================
function YuanXiao_Shop_YuanbaoUpdate()
	local str = ScriptGlobal_Format("#{MHSD_181126_55}", tostring(Player:GetData("YUANBAO")))
	YuanXiao_Shop_YuanBaoNum:SetText(str)
end

--=========================================================
--代金卷刷新
--=========================================================
function YuanXiao_Shop_CouponUpdate()
	local str = ScriptGlobal_Format("#{MHSD_181126_56}", g_YuanXiao_Shop_Coupon)
	YuanXiao_Shop_CardNum:SetText(str)
end

--=========================================================
--代币刷新
--=========================================================
function YuanXiao_Shop_DaiBiUpdate()
	local str = ScriptGlobal_Format("#{MHSD_181126_58}", g_YuanXiao_Shop_Daibi)
	YuanXiao_Shop_CandyNum:SetText(str)
end

--=========================================================
--对白刷新
--=========================================================
function YuanXiao_Shop_OnwerUpdate(nShopType, buyCount)
	
	if nShopType == 2 then
		if g_BigFairShop_OnwerId >= 1 and g_BigFairShop_OnwerId <= table.getn(g_YuanXiao_Shop_OnwerPic) then
			YuanXiao_Shop_NPC_Text:SetText(g_YuanXiao_Shop_Onwer[g_BigFairShop_OnwerId].chujian)
			YuanXiao_Shop_NPC:SetProperty("Image",g_YuanXiao_Shop_OnwerPic[g_BigFairShop_OnwerId])
		else
			YuanXiao_Shop_NPC_Text:SetText(g_YuanXiao_Shop_Onwer[1].chujian)
			YuanXiao_Shop_NPC:SetProperty("Image",g_YuanXiao_Shop_OnwerPic[1])
		end
		return
	end
	
	if g_YuanXiao_Shop_OnwerId >= 1 and g_YuanXiao_Shop_OnwerId <= table.getn(g_YuanXiao_Shop_OnwerPic) then
		if g_YuanXiao_Shop_DescChange == 0 then
			--设置店主信息
			if buyCount >= table.getn(g_YuanXiao_Shop_ItemList) then
				YuanXiao_Shop_NPC_Text:SetText(g_YuanXiao_Shop_Onwer[g_YuanXiao_Shop_OnwerId].maiwan)		
			else
				if g_YuanXiao_Shop_IsCanAllot == 0 then
					YuanXiao_Shop_NPC_Text:SetText(g_YuanXiao_Shop_Onwer[g_YuanXiao_Shop_OnwerId].chujian)	
				else
					YuanXiao_Shop_NPC_Text:SetText(g_YuanXiao_Shop_Onwer[g_YuanXiao_Shop_OnwerId].chujian2)	
				end
			end
			YuanXiao_Shop_NPC:SetProperty("Image",g_YuanXiao_Shop_OnwerPic[g_YuanXiao_Shop_OnwerId])
		else
			if g_YuanXiao_Shop_Onwer[g_YuanXiao_Shop_OnwerId].change[g_YuanXiao_Shop_DescChange] ~= nil then
				YuanXiao_Shop_NPC_Text:SetText(g_YuanXiao_Shop_Onwer[g_YuanXiao_Shop_OnwerId].change[g_YuanXiao_Shop_DescChange])
			end			
			
			if buyCount >= table.getn(g_YuanXiao_Shop_ItemList) then
				YuanXiao_Shop_NPC_Text:SetText(g_YuanXiao_Shop_Onwer[g_YuanXiao_Shop_OnwerId].maiwan)		
			end
			
			YuanXiao_Shop_NPC:SetProperty("Image",g_YuanXiao_Shop_OnwerPic[g_YuanXiao_Shop_OnwerId])
		end
	else
		if buyCount >= table.getn(g_YuanXiao_Shop_ItemList) then
			YuanXiao_Shop_NPC_Text:SetText(g_YuanXiao_Shop_Onwer[1].maiwan)	
		else
			YuanXiao_Shop_NPC_Text:SetText(g_YuanXiao_Shop_Onwer[1].chujian)	
		end
		YuanXiao_Shop_NPC:SetProperty("Image",g_YuanXiao_Shop_OnwerPic[1])	
	end
	
end

--=========================================================
--刷新返利界面
--=========================================================
function YuanXiao_Shop_FanLiUpdate()

	for i = 1, table.getn(g_YuanXiao_Shop_FanLi) do
		local bar = YuanXiao_Shop_UpFrame_RewardList:AddChild("YuanXiao_Shop_UpFrame_RewardContent")
		if nil ~= bar then
		
			local FanLiList = g_YuanXiao_Shop_FanLi[i]
			if KaJi:LuaFnGetKaJiType(39) == 1 and g_YuanXiao_Shop_FanLiKJ[i] ~= nil then
				FanLiList = g_YuanXiao_Shop_FanLiKJ[i]
			end
			
			if Player:GetData("IsOriginalJD") == 1 and g_YuanXiao_Shop_FanLiSJ[i] ~= nil then
				FanLiList = g_YuanXiao_Shop_FanLiSJ[i]
			end
			
			-- 累计元宝
			local strmsg = ""
			if g_YuanXiao_Shop_ShopCost < FanLiList.costnum then
				strmsg = ScriptGlobal_Format("#{MHSD_191203_05}", g_YuanXiao_Shop_ShopCost, FanLiList.costnum)
			else
				strmsg = ScriptGlobal_Format("#{MHSD_191203_06}", FanLiList.costnum, FanLiList.costnum)
			end
			bar:GetSubItem("YuanXiao_Shop_UpFrame_Reward_PointText"):SetText(strmsg)
			
			-- 隐藏对号
			bar:GetSubItem(g_YuanXiao_Shop_RewardLace[3]):Hide()
			bar:GetSubItem(g_YuanXiao_Shop_RewardLace[4]):Hide()
			bar:GetSubItem(g_YuanXiao_Shop_RewardLace[5]):Hide()
			
			-- 没有可选 显示文字
			local nSaveIdx = FanLiList.saveidx
			if nSaveIdx == 0 then			
				bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemNone"):SetText("#{MHSD_191203_53}")
				bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemNone"):Show()
			else
				bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemNone"):Hide()
								
				if g_YuanXiao_Shop_ChooseItem[nSaveIdx] ~= nil then
					local nChooseIdx = g_YuanXiao_Shop_ChooseItem[nSaveIdx]
					if g_YuanXiao_Shop_RewardLace[nChooseIdx] ~= nil then
						bar:GetSubItem(g_YuanXiao_Shop_RewardLace[nChooseIdx]):Show()
					end
				end
			end
			
			--action
			local ListCount = table.getn(g_YuanXiao_Shop_Reward) - 2
			for btn = 1, ListCount do
				bar:GetSubItem(g_YuanXiao_Shop_Reward[btn]):Hide()
				if FanLiList.itemid[btn] ~= nil and FanLiList.itemid[btn].id ~= 0 and FanLiList.itemid[btn].cnt ~= 0 then					
					local GiftItemID = FanLiList.itemid[btn].id
					local GiftCount = FanLiList.itemid[btn].cnt
					
					if GiftItemID == 39921576 then
						bar:GetSubItem("YuanXiao_Shop_Reward_BasicItem1_Text"):SetText(tostring(GiftCount))
						GiftCount = 1
					end
					
					-- 珍兽 显示 图鉴
					--if 39922089 == GiftItemID then
					--	bar:GetSubItem("YuanXiao_Shop_Reward_BasicItem2Preview"):Show()
					--	bar:SetSubItemEvent("YuanXiao_Shop_Reward_BasicItem2Preview", "Clicked", "YuanXiao_Shop_TuJian_Click()")	
					--else
						bar:GetSubItem("YuanXiao_Shop_Reward_BasicItem2Preview"):Hide()
					--end
					
					local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftCount)
					if theAction:GetID() ~= 0 then
						bar:GetSubItem(g_YuanXiao_Shop_Reward[btn]):SetActionItem(theAction:GetID());
						bar:GetSubItem(g_YuanXiao_Shop_Reward[btn]):Show()
					end
				end
			end
			
			if FanLiList.itemid[4].id ~= 0 and FanLiList.itemid[4].cnt ~= 0 then
				local GiftItemID = FanLiList.itemid[4].id
				local GiftCount = FanLiList.itemid[4].cnt
				local IsPreView = FanLiList.itemid[4].showpic
				local PicId = FanLiList.itemid[4].picID
				
				local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftCount)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem("YuanXiao_Shop_Reward_BasicItem4_Frame"):Show()
					bar:GetSubItem("YuanXiao_Shop_Reward_BasicItem4"):SetActionItem(theAction:GetID());
					--bar:SetSubItemEvent("YuanXiao_Shop_Reward_BasicItem4", "Clicked", "YuanXiao_Shop_Choose_Click("..i..", 4)")	
					if IsPreView == 1 then
						bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemPreview2"):Show()
						bar:SetSubItemEvent("YuanXiao_Shop_Reward_BasicItemPreview2", "Clicked", "YuanXiao_Shop_Preview_Click("..PicId..")")	
					else
						bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemPreview2"):Hide()
					end
				end
			else
				bar:GetSubItem("YuanXiao_Shop_Reward_BasicItem4_Frame"):Hide()
			end
			
			if FanLiList.itemid[5].id ~= 0 and FanLiList.itemid[5].cnt ~= 0 then
				local GiftItemID = FanLiList.itemid[5].id
				local GiftCount = FanLiList.itemid[5].cnt
				local IsPreView = FanLiList.itemid[5].showpic
				local PicId = FanLiList.itemid[5].picID
				
				local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftCount)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem("YuanXiao_Shop_Reward_BasicItem5_Frame"):Show()
					bar:GetSubItem("YuanXiao_Shop_Reward_BasicItem5"):SetActionItem(theAction:GetID());
					--bar:SetSubItemEvent("YuanXiao_Shop_Reward_BasicItem5", "Clicked", "YuanXiao_Shop_Choose_Click("..i..", 5)")	
					if IsPreView == 1 then
						bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemPreview"):Show()
						bar:SetSubItemEvent("YuanXiao_Shop_Reward_BasicItemPreview", "Clicked", "YuanXiao_Shop_Preview_Click("..PicId..")")	
					else
						bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemPreview"):Hide()
					end
				end
			else
				bar:GetSubItem("YuanXiao_Shop_Reward_BasicItem5_Frame"):Hide()
			end
			
			--按钮
			if g_YuanXiao_Shop_Getfanli[i] ~= nil then
				if g_YuanXiao_Shop_Getfanli[i] == 1 then	-- 已领取
					bar:GetSubItem("YuanXiao_Shop_Reward_Button"):Hide()
					bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemReceived"):Show()
					bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemNotReach"):Hide()
				else
					if g_YuanXiao_Shop_ShopCost < FanLiList.costnum then	-- 未达成
						bar:GetSubItem("YuanXiao_Shop_Reward_Button"):Hide()
						bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemReceived"):Hide()
						bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemNotReach"):Show()
					else
						bar:GetSubItem("YuanXiao_Shop_Reward_Button"):Show()
						bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemReceived"):Hide()
						bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemNotReach"):Hide()
					end
				end
			end
			bar:SetSubItemEvent("YuanXiao_Shop_Reward_Button", "Clicked", "YuanXiao_Shop_Reward_Click("..i..")")	
			
			--bar:GetSubItem("YuanXiao_Shop_Reward_SelectItem_Animate"):Hide()
			
			--首列图片
			bar:GetSubItem("YuanXiao_Shop_Reward_BasicItemLevel"):SetProperty("Image", FanLiList.imageshow)
			
			g_YuanXiao_nContentButton[i] = bar
		end
	end
	
	local nCurScroPos = 0
	for i = 1, table.getn(g_YuanXiao_Shop_Getfanli) do
		if g_YuanXiao_Shop_Getfanli[i] == 0 then
			nCurScroPos = i
			break
		end
	end
	
	if nCurScroPos > 0 then
		YuanXiao_Shop_UpFrame_RewardList:SetScrollPosition4Index(nCurScroPos-1)		
	end
end

--=========================================================
-- 显示 选择区 特效
--=========================================================
function YuanXiao_Shop_ShowAnimate( Idx )
	if g_YuanXiao_nContentButton[Idx] ~= nil then
		--g_YuanXiao_nContentButton[Idx]:GetSubItem("YuanXiao_Shop_Reward_SelectItem_Animate"):Show()
		--g_YuanXiao_nContentButton[Idx]:GetSubItem("YuanXiao_Shop_Reward_SelectItem_Animate"):Play(true)
	end
end

--=========================================================
-- 拆可选字串
--=========================================================
function YuanXiao_Shop_ChooseStr( str )

	local strItem = str.."-"
	local saveidxlist = 0
	local chooseidxlist = 0
	for i = 1, table.getn(g_YuanXiao_Shop_FanLi) do
	
		local FanLiList = g_YuanXiao_Shop_FanLi[i]
		if KaJi:LuaFnGetKaJiType(39) == 1 and g_YuanXiao_Shop_FanLiKJ[i] ~= nil then
			FanLiList = g_YuanXiao_Shop_FanLiKJ[i]
		end
			
		if Player:GetData("IsOriginalJD") == 1 and g_YuanXiao_Shop_FanLiSJ[i] ~= nil then
			FanLiList = g_YuanXiao_Shop_FanLiSJ[i]
		end
		
		local nidx = FanLiList.saveidx
		if nidx > 0 then
			g_YuanXiao_Shop_ChooseItem[nidx] = 0
			
			local iPos = string.find( strItem, "-" );
			if ( iPos ~= nil ) then
				local tempstr = string.sub(strItem, 1, iPos-1)
				
				local temppos = string.find( tempstr, "*" );
				if temppos ~= nil then
					saveidxlist = tonumber(string.sub(tempstr, 1, temppos-1))
					chooseidxlist = tonumber(string.sub(tempstr, temppos+1, string.len(tempstr)))
				end
				
				if saveidxlist ~= nidx then
					YuanXiao_Shop_Close()
					return
				end
				
				g_YuanXiao_Shop_ChooseItem[nidx] = chooseidxlist
					
				strItem = string.sub(strItem, iPos+1, string.len(strItem))
			end
		end
		
	end
	
end

--=========================================================
--初始化界面
--=========================================================
function YuanXiao_Shop_Init()
	if g_YuanXiao_Shop_CurPage == 2 then
	
		for i = 1, table.getn(g_YuanXiao_nContentButton) do
			for j = 1, table.getn(g_YuanXiao_Shop_Reward) do
				g_YuanXiao_nContentButton[i]:GetSubItem(g_YuanXiao_Shop_Reward[j]):SetActionItem(-1)
			end
		end
			
		YuanXiao_Shop_UpFrame_RewardList:Clear()
		
		g_YuanXiao_nContentButton = {}
		
		g_YuanXiao_Shop_CurSelectItem = 0
		g_YuanXiao_Shop_CurSelect = 0
	
		YuanXiao_Shop_FanLiUpdate()
		
	elseif g_YuanXiao_Shop_CurPage == 3 then
					
		YuanXiao_Shop_Client2_List:Clear()
		
		g_BigFairShop_ContentButton = {}
			
		YuanXiao_Shop_CouponUpdate()
		YuanXiao_Shop_YuanbaoUpdate()	
		YuanXiao_Shop_DaiBiUpdate()
			
		YuanXiao_Shop_UpdateBigShop()
		
	else
	
		for i=1, table.getn(g_YuanXiao_Shop_ItemList) do
			g_YuanXiao_Shop_List[i][2]:SetActionItem( -1 );
		end	
	
		YuanXiao_Shop_CouponUpdate()
		YuanXiao_Shop_YuanbaoUpdate()	
		YuanXiao_Shop_DaiBiUpdate()
		YuanXiao_Shop_Update()
	end
	
	YuanXiao_Shop_Buttontab03_Tips:Hide()
	if g_YuanXiao_Shop_ShowPoint == 1 then
		YuanXiao_Shop_Buttontab02_Tips:Show()
	else
		YuanXiao_Shop_Buttontab02_Tips:Hide()
	end
end

--=========================================================
--更新界面
--=========================================================
function YuanXiao_Shop_Update()	
	local count = 0
	local strItem = g_YuanXiao_Shop_Item
	for i = 1, g_YuanXiao_Shop_MAX do
		local iPos = string.find( strItem, "-" );
		if ( iPos == nil ) then
			YuanXiao_Shop_Close()
		else
			local tempstr = string.sub(strItem, 1, iPos-1)
			for j = 1, 10 do
				local temppos = string.find( tempstr, "*" );
				if temppos ~= nil then
					g_YuanXiao_Shop_ItemList[i][j] = tonumber(string.sub(tempstr, 1, temppos-1))
					tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
				end
			end
			strItem = string.sub(strItem, iPos+1, string.len(strItem))
			count = count + 1
		end
	end
	
	if count < g_YuanXiao_Shop_MAX then
		YuanXiao_Shop_Close()
	end
	
	local strfresh = ScriptGlobal_Format("#{MHSD_181126_50}", g_YuanXiao_Shop_Refresh)
	YuanXiao_Shop_ChangeBtn_Text:SetText(strfresh)
		
	local buyCount = 0
		for i = 1, table.getn(g_YuanXiao_Shop_ItemList) do
			--显示道具
			DataPool:Lua_SetXiGuaShopActionItem( i-1, g_YuanXiao_Shop_ItemList[i][1], g_YuanXiao_Shop_ItemList[i][2] );
			
			g_YuanXiao_Shop_NameList[i]:SetText("#L"..DataPool:Lua_GetItemNameByIndex(g_YuanXiao_Shop_ItemList[i][1]))
			
			
			g_YuanXiao_Shop_List[i][12]:Hide()
			
			--蒙红处理
			if g_YuanXiao_Shop_ItemList[i][8] == 1 then
				--未购买
				g_YuanXiao_Shop_List[i][3]:Hide()
				
				if 	g_YuanXiao_Shop_ItemList[i][10] == 1 then
					g_YuanXiao_Shop_List[i][12]:Show()
					g_YuanXiao_Shop_List[i][12]:Play(true)
				else
					g_YuanXiao_Shop_List[i][12]:Hide()
				end
				
				if tonumber(g_YuanXiao_Shop_ItemList[i][7]) > 0 then
					g_YuanXiao_Shop_List[i][9]:Hide()
					g_YuanXiao_Shop_List[i][8]:Show()
					g_YuanXiao_Shop_List[i][7]:Show()
					g_YuanXiao_Shop_List[i][10]:Show()
					g_YuanXiao_Shop_List[i][11]:Show()
					g_YuanXiao_Shop_List[i][13]:Show()
					
					--折扣图标
					g_YuanXiao_Shop_DiscountPic[i]:Show()
					
					--显示元宝
					local yuanbao = tonumber(g_YuanXiao_Shop_ItemList[i][3])
					local coupon = tonumber(g_YuanXiao_Shop_ItemList[i][7])
					local textShow = "#M"..tostring(yuanbao - coupon) 
					g_YuanXiao_Shop_List[i][7]:SetText(textShow)
					g_YuanXiao_Shop_List[i][10]:SetProperty("Image", "set:Alcohol2 image:YuanBao")
				
					--显示代金卷
					textShow = "#M"..g_YuanXiao_Shop_ItemList[i][7]
					g_YuanXiao_Shop_List[i][8]:SetText(textShow)
					
					if g_YuanXiao_Shop_DescChange == 4 then
						--特效闪
						g_YuanXiao_Shop_AnimateList[i]:Show()
						g_YuanXiao_Shop_AnimateList[i]:Play(true)
						
						--定时器
						SetTimer("YuanXiao_Shop","YuanXiao_Shop_AnimateStop()",600)
						g_YuanXiao_Shop_List[i][7]:SetText("")
						g_YuanXiao_Shop_List[i][8]:SetText("")
					end
				else
					g_YuanXiao_Shop_List[i][7]:Show()
					g_YuanXiao_Shop_List[i][10]:Show()
					local textShow = "#M"..tostring(g_YuanXiao_Shop_ItemList[i][3])
					if g_YuanXiao_Shop_ItemList[i][9] == 1 then
						-- 元宝
						g_YuanXiao_Shop_List[i][10]:SetProperty("Image", "set:Alcohol2 image:YuanBao")
					else
						-- 元宵
						g_YuanXiao_Shop_List[i][10]:SetProperty("Image", "set:SpringMap10 image:YuanXiaoIcon")
					end
					
					g_YuanXiao_Shop_List[i][9]:Hide() 
					g_YuanXiao_Shop_List[i][8]:Hide()
					g_YuanXiao_Shop_List[i][7]:SetText(textShow)
					g_YuanXiao_Shop_List[i][11]:Hide()	
					g_YuanXiao_Shop_List[i][13]:Hide()	
					
					--折扣图标
					g_YuanXiao_Shop_DiscountPic[i]:Hide()
					
					--特效隐藏
					g_YuanXiao_Shop_AnimateList[i]:Hide()
					g_YuanXiao_Shop_AnimateList[i]:Play(false)
				end
			else
				--已购买
				g_YuanXiao_Shop_List[i][3]:Show()
				buyCount = buyCount + 1
				
				--显示已购买
				g_YuanXiao_Shop_List[i][9]:Show()
				g_YuanXiao_Shop_List[i][9]:SetText("#{MHSD_181126_133}")
				g_YuanXiao_Shop_List[i][8]:Hide()
				g_YuanXiao_Shop_List[i][7]:Hide()
				g_YuanXiao_Shop_List[i][10]:Hide()
				g_YuanXiao_Shop_List[i][11]:Hide()
				g_YuanXiao_Shop_List[i][13]:Hide()
			end
			
			--绑定显示
			if g_YuanXiao_Shop_ItemList[i][6] == 0 then
				--非绑
				g_YuanXiao_Shop_List[i][4]:Show()
			else
				--绑定
				g_YuanXiao_Shop_List[i][4]:Hide()
			end
			
			--显示折扣
			if g_YuanXiao_Shop_ItemList[i][5] ~= 10 then
				g_YuanXiao_Shop_List[i][5]:Show()	
				local msgstr = ScriptGlobal_Format("#{MHSD_181126_46}", g_YuanXiao_Shop_ItemList[i][5])
				g_YuanXiao_Shop_List[i][6]:SetText(msgstr)
			else
				g_YuanXiao_Shop_List[i][5]:Hide()		
			end					
		end
		
	DataPool:Lua_UpdateXiGuaShopActionItem();
	
	for i=1, table.getn(g_YuanXiao_Shop_ItemList) do
		local theAction = EnumAction( i-1, "xiguashop_item");
		if theAction:GetID() ~= 0 then
			g_YuanXiao_Shop_List[i][2]:SetActionItem( theAction:GetID() );
		else
			g_YuanXiao_Shop_List[i][2]:SetActionItem( -1 );
		end
	end	
	
	YuanXiao_Shop_OnwerUpdate(1, buyCount)
end

function YuanXiao_Shop_UpdateBigShop()
		
	local strfresh = ScriptGlobal_Format("#{MHSD_181126_50}", g_YuanXiao_Shop_Refresh)
	YuanXiao_Shop_ChangeBtn_Text:SetText(strfresh)
	
	local nIndex = 1
	local buyCount = 0
	for i = 1, g_BigFairShop_MAX do
		for j = 1, g_YuanXiao_Shop_MAX do
			local showid, num, cost, itemidx, disc, isbind, coupon, IsCanBuy, ntype, IsGoodsProtect = Lua_GetBigFairShopInfo(i-1, j-1)
			if showid > 0 then
				local bar = YuanXiao_Shop_Client2_List:AddChild("YuanXiao_Shop_Client2_Item")
				if nil ~= bar then					
					local theAction = DataPool:CreateActionItemForShow(showid, num)
					if theAction:GetID() ~= 0 then
						bar:GetSubItem("YuanXiao_Shop_Client2_Item1_Icon"):SetActionItem(theAction:GetID());
					end
					
					bar:GetSubItem("YuanXiao_Shop_Client2_Item_DiscountAnimate"):Hide()
					
					if ntype == 1 then
						-- 元宝
						bar:SetSubItemEvent("YuanXiao_Shop_Client2_Item1_Icon", "Clicked", "YuanXiao_Shop_Buy_Click("..i..","..j..","..itemidx..")")	
					else
						-- 元宵
						bar:SetSubItemEvent("YuanXiao_Shop_Client2_Item1_Icon", "Clicked", "YuanXiao_Shop_Buy_Click("..i..","..j..","..itemidx..")")	
					end
					
					bar:GetSubItem("YuanXiao_Shop_Client2_Item_ItemName"):SetText("#L"..DataPool:Lua_GetItemNameByIndex(showid))
					
					if IsCanBuy == 1 then
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_Icon_Mask"):Hide()
						
						if IsGoodsProtect == 1 then
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_DiscountAnimate"):Show()
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_DiscountAnimate"):Play(true)
						else
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_DiscountAnimate"):Hide()
						end
						
						if coupon > 0 then
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_YuanBaoText"):Hide()
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_CardText"):Show()
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_Text"):Show()
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_MoneyIcon1"):Show()
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_MoneyIcon2"):Show()
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_Plus"):Show()
							
							--折扣图标
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_DiscountPic"):Show()
					
							--显示元宝
							local yuanbao = tonumber(cost)
							local textShow = "#M"..tostring(yuanbao - coupon) 
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_Text"):SetText(textShow)
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_MoneyIcon1"):SetProperty("Image", "set:Alcohol2 image:YuanBao")
							
							--显示代金卷
							textShow = "#M"..coupon
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_CardText"):SetText(textShow)
							
							if g_BigFairShop_DescChange == 1 then
								--特效闪
								bar:GetSubItem("YuanXiao_Shop_Client2_Item_Animate"):Show()
								bar:GetSubItem("YuanXiao_Shop_Client2_Item_Animate"):Play(true)
								
								--定时器
								--SetTimer("YuanXiao_Shop", "YuanXiao_Shop_BigAnimateStop()", 600)
								--bar:GetSubItem("YuanXiao_Shop_Client2_Item_Text"):SetText("")
								--bar:GetSubItem("YuanXiao_Shop_Client2_Item_CardText"):SetText("")
							end
						else
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_Text"):Show()
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_MoneyIcon1"):Show()
							local textShow = "#M"..tostring(cost)
							if ntype == 1 then
								-- 元宝
								bar:GetSubItem("YuanXiao_Shop_Client2_Item_MoneyIcon1"):SetProperty("Image", "set:Alcohol2 image:YuanBao")
							else
								-- 元宵
								bar:GetSubItem("YuanXiao_Shop_Client2_Item_MoneyIcon1"):SetProperty("Image", "set:SpringMap10 image:YuanXiaoIcon")
							end
							
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_YuanBaoText"):Hide() 
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_CardText"):Hide()
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_Text"):SetText(textShow)
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_MoneyIcon2"):Hide()	
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_Plus"):Hide()	
							
							--折扣图标
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_DiscountPic"):Hide()
							
							--特效隐藏
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_Animate"):Hide()
							bar:GetSubItem("YuanXiao_Shop_Client2_Item_Animate"):Play(false)
						end
					else
						--已购买
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_Icon_Mask"):Show()
						buyCount = buyCount + 1
						
						--显示已购买
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_YuanBaoText"):Show()
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_YuanBaoText"):SetText("#{MHSD_181126_133}")
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_CardText"):Hide()
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_Text"):Hide()
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_MoneyIcon1"):Hide()
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_MoneyIcon2"):Hide()
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_Plus"):Hide()					
					end
					
					--绑定显示
					if isbind == 0 then
						--非绑
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_Unbind"):Show()
					else
						--绑定
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_Unbind"):Hide()
					end
			
					--显示折扣
					if disc ~= 10 then
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_DiscountBK"):Show()	
						local msgstr = ScriptGlobal_Format("#{MHSD_181126_46}", disc)
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_Discount"):SetText(msgstr)
					else
						bar:GetSubItem("YuanXiao_Shop_Client2_Item_DiscountBK"):Hide()		
					end
								
					g_BigFairShop_ContentButton[i][j] = bar
					nIndex = nIndex + 1
				end
			end
		end
	end
	
	--if g_BigFairShop_LastIdx ~= 0 then
	--	YuanXiao_Shop_Client2_List:SetScrollPosition4Index(g_BigFairShop_LastIdx - 1)
	--	g_BigFairShop_LastIdx = 0
	--else
	--	YuanXiao_Shop_Client2_List:SetScrollPosition4Index(0)
	--end
	
	if g_YuanXiao_Shop_LastPos ~= 0 then
		YuanXiao_Shop_Client2_List:SetScrollPosition( g_YuanXiao_Shop_LastPos )
		g_YuanXiao_Shop_LastPos = 0
	else
		YuanXiao_Shop_Client2_List:SetScrollPosition(0)
	end
	
	YuanXiao_Shop_OnwerUpdate(2, -1)
	
end

function YuanXiao_Shop_BigAnimateStop()

	for i = 1, g_BigFairShop_MAX do
		for j = 1, g_YuanXiao_Shop_MAX do
			local showid, num, cost, itemidx, disc, isbind, coupon, IsCanBuy, ntype, IsGoodsProtect = Lua_GetBigFairShopInfo(i-1, j-1)
			if showid > 0 then
				if ntype == 1 then	
					--显示元宝
					local yuanbao = tonumber(cost)
					local textShow = "#M"..tostring(yuanbao - coupon) 
					g_BigFairShop_ContentButton[i][j]:GetSubItem("YuanXiao_Shop_Client2_Item_Text"):SetText(textShow)
								
					--显示代金卷
					textShow = "#M"..coupon
					g_BigFairShop_ContentButton[i][j]:GetSubItem("YuanXiao_Shop_Client2_Item_CardText"):SetText(textShow)
				else
					local textShow = "#M"..tostring(cost)				
					g_BigFairShop_ContentButton[i][j]:GetSubItem("YuanXiao_Shop_Client2_Item_Text"):SetText(textShow)
				end
			end
		end
	end
	KillTimer("YuanXiao_Shop_BigAnimateStop()")

end

function YuanXiao_Shop_AnimateStop()

	for i = 1, table.getn(g_YuanXiao_Shop_ItemList) do
		if g_YuanXiao_Shop_ItemList[i][8] == 1 and tonumber(g_YuanXiao_Shop_ItemList[i][7]) > 0 then
			--显示元宝
			local yuanbao = tonumber(g_YuanXiao_Shop_ItemList[i][3])
			local coupon = tonumber(g_YuanXiao_Shop_ItemList[i][7])
			local textShow = "#M"..tostring(yuanbao - coupon)
			g_YuanXiao_Shop_List[i][7]:SetText(textShow)
			g_YuanXiao_Shop_List[i][10]:SetProperty("Image", "set:Alcohol2 image:YuanBao")
				
			--显示代金卷
			textShow = "#M"..g_YuanXiao_Shop_ItemList[i][7]
			g_YuanXiao_Shop_List[i][8]:SetText(textShow)
		end
	end
	
	KillTimer("YuanXiao_Shop_AnimateStop()")

end

--=========================================================
--商店说明
--=========================================================
function YuanXiao_Shop_Help_Clicked()	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowHelpText" )
		Set_XSCRIPT_ScriptID(890713)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end

--=========================================================
--刷新商店
--=========================================================
function YuanXiao_Shop_ReFresh_Clicked()	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ReFreshFairShop" )
		Set_XSCRIPT_ScriptID(890713)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_Parameter(1, g_YuanXiao_Shop_RefershConfirm)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
end

--=========================================================
--刷新商店
--=========================================================
function YuanXiao_Shop_YBReFresh_Clicked()	

	local curTime = OSAPI:GetTickCount()
	if ( curTime - g_YuanXiao_Shop_LastClickTime < g_YuanXiao_Shop_ButtonCDTime ) then
		return
	end
	g_YuanXiao_Shop_LastClickTime = curTime
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ReFreshFairShopByYB" )
		Set_XSCRIPT_ScriptID(890713)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_Parameter(1, g_YuanXiao_Shop_RefershConfirm)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
end

--=========================================================
--刷新商店
--=========================================================
function YuanXiao_Shop_Client2_YBReFresh_Clicked()
		
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ReFreshBigFairShop" )
		Set_XSCRIPT_ScriptID(890713)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_Parameter(1, g_YuanXiao_Shop_RefershConfirm)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
	
end

function YuanXiao_Shop_Buy_Click( nRow, nCol, nItemIdx )

	if nRow < 1 or nRow > g_BigFairShop_MAX then
		return 
	end

	if nCol < 1 or nCol > g_YuanXiao_Shop_MAX then
		return 
	end
	
	g_YuanXiao_Shop_LastPos = YuanXiao_Shop_Client2_List:GetScrollPosition()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BigFairShopBuyItem" )
		Set_XSCRIPT_ScriptID(890713)
		Set_XSCRIPT_Parameter(0, nRow)
		Set_XSCRIPT_Parameter(1, nCol)
		Set_XSCRIPT_Parameter(2, nItemIdx)
		Set_XSCRIPT_Parameter(3, 1)		--二次确认
		Set_XSCRIPT_Parameter(4, 1)		--0是纯元宝购买 1是用打折券
		Set_XSCRIPT_Parameter(5, g_YuanXiao_Shop_BuyConfirm)
		Set_XSCRIPT_ParamCount(6)
	Send_XSCRIPT()	
	
end

--=========================================================
--元宝购买
--=========================================================
function YuanXiao_Shop_YuanbaoBuy( index )

	if index < 1 or index > g_YuanXiao_Shop_MAX then
		return 
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "FairBuyItem" )
		Set_XSCRIPT_ScriptID(890713)
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_Parameter(1, g_YuanXiao_Shop_ItemList[index][1]) --showid
		Set_XSCRIPT_Parameter(2, g_YuanXiao_Shop_ItemList[index][4]) --itemidx
		Set_XSCRIPT_Parameter(3, 1)		--二次确认
		Set_XSCRIPT_Parameter(4, 1)		--0是纯元宝购买 1是用打折券
		Set_XSCRIPT_Parameter(5, g_YuanXiao_Shop_BuyConfirm)
		Set_XSCRIPT_ParamCount(6)
	Send_XSCRIPT()	

end

--=========================================================
--关闭
--=========================================================
function YuanXiao_Shop_Close()

	if IsWindowShow("YuanXiao_ShopBuy") then
		CloseWindow("YuanXiao_ShopBuy", true)
	end
		
	if IsWindowShow("YuanXiao_ShopCard") then
		CloseWindow("YuanXiao_ShopCard", true)
	end
		
	if IsWindowShow("XiGua_Fashion") then
		CloseWindow("XiGua_Fashion", true)
	end
		
	if IsWindowShow("YuanXiao_Shop_Preview") then
		CloseWindow("YuanXiao_Shop_Preview", true)
	end
		
	if IsWindowShow("YuanXiao_Shop_ThreeChoices") then
		CloseWindow("YuanXiao_Shop_ThreeChoices", true)
	end
	
	for i=1, table.getn(g_YuanXiao_Shop_ItemList) do
		g_YuanXiao_Shop_List[i][2]:SetActionItem( -1 );
	end	
	
	for i = 1, table.getn(g_YuanXiao_nContentButton) do
		for j = 1, table.getn(g_YuanXiao_Shop_Reward) do
			g_YuanXiao_nContentButton[i]:GetSubItem(g_YuanXiao_Shop_Reward[j]):SetActionItem(-1)
		end
	end
		
	YuanXiao_Shop_UpFrame_RewardList:Clear()
	
	g_YuanXiao_nContentButton = {}
	
	for i = 1, table.getn(g_BigFairShop_ContentButton) do
		for j = 1, table.getn(g_BigFairShop_ContentButton[i]) do
			g_BigFairShop_ContentButton[i][j]:GetSubItem("YuanXiao_Shop_Client2_Item1_Icon"):SetActionItem(-1)
		end
	end
	
	YuanXiao_Shop_Client2_List:Clear()
	
	g_BigFairShop_ContentButton = {}
	
	g_BigFairShop_DescChange = 0
	g_BigFairShop_LastIdx = 0
	g_YuanXiao_Shop_LastPos = 0
		
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function YuanXiao_Shop_On_ResetPos()
	YuanXiao_Shop:SetProperty("UnifiedPosition", g_YuanXiao_Shop_UnifiedPosition);
end

--=========================================================
--点击页签
--=========================================================
function YuanXiao_Shop_Project_Clicked( btn )

	if g_YuanXiao_Shop_CurPage == btn then
		return
	end

	if btn == 1 then
	
		if IsWindowShow("YuanXiao_ShopBuy") then
			CloseWindow("YuanXiao_ShopBuy", true)
		end
			
		if IsWindowShow("YuanXiao_ShopCard") then
			CloseWindow("YuanXiao_ShopCard", true)
		end
			
		if IsWindowShow("XiGua_Fashion") then
			CloseWindow("XiGua_Fashion", true)
		end
	
		g_YuanXiao_Shop_DescChange = 0
	
		YuanXiao_Shop_PageSet( 1 )
	
		YuanXiao_Shop_Init()
		
	elseif btn == 2 then
	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenFairFanLi" )
			Set_XSCRIPT_ScriptID(890713)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
		
	elseif btn == 3 then
	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpenBigFairShop" )
			Set_XSCRIPT_ScriptID(890713)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
		
	else
		-- error
		YuanXiao_Shop_Close()
		return
	end
	
end

function YuanXiao_Shop_PageSet( btn )

	if btn == 2 then
		
		g_YuanXiao_Shop_CurPage = 2
		
		YuanXiao_Shop_Buttontab01:SetCheck(0)
		YuanXiao_Shop_Buttontab02:SetCheck(1)
		YuanXiao_Shop_Buttontab03:SetCheck(0)
		
		YuanXiao_Shop_Frame:Hide()
		YuanXiao_Shop_Frame2:Show()
		
		YuanXiao_Shop_DragTitle:SetText("#{MHSD_191203_03}")
	
	elseif btn == 3 then
	
		g_YuanXiao_Shop_CurPage = 3
		
		YuanXiao_Shop_Buttontab01:SetCheck(0)
		YuanXiao_Shop_Buttontab02:SetCheck(0)
		YuanXiao_Shop_Buttontab03:SetCheck(1)
			
		YuanXiao_Shop_Frame:Show()
		YuanXiao_Shop_Frame2:Hide()
		
		YuanXiao_Shop_Client:Hide()
		YuanXiao_Shop_Client2:Show()
				
		YuanXiao_Shop_DragTitle:SetText("#{MHSD_181126_126}")
		
	else
	
		g_YuanXiao_Shop_CurPage = 1
			
		YuanXiao_Shop_Buttontab01:SetCheck(1)
		YuanXiao_Shop_Buttontab02:SetCheck(0)
		YuanXiao_Shop_Buttontab03:SetCheck(0)
			
		YuanXiao_Shop_Frame:Show()
		YuanXiao_Shop_Frame2:Hide()
		
		YuanXiao_Shop_Client:Show()
		YuanXiao_Shop_Client2:Hide()
		
		YuanXiao_Shop_DragTitle:SetText("#{MHSD_181126_126}")
		
	end
end

function YuanXiao_Shop_TuJian_Click()

	Pet:AnniversaryOpenPetJian( 34459 );
	
end

--=========================================================
--领取返利
--=========================================================
function YuanXiao_Shop_Reward_Click( Idx )

	if Idx < 1 or Idx > table.getn(g_YuanXiao_Shop_FanLi) then
		return 
	end
	
	if g_YuanXiao_Shop_CurSelect ~= Idx then
		g_YuanXiao_Shop_CurSelect = Idx
		g_YuanXiao_Shop_CurSelectItem = 0		
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "FairGetFanLi" )
		Set_XSCRIPT_ScriptID(890713)
		Set_XSCRIPT_Parameter(0, Idx)
		Set_XSCRIPT_Parameter(1, g_YuanXiao_Shop_CurSelectItem)
		Set_XSCRIPT_Parameter(2, 1)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
	
end

--=========================================================
--预览
--=========================================================
function YuanXiao_Shop_Preview_Click( PicId )

	if PicId == 1 then
		Pet:AnniversaryOpenPetJian( 34459 );
	end
	
	if PicId == 2 then
		-- 预览10128618+脸型207+发型286
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(888051)
			Set_XSCRIPT_Function_Name("DressPreview")
			Set_XSCRIPT_Parameter(0, 10128618 )
			Set_XSCRIPT_Parameter(1, 286 )
			Set_XSCRIPT_Parameter(2, 207 )
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end
	
	--PushEvent( "UI_COMMAND", 89071312, PicId );
	
end

--=========================================================
--选择奖励
--=========================================================
function YuanXiao_Shop_Choose_Click( Idx, itemidx )

	if g_YuanXiao_Shop_FanLi[Idx] == nil then
		return
	end
	
	if g_YuanXiao_Shop_FanLi[Idx].itemid[itemidx] == nil then
		return
	end
	
	if g_YuanXiao_Shop_FanLi[Idx].itemid[itemidx].id == 0 or g_YuanXiao_Shop_FanLi[Idx].itemid[itemidx].cnt == 0 then
		return
	end
	
	g_YuanXiao_Shop_CurSelect = Idx
	g_YuanXiao_Shop_CurSelectItem = itemidx
	
	YuanXiao_Shop_Choose_SetCheck( Idx, itemidx )
	
end

--=========================================================
--设置选择状态
--=========================================================
function YuanXiao_Shop_Choose_SetCheck( Idx, itemidx )

	for i = 1, table.getn(g_YuanXiao_Shop_FanLi) do
		for j = 3, 5 do
			if Idx == i and j == itemidx then
				g_YuanXiao_nContentButton[i]:GetSubItem(g_YuanXiao_Shop_RewardLace[j]):Show()
			else
				g_YuanXiao_nContentButton[i]:GetSubItem(g_YuanXiao_Shop_RewardLace[j]):Hide()
			end
		end
	end
	
end

function YuanXiao_Shop_BuyConfirm( btn )
	
	local bConfirm = Variable:GetVariable("YuanXiaoShopBuyConfirm")
	if tonumber(bConfirm) == 0 then
		YuanXiao_Shop_BuyConfirm_Button:SetCheck(1)
		Variable:SetVariable("YuanXiaoShopBuyConfirm","1",0)
	else
		YuanXiao_Shop_BuyConfirm_Button:SetCheck(0)
		Variable:SetVariable("YuanXiaoShopBuyConfirm","0",0)
	end

	g_YuanXiao_Shop_BuyConfirm = YuanXiao_Shop_BuyConfirm_Button : GetCheck()
	
end

function YuanXiao_Shop_RefershConfirm( btn )
	
	local bConfirm = Variable:GetVariable("YuanXiaoShopRefershConfirm")
	if tonumber(bConfirm) == 0 then
		YuanXiao_Shop_RefershConfirm_Button:SetCheck(1)
		Variable:SetVariable("YuanXiaoShopRefershConfirm","1",0)
	else
		YuanXiao_Shop_RefershConfirm_Button:SetCheck(0)
		Variable:SetVariable("YuanXiaoShopRefershConfirm","0",0)
	end

	g_YuanXiao_Shop_RefershConfirm = YuanXiao_Shop_RefershConfirm_Button : GetCheck()
	
end

