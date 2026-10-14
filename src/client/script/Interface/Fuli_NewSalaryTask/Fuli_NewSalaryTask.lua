
--- 工资任务改造之后的新界面
--- Author: David Gao 2012.05.17

local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_Fuli_NewSalaryTask_ObjCared = -1
local g_Fuli_NewSalaryTask_MAX_OBJ_DISTANCE = 3.0
local g_changeUI = 0

local g_Fuli_NewSalaryTask_ImageList  = {}        --- 任务状态图标
local g_Fuli_NewSalaryTask_ButtonList = {}        --- ToolTips
local g_Fuli_NewSalaryTask_NameList   = {}        --- 任务名称
local g_Fuli_NewSalaryTask_ProgList   = {}        --- 任务完成数量

local g_Fuli_NewSalaryTask_Value_Count = 100000000  --- 用于解析MD1的数据

local CreateDate = 904691712			-- 2013年08月22日08:00:00
local nCharCreateDate = 0;
local g_bIsNewServerGiftsForLevelUpValid = 0
local g_ButtonPos = {
											[1] = {x =0, y = 0, tipx =0, tipy =0},
											[2] = {x =0, y = 0, tipx =0, tipy =0},
											[3] = {x =0, y = 0, tipx =0, tipy =0},
											[4] = {x =0, y = 0, tipx =0, tipy =0},
											[5] = {x =0, y = 0, tipx =0, tipy =0},
											[6] = {x =0, y = 0, tipx =0, tipy =0},
											[7] = {x =0, y = 0, tipx =0, tipy =0},
										}
										
local g_Fuli_NewSalaryTask_MaxValueByInedx = {
    [1] = { 2, 2, 40, 40,  4,  2,  3,  3 },     --- 第1等级上限
    [2] = { 2, 2, 40,  4,  4,  3,  3,  3 },     --- 第2等级上限
    [3] = { 2, 2, 40,  4,  4,  3,  3,  3 },     --- 第3等级上限
}

local g_Fuli_NewSalaryTask_Level_Desc_Old = {
    [1] = "#{GZGZ_120514_05}", 
    [2] = "#{GZGZ_120514_06}", 
    [3] = "#{GZGZ_120514_07}",
}

local g_Fuli_NewSalaryTask_Level_Desc_New = {
    [1] = "#{GZGZ_171114_60}", 
    [2] = "#{GZGZ_171114_61}", 
    [3] = "#{GZGZ_171114_62}",
}

local Fuli_NewSalaryTask_ActList = {
    [1] = {
			[1] = { name="#{GZRW_XML_6}",     prog="/2",  tip="#{GZGZ_120514_10}", sImage="set:SalaryMission2 image:SalaryMission2_11", eImage="set:SalaryMission image:SalaryMission_11", }, --- 棋局活动
			[2] = { name="#{GZRW_XML_7}",     prog="/2",  tip="#{GZGZ_120514_22}", sImage="set:SalaryMission2 image:SalaryMission2_6",  eImage="set:SalaryMission image:SalaryMission_6",  }, --- 一个都不能跑
			[3] = { name="#{GZRW_XML_8}",     prog="/40", tip="#{GZGZ_120514_12}", sImage="set:SalaryMission2 image:SalaryMission2_3",  eImage="set:SalaryMission image:SalaryMission_3",  }, --- 师门门派任务
			[4] = { name="#{GZRW_XML_9}",     prog="/40", tip="#{GZGZ_120514_14}", sImage="set:SalaryMission2 image:SalaryMission2_8",  eImage="set:SalaryMission image:SalaryMission_8",  }, --- 勇闯天劫楼
			[5] = { name="#{GZRW_XML_10}",    prog="/4",  tip="#{GZGZ_120514_16}", sImage="set:SalaryMission2 image:SalaryMission2_13", eImage="set:SalaryMission image:SalaryMission_13", }, --- 幸运快活三活动
			[6] = { name="#{GZRW_XML_11}",    prog="/2",  tip="#{GZGZ_120514_18}", sImage="set:SalaryMission2 image:SalaryMission2_10", eImage="set:SalaryMission image:SalaryMission_10", }, --- 挖藏宝图
            [7] = { name="#{GZRW_XML_12}",    prog="/3",  tip="#{GZGZ_120514_20}", sImage="set:SalaryMission2 image:SalaryMission2_4",  eImage="set:SalaryMission image:SalaryMission_4",  }, --- 贼兵入侵
            [8] = { name="#{GZGZ_120514_33}", prog="/3",  tip="#{GZGZ_120514_34}", sImage="set:SalaryMission2 image:SalaryMission2_1",  eImage="set:SalaryMission image:SalaryMission_1",  }, --- 一千零一个愿望
          },																																   
    [2] = {																																	   
			[1] = { name="#{GZRW_XML_6}",     prog="/2",  tip="#{GZGZ_120514_10}", sImage="set:SalaryMission2 image:SalaryMission2_11", eImage="set:SalaryMission image:SalaryMission_11", }, --- 棋局活动
			[2] = { name="#{GZGZ_120514_31}", prog="/2",  tip="#{GZGZ_120514_32}", sImage="set:SalaryMission2 image:SalaryMission2_5",  eImage="set:SalaryMission image:SalaryMission_5",  }, --- 黄金之链
			[3] = { name="#{GZRW_XML_8}",     prog="/40", tip="#{GZGZ_120514_12}", sImage="set:SalaryMission2 image:SalaryMission2_3",  eImage="set:SalaryMission image:SalaryMission_3",  }, --- 师门门派任务
			[4] = { name="#{GZGZ_120514_23}", prog="/4",  tip="#{GZGZ_120514_24}", sImage="set:SalaryMission2 image:SalaryMission2_2",  eImage="set:SalaryMission image:SalaryMission_2",  }, --- 四绝庄
			[5] = { name="#{GZRW_XML_10}",    prog="/4",  tip="#{GZGZ_120514_16}", sImage="set:SalaryMission2 image:SalaryMission2_13", eImage="set:SalaryMission image:SalaryMission_13", }, --- 幸运快活三活动
			[6] = { name="#{GZGZ_120514_25}", prog="/3",  tip="#{GZGZ_120514_26}", sImage="set:SalaryMission2 image:SalaryMission2_12", eImage="set:SalaryMission image:SalaryMission_12", }, --- 杀星
			[7] = { name="#{GZGZ_120514_27}", prog="/3",  tip="#{GZGZ_120514_28}", sImage="set:SalaryMission2 image:SalaryMission2_7",  eImage="set:SalaryMission image:SalaryMission_7",  }, --- 聚宝盆
            [8] = { name="#{GZGZ_120514_33}", prog="/3",  tip="#{GZGZ_120514_34}", sImage="set:SalaryMission2 image:SalaryMission2_1",  eImage="set:SalaryMission image:SalaryMission_1",  }, --- 一千零一个愿望
          },																																   
    [3] = {																																	   
			[1] = { name="#{GZGZ_120514_29}", prog="/2",  tip="#{GZGZ_120514_30}", sImage="set:SalaryMission2 image:SalaryMission2_9",  eImage="set:SalaryMission image:SalaryMission_9",  }, --- 楼兰寻宝
			[2] = { name="#{GZGZ_120514_31}", prog="/2",  tip="#{GZGZ_120514_32}", sImage="set:SalaryMission2 image:SalaryMission2_5",  eImage="set:SalaryMission image:SalaryMission_5",  }, --- 黄金之链
			[3] = { name="#{GZRW_XML_8}",     prog="/40", tip="#{GZGZ_120514_12}", sImage="set:SalaryMission2 image:SalaryMission2_3",  eImage="set:SalaryMission image:SalaryMission_3",  }, --- 师门门派任务
			[4] = { name="#{GZGZ_120514_23}", prog="/4",  tip="#{GZGZ_120514_24}", sImage="set:SalaryMission2 image:SalaryMission2_2",  eImage="set:SalaryMission image:SalaryMission_2",  }, --- 四绝庄
			[5] = { name="#{GZRW_XML_10}",    prog="/4",  tip="#{GZGZ_120514_16}", sImage="set:SalaryMission2 image:SalaryMission2_13", eImage="set:SalaryMission image:SalaryMission_13", }, --- 幸运快活三活动
			[6] = { name="#{GZGZ_120514_25}", prog="/3",  tip="#{GZGZ_120514_26}", sImage="set:SalaryMission2 image:SalaryMission2_12", eImage="set:SalaryMission image:SalaryMission_12", }, --- 杀星
			[7] = { name="#{GZGZ_120514_27}", prog="/3",  tip="#{GZGZ_120514_28}", sImage="set:SalaryMission2 image:SalaryMission2_7",  eImage="set:SalaryMission image:SalaryMission_7",  }, --- 聚宝盆
            [8] = { name="#{GZGZ_120514_33}", prog="/3",  tip="#{GZGZ_120514_34}", sImage="set:SalaryMission2 image:SalaryMission2_1",  eImage="set:SalaryMission image:SalaryMission_1",  }, --- 一千零一个愿望
          },																			   
}																						   

