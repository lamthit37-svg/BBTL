

local InfantDressPaint_CameraHeight = 1		--摄影机高度
local InfantDressPaint_CameraDistance = 2		--摄影机距离
local InfantDressPaint_CameraPitch = 3		--摄影机角度

local InfantDressPaint_CaredObjId = -1
local InfantDressPaint_TryItemIdx = -1
local InfantDressPaint_nCost = 50000

local InfantDressPaint_g_AutoPainting_State = 0
local InfantDressPaint_g_AutoPainting_Target = -1
local InfantDressPaint_g_AutoPainting_ServerRet = nil
local InfantDressPaint_g_AutoPainting_timeout = 0
local InfantDressPaint_g_RareConfirm = 0

local InfantDressPaint_g_UnifiedPosition = ""

local InfantDressPaint_g_PaintDataCache = {}

local InfantDressPaint_g_Items = {30503140,38000992}
local InfantDressPaint_g_bConfirmBind = 0
local g_InfantDressPaint_YuanbaoPay=1

function InfantDressPaint_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("UPDATE_INFANT_DRESS_PAINT")
	
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("INFANTDRESSPAINT_BIND_CONFIRM_RESULT")
	this:RegisterEvent("OPEN_INFANTDRESSWASH_FENYE2")
	
end

function InfantDressPaint_OnLoad()
	InfantDressPaint_Time:SetText("")
	InfantDressPaint_g_UnifiedPosition = InfantDressPaint_Frame:GetProperty("UnifiedPosition")
end

function InfantDressPaint_OnEvent( event )
	if event == "UI_COMMAND" and tonumber(arg0) == 8909851 then
		if( Get_XParam_INT_Count() < 1 ) then
			return
		end
		
		InfantDressPaint_g_bConfirmBind = 0
		
		local servid = Get_XParam_INT(0)
		InfantDressPaint_CaredObjId = DataPool:GetNPCIDByServerID(servid)
		if InfantDressPaint_CaredObjId == -1 then
			return
		end
		this:CareObject( InfantDressPaint_CaredObjId, 1, "InfantDressPaint" )
		
		InfantDressPaint_CheckObjWindow()
		
		if not this:IsVisible() then
			--yuanbaoPay
			if g_InfantDressPaint_YuanbaoPay == 1 or g_InfantDressPaint_YuanbaoPay == 0 then
				InfantDressPaint_Blank_Queren:SetCheck(g_InfantDressPaint_YuanbaoPay)
			end
			InfantDressPaint_Frame:SetProperty("UnifiedPosition", tostring(InfantDressPaint_g_UnifiedPosition) )
			this:Show()
		end
		InfantDressPaint_UpdateUI(1)
		
	elseif event == "OPEN_INFANTDRESSWASH_FENYE2" then
		
		InfantDressPaint_g_bConfirmBind = 0
		
		InfantDressPaint_CaredObjId = tonumber(arg0);
		if InfantDressPaint_CaredObjId == -1 then
			return
		end
		this:CareObject( InfantDressPaint_CaredObjId, 1, "InfantDressPaint" )
		
		
		InfantDressPaint_g_UnifiedPosition = Variable:GetVariable("DressClothPos")
		InfantDressPaint_Frame:SetProperty("UnifiedPosition", InfantDressPaint_g_UnifiedPosition);
		
		InfantDressPaint_CheckObjWindow()
		
		if not this:IsVisible() then
			--yuanbaoPay
			if g_InfantDressPaint_YuanbaoPay == 1 or g_InfantDressPaint_YuanbaoPay == 0 then
				InfantDressPaint_Blank_Queren:SetCheck(g_InfantDressPaint_YuanbaoPay)
			end
			InfantDressPaint_Frame:SetProperty("UnifiedPosition", tostring(InfantDressPaint_g_UnifiedPosition) )
			this:Show()
		end
		
		InfantDressPaint_FenYe1:SetProperty("Selected", "False")
		InfantDressPaint_FenYe2:SetProperty("Selected", "True")
		InfantDressPaint_FenYe3:SetProperty("Selected", "False")
		InfantDressPaint_UpdateUI(1)
	elseif event == "UI_COMMAND" and tonumber(arg0) == 8909852 then
		if not this:IsVisible() then
			return
		end
		InfantDressPaint_g_AutoPainting_ServerRet = tonumber( Get_XParam_INT(0) )
	elseif event == "OBJECT_CARED_EVENT" then
		if not this:IsVisible() then
			return
		end
		
		if tonumber(arg0) ~= InfantDressPaint_CaredObjId then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if ( arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE ) or arg1=="destroy" then
			this:Hide()
		end
	elseif event == "UPDATE_INFANT_DRESS_PAINT" then
		if not this:IsVisible() then
			return
		end
		InfantDressPaint_g_bConfirmBind = 0
		if arg0 ~= nil then
			InfantDressPaint_UpdateItem( tonumber(arg0) )
		end
	elseif event == "MONEY_CHANGE_EX" then
		if this:IsVisible() then
			InfantDressPaint_UpdateMoney()
		end
	elseif event == "MONEYJZ_CHANGE_EX" then
		if this:IsVisible() then
			InfantDressPaint_UpdateMoney()
		end
	elseif event == "PACKAGE_ITEM_CHANGED_EX" then
		if this:IsVisible() and tonumber(arg0) == InfantDressPaint_TryItemIdx  then
			InfantDressPaint_g_bConfirmBind = 0
			InfantDressPaint_UpdateItem( tonumber(arg0) )
		end
	elseif event == "INFANTDRESSPAINT_BIND_CONFIRM_RESULT" then
		if this:IsVisible() then
			InfantDressPaint_g_bConfirmBind = tonumber(arg0)
		end
	end
