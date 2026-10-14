
-- 二选一 UI

-- 服务器脚本号
local GoldRecycle_Choose_ServerScriptId = 888949

local GoldRecycle_Choose_UnifiedPosition = nil

-- UICommand
local GoldRecycle_Choose_UICommand = 88894901
local GoldRecycle_Choose_UICommandType =
{
    Type_CloseUI = 0,               -- 关闭UI
    Type_OpenUI = 1,                -- 打开UI
}

-- 当前已选择的物品索引
local GoldRecycle_Choose_choose = -1

-- 当前物品的背包位置
local GoldRecycle_Choose_BagIndex = -1

-- 调用脚本号
local GoldRecycle_Choose_ScriptId = -1

-- 物品展示控件列表
local GoldRecycle_Choose_AwardControl = {}
-- 物品已获得控件列表
local GoldRecycle_Choose_AwardGotControl = {}
-- 物品选中控件列表
local GoldRecycle_Choose_AwardchooseControl = {}

-- 最小使用等级
local GoldRecycle_Choose_MinLevel = 50

-- 奖励物品集合
local GoldRecycle_Choose_ItemSet =
{
[38005688] = {money = 50000, daibi = 5},	--机关枢纽
[38005689] = {money = 10000, daibi = 1},	--元丰通宝
[38005690] = {money = 50000, daibi = 5}, 	--元丰重宝
}

function GoldRecycle_Choose_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function GoldRecycle_Choose_OnLoad()	

	GoldRecycle_Choose_UnifiedPosition = GoldRecycle_Choose_Frame:GetProperty("UnifiedPosition")	
	
end

function GoldRecycle_Choose_OnEvent(event)

    if (event == "UI_COMMAND" and tonumber(arg0) == GoldRecycle_Choose_UICommand) then
        local type = Get_XParam_INT(0)
        if (type == GoldRecycle_Choose_UICommandType.Type_OpenUI) then
		
            GoldRecycle_Choose_OnShow()
			
			GoldRecycle_Choose_ScriptId = Get_XParam_INT(1)
			
            GoldRecycle_Choose_BagIndex= Get_XParam_INT(2)
            GoldRecycle_Choose_UpdateAwardItem(GoldRecycle_Choose_BagIndex)
		else
			GoldRecycle_Choose_OnHide()
        end
		
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        GoldRecycle_Choose_OnHide()
		
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        GoldRecycle_Choose_UnifiedPos()
		
    elseif (event == "ADJEST_UI_POS") then
        GoldRecycle_Choose_UnifiedPos()
		
	end
end

-- 界面默认位置
function GoldRecycle_Choose_UnifiedPos()

    if (this:IsVisible()) then
        if (GoldRecycle_Choose_UnifiedPosition ~= nil) then
            GoldRecycle_Choose_Frame:SetProperty("UnifiedPosition", GoldRecycle_Choose_UnifiedPosition)
        end
    end
	
end

-- 初始化控件列表
function GoldRecycle_Choose_InitControl()

    GoldRecycle_Choose_AwardControl[1] = GoldRecycle_Choose_Gift1_Icon
    GoldRecycle_Choose_AwardControl[2] = GoldRecycle_Choose_Gift2_Icon

    GoldRecycle_Choose_AwardGotControl[1] = GoldRecycle_Choose_Gift1_Num
    GoldRecycle_Choose_AwardGotControl[2] = GoldRecycle_Choose_Gift2_Num

    GoldRecycle_Choose_AwardchooseControl[1] = GoldRecycle_Choose_Gift1_Mask
    GoldRecycle_Choose_AwardchooseControl[2] = GoldRecycle_Choose_Gift2_Mask
	
end

function GoldRecycle_Choose_OnShow()
	
    if(IsWindowShow("Quest") == true) then
        CloseWindow("Quest", true)
    end

    GoldRecycle_Choose_choose = -1

    GoldRecycle_Choose_InitControl()

    GoldRecycle_Choose_ResetAwardItem()

    this:Show()
	
end

function GoldRecycle_Choose_OnHide()

    LifeAbility:Lock_Packet_Item(GoldRecycle_Choose_BagIndex, 0)
	
    this:Hide()
	
end

function GoldRecycle_Choose_OnHiden()

    GoldRecycle_Choose_OnHide()
	
end