---------------------------------------
--- 统计工资任务次数
--- 参数说明：
--- taskLevel: 1, Index: 1: 珍珑棋局		0/2	    --- 401001  --- 1110
---                      2: 一个都不能跑	0/2	    --- 050102  --- 2100
---                      3: 师门任务		0/40                --- 3111
---                      4: 除恶天劫楼		0/40                --- 4100
---                      5: 幸运快活三		0/4                 --- 5111
---                      6: 挖藏宝图		0/2                 --- 6100
---                      7: 贼兵入侵		0/3                 --- 7100
---                      8: 一千零一个愿望	0/3                 --- 8111
---
--- taskLevel: 2, Index: 1: 珍珑棋局		0/2     --- 401001  --- 1110
---                      2: 黄金之链		0/2     --- 050220  --- 2011
---                      3: 师门任务		0/40                --- 3111
---                      4: 四绝庄			0/4     --- 402052  --- 4011
---                      5: 幸运快活三		0/4                 --- 5111
---                      6: 杀星			0/3     --- 402048  --- 6011
---                      7: 聚宝盆领取		0/3                 --- 7011
---                      8: 一千零一个愿望	0/3                 --- 8111
--- 
--- taskLevel: 3, Index: 1: 楼兰寻宝		0/2     --- 808039  --- 1001
---                      2: 黄金之链		0/2     --- 050220  --- 2011
---                      3: 师门任务		0/40                --- 3111
---                      4: 四绝庄			0/4     --- 402052  --- 4011
---                      5: 幸运快活三		0/4                 --- 5111
---                      6: 杀星			0/3     --- 402048  --- 6011
---                      7: 聚宝盆领取		0/3                 --- 7011
---                      8: 一千零一个愿望	0/3                 --- 8111
--- 
---------------------------------------

