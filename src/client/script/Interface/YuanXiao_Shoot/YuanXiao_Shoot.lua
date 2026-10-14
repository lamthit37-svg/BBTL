-- 靶
local g_Target = {}
-- 靶快消失的特效
local g_TargetAnim2 = {}
-- 居中
local g_YuanXiao_Shoot_Frame_UnifiedPosition
-- 靶的存在时间
local g_TargetTime = {

	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
	[7] = 0,
	[8] = 0,
	[9] = 0,
	[10] = 0,
	[11] = 0,
	[12] = 0,
	[13] = 0,
	[14] = 0,
	[15] = 0,
	[16] = 0,
	[17] = 0,
	[18] = 0,

}

-- 靶是否被点击过了
local g_TargetIsClick = {

	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
	[7] = 0,
	[8] = 0,
	[9] = 0,
	[10] = 0,
	[11] = 0,
	[12] = 0,
	[13] = 0,
	[14] = 0,
	[15] = 0,
	[16] = 0,
	[17] = 0,
	[18] = 0,

}
local g_TargetPos = {

[1] = {x=64,y=84,r=39,z=4},
[2] = {x=144,y=103,r=39,z=4},
[3] = {x=224,y=115,r=39,z=4},
[4] = {x=304,y=124,r=39,z=4},
[5] = {x=384,y=128,r=39,z=4},
[6] = {x=466,y=126,r=39,z=4},
[7] = {x=544,y=119,r=39,z=4},
[8] = {x=624,y=106,r=39,z=4},
[9] = {x=704,y=87,r=39,z=4},
[10] = {x=67,y=264,r=25,z=3},
[11] = {x=122,y=234,r=49,z=5},
[12] = {x=229,y=270,r=28,z=3},
[13] = {x=287,y=260,r=30,z=3},
[14] = {x=353,y=243,r=49,z=5},
[15] = {x=459,y=251,r=40,z=4},
[16] = {x=554,y=261,r=30,z=3},
[17] = {x=623,y=238,r=49,z=3},
[18] = {x=725,y=284,r=25,z=3},

}

local g_TargetTick = {
	
	[1] = {createnum=1,allnum=1},
	[2] = {createnum=0,allnum=1},
	[3] = {createnum=0,allnum=1},
	[4] = {createnum=0,allnum=1},
	[5] = {createnum=1,allnum=2},
	[6] = {createnum=0,allnum=2},
	[7] = {createnum=0,allnum=2},
	[8] = {createnum=0,allnum=2},
	[9] = {createnum=1,allnum=3},
	[10] = {createnum=0,allnum=3},
	[11] = {createnum=0,allnum=3},
	[12] = {createnum=0,allnum=3},
	[13] = {createnum=1,allnum=4},
	[14] = {createnum=0,allnum=4},
	[15] = {createnum=0,allnum=4},
	[16] = {createnum=0,allnum=4},
	[17] = {createnum=1,allnum=5},
	[18] = {createnum=0,allnum=5},
	[19] = {createnum=0,allnum=5},
	[20] = {createnum=0,allnum=5},
	[21] = {createnum=1,allnum=6},
	[22] = {createnum=0,allnum=6},
	[23] = {createnum=1,allnum=7},
	[24] = {createnum=0,allnum=7},
	[25] = {createnum=1,allnum=8},
	[26] = {createnum=0,allnum=8},
	[27] = {createnum=1,allnum=9},
	[28] = {createnum=0,allnum=9},
	[29] = {createnum=1,allnum=10},
	[30] = {createnum=0,allnum=10},
	[31] = {createnum=1,allnum=11},
	[32] = {createnum=0,allnum=11},
	[33] = {createnum=1,allnum=12},
	[34] = {createnum=0,allnum=12},
	[35] = {createnum=1,allnum=13},
	[36] = {createnum=0,allnum=13},
	[37] = {createnum=1,allnum=14},
	[38] = {createnum=0,allnum=14},
	[39] = {createnum=1,allnum=15},
	[40] = {createnum=0,allnum=15},
	[41] = {createnum=1,allnum=16},
	[42] = {createnum=0,allnum=16},
	[43] = {createnum=1,allnum=17},
	[44] = {createnum=0,allnum=17},
	[45] = {createnum=1,allnum=18},
	[46] = {createnum=0,allnum=18},
	[47] = {createnum=1,allnum=19},
	[48] = {createnum=0,allnum=19},
	[49] = {createnum=1,allnum=20},
	[50] = {createnum=0,allnum=20},
	[51] = {createnum=1,allnum=21},
	[52] = {createnum=0,allnum=21},
	[53] = {createnum=1,allnum=22},
	[54] = {createnum=0,allnum=22},
	[55] = {createnum=1,allnum=23},
	[56] = {createnum=0,allnum=23},
	[57] = {createnum=1,allnum=25},
	[58] = {createnum=0,allnum=25},
	[59] = {createnum=1,allnum=25},
	[60] = {createnum=0,allnum=25},
	[61] = {createnum=2,allnum=27},
	[62] = {createnum=0,allnum=27},
	[63] = {createnum=0,allnum=27},
	[64] = {createnum=0,allnum=27},
	[65] = {createnum=1,allnum=28},
	[66] = {createnum=0,allnum=28},
	[67] = {createnum=1,allnum=29},
	[68] = {createnum=0,allnum=29},
	[69] = {createnum=1,allnum=30},
	[70] = {createnum=0,allnum=30},
	[71] = {createnum=1,allnum=31},
	[72] = {createnum=0,allnum=31},
	[73] = {createnum=2,allnum=33},
	[74] = {createnum=0,allnum=33},
	[75] = {createnum=0,allnum=33},
	[76] = {createnum=0,allnum=33},
	[77] = {createnum=1,allnum=34},
	[78] = {createnum=0,allnum=34},
	[79] = {createnum=1,allnum=35},
	[80] = {createnum=0,allnum=35},
	[81] = {createnum=1,allnum=36},
	[82] = {createnum=0,allnum=36},
	[83] = {createnum=1,allnum=37},
	[84] = {createnum=0,allnum=37},
	[85] = {createnum=2,allnum=39},
	[86] = {createnum=0,allnum=39},
	[87] = {createnum=0,allnum=39},
	[88] = {createnum=0,allnum=39},
	[89] = {createnum=1,allnum=40},
	[90] = {createnum=0,allnum=40},
	[91] = {createnum=1,allnum=41},
	[92] = {createnum=0,allnum=41},
	[93] = {createnum=1,allnum=42},
	[94] = {createnum=0,allnum=42},
	[95] = {createnum=1,allnum=43},
	[96] = {createnum=0,allnum=43},
	[97] = {createnum=2,allnum=45},
	[98] = {createnum=0,allnum=45},
	[99] = {createnum=1,allnum=46},
	[100] = {createnum=0,allnum=46},
	[101] = {createnum=2,allnum=48},
	[102] = {createnum=0,allnum=48},
	[103] = {createnum=1,allnum=49},
	[104] = {createnum=0,allnum=49},
	[105] = {createnum=2,allnum=51},
	[106] = {createnum=0,allnum=51},
	[107] = {createnum=1,allnum=52},
	[108] = {createnum=0,allnum=52},
	[109] = {createnum=2,allnum=54},
	[110] = {createnum=0,allnum=54},
	[111] = {createnum=1,allnum=55},
	[112] = {createnum=0,allnum=55},
	[113] = {createnum=2,allnum=57},
	[114] = {createnum=0,allnum=57},
	[115] = {createnum=1,allnum=58},
	[116] = {createnum=0,allnum=58},
	[117] = {createnum=2,allnum=60},
	[118] = {createnum=0,allnum=60},
	[119] = {createnum=2,allnum=62},
	[120] = {createnum=0,allnum=62},

}

