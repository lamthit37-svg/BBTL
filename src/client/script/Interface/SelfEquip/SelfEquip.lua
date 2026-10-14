-- 数据池中定义的装备数据.
--HEQUIP_WEAPON		=0,		//武器	WEAPON
--HEQUIP_CAP			=1,		//帽子	DEFENCE
--HEQUIP_ARMOR		=2,		//衣服	DEFENCE
--HEQUIP_CUFF			=3,		//护腕	DEFENCE
--HEQUIP_BOOT			=4,		//鞋	DEFENCE
--HEQUIP_SASH			=5,		//腰带	ADORN
--HEQUIP_RING			=6,		//戒指	ADORN
--HEQUIP_NECKLACE	=7,		//项链	ADORN
--HEQUIP_RIDER		=8,		//暗器	ADORN
--HEQUIP_BAG			=9,		//行囊
--HEQUIP_BOX			=10,	//箱格
--HEQUIP_RING_2		=11,	//第二个戒指	ADORN
--HEQUIP_CHARM		=12,	//护符				ADORN
--HEQUIP_CHARM_2	=13,	//第二个护符	ADORN
--HEQUIP_WRIST		=14,	//护腕				ADORN
--HEQUIP_SHOULDER	=15,	//护肩				DEFENCE
--HEQUIP_DRESS		=16,	//时装				DEFENCE
--HEQUIP_RESERVE	=17,	//预留1
--HEQUIP_RESERVE_2=18,	//预留2


--------------------------------------------------------------------------------
-- 装备按钮数据定义
--
local  g_WEAPON;		--武器
local  g_ARMOR;			--衣服
local  g_CAP;				--帽子
local  g_CUFF;			--手套
local  g_BOOT;			--鞋
local  g_RING;			--戒指
local  g_SASH;			--腰带
local  g_NECKLACE;	--项链
local  g_Dark;			--暗器
local  g_RING_2;		--戒指2
local  g_CHARM;			--护符
local  g_CHARM_2;		--护符2
local  g_WRIST;			--护腕
local  g_SHOULDER;	--护肩
local  g_LONGWEN;			--龙纹
local  g_RL;			--符石传说

local  g_EquipMask ={}
---------------------------------------------------------------------------------
-- 点数定义
--

local g_RemainPoint 			= 0;	-- 剩余点数
local g_CurExperience 	  = 0;	-- 当前剩余经验
local g_RequireExperience = 0;  -- 升级所需经验

local g_AddStr = 0;					-- 分配在力量上的剩余点数.
local g_AddSpr = 0;					-- 分配在灵气上的剩余点数.
local g_AddCon = 0;					-- 分配在体质上的剩余点数.
local g_AddInt = 0;					-- 分配在定力上的剩余点数.
local g_AddDex = 0;					-- 分配在身法上的剩余点数.

local g_CurRemainPoint = 0;				-- 分配后的剩余点数

-- 是否打开称号界面
local g_bOpenTitleDlg = 0;
local SELFEQUIP_TAB_TEXT = {};
--modify by guochenshu for:82982
--local LEVEL_MAX_ENABLE =149;	--最大允许等级
local LEVEL_MAX_ENABLE =129;	--目前允许的最高级为129
local SEFFEQUIP_MAX_STORAGEEXP_2606S=2000000000


local g_PropertyTable = {}

local g_XiulianTipTable = {"#{XL_XML_90}","#{XL_XML_91}","#{XL_XML_92}","#{XL_XML_93}","#{XL_XML_94}"
							,"#{XL_XML_95}","#{XL_XML_96}","#{XL_XML_97}","#{XL_XML_98}","#{XL_XML_99}"
							,"#{XL_XML_100}"}

local g_SelfEquip_Gem_Check_Buttons_red   = {}  --- 不能进行一键换宝石
local g_SelfEquip_Gem_Check_Buttons_green = {}  --- 可以进行一键换宝石
local g_SelfEquip_Gem_Check_Buttons_BK    = {}  --- 没有学会一键换宝石的时候，显示的背景
local g_SelfEquip_Gem_Contain_Num   = 16
--------------------------------------------
-- 提供长按左键进行连加的功能	-- HenryFour@2010-04-16
local g_AutoClick_BtnFlag = -1			-- 记录当前鼠标左键是在哪个按钮按下
local g_AutoClickTimer_Step = 100		-- 多少时间(毫秒)模拟一次 Click 操作
local g_AutoClick_FunList = {}			-- 将公用一个 Timer 的回调功能函数放到一个数组
local g_AutoClick_Going = -1			-- 标志是否开始自动点击操作(第一次LButton后经过X个Timer才算开始, 也就是说是 g_AutoClickTimer_Step * X 的时候开始进行自动加, 这样为了防止本来要点击一下的结果点了好多下)

local g_SelfEquip_LevelLock_IsSetTimer = 0;

--界面的相对位置
local g_SelfEquip_Frame_UnifiedXPosition;
local g_SelfEquip_Frame_UnifiedYPosition;

local g_NeedTipID = -1
local g_NeedTipText = -1
local g_CurActFlashType = 0
local g_ShowLevelUp = 0

local g_CurSelInfantIndex = 0;			--当前招出的孩子再客户端的index

local m_EnchanceLevel =  { 360 , 480 , 600 , 720}

local m_ZhiZunAnimate = {}

local 	g_ElementsValueName = {

	[ 1 ] = {
		"#{ZZZB_150811_166}",
		"#{ZZZB_150811_167}",
		"#{ZZZB_150811_168}",
		"#{ZZZB_150811_169}",
	},

	[ 2 ] = {
		"#{ZZZB_150811_172}",
		"#{ZZZB_150811_173}",
		"#{ZZZB_150811_174}",
		"#{ZZZB_150811_175}",
		"#{ZZZB_150811_176}",
		"#{ZZZB_150811_177}",
		"#{ZZZB_150811_178}",
		"#{ZZZB_150811_179}",
	},

	[ 3 ] = {
		"#{ZYYH_120824_19}",
	},

	[ 4 ] = {
		"#{ZZZB_150811_182}",
		"#{ZZZB_150811_183}",
	},

	[ 5 ] = {
		"#{ZYYH_120824_18}",
	},

}

local g_SelfEquip_BW_Level = 
{
[0] = { name= "#{BWDH_210908_01}"},
[1] = { name= "#{BWDH_180804_13}"},
[2] = { name= "#{BWDH_180804_14}"},
[3] = { name= "#{BWDH_250113_06}"},
}

local g_SelfEquip_BW_Image =
{
[0] = 
	{
		[1] = {HoverImage="set:BW_Match20 image:que1_Hover", NormalImage="set:BW_Match20 image:que1_Normal", PushedImage="set:BW_Match20 image:que1_Pushed",},
		[2] = {HoverImage="set:BW_Match20 image:que2_Hover", NormalImage="set:BW_Match20 image:que2_Normal", PushedImage="set:BW_Match20 image:que2_Pushed",},
		[3] = {HoverImage="set:BW_Match20 image:que3_Hover", NormalImage="set:BW_Match20 image:que3_Normal", PushedImage="set:BW_Match20 image:que3_Pushed",},
		[4] = {HoverImage="set:BW_Match20 image:que4_Hover", NormalImage="set:BW_Match20 image:que4_Normal", PushedImage="set:BW_Match20 image:que4_Pushed",},
		[5] = {HoverImage="set:BW_Match20 image:que5_Hover", NormalImage="set:BW_Match20 image:que5_Normal", PushedImage="set:BW_Match20 image:que5_Pushed",},
--		[6] = {HoverImage="set:BW_Match20 image:que6_Hover", NormalImage="set:BW_Match20 image:que6_Normal", PushedImage="set:BW_Match20 image:que6_Pushed",},
		[6] = {HoverImage="set:BW_Match20 image:que7_Hover", NormalImage="set:BW_Match20 image:que7_Normal", PushedImage="set:BW_Match20 image:que7_Pushed",},
	},
[1] = 
	{
		[1] = {HoverImage="set:BW_Match1 image:Eagle01_Hover", NormalImage="set:BW_Match1 image:Eagle01_Normal", PushedImage="set:BW_Match1 image:Eagle01_Pushed",},
		[2] = {HoverImage="set:BW_Match2 image:Eagle02_Hover", NormalImage="set:BW_Match2 image:Eagle02_Normal", PushedImage="set:BW_Match2 image:Eagle02_Pushed",},
		[3] = {HoverImage="set:BW_Match2 image:Eagle03_Hover", NormalImage="set:BW_Match2 image:Eagle03_Normal", PushedImage="set:BW_Match2 image:Eagle03_Pushed",},
		[4] = {HoverImage="set:BW_Match2 image:Eagle04_Hover", NormalImage="set:BW_Match2 image:Eagle04_Normal", PushedImage="set:BW_Match2 image:Eagle04_Pushed",},
		[5] = {HoverImage="set:BW_Match2 image:Eagle05_Hover", NormalImage="set:BW_Match2 image:Eagle05_Normal", PushedImage="set:BW_Match2 image:Eagle05_Pushed",},
--		[6] = {HoverImage="set:BW_Match2 image:Eagle06_Hover", NormalImage="set:BW_Match2 image:Eagle06_Normal", PushedImage="set:BW_Match2 image:Eagle06_Pushed",},
		[6] = {HoverImage="set:BW_Match2 image:Eagle07_Hover", NormalImage="set:BW_Match2 image:Eagle07_Normal", PushedImage="set:BW_Match2 image:Eagle07_Pushed",},
	},
	
[2] = 
	{
		[1] = {HoverImage="set:BW_Match1 image:Dragon01_Hover", NormalImage="set:BW_Match1 image:Dragon01_Normal", PushedImage="set:BW_Match1 image:Dragon01_Pushed",},
		[2] = {HoverImage="set:BW_Match1 image:Dragon02_Hover", NormalImage="set:BW_Match1 image:Dragon02_Normal", PushedImage="set:BW_Match1 image:Dragon02_Pushed",},
		[3] = {HoverImage="set:BW_Match1 image:Dragon03_Hover", NormalImage="set:BW_Match1 image:Dragon03_Normal", PushedImage="set:BW_Match1 image:Dragon03_Pushed",},
		[4] = {HoverImage="set:BW_Match1 image:Dragon04_Hover", NormalImage="set:BW_Match1 image:Dragon04_Normal", PushedImage="set:BW_Match1 image:Dragon04_Pushed",},
		[5] = {HoverImage="set:BW_Match1 image:Dragon05_Hover", NormalImage="set:BW_Match1 image:Dragon05_Normal", PushedImage="set:BW_Match1 image:Dragon05_Pushed",},
--		[6] = {HoverImage="set:BW_Match1 image:Dragon06_Hover", NormalImage="set:BW_Match1 image:Dragon06_Normal", PushedImage="set:BW_Match1 image:Dragon06_Pushed",},
		[6] = {HoverImage="set:BW_Match1 image:Dragon07_Hover", NormalImage="set:BW_Match1 image:Dragon07_Normal", PushedImage="set:BW_Match1 image:Dragon07_Pushed",},
	},
[3] =
	{
		[1] = {HoverImage="set:BW_Match21 image:Kun01_Hover", NormalImage="set:BW_Match21 image:Kun01_Normal", PushedImage="set:BW_Match21 image:Kun01_Pushed",},
		[2] = {HoverImage="set:BW_Match21 image:Kun02_Hover", NormalImage="set:BW_Match21 image:Kun02_Normal", PushedImage="set:BW_Match21 image:Kun02_Pushed",},
		[3] = {HoverImage="set:BW_Match21 image:Kun03_Hover", NormalImage="set:BW_Match21 image:Kun03_Normal", PushedImage="set:BW_Match21 image:Kun03_Pushed",},
		[4] = {HoverImage="set:BW_Match21 image:Kun04_Hover", NormalImage="set:BW_Match21 image:Kun04_Normal", PushedImage="set:BW_Match21 image:Kun04_Pushed",},
		[5] = {HoverImage="set:BW_Match21 image:Kun05_Hover", NormalImage="set:BW_Match21 image:Kun05_Normal", PushedImage="set:BW_Match21 image:Kun05_Pushed",},
--		[6] = {HoverImage="set:BW_Match21 image:Kun06_Hover", NormalImage="set:BW_Match21 image:Kun06_Normal", PushedImage="set:BW_Match21 image:Kun06_Pushed",},
		[6] = {HoverImage="set:BW_Match21 image:Kun07_Hover", NormalImage="set:BW_Match21 image:Kun07_Normal", PushedImage="set:BW_Match21 image:Kun07_Pushed",},
	},	
}

local g_SelfEquip_BW_Dw1_Name = 
{
[1] = "#{BWDH_180804_131}",
[2] = "#{BWDH_180804_132}",
[3] = "#{BWDH_180804_133}",
[4] = "#{BWDH_180804_134}",
[5] = "#{BWDH_180804_135}",
[6] = "#{BWDH_180804_136}",
}

local g_SelfEquip_BW_Dw2_Name = 
{
[1] = "#{BWDH_180804_141}",
[2] = "#{BWDH_180804_140}",
[3] = "#{BWDH_180804_139}",
[4] = "#{BWDH_180804_138}",
[5] = "#{BWDH_180804_137}",
}

local g_SelfEquip_BW_Dw2_NameYellow = 
{
[1] = "#{BWDH_180804_175}",
[2] = "#{BWDH_180804_174}",
[3] = "#{BWDH_180804_173}",
[4] = "#{BWDH_180804_172}",
[5] = "#{BWDH_180804_171}",
}

local g_SelfEquip_PrettyImage =
{
    [1] = {"set:Pretty01 image:Normal_1","set:Pretty01 image:Pushed_1","set:Pretty01 image:Hover_1"},
    [2] = {"set:Pretty01 image:Normal_2","set:Pretty01 image:Pushed_2","set:Pretty01 image:Hover_2"},
    [3] = {"set:Pretty01 image:Normal_3","set:Pretty01 image:Pushed_3","set:Pretty01 image:Hover_3"},
    [4] = {"set:Pretty01 image:Normal_4","set:Pretty01 image:Pushed_4","set:Pretty01 image:Hover_4"},
    [5] = {"set:Pretty01 image:Normal_5","set:Pretty01 image:Pushed_5","set:Pretty01 image:Hover_5"},
    [6] = {"set:Pretty01 image:Normal_6","set:Pretty01 image:Pushed_6","set:Pretty01 image:Hover_6"},
    [7] = {"set:Pretty01 image:Normal_7","set:Pretty01 image:Pushed_7","set:Pretty01 image:Hover_7"},
    [8] = {"set:Pretty01 image:Normal_8","set:Pretty01 image:Pushed_8","set:Pretty01 image:Hover_8"},
    [9] = {"set:Pretty01 image:Normal_9","set:Pretty01 image:Pushed_9","set:Pretty01 image:Hover_9"},
    [10] = {"set:Pretty01 image:Normal_10","set:Pretty01 image:Pushed_10","set:Pretty01 image:Hover_10"},
	[11] = {"set:Pretty01 image:Normal_11","set:Pretty01 image:Pushed_11","set:Pretty01 image:Hover_11"},
}

local g_SelfEquip_SectTitleLevel = 
{
	[0] = { tips = "#{TXYZ_230710_33}", image = "set:SectTitle image:SectTitle_M0_Normal", push = "set:SectTitle image:SectTitle_M0_Pushed", hover = "set:SectTitle image:SectTitle_M0_Hover" },
	[1] = { tips = "#{TXYZ_230710_03}", image = "set:SectTitle image:SectTitle_M1_Normal", push = "set:SectTitle image:SectTitle_M1_Pushed", hover = "set:SectTitle image:SectTitle_M1_Hover" },
	[2] = { tips = "#{TXYZ_230710_04}", image = "set:SectTitle image:SectTitle_M2_Normal", push = "set:SectTitle image:SectTitle_M2_Pushed", hover = "set:SectTitle image:SectTitle_M2_Hover" },
	[3] = { tips = "#{TXYZ_230710_05}", image = "set:SectTitle image:SectTitle_M3_Normal", push = "set:SectTitle image:SectTitle_M3_Pushed", hover = "set:SectTitle image:SectTitle_M3_Hover" },
	[4] = { tips = "#{TXYZ_230710_06}", image = "set:SectTitle image:SectTitle_M4_Normal", push = "set:SectTitle image:SectTitle_M4_Pushed", hover = "set:SectTitle image:SectTitle_M4_Hover" },
	[5] = { tips = "#{TXYZ_230710_07}", image = "set:SectTitle image:SectTitle_M5_Normal", push = "set:SectTitle image:SectTitle_M5_Pushed", hover = "set:SectTitle image:SectTitle_M5_Hover" },
	[6] = { tips = "#{TXYZ_230710_09}", image = "set:SectTitle image:SectTitle_M6_Normal", push = "set:SectTitle image:SectTitle_M6_Pushed", hover = "set:SectTitle image:SectTitle_M6_Hover" },
	[7] = { tips = "#{TXYZ_230710_10}", image = "set:SectTitle image:SectTitle_M7_Normal", push = "set:SectTitle image:SectTitle_M7_Pushed", hover = "set:SectTitle image:SectTitle_M7_Hover" },
	[8] = { tips = "#{TXYZ_230710_11}", image = "set:SectTitle image:SectTitle_M8_Normal", push = "set:SectTitle image:SectTitle_M8_Pushed", hover = "set:SectTitle image:SectTitle_M8_Hover" },
	[9] = { tips = "#{TXYZ_230710_12}", image = "set:SectTitle image:SectTitle_M9_Normal", push = "set:SectTitle image:SectTitle_M9_Pushed", hover = "set:SectTitle image:SectTitle_M9_Hover" },
	[10] = { tips = "#{TXYZ_230710_13}", image = "set:SectTitle image:SectTitle_M10_Normal", push = "set:SectTitle image:SectTitle_M10_Pushed", hover = "set:SectTitle image:SectTitle_M10_Hover" },
	[11] = { tips = "#{TXYZ_230710_23}", image = "set:SectTitle image:SectTitle_M11_Normal", push = "set:SectTitle image:SectTitle_M11_Pushed", hover = "set:SectTitle image:SectTitle_M11_Hover" },
	[12] = { tips = "#{TXYZ_230710_24}", image = "set:SectTitle image:SectTitle_M12_Normal", push = "set:SectTitle image:SectTitle_M12_Pushed", hover = "set:SectTitle image:SectTitle_M12_Hover" },
	[13] = { tips = "#{TXYZ_230710_25}", image = "set:SectTitle image:SectTitle_M13_Normal", push = "set:SectTitle image:SectTitle_M13_Pushed", hover = "set:SectTitle image:SectTitle_M13_Hover" },
	[14] = { tips = "#{TXYZ_230710_26}", image = "set:SectTitle image:SectTitle_M14_Normal", push = "set:SectTitle image:SectTitle_M14_Pushed", hover = "set:SectTitle image:SectTitle_M14_Hover" },
	[15] = { tips = "#{TXYZ_230710_27}", image = "set:SectTitle image:SectTitle_M15_Normal", push = "set:SectTitle image:SectTitle_M15_Pushed", hover = "set:SectTitle image:SectTitle_M15_Hover" },
	[16] = { tips = "#{TXYZ_230710_28}", image = "set:SectTitle image:SectTitle_M16_Normal", push = "set:SectTitle image:SectTitle_M16_Pushed", hover = "set:SectTitle image:SectTitle_M16_Hover" },
	[17] = { tips = "#{TXYZ_230710_29}", image = "set:SectTitle image:SectTitle_M17_Normal", push = "set:SectTitle image:SectTitle_M17_Pushed", hover = "set:SectTitle image:SectTitle_M17_Hover" },
	[18] = { tips = "#{TXYZ_230710_30}", image = "set:SectTitle image:SectTitle_M18_Normal", push = "set:SectTitle image:SectTitle_M18_Pushed", hover = "set:SectTitle image:SectTitle_M18_Hover" },
	[19] = { tips = "#{TXYZ_230710_31}", image = "set:SectTitle image:SectTitle_M19_Normal", push = "set:SectTitle image:SectTitle_M19_Pushed", hover = "set:SectTitle image:SectTitle_M19_Hover" },
	[20] = { tips = "#{TXYZ_230710_32}", image = "set:SectTitle image:SectTitle_M20_Normal", push = "set:SectTitle image:SectTitle_M20_Pushed", hover = "set:SectTitle image:SectTitle_M20_Hover" },
}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_SelfEquip_Page = {
	[1] = {Text = "#{INTERFACE_XML_877}",		NeedCheck = 0, Tip = ""},
	[2] = {Text = "#{INTERFACE_XML_882}",		NeedCheck = 0, Tip = ""},
	[3] = {Text = "#{INTERFACE_XML_854}",		NeedCheck = 0, Tip = ""},
	[4] = {Text = "#{ZNJCS_130825_7}",			NeedCheck = 0, Tip = "#{RWYQ_150707_01}"},
	[5] = {Text = "#{WH_xml_XX(95)}",			NeedCheck = 0, Tip = "#{RWYQ_150707_02}"},
	[6] = {Text = "#{XL_XML_35}",				NeedCheck = 0, Tip = "#{RWYQ_150707_03}"},
	[7] = {Text = "#{WLMJ_130121_54}",			NeedCheck = 0, Tip = "#{RWYQ_150707_04}"},
	[8] = {Text = "#{ZYXT_120528_154}",			NeedCheck = 0, Tip = "#{RWYQ_150707_05}"},
	[9] = {Text = "#{MPJJ_XT_XML_01}",  	 	NeedCheck = 0, Tip = "#{RWYQ_150707_06}"},
	[10] = {Text = "#{XLDL_140606_04}",			NeedCheck = 0, Tip = "#{RWYQ_150707_07}"},
	[11] = {Text = "#{JXJW_140822_22}",  	 	NeedCheck = 0, Tip = "#{RWYQ_150707_08}"},
	[12] = {Text = "#{ZZZB_150811_113}",		NeedCheck = 0, Tip = "#{ZZZB_150811_114}"},
	[13] = {Text = "#{WYXT_20170807_86}",		NeedCheck = 0, Tip = "#{WYXT_20170907_302}"},
	[14] = {Text = "#{JXSQ_170829_216}",		NeedCheck = 0, Tip = "#{JXSQ_170829_217}"},
	[15] = {Text = "#{NJBZ_220816_11}",			NeedCheck = 0, Tip = "#{NJBZ_220816_12}"},
	[16] = {Text = "#{CPSJ_260112_1}",			NeedCheck = 0, Tip = "#{CPSJ_260112_2}"},
	[17] = {Text = "#{INTERFACE_XML_496}",		NeedCheck = 0, Tip = ""},
}

