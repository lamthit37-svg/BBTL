-- 激活背挂，头饰

local g_DressPaint_TB_Frame_UnifiedPosition = nil 

local g_objCareID	= -1		-- careNpc
local g_Item_Pos	= -1		-- 锁定道具位置
local g_Op_Type		= 0			-- 操作类型

local g_Limit_Lv	= 30		-- 限制等级
local g_Need_Money	= 50000		-- 需要金钱
local g_eOpType = {
	Back = 0,
	Head = 1,
}

local g_Time_Rate	= 24

function DressPaint_TB_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ORNAMENTS_ITEM_UPDATE",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
end 


function DressPaint_TB_OnLoad()
	g_DressPaint_TB_Frame_UnifiedPosition = DressPaint_TB_Frame:GetProperty("UnifiedPosition");

end

function DressPaint_TB_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 88896101 then
		DressPaint_TB_OnShow(Get_XParam_INT(0), Get_XParam_INT(1))
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88896102 then
		DressPaint_TB_UpdateItemAction(-1)
	elseif event == "ORNAMENTS_ITEM_UPDATE" then
		DressPaint_TB_UpdateItemAction(tonumber(arg0))
	elseif event == "ADJEST_UI_POS" then
		DressPaint_TB_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		DressPaint_TB_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		DressPaint_TB_OnHiden()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 120203161) or  
	    ( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
		if this:IsVisible() then
			DressPaint_TB_OnHiden()
		end
	end
end

function DressPaint_TB_OnShow(opType, targetId)
	PushEvent( "CLOSE_DRESSPREVIEW")
	PushEvent( "CLOSE_GEMEFFECTPREVIEW")
	g_Op_Type = opType
	DressPaint_TB_Clear()
	DressPaint_TB_BeginCareObject(targetId)
	
	DressPaint_TB_Init()
	DressPaint_TB_InitFakeObj()
	this:Show()
end

function DressPaint_TB_Init()
	if g_Op_Type == g_eOpType.Back then
		DressPaint_TB_BackBaseUIShow()
	elseif g_Op_Type == g_eOpType.Head then
		DressPaint_TB_HeadBaseUIShow()
	end
end

function DressPaint_TB_BackBaseUIShow()
	DressPaint_TB_Title:SetText("#{BGTS_220125_05}")
	DressPaint_TB_Info:SetText("#{BGTS_220125_06}")
	DressPaint_TB_DemandPaintItemNumber:SetText("")
	DressPaint_TB_ItemText:SetText("")
	--DressPaint_TB_DemandMoney:SetProperty("MoneyNumber", 0)
end

function DressPaint_TB_HeadBaseUIShow()
	DressPaint_TB_Title:SetText("#{BGTS_220125_41}")
	DressPaint_TB_Info:SetText("#{BGTS_220125_29}")
	DressPaint_TB_DemandPaintItemNumber:SetText("")
	DressPaint_TB_ItemText:SetText("")
	--DressPaint_TB_DemandMoney:SetProperty("MoneyNumber", 0)
end

function DressPaint_TB_BackUIShow()
	if g_Item_Pos < 0 then
		return
	end

	local itemID = PlayerPackage : GetItemTableIndex(g_Item_Pos)
	local lifeTime = OrnamentsScript:GetOrnamentsLifeTime(itemID) 
	local lifeday = math.floor(lifeTime / g_Time_Rate)
	if lifeTime <= -100 then
		DressPaint_TB_Clear()
		return
	end

	if lifeTime <= 0 then
		DressPaint_TB_DemandPaintItemNumber:SetText("#{BGTS_220125_11}")
	else
		local str = ScriptGlobal_Format("#{BGTS_220125_10}", lifeday)
		DressPaint_TB_DemandPaintItemNumber:SetText(str)
	end

	local itemtype, idx, lifetimeex = OrnamentsScript:GetOrnamentsItemInfo(itemID)
	local strName = OrnamentsScript:GetOrnamentsInfo(itemtype, idx, "Name")
	local strNameText = ScriptGlobal_Format("#{BGTS_220125_60}", strName)
	DressPaint_TB_ItemText:SetText(strNameText)
	--DressPaint_TB_DemandMoney:SetProperty("MoneyNumber", g_Need_Money)
end

function DressPaint_TB_HeadUIShow()
	if g_Item_Pos < 0 then
		return
	end

	local itemID = PlayerPackage : GetItemTableIndex(g_Item_Pos)
	local lifeTime = OrnamentsScript:GetOrnamentsLifeTime(itemID) 
	local lifeday = math.floor(lifeTime / g_Time_Rate)
	if lifeTime <= -100 then
		DressPaint_TB_Clear()
		return
	end

	if lifeTime <= 0 then
		DressPaint_TB_DemandPaintItemNumber:SetText("#{BGTS_220125_11}")
	else
		local str = ScriptGlobal_Format("#{BGTS_220125_10}", lifeday)
		DressPaint_TB_DemandPaintItemNumber:SetText(str)
	end

	local itemtype, idx, lifetimeex = OrnamentsScript:GetOrnamentsItemInfo(itemID)
	local strName = OrnamentsScript:GetOrnamentsInfo(itemtype, idx, "Name")
	local strNameText = ScriptGlobal_Format("#{BGTS_220125_60}", strName)
	DressPaint_TB_ItemText:SetText(strNameText)
	--DressPaint_TB_DemandMoney:SetProperty("MoneyNumber", g_Need_Money)
end

function DressPaint_TB_Clear()

	DressPaint_TB_Object:SetActionItem(-1)

	if g_Item_Pos ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos, 0)
		g_Item_Pos = -1	
	end
	
	--DressPaint_TB_Fitting_FakeObject : DetachWindowEx("Ornaments_Player")
	DressPaint_TB_DemandPaintItemNumber:SetText("")
	DressPaint_TB_ItemText:SetText("")
	DressPaint_TB_OK:Disable()
