-- 数据池中定义的装备数据.
--HEQUIP_WEAPON		=0,		//武器	WEAPON
--HEQUIP_CAP			=1,		//帽子	DEFENCE
--HEQUIP_ARMOR		=2,		//衣服	DEFENCE
--HEQUIP_CUFF			=3,		//手套	DEFENCE
--HEQUIP_BOOT			=4,		//鞋	DEFENCE
--HEQUIP_SASH			=5,		//腰带	ADORN
--HEQUIP_RING			=6,		//戒子	ADORN
--HEQUIP_NECKLACE	=7,		//项链	ADORN
--HEQUIP_DARK		=8,		//骑乘----已修改为暗器by houzhifang
--HEQUIP_BAG			=9,		//行囊                            护符
--HEQUIP_BOX			=10,	//箱格
--HEQUIP_RING_2		=11,	//第二个戒指	ADORN
--HEQUIP_CHARM		=12,	//护符	            ADORN
--HEQUIP_CHARM_2		=13,	//第二个护符	    ADORN
--HEQUIP_WRIST		=14,	//护腕	DEFENCE
--HEQUIP_SHOULDER		=15,	//护肩	DEFENCE
--HEQUIP_DRESS		=16,	//时装


--------------------------------------------------------------------------------
-- 装备按钮数据定义
--
local  g_WEAPON;		--武器
local  g_ARMOR;			--衣服
local  g_CAP;			--帽子
local  g_CUFF;			--护腕
local  g_BOOT;			--鞋
local  g_RING;			--戒子
local  g_SASH;			--腰带
local  g_NECKLACE;		--项链
local  g_Dark;			--坐骑---已修改为暗器
local  g_Charm;			-- 护符
local  g_Charm2;		-- 护符2
local  g_Shoulder;		-- 护肩
local  g_Glove;			-- 手套
local  g_Ring2;			-- 戒指2
local  g_LongWen;		-- 龙纹
local  g_RL;			--符石传说

local g_Cur_Name = "";
local g_TargetEquip_Cur_ZoneWorldId = -1
local g_objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;

local TARGETEQUIP_TAB_TEXT = {};

local g_TargetEquip_Frame_UnifiedPosition;

local g_TargetEquip_Gem_Check_Buttons_red   = {}  --- 不能进行一键换宝石
local g_TargetEquip_Gem_Check_Buttons_green = {}  --- 可以进行一键换宝石
local g_TargetEquip_Gem_Check_Buttons_BK    = {}  --- 一键换宝石未学会时的图标
local g_TargetEquip_Gem_Contain_Num         = 18

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

local g_TargetEquip_BW_Level = 
{
[0] = { name= "#{BWDH_210908_01}"},
[1] = { name= "#{BWDH_180804_13}"},
[2] = { name= "#{BWDH_180804_14}"},
[3] = { name= "#{BWDH_250113_06}"},
}

local g_TargetEquip_BW_Dw1_Name = 
{
[1] = "#{BWDH_180804_131}",
[2] = "#{BWDH_180804_132}",
[3] = "#{BWDH_180804_133}",
[4] = "#{BWDH_180804_134}",
[5] = "#{BWDH_180804_135}",
[6] = "#{BWDH_180804_136}",
}

local g_TargetEquip_BW_Dw2_Name = 
{
[1] = "#{BWDH_180804_141}",
[2] = "#{BWDH_180804_140}",
[3] = "#{BWDH_180804_139}",
[4] = "#{BWDH_180804_138}",
[5] = "#{BWDH_180804_137}",
}

local g_TargetEquip_BW_Dw2_NameYellow = 
{
[1] = "#{BWDH_180804_175}",
[2] = "#{BWDH_180804_174}",
[3] = "#{BWDH_180804_173}",
[4] = "#{BWDH_180804_172}",
[5] = "#{BWDH_180804_171}",
}

local g_TargetEquip_BW_Image = 
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

local g_TargetEquip_PrettyImage =
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

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_TargetEquip_Page = {
	[1] = {Text = "#{INTERFACE_XML_877}",		NeedCheck = 0, Tip = ""},
	[2] = {Text = "#{INTERFACE_XML_882}",		NeedCheck = 0, Tip = ""},
	[3] = {Text = "#{INTERFACE_XML_854}",		NeedCheck = 0, Tip = ""},
	[4] = {Text = "#{ZNJCS_130825_7}",			NeedCheck = 0, Tip = ""},
	[5] = {Text = "#{WH_xml_XX(95)}",			NeedCheck = 0, Tip = ""},
	[6] = {Text = "#{WLMJ_130121_54}",			NeedCheck = 0, Tip = ""},
	[7] = {Text = "#{ZYXT_120528_154}",			NeedCheck = 0, Tip = ""},
	[8] = {Text = "#{MPJJ_XT_XML_01}",  	 	NeedCheck = 0, Tip = ""},
	[9] = {Text = "#{XLDL_140606_04}",			NeedCheck = 0, Tip = ""},
	[10] = {Text = "#{JXJW_140822_22}",  	 	NeedCheck = 0, Tip = ""},
	[11] = {Text = "#{ZZZB_150811_113}",		NeedCheck = 0, Tip = ""},
	[12] = {Text = "#{WYXT_20170807_86}",		NeedCheck = 0, Tip = ""},
	[13] = {Text = "#{JXSQ_170829_216}",		NeedCheck = 0, Tip = ""},
	[14] = {Text = "#{NJBZ_220816_11}",			NeedCheck = 0, Tip = ""},
	[15] = {Text = "#{CPSJ_260112_1}",			NeedCheck = 0, Tip = ""},
}

local g_TargetPageButton = {}
local g_TargetPageCount = 0
local g_TargetPageOrder = {}

local g_TargetEquip_25_UnifiedPosition
local g_TargetEquip_16_UnifiedPosition
local g_TargetEquip_BaoShiCheck_15_UnifiedPosition
local g_TargetEquip_BaoShiCheck_16_UnifiedPosition

