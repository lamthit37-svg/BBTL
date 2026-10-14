
-- 三选一 UI

-- 服务器脚本号
local GoldRecycle_GiftShop_ServerScriptId = 888973

local GoldRecycle_GiftShop_UnifiedPosition = nil

-- UICommand
local GoldRecycle_GiftShop_UICommand = 88897301
local GoldRecycle_GiftShop_UICommandType =
{
    Type_CloseUI = 0,               -- 关闭UI
    Type_OpenUI = 1,                -- 打开UI
}

-- 当前已选择的物品索引
local g_GoldRecycle_GiftShop_choose = -1

-- 当前物品的背包位置
local g_GoldRecycle_GiftShop_BagIndex = -1

-- 调用脚本号
local GoldRecycle_GiftShop_ScriptId = -1

-- 物品展示控件列表
local GoldRecycle_GiftShop_AwardControl = {}
-- 物品名字列表
local GoldRecycle_GiftShop_AwardNameControl = {}
-- 物品已获得控件列表
local GoldRecycle_GiftShop_AwardGotControl = {}
-- 物品选中控件列表
local GoldRecycle_GiftShop_AwardchooseControl = {}
-- 物品消耗控件列表
local GoldRecycle_GiftShop_CostControl = {}

-- 最小使用等级
local GoldRecycle_GiftShop_MinLevel = 90

function GoldRecycle_GiftShop_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function GoldRecycle_GiftShop_OnLoad()	

	GoldRecycle_GiftShop_UnifiedPosition = GoldRecycle_GiftShop_Frame_BK:GetProperty("UnifiedPosition")	
	
end

function GoldRecycle_GiftShop_OnEvent(event)

    if (event == "UI_COMMAND" and tonumber(arg0) == GoldRecycle_GiftShop_UICommand) then
        local type = Get_XParam_INT(0)
        if (type == GoldRecycle_GiftShop_UICommandType.Type_OpenUI) then
		
            GoldRecycle_GiftShop_OnShow()
			
			GoldRecycle_GiftShop_ScriptId = Get_XParam_INT(1)
			
            g_GoldRecycle_GiftShop_BagIndex= Get_XParam_INT(2)
            GoldRecycle_GiftShop_UpdateAwardItem(g_GoldRecycle_GiftShop_BagIndex)
		else
			GoldRecycle_GiftShop_Close()
        end
		
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        GoldRecycle_GiftShop_Close()
		
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        GoldRecycle_GiftShop_UnifiedPos()
		
    elseif (event == "ADJEST_UI_POS") then
        GoldRecycle_GiftShop_UnifiedPos()
		
	end
end

-- 界面默认位置
function GoldRecycle_GiftShop_UnifiedPos()

    if (this:IsVisible()) then
        if (GoldRecycle_GiftShop_UnifiedPosition ~= nil) then
            GoldRecycle_GiftShop_Frame_BK:SetProperty("UnifiedPosition", GoldRecycle_GiftShop_UnifiedPosition)
        end
    end
	
end

-- 初始化控件列表
function GoldRecycle_GiftShop_InitControl()

    GoldRecycle_GiftShop_AwardControl[1] = GoldRecycle_GiftShop_Item1
    GoldRecycle_GiftShop_AwardControl[2] = GoldRecycle_GiftShop_Item2
    GoldRecycle_GiftShop_AwardControl[3] = GoldRecycle_GiftShop_Item3

    GoldRecycle_GiftShop_AwardGotControl[1] = GoldRecycle_GiftShop_Item1_Conermark
    GoldRecycle_GiftShop_AwardGotControl[2] = GoldRecycle_GiftShop_Item2_Conermark
    GoldRecycle_GiftShop_AwardGotControl[3] = GoldRecycle_GiftShop_Item3_Conermark

    GoldRecycle_GiftShop_AwardchooseControl[1] = GoldRecycle_GiftShop_Item1_Mask
    GoldRecycle_GiftShop_AwardchooseControl[2] = GoldRecycle_GiftShop_Item2_Mask
    GoldRecycle_GiftShop_AwardchooseControl[3] = GoldRecycle_GiftShop_Item3_Mask
	
	GoldRecycle_GiftShop_CostControl[1] = GoldRecycle_GiftShop_Item1_Name
	GoldRecycle_GiftShop_CostControl[2] = GoldRecycle_GiftShop_Item2_Name
	GoldRecycle_GiftShop_CostControl[3] = GoldRecycle_GiftShop_Item3_Name
	
	GoldRecycle_GiftShop_AwardNameControl[1] = GoldRecycle_GiftShop_Item1_Info
	GoldRecycle_GiftShop_AwardNameControl[2] = GoldRecycle_GiftShop_Item2_Info
	GoldRecycle_GiftShop_AwardNameControl[3] = GoldRecycle_GiftShop_Item3_Info
end

function GoldRecycle_GiftShop_OnShow()

    g_GoldRecycle_GiftShop_choose = -1

    GoldRecycle_GiftShop_InitControl()

    GoldRecycle_GiftShop_ResetAwardItem()

    this:Show()
	
end

function GoldRecycle_GiftShop_Close()

    LifeAbility:Lock_Packet_Item(g_GoldRecycle_GiftShop_BagIndex, 0)
	
    this:Hide()
	
