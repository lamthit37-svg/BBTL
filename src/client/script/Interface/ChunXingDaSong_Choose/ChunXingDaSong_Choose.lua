-- 五选一 UI

-- 服务器脚本号
local ChunXingDaSong_Choose_ServerScriptId = 888330

local ChunXingDaSong_Choose_UnifiedPosition = nil
-- UICommand
local ChunXingDaSong_Choose_UICommand = 20122802
local ChunXingDaSong_Choose_UICommandType =
{
    Type_OpenUI = 1,                -- 打开UI
} -- end ChunXingDaSong_Choose_UICommandType

-- 当前已选择的物品索引
local ChunXingDaSong_Choose_Chose = -1
-- 当前物品的背包位置
local ChunXingDaSong_Choose_BagIndex = -1
-- 调用脚本号
local ChunXingDaSong_Choose_ScriptId = -1

-- 物品展示控件列表
local ChunXingDaSong_Choose_AwardControl = {}
-- 物品已获得控件列表
local ChunXingDaSong_Choose_AwardGotControl = {}
-- 物品名称控件列表
local ChunXingDaSong_Choose_AwardTipControl = {}
-- 物品选中控件列表
local ChunXingDaSong_Choose_AwardChoseControl = {}

-- 最小使用等级
local ChunXingDaSong_Choose_MinLevel = 30

-- 奖励物品集合
local ChunXingDaSong_Choose_ItemSet =
{
    [38005134] = {38005140, 38005138, 38005136, 38005142, 38005144},        -- 物品顺序：1：语云水，2：渺翠微，3：闻折柳，4：聆碧波，5：惊风雷（受其他功能影响，顺序不可改变！！！）
    [38005174] = {38005140, 38005138, 38005136, 38005142, 38005144},
} -- end ChunXingDaSong_Choose_ItemSet

-- 物品名称特殊处理
local ChunXingDaSong_Choose_ItemNameSet =
{
    [38005134] = {"#{CXDS_201224_38}", "#{CXDS_201224_39}", "#{CXDS_201224_40}", "#{CXDS_201224_41}", "#{CXDS_201224_42}"}
} -- end ChunXingDaSong_Choose_ItemNameSet

function ChunXingDaSong_Choose_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end -- end func ChunXingDaSong_Choose_PreLoad()

function ChunXingDaSong_Choose_OnLoad()	
	ChunXingDaSong_Choose_UnifiedPosition = ChunXingDaSong_Choose_Frame_BK:GetProperty("UnifiedPosition")	
end -- end func ChunXingDaSong_Choose_OnLoad()

function ChunXingDaSong_Choose_OnEvent(event)
    if (event == "UI_COMMAND" and tonumber(arg0) == ChunXingDaSong_Choose_UICommand) then
        local type = Get_XParam_INT(0)
        if (type == ChunXingDaSong_Choose_UICommandType.Type_OpenUI) then
            ChunXingDaSong_Choose_OnShow()
			ChunXingDaSong_Choose_ScriptId = Get_XParam_INT(1)
			ChunXingDaSong_Choose_Page_Info2:Show()
			if ChunXingDaSong_Choose_ScriptId ~= ChunXingDaSong_Choose_ServerScriptId then
				ChunXingDaSong_Choose_Page_Info2:Hide()
			end
            ChunXingDaSong_Choose_BagIndex= Get_XParam_INT(2)
            local flag1 = Get_XParam_INT(3)
            local flag2 = Get_XParam_INT(4)
            local flag3 = Get_XParam_INT(5)
            local flag4 = Get_XParam_INT(6)
            local flag5 = Get_XParam_INT(7)
            ChunXingDaSong_Choose_UpdateAwardItem(ChunXingDaSong_Choose_BagIndex, flag1, flag2, flag3, flag4, flag5)
            LifeAbility:Lock_Packet_Item(ChunXingDaSong_Choose_BagIndex, 1)
        end
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        ChunXingDaSong_Choose_OnHide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        ChunXingDaSong_Choose_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        ChunXingDaSong_Choose_UnifiedPos()
	end
end -- end func ChunXingDaSong_Choose_OnEvent()

-- 界面默认位置
function ChunXingDaSong_Choose_UnifiedPos()
    if (this:IsVisible()) then
        if (ChunXingDaSong_Choose_UnifiedPosition ~= nil) then
            ChunXingDaSong_Choose_Frame_BK:SetProperty("UnifiedPosition", ChunXingDaSong_Choose_UnifiedPosition)
        end
    end
end -- end func ChunXingDaSong_Choose_UnifiedPos()