function TargetEquip_PreLoad()

	-- 打开界面
	this:RegisterEvent("MAINTARGET_CHANGED",false);
	this:RegisterEvent("OTHERPLAYER_UPDATE_EQUIP",true);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("CLOSE_TARGET_EQUIP",false);
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("OTHER_FIVEELEMENTS_UPDATE",false)

	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function TargetEquip_OnLoad()

	-- action buttion 按钮
	g_WEAPON			= TargetEquip_Equip11;		--武器
	g_ARMOR			= TargetEquip_Equip12;		--衣服
	g_CAP					= TargetEquip_Equip1;			--帽子
	g_CUFF				= TargetEquip_Equip8;			--护腕
	g_BOOT				= TargetEquip_Equip4;			--鞋
	g_RING					= TargetEquip_Equip6;			--戒子
	g_SASH				= TargetEquip_Equip7;			--腰带
	g_NECKLACE		= TargetEquip_Equip13;		--项链
	g_Dark					= TargetEquip_Equip14;		--暗器
	g_Charm				= TargetEquip_Equip9;			--护符
	g_Charm2				= TargetEquip_Equip10;		--护符2
	g_Shoulder			= TargetEquip_Equip3;			--护肩
	g_Glove				= TargetEquip_Equip2;			--手套
	g_Ring2				= TargetEquip_Equip5;			--戒指2
	g_LongWen			= TargetEquip_Equip25;		--龙纹
	g_RL						= TargetEquip_Equip16;		--令牌

	m_ZhiZunAnimate[1]	= TargetEquip_Equip1_Animate					--帽子
	m_ZhiZunAnimate[2]	= TargetEquip_Equip12_Animate				--衣服
	m_ZhiZunAnimate[3]	= TargetEquip_Equip2_Animate					--手套
	m_ZhiZunAnimate[4]	= TargetEquip_Equip4_Animate					--鞋
	m_ZhiZunAnimate[5]	= TargetEquip_Equip7_Animate					--腰带
	m_ZhiZunAnimate[6]	= TargetEquip_Equip6_Animate					--戒指
	m_ZhiZunAnimate[7]	= TargetEquip_Equip13_Animate				--项链
	m_ZhiZunAnimate[11]	= TargetEquip_Equip5_Animate				--戒指2
	m_ZhiZunAnimate[12]	= TargetEquip_Equip9_Animate				--护符
	m_ZhiZunAnimate[13]	= TargetEquip_Equip10_Animate			--护符2
	m_ZhiZunAnimate[14]	= TargetEquip_Equip8_Animate				--护腕			
	m_ZhiZunAnimate[15]	= TargetEquip_Equip3_Animate				--护肩
	
	TARGETEQUIP_TAB_TEXT = {
		[0] = "装备",
		"资料",
		"秘籍",
		"珍兽",
		"骑乘",
		"经脉",
	};

    --- 宝石装备位
    g_TargetEquip_Gem_Check_Buttons_red[1]  = TargetEquip_BaoShiCheckRed11
    g_TargetEquip_Gem_Check_Buttons_red[2]  = TargetEquip_BaoShiCheckRed3
    g_TargetEquip_Gem_Check_Buttons_red[3]  = TargetEquip_BaoShiCheckRed7
    g_TargetEquip_Gem_Check_Buttons_red[4]  = TargetEquip_BaoShiCheckRed8
    g_TargetEquip_Gem_Check_Buttons_red[5]  = TargetEquip_BaoShiCheckRed9
    g_TargetEquip_Gem_Check_Buttons_red[6]  = TargetEquip_BaoShiCheckRed10
    g_TargetEquip_Gem_Check_Buttons_red[7]  = TargetEquip_BaoShiCheckRed12
    g_TargetEquip_Gem_Check_Buttons_red[8]  = TargetEquip_BaoShiCheckRed1
    g_TargetEquip_Gem_Check_Buttons_red[9]  = TargetEquip_BaoShiCheckRed2
    g_TargetEquip_Gem_Check_Buttons_red[10] = TargetEquip_BaoShiCheckRed4
    g_TargetEquip_Gem_Check_Buttons_red[11] = TargetEquip_BaoShiCheckRed5
    g_TargetEquip_Gem_Check_Buttons_red[12] = TargetEquip_BaoShiCheckRed6
    g_TargetEquip_Gem_Check_Buttons_red[13] = TargetEquip_BaoShiCheckRed13
    g_TargetEquip_Gem_Check_Buttons_red[14] = TargetEquip_BaoShiCheckRed14
    g_TargetEquip_Gem_Check_Buttons_red[15] = TargetEquip_BaoShiCheckRed15
	g_TargetEquip_Gem_Check_Buttons_red[17] = TargetEquip_BaoShiCheckRed16
	--g_TargetEquip_Gem_Check_Buttons_red[19] = TargetEquip_ZongMenSkill_TalentEquip_GemRed

    g_TargetEquip_Gem_Check_Buttons_green[1]  = TargetEquip_BaoShiCheckGreen11
    g_TargetEquip_Gem_Check_Buttons_green[2]  = TargetEquip_BaoShiCheckGreen3
    g_TargetEquip_Gem_Check_Buttons_green[3]  = TargetEquip_BaoShiCheckGreen7
    g_TargetEquip_Gem_Check_Buttons_green[4]  = TargetEquip_BaoShiCheckGreen8
    g_TargetEquip_Gem_Check_Buttons_green[5]  = TargetEquip_BaoShiCheckGreen9
    g_TargetEquip_Gem_Check_Buttons_green[6]  = TargetEquip_BaoShiCheckGreen10
    g_TargetEquip_Gem_Check_Buttons_green[7]  = TargetEquip_BaoShiCheckGreen12
    g_TargetEquip_Gem_Check_Buttons_green[8]  = TargetEquip_BaoShiCheckGreen1
    g_TargetEquip_Gem_Check_Buttons_green[9]  = TargetEquip_BaoShiCheckGreen2
    g_TargetEquip_Gem_Check_Buttons_green[10] = TargetEquip_BaoShiCheckGreen4
    g_TargetEquip_Gem_Check_Buttons_green[11] = TargetEquip_BaoShiCheckGreen5
    g_TargetEquip_Gem_Check_Buttons_green[12] = TargetEquip_BaoShiCheckGreen6
    g_TargetEquip_Gem_Check_Buttons_green[13] = TargetEquip_BaoShiCheckGreen13
    g_TargetEquip_Gem_Check_Buttons_green[14] = TargetEquip_BaoShiCheckGreen14
    g_TargetEquip_Gem_Check_Buttons_green[15] = TargetEquip_BaoShiCheckGreen15
	g_TargetEquip_Gem_Check_Buttons_green[17] = TargetEquip_BaoShiCheckGreen16
	--g_TargetEquip_Gem_Check_Buttons_green[19] = TargetEquip_ZongMenSkill_TalentEquip_GemGreen

    g_TargetEquip_Gem_Check_Buttons_BK[1]  = TargetEquip_BaoShiCheckBK1
    g_TargetEquip_Gem_Check_Buttons_BK[2]  = TargetEquip_BaoShiCheckBK2
    g_TargetEquip_Gem_Check_Buttons_BK[3]  = TargetEquip_BaoShiCheckBK3
    g_TargetEquip_Gem_Check_Buttons_BK[4]  = TargetEquip_BaoShiCheckBK4
    g_TargetEquip_Gem_Check_Buttons_BK[5]  = TargetEquip_BaoShiCheckBK5
    g_TargetEquip_Gem_Check_Buttons_BK[6]  = TargetEquip_BaoShiCheckBK6
    g_TargetEquip_Gem_Check_Buttons_BK[7]  = TargetEquip_BaoShiCheckBK7
    g_TargetEquip_Gem_Check_Buttons_BK[8]  = TargetEquip_BaoShiCheckBK8
    g_TargetEquip_Gem_Check_Buttons_BK[9]  = TargetEquip_BaoShiCheckBK9
    g_TargetEquip_Gem_Check_Buttons_BK[10] = TargetEquip_BaoShiCheckBK10
    g_TargetEquip_Gem_Check_Buttons_BK[11] = TargetEquip_BaoShiCheckBK11
    g_TargetEquip_Gem_Check_Buttons_BK[12] = TargetEquip_BaoShiCheckBK12
    g_TargetEquip_Gem_Check_Buttons_BK[13] = TargetEquip_BaoShiCheckBK13
    g_TargetEquip_Gem_Check_Buttons_BK[14] = TargetEquip_BaoShiCheckBK14
    g_TargetEquip_Gem_Check_Buttons_BK[15] = TargetEquip_BaoShiCheckBK15
	g_TargetEquip_Gem_Check_Buttons_BK[17] = TargetEquip_BaoShiCheckBK16
	--g_TargetEquip_Gem_Check_Buttons_BK[19] = TargetEquip_ZongMenSkill_TalentEquip_GemBK

    TargetEquip_tips1 : Hide()
    TargetEquip_tips2 : Hide()
    TargetEquip_tips3 : Hide()
    TargetEquip_tips4 : Hide()
    TargetEquip_tips5 : Hide()
    TargetEquip_tips6 : Hide()
    TargetEquip_tips7 : Hide()
    TargetEquip_tips8 : Hide()
    TargetEquip_tips9 : Hide()
    TargetEquip_tips10 : Hide()
    TargetEquip_tips11 : Hide()
    TargetEquip_tips12 : Hide()
    TargetEquip_tips13 : Hide()
    TargetEquip_tips14 : Hide()
    TargetEquip_tips15 : Hide()
	TargetEquip_tips16 : Hide()

	g_TargetEquip_Frame_UnifiedPosition=TargetEquip_Frame:GetProperty("UnifiedPosition");
	
	TargetEquip_FightScore_Button:SetToolTip("#{PFBJ_160106_1}")
	
	g_TargetPageButton[1] = TargetEquip_SelfEquip
	g_TargetPageButton[2] = TargetEquip_TargetData
	g_TargetPageButton[3] = TargetEquip_Pet
	g_TargetPageButton[4] = TargetEquip_TargetInfant
	g_TargetPageButton[5] = TargetEquip_TargetWuhun
	g_TargetPageButton[6] = TargetEquip_Miji
	g_TargetPageButton[7] = TargetEquip_ZhenYuan
	g_TargetPageButton[8] = TargetEquip_JingMai
	g_TargetPageButton[9] = TargetEquip_ShenDing
	g_TargetPageButton[10] = TargetEquip_JueWei
	g_TargetPageButton[11] = TargetEquip_BaoJian
	g_TargetPageButton[12] = TargetEquip_WuYi
	g_TargetPageButton[13] = TargetEquip_ShenQi
	g_TargetPageButton[14] = TargetEquip_Armor
	g_TargetPageButton[15] = TargetEquip_CangPin
	
	g_TargetEquip_25_UnifiedPosition = TargetEquip_Equip25:GetProperty("UnifiedPosition")
	g_TargetEquip_16_UnifiedPosition = TargetEquip_Equip16:GetProperty("UnifiedPosition")
	g_TargetEquip_BaoShiCheck_15_UnifiedPosition = TargetEquip_BaoShiCheckRed15:GetProperty("UnifiedPosition")
	g_TargetEquip_BaoShiCheck_16_UnifiedPosition = TargetEquip_BaoShiCheckRed16:GetProperty("UnifiedPosition")
	
