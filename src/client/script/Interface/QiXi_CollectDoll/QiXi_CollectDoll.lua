-- QiXi_CollectDoll 七夕瓜分活动展示界面 2019-6-24 lishilong
-- !!!reloadscript =QiXi_CollectDoll
--
local MAX_OBJ_DISTANCE 	= 3.0
local g_objCared 		= -1
local g_npcObjId 		= -1
local g_QiXi_CollectDoll_Frame_UnifiedPosition
local bCaredObj 		= 0
local bCaredMoney 		= 0

-- 激活娃娃控件
local g_tabControlWaWaGet  = {}
local g_tabControlWaWaDis  = {}
-- 激活标记数组
local g_tabActMF        = {0,0,0,0,0,0,0}
-- 领奖标记
local g_bGetedReward    = 0
-- 全服激活数量
local g_nTotalActNum    = 0
-- 激活统计时间
local g_nCurDayWorld    = 0
-- 全服瓜分总份数
local g_nMaxPriceNum    = 0
-- 活动阶段 -1 未开启； -2已结束; 1 阶段1，玩家激活阶段; 2 阶段2，结算阶段; 3 阶段3，领奖阶段
local g_nHuoDongType    = 0
-- 剩余时间
local g_nRemainToTalSecond  = 0

-- 前置活动是否完成
local g_bPreEvent1Finish    = 0
local g_bPreEvent2Finish    = 0
local g_bPreEvent3Finish    = 0

-- 今天是否领取溪娘信
local g_bGetLetterToday     = 0
local g_bHaveLetterNum      = 0

-- 结算时间，用于显示
local g_nTimeJieSuanMonth   = 8
local g_nTimeJieSuanDay     = 14

-- 结算时间，用于判断world上的时间是否也更新到结算时间了
local g_nTimeJieSuanForSetp = 20210814 -- 20200825

-- 1 找x公子 齐三郎 AutoRuntoTargetExWithName
-- 2 找y姑娘 溪娘 AutoRuntoTargetExWithName
local g_infoNPCGoto     = 
{
    -- 找齐三郎
    [1] = {nSceneID = 1, nPosX = 262, nPosY = 319, strNPCName = "齐三郎", strMsg = "#{QQFW_190620_116}"},
    -- 领取溪娘信
    [2] = {nSceneID = 1, nPosX = 328, nPosY = 306, strNPCName = "溪娘", strMsg = "#{QQFW_190620_110}"},
    -- 鹊桥相会
    [3] = {nSceneID = 30, nPosX = 223, nPosY = 138, strNPCName = "灵鹊仙子", strMsg = "#{QQFW_190620_104}"},
    -- 花好情浓
    [4] = {nSceneID = 30, nPosX = 223, nPosY = 138, strNPCName = "灵鹊仙子", strMsg = "#{QQFW_190620_105}"},
    -- 华服嘉姻
    [5] = {nSceneID = 1, nPosX = 328, nPosY = 306, strNPCName = "溪娘", strMsg = "#{QQFW_190620_106}"},
}

local g_nLimitLevel     = 30

