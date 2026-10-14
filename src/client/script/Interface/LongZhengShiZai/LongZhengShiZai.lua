--!!!reloadscript =LongZhengShiZai
local g_Frame_UnifiedPosition = nil

local g_CurPage = 0
local g_CurSteps = 0

--每一页可以展示的steps数量
local g_PageStepsSize = 17


local g_ExeScript = 888391

local g_UI_Items = {}

local g_CurStepState = 1

local g_StepTabStatus = {
    {stepend = 11,animateProperty = "LongZhengShiZai_Running",beginPosX = 16.0,YPos = 64.0},
    {stepend = 19,animateProperty = "LongZhengShiZai_Running2",beginPosX = 16.0,YPos = 63.0},
    {stepend = 31,animateProperty = "LongZhengShiZai_Running3",beginPosX = 16.0,YPos = 62.0},
}

local g_XDisplacement = {
    [1] = 0.0,[2] = 35.0,[3] = 70.0,[4] = 107.0,[5] = 143.0,[6] = 180.0,[7] = 224.0,[8] = 250.0,[9] = 287.0,
    [10] = 332.0, [11] = 387.0, [12] = 417.0, [13] = 463.0, [14] = 507.0, [15] = 553.0, [16] = 594.0, [17] = 638.0
}

--翻到下一页后 立即走几个格子
local g_nextPageMovement = 0

local g_QingZhuToSteps = {
    {qingzhu=0,step=3},
    {qingzhu=40,step=7},
    {qingzhu=80,step=11},
    {qingzhu=160,step=15},
    {qingzhu=240,step=19},
    {qingzhu=360,step=23},
    {qingzhu=480,step=27},
    {qingzhu=600,step=31},
}

