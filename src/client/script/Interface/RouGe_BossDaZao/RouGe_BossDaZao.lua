--******************************************
--周常肉鸽爬塔副本	boss选择界面
--create by  limengyue 
--2023-12-06
--******************************************

local g_RouGe_BossDaZao_Frame_UnifiedPosition;
--关心NPc
local MAX_OBJ_DISTANCE = 5.0
local objCared = -1
local g_Object = -1

local g_BossBasePoint = 1000


local g_RouGe_BossDaZao_ItemList = {}	--四个boss状态选择区域
local g_RouGe_BossDaZao_NameList = {}	--四个boss状态title名字
local g_RouGe_BossDaZao_ImgList = {}	--四个boss状态图片显示
local g_RouGe_BossDaZao_TopTipsList = {}--四个boss状态悬浮tips
local g_RouGe_BossDaZao_PointList = {}	--四个boss状态积分显示
local g_RouGe_BossDaZao_DetailList = {}	--四个boss状态简要说明


local g_RouGe_BossDaZao_Select = {1,1,1,1}	--按状态不可信 自己缓存数据吧
local g_RouGe_BossDaZao_Select1List = {}	--第一个状态互斥按钮
local g_RouGe_BossDaZao_Select1Animate = {}	--按钮选中动画
local g_RouGe_BossDaZao_Select2List = {}	--第二个状态互斥按钮
local g_RouGe_BossDaZao_Select2Animate = {}	--按钮选中动画
local g_RouGe_BossDaZao_Select3List = {}	--第三个状态互斥按钮
local g_RouGe_BossDaZao_Select3Animate = {}	--按钮选中动画
local g_RouGe_BossDaZao_Select4List = {}	--第四个状态互斥按钮
local g_RouGe_BossDaZao_Select4Animate = {}	--按钮选中动画

