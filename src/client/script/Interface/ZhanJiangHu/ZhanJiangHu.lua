--战江湖界面
-- !!!reloadscript =ZhanJiangHu
local g_ZhanJiangHu_Frame_UnifiedXPosition
local g_ZhanJiangHu_Frame_UnifiedYPosition

local g_ZhanJiangHu_BeginTime = 20260224
local g_ZhanJiangHu_EndTime = 20260303

local g_ZhanJiangHu_DataRefreshTime = 0

--2019年
local g_ZhanJiangHu_EventId2Data = 
{	
	[1] = 	{Len=12,Start = 0},   --累计活跃度
	[2] = 	{Len=5,Start = 12},	 --与好友或帮会成员完成指定副本
	[3] = 	{Len=1,Start = 17},	 --在帮会频道立下新年宏愿
	[4] = 	{Len=4,Start = 18},	 --累计领取%s0次庙会游戏奖励。 
	[5] = 	{Len=4,Start = 22},	 
	[6] = 	{Len=10,Start = 26},	 --累计获得帮会贡献点数
	[7] = 	{Len=4,Start = 36},	 --累计完成%s0次戍卫帮会
	[8] = 	{Len=2,Start = 40},   --累计完成%s0次帮会疑踪
	[9] = 	{Len=5,Start = 42},   
	[10] = 	{Len=1,Start = 47},	 --参与1次任意难度凤凰陵墓。 N/1 ----------2025新增
	[11] =	{Len=4,Start = 48},	 
	[12] = 	{Len=7,Start = 52},   
	[13] = 	{Len=2,Start = 59},	 
	[14] = 	{Len=6,Start = 61},	 --累计刷新%s0次百戏集市
	[15] = 	{Len=4,Start = 67},	 --杯酒尽江湖
}

local g_ZhanJiangHu_HongFuSocreDataIndex = 12 --2019年
local g_ZhanJiangHu_HongFuMaxValue = 100

--非卡级服
local g_ZhanJiangHu_AhieveIdData = 
{
	--2.5
	[1]  = 	{EventId=1,	NeedValue = 150,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},   --累计获得%s0点活跃值。   N/150
	[2]  = 	{EventId=2,	NeedValue = 2,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_180129_151}",},	 --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/2
	[3]  = 	{EventId=6,	NeedValue = 100,Pos={},Tips="#{CJYJ_180112_100}",Desc="#{CJYJ_180116_107}",ToolTips="#{CJYJ_180129_152}",},	 --累计获得%s0点帮会贡献度。   N/100
	[4]  = 	{EventId=10,NeedValue = 1,	Pos={},Tips="#{CJYJ_1211125_25}",Desc="#{CJYJ_1211125_26}",ToolTips="#{CJYJ_1211125_27}",},	 --领取1次任意难度凤凰陵墓活动的奖励。 N/1
	[5]  = 	{EventId=3,	NeedValue = 1,	Pos={},Tips="",Desc="#{CJYJ_180116_106}",ToolTips="#{CJYJ_180129_158}",},	 --在帮会频道发送新年宏愿。   N/1
	--2.6
	[6]  = 	{EventId=1,	NeedValue = 300,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},	 --累计获得%s0点活跃值。  N/300
	[7]  = 	{EventId=2,	NeedValue = 4,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_180129_151}",},	 --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/4	
	[8] =  {EventId=7,	NeedValue = 1,	Pos={sceneId=-1,x=66,z=135,npcName="戴三金"},Tips="",Desc="#{CJYJ_180116_110}",ToolTips="#{CJYJ_180129_155}",},	 --累计完成%s0次戍卫帮会。  N/1
	[9] = 	{EventId=14,NeedValue = 10,	Pos={sceneId=0,x=282,z=348,npcName="广妙辉"},Tips="",Desc="#{CJYJ_180116_111}",ToolTips="#{CJYJ_180129_161}",},	 --累计刷新%s0次百戏集市。 N/10
	[10] = 	{EventId=4,	NeedValue = 1,	Pos={},Tips="#{CJYJ_180129_184}",Desc="#{CJYJ_180129_171}",ToolTips="#{CJYJ_180129_175}",},	 --累计领取%s0次庙会游戏奖励。 N/1
	--2.7
	[11] = 	{EventId=1,	NeedValue = 500,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},	 --累计获得%s0点活跃值。  N/500
	[12] = 	{EventId=2,	NeedValue = 6,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_180129_151}",},	 --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/6
	[13] = 	{EventId=8,NeedValue = 2,	Pos={sceneId=-1,x=66,z=135,npcName="戴三金"},Tips="",Desc="#{CJYJ_180116_115}",ToolTips="#{CJYJ_180129_163}",},    --累计完成%s0次帮会疑踪。   N/2	
	[14] = 	{EventId=4,	NeedValue = 3,	Pos={},Tips="#{CJYJ_180129_184}",Desc="#{CJYJ_180129_171}",ToolTips="#{CJYJ_180129_175}",},	 --累计领取%s0次庙会游戏奖励。 N/2
	[15] = 	{EventId=15,NeedValue = 2,	Pos={},Tips="#{CJYJ_1211125_18}",Desc="#{CJYJ_1211125_01}",ToolTips="#{CJYJ_1211125_02}",},	 --累计对好友进行%s0次斟酒  N/2

	--2.8
	[16] = 	{EventId=1,	NeedValue = 750,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},   --累计获得%s0点活跃值。  N/750
	[17] = 	{EventId=2,	NeedValue = 8,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_180129_151}",},    --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/8
	[18] = 	{EventId=6,	NeedValue = 300,Pos={},Tips="#{CJYJ_180112_100}",Desc="#{CJYJ_180116_107}",ToolTips="#{CJYJ_180129_152}",},	 --累计获得%s0点帮会贡献度。   N/300
	[19] = 	{EventId=14,NeedValue = 20,	Pos={sceneId=0,x=282,z=348,npcName="广妙辉"},Tips="",Desc="#{CJYJ_180129_173}",ToolTips="#{CJYJ_180129_177}",},    --累计刷新%s0次百戏集市。 N/20
	[20] = 	{EventId=4,	NeedValue = 6,	Pos={},Tips="#{CJYJ_180129_184}",Desc="#{CJYJ_180129_171}",ToolTips="#{CJYJ_180129_175}",},	 --累计领取%s0次庙会游戏奖励。 N/3
	--2.9
	[21] = 	{EventId=1,NeedValue = 1050,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},   --累计获得%s0点活跃值。  N/1050
	[22] = 	{EventId=2,	NeedValue = 10,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_180129_151}",},    --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/10
	[23] = 	{EventId=6,	NeedValue = 400,Pos={},Tips="#{CJYJ_180112_100}",Desc="#{CJYJ_180116_107}",ToolTips="#{CJYJ_180129_152}",},   --活动期间累计获得帮会贡献度。   N/400
	[24] = 	{EventId=4,	NeedValue = 9,	Pos={},Tips="#{CJYJ_180129_184}",Desc="#{CJYJ_180129_171}",ToolTips="#{CJYJ_180129_175}",},	 --累计领取%s0次庙会游戏奖励。 N/4
	[25] = 	{EventId=15,NeedValue = 3,	Pos={},Tips="#{CJYJ_1211125_18}",Desc="#{CJYJ_1211125_01}",ToolTips="#{CJYJ_1211125_02}",},	 --累计对好友进行%s0次斟酒  N/3
	
	--2.10
	[26] = 	{EventId=1,NeedValue = 1400,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},  --累计获得%s0点活跃值。  N/1400
	[27] = 	{EventId=2,	NeedValue = 12,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_180129_151}",},    --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/12
	[28] = 	{EventId=7,	NeedValue = 2,	Pos={sceneId=-1,x=66,z=135,npcName="戴三金"},Tips="",Desc="#{CJYJ_180116_110}",ToolTips="#{CJYJ_180129_155}",},     --累计完成%s0次戍卫帮会。 N/2
	[29] = 	{EventId=4,	NeedValue = 12,	Pos={},Tips="#{CJYJ_180129_184}",Desc="#{CJYJ_180129_171}",ToolTips="#{CJYJ_180129_175}",},	 --累计领取%s0次庙会游戏奖励。 N/5	
	[30] = 	{EventId=15, NeedValue = 4,	Pos={},Tips="#{CJYJ_1211125_18}",Desc="#{CJYJ_1211125_01}",ToolTips="#{CJYJ_1211125_02}",},   --累计对好友进行%s0次斟酒  N/4	
	--2.11
	[31] = 	{EventId=1,NeedValue = 1800,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},   --累计获得%s0点活跃值。  N/1800
	[32] = 	{EventId=2,	NeedValue = 14,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_180129_151}",},    --与本服互为好友或本帮会成员共同完成%s0次指定副本。 N/14
	[33] = 	{EventId=6,	NeedValue = 600,Pos={},Tips="#{CJYJ_180112_100}",Desc="#{CJYJ_180116_107}",ToolTips="#{CJYJ_180129_152}",},   --累计获得%s0点帮会贡献度。 N/600
	[34] = 	{EventId=15,NeedValue = 5,	Pos={},Tips="#{CJYJ_1211125_18}",Desc="#{CJYJ_1211125_01}",ToolTips="#{CJYJ_1211125_02}",},	 --累计完成%s0次杯酒尽江湖。  N/4
	[35] = 	{EventId=14,NeedValue = 30,	Pos={sceneId=0,x=282,z=348,npcName="广妙辉"},Tips="",Desc="#{CJYJ_180129_173}",ToolTips="#{CJYJ_180129_177}",},    --累计刷新%s0次百戏集市。 N/30

	--2.12
	[36] = 	{EventId=1,NeedValue = 2250,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},   --累计获得%s0点活跃值。  N/2250
	[37] = 	{EventId=2,	NeedValue = 16,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_180129_151}",},    --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/16
	[38] = 	{EventId=6,	NeedValue = 700,Pos={},Tips="#{CJYJ_180112_100}",Desc="#{CJYJ_180116_107}",ToolTips="#{CJYJ_180129_152}",},    --累计获得%s0点帮会贡献度。   N/700
	[39] = 	{EventId=14,NeedValue = 40,	Pos={sceneId=0,x=282,z=348,npcName="广妙辉"},Tips="",Desc="#{CJYJ_180129_172}",ToolTips="#{CJYJ_180129_176}",},    --累计刷新%s0次百戏集市。 N/40	
	[40] = 	{EventId=4,NeedValue = 15,	Pos={},Tips="#{CJYJ_180129_184}",Desc="#{CJYJ_180129_171}",ToolTips="#{CJYJ_180129_175}",},	 --累计领取%s0次庙会游戏奖励。 N/6	

}

