local g_DiGong_Shop_Frame_UnifiedPosition

local g_PageItem_Num = 18

local g_UI_Items = {}

local g_UICOMMAND = 88886401

local g_ExeScript = 888864

local g_CurShopID = 0 --1,2,4

local g_ShopInfo = {} --[i] = itemIndex,itemID,itemName,shopID,onceNum,countLimit,countNow,needNum

local g_objCared = -1

local g_objID = -1

local MAX_OBJ_DISTANCE = 5.0

local g_PriceFormat = {
    -- [1] = {ItemID1 =38006331,ItemID2 =38006331,price="#{JDQL_230322_148}",show="#{JDQL_230322_148}",disc="#{JDQL_230322_129}"}, --通天暗火
    [1] = {ItemID1 =38006332,ItemID2 =38006332,price="#{JDQL_230322_149}",show="#{JDQL_230322_149}",disc="#{JDQL_230322_128}"}, --通天赤炎
}
local g_DaiBiNum = 0

local g_TimeState = 0

local g_mutiBuyIndex = 0 

function DiGong_Shop_PreLoad()
    this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("UPDATE_DIGONG_SHOP",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
    this:RegisterEvent("PACKAGE_ITEM_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function DiGong_Shop_OnLoad()
    g_DiGong_Shop_Frame_UnifiedPosition = DiGong_Shop_Frame:GetProperty("UnifiedPosition")
    g_UI_Items.ItemInfo  = {}
    for i=1,g_PageItem_Num do
        g_UI_Items.ItemInfo[i]={}
        g_UI_Items.ItemInfo[i].actionBtn = _G["DiGong_Shop_Item"..i]
        g_UI_Items.ItemInfo[i].itemName = _G[string.format("DiGong_Shop_ItemInfo%d_Text",i )]
        g_UI_Items.ItemInfo[i].itemPrice = _G[string.format("DiGong_Shop_ItemInfo%d_Price",i )]
        g_UI_Items.ItemInfo[i].quota = _G[string.format("DiGong_Shop_ItemInfo%d_Quota",i )]
    end
    g_UI_Items.Daibi = DiGong_Shop_Num_Text
    g_UI_Items.Disc = DiGong_Shop_F5_Text
end

--地宫商店 shopid:1,2,4 对应着地宫代币1,2,4  没有3
local function OpenShop(shopId,daibiNum)
    if nil == g_PriceFormat[shopId] then
        return
    end
    if g_TimeState ~= 1 and g_TimeState ~= 2 then
        return
    end
    g_CurShopID = shopId
    g_DaiBiNum = daibiNum
    DiGong_Shop_DragTitle:SetText("#{JDQL_230322_131}")
    g_UI_Items.Daibi:SetText(ScriptGlobal_Format(g_PriceFormat[shopId].show,daibiNum))
    g_UI_Items.Disc:SetText(g_PriceFormat[shopId].disc)
    g_ShopInfo = DiGongShop:Lua_GetDiGongShop(shopId) 
    local cnt = table.getn(g_ShopInfo)
    for i = 1, g_PageItem_Num do
        if i <= cnt then
            local itemInfo = g_ShopInfo[i]
            if itemInfo.shopID == shopId then
                local itemID = itemInfo.itemID
                local itemName = itemInfo.itemName
                local countLimit = itemInfo.countLimit
                local countNow = itemInfo.countNow
                local needNum = itemInfo.needNum
                local onceNum = itemInfo.onceNum
                if countLimit == -1 then
                    --不限量
                    g_UI_Items.ItemInfo[i].quota:Hide()
                    local theAction = DataPool:CreateBindActionItemForShow(itemID,onceNum)
                    if theAction:GetID() ~= 0 then
                        g_UI_Items.ItemInfo[i].actionBtn:SetActionItem(theAction:GetID())
                    end
                else
                    g_UI_Items.ItemInfo[i].quota:Show()
                    local countLeft = countLimit-countNow --剩余数量
                    if countLeft < 0 or countLeft > 255 then
                        countLeft = 0
                    end
                    --图标以及剩余数量
                    local theAction = DataPool:CreateBindActionItemForShowWithMaxNum(itemID,onceNum,countLeft)
                    if theAction:GetID() ~= 0 then
                        g_UI_Items.ItemInfo[i].actionBtn:SetActionItem(theAction:GetID())
                    end
                    if countLeft == 0 then
                        g_UI_Items.ItemInfo[i].actionBtn:SetProperty("Gloom", "true")
                    else
                        g_UI_Items.ItemInfo[i].actionBtn:SetProperty("Gloom", "False")
                    end
                end
                --价格
                g_UI_Items.ItemInfo[i].itemPrice:SetText(ScriptGlobal_Format(g_PriceFormat[shopId].price,needNum))
                --商品名
                g_UI_Items.ItemInfo[i].itemName:SetText(itemName)
            end
        else
            --空btn
            g_UI_Items.ItemInfo[i].itemPrice:SetText("")
            g_UI_Items.ItemInfo[i].itemName:SetText("")
            g_UI_Items.ItemInfo[i].quota:Hide()
        end
    end
    if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 1, "DiGong_Shop")
    end
    this:Show()
    --如果批量购买打开着 也刷新它
    if IsWindowShow("DiGong_Shop_BulkBuying") then
        DiGong_Shop_OpenMutiBuy(g_mutiBuyIndex)
    end
end

local function AskOpenShop()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(g_ExeScript)
    Set_XSCRIPT_Function_Name("OpenShop")
    Set_XSCRIPT_Parameter(0, g_CurShopID)
    Set_XSCRIPT_Parameter(1, g_objID)
    Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end

local function CleanShop()
    g_CurShopID = 0
    g_DaiBiNum = 0
    g_TimeState = 0
    g_ShopInfo = {}
    for k, v in pairs(g_UI_Items.ItemInfo) do
        v.actionBtn:SetActionItem(-1)
    end
end

function DiGong_Shop_CloseShop()
    CleanShop()
    if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "DiGong_Shop")
    end
    g_objID = -1
    g_objCared= -1
    g_mutiBuyIndex = 0
    --关闭二次确认
    PushEvent("DIGONGSHOP_CONFIRM")
    if IsWindowShow("DiGong_Shop_BulkBuying") then
        CloseWindow("DiGong_Shop_BulkBuying", true)
    end
    this:Hide()
