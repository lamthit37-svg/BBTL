--	Fight	Score

local g_myContentButton = {}
local g_myCurrentSelect = 1
local g_myRightButton = {}
local g_ChildWindow = {}
local g_ChildWindowBK = {}

--	宝石标准等级
--	一切的一切，都是从这里开始----
local g_ScoreBaseParam = 3;
local g_FightScoreRightList;
local g_FightScore_EquipMax = 18;	--	玩家身上装备数量
local g_FightScore_BaseLevelUpParam = 80;	--	是否提升宝石标准等级阀值，大于等于此值时，宝石标准等级(g_ScoreBaseParam)做加1操作，并重新计算
local g_FightScore_GemTotalScore = 0;		--	所有装备总分
local g_FightScore_EquipTotalScore = 0 --装备栏
local g_FightScore_KeMingTotalScore = 0 --刻铭栏
local g_FightScore_FuTiTotalScore = 0 --附体栏
local g_FightScore_WuHunTotalScore = 0 --武魂栏
local g_FightScore_JingTongScore = 0 --精通栏
local g_FightScore_ZhenYuanScore = 0 --真元栏
local g_FightScore_LingPaiScore = 0 --令牌栏
local g_FightScore_XiaYinScore = 0 --侠印栏
local g_FightScore_MartialScore = 0 --武意
local g_FightScore_XingZhenScore =0
local g_FightScore_XingJuanCollectionScore = {0, 0, 0, 0}
local g_FightScore_SkillCardCollectionScore = {0, 0, 0, 0}
local g_FightScore_UnderArmourTotalScore = 0
local g_FightScore_UnderArmourScore = {0, 0, 0}
local g_FightScore_UnderArmourJewelScore = {0, 0, 0}
local g_FightScore_UnderArmourPlateScore = {0, 0, 0}
local g_FightScore_ZongMenEquipTotalScore = 0
local g_FightScore_GemStdParam = g_ScoreBaseParam	--	宝石推荐标准参数
local g_FightScore_CurGemLevel = 0
local g_FightScore_PlayLevel_STL =0 
local g_FightScore_UnifiedPosition;
--宝石分页界面：最左边的装备位背景图
--17个装备位的背景图
local image_right_1 = {
	[1] = {back="set:UIIcons image:Equip_Weapon",index=0,name="#{PFZY_140613_20}",gemConIndex=0},    --武器
	[2] = {back="set:UIIcons image:Equip_Cap",index=1,name="#{PFZY_140613_21}",gemConIndex=1, ZhenYuanIndex = 10 },       --帽子
	[3] = {back="set:UIIcons image:Equip_Sash",index=5,name="#{PFZY_140613_22}",gemConIndex=5, ZhenYuanIndex = 7 },      --腰带
	[4] = {back="set:UIIcons image:Equip_Shot",index=4,name="#{PFZY_140613_23}",gemConIndex=4, ZhenYuanIndex = 9 },      --鞋
	[5] = {back="set:UIIcons image:Equip_Ring",index=6,name="#{PFZY_140613_24}",gemConIndex=6, ZhenYuanIndex = 1 },	     --戒指1
	[6] = {back="set:UIIcons image:Equip_Ring",index=11,name="#{PFZY_140613_25}",gemConIndex=8, ZhenYuanIndex = 2 },     --戒指2
	[7] = {back="set:UIIcons image:Equip_Pifeng",index=12,name="#{PFZY_140613_26}",gemConIndex=9, ZhenYuanIndex = 4 },   --护符1
	[8] = {back="set:UIIcons image:Equip_Pifeng",index=13,name="#{PFZY_140613_27}",gemConIndex=10, ZhenYuanIndex = 5 },  --护符2
	[9] = {back="set:UIIcons image:Equip_Wrist",index=14,name="#{PFZY_140613_28}",gemConIndex=11, ZhenYuanIndex = 3 },   --护腕
	[10] = {back="set:UIIcons image:Equip_Hand",index=3,name="#{PFZY_140613_29}",gemConIndex=3, ZhenYuanIndex = 8 },     --手套
	[11] = {back="set:UIIcons image:Equip_Nacket",index=7,name="#{PFZY_140613_30}",gemConIndex=7, ZhenYuanIndex = 0 },   --项链
	[12] = {back="set:UIIcons image:Equip_Armo",index=2,name="#{PFZY_140613_31}",gemConIndex=2, ZhenYuanIndex = 6 },     --衣服
	[13] = {back="set:UIIcons image:Equip_Shoulder",index=15,name="#{PFZY_140613_32}",gemConIndex=12, ZhenYuanIndex = 11 }, -- 护肩
	[14] = {back="set:UIIcons image:Equip_Anqi",index=17,name="#{PFZY_140613_33}",gemConIndex=13},     --暗器
	[15] = {back="set:CommonFrame7 image:WuhunEquip",index=18,name="#{PFZY_140613_34}",gemConIndex=14},--武魂
	[16] = {back="set:MiniMap image:LongWen",index=19,name="#{PFZY_140613_35}",gemConIndex=15},        --龙纹
	[17] = {back="set:UIIcons image:Equip_LingPai",index=20,name="#{PFZY_140613_36}",gemConIndex=16},  --令牌
    [18] = {back="set:JunXian_04 image:JunXian_Equip",index=21,name="#{HXYSJ_141031_21}",gemConIndex=17}, --侠印
--	[19] = {back="set:ZongMenSkill image:ZongMenSkill_ItemBK",index=23,name="#{PFZY_230830_17}",gemConIndex=18}, --宗门装备
}

--记录按钮是否可以点击：1，可以；0，不可以。
local Button_Left = {
}

local m_ButtonIndexMap = {
}


local g_Equip_TypeList =
{
	[1]  = { gemConIndex=0,  equipIndex=0,  },    --- 武器
	[2]  = { gemConIndex=1,  equipIndex=1,  },    --- 帽子
	[3]  = { gemConIndex=5,  equipIndex=5,  },    --- 腰带
	[4]  = { gemConIndex=4,  equipIndex=4,  },    --- 鞋子
	[5]  = { gemConIndex=6,  equipIndex=6,  },    --- 戒指（上）
	[6]  = { gemConIndex=8,  equipIndex=11, },    --- 戒指（下）
	[7]  = { gemConIndex=9,  equipIndex=12, },    --- 护符（上）
	[8]  = { gemConIndex=10, equipIndex=13, },    --- 护符（下）
	[9]  = { gemConIndex=11, equipIndex=14, },    --- 护腕
	[10] = { gemConIndex=3,  equipIndex=3,  },    --- 手套
	[11] = { gemConIndex=7,  equipIndex=7,  },    --- 项链
	[12] = { gemConIndex=2,  equipIndex=2,  },    --- 衣服
	[13] = { gemConIndex=12, equipIndex=15, },    --- 肩膀
	[14] = { gemConIndex=13, equipIndex=17, },    --- 暗器
	[15] = { gemConIndex=14, equipIndex=18, },    --- 武魂
	[16] = { gemConIndex=15, equipIndex=19, },    --- 龙纹
	[17] = { gemConIndex=16, equipIndex=20, },    --- 令牌
	[18] = { gemConIndex=17, equipIndex=21, },    --- 豪侠印
	[19] = { gemConIndex=18, equipIndex=23, },    --- 宗门信物
}

--*****************************************************************************
--
--	宝石评分相关部分
--
--	宝石标准评分表
local g_GemLevelScore_Std_List =
{
	[3] = 420,
	[4] = 2138,
	[5] = 11088,
	[6] = 48000,
	[7] = 240398,
	[8] = 961990,
	[9] = 961990,
}
--	每个装备上的宝石分值,-1表示未打孔或没有装备，0分表示没有镶嵌宝石
local g_FightScore_GemRealScore_Map = {}

--*****************************************************************************
--
--	雕文评分部分
--
--	雕文标准评分表
--	索引值为宝石标准等级
local g_FightScore_DiaoWenScore_Std_List =
{
	[3] = {stdLevel=3, stdScore=865, stdScore2=550},
	[4] = {stdLevel=4, stdScore=2615, stdScore2=865},
	[5] = {stdLevel=6, stdScore=11435, stdScore2=5660},
	[6] = {stdLevel=8, stdScore=49760, stdScore2=21375},
	[7] = {stdLevel=10, stdScore=247790, stdScore2=122840},
	[8] = {stdLevel=10, stdScore=247790, stdScore2=122840},
	[9] = {stdLevel=10, stdScore=247790, stdScore2=122840},
}

--	装备雕文真实分值表
local g_FightScore_DiaoWenRealScore_Map = {}
--	装备雕文总分
local g_FightScore_DiaoWenTotalScore = 0;

--*****************************************************************************
--
--	龙纹评分部分
--
--	龙纹标准评分表
--	索引值为宝石标准等级
--	龙纹标准等级、标准星级、标准扩展属性等级
local g_FightScore_LongWenScore_Std_List =
{
	[3] = {stdLevel=40, stdQua=4, stdExtraAttLevel=4},
	[4] = {stdLevel=70, stdQua=6, stdExtraAttLevel=7},
	[5] = {stdLevel=100, stdQua=7, stdExtraAttLevel=9},
	[6] = {stdLevel=100, stdQua=8, stdExtraAttLevel=10},
	[7] = {stdLevel=100, stdQua=8, stdExtraAttLevel=10},
	[8] = {stdLevel=100, stdQua=8, stdExtraAttLevel=10},
	[9] = {stdLevel=100, stdQua=8, stdExtraAttLevel=10},
}
--	龙纹等级对应分值
local g_FightScore_LongWenScore_Level_List =
{
	[1]  = 100,   [2]  = 200,   [3]  = 300,   [4]  = 400,   [5]  = 500,   [6]  = 600,   [7]  = 700,   [8]  = 800,   [9]  = 900,   [10]  = 1100,
	[11] = 1300,  [12] = 1500,  [13] = 1700,  [14] = 1900,  [15] = 2100,  [16] = 2300,  [17] = 2500,  [18] = 2700,  [19] = 2900,  [20]  = 3200,
	[21] = 3500,  [22] = 3800,  [23] = 4100,  [24] = 4400,  [25] = 4700,  [26] = 5000,  [27] = 5300,  [28] = 5600,  [29] = 5900,  [30]  = 6400,
	[31] = 6900,  [32] = 7400,  [33] = 7900,  [34] = 8400,  [35] = 8900,  [36] = 9400,  [37] = 9900,  [38] = 10400, [39] = 10900, [40]  = 11700,
	[41] = 12500, [42] = 13300, [43] = 14100, [44] = 14900, [45] = 15700, [46] = 16500, [47] = 17300, [48] = 18100, [49] = 18900, [50]  = 20200,
	[51] = 21500, [52] = 22800, [53] = 24100, [54] = 25400, [55] = 26700, [56] = 28000, [57] = 29300, [58] = 30600, [59] = 31900, [60]  = 34000,
	[61] = 36100, [62] = 38200, [63] = 40300, [64] = 42400, [65] = 44500, [66] = 46600, [67] = 48700, [68] = 50800, [69] = 52900, [70]  = 56300,
	[71] = 59700, [72] = 63100, [73] = 66500, [74] = 69900, [75] = 73300, [76] = 76700, [77] = 80100, [78] = 83500, [79] = 86900, [80]  = 92400,
	[81] = 97900, [82] = 103400,[83] = 108900,[84] = 114400,[85] = 119900,[86] = 125400,[87] = 130900,[88] = 136400,[89] = 141900,[90]  = 150800,
	[91] = 159700,[92] = 168600,[93] = 177500,[94] = 186400,[95] = 195300,[96] = 204200,[97] = 213100,[98] = 222000,[99] = 230900,[100] = 239800,
}
--	龙纹星级对应分值
local g_FightScore_LongWenScore_Qua_list =
{
	[1] = 100,
	[2] = 420,
	[3] = 2010,
	[4] = 5200,
	[5] = 10800,
	[6] = 20000,
	[7] = 28800,
	[8] = 32000,
	[9] = 50000,
}
--	龙纹扩展属性对应分值
local g_FightScore_LongWenScore_ExAtt_List =
{
	[0]  = 0,
	[1]  = 200,
	[2]  = 4200,
	[3]  = 10200,
	[4]  = 20200,
	[5]  = 34200,
	[6]  = 52200,
	[7]  = 76200,
	[8]  = 106200,
	[9]  = 142200,
	[10] = 182200,
}

--	图标物品ID
--	20310176		--	玉龙髓				星级
--	20310181		--	缀龙石·元			血上限
--	20310182		--	缀龙石·暴			减抗
--	20310183		--	缀龙石·伤			属性攻
--
--
--
--	龙纹实际评分表	1、等级；2、星级、3~5扩展属性
local g_FightScore_LongWenScore_RealMap = {}
--	龙纹总分
local g_FightScore_LongWenScore_Total = 0

--**********************************************************************************
--
--	暗器评分
--
--	标准品阶表
local g_FightScore_DarkScore_StdQuality_List =
{
	[3] = 2,
	[4] = 3,
	[5] = 4,
	[6] = 5,
	[7] = 5,
	[8] = 5,
	[9] = 5,
}
--
local g_FightScore_DarkScore_Quality_List =
{
	[1] = {qua=40, str="#{ZSKSSJ_PT}", param=20},			--	普通
	[2] = {qua=80, str="#{ZSKSSJ_YX}", param=40},			--	优秀
	[3] = {qua=120, str="#{ZSKSSJ_JC}", param=60},			--	杰出
	[4] = {qua=160, str="#{ZSKSSJ_ZY}", param=80},			--	卓越
	[5] = {qua=200, str="#{ZSKSSJ_WM}", param=100},			--	完美
}
--
--	装备等级标准表
local g_FightScore_DarkScore_Level_List =
{
	--	推荐暗器名称	推荐暗器的玩家等级+百兵精通等级,只要比这个小,一律都是这个
	[1] = {name = "飞蝗石", level = 75, needlevel = 30, param = 10},
	[2] = {name = "梅花镖", level = 90, needlevel = 50, param = 50},
	[3] = {name = "冰魄神针", level = 120, needlevel = 70, param = 100},
	[4] = {name = "金翅翎羽", level = 120, needlevel = 90, param = 250},
}
--
local g_FightScore_DarkScore_RealMap =
{
	[1] = {score = -1, nIndex = 0, nIndexStd = 0},
	[2] = {score = -1, nIndex = 0, nIndexStd = 0},
	[3] = {score = -1, nIndex = 0, nIndexStd = 0},
	[4] = {score = -1, nIndex = 0, nIndexStd = 0},
	[5] = {score = -1, nIndex = 0, nIndexStd = 0},
	[6] = {score = -1, nIndex = 0, nIndexStd = 0},
}
--
--金翅翎羽暗器星级推荐表
--根据角色装备最大石头等级推荐暗器星级
local g_FightScore_DarkScore_Star_List =
{
	[1] = {maxstonelv = 3, starlv=5},
	[2] = {maxstonelv = 4, starlv=6},
	[3] = {maxstonelv = 5, starlv=7},
	[4] = {maxstonelv = 6, starlv=8},
	[5] = {maxstonelv = 7, starlv=8},
	[6] = {maxstonelv = 8, starlv=8},
}
local g_FightScore_DarkScore_StarValue_List =
{
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 1250,
	[6] = 5000,
	[7] = 12000,
	[8] = 26000,
}
--
--金翅翎羽暗器粹毒血上限推荐表
local g_FightScore_DarkScore_HP_List =
{
	[1] = {maxstonelv = 3, maxhp=5000},
	[2] = {maxstonelv = 4, maxhp=9000},
	[3] = {maxstonelv = 5, maxhp=10688},
	[4] = {maxstonelv = 6, maxhp=10688},
	[5] = {maxstonelv = 7, maxhp=10688},
	[6] = {maxstonelv = 8, maxhp=10688},
}
--
--金翅翎羽暗器粹毒属性攻推荐表
local g_FightScore_DarkScore_Pro_List =
{
	[1] = {maxstonelv = 3, maxpro=85},
	[2] = {maxstonelv = 4, maxpro=145},
	[3] = {maxstonelv = 5, maxpro=176},
	[4] = {maxstonelv = 6, maxpro=176},
	[5] = {maxstonelv = 7, maxpro=176},
	[6] = {maxstonelv = 8, maxpro=176},
}
--
--金翅翎羽暗器粹毒命中推荐表
local g_FightScore_DarkScore_Hit_List =
{
	[1] = {maxstonelv = 3, maxhit=1000},
	[2] = {maxstonelv = 4, maxhit=1800},
	[3] = {maxstonelv = 5, maxhit=2175},
	[4] = {maxstonelv = 6, maxhit=2175},
	[5] = {maxstonelv = 7, maxhit=2175},
	[6] = {maxstonelv = 8, maxhit=2175},
}
--
local g_FightScore_DarkTotalScore = 0
--
--*************************************************************************************************
--
--	强化评分相关
--
--	强化标准等级表
local g_FightScore_StrengthScore_StdList =
{
	[3] = 4,
	[4] = 7,
	[5] = 30,
	[6] = 50,
	[7] = 80,
	[8] = 99,
	[9] = 99,
}
--
local g_FightScore_StrengthScore_RealMap = {}
local g_FightScore_StrengthTotalScore = 0;
--
--
--*************************************************************************************************
--
--	资质相关
--
--	资质加成分值表
local g_FightScore_ZiZhiScore_Value_List =
{
	[0] = 0,
	[1] = 10,
	[2] = 17,
	[3] = 24,
	[4] = 31,
	[5] = 38,
	[6] = 45,
	[7] = 52,
	[8] = 59,
	[9] = 66,
	[10] = 73,
	[11] = 80,
	[12] = 128,
	[13] = 176,
	[14] = 224,
	[15] = 272,
	[16] = 320,
	[17] = 750,
	[18] = 1180,
	[19] = 1610,
	[20] = 2040,
	[25] = 4080,
	[30] = 8160,
	[35] = 12240,
	[45] = 16320,
	[60] = 20400,
}

--	资质标准表
local g_FightScore_ZiZhiScore_StdList =
{
	[3] = {nGrade=126, rate=13,score=176},
	[4] = {nGrade=189, rate=16,score=320},
	[5] = {nGrade=189, rate=18,score=1180},
	[6] = {nGrade=189, rate=30,score=8160},
	[7] = {nGrade=189, rate=60,score=20400},
	[8] = {nGrade=189, rate=60,score=20400},
	[9] = {nGrade=189, rate=60,score=20400},
}
--	资质评价表
local g_FightScore_ZiZhiGrade_Value_List =
{
	[1] = {rate=1,str="#{GMItem_Equip_22}"},	--	普通
	[2] = {rate=64,str="#{GMItem_Equip_21}"},	--	中等
	[3] = {rate=126,str="#{GMItem_Equip_20}"},	--	优秀
	[4] = {rate=189,str="#{GMItem_Equip_19}"},	--	完美
--	[5] = 252,	--	超完美，暂时不用，后期再说
}
--
--
local g_FightScore_ZiZhiScore_RealMap = {}
local g_FightScore_ZiZhiTotalScore = 0
--
--
--*******************************************************************************
--
--	子女部分
--
--	子女评分标准表
local g_FightScore_InfantScore_StdList =
{
	[3] = {level=119,attr=445,skilllevel=3,cardlevel=3,cardgrade=1},
	[4] = {level=119,attr=445,skilllevel=5,cardlevel=5,cardgrade=2},
	[5] = {level=119,attr=445,skilllevel=7,cardlevel=7,cardgrade=2},
	[6] = {level=119,attr=445,skilllevel=9,cardlevel=9,cardgrade=3},
	[7] = {level=119,attr=445,skilllevel=9,cardlevel=9,cardgrade=3},
	[8] = {level=119,attr=445,skilllevel=9,cardlevel=9,cardgrade=3},
	[9] = {level=119,attr=445,skilllevel=9,cardlevel=9,cardgrade=3},
}

--	子女等级查分表
local g_FightScore_InfantScore_LevelList =
{
	[1]   = 6,    [2]   = 13,   [3]   = 20,   [4]   = 28,   [5]   = 36,   [6]   = 45,   [7]   = 55,   [8]   = 65,   [9]   = 76,   [10]  = 87,
	[11]  = 99,   [12]  = 112,  [13]  = 125,  [14]  = 139,  [15]  = 153,  [16]  = 168,  [17]  = 184,  [18]  = 200,  [19]  = 217,  [20]  = 234,
	[21]  = 252,  [22]  = 271,  [23]  = 290,  [24]  = 310,  [25]  = 330,  [26]  = 351,  [27]  = 373,  [28]  = 395,  [29]  = 418,  [30]  = 441,
	[31]  = 469,  [32]  = 501,  [33]  = 538,  [34]  = 579,  [35]  = 624,  [36]  = 674,  [37]  = 728,  [38]  = 787,  [39]  = 850,  [40]  = 917,
	[41]  = 989,  [42]  = 1065, [43]  = 1146, [44]  = 1231, [45]  = 1320, [46]  = 1414, [47]  = 1512, [48]  = 1615, [49]  = 1722, [50]  = 1833,
	[51]  = 1949, [52]  = 2069, [53]  = 2194, [54]  = 2323, [55]  = 2456, [56]  = 2594, [57]  = 2736, [58]  = 2883, [59]  = 3034, [60]  = 3189,
	[61]  = 3354, [62]  = 3526, [63]  = 3708, [64]  = 3898, [65]  = 4097, [66]  = 4305, [67]  = 4521, [68]  = 4746, [69]  = 4980, [70]  = 5222,
	[71]  = 5473, [72]  = 5733, [73]  = 6001, [74]  = 6279, [75]  = 6564, [76]  = 6859, [77]  = 7162, [78]  = 7474, [79]  = 7795, [80]  = 8124,
	[81]  = 8463, [82]  = 8809, [83]  = 9165, [84]  = 9529, [85]  = 9902, [86]  = 10284,[87]  = 10674,[88]  = 11073,[89]  = 11481,[90]  = 11897,
	[91]  = 12322,[92]  = 12756,[93]  = 13198,[94]  = 13650,[95]  = 14109,[96]  = 14578,[97]  = 15055,[98]  = 15541,[99]  = 16036,[100] = 16539,
	[101] = 17052,[102] = 17572,[103] = 18102,[104] = 18640,[105] = 19187,[106] = 19743,[107] = 20307,[108] = 20880,[109] = 21462,[110] = 22052,
	[111] = 22651,[112] = 23259,[113] = 23875,[114] = 24501,[115] = 25134,[116] = 25777,[117] = 26428,[118] = 27088,[119] = 27757,

}


--	子女综合素养总值查分表
local g_FightScore_InfantScore_AttrList =
{
	[0]   = 0,
	[1]   = 20,  [2]   = 40,  [3]   = 60,  [4]   = 80,  [5]   = 100, [6]   = 120, [7]   = 140, [8]   = 160, [9]   = 180, [10]  = 200,
	[11]  = 220, [12]  = 240, [13]  = 260, [14]  = 280, [15]  = 300, [16]  = 320, [17]  = 340, [18]  = 360, [19]  = 380, [20]  = 400,
	[21]  = 420, [22]  = 440, [23]  = 460, [24]  = 480, [25]  = 500, [26]  = 520, [27]  = 540, [28]  = 560, [29]  = 580, [30]  = 600,
	[31]  = 620, [32]  = 640, [33]  = 660, [34]  = 680, [35]  = 700, [36]  = 720, [37]  = 740, [38]  = 760, [39]  = 780, [40]  = 800,
	[41]  = 820, [42]  = 840, [43]  = 860, [44]  = 880, [45]  = 900, [46]  = 920, [47]  = 940, [48]  = 960, [49]  = 980, [50]  = 1000,
	[51]  = 1020,[52]  = 1040,[53]  = 1060,[54]  = 1080,[55]  = 1100,[56]  = 1120,[57]  = 1140,[58]  = 1160,[59]  = 1180,[60]  = 1200,
	[61]  = 1220,[62]  = 1240,[63]  = 1260,[64]  = 1280,[65]  = 1300,[66]  = 1320,[67]  = 1340,[68]  = 1360,[69]  = 1380,[70]  = 1400,
	[71]  = 1420,[72]  = 1440,[73]  = 1460,[74]  = 1480,[75]  = 1500,[76]  = 1520,[77]  = 1540,[78]  = 1560,[79]  = 1580,[80]  = 1600,
	[81]  = 1620,[82]  = 1640,[83]  = 1660,[84]  = 1680,[85]  = 1700,[86]  = 1720,[87]  = 1740,[88]  = 1760,[89]  = 1780,[90]  = 1800,
	[91]  = 1820,[92]  = 1840,[93]  = 1860,[94]  = 1880,[95]  = 1900,[96]  = 1920,[97]  = 1940,[98]  = 1960,[99]  = 1980,[100] = 2000,
	[101] = 2020,[102] = 2040,[103] = 2060,[104] = 2080,[105] = 2100,[106] = 2120,[107] = 2140,[108] = 2160,[109] = 2180,[110] = 2200,
	[111] = 2220,[112] = 2240,[113] = 2260,[114] = 2280,[115] = 2300,[116] = 2320,[117] = 2340,[118] = 2360,[119] = 2380,[120] = 2400,
	[121] = 2420,[122] = 2440,[123] = 2460,[124] = 2480,[125] = 2500,[126] = 2520,[127] = 2540,[128] = 2560,[129] = 2580,[130] = 2600,
	[131] = 2620,[132] = 2640,[133] = 2660,[134] = 2680,[135] = 2700,[136] = 2720,[137] = 2740,[138] = 2760,[139] = 2780,[140] = 2800,
	[141] = 2820,[142] = 2840,[143] = 2860,[144] = 2880,[145] = 2900,[146] = 2920,[147] = 2940,[148] = 2960,[149] = 2980,[150] = 3000,
	[151] = 3020,[152] = 3040,[153] = 3060,[154] = 3080,[155] = 3100,[156] = 3120,[157] = 3140,[158] = 3160,[159] = 3180,[160] = 3200,
	[161] = 3220,[162] = 3240,[163] = 3260,[164] = 3280,[165] = 3300,[166] = 3320,[167] = 3340,[168] = 3360,[169] = 3380,[170] = 3400,
	[171] = 3420,[172] = 3440,[173] = 3460,[174] = 3480,[175] = 3500,[176] = 3520,[177] = 3540,[178] = 3560,[179] = 3580,[180] = 3600,
	[181] = 3620,[182] = 3640,[183] = 3660,[184] = 3680,[185] = 3700,[186] = 3720,[187] = 3740,[188] = 3760,[189] = 3780,[190] = 3800,
	[191] = 3820,[192] = 3840,[193] = 3860,[194] = 3880,[195] = 3900,[196] = 3920,[197] = 3940,[198] = 3960,[199] = 3980,[200] = 4000,
	[201] = 4020,[202] = 4040,[203] = 4060,[204] = 4080,[205] = 4100,[206] = 4120,[207] = 4140,[208] = 4160,[209] = 4180,[210] = 4200,
	[211] = 4220,[212] = 4240,[213] = 4260,[214] = 4280,[215] = 4300,[216] = 4320,[217] = 4340,[218] = 4360,[219] = 4380,[220] = 4400,
	[221] = 4420,[222] = 4440,[223] = 4460,[224] = 4480,[225] = 4500,[226] = 4520,[227] = 4540,[228] = 4560,[229] = 4580,[230] = 4600,
	[231] = 4620,[232] = 4640,[233] = 4660,[234] = 4680,[235] = 4700,[236] = 4720,[237] = 4740,[238] = 4760,[239] = 4780,[240] = 4800,
	[241] = 4820,[242] = 4840,[243] = 4860,[244] = 4880,[245] = 4900,[246] = 4920,[247] = 4940,[248] = 4960,[249] = 4980,[250] = 5000,
	[251] = 5020,[252] = 5040,[253] = 5060,[254] = 5080,[255] = 5100,[256] = 5120,[257] = 5140,[258] = 5160,[259] = 5180,[260] = 5200,
	[261] = 5220,[262] = 5240,[263] = 5260,[264] = 5280,[265] = 5300,[266] = 5320,[267] = 5340,[268] = 5360,[269] = 5380,[270] = 5400,
	[271] = 5420,[272] = 5440,[273] = 5460,[274] = 5480,[275] = 5500,[276] = 5520,[277] = 5540,[278] = 5560,[279] = 5580,[280] = 5600,
	[281] = 5620,[282] = 5640,[283] = 5660,[284] = 5680,[285] = 5700,[286] = 5720,[287] = 5740,[288] = 5760,[289] = 5780,[290] = 5800,
	[291] = 5820,[292] = 5840,[293] = 5860,[294] = 5880,[295] = 5900,[296] = 5920,[297] = 5940,[298] = 5960,[299] = 5980,[300] = 6000,
	[301] = 6020,[302] = 6040,[303] = 6060,[304] = 6080,[305] = 6100,[306] = 6120,[307] = 6140,[308] = 6160,[309] = 6180,[310] = 6200,
	[311] = 6220,[312] = 6240,[313] = 6260,[314] = 6280,[315] = 6300,[316] = 6320,[317] = 6340,[318] = 6360,[319] = 6380,[320] = 6400,
	[321] = 6420,[322] = 6440,[323] = 6460,[324] = 6480,[325] = 6500,[326] = 6520,[327] = 6540,[328] = 6560,[329] = 6580,[330] = 6600,
	[331] = 6620,[332] = 6640,[333] = 6660,[334] = 6680,[335] = 6700,[336] = 6720,[337] = 6740,[338] = 6760,[339] = 6780,[340] = 6800,
	[341] = 6820,[342] = 6840,[343] = 6860,[344] = 6880,[345] = 6900,[346] = 6920,[347] = 6940,[348] = 6960,[349] = 6980,[350] = 7000,
	[351] = 7020,[352] = 7040,[353] = 7060,[354] = 7080,[355] = 7100,[356] = 7120,[357] = 7140,[358] = 7160,[359] = 7180,[360] = 7200,
	[361] = 7220,[362] = 7240,[363] = 7260,[364] = 7280,[365] = 7300,[366] = 7320,[367] = 7340,[368] = 7360,[369] = 7380,[370] = 7400,
	[371] = 7420,[372] = 7440,[373] = 7460,[374] = 7480,[375] = 7500,[376] = 7520,[377] = 7540,[378] = 7560,[379] = 7580,[380] = 7600,
	[381] = 7620,[382] = 7640,[383] = 7660,[384] = 7680,[385] = 7700,[386] = 7720,[387] = 7740,[388] = 7760,[389] = 7780,[390] = 7800,
	[391] = 7820,[392] = 7840,[393] = 7860,[394] = 7880,[395] = 7900,[396] = 7920,[397] = 7940,[398] = 7960,[399] = 7980,[400] = 8000,
	[401] = 8020,[402] = 8040,[403] = 8060,[404] = 8080,[405] = 8100,[406] = 8120,[407] = 8140,[408] = 8160,[409] = 8180,[410] = 8200,
	[411] = 8220,[412] = 8240,[413] = 8260,[414] = 8280,[415] = 8300,[416] = 8320,[417] = 8340,[418] = 8360,[419] = 8380,[420] = 8400,
	[421] = 8420,[422] = 8440,[423] = 8460,[424] = 8480,[425] = 8500,[426] = 8520,[427] = 8540,[428] = 8560,[429] = 8580,[430] = 8600,
	[431] = 8620,[432] = 8640,[433] = 8660,[434] = 8680,[435] = 8700,[436] = 8720,[437] = 8740,[438] = 8760,[439] = 8780,[440] = 8800,
	[441] = 8820,[442] = 8840,[443] = 8860,[444] = 8880,[445] = 8900,
}
--
--	子女技能查分表
local g_FightScore_InfantScore_SkillLevel_List =
{
	[1] = 0,
	[2] = 123,
	[3] = 286,
	[4] = 678,
	[5] = 1332,
	[6] = 2312,
	[7] = 4272,
	[8] = 9172,
	[9] = 18972,
}
--
--	子女卡牌品质查分表
local g_FightScore_InfantScore_CardQuality_List =
{
	[0] = 100,
	[1] = 308,
	[2] = 1369,
	[3] = 7823,
}
--
--	子女卡牌星级查分表
local g_FightScore_InfantScore_CardYanDuLevel_List =
{
	[0] = 0,
	[1] = 98,
	[2] = 294,
	[3] = 588,
	[4] = 1176,
	[5] = 2450,
	[6] = 4410,
	[7] = 9310,
	[8] = 19110,
	[9] = 38710,
}
--
--	子女评分
local g_FightScore_InfantScore_LevelScore = -1;		--	孩子等级评分
local g_FightScore_InfantLevel = 0;			--	孩子等级
local g_FightScore_InfantScore_AttrScore = -1;		--	孩子综合素养评分
local g_FightScore_InfantAttrValue = 0;			--	孩子综合素养值
local g_FightScore_InfantSkill = {};					--	孩子技能id 等级 评分
local g_FightScore_InfantCard = {};					--	孩子卡片id 等级 品质 评分
local g_FightScore_InfantTotalScore = -1;
--
--
--********************************************************************************************
--
--	神木王鼎
--
local g_FightScore_SMWDScore_StdList =
{
	[3] = 6,
	[4] = 10,
	[5] = 21,
	[6] = 36,
	[7] = 45,
	[8] = 45,
	[9] = 45,
}
--
--
local g_FightScore_SMWDScore_CountList =
{
	[0] ={score=0,    num=0,qual=1},
	[1] ={score=200,    num=1,qual=1},
	[2] ={score=700,    num=1,qual=2},
	[3] ={score=1200,   num=2,qual=2},
	[4] ={score=2200,   num=1,qual=3},
	[5] ={score=3200,   num=2,qual=3},
	[6] ={score=4200,   num=3,qual=3},
	[7] ={score=6700,   num=1,qual=4},
	[8] ={score=9200,   num=2,qual=4},
	[9] ={score=11700,  num=3,qual=4},
	[10]={score=14200,  num=4,qual=4},
	[11]={score=19200,  num=1,qual=5},
	[12]={score=24200,  num=2,qual=5},
	[13]={score=29200,  num=3,qual=5},
	[14]={score=34200,  num=4,qual=5},
	[15]={score=39200,  num=5,qual=5},
	[16]={score=49200,  num=1,qual=6},
	[17]={score=59200,  num=2,qual=6},
	[18]={score=69200,  num=3,qual=6},
	[19]={score=79200,  num=4,qual=6},
	[20]={score=89200,  num=5,qual=6},
	[21]={score=99200,  num=6,qual=6},
	[22]={score=129200, num=1,qual=7},
	[23]={score=159200, num=2,qual=7},
	[24]={score=189200, num=3,qual=7},
	[25]={score=219200, num=4,qual=7},
	[26]={score=249200, num=5,qual=7},
	[27]={score=279200, num=6,qual=7},
	[28]={score=309200, num=7,qual=7},
	[29]={score=389200, num=1,qual=8},
	[30]={score=469200, num=2,qual=8},
	[31]={score=549200, num=3,qual=8},
	[32]={score=629200, num=4,qual=8},
	[33]={score=709200, num=5,qual=8},
	[34]={score=789200, num=6,qual=8},
	[35]={score=869200, num=7,qual=8},
	[36]={score=949200, num=8,qual=8},
	[37]={score=1099200,num=1,qual=9},
	[38]={score=1249200,num=2,qual=9},
	[39]={score=1399200,num=3,qual=9},
	[40]={score=1549200,num=4,qual=9},
	[41]={score=1699200,num=5,qual=9},
	[42]={score=1849200,num=6,qual=9},
	[43]={score=1999200,num=7,qual=9},
	[44]={score=2149200,num=8,qual=9},
	[45]={score=2299200,num=9,qual=9},
}

local g_FightScore_XiaYinLevelScore = { --1~100
    0,20,40,60,80,100,120,140,160,180,
    200,240,280,320,360,400,440,480,520,560,
    600,680,760,840,920,1000,1080,1160,1240,1320,
    1400,1540,1680,1820,1960,2100,2240,2380,2520,2660,
    2800,3020,3240,3460,3680,3900,4120,4340,4560,4780,
    5000,5320,5640,5960,6280,6600,6920,7240,7560,7880,
    8200,8640,9080,9520,9960,10400,10840,11280,11720,12160,
    12600,13180,13760,14340,14920,15500,16080,16660,17240,17820,
    18400,19140,19880,20620,21360,22100,22840,23580,24320,25060,
    25800,26720,27640,28560,29480,30400,31320,32240,33160,34080,
}

local g_FightScore_XiaYinPropLevelScore = { --1~20
    500,550,625,730,870,1050,1275,1550,1880,2270,
    2725,3250,3850,4530,5295,6150,7100,8150,9305,10570,
}

local g_FightScore_SMWDScore_Total = -1
local g_FightScore_SMWDScore_Total2 = -1
local g_FightScore_SMWD_Count = 0
local g_FightScore_SMWD_Count2 = 0