local g_SelfEquip_PageButton = {}
local g_SelfEquip_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

local g_SelfEquip_2026 = {
	g_SelfEquip_25_UnifiedPosition,
	g_SelfEquip_16_UnifiedPosition,
	g_SelfEquip_BaoShiCheck_15_UnifiedPosition,
	g_SelfEquip_BaoShiCheck_16_UnifiedPosition,
}

function SelfEquip_PreLoad()
	-- 打开界面
	this:RegisterEvent("OPEN_EQUIP",true);

	-- 关闭界面
	this:RegisterEvent("CLOSE_EQUIP",false);

	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	-- 更新装备
	this:RegisterEvent("REFRESH_EQUIP",false);

	this:RegisterEvent("UNIT_HP",false);
	this:RegisterEvent("UNIT_MAX_HP",false);
	this:RegisterEvent("UNIT_MP",false);
	this:RegisterEvent("UNIT_MAX_MP",false);
	this:RegisterEvent("UNIT_RAGE",false);			-- 注册怒气
	this:RegisterEvent("UNIT_ENG",false);			-- 注册能量
	this:RegisterEvent("UNIT_MAX_ENG",false);			-- 注册能量

	this:RegisterEvent("UNIT_EXP",false);
	this:RegisterEvent("UNIT_LEVEL",false);
	this:RegisterEvent("UNIT_MAX_EXP",false);
	this:RegisterEvent("UNIT_STR",false);
	this:RegisterEvent("UNIT_SPR",false);
	this:RegisterEvent("UNIT_CON",false);
	this:RegisterEvent("UNIT_INT",false);
	this:RegisterEvent("UNIT_DEX",false);
	this:RegisterEvent("UNIT_POINT_REMAIN",false);
	this:RegisterEvent("UNIT_XIULIAN_STR",false);
	this:RegisterEvent("UNIT_XIULIAN_SPR",false);
	this:RegisterEvent("UNIT_XIULIAN_CON",false);
	this:RegisterEvent("UNIT_XIULIAN_INT",false);
	this:RegisterEvent("UNIT_XIULIAN_DEX",false);

	this:RegisterEvent("UNIT_ATT_PHYSICS",false);
	this:RegisterEvent("UNIT_ATT_MAGIC",false);
	this:RegisterEvent("UNIT_DEF_PHYSICS",false);
	this:RegisterEvent("UNIT_DEF_MAGIC",false);
	this:RegisterEvent("UNIT_HIT",false);
	this:RegisterEvent("UNIT_MISS",false);
	this:RegisterEvent("UNIT_CRITICAL_ATTACK",false);
	this:RegisterEvent("UNIT_CRITICAL_DEFENCE",false);
	this:RegisterEvent("CUR_TITLE_CHANGED",false); 		--当前称号改变
	this:RegisterEvent("UNIT_XIULIAN_ATT_PHYSICS",false);
	this:RegisterEvent("UNIT_XIULIAN_ATT_MAGIC",false);
	this:RegisterEvent("UNIT_XIULIAN_DEF_PHYSICS",false);
	this:RegisterEvent("UNIT_XIULIAN_DEF_MAGIC",false);
	this:RegisterEvent("UNIT_XIULIAN_HIT",false);
	this:RegisterEvent("UNIT_XIULIAN_MISS",false);

	this:RegisterEvent("UNIT_DEF_COLD",false);				--防御属性
	this:RegisterEvent("UNIT_DEF_FIRE",false);
	this:RegisterEvent("UNIT_DEF_LIGHT",false);
	this:RegisterEvent("UNIT_DEF_POSION",false);
	this:RegisterEvent("UNIT_MENPAI",false);

	this:RegisterEvent("UNIT_ATT_COLD",false);				--攻击属性
	this:RegisterEvent("UNIT_ATT_FIRE",false);
	this:RegisterEvent("UNIT_ATT_LIGHT",false);
	this:RegisterEvent("UNIT_ATT_POSION",false);

	this:RegisterEvent("UNIT_RESISTOTHER_COLD",false);			--减抗属性
	this:RegisterEvent("UNIT_RESISTOTHER_FIRE",false);
	this:RegisterEvent("UNIT_RESISTOTHER_LIGHT",false);
	this:RegisterEvent("UNIT_RESISTOTHER_POSION",false);

	this:RegisterEvent("UNIT_SUBRESISTLIMIT_COLD",false);			--减抗属性
	this:RegisterEvent("UNIT_SUBRESISTLIMIT_FIRE",false);
	this:RegisterEvent("UNIT_SUBRESISTLIMIT_LIGHT",false);
	this:RegisterEvent("UNIT_SUBRESISTLIMIT_POSION",false);

	this:RegisterEvent("UNIT_VIGOR",false);		-- 注册活力值
	this:RegisterEvent("UNIT_ENERGY",false);	-- 注册精力值


	this:RegisterEvent("GUILD_SHOW_MYGUILDNAME",false); --帮会信息更新


	-- 手动调整点数成功
	this:RegisterEvent("MANUAL_ATTR_SUCCESS_EQUIP",false);

	this:RegisterEvent("UPDATE_DUR",false);

	this:RegisterEvent("SEX_CHANGED",false);

	-- FakeObject模型界面互斥
	this:RegisterEvent("OPEN_YB_SHOP_FITTING",false)
	this:RegisterEvent("OPEN_SHOP_FITTING",false);						-- 元宝商店试衣间
	this:RegisterEvent("OPEN_DRESS_PAINT_FITTING",false);			-- 时装染色试衣间
	this:RegisterEvent("OPEN_DRESS_ENCHASE_FITTING",false);		-- 时装镶嵌试衣间
	this:RegisterEvent("UI_COMMAND",true);  --以及变性界面
    this:RegisterEvent("GEM_CONTAINER_REFRESH",false);
	this:RegisterEvent("ONOPENBIEYEFURCREATE",false)

	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
    this:RegisterEvent("NOTIFY_POP_UITIP",false)

  this:RegisterEvent("HUMAN_BATTLE_SCORE",false);		--战斗评分
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK",false);		--升级

	this:RegisterEvent("TOGGLE_UPDATE_INFANT",false); --子女有变化 刷新按钮状态

	this:RegisterEvent("FINISH_MISSION",false)
	this:RegisterEvent("FIVEELEMENTS_UPDATE",false)
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	
	this:RegisterEvent("FAKEOBJ_MYSELFEQUIP_CHANGE", false)
	this:RegisterEvent("FASHION_DEPOT_OP", false)
	this:RegisterEvent("FEIYUSHOW_WINDOW", false)
	this:RegisterEvent("OPEN_SPECIALDRESSPAINT", false)
	
	this:RegisterEvent("XBW_SELF_EQUIP_UPDATE_2018",false)
    this:RegisterEvent("UPDATE_REDPOINT_IN_UI",false)
  this:RegisterEvent("UPDATE_REDPOINT_IN_UI_EX",false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("UPDATE_EXTERIOR_TIP", false)
	this:RegisterEvent("UPDATE_WG_LEVEL", false)
	this:RegisterEvent("UPDATE_ZONGMENTITLELEVEL", false)
	
	this:RegisterEvent("CANGPIN_UPDATE", false)
end

function SelfEquip_OnLoad()

	-- action buttion 按钮
	g_WEAPON   = SelfEquip_11;		--武器
	g_ARMOR    = SelfEquip_12;		--衣服
	g_CAP      = SelfEquip_1;		--帽子
	g_CUFF     = SelfEquip_4;		--手套
	g_BOOT     = SelfEquip_6;		--鞋
	g_RING     = SelfEquip_7;		--戒指
	g_SASH     = SelfEquip_5;		--腰带
	g_NECKLACE = SelfEquip_13;		--项链
	g_Dark	   = SelfEquip_14;		--暗器
	g_RING_2	 = SelfEquip_8;		--戒指2
	g_CHARM		 = SelfEquip_9;		--护符
	g_CHARM_2	 = SelfEquip_10;		--护符2
	g_WRIST		 = SelfEquip_3;		--护腕
	g_SHOULDER = SelfEquip_2;		--护肩
	g_LONGWEN    = SelfEquip_25;		--龙纹
	g_RL					= SelfEquip_16;

	g_EquipMask[0]	= SelfEquip_11_Mask;
	g_EquipMask[1]	= SelfEquip_1_Mask;
	g_EquipMask[2]	= SelfEquip_12_Mask;
	g_EquipMask[3]	= SelfEquip_4_Mask;
	g_EquipMask[4]	= SelfEquip_6_Mask;
	g_EquipMask[5]	= SelfEquip_5_Mask;
	g_EquipMask[6]	= SelfEquip_7_Mask;
	g_EquipMask[7]	= SelfEquip_13_Mask;
	g_EquipMask[11]	= SelfEquip_8_Mask;
	g_EquipMask[12]	= SelfEquip_9_Mask;
	g_EquipMask[13]	= SelfEquip_10_Mask;
	g_EquipMask[14]	= SelfEquip_3_Mask;
	g_EquipMask[15]	= SelfEquip_2_Mask;
	g_EquipMask[17]	= SelfEquip_14_Mask;
	g_EquipMask[19]	= SelfEquip_25_Mask;
	g_EquipMask[20] =  SelfEquip_16_Mask;

    g_PropertyTable[1] = SelfEquip_Str_Plus;
    g_PropertyTable[2] = SelfEquip_Nimbus_Plus;
    g_PropertyTable[3] = SelfEquip_PhysicalStrength_Plus;
    g_PropertyTable[4] = SelfEquip_Stability_Plus;
    g_PropertyTable[5] = SelfEquip_Footwork_Plus;
    g_PropertyTable[6] = SelfEquip_Perporty1_Plus;
    g_PropertyTable[7] = SelfEquip_Perporty2_Plus;
    g_PropertyTable[8] = SelfEquip_Perporty3_Plus;
    g_PropertyTable[9] = SelfEquip_Perporty4_Plus;
    g_PropertyTable[10] = SelfEquip_Perporty7_Plus;
    g_PropertyTable[11] = SelfEquip_Perporty6_Plus;

	SELFEQUIP_TAB_TEXT = {
		[0] = "装备",
		"情缘",
		"珍兽",
		"骑乘",
		"经脉",
		"其他",
	};

	g_AutoClick_FunList[1] = SelfEquip_Add1_Click
	g_AutoClick_FunList[2] = SelfEquip_Add2_Click
	g_AutoClick_FunList[3] = SelfEquip_Add3_Click
	g_AutoClick_FunList[4] = SelfEquip_Add4_Click
	g_AutoClick_FunList[5] = SelfEquip_Add5_Click
	g_AutoClick_FunList[6] = SelfEquip_Dec1_Click
	g_AutoClick_FunList[7] = SelfEquip_Dec2_Click
	g_AutoClick_FunList[8] = SelfEquip_Dec3_Click
	g_AutoClick_FunList[9] = SelfEquip_Dec4_Click
	g_AutoClick_FunList[10] = SelfEquip_Dec5_Click

	g_AutoClick_Going = -1
	g_AutoClick_BtnFlag = -1

    --- 宝石装备位
    g_SelfEquip_Gem_Check_Buttons_red[1]  = SelfEquip_BaoShiCheck_11red
    g_SelfEquip_Gem_Check_Buttons_red[2]  = SelfEquip_BaoShiCheck_03red
    g_SelfEquip_Gem_Check_Buttons_red[3]  = SelfEquip_BaoShiCheck_07red
    g_SelfEquip_Gem_Check_Buttons_red[4]  = SelfEquip_BaoShiCheck_08red
    g_SelfEquip_Gem_Check_Buttons_red[5]  = SelfEquip_BaoShiCheck_09red
    g_SelfEquip_Gem_Check_Buttons_red[6]  = SelfEquip_BaoShiCheck_10red
    g_SelfEquip_Gem_Check_Buttons_red[7]  = SelfEquip_BaoShiCheck_12red
    g_SelfEquip_Gem_Check_Buttons_red[8]  = SelfEquip_BaoShiCheck_01red
    g_SelfEquip_Gem_Check_Buttons_red[9]  = SelfEquip_BaoShiCheck_02red
    g_SelfEquip_Gem_Check_Buttons_red[10] = SelfEquip_BaoShiCheck_04red
    g_SelfEquip_Gem_Check_Buttons_red[11] = SelfEquip_BaoShiCheck_05red
    g_SelfEquip_Gem_Check_Buttons_red[12] = SelfEquip_BaoShiCheck_06red
    g_SelfEquip_Gem_Check_Buttons_red[13] = SelfEquip_BaoShiCheck_13red
    g_SelfEquip_Gem_Check_Buttons_red[14] = SelfEquip_BaoShiCheck_14red
    g_SelfEquip_Gem_Check_Buttons_red[15] = SelfEquip_BaoShiCheck_15red
	g_SelfEquip_Gem_Check_Buttons_red[16] = SelfEquip_BaoShiCheck_16red

    g_SelfEquip_Gem_Check_Buttons_green[1]  = SelfEquip_BaoShiCheck_11green
    g_SelfEquip_Gem_Check_Buttons_green[2]  = SelfEquip_BaoShiCheck_03green
    g_SelfEquip_Gem_Check_Buttons_green[3]  = SelfEquip_BaoShiCheck_07green
    g_SelfEquip_Gem_Check_Buttons_green[4]  = SelfEquip_BaoShiCheck_08green
    g_SelfEquip_Gem_Check_Buttons_green[5]  = SelfEquip_BaoShiCheck_09green
    g_SelfEquip_Gem_Check_Buttons_green[6]  = SelfEquip_BaoShiCheck_10green
    g_SelfEquip_Gem_Check_Buttons_green[7]  = SelfEquip_BaoShiCheck_12green
    g_SelfEquip_Gem_Check_Buttons_green[8]  = SelfEquip_BaoShiCheck_01green
    g_SelfEquip_Gem_Check_Buttons_green[9]  = SelfEquip_BaoShiCheck_02green
    g_SelfEquip_Gem_Check_Buttons_green[10] = SelfEquip_BaoShiCheck_04green
    g_SelfEquip_Gem_Check_Buttons_green[11] = SelfEquip_BaoShiCheck_05green
    g_SelfEquip_Gem_Check_Buttons_green[12] = SelfEquip_BaoShiCheck_06green
    g_SelfEquip_Gem_Check_Buttons_green[13] = SelfEquip_BaoShiCheck_13green
    g_SelfEquip_Gem_Check_Buttons_green[14] = SelfEquip_BaoShiCheck_14green
    g_SelfEquip_Gem_Check_Buttons_green[15] = SelfEquip_BaoShiCheck_15green
	g_SelfEquip_Gem_Check_Buttons_green[16] = SelfEquip_BaoShiCheck_16green

    g_SelfEquip_Gem_Check_Buttons_BK[1]  = SelfEquip_BaoShiCheckBK1
    g_SelfEquip_Gem_Check_Buttons_BK[2]  = SelfEquip_BaoShiCheckBK2
    g_SelfEquip_Gem_Check_Buttons_BK[3]  = SelfEquip_BaoShiCheckBK3
    g_SelfEquip_Gem_Check_Buttons_BK[4]  = SelfEquip_BaoShiCheckBK4
    g_SelfEquip_Gem_Check_Buttons_BK[5]  = SelfEquip_BaoShiCheckBK5
    g_SelfEquip_Gem_Check_Buttons_BK[6]  = SelfEquip_BaoShiCheckBK6
    g_SelfEquip_Gem_Check_Buttons_BK[7]  = SelfEquip_BaoShiCheckBK7
    g_SelfEquip_Gem_Check_Buttons_BK[8]  = SelfEquip_BaoShiCheckBK8
    g_SelfEquip_Gem_Check_Buttons_BK[9]  = SelfEquip_BaoShiCheckBK9
    g_SelfEquip_Gem_Check_Buttons_BK[10] = SelfEquip_BaoShiCheckBK10
    g_SelfEquip_Gem_Check_Buttons_BK[11] = SelfEquip_BaoShiCheckBK11
    g_SelfEquip_Gem_Check_Buttons_BK[12] = SelfEquip_BaoShiCheckBK12
    g_SelfEquip_Gem_Check_Buttons_BK[13] = SelfEquip_BaoShiCheckBK13
    g_SelfEquip_Gem_Check_Buttons_BK[14] = SelfEquip_BaoShiCheckBK14
    g_SelfEquip_Gem_Check_Buttons_BK[15] = SelfEquip_BaoShiCheckBK15
	g_SelfEquip_Gem_Check_Buttons_BK[16] = SelfEquip_BaoShiCheckBK16

	g_SelfEquip_Frame_UnifiedXPosition = SelfEquip_Frame:GetProperty("UnifiedXPosition");
	g_SelfEquip_Frame_UnifiedYPosition = SelfEquip_Frame:GetProperty("UnifiedYPosition");

	m_ZhiZunAnimate[1]	= SelfEquip_1_Animate
	m_ZhiZunAnimate[2]	= SelfEquip_12_Animate
	m_ZhiZunAnimate[3]	= SelfEquip_4_Animate
	m_ZhiZunAnimate[4]	= SelfEquip_6_Animate
	m_ZhiZunAnimate[5]	= SelfEquip_5_Animate
	m_ZhiZunAnimate[6]	= SelfEquip_7_Animate
	m_ZhiZunAnimate[7]	= SelfEquip_13_Animate
	m_ZhiZunAnimate[11]	= SelfEquip_8_Animate
	m_ZhiZunAnimate[12]	= SelfEquip_9_Animate
	m_ZhiZunAnimate[13]	= SelfEquip_10_Animate
	m_ZhiZunAnimate[14]	= SelfEquip_3_Animate
	m_ZhiZunAnimate[15]	= SelfEquip_2_Animate

	g_SelfEquip_PageButton[1] = SelfEquip_SelfEquip
	g_SelfEquip_PageButton[2] = SelfEquip_SelfData
	g_SelfEquip_PageButton[3] = SelfEquip_Pet
	g_SelfEquip_PageButton[4] = SelfEquip_Infant
	g_SelfEquip_PageButton[5] = SelfEquip_Wuhun
	g_SelfEquip_PageButton[6] = SelfEquip_Xiulian
	g_SelfEquip_PageButton[7] = SelfEquip_Miji
	g_SelfEquip_PageButton[8] = SelfEquip_ZhenYuan
	g_SelfEquip_PageButton[9] = SelfEquip_JingMai
	g_SelfEquip_PageButton[10] = SelfEquip_ShenDing
	g_SelfEquip_PageButton[11] = SelfEquip_JunXian
	g_SelfEquip_PageButton[12] = SelfEquip_BaoJian
	g_SelfEquip_PageButton[13] = SelfEquip_WuYi
	g_SelfEquip_PageButton[14] = SelfEquip_ShenQi
	g_SelfEquip_PageButton[15] = SelfEquip_Armor
	g_SelfEquip_PageButton[16] = SelfEquip_CangPin
	g_SelfEquip_PageButton[17] = SelfEquip_OtherInfo
	
	g_SelfEquip_PageMask[1] = SelfEquip_SelfEquip_tips
	g_SelfEquip_PageMask[2] = SelfEquip_SelfData_tips
	g_SelfEquip_PageMask[3] = SelfEquip_Pet_tips
	g_SelfEquip_PageMask[4] = SelfEquip_Infant_tips
	g_SelfEquip_PageMask[5] = SelfEquip_Wuhun_tips
	g_SelfEquip_PageMask[6] = SelfEquip_Xiulian_tips
	g_SelfEquip_PageMask[7] = SelfEquip_Miji_tips
	g_SelfEquip_PageMask[8] = SelfEquip_ZhenYuan_tips
	g_SelfEquip_PageMask[9] = SelfEquip_JingMai_tips
	g_SelfEquip_PageMask[10] = SelfEquip_ShenDing_tips
	g_SelfEquip_PageMask[11] = SelfEquip_JunXian_tips
	g_SelfEquip_PageMask[12] = SelfEquip_BaoJian_tips
	g_SelfEquip_PageMask[13] = SelfEquip_WuYi_tips
	g_SelfEquip_PageMask[14] = SelfEquip_ShenQi_tips
	g_SelfEquip_PageMask[15] = SelfEquip_Armor_tips
	g_SelfEquip_PageMask[16] = SelfEquip_CangPin_tips
	g_SelfEquip_PageMask[17] = SelfEquip_OtherInfo_tips
		
	g_SelfEquip_2026.g_SelfEquip_25_UnifiedPosition = SelfEquip_25:GetProperty("UnifiedPosition")
	g_SelfEquip_2026.g_SelfEquip_16_UnifiedPosition = SelfEquip_16:GetProperty("UnifiedPosition")
	g_SelfEquip_2026.g_SelfEquip_BaoShiCheck_15_UnifiedPosition = SelfEquip_BaoShiCheck_15red:GetProperty("UnifiedPosition")
	g_SelfEquip_2026.g_SelfEquip_BaoShiCheck_16_UnifiedPosition = SelfEquip_BaoShiCheck_16red:GetProperty("UnifiedPosition")
	
	g_PageButtonTipsPos[1] = "{0.000000,28.000000}" 
	g_PageButtonTipsPos[2] = "{0.000000,64.000000}" 
	g_PageButtonTipsPos[3] = "{0.000000,100.000000}"
	g_PageButtonTipsPos[4] = "{0.000000,136.000000}"
	g_PageButtonTipsPos[5] = "{0.000000,172.000000}"
	g_PageButtonTipsPos[6] = "{0.000000,208.000000}"
	g_PageButtonTipsPos[7] = "{0.000000,244.000000}"
	g_PageButtonTipsPos[8] = "{0.000000,280.000000}"
	g_PageButtonTipsPos[9] = "{0.000000,316.000000}" 
	g_PageButtonTipsPos[10] = "{0.000000,352.000000}" 
	g_PageButtonTipsPos[11] = "{0.000000,388.000000}" 
	g_PageButtonTipsPos[12] = "{0.000000,424.000000}" 
	g_PageButtonTipsPos[13] = "{0.000000,460.000000}" 
	g_PageButtonTipsPos[14] = "{0.000000,496.000000}"
	g_PageButtonTipsPos[15] = "{0.000000,532.000000}"
	g_PageButtonTipsPos[16] = "{0.000000,568.000000}"
	g_PageButtonTipsPos[17] = "{0.000000,604.000000}"
	
end

-- OnEvent
function SelfEquip_OnEvent(event)

	-- 显示tooltip
	SelfEquip_SetStateTooltip();

	-- FakeObject模型界面互斥
	if ( event == "OPEN_SHOP_FITTING" ) or								-- 商店试衣间
		(event == "OPEN_YB_SHOP_FITTING") or							--元宝商店试衣间
		 ( event == "OPEN_DRESS_PAINT_FITTING" ) or					-- 时装染色试衣间
		 ( event == "OPEN_DRESS_ENCHASE_FITTING" ) or			-- 时装镶嵌试衣间
		 ( event == "UI_COMMAND" and tonumber(arg0) == 201411210 ) or --Add By YuanPeiLong 20141121 [子女变性丹设计]
		 ( event == "UI_COMMAND" and tonumber(arg0) == 20120406 ) or --变性
		 ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or --时装预览
		 ( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) or
		 (event == "FEIYUSHOW_WINDOW" and tonumber(arg0) >= 0) or
		 (event == "OPEN_SPECIALDRESSPAINT" and tonumber(arg0) >= 0) then
		if (this:IsVisible()) then
			SelfEquip_CloseUI();
			return
		end
	end
	if (event == "FASHION_DEPOT_OP" and tonumber(arg0) == 1) then
		local opType = tonumber(arg0)
		if opType == 1 then --打开界面
			if (this:IsVisible()) then
				SelfEquip_CloseUI();
				return
			end
		end
	end

	if(event == "MARTIAL_UPDATE"  or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		SelfEquip_RefreshWuYiTip()
		return
	end
	
	if ( event == "UPDATE_WILLGET_MISSION_TRACK" ) or (event=="TOGGLE_UPDATE_INFANT") or (event == "FINISH_MISSION") then
		local nLevel =Player:GetLevel()
		SelfEquip_Refresh_Page_Button(nLevel)
		SelfEquip_ShowPage()
	end

    if ( event == "GEM_CONTAINER_REFRESH" ) then
		Equip_RefreshEquip()
        return
    end

   if ( event == "UI_COMMAND" and tonumber(arg0) == 20150119) then
				local targetId = Get_XParam_INT(0)
				SelfEquip_Individuation_Clicked(targetId);
	 end
	 
	 if (event == "UI_COMMAND" and tonumber(arg0) == "80080102") then
		 SelfEquip_LevelupLock_Update();
		 return
	 end
	
	if (event == "UPDATE_ZONGMENTITLELEVEL") then
		if (this:IsVisible()) then	
			if Player:GetData("Is2606S") == 1 then	
				return 0
			end
			local sectLevel = Player:GetData("ZONEMENTITLELEVEL");
			local sectStr = g_SelfEquip_SectTitleLevel[0].tips
			local sectImg = g_SelfEquip_SectTitleLevel[0].image
			local sectPush = g_SelfEquip_SectTitleLevel[0].push
			local sectHover = g_SelfEquip_SectTitleLevel[0].hover
			if g_SelfEquip_SectTitleLevel[sectLevel].tips ~= nil then
				sectStr = g_SelfEquip_SectTitleLevel[sectLevel].tips
				sectImg = g_SelfEquip_SectTitleLevel[sectLevel].image
				sectPush = g_SelfEquip_SectTitleLevel[sectLevel].push
				sectHover = g_SelfEquip_SectTitleLevel[sectLevel].hover
			end
			
			local fixRate, expAdd, curState = LuaFnGetCurZongmenTitleInfo()	
	
			SelfEquip_SectTitle:SetToolTip(ScriptGlobal_Format("#{TXYZ_230710_02}",sectStr, expAdd, fixRate))

			SelfEquip_SectTitle:SetProperty("NormalImage", sectImg)
			SelfEquip_SectTitle:SetProperty("PushedImage", sectPush)
			SelfEquip_SectTitle:SetProperty("HoverImage", sectHover)		
		
			if curState == 1 then
				SelfEquip_SectTitle_tips:Show()
			else
				SelfEquip_SectTitle_tips:Hide()
			end		
		
			return
		end
	end	
	
	 if (event == "UI_COMMAND" and tonumber(arg0) == 99887901) then
		local fixRate, expAdd, curState = LuaFnGetCurZongmenTitleInfo()	
		if curState == 1 then
			SelfEquip_SectTitle_tips:Show()
		else
			SelfEquip_SectTitle_tips:Hide()
		end	
		if LuaFnGetZongMenSkillRedPoint() == 1 then
			SelfEquip_ZongMenSkill_IconTips:Show()
		else
			SelfEquip_ZongMenSkill_IconTips:Hide()
		end
		return
	 end
	 
	 if (event == "FAKEOBJ_MYSELFEQUIP_CHANGE") then
	 		SetFakeObjDataEx("Player")
	 end

	if ( event == "OPEN_EQUIP" ) then

		if(this:IsVisible()) then
			SelfEquip_CloseFunction();
			return;
		end
		if(IsWindowShow("SelectFacestyle")) then
			CloseWindow("SelectFacestyle", true);
		end
		if(IsWindowShow("SelectHairstyle")) then
			CloseWindow("SelectHairstyle", true);
		end
		if(IsWindowShow("SelectHairColor")) then
			CloseWindow("SelectHairColor", true);
		end
		PushEvent( "CLOSE_GEMEFFECTPREVIEW")
		SelfEquip_Open()

		SelfEquip_FakeObject:AttachWindowEx("Player");
		SetFakeObjDataEx("Player")
		
		local selfUnionPos = Variable:GetVariable("SelfUnionPos");
		if(selfUnionPos ~= nil) then
			SelfEquip_Frame:SetProperty("UnifiedPosition", selfUnionPos);
		end

		Equip_OnUpdateShow();
		Equip_RefreshEquip();

		--在打开的时候，将属性页的缺省页进行调整
		SelfEquip_SelfEquip:SetCheck(1);
		SelfEquip_SelfData:SetCheck(0);
		SelfEquip_Pet:SetCheck(0);

		-- 显示精力
		SelfEquip_ShowVigor();

		-- 显示活力
		SelfEquip_ShowEnergy();
		SelfEquip_SetTabColor(0);
		--	是否显示引导UI
--		local nLevel = tonumber(Player:GetData("LEVEL"));
--		local nCurExp = tonumber(Player:GetData("EXP"));
--		local nNeedExp = tonumber(Player:GetData("NEEDEXP"));
--		local nTimes = math.floor(tonumber(nCurExp / nNeedExp));
--		if nLevel == 10 then
--			if nTimes == 1 or nTimes == 2 or nTimes == 5 then
--				if g_ShowLevelUp == 1 then
--					SelfEquip_FreshManGuide(1, 18, 2);
--					g_ShowLevelUp = 0
--				end
--			end
--		end


		g_WEAPON:SetProperty("FlashAnimate", "BtnlightupAni")
		local nProcess = DataPool:GetCurrentFreshManGuideItemValue()
		if nProcess == 4 then
			CloseFreshManGuide()
			SetTimer("SelfEquip", "SelfEquip_FirstWeaponGuide()", 5000)
		end

		if nProcess == 20 then		--新的坐骑指引
			--SelfEquip_FreshManGuide(1,1,4)
		end

		local nLevel =Player:GetLevel()
		SelfEquip_Refresh_Page_Button(nLevel)
		SelfEquip_ShowPage()
		
	end

	-- 关闭界面
	if ( event == "CLOSE_EQUIP" ) then
		if (this:IsVisible()) then
			SelfEquip_CloseUI();
			return
		end
	end

	if( event == "HIDE_ON_SCENE_TRANSED") then
		SelfEquip_CloseFunction();
		return;
	end
--[[
	if("CUR_TITLE_CHANGED" == event) then
		GetCurTitle();
		return;
	end

	if(event == "GUILD_SHOW_MYGUILDNAME") then
		GetGuildTitle();
		return;
	end
	--]]
	-- 装备变化时刷新装备.
	if("REFRESH_EQUIP" == event) then

		Equip_RefreshEquip();
		return;
	end

	if("MANUAL_ATTR_SUCCESS_EQUIP" == event) then

		-- 分配属性成功.
		SelfEquip_ManualAttr_Success();

		-- 设置手动调节点数按钮的状态.
		SetAcceptButtonState();

		Equip_OnUpdateShow();
		return;
	end
	if "NOTIFY_POP_UITIP" == event then
	    if "SelfEquip" == arg0 then
	        g_NeedTipText = tonumber(arg1)
	        g_NeedTipID = tonumber(arg2)
	        if this:IsVisible() then
			SelfEquip_FreshManGuide(1, g_NeedTipText, g_NeedTipID)
                end
            end
	    return
	end

	--以下事件限于窗口打开时
	if(this:IsVisible()) then

		local nNumber=0;
		local nMaxnumber=0;
		local strName;

		-- 等级
		if ((event == "UNIT_LEVEL" or event == "UNIT_MAX_EXP") and arg0 == "player") then
			--nNumber = Player:GetData( "LEVEL" );
			--SelfEquip_Level:SetText( "Level " .. tostring( nNumber ) );
			--nNumber = Player:GetData("NEEDEXP");
			--SelfEquip_Exp1:SetText( tostring( nNumber ) );
			-- 刷新所有信息
			Equip_OnUpdateShow();
			--	弹出关闭新手提示。。。。。真的很坑爹。。。
			if event == "UNIT_LEVEL" then
				local nLevel = Player:GetData("LEVEL")
				if nLevel > 10 and nLevel <= 30 then
					if "SelfEquip" == GetFreshManGuideOwner() then
						CloseFreshManGuide()
					end
					SelfEquip_FreshManGuide(1, 18, 3)
				end
			end

		-- 血
		elseif((event == "UNIT_HP" or event == "UNIT_MAX_HP")  and arg0 == "player") then
			nNumber = Player:GetData("HP");
			nMaxnumber = Player:GetData( "MAXHP" );

			local strHpText = tostring( nNumber ).."/"..tostring( nMaxnumber );
			strHpText = "#cFAFFA4"..strHpText;
			SelfEquip_HP:SetText( strHpText );
		-- mana
		elseif((event == "UNIT_MP" or event == "UNIT_MAX_MP")  and arg0 == "player") then
			nNumber = Player:GetData( "MP" );
			nMaxnumber = Player:GetData( "MAXMP" );

			local strMpText = tostring( nNumber ).."/"..tostring( nMaxnumber ) ;
			strMpText = "#cFAFFA4"..strMpText;
			SelfEquip_MP:SetText( strMpText );

		-- 怒气
		elseif((event == "UNIT_RAGE" )  and arg0 == "player") then
			-- 怒气
		local menpai = Player:GetData("MEMPAI");
		  if 13 ~= menpai then 
			nNumber = Player:GetData("RAGE");
			nMaxnumber = Player:GetData("MAXRAGE");

			local strRageText = tostring( nNumber ).."/"..tostring( nMaxnumber );
			strRageText = "#cFAFFA4"..strRageText;
			SelfEquip_SP:SetText(strRageText );
		  end
		-- 桃花岛能量
		elseif((event == "UNIT_ENG" or event == "UNIT_MAX_ENG")  and arg0 == "player") then
			-- 怒气
			local menpai = Player:GetData("MEMPAI");
			if 13 == menpai then 
				
			  nNumber = Player:GetData("ENG");
			  nMaxnumber = Player:GetData("MAXENG");

			  local strRageText = tostring( nNumber ).."/"..tostring( nMaxnumber );
			  strRageText = "#cFAFFA4"..strRageText;
				SelfEquip_SP:SetText(strRageText );
			end
		--经验值
		elseif(event == "UNIT_EXP" and arg0 == "player") then
			nNumber = Player:GetData("EXP");
			SelfEquip_Exp2:SetText( "#cC8B88E"..tostring( nNumber ) );

			-- 得到升级需要的经验
			g_RequireExperience = Player:GetData("NEEDEXP");
			SelfEquip_Exp1:SetText( "#cC8B88E"..tostring( g_RequireExperience ) );

			--升级按钮
			SelfEquip_LevelupButtonShow();

		--STR
		elseif(event == "UNIT_STR" and arg0 == "player") then
			nNumber = Player:GetData("STR");
			SelfEquip_Str:SetText( tostring( nNumber ) );

		elseif(event == "UNIT_XIULIAN_STR" and arg0 == "player") then
			if(Player:GetData("XIULIANFLAG") > 0) then
				nNumber = Player:GetData("XIULIAN_STR");
				local StrText = "#H+" .. tostring( nNumber );
				SelfEquip_Str_Plus:SetText( StrText );
			else
				SelfEquip_Str_Plus:SetText("");
			end


		--SPR
		elseif(event == "UNIT_SPR" and arg0 == "player") then
			nNumber = Player:GetData("SPR");
			SelfEquip_Nimbus:SetText( tostring( nNumber ) );


		elseif(event == "UNIT_XIULIAN_SPR" and arg0 == "player" ) then
			if(Player:GetData("XIULIANFLAG") > 0) then
				nNumber = Player:GetData("XIULIAN_SPR");
				local StrText = "#H+" .. tostring( nNumber );
				SelfEquip_Nimbus_Plus:SetText( StrText );
			else
				SelfEquip_Nimbus_Plus:SetText("");
			end

		--CON
		elseif(event == "UNIT_CON" and arg0 == "player") then
			nNumber = Player:GetData("CON");
			SelfEquip_PhysicalStrength:SetText( tostring( nNumber ) );

		elseif(event == "UNIT_XIULIAN_CON" and arg0 == "player" ) then
			if(Player:GetData("XIULIANFLAG") > 0) then
				nNumber = Player:GetData("XIULIAN_CON");
				local StrText = "#H+" .. tostring( nNumber );
				SelfEquip_PhysicalStrength_Plus:SetText( StrText );
			else
				SelfEquip_PhysicalStrength_Plus:SetText("");
			end

		--INT
		elseif(event == "UNIT_INT" and arg0 == "player") then
			nNumber = Player:GetData("INT");
			SelfEquip_Stability:SetText( tostring( nNumber ) );

		elseif(event == "UNIT_XIULIAN_INT" and arg0 == "player" ) then
			if(Player:GetData("XIULIANFLAG") > 0) then
				nNumber = Player:GetData("XIULIAN_INT");
				local StrText = "#H+" .. tostring( nNumber );
				SelfEquip_Stability_Plus:SetText( StrText );
			else
				SelfEquip_Stability_Plus:SetText("");
			end

		--DEX
		elseif(event == "UNIT_DEX" and arg0 == "player") then
			nNumber = Player:GetData("DEX");
			SelfEquip_Footwork:SetText( tostring( nNumber ) );

		elseif(event == "UNIT_XIULIAN_DEX" and arg0 == "player" ) then
			if(Player:GetData("XIULIANFLAG") > 0) then
				nNumber = Player:GetData("XIULIAN_DEX");
				local StrText = "#H+" .. tostring( nNumber );
				SelfEquip_Footwork_Plus:SetText( StrText );
			else
				SelfEquip_Footwork_Plus:SetText("");
			end
		--POINT_REMAIN
		elseif(event == "UNIT_POINT_REMAIN" and arg0 == "player") then
			-- 重置属性点的分配
			SelfEquip_ResetCharRemainPoint();

		--ATT_PHYSICS
		elseif(event == "UNIT_ATT_PHYSICS" and arg0 == "player") then
			nNumber = Player:GetData("ATT_PHYSICS");
			SelfEquip_Perporty1:SetText( tostring( nNumber ) );

		elseif(event == "UNIT_XIULIAN_ATT_PHYSICS" and arg0 == "player") then
			if(Player:GetData("XIULIANFLAG") > 0) then
				nNumber = Player:GetData("XIULIAN_ATTP");
				local StrText = "#H+" .. tostring( nNumber );
				SelfEquip_Perporty1_Plus:SetText( StrText );
			else
				SelfEquip_Perporty1_Plus:SetText("");
			end
		--DEF_PHYSICS
		elseif(event == "UNIT_DEF_PHYSICS" and arg0 == "player") then
			nNumber = Player:GetData("DEF_PHYSICS");
			if nNumber > 999999 then --为帮战修改的 modified by hukai
				SelfEquip_Perporty3:SetText( "??????" );
			else
				SelfEquip_Perporty3:SetText( tostring( nNumber ) );
			end

		elseif(event == "UNIT_XIULIAN_DEF_PHYSICS" and arg0 == "player") then
			if(Player:GetData("XIULIANFLAG") > 0) then
				nNumber = Player:GetData("XIULIAN_DEFP");
				local StrText = "#H+" .. tostring( nNumber );
				SelfEquip_Perporty3_Plus:SetText( StrText );
			else
				SelfEquip_Perporty3_Plus:SetText("");
			end
		--ATT_MAGIC
		elseif(event == "UNIT_ATT_MAGIC" and arg0 == "player") then
			nNumber = Player:GetData("ATT_MAGIC");
			SelfEquip_Perporty2:SetText( tostring( nNumber ) );
			local nProcess = DataPool:GetCurrentFreshManGuideItemValue()
			if nProcess == 4 then
				local ActionWeapon 		= EnumAction(0, "equip");
				if ActionWeapon:GetID() ~= -1 then
					ActionWeapon:SetActionFlash(1)
					g_WEAPON:SetNewFlash()
				end
				DataPool:SetCurrentFreshManGuideItemValue(5)
		end

		elseif(event == "UNIT_XIULIAN_ATT_MAGIC" and arg0 == "player" ) then
		    if(Player:GetData("XIULIANFLAG") > 0) then
				nNumber = Player:GetData("XIULIAN_ATTM");
				local StrText = "#H+" .. tostring( nNumber );
				SelfEquip_Perporty2_Plus:SetText( StrText );
			else
				SelfEquip_Perporty2_Plus:SetText("");
			end

		--DEF_MAGIC
		elseif(event == "UNIT_DEF_MAGIC" and arg0 == "player") then
			nNumber = Player:GetData("DEF_MAGIC");
			if nNumber > 999999 then --为帮战修改的 modified by hukai
				SelfEquip_Perporty4:SetText( "??????" );
			else
				SelfEquip_Perporty4:SetText( tostring( nNumber ) );
			end

		elseif(event == "UNIT_XIULIAN_DEF_MAGIC" and arg0 == "player" ) then
			if(Player:GetData("XIULIANFLAG") > 0) then
				nNumber = Player:GetData("XIULIAN_DEFM");
				local StrText = "#H+" .. tostring( nNumber );
				SelfEquip_Perporty4_Plus:SetText( StrText );
			else
				SelfEquip_Perporty4_Plus:SetText("");
			end


		--UNIT_HUIXINFANGYU
--		elseif(event == "UNIT_MISS" and arg0 == "player") then
--			nNumber = Player:GetData("MISS");
--			SelfEquip_Perporty5:SetText( tostring( nNumber ) );

		--UNIT_MISS
		elseif(event == "UNIT_MISS" and arg0 == "player") then
			nNumber = Player:GetData("MISS");
			SelfEquip_Perporty6:SetText( tostring( nNumber ) );

		elseif(event == "UNIT_XIULIAN_MISS" and arg0 == "player" ) then
			if(Player:GetData("XIULIANFLAG") > 0) then
				nNumber = Player:GetData("XIULIAN_MISS");
				local StrText = "#H+" .. tostring( nNumber );
				SelfEquip_Perporty6_Plus:SetText( StrText );
			else
				SelfEquip_Perporty6_Plus:SetText("");
			end

		--UNIT_HIT
		elseif(event == "UNIT_HIT" and arg0 == "player") then
			nNumber = Player:GetData("HIT");
			SelfEquip_Perporty7:SetText( tostring( nNumber ) );

		elseif(event == "UNIT_XIULIAN_HIT" and arg0 == "player" ) then
			if(Player:GetData("XIULIANFLAG") > 0) then
				nNumber = Player:GetData("XIULIAN_HIT");
				local StrText = "#H+" .. tostring( nNumber );
				SelfEquip_Perporty7_Plus :SetText( StrText );
			else
				SelfEquip_Perporty7_Plus :SetText("");
			end

		--UNIT_CRITICAL_ATTACK
		elseif(event == "UNIT_CRITICAL_ATTACK" and arg0 == "player") then
			nNumber = Player:GetData("CRITICALATTACK");
			SelfEquip_Perporty8:SetText( tostring( nNumber ) );

		--UNIT_CRITICAL_DEFENCE
		elseif(event == "UNIT_CRITICAL_DEFENCE" and arg0 == "player") then
			nNumber = Player:GetData("CRITICALDEFENCE");
			SelfEquip_Perporty9:SetText( tostring( nNumber ) );

		--冰防御
		elseif(event == "UNIT_DEF_COLD" and arg0 == "player") then
			SelfEquip_SetStateTooltip();

		--火防御
		elseif(event == "UNIT_DEF_FIRE" and arg0 == "player") then
			SelfEquip_SetStateTooltip();

		--电防御
		elseif(event == "UNIT_DEF_LIGHT" and arg0 == "player") then
			SelfEquip_SetStateTooltip();

		--毒防御
		elseif(event == "UNIT_DEF_POSION" and arg0 == "player") then
			SelfEquip_SetStateTooltip();

		--减冰抗
		elseif(event == "UNIT_RESISTOTHER_COLD" and arg0 == "player") then
			SelfEquip_SetStateTooltip();

		--减火抗
		elseif(event == "UNIT_RESISTOTHER_FIRE" and arg0 == "player") then
			SelfEquip_SetStateTooltip();

		--减电抗
		elseif(event == "UNIT_RESISTOTHER_LIGHT" and arg0 == "player") then
			SelfEquip_SetStateTooltip();

		--减毒抗
		elseif(event == "UNIT_RESISTOTHER_POSION" and arg0 == "player") then
			SelfEquip_SetStateTooltip();
			
		elseif(event == "UNIT_SUBRESISTLIMIT_COLD" and arg0 == "player") then
			SelfEquip_SetStateTooltip();
		elseif(event == "UNIT_SUBRESISTLIMIT_FIRE" and arg0 == "player") then
			SelfEquip_SetStateTooltip();
		elseif(event == "UNIT_SUBRESISTLIMIT_LIGHT" and arg0 == "player") then
			SelfEquip_SetStateTooltip();
		elseif(event == "UNIT_SUBRESISTLIMIT_POISON" and arg0 == "player") then
			SelfEquip_SetStateTooltip();

		--冰攻击
		elseif(event == "UNIT_ATT_COLD" and arg0 == "player") then
			SelfEquip_SetStateTooltip();
		--火攻击
		elseif(event == "UNIT_ATT_FIRE" and arg0 == "player") then
			SelfEquip_SetStateTooltip();
		--电攻击
		elseif(event == "UNIT_ATT_LIGHT" and arg0 == "player") then
			SelfEquip_SetStateTooltip();
		--毒攻击
		elseif(event == "UNIT_ATT_POSION" and arg0 == "player") then
			SelfEquip_SetStateTooltip();
		--直接攻击(强化)
		elseif(event == "UNIT_ENCHANCE_ATT" and arg0 == "player") then
			SelfEquip_SetStateTooltip();
		--直接防御(强化)
		elseif(event == "UNIT_ENCHANCE_DEF" and arg0 == "player") then
			SelfEquip_SetStateTooltip();

		--玩家战斗评分
		elseif(event == "HUMAN_BATTLE_SCORE" and arg0 == "player") then
			nNumber = Player:GetData("BATTLESCORE");
			--SelfEquip_FightScore:SetText( "#{ZDPF_130115_01}"..tostring(nNumber) );
			local equipScoreHH = Player:GetData("EQUIPSCOREHH");
			SelfEquip_FightScore_Text:SetText( "#{ZDPF_130115_01}"..tostring(nNumber) );
			--SelfEquip_FightScore:SetToolTip("#{PFZY_140613_199}")
			if Player:GetData("Is2606S") == 1 then
				SelfEquip_FightScore_Text:SetToolTip(ScriptGlobal_Format("#{QXF_260623_133}",equipScoreHH))
			else
				SelfEquip_FightScore_Text:SetToolTip(ScriptGlobal_Format("#{ZDPF_130115_02}",equipScoreHH))
			end

		elseif(event == "UNIT_VIGOR" and arg0 == "player") then

			SelfEquip_ShowVigor();

		elseif(event == "UNIT_ENERGY" and arg0 == "player") then

			SelfEquip_ShowEnergy();
		elseif( event == "UPDATE_DUR" ) then
			SelfEquip_UpdateMask();

	        elseif (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		        SelfEquip_Frame_On_ResetPos();
            elseif event == "UPDATE_REDPOINT_IN_UI" then
		SelfEquip_Exterior_Tips()
		SelfEquip_YR_Tips()
	elseif event == "UPDATE_REDPOINT_IN_UI_EX" then
		SelfEquip_YR_Tips()
	elseif event == "UPDATE_WG_LEVEL" then
		Equip_OnUpdateShow()
	elseif event == "UPDATE_EXTERIOR_TIP" then
		SelfEquip_Exterior_Tips()
		else
			-- 不要默认的情况下调用这个函数， 会造成属性点数莫名其妙的刷新。
			-- 2006-3-23
			--Equip_OnUpdateShow();
		end

	end

	if event == "FIVEELEMENTS_UPDATE"  and this:IsVisible() then
		SelfEquip_UpdateFiveElementsTip()
		return
	end
	
	if(event == "ONOPENBIEYEFURCREATE" and this:IsVisible()) then
		SelfEquip_CloseUI()
	end
	
	if event == "XBW_SELF_EQUIP_UPDATE_2018" then
		SelfEquip_UpdateXbwInfo()
		return
	end
	
	if event == "UPDATE_TOY_TIP" then
		SelfEquip_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		SelfEquip_RefreshCangPinTip()
	end
	
	-- 其它事件都更新人物的基本信息.
	--Equip_OnUpdateShow();
end

--显示升级按钮
function SelfEquip_LevelupButtonShow()

	local bIs2606S = Player:GetData("Is2606S");
	local bIsCanLevelup = Player:IsCanLevelup();
	local nCompatLevel = tonumber(Player:GetData("LEVEL_CompatPKLV"));
	
	if bIs2606S == 0 then
		-- 根据经验禁止或者打开升级
		if( bIsCanLevelup==1 and nCompatLevel<LEVEL_MAX_ENABLE ) then
			if tonumber(Player:GetData("LEVEL")) == 119 and nCompatLevel == 119 then
				SelfEquip_UpLevel:Disable();
				if Player:GetData("IsExpandLevelPlayer") > 0 then
					SelfEquip_UpLevel_Tip:SetToolTip("#{KDJYD_250814_12}");
					SelfEquip_UpLevel_Tip:Show()
				else
					SelfEquip_UpLevel_Tip:Hide()
				end
			else
				SelfEquip_UpLevel:Enable();
				SelfEquip_UpLevel_Tip:Hide()
			end
		else

			SelfEquip_UpLevel:Disable();
			SelfEquip_UpLevel_Tip:Hide()
		end
		
	else
	
		--默认置灰
			SelfEquip_UpLevel:SetToolTip("");		
			SelfEquip_UpLevel:Disable();
			SelfEquip_UpLevel_Tip:Hide()
		
			--计算经验
			local nStorageExp = Player:GetData("NEEDEXP") * 4;
			if nStorageExp < SEFFEQUIP_MAX_STORAGEEXP_2606S then
				nStorageExp = SEFFEQUIP_MAX_STORAGEEXP_2606S;
			end
			local szToolTip="";
			local nDate = Lua_Get2606SNextPhaseDate();
			if nDate > 0 then
			
				local nNextLevel=LEVEL_MAX_ENABLE;
				local nOpenDate, nDayCount = Lua_Get2606SOpenDayCount()
				if nOpenDate ~= nil and nDayCount ~= nil then
			
					local nIndex = 0;
					local nFCnt = Lua_Get2606SLevelInfoCount();
					while( nIndex < nFCnt ) do
				
						local nTblDayCount, nTblLevel, nYear, nMonth, nDay = Lua_Get2606SLevelPhaseInfo( nOpenDate, nIndex )
						if nTblDayCount == nil then
							break;
						end
					
						if nDayCount < nTblDayCount then
							nNextLevel = nTblLevel;
							break
						end				
				
						nIndex = nIndex + 1;
					end
				end
			
				local nMonth = math.floor(nDate / 100);
				nMonth = math.mod(nMonth, 100)
				local nDay = math.mod(nDate, 100)
				szToolTip = ScriptGlobal_Format("#{QXFJYXG_260618_3}", LEVEL_MAX_ENABLE, nMonth, nDay, nNextLevel, nStorageExp );

				if bIsCanLevelup==1 then
					SelfEquip_UpLevel:Enable();				
					SelfEquip_UpLevel:SetToolTip(szToolTip);
				else
					SelfEquip_UpLevel_Tip:SetToolTip(szToolTip);
					SelfEquip_UpLevel_Tip:Show()
				end
				
			else
				szToolTip = ScriptGlobal_Format("#{QXFJYXG_260618_4}", nStorageExp );
				if bIsCanLevelup==1 and nCompatLevel<LEVEL_MAX_ENABLE then
					SelfEquip_UpLevel:Enable();				
					SelfEquip_UpLevel:SetToolTip(szToolTip);
				else
					SelfEquip_UpLevel_Tip:SetToolTip(szToolTip);
					SelfEquip_UpLevel_Tip:Show()
				end
			end
					
	end
	
end

-- 更新主角基本信息
function Equip_OnUpdateShow()

	g_RemainPoint 			= 0;	-- 剩余点数
	g_CurExperience 	  = 0;	-- 当前剩余经验
	g_RequireExperience = 0;  -- 升级所需经验

	g_AddStr = 0;					-- 分配在力量上的剩余点数.
	g_AddSpr = 0;					-- 分配在灵气上的剩余点数.
	g_AddCon = 0;					-- 分配在体质上的剩余点数.
	g_AddInt = 0;					-- 分配在定力上的剩余点数.
	g_AddDex = 0;					-- 分配在身法上的剩余点数.
	g_CurRemainPoint = 0;	-- 分配后的剩余点数


	local nNumber=0;
	local nMaxnumber=0;
	local strName;

	-- 禁止增加潜能按钮.
	Equip_Addition_Button1:Disable();
	Equip_Decrease_Button1:Disable();

	Equip_Addition_Button2:Disable();
	Equip_Decrease_Button2:Disable();

	Equip_Addition_Button3:Disable();
	Equip_Decrease_Button3:Disable();

	Equip_Addition_Button4:Disable();
	Equip_Decrease_Button4:Disable();

	Equip_Addition_Button5:Disable();
	Equip_Decrease_Button5:Disable();

	-- 允许按钮
	-- SelfEquip_Accept:Enalbe();

	-- 禁止增加按钮
	-- SelfEquip_Accept:Disable();

	-- 得到自己的名字
  strName = Player:GetName();
	SelfEquip_PageHeader:SetText("#gFF0FA0".. strName );

	-- 得到血值
	nNumber = Player:GetData("HP");
	nMaxnumber = Player:GetData( "MAXHP" );
	local HPText = tostring( nNumber ).."/"..tostring( nMaxnumber );
	HPText = "#cFAFFA4"..HPText;
	SelfEquip_HP:SetText( HPText );


	-- 得到魔法值
	nNumber = Player:GetData( "MP" );
	nMaxnumber = Player:GetData( "MAXMP" );

	local MPText = tostring( nNumber ).."/"..tostring( nMaxnumber );
	MPText = "#cFAFFA4"..MPText;
	SelfEquip_MP:SetText( MPText );
	
	
	-- 怒气
	local menpai = Player:GetData("MEMPAI");
	if 13 ~= menpai then
	  nNumber = Player:GetData("RAGE");
	  nMaxnumber = Player:GetData("MAXRAGE");
	  local RageText = tostring( nNumber ).."/"..tostring( nMaxnumber );
	  RageText = "#cFAFFA4"..RageText;
		SelfEquip_SP:SetText( RageText );	
		SelfEquip_SP_Text:SetText("#{INTERFACE_XML_481}")
	else
	  nNumber = Player:GetData("ENG");
	  nMaxnumber = Player:GetData("MAXENG");
	  local RageText = tostring( nNumber ).."/"..tostring( nMaxnumber );
	  RageText = "#cFAFFA4"..RageText;
		SelfEquip_SP:SetText( RageText );	
		SelfEquip_SP_Text:SetText("共情:")
		SelfEquip_SP_Text:SetToolTip("#{THJN_191001_01}")
	end


	-- 得到当前经验
	g_CurExperience = Player:GetData("EXP");
	local CurExpText = tostring( g_CurExperience );
	CurExpText = "#cC8B88E"..CurExpText;
	SelfEquip_Exp2:SetText( CurExpText );

	-- 得到升级需要的经验
	g_RequireExperience = Player:GetData("NEEDEXP");
	local NeedExpText =  tostring( g_RequireExperience );
	NeedExpText = "#cC8B88E"..NeedExpText;
	SelfEquip_Exp1:SetText( NeedExpText );

	--升级按钮
	SelfEquip_LevelupButtonShow();

	-- 得到等级
	nNumber = Player:GetData( "LEVEL" );
	local nLevel = nNumber
	local isCompatPKServer = Player:GetData("IsPKServer_JD")
	local nCompatPKLevel = Player:GetData( "LEVEL_CompatPKLV" )
	if isCompatPKServer == 1 and nCompatPKLevel < nLevel then
		local LevelText = ScriptGlobal_Format("#{CTPK_251016_2}",tostring(nCompatPKLevel));
		SelfEquip_Level:SetText( LevelText );
		local strLevelToolTip = ScriptGlobal_Format("#{CTPK_251016_3}",tostring(nLevel));
		SelfEquip_Level:SetToolTip(strLevelToolTip);
		SelfEquip_PKLevel_Image:Show()
	else
		local LevelText = ScriptGlobal_Format("#{CTPK_251016_1}",tostring(nLevel));
		SelfEquip_Level:SetText( LevelText );
		SelfEquip_Level:SetToolTip("");
		SelfEquip_PKLevel_Image:Hide()
	end

  local cur = WGAch:GetCJMaxCur()
  if cur ~= nil and cur.cur_level >= 1 and cur.cur_level <= table.getn(g_SelfEquip_PrettyImage) then
		SelfEquip_Pretty:SetToolTip(ScriptGlobal_Format("#{WGPF_191106_10}", cur.name))
		SelfEquip_Pretty:SetProperty("NormalImage", g_SelfEquip_PrettyImage[cur.cur_level][1])
		SelfEquip_Pretty:SetProperty("PushedImage", g_SelfEquip_PrettyImage[cur.cur_level][2])
		SelfEquip_Pretty:SetProperty("HoverImage", g_SelfEquip_PrettyImage[cur.cur_level][3])
	end

	if nNumber >= 10 then
		local nExpTimes = math.floor(Player:GetHumanExpRatioToNeedExp())
		if nExpTimes == 1 or nExpTimes == 2 or nExpTimes == 5 then
			g_ShowLevelUp = 1
		end
	end

	-- 如果等级大于某值禁止按钮.
	if( LEVEL_MAX_ENABLE <= nCompatPKLevel and Player:GetData("Is2606S") == 0 ) then
		SelfEquip_UpLevel:Disable();
	end

  -- 力量
  nNumber = Player:GetData("STR");
  local StrText = tostring( nNumber );
  --StrText = "#DED784"..StrText;
	SelfEquip_Str:SetText( StrText );

	-- 灵气
  nNumber = Player:GetData("SPR");
  local SprText = tostring( nNumber );
  --SprText = "#DED784"..SprText;
	SelfEquip_Nimbus:SetText( SprText );

	-- 体质
	nNumber = Player:GetData("CON");
	local ConText = tostring( nNumber );
	SelfEquip_PhysicalStrength:SetText( ConText );


	-- 定力
	nNumber = Player:GetData("INT");
	SelfEquip_Stability:SetText( tostring( nNumber ) );

	-- 身法
	nNumber = Player:GetData("DEX");
	SelfEquip_Footwork:SetText( tostring( nNumber ) );

	-- 剩余点数
	g_RemainPoint = Player:GetData("POINT_REMAIN");
	SelfEquip_Potential:SetText( tostring( g_RemainPoint ) );
	g_CurRemainPoint = g_RemainPoint;

	if(g_CurRemainPoint > 0) then

		Equip_Addition_Button1:Enable();
		Equip_Addition_Button2:Enable();
		Equip_Addition_Button3:Enable();
		Equip_Addition_Button4:Enable();
		Equip_Addition_Button5:Enable();

	end;


	-- 物理攻击
	nNumber = Player:GetData("ATT_PHYSICS");
	SelfEquip_Perporty1:SetText( tostring( nNumber ) );

	-- 物理防御
	nNumber = Player:GetData("DEF_PHYSICS");
	if nNumber > 999999 then --为帮战修改的 modified by hukai
		SelfEquip_Perporty3:SetText( "??????" );
	else
		SelfEquip_Perporty3:SetText( tostring( nNumber ) );
	end

	-- 魔法攻击
	nNumber = Player:GetData("ATT_MAGIC");
	SelfEquip_Perporty2:SetText( tostring( nNumber ) );

	-- 魔法防御
	nNumber = Player:GetData("DEF_MAGIC");
	if nNumber > 999999 then --为帮战修改的 modified by hukai
		SelfEquip_Perporty4:SetText( "??????" );
	else
		SelfEquip_Perporty4:SetText( tostring( nNumber ) );
	end

	-- 闪避率
	nNumber = Player:GetData("MISS");
	SelfEquip_Perporty6:SetText( tostring( nNumber ) );

	-- 命中率
	nNumber = Player:GetData("HIT");
	SelfEquip_Perporty7:SetText( tostring( nNumber ) );

	--zhangqiang，修炼属性加成==============================
	if Player:GetData("XIULIANFLAG") > 0 then
		nNumber = Player:GetData("XIULIAN_STR");
		local StrText = "#H+" .. tostring( nNumber );
		SelfEquip_Str_Plus:SetText( StrText );

		nNumber = Player:GetData("XIULIAN_SPR");
		local StrText = "#H+" .. tostring( nNumber );
		SelfEquip_Nimbus_Plus:SetText( StrText );

		nNumber = Player:GetData("XIULIAN_CON");
		local StrText = "#H+" .. tostring( nNumber );
		SelfEquip_PhysicalStrength_Plus:SetText( StrText );

		nNumber = Player:GetData("XIULIAN_INT");
		local StrText = "#H+" .. tostring( nNumber );
		SelfEquip_Stability_Plus:SetText( StrText );

		nNumber = Player:GetData("XIULIAN_DEX");
		local StrText = "#H+" .. tostring( nNumber );
		SelfEquip_Footwork_Plus:SetText( StrText );

		nNumber = Player:GetData("XIULIAN_HIT");
		local StrText = "#H+" .. tostring( nNumber );
		SelfEquip_Perporty7_Plus:SetText( StrText );

		nNumber = Player:GetData("XIULIAN_ATTP");
		local StrText = "#H+" .. tostring( nNumber );
		SelfEquip_Perporty1_Plus:SetText( StrText );

		nNumber = Player:GetData("XIULIAN_DEFP");
		local StrText = "#H+" .. tostring( nNumber );
		SelfEquip_Perporty3_Plus:SetText( StrText );

		nNumber = Player:GetData("XIULIAN_ATTM");
		local StrText = "#H+" .. tostring( nNumber );
		SelfEquip_Perporty2_Plus:SetText( StrText );

		nNumber = Player:GetData("XIULIAN_DEFM");
		local StrText = "#H+" .. tostring( nNumber );
		SelfEquip_Perporty4_Plus:SetText( StrText );

		nNumber = Player:GetData("XIULIAN_MISS");
		local StrText = "#H+" .. tostring( nNumber );
		SelfEquip_Perporty6_Plus:SetText( StrText );
	else
		SelfEquip_Str_Plus:SetText( "" );
		SelfEquip_Nimbus_Plus:SetText( "" );
		SelfEquip_PhysicalStrength_Plus:SetText( "" );
		SelfEquip_Stability_Plus:SetText( "" );
		SelfEquip_Footwork_Plus:SetText( "" );
		SelfEquip_Perporty7_Plus:SetText( "" );
		SelfEquip_Perporty1_Plus:SetText( "" );
		SelfEquip_Perporty3_Plus:SetText( "" );
		SelfEquip_Perporty2_Plus:SetText( "" );
		SelfEquip_Perporty4_Plus:SetText( "" );
		SelfEquip_Perporty6_Plus:SetText( "" );
	end
	--=======================================================

	-- 会心攻击
	nNumber = Player:GetData("CRITICALATTACK");
	SelfEquip_Perporty8:SetText( tostring( nNumber ) );

	SelfEquip_Perporty8_Plus:SetText( "" );

	-- 会心防御
	nNumber = Player:GetData("CRITICALDEFENCE");
	SelfEquip_Perporty9:SetText( tostring( nNumber ) );

	SelfEquip_Perporty9_Plus:SetText( "" );

	-- 活力
	SelfEquip_ShowVigor();

	-- 精力
	SelfEquip_ShowEnergy();

	-- 门派
	local menpai = Player:GetData("MEMPAI");
	local strName = "";

	-- 得到门派名称.
	if(0 == menpai) then
		strName = "少林";

	elseif(1 == menpai) then
		strName = "明教";

	elseif(2 == menpai) then
		strName = "丐帮";

	elseif(3 == menpai) then
		strName = "武当";

	elseif(4 == menpai) then
		strName = "峨嵋";

	elseif(5 == menpai) then
		strName = "星宿";

	elseif(6 == menpai) then
		strName = "天龙";

	elseif(7 == menpai) then
		strName = "天山";

	elseif(8 == menpai) then
		strName = "逍遥";

	elseif(9 == menpai) then
		strName = "无门派";

	elseif(10== menpai) then
		strName = "慕容";

	elseif(11== menpai) then
		strName = "唐门";
		
	elseif(12== menpai) then
		strName = "鬼谷";
	elseif(13== menpai) then
		strName = "#{THDXG_190705_03}";--桃花岛
	elseif(14== menpai) then
		strName = "#{XMPHM_210604_01}";
	elseif(15== menpai) then--menpai15 mptodo
		strName = "#{GMGameInterface_Script_DataPool_Info_ERenGu}";
			
	end

	-- 设置显示的门派.
	SelfEquip_MenPai:SetText(strName);

	-- 设置战斗评价
	nNumber = Player:GetData("BATTLESCORE");
	--SelfEquip_FightScore:SetText( "#{ZDPF_130115_01}"..tostring(nNumber) );
	local equipScoreHH = Player:GetData("EQUIPSCOREHH");
	SelfEquip_FightScore_Text:SetText( "#{ZDPF_130115_01}"..tostring(nNumber) );
	if Player:GetData("Is2606S") == 1 then
		SelfEquip_FightScore_Text:SetToolTip(ScriptGlobal_Format("#{QXF_260623_133}",equipScoreHH))
	else
		SelfEquip_FightScore_Text:SetToolTip(ScriptGlobal_Format("#{ZDPF_130115_02}",equipScoreHH))
	end

	if Player:GetData("Is2606S") == 1 then	
		SelfEquip_SectTitle:Hide()
		SelfEquip_SectTitle_tips:Hide()
	else
		SelfEquip_SectTitle:Show()
		SelfEquip_SectTitle_tips:Show()
	
	local sectLevel = Player:GetData("ZONEMENTITLELEVEL");
	local sectStr = g_SelfEquip_SectTitleLevel[0].tips
	local sectImg = g_SelfEquip_SectTitleLevel[0].image
	local sectPush = g_SelfEquip_SectTitleLevel[0].push
	local sectHover = g_SelfEquip_SectTitleLevel[0].hover
	if g_SelfEquip_SectTitleLevel[sectLevel].tips ~= nil then
		sectStr = g_SelfEquip_SectTitleLevel[sectLevel].tips
		sectImg = g_SelfEquip_SectTitleLevel[sectLevel].image
		sectPush = g_SelfEquip_SectTitleLevel[sectLevel].push
		sectHover = g_SelfEquip_SectTitleLevel[sectLevel].hover
	end
	
	local fixRate, expAdd, curState = LuaFnGetCurZongmenTitleInfo()	
	
	SelfEquip_SectTitle:SetToolTip(ScriptGlobal_Format("#{TXYZ_230710_02}",sectStr, expAdd, fixRate))

	SelfEquip_SectTitle:SetProperty("NormalImage", sectImg)
	SelfEquip_SectTitle:SetProperty("PushedImage", sectPush)
	SelfEquip_SectTitle:SetProperty("HoverImage", sectHover)	
	
	if curState == 1 then
		SelfEquip_SectTitle_tips:Show()
	else
		SelfEquip_SectTitle_tips:Hide()
	end
	
	end
	
	local nLevel =Player:GetLevel()	
	if nLevel >= 60 then
		SelfEquip_Shoulder_Visual_Icon:Show()
	else
		SelfEquip_Shoulder_Visual_Icon:Hide()
	end
	
	-- 设置帮会显示
--	GetGuildTitle();

	-- 得到称号
--	GetCurTitle();

	-- 设置手动调节点数按钮的状态.
	SetAcceptButtonState();

end

function SelfEquip_SectTitle_Clicked()
	PushEvent( "OPEN_SHOWZONGMENTITLELEVEL" )
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "KillRedPoint" )
		Set_XSCRIPT_ScriptID( 998879 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

-- 刷新装备
function Equip_RefreshEquip()


	--  清空按钮显示图标
	g_WEAPON:SetActionItem(-1);			--武器
	g_CAP:SetActionItem(-1);				--帽子
	g_ARMOR:SetActionItem(-1);			--盔甲
	g_CUFF:SetActionItem(-1);				--手套
	g_BOOT:SetActionItem(-1);				--鞋
	g_SASH:SetActionItem(-1);				--腰带
	g_RING:SetActionItem(-1);				--戒指
	g_NECKLACE:SetActionItem(-1);		--项链
	g_Dark:SetActionItem(-1);			--暗器
	g_RING_2:SetActionItem(-1);			--戒指2
	g_CHARM:SetActionItem(-1);			--护符
	g_CHARM_2:SetActionItem(-1);		--护符2
	g_WRIST:SetActionItem(-1);			--护腕
	g_SHOULDER:SetActionItem(-1);		--护肩
	g_LONGWEN:SetActionItem(-1);		--龙纹
	g_RL:SetActionItem(-1);					--符石传说

	local ActionWeapon 		= EnumAction(0, "equip");
	local ActionCap    		= EnumAction(1, "equip");
	local ActionArmor  		= EnumAction(2, "equip");
	local ActionCuff   		= EnumAction(3, "equip");
	local ActionBoot   		= EnumAction(4, "equip");
	local ActionSash   		= EnumAction(5, "equip");
	local ActionRing    	= EnumAction(6, "equip");
	local ActionNecklace	= EnumAction(7, "equip");
	local ActionMount			= EnumAction(17, "equip");
	local ActionRing_2		= EnumAction(11, "equip");
	local ActionCharm 		= EnumAction(12, "equip");
	local ActionCharm_2   = EnumAction(13, "equip");
	local ActionWrist  		= EnumAction(14, "equip");
	local ActionShoulder  = EnumAction(15, "equip");
	local ActionLongwen   	= EnumAction(19, "equip");
	local AciontRL					= EnumAction(20, "equip");

	-- 显示人身上的武器装备
	g_WEAPON:SetActionItem(ActionWeapon:GetID());			--武器
	g_CAP:SetActionItem(ActionCap:GetID());						--帽子
	g_ARMOR:SetActionItem(ActionArmor:GetID());				--盔甲
	g_CUFF:SetActionItem(ActionCuff:GetID());					--护腕
	g_BOOT:SetActionItem(ActionBoot:GetID());					--鞋
	g_SASH:SetActionItem(ActionSash:GetID());					--腰带
	g_RING:SetActionItem(ActionRing:GetID());					--戒子
	g_NECKLACE:SetActionItem(ActionNecklace:GetID());	--项链
	g_Dark:SetActionItem(ActionMount:GetID());				--暗器
	g_RING_2:SetActionItem(ActionRing_2:GetID());			--戒指2
	g_CHARM:SetActionItem(ActionCharm:GetID());			--护符
	g_CHARM_2:SetActionItem(ActionCharm_2:GetID());		--护符2
	g_WRIST:SetActionItem(ActionWrist:GetID());			--护腕
	g_SHOULDER:SetActionItem(ActionShoulder:GetID());		--护肩
	g_LONGWEN:SetActionItem(ActionLongwen:GetID());		--龙纹
	g_RL:SetActionItem(AciontRL:GetID());		--符石传说

  --- 显示人身上的宝石装备位
  SelfEquip_UpdateGemContainer( )

	SelfEquip_UpdateMask();
	SelfEquip_UpdateZhiZunAnimate()

	local nMinAttactLevel = DataPool:Lua_GetEnchanceMinLevel(0)
	local nMinDefenceLevel = DataPool:Lua_GetEnchanceMinLevel(1)
	local nSumLevel = 6 * (nMinAttactLevel + nMinDefenceLevel)

	if nSumLevel < m_EnchanceLevel[1] then
		SelfEquip_Effect:SetProperty("Image" , "set:UIIcons1 image:Equip_qianghua1" )
	elseif nSumLevel < m_EnchanceLevel[2] then
		SelfEquip_Effect:SetProperty("Image" , "set:UIIcons1 image:Equip_qianghua2" )
	elseif nSumLevel < m_EnchanceLevel[3] then
		SelfEquip_Effect:SetProperty("Image" , "set:UIIcons1 image:Equip_qianghua3" )
	elseif nSumLevel < m_EnchanceLevel[4] then
		SelfEquip_Effect:SetProperty("Image" , "set:UIIcons1 image:Equip_qianghua4" )
	else
		SelfEquip_Effect:SetProperty("Image" , "set:UIIcons1 image:Equip_qianghua5" )
	end

	SelfEquip_UpdateFiveElementsTip()
	
	SelfEquip_UpdateXbwInfo()

	SelfEquip_Update2026SButton()
	
end

function SelfEquip_Update2026SButton()
	
	if Player:GetData("Is2606S") == 1 then
		SelfEquip_ZhiZun_Icon:Hide()
		SelfEquip_ShenDing_Icon:Hide()
		--SelfEquip_ZongMenSkill_Icon:Hide()
		
		g_LONGWEN:Hide()
		--SelfEquip_BaoShiCheck_15red:Hide()
		--SelfEquip_BaoShiCheck_15green:Hide()
		--SelfEquip_BaoShiCheckBK15:Hide()
		
		g_RL:SetProperty("UnifiedPosition", g_SelfEquip_2026.g_SelfEquip_25_UnifiedPosition);
		SelfEquip_BaoShiCheck_16red:SetProperty("UnifiedPosition", g_SelfEquip_2026.g_SelfEquip_BaoShiCheck_15_UnifiedPosition);
		SelfEquip_BaoShiCheck_16green:SetProperty("UnifiedPosition", g_SelfEquip_2026.g_SelfEquip_BaoShiCheck_15_UnifiedPosition);
		SelfEquip_BaoShiCheckBK16:SetProperty("UnifiedPosition", g_SelfEquip_2026.g_SelfEquip_BaoShiCheck_15_UnifiedPosition);	
	else
		SelfEquip_ZhiZun_Icon:Show()
		SelfEquip_ShenDing_Icon:Show()
		--SelfEquip_ZongMenSkill_Icon:Show()
		
		g_LONGWEN:Show()
		--SelfEquip_BaoShiCheck_15red:Show()
		--SelfEquip_BaoShiCheck_15green:Show()
		--SelfEquip_BaoShiCheckBK15:Show()
				
		g_RL:SetProperty("UnifiedPosition", g_SelfEquip_2026.g_SelfEquip_16_UnifiedPosition);
		SelfEquip_BaoShiCheck_16red:SetProperty("UnifiedPosition", g_SelfEquip_2026.g_SelfEquip_BaoShiCheck_16_UnifiedPosition);
		SelfEquip_BaoShiCheck_16green:SetProperty("UnifiedPosition", g_SelfEquip_2026.g_SelfEquip_BaoShiCheck_16_UnifiedPosition);
		SelfEquip_BaoShiCheckBK16:SetProperty("UnifiedPosition", g_SelfEquip_2026.g_SelfEquip_BaoShiCheck_16_UnifiedPosition);	
	end
	
end

function SelfEquip_Equip_Click( nTypeIn,buttonIn )

	local nType = tonumber( nTypeIn );
	local button = tonumber( buttonIn );
	if( nType == 11 ) then
		if( button == 1 ) then
			g_WEAPON:DoAction();	--武器
		else
			g_WEAPON:DoSubAction();	--武器
		end
	elseif( nType == 12 ) then
		if( button == 1 ) then
			g_ARMOR:DoAction();	--衣服
		else
			g_ARMOR:DoSubAction();	--衣服
		end
	elseif( nType == 1 ) then
		if( button == 1 ) then
			g_CAP:DoAction();	--帽子
		else
			g_CAP:DoSubAction();	--帽子
		end
	elseif( nType == 4 ) then
		if( button == 1 ) then
			g_CUFF:DoAction();	--手套
		else
			g_CUFF:DoSubAction();	--手套
		end
	elseif( nType == 6 ) then
		if( button == 1 ) then
			g_BOOT:DoAction();	--鞋
		else
			g_BOOT:DoSubAction();	--鞋
		end
	elseif( nType == 7 ) then
		if( button == 1 ) then
			g_RING:DoAction();	--戒指
		else
			g_RING:DoSubAction();	--戒指
		end
	elseif( nType == 5 ) then
		if( button == 1 ) then
			g_SASH:DoAction();	--腰带
		else
			g_SASH:DoSubAction();	--腰带
		end
	elseif( nType == 13) then
		if( button == 1 ) then
			g_NECKLACE:DoAction();	--项链
		else
			g_NECKLACE:DoSubAction();	--项链
		end
	elseif( nType == 14 ) then
		if( button == 1 ) then
			g_Dark:DoAction();	--暗器
		else
			g_Dark:DoSubAction();	--暗器
		end
	elseif( nType == 2 ) then
		if( button == 1 ) then
			g_SHOULDER:DoAction();	--护肩
		else
			g_SHOULDER:DoSubAction();	--护肩
		end
	elseif( nType == 3 ) then
		if( button == 1 ) then
			g_WRIST:DoAction();	--护腕
		else
			g_WRIST:DoSubAction();	--护腕
		end
	elseif( nType == 8 ) then
		if( button == 1 ) then
			g_RING_2:DoAction();	--戒指2
		else
			g_RING_2:DoSubAction();	--戒指
		end
	elseif( nType == 9 ) then
		if( button == 1 ) then
			g_CHARM:DoAction();	--护符
		else
			g_CHARM:DoSubAction();	--护符
		end
	elseif( nType == 10 ) then
		if( button == 1 ) then
			g_CHARM_2:DoAction();	--护符2
		else
			g_CHARM_2:DoSubAction();	--护符2
		end
	elseif( nType == 25 ) then
		if( button == 1 ) then
			g_LONGWEN:DoAction();	--龙纹
		else
			g_LONGWEN:DoSubAction();	--龙纹
		end
	elseif( nType == 16 ) then
		if( button == 1 ) then
			g_RL:DoAction();	--符石传说
		else
			g_RL:DoSubAction();	--符石传说
		end

	end
end


----------------------------------------------------------------------------
-- 力量点数按钮
--
-- 减少力量点数按钮
function SelfEquip_Dec1_Click()

	if (g_AddStr > 0) then
		g_CurRemainPoint = g_CurRemainPoint + 1;
		if(g_CurRemainPoint > 0) then
			EanblePointAddButtion();
		end;

		g_AddStr = g_AddStr - 1;
	end

	if(g_AddStr <= 0) then
		g_AddStr = 0;
		Equip_Decrease_Button1:Disable();
	end

	-- 显示当前剩余的点数
	ShowCurRemainPoint();

	-- 设置剩余点数按钮状态
	SetAcceptButtonState();

	-- 显示力量
	ShowCurStr();

end

-- 增加力量点数按钮
function SelfEquip_Add1_Click()

	if (g_CurRemainPoint > 0) then
		g_AddStr = g_AddStr + 1;
		if(g_AddStr > 0) then
			Equip_Decrease_Button1:Enable();
		end

		g_CurRemainPoint = g_CurRemainPoint - 1;
	end

	if(g_CurRemainPoint <= 0) then
		g_CurRemainPoint = 0;
		DisablePointAddButtion();
	end

	-- 显示当前剩余的点数
	ShowCurRemainPoint();

	-- 设置剩余点数按钮状态
	SetAcceptButtonState();

	-- 显示力量
	ShowCurStr();

end


-----------------------------------------------------------------------------
-- 灵气点数按钮
--
-- 减少灵气点数按钮
function SelfEquip_Dec2_Click()

	if (g_AddSpr > 0) then
		g_CurRemainPoint = g_CurRemainPoint + 1;
		if(g_CurRemainPoint > 0) then
			EanblePointAddButtion();
		end

		g_AddSpr = g_AddSpr - 1;
	end

	if(g_AddSpr <= 0) then

		g_AddSpr = 0;
		Equip_Decrease_Button2:Disable();
	end

	-- 显示当前剩余的点数
	ShowCurRemainPoint();

	-- 设置剩余点数按钮状态
	SetAcceptButtonState();

	-- 显示灵气
	ShowCurSpr();

end

-- 增加灵气点数按钮
function SelfEquip_Add2_Click()

	if (g_CurRemainPoint > 0) then
		g_AddSpr = g_AddSpr + 1;
		if(g_AddSpr > 0) then
			Equip_Decrease_Button2:Enable();
		end

		g_CurRemainPoint = g_CurRemainPoint - 1;
	end

	if(g_CurRemainPoint <= 0) then
		g_CurRemainPoint = 0;
		DisablePointAddButtion();
	end

	-- 显示当前剩余的点数
	ShowCurRemainPoint();

	-- 设置剩余点数按钮状态
	SetAcceptButtonState();

	-- 显示灵气
	ShowCurSpr();

end


-----------------------------------------------------------------------------
-- 体质点数按钮
--
-- 减少体质点数按钮
function SelfEquip_Dec3_Click()

	if (g_AddCon > 0) then
		g_CurRemainPoint = g_CurRemainPoint + 1;
		if(g_CurRemainPoint > 0) then
			EanblePointAddButtion();
		end

		g_AddCon = g_AddCon - 1;
	end

	if(g_AddCon <= 0) then

		g_AddCon = 0;
		Equip_Decrease_Button3:Disable();
	end

	-- 显示当前剩余的点数
	ShowCurRemainPoint();

	-- 设置剩余点数按钮状态
	SetAcceptButtonState();

	-- 显示体质
	ShowCurCon();


end

-- 增加体质点数按钮
function SelfEquip_Add3_Click()

	if (g_CurRemainPoint > 0) then
		g_AddCon = g_AddCon + 1;
		if(g_AddCon > 0) then
			Equip_Decrease_Button3:Enable();
		end

		g_CurRemainPoint = g_CurRemainPoint - 1;
	end

	if(g_CurRemainPoint <= 0) then
		g_CurRemainPoint = 0;
		DisablePointAddButtion();
	end

	-- 显示当前剩余的点数
	ShowCurRemainPoint();

	-- 设置剩余点数按钮状态
	SetAcceptButtonState();

	-- 显示体质
	ShowCurCon();

end


-------------------------------------------------------------------------------
-- 定力点数按钮
--
-- 减少定力点数按钮
function SelfEquip_Dec4_Click()

	if (g_AddInt > 0) then
		g_CurRemainPoint = g_CurRemainPoint + 1;
		if(g_CurRemainPoint > 0) then
			EanblePointAddButtion();
		end

		g_AddInt = g_AddInt - 1;
	end

	if(g_AddInt <= 0) then

		g_AddInt = 0;
		Equip_Decrease_Button4:Disable();
	end

	-- 显示当前剩余的点数
	ShowCurRemainPoint();

	-- 设置剩余点数按钮状态
	SetAcceptButtonState();

	-- 显示定力
	ShowCurInt();

end

-- 增加定力点数按钮
function SelfEquip_Add4_Click()

	if (g_CurRemainPoint > 0) then
		g_AddInt = g_AddInt + 1;
		if(g_AddInt > 0) then
			Equip_Decrease_Button4:Enable();
		end

		g_CurRemainPoint = g_CurRemainPoint - 1;
	end

	if(g_CurRemainPoint <= 0) then

		g_CurRemainPoint = 0;
		DisablePointAddButtion();
	end

	-- 显示当前剩余的点数
	ShowCurRemainPoint();

	-- 设置剩余点数按钮状态
	SetAcceptButtonState();

	-- 显示定力
	ShowCurInt();

end



--------------------------------------------------------------------------------
-- 身法点数按钮
--
-- 减少身法点数按钮
function SelfEquip_Dec5_Click()

	if (g_AddDex > 0) then
		g_CurRemainPoint = g_CurRemainPoint + 1;
		if(g_CurRemainPoint > 0) then
			EanblePointAddButtion();
		end

		g_AddDex = g_AddDex - 1;
	end

	if(g_AddDex <= 0) then

		g_AddDex = 0;
		Equip_Decrease_Button5:Disable();
	end

	-- 显示当前剩余的点数
	ShowCurRemainPoint();

	-- 设置剩余点数按钮状态
	SetAcceptButtonState();

	-- 显示身法
	ShowCurDex();

end

-- 增加身法点数按钮
function SelfEquip_Add5_Click()

	if (g_CurRemainPoint > 0) then
		g_AddDex = g_AddDex + 1;
		if(g_AddDex > 0) then
			Equip_Decrease_Button5:Enable();
		end

		g_CurRemainPoint = g_CurRemainPoint - 1;
	end

	if(g_CurRemainPoint <= 0) then

		g_CurRemainPoint = 0;
		DisablePointAddButtion();
	end

	-- 显示当前剩余的点数
	ShowCurRemainPoint();

	-- 设置剩余点数按钮状态
	SetAcceptButtonState();

	-- 显示身法
	ShowCurDex();

end

--------------------------------------------------------------------------------
--
-- 打开所有的点数增加按钮
--
function EanbleAskAttrBn(bEnable)

	Equip_Addition_Button1:Enable();
	Equip_Addition_Button2:Enable();
	Equip_Addition_Button3:Enable();
	Equip_Addition_Button4:Enable();
	Equip_Addition_Button5:Enable();
end

--------------------------------------------------------------------------------
--
-- 打开所有的点数增加按钮
--
function EanblePointAddButtion()

	Equip_Addition_Button1:Enable();
	Equip_Addition_Button2:Enable();
	Equip_Addition_Button3:Enable();
	Equip_Addition_Button4:Enable();
	Equip_Addition_Button5:Enable();
end


--------------------------------------------------------------------------------
--
-- 禁止所有的点数增加按钮
--
function DisablePointAddButtion()

	Equip_Addition_Button1:Disable();
	Equip_Addition_Button2:Disable();
	Equip_Addition_Button3:Disable();
	Equip_Addition_Button4:Disable();
	Equip_Addition_Button5:Disable();
end


--------------------------------------------------------------------------------
--
-- 打开所有的点数增加按钮
--
function EanblePointDecButtion()

	Equip_Decrease_Button1:Enable();
	Equip_Decrease_Button2:Enable();
	Equip_Decrease_Button3:Enable();
	Equip_Decrease_Button4:Enable();
	Equip_Decrease_Button5:Enable();
end


--------------------------------------------------------------------------------
--
-- 禁止所有的点数增加按钮
--
function DisablePointDecButtion()

	Equip_Decrease_Button1:Disable();
	Equip_Decrease_Button2:Disable();
	Equip_Decrease_Button3:Disable();
	Equip_Decrease_Button4:Disable();
	Equip_Decrease_Button5:Disable();
end


---------------------------------------------------------------------------------
--
-- 显示当前的潜能
--
function ShowCurRemainPoint()

	SelfEquip_Potential:SetText( tostring( g_CurRemainPoint ) );

end

---------------------------------------------------------------------------------
--
-- 显示力量
--
function ShowCurStr()

	SelfEquip_Str:SetText( tostring( g_AddStr + Player:GetData("STR") ) );

end

---------------------------------------------------------------------------------
--
-- 显示灵气
--
function ShowCurSpr()

	SelfEquip_Nimbus:SetText( tostring( g_AddSpr + Player:GetData("SPR"))  );

end

---------------------------------------------------------------------------------
--
-- 显示体质
--
function ShowCurCon()

	SelfEquip_PhysicalStrength:SetText( tostring( g_AddCon + Player:GetData("CON"))  );

end

---------------------------------------------------------------------------------
--
-- 显示定力
--
function ShowCurInt()

	SelfEquip_Stability:SetText( tostring( g_AddInt + Player:GetData("INT"))  );

end

---------------------------------------------------------------------------------
--
-- 显示身法
--
function ShowCurDex()

	SelfEquip_Footwork:SetText( tostring( g_AddDex + Player:GetData("DEX"))  );

end



---------------------------------------------------------------------------------
--
-- 禁止, 打开申请潜能按钮潜能按钮
--
function SetAcceptButtonState()

	if(g_CurRemainPoint == g_RemainPoint) then

		SelfEquip_Accept:Disable();
	else

		SelfEquip_Accept:Enable();
	end;

end

---------------------------------------------------------------------------------
--
-- 申请增加潜能
--
function SelfEquip_Accept_Click()

	-- 发送更改属性请求.
	Player:SendAskManualAttr(g_AddStr, g_AddSpr, g_AddCon, g_AddInt, g_AddDex);

	-- 测试使用, 向服务器要装备的详细信息
	--AskEquipDetial();

end

---------------------------------------------------------------------------------
--
-- 梳妆台功能
--
function SelfEquip_Individuation_Clicked(targetId)

-- 	if IsInTServer() == 1 then
-- --		PushDebugMessage("#{BHKF_140909_327}")
-- 		return
-- 	end
	--关闭脸型发型发色界面
	if(IsWindowShow("SelectFacestyle")) then
		CloseWindow("SelectFacestyle", true)
	end
	if(IsWindowShow("SelectHairstyle")) then
		CloseWindow("SelectHairstyle", true)
	end
	if(IsWindowShow("SelectHairColor")) then
		CloseWindow("SelectHairColor", true)
	end
	--打开梳妆台界面
	PushEvent("OPEN_SHOP_DRESSER", "SelfEquip_Frame", targetId)
end

---------------------------------------------------------------------------------
--
-- 手动调整成功
--
function SelfEquip_ManualAttr_Success()

	g_AddStr = 0;					-- 分配在力量上的剩余点数.
	g_AddSpr = 0;					-- 分配在灵气上的剩余点数.
	g_AddCon = 0;					-- 分配在体质上的剩余点数.
	g_AddInt = 0;					-- 分配在定力上的剩余点数.
	g_AddDex = 0;					-- 分配在身法上的剩余点数.

	-- 禁止所有减少点数按钮
	DisablePointDecButtion();

	-- 剩余没有分配的点数
	g_RemainPoint = g_CurRemainPoint;
	if(g_CurRemainPoint > 0) then

		EanblePointAddButtion();
	end


end

---------------------------------------------------------------------------------
--
-- 点击称号按钮
--
function TitleButton_Click()

	g_bOpenTitleDlg = 1;
	-- 打开称号界面
	OpenTitleList();

end

----------------------------------------------------------------------------------
--
-- 点击帮会按钮
--
function OpenConfraternity_click()

	-- 打开或关闭帮会界面
	Guild:ToggleGuildDetailInfo();
end


----------------------------------------------------------------------------------
--
-- 得到当前的title
--
--[[
function GetCurTitle()

	-- 得到当前的称号.
	local strCurTitle = Player:GetCurTitle();
	SelfEquip_Agname:SetText(strCurTitle);

end

function GetGuildTitle()
	local szGuildName = Guild:GetMyGuildInfo("Name");
	if(nil ~= szGuildName and "" ~= szGuildName) then
		SelfEquip_Confraternity:SetText(szGuildName);
	else
		SelfEquip_Confraternity:SetText("");
	end
end
--]]
----------------------------------------------------------------------------------
--
-- 选装玩家模型（向左)
--
function SelfEquip_Modle_TurnLeft(start)
	--向左旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		SelfEquip_FakeObject:RotateBeginEx("Player", -0.3);
	--向左旋转结束
	else
		SelfEquip_FakeObject:RotateEndEx();
	end
end

----------------------------------------------------------------------------------
--
-- 选装玩家模型（向右)
--
function SelfEquip_Modle_TurnRight(start)
	--向右旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		SelfEquip_FakeObject:RotateBeginEx("Player", 0.3);
	--向右旋转结束
	else
		SelfEquip_FakeObject:RotateEndEx();
	end
end

---------------------------------------------------------------------------------
--
-- 设置状态tooltip
--
function SelfEquip_SetStateTooltip()


	-- 得到状态属性
	local iIceDefine  		= Player:GetData( "DEFENCECOLD" );
	local iFireDefine 		= Player:GetData( "DEFENCEFIRE" );
	local iThunderDefine	= Player:GetData( "DEFENCELIGHT" );
	local iPoisonDefine		= Player:GetData( "DEFENCEPOISON" );

	--不显示负抗性
	if (iIceDefine ~= nil and iIceDefine < 0) then
		iIceDefine = 0
	end
	if (iFireDefine ~= nil and iFireDefine < 0) then
		iFireDefine = 0
	end
	if (iThunderDefine ~= nil and iThunderDefine < 0) then
		iThunderDefine = 0
	end
	if (iPoisonDefine ~= nil and iPoisonDefine < 0) then
		iPoisonDefine = 0
	end

	local iIceAttack  		= Player:GetData( "ATTACKCOLD" );
	local iFireAttack 		= Player:GetData( "ATTACKFIRE" );
	local iThunderAttack	= Player:GetData( "ATTACKLIGHT" );
	local iPoisonAttack		= Player:GetData( "ATTACKPOISON" );

	local iIceResistOther	= Player:GetData( "RESISTOTHERCOLD" );
	local iFireResistOther= Player:GetData( "RESISTOTHERFIRE" );
	local iThunderResistOther	= Player:GetData( "RESISTOTHERLIGHT" );
	local iPoisonResistOther= Player:GetData( "RESISTOTHERPOISON" );

	local iIceResistLimit = Player:GetData("SUBRESISTLIMITCOLD")
	local iFireResistLimit = Player:GetData("SUBRESISTLIMITFIRE")
	local iThunderResistLimit = Player:GetData("SUBRESISTLIMITLIGHT")
	local iPoisonResistLimit = Player:GetData("SUBRESISTLIMITPOISON")

	local iEnchanceAtt = Player:GetData("ENCHANCEATT")
	local iEnchanceDef = Player:GetData("ENCHANCEDEF")

	--孩子技能
	local textInfantFireDefine = "";	-- 火抗
	local textInfantIceDefine = "";   --冰抗
	local textInfantPoisonDefine = ""; 	--毒抗
	local textInfantThunderDefine = ""; 	-- 玄抗
	local szFireResistOther = "";			--减火抗
	local szIceResistOther = "";			--减冰抗
	local szPoisonResistOther = "";			--减毒抗
	local szThunderResistOther = "";			--减玄抗
	local nSkillCount = Infant:GetMaxSkillNum()
--~ 	local nHealthValue = Infant:GetHealthValue(tonumber(g_CurSelInfantIndex)) --健康值
	for i = 1, nSkillCount do
		local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetInfantSkillInfo(tonumber(g_CurSelInfantIndex), i - 1);
		--孩子健康值为0时，抗性加成失效
--~ 		if nHealthValue <= 0 then
--~ 			nSkillEffect = "#cff00000#cffff00"
--~ 		end

		if nSkillID == 1 then
			textInfantFireDefine = "(".."#{ZNJCS_130825_7}"..":"..nSkillEffect..")"
		elseif nSkillID == 2 then
			textInfantIceDefine = "(".."#{ZNJCS_130825_7}"..":"..nSkillEffect..")"
		elseif nSkillID == 3 then
			textInfantPoisonDefine = "(".."#{ZNJCS_130825_7}"..":"..nSkillEffect..")"
		elseif nSkillID == 4 then
			textInfantThunderDefine = "(".."#{ZNJCS_130825_7}"..":"..nSkillEffect..")"
		elseif nSkillID == 5 then
			szFireResistOther = "(".."#{ZNJCS_130825_7}"..":"..nSkillEffect..")"
		elseif nSkillID == 6 then
			szIceResistOther = "(".."#{ZNJCS_130825_7}"..":"..nSkillEffect..")"
		elseif nSkillID == 7 then
			szPoisonResistOther = "(".."#{ZNJCS_130825_7}"..":"..nSkillEffect..")"
		elseif nSkillID == 8 then
			szThunderResistOther = "(".."#{ZNJCS_130825_7}"..":"..nSkillEffect..")"
		end
	end

	SelfEquip_IceFastness:SetToolTip("冰攻:"..tostring(iIceAttack).."#r冰抗:"..tostring(iIceDefine)..textInfantIceDefine.."#r减冰抗:"..tostring(iIceResistOther)..szIceResistOther.."#{JKXX_091228_1}"..tostring(iIceResistLimit) );
	SelfEquip_FireFastness:SetToolTip("火攻:"..tostring(iFireAttack).."#r火抗:"..tostring(iFireDefine)..textInfantFireDefine.."#r减火抗:"..tostring(iFireResistOther)..szFireResistOther.."#{JKXX_091228_2}"..tostring(iFireResistLimit) );
	SelfEquip_ThunderFastness:SetToolTip("玄攻:"..tostring(iThunderAttack).."#r玄抗:"..tostring(iThunderDefine)..textInfantThunderDefine.."#r减玄抗:"..tostring(iThunderResistOther)..szThunderResistOther.."#{JKXX_091228_3}"..tostring(iThunderResistLimit) );
	SelfEquip_PoisonFastness:SetToolTip("毒攻:"..tostring(iPoisonAttack).."#r毒抗:"..tostring(iPoisonDefine)..textInfantPoisonDefine.."#r减毒抗:"..tostring(iPoisonResistOther)..szPoisonResistOther.."#{JKXX_091228_4}"..tostring(iPoisonResistLimit) );

	--天锐 地磐
	if iEnchanceAtt ~= nil and iEnchanceDef ~= nil then
		local nMinAttackLevel = DataPool:Lua_GetEnchanceMinLevel(0)
		local nMinDefenceLevel = DataPool:Lua_GetEnchanceMinLevel(1)

		local nAttackValue = DataPool:Lua_GetEnchanceSetInfo( 0 , 3, nMinAttackLevel )
		local nDefenceValue = DataPool:Lua_GetEnchanceSetInfo( 1 , 3, nMinDefenceLevel )

		local nAttackValueAdd = math.ceil(( iEnchanceAtt * nAttackValue ) / ( 100 + nAttackValue ))
		local nDefenceValueAdd = math.ceil(( iEnchanceDef * nDefenceValue ) / ( 100 + nDefenceValue ))

		local strAttackTip = ScriptGlobal_Format("#{ZBQH_130521_28}" ,tostring(iEnchanceAtt) , tostring(nAttackValueAdd))
		local strDefenceTip = ScriptGlobal_Format("#{ZBQH_130521_30}" ,tostring(iEnchanceDef) , tostring(nDefenceValueAdd))

		if Player:GetData("Is2606S") == 1 then
			SelfEquip_HurtFastness:SetToolTip(strAttackTip.."#r#{QXF_260623_11}" )
		else
			SelfEquip_HurtFastness:SetToolTip(strAttackTip.."#r#{ZBQH_130521_29}" )
		end
		SelfEquip_DefenceFastness:SetToolTip(strDefenceTip.."#r#{ZBQH_130521_31}" )
	end

	--神木王鼎
	local nLevel = Player:GetData("LEVEL")
	if nLevel == nil or nLevel < 15 then
		SelfEquip_ShenDing_Icon:SetToolTip("#{XLDL_140606_01}");
	else
		--体力
		local nConValue = Player:GetData("LIANDANLUCONVALUE");
		local strConText = "#{XLDL_140606_02}";
		if nConValue ~= nil and nConValue > 0 then
			strConText = strConText.."#r体力：+"..tostring(nConValue)
		end
		--属性攻
		local nIce, nFire, nThunder, nPoison = Player:GetData("Attack_IFTPValue");
		if nIce ~= nil and nIce > 0 then
			strConText = strConText.."#r冰攻击：+"..tostring(nIce);
		end
		if nFire ~= nil and nFire > 0 then
			strConText = strConText.."#r火攻击：+"..tostring(nFire);
		end
		if nThunder ~= nil and nThunder > 0 then
			strConText = strConText.."#r玄攻击：+"..tostring(nThunder);
		end
		if nPoison ~= nil and nPoison > 0 then
			strConText = strConText.."#r毒攻击：+"..tostring(nPoison);
		end

		SelfEquip_ShenDing_Icon:SetToolTip(strConText);
	end
	
	--升级锁
	SelfEquip_LevelupLock_Update()
		
end

function SelfEquip_CheckLevelupLock()
	local nDeltaTime = 0;
	local bLock = Pneuma:GetMF( 3506 );
	local nUnlockTime = DataPool:GetPlayerMission_DataRound( 2477 )
	local nCurTime =  DataPool:GetCurrentServerTime();
	if nUnlockTime > 0 and (nCurTime - nUnlockTime) < 3600*24*3 then
		nDeltaTime = nUnlockTime + 3600*24*3 - nCurTime;
	end
	if nUnlockTime > 0 and (nCurTime - nUnlockTime) >= 3600*24*3 then
		bLock = 0;
	end
		
	if bLock >= 1 and nDeltaTime <= 0 then	--锁定
		return 2, 0;
	elseif bLock >= 1 and nDeltaTime > 0 then	--解锁中
		return 3, nDeltaTime;		
	end	
	
	--未上锁
	return 1, 0;
end

function SelfEquip_LevelupLock_Update()

	local nLevel = Player:GetLevel();
	local defineHumanMaxLevel = Player:GetDefineHumanMaxLevel()
	if Player:GetData("IsExpandLevelPlayer") > 0 then
		defineHumanMaxLevel = Player:GetDefineHumanMaxLevel()
	else
		defineHumanMaxLevel = Player:GetDefineHumanMaxLevelSub()
	end
	if ( nLevel >= 30 and nLevel < defineHumanMaxLevel ) then
		local nLockState, nDeltaTime = SelfEquip_CheckLevelupLock();	
		if nLockState == 1 then	--未上锁
			SelfEquip_LevelUpLock:SetToolTip("#{JSSJ_220303_01}")
			SelfEquip_LevelUpLock:Hide();
			SelfEquip_LevelUpLock_SuoLian:Hide();
			SelfEquip_LevelUpLock_Opening:Hide();
			SelfEquip_LevelUpLock_Open:Show();
		
		elseif nLockState == 2 then	--锁定
			SelfEquip_LevelUpLock:SetToolTip("#{JSSJ_220303_02}")
			SelfEquip_LevelUpLock:Show();
			SelfEquip_LevelUpLock_Open:Hide();
			SelfEquip_LevelUpLock_Opening:Hide();
			SelfEquip_LevelUpLock_SuoLian:Show();			
		
		elseif nLockState == 3 then	--解锁中
			local szTooltip="";
			if nDeltaTime > 3600*24 then
				local nDeltaHour = math.floor( nDeltaTime / 3600 );
				szTooltip = ScriptGlobal_Format( "#{JSSJ_220303_03}", math.floor(nDeltaHour/24), math.mod(nDeltaHour,24) )
			elseif nDeltaTime >= 3600 then
				local nDeltaHour = math.floor( nDeltaTime / 3600 );
				szTooltip = ScriptGlobal_Format( "#{JSSJ_220303_04}", math.mod(nDeltaHour,24) )
			else
				szTooltip = ScriptGlobal_Format( "#{JSSJ_220303_05}", math.floor(nDeltaTime/60)+1 )
			end
		
			SelfEquip_LevelUpLock:SetToolTip(szTooltip);
			SelfEquip_LevelUpLock:Show();
			SelfEquip_LevelUpLock_Open:Hide();
			SelfEquip_LevelUpLock_SuoLian:Show();
			SelfEquip_LevelUpLock_Opening:Show();

			if g_SelfEquip_LevelLock_IsSetTimer == 0 then			
				SetTimer("SelfEquip","SelfEquip_LevelupLock_Update()", 1000)
				g_SelfEquip_LevelLock_IsSetTimer = 1;
			end
		end
		
		--如果当前等级低于最高等级，则能升级
		local nMyLevel = Player:GetData( "LEVEL" )
		local isCompatPKServer = Player:GetData("IsPKServer_JD")
		local nCompatPKLevel = Player:GetData( "LEVEL_CompatPKLV" )
		if isCompatPKServer == 1 and nCompatPKLevel < nMyLevel then
			SelfEquip_LevelUpLock_SuoLian:Hide();
		end
		
	else
		SelfEquip_LevelUpLock:Hide();
		SelfEquip_LevelUpLock_Open:Hide();
		SelfEquip_LevelUpLock_SuoLian:Hide();
		SelfEquip_LevelUpLock_Opening:Hide();
	end	
end
---------------------------------------------------------------------------------
--
-- 显示活力
--
function SelfEquip_ShowVigor()
	--

	local iVigor = Player:GetData("VIGOR");
	local iVigorMax = Player:GetData("MAXVIGOR");
	local VigorText = tostring(iVigor).."/"..tostring(iVigorMax);
	SelfEquip_Vigor:SetText( VigorText );

end

---------------------------------------------------------------------------------
--
-- 显示活力
--
function SelfEquip_ShowEnergy()
	--

	local iEnergy 	 = Player:GetData("ENERGY");
	local iEnergyMax = Player:GetData("MAXENERGY");
	local EnergyText = tostring(iEnergy).."/"..tostring(iEnergyMax);
	SelfEquip_Energy:SetText(EnergyText);


end


----------------------------------------------------------------------------------------
--
-- 关闭界面
--

function SelfEquip_CloseUI()
	-- 打开或者关闭称号界面
	CloseTitleList();
	SelfEquip_FakeObject:DetachWindowEx("Player")
	SelfEquip_CloseFunction();

    if "SelfEquip" == GetFreshManGuideOwner() then
        CloseFreshManGuide()
    end
    g_NeedTipID = -1
    
  if g_SelfEquip_LevelLock_IsSetTimer == 1 then
   	g_SelfEquip_LevelLock_IsSetTimer = 0;
   	KillTimer("SelfEquip_LevelupLock_Update()");
  end
end


function SelfEquip_Pet_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	TogglePetPage();
	SelfEquip_SetTabColor(0);
end

--打开自己的资料页面
function SelfEquip_Page_SelfData()
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("self");

end

function SelfEquip_SetTabColor(idx)
	-- if(idx == nil or idx < 0 or idx > 5) then
		-- return;
	-- end

	-- local i = 0;
	-- local selColor = "#Y";
	-- local noselColor = "";
	-- local tab = {
								-- [0] = SelfEquip_SelfEquip,
								-- SelfEquip_SelfData,
								-- SelfEquip_Pet,
								-- SelfEquip_Ride,
								-- SelfEquip_JingMai,
								-- SelfEquip_OtherInfo,
							-- };

	-- while i < 6 do
		-- if(i == idx) then
			-- tab[i]:SetText(selColor..SELFEQUIP_TAB_TEXT[i]);
		-- else
			-- tab[i]:SetText(noselColor..SELFEQUIP_TAB_TEXT[i]);
		-- end
		-- i = i + 1;
	-- end
	return
end

function SelfEquip_XiuLian_Page_Switch()
	local nLevel = Player:GetData("LEVEL")
	if(nLevel >= 70) then
		Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
		XiuLianPage();
		SelfEquip_SetTabColor(0);
	else
		SelfEquip_Xiulian : SetCheck(0)
		PushDebugMessage("#{XL_090707_62}")
	end
end

function SelfEquip_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenJingMaiPage();
	if nRet == 1 then
		SelfEquip_SetTabColor(0);
	else
		SelfEquip_JingMai:SetCheck(0)
	end
end

--神木王鼎
function SelfEquip_ShenDing_Page_Switch()
	
	if Player:GetData("Is2606S") == 1 then
		return
	end
		
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenShenDingPage();
	if nRet == 1 then
		SelfEquip_SetTabColor(0);
	else
		SelfEquip_JingMai:SetCheck(0)
	end
end

function SelfEquip_LevelUpLock_Clicked()
	local nLockState, nDeltaTime = SelfEquip_CheckLevelupLock();
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnLevelupLock")
		Set_XSCRIPT_ScriptID(800801)
		Set_XSCRIPT_Parameter(0, nLockState)
		Set_XSCRIPT_Parameter(1, 0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function SelfEquip_JunXian_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		SelfEquip_CloseFunction();
	end
end

function Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	OpenRidePage();
	SelfEquip_SetTabColor(0);

	if (g_CurActFlashType == 4) then
		PushEvent("OPEN_FRESHMAN_NEWNPCCHAT",4)
	end
end

function Other_Info_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	OtherInfoPage();
    UpdateDoubleExpData();

end

function SelfEquip_UpdateMask()

	local i
	for i=0,22 do
		if i ~= 9 and i ~=10 and i~= 8 and i~= 18 and i~= 21 and i~= 16 and i ~= 22 then   --8:骑乘 9:行囊 10:箱子 18:武魂
			SelfEquip_UpdateMaskByIndex( i );
		end
	end
end
function SelfEquip_UpdateMaskByIndex( index )
	local ActionIndex = EnumAction(index, "equip");
	if( ActionIndex:GetEquipDur() < 0.1  or ActionIndex:IsLevelEnoughEquip() == 0 ) then
		g_EquipMask[ index ]:Show();
	else
		g_EquipMask[ index ]:Hide();
	end
end

function SelfEquip_UpdateZhiZunAnimate()

	for i = 1 , 15 do
		if i ~= 8 and i ~= 9 and i ~= 10 then			--8:骑乘 9:行囊 10:箱子
			local ActionEquip = EnumAction(i, "equip")

				if ActionEquip:Lua_GetEquipZhiZunType() == 1 then

					m_ZhiZunAnimate[ i ]:Show()
					m_ZhiZunAnimate[ i ]:SetProperty("Animate" , "ZhiZun_Flash_Big")

				elseif ActionEquip:Lua_GetEquipZhiZunType() == 2 then

					m_ZhiZunAnimate[ i ]:Show()
					m_ZhiZunAnimate[ i ]:SetProperty("Animate" , "JunXian_Flash3")

				else

					m_ZhiZunAnimate[ i ]:Hide()

				end

		end
	end

end


function SelfEquip_Open()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	g_AutoClick_Going = -1
	g_AutoClick_BtnFlag = -1
	SetTimer("SelfEquip", "SelfEquip_AutoClick_Timer()", g_AutoClickTimer_Step)

	SelfEquip_CloseSameGroupWindow()
	LEVEL_MAX_ENABLE = Lua_GetMyMaxLevelLimit();
	local nSpecKaJi89 = Player : GetData("SPECKAJI89") 
	if KaJi:LuaFnIsKaJiServer() == 1 then
		LEVEL_MAX_ENABLE = KaJi:LuaFnGetKaJiLeveL()	
	elseif nSpecKaJi89 == 1 or nSpecKaJi89 == 2 then
		LEVEL_MAX_ENABLE = 89
	end
	this:Show();
	SelfEquip_Exterior_Tips()
	SelfEquip_YR_Tips()
end

function SelfEquip_CloseFunction()
	g_AutoClick_Going = -1
	g_AutoClick_BtnFlag = -1
	KillTimer("SelfEquip_AutoClick_Timer()")
	KillTimer("SelfEquip_FirstWeaponGuide()")
	if "SelfEquip" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	g_CurActFlashType = 0
	if DataPool:GetCurrentFreshManGuideItemValue () == 5 then
		NotifyPopUITip("Packet", 1, 5)
	end
	this:Hide();
end

function SelfEquip_AskLevelup()
		-- 升级二次确认框数据置一下
		AskLevelUpAfterSec(1);
    local PlayerLevel = Player:GetData( "LEVEL" )
    local EvaluateLevelList = { 30, 45, 65, 75, 85 }

    local strMasterName = GetMasterName()

    if "" ~= strMasterName then   --空串表示在好友列表中没有找到师父名字,暨没有师父
        local ListSize = table.getn( EvaluateLevelList )
		for i = 1, ListSize do
			if EvaluateLevelList[ i ] == ( PlayerLevel+1 ) and PlayerLevel < 45 then
				--打开评价界面

				AskEvaluateAndLevelup()
				return
			end
		end
    end

    AskLevelUp( tonumber(0) )

    if g_NeedTipID == 1 and "SelfEquip" == GetFreshManGuideOwner() then
	g_NeedTipID = 2
    elseif g_NeedTipID == 2 and "SelfEquip" == GetFreshManGuideOwner() then
        CloseFreshManGuide()  --点击清除
        g_NeedTipID = -1
    end



end

--显示武魂UI
function SelfEquip_Wuhun_Switch()
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
	SelfEquip_SetTabColor(0);
end

function SelfEquip_ShowTooltip(Subject)
	if (g_PropertyTable[Subject] ~= nil) then
		if g_PropertyTable[Subject]:GetText() == "" then
			g_PropertyTable[Subject]:SetToolTip("")
		else
			if (g_XiulianTipTable[Subject] ~= nil) then
				g_PropertyTable[Subject]:SetToolTip( g_XiulianTipTable[Subject] )
			end
		end
	end
end

-- 重置人物角色的剩余属性点和已经分配的属性点
function SelfEquip_ResetCharRemainPoint()
	g_AddStr = 0;					-- 分配在力量上的剩余点数.
	g_AddSpr = 0;					-- 分配在灵气上的剩余点数.
	g_AddCon = 0;					-- 分配在体质上的剩余点数.
	g_AddInt = 0;					-- 分配在定力上的剩余点数.
	g_AddDex = 0;					-- 分配在身法上的剩余点数.

	-- 禁用属性点的增加和减少操作
	DisablePointAddButtion();
	DisablePointDecButtion();

	-- 获取剩余属性点
	local nNumber 		= Player:GetData("POINT_REMAIN");
	g_CurRemainPoint 	= nNumber;
	g_RemainPoint   	= nNumber;

	-- 更新显示
	ShowCurStr();
	ShowCurSpr();
	ShowCurCon();
	ShowCurInt();
	ShowCurDex();
	ShowCurRemainPoint();

	if(g_CurRemainPoint > 0) then
		EanblePointAddButtion();
	end

	-- 设置手动调节点数按钮的状态.
	SetAcceptButtonState();
end

--***************************************************
-- 清空鼠标长按标记
--***************************************************
function SelfEquip_AutoClick_Clear(id)
	id = tonumber(id)
	if (id == g_AutoClick_BtnFlag) then
		g_AutoClick_BtnFlag = -1
	end
end

--***************************************************
-- 定时器回调函数
--    实现慢启动, 以后可以考虑加速(必要性不大)
--***************************************************
function SelfEquip_AutoClick_Timer()
	if (g_AutoClick_BtnFlag ~= -1) then
		-- 第一次LButton后经过X个Timer才算开始, 也就是说是 g_AutoClickTimer_Step * X 的时候开始进行自动加, 这样为了防止本来要点击一下的结果点了好多下
		if (g_AutoClick_Going < 4) then
			g_AutoClick_Going = g_AutoClick_Going + 1
			--目前先设置 6 Step 的等待时间, 下面注释的代码可以后来用于实现慢启动, 逐渐加速效果.
			--if (g_AutoClick_Going == 2 or g_AutoClick_Going == 5) then
				--g_AutoClick_FunList[g_AutoClick_BtnFlag]()
			--end
		else
			g_AutoClick_FunList[g_AutoClick_BtnFlag]()
		end
	end
end

--***************************************************
-- 鼠标左键松开操作
--    注意这里其实是代替 Click, 所以需要执行一次 Click 操作
--***************************************************
function SelfEquip_AutoClick_LButtonUp(id)
	id = tonumber(id)
	SelfEquip_AutoClick_Clear(id)
	g_AutoClick_FunList[id]()
end

--***************************************************
-- 设置定时器
--    设置标记说明鼠标已经按下
--***************************************************
function SelfEquip_AutoClick_SetTimer(id)
	id = tonumber(id)
	g_AutoClick_Going = -1
	g_AutoClick_BtnFlag = id
end

--***************************************************
-- 恢复界面的默认相对位置
--***************************************************
function SelfEquip_Frame_On_ResetPos()
	SelfEquip_Frame:SetProperty("UnifiedXPosition", g_SelfEquip_Frame_UnifiedXPosition);
	SelfEquip_Frame:SetProperty("UnifiedYPosition", g_SelfEquip_Frame_UnifiedYPosition);
end

--!!!reloadscript =SelfEquip
function SelfEquip_FreshManGuide(nType, nTextID, nPosID)
    CloseFreshManGuide()
    if nType ~= 1 and      --1 is reset and open
        nType ~= 2 then    --2 is modify
        return
    end
--    if g_NeedTipID < 1 then
--        return
--    end

    local fX = 0
    local fY = 0
    local nPosX = tonumber(SelfEquip_Frame:GetProperty("AbsoluteXPosition"))
    local nPosY = tonumber(SelfEquip_Frame:GetProperty("AbsoluteYPosition"))

    if 1 == nPosID then
        fX, fY = this:GetChildOffset("SelfEquip_UpLevel")
        fX = fX + SelfEquip_UpLevel:GetProperty("AbsoluteWidth") / 2
        fY = fY + SelfEquip_UpLevel:GetProperty("AbsoluteHeight") / 2
	OpenFreshManGuide(nType, nTextID, fX, fY, "SelfEquip", "northeast")
    elseif 2 == nPosID then
	fX, fY = this:GetChildOffset("SelfEquip_UpLevel")
	local fH = tonumber(SelfEquip_UpLevel:GetProperty("AbsoluteHeight"))
	local fW = tonumber(SelfEquip_UpLevel:GetProperty("AbsoluteWidth"))
	fX = tonumber(fX + nPosX + fW - 30)
	fY = math.floor(tonumber(fY + nPosY + (fH * 0.5)) + 10)
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 16, 3, "SelfEquip")
	g_CurActFlashType = nPosID
	local nLevel = Player:GetData("LEVEL")
	if nLevel == 10 then		--2013Q3手动升级指引，仅从第10级升级到第11级出现对话气泡提示
		PushEvent("OPEN_FRESHMAN_NEWNPCCHAT",13)
	end
    elseif 3 == nPosID then
	fX, fY = this:GetChildOffset("SelfEquip_Close")
	local fH = tonumber(SelfEquip_Close:GetProperty("AbsoluteHeight"))
	local fW = tonumber(SelfEquip_Close:GetProperty("AbsoluteWidth"))
	fX = tonumber(fX + nPosX + fW)
	fY = math.floor(tonumber(fY + nPosY + (fH * 0.5)))
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 14, 3, "SelfEquip")
	local nLevel = Player:GetData("LEVEL")
	if nLevel == 11 then		--2013Q3手动升级指引，仅从第10级升级到第11级出现对话气泡提示
		PushEvent("OPEN_FRESHMAN_NEWNPCCHAT",14)
	end
	g_CurActFlashType = nPosID
	elseif 4 == nPosID then
	fX, fY = this:GetChildOffset("SelfEquip_Ride")
	local fH = tonumber(SelfEquip_Ride:GetProperty("AbsoluteHeight"))
	local fW = tonumber(SelfEquip_Ride:GetProperty("AbsoluteWidth"))
	fX = tonumber(fX + nPosX + fW - 120)
	fY = math.floor(tonumber(fY + nPosY + (fH * 0.5)) + 40)
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 22, 3, "SelfEquip")--xjc
	g_CurActFlashType = nPosID
	elseif 13 == nPosID or 14 == nPosID then
		fX, fY = this:GetChildOffset("SelfEquip_ZongMenSkill_Icon")
		local fH = tonumber(SelfEquip_ZongMenSkill_Icon:GetProperty("AbsoluteHeight"))
		local fW = tonumber(SelfEquip_ZongMenSkill_Icon:GetProperty("AbsoluteWidth"))
		fX = tonumber(fX + nPosX + fW - 120)
		fY = math.floor(tonumber(fY + nPosY + (fH * 0.5)) + 60)
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 32, 3, "SelfEquip")--xjc
		g_CurActFlashType = nPosID
    else
        return
    end

