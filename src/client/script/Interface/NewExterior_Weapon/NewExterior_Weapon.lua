--!!!reloadscript =NewExterior_Weapon
local g_NewExterior_Weapon_UnifiedPosition = ""

local EXTERIORFILTTING_TOTALKIND = 6;
local g_TargetExteriorIndex = 0		--定位的外观索引，从1开始
local g_TargetExteriorID = 0			--定位的外观ID

local g_CurSelExteriorID = 0			--当前选择的外观ID，从1开始
local g_CurSelWeaponLevel = 1
local g_Weapon_FangAn_Max = 5

local g_NeedChangeScrollSize = 1

local g_Distance = 1
local g_Distance_Ori = 2
local g_Distance_Max = 4
local g_InitList = 0
local g_ExteriorType = 1 --幻武
local g_MaxBarNum = 0
local g_BarList = {}
local g_ViewMode = 0

local g_WeaponLevelAction = {}
local g_WeaponLevelLock = {}
local g_WeaponLevelTip = {}
local g_WeaponLevelDef = {}
local g_WeaponLevelTime = {}


local g_CameraPosition =
{
	--女性相关位置
	[0] = {{fHeight = 0.85, fDistance = 12, fPitch=0.1, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.2, fPitch=0.1, fXOffset= 0 },
	       {fHeight = 1.55, fDistance = 2.5, fPitch=0.10, fXOffset= 0 }, {fHeight = 1.55, fDistance = 1.7, fPitch=0.10, fXOffset= 0 }},
	--男性相关位置
	[1] = {{fHeight = 0.85, fDistance = 12, fPitch=0.28, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.5, fPitch=0.28, fXOffset= 0 }, 
	       {fHeight = 1.65, fDistance = 2.7, fPitch=0.28, fXOffset= 0 }, {fHeight = 1.70, fDistance = 1.9, fPitch=0.28, fXOffset= 0 }},
}

local g_CameraPosition_IV =
{
	--女性相关位置
	[0] = {{fHeight = 0.85, fDistance = 12, fPitch=0.2, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.2, fPitch=0.2, fXOffset= 0 },
	       {fHeight = 1.55, fDistance = 2.5, fPitch=0.10, fXOffset= 0 }, {fHeight = 1.62, fDistance = 1.8, fPitch=0.10, fXOffset= 0 }},
	--男性相关位置
	[1] = {{fHeight = 0.85, fDistance = 12, fPitch=0.28, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.5, fPitch=0.28, fXOffset= 0 }, 
	       {fHeight = 1.70, fDistance = 2.7, fPitch=0.05, fXOffset= 0 }, {fHeight = 1.78, fDistance = 1.9, fPitch=0.05, fXOffset= 0 }},
}