local g_FightScore_TotalScore = {}
local g_FightScore_2606SValid = { -- 开启功能配置
	[1] = 1, -- 装备 Equip
	[2] = 1, -- 宝石 Gem
	[3] = 1, -- 强化 Strength
	[4] = 1, -- 暗器 Dark
	[5] = 0, -- 神木王鼎，神鼎，SMWD
	[6] = 1, -- 资质 ZiZhi
	[7] = 1, -- 刻铭 KeMing
	[8] = 1, -- 附体 FuTi
	[9] = 1, -- 雕纹 DiaoWen
	[10] = 1, -- 子女 Infant
	[11] = 1, -- 武魂 WuHun
	[12] = 0, -- 龙纹 LongWen
	[13] = 0, -- 精通 JingTong
	[14] = 1, -- 真元 ZhenYuan
	[15] = 1, -- 令牌 LingPai
	[16] = 0, -- 侠印 XiaYin
	[17] = 0, -- 武意 Material
	[18] = 0, -- 无字谱 xingzhen
	[19] = 0, -- 星盘 UnderArmour
	[20] = 1, -- 秘宝 ZongMen
}
--*******************************************************************************


--宝石标准等级对应的各个参数 对应EquipEvaluateStd.txt
--"FYMX" 非衣服、帽子、项链
--"YMX"  衣服、帽子、项链
--"WuQI" 武器
local g_Gem_Score_STL =
{
[3]={
	["WuQi"]=6,["FYMX"]=5,["YMX"]=4,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=6,["ZYStr"]=2,["ZYLevel_STL"]=4,["ZYScore_STL"]=626,
	["WuHunRate_STL"]=2,["WuHunAttr1"]=3,["WuHunAttr2"]=3,["WuHunAttr3"]=3,["WuHunAttr4"]=0,["WuHunAttr5"]=0,["WuHunAttr6"]=0,["WuHunAttr7"]=0,
	["FTWuXing"]=5,["FTLingXing"]=5,["FTRongHeDu"]=5,["FTChengZhangLv"]=5,["FTSkill1"]=1,["FTSkill2"]=1,["FTSkill3"]=1,["FTSkill4"]=1,["FTSkill5"]=0,
	["JingTong"]=375,["JingTongLevel"]=10,["BaoZhu"]=20,["LingPaiType"]=5,["KeMing"]=1,
	},
[4]={
	["WuQi"]=7,["FYMX"]=6,["YMX"]=5,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=6,["ZYStr"]=3,["ZYLevel_STL"]=5,["ZYScore_STL"]=4608,
	["WuHunRate_STL"]=3,["WuHunAttr1"]=4,["WuHunAttr2"]=4,["WuHunAttr3"]=4,["WuHunAttr4"]=4,["WuHunAttr5"]=4,["WuHunAttr6"]=0,["WuHunAttr7"]=0,
	["FTWuXing"]=6,["FTLingXing"]=6,["FTRongHeDu"]=6,["FTChengZhangLv"]=5,["FTSkill1"]=3,["FTSkill2"]=3,["FTSkill3"]=3,["FTSkill4"]=3,["FTSkill5"]=3,
	["JingTong"]=2025,["JingTongLevel"]=20,["BaoZhu"]=30,["LingPaiType"]=6,["KeMing"]=3,
	},
[5]={["WuQi"]=8,["FYMX"]=7,["YMX"]=6,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=7,["ZYStr"]=3,["ZYLevel_STL"]=7,["ZYScore_STL"]=20773,
	["WuHunRate_STL"]=4,["WuHunAttr1"]=6,["WuHunAttr2"]=6,["WuHunAttr3"]=6,["WuHunAttr4"]=6,["WuHunAttr5"]=6,["WuHunAttr6"]=6,["WuHunAttr7"]=6,
	["FTWuXing"]=8,["FTLingXing"]=8,["FTRongHeDu"]=8,["FTChengZhangLv"]=5,["FTSkill1"]=4,["FTSkill2"]=4,["FTSkill3"]=4,["FTSkill4"]=4,["FTSkill5"]=4,
	["JingTong"]=12675,["JingTongLevel"]=50,["BaoZhu"]=50,["LingPaiType"]=7,["KeMing"]=6,
	},
[6]={["WuQi"]=9,["FYMX"]=8,["YMX"]=7,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=7,["ZYStr"]=4,["ZYLevel_STL"]=7,["ZYScore_STL"]=114547,
	["WuHunRate_STL"]=5,["WuHunAttr1"]=8,["WuHunAttr2"]=8,["WuHunAttr3"]=8,["WuHunAttr4"]=8,["WuHunAttr5"]=8,["WuHunAttr6"]=8,["WuHunAttr7"]=8,
	["FTWuXing"]=10,["FTLingXing"]=10,["FTRongHeDu"]=10,["FTChengZhangLv"]=5,["FTSkill1"]=4,["FTSkill2"]=4,["FTSkill3"]=4,["FTSkill4"]=4,["FTSkill5"]=4,
	["JingTong"]=40100,["JingTongLevel"]=100,["BaoZhu"]=50,["LingPaiType"]=8,["KeMing"]=15,
	},
[7]={["WuQi"]=9,["FYMX"]=8,["YMX"]=7,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=7,["ZYStr"]=5,["ZYLevel_STL"]=9,["ZYScore_STL"]=977256,
	["WuHunRate_STL"]=5,["WuHunAttr1"]=8,["WuHunAttr2"]=8,["WuHunAttr3"]=8,["WuHunAttr4"]=8,["WuHunAttr5"]=8,["WuHunAttr6"]=8,["WuHunAttr7"]=8,
	["FTWuXing"]=10,["FTLingXing"]=10,["FTRongHeDu"]=10,["FTChengZhangLv"]=5,["FTSkill1"]=4,["FTSkill2"]=4,["FTSkill3"]=4,["FTSkill4"]=4,["FTSkill5"]=4,
	["JingTong"]=40100,["JingTongLevel"]=100,["BaoZhu"]=50,["LingPaiType"]=8,["KeMing"]=15,
	},
[8]={["WuQi"]=9,["FYMX"]=8,["YMX"]=8,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=7,["ZYStr"]=5,["ZYLevel_STL"]=9,["ZYScore_STL"]=977256,
	["WuHunRate_STL"]=5,["WuHunAttr1"]=8,["WuHunAttr2"]=8,["WuHunAttr3"]=8,["WuHunAttr4"]=8,["WuHunAttr5"]=8,["WuHunAttr6"]=8,["WuHunAttr7"]=8,
	["FTWuXing"]=10,["FTLingXing"]=10,["FTRongHeDu"]=10,["FTChengZhangLv"]=5,["FTSkill1"]=4,["FTSkill2"]=4,["FTSkill3"]=4,["FTSkill4"]=4,["FTSkill5"]=4,
	["JingTong"]=40100,["JingTongLevel"]=100,["BaoZhu"]=50,["LingPaiType"]=8,["KeMing"]=15,
	},
[9]={["WuQi"]=9,["FYMX"]=8,["YMX"]=8,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=7,["ZYStr"]=5,["ZYLevel_STL"]=9,["ZYScore_STL"]=977256,
	["WuHunRate_STL"]=5,["WuHunAttr1"]=8,["WuHunAttr2"]=8,["WuHunAttr3"]=8,["WuHunAttr4"]=8,["WuHunAttr5"]=8,["WuHunAttr6"]=8,["WuHunAttr7"]=8,
	["FTWuXing"]=10,["FTLingXing"]=10,["FTRongHeDu"]=10,["FTChengZhangLv"]=5,["FTSkill1"]=4,["FTSkill2"]=4,["FTSkill3"]=4,["FTSkill4"]=4,["FTSkill5"]=4,
	["JingTong"]=40100,["JingTongLevel"]=100,["BaoZhu"]=50,["LingPaiType"]=8,["KeMing"]=15,
	},
}
--120以后 附体技能推荐变更
local g_Gem_Score_STL_120 =
{
[3]={
	["WuQi"]=6,["FYMX"]=5,["YMX"]=4,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=6,["ZYStr"]=2,["ZYLevel_STL"]=4,["ZYScore_STL"]=626,
	["WuHunRate_STL"]=2,["WuHunAttr1"]=3,["WuHunAttr2"]=3,["WuHunAttr3"]=3,["WuHunAttr4"]=0,["WuHunAttr5"]=0,["WuHunAttr6"]=0,["WuHunAttr7"]=0,
	["FTWuXing"]=5,["FTLingXing"]=5,["FTRongHeDu"]=5,["FTChengZhangLv"]=5,["FTSkill1"]=1,["FTSkill2"]=1,["FTSkill3"]=1,["FTSkill4"]=1,["FTSkill5"]=0,
	["JingTong"]=375,["JingTongLevel"]=10,["BaoZhu"]=20,["LingPaiType"]=5,["KeMing"]=1,
	},
[4]={
	["WuQi"]=7,["FYMX"]=6,["YMX"]=5,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=6,["ZYStr"]=3,["ZYLevel_STL"]=5,["ZYScore_STL"]=4608,
	["WuHunRate_STL"]=3,["WuHunAttr1"]=4,["WuHunAttr2"]=4,["WuHunAttr3"]=4,["WuHunAttr4"]=4,["WuHunAttr5"]=4,["WuHunAttr6"]=0,["WuHunAttr7"]=0,
	["FTWuXing"]=6,["FTLingXing"]=6,["FTRongHeDu"]=6,["FTChengZhangLv"]=5,["FTSkill1"]=4,["FTSkill2"]=4,["FTSkill3"]=4,["FTSkill4"]=4,["FTSkill5"]=4,
	["JingTong"]=2025,["JingTongLevel"]=20,["BaoZhu"]=30,["LingPaiType"]=6,["KeMing"]=3,
	},
[5]={["WuQi"]=8,["FYMX"]=7,["YMX"]=6,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=7,["ZYStr"]=3,["ZYLevel_STL"]=7,["ZYScore_STL"]=20773,
	["WuHunRate_STL"]=4,["WuHunAttr1"]=6,["WuHunAttr2"]=6,["WuHunAttr3"]=6,["WuHunAttr4"]=6,["WuHunAttr5"]=6,["WuHunAttr6"]=6,["WuHunAttr7"]=6,
	["FTWuXing"]=8,["FTLingXing"]=8,["FTRongHeDu"]=8,["FTChengZhangLv"]=5,["FTSkill1"]=5,["FTSkill2"]=5,["FTSkill3"]=5,["FTSkill4"]=5,["FTSkill5"]=5,
	["JingTong"]=12675,["JingTongLevel"]=50,["BaoZhu"]=50,["LingPaiType"]=7,["KeMing"]=6,
	},
[6]={["WuQi"]=9,["FYMX"]=8,["YMX"]=7,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=7,["ZYStr"]=4,["ZYLevel_STL"]=7,["ZYScore_STL"]=114547,
	["WuHunRate_STL"]=5,["WuHunAttr1"]=8,["WuHunAttr2"]=8,["WuHunAttr3"]=8,["WuHunAttr4"]=8,["WuHunAttr5"]=8,["WuHunAttr6"]=8,["WuHunAttr7"]=8,
	["FTWuXing"]=10,["FTLingXing"]=10,["FTRongHeDu"]=10,["FTChengZhangLv"]=5,["FTSkill1"]=6,["FTSkill2"]=6,["FTSkill3"]=6,["FTSkill4"]=6,["FTSkill5"]=6,
	["JingTong"]=40100,["JingTongLevel"]=100,["BaoZhu"]=50,["LingPaiType"]=8,["KeMing"]=15,
	},
[7]={["WuQi"]=9,["FYMX"]=8,["YMX"]=7,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=7,["ZYStr"]=5,["ZYLevel_STL"]=9,["ZYScore_STL"]=977256,
	["WuHunRate_STL"]=5,["WuHunAttr1"]=8,["WuHunAttr2"]=8,["WuHunAttr3"]=8,["WuHunAttr4"]=8,["WuHunAttr5"]=8,["WuHunAttr6"]=8,["WuHunAttr7"]=8,
	["FTWuXing"]=10,["FTLingXing"]=10,["FTRongHeDu"]=10,["FTChengZhangLv"]=5,["FTSkill1"]=6,["FTSkill2"]=6,["FTSkill3"]=6,["FTSkill4"]=6,["FTSkill5"]=6,
	["JingTong"]=40100,["JingTongLevel"]=100,["BaoZhu"]=50,["LingPaiType"]=8,["KeMing"]=15,
	},
[8]={["WuQi"]=9,["FYMX"]=8,["YMX"]=8,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=7,["ZYStr"]=5,["ZYLevel_STL"]=9,["ZYScore_STL"]=977256,
	["WuHunRate_STL"]=5,["WuHunAttr1"]=8,["WuHunAttr2"]=8,["WuHunAttr3"]=8,["WuHunAttr4"]=8,["WuHunAttr5"]=8,["WuHunAttr6"]=8,["WuHunAttr7"]=8,
	["FTWuXing"]=10,["FTLingXing"]=10,["FTRongHeDu"]=10,["FTChengZhangLv"]=5,["FTSkill1"]=6,["FTSkill2"]=6,["FTSkill3"]=6,["FTSkill4"]=6,["FTSkill5"]=6,
	["JingTong"]=40100,["JingTongLevel"]=100,["BaoZhu"]=50,["LingPaiType"]=8,["KeMing"]=15,
	},
[9]={["WuQi"]=9,["FYMX"]=8,["YMX"]=8,["1,10"]=1,["11,20"]=2,["21,30"]=3,["31,40"]=4,["41,50"]=5,["51+"]=7,["ZYStr"]=5,["ZYLevel_STL"]=9,["ZYScore_STL"]=977256,
	["WuHunRate_STL"]=5,["WuHunAttr1"]=8,["WuHunAttr2"]=8,["WuHunAttr3"]=8,["WuHunAttr4"]=8,["WuHunAttr5"]=8,["WuHunAttr6"]=8,["WuHunAttr7"]=8,
	["FTWuXing"]=10,["FTLingXing"]=10,["FTRongHeDu"]=10,["FTChengZhangLv"]=5,["FTSkill1"]=6,["FTSkill2"]=6,["FTSkill3"]=6,["FTSkill4"]=6,["FTSkill5"]=6,
	["JingTong"]=40100,["JingTongLevel"]=100,["BaoZhu"]=50,["LingPaiType"]=8,["KeMing"]=15,
	},
}
local g_XingZhenScore_STL = {
	[3] = {qual = 1, x_slot_stl = 5299, c_slot_stl = 38000, x_active_stl = {31780,0,0,0}, c_active_stl = {190000,0,0,0}},
	[4] = {qual = 2, x_slot_stl = 25382, c_slot_stl = 65000, x_active_stl = {54026,190350,0,0}, c_active_stl = {266000,650000,0,0}},
	[5] = {qual = 3, x_slot_stl = 104609, c_slot_stl = 130000, x_active_stl = {54026,213192,470730,0}, c_active_stl = {266000,780000,1300000,0}},
	[6] = {qual = 4, x_slot_stl = 185530, c_slot_stl = 198000, x_active_stl = {54026,213192,564876,494740}, c_active_stl = {266000,780000,2210000,594000}},
	[7] = {qual = 4, x_slot_stl = 185530, c_slot_stl = 198000, x_active_stl = {54026,213192,564876,890532}, c_active_stl = {266000,780000,2210000,1980000}},
	[8] = {qual = 4, x_slot_stl = 185530, c_slot_stl = 198000, x_active_stl = {54026,213192,564876,890532}, c_active_stl = {266000,780000,2210000,1980000}},
}

local g_XingJuanScore = {
	[1] = 
	{
		{slot = 870,  active = 261},
		{slot = 1118, active = 335},
		{slot = 1605, active = 481},
		{slot = 2409, active = 722},
		{slot = 3615, active = 1084},
		{slot = 5299, active = 1589} 
	},
	
	[2] = 
	{
		{slot = 8960, active = 2688},
		{slot = 10519, active = 3155},
		{slot = 12775, active = 3832},
		{slot = 15892, active = 4767},
		{slot = 20041, active = 6012},
		{slot = 25382, active = 7614} 
	},
	
	[3] = 
	{
		{slot = 46360, active = 13908},
		{slot = 53760, active = 16128},
		{slot = 63022, active = 18906},
		{slot = 74403, active = 22320},
		{slot = 88181, active = 26454},
		{slot = 104609, active = 31382} 
	},
	
	[4] = 
	{
		{slot = 90000, active = 24000},
		{slot = 104607, active = 27895},
		{slot = 121342, active = 32358},
		{slot = 140323, active = 37419},
		{slot = 161680, active = 43114},
		{slot = 185530, active = 49474} 
	}
}

local g_SkillCardScore = {

	[1] = 
	{
		{slot = 8000, active = 8000},
		{slot = 11000, active = 11000},
		{slot = 14000, active = 14000},
		{slot = 23000, active = 23000},
		{slot = 38000, active = 38000} 
	},
	
	[2] = 
	{
		{slot = 20000, active = 20000},
		{slot = 24500, active = 24500},
		{slot = 29000, active = 29000},
		{slot = 42500, active = 42500},
		{slot = 65000, active = 65000} 
	},
	
	[3] = 
	{
		{slot = 40000, active = 40000},
		{slot = 49000, active = 49000},
		{slot = 58000, active = 58000},
		{slot = 85000, active = 85000},
		{slot = 130000, active = 130000} 
	},
	
	[4] = 
	{
		{slot = 66000, active = 66000},
		{slot = 79200, active = 79200},
		{slot = 92400, active = 92400},
		{slot = 132000, active = 132000},
		{slot = 198000, active = 198000} 
	}
}

local g_XingZhenQualText = {
	"#{PFZY_200424_07}",
	"#{PFZY_200424_06}",
	"#{PFZY_200424_08}",
	"#{PFZY_200424_09}",
}

local g_XingJuanImg = {
	"set:TaskTools18 image:TaskTools18_14",
	"set:TaskTools18 image:TaskTools18_13",
	"set:TaskTools18 image:TaskTools18_15",
	"set:TaskTools18 image:TaskTools18_16",
}

local g_SkillCardImg = {
	"set:Rune02 image:Rune02_16",
	"set:Rune03 image:Rune03_7",
	"set:Rune02 image:Rune02_5",
	"set:Rune01 image:Rune01_8",
}

function FightScore_PreLoad()

	this:RegisterEvent("OPEN_EQUIP_SCORE_CONDUCT")
	-- 更新装备
	this:RegisterEvent("REFRESH_EQUIP");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("XINGZHEN_UPDATE",false)
end

function FightScore_ReloadCombo()
    FightScoreFrame_Lace1_ListXiala:ResetList()
	local itemlist = {
		"#{PFZYYH_160224_8}",
		"#{PFZYYH_160224_9}",
		"#{PFZYYH_160224_10}",
		"#{PFZYYH_160224_11}",
		"#{PFZYYH_160224_12}",
		"#{PFZYYH_160224_13}",
		"#{PFZYYH_160224_14}"
	}
    for i=1,7 do
        FightScoreFrame_Lace1_ListXiala:AddTextItem(itemlist[i],i-1);
    end
	FightScoreFrame_Lace1_ListXiala:SetCurrentSelect(0)
end

function FightScore_OnLoad()
	g_FightScoreRightList = FightScoreFrame_List2_Window
	g_FightScore_UnifiedPosition = FightScoreFrame:GetProperty("UnifiedPosition")
	FightScore_ReloadCombo()
end

function FightScore_OnEvent(event)

	if(event == "OPEN_EQUIP_SCORE_CONDUCT") then
		FightScore_ReloadCombo()
		FightScore_Open()
	elseif(event == "REFRESH_EQUIP") then
		if this:IsVisible() then
			FightScore_Open()
		end
	elseif event == "XINGZHEN_UPDATE" then
		FightScore_Open()	
	end

	if (event == "ADJEST_UI_POS") and g_FightScore_UnifiedPosition ~= nil then
		FightScoreFrame:SetProperty("UnifiedPosition", g_FightScore_UnifiedPosition)
	end

	if (event == "VIEW_RESOLUTION_CHANGED") and g_FightScore_UnifiedPosition ~= nil then
		FightScoreFrame:SetProperty("UnifiedPosition", g_FightScore_UnifiedPosition)
	end
end

function FightScore_OnGemLevelChanged()
    if this:IsVisible() then
		FightScore_Open()
	end
end

function FightScore_Open( )

	--是否有百兽精通的标记
	local bEquipMaster = CachedTarget:GetMySelfEquipMasterFlag()
	if bEquipMaster ~= 0 then
		--PushDebugMessage("百兽精通：有")
	else
		--PushDebugMessage("百兽精通：无")
	end

	--对应的按钮号，不知道之前谁做的，不按装备位的宏，乱定义序号，导致以后很难弄啊
	local ActionWeapon 		= EnumAction(0, "equip"); 	--武器			1
	local ActionCap    		= EnumAction(1, "equip");	--帽子			8
	local ActionArmor  		= EnumAction(2, "equip");	--护甲			7
	local ActionCuff   		= EnumAction(3, "equip");	--手套			10
	local ActionBoot   		= EnumAction(4, "equip");	--鞋子			12
	local ActionSash   		= EnumAction(5, "equip");	--腰带			11
	local ActionRing    	= EnumAction(6, "equip");	--戒指1			3
	local ActionNecklace	= EnumAction(7, "equip");	--项链			13
	local ActionMount		= EnumAction(17, "equip");	--暗器			14
	local ActionRing_2		= EnumAction(11, "equip");	--戒指2			4
	local ActionCharm 		= EnumAction(12, "equip");	--护符1			5
	local ActionCharm_2   	= EnumAction(13, "equip");	--护符2			6
	local ActionWrist  		= EnumAction(14, "equip");	--护腕			2
	local ActionShoulder  	= EnumAction(15, "equip");	--护肩			9
	local ActionDress   	= EnumAction(18, "equip");	--武魂			16
	local ActionLongwen   	= EnumAction(19, "equip");	--龙纹			15
	local AciontRL			= EnumAction(20, "equip");	--令牌			17

	local Equip_ID = {
		[0] 	= ActionWeapon:GetID(),
		[1] 	= ActionCap:GetID(),
		[2] 	= ActionArmor:GetID(),
		[3] 	= ActionCuff:GetID(),
		[4] 	= ActionBoot:GetID(),
		[5] 	= ActionSash:GetID(),
		[6] 	= ActionRing:GetID(),
		[7] 	= ActionNecklace:GetID(),
		[8] 	= ActionMount:GetID(),
		[9] 	= ActionRing_2:GetID(),
		[10] 	= ActionCharm:GetID(),
		[11] 	= ActionCharm_2:GetID(),
		[12] 	= ActionWrist:GetID(),
		[13] 	= ActionShoulder:GetID(),
		[14] 	= ActionDress:GetID(),
		[15] 	= ActionLongwen:GetID(),
		[16] 	= AciontRL:GetID(),
	}
    
	local nGemMaxLevel = FightScore_GetEquipGemMaxLevel()
--	PushDebugMessage("gem param is: " .. nGemMaxLevel)
	--是否穿着装备
	local HaveEquip = 0
	g_ScoreBaseParam = 3
	g_FightScore_CurGemLevel = nGemMaxLevel

	--如果有穿着的装备，检查装备上的宝石最高等级
	local SelfMaxGemLevel = FightScore_CalculateAllScore() --所有计算
	g_FightScore_TotalScore = {} --这里得清空一下啊,兄弟
	g_FightScore_PlayLevel_STL =FightScore_GetPlayerLevelSTL()
	g_FightScore_TotalScore = {
	[1] = g_FightScore_EquipTotalScore,
	[2] = g_FightScore_GemTotalScore,
	[3] = g_FightScore_StrengthTotalScore,
	[4] = g_FightScore_DarkTotalScore,
	[5] = math.floor( ( g_FightScore_SMWDScore_Total + g_FightScore_SMWDScore_Total2 ) / 2 ),
	[6] = g_FightScore_ZiZhiTotalScore,
	[7] = g_FightScore_KeMingTotalScore,
	[8] = g_FightScore_FuTiTotalScore,
	[9] = g_FightScore_DiaoWenTotalScore,
	[10] = g_FightScore_InfantTotalScore,
	[11] = g_FightScore_WuHunTotalScore,
	[12] = g_FightScore_LongWenScore_Total,
	[13] = g_FightScore_JingTongScore,
	[14] = g_FightScore_ZhenYuanScore,
	[15] = g_FightScore_LingPaiScore,
    [16] = g_FightScore_XiaYinScore,
	[17] = g_FightScore_MartialScore,
	[18] = g_FightScore_XingZhenScore,
	[19] = g_FightScore_UnderArmourTotalScore,
	[20] = g_FightScore_ZongMenEquipTotalScore,
	}
    
	----------------------------------------------------------------
	--清理上次的东西，必须做这一步，否则崩
	--注意顺序，先释放，后清空，否则崩
	for num=1, table.getn(g_ChildWindow) do
		g_ChildWindow[num]:SetActionItem(-1)
	end
	g_ChildWindow = {}

	--	清除右侧界面
	FightScore_CleanRightActionItemInfo()

	if FightScoreFrame_List2_Window then
		FightScoreFrame_List2_Window:CleanAllElement("FightScore")
	else
		return
	end
	FightScoreFrame_Charts:CleanAllElement("FightScore")
   
	----------------------------------------------------------------

	-------------------------------------界面的上面部分：开始-------------------------------------
	
	
	local st,se = FightScoreFrame_Lace1_ListXiala:GetCurrentSelect()
	if tonumber(se) < 1 then
		local nMyMaxGemLevel = FightScore_GetEquipGemMaxLevel()
		local lstr = ""
		if nMyMaxGemLevel < 3 then
			lstr = "#{PFZY_140613_02}"
		else
			lstr = ""..nMyMaxGemLevel
		end
		FightScoreFrame_Lace1_Text2:SetText( "#{PFZYYH_160224_4}"..ScriptGlobal_Format("#{PFZYYH_160224_3}", lstr ) )
		FightScoreFrame_Lace1_Text3:SetText( ScriptGlobal_Format("#{PFZYYH_160224_7}", ""..g_ScoreBaseParam ) )
	else
		local lstr = ""..(tonumber(se)+2)
		FightScoreFrame_Lace1_Text2:SetText( "#{PFZYYH_160224_2}"..ScriptGlobal_Format("#{PFZYYH_160224_3}", lstr ) )
		FightScoreFrame_Lace1_Text3:SetText( ScriptGlobal_Format("#{PFZYYH_160224_6}", lstr ) )
	end
	--[[
		
	
	if g_FightScore_CurGemLevel < 3 then
		local szCurVipLevel = ScriptGlobal_Format("#{PFZY_140613_01}", "#{PFZY_140613_02}", 3)
		FightScoreFrame_Lace1_Text:SetText(szCurVipLevel)
	else
		local szCurVipLevel = ScriptGlobal_Format("#{PFZY_140613_01}", g_ScoreBaseParam, g_ScoreBaseParam)
		FightScoreFrame_Lace1_Text:SetText(szCurVipLevel)
	end
	]]
	
	-------------------------------------界面的上面部分：结束-------------------------------------
	this:Show()
	-------------------------------------界面的左侧部分：开始-------------------------------------
	local SelfLevel = Player:GetLevel()
	FightScore_Left(SelfLevel, bEquipMaster)
	-------------------------------------界面的左侧部分：结束-------------------------------------
	-------------------------------------界面的右侧部分：开始-------------------------------------
	FightScoreFrame_Charts_SetButtonSelected(g_myCurrentSelect)
	FightScore_Right(g_myCurrentSelect)
	FightScoreFrame_Charts:Flash()
	-------------------------------------界面的右侧部分：结束-------------------------------------

	this:Show()

end

function FightScore_Right(nIndex)

	----------------------------------------------------------------
	--清理上次的东西，必须做这一步，否则崩
	--注意顺序，先释放，后清空，否则崩
	for num=1, table.getn(g_ChildWindow) do
		g_ChildWindow[num]:SetActionItem(-1)
	end
	g_ChildWindow = {}

	FightScore_CleanRightActionItemInfo()

	if FightScoreFrame_List2_Window then
		FightScoreFrame_List2_Window:CleanAllElement("FightScore")
	else
		return
	end
	
	map_index = m_ButtonIndexMap[nIndex]

	------------------------------------------------------------------------------------------------------------------------------
	--nIndex=01 装备
	if map_index == 1 then
		FightScore_EquipPageUpdate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=02 宝石
	elseif map_index == 2 then
		FightScore_GemPageUpdate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=03 强化
	elseif map_index == 3 then
		FightScore_StrengthRightPanleUpDate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=04 暗器
	elseif map_index == 4 then
		FightScore_DarkRightPanleUpDate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=5 神鼎
	elseif map_index == 5 then
		FightScore_SMWDRightPanleUpDate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=06 资质
	elseif map_index == 6 then
		FightScore_ZiZhiRightPanleUpDate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=07 刻铭
	elseif map_index == 7 then
		FightScore_KeMingPageUpdate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=08 附体
	elseif map_index == 8 then
		FightScore_FuTiPageUpdate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=09 雕纹
	elseif map_index == 9 then
		FightScore_DiaoWenRightPanleUpDate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=10 子女
	elseif map_index == 10 then
		FightScore_InfantRightPanleUpDate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=11 武魂
	elseif map_index == 11 then
		FightScore_WuhunPageUpdate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=12 龙纹
	elseif map_index == 12 then
		FightScore_LongWenRightPanleUpDate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=13 精通
	elseif map_index == 13 then
		FightScore_JingTongPageUpdate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=14 真元
	elseif map_index == 14 then
		FightScore_ZhenYuanPageUpdate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --nIndex=15 令牌
	elseif map_index == 15 then
		FightScore_LingPaiPageUpdate()
		return
	-- ----------------------------------------------------------------------------------------------------------------------
    elseif map_index == 16 then
        FightScore_XiaYinPageUpdate()
        return
	elseif map_index == 17 then
		FightScore_MartialPageUpDate()
		return
	elseif map_index == 18 then
		FightScore_XingZhenPageUpdate()
		return
	elseif map_index == 19 then
		FightScore_UnderArmourPageUpdate()
		return
	elseif map_index == 20 then
		FightScore_ZongMenEquipPageUpdate()
		return
	end
	--公共
	FightScoreFrame_List2_Window:Flash()
	this:Show()
end

--	必须先调用这个玩意
function FightScore_CalculateAllScore()
	--如果有穿着的装备，检查装备上的宝石最高等级
	local SelfMaxGemLevel = 0

	--这里需要检测玩家装备上宝石的最高等级
	SelfMaxGemLevel = FightScore_GetEquipGemMaxLevel()
	local st,se = FightScoreFrame_Lace1_ListXiala:GetCurrentSelect()
	if se >= 1 then
		SelfMaxGemLevel = tonumber(se) + 2
	end
	g_FightScore_CurGemLevel = SelfMaxGemLevel
	if g_ScoreBaseParam < SelfMaxGemLevel then
		g_ScoreBaseParam = SelfMaxGemLevel
	end
	g_FightScore_CurGemLevel = SelfMaxGemLevel
	g_FightScore_GemStdParam = g_ScoreBaseParam
	FightScore_GemScoreCalculate()
	FightScore_CalculateGemTotalScore()

	g_FightScore_GemStdParam = g_ScoreBaseParam
	--	先算一遍，看是否需要提升宝石标准等级
	if se < 1 and g_FightScore_GemTotalScore >= 80 and g_ScoreBaseParam < 9 then
		g_FightScore_GemStdParam = g_ScoreBaseParam +1
		FightScore_GemScoreCalculate()
		FightScore_CalculateGemTotalScore()
	end

	FightScore_CalculateStrengthScore()
	FightScore_CalculateZiZhiScore()
	FightScore_CalculateLongWenScore()
	FightScore_CalculateDiaoWenScore()
	FightScore_CalculateEquitScore() --装备
	FightScore_CalculateKeMingScore() --刻铭
	FightScore_CalculateFuTiScore() --附体
	FightScore_CalculateWuHunScore() --武魂
	FightScore_CalculateJingTongScore() --精通
	FightScore_CalculateZhenYuanScore() --真元
	FightScore_CalculateLingPaiScore() --令牌
	FightScore_CalculateDarkScore()
	FightScore_CalculateInfantScore()
	FightScore_CalculateShenMuWangDingScore()
	FightScore_CalculateXiaYinScore()
	FightScore_CalcMartialSocre()
	FightScore_CalcXingZhenScore()
	FightScore_CalcUnderArmourScore()
	FightScore_CalcZongMenEquipScore()
	
	return g_ScoreBaseParam
end

