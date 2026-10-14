--关怀绝情谷
 
local g_Jueqing_Fuchi_Frame_UnifiedPosition 
local g_Jueqing_Fuchi_Client = {}
local g_Jueqing_Fuchi_XiuLian_Ctl = {}
local g_Jueqing_Fuchi_XiuLian_Data =
{ 
    [1]  = 	{DataIdx = 1, DataIdx69 = 1,  NeedValue = 50,  isFinal = 0, RewardList={{Id=38000464,Count = 1,Bind=1},{Id=38000485,Count = 1,Bind=1},},szNameDic="#{JQGFC_220115_47}",img="set:CircularTaskTool44 image:CircularTaskTool44_8",},    	 --升级50
    [2]  = 	{DataIdx = 1, DataIdx69 = 1,  NeedValue = 60,  isFinal = 0, isFinal69 = 1, RewardList={{Id=20310168,Count = 10,Bind=1},{Id=38005676,Count = 1,Bind=1},{Id=38000464,Count = 3,Bind=1},},szNameDic="#{JQGFC_220115_48}",img="set:CircularTaskTool44 image:CircularTaskTool44_8",},    	 --升级60
	[3]  = 	{DataIdx = 1, DataIdx69 = -1, NeedValue = 70,  isFinal = 0, RewardList={{Id=30700241,Count = 10,Bind=1},{Id=38000831,Count = 10,Bind=1},{Id=38000464,Count = 4,Bind=1},},szNameDic="#{JQGFC_220115_49}",img="set:CircularTaskTool44 image:CircularTaskTool44_8",},    	 --升级70
	[4]  = 	{DataIdx = 1, DataIdx69 = -1, NeedValue = 80,  isFinal = 0, isFinal89 = 1,RewardList={{Id=38004580,Count = 1,Bind=1},{Id=38000528,Count = 500,Bind=1},{Id=38000464,Count = 5,Bind=1},},szNameDic="#{JQGFC_220115_50}",img="set:CircularTaskTool44 image:CircularTaskTool44_8",},    	 --升级80
	[5]  = 	{DataIdx = 1, DataIdx69 = -1, NeedValue = 90,  isFinal = 0, RewardList={{Id=30505706,Count = 1,Bind=1},{Id=20800031,Count = 10,Bind=1},{Id=38000464,Count = 10,Bind=1},},szNameDic="#{JQGFC_220115_51}",img="set:CircularTaskTool44 image:CircularTaskTool44_8",},    	 --升级90
	[6]  = 	{DataIdx = 1, DataIdx69 = -1, NeedValue = 100, isFinal = 1, RewardList={{Id=20310179,Count = 5,Bind=1},{Id=20800031,Count = 20,Bind=1},{Id=38000464,Count = 20,Bind=1},},szNameDic="#{JQGFC_220115_52}",img="set:CircularTaskTool44 image:CircularTaskTool44_8",},    	 --升级100
    [7]  = 	{DataIdx = 2, DataIdx69 = -1, NeedValue = 1,    isFinal = 0, RewardList={{Id=38000466,Count = 2,Bind=1},{Id=30505821,Count = 10,Bind=1},{Id=20700055,Count = 20,Bind=1},{Id=20310178,Count = 5,Bind=1},},szNameDic="#{JQGFC_220115_53}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --素月宝箱
	[8]  = 	{DataIdx = 2, DataIdx69 = -1, NeedValue = 2,    isFinal = 0, RewardList={{Id=38000466,Count = 2,Bind=1},{Id=30505821,Count = 10,Bind=1},{Id=20700055,Count = 20,Bind=1},{Id=20310178,Count = 5,Bind=1},},szNameDic="#{JQGFC_220115_54}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --素月宝箱
	[9]  = 	{DataIdx = 2, DataIdx69 = -1, NeedValue = 3,    isFinal = 0, RewardList={{Id=38000466,Count = 2,Bind=1},{Id=30505821,Count = 10,Bind=1},{Id=20700055,Count = 20,Bind=1},{Id=20310178,Count = 5,Bind=1},},szNameDic="#{JQGFC_220115_55}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --素月宝箱
	[10] = 	{DataIdx = 2, DataIdx69 = -1, NeedValue = 4,    isFinal = 0, RewardList={{Id=38000466,Count = 2,Bind=1},{Id=30505821,Count = 10,Bind=1},{Id=20700055,Count = 20,Bind=1},{Id=20310178,Count = 5,Bind=1},},szNameDic="#{JQGFC_220115_56}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --素月宝箱
	[11] = 	{DataIdx = 2, DataIdx69 = -1, NeedValue = 5,    isFinal = 0, RewardList={{Id=38000466,Count = 2,Bind=1},{Id=30505821,Count = 10,Bind=1},{Id=20700055,Count = 20,Bind=1},{Id=20310178,Count = 5,Bind=1},},szNameDic="#{JQGFC_220115_57}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --素月宝箱
	[12] = 	{DataIdx = 2, DataIdx69 = -1, NeedValue = 6,    isFinal = 0, RewardList={{Id=38000466,Count = 2,Bind=1},{Id=30505821,Count = 10,Bind=1},{Id=20700055,Count = 20,Bind=1},{Id=20310178,Count = 5,Bind=1},},szNameDic="#{JQGFC_220115_58}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --素月宝箱
	[13] = 	{DataIdx = 2, DataIdx69 = -1, NeedValue = 7,    isFinal = 0, RewardList={{Id=38000466,Count = 2,Bind=1},{Id=30505821,Count = 10,Bind=1},{Id=20700055,Count = 20,Bind=1},{Id=20310178,Count = 5,Bind=1},},szNameDic="#{JQGFC_220115_59}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --素月宝箱
    [14] = 	{DataIdx = 2, DataIdx69 = -1, NeedValue = 8,    isFinal = 1, RewardList={{Id=38000466,Count = 2,Bind=1},{Id=30505821,Count = 10,Bind=1},{Id=20700055,Count = 20,Bind=1},{Id=20310178,Count = 5,Bind=1},{Id=38001521,Count = 1,Bind=1},},szNameDic="#{JQGFC_220115_60}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --素月宝箱
    [15] = 	{DataIdx = 3, DataIdx69 = -1, NeedValue = 1,    isFinal = 0, RewardList={{Id=38002615,Count = 10,Bind=1},{Id=30505821,Count = 20,Bind=1},{Id=20700055,Count = 40,Bind=1},{Id=20310179,Count = 1,Bind=1},},szNameDic="#{JQGFC_220115_61}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},       --华星宝箱
	[16] = 	{DataIdx = 3, DataIdx69 = -1, NeedValue = 2,    isFinal = 0, RewardList={{Id=38002615,Count = 10,Bind=1},{Id=30505821,Count = 20,Bind=1},{Id=20700055,Count = 40,Bind=1},{Id=20310179,Count = 1,Bind=1},},szNameDic="#{JQGFC_220115_62}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --华星宝箱
	[17] = 	{DataIdx = 3, DataIdx69 = -1, NeedValue = 3,    isFinal = 0, RewardList={{Id=38002615,Count = 10,Bind=1},{Id=30505821,Count = 20,Bind=1},{Id=20700055,Count = 40,Bind=1},{Id=20310179,Count = 1,Bind=1},},szNameDic="#{JQGFC_220115_63}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --华星宝箱
	[18] = 	{DataIdx = 3, DataIdx69 = -1, NeedValue = 4,    isFinal = 0, RewardList={{Id=38002615,Count = 10,Bind=1},{Id=30505821,Count = 20,Bind=1},{Id=20700055,Count = 40,Bind=1},{Id=20310179,Count = 1,Bind=1},},szNameDic="#{JQGFC_220115_64}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --华星宝箱
	[19] = 	{DataIdx = 3, DataIdx69 = -1, NeedValue = 5,    isFinal = 0, RewardList={{Id=38002615,Count = 10,Bind=1},{Id=30505821,Count = 20,Bind=1},{Id=20700055,Count = 40,Bind=1},{Id=20310179,Count = 1,Bind=1},},szNameDic="#{JQGFC_220115_65}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --华星宝箱
	[20] = 	{DataIdx = 3, DataIdx69 = -1, NeedValue = 6,    isFinal = 0, RewardList={{Id=38002615,Count = 10,Bind=1},{Id=30505821,Count = 20,Bind=1},{Id=20700055,Count = 40,Bind=1},{Id=20310179,Count = 1,Bind=1},},szNameDic="#{JQGFC_220115_66}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --华星宝箱
	[21] = 	{DataIdx = 3, DataIdx69 = -1, NeedValue = 7,    isFinal = 0, RewardList={{Id=38002615,Count = 10,Bind=1},{Id=30505821,Count = 20,Bind=1},{Id=20700055,Count = 40,Bind=1},{Id=20310179,Count = 1,Bind=1},},szNameDic="#{JQGFC_220115_67}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},    	 --华星宝箱
    [22] = 	{DataIdx = 3, DataIdx69 = -1, NeedValue = 8,    isFinal = 1, RewardList={{Id=38002615,Count = 10,Bind=1},{Id=30505821,Count = 20,Bind=1},{Id=20700055,Count = 40,Bind=1},{Id=20310179,Count = 1,Bind=1},{Id=38001523,Count = 1,Bind=1},},szNameDic="#{JQGFC_220115_68}",img="set:CircularTaskTool44 image:CircularTaskTool44_10",},        --华星宝箱
    [23] = 	{DataIdx = 4, DataIdx69 = -1, NeedValue = 1000, isFinal = 0, RewardList={{Id=38000930,Count = 80,Bind=1},{Id=38001088,Count = 20,Bind=1},{Id=38001090,Count = 2,Bind=1},},szNameDic="#{JQGFC_220115_69}",img="set:Charm5 image:Charm5_9",},      --帮贡
	[24] = 	{DataIdx = 4, DataIdx69 = -1, NeedValue = 2000, isFinal = 0, RewardList={{Id=38000930,Count = 80,Bind=1},{Id=38001088,Count = 20,Bind=1},{Id=38001090,Count = 2,Bind=1},},szNameDic="#{JQGFC_220115_70}",img="set:Charm5 image:Charm5_9",},      --帮贡
	[25] = 	{DataIdx = 4, DataIdx69 = -1, NeedValue = 3000, isFinal = 0, RewardList={{Id=38000930,Count = 80,Bind=1},{Id=38001088,Count = 20,Bind=1},{Id=38001090,Count = 2,Bind=1},},szNameDic="#{JQGFC_220115_71}",img="set:Charm5 image:Charm5_9",},      --帮贡
	[26] = 	{DataIdx = 4, DataIdx69 = -1, NeedValue = 4000, isFinal = 0, RewardList={{Id=38000930,Count = 80,Bind=1},{Id=38001088,Count = 20,Bind=1},{Id=38001090,Count = 2,Bind=1},},szNameDic="#{JQGFC_220115_72}",img="set:Charm5 image:Charm5_9",},      --帮贡
	[27] = 	{DataIdx = 4, DataIdx69 = -1, NeedValue = 5000, isFinal = 0, RewardList={{Id=38000930,Count = 80,Bind=1},{Id=38001088,Count = 20,Bind=1},{Id=38001090,Count = 2,Bind=1},},szNameDic="#{JQGFC_220115_73}",img="set:Charm5 image:Charm5_9",},      --帮贡
	[28] = 	{DataIdx = 4, DataIdx69 = -1, NeedValue = 6000, isFinal = 0, RewardList={{Id=38000930,Count = 80,Bind=1},{Id=38001088,Count = 20,Bind=1},{Id=38001090,Count = 2,Bind=1},},szNameDic="#{JQGFC_220115_74}",img="set:Charm5 image:Charm5_9",},      --帮贡
	[29] = 	{DataIdx = 4, DataIdx69 = -1, NeedValue = 7000, isFinal = 0, RewardList={{Id=38000930,Count = 80,Bind=1},{Id=38001088,Count = 20,Bind=1},{Id=38001090,Count = 2,Bind=1},},szNameDic="#{JQGFC_220115_75}",img="set:Charm5 image:Charm5_9",},      --帮贡
    [30] = 	{DataIdx = 4, DataIdx69 = -1, NeedValue = 8000, isFinal = 1, RewardList={{Id=38000930,Count = 80,Bind=1},{Id=38001088,Count = 20,Bind=1},{Id=38001090,Count = 2,Bind=1},},szNameDic="#{JQGFC_220115_76}",img="set:Charm5 image:Charm5_9",},      --帮贡
	[31] = 	{DataIdx = 5, DataIdx69 = 2, NeedValue = 1,   isFinal = 1, isFinal69 = 1, RewardList={{Id=30503133,Count = 10,Bind=1},{Id=30503129,Count = 20,Bind=1},},szNameDic="#{JQGFC_220115_77}",img="set:Fabao image:Fabao_2",},      --暗器
	[32] = 	{DataIdx = 6, DataIdx69 = 3, NeedValue = 1,   isFinal = 1, isFinal69 = 1, RewardList={{Id=38000658,Count = 3,Bind=1},{Id=38000656,Count = 3,Bind=1},{Id=38000807,Count = 5,Bind=1},},szNameDic="#{JQGFC_220115_78}",img="set:CircularTaskTool59 image:CircularTaskTool59_5",},      --子女考验任务
	[33] = 	{DataIdx = 7, DataIdx69 = 4, NeedValue = 1,   isFinal = 1, isFinal69 = 1, RewardList={{Id=30700241,Count = 10,Bind=1},{Id=20310159,Count = 4,Bind=1},{Id=20310131,Count = 20,Bind=1},{Id=20310117,Count = 20,Bind=1},},szNameDic="#{JQGFC_220115_79}",img="set:Fabao image:Fabao_4",},      --武魂
	[34] = 	{DataIdx = 8, DataIdx69 = 5, NeedValue = 1,   isFinal = 1, isFinal69 = 1, RewardList={{Id=20502003,Count = 1,Bind=1},{Id=20501003,Count = 1,Bind=1},},szNameDic="#{JQGFC_220115_80}",img="set:CircularTaskTool70 image:CircularTaskTool70_14",},      --手工装备
	[35] = 	{DataIdx = 9, DataIdx69 = -1, NeedValue = 1,  isFinal = 1, RewardList={{Id=38000378,Count = 1,Bind=1},{Id=38002214,Count = 1,Bind=1},},szNameDic="#{JQGFC_220115_81}",img="set:ZhenYuan1 image:ZhenYuan1_15",},      --镶嵌真元
	[36] = 	{DataIdx = 10,DataIdx69 = -1, NeedValue = 1,  isFinal = 1, RewardList={{Id=38000989,Count = 2,Bind=1},{Id=38000932,Count = 2,Bind=1},},szNameDic="#{JQGFC_220115_82}",img="set:EquipLingPai image:EquipLingPai_5",},      --装备令牌
	[37] = 	{DataIdx = 11,DataIdx69 = -1, NeedValue = 1,  isFinal = 1, RewardList={{Id=30505821,Count = 30,Bind=1},{Id=30505908,Count = 50,Bind=1},},szNameDic="#{JQGFC_220115_83}",img="set:Shenqi_2 image:Shenqi_2_10",},      --6星神器
	[38] = 	{DataIdx = 12,DataIdx69 = -1, NeedValue = 1,  isFinal = 1, RewardList={{Id=38001088,Count = 20,Bind=1},{Id=38001090,Count = 2,Bind=1},},szNameDic="#{JQGFC_220115_84}",img="set:HaoXiaYin1 image:HaoXiaYin1_15",},      --豪侠印
} 
local g_Jueqing_Fuchi_ClientBtn = {}
local g_Jueqing_Fuchi_ClientBtnTips = {}
local g_Jueqing_Fuchi_LiBao_Ctl = {}
local g_Jueqing_Fuchi_LiBao_Data = {
	[1]  = 	{EventId=0,  Group =1, isFinal = 0, NeedValue = 18, ShowItem = {{Id=38000466, Count= 10, Bind=1},{Id=30505821, Count= 40, Bind=1},{Id=38000528, Count= 500, Bind=1},},    Text="#{JQGFC_220115_131}", tips="#{JQGFC_220115_101}",},    	 --宝石3
	[2]  = 	{EventId=1,  Group =1, isFinal = 0, NeedValue = 18, ShowItem = {{Id=38000466, Count= 30, Bind=1},{Id=30505821, Count= 90, Bind=1},{Id=38000528, Count= 500, Bind=1},},    Text="#{JQGFC_220115_132}", tips="#{JQGFC_220115_102}",},    	 --宝石4
	[3]  = 	{EventId=2,  Group =1, isFinal = 0, isFinal_Gem=1,NeedValue = 18, ShowItem = {{Id=38000466, Count= 60, Bind=1},{Id=30505821, Count= 190, Bind=1},{Id=38000528, Count= 1000, Bind=1},},   Text="#{JQGFC_220115_133}", tips="#{JQGFC_220115_103}",},    	 --宝石5
	[4]  = 	{EventId=3,  Group =1, isFinal = 1, NeedValue = 18, ShowItem = {{Id=38000466, Count= 120, Bind=1},{Id=30505821, Count= 320, Bind=1},{Id=38000528, Count= 2000, Bind=1},},  Text="#{JQGFC_220115_134}", tips="#{JQGFC_220115_104}",},    	 --宝石6
	[5]  = 	{EventId=4,  Group =2, isFinal = 0, NeedValue = 12,  ShowItem = {{Id=20700055, Count= 100, Bind=1},{Id=20700063, Count= 100, Bind=1},},  Text="#{JQGFC_220115_135}", tips="#{JQGFC_220115_105}",},    	 --强化
	[6]  = 	{EventId=5,  Group =2, isFinal = 0, NeedValue = 12,  ShowItem = {{Id=20700055, Count= 450, Bind=1},{Id=20700063, Count= 300, Bind=1},{Id=20800045, Count= 15, Bind=1},},  KaJiFix89 =1, Text="#{JQGFC_220115_136}", tips="#{JQGFC_220115_106}",},    	 --强化
	[7]  = 	{EventId=6,  Group =2, isFinal = 0, NeedValue = 12,  ShowItem = {{Id=20700055, Count= 900, Bind=1},{Id=20700063, Count= 600, Bind=1},{Id=20800045, Count= 30, Bind=1},},  KaJiFix89 =1, Text="#{JQGFC_220115_137}", tips="#{JQGFC_220115_107}",},    	 --强化
	[8]  = 	{EventId=7,  Group =2, isFinal = 1, NeedValue = 12,  ShowItem = {{Id=20700055, Count= 2000, Bind=1},{Id=20700063, Count= 1400, Bind=1},{Id=20800045, Count= 60, Bind=1},},KaJiFix89 =1, Text="#{JQGFC_220115_138}", tips="#{JQGFC_220115_124}",},    	 --强化
	[9]  = 	{EventId=8,  Group =3, isFinal = 0, NeedValue = 6,  ShowItem = {{Id=20800031, Count= 30, Bind=1},{Id=20800033, Count= 30, Bind=1},},    Text="#{JQGFC_220115_139}", tips="#{JQGFC_220115_108}",},    	 --神鼎
	[10] = 	{EventId=9,  Group =3, isFinal = 0, NeedValue = 15, ShowItem = {{Id=20800031, Count= 120, Bind=1},{Id=20800033, Count= 120, Bind=1},},    Text="#{JQGFC_220115_140}", tips="#{JQGFC_220115_109}",},    	 --神鼎
	[11] = 	{EventId=10, Group =3, isFinal = 0, NeedValue = 21, ShowItem = {{Id=20800031, Count= 240, Bind=1},{Id=20800033, Count= 240, Bind=1},},  Text="#{JQGFC_220115_141}", tips="#{JQGFC_220115_110}",},    	 --神鼎
	[12] = 	{EventId=11, Group =3, isFinal = 1, NeedValue = 28, ShowItem = {{Id=20800031, Count= 480, Bind=1},{Id=20800033, Count= 480, Bind=1},},  Text="#{JQGFC_220115_142}", tips="#{JQGFC_220115_111}",},        --神鼎
	[13] = 	{EventId=12, Group =4, isFinal = 0, NeedValue = 8,  ShowItem = {{Id=38000930, Count= 60, Bind=1},{Id=20310179, Count= 5, Bind=1},},     Text="#{JQGFC_220115_143}", tips="#{JQGFC_220115_112}",},    	 --雕纹
	[14] = 	{EventId=13, Group =4, isFinal = 0, NeedValue = 8,  ShowItem = {{Id=38000930, Count= 200, Bind=1},{Id=20310179, Count= 25, Bind=1},},   Text="#{JQGFC_220115_144}", tips="#{JQGFC_220115_113}",},    	 --雕纹
	[15] = 	{EventId=14, Group =4, isFinal = 0, NeedValue = 8,  ShowItem = {{Id=38000930, Count= 400, Bind=1},{Id=20310179, Count= 50, Bind=1},},   Text="#{JQGFC_220115_145}", tips="#{JQGFC_220115_114}",},    	 --雕纹
	[16] = 	{EventId=15, Group =4, isFinal = 1, NeedValue = 8,  ShowItem = {{Id=38000930, Count= 920, Bind=1},{Id=20310179, Count= 90, Bind=1},},   Text="#{JQGFC_220115_146}", tips="#{JQGFC_220115_115}",},    	 --雕纹
    [17] = 	{EventId=16, Group =5, isFinal = 0, NeedValue = 6,  ShowItem = {{Id=38001088, Count= 40, Bind=1},{Id=38001090, Count= 4, Bind=1},},     Text="#{JQGFC_220115_147}", tips="#{JQGFC_220115_120}",},    	 --真元
	[18] = 	{EventId=17, Group =5, isFinal = 0, NeedValue = 6,  ShowItem = {{Id=38001088, Count= 120, Bind=1},{Id=38001090, Count= 16, Bind=1},},     Text="#{JQGFC_220115_148}", tips="#{JQGFC_220115_121}",},    	 --真元
	[19] = 	{EventId=18, Group =5, isFinal = 0, NeedValue = 6,  ShowItem = {{Id=38001088, Count= 240, Bind=1},{Id=38001090, Count= 32, Bind=1},},   Text="#{JQGFC_220115_149}", tips="#{JQGFC_220115_122}",},    	 --真元
	[20] = 	{EventId=19, Group =5, isFinal = 1, NeedValue = 6,  ShowItem = {{Id=38001088, Count= 560, Bind=1},{Id=38001090, Count= 80, Bind=1},{Id=38001178, Count= 1, Bind=1},},   Text="#{JQGFC_220115_150}", tips="#{JQGFC_220115_123}",},        --真元
}
local g_Jueqing_Fuchi_LiBao_Text = {
    [1]={dc="#{JQGFC_220115_161}", wdc="#{JQGFC_220115_155}",},
    [2]={dc="#{JQGFC_220115_162}", wdc="#{JQGFC_220115_156}",},
    [3]={dc="#{JQGFC_220115_163}", wdc="#{JQGFC_220115_157}",},
    [4]={dc="#{JQGFC_220115_164}", wdc="#{JQGFC_220115_158}",},
    [5]={dc="#{JQGFC_220115_169}", wdc="#{JQGFC_220115_160}",},
}
local g_Jueqing_Fuchi_CurPage = 1
local g_Jueqing_Fuchi_XiuLian_CurPage = 1
local g_Jueqing_Fuchi_XiuLian_TotalPage = 1
local g_Jueqing_Fuchi_XiuLian_PerPage = 5
local g_Jueqing_Fuchi_EndYear;
local g_Jueqing_Fuchi_EndMonth;
local g_Jueqing_Fuchi_EndDay;
local g_Jueqing_Fuchi_EndHour;
local g_Jueqing_Fuchi_LiBao_PageIdx = {1,1,1,1,1,1,};
local g_Jueqing_Fuchi_GemZwid = -1
function Jueqing_Fuchi_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	this:RegisterEvent("GUANHUAIJUEQINGGU_OPEN",true) 
	this:RegisterEvent("GUANHUAIJUEQINGGU_REFRESH",true) 
	
end

function Jueqing_Fuchi_OnLoad()
	Jueqing_Fuchi_LoadControl()
	g_Jueqing_Fuchi_Frame_UnifiedPosition = Jueqing_Fuchi_FrameNULL:GetProperty("UnifiedPosition") 	
end

--=========
-- 装载控件
--=========
function Jueqing_Fuchi_LoadControl() 
    
    g_Jueqing_Fuchi_Client[1] = Jueqing_Fuchi_Client1
    g_Jueqing_Fuchi_Client[2] = Jueqing_Fuchi_Client2
    g_Jueqing_Fuchi_Client[3] = Jueqing_Fuchi_Client3

    g_Jueqing_Fuchi_ClientBtn[1] = Jueqing_Fuchi_Left_Buttontab01
    g_Jueqing_Fuchi_ClientBtn[2] = Jueqing_Fuchi_Left_Buttontab02
    g_Jueqing_Fuchi_ClientBtn[3] = Jueqing_Fuchi_Left_Buttontab03

    g_Jueqing_Fuchi_ClientBtnTips[1] = Jueqing_Fuchi_Left_Buttontab01_Tips
    g_Jueqing_Fuchi_ClientBtnTips[2] = Jueqing_Fuchi_Left_Buttontab02_Tips
    g_Jueqing_Fuchi_ClientBtnTips[3] = Jueqing_Fuchi_Left_Buttontab03_Tips

    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl = {}    
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1] = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].bk           = Jueqing_Fuchi_Client2_Item1
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].icon         = Jueqing_Fuchi_Client2_Item1_Icon
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].mubiao       = Jueqing_Fuchi_Client2_Item1_Text
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].jindu        = Jueqing_Fuchi_Client2_Item1_Text2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].bonus        = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].bonus[1]     = Jueqing_Fuchi_Client2_Item1_Icon0
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].bonus[2]     = Jueqing_Fuchi_Client2_Item1_Icon1
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].bonus[3]     = Jueqing_Fuchi_Client2_Item1_Icon2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].bonus[4]     = Jueqing_Fuchi_Client2_Item1_Icon3
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].bonus[5]     = Jueqing_Fuchi_Client2_Item1_Icon4
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].num          = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].num[1]       = Jueqing_Fuchi_Client2_Item1_Num0
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].num[2]       = Jueqing_Fuchi_Client2_Item1_Num1
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].num[3]       = Jueqing_Fuchi_Client2_Item1_Num2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].num[4]       = Jueqing_Fuchi_Client2_Item1_Num3
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].num[5]       = Jueqing_Fuchi_Client2_Item1_Num4
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].btnok        = Jueqing_Fuchi_Client2_Item1_OK
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].tips         = Jueqing_Fuchi_Client2_Item1_Tips
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].dacheng      = Jueqing_Fuchi_Client2_Item1_Received
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[1].weidacheng   = Jueqing_Fuchi_Client2_Item1_GO 
    
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2] = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].bk           = Jueqing_Fuchi_Client2_Item2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].icon         = Jueqing_Fuchi_Client2_Item2_Icon
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].mubiao       = Jueqing_Fuchi_Client2_Item2_Text
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].jindu        = Jueqing_Fuchi_Client2_Item2_Text2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].bonus        = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].bonus[1]     = Jueqing_Fuchi_Client2_Item2_Icon0
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].bonus[2]     = Jueqing_Fuchi_Client2_Item2_Icon1
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].bonus[3]     = Jueqing_Fuchi_Client2_Item2_Icon2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].bonus[4]     = Jueqing_Fuchi_Client2_Item2_Icon3
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].bonus[5]     = Jueqing_Fuchi_Client2_Item2_Icon4
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].num          = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].num[1]       = Jueqing_Fuchi_Client2_Item2_Num0
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].num[2]       = Jueqing_Fuchi_Client2_Item2_Num1
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].num[3]       = Jueqing_Fuchi_Client2_Item2_Num2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].num[4]       = Jueqing_Fuchi_Client2_Item2_Num3
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].num[5]       = Jueqing_Fuchi_Client2_Item2_Num4
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].btnok        = Jueqing_Fuchi_Client2_Item2_OK
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].tips         = Jueqing_Fuchi_Client2_Item2_Tips
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].dacheng      = Jueqing_Fuchi_Client2_Item2_Received
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[2].weidacheng   = Jueqing_Fuchi_Client2_Item2_GO 
    
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3] = {} 
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].bk           = Jueqing_Fuchi_Client2_Item3
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].icon         = Jueqing_Fuchi_Client2_Item3_Icon
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].mubiao       = Jueqing_Fuchi_Client2_Item3_Text
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].jindu        = Jueqing_Fuchi_Client2_Item3_Text2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].bonus        = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].bonus[1]     = Jueqing_Fuchi_Client2_Item3_Icon0
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].bonus[2]     = Jueqing_Fuchi_Client2_Item3_Icon1
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].bonus[3]     = Jueqing_Fuchi_Client2_Item3_Icon2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].bonus[4]     = Jueqing_Fuchi_Client2_Item3_Icon3
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].bonus[5]     = Jueqing_Fuchi_Client2_Item3_Icon4
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].num          = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].num[1]       = Jueqing_Fuchi_Client2_Item3_Num0
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].num[2]       = Jueqing_Fuchi_Client2_Item3_Num1
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].num[3]       = Jueqing_Fuchi_Client2_Item3_Num2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].num[4]       = Jueqing_Fuchi_Client2_Item3_Num3
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].num[5]       = Jueqing_Fuchi_Client2_Item3_Num4
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].btnok        = Jueqing_Fuchi_Client2_Item3_OK
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].tips         = Jueqing_Fuchi_Client2_Item3_Tips
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].dacheng      = Jueqing_Fuchi_Client2_Item3_Received
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[3].weidacheng   = Jueqing_Fuchi_Client2_Item3_GO 
    
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4] = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].bk           = Jueqing_Fuchi_Client2_Item4
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].icon         = Jueqing_Fuchi_Client2_Item4_Icon
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].mubiao       = Jueqing_Fuchi_Client2_Item4_Text
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].jindu        = Jueqing_Fuchi_Client2_Item4_Text2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].bonus        = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].bonus[1]     = Jueqing_Fuchi_Client2_Item4_Icon0
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].bonus[2]     = Jueqing_Fuchi_Client2_Item4_Icon1
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].bonus[3]     = Jueqing_Fuchi_Client2_Item4_Icon2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].bonus[4]     = Jueqing_Fuchi_Client2_Item4_Icon3
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].bonus[5]     = Jueqing_Fuchi_Client2_Item4_Icon4
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].num          = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].num[1]       = Jueqing_Fuchi_Client2_Item4_Num0
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].num[2]       = Jueqing_Fuchi_Client2_Item4_Num1
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].num[3]       = Jueqing_Fuchi_Client2_Item4_Num2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].num[4]       = Jueqing_Fuchi_Client2_Item4_Num3
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].num[5]       = Jueqing_Fuchi_Client2_Item4_Num4
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].btnok        = Jueqing_Fuchi_Client2_Item4_OK
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].tips         = Jueqing_Fuchi_Client2_Item4_Tips
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].dacheng      = Jueqing_Fuchi_Client2_Item4_Received
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[4].weidacheng   = Jueqing_Fuchi_Client2_Item4_GO 
    
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5] = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].bk           = Jueqing_Fuchi_Client2_Item5
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].icon         = Jueqing_Fuchi_Client2_Item5_Icon
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].mubiao       = Jueqing_Fuchi_Client2_Item5_Text
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].jindu        = Jueqing_Fuchi_Client2_Item5_Text2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].bonus        = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].bonus[1]     = Jueqing_Fuchi_Client2_Item5_Icon0
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].bonus[2]     = Jueqing_Fuchi_Client2_Item5_Icon1
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].bonus[3]     = Jueqing_Fuchi_Client2_Item5_Icon2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].bonus[4]     = Jueqing_Fuchi_Client2_Item5_Icon3
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].bonus[5]     = Jueqing_Fuchi_Client2_Item5_Icon4
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].num          = {}
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].num[1]       = Jueqing_Fuchi_Client2_Item5_Num0
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].num[2]       = Jueqing_Fuchi_Client2_Item5_Num1
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].num[3]       = Jueqing_Fuchi_Client2_Item5_Num2
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].num[4]       = Jueqing_Fuchi_Client2_Item5_Num3
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].num[5]       = Jueqing_Fuchi_Client2_Item5_Num4
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].btnok        = Jueqing_Fuchi_Client2_Item5_OK
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].tips         = Jueqing_Fuchi_Client2_Item5_Tips
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].dacheng      = Jueqing_Fuchi_Client2_Item5_Received
    g_Jueqing_Fuchi_XiuLian_Ctl.itemctl[5].weidacheng   = Jueqing_Fuchi_Client2_Item5_GO 

    g_Jueqing_Fuchi_LiBao_Ctl.itemctl = {}    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1]= {} 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].icon2           = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].icon2[1]        = Jueqing_Fuchi_Client3_Item1_Icon1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].icon2[2]        = Jueqing_Fuchi_Client3_Item1_Icon2 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].num2            = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].num2[1]         = Jueqing_Fuchi_Client3_Item1_Num1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].num2[2]         = Jueqing_Fuchi_Client3_Item1_Num2   
    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].icon3           = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].icon3[1]        = Jueqing_Fuchi_Client3_Item6_Icon1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].icon3[2]        = Jueqing_Fuchi_Client3_Item6_Icon2  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].icon3[3]        = Jueqing_Fuchi_Client3_Item6_Icon3 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].num3            = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].num3[1]         = Jueqing_Fuchi_Client3_Item6_Num1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].num3[2]         = Jueqing_Fuchi_Client3_Item6_Num2   
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].num3[3]         = Jueqing_Fuchi_Client3_Item6_Num3   

    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].name           = Jueqing_Fuchi_Client3_Item1_Name
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].ok             = Jueqing_Fuchi_Client3_Item1_OK 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].jindu          = Jueqing_Fuchi_Client3_Item1_Text
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].tips           = Jueqing_Fuchi_Client3_Item1_Tip
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].redpoint       = Jueqing_Fuchi_Client3_Item1_Tips
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].dacheng        = Jueqing_Fuchi_Client3_Item1_Received    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].jiangliBK2     = Jueqing_Fuchi_Client3_Item1_IconBK1    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[1].jiangliBK3     = Jueqing_Fuchi_Client3_Item1_IconBK2    
     
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2]= {} 

    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].icon2           = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].icon2[1]        = Jueqing_Fuchi_Client3_Item2_Icon1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].icon2[2]        = Jueqing_Fuchi_Client3_Item2_Icon2  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].num2            = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].num2[1]         = Jueqing_Fuchi_Client3_Item2_Num1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].num2[2]         = Jueqing_Fuchi_Client3_Item2_Num2   

    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].icon3           = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].icon3[1]        = Jueqing_Fuchi_Client3_Item7_Icon1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].icon3[2]        = Jueqing_Fuchi_Client3_Item7_Icon2 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].icon3[3]        = Jueqing_Fuchi_Client3_Item7_Icon3 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].num3            = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].num3[1]         = Jueqing_Fuchi_Client3_Item7_Num1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].num3[2]         = Jueqing_Fuchi_Client3_Item7_Num2   
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].num3[3]         = Jueqing_Fuchi_Client3_Item7_Num3   

    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].name           = Jueqing_Fuchi_Client3_Item2_Name
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].ok             = Jueqing_Fuchi_Client3_Item2_OK
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].jindu          = Jueqing_Fuchi_Client3_Item2_Text
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].tips           = Jueqing_Fuchi_Client3_Item2_Tip
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].redpoint       = Jueqing_Fuchi_Client3_Item2_Tips
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].dacheng        = Jueqing_Fuchi_Client3_Item2_Received    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].jiangliBK2     = Jueqing_Fuchi_Client3_Item2_IconBK1    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[2].jiangliBK3     = Jueqing_Fuchi_Client3_Item2_IconBK2    
    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3]= {} 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].icon2           = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].icon2[1]        = Jueqing_Fuchi_Client3_Item3_Icon1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].icon2[2]        = Jueqing_Fuchi_Client3_Item3_Icon2 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].num2            = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].num2[1]         = Jueqing_Fuchi_Client3_Item3_Num1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].num2[2]         = Jueqing_Fuchi_Client3_Item3_Num2   

    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].icon3           = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].icon3[1]        = Jueqing_Fuchi_Client3_Item8_Icon1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].icon3[2]        = Jueqing_Fuchi_Client3_Item8_Icon2 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].icon3[3]        = Jueqing_Fuchi_Client3_Item8_Icon3 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].num3            = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].num3[1]         = Jueqing_Fuchi_Client3_Item8_Num1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].num3[2]         = Jueqing_Fuchi_Client3_Item8_Num2   
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].num3[3]         = Jueqing_Fuchi_Client3_Item8_Num3   

    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].name           = Jueqing_Fuchi_Client3_Item3_Name
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].ok             = Jueqing_Fuchi_Client3_Item3_OK
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].jindu          = Jueqing_Fuchi_Client3_Item3_Text
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].tips           = Jueqing_Fuchi_Client3_Item3_Tip
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].redpoint       = Jueqing_Fuchi_Client3_Item3_Tips
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].dacheng        = Jueqing_Fuchi_Client3_Item3_Received  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].jiangliBK2     = Jueqing_Fuchi_Client3_Item3_IconBK1    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[3].jiangliBK3     = Jueqing_Fuchi_Client3_Item3_IconBK2      
    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4]= {} 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].icon2           = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].icon2[1]        = Jueqing_Fuchi_Client3_Item4_Icon1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].icon2[2]        = Jueqing_Fuchi_Client3_Item4_Icon2 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].num2            = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].num2[1]         = Jueqing_Fuchi_Client3_Item4_Num1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].num2[2]         = Jueqing_Fuchi_Client3_Item4_Num2  
    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].icon3           = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].icon3[1]        = Jueqing_Fuchi_Client3_Item9_Icon1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].icon3[2]        = Jueqing_Fuchi_Client3_Item9_Icon2 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].icon3[3]        = Jueqing_Fuchi_Client3_Item9_Icon3 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].num3            = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].num3[1]         = Jueqing_Fuchi_Client3_Item9_Num1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].num3[2]         = Jueqing_Fuchi_Client3_Item9_Num2   
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].num3[3]         = Jueqing_Fuchi_Client3_Item9_Num3   

    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].name           = Jueqing_Fuchi_Client3_Item4_Name
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].ok             = Jueqing_Fuchi_Client3_Item4_OK
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].jindu          = Jueqing_Fuchi_Client3_Item4_Text
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].tips           = Jueqing_Fuchi_Client3_Item4_Tip
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].redpoint       = Jueqing_Fuchi_Client3_Item4_Tips
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].dacheng        = Jueqing_Fuchi_Client3_Item4_Received 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].jiangliBK2     = Jueqing_Fuchi_Client3_Item4_IconBK1    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[4].jiangliBK3     = Jueqing_Fuchi_Client3_Item4_IconBK2    
    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5]= {} 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].icon2           = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].icon2[1]        = Jueqing_Fuchi_Client3_Item5_Icon1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].icon2[2]        = Jueqing_Fuchi_Client3_Item5_Icon2
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].num2            = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].num2[1]         = Jueqing_Fuchi_Client3_Item5_Num1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].num2[2]         = Jueqing_Fuchi_Client3_Item5_Num2   
    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].icon3           = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].icon3[1]        = Jueqing_Fuchi_Client3_Item10_Icon1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].icon3[2]        = Jueqing_Fuchi_Client3_Item10_Icon2 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].icon3[3]        = Jueqing_Fuchi_Client3_Item10_Icon3 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].num3            = {}
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].num3[1]         = Jueqing_Fuchi_Client3_Item10_Num1  
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].num3[2]         = Jueqing_Fuchi_Client3_Item10_Num2   
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].num3[3]         = Jueqing_Fuchi_Client3_Item10_Num3   

    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].name           = Jueqing_Fuchi_Client3_Item5_Name
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].ok             = Jueqing_Fuchi_Client3_Item5_OK
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].jindu          = Jueqing_Fuchi_Client3_Item5_Text
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].tips           = Jueqing_Fuchi_Client3_Item5_Tip
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].redpoint       = Jueqing_Fuchi_Client3_Item5_Tips
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].dacheng        = Jueqing_Fuchi_Client3_Item5_Received 
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].jiangliBK2     = Jueqing_Fuchi_Client3_Item5_IconBK1    
    g_Jueqing_Fuchi_LiBao_Ctl.itemctl[5].jiangliBK3     = Jueqing_Fuchi_Client3_Item5_IconBK2    