--第一个词条血量词条
local g_Pata_BossBuff1 =
{
	[1] = {nName="#{RGPT_231130_182}",nBuffImg="set:Buff36 image:Buff36_9",nTopTips="#{RGPT_231130_382}",nSelectTips="#{RGPT_231130_383}",nPoint=0,nPointTips="#{RGPT_231130_384}",nDetail="#{RGPT_231130_610}", },
	[2] = {nName="#{RGPT_231130_182}",nBuffImg="set:Buff36 image:Buff36_9",nTopTips="#{RGPT_231130_183}",nSelectTips="#{RGPT_231130_184}",nPoint=100,nPointTips="#{RGPT_231130_187}",nDetail="#{RGPT_231130_610}", },
	[3] = {nName="#{RGPT_231130_182}",nBuffImg="set:Buff36 image:Buff36_9",nTopTips="#{RGPT_231130_331}",nSelectTips="#{RGPT_231130_185}",nPoint=200,nPointTips="#{RGPT_231130_188}",nDetail="#{RGPT_231130_610}", },
	[4] = {nName="#{RGPT_231130_182}",nBuffImg="set:Buff36 image:Buff36_9",nTopTips="#{RGPT_231130_332}",nSelectTips="#{RGPT_231130_186}",nPoint=400,nPointTips="#{RGPT_231130_189}",nDetail="#{RGPT_231130_610}", },
	[5] = {nName="#{RGPT_231130_182}",nBuffImg="set:Buff36 image:Buff36_9",nTopTips="#{RGPT_240703_22}",nSelectTips="#{RGPT_240703_6}",nPoint=-100,nPointTips="#{RGPT_240703_9}",nDetail="#{RGPT_231130_610}", },
	[6] = {nName="#{RGPT_231130_182}",nBuffImg="set:Buff36 image:Buff36_9",nTopTips="#{RGPT_240703_22}",nSelectTips="#{RGPT_240703_5}",nPoint=-200,nPointTips="#{RGPT_240703_8}",nDetail="#{RGPT_231130_610}", },
	[7] = {nName="#{RGPT_231130_182}",nBuffImg="set:Buff36 image:Buff36_9",nTopTips="#{RGPT_240703_22}",nSelectTips="#{RGPT_240703_4}",nPoint=-400,nPointTips="#{RGPT_240703_7}",nDetail="#{RGPT_231130_610}", },
}
--第二个词条伤害词条
local g_Pata_BossBuff2 =
{
	[1] = {nName="#{RGPT_231130_351}",nBuffImg="set:Buff36 image:Buff36_10",nTopTips="#{RGPT_231130_612}",nSelectTips="#{RGPT_231130_383}",nPoint=0,nPointTips="#{RGPT_231130_384}",nDetail="#{RGPT_231130_611}",  },
	[2] = {nName="#{RGPT_231130_351}",nBuffImg="set:Buff36 image:Buff36_10",nTopTips="#{RGPT_231130_345}",nSelectTips="#{RGPT_231130_348}",nPoint=100,nPointTips="#{RGPT_231130_187}",nDetail="#{RGPT_231130_611}",  },
	[3] = {nName="#{RGPT_231130_351}",nBuffImg="set:Buff36 image:Buff36_10",nTopTips="#{RGPT_231130_346}",nSelectTips="#{RGPT_231130_349}",nPoint=200,nPointTips="#{RGPT_231130_188}",nDetail="#{RGPT_231130_611}",  },
	[4] = {nName="#{RGPT_231130_351}",nBuffImg="set:Buff36 image:Buff36_10",nTopTips="#{RGPT_231130_347}",nSelectTips="#{RGPT_231130_350}",nPoint=400,nPointTips="#{RGPT_231130_189}",nDetail="#{RGPT_231130_611}",  },
	[5] = {nName="#{RGPT_231130_351}",nBuffImg="set:Buff36 image:Buff36_10",nTopTips="#{RGPT_240703_23}",nSelectTips="#{RGPT_240703_12}",nPoint=-100,nPointTips="#{RGPT_240703_15}",nDetail="#{RGPT_231130_611}",  },
	[6] = {nName="#{RGPT_231130_351}",nBuffImg="set:Buff36 image:Buff36_10",nTopTips="#{RGPT_240703_23}",nSelectTips="#{RGPT_240703_11}",nPoint=-200,nPointTips="#{RGPT_240703_14}",nDetail="#{RGPT_231130_611}",  },
	[7] = {nName="#{RGPT_231130_351}",nBuffImg="set:Buff36 image:Buff36_10",nTopTips="#{RGPT_240703_23}",nSelectTips="#{RGPT_240703_10}",nPoint=-400,nPointTips="#{RGPT_240703_13}",nDetail="#{RGPT_231130_611}",  },
}
--第三个词条狂暴词条
local g_Pata_BossBuff3 =
{
	[1] = {nName="#{RGPT_231130_352}",nBuffImg="set:Buff36 image:Buff36_11",nTopTips="#{RGPT_231130_613}",nSelectTips="#{RGPT_231130_614}",nPoint=0,nPointTips="#{RGPT_231130_384}",nDetail="#{RGPT_231130_627}",  },
	[2] = {nName="#{RGPT_231130_352}",nBuffImg="set:Buff36 image:Buff36_11",nTopTips="#{RGPT_231130_353}",nSelectTips="#{RGPT_231130_356}",nPoint=100,nPointTips="#{RGPT_231130_187}",nDetail="#{RGPT_231130_627}",  },
	[3] = {nName="#{RGPT_231130_352}",nBuffImg="set:Buff36 image:Buff36_11",nTopTips="#{RGPT_231130_354}",nSelectTips="#{RGPT_231130_357}",nPoint=200,nPointTips="#{RGPT_231130_188}",nDetail="#{RGPT_231130_627}",  },
	[4] = {nName="#{RGPT_231130_352}",nBuffImg="set:Buff36 image:Buff36_11",nTopTips="#{RGPT_231130_355}",nSelectTips="#{RGPT_231130_358}",nPoint=400,nPointTips="#{RGPT_231130_189}",nDetail="#{RGPT_231130_627}",  },
	[5] = {nName="#{RGPT_231130_352}",nBuffImg="set:Buff36 image:Buff36_11",nTopTips="#{RGPT_240703_24}",nSelectTips="#{RGPT_240703_18}",nPoint=-100,nPointTips="#{RGPT_240703_21}",nDetail="#{RGPT_231130_627}",  },
	[6] = {nName="#{RGPT_231130_352}",nBuffImg="set:Buff36 image:Buff36_11",nTopTips="#{RGPT_240703_24}",nSelectTips="#{RGPT_240703_17}",nPoint=-200,nPointTips="#{RGPT_240703_20}",nDetail="#{RGPT_231130_627}",  },
	[7] = {nName="#{RGPT_231130_352}",nBuffImg="set:Buff36 image:Buff36_11",nTopTips="#{RGPT_240703_24}",nSelectTips="#{RGPT_240703_16}",nPoint=-400,nPointTips="#{RGPT_240703_19}",nDetail="#{RGPT_231130_627}",  },
}
--额外属性第二个boss专属
local g_Pata_BossBuffEx2 =
{
	[1] = {nName="#{RGPT_231130_359}",nBuffImg="set:Buff36 image:Buff36_12",nTopTips="#{RGPT_231130_615}",nSelectTips="#{RGPT_231130_617}",nPoint=0,nPointTips="#{RGPT_231130_384}",nDetail="#{RGPT_231130_616}",  },
	[2] = {nName="#{RGPT_231130_359}",nBuffImg="set:Buff36 image:Buff36_12",nTopTips="#{RGPT_231130_360}",nSelectTips="#{RGPT_231130_363}",nPoint=100,nPointTips="#{RGPT_231130_187}",nDetail="#{RGPT_231130_616}",  },
	[3] = {nName="#{RGPT_231130_359}",nBuffImg="set:Buff36 image:Buff36_12",nTopTips="#{RGPT_231130_361}",nSelectTips="#{RGPT_231130_364}",nPoint=200,nPointTips="#{RGPT_231130_188}",nDetail="#{RGPT_231130_616}",  },
	[4] = {nName="#{RGPT_231130_359}",nBuffImg="set:Buff36 image:Buff36_12",nTopTips="#{RGPT_231130_362}",nSelectTips="#{RGPT_231130_365}",nPoint=400,nPointTips="#{RGPT_231130_189}",nDetail="#{RGPT_231130_616}",  },
}
--额外属性第三个boss专属
local g_Pata_BossBuffEx3 =
{
	[1] = {nName="#{RGPT_231130_366}",nBuffImg="set:Buff36 image:Buff36_13",nTopTips="#{RGPT_231130_618}",nSelectTips="#{RGPT_231130_620}",nPoint=0,nPointTips="#{RGPT_231130_384}",nDetail="#{RGPT_231130_619}",  },
	[2] = {nName="#{RGPT_231130_366}",nBuffImg="set:Buff36 image:Buff36_13",nTopTips="#{RGPT_231130_367}",nSelectTips="#{RGPT_231130_370}",nPoint=100,nPointTips="#{RGPT_231130_187}",nDetail="#{RGPT_231130_619}",  },
	[3] = {nName="#{RGPT_231130_366}",nBuffImg="set:Buff36 image:Buff36_13",nTopTips="#{RGPT_231130_368}",nSelectTips="#{RGPT_231130_371}",nPoint=200,nPointTips="#{RGPT_231130_188}",nDetail="#{RGPT_231130_619}", },
	[4] = {nName="#{RGPT_231130_366}",nBuffImg="set:Buff36 image:Buff36_13",nTopTips="#{RGPT_231130_369}",nSelectTips="#{RGPT_231130_372}",nPoint=400,nPointTips="#{RGPT_231130_189}",nDetail="#{RGPT_231130_619}",  },
}
--额外属性第四个boss专属
local g_Pata_BossBuffEx4 =
{
	[1] = {nName="#{RGPT_231130_373}",nBuffImg="set:Buff36 image:Buff36_14",nTopTips="#{RGPT_231130_621}",nSelectTips="#{RGPT_231130_622}",nPoint=0,nPointTips="#{RGPT_231130_384}",nDetail="#{RGPT_231130_623}",  },
	[2] = {nName="#{RGPT_231130_373}",nBuffImg="set:Buff36 image:Buff36_14",nTopTips="#{RGPT_231130_374}",nSelectTips="#{RGPT_231130_377}",nPoint=100,nPointTips="#{RGPT_231130_187}",nDetail="#{RGPT_231130_623}",  },
	[3] = {nName="#{RGPT_231130_373}",nBuffImg="set:Buff36 image:Buff36_14",nTopTips="#{RGPT_231130_375}",nSelectTips="#{RGPT_231130_378}",nPoint=200,nPointTips="#{RGPT_231130_188}",nDetail="#{RGPT_231130_623}",  },
	[4] = {nName="#{RGPT_231130_373}",nBuffImg="set:Buff36 image:Buff36_14",nTopTips="#{RGPT_231130_376}",nSelectTips="#{RGPT_231130_379}",nPoint=400,nPointTips="#{RGPT_231130_189}",nDetail="#{RGPT_231130_623}",  },
}
local g_Pata_AllBossBuff = --boss属性选择加分情况
{
	[1] 	= g_Pata_BossBuff1,
	[2] 	= g_Pata_BossBuff2,
	[3] 	= g_Pata_BossBuff3,
	[4] 	= g_Pata_BossBuffEx2,
	[5] 	= g_Pata_BossBuffEx3,
	[6] 	= g_Pata_BossBuffEx4,
}