end
function TargetEquip_SetTabColor(idx)

	-- local i = 0;
	-- local selColor = "#e010101#Y";
	-- local noselColor = "#e010101";
	-- local tab = {
								-- [0] = TargetEquip_SelfEquip,
								-- TargetEquip_TargetData,
								-- TargetEquip_Miji,
								-- TargetEquip_Pet,
								-- TargetEquip_Ride,
								-- TargetEquip_JingMai,
							-- };

	-- while i < 6 do
		-- if(i == idx) then
			-- tab[i]:SetText(selColor..TARGETEQUIP_TAB_TEXT[i]);
		-- else
			-- tab[i]:SetText(noselColor..TARGETEQUIP_TAB_TEXT[i]);
		-- end
		-- i = i + 1;
	-- end
end

-- OnEvent
function TargetEquip_OnEvent(event)

	if ( event == "MAINTARGET_CHANGED" and tonumber(arg0) == -1) then

		return;
	end

	if( "HIDE_ON_SCENE_TRANSED" == event) then
		this : Hide();
		return;
	end

	-- 装备变化时刷新装备.
	if("OTHERPLAYER_UPDATE_EQUIP" == event) then

		if (not CachedTarget:IsPresent(1)) then
			return;
		end

		if (not CachedTarget:CanGetTargetEquip()) then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end

		g_objCared = CachedTarget:GetData("NPCID", 1)
		if (type(g_objCared) ~="number") then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end

		local otherUnionPos = Variable:GetVariable("OtherUnionPos");
		if(otherUnionPos ~= nil) then
			TargetEquip_Frame:SetProperty("UnifiedPosition", otherUnionPos);
		end
		TargetEquip_SetTabColor(0);
		TargetEquip_SelfEquip:SetCheck(1);
		TargetEquip_TargetData:SetCheck(0);

		TargetEquip_FakeObject:SetFakeObject("");
		CachedTarget:TargetEquip_ChangeModel();
		TargetEquip_FakeObject:SetFakeObject("Target");

		-- 开始关心OBJ
		TargetEquip_BeginCareObject(g_objCared);
		TargetEquip_OnUpdateShow();
		TargetEquip_RefreshEquip();

		TargetEquip_ShowPage()
		
		this:Show();
		return;
	end

	if( "CLOSE_TARGET_EQUIP" == event ) then

		TargetEquip_CloseUI();
		return;
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_objCared) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if( arg1=="destroy") then
			TargetEquip_CloseUI();
			return;
		end

	elseif (event == "ADJEST_UI_POS" ) then
		TargetEquip_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TargetEquip_Frame_On_ResetPos()
	elseif event == "OTHER_FIVEELEMENTS_UPDATE"  and this:IsVisible() then
		TargetEquip_UpdateFiveElementsTip()
		return
	end

end

