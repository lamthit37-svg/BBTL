--SelfShenDing.lua

-- 界面的默认相对位置
local g_SelfShenDing_Frame_UnifiedXPosition=nil;
local g_SelfShenDing_Frame_UnifiedYPosition=nil;

local g_SelfShenDing_YuanbaoPay = 1

local g_DanYaoCtrl = {};
local g_DanYaoAttack = {};

local g_ZongConValue=0;
local g_RongHeConValue=0;
local g_CurRongHeCount=0;
local g_MaxRongHeCount=0;
local g_nDanYaoCount=0;
local g_bFlasgTimer=0;

local g_JinDanEffect  = 100	-- 金丹效果
local g_AttackJinDanEffect = 80		--属性攻金丹效果
local g_MaxEffect = 9999		-- 属性的上限值

--提供长按左键进行连加连减功能
local g_AutoClick_BtnFlag = -1		-- 记录当前鼠标左键是在哪个按钮按下
local g_AutoClickTimer_Step = 100		-- 多少时间(毫秒)模拟一次 Click 操作
local g_AutoClick_FunList = {}			-- 将公用一个 Timer 的回调功能函数放到一个数组
local g_AutoClick_Going = -1			-- 标志是否开始自动点击操作(第一次LButton后经过X个Timer才算开始, 也就是说是 g_AutoClickTimer_Step * X 的时候开始进行自动加, 这样为了防止本来要点击一下的结果点了好多下)

--存储属性攻的原设置值 和 新调整值
local g_AttackValue={
	[0] = { DBValue=0, SettingValue=0 },	--潜能
	[1] = { DBValue=0, SettingValue=0 },	--冰
	[2] = { DBValue=0, SettingValue=0 },	--火
	[3] = { DBValue=0, SettingValue=0 },	--玄
	[4] = { DBValue=0, SettingValue=0 },	--毒
};

--属性攻界面的冰火玄毒按钮
local g_AttackIFTPButtons={};