end

-- 
function InfantDressPaint_Blank_Queren_Clicked() 
	g_InfantDressPaint_YuanbaoPay = InfantDressPaint_Blank_Queren:GetCheck();
end

function InfantDressPaint_UpdateItem(Pos)
	InfantDressPaint_g_RareConfirm = 0
	
	local theAction = EnumAction(Pos, "packageitem")
	
	if theAction:GetID() == 0 then
		return
	end
	
	---[[--
	local itemTableIndex = PlayerPackage:GetItemTableIndex(Pos)
	if not itemTableIndex or itemTableIndex == -1 then
		PushDebugMessage("#{ZNSZ_140718_152}")
		return
	end
	
	if PlayerPackage:IsLock(Pos) == 1 then
		PushDebugMessage("#{ZNSZ_140718_85}")
		return
	end
				
	--]]--
	
	if IsWindowShow("InfantDressJian") and InfantDressPaint_TryItemIdx ~= -1 then
		local itemTableIndex = PlayerPackage:GetItemTableIndex(InfantDressPaint_TryItemIdx)
		PushEvent( "OPEN_INFANT_DRESS_JIAN", itemTableIndex )
	end

	if Pos ~= InfantDressPaint_TryItemIdx then
		if InfantDressPaint_TryItemIdx and InfantDressPaint_TryItemIdx ~= -1 then
			LifeAbility:Lock_Packet_Item(InfantDressPaint_TryItemIdx, 0)
		end
		InfantDressPaint_TryItemIdx = Pos
		LifeAbility:Lock_Packet_Item(Pos, 1)
		InfantDressPaint_Item:SetActionItem( theAction:GetID() )
		InfantDressPaint_UpdateUI(1)
	else
		InfantDressPaint_UpdateUI(0)
	end
	
	InfantDressPaint_UpdateModel()
end

