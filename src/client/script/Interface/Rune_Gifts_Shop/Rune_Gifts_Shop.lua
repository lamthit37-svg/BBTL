--礼物兑换商店
-- !!!reloadscript =Rune_Gifts_Shop
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
local m_curButtonType = m_ButtonType.LiangPinGift

local m_curPage = 1
local m_num4Page = 15
local m_TotalPageNum = 0

local m_haveItemList =
{
	[m_ButtonType.LiangPinGift] = {Str="#{TYLW_200616_13}", ItemID=38004804},
	[m_ButtonType.JingPinGift] = {Str="#{TYLW_200616_14}", ItemID=38004805},
	[m_ButtonType.ZhenPinGift] = {Str="#{TYLW_200616_15}", ItemID=38004734},
	[m_ButtonType.ShenPinGift] = {Str="#{TYLW_200616_16}", ItemID=38004806},
}
local m_pageButton = {}
local m_itemListUI = {}
local m_itemListData = {}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Rune_Gifts_Shop_PreLoad()
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
function Rune_Gifts_Shop_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= Rune_Gifts_Shop_Frame:GetProperty("UnifiedXPosition")
	m_Frame_UnifiedYPosition	= Rune_Gifts_Shop_Frame:GetProperty("UnifiedYPosition")

	m_pageButton[m_ButtonType.LiangPinGift] = Rune_Gifts_Shop_Page1
	m_pageButton[m_ButtonType.JingPinGift] = Rune_Gifts_Shop_Page2
	m_pageButton[m_ButtonType.ZhenPinGift] = Rune_Gifts_Shop_Page3
	m_pageButton[m_ButtonType.ShenPinGift] = Rune_Gifts_Shop_Page4


	for i = 1, m_num4Page do
		 m_itemListUI[i] = {ItemAction=_G["Rune_Gifts_Shop_Item"..i], ItemLimitBk=_G["Rune_Gifts_Shop_Item"..i.."LimitNumberBK"], 
		 					 ItemLimit=_G["Rune_Gifts_Shop_Item"..i.."LimitNumber"], ItemName=_G["Rune_Gifts_Shop_ItemInfo"..i.."_Text"],
		 					 ItemPrice=_G["Rune_Gifts_Shop_ItemInfo"..i.."_GB"]}
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Rune_Gifts_Shop_ResetPos()
	Rune_Gifts_Shop_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	Rune_Gifts_Shop_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end
--响应事件的函数，当注册的事件发生时会调用的函数
function Rune_Gifts_Shop_OnEvent(event)

	if event == "GIFTEXCHANGESHOP" then
		local nType = tonumber(arg0)
		if nType == 1 then --打开礼物兑换窗口
			m_targetId = tonumber(arg1)
			if (this:IsVisible()) then
				return
			end
			m_ObjCareID = DataPool:GetNPCIDByServerID(m_targetId)
			Rune_Gifts_Shop_Show()
		end
	elseif event == "PACKAGE_ITEM_CHANGED_EX" then
		Rune_Gifts_Shop_UpdateHaveItem()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Rune_Gifts_Shop_Hide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Rune_Gifts_Shop_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Rune_Gifts_Shop_ResetPos()
	elseif event == "OBJECT_CARED_EVENT" then
		Rune_Gifts_Shop_CareEvent(arg0,arg1,arg2)
	end

end
--显示UI
function Rune_Gifts_Shop_Show()
	Rune_Gifts_Shop_ClearData()
	this:CareObject(m_ObjCareID, 1, "Rune_Gifts_Shop");
	this:Show()
	Rune_Gifts_Shop_Update(m_curButtonType)
end
--隐藏UI
function Rune_Gifts_Shop_Hide()
	PushEvent("GIFTEXCHANGESHOP", 3)
	SetDefaultMouse()
	Rune_Gifts_Shop_ClearData()
	this:Hide()
end

--清除数据
function Rune_Gifts_Shop_ClearData()
	m_curButtonType = m_ButtonType.LiangPinGift
end

function Rune_Gifts_Shop_Update(buttonType)
	if buttonType < m_ButtonType.LiangPinGift or 
		buttonType > m_ButtonType.ShenPinGift then
		return
	end
	m_curButtonType = buttonType
	for index = 1, m_ButtonType.ShenPinGift do
		if index == m_curButtonType then
			m_pageButton[index]:SetCheck(1)
		else
			m_pageButton[index]:SetCheck(0)
		end
	end
	FashionDepot:LuaFnInitCommonGiftDuiHuanShop(m_curButtonType)
	local goodsNum = FashionDepot:LuaFnGetCommonGiftDuiHuanShopGoodsNum()
	m_curPage = 1
	m_TotalPageNum = math.ceil(goodsNum/m_num4Page)
	if m_TotalPageNum <= 0 then
		m_TotalPageNum = 1
	end
	Rune_Gifts_Shop_UpdateData()
