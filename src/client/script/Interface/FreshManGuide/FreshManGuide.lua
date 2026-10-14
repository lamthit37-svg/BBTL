-- 新手指引ui
-- created by gongxiaobo, Sep 21st, 2011

-- modified, Nov 10th, 2011     --!!!reloadscript =FreshManGuide
-- 调整一下,希望使用起来更方便一些。。。maybe
-- 另有1中可能的做法,是仿照cegui的tooltip来实现,不过底层要加不少,想来想去,还是算了

local g_Frame_Width = 0
local g_Frame_Height = 0

local g_Frame_SizeRaw = ""
local g_Lace_SizeRaw = ""

local g_Ctl_Corner = {}
local g_cached_textstr=""
local g_Text = {
    [1] = "#{XSRWGZ_110917_01}",
    [2] = "#{XSRWGZ_110917_02}",
    [3] = "#{XSRWGZ_110917_03}",
    [4] = "#{XSRWGZ_110917_04}",
    [5] = "#{XSRWGZ_110917_05}",
    [6] = "#{XSRWGZ_110917_06}",
    [7] = "#{XSRWGZ_110917_07}",
    [8] = "#{XSRWGZ_110917_11}",
    [9] = "#{XSRWGZ_110917_12}",
    [10] = "#{XSRWGZ_110917_13}",
    [11] = "#{XSRWGZ_110917_20}",
    [12] = "#{XSRWGZ_110917_21}",
    [13] = "#{XSRWGZ_110917_22}",
    [14] = "#{XSRWGZ_110917_23}",
    [15] = "#{XSRWGZ_110917_38}",
    [16] = "#{XSRWGZ_110917_39}",
    [17] = "#{XSRWGZ_110917_41}",
    [18] = "#{XSRWGZ_110917_50}",
    [19] = "#{XSRWGZ_110917_51}",
    [20] = "#{XSRWGZ_110917_107}",
    [21] = "#{XSRWGZ_110917_115}",
	[22] = "#{MPJJRW_110805_769}",--经脉界面
	[23] = "#{YLK_120307_24}",--周卡提示
	[24] = "#{ZYRW_120522_22}",  --点击初级凝练可获得真元
	[25] = "#{ZYRW_120522_23}",  --选中真元点击拾取，可将其放入真元包裹
	[26] = "#{ZYRW_120522_34}",  --选中任意盘眼后点击激活按钮，通过消耗真元碎片成功激活真元盘眼。
	[27] = "#{ZYRW_120522_35}",  --请将右侧的真元拖入已激活的盘眼中。
	[28] = "#{ZYRW_120522_36}",  --点击后可通过消耗元晶升级真元
	[29] = "#{ZYRW_120522_46}",  --点击可获得真元并有机会激活低级凝练
	[30] = "#{ZYRW_120522_47}",  --点击后有机会获得高品阶真元并有机会激活中极凝练
	[31] = "#{ZYRW_120522_48}",  --选中界面中的真元后点击炼化可获得元晶
	[32] = "#{ZYRW_120522_49}",  --将真元拖入此处，可直接炼化为元晶。真元品质、等级越高，炼化后获得的元晶也就越多
	[33] = "#{ZYRW_120522_59}",  --点击后通过消耗元晶升级真元
	[34] = "#{BBGX_120809_1}",
	[35] = "#{JDZY_120806_01}", --点击后可查看武林风云录，通过武林风云录可以查看%s0#cffff00的相关任务，完成任务后，可获得到%s1#cffff00等大礼！
	[36] = "#{JDZY_120806_33}", --点击后可查看武林风云录，完成相关任务可以获取价值不菲的神秘礼物！
	[37] = "#{WBSS_120727_93}", --装备位上可以一次镶嵌多颗宝石
	[38] = "#{JYYD_121010_06}", --点击此处即可前往玲珑岛中，一探究竟。
	[39] = "#{ZHYTS_120105_02}", --周活跃宝箱领奖提示
	[40] = "#{ZHYTS_120105_02}", --周活跃宝箱领奖提示
	[41] = "#{ZHYTS_120105_02}", --周活跃宝箱领奖提示
	[42] = "#{ZHYTS_120105_02}", --周活跃宝箱领奖提示
	[43] = "#{WLMJRW_20130226_26}",	-- 武林秘籍: 还未学习秘籍，右击背包道具栏中的武林秘籍即可学习。
	[44] = "#{WLMJRW_20130226_27}",	-- 武林秘籍: 在此可以查看已经学习的武林秘籍。
	[45] = "#{WLMJRW_20130226_45}",	-- 武林秘籍: 将一段式拖拽至任意快捷栏位中。
	[46] = "#{WLMJRW_20130226_67}",	-- 武林秘籍: 武学心得可以用来提升秘籍的层数，秘籍的层数越高，使用一段式后激活二段式和使用二段式后激活三段式的几率越大，同时还会更多的修为。
	[47] = "#{WLMJRW_20130226_80}",	-- 武林秘籍: 点击可以升级左侧已学习秘籍的领悟境界
	[48] = "#{WLMJRW_20130226_81}", -- 武林秘籍: 秘籍领悟境界提升，修为增加，修为越高，使用秘籍招式后，招式效果越大。
	[49] = "#{MDJH_130507_01}",		--名动江湖，惊喜送不停！点此立即参与其中。
	[50] = "#{FQBS_140508_5}",		--6月19日至6月26日宝石理财计划期间，可以通过分期付款的方式来购买5级、6级、7级宝石。
	[51] = "#{FQBS_140508_6}",		--您当前通过分期付款购买的宝石中，有一个即将失效，请尽快还款以保证宝石的正常使用。
	[52] = "#{FQBS_140508_7}",		--您当前通过分期付款购买的宝石中，有一个已经失效了，请尽快还款以保证宝石的正常使用。
	[53] = "#{ZZQH_140606_01}",	--至尊精华超值赠，神装强化回馈礼！点此立即参与其中。
	[54] = "#{YMQK_140612_33}",   --侠誉豪情满乾坤，金丹馈赠真英雄
	[55] = "#{YMQK_140612_34}",		--尚有金丹还未领取，请在6月22日24时前尽快领取。
	[57] = "#{JSXL_140821_5}",		--9月1日至9月7日活动期间，在本界面购买金蚕丝，将能获赠额外数量的金蚕丝或1个饰品体力雕纹图样。
	[62] = "#{NQLT_141118_04}",		--#Y最新游戏资讯，最强热度话题，每周四更新，请点击查看！
	[63] = "#{QRPHB_150113_3}",		--#Y点击打开情人节排行榜活动
	[64] = "#{BZNMR_150129_1}",
	[66] = "#{ZNJM_150430_1}",
	[67] = "#{XBZB_150511_1}",
	[68] = "#{QFHD_150519_1}",		-- #G2015年5月28日#Y更新后至#G6月3日24时#W活动期间，祈福以获得更丰厚的经验奖励！
	[69] = "#{KPLS_150527_4}",		--消费送好礼，卡牌升级道具送不停
	[70] = "#{KPLS_150527_6}",		--尚有卡牌升级道具还未领取，请在6月24日24时前尽快领取。
	[71] = "#{KPGM_150529_5}",		--6月18日至6月24日活动期间，可在本界面购买博闻集，用以装帧橙色子女典籍。
	[72] = "#{KPLS_150527_10}",		--消费送好礼，卡牌升级道具送不停
	[73] = "#{SJFL_150608_1}",		--为庆祝《新天龙八部》暑假来临，英雄共战。特在6月29日至7月5日期间开启双倍经验、双倍掉落，且每日登录 均有好礼相送，点击查看详情！
	[74] = "#{JBZY_150629_57}",		--结拜引导任务 #Y首先，点击打开好友界面！
	[75] = "#{JBZY_150629_60}",		--结拜引导任务 #Y在这里，各位大侠可以查看自己的#G江湖关系#Y哦~请点击打开！
	[76] = "#{JBZY_150629_61}",		--结拜引导任务 #Y江湖浩大，你一定不能没有一群与你肝胆相照的结义兄弟！#G结义阵法#Y就是为了结义兄弟所创的绝世奇法！点击打开#G结义界面#Y！
	[77] = "#{JBZY_150629_62}",		--结拜引导任务 #Y点击#G阵法设置#Y按钮，打开查看你已经获得的#G结义阵法#Y！
	[78] = "#{JBZY_150629_90}",		--结拜引导任务 #Y在这里你能查看你所拥有的情义值！现在请选择任意一种阵法，将其升至#G0阶1级#Y！
	[79] = "#{JBZY_150629_63}",		--结拜引导任务 #Y在这里，便可以查看你可以进行修习的阵法了！下一步便让我们来学习如何#G升级阵法#Y，请先交还本任务哦！
	[80] = "#{TLHSY_150716_1}",		--天龙好声音第一次登陆按钮tips
	[81] = "#{TLHSY_150716_2}",		--天龙好声音第一次登陆按钮tips
	[82] = "#{QXLS_150724_03}",		--七夕情人节活动
	[83] = "#{ZBSZB_150803_5}",		--9月18日、9月19日： 《新天龙八部》全球争霸赛八进四比赛正在激烈进行中，点击按钮即可观看精彩的比赛实况直播。
	[84] = "#{ZBSZB_150803_6}",		--9月25日： 《新天龙八部》全球争霸赛半决赛正在激烈进行中，点击按钮即可观看精彩的比赛实况直播。
	[85] = "#{ZBSZB_150803_7}",		--9月26日： 《新天龙八部》全球争霸赛总决赛正在激烈进行中，点击按钮即可观看精彩的比赛实况直播。
	[86] = "#{YMQK_150914_03}",		--侠誉豪情满乾坤，金丹馈赠真英雄
	[87] = "#{YMQK_150914_05}",		--尚有坤武金丹还未领取，请在9月24日24时前尽快领取。
	[88] = "#{ZDZYH_151012_5}",		--2015年10月31日21点至22点期间累计在线达到半个小时的玩家，可点击此按钮抽取紫电大奖
	[89] = "#{BZYJ_151123_08}",		--点击查看百战英杰铸精通活动
	[90] = "#{ZNHK_151201_04}",		--子女典籍超值馈，典籍注解研习送
	[91] = "#{ZNHK_151201_06}",		--您有尚未兑换的研习幸运值，请在12月27日24点前进行兑换。
	[92] = "#{MGCQ_151230_03}",		--#Y点击打开情人节排行榜活动
	[93] = "#{KSQX_160107_2}",		--#Y“犒赏群雄”新年晚会直播进行中，点击进入直播间。
	[94] = "#{KSQX_160107_1}",		--#Y“犒赏群雄”新年晚会将于2016年1月15日晚19:30~22:00进行直播，精彩内容敬请期待！
	[95] = "#{KSQX_160107_3}",		--#Y“犒赏群雄”新年晚会完满结束，可在官网查看精彩内容。
	[96] = "#{XLQK_160414_01}",		--#Y“#G袖里乾坤#Y”庆祝晚会将于#G2016年4月28日20：00至22：00#Y进行直播，精彩内容敬请期待！
	[97] = "#{XLQK_160414_02}",		--#Y“#G袖里乾坤#Y”庆祝晚会将于#G2016年4月29日19：30至22：00#Y进行直播，精彩内容敬请期待！
	[98] = "#{XLQK_160414_03}",		--#Y“#G袖里乾坤#Y”庆祝晚会将于#G2016年4月30日15：00至16：30#Y进行直播，精彩内容敬请期待！
	[99] = "#{XLQK_160414_04}",		--#Y“#G袖里乾坤#Y”庆祝晚会直播进行中，点击此处进入直播间。
	[100] = "#{XLQK_160415_09}",	--“袖里乾坤”精彩游戏活动直播进行中，点击此处进入直播间。
	[101] = "#{CXGYL_160818_2}",	--今晚21点至22点，登陆畅秀阁并观看直播30分钟即可参与抽奖，最高奖励为永久坐骑：金羽！
	[102] = "#{CXGYL_160818_3}", --秀阁有佳人，绝世而独立，媚眼含羞合，丹唇逐笑开！
	[103] = "#{ZZHKHD_160817_37}",	--与绑定荣归关系的好友完成特定副本活动，赢取江湖故人情丰厚奖励！
	[104] = "#{ZBS16_160902_485}",	--直播：荣耀之战，2016争霸赛大区赛对决即将开始
	[105] = "#{ZBS16_160902_486}",	--直播：荣耀之战，2016争霸赛三十二强赛对决即将开始
	[106] = "#{ZBS16_160902_487}",	--直播：荣耀之战，2016争霸赛十六强强赛对决即将开始
	[107] = "#{ZBS16_160902_488}",	--直播：荣耀之战，2016争霸赛八强赛对决即将开始
	[108] = "#{ZBS16_160902_489}",	--直播：荣耀之战，2016争霸赛半决赛对决即将开始
	[109] = "#{ZBS16_161018_499}",	--争霸赛线下总决赛即将开幕，精彩尽在“畅秀阁”！
	[110] = "#{ZBS16_160902_491}",	--直播：谁能问鼎天龙？争霸赛总决赛现场直播即将开始
	[111] = "#{ZBS16_160902_492}",	--群雄激战，争霸赛大区赛火热直播进中
	[112] = "#{ZBS16_160902_493}",	--强强对决，争霸赛三十二强比赛火热直播中
	[113] = "#{ZBS16_160902_494}",	--强强对决，争霸赛十六强比赛火热直播中
	[114] = "#{ZBS16_160902_495}",	--强强对决，争霸赛八强比赛火热直播中
	[115] = "#{ZBS16_160902_496}",	--强强对决，争霸赛半决赛火热直播中
	[116] = "#{ZBS16_160902_497}",	--荣耀之战！争霸赛总决赛现场火热直播中
	[117] = "#{ZBS16_160902_498}",	--最强王者即将决出！争霸赛总决赛现场直播中
	[118] = "#{MPDJM_160809_03}",	--打开鬼谷解密活动
	[119] = "#{JYWYD_161024_20}",	--家园引导任务 点击打开庭院家具仓库，可将庭院家具摆放在庄园庭院内。
	[120] = "#{JYWYD_161024_21}",	--家园引导任务 点击摆放按钮后，再选中任意家具，可进入摆放状态。摆放状态中，在庄园地面点击鼠标可将家具摆放在庄园之中。
	[121] = "#{JYWYD_161024_60}",	--家园引导任务 点击该按钮，为庄园开始开采矿石。
	[122] = "#{JYWYD_161024_93}",	--家园引导任务 点击该按钮，为庄园开始种植树木。
	[123] = "#{JYWYD_161024_123}",	--家园引导任务 点击该按钮，为庄园开始播撒鱼苗。
	[124] = "#{JYWYD_161024_155}",	--家园引导任务 点击该按钮，为庄园制造1个居室家具。
	[125] = "#{JYWYD_161024_188}",	--家园引导任务 点击该按钮，合成1个庄园居室家具。
	[126] = "#{JYWYD_161024_211}",	--家园引导任务 点击打开居室家具仓库，可将背包内的居室家具存放入居室家具仓库。
	[127] = "#{JYWYD_161024_212}",	--家园引导任务 点击存放家具按钮后，打开存放家具界面，可将背包内的居室家具放入该界面，存放入家具仓库。
	[128] = "#{JYWYD_161024_214}",	--家园引导任务 点击摆放按钮后，再选中居室家具，可进入摆放状态。摆放状态中，在庄园居室地面点击鼠标可将居室家具摆放在庄园居室内。
	[129] = "#{JYWYD_161024_354}",	--家园引导任务 #Y点击该按钮，打开#G床帐列表#Y
	[130] = "#{JYWYD_161024_355}",	--家园引导任务 #Y选中该列，合成#G1#Y个#G架子床（2级）。
	[131] = "#{WSNS_160819_24}",	--广大玩家期盼已久的天龙女神评选再度开启，点击按钮查看相关信息。。
	[132] = "#{JJXH_161122_2}",		--冬日渐远，春回大地，点击查看九九消寒详细信息
	[133] = "#{MYQD_170621_02}", 	--1月签到提示
	[134] = "#{MYQD_170621_02}",	--2月签到提示
	[135] = "#{SDKHP_161220_02}",	--秀场圣诞活动提示
	[136] = "#{MYQD_170214_48}",	--周年庆签到
	[137] = "#{CXGHD_170220_01}",	--第一少林“至尊乄笑我狂”访谈正在进行中
	[138] = "#{CXGT_170306_01}",	--#Y神秘白富美亲临、甜美献唱，花漾大Party火热进行中
	[139] = "#{CXGT_170306_02}",	--#Y女神现场抽取天马、永久时装。点击前往现场抽抽抽！
	[140] = "#{CXGT_170306_03}",	--#Y花漾女生甜美开唱，活力满满大秀舞姿。精彩正在直播中
	[141] = "#{CXGTIP_170327_01}",	--看直播，开宝箱！精彩无极限，好礼领不停，点击进入观看。
	[142] = "#{CXGZNQ_170504_01}",   --十周年玩家庆典正在进行中，看直播领奖品！
	[143] = "#{CXGZNQ_170504_02}",	--新版主题曲抢先听，古风女神玄觞现身。
	[144] = "#{TYQS_170424_04}",		--龙腾十载普天庆，金玉飞花春满城，点击打开天龙庆生图。
	[145] = "#{CXGT_170612_04}",    --意想不到的cos秀，他们怎么是这样的主播？！
	[146] = "#{CXGT_170612_05}",    --当红主播私藏解暑神器揭秘进行中~
	[147] = "#{CXGT_170612_06}",     --嗨歌盛日趴引爆你的激情！
	[148] = "#{QLSX_170620_4}" ,   --晴日暖风生麦气，绿荫幽草胜花时，点击打开清凉盛夏。
	[149] = "#{MYQD_170621_02}",     --暑期签到
	[150] = "#{CXGHD_170909_01}",     --#Y10W元宝大放送，点击观看即可参与~
	[151] = "#{ZBS16_170811_507}",     --争霸赛晋级赛，大战一触即发！
	[152] = "#{ZBS16_170811_508}",     --全服高手集结，谁能杀入32强？
	[153] = "#{ZBS16_170811_509}",     --争霸赛巅峰对决， 究竟谁是大区王者？
	[154] = "#{ZBS16_170811_510}",     --争霸赛火热进行中，美女主播邀你观战~
	[155] = "#{ZBS16_170811_511}",     --争霸赛晋级赛，惊喜尖叫不间断！
	[156] = "#{ZBS16_170811_512}",     --争霸赛大区高手巅峰对决，究竟谁才是no.1？
	[157] = "#{ZBS16_170811_513}",     --争霸赛32强究竟花落谁家？快来观战吧！
	[158] = "#{ZBS16_170811_514}",     --惊呆！争霸赛32强竟然是他们！
	[159] = "#{ZBS16_170811_515}",     --争霸赛总决赛，王者江湖，即刻开启。
	[160] = "#{ZBS16_170811_516}",     --争霸赛总决赛，这一次，只为荣耀而战！
	[161] = "#{ZBS16_170811_517}",     --争霸赛总决赛16强，今夜揭晓。
	[162] = "#{ZBS16_170811_518}",     --16支战队突出重围，成为争霸赛王者。
	[163] = "#{ZBS16_170811_519}",     --争霸赛总决赛，为了兄弟，背水一战！
	[164] = "#{ZBS16_170811_520}",     --争霸赛角逐八强战场，激情厮杀中~
	[165] = "#{ZBS16_170811_521}",     --争霸赛八强今晚揭晓，激情解说陪你观战。
	[166] = "#{ZBS16_170811_522}",     --八强战队强势来袭，大神操作迷人双眼！
	[167] = "#{ZBS16_170811_523}",     --王者战队强强对决，竟然还有这种操作？
	[168] = "#{ZBS16_170811_524}",     --王者战队强势PK，四强花落谁家？
	[169] = "#{ZBS16_170811_525}",     --为了兄弟浴血奋战，四强战队稍后产出！
	[170] = "#{ZBS16_170811_526}",     --十年磨一剑，争霸赛四强原来是他们！
	[171] = "#{ZBS16_170811_527}",     --巅峰对决，争霸赛半决赛即将开战！
	[172] = "#{ZBS16_170811_528}",     --爱恨情仇，就今夜，有个了断，争霸赛前两名战队出线！

	[174] = "#{JXYD_200916_100}",	--【九星神器引导任务】
	[175] = "#{JXYD_200916_101}",	--【九星神器引导任务】
	[176] = "#{JXYD_170817_97}",	--【九星神器引导任务】
	[177] = "#{JXYD_200916_103}",	--【九星神器引导任务】
	[178] = "#{JXYD_200916_104}",	--【九星神器引导任务】
	[179] = "#{JXYD_200916_117}",	--【九星神器引导任务】
	[180] = "#{MCYD_170812_40}",     --点击打开萌宠小窝，可将背包内的萌宠存放至萌宠仓库。
	[181] = "#{MCYD_170812_41}",     --点击存放萌宠按钮后，打开存放萌宠界面，可将背包内的萌宠放入该界面，存放入萌宠仓库。
	[182] = "#{MCYD_170812_45}",     --选择萌宠仓库内的萌宠，点击召出按钮后，将其在庄园庭院召出。
	[183] = "#{MCYD_170812_60}",     --点击打开萌宠小窝，对已召出萌宠进行喂养。
	[184] = "#{MCYD_170812_94}",     --点击喂养萌宠，每次喂养消耗1个新鲜口粮。
--	[185] = "#{MCYD_170812_73}",     --点击打开萌宠小窝，可将已成年的萌宠取回进行萌宠繁殖。
--	[186] = "#{MCYD_170812_74}",     --需先选择已召出的成年萌宠，将其收回至仓库。
--	[187] = "#{MCYD_170812_75}",     --选择萌宠仓库中的成年萌宠，将其取回至背包，即可参与繁殖?

	[192] = "#{JXYD_200916_117}",	--【九星神器引导任务】
	[193] = "#{JXYD_200916_56}",	--【九星神器引导任务】神器开蒙
	[194] = "#{JXYD_200916_57}",	--【九星神器引导任务】神器开蒙
	[195] = "#{JXYD_200916_58}",	--【九星神器引导任务】神器锻灵
	[196] = "#{JXYD_200916_59}",	--【九星神器引导任务】神器锻灵
	[197] = "#{WYYD_20170809_32}",  --【武意任务引导】
	[198] = "#{WYYD_20170816_65}",  --【武意任务引导】
	[199] = "#{WYYD_20170809_40}",  --【武意任务引导】
	[200] = "#{WYYD_20170816_127}", --【武意任务引导】
	[201] = "#{CXGTIPS_180601_14}", --大花袄热炕头，主播带你东北过大年~
	[202] = "#{CXGTIPS_180714_02}", --你的女神教你剪窗花
	[203] = "#{CXGTIPS_180714_03}", --现场捏只吉祥狗
	[204] = "#{CXGTIPS_180714_04}", --逛老北京庙会赏民俗
	[205] = "#{CTIPS_180625_05}", --这个主播可以上春晚
	[206] = "#{CTIPS_180625_06}", --一舞倾人城，再舞倾人国
	[207] = "#{CTIPS_180625_07}", --我画的是你的情怀
	[208] = "#{CTIPS_180625_08}", --你有一份饺子待领取
	[209] = "#{CXGTIPS_180514_3}", --2018天龙春晚直播开启
	[210] = "#{CXGTIPS_180514_4}", --云霄羽翼随你拿！萌妹老歌新唱
	[211] = "#{CXGTIPS_180514_5}", --春晚经典《相约1998》神还原
	[212] = "#{CXGTIPS_180514_6}", --升级版段子手，跨界cos白云、黑土
	[213] = "#{CXGTIPS_180402_13}", --#让礼盒飞！天龙全家福之最火热评选中
	[214] = "#{CXGTIPS_180402_14}", --进场参与！定制iPhone即将开奖
	[215] = "#{CXGTIPS_171212_07}", --#Y人美厨艺佳，天龙网剧女主喊你开饭啦
	[216] = "#{CXGTIPS_171212_08}", --《拜见》女主包包私藏好物大起底
	[217] = "#{CXGTIPS_171212_09}", --#Y天龙网剧女主直播中，搜狐视频VIP年卡随机抽
	[218] = "#{CXGW_171127_02}", --#Y同等配置，武意全开，天龙top操作手精彩对决中！
	[219] = "#{CXGW_171127_03}", --#Y天龙操作手top8即将诞生，定制版iPhone花落谁家！
	[220] = "#{MCYD_170812_120}", --点击打开萌宠乐园，可将萌宠乐园中的一代成年萌宠取回到背包。
	[221] = "#{MCYD_170812_121}", --请先选择一代成年萌宠。
	[222] = "#{MCYD_170812_122}", --点击将一代成年萌宠取回到背包中。
	[223] = "#{CXGTIPS_180714_05}", --#Y没眼看！网剧女主献唱，经纪人尬舞~
	[224] = "#{CXGTIPS_180714_06}", --千元点卡随你拿！网剧女主人美歌甜气质佳~
	[225] = "#{CXGTIPS_180714_07}", --网剧双美带你重温与男主的那些事儿
	[226] = "#{YDHD_171206_06}", --群英贺岁，相逢见礼，点击打开福运赠英豪。
	[227] = "#{CJYJ_180104_07}", --爆竹声中一岁除，春风送暖入屠苏，点击打开贺新春界面，共度欢乐新年
	[228] = "#{CJYJ_180104_10}", --倚剑战八方，贺岁傲江湖，点击打开战江湖界面。
	[229] = "#{QMZJ_180308_72}", --煮酒青梅次第尝，啼莺乳燕占年光。点击打开青梅煮酒界面
	[230] = "#{QMQT_180309_01}", --2018清明节活动-ypl
	[231] = "#{SEZN_190326_2}", --2018周年庆
	[232] = "#{SEZN_190326_3}", --2018周年庆
	[233] = "#{SYZN_180313_02}", --2018周年庆
	[234] = "#{QZN_180322_169}", --2018迎庆典
	[235] = "#{QZN_180322_216}", --2018迎庆典 可点击此按钮，召唤并喂养您专属的蛋蛋鸡幼崽！
	[236] = "#{SEZN_190326_4}", --2018迎庆典 可点击此按钮，召唤并喂养您专属的蛋蛋鸡幼崽！
	[237] = "#{YYGB_180511_03}", --爱重非金玉，殷勤谢与君。在520告白日，13时14分这个特殊的时刻，请收下天龙人对您的真情告白。
	[238] = "CXG_TIPS_TEXT_01", --畅秀阁tips专用
	[239] = "CXG_TIPS_TEXT_02", --畅秀阁tips专用
	[240] = "CXG_TIPS_TEXT_03", --畅秀阁tips专用
	[241] = "#{GQYJ_180818_09}", --2018国庆
	[242] = "#{GQYJ_180818_10}", --2018国庆
	[243] = "#{GQYJ_180818_138}", --2018国庆
	[244] = "#{MYQD_170721_03}", --11月签到
	[245] = "#{RACL_181206_08}", --2018Q4春节引导任务
	[246] = "#{RACL_181206_09}", --2018Q4春节引导任务
	[247] = "#{RACL_181206_10}", --2018Q4春节引导任务
	[248] = "#{RACL_181206_11}", --2018Q4春节引导任务
	[249] = "#{ZNYR_190316_02}", --2019Q1周年庆
	[251] = "#{QHNF_190429_04}", --2019Q1周年庆
	[252] = "#{QXHF_190620_02}", --2019Q1七夕
	[253] = "#{GQKJ_190722_03}", --2019国庆
	[254] = "#{ZQJL_190725_18}", --2019中秋
	[255] = "#{JBHL_190803_02}", --结伴回流
	[256] = "#{MPYR_190902_02}", --门派预热
    [257] = "#{DFZB_191115_03}",
    [258] = "#{ZNYR_200302_103}",
    [259] = "#{XZYD_200401_61}",--星阵系统引导任务
    [260] = "#{XGSD_200609_01}", --2020西瓜节
	[261] = "#{JFZH_200721_01}", --2020金枫节
	[262] = "#{XCCJ_190829_16}", --2020嘉年华直播
	[263] = "#{ZJWF_201231_01}",
	[264] = "#{MPYR_210830_02}", --2021Q3预热
	[265] = "#{XFYJ_211029_03}", --2021 双旦
	[266] = "#{CJYJ_1211125_12}", --倚剑战八方，贺岁傲江湖，点击打开战江湖界面。
	[268] = "#{HZYR_211222_75}", --花朝节
	[269] = "#{BSLK_220211_03}", --周年预热打卡
	[270] = "#{CFSN_220224_05}", --春风送暖
	[271] = "#{TWHD_220803_20}", --新天外
	[272] = "#{ZDZYH_230315_11}", --飞凰 5.8
	[273] = "#{ZDZYH_230315_12}", --飞凰 5.9
	[274] = "#{ZDZYH_230315_13}", --飞凰 5.10
	[275] = "#{ZDZYH_230315_19}", --飞凰 5.8
	[276] = "#{ZDZYH_230315_20}", --飞凰 5.9
	[277] = "#{ZDZYH_230315_21}", --飞凰 5.10
	[278] = "#{ZDZYH_230315_18}", --飞凰 
	[279] = "#{FPLS_240715_01}", --翻牌子活动
	[280] = "#{ZBZB_250902_02}", --争霸赛直播
	[281] = "#{ZBZB_250902_03}", --争霸赛直播
	[282] = "#{XFSJ_20250814_10}",
	}
 
