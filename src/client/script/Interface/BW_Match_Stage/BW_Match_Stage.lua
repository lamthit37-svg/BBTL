local g_BW_Match_Stage_Frame_UnifiedPosition;

local g_BW_Match_Stage_Star3 = {} --3颗星星
local g_BW_Match_Stage_Star4 = {} --4颗星星
--local g_BW_Match_Stage_Star2 = {} --2颗星星
local g_BW_Match_Stage_Star6 = {} --6颗星星
local g_BW_Match_Stage_Star8 = {} --8颗星星
local g_BW_Match_Stage_Star5 = {} --5颗星星

local g_BW_Match_Stage_Award_DW2_Button = {} --段位奖励按钮
local g_BW_Match_Stage_Award_DW2_ButtonText = {} --段位奖励按钮
local g_BW_Match_Stage_Award_DW2_Tips = {} --段位奖励按钮
local g_BW_Match_Stage_Award_Item_Button = {} --段位奖励按钮
local g_BW_Match_Stage_Award_Item_ButtonEx = {} --段位奖励按钮

local g_Duanwei1_Image = {

	[0] = {
		[1] = "set:BW_Match20 image:BW_que1",
		[2] = "set:BW_Match20 image:BW_que2",
		[3] = "set:BW_Match20 image:BW_que3",
		[4] = "set:BW_Match20 image:BW_que4",
		[5] = "set:BW_Match20 image:BW_que5",
		--[6] = "set:BW_Match20 image:BW_que6",
		[6] = "set:BW_Match20 image:BW_que7",
	},

	[1] = {
		[1] = "set:BW_Match5 image:Match_Eagle1",
		[2] = "set:BW_Match5 image:Match_Eagle2",
		[3] = "set:BW_Match4 image:Match_Eagle3",
		[4] = "set:BW_Match4 image:Match_Eagle4",
		[5] = "set:BW_Match4 image:Match_Eagle5",
	--	[6] = "set:BW_Match4 image:Match_Eagle6",
		[6] = "set:BW_Match3 image:Match_Eagle7",
	},

	[2] = {
		[1] = "set:BW_Match7 image:Match_Dragon1",
		[2] = "set:BW_Match6 image:Match_Dragon2",
		[3] = "set:BW_Match6 image:Match_Dragon3",
		[4] = "set:BW_Match6 image:Match_Dragon4",
		[5] = "set:BW_Match6 image:Match_Dragon5",
	--	[6] = "set:BW_Match5 image:Match_Dragon6",
		[6] = "set:BW_Match5 image:Match_Dragon7",
	},
	
	[3] = {
		[1] = "set:BW_Match21 image:BW_Kun1",
		[2] = "set:BW_Match21 image:BW_Kun2",
		[3] = "set:BW_Match21 image:BW_Kun3",
		[4] = "set:BW_Match21 image:BW_Kun4",
		[5] = "set:BW_Match21 image:BW_Kun5",
	--	[6] = "set:BW_Match21 image:BW_Kun6",
		[6] = "set:BW_Match21 image:BW_Kun7",
	},
}

local g_Duanwei1_name = {
	[1] = "#{BWDH_180804_131}",
	[2] = "#{BWDH_180804_132}",
	[3] = "#{BWDH_180804_133}",
	[4] = "#{BWDH_180804_134}",
	[5] = "#{BWDH_180804_135}",
	[6] = "#{BWDH_180804_136}",
}

local g_Duanwei2_Info = {
	[1] = {image="set:BW_Match1 image:Number1", name="#{BWDH_180804_153}"},
	[2] = {image="set:BW_Match1 image:Number2", name="#{BWDH_180804_152}"},
	[3] = {image="set:BW_Match1 image:Number3", name="#{BWDH_180804_151}"},
	[4] = {image="set:BW_Match1 image:Number4", name="#{BWDH_180804_150}"},
	[5] = {image="set:BW_Match1 image:Number5", name="#{BWDH_180804_149}"},
}

local g_FightLevel = {
	[0] = {nameNoColor = "#{BWDH_210908_01}", image="set:BW_Match20 image:queLevel"},
	[1] = {nameNoColor = "#{BWDH_180804_13}", image="set:BW_Match6 image:EagleLevle"},
	[2] = {nameNoColor = "#{BWDH_180804_14}", image="set:BW_Match6 image:DragonLevel"},
	[3] = {nameNoColor = "#{BWDH_250113_06}", image="set:BW_Match21 image:KunLevel"},
	}


local g_Bright_Stars = "set:BW_Match1 image:Bright_Stars"
local g_Gray_Stars = "set:BW_Match1 image:Gray_Stars"

local g_Button_Hover = "set:GuiShiBase image:GuiShiButton02_Hover"
local g_Button_Normal = "set:GuiShiBase image:GuiShiButton02_Normal"

local g_DuanWei_Value =
{
	ShiJian = 1, -- 试剑
	TingJian = 2, -- 听剑
	DouJian = 3, -- 斗剑
	YuJian = 4, -- 御剑
	YiJian = 5, -- 意剑
	ShenJian = 6, -- 神剑
}

local g_Level_Value =
{
	Que = 0, -- 雀影
	Ying = 1, -- 鹰扬
	Long = 2, -- 龙腾
	Kun = 3, -- 鲲跃
}


local g_WeekAward_Type =
{
	invalid = 0,
	part = 1, -- 参与奖励
	win = 2, -- 胜场奖励
	--buchang = 3, -- 补偿奖励
}
local g_WeekAward_Click = g_WeekAward_Type.invalid
local g_DuanWeiAward_Define = --段位奖励
{
	XBW_DUANWEI_REWARD_INVALID = 0,	--//初始值
	
	no_item = -1,	--//没有奖励
	no_reached = -2,	--//没有资格
	have_get = -3,	--//已经领过了
	can_get = 1,	--//可以领取
}

local g_Item_XuanJiaLing = 39923715 --玄甲令
local g_Item_ChangGeFu = 39923714 --长戈符

local g_Item_QingFengLing = 39924621 --清风令  haoqifu低级
local g_Item_HaoQiFu = 39924622 --浩气符  haoqifu高级

local g_WeekAward_Part = {  --参与奖励参与次数
	[1] = {
		need_cnt=6,
		award = {
			[g_Level_Value.Que]={xuanjialing=120, qingfengling=100}, --60-69
			[g_Level_Value.Ying]={xuanjialing=160, qingfengling=100}, --70-89
			[g_Level_Value.Long]={xuanjialing=200, qingfengling=100}, --90-119
			[g_Level_Value.Kun]={xuanjialing=200, qingfengling=100}, --120-129
		},
		text = "#{BWDH_240315_54}",
	},
	[2] = {
		need_cnt=12,
		award = {
			[g_Level_Value.Que]={xuanjialing=180, qingfengling=150}, --60-69
			[g_Level_Value.Ying]={xuanjialing=240, qingfengling=150}, --70-89
			[g_Level_Value.Long]={xuanjialing=300, qingfengling=150}, --90-119
			[g_Level_Value.Kun]={xuanjialing=300, qingfengling=150}, --120-129
		},		
		text = "#{BWDH_240315_55}",
	},
}

local g_WeekAward_WinCnt = {
	[1] = {
		need_cnt=5,
		text = "#{BWDH_240315_59}",
	},
	[2]	= {
		need_cnt=8,
		text = "#{BWDH_240315_60}",
	},
}
local g_WeekAward_WinInfo = --奖励币 长戈符 胜场奖励
{
	[g_DuanWei_Value.ShiJian] = -- 试剑
	{
		[g_Level_Value.Que]={
			[1]={changgefu=0, haoqifu=0}, [2]={changgefu=0, haoqifu=0}
		}, --60-69
		[g_Level_Value.Ying]={
			[1]={changgefu=0, haoqifu=0}, [2]={changgefu=0, haoqifu=0}
		}, --70-89
		[g_Level_Value.Long]={
			[1]={changgefu=0, haoqifu=0}, [2]={changgefu=0, haoqifu=0}
		}, --90-119
		[g_Level_Value.Kun]={
			[1]={changgefu=0, haoqifu=0}, [2]={changgefu=0, haoqifu=0}
		}, --120-129
	},
	[g_DuanWei_Value.TingJian] = -- 听剑
	{
		[g_Level_Value.Que]={
			[1]={changgefu=0, haoqifu=0}, [2]={changgefu=0, haoqifu=0}
		}, --60-69
		[g_Level_Value.Ying]={
			[1]={changgefu=0, haoqifu=0}, [2]={changgefu=0, haoqifu=0}
		}, --70-89
		[g_Level_Value.Long]={
			[1]={changgefu=0, haoqifu=0}, [2]={changgefu=0, haoqifu=0}
		}, --90-119
		[g_Level_Value.Kun]={
			[1]={changgefu=0, haoqifu=0}, [2]={changgefu=0, haoqifu=0}
		}, --120-129
	},
	[g_DuanWei_Value.DouJian] = -- 斗剑
	{
		[g_Level_Value.Que]={
			[1]={changgefu=0, haoqifu=0}, [2]={changgefu=3, haoqifu=5}
		}, --60-69
		[g_Level_Value.Ying]={
			[1]={changgefu=0, haoqifu=0}, [2]={changgefu=6, haoqifu=5}
		}, --70-89
		[g_Level_Value.Long]={
			[1]={changgefu=0, haoqifu=0}, [2]={changgefu=9, haoqifu=5}
		}, --90-119
		[g_Level_Value.Kun]={
			[1]={changgefu=0, haoqifu=0}, [2]={changgefu=9, haoqifu=5}
		}, --120-129
	},
	[g_DuanWei_Value.YuJian] = -- 御剑
	{
		[g_Level_Value.Que]={
			[1]={changgefu=2, haoqifu=3}, [2]={changgefu=3, haoqifu=5}
		}, --60-69
		[g_Level_Value.Ying]={
			[1]={changgefu=4, haoqifu=3}, [2]={changgefu=6, haoqifu=5}
		}, --70-89
		[g_Level_Value.Long]={
			[1]={changgefu=6, haoqifu=3}, [2]={changgefu=9, haoqifu=5}
		}, --90-119
		[g_Level_Value.Kun]={
			[1]={changgefu=6, haoqifu=3}, [2]={changgefu=9, haoqifu=5}
		}, --120-129
	},
	[g_DuanWei_Value.YiJian] = -- 意剑
	{
		[g_Level_Value.Que]={
			[1]={changgefu=4, haoqifu=4}, [2]={changgefu=6, haoqifu=6}
		}, --60-69
		[g_Level_Value.Ying]={
			[1]={changgefu=6, haoqifu=4}, [2]={changgefu=9, haoqifu=6}
		}, --70-89
		[g_Level_Value.Long]={
			[1]={changgefu=8, haoqifu=4}, [2]={changgefu=12, haoqifu=6}
		}, --90-119
		[g_Level_Value.Kun]={
			[1]={changgefu=8, haoqifu=4}, [2]={changgefu=12, haoqifu=6}
		}, --120-129
	},
	[g_DuanWei_Value.ShenJian] = -- 神剑
	{
		[g_Level_Value.Que]={
			[1]={changgefu=6, haoqifu=5}, [2]={changgefu=9, haoqifu=9}
		}, --60-69
		[g_Level_Value.Ying]={
			[1]={changgefu=8, haoqifu=5}, [2]={changgefu=12, haoqifu=9}
		}, --70-89
		[g_Level_Value.Long]={
			[1]={changgefu=10, haoqifu=5}, [2]={changgefu=15, haoqifu=9}
		}, --90-119
		[g_Level_Value.Kun]={
			[1]={changgefu=10, haoqifu=5}, [2]={changgefu=15, haoqifu=9}
		}, --120-129
	},
}