-- 更新主角基本信息
function TargetEquip_OnUpdateShow()

	local nNumber = 0;
	local nMaxnumber = 0;
	local strName = "";

	-- 得到名字
  strName = CachedTarget:GetData("NAME", 1);
  if strName == nil then
  	return
  end

  g_Cur_Name = strName;
  TargetEquip_PageHeader:SetText("#gFF0FA0" .. strName );

  g_TargetEquip_Cur_ZoneWorldId = CachedTarget:GetData("ZONEWORLDID", 1);

	-- 得到称号
	strName = CachedTarget:GetData("TITLE", 1)
	TargetEquip_Agname:SetText( ""..strName );

	-- 得到帮派
	strName = CachedTarget:GetData("GUILD", 1)
	-- 得到目标的和自己的ZoneWorldID
	local targetZoneWorldID = CachedTarget:GetData("ZONEWORLDID", 1)
    local selfZoneWorldID   = DataPool:GetSelfZoneWorldID()
    --- 只有自己的ZoneWorldID与传进来的参数不一致的时候，才需要显示服务器名
	if strName ~= "" then
		if selfZoneWorldID ~= nil and selfZoneWorldID ~= -1 and targetZoneWorldID ~= 0 and targetZoneWorldID ~= -1 and selfZoneWorldID ~= targetZoneWorldID then
			strName = strName.. "@" ..DataPool:GetServerName( targetZoneWorldID )
		end
	end
	TargetEquip_Confraternity:SetText( ""..strName );

	-- 得到等级
	nNumber = CachedTarget:GetData("LEVEL", 1);
	local nTargetLevel = nNumber
	local nTargetIsPlayer = CachedTarget:GetData( "ISPLAYER" )
	local nTargetCompatPKLevel = CachedTarget:GetData( "LEVEL_CompatPKLV" )
	local isCompatPKServer = Player:GetData("IsPKServer_JD")
	if isCompatPKServer == 1 and nTargetIsPlayer == 1 and nTargetCompatPKLevel < nTargetLevel then
		local LevelText = ScriptGlobal_Format("#{CTPK_251016_2}",tostring(nTargetCompatPKLevel));
		local strLevelToolTip = ScriptGlobal_Format("#{CTPK_251016_3}",tostring(nTargetLevel));
		TargetEquip_Level:SetText(LevelText);
		TargetEquip_Level:SetToolTip(strLevelToolTip);
		TargetEquip_PKLevel_Image:Show()
	else
		local LevelText = ScriptGlobal_Format("#{CTPK_251016_1}",tostring(nTargetLevel));
		TargetEquip_Level:SetText(LevelText);
		TargetEquip_Level:SetToolTip("");
		TargetEquip_PKLevel_Image:Hide()
	end
	
	--外观阶级显示
	local tarWGLevel = CachedTarget:GetData("WGCJLEVEL")
  if tarWGLevel >= 1 and tarWGLevel <= table.getn(g_TargetEquip_PrettyImage) then
		TargetEquip_Pretty:SetProperty("Image", g_TargetEquip_PrettyImage[tarWGLevel][1])
	end

	-- 得到配偶信息
	local szConsort = SystemSetup:GetPrivateInfo("other","Consort");
	TargetEquip_Spouse:SetText(szConsort);

	--得到结婚时间
	strName = SystemSetup:GetPrivateInfo("other","Weddingtime");
	TargetEquip_Date:SetText(strName)

	--得到战斗评分
	nNumber = CachedTarget:GetData("BATTLESCORE", 1);
	TargetEquip_FightScore:SetText("#{ZDPF_130115_01}"..tostring(nNumber));
	local equipScoreHH = CachedTarget:GetData("EQUIPSCOREHH");
	if Player:GetData("Is2606S") == 1 then
		TargetEquip_FightScore:SetToolTip(ScriptGlobal_Format("#{QXF_260623_133}",equipScoreHH))
	else
		TargetEquip_FightScore:SetToolTip(ScriptGlobal_Format("#{ZDPF_130115_02}",equipScoreHH))
	end

	-- 门派
	local menpai = CachedTarget:GetData("MEMPAI",1);
	local strMenpai = "";

	-- 得到门派名称.
	if(0 == menpai) then
		strMenpai = "少林";

	elseif(1 == menpai) then
		strMenpai = "明教";

	elseif(2 == menpai) then
		strMenpai = "丐帮";

	elseif(3 == menpai) then
		strMenpai = "武当";

	elseif(4 == menpai) then
		strMenpai = "峨嵋";

	elseif(5 == menpai) then
		strMenpai = "星宿";

	elseif(6 == menpai) then
		strMenpai = "天龙";

	elseif(7 == menpai) then
		strMenpai = "天山";

	elseif(8 == menpai) then
		strMenpai = "逍遥";

	elseif(9 == menpai) then
		strMenpai = "无门派";

	elseif(10== menpai) then
		strMenpai = "慕容";

	elseif(11== menpai) then
		strMenpai = "唐门";
		
	elseif(12== menpai) then
		strMenpai = "鬼谷";
		
	elseif(13== menpai) then
		strMenpai = "#{XQ_MP_15}";--桃花岛
	
	elseif(14== menpai) then
		strMenpai = "#{XMPHM_210604_01}";
		
	elseif(15== menpai) then--menpai15 mptodo
		strMenpai = "#{GMGameInterface_Script_DataPool_Info_ERenGu}";	
	end

	-- 设置显示的门派.
	TargetEquip_MenPai:SetText("门派:" .. strMenpai);

	-- 个人说明
	local szLuck = SystemSetup:GetPrivateInfo("other","luck");
	TargetEquip_Message:SetText(szLuck);

    -- 显示服务器名
    TargetEquip_SetFuwuqi( )

	local bEquipMaster = CachedTarget:GetEquipMasterFlag();
	if bEquipMaster == 1 then
		TargetEquip_BaiBingJingTong:Show()
	else
		TargetEquip_BaiBingJingTong:Hide()
	end

	local levelIndex = Player:Lua_GetOtherXbwData_2018( "LevelIndex" )
		
	if levelIndex >= 0 and levelIndex < BWDH2018:GetMaxLevelIndex() then
	
		local nCurDuanWei1 = Player:Lua_GetOtherXbwData_2018( "CuruanWei1" )
		local nCurDuanWei2 = Player:Lua_GetOtherXbwData_2018( "CuruanWei2" )
		local nCurDuanWei3 = Player:Lua_GetOtherXbwData_2018( "CuruanWei3" )
		
		local szNormalImage = g_TargetEquip_BW_Image[levelIndex][nCurDuanWei1].NormalImage
		local szHoverImage = g_TargetEquip_BW_Image[levelIndex][nCurDuanWei1].HoverImage
		local szPushedImage = g_TargetEquip_BW_Image[levelIndex][nCurDuanWei1].PushedImage
		
		local dw1Name = g_TargetEquip_BW_Dw1_Name[nCurDuanWei1]
		local dw2Name = g_TargetEquip_BW_Dw2_Name[nCurDuanWei2]
		local dw2NameYellow = g_TargetEquip_BW_Dw2_NameYellow[nCurDuanWei2]
		
		if nCurDuanWei1 >= 6 then
			TargetEquip_BW_Match1:Show()
			TargetEquip_BW_Match:Hide()
			TargetEquip_BW_Match1_Button:SetProperty("NormalImage", szNormalImage)
			TargetEquip_BW_Match1_Button:SetProperty("HoverImage", szHoverImage)
			TargetEquip_BW_Match1_Button:SetProperty("PushedImage", szPushedImage)
			local tips = ScriptGlobal_Format("#{BWDH_180804_185}", g_TargetEquip_BW_Level[levelIndex].name, dw1Name..nCurDuanWei3.."#{BWPH_180815_27}")
			TargetEquip_BW_Match1_Button:SetToolTip(tips)
			TargetEquip_BW_Match1_Text:SetText(nCurDuanWei3)
		else
			TargetEquip_BW_Match1:Hide()
			TargetEquip_BW_Match:Show()
			TargetEquip_BW_Match_Button:SetProperty("NormalImage", szNormalImage)
			TargetEquip_BW_Match_Button:SetProperty("HoverImage", szHoverImage)
			TargetEquip_BW_Match_Button:SetProperty("PushedImage", szPushedImage)
			local tips = ScriptGlobal_Format("#{BWDH_180804_185}", g_TargetEquip_BW_Level[levelIndex].name, dw1Name..dw2Name.."#{BWDH_180804_142}")
			TargetEquip_BW_Match_Button:SetToolTip(tips)
			TargetEquip_BW_Match_Text:SetText(dw2NameYellow.."#{BWDH_180804_176}")
		end
	else
		TargetEquip_BW_Match:Hide()
		TargetEquip_BW_Match1:Hide()
	end

	
	local nLevel = CachedTarget:GetData("LEVEL", 1);
	if nLevel >= 60 then
		TargetEquip_Visual_Icon:Show()
	else
		TargetEquip_Visual_Icon:Hide()
	end
	
	if Player:GetData("IsOriginalJD") == 1 then
		TargetEquip_Rune:Hide()
	else
		TargetEquip_Rune:Show()
	end
	
	if Player:GetData("Is2606S") == 1 then
		TargetEquip_Rune:Hide()
		TargetEquip_ZhiZun_Icon:Hide()
		TargetEquip_ShenDing_Icon:Hide()
		
		g_LongWen:Hide()
		
		g_RL:SetProperty("UnifiedPosition", g_TargetEquip_25_UnifiedPosition);
		TargetEquip_BaoShiCheckRed16:SetProperty("UnifiedPosition", g_TargetEquip_BaoShiCheck_15_UnifiedPosition);
		TargetEquip_BaoShiCheckGreen16:SetProperty("UnifiedPosition", g_TargetEquip_BaoShiCheck_15_UnifiedPosition);
		TargetEquip_tips16:SetProperty("UnifiedPosition", g_TargetEquip_BaoShiCheck_15_UnifiedPosition);
		TargetEquip_BaoShiCheckBK16:SetProperty("UnifiedPosition", g_TargetEquip_BaoShiCheck_15_UnifiedPosition);
	else
		TargetEquip_Rune:Show()
		TargetEquip_ZhiZun_Icon:Show()
		TargetEquip_ShenDing_Icon:Show()
		
		g_LongWen:Show()
		
		g_RL:SetProperty("UnifiedPosition", g_TargetEquip_16_UnifiedPosition);
		TargetEquip_BaoShiCheckRed16:SetProperty("UnifiedPosition", g_TargetEquip_BaoShiCheck_16_UnifiedPosition);
		TargetEquip_BaoShiCheckGreen16:SetProperty("UnifiedPosition", g_TargetEquip_BaoShiCheck_16_UnifiedPosition);
		TargetEquip_tips16:SetProperty("UnifiedPosition", g_TargetEquip_BaoShiCheck_16_UnifiedPosition);
		TargetEquip_BaoShiCheckBK16:SetProperty("UnifiedPosition", g_TargetEquip_BaoShiCheck_16_UnifiedPosition);
	end
	