local g_X_Offset = 0  --相对目标窗口的偏移
local g_Y_Offset = 0  --同上
local g_Direct   = "" --相对目标窗口的方位

local g_cached_textid = -1

function FreshManGuide_PreLoad()
	this:RegisterEvent("OPEN_FRESHMAN_GUIDE")
	this:RegisterEvent("CLOSE_FRESHMAN_GUIDE")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function FreshManGuide_OnLoad()

	--note：two varibles below will be set to string in fact, so do not compare with number directly.
	g_Frame_Width  = FreshManGuide_Frame:GetProperty("AbsoluteWidth")
	g_Frame_Height = FreshManGuide_Frame:GetProperty("AbsoluteHeight")

	g_Frame_SizeRaw = FreshManGuide_Frame:GetProperty("UnifiedSize")
	g_Lace_SizeRaw = FreshManGuide_Lace:GetProperty("UnifiedSize")

	g_Ctl_Corner = {  --顺时针,四个角
        FreshManGuide_UpLeft,
        FreshManGuide_UpRight,
        FreshManGuide_DownRight,
        FreshManGuide_DownLeft,
    }
end

function FreshManGuide_OnEvent(event)
	if event == "OPEN_FRESHMAN_GUIDE" then
		--Lua_TDU_Log("OPEN_FRESHMAN_GUIDE 1");
		if 1 ~= FreshManGuide_CheckSize(tonumber(arg4), tonumber(arg5)) then
			--Lua_TDU_Log("FreshManGuide_OnEvent 1");
			
	        return  -- 客户端主窗口比本界面还小,不予显示了就
	    end
		if "" == GetFreshManGuideOwner() and tonumber(arg0) ~= 3 then
			--Lua_TDU_Log("FreshManGuide_OnEvent 2");
			
	        return  -- 必须要有目标窗口
		end
		--Lua_TDU_Log("tonumber(arg0)"..tonumber(arg0));
	    if 1 == tonumber(arg0) then
            FreshManGuide_Reset(tonumber(arg0), tonumber(arg1), tonumber(arg2), tonumber(arg3), tonumber(arg4), tonumber(arg5), arg6)
		elseif 2 == tonumber(arg0) and this:IsVisible() then
			if g_cached_textid ~= -1 then
				FreshManGuide_Modify(g_cached_textid, "", tonumber(arg1), tonumber(arg2), tonumber(arg3), tonumber(arg4), tonumber(arg5), arg6) 
			end 
		elseif 3 == tonumber(arg0) then
			SetFreshManGuideForPlayerQuickEnter()
			--Lua_TDU_Log("OPEN_FRESHMAN_GUIDE 2");			
            FreshManGuide_Reset(tonumber(arg0), tonumber(arg1), tonumber(arg2), tonumber(arg3), tonumber(arg4), tonumber(arg5), arg6)
        end
        return
	end

	if event == "ADJEST_UI_POS" or
	    event == "VIEW_RESOLUTION_CHANGED" or
	    event == "CLOSE_FRESHMAN_GUIDE" then
		FreshManGuide_Close()
        return
	end