local g_SpecialWeaponCamera = {
-- 鸣雷
[1] = {	[0] = {startid = 414, endid = 418, fHeight = 1.25, fDistance = 17, fPitch = -1, timecount = 6000},
		[1] = {startid = 414, endid = 418, fHeight = 1.25, fDistance = 19, fPitch = -1, timecount = 6000},
		},
[2] = {	[0] = {startid = 419, endid = 423, fHeight = 1.25, fDistance = 15, fPitch = -1, timecount = 7400},
		[1] = {startid = 419, endid = 423, fHeight = 1.25, fDistance = 19, fPitch = -1, timecount = 7400},
		},		
[3] = {	[0] = {startid = 424, endid = 428, fHeight = 1.25, fDistance = 15, fPitch = -1, timecount = 7400},
		[1] = {startid = 424, endid = 428, fHeight = 1.25, fDistance = 19, fPitch = -1, timecount = 7400},
		},
-- 墨染烟华		
[4] = {	[0] = {startid = 429, endid = 433, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 13800},
		[1] = {startid = 429, endid = 433, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 13800},
		},	
-- 赤影钩金		
[5] = {	[0] = {startid = 544, endid = 548, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 8160},
		[1] = {startid = 544, endid = 548, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 8160},
		},	
-- 曲宴清音		
[6] = {	[0] = {startid = 559, endid = 563, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 9280},
		[1] = {startid = 559, endid = 563, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 9280},
		},
-- 银翼星明		
[7] = {	[0] = {startid = 564, endid = 568, fHeight = 1.25, fDistance = 17, fPitch = -1, timecount = 8880},
		[1] = {startid = 564, endid = 568, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 8880},
		},
[8] = {	[0] = {startid = 574, endid = 578, fHeight = 1.25, fDistance = 17, fPitch = -1, timecount = 14400},
		[1] = {startid = 574, endid = 578, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 14400},
		},
[9] = {	[0] = {startid = 589, endid = 593, fHeight = 1.25, fDistance = 17, fPitch = -1, timecount = 8600},
		[1] = {startid = 589, endid = 593, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 8600},
		},
[10] = {[0] = {startid = 594, endid = 598, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 8080},
		[1] = {startid = 594, endid = 598, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 8080},
		},
--凤鸣昆山
[11] = {[0] = {startid = 614, endid = 618, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 8400},
		[1] = {startid = 614, endid = 618, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 8400},
		},
--凤栖梧桐
[12] = {[0] = {startid = 609, endid = 613, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 8000},
		[1] = {startid = 609, endid = 613, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 8000},
		},
--卯君拜月
[13] = {[0] = {startid = 619, endid = 623, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 7400},
		[1] = {startid = 619, endid = 623, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 7400},
		},
[14] = {[0] = {startid = 629, endid = 633, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 7600},
		[1] = {startid = 629, endid = 633, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 7600},
		},
[15] = {[0] = {startid = 639, endid = 643, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 7200},
		[1] = {startid = 639, endid = 643, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 7200},
		},
[16] = {[0] = {startid = 644, endid = 648, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 6000},
		[1] = {startid = 644, endid = 648, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 6000},
		},
--情人节伞		
[17] = {[0] = {startid = 659, endid = 663, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 12400},
		[1] = {startid = 659, endid = 663, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 12400},
		},
--情人节镰刀
[18] = {[0] = {startid = 664, endid = 668, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 9520},
		[1] = {startid = 664, endid = 668, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 9520},
		},
[19] = {[0] = {startid = 669, endid = 673, fHeight = 1.25, fDistance = 10, fPitch = -1, timecount = 9000},
		[1] = {startid = 669, endid = 673, fHeight = 1.25, fDistance = 11, fPitch = -1, timecount = 9000},
		},
[20] = {[0] = {startid = 679, endid = 683, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 7200},
		[1] = {startid = 679, endid = 683, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 7200},
		},		
[21] = {[0] = {startid = 684, endid = 688, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 7200},
		[1] = {startid = 684, endid = 688, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 7200},
		},		
-- 金箍棒		
[22] = {[0] = {startid = 704, endid = 708, fHeight = 1.25, fDistance = 23, fPitch = -1, timecount = 17280},
		[1] = {startid = 704, endid = 708, fHeight = 1.25, fDistance = 23, fPitch = -1, timecount = 17280},
		},
-- 紫青宝剑	
[23] = {[0] = {startid = 699, endid = 703, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 10000},
		[1] = {startid = 699, endid = 703, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 10000},
		},	
-- 芭蕉灵扇	
[24] = {[0] = {startid = 709, endid = 713, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 7400},
		[1] = {startid = 709, endid = 713, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 7400},
		},	
-- 白骨鞭
[25] = {	
		[0] = {startid = 719, endid = 723, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 6800},
		[1] = {startid = 719, endid = 723, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 6800},
		},
-- 混天玄戟
[26] = {	
		[0] = {startid = 714, endid = 718, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 6800},
		[1] = {startid = 714, endid = 718, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 6800},
		},
[27] = {	
		[0] = {startid = 735, endid = 739, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 7200},
		[1] = {startid = 735, endid = 739, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 7200},
		},
[28] = {[0] = {startid = 740, endid = 744, fHeight = 1.25, fDistance = 17, fPitch = -1, timecount = 8600},
		[1] = {startid = 740, endid = 744, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 8600},
		},
[29] = {[0] = {startid = 751, endid = 755, fHeight = 1.25, fDistance = 17, fPitch = -1, timecount = 8280},
		[1] = {startid = 751, endid = 755, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 8280},
		},
-- 狼烟乱
[30] = {	
			[0] = {startid = 761, endid = 765, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 6000},
			[1] = {startid = 761, endid = 765, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 6000},
		},
-- 断离愁
[31] = {	
			[0] = {startid = 766, endid = 770, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 7160},
			[1] = {startid = 766, endid = 770, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 7160},
		},
-- 三千月相
[32] = {	
			[0] = {startid = 756, endid = 760, fHeight = 1.25, fDistance = 10, fPitch = -1, timecount = 9280},
			[1] = {startid = 756, endid = 760, fHeight = 1.25, fDistance = 12, fPitch = -1, timecount = 9280},
		},	
-- 执月流芳
[33] = {	
			[0] = {startid = 771, endid = 775, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 7960},
			[1] = {startid = 771, endid = 775, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 7960},
		},	
-- 幽篁照影
[34] = {	
			[0] = {startid = 776, endid = 780, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 8080},
			[1] = {startid = 776, endid = 780, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 8080},
		},	
-- 银翎识香
[35] = {	
			[0] = {startid = 781, endid = 785, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 6400},
			[1] = {startid = 781, endid = 785, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 6400},
		},	

[36] = {
			[0] = {startid = 786, endid = 790, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 8880},
			[1] = {startid = 786, endid = 790, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 8880},
		},
[37] = {
			[0] = {startid = 796, endid = 800, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 8800},
			[1] = {startid = 796, endid = 800, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 8800},
		},
[38] = {
			[0] = {startid = 801, endid = 805, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 9040},
			[1] = {startid = 801, endid = 805, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 9040},
		},
-- 剑意浓	
[39] = {
			[0] = {startid = 816, endid = 820, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 10400},
			[1] = {startid = 816, endid = 820, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 10400},
		},
-- 引墨	
[40] = {
			[0] = {startid = 821, endid = 825, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 8800},
			[1] = {startid = 821, endid = 825, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 8800},
		},
-- 怜骨生花	
[41] = {
			[0] = {startid = 811, endid = 815, fHeight = 1.25, fDistance = 23, fPitch = -1, timecount = 8800},
			[1] = {startid = 811, endid = 815, fHeight = 1.25, fDistance = 23, fPitch = -1, timecount = 8800},
		},
-- 湖心曲	
[42] = {
			[0] = {startid = 826, endid = 830, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 13800},
			[1] = {startid = 826, endid = 830, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 13800},
		},
-- 星杖	
[43] = {
			[0] = {startid = 836, endid = 840, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 11200},
			[1] = {startid = 836, endid = 840, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 11200},
		},
-- 璇玑碎	
[44] = {
			[0] = {startid = 831, endid = 835, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 6000},
			[1] = {startid = 831, endid = 835, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 6000},
		},
-- 拂华见月	
[45] = {
			[0] = {startid = 841, endid = 845, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 8800},
			[1] = {startid = 841, endid = 845, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 8800},
		},
-- 赤羽焚心	
[46] = {
			[0] = {startid = 851, endid = 855, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 6400},
			[1] = {startid = 851, endid = 855, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 6400},
		},
--雪羽飞
[47] = {
			[0] = {startid = 856, endid = 860, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 12000},
			[1] = {startid = 856, endid = 860, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 12000},
		},

--夏日拉收战令系统
[48] = {
			[0] = {startid = 866, endid = 870, fHeight = 1.25, fDistance = 17, fPitch = -1, timecount = 8600},
			[1] = {startid = 866, endid = 870, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 8600},
		},

--夏日拉收战令系统
[49] = {
			[0] = {startid = 861, endid = 865, fHeight = 1.25, fDistance = 17, fPitch = -1, timecount = 8600},
			[1] = {startid = 861, endid = 865, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 8600},
		},
--情人节 北境霜锋 镰
[50] = {
			[0] = {startid = 876, endid = 880, fHeight = 1.25, fDistance = 16, fPitch = -1, timecount = 9920},
			[1] = {startid = 876, endid = 880, fHeight = 1.25, fDistance = 18, fPitch = -1, timecount = 9920},
		},
--情人节 晶璨玫瑰 
[51] = {
			[0] = {startid = 886, endid = 890, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 13600},
			[1] = {startid = 886, endid = 890, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 13600},
		},
--情人节 寒晶飞羽 环
[52] = {
			[0] = {startid = 881, endid = 885, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 7600},
			[1] = {startid = 881, endid = 885, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 7600},
		},	
-- 情人节 银辉圣剑
[53] = {
			[0] = {startid = 891, endid = 895, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 11880},
			[1] = {startid = 891, endid = 895, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 11880},
		},
-- 元宵商店 拨浪鼓
[54] = {
			[0] = {startid = 896, endid = 900, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 5000},
			[1] = {startid = 896, endid = 900, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 5000},
		},
-- 银翎识香
[55] = {
			[0] = {startid = 901, endid = 905, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 8080},
			[1] = {startid = 901, endid = 905, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 8080},
		},
-- 撼岳
[56] = {
			[0] = {startid = 906, endid = 910, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 7840},
			[1] = {startid = 906, endid = 910, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 7840},
		},

-- 雪饮狂刀
[57] = {
			[0] = {startid = 921, endid = 925, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 6360},
			[1] = {startid = 921, endid = 925, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 6360},
		},

-- 2026周年庆
[58] = {
			[0] = {startid = 916, endid = 920, fHeight = 1.25, fDistance = 25, fPitch = -1, timecount = 10560},
			[1] = {startid = 916, endid = 920, fHeight = 1.25, fDistance = 25, fPitch = -1, timecount = 10560},
		},		
-- 火麟剑
[59] = {
			[0] = {startid = 911, endid = 915, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 8200},
			[1] = {startid = 911, endid = 915, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 8200},
		},
--choujiang
[60] = {
			[0] = {startid = 931, endid = 935, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 8600},
			[1] = {startid = 931, endid = 935, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 8600},
		},
-- 盘龙霸王戟
[61] = {
			[0] = {startid = 951, endid = 955, fHeight = 1.25, fDistance = 27, fPitch = -1, timecount = 13280},
			[1] = {startid = 951, endid = 955, fHeight = 1.25, fDistance = 28, fPitch = -1, timecount = 13280},
		},
-- 栖凰红颜剑
[62] = {
			[0] = {startid = 946, endid = 950, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 10000},
			[1] = {startid = 946, endid = 950, fHeight = 1.25, fDistance = 23, fPitch = -1, timecount = 10000},
		},
-- 君临天地
[63] = {
			[0] = {startid = 941, endid = 945, fHeight = 1.25, fDistance = 22, fPitch = -1, timecount = 7600},
			[1] = {startid = 941, endid = 945, fHeight = 1.25, fDistance = 23, fPitch = -1, timecount = 7600},
		},
-- 征人归
[64] = {
			[0] = {startid = 956, endid = 960, fHeight = 1.25, fDistance = 28, fPitch = -1, timecount = 9080},
			[1] = {startid = 956, endid = 960, fHeight = 1.25, fDistance = 28, fPitch = -1, timecount = 9080},
		},
}
local g_sexButtonInfo = {
    [0] = { imgH = "set:DressPreview01 image:DressPreview_Male_Hover", imgN = "set:DressPreview01 image:DressPreview_Male_Normal", imgP = "set:DressPreview01 image:DressPreview_Male_Pushed"  },
    [1] = { imgH = "set:DressPreview01 image:DressPreview_Female_Hover", imgN = "set:DressPreview01 image:DressPreview_Female_Normal", imgP = "set:DressPreview01 image:DressPreview_Female_Pushed"  },
}
local g_PlayerRace = {
    SEX_INVALID	= -1,
    SEX_FEMALE = 0,
    SEX_MALE = 1,
    SEX_NUMBERS = 2,
}
--=========
--PreLoad==
--=========
function NewExterior_Weapon_PreLoad()
	this:RegisterEvent("OPEN_EXTERIOR")
	this:RegisterEvent("ADD_EXTERIOR", false)
	this:RegisterEvent("REMOVE_EXTERIOR", false)
	this:RegisterEvent("UPDATE_EXTERIOR", false)
	this:RegisterEvent("EXTERIOR_OUTTIME", false)	
	this:RegisterEvent("EXTERIOR_ID_CHANGED", false)
	this:RegisterEvent("EXTERIOR_FUTI_VISUAL_INDEX", false)
	this:RegisterEvent("EXTERIOR_HAIR_COLOR_INDEX", false)

	this:RegisterEvent("UNIT_LEVEL",false)	
	
	this:RegisterEvent("ON_SCENE_TRANS",false)
	this:RegisterEvent("ON_SERVER_TRANS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("ADJEST_UI_POS",false)	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("UPDATE_EXTERIOR_FASHION", false)
	
	this:RegisterEvent("EXERIOR_SAVEALL_RET", false)
	
	this:RegisterEvent("OPEN_STALL_SALE",false)
	this:RegisterEvent("PROGRESSBAR_SHOW",false)
	this:RegisterEvent("MODELID_CHANGE",false)
	this:RegisterEvent("ORNAMENTS_DISPLAYUPDATE",false)
	this:RegisterEvent("UI_COMMAND")
end

--=========
--OnLoad
--=========
function NewExterior_Weapon_OnLoad()
	g_NewExterior_Weapon_UnifiedPosition = NewExterior_Weapon_Frame:GetProperty("UnifiedPosition")
	
	g_WeaponLevelAction[1] = NewExterior_Weapon_Level1_RightBtn
	g_WeaponLevelAction[2] = NewExterior_Weapon_Level2_RightBtn
	g_WeaponLevelAction[3] = NewExterior_Weapon_Level3_RightBtn
	g_WeaponLevelAction[4] = NewExterior_Weapon_Level4_RightBtn
	g_WeaponLevelAction[5] = NewExterior_Weapon_Level5_RightBtn
	
	g_WeaponLevelLock[1] = NewExterior_Weapon_Level1_ActionImg
	g_WeaponLevelLock[2] = NewExterior_Weapon_Level2_ActionImg
	g_WeaponLevelLock[3] = NewExterior_Weapon_Level3_ActionImg
	g_WeaponLevelLock[4] = NewExterior_Weapon_Level4_ActionImg
	g_WeaponLevelLock[5] = NewExterior_Weapon_Level5_ActionImg
	
	g_WeaponLevelTip[1] = NewExterior_Weapon_Level1_Tip
	g_WeaponLevelTip[2] = NewExterior_Weapon_Level2_Tip
	g_WeaponLevelTip[3] = NewExterior_Weapon_Level3_Tip
	g_WeaponLevelTip[4] = NewExterior_Weapon_Level4_Tip
	g_WeaponLevelTip[5] = NewExterior_Weapon_Level5_Tip
	
	g_WeaponLevelDef[1] = NewExterior_Weapon_Level1_Def
	g_WeaponLevelDef[2] = NewExterior_Weapon_Level2_Def
	g_WeaponLevelDef[3] = NewExterior_Weapon_Level3_Def
	g_WeaponLevelDef[4] = NewExterior_Weapon_Level4_Def
	g_WeaponLevelDef[5] = NewExterior_Weapon_Level5_Def
	
	g_WeaponLevelTime[1] = NewExterior_Weapon_Level1_Time
	g_WeaponLevelTime[2] = NewExterior_Weapon_Level2_Time
	g_WeaponLevelTime[3] = NewExterior_Weapon_Level3_Time
	g_WeaponLevelTime[4] = NewExterior_Weapon_Level4_Time
	g_WeaponLevelTime[5] = NewExterior_Weapon_Level5_Time
	
	
end
--=========
--OnEvent
--=========
function NewExterior_Weapon_OnEvent(event)

	if event == "OPEN_EXTERIOR" then
		if tonumber(arg0) == g_ExteriorType then
			if this:IsVisible() then
				if tonumber(arg1) == 0 then
					NewExterior_Weapon_SavePosition()
					this:Hide()
				end
			else
				NewExterior_Weapon_SetPosition()
				NewExterior_Weapon_CloseSameGroupWindow()
				this:Show()
				NewExterior_Weapon_Show()
			end
		end
		return
	end
	
	if ( event == "OPEN_STALL_SALE" ) -- 开始摆摊，还原试穿
		or ( event == "PROGRESSBAR_SHOW" )		-- 读进度条中，还原试穿
		or ( event == "MODELID_CHANGE" ) -- 变身 关闭界面
		then
		NewExterior_Weapon_CloseClick()
		return
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 80081701 ) then
		if (this:IsVisible()) then
			NewExterior_Weapon_CloseClick()
			return
		end
	end
	
	if event == "EXERIOR_SAVEALL_RET" then
		Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
		Exterior:LuaFnInitCurrentExteriorSet()
		NewExterior_Weapon_Show()
	end
	
	if event == "ADD_EXTERIOR" or event == "REMOVE_EXTERIOR" or event == "UPDATE_EXTERIOR" or event == "EXTERIOR_OUTTIME" or event == "EXTERIOR_ID_CHANGED" then
		if tonumber(arg0) == g_ExteriorType then
			NewExterior_Weapon_Show()
		else
			--左侧
			NewExterior_Weapon_UpdateLeftBtn()
			NewExterior_Weapon_UpdateRedPoint()
			--更新一下模型
			Exterior:LuaFnUpdateExteriorPlayerData()
		end
		return
	end
	
	if event == "EXTERIOR_FUTI_VISUAL_INDEX" or event == "EXTERIOR_HAIR_COLOR_INDEX" then
		--左侧
		NewExterior_Weapon_UpdateLeftBtn()
		NewExterior_Weapon_UpdateRedPoint()
		--更新一下模型
		Exterior:LuaFnUpdateExteriorPlayerData()
		return
	end
	
	if event == "UPDATE_EXTERIOR_FASHION" then
		if tonumber(arg0) == 1 then
			--左侧
			NewExterior_Weapon_UpdateLeftBtn()
			--更新一下模型
			Exterior:LuaFnUpdateExteriorPlayerData()
		end
		return
	end
	
	if event == "ORNAMENTS_DISPLAYUPDATE" then
		-- 刷新模型
		Exterior:LuaFnUpdateExteriorPlayerData()
		return
	end

	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		NewExterior_Weapon_Frame:SetProperty("UnifiedPosition", g_NewExterior_Weapon_UnifiedPosition)
	end
	
	if event == "UPDATE_REDPOINT_IN_UI" and this:IsVisible() then
		--NewExterior_Weapon_UpdateRedPoint()
	end

