local TOTALFITTINGKIND_NUM = 10;
local Shop_InfantFitting_DressFitFlag = 0
local Shop_InfantFitting_Selected_Hair = -1

local g_pos = ""
local g_SwitchFlag = 0
local g_Shop_InfantFitting_CurDressID = 0

local Shop_InfantFitting_CameraLevel = 0
local Shop_InfantFitting_CameraPosition =
{
	[0] = {fHeight = 0.7, fDistance = 4,},
	[1] = {fHeight = 0.87, fDistance = 2.75, },
	[2] = {fHeight = 1.04, fDistance = 1.5, }, 
}


function Shop_InfantFitting_PreLoad()
	this:RegisterEvent("DRESS_FIT_PAGE_SWITCH")
	this:RegisterEvent("CLOSE_SHOP_FITTING")
	this:RegisterEvent("OPEN_YB_SHOP_FITTING")
	this:RegisterEvent("OPEN_SHOP_INFANT_FITTING")

	this:RegisterEvent("OPEN_EQUIP")
	this:RegisterEvent("OPEN_SHOP_FITTING")
	this:RegisterEvent("OPEN_DRESS_PAINT_FITTING")
	this:RegisterEvent("OPEN_DRESS_ENCHASE_FITTING")
	this:RegisterEvent("YIGUI_OPEN")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("FASHION_DEPOT_OP", false);				-- 华裳阁
	this:RegisterEvent("FEIYUSHOW_WINDOW", false)
	this:RegisterEvent("OPEN_SPECIALDRESSPAINT", false)
	this:RegisterEvent("RESET_YUANBAO_SHOP_INFANT_FITTING")
end

function Shop_InfantFitting_OnLoad()
	g_pos = Shop_InfantFitting_Frame:GetProperty("UnifiedPosition");
end

function Shop_InfantFitting_OnEvent(event)
	--各种互斥
	if ( event == "OPEN_EQUIP" ) or						-- 角色资料界面
		(event == "OPEN_SHOP_FITTING") or				--普通商店试衣间
		 ( event == "OPEN_DRESS_PAINT_FITTING" ) or		-- 时装染色试衣间
		 ( event == "OPEN_DRESS_ENCHASE_FITTING" ) or	-- 时装镶嵌试衣间
		 ( event == "YIGUI_OPEN") or					-- 衣柜
		 ((event == "UI_COMMAND" and tonumber(arg0) == 20120406)) or --变性
		 (event == "FASHION_DEPOT_OP" and tonumber(arg0) == 1) or --华裳阁 
		 (event == "FEIYUSHOW_WINDOW" and tonumber(arg0) >= 0) or
		 (event == "OPEN_SPECIALDRESSPAINT" and tonumber(arg0) >= 0) then
		if this:IsVisible() then
			this:Hide();
		end
	end

	if event == "DRESS_FIT_PAGE_SWITCH" then
		if tonumber(arg0) and tonumber(arg0) == 1 then
			Shop_InfantFitting_CheckUI()
			Shop_InfantFitting_Frame:SetProperty("UnifiedPosition", arg1)
			Shop_InfantFitting_FakeObject:SetFakeObject( "" )
			this:Show()

			local theAction = EnumAction(0, "fittingitemdress")
			if theAction:GetID() ~= 0 then
				Shop_InfantFitting_DressFitFlag = 1
			else
				Shop_InfantFitting_DressFitFlag = 0
			end

			Shop_InfantFitting_OnUpdate_HairList()
			Shop_InfantFitting_OnUpdate_UI()

			if theAction:GetID() ~= 0 then
				local itemIdx = theAction:GetItemTableIndex()
				local bRet,nInfantDressIdx,nRule,nCost,nVisual = Infant:GetDressConvertInfo(itemIdx)
				if not bRet or bRet ~= 1 then
					PushDebugMessage("#{ZNSZ_140718_168}")
					Shop_InfantFitting_ResetComboList1()
				end
			end
		end
	elseif event == "CLOSE_SHOP_FITTING" then
		this:Hide()
	elseif event == "OPEN_YB_SHOP_FITTING" then
		if this:IsVisible() then
			Shop_InfantFitting_DressFitFlag = 1
			Shop_InfantFitting_OnUpdate_UI()
		end
	elseif event == "OPEN_SHOP_INFANT_FITTING" then
		Shop_InfantFitting_CheckUI()

		if not this:IsVisible() then
			Shop_InfantFitting_Frame:SetProperty("UnifiedPosition", g_pos)
			this:Show()
		end

		Shop_InfantFitting_FakeObject:SetFakeObject( "" )

		if Infant:GetInfantFittingData( 0 ) < 0 then
			Infant:SetInfantFittingData( 0, 0 )
		end

		Shop_InfantFitting_OnUpdate_HairList()
		Shop_InfantFitting_OnUpdate_UI()
	elseif event == "RESET_YUANBAO_SHOP_INFANT_FITTING" then
		Shop_InfantFitting_ResetComboList1()
	end