--2014年5月20日：工资任务优化:start
local g_Fuli_NewSalaryTask_MaxValueByInedx_New = {	
	[1] = { 2, 2, 40, 3,  4,  2,  2,  2 },     --- 第1等级上限 
    [2] = { 2, 2, 2,  3,  4,  3,  10,  4 },     --- 第2等级上限
    [3] = { 2, 2, 4,  3,  4,  4,  15,  4 },     --- 第3等级上限	
}
local g_Fuli_NewSalaryTask_MaxValueByInedx_Old = {
    [1] = { 2, 2, 40, 40,  4,  2,  3,  3 },     --- 第1等级上限
    [2] = { 2, 2, 40,  4,  4,  3,  3,  3 },     --- 第2等级上限
    [3] = { 2, 2, 40,  4,  4,  3,  3,  3 },     --- 第3等级上限	
}
local Fuli_NewSalaryTask_ActList_New = {
    [1] = {
			[1] = { name="#{GZRW_XML_6}",     prog="/2",  tip="#{GZGZ_120514_10}", sImage="set:SalaryMission2 image:SalaryMission2_11", eImage="set:SalaryMission image:SalaryMission_11", }, --- 棋局活动
			[2] = { name="#{GZRW_XML_7}",     prog="/2",  tip="#{GZGZ_120514_22}", sImage="set:SalaryMission2 image:SalaryMission2_6",  eImage="set:SalaryMission image:SalaryMission_6",  }, --- 一个都不能跑
			[3] = { name="#{GZRW_XML_8}",     prog="/40", tip="#{GZGZ_120514_12}", sImage="set:SalaryMission2 image:SalaryMission2_3",  eImage="set:SalaryMission image:SalaryMission_3",  }, --- 师门门派任务
			[4] = { name="#{GZGZ_120514_27}", prog="/3",  tip="#{GZGZ_120514_28}", sImage="set:SalaryMission2 image:SalaryMission2_7",  eImage="set:SalaryMission image:SalaryMission_7",  }, --- 聚宝盆
			[5] = { name="#{GZRW_XML_10}",    prog="/4",  tip="#{GZGZ_120514_16}", sImage="set:SalaryMission2 image:SalaryMission2_13", eImage="set:SalaryMission image:SalaryMission_13", }, --- 幸运快活三活动
			[6] = { name="#{GZRW_XML_11}",    prog="/2",  tip="#{GZGZ_120514_18}", sImage="set:SalaryMission2 image:SalaryMission2_10", eImage="set:SalaryMission image:SalaryMission_10", }, --- 挖藏宝图			
            [7] = { name="#{GZGZ_120514_52}",    prog="/2",  tip="#{GZGZ_120514_53}", sImage="set:SalaryMission2 image:SalaryMission2_14",  eImage="set:SalaryMission image:SalaryMission_14",  }, --- 炼金任务
            [8] = { name="#{GZGZ_120514_33}", prog="/2",  tip="#{GZGZ_120514_34}", sImage="set:SalaryMission2 image:SalaryMission2_1",  eImage="set:SalaryMission image:SalaryMission_1",  }, --- 一千零一个愿望							
          },																																   
    [2] = {																								   
			[1] = { name="#{GZGZ_120514_29}", prog="/2",  tip="#{GZGZ_120514_30}", sImage="set:SalaryMission2 image:SalaryMission2_9",  eImage="set:SalaryMission image:SalaryMission_9",  }, --- 楼兰寻宝		
			[2] = { name="#{GZGZ_120514_31}", prog="/2",  tip="#{GZGZ_120514_32}", sImage="set:SalaryMission2 image:SalaryMission2_5",  eImage="set:SalaryMission image:SalaryMission_5",  }, --- 黄金之链			
			[3] = { name="#{GZGZ_120514_54}",     prog="/2", tip="#{GZGZ_120514_55}", sImage="set:SalaryMission2 image:SalaryMission2_15",  eImage="set:SalaryMission image:SalaryMission_15",  }, --- 初战缥缈峰
			[4] = { name="#{GZGZ_120514_27}", prog="/3",  tip="#{GZGZ_120514_28}", sImage="set:SalaryMission2 image:SalaryMission2_7",  eImage="set:SalaryMission image:SalaryMission_7",  }, --- 聚宝盆
			[5] = { name="#{GZGZ_120514_56}",    prog="/4",  tip="#{GZGZ_120514_57}", sImage="set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_8", eImage="set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_16", }, --- 讨伐燕子坞
			[6] = { name="#{GZGZ_120514_25}", prog="/3",  tip="#{GZGZ_120514_26}", sImage="set:SalaryMission2 image:SalaryMission2_12", eImage="set:SalaryMission image:SalaryMission_12", }, --- 杀星
            [7] = { name="#{GZGZ_120514_52}",    prog="/10",  tip="#{GZGZ_120514_53}", sImage="set:SalaryMission2 image:SalaryMission2_14",  eImage="set:SalaryMission image:SalaryMission_14",  }, --- 炼金任务
			[8] = { name="#{GZGZ_120514_23}", prog="/4",  tip="#{GZGZ_120514_24}", sImage="set:SalaryMission2 image:SalaryMission2_2",  eImage="set:SalaryMission image:SalaryMission_2",  }, --- 四绝庄					
          },																																   
    [3] = {	
			[1] = { name="#{GZGZ_120514_29}", prog="/2",  tip="#{GZGZ_120514_30}", sImage="set:SalaryMission2 image:SalaryMission2_9",  eImage="set:SalaryMission image:SalaryMission_9",  }, --- 楼兰寻宝
			[2] = { name="#{GZGZ_120514_31}", prog="/2",  tip="#{GZGZ_120514_32}", sImage="set:SalaryMission2 image:SalaryMission2_5",  eImage="set:SalaryMission image:SalaryMission_5",  }, --- 黄金之链		
			[3] = { name="#{GZGZ_120514_54}",     prog="/4", tip="#{GZGZ_120514_55}", sImage="set:SalaryMission2 image:SalaryMission2_15",  eImage="set:SalaryMission image:SalaryMission_15",  }, --- 初战缥缈峰
			[4] = { name="#{GZGZ_120514_27}", prog="/3",  tip="#{GZGZ_120514_28}", sImage="set:SalaryMission2 image:SalaryMission2_7",  eImage="set:SalaryMission image:SalaryMission_7",  }, --- 聚宝盆
			[5] = { name="#{GZGZ_120514_56}",    prog="/4",  tip="#{GZGZ_120514_57}", sImage="set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_8", eImage="set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_16", }, --- 讨伐燕子坞
			[6] = { name="#{GZGZ_120514_58}", prog="/4",  tip="#{GZGZ_120514_59}", sImage="set:SalaryMission2 image:SalaryMission2_16", eImage="set:SalaryMission image:SalaryMission_16", }, --- 凤鸣王陵
            [7] = { name="#{GZGZ_120514_52}",    prog="/15",  tip="#{GZGZ_120514_53}", sImage="set:SalaryMission2 image:SalaryMission2_14",  eImage="set:SalaryMission image:SalaryMission_14",  }, --- 炼金任务
			[8] = { name="#{GZGZ_120514_23}", prog="/4",  tip="#{GZGZ_120514_24}", sImage="set:SalaryMission2 image:SalaryMission2_2",  eImage="set:SalaryMission image:SalaryMission_2",  }, --- 四绝庄					
          },																			   
}	
local Fuli_NewSalaryTask_ActList_Old = {
    [1] = {
			[1] = { name="#{GZRW_XML_6}",     prog="/2",  tip="#{GZGZ_120514_10}", sImage="set:SalaryMission2 image:SalaryMission2_11", eImage="set:SalaryMission image:SalaryMission_11", }, --- 棋局活动
			[2] = { name="#{GZRW_XML_7}",     prog="/2",  tip="#{GZGZ_120514_22}", sImage="set:SalaryMission2 image:SalaryMission2_6",  eImage="set:SalaryMission image:SalaryMission_6",  }, --- 一个都不能跑
			[3] = { name="#{GZRW_XML_8}",     prog="/40", tip="#{GZGZ_120514_12}", sImage="set:SalaryMission2 image:SalaryMission2_3",  eImage="set:SalaryMission image:SalaryMission_3",  }, --- 师门门派任务
			[4] = { name="#{GZRW_XML_9}",     prog="/40", tip="#{GZGZ_120514_14}", sImage="set:SalaryMission2 image:SalaryMission2_8",  eImage="set:SalaryMission image:SalaryMission_8",  }, --- 勇闯天劫楼
			[5] = { name="#{GZRW_XML_10}",    prog="/4",  tip="#{GZGZ_120514_16}", sImage="set:SalaryMission2 image:SalaryMission2_13", eImage="set:SalaryMission image:SalaryMission_13", }, --- 幸运快活三活动
			[6] = { name="#{GZRW_XML_11}",    prog="/2",  tip="#{GZGZ_120514_18}", sImage="set:SalaryMission2 image:SalaryMission2_10", eImage="set:SalaryMission image:SalaryMission_10", }, --- 挖藏宝图
            [7] = { name="#{GZRW_XML_12}",    prog="/3",  tip="#{GZGZ_120514_20}", sImage="set:SalaryMission2 image:SalaryMission2_4",  eImage="set:SalaryMission image:SalaryMission_4",  }, --- 贼兵入侵
            [8] = { name="#{GZGZ_120514_33}", prog="/3",  tip="#{GZGZ_120514_34}", sImage="set:SalaryMission2 image:SalaryMission2_1",  eImage="set:SalaryMission image:SalaryMission_1",  }, --- 一千零一个愿望
          },																																   
    [2] = {																																	   
			[1] = { name="#{GZRW_XML_6}",     prog="/2",  tip="#{GZGZ_120514_10}", sImage="set:SalaryMission2 image:SalaryMission2_11", eImage="set:SalaryMission image:SalaryMission_11", }, --- 棋局活动
			[2] = { name="#{GZGZ_120514_31}", prog="/2",  tip="#{GZGZ_120514_32}", sImage="set:SalaryMission2 image:SalaryMission2_5",  eImage="set:SalaryMission image:SalaryMission_5",  }, --- 黄金之链
			[3] = { name="#{GZRW_XML_8}",     prog="/40", tip="#{GZGZ_120514_12}", sImage="set:SalaryMission2 image:SalaryMission2_3",  eImage="set:SalaryMission image:SalaryMission_3",  }, --- 师门门派任务
			[4] = { name="#{GZGZ_120514_23}", prog="/4",  tip="#{GZGZ_120514_24}", sImage="set:SalaryMission2 image:SalaryMission2_2",  eImage="set:SalaryMission image:SalaryMission_2",  }, --- 四绝庄
			[5] = { name="#{GZRW_XML_10}",    prog="/4",  tip="#{GZGZ_120514_16}", sImage="set:SalaryMission2 image:SalaryMission2_13", eImage="set:SalaryMission image:SalaryMission_13", }, --- 幸运快活三活动
			[6] = { name="#{GZGZ_120514_25}", prog="/3",  tip="#{GZGZ_120514_26}", sImage="set:SalaryMission2 image:SalaryMission2_12", eImage="set:SalaryMission image:SalaryMission_12", }, --- 杀星
			[7] = { name="#{GZGZ_120514_27}", prog="/3",  tip="#{GZGZ_120514_28}", sImage="set:SalaryMission2 image:SalaryMission2_7",  eImage="set:SalaryMission image:SalaryMission_7",  }, --- 聚宝盆
            [8] = { name="#{GZGZ_120514_33}", prog="/3",  tip="#{GZGZ_120514_34}", sImage="set:SalaryMission2 image:SalaryMission2_1",  eImage="set:SalaryMission image:SalaryMission_1",  }, --- 一千零一个愿望
          },																																   
    [3] = {																																	   
			[1] = { name="#{GZGZ_120514_29}", prog="/2",  tip="#{GZGZ_120514_30}", sImage="set:SalaryMission2 image:SalaryMission2_9",  eImage="set:SalaryMission image:SalaryMission_9",  }, --- 楼兰寻宝
			[2] = { name="#{GZGZ_120514_31}", prog="/2",  tip="#{GZGZ_120514_32}", sImage="set:SalaryMission2 image:SalaryMission2_5",  eImage="set:SalaryMission image:SalaryMission_5",  }, --- 黄金之链
			[3] = { name="#{GZRW_XML_8}",     prog="/40", tip="#{GZGZ_120514_12}", sImage="set:SalaryMission2 image:SalaryMission2_3",  eImage="set:SalaryMission image:SalaryMission_3",  }, --- 师门门派任务
			[4] = { name="#{GZGZ_120514_23}", prog="/4",  tip="#{GZGZ_120514_24}", sImage="set:SalaryMission2 image:SalaryMission2_2",  eImage="set:SalaryMission image:SalaryMission_2",  }, --- 四绝庄
			[5] = { name="#{GZRW_XML_10}",    prog="/4",  tip="#{GZGZ_120514_16}", sImage="set:SalaryMission2 image:SalaryMission2_13", eImage="set:SalaryMission image:SalaryMission_13", }, --- 幸运快活三活动
			[6] = { name="#{GZGZ_120514_25}", prog="/3",  tip="#{GZGZ_120514_26}", sImage="set:SalaryMission2 image:SalaryMission2_12", eImage="set:SalaryMission image:SalaryMission_12", }, --- 杀星
			[7] = { name="#{GZGZ_120514_27}", prog="/3",  tip="#{GZGZ_120514_28}", sImage="set:SalaryMission2 image:SalaryMission2_7",  eImage="set:SalaryMission image:SalaryMission_7",  }, --- 聚宝盆
            [8] = { name="#{GZGZ_120514_33}", prog="/3",  tip="#{GZGZ_120514_34}", sImage="set:SalaryMission2 image:SalaryMission2_1",  eImage="set:SalaryMission image:SalaryMission_1",  }, --- 一千零一个愿望
          },																			   
}