--卡级服
local g_ZhanJiangHu_AhieveIdData_KaJi = 
{
	--2.5
	[1]  = 	{EventId=1,	NeedValue = 150,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},   --累计获得%s0点活跃值。   N/150
	[2]  = 	{EventId=2,	NeedValue = 1,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_1211125_07}",},	 --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/1
	[3]  = 	{EventId=6,	NeedValue = 50,Pos={},Tips="#{CJYJ_180112_100}",Desc="#{CJYJ_180116_107}",ToolTips="#{CJYJ_180129_152}",},	 --累计获得%s0点帮会贡献度。   N/50
	[4]  = 	{EventId=10,NeedValue = 1,	Pos={},Tips="#{CJYJ_1211125_25}",Desc="#{CJYJ_1211125_26}",ToolTips="#{CJYJ_1211125_27}",},	 --领取1次任意难度凤凰陵墓活动的奖励。 N/1
	[5]  = 	{EventId=3,	NeedValue = 1,	Pos={},Tips="",Desc="#{CJYJ_180116_106}",ToolTips="#{CJYJ_180129_158}",},	 --在帮会频道发送新年宏愿。   N/1

	--2.6
	[6]  = 	{EventId=1,	NeedValue = 300,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},	 --累计获得%s0点活跃值。  N/300
	[7]  = 	{EventId=2,	NeedValue = 2,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_1211125_07}",},	 --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/2	
	[8] =  	{EventId=7,	NeedValue = 1,	Pos={sceneId=-1,x=66,z=135,npcName="戴三金"},Tips="",Desc="#{CJYJ_180116_110}",ToolTips="#{CJYJ_180129_155}",},	 --累计完成%s0次戍卫帮会。  N/1
	[9] = 	{EventId=14,NeedValue = 10,	Pos={sceneId=0,x=282,z=348,npcName="广妙辉"},Tips="",Desc="#{CJYJ_180116_111}",ToolTips="#{CJYJ_180129_161}",},	 --累计刷新%s0次百戏集市。 N/10
	[10] = 	{EventId=4,	NeedValue = 1,	Pos={},Tips="#{CJYJ_180129_184}",Desc="#{CJYJ_180129_171}",ToolTips="#{CJYJ_180129_175}",},	 --累计领取%s0次庙会游戏奖励。 N/1

	--2.7
	[11] = 	{EventId=1,	NeedValue = 450,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},	 --累计获得%s0点活跃值。  N/450
	[12] = 	{EventId=2,	NeedValue = 3,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_1211125_07}",},	 --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/3
	[13] = 	{EventId=8,NeedValue = 1,	Pos={sceneId=-1,x=66,z=135,npcName="戴三金"},Tips="",Desc="#{CJYJ_180116_115}",ToolTips="#{CJYJ_180129_163}",},    --累计完成%s0次帮会疑踪。   N/1	
	[14] = 	{EventId=4,	NeedValue = 3,	Pos={},Tips="#{CJYJ_180129_184}",Desc="#{CJYJ_180129_171}",ToolTips="#{CJYJ_180129_175}",},	 --累计领取%s0次庙会游戏奖励。 N/2
	[15] = 	{EventId=15,NeedValue = 2,	Pos={},Tips="#{CJYJ_1211125_18}",Desc="#{CJYJ_1211125_01}",ToolTips="#{CJYJ_1211125_02}",},	 --累计对好友进行%s0次斟酒  N/2
	
	--2.8
	[16] = 	{EventId=1,	NeedValue = 600,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},   --累计获得%s0点活跃值。  N/600
	[17] = 	{EventId=2,	NeedValue = 4,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_1211125_07}",},    --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/4
	[18] = 	{EventId=6,	NeedValue = 150,Pos={},Tips="#{CJYJ_180112_100}",Desc="#{CJYJ_180116_107}",ToolTips="#{CJYJ_180129_152}",},	 --累计获得%s0点帮会贡献度。   N/150
	[19] = 	{EventId=14,NeedValue = 20,	Pos={sceneId=0,x=282,z=348,npcName="广妙辉"},Tips="",Desc="#{CJYJ_180129_172}",ToolTips="#{CJYJ_180129_176}",},    --累计刷新%s0次百戏集市。 N/20
	[20] = 	{EventId=4,	NeedValue = 6,	Pos={},Tips="#{CJYJ_180129_184}",Desc="#{CJYJ_180129_171}",ToolTips="#{CJYJ_180129_175}",},	 --累计领取%s0次庙会游戏奖励。 N/3

	--2.9
	[21] = 	{EventId=1,NeedValue = 750,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},   --累计获得%s0点活跃值。  N/750
	[22] = 	{EventId=2,	NeedValue = 5,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_1211125_07}",},    --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/5
	[23] = 	{EventId=6,	NeedValue = 200,Pos={},Tips="#{CJYJ_180112_100}",Desc="#{CJYJ_180116_107}",ToolTips="#{CJYJ_180129_152}",},   --活动期间累计获得帮会贡献度。   N/200
	[24] = 	{EventId=4,	NeedValue = 9,	Pos={},Tips="#{CJYJ_180129_184}",Desc="#{CJYJ_180129_171}",ToolTips="#{CJYJ_180129_175}",},	 --累计领取%s0次庙会游戏奖励。 N/4
	[25] = 	{EventId=15,NeedValue = 3,	Pos={},Tips="#{CJYJ_1211125_18}",Desc="#{CJYJ_1211125_01}",ToolTips="#{CJYJ_1211125_02}",},	 --累计对好友进行%s0次斟酒  N/3
		
	--2.10
	[26] = 	{EventId=1,NeedValue = 900,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},  --累计获得%s0点活跃值。  N/900
	[27] = 	{EventId=2,	NeedValue = 6,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_1211125_07}",},    --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/6
	[28] = 	{EventId=7,	NeedValue = 2,	Pos={sceneId=-1,x=66,z=135,npcName="戴三金"},Tips="",Desc="#{CJYJ_180116_110}",ToolTips="#{CJYJ_180129_155}",},     --累计完成%s0次戍卫帮会。 N/2
	[29] = 	{EventId=4,	NeedValue = 12,	Pos={},Tips="#{CJYJ_180129_184}",Desc="#{CJYJ_180129_171}",ToolTips="#{CJYJ_180129_175}",},	 --累计领取%s0次庙会游戏奖励。 N/5
	[30] = 	{EventId=14,NeedValue = 30,	Pos={sceneId=0,x=282,z=348,npcName="广妙辉"},Tips="",Desc="#{CJYJ_180129_172}",ToolTips="#{CJYJ_180129_176}",},	 --累计刷新%s0次百戏集市。 N/30
		
	--2.11
	[31] = 	{EventId=1,NeedValue = 1050,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},   --累计获得%s0点活跃值。  N/1050
	[32] = 	{EventId=2,	NeedValue = 7,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_1211125_07}",},    --与本服互为好友或本帮会成员共同完成%s0次指定副本。 N/7
	[33] = 	{EventId=6,	NeedValue = 300,Pos={},Tips="#{CJYJ_180112_100}",Desc="#{CJYJ_180116_107}",ToolTips="#{CJYJ_180129_152}",},   --累计获得%s0点帮会贡献度。 N/300
	[34] = 	{EventId=4,	NeedValue = 13,	Pos={},Tips="#{CJYJ_180129_184}",Desc="#{CJYJ_180129_171}",ToolTips="#{CJYJ_180129_175}",},	 --累计领取%s0次庙会游戏奖励。 N/6
	[35] = 	{EventId=15,NeedValue = 4,	Pos={},Tips="#{CJYJ_1211125_18}",Desc="#{CJYJ_1211125_01}",ToolTips="#{CJYJ_1211125_02}",},	 --累计对好友进行%s0次斟酒  N/4
			
	--2.12
	[36] = 	{EventId=1,NeedValue = 1200,Pos={},Tips="#{CJYJ_180112_98}",Desc="#{CJYJ_180116_104}",ToolTips="#{CJYJ_180129_150}",},   --累计获得%s0点活跃值。  N/1200
	[37] = 	{EventId=2,	NeedValue = 8,	Pos={},Tips="#{CJYJ_180112_99}",Desc="#{CJYJ_180116_105}",ToolTips="#{CJYJ_1211125_07}",},    --与本服互为好友或本帮会成员共同完成%s0次指定副本。  N/8
	[38] = 	{EventId=6,	NeedValue = 350,Pos={},Tips="#{CJYJ_180112_100}",Desc="#{CJYJ_180116_107}",ToolTips="#{CJYJ_180129_152}",},    --累计获得%s0点帮会贡献度。   N/350
	[39] = 	{EventId=4,	NeedValue = 15,	Pos={},Tips="#{CJYJ_180129_184}",Desc="#{CJYJ_180129_171}",ToolTips="#{CJYJ_180129_175}",},	 --累计领取%s0次庙会游戏奖励。N/7
	[40] = 	{EventId=14,NeedValue = 40,	Pos={sceneId=0,x=282,z=348,npcName="广妙辉"},Tips="",Desc="#{CJYJ_180129_172}",ToolTips="#{CJYJ_180129_176}",},	 --累计刷新%s0次百戏集市。 N/40	

}

local g_ZhanJiangHu_CurPage = 0

local g_ZhanJiangHu_EventDataPool = {}
local g_ZhanJiangHu_RewardStatePool = {}
local g_ZhanJiangHu_HongFuDianStatePool = {}
--活动重开OpenDay 需要对应修改