end

--=========
-- Event
--=========
function Jueqing_Fuchi_OnEvent(event) 
	if event == "GUANHUAIJUEQINGGU_OPEN" then -- 
		if this:IsVisible() then
			Jueqing_Fuchi_Close()
			return
        end 
        g_Jueqing_Fuchi_CurPage = 1;
        Jueqing_Fuchi_Clicked(1)
        this:Show() 	
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Jueqing_Fuchi_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Jueqing_Fuchi_Close()
	elseif event == "ADJEST_UI_POS" then
        Jueqing_Fuchi_On_ResetPos() 
    elseif event == "GUANHUAIJUEQINGGU_REFRESH" then
        Jueqing_Fuchi_SetClientRedPoint()   
        if this:IsVisible() then
			Jueqing_Fuchi_Clicked( 1 )  
			return
        end  
	end

end
 
--=========
-- 重置
--=========
function Jueqing_Fuchi_On_ResetPos()
	Jueqing_Fuchi_FrameNULL:SetProperty("UnifiedPosition", g_Jueqing_Fuchi_Frame_UnifiedPosition)
end


--=========
-- 关闭
--=========
function Jueqing_Fuchi_OnHiden()
    Jueqing_Fuchi_Close()
end

function Jueqing_Fuchi_Close() 
    g_Jueqing_Fuchi_XiuLian_CurPage = 1;
    g_Jueqing_Fuchi_CurPage = 1;
	this:Hide()