--- taskLevel: 1, Index: 1: 珍珑棋局		0/2	    --- 401001  --- 1100
---                      2: 一个都不能跑	0/2	    --- 050102  --- 2100
---                      3: 师门任务		0/40                --- 3100
---                      4: 聚宝盆领取		0/3                 --- 4111
---                      5: 幸运快活三		0/4                 --- 5100
---                      6: 挖藏宝图		0/2                 --- 6100
---                      7: 炼金任务		0/2                 --- 7111
---                      8: 一千零一个愿望	0/2                 --- 8100
---
--- taskLevel: 2, Index: 1: 楼兰寻宝		0/2     --- 401001  --- 1011
---                      2: 黄金之链		0/2     --- 050220  --- 2011
---                      3: 初战缥缈峰		0/2                 --- 3011
---                      4: 聚宝盆领取		0/3     --- 402052  --- 4111
---                      5: 讨伐燕子坞		0/4                 --- 5011
---                      6: 杀星			0/3     --- 402048  --- 6010
---                      7: 炼金任务		0/10                --- 7111
---                      8: 四绝庄			0/4                 --- 8011
---
--- taskLevel: 3, Index: 1: 楼兰寻宝		0/2     --- 808039  --- 1011
---                      2: 黄金之链		0/2     --- 050220  --- 2011
---                      3: 初战缥缈峰		0/4                 --- 3011
---                      4: 聚宝盆领取		0/3     --- 402052  --- 4111
---                      5: 讨伐燕子坞		0/4                 --- 5011
---                      6: 凤鸣王陵		0/4     --- 402048  --- 6001
---                      7: 炼金任务		0/15                --- 7111
---                      8: 四绝庄			0/4                 --- 8011														
--2014年5月20日：工资任务优化:end