end

--	初始武器指引。。。。简直就是坑爹嘛。。。
function SelfEquip_FirstWeaponGuide()
	Equip_RefreshEquip()
	g_WEAPON:SetProperty("FlashAnimateEnable", 0)
	SelfEquip_FreshManGuide(1, 18, 3)
	KillTimer("SelfEquip_FirstWeaponGuide()")
	--SelfEquip_11:SetActionFlash(0)
end

--2011Q3新手任务ui指引
function SelfEquip_OnShown()
    if g_NeedTipID > 0 then
        SelfEquip_FreshManGuide(1, g_NeedTipText, g_NeedTipID)
    end
end
function SelfEquip_OnMoved()
    if "SelfEquip" == GetFreshManGuideOwner() then
	    SelfEquip_FreshManGuide(2, -1, g_CurActFlashType)
--        OpenFreshManGuide(2, -1, -1, -1)
    end
end

function SelfEquip_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

function SelfEquip_BaoShiCheck_Clicked( btnIndex )
    if btnIndex < 0 or btnIndex > 17 then
        return
    end
    PushEvent( "GEM_CONTAINER_CHECK", btnIndex, 0 )
end

local g_SelfEuip_TypeList =
{
	[1]  = { name="#{WBSS_120727_34}", gemConIndex=0,  equipIndex=0,  },    --- 武器
	[2]  = { name="#{WBSS_120727_26}", gemConIndex=11, equipIndex=14, },    --- 护腕
	[3]  = { name="#{WBSS_120727_30}", gemConIndex=6,  equipIndex=6,  },    --- 戒指（上）
	[4]  = { name="#{WBSS_120727_31}", gemConIndex=8,  equipIndex=11, },    --- 戒指（下）
	[5]  = { name="#{WBSS_120727_32}", gemConIndex=9,  equipIndex=12, },    --- 护符（上）
	[6]  = { name="#{WBSS_120727_33}", gemConIndex=10, equipIndex=13, },    --- 护符（下）
	[7]  = { name="#{WBSS_120727_35}", gemConIndex=2,  equipIndex=2,  },    --- 衣服
	[8]  = { name="#{WBSS_120727_24}", gemConIndex=1,  equipIndex=1,  },    --- 帽子
	[9]  = { name="#{WBSS_120727_25}", gemConIndex=12, equipIndex=15, },    --- 肩膀
	[10] = { name="#{WBSS_120727_27}", gemConIndex=3,  equipIndex=3,  },    --- 手套
	[11] = { name="#{WBSS_120727_28}", gemConIndex=5,  equipIndex=5,  },    --- 腰带
	[12] = { name="#{WBSS_120727_29}", gemConIndex=4,  equipIndex=4,  },    --- 鞋子
	[13] = { name="#{WBSS_120727_36}", gemConIndex=7,  equipIndex=7,  },    --- 项链
	[14] = { name="#{WBSS_120727_37}", gemConIndex=13, equipIndex=17, },    --- 暗器
	[15] = { name="#{WBSS_120727_39}", gemConIndex=15, equipIndex=19, },    --- 龙纹
	[16] = { name="#{WBSS_120727_38}", gemConIndex=14, equipIndex=18, },    --- 武魂
	[17] = { name="#{BHZB_140521_241}", gemConIndex=16, equipIndex=20, },    --- 令牌 
	[18] = { name="#{HXYSJ_141031_131}", gemConIndex=17, equipIndex=21, },    --- 豪侠印
	[19] = { name="#{WBSS_230829_01}", gemConIndex=18, equipIndex=23, },    --- 镇派秘宝
}

