-- JinLiReward 2019中秋锦鲤 2019-8-1 lishilong
-- !!!reloadscript =JinLiReward
--
local MAX_OBJ_DISTANCE 	= 3.0
local g_objCared 		= -1
local g_npcObjId 		= -1
local g_JinLiReward_Frame_UnifiedPosition
local bCaredObj 		= 0
local bCaredMoney 		= 0

-- 展示控件
local g_controlActionButton = {}

-- 39920566	4级秘银
-- 39920565	4级棉布
-- 39920329	至尊强化精华
-- 39921851	帮贡牌
-- 39920538	虹耀石
-- 展示道具
local g_tableShowItem = 
{
	[1] = 39920566,
	[2] = 39920565,
	[3] = 39920329,
	[4] = 39921851,
	[5] = 39920538,
	[6] = 39921670,
	[7] = 39920207,
	[8] = 39921287,
}

--=========================================================
-- PreLoad
--=========================================================
function JinLiReward_PreLoad()
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
function JinLiReward_OnLoad()
	g_JinLiReward_Frame_UnifiedPosition = JinLiReward_MainFrame:GetProperty("UnifiedPosition")
	g_controlActionButton[1] = JinLiReward_Item1
	g_controlActionButton[2] = JinLiReward_Item2
	g_controlActionButton[3] = JinLiReward_Item3
	g_controlActionButton[4] = JinLiReward_Item4
	g_controlActionButton[5] = JinLiReward_Item5
	g_controlActionButton[6] = JinLiReward_UpItem1
	g_controlActionButton[7] = JinLiReward_UpItem2
	g_controlActionButton[8] = JinLiReward_UpItem3
end

--=========================================================
-- OnEvent
--=========================================================
function JinLiReward_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 79002004 ) then
		-- 0 关闭，1打开， 2刷新
		local nOpType 	= tonumber(arg1)
		
		if 1 == bCaredObj then
			if objid == nil or objid < 0 then
				if this:IsVisible() then
					JinLiReward_OnClose()
				end
			end
		end
		
		if 0 == nOpType then
			-- 关闭界面
			if this:IsVisible() then
				JinLiReward_OnClose()
			end
			
		elseif 1 == nOpType then
			-- 打开界面
			-- 关注npc
			if 1 == bCaredObj then
				g_npcObjId = objid
				g_objCared = DataPool : GetNPCIDByServerID(tonumber(objid))
				BeginCareObject_JinLiReward()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	JinLiReward_OnClose()
			-- end
			JinLiReward_Reset()
			JinLiReward_Frame_On_ResetPos()
			this:Show()
			JinLiReward_ParamInit()
			JinLiReward_MoneyUpdate()
			JinLiReward_Update(1)
			
		elseif 2 == nOpType then
			-- 刷新界面
			if this:IsVisible() then
				JinLiReward_ParamInit()
				JinLiReward_Update(0)
			end
		end
	
	-- 物品改变
	-- elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
	-- 	-- 刷新界面
	-- 	if this:IsVisible() then
	-- 		JinLiReward_Update(0)
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
			JinLiReward_OnClose()
		end	
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		JinLiReward_OnClose()
	
	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
	-- elseif event == "MONEYJZ_CHANGE_EX" then
		JinLiReward_MoneyUpdate()
	
	elseif (event == "ADJEST_UI_POS" ) then
		JinLiReward_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JinLiReward_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function JinLiReward_ParamInit()

end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =JinLiReward
function JinLiReward_Update(bOpen)
	for i = 1, table.getn(g_controlActionButton)  do
		local nItemID = g_tableShowItem[i]
		if nil == nItemID then
			return
		end
		local theAction = DataPool:CreateActionItemForShow(nItemID, 1)
		g_controlActionButton[i] : SetActionItem(theAction:GetID())
	end
end

--=========================================================
-- 重置界面
--=========================================================
function JinLiReward_Reset()

end

--=========================================================
-- 界面确认按钮
--=========================================================
function JinLiReward_ConfirmClick(nParam)

end

--=========================================================
-- 关闭界面
--=========================================================
function JinLiReward_OnClose()	
	this:Hide()
	StopCareObject_JinLiReward()
	-- 重置
	JinLiReward_Reset()
end

--=========================================================
-- 界面隐藏
--=========================================================
function JinLiReward_OnHiden()
	StopCareObject_JinLiReward()
	-- 重置
	JinLiReward_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_JinLiReward()
	-- 关心
	this:CareObject(g_objCared, 1, "JinLiReward")
end

function StopCareObject_JinLiReward()
	-- 取消关心
	if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "JinLiReward")
	end
	g_npcObjId = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function JinLiReward_MoneyUpdate()
end

--=========================================================
-- 界面位置
--=========================================================
function JinLiReward_Frame_On_ResetPos()
	JinLiReward_MainFrame:SetProperty("UnifiedPosition", g_JinLiReward_Frame_UnifiedPosition)
end