--非卡级服
local g_ZhanJiangHu_PageAhieve = 
{
	[1] = {AchieveCount = 5,OpenDay=20260224,RewardIcon=39921374,AchieveList={1,2,3,4,5,},RewardBit=1,Desc="#{CJYJ_180116_131}"},
	[2] = {AchieveCount = 5,OpenDay=20260225,RewardIcon=39921374,AchieveList={6,7,8,9,10,},RewardBit=2,Desc="#{CJYJ_180116_131}"},
	[3] = {AchieveCount = 5,OpenDay=20260226,RewardIcon=39921374,AchieveList={11,12,13,14,15,},RewardBit=3,Desc="#{CJYJ_180116_131}"},
	[4] = {AchieveCount = 5,OpenDay=20260227,RewardIcon=39921374,AchieveList={16,17,18,19,20,},RewardBit=4,Desc="#{CJYJ_180116_131}"},
	[5] = {AchieveCount = 5,OpenDay=20260228,RewardIcon=39921374,AchieveList={21,22,23,24,25,},RewardBit=5,Desc="#{CJYJ_180116_131}"},
	[6] = {AchieveCount = 5,OpenDay=20260301,RewardIcon=39921374,AchieveList={26,27,28,29,30,},RewardBit=6,Desc="#{CJYJ_180116_131}"},
	[7] = {AchieveCount = 5,OpenDay=20260302,RewardIcon=39921374,AchieveList={31,32,33,34,35,},RewardBit=7,Desc="#{CJYJ_180116_131}"},
	[8] = {AchieveCount = 5,OpenDay=20260303,RewardIcon=39921374,AchieveList={36,37,38,39,40,},RewardBit=8,Desc="#{CJYJ_180116_131}"},
	--RewardBit=9 鸿福奖励1
	--RewardBit=10 鸿福奖励2
}

--卡级服
local g_ZhanJiangHu_PageAhieve_KaJi = 
{
	[1] = {AchieveCount = 5,OpenDay=20260224,RewardIcon=39923679,AchieveList={1,2,3,4,5,},RewardBit=1,Desc="#{CJYJ_180116_131}"},
	[2] = {AchieveCount = 5,OpenDay=20260225,RewardIcon=39923679,AchieveList={6,7,8,9,10,},RewardBit=2,Desc="#{CJYJ_180116_131}"},
	[3] = {AchieveCount = 5,OpenDay=20260226,RewardIcon=39923679,AchieveList={11,12,13,14,15,},RewardBit=3,Desc="#{CJYJ_180116_131}"},
	[4] = {AchieveCount = 5,OpenDay=20260227,RewardIcon=39923679,AchieveList={16,17,18,19,20,},RewardBit=4,Desc="#{CJYJ_180116_131}"},
	[5] = {AchieveCount = 5,OpenDay=20260228,RewardIcon=39923679,AchieveList={21,22,23,24,25,},RewardBit=5,Desc="#{CJYJ_180116_131}"},
	[6] = {AchieveCount = 5,OpenDay=20260301,RewardIcon=39923679,AchieveList={26,27,28,29,30,},RewardBit=6,Desc="#{CJYJ_180116_131}"},
	[7] = {AchieveCount = 5,OpenDay=20260302,RewardIcon=39923679,AchieveList={31,32,33,34,35,},RewardBit=7,Desc="#{CJYJ_180116_131}"},
	[8] = {AchieveCount = 5,OpenDay=20260303,RewardIcon=39923679,AchieveList={36,37,38,39,40,},RewardBit=8,Desc="#{CJYJ_180116_131}"},
	--RewardBit=9 鸿福奖励1
	--RewardBit=10 鸿福奖励2
}

--非卡级服
g_ZhanJiangHu_HongFuReward = 
{
	[1] = {NeedHongFu = 4,RewardBit=9,RewardList={id=39920980,count=1},},
	[2] = {NeedHongFu = 6,RewardBit=10,RewardList={id=39920981,count=1},},
}

--卡级服
g_ZhanJiangHu_HongFuReward_KaJi = 
{
	[1] = {NeedHongFu = 4,RewardBit=9,RewardList={id=39920462,count=1},}, --替代
	[2] = {NeedHongFu = 6,RewardBit=10,RewardList={id=39920463,count=1},}, --替代
}

g_ZhanJiangHu_HongFuButtons = {}

local g_ZhanJiangHu_FlexTips = {}
local g_ZhanJiangHu_FlexState = 
{
	[1] = 0,
	[2] = 0,
}

local g_ZhanJiangHu_PageMaxCount = 5
local g_ZhanJiangHu_MaxPage = 8

local g_ZhanJiangHu_AchieveContorl = {}
local g_ZhanJiangHu_RewardContorl = {}
local g_ZhanJiangHu_DaySwithcButon = {}
local g_ZhanJiangHu_DaySwithButtonTips = {}

--非卡级服
local g_ZhanJiangHu_HFRewardTips = 
{
	[1] = "#{CJYJ_180104_89}",
	[2] = "#{CJYJ_180104_91}",
}

--卡级服
local g_ZhanJiangHu_HFRewardTips_KaJi = 
{
	[1] = "#{CJYJ_1211125_08}",
	[2] = "#{CJYJ_1211125_17}",
}

local g_ZhanJiangHu_HongFuNum2Iamge = 
{
	[0] = "set:Sign image:Signorange_0",
	[1] = "set:Sign image:Signorange_1",
	[2] = "set:Sign image:Signorange_2",
	[3] = "set:Sign image:Signorange_3",
	[4] = "set:Sign image:Signorange_4",
	[5] = "set:Sign image:Signorange_5",
	[6] = "set:Sign image:Signorange_6",
	[7] = "set:Sign image:Signorange_7",
	[8] = "set:Sign image:Signorange_8",
	[9] = "set:Sign image:Signorange_9",
}

local g_ZhanJiangHu_MaxBit = 32

local g_ZhanJiangHu_HeXinChunDenglongMaxCount = 8
local g_ZhanJiangHu_HeXinChunHaveDenglong = 0
--===============================================
-- OnLoad()
--===============================================
function ZhanJiangHu_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)	
	this:RegisterEvent("OPEN_ZHANJIANGHU",true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("PLAYER_ENTERING_WORLD",true)
	
	this:RegisterEvent("XINCHUNYINGJING_FLEX_UPDATE",true)
end

function ZhanJiangHu_OnLoad()
	g_ZhanJiangHu_AchieveContorl = 
	{
		[1] = {Desc=ZhanJiangHu_BottomText1,Btn=ZhanJiangHu_RewardButton1,ValueText=ZhanJiangHu_BottomInfo1,Ani=ZhanJiangHu_RewardButton1Flash,Finsh=ZhanJiangHu_DianshuBk1},
		[2] = {Desc=ZhanJiangHu_BottomText2,Btn=ZhanJiangHu_RewardButton2,ValueText=ZhanJiangHu_BottomInfo2,Ani=ZhanJiangHu_RewardButton2Flash,Finsh=ZhanJiangHu_DianshuBk2},
		[3] = {Desc=ZhanJiangHu_BottomText3,Btn=ZhanJiangHu_RewardButton3,ValueText=ZhanJiangHu_BottomInfo3,Ani=ZhanJiangHu_RewardButton3Flash,Finsh=ZhanJiangHu_DianshuBk3},
		[4] = {Desc=ZhanJiangHu_BottomText4,Btn=ZhanJiangHu_RewardButton4,ValueText=ZhanJiangHu_BottomInfo4,Ani=ZhanJiangHu_RewardButton4Flash,Finsh=ZhanJiangHu_DianshuBk4},
		[5] = {Desc=ZhanJiangHu_BottomText5,Btn=ZhanJiangHu_RewardButton5,ValueText=ZhanJiangHu_BottomInfo5,Ani=ZhanJiangHu_RewardButton5Flash,Finsh=ZhanJiangHu_DianshuBk5},
	}
	g_ZhanJiangHu_RewardContorl = 
	{
		RewardIcon = ZhanJiangHu_Icon,
		Desc = ZhanJiangHu_BottomText,
		Btn = ZhanJiangHu_TodayButton,
		FlexTip = ZhanJiangHu_TodayButtonTips,
	}
	g_ZhanJiangHu_DaySwithcButon = 
	{
		[1] = ZhanJiangHu_Button1,
		[2] = ZhanJiangHu_Button2,
		[3] = ZhanJiangHu_Button3,
		[4] = ZhanJiangHu_Button4,
		[5] = ZhanJiangHu_Button5,
		[6] = ZhanJiangHu_Button6,
		[7] = ZhanJiangHu_Button7,
		[8] = ZhanJiangHu_Button8,
	}
	g_ZhanJiangHu_HongFuButtons = 
	{
		[1] = {Btn=ZhanJiangHu_WuXiangShi,Ani=ZhanJiangHu_WuXiangShiAnimate,FinshFlag=ZhanJiangHu_WuXiangShiOver,FlexTip=ZhanJiangHu_Frame_RewardButton1Tips,Btn1=ZhanJiangHu_Frame_RewardButton1},
		[2] = {Btn=ZhanJiangHu_WuXiangLingShi,Ani=ZhanJiangHu_WuXiangLingShiAnimate,FinshFlag=ZhanJiangHu_WuXiangLingShiOver,FlexTip=ZhanJiangHu_Frame_RewardButton2Tips,Btn1=ZhanJiangHu_Frame_RewardButton2},
	}
	g_ZhanJiangHu_FlexTips = 
	{
		[1] = ZhanJiangHu_FenYe1_Tips,
		[2] = ZhanJiangHu_FenYe2_Tips,
	}
	g_ZhanJiangHu_DaySwithButtonTips = 
	{
		[1] = ZhanJiangHu_Button1Tips,
		[2] = ZhanJiangHu_Button2Tips,
		[3] = ZhanJiangHu_Button3Tips,
		[4] = ZhanJiangHu_Button4Tips,
		[5] = ZhanJiangHu_Button5Tips,
		[6] = ZhanJiangHu_Button6Tips,
		[7] = ZhanJiangHu_Button7Tips,
		[8] = ZhanJiangHu_Button8Tips,
	}
	-- 保存界面的默认相对位置
	g_ZhanJiangHu_Frame_UnifiedXPosition	= ZhanJiangHu_Frame : GetProperty("UnifiedXPosition");
	g_ZhanJiangHu_Frame_UnifiedYPosition	= ZhanJiangHu_Frame : GetProperty("UnifiedYPosition");
end
--===============================================
-- OnEvent()
--===============================================
function ZhanJiangHu_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 2018010901) then
		local bOpen = Get_XParam_INT(0)
		local nCount = Get_XParam_INT(1)
		local nIndex = 2
		for i=1,nCount do
			g_ZhanJiangHu_EventDataPool[i] = Get_XParam_INT(nIndex)
			nIndex = nIndex + 1
		end
		nCount = Get_XParam_INT(nIndex)
		nIndex = nIndex + 1
		for i=1,nCount do
			g_ZhanJiangHu_RewardStatePool[i] = Get_XParam_INT(nIndex)
			nIndex = nIndex + 1
		end
		nCount = Get_XParam_INT(nIndex)
		nIndex = nIndex + 1
		for i=1,nCount do
			g_ZhanJiangHu_HongFuDianStatePool[i] = Get_XParam_INT(nIndex)
			nIndex = nIndex + 1
		end
		local nPage = g_ZhanJiangHu_CurPage
		g_ZhanJiangHu_CurPage = 0
		local bFlexFresh = ZhanJiangHu_RefreshFlexState()
		if(bOpen == 1) then
			nPage = 1
			ZhanJiangHu_FenYe1:SetCheck(0)
			ZhanJiangHu_FenYe2:SetCheck(1)
			if(IsWindowShow("HeXinChun") == true) then
				CloseWindow("HeXinChun",true)
			end
			this:Show()
		end
		ZhanJiangHu_RefreshDayButtons()
		ZhanJiangHu_SwitchPage(nPage)
		ZhanJiangHu_RefreshHongFu()
		g_ZhanJiangHu_DataRefreshTime = OSAPI:GetTickCount()
		ZhanJiangHu_KaJi_Change()
		if(bFlexFresh == 1) then 
			PushEvent("XINCHUNYINGJING_FLEX_UPDATE",2,g_ZhanJiangHu_FlexState[2])
			Lua_ShowQuickEnterPointTipByBinary(13, 2, g_ZhanJiangHu_FlexState[2])
		end
	elseif (event == "OPEN_ZHANJIANGHU") then
		local bOpen = tonumber(arg0)
		if(bOpen == 0 and this:IsVisible()) then
			ZhanJiangHu_OnHiden()
			return
		end
		if(tonumber(arg1) ~= -1 and tonumber(arg2)  ~= -1) then
			g_ZhanJiangHu_Frame_UnifiedXPosition = arg1
			g_ZhanJiangHu_Frame_UnifiedYPosition = arg2
			ZhanJiangHu_Frame_On_ResetPos()
		end
		local nCur = OSAPI:GetTickCount()
		if( (g_ZhanJiangHu_DataRefreshTime <= 0) or (nCur - g_ZhanJiangHu_DataRefreshTime >= 300000)) then
			--重新请求一次数据
			ZhanJiangHu_AskData(1)
			return
		end
		if(IsWindowShow("HeXinChun") == true) then
			CloseWindow("HeXinChun",true)
		end
		g_ZhanJiangHu_CurPage = 0
		ZhanJiangHu_FenYe1:SetCheck(0)
		ZhanJiangHu_FenYe2:SetCheck(1)
		this:Show()
		ZhanJiangHu_RefreshDayButtons()
		ZhanJiangHu_SwitchPage(1)
		ZhanJiangHu_RefreshHongFu()
		ZhanJiangHu_KaJi_Change()
		
	elseif (event == "XINCHUNYINGJING_FLEX_UPDATE") then
		if(tonumber(arg0) ~= 1 )then
			return
		end
		g_ZhanJiangHu_FlexState[1] = tonumber(arg1)
		if(this:IsVisible()) then
			ZhanJiangHu_RefreshHongFu()
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2018010601) then
		for i=1,g_ZhanJiangHu_HeXinChunDenglongMaxCount do
			local nState = Get_XParam_INT(i)
			if(nState == 1 or nState == 2) then
				g_ZhanJiangHu_HeXinChunHaveDenglong = g_ZhanJiangHu_HeXinChunHaveDenglong + 1
			end
		end
		if(this:IsVisible())then
			ZhanJiangHu_RefreshDayButtons()
		end
		
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		ZhanJiangHu_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		ZhanJiangHu_Frame_On_ResetPos()
	elseif (event == "PLAYER_ENTERING_WORLD" ) then
		ZhanJiangHu_AskData(0)
		ZhanJiangHu_OnHiden()
	end
