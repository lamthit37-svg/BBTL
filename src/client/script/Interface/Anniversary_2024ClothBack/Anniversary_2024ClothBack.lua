-- Anniversary_2024ClothBack 周年庆h5前端

local g_Anniversary_2024ClothBack_Frame_UnifiedPosition
local g_nScriptId        = 998460
local g_nUICommandID     = 99846002
-- local g_Price            = { 25000, 12500 } --投票出来的时装价格 元宝 todo
local g_PerDisCount      = { 10, 10 }                  --每张折扣券减免比例 %
local g_MaxDisCountNum   = { 2, 2 }                    --最大折扣券张数	
local g_ZhekouquanNum    = { 0, 0 }                    -- 折扣卷数量
local g_nBuyRecords      = { 0, 0 }
-- 点击物品的客户端缓存记录，comfirm后服务器已进行完全的检查
-- 点击类型 1 时装 2 幻武
local g_nClickItemType   = 0
local g_tabZheKouQuanPos = { -1, -1, -1, -1 }
--=========================================================
-- PreLoad
--=========================================================
function Anniversary_2024ClothBack_PreLoad()
    this:RegisterEvent("UI_COMMAND") -- UI_COMMAND
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) -- 离开场景
end

--=========================================================
-- OnLoad
--=========================================================
function Anniversary_2024ClothBack_OnLoad()
    g_Anniversary_2024ClothBack_Frame_UnifiedPosition = Anniversary_2024ClothBack_Frame_BK:GetProperty("UnifiedPosition")
end

--=========================================================
-- OnEvent
--=========================================================
function Anniversary_2024ClothBack_OnEvent(event)
    if (event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID) then
        -- 0 关闭, 1 打开, 2 刷新
        local nOpType = Get_XParam_INT(0)

        -- 关闭界面
        if 0 == nOpType then
            if this:IsVisible() then
                Anniversary_2024ClothBack_OnClose()
            end
        end

        -- 打开界面
        if 1 == nOpType then
            Anniversary_2024ClothBack_Reset()
            Anniversary_2024ClothBack_ParamInit()
            Anniversary_2024ClothBack_Update()
            this:Show()
        end
        --2 刷新
        if 2 == nOpType then
            Anniversary_2024ClothBack_ParamInit()
            Anniversary_2024ClothBack_Update()
        end
        -- -- 再次确认
        -- if 3 == nOpType then
        --     local strMsg = Get_XParam_STR(0)
        --     MessageBoxSelf3("Anniversary_2024ClothBack_OnComfirmedBack", { ["Content"] = strMsg, ["Type"] = "YesNo", })
        -- end
    elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
        Anniversary_2024ClothBack_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        --切换场景关闭界面
        Anniversary_2024ClothBack_OnClose()
    end
end

-- --=========================================================
-- -- ComfirmedBack
-- --=========================================================
-- function Anniversary_2024ClothBack_OnComfirmedBack(strRet)
--     if nil == strRet then
--         return
--     end

--     if "Yes" == strRet or "Ok" == strRet then
--         --确认购买
--         if g_nClickItemType ~= 1 and g_nClickItemType ~= 2 then
--             return
--         end
--         Clear_XSCRIPT()
--         Set_XSCRIPT_Function_Name("OnBuyComfirm")
--         Set_XSCRIPT_ScriptID(g_nScriptId)
--         Set_XSCRIPT_Parameter(0, g_nClickItemType) --点击 1时装2幻武 -- nType
--         Set_XSCRIPT_Parameter(1, 0)                --nSubIndex
--         Set_XSCRIPT_ParamCount(2)
--         Send_XSCRIPT()
--     end

--     if "No" == strRet then
--         -- 关闭二次确认框就行，返回主界面
--     end
-- end

-- --===============================================
-- -- change page
-- --===============================================
-- function Anniversary_2024ClothBack_SwitchPage(nPage)
--     if nPage == g_CurPage then
--         return
--     end

--     if nPage < 1 or nPage > 2 then
--         return
--     end

--     g_CurPage = nPage
--     Anniversary_2024ClothBack_Update()
-- end