local g_Rate ={

	[0] = 0,
	[1] = 0.0003571,
	[2] = 0.0004099,
	[3] = 0.0004693,
	[4] = 0.0005362,
	[5] = 0.0006112,
	[6] = 0.0006952,
	[7] = 0.0007889,
	[8] = 0.0008932,
	[9] = 0.0010091,
	[10] = 0.0011375,
	[11] = 0.0012794,
	[12] = 0.0014358,
	[13] = 0.0016078,
	[14] = 0.0017965,
	[15] = 0.002003,
	[16] = 0.0022283,
	[17] = 0.0024736,
	[18] = 0.00274,
	[19] = 0.0030285,
	[20] = 0.0033404,
	[21] = 0.0036765,
	[22] = 0.0040378,
	[23] = 0.0044254,
	[24] = 0.00484,
	[25] = 0.0052825,
	[26] = 0.0057535,
	[27] = 0.0062536,
	[28] = 0.0067833,
	[29] = 0.007343,
	[30] = 0.0079328,
	[31] = 0.0085528,
	[32] = 0.009203,
	[33] = 0.0098831,
	[34] = 0.0105928,
	[35] = 0.0113314,
	[36] = 0.0120982,
	[37] = 0.0128923,
	[38] = 0.0137127,
	[39] = 0.014558,
	[40] = 0.0154269,
	[41] = 0.0163178,
	[42] = 0.0172289,
	[43] = 0.0181585,
	[44] = 0.0191044,
	[45] = 0.0200647,
	[46] = 0.021037,
	[47] = 0.0220191,
	[48] = 0.0230086,
	[49] = 0.0240031,
	[50] = 0.025,
	[51] = 0.0259969,
	[52] = 0.0269914,
	[53] = 0.0279809,
	[54] = 0.028963,
	[55] = 0.0299353,
	[56] = 0.0308956,
	[57] = 0.0318415,
	[58] = 0.0327711,
	[59] = 0.0336822,
	[60] = 0.0345731,
	[61] = 0.035442,
	[62] = 0.0362873,
	[63] = 0.0371077,
	[64] = 0.0379018,
	[65] = 0.0386686,
	[66] = 0.0394072,
	[67] = 0.0401169,
	[68] = 0.040797,
	[69] = 0.0414472,
	[70] = 0.0420672,
	[71] = 0.042657,
	[72] = 0.0432167,
	[73] = 0.0437464,
	[74] = 0.0442465,
	[75] = 0.0447175,
	[76] = 0.04516,
	[77] = 0.0455746,
	[78] = 0.0459622,
	[79] = 0.0463235,
	[80] = 0.0466596,
	[81] = 0.0469715,
	[82] = 0.04726,
	[83] = 0.0475264,
	[84] = 0.0477717,
	[85] = 0.047997,
	[86] = 0.0482035,
	[87] = 0.0483922,
	[88] = 0.0485642,
	[89] = 0.0487206,
	[90] = 0.0488625,
	[91] = 0.0489909,
	[92] = 0.0491068,
	[93] = 0.0492111,
	[94] = 0.0493048,
	[95] = 0.0493888,
	[96] = 0.0494638,
	[97] = 0.0495307,
	[98] = 0.0495901,
	[99] = 0.0496429,
	[100] = 0.0496895,
	
}
local g_ZhengTai = {

	[0] = 0,
	[1] = 0.0513841,
	[2] = 0.0571741,
	[3] = 0.0634656,
	[4] = 0.0702833,
	[5] = 0.0776507,
	[6] = 0.0855902,
	[7] = 0.0941224,
	[8] = 0.1032662,
	[9] = 0.1130385,
	[10] = 0.1234535,
	[11] = 0.1345228,
	[12] = 0.1462549,
	[13] = 0.1586553,
	[14] = 0.1717255,
	[15] = 0.1854639,
	[16] = 0.1998645,
	[17] = 0.2149176,
	[18] = 0.2306092,
	[19] = 0.2469211,
	[20] = 0.263831,
	[21] = 0.2813123,
	[22] = 0.2993344,
	[23] = 0.3178626,
	[24] = 0.3368583,
	[25] = 0.3562797,
	[26] = 0.3760812,
	[27] = 0.3962144,
	[28] = 0.4166285,
	[29] = 0.4372699,
	[30] = 0.4580835,
	[31] = 0.4790127,
	[32] = 0.5,
	[33] = 0.5209873,
	[34] = 0.5419165,
	[35] = 0.5627301,
	[36] = 0.5833715,
	[37] = 0.6037856,
	[38] = 0.6239188,
	[39] = 0.6437203,
	[40] = 0.6631417,
	[41] = 0.6821374,
	[42] = 0.7006656,
	[43] = 0.7186877,
	[44] = 0.736169,
	[45] = 0.7530789,
	[46] = 0.7693908,
	[47] = 0.7850824,
	[48] = 0.8001355,
	[49] = 0.8145361,
	[50] = 0.8282745,
	[51] = 0.8413447,
	[52] = 0.8537451,
	[53] = 0.8654772,
	[54] = 0.8765465,
	[55] = 0.8869615,
	[56] = 0.8967338,
	[57] = 0.9058776,
	[58] = 0.9144098,
	[59] = 0.9223493,
	[60] = 0.9297167,
	[61] = 0.9365344,
	[62] = 0.9428259,
	[63] = 0.9486159,

}

