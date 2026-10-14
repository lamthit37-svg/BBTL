----------------------
-- ValentineRoseTopList ---
----------------------
--界面位置
local g_ValentineRoseTopList_UnifiedPosition = nil

--计时器
local g_ValentineRoseTopList_CooldownDur = 4*1000	--4s冷却
local g_ValentineRoseTopList_Cooldown = 
{
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
}

--页签显示
local g_ValentineRoseTopList_CurPage = 0--默认显示页签--注：1标示排行榜；2标识兑换；3标识累计奖励；
local g_ValentineRoseTopList_MaxPage = 3--最大页签数
local g_ValentineRoseTopList_FlowerSubPage = 0
local g_ValentineRoseTopList_ExchangeSubPage = 0	-- 0情人结;1痴情玉;1情缘结

--排行榜相关控件
local g_ValentineRoseTopList_Btn_Page = {}
local g_ValentineRoseTopList_Btn_FlowerPage = {}
local g_ValentineRoseTopList_Btn_FlowerPage_Redpoint = {}
local g_ValentineRoseTopList_Present_Num = {}
local g_ValentineRoseTopList_Present_Name = {}
local g_ValentineRoseTopList_Present_Score = {}
local g_ValentineRoseTopList_Present_BonusAction1 = {}
local g_ValentineRoseTopList_Present_BonusAction2 = {}
local g_ValentineRoseTopList_Present_BonusAction3 = {}
local g_ValentineRoseTopList_Present_BonusPreview1 = {}
local g_ValentineRoseTopList_Present_BonusPreview2 = {}
local g_ValentineRoseTopList_Present_BonusPreview3 = {}

local g_ValentineRoseTopList_Receive_Num = {}
local g_ValentineRoseTopList_Receive_Name = {}
local g_ValentineRoseTopList_Receive_Score = {}
local g_ValentineRoseTopList_Receive_BonusAction1 = {}
local g_ValentineRoseTopList_Receive_BonusAction2 = {}
local g_ValentineRoseTopList_Receive_BonusAction3 = {}
local g_ValentineRoseTopList_Receive_BonusPreview1 = {}
local g_ValentineRoseTopList_Receive_BonusPreview2 = {}
local g_ValentineRoseTopList_Receive_BonusPreview3 = {}

--上榜人数
local g_ValentineRoseTopList_Ranking_Count = 20
local g_ValentineRoseTopList_Ranking_CountPerPage = 5
local g_ValentineRoseTopList_PresentRanking_CurPage = 0
local g_ValentineRoseTopList_ReceiveRanking_CurPage = 0

local g_ValentineRoseTopList_SelfPresentRank = 0;
local g_ValentineRoseTopList_SelfReceiveRank = 0;

--累计奖励页面控件
local g_ValentineRoseTopList_LeiJi_Text1 = {}
local g_ValentineRoseTopList_LeiJi_Text2 = {}
local g_ValentineRoseTopList_LeiJi_Text3 = {}
local g_ValentineRoseTopList_LeiJi_Action = {}
local g_ValentineRoseTopList_LeiJi_Button = {}
local g_ValentineRoseTopList_LeiJi_Tips = {}
local g_ValentineRoseTopList_LeiJi_Image = {}

--活动状态
local g_ValentineRoseTopList_State = -1
local g_ValentineRoseTopList_AllState = {}

--榜单信息
local g_ValentineRoseTopList_Info = --待修改
{
	--耀世传情
	[1] = {desc = "#{MGCQ_151230_12}", count = 3, sendmd = 3357, receivemd = 3358, sendtitle = "#{MGCQ_151230_19}", receivetitle = "#{MGCQ_151230_20}", 
		strsend = "#{MGCQ_151230_23}", strreceive = "#{MGCQ_151230_24}", strsendNum = "#{MGCQ_151230_25}", strreceiveNum = "#{MGCQ_151230_26}", 
		BounsBtnTip = "#{MGCQ_151230_13}", szSendBonusTip="#{MGCQ_211130_74}", szReceiveBonusTip="#{MGCQ_211130_75}" },
	--万千宠爱
	[2] = {desc = "#{MGCQ_151230_31}", count = 3, sendmd = 3359, receivemd = 3360, sendtitle = "#{MGCQ_151230_34}", receivetitle = "#{MGCQ_151230_35}", 
		strsend = "#{MGCQ_151230_23}", strreceive = "#{MGCQ_151230_24}", strsendNum = "#{MGCQ_151230_36}", strreceiveNum = "#{MGCQ_151230_37}", 
		BounsBtnTip = "#{MGCQ_151230_13}", szSendBonusTip="#{MGCQ_211130_76}", szReceiveBonusTip="#{MGCQ_211130_92}" },
	--三生挚恋
	[3] = {desc = "#{MGCQ_151230_38}", count = 3, sendmd = 3361, receivemd = 3362, sendtitle = "#{MGCQ_151230_39}", receivetitle = "#{MGCQ_151230_40}", 
		strsend = "#{MGCQ_151230_23}", strreceive = "#{MGCQ_151230_24}", strsendNum = "#{MGCQ_151230_41}", strreceiveNum = "#{MGCQ_151230_42}", 
		BounsBtnTip = "#{MGCQ_211130_05}", szSendBonusTip="#{MGCQ_211130_05}", szReceiveBonusTip="#{MGCQ_211130_73}" },
}

g_ValentineRoseTopList_LeiJi_SendMD=3363	
g_ValentineRoseTopList_QingRenJie=3364	
g_ValentineRoseTopList_ChiQingYu=3365
g_ValentineRoseTopList_QingYuanJie=3366

--榜单信息
local g_ValentineRoseTopList_Tip = --待修改
{
	[1] = {tip1 = "#{MGCQ_151230_71}", tip2 = "#{MGCQ_151230_72}", tip3 = "#{MGCQ_151230_73}"},
	[2] = {tip1 = "#{MGCQ_151230_71}", tip2 = "#{MGCQ_151230_126}", tip3 = "#{MGCQ_151230_73}"},
	[3] = {tip1 = "#{MGCQ_151230_71}", tip2 = "#{MGCQ_151230_127}", tip3 = "#{MGCQ_151230_73}"},
}

--预览数据
local g_ValentineRoseTopList_PreviewInfo = 
{
	[38008296] = { dressId=10128600, hairId=284, faceId=208 },		--礼盒
	[38008297] = { dressId=10128616, hairId=285, faceId=208 },
	[38008298] = { dressId=10128615, hairId=285, faceId=208 },
	[38008299] = { dressId=10128614, hairId=285, faceId=208 },
	[38008300] = { dressId=10128617, hairId=285, faceId=208 },
	[38008301] = { dressId=10128613, hairId=285, faceId=208 },
}

--榜单奖励
local g_ValentineRoseTopList_SendBonus = --送花奖励具体物品
{
	[1] = {	--耀世传情榜
		[1]={ itemId1=0, 				itemId2=38008297, itemId3=39924069, preview=2 },
		[2]={ itemId1=0, 				itemId2=38008298, itemId3=39924070, preview=2 },
		[3]={ itemId1=0, 				itemId2=38008299, itemId3=39924071, preview=2 },
		[4]={ itemId1=0, 				itemId2=0, 		  itemId3=38008300, preview=3 },
		[5]={ itemId1=0, 				itemId2=0, 		  itemId3=38008301, preview=3 },
	},
	[2] = {	--万千宠爱榜
		[1]={ itemId1=0, 				itemId2=38008302, itemId3=39924081, preview=0 },
		[2]={ itemId1=0, 				itemId2=0, 		  itemId3=38008303, preview=0 },
		[3]={ itemId1=0, 				itemId2=0, 		  itemId3=38008304, preview=0 },
		[4]={ itemId1=0, 				itemId2=0, 		  itemId3=38008305, preview=0 },
		[5]={ itemId1=0, 				itemId2=0, 		  itemId3=38008306, preview=0 },
	},
	[3] = {	--三生挚爱榜
		[1]={ itemId1=0, 				itemId2=38008307, itemId3=39924075, preview=0 },
		[2]={ itemId1=0, 				itemId2=38008308, itemId3=39924076, preview=0 },
		[3]={ itemId1=0, 				itemId2=38008309, itemId3=39924077, preview=0 },
		[4]={ itemId1=0, 				itemId2=0, 		  itemId3=38008310, preview=0 },
		[5]={ itemId1=0, 				itemId2=0, 		  itemId3=39910158, preview=0 },
	},
}

local g_ValentineRoseTopList_ReceiveBonus = --收花奖励具体物品
{
	[1] = {	--耀世传情榜
		[1]={ itemId1=0, 				itemId2=38008297, itemId3=39924072, preview=2 },
		[2]={ itemId1=0, 				itemId2=38008298, itemId3=39924073, preview=2 },
		[3]={ itemId1=0, 				itemId2=38008299, itemId3=39924074, preview=2 },
		[4]={ itemId1=0, 				itemId2=0, 		  itemId3=38008300, preview=3 },
		[5]={ itemId1=0, 				itemId2=0, 		  itemId3=38008301, preview=3 },
	},
	[2] = {	--万千宠爱榜
		[1]={ itemId1=0, 				itemId2=38008302, itemId3=39924082, preview=0 },
		[2]={ itemId1=0, 				itemId2=0, 		  itemId3=38008303, preview=0 },
		[3]={ itemId1=0, 				itemId2=0, 		  itemId3=38008304, preview=0 },
		[4]={ itemId1=0, 				itemId2=0, 		  itemId3=38008305, preview=0 },
		[5]={ itemId1=0, 				itemId2=0, 		  itemId3=38008306, preview=0 },
	},
	[3] = {	--三生挚爱榜
		[1]={ itemId1=0, 				itemId2=38008307, itemId3=39924078, preview=0 },
		[2]={ itemId1=0, 				itemId2=38008308, itemId3=39924079, preview=0 },
		[3]={ itemId1=0, 				itemId2=38008309, itemId3=39924080, preview=0 },
		[4]={ itemId1=0, 				itemId2=0, 		  itemId3=38008310, preview=0 },
		[5]={ itemId1=0, 				itemId2=0, 		  itemId3=39910158, preview=0 },
	},
}

