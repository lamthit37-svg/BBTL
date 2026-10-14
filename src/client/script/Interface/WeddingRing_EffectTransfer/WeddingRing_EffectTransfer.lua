-- 钻戒祝福特效转移

local g_WeddingRing_Frame_UnifiedPosition = nil 

local g_objCareID	= -1		-- careNpc
local g_Item_Pos	= -1		-- 锁定道具位置
local g_Ring_Pos	= -1		-- 戒指锁定位置
local g_Limit_Lv	= 30		-- 限制等级
local g_TargetId	= -1		-- ID
local g_Cost_Item	= 38005899	-- 消耗道具的ID
local g_Wedding_ring_list = {	-- 祝福戒指ID集合
	10422133,
	10422134,
	10422135, 
	10422136, 
	10422137, 
	10422138, 
	10422139, 
	10422140,
}

function WeddingRing_EffectTransfer_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("WEDDINGRING_TRANSFER_UPDATEUI",false)
	this:RegisterEvent("WEDDINGRING_TRANSFER_REMOVEUI",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
end 


function WeddingRing_EffectTransfer_OnLoad()
	g_WeddingRing_Frame_UnifiedPosition = WeddingRing_EffectTransfer_Frame:GetProperty("UnifiedPosition");

end

function WeddingRing_EffectTransfer_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 99811901 then
		WeddingRing_EffectTransfer_OnShow(Get_XParam_INT(0))
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99811902 then
		WeddingRing_EffectTransfer_OnHiden()
	elseif event == "WEDDINGRING_TRANSFER_UPDATEUI" then
		WeddingRing_EffectTransfer_UpdateAction(arg0, tonumber(arg1))
	elseif event == "WEDDINGRING_TRANSFER_REMOVEUI" then
		WeddingRing_EffectTransfer_RemoveAction(arg0)
	elseif event == "ADJEST_UI_POS" then
		WeddingRing_EffectTransfer_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		WeddingRing_EffectTransfer_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		WeddingRing_EffectTransfer_OnHiden()
	end
end

function WeddingRing_EffectTransfer_OnShow(targetId)
	-- 直接关闭对话框
	PushEvent("UI_COMMAND", 1000)
	-- 对现有内容进行清空
	WeddingRing_EffectTransfer_Clear()
	-- 关注NPC
	WeddingRing_EffectTransfer_BeginCareObject(targetId)
	
	this:Show()
end

function WeddingRing_EffectTransfer_ItemClear()

	if g_Item_Pos ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos, 0)
		g_Item_Pos = -1	
	end

	WeddingRing_EffectTransfer_Object2:SetActionItem(-1)

	WeddingRing_EffectTransfer_ButtonUpdate()
end

function WeddingRing_EffectTransfer_RingClear()

	if g_Ring_Pos ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Ring_Pos, 0)
		g_Ring_Pos = -1	
	end

	WeddingRing_EffectTransfer_Object1:SetActionItem(-1)

	WeddingRing_EffectTransfer_ButtonUpdate()
end

function WeddingRing_EffectTransfer_Clear()
	WeddingRing_EffectTransfer_ItemClear()
	WeddingRing_EffectTransfer_RingClear()
end


function WeddingRing_EffectTransfer_StopCareObject()
	this:CareObject(g_objCareID, 0, "WeddingRing_EffectTransfer")
	g_objCareID = -1
	g_TargetId = -1
end

function WeddingRing_EffectTransfer_BeginCareObject(targetId)
	g_TargetId = targetId
	g_objCareID = DataPool : GetNPCIDByServerID(targetId)
	this:CareObject(g_objCareID, 1, "WeddingRing_EffectTransfer")
end

function WeddingRing_EffectTransfer_IsWeddingRing(idx)
	if idx < 0 then
		return 0
	end

	for i, id in (g_Wedding_ring_list or {}) do
		if id == idx then
			return 1
		end
	end

	return 0
end

function WeddingRing_EffectTransfer_RemoveAction(sztype)
	if sztype == nil then
		return
	end

	if sztype == "item" then
		WeddingRing_EffectTransfer_ItemClear()
	elseif sztype == "ring" then
		WeddingRing_EffectTransfer_RingClear()
	end
end

function WeddingRing_EffectTransfer_UpdateAction(sztype, idx)
	if sztype == nil then
		return
	end

	if sztype == "item" then
		WeddingRing_EffectTransfer_UpdateItemAction(idx)
	elseif sztype == "ring" then
		WeddingRing_EffectTransfer_UpdateRingAction(idx)
	elseif sztype == "bag" then
		WeddingRing_EffectTransfer_UpdateBagAction(idx)
	end

end

