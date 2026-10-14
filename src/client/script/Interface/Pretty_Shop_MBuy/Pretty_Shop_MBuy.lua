local adjest_pos
local item_id
local current_lv
local itemConfig
local cur_list
local jiaozi_count
local yaohuabi_count
local defaultNum = 1
local maxbuys_count = 1
local g_ZNQ_OPEN = 1

--临时折扣最大力度
local g_DiscountMax = 5

--周年庆时间
local g_ZNQ_LimitDate = {
	20210422,
	20210512,
}

local g_ZNQ_TIPS_CHECKID =  38005256

function Pretty_Shop_MBuy_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("UPDATE_REDPOINT_IN_UI",false)
    this:RegisterEvent("CLOSE_MYSELF_PRETTYBUY",false)
    this:RegisterEvent("UPDATE_YUANBAO", false)
    this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
    this:RegisterEvent("MONEY_CHANGE_EX", false)
end

function Pretty_Shop_MBuy_OnLoad()
	adjest_pos = Pretty_Shop_MBuy_Frame:GetProperty("UnifiedPosition")
end

--***************************************************
--获取折扣数值和最小值、最大值、折扣次数已经用光则为1
--***************************************************
local function ZNQ_OnGetDiscount()
	local nowday = tonumber(DataPool:GetServerDayTime())
	local curData = WGAch:GetCJMaxCur()
	local nMDData = curData.param1
	local nMDDay = math.floor(nMDData/10000)
	local nTodaySHFlag = 0
	if nowday == nMDDay then
		nTodaySHFlag = 1
	end
	local nMDCurDiscount = math.mod(nMDData,100)
	return 100-nMDCurDiscount, 100-g_DiscountMax, nTodaySHFlag
end

--**********************************
--是否处于活动时间 
--**********************************
local function ZNQ_CheckRightTime()
	local today = tonumber(DataPool:GetServerDayTime())
	if today >= g_ZNQ_LimitDate[1] and today <= g_ZNQ_LimitDate[2]  then
		return 1
	end
	
	if today < g_ZNQ_LimitDate[1] then
		return -1
	end
	
	if today > g_ZNQ_LimitDate[2] then
		return -2
	end
	return 0
end

local function PrettyShowBuyItemInfotmation()

    local action_item = DataPool:CreateActionItemForShow(itemConfig.item_id,itemConfig.gpcount)
    if action_item:GetID() ~= 0 then
        Pretty_Shop_MBuy_But:SetActionItem(action_item:GetID())
    end

    --道具名称   #Y
    Pretty_Shop_MBuy_ItemInfo_Text:SetText(ScriptGlobal_Format("#{WGPF_210226_31}",action_item:GetName()))
    local fmtCut = itemConfig.sellcut/100
    local strPrice = ""
    local needCostName = ""
    local ownHaveName = ""
    local cost =  itemConfig.price*fmtCut * defaultNum

    local samplePrice = itemConfig.price*fmtCut
    if g_ZNQ_OPEN == 1 then
        if ZNQ_CheckRightTime() == 1 and itemConfig.item_id == g_ZNQ_TIPS_CHECKID then
            local ranDis,ranDisMax,disUsed = ZNQ_OnGetDiscount()
            cost =cost *ranDis*0.01

            samplePrice = samplePrice * ranDis*0.01
        end
    end

    local haveNum = 0
    if itemConfig.moneytype == 0 then
        strPrice = ScriptGlobal_Format("#{WGPF_210226_32}",samplePrice)
        needCostName = "#{WGPF_210226_43}"
        haveNum = Player:GetData("YUANBAO")
        ownHaveName = "#{WGPF_210226_46}"
    elseif itemConfig.moneytype == 1 then
        strPrice = ScriptGlobal_Format("#{WGPF_210226_33}",samplePrice)
        needCostName = "#{WGPF_210226_44}"
        haveNum = jiaozi_count
        ownHaveName = "#{WGPF_210226_47}"
    elseif itemConfig.moneytype == 2 then
        strPrice = ScriptGlobal_Format("#{WGPF_210226_34}", samplePrice)
        needCostName = "#{WGPF_210226_45}"
        haveNum = yaohuabi_count
        ownHaveName = "#{WGPF_210226_48}"
    end

    Pretty_Shop_MBuy_ItemInfo_Lilianzhi:SetText(strPrice)

    --需要货币
    Pretty_Shop_MBuy_Price:SetText(needCostName)


    Pretty_Shop_MBuy_Cash:SetText(ownHaveName)
    Pretty_Shop_MBuy_Cash_Lilianzhi:SetText("#cffe1b8"..haveNum)

    if  itemConfig.moneytype == 1 then
        Pretty_Shop_MBuy_Cash_Lilianzhi:Hide()
        Pretty_Shop_MBuy_Cash:Hide()

        --需要货币数量
        Pretty_Shop_MBuy_Price_Lilianzhi:SetText(ScriptGlobal_Format("#{WGPF_210226_49}", cost))
    else
        Pretty_Shop_MBuy_Cash_Lilianzhi:Show()
        Pretty_Shop_MBuy_Cash:Show()

        --需要货币数量
        Pretty_Shop_MBuy_Price_Lilianzhi:SetText("#cffe1b8"..cost)
    end
