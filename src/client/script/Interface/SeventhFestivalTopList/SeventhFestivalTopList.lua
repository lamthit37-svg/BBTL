----------------------
-- SeventhFestivalTopList ---
----------------------
--界面位置
local g_SeventhFestivalTopList_UnifiedPosition = nil

--计时器
local g_SeventhFestivalTopList_CooldownDur = 4*1000	--4s冷却
local g_SeventhFestivalTopList_Cooldown = 
{
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
}

--页签显示
local g_SeventhFestivalTopList_CurPage = 0--默认显示页签--注：1标示排行榜；2标识兑换；3标识累计奖励；
local g_SeventhFestivalTopList_MaxPage = 3--最大页签数
local g_SeventhFestivalTopList_FlowerSubPage = 0
local g_SeventhFestivalTopList_ExchangeSubPage = 0	-- 0情人结;1痴情玉;2相思结

--排行榜相关控件
local g_SeventhFestivalTopList_Btn_Page = {}
local g_SeventhFestivalTopList_Btn_FlowerPage = {}
local g_SeventhFestivalTopList_Btn_FlowerPage_Redpoint = {}

-- 送花榜相关控件
local g_SeventhFestivalTopList_Present_Num = {}
local g_SeventhFestivalTopList_Present_Name = {}
local g_SeventhFestivalTopList_Present_Score = {}
local g_SeventhFestivalTopList_Present_BonusAction1 = {}
local g_SeventhFestivalTopList_Present_BonusAction2 = {}
local g_SeventhFestivalTopList_Present_BonusAction3 = {}
local g_SeventhFestivalTopList_Present_BonusPreview1 = {}
local g_SeventhFestivalTopList_Present_BonusPreview2 = {}
local g_SeventhFestivalTopList_Present_BonusPreview3 = {}

-- 收花榜相关控件
local g_SeventhFestivalTopList_Receive_Num = {}
local g_SeventhFestivalTopList_Receive_Name = {}
local g_SeventhFestivalTopList_Receive_Score = {}
local g_SeventhFestivalTopList_Receive_BonusAction1 = {}
local g_SeventhFestivalTopList_Receive_BonusAction2 = {}
local g_SeventhFestivalTopList_Receive_BonusAction3 = {}
local g_SeventhFestivalTopList_Receive_BonusPreview1 = {}
local g_SeventhFestivalTopList_Receive_BonusPreview2 = {}
local g_SeventhFestivalTopList_Receive_BonusPreview3 = {}

--上榜人数
local g_SeventhFestivalTopList_Ranking_Count = 20
local g_SeventhFestivalTopList_Ranking_CountPerPage = 5
local g_SeventhFestivalTopList_PresentRanking_CurPage = 0
local g_SeventhFestivalTopList_ReceiveRanking_CurPage = 0

-- 个人信息相关
local g_SeventhFestivalTopList_SelfPresentRank = 0;
local g_SeventhFestivalTopList_SelfReceiveRank = 0;

--累计奖励页面控件
local g_SeventhFestivalTopList_LeiJi_Text1 = {}
local g_SeventhFestivalTopList_LeiJi_Text2 = {}
local g_SeventhFestivalTopList_LeiJi_Text3 = {}
local g_SeventhFestivalTopList_LeiJi_Action = {}
local g_SeventhFestivalTopList_LeiJi_Button = {}
local g_SeventhFestivalTopList_LeiJi_Tips = {}
local g_SeventhFestivalTopList_LeiJi_Image = {}

--活动状态
local g_SeventhFestivalTopList_State = -1
local g_SeventhFestivalTopList_AllState = {}

--榜单信息
local g_SeventhFestivalTopList_Info = --待修改
{
-- 前世仙缘
	[1] = {desc = "#{QXLS_150724_12}", count = 3, sendmd = 3521, receivemd = 3522, 
			sendtitle = "#{QXLS_150724_19}", receivetitle = "#{QXLS_150724_20}", 
			strsend = "#{QXLS_150724_23}", strreceive = "#{QXLS_150724_24}", 
			strsendNum = "#{QXLS_150724_25}", strreceiveNum = "#{QXLS_150724_26}", 
			stateing = "#{QXLS_150724_13}", stateend = "#{QXLS_150724_18}", 
			BounsBtnTip = "#{QXLS_150724_13}", szSendBonusTip="#{QXLS_220517_15}", szReceiveBonusTip="#{QXLS_220517_17}"
		},
-- 七夕纯爱
	[2] = {desc = "#{QXLS_150724_31}", count = 3, sendmd = 3523, receivemd = 3524, 
			sendtitle = "#{QXLS_150724_34}", receivetitle = "#{QXLS_150724_35}", 
			strsend = "#{QXLS_150724_23}", strreceive = "#{QXLS_150724_24}", 
			strsendNum = "#{QXLS_150724_36}", strreceiveNum = "#{QXLS_150724_37}", 
			stateing = "#{QXLS_150724_32}", stateend = "#{QXLS_150724_33}", 
			BounsBtnTip = "#{QXLS_150724_32}", szSendBonusTip="#{QXLS_220517_20}", szReceiveBonusTip="#{QXLS_220517_21}"
		},
-- 今生挚恋
	[3] = {desc = "#{QXLS_150724_38}", count = 3, sendmd = 3525, receivemd = 3526, 
			sendtitle = "#{QXLS_150724_39}", receivetitle = "#{QXLS_150724_40}", 
			strsend = "#{QXLS_150724_23}", strreceive = "#{QXLS_150724_24}", 
			strsendNum = "#{QXLS_150724_41}", strreceiveNum = "#{QXLS_150724_42}", 
			stateing = "#{QXLS_150724_149}", stateend = "#{QXLS_150724_150}", 
			BounsBtnTip = "#{QXLS_150724_149}", szSendBonusTip="#{QXLS_220517_18}", szReceiveBonusTip="#{QXLS_220517_19}"
		},
}

-- 累计送花数量
local g_SeventhFestivalTopList_LeiJi_SendMD = 3527	
local g_SeventhFestivalTopList_QingRenJie = 3528	
local g_SeventhFestivalTopList_ChiQingYu = 3529
local g_SeventhFestivalTopList_XiangSiJie = 3530

--榜单信息
local g_SeventhFestivalTopList_Tip = --待修改
{
	[1] = {tip1 = "#{QXLS_150724_71}", tip2 = "#{QXLS_150724_72}", tip3 = "#{QXLS_150724_73}"},
	[2] = {tip1 = "#{QXLS_150724_71}", tip2 = "#{QXLS_150724_126}", tip3 = "#{QXLS_150724_73}"},
	[3] = {tip1 = "#{QXLS_150724_71}", tip2 = "#{QXLS_150724_127}", tip3 = "#{QXLS_150724_73}"},
}

--预览数据
local g_SeventhFestivalTopList_PreviewInfo = 
{
	[38008816] = { dressId=10128887, hairId=300, faceId=216 },		--前世仙缘礼盒·圣
	[38008817] = { dressId=10128886, hairId=300, faceId=216 },		--前世仙缘礼盒·钻
	[38008818] = { dressId=10128885, hairId=300, faceId=216 },		--前世仙缘礼盒·金
	[38008819] = { dressId=10128888, hairId=300, faceId=216 },		--前世仙缘礼盒·银
	[38008820] = { dressId=10128884, hairId=300, faceId=216 },		--前世仙缘礼盒·铜
	[38008831] = { dressId=10128871, hairId=299, faceId=216 },		--兑换 衣服礼盒
}

--榜单奖励
local g_SeventhFestivalTopList_SendBonus = --送花奖励具体物品
{
	[1] = {	--今生挚恋
		[1]={ itemId1=38008812, 	itemId2=39923939, 	itemId3=39924393, preview=0 },
		[2]={ itemId1=0, 	itemId2=0, 			itemId3=38008813, preview=0 },
		[3]={ itemId1=0, 	itemId2=0, 			itemId3=38008814, preview=0 },
		[4]={ itemId1=0, 	itemId2=0, 			itemId3=38008815, preview=0 },
		[5]={ itemId1=0, 	itemId2=0, 			itemId3=39910166, preview=0 },
	},
	[2] = {	--倾世情人
		[1]={ itemId1=38008821, 	itemId2=39923941, 	itemId3=39924391, preview=0 },
		[2]={ itemId1=0, 	itemId2=0, 			itemId3=38008822, preview=0 },
		[3]={ itemId1=0, 	itemId2=0, 			itemId3=38008823, preview=0 },
		[4]={ itemId1=0, 	itemId2=0, 			itemId3=38008824, preview=0 },
		[5]={ itemId1=0, 	itemId2=0, 			itemId3=38008825, preview=0 },
	},
	[3] = {	--前世仙缘
		[1]={ itemId1=38008816, 	itemId2=39923937, 	itemId3=39924389, preview=1 },
		[2]={ itemId1=0, 	itemId2=0, 			itemId3=38008817, preview=3 },
		[3]={ itemId1=0, 	itemId2=0, 			itemId3=38008818, preview=3 },
		[4]={ itemId1=0, 	itemId2=0, 			itemId3=38008819, preview=3 },
		[5]={ itemId1=0, 	itemId2=0, 			itemId3=38008820, preview=3 },
	},
}

local g_SeventhFestivalTopList_ReceiveBonus = --收花奖励具体物品
{
	[1] = {	--今生挚恋
		[1]={ itemId1=38008812, 	itemId2=39923940, 	itemId3=39924394, preview=0 },
		[2]={ itemId1=0, 	itemId2=0, 			itemId3=38008813, preview=0 },
		[3]={ itemId1=0, 	itemId2=0, 			itemId3=38008814, preview=0 },
		[4]={ itemId1=0, 	itemId2=0, 			itemId3=38008815, preview=0 },
		[5]={ itemId1=0, 	itemId2=0, 			itemId3=39910166, preview=0 },
	},
	[2] = {	--倾世情人
		[1]={ itemId1=38008821, 	itemId2=39923942, 	itemId3=39924392, preview=0 },
		[2]={ itemId1=0, 	itemId2=0, 			itemId3=38008822, preview=0 },
		[3]={ itemId1=0, 	itemId2=0, 			itemId3=38008823, preview=0 },
		[4]={ itemId1=0, 	itemId2=0, 			itemId3=38008824, preview=0 },
		[5]={ itemId1=0, 	itemId2=0, 			itemId3=38008825, preview=0 },
	},
	[3] = {	--前世仙缘
		[1]={ itemId1=38008816, 	itemId2=39923938, 	itemId3=39924390, preview=1 },
		[2]={ itemId1=0, 	itemId2=0, 			itemId3=38008817, preview=3 },
		[3]={ itemId1=0, 	itemId2=0, 			itemId3=38008818, preview=3 },
		[4]={ itemId1=0, 	itemId2=0, 			itemId3=38008819, preview=3 },
		[5]={ itemId1=0, 	itemId2=0, 			itemId3=38008820, preview=3 },
	},
}

local SeventhFestivalTopList_RankingImage={
	[1] = "set:ValentineRoseTopList image:ValentineRoseTopList_1",
	[2] = "set:ValentineRoseTopList image:ValentineRoseTopList_2",
	[3] = "set:ValentineRoseTopList image:ValentineRoseTopList_3",
	[4] = "set:ValentineRoseTopList image:ValentineRoseTopList_4",
	[5] = "set:ValentineRoseTopList image:ValentineRoseTopList_5",
	[6] = "set:ValentineRoseTopList image:ValentineRoseTopList_6",
	[7] = "set:ValentineRoseTopList image:ValentineRoseTopList_7",
	[8] = "set:ValentineRoseTopList image:ValentineRoseTopList_8",
	[9] = "set:ValentineRoseTopList image:ValentineRoseTopList_9",
	[10] = "set:ValentineRoseTopList image:ValentineRoseTopList_10",
	[11] = "set:ValentineRoseTopList image:ValentineRoseTopList_11",
	[12] = "set:ValentineRoseTopList image:ValentineRoseTopList_12",
	[13] = "set:ValentineRoseTopList image:ValentineRoseTopList_13",
	[14] = "set:ValentineRoseTopList image:ValentineRoseTopList_14",
	[15] = "set:ValentineRoseTopList image:ValentineRoseTopList_15",
	[16] = "set:ValentineRoseTopList image:ValentineRoseTopList_16",
	[17] = "set:ValentineRoseTopList image:ValentineRoseTopList_17",
	[18] = "set:ValentineRoseTopList image:ValentineRoseTopList_18",
	[19] = "set:ValentineRoseTopList image:ValentineRoseTopList_19",
	[20] = "set:ValentineRoseTopList image:ValentineRoseTopList_20",
}

-- 兑换界面
local SeventhFestivalTopList_Exchange_Qingrenjie_BK = {}
local SeventhFestivalTopList_Exchange_Qingrenjie_Action = {}
local SeventhFestivalTopList_Exchange_Qingrenjie_Button = {}
local SeventhFestivalTopList_Exchange_Qingrenjie_Name = {}
local SeventhFestivalTopList_Exchange_Qingrenjie_Text = {}
local SeventhFestivalTopList_Exchange_Qingrenjie_Preview = {}
local SeventhFestivalTopList_Exchange_Qingrenjie_Limit = {}
local SeventhFestivalTopList_Exchange_Qingrenjie_Mask = {}
local SeventhFestivalTopList_Exchange_Qingrenjie_Num = {}

local SeventhFestivalTopList_Exchange_Chiqingyu_Action = {}
local SeventhFestivalTopList_Exchange_Chiqingyu_Button = {}
local SeventhFestivalTopList_Exchange_Chiqingyu_Name = {}
local SeventhFestivalTopList_Exchange_Chiqingyu_Text = {}

local SeventhFestivalTopList_Exchange_XiangSiJie_Action = {}
local SeventhFestivalTopList_Exchange_XiangSiJie_Name = {}
local SeventhFestivalTopList_Exchange_XiangSiJie_Text = {}

local g_SeventhFestivalTopList_Qingrenjie_Page = 1

g_SeventhFestivalTopList_Qingrenjie_Bonus =
{
	[1] = {neednum = 1314, itemid = 38008831, count = 1, name = "倾世回首礼盒", IsShow = 1, limitnum = -1, LimitMD = -1, OnPage = 1 },
	
	[2] = {neednum = 1250, itemid = 10101161, count = 1, name = "武器：征人归", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },
	[3] = {neednum = 1100, itemid = 10101154, count = 1, name = "武器：盘龙霸王戟", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },
	[4] = {neednum = 850, itemid = 10192302, count = 1, name = "武器：栖凰红颜剑", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },
	
	[5] = {neednum = 1688, itemid = 39910166, count = 1, name = "超级珍兽笼：楚小九", IsShow = 0, limitnum = 3, LimitMD = 3531, OnPage = 1 },
	[6] = {neednum = 1314, itemid = 39920914, count = 1, name = "95自适应珍兽笼：美人鱼", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },
	[7] = {neednum = 521, itemid = 39920915, count = 1, name = "95自适应珍兽蛋：美人鱼", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },
	
	[8] = {neednum = 300, itemid = 10102101, count = 1, name = "武器：棒棒糖（红）", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },
	[9] = {neednum = 300, itemid = 10102102, count = 1, name = "武器：棒棒糖（绿）", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },
	[10] = {neednum = 300, itemid = 10102103, count = 1, name = "武器：棒棒糖（蓝）", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },
	
	[11] = {neednum = 150, itemid = 39920549, count = 1, name = "一生一世", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },
	[12] = {neednum = 150, itemid = 39920550, count = 1, name = "永恒之爱", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },
	[13] = {neednum = 120, itemid = 39920551, count = 1, name = "漫天花雨", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },	
	[14] = {neednum = 120, itemid = 39920552, count = 1, name = "漫天花雨·心相印", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },
	
	[15] = {neednum = 20, itemid = 38006185, count = 1, name = "花海钱币", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },
	[16] = {neednum = 2, itemid = 38006186, count = 1, name = "花间钱币", IsShow = 0, limitnum = -1, LimitMD = -1, OnPage = 1 },
}