end

function NewExterior_Weapon_InitList()
	
	if g_InitList == 0 then		
		g_MaxBarNum = Exterior:LuaFnGetExteriorWeaponGroupCount()
		
		for i = 1, g_MaxBarNum do
			local bar = NewExterior_Weapon_SuperList:AddChild("NewExterior_Weapon_SuperListItem")
			g_BarList[i] = bar	
			bar:GetSubItem("NewExterior_Weapon_SuperListItemAction"):SetEvent("MouseLButtonDown", string.format("NewExterior_Weapon_ItemClicked(%d)", i))
			bar:GetSubItem("NewExterior_Weapon_SuperListItemAction"):SetEvent("MouseMove", string.format("NewExterior_Weapon_ItemMouseMove(%d)", i))
			bar:GetSubItem("NewExterior_Weapon_SuperListItemAction"):SetProperty("Empty", "False")
			bar:GetSubItem("NewExterior_Weapon_SuperListItemAction"):SetProperty("UseDefaultTooltip", "True")
		end
		g_InitList = 1
	end
end

function NewExterior_Weapon_Show()
	
	g_Distance = g_Distance_Ori
	g_NeedChangeScrollSize = 1
				
	EXTERIORFILTTING_TOTALKIND = Exterior:LuaFnGetExteriorPlayerFittingCount()
	
	NewExterior_Weapon_InitList()
	
	NewExterior_Weapon_CleanUp()
	
	NewExterior_Weapon_FakeObject:AttachWindowEx("Exterior_Player")
	Exterior:LuaFnUpdateExteriorPlayerData()
	
	g_TargetExteriorID = 0
	g_CurSelExteriorID = 0
	g_CurSelWeaponLevel = 0

	local group = 0 
	local level = 0
	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		group, level = Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Group")
		if group ~= nil and level ~= nil then
			g_TargetExteriorID = group
			g_CurSelExteriorID = group
			g_CurSelWeaponLevel = level + 1
		end			
	end	
	
	--列表
	NewExterior_Weapon_UpdateList()	
	--搭配方案
	NewExterior_Weapon_UpdateFangAn()
	--等级部分
	NewExterior_Weapon_ShowLevelBtn()
	--左侧
	NewExterior_Weapon_UpdateLeftBtn()
	--模型
	NewExterior_Weapon_UpdateObj()	

	if g_CurSelExteriorID ~= 0 then
		local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorID, g_CurSelWeaponLevel - 1)
		NewExterior_Weapon_RemoveTip(nExteriorWeaponID)
	end
	
	NewExterior_Weapon_UpdateRedPoint()
	
	NewExterior_Weapon_ShowFashionWeaponCheckButton()
	NewExterior_Weapon_GenderUpdate()
	
end