end

function Shop_InfantFitting_CheckUI()
	if IsWindowShow("Shop_Fitting2") then
		CloseWindow("Shop_Fitting2", true)
	end
	if IsWindowShow("InfantDressCut") then
		CloseWindow("InfantDressCut", true)
	end
	if IsWindowShow("InfantDressPaint") then
		CloseWindow("InfantDressPaint", true)
	end
end

function Shop_InfantFitting_OnUpdate_HairList()
	local MyInfantSex = Shop_InfantFitting_RawSex()
	Shop_InfantFitting_HairList:ClearListBox()
	local nTotal,items = Infant:GetHairData( MyInfantSex, 0, 128 )
	for i=1, nTotal do
		Shop_InfantFitting_HairList:AddItem( items[i][2], i, "FFFFFFFF", 4 )
	end
end

function Shop_InfantFitting_RawObj()
	Shop_InfantFitting_FakeObject:SetFakeObject( "" )
	if Infant:GetInfantCount() < 1 then
		Infant:SetSpecialObjProperty( 1,"CopyFrom","-1")
		Infant:SetSpecialObjProperty( 1, "Sex", tostring( 0 ) )
		Infant:SetSpecialObjProperty( 1, "RaceId", tostring( 16542 ) )
	elseif Infant:GetInfantLevel(0) < 91 then
		Infant:SetSpecialObjProperty( 1,"CopyFrom","-1")
		Infant:SetSpecialObjProperty( 1, "Sex", tostring( 0 ) )
		Infant:SetSpecialObjProperty( 1, "RaceId", tostring( 16542 ) )
	else
		if Infant:GetShowHeroCheck() == 1 then
			Infant:SetSpecialObjProperty( 1,"CopyFrom","-1")
			if Infant:GetInfantSex(0) == 0 then
				Infant:SetSpecialObjProperty( 1, "Sex", tostring( 0 ) )
				Infant:SetSpecialObjProperty( 1, "RaceId", tostring( 16542 ) )
			else
				Infant:SetSpecialObjProperty( 1, "Sex", tostring( 1 ) )
				Infant:SetSpecialObjProperty( 1, "RaceId", tostring( 16543 ) )
			end
		else
			Infant:SetSpecialObjProperty( 1,"CopyFrom","0")
		end
	end

	Infant:SetSpecialObjProperty(1,"Dir","0.0")
	Shop_InfantFitting_FakeObject:SetFakeObject( "Special_Infant_1" )
	
	Shop_InfantFitting_SetCameraPosition()

	FakeObj_RestoreCamera( "Special_Infant_1" )

end

function Shop_InfantFitting_SetCameraPosition()
	if Shop_InfantFitting_CameraLevel > -1 and Shop_InfantFitting_CameraLevel < 3 then
		FakeObj_SetCamera( "Special_Infant_1", 1, Shop_InfantFitting_CameraPosition[Shop_InfantFitting_CameraLevel].fHeight )
		FakeObj_SetCamera( "Special_Infant_1", 2, Shop_InfantFitting_CameraPosition[Shop_InfantFitting_CameraLevel].fDistance )
	end