g_SeventhFestivalTopList_Chiqingyu_Bonus =
{
	[1] = {neednum = 2, itemid = 38000403, count = 1, name = "千缘蜜语金丝"},
	[2] = {neednum = 2, itemid = 38000404, count = 1, name = "柔情蜜语金丝"},
	[3] = {neednum = 2, itemid = 38000405, count = 1, name = "甜美蜜语金丝"},
	[4] = {neednum = 2, itemid = 38000406, count = 1, name = "美满蜜语金丝"},
	[5] = {neednum = 2, itemid = 38001165, count = 1, name = "唯爱蜜语金丝"},
	[6] = {neednum = 2, itemid = 38001166, count = 1, name = "浓情蜜语金丝"},
	[7] = {neednum = 2, itemid = 38001337, count = 1, name = "纯爱蜜语金丝"},
	[8] = {neednum = 2, itemid = 38001338, count = 1, name = "挚爱蜜语金丝"},
	
	[9] = {neednum = 1, itemid = 39920904, count = 1, name = "红尘浪子", namewoman = "玲珑碧玉"},
	[10] = {neednum = 3, itemid = 39920905, count = 1, name = "俊逸英才", namewoman = "金枝玉叶"},
	[11] = {neednum = 10, itemid = 39920906, count = 1, name = "情诗圣手", namewoman = "倾世风华"},
	[12] = {neednum = 16, itemid = 39920907, count = 1, name = "仙凡情痴", namewoman = "瑶池仙姿"},
	
	[13] = {neednum = 8, itemid = 38010012, count = 1, name = "相框：银霄鹊舞", namewoman = "相框：银霄鹊舞"},		
}

g_SeventhFestivalTopList_XiangSiJie_Bonus =
{
	[1] = {neednum = 1, itemid = 10104107, count = 1, name = "武器：暖香粉蕊", IsShow = 0},
	[2] = {neednum = 1, itemid = 10104119, count = 1, name = "武器：冷玉寒芳", IsShow = 0},
	[3] = {neednum = 1, itemid = 10102119, count = 1, name = "武器：蓝色妖姬", IsShow = 0},
	
	[4] = {neednum = 1, itemid = 10102126, count = 1, name = "武器：浪漫小熊", IsShow = 0},
	[5] = {neednum = 1, itemid = 10102620, count = 1, name = "武器：合欢扇", IsShow = 0},
	[6] = {neednum = 1, itemid = 10105017, count = 1, name = "武器：影流韶", IsShow = 0},
	
	[7] = {neednum = 1, itemid = 10102719, count = 1, name = "武器：迢迢河汉语", IsShow = 0},
	[8] = {neednum = 1, itemid = 10102815, count = 1, name = "武器：风荷举", IsShow = 0},
	[9] = {neednum = 1, itemid = 10102920, count = 1, name = "武器：玉骨摇", IsShow = 0},
	[10] = {neednum = 1, itemid = 10102990, count = 1, name = "武器：粉红甜心", IsShow = 0},
	
	[11] = {neednum = 1, itemid = 38007641, count = 1, name = "挚恋心币", IsShow = 0},
}

local SeventhFestivalTopList_LeiJi_Bonus=
{
	[1]={need=11, itemId=38000992, count=2, MF=5670 },			--虹耀石*2
	[2]={need=33, itemId=39921051, count=5, MF=5671 },			--缀梦灵石*5
	[3]={need=99, itemId=38001332, count=5, MF=5672 },			--情诗恋曲*5
	[4]={need=188, itemId=10124726, count=1, MF=5673 },			--时装：仙侣情缘（30天，拾取绑定，拾取计时）
	[5]={need=521, itemId=38005288, count=30, MF=5674 },		--瑶华璧*30
	[6]={need=1688, itemId=39920871, count=300, MF=5675 },		--情人结：300
}

--===============================================
-- PreLoad()
--===============================================
function SeventhFestivalTopList_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_QIXI_TOPLIST")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UPDATE_QINGRENJIE_MD",false)
end

--===============================================
-- OnLoad()
--===============================================
function SeventhFestivalTopList_OnLoad()

	g_SeventhFestivalTopList_UnifiedPosition = SeventhFestivalTopList_Frame:GetProperty("UnifiedPosition")
		
--排行榜相关控件
	g_SeventhFestivalTopList_Btn_Page[1]	= SeventhFestivalTopList_Top_TopList1
	g_SeventhFestivalTopList_Btn_Page[2]	= SeventhFestivalTopList_Top_TopList2
	g_SeventhFestivalTopList_Btn_Page[3]	= SeventhFestivalTopList_Top_TopList3
	
--花榜下面的三个榜控件
	g_SeventhFestivalTopList_Btn_FlowerPage[1] = SeventhFestivalTopList_Ranking_Bang2;
	g_SeventhFestivalTopList_Btn_FlowerPage[2] = SeventhFestivalTopList_Ranking_Bang3;
	g_SeventhFestivalTopList_Btn_FlowerPage[3] = SeventhFestivalTopList_Ranking_Bang1;
	
	g_SeventhFestivalTopList_Btn_FlowerPage_Redpoint[1] = SeventhFestivalTopList_Ranking_Bang2_Tips;
	g_SeventhFestivalTopList_Btn_FlowerPage_Redpoint[2] = SeventhFestivalTopList_Ranking_Bang3_Tips;
	g_SeventhFestivalTopList_Btn_FlowerPage_Redpoint[3] = SeventhFestivalTopList_Ranking_Bang1_Tips;
	
--奖励排名控件	
	SeventhFestivalTopList_ListInfo_InitCtrl()

--排行榜奖励相关控件	
	SeventhFestivalTopList_Bonus_InitCtrl()

--排行榜兑换相关控件
	SeventhFestivalTopList_Exchange_InitCtrl()
	
--累计奖励
	SeventhFestivalTopList_LeiJi_InitCtrl()
	
end

function SeventhFestivalTopList_ListInfo_InitCtrl()

	g_SeventhFestivalTopList_Present_Num[1]		= SeventhFestivalTopList_Present_Item1_Num_Icon
	g_SeventhFestivalTopList_Present_Num[2]		= SeventhFestivalTopList_Present_Item2_Num_Icon
	g_SeventhFestivalTopList_Present_Num[3]		= SeventhFestivalTopList_Present_Item3_Num_Icon
	g_SeventhFestivalTopList_Present_Num[4]		= SeventhFestivalTopList_Present_Item4_Num_Icon
	g_SeventhFestivalTopList_Present_Num[5]		= SeventhFestivalTopList_Present_Item5_Num_Icon
	
	g_SeventhFestivalTopList_Present_Name[1]	= SeventhFestivalTopList_Present_Item1_Name
	g_SeventhFestivalTopList_Present_Name[2]	= SeventhFestivalTopList_Present_Item2_Name
	g_SeventhFestivalTopList_Present_Name[3]	= SeventhFestivalTopList_Present_Item3_Name
	g_SeventhFestivalTopList_Present_Name[4]	= SeventhFestivalTopList_Present_Item4_Name
	g_SeventhFestivalTopList_Present_Name[5]	= SeventhFestivalTopList_Present_Item5_Name
	
	g_SeventhFestivalTopList_Present_Score[1]	= SeventhFestivalTopList_Present_Item1_Count
	g_SeventhFestivalTopList_Present_Score[2]	= SeventhFestivalTopList_Present_Item2_Count
	g_SeventhFestivalTopList_Present_Score[3]	= SeventhFestivalTopList_Present_Item3_Count
	g_SeventhFestivalTopList_Present_Score[4]	= SeventhFestivalTopList_Present_Item4_Count
	g_SeventhFestivalTopList_Present_Score[5]	= SeventhFestivalTopList_Present_Item5_Count
	
	g_SeventhFestivalTopList_Receive_Num[1]	= SeventhFestivalTopList_Receive_Item1_Num_Icon
	g_SeventhFestivalTopList_Receive_Num[2]	= SeventhFestivalTopList_Receive_Item2_Num_Icon
	g_SeventhFestivalTopList_Receive_Num[3]	= SeventhFestivalTopList_Receive_Item3_Num_Icon
	g_SeventhFestivalTopList_Receive_Num[4]	= SeventhFestivalTopList_Receive_Item4_Num_Icon
	g_SeventhFestivalTopList_Receive_Num[5]	= SeventhFestivalTopList_Receive_Item5_Num_Icon
	
	g_SeventhFestivalTopList_Receive_Name[1]	= SeventhFestivalTopList_Receive_Item1_Name
	g_SeventhFestivalTopList_Receive_Name[2]	= SeventhFestivalTopList_Receive_Item2_Name
	g_SeventhFestivalTopList_Receive_Name[3]	= SeventhFestivalTopList_Receive_Item3_Name
	g_SeventhFestivalTopList_Receive_Name[4]	= SeventhFestivalTopList_Receive_Item4_Name
	g_SeventhFestivalTopList_Receive_Name[5]	= SeventhFestivalTopList_Receive_Item5_Name
	
	g_SeventhFestivalTopList_Receive_Score[1]	= SeventhFestivalTopList_Receive_Item1_Count
	g_SeventhFestivalTopList_Receive_Score[2]	= SeventhFestivalTopList_Receive_Item2_Count
	g_SeventhFestivalTopList_Receive_Score[3]	= SeventhFestivalTopList_Receive_Item3_Count
	g_SeventhFestivalTopList_Receive_Score[4]	= SeventhFestivalTopList_Receive_Item4_Count
	g_SeventhFestivalTopList_Receive_Score[5]	= SeventhFestivalTopList_Receive_Item5_Count
	
end

function SeventhFestivalTopList_Bonus_InitCtrl()
	
	g_SeventhFestivalTopList_Present_BonusAction1[1] = SeventhFestivalTopList_Present_Item1_Button1
	g_SeventhFestivalTopList_Present_BonusAction1[2] = SeventhFestivalTopList_Present_Item2_Button1
	g_SeventhFestivalTopList_Present_BonusAction1[3] = SeventhFestivalTopList_Present_Item3_Button1
	g_SeventhFestivalTopList_Present_BonusAction1[4] = SeventhFestivalTopList_Present_Item4_Button1
	g_SeventhFestivalTopList_Present_BonusAction1[5] = SeventhFestivalTopList_Present_Item5_Button1
	
	g_SeventhFestivalTopList_Present_BonusAction2[1] = SeventhFestivalTopList_Present_Item1_Button2
	g_SeventhFestivalTopList_Present_BonusAction2[2] = SeventhFestivalTopList_Present_Item2_Button2
	g_SeventhFestivalTopList_Present_BonusAction2[3] = SeventhFestivalTopList_Present_Item3_Button2
	g_SeventhFestivalTopList_Present_BonusAction2[4] = SeventhFestivalTopList_Present_Item4_Button2
	g_SeventhFestivalTopList_Present_BonusAction2[5] = SeventhFestivalTopList_Present_Item5_Button2
	
	g_SeventhFestivalTopList_Present_BonusAction3[1] = SeventhFestivalTopList_Present_Item1_Button3
	g_SeventhFestivalTopList_Present_BonusAction3[2] = SeventhFestivalTopList_Present_Item2_Button3
	g_SeventhFestivalTopList_Present_BonusAction3[3] = SeventhFestivalTopList_Present_Item3_Button3
	g_SeventhFestivalTopList_Present_BonusAction3[4] = SeventhFestivalTopList_Present_Item4_Button3
	g_SeventhFestivalTopList_Present_BonusAction3[5] = SeventhFestivalTopList_Present_Item5_Button3
	
	g_SeventhFestivalTopList_Present_BonusPreview1[1] = SeventhFestivalTopList_Present_Item1_Preview1
	g_SeventhFestivalTopList_Present_BonusPreview1[2] = SeventhFestivalTopList_Present_Item2_Preview1
	g_SeventhFestivalTopList_Present_BonusPreview1[3] = SeventhFestivalTopList_Present_Item3_Preview1
	g_SeventhFestivalTopList_Present_BonusPreview1[4] = SeventhFestivalTopList_Present_Item4_Preview1
	g_SeventhFestivalTopList_Present_BonusPreview1[5] = SeventhFestivalTopList_Present_Item5_Preview1
	
	g_SeventhFestivalTopList_Present_BonusPreview2[1] = SeventhFestivalTopList_Present_Item1_Preview2
	g_SeventhFestivalTopList_Present_BonusPreview2[2] = SeventhFestivalTopList_Present_Item2_Preview2
	g_SeventhFestivalTopList_Present_BonusPreview2[3] = SeventhFestivalTopList_Present_Item3_Preview2
	g_SeventhFestivalTopList_Present_BonusPreview2[4] = SeventhFestivalTopList_Present_Item4_Preview2
	g_SeventhFestivalTopList_Present_BonusPreview2[5] = SeventhFestivalTopList_Present_Item5_Preview2
	
	g_SeventhFestivalTopList_Present_BonusPreview3[1] = SeventhFestivalTopList_Present_Item1_Preview3
	g_SeventhFestivalTopList_Present_BonusPreview3[2] = SeventhFestivalTopList_Present_Item2_Preview3
	g_SeventhFestivalTopList_Present_BonusPreview3[3] = SeventhFestivalTopList_Present_Item3_Preview3
	g_SeventhFestivalTopList_Present_BonusPreview3[4] = SeventhFestivalTopList_Present_Item4_Preview3
	g_SeventhFestivalTopList_Present_BonusPreview3[5] = SeventhFestivalTopList_Present_Item5_Preview3

	g_SeventhFestivalTopList_Receive_BonusAction1[1] = SeventhFestivalTopList_Receive_Item1_Button1
	g_SeventhFestivalTopList_Receive_BonusAction1[2] = SeventhFestivalTopList_Receive_Item2_Button1
	g_SeventhFestivalTopList_Receive_BonusAction1[3] = SeventhFestivalTopList_Receive_Item3_Button1
	g_SeventhFestivalTopList_Receive_BonusAction1[4] = SeventhFestivalTopList_Receive_Item4_Button1
	g_SeventhFestivalTopList_Receive_BonusAction1[5] = SeventhFestivalTopList_Receive_Item5_Button1
	
	g_SeventhFestivalTopList_Receive_BonusAction2[1] = SeventhFestivalTopList_Receive_Item1_Button2
	g_SeventhFestivalTopList_Receive_BonusAction2[2] = SeventhFestivalTopList_Receive_Item2_Button2
	g_SeventhFestivalTopList_Receive_BonusAction2[3] = SeventhFestivalTopList_Receive_Item3_Button2
	g_SeventhFestivalTopList_Receive_BonusAction2[4] = SeventhFestivalTopList_Receive_Item4_Button2
	g_SeventhFestivalTopList_Receive_BonusAction2[5] = SeventhFestivalTopList_Receive_Item5_Button2
	
	g_SeventhFestivalTopList_Receive_BonusAction3[1] = SeventhFestivalTopList_Receive_Item1_Button3
	g_SeventhFestivalTopList_Receive_BonusAction3[2] = SeventhFestivalTopList_Receive_Item2_Button3
	g_SeventhFestivalTopList_Receive_BonusAction3[3] = SeventhFestivalTopList_Receive_Item3_Button3
	g_SeventhFestivalTopList_Receive_BonusAction3[4] = SeventhFestivalTopList_Receive_Item4_Button3
	g_SeventhFestivalTopList_Receive_BonusAction3[5] = SeventhFestivalTopList_Receive_Item5_Button3
	
	g_SeventhFestivalTopList_Receive_BonusPreview1[1] = SeventhFestivalTopList_Receive_Item1_Preview1
	g_SeventhFestivalTopList_Receive_BonusPreview1[2] = SeventhFestivalTopList_Receive_Item2_Preview1
	g_SeventhFestivalTopList_Receive_BonusPreview1[3] = SeventhFestivalTopList_Receive_Item3_Preview1
	g_SeventhFestivalTopList_Receive_BonusPreview1[4] = SeventhFestivalTopList_Receive_Item4_Preview1
	g_SeventhFestivalTopList_Receive_BonusPreview1[5] = SeventhFestivalTopList_Receive_Item5_Preview1
	
	g_SeventhFestivalTopList_Receive_BonusPreview2[1] = SeventhFestivalTopList_Receive_Item1_Preview2
	g_SeventhFestivalTopList_Receive_BonusPreview2[2] = SeventhFestivalTopList_Receive_Item2_Preview2
	g_SeventhFestivalTopList_Receive_BonusPreview2[3] = SeventhFestivalTopList_Receive_Item3_Preview2
	g_SeventhFestivalTopList_Receive_BonusPreview2[4] = SeventhFestivalTopList_Receive_Item4_Preview2
	g_SeventhFestivalTopList_Receive_BonusPreview2[5] = SeventhFestivalTopList_Receive_Item5_Preview2
	
	g_SeventhFestivalTopList_Receive_BonusPreview3[1] = SeventhFestivalTopList_Receive_Item1_Preview3
	g_SeventhFestivalTopList_Receive_BonusPreview3[2] = SeventhFestivalTopList_Receive_Item2_Preview3
	g_SeventhFestivalTopList_Receive_BonusPreview3[3] = SeventhFestivalTopList_Receive_Item3_Preview3
	g_SeventhFestivalTopList_Receive_BonusPreview3[4] = SeventhFestivalTopList_Receive_Item4_Preview3
	g_SeventhFestivalTopList_Receive_BonusPreview3[5] = SeventhFestivalTopList_Receive_Item5_Preview3
	
