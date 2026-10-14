-- SiXiangTu_Detail 四象图 奖励展示界面 2020-8-18 lishilong
-- !!!reloadscript =SiXiangTu_Detail
--
local MAX_OBJ_DISTANCE 	= 3.0
local g_objCared 		= -1
local g_npcObjId 		= -1
local g_SiXiangTu_Detail_Frame_UnifiedPosition
local bCaredObj 		= 0
local bCaredMoney 		= 0

-- 展示控件
local g_controlActionButtonXiYouPage1 	= {}
local g_controlActionButtonMiJiPage1 	= {}
local g_controlActionButtonXinJuePage1 	= {}
local g_controlActionButtonDaZaoPage1 	= {}

local g_controlActionButtonXiYouPage2 	= {}
local g_controlActionButtonMiJiPage2 	= {}
local g_controlActionButtonXinJuePage2 	= {}
local g_controlActionButtonDaZaoPage2 	= {}

-- 当前页签
local g_nCurPage = 2

-- 道具		道具id	绑定图展示道具	非绑定图展示道具	分类（类型+顺序）
-- 流光千极	34000050	39922423	39921978	稀有奖励2
-- 京华梦韵	38002780	39922422	39921677	稀有奖励1
-- 展示道具
local g_tableShowItemXiYouPage1 = 
{
	[1] = { nItemID = 39922422, nItemNum = 1, }, 
	[2] = { nItemID = 39922423, nItemNum = 1, }, 
}
local g_tableShowItemXiYouPage2 = 
{
	[1] = { nItemID = 39921677, nItemNum = 1, }, 
	[2] = { nItemID = 39921978, nItemNum = 1, }, 
}