end


-- 刷新装备
function TargetEquip_RefreshEquip()

	--  清空按钮显示图标
	g_WEAPON:SetActionItem(-1);			--武器
	g_CAP:SetActionItem(-1);				--帽子
	g_ARMOR:SetActionItem(-1);			--盔甲
	g_CUFF:SetActionItem(-1);				--护腕
	g_BOOT:SetActionItem(-1);				--鞋
	g_SASH:SetActionItem(-1);				--腰带
	g_RING:SetActionItem(-1);				--戒子
	g_NECKLACE:SetActionItem(-1);		--项链
	g_Dark:SetActionItem(-1);				--坐骑
	g_Charm:SetActionItem(-1);			-- 护符
	g_Charm2:SetActionItem(-1);			-- 护符2
	g_Shoulder:SetActionItem(-1);		-- 护肩
	g_Glove:SetActionItem(-1);			-- 手套
	g_Ring2:SetActionItem(-1);			-- 戒指2
	g_LongWen:SetActionItem(-1);		-- 龙纹 g_RL
	g_RL:SetActionItem(-1);			--符石传说
	TargetEquip_ZongMenSkill_TalentEquip:SetActionItem(-1)
	
	local ActionWeapon 		= EnumAction(0, "targetequip");
	local ActionCap    		= EnumAction(1, "targetequip");
	local ActionArmor  		= EnumAction(2, "targetequip");
	local ActionGlove		= EnumAction(3, "targetequip");
	local ActionBoot   		= EnumAction(4, "targetequip");
	local ActionSash   		= EnumAction(5, "targetequip");
	local ActionRing    	= EnumAction(6, "targetequip");
	local ActionNecklace	= EnumAction(7, "targetequip");
	local ActionDark		= EnumAction(17, "targetequip");    --修改为暗器  by houzhifang
	local ActionRing2		= EnumAction(11, "targetequip");
	local ActionCharm		= EnumAction(12, "targetequip");
	local ActionCharm2		= EnumAction(13, "targetequip");
	local ActionCuff  		= EnumAction(14, "targetequip");
	local ActionShoulder	= EnumAction(15, "targetequip");
	local ActionLongWen		= EnumAction(19, "targetequip");
	local ActionRL		= EnumAction(20, "targetequip");
	local ActionZongMenEquip = EnumAction(23, "targetequip")

	-- 显示人身上的武器装备
	g_WEAPON:SetActionItem(ActionWeapon:GetID());			--武器
	g_CAP:SetActionItem(ActionCap:GetID());						--帽子
	g_ARMOR:SetActionItem(ActionArmor:GetID());				--盔甲
	g_CUFF:SetActionItem(ActionCuff:GetID());					--护腕
	g_BOOT:SetActionItem(ActionBoot:GetID());					--鞋
	g_SASH:SetActionItem(ActionSash:GetID());					--腰带
	g_RING:SetActionItem(ActionRing:GetID());					--戒子
	g_NECKLACE:SetActionItem(ActionNecklace:GetID());	--项链
	g_Dark:SetActionItem(ActionDark:GetID());					--暗器
	g_Charm:SetActionItem(ActionCharm:GetID());				-- 护符
	g_Charm2:SetActionItem(ActionCharm2:GetID());			-- 护符2
	g_Shoulder:SetActionItem(ActionShoulder:GetID());	-- 护肩
	g_Glove:SetActionItem(ActionGlove:GetID());				-- 手套
	g_Ring2:SetActionItem(ActionRing2:GetID());				-- 戒指2
	g_LongWen:SetActionItem(ActionLongWen:GetID());-- 时装
	g_RL:SetActionItem(ActionRL:GetID());	--符石传说

	TargetEquip_ZongMenSkill_TalentEquip:SetActionItem(ActionZongMenEquip:GetID())
	
	TargetEquip_UpdateZhiZunAnimate()
	
    --- 显示人身上的宝石装备位
  TargetEquip_UpdateGemContainer( )

	local att,def = TargetEquip_GetChuanciAttAndDef()
	
	if att ~= nil and def ~= nil then
		local nMinAttackLevel = CachedTarget:Lua_GetTargetEnchanceMinLevel(0)
		local nMinDefenceLevel = CachedTarget:Lua_GetTargetEnchanceMinLevel(1)
	
		local nAttackValue = DataPool:Lua_GetEnchanceSetInfo( 0 , 3, nMinAttackLevel )
		local nDefenceValue = DataPool:Lua_GetEnchanceSetInfo( 1 , 3, nMinDefenceLevel )
	
		--五行宝鉴 之 天火
		local nAttactAddByFE = 0
		local nDefenceAddByFE = 0
		local bElementsActive	= Player:IsOtherFiveElements_ElementsActive( 3 )
		local bElementsLevel	= Player:GetOtherFiveElements_ElementsLevel( 3 )
		local bElementsType	= Player:GetOtherFiveElements_ElementsType( 3 )
		if bElementsLevel > 0 then
			if bElementsType == 1 then
				nAttactAddByFE = DataPool:Lua_GetOtherFiveElementsValueWithEquipAndJade( 3 )
			elseif bElementsType == 2 then
				nDefenceAddByFE = DataPool:Lua_GetOtherFiveElementsValueWithEquipAndJade( 3 )
			end
		end
		
		att = att + nAttactAddByFE
		def = def + nDefenceAddByFE
		
		local nAttackValueAdd = math.ceil( ( att * nAttackValue ) / 100  )
		local nDefenceValueAdd = math.ceil(( def * nDefenceValue ) /  100 )
		local nMartialAtt = MaritialSys:GetOtherMartialEnchance("attack")
		local nMartialDef = MaritialSys:GetOtherMartialEnchance("defence")
		
		local strAttackTip = ScriptGlobal_Format("#{ZBQH_130521_28}" ,tostring(att + nAttackValueAdd + nMartialAtt) , tostring(nAttackValueAdd))
		local strDefenceTip = ScriptGlobal_Format("#{ZBQH_130521_30}" ,tostring(def + nDefenceValueAdd + nMartialDef) , tostring(nDefenceValueAdd))
		
		if Player:GetData("Is2606S") == 1 then
			TargetEquip_HurtFastness:SetToolTip(strAttackTip.."#r#{QXF_260623_11}" );
		else
			TargetEquip_HurtFastness:SetToolTip(strAttackTip.."#r#{ZBQH_130521_29}" );
		end
		TargetEquip_DefenceFastness:SetToolTip(strDefenceTip.."#r#{ZBQH_130521_31}" );
	end	
	--神木王鼎
	--体力
	local nConValue = CachedTarget:GetData("LIANDANLUCONVALUE");
	local strConText = "#{XLDL_140606_02}";
	if nConValue ~= nil and type(nConValue) == "number" and nConValue > 0 then
		strConText = strConText.."#r体力：+"..tostring(nConValue)
	end
	--属性攻
	local nIce, nFire, nThunder, nPoison = CachedTarget:GetData("Attack_IFTPValue");
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
	
	TargetEquip_ShenDing_Icon:SetToolTip(strConText);
	
	local nMinAttactLevel = CachedTarget:Lua_GetTargetEnchanceMinLevel(0)
	local nMinDefenceLevel = CachedTarget:Lua_GetTargetEnchanceMinLevel(1)
	local nSumLevel = 6 * (nMinAttactLevel + nMinDefenceLevel)
	
	if nSumLevel < m_EnchanceLevel[1] then
		TargetEquip_Effect:SetProperty("Image" , "set:UIIcons1 image:Equip_qianghua1" )
	elseif nSumLevel < m_EnchanceLevel[2] then
		TargetEquip_Effect:SetProperty("Image" , "set:UIIcons1 image:Equip_qianghua2" )
	elseif nSumLevel < m_EnchanceLevel[3] then
		TargetEquip_Effect:SetProperty("Image" , "set:UIIcons1 image:Equip_qianghua3" )
	elseif nSumLevel < m_EnchanceLevel[4] then
		TargetEquip_Effect:SetProperty("Image" , "set:UIIcons1 image:Equip_qianghua4" )
	else
		TargetEquip_Effect:SetProperty("Image" , "set:UIIcons1 image:Equip_qianghua5" )
	end
	
	TargetEquip_UpdateFiveElementsTip()

