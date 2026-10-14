-- 2021Q3版本预热付费活动 繁光会宴

-- 保存UI默认位置
local CRWarmUp_Shop_UnifiedPosition = nil

-- 逻辑脚本id
local CRWarmUp_Shop_ServerScriptId = 888765
-- 二次确认的UICommand
local CRWarmUp_Shop_Confirm_UICommand = 2021091401
-- 高级奖池抽奖特效每个物品轮动间隔
local CRWarmUp_Shop_Senior_AwardAnimateInterval = 250
local CRWarmUp_Shop_Senior_AwardAnimateFinal = 1000
local CRWarmUp_Shop_Cooldown = 0 --手动刷新和购买物品的冷却标记
local CRWarmUp_Shop_Cooldown_Time = 0.5*1000	--0.5s按钮冷却
local CRWarmUp_Shop_BuyIndex = -1
local CRWarmUp_Shop_Preview_Cur = -1
local CRWarmUp_Shop_NextItemUpdateDate = -1
local CRWarmUp_Shop_NextAwardUpdateDate = -1
local CRWarmUp_Shop_SeniorAwardItemIndedx = -1
local CRWarmUp_Shop_SeniorAwardCurTick = -1
local CRWarmUp_Shop_SeniorAwardCurIndex = -1
local CRWarmUp_Shop_SeniorAwardItemCount = -1
local CRWarmUp_Shop_SeniorAwardItem = nil

-- 界面控件
local CRWarmUp_Shop_Junior_ctrlItemList = nil	-- 低级奖池物品控件列表
local CRWarmUp_Shop_Junior_ctrlAwardBtn = nil	-- 低级奖池领奖按钮控件
local CRWarmUp_Shop_Senior_ctrlItemList = nil	-- 高级奖池物品控件列表

-- 物品类型
local CRWarmUp_Shop_ItemTypeInfo =
{
	-- 元宝
	[1] = {type = 1, dict = "#{XMPYRFF_210826_17}"},
	-- 绑元
	[2] = {type = 2, dict = "#{XMPYRFF_210826_19}"},
	-- 金币
	[3] = {type = 3, dict = "#{XMPYRFF_210826_18}"},
	-- 新代币
	[4] = {type = 4, dict = ""},
} -- end CRWarmUp_Shop_ItemTypeInfo

-- 奖励领奖状态
local CRWarmUp_Shop_MaxBuyTimes = 70			-- 每周最大购买次数
-- 每档奖励需要的购买计数
local CRWarmUp_Shop_AwardStage =
{
	--看起来这里只起到档位数量提示的作用，dict没有被调用
	[1] = {buytimes = 10, dict = "#{XMPYRFF_210826_20}"},
	[2] = {buytimes = 20, dict = "#{XMPYRFF_210826_21}"},
	[3] = {buytimes = 30, dict = "#{XMPYRFF_210826_20}"},
	[4] = {buytimes = 40, dict = "#{XMPYRFF_210826_21}"},
	[5] = {buytimes = 50, dict = "#{XMPYRFF_210826_20}"},
	[6] = {buytimes = 70, dict = "#{XMPYRFF_210826_20}"},
} -- end CRWarmUp_Shop_AwardStage

-- 抽奖需要消耗的代币数量
local CRWarmUp_Shop_RaffleCost = 2

local CRWarmUp_Shop_AwardState =
{
	null = 0,           -- 无奖励
	has = 1,            -- 有奖励 未领取
	got = 2,            -- 有奖励 已领取
} -- end CRWarmUp_Shop_AwardState

-- 活动奖池物品列表
local CRWarmUp_Shop_JuniorItemList =
{
    -- {type：类型（元宝:1、绑元:2、金币:3），id：物品id，view：展示道具id，price：价格，discount：折扣（仅供UI显示使用），num：一次购买数量，maxnum：限购数量（小于零表示不限购），
    --  weighted：随机权重, mat：材料栏数量，propt:装备栏数量}
    -- 元宝物品	
	[1] = {type = 1, id = 20310168, view = 39920085, price = 945, discount = 9, num = 30, maxnum = -1, weighted = 1000, preview = -1, mat = 1, propt = 0},      -- 金蚕丝
    [2] = {type = 1, id = 20310168, view = 39920085, price = 840, discount = 8, num = 30, maxnum = -1, weighted = 400, preview = -1, mat = 1, propt = 0},      -- 金蚕丝
    [3] = {type = 1, id = 20310168, view = 39920085, price = 735, discount = 7, num = 30, maxnum = -1, weighted = 100, preview = -1, mat = 1, propt = 0},      -- 金蚕丝
    [4] = {type = 1, id = 38001554, view = 39920382, price = 1020, discount = 7.5, num = 2, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},    -- 天罡强化露
    [5] = {type = 1, id = 38000946, view = 39920940, price = 950, discount = 9.5, num = 1, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},     -- 苍鹤药魂
    [6] = {type = 1, id = 38000946, view = 39920940, price = 900, discount = 9, num = 1, maxnum = -1, weighted = 400, preview = -1, mat = 0, propt = 1},       -- 苍鹤药魂
    [7] = {type = 1, id = 38000946, view = 39920940, price = 850, discount = 8.5, num = 1, maxnum = -1, weighted = 400, preview = -1, mat = 0, propt = 1},     -- 苍鹤药魂
    [8] = {type = 1, id = 38004877, view = 39922767, price = 1440, discount = 9, num = 2, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},      -- 四绘券
    [9] = {type = 1, id = 38004805, view = 39922685, price = 1080, discount = 9, num = 40, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},     -- 精品礼物兑换券
    [10] = {type = 1, id = 38000571, view = 39920329, price = 950, discount = 9.5, num = 5, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},   -- 至尊强化精华
    [11] = {type = 1, id = 38000571, view = 39920329, price = 850, discount = 8.5, num = 5, maxnum = -1, weighted = 400, preview = -1, mat = 0, propt = 1},    -- 至尊强化精华
    [12] = {type = 1, id = 38000571, view = 39920329, price = 750, discount = 7.5, num = 5, maxnum = -1, weighted = 100, preview = -1, mat = 0, propt = 1},    -- 至尊强化精华
    [13] = {type = 1, id = 38004160, view = 39922158, price = 1080, discount = 9, num = 20, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},    -- 珍品礼物：大红袍
    [14] = {type = 1, id = 38004161, view = 39922663, price = 1080, discount = 9, num = 20, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},    -- 珍品礼物：太湖银鱼
    [15] = {type = 1, id = 38004157, view = 39922202, price = 1080, discount = 9, num = 20, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},    -- 珍品礼物：冰素针
    [16] = {type = 1, id = 38004156, view = 39922201, price = 1080, discount = 9, num = 20, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},    -- 珍品礼物：山水图
    [17] = {type = 1, id = 38004155, view = 39922200, price = 1080, discount = 9, num = 20, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},    -- 珍品礼物：十样花罗
    [18] = {type = 1, id = 38004154, view = 39922199, price = 1080, discount = 9, num = 20, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},    -- 珍品礼物：上等马驹
    [19] = {type = 1, id = 38004617, view = 39922648, price = 1620, discount = 9, num = 10, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},    -- 神品礼物：朱砂印尼
	[20] = {type = 1, id = 38004158, view = 39922205, price = 1080, discount = 9, num = 20, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},    -- 焦尾琴
    [21] = {type = 1, id = 38004159, view = 39922662, price = 1080, discount = 9, num = 20, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},    -- 多宝塔碑帖
    [22] = {type = 1, id = 38004148, view = 39922673, price = 1620, discount = 9, num = 10, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},    -- 青玉佩
    --2026年新加物品 珍品礼物兑换券
	[23] = {type = 1, id = 38004734, view = 39922686, price = 1200, discount = -1, num = 20, maxnum = -1, weighted = 110, preview = -1, mat = 0, propt = 1},    -- 珍品礼物兑换券
	[24] = {type = 1, id = 10102927, view = 39923962, price = 10000, discount = -1, num = 1, maxnum = -1, weighted = 50, preview = -1, mat = 0, propt = 1},    -- 武器：落韵摇情（拾取绑定）
	[25] = {type = 1, id = 10102850, view = 39923594, price = 10000, discount = -1, num = 1, maxnum = -1, weighted = 50, preview = -1, mat = 0, propt = 1},    -- 武器：踏风月（拾取绑定）
	-- 绑元物品
    [26] = {type = 2, id = 20800033, view = 39920946, price = 1005, discount = 8.7, num = 35, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1}, -- 九天玉碎
    [27] = {type = 2, id = 38004877, view = 39922767, price = 1520, discount = 9.5, num = 2, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},  -- 四绘券
    [28] = {type = 2, id = 38004804, view = 39922684, price = 1140, discount = 9.5, num = 80, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1}, -- 良品礼物兑换券
    [29] = {type = 2, id = 38004805, view = 39922685, price = 1140, discount = 9.5, num = 40, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1}, -- 精品礼物兑换券
    [30] = {type = 2, id = 20310168, view = 39920085, price = 987, discount = 9.4, num = 30, maxnum = -1, weighted = 1000, preview = -1, mat = 1, propt = 0},  -- 金蚕丝
    [31] = {type = 2, id = 38000443, view = 39920311, price = 765, discount = 7.5, num = 5, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},   -- 幻魂丹
    [32] = {type = 2, id = 38001595, view = 39921051, price = 750, discount = 7.5, num = 10, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},  -- 缀梦灵石
    [33] = {type = 2, id = 38000992, view = 39920490, price = 810, discount = 7.5, num = 6, maxnum = -1, weighted = 1000, preview = -1, mat = 0, propt = 1},   -- 虹耀石
    [34] = {type = 2, id = 20502015, view = 39921549, price = 828, discount = 6.9, num = 1, maxnum = -1, weighted = 1000, preview = -1, mat = 1, propt = 0},   -- 至尊秘银
    [35] = {type = 2, id = 20501009, view = 39921547, price = 828, discount = 6.9, num = 1, maxnum = -1, weighted = 1000, preview = -1, mat = 1, propt = 0},   -- 至尊棉布
    -- 金币物品
    [36] = {type = 3, id = 38000443, view = 39920311, price = 2000, discount = -1, num = 1, maxnum = -1, weighted = 500, preview = -1, mat = 0, propt = 1},      -- 幻魂丹
    [37] = {type = 3, id = 38001595, view = 39921051, price = 2000, discount = -1, num = 2, maxnum = -1, weighted = 500, preview = -1, mat = 0, propt = 1},      -- 缀梦灵石
    [38] = {type = 3, id = 38000992, view = 39920490, price = 2000, discount = -1, num = 1, maxnum = -1, weighted = 500, preview = -1, mat = 0, propt = 1},      -- 虹耀石
} -- end CRWarmUp_Shop_JuniorItemList

