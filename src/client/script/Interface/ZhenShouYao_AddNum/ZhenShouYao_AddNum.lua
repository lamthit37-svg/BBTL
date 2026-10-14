-- ZhenShouYao_AddNum
-- !!!reloadscript =ZhenShouYao_AddNum
--

local g_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local g_bCaredObj 			= 1
local g_nComfirmParam1		= 0

local g_nUICommandID		= 99865501
local g_nItemInfo			= 
{
	[30607000] = { OldMaxUseTimes=100, SameClassItem=30607002, showItem=39924405, }, --珍兽滋补丹
	[30607001] = { OldMaxUseTimes=100, SameClassItem=30607004, showItem=39924406, }, --珍兽回春丹
	[30607002] = { OldMaxUseTimes=100, SameClassItem=30607000, showItem=39920540, }, --珍兽滋补丹
	[30607004] = { OldMaxUseTimes=100, SameClassItem=30607001, showItem=39920539, }, --珍兽回春丹
	
	[30607005] = { OldMaxUseTimes=300, SameClassItem=-1, showItem=39924399, }, --超级珍兽滋补丹
	[30607006] = { OldMaxUseTimes=300, SameClassItem=-1, showItem=39924400, }, --超级珍兽回春丹
	
	[38001080] = { OldMaxUseTimes=500, SameClassItem=38001081, showItem=39924403, }, --珍兽万补丹
	[38001081] = { OldMaxUseTimes=500, SameClassItem=38001080, showItem=39920838, }, --珍兽万补丹
	
	[38001082] = { OldMaxUseTimes=500, SameClassItem=38001083, showItem=39924404, }, --珍兽回神丹
	[38001083] = { OldMaxUseTimes=500, SameClassItem=38001082, showItem=39920545, }, --珍兽回神丹
}

local g_nInputItemBagPos01				= -1
local g_bInputItemBindStatus01			= -1
local g_nInputItemBagPos02				= -1
local g_bInputItemBindStatus02			= -1

local g_nNewItemMaxUseTimes 			= 9999
local g_nInitFlagNum_NoUse				= 0
local g_nInitFlagNum_HaveUse			= -1

local g_nInterfacePos01					= 1
local g_nInterfacePos02					= 2

--=========================================================
-- PreLoad
--=========================================================
function ZhenShouYao_AddNum_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	
	this:RegisterEvent("PETFOOD_ADDNUM_RCLICK_INPUT_ITEM", false)
	this:RegisterEvent("PETFOOD_ADDNUM_DRAP_INPUT_ITEM", false)
	
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

--=========================================================
-- OnLoad
--=========================================================
function ZhenShouYao_AddNum_OnLoad()
	g_Frame_UnifiedPosition = ZhenShouYao_AddNum_Frame:GetProperty("UnifiedPosition")
end