function Fuli_NewSalaryTask_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("OPEN_NEWSALARYTASK");
end

function Fuli_NewSalaryTask_OnLoad()
    g_Fuli_NewSalaryTask_ImageList[1] = Fuli_NewSalaryTask_StaticImageFrame1
    g_Fuli_NewSalaryTask_ImageList[2] = Fuli_NewSalaryTask_StaticImageFrame2
    g_Fuli_NewSalaryTask_ImageList[3] = Fuli_NewSalaryTask_StaticImageFrame3
    g_Fuli_NewSalaryTask_ImageList[4] = Fuli_NewSalaryTask_StaticImageFrame4
    g_Fuli_NewSalaryTask_ImageList[5] = Fuli_NewSalaryTask_StaticImageFrame5
    g_Fuli_NewSalaryTask_ImageList[6] = Fuli_NewSalaryTask_StaticImageFrame6
    g_Fuli_NewSalaryTask_ImageList[7] = Fuli_NewSalaryTask_StaticImageFrame7
    g_Fuli_NewSalaryTask_ImageList[8] = Fuli_NewSalaryTask_StaticImageFrame8
    
    g_Fuli_NewSalaryTask_ButtonList[1] = Fuli_NewSalaryTask_ButtonNULL1
    g_Fuli_NewSalaryTask_ButtonList[2] = Fuli_NewSalaryTask_ButtonNULL2
    g_Fuli_NewSalaryTask_ButtonList[3] = Fuli_NewSalaryTask_ButtonNULL3
    g_Fuli_NewSalaryTask_ButtonList[4] = Fuli_NewSalaryTask_ButtonNULL4
    g_Fuli_NewSalaryTask_ButtonList[5] = Fuli_NewSalaryTask_ButtonNULL5
    g_Fuli_NewSalaryTask_ButtonList[6] = Fuli_NewSalaryTask_ButtonNULL6
    g_Fuli_NewSalaryTask_ButtonList[7] = Fuli_NewSalaryTask_ButtonNULL7
    g_Fuli_NewSalaryTask_ButtonList[8] = Fuli_NewSalaryTask_ButtonNULL8

    g_Fuli_NewSalaryTask_NameList[1] = Fuli_NewSalaryTask_ItemName1
    g_Fuli_NewSalaryTask_NameList[2] = Fuli_NewSalaryTask_ItemName2
    g_Fuli_NewSalaryTask_NameList[3] = Fuli_NewSalaryTask_ItemName3
    g_Fuli_NewSalaryTask_NameList[4] = Fuli_NewSalaryTask_ItemName4
    g_Fuli_NewSalaryTask_NameList[5] = Fuli_NewSalaryTask_ItemName5
    g_Fuli_NewSalaryTask_NameList[6] = Fuli_NewSalaryTask_ItemName6
    g_Fuli_NewSalaryTask_NameList[7] = Fuli_NewSalaryTask_ItemName7
    g_Fuli_NewSalaryTask_NameList[8] = Fuli_NewSalaryTask_ItemName8

    g_Fuli_NewSalaryTask_ProgList[1] = Fuli_NewSalaryTask_completedinfo1
    g_Fuli_NewSalaryTask_ProgList[2] = Fuli_NewSalaryTask_completedinfo2
    g_Fuli_NewSalaryTask_ProgList[3] = Fuli_NewSalaryTask_completedinfo3
    g_Fuli_NewSalaryTask_ProgList[4] = Fuli_NewSalaryTask_completedinfo4
    g_Fuli_NewSalaryTask_ProgList[5] = Fuli_NewSalaryTask_completedinfo5
    g_Fuli_NewSalaryTask_ProgList[6] = Fuli_NewSalaryTask_completedinfo6
    g_Fuli_NewSalaryTask_ProgList[7] = Fuli_NewSalaryTask_completedinfo7
    g_Fuli_NewSalaryTask_ProgList[8] = Fuli_NewSalaryTask_completedinfo8
	
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Fuli_NewSalaryTask_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Fuli_NewSalaryTask_Frame:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[1].x	= Fuli_NewSalaryTask_Button3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= Fuli_NewSalaryTask_Button3:GetProperty("UnifiedYPosition");
	g_ButtonPos[1].tipx	= Fuli_NewSalaryTask_Button3tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].tipy	= Fuli_NewSalaryTask_Button3tips:GetProperty("UnifiedYPosition");		
	
	g_ButtonPos[2].x	= Fuli_NewSalaryTask_Button6:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= Fuli_NewSalaryTask_Button6:GetProperty("UnifiedYPosition");
	g_ButtonPos[2].tipx	= Fuli_NewSalaryTask_Button6tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].tipy	= Fuli_NewSalaryTask_Button6tips:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[3].x	= Fuli_NewSalaryTask_Button5:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= Fuli_NewSalaryTask_Button5:GetProperty("UnifiedYPosition");
	g_ButtonPos[3].tipx	= Fuli_NewSalaryTask_Button5tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].tipy	= Fuli_NewSalaryTask_Button5tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[4].x	= Fuli_NewSalaryTask_Button7:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= Fuli_NewSalaryTask_Button7:GetProperty("UnifiedYPosition");
	g_ButtonPos[4].tipx	= Fuli_NewSalaryTask_Button7tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].tipy	= Fuli_NewSalaryTask_Button7tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[5].x	= Fuli_NewSalaryTask_Button8:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= Fuli_NewSalaryTask_Button8:GetProperty("UnifiedYPosition");
	g_ButtonPos[5].tipx	= Fuli_NewSalaryTask_Button8tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].tipy	= Fuli_NewSalaryTask_Button8tips:GetProperty("UnifiedYPosition");	
	
	g_ButtonPos[6].x	= Fuli_NewSalaryTask_Button9:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].y	= Fuli_NewSalaryTask_Button9:GetProperty("UnifiedYPosition");
	g_ButtonPos[6].tipx	= Fuli_NewSalaryTask_Button9tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].tipy	= Fuli_NewSalaryTask_Button9tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[7].x	= Fuli_NewSalaryTask_Button10:GetProperty("UnifiedXPosition");
	g_ButtonPos[7].y	= Fuli_NewSalaryTask_Button10:GetProperty("UnifiedYPosition");
	g_ButtonPos[7].tipx	= Fuli_NewSalaryTask_Button10tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[7].tipy	= Fuli_NewSalaryTask_Button10tips:GetProperty("UnifiedYPosition");
	