end

function Shop_InfantFitting_RawSex()
	if Infant:GetInfantCount() < 1 then
		return 0
	elseif Infant:GetInfantLevel(0) < 91 then
		return 0
	else
		return Infant:GetInfantSex(0)
	end
	return 0
end

function Shop_InfantFitting_OnUpdate_UI()
	Shop_InfantFitting_PlayerButton:SetCheck(0)
	Shop_InfantFitting_InfantButton:SetCheck(1)
	Shop_InfantFitting_UpdateZoomButton()

	Shop_InfantFitting_RawObj()
	local MyInfantSex = Shop_InfantFitting_RawSex()

	local theAction = EnumAction(0, "fittingitemdress")
	local itemIdx = theAction:GetItemTableIndex()
	local bRet,nInfantDressIdx,nRule,nCost,nVisual = Infant:GetDressConvertInfo(itemIdx)

	if theAction:GetID() ~= 0 and bRet == 1 then
		if theAction:GetItemColorInFittingRoom(0) ~= "" then
			Shop_InfantFitting_DressInfo_Text:SetText( theAction:GetItemColorInFittingRoom(0)..theAction:GetName() )
		else
			Shop_InfantFitting_DressInfo_Text:SetText( theAction:GetName() )
		end

		Shop_InfantFitting_DressItem:SetActionItem( theAction:GetID() )

		Shop_InfantFitting_DressBuy:Enable()
		Shop_InfantFitting_DressTry:Show()


		local status = CurFittingItemByTypeStatus( 0 )
		if status > 0 then
			Shop_InfantFitting_DressTry:SetText("#{FFSDGZ_120615_02}")
			Shop_InfantFitting_DressIcon:Show()
			Infant:SetSpecialObjProperty( 1, "BodyVisual", tostring( nVisual ) )
			Shop_InfantFitting_DressFitFlag = 1
			Shop_InfantFitting_DressPrint:Show()
	        Shop_InfantFitting_ALLChoice:Show()
		else
			Shop_InfantFitting_DressTry:SetText("#{FFSDGZ_120615_01}")
			Shop_InfantFitting_DressIcon:Hide()
			Shop_InfantFitting_DressFitFlag = 0
			Shop_InfantFitting_DressPrint:Hide()
	        Shop_InfantFitting_ALLChoice:Hide()
			Shop_InfantFitting_ALLChoice_Pic:Hide()
		end

		Shop_InfantFitting_UpdateComboList(theAction:GetItemTableIndex())
		if Shop_InfantFitting_DressFitFlag == 0 then
			Shop_InfantFitting_ALLChoice:Hide()
		end
	else
		Shop_InfantFitting_DressItem:SetActionItem( -1 )
		Shop_InfantFitting_DressInfo_Text:SetText("")
		Shop_InfantFitting_DressTry:Hide()
		Shop_InfantFitting_DressIcon:Hide()
		Shop_InfantFitting_DressBuy:Disable()
		Shop_InfantFitting_DressPrint:Hide()
	    Shop_InfantFitting_ALLChoice:Hide()
		Shop_InfantFitting_ALLChoice_Pic:Hide()

		Shop_InfantFitting_DressFitFlag = 0

	end

	local nSelectedHair = Infant:GetInfantFittingData(0)
	theAction = EnumAction(0, "fittingiteminfanthair")

	if nSelectedHair < 0 then
		Shop_InfantFitting_HairItem:SetActionItem( -1 )
		Shop_InfantFitting_HairItem:SetToolTip( "" )
		Shop_InfantFitting_HairIcon:Hide()
		Shop_InfantFitting_HairTry:SetText("#{FFSDGZ_120615_01}")
		Shop_InfantFitting_HairTry:Hide()
		Shop_InfantFitting_HairInfo_Text:SetText("")
		Shop_InfantFitting_HairBuy:Disable()

	else
		local nCounts,items = Infant:GetHairData( MyInfantSex, nSelectedHair-1, 1 )

		Shop_InfantFitting_HairItem:SetActionItem( theAction:GetID() )

		Shop_InfantFitting_HairIcon:Show()
		Shop_InfantFitting_HairTry:SetText( "#{FFSDGZ_120615_02}" )
		Shop_InfantFitting_HairTry:Show()
		Shop_InfantFitting_HairInfo_Text:SetText( string.format("#G%s",items[1][2]) )
		Shop_InfantFitting_HairBuy:Enable()

		Infant:SetSpecialObjProperty( 1, "HairVisual", tostring( items[1][3] ) )
	end