function FightScore_Left(SelfLevel, bEquipMaster)

	if SelfLevel <= 29 then
		this:Hide()
	end

	g_myContentButton = {}
	FightScoreFrame_Charts:CleanAllElement("FightScore")
	FightScoreFrame_List2_Window:CleanAllElement("FightScore")


	local menpaiID = Player : GetData("MEMPAI");

	local left_1 = "set:Shoulder2 image:Shoulder2_16"--装备
	local left_2 = "set:Gem6_2 image:Gem6_2_2"--宝石
	local left_3 = "set:CircularTaskTool47 image:CircularTaskTool47_12"--强化
	local left_4 = "set:Fabao image:Fabao_1"--暗器
	local left_5 = "set:SMWD_Icon image:SMWD_Icon_9"--神鼎
	local left_6 = "set:Charm5 image:Charm5_8"--资质
	local left_7 = "set:Charm3 image:Charm3_2"--刻铭
	local left_8 = "set:FightSkillXinShou image:FightSkillXinShou_11"--附体
	local left_9 = "set:Tattoo image:Tattoo_13"--雕纹
	local left_10 = "set:IMShow image:IMShow_13"--子女
	local left_11 = ""
	if menpaiID==0 or menpaiID==7 or menpaiID==2 or menpaiID==1 or menpaiID == 14 or menpaiID == 13 then --少林、天山、丐帮、明教 menpai15mptodo
		left_11="set:Fabao image:Fabao_4"
	else
		left_11="set:Fabao image:Fabao_5"--武魂
	end
	local left_11_1 = "set:Fabao image:Fabao_4"--武魂:少林、天山、丐帮、明教
	local left_12 = "set:CircularTaskTool33 image:CircularTaskTool33_6"--龙纹
	local left_13 = "set:CircularTaskTool49 image:CircularTaskTool49_6"--精通
	local left_14 = "set:ZhenYuan1 image:ZhenYuan1_15"--真元
	local left_15 = "set:EquipLingPai image:EquipLingPai_5"--令牌
    local left_16 = "set:HaoXiaYin2 image:HaoXiaYin2_8" --侠印
	local left_17 = "set:Ach_Icon image:Ach_Icon_14" --武意
	local left_18 = "set:Rune01 image:Rune01_8" --无字
	local left_19 = "set:Armor1 image:Armor1_6" --星盘
	local left_20 = "set:ZongMenToken2 image:ZongMenToken2_14" --宗门装备

	-- 刷新显示前清空左侧列表
	Button_Left = {}
	m_ButtonIndexMap = {}

	if FightScore_CheckButtonState(1, 1) == 1 then
		FightScore_AddOneItem("#{PFZY_140613_03}", nil, left_1, g_FightScore_TotalScore[1])	--装备
	end
	if FightScore_CheckButtonState(1, 2) == 1 then
		FightScore_AddOneItem("#{PFZY_140613_04}", nil, left_2, g_FightScore_TotalScore[2])	--宝石
	end
	if FightScore_CheckButtonState(1, 3) == 1 then
		FightScore_AddOneItem("#{PFZY_140613_05}", nil, left_3, g_FightScore_TotalScore[3])	--强化
	end
	if FightScore_CheckButtonState(1, 4) == 1 then
		FightScore_AddOneItem("#{PFZY_140613_06}", nil, left_4, g_FightScore_TotalScore[4])	--暗器
	end
	if FightScore_CheckButtonState(1, 5) == 1 then
		FightScore_AddOneItem("#{PFZY_140613_175}", nil, left_5, g_FightScore_TotalScore[5])--神鼎
	end
	if FightScore_CheckButtonState(1, 6) == 1 then
		FightScore_AddOneItem("#{PFZY_140613_07}", nil, left_6, g_FightScore_TotalScore[6])	--资质
	end
	if FightScore_CheckButtonState(1, 7) == 1 then
		FightScore_AddOneItem("#{PFZY_140613_08}", nil, left_7, g_FightScore_TotalScore[7])	--刻铭	
	end
	
	if bEquipMaster == 0 then
		if SelfLevel >= 30 and SelfLevel <= 44 then
			if FightScore_CheckButtonState(0, 8) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_09}", ScriptGlobal_Format("#{PFZY_140613_17}",45), left_8, g_FightScore_TotalScore[8])	--附体： 灰态
			end
	
		elseif SelfLevel >= 45 and SelfLevel <= 49 then
			if FightScore_CheckButtonState(1, 8) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_09}", nil, left_8, g_FightScore_TotalScore[8])	--附体： 正常
			end
			if FightScore_CheckButtonState(0, 9) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_10}", ScriptGlobal_Format("#{PFZY_140613_17}",50), left_9, g_FightScore_TotalScore[9])	--雕纹： 灰态
			end
			if FightScore_CheckButtonState(0, 10) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_11}", ScriptGlobal_Format("#{PFZY_140613_17}",50), left_10, g_FightScore_TotalScore[10])	--子女： 灰态
			end
	
		elseif SelfLevel >= 50 and SelfLevel <= 59 then
			if FightScore_CheckButtonState(1, 8) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_09}", nil, left_8, g_FightScore_TotalScore[8])	--附体： 正常
			end
			if FightScore_CheckButtonState(1, 9) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_10}", nil, left_9, g_FightScore_TotalScore[9])	--雕纹： 正常
			end
			if FightScore_CheckButtonState(1, 10) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_11}", nil, left_10, g_FightScore_TotalScore[10])	--子女： 正常
			end
			if FightScore_CheckButtonState(0, 11) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_12}", ScriptGlobal_Format("#{PFZY_140613_17}",65), left_11, g_FightScore_TotalScore[11])	--武魂： 灰态
			end
		elseif SelfLevel >= 60 and SelfLevel <= 64 then
			if FightScore_CheckButtonState(1, 8) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_09}", nil, left_8, g_FightScore_TotalScore[8])	--附体： 正常
			end
			if FightScore_CheckButtonState(1, 9) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_10}", nil, left_9, g_FightScore_TotalScore[9])	--雕纹： 正常
			end
			if FightScore_CheckButtonState(1, 10) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_11}", nil, left_10, g_FightScore_TotalScore[10])	--子女： 正常
			end
			if FightScore_CheckButtonState(1, 20) == 1 then
				FightScore_AddOneItem("#{PFZY_230830_01}", nil, left_20, g_FightScore_TotalScore[20])	--宗门装备： 正常
			end
			if FightScore_CheckButtonState(0, 11) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_12}", ScriptGlobal_Format("#{PFZY_140613_17}",65), left_11, g_FightScore_TotalScore[11])	--武魂： 灰态
			end
		elseif SelfLevel >= 65 and SelfLevel <= 74 then
			if FightScore_CheckButtonState(1, 8) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_09}", nil, left_8, g_FightScore_TotalScore[8])	--附体： 正常
			end
			if FightScore_CheckButtonState(1, 9) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_10}", nil, left_9, g_FightScore_TotalScore[9])	--雕纹： 正常
			end
			if FightScore_CheckButtonState(1, 10) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_11}", nil, left_10, g_FightScore_TotalScore[10])	--子女： 正常
			end
			if FightScore_CheckButtonState(1, 20) == 1 then
				FightScore_AddOneItem("#{PFZY_230830_01}", nil, left_20, g_FightScore_TotalScore[20])	--宗门装备： 正常
			end
			if FightScore_CheckButtonState(1, 11) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_12}", nil, left_11, g_FightScore_TotalScore[11])	--武魂： 正常
			end
			if FightScore_CheckButtonState(0, 18) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_200424_01}", ScriptGlobal_Format("#{PFZY_140613_17}",75), left_18, g_FightScore_TotalScore[18])	--无字谱： 灰态
			end
		elseif SelfLevel >= 75 and SelfLevel <= 79 then
			if FightScore_CheckButtonState(1, 8) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_09}", nil, left_8, g_FightScore_TotalScore[8])	--附体： 正常
			end
			if FightScore_CheckButtonState(1, 9) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_10}", nil, left_9, g_FightScore_TotalScore[9])	--雕纹： 正常
			end
			if FightScore_CheckButtonState(1, 10) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_11}", nil, left_10, g_FightScore_TotalScore[10])	--子女： 正常
			end
			if FightScore_CheckButtonState(1, 20) == 1 then
				FightScore_AddOneItem("#{PFZY_230830_01}", nil, left_20, g_FightScore_TotalScore[20])	--宗门装备： 正常
			end
			if FightScore_CheckButtonState(1, 11) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_12}", nil, left_11, g_FightScore_TotalScore[11])	--武魂： 正常
			end
			if FightScore_CheckButtonState(1, 18) == 1 then
				FightScore_AddOneItem("#{PFZY_200424_01}", nil, left_18, g_FightScore_TotalScore[18])	--无字谱： 正常
			end
			if FightScore_CheckButtonState(0, 12) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_13}", ScriptGlobal_Format("#{PFZY_140613_17}",80), left_12, g_FightScore_TotalScore[12])	--龙纹： 灰态
			end
			if FightScore_CheckButtonState(0, 13) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_14}", ScriptGlobal_Format("#{PFZY_140613_17}",80), left_13, g_FightScore_TotalScore[13])	--精通： 灰态
			end
			if FightScore_CheckButtonState(0, 14) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_15}", ScriptGlobal_Format("#{PFZY_140613_17}",80), left_14, g_FightScore_TotalScore[14])	--真元： 灰态
			end
			if FightScore_CheckButtonState(0, 15) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_16}", ScriptGlobal_Format("#{PFZY_140613_17}",80), left_15, g_FightScore_TotalScore[15])	--令牌： 灰态
			end
		elseif SelfLevel >= 80 then
			if FightScore_CheckButtonState(1, 8) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_09}", nil, left_8, g_FightScore_TotalScore[8])	--附体： 正常
			end
			if FightScore_CheckButtonState(1, 9) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_10}", nil, left_9, g_FightScore_TotalScore[9])	--雕纹： 正常
			end
			if FightScore_CheckButtonState(1, 10) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_11}", nil, left_10, g_FightScore_TotalScore[10])	--子女： 正常
			end
			if FightScore_CheckButtonState(1, 20) == 1 then
				FightScore_AddOneItem("#{PFZY_230830_01}", nil, left_20, g_FightScore_TotalScore[20])	--宗门装备： 正常
			end
			if FightScore_CheckButtonState(1, 11) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_12}", nil, left_11, g_FightScore_TotalScore[11])	--武魂： 正常
			end
			if FightScore_CheckButtonState(1, 18) == 1 then
				FightScore_AddOneItem("#{PFZY_200424_01}", nil, left_18, g_FightScore_TotalScore[18])	--无字谱： 正常
			end
			if FightScore_CheckButtonState(1, 12) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_13}", nil, left_12, g_FightScore_TotalScore[12])	--龙纹： 正常
			end
			if FightScore_CheckButtonState(1, 13) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_14}", nil, left_13, g_FightScore_TotalScore[13])	--精通： 正常
			end
			if FightScore_CheckButtonState(1, 14) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_15}", nil, left_14, g_FightScore_TotalScore[14])	--真元： 正常
			end
			if FightScore_CheckButtonState(1, 15) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_16}", nil, left_15, g_FightScore_TotalScore[15])	--令牌： 正常
			end
			if SelfLevel >= 85 then
				if FightScore_CheckButtonState(1, 16) == 1 then
					FightScore_AddOneItem("#{PFZY_140613_220}", nil, left_16, g_FightScore_TotalScore[16])	--侠印： 正常
				end
				if FightScore_CheckButtonState(1, 17) == 1 then
					FightScore_AddOneItem("#gFF0FA0武意", nil, left_17, g_FightScore_TotalScore[17])	--武意：正常
				end
				if FightScore_CheckButtonState(1, 19) == 1 then
					FightScore_AddOneItem("#{PFZY_220915_01}", nil, left_19, g_FightScore_TotalScore[19])	--星盘：正常
				end
			else
				if FightScore_CheckButtonState(0, 16) == 1 then
					FightScore_AddOneItem_Hui("#{PFZY_140613_220}", ScriptGlobal_Format("#{PFZY_140613_17}",85), left_16, g_FightScore_TotalScore[16])	--侠印： 灰态
				end
				if FightScore_CheckButtonState(0, 17) == 1 then
					FightScore_AddOneItem_Hui("#gFF0FA0武意", string.format("#cFF0000%s级开放",85), left_17, g_FightScore_TotalScore[17])
				end
				if FightScore_CheckButtonState(0, 19) == 1 then
					FightScore_AddOneItem_Hui("#{PFZY_220915_01}", ScriptGlobal_Format("#{PFZY_140613_17}", 85), left_19, g_FightScore_TotalScore[19])	--星盘：灰态
				end
			end
		end
	else
		if SelfLevel >= 30 and SelfLevel <= 39 then
			if FightScore_CheckButtonState(0, 9) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_10}", ScriptGlobal_Format("#{PFZY_140613_17}",50), left_9, g_FightScore_TotalScore[9])	 --雕纹： 灰态
			end
		elseif SelfLevel >= 40 and SelfLevel <= 44 then
			if FightScore_CheckButtonState(1, 9) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_10}", nil, left_9, g_FightScore_TotalScore[9])	--雕纹： 正常
			end
			if FightScore_CheckButtonState(0, 8) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_09}", ScriptGlobal_Format("#{PFZY_140613_17}",45), left_8, g_FightScore_TotalScore[8])	--附体： 灰态
			end
		elseif SelfLevel >= 45 and SelfLevel <= 49 then
			if FightScore_CheckButtonState(1, 8) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_09}", nil, left_8, g_FightScore_TotalScore[8])	--附体： 正常
			end
			if FightScore_CheckButtonState(1, 9) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_10}", nil, left_9, g_FightScore_TotalScore[9])	--雕纹： 正常
			end
			if FightScore_CheckButtonState(0, 10) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_11}", ScriptGlobal_Format("#{PFZY_140613_17}",50), left_10, g_FightScore_TotalScore[10])	--子女： 灰态
			end
		elseif SelfLevel >= 50 and SelfLevel <= 54 then
			if FightScore_CheckButtonState(1, 8) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_09}", nil, left_8, g_FightScore_TotalScore[8])	--附体： 正常
			end
			if FightScore_CheckButtonState(1, 9) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_10}", nil, left_9, g_FightScore_TotalScore[9])	--雕纹： 正常
			end
			if FightScore_CheckButtonState(1, 10) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_11}", nil, left_10, g_FightScore_TotalScore[10])	--子女： 正常
			end
			if FightScore_CheckButtonState(0, 11) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_12}", ScriptGlobal_Format("#{PFZY_140613_17}",55), left_11, g_FightScore_TotalScore[11])	--武魂： 灰态
			end
		elseif SelfLevel >= 55 and SelfLevel <= 59 then
			if FightScore_CheckButtonState(1, 8) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_09}", nil, left_8, g_FightScore_TotalScore[8])	--附体： 正常
			end
			if FightScore_CheckButtonState(1, 9) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_10}", nil, left_9, g_FightScore_TotalScore[9])	--雕纹： 正常
			end
			if FightScore_CheckButtonState(1, 10) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_11}", nil, left_10, g_FightScore_TotalScore[10])	--子女： 正常
			end
			if FightScore_CheckButtonState(1, 11) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_12}", nil, left_11, g_FightScore_TotalScore[11])	--武魂： 正常
			end
			if FightScore_CheckButtonState(0, 12) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_13}", ScriptGlobal_Format("#{PFZY_140613_17}",70), left_12, g_FightScore_TotalScore[12])	--龙纹： 灰态
			end
			if FightScore_CheckButtonState(0, 13) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_14}", ScriptGlobal_Format("#{PFZY_140613_17}",70), left_13, g_FightScore_TotalScore[13])	--精通： 灰态
			end
		elseif SelfLevel >= 60 and SelfLevel <= 69 then
			if FightScore_CheckButtonState(1, 8) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_09}", nil, left_8, g_FightScore_TotalScore[8])	--附体： 正常
			end
			if FightScore_CheckButtonState(1, 9) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_10}", nil, left_9, g_FightScore_TotalScore[9])	--雕纹： 正常
			end
			if FightScore_CheckButtonState(1, 10) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_11}", nil, left_10, g_FightScore_TotalScore[10])	--子女： 正常
			end
			if FightScore_CheckButtonState(1, 20) == 1 then
				FightScore_AddOneItem("#{PFZY_230830_01}", nil, left_20, g_FightScore_TotalScore[20])	--宗门装备： 正常
			end
			if FightScore_CheckButtonState(1, 11) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_12}", nil, left_11, g_FightScore_TotalScore[11])	--武魂： 正常			
			end
			if FightScore_CheckButtonState(0, 12) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_13}", ScriptGlobal_Format("#{PFZY_140613_17}",70), left_12, g_FightScore_TotalScore[12])	--龙纹： 灰态
			end
			if FightScore_CheckButtonState(0, 13) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_14}", ScriptGlobal_Format("#{PFZY_140613_17}",70), left_13, g_FightScore_TotalScore[13])	--精通： 灰态			
			end
		elseif SelfLevel >= 70 and SelfLevel <= 74 then
			if FightScore_CheckButtonState(1, 8) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_09}", nil, left_8, g_FightScore_TotalScore[8])	--附体： 正常
			end
			if FightScore_CheckButtonState(1, 9) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_10}", nil, left_9, g_FightScore_TotalScore[9])	--雕纹： 正常
			end
			if FightScore_CheckButtonState(1, 10) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_11}", nil, left_10, g_FightScore_TotalScore[10])	--子女： 正常
			end
			if FightScore_CheckButtonState(1, 20) == 1 then
				FightScore_AddOneItem("#{PFZY_230830_01}", nil, left_20, g_FightScore_TotalScore[20])	--宗门装备： 正常
			end
			if FightScore_CheckButtonState(1, 11) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_12}", nil, left_11, g_FightScore_TotalScore[11])	--武魂： 正常
			end
			if FightScore_CheckButtonState(1, 12) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_13}", nil, left_12, g_FightScore_TotalScore[12])	--龙纹： 正常
			end
			if FightScore_CheckButtonState(1, 13) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_14}", nil, left_13, g_FightScore_TotalScore[13])	--精通： 正常
			end
			if FightScore_CheckButtonState(0, 18) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_200424_01}", ScriptGlobal_Format("#{PFZY_140613_17}",75), left_18, g_FightScore_TotalScore[18])	--无字谱： 灰态			
			end
		elseif SelfLevel >= 75 and SelfLevel <= 79 then
			if FightScore_CheckButtonState(1, 8) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_09}", nil, left_8, g_FightScore_TotalScore[8])	--附体： 正常
			end
			if FightScore_CheckButtonState(1, 9) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_10}", nil, left_9, g_FightScore_TotalScore[9])	--雕纹： 正常
			end
			if FightScore_CheckButtonState(1, 10) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_11}", nil, left_10, g_FightScore_TotalScore[10])	--子女： 正常
			end
			if FightScore_CheckButtonState(1, 20) == 1 then
				FightScore_AddOneItem("#{PFZY_230830_01}", nil, left_20, g_FightScore_TotalScore[20])	--宗门装备： 正常
			end
			if FightScore_CheckButtonState(1, 11) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_12}", nil, left_11, g_FightScore_TotalScore[11])	--武魂： 正常
			end
			if FightScore_CheckButtonState(1, 12) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_13}", nil, left_12, g_FightScore_TotalScore[12])	--龙纹： 正常
			end
			if FightScore_CheckButtonState(1, 13) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_14}", nil, left_13, g_FightScore_TotalScore[13])	--精通： 正常
			end
			if FightScore_CheckButtonState(1, 18) == 1 then
				FightScore_AddOneItem("#{PFZY_200424_01}", nil, left_18, g_FightScore_TotalScore[18])		--无字谱 正常
			end
			if FightScore_CheckButtonState(0, 14) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_15}", ScriptGlobal_Format("#{PFZY_140613_17}",80), left_14, g_FightScore_TotalScore[14])	--真元： 灰态
			end
			if FightScore_CheckButtonState(0, 15) == 1 then
				FightScore_AddOneItem_Hui("#{PFZY_140613_16}", ScriptGlobal_Format("#{PFZY_140613_17}",80), left_15, g_FightScore_TotalScore[15])	--令牌： 灰态
			end
		elseif SelfLevel >= 80 then
			if FightScore_CheckButtonState(1, 8) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_09}", nil, left_8, g_FightScore_TotalScore[8])	--附体： 正常
			end
			if FightScore_CheckButtonState(1, 9) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_10}", nil, left_9, g_FightScore_TotalScore[9])	--雕纹： 正常
			end
			if FightScore_CheckButtonState(1, 10) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_11}", nil, left_10, g_FightScore_TotalScore[10])	--子女： 正常
			end
			if FightScore_CheckButtonState(1, 20) == 1 then
				FightScore_AddOneItem("#{PFZY_230830_01}", nil, left_20, g_FightScore_TotalScore[20])	--宗门装备： 正常
			end
			if FightScore_CheckButtonState(1, 11) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_12}", nil, left_11, g_FightScore_TotalScore[11])	--武魂： 正常
			end
			if FightScore_CheckButtonState(1, 12) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_13}", nil, left_12, g_FightScore_TotalScore[12])	--龙纹： 正常
			end
			if FightScore_CheckButtonState(1, 13) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_14}", nil, left_13, g_FightScore_TotalScore[13])	--精通： 正常
			end
			if FightScore_CheckButtonState(1, 18) == 1 then
				FightScore_AddOneItem("#{PFZY_200424_01}", nil, left_18, g_FightScore_TotalScore[18])		--无字谱 正常
			end
			if FightScore_CheckButtonState(1, 14) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_15}", nil, left_14, g_FightScore_TotalScore[14])	--真元： 正常
			end
			if FightScore_CheckButtonState(1, 15) == 1 then
				FightScore_AddOneItem("#{PFZY_140613_16}", nil, left_15, g_FightScore_TotalScore[15])	--令牌： 正常
			end
			if SelfLevel >= 85 then
				if FightScore_CheckButtonState(1, 16) == 1 then
					FightScore_AddOneItem("#{PFZY_140613_220}", nil, left_16, g_FightScore_TotalScore[16])	--侠印： 正常
				end
				if FightScore_CheckButtonState(1, 17) == 1 then
					FightScore_AddOneItem("#gFF0FA0武意", nil, left_17, g_FightScore_TotalScore[17])	--武意：正常
				end
				if FightScore_CheckButtonState(1, 19) == 1 then
					FightScore_AddOneItem("#{PFZY_220915_01}", nil, left_19, g_FightScore_TotalScore[19])	--星盘：正常
				end
			else
				if FightScore_CheckButtonState(0, 16) == 1 then
					FightScore_AddOneItem_Hui("#{PFZY_140613_220}", ScriptGlobal_Format("#{PFZY_140613_17}",85), left_16, g_FightScore_TotalScore[16])	--侠印： 灰态
				end
				if FightScore_CheckButtonState(0, 17) == 1 then
					FightScore_AddOneItem_Hui("#gFF0FA0武意", string.format("#cFF0000%s级开放",85), left_17, g_FightScore_TotalScore[17])
				end
				if FightScore_CheckButtonState(0, 19) == 1 then
					FightScore_AddOneItem_Hui("#{PFZY_220915_01}", ScriptGlobal_Format("#{PFZY_140613_17}", 85), left_19, g_FightScore_TotalScore[19])	--星盘：灰态
				end
			end
		end
	end

	if g_myCurrentSelect < 1 or g_myCurrentSelect > 19 then
		g_myCurrentSelect = 1
	end

	FightScoreFrame_Charts_SetButtonSelected(g_myCurrentSelect)

	FightScoreFrame_Charts:Flash()

	FightScoreFrame_Charts:SetElementsInView(g_myCurrentSelect)

	FightScore_Right(g_myCurrentSelect)

end

function FightScore_AddOneItem_Hui(sTitle, sSubTitle, strIcon)

	local ItemBar = FightScoreFrame_Charts:AddItemElement( "FightScore", "LEFT", "FightScore","" ,"")
	if ItemBar ~= nil then
		ItemBar:Disable()
		ItemBar:SetProperty("AchievementBarWindowButtonHover","DisableSection")
	end

	--先隐藏掉图片
	ItemBar:SetAchvGetedHide()
	ItemBar:SetAchievementBarIconDisImageHide()
	ItemBar:SetAchievementBarPointDisImageHide()
	ItemBar:SetAchievementBarPointImageHide()
	ItemBar:SetAchvGetHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarDateHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarProgressNameHide()

	--sTitle = "宝石"
	--sSubTitle = "美国"
	--strIcon = "Set:Gem6_2 Image:Gem6_2_2"
	if strIcon ~= nil and strIcon ~= "" then
		local sPos,_ = string.find(strIcon," ");
		local IconImageSet = string.sub(strIcon,5,sPos-1);
		local IconIamge = string.sub(strIcon,sPos+7)
		if nil ~= IconImageSet and nil ~= IconIamge then
			ItemBar:AddBarIconImage(IconImageSet,IconIamge)
		end
	end

	--显示文字：宝石
	if sTitle ~= nil then
		ItemBar:AddBarText(sTitle)
	end

	--显示文字：几十级开放
	if sSubTitle ~= nil then
		ItemBar:SetBarContentText(sSubTitle)
	end

	ItemBar:SetAchievementBarProgressNameHide()
	table.insert(g_myContentButton,ItemBar);
end

function FightScore_AddOneItem(sTitle, sSubTitle, strIcon, Score)
	local ItemBar = FightScoreFrame_Charts:AddItemElement( "FightScore", "LEFT", "FightScore","" ,"")
	if ItemBar ~= nil then
		ItemBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection")
	end

	--先隐藏掉图片
	ItemBar:SetAchvGetedHide()
	ItemBar:SetAchievementBarIconDisImageHide()
	ItemBar:SetAchievementBarPointDisImageHide()
	ItemBar:SetAchievementBarPointImageHide()
	ItemBar:SetAchvGetHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarDateHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarProgressNameHide()

	--sTitle = "宝石"
	--sSubTitle = "美国"
	--strIcon = "Set:Gem6_2 Image:Gem6_2_2"
	if strIcon ~= nil and strIcon ~= "" then
		local sPos,_ = string.find(strIcon," ");
		local IconImageSet = string.sub(strIcon,5,sPos-1);
		local IconIamge = string.sub(strIcon,sPos+7)
		if nil ~= IconImageSet and nil ~= IconIamge then
			ItemBar:AddBarIconImage(IconImageSet,IconIamge)
		end
	end

	local StarNum = 0
	if Score >=0 and Score<=20 then
		StarNum = 5
	elseif Score >=21 and Score<=40 then
		StarNum = 4
	elseif Score >=41 and Score<=60 then
		StarNum = 3
	elseif Score >=61 and Score<=80 then
		StarNum = 2
	elseif Score >=81 and Score<100 then
		StarNum = 1
	elseif Score >=100 then
		StarNum = 0
	end

	--显示文字：宝石
	if sTitle ~= nil then
		ItemBar:AddBarText(sTitle)
	end

	--显示文字：几十级开放
	if sSubTitle ~= nil then
		ItemBar:SetBarContentText(sSubTitle)
	end

	if StarNum >=1 then
		ItemBar:SetAchievementBarIconDisImageShow()
	end
	if StarNum >=2 then
		ItemBar:SetAchievementBarPointDisImageShow()
	end
	if StarNum >=3 then
		ItemBar:SetAchievementBarPointImageShow()
	end
	if StarNum >=4 then
		ItemBar:SetAchvGetShow()
	end
	if StarNum >=5 then
		ItemBar:SetAchievementBarProgressShow()
	end

	if StarNum >= 3 then	--是否显示"荐"
		ItemBar:SetAchvGetedShow()
	end
	ItemBar:SetAchievementBarProgressNameHide()
	table.insert(g_myContentButton,ItemBar);
end

function FightScoreFrame_Charts_OnItemClick()

	local sPos,ePos = string.find(arg0, "_auto_element")

	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1


	-- if Button_Left[nIndex] == 0 then
		-- return
	-- end

	if nIndex > 0 then
		FightScoreFrame_Charts_SetButtonSelected(nIndex)
		FightScoreFrame_Charts:Flash()
		g_myCurrentSelect = nIndex

		FightScore_Right(nIndex)

	end

end

function FightScoreFrame_Charts_SetButtonSelected(nIndex)

	for nButtonIndex = 1,table.getn(g_myContentButton) do
		if nil ~= g_myContentButton[nButtonIndex] then
			if Button_Left[nButtonIndex] == 0 then
				g_myContentButton[nButtonIndex]:SetBarButtonSelected(false)
				g_myContentButton[nButtonIndex]:SetProperty("MouseHollow","False")
			elseif nButtonIndex ~= nIndex then
				g_myContentButton[nButtonIndex]:SetBarButtonSelected(false)
			else
				g_myContentButton[nButtonIndex]:SetBarButtonSelected(true)
			end
		end
	end

end

function FightScoreFrame_List2_Window_OnItemClick()

	-- local sPos,ePos = string.find(arg0, "_auto_element")
	-- local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1

	-- -- if Button_Left[nIndex] == 0 then
		-- -- return
	-- -- end

	for nButtonIndex = 1,table.getn(g_myRightButton) do
		if nil ~= g_myRightButton[nButtonIndex] then
			g_myRightButton[nButtonIndex]:SetBarButtonSelected(false)
			--g_myRightButton[nButtonIndex]:SetBarButtonSelected(true)
		end
	end
	FightScoreFrame_List2_Window:Flash()

end

function FightScore_CloseClick()
	this:Hide()
end

--	打开武林风云录
function FightScoreFrame_WYFYL_Button()
	--使用nIndex作为参数，这样武林风录怎么插入这里都不用改
	FightScore_WYFYL_List = {
		[1] = -1,
		[2] = 3,
		[3] = -1,
		[4] = -1,
		[5] = -1,
		[6] = -1,
		[7] = -1,
		[8] = 4,
		[9] = 5,
		[10] = 17,
		[11] = 6,
		[12] = 12,
		[13] = 18,
		[14] = 10,
		[15] = -1,
		[16] = -1,
		[17] = 24,
		[18] = 27,
		[19] = 28,
		[20] = 30,
	}
	
	local map_index = m_ButtonIndexMap[g_myCurrentSelect]
	if map_index == 4 then
		local SelfLevel = Player:GetLevel()
		if SelfLevel < 75 then
			PushEvent("OPEN_FENGYUNLU_WITH_ID", 0)
		elseif SelfLevel < 90 then
			PushEvent("OPEN_FENGYUNLU_WITH_ID", 9)
		else
			local nNeedLevel = LifeAbility:GetWearedEquip_NeedLevel(17)
			if nNeedLevel == 90 then
				PushEvent("OPEN_FENGYUNLU_WITH_ID", 22)
			else
				PushEvent("OPEN_FENGYUNLU_WITH_ID", 14)
			end		
		end
	elseif map_index ~= nil then
		PushEvent("OPEN_FENGYUNLU_WITH_ID", FightScore_WYFYL_List[map_index])
	end
end

function FightScoreFrame_Shop_Goto(Fenye, Tag, Shop)
	if(IsWindowShow("YuanbaoShop")) then
		CloseWindow("YuanbaoShop", true)
	end
	PushEvent("TOGGLE_YUANBAOSHOP", Fenye, -1, -1, Tag, Shop)
end

--	打开元宝商店
function FightScoreFrame_Shop_Button()
	
	local map_index = m_ButtonIndexMap[g_myCurrentSelect]
	
	--map_index=01 装备
	if map_index == 1 then
		FightScoreFrame_Shop_Goto(0, 4, 2)
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=02 宝石
	elseif map_index == 2 then
		if g_ScoreBaseParam < 7 then
			FightScoreFrame_Shop_Goto(0, 2, g_ScoreBaseParam - 2 )
		else
			FightScoreFrame_Shop_Goto(4, 1, 1 )
		end
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=03 强化
	elseif map_index == 3 then
		FightScoreFrame_Shop_Goto(0, 4, 2)
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=04 暗器
	elseif map_index == 4 then
		FightScoreFrame_Shop_Goto(0, 4, 2)
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=5 神鼎
	elseif map_index == 5 then
		FightScoreFrame_Shop_Goto(0, 4, 3)
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=06 资质
	elseif map_index == 6 then
		FightScoreFrame_Shop_Goto(0, 4, 2)
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=07 刻铭
	elseif map_index == 7 then
		FightScoreFrame_Shop_Goto(0, 4, 2)
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=08 附体
	elseif map_index == 8 then
		FightScoreFrame_Shop_Goto(0, 3, 4)
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=09 雕纹
	elseif map_index == 9 then
		FightScoreFrame_Shop_Goto(1, 4, 6)
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=10 子女
	elseif map_index == 10 then
		FightScoreFrame_Shop_Goto(0, 4, 2)
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=11 武魂
	elseif map_index == 11 then
		FightScoreFrame_Shop_Goto(0, 4, 2)
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=12 龙纹
	elseif map_index == 12 then
		PushDebugMessage( "#{PFZY_140613_196}" )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=13 精通
	elseif map_index == 13 then
		PushDebugMessage( "#{PFZY_140613_195}" )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=14 真元
	elseif map_index == 14 then
		FightScoreFrame_Shop_Goto(0, 4, 3)
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=15 令牌
	elseif map_index == 15 then
		FightScoreFrame_Shop_Goto(0, 4, 2)
		return
	elseif map_index == 16 then
		PushDebugMessage("#{PFZY_140613_208}")
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	elseif map_index == 17 then
		FightScoreFrame_Shop_Goto(0, 4, 1)
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	elseif map_index == 18 then
		PushDebugMessage("#{PFZY_200424_35}")
		return
	elseif map_index == 19 then
		FightScoreFrame_Shop_Goto(0, 4, 2)
	--	PushDebugMessage("#H元宝商店不出售星盘相关物品。")
		return
	elseif map_index == 20 then
	--	FightScoreFrame_Shop_Goto(0, 0, 0)
		PushDebugMessage("#{XWXT_230825_14}")
		return
	end
end

--	打开活动日程
function FightScoreFrame_Huodong_Button()
	
	local map_index = m_ButtonIndexMap[g_myCurrentSelect]
	
	--map_index=01 装备
	if map_index == 1 then
		--OnOpenCampaign(36) 
		PushEvent("OPEN_CAMPAINLISTNEW",185 )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=02 宝石
	elseif (map_index == 2) then
		--OnOpenCampaign(34)
		PushEvent("OPEN_CAMPAINLISTNEW",92 )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=03 强化
	elseif (map_index == 3) then
		--OnOpenCampaign(46)
		PushEvent("OPEN_CAMPAINLISTNEW",158 )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=04 暗器
	elseif (map_index == 4) then
		PushEvent("OPEN_CAMPAINLISTNEW",108 )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=5 神鼎
	elseif (map_index == 5) then
		PushDebugMessage( "#{PFZY_140613_180}" )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=06 资质
	elseif (map_index == 6) then
		PushDebugMessage( "#{PFZY_140613_70}" )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=07 刻铭
	elseif (map_index == 7) then
		--OnOpenCampaign(42)
		PushEvent("OPEN_CAMPAINLISTNEW",158 )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=08 附体
	elseif (map_index == 8) then
		--OnOpenCampaign(47) 
		PushEvent("OPEN_CAMPAINLISTNEW",179 )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=09 雕纹
	elseif (map_index == 9) then
		--OnOpenCampaign(98) --tony
		PushEvent("OPEN_CAMPAINLISTNEW",19 )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=10 子女
	elseif (map_index == 10) then
		--OnOpenCampaign(120)
		PushEvent("OPEN_CAMPAINLISTNEW",84 )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=11 武魂
	elseif (map_index == 11) then
		--OnOpenCampaign(116)
		PushEvent("OPEN_CAMPAINLISTNEW",19 )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=12 龙纹
	elseif (map_index == 12) then
		--OnOpenCampaign(334)
		PushEvent("OPEN_CAMPAINLISTNEW",26 )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=13 精通
	elseif (map_index == 13) then
		--OnOpenCampaign(402)
		PushEvent("OPEN_CAMPAINLISTNEW",312 )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=14 真元
	elseif (map_index == 14) then
		--OnOpenCampaign(120)
		PushEvent("OPEN_CAMPAINLISTNEW",84 )
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	-- --map_index=15 令牌
	elseif (map_index == 15) then
		PushDebugMessage( "#{PFZY_140613_185}" )
		return
	elseif map_index == 16 then
		--if GetIndexInTodayCampaignList(504) >= 0 then
		--	OnOpenCampaign(504)
		--elseif GetIndexInTodayCampaignList(505) >= 0 then
		--	OnOpenCampaign(505)
		--else
			PushDebugMessage("#{PFZY_140613_209}")
		--end
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	elseif map_index == 17 then
		PushDebugMessage("#{PFZY_171016_02}")
		return
	-- ----------------------------------------------------------------------------------------------------------------------
	elseif map_index == 18 then
		PushEvent("OPEN_CAMPAINLISTNEW",391 )
		return
	elseif map_index == 19 then
	--	PushEvent("OPEN_CAMPAINLISTNEW", 391)
		PushDebugMessage("#{PFZY_220915_32}")
		return
	elseif map_index == 20 then
	--	PushEvent("OPEN_CAMPAINLISTNEW", 0)
		PushDebugMessage("#{PFZY_230830_16}")
		return
	end
end

--	获取装备的宝石等级
--	pIndex	-	装备位
--	gIndex	-	孔位
function FightScore_GetEquipGemLevel(pIndex, gIndex)
	if pIndex < 0 then
		return -1
	end

	if gIndex < 0 or gIndex > 4 then
		return -1
	end

	local tempEquip = EnumAction(pIndex, "equip");
	if tempEquip:GetID() < 0 then
		return -1
	end

	local nGemLevel = tempEquip:GetEquipGemLevel(gIndex)
	return nGemLevel
end

--	获取装备宝石的最大等级
function FightScore_GetEquipGemMaxLevel()
	local ntempLevel = 0
	for _, vItem in g_Equip_TypeList do
		local nTempEquip = EnumAction(vItem.equipIndex, "equip");
		if nTempEquip:GetID() >= 0 then
			local nGemSlotNum = nTempEquip:GetEquipGemSlotNum()
			for i = 0, nGemSlotNum - 1 do
				local nLevel = FightScore_GetEquipGemLevel(vItem.equipIndex, i)
				if nLevel > ntempLevel then
					ntempLevel = nLevel
				end
			end
		end
	end

	return ntempLevel
end

function FightScore_CleanRightActionItemInfo()
	local nListCount = table.getn(g_myRightButton)
	if nListCount <= 0 then
		g_myRightButton = {}
		return
	end
	for i = 1, nListCount do
		if nil ~= g_myRightButton[i] then
			for j = 1, 5 do
				local itemButton = g_myRightButton[i]:GetLuaActionButton(j,"FightScore")
				if nil ~= itemButton then
					itemButton:SetActionItem(-1)
				end
			end
		end
	end

	g_myRightButton = {}
end

--	右列界面更新成宝石页
function FightScore_GemPageUpdate()
	--	先清空
	FightScore_CleanRightActionItemInfo()

	g_FightScoreRightList:CleanAllElement("FightScore")
	FightScore_AddRightEquipElement()

--	g_FightScoreRightList:AddBarIconImage2("UIIcons", "Equip_Weapon")
--	g_FightScoreRightList:SetBarIconImage2Show()
end

function FightScore_AddRightEquipElement()
	--	装备ICON
	local nListIndex = 1
	--	标题
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_18}")
	--上方描述
	local strTemp = ScriptGlobal_Format("#{PFZY_140613_19}", g_FightScore_GemStdParam, g_FightScore_GemStdParam-1, g_FightScore_GemStdParam-1)
	if g_FightScore_GemStdParam <= 3 then
		strTemp = ScriptGlobal_Format("#{PFZY_140613_19}", g_FightScore_GemStdParam, 1, 1 )
	end
	FightScoreFrame_List2_Text:SetText( strTemp )
--	FightScore_GemScoreCalculate()
	--根据玩家镶嵌的宝石最高等级，决定显示内容
--	if g_ScoreBaseParam < 3 then
--		local szCurVipLevel = ScriptGlobal_Format("#{PFZY_140613_01}", "#{PFZY_140613_02}", 3)
--		FightScoreFrame_Lace1_Text:SetText(szCurVipLevel)
--	else
--		local szCurVipLevel = ScriptGlobal_Format("#{PFZY_140613_01}", g_ScoreBaseParam, g_ScoreBaseParam)
--		FightScoreFrame_Lace1_Text:SetText(szCurVipLevel)
--	end



	for _, vItem in image_right_1 do
		local show = 1
		if Player:GetData("Is2606S") == 1 then
			if nListIndex == 16 then -- 龙纹
				show = g_FightScore_2606SValid[12]
			elseif nListIndex == 18 then -- 豪侠印
				show = g_FightScore_2606SValid[16]
			end
		end
		if show == 1 then
			local tempEquip = EnumAction(vItem.index, "equip")
			if tempEquip:GetID() >= 0 then
				FightScore_AddGemPannelElement(tempEquip:GetID(), nListIndex)
			end
		end
		nListIndex = nListIndex + 1
	end
end

--	计算单个装备宝石评分
function FightScore_GemScoreCalculate()

	local nListIndex = 1
	local nGemNumStd = 3
	local nPlayerLevel = Player:GetData("LEVEL")
	if nPlayerLevel ~= nil and tonumber(nPlayerLevel) > 79 then
		nGemNumStd = 4
	end
	for _, vItem in image_right_1 do
		--	取出装备
		local oEquip = EnumAction(vItem.index, "equip")
		--	先初始化这个玩意才行
		local nTempTotal = 0
		--	初始化装备上每个宝石的具体评分[5]为本件装备上的宝石评分
		g_FightScore_GemRealScore_Map[nListIndex] = {[1] = -1, [2] = -1, [3] = -1, [4] = -1, [5] = 0}
		for i = 1, nGemNumStd do
			--	取出宝石
			if oEquip:GetID() > 0 then
				LifeAbility : SplitWearedEquipGem_Update( vItem.index )
				local holeCount  = LifeAbility : GetWearedEquip_HoleCount(vItem.index)
				if i <= holeCount then
					LifeAbility : GemContainer_Update()
					local nGemPos = i - 1
					nGemID = LifeAbility : SplitWearedEquipOneGem( vItem.index, nGemPos )
					--	找到评分
					local nScore = DataPool:GetGemScore_FromGemTableIndex(nGemID)
					if nScore > 0 then
						g_FightScore_GemRealScore_Map[nListIndex][i] = nScore
					end