-- 秘技		道具id	绑定图展示道具	非绑定图展示道具	分类
-- 大江之势	38004221	39922599	39922798	秘技1
-- 越王破吴	38004222	39922600	39922799	秘技2
-- 诛清君侧	38004223	39922601	39922800	秘技3
-- 百二秦关	38004224	39922602	39922801	秘技4
-- 鼎湖龙吟	38004225	39922228	39922802	秘技5
-- 避守孤城	38004238	39922616	39922803	秘技6
-- 汴河抱玉	38004240	39922229	39922804	秘技7
-- 桃源避难	38004239	39922617	39922805	秘技8
-- 刺血经书	38004226	39922604	39922806	秘技9
-- 直捣黄龙	38004227	39922223	39922807	秘技10
-- 易水萧萧	38004228	39922606	39922808	秘技11
-- 重耳纵火	38004229	39922607	39922809	秘技12
-- 图穷匕见	38004230	39922608	39922810	秘技13
-- 鹤顶为丹	38004231	39922609	39922811	秘技14
-- 三尺冰冻	38004232	39922224	39922812	秘技15
-- 烈火灼心	38004233	39922225	39922813	秘技16
-- 铁索横江	38004234	39922226	39922814	秘技17
-- 妇人之毒	38004235	39922227	39922815	秘技18
-- 临渊履冰	38004241	39922619	39922816	秘技19
-- 文姬思乡	38004248	39922626	39922817	秘技20
-- 四面楚歌	38004249	39922424	39922818	秘技21
-- 羿妻窃药	38004250	39922628	39922819	秘技22
-- 昭君落雁	38004621	39922635	39922820	秘技23
-- 药石之力	38004622	39922636	39922821	秘技24
-- 反戈一击	38004623	39922637	39922822	秘技25
local g_tableShowItemMiJiPage1 = 
{
	[1]		= { nItemID = 39922599, nItemNum = 1, },
	[2]		= { nItemID = 39922600, nItemNum = 1, },
	[3]		= { nItemID = 39922601, nItemNum = 1, },
	[4]		= { nItemID = 39922602, nItemNum = 1, },
	[5]		= { nItemID = 39922228, nItemNum = 1, },
	[6]		= { nItemID = 39922616, nItemNum = 1, },
	[7]		= { nItemID = 39922229, nItemNum = 1, },
	[8]		= { nItemID = 39922617, nItemNum = 1, },
	[9]		= { nItemID = 39922604, nItemNum = 1, },
	[10]	= { nItemID = 39922223, nItemNum = 1, },
	[11]	= { nItemID = 39922606, nItemNum = 1, },
	[12]	= { nItemID = 39922607, nItemNum = 1, },
	[13]	= { nItemID = 39922608, nItemNum = 1, },
	[14]	= { nItemID = 39922609, nItemNum = 1, },
	[15]	= { nItemID = 39922224, nItemNum = 1, },
	[16]	= { nItemID = 39922225, nItemNum = 1, },
	[17]	= { nItemID = 39922226, nItemNum = 1, },
	[18]	= { nItemID = 39922227, nItemNum = 1, },
	[19]	= { nItemID = 39922619, nItemNum = 1, },
	[20]	= { nItemID = 39922626, nItemNum = 1, },
	[21]	= { nItemID = 39922424, nItemNum = 1, },
	[22]	= { nItemID = 39922628, nItemNum = 1, },
	[23]	= { nItemID = 39922635, nItemNum = 1, },
	[24]	= { nItemID = 39922636, nItemNum = 1, },
	[25]	= { nItemID = 39922637, nItemNum = 1, },
}
local g_tableShowItemMiJiPage2 = 
{
	-- 	拾取绑定				
	-- 紫色秘技：开出紫色秘技后，从下面秘技中随机给				
	-- 秘技		道具id	绑定图展示道具	展示道具	分类
	-- 刺血经书	38004226	39922604	39922604	秘技9
	-- 直捣黄龙	38004227	39922223	39922223	秘技10
	-- 易水萧萧	38004228	39922606	39922606	秘技11
	-- 重耳纵火	38004229	39922607	39922607	秘技12
	-- 图穷匕见	38004230	39922608	39922608	秘技13
	-- 鹤顶为丹	38004231	39922609	39922609	秘技14
	-- 三尺冰冻	38004232	39922224	39922224	秘技15
	-- 烈火灼心	38004233	39922225	39922225	秘技16
	-- 铁索横江	38004234	39922226	39922226	秘技17
	-- 妇人之毒	38004235	39922227	39922227	秘技18
	-- 临渊履冰	38004241	39922619	39922619	秘技19
	-- 文姬思乡	38004248	39922626	39922626	秘技20
	-- 四面楚歌	38004249	39922424	39922424	秘技21
	-- 羿妻窃药	38004250	39922628	39922628	秘技22
	-- 昭君落雁	38004621	39922635	39922635	秘技23
	-- 药石之力	38004622	39922636	39922636	秘技24
	-- 反戈一击	38004623	39922637	39922637	秘技25

	[1]		= { nItemID = 39922798, nItemNum = 1, },
	[2]		= { nItemID = 39922799, nItemNum = 1, },
	[3]		= { nItemID = 39922800, nItemNum = 1, },
	[4]		= { nItemID = 39922801, nItemNum = 1, },
	[5]		= { nItemID = 39922802, nItemNum = 1, },
	[6]		= { nItemID = 39922803, nItemNum = 1, },
	[7]		= { nItemID = 39922804, nItemNum = 1, },
	[8]		= { nItemID = 39922805, nItemNum = 1, },
	[9]		= { nItemID = 39922604, nItemNum = 1, },
	[10]	= { nItemID = 39922223, nItemNum = 1, },
	[11]	= { nItemID = 39922606, nItemNum = 1, },
	[12]	= { nItemID = 39922607, nItemNum = 1, },
	[13]	= { nItemID = 39922608, nItemNum = 1, },
	[14]	= { nItemID = 39922609, nItemNum = 1, },
	[15]	= { nItemID = 39922224, nItemNum = 1, },
	[16]	= { nItemID = 39922225, nItemNum = 1, },
	[17]	= { nItemID = 39922226, nItemNum = 1, },
	[18]	= { nItemID = 39922227, nItemNum = 1, },
	[19]	= { nItemID = 39922619, nItemNum = 1, },
	[20]	= { nItemID = 39922626, nItemNum = 1, },
	[21]	= { nItemID = 39922424, nItemNum = 1, },
	[22]	= { nItemID = 39922628, nItemNum = 1, },
	[23]	= { nItemID = 39922635, nItemNum = 1, },
	[24]	= { nItemID = 39922636, nItemNum = 1, },
	[25]	= { nItemID = 39922637, nItemNum = 1, },

	-- [1]		= { nItemID = 39922798, nItemNum = 1, },
	-- [2]		= { nItemID = 39922799, nItemNum = 1, },
	-- [3]		= { nItemID = 39922800, nItemNum = 1, },
	-- [4]		= { nItemID = 39922801, nItemNum = 1, },
	-- [5]		= { nItemID = 39922802, nItemNum = 1, },
	-- [6]		= { nItemID = 39922803, nItemNum = 1, },
	-- [7]		= { nItemID = 39922804, nItemNum = 1, },
	-- [8]		= { nItemID = 39922805, nItemNum = 1, },
	-- [9]		= { nItemID = 39922806, nItemNum = 1, },
	-- [10]	= { nItemID = 39922807, nItemNum = 1, },
	-- [11]	= { nItemID = 39922808, nItemNum = 1, },
	-- [12]	= { nItemID = 39922809, nItemNum = 1, },
	-- [13]	= { nItemID = 39922810, nItemNum = 1, },
	-- [14]	= { nItemID = 39922811, nItemNum = 1, },
	-- [15]	= { nItemID = 39922812, nItemNum = 1, },
	-- [16]	= { nItemID = 39922813, nItemNum = 1, },
	-- [17]	= { nItemID = 39922814, nItemNum = 1, },
	-- [18]	= { nItemID = 39922815, nItemNum = 1, },
	-- [19]	= { nItemID = 39922816, nItemNum = 1, },
	-- [20]	= { nItemID = 39922817, nItemNum = 1, },
	-- [21]	= { nItemID = 39922818, nItemNum = 1, },
	-- [22]	= { nItemID = 39922819, nItemNum = 1, },
	-- [23]	= { nItemID = 39922820, nItemNum = 1, },
	-- [24]	= { nItemID = 39922821, nItemNum = 1, },
	-- [25]	= { nItemID = 39922822, nItemNum = 1, },
}