end

--卡级服，需要替换的一些文字、图片之类的
--正常服，就默认显示xml中的了
function ZhanJiangHu_KaJi_Change()
	
	--卡级服
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(48) > 0 then
		
		--1、替换一张背景图
		ZhanJiangHu_BK1:SetImage("hexinchun06", "zhanjianghubk_new")
		
		--2、替换文字
		ZhanJiangHu_WuXiangShiText:SetText("#{CJYJ_1211125_13}")
		ZhanJiangHu_WuXiangLingShiText:SetText("#{CJYJ_1211125_14}")
		
		--3、替换tips
		ZhanJiangHu_TextImage1:SetToolTip("#{CJYJ_1211125_06}")
		ZhanJiangHu_WuXiangShi:SetToolTip("#{CJYJ_1211125_15}")
		ZhanJiangHu_Frame_RewardButton1:SetToolTip("#{CJYJ_1211125_15}")
		
		ZhanJiangHu_WuXiangLingShi:SetToolTip("#{CJYJ_1211125_16}")
		ZhanJiangHu_Frame_RewardButton2:SetToolTip("#{CJYJ_1211125_16}")

	--非卡级服
	else
		--1、替换一张背景图
		ZhanJiangHu_BK1:SetImage("hexinchun05", "zhangjianghubk1")
		
		--2、替换文字
		ZhanJiangHu_WuXiangShiText:SetText("#{CJYJ_180124_139}")
		ZhanJiangHu_WuXiangLingShiText:SetText("#{CJYJ_180124_140}")
		
		--3、替换tips
		ZhanJiangHu_TextImage1:SetToolTip("#{CJYJ_180104_60}")
		ZhanJiangHu_WuXiangShi:SetToolTip("#{CJYJ_180104_56}")
		ZhanJiangHu_Frame_RewardButton1:SetToolTip("#{CJYJ_180104_56}")	
	end

end

--===============================================
-- OnHiden
--===============================================
function ZhanJiangHu_OnHiden()
	this:Hide()
end

function ZhanJiangHu_Quit_Clicked()
	ZhanJiangHu_OnHiden()
end

function ZhanJiangHu_RefreshHongFu()   --这个看看是否需要改
	
	--卡级服
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(48) > 0 then
	
		local nHongFu = ZhanJiangHu_GetHongFuValue()
		local nHongFuTemp = nHongFu
		local aBit = math.mod(nHongFuTemp,10)
		nHongFuTemp = math.floor(nHongFuTemp/10)
		local Ten = math.mod(nHongFuTemp,10)
		nHongFuTemp = math.floor(nHongFuTemp/10)
		local Hundreds = math.mod(nHongFuTemp,10)
		ZhanJiangHu_TextImage2:SetProperty("Image","")
		ZhanJiangHu_TextImage3:SetProperty("Image","")
		ZhanJiangHu_TextImage4:SetProperty("Image","")
		if(g_ZhanJiangHu_HongFuNum2Iamge[aBit] ~= nil) then
			ZhanJiangHu_TextImage4:SetProperty("Image",g_ZhanJiangHu_HongFuNum2Iamge[aBit])
		end
		if(Hundreds ~= 0 or Ten ~= 0) then
			if(g_ZhanJiangHu_HongFuNum2Iamge[Ten] ~= nil) then
				ZhanJiangHu_TextImage3:SetProperty("Image",g_ZhanJiangHu_HongFuNum2Iamge[Ten])
			end
		end
		if(Hundreds ~= 0 ) then
			if(g_ZhanJiangHu_HongFuNum2Iamge[Hundreds] ~= nil) then
				ZhanJiangHu_TextImage2:SetProperty("Image",g_ZhanJiangHu_HongFuNum2Iamge[Hundreds])
			end
		end
		--ZhanJiangHu_PresentDianshu:SetText("#{CJYJ_180104_55}"..":"..tostring(nHongFu))
		for i=1,table.getn(g_ZhanJiangHu_HongFuButtons) do
			local state = ZhanJiangHu_GetHFRewardState(i)
			if(state == 1) then
				g_ZhanJiangHu_HongFuButtons[i].FinshFlag:Hide()
				g_ZhanJiangHu_HongFuButtons[i].Btn:Disable()
				g_ZhanJiangHu_HongFuButtons[i].Btn1:Disable()
			else
				g_ZhanJiangHu_HongFuButtons[i].FinshFlag:Hide()
				g_ZhanJiangHu_HongFuButtons[i].Btn:Enable()
				g_ZhanJiangHu_HongFuButtons[i].Btn1:Enable()
			end
			if(nHongFu >= g_ZhanJiangHu_HongFuReward_KaJi[i].NeedHongFu and state == 0) then
				g_ZhanJiangHu_HongFuButtons[i].Ani:Show()
				g_ZhanJiangHu_HongFuButtons[i].FlexTip:Show()
			else
				g_ZhanJiangHu_HongFuButtons[i].Ani:Hide()
				g_ZhanJiangHu_HongFuButtons[i].FlexTip:Hide()
			end
			local theAction = DataPool:CreateActionItemForShow(g_ZhanJiangHu_HongFuReward_KaJi[i].RewardList.id, g_ZhanJiangHu_HongFuReward_KaJi[i].RewardList.count)
			if theAction:GetID() ~= 0 then
				g_ZhanJiangHu_HongFuButtons[i].Btn:SetActionItem(theAction:GetID())
			end
		end
		for i=1,table.getn(g_ZhanJiangHu_FlexTips) do
			if(g_ZhanJiangHu_FlexState[i] == 1) then
				g_ZhanJiangHu_FlexTips[i]:Show()
			else
				g_ZhanJiangHu_FlexTips[i]:Hide()
			end
		end

	--非卡级服
	else
	
		local nHongFu = ZhanJiangHu_GetHongFuValue()
		local nHongFuTemp = nHongFu
		local aBit = math.mod(nHongFuTemp,10)
		nHongFuTemp = math.floor(nHongFuTemp/10)
		local Ten = math.mod(nHongFuTemp,10)
		nHongFuTemp = math.floor(nHongFuTemp/10)
		local Hundreds = math.mod(nHongFuTemp,10)
		ZhanJiangHu_TextImage2:SetProperty("Image","")
		ZhanJiangHu_TextImage3:SetProperty("Image","")
		ZhanJiangHu_TextImage4:SetProperty("Image","")
		if(g_ZhanJiangHu_HongFuNum2Iamge[aBit] ~= nil) then
			ZhanJiangHu_TextImage4:SetProperty("Image",g_ZhanJiangHu_HongFuNum2Iamge[aBit])
		end
		if(Hundreds ~= 0 or Ten ~= 0) then
			if(g_ZhanJiangHu_HongFuNum2Iamge[Ten] ~= nil) then
				ZhanJiangHu_TextImage3:SetProperty("Image",g_ZhanJiangHu_HongFuNum2Iamge[Ten])
			end
		end
		if(Hundreds ~= 0 ) then
			if(g_ZhanJiangHu_HongFuNum2Iamge[Hundreds] ~= nil) then
				ZhanJiangHu_TextImage2:SetProperty("Image",g_ZhanJiangHu_HongFuNum2Iamge[Hundreds])
			end
		end
		--ZhanJiangHu_PresentDianshu:SetText("#{CJYJ_180104_55}"..":"..tostring(nHongFu))
		for i=1,table.getn(g_ZhanJiangHu_HongFuButtons) do
			local state = ZhanJiangHu_GetHFRewardState(i)
			if(state == 1) then
				g_ZhanJiangHu_HongFuButtons[i].FinshFlag:Hide()
				g_ZhanJiangHu_HongFuButtons[i].Btn:Disable()
				g_ZhanJiangHu_HongFuButtons[i].Btn1:Disable()
			else
				g_ZhanJiangHu_HongFuButtons[i].FinshFlag:Hide()
				g_ZhanJiangHu_HongFuButtons[i].Btn:Enable()
				g_ZhanJiangHu_HongFuButtons[i].Btn1:Enable()
			end
			if(nHongFu >= g_ZhanJiangHu_HongFuReward[i].NeedHongFu and state == 0) then
				g_ZhanJiangHu_HongFuButtons[i].Ani:Show()
				g_ZhanJiangHu_HongFuButtons[i].FlexTip:Show()
			else
				g_ZhanJiangHu_HongFuButtons[i].Ani:Hide()
				g_ZhanJiangHu_HongFuButtons[i].FlexTip:Hide()
			end
			local theAction = DataPool:CreateActionItemForShow(g_ZhanJiangHu_HongFuReward[i].RewardList.id, g_ZhanJiangHu_HongFuReward[i].RewardList.count)
			if theAction:GetID() ~= 0 then
				g_ZhanJiangHu_HongFuButtons[i].Btn:SetActionItem(theAction:GetID())
			end
		end
		for i=1,table.getn(g_ZhanJiangHu_FlexTips) do
			if(g_ZhanJiangHu_FlexState[i] == 1) then
				g_ZhanJiangHu_FlexTips[i]:Show()
			else
				g_ZhanJiangHu_FlexTips[i]:Hide()
			end
		end
		
	end
	
