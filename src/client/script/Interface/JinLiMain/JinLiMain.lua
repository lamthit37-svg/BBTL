-- JinLiMain 2019中秋锦鲤 2019-8-1 lishilong
-- !!!reloadscript =JinLiMain
--
local MAX_OBJ_DISTANCE 	= 3.0
local g_objCared 		= -1
local g_npcObjId 		= -1
local g_JinLiMain_Frame_UnifiedPosition
local bCaredObj 		= 0
local bCaredMoney 		= 0

-- 是否打开广告界面 目前暂时关掉了
local bOpenRewardShow	= 0

-- 当前服务器时间天数
local g_nCurDayServer   = 0
-- 活动开启时间 废弃 不用了
-- local g_nDayStart   	= 0
-- 今天是否用过月饼
local g_bIsUseYueBing	= 0
-- 是否已经过了帮会锦鲤传递时间
local g_bFinishBangHuiLucky	= 0

-- -- NPC寻路信息 苏州（251,265）月纤纤
local g_infoNPCGoto     = 
{
	-- NPC寻路信息 洛阳（264,243）典峰
	[1] = {nSceneID = 0, nPosX = 264, nPosY = 243, strNPCName = "典峰"},
	-- NPC寻路信息 苏州（299,316）武神像
    [2] = {nSceneID = 1, nPosX = 299, nPosY = 316, strNPCName = "武神像"},
}

-- 锦鲤数量
local g_nMaxJinLiNum	= 7

-- 活动时间
-- 第一阶段 抽取锦鲤
local g_TimeStart					= 20210924		-- 20201116		-- 20190905
local g_TimeStep1End				= 20210930		-- 20201122		-- 20190911
-- 第二阶段 传递锦鲤
local g_TimeStep2Start				= 20211001		-- 20201123		-- 20190912
local g_TimeEnd						= 20211007		-- 20201129		-- 20190918
-- 领奖阶段是一个活动时间的延续。
local g_RewardTimeStart				= 20211008		-- 20201130		-- 20190919
local g_RewardTimeEnd				= 20211010		-- 20201202		-- 20190925
-- 帮会锦鲤开启时间
local g_TimeBangHuiDay				= 20211001		-- 20201123		-- 20190913

-- 为了避免跨月计算 增加活动第x天的数组
local g_tabTimeStep1				=
{
	[1] = 20210924,			-- [1] = 20201116,			-- [1] = 20190905,
	[2] = 20210925,			-- [2] = 20201117,			-- [2] = 20190906,
	[3] = 20210926,			-- [3] = 20201118,			-- [3] = 20190907,
	[4] = 20210927,			-- [4] = 20201119,			-- [4] = 20190908,
	[5] = 20210928,			-- [5] = 20201120,			-- [5] = 20190909,
	[6] = 20210929,			-- [6] = 20201121,			-- [6] = 20190910,
	[7] = 20210930,			-- [7] = 20201122,			-- [7] = 20190911,
}

local g_tabTimeStep2				=
{
	[1] = 20211001,			-- [1] = 20201123,			-- [1] = 20190912,
	[2] = 20211002,			-- [2] = 20201124,			-- [2] = 20190913,
	[3] = 20211003,			-- [3] = 20201125,			-- [3] = 20190914,
	[4] = 20211004,			-- [4] = 20201126,			-- [4] = 20190915,
	[5] = 20211005,			-- [5] = 20201127,			-- [5] = 20190916,
	[6] = 20211006,			-- [6] = 20201128,			-- [6] = 20190917,
	[7] = 20211007,			-- [7] = 20201129,			-- [7] = 20190918,
}

-- x月x号抽出的字典
local g_tabStrDicOpenTime	=
{
	[1] = "#{ZQJL_190725_295}",
	[2] = "#{ZQJL_190725_296}",
	[3] = "#{ZQJL_190725_297}",
	[4] = "#{ZQJL_190725_298}",
	[5] = "#{ZQJL_190725_299}",
	[6] = "#{ZQJL_190725_300}",
	[7] = "#{ZQJL_190725_301}",
}

-- 全服幸运儿开奖时间时分秒
local g_TimeQuanFuStart			= 190000
local g_TimeQuanFuEnd			= 193000

-- 锦鲤开奖时间时分秒
local g_TimeJinLiStart			= 210000

-------------- 控件
-- 阶段1 的灯光
local g_controlStep1Light 		= {}
-- 阶段1 的锦鲤亮兔子控件
local g_controlStep1Rabbit	 	= {}
-- 阶段1 的锦鲤灰兔子控件
local g_controlStep1NoRabbit	= {}
-- 阶段1 的锦鲤名字控件
local g_controlStep1JinLiName 	= {}

-- 阶段2 的灯光
local g_controlStep2Light 		= {}
-- 阶段2 的今日开奖
local g_controlStep2TodayOpen 	= {}
-- 阶段2 的锦鲤亮兔子控件
local g_controlStep2Rabbit	 	= {}
-- 阶段2 的锦鲤灰兔子控件
local g_controlStep2NoRabbit	= {}
-- 阶段2 的锦鲤名字控件
local g_controlStep2JinLiName 	= {}
-- 阶段2 的宝箱控件
local g_controlStep2BoxWithRabbit	= {}
-- 阶段2 的已开奖控件
local g_controlStep2YKJ		 	= {}
-- 阶段2 的无锦鲤控件
local g_controlStep2NULL	 	= {}
-- 阶段2 的全服幸运儿名字控件
local g_controlStep2Lucky2Name	= {}
-- 阶段2 帮会幸运儿信息1 控件
local g_controlStep2Lucky3T1	= {}
-- 阶段2 帮会幸运儿信息2 控件
local g_controlStep2Lucky3T2	= {}
-- 阶段2 好友幸运儿信息1 控件
local g_controlStep2Lucky4T1	= {}
-- 阶段2 好友幸运儿信息2 控件
local g_controlStep2Lucky4T2	= {}

