--*********************
--子女时装剪裁界面
--*********************

local InfantDressCut_CameraHeight = 1		--摄影机高度
local InfantDressCut_CameraDistance = 2		--摄影机距离
local InfantDressCut_CameraPitch = 3		--摄影机角度

local InfantDressCut_CaredObjId = -1		--关注ncp的ObjId
local InfantDressCut_TryItemIdx = -1		--选中的背包索引
local InfantDressCut_PaintDressConfirm = 0	--染色时装剪裁的确认标志

local InfantDressCut_NeedItemId = 38001020
local g_InfantDressCut_YuanbaoPay=1
local g_InfantDressCut_g_UnifiedPosition = ""


function InfantDressCut_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("PROGRESSBAR_SHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_WINDOW")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("UPDATE_INFANT_DRESS_CUT")
	this:RegisterEvent("INFANT_DRESS_CUT_CONFIRM_RESULT")
	this:RegisterEvent("OPEN_INFANTDRESSWASH_FENYE1")
	
end

function InfantDressCut_OnLoad()
	g_InfantDressCut_g_UnifiedPosition = InfantDressCut_Frame:GetProperty("UnifiedPosition")
	InfantDressCut_Jian:Hide()
end

function InfantDressCut_OnEvent( event )
	if event == "UI_COMMAND" and tonumber(arg0) == 890985 then
		if( Get_XParam_INT_Count() < 1 ) then
			return
		end
		
		local servid = Get_XParam_INT(0)
		InfantDressCut_CaredObjId = DataPool:GetNPCIDByServerID(servid)
		if InfantDressCut_CaredObjId == -1 then
			return
		end
		this:CareObject( InfantDressCut_CaredObjId, 1, "InfantDressCut" )
		
		if not this:IsVisible() then
			--yuanbaoPay
			if g_InfantDressCut_YuanbaoPay == 1 or g_InfantDressCut_YuanbaoPay == 0 then
				InfantDressCut_Blank_Queren:SetCheck(g_InfantDressCut_YuanbaoPay)
			end
			this:Show()
		end
		
		if IsWindowShow("Shop_InfantFitting") then
			CloseWindow("Shop_InfantFitting", true)
		end
		if IsWindowShow("InfantDressPaint") then
			CloseWindow("InfantDressPaint", true)
		end 
		
		InfantDressCut_FenYe1:SetProperty("Selected", "True")
		InfantDressCut_FenYe2:SetProperty("Selected", "False")
		InfantDressCut_FenYe3:SetProperty("Selected", "False")
		
		InfantDressCut_UIClear()
		InfantDressCut_UpdateMoney()
		InfantDressCut_UpdateInfantModel()
		
	elseif event == "OPEN_INFANTDRESSWASH_FENYE1" then
		
		InfantDressCut_CaredObjId = tonumber(arg0);
		if InfantDressCut_CaredObjId == -1 then
			return
		end
		this:CareObject( InfantDressCut_CaredObjId, 1, "InfantDressCut" )
		
		
		g_InfantDressCut_g_UnifiedPosition = Variable:GetVariable("DressClothPos")
		InfantDressCut_Frame:SetProperty("UnifiedPosition", g_InfantDressCut_g_UnifiedPosition);
		
		if not this:IsVisible() then
			--yuanbaoPay
			if g_InfantDressCut_YuanbaoPay == 1 or g_InfantDressCut_YuanbaoPay == 0 then
				InfantDressCut_Blank_Queren:SetCheck(g_InfantDressCut_YuanbaoPay)
			end
			this:Show()
		end
		
		if IsWindowShow("Shop_InfantFitting") then
			CloseWindow("Shop_InfantFitting", true)
		end
		if IsWindowShow("InfantDressPaint") then
			CloseWindow("InfantDressPaint", true)
		end 
		
		InfantDressCut_FenYe1:SetProperty("Selected", "True")
		InfantDressCut_FenYe2:SetProperty("Selected", "False")
		InfantDressCut_FenYe3:SetProperty("Selected", "False")
		
		InfantDressCut_UIClear()
		InfantDressCut_UpdateMoney()
		InfantDressCut_UpdateInfantModel()
		
	elseif event == "OBJECT_CARED_EVENT" then
		if not this:IsVisible() then
			return
		end
		if tonumber(arg0) ~= InfantDressCut_CaredObjId then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if ( arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE ) or arg1=="destroy" then
			this:Hide()
		end
	elseif event == "PROGRESSBAR_SHOW" then
		if this:IsVisible() then
			this:Hide()
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		
			this:Hide()
	
	elseif event == "MONEY_CHANGE_EX" then
		if this:IsVisible() then
			InfantDressCut_UpdateMoney()
		end
	elseif event == "MONEYJZ_CHANGE_EX" then
		if this:IsVisible() then
			InfantDressCut_UpdateMoney()
		end
	elseif event == "UPDATE_INFANT_DRESS_CUT" then
		if not this:IsVisible() then
			return
		end
		if arg0 ~= nil and arg1 ~= nil then
			InfantDressCut_Update(tonumber(arg0), tonumber(arg1))
		end
	elseif event == "INFANT_DRESS_CUT_CONFIRM_RESULT" then
		if not arg0 or not arg1 then
			return
		end
		local nId = tonumber(arg0)
		if nId == 47 then
			if tonumber(arg1) == 1 then
				InfantDressCut_PaintDressConfirm = 1
			end
		end
	elseif event == "PACKAGE_ITEM_CHANGED_EX" then
		if this:IsVisible() and tonumber(arg0) == InfantDressCut_TryItemIdx then
			InfantDressCut_ReleaseItem()
		end
	end