--- TODO: 注意: 当玩家换装备的时候，也要修改这个地方的显示
function SelfEquip_UpdateGemContainer( )
    --- 当玩家未学会万宝随身互换时，装备位宝石查看按钮为灰态
    local gemSwitchSkillID = 278


	if( Player:GetSkillInfo( gemSwitchSkillID, "learn") ) then
	else
        for i = 1, g_SelfEquip_Gem_Contain_Num do

			g_SelfEquip_Gem_Check_Buttons_green[i] : Hide()
			g_SelfEquip_Gem_Check_Buttons_red[i]   : Hide()
			g_SelfEquip_Gem_Check_Buttons_BK[i]    : Show()

        end
        return
	end

    local ret = 0
    for i = 1, g_SelfEquip_Gem_Contain_Num do
        g_SelfEquip_Gem_Check_Buttons_BK[i]    : Hide()
		if Player:GetData("Is2606S") == 1 and i == 15 then
			continue
		end
        ret = SelfEquip_Can_SwitchGem( i )
        if ret == 1 then
            --- 正常态：玩家学会万宝随身互换，装备位上存在装备且所有装备位上的宝石都可以进行互换时
            g_SelfEquip_Gem_Check_Buttons_green[i] : Enable()
            g_SelfEquip_Gem_Check_Buttons_green[i] : Show()
            g_SelfEquip_Gem_Check_Buttons_green[i] : SetToolTip( "#{WBSS_120727_44}" )
            g_SelfEquip_Gem_Check_Buttons_red[i]   : Hide()
        else
            --- 异常态：玩家学会万宝随身互换，装备位上不存在装备或非所有装备位上的宝石都可以进行互换时
            g_SelfEquip_Gem_Check_Buttons_red[i]   : Enable()
            g_SelfEquip_Gem_Check_Buttons_red[i]   : Show()
            g_SelfEquip_Gem_Check_Buttons_red[i]   : SetToolTip( "#{WBSS_120727_44}" )
            g_SelfEquip_Gem_Check_Buttons_green[i] : Hide()
        end
    end