--左侧
function NewExterior_Weapon_UpdateLeftBtnForStyle()
	
	local sex = Exterior:LuaFnGetExteriorRaceID()
	
	-- 时装
	local cacheExteriorID, cacheExteriorIdx, gem1, gem2, gem3 = Exterior:LuaFnGetCurExteriorShareInfo("FASHION")
		
	-- 坐骑
	local edType = 0	
	cacheExteriorID = Exterior:LuaFnGetCurExteriorShareInfo("RIDE")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("RIDE")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Name")
		local strIcon = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Weapon_Ride_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_Ride_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Weapon_Ride_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_Ride_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Weapon_Ride_LockImg:Show()
		end
	end
	
	-- 幻武
	edType = 1
	cacheExteriorID = Exterior:LuaFnGetCurExteriorShareInfo("WEAPON")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Name")
		local strIcon 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Weapon_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Weapon_Weapon_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_Weapon_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Weapon_Weapon_LockImg:Show()
		end
	end
	
	-- 附体
	edType = 2
	local cacheVisualIndex = 0
	cacheExteriorID, cacheVisualIndex, _ = Exterior:LuaFnGetCurExteriorShareInfo("FUTI")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID, cacheVisualIndex, _ = Exterior:LuaFnGetCurrentExteriorSetInfo("FUTI")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "Name")
		local strImage 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "VisualIcon", cacheVisualIndex)
		NewExterior_Weapon_PetPossJian_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_PetPossJian_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Weapon_PetPossJian_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_PetPossJian_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorFutiVisualIndex() ~= cacheVisualIndex then
				NewExterior_Weapon_PetPossJian_ActionImg:Show()
			end
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 
			or Exterior:LuaFnIsExteriorFutiVisualUnlocked(cacheExteriorID, cacheVisualIndex) ~= 1 
		then
			NewExterior_Weapon_PetPossJian_LockImg:Show()
		end
	end
	
	-- 脸型
	edType = 3
	cacheExteriorID = Exterior:LuaFnGetCurExteriorShareInfo("FACE")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FACE")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Weapon_FaceStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_FaceStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_82}", strName)
		NewExterior_Weapon_FaceStyle_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_FaceStyle_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Weapon_FaceStyle_LockImg:Show()
		end
	end
	
	-- 发型
	edType = 4
	local cacheColorValue = 0
	local cacheColorIndex = 0
	cacheExteriorID, cacheColorValue = Exterior:LuaFnGetCurExteriorShareInfo("HAIR")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID, cacheColorIndex = Exterior:LuaFnGetCurrentExteriorSetInfo("HAIR")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Weapon_HairStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_HairStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_81}", strName)
		NewExterior_Weapon_HairStyle_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_HairStyle_ActionImg:Show()
		else
			if cacheColorValue ~= 0 and Exterior:LuaFnIsHaveHairColorValue(cacheColorValue) ~= 1 then
				NewExterior_Weapon_HairStyle_ActionImg:Show()
			end
			
			if cacheColorIndex ~= 0 and Exterior:LuaFnGetExteriorHairColorIndex() ~= cacheColorIndex then
				NewExterior_Weapon_HairStyle_ActionImg:Show()
			end
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Weapon_HairStyle_LockImg:Show()
		end
	end
	
	-- 头像
	edType = 5
	local strHeadTip = ""
	cacheExteriorID = Exterior:LuaFnGetCurExteriorShareInfo("PORTRAIT")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("PORTRAIT")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorPortraitInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorPortraitInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Weapon_PlayerFrame_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_PlayerFrame_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_79}", strName)
		strHeadTip = strTemp
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_PlayerFrame_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Weapon_PlayerFrame_LockImg:Show()
		end		
	end
	
	-- 头像框
	edType = 6
	cacheExteriorID = Exterior:LuaFnGetCurExteriorShareInfo("FRAME")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FRAME")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Name")
		local iFrameType = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Type")
		if iFrameType == 1 then
			NewExterior_Weapon_PlayerFrame_Mask:Hide()
			NewExterior_Weapon_PlayerFrame_Mask_Animate:Show()
			
			local strFrameAnimate = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameAnimate")
			NewExterior_Weapon_PlayerFrame_Mask_Animate:SetProperty("Animate", strFrameAnimate)
		else
			NewExterior_Weapon_PlayerFrame_Mask:Show()
			NewExterior_Weapon_PlayerFrame_Mask_Animate:Hide()
			
			local strIcon = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameIcon")
			local strImage = GetIconFullName(strIcon)
			NewExterior_Weapon_PlayerFrame_Mask:SetProperty("Image", strImage)
		end

		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_85}", strName)
		NewExterior_Weapon_PlayerFrame_LeftBtn:SetToolTip(strHeadTip.."#r"..strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_PlayerFrame_ActionImg:Show()
		end	
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Weapon_PlayerFrame_LockImg:Show()
		end		
	end
	
	-- 背饰
	local edOrnamentsType, cacheExteriorX, cacheExteriorY, cacheExteriorZ = 0, 0, 0, 0
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurExteriorShareInfo("OrnamentsBack")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsBack")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Weapon_Widget_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_Widget_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Weapon_Widget_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Weapon_Widget_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= g_OrnamentState.TIME and nState ~= g_OrnamentState.FOREVER ) then
			NewExterior_Weapon_Widget_LockImg:Show()
		end
	end

	-- 背饰
	edOrnamentsType= 1
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurExteriorShareInfo("OrnamentsHead")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsHead")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Weapon_Headdress_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_Headdress_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Weapon_Headdress_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Weapon_Headdress_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= g_OrnamentState.TIME and nState ~= g_OrnamentState.FOREVER ) then
			NewExterior_Weapon_Headdress_LockImg:Show()
		end
	end
end

--左侧
function NewExterior_Weapon_UpdateLeftBtn()
	
	NewExterior_Weapon_CleanUp_LeftButton()
		
	local g_CurSelShareStyleIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("STYLE")	
	if g_CurSelShareStyleIdx > 0 and g_CurSelShareStyleIdx <= g_Weapon_FangAn_Max then
		NewExterior_Weapon_UpdateLeftBtnForStyle()
		return
	end
	
	local sex = Exterior:LuaFnGetExteriorRaceID()
	--图鉴
	local cacheExteriorID,cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("DRESSSTYLE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local cacheID,dressExteriorID,specialExteriorID = DressStyleScript:GetDressStyleInfo(cacheExteriorID, "ID")
		if cacheID ~= nil then
			-- 获取图标
			local strIcon 	= DataPool:LuaFnGetItemIconByTableIndex(dressExteriorID)
			local strImage = GetIconFullName(strIcon)
			-- 设置action
			NewExterior_Weapon_Dress_LeftBtn:SetActionItem(-1)
			NewExterior_Weapon_Dress_LeftBtn:SetProperty("Empty", "False")
			NewExterior_Weapon_Dress_LeftBtn:SetProperty("NormalImage", strImage)
			NewExterior_Weapon_Dress_LeftBtn:SetProperty("HoverImage", strImage)
			NewExterior_Weapon_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "True")
			-- 文字tips
			local strToolTip = DressStyleScript:GetDressStyleToolTips(cacheExteriorID, cacheExteriorIdx)
			NewExterior_Weapon_Dress_LeftBtn:SetToolTip(strToolTip)
			-- 试穿
			NewExterior_Weapon_Dress_ActionImg:Show()
		end
	else
		--时装
		NewExterior_Weapon_Dress_LeftBtn:SetActionItem(-1)
		cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
		if cacheExteriorID ~= nil and cacheExteriorID > 0 then
			local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(1, cacheExteriorIdx)
			--local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, cacheExteriorID, 0)
			if theAction:GetID() ~= 0 then
				NewExterior_Weapon_Dress_LeftBtn:SetActionItem(theAction:GetID())
				NewExterior_Weapon_Dress_ActionImg:Show()
				
				local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
				if nCurFashionId ~= nil and nCurFashionId > 0 then
					if nCurFashionIdx == cacheExteriorIdx then
						NewExterior_Weapon_Dress_ActionImg:Hide()
					end
				end
			end
		else
			local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
			if nCurFashionId ~= nil and nCurFashionId > 0 then
				local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(1, nCurFashionIdx)
				--local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, nCurFashionId, 0)
				if theAction:GetID() ~= 0 then
					NewExterior_Weapon_Dress_LeftBtn:SetActionItem(theAction:GetID())
				end
			end			
		end
	end
	--坐骑
	local edType = 0	
	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("RIDE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Name")
		local strIcon = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Weapon_Ride_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_Ride_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Weapon_Ride_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_Ride_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Weapon_Ride_LockImg:Show()
		end
	end

	--幻武
	edType = 1
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Name")
		local strIcon 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Weapon_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Weapon_Weapon_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_Weapon_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Weapon_Weapon_LockImg:Show()
		end
	end
	
	--附体
	edType = 2
	local cacheVisualIndex = 0
	cacheExteriorID, cacheVisualIndex, _ = Exterior:LuaFnGetCurrentExteriorSetInfo("FUTI")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "Name")
		local strImage 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "VisualIcon", cacheVisualIndex)
		NewExterior_Weapon_PetPossJian_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_PetPossJian_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Weapon_PetPossJian_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_PetPossJian_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorFutiVisualIndex() ~= cacheVisualIndex then
				NewExterior_Weapon_PetPossJian_ActionImg:Show()
			end
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 or Exterior:LuaFnIsExteriorFutiVisualUnlocked(cacheExteriorID, cacheVisualIndex) ~= 1 then
			NewExterior_Weapon_PetPossJian_LockImg:Show()
		end
	end

	--脸型
	edType = 3
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FACE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Weapon_FaceStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_FaceStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_82}", strName)
		NewExterior_Weapon_FaceStyle_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_FaceStyle_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Weapon_FaceStyle_LockImg:Show()
		end
	end
	
	--发型
	edType = 4
	cacheExteriorID, cacheColorIndex = Exterior:LuaFnGetCurrentExteriorSetInfo("HAIR")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Weapon_HairStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_HairStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_81}", strName)
		NewExterior_Weapon_HairStyle_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_HairStyle_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorHairColorIndex() ~= cacheColorIndex then
				NewExterior_Weapon_HairStyle_ActionImg:Show()
			end
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Weapon_HairStyle_LockImg:Show()
		end
	end
	
	--头像
	edType = 5
	local strHeadTip = ""
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("PORTRAIT")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorPortraitInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorPortraitInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Weapon_PlayerFrame_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_PlayerFrame_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_79}", strName)
		strHeadTip = strTemp
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_PlayerFrame_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Weapon_PlayerFrame_LockImg:Show()
		end
	end
	
	--头像框
	edType = 6
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FRAME")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Name")
		local iFrameType = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Type")
		if iFrameType == 1 then
			NewExterior_Weapon_PlayerFrame_Mask:Hide()
			NewExterior_Weapon_PlayerFrame_Mask_Animate:Show()
			
			local strFrameAnimate = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameAnimate")
			NewExterior_Weapon_PlayerFrame_Mask_Animate:SetProperty("Animate", strFrameAnimate)
		else
			NewExterior_Weapon_PlayerFrame_Mask:Show()
			NewExterior_Weapon_PlayerFrame_Mask_Animate:Hide()
			
			local strIcon 	= Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameIcon")
			local strImage = GetIconFullName(strIcon)
			NewExterior_Weapon_PlayerFrame_Mask:SetProperty("Image", strImage)
		end
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_85}", strName)
		NewExterior_Weapon_PlayerFrame_LeftBtn:SetToolTip(strHeadTip.."#r"..strName)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Weapon_PlayerFrame_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Weapon_PlayerFrame_LockImg:Show()
		end
	end
	
	local edOrnamentsType, cacheExteriorX, cacheExteriorY, cacheExteriorZ = 0, 0, 0, 0
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsBack")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Weapon_Widget_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_Widget_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Weapon_Widget_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Weapon_Widget_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
			NewExterior_Weapon_Widget_LockImg:Show()
		end
	end

	edOrnamentsType= 1
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsHead")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Weapon_Headdress_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Weapon_Headdress_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Weapon_Headdress_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Weapon_Headdress_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
			NewExterior_Weapon_Headdress_LockImg:Show()
		end
	end
end
--列表
function NewExterior_Weapon_UpdateList()
	
	NewExterior_Weapon_UpdateCheckButton()
	NewExterior_Weapon_UpdateRedPoint()
	
	Exterior:LuaFnInitExteriorWeaponGroupList()
	local count = Exterior:LuaFnGetWeaponGroupListCount(0)
	
	for i = 1, g_MaxBarNum do	
		NewExterior_Weapon_SetItem(i, count)
	end
	
	if g_NeedChangeScrollSize == 1 then
		NewExterior_Weapon_SuperList:RefreshLayout()
		g_NeedChangeScrollSize = 0
	end
	
	if g_TargetExteriorIndex ~= 0 then
		NewExterior_Weapon_SuperList:SetScrollPosition4Index(g_TargetExteriorIndex - 1)
		g_TargetExteriorID = 0
		g_TargetExteriorIndex = 0
	else
		NewExterior_Weapon_SuperList:SetScrollPosition4Index(0)
	end
	
end