local g_Pata_CloseTick = 1	--倒计时
local g_Pata_BossIdx = -1	--当前副本第几个boss索引
local g_Pata_BossCheck = {0,0,0,0,}--四个boss状态选择情况


local g_Pata_targetId = -1;
--===============================================
-- OnLoad()
--===============================================
function RouGe_BossDaZao_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--距离NPC距离
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--===============================================
-- OnLoad()
--===============================================
function RouGe_BossDaZao_OnLoad()   
	-- 保存界面的默认相对位置
	g_RouGe_BossDaZao_Frame_UnifiedPosition = RouGe_BossDaZao_Frame:GetProperty("UnifiedPosition");

	--控件
	--四个选择区域
	g_RouGe_BossDaZao_ItemList[1] = RouGe_BossDaZao_Item1
	g_RouGe_BossDaZao_ItemList[2] = RouGe_BossDaZao_Item2
	g_RouGe_BossDaZao_ItemList[3] = RouGe_BossDaZao_Item3
	g_RouGe_BossDaZao_ItemList[4] = RouGe_BossDaZao_Item4
	--四个boss状态title名字
	g_RouGe_BossDaZao_NameList[1] = RouGe_BossDaZao_Item1_Title
	g_RouGe_BossDaZao_NameList[2] = RouGe_BossDaZao_Item2_Title
	g_RouGe_BossDaZao_NameList[3] = RouGe_BossDaZao_Item3_Title
	g_RouGe_BossDaZao_NameList[4] = RouGe_BossDaZao_Item4_Title
	--四个boss状态图片显示
	g_RouGe_BossDaZao_ImgList[1] = RouGe_BossDaZao_Item1_Add1Image
	g_RouGe_BossDaZao_ImgList[2] = RouGe_BossDaZao_Item2_Add1Image
	g_RouGe_BossDaZao_ImgList[3] = RouGe_BossDaZao_Item3_Add1Image
	g_RouGe_BossDaZao_ImgList[4] = RouGe_BossDaZao_Item4_Add1Image
	--四个boss状态悬浮tips
	g_RouGe_BossDaZao_TopTipsList[1] = RouGe_BossDaZao_Item1_TitleBK
	g_RouGe_BossDaZao_TopTipsList[2] = RouGe_BossDaZao_Item2_TitleBK
	g_RouGe_BossDaZao_TopTipsList[3] = RouGe_BossDaZao_Item3_TitleBK
	g_RouGe_BossDaZao_TopTipsList[4] = RouGe_BossDaZao_Item4_TitleBK

	--四个boss状态积分显示
	g_RouGe_BossDaZao_PointList[1] = RouGe_BossDaZao_Item1_JiFen
	g_RouGe_BossDaZao_PointList[2] = RouGe_BossDaZao_Item2_JiFen
	g_RouGe_BossDaZao_PointList[3] = RouGe_BossDaZao_Item3_JiFen
	g_RouGe_BossDaZao_PointList[4] = RouGe_BossDaZao_Item4_JiFen

	--四个boss状态简要说明
	g_RouGe_BossDaZao_DetailList[1] = RouGe_BossDaZao_Item1_Text
	g_RouGe_BossDaZao_DetailList[2] = RouGe_BossDaZao_Item2_Text
	g_RouGe_BossDaZao_DetailList[3] = RouGe_BossDaZao_Item3_Text
	g_RouGe_BossDaZao_DetailList[4] = RouGe_BossDaZao_Item4_Text
	
	--第一个状态互斥按钮
	g_RouGe_BossDaZao_Select1List[1] = RouGe_BossDaZao_Item1_Btn0
	g_RouGe_BossDaZao_Select1List[2] = RouGe_BossDaZao_Item1_Btn1
	g_RouGe_BossDaZao_Select1List[3] = RouGe_BossDaZao_Item1_Btn2
	g_RouGe_BossDaZao_Select1List[4] = RouGe_BossDaZao_Item1_Btn3
	g_RouGe_BossDaZao_Select1List[5] = RouGe_BossDaZao_Item1_Btn4
	g_RouGe_BossDaZao_Select1List[6] = RouGe_BossDaZao_Item1_Btn5
	g_RouGe_BossDaZao_Select1List[7] = RouGe_BossDaZao_Item1_Btn6
	--第二个状态互斥按钮
	g_RouGe_BossDaZao_Select2List[1] = RouGe_BossDaZao_Item2_Btn0
	g_RouGe_BossDaZao_Select2List[2] = RouGe_BossDaZao_Item2_Btn1
	g_RouGe_BossDaZao_Select2List[3] = RouGe_BossDaZao_Item2_Btn2
	g_RouGe_BossDaZao_Select2List[4] = RouGe_BossDaZao_Item2_Btn3
	g_RouGe_BossDaZao_Select2List[5] = RouGe_BossDaZao_Item2_Btn4
	g_RouGe_BossDaZao_Select2List[6] = RouGe_BossDaZao_Item2_Btn5
	g_RouGe_BossDaZao_Select2List[7] = RouGe_BossDaZao_Item2_Btn6
	--第三个状态互斥按钮
	g_RouGe_BossDaZao_Select3List[1] = RouGe_BossDaZao_Item3_Btn0
	g_RouGe_BossDaZao_Select3List[2] = RouGe_BossDaZao_Item3_Btn1
	g_RouGe_BossDaZao_Select3List[3] = RouGe_BossDaZao_Item3_Btn2
	g_RouGe_BossDaZao_Select3List[4] = RouGe_BossDaZao_Item3_Btn3
	g_RouGe_BossDaZao_Select3List[5] = RouGe_BossDaZao_Item3_Btn4
	g_RouGe_BossDaZao_Select3List[6] = RouGe_BossDaZao_Item3_Btn5
	g_RouGe_BossDaZao_Select3List[7] = RouGe_BossDaZao_Item3_Btn6
	--第四个状态互斥按钮
	g_RouGe_BossDaZao_Select4List[1] = RouGe_BossDaZao_Item4_Btn0
	g_RouGe_BossDaZao_Select4List[2] = RouGe_BossDaZao_Item4_Btn1
	g_RouGe_BossDaZao_Select4List[3] = RouGe_BossDaZao_Item4_Btn2
	g_RouGe_BossDaZao_Select4List[4] = RouGe_BossDaZao_Item4_Btn3
	--按钮选中动画
	g_RouGe_BossDaZao_Select1Animate[1] = RouGe_BossDaZao_Item1_Btn0_Animate
	g_RouGe_BossDaZao_Select1Animate[2] = RouGe_BossDaZao_Item1_Btn1_Animate
	g_RouGe_BossDaZao_Select1Animate[3] = RouGe_BossDaZao_Item1_Btn2_Animate
	g_RouGe_BossDaZao_Select1Animate[4] = RouGe_BossDaZao_Item1_Btn3_Animate
	g_RouGe_BossDaZao_Select1Animate[5] = RouGe_BossDaZao_Item1_Btn4_Animate
	g_RouGe_BossDaZao_Select1Animate[6] = RouGe_BossDaZao_Item1_Btn5_Animate
	g_RouGe_BossDaZao_Select1Animate[7] = RouGe_BossDaZao_Item1_Btn6_Animate
	g_RouGe_BossDaZao_Select2Animate[1] = RouGe_BossDaZao_Item2_Btn0_Animate
	g_RouGe_BossDaZao_Select2Animate[2] = RouGe_BossDaZao_Item2_Btn1_Animate
	g_RouGe_BossDaZao_Select2Animate[3] = RouGe_BossDaZao_Item2_Btn2_Animate
	g_RouGe_BossDaZao_Select2Animate[4] = RouGe_BossDaZao_Item2_Btn3_Animate
	g_RouGe_BossDaZao_Select2Animate[5] = RouGe_BossDaZao_Item2_Btn4_Animate
	g_RouGe_BossDaZao_Select2Animate[6] = RouGe_BossDaZao_Item2_Btn5_Animate
	g_RouGe_BossDaZao_Select2Animate[7] = RouGe_BossDaZao_Item2_Btn6_Animate
	g_RouGe_BossDaZao_Select3Animate[1] = RouGe_BossDaZao_Item3_Btn0_Animate
	g_RouGe_BossDaZao_Select3Animate[2] = RouGe_BossDaZao_Item3_Btn1_Animate
	g_RouGe_BossDaZao_Select3Animate[3] = RouGe_BossDaZao_Item3_Btn2_Animate
	g_RouGe_BossDaZao_Select3Animate[4] = RouGe_BossDaZao_Item3_Btn3_Animate
	g_RouGe_BossDaZao_Select3Animate[5] = RouGe_BossDaZao_Item3_Btn4_Animate
	g_RouGe_BossDaZao_Select3Animate[6] = RouGe_BossDaZao_Item3_Btn5_Animate
	g_RouGe_BossDaZao_Select3Animate[7] = RouGe_BossDaZao_Item3_Btn6_Animate
	g_RouGe_BossDaZao_Select4Animate[1] = RouGe_BossDaZao_Item4_Btn0_Animate
	g_RouGe_BossDaZao_Select4Animate[2] = RouGe_BossDaZao_Item4_Btn1_Animate
	g_RouGe_BossDaZao_Select4Animate[3] = RouGe_BossDaZao_Item4_Btn2_Animate
	g_RouGe_BossDaZao_Select4Animate[4] = RouGe_BossDaZao_Item4_Btn3_Animate
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function RouGe_BossDaZao_Frame_On_ResetPos()
	RouGe_BossDaZao_Frame:SetProperty("UnifiedPosition", g_RouGe_BossDaZao_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function RouGe_BossDaZao_OnEvent(event)

    if(event == "UI_COMMAND" and tonumber(arg0) == 99894801) then
		--打开界面
		if(IsWindowShow("RouGe_BossDaZao")) then
			CloseWindow("RouGe_BossDaZao", true)
		end
		--添加NPC关心 不需要
		g_Pata_targetId = Get_XParam_INT(0)
		if g_Pata_targetId >= 0 then
			objCared = DataPool : GetNPCIDByServerID(g_Pata_targetId);
			RouGe_BossDaZao_BeginCareObject(objCared)
		end
		
		if Get_XParam_INT(1) > 0 then --第几个boss
			RouGe_BossDaZao_Open(Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3),Get_XParam_INT(4))
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99894702 ) then
		--开怪成功 关闭窗口
		RouGe_BossDaZao_OnClose()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99894703 ) then
		RouGe_BossDaZao_JustShow(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3))
	end
	if (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end

		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			RouGe_BossDaZao_OnClose()
		end
	end
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		RouGe_BossDaZao_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		RouGe_BossDaZao_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       RouGe_BossDaZao_OnClose()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
    end
         
end

--===============================================
-- RouGe_BossDaZao_OnClose()
--===============================================
function RouGe_BossDaZao_OnClose()
	RouGe_BossDaZao_StopCareObject()
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function RouGe_BossDaZao_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "RouGe_BossDaZao");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "RouGe_BossDaZao")
end


