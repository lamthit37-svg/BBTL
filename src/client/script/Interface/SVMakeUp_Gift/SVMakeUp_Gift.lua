-- SVMakeUp_Gift SV错过活动补偿方案 2024-3-6 by lishilong
-- !!!reloadscript =SVMakeUp_Gift
--

local g_SVMakeUp_Gift_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 0
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= 0

local g_nCallScriptID		= 790091
local g_nUICommandID		= 79009101


local g_nItemBagPos			= -1
local g_nCostItemID			= -1
local g_nCostYuanBao		= -1
local g_nGiveItemID			= -1
local g_nGiveItemNum		= -1

local g_strShowTitle		= ""
local g_strShowTips			= ""

--=========================================================
-- PreLoad
--=========================================================
function SVMakeUp_Gift_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	if 1 == bCaredItem then
		this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	end
	if 1 == bCaredMoney then
		this:RegisterEvent("MONEY_CHANGE_EX", false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	end
	if 1 == bCaredYuanBao then
		this:RegisterEvent("UPDATE_YUANBAO", false)
	end
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
end

--=========================================================
-- OnLoad
--=========================================================
function SVMakeUp_Gift_OnLoad()
	g_SVMakeUp_Gift_Frame_UnifiedPosition = SVMakeUp_Gift_Frame:GetProperty("UnifiedPosition")

	-- SVMakeUp_Gift_OK_Button : SetEvent("Clicked", "SVMakeUp_Gift_ConfirmClick()")
end

--=========================================================
-- OnEvent
--=========================================================
function SVMakeUp_Gift_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				SVMakeUp_Gift_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						SVMakeUp_Gift_OnClose()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_SVMakeUp_Gift()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	SVMakeUp_Gift_OnClose()
			-- end
			SVMakeUp_Gift_Reset()
			SVMakeUp_Gift_Frame_On_ResetPos()
			this:Show()
			SVMakeUp_Gift_ParamInit()
			SVMakeUp_Gift_MoneyUpdate()
			SVMakeUp_Gift_YuanBaoUpdate()
			SVMakeUp_Gift_Update(1)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						SVMakeUp_Gift_OnClose()
					end
				end
			end
			if this:IsVisible() then
				SVMakeUp_Gift_ParamInit()
				SVMakeUp_Gift_Update(0)
			end
		end

		-- 二次确认框
		if 3 == nOpType then
			local strMsg = Get_XParam_STR(0)
			g_nComfirmParam1 = Get_XParam_INT(1)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("SVMakeUp_Gift_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
		end

	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_nObjCaredIDClient) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			SVMakeUp_Gift_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			SVMakeUp_Gift_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		SVMakeUp_Gift_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		SVMakeUp_Gift_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		SVMakeUp_Gift_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		SVMakeUp_Gift_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SVMakeUp_Gift_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function SVMakeUp_Gift_ParamInit()
	g_nItemBagPos		= Get_XParam_INT(1)
	g_nCostItemID		= Get_XParam_INT(2)
	g_nCostYuanBao		= Get_XParam_INT(3)
	g_nGiveItemID		= Get_XParam_INT(4)
	g_nGiveItemNum		= Get_XParam_INT(5)

	g_strShowTitle		= Get_XParam_STR(0)
	g_strShowTips		= Get_XParam_STR(1)

	-- PushDebugMessage("SVMakeUp_Gift_ParamInit:")

	-- PushDebugMessage("g_nItemBagPos:"..g_nItemBagPos..",g_nCostItemID:"..g_nCostItemID..",g_nCostYuanBao:"..g_nCostYuanBao)
	-- PushDebugMessage("g_nGiveItemID:"..g_nGiveItemID..",g_nGiveItemNum:"..g_nGiveItemNum)
	-- PushDebugMessage("g_strShowTitle:"..g_strShowTitle)
	-- PushDebugMessage("g_strShowTips:"..g_strShowTips)
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function SVMakeUp_Gift_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnItemReallyUse" )
			Set_XSCRIPT_ScriptID(g_nCallScriptID)
			Set_XSCRIPT_Parameter(0, g_nComfirmParam1)					
			Set_XSCRIPT_Parameter(1, 1)				
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end

	if "No" == strRet then
		
	end
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =SVMakeUp_Gift
function SVMakeUp_Gift_Update(bOpen)

	if g_nItemBagPos < 0 then
		SVMakeUp_Gift_OnClose()
	end

	-- PushDebugMessage("SVMakeUp_Gift_Update:"..bOpen)

	-- PushDebugMessage("g_nItemBagPos:"..g_nItemBagPos..",g_nCostItemID:"..g_nCostItemID..",g_nCostYuanBao:"..g_nCostYuanBao)
	-- PushDebugMessage("g_nGiveItemID:"..g_nGiveItemID..",g_nGiveItemNum:"..g_nGiveItemNum)
	-- PushDebugMessage("g_strShowTitle:"..g_strShowTitle)
	-- PushDebugMessage("g_strShowTips:"..g_strShowTips)

	-- 界面标题
	SVMakeUp_Gift_DragTitle : SetText(g_strShowTitle)

	-- 内容简介
	SVMakeUp_Gift_Info : SetText(g_strShowTips)

	-- 道具展示
	local theAction = DataPool:CreateActionItemForShow(g_nGiveItemID, g_nGiveItemNum)
	if 0 ~= theAction:GetID() then
		SVMakeUp_Gift_GiftItem : SetActionItem (theAction:GetID())
	end

	-- 需要的元宝
	SVMakeUp_Gift_NeedNum : SetText(ScriptGlobal_Format("#{SVBC_240308_06}", g_nCostYuanBao))

	-- 蒙红使用道具
	LifeAbility : Lock_Packet_Item(g_nItemBagPos, 1)
end

--=========================================================
-- 重置界面
--=========================================================
function SVMakeUp_Gift_Reset()

	-- 解除蒙红
	if g_nItemBagPos >= 0 then
		LifeAbility : Lock_Packet_Item(g_nItemBagPos, 0)
	end

	g_nItemBagPos		= -1
	g_nCostItemID		= -1
	g_nCostYuanBao		= -1
	g_nGiveItemID		= -1
	g_nGiveItemNum		= -1

	g_strShowTitle		= ""
	g_strShowTips		= ""

end

--=========================================================
-- 界面确认按钮
--=========================================================
function SVMakeUp_Gift_ConfirmClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnItemReallyUse" )
		Set_XSCRIPT_ScriptID(g_nCallScriptID)
		Set_XSCRIPT_Parameter(0, g_nItemBagPos)					
		Set_XSCRIPT_Parameter(1, 0)				
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--=========================================================
-- 关闭界面
--=========================================================
function SVMakeUp_Gift_OnClose()	
	this:Hide()
	StopCareObject_SVMakeUp_Gift()
	-- 重置
	SVMakeUp_Gift_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="SVMakeUp_Gift_OnHidden();" />
--=========================================================
function SVMakeUp_Gift_OnHidden()
	StopCareObject_SVMakeUp_Gift()
	-- 重置
	SVMakeUp_Gift_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_SVMakeUp_Gift()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "SVMakeUp_Gift")
end

function StopCareObject_SVMakeUp_Gift()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "SVMakeUp_Gift")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function SVMakeUp_Gift_MoneyUpdate()
	-- SVMakeUp_Gift_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- SVMakeUp_Gift_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function SVMakeUp_Gift_YuanBaoUpdate()
	-- SVMakeUp_Gift_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function SVMakeUp_Gift_Frame_On_ResetPos()
	SVMakeUp_Gift_Frame:SetProperty("UnifiedPosition", g_SVMakeUp_Gift_Frame_UnifiedPosition)
end