--=========================================================
-- 界面参数初始化
--=========================================================
function Anniversary_2024ClothBack_ParamInit()
    g_ZhekouquanNum[1] = Get_XParam_INT(1)
    g_ZhekouquanNum[2] = Get_XParam_INT(2)
    g_nBuyRecords[1] = Get_XParam_INT(3)
    g_nBuyRecords[2] = Get_XParam_INT(4)
    g_tabZheKouQuanPos[1] = Get_XParam_INT(5)
    g_tabZheKouQuanPos[2] = Get_XParam_INT(6)
    g_tabZheKouQuanPos[3] = Get_XParam_INT(7)
    g_tabZheKouQuanPos[4] = Get_XParam_INT(8)
end

--=========================================================
-- 重置界面参数（归零）
--=========================================================
function Anniversary_2024ClothBack_Reset()
    g_ZhekouquanNum[1]    = 0
    g_ZhekouquanNum[2]    = 0
    g_nBuyRecords[1]      = 0
    g_nBuyRecords[2]      = 0
    g_nClickItemType      = 0
    g_tabZheKouQuanPos[1] = -1
    g_tabZheKouQuanPos[2] = -1
    g_tabZheKouQuanPos[3] = -1
    g_tabZheKouQuanPos[4] = -1
end

--=========================================================
-- 界面更新
--=========================================================
function Anniversary_2024ClothBack_Update()
    -- 锁住道具
    if g_tabZheKouQuanPos[1] >= 0 then
        LifeAbility:Lock_Packet_Item(g_tabZheKouQuanPos[1], 1)
    end
    if g_tabZheKouQuanPos[2] >= 0 then
        LifeAbility:Lock_Packet_Item(g_tabZheKouQuanPos[2], 1)
    end
    if g_tabZheKouQuanPos[3] >= 0 then
        LifeAbility:Lock_Packet_Item(g_tabZheKouQuanPos[3], 1)
    end
    if g_tabZheKouQuanPos[4] >= 0 then
        LifeAbility:Lock_Packet_Item(g_tabZheKouQuanPos[4], 1)
    end

    Anniversary_2024ClothBack_Update2()
end

-- --=========================================================
-- -- 页签1
-- --=========================================================
-- function Anniversary_2024ClothBack_Update1()
--     -- 页签
--     Anniversary_2024ClothBack_Btn1:SetCheck(1)
--     Anniversary_2024ClothBack_Btn2:SetCheck(0)
--     Anniversary_2024ClothBack_Client1:Show()
--     Anniversary_2024ClothBack_Client2:Hide()
--     Anniversary_2024ClothBack_Client1_Pic_text1bk:Hide()

--     --道具1

--     if g_bFirstCannotBuy == 1 then
--         --如果不让买
--         Anniversary_2024ClothBack_Client1_Pic_text2:Hide() -- 华裳折扣令
--         Anniversary_2024ClothBack_Client1_Pic_Jiage1:Hide()
--         Anniversary_2024ClothBack_Client1_Pic_Jiage2:Hide()
--         Anniversary_2024ClothBack_Client1_Pic_YB_Text:Show() -- 不让购买
--         Anniversary_2024ClothBack_Client1_Pic_Btn:Hide()     -- 购买按钮
--         Anniversary_2024ClothBack_Client1_Pic_Buy_Text:Show()
--     else
--         if g_nZhekouquan_1_Num > g_MaxDisCountNum[1] then
--             g_nZhekouquan_1_Num = g_MaxDisCountNum[1]
--         end
--         Anniversary_2024ClothBack_Client1_Pic_text2:Show() -- 华裳折扣令
--         Anniversary_2024ClothBack_Client1_Pic_text2:SetProperty("Image",
--             "set:Anniversary_2024ClothBack_Client11 image:Anniversary_2024ClothBack_Client1_NoDiscount")