end

-- OnEvent
function Fuli_NewSalaryTask_OnEvent(event)
    if( event == "UI_COMMAND" and tonumber(arg0) == 20170605 ) then
		--2014年5月20日：工资任务优化：start
		g_changeUI = Get_XParam_INT(3)
		if g_changeUI == 1 then
			--Fuli_NewSalaryTask_DetailDesc:ClearAllElement()
			Fuli_NewSalaryTask_DetailDesc:SetText( "#{GZYH_140526_7}" )		
			g_Fuli_NewSalaryTask_MaxValueByInedx = g_Fuli_NewSalaryTask_MaxValueByInedx_New
			Fuli_NewSalaryTask_ActList = Fuli_NewSalaryTask_ActList_New
		else
			--Fuli_NewSalaryTask_DetailDesc:ClearAllElement()
			Fuli_NewSalaryTask_DetailDesc:SetText( "#{GZGZ_120514_08}" )		
			g_Fuli_NewSalaryTask_MaxValueByInedx = g_Fuli_NewSalaryTask_MaxValueByInedx_Old
			Fuli_NewSalaryTask_ActList = Fuli_NewSalaryTask_ActList_Old		
		end
		Fuli_NewSalaryTask_DetailDesc:Show()	
		--2014年5月20日：工资任务优化：end	
		Fuli_NewSalaryTask_Init()
		local SelfFuliUnionIPos = Variable:GetVariable("SelfFuliUIPos")
		if( SelfFuliUnionIPos ~= nil) then
			Fuli_NewSalaryTask_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
		end
			
		this:Show()
	elseif( event == "ADJEST_UI_POS" ) then
		Fuli_NewSalaryTask_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Fuli_NewSalaryTask_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Fuli_NewSalaryTask_OnClosed()
	elseif event == "OPEN_NEWSALARYTASK" then
		if(tonumber(arg0) == 0) then
			Fuli_NewSalaryTask_ResetPos()
		else
			Fuli_NewSalaryTask_SetLastPos()
		end
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AskFuliSalaryTaskData")
		Set_XSCRIPT_ScriptID(889855)
		Set_XSCRIPT_Parameter(0, 0); --不是春节版本
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif tonumber(arg0) == 8889072 then
		nCharCreateDate = Get_XParam_INT( 8 );
		g_bIsNewServerGiftsForLevelUpValid = Get_XParam_INT( 9 );
	end