-- 高级奖池物品
local CRWarmUp_Shop_SeniorItemList =
{
    [1] = {id = 10102850, view = 39923594, num = 1, mat = 0, propt = 1, weighted = 1},      -- 新幻武：夜色
    [2] = {id = 50331009, view = 39921490, num = 1, mat = 1, propt = 0, weighted = 3},      -- 时装宝石：碎钻星辰（3级，拾取绑定）
	[3] = {id = 38004355, view = 39922174, num = 5, mat = 0, propt = 1, weighted = 40},     -- 醒志酒
	[4] = {id = 50413004, view = 39920463, num = 1, mat = 1, propt = 0, weighted = 16},     -- 4级红宝石
    [5] = {id = 20502004, view = 39920566, num = 1, mat = 1, propt = 0, weighted = 20},     -- 4级秘银
    [6] = {id = 20501004, view = 39920565, num = 1, mat = 1, propt = 0, weighted = 20},     -- 4级棉布
} -- end CRWarmUp_Shop_SeniorItemList



function CRWarmUp_Shop_PreLoad()
	this:RegisterEvent("FGHY_UI_OPENJUNIOR", true)
	this:RegisterEvent("FGHY_UI_JUNIORBUYCONFIRM", true)
	this:RegisterEvent("FGHY_UI_CLOSE", true)
	this:RegisterEvent("FGHY_DATA_JUNIORUPDATEITEM", true)
	this:RegisterEvent("FGHY_DATA_JUNIORUPDATEAWARD", true)
	this:RegisterEvent("FGHY_DATA_JUNIORUPDATERESERVEDAWARD", true)
	this:RegisterEvent("FGHY_DATA_DAIBI", true)
	this:RegisterEvent("FGHY_DATA_UPDATESENIOR", true)
	this:RegisterEvent("FGHY_DATA_SENIORAWARD", true)
	this:RegisterEvent("FGHY_DATA_TODAYBUYTIMES", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func CRWarmUp_Shop_PreLoad()

function CRWarmUp_Shop_OnEvent(event)
	if (event == "FGHY_UI_OPENJUNIOR") then
		-- 同时打开背包
		-- 开背包放到服务器发消息开启吧 放这里的话会先开启本活动UI 后开启背包UI 背包UI盖在活动UI上面了
		--CRWarmUp_Shop_OpenPacket()

		CRWarmUp_Shop_NextItemUpdateDate = tonumber(arg1)
		CRWarmUp_Shop_NextAwardUpdateDate = tonumber(arg2)
		-- 开启UI
		CRWarmUp_Shop_OpenJunior(tonumber(arg0), CRWarmUp_Shop_NextItemUpdateDate, CRWarmUp_Shop_NextAwardUpdateDate)
		-- 更新小红点
		CRWarmUp_Shop_UpdateRedPointTips()
	elseif (event == "FGHY_UI_JUNIORBUYCONFIRM") then
		-- 开启低级奖池购买物品二次确认
		--CRWarmUp_Shop_OpenItemConfirm(tonumber(arg0), tonumber(arg1), tonumber(arg2), tonumber(arg3), tonumber(arg4))
	elseif (event == "FGHY_UI_CLOSE") then
		-- 关闭UI
		CRWarmUp_Shop_Hide()
	elseif (event == "FGHY_DATA_JUNIORUPDATEITEM") then
		-- 更新低级奖池
		CRWarmUp_Shop_NextItemUpdateDate = tonumber(arg0)
		CRWarmUp_Shop_NextAwardUpdateDate = tonumber(arg1)
		CRWarmUp_Shop_Junior_UpdateItem(CRWarmUp_Shop_NextItemUpdateDate)
		CRWarmUp_Shop_Junior_UpdateAward(CRWarmUp_Shop_NextAwardUpdateDate)
		CRWarmUp_Shop_Junior_UpdateReservedAward()
		-- 更新小红点
		CRWarmUp_Shop_UpdateRedPointTips()
	elseif (event == "FGHY_DATA_JUNIORUPDATEAWARD") then
		-- 更新低级奖池奖励信息
		CRWarmUp_Shop_NextAwardUpdateDate = tonumber(arg0)
		CRWarmUp_Shop_Junior_UpdateAward(CRWarmUp_Shop_NextAwardUpdateDate)
		CRWarmUp_Shop_Junior_UpdateReservedAward()
		-- 更新小红点
		CRWarmUp_Shop_UpdateRedPointTips()
	elseif (event == "FGHY_DATA_JUNIORUPDATERESERVEDAWARD") then
		-- 更新低级奖池补领奖励信息
		CRWarmUp_Shop_Junior_UpdateReservedAward()
		-- 更新小红点
		CRWarmUp_Shop_UpdateRedPointTips()
	elseif (event == "FGHY_DATA_DAIBI") then
		-- 代币
		CRWarmUp_Shop_UpdateDaiBi()
		-- 更新小红点
		CRWarmUp_Shop_UpdateRedPointTips()
	elseif (event == "FGHY_DATA_UPDATESENIOR") then
		-- 更新高级奖池
		CRWarmUp_Shop_Senior_UpdateItem()
		CRWarmUp_Shop_UpdateDaiBi()
		-- 更新小红点
		CRWarmUp_Shop_UpdateRedPointTips()
	elseif (event == "FGHY_DATA_SENIORAWARD") then
		-- 高级奖池抽奖结果
		-- 开始抽奖动画效果
		CRWarmUp_Shop_SeniorAwardItemIndedx = -1
		CRWarmUp_Shop_Senior_AwardAnimate_Start(tonumber(arg0))
	elseif (event == "FGHY_DATA_TODAYBUYTIMES") then
		CRWarmUp_Shop_UpdateTodayBuyTimesAndAvailableRefreshCount(tonumber(arg0), tonumber(arg1))
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		CRWarmUp_Shop_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		CRWarmUp_Shop_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		CRWarmUp_Shop_UnifiedPos()
	end
end -- end func CRWarmUp_Shop_OnEvent()

function CRWarmUp_Shop_OnLoad()
	CRWarmUp_Shop_InitCtrl()
	CRWarmUp_Shop_UnifiedPosition = CRWarmUp_Shop_Frame:GetProperty("UnifiedPosition")
end -- end func CRWarmUp_Shop_OnLoad()

-- 界面默认位置
function CRWarmUp_Shop_UnifiedPos()
	if (CRWarmUp_Shop_UnifiedPosition ~= nil) then
		CRWarmUp_Shop_Frame:SetProperty("UnifiedPosition", CRWarmUp_Shop_UnifiedPosition)
	end
end -- end func CRWarmUp_Shop_UnifiedPos()

-- 开启UI
function CRWarmUp_Shop_Show()
	this:Show()
end -- end func CRWarmUp_Shop_Show()

-- 关闭UI
function CRWarmUp_Shop_Hide()
	this:Hide()

	-- 关闭二次确认框
	--PushEvent("MESSAGE_BOX_SELF3_CLOSE")
	PushEvent("UI_COMMAND", 2021092901)
end -- end func CRWarmUp_Shop_Hide()

-- 关闭按钮事件
function CRWarmUp_Shop_Close()
	CRWarmUp_Shop_Hide()

	PushEvent("FGHY_UI_CLOSEPREVIEW")
end -- end func CRWarmUp_Shop_Close()

-- 页签按钮事件
function CRWarmUp_Shop_Page_Clicked(param)
	if (param == 1) then
		-- 低级奖池
		CRWarmUp_Shop_OpenJunior(0, CRWarmUp_Shop_NextItemUpdateDate, CRWarmUp_Shop_NextAwardUpdateDate)
	elseif (param == 2) then
		-- 高级奖池
		CRWarmUp_Shop_OpenSenior(0, CRWarmUp_Shop_NextItemUpdateDate, CRWarmUp_Shop_NextAwardUpdateDate)
	end
end -- end func CRWarmUp_Shop_Page_Clicked()

-- 预览按钮事件
function CRWarmUp_Shop_BoxPreview()
	PushEvent("FGHY_UI_OPENPREVIEW")
end -- end func CRWarmUp_Shop_BoxPreview()

-- 预览界面 元宝、绑元、交子按钮
function CRWarmUp_Shop_CheckClick(param)
	local moneyType = 0
	if (param == 1) then
		moneyType = CRWarmUp_Shop_ItemTypeInfo[1].type
		if (CRWarmUp_Shop_Preview_Cur == moneyType) then
			return
		end

		CRWarmUp_Shop_CheckBtn1:SetCheck(1)
		CRWarmUp_Shop_CheckBtn2:SetCheck(0)
		CRWarmUp_Shop_CheckBtn3:SetCheck(0)
	elseif (param == 2) then
		moneyType = CRWarmUp_Shop_ItemTypeInfo[2].type
		if (CRWarmUp_Shop_Preview_Cur == moneyType) then
			return
		end

		CRWarmUp_Shop_CheckBtn1:SetCheck(0)
		CRWarmUp_Shop_CheckBtn2:SetCheck(1)
		CRWarmUp_Shop_CheckBtn3:SetCheck(0)
	elseif (param == 3) then
		moneyType = CRWarmUp_Shop_ItemTypeInfo[3].type
		if (CRWarmUp_Shop_Preview_Cur == moneyType) then
			return
		end

		CRWarmUp_Shop_CheckBtn1:SetCheck(0)
		CRWarmUp_Shop_CheckBtn2:SetCheck(0)
		CRWarmUp_Shop_CheckBtn3:SetCheck(1)
	else
		return
	end

	if (moneyType == 0) then
		return
	end

	CRWarmUp_Shop_Junior_UpdatePreview(moneyType)
end -- end func CRWarmUp_Shop_CheckClick()

-- -- 预览关闭按钮事件
-- function CRWarmUp_Shop_BoxAll_Close()
-- 	CRWarmUp_Shop_OpenJunior(0, CRWarmUp_Shop_NextItemUpdateDate, CRWarmUp_Shop_NextAwardUpdateDate)
-- end -- end func CRWarmUp_Shop_BoxAll_Close()

-- 补领按钮事件
-- 202203重开 取消补领
-- function CRWarmUp_Shop_Replacement()
-- 	Clear_XSCRIPT()
-- 		Set_XSCRIPT_Function_Name("Junior_GetReservedAward")
-- 		Set_XSCRIPT_ScriptID(CRWarmUp_Shop_ServerScriptId)
-- 		Set_XSCRIPT_Parameter(0, 0)
-- 		Set_XSCRIPT_ParamCount(1)
-- 	Send_XSCRIPT()
-- end -- end func CRWarmUp_Shop_Replacement()

-- 帮助问号
function CRWarmUp_Shop_Description_Help()
	PushEvent("CCSHOP_HELP", 134)
end -- end func CRWarmUp_Shop_Description_Help()

-- 低级奖池物品图标购买按钮事件
function CRWarmUp_Shop_Item_Click(index)
	if CRWarmUp_Shop_Cooldown == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Junior_BuyItem")
			Set_XSCRIPT_ScriptID(CRWarmUp_Shop_ServerScriptId)
			Set_XSCRIPT_Parameter(0, index)		-- 物品顺序（玩家买的是当前奖池中的第几个物品）
			Set_XSCRIPT_Parameter(1, 0)			-- 0：还未二次确认 1：二次确认过的
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		--设置冷却时间
		CRWarmUp_Shop_Cooldown = 1
		SetTimer("CRWarmUp_Shop", "CRWarmUp_Shop_Cooldown_Func()",CRWarmUp_Shop_Cooldown_Time)
	else
		PushDebugMessage("#{XMPYRFF_210826_144}")--您的操作过于频繁，请稍后再行尝试
	end
end -- end func CRWarmUp_Shop_Item_Click()

-- 开启低级奖池物品购买二次确认
-- 二次确认框换了 由服务器负责处理 这里不需要了
-- function CRWarmUp_Shop_OpenItemConfirm(index, itemIndex, yuanbao, bangyuan, money)
-- 	-- 获取物品信息
-- 	local itemInfo = CRWarmUp_Shop_JuniorItemList[itemIndex]
-- 	if (itemInfo == nil) then
-- 		return
-- 	end
-- 	-- 获取购买物品名称
-- 	local itemName = DataPool:Lua_GetItemNameByIndex(itemInfo.id)
-- 	-- 获取购买数量
-- 	local buyNum = itemInfo.num

-- 	local strMsg = ""
-- 	if (yuanbao <= 0 and bangyuan <= 0) then
-- 		if (money > 0) then
-- 			-- 只消耗金币（交子）
-- 			strMsg = ScriptGlobal_Format("#{XMPYRFF_210826_46}", money, CRWarmUp_Shop_ItemTypeInfo[3].dict, buyNum, itemName)
-- 		end
-- 	else
-- 		if (yuanbao > 0 and bangyuan > 0) then
-- 			-- 元宝和绑元都消耗
-- 			strMsg = ScriptGlobal_Format("#{XMPYRFF_210826_107}", yuanbao, bangyuan, buyNum, itemName)
-- 		elseif (yuanbao > 0 and bangyuan <= 0) then
-- 			-- 只消耗元宝
-- 			-- 只消耗元宝分两种情况： 一种是购买绑元物品 但是没有绑元 全部使用元宝抵用 另一种是购买元宝物品
-- 			if (bangyuan < 0) then
-- 				-- 购买元宝物品
-- 				strMsg = ScriptGlobal_Format("#{XMPYRFF_210826_46}", yuanbao, CRWarmUp_Shop_ItemTypeInfo[1].dict, buyNum, itemName)
-- 			else
-- 				-- 购买绑元物品
-- 				strMsg = ScriptGlobal_Format("#{XMPYRFF_210826_106}", yuanbao, buyNum, itemName)
-- 			end
-- 		elseif (yuanbao <= 0 and bangyuan > 0) then
-- 			-- 只消耗绑元
-- 			strMsg = ScriptGlobal_Format("#{XMPYRFF_210826_46}", bangyuan, CRWarmUp_Shop_ItemTypeInfo[2].dict, buyNum, itemName)
-- 		end
-- 	end

-- 	-- 开启二次确认框
-- 	CRWarmUp_Shop_BuyIndex = index
-- 	MessageBoxCommon("", strMsg, "CRWarmUp_Shop", "OnBtnConfirmOK()", "OnBtnBuyCancel()");
-- end -- end func CRWarmUp_Shop_Item_Confirm()

-- function CRWarmUp_Shop_OnBtnConfirmOK()
-- 	if (CRWarmUp_Shop_BuyIndex < 1) then
-- 		return
-- 	end

-- 	Clear_XSCRIPT()
-- 		Set_XSCRIPT_Function_Name("Junior_BuyItem")
-- 		Set_XSCRIPT_ScriptID(CRWarmUp_Shop_ServerScriptId)
-- 		Set_XSCRIPT_Parameter(0, CRWarmUp_Shop_BuyIndex)		-- 物品顺序（玩家买的是当前奖池中的第几个物品）
-- 		Set_XSCRIPT_Parameter(1, 1)								-- 0：还未二次确认 1：二次确认过的
-- 		Set_XSCRIPT_ParamCount(2)
-- 	Send_XSCRIPT()
-- end -- end func CRWarmUp_Shop_OnBtnConfirmOK()

-- function CRWarmUp_Shop_OnBtnBuyCancel()
-- 	CloseMessageBoxCommon()
-- end -- end func CRWarmUp_Shop_OnBtnBuyCancel()

-- 领奖图标按钮事件
function CRWarmUp_Shop_ProgressIcon_Click(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Junior_GetAward")
		Set_XSCRIPT_ScriptID(CRWarmUp_Shop_ServerScriptId)
		Set_XSCRIPT_Parameter(0, index)								-- 奖励等级
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func CRWarmUp_Shop_ProgressIcon_Click()

-- 物品预览按钮事件
function CRWarmUp_Shop_EyeSign(index)
end -- end func CRWarmUp_Shop_EyeSign()

-- 总奖池界面的物品预览按钮
function CRWarmUp_Shop_EyeSign_Preview(index)
end -- end func CRWarmUp_Shop_EyeSign_Preview()

-- 高级奖池物品点击按钮事件
function CRWarmUp_Shop_Lottery_Click(index)
end -- end func CRWarmUp_Shop_Lottery_Click()

-- 高级奖池抽奖按钮事件
function CRWarmUp_Shop_Raffle_Click(param)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Senior_GetAward")
		Set_XSCRIPT_ScriptID(CRWarmUp_Shop_ServerScriptId)
		Set_XSCRIPT_Parameter(0, param)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func CRWarmUp_Shop_Raffle_Click()

-- 手动刷新按钮事件
function CRWarmUp_Shop_But_Click()
	if CRWarmUp_Shop_Cooldown == 0 then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Junior_ManualRefresh")
		Set_XSCRIPT_ScriptID(CRWarmUp_Shop_ServerScriptId)
		Set_XSCRIPT_Parameter(0, 0)
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		--设置冷却时间
		CRWarmUp_Shop_Cooldown = 1
		SetTimer("CRWarmUp_Shop", "CRWarmUp_Shop_Cooldown_Func()",CRWarmUp_Shop_Cooldown_Time)
	else
		PushDebugMessage("#{XMPYRFF_210826_144}")--您的操作过于频繁，请稍后再行尝试
	end

end -- end func CRWarmUp_Shop_But_Click()

-- 打开低级奖池UI
function CRWarmUp_Shop_OpenJunior(isUpdate, nextItemUpdateDate, nextAwardUpdateDate)
	-- 开启UI
	CRWarmUp_Shop_Show()

	-- 关闭高级奖池以及奖池总览界面 打开低级奖池页面
	--CRWarmUp_Shop_BoxAll:Hide()
	CRWarmUp_Shop_Client2:Hide()
	CRWarmUp_Shop_Client1:Show()
	-- 设置页签按钮状态
	CRWarmUp_Shop_Buttontab01:SetCheck(1)
	CRWarmUp_Shop_Buttontab02:SetCheck(0)

	-- 更新低级奖池信息
	CRWarmUp_Shop_Junior_UpdateItem(nextItemUpdateDate)

	-- 更新低级奖池奖励领奖信息
	CRWarmUp_Shop_Junior_UpdateAward(nextAwardUpdateDate)
end -- end func CRWarmUp_Shop_OpenJunior()

-- 打开高级级奖池UI
function CRWarmUp_Shop_OpenSenior()
	-- 开启UI
	--CRWarmUp_Shop_Show()
	
	-- 关闭低级奖池以及奖池总览界面 打开搞级奖池页面
	--CRWarmUp_Shop_BoxAll:Hide()
	CRWarmUp_Shop_Client1:Hide()
	CRWarmUp_Shop_Client2:Show()
	-- 设置页签按钮状态
	CRWarmUp_Shop_Buttontab01:SetCheck(0)
	CRWarmUp_Shop_Buttontab02:SetCheck(1)

	-- 更新高级奖池奖励信息
	CRWarmUp_Shop_Senior_UpdateItem()
	-- 更新代币
	CRWarmUp_Shop_UpdateDaiBi()
end -- end func CRWarmUp_Shop_OpenSenior()

-- -- 打开预览UI
-- function CRWarmUp_Shop_OpenPreview()
-- 	-- 开启UI
-- 	--CRWarmUp_Shop_Show()

-- 	-- 关闭高级奖池以及低级奖池界面 打开预览界面
-- 	CRWarmUp_Shop_Client2:Hide()
-- 	CRWarmUp_Shop_Client1:Hide()
-- 	CRWarmUp_Shop_BoxAll:Show()
-- 	-- 设置页签按钮状态
-- 	CRWarmUp_Shop_Buttontab01:SetCheck(1)
-- 	CRWarmUp_Shop_Buttontab02:SetCheck(0)
	
-- 	-- 默认打开元宝物品预览
-- 	CRWarmUp_Shop_Preview_Cur = -1
-- 	local previewType = CRWarmUp_Shop_ItemTypeInfo[1].type
-- 	CRWarmUp_Shop_Junior_UpdatePreview(previewType)
-- end -- end func CRWarmUp_Shop_OpenPreview()

-- 打开背包
function CRWarmUp_Shop_OpenPacket()
	PushEvent("UI_COMMAND", 111011)
end -- end func CRWarmUp_Shop_OpenPacket()

-- 打开时装预览界面
function CRWarmUp_Shop_OpenDressPreview(index)
	local dressId = 0
	local hairId = Exterior:LuaFnGetExteriorInUse(4)
	local faceId = Exterior:LuaFnGetExteriorInUse(3)

	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, dressId)
		Set_XSCRIPT_Parameter(1, hairId)
		Set_XSCRIPT_Parameter(2, faceId)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end -- end func CRWarmUp_Shop_OpenDressPreview()

-- 更新低级奖池
function CRWarmUp_Shop_Junior_UpdateItem(nextUpdateDate)
	-- 设置下一次刷新奖池物品日期
	-- if (nextUpdateDate ~= nil and nextUpdateDate > 0) then
	-- 	local year, month, day = CRWarmUp_Shop_GetYearMonthDay(nextUpdateDate)
	-- 	local updateDateText = ScriptGlobal_Format("#{XMPYRFF_210826_11}", month, day)
	-- 	CRWarmUp_Shop_Countdown_Text:SetText(updateDateText)
	-- 	CRWarmUp_Shop_Countdown_Text:Show()
	-- else
	-- 	CRWarmUp_Shop_Countdown_Text:Hide()
	-- end

	-- 刷新物品列表
	if (CRWarmUp_Shop_Junior_ctrlItemList ~= nil) then
		CRWarmUp_Shop_BoxBK:Show()
		local itemListLen = table.getn(CRWarmUp_Shop_Junior_ctrlItemList)
		for i=1, itemListLen, 1 do
			local itemCtrl = CRWarmUp_Shop_Junior_ctrlItemList[i]
			local itemIndex = FanGuangHuiYan:GetItem_Cur(i-1)
			local itemGotCount = FanGuangHuiYan:GetItemGotCount_Cur(i-1)
			local itemInfo = CRWarmUp_Shop_JuniorItemList[itemIndex]
			if (itemCtrl ~= nil) then
				if (itemInfo ~= nil) then
					-- 创建展示道具
					local theAction = DataPool:CreateActionItemForShow(itemInfo.view, itemInfo.num)
					-- 设置展示道具
					itemCtrl.icon:SetActionItem(theAction:GetID())
					if (itemGotCount > 0) then
						-- 该物品本次刷新周期内已经买过了 不能再买
						itemCtrl.icon:Disable()
					else
						itemCtrl.icon:Enable()
					end
					-- 设置道具名称
					itemCtrl.name:SetText("#L" .. DataPool:Lua_GetItemNameByIndex(itemInfo.id))
					-- 设置物品价格
					local priceText = ""
					local moneyTypeInfo = CRWarmUp_Shop_ItemTypeInfo[itemInfo.type]
					if (moneyTypeInfo.type == CRWarmUp_Shop_ItemTypeInfo[3].type) then
						priceText = ScriptGlobal_Format("#{XMPYRFF_210826_126}", itemInfo.price)
					else
						priceText = ScriptGlobal_Format("#{XMPYRFF_210826_16}", moneyTypeInfo.dict, itemInfo.price)
					end
					itemCtrl.price:SetText(priceText)
					-- 设置折扣率
					if (itemInfo.discount > 0) then
						itemCtrl.discountbk:Show()
						itemCtrl.discount:Show()
						local discountText = ScriptGlobal_Format("#{XMPYRFF_210826_15}", itemInfo.discount)
						itemCtrl.discount:SetText(discountText)
					else
						itemCtrl.discount:Hide()
						itemCtrl.discountbk:Hide()
					end

					if (itemInfo.preview > 0) then
						itemCtrl.eyesign:Show()
					else
						itemCtrl.eyesign:Hide()
					end
				else
					-- 物品信息不对 没找到相关物品
					-- 那就啥也不显示吧
					itemCtrl.icon:SetActionItem(-1)
					itemCtrl.name:SetText("")
					itemCtrl.price:SetText("")
					itemCtrl.discount:SetText("")
					itemCtrl.eyesign:Hide()
				end
			end
		end -- end for
	end
end -- end func CRWarmUp_Shop_Junior_UpdateItem()

-- 更新低级奖池领奖信息
function CRWarmUp_Shop_Junior_UpdateAward(nextUpdateDate)
	-- 刷新领奖信息
	if (CRWarmUp_Shop_Junior_ctrlAwardBtn ~= nil) then
		for i=1, table.getn(CRWarmUp_Shop_AwardStage), 1 do
			if (CRWarmUp_Shop_Junior_ctrlAwardBtn[i] ~= nil) then
				-- 获取奖励状态
				local awardState = FanGuangHuiYan:GetCurWeekAwardState(i-1)
				if (awardState == CRWarmUp_Shop_AwardState.null) then
					-- 无奖励
					--CRWarmUp_Shop_Junior_ctrlAwardBtn[i].btn:Disable()
					CRWarmUp_Shop_Junior_ctrlAwardBtn[i].get:Hide()
				elseif (awardState == CRWarmUp_Shop_AwardState.has) then
					-- 有奖励 未领奖
					--CRWarmUp_Shop_Junior_ctrlAwardBtn[i].btn:Enable()
					CRWarmUp_Shop_Junior_ctrlAwardBtn[i].get:Hide()
				elseif (awardState == CRWarmUp_Shop_AwardState.got) then
					-- 有奖励 已领奖
					--CRWarmUp_Shop_Junior_ctrlAwardBtn[i].btn:Disable()
					CRWarmUp_Shop_Junior_ctrlAwardBtn[i].get:Show()
				else
					-- 按说不应该到这
				end
			end
		end -- end for
	end

	-- 设置领奖进度条
	-- 获取购买计数
	local buyTimes = FanGuangHuiYan:GetCurWeekBuyTimes()
	CRWarmUp_Shop_Progress:SetProgress(buyTimes, CRWarmUp_Shop_MaxBuyTimes)
	if (buyTimes > CRWarmUp_Shop_MaxBuyTimes) then
		buyTimes = CRWarmUp_Shop_MaxBuyTimes
	end
	local buyTimesText = ScriptGlobal_Format("#{XMPYRFF_210826_124}", buyTimes)
	CRWarmUp_Shop_Progress_Text:SetText(buyTimesText)

	-- -- 设置下一次刷新奖池物品日期
	-- if (nextUpdateDate ~= nil and nextUpdateDate > 0) then
	-- 	local year, month, day = CRWarmUp_Shop_GetYearMonthDay(nextUpdateDate)
	-- 	local updateDateText = ScriptGlobal_Format("#{XMPYRFF_210826_24}", month, day)
	-- 	CRWarmUp_Shop_ProgressCountdown_Text:SetText(updateDateText)
	-- 	CRWarmUp_Shop_ProgressCountdown_Text:Show()
	-- else
	-- 	CRWarmUp_Shop_ProgressCountdown_Text:Hide()
	-- end
end -- end func CRWarmUp_Shop_Junior_UpdateAward()

-- 更新奖励补领信息
function CRWarmUp_Shop_Junior_UpdateReservedAward()
end -- end func CRWarmUp_Shop_Junior_UpdateReservedAward

-- -- 更新预览物品
-- function CRWarmUp_Shop_Junior_UpdatePreview(moneyType)
-- 	CRWarmUp_Shop_BoxAll_SuperList:Clear()
-- 	local len = table.getn(CRWarmUp_Shop_JuniorItemList)
-- 	for i=1, len, 1 do
-- 		local itemInfo = CRWarmUp_Shop_JuniorItemList[i]
-- 		if (itemInfo ~= nil and itemInfo.type == moneyType) then
-- 			local itemCtrl = CRWarmUp_Shop_BoxAll_SuperList:AddChild("CRWarmUp_Shop_BoxAll_CoinAItem1")
-- 			if (itemCtrl ~= nil) then
-- 				-- 创建展示道具
-- 				local theAction = DataPool:CreateActionItemForShow(itemInfo.view, itemInfo.num)
-- 				-- 设置展示道具
-- 				itemCtrl:GetSubItem("CRWarmUp_Shop_SuperListItem"):SetActionItem(theAction:GetID())
-- 				-- 设置道具名称
-- 				itemCtrl:GetSubItem("CRWarmUp_Shop_SuperListItem_Acount"):SetText("#L" .. DataPool:Lua_GetItemNameByIndex(itemInfo.id))
-- 				-- 设置物品价格
-- 				local moneyTypeInfo = CRWarmUp_Shop_ItemTypeInfo[itemInfo.type]
-- 				local priceText = ScriptGlobal_Format("#{XMPYRFF_210826_16}", moneyTypeInfo.dict, itemInfo.price)
-- 				itemCtrl:GetSubItem("CRWarmUp_Shop_SuperListItem_Price"):SetText(priceText)
-- 				-- 设置折扣率
-- 				if (itemInfo.discount > 0) then
-- 					itemCtrl:GetSubItem("CRWarmUp_Shop_SuperListItem_DiscountBK"):Show()
-- 					itemCtrl:GetSubItem("CRWarmUp_Shop_SuperListItem_DiscountText"):Show()
-- 					local discountText = ScriptGlobal_Format("#{XMPYRFF_210826_15}", itemInfo.discount)
-- 					itemCtrl:GetSubItem("CRWarmUp_Shop_SuperListItem_DiscountText"):SetText(discountText)
-- 				else
-- 					itemCtrl:GetSubItem("CRWarmUp_Shop_SuperListItem_DiscountBK"):Hide()
-- 					itemCtrl:GetSubItem("CRWarmUp_Shop_SuperListItem_DiscountText"):Hide()
-- 				end

-- 				-- 设置预览按钮事件
-- 				if (itemInfo.preview > 0) then
-- 					itemCtrl:GetSubItem("CRWarmUp_Shop_SuperListItem_EyeSign"):Show()
-- 					itemCtrl:GetSubItem("CRWarmUp_Shop_SuperListItem_EyeSign"):SetEvent("Clicked", string.format("CRWarmUp_Shop_EyeSign_Preview(%d)", i))
-- 				else
-- 					itemCtrl:GetSubItem("CRWarmUp_Shop_SuperListItem_EyeSign"):Hide()
-- 				end
-- 			end
-- 		end
-- 	end -- end for

-- 	CRWarmUp_Shop_Preview_Cur = moneyType
-- end -- end func CRWarmUp_Shop_Junior_UpdatePreview()

-- 更新高级奖池奖励信息
function CRWarmUp_Shop_Senior_UpdateItem()
	-- 202203重开 取消高级奖池

	-- -- 刷新物品列表
	-- if (CRWarmUp_Shop_Senior_ctrlItemList ~= nil) then
	-- 	CRWarmUp_Shop_BoxBK:Show()
	-- 	local itemListLen = table.getn(CRWarmUp_Shop_SeniorItemList)
	-- 	for i=1, itemListLen, 1 do
	-- 		local ctrlInfo = CRWarmUp_Shop_Senior_ctrlItemList[i]
	-- 		local itemInfo = CRWarmUp_Shop_SeniorItemList[i]
	-- 		if (ctrlInfo ~= nil and itemInfo ~= nil) then
	-- 			-- 创建展示道具
	-- 			local theAction = DataPool:CreateActionItemForShow(itemInfo.view, itemInfo.num)
	-- 			-- 设置展示道具
	-- 			ctrlInfo.icon:SetActionItem(theAction:GetID())
	-- 			-- 设置道具名称
	-- 			ctrlInfo.name:SetText("#L" .. DataPool:Lua_GetItemNameByIndex(itemInfo.id))

	-- 			-- 获取当前物品已抽取的数量
	-- 			local gotCount = FanGuangHuiYan:GetSeniorItemGotCount(i-1)
	-- 			if (gotCount > 0) then
	-- 				-- 当前物品已被抽取过
	-- 				ctrlInfo.icon:Disable()
	-- 				ctrlInfo.get:Show()
	-- 			else
	-- 				-- 当前物品未被抽取过
	-- 				ctrlInfo.icon:Enable()
	-- 				ctrlInfo.get:Hide()
	-- 			end

	-- 			ctrlInfo.animate:Hide()
	-- 		end
	-- 	end -- end for
	-- end
end -- end func CRWarmUp_Shop_Senior_UpdateItem()

-- 开始高级奖池抽奖特效
function CRWarmUp_Shop_Senior_AwardAnimate_Start(itemIndex)
	-- 202203重开 取消高级奖池
	return -1

	-- if (itemIndex == nil or itemIndex <= 0) then
	-- 	return -1
	-- end

	-- KillTimer("CRWarmUp_Shop_Senior_AwardAnimate_HeartBeat()")
	-- KillTimer("CRWarmUp_Shop_Senior_AwardAnimate_Finish()")

	-- -- 开始之前刷新一下高级奖池和代币
	-- --CRWarmUp_Shop_Senior_UpdateItem()
	-- CRWarmUp_Shop_UpdateDaiBi()
	-- CRWarmUp_Shop_UpdateRedPointTips()

	-- -- 清一下每个物品的特效显示
	-- local itemListLen = table.getn(CRWarmUp_Shop_SeniorItemList)
	-- for i=1, itemListLen, 1 do
	-- 	local ctrlInfo = CRWarmUp_Shop_Senior_ctrlItemList[i]
	-- 	if (ctrlInfo ~= nil) then
	-- 		ctrlInfo.animate:Hide()
	-- 	end
	-- end -- end for

	-- CRWarmUp_Shop_SeniorAwardItemIndedx = itemIndex

	-- -- 整理可以抽奖的物品 剔除已经抽过的
	-- CRWarmUp_Shop_SeniorAwardItem = {}
	-- local itemCount = 0
	-- local itemListLen = table.getn(CRWarmUp_Shop_SeniorItemList)
	-- for i=1, itemListLen, 1 do
	-- 	local gotCount = FanGuangHuiYan:GetSeniorItemGotCount(i-1)
	-- 	if (gotCount <= 0 or i == itemIndex) then
	-- 		itemCount = itemCount + 1
	-- 		CRWarmUp_Shop_SeniorAwardItem[itemCount] = {}
	-- 		CRWarmUp_Shop_SeniorAwardItem[itemCount].index = i
	-- 	end
	-- end -- end for
	-- if (itemCount <= 0) then
	-- 	return -2
	-- end	

	-- if (itemCount == 1) then
	-- 	-- 只剩下一个 没必要在转圈了 直接给吧
	-- 	CRWarmUp_Shop_Senior_AwardAnimate_Finish()
	-- 	return
	-- end
	
	-- -- 开启第一个物品的转圈特效
	-- local beginIndex= CRWarmUp_Shop_SeniorAwardItem[1].index
	-- local ctrlInfo = CRWarmUp_Shop_Senior_ctrlItemList[CRWarmUp_Shop_SeniorAwardItem[1].index]
	-- if (ctrlInfo == nil) then
	-- 	return -3
	-- end
	-- ctrlInfo.animate:Show()

	-- CRWarmUp_Shop_SeniorAwardCurTick = 0
	-- CRWarmUp_Shop_SeniorAwardCurIndex = beginIndex
	-- CRWarmUp_Shop_SeniorAwardItemCount = itemCount

	-- -- 设置定时器
	-- SetTimer("CRWarmUp_Shop", "CRWarmUp_Shop_Senior_AwardAnimate_HeartBeat()", CRWarmUp_Shop_Senior_AwardAnimateInterval)
	-- return 1
end -- end func CRWarmUp_Shop_Senior_AwardAnimate_Start()

-- 高级奖池抽奖特效tick
function CRWarmUp_Shop_Senior_AwardAnimate_HeartBeat()
	-- 202203重开 取消高级奖池
	return -1

	-- KillTimer("CRWarmUp_Shop_Senior_AwardAnimate_HeartBeat()")
	-- if (CRWarmUp_Shop_SeniorAwardItemCount == nil or CRWarmUp_Shop_SeniorAwardItemCount <= 0) then
	-- 	return -1
	-- end
	-- if (CRWarmUp_Shop_SeniorAwardItemIndedx <= 0) then
	-- 	return -2
	-- end

	-- CRWarmUp_Shop_SeniorAwardCurTick = CRWarmUp_Shop_SeniorAwardCurTick + 1

	-- -- 关闭上一个物品的转圈特效
	-- local lastCtrlInfo = CRWarmUp_Shop_Senior_ctrlItemList[CRWarmUp_Shop_SeniorAwardCurIndex]
	-- if (lastCtrlInfo ~= nil) then
	-- 	lastCtrlInfo.animate:Hide()
	-- end

	-- -- 开启下一个物品的转圈特效
	-- local itemIndex = math.mod(CRWarmUp_Shop_SeniorAwardCurTick, CRWarmUp_Shop_SeniorAwardItemCount) + 1
	-- if (CRWarmUp_Shop_SeniorAwardItem[itemIndex] == nil) then
	-- 	return -3
	-- end
	-- local realIndex = CRWarmUp_Shop_SeniorAwardItem[itemIndex].index
	-- local curCtrlInfo = CRWarmUp_Shop_Senior_ctrlItemList[realIndex]
	-- if (curCtrlInfo ~= nil) then
	-- 	curCtrlInfo.animate:Show()
	-- end
	-- CRWarmUp_Shop_SeniorAwardCurIndex = realIndex

	-- if (CRWarmUp_Shop_SeniorAwardCurTick >= (CRWarmUp_Shop_SeniorAwardItemCount * 2 - 1)) then
	-- 	-- 转2圈以后判断是不是抽中的物品
	-- 	if (CRWarmUp_Shop_SeniorAwardCurIndex == CRWarmUp_Shop_SeniorAwardItemIndedx) then
	-- 		-- 当前转到的物品就是抽中的物品了
	-- 		SetTimer("CRWarmUp_Shop", "CRWarmUp_Shop_Senior_AwardAnimate_Finish()", CRWarmUp_Shop_Senior_AwardAnimateFinal)
	-- 		return 1
	-- 	end
	-- end

	-- -- 设置定时器
	-- SetTimer("CRWarmUp_Shop", "CRWarmUp_Shop_Senior_AwardAnimate_HeartBeat()", CRWarmUp_Shop_Senior_AwardAnimateInterval)
	-- return 1
end -- end func CRWarmUp_Shop_Senior_AwardAnimate_HeartBeat()

-- 结束高级奖池抽奖特效
function CRWarmUp_Shop_Senior_AwardAnimate_Finish()
	-- 202203重开 取消高级奖池
	return -1

	-- KillTimer("CRWarmUp_Shop_Senior_AwardAnimate_Finish()")
	-- -- 先刷新一下高级奖池和代币
	-- CRWarmUp_Shop_Senior_UpdateItem()
	-- CRWarmUp_Shop_UpdateDaiBi()
	-- CRWarmUp_Shop_UpdateRedPointTips()

	-- local itemInfo = CRWarmUp_Shop_SeniorItemList[CRWarmUp_Shop_SeniorAwardItemIndedx]
	-- if (itemInfo == nil) then
	-- 	return -1
	-- end

	-- -- 给个提示
	-- local tipMsg = ScriptGlobal_Format("#{XMPYRFF_210826_100}", itemInfo.num, DataPool:Lua_GetItemNameByIndex(itemInfo.id))
	-- PushDebugMessage(tipMsg)

	-- -- 清空可抽奖物品临时列表
	-- CRWarmUp_Shop_SeniorAwardItem = {}
	-- return 1
end -- end func CRWarmUp_Shop_Senior_AwardAnimate_Finish()

-- 更新代币信息
function CRWarmUp_Shop_UpdateDaiBi()
	-- 202203重开 取消代币

	-- -- 更新代币
	-- local curDaiBi = FanGuangHuiYan:GetDaiBi()
	-- local textMsg = ScriptGlobal_Format("#{XMPYRFF_210826_112}", curDaiBi)
	-- CRWarmUp_Shop_Lottery_Text2:SetText(textMsg)
end -- end func CRWarmUp_Shop_UpdateDaiBi()

-- 更新今日购买次数和可刷新次数
function CRWarmUp_Shop_UpdateTodayBuyTimesAndAvailableRefreshCount(buyTimes, refreshCount)
	local buyTimesStr = ScriptGlobal_Format("#{XMPYRFF_210826_133}", buyTimes)
	local refreshCountStr = ScriptGlobal_Format("#{XMPYRFF_210826_132}", refreshCount)

	CRWarmUp_Shop_Text:SetText(buyTimesStr)
	CRWarmUp_Shop_Text1:SetText(refreshCountStr)
end -- end func CRWarmUp_Shop_UpdateTodayBuyTimesAndAvailableRefreshCount()

-- 更新小红点
function CRWarmUp_Shop_UpdateRedPointTips()
	-- 是否显示低级奖池页签小红点
	local showJuniorRedPoint = 0
	-- 是否显示高级奖池页签小红点
	local showSeniorRedPoint = 0

	-- 低级奖池页面相关小红点
	local reservedCount = 0
	for i=1, table.getn(CRWarmUp_Shop_AwardStage), 1 do
		-- 领奖按钮小红点
		if (CRWarmUp_Shop_Junior_ctrlAwardBtn ~= nil) then
			if (CRWarmUp_Shop_Junior_ctrlAwardBtn[i] ~= nil) then
				-- 获取奖励状态
				local awardState = FanGuangHuiYan:GetCurWeekAwardState(i-1)
				if (awardState == CRWarmUp_Shop_AwardState.has) then
					-- 有奖励 未领奖
					-- 显示领奖按钮小红点
					CRWarmUp_Shop_Junior_ctrlAwardBtn[i].tips:Show()
					CRWarmUp_Shop_Junior_ctrlAwardBtn[i].get:Hide()

					showJuniorRedPoint = 1
				elseif (awardState == CRWarmUp_Shop_AwardState.null) then
					-- 无奖励
					CRWarmUp_Shop_Junior_ctrlAwardBtn[i].tips:Hide()
					CRWarmUp_Shop_Junior_ctrlAwardBtn[i].get:Hide()
				elseif (awardState == CRWarmUp_Shop_AwardState.got) then
					-- 有奖励已领取
					CRWarmUp_Shop_Junior_ctrlAwardBtn[i].tips:Hide()
					CRWarmUp_Shop_Junior_ctrlAwardBtn[i].get:Show()
				else
				end
			end
		end

		-- 补领按钮小红点
		-- 检查有没有补领奖励
		-- 202203重开 取消补领
		-- local curCount = FanGuangHuiYan:GetReservedAwardCount(i-1)
		-- if (curCount > 0) then
		-- 	reservedCount = reservedCount + 1
		-- end
	end -- end for

	-- 是否需要显示补领小红点
	-- 202203重开 取消补领
	-- if (reservedCount > 0) then
	-- 	-- 有补领奖励 显示补领小红点
	-- 	CRWarmUp_Shop_Replacement_Tips:Show()
	-- 	showJuniorRedPoint = 1
	-- else
	-- 	-- 没有补领奖励 不显示补领小红点
	-- 	CRWarmUp_Shop_Replacement_Tips:Hide()
	-- end

	-- 是否显示低级奖池页签小红点
	if (showJuniorRedPoint > 0) then
		-- 需要显示低级奖池页签小红点
		CRWarmUp_Shop_Buttontab01_Tips:Show()
	else
		-- 不需要显示低级奖池页签小红点
		CRWarmUp_Shop_Buttontab01_Tips:Hide()
	end

	-- 高级奖池相页面关小红点
	-- 202203重开 取消高级奖池
	-- local curDaiBi = FanGuangHuiYan:GetDaiBi()
	-- if (curDaiBi >= CRWarmUp_Shop_RaffleCost) then
	-- 	local awardCount = 0
	-- 	local itemListLen = table.getn(CRWarmUp_Shop_SeniorItemList)
	-- 	for i=1, itemListLen, 1 do
	-- 		if (FanGuangHuiYan:GetSeniorItemGotCount(i-1) <= 0) then
	-- 			awardCount = awardCount + 1
	-- 		end
	-- 	end
	-- 	if (awardCount > 0) then
	-- 		-- 显示高级奖池抽奖按钮小红点
	-- 		CRWarmUp_Shop_Raffle_Tips:Show()
	-- 		showSeniorRedPoint = 1
	-- 	else
	-- 		CRWarmUp_Shop_Raffle_Tips:Hide()
	-- 		showSeniorRedPoint = 0
	-- 	end
	-- else
	-- 	-- 不显示高级奖池抽奖按钮小红点
	-- 	CRWarmUp_Shop_Raffle_Tips:Hide()
	-- end

	-- 是否显示高级奖池页签小红点
	-- 202203重开 取高级奖池
	-- if (showSeniorRedPoint > 0) then
	-- 	-- 需要显示高级奖池页签小红点
	-- 	CRWarmUp_Shop_Buttontab02_Tips:Show()
	-- else
	-- 	-- 不需要显示高级奖池页签小红点
	-- 	CRWarmUp_Shop_Buttontab02_Tips:Hide()
	-- end
end -- end func CRWarmUp_Shop_UpdateRedPointTips()

-- 初始化控件
function CRWarmUp_Shop_InitCtrl()
	-- 初始化低级奖池物品控件列表
	if (CRWarmUp_Shop_Junior_ctrlItemList == nil) then
		CRWarmUp_Shop_Junior_ctrlItemList = {}
		-- 物品1
		CRWarmUp_Shop_Junior_ctrlItemList[1] = {}
		CRWarmUp_Shop_Junior_ctrlItemList[1].frame = CRWarmUp_Shop_Item1
		CRWarmUp_Shop_Junior_ctrlItemList[1].icon = CRWarmUp_Shop_Item1_Icon
		CRWarmUp_Shop_Junior_ctrlItemList[1].name = CRWarmUp_Shop_Item1_Text1
		CRWarmUp_Shop_Junior_ctrlItemList[1].price = CRWarmUp_Shop_Item1_Text2
		CRWarmUp_Shop_Junior_ctrlItemList[1].discount = CRWarmUp_Shop_Item1_DiscountText
		CRWarmUp_Shop_Junior_ctrlItemList[1].discountbk = CRWarmUp_Shop_Item1_DiscountBK
		CRWarmUp_Shop_Junior_ctrlItemList[1].eyesign = CRWarmUp_Shop_Item1_EyeSign
		CRWarmUp_Shop_Item1_EyeSign:SetEvent("Clicked", "CRWarmUp_Shop_EyeSign(1)")
		-- 物品2
		CRWarmUp_Shop_Junior_ctrlItemList[2] = {}
		CRWarmUp_Shop_Junior_ctrlItemList[2].frame = CRWarmUp_Shop_Item2
		CRWarmUp_Shop_Junior_ctrlItemList[2].icon = CRWarmUp_Shop_Item2_Icon
		CRWarmUp_Shop_Junior_ctrlItemList[2].name = CRWarmUp_Shop_Item2_Text1
		CRWarmUp_Shop_Junior_ctrlItemList[2].price = CRWarmUp_Shop_Item2_Text2
		CRWarmUp_Shop_Junior_ctrlItemList[2].discount = CRWarmUp_Shop_Item2_DiscountText
		CRWarmUp_Shop_Junior_ctrlItemList[2].discountbk = CRWarmUp_Shop_Item2_DiscountBK
		CRWarmUp_Shop_Junior_ctrlItemList[2].eyesign = CRWarmUp_Shop_Item2_EyeSign
		CRWarmUp_Shop_Item2_EyeSign:SetEvent("Clicked", "CRWarmUp_Shop_EyeSign(2)")
		-- 物品3
		CRWarmUp_Shop_Junior_ctrlItemList[3] = {}
		CRWarmUp_Shop_Junior_ctrlItemList[3].frame = CRWarmUp_Shop_Item3
		CRWarmUp_Shop_Junior_ctrlItemList[3].icon = CRWarmUp_Shop_Item3_Icon
		CRWarmUp_Shop_Junior_ctrlItemList[3].name = CRWarmUp_Shop_Item3_Text1
		CRWarmUp_Shop_Junior_ctrlItemList[3].price = CRWarmUp_Shop_Item3_Text2
		CRWarmUp_Shop_Junior_ctrlItemList[3].discount = CRWarmUp_Shop_Item3_DiscountText
		CRWarmUp_Shop_Junior_ctrlItemList[3].discountbk = CRWarmUp_Shop_Item3_DiscountBK
		CRWarmUp_Shop_Junior_ctrlItemList[3].eyesign = CRWarmUp_Shop_Item3_EyeSign
		CRWarmUp_Shop_Item3_EyeSign:SetEvent("Clicked", "CRWarmUp_Shop_EyeSign(3)")
		-- 物品4
		CRWarmUp_Shop_Junior_ctrlItemList[4] = {}
		CRWarmUp_Shop_Junior_ctrlItemList[4].frame = CRWarmUp_Shop_Item4
		CRWarmUp_Shop_Junior_ctrlItemList[4].icon = CRWarmUp_Shop_Item4_Icon
		CRWarmUp_Shop_Junior_ctrlItemList[4].name = CRWarmUp_Shop_Item4_Text1
		CRWarmUp_Shop_Junior_ctrlItemList[4].price = CRWarmUp_Shop_Item4_Text2
		CRWarmUp_Shop_Junior_ctrlItemList[4].discount = CRWarmUp_Shop_Item4_DiscountText
		CRWarmUp_Shop_Junior_ctrlItemList[4].discountbk = CRWarmUp_Shop_Item4_DiscountBK
		CRWarmUp_Shop_Junior_ctrlItemList[4].eyesign = CRWarmUp_Shop_Item4_EyeSign
		CRWarmUp_Shop_Item4_EyeSign:SetEvent("Clicked", "CRWarmUp_Shop_EyeSign(4)")
		-- 物品5
		CRWarmUp_Shop_Junior_ctrlItemList[5] = {}
		CRWarmUp_Shop_Junior_ctrlItemList[5].frame = CRWarmUp_Shop_Item5
		CRWarmUp_Shop_Junior_ctrlItemList[5].icon = CRWarmUp_Shop_Item5_Icon
		CRWarmUp_Shop_Junior_ctrlItemList[5].name = CRWarmUp_Shop_Item5_Text1
		CRWarmUp_Shop_Junior_ctrlItemList[5].price = CRWarmUp_Shop_Item5_Text2
		CRWarmUp_Shop_Junior_ctrlItemList[5].discount = CRWarmUp_Shop_Item5_DiscountText
		CRWarmUp_Shop_Junior_ctrlItemList[5].discountbk = CRWarmUp_Shop_Item5_DiscountBK
		CRWarmUp_Shop_Junior_ctrlItemList[5].eyesign = CRWarmUp_Shop_Item5_EyeSign
		CRWarmUp_Shop_Item5_EyeSign:SetEvent("Clicked", "CRWarmUp_Shop_EyeSign(5)")
		-- 物品6
		CRWarmUp_Shop_Junior_ctrlItemList[6] = {}
		CRWarmUp_Shop_Junior_ctrlItemList[6].frame = CRWarmUp_Shop_Item6
		CRWarmUp_Shop_Junior_ctrlItemList[6].icon = CRWarmUp_Shop_Item6_Icon
		CRWarmUp_Shop_Junior_ctrlItemList[6].name = CRWarmUp_Shop_Item6_Text1
		CRWarmUp_Shop_Junior_ctrlItemList[6].price = CRWarmUp_Shop_Item6_Text2
		CRWarmUp_Shop_Junior_ctrlItemList[6].discount = CRWarmUp_Shop_Item6_DiscountText
		CRWarmUp_Shop_Junior_ctrlItemList[6].discountbk = CRWarmUp_Shop_Item6_DiscountBK
		CRWarmUp_Shop_Junior_ctrlItemList[6].eyesign = CRWarmUp_Shop_Item6_EyeSign
		CRWarmUp_Shop_Item6_EyeSign:SetEvent("Clicked", "CRWarmUp_Shop_EyeSign(6)")
		-- 物品7
		CRWarmUp_Shop_Junior_ctrlItemList[7] = {}
		CRWarmUp_Shop_Junior_ctrlItemList[7].frame = CRWarmUp_Shop_Item7
		CRWarmUp_Shop_Junior_ctrlItemList[7].icon = CRWarmUp_Shop_Item7_Icon
		CRWarmUp_Shop_Junior_ctrlItemList[7].name = CRWarmUp_Shop_Item7_Text1
		CRWarmUp_Shop_Junior_ctrlItemList[7].price = CRWarmUp_Shop_Item7_Text2
		CRWarmUp_Shop_Junior_ctrlItemList[7].discount = CRWarmUp_Shop_Item7_DiscountText
		CRWarmUp_Shop_Junior_ctrlItemList[7].discountbk = CRWarmUp_Shop_Item7_DiscountBK
		CRWarmUp_Shop_Junior_ctrlItemList[7].eyesign = CRWarmUp_Shop_Item7_EyeSign
		CRWarmUp_Shop_Item7_EyeSign:SetEvent("Clicked", "CRWarmUp_Shop_EyeSign(7)")
		-- 物品8
		CRWarmUp_Shop_Junior_ctrlItemList[8] = {}
		CRWarmUp_Shop_Junior_ctrlItemList[8].frame = CRWarmUp_Shop_Item8
		CRWarmUp_Shop_Junior_ctrlItemList[8].icon = CRWarmUp_Shop_Item8_Icon
		CRWarmUp_Shop_Junior_ctrlItemList[8].name = CRWarmUp_Shop_Item8_Text1
		CRWarmUp_Shop_Junior_ctrlItemList[8].price = CRWarmUp_Shop_Item8_Text2
		CRWarmUp_Shop_Junior_ctrlItemList[8].discount = CRWarmUp_Shop_Item8_DiscountText
		CRWarmUp_Shop_Junior_ctrlItemList[8].discountbk = CRWarmUp_Shop_Item8_DiscountBK
		CRWarmUp_Shop_Junior_ctrlItemList[8].eyesign = CRWarmUp_Shop_Item8_EyeSign
		CRWarmUp_Shop_Item8_EyeSign:SetEvent("Clicked", "CRWarmUp_Shop_EyeSign(8)")
	end

	-- 初始化低级奖池领奖按钮控件
	if (CRWarmUp_Shop_Junior_ctrlAwardBtn == nil) then
		CRWarmUp_Shop_Junior_ctrlAwardBtn = {}
		-- 第一档奖励
		CRWarmUp_Shop_Junior_ctrlAwardBtn[1] = {}
		CRWarmUp_Shop_Junior_ctrlAwardBtn[1].btn = CRWarmUp_Shop_Progress_Icon1
		CRWarmUp_Shop_Junior_ctrlAwardBtn[1].tips = CRWarmUp_Shop_Progress_Icon1_Tips
		CRWarmUp_Shop_Junior_ctrlAwardBtn[1].get = CRWarmUp_Shop_Progress_Icon1_Get
		-- 第二档奖励
		CRWarmUp_Shop_Junior_ctrlAwardBtn[2] = {}
		CRWarmUp_Shop_Junior_ctrlAwardBtn[2].btn = CRWarmUp_Shop_Progress_Icon2
		CRWarmUp_Shop_Junior_ctrlAwardBtn[2].tips = CRWarmUp_Shop_Progress_Icon2_Tips
		CRWarmUp_Shop_Junior_ctrlAwardBtn[2].get = CRWarmUp_Shop_Progress_Icon2_Get
		-- 第三档奖励
		CRWarmUp_Shop_Junior_ctrlAwardBtn[3] = {}
		CRWarmUp_Shop_Junior_ctrlAwardBtn[3].btn = CRWarmUp_Shop_Progress_Icon3
		CRWarmUp_Shop_Junior_ctrlAwardBtn[3].tips = CRWarmUp_Shop_Progress_Icon3_Tips
		CRWarmUp_Shop_Junior_ctrlAwardBtn[3].get = CRWarmUp_Shop_Progress_Icon3_Get
		-- 第四档奖励
		CRWarmUp_Shop_Junior_ctrlAwardBtn[4] = {}
		CRWarmUp_Shop_Junior_ctrlAwardBtn[4].btn = CRWarmUp_Shop_Progress_Icon4
		CRWarmUp_Shop_Junior_ctrlAwardBtn[4].tips = CRWarmUp_Shop_Progress_Icon4_Tips
		CRWarmUp_Shop_Junior_ctrlAwardBtn[4].get = CRWarmUp_Shop_Progress_Icon4_Get
		-- 第五档奖励
		CRWarmUp_Shop_Junior_ctrlAwardBtn[5] = {}
		CRWarmUp_Shop_Junior_ctrlAwardBtn[5].btn = CRWarmUp_Shop_Progress_Icon5
		CRWarmUp_Shop_Junior_ctrlAwardBtn[5].tips = CRWarmUp_Shop_Progress_Icon5_Tips
		CRWarmUp_Shop_Junior_ctrlAwardBtn[5].get = CRWarmUp_Shop_Progress_Icon5_Get
        -- 第六档奖励
        CRWarmUp_Shop_Junior_ctrlAwardBtn[6] = {}
        CRWarmUp_Shop_Junior_ctrlAwardBtn[6].btn = CRWarmUp_Shop_Progress_Icon6
        CRWarmUp_Shop_Junior_ctrlAwardBtn[6].tips = CRWarmUp_Shop_Progress_Icon6_Tips
        CRWarmUp_Shop_Junior_ctrlAwardBtn[6].get = CRWarmUp_Shop_Progress_Icon6_Get
	end

	-- 初始化高级奖池物品列表控件
	-- 202203重开 取消高级奖池
	-- if (CRWarmUp_Shop_Senior_ctrlItemList == nil) then
	-- 	CRWarmUp_Shop_Senior_ctrlItemList = {}
	-- 	-- 物品1
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[1] = {}
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[1].icon = CRWarmUp_Shop_Lottery_Item1
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[1].animate = CRWarmUp_Shop_Lottery_Item1_Animate
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[1].name = CRWarmUp_Shop_Lottery_Item1Name
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[1].get = CRWarmUp_Shop_Lottery_Item1Get
	-- 	-- 物品2
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[2] = {}
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[2].icon = CRWarmUp_Shop_Lottery_Item2
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[2].animate = CRWarmUp_Shop_Lottery_Item2_Animate
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[2].name = CRWarmUp_Shop_Lottery_Item2Name
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[2].get = CRWarmUp_Shop_Lottery_Item2Get
	-- 	-- 物品3
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[3] = {}
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[3].icon = CRWarmUp_Shop_Lottery_Item3
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[3].animate = CRWarmUp_Shop_Lottery_Item3_Animate
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[3].name = CRWarmUp_Shop_Lottery_Item3Name
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[3].get = CRWarmUp_Shop_Lottery_Item3Get
	-- 	-- 物品4
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[4] = {}
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[4].icon = CRWarmUp_Shop_Lottery_Item4
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[4].animate = CRWarmUp_Shop_Lottery_Item4_Animate
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[4].name = CRWarmUp_Shop_Lottery_Item4Name
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[4].get = CRWarmUp_Shop_Lottery_Item4Get
	-- 	-- 物品5
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[5] = {}
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[5].icon = CRWarmUp_Shop_Lottery_Item5
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[5].animate = CRWarmUp_Shop_Lottery_Item5_Animate
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[5].name = CRWarmUp_Shop_Lottery_Item5Name
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[5].get = CRWarmUp_Shop_Lottery_Item5Get
	-- 	-- 物品6
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[6] = {}
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[6].icon = CRWarmUp_Shop_Lottery_Item6
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[6].animate = CRWarmUp_Shop_Lottery_Item6_Animate
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[6].name = CRWarmUp_Shop_Lottery_Item6Name
	-- 	CRWarmUp_Shop_Senior_ctrlItemList[6].get = CRWarmUp_Shop_Lottery_Item6Get
	-- end
end -- end func CRWarmUp_Shop_InitCtrl()

-- 获取日期的年、月、日 20111011
function CRWarmUp_Shop_GetYearMonthDay(dateTime)
	local year = math.floor(dateTime / 10000)

	local temp = dateTime - year*10000
	local month = math.floor(temp / 100)

	local day = math.mod(dateTime, 100)

	return year, month, day
end -- end fnc CRWarmUp_Shop_GetYearMonthDay()
function CRWarmUp_Shop_Cooldown_Func()
	CRWarmUp_Shop_Cooldown = 0
	KillTimer("CRWarmUp_Shop_Cooldown_Func()")
end