-- 心决				道具id	绑定图展示道具	非绑定图展示道具	分类
-- 心决：刺心·冰	38004517	39922501	39922778	心决1
-- 心决：刺心·火	38004518	39922502	39922779	心决2
-- 心决：刺心·玄	38004519	39922503	39922780	心决3
-- 心决：刺心·毒	38004520	39922504	39922781	心决4
-- 心决：奇骨·冰	38004521	39922505	39922823	心决5
-- 心决：奇骨·火	38004522	39922506	39922824	心决6
-- 心决：奇骨·玄	38004523	39922507	39922825	心决7
-- 心决：奇骨·毒	38004524	39922508	39922826	心决8
-- 心决：大千·冰	38004525	39922509	39922827	心决9
-- 心决：大千·火	38004526	39922510	39922828	心决10
-- 心决：大千·玄	38004527	39922511	39922829	心决11
-- 心决：大千·毒	38004528	39922512	39922830	心决12
-- 心决：心眼·冰	38004529	39922513	39922782	心决13
-- 心决：心眼·火	38004530	39922514	39922783	心决14
-- 心决：心眼·玄	38004531	39922515	39922784	心决15
-- 心决：心眼·毒	38004532	39922516	39922785	心决16
-- 心决：神伏		38004533	39922187	39922786	心决17
-- 心决：无双		38004534	39922518	39922831	心决18
-- 精品残印集录		38004358	39922156	39922156	心决19
-- 珍品残印选录		38004359	39922155	39922155	心决20
-- 神品残印选录		38004360	39922180	39922180	心决21
local g_tableShowItemXinJuePage1 = 
{
	[1]		= { nItemID = 39922501, nItemNum = 1, },
	[2]		= { nItemID = 39922502, nItemNum = 1, },
	[3]		= { nItemID = 39922503, nItemNum = 1, },
	[4]		= { nItemID = 39922504, nItemNum = 1, },
	[5]		= { nItemID = 39922505, nItemNum = 1, },
	[6]		= { nItemID = 39922506, nItemNum = 1, },
	[7]		= { nItemID = 39922507, nItemNum = 1, },
	[8]		= { nItemID = 39922508, nItemNum = 1, },
	[9]		= { nItemID = 39922509, nItemNum = 1, },
	[10]	= { nItemID = 39922510, nItemNum = 1, },
	[11]	= { nItemID = 39922511, nItemNum = 1, },
	[12]	= { nItemID = 39922512, nItemNum = 1, },
	[13]	= { nItemID = 39922513, nItemNum = 1, },
	[14]	= { nItemID = 39922514, nItemNum = 1, },
	[15]	= { nItemID = 39922515, nItemNum = 1, },
	[16]	= { nItemID = 39922516, nItemNum = 1, },
	[17]	= { nItemID = 39922187, nItemNum = 1, },
	[18]	= { nItemID = 39922518, nItemNum = 1, },
	[19]	= { nItemID = 39922156, nItemNum = 1, },
	[20]	= { nItemID = 39922155, nItemNum = 1, },
	[21]	= { nItemID = 39922180, nItemNum = 1, },
}
local g_tableShowItemXinJuePage2 = 
{
	[1]		= { nItemID = 39922778, nItemNum = 1, },
	[2]		= { nItemID = 39922779, nItemNum = 1, },
	[3]		= { nItemID = 39922780, nItemNum = 1, },
	[4]		= { nItemID = 39922781, nItemNum = 1, },
	[5]		= { nItemID = 39922823, nItemNum = 1, },
	[6]		= { nItemID = 39922824, nItemNum = 1, },
	[7]		= { nItemID = 39922825, nItemNum = 1, },
	[8]		= { nItemID = 39922826, nItemNum = 1, },
	[9]		= { nItemID = 39922827, nItemNum = 1, },
	[10]	= { nItemID = 39922828, nItemNum = 1, },
	[11]	= { nItemID = 39922829, nItemNum = 1, },
	[12]	= { nItemID = 39922830, nItemNum = 1, },
	[13]	= { nItemID = 39922782, nItemNum = 1, },
	[14]	= { nItemID = 39922783, nItemNum = 1, },
	[15]	= { nItemID = 39922784, nItemNum = 1, },
	[16]	= { nItemID = 39922785, nItemNum = 1, },
	[17]	= { nItemID = 39922786, nItemNum = 1, },
	[18]	= { nItemID = 39922831, nItemNum = 1, },
	[19]	= { nItemID = 39922156, nItemNum = 1, },
	[20]	= { nItemID = 39922155, nItemNum = 1, },
	[21]	= { nItemID = 39922180, nItemNum = 1, },
}