--=========================================================
-- PreLoad
--=========================================================
function JinLiMain_PreLoad()
	-- this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	if 1 == bCaredMoney then
		this:RegisterEvent("MONEY_CHANGE_EX", false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	end
	this:RegisterEvent("ADJEST_UI_POS")
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
    
    this:RegisterEvent("OPEN_JINLI_UI")
    this:RegisterEvent("REFRESH_JINLI_UI")
    this:RegisterEvent("CLOSE_JINLI_UI")
end

--=========================================================
-- OnLoad
--=========================================================
function JinLiMain_OnLoad()
	g_JinLiMain_Frame_UnifiedPosition = JinLiMain_MainFrame:GetProperty("UnifiedPosition")

	-- 一阶段抽锦鲤的光
	g_controlStep1Light[1]		= JinLiMain_Frame_Name1_Light
	g_controlStep1Light[2]		= JinLiMain_Frame_Name2_Light
	g_controlStep1Light[3]		= JinLiMain_Frame_Name3_Light
	g_controlStep1Light[4]		= JinLiMain_Frame_Name4_Light
	g_controlStep1Light[5]		= JinLiMain_Frame_Name5_Light
	g_controlStep1Light[6]		= JinLiMain_Frame_Name6_Light
	g_controlStep1Light[7]		= JinLiMain_Frame_Name7_Light

	-- 一阶段抽锦鲤 已有锦鲤显示
	g_controlStep1Rabbit[1]		= JinLiMain_Frame_Name1_Rabbit
	g_controlStep1Rabbit[2]		= JinLiMain_Frame_Name2_Rabbit
	g_controlStep1Rabbit[3]		= JinLiMain_Frame_Name3_Rabbit
	g_controlStep1Rabbit[4]		= JinLiMain_Frame_Name4_Rabbit
	g_controlStep1Rabbit[5]		= JinLiMain_Frame_Name5_Rabbit
	g_controlStep1Rabbit[6]		= JinLiMain_Frame_Name6_Rabbit
	g_controlStep1Rabbit[7]		= JinLiMain_Frame_Name7_Rabbit

	-- 一阶段抽锦鲤 还没有锦鲤显示
	g_controlStep1NoRabbit[1]	= JinLiMain_Frame_Name1_EmptyRabbit
	g_controlStep1NoRabbit[2]	= JinLiMain_Frame_Name2_EmptyRabbit
	g_controlStep1NoRabbit[3]	= JinLiMain_Frame_Name3_EmptyRabbit
	g_controlStep1NoRabbit[4]	= JinLiMain_Frame_Name4_EmptyRabbit
	g_controlStep1NoRabbit[5]	= JinLiMain_Frame_Name5_EmptyRabbit
	g_controlStep1NoRabbit[6]	= JinLiMain_Frame_Name6_EmptyRabbit
	g_controlStep1NoRabbit[7]	= JinLiMain_Frame_Name7_EmptyRabbit

	-- 一阶段抽锦鲤 锦鲤名字
	g_controlStep1JinLiName[1]	= JinLiMain_Frame_Name1_Text
	g_controlStep1JinLiName[2]	= JinLiMain_Frame_Name2_Text
	g_controlStep1JinLiName[3]	= JinLiMain_Frame_Name3_Text
	g_controlStep1JinLiName[4]	= JinLiMain_Frame_Name4_Text
	g_controlStep1JinLiName[5]	= JinLiMain_Frame_Name5_Text
	g_controlStep1JinLiName[6]	= JinLiMain_Frame_Name6_Text
	g_controlStep1JinLiName[7]	= JinLiMain_Frame_Name7_Text

	-- 二阶段传递锦鲤 光
	g_controlStep2Light[1]		= JinLiMain_Frame1_Name1_Light
	g_controlStep2Light[2]		= JinLiMain_Frame1_Name2_Light
	g_controlStep2Light[3]		= JinLiMain_Frame1_Name3_Light
	g_controlStep2Light[4]		= JinLiMain_Frame1_Name4_Light
	g_controlStep2Light[5]		= JinLiMain_Frame1_Name5_Light
	g_controlStep2Light[6]		= JinLiMain_Frame1_Name6_Light
	g_controlStep2Light[7]		= JinLiMain_Frame1_Name7_Light

	-- 二阶段传递锦鲤 今日开奖图片
	g_controlStep2TodayOpen[1]	= JinLiMain_Frame1_Name1_TodayOpen
	g_controlStep2TodayOpen[2]	= JinLiMain_Frame1_Name2_TodayOpen
	g_controlStep2TodayOpen[3]	= JinLiMain_Frame1_Name3_TodayOpen
	g_controlStep2TodayOpen[4]	= JinLiMain_Frame1_Name4_TodayOpen
	g_controlStep2TodayOpen[5]	= JinLiMain_Frame1_Name5_TodayOpen
	g_controlStep2TodayOpen[6]	= JinLiMain_Frame1_Name6_TodayOpen
	g_controlStep2TodayOpen[7]	= JinLiMain_Frame1_Name7_TodayOpen

	-- 二阶段传递锦鲤 已有锦鲤
	g_controlStep2Rabbit[1]		= JinLiMain_Frame1_Name1_Rabbit
	g_controlStep2Rabbit[2]		= JinLiMain_Frame1_Name2_Rabbit
	g_controlStep2Rabbit[3]		= JinLiMain_Frame1_Name3_Rabbit
	g_controlStep2Rabbit[4]		= JinLiMain_Frame1_Name4_Rabbit
	g_controlStep2Rabbit[5]		= JinLiMain_Frame1_Name5_Rabbit
	g_controlStep2Rabbit[6]		= JinLiMain_Frame1_Name6_Rabbit
	g_controlStep2Rabbit[7]		= JinLiMain_Frame1_Name7_Rabbit

	-- 二阶段传递锦鲤 没有锦鲤
	g_controlStep2NoRabbit[1]	= JinLiMain_Frame1_Name1_EmptyRabbit
	g_controlStep2NoRabbit[2]	= JinLiMain_Frame1_Name2_EmptyRabbit
	g_controlStep2NoRabbit[3]	= JinLiMain_Frame1_Name3_EmptyRabbit
	g_controlStep2NoRabbit[4]	= JinLiMain_Frame1_Name4_EmptyRabbit
	g_controlStep2NoRabbit[5]	= JinLiMain_Frame1_Name5_EmptyRabbit
	g_controlStep2NoRabbit[6]	= JinLiMain_Frame1_Name6_EmptyRabbit
	g_controlStep2NoRabbit[7]	= JinLiMain_Frame1_Name7_EmptyRabbit

	-- 二阶段传递锦鲤 锦鲤名字
	g_controlStep2JinLiName[1]	= JinLiMain_Frame1_Name1_Text
	g_controlStep2JinLiName[2]	= JinLiMain_Frame1_Name2_Text
	g_controlStep2JinLiName[3]	= JinLiMain_Frame1_Name3_Text
	g_controlStep2JinLiName[4]	= JinLiMain_Frame1_Name4_Text
	g_controlStep2JinLiName[5]	= JinLiMain_Frame1_Name5_Text
	g_controlStep2JinLiName[6]	= JinLiMain_Frame1_Name6_Text
	g_controlStep2JinLiName[7]	= JinLiMain_Frame1_Name7_Text

	-- 二阶段传递锦鲤 拿着盒子的兔子
	g_controlStep2BoxWithRabbit[1]		= JinLiMain_Frame1_Name1_Box
	g_controlStep2BoxWithRabbit[2]		= JinLiMain_Frame1_Name2_Box
	g_controlStep2BoxWithRabbit[3]		= JinLiMain_Frame1_Name3_Box
	g_controlStep2BoxWithRabbit[4]		= JinLiMain_Frame1_Name4_Box
	g_controlStep2BoxWithRabbit[5]		= JinLiMain_Frame1_Name5_Box
	g_controlStep2BoxWithRabbit[6]		= JinLiMain_Frame1_Name6_Box
	g_controlStep2BoxWithRabbit[7]		= JinLiMain_Frame1_Name7_Box

	-- 二阶段传递锦鲤 已开奖图片
	g_controlStep2YKJ[1]		= JinLiMain_Frame1_Name1_YKJ
	g_controlStep2YKJ[2]		= JinLiMain_Frame1_Name2_YKJ
	g_controlStep2YKJ[3]		= JinLiMain_Frame1_Name3_YKJ
	g_controlStep2YKJ[4]		= JinLiMain_Frame1_Name4_YKJ
	g_controlStep2YKJ[5]		= JinLiMain_Frame1_Name5_YKJ
	g_controlStep2YKJ[6]		= JinLiMain_Frame1_Name6_YKJ
	g_controlStep2YKJ[7]		= JinLiMain_Frame1_Name7_YKJ

	-- 二阶段传递锦鲤 暂无人选图片
	g_controlStep2NULL[1]		= JinLiMain_Frame1_Name1_Null
	g_controlStep2NULL[2]		= JinLiMain_Frame1_Name2_Null
	g_controlStep2NULL[3]		= JinLiMain_Frame1_Name3_Null
	g_controlStep2NULL[4]		= JinLiMain_Frame1_Name4_Null
	g_controlStep2NULL[5]		= JinLiMain_Frame1_Name5_Null
	g_controlStep2NULL[6]		= JinLiMain_Frame1_Name6_Null
	g_controlStep2NULL[7]		= JinLiMain_Frame1_Name7_Null

	-- 主界面废弃以下奖励展示控件
	-- g_controlStep2Lucky2Name[1]	= JinLiMain_Frame1_Reward1_Text3
	-- g_controlStep2Lucky2Name[2]	= JinLiMain_Frame1_Reward1_Text4
	-- g_controlStep2Lucky2Name[3]	= JinLiMain_Frame1_Reward1_Text5
	-- g_controlStep2Lucky2Name[4]	= JinLiMain_Frame1_Reward1_Text6
	-- g_controlStep2Lucky2Name[5]	= JinLiMain_Frame1_Reward1_Text7
	-- g_controlStep2Lucky2Name[6]	= JinLiMain_Frame1_Reward1_Text8
	-- g_controlStep2Lucky2Name[7]	= JinLiMain_Frame1_Reward1_Text9

	-- g_controlStep2Lucky3T1[1]	= JinLiMain_Frame1_Reward2_Text1
	-- g_controlStep2Lucky3T1[2]	= JinLiMain_Frame1_Reward2_Text2
	-- g_controlStep2Lucky3T1[3]	= JinLiMain_Frame1_Reward2_Text3
	-- g_controlStep2Lucky3T1[4]	= JinLiMain_Frame1_Reward2_Text4
	-- g_controlStep2Lucky3T1[5]	= JinLiMain_Frame1_Reward2_Text5
	-- g_controlStep2Lucky3T1[6]	= JinLiMain_Frame1_Reward2_Text6
	-- g_controlStep2Lucky3T1[7]	= JinLiMain_Frame1_Reward2_Text7

	-- g_controlStep2Lucky3T2[1]	= JinLiMain_Frame1_Reward2_Text1_1
	-- g_controlStep2Lucky3T2[2]	= JinLiMain_Frame1_Reward2_Text2_1
	-- g_controlStep2Lucky3T2[3]	= JinLiMain_Frame1_Reward2_Text3_1
	-- g_controlStep2Lucky3T2[4]	= JinLiMain_Frame1_Reward2_Text4_1
	-- g_controlStep2Lucky3T2[5]	= JinLiMain_Frame1_Reward2_Text5_1
	-- g_controlStep2Lucky3T2[6]	= JinLiMain_Frame1_Reward2_Text6_1
	-- g_controlStep2Lucky3T2[7]	= JinLiMain_Frame1_Reward2_Text7_1

	-- g_controlStep2Lucky4T1[1]	= JinLiMain_Frame1_Reward3_Text1
	-- g_controlStep2Lucky4T1[2]	= JinLiMain_Frame1_Reward3_Text2
	-- g_controlStep2Lucky4T1[3]	= JinLiMain_Frame1_Reward3_Text3
	-- g_controlStep2Lucky4T1[4]	= JinLiMain_Frame1_Reward3_Text4
	-- g_controlStep2Lucky4T1[5]	= JinLiMain_Frame1_Reward3_Text5
	-- g_controlStep2Lucky4T1[6]	= JinLiMain_Frame1_Reward3_Text6
	-- g_controlStep2Lucky4T1[7]	= JinLiMain_Frame1_Reward3_Text7

	-- g_controlStep2Lucky4T2[1]	= JinLiMain_Frame1_Reward3_Text1_1
	-- g_controlStep2Lucky4T2[2]	= JinLiMain_Frame1_Reward3_Text2_1
	-- g_controlStep2Lucky4T2[3]	= JinLiMain_Frame1_Reward3_Text3_1
	-- g_controlStep2Lucky4T2[4]	= JinLiMain_Frame1_Reward3_Text4_1
	-- g_controlStep2Lucky4T2[5]	= JinLiMain_Frame1_Reward3_Text5_1
	-- g_controlStep2Lucky4T2[6]	= JinLiMain_Frame1_Reward3_Text6_1
	-- g_controlStep2Lucky4T2[7]	= JinLiMain_Frame1_Reward3_Text7_1	
end

--=========================================================
-- OnEvent
--=========================================================
function JinLiMain_OnEvent(event)
    if event == "OPEN_JINLI_UI" or event == "REFRESH_JINLI_UI" then
		-- 0 关闭，1打开， 2刷新
        local nOpType 	= 1
        if event == "REFRESH_JINLI_UI" then
            nOpType = 2
        end

		local objid = tonumber(arg0)
		
		if 1 == bCaredObj then
			if objid == nil or objid < 0 then
				if this:IsVisible() then
					JinLiMain_OnClose()
				end
			end
		end
		
		if 1 == nOpType then
			-- 打开界面
			-- 关注npc
			if 1 == bCaredObj then
				g_npcObjId = objid
				g_objCared = DataPool : GetNPCIDByServerID(tonumber(objid))
				BeginCareObject_JinLiMain()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	JinLiMain_OnClose()
			-- end
			JinLiMain_Reset()
			JinLiMain_Frame_On_ResetPos()
			this:Show()
			JinLiMain_ParamInit()
			JinLiMain_MoneyUpdate()
			JinLiMain_Update(1)
			
		elseif 2 == nOpType then
			-- 刷新界面
			if this:IsVisible() then
				JinLiMain_ParamInit()
				JinLiMain_Update(0)
			end
		end
    
    elseif ( event == "CLOSE_JINLI_UI" ) and this:IsVisible() then
        JinLiMain_OnClose()
	
	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			JinLiMain_OnClose()
		end	
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		JinLiMain_OnClose()
	
	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
	-- elseif event == "MONEYJZ_CHANGE_EX" then
		JinLiMain_MoneyUpdate()
	
	elseif (event == "ADJEST_UI_POS" ) then
		JinLiMain_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JinLiMain_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function JinLiMain_ParamInit()
	g_nCurDayServer 		= tonumber(arg1)
	-- g_nDayStart 			= tonumber(arg2)
	g_bIsUseYueBing 		= tonumber(arg3)
	g_bFinishBangHuiLucky 	= tonumber(arg4)

	-- PushDebugMessage("JinLiMain_ParamInit".."g_nCurDayServer"..g_nCurDayServer.."g_nDayStart"..g_nDayStart.."g_bIsUseYueBing"..g_bIsUseYueBing.."g_bFinishBangHuiLucky"..g_bFinishBangHuiLucky )
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =JinLiMain
function JinLiMain_Update(bOpen)
	-- PushDebugMessage("JinLiMain_Update"..JinLiMain_GetHuoDongStep())
	
	if 0 == JinLiMain_GetHuoDongStep() then
		JinLiMain_OnClose()
	end

	AskServerTimeAgain()

	-- 标题和蒙版切换
	JinLiMain_DragTitleBK 	: Hide()
	JinLiMain_DragTitle1BK 	: Hide()
	JinLiMain_FrameBK 		: Hide()
	JinLiMain_Frame1BK 		: Hide()

	JinLiMain_FirstStageBK 	: Hide()
	JinLiMain_SecondStageBK : Hide()

	-- 抽锦鲤阶段
	if 1 == JinLiMain_GetHuoDongStep() then
		-- 蒙版1数据填充
		JinLiMain_DragTitleBK 	: Show()
		JinLiMain_FrameBK 		: Show()
		JinLiMain_FirstStageBK 	: Show()

		-- local nDayIndex = g_nCurDayServer - g_nDayStart + 1
		local nDayIndex = JinLiMain_GetDayIndex(1, g_nCurDayServer)

		for i = 1, g_nMaxJinLiNum do
			-- 光
			if i <= nDayIndex then
				g_controlStep1Light[i] : Show()
			else
				g_controlStep1Light[i] : Hide()
			end

			-- 兔子和锦鲤名字
			-- PushDebugMessage("DataPool:Lua_GetJinLiInfoByIndex(i)"..i)
			local bRet, bSet, nSelfGUIDH, nSelfGUIDL, nValue4, strPlayerName, strGuildName = DataPool:Lua_GetJinLiInfoByIndex(i)

			if nil ~= bRet and 1 == bRet and 1 == bSet then
				-- 有这个锦鲤
				g_controlStep1Rabbit[i] : Show()
				g_controlStep1NoRabbit[i] : Hide()
				g_controlStep1JinLiName[i] : SetText(ScriptGlobal_Format("#{ZQJL_190725_273}", strPlayerName))
			else
				-- 没有这个锦鲤
				g_controlStep1Rabbit[i] : Hide()
				g_controlStep1NoRabbit[i] : Show()
				-- g_controlStep1JinLiName[i] : SetText("#{ZQJL_190725_272}")
				g_controlStep1JinLiName[i] : SetText(g_tabStrDicOpenTime[i])

				local nServerMinuteTime = tonumber(DataPool:GetServerMinuteTime())
				
				-- 特殊处理过期和今天
				if nDayIndex == i and nServerMinuteTime <= g_TimeJinLiStart then
					-- ZQJL_190725_304	#L今日21时选出
					g_controlStep1JinLiName[i] : SetText("#{ZQJL_190725_304}")
				end

				if (nDayIndex > i) or (nDayIndex == i and nServerMinuteTime > g_TimeJinLiStart) then
					-- ZQJL_190725_305	#L无人当选
					g_controlStep1JinLiName[i] : SetText("#{ZQJL_190725_305}")
				end
			end
			
		end
	end

	-- 传递锦鲤、领奖阶段
	if 2 == JinLiMain_GetHuoDongStep() or 3 == JinLiMain_GetHuoDongStep() then
		-- 蒙版2数据填充
		JinLiMain_DragTitle1BK 	: Show()
		JinLiMain_Frame1BK 		: Show()
		JinLiMain_SecondStageBK : Show()

		-- local nDayIndex = g_nCurDayServer - g_nMaxJinLiNum - g_nDayStart + 1
		-- 返回0 表示处于第三阶段
		local nDayIndex = JinLiMain_GetDayIndex(2, g_nCurDayServer)

		for i = 1, g_nMaxJinLiNum do
			-- 光 今日开奖
			if i == nDayIndex then
				g_controlStep2Light[i] : Show()
				g_controlStep2TodayOpen[i] : Show()
			else
				g_controlStep2Light[i] : Hide()
				g_controlStep2TodayOpen[i] : Hide()
			end

			-- 隐藏所有状态控制控件
			g_controlStep2Rabbit[i] : Hide()
			g_controlStep2NoRabbit[i] : Hide()
			g_controlStep2BoxWithRabbit[i] : Hide()
			g_controlStep2YKJ[i] : Hide()
			g_controlStep2NULL[i] : Hide()
		
			local bRet, bSet, nSelfGUIDH, nSelfGUIDL, nValue4, strPlayerName, strGuildName = DataPool:Lua_GetJinLiInfoByIndex(i)

			local bRet2, bSet2, nSelfGUIDH2, nSelfGUIDL2, nValue42, strPlayerName2, strGuildName2 = DataPool:Lua_GetJinLiInfoByIndex(i + g_nMaxJinLiNum)

			local bRet3, bSet3, nSelfGUIDH3, nSelfGUIDL3, nValue43, strPlayerName3, strGuildName3 = DataPool:Lua_GetJinLiInfoByIndex(i + g_nMaxJinLiNum * 2)

			local bRet4, bSet4, nSelfGUIDH4, nSelfGUIDL4, nValue44, strPlayerName4, strGuildName4 = DataPool:Lua_GetJinLiInfoByIndex(i + g_nMaxJinLiNum * 3)

			-- 兔子和锦鲤名字，开奖信息
			if nil ~= bRet and 1 == bRet and 1 == bSet then
				-- 有这个锦鲤
				g_controlStep2Rabbit[i] : Show()
				g_controlStep2JinLiName[i] : SetText(ScriptGlobal_Format("#{ZQJL_190725_273}", strPlayerName))

				-- 判断全服锦鲤传递是否已经完成
				if nil ~= bRet2 and 1 == bRet2 and 1 == bSet2 then
					-- 显示已开奖
					g_controlStep2YKJ[i] : Show()
					-- 特殊处理今日开奖控件
					g_controlStep2TodayOpen[i] : Hide()
				else
					-- 显示宝箱
					g_controlStep2BoxWithRabbit[i] : Show()
					g_controlStep2Rabbit[i] : Hide()
				end
			else
				-- 没有这个锦鲤
				g_controlStep2NoRabbit[i] : Show()
				g_controlStep2JinLiName[i] : SetText("#{ZQJL_190725_272}")
				-- 显示暂无图片
				-- g_controlStep2NULL[i] : Show()
			end

			-- -- 底部中奖名单 全服
			-- if nil ~= bRet2 and 1 == bRet2 and 1 == bSet2 then
			-- 	g_controlStep2Lucky2Name[i] : SetText(ScriptGlobal_Format("#{ZQJL_190725_218}", strPlayerName2))
			-- elseif nDayIndex > i or 0 == nDayIndex then 
			-- 	-- 开奖时间过了，但是锦鲤没来
			-- 	g_controlStep2Lucky2Name[i] : SetText("#{ZQJL_190725_196}")
			-- else
			-- 	g_controlStep2Lucky2Name[i] : SetText("#{ZQJL_190725_195}")			
			-- end
			
			-- -- 底部中奖名单 帮会
			-- if nil ~= bRet3 and 1 == bRet3 and 1 == bSet3 then
			-- 	g_controlStep2Lucky3T1[i] : SetText(ScriptGlobal_Format("#{ZQJL_190725_203}", strGuildName3))
			-- 	g_controlStep2Lucky3T1[i] : SetProperty("HorzFormatting", "WordWrapLeftAligned")
			-- 	g_controlStep2Lucky3T2[i] : SetText(ScriptGlobal_Format("#{ZQJL_190725_218}", strPlayerName3))
			-- 	g_controlStep2Lucky3T2[i] : Show()
			-- elseif 1 == g_bFinishBangHuiLucky then 
			-- 	-- 开奖时间过了，但是锦鲤没来
			-- 	g_controlStep2Lucky3T1[i] : SetText("#{ZQJL_190725_196}")
			-- 	g_controlStep2Lucky3T1[i] : SetProperty("HorzFormatting", "WordWrapCentred")
			-- 	g_controlStep2Lucky3T2[i] : Hide()
			-- else
			-- 	g_controlStep2Lucky3T1[i] : SetText("#{ZQJL_190725_195}")		
			-- 	g_controlStep2Lucky3T1[i] : SetProperty("HorzFormatting", "WordWrapCentred")	
			-- 	g_controlStep2Lucky3T2[i] : Hide()
			-- end

			-- -- 底部中奖名单 好友
			-- if nil ~= bRet and 1 == bRet and 1 == bSet then
			-- 	g_controlStep2Lucky4T1[i] : SetText(ScriptGlobal_Format("#{ZQJL_190725_218}", strPlayerName))
			-- else
			-- 	g_controlStep2Lucky4T1[i] : SetText("#{ZQJL_190725_39}")		
			-- end
			-- if nil ~= bRet4 and 1 == bRet4 and 1 == bSet4 then
			-- 	g_controlStep2Lucky4T2[i] : SetText(ScriptGlobal_Format("#{ZQJL_190725_218}", strPlayerName4))
			-- else
			-- 	g_controlStep2Lucky4T2[i] : SetText("#{ZQJL_190725_204}")		
			-- end
			
		end

		-- -- 今日抽奖设置 全服
		-- JinLiMain_Frame1_Reward1_Text1 : Hide()
		-- JinLiMain_Frame1_Reward1_Text1_1 : Hide()
		-- JinLiMain_Frame1_Reward1_Step3Text : Hide()

		-- if 3 == JinLiMain_GetHuoDongStep() then
		-- 	JinLiMain_Frame1_Reward1_Step3Text : Show()
		-- else
		-- 	local bRetToday, bSetToday, nSelfGUIDHToday, nSelfGUIDLToday, nValue4Today, strPlayerNameToday, strGuildNameToday = DataPool:Lua_GetJinLiInfoByIndex(nDayIndex + g_nMaxJinLiNum)
		-- 	if nil ~= bRetToday and 1 == bRetToday and 1 == bSetToday then
		-- 		JinLiMain_Frame1_Reward1_Text1_1 : SetText(ScriptGlobal_Format("#{ZQJL_190725_218}", strPlayerNameToday))
		-- 	else
		-- 		JinLiMain_Frame1_Reward1_Text1_1 : SetText("#{ZQJL_190725_195}")
		-- 	end

		-- 	JinLiMain_Frame1_Reward1_Text1 : Show()
		-- 	JinLiMain_Frame1_Reward1_Text1_1 : Show()
		-- end

		-- 2020 新增 全服幸运儿 开奖按钮 和 开奖信息设置
		
		-- 默认开奖按钮隐藏红点
		JinLiMain_Frame1_LotteryButton_Tips : Hide()

		if 3 == JinLiMain_GetHuoDongStep() then
			-- ZQJL_190725_283	#L献礼已完成
			JinLiMain_Frame1_AllLucklyText : SetText("#{ZQJL_190725_283}")	
		elseif 2 == JinLiMain_GetHuoDongStep() then

			-- 返回0 表示处于第三阶段
			local nDayIndex = JinLiMain_GetDayIndex(2, g_nCurDayServer)

			-- x号锦鲤
			local bRet, bSet, nSelfGUIDH, nSelfGUIDL, nValue4, strPlayerName, strGuildName = DataPool:Lua_GetJinLiInfoByIndex(nDayIndex)

			-- PushDebugMessage("nDayIndex"..nDayIndex.."bRet"..bRet.."nSelfGUIDH"..nSelfGUIDH.."nSelfGUIDL"..nSelfGUIDL)
			-- x号全服幸运儿
			local bRetToday, bSetToday, nSelfGUIDHToday, nSelfGUIDLToday, nValue4Today, strPlayerNameToday, strGuildNameToday = DataPool:Lua_GetJinLiInfoByIndex(nDayIndex + g_nMaxJinLiNum)

			local strGUID = GetSelfGUID()
			local strJinLiGUID = ""
			local strLuckyGUID = ""
			if nil ~= bRet and 1 == bRet and 1 == bSet then
				strJinLiGUID = string.format("0X%08X%08X", nSelfGUIDH, nSelfGUIDL)
			end

			if nil ~= bRetToday and 1 == bRetToday and 1 == bSetToday then
				strLuckyGUID = string.format("0X%08X%08X", nSelfGUIDHToday, nSelfGUIDLToday)
			end

			local nServerMinuteTime = tonumber(DataPool:GetServerMinuteTime())

			if nil ~= bRetToday and 1 == bRetToday and 1 == bSetToday then
				if strLuckyGUID == strGUID then					
					JinLiMain_Frame1_AllLucklyText : SetText(ScriptGlobal_Format("#{ZQJL_190725_278}", strPlayerNameToday))
				else					
					JinLiMain_Frame1_AllLucklyText : SetText(ScriptGlobal_Format("#{ZQJL_190725_277}", strPlayerNameToday))
				end
			else
				-- 尚未选出 ZQJL_190725_279
				JinLiMain_Frame1_AllLucklyText : SetText("#{ZQJL_190725_279}")

				-- PushDebugMessage("nServerMinuteTime"..nServerMinuteTime)

				-- 当日锦鲤玩家，在全服开奖时间段内 触发按钮红点
				if nServerMinuteTime >= g_TimeQuanFuStart and nServerMinuteTime < g_TimeQuanFuEnd and strGUID == strJinLiGUID then	
					JinLiMain_Frame1_LotteryButton_Tips : Show()
				end
			end
		end
	
	end
	
end

--=========================================================
-- 获取活动的阶段 1 一阶段；2 二阶段；0 活动关闭
--=========================================================
function JinLiMain_GetHuoDongStep()

	if nil == g_nCurDayServer or g_nCurDayServer <= 0 then
		return 0 
	end

	if g_nCurDayServer >= g_TimeStart and g_nCurDayServer <= g_TimeStep1End then
		return 1
	end

	if g_nCurDayServer >= g_TimeStep2Start and g_nCurDayServer <= g_TimeEnd then
		return 2
	end

	if g_nCurDayServer >= g_RewardTimeStart and g_nCurDayServer <= g_RewardTimeEnd then
		return 3
	end

	return 0 
end

--**********************************
-- 辅助函数 获取当前是活动阶段x的第几天 返回0 非法
--**********************************
function JinLiMain_GetDayIndex(nStep, nDay)
	if nStep < 1 or nStep > 2 then
		return 0
	end

	local tableDay = g_tabTimeStep1
	if 2 == nStep then
		tableDay = g_tabTimeStep2
	end

	for i = 1, table.getn(tableDay) do
		if nDay == tableDay[i] then
			return i
		end
	end

	return 0
end

--=========================================================
--帮助按钮
--=========================================================
function JinLiMain_HelpClick(nParam)
	-- 借用一下别人的通道
	-- 一阶段主界面的问号
	if 1 == nParam then 
		PushEvent("CCSHOP_HELP", 71)
	end

	-- 二阶段主界面的问号
	if 2 == nParam then 
		PushEvent("CCSHOP_HELP", 72)
	end 

	-- 阶段一的右下角说明
	if 3 == nParam then 
		PushEvent("CCSHOP_HELP", 73)
	end 

	-- if 4 == nParam then 
	-- 	PushEvent("CCSHOP_HELP", 74)
	-- end 
	-- if 5 == nParam then 
	-- 	PushEvent("CCSHOP_HELP", 75)
	-- end 
end

--=========================================================
-- 重置界面
--=========================================================
function JinLiMain_Reset()

end

--=========================================================
-- 打开广告界面
--=========================================================
function JinLiMain_OnClickOpenRewardUIButton()
	if 1 == bOpenRewardShow then
		PushEvent("UI_COMMAND", 79002004, 1 )
	end
end

--=========================================================
-- 2020年新增的开奖按钮
--=========================================================
function JinLiMain_OnClickKaiJiangButton()

	-- 是否在传递活动时间内
	if 2 ~= JinLiMain_GetHuoDongStep() then
		PushDebugMessage("#{ZQJL_190725_285}")
		return
	end

	local strGUID = GetSelfGUID()

	local bJinLi = 0
	for i = 1, g_nMaxJinLiNum do
		local bRet, bSet, nSelfGUIDH, nSelfGUIDL, nValue4, strPlayerName, strGuildName = DataPool:Lua_GetJinLiInfoByIndex(i)
		-- 兔子和锦鲤名字，开奖信息
		if nil ~= bRet and 1 == bRet and 1 == bSet then
			local strJinLiGUID = string.format("0X%08X%08X", nSelfGUIDH, nSelfGUIDL)
			if strGUID == strJinLiGUID then
				bJinLi = 1
				break
			end
		end
	end

	-- 玩家是否是锦鲤玩家
	if 0 == bJinLi then
		PushDebugMessage("#{ZQJL_190725_286}")
		return
	end

	-- 返回0 表示处于第三阶段
	local nDayIndex = JinLiMain_GetDayIndex(2, g_nCurDayServer)

	-- x号锦鲤
	local bRet, bSet, nSelfGUIDH, nSelfGUIDL, nValue4, strPlayerName, strGuildName = DataPool:Lua_GetJinLiInfoByIndex(nDayIndex)
	-- x号全服幸运儿
	local bRetToday, bSetToday, nSelfGUIDHToday, nSelfGUIDLToday, nValue4Today, strPlayerNameToday, strGuildNameToday = DataPool:Lua_GetJinLiInfoByIndex(nDayIndex + g_nMaxJinLiNum)

	local strJinLiGUID = ""
	local strLuckyGUID = ""
	if nil ~= bRet and 1 == bRet and 1 == bSet then
		strJinLiGUID = string.format("0X%08X%08X", nSelfGUIDH, nSelfGUIDL)
	end

	if nil ~= bRetToday and 1 == bRetToday and 1 == bSetToday then
		strLuckyGUID = string.format("0X%08X%08X", nSelfGUIDHToday, nSelfGUIDLToday)
	end

	-- 玩家是否是当日锦鲤玩家
	if strGUID ~= strJinLiGUID then
		PushDebugMessage("#{ZQJL_190725_287}")
		return
	end

	-- 今天的全服幸运儿已经诞生了
	if nil ~= bRetToday and 1 == bRetToday and 1 == bSetToday then
		PushDebugMessage("#{ZQJL_190725_288}")
		return
	end

	-- 自动寻路并且关闭界面
	AutoRuntoTargetExWithName(g_infoNPCGoto[2].nPosX, g_infoNPCGoto[2].nPosY, g_infoNPCGoto[2].nSceneID, g_infoNPCGoto[2].strNPCName)

	PushDebugMessage("#{ZQJL_190725_289}")

	-- 关闭界面
	if this:IsVisible() then
		JinLiMain_OnClose()
	end
end

--=========================================================
-- 2020年新增的专门介绍用的对话框
--=========================================================
function JinLiMain_OnClickShowInfoButton(nParam)

	-- PushDebugMessage("JinLiMain_OnClickShowInfoButton"..nParam)

	PushEvent("UI_COMMAND", 79002006, nParam )
	
end

--=========================================================
-- 界面确认按钮
--=========================================================
function JinLiMain_ConfirmClick()

	-- 当前服务器时间是否处于活动时间内 当前服务器时间是否处于活动时间内//2019年9月5日至2019年9月11日24时
	if 1 ~= JinLiMain_GetHuoDongStep() then
		PushDebugMessage("#{ZQJL_190725_246}")
		return
	end

	-- 等级
	if Player:GetData( "LEVEL" ) < 30 then
		PushDebugMessage("#{ZQJL_190725_247}")
		return
	end

	-- 吃过月饼
	if 1 == g_bIsUseYueBing then
		PushDebugMessage("#{ZQJL_190725_30}")
		return
	end
	
	-- 自动寻路并且关闭界面
	AutoRuntoTargetExWithName(g_infoNPCGoto[1].nPosX, g_infoNPCGoto[1].nPosY, g_infoNPCGoto[1].nSceneID, g_infoNPCGoto[1].strNPCName)

	-- local nDayIndex = g_nCurDayServer - g_nDayStart + 1
	local nDayIndex = JinLiMain_GetDayIndex(1, g_nCurDayServer)

	local bRetToday, bSetToday, nSelfGUIDHToday, nSelfGUIDLToday, nValue4Today, strPlayerNameToday, strGuildNameToday = DataPool:Lua_GetJinLiInfoByIndex(nDayIndex)

	-- 今天的锦鲤被抽中了 额外给个提示
	if  nil ~= bRetToday and 1 == bRetToday and 1 == bSetToday then
		PushDebugMessage("#{ZQJL_190725_233}")
	end
	
    -- 关闭界面
    if this:IsVisible() then
        JinLiMain_OnClose()
	end
	
	-- Clear_XSCRIPT()
	-- 	Set_XSCRIPT_Function_Name( "OnUIEvent" )
	-- 	Set_XSCRIPT_ScriptID(060225)
	-- 	Set_XSCRIPT_Parameter(0, 2)					
	-- 	Set_XSCRIPT_Parameter(1, nPage)				
	-- 	Set_XSCRIPT_ParamCount(2)
	-- Send_XSCRIPT()
end

--=========================================================
-- 关闭界面
--=========================================================
function JinLiMain_OnClose()	
	this:Hide()
	StopCareObject_JinLiMain()
	-- 重置
	JinLiMain_Reset()
end

--=========================================================
-- 界面隐藏
--=========================================================
function JinLiMain_OnHiden()
	StopCareObject_JinLiMain()
	-- 重置
	JinLiMain_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_JinLiMain()
	-- 关心
	this:CareObject(g_objCared, 1, "JinLiMain")
end

function StopCareObject_JinLiMain()
	-- 取消关心
	if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "JinLiMain")
	end
	g_npcObjId = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function JinLiMain_MoneyUpdate()
end

--=========================================================
-- 界面位置
--=========================================================
function JinLiMain_Frame_On_ResetPos()
	JinLiMain_MainFrame:SetProperty("UnifiedPosition", g_JinLiMain_Frame_UnifiedPosition)
end