end

function Jueqing_Fuchi_Tab_Click( idx )
    for i = 1, 3 do
        g_Jueqing_Fuchi_ClientBtn[i]:SetProperty("Selected", "False");
    end
    g_Jueqing_Fuchi_CurPage = idx
    Jueqing_Fuchi_Clicked( 1 )    
    Jueqing_Fuchi_Client_Tab_Click(g_Jueqing_Fuchi_CurPage)
end
--=========
-- 打开
--=========
function Jueqing_Fuchi_Clicked( isopen )
    local kajiType = KaJi:LuaFnGetKaJiType(158)
    if kajiType == 1 then
        Jueqing_Fuchi_Client1_BK:Show()
        Jueqing_Fuchi_Client1_BK2:Hide()
        Jueqing_Fuchi_Left_Buttontab03:Hide()
        Jueqing_Fuchi_Left_Buttontab01_Line1:Show()
        Jueqing_Fuchi_Left_Buttontab01_Line2:Hide()
        Jueqing_Fuchi_Left_Buttontab02_Line:Hide()
    else
        Jueqing_Fuchi_Client1_BK:Hide()
        Jueqing_Fuchi_Client1_BK2:Show()
        Jueqing_Fuchi_Left_Buttontab03:Show()
        Jueqing_Fuchi_Left_Buttontab01_Line1:Hide()
        Jueqing_Fuchi_Left_Buttontab01_Line2:Show()
        Jueqing_Fuchi_Left_Buttontab02_Line:Show()
    end

    local pEndTime = Lua_GetGuanHuaiJueQingGuDate()
    g_Jueqing_Fuchi_EndYear  = math.floor(pEndTime/100000000)
	g_Jueqing_Fuchi_EndMonth = math.mod(math.floor(pEndTime/1000000),100)
	g_Jueqing_Fuchi_EndDay   = math.mod(math.floor(pEndTime/10000),100) 
    g_Jueqing_Fuchi_EndHour  = math.mod(math.floor(pEndTime/100),100)  
    		
    --红点
    Jueqing_Fuchi_SetClientRedPoint()
    for i = 1, table.getn(g_Jueqing_Fuchi_Client) do
        if isopen == 1 then
            g_Jueqing_Fuchi_Client[i]:Hide()
        end
    end
    if g_Jueqing_Fuchi_CurPage == 2 then
        Jueqing_Fuchi_Fresh_XiuLian(isopen)
    elseif g_Jueqing_Fuchi_CurPage == 3 then
        Jueqing_Fuchi_Fresh_LiBao(isopen)
    end
    
    g_Jueqing_Fuchi_ClientBtn[g_Jueqing_Fuchi_CurPage]:SetProperty("Selected", "True");
    g_Jueqing_Fuchi_Client[g_Jueqing_Fuchi_CurPage]:Show()