-- 道具id	绑定图展示道具	非绑定图展示道具	分类（类型+顺序）
-- 20502004	39920566	39920566	1	打造1		4级秘银	
-- 20501004	39920565	39920565	1	打造2		4级棉布	
-- 20502003	39920397	39920397	1	打造3		3级秘银	
-- 20501003	39920396	39920396	1	打造4		3级棉布	
-- 38001014	39920477	39920477	10	打造5		释灵浆	
-- 38000656	39920332	39920332	5	打造6		悟灵珠	
-- 30503188	39921141	39921141	10	打造7		高级根骨	
-- 38000571	39920329	39920329	2	打造8		至尊强化精
-- 38000658	39920333	39920333	1	打造9		觉灵珠	
-- 20310168	39920085	39920085	10	打造10		金蚕丝	
-- 38000380	39920298	39920298	1	打造11		真元精魄	
local g_tableShowItemDaZaoPage1 = 
{
	[1]		= { nItemID = 39920566, nItemNum = 1, 	}, 
	[2]		= { nItemID = 39920565, nItemNum = 1, 	}, 
	[3]		= { nItemID = 39920397, nItemNum = 1, 	}, 
	[4]		= { nItemID = 39920396, nItemNum = 1, 	}, 
	[5]		= { nItemID = 39920477, nItemNum = 10, 	}, 
	[6]		= { nItemID = 39920332, nItemNum = 5, 	}, 
	[7]		= { nItemID = 39921141, nItemNum = 10, 	}, 
	[8]		= { nItemID = 39920329, nItemNum = 2, 	}, 
	[9]		= { nItemID = 39920333, nItemNum = 1, 	}, 
	[10]	= { nItemID = 39920085, nItemNum = 10, 	}, 
	[11]	= { nItemID = 39920298, nItemNum = 1, 	}, 
}
local g_tableShowItemDaZaoPage2 = 
{
	[1]		= { nItemID = 39920566, nItemNum = 1, 	}, 
	[2]		= { nItemID = 39920565, nItemNum = 1, 	}, 
	[3]		= { nItemID = 39920397, nItemNum = 1, 	}, 
	[4]		= { nItemID = 39920396, nItemNum = 1, 	}, 
	[5]		= { nItemID = 39920477, nItemNum = 10, 	}, 
	[6]		= { nItemID = 39920332, nItemNum = 5, 	}, 
	[7]		= { nItemID = 39921141, nItemNum = 10, 	}, 
	[8]		= { nItemID = 39920329, nItemNum = 2, 	}, 
	[9]		= { nItemID = 39920333, nItemNum = 1, 	}, 
	[10]	= { nItemID = 39920085, nItemNum = 10, 	}, 
	[11]	= { nItemID = 39920298, nItemNum = 1, 	}, 
}

