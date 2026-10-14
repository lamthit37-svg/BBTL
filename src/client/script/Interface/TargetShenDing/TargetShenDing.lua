--TargetShenDing.lua
local g_TargetShenDing_Frame_UnifiedPosition = nil;

local g_DanYaoCtrl = {};

local g_ZongConValue=0;
local g_RongHeConValue=0;
local g_CurRongHeCount=0;
local g_MaxRongHeCount=0;
local g_nDanYaoCount=0;

local g_DanYaoAttack = {};

local g_ChengDanParam={
	[1] = { ConEffect=15,  MaxCount=1 },
	[2] = { ConEffect=17,  MaxCount=2 },
	[3] = { ConEffect=19, MaxCount=3 },
	[4] = { ConEffect=24, MaxCount=4 },
	[5] = { ConEffect=29, MaxCount=5 },
	[6] = { ConEffect=34, MaxCount=6 },
	[7] = { ConEffect=39, MaxCount=7 },
	[8] = { ConEffect=45, MaxCount=8 },
	[9] = { ConEffect=51, MaxCount=9 },
	};
	
--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_TargetShenDing_Page = {
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

function TargetShenDing_PreLoad()
	-- 打开界面
	this:RegisterEvent("OPEN_OTHERPLAYER_SHENDING");
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function TargetShenDing_OnLoad()
	-- 保存界面的默认相对位置
	g_TargetShenDing_Frame_UnifiedPosition = TargetShenDing_Frame:GetProperty("UnifiedPosition")
		
	g_DanYaoCtrl[1] = { count=1, 
		Index = { 
			[1] = { ctrl = TargetShenDing_BK_1_Item1, Hover = TargetShenDing_BK_1_Item1_Hover }, 
			};
		};
	g_DanYaoCtrl[2] = { count=2, 
		Index = { 
			[1] = { ctrl = TargetShenDing_BK_2_Item1, Hover = TargetShenDing_BK_2_Item1_Hover }, 
			[2] = { ctrl = TargetShenDing_BK_2_Item2, Hover = TargetShenDing_BK_2_Item2_Hover }, 
			 };
		};
	g_DanYaoCtrl[3] = { count=3, 
		Index = { 
			[1] = { ctrl = TargetShenDing_BK_3_Item1, Hover = TargetShenDing_BK_3_Item1_Hover }, 
			[2] = { ctrl = TargetShenDing_BK_3_Item2, Hover = TargetShenDing_BK_3_Item2_Hover }, 
			[3] = { ctrl = TargetShenDing_BK_3_Item3, Hover = TargetShenDing_BK_3_Item3_Hover }, 
			};
		};
	g_DanYaoCtrl[4] = { count=4, 
		Index = { 
			[1] = { ctrl = TargetShenDing_BK_4_Item1, Hover = TargetShenDing_BK_4_Item1_Hover }, 
			[2] = { ctrl = TargetShenDing_BK_4_Item2, Hover = TargetShenDing_BK_4_Item2_Hover }, 
			[3] = { ctrl = TargetShenDing_BK_4_Item3, Hover = TargetShenDing_BK_4_Item3_Hover }, 
			[4] = { ctrl = TargetShenDing_BK_4_Item4, Hover = TargetShenDing_BK_4_Item4_Hover }, 
			};
		};
	g_DanYaoCtrl[5] = { count=5, 
		Index = { 
			[1] = { ctrl = TargetShenDing_BK_5_Item1, Hover = TargetShenDing_BK_5_Item1_Hover }, 
			[2] = { ctrl = TargetShenDing_BK_5_Item2, Hover = TargetShenDing_BK_5_Item2_Hover }, 
			[3] = { ctrl = TargetShenDing_BK_5_Item3, Hover = TargetShenDing_BK_5_Item3_Hover }, 
			[4] = { ctrl = TargetShenDing_BK_5_Item4, Hover = TargetShenDing_BK_5_Item4_Hover }, 
			[5] = { ctrl = TargetShenDing_BK_5_Item5, Hover = TargetShenDing_BK_5_Item5_Hover }, 
			};
		};
	g_DanYaoCtrl[6] = { count=6, 
		Index = { 
			[1] = { ctrl = TargetShenDing_BK_6_Item1, Hover = TargetShenDing_BK_6_Item1_Hover }, 
			[2] = { ctrl = TargetShenDing_BK_6_Item2, Hover = TargetShenDing_BK_6_Item2_Hover }, 
			[3] = { ctrl = TargetShenDing_BK_6_Item3, Hover = TargetShenDing_BK_6_Item3_Hover }, 
			[4] = { ctrl = TargetShenDing_BK_6_Item4, Hover = TargetShenDing_BK_6_Item4_Hover }, 
			[5] = { ctrl = TargetShenDing_BK_6_Item5, Hover = TargetShenDing_BK_6_Item5_Hover }, 
			[6] = { ctrl = TargetShenDing_BK_6_Item6, Hover = TargetShenDing_BK_6_Item6_Hover }, 
			};
		};
	g_DanYaoCtrl[7] = { count=7, 
		Index = { 
			[1] = { ctrl = TargetShenDing_BK_7_Item1, Hover = TargetShenDing_BK_7_Item1_Hover }, 
			[2] = { ctrl = TargetShenDing_BK_7_Item2, Hover = TargetShenDing_BK_7_Item2_Hover }, 
			[3] = { ctrl = TargetShenDing_BK_7_Item3, Hover = TargetShenDing_BK_7_Item3_Hover }, 
			[4] = { ctrl = TargetShenDing_BK_7_Item4, Hover = TargetShenDing_BK_7_Item4_Hover }, 
			[5] = { ctrl = TargetShenDing_BK_7_Item5, Hover = TargetShenDing_BK_7_Item5_Hover }, 
			[6] = { ctrl = TargetShenDing_BK_7_Item6, Hover = TargetShenDing_BK_7_Item6_Hover }, 
			[7] = { ctrl = TargetShenDing_BK_7_Item7, Hover = TargetShenDing_BK_7_Item7_Hover }, 
			};
		};
	g_DanYaoCtrl[8] = { count=8, 
		Index = { 
			[1] = { ctrl = TargetShenDing_BK_8_Item1, Hover = TargetShenDing_BK_8_Item1_Hover }, 
			[2] = { ctrl = TargetShenDing_BK_8_Item2, Hover = TargetShenDing_BK_8_Item2_Hover }, 
			[3] = { ctrl = TargetShenDing_BK_8_Item3, Hover = TargetShenDing_BK_8_Item3_Hover }, 
			[4] = { ctrl = TargetShenDing_BK_8_Item4, Hover = TargetShenDing_BK_8_Item4_Hover }, 
			[5] = { ctrl = TargetShenDing_BK_8_Item5, Hover = TargetShenDing_BK_8_Item5_Hover }, 
			[6] = { ctrl = TargetShenDing_BK_8_Item6, Hover = TargetShenDing_BK_8_Item6_Hover }, 
			[7] = { ctrl = TargetShenDing_BK_8_Item7, Hover = TargetShenDing_BK_8_Item7_Hover }, 
			[8] = { ctrl = TargetShenDing_BK_8_Item8, Hover = TargetShenDing_BK_8_Item8_Hover }, 
			};
		};
	g_DanYaoCtrl[9] = { count=9, 
		Index = { 
			[1] = { ctrl = TargetShenDing_BK_9_Item1, Hover = TargetShenDing_BK_9_Item1_Hover }, 
			[2] = { ctrl = TargetShenDing_BK_9_Item2, Hover = TargetShenDing_BK_9_Item2_Hover }, 
			[3] = { ctrl = TargetShenDing_BK_9_Item3, Hover = TargetShenDing_BK_9_Item3_Hover }, 
			[4] = { ctrl = TargetShenDing_BK_9_Item4, Hover = TargetShenDing_BK_9_Item4_Hover }, 
			[5] = { ctrl = TargetShenDing_BK_9_Item5, Hover = TargetShenDing_BK_9_Item5_Hover }, 
			[6] = { ctrl = TargetShenDing_BK_9_Item6, Hover = TargetShenDing_BK_9_Item6_Hover }, 
			[7] = { ctrl = TargetShenDing_BK_9_Item7, Hover = TargetShenDing_BK_9_Item7_Hover }, 
			[8] = { ctrl = TargetShenDing_BK_9_Item8, Hover = TargetShenDing_BK_9_Item8_Hover }, 
			[9] = { ctrl = TargetShenDing_BK_9_Item9, Hover = TargetShenDing_BK_9_Item9_Hover }, 
			};
		};
		
		--属性攻的控件	
	g_DanYaoAttack[1] = { ctrl=TargetShenDing2_BK_1_Item1, Hover=TargetShenDing2_BK_1_Item1_Hover, Level=1, Count=1, ConEffect=10, Image="set:SMWD_Icon image:SMWD_Icon_1"};
	
	g_DanYaoAttack[2] = { ctrl=TargetShenDing2_BK_2_Item1, Hover=TargetShenDing2_BK_2_Item1_Hover, Level=2, Count=1, ConEffect=14, Image="set:SMWD_Icon image:SMWD_Icon_2"};
	g_DanYaoAttack[3] = { ctrl=TargetShenDing2_BK_2_Item2, Hover=TargetShenDing2_BK_2_Item2_Hover, Level=2, Count=2, ConEffect=14, Image="set:SMWD_Icon image:SMWD_Icon_2"};
	
	g_DanYaoAttack[4] = { ctrl=TargetShenDing2_BK_3_Item1, Hover=TargetShenDing2_BK_3_Item1_Hover, Level=3, Count=1, ConEffect=18, Image="set:SMWD_Icon image:SMWD_Icon_3"};
	g_DanYaoAttack[5] = { ctrl=TargetShenDing2_BK_3_Item2, Hover=TargetShenDing2_BK_3_Item2_Hover, Level=3, Count=2, ConEffect=18, Image="set:SMWD_Icon image:SMWD_Icon_3"};
	g_DanYaoAttack[6] = { ctrl=TargetShenDing2_BK_3_Item3, Hover=TargetShenDing2_BK_3_Item3_Hover, Level=3, Count=3, ConEffect=18, Image="set:SMWD_Icon image:SMWD_Icon_3"};
	
	g_DanYaoAttack[7] = { ctrl=TargetShenDing2_BK_4_Item1, Hover=TargetShenDing2_BK_4_Item1_Hover, Level=4, Count=1, ConEffect=22, Image="set:SMWD_Icon image:SMWD_Icon_4"};
	g_DanYaoAttack[8] = { ctrl=TargetShenDing2_BK_4_Item2, Hover=TargetShenDing2_BK_4_Item2_Hover, Level=4, Count=2, ConEffect=22, Image="set:SMWD_Icon image:SMWD_Icon_4"};
	g_DanYaoAttack[9] = { ctrl=TargetShenDing2_BK_4_Item3, Hover=TargetShenDing2_BK_4_Item3_Hover, Level=4, Count=3, ConEffect=22, Image="set:SMWD_Icon image:SMWD_Icon_4"};
	g_DanYaoAttack[10] = { ctrl=TargetShenDing2_BK_4_Item4, Hover=TargetShenDing2_BK_4_Item4_Hover, Level=4, Count=4, ConEffect=22, Image="set:SMWD_Icon image:SMWD_Icon_4"};
	
	g_DanYaoAttack[11] = { ctrl=TargetShenDing2_BK_5_Item1, Hover=TargetShenDing2_BK_5_Item1_Hover, Level=5, Count=1, ConEffect=26, Image="set:SMWD_Icon image:SMWD_Icon_5"};
	g_DanYaoAttack[12] = { ctrl=TargetShenDing2_BK_5_Item2, Hover=TargetShenDing2_BK_5_Item2_Hover, Level=5, Count=2, ConEffect=26, Image="set:SMWD_Icon image:SMWD_Icon_5"};
	g_DanYaoAttack[13] = { ctrl=TargetShenDing2_BK_5_Item3, Hover=TargetShenDing2_BK_5_Item3_Hover, Level=5, Count=3, ConEffect=26, Image="set:SMWD_Icon image:SMWD_Icon_5"};
	g_DanYaoAttack[14] = { ctrl=TargetShenDing2_BK_5_Item4, Hover=TargetShenDing2_BK_5_Item4_Hover, Level=5, Count=4, ConEffect=26, Image="set:SMWD_Icon image:SMWD_Icon_5"};
	g_DanYaoAttack[15] = { ctrl=TargetShenDing2_BK_5_Item5, Hover=TargetShenDing2_BK_5_Item5_Hover, Level=5, Count=5, ConEffect=26, Image="set:SMWD_Icon image:SMWD_Icon_5"};
	
	g_DanYaoAttack[16] = { ctrl=TargetShenDing2_BK_6_Item1, Hover=TargetShenDing2_BK_6_Item1_Hover, Level=6, Count=1, ConEffect=31, Image="set:SMWD_Icon image:SMWD_Icon_6"};
	g_DanYaoAttack[17] = { ctrl=TargetShenDing2_BK_6_Item2, Hover=TargetShenDing2_BK_6_Item2_Hover, Level=6, Count=2, ConEffect=31, Image="set:SMWD_Icon image:SMWD_Icon_6"};
	g_DanYaoAttack[18] = { ctrl=TargetShenDing2_BK_6_Item3, Hover=TargetShenDing2_BK_6_Item3_Hover, Level=6, Count=3, ConEffect=31, Image="set:SMWD_Icon image:SMWD_Icon_6"};
	g_DanYaoAttack[19] = { ctrl=TargetShenDing2_BK_6_Item4, Hover=TargetShenDing2_BK_6_Item4_Hover, Level=6, Count=4, ConEffect=31, Image="set:SMWD_Icon image:SMWD_Icon_6"};
	g_DanYaoAttack[20] = { ctrl=TargetShenDing2_BK_6_Item5, Hover=TargetShenDing2_BK_6_Item5_Hover, Level=6, Count=5, ConEffect=31, Image="set:SMWD_Icon image:SMWD_Icon_6"};
	g_DanYaoAttack[21] = { ctrl=TargetShenDing2_BK_6_Item6, Hover=TargetShenDing2_BK_6_Item6_Hover, Level=6, Count=6, ConEffect=31, Image="set:SMWD_Icon image:SMWD_Icon_6"};
	
	g_DanYaoAttack[22] = { ctrl=TargetShenDing2_BK_7_Item1, Hover=TargetShenDing2_BK_7_Item1_Hover, Level=7, Count=1, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};
	g_DanYaoAttack[23] = { ctrl=TargetShenDing2_BK_7_Item2, Hover=TargetShenDing2_BK_7_Item2_Hover, Level=7, Count=2, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};
	g_DanYaoAttack[24] = { ctrl=TargetShenDing2_BK_7_Item3, Hover=TargetShenDing2_BK_7_Item3_Hover, Level=7, Count=3, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};
	g_DanYaoAttack[25] = { ctrl=TargetShenDing2_BK_7_Item4, Hover=TargetShenDing2_BK_7_Item4_Hover, Level=7, Count=4, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};
	g_DanYaoAttack[26] = { ctrl=TargetShenDing2_BK_7_Item5, Hover=TargetShenDing2_BK_7_Item5_Hover, Level=7, Count=5, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};
	g_DanYaoAttack[27] = { ctrl=TargetShenDing2_BK_7_Item6, Hover=TargetShenDing2_BK_7_Item6_Hover, Level=7, Count=6, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};
	g_DanYaoAttack[28] = { ctrl=TargetShenDing2_BK_7_Item7, Hover=TargetShenDing2_BK_7_Item7_Hover, Level=7, Count=7, ConEffect=36, Image="set:SMWD_Icon image:SMWD_Icon_7"};
	
	g_DanYaoAttack[29] = { ctrl=TargetShenDing2_BK_8_Item1, Hover=TargetShenDing2_BK_8_Item1_Hover, Level=8, Count=1, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[30] = { ctrl=TargetShenDing2_BK_8_Item2, Hover=TargetShenDing2_BK_8_Item2_Hover, Level=8, Count=2, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[31] = { ctrl=TargetShenDing2_BK_8_Item3, Hover=TargetShenDing2_BK_8_Item3_Hover, Level=8, Count=3, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[32] = { ctrl=TargetShenDing2_BK_8_Item4, Hover=TargetShenDing2_BK_8_Item4_Hover, Level=8, Count=4, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[33] = { ctrl=TargetShenDing2_BK_8_Item5, Hover=TargetShenDing2_BK_8_Item5_Hover, Level=8, Count=5, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[34] = { ctrl=TargetShenDing2_BK_8_Item6, Hover=TargetShenDing2_BK_8_Item6_Hover, Level=8, Count=6, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[35] = { ctrl=TargetShenDing2_BK_8_Item7, Hover=TargetShenDing2_BK_8_Item7_Hover, Level=8, Count=7, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	g_DanYaoAttack[36] = { ctrl=TargetShenDing2_BK_8_Item8, Hover=TargetShenDing2_BK_8_Item8_Hover, Level=8, Count=8, ConEffect=41, Image="set:SMWD_Icon image:SMWD_Icon_8"};
	
	g_DanYaoAttack[37] = { ctrl=TargetShenDing2_BK_9_Item1, Hover=TargetShenDing2_BK_9_Item1_Hover, Level=9, Count=1, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[38] = { ctrl=TargetShenDing2_BK_9_Item2, Hover=TargetShenDing2_BK_9_Item2_Hover, Level=9, Count=2, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[39] = { ctrl=TargetShenDing2_BK_9_Item3, Hover=TargetShenDing2_BK_9_Item3_Hover, Level=9, Count=3, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[40] = { ctrl=TargetShenDing2_BK_9_Item4, Hover=TargetShenDing2_BK_9_Item4_Hover, Level=9, Count=4, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[41] = { ctrl=TargetShenDing2_BK_9_Item5, Hover=TargetShenDing2_BK_9_Item5_Hover, Level=9, Count=5, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[42] = { ctrl=TargetShenDing2_BK_9_Item6, Hover=TargetShenDing2_BK_9_Item6_Hover, Level=9, Count=6, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[43] = { ctrl=TargetShenDing2_BK_9_Item7, Hover=TargetShenDing2_BK_9_Item7_Hover, Level=9, Count=7, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[44] = { ctrl=TargetShenDing2_BK_9_Item8, Hover=TargetShenDing2_BK_9_Item8_Hover, Level=9, Count=8, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	g_DanYaoAttack[45] = { ctrl=TargetShenDing2_BK_9_Item9, Hover=TargetShenDing2_BK_9_Item9_Hover, Level=9, Count=9, ConEffect=46, Image="set:SMWD_Icon image:SMWD_Icon_9"};
	
	g_TargetPageButton[1] = TargetShenDing_SelfEquip
	g_TargetPageButton[2] = TargetShenDing_SelfData
	g_TargetPageButton[3] = TargetShenDing_Pet
	g_TargetPageButton[4] = TargetShenDing_Infant
	g_TargetPageButton[5] = TargetShenDing_Wuhun
	g_TargetPageButton[6] = TargetShenDing_Miji
	g_TargetPageButton[7] = TargetShenDing_ZhenYuan
	g_TargetPageButton[8] = TargetShenDing_JingMai
	g_TargetPageButton[9] = TargetShenDing_ShenDing
	g_TargetPageButton[10] = TargetShenDing_JueWei
	g_TargetPageButton[11] = TargetShenDing_BaoJian
	g_TargetPageButton[12] = TargetShenDing_WuYi
	g_TargetPageButton[13] = TargetShenDing_ShenQi
	g_TargetPageButton[14] = TargetShenDing_Armor
	g_TargetPageButton[15] = TargetShenDing_CangPin
	
end

-- OnEvent
function TargetShenDing_OnEvent(event)

	--显示界面
	if ( event == "OPEN_OTHERPLAYER_SHENDING" ) then		
		if(this:IsVisible()) then
			this:Hide();
			return;
		end
		
		local obj_id = CachedTarget:GetData("NPCID", 1)
		if (type(obj_id) ~="number") then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end
		this:CareObject(obj_id , 1, "TargetShenDing")
		
		--更新数据
		TargetShenDing_OnUpdateShow();
		TargetShenDing_SetTabColor(8);
		local OtherUnionPos = Variable:GetVariable("OtherUnionPos");
	    if(OtherUnionPos ~= nil) then
		    TargetShenDing_Frame:SetProperty("UnifiedPosition", OtherUnionPos);
    	end
		this:Show();
	end
	
	if( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		return;
	end
	
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		TargetShenDing_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TargetShenDing_ResetPos()
	end

	return;

end

function TargetShenDing_CalcChengDanLevelAndPosByCount( nDanYaoCount )
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

function TargetShenDing_UpdateDanYaoUI()

	local nLevel, nPos = TargetShenDing_CalcChengDanLevelAndPosByCount( g_nDanYaoCount );
	local nNextLevel, nNextPos = TargetShenDing_CalcChengDanLevelAndPosByCount( g_nDanYaoCount+1 );
	
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
			
end

--显示体力界面
function TargetShenDing_OnUpdateShow()
	--显示&隐藏
	TargetShenDing_Frame_Part:Show();
	TargetShenDing2_Frame_Part:Hide();
	TargetShenDing_FenYe1:SetCheck(1);
	TargetShenDing_FenYe2:SetCheck(0);
		
	--体力
	g_ZoneConValue=CachedTarget:GetData("LIANDANLUCONVALUE");
	g_RongHeConValue=CachedTarget:GetData("RongHeConValue");
	--融合
	g_CurRongHeCount=CachedTarget:GetData("JinDanRongHeCount");
	g_MaxRongHeCount=CachedTarget:GetData("MaxJinDanRongHeCount");
		
	local strText = ScriptGlobal_Format("#{XLDL_140606_18}",g_ZoneConValue,g_RongHeConValue);
	TargetShenDing_ZongTiLi:SetText(strText);
		
	local strTipText = ScriptGlobal_Format("#{XLDL_140606_54}",
			g_ZoneConValue-g_RongHeConValue, g_RongHeConValue );
	TargetShenDing_ZongTiLi:SetToolTip( strTipText );
	
	--药丹等级
	g_nDanYaoCount = tonumber(CachedTarget:GetData("LianDanCount"));
	TargetShenDing_UpdateDanYaoUI();
end

--显示属性攻页面
function TargetShenDing_OnUpdateShow_Attack()
	--显示&隐藏
	TargetShenDing_Frame_Part:Hide();
	TargetShenDing2_Frame_Part:Show();
	TargetShenDing_FenYe1:SetCheck(0);
	TargetShenDing_FenYe2:SetCheck(1);
		
	--药丹等级
	local nAttackDanYaoCount = CachedTarget:GetData("Attack_DanYaoCount");
	TargetShenDing_UpdateDanYaoCtrl( nAttackDanYaoCount, g_DanYaoAttack );
	
	--各属性值
	local nIce, nFire, nThunder, nPoison = CachedTarget:GetData("Attack_IFTPValue");
	TargetShenDing2_ShuXingGong_Bing_Text2:SetText( "#H"..tostring(nIce));
	TargetShenDing2_ShuXingGong_Huo_Text2:SetText( "#H"..tostring(nFire));
	TargetShenDing2_ShuXingGong_Xuan_Text2:SetText( "#H"..tostring(nThunder));
	TargetShenDing2_ShuXingGong_Du_Text2:SetText( "#H"..tostring(nPoison));
	
end

--显示丹药控件
function TargetShenDing_UpdateDanYaoCtrl( DanYaoCount, DanYaoCtrl )

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
		strToolTip = ScriptGlobal_Format("#{XLDL_140606_124}", DanYaoCtrl[DanYaoCount+1].ConEffect)
		DanYaoCtrl[DanYaoCount+1].Hover:SetToolTip(strToolTip);
	end
	
end

function TargetShenDing_ResetPos()
	TargetShenDing_Frame:SetProperty("UnifiedPosition",g_TargetShenDing_Frame_UnifiedPosition)
end

function TargetShenDing_OnMoved()
end

function TargetShenDing_CloseFunction()
	this:Hide();
end

--查看帮助
function TargetShenDing_BangZhu()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnLianDanLuHelp");
		Set_XSCRIPT_ScriptID(339008);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end

--分页
function TargetShenDing_ChangeTabIndex( page )
	if page == 0 then
		TargetShenDing_OnUpdateShow();
	elseif page == 1 then
		TargetShenDing_OnUpdateShow_Attack();
	end
end

--装备
function TargetShenDing_SelfEquip_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenEquipFrame("other");
	TargetShenDing_CloseFunction()
end

--资料
function TargetShenDing_SelfData_Switch()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("other")
	TargetShenDing_CloseFunction()
end

--珍兽
function TargetShenDing_Pet_Switch()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPetFrame("other");
	TargetShenDing_CloseFunction()
end

--子女
function TargetShenDing_Infant_Switch()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:Other_ToggleInfantPage();
	if bRet == 1 then
		TargetShenDing_CloseFunction()
	else
		TargetShenDing_SetTabColor(8)
	end
end

--武魂
function TargetShenDing_Wuhun_Switch()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherWuhun();
	TargetShenDing_CloseFunction()
end

--秘籍
function TargetShenDing_Miji_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherMiji();
	TargetShenDing_CloseFunction()
end

--真元
function TargetShenDing_ZhenYuan_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleTargetZhenYuanPage();
	if bRet == 1 then
		TargetShenDing_CloseFunction()
	else
		TargetShenDing_SetTabColor(8)
	end
end

--经脉
function TargetShenDing_JingMai_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherJingMai();
	TargetShenDing_CloseFunction()
end

--神鼎
function TargetShenDing_ShenDing_Page_Switch()
end

--骑乘
function TargetShenDing_Ride_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenRidePage("other");
	TargetShenDing_CloseFunction()
end

--===============================================
-- SetTabColor
--===============================================
function TargetShenDing_SetTabColor(idx)
	if(idx == nil or idx < 0 or idx > 9) then
		return;
	end


	local i = 0;
	local selColor = "#Y";
	local noselColor = "";
	local tab = {
								[0] = TargetShenDing_SelfEquip,
								TargetShenDing_SelfData,
								TargetShenDing_Pet,
								TargetShenDing_Infant,
								TargetShenDing_Wuhun,
								TargetShenDing_Miji,
								TargetShenDing_ZhenYuan,
								TargetShenDing_JingMai,
								TargetShenDing_ShenDing,
								TargetShenDing_JueWei,
								TargetShenDing_Ride,
							};

	while i < 11 do
		if(i == idx) then
			tab[i]:SetCheck(1);
		else
			tab[i]:SetCheck(0);
		end
		i = i + 1;
	end
end

function TargetShenDing_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetShenDing_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end

function TargetShenDing_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

function TargetShenDing_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function TargetShenDing_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function TargetShenDing_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetShenDing_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end


function TargetShenDing_ShowPage()

	for i = 1, table.getn(g_TargetShenDing_Page) do
		g_TargetPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	TargetShenDing_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_TargetPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_TargetShenDing_Page) do
			if i ~= nOtherPageNumber then
				g_TargetPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_TargetPageOrder = {}
	g_TargetPageCount = 0
	for i = 1, table.getn(g_TargetShenDing_Page) do
		if TargetShenDing_CheckPage(i) == 1 then
			g_TargetPageCount = g_TargetPageCount + 1
			g_TargetPageButton[g_TargetPageCount]:Show()
			g_TargetPageButton[g_TargetPageCount]:SetText(g_TargetShenDing_Page[i].Text)	
			g_TargetPageOrder[g_TargetPageCount] = i
		end
	end
	
end

function TargetShenDing_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_TargetPageOrder[idx]
	
	if idx == 1 then--装备
		TargetShenDing_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		TargetShenDing_SelfData_Switch()
	elseif idx == 3 then--珍兽
		TargetShenDing_Pet_Switch()
	elseif idx == 4 then--子女
		TargetShenDing_Infant_Switch()
	elseif idx == 5 then--武魂
		TargetShenDing_Wuhun_Switch()
	elseif idx == 6 then--秘籍
		TargetShenDing_Miji_Page_Switch()
	elseif idx == 7 then--真元
		TargetShenDing_ZhenYuan_Page_Switch()
	elseif idx == 8 then--经脉
		TargetShenDing_JingMai_Page_Switch()
	elseif idx == 9 then--神鼎
		TargetShenDing_ShenDing_Page_Switch()
	elseif idx == 10 then--侠印
		TargetShenDing_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		TargetShenDing_OpenBaoJian()
	elseif idx == 12 then--武意
		TargetShenDing_OpenWuYi()
	elseif idx == 13 then--神器
		TargetShenDing_OpenShenQi()
	elseif idx == 14 then--星盘
		TargetShenDing_Armor_Page_Switch()
	elseif idx == 15 then--名物
		TargetShenDing_CangPin_Page_Switch()
	end
end

function TargetShenDing_CheckPage(idx)
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

function TargetShenDing_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end