--=========================================================
-- PreLoad
--=========================================================
function QiXi_CollectDoll_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	-- this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	if 1 == bCaredMoney then
		this:RegisterEvent("MONEY_CHANGE_EX", false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	end
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

--=========================================================
-- OnLoad
--=========================================================
function QiXi_CollectDoll_OnLoad()
    g_QiXi_CollectDoll_Frame_UnifiedPosition = QiXi_CollectDoll_Frame:GetProperty("UnifiedPosition")

    g_tabControlWaWaGet[1] = QiXi_CollectDoll_Doll1_Get
    g_tabControlWaWaGet[2] = QiXi_CollectDoll_Doll2_Get
    g_tabControlWaWaGet[3] = QiXi_CollectDoll_Doll3_Get
    g_tabControlWaWaGet[4] = QiXi_CollectDoll_Doll4_Get
    g_tabControlWaWaGet[5] = QiXi_CollectDoll_Doll5_Get
    g_tabControlWaWaGet[6] = QiXi_CollectDoll_Doll6_Get
    g_tabControlWaWaGet[7] = QiXi_CollectDoll_Doll7_Get

    g_tabControlWaWaDis[1] = QiXi_CollectDoll_Doll1_Dis
    g_tabControlWaWaDis[2] = QiXi_CollectDoll_Doll2_Dis
    g_tabControlWaWaDis[3] = QiXi_CollectDoll_Doll3_Dis
    g_tabControlWaWaDis[4] = QiXi_CollectDoll_Doll4_Dis
    g_tabControlWaWaDis[5] = QiXi_CollectDoll_Doll5_Dis
    g_tabControlWaWaDis[6] = QiXi_CollectDoll_Doll6_Dis
    g_tabControlWaWaDis[7] = QiXi_CollectDoll_Doll7_Dis
end

--=========================================================
-- OnEvent
--=========================================================
function QiXi_CollectDoll_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 920190618 ) then
		-- 0 关闭，1打开， 2刷新
		local nOpType 	= Get_XParam_INT(0)
		local objid 	= Get_XParam_INT(1)
		
		if 1 == bCaredObj then
			if objid == nil or objid < 0 then
				if this:IsVisible() then
					QiXi_CollectDoll_OnClose()
				end
			end
		end
		
		if 0 == nOpType then
			-- 关闭界面
			if this:IsVisible() then
				QiXi_CollectDoll_OnClose()
			end
			
		elseif 1 == nOpType then
			-- 打开界面
			-- 关注npc
			if 1 == bCaredObj then
				g_npcObjId = objid
				g_objCared = DataPool : GetNPCIDByServerID(tonumber(objid))
				BeginCareObject_QiXi_CollectDoll()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	QiXi_CollectDoll_OnClose()
			-- end
            QiXi_CollectDoll_Reset()
            QiXi_CollectDoll_Frame_On_ResetPos()
			this:Show()
			QiXi_CollectDoll_ParamInit()
			QiXi_CollectDoll_MoneyUpdate()
			QiXi_CollectDoll_Update(1)
			
		elseif 2 == nOpType then
			-- 刷新界面
            if this:IsVisible() then
                QiXi_CollectDoll_Reset()
				QiXi_CollectDoll_ParamInit()
				QiXi_CollectDoll_Update(0)
			end
		end
    
    -- 客户端寻路
    elseif ( event == "UI_COMMAND" and tonumber(arg0) == 920190622 ) then
        local nOpType 	= Get_XParam_INT(0)
        -- 1 找x公子 AutoRuntoTargetExWithName
        -- 2 找y姑娘 AutoRuntoTargetExWithName
        -- if 1 == nOpType then
        --     AutoRuntoTargetExWithName(g_infoNPCGoto[1].nPosX, g_infoNPCGoto[1].nPosY, g_infoNPCGoto[1].nSceneID, g_infoNPCGoto[1].strNPCName)
        --     -- 关闭界面
		-- 	if this:IsVisible() then
		-- 		QiXi_CollectDoll_OnClose()
		-- 	end
        -- end

        -- if 2 == nOpType then
        --     AutoRuntoTargetExWithName(g_infoNPCGoto[2].nPosX, g_infoNPCGoto[2].nPosY, g_infoNPCGoto[2].nSceneID, g_infoNPCGoto[2].strNPCName)
        --     -- 关闭界面
		-- 	if this:IsVisible() then
		-- 		QiXi_CollectDoll_OnClose()
		-- 	end
        -- end

        QiXi_CollectDoll_AutoGoNPC(nOpType)

	-- 物品改变
	-- elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
	-- 	-- 刷新界面
	-- 	if this:IsVisible() then
	-- 		QiXi_CollectDoll_Update(0)
	-- 	end
	
	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			QiXi_CollectDoll_OnClose()
		end	
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		QiXi_CollectDoll_OnClose()
	
	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
	-- elseif event == "MONEYJZ_CHANGE_EX" then
		QiXi_CollectDoll_MoneyUpdate()
	
	elseif (event == "ADJEST_UI_POS" ) then
		QiXi_CollectDoll_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		QiXi_CollectDoll_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function QiXi_CollectDoll_ParamInit()

    local nActMFToClient = Get_XParam_INT(2)
    for i = 1, table.getn(g_tabActMF) do 
        g_tabActMF[table.getn(g_tabActMF) + 1 - i] = math.mod(nActMFToClient, 10)
        nActMFToClient = math.floor(nActMFToClient / 10)
    end

    g_bGetedReward              = Get_XParam_INT(3)

    g_nTotalActNum              = Get_XParam_INT(4)
    g_nCurDayWorld              = Get_XParam_INT(5)
    g_nMaxPriceNum              = Get_XParam_INT(6)
    g_nHuoDongType              = Get_XParam_INT(7)

    local nDiffDay              = Get_XParam_INT(8)
    local nTodayRemainSecond    = Get_XParam_INT(9)

    g_nRemainToTalSecond    = nDiffDay * 86400 + nTodayRemainSecond

    g_bPreEvent1Finish          = Get_XParam_INT(10)
    g_bPreEvent2Finish          = Get_XParam_INT(11)
    g_bPreEvent3Finish          = Get_XParam_INT(12)

    g_bGetLetterToday           = Get_XParam_INT(13)
    g_bHaveLetterNum            = Get_XParam_INT(14)
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =QiXi_CollectDoll
function QiXi_CollectDoll_Update(bOpen)

    if g_nHuoDongType < 1 or g_nHuoDongType > 3 then
        PushDebugMessage("非法界面参数")
        return
    end

    -- 是否显示刷新提示，非激活阶段不显示
    if 1 == g_nHuoDongType then
        QiXi_CollectDoll_RefreshText : Show()
    else
        QiXi_CollectDoll_RefreshText : Hide()
    end

    -- 是否显示前置活动按钮蒙版，非激活阶段不显示 换另一套蒙版
    if 1 == g_nHuoDongType then
        QiXi_CollectDoll_Area1 : Show()
        QiXi_CollectDoll_Area2 : Hide()
    else
        QiXi_CollectDoll_Area1 : Hide()
        QiXi_CollectDoll_Area2 : Show()
    end

    -- 前置活动完成情况设置
    if 1 == g_bPreEvent1Finish then
        QiXi_CollectDoll_Action01_Finish : Show()
        QiXi_CollectDoll_Action01_Undone : Hide()
        QiXi_CollectDoll_Action01_Button : Disable()
    else
        QiXi_CollectDoll_Action01_Finish : Hide()
        QiXi_CollectDoll_Action01_Undone : Show()
        QiXi_CollectDoll_Action01_Button : Enable() 
    end

    if 1 == g_bPreEvent2Finish then
        QiXi_CollectDoll_Action02_Finish : Show()
        QiXi_CollectDoll_Action02_Undone : Hide()
        QiXi_CollectDoll_Action02_Button : Disable()
    else
        QiXi_CollectDoll_Action02_Finish : Hide()
        QiXi_CollectDoll_Action02_Undone : Show()
        QiXi_CollectDoll_Action02_Button : Enable() 
    end

    if 1 == g_bPreEvent3Finish then
        QiXi_CollectDoll_Action03_Finish : Show()
        QiXi_CollectDoll_Action03_Undone : Hide()
        QiXi_CollectDoll_Action03_Button : Disable()
    else
        QiXi_CollectDoll_Action03_Finish : Hide()
        QiXi_CollectDoll_Action03_Undone : Show()
        QiXi_CollectDoll_Action03_Button : Enable() 
    end

    -- 激活娃娃显示
    local nActNum = 0 
    for i = 1, table.getn(g_tabActMF) do 
        if 1 == g_tabActMF[i] then
            nActNum = nActNum + 1
            g_tabControlWaWaGet[i] : Show()
            g_tabControlWaWaDis[i] : Hide()
        else
            g_tabControlWaWaGet[i] : Hide()
            g_tabControlWaWaDis[i] : Show()
        end
    end

    -- 个人激活数量描述
    QiXi_CollectDoll_ActivateText : SetText(ScriptGlobal_Format("#{QQFW_190620_55}", nActNum, table.getn(g_tabActMF)))
    
    -- 全服总激活统计显示
    -- PushDebugMessage("g_nCurDayWorld"..g_nCurDayWorld)

    local nTempValue = math.mod(g_nCurDayWorld, 10000)

    local nShowMonth = math.floor(nTempValue / 100)
    local nShowDay  = math.mod(nTempValue, 100)

    if nShowMonth >= g_nTimeJieSuanMonth and nShowDay >= g_nTimeJieSuanDay then
        nShowMonth = g_nTimeJieSuanMonth
        nShowDay = g_nTimeJieSuanDay
    end

    QiXi_CollectDoll_CollectNumText : SetText(ScriptGlobal_Format("#{QQFW_190620_16}", nShowMonth, nShowDay, 0, g_nTotalActNum))

    -- 三阶段且有领奖资格的人换另一个文本
    if 3 == g_nHuoDongType and nActNum >= table.getn(g_tabActMF) then
        QiXi_CollectDoll_CollectNumText : SetText(ScriptGlobal_Format("#{QQFW_190620_10}", g_nTotalActNum))
    end

    -- PushDebugMessage("g_nHuoDongType"..g_nHuoDongType.."g_bGetLetterToday"..g_bGetLetterToday.."g_bHaveLetterNum"..g_bHaveLetterNum)
    -- 右下角按钮的状态
    if 1 == g_nHuoDongType then
        if 1 == g_bGetLetterToday then
            -- 已领取溪娘信
            if g_bHaveLetterNum > 0 then
                -- 包里有信
                -- 前往七巧庭QQFW_190620_12
                QiXi_CollectDoll_Button : SetText("#{QQFW_190620_12}")
                QiXi_CollectDoll_Button : SetToolTip("#{QQFW_190620_93}")    
                QiXi_CollectDoll_Button : Enable()  
                QiXi_CollectDoll_Button_Tips : Show()
            else
                -- 包里没信
                -- 前往七巧庭QQFW_190620_12
                QiXi_CollectDoll_Button : SetText("#{QQFW_190620_12}")
                QiXi_CollectDoll_Button : SetToolTip("#{QQFW_190620_93}")    
                QiXi_CollectDoll_Button : Enable()  
                QiXi_CollectDoll_Button_Tips : Hide()
            end   
        else
            -- 今天还没领溪娘信
            if 1 == g_bPreEvent1Finish and 1 == g_bPreEvent2Finish and 1 == g_bPreEvent3Finish then
                -- 前置任务都完成了
                -- 不管包里有没有信都去领了先
                -- 领取溪娘信QQFW_190620_107
                QiXi_CollectDoll_Button : SetText("#{QQFW_190620_107}")
                QiXi_CollectDoll_Button : SetToolTip("#{QQFW_190620_108}")   
                QiXi_CollectDoll_Button : Enable()  
                QiXi_CollectDoll_Button_Tips : Show()    
            else
                -- 还有前置任务没有完成
                if g_bHaveLetterNum > 0 then
                    -- 包里有信
                    -- 前往七巧庭QQFW_190620_12
                    QiXi_CollectDoll_Button : SetText("#{QQFW_190620_12}")
                    QiXi_CollectDoll_Button : SetToolTip("#{QQFW_190620_93}")    
                    QiXi_CollectDoll_Button : Enable()  
                    QiXi_CollectDoll_Button_Tips : Show()
                else
                    -- 包里没信
                    -- 领取溪娘信QQFW_190620_107
                    QiXi_CollectDoll_Button : SetText("#{QQFW_190620_107}")
                    QiXi_CollectDoll_Button : SetToolTip("#{QQFW_190620_108}")   
                    QiXi_CollectDoll_Button : Enable()  
                    QiXi_CollectDoll_Button_Tips : Hide()  
                end         
            end
        end      

        -- 特殊处理集齐了娃娃的情况
        if nActNum >= table.getn(g_tabActMF) then
            QiXi_CollectDoll_Button_Tips : Hide()  
        end
    end 

    if 2 == g_nHuoDongType then
        -- 结算中 QQFW_190620_13
        QiXi_CollectDoll_Button2 : SetText("#{QQFW_190620_13}")
        QiXi_CollectDoll_Button2 : Disable()      
        QiXi_CollectDoll_Button2 : SetToolTip("")    
        QiXi_CollectDoll_Button2_Tips : Hide()  
    end

    if 3 == g_nHuoDongType then
        if nActNum >= table.getn(g_tabActMF) then
            if 0 == g_bGetedReward then
                -- 领取奖励 QQFW_190620_14
                QiXi_CollectDoll_Button2 : SetText("#{QQFW_190620_14}")
                QiXi_CollectDoll_Button2 : Enable()
                QiXi_CollectDoll_Button2 : SetToolTip("")    
                QiXi_CollectDoll_Button2_Tips : Show()
            else
                -- 已领取 
                QiXi_CollectDoll_Button2 : SetText("#{QQFW_190620_139}")
                QiXi_CollectDoll_Button2 : Disable()
                QiXi_CollectDoll_Button2 : SetToolTip("")    
                QiXi_CollectDoll_Button2_Tips : Hide()  
            end        
        else
            -- 已结束 QQFW_190620_15
            QiXi_CollectDoll_Button2 : SetText("#{QQFW_190620_15}")
            QiXi_CollectDoll_Button2 : Disable()
            QiXi_CollectDoll_Button2 : SetToolTip("")    
            QiXi_CollectDoll_Button2_Tips : Hide()  
        end
    end

    -- 红色文本显示区
    -- if 1 == g_nHuoDongType then
    --     QiXi_CollectDoll_CountDown : SetText("#{QQFW_190620_56}")
    --     QiXi_CollectDoll_Timeproc()
    --     SetTimer("QiXi_CollectDoll", "QiXi_CollectDoll_Timeproc()", 1000)
    -- end

    -- QiXi_CollectDoll_CountDown : SetText("#{QQFW_190620_56}")
    QiXi_CollectDoll_Timeproc()
    SetTimer("QiXi_CollectDoll", "QiXi_CollectDoll_Timeproc()", 1000)

    if (2 == g_nHuoDongType or 3 == g_nHuoDongType) and g_nCurDayWorld >= g_nTimeJieSuanForSetp then
        KillTimer("QiXi_CollectDoll_Timeproc()")
        -- 红色文本显示区
        if nActNum >= table.getn(g_tabActMF) then
            -- 获奖的玩家
            local nPriceNum = math.ceil(g_nMaxPriceNum / g_nTotalActNum)
            QiXi_CollectDoll_CountDown : SetText(ScriptGlobal_Format("#{QQFW_190620_25}", nPriceNum))
            -- QiXi_CollectDoll_CountDownNum  : SetText("#{QQFW_190620_26}")
        else
            -- 未获奖的玩家
            QiXi_CollectDoll_CountDown : SetText(ScriptGlobal_Format("#{QQFW_190620_28}", g_nTimeJieSuanMonth, g_nTimeJieSuanDay, 0, 0))
            -- QiXi_CollectDoll_CountDownNum  : SetText("#{QQFW_190620_29}")
        end
    end