end


function TargetEquip_UpdateZhiZunAnimate()
	
	for i = 1 , 15 do
		if i ~= 8 and i ~= 9 and i ~= 10 then			--8:骑乘 9:行囊 10:箱子
			local ActionEquip = EnumAction(i, "targetequip")

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
----------------------------------------------------------------------------------
--
-- 旋转玩家模型（向左)
--
function TargetEquip_Modle_TurnLeft(start)
	--向左旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		TargetEquip_FakeObject:RotateBegin(-0.3);
	--向左旋转结束
	else
		TargetEquip_FakeObject:RotateEnd();
	end
end

----------------------------------------------------------------------------------
--
-- 旋转玩家模型（向右)
--
function TargetEquip_Modle_TurnRight(start)
	--向右旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		TargetEquip_FakeObject:RotateBegin(0.3);
	--向右旋转结束
	else
		TargetEquip_FakeObject:RotateEnd();
	end
end

----------------------------------------------------------------------------------------
--
-- 关闭界面
--
function TargetEquip_CloseUI()

	this:Hide();

	-- 取消关心OBJ
	TargetEquip_StopCareObject(g_objCared);

	-- 清空FakeModel窗口
	TargetEquip_FakeObject:SetFakeObject("");
	CachedTarget:TargetEquip_DestroyUIModel();

	-- 清空角色信息和装备图标
	TargetEquip_ClearPlayerInfo();
	TargetEquip_ClearEquipItem();

    --- 关闭一键换宝石查看界面
    --- 这里复用下下面这个Event，3 表示关闭TargetEquipBaoshiCheck界面
    PushEvent( "GEM_CONTAINER_CHECK", 1, 3 )
end

----------------------------------------------------------------------------------------
--
-- 清空装备界面中的角色信息
--
function TargetEquip_ClearPlayerInfo()

	TargetEquip_PageHeader:SetText("");
	TargetEquip_Agname:SetText("");
	TargetEquip_Confraternity:SetText("");
	TargetEquip_Level:SetText("等级:");
	TargetEquip_Spouse:SetText("");
	TargetEquip_MenPai:SetText("门派:");
	TargetEquip_Message:SetText("");
    TargetEquip_Fuwuqi:SetText("")
end

----------------------------------------------------------------------------------------
--
--  清空装备界面中的装备图标
--
function TargetEquip_ClearEquipItem()

	--  清空按钮显示图标
	g_WEAPON:SetActionItem(-1);			--武器
	g_CAP:SetActionItem(-1);				--帽子
	g_ARMOR:SetActionItem(-1);			--盔甲
	g_CUFF:SetActionItem(-1);				--护腕
	g_BOOT:SetActionItem(-1);				--鞋
	g_SASH:SetActionItem(-1);				--腰带
	g_RING:SetActionItem(-1);				--戒子
	g_NECKLACE:SetActionItem(-1);		--项链
	g_Dark:SetActionItem(-1);			--坐骑
	g_Charm:SetActionItem(-1);		-- 护符
	g_Charm2:SetActionItem(-1);		-- 护符2
	g_Shoulder:SetActionItem(-1);		-- 护肩
	g_Glove:SetActionItem(-1);		-- 手套
	g_Ring2:SetActionItem(-1);		-- 戒指2
	g_LongWen:SetActionItem(-1);		-- 时装
	g_RL:SetActionItem(-1);   --符石传说
end

----------------------------------------------------------------------------------------
--
-- 打开玩家信息界面
--
-- 资料
--
function TargetEquip_TargetData_Down()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("other")
end
--
-- 珍兽
--
function TargetEquip_OtherPet_Down()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPetFrame("other");
end

--神木王鼎
function TargetEquip_TargetShenDing_Down()
	
	if Player:GetData("Is2606S") == 1 then
		return
	end
	
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1);
	
	local nLevel = CachedTarget:GetData("LEVEL",1);
	if nLevel == nil or nLevel < 15 then
		PushDebugMessage( "#{XLDL_140606_63}" );
	else
		local bRet = SystemSetup:OpenOtherShenDing();
		if bRet == 1 then
			this:Hide()
		end
	end	
end

--
-- 骑乘
--
function TargetEquip_OtherRide_Down()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenRidePage("other");
end

--武魂

function TargetEquip_TargetWuhun_Switch()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherWuhun();
end

--经脉
function TargetEquip_OtherJingMai_Down()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherJingMai();
end

function TargetEquip_ZhenYuan_Down()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleTargetZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetEquip_TargetMiji_Down()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherMiji();
	this:Hide()
end
----------------------------------------------------------------------------------------
--
-- “私聊”按钮的响应函数
--
function Set_To_Private()

	--CachedTarget:Set_To_Private(g_Cur_Name); quyan kvk
	Talk:ContexMenuTalk(g_Cur_Name, g_TargetEquip_Cur_ZoneWorldId);

end

----------------------------------------------------------------------------------------
--
-- “加为好友”按钮的响应函数
--
function Set_To_Friend()

	DataPool:AddFriendAndGrouping( g_Cur_Name, g_TargetEquip_Cur_ZoneWorldId );

end

--=========================================================
--开始关心OBJ
--在开始关心之前需要先确定这个界面是不是已经有“关心”的OBJ，
--如果有的话，先取消已经有的“关心”
--=========================================================
function TargetEquip_BeginCareObject(objCaredId)

	if (type(objCaredId) == "number") then
		g_objCared = objCaredId;
		this:CareObject(g_objCared, 1, "TargetEquip");
	else
		return;
	end

end

--=========================================================
--停止对某OBJ的关心
--=========================================================
function TargetEquip_StopCareObject(objCaredId)

	if (type(objCaredId) == "number") then
		this:CareObject(objCaredId, 0, "TargetEquip");
		g_objCared = -1;
	else
		return;
	end

end

function TargetEquip_Frame_On_ResetPos()
  TargetEquip_Frame:SetProperty("UnifiedPosition", g_TargetEquip_Frame_UnifiedPosition);
end


function TargetEquip_SetFuwuqi( )
    -- 得到目标的和自己的ZoneWorldID
	local targetZoneWorldID = CachedTarget:GetData("ZONEWORLDID", 1)
    local selfZoneWorldID   = DataPool:GetSelfZoneWorldID()

    local strServerName = ""
    --- 只有自己的ZoneWorldID与传进来的参数不一致的时候，才需要显示服务器名
    if selfZoneWorldID ~= nil and selfZoneWorldID ~= -1 and targetZoneWorldID ~= 0 and targetZoneWorldID ~= -1 and selfZoneWorldID ~= targetZoneWorldID then
        --- 得到服务器名称
        strServerName = DataPool:GetServerName( targetZoneWorldID )
    end

	TargetEquip_Fuwuqi:SetText( strServerName )
end

local g_TargetEuip_TypeList =
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