function InfantDressPaint_UpdateUI( bchangeitem )

	--更新消耗金钱
	InfantDressPaint_UpdateMoney()
	
	if InfantDressPaint_g_AutoPainting_State == 0 then
		InfantDressPaint_Auto:SetText("#{ZNSZ_140718_138}")
	else
		InfantDressPaint_Auto:SetText("#{ZNSZ_140718_139}")
	end
	
	if InfantDressPaint_TryItemIdx and InfantDressPaint_TryItemIdx ~= -1 then
		if bchangeitem == 1 then
			InfantDressPaint_Auto_Choice:ResetList()
			InfantDressPaint_Auto_Choice:SetText("#{YJRS_140613_03}")
			local nTableIndex = PlayerPackage:GetItemTableIndex(InfantDressPaint_TryItemIdx) 
			local tPaintData = Infant:GetInfantDressPaintData( nTableIndex )
			InfantDressPaint_g_PaintDataCache = {}
			if type(tPaintData) == "table" then
				for i,v in tPaintData do
					InfantDressPaint_g_PaintDataCache[i] = { v[1] + 1, v[2], v[3], v[4]  }
					if v[3] > 14000 then
						InfantDressPaint_Auto_Choice:AddTextItem( ScriptGlobal_Format("#{SZRSYH_120912_07}", v[4] ), i ) 
					elseif v[3] > 1000 then
						InfantDressPaint_Auto_Choice:AddTextItem( ScriptGlobal_Format("#{SZRSYH_120912_08}", v[4] ), i ) 
					elseif v[3] > 0 then
						InfantDressPaint_Auto_Choice:AddTextItem( ScriptGlobal_Format("#{SZRSYH_120912_09}", v[4] ), i ) 
					end
				end
				InfantDressPaint_Auto_Choice:AddTextItem( "#{YJRS_140613_23}" , 99 ) 
			end
			InfantDressPaint_Auto:Disable()
			InfantDressPaint_Auto_Animate:Play(false)
		end
		InfantDressPaint_Auto_Choice:Enable()
		InfantDressPaint_OK:Enable()
		InfantDressPaint_Jian:Enable()
	else
		InfantDressPaint_Auto_Choice:ResetList()
		InfantDressPaint_Auto_Choice:SetText("#{YJRS_140613_03}")
		InfantDressPaint_Auto_Choice:Disable()
		InfantDressPaint_Auto:Disable()
		InfantDressPaint_Auto_Animate:Play(false)
		InfantDressPaint_OK:Disable()
		InfantDressPaint_Jian:Disable()
  	end
	
end

function InfantDressPaint_CheckObjWindow()
	if IsWindowShow("Shop_InfantFitting") then
		CloseWindow("Shop_InfantFitting", true)
	end
	if IsWindowShow("InfantDressCut") then
		CloseWindow("InfantDressCut", true)
	end
end

function InfantDressPaint_ReleaseItem()
	InfantDressPaint_UIClear()
	InfantDressPaint_UpdateMoney()
	InfantDressPaint_UpdateModel()
end

function InfantDressPaint_OnHide()
	
	if InfantDressPaint_g_AutoPainting_State ~= 0 then
		KillTimer("InfantDressPaint_OnTimer()")
		InfantDressPaint_g_AutoPainting_ServerRet = nil
		InfantDressPaint_g_AutoPainting_timeout = 0
		InfantDressPaint_g_AutoPainting_State = 0
		PushDebugMessage("#{ZNSZ_140718_151}")
	end
	
	
	InfantDressPaint_UIClear()
	InfantDressPaint_StopCare()
	InfantDressPaint_UpdateModel()
	
	PushEvent( "OPEN_INFANT_DRESS_JIAN", -1 )
end

function InfantDressPaint_OnHiden()
	this:Hide()
end

function InfantDressPaint_UIClear()
	if InfantDressPaint_TryItemIdx and InfantDressPaint_TryItemIdx ~= -1 then
		LifeAbility:Lock_Packet_Item(InfantDressPaint_TryItemIdx, 0)
  	end
	InfantDressPaint_TryItemIdx = -1
	InfantDressPaint_UpdateUI(1)
	InfantDressPaint_Item:SetActionItem(-1)
