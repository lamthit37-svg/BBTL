-- QiXi_DragDoll 七夕瓜分活动激活界面 2019-6-24 lishilong
-- !!!reloadscript =QiXi_DragDoll
--
local MAX_OBJ_DISTANCE 	= 3.0
local g_objCared 		= -1
local g_npcObjId 		= -1
local g_QiXi_DragDoll_Frame_UnifiedPosition
local bCaredObj 		= 1
local bCaredMoney 		= 0

-- 激活娃娃控件
local g_tabControlWaWaGet  = {}
local g_tabControlWaWaDis  = {}

-- Client2的激活控件
local g_tabControlWaWaAct  = {}
-- Client3的激活控件
local g_tabControlWaWaAct2 = {}

-- 各种Animate
local g_tabAnimateLeaf  = {}
local g_tabAnimateAct   = {}
local g_tabAnimateFall  = {}

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
-- 可用道具数量
local g_nHaveItemNum    = 0
-- 本次激活的娃娃
local g_nCurActWaWa     = 0

-- cd时间
local g_nCDTime         = 0
-- Play心跳计数
local g_nTickPlay       = 0

-- 38002749 动作礼包
local g_nItemIDLiBaoAction	= 30103096

--=========================================================
-- PreLoad
--=========================================================
function QiXi_DragDoll_PreLoad()
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
function QiXi_DragDoll_OnLoad()
    g_QiXi_DragDoll_Frame_UnifiedPosition = QiXi_DragDoll_FrameNULL:GetProperty("UnifiedPosition")
    
    g_tabControlWaWaGet[1]  = QiXi_DragDoll_Doll1_Get
    g_tabControlWaWaGet[2]  = QiXi_DragDoll_Doll2_Get
    g_tabControlWaWaGet[3]  = QiXi_DragDoll_Doll3_Get
    g_tabControlWaWaGet[4]  = QiXi_DragDoll_Doll4_Get
    g_tabControlWaWaGet[5]  = QiXi_DragDoll_Doll5_Get
    g_tabControlWaWaGet[6]  = QiXi_DragDoll_Doll6_Get
    g_tabControlWaWaGet[7]  = QiXi_DragDoll_Doll7_Get

    g_tabControlWaWaDis[1]  = QiXi_DragDoll_Doll1
    g_tabControlWaWaDis[2]  = QiXi_DragDoll_Doll2
    g_tabControlWaWaDis[3]  = QiXi_DragDoll_Doll3
    g_tabControlWaWaDis[4]  = QiXi_DragDoll_Doll4
    g_tabControlWaWaDis[5]  = QiXi_DragDoll_Doll5
    g_tabControlWaWaDis[6]  = QiXi_DragDoll_Doll6
    g_tabControlWaWaDis[7]  = QiXi_DragDoll_Doll7

    g_tabControlWaWaAct[1]  = QiXi_DragDoll_Display_Doll1
    g_tabControlWaWaAct[2]  = QiXi_DragDoll_Display_Doll2
    g_tabControlWaWaAct[3]  = QiXi_DragDoll_Display_Doll3
    g_tabControlWaWaAct[4]  = QiXi_DragDoll_Display_Doll4
    g_tabControlWaWaAct[5]  = QiXi_DragDoll_Display_Doll5
    g_tabControlWaWaAct[6]  = QiXi_DragDoll_Display_Doll6
    g_tabControlWaWaAct[7]  = QiXi_DragDoll_Display_Doll7

    g_tabControlWaWaAct2[1]  = QiXi_DragDoll_Final_Doll1
    g_tabControlWaWaAct2[2]  = QiXi_DragDoll_Final_Doll2
    g_tabControlWaWaAct2[3]  = QiXi_DragDoll_Final_Doll3
    g_tabControlWaWaAct2[4]  = QiXi_DragDoll_Final_Doll4
    g_tabControlWaWaAct2[5]  = QiXi_DragDoll_Final_Doll5
    g_tabControlWaWaAct2[6]  = QiXi_DragDoll_Final_Doll6
    g_tabControlWaWaAct2[7]  = QiXi_DragDoll_Final_Doll7

    g_tabAnimateLeaf[1]     = QiXi_DragDoll_Leaf1
    g_tabAnimateLeaf[2]     = QiXi_DragDoll_Leaf2
    g_tabAnimateLeaf[3]     = QiXi_DragDoll_Leaf3
    g_tabAnimateLeaf[4]     = QiXi_DragDoll_Leaf4
    g_tabAnimateLeaf[5]     = QiXi_DragDoll_Leaf5
    g_tabAnimateLeaf[6]     = QiXi_DragDoll_Leaf6

    g_tabAnimateAct[1]      = QiXi_DragDoll_Doll1_Animate
    g_tabAnimateAct[2]      = QiXi_DragDoll_Doll2_Animate
    g_tabAnimateAct[3]      = QiXi_DragDoll_Doll3_Animate
    g_tabAnimateAct[4]      = QiXi_DragDoll_Doll4_Animate
    g_tabAnimateAct[5]      = QiXi_DragDoll_Doll5_Animate
    g_tabAnimateAct[6]      = QiXi_DragDoll_Doll6_Animate
    g_tabAnimateAct[7]      = QiXi_DragDoll_Doll7_Animate

    g_tabAnimateFall[1]     = QiXi_DragDoll_Doll1_Fall
    g_tabAnimateFall[2]     = QiXi_DragDoll_Doll2_Fall
    g_tabAnimateFall[3]     = QiXi_DragDoll_Doll3_Fall
    g_tabAnimateFall[4]     = QiXi_DragDoll_Doll4_Fall
    g_tabAnimateFall[5]     = QiXi_DragDoll_Doll5_Fall
    g_tabAnimateFall[6]     = QiXi_DragDoll_Doll6_Fall
    g_tabAnimateFall[7]     = QiXi_DragDoll_Doll7_Fall
    