end

-- 
function InfantDressCut_Blank_Queren_Clicked() 
	g_InfantDressCut_YuanbaoPay = InfantDressCut_Blank_Queren:GetCheck();
end

function InfantDressCut_OnShow()
	
end

function InfantDressCut_Update(Pos, isEquip)
	if not InfantDressCut_TryItemIdx or InfantDressCut_TryItemIdx == -1 then
		InfantDressCut_NeedItem:SetActionItem(-1)
	end
	
	if isEquip == 1 then
		local theAction = EnumAction(Pos, "packageitem")
		if theAction:GetID() ~= 0 then

			local EquipPoint = LifeAbility:Get_Equip_Point(Pos)
			if not EquipPoint or EquipPoint ~= 16 then
				PushDebugMessage("#{ZNSZ_140718_82}")
				return
			end
			
			---[[--
			local itemTableIndex = PlayerPackage:GetItemTableIndex(Pos)
			if not itemTableIndex or itemTableIndex == -1 then
				PushDebugMessage("#{ZNSZ_140718_82}")
				return
			end
			
			local bret,itemdress = Infant:GetDressConvertInfo(itemTableIndex)
			if not bret or bret ~= 1 then
				PushDebugMessage("#{ZNSZ_140718_83}")
				return
			end
			
			local gem0,gem1,gem2
			bret,gem0,gem1,gem2 = DressEnchasing:GetDressGemType(Pos)
			if not bret or bret ~= 1 then
				PushDebugMessage("#{ZNSZ_140718_82}")
				return
			end
			
			if gem0 ~= -1 or gem1 ~= -1 or gem2 ~= -1 then
				PushDebugMessage("#{ZNSZ_140718_84}")
				return
			end
			
			if PlayerPackage:IsLock(Pos) == 1 then
				PushDebugMessage("#{ZNSZ_140718_85}")
				return
			end
			--]]--
			
			if InfantDressCut_TryItemIdx and InfantDressCut_TryItemIdx ~= -1 then
				LifeAbility:Lock_Packet_Item(InfantDressCut_TryItemIdx, 0)
			end
			
			InfantDressCut_TryItemIdx = Pos
			InfantDressCut_PaintDressConfirm = 0
			LifeAbility:Lock_Packet_Item(Pos, 1)
			InfantDressCut_Item:SetActionItem(theAction:GetID())
			
			local action_mat = Infant:UpdateVirtualMaterial( 0, InfantDressCut_NeedItemId )
			if action_mat and action_mat:GetID() ~= 0 then
				InfantDressCut_NeedItem:SetActionItem( action_mat:GetID() )
			end
			
			
			
			local tDressColor = Infant:GetInfantDressPaintData( itemdress )
			if tDressColor ~= nil then
				InfantDressCut_Jian:Show()
				InfantDressCut_Jian:Enable()
			else
				InfantDressCut_Jian:Hide()
				InfantDressCut_Jian:Disable()
			end
			
			--启用确定按钮
			InfantDressCut_OK:Enable()
			--更新花费
			InfantDressCut_UpdateMoney()
			--更新模型
			InfantDressCut_UpdateInfantModel()
		end
	else
		PushDebugMessage("#{SZPR_091023_17}")
	end