end

function InfantDressPaint_StopCare()
	if InfantDressPaint_CaredObjId ~= -1 then
		this:CareObject(InfantDressPaint_CaredObjId, 0, "InfantDressPaint")
		InfantDressPaint_CaredObjId = -1
	end
end

function InfantDressPaint_UpdateMoney()
	InfantDressPaint_Cost:SetProperty("MoneyNumber", 0)
	if InfantDressPaint_TryItemIdx and InfantDressPaint_TryItemIdx ~= -1 then
		InfantDressPaint_Cost:SetProperty("MoneyNumber", InfantDressPaint_nCost )
	end
	
	local playerMoney = Player:GetData("MONEY")
	InfantDressPaint_Money:SetProperty("MoneyNumber", playerMoney)
	
	local playerJZ = Player:GetData("MONEY_JZ")
	InfantDressPaint_Jiaozi:SetProperty("MoneyNumber", playerJZ)
end

function InfantDressPaint_UpdateModel()

	InfantDressPaint_FakeObject:SetFakeObject( "" )
	InfantDressPaint_ColorText:SetText( "" )
	
	if InfantDressPaint_TryItemIdx == -1 then
		return
	end
	
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
	
	local bRet,nVisual,nRare,szDesc = Infant:GetInfantDressVisualByItem(InfantDressPaint_TryItemIdx)
	if bRet == 1 then
		Infant:SetSpecialObjProperty( 1, "BodyVisual", tostring(nVisual) )
		local szDescFinal = ""
		if nRare > 14000 then
			szDescFinal = ScriptGlobal_Format("#{SZRSYH_120912_10}", szDesc )
		elseif nRare > 1000 then
			szDescFinal = ScriptGlobal_Format("#{SZRSYH_120912_11}", szDesc )
		elseif nRare > 0 then
			szDescFinal = ScriptGlobal_Format("#{SZRSYH_120912_12}", szDesc )
		else
			szDescFinal = "#{ZNSZ_140718_171}"
		end
		InfantDressPaint_ColorText:SetText( szDescFinal )
	end
	
	InfantDressPaint_FakeObject:SetFakeObject( "Special_Infant_1" )
	
	FakeObj_SetCamera( "Special_Infant_1", InfantDressPaint_CameraHeight, 0.7 )
	FakeObj_SetCamera( "Special_Infant_1", InfantDressPaint_CameraDistance, 4 )
	
	FakeObj_RestoreCamera( "Special_Infant_1" )
	
end

function InfantDressPaint_Model_TurnLeft_Handler(start)
	if start == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		InfantDressPaint_FakeObject:RotateBegin(-0.3)
	else
		InfantDressPaint_FakeObject:RotateEnd()
	end
end

function InfantDressPaint_Model_TurnRight_Handler(start)
	if start == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		InfantDressPaint_FakeObject:RotateBegin(0.3)
	else
		InfantDressPaint_FakeObject:RotateEnd()
	end
end

function InfantDressPaint_DestMode_Changed()
	if not InfantDressPaint_TryItemIdx or InfantDressPaint_TryItemIdx == -1 then
		return
	end
	
	local _name,_ComIdx = InfantDressPaint_Auto_Choice:GetCurrentSelect()
	local bRet,nVisual,nRare,Style = Infant:GetInfantDressRareByItem(InfantDressPaint_TryItemIdx)
	
	if _ComIdx > 0 and _ComIdx < 99 then
		InfantDressPaint_g_AutoPainting_Target = InfantDressPaint_g_PaintDataCache[_ComIdx][1]
		if InfantDressPaint_g_AutoPainting_Target == nVisual then
			InfantDressPaint_Auto:Disable()
			InfantDressPaint_Auto_Animate:Play(false)
			PushDebugMessage("#{YJRS_140613_18}")
		else
			InfantDressPaint_Auto:Enable()
			InfantDressPaint_Auto_Animate:Play(true)
		end
	elseif _ComIdx == 99 then
		InfantDressPaint_g_AutoPainting_Target = _ComIdx
		if nRare ~= 0 and nRare <= 1000 then 
			InfantDressPaint_Auto:Disable()
			InfantDressPaint_Auto_Animate:Play(false)
			PushDebugMessage("#{YJRS_140613_18}")
		else
			InfantDressPaint_Auto:Enable()
			InfantDressPaint_Auto_Animate:Play(true)
		end
	else
		InfantDressPaint_g_AutoPainting_Target = -1
		InfantDressPaint_Auto:Disable()
		InfantDressPaint_Auto_Animate:Play(false)
	end