--=========================================================
--停止对某NPC的关心
--=========================================================
function RouGe_BossDaZao_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "RouGe_BossDaZao");
		g_Object = -1;
	end
end
--=========================================================
--help
--=========================================================
function RouGe_BossDaZao_Help()

end

--=========================================================
--默认打开界面
--nBossId boss索引
--nRandomList本期场地元素列表 需要拆分
--=========================================================
function RouGe_BossDaZao_Open(nBossIdx,nBossId,bLeader)
	--设置参数
	g_Pata_BossIdx = nBossIdx
	g_RouGe_BossDaZao_Select = {1,1,1,1}
	--PushDebugMessage(" nBossId="..nBossId)
	RouGe_BossDaZao_DragTitle:SetText(ScriptGlobal_Format("#{RGPT_231130_181}",TServerUI:GetMonsterNamebyDataID(nBossId)))
	--按钮状态设置
	for index=1,table.getn(g_RouGe_BossDaZao_ItemList)  do
		if index == table.getn(g_RouGe_BossDaZao_ItemList) then
			if g_Pata_BossIdx > 1 then
				g_RouGe_BossDaZao_ItemList[index]:Show()
				g_RouGe_BossDaZao_ImgList[index]:SetProperty( "Image", g_Pata_AllBossBuff[2+g_Pata_BossIdx][1].nBuffImg )
				g_RouGe_BossDaZao_TopTipsList[index]:SetToolTip(g_Pata_AllBossBuff[2+g_Pata_BossIdx][1].nTopTips)
			else
				g_RouGe_BossDaZao_ItemList[index]:Hide()
			end
		else
			g_RouGe_BossDaZao_ItemList[index]:Show()
			g_RouGe_BossDaZao_ImgList[index]:SetProperty( "Image", g_Pata_AllBossBuff[index][1].nBuffImg )
			g_RouGe_BossDaZao_TopTipsList[index]:SetToolTip(g_Pata_AllBossBuff[index][1].nTopTips);
		end
	end
	
	
	--显示词条
	for index=1,table.getn(g_RouGe_BossDaZao_NameList)  do
		g_RouGe_BossDaZao_NameList[index]:SetText(g_Pata_AllBossBuff[index][1].nName);
		g_RouGe_BossDaZao_DetailList[index]:SetText(g_Pata_AllBossBuff[index][1].nDetail);
		if index == table.getn(g_RouGe_BossDaZao_NameList)  and  g_Pata_BossIdx > 1 then
			--特殊处理
			g_RouGe_BossDaZao_NameList[index]:SetText(g_Pata_AllBossBuff[2+g_Pata_BossIdx][1].nName);
			g_RouGe_BossDaZao_DetailList[index]:SetText(g_Pata_AllBossBuff[2+g_Pata_BossIdx][1].nDetail);
		end
	end

	--显示属性 默认选中第一个属性
	for index=1,table.getn(g_RouGe_BossDaZao_Select1List)  do
		g_RouGe_BossDaZao_Select1List[index]:Enable()
		g_RouGe_BossDaZao_Select1Animate[index]:Hide()
		if index == 1 then
			g_RouGe_BossDaZao_Select1List[index]:SetCheck(1)
		else
			g_RouGe_BossDaZao_Select1List[index]:SetCheck(0)
		end
		g_RouGe_BossDaZao_Select1List[index]:SetText(g_Pata_AllBossBuff[1][index].nSelectTips)
	end
	for index=1,table.getn(g_RouGe_BossDaZao_Select2List)  do
		g_RouGe_BossDaZao_Select2List[index]:Enable()
		g_RouGe_BossDaZao_Select2Animate[index]:Hide()
		if index == 1 then
			g_RouGe_BossDaZao_Select2List[index]:SetCheck(1)
		else
			g_RouGe_BossDaZao_Select2List[index]:SetCheck(0)
		end
		g_RouGe_BossDaZao_Select2List[index]:SetText(g_Pata_AllBossBuff[2][index].nSelectTips)
	end
	for index=1,table.getn(g_RouGe_BossDaZao_Select3List)  do
		g_RouGe_BossDaZao_Select3List[index]:Enable()
		g_RouGe_BossDaZao_Select3Animate[index]:Hide()
		if index == 1 then
			g_RouGe_BossDaZao_Select3List[index]:SetCheck(1)
		else
			g_RouGe_BossDaZao_Select3List[index]:SetCheck(0)
		end
		g_RouGe_BossDaZao_Select3List[index]:SetText(g_Pata_AllBossBuff[3][index].nSelectTips)
	end
	for index=1,table.getn(g_RouGe_BossDaZao_Select4List)  do
		g_RouGe_BossDaZao_Select4List[index]:Enable()
		g_RouGe_BossDaZao_Select4Animate[index]:Hide()
		if index == 1 then
			g_RouGe_BossDaZao_Select4List[index]:SetCheck(1)
		else
			g_RouGe_BossDaZao_Select4List[index]:SetCheck(0)
		end
		g_RouGe_BossDaZao_Select4List[index]:SetText(g_Pata_AllBossBuff[2+g_Pata_BossIdx][index].nSelectTips)
	end
	
	--显示积分 默认显示第一个
	for index=1,table.getn(g_RouGe_BossDaZao_PointList)  do
		g_RouGe_BossDaZao_PointList[index]:SetText(g_Pata_AllBossBuff[index][1].nPointTips);
		if index == table.getn(g_RouGe_BossDaZao_PointList)  and  g_Pata_BossIdx > 1 then
			--特殊处理
			g_RouGe_BossDaZao_PointList[index]:SetText(g_Pata_AllBossBuff[2+g_Pata_BossIdx][1].nPointTips);
		end
	end
	
	--队长显示
	if bLeader == 1 then
		RouGe_BossDaZao_Ok:Show()
		RouGe_BossDaZao_DuiYuanText:Hide()
	else
		RouGe_BossDaZao_Ok:Hide()
		RouGe_BossDaZao_DuiYuanText:Show()
		RouGe_BossDaZao_DuiYuanText:SetText("#{RGPT_231130_191}");
	end

	--重新计算积分
	CalRouGe_BossDaZao_Point()
	this:Show()