end

function SelfEquip_Can_SwitchGem( curSel )

	if curSel == 16 then
		curSel = 17
	end
	local conPos     = g_SelfEuip_TypeList[curSel].gemConIndex
    local equipPoint = g_SelfEuip_TypeList[curSel].equipIndex

    --- 得到装备上的宝石
    local equipTypeList = {}
    local isHaveEquip, gemIndex1, gemIndex2, gemIndex3, gemIndex4 = LifeAbility : SplitWearedEquipGem( equipPoint )
    local gemIndexList  = {}
    gemIndexList[1] = gemIndex1
    gemIndexList[2] = gemIndex2
    gemIndexList[3] = gemIndex3
    gemIndexList[4] = gemIndex4
    if isHaveEquip == 1 then
        for i = 1, 4 do
            if gemIndexList[i] > 0 then
                equipTypeList[i] = SelfEquip_GetGemTypeByIndex( gemIndexList[i] )
            else
                equipTypeList[i] = -1
            end
        end
    else
        --- 没有装备
        return 0
    end

    --- 其次得到装备位上的宝石类型
    local gemConTypeList  = { }
    local bHaveGemCon     = 0       --- 装备位上是否有宝石
    LifeAbility : GemContainer_Update()
    for i = 1, 4 do
        local nItemID, tmpGemType
        nItemID, _, tmpGemType = LifeAbility : GetGemContainer_Gem( conPos, i - 1 )
        if nItemID ~= -1 then
            gemConTypeList[i] = tmpGemType
            bHaveGemCon       = 1
        else
            gemConTypeList[i] = -1
        end
    end
    if bHaveGemCon == 0 then
        return 0
    end

    --- 判断装备位上的所有宝石对应的当前装备上的孔位是否都存在宝石
    for i = 1, 4 do
        --- 如果装备位上有宝石
        if gemConTypeList[i] > 0 then
            -- 判断装备位上的所有宝石对应的当前装备上的孔位是否都存在宝石
            if equipTypeList[i] <= 0 then
                return 0
            end
            equipTypeList[i] = gemConTypeList[i]
        end
    end

    --- 判断互换后，当前装备前三孔是否会出现同类型宝石
    if equipTypeList[1] > 0 then
        if ( equipTypeList[1] == equipTypeList[2] ) or ( equipTypeList[1] == equipTypeList[3] ) then
            return 0
        end
    end

    if equipTypeList[2] > 0 then
        if ( equipTypeList[1] == equipTypeList[2] ) or ( equipTypeList[2] == equipTypeList[3] ) then
            return 0
        end
    end

    if equipTypeList[3] > 0 then
        if ( equipTypeList[1] == equipTypeList[3] ) or ( equipTypeList[2] == equipTypeList[3] ) then
            return 0
        end
    end

    return 1
