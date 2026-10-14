

local InfantDressJian_CameraHeight = 1		--摄影机高度
local InfantDressJian_CameraDistance = 2	--摄影机距离
local InfantDressJian_CameraPitch = 3		--摄影机角度

local InfantDressJian_g_UnifiedPosition = ""
local InfantDressJian_g_Current_DressId = -1

function InfantDressJian_PreLoad()
	this:RegisterEvent("OPEN_INFANT_DRESS_JIAN")
end

function InfantDressJian_OnLoad()
	InfantDressJian_g_UnifiedPosition = InfantDressJian_Frame:GetProperty("UnifiedPosition")
end

function InfantDressJian_OnEvent( event )
	if event == "OPEN_INFANT_DRESS_JIAN" then
		InfantDressJian_g_Current_DressId = tonumber(arg0)
		
		if InfantDressJian_g_Current_DressId == -1 then
			this:Hide()
		else
			if not this:IsVisible() then
				InfantDressJian_Frame:SetProperty("UnifiedPosition", tostring(InfantDressJian_g_UnifiedPosition) )
				this:Show()
			end
			InfantDressJian_UpdateUI()
		end
	end
end

function InfantDressJian_UpdateUI()
	
	Infant:SetSpecialObjProperty(8,"CopyFrom","0")
	Infant:SetSpecialObjProperty(8,"Dir","0.0")
	
	local nDefaultVisual = Infant:GetInfantDressVisualById(InfantDressJian_g_Current_DressId)
	Infant:SetSpecialObjProperty( 8, "BodyVisual", tostring(nDefaultVisual) )
	
	InfantDressJian_FakeObject:SetFakeObject( "" )
	InfantDressJian_FakeObject:SetFakeObject( "Special_Infant_8" )
	
	FakeObj_SetCamera( "Special_Infant_8", InfantDressJian_CameraHeight, 0.7 )
	FakeObj_SetCamera( "Special_Infant_8", InfantDressJian_CameraDistance, 4 )
	FakeObj_RestoreCamera( "Special_Infant_8" )
	
	InfantDressJian_List:ClearSelectState()
	InfantDressJian_List:ClearListBox()
	
	InfantDressJian_List:AddItem( "#{FTHS_120719_45}", 0 )
	local tDressColor = Infant:GetInfantDressPaintData( InfantDressJian_g_Current_DressId )
	if tDressColor ~= nil then
		for i,v in tDressColor do
			if v[2] > 0 then
				if v[3] > 14000 then
					InfantDressJian_List:AddItem( ScriptGlobal_Format("#W#{SZRSYH_120912_07}", v[4] ), i ) 
				elseif v[3] > 1000 then
					InfantDressJian_List:AddItem( ScriptGlobal_Format("#{SZRSYH_120912_08}", v[4] ), i ) 
				elseif v[3] > 0 then
					InfantDressJian_List:AddItem( ScriptGlobal_Format("#{SZRSYH_120912_09}", v[4] ), i ) 
				end
			end
		end
	end
	
	--InfantDressJian_List:SetFirstSelectItem(0)
end

function InfantDressJian_CloseOnclick()
	this:Hide()
end

function InfantDressJian_OnHide()
	InfantDressJian_FakeObject:SetFakeObject("")
end

function InfantDressJian_OnModelTurnLeft(start)
	if start == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		InfantDressJian_FakeObject:RotateBegin(-0.3)
	else
		InfantDressJian_FakeObject:RotateEnd()
	end
end

function InfantDressJian_OnModelTurnRight(start)
	if start == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		InfantDressJian_FakeObject:RotateBegin(0.3)
	else
		InfantDressJian_FakeObject:RotateEnd()
	end
end

function InfantDressJian_List_Click()
	local typeIdx = InfantDressJian_List:GetFirstSelectItem();
	if typeIdx == 0 then
		local nDefaultVisual = Infant:GetInfantDressVisualById(InfantDressJian_g_Current_DressId)
		Infant:SetSpecialObjProperty( 8, "BodyVisual", tostring(nDefaultVisual) )
		return
	end
	
	local tDressColor = Infant:GetInfantDressPaintData( InfantDressJian_g_Current_DressId )
	if tDressColor[typeIdx] and tDressColor[typeIdx][2] > 0 then
		Infant:SetSpecialObjProperty( 8, "BodyVisual", tostring(tDressColor[typeIdx][2]) )
		return
	end
	
	local nDefaultVisual = Infant:GetInfantDressVisualById(InfantDressJian_g_Current_DressId)
	Infant:SetSpecialObjProperty( 8, "BodyVisual", tostring(nDefaultVisual) )
end