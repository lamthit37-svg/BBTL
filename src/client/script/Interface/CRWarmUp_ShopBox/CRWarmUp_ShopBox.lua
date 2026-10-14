-- 2021Q3版本预热付费活动 繁光会宴 物品预览界面

-- 保存UI默认位置
local CRWarmUp_ShopBox_UnifiedPosition = nil

local CRWarmUp_ShopBox_Preview_Cur = -1

-- 物品类型
local CRWarmUp_ShopBox_ItemTypeInfo =
{
	-- 元宝
	[1] = {type = 1, dict = "#{XMPYRFF_210826_17}"},
	-- 绑元
	[2] = {type = 2, dict = "#{XMPYRFF_210826_19}"},
	-- 金币
	[3] = {type = 3, dict = "#{XMPYRFF_210826_18}"},
	-- 新代币
	[4] = {type = 4, dict = ""},
} -- end CRWarmUp_ShopBox_ItemTypeInfo

-- 活动奖池物品列表
local CRWarmUp_ShopBox_JuniorItemList =
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
    [7] = {type = 1, id = 38000946, view = 39920940, price = 850, discount = 8.5, num = 1, maxnum = -1, weighted = 100, preview = -1, mat = 0, propt = 1},     -- 苍鹤药魂
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
} -- end CRWarmUp_ShopBox_JuniorItemList