end 

--=========
-- 红点
--=========
function Jueqing_Fuchi_SetClientRedPoint()
    local red = Lua_GetGuanHuaiJueQingGuRedPoint()
    
    local IsShowTips = 0 
    for index, value in ipairs(g_Jueqing_Fuchi_ClientBtnTips) do
        if red[index] == 1 then
            g_Jueqing_Fuchi_ClientBtnTips[index]:Show()
            IsShowTips = 1;
        else
            g_Jueqing_Fuchi_ClientBtnTips[index]:Hide()
        end
    end
     
    Lua_ShowQuickEnterPointTip(30, IsShowTips)
end

--=========
-- 修炼界面
--=========
function Jueqing_Fuchi_Fresh_XiuLian(isopen)
    if math.mod( g_Jueqing_Fuchi_XiuLian_Data[table.getn(g_Jueqing_Fuchi_XiuLian_Data)].DataIdx , g_Jueqing_Fuchi_XiuLian_PerPage ) == 0 then
        g_Jueqing_Fuchi_XiuLian_TotalPage = math.floor( g_Jueqing_Fuchi_XiuLian_Data[table.getn(g_Jueqing_Fuchi_XiuLian_Data)].DataIdx / g_Jueqing_Fuchi_XiuLian_PerPage)
    else
        g_Jueqing_Fuchi_XiuLian_TotalPage = math.floor( g_Jueqing_Fuchi_XiuLian_Data[table.getn(g_Jueqing_Fuchi_XiuLian_Data)].DataIdx / g_Jueqing_Fuchi_XiuLian_PerPage) + 1
    end 
    
    local dexpText  = ScriptGlobal_Format("#{JQGFC_220115_14}", g_Jueqing_Fuchi_EndYear, g_Jueqing_Fuchi_EndMonth,g_Jueqing_Fuchi_EndDay,g_Jueqing_Fuchi_EndHour)
    Jueqing_Fuchi_Client2_Info:SetText(dexpText)
    local kajiType = KaJi:LuaFnGetKaJiType(158)
    if kajiType == 1 then
        g_Jueqing_Fuchi_XiuLian_TotalPage = 1 
        Jueqing_Fuchi_Client2_Info:SetText(ScriptGlobal_Format("#{JQGFC_240926_01}", g_Jueqing_Fuchi_EndYear, g_Jueqing_Fuchi_EndMonth,g_Jueqing_Fuchi_EndDay,g_Jueqing_Fuchi_EndHour))
    end

    local ctltbl = g_Jueqing_Fuchi_XiuLian_Ctl.itemctl
    if isopen == 1 then
        for i, v in ipairs(ctltbl) do
            v.bk:Hide()
            v.mubiao:Hide()
            v.jindu:Hide()
            v.btnok:Hide()
            v.tips:Hide()
            v.weidacheng:Hide()
            v.dacheng:Hide()
            for j, b in ipairs(v.bonus) do
                b:Hide() 
            end
            for j, n in ipairs(v.num) do
                n:Hide() 
            end
        end
    end

    local con,gift,data = Lua_GetGuanHuaiJueQingGuXiuLianData()
    if con == nil or gift == nil or data == nil then
        PushDebugMessage("Jueqing_Fuchi_Fresh_XiuLian nil 1")
        return -1
    end 
    local curidx = (g_Jueqing_Fuchi_XiuLian_CurPage-1)*g_Jueqing_Fuchi_XiuLian_PerPage  

    for i=1, table.getn(ctltbl) do  
        local pos = Jueqing_Fuchi_GetCurDataPos_XiuLian(curidx+i)         
        if pos == -1 then
            break;
        end 
        ctltbl[i].bk:Show()
        ctltbl[i].mubiao:Show()
        ctltbl[i].mubiao:SetText(g_Jueqing_Fuchi_XiuLian_Data[pos].szNameDic)
        ctltbl[i].icon:SetProperty( "Image", g_Jueqing_Fuchi_XiuLian_Data[pos].img )		
        for j, r in ipairs(g_Jueqing_Fuchi_XiuLian_Data[pos].RewardList) do   
            --Lua_TDU_Log("j:"..j)   
            --Lua_TDU_Log("table.getn(ctltbl[i].bonus):"..table.getn(ctltbl[i].bonus))   
            if j > table.getn(ctltbl[i].bonus) then
                break
            end     
            ctltbl[i].bonus[j]:Show() 	
            local itemAction;	  
            if r.Count > 1 then 
                ctltbl[i].num[j]:Show()
                ctltbl[i].num[j]:SetText(ScriptGlobal_Format("#{JQGFC_220115_172}", r.Count)) 
            else
                ctltbl[i].num[j]:Hide()
            end  
            if r.Bind == 1 then
                itemAction=DataPool:CreateBindActionItemForShow(r.Id, 1)
            else
                itemAction=DataPool:CreateActionItemForShow(r.Id, 1)
            end

            if itemAction:GetID() ~= 0 then
			    ctltbl[i].bonus[j]:SetActionItem(itemAction:GetID())
            end 
        end
        local strjindu = data[g_Jueqing_Fuchi_XiuLian_Data[pos].DataIdx]
        if strjindu >= g_Jueqing_Fuchi_XiuLian_Data[pos].NeedValue then
            strjindu = g_Jueqing_Fuchi_XiuLian_Data[pos].NeedValue
        end
        
        ctltbl[i].jindu:Show()
        ctltbl[i].btnok:Hide()
        ctltbl[i].weidacheng:Hide()
        ctltbl[i].dacheng:Hide()
        if con[pos] == 0 then
            ctltbl[i].weidacheng:Show()            
            ctltbl[i].jindu:SetText(ScriptGlobal_Format("#{JQGFC_220115_88}",strjindu,g_Jueqing_Fuchi_XiuLian_Data[pos].NeedValue))
        elseif con[pos] == 1 and gift[pos] == 0 then
            ctltbl[i].btnok:Show()
            ctltbl[i].tips:Show()            
            ctltbl[i].jindu:SetText(ScriptGlobal_Format("#{JQGFC_220115_168}",strjindu,g_Jueqing_Fuchi_XiuLian_Data[pos].NeedValue))
        elseif con[pos] == 1 and gift[pos] == 1 then
            ctltbl[i].dacheng:Show()            
            ctltbl[i].jindu:SetText(ScriptGlobal_Format("#{JQGFC_220115_168}",strjindu,g_Jueqing_Fuchi_XiuLian_Data[pos].NeedValue))
        end
    end
    Jueqing_Fuchi_Client2_CurrentlyPage:SetText(ScriptGlobal_Format("#{JQGFC_220115_100}",g_Jueqing_Fuchi_XiuLian_CurPage,g_Jueqing_Fuchi_XiuLian_TotalPage))    
    if g_Jueqing_Fuchi_XiuLian_CurPage == 1 then
        Jueqing_Fuchi_Client2_UpPage:Disable()
    else
        Jueqing_Fuchi_Client2_UpPage:Enable()
    end
    if g_Jueqing_Fuchi_XiuLian_CurPage == g_Jueqing_Fuchi_XiuLian_TotalPage then
        Jueqing_Fuchi_Client2_DownPage:Disable()
    else
        Jueqing_Fuchi_Client2_DownPage:Enable()
    end
    