end

--=========================================================
-- OnEvent
--=========================================================
function QiXi_DragDoll_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 920190619 ) then
		-- 0 关闭，1打开， 2刷新
		local nOpType 	= Get_XParam_INT(0)
		local objid 	= Get_XParam_INT(1)
		
		if 1 == bCaredObj and 1 == nOpType then
			if objid == nil or objid < 0 then
                if this:IsVisible() then
                    -- PushDebugMessage("objid == nil or objid < 0")
					QiXi_DragDoll_OnClose()
				end
			end
        end
        
        -- if 1 == bCaredObj  then
		-- 	if objid == nil or objid < 0 then
        --         if this:IsVisible() then
        --             if nil == objid then
        --                 PushDebugMessage("objid == nil")
        --             else
        --                 PushDebugMessage("objid".. objid)
        --             end
		-- 			QiXi_DragDoll_OnClose()
		-- 		end
		-- 	end
		-- end
		
		if 0 == nOpType then
			-- 关闭界面
            if this:IsVisible() then
                -- PushDebugMessage("2222222")
				QiXi_DragDoll_OnClose()
			end
			
		elseif 1 == nOpType then
			-- 打开界面
			-- 关注npc
			if 1 == bCaredObj then
                g_npcObjId = objid
                -- PushDebugMessage("打开界面 g_npcObjId"..g_npcObjId)
				g_objCared = DataPool : GetNPCIDByServerID(tonumber(objid))
				BeginCareObject_QiXi_DragDoll()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
            -- if this:IsVisible() then
            --     -- PushDebugMessage("3333333")
			-- 	QiXi_DragDoll_OnClose()
			-- end
            QiXi_DragDoll_Reset()
            QiXi_DragDoll_Frame_On_ResetPos()
			this:Show()
			QiXi_DragDoll_ParamInit()
			QiXi_DragDoll_MoneyUpdate()
			QiXi_DragDoll_Update(1)
			
		elseif 2 == nOpType then
			-- 刷新界面
			if this:IsVisible() then
                -- 跨天刷新特写 
                if Get_XParam_INT(9) < 0 and g_nCurActWaWa > 0 then
                    QiXi_DragDoll_Reset()
                    QiXi_DragDoll_ParamInit()
                    QiXi_DragDoll_Update(0)
                else
                    QiXi_DragDoll_ParamInit()
                    QiXi_DragDoll_Update(0)
                end
            end
        elseif 3 == nOpType then
			-- 清cd
			if this:IsVisible() then
                KillTimer("QiXi_DragDoll_TimeprocCD()")
                g_nCDTime = 0
			end
		end
	
	-- 物品改变
	-- elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
	-- 	-- 刷新界面
	-- 	if this:IsVisible() then
	-- 		QiXi_DragDoll_Update(0)
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
			QiXi_DragDoll_OnClose()
		end	
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		QiXi_DragDoll_OnClose()
	
	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
	-- elseif event == "MONEYJZ_CHANGE_EX" then
		QiXi_DragDoll_MoneyUpdate()
	
	elseif (event == "ADJEST_UI_POS" ) then
		QiXi_DragDoll_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		QiXi_DragDoll_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function QiXi_DragDoll_ParamInit()
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

    g_nHaveItemNum              = Get_XParam_INT(8)

    g_nCurActWaWa               = Get_XParam_INT(9)
    if g_nCurActWaWa < 0 then
        g_nCurActWaWa = 0
    end