end

function SeventhFestivalTopList_Exchange_InitCtrl()

	SeventhFestivalTopList_Exchange_Qingrenjie_BK[1] = SeventhFestivalTopList_ExchangeFrame_BK1
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[2] = SeventhFestivalTopList_ExchangeFrame_BK2
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[3] = SeventhFestivalTopList_ExchangeFrame_BK3
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[4] = SeventhFestivalTopList_ExchangeFrame_BK4
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[5] = SeventhFestivalTopList_ExchangeFrame_BK5
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[6] = SeventhFestivalTopList_ExchangeFrame_BK6
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[7] = SeventhFestivalTopList_ExchangeFrame_BK7
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[8] = SeventhFestivalTopList_ExchangeFrame_BK8
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[9] = SeventhFestivalTopList_ExchangeFrame_BK9
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[10] = SeventhFestivalTopList_ExchangeFrame_BK10
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[11] = SeventhFestivalTopList_ExchangeFrame_BK11
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[12] = SeventhFestivalTopList_ExchangeFrame_BK12
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[13] = SeventhFestivalTopList_ExchangeFrame_BK13
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[14] = SeventhFestivalTopList_ExchangeFrame_BK14
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[15] = SeventhFestivalTopList_ExchangeFrame_BK15
	SeventhFestivalTopList_Exchange_Qingrenjie_BK[16] = SeventhFestivalTopList_ExchangeFrame_BK16
	
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[1] = SeventhFestivalTopList_ExchangeFrame_BK1_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[2] = SeventhFestivalTopList_ExchangeFrame_BK2_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[3] = SeventhFestivalTopList_ExchangeFrame_BK3_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[4] = SeventhFestivalTopList_ExchangeFrame_BK4_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[5] = SeventhFestivalTopList_ExchangeFrame_BK5_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[6] = SeventhFestivalTopList_ExchangeFrame_BK6_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[7] = SeventhFestivalTopList_ExchangeFrame_BK7_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[8] = SeventhFestivalTopList_ExchangeFrame_BK8_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[9] = SeventhFestivalTopList_ExchangeFrame_BK9_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[10] = SeventhFestivalTopList_ExchangeFrame_BK10_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[11] = SeventhFestivalTopList_ExchangeFrame_BK11_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[12] = SeventhFestivalTopList_ExchangeFrame_BK12_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[13] = SeventhFestivalTopList_ExchangeFrame_BK13_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[14] = SeventhFestivalTopList_ExchangeFrame_BK14_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[15] = SeventhFestivalTopList_ExchangeFrame_BK15_Icon
	SeventhFestivalTopList_Exchange_Qingrenjie_Action[16] = SeventhFestivalTopList_ExchangeFrame_BK16_Icon
	
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[1] = SeventhFestivalTopList_ExchangeFrame_BK1_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[2] = SeventhFestivalTopList_ExchangeFrame_BK2_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[3] = SeventhFestivalTopList_ExchangeFrame_BK3_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[4] = SeventhFestivalTopList_ExchangeFrame_BK4_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[5] = SeventhFestivalTopList_ExchangeFrame_BK5_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[6] = SeventhFestivalTopList_ExchangeFrame_BK6_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[7] = SeventhFestivalTopList_ExchangeFrame_BK7_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[8] = SeventhFestivalTopList_ExchangeFrame_BK8_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[9] = SeventhFestivalTopList_ExchangeFrame_BK9_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[10] = SeventhFestivalTopList_ExchangeFrame_BK10_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[11] = SeventhFestivalTopList_ExchangeFrame_BK11_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[12] = SeventhFestivalTopList_ExchangeFrame_BK12_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[13] = SeventhFestivalTopList_ExchangeFrame_BK13_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[14] = SeventhFestivalTopList_ExchangeFrame_BK14_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[15] = SeventhFestivalTopList_ExchangeFrame_BK15_Icon_Preview
	SeventhFestivalTopList_Exchange_Qingrenjie_Preview[16] = SeventhFestivalTopList_ExchangeFrame_BK16_Icon_Preview
	
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[1] = SeventhFestivalTopList_ExchangeFrame_BK1_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[2] = SeventhFestivalTopList_ExchangeFrame_BK2_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[3] = SeventhFestivalTopList_ExchangeFrame_BK3_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[4] = SeventhFestivalTopList_ExchangeFrame_BK4_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[5] = SeventhFestivalTopList_ExchangeFrame_BK5_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[6] = SeventhFestivalTopList_ExchangeFrame_BK6_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[7] = SeventhFestivalTopList_ExchangeFrame_BK7_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[8] = SeventhFestivalTopList_ExchangeFrame_BK8_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[9] = SeventhFestivalTopList_ExchangeFrame_BK9_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[10] = SeventhFestivalTopList_ExchangeFrame_BK10_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[11] = SeventhFestivalTopList_ExchangeFrame_BK11_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[12] = SeventhFestivalTopList_ExchangeFrame_BK12_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[13] = SeventhFestivalTopList_ExchangeFrame_BK13_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[14] = SeventhFestivalTopList_ExchangeFrame_BK14_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[15] = SeventhFestivalTopList_ExchangeFrame_BK15_Icon_NumBK
	SeventhFestivalTopList_Exchange_Qingrenjie_Limit[16] = SeventhFestivalTopList_ExchangeFrame_BK16_Icon_NumBK
	
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[1] = SeventhFestivalTopList_ExchangeFrame_BK1_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[2] = SeventhFestivalTopList_ExchangeFrame_BK2_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[3] = SeventhFestivalTopList_ExchangeFrame_BK3_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[4] = SeventhFestivalTopList_ExchangeFrame_BK4_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[5] = SeventhFestivalTopList_ExchangeFrame_BK5_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[6] = SeventhFestivalTopList_ExchangeFrame_BK6_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[7] = SeventhFestivalTopList_ExchangeFrame_BK7_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[8] = SeventhFestivalTopList_ExchangeFrame_BK8_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[9] = SeventhFestivalTopList_ExchangeFrame_BK9_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[10] = SeventhFestivalTopList_ExchangeFrame_BK10_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[11] = SeventhFestivalTopList_ExchangeFrame_BK11_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[12] = SeventhFestivalTopList_ExchangeFrame_BK12_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[13] = SeventhFestivalTopList_ExchangeFrame_BK13_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[14] = SeventhFestivalTopList_ExchangeFrame_BK14_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[15] = SeventhFestivalTopList_ExchangeFrame_BK15_Icon_Num
	SeventhFestivalTopList_Exchange_Qingrenjie_Num[16] = SeventhFestivalTopList_ExchangeFrame_BK16_Icon_Num
	
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[1] = SeventhFestivalTopList_ExchangeFrame_BK1_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[2] = SeventhFestivalTopList_ExchangeFrame_BK2_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[3] = SeventhFestivalTopList_ExchangeFrame_BK3_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[4] = SeventhFestivalTopList_ExchangeFrame_BK4_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[5] = SeventhFestivalTopList_ExchangeFrame_BK5_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[6] = SeventhFestivalTopList_ExchangeFrame_BK6_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[7] = SeventhFestivalTopList_ExchangeFrame_BK7_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[8] = SeventhFestivalTopList_ExchangeFrame_BK8_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[9] = SeventhFestivalTopList_ExchangeFrame_BK9_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[10] = SeventhFestivalTopList_ExchangeFrame_BK10_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[11] = SeventhFestivalTopList_ExchangeFrame_BK11_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[12] = SeventhFestivalTopList_ExchangeFrame_BK12_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[13] = SeventhFestivalTopList_ExchangeFrame_BK13_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[14] = SeventhFestivalTopList_ExchangeFrame_BK14_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[15] = SeventhFestivalTopList_ExchangeFrame_BK15_Icon_RedMask
	SeventhFestivalTopList_Exchange_Qingrenjie_Mask[16] = SeventhFestivalTopList_ExchangeFrame_BK16_Icon_RedMask
	
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[1] = SeventhFestivalTopList_ExchangeFrame_BK1_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[2] = SeventhFestivalTopList_ExchangeFrame_BK2_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[3] = SeventhFestivalTopList_ExchangeFrame_BK3_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[4] = SeventhFestivalTopList_ExchangeFrame_BK4_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[5] = SeventhFestivalTopList_ExchangeFrame_BK5_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[6] = SeventhFestivalTopList_ExchangeFrame_BK6_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[7] = SeventhFestivalTopList_ExchangeFrame_BK7_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[8] = SeventhFestivalTopList_ExchangeFrame_BK8_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[9] = SeventhFestivalTopList_ExchangeFrame_BK9_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[10] = SeventhFestivalTopList_ExchangeFrame_BK10_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[11] = SeventhFestivalTopList_ExchangeFrame_BK11_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[12] = SeventhFestivalTopList_ExchangeFrame_BK12_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[13] = SeventhFestivalTopList_ExchangeFrame_BK13_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[14] = SeventhFestivalTopList_ExchangeFrame_BK14_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[15] = SeventhFestivalTopList_ExchangeFrame_BK15_Text1
	SeventhFestivalTopList_Exchange_Qingrenjie_Name[16] = SeventhFestivalTopList_ExchangeFrame_BK16_Text1

	SeventhFestivalTopList_Exchange_Qingrenjie_Text[1] = SeventhFestivalTopList_ExchangeFrame_BK1_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[2] = SeventhFestivalTopList_ExchangeFrame_BK2_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[3] = SeventhFestivalTopList_ExchangeFrame_BK3_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[4] = SeventhFestivalTopList_ExchangeFrame_BK4_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[5] = SeventhFestivalTopList_ExchangeFrame_BK5_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[6] = SeventhFestivalTopList_ExchangeFrame_BK6_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[7] = SeventhFestivalTopList_ExchangeFrame_BK7_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[8] = SeventhFestivalTopList_ExchangeFrame_BK8_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[9] = SeventhFestivalTopList_ExchangeFrame_BK9_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[10] = SeventhFestivalTopList_ExchangeFrame_BK10_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[11] = SeventhFestivalTopList_ExchangeFrame_BK11_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[12] = SeventhFestivalTopList_ExchangeFrame_BK12_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[13] = SeventhFestivalTopList_ExchangeFrame_BK13_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[14] = SeventhFestivalTopList_ExchangeFrame_BK14_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[15] = SeventhFestivalTopList_ExchangeFrame_BK15_Text2
	SeventhFestivalTopList_Exchange_Qingrenjie_Text[16] = SeventhFestivalTopList_ExchangeFrame_BK16_Text2

	SeventhFestivalTopList_Exchange_Chiqingyu_Action[1] = SeventhFestivalTopList_ExchangeFrame1_BK1_Icon
	SeventhFestivalTopList_Exchange_Chiqingyu_Action[2] = SeventhFestivalTopList_ExchangeFrame1_BK2_Icon
	SeventhFestivalTopList_Exchange_Chiqingyu_Action[3] = SeventhFestivalTopList_ExchangeFrame1_BK3_Icon
	SeventhFestivalTopList_Exchange_Chiqingyu_Action[4] = SeventhFestivalTopList_ExchangeFrame1_BK4_Icon
	SeventhFestivalTopList_Exchange_Chiqingyu_Action[5] = SeventhFestivalTopList_ExchangeFrame1_BK5_Icon
	SeventhFestivalTopList_Exchange_Chiqingyu_Action[6] = SeventhFestivalTopList_ExchangeFrame1_BK6_Icon
	SeventhFestivalTopList_Exchange_Chiqingyu_Action[7] = SeventhFestivalTopList_ExchangeFrame1_BK7_Icon
	SeventhFestivalTopList_Exchange_Chiqingyu_Action[8] = SeventhFestivalTopList_ExchangeFrame1_BK12_Icon
	SeventhFestivalTopList_Exchange_Chiqingyu_Action[9] = SeventhFestivalTopList_ExchangeFrame1_BK8_Icon
	SeventhFestivalTopList_Exchange_Chiqingyu_Action[10] = SeventhFestivalTopList_ExchangeFrame1_BK9_Icon
	SeventhFestivalTopList_Exchange_Chiqingyu_Action[11] = SeventhFestivalTopList_ExchangeFrame1_BK10_Icon
	SeventhFestivalTopList_Exchange_Chiqingyu_Action[12] = SeventhFestivalTopList_ExchangeFrame1_BK11_Icon
	SeventhFestivalTopList_Exchange_Chiqingyu_Action[13] = SeventhFestivalTopList_ExchangeFrame1_BK13_Icon
	
	SeventhFestivalTopList_Exchange_Chiqingyu_Name[1] = SeventhFestivalTopList_ExchangeFrame1_BK1_Text1
	SeventhFestivalTopList_Exchange_Chiqingyu_Name[2] = SeventhFestivalTopList_ExchangeFrame1_BK2_Text1
	SeventhFestivalTopList_Exchange_Chiqingyu_Name[3] = SeventhFestivalTopList_ExchangeFrame1_BK3_Text1
	SeventhFestivalTopList_Exchange_Chiqingyu_Name[4] = SeventhFestivalTopList_ExchangeFrame1_BK4_Text1
	SeventhFestivalTopList_Exchange_Chiqingyu_Name[5] = SeventhFestivalTopList_ExchangeFrame1_BK5_Text1
	SeventhFestivalTopList_Exchange_Chiqingyu_Name[6] = SeventhFestivalTopList_ExchangeFrame1_BK6_Text1
	SeventhFestivalTopList_Exchange_Chiqingyu_Name[7] = SeventhFestivalTopList_ExchangeFrame1_BK7_Text1
	SeventhFestivalTopList_Exchange_Chiqingyu_Name[8] = SeventhFestivalTopList_ExchangeFrame1_BK12_Text1
	SeventhFestivalTopList_Exchange_Chiqingyu_Name[9] = SeventhFestivalTopList_ExchangeFrame1_BK8_Text1
	SeventhFestivalTopList_Exchange_Chiqingyu_Name[10] = SeventhFestivalTopList_ExchangeFrame1_BK9_Text1
	SeventhFestivalTopList_Exchange_Chiqingyu_Name[11] = SeventhFestivalTopList_ExchangeFrame1_BK10_Text1
	SeventhFestivalTopList_Exchange_Chiqingyu_Name[12] = SeventhFestivalTopList_ExchangeFrame1_BK11_Text1
	SeventhFestivalTopList_Exchange_Chiqingyu_Name[13] = SeventhFestivalTopList_ExchangeFrame1_BK13_Text1
	
	SeventhFestivalTopList_Exchange_Chiqingyu_Text[1] = SeventhFestivalTopList_ExchangeFrame1_BK1_Text2
	SeventhFestivalTopList_Exchange_Chiqingyu_Text[2] = SeventhFestivalTopList_ExchangeFrame1_BK2_Text2
	SeventhFestivalTopList_Exchange_Chiqingyu_Text[3] = SeventhFestivalTopList_ExchangeFrame1_BK3_Text2
	SeventhFestivalTopList_Exchange_Chiqingyu_Text[4] = SeventhFestivalTopList_ExchangeFrame1_BK4_Text2
	SeventhFestivalTopList_Exchange_Chiqingyu_Text[5] = SeventhFestivalTopList_ExchangeFrame1_BK5_Text2
	SeventhFestivalTopList_Exchange_Chiqingyu_Text[6] = SeventhFestivalTopList_ExchangeFrame1_BK6_Text2
	SeventhFestivalTopList_Exchange_Chiqingyu_Text[7] = SeventhFestivalTopList_ExchangeFrame1_BK7_Text2
	SeventhFestivalTopList_Exchange_Chiqingyu_Text[8] = SeventhFestivalTopList_ExchangeFrame1_BK12_Text2
	SeventhFestivalTopList_Exchange_Chiqingyu_Text[9] = SeventhFestivalTopList_ExchangeFrame1_BK8_Text2
	SeventhFestivalTopList_Exchange_Chiqingyu_Text[10] = SeventhFestivalTopList_ExchangeFrame1_BK9_Text2
	SeventhFestivalTopList_Exchange_Chiqingyu_Text[11] = SeventhFestivalTopList_ExchangeFrame1_BK10_Text2
	SeventhFestivalTopList_Exchange_Chiqingyu_Text[12] = SeventhFestivalTopList_ExchangeFrame1_BK11_Text2
	SeventhFestivalTopList_Exchange_Chiqingyu_Text[13] = SeventhFestivalTopList_ExchangeFrame1_BK13_Text2
		
	SeventhFestivalTopList_Exchange_XiangSiJie_Action[1] = SeventhFestivalTopList_ExchangeFrame_XS1_Icon
	SeventhFestivalTopList_Exchange_XiangSiJie_Action[2] = SeventhFestivalTopList_ExchangeFrame_XS2_Icon
	SeventhFestivalTopList_Exchange_XiangSiJie_Action[3] = SeventhFestivalTopList_ExchangeFrame_XS3_Icon
	SeventhFestivalTopList_Exchange_XiangSiJie_Action[4] = SeventhFestivalTopList_ExchangeFrame_XS4_Icon
	SeventhFestivalTopList_Exchange_XiangSiJie_Action[5] = SeventhFestivalTopList_ExchangeFrame_XS5_Icon
	SeventhFestivalTopList_Exchange_XiangSiJie_Action[6] = SeventhFestivalTopList_ExchangeFrame_XS6_Icon
	SeventhFestivalTopList_Exchange_XiangSiJie_Action[7] = SeventhFestivalTopList_ExchangeFrame_XS7_Icon
	SeventhFestivalTopList_Exchange_XiangSiJie_Action[8] = SeventhFestivalTopList_ExchangeFrame_XS8_Icon
	SeventhFestivalTopList_Exchange_XiangSiJie_Action[9] = SeventhFestivalTopList_ExchangeFrame_XS9_Icon
	SeventhFestivalTopList_Exchange_XiangSiJie_Action[10] = SeventhFestivalTopList_ExchangeFrame_XS10_Icon
	SeventhFestivalTopList_Exchange_XiangSiJie_Action[11] = SeventhFestivalTopList_ExchangeFrame_XS11_Icon
	
	SeventhFestivalTopList_Exchange_XiangSiJie_Name[1] = SeventhFestivalTopList_ExchangeFrame_XS1_Text1
	SeventhFestivalTopList_Exchange_XiangSiJie_Name[2] = SeventhFestivalTopList_ExchangeFrame_XS2_Text1
	SeventhFestivalTopList_Exchange_XiangSiJie_Name[3] = SeventhFestivalTopList_ExchangeFrame_XS3_Text1
	SeventhFestivalTopList_Exchange_XiangSiJie_Name[4] = SeventhFestivalTopList_ExchangeFrame_XS4_Text1
	SeventhFestivalTopList_Exchange_XiangSiJie_Name[5] = SeventhFestivalTopList_ExchangeFrame_XS5_Text1
	SeventhFestivalTopList_Exchange_XiangSiJie_Name[6] = SeventhFestivalTopList_ExchangeFrame_XS6_Text1
	SeventhFestivalTopList_Exchange_XiangSiJie_Name[7] = SeventhFestivalTopList_ExchangeFrame_XS7_Text1
	SeventhFestivalTopList_Exchange_XiangSiJie_Name[8] = SeventhFestivalTopList_ExchangeFrame_XS8_Text1
	SeventhFestivalTopList_Exchange_XiangSiJie_Name[9] = SeventhFestivalTopList_ExchangeFrame_XS9_Text1
	SeventhFestivalTopList_Exchange_XiangSiJie_Name[10] = SeventhFestivalTopList_ExchangeFrame_XS10_Text1
	SeventhFestivalTopList_Exchange_XiangSiJie_Name[11] = SeventhFestivalTopList_ExchangeFrame_XS11_Text1

	SeventhFestivalTopList_Exchange_XiangSiJie_Text[1] = SeventhFestivalTopList_ExchangeFrame_XS1_Text2
	SeventhFestivalTopList_Exchange_XiangSiJie_Text[2] = SeventhFestivalTopList_ExchangeFrame_XS2_Text2
	SeventhFestivalTopList_Exchange_XiangSiJie_Text[3] = SeventhFestivalTopList_ExchangeFrame_XS3_Text2
	SeventhFestivalTopList_Exchange_XiangSiJie_Text[4] = SeventhFestivalTopList_ExchangeFrame_XS4_Text2
	SeventhFestivalTopList_Exchange_XiangSiJie_Text[5] = SeventhFestivalTopList_ExchangeFrame_XS5_Text2
	SeventhFestivalTopList_Exchange_XiangSiJie_Text[6] = SeventhFestivalTopList_ExchangeFrame_XS6_Text2
	SeventhFestivalTopList_Exchange_XiangSiJie_Text[7] = SeventhFestivalTopList_ExchangeFrame_XS7_Text2
	SeventhFestivalTopList_Exchange_XiangSiJie_Text[8] = SeventhFestivalTopList_ExchangeFrame_XS8_Text2
	SeventhFestivalTopList_Exchange_XiangSiJie_Text[9] = SeventhFestivalTopList_ExchangeFrame_XS9_Text2
	SeventhFestivalTopList_Exchange_XiangSiJie_Text[10] = SeventhFestivalTopList_ExchangeFrame_XS10_Text2
	SeventhFestivalTopList_Exchange_XiangSiJie_Text[11] = SeventhFestivalTopList_ExchangeFrame_XS11_Text2
	