end

--=========================================================
--boss属性选择
--=========================================================
function RouGe_BossDaZao_Select1(nIndex)
	if nIndex < 1 or nIndex > 7 then
		return
	end	
	for index=1,table.getn(g_RouGe_BossDaZao_Select1List)  do
		if index == nIndex then
			g_RouGe_BossDaZao_Select1List[index]:SetCheck(1)
		else
			g_RouGe_BossDaZao_Select1List[index]:SetCheck(0)
		end
	end
	g_RouGe_BossDaZao_Select[1] = nIndex
	--重新设置积分显示
	g_RouGe_BossDaZao_PointList[1]:SetText(g_Pata_AllBossBuff[1][nIndex].nPointTips);
	--重新计算积分
	CalRouGe_BossDaZao_Point()
end

--=========================================================
--boss属性选择
--=========================================================
function RouGe_BossDaZao_Select2(nIndex)
	if nIndex < 1 or nIndex > 7 then
		return
	end
	for index=1,table.getn(g_RouGe_BossDaZao_Select2List)  do
		if index == nIndex then
			g_RouGe_BossDaZao_Select2List[index]:SetCheck(1)
		else
			g_RouGe_BossDaZao_Select2List[index]:SetCheck(0)
		end
	end
	g_RouGe_BossDaZao_Select[2] = nIndex
	--重新设置积分显示
	g_RouGe_BossDaZao_PointList[2]:SetText(g_Pata_AllBossBuff[2][nIndex].nPointTips);
	--重新计算积分
	CalRouGe_BossDaZao_Point()