end

--=========================================================
-- 倒计时
--=========================================================
function QiXi_CollectDoll_Timeproc() 

    -- PushDebugMessage("QiXi_CollectDoll_Timeproc")

    local nTempValue = g_nRemainToTalSecond

    local nShowDay = math.floor(nTempValue / 86400)
    nTempValue = math.mod(nTempValue, 86400)

    local nShowHour = math.floor(nTempValue / 3600)
    nTempValue = math.mod(nTempValue, 3600)

    local nShowMintue= math.floor(nTempValue / 60)
    local nShowSecond = math.mod(nTempValue, 60)
   
    QiXi_CollectDoll_CountDown  : SetText(ScriptGlobal_Format("#{QQFW_190620_56}", nShowDay, nShowHour, nShowMintue, nShowSecond))
    -- QiXi_CollectDoll_CountDownNum  : SetText(ScriptGlobal_Format("#{QQFW_190620_64}", nShowDay, nShowHour, nShowMintue, nShowSecond))

    g_nRemainToTalSecond = g_nRemainToTalSecond - 1

    if g_nRemainToTalSecond < 0 then
        g_nRemainToTalSecond = 0
    end
end

--=========================================================
-- 重置界面
--=========================================================
function QiXi_CollectDoll_Reset()
    KillTimer("QiXi_CollectDoll_Timeproc()")