end

function DressPaint_TB_Resume_Equip()
	DressPaint_TB_Init()
	DressPaint_TB_Clear()
	DressPaint_TB_RefreshFakeObj()
end

function DressPaint_TB_StopCareObject()
	this:CareObject(g_objCareID, 0, "DressPaint_TB")
	g_objCareID = -1
end

function DressPaint_TB_BeginCareObject(targetId)
	g_objCareID = DataPool : GetNPCIDByServerID(targetId)
	this:CareObject(g_objCareID, 1, "DressPaint_TB")
end


function DressPaint_TB_UpdateItemAction(Idx)
	if Idx < 0 then
		DressPaint_TB_Clear()
	else
		-- 判定该道具是否可以加入
		local itemID = PlayerPackage : GetItemTableIndex(Idx)
		if itemID < 0 then
			if g_Op_Type == g_eOpType.Back then
				PushDebugMessage("#{BGTS_220125_16}")
			elseif g_Op_Type == g_eOpType.Head then
				PushDebugMessage("#{BGTS_220125_31}")
			end
			return
		end
		-- 是否为正常道具
		local bRet = OrnamentsScript:IsOrnamentsItem(itemID, g_Op_Type)
		if bRet ~= 1 then
			if g_Op_Type == g_eOpType.Back then
				PushDebugMessage("#{BGTS_220125_16}")
			elseif g_Op_Type == g_eOpType.Head then
				PushDebugMessage("#{BGTS_220125_31}")
			end
			return
		end

		local theAction = EnumAction(Idx, "packageitem")
		if theAction:GetID() ~= 0 then
			-- 锁定
			if PlayerPackage:IsLock( Idx ) == 1 then
				PushDebugMessage("#{BGTS_220125_17}")	--道具已上锁
				return
			end
			-- 过期
			--if GuiShiUI:LuaFnMarketIsTimeLifeItem(Idx,1) > 0 then
			--	PushDebugMessage("#{BGTS_220125_18}")	--道具已过期
			--	return
			--end

			if Idx ~= -1 then
				
				if g_Item_Pos ~= -1 then
					LifeAbility : Lock_Packet_Item(g_Item_Pos, 0)
					g_Item_Pos = -1
				end

				g_Item_Pos = Idx
				LifeAbility : Lock_Packet_Item(g_Item_Pos, 1)
			end

			DressPaint_TB_Object:SetActionItem(theAction:GetID())

			if g_Op_Type == g_eOpType.Back then
				DressPaint_TB_BackUIShow()
			elseif g_Op_Type == g_eOpType.Head then
				DressPaint_TB_HeadUIShow()
			end
			-- 显示模型
			--DressPaint_TB_InitFakeObj()
			DressPaint_TB_RefreshFakeObj()
			DressPaint_TB_OK:Enable()
		end

	end