end

function SeventhFestivalTopList_LeiJi_InitCtrl()
	g_SeventhFestivalTopList_LeiJi_Text1[1] = SeventhFestivalTopList_Leiji_Item1_Text
	g_SeventhFestivalTopList_LeiJi_Text1[2] = SeventhFestivalTopList_Leiji_Item2_Text
	g_SeventhFestivalTopList_LeiJi_Text1[3] = SeventhFestivalTopList_Leiji_Item3_Text
	g_SeventhFestivalTopList_LeiJi_Text1[4] = SeventhFestivalTopList_Leiji_Item4_Text
	g_SeventhFestivalTopList_LeiJi_Text1[5] = SeventhFestivalTopList_Leiji_Item5_Text
	g_SeventhFestivalTopList_LeiJi_Text1[6] = SeventhFestivalTopList_Leiji_Item6_Text
	
	g_SeventhFestivalTopList_LeiJi_Text2[1] = SeventhFestivalTopList_Leiji_Item1_Text2
	g_SeventhFestivalTopList_LeiJi_Text2[2] = SeventhFestivalTopList_Leiji_Item2_Text2
	g_SeventhFestivalTopList_LeiJi_Text2[3] = SeventhFestivalTopList_Leiji_Item3_Text2
	g_SeventhFestivalTopList_LeiJi_Text2[4] = SeventhFestivalTopList_Leiji_Item4_Text2
	g_SeventhFestivalTopList_LeiJi_Text2[5] = SeventhFestivalTopList_Leiji_Item5_Text2
	g_SeventhFestivalTopList_LeiJi_Text2[6] = SeventhFestivalTopList_Leiji_Item6_Text2
	
	g_SeventhFestivalTopList_LeiJi_Text3[1] = SeventhFestivalTopList_Leiji_Item1_Text3
	g_SeventhFestivalTopList_LeiJi_Text3[2] = SeventhFestivalTopList_Leiji_Item2_Text3
	g_SeventhFestivalTopList_LeiJi_Text3[3] = SeventhFestivalTopList_Leiji_Item3_Text3
	g_SeventhFestivalTopList_LeiJi_Text3[4] = SeventhFestivalTopList_Leiji_Item4_Text3
	g_SeventhFestivalTopList_LeiJi_Text3[5] = SeventhFestivalTopList_Leiji_Item5_Text3
	g_SeventhFestivalTopList_LeiJi_Text3[6] = SeventhFestivalTopList_Leiji_Item6_Text3
	
	g_SeventhFestivalTopList_LeiJi_Action[1] = SeventhFestivalTopList_Leiji_Item1_Button
	g_SeventhFestivalTopList_LeiJi_Action[2] = SeventhFestivalTopList_Leiji_Item2_Button
	g_SeventhFestivalTopList_LeiJi_Action[3] = SeventhFestivalTopList_Leiji_Item3_Button
	g_SeventhFestivalTopList_LeiJi_Action[4] = SeventhFestivalTopList_Leiji_Item4_Button
	g_SeventhFestivalTopList_LeiJi_Action[5] = SeventhFestivalTopList_Leiji_Item5_Button
	g_SeventhFestivalTopList_LeiJi_Action[6] = SeventhFestivalTopList_Leiji_Item6_Button
	
	g_SeventhFestivalTopList_LeiJi_Button[1] = SeventhFestivalTopList_Leiji_Item1_Icon
	g_SeventhFestivalTopList_LeiJi_Button[2] = SeventhFestivalTopList_Leiji_Item2_Icon
	g_SeventhFestivalTopList_LeiJi_Button[3] = SeventhFestivalTopList_Leiji_Item3_Icon
	g_SeventhFestivalTopList_LeiJi_Button[4] = SeventhFestivalTopList_Leiji_Item4_Icon
	g_SeventhFestivalTopList_LeiJi_Button[5] = SeventhFestivalTopList_Leiji_Item5_Icon
	g_SeventhFestivalTopList_LeiJi_Button[6] = SeventhFestivalTopList_Leiji_Item6_Icon
	
	g_SeventhFestivalTopList_LeiJi_Tips[1] = SeventhFestivalTopList_Leiji_Item1_Icon_Tips
	g_SeventhFestivalTopList_LeiJi_Tips[2] = SeventhFestivalTopList_Leiji_Item2_Icon_Tips
	g_SeventhFestivalTopList_LeiJi_Tips[3] = SeventhFestivalTopList_Leiji_Item3_Icon_Tips
	g_SeventhFestivalTopList_LeiJi_Tips[4] = SeventhFestivalTopList_Leiji_Item4_Icon_Tips
	g_SeventhFestivalTopList_LeiJi_Tips[5] = SeventhFestivalTopList_Leiji_Item5_Icon_Tips
	g_SeventhFestivalTopList_LeiJi_Tips[6] = SeventhFestivalTopList_Leiji_Item6_Icon_Tips
	
	g_SeventhFestivalTopList_LeiJi_Image[1] = SeventhFestivalTopList_Leiji_Item1_Image
	g_SeventhFestivalTopList_LeiJi_Image[2] = SeventhFestivalTopList_Leiji_Item2_Image
	g_SeventhFestivalTopList_LeiJi_Image[3] = SeventhFestivalTopList_Leiji_Item3_Image
	g_SeventhFestivalTopList_LeiJi_Image[4] = SeventhFestivalTopList_Leiji_Item4_Image
	g_SeventhFestivalTopList_LeiJi_Image[5] = SeventhFestivalTopList_Leiji_Item5_Image
	g_SeventhFestivalTopList_LeiJi_Image[6] = SeventhFestivalTopList_Leiji_Item6_Image
	
end

--===============================================
-- OnEvent()
--===============================================
function SeventhFestivalTopList_OnEvent(event)

	if (event  == "UI_COMMAND") and (tonumber(arg0) == 891396) then
		--设置当前页
		local npage = Get_XParam_INT(0)
		if npage == 4 then
			if this:IsVisible() and g_SeventhFestivalTopList_CurPage == 3 then
				SeventhFestivalTopList_Rank_ShowRedPoint()
				SeventhFestivalTopList_LeiJiAward_Update()
			end
		elseif npage == 5 then
			if this:IsVisible() then
				SeventhFestivalTopList_Rank_ShowRedPoint()
			end
		else
			if npage < 1 or npage > 3 then
				return
			end
			g_SeventhFestivalTopList_CurPage = 1;   --花榜
			g_SeventhFestivalTopList_FlowerSubPage = npage;
			g_SeventhFestivalTopList_Btn_Page[g_SeventhFestivalTopList_CurPage] : SetCheck(1)
			
			--显示状态
			local state1 = Get_XParam_INT(1)
			local state2 = Get_XParam_INT(2)
			local state3 = Get_XParam_INT(3)
			if state1 ~= nil and state1 >= 0 and 
				state2 ~= nil and state2 >= 0 and 
				state3 ~= nil and state3 >= 0 then
				SeventhFestivalTopList_Rank_ShowState(state1, state2, state3)
			end
			
			--显示倒计时
			local strTime = Get_XParam_STR(0)
			if strTime ~= nil then
				SeventhFestivalTopList_Ranking_CountDown:SetText("#{QRPHB_150113_9}"..strTime)
			end
		end
	elseif (event == "OPEN_QIXI_TOPLIST") then
		--显示排行榜
		SeventhFestivalTopList_Rank_ShowRedPoint()
		for i=1, 3 do
			if i ~= index then
				g_SeventhFestivalTopList_Btn_FlowerPage[i]:SetCheck(0);
			end
		end	
		this:Show()
		
		--显示排行榜
		g_SeventhFestivalTopList_PresentRanking_CurPage = 0
		g_SeventhFestivalTopList_ReceiveRanking_CurPage = 0
		SeventhFestivalTopList_Rank_ShowTopList()
	elseif (event == "ADJEST_UI_POS") then
		SeventhFestivalTopList_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SeventhFestivalTopList_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		SeventhFestivalTopList_Close_Click()
	elseif event == "UPDATE_QINGRENJIE_MD" and this:IsVisible() then	
		--情人结数量
		SeventhFestivalTopList_Exchange_UpdateQingRenJieCount()
		--痴情玉数量
		SeventhFestivalTopList_Exchange_UpdateChiqingyuCount()
		--相思结数量
		SeventhFestivalTopList_Exchange_UpdateXiangSiJieCount()
		if g_SeventhFestivalTopList_CurPage == 2 then
			SeventhFestivalTopList_Qingrenjie_UpdateLimit()
		end
	end
