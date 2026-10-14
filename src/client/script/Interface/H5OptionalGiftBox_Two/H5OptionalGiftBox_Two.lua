--!!!reloadscript =H5OptionalGiftBox_Two
--2选礼包

--变量
local g_H5OptionalGiftBox_Two_Frame_UnifiedPosition = ""
local g_H5OptionalGiftBox_Two_CurSelPos = -1
local g_H5OptionalGiftBox_Two_CurBagPos = -1


--UI
local g_H5OptionalGiftBox_Two_UI_ActionItem = {}
local g_H5OptionalGiftBox_Two_UI_ActionChosenMask = {}
local g_H5OptionalGiftBox_Two_UI_ActionCornerMask = {}
local g_H5OptionalGiftBox_Two_UI_ItemName = {}
local g_H5OptionalGiftBox_Two_UI_DragTitle = ""
local g_H5OptionalGiftBox_Two_UI_Info = ""
local g_H5OptionalGiftBox_Two_UI_Remark = ""

--常量
local g_H5OptionalGiftBox_Two_MainScript = 999761
local g_H5OptionalGiftBox_Two_UIC = 99976102


local g_GiftList = {
    [1] = { id = -1, num = 0 },
    [2] = { id = -1, num = 0 }
}
local g_GiftInfo = {
    [38008181] = { title = "#{YYYR_250923_08}" },
    [38008182] = { title = "#{YYYR_250923_09}" },
}

function H5OptionalGiftBox_Two_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

function H5OptionalGiftBox_Two_OnLoad()
    g_H5OptionalGiftBox_Two_Frame_UnifiedPosition = H5OptionalGiftBox_Two_Frame_BK:GetProperty("UnifiedPosition")

    g_H5OptionalGiftBox_Two_UI_DragTitle = H5OptionalGiftBox_Two_DragTitle
    g_H5OptionalGiftBox_Two_UI_Info = H5OptionalGiftBox_Two_Info
    g_H5OptionalGiftBox_Two_UI_Remark = H5OptionalGiftBox_Two_Remark

    g_H5OptionalGiftBox_Two_UI_ActionItem[1] = H5OptionalGiftBox_Two_Item1
    g_H5OptionalGiftBox_Two_UI_ActionItem[2] = H5OptionalGiftBox_Two_Item2

    g_H5OptionalGiftBox_Two_UI_ActionChosenMask[1] = H5OptionalGiftBox_Two_Item1_Mask
    g_H5OptionalGiftBox_Two_UI_ActionChosenMask[2] = H5OptionalGiftBox_Two_Item2_Mask

    g_H5OptionalGiftBox_Two_UI_ActionCornerMask[1] = H5OptionalGiftBox_Two_Item1_Cornermark
    g_H5OptionalGiftBox_Two_UI_ActionCornerMask[2] = H5OptionalGiftBox_Two_Item2_Cornermark

    g_H5OptionalGiftBox_Two_UI_ItemName[1] = H5OptionalGiftBox_Two_Item1_Name
    g_H5OptionalGiftBox_Two_UI_ItemName[2] = H5OptionalGiftBox_Two_Item2_Name
end

function H5OptionalGiftBox_Two_OnEvent(event)
    if event == "UI_COMMAND" and (tonumber(arg0) == g_H5OptionalGiftBox_Two_UIC) then
        H5OptionalGiftBox_Two_CleanUp()
        g_H5OptionalGiftBox_Two_CurBagPos = Get_XParam_INT(0)
        LifeAbility:Lock_Packet_Item(g_H5OptionalGiftBox_Two_CurBagPos, 1)
        g_GiftList[1].id = Get_XParam_INT(1)
        g_GiftList[1].num = Get_XParam_INT(2)
        g_GiftList[2].id = Get_XParam_INT(3)
        g_GiftList[2].num = Get_XParam_INT(4)
        this:Show()
        H5OptionalGiftBox_Two_Update()

        return
    end

    if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
        H5OptionalGiftBox_Two_Frame_On_ResetPos()
    end

    if event == "HIDE_ON_SCENE_TRANSED" then
        this:Hide()
        return
    end

    if event == "PACKAGE_ITEM_CHANGED_EX" and tonumber(arg0) == g_H5OptionalGiftBox_Two_CurBagPos then
        this:Hide()
        return
    end