--					--	形成表格
					g_FightScore_GemRealScore_Map[nListIndex][i] = nScore
					if nScore >= g_GemLevelScore_Std_List[g_FightScore_GemStdParam] then
						g_FightScore_GemRealScore_Map[nListIndex][i] = g_GemLevelScore_Std_List[g_FightScore_GemStdParam]
					end
				end
			end

			--	先把分值加起来
			if g_FightScore_GemRealScore_Map[nListIndex][i] > 0 then
				nTempTotal = nTempTotal + g_FightScore_GemRealScore_Map[nListIndex][i]
			end

		end

		--	装备上每个宝石评分相加，除以玩家base等级对应的最大宝石评分，得到的结果为推荐等级
		g_FightScore_GemRealScore_Map[nListIndex][5] = math.floor((nTempTotal / (nGemNumStd * g_GemLevelScore_Std_List[g_FightScore_GemStdParam]))*100)

		nListIndex = nListIndex + 1
	end
end

--	计算宝石总分
function FightScore_CalculateGemTotalScore()
	--	累加各装备宝石评分之和
	local nTotalScore = 0
	for i = 1, g_FightScore_EquipMax do
		nTotalScore = nTotalScore + g_FightScore_GemRealScore_Map[i][5]
	end

	--	取平均值
	g_FightScore_GemTotalScore = math.floor(nTotalScore / g_FightScore_EquipMax)

	--	返回平均值作为宝石总体推荐值
	return g_FightScore_GemTotalScore
end

--	计算单个装备雕文评分
function FightScore_CalculateDiaoWenScore()
	local nListIndex = 1
	local nTempTotalScore = 0
	g_FightScore_DiaoWenTotalScore = 0
	for _, vItem in image_right_1 do
		g_FightScore_DiaoWenRealScore_Map[nListIndex] = -1
		--	取出装备
		local oEquip = EnumAction(vItem.index, "equip")
		if oEquip:GetID() > 0 then
			local nDiaoWenID = LifeAbility:GetWearedDiaowenId(vItem.index)
			local nDiaoWenIDEx = LifeAbility:GetWearedDiaowenIdEx(vItem.index)
			local nScore = 0
			local nScoreEx = 0
			local nTempScore = 0

			if nDiaoWenIDEx <= 0 then
				--	查到分值后直接求得分数百分比并取得100以内的区间值
				nTempScore = DataPool:GetDWScore_FromDiaoWenTableIndex(nDiaoWenID)
				if nTempScore > g_FightScore_DiaoWenScore_Std_List[g_ScoreBaseParam].stdScore then
					nTempScore = 100
				else
					nTempScore = math.floor((nTempScore / g_FightScore_DiaoWenScore_Std_List[g_ScoreBaseParam].stdScore) * 100)
				end
			else
				if nDiaoWenID > 0 then
					--	取出两个雕纹评分
					nScore = DataPool:GetDWScore_FromDiaoWenTableIndex(nDiaoWenID)
					nScoreEx = DataPool:GetDWScore_FromDiaoWenTableIndex(nDiaoWenIDEx)
					local nScoreMax = nScore
					local nScoreMin = nScoreEx

					--	得出最大雕文评分和最小雕文评分
					if nScore < nScoreEx then
						nScoreMax = nScoreEx
						nScoreMin = nScore
					end

					--	对比标准分,如果实际值大于标准值，则取较小值
					if nScoreMax > g_FightScore_DiaoWenScore_Std_List[g_ScoreBaseParam].stdScore then
						nScoreMax = g_FightScore_DiaoWenScore_Std_List[g_ScoreBaseParam].stdScore
					end

					if nScoreMin > g_FightScore_DiaoWenScore_Std_List[g_ScoreBaseParam].stdScore2 then
						nScoreMin = g_FightScore_DiaoWenScore_Std_List[g_ScoreBaseParam].stdScore2
					end

					--	计算完成度
					local nStdCount = g_FightScore_DiaoWenScore_Std_List[g_ScoreBaseParam].stdScore + g_FightScore_DiaoWenScore_Std_List[g_ScoreBaseParam].stdScore2
					nTempScore = math.floor(((nScoreMax + nScoreMin) / nStdCount) * 100)
				end
			end
			g_FightScore_DiaoWenRealScore_Map[nListIndex] = nTempScore
		end
		if g_FightScore_DiaoWenRealScore_Map[nListIndex] > 0 then
			nTempTotalScore = nTempTotalScore + g_FightScore_DiaoWenRealScore_Map[nListIndex]
		end

		nListIndex = nListIndex + 1
	end

	g_FightScore_DiaoWenTotalScore = math.floor(nTempTotalScore / g_FightScore_EquipMax)
end

--	计算龙纹评分
function FightScore_CalculateLongWenScore()
	--	取出龙纹
	local oEquip = EnumAction(19, "equip")
	g_FightScore_LongWenScore_RealMap = {[1]=-1,[2]=-1,[3]=-1,[4]=-1,[5]=-1,}
	local nTempRealScore = 0
	local nTempStdScore = 0
	g_FightScore_LongWenScore_Total = 0
	if oEquip:GetID() > 0 then
		--	取得龙纹的提升等级
		local nLevel = LifeAbility:GetWearedLongWen_Level(19)
		if nLevel >= 0 then
			local nStdLevel = g_FightScore_LongWenScore_Std_List[g_ScoreBaseParam].stdLevel
			if ( nLevel > nStdLevel  ) then
				nLevel = nStdLevel
			end
			nTempRealScore = nTempRealScore + g_FightScore_LongWenScore_Level_List[nLevel]
			nTempStdScore = nTempStdScore + g_FightScore_LongWenScore_Level_List[nStdLevel]
			g_FightScore_LongWenScore_RealMap[1] = math.floor((g_FightScore_LongWenScore_Level_List[nLevel]/g_FightScore_LongWenScore_Level_List[nStdLevel])*100)
			if g_FightScore_LongWenScore_RealMap[1] > 100 then
				g_FightScore_LongWenScore_RealMap[1] = 100
			end
		end
		--	直接取得龙纹的quality就是星级
		local nQua = LifeAbility:GetWearedLongWen_Star(19);
		if nQua >= 0 then
			local nStdQua = g_FightScore_LongWenScore_Std_List[g_ScoreBaseParam].stdQua
			if ( nQua > nStdQua  ) then
				nQua = nStdQua
			end
			nTempRealScore = nTempRealScore + g_FightScore_LongWenScore_Qua_list[nQua]
			nTempStdScore = nTempStdScore + g_FightScore_LongWenScore_Qua_list[nStdQua]
			g_FightScore_LongWenScore_RealMap[2] = math.floor((g_FightScore_LongWenScore_Qua_list[nQua]/g_FightScore_LongWenScore_Qua_list[nStdQua])*100);
			if g_FightScore_LongWenScore_RealMap[2] > 100 then
				g_FightScore_LongWenScore_RealMap[2] = 100
			end
		end

		--	获取扩展属性分值
		for i = 0, 2 do
			local nExAttLevel = LifeAbility:GetWearedLongWen_AttLevel(19, i)
			if nExAttLevel > 0 then
				local nStdAttLevel = g_FightScore_LongWenScore_Std_List[g_ScoreBaseParam].stdExtraAttLevel
				if ( nExAttLevel > nStdAttLevel  ) then
					nExAttLevel = nStdAttLevel
				end
				nTempRealScore = nTempRealScore + g_FightScore_LongWenScore_ExAtt_List[nExAttLevel]
				nTempStdScore = nTempStdScore + g_FightScore_LongWenScore_ExAtt_List[nStdAttLevel]
				g_FightScore_LongWenScore_RealMap[i+3] = math.floor((g_FightScore_LongWenScore_ExAtt_List[nExAttLevel]/g_FightScore_LongWenScore_ExAtt_List[nStdAttLevel])*100)
				if g_FightScore_LongWenScore_RealMap[i+3] > 100 then
					g_FightScore_LongWenScore_RealMap[i+3] = 100
				end
			end
		end
		local nNeedLevel = LifeAbility:GetWearedEquip_NeedLevel(19)
		nTempRealScore = nTempRealScore + 10 + nNeedLevel
		nTempStdScore = nTempStdScore + 10 + nNeedLevel

		g_FightScore_LongWenScore_Total = math.floor((nTempRealScore / nTempStdScore) * 100)
	end


end

function FightScore_CalculateDarkScore()
	--	取出暗器
	local oEquip = EnumAction(17, "equip")
	local nEquipID = -1
	g_FightScore_DarkTotalScore = 0
	if oEquip ~= nil then
		nEquipID = oEquip:GetID()
	end

	if nEquipID > 0 then
		local nLevel = Player:GetData("LEVEL")
		local nNeedLevel = LifeAbility:GetWearedEquip_NeedLevel(17)
		local nGrade = LifeAbility:GetWearedDark_QualityGrade(17)

		--暗器进阶完成度
		for i,vItem in g_FightScore_DarkScore_Level_List do
			if nNeedLevel == vItem.needlevel then
				g_FightScore_DarkScore_RealMap[1].nIndex = i --携带暗器等级
				break
			end
		end

		if nNeedLevel < g_FightScore_DarkScore_Level_List[3].needlevel then
			--佩戴冰魄神针以下(不包括神针)最多推荐到冰魄
			for i,vItem in g_FightScore_DarkScore_Level_List do
				if ( i == 1 and nLevel < vItem.level ) or ( i > 1 and nLevel < vItem.level and nLevel >= g_FightScore_DarkScore_Level_List[i - 1].level ) then
					g_FightScore_DarkScore_RealMap[1].nIndexStd = i --推荐暗器等级
				end
			end
		else
			--佩戴冰魄神针以上(包括神针)推荐到金翅翎羽
			if nLevel < g_FightScore_DarkScore_Level_List[2].level then
				for i,vItem in g_FightScore_DarkScore_Level_List do
					if ( i == 1 and nLevel < vItem.level ) or ( i > 1 and nLevel < vItem.level and nLevel >= g_FightScore_DarkScore_Level_List[i - 1].level ) then
						g_FightScore_DarkScore_RealMap[1].nIndexStd = i --推荐暗器等级
					end
				end
			else
				g_FightScore_DarkScore_RealMap[1].nIndexStd = 4
			end
		end
		
		--计算暗器进阶完成度
		local nRealLevelParam = g_FightScore_DarkScore_Level_List[g_FightScore_DarkScore_RealMap[1].nIndex].param
		local nStdLevelParam = g_FightScore_DarkScore_Level_List[g_FightScore_DarkScore_RealMap[1].nIndexStd].param

		if nRealLevelParam >= nStdLevelParam then
			g_FightScore_DarkScore_RealMap[1].score = 100
		else
			g_FightScore_DarkScore_RealMap[1].score = math.floor(( nRealLevelParam / nStdLevelParam ) * 100)
		end
		
		--计算品质完成度
		for i,vItem in g_FightScore_DarkScore_Quality_List do
			if ( i == 1 and nGrade < vItem.qua ) or ( i > 1 and nGrade < vItem.qua and nGrade >= g_FightScore_DarkScore_Quality_List[i - 1].qua ) or ( i == 5 and nGrade >= vItem.qua ) then
				g_FightScore_DarkScore_RealMap[2].nIndex = i
				break
			end
		end

		g_FightScore_DarkScore_RealMap[2].nIndexStd = g_FightScore_DarkScore_StdQuality_List[g_ScoreBaseParam]

		local nRealQuaParam = g_FightScore_DarkScore_Quality_List[g_FightScore_DarkScore_RealMap[2].nIndex].param
		local nStdQuaParam = g_FightScore_DarkScore_Quality_List[g_FightScore_DarkScore_RealMap[2].nIndexStd].param
		if nRealQuaParam >= nStdQuaParam then
			g_FightScore_DarkScore_RealMap[2].score = 100
		else
			g_FightScore_DarkScore_RealMap[2].score = math.floor(( nRealQuaParam / nStdQuaParam ) * 100)
		end
		
		if nNeedLevel == g_FightScore_DarkScore_Level_List[4].needlevel then
			--金翅翎羽星级
			local humanMaxStoneLv = FightScore_GetEquipGemMaxLevel()
			local st,se = FightScoreFrame_Lace1_ListXiala:GetCurrentSelect()
			if se >= 1 then
				humanMaxStoneLv = tonumber(se) + 2
			end
			
			local humanLYStarLv = LifeAbility:GetWearedDarkLY_StarLv(17)
			if humanLYStarLv == nil or humanLYStarLv <= 0 then
				humanLYStarLv = 4
			end
			g_FightScore_DarkScore_RealMap[3].nIndex = humanLYStarLv	--实际暗器星级
			for i,vItem in g_FightScore_DarkScore_Star_List do
				if humanMaxStoneLv <= vItem.maxstonelv then
					g_FightScore_DarkScore_RealMap[3].nIndexStd = vItem.starlv 			--推荐暗器星级
					break
				end
			end
			local nRealStarParam = g_FightScore_DarkScore_StarValue_List[g_FightScore_DarkScore_RealMap[3].nIndex]
			local nStdStarParam = g_FightScore_DarkScore_StarValue_List[g_FightScore_DarkScore_RealMap[3].nIndexStd]
			if nRealStarParam >= nStdStarParam then
				g_FightScore_DarkScore_RealMap[3].score = 100
			else
				g_FightScore_DarkScore_RealMap[3].score = math.floor(( nRealStarParam / nStdStarParam ) * 100)			
			end
		
			--暗器粹毒血上限完成度
			local humanLYAddHP = LifeAbility:GetWearedDarkLY_CuiduHP(17) --实际暗器血上限
			for i,vItem in g_FightScore_DarkScore_HP_List do
				if humanMaxStoneLv <= vItem.maxstonelv then
					g_FightScore_DarkScore_RealMap[4].nIndexStd = i 			--推荐暗器血上限
					break
				end
			end
			local nRealLYHPParam = math.floor(humanLYAddHP/10688*10000)
			local nStdLYHPParam = math.floor(g_FightScore_DarkScore_HP_List[g_FightScore_DarkScore_RealMap[4].nIndexStd].maxhp/10688*10000)
			if nRealLYHPParam >= nStdLYHPParam then
				g_FightScore_DarkScore_RealMap[4].score = 100
			else
				g_FightScore_DarkScore_RealMap[4].score = math.floor(( nRealLYHPParam / nStdLYHPParam ) * 100)	
			end
			
			--暗器粹毒属性攻完成度
			local humanLYAddPro = LifeAbility:GetWearedDarkLY_CuiduPro(17) --实际暗器属性攻
			for i,vItem in g_FightScore_DarkScore_Pro_List do
				if humanMaxStoneLv <= vItem.maxstonelv then
					g_FightScore_DarkScore_RealMap[5].nIndexStd = i 			--推荐暗器属性攻
					break
				end
			end
			
			local nRealLYAddProParam = math.floor(humanLYAddPro/176*10000)
			local nStdLYAddProParam = math.floor(g_FightScore_DarkScore_Pro_List[g_FightScore_DarkScore_RealMap[5].nIndexStd].maxpro/176*10000)
			if nRealLYAddProParam >= nStdLYAddProParam then
				g_FightScore_DarkScore_RealMap[5].score = 100
			else
				g_FightScore_DarkScore_RealMap[5].score = math.floor(( nRealLYAddProParam / nStdLYAddProParam ) * 100)	
			end
			
			--暗器粹毒命中完成度
			local humanLYAddHit = LifeAbility:GetWearedDarkLY_CuiduHit(17) --实际暗器命中
			for i,vItem in g_FightScore_DarkScore_Hit_List do
				if humanMaxStoneLv <= vItem.maxstonelv then
					g_FightScore_DarkScore_RealMap[6].nIndexStd = i 			--推荐暗器命中
					break
				end
			end
			
			local nRealLYAddHitParam = math.floor(humanLYAddHit/2175*10000)
			local nStdLYAddHitParam = math.floor(g_FightScore_DarkScore_Hit_List[g_FightScore_DarkScore_RealMap[6].nIndexStd].maxhit/2175*10000)
			if nRealLYAddHitParam >= nStdLYAddHitParam then
				g_FightScore_DarkScore_RealMap[6].score = 100
			else
				g_FightScore_DarkScore_RealMap[6].score = math.floor(( nRealLYAddHitParam / nStdLYAddHitParam ) * 100)	
			end
			
			--暗器总完成度
			local nRealScore = 10+nNeedLevel+(3*nRealLevelParam*nRealQuaParam) + nRealStarParam + nRealLYHPParam + nRealLYAddProParam + nRealLYAddHitParam
			local nStdScore = 10+nNeedLevel+(3*nStdLevelParam*nStdQuaParam) + nStdStarParam + nStdLYHPParam + nStdLYAddProParam + nStdLYAddHitParam
			g_FightScore_DarkTotalScore = math.floor((nRealScore / nStdScore) * 100)
		else
			--暗器总完成度
			local nRealScore = 10+nNeedLevel+(3*nRealLevelParam*nRealQuaParam)
			local nStdScore = 10+nNeedLevel+(3*nStdLevelParam*nStdQuaParam)
			g_FightScore_DarkTotalScore = math.floor((nRealScore / nStdScore) * 100)
		end	
	end
end

function FightScore_CalculateStrengthScore()
	--	取出装备
	local nListIndex = 1
	local nTempTotal = 0;
	local nEquipCount = 0;
	g_FightScore_StrengthTotalScore = 0
	for _, vItem in image_right_1 do
		if nListIndex == 15 then
			nListIndex = nListIndex + 1
			continue
		end
		g_FightScore_StrengthScore_RealMap[nListIndex] = -1;
		local oEquip = EnumAction(vItem.index, "equip")
		if oEquip ~= nil then
			local nlevel,_,_ = oEquip:GetStrengthenLevel()
			if nlevel > 0 then
				local nStdLevel = g_FightScore_StrengthScore_StdList[g_ScoreBaseParam]
				if nlevel > nStdLevel then
					nlevel = nStdLevel
				end
				local nScore = math.floor((nlevel / g_FightScore_StrengthScore_StdList[g_ScoreBaseParam]) * 100)
				g_FightScore_StrengthScore_RealMap[nListIndex] = nScore
				nTempTotal = nTempTotal + nScore
			end
		end

		nListIndex = nListIndex + 1
		nEquipCount = nEquipCount + 1
	end

	g_FightScore_StrengthTotalScore = math.floor(nTempTotal / nEquipCount)
end

--	根据装备资质比率取得资质评分
function FightScore_GetZiZhiScoreByRate(nRate)
	local nScore = 0
	if g_FightScore_ZiZhiScore_Value_List[nRate] ~= nil then
		nScore = g_FightScore_ZiZhiScore_Value_List[nRate]
	end

	return nScore
end

--	计算资质评分
function FightScore_CalculateZiZhiScore()
	--	取出装备
	--	武魂剔除(装备列表中索引值为15)
	local nListIndex = 1
	local nTempTotal = 0
	local nEquipNum = 0	--扣除武魂
	g_FightScore_ZiZhiTotalScore = 0
	for _, vItem in image_right_1 do
		if nListIndex == 15 then
			nListIndex = nListIndex + 1
			continue
		end
		--	品阶评价、资质百分比、分值
		local tempZiZhiMap={grade=-1,rate=-1,score=-1}
		local oEquip = EnumAction(vItem.index, "equip")
		if oEquip ~= nil then
			if oEquip:IsEquipHaveZiZhi() > 0 then
				--	获取资质点
				tempZiZhiMap.grade = oEquip:GetEquipMaxAttrByAptValue()
				--	获取资质比率
				tempZiZhiMap.rate = oEquip:GetEquipMaxAttrByAptRate()
				--	获取资质评分
				local tempScore = FightScore_GetZiZhiScoreByRate(tempZiZhiMap.rate)

				if tempScore > g_FightScore_ZiZhiScore_StdList[g_ScoreBaseParam].score then
					tempScore = g_FightScore_ZiZhiScore_StdList[g_ScoreBaseParam].score
				end

				tempZiZhiMap.score = math.floor((tempScore / g_FightScore_ZiZhiScore_StdList[g_ScoreBaseParam].score)*100)
				nTempTotal = nTempTotal + tempZiZhiMap.score
				nEquipNum = nEquipNum + 1
			end
			if oEquip:GetID() <= 0 then
				nEquipNum = nEquipNum + 1
			end
		end
		g_FightScore_ZiZhiScore_RealMap[nListIndex] = tempZiZhiMap
		nListIndex = nListIndex + 1
	end

	g_FightScore_ZiZhiTotalScore = math.floor(nTempTotal / nEquipNum)
end

--	计算子女评分
function FightScore_CalculateInfantScore()
	--	有孩子才将总分置为0
	local nChildNum = Infant:GetInfantCount()
	--	先清空上次结果
	g_FightScore_InfantLevel = 0;
	g_FightScore_InfantAttrValue = 0;
	g_FightScore_InfantScore_AttrScore = -1;
	g_FightScore_InfantScore_LevelScore = -1;
	g_FightScore_InfantSkill = {};
	g_FightScore_InfantCard = {};
	g_FightScore_InfantTotalScore = 0;

	--	有孩子才能开始干别的
	if nChildNum > 0 then
		local ntempTotalScore = 0;
		local nTempStdScore = 10;
		local nTempRealScore = 10;
		--	孩子等级
		g_FightScore_InfantLevel = Infant:GetInfantLevel(0)
		local nLevelStd = g_FightScore_InfantScore_LevelList[g_FightScore_InfantScore_StdList[g_ScoreBaseParam].level]
		local nLevelReal = g_FightScore_InfantScore_LevelList[g_FightScore_InfantLevel]
		if g_FightScore_InfantLevel > g_FightScore_InfantScore_StdList[g_ScoreBaseParam].level then
			nLevelReal = nLevelStd
		end
		g_FightScore_InfantScore_LevelScore = math.floor((nLevelReal / nLevelStd) * 100)
		nTempStdScore = nTempStdScore + nLevelStd
		nTempRealScore = nTempRealScore + nLevelReal
		ntempTotalScore = ntempTotalScore + g_FightScore_InfantScore_LevelScore

		--	综合素养值
		g_FightScore_InfantAttrValue = Infant:GetMainAttribute(0)
		local nAttrStd = g_FightScore_InfantScore_AttrList[g_FightScore_InfantScore_StdList[g_ScoreBaseParam].attr]
		local nAttrReal = g_FightScore_InfantScore_AttrList[g_FightScore_InfantAttrValue]
		if g_FightScore_InfantAttrValue > g_FightScore_InfantScore_StdList[g_ScoreBaseParam].attr then
			nAttrReal = nAttrStd
		end
		g_FightScore_InfantScore_AttrScore = math.floor((nAttrReal / nAttrStd) * 100)
		nTempStdScore = nTempStdScore + nAttrStd
		nTempRealScore = nTempRealScore + nAttrReal
		ntempTotalScore = ntempTotalScore + g_FightScore_InfantScore_AttrScore
		--	技能相关
		for i = 0, 3 do
			g_FightScore_InfantSkill[i+1] = {id = -1, level = -1, score = 0}
			local nID, nLevel = Infant:GetInfantSkillInfo(0, i)
			if nID >= 0 then
				g_FightScore_InfantSkill[i+1].id = nID
				g_FightScore_InfantSkill[i+1].level = nLevel
				local nSkillLevelStd = g_FightScore_InfantScore_SkillLevel_List[g_FightScore_InfantScore_StdList[g_ScoreBaseParam].skilllevel]
				local nSkillLevelReal = g_FightScore_InfantScore_SkillLevel_List[nLevel]
				if nLevel > g_FightScore_InfantScore_StdList[g_ScoreBaseParam].skilllevel then
					nSkillLevelReal = nSkillLevelStd
				end
				g_FightScore_InfantSkill[i+1].score = math.floor((nSkillLevelReal / nSkillLevelStd) * 100)
				nTempStdScore = nTempStdScore + nSkillLevelStd
				nTempRealScore = nTempRealScore + nSkillLevelReal
				ntempTotalScore = ntempTotalScore + g_FightScore_InfantSkill[i+1].score
			end
		end


		--	卡牌
		for i = 0, 5 do
			g_FightScore_InfantCard[i+1] = {cardId=-1,yanduLevel=-1,cardQual=-1,score=-1};
			local nCardID = Infant:GetInfantCardItemIndex(0, i)
			if nCardID > 0 then
				local nCardYanDuLevel = Infant:GetInfantCardYanDuLevel(0, i)
				local nCardQual = Infant:GetInfantCardQuality(0, i)
				g_FightScore_InfantCard[i+1].cardId = nCardID
				g_FightScore_InfantCard[i+1].yanduLevel = nCardYanDuLevel
				g_FightScore_InfantCard[i+1].cardQual = nCardQual

				local nCardYanDuStdScore = g_FightScore_InfantScore_CardYanDuLevel_List[g_FightScore_InfantScore_StdList[g_ScoreBaseParam].cardlevel]
				local nCardQualStdScore = g_FightScore_InfantScore_CardQuality_List[g_FightScore_InfantScore_StdList[g_ScoreBaseParam].cardgrade]

				local nCardYanDuScore = g_FightScore_InfantScore_CardYanDuLevel_List[nCardYanDuLevel]
				if nCardYanDuScore > nCardYanDuStdScore then
					nCardYanDuScore = nCardYanDuStdScore
				end

				local nCardQualScore = g_FightScore_InfantScore_CardQuality_List[nCardQual]
				if nCardQualScore > nCardQualStdScore then
					nCardQualScore = nCardQualStdScore
				end

				local nScore = math.floor(((nCardYanDuScore + nCardQualScore)/(nCardYanDuStdScore + nCardQualStdScore)) * 100)
				nTempStdScore = nTempStdScore + nCardYanDuStdScore + nCardQualStdScore
				nTempRealScore = nTempRealScore + nCardYanDuScore + nCardQualScore
				g_FightScore_InfantCard[i+1].score = nScore
				ntempTotalScore = ntempTotalScore + g_FightScore_InfantCard[i+1].score
			end
		end

		g_FightScore_InfantTotalScore = math.floor((nTempRealScore / nTempStdScore) * 100)
	end
end

function FightScore_CalculateShenMuWangDingScore()
	g_FightScore_SMWD_Count = tonumber(Player:GetData("LianDanCount"));
	g_FightScore_SMWD_Count2 = tonumber(Player:GetData("Attack_DanYaoCount"));
	g_FightScore_SMWDScore_Total = -1
	g_FightScore_SMWDScore_Total2 = -1
	if g_FightScore_SMWD_Count >= 0 then
		local nScoreReal = g_FightScore_SMWDScore_CountList[g_FightScore_SMWD_Count].score
		local nScoreStd = g_FightScore_SMWDScore_CountList[g_FightScore_SMWDScore_StdList[g_ScoreBaseParam]].score
		if nScoreReal > nScoreStd then
			nScoreReal = nScoreStd
		end
		g_FightScore_SMWDScore_Total = math.floor((nScoreReal / nScoreStd) * 100)
	end
	if g_FightScore_SMWD_Count2 >= 0 then
		local nScoreReal = g_FightScore_SMWDScore_CountList[g_FightScore_SMWD_Count2].score
		local nScoreStd = g_FightScore_SMWDScore_CountList[g_FightScore_SMWDScore_StdList[g_ScoreBaseParam]].score
		if nScoreReal > nScoreStd then
			nScoreReal = nScoreStd
		end
		g_FightScore_SMWDScore_Total2 = math.floor((nScoreReal / nScoreStd) * 100)
	end
end

--	nImageListIndex 为 image_right_1 表中的索引
function FightScore_AddGemPannelElement(actionID, nImageListIndex)
	local ItemBar = g_FightScoreRightList:AddItemElement( "FightScoreDetail", "LEFT", "FightScore","" ,"")
	local nEquipLimit = {[14]={[0]=30,[1]=20}, [15]={[0]=65,[1]=55},[16]={[0]=80,[1]=70}, [17]={[0]=80,[1]=70}, [18]={[0]=85,[1]=85}, [19]={[0]=60,[1]=50}}	--	各种装备限制等级
	local strEquipLimit = {[14]="#{PFZY_140613_40}", [15]="#{PFZY_140613_55}",[16]="#{PFZY_140613_56}", [17]="#{PFZY_140613_57}", [18]="#{PFZY_140613_57}", [19] = "#{PFZY_140613_57}"}
	local strEquipImage = {	[14]="set:Fabao image:Fabao_2",[15]="set:Fabao image:Fabao_5",
				[16]="set:CircularTaskTool33 image:CircularTaskTool33_6",[17]="set:EquipLingPai image:EquipLingPai_5",[18]="set:HaoXiaYin2 image:HaoXiaYin2_8", [19]="set:ZongMenToken2 image:ZongMenToken2_14"}
	local isFlag = CachedTarget:GetMySelfEquipMasterFlag()
	local nPlayerlevel = Player:GetLevel()
	if ItemBar == nil then
		return
	end

	ItemBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection")

	--先隐藏掉图片
	ItemBar:SetAchvGetedHide()
	ItemBar:SetAchievementBarIconDisImageHide()
	ItemBar:SetAchievementBarPointDisImageHide()
	ItemBar:SetAchievementBarPointImageHide()
	ItemBar:SetAchvGetHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarDateHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarProgressNameHide()

	for j=1,16 do
		if j < 2 or j > 6 then
			ItemBar:Setm_newImageHide(j)
		end
	end


	--	先设置好底图
	local itemButton = ItemBar:GetLuaActionButton(1,"FightScore")
	itemButton:SetProperty("BackImage", image_right_1[nImageListIndex].back)
	if actionID > 0 then
		itemButton:SetActionItem(actionID)
	end
	local bShowStar = 1
	--	宝石部分
	if actionID > 0 then
		--	获取装备打孔数量
		LifeAbility : SplitWearedEquipGem_Update( image_right_1[nImageListIndex].index )
		local holeCount  = LifeAbility : GetWearedEquip_HoleCount(image_right_1[nImageListIndex].index)
		local nGemActionId = -1
		local nGemID = -1
		for i = 0, 3 do
			local gemButton = ItemBar:GetLuaActionButton(i+2,"FightScore")
			if gemButton ~= nil then
				--	设置背景图
				if i < holeCount then
					--	有孔，有木有宝石另说
					LifeAbility : SplitWearedEquipGem_Update(image_right_1[nImageListIndex].index)
					nGemID = LifeAbility : SplitWearedEquipOneGem( image_right_1[nImageListIndex].index, i )

					gemButton:SetToolTip("#{PFZY_140613_37}")
					if nGemID > 0 then
						local nGemAction = LifeAbility : CreateVirtualActionItem(nGemID, (image_right_1[nImageListIndex].index*4)+i);

						if nGemAction ~= nil then
							gemButton:SetActionItem(nGemAction:GetID())
							nGemAction:SetSelectStatus(0)
							ItemBar:Setm_newImage(7+i,"Face_04", "Remind3_Bak")
							ItemBar:Setm_newImageShow(7+i)
							if DataPool:GetGemScore_FromGemTableIndex(nGemID) >= g_GemLevelScore_Std_List[g_FightScore_GemStdParam] then
								ItemBar:Setm_newImageHide(7+i)
								nGemAction:SetSelectStatus(1)
--								gemButton:Enable()
							end

						else
							--	木有宝石
							gemButton:SetActionItem(-1)
							gemButton:Disable()
							gemButton:SetProperty("BackImage", "set:CommonItem image:ActionBK")
							gemButton:SetToolTip("#{PFZY_140613_37}")
						end
					end
				else
					--	木有窟窿
					if 1 == SystemSetup:IsClassic() then
						--	经典
						gemButton:SetProperty("BackImage", "set:Agname3 image:BaoShiCheckFeng")
					else
						--	唯美
						gemButton:SetProperty("BackImage", "set:WM_CommonFrame1 image:Feng")
					end
					gemButton:SetActionItem(-1)
					gemButton:SetToolTip("#{PFZY_140613_38}")
				end
			end
		end
	else
		local strNoEquipToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", image_right_1[nImageListIndex].name)

		--	隐藏所有宝石孔位
		for i = 2, 5 do
			local gemButton = ItemBar:GetLuaActionButton(i,"FightScore")
			gemButton:SetProperty("Visible", "False")
		end

		--	设置未装备文字
		local strNoEquipText = "#cFF0000" .. strNoEquipToolTips

		--	还木有条件装备
		if nImageListIndex > 13 and nEquipLimit[nImageListIndex][isFlag] > nPlayerlevel then
			--	背景图片
			itemButton:SetProperty("BackImage", strEquipImage[nImageListIndex])
			strNoEquipToolTips = ScriptGlobal_Format(strEquipLimit[nImageListIndex], nEquipLimit[nImageListIndex][isFlag])
--			strNoEquipToolTips = strNoEquipToolTips .. image_right_1[nImageListIndex].name
			strNoEquipText = strNoEquipToolTips
			bShowStar = 0
		end

		itemButton:SetToolTip(strNoEquipToolTips)
		ItemBar:Setm_newTextHide(1)
		ItemBar:Setm_newText(1, strNoEquipText)
		ItemBar:Setm_newTextShow(1)

	end

	if bShowStar > 0 then
		--	显示星星、推荐
		local nEquipGemScore = g_FightScore_GemRealScore_Map[nImageListIndex][5]

		--	显示第一个
		if nEquipGemScore < 100 then
			ItemBar:Setm_newImageShow(11)
		else
			ItemBar:Setm_newImageHide(11)
		end

		--	显示第二个
		if nEquipGemScore <= 80 then
			ItemBar:Setm_newImageShow(12)
		else
			ItemBar:Setm_newImageHide(12)
		end

		--	显示第三个
		if nEquipGemScore <= 60 then
			ItemBar:Setm_newImageShow(13)
			ItemBar:Setm_newImageShow(16)
		else
			ItemBar:Setm_newImageHide(13)
			ItemBar:Setm_newImageHide(16)
		end

		--	显示第四个
		if nEquipGemScore <= 40 then
			ItemBar:Setm_newImageShow(14)
			ItemBar:Setm_newImageShow(16)
		else
			ItemBar:Setm_newImageHide(14)
		end

		--	显示第五个
		if nEquipGemScore <= 20 then
			ItemBar:Setm_newImageShow(15)
			ItemBar:Setm_newImageShow(16)
		else
			ItemBar:Setm_newImageHide(15)
		end
	end

	ItemBar:SetAchvGetedShow()
	ItemBar:SetAchievementBarProgressShow()

	g_FightScoreRightList:Flash();
	table.insert(g_myRightButton, ItemBar)

	--	最下面的描述文字
	local MissionIndex = 1189
	local bHaveDone = DataPool:Lua_IsMissionHaveDone(MissionIndex)
	if bHaveDone > 0 then
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_42}")
		FightScoreFrame_Lace2_WYFY_Button:Hide()
	else
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_41}".."#{PFZY_140613_42}")
		FightScoreFrame_Lace2_WYFY_Button:Show()
	end
end

--	参数说明：最前面的ActionButton的底图，是否需要新建ActionItem,物品ID，显示的文字，分值
--	当bActionItem为0时，itemID是ActionItemID
--	当bActionItem为1时，itemID为新建的ActionItem所需的物品ID
function FightScore_CreateRightElementWithText(strBackImage, bActionItem, itemID, strText, score, strToolTips)
	local ItemBar = g_FightScoreRightList:AddItemElement( "FightScoreDetail", "LEFT", "FightScore","" ,"")

	if ItemBar == nil then
		return
	end

	ItemBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection")

	--先隐藏掉图片
	ItemBar:SetAchvGetedHide()
	ItemBar:SetAchievementBarIconDisImageHide()
	ItemBar:SetAchievementBarPointDisImageHide()
	ItemBar:SetAchievementBarPointImageHide()
	ItemBar:SetAchvGetHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarDateHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarProgressNameHide()
	for i = 2, 5 do
		nChildSlot = ItemBar:GetLuaActionButton(i,"FightScore")
		if nChildSlot ~= nil then
			nChildSlot:Hide()
		end
	end

	for j=1,16 do 
		if j < 2 or j > 6 then
			ItemBar:Setm_newImageHide(j)
		end
	end

	local ItemButton  = ItemBar:GetLuaActionButton(1,"FightScore")
	if ItemButton == nil then
		return
	end
	ItemButton:SetProperty("BackImage", strBackImage)
	local nActionID = -1
	--	设置ActionButton
	if bActionItem > 0 then
		local nListIndex = table.getn(g_myRightButton)
		oActionItem = LifeAbility:CreateVirtualActionItem(itemID, nListIndex)
		nActionID = oActionItem:GetID()
	else
		nActionID = itemID
	end
	ItemButton:SetActionItem(nActionID)
	if strToolTips ~= "" then
		ItemButton:SetToolTip(strToolTips)
	end
	--	设置文字
	local strNoEquipText = strText
	ItemBar:Setm_newTextHide(1)
	ItemBar:Setm_newText(1, strNoEquipText)
	ItemBar:Setm_newTextShow(1)
	--	设置显示星星和推荐图片
		--	显示第一个
	if score < 100 then
		ItemBar:Setm_newImageShow(11)
	end

	--	显示第二个
	if score <= 80 then
		ItemBar:Setm_newImageShow(12)
	end

	--	显示第三个
	if score <= 60 then
		ItemBar:Setm_newImageShow(13)
		ItemBar:Setm_newImageShow(16)
	end

	--	显示第四个
	if score <= 40 then
		ItemBar:Setm_newImageShow(14)
		ItemBar:Setm_newImageShow(16)
	end

	--	显示第五个
	if score <= 20 then
		ItemBar:Setm_newImageShow(15)
		ItemBar:Setm_newImageShow(16)
	end

	ItemBar:SetAchvGetedShow()
	ItemBar:SetAchievementBarProgressShow()

	g_FightScoreRightList:Flash();

	table.insert(g_myRightButton, ItemBar)