local ValentineRoseTopList_RankingImage={
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

local ValentineRoseTopList_Exchange_Qingrenjie_Action = {}
local ValentineRoseTopList_Exchange_Qingrenjie_Name = {}
local ValentineRoseTopList_Exchange_Qingrenjie_Text = {}
local ValentineRoseTopList_Exchange_Qingrenjie_LimitBK = {}
local ValentineRoseTopList_Exchange_Qingrenjie_LimitNum = {}
local ValentineRoseTopList_Exchange_Qingrenjie_LimitImage = {}
local ValentineRoseTopList_Exchange_Qingrenjie_Mark = {}
local ValentineRoseTopList_Exchange_Chiqingyu_Action = {}
local ValentineRoseTopList_Exchange_Chiqingyu_Name = {}
local ValentineRoseTopList_Exchange_Chiqingyu_Text = {}
local ValentineRoseTopList_Exchange_Qingyuanjie_Action = {}
local ValentineRoseTopList_Exchange_Qingyuanjie_Name = {}
local ValentineRoseTopList_Exchange_Qingyuanjie_Text = {}

g_ValentineRoseTopList_Qingrenjie_Bonus =
{
	[1] = {neednum = 1314, itemid = 38008296, count = 1, name = "凛冬誓约礼盒", LimitMD = -1, LimitNum = -1},
	[2] = {neednum = 1688, itemid = 39910158, count = 1, name = "超级珍兽笼：恋爱天使", LimitMD = 3419, LimitNum = 3},
	[3] = {neednum = 1060, itemid = 10117032, count = 1, name = "北境霜锋", LimitMD = -1, LimitNum = -1},
	[4] = {neednum = 1060, itemid = 10192252, count = 1, name = "晶璨玫瑰", LimitMD = -1, LimitNum = -1},
	[5] = {neednum = 800, itemid = 10105130, count = 1, name = "寒晶飞羽", LimitMD = -1, LimitNum = -1},
	[6] = {neednum = 521, itemid = 30504325, count = 1, name = "珍兽蛋：熊猫双侠", LimitMD = -1, LimitNum = -1},	
	[7] = {neednum = 310, itemid = 38008321, count = 1, name = "雪影双生", LimitMD = -1, LimitNum = -1},	
	[8] = {neednum = 300, itemid = 39920546, count = 1, name = "山楂冰糖葫芦", LimitMD = -1, LimitNum = -1},
	[9] = {neednum = 300, itemid = 39920547, count = 1, name = "大风车", LimitMD = -1, LimitNum = -1},
	[10] = {neednum = 150, itemid = 39920548, count = 1, name = "长相思", LimitMD = -1, LimitNum = -1},
	[11] = {neednum = 150, itemid = 39920549, count = 1, name = "一生一世", LimitMD = -1, LimitNum = -1},
	[12] = {neednum = 150, itemid = 39920550, count = 1, name = "永恒之爱", LimitMD = -1, LimitNum = -1},
	[13] = {neednum = 120, itemid = 39920551, count = 1, name = "漫天花雨", LimitMD = -1, LimitNum = -1},
	[14] = {neednum = 120, itemid = 39920552, count = 1, name = "漫天花雨·心相印", LimitMD = -1, LimitNum = -1},	
	[15] = {neednum = 20, itemid = 38006185, count = 1, name = "花海钱币", LimitMD = -1, LimitNum = -1},	
	[16] = {neednum = 2, itemid = 38006186, count = 1, name = "花间钱币", LimitMD = -1, LimitNum = -1},
}


g_ValentineRoseTopList_Chiqingyu_Bonus =
{
	[1] = {neednum = 2, itemid = 38000402, count = 1, name = "恒爱蜜语金丝"},
	[2] = {neednum = 2, itemid = 38000403, count = 1, name = "千缘蜜语金丝"},
	[3] = {neednum = 2, itemid = 38000404, count = 1, name = "柔情蜜语金丝"},
	[4] = {neednum = 2, itemid = 38000405, count = 1, name = "甜美蜜语金丝"},
	[5] = {neednum = 2, itemid = 38000406, count = 1, name = "美满蜜语金丝"},
	[6] = {neednum = 2, itemid = 38001165, count = 1, name = "唯爱蜜语金丝"},
	[7] = {neednum = 2, itemid = 38001166, count = 1, name = "浓情蜜语金丝"},
	[8] = {neednum = 2, itemid = 38000432, count = 1, name = "相守蜜语金丝"},
	[9] = {neednum = 1, itemid = 39920527, count = 1, name = "气宇不凡", namewoman = "如花似玉"},
	[10] = {neednum = 3, itemid = 39920528, count = 1, name = "风流倜傥", namewoman = "国色天香"},
	[11] = {neednum = 10, itemid = 39920529, count = 1, name = "玉树临风", namewoman = "倾国倾城"},
	[12] = {neednum = 16, itemid = 39920530, count = 1, name = "龙章凤姿", namewoman = "绝世佳人"},
	[13] = {neednum = 3, itemid = 39921199, count = 1, name = "浓情爱神石雕", namewoman = "浓情爱神石雕"},
	[14] = {neednum = 3, itemid = 39921200, count = 1, name = "浓情巧克力", namewoman = "浓情巧克力"},
	[15] = {neednum = 3, itemid = 39921201, count = 1, name = "浓情蜜语花毯", namewoman = "浓情蜜语花毯"},	
	[16] = {neednum = 8, itemid = 38010025, count = 1, name = "相框：花间蕊意", namewoman = "相框：花间蕊意"},		
}

g_ValentineRoseTopList_Qingyuanjie_Bonus =
{
	[1] = {neednum = 1, itemid = 10102462, count = 1, name = "武器：幽梦"},	
	[2] = {neednum = 1, itemid = 10102474, count = 1, name = "武器：柔情"},
	[3] = {neednum = 1, itemid = 10102127, count = 1, name = "武器：绮梦玫瑰"},
	[4] = {neednum = 1, itemid = 10102120, count = 1, name = "武器：一生一世"},
	[5] = {neednum = 1, itemid = 10102123, count = 1, name = "武器：草莓甜筒"},
	[6] = {neednum = 1, itemid = 10107016, count = 1, name = "武器：霜玉流光"},
	[7] = {neednum = 1, itemid = 10102650, count = 1, name = "武器：千重花嫁"},
	[8] = {neednum = 1, itemid = 10102751, count = 1, name = "武器：醉红姻"},
	[9] = {neednum = 1, itemid = 10102870, count = 1, name = "武器：灵寒一枝"},
	[10]= {neednum = 1, itemid = 10102947, count = 1, name = "武器：方糖海盐"},
	[11]= {neednum = 1, itemid = 10192057, count = 1, name = "武器：美梦成真"},
	[12]= {neednum = 1, itemid = 38007641, count = 1, name = "挚恋心币"},
}

local ValentineRoseTopList_LeiJi_Bonus=
{
	[1]={need=11, itemId=38000992, count=2, MF=5340 },		--虹耀石*2
	[2]={need=33, itemId=38001595, count=5, MF=5341 },		--缀梦灵石*5
	[3]={need=99, itemId=38001332, count=5, MF=5342 },		--情诗恋曲*5
	[4]={need=188, itemId=10124726, count=1, MF=5343 },		--时装：仙侣情缘（30天，拾取绑定，拾取计时）
	[5]={need=521, itemId=38005288, count=30, MF=5344 },		--瑶华璧*30
	[6]={need=1688, itemId=39924602, count=300, MF=5345 },		--情人结：300
}

--===============================================
-- PreLoad()
--===============================================
function ValentineRoseTopList_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_ROSE_TOPLIST")
	this:RegisterEvent("UPDATE_QINGRENJIE_MD",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--===============================================
-- OnLoad()
--===============================================
function ValentineRoseTopList_OnLoad()
	g_ValentineRoseTopList_UnifiedPosition = ValentineRoseTopList_Frame:GetProperty("UnifiedPosition")
		
	--排行榜相关控件
	g_ValentineRoseTopList_Btn_Page[1]	= ValentineRoseTopList_Top_TopList1
	g_ValentineRoseTopList_Btn_Page[2]	= ValentineRoseTopList_Top_TopList2
	g_ValentineRoseTopList_Btn_Page[3]	= ValentineRoseTopList_Top_TopList3
	
	--花榜下面的三个榜控件
	g_ValentineRoseTopList_Btn_FlowerPage[1] = ValentineRoseTopList_Ranking_Bang2;
	g_ValentineRoseTopList_Btn_FlowerPage[2] = ValentineRoseTopList_Ranking_Bang3;
	g_ValentineRoseTopList_Btn_FlowerPage[3] = ValentineRoseTopList_Ranking_Bang1;
	
	g_ValentineRoseTopList_Btn_FlowerPage_Redpoint[1] = ValentineRoseTopList_Ranking_Bang2_Tips;
	g_ValentineRoseTopList_Btn_FlowerPage_Redpoint[2] = ValentineRoseTopList_Ranking_Bang3_Tips;
	g_ValentineRoseTopList_Btn_FlowerPage_Redpoint[3] = ValentineRoseTopList_Ranking_Bang1_Tips;
	
	--奖励排名控件
	g_ValentineRoseTopList_Present_Num[1]		= ValentineRoseTopList_Present_Item1_Num_Icon
	g_ValentineRoseTopList_Present_Num[2]		= ValentineRoseTopList_Present_Item2_Num_Icon
	g_ValentineRoseTopList_Present_Num[3]		= ValentineRoseTopList_Present_Item3_Num_Icon
	g_ValentineRoseTopList_Present_Num[4]		= ValentineRoseTopList_Present_Item4_Num_Icon
	g_ValentineRoseTopList_Present_Num[5]		= ValentineRoseTopList_Present_Item5_Num_Icon
	
	g_ValentineRoseTopList_Present_Name[1]	= ValentineRoseTopList_Present_Item1_Name
	g_ValentineRoseTopList_Present_Name[2]	= ValentineRoseTopList_Present_Item2_Name
	g_ValentineRoseTopList_Present_Name[3]	= ValentineRoseTopList_Present_Item3_Name
	g_ValentineRoseTopList_Present_Name[4]	= ValentineRoseTopList_Present_Item4_Name
	g_ValentineRoseTopList_Present_Name[5]	= ValentineRoseTopList_Present_Item5_Name
	
	g_ValentineRoseTopList_Present_Score[1]	= ValentineRoseTopList_Present_Item1_Count
	g_ValentineRoseTopList_Present_Score[2]	= ValentineRoseTopList_Present_Item2_Count
	g_ValentineRoseTopList_Present_Score[3]	= ValentineRoseTopList_Present_Item3_Count
	g_ValentineRoseTopList_Present_Score[4]	= ValentineRoseTopList_Present_Item4_Count
	g_ValentineRoseTopList_Present_Score[5]	= ValentineRoseTopList_Present_Item5_Count
	
	g_ValentineRoseTopList_Present_BonusAction1[1] = ValentineRoseTopList_Present_Item1_Button1
	g_ValentineRoseTopList_Present_BonusAction1[2] = ValentineRoseTopList_Present_Item2_Button1
	g_ValentineRoseTopList_Present_BonusAction1[3] = ValentineRoseTopList_Present_Item3_Button1
	g_ValentineRoseTopList_Present_BonusAction1[4] = ValentineRoseTopList_Present_Item4_Button1
	g_ValentineRoseTopList_Present_BonusAction1[5] = ValentineRoseTopList_Present_Item5_Button1
	
	g_ValentineRoseTopList_Present_BonusAction2[1] = ValentineRoseTopList_Present_Item1_Button2
	g_ValentineRoseTopList_Present_BonusAction2[2] = ValentineRoseTopList_Present_Item2_Button2
	g_ValentineRoseTopList_Present_BonusAction2[3] = ValentineRoseTopList_Present_Item3_Button2
	g_ValentineRoseTopList_Present_BonusAction2[4] = ValentineRoseTopList_Present_Item4_Button2
	g_ValentineRoseTopList_Present_BonusAction2[5] = ValentineRoseTopList_Present_Item5_Button2
	
	g_ValentineRoseTopList_Present_BonusAction3[1] = ValentineRoseTopList_Present_Item1_Button3
	g_ValentineRoseTopList_Present_BonusAction3[2] = ValentineRoseTopList_Present_Item2_Button3
	g_ValentineRoseTopList_Present_BonusAction3[3] = ValentineRoseTopList_Present_Item3_Button3
	g_ValentineRoseTopList_Present_BonusAction3[4] = ValentineRoseTopList_Present_Item4_Button3
	g_ValentineRoseTopList_Present_BonusAction3[5] = ValentineRoseTopList_Present_Item5_Button3
	
	g_ValentineRoseTopList_Present_BonusPreview1[1] = ValentineRoseTopList_Present_Item1_Preview1
	g_ValentineRoseTopList_Present_BonusPreview1[2] = ValentineRoseTopList_Present_Item2_Preview1
	g_ValentineRoseTopList_Present_BonusPreview1[3] = ValentineRoseTopList_Present_Item3_Preview1
	g_ValentineRoseTopList_Present_BonusPreview1[4] = ValentineRoseTopList_Present_Item4_Preview1
	g_ValentineRoseTopList_Present_BonusPreview1[5] = ValentineRoseTopList_Present_Item5_Preview1
	
	g_ValentineRoseTopList_Present_BonusPreview2[1] = ValentineRoseTopList_Present_Item1_Preview2
	g_ValentineRoseTopList_Present_BonusPreview2[2] = ValentineRoseTopList_Present_Item2_Preview2
	g_ValentineRoseTopList_Present_BonusPreview2[3] = ValentineRoseTopList_Present_Item3_Preview2
	g_ValentineRoseTopList_Present_BonusPreview2[4] = ValentineRoseTopList_Present_Item4_Preview2
	g_ValentineRoseTopList_Present_BonusPreview2[5] = ValentineRoseTopList_Present_Item5_Preview2
	
	g_ValentineRoseTopList_Present_BonusPreview3[1] = ValentineRoseTopList_Present_Item1_Preview3
	g_ValentineRoseTopList_Present_BonusPreview3[2] = ValentineRoseTopList_Present_Item2_Preview3
	g_ValentineRoseTopList_Present_BonusPreview3[3] = ValentineRoseTopList_Present_Item3_Preview3
	g_ValentineRoseTopList_Present_BonusPreview3[4] = ValentineRoseTopList_Present_Item4_Preview3
	g_ValentineRoseTopList_Present_BonusPreview3[5] = ValentineRoseTopList_Present_Item5_Preview3
	
	g_ValentineRoseTopList_Receive_Num[1]		= ValentineRoseTopList_Receive_Item1_Num_Icon
	g_ValentineRoseTopList_Receive_Num[2]		= ValentineRoseTopList_Receive_Item2_Num_Icon
	g_ValentineRoseTopList_Receive_Num[3]		= ValentineRoseTopList_Receive_Item3_Num_Icon
	g_ValentineRoseTopList_Receive_Num[4]		= ValentineRoseTopList_Receive_Item4_Num_Icon
	g_ValentineRoseTopList_Receive_Num[5]		= ValentineRoseTopList_Receive_Item5_Num_Icon
	
	g_ValentineRoseTopList_Receive_Name[1]	= ValentineRoseTopList_Receive_Item1_Name
	g_ValentineRoseTopList_Receive_Name[2]	= ValentineRoseTopList_Receive_Item2_Name
	g_ValentineRoseTopList_Receive_Name[3]	= ValentineRoseTopList_Receive_Item3_Name
	g_ValentineRoseTopList_Receive_Name[4]	= ValentineRoseTopList_Receive_Item4_Name
	g_ValentineRoseTopList_Receive_Name[5]	= ValentineRoseTopList_Receive_Item5_Name
	
	g_ValentineRoseTopList_Receive_Score[1]	= ValentineRoseTopList_Receive_Item1_Count
	g_ValentineRoseTopList_Receive_Score[2]	= ValentineRoseTopList_Receive_Item2_Count
	g_ValentineRoseTopList_Receive_Score[3]	= ValentineRoseTopList_Receive_Item3_Count
	g_ValentineRoseTopList_Receive_Score[4]	= ValentineRoseTopList_Receive_Item4_Count
	g_ValentineRoseTopList_Receive_Score[5]	= ValentineRoseTopList_Receive_Item5_Count
	
	g_ValentineRoseTopList_Receive_BonusAction1[1] = ValentineRoseTopList_Receive_Item1_Button1
	g_ValentineRoseTopList_Receive_BonusAction1[2] = ValentineRoseTopList_Receive_Item2_Button1
	g_ValentineRoseTopList_Receive_BonusAction1[3] = ValentineRoseTopList_Receive_Item3_Button1
	g_ValentineRoseTopList_Receive_BonusAction1[4] = ValentineRoseTopList_Receive_Item4_Button1
	g_ValentineRoseTopList_Receive_BonusAction1[5] = ValentineRoseTopList_Receive_Item5_Button1
	
	g_ValentineRoseTopList_Receive_BonusAction2[1] = ValentineRoseTopList_Receive_Item1_Button2
	g_ValentineRoseTopList_Receive_BonusAction2[2] = ValentineRoseTopList_Receive_Item2_Button2
	g_ValentineRoseTopList_Receive_BonusAction2[3] = ValentineRoseTopList_Receive_Item3_Button2
	g_ValentineRoseTopList_Receive_BonusAction2[4] = ValentineRoseTopList_Receive_Item4_Button2
	g_ValentineRoseTopList_Receive_BonusAction2[5] = ValentineRoseTopList_Receive_Item5_Button2
	
	g_ValentineRoseTopList_Receive_BonusAction3[1] = ValentineRoseTopList_Receive_Item1_Button3
	g_ValentineRoseTopList_Receive_BonusAction3[2] = ValentineRoseTopList_Receive_Item2_Button3
	g_ValentineRoseTopList_Receive_BonusAction3[3] = ValentineRoseTopList_Receive_Item3_Button3
	g_ValentineRoseTopList_Receive_BonusAction3[4] = ValentineRoseTopList_Receive_Item4_Button3
	g_ValentineRoseTopList_Receive_BonusAction3[5] = ValentineRoseTopList_Receive_Item5_Button3
	
	g_ValentineRoseTopList_Receive_BonusPreview1[1] = ValentineRoseTopList_Receive_Item1_Preview1
	g_ValentineRoseTopList_Receive_BonusPreview1[2] = ValentineRoseTopList_Receive_Item2_Preview1
	g_ValentineRoseTopList_Receive_BonusPreview1[3] = ValentineRoseTopList_Receive_Item3_Preview1
	g_ValentineRoseTopList_Receive_BonusPreview1[4] = ValentineRoseTopList_Receive_Item4_Preview1
	g_ValentineRoseTopList_Receive_BonusPreview1[5] = ValentineRoseTopList_Receive_Item5_Preview1
	
	g_ValentineRoseTopList_Receive_BonusPreview2[1] = ValentineRoseTopList_Receive_Item1_Preview2
	g_ValentineRoseTopList_Receive_BonusPreview2[2] = ValentineRoseTopList_Receive_Item2_Preview2
	g_ValentineRoseTopList_Receive_BonusPreview2[3] = ValentineRoseTopList_Receive_Item3_Preview2
	g_ValentineRoseTopList_Receive_BonusPreview2[4] = ValentineRoseTopList_Receive_Item4_Preview2
	g_ValentineRoseTopList_Receive_BonusPreview2[5] = ValentineRoseTopList_Receive_Item5_Preview2
	
	g_ValentineRoseTopList_Receive_BonusPreview3[1] = ValentineRoseTopList_Receive_Item1_Preview3
	g_ValentineRoseTopList_Receive_BonusPreview3[2] = ValentineRoseTopList_Receive_Item2_Preview3
	g_ValentineRoseTopList_Receive_BonusPreview3[3] = ValentineRoseTopList_Receive_Item3_Preview3
	g_ValentineRoseTopList_Receive_BonusPreview3[4] = ValentineRoseTopList_Receive_Item4_Preview3
	g_ValentineRoseTopList_Receive_BonusPreview3[5] = ValentineRoseTopList_Receive_Item5_Preview3
	
	--排行榜兑换相关控件
	ValentineRoseTopList_Exchange_Qingrenjie_Action[1] = ValentineRoseTopList_ExchangeFrame_BK1_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[2] = ValentineRoseTopList_ExchangeFrame_BK2_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[3] = ValentineRoseTopList_ExchangeFrame_BK3_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[4] = ValentineRoseTopList_ExchangeFrame_BK4_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[5] = ValentineRoseTopList_ExchangeFrame_BK5_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[6] = ValentineRoseTopList_ExchangeFrame_BK6_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[7] = ValentineRoseTopList_ExchangeFrame_BK7_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[8] = ValentineRoseTopList_ExchangeFrame_BK8_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[9] = ValentineRoseTopList_ExchangeFrame_BK9_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[10] = ValentineRoseTopList_ExchangeFrame_BK10_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[11] = ValentineRoseTopList_ExchangeFrame_BK11_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[12] = ValentineRoseTopList_ExchangeFrame_BK12_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[13] = ValentineRoseTopList_ExchangeFrame_BK13_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[14] = ValentineRoseTopList_ExchangeFrame_BK14_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[15] = ValentineRoseTopList_ExchangeFrame_BK15_Icon
	ValentineRoseTopList_Exchange_Qingrenjie_Action[16] = ValentineRoseTopList_ExchangeFrame_BK16_Icon
	
	ValentineRoseTopList_Exchange_Qingrenjie_Name[1] = ValentineRoseTopList_ExchangeFrame_BK1_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[2] = ValentineRoseTopList_ExchangeFrame_BK2_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[3] = ValentineRoseTopList_ExchangeFrame_BK3_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[4] = ValentineRoseTopList_ExchangeFrame_BK4_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[5] = ValentineRoseTopList_ExchangeFrame_BK5_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[6] = ValentineRoseTopList_ExchangeFrame_BK6_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[7] = ValentineRoseTopList_ExchangeFrame_BK7_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[8] = ValentineRoseTopList_ExchangeFrame_BK8_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[9] = ValentineRoseTopList_ExchangeFrame_BK9_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[10] = ValentineRoseTopList_ExchangeFrame_BK10_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[11] = ValentineRoseTopList_ExchangeFrame_BK11_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[12] = ValentineRoseTopList_ExchangeFrame_BK12_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[13] = ValentineRoseTopList_ExchangeFrame_BK13_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[14] = ValentineRoseTopList_ExchangeFrame_BK14_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[15] = ValentineRoseTopList_ExchangeFrame_BK15_Text1
	ValentineRoseTopList_Exchange_Qingrenjie_Name[16] = ValentineRoseTopList_ExchangeFrame_BK16_Text1

	ValentineRoseTopList_Exchange_Qingrenjie_Text[1] = ValentineRoseTopList_ExchangeFrame_BK1_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[2] = ValentineRoseTopList_ExchangeFrame_BK2_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[3] = ValentineRoseTopList_ExchangeFrame_BK3_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[4] = ValentineRoseTopList_ExchangeFrame_BK4_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[5] = ValentineRoseTopList_ExchangeFrame_BK5_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[6] = ValentineRoseTopList_ExchangeFrame_BK6_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[7] = ValentineRoseTopList_ExchangeFrame_BK7_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[8] = ValentineRoseTopList_ExchangeFrame_BK8_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[9] = ValentineRoseTopList_ExchangeFrame_BK9_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[10] = ValentineRoseTopList_ExchangeFrame_BK10_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[11] = ValentineRoseTopList_ExchangeFrame_BK11_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[12] = ValentineRoseTopList_ExchangeFrame_BK12_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[13] = ValentineRoseTopList_ExchangeFrame_BK13_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[14] = ValentineRoseTopList_ExchangeFrame_BK14_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[15] = ValentineRoseTopList_ExchangeFrame_BK15_Text2
	ValentineRoseTopList_Exchange_Qingrenjie_Text[16] = ValentineRoseTopList_ExchangeFrame_BK16_Text2

	ValentineRoseTopList_Exchange_Chiqingyu_Action[1] = ValentineRoseTopList_ExchangeFrame1_BK1_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[2] = ValentineRoseTopList_ExchangeFrame1_BK2_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[3] = ValentineRoseTopList_ExchangeFrame1_BK3_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[4] = ValentineRoseTopList_ExchangeFrame1_BK4_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[5] = ValentineRoseTopList_ExchangeFrame1_BK5_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[6] = ValentineRoseTopList_ExchangeFrame1_BK6_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[7] = ValentineRoseTopList_ExchangeFrame1_BK7_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[8] = ValentineRoseTopList_ExchangeFrame1_BK12_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[9] = ValentineRoseTopList_ExchangeFrame1_BK8_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[10] = ValentineRoseTopList_ExchangeFrame1_BK9_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[11] = ValentineRoseTopList_ExchangeFrame1_BK10_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[12] = ValentineRoseTopList_ExchangeFrame1_BK11_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[13] = ValentineRoseTopList_ExchangeFrame1_BK13_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[14] = ValentineRoseTopList_ExchangeFrame1_BK14_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[15] = ValentineRoseTopList_ExchangeFrame1_BK15_Icon
	ValentineRoseTopList_Exchange_Chiqingyu_Action[16] = ValentineRoseTopList_ExchangeFrame1_BK16_Icon	
	
	ValentineRoseTopList_Exchange_Chiqingyu_Name[1] = ValentineRoseTopList_ExchangeFrame1_BK1_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[2] = ValentineRoseTopList_ExchangeFrame1_BK2_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[3] = ValentineRoseTopList_ExchangeFrame1_BK3_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[4] = ValentineRoseTopList_ExchangeFrame1_BK4_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[5] = ValentineRoseTopList_ExchangeFrame1_BK5_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[6] = ValentineRoseTopList_ExchangeFrame1_BK6_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[7] = ValentineRoseTopList_ExchangeFrame1_BK7_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[8] = ValentineRoseTopList_ExchangeFrame1_BK12_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[9] = ValentineRoseTopList_ExchangeFrame1_BK8_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[10] = ValentineRoseTopList_ExchangeFrame1_BK9_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[11] = ValentineRoseTopList_ExchangeFrame1_BK10_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[12] = ValentineRoseTopList_ExchangeFrame1_BK11_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[13] = ValentineRoseTopList_ExchangeFrame1_BK13_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[14] = ValentineRoseTopList_ExchangeFrame1_BK14_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[15] = ValentineRoseTopList_ExchangeFrame1_BK15_Text1
	ValentineRoseTopList_Exchange_Chiqingyu_Name[16] = ValentineRoseTopList_ExchangeFrame1_BK16_Text1
	
	ValentineRoseTopList_Exchange_Chiqingyu_Text[1] = ValentineRoseTopList_ExchangeFrame1_BK1_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[2] = ValentineRoseTopList_ExchangeFrame1_BK2_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[3] = ValentineRoseTopList_ExchangeFrame1_BK3_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[4] = ValentineRoseTopList_ExchangeFrame1_BK4_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[5] = ValentineRoseTopList_ExchangeFrame1_BK5_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[6] = ValentineRoseTopList_ExchangeFrame1_BK6_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[7] = ValentineRoseTopList_ExchangeFrame1_BK7_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[8] = ValentineRoseTopList_ExchangeFrame1_BK12_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[9] = ValentineRoseTopList_ExchangeFrame1_BK8_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[10] = ValentineRoseTopList_ExchangeFrame1_BK9_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[11] = ValentineRoseTopList_ExchangeFrame1_BK10_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[12] = ValentineRoseTopList_ExchangeFrame1_BK11_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[13] = ValentineRoseTopList_ExchangeFrame1_BK13_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[14] = ValentineRoseTopList_ExchangeFrame1_BK14_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[15] = ValentineRoseTopList_ExchangeFrame1_BK15_Text2
	ValentineRoseTopList_Exchange_Chiqingyu_Text[16] = ValentineRoseTopList_ExchangeFrame1_BK16_Text2
	
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[1] = ValentineRoseTopList_ExchangeFrame_XS1_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[2] = ValentineRoseTopList_ExchangeFrame_XS2_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[3] = ValentineRoseTopList_ExchangeFrame_XS3_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[4] = ValentineRoseTopList_ExchangeFrame_XS4_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[5] = ValentineRoseTopList_ExchangeFrame_XS5_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[6] = ValentineRoseTopList_ExchangeFrame_XS6_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[7] = ValentineRoseTopList_ExchangeFrame_XS7_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[8] = ValentineRoseTopList_ExchangeFrame_XS8_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[9] = ValentineRoseTopList_ExchangeFrame_XS9_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[10] = ValentineRoseTopList_ExchangeFrame_XS10_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[11] = ValentineRoseTopList_ExchangeFrame_XS11_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[12] = ValentineRoseTopList_ExchangeFrame_XS12_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[13] = ValentineRoseTopList_ExchangeFrame_XS13_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[14] = ValentineRoseTopList_ExchangeFrame_XS14_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[15] = ValentineRoseTopList_ExchangeFrame_XS15_Icon
	ValentineRoseTopList_Exchange_Qingyuanjie_Action[16] = ValentineRoseTopList_ExchangeFrame_XS16_Icon
		
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[1] = ValentineRoseTopList_ExchangeFrame_XS1_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[2] = ValentineRoseTopList_ExchangeFrame_XS2_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[3] = ValentineRoseTopList_ExchangeFrame_XS3_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[4] = ValentineRoseTopList_ExchangeFrame_XS4_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[5] = ValentineRoseTopList_ExchangeFrame_XS5_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[6] = ValentineRoseTopList_ExchangeFrame_XS6_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[7] = ValentineRoseTopList_ExchangeFrame_XS7_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[8] = ValentineRoseTopList_ExchangeFrame_XS8_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[9] = ValentineRoseTopList_ExchangeFrame_XS9_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[10] = ValentineRoseTopList_ExchangeFrame_XS10_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[11] = ValentineRoseTopList_ExchangeFrame_XS11_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[12] = ValentineRoseTopList_ExchangeFrame_XS12_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[13] = ValentineRoseTopList_ExchangeFrame_XS13_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[14] = ValentineRoseTopList_ExchangeFrame_XS14_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[15] = ValentineRoseTopList_ExchangeFrame_XS15_Text1
	ValentineRoseTopList_Exchange_Qingyuanjie_Name[16] = ValentineRoseTopList_ExchangeFrame_XS16_Text1

	ValentineRoseTopList_Exchange_Qingyuanjie_Text[1] = ValentineRoseTopList_ExchangeFrame_XS1_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[2] = ValentineRoseTopList_ExchangeFrame_XS2_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[3] = ValentineRoseTopList_ExchangeFrame_XS3_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[4] = ValentineRoseTopList_ExchangeFrame_XS4_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[5] = ValentineRoseTopList_ExchangeFrame_XS5_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[6] = ValentineRoseTopList_ExchangeFrame_XS6_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[7] = ValentineRoseTopList_ExchangeFrame_XS7_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[8] = ValentineRoseTopList_ExchangeFrame_XS8_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[9] = ValentineRoseTopList_ExchangeFrame_XS9_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[10] = ValentineRoseTopList_ExchangeFrame_XS10_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[11] = ValentineRoseTopList_ExchangeFrame_XS11_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[12] = ValentineRoseTopList_ExchangeFrame_XS12_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[13] = ValentineRoseTopList_ExchangeFrame_XS13_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[14] = ValentineRoseTopList_ExchangeFrame_XS14_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[15] = ValentineRoseTopList_ExchangeFrame_XS15_Text2
	ValentineRoseTopList_Exchange_Qingyuanjie_Text[16] = ValentineRoseTopList_ExchangeFrame_XS16_Text2
	
	--限量
	ValentineRoseTopList_Limit_InitCtrl()
	
	--累计奖励
	ValentineRoseTopList_LeiJi_InitCtrl()
		
end

function ValentineRoseTopList_Limit_InitCtrl()
	
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[1] = ValentineRoseTopList_ExchangeFrame_BK1_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[2] = ValentineRoseTopList_ExchangeFrame_BK2_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[3] = ValentineRoseTopList_ExchangeFrame_BK3_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[4] = ValentineRoseTopList_ExchangeFrame_BK4_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[5] = ValentineRoseTopList_ExchangeFrame_BK5_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[6] = ValentineRoseTopList_ExchangeFrame_BK6_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[7] = ValentineRoseTopList_ExchangeFrame_BK7_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[8] = ValentineRoseTopList_ExchangeFrame_BK8_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[9] = ValentineRoseTopList_ExchangeFrame_BK9_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[10] = ValentineRoseTopList_ExchangeFrame_BK10_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[11] = ValentineRoseTopList_ExchangeFrame_BK11_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[12] = ValentineRoseTopList_ExchangeFrame_BK12_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[13] = ValentineRoseTopList_ExchangeFrame_BK13_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[14] = ValentineRoseTopList_ExchangeFrame_BK14_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[15] = ValentineRoseTopList_ExchangeFrame_BK15_BuyLimitNumBK
	ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[16] = ValentineRoseTopList_ExchangeFrame_BK16_BuyLimitNumBK
	
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[1] = ValentineRoseTopList_ExchangeFrame_BK1_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[2] = ValentineRoseTopList_ExchangeFrame_BK2_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[3] = ValentineRoseTopList_ExchangeFrame_BK3_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[4] = ValentineRoseTopList_ExchangeFrame_BK4_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[5] = ValentineRoseTopList_ExchangeFrame_BK5_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[6] = ValentineRoseTopList_ExchangeFrame_BK6_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[7] = ValentineRoseTopList_ExchangeFrame_BK7_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[8] = ValentineRoseTopList_ExchangeFrame_BK8_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[9] = ValentineRoseTopList_ExchangeFrame_BK9_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[10] = ValentineRoseTopList_ExchangeFrame_BK10_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[11] = ValentineRoseTopList_ExchangeFrame_BK11_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[12] = ValentineRoseTopList_ExchangeFrame_BK12_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[13] = ValentineRoseTopList_ExchangeFrame_BK13_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[14] = ValentineRoseTopList_ExchangeFrame_BK14_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[15] = ValentineRoseTopList_ExchangeFrame_BK15_BuyLimitNum
	ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[16] = ValentineRoseTopList_ExchangeFrame_BK16_BuyLimitNum
	
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[1] = ValentineRoseTopList_ExchangeFrame_BK1_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[2] = ValentineRoseTopList_ExchangeFrame_BK2_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[3] = ValentineRoseTopList_ExchangeFrame_BK3_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[4] = ValentineRoseTopList_ExchangeFrame_BK4_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[5] = ValentineRoseTopList_ExchangeFrame_BK5_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[6] = ValentineRoseTopList_ExchangeFrame_BK6_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[7] = ValentineRoseTopList_ExchangeFrame_BK7_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[8] = ValentineRoseTopList_ExchangeFrame_BK8_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[9] = ValentineRoseTopList_ExchangeFrame_BK9_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[10] = ValentineRoseTopList_ExchangeFrame_BK10_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[11] = ValentineRoseTopList_ExchangeFrame_BK11_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[12] = ValentineRoseTopList_ExchangeFrame_BK12_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[13] = ValentineRoseTopList_ExchangeFrame_BK13_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[14] = ValentineRoseTopList_ExchangeFrame_BK14_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[15] = ValentineRoseTopList_ExchangeFrame_BK15_BuyLimit
	ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[16] = ValentineRoseTopList_ExchangeFrame_BK16_BuyLimit
	
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[1] = ValentineRoseTopList_ExchangeFrame_BK1_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[2] = ValentineRoseTopList_ExchangeFrame_BK2_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[3] = ValentineRoseTopList_ExchangeFrame_BK3_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[4] = ValentineRoseTopList_ExchangeFrame_BK4_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[5] = ValentineRoseTopList_ExchangeFrame_BK5_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[6] = ValentineRoseTopList_ExchangeFrame_BK6_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[7] = ValentineRoseTopList_ExchangeFrame_BK7_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[8] = ValentineRoseTopList_ExchangeFrame_BK8_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[9] = ValentineRoseTopList_ExchangeFrame_BK9_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[10] = ValentineRoseTopList_ExchangeFrame_BK10_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[11] = ValentineRoseTopList_ExchangeFrame_BK11_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[12] = ValentineRoseTopList_ExchangeFrame_BK12_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[13] = ValentineRoseTopList_ExchangeFrame_BK13_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[14] = ValentineRoseTopList_ExchangeFrame_BK14_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[15] = ValentineRoseTopList_ExchangeFrame_BK15_Mask
	ValentineRoseTopList_Exchange_Qingrenjie_Mark[16] = ValentineRoseTopList_ExchangeFrame_BK16_Mask
	
end

function ValentineRoseTopList_LeiJi_InitCtrl()
	g_ValentineRoseTopList_LeiJi_Text1[1] = ValentineRoseTopList_Leiji_Item1_Text
	g_ValentineRoseTopList_LeiJi_Text1[2] = ValentineRoseTopList_Leiji_Item2_Text
	g_ValentineRoseTopList_LeiJi_Text1[3] = ValentineRoseTopList_Leiji_Item3_Text
	g_ValentineRoseTopList_LeiJi_Text1[4] = ValentineRoseTopList_Leiji_Item4_Text
	g_ValentineRoseTopList_LeiJi_Text1[5] = ValentineRoseTopList_Leiji_Item5_Text
	g_ValentineRoseTopList_LeiJi_Text1[6] = ValentineRoseTopList_Leiji_Item6_Text
	
	g_ValentineRoseTopList_LeiJi_Text2[1] = ValentineRoseTopList_Leiji_Item1_Text2
	g_ValentineRoseTopList_LeiJi_Text2[2] = ValentineRoseTopList_Leiji_Item2_Text2
	g_ValentineRoseTopList_LeiJi_Text2[3] = ValentineRoseTopList_Leiji_Item3_Text2
	g_ValentineRoseTopList_LeiJi_Text2[4] = ValentineRoseTopList_Leiji_Item4_Text2
	g_ValentineRoseTopList_LeiJi_Text2[5] = ValentineRoseTopList_Leiji_Item5_Text2
	g_ValentineRoseTopList_LeiJi_Text2[6] = ValentineRoseTopList_Leiji_Item6_Text2
	
	g_ValentineRoseTopList_LeiJi_Text3[1] = ValentineRoseTopList_Leiji_Item1_Text3
	g_ValentineRoseTopList_LeiJi_Text3[2] = ValentineRoseTopList_Leiji_Item2_Text3
	g_ValentineRoseTopList_LeiJi_Text3[3] = ValentineRoseTopList_Leiji_Item3_Text3
	g_ValentineRoseTopList_LeiJi_Text3[4] = ValentineRoseTopList_Leiji_Item4_Text3
	g_ValentineRoseTopList_LeiJi_Text3[5] = ValentineRoseTopList_Leiji_Item5_Text3
	g_ValentineRoseTopList_LeiJi_Text3[6] = ValentineRoseTopList_Leiji_Item6_Text3
	
	g_ValentineRoseTopList_LeiJi_Action[1] = ValentineRoseTopList_Leiji_Item1_Button
	g_ValentineRoseTopList_LeiJi_Action[2] = ValentineRoseTopList_Leiji_Item2_Button
	g_ValentineRoseTopList_LeiJi_Action[3] = ValentineRoseTopList_Leiji_Item3_Button
	g_ValentineRoseTopList_LeiJi_Action[4] = ValentineRoseTopList_Leiji_Item4_Button
	g_ValentineRoseTopList_LeiJi_Action[5] = ValentineRoseTopList_Leiji_Item5_Button
	g_ValentineRoseTopList_LeiJi_Action[6] = ValentineRoseTopList_Leiji_Item6_Button
	
	g_ValentineRoseTopList_LeiJi_Button[1] = ValentineRoseTopList_Leiji_Item1_Icon
	g_ValentineRoseTopList_LeiJi_Button[2] = ValentineRoseTopList_Leiji_Item2_Icon
	g_ValentineRoseTopList_LeiJi_Button[3] = ValentineRoseTopList_Leiji_Item3_Icon
	g_ValentineRoseTopList_LeiJi_Button[4] = ValentineRoseTopList_Leiji_Item4_Icon
	g_ValentineRoseTopList_LeiJi_Button[5] = ValentineRoseTopList_Leiji_Item5_Icon
	g_ValentineRoseTopList_LeiJi_Button[6] = ValentineRoseTopList_Leiji_Item6_Icon
	
	g_ValentineRoseTopList_LeiJi_Tips[1] = ValentineRoseTopList_Leiji_Item1_Icon_Tips
	g_ValentineRoseTopList_LeiJi_Tips[2] = ValentineRoseTopList_Leiji_Item2_Icon_Tips
	g_ValentineRoseTopList_LeiJi_Tips[3] = ValentineRoseTopList_Leiji_Item3_Icon_Tips
	g_ValentineRoseTopList_LeiJi_Tips[4] = ValentineRoseTopList_Leiji_Item4_Icon_Tips
	g_ValentineRoseTopList_LeiJi_Tips[5] = ValentineRoseTopList_Leiji_Item5_Icon_Tips
	g_ValentineRoseTopList_LeiJi_Tips[6] = ValentineRoseTopList_Leiji_Item6_Icon_Tips
	
	g_ValentineRoseTopList_LeiJi_Image[1] = ValentineRoseTopList_Leiji_Item1_Image
	g_ValentineRoseTopList_LeiJi_Image[2] = ValentineRoseTopList_Leiji_Item2_Image
	g_ValentineRoseTopList_LeiJi_Image[3] = ValentineRoseTopList_Leiji_Item3_Image
	g_ValentineRoseTopList_LeiJi_Image[4] = ValentineRoseTopList_Leiji_Item4_Image
	g_ValentineRoseTopList_LeiJi_Image[5] = ValentineRoseTopList_Leiji_Item5_Image
	g_ValentineRoseTopList_LeiJi_Image[6] = ValentineRoseTopList_Leiji_Item6_Image
	
end

--===============================================
-- OnEvent()
--===============================================
function ValentineRoseTopList_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 891049) then
		--设置当前页
		local npage = Get_XParam_INT(0)
		if npage == 4 then
			if this:IsVisible() and g_ValentineRoseTopList_CurPage == 3 then
				ValentineRoseTopList_Rank_ShowRedPoint()
				ValentineRoseTopList_LeiJiAward_Update()
			end
		elseif npage == 5 then
			if this:IsVisible() then
				ValentineRoseTopList_Rank_ShowRedPoint()
			end
		else
			if npage < 1 or npage > 3 then
				return
			end
			g_ValentineRoseTopList_CurPage = 1;   --花榜
			g_ValentineRoseTopList_FlowerSubPage = npage;
			g_ValentineRoseTopList_Btn_Page[g_ValentineRoseTopList_CurPage] : SetCheck(1)
			--显示状态
			local state1 = Get_XParam_INT(1)
			local state2 = Get_XParam_INT(2)
			local state3 = Get_XParam_INT(3)
			if state1 ~= nil and state1 >= 0 and 
				state2 ~= nil and state2 >= 0 and 
				state3 ~= nil and state3 >= 0 then
				ValentineRoseTopList_Rank_ShowState(state1, state2, state3)
			end
			--显示倒计时
			local strTime = Get_XParam_STR(0)
			if strTime ~= nil then
				ValentineRoseTopList_Ranking_CountDown:SetText("#{QRPHB_150113_9}"..strTime)
			end
		end
	elseif (event == "OPEN_ROSE_TOPLIST") then
		--显示界面
		ValentineRoseTopList_Rank_ShowRedPoint()
		for i=1, 3 do
			if i ~= index then
				g_ValentineRoseTopList_Btn_FlowerPage[i]:SetCheck(0);
			end
		end
	
		this:Show()
		--显示排行榜
		g_ValentineRoseTopList_PresentRanking_CurPage = 0
		g_ValentineRoseTopList_ReceiveRanking_CurPage = 0
		ValentineRoseTopList_Rank_ShowTopList()
	elseif (event == "UPDATE_QINGRENJIE_MD" and this:IsVisible()) then
		ValentineRoseTopList_Exchange_UpdateQingRenJieCount()
	elseif (event == "ADJEST_UI_POS") then
		ValentineRoseTopList_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ValentineRoseTopList_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ValentineRoseTopList_Close_Click()
	end
end

--===============================================
-- 以下为界面更新显示
--===============================================
--显示排行榜状态
function ValentineRoseTopList_Rank_ShowState(state1, state2, state3)
	g_ValentineRoseTopList_AllState[1] = state1;
	g_ValentineRoseTopList_AllState[2] = state2;
	g_ValentineRoseTopList_AllState[3] = state3;
	g_ValentineRoseTopList_State = g_ValentineRoseTopList_AllState[g_ValentineRoseTopList_FlowerSubPage];

end

--显示排行榜
function ValentineRoseTopList_Rank_ShowTopList()
	--有效性判断
	if g_ValentineRoseTopList_CurPage ~= 1 then
		return
	end
	if g_ValentineRoseTopList_FlowerSubPage < 1 or g_ValentineRoseTopList_FlowerSubPage > 3 then
		return
	end
		
	--设置右侧按钮状态
	g_ValentineRoseTopList_Btn_FlowerPage[g_ValentineRoseTopList_FlowerSubPage]:SetCheck(1);
	
	--隐藏兑奖
	ValentineRoseTopList_Exchange_Client:Hide()
	ValentineRoseTopList_Leiji_Client:Hide()
	
	--显示排行榜
	ValentineRoseTopList_Ranking_Frame:Show()	

	--显示活动说明
	ValentineRoseTopList_Ranking_Info:SetText(g_ValentineRoseTopList_Info[g_ValentineRoseTopList_FlowerSubPage].desc)
	
	ValentineRoseTopList_Present_TitleName:SetText(g_ValentineRoseTopList_Info[g_ValentineRoseTopList_FlowerSubPage].sendtitle)
	ValentineRoseTopList_Receive_TitleName:SetText(g_ValentineRoseTopList_Info[g_ValentineRoseTopList_FlowerSubPage].receivetitle)
	
	ValentineRoseTopList_Rank_ShowTopListPage();
	
	ValentineRoseTopList_Present_ShowSelfRank()
	ValentineRoseTopList_Receive_ShowSelfRank()
				
end

--显示排行榜
function ValentineRoseTopList_Rank_ShowTopListPage()
	--显示送花榜单
	ValentineRoseTopList_Present_ShowRank()
	--显示收花榜单
	ValentineRoseTopList_Receive_ShowRank()	
end

function ValentineRoseTopList_Present_ShowRank()
	--显示送花榜单
	local strDefName = ValentineRoseTopList_Rank_DefaultName()
	local sendBonus = g_ValentineRoseTopList_SendBonus[g_ValentineRoseTopList_FlowerSubPage];
	
	--初始化奖励控件
	for i=1, g_ValentineRoseTopList_Ranking_CountPerPage do
		g_ValentineRoseTopList_Present_BonusAction1[i]:Hide();
		g_ValentineRoseTopList_Present_BonusAction2[i]:Hide();
		g_ValentineRoseTopList_Present_BonusAction3[i]:Hide();
		g_ValentineRoseTopList_Present_BonusPreview1[i]:Hide();
		g_ValentineRoseTopList_Present_BonusPreview2[i]:Hide();
		g_ValentineRoseTopList_Present_BonusPreview3[i]:Hide();
		g_ValentineRoseTopList_Receive_BonusAction1[i]:Hide();
		g_ValentineRoseTopList_Receive_BonusAction2[i]:Hide();
		g_ValentineRoseTopList_Receive_BonusAction3[i]:Hide();
		g_ValentineRoseTopList_Receive_BonusPreview1[i]:Hide();
		g_ValentineRoseTopList_Receive_BonusPreview2[i]:Hide();
		g_ValentineRoseTopList_Receive_BonusPreview3[i]:Hide();
	end
	
	ValentineRoseTopList_Present_CurrentlyPage:SetText( ScriptGlobal_Format("#{MGCQ_211130_71}", g_ValentineRoseTopList_PresentRanking_CurPage+1 ) );
	--上一页
	if g_ValentineRoseTopList_PresentRanking_CurPage > 0 then
		ValentineRoseTopList_Present_UpPage:Enable();
	else
		ValentineRoseTopList_Present_UpPage:Disable();
	end
	--下一页
	if (g_ValentineRoseTopList_PresentRanking_CurPage+1) * g_ValentineRoseTopList_Ranking_CountPerPage < g_ValentineRoseTopList_Ranking_Count then
		ValentineRoseTopList_Present_DownPage:Enable();
	else
		ValentineRoseTopList_Present_DownPage:Disable();
	end
	ValentineRoseTopList_Ranking_GetAward1:SetToolTip( g_ValentineRoseTopList_Info[g_ValentineRoseTopList_FlowerSubPage].szSendBonusTip )  
	
	for i=1, g_ValentineRoseTopList_Ranking_CountPerPage do
		local nRank = g_ValentineRoseTopList_Ranking_CountPerPage * g_ValentineRoseTopList_PresentRanking_CurPage + i;
		
		g_ValentineRoseTopList_Present_Num[i]:SetProperty("Image", ValentineRoseTopList_RankingImage[nRank])
		--更新数据
		local index,name,score,isGetBonus,szGuid = DataPool:Lua_GetRoseSendTopListInfo(nRank-1)
		if index ~= nil and index >= 0 and name ~= "" then
			g_ValentineRoseTopList_Present_Name[i]:SetText( ScriptGlobal_Format("#{MGCQ_211130_10}", name ) );
			local scoreStr = ScriptGlobal_Format("#{MGCQ_211130_11}", tostring(score))
			g_ValentineRoseTopList_Present_Score[i]:SetText(scoreStr)
		else
			--初始化默认值
			g_ValentineRoseTopList_Present_Name[i]:SetText(strDefName)--“虚位以待”或者“未能决出”
			local scoreStr = ScriptGlobal_Format("#{MGCQ_211130_11}", " ")
			g_ValentineRoseTopList_Present_Score[i]:SetText(scoreStr)
		end
		
		--奖励
		local nBonusRank = ValentineRoseTopList_ConvertToBonusRank( nRank )
		if sendBonus[nBonusRank] ~= nil then
			if sendBonus[nBonusRank].itemId1 > 0 then
				local theAction = DataPool:CreateActionItemForShow(sendBonus[nBonusRank].itemId1, 1);
				if theAction:GetID() ~= 0 then
					g_ValentineRoseTopList_Present_BonusAction1[i]:SetActionItem(theAction:GetID())
					g_ValentineRoseTopList_Present_BonusAction1[i]:Show();
				end
				if sendBonus[nBonusRank].preview == 1 then
					g_ValentineRoseTopList_Present_BonusPreview1[i]:Show();
				end
			end
			
			if sendBonus[nBonusRank].itemId2 > 0 then
				local theAction = DataPool:CreateActionItemForShow(sendBonus[nBonusRank].itemId2, 1);
				if theAction:GetID() ~= 0 then
					g_ValentineRoseTopList_Present_BonusAction2[i]:SetActionItem(theAction:GetID())
					g_ValentineRoseTopList_Present_BonusAction2[i]:Show()
				end
				if sendBonus[nBonusRank].preview == 2 then
					g_ValentineRoseTopList_Present_BonusPreview2[i]:Show();
				end
			end
			
			if sendBonus[nBonusRank].itemId3 > 0 then
				local theAction = DataPool:CreateActionItemForShow(sendBonus[nBonusRank].itemId3, 1);
				if theAction:GetID() ~= 0 then
					g_ValentineRoseTopList_Present_BonusAction3[i]:SetActionItem(theAction:GetID())
					g_ValentineRoseTopList_Present_BonusAction3[i]:Show();
				end
				if sendBonus[nBonusRank].preview == 3 then
					g_ValentineRoseTopList_Present_BonusPreview3[i]:Show();
				end
			end
			
		end
	end
	
end

function ValentineRoseTopList_Present_ShowSelfRank()
	
	g_ValentineRoseTopList_SelfPresentRank = 0;
	local szSelfName = Player:GetName();
	local szSelfGuid = GetSelfGUID();
	local nSelfSendNum =  DataPool:GetPlayerMission_DataRound(g_ValentineRoseTopList_Info[g_ValentineRoseTopList_FlowerSubPage].sendmd)
	local sendBonus = g_ValentineRoseTopList_SendBonus[g_ValentineRoseTopList_FlowerSubPage];
	
	for i=1, g_ValentineRoseTopList_Ranking_Count do
		
		local index,name,score,isGetBonus,szGuid = DataPool:Lua_GetRoseSendTopListInfo(i-1)
		if index ~= nil and index >= 0 and szGuid ~= "" then
			if szGuid == szSelfGuid and nSelfSendNum == score then
				g_ValentineRoseTopList_SelfPresentRank = i;
			end
		end
	end
	
	-- 玩家自己的送花信息
	if g_ValentineRoseTopList_SelfPresentRank > 0 and ValentineRoseTopList_RankingImage[g_ValentineRoseTopList_SelfPresentRank] ~= nil then
		ValentineRoseTopList_Present_Me_Top1_Num_Icon:SetProperty("Image", ValentineRoseTopList_RankingImage[g_ValentineRoseTopList_SelfPresentRank])
		ValentineRoseTopList_Present_Me_Top1_Num_Icon:Show();
		ValentineRoseTopList_Present_Me_Top1_Lost:Hide();
	else
		ValentineRoseTopList_Present_Me_Top1_Lost:SetText( "#{MGCQ_211130_94}" );
		ValentineRoseTopList_Present_Me_Top1_Num_Icon:Hide();
		ValentineRoseTopList_Present_Me_Top1_Lost:Show();
	end
	ValentineRoseTopList_Present_Me_Top1_Name:SetText( ScriptGlobal_Format("#{MGCQ_211130_10}", szSelfName ) );
	ValentineRoseTopList_Present_Me_Top1_Count:SetText( ScriptGlobal_Format("#{MGCQ_211130_11}", tostring(nSelfSendNum)) );
	ValentineRoseTopList_Present_Me_Item_Button1:Hide();
	ValentineRoseTopList_Present_Me_Item_Button2:Hide();
	ValentineRoseTopList_Present_Me_Item_Button3:Hide();
	ValentineRoseTopList_Present_Me_Item_Preview1:Hide();
	ValentineRoseTopList_Present_Me_Item_Preview2:Hide();
	ValentineRoseTopList_Present_Me_Item_Preview3:Hide();
	
	local nSelfPresentBonusRank = ValentineRoseTopList_ConvertToBonusRank( g_ValentineRoseTopList_SelfPresentRank )
	if sendBonus[nSelfPresentBonusRank] ~= nil then
		if sendBonus[nSelfPresentBonusRank].itemId1 > 0 then
			local theAction = DataPool:CreateActionItemForShow(sendBonus[nSelfPresentBonusRank].itemId1, 1);
			if theAction:GetID() ~= 0 then
				ValentineRoseTopList_Present_Me_Item_Button1:SetActionItem(theAction:GetID())
				ValentineRoseTopList_Present_Me_Item_Button1:Show();
			end
			if sendBonus[nSelfPresentBonusRank].preview == 1 then
				ValentineRoseTopList_Present_Me_Item_Preview1:Show();
			end
		end
			
		if sendBonus[nSelfPresentBonusRank].itemId2 > 0 then
			local theAction = DataPool:CreateActionItemForShow(sendBonus[nSelfPresentBonusRank].itemId2, 1);
			if theAction:GetID() ~= 0 then
				ValentineRoseTopList_Present_Me_Item_Button2:SetActionItem(theAction:GetID())
				ValentineRoseTopList_Present_Me_Item_Button2:Show();
			end
			if sendBonus[nSelfPresentBonusRank].preview == 2 then
				ValentineRoseTopList_Present_Me_Item_Preview2:Show();
			end
		end
		
		if sendBonus[nSelfPresentBonusRank].itemId3 > 0 then
			local theAction = DataPool:CreateActionItemForShow(sendBonus[nSelfPresentBonusRank].itemId3, 1);
			if theAction:GetID() ~= 0 then
				ValentineRoseTopList_Present_Me_Item_Button3:SetActionItem(theAction:GetID())
				ValentineRoseTopList_Present_Me_Item_Button3:Show();
			end
			if sendBonus[nSelfPresentBonusRank].preview == 3 then
				ValentineRoseTopList_Present_Me_Item_Preview3:Show();
			end
		end
	end
end

function ValentineRoseTopList_Receive_ShowRank()
	--显示送花榜单
	local strDefName = ValentineRoseTopList_Rank_DefaultName()
	local receiveBonus = g_ValentineRoseTopList_ReceiveBonus[g_ValentineRoseTopList_FlowerSubPage];
	ValentineRoseTopList_Receive_CurrentlyPage:SetText( ScriptGlobal_Format("#{MGCQ_211130_71}", g_ValentineRoseTopList_ReceiveRanking_CurPage+1 ) );
	--上一页
	if g_ValentineRoseTopList_ReceiveRanking_CurPage > 0 then
		ValentineRoseTopList_Receive_UpPage:Enable();
	else
		ValentineRoseTopList_Receive_UpPage:Disable();
	end
	--下一页
	if (g_ValentineRoseTopList_ReceiveRanking_CurPage+1) * g_ValentineRoseTopList_Ranking_CountPerPage < g_ValentineRoseTopList_Ranking_Count then
		ValentineRoseTopList_Receive_DownPage:Enable();
	else
		ValentineRoseTopList_Receive_DownPage:Disable();
	end
	ValentineRoseTopList_Ranking_GetAward2:SetToolTip( g_ValentineRoseTopList_Info[g_ValentineRoseTopList_FlowerSubPage].szReceiveBonusTip )  
	
	for i=1, g_ValentineRoseTopList_Ranking_CountPerPage do
		local nRank = g_ValentineRoseTopList_Ranking_CountPerPage * g_ValentineRoseTopList_ReceiveRanking_CurPage + i;
	
		g_ValentineRoseTopList_Receive_Num[i]:SetProperty("Image", ValentineRoseTopList_RankingImage[nRank])
		
		--更新数据
		local index,name,score,isGetBonus,szGuid = DataPool:Lua_GetRoseReceiveTopListInfo(nRank-1)
		if index ~= nil and index >= 0 and name ~= "" then
			g_ValentineRoseTopList_Receive_Name[i]:SetText( ScriptGlobal_Format("#{MGCQ_211130_10}", name ) )
			local scoreStr = ScriptGlobal_Format("#{MGCQ_211130_11}", tostring(score))
			g_ValentineRoseTopList_Receive_Score[i]:SetText(scoreStr)
		else
			--初始化默认值
			g_ValentineRoseTopList_Receive_Name[i]:SetText(strDefName)--“虚位以待”或者“未能决出”
			local scoreStr = ScriptGlobal_Format("#{MGCQ_211130_11}", " ")
			g_ValentineRoseTopList_Receive_Score[i]:SetText(scoreStr)
		end
		
		--奖励
		local nBonusRank = ValentineRoseTopList_ConvertToBonusRank( nRank )
		if receiveBonus[nBonusRank] ~= nil then
			if receiveBonus[nBonusRank].itemId1 > 0 then
				local theAction = DataPool:CreateActionItemForShow(receiveBonus[nBonusRank].itemId1, 1);
				if theAction:GetID() ~= 0 then
					g_ValentineRoseTopList_Receive_BonusAction1[i]:SetActionItem(theAction:GetID())
					g_ValentineRoseTopList_Receive_BonusAction1[i]:Show();
				end
				
				if receiveBonus[nBonusRank].preview == 1 then
					g_ValentineRoseTopList_Receive_BonusPreview1[i]:Show();
				end
			end
			
			if receiveBonus[nBonusRank].itemId2 > 0 then
				local theAction = DataPool:CreateActionItemForShow(receiveBonus[nBonusRank].itemId2, 1);
				if theAction:GetID() ~= 0 then
					g_ValentineRoseTopList_Receive_BonusAction2[i]:SetActionItem(theAction:GetID())
					g_ValentineRoseTopList_Receive_BonusAction2[i]:Show();
				end
				
				if receiveBonus[nBonusRank].preview == 2 then
					g_ValentineRoseTopList_Receive_BonusPreview2[i]:Show();
				end
			end
			
			if receiveBonus[nBonusRank].itemId3 > 0 then
				local theAction = DataPool:CreateActionItemForShow(receiveBonus[nBonusRank].itemId3, 1);
				if theAction:GetID() ~= 0 then
					g_ValentineRoseTopList_Receive_BonusAction3[i]:SetActionItem(theAction:GetID())
					g_ValentineRoseTopList_Receive_BonusAction3[i]:Show();
				end
				
				if receiveBonus[nBonusRank].preview == 3 then
					g_ValentineRoseTopList_Receive_BonusPreview3[i]:Show();
				end
			end
			
		end
		
	end
	
end

function ValentineRoseTopList_Receive_ShowSelfRank()
	
	g_ValentineRoseTopList_SelfReceiveRank = 0;
	local szSelfName = Player:GetName();
	local szSelfGuid = GetSelfGUID();
	local nSelfReceiveNum = DataPool:GetPlayerMission_DataRound(g_ValentineRoseTopList_Info[g_ValentineRoseTopList_FlowerSubPage].receivemd)
	local receiveBonus = g_ValentineRoseTopList_ReceiveBonus[g_ValentineRoseTopList_FlowerSubPage];

	for i=1, g_ValentineRoseTopList_Ranking_Count do
		
		local index,name,score,isGetBonus,szGuid = DataPool:Lua_GetRoseReceiveTopListInfo(i-1)
		if index ~= nil and index >= 0 and szGuid ~= "" then
			if szGuid == szSelfGuid and nSelfReceiveNum == score then
				g_ValentineRoseTopList_SelfReceiveRank = i;
			end
		end
	end
	
	-- 玩家自己的收花信息
	if g_ValentineRoseTopList_SelfReceiveRank > 0 and ValentineRoseTopList_RankingImage[g_ValentineRoseTopList_SelfReceiveRank] ~= nil then
		ValentineRoseTopList_Receive_Me_Top1_Num_Icon:SetProperty("Image", ValentineRoseTopList_RankingImage[g_ValentineRoseTopList_SelfReceiveRank])
		ValentineRoseTopList_Receive_Me_Top1_Num_Icon:Show();
		ValentineRoseTopList_Receive_Me_Top1_Lost:Hide();
	else
		ValentineRoseTopList_Receive_Me_Top1_Lost:SetText( "#{MGCQ_211130_94}" );
		ValentineRoseTopList_Receive_Me_Top1_Num_Icon:Hide();
		ValentineRoseTopList_Receive_Me_Top1_Lost:Show();
	end

	ValentineRoseTopList_Receive_Me_Top1_Name:SetText( ScriptGlobal_Format("#{MGCQ_211130_10}", szSelfName ) );
	ValentineRoseTopList_Receive_Me_Top1_Count:SetText( ScriptGlobal_Format("#{MGCQ_211130_11}", tostring(nSelfReceiveNum)) );
	ValentineRoseTopList_Receive_Me_Item_Button1:Hide();
	ValentineRoseTopList_Receive_Me_Item_Button2:Hide();
	ValentineRoseTopList_Receive_Me_Item_Button3:Hide();
	ValentineRoseTopList_Receive_Me_Item_Preview1:Hide();
	ValentineRoseTopList_Receive_Me_Item_Preview2:Hide();
	ValentineRoseTopList_Receive_Me_Item_Preview3:Hide();
	
	local nSelfReceiveBonusRank = ValentineRoseTopList_ConvertToBonusRank( g_ValentineRoseTopList_SelfReceiveRank )
	if receiveBonus[nSelfReceiveBonusRank] ~= nil then
		if receiveBonus[nSelfReceiveBonusRank].itemId1 > 0 then
			local theAction = DataPool:CreateActionItemForShow(receiveBonus[nSelfReceiveBonusRank].itemId1, 1);
			if theAction:GetID() ~= 0 then
				ValentineRoseTopList_Receive_Me_Item_Button1:SetActionItem(theAction:GetID())
				ValentineRoseTopList_Receive_Me_Item_Button1:Show();
			end
			if receiveBonus[nSelfReceiveBonusRank].preview == 1 then
				ValentineRoseTopList_Receive_Me_Item_Preview1:Show();
			end
		end
			
		if receiveBonus[nSelfReceiveBonusRank].itemId2 > 0 then
			local theAction = DataPool:CreateActionItemForShow(receiveBonus[nSelfReceiveBonusRank].itemId2, 1);
			if theAction:GetID() ~= 0 then
				ValentineRoseTopList_Receive_Me_Item_Button2:SetActionItem(theAction:GetID())
				ValentineRoseTopList_Receive_Me_Item_Button2:Show();
			end
			if receiveBonus[nSelfReceiveBonusRank].preview == 2 then
				ValentineRoseTopList_Receive_Me_Item_Preview2:Show();
			end
		end
		
		if receiveBonus[nSelfReceiveBonusRank].itemId3 > 0 then
			local theAction = DataPool:CreateActionItemForShow(receiveBonus[nSelfReceiveBonusRank].itemId3, 1);
			if theAction:GetID() ~= 0 then
				ValentineRoseTopList_Receive_Me_Item_Button3:SetActionItem(theAction:GetID())
				ValentineRoseTopList_Receive_Me_Item_Button3:Show();
			end
			if receiveBonus[nSelfReceiveBonusRank].preview == 3 then
				ValentineRoseTopList_Receive_Me_Item_Preview3:Show();
			end
		end
		
	end
end

--预览奖励
function ValentineRoseTopList_Present_OnPreview( nType, index )

	--有效性判断
	if g_ValentineRoseTopList_CurPage ~= 1 then
		return
	end
	if g_ValentineRoseTopList_FlowerSubPage < 1 or g_ValentineRoseTopList_FlowerSubPage > 3 then
		return
	end
	
	if nType ~= 1 and nType ~= 2 and nType ~= 3 then
		return
	end
	
	if index < 1 or index > 5 then
		return
	end
	
	local sendBonus = g_ValentineRoseTopList_SendBonus[g_ValentineRoseTopList_FlowerSubPage];
	local nRank = g_ValentineRoseTopList_Ranking_CountPerPage * g_ValentineRoseTopList_PresentRanking_CurPage + index;
	if nRank < 1 or nRank > g_ValentineRoseTopList_Ranking_Count then
		return
	end
	
	local nBonusRank = ValentineRoseTopList_ConvertToBonusRank( nRank )
	local nBonusId = -1;
	if sendBonus[nBonusRank].preview == 1 then
		nBonusId = sendBonus[nBonusRank].itemId1
	elseif sendBonus[nBonusRank].preview == 2 then
		nBonusId = sendBonus[nBonusRank].itemId2
	elseif sendBonus[nBonusRank].preview == 3 then
		nBonusId = sendBonus[nBonusRank].itemId3
	end
	
	if g_ValentineRoseTopList_PreviewInfo[nBonusId] == nil then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, g_ValentineRoseTopList_PreviewInfo[nBonusId].dressId )
		Set_XSCRIPT_Parameter(1, g_ValentineRoseTopList_PreviewInfo[nBonusId].hairId )
		Set_XSCRIPT_Parameter(2, g_ValentineRoseTopList_PreviewInfo[nBonusId].faceId )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