-- 连击的美术字
local g_Image = {

	[0] = "set:Shoot4  image:BigNum0",
	[1] = "set:Shoot4  image:BigNum1",
	[2] = "set:Shoot4  image:BigNum2",
	[3] = "set:Shoot4  image:BigNum3",
	[4] = "set:Shoot4  image:BigNum4",
	[5] = "set:Shoot4  image:BigNum5",
	[6] = "set:Shoot4  image:BigNum6",
	[7] = "set:Shoot4  image:BigNum7",
	[8] = "set:Shoot4  image:BigNum8",
	[9] = "set:Shoot4  image:BigNum9",
	
}

-- 倒计时的美术字
local g_Image1 = {

	[0] = "set:Shoot4  image:num0",
	[1] = "set:Shoot4  image:num1",
	[2] = "set:Shoot4  image:num2",
	[3] = "set:Shoot4  image:num3",
	[4] = "set:Shoot4  image:num4",
	[5] = "set:Shoot4  image:num5",
	[6] = "set:Shoot4  image:num6",
	[7] = "set:Shoot4  image:num7",
	[8] = "set:Shoot4  image:num8",
	[9] = "set:Shoot4  image:num9",
	
}

-- 结果图片
local g_ImageRes = {

	[1] = "set:Shoot4  image:result1",
	[2] = "set:Shoot4  image:result2",
	[3] = "set:Shoot4  image:result3",
	[4] = "set:Shoot4  image:result4",
	[5] = "set:Shoot4  image:result5",
	[6] = "set:Shoot4  image:result6",
	
	
}

-- 特效
local g_Anim = {

	[1] = "Shoot_ZhengZhongBaXin",
	[2] = "Shoot_YanJiShouKuai",
	[3] = "Shoot_QianJunYiFa",
	[4] = "Shoot_BaiFaBaiZhong",
	
}

local g_TargetAnim = {}
local g_GameTimer = -1

local g_MaxShoot = 62
-- 点击的次数
local g_NowCount = 0

-- 击中靶心的次数
local g_NowHitCount = 0

-- 出现的靶子数量
local g_ShootCount = 0

-- 单次游戏最大射击次数
local g_MaxShootTime = 10000

local g_GameTime = 136

local g_ObjCaredID = -1

local g_Combo = 0
-- 是否射中了圆心
local g_IsHitCore = 0

local g_WrongTime = 0
local g_CDTime = 0
local g_RSCDTime = 0