end

function FightScore_DiaoWenRightPanleUpDate()
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_63}")
	for i = 1, g_FightScore_EquipMax do
		if Player:GetData("Is2606S") == 1 then
			if i == 16 and g_FightScore_2606SValid[12] == 0 then -- 龙纹
				continue
			elseif i == 18 and g_FightScore_2606SValid[16] == 0 then -- 豪侠印
				continue
			end
		end
		local strBackImage = image_right_1[i].back
		local oEquip = EnumAction(image_right_1[i].index, "equip")
		local nEquipId = oEquip:GetID()
		local strText = ""
		local strTips = ""
		local nScore = g_FightScore_DiaoWenRealScore_Map[i]
		if nEquipId > 0 then
			if g_FightScore_DiaoWenRealScore_Map[i] < 0 then
				strText = "#{PFZY_140613_65}"
			else
				local nDiaoWenID = LifeAbility:GetWearedDiaowenId(image_right_1[i].index)
				if nDiaoWenID > 0 then
					--	查到分值后直接求得分数百分比并取得100以内的区间值
					local nLevel = LifeAbility:GetWearedDiaoWenGrade(nDiaoWenID)
					local strName = LifeAbility:GetWearedDiaoWenName(nDiaoWenID)
					if nLevel < g_FightScore_DiaoWenScore_Std_List[g_ScoreBaseParam].stdLevel then
						strText = ScriptGlobal_Format("#{PFZY_140613_66}", strName)
					else
						strText = ScriptGlobal_Format("#{PFZY_140613_67}", strName)
					end

					local nDiaoWenIDEx = LifeAbility:GetWearedDiaowenIdEx(image_right_1[i].index)
					if nDiaoWenIDEx > 0 then
						strDesc = LifeAbility:GetWearedDiaoWenDesc(nDiaoWenID)
						strDescEx = LifeAbility:GetWearedDiaoWenDesc(nDiaoWenIDEx)
						local nLevelEx = LifeAbility:GetWearedDiaoWenGrade(nDiaoWenIDEx)
						if nScore < 100 then
							strText = ScriptGlobal_Format("#{PFZY_140613_203}", strDesc, strDescEx, nLevel, nLevelEx)
						else
							strText = ScriptGlobal_Format("#{PFZY_140613_204}", strDesc, strDescEx, nLevel, nLevelEx)
						end
					end
				else
					strText = "#{PFZY_140613_65}"
				end
			end
		else
			nEquipId = -1
			strText = ScriptGlobal_Format("#{PFZY_140613_54}", image_right_1[i].name)
			strTips = ScriptGlobal_Format("#{PFZY_140613_39}", image_right_1[i].name)

			if i == 14 and g_FightScore_PlayLevel_STL <30 then
				strBackImage = "set:Fabao image:Fabao_2"
				if CachedTarget:GetMySelfEquipMasterFlag() ~= 0 then --有百兵精通
					strText = ScriptGlobal_Format("#{PFZY_140613_40}",20)
				else
					strText = ScriptGlobal_Format("#{PFZY_140613_40}",30)
				end
			elseif i == 15 and g_FightScore_PlayLevel_STL <65 then
				strBackImage = "set:Fabao image:Fabao_5"
				if CachedTarget:GetMySelfEquipMasterFlag() ~= 0 then --有百兵精通
					strText = ScriptGlobal_Format("#{PFZY_140613_55}",55)
				else
					strText = ScriptGlobal_Format("#{PFZY_140613_55}",65)
				end
			elseif i == 16 and g_FightScore_PlayLevel_STL <80 then
				strBackImage = "set:CircularTaskTool33 image:CircularTaskTool33_6"
				if CachedTarget:GetMySelfEquipMasterFlag() ~= 0 then --有百兵精通
					strText = ScriptGlobal_Format("#{PFZY_140613_56}",70)
				else
					strText = ScriptGlobal_Format("#{PFZY_140613_56}",80)
				end
			elseif i == 17 and Player:GetLevel() <80 then
				strBackImage = "set:EquipLingPai image:EquipLingPai_5"
				strText = ScriptGlobal_Format("#{PFZY_140613_57}",80)
			end

		end

		if nScore < 0 then
			nScore = 100
		end
		FightScore_CreateRightElementWithText(strBackImage, 0, nEquipId, strText, nScore, strTips)
	end

	--上方描述
	local strTemp = ScriptGlobal_Format("#{PFZY_140613_64}", g_FightScore_DiaoWenScore_Std_List[g_ScoreBaseParam].stdLevel, g_FightScore_DiaoWenScore_Std_List[g_ScoreBaseParam].stdLevel, g_FightScore_DiaoWenScore_Std_List[g_ScoreBaseParam].stdLevel - 1)
	FightScoreFrame_List2_Text:SetText( strTemp )

	--	最下面的描述文字
	local MissionIndex = 1616
	local bHaveDone = DataPool:Lua_IsMissionHaveDone(MissionIndex)
	if bHaveDone > 0 then
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_69}")
		FightScoreFrame_Lace2_WYFY_Button:Hide()
	else
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_68}".."#{PFZY_140613_69}")
		FightScoreFrame_Lace2_WYFY_Button:Show()
	end

end

function FightScore_StrengthRightPanleUpDate()
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_131}")
    local nEquipLimit = {[14]={[0]=30,[1]=20}, [15]={[0]=65,[1]=55},[16]={[0]=80,[1]=70}, [17]={[0]=80,[1]=70}, [18]={[0]=85,[1]=85}}	--	各种装备限制等级
	local strEquipLimit = {[14]="#{PFZY_140613_40}", [15]="#{PFZY_140613_55}",[16]="#{PFZY_140613_56}", [17]="#{PFZY_140613_57}", [18]="#{PFZY_140613_57}", }
	local strEquipImage = {	[14]="set:Fabao image:Fabao_2",[15]="set:Fabao image:Fabao_5",
				[16]="set:CircularTaskTool33 image:CircularTaskTool33_6",[17]="set:EquipLingPai image:EquipLingPai_5",[18]="set:HaoXiaYin2 image:HaoXiaYin2_8"}
	local isFlag = CachedTarget:GetMySelfEquipMasterFlag()
	local nPlayerlevel = Player:GetLevel()
	for i = 1, g_FightScore_EquipMax do
		if i == 15 then
			--	剔除武魂
			continue
		end
		if Player:GetData("Is2606S") == 1 then
			if i == 16 and g_FightScore_2606SValid[12] == 0 then -- 龙纹
				continue
			elseif i == 18 and g_FightScore_2606SValid[16] == 0 then -- 豪侠印
				continue
			end
		end

		local strBackImage = image_right_1[i].back
		local oEquip = EnumAction(image_right_1[i].index, "equip")
		local nEquipID = -1
		local strTemp = ""
		local nScore = g_FightScore_StrengthScore_RealMap[i]
		local strToolTips = ""

		if oEquip ~= nil then
			local nlevel,_,_ = oEquip:GetStrengthenLevel()
			nEquipID = oEquip:GetID()
			if nEquipID > 0 then
				if nlevel >= g_FightScore_StrengthScore_StdList[g_ScoreBaseParam] then
					strTemp = ScriptGlobal_Format("#{PFZY_140613_133}", nlevel)
				else
					strTemp = ScriptGlobal_Format("#{PFZY_140613_132}", nlevel)
				end
			else
				strToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", image_right_1[i].name)
				strTemp = "#cFF0000" .. strToolTips
				if i > 13 and nEquipLimit[i] ~= nil then
					if nPlayerlevel < nEquipLimit[i][isFlag] then
						strTemp = ScriptGlobal_Format(strEquipLimit[i], nEquipLimit[i][isFlag])
						strBackImage = strEquipImage[i]
						nScore = 100	--	不显示星星
						strToolTips = ""
					end
				end
			end
		else
			strToolTips = ScriptGlobal_Format("#{PFZY_140613_39}", image_right_1[i].name)
			strTemp = "#cFF0000" .. strToolTips
			if nEquipLimit[i] ~= nil then
				if nPlayerLevel < nEquipLimit[i][isFlag] then
					strTemp = ScriptGlobal_Format(strEquipLimit[i], nEquipLimit[i][isFlag])
					strBackImage = strEquipImage[i]
					nScore = 100
					--strToolTips = ""
				end
			end
		end
		FightScore_CreateRightElementWithText(strBackImage, 0, nEquipID, strTemp, nScore, strToolTips)
	end

	local strTuiJianText = ScriptGlobal_Format("#{PFZY_140613_94}", g_FightScore_StrengthScore_StdList[g_ScoreBaseParam])
	FightScoreFrame_List2_Text:SetText(strTuiJianText)
	FightScoreFrame_Lace2_WYFY_Button:Hide() --隐藏武林风云按钮
	FightScoreFrame_Lace2_Shop_Button:Show()
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("#{PFZY_140613_44}") --商城按钮
	FightScoreFrame_Lace2_HD_Button:Show()
	FightScoreFrame_Lace2_HD_Button:SetToolTip("#{PFZY_140613_50}") --活动按钮
	FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_137}")
end

--	资质界面
function FightScore_ZiZhiRightPanleUpDate()
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_138}")
	local nEquipLimit = {[14]={[0]=30,[1]=20}, [15]={[0]=65,[1]=55},[16]={[0]=80,[1]=70}, [17]={[0]=80,[1]=70}, [18]={[0]=85,[1]=85}}	--	各种装备限制等级
	local strEquipLimit = {[14]="#{PFZY_140613_40}", [15]="#{PFZY_140613_55}",[16]="#{PFZY_140613_56}", [17]="#{PFZY_140613_57}", [18]="#{PFZY_140613_57}", }
	local strEquipImage = {	[14]="set:Fabao image:Fabao_2",[15]="set:Fabao image:Fabao_5",
				[16]="set:CircularTaskTool33 image:CircularTaskTool33_6",[17]="set:EquipLingPai image:EquipLingPai_5",[18]="set:HaoXiaYin2 image:HaoXiaYin2_8"}
	local isFlag = CachedTarget:GetMySelfEquipMasterFlag()
	local nPlayerlevel = Player:GetLevel()
	--	武魂剔除(装备列表中索引值为15)
	for i = 1, g_FightScore_EquipMax do
		if i == 15 then
			continue
		end
		if Player:GetData("Is2606S") == 1 then
			if i == 16 and g_FightScore_2606SValid[12] == 0 then -- 龙纹
				continue
			elseif i == 18 and g_FightScore_2606SValid[16] == 0 then -- 豪侠印
				continue
			end
		end

		local strBackImage = image_right_1[i].back
		local oEquip = EnumAction(image_right_1[i].index, "equip")
		local nEquipID = -1
		local strTemp = ""
		local nScore = 0;
		local strTips = ""
		if g_FightScore_ZiZhiScore_RealMap[i] ~= nil then
			nScore = g_FightScore_ZiZhiScore_RealMap[i].score
		end

		if oEquip ~= nil then
			local nGrade = g_FightScore_ZiZhiScore_RealMap[i].grade
			local nRate = g_FightScore_ZiZhiScore_RealMap[i].rate
			nEquipID = oEquip:GetID()
			if nEquipID > 0 then
				local nTempIndex = 1
				local strGrade = ""
				local strRate = ""
				if nRate < 0 then
					strGrade = ""	--	无资质
				end

				if nRate == 0 then
					strGrade = ""	--	未鉴定
				end
				if nRate > 0 then
					for _, vElement in g_FightScore_ZiZhiGrade_Value_List do
						if vElement.rate > nGrade then
							break
						end
						strGrade = g_FightScore_ZiZhiGrade_Value_List[nTempIndex].str
						nTempIndex = nTempIndex + 1
					end
				end

				if nRate > 0 and strGrade ~= ""then
					--	颜色这部分字典中给的有问题，暂时不是用ScriptGlobal_Format进行拼接，原因是文档中的"+x%"的%有问题，后面再改吧。
					--	--	颜色
					if nRate >= g_FightScore_ZiZhiScore_StdList[g_ScoreBaseParam].rate then
						strRate = "#c00FF00" .. nRate
						strGrade = "#c00FF00" .. strGrade
					else
						strRate = "#cFF0000" .. nRate
						strGrade = "#cFF0000" .. strGrade
					end
					strTemp = ScriptGlobal_Format("#{PFZY_140613_142}", strGrade, strRate)
					--strTemp = "#cfff263当前最高资质：#cFF0000" .. strGrade .. strRate
				else
					if nRate < 0 then
						strTemp = "#{PFZY_140613_140}"	--	无资质
						nScore = 100
					end

					if nRate == 0 then
						strTemp = "#{PFZY_140613_141}"	--	未鉴定
					end
				end
			else

				strTips = ScriptGlobal_Format("#{PFZY_140613_39}", image_right_1[i].name)
				strTemp = "#cFF0000" .. strTips
				if i > 13 and nEquipLimit[i] ~= nil then
					if nPlayerlevel < nEquipLimit[i][isFlag] then
						strTemp = ScriptGlobal_Format(strEquipLimit[i], nEquipLimit[i][isFlag])
						strBackImage = strEquipImage[i]
						nScore = 100
						strTips = ""
					end
				end
			end
		else
			strTips = ScriptGlobal_Format("#{PFZY_140613_39}", image_right_1[i].name)
			strTemp = "#cFF0000" .. strTips
			if i > 13 and nEquipLimit[i] ~= nil then
				if nPlayerlevel < nEquipLimit[i][isFlag] then
					strTemp = ScriptGlobal_Format(strEquipLimit[i], nEquipLimit[i][isFlag])
					strBackImage = strEquipImage[i]
					nScore = 100
					strTips = ""
				end
			end
		end
		FightScore_CreateRightElementWithText(strBackImage, 0, nEquipID, strTemp, nScore, strTips)

	end
	--	资质鉴定至str + x%
	local strDesc = g_FightScore_ZiZhiGrade_Value_List[g_FightScore_ZiZhiScore_StdList[g_ScoreBaseParam].nGrade]
	for _, vTemp in g_FightScore_ZiZhiGrade_Value_List do
		if vTemp.rate == g_FightScore_ZiZhiScore_StdList[g_ScoreBaseParam].nGrade then
			strDesc = vTemp.str
		end
	end
	local strTuiJianText = ScriptGlobal_Format("#{PFZY_140613_139}", strDesc, g_FightScore_ZiZhiScore_StdList[g_ScoreBaseParam].rate)
	FightScoreFrame_List2_Text:SetText(strTuiJianText)
	FightScoreFrame_Lace2_WYFY_Button:Hide() --隐藏武林风云按钮
	FightScoreFrame_Lace2_Shop_Button:Show()
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("#{PFZY_140613_44}") --商城按钮
	FightScoreFrame_Lace2_HD_Button:Show()
	FightScoreFrame_Lace2_HD_Button:SetToolTip("#{PFZY_140613_50}") --活动按钮
	FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_194}")
end

--	20310176		--	玉龙髓				星级
--	20310181		--	缀龙石·元			血上限
--	20310182		--	缀龙石·暴			减抗
--	20310183		--	缀龙石·伤			属性攻
function FightScore_LongWenRightPanleUpDate()
	--	页签
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_77}")
	local nLongWenList =
	{
		[1] = {icon="set:CircularTaskTool32 image:CircularTaskTool32_12", tips="#{PFZY_140613_87}"},
		[2] = {icon="set:CircularTaskTool32 image:CircularTaskTool32_10", tips="#{PFZY_140613_88}"},
		[3] = {icon="set:CircularTaskTool32 image:CircularTaskTool32_11", tips="#{PFZY_140613_89}"},
	}
	local strBackImage = "set:MiniMap image:LongWen"
	local oLongWen = EnumAction(19,"equip")
	local nLongWenID = oLongWen:GetID()
	if nLongWenID > 0 then
		--	龙纹等级
		local nLevel = LifeAbility:GetWearedLongWen_Level(19)
		local strTemp = ""
		if g_FightScore_LongWenScore_RealMap[1] < 100 then
			strTemp = ScriptGlobal_Format("#{PFZY_140613_82}", nLevel, g_FightScore_LongWenScore_Std_List[g_ScoreBaseParam].stdLevel)
		else
			strTemp = ScriptGlobal_Format("#{PFZY_140613_83}", nLevel)
		end
		FightScore_CreateRightElementWithText(strBackImage, 0, oLongWen:GetID(), strTemp, g_FightScore_LongWenScore_RealMap[1], "")

		--	龙纹星级
		local nQua = LifeAbility:GetWearedLongWen_Star(19);
		if g_FightScore_LongWenScore_RealMap[2] < 100 then
			strTemp = ScriptGlobal_Format("#{PFZY_140613_85}", nQua, g_FightScore_LongWenScore_Std_List[g_ScoreBaseParam].stdQua)
		else
			strTemp = ScriptGlobal_Format("#{PFZY_140613_86}", nQua)
		end
		FightScore_CreateRightElementWithText("set:CircularTaskTool33 image:CircularTaskTool33_5", 0, -1, strTemp, g_FightScore_LongWenScore_RealMap[2], "#{PFZY_140613_84}")

		--	扩展属性
		for i = 0, 2 do
			local nExAttLevel = LifeAbility:GetWearedLongWen_AttLevel(19, i)
			if nExAttLevel > 0 then
				if g_FightScore_LongWenScore_RealMap[i+3] < 100 then
					strTemp = ScriptGlobal_Format("#{PFZY_140613_91}", nExAttLevel, g_FightScore_LongWenScore_Std_List[g_ScoreBaseParam].stdExtraAttLevel)
				else
					strTemp = ScriptGlobal_Format("#{PFZY_140613_92}", nExAttLevel)
				end
				FightScore_CreateRightElementWithText(nLongWenList[i+1].icon, 0, -1, strTemp, g_FightScore_LongWenScore_RealMap[i+3], nLongWenList[i+1].tips)
			else
				FightScore_CreateRightElementWithText(nLongWenList[i+1].icon, 0, -1, "#{PFZY_140613_90}", 0, nLongWenList[i+1].tips)
			end
		end
	else
		--	木有龙纹
		FightScore_CreateRightElementWithText(strBackImage, 0, -1, "#{PFZY_140613_78}", 100, "")
	end

	FightScoreFrame_List2_Text:SetText( "" )			--清空描述

	--	最下面的描述文字
	local MissionIndex = 1795
	local bHaveDone = DataPool:Lua_IsMissionHaveDone(MissionIndex)
	if bHaveDone > 0 then
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_80}")
		FightScoreFrame_Lace2_WYFY_Button:Hide()
	else
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_79}".."#{PFZY_140613_80}")
		FightScoreFrame_Lace2_WYFY_Button:Show()
	end

end

function FightScore_DarkRightPanleUpDate()
	--	页签
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_107}")

	local strBackImage = "set:UIIcons image:Equip_Anqi"
	local nDarkID = EnumAction(17,"equip"):GetID()
	if nDarkID > 0 then
		--	暗器种类，也就是需求等级
		nNeedLevel = LifeAbility:GetWearedEquip_NeedLevel(17)
		local strTemp = ""
		local strDarkName = PlayerPackage:GetEquipItemName( LifeAbility:GetWearedEquip_ItemTableIndex(17) )
		if g_FightScore_DarkScore_RealMap[1].nIndex < g_FightScore_DarkScore_RealMap[1].nIndexStd then
			strTemp = ScriptGlobal_Format("#{PFZY_140613_108}", strDarkName, g_FightScore_DarkScore_Level_List[g_FightScore_DarkScore_RealMap[1].nIndexStd].name)
		else
			strTemp = ScriptGlobal_Format("#{PFZY_140613_109}", strDarkName)
		end
		FightScore_CreateRightElementWithText(strBackImage, 0, nDarkID, strTemp, g_FightScore_DarkScore_RealMap[1].score, "")

		--	暗器品阶
		if g_FightScore_DarkScore_RealMap[2].nIndex < g_FightScore_DarkScore_RealMap[2].nIndexStd then
			strTemp = ScriptGlobal_Format("#{PFZY_140613_110}", g_FightScore_DarkScore_Quality_List[g_FightScore_DarkScore_RealMap[2].nIndex].str, g_FightScore_DarkScore_Quality_List[g_FightScore_DarkScore_RealMap[2].nIndexStd].str)
		else
			strTemp = ScriptGlobal_Format("#{PFZY_140613_111}", g_FightScore_DarkScore_Quality_List[g_FightScore_DarkScore_RealMap[2].nIndex].str)
		end
		FightScore_CreateRightElementWithText("set:FabaoDaoju image:FabaoDaoju_4", 0, -1, strTemp, g_FightScore_DarkScore_RealMap[2].score, "")

		if nNeedLevel == g_FightScore_DarkScore_Level_List[4].needlevel then
			--  暗器星级
			local iconlqty =  tostring(DataPool : Lua_GetItemIconNameByIndex(20800046))
			if g_FightScore_DarkScore_RealMap[3].nIndex < g_FightScore_DarkScore_RealMap[3].nIndexStd then
				strTemp = ScriptGlobal_Format("#{PFZY_140613_85}", g_FightScore_DarkScore_RealMap[3].nIndex, g_FightScore_DarkScore_RealMap[3].nIndexStd)
			else
				strTemp = ScriptGlobal_Format("#{PFZY_140613_86}", g_FightScore_DarkScore_RealMap[3].nIndex)
			end
			
			FightScore_CreateRightElementWithText(iconlqty, 0, -1, strTemp, g_FightScore_DarkScore_RealMap[3].score, "#{PFZY_160317_02}")
			
			-- 暗器炼毒血上限
			local iconyy = tostring(DataPool : Lua_GetItemIconNameByIndex(20800040))
			local humanLYAddHP = LifeAbility:GetWearedDarkLY_CuiduHP(17)
			local nRealLYHPParam = math.floor(humanLYAddHP/10688*10000)
			local nStdLYHPParam = math.floor(g_FightScore_DarkScore_HP_List[g_FightScore_DarkScore_RealMap[4].nIndexStd].maxhp/10688*10000)
			if nRealLYHPParam < nStdLYHPParam then
				strTemp = ScriptGlobal_Format("#{PFZY_160317_04}", humanLYAddHP, g_FightScore_DarkScore_HP_List[g_FightScore_DarkScore_RealMap[4].nIndexStd].maxhp)
			else
				strTemp = ScriptGlobal_Format("#{PFZY_160317_05}", humanLYAddHP)
			end
			
			FightScore_CreateRightElementWithText(iconyy, 0, -1, strTemp, g_FightScore_DarkScore_RealMap[4].score, "#{PFZY_160317_03}")
			
			-- 暗器炼毒属性攻
			local iconsxg = tostring(DataPool : Lua_GetItemIconNameByIndex(20800042))
			local humanLYAddPro = LifeAbility:GetWearedDarkLY_CuiduPro(17)
			local nRealLYAddProParam = math.floor(humanLYAddPro/176*10000)
			local nStdLYAddProParam = math.floor(g_FightScore_DarkScore_Pro_List[g_FightScore_DarkScore_RealMap[5].nIndexStd].maxpro/176*10000)
			if nRealLYAddProParam < nStdLYAddProParam then
				strTemp = ScriptGlobal_Format("#{PFZY_160317_04}", humanLYAddPro, g_FightScore_DarkScore_Pro_List[g_FightScore_DarkScore_RealMap[5].nIndexStd].maxpro)
			else
				strTemp = ScriptGlobal_Format("#{PFZY_160317_05}", humanLYAddPro)
			end
			FightScore_CreateRightElementWithText(iconsxg, 0, -1, strTemp, g_FightScore_DarkScore_RealMap[5].score, "#{PFZY_160317_06}")
			
			-- 暗器炼毒命中
			local iconmz = tostring(DataPool : Lua_GetItemIconNameByIndex(20800044))
			local humanLYAddHit = LifeAbility:GetWearedDarkLY_CuiduHit(17)
			local nRealLYAddHitParam = math.floor(humanLYAddHit/2175*10000)
			local nStdLYAddHitParam = math.floor(g_FightScore_DarkScore_Hit_List[g_FightScore_DarkScore_RealMap[6].nIndexStd].maxhit/2175*10000)
			if nRealLYAddHitParam < nStdLYAddHitParam then
				strTemp = ScriptGlobal_Format("#{PFZY_160317_04}", humanLYAddHit, g_FightScore_DarkScore_Hit_List[g_FightScore_DarkScore_RealMap[6].nIndexStd].maxhit)
			else
				strTemp = ScriptGlobal_Format("#{PFZY_160317_05}", humanLYAddHit)
			end
			FightScore_CreateRightElementWithText(iconmz, 0, -1, strTemp, g_FightScore_DarkScore_RealMap[6].score, "#{PFZY_160317_07}")
		end
	else
		--	木有暗器
		FightScore_CreateRightElementWithText(strBackImage, 0, -1, "#{PFZY_140613_93}", 100, "")
	end

	if nNeedLevel == g_FightScore_DarkScore_Level_List[3].needlevel then
		FightScoreFrame_List2_Text:SetText( "#{PFZY_160317_01}" )
	else
		FightScoreFrame_List2_Text:SetText( "" )			--清空描述
	end
	

	--	最下面的描述文字
	local MissionIndex = 1633
	local bHaveDone = DataPool:Lua_IsMissionHaveDone(MissionIndex)
	local MissionIndex2 = 1836
	local bHaveDone2 = DataPool:Lua_IsMissionHaveDone(MissionIndex2)
	if bHaveDone > 0 and bHaveDone2 > 0 then
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_106}")
		if Player:GetData("Is2606S") == 1 then
			FightScoreFrame_Lace2_Text:SetText("#{QXF_260623_29}")
		end
		FightScoreFrame_Lace2_WYFY_Button:Hide()
	else
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_105}".."#{PFZY_140613_106}")
		if Player:GetData("Is2606S") == 1 then 
			FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_105}".."#{QXF_260623_29}")
		end
		FightScoreFrame_Lace2_WYFY_Button:Show()
	end

end

function FightScore_InfantRightPanleUpDate()
	--	页签
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_151}")

	--	子女技能图标
	local nInfantSkillList =
	{
		[1] = {icon="set:FightSkillInfant image:FightSkillInfant_3", tips="火抗"},
		[2] = {icon="set:FightSkillInfant image:FightSkillInfant_1", tips="冰抗"},
		[3] = {icon="set:FightSkillInfant image:FightSkillInfant_7", tips="毒抗"},
		[4] = {icon="set:FightSkillInfant image:FightSkillInfant_5", tips="玄抗"},
		[5] = {icon="set:FightSkillInfant image:FightSkillInfant_4", tips="减火抗"},
		[6] = {icon="set:FightSkillInfant image:FightSkillInfant_2", tips="减冰抗"},
		[7] = {icon="set:FightSkillInfant image:FightSkillInfant_8", tips="减毒抗"},
		[8] = {icon="set:FightSkillInfant image:FightSkillInfant_6", tips="减玄抗"},
	}
	--	子女卡牌类型
	local nInfantCardType =
	{
		[1] = "神兵",
		[2] = "锦装",
		[3] = "轻功",
		[4] = "良驹",
		[5] = "武决",
		[6] = "名饰",
	}
	--	子女卡牌品质
	local nInfantCardQual =
	{
		[0] = "绿色",
		[1] = "蓝色",
		[2] = "紫色",
		[3] = "橙色",
	}
	local strBackImage = "set:IMShow image:IMShow_13"
	local strBackImageNull = "set:TaskTools17 image:TaskTools17_3"
	local nChildNum = Infant:GetInfantCount()
	if nChildNum~= nil and nChildNum > 0 then
		--有子女
		--子女等级
		local strTemp = ""
		local strTemp2 = ""
		if g_FightScore_InfantScore_LevelScore < 100 then
			strTemp = ScriptGlobal_Format("#{PFZY_140613_155}", g_FightScore_InfantLevel, g_FightScore_InfantScore_StdList[g_ScoreBaseParam].level)
		else
			strTemp = ScriptGlobal_Format("#{PFZY_140613_156}", g_FightScore_InfantLevel)
		end
		FightScore_CreateRightElementWithText("set:CircularTaskTool57 image:CircularTaskTool57_6", 0, -1, strTemp, g_FightScore_InfantScore_LevelScore, "")

		--子女素养
		if g_FightScore_InfantScore_AttrScore < 100 then
			strTemp = ScriptGlobal_Format("#{PFZY_140613_157}", g_FightScore_InfantAttrValue, g_FightScore_InfantScore_StdList[g_ScoreBaseParam].attr)
		else
			strTemp = ScriptGlobal_Format("#{PFZY_140613_158}", g_FightScore_InfantAttrValue)
		end
		FightScore_CreateRightElementWithText("set:CircularTaskTool57 image:CircularTaskTool57_5", 0, -1, strTemp, g_FightScore_InfantScore_AttrScore, "")

		--子女技能
		for i = 0, 3 do
			if g_FightScore_InfantSkill[i+1].id > 0 then
				if g_FightScore_InfantSkill[i+1].score < 100 then
					strTemp = ScriptGlobal_Format("#{PFZY_140613_161}", g_FightScore_InfantSkill[i+1].level, g_FightScore_InfantScore_StdList[g_ScoreBaseParam].skilllevel)
				else
					strTemp = ScriptGlobal_Format("#{PFZY_140613_162}", g_FightScore_InfantSkill[i+1].level)
				end
				FightScore_CreateRightElementWithText(nInfantSkillList[ g_FightScore_InfantSkill[i+1].id ].icon, 0, -1, strTemp, g_FightScore_InfantSkill[i+1].score, nInfantSkillList[ g_FightScore_InfantSkill[i+1].id ].tips)
			else
				FightScore_CreateRightElementWithText(strBackImageNull, 0, -1, "#{PFZY_140613_160}", 100, "#{PFZY_140613_159}")
			end
		end

		--子女卡牌
		for i = 0, 5 do
			if g_FightScore_InfantCard[i+1].cardId > 0 then
				local CardQualReal = g_FightScore_InfantCard[i+1].cardQual
				local CardYanDuLevelReal = g_FightScore_InfantCard[i+1].yanduLevel
				local CardQualStd = g_FightScore_InfantScore_StdList[g_ScoreBaseParam].cardgrade
				local CardYanDuLevelStd = g_FightScore_InfantScore_StdList[g_ScoreBaseParam].cardlevel
				if CardQualReal < CardQualStd then
					strTemp = ScriptGlobal_Format("#{PFZY_140613_166}", nInfantCardQual[CardQualReal], nInfantCardQual[CardQualStd])
				else
					strTemp = ScriptGlobal_Format("#{PFZY_140613_168}", nInfantCardQual[CardQualReal])
				end
				if CardYanDuLevelReal < CardYanDuLevelStd then
					strTemp2 = ScriptGlobal_Format("#{PFZY_140613_167}", CardYanDuLevelReal, CardYanDuLevelStd)
				else
					strTemp2 = ScriptGlobal_Format("#{PFZY_140613_169}", CardYanDuLevelReal)
				end
				FightScore_CreateRightElementWithText(strBackImageNull, 0, EnumAction(i, "infantcard"):GetID(), strTemp.."#r"..strTemp2, g_FightScore_InfantCard[i+1].score, "")
			else
				strTemp = ScriptGlobal_Format("#{PFZY_140613_164}", nInfantCardType[i+1])
				strTemp2 = ScriptGlobal_Format("#{PFZY_140613_163}", nInfantCardType[i+1])
				FightScore_CreateRightElementWithText(strBackImageNull, 0, -1, strTemp, 100, strTemp2)
			end
		end
	else
		--没有子女
		FightScore_CreateRightElementWithText(strBackImage, 0, -1, "#{PFZY_140613_152}", 100, "")
	end

	FightScoreFrame_List2_Text:SetText( "" )			--清空描述

	--	最下面的描述文字
	local MissionIndex = 1814
	local bHaveDone = DataPool:Lua_IsMissionHaveDone(MissionIndex)
	if bHaveDone > 0 then
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_154}")
		FightScoreFrame_Lace2_WYFY_Button:Hide()
	else
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_153}".."#{PFZY_140613_154}")
		FightScoreFrame_Lace2_WYFY_Button:Show()
	end

end


function FightScore_SMWDRightPanleUpDate()
	--	页签
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_181}")
	local CountReal = g_FightScore_SMWD_Count
	local CountReal2 = g_FightScore_SMWD_Count2
	local CountStd = g_FightScore_SMWDScore_StdList[g_ScoreBaseParam]

	if CountReal >= 0 then
		local numReal = g_FightScore_SMWDScore_CountList[CountReal].num
		local qualReal = g_FightScore_SMWDScore_CountList[CountReal].qual
		local numStd = g_FightScore_SMWDScore_CountList[CountStd].num
		local qualStd = g_FightScore_SMWDScore_CountList[CountStd].qual
		local strBackImage = "set:CircularTaskTool79 image:CircularTaskTool79_5"

		local strTemp = ScriptGlobal_Format("#{PFZY_140613_177}", numStd, qualStd )
		FightScoreFrame_List2_Text:SetText( strTemp )

		if ( g_FightScore_SMWDScore_Total < 100 ) then
			strTemp = ScriptGlobal_Format("#{PFZY_140613_178}", numReal, qualReal )
		else
			strTemp = ScriptGlobal_Format("#{PFZY_140613_202}", numReal, qualReal )
		end
		FightScore_CreateRightElementWithText(strBackImage, 0, -1, strTemp, g_FightScore_SMWDScore_Total, "" )
	end
	
	if CountReal2 >= 0 then
		local numReal = g_FightScore_SMWDScore_CountList[CountReal2].num
		local qualReal = g_FightScore_SMWDScore_CountList[CountReal2].qual
		local strBackImage = "set:CircularTaskTool79 image:CircularTaskTool79_6"
		if ( g_FightScore_SMWDScore_Total2 < 100 ) then
			strTemp = ScriptGlobal_Format("#{PFZY_140613_221}", numReal, qualReal )
		else
			strTemp = ScriptGlobal_Format("#{PFZY_140613_222}", numReal, qualReal )
		end
		FightScore_CreateRightElementWithText(strBackImage, 0, -1, strTemp, g_FightScore_SMWDScore_Total2, "" )
	end

	--	最下面的描述文字
	FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_179}")
	FightScoreFrame_Lace2_WYFY_Button:Hide()
end

--获取装备标准星级
-- nStyle 装备位置编号
-- MaxGemNum 全身宝石最高等级
function FightScore_GetEquipGem_STL(nStyle,MaxGemNum)
	local mark=""
	if nStyle == 0 then	--武器
		local PlayerLevel_STL = FightScore_GetPlayerLevelSTL()
		if PlayerLevel_STL < 86 then
			return 5
		elseif PlayerLevel_STL>=86 and PlayerLevel_STL< 92 then
			return g_Gem_Score_STL[MaxGemNum]["WuQi"]
		elseif PlayerLevel_STL>=92 and PlayerLevel_STL<96 then
			return 5
		elseif PlayerLevel_STL>=96 then
			return g_Gem_Score_STL[MaxGemNum]["WuQi"]
		end
	elseif nStyle==1 or nStyle==2 or nStyle==7 then --帽子、衣服、项链
		mark = "YMX"
	elseif nStyle==3 or nStyle==4 or nStyle==5 or nStyle==6 or nStyle==11 or nStyle==12  --非武器、帽子、衣服、项链
	or nStyle==13 or nStyle ==14 or nStyle==15 then
		mark = "FYMX"
	end

	if g_Gem_Score_STL[MaxGemNum][mark] ~= nil then
		return g_Gem_Score_STL[MaxGemNum][mark]
	end

	PushDebugMessage("FightScore_GetEquipGem_STL error")
	return -1
end