--- 显示人身上的宝石装备位
function TargetEquip_UpdateGemContainer( )
    local ret = 0
    for i = 1, g_TargetEquip_Gem_Contain_Num do
		local nShow = 1
		if Player:GetData("Is2606S") == 1 and i == 15 then
			g_TargetEquip_Gem_Check_Buttons_BK[i]:Hide()
			g_TargetEquip_Gem_Check_Buttons_red[i]:Hide()
			g_TargetEquip_Gem_Check_Buttons_green[i]:Hide()
			nShow = 0 			
		end
		if i ~= 16 and i ~= 18 and nShow == 1 then
			g_TargetEquip_Gem_Check_Buttons_BK[i]:Hide()
			ret = TargetEquip_Can_SwitchGem(i)
			
			if ret == 1 then
				--- 正常态：玩家学会万宝随身互换，装备位上存在装备且所有装备位上的宝石都可以进行互换时
				g_TargetEquip_Gem_Check_Buttons_green[i]:Enable()
				g_TargetEquip_Gem_Check_Buttons_green[i]:Show()
				g_TargetEquip_Gem_Check_Buttons_green[i]:SetToolTip( "#{WBSS_120727_44}" )
				g_TargetEquip_Gem_Check_Buttons_red[i]:Hide()
			else
				--- 异常态：玩家学会万宝随身互换，装备位上不存在装备或非所有装备位上的宝石都可以进行互换时
				g_TargetEquip_Gem_Check_Buttons_red[i]:Enable()
				g_TargetEquip_Gem_Check_Buttons_red[i]:Show()
				g_TargetEquip_Gem_Check_Buttons_red[i]:SetToolTip( "#{WBSS_120727_44}" )
				g_TargetEquip_Gem_Check_Buttons_green[i]:Hide()
			end
		end
    end

end

function TargetEquip_Can_SwitchGem(curSel)

    local equipPoint = g_TargetEuip_TypeList[curSel].equipIndex
    local gemConPos  = g_TargetEuip_TypeList[curSel].gemConIndex

    --- 得到装备上的宝石
    local equipIndex, gemHole, equipGem1, equipGem2, equipGem3, equipGem4 = LifeAbility : Get_OtherPlayerEquip_GemInfo( equipPoint )
    local equipTypeList = {}
    local gemIndexList  = {}
    gemIndexList[1] = equipGem1
    gemIndexList[2] = equipGem2
    gemIndexList[3] = equipGem3
    gemIndexList[4] = equipGem4
    if equipIndex ~= -1 then
        for i = 1, 4 do
            if gemIndexList[i] > 0 then
                equipTypeList[i] = TargetEquip_GetGemTypeByIndex( gemIndexList[i] )
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
    local conGem1, conGem2, conGem3, conGem4 = LifeAbility : Get_OtherPlayerEquip_GemContainerInfo( gemConPos )
    gemConTypeList[1] = conGem1
    gemConTypeList[2] = conGem2
    gemConTypeList[3] = conGem3
    gemConTypeList[4] = conGem4
    for i = 1, 4 do
        if gemConTypeList[i] > 0 then
            gemConTypeList[i] = TargetEquip_GetGemTypeByIndex( gemConTypeList[i] )
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
function TargetEquip_GetGemTypeByIndex( itemTblIdx )
    if itemTblIdx == nil or itemTblIdx <= 0 then
        return -1
    end

    local tmpValue = math.mod( itemTblIdx, 100000 )
    local itemType = math.floor( tmpValue / 1000 )
    return itemType
end

function TargetEquip_BaoShiCheck_Clicked( btnIndex )
    if btnIndex < 0 or btnIndex > 19 then
        return
    end
    PushEvent( "GEM_CONTAINER_CHECK", btnIndex, 1 )
end

function TargetEquip_GetChuanciAttAndDef()

	local attsum = 0
	local defsum = 0

  for i = 0, 23 do
  	local actionItem 		= EnumAction(i, "targetequip");
    local arg1,arg2 = actionItem:GetEnhanceAttAndDef();
    attsum = attsum + tonumber(arg1)
    defsum = defsum + tonumber(arg2)
  end

  return attsum,defsum
end

function TargetEquip_TargetInfant_Switch()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:Other_ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetEquip_EnchanceSetAttr_MouseEnter()
	
	if SystemSetup:IsClassic() == 1 then
		local SetX= TargetEquip_Effect:GetProperty("AbsoluteXPosition") + TargetEquip_Bk1:GetProperty("AbsoluteXPosition")+TargetEquip_FakeObject_Frame:GetProperty("AbsoluteXPosition")+TargetEquip_Frame_Client:GetProperty("AbsoluteXPosition")+TargetEquip_Client:GetProperty("AbsoluteXPosition") +TargetEquip_Frame:GetProperty("AbsoluteXPosition") 
		local SetY = TargetEquip_Effect:GetProperty("AbsoluteYPosition")  + TargetEquip_Bk1:GetProperty("AbsoluteYPosition")+TargetEquip_FakeObject_Frame:GetProperty("AbsoluteYPosition")+TargetEquip_Frame_Client:GetProperty("AbsoluteYPosition")+TargetEquip_Client:GetProperty("AbsoluteYPosition")+TargetEquip_Frame:GetProperty("AbsoluteYPosition")
		local SetWidth = TargetEquip_Effect:GetProperty("AbsoluteWidth")
		local SetHeight = TargetEquip_Effect:GetProperty("AbsoluteHeight")
		PushEvent("OPEN_OTHER_ENCHANCESET", SetX,SetY,SetWidth,SetHeight)
	else
		local SetX= TargetEquip_Effect:GetProperty("AbsoluteXPosition") + TargetEquip_EffectBK:GetProperty("AbsoluteXPosition")+TargetEquip_Bk1:GetProperty("AbsoluteXPosition")+TargetEquip_FakeObject_Frame:GetProperty("AbsoluteXPosition")+TargetEquip_Frame_Client:GetProperty("AbsoluteXPosition") +TargetEquip_Client:GetProperty("AbsoluteXPosition") +TargetEquip_Frame:GetProperty("AbsoluteXPosition") 
		local SetY = TargetEquip_Effect:GetProperty("AbsoluteYPosition")  + TargetEquip_EffectBK:GetProperty("AbsoluteYPosition")+TargetEquip_Bk1:GetProperty("AbsoluteYPosition")+TargetEquip_FakeObject_Frame:GetProperty("AbsoluteYPosition")+TargetEquip_Frame_Client:GetProperty("AbsoluteYPosition")+TargetEquip_Client:GetProperty("AbsoluteYPosition") +TargetEquip_Frame:GetProperty("AbsoluteXPosition") 
		local SetWidth = TargetEquip_Effect:GetProperty("AbsoluteWidth")
		local SetHeight = TargetEquip_Effect:GetProperty("AbsoluteHeight")
		PushEvent("OPEN_OTHER_ENCHANCESET", SetX,SetY,SetWidth,SetHeight)
	
	end
end

function TargetEquip_EnchanceSetAttr_MouseLeave()
	PushEvent("CLOSE_OTHER_ENCHANCESET")
end

function TargetEquip_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetEquip_ZhiZunEquipSet_MouseEnter()
	