end


function ZhanJiangHu_RefreshDayButtons()
	for i=1,table.getn(g_ZhanJiangHu_DaySwithcButon) do
		local nState = ZhanJiangHu_HasRewardForDay(i)
		if(ZhanJiangHu_CheckDayHasOpen(i) == 1) then
			g_ZhanJiangHu_DaySwithcButon[i]:Enable()
		else
			g_ZhanJiangHu_DaySwithcButon[i]:Disable()
		end
		if(g_ZhanJiangHu_CurPage == i) then
			g_ZhanJiangHu_DaySwithcButon[i]:SetCheck(1)
		else
			g_ZhanJiangHu_DaySwithcButon[i]:SetCheck(0)
		end
		if(g_ZhanJiangHu_DaySwithButtonTips[i] ~= nil) then
			if(nState == 1 ) then
				g_ZhanJiangHu_DaySwithButtonTips[i]:Show()
			else
				g_ZhanJiangHu_DaySwithButtonTips[i]:Hide()
			end
		end
	end
	--ZhanJiangHu_ShuLiang:SetText(""..g_ZhanJiangHu_HeXinChunHaveDenglong)
	--ZhanJiangHu_Denglong:SetText(ScriptGlobal_Format("#{CJYJ_180124_137}",g_ZhanJiangHu_HeXinChunDenglongMaxCount - g_ZhanJiangHu_HeXinChunHaveDenglong))
end