--         Anniversary_2024ClothBack_Client1_Pic_YB_Text:Show() -- 不让购买
--         if g_nBuyRecords[1][1] == 0 then
--             --未购买
--             if g_nZhekouquan_1_Num <= 0 then
--                 --无折扣券 只展示原价
--                 Anniversary_2024ClothBack_Client1_Pic_Jiage2:Show() --无折扣券
--                 Anniversary_2024ClothBack_Client1_Pic_Jiage1:Hide()
--                 Anniversary_2024ClothBack_Client1_Pic_Jiage2_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_240415_23}",
--                     g_Price[1]))
--                 Anniversary_2024ClothBack_Client1_Pic_Jiage2_Text4:Show()
--                 Anniversary_2024ClothBack_Client1_Pic_Jiage2_YuanJiaBK:Show()
--             else
--                 --有折扣券 原价划线  +折扣价
--                 local zhekoujia = g_Price[1] * (100 - g_nZhekouquan_1_Num * g_PerDisCount[1]) / 100
--                 Anniversary_2024ClothBack_Client1_Pic_Jiage1:Show() --有折扣券
--                 Anniversary_2024ClothBack_Client1_Pic_Jiage2:Hide()
--                 Anniversary_2024ClothBack_Client1_Pic_Jiage1_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_23}",
--                     g_Price[1]))
--                 Anniversary_2024ClothBack_Client1_Pic_Jiage1_Text4:Show()
--                 Anniversary_2024ClothBack_Client1_Pic_Jiage1_Text3:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_22}",
--                     zhekoujia))
--                 Anniversary_2024ClothBack_Client1_Pic_Jiage1_Text3:Show()
--                 Anniversary_2024ClothBack_Client1_Pic_Jiage1_Text4_OriginalLine:Show()

--                 Anniversary_2024ClothBack_Client1_Pic_Jiage1_YuanJiaBK:Show()

--                 if g_nZhekouquan_1_Num == 1 then
--                     Anniversary_2024ClothBack_Client1_Pic_text2:SetProperty("Image",
--                         "set:Anniversary_2024ClothBack_Client11 image:Anniversary_2024ClothBack_Client1_9zhe")
--                 end
--                 if g_nZhekouquan_1_Num >= 2 then
--                     Anniversary_2024ClothBack_Client1_Pic_text2:SetProperty("Image",
--                         "set:Anniversary_2024ClothBack_Client11 image:Anniversary_2024ClothBack_Client1_8zhe")
--                 end
--             end
--             Anniversary_2024ClothBack_Client1_Pic_text1bk:Hide() -- 已购买角标
--             Anniversary_2024ClothBack_Client1_Pic_Btn:Show()     -- 购买按钮
--         else
--             Anniversary_2024ClothBack_Client1_Pic_text1bk:Show() --“已购买”图标
--             Anniversary_2024ClothBack_Client1_Pic_Btn:Hide()     -- 购买按钮

--             --只展示原价
--             Anniversary_2024ClothBack_Client1_Pic_Jiage2:Show() --无折扣券
--             Anniversary_2024ClothBack_Client1_Pic_Jiage1:Hide()
--             Anniversary_2024ClothBack_Client1_Pic_Jiage2_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_23}",
--                 g_Price[1]))
--             Anniversary_2024ClothBack_Client1_Pic_Jiage2_Text4:Show()
--             Anniversary_2024ClothBack_Client1_Pic_Jiage2_YuanJiaBK:Show()
--             Anniversary_2024ClothBack_Client1_Pic_text2:Hide()
--         end
--         Anniversary_2024ClothBack_Client1_Pic_YB_Text:Hide()
--         Anniversary_2024ClothBack_Client1_Pic_Buy_Text:Hide()
--     end