end

function FreshManGuide_Close()
    if not this:IsVisible() then
        return
    end

    KillTimer("FreshManGuide_Close()")
    this:Hide()
end

function FreshManGuide_Reset(ntype, nTextID, nTipPosX, nTipPosY, nClientWidth, nClientHight, szCorner)
	--Lua_TDU_Log("OPEN_FRESHMAN_GUIDE 3");
	--Lua_TDU_Log("OPEN_FRESHMAN_GUIDE ntype:"..ntype);
	--Lua_TDU_Log("OPEN_FRESHMAN_GUIDE nTextID:"..nTextID); 
	
	

    KillTimer("FreshManGuide_Close()")
	if ntype == 1 then
		g_cached_textid = nTextID
		g_cached_textstr= ""
		if GetFreshManGuideOwner() == "PlayerQuicklyEnter" and ( nTextID == 93 or nTextID == 94 or nTextID == 95 or nTextID == 96 or nTextID == 97 or nTextID == 98 or nTextID == 99 or nTextID == 100) then
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "PlayerQuicklyEnter" and ( nTextID == 108 or nTextID == 109 or nTextID == 115 or nTextID == 116 or nTextID == 118 or nTextID == 131) then
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)  --争霸赛16版 10月22日总决赛期间tips显示10s
		elseif GetFreshManGuideOwner() == "PlayerQuicklyEnter" and ( nTextID == 229 ) then
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 5000) --青梅煮酒tips?Tips持续5秒钟
		elseif GetFreshManGuideOwner() == "PlayerQuicklyEnter" and ( nTextID == 226 ) then
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "PlayerQuicklyEnter" and ( nTextID == 259 ) then-- 星阵系统引导任务
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 300*1000)
		elseif GetFreshManGuideOwner() == "PlayerFrame" and ( nTextID == 90 or nTextID == 91 or nTextID == 34 or nTextID == 35 or nTextID == 36 or nTextID == 49 or nTextID == 53) then
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "MiniMap" and (nTextID == 39 or nTextID == 40 or nTextID == 41 or nTextID == 42 or nTextID == 62) then
				SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)			--- 10秒关闭 周活跃奖励
		elseif GetFreshManGuideOwner() == "PlayerFrame" or GetFreshManGuideOwner() == "MiniMap" then --游龙卡特写 家园按钮
			 SetTimer("FreshManGuide", "FreshManGuide_Close()", 30000)	--30秒关闭;如果有渐变需求,缩小elapse,然后在回调中计数并更新alpha
		elseif GetFreshManGuideOwner() == "ZhenYuanNingLian" or GetFreshManGuideOwner() == "ZhenYuanActivation" or GetFreshManGuideOwner() == "ZhenYuan" then
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "EquipBaoshiChange" then      --- 30秒关闭，一键换宝石
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 30000)
		elseif GetFreshManGuideOwner() == "BudgetPlanGem_button" then      --- 10秒关闭，分期宝石
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "WeekgiftEnter" then      --- 10秒关闭，每日领奖
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "SummerVacation_Anniu" then      --- 10秒关闭，每日领奖
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "Rosebang_Anniu" then      --- 10秒关闭，玫瑰传情
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "Bazhounianlingjiang_Anniu" then
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "PlayerQuicklyEnter" then  --周年庆
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "Banghui_KVKZCzhibo" then  --雄霸天下直播
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		--elseif GetFreshManGuideOwner() == "BaoDianZhenJiangHu2_Anniu" then  --宝典震江湖
		--	SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "SeventhFestivalEnter" then  --七夕情人节
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "Jincanxianli_Anniu" and nTextID == 57 then  --金蚕献礼活动
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "ZidianLottery" then  --紫电赠英豪
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "GoldTopList_AnNiu"  and nTextID == 89 then  --百战英杰铸精通
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif GetFreshManGuideOwner() == "ValentineRoseEnter" then  --2016情人节
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10000)
		elseif nTextID >= 119 and nTextID <= 130 then	--家园引导任务
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 30000)
		--【九星神器引导任务】
		elseif (nTextID >= 174 and nTextID <= 179) or nTextID == 192 then
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 30*1000)
		elseif nTextID >= 180 and nTextID <= 187 then
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10*1000)
		--【九星神器引导任务】神器开蒙
		elseif (nTextID == 193 or nTextID == 194)  then
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 30*1000)
		--【九星神器引导任务】神器锻灵
		elseif (nTextID == 195 or nTextID == 196)  then
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 30*1000)
		elseif (nTextID == 197 or nTextID == 198 or nTextID == 199 or nTextID == 200) then
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10*1000)
		--2018清明节活动-ypl
		elseif GetFreshManGuideOwner() == "PlayerQuicklyEnter" and ( nTextID == 230 ) then
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 10*1000)
		else
			SetTimer("FreshManGuide", "FreshManGuide_Close()", 5000)	--5秒关闭;如果有渐变需求,缩小elapse,然后在回调中计数并更新alpha
		end
	elseif ntype == 3 then  
	    local g_Flex		= GetPlayerQuickEnterHide() 
	    if type(g_Flex) ~= "table" then
	    	return
		end 
		local idx = -1
		for index, value in ipairs(g_Flex) do
			if value.ID == nTextID  then
				idx = index
			end
		end

		if idx == -1 then
			--Lua_TDU_Log("idx==-1");
			return
		end
        g_cached_textid  = -1
		g_cached_textstr = g_Flex[idx].FreshStr   
		local fx, fy = Lua_GetQuickEnterOffSet(g_Flex[idx].ID) 
		nTipPosX = fx
		nTipPosY = fy
        SetTimer("FreshManGuide", "FreshManGuide_Close()", tonumber(g_Flex[idx].FreshFlash)) 
	end

    FreshManGuide_Modify(g_cached_textid, g_cached_textstr, nTipPosX, nTipPosY, nClientWidth, nClientHight, szCorner)
	this:Show()