end

--- 根据物品序列号来获得物品的类型
function SelfEquip_GetGemTypeByIndex( itemTblIdx )
    if itemTblIdx == nil or itemTblIdx <= 0 then
        return -1
    end

    local tmpValue = math.mod( itemTblIdx, 100000 )
    local itemType = math.floor( tmpValue / 1000 )
    return itemType
end

function SelfEquip_Miji_Page_Switch()
		Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenMijiPage();
	if bRet == 1 then
		this:Hide()
	end
end

--显示孩子UI
function SelfEquip_Infant_Switch()
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = Infant:ToggleInfantPage();
	if nRet == 1 then
		this:Hide()
		SelfEquip_SelfEquip:SetCheck(0);
	else
		SelfEquip_Infant:SetCheck(0)
	end
	SelfEquip_SetTabColor(0);
end

--2014:yuanpeilong:EquipScoreConduct:start
function SelfEquip_FightScore_Clicked()
	if Player:GetLevel() >= 30 then
		PushEvent("OPEN_EQUIP_SCORE_CONDUCT")
	else
		PushDebugMessage("#{PFZY_140613_174}")
	end
end
--2014:yuanpeilong:EquipScoreConduct:end

function SelfEquip_EnchanceSetAttr_MouseEnter()

	if SystemSetup:IsClassic() == 1 then
		local SetX= SelfEquip_Effect:GetProperty("AbsoluteXPosition") + SelfEquip_FakeObject_Frame:GetProperty("AbsoluteXPosition")+SelfEquip_Frame_Client:GetProperty("AbsoluteXPosition")+SelfEquip_MainFrame:GetProperty("AbsoluteXPosition")+SelfEquip_Frame:GetProperty("AbsoluteXPosition")
		local SetY = SelfEquip_Effect:GetProperty("AbsoluteYPosition")  + SelfEquip_FakeObject_Frame:GetProperty("AbsoluteYPosition")+SelfEquip_Frame_Client:GetProperty("AbsoluteYPosition")+SelfEquip_MainFrame:GetProperty("AbsoluteYPosition")+SelfEquip_Frame:GetProperty("AbsoluteYPosition")
		local SetWidth = SelfEquip_Effect:GetProperty("AbsoluteWidth")
		local SetHeight = SelfEquip_Effect:GetProperty("AbsoluteHeight")
		PushEvent("OPEN_ENCHANCESET", SetX,SetY,SetWidth,SetHeight)
	else
		local SetX= SelfEquip_Effect:GetProperty("AbsoluteXPosition") + SelfEquip_Effect_BK:GetProperty("AbsoluteXPosition")+SelfEquip_FakeObject_Frame:GetProperty("AbsoluteXPosition")+SelfEquip_Frame_Client:GetProperty("AbsoluteXPosition")+SelfEquip_MainFrame:GetProperty("AbsoluteXPosition") +SelfEquip_Frame:GetProperty("AbsoluteXPosition")
		local SetY = SelfEquip_Effect:GetProperty("AbsoluteYPosition")  + SelfEquip_Effect_BK:GetProperty("AbsoluteYPosition")+SelfEquip_FakeObject_Frame:GetProperty("AbsoluteYPosition")+SelfEquip_Frame_Client:GetProperty("AbsoluteYPosition")+SelfEquip_MainFrame:GetProperty("AbsoluteYPosition") +SelfEquip_Frame:GetProperty("AbsoluteXPosition")
		local SetWidth = SelfEquip_Effect:GetProperty("AbsoluteWidth")
		local SetHeight = SelfEquip_Effect:GetProperty("AbsoluteHeight")
		PushEvent("OPEN_ENCHANCESET", SetX,SetY,SetWidth,SetHeight)
	end

