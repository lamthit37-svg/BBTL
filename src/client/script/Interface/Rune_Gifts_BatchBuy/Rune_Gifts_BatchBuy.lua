--礼物兑换商店批量兑换
-- !!!reloadscript =Rune_Gifts_BatchBuy
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition
local m_targetId = 0
local m_ObjCareID = 0

local m_ButtonType = 
{
	LiangPinGift=1, --良品礼物
	JingPinGift=2, --精品礼物
	ZhenPinGift=3, --珍品礼物
	ShenPinGift=4, --神品礼物
}
local m_haveItemList =
{
	[m_ButtonType.LiangPinGift] = {Str="#{TYLW_200616_13}", Str1="#{TYLW_200616_20}"},
	[m_ButtonType.JingPinGift] = {Str="#{TYLW_200616_14}", Str1="#{TYLW_200616_21}"},
	[m_ButtonType.ZhenPinGift] = {Str="#{TYLW_200616_15}", Str1="#{TYLW_200616_22}"},
	[m_ButtonType.ShenPinGift] = {Str="#{TYLW_200616_16}", Str1="#{TYLW_200616_23}"},
}
local m_curButtonType = 0
local m_realIndex = 0

local m_CurNum = 1

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Rune_Gifts_BatchBuy_PreLoad()
	this:RegisterEvent("GIFTEXCHANGESHOP")
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Rune_Gifts_BatchBuy_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= Rune_Gifts_BatchBuy_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= Rune_Gifts_BatchBuy_Frame:GetProperty("UnifiedYPosition");
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Rune_Gifts_BatchBuy_ResetPos()
	Rune_Gifts_BatchBuy_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	Rune_Gifts_BatchBuy_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end
--响应事件的函数，当注册的事件发生时会调用的函数
function Rune_Gifts_BatchBuy_OnEvent(event)

	if event == "GIFTEXCHANGESHOP" then
		local nType = tonumber(arg0)
		if nType == 2 then --打开批量兑换界面
			if (this:IsVisible()) then
				return
			end
			m_targetId = tonumber(arg1)
			m_realIndex = tonumber(arg2)
			m_curButtonType = tonumber(arg3)
			m_ObjCareID = DataPool:GetNPCIDByServerID(m_targetId)
			Rune_Gifts_BatchBuy_Show()
		elseif nType == 3 then
			if (this:IsVisible()) then
				Rune_Gifts_BatchBuy_Hide()
				return
			end
		end
	elseif event == "PACKAGE_ITEM_CHANGED_EX" then
		Rune_Gifts_BatchBuy_UpdateHaveItem()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Rune_Gifts_BatchBuy_Hide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Rune_Gifts_BatchBuy_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Rune_Gifts_BatchBuy_ResetPos()
	elseif event == "OBJECT_CARED_EVENT" then
		Rune_Gifts_BatchBuy_CareEvent(arg0,arg1,arg2)
	end

end
--显示UI
function Rune_Gifts_BatchBuy_Show()
	Rune_Gifts_BatchBuy_ClearData()
	this:CareObject(m_ObjCareID, 1, "Rune_Gifts_BatchBuy");
	this:Show()
	Rune_Gifts_BatchBuy_Updata()
end
--隐藏UI
function Rune_Gifts_BatchBuy_Hide()
	Rune_Gifts_BatchBuy_ClearData()
	Rune_Gifts_BatchBuy_NumberInput:SetProperty("DefaultEditBox", "False");
	this:Hide()
end

--清除数据
function Rune_Gifts_BatchBuy_ClearData()
	m_CurNum = 1
end

function Rune_Gifts_BatchBuy_Updata()
	local nType , itemId, showItemId, needItemId, needItemNum = FashionDepot:LuaFnGetCommonGiftDuiHuanShopGoodsInfo(m_realIndex)
	if nil == nType then
		Rune_Gifts_BatchBuy_OnHidden()
		return
	end
	if m_curButtonType < m_ButtonType.LiangPinGift or 
		m_curButtonType > m_ButtonType.ShenPinGift then
		Rune_Gifts_BatchBuy_OnHidden()
		return
	end
	if showItemId <= 0 then
		showItemId = itemId
	end
	local theAction = DataPool:CreateActionItemForShow(showItemId, 1)
	if theAction:GetID() ~= 0 then
		Rune_Gifts_BatchBuy_Item:SetActionItem(theAction:GetID())
		Rune_Gifts_BatchBuy_Item:ActionEnable()
		Rune_Gifts_BatchBuyBtnNumberBK:Hide()
		-- Rune_Gifts_BatchBuyBtnNumber:SetText("1")
		local itemName = DataPool:Lua_GetItemNameByIndex(itemId)
		Rune_Gifts_BatchBuy_ItemName:SetText("#L"..itemName)
		Rune_Gifts_BatchBuy_ItemPrice:SetText(ScriptGlobal_Format(m_haveItemList[m_curButtonType].Str, needItemNum))
	end
	Rune_Gifts_BatchBuy_UpdateHaveItem()

	Rune_Gifts_BatchBuy_NumberInput:SetProperty("DefaultEditBox", "True");
	Rune_Gifts_BatchBuy_NumberInput:SetText(tostring(1));
	Rune_Gifts_BatchBuy_NumberInput:SetSelected( 0, -1 );
