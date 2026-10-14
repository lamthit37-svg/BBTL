-- 商店批量兑换
-- -- !!!reloadscript =ChongLou_DaibiShop_Mbuy
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition
local g_objID = 0
local m_ObjCareID = 0
--NPC最大距离
local MAX_OBJ_DISTANCE = 3.0
--代币数量
local CLdaibi_count = 0
--代币类型
local CLdaibi_type = 0
--输入数量
local defaultNum = 1

local maxbuys_count = 1
local itemConfig
local current_lv
local item_id
local itemIndex
local cur_list =
{
	-- [idx] key
	-- id,          item_id,	name,	 show_id,   time_type,	count,		now, 		      price, 	 moneytype,  				gpcount
	-- 表中ID（1）   道具id      道具名称  道具展示id  限时类型    限购数量,    当前以买限购的数量  商品价格   货币类型(0高级 1低级)	    商品数量
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function ChongLou_DaibiShop_Mbuy_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function ChongLou_DaibiShop_Mbuy_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= ChongLou_DaibiShop_Mbuy_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= ChongLou_DaibiShop_Mbuy_Frame:GetProperty("UnifiedYPosition");
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ChongLou_DaibiShop_Mbuy_ResetPos()
	ChongLou_DaibiShop_Mbuy_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	ChongLou_DaibiShop_Mbuy_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end

--响应事件的函数，当注册的事件发生时会调用的函数
function ChongLou_DaibiShop_Mbuy_OnEvent(event)

	if event == "UI_COMMAND" then
		if tonumber(arg0) == 88843103 then
			--上 需要
			--下 拥有
			if Get_XParam_STR(0) == "REFRESH_HIGHLOW_SHOW" then --高级代币和低级代币有变动
				-- Get_XParam_INT(0) --货币类型
				-- Get_XParam_INT(1) --玩家拥有数量
				-- Get_XParam_STR(0) --字符
				if this:IsVisible() then
					--代币类型
					CLdaibi_type = Get_XParam_INT(0)
					--玩家拥有数量
					CLdaibi_count = Get_XParam_INT(1)
					if itemConfig.moneytype == CLdaibi_type then
						ChongLou_DaibiShop_Mbuy_Show(true)
					end					     
				end
			else
				-- Get_XParam_INT(0) --货币类型
				-- Get_XParam_INT(1) --玩家拥有数量
				-- Get_XParam_INT(2) --targetId
				-- Get_XParam_INT(3) --item_id
				-- Get_XParam_INT(4) --商店等级
				-- Get_XParam_INT(5) --itemIndex 索引
				CLdaibi_count = Get_XParam_INT(1)
				g_objID = Get_XParam_INT(2)--objID
				m_ObjCareID = DataPool : GetNPCIDByServerID(tonumber(g_objID))
				item_id = Get_XParam_INT(3)
				current_lv = Get_XParam_INT(4)
				itemIndex =  Get_XParam_INT(5)

				cur_list =  DataPool:LuaFnGetChongLouShopByLv(current_lv)
				local cnt = table.getn(cur_list)
				for idx = 1, cnt do
					local item = cur_list[idx]
					if item.id == itemIndex then
						itemConfig = item
						break
					end
				end

				ChongLou_DaibiShop_ShowBuyItemInfotmation()
				ChongLou_DaibiShop_Mbuy_Show(false)
				OpenWindow("Packet")
			end
		end
	-- elseif event == "PACKAGE_ITEM_CHANGED_EX" then
	-- 	ChongLou_DaibiShop_Mbuy_UpdateHaveItem()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ChongLou_DaibiShop_Mbuy_Hide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ChongLou_DaibiShop_Mbuy_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		ChongLou_DaibiShop_Mbuy_ResetPos()
	elseif event == "OBJECT_CARED_EVENT" then
		ChongLou_DaibiShop_Mbuy_CareEvent(arg0,arg1,arg2)
	end

end

--显示UI
function ChongLou_DaibiShop_Mbuy_Show(referes)
	if referes == false then
		defaultNum = 1
	else
		if tonumber(defaultNum) == nil or defaultNum < 1 then
            defaultNum = 1
        end
	end
	
	maxbuys_count = 1

	-- --最大数量
	ChongLou_DaibiShop_Mbuy_InputNum:SetProperty("DefaultEditBox", "True")
	ChongLou_DaibiShop_Mbuy_InputNum:SetText(tostring(defaultNum))
	ChongLou_DaibiShop_Mbuy_InputNum:SetSelected( 0, -1 )

    local haveNum = CLdaibi_count
	local cost = itemConfig.price * defaultNum

	if cost > 0 then
        if itemConfig.time_type == 0 then --不限购
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

	this:CareObject(m_ObjCareID, 1, "ChongLou_DaibiShop_Mbuy");
	this:Show()

end

--隐藏UI
function ChongLou_DaibiShop_Mbuy_Hide()
	ChongLou_DaibiShop_Mbuy_ClearData()
	ChongLou_DaibiShop_Mbuy_InputNum:SetProperty("DefaultEditBox", "False");
	this:Hide()
end

--清除数据
function ChongLou_DaibiShop_Mbuy_ClearData()
	defaultNum = 1
	CLdaibi_type = 0
end

function ChongLou_DaibiShop_ShowBuyItemInfotmation()

    --icon
    local action_item = DataPool:CreateActionItemForShow(itemConfig.item_id,itemConfig.gpcount)
    if action_item:GetID() ~= 0 then
        ChongLou_DaibiShop_Mbuy_Item:SetActionItem(action_item:GetID())
    end

	--道具名称   #Y
	ChongLou_DaibiShop_Mbuy_ItemInfo_Text:SetText("#cfff263"..action_item:GetName())
	
    local strPrice = ""
    local needCostName = ""
    local ownHaveName = ""
    local cost =  itemConfig.price * defaultNum
	local samplePrice = itemConfig.price
	local haveNum = CLdaibi_count
	
    if itemConfig.moneytype == 1 then
        strPrice = ScriptGlobal_Format("#{CLDHDB_210510_15}",samplePrice)--玲珑华璧
        needCostName = "#{CLDHDB_210510_26}"--需要玲珑华璧：
        ownHaveName = "#{CLDHDB_210510_28}"--拥有玲珑华璧：
    elseif itemConfig.moneytype == 2 then
        strPrice = ScriptGlobal_Format("#{CLDHDB_210510_16}",samplePrice)--玲珑白玉
        needCostName = "#{CLDHDB_210510_27}"--需要玲珑白玉：
        ownHaveName = "#{CLDHDB_210510_29}"--拥有玲珑白玉：
    end
	--单价
    ChongLou_DaibiShop_Mbuy_ItemInfo_GB:SetText(strPrice)

    --需要货币
	ChongLou_DaibiShop_Mbuy_Price:SetText(needCostName)
	--需要货币数量
	ChongLou_DaibiShop_Mbuy_Price_Yuanbao:SetText("#cfff263"..cost)


    ChongLou_DaibiShop_Mbuy_Cash:SetText(ownHaveName)
    ChongLou_DaibiShop_Mbuy_Cash_Yuanbao:SetText("#cfff263"..haveNum)
 
end

--##############点击事件##############
function ChongLou_DaibiShop_Mbuy_Close_Clicked()
	ChongLou_DaibiShop_Mbuy_Hide()
end

function ChongLou_DaibiShop_Mbuy_TextChanged()
	local nString = ChongLou_DaibiShop_Mbuy_InputNum:GetText()
	
    if nString == nil or nString == "" then
        -- PushDebugMessage("nString + === nil")
        defaultNum = 0
        ChongLou_DaibiShop_ShowBuyItemInfotmation()
		return
	end
		
	local nBuysNum = tonumber(nString)
    if nBuysNum == nil then
        -- PushDebugMessage("nString  === error")
        defaultNum = 0
        ChongLou_DaibiShop_ShowBuyItemInfotmation()
		return
    end
    
    if nBuysNum > maxbuys_count then
        defaultNum = maxbuys_count
        ChongLou_DaibiShop_Mbuy_InputNum:SetText(defaultNum)
        ChongLou_DaibiShop_ShowBuyItemInfotmation()
        -- PushDebugMessage("nString  === max")
        return
    end

    defaultNum = nBuysNum
    ChongLou_DaibiShop_ShowBuyItemInfotmation()
end

function ChongLou_DaibiShop_Mbuy_CalMax()
	ChongLou_DaibiShop_Mbuy_InputNum:SetText(maxbuys_count)
end

function ChongLou_DaibiShop_Mbuy_BuyMulti_Clicked()
	if defaultNum <= 0 then
        PushDebugMessage("#{CLDHDB_210510_41}")
        return
    end

    this:Hide()
    Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888431)
		Set_XSCRIPT_Function_Name("MBuyConfirm")
		Set_XSCRIPT_Parameter(0, g_objID)
		Set_XSCRIPT_Parameter(1, itemConfig.id)
		Set_XSCRIPT_Parameter(2, defaultNum)
		Set_XSCRIPT_ParamCount(3)
    Send_XSCRIPT()
end
--####################################

function ChongLou_DaibiShop_Mbuy_CareEvent(arg0,arg1,arg2)
	local ObjCaredID = tonumber(arg0)
	if( ObjCaredID ~= m_ObjCareID) then
		return
	end
	local ObjDistance = tonumber(arg2)
	if( (arg1 == "distance" and ObjDistance > MAX_OBJ_DISTANCE) or arg1=="destroy") then
		ChongLou_DaibiShop_Mbuy_Hide()
	end
end