end

function SelfEquip_EnchanceSetAttr_MouseLeave()
	PushEvent("CLOSE_ENCHANCESET")
end

function SelfEquip_Refresh_Page_Button( nLevel)
	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		SelfEquip_ShenDing:Disable()
		SelfEquip_ShenDing_tips:Show()
	--	SelfEquip_ShenDing_tips:SetToolTip("#{RWYQ_150707_07}")
	else
		SelfEquip_ShenDing:Enable()
		SelfEquip_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		SelfEquip_Infant:Disable()
		SelfEquip_Infant_tips:Show()
	--	SelfEquip_Infant_tips:SetToolTip("#{RWYQ_150707_01}")
	else
		SelfEquip_Infant:Enable()
		SelfEquip_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		SelfEquip_Wuhun:Disable()
--		SelfEquip_Wuhun_tips:Show()
	--	SelfEquip_Wuhun_tips:SetToolTip("#{RWYQ_150707_02}")
--	else
		SelfEquip_Wuhun:Enable()
		SelfEquip_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		SelfEquip_Xiulian:Disable()
		SelfEquip_Xiulian_tips:Show()
	--	SelfEquip_Xiulian_tips:SetToolTip("#{RWYQ_150707_03}")
	else
		SelfEquip_Xiulian:Enable()
		SelfEquip_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		SelfEquip_Miji:Disable()
		SelfEquip_Miji_tips:Show()
	--	SelfEquip_Miji_tips:SetToolTip("#{RWYQ_150707_04}")
	else
		SelfEquip_Miji:Enable()
		SelfEquip_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		SelfEquip_ZhenYuan:Disable()
		SelfEquip_ZhenYuan_tips:Show()
	--	SelfEquip_ZhenYuan_tips:SetToolTip("#{RWYQ_150707_05}")
	else
		SelfEquip_ZhenYuan:Enable()
		SelfEquip_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		SelfEquip_JunXian:Disable()
		SelfEquip_JunXian_tips:Show()
	--	SelfEquip_JunXian_tips:SetToolTip("#{RWYQ_150707_08}")
	else
		SelfEquip_JunXian:Enable()
		SelfEquip_JunXian_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		SelfEquip_JingMai:Disable()
		SelfEquip_JingMai_tips:Show()
	--	SelfEquip_JingMai_tips:SetToolTip("#{RWYQ_150707_06}")
	else
		SelfEquip_JingMai:Enable()
		SelfEquip_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		SelfEquip_BaoJian:Disable()
		SelfEquip_BaoJian_tips:Show()
	else
		SelfEquip_BaoJian:Enable()
		SelfEquip_BaoJian_tips:Hide()
	end
	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		SelfEquip_WuYi:Enable()
		SelfEquip_WuYi_tips:Hide()
	else
		SelfEquip_WuYi:Disable()
		SelfEquip_WuYi_tips:Show()
	end
	SelfEquip_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		SelfEquip_ShenQi:Enable()
		SelfEquip_ShenQi_tips:Hide()
	else
		SelfEquip_ShenQi:Disable()
		SelfEquip_ShenQi_tips:Show()
	end

	SelfEquip_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		SelfEquip_Armor:Enable()
		SelfEquip_Armor_tips:Hide()
	else
		SelfEquip_Armor:Disable()
		SelfEquip_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		SelfEquip_CangPin:Enable()
		SelfEquip_CangPin_tips:Hide()
	else
		SelfEquip_CangPin:Disable()
		SelfEquip_CangPin_tips:Show()
	end
	
	SelfEquip_RefreshCangPinTip()