function NewExterior_Weapon_SetItem(index, max_count)
	
	if g_BarList[index] == nil then
		return
	end
	
	if index > max_count then
		g_BarList[index]:Hide()
		return
	end
	
	local bar = g_BarList[index]
	bar:Show()
	
	local nMyMenpai = Player:GetData("MEMPAI")
	local nGroupID 	= Exterior:LuaFnGetWeaponGroupIDFromList(index - 1)
	local strIcon 	= Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "Icon")
	local strName 	= Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "Name")
	local strImage = GetIconFullName(strIcon)
	local nMenpai 	= Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "Menpai")
	
	local ctrlAction = bar:GetSubItem("NewExterior_Weapon_SuperListItemAction")
	if ctrlAction ~= nil then	

		ctrlAction:SetProperty("NormalImage", strImage)
		ctrlAction:SetProperty("HoverImage", strImage)
		
		local strTemp = Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "ToolTips")  --ScriptGlobal_Format("#{WGTJ_201222_78}", strName)
		if nGroupID == 32 then
			strTemp = strTemp.."#r#{WGTJ_201222_146}"
		elseif nGroupID == 31 then
			strTemp = strTemp.."#r#{WGTJ_201222_145}"
		end
		ctrlAction:SetToolTip(strTemp)
		
		if g_CurSelExteriorID == nGroupID then
			ctrlAction:SetPushed(1)
			bar:GetSubItem("NewExterior_Weapon_SuperListItemActionTry"):Show()			
			local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorID, g_CurSelWeaponLevel - 1)
			if Exterior:LuaFnGetExteriorInUse(g_ExteriorType) == nExteriorWeaponID then
				bar:GetSubItem("NewExterior_Weapon_SuperListItemActionTry"):Hide()
			end
		else
			ctrlAction:SetPushed(0)
			bar:GetSubItem("NewExterior_Weapon_SuperListItemActionTry"):Hide()
		end			

		if g_TargetExteriorID == nGroupID then
			g_TargetExteriorIndex = index
		end
	end
	
	--非本门派蒙红 
	if nMyMenpai == nMenpai or nMenpai == -1 then			
		bar:GetSubItem("NewExterior_Weapon_SuperListItemActionMark"):Hide()
	else
		bar:GetSubItem("NewExterior_Weapon_SuperListItemActionMark"):Show()
	end	

	bar:GetSubItem("NewExterior_Weapon_SuperListItemActionTime"):Hide()
	--锁
	if Exterior:LuaFnIsHaveExteriorWeaponGroup(nGroupID) == 1 then
		bar:GetSubItem("NewExterior_Weapon_SuperListItemActionLock"):Hide()
	else		
		bar:GetSubItem("NewExterior_Weapon_SuperListItemActionLock"):Show()
	end	

	--使用中
	if Exterior:LuaFnGetWeaponGroupInUse() == nGroupID then
		bar:GetSubItem("NewExterior_Weapon_SuperListItemActionDef"):Show()
	else
		bar:GetSubItem("NewExterior_Weapon_SuperListItemActionDef"):Hide()
	end
	
	--红点
	bar:GetSubItem("NewExterior_Weapon_SuperListItemActionTip"):Hide()
	local nTip = Exterior:LuaFnGetExteriorWeaponGroupTip(nGroupID)
	if nTip == 1 then
		bar:GetSubItem("NewExterior_Weapon_SuperListItemActionTip"):Show()
	end
	
	bar:GetSubItem("NewExterior_Weapon_SuperListItemActionButton"):Hide()
	for i = 1, 5 do	
		local nID = Exterior:LuaFnGetWeaponIDFromGroup(nGroupID, i - 1)
		if nID > 0 then	
			local ActionNum = Exterior:LuaFnGetExteriorWeaponActionNum(nID)
			if ActionNum > 0 then
				bar:GetSubItem("NewExterior_Weapon_SuperListItemActionButton"):Show()
				break
			end
		end
	end
	
end
--模型
function NewExterior_Weapon_UpdateObj()

	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		
		Exterior:LuaFnUpdateExteriorAvatarWeapon(cacheExteriorID)
		Exterior:LuaFnUpdateExteriorPlayerData()
		
		NewExterior_Weapon_MidClient1:Hide()
		NewExterior_Weapon_MidClient2:Hide()
		NewExterior_Weapon_MidClient3:Hide()
		local ActionNum = Exterior:LuaFnGetExteriorWeaponActionNum(cacheExteriorID)
		
		if ActionNum == 1 then
			NewExterior_Weapon_MidClient1:Show()
		elseif ActionNum == 2 then
			NewExterior_Weapon_MidClient2:Show()		
		elseif ActionNum == 3 then
			NewExterior_Weapon_MidClient3:Show()
		end
	else
		Exterior:LuaFnUpdateExteriorPlayerData()
		
		NewExterior_Weapon_MidClient1:Hide()
		NewExterior_Weapon_MidClient2:Hide()
		NewExterior_Weapon_MidClient3:Hide()	
	end

	NewExterior_Weapon_ActionEnd()

	NewExterior_Weapon_UpdateCamera()

end
--等级部分
function NewExterior_Weapon_ShowLevelBtn()

	if g_CurSelExteriorID > 0 then
		for i = 1, 5 do	
			local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorID, i - 1)
			if nExteriorWeaponID ~= nil and nExteriorWeaponID > 0 then
				
				g_WeaponLevelAction[i]:Show()
			
				local strIcon 	= Exterior:LuaFnGetExteriorWeaponInfo(nExteriorWeaponID, "Icon")
				local strName 	= Exterior:LuaFnGetExteriorWeaponInfo(nExteriorWeaponID, "Name")
				local strImage = GetIconFullName(strIcon)
				
				g_WeaponLevelAction[i]:SetProperty("NormalImage", strImage)
				g_WeaponLevelAction[i]:SetProperty("HoverImage", strImage)
				
				local strTemp = Exterior:LuaFnGetExteriorWeaponToolTip(nExteriorWeaponID)
				if g_CurSelExteriorID == 32 then
					strTemp = strTemp.."#r#{WGTJ_201222_146}"
				elseif g_CurSelExteriorID == 31 then
					strTemp = strTemp.."#r#{WGTJ_201222_145}"
				end
				g_WeaponLevelAction[i]:SetToolTip(strTemp)
				
				if i == g_CurSelWeaponLevel then
					g_WeaponLevelAction[i]:SetPushed(1)
				else
					g_WeaponLevelAction[i]:SetPushed(0)
				end
				
				--解锁&限时标志
				if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorWeaponID) == 1 then
					g_WeaponLevelLock[i]:Hide()
					local nLeftTime = Exterior:LuaFnGetExteriorLeftTime(g_ExteriorType, nExteriorWeaponID)
					if nLeftTime and nLeftTime < 0 then
						g_WeaponLevelTime[i]:Hide()
					elseif nLeftTime and nLeftTime == 0 then
						g_WeaponLevelTime[i]:Show()
					elseif nLeftTime and nLeftTime > 0 then
						g_WeaponLevelTime[i]:Show()
					end
				else
					g_WeaponLevelLock[i]:Show()
					g_WeaponLevelTime[i]:Hide()
				end			
				
				g_WeaponLevelDef[i]:Hide()
				--使用中
				if Exterior:LuaFnGetExteriorInUse(g_ExteriorType) == nExteriorWeaponID then
					g_WeaponLevelDef[i]:Show()				
				end				
				
				g_WeaponLevelTip[i]:Hide()
				--红点
				local nTip = Exterior:LuaFnGetExteriorTip(g_ExteriorType, nExteriorWeaponID)
				if nTip == 1 then
					g_WeaponLevelTip[i]:Show()
				end
			else
				g_WeaponLevelAction[i]:Hide()			
			end			
		end
	else
		g_CurSelWeaponLevel = 0
		for i = 1, 5 do	
			g_WeaponLevelAction[i]:Hide()
		end
	end
end

function NewExterior_Weapon_UpdateOpBtn()
						
end

function NewExterior_Weapon_MakeHyperlink(nGroupID)
	local tempWeaponLevel = 1
	for i = 1, 5 do
		local nID = Exterior:LuaFnGetWeaponIDFromGroup(nGroupID, i - 1)
		if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nID) == 1 then
			tempWeaponLevel = i
		end
	end
	local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(nGroupID, tempWeaponLevel - 1)

	local ret = Exterior:LuaFnExteriorWeaponItemClick(nExteriorWeaponID)
	if ret == 2 then
		PushDebugMessage("#{WGTJ_201222_132}")
	end
	return ret
end

function NewExterior_Weapon_ItemClicked(nIndex)
	
	local nGroupID 	= Exterior:LuaFnGetWeaponGroupIDFromList(nIndex - 1)	
	local ret = NewExterior_Weapon_MakeHyperlink(nGroupID)
	if ret == 1 or ret == 2 then
		return
	end
	if g_CurSelExteriorID ~= nGroupID then
		g_CurSelExteriorID = nGroupID
		NewExterior_Weapon_SetItemSelected(nIndex)		
		
		g_CurSelWeaponLevel = 1
		for i = 1, 5 do
			local nID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorID, i - 1)
			if nID > 0 then
				g_CurSelWeaponLevel = i
				break
			end			
		end
		
		for i = 1, 5 do
			local nID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorID, i - 1)
			if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nID) == 1 then
				g_CurSelWeaponLevel = i
			end
		end
		
		NewExterior_Weapon_ShowLevelBtn()
		
		local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorID, g_CurSelWeaponLevel - 1)
		Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", nExteriorWeaponID)	
		Exterior:LuaFnSetCurExteriorShareInfo("WEAPON", nExteriorWeaponID, g_CurSelWeaponLevel)
		
		NewExterior_Weapon_UpdateLeftBtn()		
		NewExterior_Weapon_UpdateObj()		

		NewExterior_Weapon_RemoveTip(nExteriorWeaponID)
		NewExterior_Weapon_UpdateRedPoint()
	else
		local defExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
		Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", defExteriorID)	
		
		local group, level = 0, 0
		if defExteriorID ~= nil and defExteriorID > 0 then
			group, level = Exterior:LuaFnGetExteriorWeaponInfo(defExteriorID, "Group")
		end
		Exterior:LuaFnSetCurExteriorShareInfo("WEAPON", defExteriorID, level+1)
		
		NewExterior_Weapon_Show()
	end	
	
	NewExterior_Weapon_CloseTuJing()