end

--================================================
-- 界面的默认相对位置
--================================================
function Fuli_NewSalaryTask_ResetPos()
	Fuli_NewSalaryTask_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Fuli_NewSalaryTask_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Fuli_NewSalaryTask_SetLastPos()
	local SelfFuliUnionIPos = Variable:GetVariable("SelfFuliUIPos")
	if( SelfFuliUnionIPos ~= nil) then
	    Fuli_NewSalaryTask_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
	end
end

function Fuli_NewSalaryTask_Init()
    local stData1 = Get_XParam_INT( 1 )
	local stData2 = Get_XParam_INT( 2 )

    local salaryLevel = math.floor( stData1 / g_Fuli_NewSalaryTask_Value_Count )
    if salaryLevel <= 0 then
        salaryLevel = 1
    end

	if g_changeUI == 1 then
		Fuli_NewSalaryTask_thelevel:SetText( g_Fuli_NewSalaryTask_Level_Desc_New[salaryLevel] )
	else
		Fuli_NewSalaryTask_thelevel:SetText( g_Fuli_NewSalaryTask_Level_Desc_Old[salaryLevel] )
	end
	
    --- tempData[1-8] 存放的是当前的任务[1-8]计数
	local tempData = {}
	local nIndex = 0
	for i = 1, 4 do
		nIndex =  nIndex + 1
		tempData[nIndex] = math.mod( stData1, 100 ) 
		stData1 = math.floor( stData1 / 100 )
	end
	
	for i = 1, 4 do
		nIndex =  nIndex + 1
		tempData[nIndex] = math.mod( stData2, 100 ) 
		stData2 = math.floor( stData2 / 100 )
	end

    for i = 1, 8 do
        --- 如果任务已经完成了, 设置图标
        if tempData[i] == g_Fuli_NewSalaryTask_MaxValueByInedx[salaryLevel][i] then
            g_Fuli_NewSalaryTask_ImageList[i]:SetProperty("Image", Fuli_NewSalaryTask_ActList[salaryLevel][i].eImage );
        else
            g_Fuli_NewSalaryTask_ImageList[i]:SetProperty("Image", Fuli_NewSalaryTask_ActList[salaryLevel][i].sImage );
        end

        --- 设置任务名称
        g_Fuli_NewSalaryTask_NameList[i]:SetText( Fuli_NewSalaryTask_ActList[salaryLevel][i].name )

        --- 设置完成信息
        g_Fuli_NewSalaryTask_ProgList[i]:SetText( tostring( tempData[i] )..Fuli_NewSalaryTask_ActList[salaryLevel][i].prog )

        --- 设置ToolTips
        g_Fuli_NewSalaryTask_ButtonList[i]:SetToolTip( Fuli_NewSalaryTask_ActList[salaryLevel][i].tip )
    end

	local text1 = ScriptGlobal_Format("#{FLJM_170527_06}", Get_XParam_INT( 4 ))
	Fuli_NewSalaryTask_Text:SetText( text1 )
	--local text2 = ScriptGlobal_Format("#{FLJM_170527_07}", Get_XParam_INT( 5 ))
	--Fuli_NewSalaryTask_Text1:SetText( text2 )
	
	local nSalaryTask = 2
	local nShaoDang = 3
	local nOneDay = 4
	local nHuiGui 			= 5
	local nSuperSave		= 6
	local nZhanLing = 7
		
	-- 角色创建日期
	if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 ) then
		Fuli_NewSalaryTask_Button3 : Hide();
		
		nSalaryTask = nSalaryTask - 1
		nShaoDang = nShaoDang-1
		nOneDay = nOneDay-1
		nHuiGui   = nHuiGui - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
	--	return
	else
		Fuli_NewSalaryTask_Button3 : Show();
			
	end
	
	local nLevel = Player:GetLevel();
	if ( nLevel < 35 ) then
		Fuli_NewSalaryTask_Button6:Hide()
		nSalaryTask = - 1
		nShaoDang = nShaoDang-1
		nOneDay = nOneDay-1
		nHuiGui   = nHuiGui - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
	else
		Fuli_NewSalaryTask_Button6:Show()
	end
	
	Fuli_NewSalaryTask_Button5:Show()
	if ( nLevel < 60 ) then
		Fuli_NewSalaryTask_Button5:Hide()
		nShaoDang = -1
		nOneDay = nOneDay-1
		nHuiGui   = nHuiGui - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
	end
		
	nOneDay = -1
	if nOneDay == -1  then
		nHuiGui   = nHuiGui - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
		Fuli_NewSalaryTask_Button7:Hide()
	end

	-- 回归好礼	
	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		Fuli_NewSalaryTask_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		Fuli_NewSalaryTask_Button8 : Hide()
		nHuiGui   =  - 1
		nSuperSave = nSuperSave -1 
		nZhanLing = nZhanLing -1
	end
	
	-- 累充
	if DataPool:Lua_GetUpdateTipsFlag( 3 ) == 1 then
		Fuli_NewSalaryTask_Button9 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 3 ) == 0 then
		Fuli_NewSalaryTask_Button9 : Hide()
		nSuperSaveUp =-1; 
		nZhanLing = nZhanLing -1
	end

	Fuli_NewSalaryTask_Button10:Show()
		if ( nLevel < 30 ) then
			Fuli_NewSalaryTask_Button10:Hide()
			nZhanLing = nZhanLing -1
		end
	
	
	if nSalaryTask ~= -1 then
		Fuli_NewSalaryTask_Button6:SetProperty("UnifiedXPosition", g_ButtonPos[nSalaryTask].x);
		Fuli_NewSalaryTask_Button6:SetProperty("UnifiedYPosition", g_ButtonPos[nSalaryTask].y);
		Fuli_NewSalaryTask_Button6tips:SetProperty("UnifiedXPosition", g_ButtonPos[nSalaryTask].tipx);
		Fuli_NewSalaryTask_Button6tips:SetProperty("UnifiedYPosition", g_ButtonPos[nSalaryTask].tipy);
	end
	
	if nShaoDang ~= -1 then
		Fuli_NewSalaryTask_Button5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].x);
		Fuli_NewSalaryTask_Button5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].y);
		Fuli_NewSalaryTask_Button5tips:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].tipx);
		Fuli_NewSalaryTask_Button5tips:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].tipy);
		
	end
	
	if nOneDay ~= -1 then
		Fuli_NewSalaryTask_Button7:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].x);
		Fuli_NewSalaryTask_Button7:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].y);
		Fuli_NewSalaryTask_Button7tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].tipx);
		Fuli_NewSalaryTask_Button7tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].tipy);
		
	end	
	
	if nHuiGui ~= -1 then
		Fuli_NewSalaryTask_Button8:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].x);
		Fuli_NewSalaryTask_Button8:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].y);
		Fuli_NewSalaryTask_Button8tips:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].tipx);
		Fuli_NewSalaryTask_Button8tips:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].tipy);
	end
	
	if nSuperSave ~= -1 then
		Fuli_NewSalaryTask_Button9:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].x);
		Fuli_NewSalaryTask_Button9:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].y);
		Fuli_NewSalaryTask_Button9tips:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].tipx);
		Fuli_NewSalaryTask_Button9tips:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].tipy);
	end

	if nZhanLing ~= -1 then
		Fuli_NewSalaryTask_Button10:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].x);
		Fuli_NewSalaryTask_Button10:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].y);
		Fuli_NewSalaryTask_Button10tips:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].tipx);
		Fuli_NewSalaryTask_Button10tips:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].tipy);
	end
	
	Fuli_NewSalaryTask_Button1:SetCheck(0)
	Fuli_NewSalaryTask_Button2:SetCheck(0)
	Fuli_NewSalaryTask_Button3:SetCheck(0)
	Fuli_NewSalaryTask_Button5:SetCheck(0)
	Fuli_NewSalaryTask_Button6:SetCheck(1)
	Fuli_NewSalaryTask_Button7:SetCheck(0)
	Fuli_NewSalaryTask_Button8:SetCheck(0)
	Fuli_NewSalaryTask_Button9:SetCheck(0)
	
	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		Fuli_NewSalaryTask_Button7tips : Hide()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		Fuli_NewSalaryTask_Button7tips : Hide()
	end
	

	--刷新红点
	if DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 then
		Fuli_NewSalaryTask_Button1tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		Fuli_NewSalaryTask_Button1tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		Fuli_NewSalaryTask_Button2tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		Fuli_NewSalaryTask_Button2tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
		if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 )then
			DataPool:Lua_SetRedPointInUIShow(39, 0)
			Fuli_NewSalaryTask_Button3tips : Hide()
		else
			Fuli_NewSalaryTask_Button3tips : Show()
		end
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		Fuli_NewSalaryTask_Button3tips : Hide()
	end
	
	if DataPool:Lua_GetDailySeckillFlag() == 1 then
		Fuli_NewSalaryTask_Button5tips : Show()
	else
		Fuli_NewSalaryTask_Button5tips : Hide()
	end
	--Fuli_NewSalaryTask_Button5tips : Hide()
	Fuli_NewSalaryTask_Button6tips : Hide()
	
	
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		Fuli_NewSalaryTask_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		Fuli_NewSalaryTask_Button8tips : Hide()		
	end	
	
	if DataPool:Lua_GetUpdateTipsFlag( 4 ) == 1 then
		Fuli_NewSalaryTask_Button9tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 4 ) == 0 then
		Fuli_NewSalaryTask_Button9tips : Hide()
	end

	if DataPool:Lua_GetUpdateTipsFlag( 5 ) == 1 then
		Fuli_NewSalaryTask_Button10tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 5 ) == 0 then
		Fuli_NewSalaryTask_Button10tips : Hide()
	end
	
    return