end

function InfantDressPaint_OnOk()

	if InfantDressPaint_CheckPaint() == 0 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnDressPaint_Impl")
		Set_XSCRIPT_ScriptID(890985)
		Set_XSCRIPT_Parameter(0,InfantDressPaint_TryItemIdx)
		Set_XSCRIPT_Parameter(1,100)
		Set_XSCRIPT_Parameter(2,g_InfantDressPaint_YuanbaoPay)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	
end

function InfantDressPaint_CheckPaint()

	if InfantDressPaint_g_AutoPainting_State ~= 0 then
		return 0
	end
	
	if InfantDressPaint_TryItemIdx == -1 then
		PushDebugMessage("#{ZNSZ_140718_152}")
		return 0
	end
	
	if PlayerPackage:IsLock(InfantDressPaint_TryItemIdx) == 1 then
		PushDebugMessage("#{ZNSZ_140718_85}")
		return 0
	end
	
	local bRet,nVisual,nRare,Style = Infant:GetInfantDressRareByItem(InfantDressPaint_TryItemIdx)
	if bRet ~= 1 then
		PushDebugMessage("not paintable ")
		return 0
	end
	
	if nRare ~= 0 and nRare <= 1000 and InfantDressPaint_g_RareConfirm == 0 then
		InfantDressPaint_g_RareConfirm = 1
		PushEvent("DRESSPAINT_SELECTSERVER", Style )
		return 0
	end
	
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZNSZ_140718_144}")
		return 0
	end
	
	
	if InfantDressPaint_g_bConfirmBind ~= 1 and PlayerPackage:GetItemBindStatusByIndex(InfantDressPaint_TryItemIdx) ~= 1 then
		local havebind = 0
		for i=0,29 do
			for _,itemid in InfantDressPaint_g_Items do
				if PlayerPackage:GetItemTableIndex(i) == itemid and PlayerPackage:GetItemBindStatusByIndex(i) == 1 then
					havebind = 1
					break
				end
			end
		end
		
		if havebind == 1 then
			PushEvent("INFANTDRESSPAINT_BIND_CONFIRM")
			return 0
		end
	end

	local playerMoney = Player:GetData("MONEY")
	local playerJZ = Player:GetData("MONEY_JZ")
	if playerJZ + playerMoney < InfantDressPaint_nCost then
		PushDebugMessage("#{ZNSZ_140718_155}")
		return 0
	end
	
	return 1
end