end

function H5OptionalGiftBox_Two_Update()
    if g_H5OptionalGiftBox_Two_CurBagPos < 0 then
        return
    end

    --当前打开的礼包id
    local item_table_index = PlayerPackage:GetItemTableIndex(g_H5OptionalGiftBox_Two_CurBagPos)
    local info = g_GiftInfo[item_table_index]
    if info == nil then
        return
    end

    g_H5OptionalGiftBox_Two_UI_DragTitle:SetText(info.title)
    g_H5OptionalGiftBox_Two_UI_Info:SetText("#{YYYR_250923_10}")
    g_H5OptionalGiftBox_Two_UI_Remark:SetText("")

    for i = 1, 2 do
        local itemAction
        itemAction = DataPool:CreateBindActionItemForShow(g_GiftList[i].id, g_GiftList[i].num)

        if itemAction:GetID() ~= 0 then
            g_H5OptionalGiftBox_Two_UI_ActionItem[i]:SetActionItem(itemAction:GetID())
        end

        local strName = DataPool:Lua_GetItemNameByIndex(g_GiftList[i].id)
        g_H5OptionalGiftBox_Two_UI_ItemName[i]:SetText("#L" .. strName)
    end
end

function H5OptionalGiftBox_Two_OnItemClicked(index)
    g_H5OptionalGiftBox_Two_CurSelPos = index

    for i = 1, 2 do
        g_H5OptionalGiftBox_Two_UI_ActionItem[i]:SetPushed(0)
        g_H5OptionalGiftBox_Two_UI_ActionChosenMask[i]:Hide()
    end

    g_H5OptionalGiftBox_Two_UI_ActionItem[index]:SetPushed(1)
    g_H5OptionalGiftBox_Two_UI_ActionChosenMask[index]:Show()
    g_H5OptionalGiftBox_Two_CurSelPos = index
end

function H5OptionalGiftBox_Two_CleanUp()
    for i = 1, 2 do
        g_H5OptionalGiftBox_Two_UI_ActionItem[i]:SetActionItem(-1)
        g_H5OptionalGiftBox_Two_UI_ItemName[i]:SetText("")
        g_H5OptionalGiftBox_Two_UI_ActionChosenMask[i]:Hide()
    end

    if g_H5OptionalGiftBox_Two_CurBagPos >= 0 then
        LifeAbility:Lock_Packet_Item(g_H5OptionalGiftBox_Two_CurBagPos, 0)
    end

    g_H5OptionalGiftBox_Two_CurBagPos = -1
    g_H5OptionalGiftBox_Two_CurSelPos = -1

    g_GiftList[1].id = -1
    g_GiftList[1].num = 0
    g_GiftList[2].id = -1
    g_GiftList[2].num = 0
end

function H5OptionalGiftBox_Two_OnHidden()
    H5OptionalGiftBox_Two_CleanUp()
    this:Hide()
end

function H5OptionalGiftBox_Two_OnGetClicked()
    if g_H5OptionalGiftBox_Two_CurBagPos < 0 then
        return
    end

    if g_H5OptionalGiftBox_Two_CurSelPos < 0 then
        PushDebugMessage(ScriptGlobal_Format("#{TYLB_20220809_09}", 1))
        return
    end

    local item_table_index = PlayerPackage:GetItemTableIndex(g_H5OptionalGiftBox_Two_CurBagPos)

    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("OnClientGetGift")
    Set_XSCRIPT_ScriptID(g_H5OptionalGiftBox_Two_MainScript)
    Set_XSCRIPT_Parameter(0, g_H5OptionalGiftBox_Two_CurBagPos)
    Set_XSCRIPT_Parameter(1, g_H5OptionalGiftBox_Two_CurSelPos)
    Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()

    this:Hide()
end

function H5OptionalGiftBox_Two_Frame_On_ResetPos()
    if g_H5OptionalGiftBox_Two_Frame_UnifiedPosition ~= nil then
        H5OptionalGiftBox_Two_Frame_BK:SetProperty("UnifiedPosition", g_H5OptionalGiftBox_Two_Frame_UnifiedPosition)
    end
end