end

--===============================================
-- 以下为界面更新显示
--===============================================
--显示排行榜状态
function SeventhFestivalTopList_Rank_ShowState(state1, state2, state3)

	g_SeventhFestivalTopList_AllState[1] = state1;
	g_SeventhFestivalTopList_AllState[2] = state2;
	g_SeventhFestivalTopList_AllState[3] = state3;
	g_SeventhFestivalTopList_State = g_SeventhFestivalTopList_AllState[g_SeventhFestivalTopList_FlowerSubPage];
	
end

--显示排行榜
function SeventhFestivalTopList_Rank_ShowTopList()

--有效性判断
	if g_SeventhFestivalTopList_CurPage ~= 1 then
		return
	end	
	if g_SeventhFestivalTopList_FlowerSubPage < 1 or g_SeventhFestivalTopList_FlowerSubPage > 3 then
		return
	end
		
--设置右侧按钮状态
	g_SeventhFestivalTopList_Btn_FlowerPage[g_SeventhFestivalTopList_FlowerSubPage]:SetCheck(1);
	
--隐藏兑奖
	SeventhFestivalTopList_Exchange_Client:Hide()
	SeventhFestivalTopList_Leiji_Client:Hide()
	
--显示排行榜
	SeventhFestivalTopList_Ranking_Frame:Show()	

--显示活动说明
	SeventhFestivalTopList_Ranking_Info:SetText(g_SeventhFestivalTopList_Info[g_SeventhFestivalTopList_FlowerSubPage].desc)
	
	SeventhFestivalTopList_Present_TitleName:SetText(g_SeventhFestivalTopList_Info[g_SeventhFestivalTopList_FlowerSubPage].sendtitle)
	SeventhFestivalTopList_Receive_TitleName:SetText(g_SeventhFestivalTopList_Info[g_SeventhFestivalTopList_FlowerSubPage].receivetitle)
	
	SeventhFestivalTopList_Rank_ShowTopListPage();
	
	SeventhFestivalTopList_Present_ShowSelfRank()
	SeventhFestivalTopList_Receive_ShowSelfRank()
	
end

--显示排行榜
function SeventhFestivalTopList_Rank_ShowTopListPage()

--显示送花榜单
	SeventhFestivalTopList_Present_ShowRank()
	
--显示收花榜单
	SeventhFestivalTopList_Receive_ShowRank()	
	
end

function SeventhFestivalTopList_Present_ShowRank()

--显示送花榜单
	local strDefName = SeventhFestivalTopList_Rank_DefaultName()
	local sendBonus = g_SeventhFestivalTopList_SendBonus[g_SeventhFestivalTopList_FlowerSubPage];
	
--初始化奖励控件
	for i=1, g_SeventhFestivalTopList_Ranking_CountPerPage do
		g_SeventhFestivalTopList_Present_BonusAction1[i]:Hide();
		g_SeventhFestivalTopList_Present_BonusAction2[i]:Hide();
		g_SeventhFestivalTopList_Present_BonusAction3[i]:Hide();
		g_SeventhFestivalTopList_Present_BonusPreview1[i]:Hide();
		g_SeventhFestivalTopList_Present_BonusPreview2[i]:Hide();
		g_SeventhFestivalTopList_Present_BonusPreview3[i]:Hide();
		g_SeventhFestivalTopList_Receive_BonusAction1[i]:Hide();
		g_SeventhFestivalTopList_Receive_BonusAction2[i]:Hide();
		g_SeventhFestivalTopList_Receive_BonusAction3[i]:Hide();
		g_SeventhFestivalTopList_Receive_BonusPreview1[i]:Hide();
		g_SeventhFestivalTopList_Receive_BonusPreview2[i]:Hide();
		g_SeventhFestivalTopList_Receive_BonusPreview3[i]:Hide();
	end
	
	SeventhFestivalTopList_Present_CurrentlyPage:SetText( ScriptGlobal_Format("#{QXLS_220517_11}", g_SeventhFestivalTopList_PresentRanking_CurPage+1 ) );
	
--上一页
	if g_SeventhFestivalTopList_PresentRanking_CurPage > 0 then
		SeventhFestivalTopList_Present_UpPage:Enable();
	else
		SeventhFestivalTopList_Present_UpPage:Disable();
	end
	
--下一页
	if (g_SeventhFestivalTopList_PresentRanking_CurPage+1) * g_SeventhFestivalTopList_Ranking_CountPerPage < g_SeventhFestivalTopList_Ranking_Count then
		SeventhFestivalTopList_Present_DownPage:Enable();
	else
		SeventhFestivalTopList_Present_DownPage:Disable();
	end
	SeventhFestivalTopList_Ranking_GetAward1:SetToolTip( g_SeventhFestivalTopList_Info[g_SeventhFestivalTopList_FlowerSubPage].szSendBonusTip )  
	
	for i=1, g_SeventhFestivalTopList_Ranking_CountPerPage do
		local nRank = g_SeventhFestivalTopList_Ranking_CountPerPage * g_SeventhFestivalTopList_PresentRanking_CurPage + i;
		
		g_SeventhFestivalTopList_Present_Num[i]:SetProperty("Image", SeventhFestivalTopList_RankingImage[nRank])
		--更新数据
		local index,name,score,isGetBonus,szGuid = DataPool:Lua_GetQixiSendTopListInfo(nRank-1)
		if index ~= nil and index >= 0 and name ~= "" then
			g_SeventhFestivalTopList_Present_Name[i]:SetText( ScriptGlobal_Format("#{QXLS_220517_12}", name ) );
			
			local scoreStr = ScriptGlobal_Format("#{QXLS_220517_13}", tostring(score))
			g_SeventhFestivalTopList_Present_Score[i]:SetText(scoreStr)
		else
			--初始化默认值
			g_SeventhFestivalTopList_Present_Name[i]:SetText(strDefName) --“虚位以待”或者“未能决出”
			
			local scoreStr = ScriptGlobal_Format("#{QXLS_220517_13}", " ")
			g_SeventhFestivalTopList_Present_Score[i]:SetText(scoreStr)
		end
		
		--奖励
		local nBonusRank = SeventhFestivalTopList_ConvertToBonusRank( nRank )
		if sendBonus[nBonusRank] ~= nil then
			if sendBonus[nBonusRank].itemId1 > 0 then
				local theAction = DataPool:CreateActionItemForShow(sendBonus[nBonusRank].itemId1, 1);
				if theAction:GetID() ~= 0 then
					g_SeventhFestivalTopList_Present_BonusAction1[i]:SetActionItem(theAction:GetID())
					g_SeventhFestivalTopList_Present_BonusAction1[i]:Show();
				end
				if sendBonus[nBonusRank].preview == 1 then
					g_SeventhFestivalTopList_Present_BonusPreview1[i]:Show();
				end
			end
			
			if sendBonus[nBonusRank].itemId2 > 0 then
				local theAction = DataPool:CreateActionItemForShow(sendBonus[nBonusRank].itemId2, 1);
				if theAction:GetID() ~= 0 then
					g_SeventhFestivalTopList_Present_BonusAction2[i]:SetActionItem(theAction:GetID())
					g_SeventhFestivalTopList_Present_BonusAction2[i]:Show()
				end
				if sendBonus[nBonusRank].preview == 2 then
					g_SeventhFestivalTopList_Present_BonusPreview2[i]:Show();
				end
			end
			
			if sendBonus[nBonusRank].itemId3 > 0 then
				local theAction = DataPool:CreateActionItemForShow(sendBonus[nBonusRank].itemId3, 1);
				if theAction:GetID() ~= 0 then
					g_SeventhFestivalTopList_Present_BonusAction3[i]:SetActionItem(theAction:GetID())
					g_SeventhFestivalTopList_Present_BonusAction3[i]:Show();
				end
				if sendBonus[nBonusRank].preview == 3 then
					g_SeventhFestivalTopList_Present_BonusPreview3[i]:Show();
				end
			end
			
		end
	end
	
end

function SeventhFestivalTopList_Present_ShowSelfRank()
	
	g_SeventhFestivalTopList_SelfPresentRank = 0;
	local szSelfName = Player:GetName();
	local szSelfGuid = GetSelfGUID();
	local nSelfSendNum =  DataPool:GetPlayerMission_DataRound(g_SeventhFestivalTopList_Info[g_SeventhFestivalTopList_FlowerSubPage].sendmd)
	local sendBonus = g_SeventhFestivalTopList_SendBonus[g_SeventhFestivalTopList_FlowerSubPage];
	
	for i=1, g_SeventhFestivalTopList_Ranking_Count do		
		local index,name,score,isGetBonus,szGuid = DataPool:Lua_GetQixiSendTopListInfo(i-1)
		if index ~= nil and index >= 0 and szGuid ~= "" then
			if szGuid == szSelfGuid and nSelfSendNum == score then
				g_SeventhFestivalTopList_SelfPresentRank = i;
			end
		end
	end
	
	-- 玩家自己的送花信息
	if g_SeventhFestivalTopList_SelfPresentRank > 0 and SeventhFestivalTopList_RankingImage[g_SeventhFestivalTopList_SelfPresentRank] ~= nil then
		SeventhFestivalTopList_Present_Me_Top1_Num_Icon:SetProperty("Image", SeventhFestivalTopList_RankingImage[g_SeventhFestivalTopList_SelfPresentRank])
		SeventhFestivalTopList_Present_Me_Top1_Num_Icon:Show();
		SeventhFestivalTopList_Present_Me_Top1_Lost:Hide();
	else
		SeventhFestivalTopList_Present_Me_Top1_Lost:SetText( "#{QXLS_220517_53}" );
		SeventhFestivalTopList_Present_Me_Top1_Num_Icon:Hide();
		SeventhFestivalTopList_Present_Me_Top1_Lost:Show();
	end
	SeventhFestivalTopList_Present_Me_Top1_Name:SetText( ScriptGlobal_Format("#{QXLS_220517_12}", szSelfName ) );
	SeventhFestivalTopList_Present_Me_Top1_Count:SetText( ScriptGlobal_Format("#{QXLS_220517_13}", tostring(nSelfSendNum)) );
	SeventhFestivalTopList_Present_Me_Item_Button1:Hide();
	SeventhFestivalTopList_Present_Me_Item_Button2:Hide();
	SeventhFestivalTopList_Present_Me_Item_Button3:Hide();
	SeventhFestivalTopList_Present_Me_Item_Preview1:Hide();
	SeventhFestivalTopList_Present_Me_Item_Preview2:Hide();
	SeventhFestivalTopList_Present_Me_Item_Preview3:Hide();
	
	local nSelfPresentBonusRank = SeventhFestivalTopList_ConvertToBonusRank( g_SeventhFestivalTopList_SelfPresentRank )
	if sendBonus[nSelfPresentBonusRank] ~= nil then
		if sendBonus[nSelfPresentBonusRank].itemId1 > 0 then
			local theAction = DataPool:CreateActionItemForShow(sendBonus[nSelfPresentBonusRank].itemId1, 1);
			if theAction:GetID() ~= 0 then
				SeventhFestivalTopList_Present_Me_Item_Button1:SetActionItem(theAction:GetID())
				SeventhFestivalTopList_Present_Me_Item_Button1:Show();
			end
			if sendBonus[nSelfPresentBonusRank].preview == 1 then
				SeventhFestivalTopList_Present_Me_Item_Preview1:Show();
			end
		end
			
		if sendBonus[nSelfPresentBonusRank].itemId2 > 0 then
			local theAction = DataPool:CreateActionItemForShow(sendBonus[nSelfPresentBonusRank].itemId2, 1);
			if theAction:GetID() ~= 0 then
				SeventhFestivalTopList_Present_Me_Item_Button2:SetActionItem(theAction:GetID())
				SeventhFestivalTopList_Present_Me_Item_Button2:Show();
			end
			if sendBonus[nSelfPresentBonusRank].preview == 2 then
				SeventhFestivalTopList_Present_Me_Item_Preview2:Show();
			end
		end
		
		if sendBonus[nSelfPresentBonusRank].itemId3 > 0 then
			local theAction = DataPool:CreateActionItemForShow(sendBonus[nSelfPresentBonusRank].itemId3, 1);
			if theAction:GetID() ~= 0 then
				SeventhFestivalTopList_Present_Me_Item_Button3:SetActionItem(theAction:GetID())
				SeventhFestivalTopList_Present_Me_Item_Button3:Show();
			end
			if sendBonus[nSelfPresentBonusRank].preview == 3 then
				SeventhFestivalTopList_Present_Me_Item_Preview3:Show();
			end
		end
	end
end

function SeventhFestivalTopList_Receive_ShowRank()
	
--显示送花榜单
	local strDefName = SeventhFestivalTopList_Rank_DefaultName()
	local receiveBonus = g_SeventhFestivalTopList_ReceiveBonus[g_SeventhFestivalTopList_FlowerSubPage];
	SeventhFestivalTopList_Receive_CurrentlyPage:SetText( ScriptGlobal_Format("#{QXLS_220517_11}", g_SeventhFestivalTopList_ReceiveRanking_CurPage+1 ) );
	
--上一页
	if g_SeventhFestivalTopList_ReceiveRanking_CurPage > 0 then
		SeventhFestivalTopList_Receive_UpPage:Enable();
	else
		SeventhFestivalTopList_Receive_UpPage:Disable();
	end
	
--下一页
	if (g_SeventhFestivalTopList_ReceiveRanking_CurPage+1) * g_SeventhFestivalTopList_Ranking_CountPerPage < g_SeventhFestivalTopList_Ranking_Count then
		SeventhFestivalTopList_Receive_DownPage:Enable();
	else
		SeventhFestivalTopList_Receive_DownPage:Disable();
	end
	SeventhFestivalTopList_Ranking_GetAward2:SetToolTip( g_SeventhFestivalTopList_Info[g_SeventhFestivalTopList_FlowerSubPage].szReceiveBonusTip )  
	
	for i=1, g_SeventhFestivalTopList_Ranking_CountPerPage do
		local nRank = g_SeventhFestivalTopList_Ranking_CountPerPage * g_SeventhFestivalTopList_ReceiveRanking_CurPage + i;
	
		g_SeventhFestivalTopList_Receive_Num[i]:SetProperty("Image", SeventhFestivalTopList_RankingImage[nRank])
		
		--更新数据
		local index,name,score,isGetBonus,szGuid = DataPool:Lua_GetQixiReceiveTopListInfo(nRank-1)
		if index ~= nil and index >= 0 and name ~= "" then
			g_SeventhFestivalTopList_Receive_Name[i]:SetText( ScriptGlobal_Format("#{QXLS_220517_12}", name ) )
			local scoreStr = ScriptGlobal_Format("#{QXLS_220517_13}", tostring(score))
			g_SeventhFestivalTopList_Receive_Score[i]:SetText(scoreStr)
		else
			--初始化默认值
			g_SeventhFestivalTopList_Receive_Name[i]:SetText(strDefName)--“虚位以待”或者“未能决出”
			local scoreStr = ScriptGlobal_Format("#{QXLS_220517_13}", " ")
			g_SeventhFestivalTopList_Receive_Score[i]:SetText(scoreStr)
		end
		
		--奖励
		local nBonusRank = SeventhFestivalTopList_ConvertToBonusRank( nRank )
		if receiveBonus[nBonusRank] ~= nil then
			if receiveBonus[nBonusRank].itemId1 > 0 then
				local theAction = DataPool:CreateActionItemForShow(receiveBonus[nBonusRank].itemId1, 1);
				if theAction:GetID() ~= 0 then
					g_SeventhFestivalTopList_Receive_BonusAction1[i]:SetActionItem(theAction:GetID())
					g_SeventhFestivalTopList_Receive_BonusAction1[i]:Show();
				end
				
				if receiveBonus[nBonusRank].preview == 1 then
					g_SeventhFestivalTopList_Receive_BonusPreview1[i]:Show();
				end
			end
			
			if receiveBonus[nBonusRank].itemId2 > 0 then
				local theAction = DataPool:CreateActionItemForShow(receiveBonus[nBonusRank].itemId2, 1);
				if theAction:GetID() ~= 0 then
					g_SeventhFestivalTopList_Receive_BonusAction2[i]:SetActionItem(theAction:GetID())
					g_SeventhFestivalTopList_Receive_BonusAction2[i]:Show();
				end
				
				if receiveBonus[nBonusRank].preview == 2 then
					g_SeventhFestivalTopList_Receive_BonusPreview2[i]:Show();
				end
			end
			
			if receiveBonus[nBonusRank].itemId3 > 0 then
				local theAction = DataPool:CreateActionItemForShow(receiveBonus[nBonusRank].itemId3, 1);
				if theAction:GetID() ~= 0 then
					g_SeventhFestivalTopList_Receive_BonusAction3[i]:SetActionItem(theAction:GetID())
					g_SeventhFestivalTopList_Receive_BonusAction3[i]:Show();
				end
				
				if receiveBonus[nBonusRank].preview == 3 then
					g_SeventhFestivalTopList_Receive_BonusPreview3[i]:Show();
				end
			end
			
		end
		
	end
	