-- 初始化控件列表
function ChunXingDaSong_Choose_InitControl()
    ChunXingDaSong_Choose_AwardControl[1] = ChunXingDaSong_Choose_Page_Lace1Item
    ChunXingDaSong_Choose_AwardControl[2] = ChunXingDaSong_Choose_Page_Lace2Item
    ChunXingDaSong_Choose_AwardControl[3] = ChunXingDaSong_Choose_Page_Lace3Item
    ChunXingDaSong_Choose_AwardControl[4] = ChunXingDaSong_Choose_Page_Lace4Item
    ChunXingDaSong_Choose_AwardControl[5] = ChunXingDaSong_Choose_Page_Lace5Item

    ChunXingDaSong_Choose_AwardGotControl[1] = ChunXingDaSong_Choose_Page_Lace1Item_Conermark
    ChunXingDaSong_Choose_AwardGotControl[2] = ChunXingDaSong_Choose_Page_Lace2Item_Conermark
    ChunXingDaSong_Choose_AwardGotControl[3] = ChunXingDaSong_Choose_Page_Lace3Item_Conermark
    ChunXingDaSong_Choose_AwardGotControl[4] = ChunXingDaSong_Choose_Page_Lace4Item_Conermark
    ChunXingDaSong_Choose_AwardGotControl[5] = ChunXingDaSong_Choose_Page_Lace5Item_Conermark

    ChunXingDaSong_Choose_AwardTipControl[1] = ChunXingDaSong_Choose_Page_Lace1Item_Tip
    ChunXingDaSong_Choose_AwardTipControl[2] = ChunXingDaSong_Choose_Page_Lace2Item_Tip
    ChunXingDaSong_Choose_AwardTipControl[3] = ChunXingDaSong_Choose_Page_Lace3Item_Tip
    ChunXingDaSong_Choose_AwardTipControl[4] = ChunXingDaSong_Choose_Page_Lace4Item_Tip
    ChunXingDaSong_Choose_AwardTipControl[5] = ChunXingDaSong_Choose_Page_Lace5Item_Tip

    ChunXingDaSong_Choose_AwardChoseControl[1] = ChunXingDaSong_Choose_Page_Lace1Item_Mask
    ChunXingDaSong_Choose_AwardChoseControl[2] = ChunXingDaSong_Choose_Page_Lace2Item_Mask
    ChunXingDaSong_Choose_AwardChoseControl[3] = ChunXingDaSong_Choose_Page_Lace3Item_Mask
    ChunXingDaSong_Choose_AwardChoseControl[4] = ChunXingDaSong_Choose_Page_Lace4Item_Mask
    ChunXingDaSong_Choose_AwardChoseControl[5] = ChunXingDaSong_Choose_Page_Lace5Item_Mask
end -- end func ChunXingDaSong_Choose_InitControl()

function ChunXingDaSong_Choose_OnShow()
    ChunXingDaSong_Choose_Chose = -1

    ChunXingDaSong_Choose_InitControl()

    ChunXingDaSong_Choose_ResetAwardItem()

    this:Show()
end -- end func ChunXingDaSong_Choose_OnShow()

function ChunXingDaSong_Choose_OnHide()
    LifeAbility:Lock_Packet_Item(ChunXingDaSong_Choose_BagIndex, 0)
    this:Hide()
end -- end func ChunXingDaSong_Choose_OnHide()

function ChunXingDaSong_Choose_OnHidden()
    ChunXingDaSong_Choose_OnHide()
end -- end func ChunXingDaSong_Choose_OnHidden()

-- 物品选择点击事件
function ChunXingDaSong_Choose_OnActionItemClicked(arg)
    -- 当前选中的
    local chose = tonumber(arg)
    if (chose <= 0) then
        return
    end

    -- for i = 1, 5, 1 do
    --     ChunXingDaSong_Choose_AwardTipControl[i]:SetPushed(0)
    -- end -- end for

    if (ChunXingDaSong_Choose_Chose ~= chose) then
        -- 之前选中的和当前选中的不一致
        -- 取消之前的选中提示
        if (ChunXingDaSong_Choose_Chose > 0) then
            if (ChunXingDaSong_Choose_AwardChoseControl[ChunXingDaSong_Choose_Chose] ~= nil) then
                ChunXingDaSong_Choose_AwardChoseControl[ChunXingDaSong_Choose_Chose]:Hide()
            end
        end

        -- 显示当前的选中提示
        if (ChunXingDaSong_Choose_AwardChoseControl[chose] ~= nil) then
            ChunXingDaSong_Choose_AwardChoseControl[chose]:Show()
        end

        --ChunXingDaSong_Choose_AwardTipControl[chose]:SetPushed(1)
        ChunXingDaSong_Choose_Chose = chose
    else
        -- 之前选中的和当前选中的是同一个 取消选中提示
        ChunXingDaSong_Choose_AwardChoseControl[chose]:Hide()

        --ChunXingDaSong_Choose_AwardTipControl[ChunXingDaSong_Choose]:SetPushed(0)

        ChunXingDaSong_Choose_Chose = -1
    end
end -- end func ChunXingDaSong_Choose_OnActionItemClicked()