end

function Shop_InfantFitting_OnHide_Internal()
	Shop_InfantFitting_FakeObject:SetFakeObject( "" )
	Shop_InfantFitting_DressFitFlag = 0
	Shop_InfantFitting_CameraLevel = 0
	if g_SwitchFlag == 0 then
		RestoreShopFitting(TOTALFITTINGKIND_NUM)
		Infant:ClearInfantFittingData()
	else
		g_SwitchFlag = 0
	end
end


function Shop_InfantFitting_Close_Clicked()
	this:Hide()
end

function Shop_InfantFitting_Type_Switch(nPos)
	if nPos == 0 then
		local pos = Shop_InfantFitting_Frame:GetProperty("UnifiedPosition")
		g_SwitchFlag = 1
		PushEvent("DRESS_FIT_PAGE_SWITCH","0",pos)
		return
	end
end

function Shop_InfantFitting_OnModel_Left(start)
	if ( start == 1 and CEArg:GetValue("MouseButton") == "LeftButton" ) then
		Shop_InfantFitting_FakeObject:RotateBegin(-0.3)
	else
		Shop_InfantFitting_FakeObject:RotateEnd()
	end
end

function Shop_InfantFitting_OnModel_Right(start)
	if ( start == 1 and CEArg:GetValue("MouseButton") == "LeftButton" ) then
		Shop_InfantFitting_FakeObject:RotateBegin(0.3)
	else
		Shop_InfantFitting_FakeObject:RotateEnd()
	end
end

function Shop_InfantFitting_OnDressBuy()
	if Shop_InfantFitting_DressItem:GetActionItem() == -1 then
		return
	end
	local theAction = EnumAction(0, "fittingitemdress" )
	if theAction:GetID() == 0  then
		return
	end
	if NpcShop:BuyItemWithOutConfirm() > 0 then
		NpcShop:BuyItemFromFittingRoom( 0, 1 )
	else
		PushEvent( "FITTINGROOM_BUY_ITEM_CONFIRM", "close")
		if theAction:GetID() ~= 0  then
			local nPrice = theAction:GetItemPriceInFittingRoom( 0 )
			local nItemSourceShopUnit = theAction:GetItemSourceShopUnitInFittingRoom( 0 )
			PushEvent( "FITTINGROOM_BUY_ITEM_CONFIRM", "open", 0, theAction:GetName(), nPrice, nItemSourceShopUnit )
		end
	end
end

function Shop_InfantFitting_OnDressView()
	if Shop_InfantFitting_DressFitFlag == 0 then
		Shop_InfantFitting_DressFitFlag = 1
		ReWearFromFittingItem(0)
	else
		Shop_InfantFitting_DressFitFlag = 0
		RestoreShopFitting(0)
	end
	Shop_InfantFitting_OnUpdate_UI()
end

