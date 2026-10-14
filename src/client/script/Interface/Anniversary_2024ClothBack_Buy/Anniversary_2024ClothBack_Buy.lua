-- Anniversary_2024ClothBack_Buy 选择购买

local g_Anniversary_2024ClothBack_Buy_Frame_UnifiedPosition
local g_nScriptId      = 998460
local g_nUICommandID   = 99846003
local g_ItemData       =
{
    {
        { id = 39923128, price = 32000, name = "#{ZNQSZ_260427_01}" }, -- 锦罗半剪礼盒
        { id = 39923230, price = 25000, name = "#{ZNQSZ_260427_02}" }, -- 吉庆千结礼盒
        { id = 39924951, price = 9598,  name = "#{ZNQSZ_260427_03}" }, -- 青阳山色礼盒
    },
    {
        { id = 39924319, price = 12500, name = "#{ZNQSZ_260427_04}" }, -- 断浪
        { id = 39924105, price = 12500, name = "#{ZNQSZ_260427_05}" }, -- 花间舞
        { id = 39923788, price = 12500, name = "#{ZNQSZ_260427_06}" }, -- 点墨留白
    }
}                                                                      -- 投票出来的物品数据
local g_PerDisCount    = { 10, 10 }                                    --每张折扣券减免比例 %
local g_MaxDisCountNum = { 2, 2 }                                      --最大折扣券张数	


-- 类型 1 时装 2 幻武
local g_nItemType = 0
local g_tabCouponNum = { 0, 0 }
local g_tabCouponText = { "#{ZNQSZ_230301_11}", "#{ZNQSZ_230301_12}" }

local g_cItemTabs = {}
local g_nClickIndex = 0

--=========================================================
-- PreLoad
--=========================================================
function Anniversary_2024ClothBack_Buy_PreLoad()
    this:RegisterEvent("UI_COMMAND") -- UI_COMMAND
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) -- 离开场景
end

--=========================================================
-- OnLoad
--=========================================================
function Anniversary_2024ClothBack_Buy_OnLoad()
    g_Anniversary_2024ClothBack_Buy_Frame_UnifiedPosition = Anniversary_2024ClothBack_Buy_Frame:GetProperty(
        "UnifiedPosition")

    g_cItemTabs[1] =
    {
        icon = Anniversary_2024ClothBack_Buy_Frame_Client1_Icons,
        name = Anniversary_2024ClothBack_Buy_Frame_Client1_Icons_Name,
        num = Anniversary_2024ClothBack_Buy_Frame_Client1_Coupon_Num,
        ybNum = Anniversary_2024ClothBack_Buy_Frame_Client1_YB_Num,
        delete = Anniversary_2024ClothBack_Buy_Frame_Client1_YB_Delete,
        newYB = Anniversary_2024ClothBack_Buy_Frame_Client1_NewYB,
        newYBNum = Anniversary_2024ClothBack_Buy_Frame_Client1_NewYB_Num,
    }
    g_cItemTabs[2] =
    {
        icon = Anniversary_2024ClothBack_Buy_Frame_Client2_Icons,
        name = Anniversary_2024ClothBack_Buy_Frame_Client2_Icons_Name,
        num = Anniversary_2024ClothBack_Buy_Frame_Client2_Coupon_Num,
        ybNum = Anniversary_2024ClothBack_Buy_Frame_Client2_YB_Num,
        delete = Anniversary_2024ClothBack_Buy_Frame_Client2_YB_Delete,
        newYB = Anniversary_2024ClothBack_Buy_Frame_Client2_NewYB,
        newYBNum = Anniversary_2024ClothBack_Buy_Frame_Client2_NewYB_Num,
    }
    g_cItemTabs[3] =
    {
        icon = Anniversary_2024ClothBack_Buy_Frame_Client3_Icons,
        name = Anniversary_2024ClothBack_Buy_Frame_Client3_Icons_Name,
        num = Anniversary_2024ClothBack_Buy_Frame_Client3_Coupon_Num,
        ybNum = Anniversary_2024ClothBack_Buy_Frame_Client3_YB_Num,
        delete = Anniversary_2024ClothBack_Buy_Frame_Client3_YB_Delete,
        newYB = Anniversary_2024ClothBack_Buy_Frame_Client3_NewYB,
        newYBNum = Anniversary_2024ClothBack_Buy_Frame_Client3_NewYB_Num,
    }
end