end
function Rune_Gifts_BatchBuy_UpdateHaveItem()
	if m_curButtonType < m_ButtonType.LiangPinGift or 
		m_curButtonType > m_ButtonType.ShenPinGift then
		return
	end
	local nType , itemId, showItemId, needItemId, needItemNum = FashionDepot:LuaFnGetCommonGiftDuiHuanShopGoodsInfo(m_realIndex)
	if nil == nType then
		Rune_Gifts_BatchBuy_OnHidden()
		return
	end
	local itemcount = PlayerPackage:CountAvailableItemByIDTable(needItemId)
	local canBuyNum = math.ceil(itemcount/needItemNum)
	-- local num = tonumber(Rune_Gifts_BatchBuy_NumberInput:GetText())
	Rune_Gifts_BatchBuy_TextNeed:SetText(ScriptGlobal_Format("#{TYLW_200616_36}", m_haveItemList[m_curButtonType].Str1))
	Rune_Gifts_BatchBuy_TextNeedNum:SetText("#L"..m_CurNum*needItemNum)
	Rune_Gifts_BatchBuy_TextHave:SetText(ScriptGlobal_Format("#{TYLW_200616_37}", m_haveItemList[m_curButtonType].Str1))
	if m_CurNum > canBuyNum then
		Rune_Gifts_BatchBuy_TextHaveNum:SetText("#cff0000"..itemcount)
	else
		Rune_Gifts_BatchBuy_TextHaveNum:SetText("#M"..itemcount)
	end
end

--##############点击事件##############
function Rune_Gifts_BatchBuy_OnHidden()
	Rune_Gifts_BatchBuy_Hide()
end
function Rune_Gifts_BatchBuy_TextChanged()
	local nString = Rune_Gifts_BatchBuy_NumberInput:GetText()
	
	local num = 1
	
	if nString == nil or nString == "" then
		m_CurNum = 0
		Rune_Gifts_BatchBuy_UpdateHaveItem()
		return
	else
		num = tonumber(nString)
	end
	local nType , itemId, showItemId, needItemId, needItemNum = FashionDepot:LuaFnGetCommonGiftDuiHuanShopGoodsInfo(m_realIndex)
	if nil == nType then
		Rune_Gifts_BatchBuy_OnHidden()
		return
	end
	local itemcount = PlayerPackage:CountAvailableItemByIDTable(needItemId)

	local canBuyNum = math.floor(itemcount/needItemNum)
	if(num > canBuyNum) then
		num = canBuyNum
	end
	if num <= 0 then
		num = 1
	end
	if m_CurNum ~= tonumber(nString) then
		m_CurNum = num
		Rune_Gifts_BatchBuy_NumberInput:SetText(tostring(m_CurNum))
		Rune_Gifts_BatchBuy_UpdateHaveItem()
	end
end
function Rune_Gifts_BatchBuy_CalMax()
	local nType , itemId, showItemId, needItemId, needItemNum = FashionDepot:LuaFnGetCommonGiftDuiHuanShopGoodsInfo(m_realIndex)
	if nil == nType then
		Rune_Gifts_BatchBuy_OnHidden()
		return
	end
	local num = tonumber(Rune_Gifts_BatchBuy_NumberInput:GetText())
	local itemcount = PlayerPackage:CountAvailableItemByIDTable(needItemId)

	local canBuyNum = math.floor(itemcount/needItemNum)
	if canBuyNum < 1 then
		canBuyNum = 1
	end
	m_CurNum = canBuyNum
	Rune_Gifts_BatchBuy_NumberInput:SetText(tostring(canBuyNum))
	Rune_Gifts_BatchBuy_UpdateHaveItem()
end

function Rune_Gifts_BatchBuy_OKClick()
	-- local num = tonumber(Rune_Gifts_BatchBuy_NumberInput:GetText())
	if m_CurNum <= 0 then
		PushDebugMessage("#{TYLW_200616_40}")
		return
	end
	local nType , itemId, showItemId, needItemId, needItemNum = FashionDepot:LuaFnGetCommonGiftDuiHuanShopGoodsInfo(m_realIndex)
	if nil == nType then
		Rune_Gifts_BatchBuy_OnHidden()
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("BatchExchangeItem")
		Set_XSCRIPT_ScriptID( 888089 )
		Set_XSCRIPT_Parameter(0, m_targetId)
		Set_XSCRIPT_Parameter(1, nType)
		Set_XSCRIPT_Parameter(2, itemId)
		Set_XSCRIPT_Parameter(3, m_CurNum)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
	Rune_Gifts_BatchBuy_OnHidden()
end
function Rune_Gifts_BatchBuy_CancelClick()
	Rune_Gifts_BatchBuy_OnHidden()
end
--####################################

function Rune_Gifts_BatchBuy_CareEvent(arg0,arg1,arg2)
	local ObjCaredID = tonumber(arg0)
	if( ObjCaredID ~= m_ObjCareID) then
		return
	end
	local ObjDistance = tonumber(arg2)
	if( (arg1 == "distance" and ObjDistance>MAX_OBJ_DISTANCE) or arg1=="destroy") then
		Rune_Gifts_BatchBuy_Hide()
	end
end