--!!!reloadscript =T3WarmUpJinLingMatch
local g_Frame_UnifiedPosition = nil

local g_MAX_SDJL_MSG = 10

local g_RedPointFlagNum = 17

local g_MsgNum = {
    [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 0
}

local g_MsgTips = {
    [1] = "#{JLSS_210126_28}",[2] = "#{JLSS_210126_82}",[3] = "#{JLSS_210126_83}",[4] = "#{JLSS_210126_84}",[5] = "#{JLSS_210126_85}",
    [6] = "#{JLSS_210126_86}",[7] = "#{JLSS_210126_87}",[8] = "#{JLSS_210126_88}",[9] = "#{JLSS_210126_89}",[10] = "#{JLSS_210126_90}",
}

local g_PoolInfo = {
    [1] = "#{JLSS_210126_93}",[2] = "#{JLSS_210126_95}",[3] = "#{JLSS_210126_97}",[4] = "#{JLSS_210126_99}"
}
local g_PoolTips = {
    [1] = "#{JLSS_210126_92}",[2] = "#{JLSS_210126_94}",[3] = "#{JLSS_210126_96}",[4] = "#{JLSS_210126_98}",
}

local g_PoolBtn = {}


local g_MsgBtn = {}
local g_MsgBtnRedPoint = {}
local g_MsgBtnNumText = {}
local g_MsgBtnImg = {}

local g_PrizeBtn = {}
local g_PrizeBtnRedPoint = {}
local g_PrizeBtnMask = {}
local g_PrizeBtnBK = {}
local g_PrizeProgressImg ={}

local g_LeftBtnTab = {}

local g_AccPrizeNeedTimesText = {}

local g_Frame = {}

local g_UI2SubFrame = {}

local g_PoollevelImages = {
    [1] = {
            name = "set:T3WarmUpJinLing image:baoxiangbigname_01",
            before = "set:T3WarmUpJinLing image:baoxiangbig_01_Normal",
            after = "set:T3WarmUpJinLing image:baoxiangbig_01_Hover"
        },
    [2] = {
            name = "set:T3WarmUpJinLing image:baoxiangbigname_02",
            before = "set:T3WarmUpJinLing image:baoxiangbig_02_Normal",
            after = "set:T3WarmUpJinLing image:baoxiangbig_02_Hover"
        },
    [3] = {
            name = "set:T3WarmUpJinLing image:baoxiangbigname_03",
            before = "set:T3WarmUpJinLing2 image:baoxiangbig_03_Normal",
            after = "set:T3WarmUpJinLing2 image:baoxiangbig_03_Hover"
        },
    [4] = {
            name = "set:T3WarmUpJinLing image:baoxiangbigname_04",
            before = "set:T3WarmUpJinLing2 image:baoxiangbig_03_Normal",
            after = "set:T3WarmUpJinLing2 image:baoxiangbig_03_Hover"
        },
}

local g_MsgImgs = {
    [1] = {normal = "set:T3WarmUpJinLing image:05_Normal",disable = "set:T3WarmUpJinLing2 image:05_Disabled"},
    [2] = {normal = "set:T3WarmUpJinLing image:09_Normal",disable = "set:T3WarmUpJinLing2 image:09_Disabled"},
    [3] = {normal = "set:T3WarmUpJinLing image:10_Normal",disable = "set:T3WarmUpJinLing2 image:10_Disabled"},
    [4] = {normal = "set:T3WarmUpJinLing image:06_Normal",disable = "set:T3WarmUpJinLing2 image:06_Disabled"},
    [5] = {normal = "set:T3WarmUpJinLing image:07_Normal",disable = "set:T3WarmUpJinLing2 image:07_Disabled"},
    [6] = {normal = "set:T3WarmUpJinLing image:04_Normal",disable = "set:T3WarmUpJinLing2 image:04_Disabled"},
    [7] = {normal = "set:T3WarmUpJinLing image:08_Normal",disable = "set:T3WarmUpJinLing2 image:08_Disabled"},
    [8] = {normal = "set:T3WarmUpJinLing image:03_Normal",disable = "set:T3WarmUpJinLing2 image:03_Disabled"},
    [9] = {normal = "set:T3WarmUpJinLing image:02_Normal",disable = "set:T3WarmUpJinLing2 image:02_Disabled"},
    [10] = {normal = "set:T3WarmUpJinLing image:01_Normal",disable = "set:T3WarmUpJinLing2 image:01_Disabled"},
}



local g_ExeScript = 888380

local g_MsgChoose = 0
--累计领取次数
local g_GetPrizeTimes = 0

--累计奖励 对应的次数
local g_AccPrizeNeedTimes = {
    [1] = 1,
    [2] = 3,
    [3] = 5,
    [4] = 8,
    [5] = 12,
}


function T3WarmUpJinLingMatch_PreLoad()
	this:RegisterEvent("SDJL_UI", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function T3WarmUpJinLingMatch_OnLoad()
    g_Frame_UnifiedPosition = T3WarmUpJinLingMatch_Frame:GetProperty("UnifiedPosition")
    g_MsgBtn[1] = T3WarmUpJinLingMatchList_Info2Item1Icon
    g_MsgBtn[2] = T3WarmUpJinLingMatchList_Info2Item2Icon
    g_MsgBtn[3] = T3WarmUpJinLingMatchList_Info2Item3Icon
    g_MsgBtn[4] = T3WarmUpJinLingMatchList_Info2Item4Icon
    g_MsgBtn[5] = T3WarmUpJinLingMatchList_Info2Item5Icon
    g_MsgBtn[6] = T3WarmUpJinLingMatchList_Info2Item6Icon
    g_MsgBtn[7] = T3WarmUpJinLingMatchList_Info2Item7Icon
    g_MsgBtn[8] = T3WarmUpJinLingMatchList_Info2Item8Icon
    g_MsgBtn[9] = T3WarmUpJinLingMatchList_Info2Item9Icon
    g_MsgBtn[10] = T3WarmUpJinLingMatchList_Info2Item10Icon

    g_MsgBtnRedPoint[1] = T3WarmUpJinLingMatch_Info2Item1_Tips
    g_MsgBtnRedPoint[2] = T3WarmUpJinLingMatch_Info2Item2_Tips
    g_MsgBtnRedPoint[3] = T3WarmUpJinLingMatch_Info2Item3_Tips
    g_MsgBtnRedPoint[4] = T3WarmUpJinLingMatch_Info2Item4_Tips
    g_MsgBtnRedPoint[5] = T3WarmUpJinLingMatch_Info2Item5_Tips
    g_MsgBtnRedPoint[6] = T3WarmUpJinLingMatch_Info2Item6_Tips
    g_MsgBtnRedPoint[7] = T3WarmUpJinLingMatch_Info2Item7_Tips
    g_MsgBtnRedPoint[8] = T3WarmUpJinLingMatch_Info2Item8_Tips
    g_MsgBtnRedPoint[9] = T3WarmUpJinLingMatch_Info2Item9_Tips
    g_MsgBtnRedPoint[10] = T3WarmUpJinLingMatch_Info2Item10_Tips

    g_MsgBtnNumText[1] = T3WarmUpJinLingMatch_Info2Item1Text
    g_MsgBtnNumText[2] = T3WarmUpJinLingMatch_Info2Item2Text
    g_MsgBtnNumText[3] = T3WarmUpJinLingMatch_Info2Item3Text
    g_MsgBtnNumText[4] = T3WarmUpJinLingMatch_Info2Item4Text
    g_MsgBtnNumText[5] = T3WarmUpJinLingMatch_Info2Item5Text
    g_MsgBtnNumText[6] = T3WarmUpJinLingMatch_Info2Item6Text
    g_MsgBtnNumText[7] = T3WarmUpJinLingMatch_Info2Item7Text
    g_MsgBtnNumText[8] = T3WarmUpJinLingMatch_Info2Item8Text
    g_MsgBtnNumText[9] = T3WarmUpJinLingMatch_Info2Item9Text
    g_MsgBtnNumText[10] = T3WarmUpJinLingMatch_Info2Item10Text

    g_MsgBtnImg[1] = T3WarmUpJinLingMatch_Info2Item1
    g_MsgBtnImg[2] = T3WarmUpJinLingMatch_Info2Item2
    g_MsgBtnImg[3] = T3WarmUpJinLingMatch_Info2Item3
    g_MsgBtnImg[4] = T3WarmUpJinLingMatch_Info2Item4
    g_MsgBtnImg[5] = T3WarmUpJinLingMatch_Info2Item5
    g_MsgBtnImg[6] = T3WarmUpJinLingMatch_Info2Item6
    g_MsgBtnImg[7] = T3WarmUpJinLingMatch_Info2Item7
    g_MsgBtnImg[8] = T3WarmUpJinLingMatch_Info2Item8
    g_MsgBtnImg[9] = T3WarmUpJinLingMatch_Info2Item9
    g_MsgBtnImg[10] = T3WarmUpJinLingMatch_Info2Item10

    g_PrizeBtn[1] = T3WarmUpJinLingMatchGift_Item1
    g_PrizeBtn[2] = T3WarmUpJinLingMatchGift_Item2
    g_PrizeBtn[3] = T3WarmUpJinLingMatchGift_Item3
    g_PrizeBtn[4] = T3WarmUpJinLingMatchGift_Item4
    g_PrizeBtn[5] = T3WarmUpJinLingMatchGift_Item5

    g_PrizeBtnRedPoint[1] = T3WarmUpJinLingMatchGift_Item1_Tips
    g_PrizeBtnRedPoint[2] = T3WarmUpJinLingMatchGift_Item2_Tips
    g_PrizeBtnRedPoint[3] = T3WarmUpJinLingMatchGift_Item3_Tips
    g_PrizeBtnRedPoint[4] = T3WarmUpJinLingMatchGift_Item4_Tips
    g_PrizeBtnRedPoint[5] = T3WarmUpJinLingMatchGift_Item5_Tips

    g_PrizeBtnMask[1] =  T3WarmUpJinLingMatchGift_Item1_Mask
    g_PrizeBtnMask[2] =  T3WarmUpJinLingMatchGift_Item2_Mask
    g_PrizeBtnMask[3] =  T3WarmUpJinLingMatchGift_Item3_Mask
    g_PrizeBtnMask[4] =  T3WarmUpJinLingMatchGift_Item4_Mask
    g_PrizeBtnMask[5] =  T3WarmUpJinLingMatchGift_Item5_Mask

    g_AccPrizeNeedTimesText[1] = T3WarmUpJinLingMatchGift_Item1_Text
    g_AccPrizeNeedTimesText[2] = T3WarmUpJinLingMatchGift_Item2_Text
    g_AccPrizeNeedTimesText[3] = T3WarmUpJinLingMatchGift_Item3_Text
    g_AccPrizeNeedTimesText[4] = T3WarmUpJinLingMatchGift_Item4_Text
    g_AccPrizeNeedTimesText[5] = T3WarmUpJinLingMatchGift_Item5_Text

    g_PrizeBtnBK[1] = T3WarmUpJinLingMatchGift_Item1BK
    g_PrizeBtnBK[2] = T3WarmUpJinLingMatchGift_Item2BK
    g_PrizeBtnBK[3] = T3WarmUpJinLingMatchGift_Item3BK
    g_PrizeBtnBK[4] = T3WarmUpJinLingMatchGift_Item4BK
    g_PrizeBtnBK[5] = T3WarmUpJinLingMatchGift_Item5BK

    g_PrizeProgressImg[2] = T3WarmUpJinLingMatchGift_Progress1
    g_PrizeProgressImg[3] = T3WarmUpJinLingMatchGift_Progress2
    g_PrizeProgressImg[4] = T3WarmUpJinLingMatchGift_Progress3
    g_PrizeProgressImg[5] = T3WarmUpJinLingMatchGift_Progress4



    g_LeftBtnTab[1] = T3WarmUpJinLingMatch_Buttontab01
    g_LeftBtnTab[2] = T3WarmUpJinLingMatch_Buttontab02
    g_LeftBtnTab[3] = T3WarmUpJinLingMatch_Buttontab03

    g_Frame[1] = T3WarmUpJinLingMatch
    g_Frame[2] = T3WarmUpJinLingMatchGift
    g_Frame[3] = T3WarmUpJinLingMatchWX

    g_PoolBtn[1] =T3WarmUpJinLingMatchGift_P1Box1
    g_PoolBtn[2] =T3WarmUpJinLingMatchGift_P1Box2 
    g_PoolBtn[3] =T3WarmUpJinLingMatchGift_P1Box3 
    g_PoolBtn[4] =T3WarmUpJinLingMatchGift_P1Box4  
    
end

function T3WarmUpJinLingMatch_OnEvent(event)
    if event == "SDJL_UI" then
    --第一个参数opt:
    --  0 关闭
    --  1 打开界面1
    --  2 刷新界面1
    --  3 打开界面2
    --  4 刷新界面2
    --  5 鼠标选完人了
    --  6 服务端要求选人
    --  7 二次确认
    --  8 选择奖励
    --  9 打开界面3 ..
    local Opt = tonumber(arg0)
    if 6 == Opt then
        --鼠标进入点人状态 关闭界面
        MouseEnterGiveMessage()
        if this:IsVisible() then
            T3WarmUpJinLingMatch_Close()
        end
        return 
    elseif 5 == Opt then
        if IsInTServer()  == 1 then
            PushDebugMessage("#{JLSS_210126_43}")
            return
        end
        local targetID = tonumber(arg1)
        if targetID < 15000 then
            return 
        end
        Clear_XSCRIPT()
        Set_XSCRIPT_ScriptID( g_ExeScript )
        Set_XSCRIPT_Function_Name( "OnGiveMessage" )
        Set_XSCRIPT_Parameter(0, g_MsgChoose)
        Set_XSCRIPT_Parameter(1, targetID)
        Set_XSCRIPT_Parameter(2, 1)
        Set_XSCRIPT_ParamCount( 3 )
        Send_XSCRIPT()
        return 
    --elseif 7 == Opt then
        --二次确认  MessageBox_Self2
    --elseif 8 == Opt then
        --选择奖励  T3WarmUpJinLingAward
    elseif 0 == Opt then
        T3WarmUpJinLingMatch_Close()
        return 
    elseif 2 == Opt then --刷新界面1
        if T3WarmUpJinLingMatch:IsVisible() then	
            T3WarmUpJinLingMatch_OpenUI1()
        end
    elseif 4 == Opt then --刷新界面2
        if T3WarmUpJinLingMatchGift:IsVisible() then	
            T3WarmUpJinLingMatch_OpenUI2()
        end
    elseif 1 == Opt then --打开界面1
        T3WarmUpJinLingMatch_OpenUI1()
    elseif 3 == Opt then --打开界面2
        T3WarmUpJinLingMatch_OpenUI2()
    elseif 9 == Opt then --打开界面3
        T3WarmUpJinLingMatch_OpenUI3()
    end
	elseif event == "VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then
        T3WarmUpJinLingMatch_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
		T3WarmUpJinLingMatch_Close()
	end

end

function T3WarmUpJinLingMatch_OpenUI1()
    g_MsgChoose = 0
    g_MsgNum[1],g_MsgNum[2],g_MsgNum[3],g_MsgNum[4],g_MsgNum[5],g_MsgNum[6],g_MsgNum[7],g_MsgNum[8],g_MsgNum[9],g_MsgNum[10]=
        tonumber(arg1),tonumber(arg2),tonumber(arg3),tonumber(arg4),tonumber(arg5),tonumber(arg6),tonumber(arg7),tonumber(arg8),tonumber(arg9),tonumber(arg10)

    for i=1,g_MAX_SDJL_MSG do
        g_MsgBtn[i]:SetCheck(0)
    end 
    --msg数量
    for i =1, g_MAX_SDJL_MSG do
        local msgNum = g_MsgNum[i]
        local str = ""
        if msgNum == 0 then
            str = "#{JLSS_210126_127}"
        else
            str = ScriptGlobal_Format("#{JLSS_210126_128}",msgNum)
        end
        g_MsgBtnNumText[i]:SetText(str)
        if g_MsgNum[i] > 0 then
            g_MsgBtnImg[i]:SetProperty("Image", g_MsgImgs[i].normal )
        else
            g_MsgBtnImg[i]:SetProperty("Image", g_MsgImgs[i].disable )
        end
        g_MsgBtn[i]:SetToolTip(g_MsgTips[i])
    end
    --红点
    local redPointData = T3WarmUpJinLingMatch_GetBitTable(tonumber(arg11))
    local kinds = tonumber(arg12)

    --卡片收集进度
    T3WarmUpJinLingMatch_Info2:SetText(ScriptGlobal_Format("#{JLSS_210126_126}",kinds))

    --本页签红点
    T3WarmUpJinLingMatch_Buttontab01_Tips:Hide()
    for i = 1, g_MAX_SDJL_MSG do
        if redPointData[i] == 1 then
            --显示红点
            g_MsgBtnRedPoint[i]:Show()
            T3WarmUpJinLingMatch_Buttontab01_Tips:Show()
        else
            g_MsgBtnRedPoint[i]:Hide()
        end
    end

    --如果 另一个页面有需要显示的红点 则该页签显示红点
    T3WarmUpJinLingMatch_Buttontab02_Tips:Hide()
    for i = g_MAX_SDJL_MSG+1 , g_RedPointFlagNum-1 do
        if redPointData[i] == 1 then
            T3WarmUpJinLingMatch_Buttontab02_Tips:Show()
            break;
        end
    end

    if redPointData[g_RedPointFlagNum] == 1 then
        T3WarmUpJinLingMatch_Buttontab03_Tips:Show()
    else
        T3WarmUpJinLingMatch_Buttontab03_Tips:Hide()
    end

    

    g_LeftBtnTab[1]:SetCheck(1)
    g_LeftBtnTab[2]:SetCheck(0)
    g_LeftBtnTab[3]:SetCheck(0)


    this:Show()
    g_Frame[1]:Show()
    g_Frame[2]:Hide()
    g_Frame[3]:Hide()
end

function T3WarmUpJinLingMatch_OpenUI2()
    local redPointData = T3WarmUpJinLingMatch_GetBitTable(tonumber(arg1))
    local getPrizeLevel = tonumber(arg2)
    local state = tonumber(arg3)
    local getPrizeTimes = 0
    
    if 1 == state then
        T3WarmUpJinLingMatchGift_Info:SetText("#{JLSS_210126_58}")
        T3WarmUpJinLingMatchGift_P1:Show()
        T3WarmUpJinLingMatchGift_P2:Hide()
        --1.赛前阶段 4个按钮 每点一个按钮 显示一段文字
        T3WarmUpJinLingMatchGift_P1Text:SetText("")
        for i =1,table.getn(g_PoolBtn) do
                g_PoolBtn[i]:SetCheck(0)
        end
        T3WarmUpJinLingMatch_P1BoxClicked(4)
        --g_LeftBtnTab[1]:Enable()
    else
        local activePoint = tonumber(arg4)
        getPrizeTimes = tonumber(arg5)
        --奖池level 1:未集齐不是城主 2.未集齐是城主 3.集齐不是城主 4.集齐是城主 
        local poolLevel = tonumber(arg6)
        T3WarmUpJinLingMatchGift_Info:SetText("#{JLSS_210126_138}")
        T3WarmUpJinLingMatchGift_ActiveNum:SetText(ScriptGlobal_Format("#{JLSS_210126_66}",activePoint))
        --T3WarmUpJinLingMatchGift_ActiveTimes:SetText(ScriptGlobal_Format("#{JLSS_210126_75}",getPrizeTimes))
        T3WarmUpJinLingMatchGift_P2:Show()
        T3WarmUpJinLingMatchGift_P1:Hide()
        T3WarmUpJinLingMatchGift_P2BoxName:SetProperty("Image", g_PoollevelImages[poolLevel].name )
        --g_LeftBtnTab[1]:Disable()
        T3WarmUpJinLingMatchGift_PickText:Hide()
        if 2 == state then
            --2.赛后 未抽奖
            T3WarmUpJinLingMatchGift_P2Box:SetToolTip(g_PoolTips[poolLevel])
            T3WarmUpJinLingMatchGift_P2Box_Item1:Hide()
            T3WarmUpJinLingMatchGift_P2Box_Item2:Hide()
            T3WarmUpJinLingMatchGift_P2Box_Item3:Hide()
            T3WarmUpJinLingMatchGift_P2Box_Item4:Hide()
            T3WarmUpJinLingMatchGift_P2Box_Item5:Hide()
            T3WarmUpJinLingMatchGift_P2Box_Item6:Hide()
            T3WarmUpJinLingMatchGift_P2Box:SetProperty("Image", g_PoollevelImages[poolLevel].before )
            T3WarmUpJinLingMatchGift_Pick:Enable()
            if poolLevel == 4 and getPrizeTimes == 0 then
                T3WarmUpJinLingMatchGift_PickText:Show()
            end
        elseif 3 == state or 4 == state  then
            --3.抽完 我也看完了 --4.抽完 我想看一次
            if 3 == state then
                T3WarmUpJinLingMatchGift_P2Box_Item1:Hide()
                T3WarmUpJinLingMatchGift_P2Box_Item2:Hide()
                T3WarmUpJinLingMatchGift_P2Box_Item3:Hide()
                T3WarmUpJinLingMatchGift_P2Box_Item4:Hide()
                T3WarmUpJinLingMatchGift_P2Box_Item5:Hide()
                T3WarmUpJinLingMatchGift_P2Box_Item6:Hide()
            elseif 4 == state then
                local ShowID = tonumber(arg7)
                local num = tonumber(arg8)
                local gotSP1 = tonumber(arg9) --剪纸风车
                local gotSP2 = tonumber(arg10)  --金色心决
                if gotSP1 == 0 and gotSP2 == 0 then
                    T3WarmUpJinLingMatchGift_P2Box_Item1:Show()
                    T3WarmUpJinLingMatchGift_P2Box_Item2:Hide()
                    T3WarmUpJinLingMatchGift_P2Box_Item3:Hide()
                    T3WarmUpJinLingMatchGift_P2Box_Item4:Hide()
                    T3WarmUpJinLingMatchGift_P2Box_Item5:Hide()
                    T3WarmUpJinLingMatchGift_P2Box_Item6:Hide()
                    local theAction =  DataPool:CreateActionItemForShow(ShowID, num)
                    if nil~= theAction then
                        T3WarmUpJinLingMatchGift_P2Box_Item1:SetActionItem(theAction:GetID())
                    end
                    T3WarmUpJinLingMatchGift_P2Box_Item1:Enable()
                    T3WarmUpJinLingMatchGift_P2Box_Item1Animate:Show()
                    T3WarmUpJinLingMatchGift_P2Box_Item1Mask:Hide()
                elseif gotSP1 ~=0 and gotSP2 ~= 0 then
                    T3WarmUpJinLingMatchGift_P2Box_Item1:Hide()
                    T3WarmUpJinLingMatchGift_P2Box_Item2:Hide()
                    T3WarmUpJinLingMatchGift_P2Box_Item3:Hide()
                    T3WarmUpJinLingMatchGift_P2Box_Item4:Show()
                    T3WarmUpJinLingMatchGift_P2Box_Item5:Show()
                    T3WarmUpJinLingMatchGift_P2Box_Item6:Show()
                    local theAction =  DataPool:CreateActionItemForShow(ShowID, num)
                    if nil~= theAction then
                        T3WarmUpJinLingMatchGift_P2Box_Item4:SetActionItem(theAction:GetID())
                    end
                    T3WarmUpJinLingMatchGift_P2Box_Item4:Enable()
                    T3WarmUpJinLingMatchGift_P2Box_Item4Animate:Show()
                    T3WarmUpJinLingMatchGift_P2Box_Item4Mask:Hide()
                    theAction =  DataPool:CreateActionItemForShow(gotSP1, 1)
                    if nil~= theAction then
                        T3WarmUpJinLingMatchGift_P2Box_Item5:SetActionItem(theAction:GetID())
                    end
                    T3WarmUpJinLingMatchGift_P2Box_Item5:Enable()
                    T3WarmUpJinLingMatchGift_P2Box_Item5Animate:Show()
                    T3WarmUpJinLingMatchGift_P2Box_Item5Mask:Hide()
                    theAction =  DataPool:CreateActionItemForShow(gotSP2, 1)
                    if nil~= theAction then
                        T3WarmUpJinLingMatchGift_P2Box_Item6:SetActionItem(theAction:GetID())
                    end
                    T3WarmUpJinLingMatchGift_P2Box_Item6:Enable()
                    T3WarmUpJinLingMatchGift_P2Box_Item6Animate:Show()
                    T3WarmUpJinLingMatchGift_P2Box_Item6Mask:Hide()

                elseif gotSP1 ~= 0 or gotSP2 ~= 0 then
                    T3WarmUpJinLingMatchGift_P2Box_Item1:Hide()
                    T3WarmUpJinLingMatchGift_P2Box_Item2:Show()
                    T3WarmUpJinLingMatchGift_P2Box_Item3:Show()
                    T3WarmUpJinLingMatchGift_P2Box_Item4:Hide()
                    T3WarmUpJinLingMatchGift_P2Box_Item5:Hide()
                    T3WarmUpJinLingMatchGift_P2Box_Item6:Hide()
                    local theAction =  DataPool:CreateActionItemForShow(ShowID, num)
                    if nil~= theAction then
                        T3WarmUpJinLingMatchGift_P2Box_Item2:SetActionItem(theAction:GetID())
                    end
                    T3WarmUpJinLingMatchGift_P2Box_Item2:Enable()
                    T3WarmUpJinLingMatchGift_P2Box_Item2Animate:Show()
                    T3WarmUpJinLingMatchGift_P2Box_Item2Mask:Hide()
                    if  gotSP1 ~= 0 then
                        theAction =  DataPool:CreateActionItemForShow(gotSP1, 1)
                    else
                        theAction =  DataPool:CreateActionItemForShow(gotSP2, 1)
                    end
                    if nil~= theAction then
                        T3WarmUpJinLingMatchGift_P2Box_Item3:SetActionItem(theAction:GetID())
                    end
                    T3WarmUpJinLingMatchGift_P2Box_Item3:Enable()
                    T3WarmUpJinLingMatchGift_P2Box_Item3Animate:Show()
                    T3WarmUpJinLingMatchGift_P2Box_Item3Mask:Hide()
                end
            end
            T3WarmUpJinLingMatchGift_P2Box:SetToolTip(g_PoolTips[poolLevel])
            T3WarmUpJinLingMatchGift_P2Box:SetProperty("Image", g_PoollevelImages[poolLevel].after )
            T3WarmUpJinLingMatchGift_Pick:Disable()
        elseif 5 == state then
            --特殊刷新一次 只刷新累计领奖部分 避免把光环特效刷没了
        end
    end
    --累计抽奖次数
    if 1 == state then
        T3WarmUpJinLingMatchGift_ActiveTimesOpen:Show()
        T3WarmUpJinLingMatchGift_ActiveTimes:Hide()
        T3WarmUpJinLingMatchGift_ActiveTimesNumber:Hide()
    else
        T3WarmUpJinLingMatchGift_ActiveTimesOpen:Hide()
        T3WarmUpJinLingMatchGift_ActiveTimes:Show()
        T3WarmUpJinLingMatchGift_ActiveTimesNumber:Show()
        T3WarmUpJinLingMatchGift_ActiveTimesNumber:SetText("#M"..tostring(getPrizeTimes))
    end

    --本页签红点
    T3WarmUpJinLingMatch_Buttontab02_Tips:Hide()

    for j = g_MAX_SDJL_MSG+1, g_RedPointFlagNum-2 do
        local i = j - g_MAX_SDJL_MSG
        local text = "#{JLSS_210126_75}"
        if redPointData[j] == 1 then
            --显示红点 按钮mask
            g_PrizeBtnRedPoint[i]:Show()
            T3WarmUpJinLingMatch_Buttontab02_Tips:Show()
            --需要显示红点的 代表都没领过 不用mask
            g_PrizeBtnMask[i]:Hide()
           -- g_PrizeBtn[i]:Enable()
            g_PrizeBtnBK[i]:SetProperty("Image","set:T3WarmUpJinLing image:libai_HoverBK")
        else
            g_PrizeBtnRedPoint[i]:Hide()
            --不需要显示红点的 代表没领过 那么够level的显示mask 
            if getPrizeLevel >= i then
                g_PrizeBtnMask[i]:Show()
                --g_PrizeBtn[i]:Disable()
                g_PrizeBtnBK[i]:SetProperty("Image","set:T3WarmUpJinLing image:libai_HoverBK")
            else
                g_PrizeBtnMask[i]:Hide()
                --g_PrizeBtn[i]:Enable()
                g_PrizeBtnBK[i]:SetProperty("Image","set:T3WarmUpJinLing image:libai_NormalBK")
                text = "#{JLSS_210126_109}"
            end
        end
        g_AccPrizeNeedTimesText[i]:SetText(ScriptGlobal_Format(text,g_AccPrizeNeedTimes[i]))
    end
    --进度条
    for i=2,5 do
        if getPrizeTimes >= g_AccPrizeNeedTimes[i] then
            g_PrizeProgressImg[i]:Show()
        else
            g_PrizeProgressImg[i]:Hide()
        end
    end
    if redPointData[g_RedPointFlagNum-1] == 1 then
        T3WarmUpJinLingMatchGift_Pick_Tips:Show()
        T3WarmUpJinLingMatch_Buttontab02_Tips:Show()
    else
        T3WarmUpJinLingMatchGift_Pick_Tips:Hide()
    end
    
    --如果 另一个页面有需要显示的红点 则该页签显示红点
    T3WarmUpJinLingMatch_Buttontab01_Tips:Hide()
    for i = 1, g_MAX_SDJL_MSG do
        if redPointData[i] == 1 then
            T3WarmUpJinLingMatch_Buttontab01_Tips:Show()
            break
        end
    end

    if redPointData[g_RedPointFlagNum] == 1 then
        T3WarmUpJinLingMatch_Buttontab03_Tips:Show()
    else
        T3WarmUpJinLingMatch_Buttontab03_Tips:Hide()
    end
    g_LeftBtnTab[1]:SetCheck(0)
    g_LeftBtnTab[2]:SetCheck(1)
    g_LeftBtnTab[3]:SetCheck(0)
    this:Show()
    g_Frame[1]:Hide()
    g_Frame[2]:Show()
    g_Frame[3]:Hide()
end

function T3WarmUpJinLingMatch_OpenUI3()
    local redPointData = T3WarmUpJinLingMatch_GetBitTable(tonumber(arg1))
    T3WarmUpJinLingMatch_Buttontab01_Tips:Hide()
    for i = 1, g_MAX_SDJL_MSG do
        if redPointData[i] == 1 then
            T3WarmUpJinLingMatch_Buttontab01_Tips:Show()
            break;
        end
    end
    T3WarmUpJinLingMatch_Buttontab02_Tips:Hide()
    for i = g_MAX_SDJL_MSG+1 , g_RedPointFlagNum-1 do
        if redPointData[i] == 1 then
            T3WarmUpJinLingMatch_Buttontab02_Tips:Show()
            break;
        end
    end

    --local isState1 = tonumber(arg2)
    -- if isState1 == 1 then
    --     g_LeftBtnTab[1]:Enable()
    -- else
    --     g_LeftBtnTab[1]:Disable()
    -- end

    T3WarmUpJinLingMatch_Buttontab03_Tips:Hide()

    g_Frame[1]:Hide()
    g_Frame[2]:Hide()
    g_Frame[3]:Show()
    this:Show()

    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "OnLookWX" )
    Set_XSCRIPT_ParamCount( 0 )
    Send_XSCRIPT()
end

--领奖
function T3WarmUpJinLingMatch_GetAccPrizeClicked(awardIndex)
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "OnGetPrize" )
    Set_XSCRIPT_Parameter(0, awardIndex)
    Set_XSCRIPT_ParamCount( 2 )
    Send_XSCRIPT()