function LongZhengShiZai_PreLoad()
	this:RegisterEvent("NLZSZ_UI", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function LongZhengShiZai_OnLoad()
    g_Frame_UnifiedPosition = LongZhengShiZai_Frame:GetProperty("UnifiedPosition")
    g_UI_Items = {
        PrizeBtn = {
            [1] = {window = LongZhengShiZai_Reward1,btn = LongZhengShiZai_RewardItem1,mask = LongZhengShiZai_Received1,img = LongZhengShiZai_Received_Image1,redPoint = LongZhengShiZai_RewardItem_Tips1},
            [2] = {window = LongZhengShiZai_Reward2,btn = LongZhengShiZai_RewardItem2,mask = LongZhengShiZai_Received2,img = LongZhengShiZai_Received_Image2,redPoint = LongZhengShiZai_RewardItem_Tips2},
            [3] = {window = LongZhengShiZai_Reward3,btn = LongZhengShiZai_RewardItem3,mask = LongZhengShiZai_Received3,img = LongZhengShiZai_Received_Image3,redPoint = LongZhengShiZai_RewardItem_Tips3},
            [4] = {window = LongZhengShiZai_Reward4,btn = LongZhengShiZai_RewardItem4,mask = LongZhengShiZai_Received4,img = LongZhengShiZai_Received_Image4,redPoint = LongZhengShiZai_RewardItem_Tips4},
            [5] = {window = LongZhengShiZai_Reward5,btn = LongZhengShiZai_RewardItem5,mask = LongZhengShiZai_Received5,img = LongZhengShiZai_Received_Image5,redPoint = LongZhengShiZai_RewardItem_Tips5},
            [6] = {window = LongZhengShiZai_Reward6,btn = LongZhengShiZai_RewardItem6,mask = LongZhengShiZai_Received6,img = LongZhengShiZai_Received_Image6,redPoint = LongZhengShiZai_RewardItem_Tips6},
            [7] = {window = LongZhengShiZai_Reward7,btn = LongZhengShiZai_RewardItem7,mask = LongZhengShiZai_Received7,img = LongZhengShiZai_Received_Image7,redPoint = LongZhengShiZai_RewardItem_Tips7},
            [8] = {window = LongZhengShiZai_Reward8,btn = LongZhengShiZai_RewardItem8,mask = LongZhengShiZai_Received8,img = LongZhengShiZai_Received_Image8,redPoint = LongZhengShiZai_RewardItem_Tips8},
            [9] = {window = LongZhengShiZai_Reward9,btn = LongZhengShiZai_RewardItem9,mask = LongZhengShiZai_Received9,img = LongZhengShiZai_Received_Image9,redPoint = LongZhengShiZai_RewardItem_Tips9},
            [10] = {window = LongZhengShiZai_Reward10,btn = LongZhengShiZai_RewardItem10,mask = LongZhengShiZai_Received10,img = LongZhengShiZai_Received_Image10,redPoint = LongZhengShiZai_RewardItem_Tips10},
            [11] = {window = LongZhengShiZai_Reward11,btn = LongZhengShiZai_RewardItem11,mask = LongZhengShiZai_Received11,img = LongZhengShiZai_Received_Image11,redPoint = LongZhengShiZai_RewardItem_Tips11},
            [12] = {window = LongZhengShiZai_Reward12,btn = LongZhengShiZai_RewardItem12,mask = LongZhengShiZai_Received12,img = LongZhengShiZai_Received_Image12,redPoint = LongZhengShiZai_RewardItem_Tips12},
            [13] = {window = LongZhengShiZai_Reward13,btn = LongZhengShiZai_RewardItem13,mask = LongZhengShiZai_Received13,img = LongZhengShiZai_Received_Image13,redPoint = LongZhengShiZai_RewardItem_Tips13},
            [14] = {window = LongZhengShiZai_Reward14,btn = LongZhengShiZai_RewardItem14,mask = LongZhengShiZai_Received14,img = LongZhengShiZai_Received_Image14,redPoint = LongZhengShiZai_RewardItem_Tips14},
            [15] = {window = LongZhengShiZai_Reward15,btn = LongZhengShiZai_RewardItem15,mask = LongZhengShiZai_Received15,img = LongZhengShiZai_Received_Image15,redPoint = LongZhengShiZai_RewardItem_Tips15},
            [16] = {window = LongZhengShiZai_Reward16,btn = LongZhengShiZai_RewardItem16,mask = LongZhengShiZai_Received16,img = LongZhengShiZai_Received_Image16,redPoint = LongZhengShiZai_RewardItem_Tips16},
            [17] = {window = LongZhengShiZai_Reward17,btn = LongZhengShiZai_RewardItem17,mask = LongZhengShiZai_Received17,img = LongZhengShiZai_Received_Image17,redPoint = LongZhengShiZai_RewardItem_Tips17},
        
        },
        StepsInfo = {
            [1] = {StepNum = LongZhengShiZai_Mile1,Spot=LongZhengShiZai_SmallSpot1},
            [2] = {StepNum = LongZhengShiZai_Mile2,Spot=LongZhengShiZai_SmallSpot2},
            [3] = {StepNum = LongZhengShiZai_Mile3,Spot=LongZhengShiZai_SmallSpot3},
            [4] = {StepNum = LongZhengShiZai_Mile4,Spot=LongZhengShiZai_SmallSpot4},
            [5] = {StepNum = LongZhengShiZai_Mile5,Spot=LongZhengShiZai_SmallSpot5},
            [6] = {StepNum = LongZhengShiZai_Mile6,Spot=LongZhengShiZai_SmallSpot6},
            [7] = {StepNum = LongZhengShiZai_Mile7,Spot=LongZhengShiZai_SmallSpot7},
            [8] = {StepNum = LongZhengShiZai_Mile8,Spot=LongZhengShiZai_SmallSpot8},
            [9] = {StepNum = LongZhengShiZai_Mile9,Spot=LongZhengShiZai_SmallSpot9},
            [10] = {StepNum = LongZhengShiZai_Mile10,Spot=LongZhengShiZai_SmallSpot10},
            [11] = {StepNum = LongZhengShiZai_Mile11,Spot=LongZhengShiZai_SmallSpot11},
            [12] = {StepNum = LongZhengShiZai_Mile12,Spot=LongZhengShiZai_SmallSpot12},
            [13] = {StepNum = LongZhengShiZai_Mile13,Spot=LongZhengShiZai_SmallSpot13},
            [14] = {StepNum = LongZhengShiZai_Mile14,Spot=LongZhengShiZai_SmallSpot14},
            [15] = {StepNum = LongZhengShiZai_Mile15,Spot=LongZhengShiZai_SmallSpot15},
            [16] = {StepNum = LongZhengShiZai_Mile16,Spot=LongZhengShiZai_SmallSpot16},
            [17] = {StepNum = LongZhengShiZai_Mile17,Spot=LongZhengShiZai_SmallSpot17},
        },

        Blocks = {
            [1] = {window = LongZhengShiZai_Block1, normal = LongZhengShiZai_Normal1, hover = LongZhengShiZai_Hover1},
            [2] = {window = LongZhengShiZai_Block2, normal = LongZhengShiZai_Normal2, hover = LongZhengShiZai_Hover2},
            [3] = {window = LongZhengShiZai_Block3, normal = LongZhengShiZai_Normal3, hover = LongZhengShiZai_Hover3},
            [4] = {window = LongZhengShiZai_Block4, normal = LongZhengShiZai_Normal4, hover = LongZhengShiZai_Hover4},
            [5] = {window = LongZhengShiZai_Block5, normal = LongZhengShiZai_Normal5, hover = LongZhengShiZai_Hover5},
            [6] = {window = LongZhengShiZai_Block6, normal = LongZhengShiZai_Normal6, hover = LongZhengShiZai_Hover6},
            [7] = {window = LongZhengShiZai_Block7, normal = LongZhengShiZai_Normal7, hover = LongZhengShiZai_Hover7},
            [8] = {window = LongZhengShiZai_Block8, normal = LongZhengShiZai_Normal8, hover = LongZhengShiZai_Hover8},
            [9] = {window = LongZhengShiZai_Block9, normal = LongZhengShiZai_Normal9, hover = LongZhengShiZai_Hover9},
            [10] = {window = LongZhengShiZai_Block10, normal = LongZhengShiZai_Normal10, hover = LongZhengShiZai_Hover10},
            [11] = {window = LongZhengShiZai_Block11, normal = LongZhengShiZai_Normal11, hover = LongZhengShiZai_Hover11},
            [12] = {window = LongZhengShiZai_Block12, normal = LongZhengShiZai_Normal12, hover = LongZhengShiZai_Hover12},
            [13] = {window = LongZhengShiZai_Block13, normal = LongZhengShiZai_Normal13, hover = LongZhengShiZai_Hover13},
            [14] = {window = LongZhengShiZai_Block14, normal = LongZhengShiZai_Normal14, hover = LongZhengShiZai_Hover14},
            [15] = {window = LongZhengShiZai_Block15, normal = LongZhengShiZai_Normal15, hover = LongZhengShiZai_Hover15},
            [16] = {window = LongZhengShiZai_Block16, normal = LongZhengShiZai_Normal16, hover = LongZhengShiZai_Hover16},
            [17] = {window = LongZhengShiZai_Block17, normal = LongZhengShiZai_Normal17, hover = LongZhengShiZai_Hover17},
        },

        PageBtn = {left = LongZhengShiZai_LeftBtn , right = LongZhengShiZai_RightBtn,leftRedPoint = LongZhengShiZai_RewardItem_LeftTips,rightRedPoint = LongZhengShiZai_RewardItem_RightTips},
        
        ActiveSteps = LongZhengShiZai_Steps,

        StepTab = LongZhengShiZai_Running,
        
        StepBtn = {btn = LongZhengShiZai_GoOn,redPoint = LongZhengShiZai_RewardItem_GoOnTips,finished = LongZhengShiZai_Activity1Finish }
    
    }
end

function LongZhengShiZai_OnEvent(event)
    if event == "NLZSZ_UI" then
        --第一个参数opt:
        --  1 打开界面
        --  2 刷新界面
        --  3 增加进度
        local Opt = tonumber(arg0)
        if 1 == Opt then
            LongZhengShiZai_Open()
        elseif 2 == Opt then
            if (this:IsVisible()) then
                LongZhengShiZai_Open()
            end
        elseif 3 == Opt then
            LongZhengShiZai_AddStep()
        end
	elseif event == "VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then
        LongZhengShiZai_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
		LongZhengShiZai_OnClose()
	end

end
function LongZhengShiZai_Open()
    LongZhengShiZai_OnOpen()
    LongZhengShiZai_SetStepTab(g_CurSteps)
    if g_nextPageMovement > 0 then
        LongZhengShiZai_AddProgessAni(g_CurSteps-g_nextPageMovement,g_nextPageMovement)
        g_nextPageMovement = 0
    else
        LongZhengShiZai_SetProgessAni(g_CurSteps)
    end
    
end

function  LongZhengShiZai_AddStep()
    local from = g_CurSteps
    LongZhengShiZai_OnOpen()
    LongZhengShiZai_SetStepTab(g_CurSteps)
    local odds = 0
    for i=1,8 do
        if g_QingZhuToSteps[i].step > from then
            odds = g_QingZhuToSteps[i].step-from
            break
        end
    end
    LongZhengShiZai_AddProgessAni(from,odds)    
end

function LongZhengShiZai_OnOpen()
    g_CurPage = tonumber(arg1)
    local avilaQingzhu = tonumber(arg2)
    g_CurSteps = tonumber(arg3)
    local CurPagePrizeStateTable = LongZhengShiZai_GetBitTable(tonumber(arg4))
    local stepsBegin = LongZhengShiZai_GetPageFrontStep(g_CurPage)
    local stepEnd = Lua_GetNewLongZhengShiZaiNum()
    g_UI_Items.ActiveSteps:SetText(ScriptGlobal_Format("#{YZTX_210310_17}",avilaQingzhu))
    LongZhengShiZai_Zhu:SetToolTip(ScriptGlobal_Format("#{YZTX_210310_63}",avilaQingzhu))
    LongZhengShiZai_Spot3:Show()
    for i=1,g_PageStepsSize do
        local stepIndex = stepsBegin+i-1
        local ret,showID,strImage = Lua_GetNewLongZhengShiZaiInfo(stepIndex)
        if ret == 1 then
            --该step有奖励
            g_UI_Items.StepsInfo[i].StepNum:SetText("#L"..tostring(LongZhengShiZai_StepsToQingZhu(stepIndex)))
            g_UI_Items.StepsInfo[i].Spot:Show()
            g_UI_Items.PrizeBtn[i].img:SetProperty("Image", strImage )
            local theAction =  DataPool:CreateActionItemForShow(showID, 1)
            if nil~= theAction then
                g_UI_Items.PrizeBtn[i].btn:SetActionItem(theAction:GetID())
            end
            g_UI_Items.PrizeBtn[i].window:Show()
            g_UI_Items.PrizeBtn[i].redPoint:Hide()
            g_UI_Items.Blocks[i].window:Show()
            if stepIndex <= g_CurSteps then
                g_UI_Items.Blocks[i].hover:Show()
                g_UI_Items.Blocks[i].normal:Hide()
                --可以领的奖励
                if CurPagePrizeStateTable[i] == 1 then
                    --未领
                    g_UI_Items.PrizeBtn[i].btn:SetProperty("Gloom", "False")
                    g_UI_Items.PrizeBtn[i].mask:Hide()
                    g_UI_Items.PrizeBtn[i].redPoint:Show()
                else
                    --已领
                    g_UI_Items.PrizeBtn[i].btn:SetProperty("Gloom", "True")
                    g_UI_Items.PrizeBtn[i].mask:Show()
                end
            else
                --不能领的奖励   
                g_UI_Items.Blocks[i].normal:Show()
                g_UI_Items.Blocks[i].hover:Hide()
                g_UI_Items.PrizeBtn[i].btn:SetProperty("Gloom", "False")
                g_UI_Items.PrizeBtn[i].mask:Hide()
            end
            g_UI_Items.PrizeBtn[i].btn:Show()
        else
            if i == g_QingZhuToSteps[1].step and stepsBegin == 1 then
                g_UI_Items.StepsInfo[i].StepNum:SetText("#L0")
                g_UI_Items.StepsInfo[i].Spot:Show()

                --     --第一步
                --     --无奖励 但是有底图
                LongZhengShiZai_Spot3:Hide()
                g_UI_Items.PrizeBtn[i].window:Show()
                g_UI_Items.PrizeBtn[i].btn:Hide()
                g_UI_Items.PrizeBtn[i].mask:Hide()
                g_UI_Items.PrizeBtn[i].redPoint:Hide()
                g_UI_Items.PrizeBtn[i].img:Show()
                g_UI_Items.PrizeBtn[i].img:SetProperty("Image", "set:LongZhengShiZai_04 image:LongZhengShiZai_04_Card_2007" )
            else
                g_UI_Items.StepsInfo[i].StepNum:SetText("")
                g_UI_Items.StepsInfo[i].Spot:Hide()

                g_UI_Items.PrizeBtn[i].window:Hide()
            end 
            g_UI_Items.Blocks[i].window:Hide()
        end
    end

    if stepsBegin <= 1 then
        g_UI_Items.PageBtn.left:Disable()
        g_UI_Items.PageBtn.right:Enable()

    elseif stepsBegin + g_PageStepsSize -1 >= stepEnd then
        g_UI_Items.PageBtn.left:Enable()
        g_UI_Items.PageBtn.right:Disable()

    else
        g_UI_Items.PageBtn.left:Enable()
        g_UI_Items.PageBtn.right:Enable()
    end

    if g_CurSteps < stepEnd then
        g_UI_Items.StepBtn.btn:Show()
        g_UI_Items.StepBtn.finished:Hide()
        if avilaQingzhu >= LongZhengShiZai_NextLevelNeedQingZhu(g_CurSteps)  then
            g_UI_Items.StepBtn.redPoint:Show()
        else
            g_UI_Items.StepBtn.redPoint:Hide()
        end
        LongZhengShiZai_Buy_Btn:Show()
        LongZhengShiZai_Buy_Btn:SetToolTip("#{YZTX_210310_31}")
    else
        g_UI_Items.StepBtn.btn:Hide()
        g_UI_Items.StepBtn.finished:Show()
        g_UI_Items.StepBtn.redPoint:Hide()
        LongZhengShiZai_Buy_Btn:Hide()
    end


    if CurPagePrizeStateTable[g_PageStepsSize+1] == 1 then
        g_UI_Items.PageBtn.leftRedPoint:Show()
    else
        g_UI_Items.PageBtn.leftRedPoint:Hide()
    end

    if CurPagePrizeStateTable[g_PageStepsSize+2] == 1 then
        g_UI_Items.PageBtn.rightRedPoint:Show()
    else
        g_UI_Items.PageBtn.rightRedPoint:Hide()
    end
    
    this:Show()
end

--设置tab样式
function LongZhengShiZai_SetStepTab(step)
    --设置进度tab的样式
    local tabStyle = nil
    local find = 0
    for index,info in g_StepTabStatus do
        tabStyle = _G[info.animateProperty]
        if step <= info.stepend and find == 0 then
            if tabStyle ~= nil then
                find = 1
                g_UI_Items.StepTab = tabStyle
                g_UI_Items.StepTab:Show()
                g_CurStepState = index
            end
        else
            tabStyle:Hide()
        end
    end
end

-- 进度条播放前进一格的动画
-- from : 起始step
-- 必须是设置完页面数据再用这个函数 from是设置数据之前的curstep
function LongZhengShiZai_AddProgessAni(from,movement)
    --PushDebugMessage("from:"..from.."movement:"..movement)
    local ret = LongZhengShiZai_SetProgessAni(from)
    local curPageIndex = from-(g_PageStepsSize-1)*(g_CurPage-1)
    if ret == 0 or curPageIndex >= g_PageStepsSize or curPageIndex < 1 then
        PushDebugMessage("页面数据错误，请重新打开页面")
        return 
    end 
    g_UI_Items.StepTab:Show()
    local XDisplacementCur = g_XDisplacement[curPageIndex]
    local XDisplacementNext = 0
    local movestep = movement
    if curPageIndex + movement > g_PageStepsSize then
        XDisplacementNext = g_XDisplacement[g_PageStepsSize]
        g_nextPageMovement = curPageIndex + movement - g_PageStepsSize
        movestep = g_PageStepsSize - curPageIndex
    else
        XDisplacementNext = g_XDisplacement[curPageIndex+movement]
        g_nextPageMovement = 0        
    end
     
    local XMove = XDisplacementNext - XDisplacementCur
    local velocity = movestep/2
    local from_to_info = string.format( "curve:Liner mode:Once duration:%.1f startx:0 starty:0 endx:%d endy:0",velocity,XMove )
    g_UI_Items.StepTab:Tween_SetInfo("Position", from_to_info)
    g_UI_Items.StepTab:Tween_Play("Position", true, false)
end

function LongZhengShiZai_SetProgessAni(stepIndex)
    --直接设置当前页面的进度tab
    --直接设置进度的位置
    local curPageIndex = stepIndex-(g_PageStepsSize-1)*(g_CurPage-1)
    if curPageIndex < 1 or curPageIndex > g_PageStepsSize then
        g_UI_Items.StepTab:Hide()
        return 0 
    end

    local XDisplacement = g_XDisplacement[curPageIndex]
    local Xbegin = g_StepTabStatus[g_CurStepState].beginPosX
    local YPos = g_StepTabStatus[g_CurStepState].YPos
    --PushDebugMessage( g_UI_Items.StepTab:GetProperty("UnifiedPosition"))
    g_UI_Items.StepTab:SetProperty("UnifiedPosition", "{{0.0,"..tostring(Xbegin+XDisplacement).."},{0.000000,"..tostring(YPos).."}}")
    return 1
end



function LongZhengShiZai_TweenEnd()
    --检查需不需要自动翻页
    if (g_CurPage*(g_PageStepsSize-1)+1 == g_CurSteps and g_CurSteps < Lua_GetNewLongZhengShiZaiNum()) or g_nextPageMovement > 0 then
        LongZhengShiZai_AskOpenPageIndex(g_CurPage+1)
    elseif g_nextPageMovement > 0 then
        LongZhengShiZai_AskOpenPageIndex(g_CurPage+1)
    end
end

function LongZhengShiZai_OnRewardClick(Index)
    if  g_UI_Items.PrizeBtn[Index] == nil then
        return 
    end

    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "OnGetPrize" )
    Set_XSCRIPT_Parameter(0, Index+(g_PageStepsSize-1)*(g_CurPage-1))
    Set_XSCRIPT_Parameter(1, g_CurPage)
    Set_XSCRIPT_ParamCount( 2 )
    Send_XSCRIPT()
