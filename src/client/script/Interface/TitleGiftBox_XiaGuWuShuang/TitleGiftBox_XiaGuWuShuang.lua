
-- 服务器脚本号
local TitleGiftBox_XiaGuWuShuang_ServerScriptId = 888343

local TitleGiftBox_XiaGuWuShuang_UnifiedPosition = nil
-- UICommand
local TitleGiftBox_XiaGuWuShuang_UICommandType =
{
    Type_OpenUI = 1,                -- 打开UI
} -- end TitleGiftBox_XiaGuWuShuang_UICommandType

-- 当前已选择的物品索引
local TitleGiftBox_XiaGuWuShuang_Chose = -1
-- 当前物品的背包位置
local TitleGiftBox_XiaGuWuShuang_BagIndex = -1

-- 物品展示控件列表
local TitleGiftBox_XiaGuWuShuang_AwardControl = {}
-- 物品已获得控件列表
local TitleGiftBox_XiaGuWuShuang_AwardGotControl = {}
-- 物品名称控件列表
local TitleGiftBox_XiaGuWuShuang_AwardTipControl = {}
-- 物品选中控件列表
local TitleGiftBox_XiaGuWuShuang_AwardChoseControl = {}

-- 最小使用等级
local TitleGiftBox_XiaGuWuShuang_MinLevel = 30

-- 奖励物品集合
local TitleGiftBox_XiaGuWuShuang_ItemSet =
{
    [38005180] = {
		[1]={itemid=39923191,titleid=1655,name="#{CJYJ_180129_193}"}, 
		[2]={itemid=39923192,titleid=1656,name="#{CJYJ_180129_194}"}, 
		[3]={itemid=39923193,titleid=1657,name="#{CJYJ_180129_195}"}, 
		[4]={itemid=39923194,titleid=1658,name="#{CJYJ_180129_196}"},
		},
} -- end TitleGiftBox_XiaGuWuShuang_ItemSet

function TitleGiftBox_XiaGuWuShuang_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end -- end func TitleGiftBox_XiaGuWuShuang_PreLoad()

function TitleGiftBox_XiaGuWuShuang_OnLoad()	
	TitleGiftBox_XiaGuWuShuang_UnifiedPosition = TitleGiftBox_XiaGuWuShuang_Frame_BK:GetProperty("UnifiedPosition")	
end -- end func TitleGiftBox_XiaGuWuShuang_OnLoad()

function TitleGiftBox_XiaGuWuShuang_OnEvent(event)
    if (event == "UI_COMMAND" and tonumber(arg0) == 88834301) then
        local type = Get_XParam_INT(0)
        if (type == TitleGiftBox_XiaGuWuShuang_UICommandType.Type_OpenUI) then
            TitleGiftBox_XiaGuWuShuang_OnShow()
            TitleGiftBox_XiaGuWuShuang_BagIndex= Get_XParam_INT(1)
            local flag1 = Get_XParam_INT(2)
            local flag2 = Get_XParam_INT(3)
            local flag3 = Get_XParam_INT(4)
            local flag4 = Get_XParam_INT(5)
            TitleGiftBox_XiaGuWuShuang_UpdateAwardItem(TitleGiftBox_XiaGuWuShuang_BagIndex, flag1, flag2, flag3, flag4)
            LifeAbility:Lock_Packet_Item(TitleGiftBox_XiaGuWuShuang_BagIndex, 1)
        end
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        TitleGiftBox_XiaGuWuShuang_OnHide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        TitleGiftBox_XiaGuWuShuang_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        TitleGiftBox_XiaGuWuShuang_UnifiedPos()
	end
end -- end func TitleGiftBox_XiaGuWuShuang_OnEvent()

-- 界面默认位置
function TitleGiftBox_XiaGuWuShuang_UnifiedPos()
    if (this:IsVisible()) then
        if (TitleGiftBox_XiaGuWuShuang_UnifiedPosition ~= nil) then
            TitleGiftBox_XiaGuWuShuang_Frame_BK:SetProperty("UnifiedPosition", TitleGiftBox_XiaGuWuShuang_UnifiedPosition)
        end
    end
end -- end func TitleGiftBox_XiaGuWuShuang_UnifiedPos()