function WeddingRing_EffectTransfer_UpdateItemAction(Idx)
	if Idx < 0 then
		WeddingRing_EffectTransfer_ItemClear()
	else
		-- 判定该道具是否可以加入
		local itemID = PlayerPackage : GetItemTableIndex(Idx)
		if itemID ~= g_Cost_Item then
			local sztips = ScriptGlobal_Format("#{HJZY_220520_14}", DataPool:Lua_GetItemNameByIndex(g_Cost_Item))
			PushDebugMessage(sztips)
			return
		end

		local theAction = EnumAction(Idx, "packageitem")
		if theAction:GetID() ~= 0 then
			-- 锁定
			if PlayerPackage:IsLock( Idx ) == 1 then
				PushDebugMessage("#{HJZY_220520_11}")	--道具已上锁
				return
			end

			if Idx ~= -1 then
				
				if g_Item_Pos ~= -1 then
					LifeAbility : Lock_Packet_Item(g_Item_Pos, 0)
					g_Item_Pos = -1
				end

				g_Item_Pos = Idx
				LifeAbility : Lock_Packet_Item(g_Item_Pos, 1)
			end

			WeddingRing_EffectTransfer_Object2:SetActionItem(theAction:GetID())
		end

		WeddingRing_EffectTransfer_ButtonUpdate()
	end
end

function WeddingRing_EffectTransfer_UpdateRingAction(Idx)
	if Idx < 0 then
		WeddingRing_EffectTransfer_RingClear()
	else
		-- 判定该道具是否可以加入
		local itemID = PlayerPackage : GetItemTableIndex(Idx)
		local isRing = WeddingRing_EffectTransfer_IsWeddingRing(itemID)
		if isRing < 1 then
			PushDebugMessage("#{HJZY_220520_13}")
			return
		end

		local theAction = EnumAction(Idx, "packageitem")
		if theAction:GetID() ~= 0 then
			-- 锁定
			if PlayerPackage:IsLock( Idx ) == 1 then
				PushDebugMessage("#{HJZY_220520_11}")	--道具已上锁
				return
			end

			if Idx ~= -1 then
				if g_Ring_Pos ~= -1 then
					LifeAbility : Lock_Packet_Item(g_Ring_Pos, 0)
					g_Ring_Pos = -1
				end

				g_Ring_Pos = Idx
				LifeAbility : Lock_Packet_Item(g_Ring_Pos, 1)
			end

			WeddingRing_EffectTransfer_Object1:SetActionItem(theAction:GetID())
		end

		WeddingRing_EffectTransfer_ButtonUpdate()
	end
end

function WeddingRing_EffectTransfer_UpdateBagAction(Idx)
	if Idx < 0 then
		return
	end
	local theAction = EnumAction(Idx, "packageitem")
	if theAction:GetID() ~= 0 then
		-- 锁定
		if PlayerPackage:IsLock( Idx ) == 1 then
			PushDebugMessage("#{HJZY_220520_11}")	--道具已上锁
			return
		end

		local itemID = PlayerPackage : GetItemTableIndex(Idx)
		local isRing = WeddingRing_EffectTransfer_IsWeddingRing(itemID)
		if isRing > 0 then
			WeddingRing_EffectTransfer_UpdateRingAction(Idx)
			return
		end
		local itemID = PlayerPackage : GetItemTableIndex(Idx)
		if itemID == g_Cost_Item then
			WeddingRing_EffectTransfer_UpdateItemAction(Idx)
			return
		end

		PushDebugMessage("#{HJZY_220520_12}")	--该物品不符合要求

		return
	end
end

function WeddingRing_EffectTransfer_ButtonUpdate()
	if g_Ring_Pos < 0 or g_Item_Pos < 0 then
		WeddingRing_EffectTransfer_OK:Disable()
	else
		WeddingRing_EffectTransfer_OK:Enable()
	end
end

function WeddingRing_EffectTransfer_Buttons_Clicked()
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZBSX_130625_62}")
		return
	end

	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end

	-- 判断ID是否合法
	if g_Ring_Pos < 0 then
		PushDebugMessage("#{HJZY_220520_13}")
		return
	end

	if g_Item_Pos < 0 then
		local sztips = ScriptGlobal_Format("#{HJZY_220520_14}", DataPool:Lua_GetItemNameByIndex(g_Cost_Item))
		PushDebugMessage(sztips)
		return
	end

	-- 发送给服务器
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnRingActive" )
		Set_XSCRIPT_ScriptID( 998119 )
		Set_XSCRIPT_Parameter( 0, g_Ring_Pos )
		Set_XSCRIPT_Parameter( 1, g_Item_Pos )
		Set_XSCRIPT_Parameter( 2, g_TargetId )
		Set_XSCRIPT_ParamCount( 3 )
	Send_XSCRIPT()

end

function WeddingRing_EffectTransfer_Cancel_Clicked()
	WeddingRing_EffectTransfer_OnHiden()
end

function WeddingRing_EffectTransfer_ItemRClick()
	WeddingRing_EffectTransfer_ItemClear()
end

function WeddingRing_EffectTransfer_RingRClick()
	WeddingRing_EffectTransfer_RingClear()
end

function WeddingRing_EffectTransfer_ResetPos()
	WeddingRing_EffectTransfer_Frame:SetProperty("UnifiedPosition", g_WeddingRing_Frame_UnifiedPosition)
end

function WeddingRing_EffectTransfer_OnHiden()
	WeddingRing_EffectTransfer_Clear()
	WeddingRing_EffectTransfer_StopCareObject()
	this:Hide()
end

function WeddingRing_EffectTransfer_Close()
	WeddingRing_EffectTransfer_OnHiden()
end