end

function InfantDressCut_UpdateInfantModel()
	
	InfantDressCut_FakeObject:SetFakeObject( "" )
	if not this:IsVisible() then
		return
	end
	
	Infant:SetSpecialObjProperty(1,"CopyFrom","0")
	Infant:SetSpecialObjProperty(1,"Dir","0.0")
	--强制成年模式
	local s = Infant:GetInfantSex(0)
	if s == 0 then
		Infant:SetSpecialObjProperty(1,"RaceId","16542")
	else
		Infant:SetSpecialObjProperty(1,"RaceId","16543")
	end
	
	if InfantDressCut_TryItemIdx and InfantDressCut_TryItemIdx ~= -1 then
		local itemTableIndex = PlayerPackage:GetItemTableIndex(InfantDressCut_TryItemIdx)
		local bAdultCanPaint,itemVisualIdx = DressReplaceColor:GetDressVisualIndex(InfantDressCut_TryItemIdx)
		
		if itemTableIndex and itemTableIndex ~= -1 then
			local bret,itemdress,rule,ncost,nvisual = Infant:GetDressConvertInfo(itemTableIndex)
			if bret and bret == 1 then
				local tPaintData = Infant:GetInfantDressPaintData( itemdress )
				if bAdultCanPaint and itemVisualIdx > 0 and itemVisualIdx < 10 and tPaintData then
					for i,v in tPaintData do
						if ( v[1] + 1 ) == ( itemVisualIdx - 1 ) then
							nvisual = v[2]
							break
						end
					end
				end
				Infant:SetSpecialObjProperty(1,"BodyVisual",tostring(nvisual) )
			end
		end
	end
	InfantDressCut_FakeObject:SetFakeObject( "Special_Infant_1" )
	
	FakeObj_SetCamera( "Special_Infant_1", InfantDressCut_CameraHeight, 0.7 )
	FakeObj_SetCamera( "Special_Infant_1", InfantDressCut_CameraDistance, 4 )
	
	FakeObj_RestoreCamera( "Special_Infant_1" )
end

function InfantDressCut_UpdateMoney()
	
	InfantDressCut_Cost:SetProperty("MoneyNumber", 0)
	if InfantDressCut_TryItemIdx and InfantDressCut_TryItemIdx ~= -1 then
		local itemTableIndex = PlayerPackage:GetItemTableIndex(InfantDressCut_TryItemIdx)
		if itemTableIndex and itemTableIndex ~= -1 then
			local bret,itemdress,rule,ncost,nvisual = Infant:GetDressConvertInfo(itemTableIndex)
			if bret and bret == 1 then
				InfantDressCut_Cost:SetProperty("MoneyNumber", ncost )
			end
		end
	end
	
	local playerMoney = Player:GetData("MONEY")
	InfantDressCut_Money:SetProperty("MoneyNumber", playerMoney)
	
	local playerJZ = Player:GetData("MONEY_JZ")
	InfantDressCut_Jiaozi:SetProperty("MoneyNumber", playerJZ)
end

function InfantDressCut_Model_TurnLeft_Handler(start)
	if ( start == 1 and CEArg:GetValue("MouseButton") == "LeftButton" ) then
		InfantDressCut_FakeObject:RotateBegin(-0.3)
	else
		InfantDressCut_FakeObject:RotateEnd()
	end
end

function InfantDressCut_Model_TurnRight_Handler(start)
	if ( start == 1 and CEArg:GetValue("MouseButton") == "LeftButton" ) then
		InfantDressCut_FakeObject:RotateBegin(0.3)
	else
		InfantDressCut_FakeObject:RotateEnd()
	end
end

--关闭调用
function InfantDressCut_Close()
	this:Hide()