-- 初始化控件列表
function TitleGiftBox_XiaGuWuShuang_InitControl()
    TitleGiftBox_XiaGuWuShuang_AwardControl[1] = TitleGiftBox_XiaGuWuShuang_Page_Lace1Item
    TitleGiftBox_XiaGuWuShuang_AwardControl[2] = TitleGiftBox_XiaGuWuShuang_Page_Lace2Item
    TitleGiftBox_XiaGuWuShuang_AwardControl[3] = TitleGiftBox_XiaGuWuShuang_Page_Lace3Item
    TitleGiftBox_XiaGuWuShuang_AwardControl[4] = TitleGiftBox_XiaGuWuShuang_Page_Lace4Item

    TitleGiftBox_XiaGuWuShuang_AwardGotControl[1] = TitleGiftBox_XiaGuWuShuang_Page_Lace1Item_Mark
    TitleGiftBox_XiaGuWuShuang_AwardGotControl[2] = TitleGiftBox_XiaGuWuShuang_Page_Lace2Item_Mark
    TitleGiftBox_XiaGuWuShuang_AwardGotControl[3] = TitleGiftBox_XiaGuWuShuang_Page_Lace3Item_Mark
    TitleGiftBox_XiaGuWuShuang_AwardGotControl[4] = TitleGiftBox_XiaGuWuShuang_Page_Lace4Item_Mark

    TitleGiftBox_XiaGuWuShuang_AwardTipControl[1] = TitleGiftBox_XiaGuWuShuang_Page_Lace1Item_Tip
    TitleGiftBox_XiaGuWuShuang_AwardTipControl[2] = TitleGiftBox_XiaGuWuShuang_Page_Lace2Item_Tip
    TitleGiftBox_XiaGuWuShuang_AwardTipControl[3] = TitleGiftBox_XiaGuWuShuang_Page_Lace3Item_Tip
    TitleGiftBox_XiaGuWuShuang_AwardTipControl[4] = TitleGiftBox_XiaGuWuShuang_Page_Lace4Item_Tip

    TitleGiftBox_XiaGuWuShuang_AwardChoseControl[1] = TitleGiftBox_XiaGuWuShuang_Page_Lace1Item_Mask
    TitleGiftBox_XiaGuWuShuang_AwardChoseControl[2] = TitleGiftBox_XiaGuWuShuang_Page_Lace2Item_Mask
    TitleGiftBox_XiaGuWuShuang_AwardChoseControl[3] = TitleGiftBox_XiaGuWuShuang_Page_Lace3Item_Mask
    TitleGiftBox_XiaGuWuShuang_AwardChoseControl[4] = TitleGiftBox_XiaGuWuShuang_Page_Lace4Item_Mask
end -- end func TitleGiftBox_XiaGuWuShuang_InitControl()

function TitleGiftBox_XiaGuWuShuang_OnShow()
    TitleGiftBox_XiaGuWuShuang_Chose = -1

    TitleGiftBox_XiaGuWuShuang_InitControl()

    TitleGiftBox_XiaGuWuShuang_ResetAwardItem()

    this:Show()
end -- end func TitleGiftBox_XiaGuWuShuang_OnShow()

function TitleGiftBox_XiaGuWuShuang_OnHide()
    LifeAbility:Lock_Packet_Item(TitleGiftBox_XiaGuWuShuang_BagIndex, 0)
    this:Hide()
end -- end func TitleGiftBox_XiaGuWuShuang_OnHide()

function TitleGiftBox_XiaGuWuShuang_OnHidden()
    TitleGiftBox_XiaGuWuShuang_OnHide()
end -- end func TitleGiftBox_XiaGuWuShuang_OnHidden()