function ZhanJiangHu_SwitchPage(nPage)   --这个看看是否需要改
	if(nPage== nil or nPage < 1 or nPage > g_ZhanJiangHu_MaxPage) then
		return
	end
		
	--卡级服
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(48) > 0 then
	
		if(g_ZhanJiangHu_CurPage == nPage) then
			ZhanJiangHu_RefreshDayButtons()
			return
		end
		for i=1,g_ZhanJiangHu_PageMaxCount do
			local AchieveId = g_ZhanJiangHu_PageAhieve_KaJi[nPage].AchieveList[i]
			g_ZhanJiangHu_AchieveContorl[i].Desc:Hide()
			g_ZhanJiangHu_AchieveContorl[i].Btn:Hide()
			if(AchieveId ~= nil) then
				local szDesc = g_ZhanJiangHu_AhieveIdData_KaJi[AchieveId].Desc
				local nSocre = ZhanJiangHu_GetEventDataById(g_ZhanJiangHu_AhieveIdData_KaJi[AchieveId].EventId)
				local nNeedValue = g_ZhanJiangHu_AhieveIdData_KaJi[AchieveId].NeedValue
				local szToolTips = g_ZhanJiangHu_AhieveIdData_KaJi[AchieveId].ToolTips
				local desc = szDesc
				--特写1：同一项目，两套显示，因此在此特写
				--if(AchieveId == 9) then --2019年
					--desc = ScriptGlobal_Format(szDesc,2)
					--if(nSocre < nNeedValue) then
					--	desc = desc.." "..ScriptGlobal_Format("#{CJYJ_180119_134}",ZhanJiangHu_GetEventDataById(11)) --2019年
					--end
				--2019年
				--elseif(AchieveId == 19) then
				--	desc = ScriptGlobal_Format(szDesc,2)
				--	if(nSocre < nNeedValue) then
					--	desc = desc.." "..ScriptGlobal_Format("#{CJYJ_180129_178}",ZhanJiangHu_GetEventDataById(13)) --2019年
				--	end	
				--2019年
				--elseif(AchieveId == 35) then
					--desc = ScriptGlobal_Format(szDesc,nNeedValue)
				--	if(nSocre < nNeedValue) then
					--	desc = desc.." "..ScriptGlobal_Format("#{CJYJ_180129_179}",ZhanJiangHu_GetEventDataById(14)) --2019年
					--end					
				--特写2：有的描述，不含变量，有的含有变量，因此在此特写
			--	else
					if(AchieveId == 5) then --2019年
						desc = ScriptGlobal_Format(desc," ")
					else
						desc = ScriptGlobal_Format(desc,nNeedValue)
					end
				--end
				if(nSocre >= nNeedValue) then
					g_ZhanJiangHu_AchieveContorl[i].Btn:Hide()
					g_ZhanJiangHu_AchieveContorl[i].Ani:Hide()
					g_ZhanJiangHu_AchieveContorl[i].Btn:SetToolTip("")
					g_ZhanJiangHu_AchieveContorl[i].Finsh:Show()
					g_ZhanJiangHu_AchieveContorl[i].ValueText:Hide()
				else
					g_ZhanJiangHu_AchieveContorl[i].Btn:Show()
					g_ZhanJiangHu_AchieveContorl[i].Ani:Hide()
					g_ZhanJiangHu_AchieveContorl[i].Finsh:Hide()
					g_ZhanJiangHu_AchieveContorl[i].Btn:SetToolTip(szToolTips)
					g_ZhanJiangHu_AchieveContorl[i].ValueText:SetText(tostring(nSocre).."/"..g_ZhanJiangHu_AhieveIdData_KaJi[AchieveId].NeedValue)
					g_ZhanJiangHu_AchieveContorl[i].ValueText:Show()
				end
				local nReward = g_ZhanJiangHu_PageAhieve_KaJi[i].RewardIcon
				local theAction = DataPool:CreateActionItemForShow(nReward, 1)
				if theAction:GetID() ~= 0 then
					ZhanJiangHu_Icon:SetActionItem(theAction:GetID())
				end
				g_ZhanJiangHu_AchieveContorl[i].Desc:SetText(desc)
				g_ZhanJiangHu_AchieveContorl[i].Desc:Show()
			end
		end
		local nToDayState = ZhanJiangHu_GetDayRewardState(nPage)
		if(nToDayState == 1) then
			g_ZhanJiangHu_RewardContorl.Btn:SetText("#{CJYJ_180104_63}")
			g_ZhanJiangHu_RewardContorl.Btn:Disable()
			g_ZhanJiangHu_RewardContorl.FlexTip:Hide()
		else
			g_ZhanJiangHu_RewardContorl.Btn:SetText("#{CJYJ_180104_62}")
			g_ZhanJiangHu_RewardContorl.Btn:Enable()
			if(ZhanJiangHu_CanGetDayReward(nPage) == 1) then
				g_ZhanJiangHu_RewardContorl.FlexTip:Show()
			else
				g_ZhanJiangHu_RewardContorl.FlexTip:Hide()
			end
		end
		local umcom = ZhanJiangHu_GetUnCompleteAchieveCount(nPage)
		local FinshCount = g_ZhanJiangHu_PageAhieve_KaJi[nPage].AchieveCount - umcom
		g_ZhanJiangHu_RewardContorl.Desc:SetText(ScriptGlobal_Format(g_ZhanJiangHu_PageAhieve_KaJi[nPage].Desc,FinshCount))
		g_ZhanJiangHu_CurPage = nPage
		ZhanJiangHu_RefreshDayButtons()
	
	--非卡级服
	else
	
		if(g_ZhanJiangHu_CurPage == nPage) then
			ZhanJiangHu_RefreshDayButtons()
			return
		end
		for i=1,g_ZhanJiangHu_PageMaxCount do
			local AchieveId = g_ZhanJiangHu_PageAhieve[nPage].AchieveList[i]
			g_ZhanJiangHu_AchieveContorl[i].Desc:Hide()
			g_ZhanJiangHu_AchieveContorl[i].Btn:Hide()
			if(AchieveId ~= nil) then
				local szDesc = g_ZhanJiangHu_AhieveIdData[AchieveId].Desc
				local nSocre = ZhanJiangHu_GetEventDataById(g_ZhanJiangHu_AhieveIdData[AchieveId].EventId)
				local nNeedValue = g_ZhanJiangHu_AhieveIdData[AchieveId].NeedValue
				local szToolTips = g_ZhanJiangHu_AhieveIdData[AchieveId].ToolTips
				local desc = szDesc
				--特写1：同一项目，两套显示，因此在此特写
				--if(AchieveId == 9) then --2019年
					--desc = ScriptGlobal_Format(szDesc,2)
					--if(nSocre < nNeedValue) then
					--	desc = desc.." "..ScriptGlobal_Format("#{CJYJ_180119_134}",ZhanJiangHu_GetEventDataById(11)) --2019年
					--end
				--2019年
				--elseif(AchieveId == 19) then
					--desc = ScriptGlobal_Format(szDesc,2)
					--if(nSocre < nNeedValue) then
					--	desc = desc.." "..ScriptGlobal_Format("#{CJYJ_180129_178}",ZhanJiangHu_GetEventDataById(13)) --2019年
					--end	
				--2019年
				--elseif(AchieveId == 35) then
					--desc = ScriptGlobal_Format(szDesc,nNeedValue)
					--if(nSocre < nNeedValue) then
					--	desc = desc.." "..ScriptGlobal_Format("#{CJYJ_180129_179}",ZhanJiangHu_GetEventDataById(14)) --2019年
					--end					
				--特写2：有的描述，不含变量，有的含有变量，因此在此特写
				--else
					if(AchieveId == 5) then --2019年
						desc = ScriptGlobal_Format(desc," ")
					else
						desc = ScriptGlobal_Format(desc,nNeedValue)
					end
				--end
				if(nSocre >= nNeedValue) then
					g_ZhanJiangHu_AchieveContorl[i].Btn:Hide()
					g_ZhanJiangHu_AchieveContorl[i].Ani:Hide()
					g_ZhanJiangHu_AchieveContorl[i].Btn:SetToolTip("")
					g_ZhanJiangHu_AchieveContorl[i].Finsh:Show()
					g_ZhanJiangHu_AchieveContorl[i].ValueText:Hide()
				else
					g_ZhanJiangHu_AchieveContorl[i].Btn:Show()
					g_ZhanJiangHu_AchieveContorl[i].Ani:Hide()
					g_ZhanJiangHu_AchieveContorl[i].Finsh:Hide()
					g_ZhanJiangHu_AchieveContorl[i].Btn:SetToolTip(szToolTips)
					g_ZhanJiangHu_AchieveContorl[i].ValueText:SetText(tostring(nSocre).."/"..g_ZhanJiangHu_AhieveIdData[AchieveId].NeedValue)
					g_ZhanJiangHu_AchieveContorl[i].ValueText:Show()
				end
				local nReward = g_ZhanJiangHu_PageAhieve[i].RewardIcon
				local theAction = DataPool:CreateActionItemForShow(nReward, 1)
				if theAction:GetID() ~= 0 then
					ZhanJiangHu_Icon:SetActionItem(theAction:GetID())
				end
				g_ZhanJiangHu_AchieveContorl[i].Desc:SetText(desc)
				g_ZhanJiangHu_AchieveContorl[i].Desc:Show()
			end
		end
		local nToDayState = ZhanJiangHu_GetDayRewardState(nPage)
		if(nToDayState == 1) then
			g_ZhanJiangHu_RewardContorl.Btn:SetText("#{CJYJ_180104_63}")
			g_ZhanJiangHu_RewardContorl.Btn:Disable()
			g_ZhanJiangHu_RewardContorl.FlexTip:Hide()
		else
			g_ZhanJiangHu_RewardContorl.Btn:SetText("#{CJYJ_180104_62}")
			g_ZhanJiangHu_RewardContorl.Btn:Enable()
			if(ZhanJiangHu_CanGetDayReward(nPage) == 1) then
				g_ZhanJiangHu_RewardContorl.FlexTip:Show()
			else
				g_ZhanJiangHu_RewardContorl.FlexTip:Hide()
			end
		end
		local umcom = ZhanJiangHu_GetUnCompleteAchieveCount(nPage)
		local FinshCount = g_ZhanJiangHu_PageAhieve[nPage].AchieveCount - umcom
		g_ZhanJiangHu_RewardContorl.Desc:SetText(ScriptGlobal_Format(g_ZhanJiangHu_PageAhieve[nPage].Desc,FinshCount))
		g_ZhanJiangHu_CurPage = nPage
		ZhanJiangHu_RefreshDayButtons()	
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ZhanJiangHu_Frame_On_ResetPos()
	ZhanJiangHu_Frame : SetProperty("UnifiedXPosition", g_ZhanJiangHu_Frame_UnifiedXPosition);
	ZhanJiangHu_Frame : SetProperty("UnifiedYPosition", g_ZhanJiangHu_Frame_UnifiedYPosition);
end

--获取鸿福点数
function ZhanJiangHu_GetHongFuValue()
	return ZhanJiangHu_GetEventDataById(g_ZhanJiangHu_HongFuSocreDataIndex)
end

function ZhanJiangHu_ChangeTabIndex()
	local X = ZhanJiangHu_Frame : GetProperty("UnifiedXPosition");
	local Y = ZhanJiangHu_Frame : GetProperty("UnifiedYPosition");
	PushEvent("OPEN_HEXINCHUN",1,X,Y)
	--ZhanJiangHu_OnHiden()
end

function ZhanJiangHu_AskData(bOpen)
	-- local curDay = tonumber(DataPool:GetServerDayTime());
	-- if(curDay >= g_ZhanJiangHu_BeginTime and curDay <= g_ZhanJiangHu_EndTime) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenUI")
			Set_XSCRIPT_ScriptID(892664)
			Set_XSCRIPT_Parameter(0,bOpen)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	-- end
end

--战江湖成就是否完成
function ZhanJiangHu_AhieveHasFinsh(AchieveId)

	--卡级服
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(48) > 0 then
		if(g_ZhanJiangHu_AhieveIdData_KaJi[AchieveId] == nil) then
			return 0
		end
		local nEventData = ZhanJiangHu_GetEventDataById(g_ZhanJiangHu_AhieveIdData_KaJi[AchieveId].EventId)
		if(nEventData ~= nil and nEventData >= g_ZhanJiangHu_AhieveIdData_KaJi[AchieveId].NeedValue) then
			return 1
		end
		return 0
	--非卡级服
	else
		if(g_ZhanJiangHu_AhieveIdData[AchieveId] == nil) then
			return 0
		end
		local nEventData = ZhanJiangHu_GetEventDataById(g_ZhanJiangHu_AhieveIdData[AchieveId].EventId)
		if(nEventData ~= nil and nEventData >= g_ZhanJiangHu_AhieveIdData[AchieveId].NeedValue) then
			return 1
		end
		return 0		
	end
end
--当天页签下是否有奖励可以领取包括鸿福点数
function ZhanJiangHu_HasRewardForDay(nDay)
	--卡级服
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(48) > 0 then
		if(nDay == nil or g_ZhanJiangHu_PageAhieve_KaJi[nDay] == nil) then
			return -1
		end
		if(ZhanJiangHu_CheckDayHasOpen(nDay) == 0) then
			return -2
		end
		return ZhanJiangHu_CanGetDayReward(nDay)
	--非卡级服
	else
		if(nDay == nil or g_ZhanJiangHu_PageAhieve[nDay] == nil) then
			return -1
		end
		if(ZhanJiangHu_CheckDayHasOpen(nDay) == 0) then
			return -2
		end
		return ZhanJiangHu_CanGetDayReward(nDay)		
	end
end
--当天奖励是否可以领取
function ZhanJiangHu_CanGetDayReward(nDay)

	--卡级服
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(48) > 0 then
		if(nDay == nil or g_ZhanJiangHu_PageAhieve_KaJi[nDay] == nil) then
			return -1
		end
		if(ZhanJiangHu_CheckDayHasOpen(nDay) == 0) then
			return -2
		end
		--全部完成
		if(ZhanJiangHu_DayAchieveHasFinsh(nDay) == 1) then
			if(ZhanJiangHu_GetDayRewardState(nDay) == 0) then
				return 1
			else
				return -1
			end
		end
		return 0
	--非卡级服
	else
		if(nDay == nil or g_ZhanJiangHu_PageAhieve[nDay] == nil) then
			return -1
		end
		if(ZhanJiangHu_CheckDayHasOpen(nDay) == 0) then
			return -2
		end
		--全部完成
		if(ZhanJiangHu_DayAchieveHasFinsh(nDay) == 1) then
			if(ZhanJiangHu_GetDayRewardState(nDay) == 0) then
				return 1
			else
				return -1
			end
		end
		return 0		
	end
end

function ZhanJiangHu_DayAchieveHasFinsh(nDayIndex)
	local nUmCom = ZhanJiangHu_GetUnCompleteAchieveCount(nDayIndex)
	--全部完成
	if(nUmCom <= 0) then
		return 1
	end
	return 0
end