end

--szCorner代表调用者期望的显示方位
--如期望方位显示不下本窗口,才进入自由选择
function FreshManGuide_Modify(nTextID, nTextStr, nTipPosX, nTipPosY, nClientWidth, nClientHight, szCorner)
	--Lua_TDU_Log("FreshManGuide_Modify nTextID"..nTextID);		     
	--Lua_TDU_Log("FreshManGuide_Modify nTextStr"..nTextStr);		     
	
	if nTextID ~= -1 then
		FreshManGuide_CrackSize( nTextID ) 
		if nTextID == 238 then--畅秀阁tips
			local tableTemp = GetXiuChangParams()
			local strTemp = tableTemp.textid1
			if strTemp ~= nil then
				FreshManGuide_GuideInfo:SetText(strTemp)
			else
				FreshManGuide_GuideInfo:SetText("")
			end
		elseif nTextID == 239 then
			local tableTemp = GetXiuChangParams()
			local strTemp = tableTemp.textid2
			if strTemp ~= nil then
				FreshManGuide_GuideInfo:SetText(strTemp)
			else
				FreshManGuide_GuideInfo:SetText("")
			end
		elseif nTextID == 240 then
			local tableTemp = GetXiuChangParams()
			local strTemp = tableTemp.textid3
			if strTemp ~= nil then
				FreshManGuide_GuideInfo:SetText(strTemp)
			else
				FreshManGuide_GuideInfo:SetText("")
			end
		else
			FreshManGuide_GuideInfo:SetText(g_Text[nTextID])
		end
	else
		FreshManGuide_GuideInfo:SetText(nTextStr)
	end 

	if nTipPosX ~= -1 or nTipPosY ~= -1 then             --都为-1，表示不改变相对位置
        g_X_Offset = nTipPosX                            --本tip相对于目标窗口的偏移
        g_Y_Offset = nTipPosY
    end
    if szCorner ~= "" then                               --空串,表示方位不变
        g_Direct = szCorner
    end
    local OffsetX, OffsetY = GetWindowPos(GetFreshManGuideOwner()) --得到目标窗口相对于底板的偏移
    OffsetX = OffsetX + g_X_Offset                       --本tip相对于客户端窗口底板的偏移
    OffsetY = OffsetY + g_Y_Offset

    if "northwest" == g_Direct and
        OffsetX - g_Frame_Width > 0 and OffsetY - g_Frame_Height > 0 then
        FreshManGuide_To(OffsetX - g_Frame_Width, OffsetY - g_Frame_Height)
        FreshManGuide_Show_Corner(3)   --左上显示，show右下角
    elseif "northeast" == g_Direct and
        OffsetX + g_Frame_Width - nClientWidth < 0 and OffsetY - g_Frame_Height > 0 then
        FreshManGuide_To(OffsetX, OffsetY - g_Frame_Height)
        FreshManGuide_Show_Corner(4)   --右上显示，show左下角
    elseif "southeast" == g_Direct and
        OffsetX + g_Frame_Width - nClientWidth < 0 and OffsetY + g_Frame_Height - nClientHight < 0 then
        FreshManGuide_To(OffsetX, OffsetY)
        FreshManGuide_Show_Corner(1)   --右下显示，show左上角
    elseif "southwest" == g_Direct and
        OffsetX - g_Frame_Width > 0 and OffsetY + g_Frame_Height - nClientHight < 0 then
        FreshManGuide_To(OffsetX - g_Frame_Width, OffsetY)
        FreshManGuide_Show_Corner(2)   --左下显示，show右上角
    else
        if OffsetX - g_Frame_Width < 0 then
            if OffsetY - g_Frame_Height < 0 then
                FreshManGuide_To(OffsetX, OffsetY)
                FreshManGuide_Show_Corner(1)
            else
                FreshManGuide_To(OffsetX, OffsetY - g_Frame_Height)
                FreshManGuide_Show_Corner(4)
            end
        else
            if OffsetY - g_Frame_Height < 0 then
                FreshManGuide_To(OffsetX - g_Frame_Width, OffsetY)
                FreshManGuide_Show_Corner(2)
            else
                FreshManGuide_To(OffsetX - g_Frame_Width, OffsetY - g_Frame_Height)
                FreshManGuide_Show_Corner(3)
            end
        end
    end
 