end

function ValentineRoseTopList_Receive_OnPreview( nType, index )
	--有效性判断
	if g_ValentineRoseTopList_CurPage ~= 1 then
		return
	end
	if g_ValentineRoseTopList_FlowerSubPage < 1 or g_ValentineRoseTopList_FlowerSubPage > 3 then
		return
	end
	
	if nType ~= 1 and nType ~= 2 and nType ~= 3 then
		return
	end
	
	if index < 1 or index > 5 then
		return
	end
	
	local receiveBonus = g_ValentineRoseTopList_ReceiveBonus[g_ValentineRoseTopList_FlowerSubPage];
	local nRank = g_ValentineRoseTopList_Ranking_CountPerPage * g_ValentineRoseTopList_ReceiveRanking_CurPage + index;
	if nRank < 1 or nRank > g_ValentineRoseTopList_Ranking_Count then
		return
	end
	
	local nBonusRank = ValentineRoseTopList_ConvertToBonusRank( nRank )
	local nBonusId = -1;
	if receiveBonus[nBonusRank].preview == 1 then
		nBonusId = receiveBonus[nBonusRank].itemId1
	elseif receiveBonus[nBonusRank].preview == 2 then
		nBonusId = receiveBonus[nBonusRank].itemId2
	elseif receiveBonus[nBonusRank].preview == 3 then
		nBonusId = receiveBonus[nBonusRank].itemId3
	end
	
	if g_ValentineRoseTopList_PreviewInfo[nBonusId] == nil then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, g_ValentineRoseTopList_PreviewInfo[nBonusId].dressId )
		Set_XSCRIPT_Parameter(1, g_ValentineRoseTopList_PreviewInfo[nBonusId].hairId )
		Set_XSCRIPT_Parameter(2, g_ValentineRoseTopList_PreviewInfo[nBonusId].faceId )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