--获取装备属性条数标准参数
-- nLevelSTL 装备标准等级
-- MaxGemNum 全身宝石最高等级
function FightScore_GetEquipAttrNum_STL(nLevelSTL, MaxGemNum)
	local mark=""
	if nLevelSTL >=1 and nLevelSTL <= 10 then
		mark = "1,10"
	elseif nLevelSTL >= 11 and nLevelSTL <= 20 then
		mark = "11,20"
	elseif nLevelSTL >= 21 and nLevelSTL <= 30 then
		mark = "21,30"
	elseif nLevelSTL >= 31 and nLevelSTL <= 40 then
		mark = "31,40"
	elseif nLevelSTL >= 41 and nLevelSTL <= 50 then
		mark = "41,50"
	elseif nLevelSTL >= 51 then
		mark = "51+"
	end

	if g_Gem_Score_STL[MaxGemNum][mark] ~= nil then
		return g_Gem_Score_STL[MaxGemNum][mark]
	end

	PushDebugMessage("FightScore_GetEquipAttrNum_STL error")
	return -1
end

function  FightScore_GetPlayerLevelSTL()
	--玩家标准等级(自身等级+百兵精通等级)
	local PlayerLevel_STL = Player:GetLevel()

	if CachedTarget:GetMySelfEquipMasterFlag() ~= 0 then
		PlayerLevel_STL = PlayerLevel_STL + 10
	end
	local defineHumanMaxLevel = Player:GetDefineHumanMaxLevel()
	if PlayerLevel_STL > defineHumanMaxLevel then
		PlayerLevel_STL = defineHumanMaxLevel
	end

	return PlayerLevel_STL
end

--计算装备评分
local g_FightScore_EquipRate={}--装备分值
function FightScore_CalculateEquitScore()
	local EquipY = {0.001,0.001,0.002,0.005,0.01,0.03,0.12,0.5,1.0,1.75};--星级  没有星级当做1级处理
	local EquipZ = {0.1,0.1,0.25,0.4,0.55,0.7,0.85,1.0,1.0,1.0};--属性条数
	g_FightScore_EquipRate={}
	local PlayerLevel_STL = FightScore_GetPlayerLevelSTL()
	local FightScore_TotalReal=0
	local FightScore_TotalSTL=0
	local PlayerGemMaxNum = g_ScoreBaseParam
	local AttrNum_STL = FightScore_GetEquipAttrNum_STL(PlayerLevel_STL,PlayerGemMaxNum)
	for i=1, 13 do
		local nIndex = image_right_1[i].index
		if nIndex == 0 then -- 武器
			local EquipLevel_STL,P_STL = DataPool:GetEquipScoreSTL(nIndex)
			local EquipQual_STL = FightScore_GetEquipGem_STL(nIndex,g_ScoreBaseParam)
			local EquipAttrNum_STL = FightScore_GetEquipAttrNum_STL(EquipLevel_STL,g_ScoreBaseParam)
			local X_STL = EquipLevel_STL/100
			local Y_STL = EquipY[EquipQual_STL+1]
			local Z_STL = EquipZ[EquipAttrNum_STL+1]
			local EquipScore_STL = 0
			local EquipLevel_Real,EquipQual_Real,EquipAttrNum_Real,P_Real = DataPool:GetEquipScore(nIndex)
			if EquipLevel_Real < 0 then
				table.insert(g_FightScore_EquipRate,0)
				EquipScore_STL = 10+EquipLevel_STL+(100000*X_STL*Y_STL*Z_STL*P_STL)
				FightScore_TotalSTL = FightScore_TotalSTL+EquipScore_STL
				continue
			end
			EquipScore_STL = 10+EquipLevel_STL+(100000*X_STL*Y_STL*Z_STL*P_STL)
			FightScore_TotalSTL = FightScore_TotalSTL+EquipScore_STL
			local X_Real = EquipLevel_Real/100
			local Y_Real = EquipY[EquipQual_Real+1]
			local Z_Real = EquipZ[EquipAttrNum_Real+1]
			if EquipLevel_Real > EquipLevel_STL then
				EquipLevel_Real = EquipLevel_STL
			end
			if X_Real > X_STL then
				X_Real = X_STL
			end
			if Y_Real > Y_STL then
				Y_Real = Y_STL
			end
			if Z_Real > Z_STL then
				Z_Real = Z_STL
			end
			local EquipScore_Real = 10+EquipLevel_Real+(100000*X_Real*Y_Real*Z_Real*P_Real)
			FightScore_TotalReal = FightScore_TotalReal+EquipScore_Real
			local nRate = math.floor(EquipScore_Real/EquipScore_STL*100)
			table.insert(g_FightScore_EquipRate,nRate)
		else
			local EquipLevel_STL = DataPool:GetEquipScoreSTL(nIndex)
			local EquipQual_STL = FightScore_GetEquipGem_STL(nIndex,g_ScoreBaseParam)
			local EquipAttrNum_STL = FightScore_GetEquipAttrNum_STL(EquipLevel_STL,g_ScoreBaseParam)
			local X_STL = EquipLevel_STL/100
			local Y_STL = EquipY[EquipQual_STL+1]
			local Z_STL = EquipZ[EquipAttrNum_STL+1]
			local EquipScore_STL = 10+EquipLevel_STL+(50000*X_STL*Y_STL*Z_STL)
			FightScore_TotalSTL = FightScore_TotalSTL+EquipScore_STL

			local EquipLevel_Real,EquipQual_Real,EquipAttrNum_Real = DataPool:GetEquipScore(nIndex)
			if EquipLevel_Real < 0 then
				table.insert(g_FightScore_EquipRate,0)
				continue
			end
			local X_Real = EquipLevel_Real/100
			local Y_Real = EquipY[EquipQual_Real+1]
			local Z_Real = EquipZ[EquipAttrNum_Real+1]
			if EquipLevel_Real > EquipLevel_STL then
				EquipLevel_Real = EquipLevel_STL
			end
			if X_Real > X_STL then
				X_Real = X_STL
			end
			if Y_Real > Y_STL then
				Y_Real = Y_STL
			end
			if Z_Real > Z_STL then
				Z_Real = Z_STL
			end
			local EquipScore_Real = 10+EquipLevel_Real+(50000*X_Real*Y_Real*Z_Real)
			FightScore_TotalReal = FightScore_TotalReal+EquipScore_Real
			local nRate = math.floor(EquipScore_Real/EquipScore_STL*100)
			table.insert(g_FightScore_EquipRate,nRate)
		end
	end

	if FightScore_TotalSTL == 0 then
		g_FightScore_EquipTotalScore = 0
	else
		g_FightScore_EquipTotalScore = math.floor(FightScore_TotalReal/FightScore_TotalSTL*100)
	end
end


--	右列界面更新成装备页
function FightScore_EquipPageUpdate()
	FightScore_CleanRightActionItemInfo() --先清空
	g_FightScoreRightList:CleanAllElement("FightScore")	--先清空
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_51}") --设置标题
	FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_58}") --设置下方内容
	FightScoreFrame_Lace2_WYFY_Button:Hide() --隐藏武林风云按钮
	FightScoreFrame_Lace2_Shop_Button:Show()
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("#{PFZY_140613_44}") --商城按钮
	FightScoreFrame_Lace2_HD_Button:Show()
	FightScoreFrame_Lace2_HD_Button:SetToolTip("#{PFZY_140613_50}") --活动按钮

	local PlayerLevel_STL = FightScore_GetPlayerLevelSTL()
	local AttrNum_STL = FightScore_GetEquipAttrNum_STL(PlayerLevel_STL,g_ScoreBaseParam)
	local Str =""
	local A = DataPool:GetEquipTableValue(1)
	local B = g_Gem_Score_STL[g_ScoreBaseParam]["WuQi"]
	local C = g_Gem_Score_STL[g_ScoreBaseParam]["FYMX"]
	local D = AttrNum_STL
	local E = g_Gem_Score_STL[g_ScoreBaseParam]["YMX"]
	if PlayerLevel_STL <= 41 then
		Str = ScriptGlobal_Format("#{PFZY_140613_52}",A,B,C,D,E)
	else
		Str = ScriptGlobal_Format("#{PFZY_140613_53}",A,B,C,D,E)
	end
	FightScoreFrame_List2_Text:SetText(Str)  --标题下方
	FightScore_AddRightEquipPageElement()
end


function FightScore_AddRightEquipPageElement()
	for i=1,13 do
		local nIndex = image_right_1[i].index
		local tempEquip = EnumAction(nIndex, "equip")
		FightScore_AddEquipElement(tempEquip:GetID(), i)
	end
end

--	添加右侧装备栏
function FightScore_AddRightChildElement()
	local ItemBar = g_FightScoreRightList:AddItemElement( "FightScoreDetail", "LEFT", "FightScore","" ,"")
	if ItemBar == nil then
		return
	end
	ItemBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection")
	--先隐藏掉图片
	ItemBar:SetAchvGetedHide()
	ItemBar:SetAchievementBarIconDisImageHide()
	ItemBar:SetAchievementBarPointDisImageHide()
	ItemBar:SetAchievementBarPointImageHide()
	ItemBar:SetAchvGetHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarDateHide()
	ItemBar:SetAchievementBarProgressHide()
	ItemBar:SetAchievementBarProgressNameHide()
	for i = 2, 5 do
		nChildSlot = ItemBar:GetLuaActionButton(i,"FightScore")
		if nChildSlot ~= nil then
			nChildSlot:Hide()
		end
	end
	for j=1,16 do 
		if j < 2 or j > 6 then
			ItemBar:Setm_newImageHide(j)
		end
	end

	return ItemBar
end


function FightScore_SetRightElementStarNum( nRate , ChildUI, useTips)
	local StarNum = 0
	if nRate >=0 and nRate<=20 then
		StarNum = 5
	elseif nRate >=21 and nRate<=40 then
		StarNum = 4
	elseif nRate >=41 and nRate<=60 then
		StarNum = 3
	elseif nRate >=61 and nRate<=80 then
		StarNum = 2
	elseif nRate >=81 and nRate<100 then
		StarNum = 1
	elseif nRate >=100 then
		StarNum = 0
	end

	local Tips = ""
	--显示几个星星
	if StarNum >=1 then
		ChildUI:Setm_newImageShow(11)
		Tips ="#{PFZY_140613_49}"
	end
	if StarNum >=2 then
		ChildUI:Setm_newImageShow(12)
		Tips ="#{PFZY_140613_48}"
	end
	if StarNum >=3 then
		ChildUI:Setm_newImageShow(13)
		Tips ="#{PFZY_140613_47}"
	end
	if StarNum >=4 then
		ChildUI:Setm_newImageShow(14)
		Tips ="#{PFZY_140613_46}"
	end
	if StarNum >=5 then
		ChildUI:Setm_newImageShow(15)
		Tips ="#{PFZY_140613_45}"
	end

	--是否显示"荐"
	if StarNum >= 3 then
		ChildUI:Setm_newImageShow(16)
	end

	if useTips == 1 then
		ChildUI:SetToolTip(Tips)
	end

	return StarNum
end

function FightScore_AddEquipElement(actionID, nImageListIndex)
	local ItemBar = FightScore_AddRightChildElement()
	--	先设置好底图
	local itemButton = ItemBar:GetLuaActionButton(1,"FightScore")
	itemButton:SetProperty("BackImage", image_right_1[nImageListIndex].back)
	if actionID > 0 then
		itemButton:SetActionItem(actionID)
	end

	local nPos = image_right_1[nImageListIndex].index
	local EquipLevel = DataPool:GetEquipLevel(nPos)
	local EquipQual = DataPool:GetEquipQual(nPos)
	if EquipQual>100 then
		EquipQual = 8
	elseif EquipQual > 10 then
		EquipQual = math.floor(EquipQual/10)
	end
	local EquipAttrNum = DataPool:GetEquipAttrNum(nPos)
	local nRate = g_FightScore_EquipRate[nImageListIndex]

	local EquipLevel_STL,_ = DataPool:GetEquipScoreSTL(nPos)
	local EquipQual_STL = FightScore_GetEquipGem_STL(nPos,g_ScoreBaseParam)
	local EquipAttrNum_STL = FightScore_GetEquipAttrNum_STL(EquipLevel_STL,g_ScoreBaseParam)

	--有装备
	local StrContent1 =""
	local StrContent2 =""
	if actionID > 0 then
		if nPos == 0 and DataPool:IsSuperWeapon(0) == 1 then
			if nRate >= 100 then
				StrContent1 = ScriptGlobal_Format("#{PFZY_140613_60}",EquipLevel,EquipQual)
				ItemBar:Setm_newText(17, StrContent1)
				ItemBar:Setm_newTextShow(17)
			else
				StrContent1 = ScriptGlobal_Format("#{PFZY_140613_59}",EquipLevel,EquipQual)
				StrContent2 = ScriptGlobal_Format("#{PFZY_140613_200}",EquipLevel_STL,EquipQual_STL)
				ItemBar:Setm_newText(18, StrContent1)
				ItemBar:Setm_newTextShow(18)
				ItemBar:Setm_newText(19, StrContent2)
				ItemBar:Setm_newTextShow(19)
			end
		else
			if nRate >= 100 then
				StrContent1 = ScriptGlobal_Format("#{PFZY_140613_62}",EquipLevel,EquipQual,EquipAttrNum)
				ItemBar:Setm_newText(17, StrContent1)
				ItemBar:Setm_newTextShow(17)
			else
				StrContent1 = ScriptGlobal_Format("#{PFZY_140613_61}",EquipLevel,EquipQual,EquipAttrNum)
				StrContent2 = ScriptGlobal_Format("#{PFZY_140613_201}",EquipLevel_STL,EquipQual_STL,EquipAttrNum_STL)
				ItemBar:Setm_newText(18, StrContent1)
				ItemBar:Setm_newTextShow(18)
				ItemBar:Setm_newText(19, StrContent2)
				ItemBar:Setm_newTextShow(19)
			end
		end
	else
		StrContent1 = ScriptGlobal_Format("#{PFZY_140613_54}", image_right_1[nImageListIndex].name)
		itemButton:SetToolTip(ScriptGlobal_Format("#{PFZY_140613_39}", image_right_1[nImageListIndex].name))
		ItemBar:Setm_newText(17, StrContent1)
		ItemBar:Setm_newTextShow(17)
	end

	--	显示星星、推荐
	FightScore_SetRightElementStarNum(nRate,ItemBar,0)

	g_FightScoreRightList:Flash();
	table.insert(g_myRightButton, ItemBar)
end

--计算刻铭整体分
function FightScore_CalculateKeMingScore()
	local nScore_Real =0
	local nScore_STL = 0

	if g_ScoreBaseParam >= 6 then
		local PlayerLevel_STL = FightScore_GetPlayerLevelSTL()
		if CachedTarget:GetMySelfEquipMasterFlag() ~= 0 then --有百兵精通
			if PlayerLevel_STL>=1 and PlayerLevel_STL<=19 then
				nScore_STL = 13
			elseif PlayerLevel_STL >=20 and PlayerLevel_STL<=69 then
				nScore_STL = 14
			elseif PlayerLevel_STL>=70 and PlayerLevel_STL<=79 then
				nScore_STL = 15
			elseif PlayerLevel_STL >= 80 then
				nScore_STL = 16
			end
		else
			if PlayerLevel_STL>=1 and PlayerLevel_STL<=29 then
				nScore_STL = 13
			elseif PlayerLevel_STL >=30 and PlayerLevel_STL<=79 then
				nScore_STL = 14
			elseif PlayerLevel_STL >= 80 then
				nScore_STL = 16
			end
		end
	else
		nScore_STL = g_Gem_Score_STL[g_ScoreBaseParam]["KeMing"]
	end

	for i=1,table.getn(image_right_1) do
		if i == 15 then --武魂没有刻铭
			continue
		end
		local nPos = image_right_1[i].index
		if DataPool:IsSelfEquipLocked(nPos)==1 then
			nScore_Real = nScore_Real+1
		end
	end
	g_FightScore_KeMingTotalScore = math.floor(nScore_Real/nScore_STL*100)
end

--	右列界面更新成刻铭页
function FightScore_KeMingPageUpdate()
	FightScore_CleanRightActionItemInfo() --先清空
	g_FightScoreRightList:CleanAllElement("FightScore")	--先清空
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_134}") --设置标题
	FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_176}") --设置下方内容
	FightScoreFrame_Lace2_WYFY_Button:Hide() --隐藏武林风云按钮
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("#{PFZY_140613_44}") --商城按钮
	FightScoreFrame_Lace2_HD_Button:SetToolTip("#{PFZY_140613_50}") --活动按钮
	FightScoreFrame_List2_Text:SetText("")
	FightScore_AddRightKeMingPageElement()
end


function FightScore_AddRightKeMingPageElement()
	for i=1,table.getn(image_right_1) do
		local nIndex = image_right_1[i].index
		if nIndex == 18 then --武魂没刻铭
			continue
		end
		if Player:GetData("Is2606S") == 1 then
			if i == 16 and g_FightScore_2606SValid[12] == 0 then -- 龙纹
				continue
			elseif i == 18 and g_FightScore_2606SValid[16] == 0 then -- 豪侠印
				continue
			end
		end
		local tempEquip = EnumAction(nIndex, "equip")
		FightScore_AddKemingElement(tempEquip:GetID(), i)
	end
end

function FightScore_AddKemingElement(actionID, ListIndex)

	local ItemBar = FightScore_AddRightChildElement()
	--	先设置好底图
	local itemButton = ItemBar:GetLuaActionButton(1,"FightScore")
	itemButton:SetProperty("BackImage", image_right_1[ListIndex].back)

	if actionID > 0 then
		itemButton:SetActionItem(actionID)
	end

	local nPos = image_right_1[ListIndex].index

	local StrContent =""
	--有装备
	if actionID > 0 then
		if  DataPool:IsSelfEquipLocked(nPos) == 1 then
			StrContent = "#{PFZY_140613_135}"
			FightScore_SetRightElementStarNum(100,ItemBar,0)
		else
			StrContent = "#{PFZY_140613_136}"
			FightScore_SetRightElementStarNum(g_FightScore_KeMingTotalScore,ItemBar,0)
		end
	else
		StrContent = ScriptGlobal_Format("#{PFZY_140613_54}", image_right_1[ListIndex].name)
		itemButton:SetToolTip(ScriptGlobal_Format("#{PFZY_140613_39}", image_right_1[ListIndex].name))
		if nPos == 17 and g_FightScore_PlayLevel_STL <30 then
			itemButton:SetProperty("BackImage", "set:Fabao image:Fabao_2")
			if CachedTarget:GetMySelfEquipMasterFlag() ~= 0 then --有百兵精通
				StrContent = ScriptGlobal_Format("#{PFZY_140613_40}",20)
				itemButton:SetToolTip("")
			else
				StrContent = ScriptGlobal_Format("#{PFZY_140613_40}",30)
			end
		elseif nPos == 19 and g_FightScore_PlayLevel_STL <80 then
			itemButton:SetProperty("BackImage", "set:CircularTaskTool33 image:CircularTaskTool33_6")
			if CachedTarget:GetMySelfEquipMasterFlag() ~= 0 then --有百兵精通
				StrContent = ScriptGlobal_Format("#{PFZY_140613_56}",70)
			else
				StrContent = ScriptGlobal_Format("#{PFZY_140613_56}",80)
			end
			itemButton:SetToolTip("")
		elseif nPos == 20 and Player:GetLevel() < 80 then
			local PlayerLevel_Real = Player:GetLevel()
			itemButton:SetProperty("BackImage", "set:EquipLingPai image:EquipLingPai_5")
			StrContent = ScriptGlobal_Format("#{PFZY_140613_57}",80)
			itemButton:SetToolTip("")
		end
		FightScore_SetRightElementStarNum(g_FightScore_KeMingTotalScore,ItemBar,0)
	end

	ItemBar:Setm_newTextHide(1)
	ItemBar:Setm_newText(1, StrContent)
	ItemBar:Setm_newTextShow(1)

	--	显示星星、推荐


	g_FightScoreRightList:Flash();
	table.insert(g_myRightButton, ItemBar)
end

--计算附体整体分
local g_FightScore_FuTiRateMap={}
local g_FightScore_ChengZhangLv = {0,100,331,4000,15789} --成长率
local g_FightScore_PetWuXing = {0,24,56,107,232,392,852,2361,3695,21998,22399} --悟性
local g_FightScore_PetLingXing = {0,100,266,544,1044,1877,3127,5127,8461,13461,23461} --灵性
local g_FightScore_PetRHD = {0,40,106,244,632,792,1633,8639,9020,20681,20904} --融合度
local g_FightScore_Skill = {396,992,1022,1172,1922,5672,5672,5672} --附体技能
local g_FightScore_Skill_120 = {396,992,1022,1172,1922,5672,16922,39422} --附体技能


function FightScore_GetPetTakeLevelSTL(PlayerLevel_STL)
	if PlayerLevel_STL >= 45 and PlayerLevel_STL < 55 then
		return 45
	elseif PlayerLevel_STL >=55 and PlayerLevel_STL < 65 then
		return 45
	elseif PlayerLevel_STL >=65 and PlayerLevel_STL < 75 then
		return 45
	elseif PlayerLevel_STL >=75 and PlayerLevel_STL < 85 then
		return 75
	elseif PlayerLevel_STL >=85 and PlayerLevel_STL < 95 then
		return 85
	elseif PlayerLevel_STL >=95 then
		return 95
	end
end

function FightScore_GetTakeLevelRate(nTakeLevel)
	if nTakeLevel>=1 and nTakeLevel<=35 then
		return 0.13
	elseif nTakeLevel >=36 and  nTakeLevel <= 65 then
		return 0.18
	elseif nTakeLevel >=66 and  nTakeLevel <= 85 then
		return 0.24
	elseif nTakeLevel >=86 then
		return 1
	end
end

--分项顺序 携带等级/成长、悟性、灵性、融合度、珍兽等级、技能 1~5
local g_FightScoreFuTiData={} --计算顺便存下显示用的数据
function FightScore_CalculateFuTiScore()
	g_FightScoreFuTiData={}
	g_FightScore_FuTiRateMap={}
	local PetIndex = Pet:GetFuTiPetIndex() --当前的附体珍兽
	if PetIndex == -1 then --没有附体珍兽
		g_FightScore_FuTiTotalScore=0
		return
	end
	local IsCZL_JD = 0 --成长率是否鉴定过
	local Score_Real = 0
	local Score_STL = 0

	--携带等级/成长率
	local PlayerLevel_STL = FightScore_GetPlayerLevelSTL()
	local TakeLevel_Real = Pet:GetTakeLevel(PetIndex)
	local TakeLevel_STL = FightScore_GetPetTakeLevelSTL(PlayerLevel_STL)
	table.insert(g_FightScoreFuTiData,TakeLevel_Real)
	table.insert(g_FightScoreFuTiData,TakeLevel_STL)
	if TakeLevel_Real > TakeLevel_STL then
		TakeLevel_Real = TakeLevel_STL
	end

	local PetRate = Pet:GetGrowRate(PetIndex)
	local PetCZL_Real = Pet:GetPetGrowLevel(PetIndex,PetRate)
	local PetCZL_STL = g_Gem_Score_STL[g_ScoreBaseParam]["FTChengZhangLv"]
	local PetTakeScore_Real = 0
	local PetTakeScore_STL = 0
	local PetCZL_Score_Real = 0
	local PetCZL_Score_STL = 0
	if PetCZL_Real>=0 then
		IsCZL_JD = 1
		table.insert(g_FightScoreFuTiData,PetCZL_Real)
		PetCZL_Score_Real = g_FightScore_ChengZhangLv[PetCZL_Real+1]
		PetCZL_Score_STL = g_FightScore_ChengZhangLv[PetCZL_STL]
		PetTakeScore_Real = FightScore_GetTakeLevelRate(TakeLevel_Real)*PetCZL_Score_Real
		PetTakeScore_STL = FightScore_GetTakeLevelRate(TakeLevel_STL)*PetCZL_Score_STL
		if PetTakeScore_Real > PetTakeScore_STL then
			PetTakeScore_Real = PetTakeScore_STL
		end
		local PetTakeRate =  math.floor(PetTakeScore_Real/PetTakeScore_STL*100)
		table.insert(g_FightScore_FuTiRateMap,PetTakeRate)
	else
		table.insert(g_FightScoreFuTiData,-1) --负1显示为未知
		table.insert(g_FightScore_FuTiRateMap,0)--未鉴定，5星推荐
	end
	table.insert(g_FightScoreFuTiData,PetCZL_STL)

	--悟性
	local PetWuXing_Real = Pet:GetSavvy(PetIndex)
	local PetWuXing_STL = g_Gem_Score_STL[g_ScoreBaseParam]["FTWuXing"]
	table.insert(g_FightScoreFuTiData,PetWuXing_Real)
	table.insert(g_FightScoreFuTiData,PetWuXing_STL)
	local PetWuXingRate = math.floor(g_FightScore_PetWuXing[PetWuXing_Real+1]/g_FightScore_PetWuXing[PetWuXing_STL+1]*100)
	table.insert(g_FightScore_FuTiRateMap,PetWuXingRate)
	if PetWuXing_Real > PetWuXing_STL then
		PetWuXing_Real = PetWuXing_STL
	end


	--灵性
	local PetLingXing_Real = Pet:GetLixing(PetIndex)
	local PetLingXing_STL = g_Gem_Score_STL[g_ScoreBaseParam]["FTLingXing"]
	table.insert(g_FightScoreFuTiData,PetLingXing_Real)
	table.insert(g_FightScoreFuTiData,PetLingXing_STL)
	local PetLingXingRate = math.floor(g_FightScore_PetLingXing[PetLingXing_Real+1]/g_FightScore_PetLingXing[PetLingXing_STL+1]*100)
	table.insert(g_FightScore_FuTiRateMap,PetLingXingRate)
	if PetLingXing_Real > PetLingXing_STL then
		PetLingXing_Real = PetLingXing_STL
	end

	--融合度
	local PetRHD_Real = Pet:GetFitValue(PetIndex)
	local PetRHD_STL = g_Gem_Score_STL[g_ScoreBaseParam]["FTRongHeDu"]
	table.insert(g_FightScoreFuTiData,PetRHD_Real)
	table.insert(g_FightScoreFuTiData,PetRHD_STL)
	local PetRHDRate = math.floor(g_FightScore_PetRHD[PetRHD_Real+1]/g_FightScore_PetRHD[PetRHD_STL+1]*100)
	table.insert(g_FightScore_FuTiRateMap,PetRHDRate)
	if PetRHD_Real > PetRHD_STL  then
		PetRHD_Real = PetRHD_STL
	end

	--珍兽等级
	local PetLevel_Real = Pet:GetLevel(PetIndex)
	local PetLevel_STL = Player:GetLevel()
	table.insert(g_FightScoreFuTiData,PetLevel_Real)
	table.insert(g_FightScoreFuTiData,PetLevel_STL)
	local PetLevelRate = math.floor(PetLevel_Real/PetLevel_STL*100)
	table.insert(g_FightScore_FuTiRateMap,PetLevelRate)
	local definePetMaxLevel = Player:GetDefinePetMaxLevel()
	local L_Real = PetLevel_Real/definePetMaxLevel
	local L_STL = PetLevel_STL/definePetMaxLevel
	if L_Real > L_STL then
		L_Real = L_STL
	end
	--人物120之前评分不变 120之后改变
	local playerlevel = Player:GetLevel()
	local FightScore_Skill = g_FightScore_Skill
	local Gem_Score_STL = g_Gem_Score_STL
	if playerlevel >= 120 then
		FightScore_Skill = g_FightScore_Skill_120
		Gem_Score_STL = g_Gem_Score_STL_120
	end
	--附体技能 5个
	for i=0,4 do
		local SkillLevel_Real,Name =  DataPool:GetFuTiSkillLevel(i)
		local StrMark = "FTSkill"..tostring(i+1)
		local SkillLevel_STL = Gem_Score_STL[g_ScoreBaseParam][StrMark]
		local SkillRate = 0
		local SkillScore_Real = 0
		local SkillScore_STL = 0
		if SkillLevel_Real >= 0 then
			SkillScore_Real = FightScore_Skill[SkillLevel_Real+1] -- Lua、C++游标起始不同
			SkillScore_STL = FightScore_Skill[SkillLevel_STL+2] -- 技能表中前面有普通和高级2个0级技能
			SkillRate = math.floor(SkillScore_Real/SkillScore_STL*100)
			if  SkillScore_Real > SkillScore_STL then
				SkillScore_Real = SkillScore_STL
			end
			Score_Real = Score_Real+SkillScore_Real
		end
		table.insert(g_FightScore_FuTiRateMap,SkillRate)
		Score_STL = Score_STL+SkillScore_STL
	end

	if IsCZL_JD == 1 then
		Score_Real = Score_Real+g_FightScore_PetWuXing[PetWuXing_Real+1]+g_FightScore_PetLingXing[PetLingXing_Real+1]+g_FightScore_PetRHD[PetRHD_Real+1]+PetTakeScore_Real
		Score_STL = Score_STL+g_FightScore_PetWuXing[PetWuXing_STL]+g_FightScore_PetLingXing[PetLingXing_STL]+g_FightScore_PetRHD[PetRHD_STL]+PetTakeScore_STL
		g_FightScore_FuTiTotalScore = math.floor((10+Score_Real*L_Real)/(10+Score_STL*L_STL)*100)
	else
		g_FightScore_FuTiTotalScore = 0
	end
end

function FightScore_FuTiPageUpdate()
	FightScore_CleanRightActionItemInfo() --先清空
	g_FightScoreRightList:CleanAllElement("FightScore")	--先清空
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_112}") --设置标题
	FightScoreFrame_Lace2_WYFY_Button:SetToolTip("#{PFZY_140613_43}")
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("#{PFZY_140613_44}") --商城按钮
	FightScoreFrame_Lace2_HD_Button:SetToolTip("#{PFZY_140613_50}") --活动按钮
	FightScoreFrame_List2_Text:SetText("")  --标题下方
	FightScore_AddRightFuTiPageElement()

	local MissionIndex = 1611
	local bHaveDone = DataPool:Lua_IsMissionHaveDone(MissionIndex)
	if bHaveDone > 0 then
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_115}") --设置下方内容
		FightScoreFrame_Lace2_WYFY_Button:Hide() --隐藏武林风云按钮
	else
		local Str = "#{PFZY_140613_114}".."#{PFZY_140613_115}"
		FightScoreFrame_Lace2_Text:SetText(Str)
		FightScoreFrame_Lace2_WYFY_Button:Show()
	end
end

--通用接口，添加右侧子项
function FightScore_AddRightElement(ImageName,actionID,MidStr,StarRate,Tips,IsShowStar)
	local ItemBar = FightScore_AddRightChildElement()
	--	先设置好底图
	local itemButton = ItemBar:GetLuaActionButton(1,"FightScore")
	itemButton:SetProperty("BackImage", ImageName)
	if actionID > 0 then
		itemButton:SetActionItem(actionID)
	else
		itemButton:SetToolTip(Tips)
	end

	ItemBar:Setm_newText(1, MidStr)
	ItemBar:Setm_newTextShow(1)

	--	显示星星、推荐
	if IsShowStar == 1 then
		FightScore_SetRightElementStarNum(StarRate,ItemBar,1)
	end

	g_FightScoreRightList:Flash();
	table.insert(g_myRightButton, ItemBar)
end

--通用接口，添加右侧子项
function FightScore_AddRightElementWithSixString(ImageName,actionID,str1,str2,str3,str4,str5,str6,StarRate,useTips,IsShowStar)
	local ItemBar = FightScore_AddRightChildElement()
	--	先设置好底图
	local itemButton = ItemBar:GetLuaActionButton(1,"FightScore")
	itemButton:SetProperty("BackImage", ImageName)
	if actionID > 0 then
		itemButton:SetActionItem(actionID)
	end

	local Tips =""

	if StarRate >= 100 then
		if str1 ~= "" then
			ItemBar:Setm_newText(17,str1)
			ItemBar:Setm_newTextShow(17)
		end

		if str2 ~= "" then
			ItemBar:Setm_newText(18,"      "..str2)
			ItemBar:Setm_newTextShow(18)
		end

		if str3 ~= "" then
			ItemBar:Setm_newText(19,"      "..str3)
			ItemBar:Setm_newTextShow(19)
		end
	else
		if str1 ~= "" then
			ItemBar:Setm_newText(3,str1)
			ItemBar:Setm_newTextShow(3)
		end

		if str2 ~= "" then
			ItemBar:Setm_newText(4,str2)
			ItemBar:Setm_newTextShow(4)
		end

		if str3 ~= "" then
			ItemBar:Setm_newText(5,str3)
			ItemBar:Setm_newTextShow(5)
		end

		if str4 ~= "" then
			ItemBar:Setm_newText(6,str4)
			ItemBar:Setm_newTextShow(6)
		end

		if str5 ~= "" then
			ItemBar:Setm_newText(7,str5)
			ItemBar:Setm_newTextShow(7)
		end

		if str6 ~= "" then
			ItemBar:Setm_newText(8,str6)
			ItemBar:Setm_newTextShow(8)
		end
	end

	if useTips == 1 then
		ItemBar:SetToolTip(Tips)
	end
	--	显示星星、推荐
	if IsShowStar == 1 then
		FightScore_SetRightElementStarNum(StarRate,ItemBar,1)
	end

	g_FightScoreRightList:Flash();
	table.insert(g_myRightButton, ItemBar)
end

g_FightScore_ChengZhangString ={"普通","优秀","杰出","卓越","完美"}
function FightScore_AddRightFuTiPageElement()
	local Num = table.getn(g_FightScore_FuTiRateMap)
	if Num ==0 then --没有附体珍兽
		FightScore_AddRightElement("",-1,"#{PFZY_140613_113}",g_FightScore_FuTiTotalScore,"",0)
		return
	end

	local PetIndex = Pet:GetFuTiPetIndex() --当前的附体珍兽
	if PetIndex == -1 then --没有附体珍兽
		return
	end

	--附体第一子项需特写
	local nNum = table.getn(g_FightScoreFuTiData)
	local PetIcon = Pet:GetPetPortraitByIndex(PetIndex)
	local Level_Real = g_FightScoreFuTiData[1]
	local Level_STL = g_FightScoreFuTiData[2]
	local CZL_Real = g_FightScoreFuTiData[3]
	local CZL_STL = g_FightScoreFuTiData[4]
	local nRate1 = g_FightScore_FuTiRateMap[1]
	local str1=""
	if CZL_Real >= 0 then--成长率鉴定标记
		str1 = ScriptGlobal_Format("#{PFZY_140613_118}",g_FightScore_ChengZhangString[CZL_Real+1])
	else
		str1 = ScriptGlobal_Format("#{PFZY_140613_118}","未知")
	end

	if nRate1 < 100 then
		FightScore_AddRightElementWithSixString(PetIcon,-1,"#{PFZY_140613_116}",
												ScriptGlobal_Format("#{PFZY_140613_117}",Level_Real),
												str1,
												"#{PFZY_140613_119}",
												ScriptGlobal_Format("#{PFZY_140613_120}",Level_STL),
												ScriptGlobal_Format("#{PFZY_140613_121}",g_FightScore_ChengZhangString[CZL_STL]),
												nRate1,
												1,
												1)
	else
		FightScore_AddRightElementWithSixString(PetIcon,-1,"#{PFZY_140613_116}",
												ScriptGlobal_Format("#{PFZY_140613_120}",Level_Real),
												ScriptGlobal_Format("#{PFZY_140613_121}",g_FightScore_ChengZhangString[CZL_Real+1]),
												"","","",nRate1,1,0)
	end

	--悟性
	local WuXing_Real = g_FightScoreFuTiData[5]
	local WuXing_STL = g_FightScoreFuTiData[6]
	local WuXingRate  = g_FightScore_FuTiRateMap[2]
	local WuXingIcon = "set:Cloth4 image:Cloth4_8"
	local WuXingString = ""
	if WuXingRate < 100 then
		WuXingString =ScriptGlobal_Format("#{PFZY_140613_122}",WuXing_Real,WuXing_STL)
	else
		WuXingString =ScriptGlobal_Format("#{PFZY_140613_123}",WuXing_Real)
	end
	FightScore_AddRightElement(WuXingIcon,-1,WuXingString,WuXingRate,"",1)

	--灵性
	local LingXing_Real = g_FightScoreFuTiData[7]
	local LingXing_STL = g_FightScoreFuTiData[8]
	local LingXingRate  = g_FightScore_FuTiRateMap[3]
	local LingXingIcon = "set:PetMedicine image:PetMedicine_14"
	local LingXingString = ""
	if LingXingRate < 100 then
		LingXingString =ScriptGlobal_Format("#{PFZY_140613_124}",LingXing_Real,LingXing_STL)
	else
		LingXingString =ScriptGlobal_Format("#{PFZY_140613_125}",LingXing_Real)
	end
	FightScore_AddRightElement(LingXingIcon,-1,LingXingString,LingXingRate,"",1)

	--融合度
	local RHD_Real = g_FightScoreFuTiData[9]
	local RHD_STL = g_FightScoreFuTiData[10]
	local RHDRate  = g_FightScore_FuTiRateMap[4]
	local RHDIcon = "set:PetMedicine image:PetMedicine_16"
	local RHDString = ""
	if RHDRate < 100 then
		RHDString =ScriptGlobal_Format("#{PFZY_140613_126}",RHD_Real,RHD_STL)
	else
		RHDString =ScriptGlobal_Format("#{PFZY_140613_127}",RHD_Real)
	end
	FightScore_AddRightElement(RHDIcon,-1,RHDString,RHDRate,"",1)

	--珍兽等级
	local Level_Real = g_FightScoreFuTiData[11]
	local Level_STL = g_FightScoreFuTiData[12]
	local LevelRate  = g_FightScore_FuTiRateMap[5]
	local LevelIcon = "set:TaskTools15 image:TaskTools15_16"
	local LevelString = ""
	if LevelRate < 100 then
		LevelString =ScriptGlobal_Format("#{PFZY_140613_197}",Level_Real,Level_STL)
	else
		LevelString =ScriptGlobal_Format("#{PFZY_140613_198}",Level_Real)
	end
	FightScore_AddRightElement(LevelIcon,-1,LevelString,LevelRate,"",1)

	--人物120之前评分不变 120之后改变
	local playerlevel = Player:GetLevel()
	local Gem_Score_STL = g_Gem_Score_STL
	if playerlevel >= 120 then
		Gem_Score_STL = g_Gem_Score_STL_120
	end

	--5个附体技能
	local SkillString =""
	local IconName =""
	for i=0,4 do
		local SkillLevel_Real,ImageName =  DataPool:GetFuTiSkillLevel(i)
		if SkillLevel_Real < 0 then
			FightScore_AddRightElement("",-1,"#{PFZY_140613_128}",0,"",1)
			continue
		end
		if SkillLevel_Real < 2 then
			SkillLevel_Real = 0
		else
			SkillLevel_Real = SkillLevel_Real-1
		end
		local StrMark = "FTSkill"..tostring(i+1)
		local SkillLevel_STL = Gem_Score_STL[g_ScoreBaseParam][StrMark]
		local SkillRate = g_FightScore_FuTiRateMap[6+i]
		if SkillLevel_Real >= 0 then
			if SkillRate < 100 then
				SkillString = ScriptGlobal_Format("#{PFZY_140613_129}",SkillLevel_Real,SkillLevel_STL)
			else
				SkillString = ScriptGlobal_Format("#{PFZY_140613_130}",SkillLevel_Real)
			end
		end
		IconName = FightScore_GetIconName(ImageName)
		FightScore_AddRightElement(IconName,-1,SkillString,SkillRate,"",1)
	end