--=========================================================
-- PreLoad
--=========================================================
function SiXiangTu_Detail_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	-- this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	if 1 == bCaredMoney then
		this:RegisterEvent("MONEY_CHANGE_EX", false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	end
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

--=========================================================
-- OnLoad
--=========================================================
function SiXiangTu_Detail_OnLoad()
	g_SiXiangTu_Detail_Frame_UnifiedPosition = SiXiangTu_Detail_Frame:GetProperty("UnifiedPosition")

	g_controlActionButtonXiYouPage1[1] 		= SiXiangTu_Detail_Page1_Icon1
	g_controlActionButtonXiYouPage1[2] 		= SiXiangTu_Detail_Page1_Icon2

	g_controlActionButtonMiJiPage1[1]		= SiXiangTu_Detail_Page1_Icon3
	g_controlActionButtonMiJiPage1[2]		= SiXiangTu_Detail_Page1_Icon4
	g_controlActionButtonMiJiPage1[3]		= SiXiangTu_Detail_Page1_Icon5
	g_controlActionButtonMiJiPage1[4]		= SiXiangTu_Detail_Page1_Icon6
	g_controlActionButtonMiJiPage1[5]		= SiXiangTu_Detail_Page1_Icon7
	g_controlActionButtonMiJiPage1[6]		= SiXiangTu_Detail_Page1_Icon8
	g_controlActionButtonMiJiPage1[7]		= SiXiangTu_Detail_Page1_Icon9
	g_controlActionButtonMiJiPage1[8]		= SiXiangTu_Detail_Page1_Icon10
	g_controlActionButtonMiJiPage1[9]		= SiXiangTu_Detail_Page1_Icon11
	g_controlActionButtonMiJiPage1[10]		= SiXiangTu_Detail_Page1_Icon12
	g_controlActionButtonMiJiPage1[11]		= SiXiangTu_Detail_Page1_Icon13
	g_controlActionButtonMiJiPage1[12]		= SiXiangTu_Detail_Page1_Icon14
	g_controlActionButtonMiJiPage1[13]		= SiXiangTu_Detail_Page1_Icon15
	g_controlActionButtonMiJiPage1[14]		= SiXiangTu_Detail_Page1_Icon16
	g_controlActionButtonMiJiPage1[15]		= SiXiangTu_Detail_Page1_Icon17
	g_controlActionButtonMiJiPage1[16]		= SiXiangTu_Detail_Page1_Icon18
	g_controlActionButtonMiJiPage1[17]		= SiXiangTu_Detail_Page1_Icon19
	g_controlActionButtonMiJiPage1[18]		= SiXiangTu_Detail_Page1_Icon20
	g_controlActionButtonMiJiPage1[19]		= SiXiangTu_Detail_Page1_Icon21
	g_controlActionButtonMiJiPage1[20]		= SiXiangTu_Detail_Page1_Icon22
	g_controlActionButtonMiJiPage1[21]		= SiXiangTu_Detail_Page1_Icon23
	g_controlActionButtonMiJiPage1[22]		= SiXiangTu_Detail_Page1_Icon24
	g_controlActionButtonMiJiPage1[23]		= SiXiangTu_Detail_Page1_Icon25
	g_controlActionButtonMiJiPage1[24]		= SiXiangTu_Detail_Page1_Icon26
	g_controlActionButtonMiJiPage1[25]		= SiXiangTu_Detail_Page1_Icon27

	g_controlActionButtonXinJuePage1[1]		= SiXiangTu_Detail_Page1_Icon28
	g_controlActionButtonXinJuePage1[2]		= SiXiangTu_Detail_Page1_Icon29
	g_controlActionButtonXinJuePage1[3]		= SiXiangTu_Detail_Page1_Icon30
	g_controlActionButtonXinJuePage1[4]		= SiXiangTu_Detail_Page1_Icon31
	g_controlActionButtonXinJuePage1[5]		= SiXiangTu_Detail_Page1_Icon32
	g_controlActionButtonXinJuePage1[6]		= SiXiangTu_Detail_Page1_Icon33
	g_controlActionButtonXinJuePage1[7]		= SiXiangTu_Detail_Page1_Icon34
	g_controlActionButtonXinJuePage1[8]		= SiXiangTu_Detail_Page1_Icon35
	g_controlActionButtonXinJuePage1[9]		= SiXiangTu_Detail_Page1_Icon36
	g_controlActionButtonXinJuePage1[10]	= SiXiangTu_Detail_Page1_Icon37
	g_controlActionButtonXinJuePage1[11]	= SiXiangTu_Detail_Page1_Icon38
	g_controlActionButtonXinJuePage1[12]	= SiXiangTu_Detail_Page1_Icon39
	g_controlActionButtonXinJuePage1[13]	= SiXiangTu_Detail_Page1_Icon40
	g_controlActionButtonXinJuePage1[14]	= SiXiangTu_Detail_Page1_Icon41
	g_controlActionButtonXinJuePage1[15]	= SiXiangTu_Detail_Page1_Icon42
	g_controlActionButtonXinJuePage1[16]	= SiXiangTu_Detail_Page1_Icon43
	g_controlActionButtonXinJuePage1[17]	= SiXiangTu_Detail_Page1_Icon44
	g_controlActionButtonXinJuePage1[18]	= SiXiangTu_Detail_Page1_Icon45
	g_controlActionButtonXinJuePage1[19]	= SiXiangTu_Detail_Page1_Icon46
	g_controlActionButtonXinJuePage1[20]	= SiXiangTu_Detail_Page1_Icon47
	g_controlActionButtonXinJuePage1[21]	= SiXiangTu_Detail_Page1_Icon48

	g_controlActionButtonDaZaoPage1[1]		= SiXiangTu_Detail_Page1_Icon49
	g_controlActionButtonDaZaoPage1[2]		= SiXiangTu_Detail_Page1_Icon50
	g_controlActionButtonDaZaoPage1[3]		= SiXiangTu_Detail_Page1_Icon51
	g_controlActionButtonDaZaoPage1[4]		= SiXiangTu_Detail_Page1_Icon52
	g_controlActionButtonDaZaoPage1[5]		= SiXiangTu_Detail_Page1_Icon53
	g_controlActionButtonDaZaoPage1[6]		= SiXiangTu_Detail_Page1_Icon54
	g_controlActionButtonDaZaoPage1[7]		= SiXiangTu_Detail_Page1_Icon55
	g_controlActionButtonDaZaoPage1[8]		= SiXiangTu_Detail_Page1_Icon56
	g_controlActionButtonDaZaoPage1[9]		= SiXiangTu_Detail_Page1_Icon57
	g_controlActionButtonDaZaoPage1[10]		= SiXiangTu_Detail_Page1_Icon58
	g_controlActionButtonDaZaoPage1[11]		= SiXiangTu_Detail_Page1_Icon59

	g_controlActionButtonXiYouPage2[1] 		= SiXiangTu_Detail_Page2_Icon1
	g_controlActionButtonXiYouPage2[2] 		= SiXiangTu_Detail_Page2_Icon2

	g_controlActionButtonMiJiPage2[1]		= SiXiangTu_Detail_Page2_Icon3
	g_controlActionButtonMiJiPage2[2]		= SiXiangTu_Detail_Page2_Icon4
	g_controlActionButtonMiJiPage2[3]		= SiXiangTu_Detail_Page2_Icon5
	g_controlActionButtonMiJiPage2[4]		= SiXiangTu_Detail_Page2_Icon6
	g_controlActionButtonMiJiPage2[5]		= SiXiangTu_Detail_Page2_Icon7
	g_controlActionButtonMiJiPage2[6]		= SiXiangTu_Detail_Page2_Icon8
	g_controlActionButtonMiJiPage2[7]		= SiXiangTu_Detail_Page2_Icon9
	g_controlActionButtonMiJiPage2[8]		= SiXiangTu_Detail_Page2_Icon10
	g_controlActionButtonMiJiPage2[9]		= SiXiangTu_Detail_Page2_Icon11
	g_controlActionButtonMiJiPage2[10]		= SiXiangTu_Detail_Page2_Icon12
	g_controlActionButtonMiJiPage2[11]		= SiXiangTu_Detail_Page2_Icon13
	g_controlActionButtonMiJiPage2[12]		= SiXiangTu_Detail_Page2_Icon14
	g_controlActionButtonMiJiPage2[13]		= SiXiangTu_Detail_Page2_Icon15
	g_controlActionButtonMiJiPage2[14]		= SiXiangTu_Detail_Page2_Icon16
	g_controlActionButtonMiJiPage2[15]		= SiXiangTu_Detail_Page2_Icon17
	g_controlActionButtonMiJiPage2[16]		= SiXiangTu_Detail_Page2_Icon18
	g_controlActionButtonMiJiPage2[17]		= SiXiangTu_Detail_Page2_Icon19
	g_controlActionButtonMiJiPage2[18]		= SiXiangTu_Detail_Page2_Icon20
	g_controlActionButtonMiJiPage2[19]		= SiXiangTu_Detail_Page2_Icon21
	g_controlActionButtonMiJiPage2[20]		= SiXiangTu_Detail_Page2_Icon22
	g_controlActionButtonMiJiPage2[21]		= SiXiangTu_Detail_Page2_Icon23
	g_controlActionButtonMiJiPage2[22]		= SiXiangTu_Detail_Page2_Icon24
	g_controlActionButtonMiJiPage2[23]		= SiXiangTu_Detail_Page2_Icon25
	g_controlActionButtonMiJiPage2[24]		= SiXiangTu_Detail_Page2_Icon26
	g_controlActionButtonMiJiPage2[25]		= SiXiangTu_Detail_Page2_Icon27

	g_controlActionButtonXinJuePage2[1]		= SiXiangTu_Detail_Page2_Icon28
	g_controlActionButtonXinJuePage2[2]		= SiXiangTu_Detail_Page2_Icon29
	g_controlActionButtonXinJuePage2[3]		= SiXiangTu_Detail_Page2_Icon30
	g_controlActionButtonXinJuePage2[4]		= SiXiangTu_Detail_Page2_Icon31
	g_controlActionButtonXinJuePage2[5]		= SiXiangTu_Detail_Page2_Icon32
	g_controlActionButtonXinJuePage2[6]		= SiXiangTu_Detail_Page2_Icon33
	g_controlActionButtonXinJuePage2[7]		= SiXiangTu_Detail_Page2_Icon34
	g_controlActionButtonXinJuePage2[8]		= SiXiangTu_Detail_Page2_Icon35
	g_controlActionButtonXinJuePage2[9]		= SiXiangTu_Detail_Page2_Icon36
	g_controlActionButtonXinJuePage2[10]	= SiXiangTu_Detail_Page2_Icon37
	g_controlActionButtonXinJuePage2[11]	= SiXiangTu_Detail_Page2_Icon38
	g_controlActionButtonXinJuePage2[12]	= SiXiangTu_Detail_Page2_Icon39
	g_controlActionButtonXinJuePage2[13]	= SiXiangTu_Detail_Page2_Icon40
	g_controlActionButtonXinJuePage2[14]	= SiXiangTu_Detail_Page2_Icon41
	g_controlActionButtonXinJuePage2[15]	= SiXiangTu_Detail_Page2_Icon42
	g_controlActionButtonXinJuePage2[16]	= SiXiangTu_Detail_Page2_Icon43
	g_controlActionButtonXinJuePage2[17]	= SiXiangTu_Detail_Page2_Icon44
	g_controlActionButtonXinJuePage2[18]	= SiXiangTu_Detail_Page2_Icon45
	g_controlActionButtonXinJuePage2[19]	= SiXiangTu_Detail_Page2_Icon46
	g_controlActionButtonXinJuePage2[20]	= SiXiangTu_Detail_Page2_Icon47
	g_controlActionButtonXinJuePage2[21]	= SiXiangTu_Detail_Page2_Icon48

	g_controlActionButtonDaZaoPage2[1]		= SiXiangTu_Detail_Page2_Icon49
	g_controlActionButtonDaZaoPage2[2]		= SiXiangTu_Detail_Page2_Icon50
	g_controlActionButtonDaZaoPage2[3]		= SiXiangTu_Detail_Page2_Icon51
	g_controlActionButtonDaZaoPage2[4]		= SiXiangTu_Detail_Page2_Icon52
	g_controlActionButtonDaZaoPage2[5]		= SiXiangTu_Detail_Page2_Icon53
	g_controlActionButtonDaZaoPage2[6]		= SiXiangTu_Detail_Page2_Icon54
	g_controlActionButtonDaZaoPage2[7]		= SiXiangTu_Detail_Page2_Icon55
	g_controlActionButtonDaZaoPage2[8]		= SiXiangTu_Detail_Page2_Icon56
	g_controlActionButtonDaZaoPage2[9]		= SiXiangTu_Detail_Page2_Icon57
	g_controlActionButtonDaZaoPage2[10]		= SiXiangTu_Detail_Page2_Icon58
	g_controlActionButtonDaZaoPage2[11]		= SiXiangTu_Detail_Page2_Icon59

end

--=========================================================
-- OnEvent
--=========================================================
function SiXiangTu_Detail_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 79005002 ) then
		-- 0 关闭，1打开， 2刷新
		local nOpType 	= tonumber(arg1)
		local nOpType2 	= Get_XParam_INT(0)
		if 1 == nOpType2 then
			nOpType = 1
		end

		-- PushDebugMessage("nOpType"..nOpType)
		
		if 1 == bCaredObj then
			if objid == nil or objid < 0 then
				if this:IsVisible() then
					SiXiangTu_Detail_OnClose()
				end
			end
		end
		
		if 0 == nOpType then
			-- 关闭界面
			if this:IsVisible() then
				SiXiangTu_Detail_OnClose()
			end
			
		elseif 1 == nOpType then
			-- 打开界面
			-- 关注npc
			if 1 == bCaredObj then
				g_npcObjId = objid
				g_objCared = DataPool : GetNPCIDByServerID(tonumber(objid))
				BeginCareObject_SiXiangTu_Detail()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	SiXiangTu_Detail_OnClose()
			-- end
			SiXiangTu_Detail_Reset()
			SiXiangTu_Detail_Frame_On_ResetPos()
			this:Show()
			SiXiangTu_Detail_ParamInit()
			SiXiangTu_Detail_MoneyUpdate()
			SiXiangTu_Detail_Update(1)
			
		elseif 2 == nOpType then
			-- 刷新界面
			if this:IsVisible() then
				SiXiangTu_Detail_ParamInit()
				SiXiangTu_Detail_Update(0)
			end
		end
	
	-- 物品改变
	-- elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
	-- 	-- 刷新界面
	-- 	if this:IsVisible() then
	-- 		SiXiangTu_Detail_Update(0)
	-- 	end
	
	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			SiXiangTu_Detail_OnClose()
		end	
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		SiXiangTu_Detail_OnClose()
	
	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
	-- elseif event == "MONEYJZ_CHANGE_EX" then
		SiXiangTu_Detail_MoneyUpdate()
	
	elseif (event == "ADJEST_UI_POS" ) then
		SiXiangTu_Detail_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SiXiangTu_Detail_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function SiXiangTu_Detail_ParamInit()