-- local g_WeekAwardNeedCnt_Ex = 8 --本周胜利8场可以领取补偿奖励
-- local g_WeekAward_Ex = --奖励币 长戈符 
-- {
	-- [0]=3, --60-69
	-- [1]=6, --70-89
	-- [2]=9, --90-119
	-- [3]=9, --120-129
-- }

local g_DuanWeiAward_dw1 = 0
local g_DuanWeiAward_dw2 = 0

----------------------------------普通服奖励--------------------------------
local g_DuanWeiAward_Info = {}
--60-69级
g_DuanWeiAward_Info[0] = {
	[1] = { --拭剑
		[1] = { -- 一阶
			item = {
				{id=38001553, num=2,},
				{id=20310168, num=3,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},	
	},
	[2] = { --听剑
		[1] = { -- 一阶
			item = {
				{id=38001553, num=4,},
				{id=30008034, num=3,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38001553, num=4,},
				{id=30008034, num=3,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38001553, num=4,},
				{id=30008034, num=3,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[3] = { --斗剑
		[1] = { -- 一阶
			item = {
				{id=30503188, num=3,},
				{id=20310175, num=2,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=30503188, num=3,},
				{id=20310175, num=2,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=30503188, num=3,},
				{id=20310175, num=2,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
	},
	[4] = { --御剑
		[1] = { -- 一阶
			item = {
				{id=20310149, num=5,},
				{id=20310140, num=5,},
			},
			PropertySpace=0, --道具栏
			MaterialSpace=2, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=20310131, num=5,},
				{id=20310122, num=5,},
			},
			PropertySpace=0, --道具栏
			MaterialSpace=2, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=20310149, num=5,},
				{id=20310140, num=5,},
			},
			PropertySpace=0, --道具栏
			MaterialSpace=2, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=20310131, num=5,},
				{id=20310122, num=5,},
			},
			PropertySpace=0, --道具栏
			MaterialSpace=2, --材料栏
		},
	},
	[5] = { --意剑
		[1] = { -- 一阶
			item = {
				{id=38004038, num=1,},
				{id=38000571, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38004038, num=1,},
				{id=38000571, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38004038, num=1,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=0, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=38004038, num=1,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[6] = { --神剑
		[1] = { -- 一阶
			item = {
				{id=39910142, num=1,},
				{id=38010095, num=1,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
}


--70-89级
g_DuanWeiAward_Info[1] = {
	[1] = { --拭剑
		[1] = { -- 一阶
			item = {
				{id=38001553, num=3,},
				{id=20310168, num=4,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},	
	},
	[2] = { --听剑
		[1] = { -- 一阶
			item = {
				{id=38001553, num=5,},
				{id=30008034, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38001553, num=5,},
				{id=30008034, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38001553, num=5,},
				{id=30008034, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[3] = { --斗剑
		[1] = { -- 一阶
			item = {
				{id=38004358, num=3,},
				{id=38004354, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38004358, num=3,},
				{id=38004354, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38004358, num=3,},
				{id=38004354, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[4] = { --御剑
		[1] = { -- 一阶
			item = {
				{id=38007521, num=5,},
				{id=38007502, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38007521, num=5,},
				{id=38007502, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38007521, num=5,},
				{id=38007502, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=38007521, num=5,},
				{id=38007502, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[5] = { --意剑
		[1] = { -- 一阶
			item = {
				{id=38005556, num=1,},
				{id=38004734, num=20,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38005556, num=1,},
				{id=38004734, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38005556, num=1,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=0, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=38005556, num=1,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[6] = { --神剑
		[1] = { -- 一阶
			item = {
				{id=39910142, num=1,},
				{id=38010095, num=1,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
}


--90-119级
g_DuanWeiAward_Info[2] = {
	[1] = { --拭剑
		[1] = { -- 一阶
			item = {
				{id=38001553, num=4,},
				{id=20310168, num=5,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},	
	},
	[2] = { --听剑
		[1] = { -- 一阶
			item = {
				{id=38001553, num=8,},
				{id=30008034, num=8,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38001553, num=8,},
				{id=30008034, num=8,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38001553, num=8,},
				{id=30008034, num=8,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[3] = { --斗剑
		[1] = { -- 一阶
			item = {
				{id=38004358, num=5,},
				{id=38004354, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38004358, num=5,},
				{id=38004354, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38004358, num=5,},
				{id=38004354, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[4] = { --御剑
		[1] = { -- 一阶
			item = {
				{id=38007521, num=8,},
				{id=38007502, num=15,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38007521, num=8,},
				{id=38007502, num=15,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38007521, num=8,},
				{id=38007502, num=15,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=38007521, num=8,},
				{id=38007502, num=15,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[5] = { --意剑
		[1] = { -- 一阶
			item = {
				{id=38005556, num=1,},
				{id=38004734, num=20,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38005556, num=1,},
				{id=38004734, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38005556, num=1,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=0, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=38005556, num=1,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[6] = { --神剑
		[1] = { -- 一阶
			item = {
				{id=39910142, num=1,},
				{id=38010095, num=1,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
}


--120-129级
g_DuanWeiAward_Info[3] = {
	[1] = { --拭剑
		[1] = { -- 一阶
			item = {
				{id=39925039, num=2,},
				{id=20310168, num=5,},
			},
			PropertySpace=0, --道具栏
			MaterialSpace=2, --材料栏
		},	
	},
	[2] = { --听剑
		[1] = { -- 一阶
			item = {
				{id=39925040, num=2,},
				{id=30008034, num=8,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=39925040, num=2,},
				{id=30008034, num=8,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=39925039, num=2,},
				{id=30008034, num=8,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
	},
	[3] = { --斗剑
		[1] = { -- 一阶
			item = {
				{id=38004358, num=5,},
				{id=38004354, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38004358, num=5,},
				{id=38004354, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38004358, num=5,},
				{id=38004354, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[4] = { --御剑
		[1] = { -- 一阶
			item = {
				{id=38007521, num=8,},
				{id=38007502, num=15,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38007521, num=8,},
				{id=38007502, num=15,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38007521, num=8,},
				{id=38007502, num=15,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=38007521, num=8,},
				{id=38007502, num=15,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[5] = { --意剑
		[1] = { -- 一阶
			item = {
				{id=38005556, num=1,},
				{id=38004734, num=20,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38005556, num=1,},
				{id=38004734, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38005556, num=1,},
				{id=39925041, num=3,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=38005556, num=1,},
				{id=39925041, num=2,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
	},
	[6] = { --神剑
		[1] = { -- 一阶
			item = {
				{id=39910142, num=1,},
				{id=38010095, num=1,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
}

----------------------------------普通服奖励--------------------------------


----------------------------------删减服奖励--------------------------------
local g_DuanWeiAward_Info_Original = {}
--60-69级
g_DuanWeiAward_Info_Original[0] = {
	[1] = { --拭剑
		[1] = { -- 一阶
			item = {
				{id=38001553, num=2,},
				{id=20310168, num=3,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},	
	},
	[2] = { --听剑
		[1] = { -- 一阶
			item = {
				{id=38001553, num=4,},
				{id=30008034, num=3,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38001553, num=4,},
				{id=30008034, num=3,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38001553, num=4,},
				{id=30008034, num=3,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[3] = { --斗剑
		[1] = { -- 一阶
			item = {
				{id=30503188, num=3,},
				{id=20310175, num=2,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=30503188, num=3,},
				{id=20310175, num=2,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=30503188, num=3,},
				{id=20310175, num=2,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
	},
	[4] = { --御剑
		[1] = { -- 一阶
			item = {
				{id=20310149, num=5,},
				{id=20310140, num=5,},
			},
			PropertySpace=0, --道具栏
			MaterialSpace=2, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=20310131, num=5,},
				{id=20310122, num=5,},
			},
			PropertySpace=0, --道具栏
			MaterialSpace=2, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=20310149, num=5,},
				{id=20310140, num=5,},
			},
			PropertySpace=0, --道具栏
			MaterialSpace=2, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=20310131, num=5,},
				{id=20310122, num=5,},
			},
			PropertySpace=0, --道具栏
			MaterialSpace=2, --材料栏
		},
	},
	[5] = { --意剑
		[1] = { -- 一阶
			item = {
				{id=38004038, num=1,},
				{id=38000571, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38004038, num=1,},
				{id=38000571, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38004038, num=1,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=0, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=38004038, num=1,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[6] = { --神剑
		[1] = { -- 一阶
			item = {
				{id=39910142, num=1,},
				{id=38010095, num=1,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
}


--70-89级
g_DuanWeiAward_Info_Original[1] = {
	[1] = { --拭剑
		[1] = { -- 一阶
			item = {
				{id=38001553, num=3,},
				{id=20310168, num=4,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},	
	},
	[2] = { --听剑
		[1] = { -- 一阶
			item = {
				{id=38001553, num=5,},
				{id=30008034, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38001553, num=5,},
				{id=30008034, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38001553, num=5,},
				{id=30008034, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[3] = { --斗剑
		[1] = { -- 一阶
			item = {
				{id=30503188, num=5,},
				{id=20310175, num=3,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=30503188, num=5,},
				{id=20310175, num=3,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=30503188, num=5,},
				{id=20310175, num=3,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
	},
	[4] = { --御剑
		[1] = { -- 一阶
			item = {
				{id=20310168, num=4,},
				{id=30700242, num=5,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=20310168, num=4,},
				{id=30700242, num=5,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=20310168, num=4,},
				{id=30700242, num=5,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=20310168, num=4,},
				{id=30700242, num=5,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
	},
	[5] = { --意剑
		[1] = { -- 一阶
			item = {
				{id=38005556, num=1,},
				{id=38000571, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38005556, num=1,},
				{id=38000571, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38005556, num=1,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=0, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=38005556, num=1,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[6] = { --神剑
		[1] = { -- 一阶
			item = {
				{id=39910142, num=1,},
				{id=38010116, num=1,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
}


--90-119级
g_DuanWeiAward_Info_Original[2] = {
	[1] = { --拭剑
		[1] = { -- 一阶
			item = {
				{id=38001553, num=4,},
				{id=20310168, num=5,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},	
	},
	[2] = { --听剑
		[1] = { -- 一阶
			item = {
				{id=38001553, num=8,},
				{id=30008034, num=8,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38001553, num=8,},
				{id=30008034, num=8,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38001553, num=8,},
				{id=30008034, num=8,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[3] = { --斗剑
		[1] = { -- 一阶
			item = {
				{id=30503188, num=8,},
				{id=20310175, num=5,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=30503188, num=8,},
				{id=20310175, num=5,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=30503188, num=8,},
				{id=20310175, num=5,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
	},
	[4] = { --御剑
		[1] = { -- 一阶
			item = {
				{id=20310168, num=5,},
				{id=30700242, num=6,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=20310168, num=5,},
				{id=30700242, num=6,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=20310168, num=5,},
				{id=30700242, num=6,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=20310168, num=5,},
				{id=30700242, num=6,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
	},
	[5] = { --意剑
		[1] = { -- 一阶
			item = {
				{id=38005556, num=1,},
				{id=38000571, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38005556, num=1,},
				{id=38000571, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38005556, num=1,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=0, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=38005556, num=1,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
	[6] = { --神剑
		[1] = { -- 一阶
			item = {
				{id=39910142, num=1,},
				{id=38010116, num=1,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
}


--120-129级
g_DuanWeiAward_Info_Original[3] = {
	[1] = { --拭剑
		[1] = { -- 一阶
			item = {
				{id=39925039, num=2,},
				{id=20310168, num=5,},
			},
			PropertySpace=0, --道具栏
			MaterialSpace=2, --材料栏
		},	
	},
	[2] = { --听剑
		[1] = { -- 一阶
			item = {
				{id=39925040, num=2,},
				{id=30008034, num=8,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=39925040, num=2,},
				{id=30008034, num=8,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=39925039, num=2,},
				{id=30008034, num=8,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
	},
	[3] = { --斗剑
		[1] = { -- 一阶
			item = {
				{id=30503188, num=8,},
				{id=20310175, num=5,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=30503188, num=8,},
				{id=20310175, num=5,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=30503188, num=8,},
				{id=20310175, num=5,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
	},
	[4] = { --御剑
		[1] = { -- 一阶
			item = {
				{id=20310168, num=5,},
				{id=30700242, num=6,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=20310168, num=5,},
				{id=30700242, num=6,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=20310168, num=5,},
				{id=30700242, num=6,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=20310168, num=5,},
				{id=30700242, num=6,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
	},
	[5] = { --意剑
		[1] = { -- 一阶
			item = {
				{id=38005556, num=1,},
				{id=38000571, num=10,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[2] = { -- 二阶
			item = {
				{id=38005556, num=1,},
				{id=38000571, num=5,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
		[3] = { -- 三阶
			item = {
				{id=38005556, num=1,},
				{id=39925041, num=3,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
		[4] = { -- 四阶
			item = {
				{id=38005556, num=1,},
				{id=39925041, num=2,},
			},
			PropertySpace=1, --道具栏
			MaterialSpace=1, --材料栏
		},
	},
	[6] = { --神剑
		[1] = { -- 一阶
			item = {
				{id=39910142, num=1,},
				{id=38010116, num=1,},
			},
			PropertySpace=2, --道具栏
			MaterialSpace=0, --材料栏
		},
	},
}

----------------------------------删减服奖励--------------------------------


function BW_Match_Stage_PreLoad()
	this:RegisterEvent("XBW_SELF_DETAIL_UPDATE_2018", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BW_Match_Stage_OnLoad()
	g_BW_Match_Stage_Frame_UnifiedPosition = BW_Match_Stage_Frame:GetProperty("UnifiedPosition");

	g_BW_Match_Stage_Star3[1] = BW_Match_Stage_Star1
	g_BW_Match_Stage_Star3[2] = BW_Match_Stage_Star2
	g_BW_Match_Stage_Star3[3] = BW_Match_Stage_Star3

	g_BW_Match_Stage_Star4[1] = BW_Match_Stage_Star1_1
	g_BW_Match_Stage_Star4[2] = BW_Match_Stage_Star1_2
	g_BW_Match_Stage_Star4[3] = BW_Match_Stage_Star1_3
	g_BW_Match_Stage_Star4[4] = BW_Match_Stage_Star1_4

  -- g_BW_Match_Stage_Star2[1] = BW_Match_Stage_Star2_1
  -- g_BW_Match_Stage_Star2[2] = BW_Match_Stage_Star2_2

	g_BW_Match_Stage_Star6[1] = BW_Match_Stage_Star6_1
	g_BW_Match_Stage_Star6[2] = BW_Match_Stage_Star6_2
	g_BW_Match_Stage_Star6[3] = BW_Match_Stage_Star6_3
	g_BW_Match_Stage_Star6[4] = BW_Match_Stage_Star6_4
	g_BW_Match_Stage_Star6[5] = BW_Match_Stage_Star6_5
	g_BW_Match_Stage_Star6[6] = BW_Match_Stage_Star6_6

	g_BW_Match_Stage_Star8[1] = BW_Match_Stage_Star8_1
	g_BW_Match_Stage_Star8[2] = BW_Match_Stage_Star8_2
	g_BW_Match_Stage_Star8[3] = BW_Match_Stage_Star8_3
	g_BW_Match_Stage_Star8[4] = BW_Match_Stage_Star8_4
	g_BW_Match_Stage_Star8[5] = BW_Match_Stage_Star8_5
	g_BW_Match_Stage_Star8[6] = BW_Match_Stage_Star8_6
	g_BW_Match_Stage_Star8[7] = BW_Match_Stage_Star8_7
	g_BW_Match_Stage_Star8[8] = BW_Match_Stage_Star8_8

	g_BW_Match_Stage_Star5[1] = BW_Match_Stage_Star5_1
	g_BW_Match_Stage_Star5[2] = BW_Match_Stage_Star5_2
	g_BW_Match_Stage_Star5[3] = BW_Match_Stage_Star5_3
	g_BW_Match_Stage_Star5[4] = BW_Match_Stage_Star5_4
	g_BW_Match_Stage_Star5[5] = BW_Match_Stage_Star5_5

	g_BW_Match_Stage_Award_DW2_Button[1] = BW_Match_Stage_StageRight_RewardTitle1
	g_BW_Match_Stage_Award_DW2_Button[2] = BW_Match_Stage_StageRight_RewardTitle2
	g_BW_Match_Stage_Award_DW2_Button[3] = BW_Match_Stage_StageRight_RewardTitle3
	g_BW_Match_Stage_Award_DW2_Button[4] = BW_Match_Stage_StageRight_RewardTitle4
	
	g_BW_Match_Stage_Award_DW2_ButtonText[1] = BW_Match_Stage_StageRight_RewardTitle1_Text
	g_BW_Match_Stage_Award_DW2_ButtonText[2] = BW_Match_Stage_StageRight_RewardTitle2_Text
	g_BW_Match_Stage_Award_DW2_ButtonText[3] = BW_Match_Stage_StageRight_RewardTitle3_Text
	g_BW_Match_Stage_Award_DW2_ButtonText[4] = BW_Match_Stage_StageRight_RewardTitle4_Text

	g_BW_Match_Stage_Award_DW2_Tips[1] = BW_Match_Stage_StageRight_RewardTitle1_Tips
	g_BW_Match_Stage_Award_DW2_Tips[2] = BW_Match_Stage_StageRight_RewardTitle2_Tips
	g_BW_Match_Stage_Award_DW2_Tips[3] = BW_Match_Stage_StageRight_RewardTitle3_Tips
	g_BW_Match_Stage_Award_DW2_Tips[4] = BW_Match_Stage_StageRight_RewardTitle4_Tips

	g_BW_Match_Stage_Award_Item_Button[1] = BW_Match_Stage_StageRight_Reward_Icon1
	g_BW_Match_Stage_Award_Item_Button[2] = BW_Match_Stage_StageRight_Reward_Icon2
	g_BW_Match_Stage_Award_Item_ButtonEx[1] = BW_Match_Stage_StageRight_Reward_Icon3
  
	BW_Match_Stage_StageRight_Reward_Select:ComboBoxAddItem( "试剑", 0);--试剑
	BW_Match_Stage_StageRight_Reward_Select:ComboBoxAddItem( "听剑", 1);--听剑
	BW_Match_Stage_StageRight_Reward_Select:ComboBoxAddItem( "斗剑", 2);--斗剑
	BW_Match_Stage_StageRight_Reward_Select:ComboBoxAddItem( "御剑", 3);--御剑
	BW_Match_Stage_StageRight_Reward_Select:ComboBoxAddItem( "意剑", 4);--意剑
	BW_Match_Stage_StageRight_Reward_Select:ComboBoxAddItem( "神剑", 5);--神剑
end

-- OnEvent
function BW_Match_Stage_OnEvent(event)
	--
	if (event == "XBW_SELF_DETAIL_UPDATE_2018") then

		local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
		if levelIndex < 0 or levelIndex >= BWDH2018:GetMaxLevelIndex() then
			return
		end

		local isUpdate = 0
		if this:IsVisible() == true then
			isUpdate = 1
		end

		BW_Match_Stage_UpdateSelf_Top(isUpdate)
		BW_Match_Stage_UpdateSelf_Other(isUpdate)
		this:Show()

	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		BW_Match_StageFrame_CloseWindow()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		BW_Match_Stage_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BW_Match_Stage_Frame_On_ResetPos()
	end
end

function BW_Match_Stage_Init( )
	BW_Match_Stage_DragTitleBK:SetText("")

	BW_Match_Stage_StageLeft_Text1:SetText("")
	BW_Match_Stage_StageLeft_Text2:SetText("")
	BW_Match_Stage_StarSet:Hide()
	BW_Match_Stage_StarSet1:Hide()
	BW_Match_Stage_StarSet3:Hide()
	--BW_Match_Stage_StarSet2:Hide()
	BW_Match_Stage_StarSet6:Hide()
	BW_Match_Stage_StarSet8:Hide()
	BW_Match_Stage_StarSet5:Hide()

	BW_Match_Stage_StageRight_Text1_1:SetText("")
	BW_Match_Stage_StageRight_Text2_1:SetText("")
	BW_Match_Stage_StageRight_Text3_1:SetText("")
	BW_Match_Stage_StageRight_Text4_1:SetText("")
end

function BW_Match_Stage_UpdateSelf_Other( isUpdate )

	BW_Match_Stage_Init()

	local name = Player:GetName( )
	local text = ScriptGlobal_Format("#{BWDH_180804_26}", name)
	BW_Match_Stage_DragTitle:SetText(text)

	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	BW_Match_Stage_Client_FrameLeftTitle:SetProperty("Image", g_FightLevel[levelIndex].image)

	--大段位
	local nCurDuanWei1 = Player:Lua_GetXbwData_2018( "CuruanWei1" )
	BW_Match_Stage_StageLeft_Image:SetProperty("Image", g_Duanwei1_Image[levelIndex][nCurDuanWei1])

	--小段位
	local nCurDuanWei2 = Player:Lua_GetXbwData_2018( "CuruanWei2" )
	if nCurDuanWei1 ~= g_DuanWei_Value.ShenJian then
		BW_Match_Stage_StageLeft_Text1:SetProperty("Image", g_Duanwei2_Info[nCurDuanWei2].image)
		BW_Match_Stage_StageLeft_Text1:Show()
	else
		BW_Match_Stage_StageLeft_Text1:Hide()
	end

	local text2 = ""
	if nCurDuanWei1 < g_DuanWei_Value.ShenJian then
		text2 = ScriptGlobal_Format("#{BWDH_180804_154}", g_Duanwei1_name[nCurDuanWei1], g_Duanwei2_Info[nCurDuanWei2].name)
	else
		text2 = "#{BWDH_180804_155}"
	end
	BW_Match_Stage_StageLeft_Text2:SetText(text2)

	--星星
	local nCurDuanWei3 = Player:Lua_GetXbwData_2018( "CuruanWei3" )
	if nCurDuanWei3 == nil then
		return
	end

	local nMaxDuanWei3 = BWDH2018:GetXbwDuanweinfo2018(nCurDuanWei1, nCurDuanWei2)
	if  nCurDuanWei1 == g_DuanWei_Value.ShenJian then --王者
		BW_Match_Stage_StarSet3:Show()
		BW_Match_Stage_Star3_1:SetProperty("Image", g_Bright_Stars)
		BW_Match_Stage_Star3_1:SetToolTip("#{BWDH_180804_31}")
		BW_Match_Stage_Star3Text:SetText(tostring(nCurDuanWei3))

	-- elseif nMaxDuanWei3 == 2 then
		-- BW_Match_Stage_StarSet2:Show()
		-- for i=1,nMaxDuanWei3 do
			-- if i <= nCurDuanWei3 then
				-- g_BW_Match_Stage_Star2[i]:SetProperty("Image", g_Bright_Stars)
			-- else
				-- g_BW_Match_Stage_Star2[i]:SetProperty("Image", g_Gray_Stars)
			-- end
			-- g_BW_Match_Stage_Star2[i]:SetToolTip("#{BWDH_180804_31}")
		-- end

	elseif nMaxDuanWei3 == 3 then
		BW_Match_Stage_StarSet:Show()
		for i=1,nMaxDuanWei3 do
			if i <= nCurDuanWei3 then
				g_BW_Match_Stage_Star3[i]:SetProperty("Image", g_Bright_Stars)
			else
				g_BW_Match_Stage_Star3[i]:SetProperty("Image", g_Gray_Stars)
			end
			g_BW_Match_Stage_Star3[i]:SetToolTip("#{BWDH_180804_31}")
		end

	elseif nMaxDuanWei3 == 4 then
		BW_Match_Stage_StarSet1:Show()
		for i=1,nMaxDuanWei3 do
			if i <= nCurDuanWei3 then
				g_BW_Match_Stage_Star4[i]:SetProperty("Image", g_Bright_Stars)
			else
				g_BW_Match_Stage_Star4[i]:SetProperty("Image", g_Gray_Stars)
			end
			g_BW_Match_Stage_Star4[i]:SetToolTip("#{BWDH_180804_31}")
		end
	elseif nMaxDuanWei3 == 6 then
		BW_Match_Stage_StarSet6:Show()
		for i=1,nMaxDuanWei3 do
			if i <= nCurDuanWei3 then
				g_BW_Match_Stage_Star6[i]:SetProperty("Image", g_Bright_Stars)
			else
				g_BW_Match_Stage_Star6[i]:SetProperty("Image", g_Gray_Stars)
			end
			g_BW_Match_Stage_Star6[i]:SetToolTip("#{BWDH_180804_31}")
		end
	elseif nMaxDuanWei3 == 8 then
		BW_Match_Stage_StarSet8:Show()
		for i=1,nMaxDuanWei3 do
			if i <= nCurDuanWei3 then
				g_BW_Match_Stage_Star8[i]:SetProperty("Image", g_Bright_Stars)
			else
				g_BW_Match_Stage_Star8[i]:SetProperty("Image", g_Gray_Stars)
			end
			g_BW_Match_Stage_Star8[i]:SetToolTip("#{BWDH_180804_31}")
		end
	elseif nMaxDuanWei3 == 5 then
		BW_Match_Stage_StarSet5:Show()
		for i=1,nMaxDuanWei3 do
			if i <= nCurDuanWei3 then
				g_BW_Match_Stage_Star5[i]:SetProperty("Image", g_Bright_Stars)
			else
				g_BW_Match_Stage_Star5[i]:SetProperty("Image", g_Gray_Stars)
			end
			g_BW_Match_Stage_Star5[i]:SetToolTip("#{BWDH_180804_31}")
		end
	end

	--本周参与次数
	local nCurWeekTotalCnt = Player:Lua_GetXbwData_2018( "CurWeekTotalCnt" )
	local text = ScriptGlobal_Format("#{SXTZ_210510_24}", nCurWeekTotalCnt)
	BW_Match_Stage_StageRight_Text1_1:SetText( text )

	--赛季的参与次数
	local nSeasonPartCnt = Player:Lua_GetXbwData_2018( "SeasonPartCnt" )
	local text = ScriptGlobal_Format("#{SXTZ_210510_24}", nSeasonPartCnt)
	BW_Match_Stage_StageRight_Text2_1:SetText( text )

	--赛季胜率
	if nSeasonPartCnt == 0 then
		local text = ScriptGlobal_Format("#{SXTZ_210510_24}", "无")
		BW_Match_Stage_StageRight_Text3_1:SetText(text)
	else
		local nSeasonWinCnt = Player:Lua_GetXbwData_2018( "SeasonWinCnt" )
		local result = math.floor( (nSeasonWinCnt/nSeasonPartCnt) * 100 )
		local text6 = ScriptGlobal_Format("#{BWDH_180804_35}", tostring(result))
		BW_Match_Stage_StageRight_Text3_1:SetText(text6)
	end

	--赛季最高连胜场次
	local nSeasonConWinCnt = Player:Lua_GetXbwData_2018( "SeasonConWinCnt" )
	local text = ScriptGlobal_Format("#{SXTZ_210510_24}", nSeasonConWinCnt)
	BW_Match_Stage_StageRight_Text4_1:SetText(text)

	--名剑币
	local nDaiBi = 0
	if nCurDuanWei1 == g_DuanWei_Value.ShenJian then
		if nCurDuanWei3 >= 3 then
			nDaiBi = math.floor(nCurDuanWei3/3)
		end
	end
	local textDaiBi = ScriptGlobal_Format("#{BWDH_240315_50}", tostring(nDaiBi))
	BW_Match_Stage_StageRight_Text6:SetText(textDaiBi)

	--周奖励
	BW_Match_Stage_Show_WeekAward(isUpdate)

	--段位奖励
	BW_Match_Stage_ShowDuanWeiReward()
end

function BW_Match_Stage_UpdateSelf_Top( isUpdate )

	--BW_Match_Stage_StageRight_Image7:Show()
	--BW_Match_Stage_StageRight_Image8:Hide()

	BW_Match_Stage_Client_FrameTitle:SetText("")
	BW_Match_Stage_StageRight_Text7:SetText("")
	--BW_Match_Stage_StageRight_Text7_1:SetText("")
	--BW_Match_Stage_StageRightTop_Help:Hide()
	--BW_Match_Stage_Have:Show()

	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )

	--本赛季将于x年x月x日结束
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nIndex,seasonBeg,weekAwardExEnd,seasonEnd = BWDH2018:GetXbwGetRecentSeasonInfo2018(curDay)

	if nIndex == nil then
		local textTitle = ScriptGlobal_Format("#{BWDH_180804_192}", tostring(1))
		BW_Match_Stage_Client_FrameTitle:SetText(textTitle)
		BW_Match_Stage_StageRight_Text7:SetText("#{BWDH_180804_184}")

	elseif curDay <= seasonEnd then
		local year = math.floor(seasonEnd/10000)
		local month = math.mod( math.floor( seasonEnd / 100 ), 100 )
		local day = math.mod( seasonEnd, 100 )

		local textTitle = ScriptGlobal_Format("#{BWDH_180804_192}", tostring(nIndex+1))
		BW_Match_Stage_Client_FrameTitle:SetText(textTitle)

		local text3 = ScriptGlobal_Format("#{BWDH_180804_27}", tostring(year), tostring(month), tostring(day))
		BW_Match_Stage_StageRight_Text7:SetText(text3)
		--BW_Match_Stage_StageRight_Text7:SetText("")
	else
		local textTitle = ScriptGlobal_Format("#{BWDH_180804_192}", tostring(nIndex+1))
		BW_Match_Stage_Client_FrameTitle:SetText(textTitle)

		local text4 = ScriptGlobal_Format("#{BWDH_180804_156}", tostring(nIndex+1))
		BW_Match_Stage_StageRight_Text7:SetText(text4)
	end
end


function BW_Match_Stage_Show_WeekAward(isUpdate)
	-- local isButton = BW_Match_Stage_IsShowButton_WeekEx()
	-- if isButton == 0 then
		-- BW_Match_Stage_StageLeft_RewardTitle3:Hide()
		-- BW_Match_Stage_StageLeft_RewardTitle3_Text:Hide()
	-- else
		-- BW_Match_Stage_StageLeft_RewardTitle3:Show()
		-- BW_Match_Stage_StageLeft_RewardTitle3_Text:Show()
	-- end
	
	-- local isTips = BW_Match_Stage_IsShowTips_WeekEx()
	-- if isTips == 0 then
		-- BW_Match_Stage_StageLeft_RewardTitle3_Tips:Hide()
	-- else
		-- BW_Match_Stage_StageLeft_RewardTitle3_Tips:Show()
	-- end
	
	local isTips = BW_Match_Stage_IsShowTips_WeekPart(1)
	local isTips2 = BW_Match_Stage_IsShowTips_WeekPart(2)
	if isTips == 1 or isTips2 == 1 then
		BW_Match_Stage_StageLeft_RewardTitle1_Tips:Show()
	else
		BW_Match_Stage_StageLeft_RewardTitle1_Tips:Hide()
	end
	
	local isTips = BW_Match_Stage_IsShowTips_WeekWin(1)
	local isTips2 = BW_Match_Stage_IsShowTips_WeekWin(2)
	if isTips == 1 or isTips2 == 1 then
		BW_Match_Stage_StageLeft_RewardTitle2_Tips:Show()
	else
		BW_Match_Stage_StageLeft_RewardTitle2_Tips:Hide()
	end
	
	if isUpdate == 1 then
		-- if g_WeekAward_Click == g_WeekAward_Type.buchang then
			-- BW_Match_Stage_Show_WeekEx_Clicked()
		if g_WeekAward_Click == g_WeekAward_Type.win then
			BW_Match_Stage_Show_WeekWin_Clicked()
		elseif g_WeekAward_Click == g_WeekAward_Type.part then
			BW_Match_Stage_Show_WeekPart_Clicked()
		else
			BW_Match_Stage_Show_WeekPart_Clicked()
		end
	else
		BW_Match_Stage_Show_WeekPart_Clicked()
	end	
end

--鼠标点击事件
function BW_Match_Stage_Show_WeekPart_Clicked()
	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	if levelIndex < 0 or levelIndex >= BWDH2018:GetMaxLevelIndex() then
		return
	end
	
	BW_Match_Stage_StageLeft_RewardTitle1:SetProperty("NormalImage", g_Button_Hover)
	BW_Match_Stage_StageLeft_RewardTitle2:SetProperty("NormalImage", g_Button_Normal)
	--BW_Match_Stage_StageLeft_RewardTitle3:SetProperty("NormalImage", g_Button_Normal)
	
	BW_Match_Stage_StageLeft_RewardBk:Show()
	BW_Match_Stage_StageLeft_RewardBk_One:Hide()

	local isTips = BW_Match_Stage_IsShowTips_WeekPart(1)
	if isTips == 1 then
		BW_Match_Stage_StageLeft_RewardBtn01_Tips:Show()
	else
		BW_Match_Stage_StageLeft_RewardBtn01_Tips:Hide()
	end

	local isTips2 = BW_Match_Stage_IsShowTips_WeekPart(2)
	if isTips2 == 1 then
		BW_Match_Stage_StageLeft_RewardBtn02_Tips:Show()
	else
		BW_Match_Stage_StageLeft_RewardBtn02_Tips:Hide()
	end

	local itemNum = g_WeekAward_Part[1].award[levelIndex].xuanjialing
	BW_Match_Stage_StageLeft_Reward_Icon2_Num:SetText(itemNum)
	local theAction = DataPool:CreateActionItemForShow(g_Item_XuanJiaLing, 1)
	if theAction:GetID() ~= 0 then
		BW_Match_Stage_StageLeft_Reward_Icon2:SetActionItem(theAction:GetID())
	end
	
	local itemNum = g_WeekAward_Part[1].award[levelIndex].qingfengling
	BW_Match_Stage_StageLeft_Reward_Icon2_2_Num:SetText(itemNum)
	local theAction = DataPool:CreateActionItemForShow(g_Item_QingFengLing, 1)
	if theAction:GetID() ~= 0 then
		BW_Match_Stage_StageLeft_Reward_Icon2_2:SetActionItem(theAction:GetID())
	end
	
	local itemNum = g_WeekAward_Part[2].award[levelIndex].xuanjialing
	BW_Match_Stage_StageLeft_Reward_Icon1_Num:SetText(itemNum)
	local theAction = DataPool:CreateActionItemForShow(g_Item_XuanJiaLing, 1)
	if theAction:GetID() ~= 0 then
		BW_Match_Stage_StageLeft_Reward_Icon1:SetActionItem(theAction:GetID())
	end
		
	local itemNum = g_WeekAward_Part[2].award[levelIndex].qingfengling
	BW_Match_Stage_StageLeft_Reward_Icon1_2_Num:SetText(itemNum)
	local theAction = DataPool:CreateActionItemForShow(g_Item_QingFengLing, 1)
	if theAction:GetID() ~= 0 then
		BW_Match_Stage_StageLeft_Reward_Icon1_2:SetActionItem(theAction:GetID())
	end
	
	BW_Match_Stage_StageLeft_Reward_Icon1_Text:SetText(g_WeekAward_Part[1].text)
	BW_Match_Stage_StageLeft_Reward_Icon2_Text:SetText(g_WeekAward_Part[2].text)
	
	--您已领取过奖励了
	local total_6, total_12, win_4, win_8, ex_8 = BW_Match_Stage_GetWeekRewardData()
	if total_6 >= 1 then
		BW_Match_Stage_StageLeft_RewardBtn01:SetText("#{BWDH_240315_71}")
		BW_Match_Stage_StageLeft_RewardBtn01:Disable()
	else
		BW_Match_Stage_StageLeft_RewardBtn01:SetText("#{BWDH_240315_70}")
		BW_Match_Stage_StageLeft_RewardBtn01:Enable()
	end

	if total_12 >= 1 then
		BW_Match_Stage_StageLeft_RewardBtn02:SetText("#{BWDH_240315_71}")
		BW_Match_Stage_StageLeft_RewardBtn02:Disable()
	else
		BW_Match_Stage_StageLeft_RewardBtn02:SetText("#{BWDH_240315_70}")
		BW_Match_Stage_StageLeft_RewardBtn02:Enable()
	end
	g_WeekAward_Click = g_WeekAward_Type.part
end

function BW_Match_Stage_Show_WeekWin_Clicked()
	local nCurDuanWei1 = Player:Lua_GetXbwData_2018( "CuruanWei1" )
	if nCurDuanWei1 < g_DuanWei_Value.DouJian then
		PushDebugMessage("#{BWDH_240315_86}")
		return
	end

	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	if levelIndex < 0 or levelIndex >= BWDH2018:GetMaxLevelIndex() then
		return
	end
	
	local dw_award_info = g_WeekAward_WinInfo[nCurDuanWei1]
	if dw_award_info == nil then
		return
	end

	local level_award_info = dw_award_info[levelIndex]
	if level_award_info == nil then
		return
	end
	
	BW_Match_Stage_StageLeft_RewardTitle1:SetProperty("NormalImage", g_Button_Normal)
	BW_Match_Stage_StageLeft_RewardTitle2:SetProperty("NormalImage", g_Button_Hover)
	--BW_Match_Stage_StageLeft_RewardTitle3:SetProperty("NormalImage", g_Button_Normal)
	
	if nCurDuanWei1 == g_DuanWei_Value.DouJian then
		BW_Match_Stage_StageLeft_RewardBk:Hide()
		BW_Match_Stage_StageLeft_RewardBk_One:Show()

		local isTips = BW_Match_Stage_IsShowTips_WeekWin(2)
		if isTips == 1 then
			BW_Match_Stage_StageLeft_RewardBtn_Tips:Show()
		else
			BW_Match_Stage_StageLeft_RewardBtn_Tips:Hide()
		end

		local addChangGeFu = level_award_info[2].changgefu
		local theAction = DataPool:CreateActionItemForShow(g_Item_ChangGeFu, addChangGeFu)
		if theAction:GetID() ~= 0 then
			BW_Match_Stage_StageLeft_Reward_Icon:SetActionItem(theAction:GetID())
		end
		
		local addHaoQiFu = level_award_info[2].haoqifu
		local theAction = DataPool:CreateActionItemForShow(g_Item_HaoQiFu, addHaoQiFu)
		if theAction:GetID() ~= 0 then
			BW_Match_Stage_StageLeft_Reward_Icon_2:SetActionItem(theAction:GetID())
		end
		
		--您已领取过奖励了
		local total_6, total_12, win_4, win_8, ex_8 = BW_Match_Stage_GetWeekRewardData()
		if win_8 >= 1 then
			BW_Match_Stage_StageLeft_RewardBtn:SetText("#{BWDH_240315_71}")
			BW_Match_Stage_StageLeft_RewardBtn:Disable()
		else
			BW_Match_Stage_StageLeft_RewardBtn:SetText("#{BWDH_240315_70}")
			BW_Match_Stage_StageLeft_RewardBtn:Enable()
		end
	else
		BW_Match_Stage_StageLeft_RewardBk:Show()
		BW_Match_Stage_StageLeft_RewardBk_One:Hide()

		local isTips = BW_Match_Stage_IsShowTips_WeekWin(1)
		if isTips == 1 then
			BW_Match_Stage_StageLeft_RewardBtn01_Tips:Show()
		else
			BW_Match_Stage_StageLeft_RewardBtn01_Tips:Hide()
		end

		local isTips2 = BW_Match_Stage_IsShowTips_WeekWin(2)
		if isTips2 == 1 then
			BW_Match_Stage_StageLeft_RewardBtn02_Tips:Show()
		else
			BW_Match_Stage_StageLeft_RewardBtn02_Tips:Hide()
		end

		local addChangGeFu = level_award_info[1].changgefu
		BW_Match_Stage_StageLeft_Reward_Icon2_Num:SetText(addChangGeFu)
		local theAction = DataPool:CreateActionItemForShow(g_Item_ChangGeFu, 1)
		if theAction:GetID() ~= 0 then
			BW_Match_Stage_StageLeft_Reward_Icon2:SetActionItem(theAction:GetID())
		end
	
		local addHaoQiFu = level_award_info[1].haoqifu
		BW_Match_Stage_StageLeft_Reward_Icon2_2_Num:SetText(addHaoQiFu)
		local theAction = DataPool:CreateActionItemForShow(g_Item_HaoQiFu, 1)
		if theAction:GetID() ~= 0 then
			BW_Match_Stage_StageLeft_Reward_Icon2_2:SetActionItem(theAction:GetID())
		end
		
		local addChangGeFu = level_award_info[2].changgefu
		BW_Match_Stage_StageLeft_Reward_Icon1_Num:SetText(addChangGeFu)
		local theAction = DataPool:CreateActionItemForShow(g_Item_ChangGeFu, 1)
		if theAction:GetID() ~= 0 then
			BW_Match_Stage_StageLeft_Reward_Icon1:SetActionItem(theAction:GetID())
		end
		
		local addHaoQiFu = level_award_info[2].haoqifu
		BW_Match_Stage_StageLeft_Reward_Icon1_2_Num:SetText(addHaoQiFu)
		local theAction = DataPool:CreateActionItemForShow(g_Item_HaoQiFu, 1)
		if theAction:GetID() ~= 0 then
			BW_Match_Stage_StageLeft_Reward_Icon1_2:SetActionItem(theAction:GetID())
		end
	
		BW_Match_Stage_StageLeft_Reward_Icon1_Text:SetText(g_WeekAward_WinCnt[1].text)
		BW_Match_Stage_StageLeft_Reward_Icon2_Text:SetText(g_WeekAward_WinCnt[2].text)
	
		--您已领取过奖励了
		local total_6, total_12, win_4, win_8, ex_8 = BW_Match_Stage_GetWeekRewardData()
		if win_4 >= 1 then
			BW_Match_Stage_StageLeft_RewardBtn01:SetText("#{BWDH_240315_71}")
			BW_Match_Stage_StageLeft_RewardBtn01:Disable()
		else
			BW_Match_Stage_StageLeft_RewardBtn01:SetText("#{BWDH_240315_70}")
			BW_Match_Stage_StageLeft_RewardBtn01:Enable()
		end

		if win_8 >= 1 then
			BW_Match_Stage_StageLeft_RewardBtn02:SetText("#{BWDH_240315_71}")
			BW_Match_Stage_StageLeft_RewardBtn02:Disable()
		else
			BW_Match_Stage_StageLeft_RewardBtn02:SetText("#{BWDH_240315_70}")
			BW_Match_Stage_StageLeft_RewardBtn02:Enable()
		end
	end
	g_WeekAward_Click = g_WeekAward_Type.win
end

-- function BW_Match_Stage_Show_WeekEx_Clicked()
	-- local nCurDuanWei1 = Player:Lua_GetXbwData_2018( "CuruanWei1" )
	-- if nCurDuanWei1 >= g_DuanWei_Value.DouJian then
		-- return
	-- end
	
	-- local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	-- if levelIndex < 0 or levelIndex >= BWDH2018:GetMaxLevelIndex() then
		-- return
	-- end

	-- BW_Match_Stage_StageLeft_RewardTitle1:SetProperty("NormalImage", g_Button_Normal)
	-- BW_Match_Stage_StageLeft_RewardTitle2:SetProperty("NormalImage", g_Button_Normal)
	-- BW_Match_Stage_StageLeft_RewardTitle3:SetProperty("NormalImage", g_Button_Hover)
	
	-- BW_Match_Stage_StageLeft_RewardBk:Hide()
	-- BW_Match_Stage_StageLeft_RewardBk_One:Show()

	-- local isTips = BW_Match_Stage_IsShowTips_WeekEx()
	-- if isTips == 1 then
		-- BW_Match_Stage_StageLeft_RewardBtn_Tips:Show()
	-- else
		-- BW_Match_Stage_StageLeft_RewardBtn_Tips:Hide()
	-- end

	-- local addChangGeFu = g_WeekAward_Ex[levelIndex]
	-- local theAction = DataPool:CreateActionItemForShow(g_Item_ChangGeFu, addChangGeFu)
	-- if theAction:GetID() ~= 0 then
		-- BW_Match_Stage_StageLeft_Reward_Icon:SetActionItem(theAction:GetID())
	-- end
		
	-- --您已领取过奖励了
	-- local total_6, total_12, win_4, win_8, ex_8 = BW_Match_Stage_GetWeekRewardData()
	-- if ex_8 >= 1 then
		-- BW_Match_Stage_StageLeft_RewardBtn:SetText("#{BWDH_240315_71}")
		-- BW_Match_Stage_StageLeft_RewardBtn:Disable()
	-- else
		-- BW_Match_Stage_StageLeft_RewardBtn:SetText("#{BWDH_240315_70}")
		-- BW_Match_Stage_StageLeft_RewardBtn:Enable()
	-- end

	-- g_WeekAward_Click = g_WeekAward_Type.buchang
-- end

function BW_Match_Stage_GetWeekAward_Clicked(index)
	-- if g_WeekAward_Click == g_WeekAward_Type.buchang then
		-- BW_Match_Stage_GetWeekAwardEx(index)
	if g_WeekAward_Click == g_WeekAward_Type.win then
		BW_Match_Stage_GetWeekWin(index)
	elseif g_WeekAward_Click == g_WeekAward_Type.part then
		BW_Match_Stage_GetWeekPart(index)
	end
end

function BW_Match_Stage_GetWeekPart(index)
	--- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{FCMX_90609_22}" )
		return
	end

	local curDay = tonumber(DataPool:GetServerDayTime())
	local nIndex,seasonBeg,weekAwardExEnd,seasonEnd = BWDH2018:GetXbwGetRecentSeasonInfo2018(curDay)
	if nIndex == nil then
		PushDebugMessage("#{BWDH_180804_209}")
		return
	end
	if curDay > seasonEnd then
		local tips = ScriptGlobal_Format("#{BWDH_180804_107}", tostring(nIndex+1))
		PushDebugMessage(tips)
		return
	end

	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	if levelIndex < 0 or levelIndex >= BWDH2018:GetMaxLevelIndex() then
		PushDebugMessage( "#{BWDH_180804_114}" )
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TryToTakePrize_Week_Part")
		Set_XSCRIPT_ScriptID(999246)
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end


function BW_Match_Stage_GetWeekWin(index)
	--- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{FCMX_90609_22}" )
		return
	end

	local curDay = tonumber(DataPool:GetServerDayTime())
	local nIndex,seasonBeg,weekAwardExEnd,seasonEnd = BWDH2018:GetXbwGetRecentSeasonInfo2018(curDay)
	if nIndex == nil then
		PushDebugMessage("#{BWDH_180804_209}")
		return
	end
	if curDay > seasonEnd then
		local tips = ScriptGlobal_Format("#{BWDH_180804_107}", tostring(nIndex+1))
		PushDebugMessage(tips)
		return
	end

	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	if levelIndex < 0 or levelIndex >= BWDH2018:GetMaxLevelIndex() then
		PushDebugMessage( "#{BWDH_180804_114}" )
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TryToTakePrize_Week_Win")
		Set_XSCRIPT_ScriptID(999246)
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end


-- function BW_Match_Stage_GetWeekAwardEx(index)
	-- --- 角色当前未处于全沉迷或半沉迷状态；
	-- if IsInFatigueState() <= 0 then
		-- PushDebugMessage( "#{FCMX_90609_22}" )
		-- return
	-- end

	-- local curDay = tonumber(DataPool:GetServerDayTime())
	-- local nIndex,seasonBeg,weekAwardExEnd,seasonEnd = BWDH2018:GetXbwGetRecentSeasonInfo2018(curDay)
	-- if nIndex == nil then
		-- return
	-- end
	-- if curDay > weekAwardExEnd then
		-- return
	-- end

	-- local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	-- if levelIndex < 0 or levelIndex >= BWDH2018:GetMaxLevelIndex() then
		-- PushDebugMessage( "#{BWDH_180804_114}" )
		-- return
	-- end

	-- Clear_XSCRIPT()
		-- Set_XSCRIPT_Function_Name("TryToTakePrize_Week_Ex")
		-- Set_XSCRIPT_ScriptID(999246)
		-- Set_XSCRIPT_ParamCount(0)
	-- Send_XSCRIPT()
-- end


--场次奖励
function BW_Match_Stage_IsShowTips_WeekPart(index)
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nIndex,seasonBeg,weekAwardExEnd,seasonEnd = BWDH2018:GetXbwGetRecentSeasonInfo2018(curDay)
	if curDay > seasonEnd then
		return 0
	end

	--您已领取过奖励了
	local total_6, total_12, win_4, win_8, ex_8 = BW_Match_Stage_GetWeekRewardData()
	local total_flag = total_12
	if index == 1 then
		total_flag = total_6
	end
	if total_flag >= 1 then
		return 0
	end

	-- 玩家上周累计参与场次是否≥6 12 场
	local nCurWeekTotalCnt = Player:Lua_GetXbwData_2018( "CurWeekTotalCnt" )
	if nCurWeekTotalCnt < g_WeekAward_Part[index].need_cnt then
		return 0
	end

	return 1
end

--胜场奖励
function BW_Match_Stage_IsShowTips_WeekWin(index)
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nIndex,seasonBeg,weekAwardExEnd,seasonEnd = BWDH2018:GetXbwGetRecentSeasonInfo2018(curDay)
	if curDay > seasonEnd then
		return 0
	end

	local nDuanWei1 = Player:Lua_GetXbwData_2018( "CuruanWei1" )
	if nDuanWei1 < g_DuanWei_Value.DouJian then
		return 0
	end
	
	if nDuanWei1==g_DuanWei_Value.DouJian and index==1 then
		return 0
	end

	--您已领取过奖励了
	local total_6, total_12, win_4, win_8, ex_8 = BW_Match_Stage_GetWeekRewardData()
	local total_flag = win_8
	if index == 1 then
		total_flag = win_4
	end
	if total_flag >= 1 then
		return 0
	end

	-- 玩家上周累计参与场次是否≥6 12 场
	local CurWeekWinCnt = Player:Lua_GetXbwData_2018( "CurWeekWinCnt" )
	if CurWeekWinCnt < g_WeekAward_WinCnt[index].need_cnt then
		return 0
	end

	return 1
end


--赛季初补偿奖励
-- function BW_Match_Stage_IsShowTips_WeekEx()

	-- local curDay = tonumber(DataPool:GetServerDayTime());
	-- local nIndex,seasonBeg,weekAwardExEnd,seasonEnd = BWDH2018:GetXbwGetRecentSeasonInfo2018(curDay)
	-- if curDay > weekAwardExEnd then
		-- return 0
	-- end

	-- local flag = Player:Lua_GetXbwData_2018("IsCanGetWeekRewardEx")
	-- if flag~=1 and nIndex~=0 then
		-- return 0
	-- end

	-- local nDuanWei1 = Player:Lua_GetXbwData_2018( "CuruanWei1" )
	-- if nDuanWei1 >= g_DuanWei_Value.DouJian then
		-- return 0
	-- end

	-- -- 玩家胜场次数是否≥8 场
	-- local CurWeekWinCnt = Player:Lua_GetXbwData_2018( "CurWeekWinCnt" )
	-- if CurWeekWinCnt < g_WeekAwardNeedCnt_Ex then
		-- return 0
	-- end

	-- --您已领取过奖励了
	-- local total_6, total_12, win_4, win_8, ex_8 = BW_Match_Stage_GetWeekRewardData()
	-- if ex_8 >= 1 then
		-- return 0
	-- end

	-- return 1
-- end

-- --赛季初补偿奖励
-- function BW_Match_Stage_IsShowButton_WeekEx()
	-- local curDay = tonumber(DataPool:GetServerDayTime());
	-- local nIndex,seasonBeg,weekAwardExEnd,seasonEnd = BWDH2018:GetXbwGetRecentSeasonInfo2018(curDay)
	-- if curDay > weekAwardExEnd then
		-- return 0
	-- end

	-- local flag = Player:Lua_GetXbwData_2018("IsCanGetWeekRewardEx")
	-- if flag~=1 and nIndex~=0 then
		-- return 0
	-- end

	-- local nDuanWei1 = Player:Lua_GetXbwData_2018( "CuruanWei1" )
	-- if nDuanWei1 >= g_DuanWei_Value.DouJian then
		-- return 0
	-- end

	-- return 1
-- end

function BW_Match_Stage_ShowDuanWeiReward()
	local is_find,dest_duanwei1,dest_duanwei2 = BW_Match_Stage_GetDestDuanWei(g_DuanWeiAward_Define.can_get)
	if is_find == 1 then
		BW_Match_Stage_StageRight_Reward_Select:SetCurrentSelect(dest_duanwei1-1) --试剑
		BW_Match_Stage_SelectDuanWeiReward(dest_duanwei1, dest_duanwei2)
		BW_Match_Stage_StageRight_Reward_Select_Tips:Show()
		return
	end

	--没有可领取的奖励 则默认选中下一级奖励
	local is_find,dest_duanwei1,dest_duanwei2 = BW_Match_Stage_GetDestDuanWei(g_DuanWeiAward_Define.no_reached)
	if is_find == 1 then
		BW_Match_Stage_StageRight_Reward_Select:SetCurrentSelect(dest_duanwei1-1) --试剑
		BW_Match_Stage_SelectDuanWeiReward(dest_duanwei1, dest_duanwei2)
		BW_Match_Stage_StageRight_Reward_Select_Tips:Hide()
		return
	end
	
	--都领取了 显示神剑
	BW_Match_Stage_StageRight_Reward_Select:SetCurrentSelect(g_DuanWei_Value.ShenJian-1) --试剑
	BW_Match_Stage_SelectDuanWeiReward(g_DuanWei_Value.ShenJian, 1)
	BW_Match_Stage_StageRight_Reward_Select_Tips:Hide()
end

function BW_Match_Stage_GetDestDuanWei(dest_state)
	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	local level_award = g_DuanWeiAward_Info[levelIndex]
	if Player:GetData("IsOriginalJD") == 1 then
		level_award = g_DuanWeiAward_Info_Original[levelIndex]
	end
	
	if level_award == nil then
		return 0,0,0
	end

	local dest_duanwei1 = 0
	local dest_duanwei2 = 0
	local is_find = 0

	for duanwei1=g_DuanWei_Value.ShiJian, g_DuanWei_Value.ShenJian do
		local duanwei1_award = level_award[duanwei1]
		local count = table.getn(duanwei1_award)
		for duanwei2=count, 1, -1 do
			local state = BW_Match_Stage_DuanWeiRewardState(duanwei1, duanwei2)
			if state == dest_state then
				dest_duanwei1 = duanwei1
				dest_duanwei2 = duanwei2
				is_find = 1
				return is_find, dest_duanwei1, dest_duanwei2
			end
		end
	end
	return is_find, dest_duanwei1, dest_duanwei2
end

function BW_Match_Stage_DuanWei1_LineChanged()
	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	local level_award = g_DuanWeiAward_Info[levelIndex]
	if Player:GetData("IsOriginalJD") == 1 then
		level_award = g_DuanWeiAward_Info_Original[levelIndex]
	end
	
	if level_award == nil then
		return
	end

	local __txt, id = BW_Match_Stage_StageRight_Reward_Select:GetCurrentSelect()
	local duanwei1 = id + 1

	local duanwei1_award = level_award[duanwei1]
	local count = table.getn(duanwei1_award)
	BW_Match_Stage_SelectDuanWeiReward(duanwei1, count)
end

function BW_Match_Stage_DuanWeiAward_DuanWei2_Clicked(duanwei2)
	BW_Match_Stage_SelectDuanWeiReward(g_DuanWeiAward_dw1, duanwei2)
end

function BW_Match_Stage_SelectDuanWeiReward(duanwei1, duanwei2)
	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	local level_award = g_DuanWeiAward_Info[levelIndex]
	if Player:GetData("IsOriginalJD") == 1 then
		level_award = g_DuanWeiAward_Info_Original[levelIndex]
	end
	
	if level_award == nil then
		return
	end

	local duanwei1_award = level_award[duanwei1]
	local count = table.getn(duanwei1_award)
	for index=1, table.getn(g_BW_Match_Stage_Award_DW2_Button) do
		if index<=count and duanwei1~=g_DuanWei_Value.ShenJian then
			g_BW_Match_Stage_Award_DW2_Button[index]:Show()
			g_BW_Match_Stage_Award_DW2_Button[index]:SetProperty("NormalImage", g_Button_Normal)
			g_BW_Match_Stage_Award_DW2_ButtonText[index]:Show()
			local state = BW_Match_Stage_DuanWeiRewardState(duanwei1, index)
			if state == g_DuanWeiAward_Define.can_get then
				g_BW_Match_Stage_Award_DW2_Tips[index]:Show()
			else
				g_BW_Match_Stage_Award_DW2_Tips[index]:Hide()
			end
		else
			g_BW_Match_Stage_Award_DW2_Button[index]:Hide()
			g_BW_Match_Stage_Award_DW2_Tips[index]:Hide()
			g_BW_Match_Stage_Award_DW2_ButtonText[index]:Hide()
		end
	end

	g_BW_Match_Stage_Award_DW2_Button[duanwei2]:SetProperty("NormalImage", g_Button_Hover)
	
	--填物品
	for index=1, table.getn(g_BW_Match_Stage_Award_Item_Button) do
		g_BW_Match_Stage_Award_Item_Button[index]:Hide()
	end
	for index=1, table.getn(g_BW_Match_Stage_Award_Item_ButtonEx) do
		g_BW_Match_Stage_Award_Item_ButtonEx[index]:Hide()
	end

	local duanwei2_award = duanwei1_award[duanwei2]
	local awardItemNum = table.getn(duanwei2_award.item)
	if awardItemNum == table.getn(g_BW_Match_Stage_Award_Item_Button) then
		for index=1, awardItemNum do
			local itemId = duanwei2_award.item[index].id
			local itemNum = duanwei2_award.item[index].num
			local theAction = DataPool:CreateActionItemForShow(itemId, itemNum)
			if theAction:GetID() ~= 0 then
				g_BW_Match_Stage_Award_Item_Button[index]:SetActionItem(theAction:GetID())
				g_BW_Match_Stage_Award_Item_Button[index]:Show()
			end
		end
	else
		for index=1, awardItemNum do
			local itemId = duanwei2_award.item[index].id
			local itemNum = duanwei2_award.item[index].num
			local theAction = DataPool:CreateActionItemForShow(itemId, itemNum)
			if theAction:GetID() ~= 0 then
				g_BW_Match_Stage_Award_Item_ButtonEx[index]:SetActionItem(theAction:GetID())
				g_BW_Match_Stage_Award_Item_ButtonEx[index]:Show()
			end
		end
	end

	local state = BW_Match_Stage_DuanWeiRewardState(duanwei1, duanwei2)
	if state == g_DuanWeiAward_Define.can_get then
		BW_Match_Stage_StageRight_RewardBtn_Tips:Show()
	else
		BW_Match_Stage_StageRight_RewardBtn_Tips:Hide()
	end

	if state == g_DuanWeiAward_Define.have_get then
		BW_Match_Stage_StageRight_RewardBtn:SetText("#{BWDH_240315_71}")
		BW_Match_Stage_StageRight_RewardBtn:Disable()
	else
		BW_Match_Stage_StageRight_RewardBtn:SetText("#{BWDH_240315_70}")
		BW_Match_Stage_StageRight_RewardBtn:Enable()
	end
	g_DuanWeiAward_dw1 = duanwei1
	g_DuanWeiAward_dw2 = duanwei2
end

--获得段位奖励的领取状态
function BW_Match_Stage_DuanWeiRewardState(duanwei1, duanwei2)

	if duanwei1 == g_DuanWei_Value.ShiJian and duanwei2==2 then
		return g_DuanWeiAward_Define.no_item
	end

	local getFlag, firstFlag, secondFlag, thirdFlag, fourthFlag = BW_Match_Stage_GetDuanWeiRewardData(duanwei1)
	if getFlag == g_DuanWeiAward_Define.XBW_DUANWEI_REWARD_INVALID then
		return g_DuanWeiAward_Define.no_reached
	end

	if getFlag > duanwei2 then
		return g_DuanWeiAward_Define.no_reached
	end
	
	if duanwei2 == 1 and firstFlag == 1 then
		return g_DuanWeiAward_Define.have_get
	end

	if duanwei2 == 2 and secondFlag == 1 then
		return g_DuanWeiAward_Define.have_get
	end

	if duanwei2 == 3 and thirdFlag == 1 then
		return g_DuanWeiAward_Define.have_get
	end

	if duanwei2 == 4 and fourthFlag == 1 then
		return g_DuanWeiAward_Define.have_get
	end

	return g_DuanWeiAward_Define.can_get
end

function BW_Match_Stage_GetDuanWeiAward( )
	--- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{FCMX_90609_22}" )
		return
	end

	local curDay = tonumber(DataPool:GetServerDayTime())
	local nIndex,seasonBeg,weekAwardExEnd,seasonEnd = BWDH2018:GetXbwGetRecentSeasonInfo2018(curDay)
	if nIndex == nil then
		return
	end

	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	if levelIndex < 0 or levelIndex >= BWDH2018:GetMaxLevelIndex() then
		PushDebugMessage( "#{BWDH_180804_114}" )
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TryToTakePrize_DuanWei")
		Set_XSCRIPT_ScriptID(999246)
		Set_XSCRIPT_Parameter(0, g_DuanWeiAward_dw1)
		Set_XSCRIPT_Parameter(1, g_DuanWeiAward_dw2)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--获得段位奖励数据
function BW_Match_Stage_GetDuanWeiRewardData(duanwei1)
	local data = Player:Lua_GetXbwData_2018("DuanWeiReward", duanwei1)
	local getFlag = math.mod(data, 10)
	local firstFlag = math.mod(math.floor(data/10), 10)
	local secondFlag = math.mod(math.floor(data/100), 10)
	local thirdFlag = math.mod(math.floor(data/1000), 10)
	local fourthFlag = math.mod(math.floor(data/10000), 10)
	return getFlag, firstFlag, secondFlag, thirdFlag, fourthFlag
end

--获得周奖励数据
function BW_Match_Stage_GetWeekRewardData()
	local data = Player:Lua_GetXbwData_2018("WeekReward")
	local total_6 = math.mod(data, 10)
	local total_12 = math.mod(math.floor(data/10), 10)
	local win_4 = math.mod(math.floor(data/100), 10)
	local win_8 = math.mod(math.floor(data/1000), 10)
	local ex_8 = math.mod(math.floor(data/10000), 10)
	return total_6, total_12, win_4, win_8, ex_8
end


function BW_Match_StageFrame_CloseWindow()
  this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BW_Match_Stage_Frame_On_ResetPos()
  BW_Match_Stage_Frame:SetProperty("UnifiedPosition", g_BW_Match_Stage_Frame_UnifiedPosition);
end



-- function BW_Match_Stage_HelpAward_Clicked()
-- 	Clear_XSCRIPT()
-- 		Set_XSCRIPT_Function_Name("ClientCallFunction")
-- 		Set_XSCRIPT_ScriptID(892895)
-- 		Set_XSCRIPT_Parameter(0, -1)
-- 		Set_XSCRIPT_Parameter(1, 2)
-- 		Set_XSCRIPT_ParamCount(2)
-- 	Send_XSCRIPT()
-- end

-- function BW_Match_Stage_HelpScore_Clicked()
	-- Clear_XSCRIPT()
		-- Set_XSCRIPT_Function_Name("ClientCallFunction")
		-- Set_XSCRIPT_ScriptID(892895)
		-- Set_XSCRIPT_Parameter(0, -1)
		-- Set_XSCRIPT_Parameter(1, 1)
		-- Set_XSCRIPT_ParamCount(2)
	-- Send_XSCRIPT()
-- end

function BW_Match_Stage_HelpLevel_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientCallFunction")
		Set_XSCRIPT_ScriptID(892895)
		Set_XSCRIPT_Parameter(0, -1)
		Set_XSCRIPT_Parameter(1, 3)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

-- function BW_Match_Stage_HelpDaibi_Clicked()
-- 	Clear_XSCRIPT()
-- 		Set_XSCRIPT_Function_Name("ClientCallFunction")
-- 		Set_XSCRIPT_ScriptID(892895)
-- 		Set_XSCRIPT_Parameter(0, -1)
-- 		Set_XSCRIPT_Parameter(1, 4)
-- 		Set_XSCRIPT_ParamCount(2)
-- 	Send_XSCRIPT()
-- end