end

function NewExterior_Weapon_ItemMouseMove(nIndex)

end

function NewExterior_Weapon_SetItemSelected(nIndex)
	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("NewExterior_Weapon_SuperListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
					g_BarList[i]:GetSubItem("NewExterior_Weapon_SuperListItemActionTry"):Show()
					local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorID, nIndex - 1)
					if Exterior:LuaFnGetExteriorInUse(g_ExteriorType) == nExteriorWeaponID then
						g_BarList[i]:GetSubItem("NewExterior_Weapon_SuperListItemActionTry"):Hide()
					end
				else
					ctrlAction:SetPushed(0)	
					g_BarList[i]:GetSubItem("NewExterior_Weapon_SuperListItemActionTry"):Hide()
				end
			end
		end
	end
end
function NewExterior_Weapon_MakeHyperlink2(nLevel)
	local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorID, nLevel - 1)
	if nExteriorWeaponID <= 0 then
		return
	end
	local ret = Exterior:LuaFnExteriorWeaponItemClick(nExteriorWeaponID)
	if ret == 2 then
		PushDebugMessage("#{WGTJ_201222_132}")
	end
	return ret
end
function NewExterior_Weapon_WeaponLevelClicked(nLevel)
	local ret = NewExterior_Weapon_MakeHyperlink2(nLevel)
	if ret == 1 or ret ==2 then
		return
	end
	if g_CurSelExteriorID == 0 then
		return
	end
	
	if nLevel == g_CurSelWeaponLevel then
		return
	end
	
	local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorID, nLevel - 1)
	if nExteriorWeaponID <= 0 then
		return
	end

	g_CurSelWeaponLevel = nLevel
	NewExterior_Weapon_SetWeaponLevelSelected(nLevel)
	
	Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", nExteriorWeaponID)
	
	Exterior:LuaFnSetCurExteriorShareInfo("WEAPON", nExteriorWeaponID, g_CurSelWeaponLevel)
	
	NewExterior_Weapon_UpdateLeftBtn()		
	NewExterior_Weapon_UpdateObj()		

	NewExterior_Weapon_RemoveTip(nExteriorWeaponID)
	NewExterior_Weapon_UpdateRedPoint()
	NewExterior_Weapon_UpdateGroupTry()

end

function NewExterior_Weapon_SetWeaponLevelSelected(nIndex)
	for i = 1, 5 do		
		if i == nIndex then
			g_WeaponLevelAction[i]:SetPushed(1)
		else
			g_WeaponLevelAction[i]:SetPushed(0)	
		end
	end
end

function NewExterior_Weapon_TryExterior()
	local selfSex = GetMySelfRaceId()
	local selectSex = Exterior:LuaFnGetExteriorRaceID()
	if selfSex ~= selectSex then
		PushDebugMessage("#{SZTJ_231030_01}")
		return
	end
	if Exterior:LuaFnIsHaveExteriorChange() ~= 1 then
		if Exterior:LuaFnIsHaveDressStyleChange() == 1 then
			Exterior:LuaFnSetCurrentExteriorSetInfo("RESETDRESSSTYLE")
			Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", selfSex)
			Exterior:LuaFnInitCurrentExteriorSet()
			NewExterior_Weapon_Show()
		else
			PushDebugMessage("#{WGTJ_201222_72}")
		end
		return
	end
	
	Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	Exterior:LuaFnSaveExteriorAllChange(1)
end

function NewExterior_Weapon_TakeOffRide()
	local defExteriorID = Exterior:LuaFnGetExteriorInUse(0)
	if defExteriorID == 0 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("RIDE", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("RIDE", 0)
		NewExterior_Weapon_UpdateLeftBtn()
	else
		Exterior:LuaFnSetExteriorInUse(0, 0, 0)
	end
end

function NewExterior_Weapon_TakeOffWeapon()
	local defExteriorID = Exterior:LuaFnGetExteriorInUse(1)
	if defExteriorID == 0 then
		g_CurSelExteriorID = 0
		Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("WEAPON", 0, 0)
		NewExterior_Weapon_UpdateList()
		NewExterior_Weapon_UpdateLeftBtn()
		Exterior:LuaFnRestoreExteriorPlayerFittingData(1)
		Exterior:LuaFnUpdateExteriorPlayerData()
		NewExterior_Weapon_ShowLevelBtn()
		NewExterior_Weapon_UpdateObj()	
	else
		g_CurSelExteriorID = 0
		Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("WEAPON", 0, 0)
		
		Exterior:LuaFnSetExteriorInUse(1, 0, 0)
	end
end

function NewExterior_Weapon_RemovePreview()
	if Exterior:LuaFnIsHaveExteriorChange() == 1 or Exterior:LuaFnIsHaveDressStyleChange() == 1 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
		Exterior:LuaFnInitCurrentExteriorSet()
		NewExterior_Weapon_Show()
		PushDebugMessage("#{WGTJ_201222_98}")
	else
		PushDebugMessage("#{WGTJ_201222_76}")
	end
end

function NewExterior_Weapon_Goto()
	AutoRuntoTargetExWithName(338, 270, 0, "庄舞诗")
end

function NewExterior_Weapon_CloseClick()
	Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	
	NewExterior_Weapon_SavePosition()
	this:Hide()
end

function NewExterior_Weapon_OnHidden()	
	
	if IsWindowShow("NewExterior_DressBox") 
		or IsWindowShow("NewExterior_Ride") 
		or IsWindowShow("NewExterior_PetPossJian")
		or IsWindowShow("NewExterior_Facestyle") 
		or IsWindowShow("NewExterior_HairStyle") 
		or IsWindowShow("NewExterior_PlayerFrame")
		or IsWindowShow("NewExterior_Widget") 
		or IsWindowShow("NewExterior_Headdress")
		or IsWindowShow("NewExterior_DressStyle")
		or IsWindowShow("NewExterior_GemEffect") then
	else	
		Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	end	
	
	NewExterior_Weapon_CleanUp()
	
	if IsWindowShow("NewExterior_PlanSetting") then
		CloseWindow("NewExterior_PlanSetting", true)
	end
	
	NewExterior_Weapon_CloseTuJing()
end

function NewExterior_Weapon_CleanUp()
	for i = 1, g_MaxBarNum do
		if g_BarList[i] then
			local ctrlAction = g_BarList[i]:GetSubItem("NewExterior_Weapon_SuperListItemAction")			
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
			end
		end
	end
	NewExterior_Weapon_FakeObject:DetachWindowEx()
	
	NewExterior_Weapon_CleanUp_LeftButton()
	
	for i = 1, 5 do
		g_WeaponLevelAction[i]:SetProperty("Empty", "False")
		g_WeaponLevelAction[i]:SetProperty("UseDefaultTooltip", "True")
		g_WeaponLevelAction[i]:SetProperty("NormalImage", "")
		g_WeaponLevelAction[i]:SetProperty("HoverImage", "")
		g_WeaponLevelAction[i]:SetToolTip("")
		g_WeaponLevelLock[i]:Hide()
	end
end
	
function NewExterior_Weapon_CleanUp_LeftButton()
	NewExterior_Weapon_Dress_LeftBtn:SetActionItem(-1)
	NewExterior_Weapon_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "False")
	NewExterior_Weapon_Dress_LeftBtn:SetProperty("NormalImage", "")
	NewExterior_Weapon_Dress_LeftBtn:SetProperty("HoverImage", "")
	NewExterior_Weapon_Dress_LeftBtn:SetProperty("Empty", "True")

	local ctrl_list = {
		[1] = NewExterior_Weapon_Weapon_LeftBtn,
		[2] = NewExterior_Weapon_PetPossJian_LeftBtn,
		[3] = NewExterior_Weapon_FaceStyle_LeftBtn,
		[4] = NewExterior_Weapon_HairStyle_LeftBtn,
		[5] = NewExterior_Weapon_PlayerFrame_LeftBtn,
		[6] = NewExterior_Weapon_Ride_LeftBtn,
		[7] = NewExterior_Weapon_Widget_LeftBtn,
		[8] = NewExterior_Weapon_Headdress_LeftBtn,
	}
	
	for i = 1 ,8 do
		ctrl_list[i]:SetProperty("Empty", "False")
		ctrl_list[i]:SetProperty("UseDefaultTooltip", "True")
		ctrl_list[i]:SetProperty("NormalImage", "")
		ctrl_list[i]:SetProperty("HoverImage", "")
		ctrl_list[i]:SetToolTip("")
	end
	
	NewExterior_Weapon_PlayerFrame_Mask:SetProperty("Image", "")
	NewExterior_Weapon_PlayerFrame_Mask_Animate:SetProperty("Animate", "")
	
	NewExterior_Weapon_Dress_ActionImg:Hide()
	NewExterior_Weapon_Weapon_ActionImg:Hide()
	NewExterior_Weapon_PetPossJian_ActionImg:Hide()
	NewExterior_Weapon_FaceStyle_ActionImg:Hide()
	NewExterior_Weapon_HairStyle_ActionImg:Hide()
	NewExterior_Weapon_PlayerFrame_ActionImg:Hide()
	NewExterior_Weapon_Ride_ActionImg:Hide()	
	NewExterior_Weapon_Widget_ActionImg:Hide()
	NewExterior_Weapon_Headdress_ActionImg:Hide()

	NewExterior_Weapon_Dress_LockImg:Hide()
	NewExterior_Weapon_Weapon_LockImg:Hide()
	NewExterior_Weapon_PetPossJian_LockImg:Hide()
	NewExterior_Weapon_FaceStyle_LockImg:Hide()
	NewExterior_Weapon_HairStyle_LockImg:Hide()
	NewExterior_Weapon_PlayerFrame_LockImg:Hide()
	NewExterior_Weapon_Ride_LockImg:Hide()
	NewExterior_Weapon_Widget_LockImg:Hide()
	NewExterior_Weapon_Headdress_LockImg:Hide()