--     if g_nZhekouquan_2_Num > g_MaxDisCountNum[2] then
--         g_nZhekouquan_2_Num = g_MaxDisCountNum[2]
--     end
--     Anniversary_2024ClothBack_Client1_Pic1_text2:Show() -- 幻武折扣令
--     Anniversary_2024ClothBack_Client1_Pic1_text2:SetProperty("Image",
--         "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_NoDiscount")
--     --道具2
--     if g_nBuyRecords[1][2] == 0 then
--         --未购买
--         if g_nZhekouquan_2_Num <= 0 then
--             --无折扣券 只展示原价
--             Anniversary_2024ClothBack_Client1_Pic1_Jiage2:Show() --无折扣券
--             Anniversary_2024ClothBack_Client1_Pic1_Jiage1:Hide()
--             Anniversary_2024ClothBack_Client1_Pic1_Jiage2_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_240415_23}",
--                 g_Price[2]))
--             Anniversary_2024ClothBack_Client1_Pic1_Jiage2_Text4:Show()
--             Anniversary_2024ClothBack_Client1_Pic1_Jiage2_YuanJiaBK:Show()
--         else
--             --有折扣券 原价划线  +折扣价
--             local zhekoujia = g_Price[2] * (100 - g_nZhekouquan_2_Num * g_PerDisCount[2]) / 100
--             Anniversary_2024ClothBack_Client1_Pic1_Jiage1:Show() --有折扣券
--             Anniversary_2024ClothBack_Client1_Pic1_Jiage2:Hide()
--             Anniversary_2024ClothBack_Client1_Pic1_Jiage1_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_23}",
--                 g_Price[2]))
--             Anniversary_2024ClothBack_Client1_Pic1_Jiage1_Text4:Show()
--             Anniversary_2024ClothBack_Client1_Pic1_Jiage1_Text3:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_22}",
--                 zhekoujia))
--             Anniversary_2024ClothBack_Client1_Pic1_Jiage1_Text3:Show()
--             Anniversary_2024ClothBack_Client1_Pic1_Jiage1_Text4_OriginalLine:Show()

--             Anniversary_2024ClothBack_Client1_Pic1_Jiage1_YuanJiaBK:Show()
--             if g_nZhekouquan_2_Num == 1 then
--                 Anniversary_2024ClothBack_Client1_Pic1_text2:SetProperty("Image",
--                     "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_9zhe")
--             end
--             if g_nZhekouquan_2_Num >= 2 then
--                 Anniversary_2024ClothBack_Client1_Pic1_text2:SetProperty("Image",
--                     "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_8zhe")
--             end
--         end
--         Anniversary_2024ClothBack_Client1_Pic1_text1bk:Hide() -- 已购买角标
--         Anniversary_2024ClothBack_Client1_Pic1_Btn:Show()     -- 购买按钮
--     else
--         Anniversary_2024ClothBack_Client1_Pic1_text1bk:Show() --“已购买”图标
--         Anniversary_2024ClothBack_Client1_Pic1_Btn:Hide()     -- 购买按钮

--         --只展示原价
--         Anniversary_2024ClothBack_Client1_Pic1_Jiage2:Show() --无折扣券
--         Anniversary_2024ClothBack_Client1_Pic1_Jiage1:Hide()
--         Anniversary_2024ClothBack_Client1_Pic1_Jiage2_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_240415_23}", g_Price[2]))
--         Anniversary_2024ClothBack_Client1_Pic1_Jiage2_Text4:Show()
--         Anniversary_2024ClothBack_Client1_Pic1_Jiage2_YuanJiaBK:Show()
--         Anniversary_2024ClothBack_Client1_Pic1_text2:Hide()
--     end
--     Anniversary_2024ClothBack_Client1_Pic1_YB_Text:Hide()
--     Anniversary_2024ClothBack_Client1_Pic1_Buy_Text:Hide()
-- end