function YuanXiao_Shoot_PreLoad()

	this:RegisterEvent("UI_COMMAND", true);
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function YuanXiao_Shoot_OnLoad()

	g_Target[1] = YuanXiao_Shoot_Client2_Target1Btn;
	g_Target[2] = YuanXiao_Shoot_Client2_Target2Btn;
	g_Target[3] = YuanXiao_Shoot_Client2_Target3Btn;
	g_Target[4] = YuanXiao_Shoot_Client2_Target4Btn;
	g_Target[5] = YuanXiao_Shoot_Client2_Target5Btn;
	g_Target[6] = YuanXiao_Shoot_Client2_Target6Btn;
	g_Target[7] = YuanXiao_Shoot_Client2_Target7Btn;
	g_Target[8] = YuanXiao_Shoot_Client2_Target8Btn;
	g_Target[9] = YuanXiao_Shoot_Client2_Target9Btn;
	g_Target[10] = YuanXiao_Shoot_Client2_Target10Btn;
	g_Target[11] = YuanXiao_Shoot_Client2_Target11Btn;
	g_Target[12] = YuanXiao_Shoot_Client2_Target12Btn;
	g_Target[13] = YuanXiao_Shoot_Client2_Target13Btn;
	g_Target[14] = YuanXiao_Shoot_Client2_Target14Btn;
	g_Target[15] = YuanXiao_Shoot_Client2_Target15Btn;
	g_Target[16] = YuanXiao_Shoot_Client2_Target16Btn;
	g_Target[17] = YuanXiao_Shoot_Client2_Target17Btn;
	g_Target[18] = YuanXiao_Shoot_Client2_Target18Btn;
	
	g_TargetAnim[1] = YuanXiao_Shoot_Client2_Target1Animate;
	g_TargetAnim[2] = YuanXiao_Shoot_Client2_Target2Animate;
	g_TargetAnim[3] = YuanXiao_Shoot_Client2_Target3Animate;
	g_TargetAnim[4] = YuanXiao_Shoot_Client2_Target4Animate;
	g_TargetAnim[5] = YuanXiao_Shoot_Client2_Target5Animate;
	g_TargetAnim[6] = YuanXiao_Shoot_Client2_Target6Animate;
	g_TargetAnim[7] = YuanXiao_Shoot_Client2_Target7Animate;
	g_TargetAnim[8] = YuanXiao_Shoot_Client2_Target8Animate;
	g_TargetAnim[9] = YuanXiao_Shoot_Client2_Target9Animate;
	g_TargetAnim[10] = YuanXiao_Shoot_Client2_Target10Animate;
	g_TargetAnim[11] = YuanXiao_Shoot_Client2_Target11Animate;
	g_TargetAnim[12] = YuanXiao_Shoot_Client2_Target12Animate;
	g_TargetAnim[13] = YuanXiao_Shoot_Client2_Target13Animate;
	g_TargetAnim[14] = YuanXiao_Shoot_Client2_Target14Animate;
	g_TargetAnim[15] = YuanXiao_Shoot_Client2_Target15Animate;
	g_TargetAnim[16] = YuanXiao_Shoot_Client2_Target16Animate;
	g_TargetAnim[17] = YuanXiao_Shoot_Client2_Target17Animate;
	g_TargetAnim[18] = YuanXiao_Shoot_Client2_Target18Animate;
	
	g_TargetAnim2[1] = YuanXiao_Shoot_Client2_Target1Animate2;
	g_TargetAnim2[2] = YuanXiao_Shoot_Client2_Target2Animate2;
	g_TargetAnim2[3] = YuanXiao_Shoot_Client2_Target3Animate2;
	g_TargetAnim2[4] = YuanXiao_Shoot_Client2_Target4Animate2;
	g_TargetAnim2[5] = YuanXiao_Shoot_Client2_Target5Animate2;
	g_TargetAnim2[6] = YuanXiao_Shoot_Client2_Target6Animate2;
	g_TargetAnim2[7] = YuanXiao_Shoot_Client2_Target7Animate2;
	g_TargetAnim2[8] = YuanXiao_Shoot_Client2_Target8Animate2;
	g_TargetAnim2[9] = YuanXiao_Shoot_Client2_Target9Animate2;
	g_TargetAnim2[10] = YuanXiao_Shoot_Client2_Target10Animate2;
	g_TargetAnim2[11] = YuanXiao_Shoot_Client2_Target11Animate2;
	g_TargetAnim2[12] = YuanXiao_Shoot_Client2_Target12Animate2;
	g_TargetAnim2[13] = YuanXiao_Shoot_Client2_Target13Animate2;
	g_TargetAnim2[14] = YuanXiao_Shoot_Client2_Target14Animate2;
	g_TargetAnim2[15] = YuanXiao_Shoot_Client2_Target15Animate2;
	g_TargetAnim2[16] = YuanXiao_Shoot_Client2_Target16Animate2;
	g_TargetAnim2[17] = YuanXiao_Shoot_Client2_Target17Animate2;
	g_TargetAnim2[18] = YuanXiao_Shoot_Client2_Target18Animate2;
	
	YuanXiao_Shoot_Client1:Hide()
	YuanXiao_Shoot_Client2:Hide()
	YuanXiao_Shoot_Client3:Hide()
	
	g_YuanXiao_Shoot_Frame_UnifiedPosition=YuanXiao_Shoot:GetProperty("UnifiedPosition")
	
end


function YuanXiao_Shoot_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 89302201 then
		
		local nMonsterId = Get_XParam_INT(1)
		if nMonsterId == nil then
			return 
		end
		local g_ObjCaredID = DataPool : GetNPCIDByServerID(nMonsterId);
		if g_ObjCaredID ~= -1 then
			this:CareObject(g_ObjCaredID, 1, "YuanXiaoShoot");
		end
		
		-- 得到历史最高分
		--local score = Get_XParam_INT(0)
		local nLastBestTime = Get_XParam_INT(0)
		if nLastBestTime == nil then
			return 
		end
		YuanXiao_Shoot_Client_Text:SetText(ScriptGlobal_Format("#{YXSJ_181204_32}",nLastBestTime))
		YuanXiao_Shoot_Client1:Show()
		YuanXiao_Shoot_Close2:Hide()
		
		for i = 1,18 do
			g_TargetAnim[i]:Play(false)
			g_TargetAnim2[i]:Play(false)
		end
		
		this:Show()
		
	elseif  event == "UI_COMMAND" and tonumber(arg0) == 89302202 then
		
		YuanXiao_Shoot_Start()
		
	elseif  event == "UI_COMMAND" and tonumber(arg0) == 89302203 then
		
		AutoRunToTargetEx(299,350,0)
		SetAutoRunTargetNPCName( "洛神箭" )
	-- elseif  event == "UI_COMMAND" and tonumber(arg0) == 89302204 then
		
		-- local nLastBestTime = Get_XParam_INT(0)
		-- if nLastBestTime == nil then
			-- return 
		-- end
		-- local isHitAll = Get_XParam_INT(1)
		-- if isHitAll == nil then
			-- return 
		-- end
		-- YuanXiao_Shoot_Client_Text:SetText(ScriptGlobal_Format("#{YXSJ_181204_32}",nLastBestTime))
		
		-- YuanXiao_Shoot_Client3_TextBK1:Hide()
		-- YuanXiao_Shoot_Client3_TextBK2:Show()
		-- YuanXiao_Shoot_Client3_Text4:SetText(ScriptGlobal_Format("#{YXSJ_181204_43}",g_YuanXiao))
		-- if isHitAll == 1 then
			-- YuanXiao_Shoot_Client3_Text5:SetText("#{YXSJ_181204_44}")
		-- else
			-- YuanXiao_Shoot_Client3_Text5:SetText("")
		-- end
		
	-- elseif  event == "UI_COMMAND" and tonumber(arg0) == 89302205 then
		
		-- YuanXiao_Shoot_Client3_TextBK1:Hide()
		-- YuanXiao_Shoot_Client3_TextBK2:Show()
		-- YuanXiao_Shoot_Client3_Text4:SetText("#{YXSJ_181204_45}")
	elseif (event == "ADJEST_UI_POS" ) then
		YuanXiao_Shoot_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		YuanXiao_Shoot_On_ResetPos()
	end
	
	
	
end



function YuanXiao_Shoot_Start_Click()
	
	--点错了惩罚0.2秒
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_CDTime < 2000) then
   		return;
   	end
	g_CDTime = curTime
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("StartCheck");
		Set_XSCRIPT_ScriptID(893021);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();