local g_ChengDanParam={
	[1] = { MaxCount=1, NingLianValue=200,   ConEffect=15, Name="#{XLDL_140606_72}" },
	[2] = { MaxCount=2, NingLianValue=500,   ConEffect=17, Name="#{XLDL_140606_73}" },
	[3] = { MaxCount=3, NingLianValue=1000,  ConEffect=19, Name="#{XLDL_140606_74}" },
	[4] = { MaxCount=4, NingLianValue=2500,  ConEffect=24, Name="#{XLDL_140606_75}" },
	[5] = { MaxCount=5, NingLianValue=5000,  ConEffect=29, Name="#{XLDL_140606_76}" },
	[6] = { MaxCount=6, NingLianValue=10000, ConEffect=34, Name="#{XLDL_140606_77}" },
	[7] = { MaxCount=7, NingLianValue=30000, ConEffect=39, Name="#{XLDL_140606_78}" },
	[8] = { MaxCount=8, NingLianValue=80000, ConEffect=45, Name="#{XLDL_140606_79}" },
	[9] = { MaxCount=9, NingLianValue=150000,ConEffect=51, Name="#{XLDL_140606_80}" },
	}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_SelfShenDing_Page = {
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

local g_SelfShenDing_PageButton = {}
local g_SelfShenDing_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

function SelfShenDing_PreLoad()
	-- 打开界面
	this:RegisterEvent("OPEN_SHENDING_PAGE");
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	--数据变化
	this:RegisterEvent("UPDATE_LIANDANLU_CON_VALUE")
	this:RegisterEvent("UPDATE_RONGHE_CON_VALUE")
	this:RegisterEvent("UPDATE_LIANDAN_COUNT")
	this:RegisterEvent("UPDATE_LIANDANLU_YAOCHEN_VALUE")
	this:RegisterEvent("UPDATE_JINDAN_RONGHE_COUNT")
	this:RegisterEvent("UPDATE_JINDAN_RONGHE_MAXCOUNT")
	this:RegisterEvent("UI_COMMAND");

	this:RegisterEvent("UPDATE_SMWD_ATTACK");
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK");		--升级
	this:RegisterEvent("TOGGLE_UPDATE_INFANT"); --子女有变化 刷新按钮状态
	this:RegisterEvent("FINISH_MISSION");
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
end

function SelfShenDing_OnLoad()
	-- 保存界面的默认相对位置
	g_SelfShenDing_Frame_UnifiedXPosition	= SelfShenDing_Frame : GetProperty("UnifiedXPosition");
	g_SelfShenDing_Frame_UnifiedYPosition	= SelfShenDing_Frame : GetProperty("UnifiedYPosition");

	g_DanYaoCtrl[1] = { count=1,
		Index = {
			[1] = { ctrl = SelfShenDing_BK_1_Item1, Hover = SelfShenDing_BK_1_Item1_Hover },
			};
		};
	g_DanYaoCtrl[2] = { count=2,
		Index = {
			[1] = { ctrl = SelfShenDing_BK_2_Item1, Hover = SelfShenDing_BK_2_Item1_Hover },
			[2] = { ctrl = SelfShenDing_BK_2_Item2, Hover = SelfShenDing_BK_2_Item2_Hover },
			 };
		};
	g_DanYaoCtrl[3] = { count=3,
		Index = {
			[1] = { ctrl = SelfShenDing_BK_3_Item1, Hover = SelfShenDing_BK_3_Item1_Hover },
			[2] = { ctrl = SelfShenDing_BK_3_Item2, Hover = SelfShenDing_BK_3_Item2_Hover },
			[3] = { ctrl = SelfShenDing_BK_3_Item3, Hover = SelfShenDing_BK_3_Item3_Hover },
			};
		};
	g_DanYaoCtrl[4] = { count=4,
		Index = {
			[1] = { ctrl = SelfShenDing_BK_4_Item1, Hover = SelfShenDing_BK_4_Item1_Hover },
			[2] = { ctrl = SelfShenDing_BK_4_Item2, Hover = SelfShenDing_BK_4_Item2_Hover },
			[3] = { ctrl = SelfShenDing_BK_4_Item3, Hover = SelfShenDing_BK_4_Item3_Hover },
			[4] = { ctrl = SelfShenDing_BK_4_Item4, Hover = SelfShenDing_BK_4_Item4_Hover },
			};
		};
	g_DanYaoCtrl[5] = { count=5,
		Index = {
			[1] = { ctrl = SelfShenDing_BK_5_Item1, Hover = SelfShenDing_BK_5_Item1_Hover },
			[2] = { ctrl = SelfShenDing_BK_5_Item2, Hover = SelfShenDing_BK_5_Item2_Hover },
			[3] = { ctrl = SelfShenDing_BK_5_Item3, Hover = SelfShenDing_BK_5_Item3_Hover },
			[4] = { ctrl = SelfShenDing_BK_5_Item4, Hover = SelfShenDing_BK_5_Item4_Hover },
			[5] = { ctrl = SelfShenDing_BK_5_Item5, Hover = SelfShenDing_BK_5_Item5_Hover },
			};
		};
	g_DanYaoCtrl[6] = { count=6,
		Index = {
			[1] = { ctrl = SelfShenDing_BK_6_Item1, Hover = SelfShenDing_BK_6_Item1_Hover },
			[2] = { ctrl = SelfShenDing_BK_6_Item2, Hover = SelfShenDing_BK_6_Item2_Hover },
			[3] = { ctrl = SelfShenDing_BK_6_Item3, Hover = SelfShenDing_BK_6_Item3_Hover },
			[4] = { ctrl = SelfShenDing_BK_6_Item4, Hover = SelfShenDing_BK_6_Item4_Hover },
			[5] = { ctrl = SelfShenDing_BK_6_Item5, Hover = SelfShenDing_BK_6_Item5_Hover },
			[6] = { ctrl = SelfShenDing_BK_6_Item6, Hover = SelfShenDing_BK_6_Item6_Hover },
			};
		};
	g_DanYaoCtrl[7] = { count=7,
		Index = {
			[1] = { ctrl = SelfShenDing_BK_7_Item1, Hover = SelfShenDing_BK_7_Item1_Hover },
			[2] = { ctrl = SelfShenDing_BK_7_Item2, Hover = SelfShenDing_BK_7_Item2_Hover },
			[3] = { ctrl = SelfShenDing_BK_7_Item3, Hover = SelfShenDing_BK_7_Item3_Hover },
			[4] = { ctrl = SelfShenDing_BK_7_Item4, Hover = SelfShenDing_BK_7_Item4_Hover },
			[5] = { ctrl = SelfShenDing_BK_7_Item5, Hover = SelfShenDing_BK_7_Item5_Hover },
			[6] = { ctrl = SelfShenDing_BK_7_Item6, Hover = SelfShenDing_BK_7_Item6_Hover },
			[7] = { ctrl = SelfShenDing_BK_7_Item7, Hover = SelfShenDing_BK_7_Item7_Hover },
			};
		};
	g_DanYaoCtrl[8] = { count=8,
		Index = {
			[1] = { ctrl = SelfShenDing_BK_8_Item1, Hover = SelfShenDing_BK_8_Item1_Hover },
			[2] = { ctrl = SelfShenDing_BK_8_Item2, Hover = SelfShenDing_BK_8_Item2_Hover },
			[3] = { ctrl = SelfShenDing_BK_8_Item3, Hover = SelfShenDing_BK_8_Item3_Hover },
			[4] = { ctrl = SelfShenDing_BK_8_Item4, Hover = SelfShenDing_BK_8_Item4_Hover },
			[5] = { ctrl = SelfShenDing_BK_8_Item5, Hover = SelfShenDing_BK_8_Item5_Hover },
			[6] = { ctrl = SelfShenDing_BK_8_Item6, Hover = SelfShenDing_BK_8_Item6_Hover },
			[7] = { ctrl = SelfShenDing_BK_8_Item7, Hover = SelfShenDing_BK_8_Item7_Hover },
			[8] = { ctrl = SelfShenDing_BK_8_Item8, Hover = SelfShenDing_BK_8_Item8_Hover },
			};
		};
	g_DanYaoCtrl[9] = { count=9,
		Index = {
			[1] = { ctrl = SelfShenDing_BK_9_Item1, Hover = SelfShenDing_BK_9_Item1_Hover },
			[2] = { ctrl = SelfShenDing_BK_9_Item2, Hover = SelfShenDing_BK_9_Item2_Hover },
			[3] = { ctrl = SelfShenDing_BK_9_Item3, Hover = SelfShenDing_BK_9_Item3_Hover },
			[4] = { ctrl = SelfShenDing_BK_9_Item4, Hover = SelfShenDing_BK_9_Item4_Hover },
			[5] = { ctrl = SelfShenDing_BK_9_Item5, Hover = SelfShenDing_BK_9_Item5_Hover },
			[6] = { ctrl = SelfShenDing_BK_9_Item6, Hover = SelfShenDing_BK_9_Item6_Hover },
			[7] = { ctrl = SelfShenDing_BK_9_Item7, Hover = SelfShenDing_BK_9_Item7_Hover },
			[8] = { ctrl = SelfShenDing_BK_9_Item8, Hover = SelfShenDing_BK_9_Item8_Hover },
			[9] = { ctrl = SelfShenDing_BK_9_Item9, Hover = SelfShenDing_BK_9_Item9_Hover },
			};
		};

	--属性攻的控件
	g_DanYaoAttack[1] = { ctrl=SelfShenDing2_BK_1_Item1, Hover=SelfShenDing2_BK_1_Item1_Hover, Level=1, Count=1, ConEffect=10, Image="set:SMWD_Icon image:SMWD_Icon_1"};

	g_DanYaoAttack[2] = { ctrl=SelfShenDing2_BK_2_Item1, Hover=SelfShenDing2_BK_2_Item1_Hover, Level=2, Count=1, ConEffect=14, Image="set:SMWD_Icon image:SMWD_Icon_2"};
	g_DanYaoAttack[3] = { ctrl=SelfShenDing2_BK_2_Item2, Hover=SelfShenDing2_BK_2_Item2_Hover, Level=2, Count=2, ConEffect=14, Image="set:SMWD_Icon image:SMWD_Icon_2"};

	g_DanYaoAttack[4] = { ctrl=SelfShenDing2_BK_3_Item1, Hover=SelfShenDing2_BK_3_Item1_Hover, Level=3, Count=1, ConEffect=18, Image="set:SMWD_Icon image:SMWD_Icon_3"};
	g_DanYaoAttack[5] = { ctrl=SelfShenDing2_BK_3_Item2, Hover=SelfShenDing2_BK_3_Item2_Hover, Level=3, Count=2, ConEffect=18, Image="set:SMWD_Icon image:SMWD_Icon_3"};
	g_DanYaoAttack[6] = { ctrl=SelfShenDing2_BK_3_Item3, Hover=SelfShenDing2_BK_3_Item3_Hover, Level=3, Count=3, ConEffect=18, Image="set:SMWD_Icon image:SMWD_Icon_3"};

	g_DanYaoAttack[7] = { ctrl=SelfShenDing2_BK_4_Item1, Hover=SelfShenDing2_BK_4_Item1_Hover, Level=4, Count=1, ConEffect=22, Image="set:SMWD_Icon image:SMWD_Icon_4"};
	g_DanYaoAttack[8] = { ctrl=SelfShenDing2_BK_4_Item2, Hover=SelfShenDing2_BK_4_Item2_Hover, Level=4, Count=2, ConEffect=22, Image="set:SMWD_Icon image:SMWD_Icon_4"};
	g_DanYaoAttack[9] = { ctrl=SelfShenDing2_BK_4_Item3, Hover=SelfShenDing2_BK_4_Item3_Hover, Level=4, Count=3, ConEffect=22, Image="set:SMWD_Icon image:SMWD_Icon_4"};
	g_DanYaoAttack[10] = { ctrl=SelfShenDing2_BK_4_Item4, Hover=SelfShenDing2_BK_4_Item4_Hover, Level=4, Count=4, ConEffect=22, Image="set:SMWD_Icon image:SMWD_Icon_4"};

	g_DanYaoAttack[11] = { ctrl=SelfShenDing2_BK_5_Item1, Hover=SelfShenDing2_BK_5_Item1_Hover, Level=5, Count=1, ConEffect=26, Image="set:SMWD_Icon image:SMWD_Icon_5"};
	g_DanYaoAttack[12] = { ctrl=SelfShenDing2_BK_5_Item2, Hover=SelfShenDing2_BK_5_Item2_Hover, Level=5, Count=2, ConEffect=26, Image="set:SMWD_Icon image:SMWD_Icon_5"};
	g_DanYaoAttack[13] = { ctrl=SelfShenDing2_BK_5_Item3, Hover=SelfShenDing2_BK_5_Item3_Hover, Level=5, Count=3, ConEffect=26, Image="set:SMWD_Icon image:SMWD_Icon_5"};
	g_DanYaoAttack[14] = { ctrl=SelfShenDing2_BK_5_Item4, Hover=SelfShenDing2_BK_5_Item4_Hover, Level=5, Count=4, ConEffect=26, Image="set:SMWD_Icon image:SMWD_Icon_5"};
	g_DanYaoAttack[15] = { ctrl=SelfShenDing2_BK_5_Item5, Hover=SelfShenDing2_BK_5_Item5_Hover, Level=5, Count=5, ConEffect=26, Image="set:SMWD_Icon image:SMWD_Icon_5"};

	g_DanYaoAttack[16] = { ctrl=SelfShenDing2_BK_6_Item1, Hover=SelfShenDing2_BK_6_Item1_Hover, Level=6, Count=1, ConEffect=31, Image="set:SMWD_Icon image:SMWD_Icon_6"};
	g_DanYaoAttack[17] = { ctrl=SelfShenDing2_BK_6_Item2, Hover=SelfShenDing2_BK_6_Item2_Hover, Level=6, Count=2, ConEffect=31, Image="set:SMWD_Icon image:SMWD_Icon_6"};
	g_DanYaoAttack[18] = { ctrl=SelfShenDing2_BK_6_Item3, Hover=SelfShenDing2_BK_6_Item3_Hover, Level=6, Count=3, ConEffect=31, Image="set:SMWD_Icon image:SMWD_Icon_6"};
	g_DanYaoAttack[19] = { ctrl=SelfShenDing2_BK_6_Item4, Hover=SelfShenDing2_BK_6_Item4_Hover, Level=6, Count=4, ConEffect=31, Image="set:SMWD_Icon image:SMWD_Icon_6"};
	g_DanYaoAttack[20] = { ctrl=SelfShenDing2_BK_6_Item5, Hover=SelfShenDing2_BK_6_Item5_Hover, Level=6, Count=5, ConEffect=31, Image="set:SMWD_Icon image:SMWD_Icon_6"};
	g_DanYaoAttack[21] = { ctrl=SelfShenDing2_BK_6_Item6, Hover=SelfShenDing2_BK_6_Item6_Hover, Level=6, Count=6, ConEffect=31, Image="set:SMWD_Icon image:SMWD_Icon_6"};

	g_DanYaoAttack[22] = { ctrl=SelfShenDing2_BK_7_Item1, Hover=SelfShenDing2_BK_7_Item1_Hover, Level=7, Count=1, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};
	g_DanYaoAttack[23] = { ctrl=SelfShenDing2_BK_7_Item2, Hover=SelfShenDing2_BK_7_Item2_Hover, Level=7, Count=2, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};
	g_DanYaoAttack[24] = { ctrl=SelfShenDing2_BK_7_Item3, Hover=SelfShenDing2_BK_7_Item3_Hover, Level=7, Count=3, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};
	g_DanYaoAttack[25] = { ctrl=SelfShenDing2_BK_7_Item4, Hover=SelfShenDing2_BK_7_Item4_Hover, Level=7, Count=4, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};
	g_DanYaoAttack[26] = { ctrl=SelfShenDing2_BK_7_Item5, Hover=SelfShenDing2_BK_7_Item5_Hover, Level=7, Count=5, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};
	g_DanYaoAttack[27] = { ctrl=SelfShenDing2_BK_7_Item6, Hover=SelfShenDing2_BK_7_Item6_Hover, Level=7, Count=6, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};
	g_DanYaoAttack[28] = { ctrl=SelfShenDing2_BK_7_Item7, Hover=SelfShenDing2_BK_7_Item7_Hover, Level=7, Count=7, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};

	g_DanYaoAttack[29] = { ctrl=SelfShenDing2_BK_8_Item1, Hover=SelfShenDing2_BK_8_Item1_Hover, Level=8, Count=1, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[30] = { ctrl=SelfShenDing2_BK_8_Item2, Hover=SelfShenDing2_BK_8_Item2_Hover, Level=8, Count=2, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[31] = { ctrl=SelfShenDing2_BK_8_Item3, Hover=SelfShenDing2_BK_8_Item3_Hover, Level=8, Count=3, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[32] = { ctrl=SelfShenDing2_BK_8_Item4, Hover=SelfShenDing2_BK_8_Item4_Hover, Level=8, Count=4, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[33] = { ctrl=SelfShenDing2_BK_8_Item5, Hover=SelfShenDing2_BK_8_Item5_Hover, Level=8, Count=5, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[34] = { ctrl=SelfShenDing2_BK_8_Item6, Hover=SelfShenDing2_BK_8_Item6_Hover, Level=8, Count=6, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[35] = { ctrl=SelfShenDing2_BK_8_Item7, Hover=SelfShenDing2_BK_8_Item7_Hover, Level=8, Count=7, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[36] = { ctrl=SelfShenDing2_BK_8_Item8, Hover=SelfShenDing2_BK_8_Item8_Hover, Level=8, Count=8, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};

	g_DanYaoAttack[37] = { ctrl=SelfShenDing2_BK_9_Item1, Hover=SelfShenDing2_BK_9_Item1_Hover, Level=9, Count=1, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[38] = { ctrl=SelfShenDing2_BK_9_Item2, Hover=SelfShenDing2_BK_9_Item2_Hover, Level=9, Count=2, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[39] = { ctrl=SelfShenDing2_BK_9_Item3, Hover=SelfShenDing2_BK_9_Item3_Hover, Level=9, Count=3, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[40] = { ctrl=SelfShenDing2_BK_9_Item4, Hover=SelfShenDing2_BK_9_Item4_Hover, Level=9, Count=4, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[41] = { ctrl=SelfShenDing2_BK_9_Item5, Hover=SelfShenDing2_BK_9_Item5_Hover, Level=9, Count=5, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[42] = { ctrl=SelfShenDing2_BK_9_Item6, Hover=SelfShenDing2_BK_9_Item6_Hover, Level=9, Count=6, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[43] = { ctrl=SelfShenDing2_BK_9_Item7, Hover=SelfShenDing2_BK_9_Item7_Hover, Level=9, Count=7, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[44] = { ctrl=SelfShenDing2_BK_9_Item8, Hover=SelfShenDing2_BK_9_Item8_Hover, Level=9, Count=8, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[45] = { ctrl=SelfShenDing2_BK_9_Item9, Hover=SelfShenDing2_BK_9_Item9_Hover, Level=9, Count=9, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};


	--连加、连减功能
	g_AutoClick_FunList[1] = SelfShenDing2_IceAttack_Add_Click
	g_AutoClick_FunList[2] = SelfShenDing2_IceAttack_Dec_Click
	g_AutoClick_FunList[3] = SelfShenDing2_FireAttack_Add_Click
	g_AutoClick_FunList[4] = SelfShenDing2_FireAttack_Dec_Click
	g_AutoClick_FunList[5] = SelfShenDing2_ThunderAttack_Add_Click
	g_AutoClick_FunList[6] = SelfShenDing2_ThunderAttack_Dec_Click
	g_AutoClick_FunList[7] = SelfShenDing2_PoisonAttack_Add_Click
	g_AutoClick_FunList[8] = SelfShenDing2_PoisonAttack_Dec_Click

	g_AutoClick_BtnFlag = -1
	g_AutoClick_Going = -1

	--按钮
	g_AttackIFTPButtons[1] = { AddBtn=SelfShenDing2_ShuXingGong_Bing_Add, SubBtn=SelfShenDing2_ShuXingGong_Bing_Sub };
	g_AttackIFTPButtons[2] = { AddBtn=SelfShenDing2_ShuXingGong_Huo_Add, 	SubBtn=SelfShenDing2_ShuXingGong_Huo_Sub };
	g_AttackIFTPButtons[3] = { AddBtn=SelfShenDing2_ShuXingGong_Xuan_Add, SubBtn=SelfShenDing2_ShuXingGong_Xuan_Sub };
	g_AttackIFTPButtons[4] = { AddBtn=SelfShenDing2_ShuXingGong_Du_Add, 	SubBtn=SelfShenDing2_ShuXingGong_Du_Sub };

	--默认不显示
	SelfShenDing2_ShuXingGong_Reset_Tips : Hide();
	
	g_SelfShenDing_YuanbaoPay = 1;		--元宝支付确认 默认选中
	SelfShenDing_querengoumai:SetCheck(g_SelfShenDing_YuanbaoPay)
	
	g_SelfShenDing_PageButton[1] = SelfShenDing_SelfEquip
	g_SelfShenDing_PageButton[2] = SelfShenDing_SelfData
	g_SelfShenDing_PageButton[3] = SelfShenDing_Pet
	g_SelfShenDing_PageButton[4] = SelfShenDing_Infant
	g_SelfShenDing_PageButton[5] = SelfShenDing_Wuhun
	g_SelfShenDing_PageButton[6] = SelfShenDing_Xiulian
	g_SelfShenDing_PageButton[7] = SelfShenDing_Miji
	g_SelfShenDing_PageButton[8] = SelfShenDing_ZhenYuan
	g_SelfShenDing_PageButton[9] = SelfShenDing_JingMai
	g_SelfShenDing_PageButton[10] = SelfShenDing_ShenDing
	g_SelfShenDing_PageButton[11] = SelfShenDing_JueWei
	g_SelfShenDing_PageButton[12] = SelfShenDing_BaoJian
	g_SelfShenDing_PageButton[13] = SelfShenDing_WuYi
	g_SelfShenDing_PageButton[14] = SelfShenDing_ShenQi
	g_SelfShenDing_PageButton[15] = SelfShenDing_Armor
	g_SelfShenDing_PageButton[16] = SelfShenDing_CangPin
	g_SelfShenDing_PageButton[17] = SelfShenDing_OtherInfo
	
	g_SelfShenDing_PageMask[1] = SelfShenDing_SelfEquip_tips
	g_SelfShenDing_PageMask[2] = SelfShenDing_SelfData_tips
	g_SelfShenDing_PageMask[3] = SelfShenDing_Pet_tips
	g_SelfShenDing_PageMask[4] = SelfShenDing_Infant_tips
	g_SelfShenDing_PageMask[5] = SelfShenDing_Wuhun_tips
	g_SelfShenDing_PageMask[6] = SelfShenDing_Xiulian_tips
	g_SelfShenDing_PageMask[7] = SelfShenDing_Miji_tips
	g_SelfShenDing_PageMask[8] = SelfShenDing_ZhenYuan_tips
	g_SelfShenDing_PageMask[9] = SelfShenDing_JingMai_tips
	g_SelfShenDing_PageMask[10] = SelfShenDing_ShenDing_tips
	g_SelfShenDing_PageMask[11] = SelfShenDing_JueWei_tips
	g_SelfShenDing_PageMask[12] = SelfShenDing_BaoJian_tips
	g_SelfShenDing_PageMask[13] = SelfShenDing_WuYi_tips
	g_SelfShenDing_PageMask[14] = SelfShenDing_ShenQi_tips
	g_SelfShenDing_PageMask[15] = SelfShenDing_Armor_tips
	g_SelfShenDing_PageMask[16] = SelfShenDing_CangPin_tips
	g_SelfShenDing_PageMask[17] = SelfShenDing_OtherInfo_tips
	
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
function SelfShenDing_OnEvent(event)

	if ( event == "UPDATE_WILLGET_MISSION_TRACK" ) or (event=="TOGGLE_UPDATE_INFANT")  or (event == "FINISH_MISSION") then
		local nLevel =Player:GetLevel()
		SelfShenDing_Refresh_Page_Button(nLevel)
		SelfShenDing_ShowPage()
	end
	--显示界面
	if ( event == "OPEN_SHENDING_PAGE" ) then
		if(this:IsVisible()) then
			SelfShenDing_CloseFunction()
			return;
		end

		g_AutoClick_Going = -1
		g_AutoClick_BtnFlag = -1
		SetTimer("SelfShenDing", "SelfShenDing_AutoClick_Timer()", g_AutoClickTimer_Step)

		--更新数据
		SelfShenDing_OnUpdateShow();

		SelfShenDing_SetTabColor(9);
		SelfShenDing_ShenDing:SetCheck(1);
		SelfShenDing_OnShown();
		local nLevel =Player:GetLevel()
		SelfShenDing_Refresh_Page_Button(nLevel)
		SelfShenDing_ShowPage()
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 201406072) then

		--使用金丹
		local isSuccess = tonumber(Get_XParam_INT(0));
		local nType = tonumber(Get_XParam_INT(1))

		--成功
		if isSuccess == 1 then
			if nType == 0 then		--体力
				--更新数据
				SelfShenDing_OnUpdateShow();

				SelfShenDing_SetTabColor(9);
				SelfShenDing_ShenDing:SetCheck(1);
				SelfShenDing_OnShown();
			elseif nType == 1 then	--属性攻
				SelfShenDing_OnUpdateShow_Attack( 1 );
				SelfShenDing_OnShown();
			end
		end
	end

	if( event == "HIDE_ON_SCENE_TRANSED") then
		SelfShenDing_CloseFunction()
		return;
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		SelfShenDing_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SelfShenDing_Frame_On_ResetPos()
	end

	--数据变化事件限于窗口打开时
	if(this:IsVisible()) then
		if ( event == "UPDATE_LIANDANLU_CON_VALUE" ) then
			g_ZoneConValue=Player:GetData("LIANDANLUCONVALUE");
			SelfShenDing_UpdateRongHeData();

		elseif ( event == "UPDATE_RONGHE_CON_VALUE" ) then
			g_RongHeConValue=Player:GetData("RongHeConValue");
			SelfShenDing_UpdateRongHeData();

		elseif ( event == "UPDATE_LIANDAN_COUNT" ) then
			g_nDanYaoCount = tonumber(Player:GetData("LianDanCount"));
			SelfShenDing_UpdateDanYaoUI();

		elseif ( event == "UPDATE_LIANDANLU_YAOCHEN_VALUE" ) then
			local nYaoChen = Player:GetData("YaoChenValue");
			local strText = ScriptGlobal_Format("#{XLDL_140606_30}",nYaoChen)
			SelfShenDing_YaoChen:SetText( strText );
		elseif ( event == "UPDATE_JINDAN_RONGHE_COUNT" ) then
			g_CurRongHeCount=Player:GetData("JinDanRongHeCount");
			SelfShenDing_UpdateRongHeData();

		elseif ( event == "UPDATE_JINDAN_RONGHE_MAXCOUNT" ) then
			g_MaxRongHeCount=Player:GetData("MaxJinDanRongHeCount");
			SelfShenDing_UpdateRongHeData();

		elseif ( event == "UPDATE_SMWD_ATTACK" ) then
			SelfShenDing_OnUpdateShow_Attack( 0 );

		end

		if ( event == "UI_COMMAND" and tonumber(arg0) == 201406071) then

			--处理凝炼结果
			local isSuccess = tonumber(Get_XParam_INT(0));
			local nType = tonumber(Get_XParam_INT(1));

			--成功
			if isSuccess == 1 then
				SelfShenDing_SetFlashState(2, nType);
			end
		end

	end
	if(event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		SelfShenDing_RefreshWuYiTip()
	end

	if event == "UPDATE_TOY_TIP" then
		SelfShenDing_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		SelfShenDing_RefreshCangPinTip()
	end
end

--体力及融合数据
function SelfShenDing_UpdateRongHeData()

	--总体力
	local strText = ScriptGlobal_Format("#{XLDL_140606_18}",g_ZoneConValue,g_RongHeConValue);
	SelfShenDing_ZongTiLi:SetText(strText);

	--总体力Tips
	local strTipText = ScriptGlobal_Format("#{XLDL_140606_54}",
			g_ZoneConValue-g_RongHeConValue, g_RongHeConValue );
	SelfShenDing_ZongTiLi:SetToolTip( strTipText );

	--融合的Tips
	if g_MaxRongHeCount > 0 then
		SelfShenDing_Btn_RongHe_Text:SetToolTip( "#{XLDL_140606_65}" );
	else
		SelfShenDing_Btn_RongHe_Text:SetToolTip( "#{XLDL_140606_55}" );
	end

	--融合数据
	local strRongHeText = ScriptGlobal_Format("#{XLDL_140606_56}",g_CurRongHeCount, g_MaxRongHeCount);
	SelfShenDing_Btn_RongHe_Text:SetText(strRongHeText);

	--融合效力
	local strRongHeEffText = ScriptGlobal_Format("#{XLDL_140606_66}", g_RongHeConValue );
	SelfShenDing_Btn_RongHe_Text2:SetText( strRongHeEffText );

end

--更新属性攻融合数据
function SelfShenDing_UpdateAttackRongHeData()

	local nMaxRongHe = Player:GetData("Attack_MaxJinDanCount");
	local nCurRongHe = Player:GetData("Attack_JinDanCount");
	local nRongHeAttackValue = nCurRongHe * g_AttackJinDanEffect;

	--融合的Tips
	if nMaxRongHe > 0 then
		SelfShenDing2_Btn_RongHe_Text:SetToolTip( "#{XLDL_140606_161}" );
	else
		SelfShenDing2_Btn_RongHe_Text:SetToolTip( "#{XLDL_140606_160}" );
	end

	--融合数据
	local strRongHeText = ScriptGlobal_Format("#{XLDL_140606_156}",nCurRongHe, nMaxRongHe);
	SelfShenDing2_Btn_RongHe_Text:SetText(strRongHeText);

	--融合效力
	local strRongHeEffText = ScriptGlobal_Format("#{XLDL_140606_67}", nRongHeAttackValue );
	SelfShenDing2_Btn_RongHe_Text2:SetText( strRongHeEffText );

end

function SelfShenDing_CalcChengDanLevelAndPosByCount( nDanYaoCount )
	local level = 0;
	local pos = 0;

	if nDanYaoCount ~= nil then
		local lvl=0;
		for lvl=1, 9 do
			if nDanYaoCount <= g_ChengDanParam[lvl].MaxCount then
				level = lvl;
				pos = nDanYaoCount;
				break;
			end

			nDanYaoCount = nDanYaoCount - g_ChengDanParam[lvl].MaxCount;
		end
	end

	return level, pos;
end

function SelfShenDing_UpdateDanYaoUI()

	local nLevel, nPos = SelfShenDing_CalcChengDanLevelAndPosByCount( g_nDanYaoCount );
	local nNextLevel, nNextPos = SelfShenDing_CalcChengDanLevelAndPosByCount( g_nDanYaoCount+1 );

	local strToolTip = "";
	for lvl=1, 9 do	--等级
		for count=1, g_ChengDanParam[lvl].MaxCount do
			--已有药丹的控件显示
			if lvl < nLevel or
				(lvl == nLevel and count <= nPos) then
				g_DanYaoCtrl[lvl].Index[count].ctrl:SetProperty( "BackImage", "set:SMWD_Icon image:SMWD_Icon_"..lvl )
				g_DanYaoCtrl[lvl].Index[count].Hover:Hide();
				strToolTip = ScriptGlobal_Format("#{XLDL_140606_19}",g_ChengDanParam[lvl].ConEffect)
				g_DanYaoCtrl[lvl].Index[count].ctrl:SetToolTip(strToolTip);
			end

			--要选中的那个
			if (lvl==nNextLevel and count ==nNextPos ) then
				g_DanYaoCtrl[lvl].Index[count].ctrl:SetProperty( "BackImage", "set:SMWD_1 image:SMWD_BK" )
				g_DanYaoCtrl[lvl].Index[count].Hover:Show();
				strToolTip = ScriptGlobal_Format("#{XLDL_140606_20}",g_ChengDanParam[lvl].ConEffect)
				g_DanYaoCtrl[lvl].Index[count].Hover:SetToolTip(strToolTip);
			end

			--没有药丹的控件显示(tips)
			if (lvl==nNextLevel and count >nNextPos ) or (lvl > nNextLevel and nNextLevel>0) then
				g_DanYaoCtrl[lvl].Index[count].ctrl:SetProperty( "BackImage", "set:SMWD_1 image:SMWD_BK" )
				g_DanYaoCtrl[lvl].Index[count].Hover:Hide();
				strToolTip = ScriptGlobal_Format("#{XLDL_140606_20}",g_ChengDanParam[lvl].ConEffect)
				g_DanYaoCtrl[lvl].Index[count].ctrl:SetToolTip(strToolTip);
			end

		end
	end

	--需要药尘数
	if g_nDanYaoCount >= 45 then
		SelfShenDing_XuYaoYaoChen_Text:SetText( "#{XLDL_140606_70}" );
	else
		local strYCText = ScriptGlobal_Format("#{XLDL_140606_69}",g_ChengDanParam[nNextLevel].NingLianValue)
		SelfShenDing_XuYaoYaoChen_Text:SetText( strYCText );
	end

end

--显示丹药控件
function SelfShenDing_UpdateDanYaoCtrl( DanYaoCount, DanYaoCtrl )

	local strToolTip = "";

	for cnt=1, 45 do

		--已有丹药
		if cnt <= DanYaoCount then
			DanYaoCtrl[cnt].ctrl:SetProperty( "BackImage", DanYaoCtrl[cnt].Image );
			DanYaoCtrl[cnt].Hover:Hide();
			strToolTip = ScriptGlobal_Format("#{XLDL_140606_123}",DanYaoCtrl[cnt].ConEffect)
			DanYaoCtrl[cnt].ctrl:SetToolTip(strToolTip);

		else		--还没有丹药
			DanYaoCtrl[cnt].ctrl:SetProperty( "BackImage", "set:SMWD_1 image:SMWD_BK" );
			DanYaoCtrl[cnt].Hover:Hide();
			strToolTip = ScriptGlobal_Format("#{XLDL_140606_124}",DanYaoCtrl[cnt].ConEffect)
			DanYaoCtrl[cnt].ctrl:SetToolTip(strToolTip);

		end

	end

	--处理选中的那个
	if DanYaoCount >= 0 and DanYaoCount < 45 then
		DanYaoCtrl[DanYaoCount+1].Hover:Show();
		strToolTip = ScriptGlobal_Format("#{XLDL_140606_124}",DanYaoCtrl[DanYaoCount+1].ConEffect)
		DanYaoCtrl[DanYaoCount+1].Hover:SetToolTip(strToolTip);
	end

end

--显示体力页面
function SelfShenDing_OnUpdateShow()

	SelfShenDing_Frame_Part:Show();
	SelfShenDing2_Frame_Part:Hide();
	SelfShenDing_FenYe1:SetCheck(1)
	SelfShenDing_FenYe2:SetCheck(0)

	SelfShenDing_SetFlashState(0, 0);

	--体力
	g_ZoneConValue=Player:GetData("LIANDANLUCONVALUE");
	g_RongHeConValue=Player:GetData("RongHeConValue");

	--药丹等级
	g_nDanYaoCount = tonumber(Player:GetData("LianDanCount"));

	--药尘
	local nYaoChen = Player:GetData("YaoChenValue");
	local strText = ScriptGlobal_Format("#{XLDL_140606_30}",nYaoChen)
	SelfShenDing_YaoChen:SetText( strText );

	--融合
	g_CurRongHeCount=Player:GetData("JinDanRongHeCount");
	g_MaxRongHeCount=Player:GetData("MaxJinDanRongHeCount");

	SelfShenDing_UpdateDanYaoUI();
	SelfShenDing_UpdateRongHeData();

end

--显示当前各属性攻及潜能点的值
function SelfShenDing_UpdateAttackPoints()

	--显示数值
	SelfShenDing2_ShuXingGong_QianNeng_Text2:SetText( "#cfff263"..tostring(g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue) );

	SelfShenDing2_ShuXingGong_Bing_Text2:SetText( "#H"..tostring(g_AttackValue[1].DBValue + g_AttackValue[1].SettingValue) );
	SelfShenDing2_ShuXingGong_Huo_Text2:SetText( "#H"..tostring(g_AttackValue[2].DBValue + g_AttackValue[2].SettingValue) );
	SelfShenDing2_ShuXingGong_Xuan_Text2:SetText( "#H"..tostring(g_AttackValue[3].DBValue + g_AttackValue[3].SettingValue) );
	SelfShenDing2_ShuXingGong_Du_Text2:SetText( "#H"..tostring(g_AttackValue[4].DBValue + g_AttackValue[4].SettingValue) );

	--四对加减按钮状态
	for idx=1, 4 do

		if g_AttackIFTPButtons[idx] == nil or
				g_AttackIFTPButtons[idx].AddBtn == nil or
				g_AttackIFTPButtons[idx].SubBtn == nil then
			continue;
		end

		--加按钮
		if g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue > 0 then	--仍有潜能点
			g_AttackIFTPButtons[idx].AddBtn : Enable();
		else
			g_AttackIFTPButtons[idx].AddBtn : Disable();
		end

		--减按钮
		if g_AttackValue[idx].SettingValue > 0 then
			g_AttackIFTPButtons[idx].SubBtn : Enable();
		else
			g_AttackIFTPButtons[idx].SubBtn : Disable();
		end
	end

	--确定按钮
	if g_AttackValue[0].SettingValue == 0 then	--没有变化
		SelfShenDing2_ShuXingGong_Accept : Disable();
	else
		SelfShenDing2_ShuXingGong_Accept : Enable();
	end

	--重置按钮
	if (g_AttackValue[1].DBValue + g_AttackValue[2].DBValue +
		g_AttackValue[3].DBValue + g_AttackValue[4].DBValue) > 0 then
		SelfShenDing2_ShuXingGong_Reset : Enable();
		SelfShenDing2_ShuXingGong_Reset_Tips : Hide();
	else
		SelfShenDing2_ShuXingGong_Reset : Disable();
		SelfShenDing2_ShuXingGong_Reset_Tips : Show();
	end

end

--显示属性攻页面
function SelfShenDing_OnUpdateShow_Attack( IsSwitch )

	if IsSwitch == 1 then
		SelfShenDing_Frame_Part:Hide();
		SelfShenDing2_Frame_Part:Show();
		SelfShenDing_FenYe1:SetCheck(0)
		SelfShenDing_FenYe2:SetCheck(1)

		SelfShenDing_SetFlashState(0, 1);
	end

	--药丹等级
	local nAttackDanYaoCount = tonumber(Player:GetData("Attack_DanYaoCount"));

	SelfShenDing_UpdateDanYaoCtrl( nAttackDanYaoCount, g_DanYaoAttack );

	--需要药尘数
	if nAttackDanYaoCount < 0 or nAttackDanYaoCount >= 45 then
		SelfShenDing2_XuYaoYaoChen_Text:SetText( "#{XLDL_140606_70}" );
	else
		local strYCText = ScriptGlobal_Format("#{XLDL_140606_69}",g_ChengDanParam[g_DanYaoAttack[nAttackDanYaoCount+1].Level].NingLianValue)
		SelfShenDing2_XuYaoYaoChen_Text:SetText( strYCText );
	end

	--融合界面
	SelfShenDing_UpdateAttackRongHeData();

	--各项属性及潜能点
	g_AttackValue[0].DBValue = tonumber(Player:GetData("Attack_QianNengPoint"));
	local nIce, nFire, nThunder, nPoison = Player:GetData("Attack_IFTPValue");
	g_AttackValue[1].DBValue = nIce;
	g_AttackValue[2].DBValue = nFire;
	g_AttackValue[3].DBValue = nThunder;
	g_AttackValue[4].DBValue = nPoison;

	for idx=0, 4 do
		g_AttackValue[idx].SettingValue = 0;
	end

	SelfShenDing_UpdateAttackPoints();

	--增加界面潜能数值显示部分鼠标悬浮tips
	local nCurRongHe = Player:GetData("Attack_JinDanCount");
	local nRongHeAttackValue = nCurRongHe * g_AttackJinDanEffect;

	local strToolTip = ScriptGlobal_Format( "#{XLDL_140606_147}",
			(g_AttackValue[0].DBValue+nIce+nFire+nThunder+nPoison - nRongHeAttackValue) );
	local strToolTip2 = ScriptGlobal_Format( "#{XLDL_140606_148}", nRongHeAttackValue );
	SelfShenDing2_ShuXingGong_QianNeng_Text1:SetToolTip( strToolTip.."#r"..strToolTip2 );
	SelfShenDing2_ShuXingGong_QianNeng_Text2:SetToolTip( strToolTip.."#r"..strToolTip2 );

end

--凝炼
function SelfShenDing_NingLian()

	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end

	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	--距离前一次凝炼是否大于等于0.5秒（该0.5秒为神木王鼎的凝炼过程动画的时间长度） XLDL_140606_34
	if g_bFlasgTimer > 0 then
		PushDebugMessage( "#{XLDL_140606_34}" );
		return
	end
	
	SelfShenDing_SetFlashState(1, 0);
	
	--开始凝炼
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnLianDanLuNingLian");
		Set_XSCRIPT_ScriptID(339008);
		Set_XSCRIPT_Parameter(0, tonumber(SelfShenDing_querengoumai:GetCheck()) )
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();

end

--属性攻凝炼
function SelfShenDing2_NingLian()

	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end

	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	--距离前一次凝炼是否大于等于0.5秒（该0.5秒为神木王鼎的凝炼过程动画的时间长度） XLDL_140606_34
	if g_bFlasgTimer > 0 then
		PushDebugMessage( "#{XLDL_140606_34}" );
		return
	end

	SelfShenDing_SetFlashState(1, 1);
	
	--开始凝炼
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnLianDanLuNingLian");
		Set_XSCRIPT_ScriptID(339011);
		Set_XSCRIPT_Parameter(0, tonumber(SelfShenDing_querengoumai:GetCheck()) )
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
		
end

--融合
function SelfShenDing_RongHe()

	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end

	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	--开始融合
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnLianDanLuRongHe");
		Set_XSCRIPT_ScriptID(339008);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end

--属性攻融合
function SelfShenDing2_RongHe()

	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end

	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	--开始融合
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnLianDanLuRongHe");
		Set_XSCRIPT_ScriptID(339011);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end

--查看帮助
function SelfShenDing_BangZhu()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnLianDanLuHelp");
		Set_XSCRIPT_ScriptID(339008);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end

--分页
function SelfShenDing_ChangeTabIndex( page )

	if page == 0 then
		SelfShenDing_OnUpdateShow();
	elseif page == 1 then
		SelfShenDing_OnUpdateShow_Attack( 1 );
	end

end

--属性攻确定事件
function SelfShenDing2_Accept_Click()

	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end

	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	--潜能点是否分配
	if g_AttackValue[0].SettingValue <= 0 then
		PushDebugMessage("#{XLDL_140606_102}")
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnLianDanLuQianNengAccept");
		Set_XSCRIPT_ScriptID(339011);
		Set_XSCRIPT_Parameter(0, tonumber(g_AttackValue[1].DBValue + g_AttackValue[1].SettingValue) )
		Set_XSCRIPT_Parameter(1, tonumber(g_AttackValue[2].DBValue + g_AttackValue[2].SettingValue) )
		Set_XSCRIPT_Parameter(2, tonumber(g_AttackValue[3].DBValue + g_AttackValue[3].SettingValue) )
		Set_XSCRIPT_Parameter(3, tonumber(g_AttackValue[4].DBValue + g_AttackValue[4].SettingValue) )
		Set_XSCRIPT_ParamCount(4);
	Send_XSCRIPT();
end

--属性攻重置事件
function SelfShenDing2_Reset_Click()

	--潜能点是否分配
	if (g_AttackValue[1].DBValue+g_AttackValue[2].DBValue+g_AttackValue[3].DBValue+g_AttackValue[4].DBValue) <= 0 then
		PushDebugMessage("#{XLDL_140606_103}")
		return
	end

	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end

	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	PushEvent( "SHENDING_RESET_CONFIRM", 339011 );
end

--属性攻加减点 MouseLeave & MouseEnter：index取值(1~8)
function SelfShenDing2_AutoClick_Clear( index )

	local id = tonumber(index)
	if (id == g_AutoClick_BtnFlag) then
		g_AutoClick_BtnFlag = -1
	end

end

--属性攻加减点 Clicked ：index取值(1~8)
function SelfShenDing2_AutoClick_LButtonUp( index )
	local id = tonumber( index )
	SelfShenDing2_AutoClick_Clear( index )
	if g_AutoClick_FunList[id] ~= nil then
		g_AutoClick_FunList[id]( 1 )
	end
end

--属性攻加减点 MouseLButtonDown ：index取值(1~8)
function SelfShenDing2_AutoClick_SetTimer( index )

	local id = tonumber(index);
	g_AutoClick_Going = -1;
	g_AutoClick_BtnFlag = id;

end

--================================================
--自动加减点函数们
function SelfShenDing_AutoClick_Timer()
	if (g_AutoClick_BtnFlag ~= -1) then
		-- 第一次LButton后经过X个Timer才算开始, 也就是说是 g_AutoClickTimer_Step * X 的时候开始进行自动加, 这样为了防止本来要点击一下的结果点了好多下
		if (g_AutoClick_Going < 4) then
			g_AutoClick_Going = g_AutoClick_Going + 1
		elseif (g_AutoClick_Going < 10) then
			if g_AutoClick_FunList[g_AutoClick_BtnFlag] ~= nil then
				g_AutoClick_FunList[g_AutoClick_BtnFlag]( 10 )
			end
			g_AutoClick_Going = g_AutoClick_Going + 1;
		else
			if g_AutoClick_FunList[g_AutoClick_BtnFlag] ~= nil then
				g_AutoClick_FunList[g_AutoClick_BtnFlag]( 50 )
			end
			g_AutoClick_Going = g_AutoClick_Going + 1;
		end
	end
end

function SelfShenDing2_IceAttack_Add_Click( nStep )

	--没有潜能点可加
	if (g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue) <= 0 then
		PushDebugMessage( "#{XLDL_140606_100}" );
		return
	end

	if (g_AttackValue[1].DBValue + g_AttackValue[1].SettingValue) >= g_MaxEffect then
		PushDebugMessage( "#{XLDL_140606_101}" );
		return
	end

	if (g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue) < nStep then
		nStep = g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue;
	end

	g_AttackValue[1].SettingValue = g_AttackValue[1].SettingValue + nStep;
	g_AttackValue[0].SettingValue = g_AttackValue[0].SettingValue + nStep;

	SelfShenDing_UpdateAttackPoints()

end

function SelfShenDing2_IceAttack_Dec_Click( nStep )

	--没有潜能点可减
	if g_AttackValue[1].SettingValue <= 0 then
		return
	end

	if g_AttackValue[1].SettingValue < nStep then
		nStep = g_AttackValue[1].SettingValue;
	end

	g_AttackValue[1].SettingValue = g_AttackValue[1].SettingValue - nStep;
	g_AttackValue[0].SettingValue = g_AttackValue[0].SettingValue - nStep;

	SelfShenDing_UpdateAttackPoints()

end
function SelfShenDing2_FireAttack_Add_Click( nStep )
	--没有潜能点可加
	if (g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue) <= 0 then
		PushDebugMessage( "#{XLDL_140606_100}" );
		return
	end

	if (g_AttackValue[2].DBValue + g_AttackValue[2].SettingValue) >= g_MaxEffect then
		PushDebugMessage( "#{XLDL_140606_101}" );
		return
	end

	if (g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue) < nStep then
		nStep = g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue;
	end

	g_AttackValue[2].SettingValue = g_AttackValue[2].SettingValue + nStep;
	g_AttackValue[0].SettingValue = g_AttackValue[0].SettingValue + nStep;

	SelfShenDing_UpdateAttackPoints()

end
function SelfShenDing2_FireAttack_Dec_Click( nStep )
	--没有潜能点可减
	if g_AttackValue[2].SettingValue <= 0 then
		return
	end

	if g_AttackValue[2].SettingValue < nStep then
		nStep = g_AttackValue[2].SettingValue;
	end

	g_AttackValue[2].SettingValue = g_AttackValue[2].SettingValue - nStep;
	g_AttackValue[0].SettingValue = g_AttackValue[0].SettingValue - nStep;

	SelfShenDing_UpdateAttackPoints()
end
function SelfShenDing2_ThunderAttack_Add_Click( nStep )
	--没有潜能点可加
	if (g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue) <= 0 then
		PushDebugMessage( "#{XLDL_140606_100}" );
		return
	end

	if (g_AttackValue[3].DBValue + g_AttackValue[3].SettingValue) >= g_MaxEffect then
		PushDebugMessage( "#{XLDL_140606_101}" );
		return
	end

	if (g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue) < nStep then
		nStep = g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue;
	end

	g_AttackValue[3].SettingValue = g_AttackValue[3].SettingValue + nStep;
	g_AttackValue[0].SettingValue = g_AttackValue[0].SettingValue + nStep;

	SelfShenDing_UpdateAttackPoints()
end
function SelfShenDing2_ThunderAttack_Dec_Click( nStep )
	--没有潜能点可减
	if g_AttackValue[3].SettingValue <= 0 then
		return
	end

	if g_AttackValue[3].SettingValue < nStep then
		nStep = g_AttackValue[3].SettingValue;
	end

	g_AttackValue[3].SettingValue = g_AttackValue[3].SettingValue - nStep;
	g_AttackValue[0].SettingValue = g_AttackValue[0].SettingValue - nStep;

	SelfShenDing_UpdateAttackPoints()
end
function SelfShenDing2_PoisonAttack_Add_Click( nStep )
	--没有潜能点可加
	if (g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue) <= 0 then
		PushDebugMessage( "#{XLDL_140606_100}" );
		return
	end

	if (g_AttackValue[4].DBValue + g_AttackValue[4].SettingValue) >= g_MaxEffect then
		PushDebugMessage( "#{XLDL_140606_101}" );
		return
	end

	if (g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue) < nStep then
		nStep = g_AttackValue[0].DBValue - g_AttackValue[0].SettingValue;
	end

	g_AttackValue[4].SettingValue = g_AttackValue[4].SettingValue + nStep;
	g_AttackValue[0].SettingValue = g_AttackValue[0].SettingValue + nStep;

	SelfShenDing_UpdateAttackPoints()
end
function SelfShenDing2_PoisonAttack_Dec_Click( nStep )
	--没有潜能点可减
	if g_AttackValue[4].SettingValue <= 0 then
		return
	end

	if g_AttackValue[4].SettingValue < nStep then
		nStep = g_AttackValue[4].SettingValue;
	end

	g_AttackValue[4].SettingValue = g_AttackValue[4].SettingValue - nStep;
	g_AttackValue[0].SettingValue = g_AttackValue[0].SettingValue - nStep;

	SelfShenDing_UpdateAttackPoints()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function SelfShenDing_Frame_On_ResetPos()

	SelfShenDing_Frame : SetProperty("UnifiedXPosition", g_SelfShenDing_Frame_UnifiedXPosition);
	SelfShenDing_Frame : SetProperty("UnifiedYPosition", g_SelfShenDing_Frame_UnifiedYPosition);

end

function SelfShenDing_OnMoved()
	if "SelfEquip" == GetFreshManGuideOwner() then
  end
end

function SelfShenDing_CloseFunction()
	g_AutoClick_Going = -1
	g_AutoClick_BtnFlag = -1
	KillTimer("SelfShenDing_AutoClick_Timer()")
	
	g_SelfShenDing_YuanbaoPay = SelfShenDing_querengoumai:GetCheck();
	this:Hide();
end

--装备
function SelfShenDing_SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);

	OpenEquip(1);
	SelfShenDing_CloseFunction();
end

--资料
function SelfShenDing_SelfData_Switch()
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("self");
	SelfShenDing_CloseFunction();
end

--珍兽
function SelfShenDing_Pet_Switch()
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	TogglePetPage();
	SelfShenDing_CloseFunction();
end

--子女
function SelfShenDing_Infant_Switch()
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	if bRet == 1 then
		SelfShenDing_CloseFunction();
	end
end

--武魂
function SelfShenDing_Wuhun_Switch()
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
	SelfShenDing_CloseFunction();
end

--修炼
function SelfShenDing_Xiulian_Switch()
  local nLevel = Player:GetData("LEVEL")
	if(nLevel >= 70) then
		Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);
		XiuLianPage();
		SelfShenDing_CloseFunction();
	else
		SelfShenDing_SetTabColor(9);
	  PushDebugMessage("#{XL_090707_62}")
	end
end

--秘籍
function SelfShenDing_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenMijiPage();
	if bRet == 1 then
		SelfShenDing_CloseFunction();
	else
		SelfShenDing_SetTabColor(9);
	end
end

--真元
function SelfShenDing_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet == 1 then
		SelfShenDing_CloseFunction();
	else
		SelfShenDing_SetTabColor(9);
	end
end

--经脉
function SelfShenDing_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenJingMaiPage();
	if nRet == 1 then
		SelfShenDing_CloseFunction();
	else
		SelfShenDing_SetTabColor(9)
	end
end

--神鼎
function SelfShenDing_ShenDing_Page_Switch()
end

--骑乘
function SelfShenDing_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);

	OpenRidePage();
	SelfShenDing_CloseFunction();
end

--其他
function SelfShenDing_Other_Info_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);

	OtherInfoPage();
	SelfShenDing_CloseFunction();
end

--=======================================================
--凝丹的Flash控制
--=======================================================
function SelfShenDing_SetFlashState(idx, type)
	if( idx == nil or idx < 0 or idx > 3 ) then
		return
	end

	if( type < 0 or type > 1 ) then
		return
	end

	local FlashProc={
		[0]="SelfShenDing_ConFlashTimerProc()",
		[1]="SelfShenDing_AttackFlashTimerProc()",
		}

	if g_bFlasgTimer > 0 then
		KillTimer( FlashProc[type] );
		g_bFlasgTimer = 0;
	end

	local tab = {};

	if type == 0 then
		tab[0] = SelfShenDing_Flash2_PingShi;
		tab[1] = SelfShenDing_Flash2_GuoCheng;
		tab[2] = SelfShenDing_Flash2_ChengGong;
	elseif type == 1 then
		tab[0] = SelfShenDing2_Flash2_PingShi;
		tab[1] = SelfShenDing2_Flash2_GuoCheng;
		tab[2] = SelfShenDing2_Flash2_ChengGong;
	end

		local i = 0;
		while i < 3 do
			if i == idx then
				tab[i]:Show();
			else
				tab[i]:Hide();
			end

			i = i + 1;
		end

		--要把状态恢复成正常，需要Timer
		if idx ~= 0 then
			SetTimer("SelfShenDing", FlashProc[type], 500)
			g_bFlasgTimer = 1;
		end

end

function SelfShenDing_ConFlashTimerProc()
	SelfShenDing_SetFlashState(0, 0);
end
function SelfShenDing_AttackFlashTimerProc()
	SelfShenDing_SetFlashState(0, 1);
end

--===============================================
-- SetTabColor
--===============================================
function SelfShenDing_SetTabColor(idx)
	if(idx == nil or idx < 0 or idx > 11) then
		return;
	end

	local i = 0;
	local selColor = "#Y";
	local noselColor = "";
	local tab = {
								[0] = SelfShenDing_SelfEquip,
								SelfShenDing_SelfData,
								SelfShenDing_Pet,
								SelfShenDing_Infant,
								SelfShenDing_Wuhun,
								SelfShenDing_Xiulian,
								SelfShenDing_Miji,
								SelfShenDing_ZhenYuan,
								SelfShenDing_JingMai,
								SelfShenDing_ShenDing,
								SelfShenDing_JueWei,
								SelfShenDing_Ride,
								SelfShenDing_OtherInfo,
							};

	while i < 13 do
		if(i == idx) then
			tab[i]:SetCheck(1);
		else
			tab[i]:SetCheck(0);
		end
		i = i + 1;
	end
end

function SelfShenDing_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		SelfShenDing_CloseFunction()
	end
end

function SelfShenDing_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end

function SelfShenDing_Refresh_Page_Button( nLevel)

	if 1 == 1 then
		return
	end
	

	--神鼎
	if ( nLevel < 15 ) then
		SelfShenDing_ShenDing:Disable()
		SelfShenDing_ShenDing_tips:Show()
--		SelfShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		SelfShenDing_ShenDing:Enable()
		SelfShenDing_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		SelfShenDing_Infant:Disable()
		SelfShenDing_Infant_tips:Show()
	--	SelfShenDing_Infant:SetToolTip("#{RWYQ_150707_01}")
	else
		SelfShenDing_Infant:Enable()
		SelfShenDing_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		SelfShenDing_Wuhun:Disable()
--		SelfShenDing_Wuhun_tips:Show()
	--	SelfShenDing_Wuhun:SetToolTip("#{RWYQ_150707_02}")
--	else
		SelfShenDing_Wuhun:Enable()
		SelfShenDing_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		SelfShenDing_Xiulian:Disable()
		SelfShenDing_Xiulian_tips:Show()
	--	SelfShenDing_Xiulian:SetToolTip("#{RWYQ_150707_03}")
	else
		SelfShenDing_Xiulian:Enable()
		SelfShenDing_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		SelfShenDing_Miji:Disable()
		SelfShenDing_Miji_tips:Show()
	--	SelfShenDing_Miji:SetToolTip("#{RWYQ_150707_04}")
	else
		SelfShenDing_Miji:Enable()
		SelfShenDing_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		SelfShenDing_ZhenYuan:Disable()
		SelfShenDing_ZhenYuan_tips:Show()
	--	SelfShenDing_ZhenYuan:SetToolTip("#{RWYQ_150707_05}")
	else
		SelfShenDing_ZhenYuan:Enable()
		SelfShenDing_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		SelfShenDing_JueWei:Disable()
	--	SelfShenDing_JueWei:SetToolTip("#{RWYQ_150707_08}")
	else
		SelfShenDing_JueWei:Enable()
		SelfShenDing_JueWei_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		SelfShenDing_JingMai:Disable()
	--	SelfShenDing_JingMai:SetToolTip("#{RWYQ_150707_06}")
	else
		SelfShenDing_JingMai:Enable()
		SelfShenDing_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		SelfShenDing_BaoJian:Disable()
		SelfShenDing_BaoJian_tips:Show()
	else
		SelfShenDing_BaoJian:Enable()
		SelfShenDing_BaoJian_tips:Hide()
	end

	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		SelfShenDing_WuYi:Enable()
		SelfShenDing_WuYi_tips:Hide()
	else
		SelfShenDing_WuYi:Disable()
		SelfShenDing_WuYi_tips:Show()
	end
	SelfShenDing_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		SelfShenDing_ShenQi:Enable()
		SelfShenDing_ShenQi_tips:Hide()
	else
		SelfShenDing_ShenQi:Disable()
		SelfShenDing_ShenQi_tips:Show()
	end
	SelfShenDing_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		SelfShenDing_Armor:Enable()
		SelfShenDing_Armor_tips:Hide()
	else
		SelfShenDing_Armor:Disable()
		SelfShenDing_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		SelfShenDing_CangPin:Enable()
		SelfShenDing_CangPin_tips:Hide()
	else
		SelfShenDing_CangPin:Disable()
		SelfShenDing_CangPin_tips:Show()
	end
	
	SelfShenDing_RefreshCangPinTip()
end

function SelfShenDing_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

function SelfShenDing_OnShown()
	--yuanbaoPay
	if g_SelfShenDing_YuanbaoPay == 1 or g_SelfShenDing_YuanbaoPay == 0 then
		SelfShenDing_querengoumai:SetCheck(g_SelfShenDing_YuanbaoPay)
	end
	this:Show();
end

--确认购买
function SelfShenDing_querengoumai_Clicked()
end

-- 九星神器DIY技能
function SelfShenDing_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function SelfShenDing_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfShenDing_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfShenDing_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		SelfShenDing_WuYi_Buttontips:Show()
	else
		SelfShenDing_WuYi_Buttontips:Hide()
	end
end

function SelfShenDing_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfShenDing_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfShenDing_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		SelfShenDing_OtherInfo_ButtonTips:Show()
	else
		SelfShenDing_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function SelfShenDing_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function SelfShenDing_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfShenDing_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function SelfShenDing_RefreshCangPinTip()
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
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfShenDing_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfShenDing_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		SelfShenDing_CangPin_Buttontips:Show()
	else
		SelfShenDing_CangPin_Buttontips:Hide()
	end
end


function SelfShenDing_ShowPage()

	for i = 1, table.getn(g_SelfShenDing_Page) do
		g_SelfShenDing_PageButton[i]:Hide()
		g_SelfShenDing_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	SelfShenDing_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_SelfShenDing_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_SelfShenDing_Page) do
			if i ~= nPageNumber then
				g_SelfShenDing_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_SelfShenDing_Page) do
		if SelfShenDing_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_SelfShenDing_PageButton[g_PageCount]:Show()
			g_SelfShenDing_PageButton[g_PageCount]:SetText(g_SelfShenDing_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if SelfShenDing_IsPageEnable(i) == 1 then
				g_SelfShenDing_PageButton[g_PageCount]:Enable()
				g_SelfShenDing_PageMask[g_PageCount]:Hide()
			else
				g_SelfShenDing_PageButton[g_PageCount]:Disable()
				g_SelfShenDing_PageMask[g_PageCount]:Show()
				if g_SelfShenDing_Page[i].Tip ~= "" then
					g_SelfShenDing_PageMask[g_PageCount]:SetToolTip(g_SelfShenDing_Page[i].Tip)
				end
			end
		end
	end
	
	SelfShenDing_RefreshWuYiTip()
	SelfShenDing_RefreshOtherInfoTip()
	SelfShenDing_RefreshCangPinTip()
	
end

function SelfShenDing_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		SelfShenDing_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		SelfShenDing_SelfData_Switch()
	elseif idx == 3 then--珍兽
		SelfShenDing_Pet_Switch()
	elseif idx == 4 then--子女
		SelfShenDing_Infant_Switch()
	elseif idx == 5 then--武魂
		SelfShenDing_Wuhun_Switch()
	elseif idx == 6 then--修炼
		SelfShenDing_Xiulian_Switch()
	elseif idx == 7 then--秘籍
		SelfShenDing_Miji_Page_Switch()
	elseif idx == 8 then--真元
		SelfShenDing_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		SelfShenDing_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		SelfShenDing_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		SelfShenDing_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		SelfShenDing_OpenBaoJian()
	elseif idx == 13 then--武意
		SelfShenDing_OpenWuYi()
	elseif idx == 14 then--神器
		SelfShenDing_OpenShenQi()
	elseif idx == 15 then--星盘
		SelfShenDing_Armor_Page_Switch()
	elseif idx == 16 then--名物
		SelfShenDing_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		SelfShenDing_Other_Info_Page_Switch()
	end
end

function SelfShenDing_CheckPage(idx)
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

function SelfShenDing_IsPageEnable(idx)
	
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

function SelfShenDing_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


