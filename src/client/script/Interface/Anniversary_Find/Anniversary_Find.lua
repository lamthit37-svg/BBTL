-- Anniversary_Find 周年庆预热访仙活动 主界面 2019-3-18 by lishilong
-- !!!reloadscript =Anniversary_Find
--
local MAX_OBJ_DISTANCE = 3.0
local g_objCared = -1
local g_npcObjId = -1
local g_Anniversary_Find_Frame_UnifiedPosition
local bCaredObj = 0

-- 激活标记
local g_tabActFlag      = {0, 0, 0, 0, 0, 0}
local g_bActWX          = 0
local g_nActIndex		= 0

-- 控件 激活、未激活
local g_controlAct      = {}
local g_controlUnAct    = {}
local g_controlAnimate	= {}

--=========================================================
-- PreLoad
--=========================================================
function Anniversary_Find_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

--=========================================================
-- OnLoad
--=========================================================
function Anniversary_Find_OnLoad()
    g_Anniversary_Find_Frame_UnifiedPosition = Anniversary_Find_Frame:GetProperty("UnifiedPosition")
    
    g_controlAct[1]     = Anniversary_Find_NPC1_Light
    g_controlAct[2]     = Anniversary_Find_NPC2_Light
    g_controlAct[3]     = Anniversary_Find_NPC3_Light
    g_controlAct[4]     = Anniversary_Find_NPC4_Light
    g_controlAct[5]     = Anniversary_Find_NPC5_Light
    g_controlAct[6]     = Anniversary_Find_NPC6_Light

    g_controlUnAct[1]   = Anniversary_Find_NPC1_Dis
    g_controlUnAct[2]   = Anniversary_Find_NPC2_Dis
    g_controlUnAct[3]   = Anniversary_Find_NPC3_Dis
    g_controlUnAct[4]   = Anniversary_Find_NPC4_Dis
    g_controlUnAct[5]   = Anniversary_Find_NPC5_Dis
	g_controlUnAct[6]   = Anniversary_Find_NPC6_Dis
	
	g_controlAnimate[1]	= Anniversary_Find_Animate1
    g_controlAnimate[2]	= Anniversary_Find_Animate2
    g_controlAnimate[3]	= Anniversary_Find_Animate3
    g_controlAnimate[4]	= Anniversary_Find_Animate4
    g_controlAnimate[5]	= Anniversary_Find_Animate5
    g_controlAnimate[6]	= Anniversary_Find_Animate6

    -- PushDebugMessage("Anniversary_Find_OnLoad")
end