end

function NewExterior_Weapon_FakeObject_TurnLeft(idx)
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		NewExterior_Weapon_FakeObject:RotateBeginEx("Exterior_Player", -0.3)
	else
		NewExterior_Weapon_FakeObject:RotateEndEx()
	end
end

function NewExterior_Weapon_FakeObject_TurnRight(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		NewExterior_Weapon_FakeObject:RotateBeginEx("Exterior_Player", 0.3)
	else
		NewExterior_Weapon_FakeObject:RotateEndEx()
	end
end
--缩小
function NewExterior_Weapon_ZoomOut()
	if g_Distance == 1 then
		return
	end
	g_Distance = g_Distance - 1
	NewExterior_Weapon_UpdateCamera()
end
--放大
function NewExterior_Weapon_ZoomIn()
	if g_Distance == g_Distance_Max then
		return
	end	
	g_Distance = g_Distance + 1
	NewExterior_Weapon_UpdateCamera()
end

function NewExterior_Weapon_UpdateCamera()
	local sex = Exterior:LuaFnGetExteriorRaceID()
	if sex ~= 0 and sex ~= 1 then 
		return
	end
		
	if g_Distance < 1 or g_Distance > g_Distance_Max then
		return
	end
	
	local isIVMode = LuaFnGetCurModelState()
	local cameraInfo = g_CameraPosition
	if isIVMode == 1 then
		cameraInfo = g_CameraPosition_IV
	end
	
	local fHeight, fDistance, fPitch = NewExterior_Weapon_FakeObject:GetCameraEx()
	fHeight = cameraInfo[sex][g_Distance].fHeight
	fDistance = cameraInfo[sex][g_Distance].fDistance
	fPitch = cameraInfo[sex][g_Distance].fPitch
	fXOffset = cameraInfo[sex][g_Distance].fXOffset
	NewExterior_Weapon_FakeObject:SetCameraEx(fHeight, fDistance, fPitch, fXOffset)
	
	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
	
	--if cacheExteriorID >= 26 and cacheExteriorID <= 30 then
	--	fHeight = 1.15
	--	fDistance = 6.4
	--else
	--	fHeight = 0.95
	--	fDistance = 5.4
--	end
	
end

function Exterior_Weapon_DoAction(index)	
	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
	
	local sex = Exterior:LuaFnGetExteriorRaceID()
	for i = 1, table.getn(g_SpecialWeaponCamera) do
		if g_SpecialWeaponCamera[i][sex] ~= nil and cacheExteriorID >= g_SpecialWeaponCamera[i][sex].startid and cacheExteriorID <= g_SpecialWeaponCamera[i][sex].endid then
			local fHeight, fDistance, fPitch = NewExterior_Weapon_FakeObject:GetCameraEx()
			if g_SpecialWeaponCamera[i][sex].fDistance ~= -1 then
				fDistance = g_SpecialWeaponCamera[i][sex].fDistance
			end
			if g_SpecialWeaponCamera[i][sex].fHeight ~= -1 then
				fHeight = g_SpecialWeaponCamera[i][sex].fHeight
			end
			if g_SpecialWeaponCamera[i][sex].fPitch ~= -1 then
				fPitch = g_SpecialWeaponCamera[i][sex].fPitch
			end
			NewExterior_Weapon_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)
			NewExterior_Weapon_Model_Plus:Disable()
			NewExterior_Weapon_Model_Subtract:Disable()
			NewExterior_Weapon_Model_TurnLeft:Disable()
			NewExterior_Weapon_Model_TurnRight:Disable()
			
			SetTimer("NewExterior_Weapon","NewExterior_Weapon_ActionEnd()", g_SpecialWeaponCamera[i][sex].timecount)
		end		
	end
	
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		Exterior:LuaFnExteriorAvatarPlayAction(0, cacheExteriorID, index - 1)
	end	
end

function NewExterior_Weapon_ActionEnd()
	KillTimer("NewExterior_Weapon_ActionEnd()");
	
	NewExterior_Weapon_Model_Plus:Enable()
	NewExterior_Weapon_Model_Subtract:Enable()
	NewExterior_Weapon_Model_TurnLeft:Enable()
	NewExterior_Weapon_Model_TurnRight:Enable()
	
	NewExterior_Weapon_UpdateCamera()
end

function NewExterior_Weapon_UpdateCheckButton()
--	NewExterior_Weapon_ButtonHuanwu:SetCheck(0)
--	NewExterior_Weapon_ButtonZhuangrong:SetCheck(0)
--	NewExterior_Weapon_ButtonFuti:SetCheck(0)
--	NewExterior_Weapon_ButtonZuoqi:SetCheck(1)
end
--右键取下时装
function NewExterior_Weapon_ActionToDressBox()
	local isShow = 0
	local cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		cacheExteriorID = 0
		cacheExteriorIdx = -1
		Exterior:LuaFnSetCurrentExteriorSetInfo("FASHION", cacheExteriorID, cacheExteriorIdx)            
		isShow = 1
		--return
	end
	local gem1, gem2, gem3 = 0,0,0
	cacheExteriorID, cacheExteriorIdx, gem1, gem2, gem3 = Exterior:LuaFnGetCurExteriorShareInfo("FASHION")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		cacheExteriorID = 0
		cacheExteriorIdx = -1
		Exterior:LuaFnSetCurExteriorShareInfo("FASHION", cacheExteriorID, cacheExteriorIdx)            
		isShow = 1
	end
	local cacheID,cacheSubID = Exterior:LuaFnGetCurrentExteriorSetInfo("DRESSSTYLE")
	if cacheID ~= nil and cacheID > 0 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("DRESSSTYLE", 0, 0)
		isShow = 1
	end

	if isShow > 0 then
		for i=1, 3 do
            Exterior:LuaFnSetCurrentExteriorSetInfo("GEMEFFECT", i-1, 0, 0)
        end
		NewExterior_Weapon_Show()
	end
	Exterior:LuaFnUnUseExteriorFashion(1)
end
--时装
function NewExterior_Weapon_OpenFashion()
	NewExterior_Weapon_SavePosition()
	PushEvent("OPEN_EXTERIOR_FASHION", 1, 0)
end
--幻武
function NewExterior_Weapon_OpenWeapon()
	--NewExterior_Weapon_SavePosition()
	--Exterior:LuaFnAskOpenExterior(1)
	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
	Exterior:LuaFnExteriorWeaponItemClick(cacheExteriorID)
end
--附体
function NewExterior_Weapon_OpenFuti()
	NewExterior_Weapon_SavePosition()
	Exterior:LuaFnAskOpenExterior(2)
end
--坐骑
function NewExterior_Weapon_OpenRide()
	NewExterior_Weapon_SavePosition()
	Exterior:LuaFnAskOpenExterior(0)
end
--发型
function NewExterior_Weapon_OpenHair()
	NewExterior_Weapon_SavePosition()	
	Exterior:LuaFnAskOpenExterior(4)
end
--脸型
function NewExterior_Weapon_OpenFace()
	NewExterior_Weapon_SavePosition()	
	Exterior:LuaFnAskOpenExterior(3)
end
--头像
function NewExterior_Weapon_OpenPortrait()
	NewExterior_Weapon_SavePosition()	
	Exterior:LuaFnAskOpenExterior(5)
end
--背挂
function NewExterior_Weapon_OpenOrnamentsBack()
	NewExterior_Weapon_SavePosition()	
	OrnamentsScript:AskOrnamentsInfo(0)
end
--头挂
function NewExterior_Weapon_OpenOrnamentsHead()
	NewExterior_Weapon_SavePosition()	
	OrnamentsScript:AskOrnamentsInfo(1)
end
--打开展示柜
function NewExterior_Weapon_OpenYiRongGe()
	NewExterior_Weapon_SavePosition()
	Exterior:LuaFnAskExteriorYiRongGeInfo(1, 2)
end
function NewExterior_Weapon_OpenInfant()
	NewExterior_Weapon_SavePosition()
	Exterior:LuaFnInitExteriorFashionList(2, 1)
end

function NewExterior_Weapon_CloseSameGroupWindow()
	CloseWindow("SelfEquip", true)
	CloseWindow("NewExterior_Ride", true)
	--CloseWindow("NewExterior_Weapon", true)
	CloseWindow("NewExterior_PetPossJian", true)
	CloseWindow("NewExterior_Facestyle", true)
	CloseWindow("NewExterior_HairStyle", true)
	CloseWindow("NewExterior_PlayerFrame", true)
	CloseWindow("NewExterior_DressBox", true)
	CloseWindow("NewExterior_Widget", true)
	CloseWindow("NewExterior_Headdress", true)
	CloseWindow("NewExterior_DressStyle", true)
	CloseWindow("NewExterior_GemEffect", true)
	CloseWindow("NewExterior_PlanSetting", true)
	CloseWindow("NewExterior_TuJing", true)
end

function NewExterior_Weapon_SavePosition()
	Variable:SetVariable("ExteriorUnionPos", NewExterior_Weapon_Frame:GetProperty("UnifiedPosition"), 1)
end

function NewExterior_Weapon_SetPosition()	
	local nExteriorUnionPos = Variable:GetVariable("ExteriorUnionPos")
	if nExteriorUnionPos ~= nil then
		NewExterior_Weapon_Frame:SetProperty("UnifiedPosition", nExteriorUnionPos)
	end
end

