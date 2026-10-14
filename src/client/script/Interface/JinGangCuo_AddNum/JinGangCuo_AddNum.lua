-- JinGangCuo_AddNum
-- !!!reloadscript =JinGangCuo_AddNum
--

local g_JinGangCuo_AddNum_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 1
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= 0

local g_nUICommandID					= 80926101
local g_nJinGangCuoItemID				= 30008048

local g_nInputItemBagPos01				= -1
local g_bInputItemBindStatus01			= -1
local g_nInputItemBagPos02				= -1
local g_bInputItemBindStatus02			= -1

local g_nNewJinGangCuoMaxUseTimes 		= 99
local g_nNewJinGangCuoUseTimes 			= 11
local g_nOldJinGangCuoMaxUseTimes		= 11
local g_nNewJinGangCuoInitFlagNum		= -1

--=========================================================
-- PreLoad
--=========================================================
function JinGangCuo_AddNum_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("INGANGCUO_ADDNUM_RCLICK_INPUT_ITEM", false)
	this:RegisterEvent("JINGANGCUO_ADDNUM_DRAP_INPUT_ITEM", false)
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
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

--=========================================================
-- OnLoad
--=========================================================
function JinGangCuo_AddNum_OnLoad()
	g_JinGangCuo_AddNum_Frame_UnifiedPosition = JinGangCuo_AddNum_Frame:GetProperty("UnifiedPosition")

	-- JinGangCuo_AddNum_OK_Button : SetEvent("Clicked", "JinGangCuo_AddNum_ConfirmClick()")
end

--=========================================================
-- OnEvent
--=========================================================
function JinGangCuo_AddNum_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				JinGangCuo_AddNum_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						JinGangCuo_AddNum_OnClose()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_JinGangCuo_AddNum()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	JinGangCuo_AddNum_OnClose()
			-- end
			JinGangCuo_AddNum_Reset()
			JinGangCuo_AddNum_Frame_On_ResetPos()
			this:Show()
			JinGangCuo_AddNum_ParamInit()
			JinGangCuo_AddNum_MoneyUpdate()
			JinGangCuo_AddNum_YuanBaoUpdate()
			JinGangCuo_AddNum_Update(1)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						JinGangCuo_AddNum_OnClose()
					end
				end
			end
			if this:IsVisible() then
				JinGangCuo_AddNum_ParamInit()
				JinGangCuo_AddNum_Update(0)
			end
		end

		-- 二次确认框
		if 3 == nOpType then
			local strMsg = Get_XParam_STR(0)
			-- g_nComfirmParam1 = Get_XParam_INT(1)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("JinGangCuo_AddNum_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
		end

	-- 右键背包道具放入
	elseif event == "INGANGCUO_ADDNUM_RCLICK_INPUT_ITEM" and this:IsVisible() then
		local nItemBagPos = tonumber(arg0)
		JinGangCuo_AddNum_OnRClickBagItem(nItemBagPos)

	-- 道具拖拽放入
	elseif event == "JINGANGCUO_ADDNUM_DRAP_INPUT_ITEM" and this:IsVisible() then
		local nItemBagPos = tonumber(arg0)
		local nDragButtonIndex = tonumber(arg1)
		JinGangCuo_AddNum_OnDragInputItem(nItemBagPos, nDragButtonIndex)

	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_nObjCaredIDClient) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			JinGangCuo_AddNum_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			JinGangCuo_AddNum_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		JinGangCuo_AddNum_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		JinGangCuo_AddNum_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		JinGangCuo_AddNum_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		JinGangCuo_AddNum_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JinGangCuo_AddNum_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function JinGangCuo_AddNum_ParamInit()
	local nInputItemBagPos01 = Get_XParam_INT(2)
	local nInputItemBagPos02 = Get_XParam_INT(3)

	JinGangCuo_AddNum_ActionButtonSet(1, nInputItemBagPos01)
	JinGangCuo_AddNum_ActionButtonSet(2, nInputItemBagPos02)
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function JinGangCuo_AddNum_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnAddJingGangCuoUseTimes" )
			Set_XSCRIPT_ScriptID(809261)
			Set_XSCRIPT_Parameter(0, g_nServerObjID)	
			Set_XSCRIPT_Parameter(1, g_nInputItemBagPos01)					
			Set_XSCRIPT_Parameter(2, g_nInputItemBagPos02)				
			Set_XSCRIPT_Parameter(3, 1)				
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end

	if "No" == strRet then
		
	end
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =JinGangCuo_AddNum
function JinGangCuo_AddNum_Update(bOpen)

	local nOldItemCanUseTimes = 0
	local nNewItemCanUseTimes = 0
	local nMatItemCanUseTimes = 0

	if g_nInputItemBagPos01 >= 0 then
		nOldItemCanUseTimes = JinGangCuo_AddNum_GetJinGangCuoCanUseTimes(g_nInputItemBagPos01)
		JinGangCuo_AddNum_ActionButtonSet(1, g_nInputItemBagPos01)
	end

	if g_nInputItemBagPos02 >= 0 then
		nMatItemCanUseTimes = JinGangCuo_AddNum_GetJinGangCuoCanUseTimes(g_nInputItemBagPos02)
		JinGangCuo_AddNum_ActionButtonSet(2, g_nInputItemBagPos02)
	end

	-- PushDebugMessage("JinGangCuo_AddNum_Update"..",g_nInputItemBagPos01:"..g_nInputItemBagPos01..",g_nInputItemBagPos02:"..g_nInputItemBagPos02..",nOldItemCanUseTimes:"..nOldItemCanUseTimes..",nMatItemCanUseTimes:"..nMatItemCanUseTimes)

	if nOldItemCanUseTimes > 0 then
		local strMsg = ScriptGlobal_Format("#{JGCYH_230414_13}", nOldItemCanUseTimes)
		JinGangCuo_AddNum_AddFileTxt : SetText(strMsg)
	else
		JinGangCuo_AddNum_AddFileTxt : SetText("")
	end

	if nMatItemCanUseTimes > 0 then
		local strMsg = ScriptGlobal_Format("#{JGCYH_230414_13}", nMatItemCanUseTimes)
		JinGangCuo_AddNum_RemainFileTxt : SetText(strMsg)
	else
		JinGangCuo_AddNum_RemainFileTxt : SetText("")
	end

	if nOldItemCanUseTimes > 0 and nMatItemCanUseTimes > 0 then
		nNewItemCanUseTimes = nOldItemCanUseTimes + nMatItemCanUseTimes
		if nNewItemCanUseTimes > g_nNewJinGangCuoMaxUseTimes then
			nNewItemCanUseTimes = g_nNewJinGangCuoMaxUseTimes
		end

		local strMsg = ScriptGlobal_Format("#{JGCYH_230414_15}", nNewItemCanUseTimes)
		JinGangCuo_AddNum_AfterFileTxt : SetText(strMsg)
	else 
		JinGangCuo_AddNum_AfterFileTxt : SetText("")
	end
	
