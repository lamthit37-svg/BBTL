--MisDescBegin
x998839_g_ScriptId = 998839
x998839_g_MainScriptId = 998840--主脚本号
x998839_g_KDZZID = 1006000605
x998839_g_MissionLevel = 30
x998839_g_Position_X=-1
x998839_g_Position_Z=-1
x998839_g_SceneID=-1
x998839_g_AccomplishNPC_Name=""
x998839_g_MissionName="#{ZMYR_230803_40}"
x998839_g_MissionId = 0
x998839_g_MissionKind = 143
x998839_g_IfMissionElite = 0
x998839_g_IsMissionOkFail = 0--任务完成标志位(一定要为0)
x998839_g_ParamCustom = 1--任务参数0-完成标记1-完成情况2-子任务类型3-随机索引
x998839_g_ParamType = 2--任务参数0-完成标记1-完成情况2-子任务类型3-随机索引
x998839_g_ParamIndex = 3--任务参数0-完成标记1-完成情况2-子任务类型3-随机索引
x998839_g_ParamMenPai = 4--任务参数4-接任务门派
x998839_g_MissionTarget=""--任务目标(任务面板中任务信息显示内容)
x998839_g_Custom = {}--自定义完成情况，内容不能使用字典，分别对应missionparam的第1位后延
x998839_g_NpcDist = 5
x998839_g_TypeEnum = { XunRen=1, Monster=2, Assist=3, }
x998839_g_XunRenNpc = 
{
[1] = { npcid = 7, sceneid = 0, tip = "#{ZMYR_230803_60}", },--洛阳游坦之154.9,221.8
[2] = { npcid = 237, sceneid = 2, tip = "#{ZMYR_230803_61}", },--大理刀白凤50,27
[3] = { npcid = 39, sceneid = 1, tip = "#{ZMYR_230803_62}", },--苏州朱丹臣248.2,162.9
}
x998839_g_MonsterNum = 5
x998839_g_MonsterId = 50861
x998839_g_BossNum = 1
x998839_g_BossId = 50875
x998839_g_BossAI = 19
x998839_g_ExtAI = 380
x998839_g_BossScript = 998837
x998839_g_BossDieTime = 5*60
x998839_g_AssistNum = 5
x998839_g_NpcList = {
[MP_SHAOLIN] = {menpaiid=MP_SHAOLIN,	menpainame="少林", npcname="#{ZMYR_230803_79}",	
npcid = 218, missionid = 3120, sceneid = 9, monsterid = 50847, link = "#{ZMYR_230803_65}"},
[MP_MINGJIAO] = {menpaiid=MP_MINGJIAO,	menpainame="明教", npcname="#{ZMYR_230803_80}",	
npcid = 55, missionid = 3121, sceneid = 11, monsterid = 50852, link = "#{ZMYR_230803_66}"},
[MP_GAIBANG] = {menpaiid=MP_GAIBANG,	menpainame="丐帮", npcname="#{ZMYR_230803_81}",	
npcid = 239, missionid = 3122, sceneid = 10, monsterid = 50851, link = "#{ZMYR_230803_67}"},
[MP_WUDANG] = {menpaiid=MP_WUDANG,	menpainame="武当", npcname="#{ZMYR_230803_82}",	
npcid = 19, missionid = 3123, sceneid = 12, monsterid = 50848, link = "#{ZMYR_230803_68}"},
[MP_EMEI] = {menpaiid=MP_EMEI,		menpainame="峨眉", npcname="#{ZMYR_230803_83}",
npcid = 45, missionid = 3124, sceneid = 15, monsterid = 50849, link = "#{ZMYR_230803_69}"},
[MP_XINGSU] = {menpaiid=MP_XINGSU,	menpainame="星宿", npcname="#{ZMYR_230803_84}",
npcid = 8, missionid = 3125, sceneid = 16, monsterid = 50850, link = "#{ZMYR_230803_70}"},
[MP_DALI] = {menpaiid=MP_DALI,		menpainame="天龙", npcname="#{ZMYR_230803_85}",
npcid = 222, missionid = 3126, sceneid = 13, monsterid = 50853, link = "#{ZMYR_230803_71}"},
[MP_TIANSHAN] = {menpaiid=MP_TIANSHAN,	menpainame="天山", npcname="#{ZMYR_230803_86}",	
npcid = 37, missionid = 3127, sceneid = 17, monsterid = 50854, link = "#{ZMYR_230803_72}"},
[MP_XIAOYAO] = {menpaiid=MP_XIAOYAO,	menpainame="逍遥", npcname="#{ZMYR_230803_87}",	
npcid = 30, missionid = 3128, sceneid = 14, monsterid = 50855, link = "#{ZMYR_230803_73}"},
[MP_GUSU] = {menpaiid=MP_GUSU,	menpainame="慕容", npcname="#{ZMYR_230803_88}",
npcid = 10084, missionid = 3129, sceneid = 195, monsterid = 50856, link = "#{ZMYR_230803_74}"},
[MP_TANGMEN] = {menpaiid=MP_TANGMEN,	menpainame="唐门", npcname="#{ZMYR_230803_89}",
npcid = 16464, missionid = 3130, sceneid = 521, monsterid = 50857, link = "#{ZMYR_230803_75}"},
[MP_GUIGU] = {menpaiid=MP_GUIGU,	menpainame="鬼谷", npcname="#{ZMYR_230803_90}",
npcid = 16855, missionid = 3131, sceneid = 587, monsterid = 50858, link = "#{ZMYR_230803_76}"},
[MP_TAOHUADAO] = {menpaiid=MP_TAOHUADAO,	menpainame="桃花岛", npcname="#{ZMYR_230803_91}",
npcid = 17035, missionid = 3132, sceneid = 1124, monsterid = 50859, link = "#{ZMYR_230803_77}"},
[MP_MENPAI14] = {menpaiid=MP_MENPAI14,	menpainame="绝情谷", npcname="#{ZMYR_230803_92}",
npcid = 17201, missionid = 3133, sceneid = 1148, monsterid = 50860, link = "#{ZMYR_230803_78}"},
}
x998839_g_BagSpace = 1
x998839_g_MatSpace = 1
x998839_g_PrizeId = 20310168
x998839_g_PrizeList = 
{
[1] = {id=30008034,rand=3000,},
[2] = {id=30700241,rand=6000,},
[3] = {id=38001595,rand=7500,},
[4] = {id=38000807,rand=10000,},
}
--MisDescEnd