end

function Jueqing_Fuchi_GetCurDataPos_XiuLian(Dataidx)    
    local con,gift,data = Lua_GetGuanHuaiJueQingGuXiuLianData()
    if con == nil or gift == nil or data == nil then
        PushDebugMessage("Jueqing_Fuchi_Fresh_XiuLian nil 1")
        return -1
    end
    local specKaJi89 = Player : GetData("SPECKAJI89") 
    for i, v in ipairs(g_Jueqing_Fuchi_XiuLian_Data) do
        if specKaJi89 > 0 then
            if Dataidx == v.DataIdx and con[i] == 0 then
                return i
            elseif Dataidx == v.DataIdx and con[i] == 1 and gift[i] == 0 then
                return i 
            elseif Dataidx == v.DataIdx and g_Jueqing_Fuchi_XiuLian_Data[i].isFinal89 == 1 then
                return i
            end   
        end
        local kajiType = KaJi:LuaFnGetKaJiType(158)
        if kajiType == 1 then
            if Dataidx == v.DataIdx69 and con[i] == 0 then
                return i
            elseif Dataidx == v.DataIdx69 and con[i] == 1 and gift[i] == 0 then
                return i 
            elseif Dataidx == v.DataIdx69 and g_Jueqing_Fuchi_XiuLian_Data[i].isFinal69 == 1 then
                return i
            end    
        else
            if Dataidx == v.DataIdx and con[i] == 0 then
                return i
            elseif Dataidx == v.DataIdx and con[i] == 1 and gift[i] == 0 then
                return i 
            elseif Dataidx == v.DataIdx and g_Jueqing_Fuchi_XiuLian_Data[i].isFinal == 1 then
                return i
            end        
        end
    end
    return -1 