end

--=========================================================
-- 自动寻路按钮
--=========================================================
function QiXi_CollectDoll_AutoGoNPC(nIndex)

    local subItem = g_infoNPCGoto[nIndex]
    if nil == subItem then
        return
    end

    -- 是否在激活阶段
    if 1 ~= g_nHuoDongType then
        PushDebugMessage("#{QQFW_190620_102}")
        return
    end

    -- 等级判断
    local nLevel =Player:GetLevel()
    if nLevel < g_nLimitLevel then
        PushDebugMessage("#{QQFW_190620_103}")
        return
    end

    AutoRuntoTargetExWithName(subItem.nPosX, subItem.nPosY, subItem.nSceneID, subItem.strNPCName)

    if "" ~= subItem.strMsg then
        PushDebugMessage(subItem.strMsg)
    end

    -- 关闭界面
    if this:IsVisible() then
        QiXi_CollectDoll_OnClose()
    end
end

--=========================================================
-- 界面确认按钮
--=========================================================
function QiXi_CollectDoll_ConfirmClick()
    -- 参与活动 2 领取奖励 3
    local nClickType = 0
    if 1 == g_nHuoDongType then
        nClickType = 2
    end

    if 3 == g_nHuoDongType then
        nClickType = 3
    end

    if 0 == nClickType then
        PushDebugMessage("非法界面参数2")
        return
    end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnUIEvent" )
		Set_XSCRIPT_ScriptID(790010)
		Set_XSCRIPT_Parameter(0, -1)					
		Set_XSCRIPT_Parameter(1, nClickType)				
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--=========================================================
--帮助按钮
--=========================================================
function QiXi_CollectDoll_HelpClick()
    -- 借用一下别人的通道， 七夕瓜分活动 
    PushEvent("CCSHOP_HELP", 98)
end

--=========================================================
-- 关闭界面
--=========================================================
function QiXi_CollectDoll_OnClose()	
    -- PushDebugMessage("QiXi_CollectDoll_OnClose")
	this:Hide()
	StopCareObject_QiXi_CollectDoll()
	-- 重置
	QiXi_CollectDoll_Reset()
end

--=========================================================
-- 界面隐藏
--=========================================================
function QiXi_CollectDoll_OnHiden()
    -- PushDebugMessage("QiXi_CollectDoll_OnHiden")
	StopCareObject_QiXi_CollectDoll()
	-- 重置
	QiXi_CollectDoll_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_QiXi_CollectDoll()
	-- 关心
	this:CareObject(g_objCared, 1, "QiXi_CollectDoll")
end

function StopCareObject_QiXi_CollectDoll()
	-- 取消关心
	if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "QiXi_CollectDoll")
	end
	g_npcObjId = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function QiXi_CollectDoll_MoneyUpdate()
end

--=========================================================
-- 界面位置
--=========================================================
function QiXi_CollectDoll_Frame_On_ResetPos()
	QiXi_CollectDoll_Frame:SetProperty("UnifiedPosition", g_QiXi_CollectDoll_Frame_UnifiedPosition)
end