end

--=========================================================
-- 右键背包道具放入
--=========================================================
function JinGangCuo_AddNum_OnRClickBagItem(nItemBagPos)

	-- PushDebugMessage("JinGangCuo_AddNum_OnRClickBagItem"..",nItemBagPos:"..nItemBagPos)

	local nItemTableIndex = PlayerPackage : GetItemTableIndex( nItemBagPos )
	if g_nJinGangCuoItemID ~= nItemTableIndex then
		PushDebugMessage("#{JGCYH_230414_09}")
		return
	end

	if 1 == PlayerPackage:IsLock( nItemBagPos ) then
		PushDebugMessage("#{JGCYH_230414_10}")
		return
	end

	local nItemCanUseTimes = JinGangCuo_AddNum_GetJinGangCuoCanUseTimes(nItemBagPos)

	-- 格子1空着 优先格子1
	if g_nInputItemBagPos01 < 0 then

		if nItemCanUseTimes >= g_nNewJinGangCuoMaxUseTimes then
			PushDebugMessage("#{JGCYH_230414_11}")
			return
		end

		JinGangCuo_AddNum_ActionButtonSet(1, nItemBagPos)
		JinGangCuo_AddNum_Update(0)
		return
	end

	-- 格子1不空 替换格子2
	if nItemCanUseTimes >= g_nNewJinGangCuoMaxUseTimes then
		PushDebugMessage("#{JGCYH_230414_25}")
		return
	end

	JinGangCuo_AddNum_ActionButtonSet(2, nItemBagPos)
	JinGangCuo_AddNum_Update(0)

	-- if g_nInputItemBagPos02 < 0 then
	-- 	JinGangCuo_AddNum_ActionButtonSet(2, nItemBagPos)
	-- 	JinGangCuo_AddNum_Update(0)
	-- 	return
	-- end

	-- PushDebugMessage("满了")
	