end


--抽奖
function T3WarmUpJinLingMatch_RandomPrizeClicked()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "OnRandomPrize" )
    Set_XSCRIPT_ParamCount( 0 )
    Send_XSCRIPT()
end

--赠送
function T3WarmUpJinLingMatch_GiveMsgClicked()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "OnGiveMessage" )
    Set_XSCRIPT_Parameter(0, g_MsgChoose)
    Set_XSCRIPT_Parameter(1, 0)
    Set_XSCRIPT_Parameter(2, 1)
    Set_XSCRIPT_ParamCount( 3 )
    Send_XSCRIPT()
end

--鼠标悬停msg
function T3WarmUpJinLingMatch_MsgLook(msgIndex)
    if nil == g_MsgBtnRedPoint[msgIndex] or not g_MsgBtnRedPoint[msgIndex]:IsVisible() then
        return
    end
    g_MsgBtnRedPoint[msgIndex]:Hide()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "OnHideMsgRedPoint" )
    Set_XSCRIPT_Parameter(0, msgIndex)
    Set_XSCRIPT_ParamCount( 1 )
    Send_XSCRIPT()
end

function T3WarmUpJinLingMatch_MsgClicked(msgIndex)
    if g_MsgChoose == msgIndex then
        g_MsgBtn[msgIndex]:SetCheck(0)
        g_MsgChoose = 0
        return 
    end
    g_MsgChoose = msgIndex
    for i=1,g_MAX_SDJL_MSG do
        if i== msgIndex then
            --g_MsgBtn[i]:SetCheck(1) --不用设置1 控件自动设置了 再设置一次就0了
        else
            g_MsgBtn[i]:SetCheck(0)
        end
    end