-- 物品选择点击事件
function TitleGiftBox_XiaGuWuShuang_OnActionItemClicked(arg)
    -- 当前选中的
    local chose = tonumber(arg)
    if (chose <= 0) then
        return
    end

    if (TitleGiftBox_XiaGuWuShuang_Chose ~= chose) then
        -- 之前选中的和当前选中的不一致
        -- 取消之前的选中提示
        if (TitleGiftBox_XiaGuWuShuang_Chose > 0) then
            if (TitleGiftBox_XiaGuWuShuang_AwardChoseControl[TitleGiftBox_XiaGuWuShuang_Chose] ~= nil) then
                TitleGiftBox_XiaGuWuShuang_AwardChoseControl[TitleGiftBox_XiaGuWuShuang_Chose]:Hide()
            end
        end

        -- 显示当前的选中提示
        if (TitleGiftBox_XiaGuWuShuang_AwardChoseControl[chose] ~= nil) then
            TitleGiftBox_XiaGuWuShuang_AwardChoseControl[chose]:Show()
        end

        --TitleGiftBox_XiaGuWuShuang_AwardTipControl[chose]:SetPushed(1)
        TitleGiftBox_XiaGuWuShuang_Chose = chose
    else
        -- 之前选中的和当前选中的是同一个 取消选中提示
        TitleGiftBox_XiaGuWuShuang_AwardChoseControl[chose]:Hide()

        --TitleGiftBox_XiaGuWuShuang_AwardTipControl[TitleGiftBox_XiaGuWuShuang]:SetPushed(0)

        TitleGiftBox_XiaGuWuShuang_Chose = -1
    end
end -- end func TitleGiftBox_XiaGuWuShuang_OnActionItemClicked()

-- 领取按钮事件
function TitleGiftBox_XiaGuWuShuang_OKClicked()
	TitleGiftBox_XiaGuWuShuang_Finish() 
end

-- 领取物品确认 确认
function TitleGiftBox_XiaGuWuShuang_Finish()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Finish")
		Set_XSCRIPT_ScriptID(TitleGiftBox_XiaGuWuShuang_ServerScriptId)
		Set_XSCRIPT_Parameter(0, TitleGiftBox_XiaGuWuShuang_BagIndex)
		Set_XSCRIPT_Parameter(1, TitleGiftBox_XiaGuWuShuang_Chose)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

    TitleGiftBox_XiaGuWuShuang_OnHide()
end

-- 重置奖励物品
function TitleGiftBox_XiaGuWuShuang_ResetAwardItem()
    for i = 1, 4 do
        TitleGiftBox_XiaGuWuShuang_AwardControl[i]:SetActionItem(-1)
        TitleGiftBox_XiaGuWuShuang_AwardTipControl[i]:SetText("")
        TitleGiftBox_XiaGuWuShuang_AwardChoseControl[i]:Hide()
        TitleGiftBox_XiaGuWuShuang_AwardGotControl[i]:Hide()
    end

    if (TitleGiftBox_XiaGuWuShuang_BagIndex >= 0) then
        LifeAbility:Lock_Packet_Item(TitleGiftBox_XiaGuWuShuang_BagIndex, 0)
    end
end

-- 刷新奖励物品
function TitleGiftBox_XiaGuWuShuang_UpdateAwardItem(bagIndex, flag1, flag2, flag3, flag4)
    if (bagIndex >= 0) then
        LifeAbility:Lock_Packet_Item(bagIndex, 1)
    end

    local itemId = PlayerPackage:GetItemTableIndex(bagIndex)
    if (TitleGiftBox_XiaGuWuShuang_ItemSet[itemId] == nil) then
        return
    end

    local flagVal = {flag1, flag2, flag3, flag4}
    for i = 1, 4 do
        local itemAction = DataPool:CreateActionItemForShow(TitleGiftBox_XiaGuWuShuang_ItemSet[itemId][i].itemid, 1)
		if itemAction:GetID() ~= 0 then
            TitleGiftBox_XiaGuWuShuang_AwardControl[i]:SetActionItem(itemAction:GetID())
            
            if (TitleGiftBox_XiaGuWuShuang_ItemSet[itemId] ~= nil) then
                TitleGiftBox_XiaGuWuShuang_AwardTipControl[i]:SetText("#L" .. TitleGiftBox_XiaGuWuShuang_ItemSet[itemId][i].name)
            else
                local itemName = PlayerPackage:GetItemName(TitleGiftBox_XiaGuWuShuang_ItemSet[itemId][i].itemid)
                TitleGiftBox_XiaGuWuShuang_AwardTipControl[i]:SetText("#L" .. itemName)
            end

            if (flagVal[i] > 0) then
                TitleGiftBox_XiaGuWuShuang_AwardGotControl[i]:Show()
            end
		end
    end
end