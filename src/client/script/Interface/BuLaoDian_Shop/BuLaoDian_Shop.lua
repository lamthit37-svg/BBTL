local g_BuLaoDian_Shop_Frame_UnifiedPosition

-- 商店物品最大数量
local g_BuLaoDian_Shop_MaxItemNum = 9

local g_PageItem_Num = 12

local g_UI_Items = {}

local g_objCared = -1

local g_objID = -1

local MAX_OBJ_DISTANCE = 5.0

local g_DaiBiNum = 0

function BuLaoDian_Shop_PreLoad()
	this:RegisterEvent("TIANJICHENG_OPENSHOP")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function BuLaoDian_Shop_OnLoad()
    g_BuLaoDian_Shop_Frame_UnifiedPosition = BuLaoDian_Shop_Frame:GetProperty("UnifiedPosition")
	for i = 1, g_PageItem_Num do
		g_UI_Items[i] = {}
		g_UI_Items[i].ItemUI = _G["BuLaoDian_Shop_Item"..i]
		g_UI_Items[i].NumUI = _G["BuLaoDian_Shop_Item"..i.."Num"]
		g_UI_Items[i].NameUI = _G["BuLaoDian_Shop_ItemInfo"..i.."_Text"]
		g_UI_Items[i].PriceUI = _G["BuLaoDian_Shop_ItemInfo"..i.."_Price"]
	end
end

function BuLaoDian_Shop_OnEvent(event)
    if event == "TIANJICHENG_OPENSHOP" then--
		g_DaiBiNum = tonumber(arg0)
		local objID = tonumber(arg1)
		if objID < 0 then
			if this:IsVisible() then

			else
				return
			end
		end
		g_objID = objID
		g_objCared = DataPool : GetNPCIDByServerID(tonumber(g_objID))
		if g_objCared == -1 then
			PushDebugMessage("server传过来的数据有问题。")
			return
		end
		if nil ~= g_objCared and g_objCared > 0 then
			this:CareObject(g_objCared, 1, "BuLaoDian_Shop")
		end
		if (this:IsVisible()) then
			BuLaoDian_Main_Update()
			-- 打开背包
			OpenWindow("Packet")
			return
		end
		BuLaoDian_Main_Show()
		BuLaoDian_Main_Update()
		-- 打开背包
		OpenWindow("Packet")

    elseif ( event == "OBJECT_CARED_EVENT" and this:IsVisible() ) then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
        if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
            BuLaoDian_Shop_CloseShop()
        end
	end
    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
			event == "VIEW_RESOLUTION_CHANGED" then
				BuLaoDian_Shop_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            this:Hide()
        end
    end
end

function BuLaoDian_Shop_ResetPos()
    BuLaoDian_Shop_Frame:SetProperty("UnifiedPosition", g_BuLaoDian_Shop_Frame_UnifiedPosition)
end
--显示UI
function BuLaoDian_Main_Show()
	BuLaoDian_Main_ClearData()

	this:Show()
	
end
--隐藏UI
function BuLaoDian_Main_Hide()
    if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "BuLaoDian_Shop")
    end
	BuLaoDian_Main_ClearData()
	this:Hide()
end

--清除数据
function BuLaoDian_Main_ClearData()
	
end
--更新
function BuLaoDian_Main_Update()
	
    BuLaoDian_Shop_Num_Text:SetText(ScriptGlobal_Format("#{TJZF_230525_129}",g_DaiBiNum))
	local tableCount = DiGongShop:Lua_GetTJCPVPShopItemCount()
	if tableCount <= 0 then
		return
	end
	if tableCount >= g_BuLaoDian_Shop_MaxItemNum then
		tableCount = g_BuLaoDian_Shop_MaxItemNum
	end
	local realIndex = 0
	for index = 0, tableCount - 1 do
		local itemIndex, itemId, itemName, isBind, bagType, onceNum, countLimit, dataPos, needNum = DiGongShop:Lua_GetTJCPVPShopItem(index)
		if itemIndex ~= nil and itemIndex > 0 then

			local exchangedNum = DiGongShop:Lua_GetTJCPVPExchangedNum(dataPos)
			local countLeft = countLimit - exchangedNum
			if countLeft < 0 or countLeft >= 255 then
				countLeft = 0
			end
			realIndex = realIndex + 1

			g_UI_Items[realIndex].ItemUI:Enable()
			g_UI_Items[realIndex].ItemUI:SetProperty("Gloom", "false")

			local theAction = DataPool:CreateBindActionItemForShow(itemId, 1)
			if theAction:GetID() ~= 0 then
				g_UI_Items[realIndex].ItemUI:SetActionItem(theAction:GetID())
			end
			if (countLeft <= 0) then
				g_UI_Items[realIndex].ItemUI:SetProperty("Gloom", "true")
				g_UI_Items[realIndex].ItemUI:Disable()
			end

			g_UI_Items[realIndex].NumUI:SetText(tostring(countLeft))

			local itemName = DataPool:Lua_GetItemNameByIndex(itemId)
			g_UI_Items[realIndex].NameUI:SetText(itemName)
			local szNeedNum = ScriptGlobal_Format("#{TJZF_230525_148}", needNum)
			g_UI_Items[realIndex].PriceUI:SetText(szNeedNum)

		end
	end
end

function BuLaoDian_Shop_CloseShop()
	BuLaoDian_Main_Hide()
end

function BuLaoDian_Shop_ItemClicked(index)
    local index = tonumber(index) - 1
    if index < 0 then
        return
    end
	if index >= g_PageItem_Num then
		return
	end

    -- 获取商店物品信息
	local itemIndex, itemId, itemName, isBind, bagType, onceNum, countLimit, dataPos, needNum = DiGongShop:Lua_GetTJCPVPShopItem(index)
    if (itemIndex == nil or itemIndex <= 0) then
        return
    end
	
    local exchangedNum = DiGongShop:Lua_GetTJCPVPExchangedNum(dataPos)
    if (countLimit <= exchangedNum) then
        PushDebugMessage("#{TJZF_230525_131}")
        return
    end
    if (g_DaiBiNum < needNum) then
        -- 代币数量不足
        PushDebugMessage("#{TJZF_230525_132}")
        return
    end

    Clear_XSCRIPT()
        Set_XSCRIPT_ScriptID(998571)
        Set_XSCRIPT_Function_Name("ExchangeItem")
        Set_XSCRIPT_Parameter(0, g_objID)
        Set_XSCRIPT_Parameter(1, itemIndex)
        Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end