end

function SeventhFestivalTopList_Receive_ShowSelfRank()
	
	g_SeventhFestivalTopList_SelfReceiveRank = 0;
	local szSelfName = Player:GetName();
	local szSelfGuid = GetSelfGUID();
	local nSelfReceiveNum = DataPool:GetPlayerMission_DataRound(g_SeventhFestivalTopList_Info[g_SeventhFestivalTopList_FlowerSubPage].receivemd)
	local receiveBonus = g_SeventhFestivalTopList_ReceiveBonus[g_SeventhFestivalTopList_FlowerSubPage];

	for i=1, g_SeventhFestivalTopList_Ranking_Count do
		
		local index,name,score,isGetBonus,szGuid = DataPool:Lua_GetQixiReceiveTopListInfo(i-1)
		if index ~= nil and index >= 0 and szGuid ~= "" then
			if szGuid == szSelfGuid and nSelfReceiveNum == score then
				g_SeventhFestivalTopList_SelfReceiveRank = i;
			end
		end
	end
	
	-- 玩家自己的收花信息
	if g_SeventhFestivalTopList_SelfReceiveRank > 0 and SeventhFestivalTopList_RankingImage[g_SeventhFestivalTopList_SelfReceiveRank] ~= nil then
		SeventhFestivalTopList_Receive_Me_Top1_Num_Icon:SetProperty("Image", SeventhFestivalTopList_RankingImage[g_SeventhFestivalTopList_SelfReceiveRank])
		SeventhFestivalTopList_Receive_Me_Top1_Num_Icon:Show();
		SeventhFestivalTopList_Receive_Me_Top1_Lost:Hide();
	else
		SeventhFestivalTopList_Receive_Me_Top1_Lost:SetText( "#{QXLS_220517_53}" );
		SeventhFestivalTopList_Receive_Me_Top1_Num_Icon:Hide();
		SeventhFestivalTopList_Receive_Me_Top1_Lost:Show();
	end

	SeventhFestivalTopList_Receive_Me_Top1_Name:SetText( ScriptGlobal_Format("#{QXLS_220517_12}", szSelfName ) );
	SeventhFestivalTopList_Receive_Me_Top1_Count:SetText( ScriptGlobal_Format("#{QXLS_220517_13}", tostring(nSelfReceiveNum)) );
	SeventhFestivalTopList_Receive_Me_Item_Button1:Hide();
	SeventhFestivalTopList_Receive_Me_Item_Button2:Hide();
	SeventhFestivalTopList_Receive_Me_Item_Button3:Hide();
	SeventhFestivalTopList_Receive_Me_Item_Preview1:Hide();
	SeventhFestivalTopList_Receive_Me_Item_Preview2:Hide();
	SeventhFestivalTopList_Receive_Me_Item_Preview3:Hide();
	
	local nSelfReceiveBonusRank = SeventhFestivalTopList_ConvertToBonusRank( g_SeventhFestivalTopList_SelfReceiveRank )
	if receiveBonus[nSelfReceiveBonusRank] ~= nil then
		if receiveBonus[nSelfReceiveBonusRank].itemId1 > 0 then
			local theAction = DataPool:CreateActionItemForShow(receiveBonus[nSelfReceiveBonusRank].itemId1, 1);
			if theAction:GetID() ~= 0 then
				SeventhFestivalTopList_Receive_Me_Item_Button1:SetActionItem(theAction:GetID())
				SeventhFestivalTopList_Receive_Me_Item_Button1:Show();
			end
			if receiveBonus[nSelfReceiveBonusRank].preview == 1 then
				SeventhFestivalTopList_Receive_Me_Item_Preview1:Show();
			end
		end
			
		if receiveBonus[nSelfReceiveBonusRank].itemId2 > 0 then
			local theAction = DataPool:CreateActionItemForShow(receiveBonus[nSelfReceiveBonusRank].itemId2, 1);
			if theAction:GetID() ~= 0 then
				SeventhFestivalTopList_Receive_Me_Item_Button2:SetActionItem(theAction:GetID())
				SeventhFestivalTopList_Receive_Me_Item_Button2:Show();
			end
			if receiveBonus[nSelfReceiveBonusRank].preview == 2 then
				SeventhFestivalTopList_Receive_Me_Item_Preview2:Show();
			end
		end
		
		if receiveBonus[nSelfReceiveBonusRank].itemId3 > 0 then
			local theAction = DataPool:CreateActionItemForShow(receiveBonus[nSelfReceiveBonusRank].itemId3, 1);
			if theAction:GetID() ~= 0 then
				SeventhFestivalTopList_Receive_Me_Item_Button3:SetActionItem(theAction:GetID())
				SeventhFestivalTopList_Receive_Me_Item_Button3:Show();
			end
			if receiveBonus[nSelfReceiveBonusRank].preview == 3 then
				SeventhFestivalTopList_Receive_Me_Item_Preview3:Show();
			end
		end
		
	end
end


--预览奖励
function SeventhFestivalTopList_Present_OnPreview( nType, index )

	--有效性判断
	if g_SeventhFestivalTopList_CurPage ~= 1 then
		return
	end
	if g_SeventhFestivalTopList_FlowerSubPage < 1 or g_SeventhFestivalTopList_FlowerSubPage > 3 then
		return
	end
	
	if nType ~= 1 and nType ~= 2 and nType ~= 3 then
		return
	end
	
	if index < 1 or index > 5 then
		return
	end
	
	local sendBonus = g_SeventhFestivalTopList_SendBonus[g_SeventhFestivalTopList_FlowerSubPage];
	local nRank = g_SeventhFestivalTopList_Ranking_CountPerPage * g_SeventhFestivalTopList_PresentRanking_CurPage + index;
	if nRank < 1 or nRank > g_SeventhFestivalTopList_Ranking_Count then
		return
	end
	
	local nBonusRank = SeventhFestivalTopList_ConvertToBonusRank( nRank )
	local nBonusId = -1;
	if sendBonus[nBonusRank].preview == 1 then
		nBonusId = sendBonus[nBonusRank].itemId1
	elseif sendBonus[nBonusRank].preview == 2 then
		nBonusId = sendBonus[nBonusRank].itemId2
	elseif sendBonus[nBonusRank].preview == 3 then
		nBonusId = sendBonus[nBonusRank].itemId3
	end
	
	if g_SeventhFestivalTopList_PreviewInfo[nBonusId] == nil then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, g_SeventhFestivalTopList_PreviewInfo[nBonusId].dressId )
		Set_XSCRIPT_Parameter(1, g_SeventhFestivalTopList_PreviewInfo[nBonusId].hairId )
		Set_XSCRIPT_Parameter(2, g_SeventhFestivalTopList_PreviewInfo[nBonusId].faceId )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

end

function SeventhFestivalTopList_Receive_OnPreview( nType, index )
	--有效性判断
	if g_SeventhFestivalTopList_CurPage ~= 1 then
		return
	end
	if g_SeventhFestivalTopList_FlowerSubPage < 1 or g_SeventhFestivalTopList_FlowerSubPage > 3 then
		return
	end
	
	if nType ~= 1 and nType ~= 2 and nType ~= 3 then
		return
	end
	
	if index < 1 or index > 5 then
		return
	end
	
	local receiveBonus = g_SeventhFestivalTopList_ReceiveBonus[g_SeventhFestivalTopList_FlowerSubPage];
	local nRank = g_SeventhFestivalTopList_Ranking_CountPerPage * g_SeventhFestivalTopList_ReceiveRanking_CurPage + index;
	if nRank < 1 or nRank > g_SeventhFestivalTopList_Ranking_Count then
		return
	end
	
	local nBonusRank = SeventhFestivalTopList_ConvertToBonusRank( nRank )
	local nBonusId = -1;
	if receiveBonus[nBonusRank].preview == 1 then
		nBonusId = receiveBonus[nBonusRank].itemId1
	elseif receiveBonus[nBonusRank].preview == 2 then
		nBonusId = receiveBonus[nBonusRank].itemId2
	elseif receiveBonus[nBonusRank].preview == 3 then
		nBonusId = receiveBonus[nBonusRank].itemId3
	end
	
	if g_SeventhFestivalTopList_PreviewInfo[nBonusId] == nil then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, g_SeventhFestivalTopList_PreviewInfo[nBonusId].dressId )
		Set_XSCRIPT_Parameter(1, g_SeventhFestivalTopList_PreviewInfo[nBonusId].hairId )
		Set_XSCRIPT_Parameter(2, g_SeventhFestivalTopList_PreviewInfo[nBonusId].faceId )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

end

function SeventhFestivalTopList_Present_OnSelfPreview( nType )
	--有效性判断
	if g_SeventhFestivalTopList_CurPage ~= 1 then
		return
	end
	if g_SeventhFestivalTopList_FlowerSubPage < 1 or g_SeventhFestivalTopList_FlowerSubPage > 3 then
		return
	end
	
	if nType ~= 1 and nType ~= 2 and nType ~= 3 then
		return
	end
	
	local sendBonus = g_SeventhFestivalTopList_SendBonus[g_SeventhFestivalTopList_FlowerSubPage];
	if g_SeventhFestivalTopList_SelfPresentRank < 1 or g_SeventhFestivalTopList_SelfPresentRank > g_SeventhFestivalTopList_Ranking_Count then
		return
	end
	
	local nBonusRank = SeventhFestivalTopList_ConvertToBonusRank( g_SeventhFestivalTopList_SelfPresentRank )
	local nBonusId = -1;
	if sendBonus[nBonusRank].preview == 1 then
		nBonusId = sendBonus[nBonusRank].itemId1
	elseif sendBonus[nBonusRank].preview == 2 then
		nBonusId = sendBonus[nBonusRank].itemId2
	elseif sendBonus[nBonusRank].preview == 3 then
		nBonusId = sendBonus[nBonusRank].itemId3
	end
	
	if g_SeventhFestivalTopList_PreviewInfo[nBonusId] == nil then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, g_SeventhFestivalTopList_PreviewInfo[nBonusId].dressId )
		Set_XSCRIPT_Parameter(1, g_SeventhFestivalTopList_PreviewInfo[nBonusId].hairId )
		Set_XSCRIPT_Parameter(2, g_SeventhFestivalTopList_PreviewInfo[nBonusId].faceId )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function SeventhFestivalTopList_Receive_OnSelfPreview( nType )
	--有效性判断
	if g_SeventhFestivalTopList_CurPage ~= 1 then
		return
	end
	if g_SeventhFestivalTopList_FlowerSubPage < 1 or g_SeventhFestivalTopList_FlowerSubPage > 3 then
		return
	end
	
	if nType ~= 1 and nType ~= 2 and nType ~= 3 then
		return
	end
	
	local receiveBonus = g_SeventhFestivalTopList_ReceiveBonus[g_SeventhFestivalTopList_FlowerSubPage];
	if g_SeventhFestivalTopList_SelfReceiveRank < 1 or g_SeventhFestivalTopList_SelfReceiveRank > g_SeventhFestivalTopList_Ranking_Count then
		return
	end
	
	local nBonusRank = SeventhFestivalTopList_ConvertToBonusRank( g_SeventhFestivalTopList_SelfReceiveRank )
	local nBonusId = -1;
	if receiveBonus[nBonusRank].preview == 1 then
		nBonusId = receiveBonus[nBonusRank].itemId1
	elseif receiveBonus[nBonusRank].preview == 2 then
		nBonusId = receiveBonus[nBonusRank].itemId2
	elseif receiveBonus[nBonusRank].preview == 3 then
		nBonusId = receiveBonus[nBonusRank].itemId3
	end
	
	if g_SeventhFestivalTopList_PreviewInfo[nBonusId] == nil then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, g_SeventhFestivalTopList_PreviewInfo[nBonusId].dressId )
		Set_XSCRIPT_Parameter(1, g_SeventhFestivalTopList_PreviewInfo[nBonusId].hairId )
		Set_XSCRIPT_Parameter(2, g_SeventhFestivalTopList_PreviewInfo[nBonusId].faceId )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function SeventhFestivalTopList_QingRenJie_OnPreview(index)
	if g_SeventhFestivalTopList_Qingrenjie_Bonus[index] == nil then
		return
	end
	
	local nBonusId = g_SeventhFestivalTopList_Qingrenjie_Bonus[index].itemid;
	if nBonusId == nil then
		return
	end
	
	if g_SeventhFestivalTopList_PreviewInfo[nBonusId] == nil then
		return
	end
	
	local nDressId = g_SeventhFestivalTopList_PreviewInfo[nBonusId].dressId
	local nHairId = g_SeventhFestivalTopList_PreviewInfo[nBonusId].hairId
	local nFaceId = g_SeventhFestivalTopList_PreviewInfo[nBonusId].faceId
	
	PushEvent("OPEN_DRESSPREVIEW", nDressId, nHairId, nFaceId) --时装\发型\脸型

end

--刷新榜单
function SeventhFestivalTopList_Ranking_OnUpdate()

	--有效性判断
	if g_SeventhFestivalTopList_CurPage ~= 1 then
		return
	end
	if g_SeventhFestivalTopList_FlowerSubPage < 1 or g_SeventhFestivalTopList_FlowerSubPage > 3 then
		return
	end
	
	SeventhFestivalTopList_RankClick_Refresh(g_SeventhFestivalTopList_FlowerSubPage)
	
end