end

function YuanXiao_Shoot_Clear()

	YuanXiao_Shoot_Client1:Hide()
	YuanXiao_Shoot_Client3:Hide()
	YuanXiao_Shoot_Client2:Hide()
	for i = 1,18 do
		g_Target[i]:Hide()
		g_TargetTime[i] = 0
		g_TargetIsClick[i] = 0
		g_TargetAnim[i]:Play(false)
		g_TargetAnim2[i]:Play(false)
	end
	g_NowHitCount = 0
	g_GameTimer = g_GameTime
	g_NowCount = 0
	g_ShootCount = 0
	g_Combo = 0
	g_IsHitCore = 0
	--YuanXiao_Shoot_Client2_Text2:SetText("")
	--YuanXiao_Shoot_Client2_Text3:SetText("")
	--YuanXiao_Shoot_Client2_Text4:SetText("")
	YuanXiao_Shoot_ComboPic2:Hide()
	--YuanXiao_Shoot_Client2_Text5:SetText("")
	YuanXiao_Shoot_Client3_TextBK:SetText("")
	YuanXiao_Shoot_Client_Text:SetText("")
	
end


function YuanXiao_Shoot_Start()

	-- 把鼠标设置为射箭
	Archer()
	
	YuanXiao_Shoot_Close2:Show()
	YuanXiao_Shoot_Client1:Hide()
	YuanXiao_Shoot_Client3:Hide()
	YuanXiao_Shoot_Client2:Show()
	YuanXiao_Shoot_ComboPic2:Hide()
	YuanXiao_Shoot_ComboClient:Hide()
	for i = 1,18 do
		g_Target[i]:Hide()
		g_TargetTime[i] = 0
		g_TargetIsClick[i] = 0
		g_TargetAnim[i]:Play(false)
		g_TargetAnim2[i]:Play(false)
	end
	YuanXiao_Shoot_TitlePic:Play(false)
	g_NowHitCount = 0
	g_GameTimer = g_GameTime
	g_NowCount = 0
	g_ShootCount = 0
	g_Combo = 0
	g_IsHitCore = 0
	
	-- 设置倒计时
	YuanXiao_Shoot_Time2:Hide()
	YuanXiao_Shoot_Time1:SetProperty("Image", g_Image1[0])		
	-- 设置击中靶的数量
	YuanXiao_Shoot_Hit2:Hide()
	YuanXiao_Shoot_Hit1:SetProperty("Image", g_Image1[0])
	
	SetTimer("YuanXiao_Shoot","YuanXiao_Shoot_Game_Timer()", 250)
	
end