end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =SiXiangTu_Detail
function SiXiangTu_Detail_Update(bOpen)

	SiXiangTu_Detail_Page1 : Show()
	SiXiangTu_Detail_Page2 : Hide()

	if 2 == g_nCurPage then
		SiXiangTu_Detail_Page1 : Hide()
		SiXiangTu_Detail_Page2 : Show()
	end

	local controlActionButton = {}
	local tableShowItem = {}

	controlActionButton[1] =	g_controlActionButtonXiYouPage1
	controlActionButton[2] =	g_controlActionButtonMiJiPage1
	controlActionButton[3] =	g_controlActionButtonXinJuePage1
	controlActionButton[4] =	g_controlActionButtonDaZaoPage1

	controlActionButton[5] =	g_controlActionButtonXiYouPage2
	controlActionButton[6] =	g_controlActionButtonMiJiPage2
	controlActionButton[7] =	g_controlActionButtonXinJuePage2
	controlActionButton[8] =	g_controlActionButtonDaZaoPage2

	tableShowItem[1] =	g_tableShowItemXiYouPage1
	tableShowItem[2] =	g_tableShowItemMiJiPage1
	tableShowItem[3] =	g_tableShowItemXinJuePage1
	tableShowItem[4] =	g_tableShowItemDaZaoPage1

	tableShowItem[5] =	g_tableShowItemXiYouPage2
	tableShowItem[6] =	g_tableShowItemMiJiPage2
	tableShowItem[7] =	g_tableShowItemXinJuePage2
	tableShowItem[8] =	g_tableShowItemDaZaoPage2

	for nIndex = 1, 8 do
		local curControlActionButton = controlActionButton[nIndex]
		local curTableShowItem = tableShowItem[nIndex]

		-- PushDebugMessage("curTableShowItem"..table.getn(curTableShowItem))
		-- PushDebugMessage("g_tableShowItemXinJuePage2"..table.getn(g_tableShowItemXinJuePage2))
		-- PushDebugMessage("g_tableShowItemXinJuePage1"..table.getn(g_tableShowItemXinJuePage1))

		for i = 1, table.getn(curTableShowItem)  do
			local nItemID = curTableShowItem[i].nItemID
			local nItemNum = curTableShowItem[i].nItemNum
			-- if i == 15 then
			-- 	PushDebugMessage("nItemID"..nItemID)
			-- end
			if nil ~= nItemID and nil ~= curControlActionButton[i] then
				local theAction = DataPool:CreateActionItemForShow(nItemID, nItemNum)
				curControlActionButton[i] : SetActionItem(theAction:GetID())
			end	
		end
	end