--=========================================================
-- OnEvent
--=========================================================
function Anniversary_Find_OnEvent(event)
    if ( event == "UI_COMMAND" and tonumber(arg0) == 920190318 ) then
        -- PushDebugMessage("Anniversary_Find_OnEvent")

		-- 0 关闭，1打开， 2刷新
		local nOpType 	= Get_XParam_INT(0)
        local objid 	= Get_XParam_INT(1)
		
		if 1 == bCaredObj then
			if objid == nil or objid < 0 then
				if this:IsVisible() then
					Anniversary_Find_OnClose()
				end
			end
		end
		
		if 0 == nOpType then
			-- 关闭界面
			if this:IsVisible() then
				Anniversary_Find_OnClose()
			end
			
		elseif 1 == nOpType then
			-- 打开界面
			-- 关注npc
			if 1 == bCaredObj then
				g_npcObjId = objid
				g_objCared = DataPool : GetNPCIDByServerID(tonumber(objid))
				BeginCareObject_Anniversary_Find()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			if this:IsVisible() then
				Anniversary_Find_OnClose()
			end
			Anniversary_Find_Reset()
            this:Show()
            Anniversary_Find_ParamInit()
			Anniversary_Find_MoneyUpdate()
			Anniversary_Find_Update(1)
			
		elseif 2 == nOpType then
			-- 刷新界面
            if this:IsVisible() then
                Anniversary_Find_ParamInit()
				Anniversary_Find_Update(0)
			end
		end
	
	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		-- 刷新界面
		-- if this:IsVisible() then
		-- 	Anniversary_Find_Update(0)
		-- end
	
	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			Anniversary_Find_OnClose()
		end	
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Anniversary_Find_OnClose()
	
	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
	-- elseif event == "MONEYJZ_CHANGE_EX" then
		Anniversary_Find_MoneyUpdate()
	
	elseif (event == "ADJEST_UI_POS" ) then
		Anniversary_Find_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Anniversary_Find_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function Anniversary_Find_ParamInit()
    g_bActWX        = Get_XParam_INT(2)
        
    for i = 1, table.getn(g_tabActFlag) do
        g_tabActFlag[i] = Get_XParam_INT(i + 2)
        if nil == g_tabActFlag[i] then
            g_tabActFlag[i] = 0
        end
	end
	
	g_nActIndex		= Get_XParam_INT(3 + table.getn(g_tabActFlag))
    
    -- PushDebugMessage("g_tabActFlag"..g_tabActFlag[1]..","..g_tabActFlag[2]..","..g_tabActFlag[3]..","..g_tabActFlag[4]..","..g_tabActFlag[5]..","..g_tabActFlag[6])
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =Anniversary_Find
function Anniversary_Find_Update(bAutoPos)
    local nTotalNum = 0
    for i = 1, table.getn(g_tabActFlag) do
        if 1 == g_tabActFlag[i] then
            g_controlAct[i]     : Show()
            g_controlUnAct[i]   : Hide()
            nTotalNum = nTotalNum +1
        else
            g_controlAct[i]     : Hide()
            g_controlUnAct[i]   : Show()
        end
    end

    -- 按钮
    if nTotalNum >= table.getn(g_tabActFlag) then
        -- ZNTZ_190318_64	激活
        Anniversary_Find_Btn1   : Hide()
        Anniversary_Find_Btn2   : Show()
    else
        -- ZNTZ_190318_63	参与活动
        Anniversary_Find_Btn1   : Show()
        Anniversary_Find_Btn2   : Hide()
    end

    -- 描述 红色 ZNTZ_190318_95	#cfff263访遇进度#cff0000%s0/6红色的访遇字典
	local strMsg = ScriptGlobal_Format("#{ZNTZ_190318_95}", nTotalNum, table.getn(g_tabActFlag))
	-- 全部激活 换色 绿色
	if nTotalNum >= table.getn(g_tabActFlag) then
		strMsg = ScriptGlobal_Format("#{ZNTZ_190318_03}", nTotalNum, table.getn(g_tabActFlag))
	end
    Anniversary_Find_Collect : SetText(strMsg)

    -- 激活状态
    if 1 == g_bActWX then
        Anniversary_Find_Btn2 : SetText("#{ZNTZ_190318_67}")
        Anniversary_Find_Text : SetText("#{ZNTZ_190318_66}")
    else
        Anniversary_Find_Btn2 : SetText("#{ZNTZ_190318_64}")
        Anniversary_Find_Text : SetText("#{ZNTZ_190318_65}")
	end

	-- 激活按钮的特效 全部完成还未激活显示
	if nTotalNum >= table.getn(g_tabActFlag) and 0 == g_bActWX then
		Anniversary_Find_BtnAnimate : Show()
		-- Anniversary_Find_BtnAnimate	: Play(true)
		-- PushDebugMessage("true 激活按钮的特效 全部完成还未激活显示")
	else
		-- Anniversary_Find_BtnAnimate	: Play(false)
		Anniversary_Find_BtnAnimate : Hide()
		-- PushDebugMessage("false 激活按钮的特效 全部完成还未激活显示")
	end
	
	-- 单独处理Animate的逻辑
	if g_nActIndex >= 1 and g_nActIndex <= table.getn(g_controlAnimate) then
		-- 隐藏被激活图片
		g_controlAct[g_nActIndex]     : Hide()
		g_controlUnAct[g_nActIndex]   : Show()

		-- 显示激活动画
		g_controlAnimate[g_nActIndex]	: Play(true)
	end
end

--=========================================================
-- Animate播放完成的回调
--=========================================================
function Anniversary_Find_OnAnimateEnd(nIndex)
	g_nActIndex = 0
	Anniversary_Find_Update(0)
end

--=========================================================
--重置界面
--=========================================================
function Anniversary_Find_Reset()
    for i = 1, table.getn(g_tabActFlag) do
        g_tabActFlag[i] = 0
    end

	g_bActWX = 0
	g_nActIndex = 0

	for i = 1, table.getn(g_controlAnimate) do
		g_controlAnimate[i] : Play(false)
	end

	-- Anniversary_Find_BtnAnimate	: Play(false)
	Anniversary_Find_BtnAnimate : Hide()
end

--=========================================================
--界面确认按钮
--=========================================================
function Anniversary_Find_ConfirmClick(nType)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnUIEvent" )
		Set_XSCRIPT_ScriptID(790003)
		Set_XSCRIPT_Parameter(0, nType)							
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=========================================================
--帮助按钮
--=========================================================
function Anniversary_Find_HelpClick()
    -- 借用一下别人的通道， 周年庆预热访仙活动 
    PushEvent("CCSHOP_HELP", 99)
end
    
--=========================================================
-- 关闭界面
--=========================================================
function Anniversary_Find_OnClose()	
	this:Hide()
	StopCareObject_Anniversary_Find()
	-- 重置
	Anniversary_Find_Reset()
end

--=========================================================
--界面隐藏
--=========================================================
function Anniversary_Find_OnHiden()
	StopCareObject_Anniversary_Find()
	-- 重置
	Anniversary_Find_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_Anniversary_Find()
	-- 关心
	this:CareObject(g_objCared, 1, "Anniversary_Find")
end

function StopCareObject_Anniversary_Find()
	-- 取消关心
	if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "Anniversary_Find")
	end
	g_npcObjId = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function Anniversary_Find_MoneyUpdate()
end

--=========================================================
-- 界面位置
--=========================================================
function Anniversary_Find_Frame_On_ResetPos()
  Anniversary_Find_Frame:SetProperty("UnifiedPosition", g_Anniversary_Find_Frame_UnifiedPosition)
end