end
function Rune_Gifts_Shop_UpdateData()
	if m_curPage > m_TotalPageNum then
		return
	end
	if m_TotalPageNum == 1 then
		Rune_Gifts_Shop_UpPage:Hide()
		Rune_Gifts_Shop_DownPage:Hide()
		Rune_Gifts_Shop_CurrentlyPage:Hide()
	else
		Rune_Gifts_Shop_UpPage:Show()
		Rune_Gifts_Shop_DownPage:Show()
		Rune_Gifts_Shop_CurrentlyPage:Show()
	end
	if m_curPage <= 1 then
		Rune_Gifts_Shop_UpPage:Disable()
	else
		Rune_Gifts_Shop_UpPage:Enable()
	end
	if m_curPage >= m_TotalPageNum then
		Rune_Gifts_Shop_DownPage:Disable()
	else
		Rune_Gifts_Shop_DownPage:Enable()
	end

	Rune_Gifts_Shop_CurrentlyPage:SetText(ScriptGlobal_Format("#{TYLW_200616_17}", m_curPage, m_TotalPageNum))
	Rune_Gifts_Shop_UpdateHaveItem()

	local goodsNum = FashionDepot:LuaFnGetCommonGiftDuiHuanShopGoodsNum()
	local startIndex = m_num4Page * (m_curPage - 1)
	for index = 1, m_num4Page do
		local nType , itemId, showItemId, needItemId, needItemNum = FashionDepot:LuaFnGetCommonGiftDuiHuanShopGoodsInfo(startIndex)
		if nil ~= nType then
			m_itemListData[index] = startIndex
			if showItemId <= 0 then
				showItemId = itemId
			end
			local theAction = DataPool:CreateActionItemForShow(showItemId, 1)
			if theAction:GetID() ~= 0 then
				m_itemListUI[index].ItemAction:SetActionItem(theAction:GetID())
				m_itemListUI[index].ItemAction:ActionEnable()
				m_itemListUI[index].ItemLimitBk:Hide()
				-- m_itemListUI[index].ItemLimit:SetText("1")
				local itemName = DataPool:Lua_GetItemNameByIndex(itemId)
				m_itemListUI[index].ItemName:SetText("#L"..itemName)
				m_itemListUI[index].ItemPrice:SetText(ScriptGlobal_Format(m_haveItemList[m_curButtonType].Str, needItemNum))
			end
		else
			m_itemListData[index] = -1
			m_itemListUI[index].ItemAction:SetActionItem(-1)
			m_itemListUI[index].ItemAction:ActionDisable()
			m_itemListUI[index].ItemLimitBk:Hide()
			m_itemListUI[index].ItemName:SetText("")
			m_itemListUI[index].ItemPrice:SetText("")
		end
		startIndex = startIndex + 1
	end
end

function Rune_Gifts_Shop_UpdateHaveItem()
	if m_curButtonType < m_ButtonType.LiangPinGift or 
		m_curButtonType > m_ButtonType.ShenPinGift then
		return
	end
	local itemcount = PlayerPackage:CountAvailableItemByIDTable(m_haveItemList[m_curButtonType].ItemID)
	Rune_Gifts_Shop_Text1:SetText(ScriptGlobal_Format(m_haveItemList[m_curButtonType].Str, itemcount))
end

--##############点击事件##############
function Rune_Gifts_Shop_OnHidden()
	Rune_Gifts_Shop_Hide()
end
function Rune_Gifts_Shop_PageClick(buttonType)
	if m_curButtonType == buttonType then
		return
	end
	SetDefaultMouse()
	PushEvent("GIFTEXCHANGESHOP", 3)
	Rune_Gifts_Shop_Update(buttonType)
end
function Rune_Gifts_Shop_QuestionMarkClick()
	PushEvent("GIFTEXCHANGESHOP", 3)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowHelpText")
		Set_XSCRIPT_ScriptID( 888089 )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
function Rune_Gifts_Shop_ItemClicked(index)
	if nil == m_itemListData[index] or m_itemListData[index] < 0 then
		return
	end
	PushEvent("GIFTEXCHANGESHOP", 3)
	local nType , itemId, showItemId, needItemId, needItemNum = FashionDepot:LuaFnGetCommonGiftDuiHuanShopGoodsInfo(m_itemListData[index])
	if CheckBuyMult() == 1 then
		PushEvent("GIFTEXCHANGESHOP", 2, m_targetId, m_itemListData[index], m_curButtonType)
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ExchangeItem")
			Set_XSCRIPT_ScriptID( 888089 )
			Set_XSCRIPT_Parameter(0, m_targetId)
			Set_XSCRIPT_Parameter(1, nType)
			Set_XSCRIPT_Parameter(2, itemId)
			Set_XSCRIPT_Parameter(3, 0)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end
end
function Rune_Gifts_Shop_UpPageClick()
	if m_curPage <= 1 then
		return
	end
	PushEvent("GIFTEXCHANGESHOP", 3)
	m_curPage = m_curPage - 1
	Rune_Gifts_Shop_UpdateData()
end
function Rune_Gifts_Shop_DownPageClick()
	if m_curPage >= m_TotalPageNum then
		return
	end
	PushEvent("GIFTEXCHANGESHOP", 3)
	m_curPage = m_curPage + 1
	Rune_Gifts_Shop_UpdateData()
end
function Rune_Gifts_Shop_DuihuanClick()
	PushEvent("GIFTEXCHANGESHOP", 3)
	PrepearBuyMult()
end
--####################################

--以下是用户自定义的函数
function Rune_Gifts_Shop_CareEvent(arg0,arg1,arg2)
	local ObjCaredID = tonumber(arg0)
	if( ObjCaredID ~= m_ObjCareID) then
		return
	end
	local ObjDistance = tonumber(arg2)
	if( (arg1 == "distance" and ObjDistance>MAX_OBJ_DISTANCE) or arg1=="destroy") then
		Rune_Gifts_Shop_Hide()
	end
end