end

function Fuli_NewSalaryTask_OnClosed()
    this:Hide()
    return
end

function Fuli_NewSalaryTask_Button1_Click()
	OpenMonthlySign(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_NewSalaryTask_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_NewSalaryTask_Button2_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end
	
	OpenStrongRoadDiaoWen(1)
	
	Variable:SetVariable("SelfFuliUIPos", Fuli_NewSalaryTask_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_NewSalaryTask_Button3_Click()
	OpenQianKunDai(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_NewSalaryTask_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_NewSalaryTask_Button4_Click()

end

function Fuli_NewSalaryTask_Button5_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 60 ) then
		PushDebugMessage("#{JFRW_170217_4}")
		return
	end
	
	--Clear_XSCRIPT()
	--	Set_XSCRIPT_Function_Name("OpenDailyFuBen")
	--	Set_XSCRIPT_ScriptID(892428)
	--	Set_XSCRIPT_Parameter(0,0);
	--	Set_XSCRIPT_ParamCount(1)
	--Send_XSCRIPT()
	
	OpenZhaoHui(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_NewSalaryTask_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_NewSalaryTask_Button6_Click()
	
end

function Fuli_NewSalaryTask_Button7_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end
	Variable:SetVariable("SelfFuliUIPos", Fuli_NewSalaryTask_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_NewSalaryTask_Button8_Click()
	OpenHuiGui(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_NewSalaryTask_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_NewSalaryTask_Button9_Click()
	OpenSuperSaveUp(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_NewSalaryTask_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_NewSalaryTask_Button10_Click()
	local nLevel = Player:GetLevel();
	if( nLevel < 30 ) then
		PushDebugMessage("#{TLZL_190802_03}")	
		return
	end
	OpenZhanLing(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_NewSalaryTask_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_NewSalaryTask_Bk_Help_Click()
	--PushEvent("OPEN_QUESTFALSE","Fuli_NewSalaryTask")
	PushEvent("OPEN_SWEEPPAGE_QUEST", "Fuli_NewSalaryTask", g_changeUI)
end