--=========================================================
-- OnEvent
--=========================================================
function Anniversary_2024ClothBack_Buy_OnEvent(event)
    if (event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID) then
        -- 0 关闭, 1 打开, 2 刷新
        local nOpType = Get_XParam_INT(0)

        -- 关闭界面
        if 0 == nOpType then
            if this:IsVisible() then
                Anniversary_2024ClothBack_Buy_OnClose()
            end
        end

        -- 打开界面
        if 1 == nOpType then
            if this:IsVisible() then
                Anniversary_2024ClothBack_Buy_OnClose()
            end
            Anniversary_2024ClothBack_Buy_Reset()
            Anniversary_2024ClothBack_Buy_ParamInit()
            Anniversary_2024ClothBack_Buy_Update()
            this:Show()
        end
        -- 再次确认
        if 3 == nOpType then
            local strMsg = Get_XParam_STR(0)
            MessageBoxSelf3("Anniversary_2024ClothBack_Buy_OnComfirmedBack",
                { ["Content"] = strMsg, ["Type"] = "YesNo", })
        end
    elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
        Anniversary_2024ClothBack_Buy_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        --切换场景关闭界面
        Anniversary_2024ClothBack_Buy_OnClose()
    end
end

--=========================================================
-- ComfirmedBack
--=========================================================
function Anniversary_2024ClothBack_Buy_OnComfirmedBack(strRet)
    if nil == strRet then
        return
    end

    if "Yes" == strRet or "Ok" == strRet then
        --确认购买
        if g_nItemType ~= 1 and g_nItemType ~= 2 then
            return
        end
        if g_nClickIndex < 1 or g_nClickIndex > 4 then
            return
        end
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("OnBuyComfirm")
        Set_XSCRIPT_ScriptID(g_nScriptId)
        Set_XSCRIPT_Parameter(0, g_nItemType)   --nType
        Set_XSCRIPT_Parameter(1, g_nClickIndex) -- nSubIndex
        Set_XSCRIPT_ParamCount(2)
        Send_XSCRIPT()
    end

    if "No" == strRet then
        -- 关闭二次确认框就行，返回主界面
    end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function Anniversary_2024ClothBack_Buy_ParamInit()
    g_tabCouponNum[1] = Get_XParam_INT(1)
    g_tabCouponNum[2] = Get_XParam_INT(2)
    g_nItemType       = Get_XParam_INT(3)
end

--=========================================================
-- 重置界面参数（归零）
--=========================================================
function Anniversary_2024ClothBack_Buy_Reset()
    g_tabCouponNum[1] = 0
    g_tabCouponNum[2] = 0
    g_nItemType       = 0
end

--=========================================================
-- 界面更新
--=========================================================
function Anniversary_2024ClothBack_Buy_Update()
    for i, itemData in g_ItemData[g_nItemType] do
        local cItemTab = g_cItemTabs[i]

        local theAction = DataPool:CreateBindActionItemForShow(itemData.id, 1)
        cItemTab.icon:SetActionItem(theAction:GetID())
        cItemTab.name:SetText(itemData.name)
        if g_tabCouponNum[g_nItemType] > 0 then
            cItemTab.num:Show()
            cItemTab.num:SetText(ScriptGlobal_Format(g_tabCouponText[g_nItemType], g_tabCouponNum[g_nItemType]))
        else
            cItemTab.num:Hide()
        end
        cItemTab.ybNum:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_28}", itemData.price))
        if g_tabCouponNum[g_nItemType] > 0 then
            local couponNum = g_tabCouponNum[g_nItemType]
            if couponNum > g_MaxDisCountNum[g_nItemType] then
                couponNum = g_MaxDisCountNum[g_nItemType]
            end

            cItemTab.delete:Show()
            cItemTab.newYB:Show()
            cItemTab.newYBNum:Show()
            local newYB = math.floor(itemData.price * (100 - couponNum * g_PerDisCount[g_nItemType]) / 100)
            cItemTab.newYBNum:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_28}", newYB))
        else
            cItemTab.delete:Hide()
            cItemTab.newYB:Hide()
            cItemTab.newYBNum:Hide()
        end
    end
end

--=========================================================
-- 首次点击购买
--=========================================================
function Anniversary_2024ClothBack_Buy_OnBuy(index)
    g_nClickIndex = index
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("OnBuy")
    Set_XSCRIPT_ScriptID(g_nScriptId)
    Set_XSCRIPT_Parameter(0, g_nItemType)   --nType
    Set_XSCRIPT_Parameter(1, g_nClickIndex) -- nSubIndex
    Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end

--=========================================================
-- 点击帮助
--=========================================================
function Anniversary_2024ClothBack_Buy_OnHelp()
end

--=========================================================
-- 关闭界面
--=========================================================
function Anniversary_2024ClothBack_Buy_OnClose()
    this:Hide()
end

--=========================================================
-- 界面隐藏
--=========================================================
function Anniversary_2024ClothBack_Buy_OnHidden()
    this:Hide()
end

function Anniversary_2024ClothBack_Buy_On_ResetPos()
    Anniversary_2024ClothBack_Buy_Frame:SetProperty("UnifiedPosition",
        g_Anniversary_2024ClothBack_Buy_Frame_UnifiedPosition)
end