-- 物品选择点击事件
function GoldRecycle_Choose_OnActionItemClicked( arg )
   
   -- 当前选中的
    local choose = tonumber(arg)
    if (choose ~= 1 and choose ~= 2) then
        return
    end

    if (GoldRecycle_Choose_choose ~= choose) then
        -- 之前选中的和当前选中的不一致
        -- 取消之前的选中提示
        if (GoldRecycle_Choose_choose > 0) then
            if (GoldRecycle_Choose_AwardchooseControl[GoldRecycle_Choose_choose] ~= nil) then
                GoldRecycle_Choose_AwardchooseControl[GoldRecycle_Choose_choose]:Hide()
            end
        end

        -- 显示当前的选中提示
        if (GoldRecycle_Choose_AwardchooseControl[choose] ~= nil) then
            GoldRecycle_Choose_AwardchooseControl[choose]:Show()
        end

        GoldRecycle_Choose_choose = choose
    else
        -- 之前选中的和当前选中的是同一个 取消选中提示
        GoldRecycle_Choose_AwardchooseControl[choose]:Hide()
		
        GoldRecycle_Choose_choose = -1
    end
end

-- 领取按钮事件
function GoldRecycle_Choose_Select()

    if (GoldRecycle_Choose_BagIndex < 0) then
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
    if (Player:GetData("LEVEL") < GoldRecycle_Choose_MinLevel) then
        PushDebugMessage("#{FBJB_20220124_07}")
		return
    end

    -- 是否已选择奖励物品
    if (GoldRecycle_Choose_choose <= 0) then
        -- 没有选取物品
        PushDebugMessage("#{FBJB_20220124_08}")
        return
    end

    -- 不要二次确认了
    GoldRecycle_Choose_Confirm()
end

-- 领取物品确认 确认
function GoldRecycle_Choose_Confirm()

    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnChooseOne")
		Set_XSCRIPT_ScriptID(GoldRecycle_Choose_ServerScriptId)
		Set_XSCRIPT_Parameter(0, GoldRecycle_Choose_BagIndex)
		Set_XSCRIPT_Parameter(1, GoldRecycle_Choose_choose)
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	
end

-- 重置奖励物品
function GoldRecycle_Choose_ResetAwardItem()

	GoldRecycle_Choose_DragTitle:SetText( "" )

    GoldRecycle_Choose_AwardControl[1]:SetActionItem(-1)
    GoldRecycle_Choose_AwardControl[2]:SetActionItem(-1)
	
    GoldRecycle_Choose_AwardchooseControl[1]:Hide()
    GoldRecycle_Choose_AwardchooseControl[2]:Hide()
	
    GoldRecycle_Choose_AwardGotControl[1]:Hide()
    GoldRecycle_Choose_AwardGotControl[2]:Hide()

    if (GoldRecycle_Choose_BagIndex >= 0) then
        LifeAbility:Lock_Packet_Item(GoldRecycle_Choose_BagIndex, 0)
    end
	
end

-- 刷新奖励物品
function GoldRecycle_Choose_UpdateAwardItem( bagIndex )

    if (bagIndex >= 0) then
        LifeAbility:Lock_Packet_Item(bagIndex, 1)
    end

    local itemId = PlayerPackage:GetItemTableIndex(bagIndex)
    if (GoldRecycle_Choose_ItemSet[itemId] == nil) then
        return
    end
	
	local strname = PlayerPackage:GetBagItemName(bagIndex)
	if strname ~= nil and strname ~= "" then
		GoldRecycle_Choose_DragTitle:SetText( "#gFF0FA0"..strname )
	end
	
	local str = ScriptGlobal_Format("#{FBJB_20220124_42}", GoldRecycle_Choose_ItemSet[itemId].money) 
	GoldRecycle_Choose_Gift1_Text:SetText( str )
	
	str = ScriptGlobal_Format("#{FBJB_20220124_04}", GoldRecycle_Choose_ItemSet[itemId].daibi) 
	GoldRecycle_Choose_Gift2_Text:SetText( str )

    local itemAction = DataPool:CreateActionItemForShow(39923744, 1)
	if itemAction:GetID() ~= 0 then
        GoldRecycle_Choose_AwardControl[1]:SetActionItem(itemAction:GetID())
    end
	
	itemAction = DataPool:CreateActionItemForShow(39923745, 1)
	if itemAction:GetID() ~= 0 then
        GoldRecycle_Choose_AwardControl[2]:SetActionItem(itemAction:GetID())
    end
	
end