--显示累计奖励
function SeventhFestivalTopList_LeiJiAward_Update()

	local nAllSendNum = DataPool:GetPlayerMission_DataRound(g_SeventhFestivalTopList_LeiJi_SendMD);
		
	for i=1, table.getn(SeventhFestivalTopList_LeiJi_Bonus) do
		g_SeventhFestivalTopList_LeiJi_Text1[i]:SetText( ScriptGlobal_Format("#{QXLS_220517_42}", SeventhFestivalTopList_LeiJi_Bonus[i].need) );
		if nAllSendNum >= SeventhFestivalTopList_LeiJi_Bonus[i].need then
			local szText = ScriptGlobal_Format( "#{QXLS_220517_44}", tostring(SeventhFestivalTopList_LeiJi_Bonus[i].need), tostring(SeventhFestivalTopList_LeiJi_Bonus[i].need) )
			g_SeventhFestivalTopList_LeiJi_Text2[i]:SetText( szText );	
			if Pneuma:GetMF(SeventhFestivalTopList_LeiJi_Bonus[i].MF) == 0 then
				g_SeventhFestivalTopList_LeiJi_Button[i]:Show();
				g_SeventhFestivalTopList_LeiJi_Tips[i]:Show();
				g_SeventhFestivalTopList_LeiJi_Image[i]:Hide();
			else
				g_SeventhFestivalTopList_LeiJi_Button[i]:Hide();
				g_SeventhFestivalTopList_LeiJi_Tips[i]:Hide();
				g_SeventhFestivalTopList_LeiJi_Image[i]:Show();
			end
		else
			local szText = ScriptGlobal_Format( "#{QXLS_220517_43}", tostring(nAllSendNum), tostring(SeventhFestivalTopList_LeiJi_Bonus[i].need) )
			g_SeventhFestivalTopList_LeiJi_Text2[i]:SetText( szText );	
				g_SeventhFestivalTopList_LeiJi_Button[i]:Show();
				g_SeventhFestivalTopList_LeiJi_Tips[i]:Hide();
				g_SeventhFestivalTopList_LeiJi_Image[i]:Hide();
		end
		
		
		local theAction = DataPool:CreateActionItemForShow(SeventhFestivalTopList_LeiJi_Bonus[i].itemId, 1)
		if theAction:GetID() ~= 0 then
			g_SeventhFestivalTopList_LeiJi_Action[i]:SetActionItem(theAction:GetID())
			if SeventhFestivalTopList_LeiJi_Bonus[i].count > 1 then
				g_SeventhFestivalTopList_LeiJi_Text3[i]:SetText( "#e010101#cFFFFFF"..tostring(SeventhFestivalTopList_LeiJi_Bonus[i].count) );	
			else
				g_SeventhFestivalTopList_LeiJi_Text3[i]:Hide()
			end
		end
	end
	
end

function SeventhFestivalTopList_LeiJiAward_OnClicked( index )

	local nCooldown = g_SeventhFestivalTopList_Cooldown[6]
	local iCur = FindFriendDataPool:GetTickCount()
	if ( iCur - nCooldown < 1) then
		PushDebugMessage("#{QXLS_150724_01}")
		return 0
	end
	g_SeventhFestivalTopList_Cooldown[6] = iCur
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "QiXiLeiJi_Exchange" )
		Set_XSCRIPT_ScriptID( 891396 )
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

--显示小红点
function SeventhFestivalTopList_Rank_ShowRedPoint()

	local szSelfName = Player:GetName();
	local presentRedpoint = {[1]=0,[2]=0,[3]=0,};
	local receiveRedpoint = {[1]=0,[2]=0,[3]=0,};
		
	-- 花榜
	for i=1, 3 do		
	--送花
		if DataPool:Lua_GetQixiIsHaveBonus( (i-1)*2 ) > 0 then
			presentRedpoint[i] = 1;
		end		
	--收花
		if DataPool:Lua_GetQixiIsHaveBonus( (i-1)*2 + 1 ) > 0 then
			receiveRedpoint[i] = 1;
		end
	end
	
	-- 当前页面小红点
	if g_SeventhFestivalTopList_CurPage == 1 then
		if presentRedpoint[g_SeventhFestivalTopList_FlowerSubPage] ~= nil and presentRedpoint[g_SeventhFestivalTopList_FlowerSubPage] == 1 then
			SeventhFestivalTopList_Ranking_GetAward1_Tips:Show();
		else
			SeventhFestivalTopList_Ranking_GetAward1_Tips:Hide();
		end			
		
		if receiveRedpoint[g_SeventhFestivalTopList_FlowerSubPage] ~= nil and receiveRedpoint[g_SeventhFestivalTopList_FlowerSubPage] == 1 then
			SeventhFestivalTopList_Ranking_GetAward2_Tips:Show();
		else
			SeventhFestivalTopList_Ranking_GetAward2_Tips:Hide();
		end
	end
	
	-- 标题小红点
	local bFlowerPoint = 0
	for i=1, 3 do
		if (presentRedpoint[i] ~= nil and presentRedpoint[i] == 1) or 
			(receiveRedpoint[i] ~= nil and receiveRedpoint[i] == 1 ) then
			g_SeventhFestivalTopList_Btn_FlowerPage_Redpoint[i]:Show();
			bFlowerPoint = 1;
		else
			g_SeventhFestivalTopList_Btn_FlowerPage_Redpoint[i]:Hide();
		end
	end	
	if bFlowerPoint == 1 then
		SeventhFestivalTopList_Top_TopList1_Tips:Show();
	else
		SeventhFestivalTopList_Top_TopList1_Tips:Hide();
	end
	
	-- 兑换页面
	SeventhFestivalTopList_Ranking_Chiqing_Tips:Hide();
	SeventhFestivalTopList_Ranking_Qingren_Tips:Hide();
	SeventhFestivalTopList_Ranking_Xiangsijie_Tips:Hide();
	SeventhFestivalTopList_Top_TopList2_Tips:Hide();

	-- 累计奖励
	SeventhFestivalTopList_Top_TopList3_Tips:Hide();
	local nAllSendNum = DataPool:GetPlayerMission_DataRound(g_SeventhFestivalTopList_LeiJi_SendMD);
	for i=1, table.getn(SeventhFestivalTopList_LeiJi_Bonus) do
		if nAllSendNum >= SeventhFestivalTopList_LeiJi_Bonus[i].need then
			if Pneuma:GetMF(SeventhFestivalTopList_LeiJi_Bonus[i].MF) == 0 then
				SeventhFestivalTopList_Top_TopList3_Tips:Show();
				break
			end
		end
	end
end

--显示默认的名字
function SeventhFestivalTopList_Rank_DefaultName()
	local strMsg=""
	
	if g_SeventhFestivalTopList_State < 6 then 
		strMsg = "#{QXLS_150724_21}"
	elseif g_SeventhFestivalTopList_State >= 6 then 
		strMsg = "#{QXLS_150724_22}"	
	end
		
	return strMsg
end

--===============================================
-- 以下为事件响应
--===============================================
--点击关闭
function SeventhFestivalTopList_Close_Click()
	--数据清空
	SeventhFestivalTopList_Clear()
	--界面隐藏
	this:Hide()
end

--点击页签
function SeventhFestivalTopList_Page_Click(index)

--有效性判断
	if index <= 0 or index > g_SeventhFestivalTopList_MaxPage then
		return
	end
	
	local nPage = g_SeventhFestivalTopList_CurPage
	g_SeventhFestivalTopList_CurPage = index
	
--页面内容更新 1标示排行榜；2标识兑换；3标识累计奖励；
	if g_SeventhFestivalTopList_CurPage == 1 then
		SeventhFestivalTopList_Ranking_Frame:Show()	
		SeventhFestivalTopList_Exchange_Client:Hide()
		SeventhFestivalTopList_Leiji_Client:Hide()
		
		--打开默认页面
		SeventhFestivalTopList_RankClick_Refresh(0); 
		
	elseif g_SeventhFestivalTopList_CurPage == 2 then
	
		SeventhFestivalTopList_Ranking_Frame:Hide()	
		SeventhFestivalTopList_Exchange_Client:Show()
		SeventhFestivalTopList_Leiji_Client:Hide()
	
		--打开情人结页面
		SeventhFestivalTopList_Exchange_Qingrenjie_Update()
		
	elseif g_SeventhFestivalTopList_CurPage == 3 then
	
		SeventhFestivalTopList_Ranking_Frame:Hide()	
		SeventhFestivalTopList_Exchange_Client:Hide()
		SeventhFestivalTopList_Leiji_Client:Show()
		
		SeventhFestivalTopList_LeiJiAward_Update();
	end
end

--点击刷新
function SeventhFestivalTopList_RankClick_Refresh(index)
	
