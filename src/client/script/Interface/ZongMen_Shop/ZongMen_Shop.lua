local g_ZongMen_Shop_Frame_UnifiedXPosition
local g_ZongMen_Shop_Frame_UnifiedYPosition

local g_ZongMen_Shop_Page1Type = 1 --当前页数
local g_ZongMen_Shop_Page2Type = 1 --当前页数
local g_ZongMen_Shop_CurPage = 0
local g_ZongMen_Shop_PerPageCount = 18 --每一页显示的商品数量

local g_ZongMen_Shop_ItemsCount = {} --某个页签下的商品总数量

local g_ZongMen_Shop_ServerObj = -1
local g_ZongMen_Shop_CareObj = -1

local g_ZongMen_Shop_FPage = {}
local g_ZongMen_Shop_FPageLock = {}
local g_ZongMen_Shop_SPage = {}

local g_ZongMen_Shop_UI_Frame = {}
local g_ZongMen_Shop_UI_ActionButton = {}
local g_ZongMen_Shop_UI_ItemButLimit = {}
local g_ZongMen_Shop_UI_DisCount = {}
local g_ZongMen_Shop_UI_ItemMask = {}
local g_ZongMen_Shop_UI_ItemName = {}
local g_ZongMen_Shop_UI_ItemPrice = {}
local g_ZongMen_Shop_UI_ItemWLimit = {}
local g_ZongMen_Shop_UI_ItemFLimit = {}
local g_ZongMen_Shop_UI_ItemDLimit = {}

local g_ZongMen_Shop_ItemsInfo = {}

local g_ZongMen_Shop_BuyingIndex = -1

local g_ZongMen_Shop_CurWeek = 0