function ZhanJiangHu_GetUnCompleteAchieveCount(nDayIndex)

	--卡级服
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(48) > 0 then
		if(nDayIndex == nil or g_ZhanJiangHu_PageAhieve_KaJi[nDayIndex] == nil) then
			return 999
		end
		local nCount = 0
		for i=1,g_ZhanJiangHu_PageAhieve_KaJi[nDayIndex].AchieveCount do
			local AchId = g_ZhanJiangHu_PageAhieve_KaJi[nDayIndex].AchieveList[i]
			nCount = nCount + ZhanJiangHu_AhieveHasFinsh(AchId)
		end
		local nUmCom = g_ZhanJiangHu_PageAhieve_KaJi[nDayIndex].AchieveCount - nCount
		return nUmCom
	--非卡级服
	else
		if(nDayIndex == nil or g_ZhanJiangHu_PageAhieve[nDayIndex] == nil) then
			return 999
		end
		local nCount = 0
		for i=1,g_ZhanJiangHu_PageAhieve[nDayIndex].AchieveCount do
			local AchId = g_ZhanJiangHu_PageAhieve[nDayIndex].AchieveList[i]
			nCount = nCount + ZhanJiangHu_AhieveHasFinsh(AchId)
		end
		local nUmCom = g_ZhanJiangHu_PageAhieve[nDayIndex].AchieveCount - nCount
		return nUmCom		
	end
end

function ZhanJiangHu_CheckDayHasOpen(nDayIndex)

	--卡级服
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(48) > 0 then
		if(nDayIndex == nil or g_ZhanJiangHu_PageAhieve_KaJi[nDayIndex] == nil) then
			return 0
		end
		local nCurrentDay = tonumber(DataPool:GetServerDayTime());
		local nNeedDay = g_ZhanJiangHu_PageAhieve_KaJi[nDayIndex].OpenDay
		if(nCurrentDay >= nNeedDay) then
			return 1
		end
		return 0
	--非卡级服
	else
		if(nDayIndex == nil or g_ZhanJiangHu_PageAhieve[nDayIndex] == nil) then
			return 0
		end
		local nCurrentDay = tonumber(DataPool:GetServerDayTime());
		local nNeedDay = g_ZhanJiangHu_PageAhieve[nDayIndex].OpenDay
		if(nCurrentDay >= nNeedDay) then
			return 1
		end
		return 0		
	end
end

----战江湖成就对应奖励状态
function ZhanJiangHu_GetDayRewardState(nDayIndex)

	--卡级服
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(48) > 0 then
		if(g_ZhanJiangHu_PageAhieve_KaJi[nDayIndex] == nil) then
			return -1
		end
		local nSplit = math.floor(g_ZhanJiangHu_PageAhieve_KaJi[nDayIndex].RewardBit / g_ZhanJiangHu_MaxBit) + 1
		local nIndex = math.mod(g_ZhanJiangHu_PageAhieve_KaJi[nDayIndex].RewardBit ,g_ZhanJiangHu_MaxBit)
		if(g_ZhanJiangHu_RewardStatePool[nSplit] == nil) then
			return -1
		end
		local Data = g_ZhanJiangHu_RewardStatePool[nSplit]
		local bRet,state = GetBitValueInUINT(Data,nIndex,1)
		return state	
	--非卡级服
	else
		if(g_ZhanJiangHu_PageAhieve[nDayIndex] == nil) then
			return -1
		end
		local nSplit = math.floor(g_ZhanJiangHu_PageAhieve[nDayIndex].RewardBit / g_ZhanJiangHu_MaxBit) + 1
		local nIndex = math.mod(g_ZhanJiangHu_PageAhieve[nDayIndex].RewardBit ,g_ZhanJiangHu_MaxBit)
		if(g_ZhanJiangHu_RewardStatePool[nSplit] == nil) then
			return -1
		end
		local Data = g_ZhanJiangHu_RewardStatePool[nSplit]
		local bRet,state = GetBitValueInUINT(Data,nIndex,1)
		return state	
	end
end

function ZhanJiangHu_GetHFRewardState(nId)

	--卡级服
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(48) > 0 then
		if(g_ZhanJiangHu_HongFuReward_KaJi[nId] == nil) then
			return
		end
		local nSplit = math.floor(g_ZhanJiangHu_HongFuReward_KaJi[nId].RewardBit / g_ZhanJiangHu_MaxBit) + 1
		local nIndex = math.mod(g_ZhanJiangHu_HongFuReward_KaJi[nId].RewardBit ,g_ZhanJiangHu_MaxBit)
		if(g_ZhanJiangHu_RewardStatePool[nSplit] == nil) then
			return -1
		end
		local Data = g_ZhanJiangHu_RewardStatePool[nSplit]
		local bRet,state = GetBitValueInUINT(Data,nIndex,1)
		return state	
	--非卡级服
	else
		if(g_ZhanJiangHu_HongFuReward[nId] == nil) then
			return
		end
		local nSplit = math.floor(g_ZhanJiangHu_HongFuReward[nId].RewardBit / g_ZhanJiangHu_MaxBit) + 1
		local nIndex = math.mod(g_ZhanJiangHu_HongFuReward[nId].RewardBit ,g_ZhanJiangHu_MaxBit)
		if(g_ZhanJiangHu_RewardStatePool[nSplit] == nil) then
			return -1
		end
		local Data = g_ZhanJiangHu_RewardStatePool[nSplit]
		local bRet,state = GetBitValueInUINT(Data,nIndex,1)
		return state	
	end
end



function ZhanJiangHu_GetEventDataById(EventId)
	if(EventId == nil or g_ZhanJiangHu_EventId2Data[EventId] == nil) then
		return
	end
	local nStart = g_ZhanJiangHu_EventId2Data[EventId].Start
	local nLen = g_ZhanJiangHu_EventId2Data[EventId].Len
	local nIndex = math.floor(nStart / 32) + 1
	--处理跨MD数据
	local nNum = math.mod(nStart ,32)
	local nRetValue = 0
	local nRetValueLen = 0
	local nMaxClycle = 99 --做一个循环限制
	while(1) do
		if(nIndex >= nMaxClycle) then
			return
		end
		if(g_ZhanJiangHu_EventDataPool[nIndex] == nil) then
			return
		end
		local nEnd = nNum + nLen
		if(nEnd > 32) then
			nEnd = 32
		end
		local nSize = nEnd - nNum
		local nData = g_ZhanJiangHu_EventDataPool[nIndex]
		local nRet,nValue = GetBitValueInUINT(nData,nNum,nSize)
		nRet,nRetValue = SetBitValueInUINT(nRetValue,nRetValueLen,nSize,nValue)
		
		nLen = nLen - nSize
		nRetValueLen = nRetValueLen + nSize
		nNum = 0
		nIndex = nIndex + 1
		if(nLen <= 0) then
			return nRetValue
		end
	end
end