end

function FreshManGuide_To(nXPos, nYPos)
    FreshManGuide_Frame:SetProperty("AbsoluteXPosition", nXPos)
    FreshManGuide_Frame:SetProperty("AbsoluteYPosition", nYPos)
end

function FreshManGuide_Show_Corner(nIdx)
    if nil == g_Ctl_Corner[nIdx] then
        return
    end

    for i = 1, table.getn(g_Ctl_Corner) do
       if nIdx == i then
           g_Ctl_Corner[i]:Show()
       else
           g_Ctl_Corner[i]:Hide()
       end
    end
end

function FreshManGuide_CheckSize(nClientWidth, nClientHight)
    if g_Frame_Width - nClientWidth > 0 or g_Frame_Height - nClientHight > 0 then
        return 0
    end
    return 1
end

function FreshManGuide_CrackSize( nTextID )

	if nTextID == 57 then
		FreshManGuide_Frame:SetProperty("UnifiedSize", "{{0.000000,304.000000},{0.000000,102.000000}}" )
		FreshManGuide_Lace:SetProperty("UnifiedSize", "{{0.000000,270.000000},{0.000000,80.000000}}" )
	elseif nTextID == 88 or nTextID == 272 or nTextID == 273 or nTextID == 274 then
		FreshManGuide_Frame:SetProperty("UnifiedSize", "{{0.000000,304.000000},{0.000000,142.000000}}" )
		FreshManGuide_Lace:SetProperty("UnifiedSize", "{{0.000000,270.000000},{0.000000,120.000000}}" )
	elseif nTextID == 275 or nTextID == 276 or nTextID == 277 or nTextID == 278 then
		FreshManGuide_Frame:SetProperty("UnifiedSize", "{{0.000000,304.000000},{0.000000,142.000000}}" )
		FreshManGuide_Lace:SetProperty("UnifiedSize", "{{0.000000,270.000000},{0.000000,120.000000}}" )
	elseif nTextID == 133 or nTextID == 134 or nTextID == 136 or nTextID == 149 or nTextID == 244  then
		FreshManGuide_Frame:SetProperty("UnifiedSize", "{{0.000000,324.000000},{0.000000,122.000000}}" )
		FreshManGuide_Lace:SetProperty("UnifiedSize", "{{0.000000,290.000000},{0.000000,100.000000}}" )
	else
		FreshManGuide_Frame:SetProperty("UnifiedSize", tostring(g_Frame_SizeRaw) )
		FreshManGuide_Lace:SetProperty("UnifiedSize", tostring(g_Lace_SizeRaw) )
	end

	g_Frame_Width  = FreshManGuide_Frame:GetProperty("AbsoluteWidth")
	g_Frame_Heigh = FreshManGuide_Frame:GetProperty("AbsoluteHeight")

end