-- 小游戏逻辑 通过设置一个60秒的定时器来控制靶的刷出
function YuanXiao_Shoot_Game_Timer()

	g_GameTimer = g_GameTimer - 1
	
	-- 设置倒计时
	local nNowTime = math.ceil(g_GameTimer/4)
	local high = math.floor(nNowTime/10)
	local low = nNowTime - high*10
	if high == 0 then
		YuanXiao_Shoot_Time2:Hide()
	elseif 0 < high and high <= 9 then
		YuanXiao_Shoot_Time2:Show()
		YuanXiao_Shoot_Time2:SetProperty("Image", g_Image1[high])
	end
	
	if 0 <= low and low <= 9 then
		YuanXiao_Shoot_Time1:Show()
		YuanXiao_Shoot_Time1:SetProperty("Image", g_Image1[low])
	end
	-- local text = ScriptGlobal_Format("#{YXSJ_181204_10}",math.ceil(g_GameTimer/2))
	-- YuanXiao_Shoot_Client2_Text5:SetText(text)
	
	local nLeaveNum = 0
	if g_GameTimer < 0 then
		KillTimer("YuanXiao_Shoot_Game_Timer()")
		-- 结束的时候把所有都关掉,把数据清零
		for i = 1,18 do
			g_Target[i]:Hide()
			g_TargetTime[i] = 0
			g_TargetIsClick[i] = 0
			g_TargetAnim[i]:Play(false)
			g_TargetAnim2[i]:Play(false)
		end
		YuanXiao_Shoot_Client1:Hide()
		YuanXiao_Shoot_Client2:Hide()
		YuanXiao_Shoot_Client3:Show()
		YuanXiao_Shoot_Close2:Hide()
		-- 设置评价
		local nHitRate = 0
		if g_NowCount ~= 0 then
			nHitRate = math.ceil((g_NowHitCount/g_NowCount)*100)
		end
		local nRank = g_ZhengTai[g_NowHitCount] + g_Rate[nHitRate]
		nRank = math.floor(nRank*100)
		-- 得到当天的分数
		local misData1 = DataPool:GetPlayerMission_DataRound(3353)
		local clickcount = math.floor(misData1 / 100)
		local score = misData1 - clickcount*100
		-- 判断今天进没进行游戏
		local misData = DataPool:GetPlayerMission_DataRound(3352)
		local lastDay = math.floor(misData / 100)
		local curDay = DataPool:DateTime2DayTime(tonumber(DataPool:GetServerDayTime()))
		
		local scorelevel = 0 
		--local nYuanXiaoNum = 0
		--local nXunZhangNum = 0
		local text3 = ""
		if g_NowHitCount >= score then
			scorelevel = 1
		elseif g_NowHitCount < score then
			if 2 <= score and score <= 9 then
				--nYuanXiaoNum = 1
				text3 = ScriptGlobal_Format("#{YXSJ_181204_72}",1)
			elseif 10 <= score and score <= 19 then
				--nYuanXiaoNum = 2
				text3 = ScriptGlobal_Format("#{YXSJ_181204_72}",2)
			elseif 20 <= score and score <= 39 then
				--nYuanXiaoNum = 4
				text3 = ScriptGlobal_Format("#{YXSJ_181204_72}",4)
			elseif 40 <= score and score <= 59 then
				--nYuanXiaoNum = 6
				text3 = ScriptGlobal_Format("#{YXSJ_181204_72}",6)
			elseif 60 <= score and score <= 62 then
				--nYuanXiaoNum = 6
				--nXunZhangNum = 1
				text3 = ScriptGlobal_Format("#{YXSJ_181204_73}",6)
			else
				text3 = "#{YXSJ_181204_71}"
			end
		end
		local text = ScriptGlobal_Format("#{YXSJ_181204_68}",g_NowHitCount)
		YuanXiao_Shoot_Client3_Text1:SetText(text)
		local text2 = ScriptGlobal_Format("#{YXSJ_181204_69}",nRank)
		YuanXiao_Shoot_Client3_Text2:SetText(text2)
		if curDay ~= lastDay then
			if scorelevel == 1 then
				if g_NowHitCount >= 2 then
					if 2 <= g_NowHitCount and g_NowHitCount <= 9 then
						YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[5])
						YuanXiao_Shoot_Client3_Text3:SetText("#{YXSJ_181204_70}"..ScriptGlobal_Format("#{YXSJ_181204_72}",1))
						
					elseif 10 <= g_NowHitCount and g_NowHitCount <= 19 then
						YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[4])
						YuanXiao_Shoot_Client3_Text3:SetText("#{YXSJ_181204_70}"..ScriptGlobal_Format("#{YXSJ_181204_72}",2))
						
					elseif 20 <= g_NowHitCount and g_NowHitCount <= 39 then
						YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[3])
						YuanXiao_Shoot_Client3_Text3:SetText("#{YXSJ_181204_70}"..ScriptGlobal_Format("#{YXSJ_181204_72}",4))
						
					elseif 40 <= g_NowHitCount and g_NowHitCount <= 59 then
						YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[2])
						YuanXiao_Shoot_Client3_Text3:SetText("#{YXSJ_181204_70}"..ScriptGlobal_Format("#{YXSJ_181204_72}",6))
						
					elseif 60 <= g_NowHitCount and g_NowHitCount <= 62 then
						YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[1])
						YuanXiao_Shoot_Client3_Text3:SetText("#{YXSJ_181204_70}"..ScriptGlobal_Format("#{YXSJ_181204_73}",6))
						
					end
				
				else
					YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[6])
					YuanXiao_Shoot_Client3_Text3:SetText("#{YXSJ_181204_70}".."#{YXSJ_181204_71}")
				end
			else
				if g_NowHitCount >= 2 then
					if 2 <= g_NowHitCount and g_NowHitCount <= 9 then
						YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[5])
					elseif 10 <= g_NowHitCount and g_NowHitCount <= 19 then
						YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[4])
					elseif 20 <= g_NowHitCount and g_NowHitCount <= 39 then
						YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[3])
					elseif 40 <= g_NowHitCount and g_NowHitCount <= 59 then
						YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[2])
					elseif 60 <= g_NowHitCount and g_NowHitCount <= 62 then
						YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[1])
					end	
				else
					YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[6])
				end
				YuanXiao_Shoot_Client3_Text3:SetText("#{YXSJ_181204_70}"..text3)
			end
		else
			if g_NowHitCount >= 2 then
				if 2 <= g_NowHitCount and g_NowHitCount <= 9 then
					YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[5])
				elseif 10 <= g_NowHitCount and g_NowHitCount <= 19 then
					YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[4])
				elseif 20 <= g_NowHitCount and g_NowHitCount <= 39 then
					YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[3])
				elseif 40 <= g_NowHitCount and g_NowHitCount <= 59 then
					YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[2])
				elseif 60 <= g_NowHitCount and g_NowHitCount <= 62 then
					YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[1])
				end	
			else
				YuanXiao_Shoot_Client3_TextResult:SetProperty("Image", g_ImageRes[6])
			end
			YuanXiao_Shoot_Client3_Text3:SetText("#{YXSJ_181204_74}")
		end
		
		-- 设置分数
		if g_NowHitCount <= g_MaxShoot then
			YuanXiao_Shoot_SetScore()
		end
		--g_NowHitCount = 0
		--g_NowCount = 0
		g_ShootCount = 0
		g_Combo = 0
		g_IsHitCore = 0
		-- 把鼠标变成普通的
		SetDefaultMouse()
		return 
	end
	
	for i = 1,18 do
		if g_TargetTime[i] > 0 and g_TargetTime[i] <= 16 then
		
			g_TargetTime[i] = g_TargetTime[i] - 1
			--把需要自消亡的干掉
			if g_TargetTime[i] == 0 then
				g_Target[i]:Hide()
				g_TargetIsClick[i] = 0
				g_TargetAnim2[i]:Play(false)
			end
			--剩余1秒的时候需要一个闪烁特效
			if g_TargetTime[i] == 4 then
				g_TargetAnim2[i]:Play(true)
			end
		end
		if g_TargetTime[i] == 0 then
			nLeaveNum = nLeaveNum + 1
		end
	end
	
	if g_GameTimer < 16 then
		return
	end
	
	-- 在每个tick的时候，分为三种情况,
	-- 1.能把当时需要生成的都能刷出来
	-- 2.只能刷出来一部分
	-- 3.全都刷不出来
	if g_TargetTick[g_GameTime - g_GameTimer].createnum <= nLeaveNum then
	
		for i=0,g_TargetTick[g_GameTime - g_GameTimer].createnum - 1 do
			local nSeat = YuanXiao_Shoot_Random()
			g_TargetTime[nSeat] = 16
			g_Target[nSeat]:Show()
		end
	elseif nLeaveNum == 0 then
	
		for i=0,g_TargetTick[g_GameTime - g_GameTimer].createnum - 1 do 
		
			local nMinTarget = g_TargetTime[1]
			local nMin = 1
			for j = 2,18 do
				if nMinTarget < g_TargetTime[j] then
					nMinTarget = g_TargetTime[j]
					nMin = j
				end
			end
			g_TargetTime[nMin] = 16
		end
	elseif  g_TargetTick[g_GameTime - g_GameTimer].createnum > nLeaveNum and nLeaveNum ~= 0 then
		
		for i=0,nLeaveNum-1 do
			local nSeat = YuanXiao_Shoot_Random()
			g_TargetTime[nSeat] = 16
			g_Target[nSeat]:Show()
		end
		for i=0,g_TargetTick[g_GameTime - g_GameTimer].createnum - 1 - nLeaveNum do 
		
			local nMinTarget = g_TargetTime[1]
			local nMin = 1
			for j = 2,18 do
				if nMinTarget < g_TargetTime[j] and g_TargetIsClick[index] ~= 1 then
					nMinTarget = g_TargetTime[j]
					nMin = j
				end
			end
			g_TargetTime[nMin] = 16
			g_TargetAnim2[nMin]:Play(false)
		end
	end
	
	-- 统计刷的靶子数量
	g_ShootCount = g_ShootCount +  g_TargetTick[g_GameTime - g_GameTimer].createnum 
	-- local text = ScriptGlobal_Format("#{YXSJ_181204_11}",g_ShootCount)
	-- YuanXiao_Shoot_Client2_Text2:SetText(text)
	