end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =QiXi_DragDoll
function QiXi_DragDoll_Update(bOpen)

	QiXi_DragDoll_Client1 : Show()
    QiXi_DragDoll_Client2 : Hide()
    QiXi_DragDoll_Client3 : Hide()

    -- 停止所有动画
    for i = 1, table.getn(g_tabAnimateLeaf) do
        g_tabAnimateLeaf[i] : Play(false)
    end

    for i = 1, table.getn(g_tabAnimateAct) do
        g_tabAnimateAct[i] : Play(false)
    end

    for i = 1, table.getn(g_tabAnimateFall) do
        g_tabAnimateFall[i] : Play(false)
    end
    
    if g_nHuoDongType < 1 or g_nHuoDongType > 3 then
        PushDebugMessage("非法界面参数")
        return
    end
  
    -- 激活娃娃显示
    local nActNum = 0 
    for i = 1, table.getn(g_tabActMF) do 
        if 1 == g_tabActMF[i] and g_nCurActWaWa ~= i then
            nActNum = nActNum + 1
            g_tabControlWaWaGet[i] : Show()
            g_tabControlWaWaDis[i] : Hide()
        else
            g_tabControlWaWaGet[i] : Hide()
            g_tabControlWaWaDis[i] : Show()
        end
    end

    -- 兑换道具数量
    if g_nHaveItemNum <= 0 then
        QiXi_DragDoll_ZongZi1_CurrencyText : SetText(ScriptGlobal_Format("#{QQFW_190620_86}", g_nHaveItemNum, 7))
    else   
        QiXi_DragDoll_ZongZi1_CurrencyText : SetText(ScriptGlobal_Format("#{QQFW_190620_77}", g_nHaveItemNum, 7))
    end

    -- 活动截止时间
    -- QiXi_DragDoll_ZongZi1_InfoText1 : SetText("#{QQFW_190620_56}")

    -- 触发激活的定时器
    if g_nCurActWaWa > 0 then
        g_nTickPlay = 0
        QiXi_DragDoll_TimeprocPlay() 
        SetTimer("QiXi_DragDoll", "QiXi_DragDoll_TimeprocPlay()", 500)
    end
end

--=========================================================
-- cd 心跳 1s
--=========================================================
function QiXi_DragDoll_TimeprocCD() 

    -- PushDebugMessage("QiXi_DragDoll_TimeprocCD"..g_nCDTime)
    g_nCDTime = g_nCDTime - 1
    if g_nCDTime <= 0 then
        g_nCDTime = 0
        KillTimer("QiXi_DragDoll_TimeprocCD()")
    end
end

--=========================================================
-- play 心跳 0.5s
--=========================================================
function QiXi_DragDoll_TimeprocPlay() 
    
    -- 前2s播放叶子Animate

    -- 0s开始播放的叶子Animate
    if 0 == g_nTickPlay then       
        g_tabAnimateLeaf[1] : Play(true)
        g_tabAnimateLeaf[2] : Play(true)
    end

    -- 0.5s开始播放的叶子Animate
    if 1 == g_nTickPlay then     
        g_tabAnimateLeaf[3] : Play(true)
        g_tabAnimateLeaf[4] : Play(true)
    end

    -- 1s开始播放的叶子Animate
    if 2 == g_nTickPlay then     
        g_tabAnimateLeaf[5] : Play(true)
        g_tabAnimateLeaf[6] : Play(true)
    end

    -- 2s结束所有叶子动画 并且播激活动画
    if 4 == g_nTickPlay then    
        for i = 1, table.getn(g_tabAnimateLeaf) do
            g_tabAnimateLeaf[i] : Play(false)
        end

        -- 结束定时器
        KillTimer("QiXi_DragDoll_TimeprocPlay()")

        -- 开始动画
        g_tabAnimateAct[g_nCurActWaWa] : Play(true)
    end

    g_nTickPlay = g_nTickPlay + 1
    
end