end

--=========================================================
--boss属性选择
--=========================================================
function RouGe_BossDaZao_Select3(nIndex)
	if nIndex < 1 or nIndex > 7 then
		return
	end
	for index=1,table.getn(g_RouGe_BossDaZao_Select3List)  do
		if index == nIndex then
			g_RouGe_BossDaZao_Select3List[index]:SetCheck(1)
		else
			g_RouGe_BossDaZao_Select3List[index]:SetCheck(0)
		end
	end
	g_RouGe_BossDaZao_Select[3] = nIndex
	--重新设置积分显示
	g_RouGe_BossDaZao_PointList[3]:SetText(g_Pata_AllBossBuff[3][nIndex].nPointTips);
	--重新计算积分
	CalRouGe_BossDaZao_Point()
end

--=========================================================
--boss属性选择
--=========================================================
function RouGe_BossDaZao_Select4(nIndex)
	if nIndex < 1 or nIndex > 4 then
		return
	end
	for index=1,table.getn(g_RouGe_BossDaZao_Select4List)  do
		if index == nIndex then
			g_RouGe_BossDaZao_Select4List[index]:SetCheck(1)
		else
			g_RouGe_BossDaZao_Select4List[index]:SetCheck(0)
		end
	end
	g_RouGe_BossDaZao_Select[4] = nIndex
	--重新设置积分显示
	g_RouGe_BossDaZao_PointList[4]:SetText(g_Pata_AllBossBuff[2+g_Pata_BossIdx][nIndex].nPointTips);
	--重新计算积分
	CalRouGe_BossDaZao_Point()
end