end

function YuanXiao_Shoot_Random()

	local nRandomShootBox = {}
	local nRandomLeaveNum = 0
	for i = 1,18 do
	
		if g_TargetTime[i] == 0 and g_TargetIsClick[index] ~= 1 then
			nRandomShootBox[nRandomLeaveNum] = i
			nRandomLeaveNum = nRandomLeaveNum + 1
		end
		
	end
	
	return nRandomShootBox[math.random(0,nRandomLeaveNum-1)]
	
end

-- 判断是否射在了button的靶圈里，咱们的button都是方的，
-- 结果非要在里面画个圈，让我判断玩家点没点圈里，透你妹
function YuanXiao_Shoot_IsShoot(index)

	local MouseX,MouseY = GetMousePos()
	
	local PacketUnionXPos=YuanXiao_Shoot:GetProperty("UnifiedXPosition")
	local PacketUnionYPos=YuanXiao_Shoot:GetProperty("UnifiedYPosition")
	
	if(PacketUnionXPos == nil or PacketUnionYPos ==nil) then
		return
	end
	
	local xi = string.find(PacketUnionXPos,"{")
	local xj = string.find(PacketUnionXPos,",")
	local xk = string.find(PacketUnionXPos,"}")
	local yi = string.find(PacketUnionYPos,"{")
	local yj = string.find(PacketUnionYPos,",")
	local yk = string.find(PacketUnionYPos,"}")
	if xi==nil or xj==nil or xk==nil or yi==nil or yj==nil or yk==nil then return	end;

	local xscale = string.sub(PacketUnionXPos,xi+1,xj-1)
	local xpos = string.sub(PacketUnionXPos,xj+1,xk-1)
	local yscale = string.sub(PacketUnionYPos,yi+1,yj-1)
	local ypos = string.sub(PacketUnionYPos,yj+1,yk-1)
	if xscale==nil or xpos==nil or yscale==nil or ypos==nil then return end;
	
	local xmax, ymax = GetCurClientSize()
	local PacketXPos=xscale*xmax + xpos	--绝对坐标
	local PacketYPos=yscale*ymax + ypos	--绝对坐
	
	local ButttonXPos = PacketXPos + g_TargetPos[index].x + g_TargetPos[index].r
	local ButttonYPos = PacketYPos + g_TargetPos[index].y + g_TargetPos[index].r
	
	--PushDebugMessage(MouseX..","..MouseY)
	--PushDebugMessage(PacketXPos..","..PacketYPos)
	--local dis = (ButttonXPos - MouseX) * (ButttonXPos - MouseX) + (ButttonYPos - MouseY) * (ButttonYPos - MouseY)
	--PushDebugMessage(dis)
	-- 计算是否射中了圆心
	if (ButttonXPos - MouseX) * (ButttonXPos - MouseX) + (ButttonYPos - MouseY) * (ButttonYPos - MouseY) <= g_TargetPos[index].z * g_TargetPos[index].z then 
		g_IsHitCore = 1
	end
	
	if (ButttonXPos - MouseX) * (ButttonXPos - MouseX) + (ButttonYPos - MouseY) * (ButttonYPos - MouseY) <= g_TargetPos[index].r * g_TargetPos[index].r then 
		return 1
	else
		return 0
	end
	
end


---------------------------------------------------------------
----18个靶的点击函数-------------------------------------------
---------------------------------------------------------------