end


function DressPaint_TB_ResetPos()
	DressPaint_TB_Frame:SetProperty("UnifiedPosition", g_DressPaint_TB_Frame_UnifiedPosition)
end

function DressPaint_TB_OnHiden()
	DressPaint_TB_Clear()
	DressPaint_TB_StopCareObject()

	DressPaint_TB_Fitting_FakeObject : DetachWindowEx("Ornaments_Player")

	this:Hide()
end

function DressPaint_TB_OK_Clicked()
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZBSX_130625_62}")
		return
	end

	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end	
	
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{FCMX_90609_22}" )
		return
	end

	if g_Item_Pos < 0 then
		return
	end

	local itemID = PlayerPackage : GetItemTableIndex(g_Item_Pos)
	-- 发送给服务器
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UnlockOrnaments" )
		Set_XSCRIPT_ScriptID( 888961 )
		Set_XSCRIPT_Parameter( 0, g_Item_Pos )
		Set_XSCRIPT_Parameter( 1, itemID )
		Set_XSCRIPT_Parameter( 2, g_Op_Type )
		Set_XSCRIPT_Parameter( 3, 1 )
		Set_XSCRIPT_ParamCount( 4 )
	Send_XSCRIPT()

end

function DressPaint_TB_InitFakeObj()
	DressPaint_TB_Fitting_FakeObject:DetachWindowEx()
	DressPaint_TB_Fitting_FakeObject:AttachWindowEx("Ornaments_Player")
	SetFakeObjDataEx("Ornaments_Player")

	if g_Item_Pos ~= -1 then
		local itemID = PlayerPackage : GetItemTableIndex(g_Item_Pos)
		local itemtype, idx, lifetime = OrnamentsScript:GetOrnamentsItemInfo(itemID)
		if itemidx ~= -100 and itemtype == g_Op_Type then
			OrnamentsScript:UpdateTBOrnamentsID(g_Op_Type, idx)
		end
	end
end

function DressPaint_TB_RefreshFakeObj()
	if g_Item_Pos ~= -1 then
		local itemID = PlayerPackage : GetItemTableIndex(g_Item_Pos)
		local itemtype, idx, lifetime = OrnamentsScript:GetOrnamentsItemInfo(itemID)
		if itemidx ~= -100 and itemtype == g_Op_Type then
			OrnamentsScript:UpdateTBOrnamentsID(g_Op_Type, idx)
		end
	else
		OrnamentsScript:UpdateTBOrnamentsID(g_Op_Type, 0)
	end
end

function DressPaint_TB_Fitting_TurnLeft(idx)
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		DressPaint_TB_Fitting_FakeObject:RotateBeginEx("Ornaments_Player", -0.3)
	else
		DressPaint_TB_Fitting_FakeObject:RotateEndEx()
	end
end

function DressPaint_TB_Fitting_TurnRight(idx)
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		DressPaint_TB_Fitting_FakeObject:RotateBeginEx("Ornaments_Player", 0.3)
	else
		DressPaint_TB_Fitting_FakeObject:RotateEndEx()
	end
end