function NewExterior_Weapon_RemoveTip(nExteriorID)	
	local nTip = Exterior:LuaFnGetExteriorTip(g_ExteriorType, nExteriorID)
	if nTip == 1 then
		Exterior:LuaFnRemoveExteriorTip(g_ExteriorType, nExteriorID)
	--	NewExterior_Ride_UpdateCheckButton()
		
		for i = 1, 5 do	
			local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorID, i - 1)
			if nExteriorWeaponID == nExteriorID then
				g_WeaponLevelTip[i]:Hide()			
			end
		end

		NewExterior_Weapon_UpdateGroupTip()
	end	
end

function NewExterior_Weapon_UpdateGroupTip()
	--更新幻武组的红点
	for i = 1, g_MaxBarNum do
		if g_BarList[i] then
			local nGroupID 	= Exterior:LuaFnGetWeaponGroupIDFromList(i - 1)
			local nTip = Exterior:LuaFnGetExteriorWeaponGroupTip(nGroupID)
			if nTip == 1 then
				g_BarList[i]:GetSubItem("NewExterior_Weapon_SuperListItemActionTip"):Show()
			else
				g_BarList[i]:GetSubItem("NewExterior_Weapon_SuperListItemActionTip"):Hide()
			end
		end
	end
end

--更新幻武组的试穿标志
function NewExterior_Weapon_UpdateGroupTry()
	for i = 1, g_MaxBarNum do
		if g_BarList[i] then
			local nGroupID 	= Exterior:LuaFnGetWeaponGroupIDFromList(i - 1)
			if nGroupID == g_CurSelExteriorID then
				local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorID, g_CurSelWeaponLevel - 1)
				if nExteriorWeaponID == Exterior:LuaFnGetExteriorInUse(g_ExteriorType) then
					g_BarList[i]:GetSubItem("NewExterior_Weapon_SuperListItemActionTry"):Hide()
				else
					g_BarList[i]:GetSubItem("NewExterior_Weapon_SuperListItemActionTry"):Show()
				end
			end
		end
	end
end

function NewExterior_Weapon_UpdateRedPoint()
	
	NewExterior_Weapon_Dress_Tip:Hide()
	
	if Exterior:LuaFnIsHaveExteriorShowTip(0) == 1 then
		NewExterior_Weapon_Ride_Tip:Show()
	else
		NewExterior_Weapon_Ride_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(1) == 1 then
		NewExterior_Weapon_Weapon_Tip:Show()
	else
		NewExterior_Weapon_Weapon_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(2) == 1 then
		NewExterior_Weapon_PetPossJian_Tip:Show()
	else
		NewExterior_Weapon_PetPossJian_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(3) == 1 then
		NewExterior_Weapon_FaceStyle_Tip:Show()
	else
		NewExterior_Weapon_FaceStyle_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(4) == 1 or Exterior:LuaFnIsHaveHairColorShowTip() == 1 then
		NewExterior_Weapon_HairStyle_Tip:Show()
	else
		NewExterior_Weapon_HairStyle_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(5) == 1 or Exterior:LuaFnIsHaveExteriorShowTip(6) == 1 then
		NewExterior_Weapon_PlayerFrame_Tip:Show()
	else
		NewExterior_Weapon_PlayerFrame_Tip:Hide()
	end	
	
	if Pneuma:GetMF(2959)== 1 or Exterior:LuaFnIsHaveExteriorShowTip(7) == 1 or Exterior:LuaFnIsHaveInfantHairColorShowTip() == 1 then 
		NewExterior_Weapon_SwitchBtn_Tip:Show()
	else
		NewExterior_Weapon_SwitchBtn_Tip:Hide()
	end

	if OrnamentsScript:IsHaveOrnamentsShowTip(0) == 1 then
		NewExterior_Weapon_Widget_Tip:Show()
	else
		NewExterior_Weapon_Widget_Tip:Hide()
	end

	if OrnamentsScript:IsHaveOrnamentsShowTip(1) == 1 then
		NewExterior_Weapon_Headdress_Tip:Show()
	else
		NewExterior_Weapon_Headdress_Tip:Hide()
	end
end

function NewExterior_Weapon_ShowFashionWeaponCheckButton()
	local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
	NewExterior_Weapon_Dress_Type:SetCheck(IsDisplay)
	
	IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
	NewExterior_Weapon_Weapon_Type:SetCheck(IsDisplay)

	IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
	NewExterior_Weapon_Widget_Type:SetCheck(IsDisplay)
	
	IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
	NewExterior_Weapon_Headdress_Type:SetCheck(IsDisplay)

	IsDisplay = SystemSetup:Lua_GetFuTiDisplayState()
	NewExterior_Weapon_PetPossJian_Type:SetCheck(IsDisplay)
end

function NewExterior_Weapon_FashionDisplay()
	local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
	if IsDisplay == 1 then
		NewExterior_Weapon_Dress_Type:SetCheck(0)
		SystemSetup:LuaFnCloseFashionDisplay(1)
	else
		NewExterior_Weapon_Dress_Type:SetCheck(1)
		SystemSetup:LuaFnCloseFashionDisplay(0)
	end	
end

function NewExterior_Weapon_ExteriorWeaponDisplay()
	local IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
	if IsDisplay == 1 then
		NewExterior_Weapon_Weapon_Type:SetCheck(0)
		SystemSetup:LuaFnCloseExteriorWeaponDisplay(1)
	else
		NewExterior_Weapon_Weapon_Type:SetCheck(1)
		SystemSetup:LuaFnCloseExteriorWeaponDisplay(0)
	end	
end

function NewExterior_Weapon_OrnamentsBackDisplay()
	local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
	if IsDisplay == 1 then
		NewExterior_Weapon_Widget_Type:SetCheck(0)
		SystemSetup:SetOrnamentsDisplayState(0, 1)
		OrnamentsScript:ResetOrnamentsUseInfo(0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		NewExterior_Weapon_Widget_Type:SetCheck(1)
		SystemSetup:SetOrnamentsDisplayState(0, 0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	end	
end

function NewExterior_Weapon_OrnamentsHeadDisplay()
	local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
	if IsDisplay == 1 then
		NewExterior_Weapon_Headdress_Type:SetCheck(0)
		SystemSetup:SetOrnamentsDisplayState(1, 1)
		OrnamentsScript:ResetOrnamentsUseInfo(1)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		NewExterior_Weapon_Headdress_Type:SetCheck(1)
		SystemSetup:SetOrnamentsDisplayState(1, 0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	end	
end

function NewExterior_Weapon_ActionToOrnamentsBack()
	local useID = OrnamentsScript:GetOrnamentsUseID(0)
	if useID > 0 then
		OrnamentsScript:TakeOffOrnaments(0)
	end
	Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSBACK", 0, 0, 0, 0)
	Exterior:LuaFnSetCurExteriorShareInfo("ORNAMENTSBACK", 0, 0, 0, 0)
	NewExterior_Weapon_UpdateLeftBtn()
	Exterior:LuaFnRestoreExteriorPlayerFittingData(6)
	Exterior:LuaFnUpdateExteriorPlayerData()
end

function NewExterior_Weapon_ActionToOrnamentsHead()
	local useID = OrnamentsScript:GetOrnamentsUseID(1)
	if useID > 0 then
		OrnamentsScript:TakeOffOrnaments(1)
	end
	Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSHEAD", 0, 0, 0, 0)
	Exterior:LuaFnSetCurExteriorShareInfo("ORNAMENTSHEAD", 0, 0, 0, 0)
	NewExterior_Weapon_UpdateLeftBtn()
	Exterior:LuaFnRestoreExteriorPlayerFittingData(7)
	Exterior:LuaFnUpdateExteriorPlayerData()
end

-- 来源
function NewExterior_Weapon_CloseTuJing()
	if IsWindowShow("NewExterior_TuJing") then
		CloseWindow("NewExterior_TuJing", true)
	end
end

-- 来源
function NewExterior_Weapon_ClickTuJing()
	if g_CurSelExteriorID > 0 then		
		PushEvent("OPEN_EXTERIOR_TUJING", g_ExteriorType, g_CurSelExteriorID, -1, -1)
	else
		PushDebugMessage("#{SZDP_230509_64}")
	end
end

--方案
function NewExterior_Weapon_UpdateFangAn()
	
	local g_CurSelShareStyleIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("STYLE")	
	if g_CurSelShareStyleIdx > 0 then
		Exterior:LuaFnTryExteriorShareInfo(g_CurSelShareStyleIdx-1)
	end
	
end

function NewExterior_Weapon_ChangeSex()
	local sex = Exterior:LuaFnGetExteriorRaceID()
	if sex ~= nil then
		if sex == g_PlayerRace.SEX_FEMALE then
			Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_MALE)
		elseif sex == g_PlayerRace.SEX_MALE then
			Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_FEMALE)
		end
		NewExterior_Weapon_Show()
	end
end

function NewExterior_Weapon_GenderUpdate()
	local sex = Exterior:LuaFnGetExteriorRaceID()
	if sex ~= nil and g_sexButtonInfo[sex] ~= nil then
		NewExterior_Weapon_GenderChange_Btn:SetProperty("HoverImage", g_sexButtonInfo[sex].imgH)
		NewExterior_Weapon_GenderChange_Btn:SetProperty("NormalImage", g_sexButtonInfo[sex].imgN)
		NewExterior_Weapon_GenderChange_Btn:SetProperty("PushedImage", g_sexButtonInfo[sex].imgP)
	end
end

function NewExterior_Weapon_PetPossJianDisplay()
	local IsDisplay = SystemSetup:Lua_GetFuTiDisplayState()
	if IsDisplay == 1 then
		NewExterior_Weapon_PetPossJian_Type:SetCheck(0)
		SystemSetup:Lua_SetFuTiDisplayState(1)
	else
		NewExterior_Weapon_PetPossJian_Type:SetCheck(1)
		SystemSetup:Lua_SetFuTiDisplayState(0)
	end	
end
--!!!reloadscript =NewExterior_Weapon