--=========================================================
-- 页签2
--=========================================================
function Anniversary_2024ClothBack_Update2()
    if g_ZhekouquanNum[1] > g_MaxDisCountNum[1] then
        g_ZhekouquanNum[1] = g_MaxDisCountNum[1]
    end
    Anniversary_2024ClothBack_Client2_Pic_text2:Show() -- 华裳折扣令
    Anniversary_2024ClothBack_Client2_Pic_text2:SetProperty("Image",
        "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_NoDiscount")
    --道具1
    -- Anniversary_2024ClothBack_Client1_Pic_Jiage_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_240415_23}", g_Price[1]))

    if g_nBuyRecords[1] == 0 then
        --未购买
        if g_ZhekouquanNum[1] <= 0 then
            --无折扣券 只展示原价
            -- Anniversary_2024ClothBack_Client2_Pic_Jiage1:Hide()
            -- Anniversary_2024ClothBack_Client1_Pic_Jiage:Show()
            Anniversary_2024ClothBack_Client2_Pic_Bk01:Hide()
        else
            --有折扣券 原价划线  +折扣价
            -- local zhekoujia1 = g_Price[1] * (100 - g_ZhekouquanNum[1] * g_PerDisCount[1]) / 100
            -- Anniversary_2024ClothBack_Client2_Pic_Jiage1_Text3:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_22}", zhekoujia1))
            -- Anniversary_2024ClothBack_Client2_Pic_Jiage1_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_23}", g_Price[1]))
            -- Anniversary_2024ClothBack_Client2_Pic_Jiage1:Show()
            -- Anniversary_2024ClothBack_Client1_Pic_Jiage:Hide()
            Anniversary_2024ClothBack_Client2_Pic_Bk01:Show()
            if g_ZhekouquanNum[1] == 1 then
                Anniversary_2024ClothBack_Client2_Pic_text2:SetProperty("Image",
                    "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_9zhe")
            end
            if g_ZhekouquanNum[1] >= 2 then
                Anniversary_2024ClothBack_Client2_Pic_text2:SetProperty("Image",
                    "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_8zhe")
            end
        end
        Anniversary_2024ClothBack_Client2_Pic_text1bk:Hide() -- 已购买角标
        Anniversary_2024ClothBack_Client2_Pic_Btn:Show()     -- 购买按钮
    else
        Anniversary_2024ClothBack_Client2_Pic_text1bk:Show() --“已购买”图标
        Anniversary_2024ClothBack_Client2_Pic_Btn:Hide()     -- 购买按钮
        Anniversary_2024ClothBack_Client2_Pic_Bk01:Hide()
    end


    if g_ZhekouquanNum[2] > g_MaxDisCountNum[2] then
        g_ZhekouquanNum[2] = g_MaxDisCountNum[2]
    end
    Anniversary_2024ClothBack_Client2_Pic1_text2:Show() -- 幻武折扣令
    Anniversary_2024ClothBack_Client2_Pic1_text2:SetProperty("Image",
        "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_NoDiscount")
    --道具2
    -- Anniversary_2024ClothBack_Client2_Pic1_Jiage2_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_240415_23}", g_Price[2]))
    if g_nBuyRecords[2] == 0 then
        --未购买
        if g_ZhekouquanNum[2] <= 0 then
            --无折扣券 只展示原价
            -- Anniversary_2024ClothBack_Client2_Pic1_Jiage1:Hide()
            -- Anniversary_2024ClothBack_Client2_Pic1_Jiage2:Show()
            Anniversary_2024ClothBack_Client2_Pic1_Bk01:Hide()
        else
            --有折扣券 原价划线  +折扣价
            -- local zhekoujia = g_Price[2] * (100 - g_ZhekouquanNum[2] * g_PerDisCount[2]) / 100
            -- Anniversary_2024ClothBack_Client2_Pic1_Jiage1_Text3:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_22}", zhekoujia))
            -- Anniversary_2024ClothBack_Client2_Pic1_Jiage1_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_23}", g_Price[2]))
            -- Anniversary_2024ClothBack_Client2_Pic1_Jiage1:Show()
            -- Anniversary_2024ClothBack_Client2_Pic1_Jiage2:Hide()
            Anniversary_2024ClothBack_Client2_Pic1_Bk01:Show()

            if g_ZhekouquanNum[2] == 1 then
                Anniversary_2024ClothBack_Client2_Pic1_text2:SetProperty("Image",
                    "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_9zhe")
            end
            if g_ZhekouquanNum[2] >= 2 then
                Anniversary_2024ClothBack_Client2_Pic1_text2:SetProperty("Image",
                    "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_8zhe")
            end
        end
        Anniversary_2024ClothBack_Client2_Pic1_text1bk:Hide() -- 已购买角标
        Anniversary_2024ClothBack_Client2_Pic1_Btn:Show()     -- 购买按钮
    else
        Anniversary_2024ClothBack_Client2_Pic1_text1bk:Show() --“已购买”图标
        Anniversary_2024ClothBack_Client2_Pic1_Btn:Hide()     -- 购买按钮
        -- Anniversary_2024ClothBack_Client2_Pic1_Jiage1:Hide()
        -- Anniversary_2024ClothBack_Client2_Pic1_Jiage2:Show()
        Anniversary_2024ClothBack_Client2_Pic1_Bk01:Hide()
    end