end

function InfantDressCut_OnHide()
	InfantDressCut_FakeObject:SetFakeObject("")
	InfantDressCut_StopCare()
	InfantDressCut_UIClear()
	if IsWindowShow("InfantDressJian") then
		CloseWindow("InfantDressJian", true)
	end 
end

function InfantDressCut_OnOk()
	
	---[[--
	if not InfantDressCut_TryItemIdx or InfantDressCut_TryItemIdx == -1 then
		PushDebugMessage("#{ZNSZ_140718_86}")
		return
	end
	
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZNSZ_140718_46}")
		return
	end
	
	local itemTableIndex = PlayerPackage:GetItemTableIndex(InfantDressCut_TryItemIdx)
	if not itemTableIndex or itemTableIndex == -1 then
		PushDebugMessage("#{ZNSZ_140718_86}")
		return
	end
	
	local bret,itemdress,rule,ncost,nvisual = Infant:GetDressConvertInfo(itemTableIndex)
	if not bret or bret ~= 1 then
		PushDebugMessage("#{ZNSZ_140718_83}")
		return 
	end
	
	local playerMoney = Player:GetData("MONEY")
	local playerJZ = Player:GetData("MONEY_JZ")
	if playerJZ + playerMoney < ncost then
		PushDebugMessage("#{ZNSZ_140718_47}")
		return 
	end
	
	--[[
	if DressReplaceColor:DressCanWash( InfantDressCut_TryItemIdx ) == 1 and InfantDressCut_PaintDressConfirm ~= 1 then
		PushEvent( "INFANT_DRESS_CUT_CONFIRM", 47 )
		return
	end
	--]]--
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnJianCai_Impl")
		Set_XSCRIPT_ScriptID(890985)
		Set_XSCRIPT_Parameter(0,InfantDressCut_TryItemIdx)
		Set_XSCRIPT_Parameter(1,g_InfantDressCut_YuanbaoPay)
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	
	--InfantDressCut_ReleaseItem()
end

function InfantDressCut_ReleaseItem()
	InfantDressCut_UIClear()
	InfantDressCut_UpdateMoney()
	InfantDressCut_UpdateInfantModel()
end

function InfantDressCut_StopCare()
	this:CareObject(InfantDressCut_CaredObjId, 0, "InfantDressCut")
	InfantDressCut_CaredObjId = -1
end

function InfantDressCut_UIClear()
	if not InfantDressCut_TryItemIdx or InfantDressCut_TryItemIdx ~= -1 then
		LifeAbility:Lock_Packet_Item(InfantDressCut_TryItemIdx, 0)
  	end
	InfantDressCut_OK:Disable()
	InfantDressCut_Item:SetActionItem(-1)
	InfantDressCut_TryItemIdx = -1
	InfantDressCut_PaintDressConfirm = 0
	InfantDressCut_NeedItem:SetActionItem(-1)
	InfantDressCut_Jian:Disable()
end

function InfantDressCut_OnHiden()
	this:Hide()
end

function InfantDressCut_OnJian()
	if not InfantDressCut_TryItemIdx or InfantDressCut_TryItemIdx == -1 then
		return
	end
	local itemTableIndex = PlayerPackage:GetItemTableIndex(InfantDressCut_TryItemIdx)
	local bret,itemdress = Infant:GetDressConvertInfo(itemTableIndex)
	if bret and bret == 1 then
		PushEvent( "OPEN_INFANT_DRESS_JIAN", itemdress )
	end
end

function InfantDressCut_FenYe3_Clicked()
	--PushDebugMessage("InfantDressCut_FenYe3_Clicked"..InfantDressCut_CaredObjId)
	Variable:SetVariable("DressClothPos", InfantDressCut_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("OPEN_INFANTDRESSWASH_FENYE3", InfantDressCut_CaredObjId);
end

function InfantDressCut_FenYe2_Clicked()
	--PushDebugMessage("InfantDressCut_FenYe2_Clicked"..InfantDressCut_CaredObjId)
	Variable:SetVariable("DressClothPos", InfantDressCut_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("OPEN_INFANTDRESSWASH_FENYE2", InfantDressCut_CaredObjId);
end