--=========================================================
--boss积分计算
--=========================================================
function CalRouGe_BossDaZao_Point()
	local bBossCheck1 = g_RouGe_BossDaZao_Select[1]
	local bBossCheck2 = g_RouGe_BossDaZao_Select[2]
	local bBossCheck3 = g_RouGe_BossDaZao_Select[3]
	local bBossCheck4 = g_RouGe_BossDaZao_Select[4]
	--PushDebugMessage("test Idx="..g_Pata_BossIdx.." Boss1="..bBossCheck1.." Boss2="..bBossCheck2.." Boss3="..bBossCheck3.." Boss4="..bBossCheck4)
	local nBasePoint = g_Pata_AllBossBuff[1][bBossCheck1].nPoint + g_Pata_AllBossBuff[2][bBossCheck2].nPoint +g_Pata_AllBossBuff[3][bBossCheck3].nPoint
	if g_Pata_BossIdx > 1 then
		nBasePoint = nBasePoint + g_Pata_AllBossBuff[2+g_Pata_BossIdx][bBossCheck4].nPoint
	end
	--PushDebugMessage("test 积分 all="..nBasePoint.." bBossCheck1="..bBossCheck1.." bBossCheck2="..bBossCheck3.." bBossCheck3="..bBossCheck3.." bBossCheck4"..bBossCheck4)
	
	RouGe_BossDaZao_ZongJiFen:SetText(ScriptGlobal_Format("#{RGPT_231130_193}",tostring(nBasePoint)));
	RouGe_BossDaZao_ZongJiFen:Show();
end


--=========================================================
--boss选择确认
--=========================================================
function RouGe_BossDaZao_Confirm()
	--按钮状态选择
	local bBossCheck1 = g_RouGe_BossDaZao_Select[1]
	local bBossCheck2 = g_RouGe_BossDaZao_Select[2]
	local bBossCheck3 = g_RouGe_BossDaZao_Select[3]
	local bBossCheck4 = -1
	if g_Pata_BossIdx > 1 then
		bBossCheck4 = g_RouGe_BossDaZao_Select[4]
	end	
	--PushDebugMessage("test Boss1="..bBossCheck1.." Boss2="..bBossCheck2.." Boss3="..bBossCheck3.." Boss4="..bBossCheck4)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BossChoiceConfirm" )
		Set_XSCRIPT_ScriptID( 998947)	
		Set_XSCRIPT_Parameter( 0 ,g_Pata_targetId)
		Set_XSCRIPT_Parameter( 1 ,bBossCheck1)
		Set_XSCRIPT_Parameter( 2 ,bBossCheck2)
		Set_XSCRIPT_Parameter( 3 ,bBossCheck3)
		Set_XSCRIPT_Parameter( 4 ,bBossCheck4)
		Set_XSCRIPT_ParamCount( 5 )
	Send_XSCRIPT()
end