end

--=========================================================
-- 道具拖拽放入
--=========================================================
function JinGangCuo_AddNum_OnDragInputItem(nItemBagPos, nDragButtonIndex)
	-- PushDebugMessage("JinGangCuo_AddNum_OnDragInputItem"..",nItemBagPos:"..nItemBagPos..",nDragButtonIndex:"..nDragButtonIndex)

	local nItemTableIndex = PlayerPackage : GetItemTableIndex( nItemBagPos )

	if g_nJinGangCuoItemID ~= nItemTableIndex then
		PushDebugMessage("#{JGCYH_230414_09}")
		return
	end

	if 1 == PlayerPackage:IsLock( nItemBagPos ) then
		PushDebugMessage("#{JGCYH_230414_10}")
		return
	end

	local nItemCanUseTimes = JinGangCuo_AddNum_GetJinGangCuoCanUseTimes(nItemBagPos)
	if 1 == nDragButtonIndex then	
		if nItemCanUseTimes >= g_nNewJinGangCuoMaxUseTimes then
			PushDebugMessage("#{JGCYH_230414_11}")
			return
		end
	end

	if 2 == nDragButtonIndex then	
		if nItemCanUseTimes >= g_nNewJinGangCuoMaxUseTimes then
			PushDebugMessage("#{JGCYH_230414_25}")
			return
		end
	end

	JinGangCuo_AddNum_ActionButtonSet(nDragButtonIndex, nItemBagPos)
	JinGangCuo_AddNum_Update(0)
end

--=========================================================
-- 右键界面ActionButton
--=========================================================
function JinGangCuo_AddNum_OnRClickActionButton(nButtonIndex)
	JinGangCuo_AddNum_ActionButtonSet(nButtonIndex, -1)
	JinGangCuo_AddNum_Update(0)
end

--=========================================================
-- 处理ActionButton放入操作
-- 支持自动蒙红解除蒙红 更换全局变量
--=========================================================
function JinGangCuo_AddNum_ActionButtonSet(nButtonIndex, nItemBagPos)

	if 1 == nButtonIndex then

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
			JinGangCuo_AddNum_BeforeFileItem : SetActionItem(-1)
			g_nInputItemBagPos01 = -1
			g_bInputItemBindStatus01 = -1
		else
			-- local theAction = EnumAction(nItemBagPos, "packageitem")
			local bBind = PlayerPackage : GetItemBindStatusByIndex(nItemBagPos)
			local nItemTableIndex = PlayerPackage : GetItemTableIndex( nItemBagPos )
			local theAction = nil
			if 1 == bBind then
				theAction = DataPool : CreateBindActionItemForShow(nItemTableIndex, 1)
			else
				theAction = DataPool : CreateActionItemForShow(nItemTableIndex, 1)
			end

			if nil ~= theAction and 0 ~= theAction:GetID() then
				JinGangCuo_AddNum_BeforeFileItem : SetActionItem(theAction:GetID())
				LifeAbility : Lock_Packet_Item(nItemBagPos, 1)
			end
			
			g_nInputItemBagPos01 = nItemBagPos
			g_bInputItemBindStatus01 = bBind
		end

	end

	if 2 == nButtonIndex then

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

		-- if nItemBagPos >= 0 and nItemBagPos == g_nInputItemBagPos01 then
		-- 	return
		-- end

		if g_nInputItemBagPos02 >= 0 then
			LifeAbility : Lock_Packet_Item(g_nInputItemBagPos02, 0)
		end

		if nItemBagPos < 0 then
			JinGangCuo_AddNum_UseFileItem : SetActionItem(-1)
			g_nInputItemBagPos02 = -1
			g_bInputItemBindStatus02 = -1
		else
			-- local theAction = EnumAction(nItemBagPos, "packageitem")
			local bBind = PlayerPackage : GetItemBindStatusByIndex(nItemBagPos)
			local nItemTableIndex = PlayerPackage : GetItemTableIndex( nItemBagPos )
			local theAction = nil
			if 1 == bBind then
				theAction = DataPool : CreateBindActionItemForShow(nItemTableIndex, 1)
			else
				theAction = DataPool : CreateActionItemForShow(nItemTableIndex, 1)
			end

			if nil ~= theAction and 0 ~= theAction:GetID() then
				JinGangCuo_AddNum_UseFileItem : SetActionItem(theAction:GetID())
				LifeAbility : Lock_Packet_Item(nItemBagPos, 1)
			end
			
			g_nInputItemBagPos02 = nItemBagPos
			g_bInputItemBindStatus02 = bBind
		end

	end