end

function Jueqing_Fuchi_Client2_PageUp()
    g_Jueqing_Fuchi_XiuLian_CurPage = g_Jueqing_Fuchi_XiuLian_CurPage -1 
    if g_Jueqing_Fuchi_XiuLian_CurPage <= 1 then
        g_Jueqing_Fuchi_XiuLian_CurPage = 1  
    end
    Jueqing_Fuchi_Fresh_XiuLian(1)
end

function Jueqing_Fuchi_Client2_PageDown()
    g_Jueqing_Fuchi_XiuLian_CurPage = g_Jueqing_Fuchi_XiuLian_CurPage + 1 
    if g_Jueqing_Fuchi_XiuLian_CurPage >= g_Jueqing_Fuchi_XiuLian_TotalPage then
        g_Jueqing_Fuchi_XiuLian_CurPage = g_Jueqing_Fuchi_XiuLian_TotalPage  
    end
    Jueqing_Fuchi_Fresh_XiuLian(1)
end

function Jueqing_Fuchi_Client2OKClick(id)
    local curidx = (g_Jueqing_Fuchi_XiuLian_CurPage-1)*g_Jueqing_Fuchi_XiuLian_PerPage  
    local pos = Jueqing_Fuchi_GetCurDataPos_XiuLian(curidx+id)
    if pos == -1 then
        PushDebugMessage("error 1")
        return
    end
    --if g_Jueqing_Fuchi_XiuLian_Data[pos] ~= nil and g_Jueqing_Fuchi_XiuLian_Data[pos].sel ~= nil and g_Jueqing_Fuchi_XiuLian_Data[pos].sel == 1 then        
    --    PushEvent("UI_COMMAND", 88892103, pos)
    --    return
    --end
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "GetGift" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 888922 );											-- 脚本编号  
        Set_XSCRIPT_Parameter( 0, pos);	 
        Set_XSCRIPT_ParamCount( 1 ); 	-- 参数个数  
    Send_XSCRIPT()	