function InfantDressPaint_OnTimer()
	
	--超时了。。。搞毛啊
	if InfantDressPaint_g_AutoPainting_timeout >= 20 then
		KillTimer("InfantDressPaint_OnTimer()")
		InfantDressPaint_g_AutoPainting_ServerRet = nil
		InfantDressPaint_g_AutoPainting_timeout = 0
		InfantDressPaint_g_AutoPainting_State = 0
		InfantDressPaint_Auto:SetText("#{ZNSZ_140718_138}")
		return
	end
	
	--服务器尚未返回结果
	if InfantDressPaint_g_AutoPainting_ServerRet == nil then
		InfantDressPaint_g_AutoPainting_timeout = InfantDressPaint_g_AutoPainting_timeout + 1
		return
	end
	
	--条件不满足，被终止了。。
	if InfantDressPaint_g_AutoPainting_ServerRet < 0 then
		KillTimer("InfantDressPaint_OnTimer()")

		if InfantDressPaint_g_AutoPainting_ServerRet == -2 then
			PushDebugMessage("#{ZNSZ_140718_149}")
		elseif InfantDressPaint_g_AutoPainting_ServerRet == -3 then
			PushDebugMessage("#{ZNSZ_140718_148}")
		end
		
		InfantDressPaint_g_AutoPainting_ServerRet = nil
		InfantDressPaint_g_AutoPainting_timeout = 0
		InfantDressPaint_g_AutoPainting_State = 0
		InfantDressPaint_Auto:SetText("#{ZNSZ_140718_138}")
		
		return
	end
	
	--roll到了目标颜色
	if InfantDressPaint_g_AutoPainting_Target == InfantDressPaint_g_AutoPainting_ServerRet then
		KillTimer("InfantDressPaint_OnTimer()")
		InfantDressPaint_g_AutoPainting_ServerRet = nil
		InfantDressPaint_g_AutoPainting_timeout = 0
		InfantDressPaint_g_AutoPainting_State = 0
		InfantDressPaint_Auto:SetText("#{ZNSZ_140718_138}")
		InfantDressPaint_Auto:Disable()
		InfantDressPaint_Auto_Animate:Play(false)
		return
	end
	
	InfantDressPaint_g_AutoPainting_ServerRet = nil
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnDressPaint_Impl")
		Set_XSCRIPT_ScriptID(890985)
		Set_XSCRIPT_Parameter(0,InfantDressPaint_TryItemIdx)
		Set_XSCRIPT_Parameter(1, InfantDressPaint_g_AutoPainting_Target + 100 )
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
end

function InfantDressPaint_OnAuto()
	if InfantDressPaint_g_AutoPainting_State == 0 then
		if InfantDressPaint_CheckPaint() == 0 then
			return
		end
		InfantDressPaint_Auto:SetText("#{ZNSZ_140718_139}")
		InfantDressPaint_g_AutoPainting_ServerRet = 0
		InfantDressPaint_g_AutoPainting_timeout = 0
		InfantDressPaint_g_AutoPainting_State = 1
		SetTimer("InfantDressPaint","InfantDressPaint_OnTimer()", 300)
	else
		KillTimer("InfantDressPaint_OnTimer()")
		InfantDressPaint_g_AutoPainting_ServerRet = nil
		InfantDressPaint_g_AutoPainting_timeout = 0
		InfantDressPaint_g_AutoPainting_State = 0
		InfantDressPaint_Auto:SetText("#{ZNSZ_140718_138}")
		
		PushDebugMessage("#{ZNSZ_140718_151}")
	end
end

function InfantDressPaint_OnJian()
	if not InfantDressPaint_TryItemIdx or InfantDressPaint_TryItemIdx == -1 then
		return
	end
	
	local itemTableIndex = PlayerPackage:GetItemTableIndex(InfantDressPaint_TryItemIdx)
	
	PushEvent( "OPEN_INFANT_DRESS_JIAN", itemTableIndex )
	
end

function InfantDressPaint_FenYe3_Clicked()
	--PushDebugMessage("InfantDressPaint_FenYe3_Clicked"..InfantDressPaint_CaredObjId)
	Variable:SetVariable("DressClothPos", InfantDressPaint_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("OPEN_INFANTDRESSWASH_FENYE3", InfantDressPaint_CaredObjId);
end

function InfantDressPaint_FenYe1_Clicked()
	--PushDebugMessage("InfantDressPaint_FenYe1_Clicked"..InfantDressPaint_CaredObjId)
	Variable:SetVariable("DressClothPos", InfantDressPaint_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("OPEN_INFANTDRESSWASH_FENYE1", InfantDressPaint_CaredObjId);
end