end

--=========================================================
-- 获得金刚锉的可使用次数
--=========================================================
function JinGangCuo_AddNum_GetJinGangCuoCanUseTimes(nItemBagPos)

	local nItemTableIndex = PlayerPackage : GetItemTableIndex( nItemBagPos )

	if g_nJinGangCuoItemID ~= nItemTableIndex then
		return 0
	end

	-- 重写金刚锉的逻辑
	-- 需要兼容线上已有的金刚锉
	-- 旧物品参数含义：
	-- 04Int：未使用为0。已使用存的是最大使用次数 固定11次
	-- 08Int：未使用为0。已使用存的是已经使用的次数
	-- 兼容逻辑如下：
	-- 1、检测到04Int有数值并且是11，则认为该物品为需要兼容的线上已使用过的金刚锉。设置04Int为-1，设置08Int为使用次数（04Int-08Int）。
	-- 2、检测到04Int数值为0，则认为该物品为新物品或者未使用过的金刚锉。设置04Int为-1，设置08Int为使用次数11。
	-- 新物品参数含义：
	-- 04Int：未使用为0。已使用存的是-1，初始化标记。
	-- 08Int：未使用为0。已使用存的是可使用次数。	

	local nParamInt4 = PlayerPackage:Lua_GetItemAttachParam( nItemBagPos, 4, 2 )
	local nParamInt8 = PlayerPackage:Lua_GetItemAttachParam( nItemBagPos, 8, 2 )
	local nJinGangCuoCanUseTimes = 0

	-- PushDebugMessage("JinGangCuo_AddNum_GetJinGangCuoCanUseTimes"..",nParamInt4:"..nParamInt4..",nParamInt8:"..nParamInt8)

	-- 没有初始化过的道具 不处理
	if 0 == nParamInt4 then
		nJinGangCuoCanUseTimes = g_nNewJinGangCuoUseTimes
	end

	-- 已经转换过参数的 使用过的道具
	if g_nNewJinGangCuoInitFlagNum == nParamInt4 then
		nJinGangCuoCanUseTimes = nParamInt8
	end

	-- 没有转换过参数的旧道具
	if g_nOldJinGangCuoMaxUseTimes == nParamInt4 then
		nJinGangCuoCanUseTimes = nParamInt4 - nParamInt8
	end

	return nJinGangCuoCanUseTimes
	
end

--=========================================================
-- 重置界面
--=========================================================
function JinGangCuo_AddNum_Reset()

	-- PushDebugMessage("JinGangCuo_AddNum_Reset")

	JinGangCuo_AddNum_ActionButtonSet(1, -1)
	JinGangCuo_AddNum_ActionButtonSet(2, -1)
	
end

--=========================================================
-- 界面确认按钮
--=========================================================
function JinGangCuo_AddNum_ConfirmClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnAddJingGangCuoUseTimes" )
		Set_XSCRIPT_ScriptID(809261)
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
function JinGangCuo_AddNum_OnHelp()	
end

--=========================================================
-- 关闭界面
--=========================================================
function JinGangCuo_AddNum_OnClose()		
	-- 重置
	JinGangCuo_AddNum_Reset()

	StopCareObject_JinGangCuo_AddNum()

	this:Hide()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="JinGangCuo_AddNum_OnHidden();" />
--=========================================================
function JinGangCuo_AddNum_OnHidden()	
	-- 重置
	JinGangCuo_AddNum_Reset()

	StopCareObject_JinGangCuo_AddNum()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_JinGangCuo_AddNum()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "JinGangCuo_AddNum")
end

function StopCareObject_JinGangCuo_AddNum()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "JinGangCuo_AddNum")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function JinGangCuo_AddNum_MoneyUpdate()
	-- JinGangCuo_AddNum_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- JinGangCuo_AddNum_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function JinGangCuo_AddNum_YuanBaoUpdate()
	-- JinGangCuo_AddNum_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function JinGangCuo_AddNum_Frame_On_ResetPos()
	JinGangCuo_AddNum_Frame:SetProperty("UnifiedPosition", g_JinGangCuo_AddNum_Frame_UnifiedPosition)
end