end

function Pretty_Shop_MBuy_OnEvent(event)
    if event == "UI_COMMAND" then
        local cmd = tonumber(arg0)

        if cmd == 88840502 then
            if this:IsVisible() then
                if Get_XParam_STR(0) == "REFERES_YAOHUABI_SHOW" then
                    if itemConfig.moneytype == 2 then
                        local huayaobi = Get_XParam_INT(1)		
                        --当前拥有的代币
                        yaohuabi_count = huayaobi
                        Init_Pretty_Shop_MBuy(true)
                    end
                elseif  Get_XParam_STR(0) == "OPEN_SHOP_MBUY" then
                    item_id = Get_XParam_INT(0)
                    current_lv = Get_XParam_INT(1)
                    cur_list = WGAch:GetShopByLv(current_lv)
        
                    local cnt = table.getn(cur_list)
                    for idx = 1, cnt do
                        local item = cur_list[idx]
                        if item.item_id == item_id then
                            itemConfig = item
                            break
                        end
                    end
        
                    jiaozi_count = Get_XParam_INT(2) /10000
                    yaohuabi_count = Get_XParam_INT(3)
                    PrettyShowBuyItemInfotmation()
                    Init_Pretty_Shop_MBuy(false)
                end
            else
                if Get_XParam_STR(0) == "OPEN_SHOP_MBUY" then
                    this:Show()
                    item_id = Get_XParam_INT(0)
                    current_lv = Get_XParam_INT(1)
                    cur_list = WGAch:GetShopByLv(current_lv)
        
                    local cnt = table.getn(cur_list)
                    for idx = 1, cnt do
                        local item = cur_list[idx]
                        if item.item_id == item_id then
                            itemConfig = item
                            break
                        end
                    end
        
                    jiaozi_count = Get_XParam_INT(2) /10000
                    yaohuabi_count = Get_XParam_INT(3)
                    PrettyShowBuyItemInfotmation()
                    Init_Pretty_Shop_MBuy(false)
                end
            end
        end

    elseif event == "UPDATE_YUANBAO"  then
        if this:IsVisible() then
            if itemConfig.moneytype  == 0 then
                yaohuabi_count = Player:GetData("YUANBAO")
                Init_Pretty_Shop_MBuy(true)
            end
        end
    elseif event == "MONEYJZ_CHANGE_EX" or event == "MONEY_CHANGE_EX" then
        if itemConfig.moneytype  == 1 then
            if this:IsVisible() then
                jiaozi_count   = math.floor(Player:GetData("MONEY_JZ")/10000)
                Init_Pretty_Shop_MBuy(true)
            end
        end
    elseif event == "CLOSE_MYSELF_PRETTYBUY" then
        if this:IsVisible() then
            Pretty_Shop_MBuy_OnHidden()
        end
    end
    
    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            this:Hide()
        end
    end
end



function Init_Pretty_Shop_MBuy(referes)
    if referes == false then
        defaultNum = 1
    else
        if tonumber(defaultNum) == nil or defaultNum < 1 then
            defaultNum = 1
        end
    end

    maxbuys_count = 1

    -- --最大数量
    Pretty_Shop_MBuy_InputNum:SetProperty("DefaultEditBox", "True")
    Pretty_Shop_MBuy_InputNum:SetText(tostring(defaultNum))
    Pretty_Shop_MBuy_InputNum:SetSelected( 0, -1 )

    local fmtCut = itemConfig.sellcut * 0.01
    local haveNum = 0
    local cost = itemConfig.price*fmtCut * defaultNum
    cost = tonumber(string.format("%.2f",cost))

    if itemConfig.moneytype == 0 then
        haveNum = Player:GetData("YUANBAO")
        	--周年庆特写
        if g_ZNQ_OPEN == 1 then
			if ZNQ_CheckRightTime() == 1 and itemConfig.item_id == g_ZNQ_TIPS_CHECKID then
        		local ranDis,ranDisMax,disUsed = ZNQ_OnGetDiscount()
        		cost =cost *ranDis*0.01
            end
        end

    elseif itemConfig.moneytype == 1 then
        haveNum = jiaozi_count + Player:GetData("MONEY") /10000
            
    elseif itemConfig.moneytype == 2 then
        haveNum = yaohuabi_count
    end

    local layNum = DataPool:Lua_GetLayNumByIndex(itemConfig.item_id)

    if cost > 0 then
        if itemConfig.count == -1 then --不限购
            maxbuys_count = math.floor(haveNum /cost)
        else
            if itemConfig.count - itemConfig.now >= 0 then  --限购剩余可买的数量
                local mn =  math.floor(haveNum /cost)  --当前币可以买的最多数量
                local cmax = itemConfig.count - itemConfig.now  --限购后还可以买的数量
                maxbuys_count = math.min(mn,cmax)  --币可以买的数量  和限购可以买的数量 取最小值
            else
                maxbuys_count = 0
            end
        end
    else
        maxbuys_count = itemConfig.count - itemConfig.now
    end

    --layNum 叠加的最大数量 要减去 背包里面该道具已经拥有的数量
    local nNum =  0
    if layNum > 1 then
        local nowNum = Pretty_Shop_MBuy_GetItemCountByID(itemConfig.item_id)
        local modNum = math.mod(nowNum,layNum)
        if modNum > 0 then
            nNum = layNum - modNum
        end
    end

    --在和背包剩余格数来取最小的
    local bagSpace =  Pretty_Shop_MBuy_GetAddNum(itemConfig.item_id,layNum,itemConfig.bagType)
    maxbuys_count =  math.min(maxbuys_count,bagSpace)
    
    -- PushDebugMessage("背包里面已经有 { "..nNum.."}")
    -- PushDebugMessage("现在还可以购买 { "..maxbuys_count.."}")
    -- PushDebugMessage("背包还可以装下 { "..bagSpace.."}")

    if itemConfig.count == -1 then
        Pretty_Shop_MBuy_Num:Hide()
        Pretty_Shop_MBuy_NumBK:Hide()
    else
        Pretty_Shop_MBuy_NumBK:Show()
        Pretty_Shop_MBuy_Num:Show()
        Pretty_Shop_MBuy_Num:SetText(itemConfig.count - itemConfig.now)
    end