function YuanXiao_Shoot_Click(index)

	if g_NowCount > g_MaxShootTime then
		return
	end
	
	if g_TargetIsClick[index] == 1 then
		return
	end
	
	--点错了惩罚0.2秒
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_WrongTime < 200) then
   		return;
   	end
	
	local isShoot = YuanXiao_Shoot_IsShoot(index)
	g_NowCount = g_NowCount + 1
	if isShoot == 1 then
		local nLeaveTime = g_TargetTime[index] 
		g_NowHitCount = g_NowHitCount + 1
		g_TargetIsClick[index] = 1
		--g_Target[index]:Hide()
		g_TargetTime[index] = 3
		g_TargetAnim[index]:Play(true)
		g_TargetAnim2[index]:Play(false)
		
		if g_Combo == 0 then
			YuanXiao_Shoot_ComboPic2:Hide()
		end
		-- 设置连击数
		g_Combo = g_Combo + 1
		if g_Combo > 1 then
			YuanXiao_Shoot_ComboClient:Show()
			local high = math.floor(g_Combo/10)
			local low = g_Combo - high*10
			if high == 0 then
				YuanXiao_Shoot_Combo1:Hide()
			elseif 0 < high and high <= 9 then
				YuanXiao_Shoot_Combo1:Show()
				YuanXiao_Shoot_Combo1:SetProperty("Image", g_Image[high])
			end
			
			if 0 <= low and low <= 9 then
				YuanXiao_Shoot_Combo2:Show()
				YuanXiao_Shoot_Combo2:SetProperty("Image", g_Image[low])
			end
		elseif g_Combo == 1 then
			YuanXiao_Shoot_ComboClient:Hide()
		end
		
		local high1 = math.floor(g_NowHitCount/10)
		local low1 = g_NowHitCount - high1*10
		if high1 == 0 then
			YuanXiao_Shoot_Hit2:Hide()
		elseif 0 < high1 and high1 <= 9 then
			YuanXiao_Shoot_Hit2:Show()
			YuanXiao_Shoot_Hit2:SetProperty("Image", g_Image1[high1])
		end
		
		if 0 <= low1 and low1 <= 9 then
			YuanXiao_Shoot_Hit1:Show()
			YuanXiao_Shoot_Hit1:SetProperty("Image", g_Image1[low1])
		end
		
		local nTitle = 0
		-- 如果连击是5的倍数
		if (g_Combo - math.floor(g_Combo/5) * 5) == 0 then
			nTitle = 4
		end
		
		-- 前0.5秒点击到
		if nLeaveTime <= 16 and nLeaveTime >= 15 then
			nTitle = 2
		end
		
		-- 后0.5秒点到
		if nLeaveTime >= 1 and nLeaveTime <= 2 then
			nTitle = 3
		end
		
		-- 射中了圆心
		if g_IsHitCore == 1 then
			nTitle = 1
			g_IsHitCore = 0
		end
		
		--PushDebugMessage(nTitle)
		
		if 1 <= nTitle and nTitle <= 4 then
			YuanXiao_Shoot_TitlePic:Play(false)
			YuanXiao_Shoot_TitlePic:SetProperty("Animate",g_Anim[nTitle])
			YuanXiao_Shoot_TitlePic:Play(true)
		end
		-- 设置击中靶的数量
		--local text = ScriptGlobal_Format("#{YXSJ_181204_12}",g_NowHitCount)
		--YuanXiao_Shoot_Client2_Text3:SetText(text)
	end
	-- local text = ScriptGlobal_Format("#{YXSJ_181204_13}",g_NowCount)
	-- YuanXiao_Shoot_Client2_Text4:SetText(text)
end


-- 背景的空button被点击，用来统计点击次数
function YuanXiao_Shoot_BG_Click()

	if g_NowCount > g_MaxShootTime then
		return
	end
	
	--点错了惩罚0.2秒
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_WrongTime < 200) then
   		return;
   	end
	g_WrongTime = curTime
	
	g_Combo = 0
	YuanXiao_Shoot_ComboPic2:Show()
	g_NowCount = g_NowCount + 1
	-- local text = ScriptGlobal_Format("#{YXSJ_181204_13}",g_NowCount)
	-- YuanXiao_Shoot_Client2_Text4:SetText(text)
end

-- 重新开始
function YuanXiao_Shoot_Again_Click()

	--点错了惩罚0.2秒
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_RSCDTime < 2000) then
   		return;
   	end
	g_RSCDTime = curTime
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("StartCheck");
		Set_XSCRIPT_ScriptID(893021);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT()
	
end

-- 返回
-- function YuanXiao_Return_Click()
	
	-- YuanXiao_Shoot_Client1:Show()
	-- YuanXiao_Shoot_Client2:Hide()
	-- YuanXiao_Shoot_Client3:Hide()
	
-- end

-- 领取奖励
-- function YuanXiao_Get_Click()
	
	-- local curTime = OSAPI:GetTickCount();
	-- if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then
 	 	-- PushDebugMessage("#{JCXT_180323_37}"); --不可连续点击，请稍等片刻后再点击
   		-- return;
   	-- end
   	-- g_ButtonLastTime = curTime;
	
	-- if g_NowCount > g_MaxShootTime then
		-- return
	-- end
	-- if g_NowHitCount > g_MaxShoot then
		-- return
	-- end
	-- Clear_XSCRIPT();
		-- Set_XSCRIPT_Function_Name("GetAward");
		-- Set_XSCRIPT_ScriptID(893021);
		-- Set_XSCRIPT_Parameter(0,g_NowHitCount);
		-- Set_XSCRIPT_Parameter(1,g_NowCount);
		-- Set_XSCRIPT_Parameter(2,0);
		-- Set_XSCRIPT_ParamCount(2);
	-- Send_XSCRIPT();
-- end

function YuanXiao_Shoot_SetScore()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("SetScore");
		Set_XSCRIPT_ScriptID(893021);
		Set_XSCRIPT_Parameter(0,g_NowHitCount);
		Set_XSCRIPT_Parameter(1,g_NowCount);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end

function YuanXiao_Shoot_Close()

	YuanXiao_Shoot_Clear()
	this:CareObject(g_ObjCaredID, 0, "YuanXiaoShoot");
	this:Hide()

end

function YuanXiao_Shoot_Hidden()

	if g_GameTimer >= 0 then
		-- 结束的时候把所有都关掉,把数据清零
		for i = 1,18 do
			g_Target[i]:Hide()
			g_TargetTime[i] = 0
			g_TargetIsClick[i] = 0
			g_TargetAnim[i]:Play(false)
			g_TargetAnim2[i]:Play(false)
		end
		YuanXiao_Shoot_Client1:Hide()
		YuanXiao_Shoot_Client2:Hide()
		YuanXiao_Shoot_Client3:Hide()
		YuanXiao_Shoot_Close2:Hide()
		YuanXiao_Shoot_Client_Text:SetText("")
		this:CareObject(g_ObjCaredID, 0, "YuanXiaoShoot")
		g_ObjCaredID = -1
		this:Hide()
		
		g_Combo = 0
		g_IsHitCore = 0
		g_NowHitCount = 0
		g_NowCount = 0
		g_ShootCount = 0
		-- 把鼠标变成普通的
		SetDefaultMouse()
		KillTimer("YuanXiao_Shoot_Game_Timer()")
		return 
	end
	
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function YuanXiao_Shoot_On_ResetPos()
	
	YuanXiao_Shoot:SetProperty("UnifiedPosition", g_YuanXiao_Shoot_Frame_UnifiedPosition)
  
end