end

function FightScore_GetIconName(ImageName)
	local Temp =""
	if ImageName ~= nil and ImageName ~= "" then
		local sPos, ePos = string.find(ImageName, "_")
		if sPos ~= nil then
			local filename = string.sub(ImageName, 0, sPos-1)
			Temp = string.format("set:%s image:%s", filename, ImageName)
		end
	end
	return Temp
end

--获取武魂的标准等级和成长率
--获取武魂标准评分
local g_FightScore_WuhunX={0,300,400,700,1600,4300,12400,28600,61000} --8个等级
local g_FightScore_WuhunY={268,990,3960,19800,99000}
--g_FightScore_ChengZhangString ={"普通","优秀","杰出","卓越","完美"}

function Fight_GetWuHunScore_STL(MaxGemNum,nPos)
	if nPos > 7 or nPos < 0 then
		return 0
	end
	local g_WuhunAttrMap ={}
	if nPos == 0 then --为0时，是算武魂整体标准评分
		local X=0
		for i=1,7 do
			local mark = "WuHunAttr"..tostring(i)
			local level_stl = g_Gem_Score_STL[MaxGemNum][mark]
			if level_stl> 8 then
				level_stl=8
			end
			local AttrScore_STL=g_FightScore_WuhunX[level_stl+1]
			table.insert(g_WuhunAttrMap,AttrScore_STL)
		end
		local Temp = g_Gem_Score_STL[MaxGemNum]["WuHunRate_STL"]
		return Player:GetLevel(),g_WuhunAttrMap[1],g_WuhunAttrMap[2],g_WuhunAttrMap[3],g_WuhunAttrMap[4],g_WuhunAttrMap[5],
		g_WuhunAttrMap[6],g_WuhunAttrMap[7],g_FightScore_WuhunY[Temp]
	end

	--nPos不为0，就是要单个武魂属性的等级
	local mark = "WuHunAttr"..tostring(nPos)
	local level_stl = g_Gem_Score_STL[MaxGemNum][mark]
	return level_stl
end

--公式	10+装备等级+(X1+X2+X3+X4+X5+X6+X7)+成长率打造值
local g_FightScore_IsHaveWuHun = 1
function FightScore_CalculateWuHunScore()
	g_FightScore_IsHaveWuHun = 1
	local WuHunLevel_Real,WuHunAttr1_Real,WuHunAttr2_Real,WuHunAttr3_Real,WuHunAttr4_Real,WuHunAttr5_Real,WuHunAttr6_Real,WuHunAttr7_Real,WuHunCZL_Real
	= DataPool:GetEquipScore(18) --18为武魂装备位
	local WuHunLevel_STL,WuHunAttr1_STL,WuHunAttr2_STL,WuHunAttr3_STL,WuHunAttr4_STL,WuHunAttr5_STL,WuHunAttr6_STL,WuHunAttr7_STL,WuHunCZL_STL
	= Fight_GetWuHunScore_STL(g_ScoreBaseParam,0)
	if WuHunLevel_Real > 0 then --装备了武魂
		if WuHunLevel_Real > WuHunLevel_STL then
			WuHunLevel_Real = WuHunLevel_STL
		end
		if WuHunAttr1_Real > WuHunAttr1_STL then
			WuHunAttr1_Real = WuHunAttr1_STL
		end
	    if WuHunAttr2_Real > WuHunAttr2_STL then
			WuHunAttr2_Real = WuHunAttr2_STL
		end
		if WuHunAttr3_Real > WuHunAttr3_STL then
			WuHunAttr3_Real = WuHunAttr3_STL
		end
		if WuHunAttr4_Real > WuHunAttr4_STL then
			WuHunAttr4_Real = WuHunAttr4_STL
		end
		if WuHunAttr5_Real > WuHunAttr5_STL then
			WuHunAttr5_Real = WuHunAttr5_STL
		end
		if WuHunAttr6_Real > WuHunAttr6_STL then
			WuHunAttr6_Real = WuHunAttr6_STL
		end
		if WuHunAttr7_Real > WuHunAttr7_STL then
			WuHunAttr7_Real = WuHunAttr7_STL
		end
		if WuHunCZL_Real > WuHunCZL_STL then
			WuHunCZL_Real = WuHunCZL_STL
		end

		local WuHunScore_Real = 10+WuHunAttr1_Real+WuHunAttr2_Real+WuHunAttr3_Real+WuHunAttr4_Real+WuHunAttr5_Real+
		WuHunAttr6_Real+WuHunAttr7_Real+WuHunCZL_Real
		local WuHunScore_STL = 10+WuHunAttr1_STL+WuHunAttr2_STL+WuHunAttr3_STL+WuHunAttr4_STL+WuHunAttr5_STL+
		WuHunAttr6_STL+WuHunAttr7_STL+WuHunCZL_STL

		g_FightScore_WuHunTotalScore = math.floor(WuHunScore_Real/WuHunScore_STL*100)
	else
		g_FightScore_WuHunTotalScore = 0
		g_FightScore_IsHaveWuHun = 0
	end
end

function FightScore_WuhunPageUpdate()
	FightScore_CleanRightActionItemInfo() --先清空
	g_FightScoreRightList:CleanAllElement("FightScore")	--先清空
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_95}") --设置标题
	FightScoreFrame_Lace2_WYFY_Button:SetToolTip("#{PFZY_140613_43}")
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("#{PFZY_140613_44}") --商城按钮
	FightScoreFrame_Lace2_HD_Button:SetToolTip("#{PFZY_140613_50}") --活动按钮
	FightScoreFrame_List2_Text:SetText("")  --标题下方
	FightScore_AddRightWuHunPageElement()

	--	最下面的描述文字
	local MissionIndex = 1621
	local bHaveDone = DataPool:Lua_IsMissionHaveDone(MissionIndex)
	if bHaveDone > 0 then
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_98}")
		FightScoreFrame_Lace2_WYFY_Button:Hide()
	else
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_97}".."#{PFZY_140613_98}")
		FightScoreFrame_Lace2_WYFY_Button:Show()
	end
end



function FightScore_AddRightWuHunPageElement()
	if g_FightScore_IsHaveWuHun == 0 then --未装备武魂
		local IconName = "set:CommonFrame7 image:WuhunEquip"
		FightScore_AddRightElement(IconName,-1,"#{PFZY_140613_96}",0,"",0)
		return
	end

	--装备了武魂
	--成长属性
	local WuHunA_Real = DataPool:GetEquipScore(18,-1)
	local WuHunA_STL = g_Gem_Score_STL[g_ScoreBaseParam]["WuHunRate_STL"]
	local WuHunA_Rate = math.floor(g_FightScore_WuhunY[WuHunA_Real]/g_FightScore_WuhunY[WuHunA_STL]*100)
	local WuHunAString =""
	local WuHunAction = EnumAction(18, "equip")
	if WuHunA_Rate < 100 then
		WuHunAString = ScriptGlobal_Format("#{PFZY_140613_99}",g_FightScore_ChengZhangString[WuHunA_Real],g_FightScore_ChengZhangString[WuHunA_STL])
	else
		WuHunAString = ScriptGlobal_Format("#{PFZY_140613_100}",g_FightScore_ChengZhangString[WuHunA_Real])
	end
	FightScore_AddRightElement("",WuHunAction:GetID(),WuHunAString,WuHunA_Rate,"",1)

	--7条拓展属性
	for i=1,7 do
		local Level_Real,IconName,AttrName = DataPool:GetEquipScore(18,i-1)
		local attr_Rate = 0
		local ImageName = FightScore_GetIconName(IconName)
		local MidStr =""
		if Level_Real < 0 or IconName==nil or AttrName == nil then --属性没学习
			MidStr = "#{PFZY_140613_102}"
			FightScore_AddRightElement("",-1,MidStr,0,"#{PFZY_140613_101}",1)
		else
			local attr_Real = g_FightScore_WuhunX[Level_Real+1]
			local Level_STL = Fight_GetWuHunScore_STL(g_ScoreBaseParam,i)

			if Level_STL == 0 then
				attr_Rate = 100
			else
				local attr_STL = g_FightScore_WuhunX[Level_STL+1]
				attr_Rate = math.floor(attr_Real/attr_STL*100)
			end

			if attr_Rate < 100 then
				MidStr =ScriptGlobal_Format("#{PFZY_140613_103}",Level_Real,Level_STL)
			else
				MidStr =ScriptGlobal_Format("#{PFZY_140613_104}",Level_Real)
			end
			FightScore_AddRightElement(ImageName,-1,MidStr,attr_Rate,AttrName,1)
		end
	end
end

--精通
function FightScore_GetJingTongScore_STL(MaxGemNum)
	return g_Gem_Score_STL[MaxGemNum]["JingTong"]*3
end

function FightScore_CalculateJingTongScore()
	local Score_Real1,Score_Real2,Score_Real3,Score_Real4,Score_Real5,Score_Real6,Score_Real7,Score_Real8,
			Score_Real9,Score_Real10,Score_Real11,Score_Real12 = DataPool:GetJingTongScore(0,g_Gem_Score_STL[g_ScoreBaseParam]["JingTong"])
	local Score_STL = FightScore_GetJingTongScore_STL(g_ScoreBaseParam)
	if Score_Real1 > Score_STL then
		Score_Real1 = Score_STL
	end
	if Score_Real2 > Score_STL then
		Score_Real2 = Score_STL
	end
	if Score_Real3 > Score_STL then
		Score_Real3 = Score_STL
	end
	if Score_Real4 > Score_STL then
		Score_Real4 = Score_STL
	end
	if Score_Real5 > Score_STL then
		Score_Real5 = Score_STL
	end
	if Score_Real6 > Score_STL then
		Score_Real6 = Score_STL
	end
	if Score_Real7 > Score_STL then
		Score_Real7 = Score_STL
	end
	if Score_Real8 > Score_STL then
		Score_Real8 = Score_STL
	end
	if Score_Real9 > Score_STL then
		Score_Real9 = Score_STL
	end
	if Score_Real10 > Score_STL then
		Score_Real10 = Score_STL
	end
	if Score_Real11 > Score_STL then
		Score_Real11 = Score_STL
	end
	if Score_Real12 > Score_STL then
		Score_Real12 = Score_STL
	end

	local ScoreTotal_Real = Score_Real1+Score_Real2+Score_Real3+Score_Real4+Score_Real5+Score_Real6+Score_Real7+Score_Real8+Score_Real9+Score_Real10+Score_Real11+Score_Real12
	local ScoreTotal_STL = Score_STL*12
	g_FightScore_JingTongScore =  math.floor(ScoreTotal_Real/ScoreTotal_STL*100)
end

function FightScore_JingTongPageUpdate()
	FightScore_CleanRightActionItemInfo() --先清空
	g_FightScoreRightList:CleanAllElement("FightScore")	--先清空
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_143}") --设置标题
	FightScoreFrame_Lace2_WYFY_Button:SetToolTip("#{PFZY_140613_43}")
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("#{PFZY_140613_44}") --商城按钮
	FightScoreFrame_Lace2_HD_Button:SetToolTip("#{PFZY_140613_50}") --活动按钮
	local Level_STL = g_Gem_Score_STL[g_ScoreBaseParam]["JingTongLevel"]
	FightScoreFrame_List2_Text:SetText(ScriptGlobal_Format("#{PFZY_140613_144}",Level_STL))  --标题下方
	FightScore_AddRightJingTongPageElement()

	--	最下面的描述文字
	local MissionIndex = 1802
	local bHaveDone = DataPool:Lua_IsMissionHaveDone(MissionIndex)
	if bHaveDone > 0 then
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_150}") --设置下方内容
		FightScoreFrame_Lace2_WYFY_Button:Hide()
	else
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_149}".."#{PFZY_140613_150}")
		FightScoreFrame_Lace2_WYFY_Button:Show()
	end
end

function FightScore_AddRightJingTongPageElement()
	for i=2,13 do
		local nIndex = image_right_1[i].index
		local tempEquip = EnumAction(nIndex, "equip")
		FightScore_AddJingTongElement(tempEquip:GetID(), i)
	end
end

function FightScore_AddJingTongElement(actionID, nImageListIndex)
	local nPos = image_right_1[nImageListIndex].index
	local Score_Real = DataPool:GetJingTongScore(nPos,g_Gem_Score_STL[g_ScoreBaseParam]["JingTong"])

	if actionID < 0 or Score_Real < 0 then --没装备
		local StrContent = ScriptGlobal_Format("#{PFZY_140613_54}", image_right_1[nImageListIndex].name)
		local ToolTip = ScriptGlobal_Format("#{PFZY_140613_39}", image_right_1[nImageListIndex].name)
		FightScore_AddRightElement(image_right_1[nImageListIndex].back,-1,StrContent,0,ToolTip,1)
		return
	elseif Score_Real == 0 then --未淬炼(未精通属性)
		FightScore_AddRightElement("",actionID,"#{PFZY_140613_145}",0,"",1)
		return
	elseif actionID > 0 and Score_Real > 0 then --有装备、有属性精通
		local AttrLevel1,AttrName1,AttrLevel2,AttrName2,AttrLevel3,AttrName3 = DataPool:GetJingTongAttrInfo(nPos)
		local Score_STL = FightScore_GetJingTongScore_STL(g_ScoreBaseParam)
		local nRate = math.floor(Score_Real/Score_STL*100)
		local Level_STL = g_Gem_Score_STL[g_ScoreBaseParam]["JingTongLevel"]
		local Str1,Str2,Str3

		if AttrLevel1 < Level_STL then
			Str1 = ScriptGlobal_Format("#{PFZY_140613_147}","#cfff263#{"..AttrName1.."}",AttrLevel1)
		else
			Str1 = ScriptGlobal_Format("#{PFZY_140613_148}","#cfff263#{"..AttrName1.."}",AttrLevel1)
		end

		if AttrLevel2 < Level_STL then
			Str2 = ScriptGlobal_Format("#{PFZY_140613_147}","#cfff263#{"..AttrName2.."}",AttrLevel2)
		else
			Str2 = ScriptGlobal_Format("#{PFZY_140613_148}","#cfff263#{"..AttrName2.."}",AttrLevel2)
		end

		if AttrLevel3 < Level_STL then
			Str3 = ScriptGlobal_Format("#{PFZY_140613_147}","#cfff263#{"..AttrName3.."}",AttrLevel3)
		else
			Str3 = ScriptGlobal_Format("#{PFZY_140613_148}","#cfff263#{"..AttrName3.."}",AttrLevel3)
		end

		FightScore_AddRightElementWithFourString("",actionID,"#{PFZY_140613_146}",Str1,Str2,Str3,nRate,0,1)
	end
end

--通用接口，添加右侧子项
function FightScore_AddRightElementWithFourString(ImageName,actionID,strTile,str1,str2,str3,StarRate,useTips,IsShowStar)
	local ItemBar = FightScore_AddRightChildElement()
	--	先设置好底图
	local itemButton = ItemBar:GetLuaActionButton(1,"FightScore")
	itemButton:SetProperty("BackImage", ImageName)
	if actionID > 0 then
		itemButton:SetActionItem(actionID)
	end

	local Tips =""

	if str1 ~= "" then
		ItemBar:Setm_newText(13,strTile)
		ItemBar:Setm_newTextShow(13)
	end

	if str2 ~= "" then
		ItemBar:Setm_newText(14,str1)
		ItemBar:Setm_newTextShow(14)
	end

	if str3 ~= "" then
		ItemBar:Setm_newText(15,str2)
		ItemBar:Setm_newTextShow(15)
	end

	if str4 ~= "" then
		ItemBar:Setm_newText(16,str3)
		ItemBar:Setm_newTextShow(16)
	end

	if useTips == 1 then
		ItemBar:SetToolTip(Tips)
	end
	--	显示星星、推荐
	if IsShowStar == 1 then
		FightScore_SetRightElementStarNum(StarRate,ItemBar,1)
	end

	g_FightScoreRightList:Flash();
	table.insert(g_myRightButton, ItemBar)
end

--真元
local g_FightScore_ZhenYuan_MF={599, 596, 598, 590, 591, 593, 594, 592, 597, 589, 595, 600}
local g_FightScore_ZhenYuan_Equip = {1,5,4,6,11,12,13,14,3,7,2,15} --真元装备位顺序

--返回真元标准品质字符串、标准等级、标准评分
function FightScore_GetPneumaScore_STL(MaxGemNum)
	return g_Gem_Score_STL[MaxGemNum]["ZYStr"],g_Gem_Score_STL[MaxGemNum]["ZYLevel_STL"],g_Gem_Score_STL[MaxGemNum]["ZYScore_STL"]
end

function FightScore_CalculateZhenYuanScore()
	local TotalScore = 0
	local TotalScore_STL = 0
	local nQualSTL,nLevelSTL,nScore_STL = FightScore_GetPneumaScore_STL(g_ScoreBaseParam)
	for i=1,table.getn(g_FightScore_ZhenYuan_MF) do
		local MF = Pneuma:GetMF(g_FightScore_ZhenYuan_MF[i])
		local PneumaAction,_ = Pneuma:EnumPneumaItem("pneuma", i-1)
		if MF ~= 1 or PneumaAction:GetID() == 0 then
			continue
		end

		local nScoreReal,_,_ = DataPool:GetPneumaScore(g_FightScore_ZhenYuan_Equip[i])
		if nScoreReal > nScore_STL then
			nScoreReal = nScore_STL
		end
		if nScoreReal < 0 then
			continue
		end
		TotalScore = TotalScore+nScoreReal
	end
	TotalScore_STL = nScore_STL*12
	g_FightScore_ZhenYuanScore = math.floor(TotalScore/TotalScore_STL*100)
end

function FightScore_ZhenYuanPageUpdate()
	FightScore_CleanRightActionItemInfo() --先清空
	g_FightScoreRightList:CleanAllElement("FightScore")	--先清空
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_71}") --设置标题
	FightScoreFrame_Lace2_WYFY_Button:SetToolTip("#{PFZY_140613_43}")
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("#{PFZY_140613_44}") --商城按钮
	FightScoreFrame_Lace2_HD_Button:SetToolTip("#{PFZY_140613_50}") --活动按钮
	FightScoreFrame_List2_Text:SetText("")  --标题下方
	FightScore_AddRightZhenYuanPageElement()

	--	最下面的描述文字
	local MissionIndex = 1627
	local bHaveDone = DataPool:Lua_IsMissionHaveDone(MissionIndex)
	if bHaveDone > 0 then
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_76}")
		FightScoreFrame_Lace2_WYFY_Button:Hide()
	else
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_75}".."#{PFZY_140613_76}")
		FightScoreFrame_Lace2_WYFY_Button:Show()
	end
end

local g_FightScore_ZhenYuanColor={"白色","绿色","蓝色","紫色","橙色","金色"}
function FightScore_AddRightZhenYuanPageElement()
	local nQualSTL,nLevelSTL,nScore_STL = FightScore_GetPneumaScore_STL(g_ScoreBaseParam)
	for i=2,13 do
		local EquipPos = image_right_1[i].index
		local EquipAction = EnumAction(EquipPos,"equip")
		local ActionID = EquipAction:GetID()

		--没装备
		if ActionID <= 0 then
			local StrContent = ScriptGlobal_Format("#{PFZY_140613_54}", image_right_1[i].name)
			local ToolTip = ScriptGlobal_Format("#{PFZY_140613_39}", image_right_1[i].name)
			FightScore_AddRightElement(image_right_1[i].back,-1,StrContent,0,ToolTip,1)
		else
			--未解封盘眼或未装备真元
			local PneumaAction, bBlocked = Pneuma:EnumPneumaItem("pneuma", image_right_1[i].ZhenYuanIndex )
			
			if bBlocked == 1 or PneumaAction:GetID() == 0 then
				FightScore_AddRightElement("",ActionID,"#{PFZY_140613_72}",0,"",1)
			else
				--有真元
				local nScore_Real,nLevelReal,nQualReal = DataPool:GetPneumaScore(EquipPos)
				local nReteChild = math.floor(nScore_Real/nScore_STL*100)
				local StrZhenYuan =""
				if nReteChild < 100 then
					StrZhenYuan = ScriptGlobal_Format("#{PFZY_140613_73}",g_FightScore_ZhenYuanColor[nQualReal],nLevelReal,g_FightScore_ZhenYuanColor[nQualSTL],nLevelSTL)
				else
					StrZhenYuan = ScriptGlobal_Format("#{PFZY_140613_74}",g_FightScore_ZhenYuanColor[nQualReal],nLevelReal)
				end
				FightScore_AddRightElement("",ActionID,StrZhenYuan,nReteChild,"",1)
			end
		end
	end
end

--令牌
local g_Lingpai_QualScore={0,100,484,1406,3254,8432,16632,33896,61488,89934};
local g_LingPai_BaoZhuScore={0,10,27,54,81,112,144,176,216,257,
				298,352,406,460,533,605,677,772,867,962,1084,
				1206,1328,1482,1635,1789,1979,2168,2358,2589,2819,3049,
				3325,3601,3876,4202,4527,4852,5232,5611,5991,6429,6867,7306,
				7807,8309,8810,9380,9949,10518,11088}
local g_LingPai_DaZaoScore={500,1500,3000,5000,7500}
local g_LingPai_Name={"江湖令","金兰令","聚义令","歃血令","霸王令"}

function FightScore_GetLingPaiScore_STL(MaxGemNum)
	local Level = 80  --令牌标准等级
	local X = 7500  --打造成本
	local BaoZhuLevel = g_Gem_Score_STL[MaxGemNum]["BaoZhu"]
	local BaoZhuScore = g_LingPai_BaoZhuScore[BaoZhuLevel+1]
	local Qual = g_Gem_Score_STL[MaxGemNum]["LingPaiType"]
	local R = g_Lingpai_QualScore[Qual+1]
	return Level,X,BaoZhuScore,BaoZhuScore,BaoZhuScore,BaoZhuScore,R
end

function FightScore_CalculateLingPaiScore()
	local LingPaiLevel_Real, LingPaiX_Real,LingPaiBZ1_Real,LingPaiBZ2_Real,LingPaiBZ3_Real,LingPaiBZ4_Real,LingPaiR_Real= DataPool:GetLingPaiScore()
	local LingPaiLevel_STL, LingPaiX_STL,LingPaiBZ1_STL,LingPaiBZ2_STL,LingPaiBZ3_STL,LingPaiBZ4_STL,LingPaiR_STL = FightScore_GetLingPaiScore_STL(g_ScoreBaseParam)
	if LingPaiLevel_Real <=0 then
		g_FightScore_LingPaiScore = 0
	else
		if LingPaiLevel_Real > LingPaiLevel_STL then
			LingPaiLevel_Real = LingPaiLevel_STL
		end
		if LingPaiX_Real > LingPaiX_STL then
			LingPaiX_Real = LingPaiX_STL
		end
		if LingPaiBZ1_Real > LingPaiBZ1_STL then
			LingPaiBZ1_Real = LingPaiBZ1_STL
		end
		if LingPaiBZ2_Real > LingPaiBZ2_STL then
			LingPaiBZ2_Real = LingPaiBZ2_STL
		end
		if LingPaiBZ3_Real > LingPaiBZ3_STL then
			LingPaiBZ3_Real = LingPaiBZ3_STL
		end
		if LingPaiBZ4_Real > LingPaiBZ4_STL then
			LingPaiBZ4_Real = LingPaiBZ4_STL
		end
		if LingPaiR_Real > LingPaiR_STL then
			LingPaiR_Real = LingPaiR_STL
		end
		local ScpreTotal_Real = 10+LingPaiLevel_Real+LingPaiX_Real+LingPaiBZ1_Real+LingPaiBZ2_Real+LingPaiBZ3_Real+LingPaiBZ4_Real+LingPaiR_Real
		local ScoreTotal_STL = 10+LingPaiLevel_STL+LingPaiX_STL+LingPaiBZ1_STL+LingPaiBZ2_STL+LingPaiBZ3_STL+LingPaiBZ4_STL+LingPaiR_STL
		g_FightScore_LingPaiScore = math.floor(ScpreTotal_Real/ScoreTotal_STL*100)
	end
end

function FightScore_GetXiaYinScore_STL(MaxGemNum)
    local maxGem = tonumber(MaxGemNum)
    if maxGem < 3 then
        maxGem = 3
    elseif maxGem > 8 then
        maxGem = 8
    end
    local scmaps = {
        --成长等级，授印属性等级，属性条目
        {15,4,1},     --对应3级宝石
        {30,10,3},    --对应4级宝石
        {60,15,5},    --对应5级宝石
        {100,20,7},   --对应6级宝石
        {100,20,7},   --对应7级宝石
        {100,20,7},   --对应8级宝石
    }
    local ret = scmaps[maxGem-2]
    return ret[1], ret[2], ret[3]
end

function FightScore_GetXiaYinInfo()
    local item = EnumAction( 21, "equip" )
    if not item or item:GetID() <= 0 then
        return -1, {}
    end
    local lv = item:GetEquipHXYLevel()
    local props = {0,0,0,0,0,0,0}
    for i=1,7 do
        local nIndex , iEffectLevel = DataPool:Lua_GetHXYEffect( i - 1 )
        if nIndex ~= nil then
            props[i] = iEffectLevel
        end
    end
    return lv, props
end

function FightScore_CalculateXiaYinScore()
    local myLv, myProps = FightScore_GetXiaYinInfo()
    local stdLv, stdProp = FightScore_GetXiaYinScore_STL(g_ScoreBaseParam)
    g_FightScore_XiaYinScore = 0
    if myLv >= 0 then
        local myScore = 10 + 85
        if myLv > 0 and myLv <= 100 then
			if myLv > stdLv then
				myScore = myScore + g_FightScore_XiaYinLevelScore[stdLv]
			else
				myScore = myScore + g_FightScore_XiaYinLevelScore[myLv]
			end
        end
        for i=1, 7 do
            if myProps[i] > 0 and myProps[i] <= 20 then
				if myProps[i] > stdProp then
					myScore = myScore + g_FightScore_XiaYinPropLevelScore[ stdProp ]
				else
					myScore = myScore + g_FightScore_XiaYinPropLevelScore[ myProps[i] ]
				end
            end
        end
        local stdScore = 10 + 85
		if stdLv > 0 and stdLv <= 100 then
            stdScore = stdScore + g_FightScore_XiaYinLevelScore[stdLv]
        end
		if stdProp > 0 and stdProp <= 20 then
			stdScore = stdScore + g_FightScore_XiaYinPropLevelScore[stdProp] * 7
		end
        g_FightScore_XiaYinScore = math.floor( myScore * 100 / stdScore )
    end
end

function FightScore_CalcMartialSocre()
	local MartialLevel = MaritialSys:GetMaritiaLevel()
	local nAlreadyPoint = MaritialSys:GetMaritiaAlreadyPoint()
	local nRemainPoint = MaritialSys:GetMaritiaRemainPoint()
	local nAleardyTalentPoint = 0
	g_FightScore_MartialScore = 10
	for i=1,5 do
		local nId,nLevel = MaritialSys:GetTalentLevelBylayerID(i - 1)
		nAleardyTalentPoint = nAleardyTalentPoint + nLevel
	end
	local nRemainTalentPoint = MaritialSys:GetTalentRemainPoint()
	if(MartialLevel >= 150  and 
	   nAlreadyPoint > 0 and nRemainPoint <= 0 and
	   nAleardyTalentPoint > 0	and nRemainTalentPoint <= 0) then
			g_FightScore_MartialScore = 100
	end
end

function FightScore_LingPaiPageUpdate()
	FightScore_CleanRightActionItemInfo() --先清空
	g_FightScoreRightList:CleanAllElement("FightScore")	--先清空
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_172}") --设置标题
	FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_183}") --设置下方内容
	FightScoreFrame_Lace2_WYFY_Button:Hide() --武林风云按钮
	FightScoreFrame_Lace2_WYFY_Button:SetToolTip("#{PFZY_140613_43}")
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("#{PFZY_140613_44}") --商城按钮
	FightScoreFrame_Lace2_HD_Button:SetToolTip("#{PFZY_140613_50}") --活动按钮
	FightScoreFrame_List2_Text:SetText("")  --标题下方
	FightScore_AddRightLingPaiPageElement()
end

function FightScore_AddRightLingPaiPageElement()
	local AciontRL = EnumAction(20,"equip")
	local ActionID = AciontRL:GetID()
	if ActionID <= 0 then --未装备令牌
		FightScore_AddRightElement(image_right_1[17].back,-1,"#{PFZY_140613_173}",0,"",0)
		return
	end

	local nType,BaoZhu1,BaoZhu2,BaoZhu3,BaoZhu4,nQual = DataPool:GetLingPaiInfo()
	local BaoZhuLevelMap={}
	table.insert(BaoZhuLevelMap,BaoZhu1)
	table.insert(BaoZhuLevelMap,BaoZhu2)
	table.insert(BaoZhuLevelMap,BaoZhu3)
	table.insert(BaoZhuLevelMap,BaoZhu4)

	if nType < 0 or BaoZhu1 == nil then
		--没有令牌
		return
	end

	--打造成本
	local DaZaoScore_Real = g_LingPai_DaZaoScore[nType+1]
	local DaZaoScore_STL = 7500
	local nRate1 = math.floor(DaZaoScore_Real/DaZaoScore_STL*100)
	local Name1 = g_LingPai_Name[nType+1]
	local Str1 =""
	if nRate1 < 100 then
		Str1 = ScriptGlobal_Format("#{PFZY_140613_186}",Name1,"霸王令")
	else
		Str1 = ScriptGlobal_Format("#{PFZY_140613_187}",Name1)
	end
	FightScore_AddRightElement("",ActionID,Str1,nRate1,"",1)

	--4个宝珠位置
	local BaoZhuScoreLevel_STL = g_Gem_Score_STL[g_ScoreBaseParam]["BaoZhu"]
	local BaoZhuScore_STL = g_LingPai_BaoZhuScore[BaoZhuScoreLevel_STL+1]
	for i=1,4 do
		local nLevel = BaoZhuLevelMap[i]
		if nLevel == nil or nLevel <= 0 then
			FightScore_AddRightElement("",-1,"#{PFZY_140613_188}",0,"",1)
		else
			local BaoZhuScore_Real = g_LingPai_BaoZhuScore[nLevel+1]
			local RateBaoZhu = math.floor(BaoZhuScore_Real/BaoZhuScore_STL*100)
			local IconName,ItemName = DataPool:GetLingPaiBaoZhuIconName(i-1)
			if IconName ~= "" then
				IconName = FightScore_GetIconName(IconName)
			end
			if ItemName == nil then
				ItemName =""
			end
			local StrBaoZhu = ""
			if RateBaoZhu <100 then
				StrBaoZhu = ScriptGlobal_Format("#{PFZY_140613_189}",nLevel,BaoZhuScoreLevel_STL)
			else
				StrBaoZhu = ScriptGlobal_Format("#{PFZY_140613_190}",nLevel)
			end
			FightScore_AddRightElement(IconName,-1,StrBaoZhu,RateBaoZhu,ItemName,1)
		end
	end

	--星级
	local StarLevel_Real = nQual
	local StarLevel_STL = g_Gem_Score_STL[g_ScoreBaseParam]["LingPaiType"]
	local StarRate = math.floor(g_Lingpai_QualScore[StarLevel_Real+1]/g_Lingpai_QualScore[StarLevel_STL+1]*100)
	local StrStar = ""
	if StarRate < 100 then
		StrStar =ScriptGlobal_Format("#{PFZY_140613_191}",StarLevel_Real,StarLevel_STL)
	else
		StrStar =ScriptGlobal_Format("#{PFZY_140613_192}",StarLevel_Real)
	end
	FightScore_AddRightElement("set:CircularTaskTool60 image:CircularTaskTool60_15",-1,StrStar,StarRate,"",1)
end

function FightScore_XiaYinPageUpdate()
	FightScore_CleanRightActionItemInfo() --先清空
	g_FightScoreRightList:CleanAllElement("FightScore")	--先清空
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_140613_206}") --设置标题
	FightScoreFrame_Lace2_Text:SetText("#{PFZY_140613_207}") --设置下方内容
	FightScoreFrame_Lace2_WYFY_Button:Hide() --武林风云按钮
	FightScoreFrame_Lace2_WYFY_Button:SetToolTip("#{PFZY_140613_43}")
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("#{PFZY_140613_44}") --商城按钮
	FightScoreFrame_Lace2_HD_Button:SetToolTip("#{PFZY_140613_210}") --活动按钮
	FightScoreFrame_List2_Text:SetText("")  --标题下方
	FightScore_AddRightXiaYinPageElement()    
end 


function FightScore_AddRightXiaYinPageElement()
    local AciontRL = EnumAction(21,"equip")
	local ActionID = AciontRL:GetID()
	if ActionID <= 0 then --未装备侠印
		FightScore_AddRightElement(image_right_1[18].back,-1,
		ScriptGlobal_Format("#{PFZY_140613_54}", "#{HXYSJ_141031_21}"),0,
		ScriptGlobal_Format("#{PFZY_140613_39}", "#{HXYSJ_141031_21}"),0)
		return
	end
    local lv, props = FightScore_GetXiaYinInfo()
    local stdLv, stdProp = FightScore_GetXiaYinScore_STL(g_ScoreBaseParam)
    --FightScore_AddRightElement(ImageName,actionID,MidStr,StarRate,Tips,IsShowStar)
    local icondic = {
		"set:JunXian1 image:JunXian1_1",
		"set:JunXian1 image:JunXian1_6",
		"set:JunXian1 image:JunXian1_5",
		"set:JunXian1 image:JunXian1_2",
		"set:JunXian1 image:JunXian1_4",
		"set:JunXian1 image:JunXian1_3",
		"set:JunXian1 image:JunXian1_7",
	}
	local tipsdic = {
		"#{JXJW_140922_12}",
		"#{JXJW_140922_14}",
		"#{JXJW_140922_13}",
		"#{JXJW_140922_11}",
		"#{JXJW_140922_16}",
		"#{JXJW_140922_17}",
		"#{JXJW_140922_15}",
	}
	if lv < stdLv then
		if lv < 1 then
			lv = 1
		end
		FightScore_AddRightElement("",ActionID, ScriptGlobal_Format("#{PFZY_140613_91}",lv,stdLv) ,
			math.floor(g_FightScore_XiaYinLevelScore[lv]*100/g_FightScore_XiaYinLevelScore[stdLv]),"",1)
	else
		FightScore_AddRightElement("",ActionID, ScriptGlobal_Format("#{PFZY_140613_92}",lv) , 1.0 ,"",1)
	end
    for i=1,7 do
		if props[i] < stdProp then
			if props[i] <= 0 then
				FightScore_AddRightElement(icondic[i],-1,"#{PFZY_140613_219}", 0.0, tipsdic[i], 1 )
			else
				FightScore_AddRightElement(icondic[i],-1,ScriptGlobal_Format("#{PFZY_140613_91}",props[i],stdProp),
					math.floor(g_FightScore_XiaYinPropLevelScore[ props[i] ]*100/g_FightScore_XiaYinPropLevelScore[stdProp]),tipsdic[i],1)
			end
		else
			FightScore_AddRightElement(icondic[i],-1,ScriptGlobal_Format("#{PFZY_140613_92}",props[i]), 1.0 ,tipsdic[i],1)
		end
    end   