end

--寻路
-- function T3WarmUpJinLingMatch_GotoClicked()
--     AutoRuntoTargetExWithName(265, 255, 0, "秦明轩")	
-- end


function T3WarmUpJinLingMatch_Close()
    this:Hide()
end

function T3WarmUpJinLingMatch_On_ResetPos()
    if (this:IsVisible()) then
        if (g_Frame_UnifiedPosition ~= nil) then
            T3WarmUpJinLingMatch_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
        end
    end
end

function T3WarmUpJinLingMatch_GetBitTable(nOct)
	local BitTable = {}
	local oct = nOct
	for i = 1 , g_RedPointFlagNum do
		BitTable[i] = math.mod(oct , 2)
		oct = math.floor(oct / 2)
	end
	return BitTable
end

function T3WarmUpJinLingMatch_Project_Clicked(index)
    if index == 1 and tonumber(DataPool:GetServerDayTime()) > 20210306 then
        g_LeftBtnTab[index]:SetCheck(0)
        PushDebugMessage("#{JLSS_210126_114}")
        return 
    elseif index == 3 and tonumber(DataPool:GetServerDayTime()) > 20210306 then
        g_LeftBtnTab[index]:SetCheck(0)
        PushDebugMessage("#{JLYY_210113_02}")
        return  
    end
    for i=1,3 do
        if i == index then
            g_LeftBtnTab[i]:SetCheck(1)
        else
            g_LeftBtnTab[i]:SetCheck(0)
        end
    end
   
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("OnOpenUI")
    Set_XSCRIPT_ScriptID(888380)
    Set_XSCRIPT_Parameter(0, index)
    Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()
end

function T3WarmUpJinLingMatch_P1BoxClicked(index)
    for i =1,table.getn(g_PoolBtn) do
        if index ~= i then
            g_PoolBtn[i]:SetCheck(0)
        end
    end
    T3WarmUpJinLingMatchGift_P1Text:SetText(g_PoolInfo[index])
end