-- 领取按钮事件
function ChunXingDaSong_Choose_OKClicked()
    if (ChunXingDaSong_Choose_BagIndex < 0) then
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

    -- 角色当前未处于全沉迷或半沉迷状态；
	if (IsInFatigueState() <= 0) then
		PushDebugMessage("#{FCMX_90609_22}")
		return
    end
    
    -- 判断玩家等级
    if (Player:GetData("LEVEL") < ChunXingDaSong_Choose_MinLevel) then
        PushDebugMessage("#{CXDS_201224_33}")
		return
    end

    -- 是否已选择奖励物品
    if (ChunXingDaSong_Choose_Chose <= 0) then
        -- 没有选取物品
        PushDebugMessage("#{CXDS_201224_44}")
        return
    end

    -- 不要二次确认了
    ChunXingDaSong_Choose_Confirm()
    -- -- 弹出二次确认
    -- local itemId = PlayerPackage:GetItemTableIndex(ChunXingDaSong_Choose_BagIndex)
    -- if (ChunXingDaSong_Choose_ItemSet[itemId] ~= nil) then
    --     local itemName = PlayerPackage:GetItemName(ChunXingDaSong_Choose_ItemSet[itemId][ChunXingDaSong_Choose_Chose])
    --     local szTip = ScriptGlobal_Format("#{CXDS_201224_45}", itemName)
    --     MessageBoxCommon("", szTip, "ChunXingDaSong_Choose", "Confirm()", "Cancel()")
    -- end
end -- end func ChunXingDaSong_Choose_OKClicked()

-- 领取物品确认 确认
function ChunXingDaSong_Choose_Confirm()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PickOne")
		if ChunXingDaSong_Choose_ScriptId == -1 then
			Set_XSCRIPT_ScriptID(ChunXingDaSong_Choose_ServerScriptId)
		else
			Set_XSCRIPT_ScriptID(ChunXingDaSong_Choose_ScriptId)
		end
		Set_XSCRIPT_Parameter(0, ChunXingDaSong_Choose_BagIndex)
		Set_XSCRIPT_Parameter(1, ChunXingDaSong_Choose_Chose)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
    
    CloseMessageBoxCommon()
    ChunXingDaSong_Choose_OnHide()
end -- end func ChunXingDaSong_Choose_Confirm()

-- 领取物品确认 取消
function ChunXingDaSong_Choose_Cancel()
    CloseMessageBoxCommon()
    --ChunXingDaSong_Choose_OnHide()
end -- end func ChunXingDaSong_Choose_Cancel()

-- 重置奖励物品
function ChunXingDaSong_Choose_ResetAwardItem()
    for i = 1, 5, 1 do
        ChunXingDaSong_Choose_AwardControl[i]:SetActionItem(-1)
        ChunXingDaSong_Choose_AwardTipControl[i]:SetText("")
        ChunXingDaSong_Choose_AwardChoseControl[i]:Hide()
        ChunXingDaSong_Choose_AwardGotControl[i]:Hide()
    end -- end for

    if (ChunXingDaSong_Choose_BagIndex >= 0) then
        LifeAbility:Lock_Packet_Item(ChunXingDaSong_Choose_BagIndex, 0)
    end
end -- end func ChunXingDaSong_Choose_ResetAwardItem()

-- 刷新奖励物品
function ChunXingDaSong_Choose_UpdateAwardItem(bagIndex, flag1, flag2, flag3, flag4, flag5)
    if (bagIndex >= 0) then
        LifeAbility:Lock_Packet_Item(bagIndex, 1)
    end

    local itemId = PlayerPackage:GetItemTableIndex(bagIndex)
    if (ChunXingDaSong_Choose_ItemSet[itemId] == nil) then
        return
    end

    local flagVal = {flag1, flag2, flag3, flag4, flag5}
    for i = 1, 5, 1 do
        local itemAction = DataPool:CreateActionItemForShow(ChunXingDaSong_Choose_ItemSet[itemId][i], 1)
		if itemAction:GetID() ~= 0 then
            ChunXingDaSong_Choose_AwardControl[i]:SetActionItem(itemAction:GetID())
            
            if (ChunXingDaSong_Choose_ItemNameSet[itemId] ~= nil) then
                ChunXingDaSong_Choose_AwardTipControl[i]:SetText("#L" .. ChunXingDaSong_Choose_ItemNameSet[itemId][i])
            else
                local itemName = PlayerPackage:GetItemName(ChunXingDaSong_Choose_ItemSet[itemId][i])
                ChunXingDaSong_Choose_AwardTipControl[i]:SetText("#L" .. itemName)
            end

            if (flagVal[i] > 0) then
                ChunXingDaSong_Choose_AwardGotControl[i]:Show()
            end
		end
    end -- end for
end -- end func ChunXingDaSong_Choose_UpdateAwardItem()