end

function ValentineRoseTopList_Present_OnSelfPreview( nType )
	--有效性判断
	if g_ValentineRoseTopList_CurPage ~= 1 then
		return
	end
	if g_ValentineRoseTopList_FlowerSubPage < 1 or g_ValentineRoseTopList_FlowerSubPage > 3 then
		return
	end
	
	if nType ~= 1 and nType ~= 2 and nType ~= 3 then
		return
	end
	
	local sendBonus = g_ValentineRoseTopList_SendBonus[g_ValentineRoseTopList_FlowerSubPage];
	if g_ValentineRoseTopList_SelfPresentRank < 1 or g_ValentineRoseTopList_SelfPresentRank > g_ValentineRoseTopList_Ranking_Count then
		return
	end
	
	local nBonusRank = ValentineRoseTopList_ConvertToBonusRank( g_ValentineRoseTopList_SelfPresentRank )
	local nBonusId = -1;
	if sendBonus[nBonusRank].preview == 1 then
		nBonusId = sendBonus[nBonusRank].itemId1
	elseif sendBonus[nBonusRank].preview == 2 then
		nBonusId = sendBonus[nBonusRank].itemId2
	elseif sendBonus[nBonusRank].preview == 3 then
		nBonusId = sendBonus[nBonusRank].itemId3
	end
	
	if g_ValentineRoseTopList_PreviewInfo[nBonusId] == nil then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, g_ValentineRoseTopList_PreviewInfo[nBonusId].dressId )
		Set_XSCRIPT_Parameter(1, g_ValentineRoseTopList_PreviewInfo[nBonusId].hairId )
		Set_XSCRIPT_Parameter(2, g_ValentineRoseTopList_PreviewInfo[nBonusId].faceId )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function ValentineRoseTopList_Receive_OnSelfPreview( nType )
	--有效性判断
	if g_ValentineRoseTopList_CurPage ~= 1 then
		return
	end
	if g_ValentineRoseTopList_FlowerSubPage < 1 or g_ValentineRoseTopList_FlowerSubPage > 3 then
		return
	end
	
	if nType ~= 1 and nType ~= 2 and nType ~= 3 then
		return
	end
	
	local receiveBonus = g_ValentineRoseTopList_ReceiveBonus[g_ValentineRoseTopList_FlowerSubPage];
	if g_ValentineRoseTopList_SelfReceiveRank < 1 or g_ValentineRoseTopList_SelfReceiveRank > g_ValentineRoseTopList_Ranking_Count then
		return
	end
	
	local nBonusRank = ValentineRoseTopList_ConvertToBonusRank( g_ValentineRoseTopList_SelfReceiveRank )
	local nBonusId = -1;
	if receiveBonus[nBonusRank].preview == 1 then
		nBonusId = receiveBonus[nBonusRank].itemId1
	elseif receiveBonus[nBonusRank].preview == 2 then
		nBonusId = receiveBonus[nBonusRank].itemId2
	elseif receiveBonus[nBonusRank].preview == 3 then
		nBonusId = receiveBonus[nBonusRank].itemId3
	end
	
	if g_ValentineRoseTopList_PreviewInfo[nBonusId] == nil then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, g_ValentineRoseTopList_PreviewInfo[nBonusId].dressId )
		Set_XSCRIPT_Parameter(1, g_ValentineRoseTopList_PreviewInfo[nBonusId].hairId )
		Set_XSCRIPT_Parameter(2, g_ValentineRoseTopList_PreviewInfo[nBonusId].faceId )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function ValentineRoseTopList_QingRenJie_OnPreview(index)
	if index ~= 1 or g_ValentineRoseTopList_Qingrenjie_Bonus[index] == nil then
		return
	end
	
	local nBonusId = g_ValentineRoseTopList_Qingrenjie_Bonus[index].itemid;
	if nBonusId == nil then
		return
	end
	
	if g_ValentineRoseTopList_PreviewInfo[nBonusId] == nil then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, g_ValentineRoseTopList_PreviewInfo[nBonusId].dressId )
		Set_XSCRIPT_Parameter(1, g_ValentineRoseTopList_PreviewInfo[nBonusId].hairId )
		Set_XSCRIPT_Parameter(2, g_ValentineRoseTopList_PreviewInfo[nBonusId].faceId )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--刷新榜单