end

--打开武林风云录
function Jueqing_Fuchi_Road_OpenWLFYL(nIndex)
		-- 打开UI
	local menpai = Player : GetData( "MEMPAI" );		--获取玩家门派ID
	if ( menpai < 0 or menpai > 15 or menpai == 9 ) then--menpai15 mptodo
		PushDebugMessage( "#{JDZY_120806_875}" );
		return
	end
		-- 等级	
		local nLevel = Player:GetLevel();	
		if ( nLevel < 30 ) then		
			PushDebugMessage("#{XSJNH_180112_236}")		
			return	
		end	
	Lua_ToggleFengyunlu();
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnClientBnClicked" );	-- 脚本入口
		Set_XSCRIPT_ScriptID( 290099 )						-- 脚本ID
		Set_XSCRIPT_ParamCount( 0 )							-- 参数个数
	Send_XSCRIPT()
	PushEvent("UI_COMMAND",2018012303,nIndex)
end
function Jueqing_Fuchi_Client2GotoClick(id)
    local curidx = (g_Jueqing_Fuchi_XiuLian_CurPage-1)*g_Jueqing_Fuchi_XiuLian_PerPage  
    local param0 = Jueqing_Fuchi_GetCurDataPos_XiuLian(curidx+id)
    if param0 == -1 then
        PushDebugMessage("error 1")
        return
    end     
    
    if param0 >= 1 and param0 <= 22 then --打开精彩活动界面 选中全天活动
        OpenTodayCampaignList(); 
	elseif param0 >= 23 and param0 <= 30 then --帮会界面
        Jueqing_Fuchi_Guild();  
	elseif param0 == 31 then --打开武林风云录 选中该暗器页签
        Jueqing_Fuchi_Road_OpenWLFYL(1)
    elseif param0 == 32 then --子女
        Jueqing_Fuchi_Road_OpenWLFYL(9)
	elseif param0 == 33 then -- 打开武林风云录 选中武魂
        Jueqing_Fuchi_Road_OpenWLFYL(11)
    elseif param0 == 34 then --手工
        AutoRunToTargetEx(367,249.4,1) 
    elseif param0 == 35 then --真元
        Jueqing_Fuchi_Road_OpenWLFYL(17)
    elseif param0 == 36 then 
        AutoRunToTargetEx(236,235,0)
    elseif param0 == 37 then 
        AutoRunToTargetEx(355,240,1)  
    elseif param0 == 38 then  
        AutoRunToTargetEx(236,235,0)
	end
end

function Jueqing_Fuchi_Guild() 
        if IsTBFinalServer() > 0 then
        --如果玩家当前在跨服总决赛特殊服务器,则直接打开雄霸天下界面,不用走其他判断,因为玩家肯定有帮会
            Guild:AskGuildMembersInfo();		--请求帮会数据信息
            ZhanTuanInterface:GetZhanTuanInfo();
            return
        end
      local guildID, clanID = DataPool:GetGuildClanID()
        local nAllianceID = Player:GetData("AllianceID") 
        --- 既没有势力，也没有帮会
        if guildID < 0 and clanID < 0 then
            PushDebugMessage( "你当前尚未加入帮会。请到洛阳（237，236）范纯仁处申请加入帮会，更好地体味江湖。" )
            --- 如果是在K服，还要再谈一条醒目提示
            --if KVKInterface:IsInKVKServer() == 1 then
              --  PushDebugMessage( "#{KVKSL_110628_72}" )
            --end
            return
        end
    
        --- 如果玩家既有势力，又有帮会
        if guildID >= 0 and (clanID >= 0 or nAllianceID>=0) then
            --- 如果是在K服，打开势力面板
            if KVKInterface:IsInKVKServer() == 1 then
                if nAllianceID>=0 then --打开战盟界面
                    --如果玩家拥有战盟，其在天外点击帮会按钮时，默认弹出战盟界面
                local alliancemark =0;
              end
            --- 如果是在原服，打开帮会面板
            else
                Guild:ToggleGuildDetailInfo()
            end
            return
        end
    
        --- 如果玩家没有势力，只有帮会, 无论如何，都打开帮会界面
        if guildID >= 0 and clanID < 0 then
            Guild:ToggleGuildDetailInfo()
            return
        end 
end