end

-- --=========================================================
-- -- 首次点击购买
-- --=========================================================
-- function Anniversary_2024ClothBack_onBuy()
--     Clear_XSCRIPT()
--     Set_XSCRIPT_Function_Name("OnBuy")
--     Set_XSCRIPT_ScriptID(g_nScriptId)
--     Set_XSCRIPT_Parameter(0, g_nClickItemType) --nType
--     Set_XSCRIPT_Parameter(1, 0)                --nSubIndex
--     Set_XSCRIPT_ParamCount(2)
--     Send_XSCRIPT()
-- end

--=========================================================
-- 显示选择购买页面
--=========================================================
function Anniversary_2024ClothBack_onChooseBuy(op)
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("OnShowChooseBuy")
    Set_XSCRIPT_ScriptID(g_nScriptId)
    Set_XSCRIPT_Parameter(0, op)               --op
    Set_XSCRIPT_Parameter(1, g_nClickItemType) --nType
    Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end

-- --=========================================================
-- -- 点击购买时装1
-- --=========================================================
-- function Anniversary_2024ClothBack_Client1_OnBuy()
--     g_nClickItemType = 1
--     Anniversary_2024ClothBack_onBuy()
-- end

-- --=========================================================
-- -- 点击购买幻武1
-- --=========================================================
-- function Anniversary_2024ClothBack_Client1_OnBuy1()
--     g_nClickItemType = 2
--     Anniversary_2024ClothBack_onBuy()
-- end

--=========================================================
-- 点击购买时装2
--=========================================================
function Anniversary_2024ClothBack_Client2_OnBuy()
    g_nClickItemType = 1
    Anniversary_2024ClothBack_onChooseBuy(1)
end

--=========================================================
-- 点击购买幻武2
--=========================================================
function Anniversary_2024ClothBack_Client2_OnBuy1()
    g_nClickItemType = 2
    Anniversary_2024ClothBack_onChooseBuy(1)
end

--=========================================================
-- 点击帮助
--=========================================================
function Anniversary_2024ClothBack_OnHelp()
end

--=========================================================
-- 关闭界面
--=========================================================
function Anniversary_2024ClothBack_OnClose()
    if g_tabZheKouQuanPos[1] >= 0 then
        LifeAbility:Lock_Packet_Item(g_tabZheKouQuanPos[1], 0)
    end
    if g_tabZheKouQuanPos[2] >= 0 then
        LifeAbility:Lock_Packet_Item(g_tabZheKouQuanPos[2], 0)
    end
    if g_tabZheKouQuanPos[3] >= 0 then
        LifeAbility:Lock_Packet_Item(g_tabZheKouQuanPos[3], 0)
    end
    if g_tabZheKouQuanPos[4] >= 0 then
        LifeAbility:Lock_Packet_Item(g_tabZheKouQuanPos[4], 0)
    end
    Anniversary_2024ClothBack_onChooseBuy(0)
    this:Hide()
end

--=========================================================
-- 界面隐藏
--=========================================================
function Anniversary_2024ClothBack_OnHidden()
    -- 重置
    if g_tabZheKouQuanPos[1] >= 0 then
        LifeAbility:Lock_Packet_Item(g_tabZheKouQuanPos[1], 0)
    end
    if g_tabZheKouQuanPos[2] >= 0 then
        LifeAbility:Lock_Packet_Item(g_tabZheKouQuanPos[2], 0)
    end
    if g_tabZheKouQuanPos[3] >= 0 then
        LifeAbility:Lock_Packet_Item(g_tabZheKouQuanPos[3], 0)
    end
    if g_tabZheKouQuanPos[4] >= 0 then
        LifeAbility:Lock_Packet_Item(g_tabZheKouQuanPos[4], 0)
    end
    Anniversary_2024ClothBack_onChooseBuy(0)
    this:Hide()
end

function Anniversary_2024ClothBack_On_ResetPos()
    Anniversary_2024ClothBack_Frame_BK:SetProperty("UnifiedPosition", g_Anniversary_2024ClothBack_Frame_UnifiedPosition)
end