--************************
-- PreLoad
--************************
function ZongMen_Shop_PreLoad()
    this:RegisterEvent("UPDATE_ZONGMEN_SHOPINFO", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
    this:RegisterEvent("CHANGE_WEEK", false)
    this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("ZONGMEN_DIZILEVEL_UPDATE",false)
end

--************************
-- OnLoad
--************************
function ZongMen_Shop_OnLoad()
	g_ZongMen_Shop_FPage[1] = ZongMen_Shop_PageButton1
	g_ZongMen_Shop_FPage[2] = ZongMen_Shop_PageButton2
	g_ZongMen_Shop_FPage[3] = ZongMen_Shop_PageButton3
	g_ZongMen_Shop_FPage[4] = ZongMen_Shop_PageButton4
	g_ZongMen_Shop_FPage[5] = ZongMen_Shop_PageButton5

	g_ZongMen_Shop_FPageLock[1] = ZongMen_Shop_PageButton1_LockedIcon
	g_ZongMen_Shop_FPageLock[2] = ZongMen_Shop_PageButton2_LockedIcon
	g_ZongMen_Shop_FPageLock[3] = ZongMen_Shop_PageButton3_LockedIcon
	g_ZongMen_Shop_FPageLock[4] = ZongMen_Shop_PageButton4_LockedIcon
	g_ZongMen_Shop_FPageLock[5] = ZongMen_Shop_PageButton5_LockedIcon

	g_ZongMen_Shop_SPage[1] = ZongMen_Shop_IndexButton1
	g_ZongMen_Shop_SPage[2] = ZongMen_Shop_IndexButton2

	g_ZongMen_Shop_UI_Frame[1] = ZongMen_Shop_Item1Frame
	g_ZongMen_Shop_UI_Frame[2] = ZongMen_Shop_Item2Frame
	g_ZongMen_Shop_UI_Frame[3] = ZongMen_Shop_Item3Frame
	g_ZongMen_Shop_UI_Frame[4] = ZongMen_Shop_Item4Frame
	g_ZongMen_Shop_UI_Frame[5] = ZongMen_Shop_Item5Frame
	g_ZongMen_Shop_UI_Frame[6] = ZongMen_Shop_Item6Frame
	g_ZongMen_Shop_UI_Frame[7] = ZongMen_Shop_Item7Frame
	g_ZongMen_Shop_UI_Frame[8] = ZongMen_Shop_Item8Frame
	g_ZongMen_Shop_UI_Frame[9] = ZongMen_Shop_Item9Frame
	g_ZongMen_Shop_UI_Frame[10] = ZongMen_Shop_Item10Frame
	g_ZongMen_Shop_UI_Frame[11] = ZongMen_Shop_Item11Frame
	g_ZongMen_Shop_UI_Frame[12] = ZongMen_Shop_Item12Frame
	g_ZongMen_Shop_UI_Frame[13] = ZongMen_Shop_Item13Frame
	g_ZongMen_Shop_UI_Frame[14] = ZongMen_Shop_Item14Frame
	g_ZongMen_Shop_UI_Frame[15] = ZongMen_Shop_Item15Frame
	g_ZongMen_Shop_UI_Frame[16] = ZongMen_Shop_Item16Frame
	g_ZongMen_Shop_UI_Frame[17] = ZongMen_Shop_Item17Frame
	g_ZongMen_Shop_UI_Frame[18] = ZongMen_Shop_Item18Frame

	g_ZongMen_Shop_UI_ActionButton[1] = ZongMen_Shop_Item1
	g_ZongMen_Shop_UI_ActionButton[2] = ZongMen_Shop_Item2
	g_ZongMen_Shop_UI_ActionButton[3] = ZongMen_Shop_Item3
	g_ZongMen_Shop_UI_ActionButton[4] = ZongMen_Shop_Item4
	g_ZongMen_Shop_UI_ActionButton[5] = ZongMen_Shop_Item5
	g_ZongMen_Shop_UI_ActionButton[6] = ZongMen_Shop_Item6
	g_ZongMen_Shop_UI_ActionButton[7] = ZongMen_Shop_Item7
	g_ZongMen_Shop_UI_ActionButton[8] = ZongMen_Shop_Item8
	g_ZongMen_Shop_UI_ActionButton[9] = ZongMen_Shop_Item9
	g_ZongMen_Shop_UI_ActionButton[10] = ZongMen_Shop_Item10
	g_ZongMen_Shop_UI_ActionButton[11] = ZongMen_Shop_Item11
	g_ZongMen_Shop_UI_ActionButton[12] = ZongMen_Shop_Item12
	g_ZongMen_Shop_UI_ActionButton[13] = ZongMen_Shop_Item13
	g_ZongMen_Shop_UI_ActionButton[14] = ZongMen_Shop_Item14
	g_ZongMen_Shop_UI_ActionButton[15] = ZongMen_Shop_Item15
	g_ZongMen_Shop_UI_ActionButton[16] = ZongMen_Shop_Item16
	g_ZongMen_Shop_UI_ActionButton[17] = ZongMen_Shop_Item17
	g_ZongMen_Shop_UI_ActionButton[18] = ZongMen_Shop_Item18

	g_ZongMen_Shop_UI_ItemButLimit[1] = ZongMen_Shop_Item1_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[2] = ZongMen_Shop_Item2_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[3] = ZongMen_Shop_Item3_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[4] = ZongMen_Shop_Item4_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[5] = ZongMen_Shop_Item5_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[6] = ZongMen_Shop_Item6_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[7] = ZongMen_Shop_Item7_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[8] = ZongMen_Shop_Item8_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[9] = ZongMen_Shop_Item9_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[10] = ZongMen_Shop_Item10_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[11] = ZongMen_Shop_Item11_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[12] = ZongMen_Shop_Item12_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[13] = ZongMen_Shop_Item13_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[14] = ZongMen_Shop_Item14_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[15] = ZongMen_Shop_Item15_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[16] = ZongMen_Shop_Item16_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[17] = ZongMen_Shop_Item17_BuyLimitNum
	g_ZongMen_Shop_UI_ItemButLimit[18] = ZongMen_Shop_Item18_BuyLimitNum

	g_ZongMen_Shop_UI_DisCount[1] = ZongMen_Shop_Item1_Discount
	g_ZongMen_Shop_UI_DisCount[2] = ZongMen_Shop_Item2_Discount
	g_ZongMen_Shop_UI_DisCount[3] = ZongMen_Shop_Item3_Discount
	g_ZongMen_Shop_UI_DisCount[4] = ZongMen_Shop_Item4_Discount
	g_ZongMen_Shop_UI_DisCount[5] = ZongMen_Shop_Item5_Discount
	g_ZongMen_Shop_UI_DisCount[6] = ZongMen_Shop_Item6_Discount
	g_ZongMen_Shop_UI_DisCount[7] = ZongMen_Shop_Item7_Discount
	g_ZongMen_Shop_UI_DisCount[8] = ZongMen_Shop_Item8_Discount
	g_ZongMen_Shop_UI_DisCount[9] = ZongMen_Shop_Item9_Discount
	g_ZongMen_Shop_UI_DisCount[10] = ZongMen_Shop_Item10_Discount
	g_ZongMen_Shop_UI_DisCount[11] = ZongMen_Shop_Item11_Discount
	g_ZongMen_Shop_UI_DisCount[12] = ZongMen_Shop_Item12_Discount
	g_ZongMen_Shop_UI_DisCount[13] = ZongMen_Shop_Item13_Discount
	g_ZongMen_Shop_UI_DisCount[14] = ZongMen_Shop_Item14_Discount
	g_ZongMen_Shop_UI_DisCount[15] = ZongMen_Shop_Item15_Discount
	g_ZongMen_Shop_UI_DisCount[16] = ZongMen_Shop_Item16_Discount
	g_ZongMen_Shop_UI_DisCount[17] = ZongMen_Shop_Item17_Discount
	g_ZongMen_Shop_UI_DisCount[18] = ZongMen_Shop_Item18_Discount

	g_ZongMen_Shop_UI_ItemMask[1] = ZongMen_Shop_Item1_Mask
	g_ZongMen_Shop_UI_ItemMask[2] = ZongMen_Shop_Item2_Mask
	g_ZongMen_Shop_UI_ItemMask[3] = ZongMen_Shop_Item3_Mask
	g_ZongMen_Shop_UI_ItemMask[4] = ZongMen_Shop_Item4_Mask
	g_ZongMen_Shop_UI_ItemMask[5] = ZongMen_Shop_Item5_Mask
	g_ZongMen_Shop_UI_ItemMask[6] = ZongMen_Shop_Item6_Mask
	g_ZongMen_Shop_UI_ItemMask[7] = ZongMen_Shop_Item7_Mask
	g_ZongMen_Shop_UI_ItemMask[8] = ZongMen_Shop_Item8_Mask
	g_ZongMen_Shop_UI_ItemMask[9] = ZongMen_Shop_Item9_Mask
	g_ZongMen_Shop_UI_ItemMask[10] = ZongMen_Shop_Item10_Mask
	g_ZongMen_Shop_UI_ItemMask[11] = ZongMen_Shop_Item11_Mask
	g_ZongMen_Shop_UI_ItemMask[12] = ZongMen_Shop_Item12_Mask
	g_ZongMen_Shop_UI_ItemMask[13] = ZongMen_Shop_Item13_Mask
	g_ZongMen_Shop_UI_ItemMask[14] = ZongMen_Shop_Item14_Mask
	g_ZongMen_Shop_UI_ItemMask[15] = ZongMen_Shop_Item15_Mask
	g_ZongMen_Shop_UI_ItemMask[16] = ZongMen_Shop_Item16_Mask
	g_ZongMen_Shop_UI_ItemMask[17] = ZongMen_Shop_Item17_Mask
	g_ZongMen_Shop_UI_ItemMask[18] = ZongMen_Shop_Item18_Mask

	g_ZongMen_Shop_UI_ItemName[1] = ZongMen_Shop_Item1_Text
	g_ZongMen_Shop_UI_ItemName[2] = ZongMen_Shop_Item2_Text
	g_ZongMen_Shop_UI_ItemName[3] = ZongMen_Shop_Item3_Text
	g_ZongMen_Shop_UI_ItemName[4] = ZongMen_Shop_Item4_Text
	g_ZongMen_Shop_UI_ItemName[5] = ZongMen_Shop_Item5_Text
	g_ZongMen_Shop_UI_ItemName[6] = ZongMen_Shop_Item6_Text
	g_ZongMen_Shop_UI_ItemName[7] = ZongMen_Shop_Item7_Text
	g_ZongMen_Shop_UI_ItemName[8] = ZongMen_Shop_Item8_Text
	g_ZongMen_Shop_UI_ItemName[9] = ZongMen_Shop_Item9_Text
	g_ZongMen_Shop_UI_ItemName[10] = ZongMen_Shop_Item10_Text
	g_ZongMen_Shop_UI_ItemName[11] = ZongMen_Shop_Item11_Text
	g_ZongMen_Shop_UI_ItemName[12] = ZongMen_Shop_Item12_Text
	g_ZongMen_Shop_UI_ItemName[13] = ZongMen_Shop_Item13_Text
	g_ZongMen_Shop_UI_ItemName[14] = ZongMen_Shop_Item14_Text
	g_ZongMen_Shop_UI_ItemName[15] = ZongMen_Shop_Item15_Text
	g_ZongMen_Shop_UI_ItemName[16] = ZongMen_Shop_Item16_Text
	g_ZongMen_Shop_UI_ItemName[17] = ZongMen_Shop_Item17_Text
	g_ZongMen_Shop_UI_ItemName[18] = ZongMen_Shop_Item18_Text

	g_ZongMen_Shop_UI_ItemPrice[1] = ZongMen_Shop_Item1_Price
	g_ZongMen_Shop_UI_ItemPrice[2] = ZongMen_Shop_Item2_Price
	g_ZongMen_Shop_UI_ItemPrice[3] = ZongMen_Shop_Item3_Price
	g_ZongMen_Shop_UI_ItemPrice[4] = ZongMen_Shop_Item4_Price
	g_ZongMen_Shop_UI_ItemPrice[5] = ZongMen_Shop_Item5_Price
	g_ZongMen_Shop_UI_ItemPrice[6] = ZongMen_Shop_Item6_Price
	g_ZongMen_Shop_UI_ItemPrice[7] = ZongMen_Shop_Item7_Price
	g_ZongMen_Shop_UI_ItemPrice[8] = ZongMen_Shop_Item8_Price
	g_ZongMen_Shop_UI_ItemPrice[9] = ZongMen_Shop_Item9_Price
	g_ZongMen_Shop_UI_ItemPrice[10] = ZongMen_Shop_Item10_Price
	g_ZongMen_Shop_UI_ItemPrice[11] = ZongMen_Shop_Item11_Price
	g_ZongMen_Shop_UI_ItemPrice[12] = ZongMen_Shop_Item12_Price
	g_ZongMen_Shop_UI_ItemPrice[13] = ZongMen_Shop_Item13_Price
	g_ZongMen_Shop_UI_ItemPrice[14] = ZongMen_Shop_Item14_Price
	g_ZongMen_Shop_UI_ItemPrice[15] = ZongMen_Shop_Item15_Price
	g_ZongMen_Shop_UI_ItemPrice[16] = ZongMen_Shop_Item16_Price
	g_ZongMen_Shop_UI_ItemPrice[17] = ZongMen_Shop_Item17_Price
	g_ZongMen_Shop_UI_ItemPrice[18] = ZongMen_Shop_Item18_Price

	g_ZongMen_Shop_UI_ItemWLimit[1] = ZongMen_Shop_Item1_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[2] = ZongMen_Shop_Item2_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[3] = ZongMen_Shop_Item3_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[4] = ZongMen_Shop_Item4_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[5] = ZongMen_Shop_Item5_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[6] = ZongMen_Shop_Item6_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[7] = ZongMen_Shop_Item7_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[8] = ZongMen_Shop_Item8_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[9] = ZongMen_Shop_Item9_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[10] = ZongMen_Shop_Item10_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[11] = ZongMen_Shop_Item11_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[12] = ZongMen_Shop_Item12_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[13] = ZongMen_Shop_Item13_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[14] = ZongMen_Shop_Item14_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[15] = ZongMen_Shop_Item15_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[16] = ZongMen_Shop_Item16_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[17] = ZongMen_Shop_Item17_Limit1
	g_ZongMen_Shop_UI_ItemWLimit[18] = ZongMen_Shop_Item18_Limit1

	g_ZongMen_Shop_UI_ItemFLimit[1] = ZongMen_Shop_Item1_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[2] = ZongMen_Shop_Item2_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[3] = ZongMen_Shop_Item3_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[4] = ZongMen_Shop_Item4_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[5] = ZongMen_Shop_Item5_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[6] = ZongMen_Shop_Item6_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[7] = ZongMen_Shop_Item7_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[8] = ZongMen_Shop_Item8_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[9] = ZongMen_Shop_Item9_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[10] = ZongMen_Shop_Item10_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[11] = ZongMen_Shop_Item11_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[12] = ZongMen_Shop_Item12_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[13] = ZongMen_Shop_Item13_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[14] = ZongMen_Shop_Item14_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[15] = ZongMen_Shop_Item15_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[16] = ZongMen_Shop_Item16_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[17] = ZongMen_Shop_Item17_Limit2
	g_ZongMen_Shop_UI_ItemFLimit[18] = ZongMen_Shop_Item18_Limit2

	g_ZongMen_Shop_UI_ItemDLimit[1] = ZongMen_Shop_Item1_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[2] = ZongMen_Shop_Item2_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[3] = ZongMen_Shop_Item3_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[4] = ZongMen_Shop_Item4_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[5] = ZongMen_Shop_Item5_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[6] = ZongMen_Shop_Item6_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[7] = ZongMen_Shop_Item7_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[8] = ZongMen_Shop_Item8_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[9] = ZongMen_Shop_Item9_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[10] = ZongMen_Shop_Item10_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[11] = ZongMen_Shop_Item11_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[12] = ZongMen_Shop_Item12_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[13] = ZongMen_Shop_Item13_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[14] = ZongMen_Shop_Item14_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[15] = ZongMen_Shop_Item15_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[16] = ZongMen_Shop_Item16_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[17] = ZongMen_Shop_Item17_Limit3
	g_ZongMen_Shop_UI_ItemDLimit[18] = ZongMen_Shop_Item18_Limit3

    g_ZongMen_Shop_Frame_UnifiedXPosition = ZongMen_Shop_Frame:GetProperty("UnifiedXPosition") 
	g_ZongMen_Shop_Frame_UnifiedYPosition = ZongMen_Shop_Frame:GetProperty("UnifiedYPosition")
end

--************************
-- OnEvent
--************************
function ZongMen_Shop_OnEvent(event)
	if event == "UPDATE_ZONGMEN_SHOPINFO" then
		if arg0 == "show" then
			g_ZongMen_Shop_CurWeek = tonumber(arg1)

			if tonumber(arg2) > 0 then
				g_ZongMen_Shop_ServerObj = tonumber(arg2)
				g_ZongMen_Shop_CareObj = DataPool:GetNPCIDByServerID(g_ZongMen_Shop_ServerObj)
				this:CareObject( g_ZongMen_Shop_CareObj, 1, "ZongMen_Shop" )
			end

			g_ZongMen_Shop_Page1Type = 0
			g_ZongMen_Shop_Page2Type = 0
			g_ZongMen_Shop_BuyingIndex = -1

			local num = GetZongMenShop_ItemsTotalCount(g_ZongMen_Shop_Page1Type,g_ZongMen_Shop_Page2Type)

			if num == 0 then
				g_ZongMen_Shop_CurPage = 0
			else
				g_ZongMen_Shop_CurPage = 1
			end

			for i = 1, 5 do
				g_ZongMen_Shop_FPageLock[i]:Show()
			end

			local zmdzlevel = Player:GetData("ZONGMENDIZILEVEL")
			if zmdzlevel > 5 then
				zmdzlevel = 5
			end
			if zmdzlevel > 0 then
				for i = 1, zmdzlevel do
					g_ZongMen_Shop_FPageLock[i]:Hide()
				end
			end

			ZongMen_Shop_Update()

			this:Show()
		elseif arg0 == "on_buy" then
			if this:IsVisible() then
				g_ZongMen_Shop_BuyingIndex = -1

				ZongMen_Shop_Update()
			end
		elseif arg0 == "on_cancle" then
			g_ZongMen_Shop_BuyingIndex = -1
		end
    elseif event == "UPDATE_YUANBAO" then
		if this:IsVisible() then
			local yuanbao = tostring(Player:GetData("YUANBAO"))
			local ybstr = ScriptGlobal_Format( "#{ZMSD_230625_57}", tostring(yuanbao) )
			ZongMen_Shop_Currency1:SetText(ybstr)
		end
    elseif event == "MONEY_CHANGE_EX" then
		if this:IsVisible() then
			local money = Player:GetData("MONEY")
			local moneystr = ScriptGlobal_Format( "#{ZMSD_230625_59}", tostring(money) )
			ZongMen_Shop_Currency2:SetText(moneystr)
		end
	elseif ( event == "ZONGMEN_DIZILEVEL_UPDATE" ) then
		if arg0 == "con" then
			if (this:IsVisible()) then
				local zmcon = Player : GetData( "ZONGMENCON" )
				if tonumber(zmcon) <= 0 then
					zmcon = 0
				end
				local zmstr = ScriptGlobal_Format( "#{ZMSD_230625_61}", tostring(zmcon) )
				ZongMen_Shop_Currency3:SetText(zmstr)
			end
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
		ZongMen_Shop_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ZongMen_Shop_OnCloseClicked()
    elseif event == "OBJECT_CARED_EVENT" then
		if tonumber(arg0) ~= g_ZongMen_Shop_CareObj then
			return
		end
		if (arg1 == "distance" and tonumber(arg2) > 5) or arg1 == "destroy" then
			ZongMen_Shop_OnCloseClicked()
		end
	end
end

function ZongMen_Shop_Update()
	g_ZongMen_Shop_ItemsInfo = {}
    g_ZongMen_Shop_ItemsInfo = GetZongMenShopData( g_ZongMen_Shop_Page1Type, g_ZongMen_Shop_Page2Type, g_ZongMen_Shop_CurPage, g_ZongMen_Shop_PerPageCount )
	if type(g_ZongMen_Shop_ItemsInfo) ~= "table" then
        PushDebugMessage("ZongMen_Shop_Update failed 0")
		return
    end

    local item_count = table.getn(g_ZongMen_Shop_ItemsInfo)
	if item_count > g_ZongMen_Shop_PerPageCount then
		PushDebugMessage("ZongMen_Shop_Update failed 1")
		return
	end

    for i = 1, item_count do
        g_ZongMen_Shop_UI_Frame[i]:Show()
        ZongMen_Shop_UpdateItemUI(i)
    end

    for i = item_count + 1, g_ZongMen_Shop_PerPageCount do
        g_ZongMen_Shop_UI_Frame[i]:Hide()
    end

	if g_ZongMen_Shop_Page1Type == 0 then
		ZongMen_Shop_UnLockText:SetText("#{ZMSD_230625_18}")
	elseif g_ZongMen_Shop_Page1Type == 1 then
		ZongMen_Shop_UnLockText:SetText("#{ZMSD_230625_22}")
	elseif g_ZongMen_Shop_Page1Type == 2 then
		ZongMen_Shop_UnLockText:SetText("#{ZMSD_230625_26}")
	elseif g_ZongMen_Shop_Page1Type == 3 then
		ZongMen_Shop_UnLockText:SetText("#{ZMSD_230625_39}")
	elseif g_ZongMen_Shop_Page1Type == 4 then
		ZongMen_Shop_UnLockText:SetText("#{ZMSD_230625_46}")
	else
		ZongMen_Shop_UnLockText:SetText("#{ZMSD_230625_18}")
	end

	local num = GetZongMenShop_ItemsTotalCount(g_ZongMen_Shop_Page1Type,g_ZongMen_Shop_Page2Type)
	local totalpage = 0
	if math.mod( tonumber(num), g_ZongMen_Shop_PerPageCount ) == 0 then
		totalpage = math.floor(tonumber(tonumber(num)/g_ZongMen_Shop_PerPageCount))
	else
		totalpage = math.floor(tonumber(tonumber(num)/g_ZongMen_Shop_PerPageCount))+1
	end
	local pagestr = ScriptGlobal_Format( "#{XBGSD_202107_33}", tostring(g_ZongMen_Shop_CurPage), tostring(totalpage) )
	ZongMen_Shop_CurrentlyPage:SetText(pagestr)

	local yuanbao = Player:GetData("YUANBAO")
	local ybstr = ScriptGlobal_Format( "#{ZMSD_230625_57}", tostring(yuanbao) )
	local money = Player:GetData("MONEY")
	local moneystr = ScriptGlobal_Format( "#{ZMSD_230625_59}", tostring(money) )
	local zmcon = Player:GetData("ZONGMENCON")
	local zmstr = ScriptGlobal_Format( "#{ZMSD_230625_61}", tostring(zmcon) )

	ZongMen_Shop_Currency1:SetText(ybstr)
	ZongMen_Shop_Currency2:SetText(moneystr)
	ZongMen_Shop_Currency3:SetText(zmstr)
end

function ZongMen_Shop_UpdateItemUI(i)
	local itemid = g_ZongMen_Shop_ItemsInfo[i].itemid
    local num = g_ZongMen_Shop_ItemsInfo[i].num
    local huobi = g_ZongMen_Shop_ItemsInfo[i].huobi
    local price = g_ZongMen_Shop_ItemsInfo[i].price
    local leftnum = g_ZongMen_Shop_ItemsInfo[i].leftnum
    local zhekou = g_ZongMen_Shop_ItemsInfo[i].zhekou
	local limit_type = g_ZongMen_Shop_ItemsInfo[i].limit_type

	local theAction = DataPool:CreateBindActionItemForShow( itemid, num )
    local actionId = theAction:GetID()
    if actionId ~= 0 then
        g_ZongMen_Shop_UI_ActionButton[i]:SetActionItem(actionId)
    end

	g_ZongMen_Shop_UI_ItemName[i]:SetText(DataPool:Lua_GetItemNameByIndex(itemid))

	local pricestr = ""
	if huobi == 1 then
		pricestr = ScriptGlobal_Format( "#{ZMSD_230625_54}", tostring(price) )
	elseif huobi == 2 then
		pricestr = ScriptGlobal_Format( "#{ZMSD_230625_52}", tostring(price) )
	elseif huobi == 3 then
		pricestr = ScriptGlobal_Format( "#{ZMSD_230625_53}", tostring(price) )
	end

	g_ZongMen_Shop_UI_ItemPrice[i]:SetText(pricestr)

	if zhekou == 1 then
		g_ZongMen_Shop_UI_DisCount[i]:Show()
	else
		g_ZongMen_Shop_UI_DisCount[i]:Hide()
	end

	if leftnum == -1 then
		g_ZongMen_Shop_UI_ItemButLimit[i]:Hide()
		g_ZongMen_Shop_UI_ItemMask[i]:Hide()
		g_ZongMen_Shop_UI_ItemWLimit[i]:Hide()
		g_ZongMen_Shop_UI_ItemFLimit[i]:Hide()
	else
		if leftnum == 0 then
			g_ZongMen_Shop_UI_ItemButLimit[i]:Show()
			g_ZongMen_Shop_UI_ItemButLimit[i]:SetText(tostring(leftnum))
			g_ZongMen_Shop_UI_ItemMask[i]:Show()
		else
			g_ZongMen_Shop_UI_ItemButLimit[i]:Show()
			g_ZongMen_Shop_UI_ItemButLimit[i]:SetText(tostring(leftnum))
			g_ZongMen_Shop_UI_ItemMask[i]:Hide()
		end

		if limit_type == 2 then
			g_ZongMen_Shop_UI_ItemWLimit[i]:Hide()
			g_ZongMen_Shop_UI_ItemFLimit[i]:Show()
			g_ZongMen_Shop_UI_ItemDLimit[i]:Hide()
		elseif limit_type == 1 then
			g_ZongMen_Shop_UI_ItemWLimit[i]:Show()
			g_ZongMen_Shop_UI_ItemFLimit[i]:Hide()
			g_ZongMen_Shop_UI_ItemDLimit[i]:Hide()
		elseif limit_type == 0 then
			g_ZongMen_Shop_UI_ItemWLimit[i]:Hide()
			g_ZongMen_Shop_UI_ItemFLimit[i]:Hide()
			g_ZongMen_Shop_UI_ItemDLimit[i]:Show()
		else
			g_ZongMen_Shop_UI_ItemWLimit[i]:Hide()
			g_ZongMen_Shop_UI_ItemFLimit[i]:Hide()
			g_ZongMen_Shop_UI_ItemDLimit[i]:Hide()
		end
	end
end

function ZongMen_Shop_ChangeShowTab(idx)
	g_ZongMen_Shop_BuyingIndex = -1

	if idx >= 1 and idx <= 5 then
		if g_ZongMen_Shop_Page1Type == (idx-1) then
			return
		end

		g_ZongMen_Shop_Page1Type = idx-1
	else
		g_ZongMen_Shop_Page1Type = 0
	end

	local num = GetZongMenShop_ItemsTotalCount(g_ZongMen_Shop_Page1Type,g_ZongMen_Shop_Page2Type)

	if num == 0 then
		g_ZongMen_Shop_CurPage = 0
	else
		g_ZongMen_Shop_CurPage = 1
	end

	ZongMen_Shop_Update()
end

function ZongMen_Shop_ChangeShowIndex(idx)
	g_ZongMen_Shop_BuyingIndex = -1

	if idx >= 1 and idx <= 2 then
		if g_ZongMen_Shop_Page2Type == (idx-1) then
			return
		end

		g_ZongMen_Shop_Page2Type = idx-1
	else
		g_ZongMen_Shop_Page2Type = 0
	end

	local num = GetZongMenShop_ItemsTotalCount(g_ZongMen_Shop_Page1Type,g_ZongMen_Shop_Page2Type)

	if num == 0 then
		g_ZongMen_Shop_CurPage = 0
	else
		g_ZongMen_Shop_CurPage = 1
	end

	ZongMen_Shop_Update()
end

function ZongMen_Shop_PageUp()
	g_ZongMen_Shop_BuyingIndex = -1

	if g_ZongMen_Shop_CurPage == 1 then
		return
	end

	g_ZongMen_Shop_CurPage = g_ZongMen_Shop_CurPage-1

	if g_ZongMen_Shop_CurPage <= 0 then
		g_ZongMen_Shop_CurPage = 0
	end

	ZongMen_Shop_Update()
end

function ZongMen_Shop_PageDown()
	g_ZongMen_Shop_BuyingIndex = -1

	local num = GetZongMenShop_ItemsTotalCount(g_ZongMen_Shop_Page1Type,g_ZongMen_Shop_Page2Type)

	if g_ZongMen_Shop_CurPage*g_ZongMen_Shop_PerPageCount >= num then
		return
	end

	g_ZongMen_Shop_CurPage = g_ZongMen_Shop_CurPage+1

	ZongMen_Shop_Update()
end

function ZongMen_Shop_ItemButton_Clicked(i)
	local zmlevel = Player:GetData("LEVEL")
	if zmlevel < 60 then
		PushDebugMessage("#{ZMSD_230625_16}")
		return
	end

	if g_ZongMen_Shop_BuyingIndex ~= -1 then
		return
	end

	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end

	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
    end

	if type(g_ZongMen_Shop_ItemsInfo) ~= "table" or g_ZongMen_Shop_ItemsInfo[i] == nil then
	    return
    end

	local zmdzlevel = Player:GetData("ZONGMENDIZILEVEL")
	if g_ZongMen_Shop_Page1Type+1 > zmdzlevel then
		if g_ZongMen_Shop_Page1Type+1 <= 1 then
			PushDebugMessage("#{ZMSD_230625_63}")
		elseif g_ZongMen_Shop_Page1Type+1 == 2 then
			PushDebugMessage("#{ZMSD_230625_64}")
		elseif g_ZongMen_Shop_Page1Type+1 == 3 then
			PushDebugMessage("#{ZMSD_230625_65}")
		elseif g_ZongMen_Shop_Page1Type+1 == 4 then
			PushDebugMessage("#{ZMSD_230625_66}")
		elseif g_ZongMen_Shop_Page1Type+1 == 5 then
			PushDebugMessage("#{ZMSD_230625_67}")
		end
		return
	end

    if g_ZongMen_Shop_ItemsInfo[i].leftnum == 0 then
        PushDebugMessage("#{ZMSD_230625_69}") --该商品已售罄，购买失败。
		return
    end

	local idx = g_ZongMen_Shop_ItemsInfo[i].idx
	local itemid = g_ZongMen_Shop_ItemsInfo[i].itemid
    local itemnum = g_ZongMen_Shop_ItemsInfo[i].num
    local huobi = g_ZongMen_Shop_ItemsInfo[i].huobi
    local price = g_ZongMen_Shop_ItemsInfo[i].price
    local leftnum = g_ZongMen_Shop_ItemsInfo[i].leftnum
    local zhekou = g_ZongMen_Shop_ItemsInfo[i].zhekou
	local limit_type = g_ZongMen_Shop_ItemsInfo[i].limit_type

	local num = GetZongMenShop_MaxNumCanBuy( tonumber(itemid), tonumber(itemnum) )

	if num <= 0 then
        return
    end

	g_ZongMen_Shop_BuyingIndex = i

	PushEvent( "ZONGMEN_SHOPINFO_CONFIRM", idx, 1, g_ZongMen_Shop_CurWeek, g_ZongMen_Shop_ServerObj )

	--PushEvent( "OPEN_YUANBAOSHOP_MULTI_BUYWND", idx, 998611, g_ZongMen_Shop_CareObj, g_ZongMen_Shop_CurWeek, g_ZongMen_Shop_ServerObj )
end

--************************
-- On_ResetPos
--************************
function ZongMen_Shop_On_ResetPos()
	ZongMen_Shop_Frame:SetProperty( "UnifiedXPosition", g_ZongMen_Shop_Frame_UnifiedXPosition )
	ZongMen_Shop_Frame:SetProperty( "UnifiedYPosition", g_ZongMen_Shop_Frame_UnifiedYPosition )
end

function ZongMen_Shop_OnCloseClicked()
	PushEvent("CLOSE_BOOTH") --关闭批量购买窗口Shop_MBuy
	this:Hide()
end

function ZongMen_Shop_OnHidden()
	PushEvent("CLOSE_BOOTH") --关闭批量购买窗口Shop_MBuy
	this:Hide()
end