--有效性判断
	if g_SeventhFestivalTopList_CurPage ~= 1 then
		return 0
	end	
	if index == nil or index < 0 or index > 3 then
		return 0
	end
	
	for i=1, 3 do
		if i ~= index then
			g_SeventhFestivalTopList_Btn_FlowerPage[i]:SetCheck(0);
		end
	end
	
	if index > 0 then
		g_SeventhFestivalTopList_FlowerSubPage = index
		--判断冷却时间
		local nCooldown = g_SeventhFestivalTopList_Cooldown[g_SeventhFestivalTopList_FlowerSubPage]
		local iCur = FindFriendDataPool:GetTickCount()
		if ( iCur - nCooldown < g_SeventhFestivalTopList_CooldownDur) then
			PushDebugMessage("#{QXLS_150724_01}")
			return 0
		end
		g_SeventhFestivalTopList_Cooldown[g_SeventhFestivalTopList_FlowerSubPage] = iCur
	end
	
	--请求服务器数据
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientAskQixiTopList" )
		Set_XSCRIPT_ScriptID( 891396 )
		Set_XSCRIPT_Parameter(0,index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
	return 1
end

--送花点击预览
function SeventhFestivalTopList_Present_Zhanshi(index)
	--参数判断
	if index < 1 or index > 3 then
		return
	end
	--显示预览界面
	PushEvent("OPEN_QIXITOPLIST_ZHANSHI",index, g_SeventhFestivalTopList_FlowerSubPage, 1)
end

--收花点击预览
function SeventhFestivalTopList_Receive_Zhanshi(index)
	--参数判断
	if index < 1 or index > 3 then
		return
	end
	--显示预览界面
	PushEvent("OPEN_QIXITOPLIST_ZHANSHI",index, g_SeventhFestivalTopList_FlowerSubPage, 2)
end

--点击送花榜领奖
function SeventhFestivalTopList_Prize_Present()
	
--有效性判断
	if g_SeventhFestivalTopList_CurPage ~= 1 then
		return
	end	
	if g_SeventhFestivalTopList_FlowerSubPage < 1 or g_SeventhFestivalTopList_FlowerSubPage > 3 then
		return
	end	
		
--判断领奖时间
	if g_SeventhFestivalTopList_State == 0 then--理论上不存在
		PushDebugMessage(g_SeventhFestivalTopList_Tip[g_SeventhFestivalTopList_FlowerSubPage].tip1)
		return
	elseif g_SeventhFestivalTopList_State >= 1 and g_SeventhFestivalTopList_State <= 5 then--排行榜计时中
		PushDebugMessage(g_SeventhFestivalTopList_Tip[g_SeventhFestivalTopList_FlowerSubPage].tip2)
		return
	elseif g_SeventhFestivalTopList_State == 6 then--可以领奖
	else--理论上不存在
		PushDebugMessage(g_SeventhFestivalTopList_Tip[g_SeventhFestivalTopList_FlowerSubPage].tip3)
		return
	end
		
--判断安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{QRPHB_150113_105}")--在安全时间内无法进行此操作。打开包裹栏，点击防盗号按钮可以自行设置安全时间。
		return
	end
	
--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then	
		return
	end
  
	--参数判断
	if g_SeventhFestivalTopList_SelfPresentRank < 1 or g_SeventhFestivalTopList_SelfPresentRank > g_SeventhFestivalTopList_Ranking_Count then
		PushDebugMessage("#{QXLS_150724_75}")
		return
	end
	
	--领奖
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientGetQixiSendTopListPrize" )
		Set_XSCRIPT_ScriptID( 891396 )
		Set_XSCRIPT_Parameter(0, g_SeventhFestivalTopList_FlowerSubPage)
		Set_XSCRIPT_Parameter(1, g_SeventhFestivalTopList_SelfPresentRank)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

end

--点击收花榜领奖
function SeventhFestivalTopList_Prize_Receive()
	
--有效性判断
	if g_SeventhFestivalTopList_CurPage ~= 1 then
		return
	end	
	if g_SeventhFestivalTopList_FlowerSubPage < 1 or g_SeventhFestivalTopList_FlowerSubPage > 3 then
		return
	end	
		
--判断领奖时间
	if g_SeventhFestivalTopList_State == 0 then--理论上不存在
		PushDebugMessage(g_SeventhFestivalTopList_Tip[g_SeventhFestivalTopList_FlowerSubPage].tip1)
		return
	elseif g_SeventhFestivalTopList_State >= 1 and g_SeventhFestivalTopList_State <= 5 then--排行榜计时中
		PushDebugMessage(g_SeventhFestivalTopList_Tip[g_SeventhFestivalTopList_FlowerSubPage].tip2)
		return
	elseif g_SeventhFestivalTopList_State == 6 then--可以领奖
	else--理论上不存在
		PushDebugMessage(g_SeventhFestivalTopList_Tip[g_SeventhFestivalTopList_FlowerSubPage].tip3)
		return
	end
	
--判断安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{QRPHB_150113_105}")--在安全时间内无法进行此操作。打开包裹栏，点击防盗号按钮可以自行设置安全时间。
		return
	end
	
--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then	
		return
	end
  
	if g_SeventhFestivalTopList_SelfReceiveRank < 1 or g_SeventhFestivalTopList_SelfReceiveRank > g_SeventhFestivalTopList_Ranking_Count then
		PushDebugMessage("#{QXLS_150724_75}")
		return
	end
	
	--领奖
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientGetQixiReceiveTopListPrize" )
		Set_XSCRIPT_ScriptID( 891396 )
		Set_XSCRIPT_Parameter(0, g_SeventhFestivalTopList_FlowerSubPage)
		Set_XSCRIPT_Parameter(1, g_SeventhFestivalTopList_SelfReceiveRank)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

end

--送花榜上一页
function SeventhFestivalTopList_Present_PageUp()
	if g_SeventhFestivalTopList_PresentRanking_CurPage > 0 then
		g_SeventhFestivalTopList_PresentRanking_CurPage = g_SeventhFestivalTopList_PresentRanking_CurPage - 1;
	end
	
	SeventhFestivalTopList_Rank_ShowTopListPage()
end

--送花榜下一页
function SeventhFestivalTopList_Present_PageDown()
	if (g_SeventhFestivalTopList_PresentRanking_CurPage+1) * g_SeventhFestivalTopList_Ranking_CountPerPage < g_SeventhFestivalTopList_Ranking_Count then
		g_SeventhFestivalTopList_PresentRanking_CurPage = g_SeventhFestivalTopList_PresentRanking_CurPage + 1
	end 
	
	SeventhFestivalTopList_Rank_ShowTopListPage();
end

--收花榜上一页
function SeventhFestivalTopList_Receive_PageUp()
	if g_SeventhFestivalTopList_ReceiveRanking_CurPage > 0 then
		g_SeventhFestivalTopList_ReceiveRanking_CurPage = g_SeventhFestivalTopList_ReceiveRanking_CurPage - 1;
	end
	
	SeventhFestivalTopList_Rank_ShowTopListPage();
end

--收花榜下一页
function SeventhFestivalTopList_Receive_PageDown()
	if (g_SeventhFestivalTopList_ReceiveRanking_CurPage+1) * g_SeventhFestivalTopList_Ranking_CountPerPage < g_SeventhFestivalTopList_Ranking_Count then
		g_SeventhFestivalTopList_ReceiveRanking_CurPage = g_SeventhFestivalTopList_ReceiveRanking_CurPage + 1
	end 
	
	SeventhFestivalTopList_Rank_ShowTopListPage();
end

--===============================================
-- 以下为基础函数
--===============================================
--状态清空
function SeventhFestivalTopList_Clear()

 	--当前页码清空
	g_SeventhFestivalTopList_CurPage = 0
	g_SeventhFestivalTopList_FlowerSubPage = 0
	g_SeventhFestivalTopList_ExchangeSubPage = 0
	--活动状态清空
	g_SeventhFestivalTopList_State = -1
	
end

--重置位置
function SeventhFestivalTopList_ResetPos()
	SeventhFestivalTopList_Frame:SetProperty("UnifiedPosition",g_SeventhFestivalTopList_UnifiedPosition)
end

--===============================================
-- 以下为兑换奖励
--===============================================
function SeventhFestivalTopList_Exchange_UpdateQingRenJieCount()

	local nQingRenJieCount = DataPool:GetPlayerMission_DataRound(g_SeventhFestivalTopList_QingRenJie)
	local strQingRenJie = ScriptGlobal_Format("#{QXLS_20210702_03}", nQingRenJieCount)
	SeventhFestivalTopList_Exchange_ZongText:SetText( strQingRenJie )
	
end

function SeventhFestivalTopList_Exchange_UpdateChiqingyuCount()

	local nChiQingYuCount = DataPool:GetPlayerMission_DataRound(g_SeventhFestivalTopList_ChiQingYu)
	local strChiqingyu = ScriptGlobal_Format("#{QXLS_20210702_04}", nChiQingYuCount)
	SeventhFestivalTopList_Exchange_ZongText2:SetText( strChiqingyu )
	
end

function SeventhFestivalTopList_Exchange_UpdateXiangSiJieCount()

	local nXiangSiJieCount = DataPool:GetPlayerMission_DataRound(g_SeventhFestivalTopList_XiangSiJie)
	local strXiangSiJie = ScriptGlobal_Format("#{QXLS_240704_43}", nXiangSiJieCount)
	SeventhFestivalTopList_Exchange_ZongText1:SetText( strXiangSiJie )
	
end

--情人结兑换奖励窗口
function SeventhFestivalTopList_Exchange_Qingrenjie_Update()

	g_SeventhFestivalTopList_ExchangeSubPage = 0;
	
	SeventhFestivalTopList_Exchange_GiftFrame:Show()
	SeventhFestivalTopList_Exchange_GiftFrame1:Hide()
	SeventhFestivalTopList_Exchange_GiftFrame2:Hide()
	
	SeventhFestivalTopList_Ranking_Chiqing:SetCheck(0);
	SeventhFestivalTopList_Ranking_Qingren:SetCheck(1);
	SeventhFestivalTopList_Ranking_Xiangsijie:SetCheck(0);
			
	SeventhFestivalTopList_Exchange_Info:SetText( "#{QXLS_150724_101}" )
	SeventhFestivalTopList_Exchange_UpdateQingRenJieCount()
	
	for i = 1, table.getn(SeventhFestivalTopList_Exchange_Qingrenjie_BK) do
		SeventhFestivalTopList_Exchange_Qingrenjie_BK[i]:Hide()
	end
		
	for i = 1, table.getn(g_SeventhFestivalTopList_Qingrenjie_Bonus) do
		SeventhFestivalTopList_Exchange_Qingrenjie_BK[i]:Show()
		
		local theAction = DataPool:CreateActionItemForShow(g_SeventhFestivalTopList_Qingrenjie_Bonus[i].itemid, g_SeventhFestivalTopList_Qingrenjie_Bonus[i].count)
		if theAction:GetID() ~= 0 then
			SeventhFestivalTopList_Exchange_Qingrenjie_Action[i]:SetActionItem(theAction:GetID())
		end
		
		local strName = ScriptGlobal_Format("#{QXLS_220517_54}", g_SeventhFestivalTopList_Qingrenjie_Bonus[i].name)
		SeventhFestivalTopList_Exchange_Qingrenjie_Name[i]:SetText( strName )
		
		local strText = ScriptGlobal_Format("#{QXLS_150724_103}", g_SeventhFestivalTopList_Qingrenjie_Bonus[i].neednum)
		local strTips = ScriptGlobal_Format("#{QXLS_150724_104}", g_SeventhFestivalTopList_Qingrenjie_Bonus[i].neednum, g_SeventhFestivalTopList_Qingrenjie_Bonus[i].name)
		SeventhFestivalTopList_Exchange_Qingrenjie_Text[i]:SetText( strText )
		SeventhFestivalTopList_Exchange_Qingrenjie_Text[i]:SetToolTip( strTips )
		
		if SeventhFestivalTopList_Exchange_Qingrenjie_Preview[i] ~= nil then
			if g_SeventhFestivalTopList_Qingrenjie_Bonus[i].IsShow == 1 then
				SeventhFestivalTopList_Exchange_Qingrenjie_Preview[i]:Show()
			else
				SeventhFestivalTopList_Exchange_Qingrenjie_Preview[i]:Hide()
			end
		end		
	end
	
	SeventhFestivalTopList_Qingrenjie_UpdateLimit()
	
	--SeventhFestivalTopList_Qingrenjie_ShowBonus( 1 )
	
end

function SeventhFestivalTopList_Qingrenjie_UpdateLimit()

	for i = 1, table.getn(g_SeventhFestivalTopList_Qingrenjie_Bonus) do
		if SeventhFestivalTopList_Exchange_Qingrenjie_Limit[i] ~= nil and SeventhFestivalTopList_Exchange_Qingrenjie_Mask[i] ~= nil then
			local nLimitNum = g_SeventhFestivalTopList_Qingrenjie_Bonus[i].limitnum
			local nLimitMD = g_SeventhFestivalTopList_Qingrenjie_Bonus[i].LimitMD
			if nLimitMD > 0 and nLimitNum > 0 then
				--local nMyExchangeNum = math.floor(DataPool:GetPlayerMission_DataRound(nLimitMD)/10)
				local nMyExchangeNum = DataPool:GetPlayerMission_DataRound(nLimitMD)
				local nLastNum = nLimitNum - nMyExchangeNum
				if nLastNum <= 0 then
					nLastNum = 0				
					SeventhFestivalTopList_Exchange_Qingrenjie_Mask[i]:Show()
					SeventhFestivalTopList_Exchange_Qingrenjie_Limit[i]:Hide()
				else
					SeventhFestivalTopList_Exchange_Qingrenjie_Num[i]:SetText(tostring(nLastNum))
					SeventhFestivalTopList_Exchange_Qingrenjie_Limit[i]:Show()
					SeventhFestivalTopList_Exchange_Qingrenjie_Mask[i]:Hide()
				end
			else
				SeventhFestivalTopList_Exchange_Qingrenjie_Limit[i]:Hide()
				SeventhFestivalTopList_Exchange_Qingrenjie_Mask[i]:Hide()
			end
		end
	end
	
end

--痴情玉兑换奖励窗口
function SeventhFestivalTopList_Exchange_Chiqingyu_Update()

	g_SeventhFestivalTopList_ExchangeSubPage = 1;
	
	SeventhFestivalTopList_Exchange_GiftFrame:Hide()
	SeventhFestivalTopList_Exchange_GiftFrame1:Show()
	SeventhFestivalTopList_Exchange_GiftFrame2:Hide()
	
	SeventhFestivalTopList_Ranking_Chiqing:SetCheck(1);
	SeventhFestivalTopList_Ranking_Qingren:SetCheck(0);
	SeventhFestivalTopList_Ranking_Xiangsijie:SetCheck(0);
		
	SeventhFestivalTopList_Exchange_Info:SetText( "#{QXLS_150724_105}" )
	SeventhFestivalTopList_Exchange_UpdateChiqingyuCount()
	
	for i = 1, table.getn(g_SeventhFestivalTopList_Chiqingyu_Bonus) do
		local theAction = DataPool:CreateActionItemForShow(g_SeventhFestivalTopList_Chiqingyu_Bonus[i].itemid, g_SeventhFestivalTopList_Chiqingyu_Bonus[i].count)
		if theAction:GetID() ~= 0 then
			SeventhFestivalTopList_Exchange_Chiqingyu_Action[i]:SetActionItem(theAction:GetID())
		end
		
		local MySex =Player:GetMySex()
		local itemname
		if MySex == 0 and i > 8 then
			itemname = g_SeventhFestivalTopList_Chiqingyu_Bonus[i].namewoman
		elseif MySex == 1 and i > 8 then
			itemname = g_SeventhFestivalTopList_Chiqingyu_Bonus[i].name
		else
			itemname = PlayerPackage:GetItemName( g_SeventhFestivalTopList_Chiqingyu_Bonus[i].itemid )
		end
		
		local strName = ScriptGlobal_Format("#{QXLS_220517_54}", itemname)
		SeventhFestivalTopList_Exchange_Chiqingyu_Name[i]:SetText( strName );
		
		local strText = ScriptGlobal_Format("#{QXLS_150724_107}", g_SeventhFestivalTopList_Chiqingyu_Bonus[i].neednum)
		local strTips = ScriptGlobal_Format("#{QXLS_150724_108}", g_SeventhFestivalTopList_Chiqingyu_Bonus[i].neednum, itemname)
		SeventhFestivalTopList_Exchange_Chiqingyu_Text[i]:SetText( strText )
		SeventhFestivalTopList_Exchange_Chiqingyu_Text[i]:SetToolTip( strTips )
	end
	
end

--情人结兑换奖励窗口
function SeventhFestivalTopList_Exchange_Xiangsijie_Update()

	g_SeventhFestivalTopList_ExchangeSubPage = 2;
	
	SeventhFestivalTopList_Exchange_GiftFrame:Hide()
	SeventhFestivalTopList_Exchange_GiftFrame1:Hide()
	SeventhFestivalTopList_Exchange_GiftFrame2:Show()
	
	SeventhFestivalTopList_Ranking_Chiqing:SetCheck(0);
	SeventhFestivalTopList_Ranking_Qingren:SetCheck(0);
	SeventhFestivalTopList_Ranking_Xiangsijie:SetCheck(1);
			
	SeventhFestivalTopList_Exchange_Info:SetText( "#{QXLS_240704_48}" )
	SeventhFestivalTopList_Exchange_UpdateXiangSiJieCount()
		
	for i = 1, table.getn(g_SeventhFestivalTopList_XiangSiJie_Bonus) do
		local theAction = DataPool:CreateActionItemForShow(g_SeventhFestivalTopList_XiangSiJie_Bonus[i].itemid, g_SeventhFestivalTopList_XiangSiJie_Bonus[i].count)
		if theAction:GetID() ~= 0 then
			SeventhFestivalTopList_Exchange_XiangSiJie_Action[i]:SetActionItem(theAction:GetID())
		end
		
		local strName = ScriptGlobal_Format("#{QXLS_240704_4}", g_SeventhFestivalTopList_XiangSiJie_Bonus[i].name)
		SeventhFestivalTopList_Exchange_XiangSiJie_Name[i]:SetText( strName )
		
		local strText = ScriptGlobal_Format("#{QXLS_240704_2}", g_SeventhFestivalTopList_XiangSiJie_Bonus[i].neednum)
		local strTips = ScriptGlobal_Format("#{QXLS_240704_3}", g_SeventhFestivalTopList_XiangSiJie_Bonus[i].neednum, g_SeventhFestivalTopList_XiangSiJie_Bonus[i].name)
		SeventhFestivalTopList_Exchange_XiangSiJie_Text[i]:SetText( strText )
		SeventhFestivalTopList_Exchange_XiangSiJie_Text[i]:SetToolTip( strTips )
	end
	
end

--情人结兑换奖励
function SeventhFestivalTopList_Exchange_Qingrenjie_Click(i)
	
	local str = ScriptGlobal_Format("#{QXLS_150724_110}", g_SeventhFestivalTopList_Qingrenjie_Bonus[i].neednum, g_SeventhFestivalTopList_Qingrenjie_Bonus[i].name)
	PushEvent("QIXIRANK_EXCHANGE_CONFIRM", 1, i, str)
	
end

--痴情玉兑换奖励
function SeventhFestivalTopList_Exchange_Chiqingyu_Click(i)

	local MySex =Player:GetMySex()
	local itemname
	if MySex == 0 and i > 8 then
		itemname = g_SeventhFestivalTopList_Chiqingyu_Bonus[i].namewoman
	elseif MySex == 1 and i > 8 then
		itemname = g_SeventhFestivalTopList_Chiqingyu_Bonus[i].name
	else
		itemname = PlayerPackage:GetItemName( g_SeventhFestivalTopList_Chiqingyu_Bonus[i].itemid )
	end
	
	local str = ScriptGlobal_Format("#{QXLS_150724_117}", g_SeventhFestivalTopList_Chiqingyu_Bonus[i].neednum, itemname)
	PushEvent("QIXIRANK_EXCHANGE_CONFIRM", 2, i, str)
	
end

--新代币兑换奖励
function SeventhFestivalTopList_Exchange_Xiangsijie_Click(i)
	
	local str = ScriptGlobal_Format("#{QXLS_240704_42}", g_SeventhFestivalTopList_XiangSiJie_Bonus[i].neednum, g_SeventhFestivalTopList_XiangSiJie_Bonus[i].name)
	PushEvent("QIXIRANK_EXCHANGE_CONFIRM", 3, i, str)
	
end

--打开元宝商店——花舞人间——春城百花
function SeventhFestivalTopList_BuyRose()
	SeventhFestivalTopList_Shop_Goto(0, 6, 5)
end

function SeventhFestivalTopList_Shop_Goto(Fenye, Tag, Shop)
	if(IsWindowShow("YuanbaoShop")) then
		CloseWindow("YuanbaoShop", true)
	end
	PushEvent("TOGGLE_YUANBAOSHOP", Fenye, -1, -1, Tag, Shop)
end

function SeventhFestivalTopList_ConvertToBonusRank( nRank )
	local nBonusRank = nRank
	if nRank >= 4 and nRank <= 10 then
		nBonusRank = 4;
	elseif nRank >= 11 and nRank <= 20 then
		nBonusRank = 5;
	end	
	return nBonusRank	
end

function SeventhFestivalTopList_Qingrenjie_ShowBonus( nPage )
	if 1 == 1 then
		return
	end

	for i = 1, table.getn(g_SeventhFestivalTopList_Qingrenjie_Bonus) do
		if g_SeventhFestivalTopList_Qingrenjie_Bonus[i].OnPage == nPage then
			SeventhFestivalTopList_Exchange_Qingrenjie_BK[i]:Show()
		else
			SeventhFestivalTopList_Exchange_Qingrenjie_BK[i]:Hide()
		end
	end
	
	if nPage <= 1 then
		SeventhFestivalTopList_Exchange_GiftFrame_UpPage:Disable()
		SeventhFestivalTopList_Exchange_GiftFrame_DownPage:Enable()
		
		SeventhFestivalTopList_Exchange_GiftFrame_CurrentlyPage:SetText("1/2")
	else
		SeventhFestivalTopList_Exchange_GiftFrame_UpPage:Enable()
		SeventhFestivalTopList_Exchange_GiftFrame_DownPage:Enable()
		
		SeventhFestivalTopList_Exchange_GiftFrame_CurrentlyPage:SetText("2/2")
	end
	
end

function SeventhFestivalTopList_Exchange_GiftFrame_PageUp()
	if 1 == 1 then
		return
	end

	if g_SeventhFestivalTopList_Qingrenjie_Page <= 1 then
		return
	end
	g_SeventhFestivalTopList_Qingrenjie_Page = g_SeventhFestivalTopList_Qingrenjie_Page - 1
	SeventhFestivalTopList_Qingrenjie_ShowBonus( g_SeventhFestivalTopList_Qingrenjie_Page )
	
end

function SeventhFestivalTopList_Exchange_GiftFrame_PageDown()
	if 1 == 1 then
		return
	end

	if g_SeventhFestivalTopList_Qingrenjie_Page >= 2 then
		return
	end
	g_SeventhFestivalTopList_Qingrenjie_Page = g_SeventhFestivalTopList_Qingrenjie_Page + 1
	SeventhFestivalTopList_Qingrenjie_ShowBonus( g_SeventhFestivalTopList_Qingrenjie_Page )
	
end