end

function GoldRecycle_GiftShop_OnHidden()

    GoldRecycle_GiftShop_Close()
	
end

-- 物品选择点击事件
function GoldRecycle_GiftShop_Choose( arg )
   
   -- 当前选中的
    local choose = tonumber(arg)
    if (choose < 1 and choose > 3) then
        return
    end

    if (g_GoldRecycle_GiftShop_choose ~= choose) then
        -- 之前选中的和当前选中的不一致
        -- 取消之前的选中提示
        if (g_GoldRecycle_GiftShop_choose > 0) then
            if (GoldRecycle_GiftShop_AwardchooseControl[g_GoldRecycle_GiftShop_choose] ~= nil) then
                GoldRecycle_GiftShop_AwardchooseControl[g_GoldRecycle_GiftShop_choose]:Hide()
            end
        end

        -- 显示当前的选中提示
        if (GoldRecycle_GiftShop_AwardchooseControl[choose] ~= nil) then
            GoldRecycle_GiftShop_AwardchooseControl[choose]:Show()
        end

        g_GoldRecycle_GiftShop_choose = choose
    else
        -- 之前选中的和当前选中的是同一个 取消选中提示
        GoldRecycle_GiftShop_AwardchooseControl[choose]:Hide()
		
        g_GoldRecycle_GiftShop_choose = -1
    end
end

-- 领取按钮事件
function GoldRecycle_GiftShop_GetClick()

    if (g_GoldRecycle_GiftShop_BagIndex < 0) then
        return
    end

    -- 安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end

    -- 判断电话密保和二级密码保护
	if (CheckPhoneMibaoAndMinorPassword() ~= 1) then			
		return
    end
    
    -- 判断玩家等级
    if (Player:GetData("LEVEL") < GoldRecycle_GiftShop_MinLevel) then
        PushDebugMessage("#{FBJB_20220124_70}")
		return
    end

    -- 是否已选择奖励物品
    if (g_GoldRecycle_GiftShop_choose <= 0) then
        -- 没有选取物品
        PushDebugMessage("#{FBJB_20220124_61}")
        return
    end

    -- 不要二次确认了
    GoldRecycle_GiftShop_Confirm()
end

-- 领取物品确认 确认
function GoldRecycle_GiftShop_Confirm()

    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("On3ChooseOne")
		Set_XSCRIPT_ScriptID(GoldRecycle_GiftShop_ServerScriptId)
		Set_XSCRIPT_Parameter(0, g_GoldRecycle_GiftShop_BagIndex)
		Set_XSCRIPT_Parameter(1, g_GoldRecycle_GiftShop_choose)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
end

-- 重置奖励物品
function GoldRecycle_GiftShop_ResetAwardItem()

	GoldRecycle_GiftShop_DragTitle:SetText( "" )
	
	for i = 1, 3 do 
		GoldRecycle_GiftShop_AwardControl[i]:SetActionItem(-1)
		GoldRecycle_GiftShop_AwardNameControl[i]:SetText( "" )
		GoldRecycle_GiftShop_AwardchooseControl[i]:Hide()
		GoldRecycle_GiftShop_AwardGotControl[i]:Hide()
	end

    if (g_GoldRecycle_GiftShop_BagIndex >= 0) then
        LifeAbility:Lock_Packet_Item(g_GoldRecycle_GiftShop_BagIndex, 0)
    end
	
end

-- 刷新奖励物品
function GoldRecycle_GiftShop_UpdateAwardItem( bagIndex )

    if (bagIndex >= 0) then
        LifeAbility:Lock_Packet_Item(bagIndex, 1)
    end
	
	local strname = PlayerPackage:GetBagItemName(bagIndex)
	if strname ~= nil and strname ~= "" then
		GoldRecycle_GiftShop_DragTitle:SetText( "#gFF0FA0"..strname )
	end

    local itemId = PlayerPackage:GetItemTableIndex(bagIndex)	
	
	for i = 0, 2 do
		local nOpItemId, nOpItemNum, nOpItemCost, nOpItemBind = GetMoneyRecycleOpItemByItemId(itemId, i)
		if nOpItemId > 0 then	
			local str = ScriptGlobal_Format("#{FBJB_20220124_57}", math.floor(nOpItemCost/10000)) 
			GoldRecycle_GiftShop_CostControl[i+1]:SetText( str )
			
			str = DataPool:Lua_GetItemNameByIndex(nOpItemId)
			if str ~= nil then
				GoldRecycle_GiftShop_AwardNameControl[i+1]:SetText( "#L"..str )
			end

			local itemAction = DataPool:CreateActionItemForShow(nOpItemId, nOpItemNum)
			if nOpItemBind == 1 then
				itemAction = DataPool:CreateBindActionItemForShow(nOpItemId, nOpItemNum)
			end
			if itemAction:GetID() ~= 0 then
				GoldRecycle_GiftShop_AwardControl[i+1]:SetActionItem(itemAction:GetID())
			end
		end
	end
	
end

function GoldRecycle_GiftShop_Help_Clicked()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GoldRecycleShowHelp")
		Set_XSCRIPT_ScriptID(888973)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
end