function CRWarmUp_ShopBox_PreLoad()
    this:RegisterEvent("FGHY_UI_OPENPREVIEW", true)
    this:RegisterEvent("FGHY_UI_CLOSEPREVIEW", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func CRWarmUp_ShopBox_PreLoad()

function CRWarmUp_ShopBox_OnEvent(event)
    if (event == "FGHY_UI_OPENPREVIEW") then
        -- 开启UI
        CRWarmUp_ShopBox_Show()
		CRWarmUp_ShopBox_Junior_UpdatePreview(CRWarmUp_ShopBox_ItemTypeInfo[1].type)
		CRWarmUp_ShopBox_CheckBtn1:SetCheck(1)
    elseif (event == "FGHY_UI_CLOSEPREVIEW") then
        -- 关闭UI
        CRWarmUp_ShopBox_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		CRWarmUp_ShopBox_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		CRWarmUp_ShopBox_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		CRWarmUp_ShopBox_UnifiedPos()
	end
end -- end func CRWarmUp_ShopBox_OnEvent()

function CRWarmUp_ShopBox_OnLoad()
	CRWarmUp_ShopBox_UnifiedPosition = CRWarmUp_ShopBox_FrameNULL:GetProperty("UnifiedPosition")
end -- end func CRWarmUp_ShopBox_OnLoad()

-- 界面默认位置
function CRWarmUp_ShopBox_UnifiedPos()
	if (CRWarmUp_ShopBox_UnifiedPosition ~= nil) then
		CRWarmUp_ShopBox_FrameNULL:SetProperty("UnifiedPosition", CRWarmUp_ShopBox_UnifiedPosition)
	end
end -- end func CRWarmUp_ShopBox_UnifiedPos()

-- 开启UI
function CRWarmUp_ShopBox_Show()
	this:Show()
end -- end func CRWarmUp_ShopBox_Show()

-- 关闭UI
function CRWarmUp_ShopBox_Hide()
	this:Hide()
end -- end func CRWarmUp_ShopBox_Hide()

-- 关闭按钮事件
function CRWarmUp_ShopBox_Close()
	CRWarmUp_ShopBox_Hide()
end -- end func CRWarmUp_ShopBox_Close()

-- 预览界面 元宝、绑元、交子按钮
function CRWarmUp_ShopBox_CheckClick(param)
	local moneyType = 0
	if (param == 1) then
		moneyType = CRWarmUp_ShopBox_ItemTypeInfo[1].type
		if (CRWarmUp_ShopBox_Preview_Cur == moneyType) then
			return
		end

		CRWarmUp_ShopBox_CheckBtn1:SetCheck(1)
		CRWarmUp_ShopBox_CheckBtn2:SetCheck(0)
		CRWarmUp_ShopBox_CheckBtn3:SetCheck(0)
	elseif (param == 2) then
		moneyType = CRWarmUp_ShopBox_ItemTypeInfo[2].type
		if (CRWarmUp_ShopBox_Preview_Cur == moneyType) then
			return
		end

		CRWarmUp_ShopBox_CheckBtn1:SetCheck(0)
		CRWarmUp_ShopBox_CheckBtn2:SetCheck(1)
		CRWarmUp_ShopBox_CheckBtn3:SetCheck(0)
	elseif (param == 3) then
		moneyType = CRWarmUp_ShopBox_ItemTypeInfo[3].type
		if (CRWarmUp_ShopBox_Preview_Cur == moneyType) then
			return
		end

		CRWarmUp_ShopBox_CheckBtn1:SetCheck(0)
		CRWarmUp_ShopBox_CheckBtn2:SetCheck(0)
		CRWarmUp_ShopBox_CheckBtn3:SetCheck(1)
	else
		return
	end

	if (moneyType == 0) then
		return
	end

	CRWarmUp_ShopBox_Junior_UpdatePreview(moneyType)
end -- end func CRWarmUp_ShopBox_CheckClick()

-- 更新预览物品
function CRWarmUp_ShopBox_Junior_UpdatePreview(moneyType)
	CRWarmUp_ShopBox_SuperList:Clear()
	local len = table.getn(CRWarmUp_ShopBox_JuniorItemList)
	for i=1, len, 1 do
		local itemInfo = CRWarmUp_ShopBox_JuniorItemList[i]
		if (itemInfo ~= nil and itemInfo.type == moneyType) then
			local itemCtrl = CRWarmUp_ShopBox_SuperList:AddChild("CRWarmUp_ShopBox_CoinAItem1")
			if (itemCtrl ~= nil) then
				-- 创建展示道具
				local theAction = DataPool:CreateActionItemForShow(itemInfo.view, itemInfo.num)
				-- 设置展示道具
				itemCtrl:GetSubItem("CRWarmUp_ShopBox_SuperListItem"):SetActionItem(theAction:GetID())
				-- 设置道具名称
				itemCtrl:GetSubItem("CRWarmUp_ShopBox_SuperListItem_Acount"):SetText("#L" .. DataPool:Lua_GetItemNameByIndex(itemInfo.id))
				-- 设置物品价格
				local priceText = ""
				local moneyTypeInfo = CRWarmUp_ShopBox_ItemTypeInfo[itemInfo.type]
				if (moneyTypeInfo.type == CRWarmUp_ShopBox_ItemTypeInfo[3].type) then
					priceText = ScriptGlobal_Format("#{XMPYRFF_210826_126}", itemInfo.price)
				else
					priceText = ScriptGlobal_Format("#{XMPYRFF_210826_16}", moneyTypeInfo.dict, itemInfo.price)
				end
				itemCtrl:GetSubItem("CRWarmUp_ShopBox_SuperListItem_Price"):SetText(priceText)
				-- 设置折扣率
				if (itemInfo.discount > 0) then
					itemCtrl:GetSubItem("CRWarmUp_ShopBox_SuperListItem_DiscountBK"):Show()
					itemCtrl:GetSubItem("CRWarmUp_ShopBox_SuperListItem_DiscountText"):Show()
					local discountText = ScriptGlobal_Format("#{XMPYRFF_210826_15}", itemInfo.discount)
					itemCtrl:GetSubItem("CRWarmUp_ShopBox_SuperListItem_DiscountText"):SetText(discountText)
				else
					itemCtrl:GetSubItem("CRWarmUp_ShopBox_SuperListItem_DiscountBK"):Hide()
					itemCtrl:GetSubItem("CRWarmUp_ShopBox_SuperListItem_DiscountText"):Hide()
				end
				
				itemCtrl:GetSubItem("CRWarmUp_ShopBox_SuperListItem_EyeSign"):Hide()
			end
		end
	end -- end for

	CRWarmUp_ShopBox_Preview_Cur = moneyType
end -- end func CRWarmUp_ShopBox_Junior_UpdatePreview()