end

function Pretty_Shop_MBuy_GetItemCountByID(nItemId)
    return PlayerPackage:CountAvailableItemByIDTable(nItemId) + PlayerPackage:Lua_GetLockItemCount(nItemId)
end

function Pretty_Shop_MBuy_GetAddNum(nItemId,layNum,bagType)
    -- local addNum = 0
    -- local diffNum= 0
    -- for i = 1,20 do
    --     local newIndex = i - 1
    --     local itemID = PlayerPackage:GetItemTableIndex(newIndex)
    --     if itemID == nItemId or itemID == -1 then
    --         if itemID == - 1 then
    --             diffNum = layNum
    --         else
    --             local itemNum =  PlayerPackage:GetBagItemNum(newIndex) -- 当前数量
    --             diffNum = layNum - itemNum
    --         end
    --         addNum = addNum + diffNum
    --     end
 
    -- end
    -- return addNum
    return PlayerPackage:GetAddItemMaxNum(nItemId,layNum,bagType)
end

function Pretty_Shop_MBuy_ResetPos()
    Pretty_Shop_MBuy_Frame:SetProperty("UnifiedPosition", adjest_pos)
end
 
function Pretty_Shop_MBuy_TextChanged()
    local nString = Pretty_Shop_MBuy_InputNum:GetText()
	
    if nString == nil or nString == "" then
        -- PushDebugMessage("nString + === nil")
        -- Pretty_Shop_MBuy_InputNum:SetProperty("DefaultEditBox", "True")
        -- Pretty_Shop_MBuy_InputNum:SetText("1")
        -- Pretty_Shop_MBuy_InputNum:SetSelected( 0, -1 )
        defaultNum = 0
        PrettyShowBuyItemInfotmation()
		return
	end
		
	local nBuysNum = tonumber(nString)
    if nBuysNum == nil then
        -- Pretty_Shop_MBuy_InputNum:SetText("1")
        -- Pretty_Shop_MBuy_InputNum:SetSelected( 0, -1 )
        -- PushDebugMessage("nString  === error")
        defaultNum = 0
        PrettyShowBuyItemInfotmation()
		return
    end
    
    if nBuysNum > maxbuys_count then
        defaultNum = maxbuys_count
        Pretty_Shop_MBuy_InputNum:SetText(defaultNum)
        PrettyShowBuyItemInfotmation()
        -- PushDebugMessage("nString  === max")
        return
    end

    defaultNum = nBuysNum
    PrettyShowBuyItemInfotmation()
end

--最大数量
function Pretty_Shop_MBuy_CalMax()
    Pretty_Shop_MBuy_InputNum:SetText(maxbuys_count)
end

--确定
function Pretty_Shop_MBuy_OK_Clicked()
    if defaultNum <= 0 then
        PushDebugMessage("#{WGPF_210226_41}")
        return
    end

    this:Hide()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(888051)
    Set_XSCRIPT_Function_Name("WaiGuanConfirmShopBuy")
    Set_XSCRIPT_Parameter(0, itemConfig.id)
    Set_XSCRIPT_Parameter(1, defaultNum)
    Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end

--关闭
function Pretty_Shop_MBuy_Close_Clicked()
    this:Hide()
end


function Pretty_Shop_MBuy_OnHidden()
    this:Hide()
end