--=========
-- 礼包界面
--=========
function Jueqing_Fuchi_Fresh_LiBao(isopen)
    local ctltbl = g_Jueqing_Fuchi_LiBao_Ctl.itemctl 

    if isopen == 1 then
        for i, v in ipairs(ctltbl) do   
            local pos = Jueqing_Fuchi_GetCurDataPos_LiBao(i)
            if pos == -1 then
                PushDebugMessage("error 1")
                return
            end  
            g_Jueqing_Fuchi_LiBao_PageIdx[i] = pos  
        end
    end   
    local con,gift,data = Lua_GetGuanHuaiJueQingGuLiBaoData()
    if con == nil or gift == nil or data == nil then
        PushDebugMessage("Jueqing_Fuchi_Fresh_LiBao nil 1")
        return -1
    end
        
    Jueqing_Fuchi_Client3_Info_Text:SetText(ScriptGlobal_Format("#{JQGFC_220115_94}",g_Jueqing_Fuchi_EndYear,g_Jueqing_Fuchi_EndMonth,g_Jueqing_Fuchi_EndDay,g_Jueqing_Fuchi_EndHour));
   
    for i=1, table.getn(ctltbl) do 
        local pos = g_Jueqing_Fuchi_LiBao_PageIdx[i]
        ctltbl[i].ok:SetText("#{JQGFC_220115_16}")
        local numctrl  = ctltbl[i].num2
        local iconctrl = ctltbl[i].icon2 
        local ShowItemSize = table.getn(g_Jueqing_Fuchi_LiBao_Data[pos].ShowItem)
        if ShowItemSize == 2 then 
            ctltbl[i].jiangliBK2:Show() 
            ctltbl[i].jiangliBK3:Hide()
            numctrl  = ctltbl[i].num2
            iconctrl = ctltbl[i].icon2 
        else
            ctltbl[i].jiangliBK2:Hide() 
            ctltbl[i].jiangliBK3:Show()
            numctrl  = ctltbl[i].num3
            iconctrl = ctltbl[i].icon3 
        end

        local specKaJi89 = Player : GetData("SPECKAJI89") 
        if specKaJi89 > 0 then
            if g_Jueqing_Fuchi_LiBao_Data[pos].KaJiFix89 ~= nil and g_Jueqing_Fuchi_LiBao_Data[pos].KaJiFix89 == 1 then
                ctltbl[i].jiangliBK2:Show() 
                ctltbl[i].jiangliBK3:Hide()
                numctrl  = ctltbl[i].num2
                iconctrl = ctltbl[i].icon2 
                ShowItemSize = 2
            elseif ShowItemSize == 2 then 
                ctltbl[i].jiangliBK2:Show() 
                ctltbl[i].jiangliBK3:Hide()
                numctrl  = ctltbl[i].num2
                iconctrl = ctltbl[i].icon2 
            else
                ctltbl[i].jiangliBK2:Hide() 
                ctltbl[i].jiangliBK3:Show()
                numctrl  = ctltbl[i].num3
                iconctrl = ctltbl[i].icon3 
            end 
        end
        for index=1, ShowItemSize do
            local itemAction;	    
            if g_Jueqing_Fuchi_LiBao_Data[pos].ShowItem[index].Count > 1 then 
                numctrl[index]:Show()
                numctrl[index]:SetText(ScriptGlobal_Format("#{JQGFC_220115_172}", g_Jueqing_Fuchi_LiBao_Data[pos].ShowItem[index].Count))  
            else 
                numctrl[index]:Hide()
            end
            if g_Jueqing_Fuchi_LiBao_Data[pos].ShowItem[index].Bind == 1 then
                itemAction=DataPool:CreateBindActionItemForShow(g_Jueqing_Fuchi_LiBao_Data[pos].ShowItem[index].Id, 1)
            else
                itemAction=DataPool:CreateActionItemForShow(g_Jueqing_Fuchi_LiBao_Data[pos].ShowItem[index].Id, 1)
            end
            if itemAction:GetID() ~= 0 then
                iconctrl[index]:SetActionItem(-1)
                iconctrl[index]:SetActionItem(itemAction:GetID())
                ctltbl[i].name:SetText(g_Jueqing_Fuchi_LiBao_Data[pos].Text)
            end 
        end
        ctltbl[i].tips:SetText(g_Jueqing_Fuchi_LiBao_Data[pos].tips)
        ctltbl[i].redpoint:Hide()
        ctltbl[i].ok:Hide()
        ctltbl[i].dacheng:Hide()
        local con,gift,data = Lua_GetGuanHuaiJueQingGuLiBaoData()
        if con[pos] == 0 and gift[pos] == 0 then
            local idx =g_Jueqing_Fuchi_LiBao_Data[pos].Group
            ctltbl[i].jindu:SetText(ScriptGlobal_Format(g_Jueqing_Fuchi_LiBao_Text[idx].wdc,data[pos],g_Jueqing_Fuchi_LiBao_Data[pos].NeedValue))               
            ctltbl[i].ok:Show()        
        elseif con[pos] == 1 and gift[pos] == 0  then
            local idx =g_Jueqing_Fuchi_LiBao_Data[pos].Group
            ctltbl[i].jindu:SetText(ScriptGlobal_Format(g_Jueqing_Fuchi_LiBao_Text[idx].dc,g_Jueqing_Fuchi_LiBao_Data[pos].NeedValue,g_Jueqing_Fuchi_LiBao_Data[pos].NeedValue) )
            ctltbl[i].redpoint:Show()
            ctltbl[i].ok:Show()
        elseif con[pos] == 1 and gift[pos] == 1  then
            local idx =g_Jueqing_Fuchi_LiBao_Data[pos].Group
            ctltbl[i].jindu:SetText(ScriptGlobal_Format(g_Jueqing_Fuchi_LiBao_Text[idx].dc,g_Jueqing_Fuchi_LiBao_Data[pos].NeedValue,g_Jueqing_Fuchi_LiBao_Data[pos].NeedValue) )
            ctltbl[i].ok:Hide()
            ctltbl[i].dacheng:Show()
        end
    end
end

function Jueqing_Fuchi_GetCurDataPos_LiBao(Dataidx)    
    local con,gift,data = Lua_GetGuanHuaiJueQingGuLiBaoData()
    if con == nil or gift == nil or data == nil then
        PushDebugMessage("Jueqing_Fuchi_GetCurDataPos_LiBao nil 1")
        return -1
    end
    local zoneworldid =  DataPool:GetSelfZoneWorldID()
    for i, v in ipairs(g_Jueqing_Fuchi_LiBao_Data) do
        if Dataidx == v.Group and con[i] == 0 then
            return i
        elseif Dataidx == v.Group and con[i] == 1 and gift[i] == 0 then
            return i  
        elseif Dataidx == v.Group and g_Jueqing_Fuchi_LiBao_Data[i].isFinal_Gem == 1 and zoneworldid == g_Jueqing_Fuchi_GemZwid then
            return i
        elseif Dataidx == v.Group and g_Jueqing_Fuchi_LiBao_Data[i].isFinal == 1 then
            return i
        end        
    end
    return -1 
end

function Jueqing_Fuchi_Client3_Item_Click(id)
    local pos = g_Jueqing_Fuchi_LiBao_PageIdx[id]
    if pos == -1 then
        PushDebugMessage("error 1")
        return
    end 	    
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "GetGift" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 888923 );											-- 脚本编号
        Set_XSCRIPT_Parameter( 0, pos);	   
        Set_XSCRIPT_Parameter( 1, 0);	 
        Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数  
    Send_XSCRIPT()
end

function Jueqing_Fuchi_Client_Tab_Click(id) 
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "Click" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 888921 );											-- 脚本编号
        Set_XSCRIPT_Parameter( 0, id);	    
        Set_XSCRIPT_ParamCount( 1 ); 	-- 参数个数  
    Send_XSCRIPT()
end

function Jueqing_Fuchi_Client3_Item_LeftArrow_Click(idx)
    local nMin, nMax = Jueqing_Fuchi_Client3_GetByGroup(idx)
    if g_Jueqing_Fuchi_LiBao_PageIdx[idx] > nMin then
        g_Jueqing_Fuchi_LiBao_PageIdx[idx] = g_Jueqing_Fuchi_LiBao_PageIdx[idx] - 1
    end
    Jueqing_Fuchi_Fresh_LiBao(0)
end

function Jueqing_Fuchi_Client3_Item_RightArrow_Click(idx)
    local nMin, nMax = Jueqing_Fuchi_Client3_GetByGroup(idx) 
    if g_Jueqing_Fuchi_LiBao_PageIdx[idx] < nMax then
        g_Jueqing_Fuchi_LiBao_PageIdx[idx] = g_Jueqing_Fuchi_LiBao_PageIdx[idx] + 1
    end    
    Jueqing_Fuchi_Fresh_LiBao(0)
end

function Jueqing_Fuchi_Client3_GetByGroup(idx)
    local nMinPos = 0
    local nMaxPos = 0
    local zoneworldid =  DataPool:GetSelfZoneWorldID()
    for index, value in ipairs(g_Jueqing_Fuchi_LiBao_Data) do
        if value.Group == idx and nMinPos == 0 then
            nMinPos = index
        end
        if value.Group == idx and (value.isFinal_Gem~=nil and value.isFinal_Gem == 1 and zoneworldid == g_Jueqing_Fuchi_GemZwid) then 
            nMaxPos = index
            break
        elseif value.Group == idx and value.isFinal == 1 then
            nMaxPos = index        
        end
    end
    return nMinPos,nMaxPos
end

function Jueqing_Fuchi_Help_Client2_Clicked()
    local kajiType = KaJi:LuaFnGetKaJiType(158)
    if kajiType == 1 then
        PushEvent("CCSHOP_HELP", 221)        
    else
        PushEvent("CCSHOP_HELP", 150)
    end 
end

function Jueqing_Fuchi_Help_Client3_Clicked()
    local specKaJi89 = Player : GetData("SPECKAJI89")  
    local zoneworldid =  DataPool:GetSelfZoneWorldID()
    if zoneworldid == g_Jueqing_Fuchi_GemZwid then
        PushEvent("CCSHOP_HELP", 222)
    elseif specKaJi89 > 0 then
        PushEvent("CCSHOP_HELP", 223)
    else
        PushEvent("CCSHOP_HELP", 151)
    end
    
end