--=========================================================
--预告界面
--nBossIdx boss索引
--=========================================================
function RouGe_BossDaZao_JustShow(nBossIdx,nBossId,nBossChoiceList,nTickTime)
	g_RouGe_BossDaZao_Select[1] = math.mod(nBossChoiceList,10)
	g_RouGe_BossDaZao_Select[2] = math.floor(math.mod(nBossChoiceList,100)/10)  
	g_RouGe_BossDaZao_Select[3] = math.floor(math.mod(nBossChoiceList,1000)/100)
	g_RouGe_BossDaZao_Select[4] = math.floor(math.mod(nBossChoiceList,10000)/1000) 
	RouGe_BossDaZao_DragTitle:SetText(ScriptGlobal_Format("#{RGPT_231130_181}",TServerUI:GetMonsterNamebyDataID(nBossId)))

	g_Pata_BossIdx = nBossIdx
	--动画重置
	KillTimer("RouGe_BossDaZao_CloseWindow()")
	--PushDebugMessage("test JustShow nBossId="..nBossId.." nBossChoiceList="..nBossChoiceList)
	
	--确认键不可点
	RouGe_BossDaZao_Ok:Hide()
	
	for index=1,table.getn(g_RouGe_BossDaZao_ItemList)  do
		if index == table.getn(g_RouGe_BossDaZao_ItemList) then
			if g_Pata_BossIdx > 1 then
				g_RouGe_BossDaZao_ItemList[index]:Show()
				g_RouGe_BossDaZao_ImgList[index]:SetProperty( "Image", g_Pata_AllBossBuff[2+g_Pata_BossIdx][g_RouGe_BossDaZao_Select[index]].nBuffImg )
				g_RouGe_BossDaZao_TopTipsList[index]:SetToolTip(g_Pata_AllBossBuff[2+g_Pata_BossIdx][g_RouGe_BossDaZao_Select[index]].nTopTips)
			else
				g_RouGe_BossDaZao_ItemList[index]:Hide()
			end
		else
			g_RouGe_BossDaZao_ItemList[index]:Show()
			g_RouGe_BossDaZao_ImgList[index]:SetProperty( "Image", g_Pata_AllBossBuff[index][g_RouGe_BossDaZao_Select[index]].nBuffImg )
			g_RouGe_BossDaZao_TopTipsList[index]:SetToolTip(g_Pata_AllBossBuff[index][g_RouGe_BossDaZao_Select[index]].nTopTips);
		end
	end

	
	--显示词条
	for index=1,table.getn(g_RouGe_BossDaZao_NameList)  do
		g_RouGe_BossDaZao_NameList[index]:SetText(g_Pata_AllBossBuff[index][g_RouGe_BossDaZao_Select[index]].nName);
		g_RouGe_BossDaZao_DetailList[index]:SetText(g_Pata_AllBossBuff[index][g_RouGe_BossDaZao_Select[index]].nDetail);
		if index == table.getn(g_RouGe_BossDaZao_NameList)  and  g_Pata_BossIdx > 1 then
			--特殊处理
			g_RouGe_BossDaZao_NameList[index]:SetText(g_Pata_AllBossBuff[2+g_Pata_BossIdx][g_RouGe_BossDaZao_Select[index]].nName);
			g_RouGe_BossDaZao_DetailList[index]:SetText(g_Pata_AllBossBuff[2+g_Pata_BossIdx][g_RouGe_BossDaZao_Select[index]].nDetail);
		end
	end
	
	--显示属性 
	for index=1,table.getn(g_RouGe_BossDaZao_Select1List)  do
		if index == g_RouGe_BossDaZao_Select[1] then
			g_RouGe_BossDaZao_Select1Animate[index]:Show()
			g_RouGe_BossDaZao_Select1Animate[index]:Play(true)	
			g_RouGe_BossDaZao_Select1List[index]:SetCheck(1)
		else
			g_RouGe_BossDaZao_Select1Animate[index]:Hide()
			g_RouGe_BossDaZao_Select1List[index]:SetCheck(0)
		end
		g_RouGe_BossDaZao_Select1List[index]:SetText(g_Pata_AllBossBuff[1][index].nSelectTips)
		g_RouGe_BossDaZao_Select1List[index]:Disable()
	end
	for index=1,table.getn(g_RouGe_BossDaZao_Select2List)  do
		if index == g_RouGe_BossDaZao_Select[2] then
			g_RouGe_BossDaZao_Select2Animate[index]:Show()
			g_RouGe_BossDaZao_Select2Animate[index]:Play(true)	
			g_RouGe_BossDaZao_Select2List[index]:SetCheck(1)
		else
			g_RouGe_BossDaZao_Select2Animate[index]:Hide()
			g_RouGe_BossDaZao_Select2List[index]:SetCheck(0)
		end
		g_RouGe_BossDaZao_Select2List[index]:SetText(g_Pata_AllBossBuff[2][index].nSelectTips)
		g_RouGe_BossDaZao_Select2List[index]:Disable()
	end
	for index=1,table.getn(g_RouGe_BossDaZao_Select3List)  do
		if index == g_RouGe_BossDaZao_Select[3] then
			g_RouGe_BossDaZao_Select3Animate[index]:Show()
			g_RouGe_BossDaZao_Select3Animate[index]:Play(true)	
			g_RouGe_BossDaZao_Select3List[index]:SetCheck(1)
		else
			g_RouGe_BossDaZao_Select3Animate[index]:Hide()
			g_RouGe_BossDaZao_Select3List[index]:SetCheck(0)
		end
		g_RouGe_BossDaZao_Select3List[index]:SetText(g_Pata_AllBossBuff[3][index].nSelectTips)
		g_RouGe_BossDaZao_Select3List[index]:Disable()
	end
	if g_Pata_BossIdx > 1 then
		for index=1,table.getn(g_RouGe_BossDaZao_Select4List)  do
			if index == g_RouGe_BossDaZao_Select[4] then
				g_RouGe_BossDaZao_Select4Animate[index]:Show()
				g_RouGe_BossDaZao_Select4Animate[index]:Play(true)	
				g_RouGe_BossDaZao_Select4List[index]:SetCheck(1)
			else
				g_RouGe_BossDaZao_Select4Animate[index]:Hide()
				g_RouGe_BossDaZao_Select4List[index]:SetCheck(0)
			end
			g_RouGe_BossDaZao_Select4List[index]:SetText(g_Pata_AllBossBuff[2+g_Pata_BossIdx][index].nSelectTips)
			g_RouGe_BossDaZao_Select4List[index]:Disable()
		end
	end
	
	
	--显示积分 
	for index=1,table.getn(g_RouGe_BossDaZao_PointList)  do
		g_RouGe_BossDaZao_PointList[index]:SetText(g_Pata_AllBossBuff[index][g_RouGe_BossDaZao_Select[index]].nPointTips);
		if index == table.getn(g_RouGe_BossDaZao_PointList)  and  g_Pata_BossIdx > 1 then
			--特殊处理
			g_RouGe_BossDaZao_PointList[index]:SetText(g_Pata_AllBossBuff[2+g_Pata_BossIdx][g_RouGe_BossDaZao_Select[index]].nPointTips);
		end
	end
	
	--重新计算积分
	CalRouGe_BossDaZao_Point()

	--倒计时
	RouGe_BossDaZao_DuiYuanText:Show()
	SetTimer("RouGe_BossDaZao","RouGe_BossDaZao_CloseWindow()", 1000);		--设置定时器5秒钟倒计时
	g_Pata_CloseTick = nTickTime
	RouGe_BossDaZao_DuiYuanText:SetText(ScriptGlobal_Format("#{RGPT_231130_192}",g_Pata_CloseTick));

	this:Show()
end


--================================================
-- 倒计时界面
--================================================
function RouGe_BossDaZao_CloseWindow()
	KillTimer("RouGe_BossDaZao_CloseWindow()")
	g_Pata_CloseTick = g_Pata_CloseTick - 1
	RouGe_BossDaZao_DuiYuanText:SetText(ScriptGlobal_Format("#{RGPT_231130_192}",g_Pata_CloseTick));
	--PushDebugMessage("test  RouGe_BossDaZao_CloseWindow  g_Pata_CloseTick="..g_Pata_CloseTick)
	if g_Pata_CloseTick > 0 then
		SetTimer("RouGe_BossDaZao","RouGe_BossDaZao_CloseWindow()", 1000)
	else
		--关闭界面
		RouGe_BossDaZao_OnClose()
	end
end

--=========================================================
--各种说明
--=========================================================
function RouGe_BossDaZao_Help()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BossChoiceHelp" )
		Set_XSCRIPT_ScriptID( 998947)	
		Set_XSCRIPT_Parameter( 0 ,g_Pata_targetId)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end