function Shop_InfantFitting_OnHairBuy()
	if Shop_InfantFitting_HairItem:GetActionItem() == -1 then
		return
	end
	local theAction = EnumAction(0, "fittingiteminfanthair" )
	if theAction:GetID() == 0  then
		return
	end
	if NpcShop:BuyItemWithOutConfirm() > 0 then
		NpcShop:BuyItemFromFittingRoom( 5, 1 )
	else
		PushEvent( "FITTINGROOM_BUY_ITEM_CONFIRM", "close")
		if theAction:GetID() ~= 0  then
			local nPrice = theAction:GetItemPriceInFittingRoom( 5 )
			local nItemSourceShopUnit = theAction:GetItemSourceShopUnitInFittingRoom( 5 )
			PushEvent( "FITTINGROOM_BUY_ITEM_CONFIRM", "open", 5, theAction:GetName(), nPrice, nItemSourceShopUnit )
		end
	end
end

function Shop_InfantFitting_OnHairView()
	Shop_InfantFitting_HairList:ClearSelectState()
	Infant:SetInfantFittingData( 0, -1 )
	RestoreShopFitting(5)
	Shop_InfantFitting_OnUpdate_UI()
end

function Shop_InfantFitting_OnSelectHair()

	local theAction = EnumAction(0, "fittingiteminfanthair")
	if theAction:GetID() == 0 then
		PushEvent("FAKE_SWTICH_YUANBAO_SHOP")
	end

	Infant:SetInfantFittingData( 0, Shop_InfantFitting_HairList:GetFirstSelectItem() )
	Shop_InfantFitting_OnUpdate_UI()
end

function Shop_InfantFitting_UpdateComboList(itemindex)
	Shop_InfantFitting_ALLChoice:ResetList();
	g_Shop_InfantFitting_CurDressID=0
--~ 	Shop_InfantFitting_ALLChoice:Show()
	Shop_InfantFitting_ALLChoice:Hide()
	if itemindex <= 0 then
		return
	end

	local _,dressID,_,_,_ = Infant:GetDressConvertInfo(itemindex)

	g_Shop_InfantFitting_CurDressID = dressID

	local tPaintData = Infant:GetInfantDressPaintData( g_Shop_InfantFitting_CurDressID )

	if type(tPaintData) == "table" then
		Shop_InfantFitting_ALLChoice:AddTextItem("#{FTHS_120719_45}", 0)
		for i,v in tPaintData do
			if v[3] > 14000 then
				Shop_InfantFitting_ALLChoice:AddTextItem( ScriptGlobal_Format("#{SZRSYH_120912_07}", v[4] ), i )
			elseif v[3] > 1000 then
				Shop_InfantFitting_ALLChoice:AddTextItem( ScriptGlobal_Format("#{SZRSYH_120912_08}", v[4] ), i )
			elseif v[3] > 0 then
				Shop_InfantFitting_ALLChoice:AddTextItem( ScriptGlobal_Format("#{SZRSYH_120912_09}", v[4] ), i )
			end
		end
		Shop_InfantFitting_DressPrint:SetText("染色风格预览")
		Shop_InfantFitting_ALLChoice_Pic:Hide()
		Shop_InfantFitting_ALLChoice:Show()
		Shop_InfantFitting_ALLChoice:Enable()
	else
		Shop_InfantFitting_ResetComboList()
		if Shop_InfantFitting_DressFitFlag == 0 then
			Shop_InfantFitting_ALLChoice:Hide()
			Shop_InfantFitting_DressPrint:Hide()
		end
--~ 		Shop_InfantFitting_DressPrint:Show()
--~ 		Shop_InfantFitting_DressPrint:SetText("无法染色")
--~ 		Shop_InfantFitting_ALLChoice:Hide()
--~ 		Shop_InfantFitting_ALLChoice_Pic:Show()
--~ 		Shop_InfantFitting_ALLChoice:Disable()
	end

	Shop_InfantFitting_ALLChoice:SetCurrentSelect(0)
	Shop_InfantFitting_FakeObject:SetFakeObject("Special_Infant_1")
end