end


function DiGong_Shop_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
        --打开地宫商店
        local shopId = Get_XParam_INT(0)
        local daibiNum = Get_XParam_INT(1)
        g_objID = Get_XParam_INT(2)
        g_objCared = DataPool : GetNPCIDByServerID(tonumber(g_objID))
        CleanShop()
        g_TimeState = Get_XParam_INT(3)
        OpenShop(shopId,daibiNum)
        OpenWindow("Packet")
    elseif event == "UPDATE_DIGONG_SHOP" and this:IsVisible() then
        AskOpenShop()
    elseif ( event == "OBJECT_CARED_EVENT" and this:IsVisible() ) then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
        if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
            DiGong_Shop_CloseShop()
        end
    elseif event == "PACKAGE_ITEM_CHANGED"  and this:IsVisible() then
        if (arg0 == nil ) then
			return
        end
        local changeItemindex = tonumber(arg0)
        if -1 == changeItemindex or nil == changeItemindex then
            AskOpenShop()
            return
        end
        if PlayerPackage:GetItemTableIndex(changeItemindex) == g_PriceFormat[g_CurShopID].ItemID1 or 
            PlayerPackage:GetItemTableIndex(changeItemindex)== g_PriceFormat[g_CurShopID].ItemID2 then
            AskOpenShop()
            return
        end
    end

    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
			event == "VIEW_RESOLUTION_CHANGED" then
				DiGong_Shop_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            this:Hide()
        end
    end
end


function DiGong_Shop_BuyMult()
	PrepearBuyMult()
end
function DiGong_Shop_OpenMutiBuy(index)
    if g_ShopInfo[index] ~= nil then
        g_mutiBuyIndex = index
        local maxNum = -1
        if  g_ShopInfo[index].countLimit > 0 then
            if g_ShopInfo[index].countLimit < g_ShopInfo[index].countNow then
                return 
            end
            maxNum = g_ShopInfo[index].countLimit - g_ShopInfo[index].countNow
        end
        PushEvent("DIGONG_SHOP_MITYBUY",
        g_ShopInfo[index].needNum,
        g_ShopInfo[index].itemID,
        g_CurShopID,
        g_objID,
        g_DaiBiNum,
        maxNum,
        g_ShopInfo[index].onceNum,
        g_ShopInfo[index].itemName,
        g_ShopInfo[index].itemIndex)
    end
end

function DiGong_Shop_ItemClicked(index)
    local mutiBuy = DiGongShop:CheckIsMultiBuy()
    if mutiBuy == 1 then
        DiGong_Shop_OpenMutiBuy(index)
    else
        if g_ShopInfo[index] ~= nil then
            Clear_XSCRIPT()
            Set_XSCRIPT_ScriptID(g_ExeScript)
            Set_XSCRIPT_Function_Name("BuyItem")
            Set_XSCRIPT_Parameter(0, g_ShopInfo[index].itemIndex)
            Set_XSCRIPT_Parameter(1, g_ShopInfo[index].itemID)
            Set_XSCRIPT_Parameter(2, g_ShopInfo[index].shopID)
            Set_XSCRIPT_Parameter(3, g_objID)
            Set_XSCRIPT_Parameter(4, 1)
            Set_XSCRIPT_ParamCount(5)
            Send_XSCRIPT()
        end
    end
    
end

function DiGong_Shop_ResetPos()
    DiGong_Shop_Frame:SetProperty("UnifiedPosition", g_DiGong_Shop_Frame_UnifiedPosition)
end