end

function LongZhengShiZai_OnStepBtnClick()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "OnStep" )
    Set_XSCRIPT_ParamCount( 0 )
    Send_XSCRIPT()
end

function LongZhengShiZai_OnPageBtnClick(forward)
    if forward == 1 then
        --left
        LongZhengShiZai_AskOpenPageIndex(g_CurPage-1)
    elseif forward == 2 then
        --right
        LongZhengShiZai_AskOpenPageIndex(g_CurPage+1)
    end
end

function LongZhengShiZai_AskOpenPageIndex(pageIndex)
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "OnOpenUIIndex" )
    Set_XSCRIPT_Parameter(0, pageIndex)
    Set_XSCRIPT_ParamCount( 1 )
    Send_XSCRIPT()
end



function LongZhengShiZai_OnClose()
    this:Hide()
    if IsWindowShow("LongZhengShiZai_BuyEXP") then
        CloseWindow("LongZhengShiZai_BuyEXP", true)
    end
end

function LongZhengShiZai_OnHelpBtnClick()
    -- 借用一下别人的通道
	PushEvent("OPEN_SWEEPPAGE_QUEST", "LongZhengShiZai")
end



function LongZhengShiZai_On_ResetPos()
    if (this:IsVisible()) then
        if (g_Frame_UnifiedPosition ~= nil) then
            LongZhengShiZai_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
        end
    end
end

function LongZhengShiZai_GetPageFrontStep(pageIndex)
    return (pageIndex-1)*(g_PageStepsSize-1) + 1
end

function LongZhengShiZai_GetBitTable(nOct)
	local BitTable = {}
	local oct = nOct
	for i = 1 , g_PageStepsSize+2 do
		BitTable[i] = math.mod(oct , 2)
		oct = math.floor(oct / 2)
	end
	return BitTable
end

function LongZhengShiZai_Buy_BtnClicked()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "OnOpenUIBuy" )
    Set_XSCRIPT_ParamCount( 0 )
    Send_XSCRIPT()
end

function LongZhengShiZai_NextLevelNeedQingZhu(curStep)
    local pre = 0
    for i=1,8 do
        if curStep >= g_QingZhuToSteps[i].step then
            pre = g_QingZhuToSteps[i].qingzhu
        else
            return g_QingZhuToSteps[i].qingzhu-pre
        end
    end
    return 9999
end

function LongZhengShiZai_StepsToQingZhu(step)
    for i=1,8 do
        if step == g_QingZhuToSteps[i].step then
            return g_QingZhuToSteps[i].qingzhu
        end
    end
    return -1
end