function Shop_InfantFitting_ComboList_Changed()
	if g_Shop_InfantFitting_CurDressID == 0 then
		return
	end

	local _, Index = Shop_InfantFitting_ALLChoice:GetCurrentSelect()
	if Index > 8 or Index < 0 then
		return
	end

	if Index == 0 then
		local nDefaultVisual = Infant:GetInfantDressVisualById(g_Shop_InfantFitting_CurDressID)
		Infant:SetSpecialObjProperty( 1, "BodyVisual", tostring( nDefaultVisual ) )
		return
	end

	local tPaintData = Infant:GetInfantDressPaintData( g_Shop_InfantFitting_CurDressID )
	if type(tPaintData) ~= "table" then
		return
	end

	local nVisual = tPaintData[Index][2]

	if nVisual <= 0 or nVisual == nil then
		return
	end

	Infant:SetSpecialObjProperty( 1, "BodyVisual", tostring( nVisual ) )
end

function Shop_InfantFitting_ResetComboList()
	Shop_InfantFitting_ALLChoice:ResetList()
	g_Shop_InfantFitting_CurDressID=0
	Shop_InfantFitting_DressPrint:Show()
	Shop_InfantFitting_DressPrint:SetText("染色风格预览")
	Shop_InfantFitting_ALLChoice_Pic:Show()
	Shop_InfantFitting_ALLChoice:Show()
	Shop_InfantFitting_ALLChoice:AddTextItem("无法染色",0)
	Shop_InfantFitting_ALLChoice:SetCurrentSelect(0)
	Shop_InfantFitting_ALLChoice:Disable()
end

function Shop_InfantFitting_ResetComboList1()
	Shop_InfantFitting_ALLChoice:ResetList()
	Shop_InfantFitting_ALLChoice:Hide()
	Shop_InfantFitting_ALLChoice_Pic:Hide()
	Shop_InfantFitting_DressPrint:Hide()
	g_Shop_InfantFitting_CurDressID=0
end

function Shop_InfantFitting_ZoomIn()
	if Shop_InfantFitting_CameraLevel < 0 or Shop_InfantFitting_CameraLevel > 1 then
		return
	end
	
	Shop_InfantFitting_CameraLevel = Shop_InfantFitting_CameraLevel + 1
	
	Shop_InfantFitting_SetCameraPosition()
	Shop_InfantFitting_UpdateZoomButton()
end

function Shop_InfantFitting_ZoomOut()
	if Shop_InfantFitting_CameraLevel < 1 or Shop_InfantFitting_CameraLevel > 2then
		return
	end
	
	Shop_InfantFitting_CameraLevel = Shop_InfantFitting_CameraLevel - 1
	
	Shop_InfantFitting_SetCameraPosition()
	Shop_InfantFitting_UpdateZoomButton()
end

function Shop_InfantFitting_UpdateZoomButton()
	Shop_InfantFitting_Model_ZoomIn:Enable()
	Shop_InfantFitting_Model_ZoomOut:Enable()
	
	Shop_InfantFitting_Model_ZoomIn_Tips:SetToolTip("")
	Shop_InfantFitting_Model_ZoomIn_Tips:Hide()
	Shop_InfantFitting_Model_ZoomOut_Tips:SetToolTip("")
	Shop_InfantFitting_Model_ZoomOut_Tips:Hide()
	
	if Shop_InfantFitting_CameraLevel == 0 then 
		Shop_InfantFitting_Model_ZoomOut:Disable()
		Shop_InfantFitting_Model_ZoomOut_Tips:Show()
		Shop_InfantFitting_Model_ZoomOut_Tips:SetToolTip( "#{YBDYL_150703_03}" );
	elseif Shop_InfantFitting_CameraLevel == 2 then
		Shop_InfantFitting_Model_ZoomIn:Disable()
		Shop_InfantFitting_Model_ZoomIn_Tips:Show()
		Shop_InfantFitting_Model_ZoomIn_Tips:SetToolTip( "#{YBDYL_150703_01}" );
	end
end