function ValentineRoseTopList_Ranking_OnUpdate()
	--有效性判断
	if g_ValentineRoseTopList_CurPage ~= 1 then
		return
	end
	if g_ValentineRoseTopList_FlowerSubPage < 1 or g_ValentineRoseTopList_FlowerSubPage > 3 then
		return
	end
	
	ValentineRoseTopList_RankClick_Refresh(g_ValentineRoseTopList_FlowerSubPage)
end

--显示累计奖励
function ValentineRoseTopList_LeiJiAward_Update()

	local nAllSendNum = DataPool:GetPlayerMission_DataRound(g_ValentineRoseTopList_LeiJi_SendMD);
		
	for i=1, table.getn(ValentineRoseTopList_LeiJi_Bonus) do
		g_ValentineRoseTopList_LeiJi_Text1[i]:SetText( ScriptGlobal_Format("#{MGCQ_211130_37}", ValentineRoseTopList_LeiJi_Bonus[i].need) );
		if nAllSendNum >= ValentineRoseTopList_LeiJi_Bonus[i].need then
			local szText = ScriptGlobal_Format( "#{MGCQ_211130_39}", tostring(nAllSendNum), tostring(ValentineRoseTopList_LeiJi_Bonus[i].need) )
			g_ValentineRoseTopList_LeiJi_Text2[i]:SetText( szText );	
			if Pneuma:GetMF(ValentineRoseTopList_LeiJi_Bonus[i].MF) == 0 then
				g_ValentineRoseTopList_LeiJi_Button[i]:Show();
				g_ValentineRoseTopList_LeiJi_Tips[i]:Show();
				g_ValentineRoseTopList_LeiJi_Image[i]:Hide();
			else
				g_ValentineRoseTopList_LeiJi_Button[i]:Hide();
				g_ValentineRoseTopList_LeiJi_Tips[i]:Hide();
				g_ValentineRoseTopList_LeiJi_Image[i]:Show();
			end
		else
			local szText = ScriptGlobal_Format( "#{MGCQ_211130_38}", tostring(nAllSendNum), tostring(ValentineRoseTopList_LeiJi_Bonus[i].need) )
			g_ValentineRoseTopList_LeiJi_Text2[i]:SetText( szText );	
				g_ValentineRoseTopList_LeiJi_Button[i]:Show();
				g_ValentineRoseTopList_LeiJi_Tips[i]:Hide();
				g_ValentineRoseTopList_LeiJi_Image[i]:Hide();
		end
		
		
		local theAction = DataPool:CreateActionItemForShow(ValentineRoseTopList_LeiJi_Bonus[i].itemId, 1)
		if theAction:GetID() ~= 0 then
			g_ValentineRoseTopList_LeiJi_Action[i]:SetActionItem(theAction:GetID())
			g_ValentineRoseTopList_LeiJi_Text3[i]:SetText( "#e010101#cFFFFFF"..tostring(ValentineRoseTopList_LeiJi_Bonus[i].count) );	
		end
	end
	