--=========================================================
-- OnEvent
--=========================================================
function ZhenShouYao_AddNum_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				ZhenShouYao_AddNum_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 显示界面
			ZhenShouYao_AddNum_Open()
		end
			
		-- 刷新界面
		if 2 == nOpType then
			if this:IsVisible() == true then
				ZhenShouYao_AddNum_ParamInit()
				ZhenShouYao_AddNum_Update()
			end
		end

		-- 二次确认框
		if 3 == nOpType then
			local strMsg = Get_XParam_STR(0)
			-- g_nComfirmParam1 = Get_XParam_INT(1)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("ZhenShouYao_AddNum_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
		end

	-- 右键背包道具放入
	elseif event == "PETFOOD_ADDNUM_RCLICK_INPUT_ITEM" then
		local nItemBagPos = tonumber(arg0)
		ZhenShouYao_AddNum_OnRClickBagItem(nItemBagPos)

	-- 道具拖拽放入
	elseif event == "PETFOOD_ADDNUM_DRAP_INPUT_ITEM" then
		local nItemBagPos = tonumber(arg0)
		local nDragButtonIndex = tonumber(arg1)
		ZhenShouYao_AddNum_OnDragInputItem(nItemBagPos, nDragButtonIndex)

	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == g_bCaredObj then
		if(tonumber(arg0) ~= g_nObjCaredIDClient) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			ZhenShouYao_AddNum_OnClose()
		end	

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ZhenShouYao_AddNum_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		ZhenShouYao_AddNum_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ZhenShouYao_AddNum_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function ZhenShouYao_AddNum_ParamInit()
	local nInputItemBagPos01 = Get_XParam_INT(2)
	local nInputItemBagPos02 = Get_XParam_INT(3)

	ZhenShouYao_AddNum_ActionButtonSet(g_nInterfacePos01, nInputItemBagPos01)
	ZhenShouYao_AddNum_ActionButtonSet(g_nInterfacePos02, nInputItemBagPos02)
end

--=========================================================
-- 打开界面
--=========================================================
function ZhenShouYao_AddNum_Open()
	ZhenShouYao_AddNum_Reset()
	ZhenShouYao_AddNum_Frame_On_ResetPos()
	
	-- 关注npc
	BeginCareObject_ZhenShouYao_AddNum()
	this:Show()
	
	ZhenShouYao_AddNum_ParamInit()
	ZhenShouYao_AddNum_Update()
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function ZhenShouYao_AddNum_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnAddUseTimes" )
			Set_XSCRIPT_ScriptID(998655)
			Set_XSCRIPT_Parameter(0, g_nServerObjID)	
			Set_XSCRIPT_Parameter(1, g_nInputItemBagPos01)					
			Set_XSCRIPT_Parameter(2, g_nInputItemBagPos02)				
			Set_XSCRIPT_Parameter(3, 1)				
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end
end

--=========================================================
-- 界面更新
--=========================================================
function ZhenShouYao_AddNum_Update()

	local nOldItemCanUseTimes = 0
	local nNewItemCanUseTimes = 0
	local nMatItemCanUseTimes = 0
	
	if g_nInputItemBagPos01 >= 0 then
		nOldItemCanUseTimes = ZhenShouYao_AddNum_GetCanUseTimes(g_nInputItemBagPos01)
		ZhenShouYao_AddNum_ActionButtonSet(g_nInterfacePos01, g_nInputItemBagPos01)
	end

	if g_nInputItemBagPos02 >= 0 then
		nMatItemCanUseTimes = ZhenShouYao_AddNum_GetCanUseTimes(g_nInputItemBagPos02)
		ZhenShouYao_AddNum_ActionButtonSet(g_nInterfacePos02, g_nInputItemBagPos02)
	end

	-- PushDebugMessage("ZhenShouYao_AddNum_Update"..",g_nInputItemBagPos01:"..g_nInputItemBagPos01..",g_nInputItemBagPos02:"..g_nInputItemBagPos02..",nOldItemCanUseTimes:"..nOldItemCanUseTimes..",nMatItemCanUseTimes:"..nMatItemCanUseTimes)

	if nOldItemCanUseTimes > 0 then
		local strMsg = ScriptGlobal_Format("#{YBYY_230721_10}", nOldItemCanUseTimes)
		ZhenShouYao_AddNum_AddFileTxt : SetText(strMsg)
	else
		ZhenShouYao_AddNum_AddFileTxt : SetText("")
	end

	if nMatItemCanUseTimes > 0 then
		local strMsg = ScriptGlobal_Format("#{YBYY_230721_10}", nMatItemCanUseTimes)
		ZhenShouYao_AddNum_RemainFileTxt : SetText(strMsg)
	else
		ZhenShouYao_AddNum_RemainFileTxt : SetText("")
	end

	if nOldItemCanUseTimes > 0 and nMatItemCanUseTimes > 0 then
		nNewItemCanUseTimes = nOldItemCanUseTimes + nMatItemCanUseTimes
		if nNewItemCanUseTimes > g_nNewItemMaxUseTimes then
			nNewItemCanUseTimes = g_nNewItemMaxUseTimes
		end

		local strMsg = ScriptGlobal_Format("#{YBYY_230721_10}", nNewItemCanUseTimes)
		ZhenShouYao_AddNum_AfterFileTxt : SetText(strMsg)
	else 
		ZhenShouYao_AddNum_AfterFileTxt : SetText("")
	end
	
end

--=========================================================
-- 右键背包道具放入
--=========================================================
function ZhenShouYao_AddNum_OnRClickBagItem(nItemBagPos)

	-- PushDebugMessage("ZhenShouYao_AddNum_OnRClickBagItem"..",nItemBagPos:"..nItemBagPos)

	local nItemTableIndex = PlayerPackage : GetItemTableIndex( nItemBagPos )
	if nil == g_nItemInfo[nItemTableIndex] then
		PushDebugMessage("#{YBYY_230721_14}")
		return
	end

	if 1 == PlayerPackage:IsLock( nItemBagPos ) then
		PushDebugMessage("#{YBYY_230721_15}")
		return
	end

	local nItemCanUseTimes = ZhenShouYao_AddNum_GetCanUseTimes(nItemBagPos)
	if nItemCanUseTimes >= g_nNewItemMaxUseTimes then
		PushDebugMessage("#{YBYY_230721_21}")
		return
	end
	
	-- 格子1空着 优先格子1
	if g_nInputItemBagPos01 < 0 then

		ZhenShouYao_AddNum_ActionButtonSet(g_nInterfacePos01, nItemBagPos)
		ZhenShouYao_AddNum_Update()
		return
	end

	-- 格子1不空 替换格子2
	local nItemIndex01 = PlayerPackage : GetItemTableIndex( g_nInputItemBagPos01 )
	
	local isSameClass = 0
	if nItemIndex01 == g_nItemInfo[nItemTableIndex].SameClassItem and 
		nItemTableIndex == g_nItemInfo[nItemIndex01].SameClassItem then
		isSameClass = 1
	end
	
	if nItemIndex01 ~= nItemTableIndex and isSameClass == 0 then
		local strName = PlayerPackage:GetBagItemName( g_nInputItemBagPos01 )
		local strMsg = ScriptGlobal_Format("#{YBYY_230721_18}", strName)
		PushDebugMessage(strMsg)
		return
	end
		
	ZhenShouYao_AddNum_ActionButtonSet(g_nInterfacePos02, nItemBagPos)
	ZhenShouYao_AddNum_Update()
	
end

--=========================================================
-- 道具拖拽放入
--=========================================================
function ZhenShouYao_AddNum_OnDragInputItem(nItemBagPos, nDragButtonIndex)
	-- PushDebugMessage("ZhenShouYao_AddNum_OnDragInputItem"..",nItemBagPos:"..nItemBagPos..",nDragButtonIndex:"..nDragButtonIndex)

	local nItemTableIndex = PlayerPackage : GetItemTableIndex( nItemBagPos )

	if nil == g_nItemInfo[nItemTableIndex] then
		PushDebugMessage("#{YBYY_230721_14}")
		return
	end

	if 1 == PlayerPackage:IsLock( nItemBagPos ) then
		PushDebugMessage("#{YBYY_230721_15}")
		return
	end

	local nItemCanUseTimes = ZhenShouYao_AddNum_GetCanUseTimes(nItemBagPos)
	if g_nInterfacePos01 == nDragButtonIndex then	
		if nItemCanUseTimes >= g_nNewItemMaxUseTimes then
			PushDebugMessage("#{YBYY_230721_16}")
			return
		end
	end

	if g_nInterfacePos02 == nDragButtonIndex then		
		if g_nInputItemBagPos01 == -1 then
			PushDebugMessage("#{YBYY_230721_17}")
			return
		end
		
		local nItemIndex01 = PlayerPackage : GetItemTableIndex( g_nInputItemBagPos01 )
		
		local isSameClass = 0
		if nItemIndex01 == g_nItemInfo[nItemTableIndex].SameClassItem and 
			nItemTableIndex == g_nItemInfo[nItemIndex01].SameClassItem then
			isSameClass = 1
		end
		
		if nItemIndex01 ~= nItemTableIndex and isSameClass == 0 then
			local strName = PlayerPackage:GetBagItemName( g_nInputItemBagPos01 )
			local strMsg = ScriptGlobal_Format("#{YBYY_230721_18}", strName)
			PushDebugMessage(strMsg)
			return
		end
		
		if nItemCanUseTimes >= g_nNewItemMaxUseTimes then
			PushDebugMessage("#{YBYY_230721_20}")
			return
		end	
	end

	ZhenShouYao_AddNum_ActionButtonSet(nDragButtonIndex, nItemBagPos)
	ZhenShouYao_AddNum_Update()
end

--=========================================================
-- 右键界面ActionButton
--=========================================================
function ZhenShouYao_AddNum_OnRClickActionButton(nButtonIndex)
	ZhenShouYao_AddNum_ActionButtonSet(nButtonIndex, -1)
	
	if g_nInterfacePos01 == nButtonIndex then	
		ZhenShouYao_AddNum_ActionButtonSet(g_nInterfacePos02, -1)
	end
	
	ZhenShouYao_AddNum_Update()
end

--=========================================================
-- 处理ActionButton放入操作
-- 支持自动蒙红解除蒙红 更换全局变量
--=========================================================
function ZhenShouYao_AddNum_ActionButtonSet(nButtonIndex, nItemBagPos)

	if g_nInterfacePos01 == nButtonIndex then
		
		if nItemBagPos == g_nInputItemBagPos01 then
			local bChangeBindStatus = 0
			if nItemBagPos >= 0 then
				local bBind = PlayerPackage : GetItemBindStatusByIndex(nItemBagPos)
				if g_bInputItemBindStatus01 ~= bBind then
					bChangeBindStatus = 1
				end
			end

			if 0 == bChangeBindStatus then
				return
			end
			
		end

		-- if nItemBagPos >= 0 and nItemBagPos == g_nInputItemBagPos02 then
		-- 	return
		-- end
		if g_nInputItemBagPos01 >= 0 then
			LifeAbility : Lock_Packet_Item(g_nInputItemBagPos01, 0)
		end

		if nItemBagPos < 0 then
			ZhenShouYao_AddNum_BeforeFileItem : SetActionItem(-1)
			g_nInputItemBagPos01 = -1
			g_bInputItemBindStatus01 = -1
		else
			-- local theAction = EnumAction(nItemBagPos, "packageitem")
			local bBind = PlayerPackage : GetItemBindStatusByIndex(nItemBagPos)
			local nItemTableIndex = PlayerPackage : GetItemTableIndex( nItemBagPos )
			local nShowItemId = g_nItemInfo[nItemTableIndex].showItem
			local theAction = nil
			if 1 == bBind then
				theAction = DataPool : CreateBindActionItemForShow(nShowItemId, 1)
			else
				theAction = DataPool : CreateActionItemForShow(nShowItemId, 1)
			end

			if nil ~= theAction and 0 ~= theAction:GetID() then
				ZhenShouYao_AddNum_BeforeFileItem : SetActionItem(theAction:GetID())
				LifeAbility : Lock_Packet_Item(nItemBagPos, 1)
			end
			
			g_nInputItemBagPos01 = nItemBagPos
			g_bInputItemBindStatus01 = bBind
		end

	end

	if g_nInterfacePos02 == nButtonIndex then

		if nItemBagPos == g_nInputItemBagPos02 then
			local bChangeBindStatus = 0
			if nItemBagPos >= 0 then
				local bBind = PlayerPackage : GetItemBindStatusByIndex(nItemBagPos)
				if g_bInputItemBindStatus02 ~= bBind then
					bChangeBindStatus = 1
				end
			end

			if 0 == bChangeBindStatus then
				return
			end
		end

		if g_nInputItemBagPos02 >= 0 then
			LifeAbility : Lock_Packet_Item(g_nInputItemBagPos02, 0)
		end

		if nItemBagPos < 0 then
			ZhenShouYao_AddNum_UseFileItem : SetActionItem(-1)
			g_nInputItemBagPos02 = -1
			g_bInputItemBindStatus02 = -1
		else
			-- local theAction = EnumAction(nItemBagPos, "packageitem")
			local bBind = PlayerPackage : GetItemBindStatusByIndex(nItemBagPos)
			local nItemTableIndex = PlayerPackage : GetItemTableIndex( nItemBagPos )
			local nShowItemId = g_nItemInfo[nItemTableIndex].showItem
			local theAction = nil
			if 1 == bBind then
				theAction = DataPool : CreateBindActionItemForShow(nShowItemId, 1)
			else
				theAction = DataPool : CreateActionItemForShow(nShowItemId, 1)
			end

			if nil ~= theAction and 0 ~= theAction:GetID() then
				ZhenShouYao_AddNum_UseFileItem : SetActionItem(theAction:GetID())
				LifeAbility : Lock_Packet_Item(nItemBagPos, 1)
			end
			
			g_nInputItemBagPos02 = nItemBagPos
			g_bInputItemBindStatus02 = bBind
		end

	end
end

--=========================================================
-- 获得可使用次数
--=========================================================
function ZhenShouYao_AddNum_GetCanUseTimes(nItemBagPos)

	local nItemTableIndex = PlayerPackage : GetItemTableIndex( nItemBagPos )

	if nil == g_nItemInfo[nItemTableIndex] then
		return 0
	end

	-- 重写珍兽药的逻辑
	-- 需要兼容线上已有的珍兽药
	-- 珍兽药包括 超级珍兽回春丹、超级珍兽滋补丹、珍兽万补丹、珍兽回神丹、珍兽滋补丹、珍兽回春丹
	-- 旧物品参数含义：
	-- 04Int：未使用为0。已使用存的是最大使用次数
	-- 08Int：未使用为0。已使用存的是已经使用的次数
	-- 兼容逻辑如下：
	-- 1、检测到04Int有数值并且是最大值，则认为该物品为需要兼容的线上已使用过的珍兽药。设置04Int为-1，设置08Int为使用次数（04Int-08Int）。
	-- 2、检测到04Int数值为0，则认为该物品为新物品或者未使用过的珍兽药。设置04Int为-1，设置08Int为使用次数11。
	-- 新物品参数含义：
	-- 04Int：未使用为0。已使用存的是-1，初始化标记。
	-- 08Int：未使用为0。已使用存的是可使用次数。	

	local nParamInt4 = PlayerPackage:Lua_GetItemAttachParam( nItemBagPos, 4, 2 )
	local nParamInt8 = PlayerPackage:Lua_GetItemAttachParam( nItemBagPos, 8, 2 )
	local nCanUseTimes = 0

	-- PushDebugMessage("ZhenShouYao_AddNum_GetCanUseTimes"..",nParamInt4:"..nParamInt4..",nParamInt8:"..nParamInt8)

	-- 没有初始化过的道具 不处理
	if g_nInitFlagNum_NoUse == nParamInt4 then
		nCanUseTimes = g_nItemInfo[nItemTableIndex].OldMaxUseTimes
	end

	-- 已经转换过参数的 使用过的道具
	if g_nInitFlagNum_HaveUse == nParamInt4 then
		nCanUseTimes = nParamInt8
	end

	-- 没有转换过参数的旧道具
	if g_nItemInfo[nItemTableIndex].OldMaxUseTimes == nParamInt4 then
		nCanUseTimes = nParamInt4 - nParamInt8
	end

	return nCanUseTimes
	
end

--=========================================================
-- 重置界面
--=========================================================
function ZhenShouYao_AddNum_Reset()

	-- PushDebugMessage("ZhenShouYao_AddNum_Reset")

	ZhenShouYao_AddNum_ActionButtonSet(g_nInterfacePos01, -1)
	ZhenShouYao_AddNum_ActionButtonSet(g_nInterfacePos02, -1)
	
end

--=========================================================
-- 界面确认按钮
--=========================================================
function ZhenShouYao_AddNum_ConfirmClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnAddUseTimes" )
		Set_XSCRIPT_ScriptID(998655)
		Set_XSCRIPT_Parameter(0, g_nServerObjID)	
		Set_XSCRIPT_Parameter(1, g_nInputItemBagPos01)					
		Set_XSCRIPT_Parameter(2, g_nInputItemBagPos02)				
		Set_XSCRIPT_Parameter(3, 0)				
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

--=========================================================
-- 帮助
--=========================================================
function ZhenShouYao_AddNum_OnHelp()	
end

--=========================================================
-- 关闭界面
--=========================================================
function ZhenShouYao_AddNum_OnClose()		
	-- 重置
	ZhenShouYao_AddNum_Reset()

	StopCareObject_ZhenShouYao_AddNum()

	this:Hide()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="ZhenShouYao_AddNum_OnHidden();" />
--=========================================================
function ZhenShouYao_AddNum_OnHidden()	
	-- 重置
	ZhenShouYao_AddNum_Reset()

	StopCareObject_ZhenShouYao_AddNum()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_ZhenShouYao_AddNum()
	if 1 ~= g_bCaredObj then
		return
	end
	
	local nServerObjID 	= Get_XParam_INT(1)
	if nServerObjID == nil or nServerObjID < 0 then
		return
	end
	
	g_nServerObjID = nServerObjID
	g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
			
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "ZhenShouYao_AddNum")
end


function StopCareObject_ZhenShouYao_AddNum()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "ZhenShouYao_AddNum")
	end
	g_nServerObjID = -1
end


--=========================================================
-- 界面位置
--=========================================================
function ZhenShouYao_AddNum_Frame_On_ResetPos()
	ZhenShouYao_AddNum_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