end

--=========================================================
-- 重置界面
--=========================================================
function SiXiangTu_Detail_Reset()

end

--=========================================================
-- 界面隐藏
--=========================================================
function SiXiangTu_Detail_OnHiden()

end

--=========================================================
-- 切换页签
--=========================================================
function SiXiangTu_Detail_ChangeShowTab(nPage)

	-- PushDebugMessage("nPage"..nPage)

	-- 暂时屏蔽页签 只显示非绑定页签 2
	-- if g_nCurPage == nPage then
	-- 	return
	-- end

	-- g_nCurPage = nPage
	-- SiXiangTu_Detail_Update(0)
end

--=========================================================
-- 关闭界面
--=========================================================
function SiXiangTu_Detail_OnClose()	
	this:Hide()
	StopCareObject_SiXiangTu_Detail()
	-- 重置
	SiXiangTu_Detail_Reset()
end

--=========================================================
-- 界面隐藏
--=========================================================
function SiXiangTu_Detail_OnHiden()
	StopCareObject_SiXiangTu_Detail()
	-- 重置
	SiXiangTu_Detail_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_SiXiangTu_Detail()
	-- 关心
	this:CareObject(g_objCared, 1, "SiXiangTu_Detail")
end

function StopCareObject_SiXiangTu_Detail()
	-- 取消关心
	if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "SiXiangTu_Detail")
	end
	g_npcObjId = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function SiXiangTu_Detail_MoneyUpdate()
end

--=========================================================
-- 界面位置
--=========================================================
function SiXiangTu_Detail_Frame_On_ResetPos()
	SiXiangTu_Detail_Frame:SetProperty("UnifiedPosition", g_SiXiangTu_Detail_Frame_UnifiedPosition)
end