function ZhanJiangHu_ClickCanjia(nIndex)
	if(nIndex < 1 or nIndex > g_ZhanJiangHu_PageMaxCount) then
		return
	end
		
	--卡级服
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(48) > 0 then
	
		local nAchieveId = g_ZhanJiangHu_PageAhieve_KaJi[g_ZhanJiangHu_CurPage].AchieveList[nIndex]
		local nState = ZhanJiangHu_AhieveHasFinsh(nAchieveId)
		if(nState == 1) then
			--走领取鸿福点的逻辑
			-- local HasGet = ZhanJiangHu_GetHongFuDianState(nAchieveId)
			-- if(HasGet == 1) then
				--PushDebugMessage("#{CJYJ_180104_81}")
				-- return
			-- end
			-- Clear_XSCRIPT()
				-- Set_XSCRIPT_Function_Name("GetHongFuDian")
				-- Set_XSCRIPT_ScriptID(892664)
				-- Set_XSCRIPT_Parameter(0,nAchieveId)
				-- Set_XSCRIPT_ParamCount(1)
			-- Send_XSCRIPT()
			return
		else
			--自动寻路逻辑
			if(nAchieveId == 5) then --2019年
				local guildID, clanID = DataPool:GetGuildClanID()
				 if(guildID < 0) then
					PushDebugMessage( "你当前尚未加入帮会。请到洛阳（237，236）范纯仁处申请加入帮会，更好地体味江湖。" )
					return
				 end
				 local TalkTable = {"春华又至，恭贺新春！","新年新至，仗剑天涯！诸位兄弟，且与我一同征战江湖！","光阴飞逝，又是新的一年。诸位！愿我的江湖，年年更新，岁岁有你。"}  --2019年
				 local nNum = math.random(1,3)
				Talk : SendChatMessage("guild", TalkTable[nNum]);
				Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name("OnTlakInGuild")
					Set_XSCRIPT_ScriptID(892664)
					Set_XSCRIPT_ParamCount(0)
				Send_XSCRIPT()
				return
			end
			--if (nAchieveId == 4 or nAchieveId == 10 or nAchieveId == 14 or nAchieveId == 20 or nAchieveId == 24 or nAchieveId == 29 or nAchieveId == 34 or nAchieveId == 39) then
				--PushDebugMessage( "#{CJYJ_180129_184}" )
				--return
			--end
			if (nAchieveId == 3 or nAchieveId == 18 or nAchieveId == 23 or nAchieveId == 33 or nAchieveId == 38 or nAchieveId == 13 or nAchieveId == 28 or nAchieveId == 8) then
				local guildID, clanID = DataPool:GetGuildClanID()
				if guildID < 0 then
					PushDebugMessage( "你当前尚未加入帮会。请到洛阳（237，236）范纯仁处申请加入帮会，更好地体味江湖。" )
					return
				end
			end
			if (nAchieveId == 13) then
				local playerlevel = Player:GetLevel()
				if playerlevel < 10 then
					PushDebugMessage( "#{CJYJ_180129_185}" )
					return
				end
			end
			local Pos = g_ZhanJiangHu_AhieveIdData_KaJi[nAchieveId].Pos
			local szTips = g_ZhanJiangHu_AhieveIdData_KaJi[nAchieveId].Tips
			if(Pos ~= nil and Pos.x ~= nil and Pos.z ~= nil and Pos.sceneId~=nil and Pos.npcName ~= nil) then
				--自动寻路
		-- 自动寻路
				--if nAchieveId == 15 then
					--local playerlevel = Player:GetLevel()
					--local x = -1
					--local z = -1
					--local sceneId = -1
					--local name = ""
					--if playerlevel < 60 then
						--PushDebugMessage("#{CJYJ_180129_183}")
						--return
					--elseif playerlevel < 80 then
						--x = 184
						--z = 98
						--sceneId = 2
						--name = "周颐真"						
					--elseif playerlevel < 90 then
					--	x = 185
					--	z = 104
					--	sceneId = 2
					--	name = "周叔彬"
					--elseif playerlevel < 110 then
					--	x = 293
					--	z = 229
					--	sceneId = 1
					--	name = "周仲青"				
					--else
					--	x = 296
					--	z = 225
					--	sceneId = 0
					--	name = "周伯衡"				
					--end
					--local bRet = AutoRuntoTargetExWithName(x, z, sceneId, name)
					--if 0 == bRet then
						--PushDebugMessage("#{JRHD_170720_07}")
					--end				
				--else
					local bRet = AutoRuntoTargetExWithName(Pos.x, Pos.z, Pos.sceneId, Pos.npcName)
					if 0 == bRet then
						PushDebugMessage("#{JRHD_170720_07}")
					end
				--end
			end
			if(szTips ~= nil and szTips~= "") then
				PushDebugMessage(ScriptGlobal_Format(szTips,tostring(g_ZhanJiangHu_AhieveIdData_KaJi[nAchieveId].NeedValue)))
			end
		end	
	--非卡级服
	else
	
		local nAchieveId = g_ZhanJiangHu_PageAhieve[g_ZhanJiangHu_CurPage].AchieveList[nIndex]
		local nState = ZhanJiangHu_AhieveHasFinsh(nAchieveId)
		if(nState == 1) then
			--走领取鸿福点的逻辑
			-- local HasGet = ZhanJiangHu_GetHongFuDianState(nAchieveId)
			-- if(HasGet == 1) then
				--PushDebugMessage("#{CJYJ_180104_81}")
				-- return
			-- end
			-- Clear_XSCRIPT()
				-- Set_XSCRIPT_Function_Name("GetHongFuDian")
				-- Set_XSCRIPT_ScriptID(892664)
				-- Set_XSCRIPT_Parameter(0,nAchieveId)
				-- Set_XSCRIPT_ParamCount(1)
			-- Send_XSCRIPT()
			return
		else
			--自动寻路逻辑
			if(nAchieveId == 5) then --2019年
				local guildID, clanID = DataPool:GetGuildClanID()
				 if(guildID < 0) then
					PushDebugMessage( "你当前尚未加入帮会。请到洛阳（237，236）范纯仁处申请加入帮会，更好地体味江湖。" )
					return
				 end
				 local TalkTable = {"春华又至，恭贺新春！","新年新至，仗剑天涯！诸位兄弟，且与我一同征战江湖！","光阴飞逝，又是新的一年。诸位！愿我的江湖，年年更新，岁岁有你。"}  --2019年
				 local nNum = math.random(1,3)
				Talk : SendChatMessage("guild", TalkTable[nNum]);
				Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name("OnTlakInGuild")
					Set_XSCRIPT_ScriptID(892664)
					Set_XSCRIPT_ParamCount(0)
				Send_XSCRIPT()
				return
			end
			--if (nAchieveId == 4 or nAchieveId == 10 or nAchieveId == 14 or nAchieveId == 20 or nAchieveId == 24 or nAchieveId == 29 or nAchieveId == 40 ) then
				--PushDebugMessage( "#{CJYJ_180129_184}" )
				--return
			--end
			if (nAchieveId == 3 or nAchieveId == 18 or nAchieveId == 23 or nAchieveId == 33 or nAchieveId == 38 or nAchieveId == 13 or nAchieveId == 28 or nAchieveId == 8) then
				local guildID, clanID = DataPool:GetGuildClanID()
				if guildID < 0 then
					PushDebugMessage( "你当前尚未加入帮会。请到洛阳（237，236）范纯仁处申请加入帮会，更好地体味江湖。" )
					return
				end
			end
			if (nAchieveId == 13) then
				local playerlevel = Player:GetLevel()
				if playerlevel < 10 then
					PushDebugMessage( "#{CJYJ_180129_185}" )
					return
				end
			end
			local Pos = g_ZhanJiangHu_AhieveIdData[nAchieveId].Pos
			local szTips = g_ZhanJiangHu_AhieveIdData[nAchieveId].Tips
			if(Pos ~= nil and Pos.x ~= nil and Pos.z ~= nil and Pos.sceneId~=nil and Pos.npcName ~= nil) then
				--自动寻路
		-- 自动寻路
				--if nAchieveId == 15 then
					--local playerlevel = Player:GetLevel()
					--local x = -1
					--local z = -1
					--local sceneId = -1
					--local name = ""
					--if playerlevel < 60 then
					--	PushDebugMessage("#{CJYJ_180129_183}")
					--	return
					--elseif playerlevel < 80 then
					--	x = 184
					--	z = 98
					--	sceneId = 2
					--	name = "周颐真"						
					--elseif playerlevel < 90 then
						--x = 185
						--z = 104
						--sceneId = 2
						--name = "周叔彬"
				--	elseif playerlevel < 110 then
					--	x = 293
						--z = 229
						--sceneId = 1
						--name = "周仲青"				
					--else
						--x = 296
						--z = 225
						--sceneId = 0
						--name = "周伯衡"				
					--end
					--local bRet = AutoRuntoTargetExWithName(x, z, sceneId, name)
					--if 0 == bRet then
						--PushDebugMessage("#{JRHD_170720_07}")
					--end				
				--else
					local bRet = AutoRuntoTargetExWithName(Pos.x, Pos.z, Pos.sceneId, Pos.npcName)
					if 0 == bRet then
						PushDebugMessage("#{JRHD_170720_07}")
					end
				--end
			end
			if(szTips ~= nil and szTips~= "") then
				PushDebugMessage(ScriptGlobal_Format(szTips,tostring(g_ZhanJiangHu_AhieveIdData[nAchieveId].NeedValue)))
			end
		end	
	end
end

function ZhanJiangHu_ClickGetReward()
	if(g_ZhanJiangHu_CurPage < 1 or g_ZhanJiangHu_CurPage > g_ZhanJiangHu_MaxPage) then
		return
	end
	local nRet = ZhanJiangHu_CanGetDayReward(g_ZhanJiangHu_CurPage)
	if(nRet == -2) then
		--PushDebugMessage( "没有开放" )
		return
	end
	if(nRet == -1) then
		PushDebugMessage( "#{CJYJ_180104_81}" )
		return
	end
	if(nRet == 0) then
		local umcom = ZhanJiangHu_GetUnCompleteAchieveCount(g_ZhanJiangHu_CurPage)
		PushDebugMessage(ScriptGlobal_Format("#{CJYJ_180104_80}",umcom))
		return
	end
	
	if(nRet == 1) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetDayReward")
			Set_XSCRIPT_ScriptID(892664)
			Set_XSCRIPT_Parameter(0,g_ZhanJiangHu_CurPage)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end

function ZhanJiangHu_ClickGetHFReward(nIndex)

	--卡级服
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(48) > 0 then
		if(nIndex ~= 1 and nIndex ~= 2) then
			return
		end
		if(ZhanJiangHu_GetHongFuValue() < g_ZhanJiangHu_HongFuReward_KaJi[nIndex].NeedHongFu) then
			PushDebugMessage(g_ZhanJiangHu_HFRewardTips_KaJi[nIndex])
			return
		end
		if(ZhanJiangHu_GetHFRewardState(nIndex) == 1) then
			PushDebugMessage("已经领取过鸿福奖励")
			return
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetHFReward")
			Set_XSCRIPT_ScriptID(892664)
			Set_XSCRIPT_Parameter(0,nIndex)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	--非卡级服
	else
		if(nIndex ~= 1 and nIndex ~= 2) then
			return
		end
		if(ZhanJiangHu_GetHongFuValue() < g_ZhanJiangHu_HongFuReward[nIndex].NeedHongFu) then
			PushDebugMessage(g_ZhanJiangHu_HFRewardTips[nIndex])
			return
		end
		if(ZhanJiangHu_GetHFRewardState(nIndex) == 1) then
			PushDebugMessage("已经领取过鸿福奖励")
			return
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetHFReward")
			Set_XSCRIPT_ScriptID(892664)
			Set_XSCRIPT_Parameter(0,nIndex)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()		
	end
end


function ZhanJiangHu_RefreshFlexState()

	--卡级服
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(48) > 0 then
		local nFlex = 0
		local nHongFu = ZhanJiangHu_GetHongFuValue()
		for i=1,g_ZhanJiangHu_MaxPage do
			if(ZhanJiangHu_CheckDayHasOpen(i) == 1) then
				if(ZhanJiangHu_HasRewardForDay(i) == 1) then
					nFlex = 1
				end
			end
		end
		for i=1,table.getn(g_ZhanJiangHu_HongFuButtons) do
			local state = ZhanJiangHu_GetHFRewardState(i)
			if(nHongFu >= g_ZhanJiangHu_HongFuReward_KaJi[i].NeedHongFu and state == 0) then
				nFlex = 1
			end
		end
		if(nFlex ~= g_ZhanJiangHu_FlexState[2]) then
			g_ZhanJiangHu_FlexState[2] = nFlex
			return 1
		end
		return 0
	--非卡级服
	else
		local nFlex = 0
		local nHongFu = ZhanJiangHu_GetHongFuValue()
		for i=1,g_ZhanJiangHu_MaxPage do
			if(ZhanJiangHu_CheckDayHasOpen(i) == 1) then
				if(ZhanJiangHu_HasRewardForDay(i) == 1) then
					nFlex = 1
				end
			end
		end
		for i=1,table.getn(g_ZhanJiangHu_HongFuButtons) do
			local state = ZhanJiangHu_GetHFRewardState(i)
			if(nHongFu >= g_ZhanJiangHu_HongFuReward[i].NeedHongFu and state == 0) then
				nFlex = 1
			end
		end
		if(nFlex ~= g_ZhanJiangHu_FlexState[2]) then
			g_ZhanJiangHu_FlexState[2] = nFlex
			return 1
		end
		return 0		
	end
end

function ZhanJiangHu_HelpClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NpcText")
		Set_XSCRIPT_ScriptID(892664)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