end

function FightScore_MartialPageUpDate()
	FightScore_CleanRightActionItemInfo() --先清空
	g_FightScoreRightList:CleanAllElement("FightScore")	--先清空
	FightScoreFrame_List2_Title_Text:SetText("#gFF0FA0武意") --设置标题
	FightScoreFrame_Lace2_Text:SetText("#{PFZY_171016_01}") --设置下方内容
	if(DataPool:Lua_IsMissionHaveDone(1868) ~= 1 ) then
		FightScoreFrame_Lace2_WYFY_Button:Show() --武林风云按钮
	else
		FightScoreFrame_Lace2_WYFY_Button:Hide() --武林风云按钮
	end
	FightScoreFrame_Lace2_WYFY_Button:SetToolTip("#{PFZY_140613_43}")
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("#{PFZY_140613_44}") --商城按钮
	FightScoreFrame_Lace2_HD_Button:SetToolTip("#{PFZY_140613_210}") --活动按钮
	FightScoreFrame_List2_Text:SetText("")  --标题下方
	FightScore_AddRightMartialPageElement()
end

function FightScore_AddRightMartialPageElement()
	local MartialLevelIcon = "set:Ach_Icon image:Ach_Icon_14";
	local MartialAttrIcon = "set:CircularTaskTool88 image:CircularTaskTool88_14";
	local MartialTalentIcon = "set:CircularTaskTool88 image:CircularTaskTool88_15"
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or Player:GetLevel() < 85) then
		FightScore_AddRightElement(MartialLevelIcon,-1,"#{PFBJ_170911_01}",1.0,"#{PFBJ_170911_01}",1)
	else
		--武意等级
		local MartialLevel = MaritialSys:GetMaritiaLevel()
		local leveltips = ScriptGlobal_Format("#{PFBJ_170911_03}",MartialLevel).."#r".."#{PFBJ_170911_14}"
		local bStart = 1
		if(MartialLevel >= 150) then
			leveltips = ScriptGlobal_Format("#{PFBJ_170911_13}",MartialLevel)
			bStart = 0
		end
		FightScore_AddRightElement(MartialLevelIcon,-1,leveltips,(MartialLevel/150),"",bStart)
		--武意灵气
		local nAlreadyPoint = MaritialSys:GetMaritiaAlreadyPoint()
		local nRemainPoint = MaritialSys:GetMaritiaRemainPoint()
		local AttrTips = ScriptGlobal_Format("#{PFBJ_170911_15}",nAlreadyPoint)
		bStart = 1
		if(nAlreadyPoint > 0 and nRemainPoint <= 0 ) then
			AttrTips = ScriptGlobal_Format("#{PFBJ_170911_16}",nAlreadyPoint)
			bStart = 0
		else
			if(nAlreadyPoint + nRemainPoint > 0) then
				AttrTips = AttrTips .."#r"..ScriptGlobal_Format("#{PFBJ_170911_17}",tostring(nAlreadyPoint+nRemainPoint))
			end
		end
		FightScore_AddRightElement(MartialAttrIcon,-1,AttrTips,1.0,"",bStart)
		--武意培元
		local nAleardyTalentPoint = 0
		for i=1,5 do
			local nId,nLevel = MaritialSys:GetTalentLevelBylayerID(i - 1)
			nAleardyTalentPoint = nAleardyTalentPoint + nLevel
		end
		local nRemainTalentPoint = MaritialSys:GetTalentRemainPoint()
		local TalentTips = ScriptGlobal_Format("#{PFBJ_170911_18}",nAleardyTalentPoint)
		bStart = 1
		if(nAleardyTalentPoint > 0 and nRemainTalentPoint <= 0) then
			TalentTips = ScriptGlobal_Format("#{PFBJ_170911_19}",nAleardyTalentPoint)
			bStart = 0
		else
			if(nAleardyTalentPoint + nRemainTalentPoint > 0) then
				TalentTips = TalentTips.."#r"..ScriptGlobal_Format("#{PFBJ_170911_20}",tostring(nAleardyTalentPoint+nRemainTalentPoint))
			end
		end
		FightScore_AddRightElement(MartialTalentIcon,-1,TalentTips,1.0,"",bStart)
	end

end

function FightScore_SetButtonState(index, bEnable, map_index)	
	if index > 0 and index <= 20 then	
		Button_Left[index] = bEnable
		m_ButtonIndexMap[index] = map_index	
	end	
end

function FightScore_CheckButtonState(bEnable, map_index)
	local addFlag = 1
	if Player:GetData("Is2606S") == 1 then
		if g_FightScore_2606SValid[map_index] then
			addFlag = g_FightScore_2606SValid[map_index]
		end
	end
	if addFlag == 1 then	
		table.insert(Button_Left, bEnable)
		table.insert(m_ButtonIndexMap, map_index)
		return 1
	end	
	return 0
end

function FightScore_CalcXingZhenScore()

	local XingZhenScore = 0
	local XingZhenScore_STL = 100
	
	local XingJuanCollectionScore = {0, 0, 0, 0}
	local nMaxXingJuanNum = DataPool:LuaFnGetXingJuanMaxCount()
	for i = 1, nMaxXingJuanNum do
		local nXingJuanID = DataPool:LuaFnMyXingJuanID(i - 1)
		if nXingJuanID > 0 then
			local nUnLocked = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "UnLocked")
			if nUnLocked == 1 then
				local nOrder = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
				local nQuality = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Quality")
				if nQuality >= 1 and nQuality <= 4 and nOrder >= 0 and nOrder <= 5 then
					XingJuanCollectionScore[nQuality] = XingJuanCollectionScore[nQuality] + g_XingJuanScore[nQuality][nOrder + 1].active
				end
			end
		end
	end
	
	local SkillCardCollectionScore = {0, 0, 0, 0}
	local nMaxSkillCardNum = DataPool:LuaFnGetSkillCardMaxCount()
	for i = 1, nMaxSkillCardNum do
		local nSkillCardID = DataPool:LuaFnMySkillCardID(i - 1)
		if nSkillCardID > 0 then
			local nUnLocked = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "UnLocked")
			if nUnLocked == 1 then
				local nLevel = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Level")
				local nQuality = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Quality")
				if nQuality >= 1 and nQuality <= 4 and nLevel >= 1 and nLevel <= 5 then
					SkillCardCollectionScore[nQuality] = SkillCardCollectionScore[nQuality] + g_SkillCardScore[nQuality][nLevel].active
				end
			end			
		end
	end
	
	for i = 1, 4 do
		local nXingJuanID = DataPool:LuaFnGetActivedXingJuanID(i)
		if nXingJuanID > 0 then
			local nUnLocked = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "UnLocked")
			if nUnLocked == 1 then
				local nOrder = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
				local nQuality = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Quality")
				if nQuality >= 1 and nQuality <= 4 and nOrder >= 0 and nOrder <= 5 then
					XingZhenScore = XingZhenScore + g_XingJuanScore[nQuality][nOrder + 1].slot
				end
				
				local nSkillCardID = DataPool:LuaFnGetActivedSkillCardID(i)
				
				if nSkillCardID > 0 then
					local nUnLocked = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "UnLocked")
					if nUnLocked == 1 then
						local nLevel = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Level")
						local nQuality = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Quality")
						if nQuality >= 1 and nQuality <= 4 and nLevel >= 1 and nLevel <= 5 then
							XingZhenScore = XingZhenScore + g_SkillCardScore[nQuality][nLevel].slot
						end
					end			
				end
			end	
		end
	end
	
	local nXingJuanSlot_STL = g_XingZhenScore_STL[g_ScoreBaseParam].x_slot_stl
	local nSkillCardSlot_STL = g_XingZhenScore_STL[g_ScoreBaseParam].c_slot_stl
	local nXingJuanActive_STL = 0
	local XingJuanCollectionScoreAll = 0
	for i = 1, 4 do
		if g_XingZhenScore_STL[g_ScoreBaseParam].x_active_stl[i] ~= 0 then
			nXingJuanActive_STL = nXingJuanActive_STL + g_XingZhenScore_STL[g_ScoreBaseParam].x_active_stl[i]
			XingJuanCollectionScoreAll = XingJuanCollectionScoreAll + XingJuanCollectionScore[i]
		end
	end
	
	local nSkillCardActive_STL = 0
	local SkillCardCollectionScoreAll = 0
	for i = 1, 4 do
		if g_XingZhenScore_STL[g_ScoreBaseParam].c_active_stl[i] ~= 0 then
			nSkillCardActive_STL = nSkillCardActive_STL + g_XingZhenScore_STL[g_ScoreBaseParam].c_active_stl[i]
			SkillCardCollectionScoreAll = SkillCardCollectionScoreAll + SkillCardCollectionScore[i]
		end
	end
	
	XingZhenScore = XingZhenScore + XingJuanCollectionScoreAll + SkillCardCollectionScoreAll	
	XingZhenScore_STL = nXingJuanSlot_STL*4 + nSkillCardSlot_STL*4 + nXingJuanActive_STL + nSkillCardActive_STL
	
	g_FightScore_XingZhenScore = math.floor(XingZhenScore/XingZhenScore_STL*100)
	for i = 1, 4 do
		g_FightScore_XingJuanCollectionScore[i] = 0
		if g_XingZhenScore_STL[g_ScoreBaseParam].x_active_stl[i] ~= 0 then
			g_FightScore_XingJuanCollectionScore[i] = math.floor(XingJuanCollectionScore[i]/g_XingZhenScore_STL[g_ScoreBaseParam].x_active_stl[i]*100)
		end
		
		g_FightScore_SkillCardCollectionScore[i] = 0
		if g_XingZhenScore_STL[g_ScoreBaseParam].c_active_stl[i] ~= 0 then
			g_FightScore_SkillCardCollectionScore[i] = math.floor(SkillCardCollectionScore[i]/g_XingZhenScore_STL[g_ScoreBaseParam].c_active_stl[i]*100)
		end
	end

end

function FightScore_XingZhenPageUpdate()
	
	FightScore_CleanRightActionItemInfo() 				--先清空
	g_FightScoreRightList:CleanAllElement("FightScore")	--先清空
	
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_200424_01}") --设置标题
	
	if DataPool:Lua_IsMissionHaveDone(1926) ~= 1 then
		FightScoreFrame_Lace2_WYFY_Button:Show() --武林风云按钮
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_200424_29}#{PFZY_200424_30}") --设置下方内容
	else
		FightScoreFrame_Lace2_WYFY_Button:Hide() --武林风云按钮
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_200424_30}") --设置下方内容
	end
	FightScoreFrame_Lace2_WYFY_Button:SetToolTip("#{PFZY_140613_43}")
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("#{PFZY_140613_44}") --商城按钮
	FightScoreFrame_Lace2_HD_Button:SetToolTip("#{PFZY_140613_50}") --活动按钮
	FightScoreFrame_List2_Text:SetText("")  --标题下方
	FightScore_AddRightXingZhenPageElement()
end

function FightScore_AddRightXingZhenPageElement()
	
	for i = 1, 4 do	
		local ItemBar = FightScore_AddRightChildElement()
		--	先设置好底图
		local itemButton = ItemBar:GetLuaActionButton(1,"FightScore")
		itemButton:SetProperty("BackImage", "")		
		
		local nRate = 0
		local nXingJuanID = DataPool:LuaFnGetActivedXingJuanID(i)
		
		if nXingJuanID > 0 then
			local nOrder = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
			local nQuality = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Quality")
			local theAction = EnumAction(nXingJuanID,"xingjuan")
			if theAction:GetID() ~= 0  then
				itemButton:SetActionItem(theAction:GetID())			
			end
			
			if nQuality >= 1 and nQuality <= 4 and nOrder >= 0 and nOrder <= 5 then
				if	g_XingJuanScore[nQuality][nOrder + 1].slot < g_XingZhenScore_STL[g_ScoreBaseParam].x_slot_stl then
					local Recommand_Qual = g_XingZhenScore_STL[g_ScoreBaseParam].qual
					local strTemp = ScriptGlobal_Format("#{PFZY_200424_05}", g_XingZhenQualText[nQuality], tostring(nOrder), g_XingZhenQualText[Recommand_Qual], "5")
					ItemBar:Setm_newText(1, strTemp)
				else				
					local strTemp = ScriptGlobal_Format("#{PFZY_200424_16}", g_XingZhenQualText[nQuality], tostring(nOrder))
					ItemBar:Setm_newText(1, strTemp)
				end
				
				nRate = math.floor(g_XingJuanScore[nQuality][nOrder + 1].slot/g_XingZhenScore_STL[g_ScoreBaseParam].x_slot_stl*100)				
			end
		else
			itemButton:SetToolTip("#{PFZY_200424_03}")
			ItemBar:Setm_newText(1, "#{PFZY_200424_02}")
		end
		
		FightScore_SetRightElementStarNum(nRate,ItemBar,0)		
		table.insert(g_myRightButton, ItemBar)
	end
	
	for i = 1, 4 do	
		local ItemBar = FightScore_AddRightChildElement()
		--	先设置好底图
		local itemButton = ItemBar:GetLuaActionButton(1,"FightScore")
		itemButton:SetProperty("BackImage", "")		
		
		local nRate = 0
		local nSkillCardID = DataPool:LuaFnGetActivedSkillCardID(i)
		
		if nSkillCardID > 0 then			
			local nLevel = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Level")
			local nQuality = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Quality")	
			local cardAction = EnumAction(nSkillCardID,"skillcard")
			if cardAction:GetID() ~= 0  then
				itemButton:SetActionItem(cardAction:GetID())			
			end
			
			if nQuality >= 1 and nQuality <= 4 and nLevel >= 1 and nLevel <= 5 then
				if	g_SkillCardScore[nQuality][nLevel].slot < g_XingZhenScore_STL[g_ScoreBaseParam].c_slot_stl then
					local Recommand_Qual = g_XingZhenScore_STL[g_ScoreBaseParam].qual
					local strTemp = ScriptGlobal_Format("#{PFZY_200424_18}", g_XingZhenQualText[nQuality], tostring(nLevel), g_XingZhenQualText[Recommand_Qual], "5")
					ItemBar:Setm_newText(1, strTemp)					
				else				
					local strTemp = ScriptGlobal_Format("#{PFZY_200424_19}", g_XingZhenQualText[nQuality], tostring(nLevel))
					ItemBar:Setm_newText(1, strTemp)
				end
				
				nRate = math.floor(g_SkillCardScore[nQuality][nLevel].slot/g_XingZhenScore_STL[g_ScoreBaseParam].c_slot_stl*100)				
			end
		else
			itemButton:SetToolTip("#{PFZY_200424_17}")
			ItemBar:Setm_newText(1, "#{PFZY_200424_04}")
		end
		
		FightScore_SetRightElementStarNum(nRate,ItemBar,0)		
		table.insert(g_myRightButton, ItemBar)
	end
	
	FightScore_AddRightXingZhenPageElement_XingJuanCollection()
	FightScore_AddRightXingZhenPageElement_SkillCardCollection()
	g_FightScoreRightList:Flash()

end

function FightScore_AddRightXingZhenPageElement_XingJuanCollection()
	
	local strText = {"#{PFZY_200424_20}", "#{PFZY_200424_21}", "#{PFZY_200424_22}", "#{PFZY_200424_23}"}

	for i = 1, 4 do	
		
		local index = 4 - i + 1
		
		if g_XingZhenScore_STL[g_ScoreBaseParam].x_active_stl[index] ~= 0 then
	
			local ItemBar = FightScore_AddRightChildElement()
			local itemButton = ItemBar:GetLuaActionButton(1,"FightScore")
			
			local valid_count, collect_count, uporder_count = DataPool:LuaFnXingJuanCollection(index)
			local strTemp = ScriptGlobal_Format(strText[i], tostring(collect_count), tostring(valid_count), tostring(uporder_count))
			ItemBar:Setm_newText(1, strTemp)
				
			itemButton:SetProperty("BackImage", g_XingJuanImg[index])
			
			FightScore_SetRightElementStarNum(g_FightScore_XingJuanCollectionScore[index],ItemBar,0)
			table.insert(g_myRightButton, ItemBar)
		end
	end
	
end

function FightScore_AddRightXingZhenPageElement_SkillCardCollection()
	
	local strText = {"#{PFZY_200424_24}", "#{PFZY_200424_25}", "#{PFZY_200424_26}", "#{PFZY_200424_27}"}
	
	for i = 1, 4 do	
		
		local index = 4 - i + 1
		
		if g_XingZhenScore_STL[g_ScoreBaseParam].c_active_stl[index] ~= 0 then
	
			local ItemBar = FightScore_AddRightChildElement()
			local itemButton = ItemBar:GetLuaActionButton(1,"FightScore")
			
			local valid_count, collect_count, uporder_count = DataPool:LuaFnSkillCardCollection(index)
			local strTemp = ScriptGlobal_Format(strText[i], tostring(collect_count), tostring(valid_count), tostring(uporder_count))
			ItemBar:Setm_newText(1, strTemp)
				
			itemButton:SetProperty("BackImage", g_SkillCardImg[index])
			
			FightScore_SetRightElementStarNum(g_FightScore_SkillCardCollectionScore[index],ItemBar,0)
			table.insert(g_myRightButton, ItemBar)
		end
	end
	
end

function FightScore_GetXingZhen_STL(MaxGemNum,nPos)
	local nXingJuanSlot_STL = g_XingZhenScore_STL[MaxGemNum].x_slot_stl
	local nSkillCardSlot_STL = g_XingZhenScore_STL[MaxGemNum].c_slot_stl
	local nXingJuanSlot_STL = g_XingZhenScore_STL[MaxGemNum].x_slot_stl
	local nSkillCardSlot_STL = g_XingZhenScore_STL[MaxGemNum].c_slot_stl
	
end

local g_UA_Rank_Name = {
	"#{PFZY_220915_07}",
	"#{PFZY_220915_08}",
	"#{PFZY_220915_09}",
	"#{PFZY_220915_10}",
	"#{PFZY_220915_11}",
	"#{PFZY_220915_12}",
}

local g_UnderArmour_STL = {
	[3] = {ua_stl = 65209, jewel_stl = 46875, plate_stl = 100000},
	[4] = {ua_stl = 86945, jewel_stl = 46875, plate_stl = 100000},
	[5] = {ua_stl = 113029, jewel_stl = 125000, plate_stl = 300000},
	[6] = {ua_stl = 130418, jewel_stl = 125000, plate_stl = 300000},
	[7] = {ua_stl = 130418, jewel_stl = 125000, plate_stl = 300000},
	[8] = {ua_stl = 130418, jewel_stl = 125000, plate_stl = 300000},
}

local g_UnderArmour_Recommand = {
	[3] = {ua_rank = "#{PFZY_220915_12}", ua_star = 4, jewel_qual = "#{PFZY_220915_18}", jewel_level = 5, plate_level = 1},
	[4] = {ua_rank = "#{PFZY_220915_12}", ua_star = 6, jewel_qual = "#{PFZY_220915_18}", jewel_level = 5, plate_level = 1},
	[5] = {ua_rank = "#{PFZY_220915_12}", ua_star = 8, jewel_qual = "#{PFZY_220915_19}", jewel_level = 5, plate_level = 3},
	[6] = {ua_rank = "#{PFZY_220915_12}", ua_star = 9, jewel_qual = "#{PFZY_220915_19}", jewel_level = 5, plate_level = 3},
	[7] = {ua_rank = "#{PFZY_220915_12}", ua_star = 9, jewel_qual = "#{PFZY_220915_19}", jewel_level = 5, plate_level = 3},
	[8] = {ua_rank = "#{PFZY_220915_12}", ua_star = 9, jewel_qual = "#{PFZY_220915_19}", jewel_level = 5, plate_level = 3},
}

function FightScore_CalcUnderArmourScore()
	local iUnderArmourScore = 0
	local iUnderArmourScore_STL = 0

	for i = 1, 3 do
		local iActive = DataPool:LuaFnGetUnderArmourData(i - 1, "ACTIVED")
		if iActive == 1 then
			local iRank = DataPool:LuaFnGetUnderArmourData(i - 1, "RANK")
			local iLevel = DataPool:LuaFnGetUnderArmourData(i - 1, "LEVEL")
			local iStar = DataPool:LuaFnGetUnderArmourData(i - 1, "STAR")

			local fScore = DataPool:LuaFnGetUnderArmourFightScore(i - 1, iRank, iLevel, iStar)
			iUnderArmourScore = iUnderArmourScore + fScore
			g_FightScore_UnderArmourScore[i] = fScore
			
			local iJewel = DataPool:LuaFnGetUnderArmourData(i - 1, "JEWEL")
			if tonumber(iJewel) ~= nil and tonumber(iJewel) > 0 then
				local iJewelLevel = DataPool:LuaFnGetUnderArmourData(i - 1, "JEWEL_LEVEL")
				fScore = DataPool:LuaFnGetUnderArmourJewelFightScore(tonumber(iJewel), iJewelLevel)
				iUnderArmourScore = iUnderArmourScore + fScore
				g_FightScore_UnderArmourJewelScore[i] = fScore
				
				local iPlate = DataPool:LuaFnGetUnderArmourData(i - 1, "PLATE")
				if tonumber(iPlate) ~= nil and tonumber(iPlate) > 0 then
					local iPlateLevel = DataPool:LuaFnGetUnderArmourData(i - 1, "PLATE_LEVEL")
					fScore = DataPool:LuaFnGetUnderArmourPlateFightScore(tonumber(iPlate), iPlateLevel)
					iUnderArmourScore = iUnderArmourScore + fScore
					g_FightScore_UnderArmourPlateScore[i] = fScore
				end
			end
		end
	end
	
	iUnderArmourScore_STL = iUnderArmourScore_STL + g_UnderArmour_STL[g_ScoreBaseParam].ua_stl
	iUnderArmourScore_STL = iUnderArmourScore_STL + g_UnderArmour_STL[g_ScoreBaseParam].jewel_stl
	iUnderArmourScore_STL = iUnderArmourScore_STL + g_UnderArmour_STL[g_ScoreBaseParam].plate_stl
	iUnderArmourScore_STL = iUnderArmourScore_STL * 3

	g_FightScore_UnderArmourTotalScore = math.floor(iUnderArmourScore/iUnderArmourScore_STL*100)
end

function FightScore_UnderArmourPageUpdate()
	
	FightScore_CleanRightActionItemInfo() 				--先清空
	g_FightScoreRightList:CleanAllElement("FightScore")	--先清空
	
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_220915_02}") --设置标题
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		FightScoreFrame_Lace2_WYFY_Button:Show() --武林风云按钮
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_220915_28}#{PFZY_220915_29}") --设置下方内容
	else
		FightScoreFrame_Lace2_WYFY_Button:Hide() --武林风云按钮
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_220915_29}") --设置下方内容
	end
	FightScoreFrame_Lace2_WYFY_Button:SetToolTip("#{PFZY_220915_30}")
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("#{PFZY_140613_44}") --商城按钮
	FightScoreFrame_Lace2_HD_Button:SetToolTip("#{PFZY_220915_31}") --活动按钮
	FightScoreFrame_List2_Text:SetText("")  --标题下方
	FightScore_AddRightUnderArmourPageElement()
end

function FightScore_AddRightUnderArmourPageElement()
	
	local strTemp = ""
	for i = 1, 3 do
		local ItemBar = FightScore_AddRightChildElement()
		--	先设置好底图
		local itemButton = ItemBar:GetLuaActionButton(1, "FightScore")		

		local nRate = 0
		local iActive = DataPool:LuaFnGetUnderArmourData(i - 1, "ACTIVED")
		
		if iActive == 1 then
			itemButton:SetEvent("MouseEnter", string.format("FightScore_UnderArmourMouseEnter(%d)", i))
			itemButton:SetEvent("MouseLeave", string.format("FightScore_UnderArmourMouseLeave(%d)", i))
			
			nRate = math.floor(g_FightScore_UnderArmourScore[i]/g_UnderArmour_STL[g_ScoreBaseParam].ua_stl*100)
			
			local iRank = DataPool:LuaFnGetUnderArmourData(i - 1, "RANK")
			local iLevel = DataPool:LuaFnGetUnderArmourData(i - 1, "LEVEL")
			local iStar = DataPool:LuaFnGetUnderArmourData(i - 1, "STAR")
			
			local strIcon = DataPool:LuaFnGetUnderArmourInfo(i - 1, "ICON", iRank)
			local strIconImage = GetIconFullName(tostring(strIcon))
			itemButton:SetProperty("BackImage", tostring(strIconImage))

			if nRate < 100 then
				if iRank == 5 then
					strTemp = ScriptGlobal_Format("#{PFZY_220915_34}", tostring(iStar))
				else
					strTemp = ScriptGlobal_Format("#{PFZY_220915_05}", tostring(g_UA_Rank_Name[iRank + 1]), tostring(iLevel), tostring(iStar))
				end
				ItemBar:Setm_newText(18, strTemp)
				ItemBar:Setm_newTextShow(18)
				strTemp = ScriptGlobal_Format("#{PFZY_220915_06}", g_UnderArmour_Recommand[g_ScoreBaseParam].ua_rank, tostring(g_UnderArmour_Recommand[g_ScoreBaseParam].ua_star))
				ItemBar:Setm_newText(19, strTemp)
				ItemBar:Setm_newTextShow(19)
			else
				if iRank == 5 then
					strTemp = ScriptGlobal_Format("#{PFZY_220915_33}", tostring(iStar))
				else
					strTemp = ScriptGlobal_Format("#{PFZY_220915_13}", tostring(g_UA_Rank_Name[iRank + 1]), tostring(iLevel), tostring(iStar))
				end
				ItemBar:Setm_newText(17, strTemp)
				ItemBar:Setm_newTextShow(17)
			end
		else
			local strIcon = DataPool:LuaFnGetUnderArmourInfo(i - 1, "LOCKICON")
			local strIconImage = GetIconFullName(tostring(strIcon))
			itemButton:SetProperty("BackImage", tostring(strIconImage))

			itemButton:SetToolTip("#{PFZY_220915_03}")
			ItemBar:Setm_newText(17, "#{PFZY_220915_04}")
			ItemBar:Setm_newTextShow(17)
		end
		
		FightScore_SetRightElementStarNum(nRate, ItemBar, 0)		
		table.insert(g_myRightButton, ItemBar)
	end
	
	for i = 1, 3 do
		local ItemBar = FightScore_AddRightChildElement()
		--	先设置好底图
		local itemButton = ItemBar:GetLuaActionButton(1, "FightScore")
		itemButton:SetProperty("BackImage", "")
		
		local nRate = 0
		local iActive = DataPool:LuaFnGetUnderArmourData(i - 1, "ACTIVED")
		local iJewel = DataPool:LuaFnGetUnderArmourData(i - 1, "JEWEL")
		if iActive == 1 and tonumber(iJewel) ~= nil and iJewel > 0 then
			local itemAction = EnumAction(i - 1, "UnderArmourJewel")
			itemButton:SetActionItem(itemAction:GetID())
			
			nRate = math.floor(g_FightScore_UnderArmourJewelScore[i]/g_UnderArmour_STL[g_ScoreBaseParam].jewel_stl*100)
			
			local iJewelLevel = DataPool:LuaFnGetUnderArmourData(i - 1, "JEWEL_LEVEL")
			local iQual = DataPool:LuaFnGetUnderArmourJewelQual(tonumber(iJewel))
			
			local qual_str = "#{PFZY_220915_18}"
			if iQual == 1 then
				qual_str = "#{PFZY_220915_19}"
			end

			if nRate < 100 then
				strTemp = ScriptGlobal_Format("#{PFZY_220915_16}", qual_str, tostring(iJewelLevel + 1))
				ItemBar:Setm_newText(18, strTemp)
				ItemBar:Setm_newTextShow(18)
				strTemp = ScriptGlobal_Format("#{PFZY_220915_17}", g_UnderArmour_Recommand[g_ScoreBaseParam].jewel_qual, tostring(g_UnderArmour_Recommand[g_ScoreBaseParam].jewel_level))
				ItemBar:Setm_newText(19, strTemp)
				ItemBar:Setm_newTextShow(19)
		else
				strTemp = ScriptGlobal_Format("#{PFZY_220915_20}", qual_str, tostring(iJewelLevel + 1))
				ItemBar:Setm_newText(17, strTemp)
				ItemBar:Setm_newTextShow(17)
			end
		else
			itemButton:SetToolTip("#{PFZY_220915_14}")
			ItemBar:Setm_newText(17, "#{PFZY_220915_15}")
			ItemBar:Setm_newTextShow(17)
		end
		
		FightScore_SetRightElementStarNum(nRate, ItemBar, 0)		
		table.insert(g_myRightButton, ItemBar)
	end

	for i = 1, 3 do		
		if g_UnderArmour_STL[g_ScoreBaseParam].plate_stl > 0 then
			local ItemBar = FightScore_AddRightChildElement()
			--	先设置好底图
			local itemButton = ItemBar:GetLuaActionButton(1, "FightScore")
			itemButton:SetProperty("BackImage", "")
			
			local nRate = 0
			local iActive = DataPool:LuaFnGetUnderArmourData(i - 1, "ACTIVED")
			local iJewel = DataPool:LuaFnGetUnderArmourData(i - 1, "JEWEL")
			if iActive == 1 and tonumber(iJewel) ~= nil and iJewel > 0 then			
				local iPlate = DataPool:LuaFnGetUnderArmourData(i - 1, "PLATE")
				if tonumber(iPlate) ~= nil and tonumber(iPlate) > 0 then
					local iPlateLevel = DataPool:LuaFnGetUnderArmourData(i - 1, "PLATE_LEVEL")
					local itemAction = EnumAction(i - 1, "UnderArmourJewel")
					itemButton:SetActionItem(itemAction:GetID())

					nRate = math.floor(g_FightScore_UnderArmourPlateScore[i]/g_UnderArmour_STL[g_ScoreBaseParam].plate_stl*100)
					
					if nRate < 100 then
						strTemp = ScriptGlobal_Format("#{PFZY_220915_25}", tostring(iPlateLevel + 1))
						ItemBar:Setm_newText(18, strTemp)
						ItemBar:Setm_newTextShow(18)
						strTemp = ScriptGlobal_Format("#{PFZY_220915_26}", tostring(g_UnderArmour_Recommand[g_ScoreBaseParam].plate_level))
						ItemBar:Setm_newText(19, strTemp)
						ItemBar:Setm_newTextShow(19)
					else
						strTemp = ScriptGlobal_Format("#{PFZY_220915_27}", tostring(iPlateLevel + 1))
						ItemBar:Setm_newText(17, strTemp)
						ItemBar:Setm_newTextShow(17)
					end
				else
					local strIcon = DataPool:LuaFnGetItemIconByTableIndex(tonumber(iJewel))
					local strIconImage = GetIconFullName(strIcon)
					itemButton:SetProperty("BackImage", strIconImage)
					itemButton:SetToolTip("#{PFZY_220915_21}")
					ItemBar:Setm_newText(1, "#{PFZY_220915_22}")
				end
			else
				itemButton:SetToolTip("#{PFZY_220915_21}")
				ItemBar:Setm_newText(17, "#{PFZY_220915_22}")
				ItemBar:Setm_newTextShow(17)
			end
			
			FightScore_SetRightElementStarNum(nRate, ItemBar, 0)		
			table.insert(g_myRightButton, ItemBar)
		end
	end

	g_FightScoreRightList:Flash()
end

function FightScore_UnderArmourMouseEnter(index)

	if g_myRightButton[index] == nil then
		return
	end

	local itemButton = g_myRightButton[index]:GetLuaActionButton(1, "FightScore")
	if itemButton == nil then
		return
	end

	local iActive = DataPool:LuaFnGetUnderArmourData(index - 1, "ACTIVED")
	if iActive ~= 1 then
		return
	end
	local fX, fY = itemButton:GetAbsolutePositionToScreen()
	local SetWidth = itemButton:GetProperty("AbsoluteWidth")
	local SetHeight = itemButton:GetProperty("AbsoluteHeight")
	LuaFnOpenUnderArmourTip(0, index, tonumber(fX), tonumber(fY), tonumber(SetWidth), tonumber(SetHeight))

end

function FightScore_UnderArmourMouseLeave(index)
	LuaFnCloseUnderArmourTip(0, index)
end

local g_ZongMenEquipLevelStr = {
	"#{PFZY_230830_08}",
	"#{PFZY_230830_09}",
	"#{PFZY_230830_10}",
	"#{PFZY_230830_11}",
	"#{PFZY_230830_12}",
}

local g_ZongMenEquip_Recommand = {
	[3] = {equip_level = 5},
	[4] = {equip_level = 5},
	[5] = {equip_level = 5},
	[6] = {equip_level = 5},
	[7] = {equip_level = 5},
	[8] = {equip_level = 5},
}

function FightScore_CalcZongMenEquipScore()
	local iZongMenEquipScore = 0
	local iZongMenEquipScore_STL = 5

	if DataPool:LuaFnIsEquipZMXW() == 1 then
		local item_table_index = DataPool:LuaFnGetEquipItemTableIndex(23)
		local equip_level = DataPool:LuaFnGetZMXWInfo(tonumber(item_table_index), "LEVEL")
		iZongMenEquipScore = equip_level
	end

	g_FightScore_ZongMenEquipTotalScore = math.floor(iZongMenEquipScore/iZongMenEquipScore_STL*100)
end

function FightScore_ZongMenEquipPageUpdate()

	FightScore_CleanRightActionItemInfo() 				--先清空
	g_FightScoreRightList:CleanAllElement("FightScore")	--先清空
	
	FightScoreFrame_List2_Title_Text:SetText("#{PFZY_230830_01}") --设置标题
	
	if DataPool:Lua_IsMissionHaveDone(3022) ~= 1 then
		FightScoreFrame_Lace2_WYFY_Button:Show() --武林风云按钮
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_230830_13}#{PFZY_230830_14}") --设置下方内容
	else
		FightScoreFrame_Lace2_WYFY_Button:Hide() --武林风云按钮
		FightScoreFrame_Lace2_Text:SetText("#{PFZY_230830_14}") --设置下方内容
	end
	FightScoreFrame_Lace2_WYFY_Button:SetToolTip("#{PFZY_230830_15}")
	FightScoreFrame_Lace2_Shop_Button:SetToolTip("") --商城按钮
	FightScoreFrame_Lace2_HD_Button:SetToolTip("") --活动按钮
	FightScoreFrame_List2_Text:SetText("")  --标题下方
	FightScore_AddRightZongMenEquipPageElement()
end

function FightScore_AddRightZongMenEquipPageElement()
	
	local strTemp = ""
	local nRate = 0
	local ItemBar = FightScore_AddRightChildElement()
	--	先设置好底图
	local itemButton = ItemBar:GetLuaActionButton(1, "FightScore")		
	itemButton:SetProperty("BackImage", "set:ZongMenSkill image:ZongMenSkill_ItemBK")
	
	if DataPool:LuaFnIsEquipZMXW() == 1 then
		local ActionEquip = EnumAction(23, "equip")		
		itemButton:SetActionItem(ActionEquip:GetID())
		
		local item_table_index = DataPool:LuaFnGetEquipItemTableIndex(23)
		local equip_level = DataPool:LuaFnGetZMXWInfo(tonumber(item_table_index), "LEVEL")
		
		nRate = math.floor(g_FightScore_ZongMenEquipTotalScore/100*100)

		if nRate < 100 then
			strTemp = ScriptGlobal_Format("#{PFZY_230830_04}", tostring(g_ZongMenEquipLevelStr[equip_level]))
			ItemBar:Setm_newText(18, strTemp)
			ItemBar:Setm_newTextShow(18)
			strTemp = ScriptGlobal_Format("#{PFZY_230830_18}", tostring(g_ZongMenEquipLevelStr[g_ZongMenEquip_Recommand[g_ScoreBaseParam].equip_level]))
			ItemBar:Setm_newText(19, strTemp)
			ItemBar:Setm_newTextShow(19)
		else
			strTemp = ScriptGlobal_Format("#{PFZY_230830_04}", tostring(g_ZongMenEquipLevelStr[equip_level]))
			ItemBar:Setm_newText(17, strTemp)
			ItemBar:Setm_newTextShow(17)
		end
		
		FightScore_SetRightElementStarNum(nRate, ItemBar, 1)
	else
		ItemBar:Setm_newText(1, "#{PFZY_230830_03}")
		ItemBar:Setm_newTextShow(1)
	end

	
	table.insert(g_myRightButton, ItemBar)
	
	g_FightScoreRightList:Flash()
end