end

function ValentineRoseTopList_LeiJiAward_OnClicked( index )

	local nCooldown = g_ValentineRoseTopList_Cooldown[6]
		local iCur = FindFriendDataPool:GetTickCount()
		if ( iCur - nCooldown < 1) then
			PushDebugMessage("#{MGCQ_151230_01}")
		  return 0
		end
		g_ValentineRoseTopList_Cooldown[6] = iCur
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "LeiJi_Exchange" )
		Set_XSCRIPT_ScriptID( 891056 )
		Set_XSCRIPT_Parameter(0,index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

--显示小红点
function ValentineRoseTopList_Rank_ShowRedPoint()

	local szSelfName = Player:GetName();
	local presentRedpoint = {[1]=0,[2]=0,[3]=0,};
	local receiveRedpoint = {[1]=0,[2]=0,[3]=0,};
		
	-- 花榜
	for i=1, 3 do
		
		--送花
		if DataPool:Lua_GetRoseIsHaveBonus( (i-1)*2 ) > 0 then
			presentRedpoint[i] = 1;
		end
		
		--收花
		if DataPool:Lua_GetRoseIsHaveBonus( (i-1)*2 + 1 ) > 0 then
			receiveRedpoint[i] = 1;
		end
	end
	
	-- 当前页面小红点
	if g_ValentineRoseTopList_CurPage == 1 then
		if presentRedpoint[g_ValentineRoseTopList_FlowerSubPage] ~= nil and presentRedpoint[g_ValentineRoseTopList_FlowerSubPage] == 1 then
			ValentineRoseTopList_Ranking_GetAward1_Tips:Show();
		else
			ValentineRoseTopList_Ranking_GetAward1_Tips:Hide();
		end			
		
		if receiveRedpoint[g_ValentineRoseTopList_FlowerSubPage] ~= nil and receiveRedpoint[g_ValentineRoseTopList_FlowerSubPage] == 1 then
			ValentineRoseTopList_Ranking_GetAward2_Tips:Show();
		else
			ValentineRoseTopList_Ranking_GetAward2_Tips:Hide();
		end
	end
	
	-- 标题小红点
	local bFlowerPoint = 0
	for i=1, 3 do
		if (presentRedpoint[i] ~= nil and presentRedpoint[i] == 1) or 
			(receiveRedpoint[i] ~= nil and receiveRedpoint[i] == 1 ) then
			g_ValentineRoseTopList_Btn_FlowerPage_Redpoint[i]:Show();
			bFlowerPoint = 1;
		else
			g_ValentineRoseTopList_Btn_FlowerPage_Redpoint[i]:Hide();
		end
	end	
	if bFlowerPoint == 1 then
		ValentineRoseTopList_Top_TopList1_Tips:Show();
	else
		ValentineRoseTopList_Top_TopList1_Tips:Hide();
	end
	
	-- 兑换页面
	ValentineRoseTopList_Ranking_Chiqing_Tips:Hide();
	ValentineRoseTopList_Ranking_Qingren_Tips:Hide();
	ValentineRoseTopList_Ranking_Qingyuan_Tips:Hide();
	ValentineRoseTopList_Top_TopList2_Tips:Hide();

	-- 累计奖励
	ValentineRoseTopList_Top_TopList3_Tips:Hide();
	local nAllSendNum = DataPool:GetPlayerMission_DataRound(g_ValentineRoseTopList_LeiJi_SendMD);
	for i=1, table.getn(ValentineRoseTopList_LeiJi_Bonus) do
		if nAllSendNum >= ValentineRoseTopList_LeiJi_Bonus[i].need then
			if Pneuma:GetMF(ValentineRoseTopList_LeiJi_Bonus[i].MF) == 0 then
				ValentineRoseTopList_Top_TopList3_Tips:Show();
				break
			end
		end
	end
end

--显示默认的名字
function ValentineRoseTopList_Rank_DefaultName()
	local strMsg=""
	
	if g_ValentineRoseTopList_State < 6 then 
		strMsg = "#{MGCQ_151230_21}"
	elseif g_ValentineRoseTopList_State >= 6 then 
		strMsg = "#{MGCQ_151230_22}"	
	end
		
	return strMsg
end

--===============================================
-- 以下为事件响应
--===============================================
--点击关闭
function ValentineRoseTopList_Close_Click()
	--数据清空
	ValentineRoseTopList_Clear()
	--界面隐藏
	this:Hide()
end

--点击页签
function ValentineRoseTopList_Page_Click(index)
	--有效性判断
	if index <= 0 or index > g_ValentineRoseTopList_MaxPage then
		return
	end
	
	local nPage = g_ValentineRoseTopList_CurPage
	g_ValentineRoseTopList_CurPage = index
	
	--页面内容更新 1标示排行榜；2标识兑换；3标识累计奖励；
	if g_ValentineRoseTopList_CurPage == 1 then
		ValentineRoseTopList_Ranking_Frame:Show()	
		ValentineRoseTopList_Exchange_Client:Hide()
		ValentineRoseTopList_Leiji_Client:Hide()
		
		--打开默认页面
		ValentineRoseTopList_RankClick_Refresh(0); 
		
	elseif g_ValentineRoseTopList_CurPage == 2 then
	
		ValentineRoseTopList_Ranking_Frame:Hide()	
		ValentineRoseTopList_Exchange_Client:Show()
		ValentineRoseTopList_Leiji_Client:Hide()
	
		--打开情人结页面
		ValentineRoseTopList_Exchange_Qingrenjie_Update()
		
	elseif g_ValentineRoseTopList_CurPage == 3 then
	
		ValentineRoseTopList_Ranking_Frame:Hide()	
		ValentineRoseTopList_Exchange_Client:Hide()
		ValentineRoseTopList_Leiji_Client:Show()
		
		ValentineRoseTopList_LeiJiAward_Update();
	end
end

--点击刷新
function ValentineRoseTopList_RankClick_Refresh(index)
	--有效性判断
	if g_ValentineRoseTopList_CurPage ~= 1 then
		return 0
	end	
	if index == nil or index < 0 or index > 3 then
		return 0
	end
	
	for i=1, 3 do
		if i ~= index then
			g_ValentineRoseTopList_Btn_FlowerPage[i]:SetCheck(0);
		end
	end
	
	if index > 0 then
		g_ValentineRoseTopList_FlowerSubPage = index
		--判断冷却时间
		local nCooldown = g_ValentineRoseTopList_Cooldown[g_ValentineRoseTopList_FlowerSubPage]
		local iCur = FindFriendDataPool:GetTickCount()
		if ( iCur - nCooldown < g_ValentineRoseTopList_CooldownDur) then
			PushDebugMessage("#{MGCQ_151230_01}")
		  return 0
		end
		g_ValentineRoseTopList_Cooldown[g_ValentineRoseTopList_FlowerSubPage] = iCur
	end
	
	--请求服务器数据
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientAskRoseTopList" )
		Set_XSCRIPT_ScriptID( 891049 )--待修改脚本号：891049
		Set_XSCRIPT_Parameter(0,index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
	return 1
end

--送花点击预览
function ValentineRoseTopList_Present_Zhanshi(index)
	--参数判断
	if index < 1 or index > 3 then
		return
	end
	--显示预览界面
	PushEvent("OPEN_ROSETOPLIST_ZHANSHI",index, g_ValentineRoseTopList_FlowerSubPage)
end

--收花点击预览
function ValentineRoseTopList_Receive_Zhanshi(index)
	--参数判断
	if index < 1 or index > 3 then
		return
	end
	--显示预览界面
	PushEvent("OPEN_ROSETOPLIST_ZHANSHI",index, g_ValentineRoseTopList_FlowerSubPage)
end

--点击送花榜领奖
function ValentineRoseTopList_Prize_Present()
	--有效性判断
	if g_ValentineRoseTopList_CurPage ~= 1 then
		return
	end	
	if g_ValentineRoseTopList_FlowerSubPage < 1 or g_ValentineRoseTopList_FlowerSubPage > 3 then
		return
	end	
		
	--判断领奖时间
	if g_ValentineRoseTopList_State == 0 then--理论上不存在
		PushDebugMessage(g_ValentineRoseTopList_Tip[g_ValentineRoseTopList_FlowerSubPage].tip1)
		return
	elseif g_ValentineRoseTopList_State >= 1 and g_ValentineRoseTopList_State <= 5 then--排行榜计时中
		PushDebugMessage(g_ValentineRoseTopList_Tip[g_ValentineRoseTopList_FlowerSubPage].tip2)
		return
	elseif g_ValentineRoseTopList_State == 6 then--可以领奖
	else--理论上不存在
		PushDebugMessage(g_ValentineRoseTopList_Tip[g_ValentineRoseTopList_FlowerSubPage].tip3)
		return
	end
		
	--判断安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{MGCQ_151230_77}")--在安全时间内无法进行此操作。打开包裹栏，点击防盗号按钮可以自行设置安全时间。
		return
	end
	
	--判断电话密保和二级密码保护
  if CheckPhoneMibaoAndMinorPassword() ~= 1 then	
    return
  end
  
  --参数判断
	if g_ValentineRoseTopList_SelfPresentRank < 1 or g_ValentineRoseTopList_SelfPresentRank > g_ValentineRoseTopList_Ranking_Count then
		PushDebugMessage("#{MGCQ_151230_75}")
		return
	end
	
	--领奖
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientGetRoseSendTopListPrize" )
		Set_XSCRIPT_ScriptID( 891049 )--待修改脚本号：891049
		Set_XSCRIPT_Parameter(0,g_ValentineRoseTopList_FlowerSubPage)
		Set_XSCRIPT_Parameter(1,g_ValentineRoseTopList_SelfPresentRank)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

end

--点击收花榜领奖
function ValentineRoseTopList_Prize_Receive()
	--有效性判断
	if g_ValentineRoseTopList_CurPage ~= 1 then
		return
	end	
	if g_ValentineRoseTopList_FlowerSubPage < 1 or g_ValentineRoseTopList_FlowerSubPage > 3 then
		--PushDebugMessage("当前页签不是排行榜")
		return
	end	
		
	--判断领奖时间
	if g_ValentineRoseTopList_State == 0 then--理论上不存在
		PushDebugMessage(g_ValentineRoseTopList_Tip[g_ValentineRoseTopList_FlowerSubPage].tip1)
		return
	elseif g_ValentineRoseTopList_State >= 1 and g_ValentineRoseTopList_State <= 5 then--排行榜计时中
		PushDebugMessage(g_ValentineRoseTopList_Tip[g_ValentineRoseTopList_FlowerSubPage].tip2)
		return
	elseif g_ValentineRoseTopList_State == 6 then--可以领奖
	else--理论上不存在
		PushDebugMessage(g_ValentineRoseTopList_Tip[g_ValentineRoseTopList_FlowerSubPage].tip3)
		return
	end
	
	--判断安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{MGCQ_151230_77}")--在安全时间内无法进行此操作。打开包裹栏，点击防盗号按钮可以自行设置安全时间。
		return
	end
	
	--判断电话密保和二级密码保护
  if CheckPhoneMibaoAndMinorPassword() ~= 1 then	
    return
  end
  
  if g_ValentineRoseTopList_SelfReceiveRank < 1 or g_ValentineRoseTopList_SelfReceiveRank > g_ValentineRoseTopList_Ranking_Count then
		PushDebugMessage("#{MGCQ_151230_75}")
		return
	end
	
	--领奖
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientGetRoseReceiveTopListPrize" )
		Set_XSCRIPT_ScriptID( 891049 )--待修改脚本号：891049
		Set_XSCRIPT_Parameter(0,g_ValentineRoseTopList_FlowerSubPage)
		Set_XSCRIPT_Parameter(1,g_ValentineRoseTopList_SelfReceiveRank)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

end

--送花榜上一页
function ValentineRoseTopList_Present_PageUp()
	if g_ValentineRoseTopList_PresentRanking_CurPage > 0 then
		g_ValentineRoseTopList_PresentRanking_CurPage = g_ValentineRoseTopList_PresentRanking_CurPage - 1;
	end
	
	ValentineRoseTopList_Rank_ShowTopListPage()
end

--送花榜下一页
function ValentineRoseTopList_Present_PageDown()
	if (g_ValentineRoseTopList_PresentRanking_CurPage+1) * g_ValentineRoseTopList_Ranking_CountPerPage < g_ValentineRoseTopList_Ranking_Count then
		g_ValentineRoseTopList_PresentRanking_CurPage = g_ValentineRoseTopList_PresentRanking_CurPage + 1
	end 
	
	ValentineRoseTopList_Rank_ShowTopListPage();
end

--收花榜上一页
function ValentineRoseTopList_Receive_PageUp()
	if g_ValentineRoseTopList_ReceiveRanking_CurPage > 0 then
		g_ValentineRoseTopList_ReceiveRanking_CurPage = g_ValentineRoseTopList_ReceiveRanking_CurPage - 1;
	end
	
	ValentineRoseTopList_Rank_ShowTopListPage();
end

--收花榜下一页
function ValentineRoseTopList_Receive_PageDown()
	if (g_ValentineRoseTopList_ReceiveRanking_CurPage+1) * g_ValentineRoseTopList_Ranking_CountPerPage < g_ValentineRoseTopList_Ranking_Count then
		g_ValentineRoseTopList_ReceiveRanking_CurPage = g_ValentineRoseTopList_ReceiveRanking_CurPage + 1
	end 
	
	ValentineRoseTopList_Rank_ShowTopListPage();
end

--===============================================
-- 以下为基础函数
--===============================================
--状态清空
function ValentineRoseTopList_Clear()
	--取消按钮的选中状态
 	--if g_ValentineRoseTopList_CurPage >= 1 or g_ValentineRoseTopList_CurPage <= 6 then
 		--g_RoseBtn_Page[g_ValentineRoseTopList_CurPage]:SetCheck(0)
 	--end
 	--当前页码清空
	g_ValentineRoseTopList_CurPage = 0
	g_ValentineRoseTopList_FlowerSubPage = 0
	g_ValentineRoseTopList_ExchangeSubPage = 0
	--活动状态清空
	g_ValentineRoseTopList_State = -1
end

--重置位置
function ValentineRoseTopList_ResetPos()
	ValentineRoseTopList_Frame:SetProperty("UnifiedPosition",g_ValentineRoseTopList_UnifiedPosition)
end


--===============================================
-- 以下为兑换奖励
--===============================================
function ValentineRoseTopList_Exchange_UpdateQingRenJieCount()

	local nQingRenJieCount = DataPool:GetPlayerMission_DataRound(g_ValentineRoseTopList_QingRenJie)
	ValentineRoseTopList_Exchange_ZongText:SetText( ScriptGlobal_Format("#{MGCQ_210107_09}", nQingRenJieCount) )
	
	local nChiQingYuCount = DataPool:GetPlayerMission_DataRound(g_ValentineRoseTopList_ChiQingYu)
	ValentineRoseTopList_Exchange_ChiqingText:SetText( ScriptGlobal_Format("#{MGCQ_220128_11}", nChiQingYuCount) )
	
	local nQingYuanJieCount = DataPool:GetPlayerMission_DataRound(g_ValentineRoseTopList_QingYuanJie)
	ValentineRoseTopList_Exchange_ZongText1:SetText( ScriptGlobal_Format("#{MGCQ_241219_06}", nQingYuanJieCount) )
	
	if g_ValentineRoseTopList_ExchangeSubPage == 0 and g_ValentineRoseTopList_CurPage == 2 then
		for i = 1, table.getn(g_ValentineRoseTopList_Qingrenjie_Bonus) do		
			-- 限量		
			local nLimitNum = g_ValentineRoseTopList_Qingrenjie_Bonus[i].LimitNum
			local nLimitMD = g_ValentineRoseTopList_Qingrenjie_Bonus[i].LimitMD
			if nLimitMD > 0 and nLimitNum > 0 then
				local nExchangeNum =  DataPool:GetPlayerMission_DataRound(nLimitMD)
				local nLastNum = nLimitNum - nExchangeNum
				if nLastNum > 0 then
					ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[i]:Show()
					ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[i]:SetText(tonumber(nLastNum))
				else
					ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[i]:Hide()
					ValentineRoseTopList_Exchange_Qingrenjie_Mark[i]:Show()
				end
			end
		end
	end
	
end

--情人结兑换奖励窗口
function ValentineRoseTopList_Exchange_Qingrenjie_Update()
	g_ValentineRoseTopList_ExchangeSubPage = 0;
	
	ValentineRoseTopList_Exchange_GiftFrame:Show()
	ValentineRoseTopList_Exchange_GiftFrame1:Hide()
	ValentineRoseTopList_Exchange_GiftFrame2:Hide()
	
	ValentineRoseTopList_Ranking_Chiqing:SetCheck(0);
	ValentineRoseTopList_Ranking_Qingren:SetCheck(1);
	ValentineRoseTopList_Ranking_Qingyuan:SetCheck(0);
			
	ValentineRoseTopList_Exchange_Info:SetText( "#{MGCQ_151230_101}" )
	ValentineRoseTopList_Exchange_UpdateQingRenJieCount()
		
	for i = 1, table.getn(g_ValentineRoseTopList_Qingrenjie_Bonus) do
		local theAction = DataPool:CreateActionItemForShow(g_ValentineRoseTopList_Qingrenjie_Bonus[i].itemid, g_ValentineRoseTopList_Qingrenjie_Bonus[i].count)
		if theAction:GetID() ~= 0 then
			ValentineRoseTopList_Exchange_Qingrenjie_Action[i]:SetActionItem(theAction:GetID())
		end
		
		--local itemname = PlayerPackage:GetItemName( g_ValentineRoseTopList_Qingrenjie_Bonus[i].itemid )
		local strName = ScriptGlobal_Format("#{MGCQ_211130_93}", g_ValentineRoseTopList_Qingrenjie_Bonus[i].name)
		ValentineRoseTopList_Exchange_Qingrenjie_Name[i]:SetText( strName )
		
		local strText = ScriptGlobal_Format("#{QRPHB_150113_114}", g_ValentineRoseTopList_Qingrenjie_Bonus[i].neednum)
		local strTips = ScriptGlobal_Format("#{QRPHB_150113_113}", g_ValentineRoseTopList_Qingrenjie_Bonus[i].neednum, g_ValentineRoseTopList_Qingrenjie_Bonus[i].name)
		ValentineRoseTopList_Exchange_Qingrenjie_Text[i]:SetText( strText )
		ValentineRoseTopList_Exchange_Qingrenjie_Text[i]:SetToolTip( strTips )
		
		-- 限量
		ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[i]:Hide()
		ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[i]:Hide()
		ValentineRoseTopList_Exchange_Qingrenjie_Mark[i]:Hide()
		
		local nLimitNum = g_ValentineRoseTopList_Qingrenjie_Bonus[i].LimitNum
		local nLimitMD = g_ValentineRoseTopList_Qingrenjie_Bonus[i].LimitMD
		if nLimitMD > 0 and nLimitNum > 0 then
			ValentineRoseTopList_Exchange_Qingrenjie_LimitImage[i]:Show()
				
			local nExchangeNum =  DataPool:GetPlayerMission_DataRound(nLimitMD)
			local nLastNum = nLimitNum - nExchangeNum
			if nLastNum > 0 then
				ValentineRoseTopList_Exchange_Qingrenjie_LimitBK[i]:Show()
				ValentineRoseTopList_Exchange_Qingrenjie_LimitNum[i]:SetText(tonumber(nLastNum))
			else
				ValentineRoseTopList_Exchange_Qingrenjie_Mark[i]:Show()
			end
		end
	end
	
end

--痴情玉兑换奖励窗口
function ValentineRoseTopList_Exchange_Chiqingyu_Update()
	g_ValentineRoseTopList_ExchangeSubPage = 1;
	
	ValentineRoseTopList_Exchange_GiftFrame:Hide()
	ValentineRoseTopList_Exchange_GiftFrame1:Show()
	ValentineRoseTopList_Exchange_GiftFrame2:Hide()
	
	ValentineRoseTopList_Ranking_Chiqing:SetCheck(1);
	ValentineRoseTopList_Ranking_Qingren:SetCheck(0);
	ValentineRoseTopList_Ranking_Qingyuan:SetCheck(0);
		
	ValentineRoseTopList_Exchange_Info:SetText( "#{MGCQ_151230_105}" )
	
	for i = 1, table.getn(g_ValentineRoseTopList_Chiqingyu_Bonus) do
		local theAction = DataPool:CreateActionItemForShow(g_ValentineRoseTopList_Chiqingyu_Bonus[i].itemid, g_ValentineRoseTopList_Chiqingyu_Bonus[i].count)
		if theAction:GetID() ~= 0 then
			ValentineRoseTopList_Exchange_Chiqingyu_Action[i]:SetActionItem(theAction:GetID())
		end
		
		local MySex =Player:GetMySex()
		local itemname
		if MySex == 0 and i > 8 then
			itemname = g_ValentineRoseTopList_Chiqingyu_Bonus[i].namewoman
		elseif MySex == 1 and i > 8 then
			itemname = g_ValentineRoseTopList_Chiqingyu_Bonus[i].name
		else
			itemname = PlayerPackage:GetItemName( g_ValentineRoseTopList_Chiqingyu_Bonus[i].itemid )
		end
		
		local strName = ScriptGlobal_Format("#{MGCQ_211130_93}", itemname)
		ValentineRoseTopList_Exchange_Chiqingyu_Name[i]:SetText( strName );
		
		local strText = ScriptGlobal_Format("#{QRPHB_150113_119}", g_ValentineRoseTopList_Chiqingyu_Bonus[i].neednum)
		local strTips = ScriptGlobal_Format("#{QRPHB_150113_118}", g_ValentineRoseTopList_Chiqingyu_Bonus[i].neednum, itemname)
		ValentineRoseTopList_Exchange_Chiqingyu_Text[i]:SetText( strText )
		ValentineRoseTopList_Exchange_Chiqingyu_Text[i]:SetToolTip( strTips )
	end
	
end

--情缘结兑换奖励窗口
function ValentineRoseTopList_Exchange_Qingyuanjie_Update()
		g_ValentineRoseTopList_ExchangeSubPage = 1;
	
	ValentineRoseTopList_Exchange_GiftFrame:Hide()
	ValentineRoseTopList_Exchange_GiftFrame1:Hide()
	ValentineRoseTopList_Exchange_GiftFrame2:Show()
	
	ValentineRoseTopList_Ranking_Chiqing:SetCheck(0);
	ValentineRoseTopList_Ranking_Qingren:SetCheck(0);
	ValentineRoseTopList_Ranking_Qingyuan:SetCheck(1);
		
	ValentineRoseTopList_Exchange_Info:SetText( "#{MGCQ_241219_01}" )
	
	for i = 1, table.getn(g_ValentineRoseTopList_Qingyuanjie_Bonus) do
		local theAction = DataPool:CreateActionItemForShow(g_ValentineRoseTopList_Qingyuanjie_Bonus[i].itemid, g_ValentineRoseTopList_Qingyuanjie_Bonus[i].count)
		if theAction:GetID() ~= 0 then
			ValentineRoseTopList_Exchange_Qingyuanjie_Action[i]:SetActionItem(theAction:GetID())
		end
		
		local strName = ScriptGlobal_Format("#{MGCQ_211130_93}", g_ValentineRoseTopList_Qingyuanjie_Bonus[i].name)
		ValentineRoseTopList_Exchange_Qingyuanjie_Name[i]:SetText( strName )
		
		local strText = ScriptGlobal_Format("#{MGCQ_241219_03}", g_ValentineRoseTopList_Qingyuanjie_Bonus[i].neednum)
		local strTips = ScriptGlobal_Format("#{MGCQ_241219_05}", g_ValentineRoseTopList_Qingyuanjie_Bonus[i].neednum, g_ValentineRoseTopList_Qingyuanjie_Bonus[i].name)
		ValentineRoseTopList_Exchange_Qingyuanjie_Text[i]:SetText( strText )
		ValentineRoseTopList_Exchange_Qingyuanjie_Text[i]:SetToolTip( strTips )
		
		ValentineRoseTopList_Exchange_Qingyuanjie_Action[i]:Show();
		ValentineRoseTopList_Exchange_Qingyuanjie_Name[i]:Show();
		ValentineRoseTopList_Exchange_Qingyuanjie_Text[i]:Show();
	end
	for i=table.getn(g_ValentineRoseTopList_Qingyuanjie_Bonus)+1, 16 do
		ValentineRoseTopList_Exchange_Qingyuanjie_Action[i]:Hide();
		ValentineRoseTopList_Exchange_Qingyuanjie_Name[i]:Hide();
		ValentineRoseTopList_Exchange_Qingyuanjie_Text[i]:Hide();
	end
	
	--ValentineRoseTopList_ExchangeFrame_Page:Hide();
end

--情人结兑换奖励
function ValentineRoseTopList_Exchange_Qingrenjie_Click(i)
	local str = ScriptGlobal_Format("#{MGCQ_151230_177}", g_ValentineRoseTopList_Qingrenjie_Bonus[i].neednum, g_ValentineRoseTopList_Qingrenjie_Bonus[i].name)
	PushEvent("ROSERANK_EXCHANGE_CONFIRM", 1, i, str)
end

--痴情玉兑换奖励
function ValentineRoseTopList_Exchange_Chiqingyu_Click(i)
	local MySex =Player:GetMySex()
	local itemname
	if MySex == 0 and i > 8 then
		itemname = g_ValentineRoseTopList_Chiqingyu_Bonus[i].namewoman
	elseif MySex == 1 and i > 8 then
		itemname = g_ValentineRoseTopList_Chiqingyu_Bonus[i].name
	else
		itemname = PlayerPackage:GetItemName( g_ValentineRoseTopList_Chiqingyu_Bonus[i].itemid )
	end
	
	local str = ScriptGlobal_Format("#{MGCQ_151230_178}", g_ValentineRoseTopList_Chiqingyu_Bonus[i].neednum, itemname)
	PushEvent("ROSERANK_EXCHANGE_CONFIRM", 2, i, str)
end

--情缘结兑换奖励
function ValentineRoseTopList_Exchange_Xiangsijie_Click(i)
	local str = ScriptGlobal_Format("#{MGCQ_241219_10}", g_ValentineRoseTopList_Qingyuanjie_Bonus[i].neednum, g_ValentineRoseTopList_Qingyuanjie_Bonus[i].name)
	PushEvent("ROSERANK_EXCHANGE_CONFIRM", 3, i, str)
end

--打开元宝商店——花舞人间——春城百花
function ValentineRoseTopList_BuyRose()
	ValentineRoseTopList_Shop_Goto(0, 6, 5)
end

function ValentineRoseTopList_Shop_Goto(Fenye, Tag, Shop)
	if(IsWindowShow("YuanbaoShop")) then
		CloseWindow("YuanbaoShop", true)
	end
	PushEvent("TOGGLE_YUANBAOSHOP", Fenye, -1, -1, Tag, Shop)
end

function ValentineRoseTopList_ConvertToBonusRank( nRank )
	local nBonusRank = nRank
	if nRank >=4 and nRank <=10 then
		nBonusRank = 4;
	elseif nRank >=11 and nRank <=20 then
		nBonusRank = 5;
	end	
	return nBonusRank	
end