end


function SelfEquip_ZhiZunEquipSet_MouseEnter()

--	if SystemSetup:IsClassic() == 1 then
--		local SetX= SelfEquip_ZhiZun_Icon:GetProperty("AbsoluteXPosition") + SelfEquip_FakeObject_Frame:GetProperty("AbsoluteXPosition")+SelfEquip_Frame_Client:GetProperty("AbsoluteXPosition")+SelfEquip_MainFrame:GetProperty("AbsoluteXPosition")+SelfEquip_Frame:GetProperty("AbsoluteXPosition")
--		local SetY = SelfEquip_ZhiZun_Icon:GetProperty("AbsoluteYPosition")  + SelfEquip_FakeObject_Frame:GetProperty("AbsoluteYPosition")+SelfEquip_Frame_Client:GetProperty("AbsoluteYPosition")+SelfEquip_MainFrame:GetProperty("AbsoluteYPosition")+SelfEquip_Frame:GetProperty("AbsoluteYPosition")
--		local SetWidth = SelfEquip_ZhiZun_Icon:GetProperty("AbsoluteWidth")
--		local SetHeight = SelfEquip_ZhiZun_Icon:GetProperty("AbsoluteHeight")
--		PushEvent("SELF_ZHIZUN_EQUIPSET_TIP_OPEN", SetX,SetY,SetWidth,SetHeight)
--	else
--		local SetX= SelfEquip_ZhiZun_Icon:GetProperty("AbsoluteXPosition") + SelfEquip_Effect_BK:GetProperty("AbsoluteXPosition")+SelfEquip_FakeObject_Frame:GetProperty("AbsoluteXPosition")+SelfEquip_Frame_Client:GetProperty("AbsoluteXPosition")+SelfEquip_MainFrame:GetProperty("AbsoluteXPosition") +SelfEquip_Frame:GetProperty("AbsoluteXPosition")
--		local SetY = SelfEquip_ZhiZun_Icon:GetProperty("AbsoluteYPosition")  + SelfEquip_Effect_BK:GetProperty("AbsoluteYPosition")+SelfEquip_FakeObject_Frame:GetProperty("AbsoluteYPosition")+SelfEquip_Frame_Client:GetProperty("AbsoluteYPosition")+SelfEquip_MainFrame:GetProperty("AbsoluteYPosition") +SelfEquip_Frame:GetProperty("AbsoluteXPosition")
--		local SetWidth = SelfEquip_ZhiZun_Icon:GetProperty("AbsoluteWidth")
--		local SetHeight = SelfEquip_ZhiZun_Icon:GetProperty("AbsoluteHeight")
--		PushEvent("SELF_ZHIZUN_EQUIPSET_TIP_OPEN", SetX,SetY,SetWidth,SetHeight)
--	end

end

function SelfEquip_ZhiZunEquipSet_MouseLeave()
--	PushEvent("SELF_ZHIZUN_EQUIPSET_TIP_CLOSE")
end

function SelfEquip_ZhiZunEquipSet_MouseClick()

	if Player:GetData("Is2606S") == 1 then
		return
	end
	
	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()
	SelfEquip_SetTabColor(0)

end

function SelfEquip_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()
	SelfEquip_SetTabColor(0)

end

function SelfEquip_UpdateFiveElementsTip()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		SelfEquip_ZhiZun_Icon:SetToolTip("#{ZZZB_150811_115}")
		return
	end

	local strTips = {}

	for i = 1 , 5 do

		strTips[ i ] = ""

		local bElementsActive 	= Player:IsFiveElements_ElementsActive( i - 1 )
		local bElementsLevel	= Player:GetFiveElements_ElementsLevel( i - 1 )
		local bElementsType		= Player:GetFiveElements_ElementsType( i - 1 )

		if bElementsLevel > 0 then

			if i == 3 or i == 5 then

				local nElementsValue = DataPool:Lua_GetFiveElementsValueWithEquipAndJade( i - 1 )

				local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_141}", g_ElementsValueName[ i ][ 1 ] , nElementsValue )
				strTips[ i ] = strTips[ i ]..tostring(nValueText)

			end

			if i == 1 or i == 2 or i == 4 then
				if g_ElementsValueName[ i ][ bElementsType ] ~= nil then

					local nElementsValue = DataPool:Lua_GetFiveElementsValueWithEquipAndJade( i - 1 )

					local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_141}", g_ElementsValueName[ i ][ bElementsType ] , nElementsValue )

					strTips[ i ] = strTips[ i ]..tostring(nValueText)

				end
			end

		else
			strTips[ i ] = strTips[ i ].."#{ZZZB_150811_117}"
		end
	end

	local stringToolTip = ScriptGlobal_Format("#{ZZZB_150811_116}"  , strTips[ 1 ], strTips[ 2 ], strTips[ 3 ], strTips[ 4 ], strTips[ 5 ])

	SelfEquip_ZhiZun_Icon:SetToolTip(stringToolTip)


end

function SelfEquip_OnYirong()
	--Clear_XSCRIPT()
	--	Set_XSCRIPT_Function_Name("OnUseYiRongGe")
	--	Set_XSCRIPT_ScriptID(889644)
	--	Set_XSCRIPT_ParamCount(0)
	--Send_XSCRIPT()	
	
	Exterior:LuaFnInitExteriorFashionList(1, 1)
	--PushEvent("OPEN_EXTERIOR_FASHION", 1, 1)
end

function SelfEquip_ZongMenSkill_Icon_CLicked()

	if DataPool:Lua_CheckOpenTalent() == 1 then
		ToggleTalentPage()
	end
	if "SelfEquip" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	if g_CurActFlashType == 13 or g_CurActFlashType == 14 then
		PushEvent("OPEN_ZONGMEN_SKILL_GUIDE",g_CurActFlashType)
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "KillRedPoint" )
		Set_XSCRIPT_ScriptID( 998827 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


function SelfEquip_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

-- 九星神器DIY技能
function SelfEquip_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
end

function SelfEquip_Xunzhang_Open()

	--PushEvent("SHOULDERDECO_OPEN", 1)	
	XunzhangSysScript:AskNameBoardExInfo()
end


function SelfEquip_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfEquip_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfEquip_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		SelfEquip_WuYi_Buttontips:Show()
	else
		SelfEquip_WuYi_Buttontips:Hide()
	end
end

function SelfEquip_ShowXbwInfo()
	
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("XBW_SELF_DETAIL_UPDATE_2018")
end

function SelfEquip_UpdateXbwInfo()
	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
		
	if levelIndex >= 0 and levelIndex < BWDH2018:GetMaxLevelIndex() then
	
		local nCurDuanWei1 = Player:Lua_GetXbwData_2018( "CuruanWei1" )
		local nCurDuanWei2 = Player:Lua_GetXbwData_2018( "CuruanWei2" )
		local nCurDuanWei3 = Player:Lua_GetXbwData_2018( "CuruanWei3" )
		
		local szNormalImage = g_SelfEquip_BW_Image[levelIndex][nCurDuanWei1].NormalImage
		local szHoverImage = g_SelfEquip_BW_Image[levelIndex][nCurDuanWei1].HoverImage
		local szPushedImage = g_SelfEquip_BW_Image[levelIndex][nCurDuanWei1].PushedImage
		
		local dw1Name = g_SelfEquip_BW_Dw1_Name[nCurDuanWei1]
		local dw2Name = g_SelfEquip_BW_Dw2_Name[nCurDuanWei2]
		local dw2NameYellow = g_SelfEquip_BW_Dw2_NameYellow[nCurDuanWei2]
		
		if nCurDuanWei1 >= 6 then
			SelfEquip_BW_Match1:Show()
			SelfEquip_BW_Match:Hide()
			SelfEquip_BW_Match1_Button:SetProperty("NormalImage", szNormalImage)
			SelfEquip_BW_Match1_Button:SetProperty("HoverImage", szHoverImage)
			SelfEquip_BW_Match1_Button:SetProperty("PushedImage", szPushedImage)
			local tips = ScriptGlobal_Format("#{BWDH_180804_185}", g_SelfEquip_BW_Level[levelIndex].name, dw1Name..nCurDuanWei3.."#{BWPH_180815_27}")
			SelfEquip_BW_Match1_Button:SetToolTip(tips)
			SelfEquip_BW_Match1_Text:SetText(nCurDuanWei3)
		else
			SelfEquip_BW_Match1:Hide()
			SelfEquip_BW_Match:Show()
			SelfEquip_BW_Match_Button:SetProperty("NormalImage", szNormalImage)
			SelfEquip_BW_Match_Button:SetProperty("HoverImage", szHoverImage)
			SelfEquip_BW_Match_Button:SetProperty("PushedImage", szPushedImage)
			local tips = ScriptGlobal_Format("#{BWDH_180804_185}", g_SelfEquip_BW_Level[levelIndex].name, dw1Name..dw2Name.."#{BWDH_180804_142}")
			SelfEquip_BW_Match_Button:SetToolTip(tips)
			SelfEquip_BW_Match_Text:SetText(dw2NameYellow.."#{BWDH_180804_176}")
		end
	else
		SelfEquip_BW_Match:Hide()
		SelfEquip_BW_Match1:Hide()
	end
end

function SelfEquip_YR_Tips()
	if DataPool:Lua_IsRedPointInUIShow(26) == 1 then
        SelfEquip_Pretty_tips:Show()
    else
        SelfEquip_Pretty_tips:Hide()
	end
end

function SelfEquip_Exterior_Tips()

	-- 人物图鉴第一次上线小红点+子女图鉴第一次上线小红点
	if Pneuma:GetMF(2958)==1 or Pneuma:GetMF(2959)== 1 then 
		SelfEquip_Yirong_Icontips:Show()
		return
	end

	if Exterior:LuaFnIsHaveExteriorShowTip(-1) == 1 then
        SelfEquip_Yirong_Icontips:Show()
		return
	end
	
	if Exterior:LuaFnIsHaveHairColorShowTip() == 1 then
		SelfEquip_Yirong_Icontips:Show()
		return
    end

	if Exterior:LuaFnIsHaveInfantHairColorShowTip() == 1 then
		SelfEquip_Yirong_Icontips:Show()
		return
    end

	if OrnamentsScript:IsHaveOrnamentsShowTip(-1) == 1 then
		SelfEquip_Yirong_Icontips:Show()
		return
	end
	
	SelfEquip_Yirong_Icontips:Hide()

end

function SelfEquip_CloseSameGroupWindow()
	--CloseWindow("SelfEquip", true)
	CloseWindow("NewExterior_Ride", true)
	CloseWindow("NewExterior_Weapon", true)
	CloseWindow("NewExterior_PetPossJian", true)
	CloseWindow("NewExterior_Facestyle", true)
	CloseWindow("NewExterior_HairStyle", true)
	CloseWindow("NewExterior_PlayerFrame", true)
	CloseWindow("NewExterior_DressBox", true)
	CloseWindow("NewExterior_Widget", true)
	CloseWindow("NewExterior_Headdress", true)
	CloseWindow("NewExterior_DressStyle", true)
	CloseWindow("NewExterior_GemEffect", true)
end

function SelfEquip_ShowWGCJUI()
	PushEvent("OPEN_WG_ACHIEVEMENT")
end

function SelfEquip_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfEquip_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfEquip_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		SelfEquip_OtherInfo_ButtonTips:Show()
	else
		SelfEquip_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function SelfEquip_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")

end

function SelfEquip_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfEquip_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function SelfEquip_RefreshCangPinTip()
	local CangPinClassCount = 4
	local bHaveChipToMelt = DataPool:LuaFnIsCanMeltCangPinChip()
	local bTip = 0
	for i = 1, CangPinClassCount do
		if DataPool:LuaFnIsCangPinClassShowTip(i - 1) == 1 then
			bTip = 1
		end
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 16 and g_PageButtonTipsPos[idx] then -- 名物
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfEquip_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfEquip_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		SelfEquip_CangPin_Buttontips:Show()
	else
		SelfEquip_CangPin_Buttontips:Hide()
	end
end


function SelfEquip_ShowPage()

	for i = 1, table.getn(g_SelfEquip_Page) do
		g_SelfEquip_PageButton[i]:Hide()
		g_SelfEquip_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	SelfEquip_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_SelfEquip_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_SelfEquip_Page) do
			if i ~= nPageNumber then
				g_SelfEquip_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_SelfEquip_Page) do
		if SelfEquip_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_SelfEquip_PageButton[g_PageCount]:Show()
			g_SelfEquip_PageButton[g_PageCount]:SetText(g_SelfEquip_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if SelfEquip_IsPageEnable(i) == 1 then
				g_SelfEquip_PageButton[g_PageCount]:Enable()
				g_SelfEquip_PageMask[g_PageCount]:Hide()
			else
				g_SelfEquip_PageButton[g_PageCount]:Disable()
				g_SelfEquip_PageMask[g_PageCount]:Show()
				if g_SelfEquip_Page[i].Tip ~= "" then
					g_SelfEquip_PageMask[g_PageCount]:SetToolTip(g_SelfEquip_Page[i].Tip)
				end
			end
		end
	end
	
	SelfEquip_RefreshWuYiTip()
	SelfEquip_RefreshOtherInfoTip()
	SelfEquip_RefreshCangPinTip()
	
end

function SelfEquip_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		--SelfData_SelfEquip_Down(0);
	elseif idx == 2 then--资料
		SelfEquip_Page_SelfData()
	elseif idx == 3 then--珍兽
		SelfEquip_Pet_Page_Switch()
	elseif idx == 4 then--子女
		SelfEquip_Infant_Switch()
	elseif idx == 5 then--武魂
		SelfEquip_Wuhun_Switch()
	elseif idx == 6 then--修炼
		SelfEquip_XiuLian_Page_Switch()
	elseif idx == 7 then--秘籍
		SelfEquip_Miji_Page_Switch()
	elseif idx == 8 then--真元
		SelfEquip_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		SelfEquip_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		SelfEquip_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		SelfEquip_JunXian_Page_Switch()
	elseif idx == 12 then--宝鉴
		SelfEquip_OpenBaoJian()
	elseif idx == 13 then--武意
		SelfEquip_OpenWuYi()
	elseif idx == 14 then--神器
		SelfEquip_OpenShenQi()
	elseif idx == 15 then--星盘
		SelfEquip_Armor_Page_Switch()
	elseif idx == 16 then--名物
		SelfEquip_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		Other_Info_Page_Switch()
	end
end

function SelfEquip_CheckPage(idx)
	if idx == 1 then--装备
		return 1
	elseif idx == 2 then--资料
		return 1
	elseif idx == 3 then--珍兽
		return 1
	elseif idx == 4 then--子女
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 5 then--武魂
		return 1
	elseif idx == 6 then--修炼
		return 1
	elseif idx == 7 then--秘籍
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 8 then--真元
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 9 then--经脉
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 10 then--神鼎
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 11 then--侠印
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 12 then--宝鉴
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 13 then--武意
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 14 then--神器
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 15 then--星盘
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 16 then--名物
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 17 then--其他
		return 1
	end
	return 0
end

function SelfEquip_IsPageEnable(idx)
	
	local nLevel = Player:GetLevel()
	
	if idx == 1 then--装备
		return 1
	elseif idx == 2 then--资料
		return 1
	elseif idx == 3 then--珍兽
		return 1
	elseif idx == 4 then--子女
		local InfantCount = Infant:GetInfantCount();
		if ( nLevel < 50 ) or ( InfantCount <= 0 ) then
			return 0
		end
		return 1
	elseif idx == 5 then--武魂
		return 1
	elseif idx == 6 then--修炼
		if ( nLevel < 70 ) then
			return 0
		end
		return 1
	elseif idx == 7 then--秘籍
		local ret = DataPool:Lua_IsMissionHaveDone(1651)
		if ( nLevel < 75 ) or ( ret == 0 ) then
			return 0
		end
		return 1
	elseif idx == 8 then--真元
		local ret = DataPool:Lua_IsMissionHaveDone(1600)
		if ( nLevel < 80 ) or ( ret == 0 ) then
			return 0
		end
		return 1
	elseif idx == 9 then--经脉
		local ret = DataPool:Lua_IsMissionHaveDone(1554)
		if ( nLevel < 90 ) or ( ret == 0 )  then
			return 0
		end
		return 1
	elseif idx == 10 then--神鼎
		if ( nLevel < 15 ) then
			return 0
		end
		return 1
	elseif idx == 11 then--侠印
		if ( nLevel < 85 ) then
			return 0
		end
		return 1
	elseif idx == 12 then--宝鉴
		if ( nLevel < 85 ) then
			return 0
		end
		return 1
	elseif idx == 13 then--武意
		if (MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
			return 1
		end
		return 0
	elseif idx == 14 then--神器
		if (DataPool:Lua_IsMissionHaveDone(1950) == 1) then
			return 1
		end
		return 0
	elseif idx == 15 then--星盘
		if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
			return 1
		end
		return 0
	elseif idx == 16 then--名物
		if nLevel < 30 then
			return 0
		end
		return 1
	elseif idx == 17 then--其他
		return 1
	end
	return 0
end

function SelfEquip_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