--=========================================================
-- Animate播放完成的回调 激活
--=========================================================
function QiXi_DragDoll_OnAnimateActEnd()
	g_tabAnimateFall[g_nCurActWaWa] : Play(true)
end

--=========================================================
-- Animate播放完成的回调 掉落
--=========================================================
function QiXi_DragDoll_OnAnimateFallEnd()

    local bActAll = 1
    for i = 1, table.getn(g_tabActMF) do 
        if 0 == g_tabActMF[i] then
            bActAll = 0
            break
        end
    end

    if 1 == bActAll then
        QiXi_DragDoll_Client3 : Show()
    
        for i = 1, table.getn(g_tabControlWaWaAct2) do
            g_tabControlWaWaAct2[i] : Hide()    
        end

        g_tabControlWaWaAct2[g_nCurActWaWa] : Show()

        local theAction = DataPool:CreateActionItemForShow(g_nItemIDLiBaoAction, 1)
        QiXi_DragDoll_Final_Package : SetActionItem(theAction:GetID())
    else
        QiXi_DragDoll_Client2 : Show()
    
        for i = 1, table.getn(g_tabControlWaWaAct) do
            g_tabControlWaWaAct[i] : Hide()    
        end

        g_tabControlWaWaAct[g_nCurActWaWa] : Show()
    end
    
    g_tabControlWaWaGet[g_nCurActWaWa] : Show()

    g_nCurActWaWa = 0
end

--=========================================================
-- 重置界面
--=========================================================
function QiXi_DragDoll_Reset()
    KillTimer("QiXi_DragDoll_TimeprocPlay()")
    KillTimer("QiXi_DragDoll_TimeprocCD()")
    g_nCDTime = 0
    g_nTickPlay = 0
    g_nCurActWaWa = 0

    -- 停止所有动画
    for i = 1, table.getn(g_tabAnimateLeaf) do
        g_tabAnimateLeaf[i] : Play(false)
    end

    for i = 1, table.getn(g_tabAnimateAct) do
        g_tabAnimateAct[i] : Play(false)
    end

    for i = 1, table.getn(g_tabAnimateFall) do
        g_tabAnimateFall[i] : Play(false)
    end
end

--=========================================================
--帮助按钮
--=========================================================
function QiXi_DragDoll_HelpClick()
    -- 借用一下别人的通道， 七夕瓜分活动 
    PushEvent("CCSHOP_HELP", 97)
end

--=========================================================
-- 界面确认按钮 激活
--=========================================================
function QiXi_DragDoll_ConfirmClick()

    if g_nCDTime > 0 then
        PushDebugMessage(ScriptGlobal_Format("#{QQFW_190620_78}", g_nCDTime))
        return
    end

    g_nCDTime = 5
    SetTimer("QiXi_DragDoll", "QiXi_DragDoll_TimeprocCD()", 1000)

    -- PushDebugMessage("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnUIEvent" )
		Set_XSCRIPT_ScriptID(790010)
		Set_XSCRIPT_Parameter(0, g_npcObjId)					
		Set_XSCRIPT_Parameter(1, 1)				
		Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
    
    -- PushDebugMessage("界面确认按钮 g_npcObjId"..g_npcObjId)
end

--=========================================================
-- 关闭小界面
--=========================================================
function QiXi_DragDoll_OnCloseClient2()
    QiXi_DragDoll_Update(0)
end

--=========================================================
-- 关闭界面
--=========================================================
function QiXi_DragDoll_OnClose()	
	this:Hide()
	StopCareObject_QiXi_DragDoll()
	-- 重置
	QiXi_DragDoll_Reset()
end

--=========================================================
-- 界面隐藏
--=========================================================
function QiXi_DragDoll_OnHiden()
	StopCareObject_QiXi_DragDoll()
	-- 重置
	QiXi_DragDoll_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_QiXi_DragDoll()
	-- 关心
	this:CareObject(g_objCared, 1, "QiXi_DragDoll")
end

function StopCareObject_QiXi_DragDoll()
	-- 取消关心
	if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "QiXi_DragDoll")
	end
    g_npcObjId = -1
    
    -- PushDebugMessage("取消关心 g_npcObjId"..g_npcObjId)
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function QiXi_DragDoll_MoneyUpdate()
end

--=========================================================
-- 界面位置
--=========================================================
function QiXi_DragDoll_Frame_On_ResetPos()
	QiXi_DragDoll_FrameNULL:SetProperty("UnifiedPosition", g_QiXi_DragDoll_Frame_UnifiedPosition)
end