--	if SystemSetup:IsClassic() == 1 then
--		local SetX= TargetEquip_ZhiZun_Icon:GetProperty("AbsoluteXPosition") + TargetEquip_FakeObject_Frame:GetProperty("AbsoluteXPosition")+TargetEquip_Frame_Client:GetProperty("AbsoluteXPosition")+TargetEquip_Client:GetProperty("AbsoluteXPosition") +TargetEquip_Frame:GetProperty("AbsoluteXPosition") 
--		local SetY = TargetEquip_ZhiZun_Icon:GetProperty("AbsoluteYPosition")  + TargetEquip_FakeObject_Frame:GetProperty("AbsoluteYPosition")+TargetEquip_Frame_Client:GetProperty("AbsoluteYPosition")+TargetEquip_Client:GetProperty("AbsoluteYPosition")+TargetEquip_Frame:GetProperty("AbsoluteYPosition")
--		local SetWidth = TargetEquip_ZhiZun_Icon:GetProperty("AbsoluteWidth")
--		local SetHeight = TargetEquip_ZhiZun_Icon:GetProperty("AbsoluteHeight")
--		PushEvent("TARGET_ZHIZUN_EQUIPSET_TIP_OPEN", SetX,SetY,SetWidth,SetHeight)
--	else
--		local SetX= TargetEquip_ZhiZun_Icon:GetProperty("AbsoluteXPosition") + TargetEquip_EffectBK:GetProperty("AbsoluteXPosition")+TargetEquip_Bk1:GetProperty("AbsoluteXPosition")+TargetEquip_FakeObject_Frame:GetProperty("AbsoluteXPosition")+TargetEquip_Frame_Client:GetProperty("AbsoluteXPosition") +TargetEquip_Client:GetProperty("AbsoluteXPosition") +TargetEquip_Frame:GetProperty("AbsoluteXPosition") 
--		local SetY = TargetEquip_ZhiZun_Icon:GetProperty("AbsoluteYPosition")  + TargetEquip_EffectBK:GetProperty("AbsoluteYPosition")+TargetEquip_Bk1:GetProperty("AbsoluteYPosition")+TargetEquip_FakeObject_Frame:GetProperty("AbsoluteYPosition")+TargetEquip_Frame_Client:GetProperty("AbsoluteYPosition")+TargetEquip_Client:GetProperty("AbsoluteYPosition") +TargetEquip_Frame:GetProperty("AbsoluteXPosition") 
--		local SetWidth = TargetEquip_ZhiZun_Icon:GetProperty("AbsoluteWidth")
--		local SetHeight = TargetEquip_ZhiZun_Icon:GetProperty("AbsoluteHeight")
--		PushEvent("TARGET_ZHIZUN_EQUIPSET_TIP_OPEN", SetX,SetY,SetWidth,SetHeight)
--	end
end

function TargetEquip_ZhiZunEquipSet_MouseLeave()
--	PushEvent("TARGET_ZHIZUN_EQUIPSET_TIP_CLOSE")
end

function TargetEquip_ZhiZunEquipSet_MouseClick()
	
	if Player:GetData("Is2606S") == 1 then
		return
	end
	
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end

function TargetEquip_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end


function TargetEquip_UpdateFiveElementsTip()
	
	local nLevel = CachedTarget:GetData("LEVEL", 1)
	if nLevel < 85 then
		TargetEquip_ZhiZun_Icon:SetToolTip("#{ZZZB_150811_115}")
		return
	end
	
	local strTips = {}
	
	for i = 1 , 5 do
		
		strTips[ i ] = ""
		
		local bElementsActive 	= Player:IsOtherFiveElements_ElementsActive( i - 1 )
		local bElementsLevel	= Player:GetOtherFiveElements_ElementsLevel( i - 1 )
		local bElementsType		= Player:GetOtherFiveElements_ElementsType( i - 1 )
			
		if bElementsLevel > 0 then

			if i == 3 or i == 5 then
				
				local nElementsValue = DataPool:Lua_GetOtherFiveElementsValueWithEquipAndJade( i - 1 )
				
				local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_141}", g_ElementsValueName[ i ][ 1 ] , nElementsValue )
				strTips[ i ] = strTips[ i ]..tostring(nValueText)
				
			end
			
			if i == 1 or i == 2 or i == 4 then
				if g_ElementsValueName[ i ][ bElementsType ] ~= nil then
					
					local nElementsValue = DataPool:Lua_GetOtherFiveElementsValueWithEquipAndJade( i - 1 )
					
					local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_141}", g_ElementsValueName[ i ][ bElementsType ] , nElementsValue )
					
					strTips[ i ] = strTips[ i ]..tostring(nValueText)
					
				end
			end
			
		else
			strTips[ i ] = strTips[ i ].."#{ZZZB_150811_117}"
		end
	end
	
	local stringToolTip = ScriptGlobal_Format("#{ZZZB_150811_116}"  , strTips[ 1 ], strTips[ 2 ], strTips[ 3 ], strTips[ 4 ], strTips[ 5 ])
	
	TargetEquip_ZhiZun_Icon:SetToolTip(stringToolTip)
	

end

function TargetEquip_ShowFightScore()
	local nLevel = CachedTarget:GetData("LEVEL")
	if nLevel < 30 then
		PushDebugMessage("#{PFBJ_160106_2}")
	else
		PushEvent( "TARGETEQUIP_FIGHTSCORE_SHOW" )
	end
end

function TargetEquip_OpenShopDress()
	PushEvent( "TARGET_DRESS",  g_objCared )
end

function TargetEquip_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

function TargetEquip_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function TargetEquip_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function TargetEquip_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end

function TargetEquip_ShowXbwInfo()
	
	Variable:SetVariable("OtherUnionPos", TargetEquip_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("XBW_OTHER_DETAIL_UPDATE_2018")
end

function TargetEquip_ShowXingZhen()	
	LuaFnOpenTargetXingZhen()
end

function TargetEquip_Xunzhang_Open()
	PushEvent("XUNZHANG_BASE_OPEN_OTHER", 1)	
end

function TargetEquip_ShowPage()

	for i = 1, table.getn(g_TargetEquip_Page) do
		g_TargetPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	TargetEquip_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_TargetPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_TargetEquip_Page) do
			if i ~= nOtherPageNumber then
				g_TargetPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_TargetPageOrder = {}
	g_TargetPageCount = 0
	for i = 1, table.getn(g_TargetEquip_Page) do
		if TargetEquip_CheckPage(i) == 1 then
			g_TargetPageCount = g_TargetPageCount + 1
			g_TargetPageButton[g_TargetPageCount]:Show()
			g_TargetPageButton[g_TargetPageCount]:SetText(g_TargetEquip_Page[i].Text)	
			g_TargetPageOrder[g_TargetPageCount] = i
		end
	end
	
end

function TargetEquip_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_TargetPageOrder[idx]
	
	if idx == 1 then--装备
		--TargetWuhun_OtherEquip_Page_Switch();
	elseif idx == 2 then--资料
		TargetEquip_TargetData_Down()
	elseif idx == 3 then--珍兽
		TargetEquip_OtherPet_Down()
	elseif idx == 4 then--子女
		TargetEquip_TargetInfant_Switch()
	elseif idx == 5 then--武魂
		TargetEquip_TargetWuhun_Switch()
	elseif idx == 6 then--秘籍
		TargetEquip_TargetMiji_Down()
	elseif idx == 7 then--真元
		TargetEquip_ZhenYuan_Down()
	elseif idx == 8 then--经脉
		TargetEquip_OtherJingMai_Down()
	elseif idx == 9 then--神鼎
		TargetEquip_TargetShenDing_Down()
	elseif idx == 10 then--侠印
		TargetEquip_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		TargetEquip_OpenBaoJian()
	elseif idx == 12 then--武意
		TargetEquip_OpenWuYi()
	elseif idx == 13 then--神器
		TargetEquip_OpenShenQi()
	elseif idx == 14 then--星盘
		TargetEquip_Armor_Page_Switch()
	elseif idx == 15 then--名物
		TargetEquip_CangPin_Page_Switch()
	end
end

function TargetEquip_CheckPage(idx)
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
	elseif idx == 6 then--秘籍
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 7 then--真元
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 8 then--经脉
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 9 then--神鼎
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 10 then--侠印
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 11 then--宝鉴
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 12 then--武意
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 13 then--神器
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 14 then--星盘
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 15 then--名物
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	end
	return 0
end

function TargetEquip_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


