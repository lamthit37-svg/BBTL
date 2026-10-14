-- InfantSelectHairColor.lua
-- !!!reloadscript =InfantSelectHairColor
--*********************
--子女选择染发颜色界面
--*********************

local InfantSelectHairColor_CameraHeight = 1		--摄影机高度
local InfantSelectHairColor_CameraDistance = 2		--摄影机距离
local InfantSelectHairColor_CameraPitch = 3			--摄影机角度

local InfantSelectHairColor_CaredObjId = -1		--关注ncp的ObjId

local g_update_type = -1
local g_InfantSelectHairColor_YuanbaoPay=1

local g_InfantSelectHairColor_SelectIndex = 0
local g_InfantSelectHairColor_MaxNum = 20
local g_InfantSelectHairColor_Array = {}

local g_InfantSelectHairColor_CameraLevel = 0
local g_InfantSelectHairColor_CameraPosition =
{
	[0] = {fHeight = 1.09, fDistance = 1.30, },
	[1] = {fHeight = 0.90, fDistance = 2.30, },
	[2] = {fHeight = 0.63, fDistance = 3.30, }, 
}

function InfantSelectHairColor_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("PROGRESSBAR_SHOW")
	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_WINDOW")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("REFRESH_INFANT_HAIRCOLOR",false)
	
end

function InfantSelectHairColor_OnLoad()
	InfantSelectHairColor_Red:SetProperty( "DocumentSize","1" );
	InfantSelectHairColor_Red:SetProperty( "PageSize","0.1" );
	InfantSelectHairColor_Red:SetProperty( "StepSize","0.1" );
	
	InfantSelectHairColor_Green:SetProperty( "DocumentSize","1" );
	InfantSelectHairColor_Green:SetProperty( "PageSize","0.1" );
	InfantSelectHairColor_Green:SetProperty( "StepSize","0.1" );
	
	InfantSelectHairColor_Blue:SetProperty( "DocumentSize","1" );
	InfantSelectHairColor_Blue:SetProperty( "PageSize","0.1" );
	InfantSelectHairColor_Blue:SetProperty( "StepSize","0.1" );
	
	InfantSelectHairColor_Bright:SetProperty( "DocumentSize","1" );
	InfantSelectHairColor_Bright:SetProperty( "PageSize","0.1" );
	InfantSelectHairColor_Bright:SetProperty( "StepSize","0.1" );

	g_InfantSelectHairColor_Array = {
		{uiItem = InfantSelectHairColor_Item_One, uiIcon = InfantSelectHairColor_OneIcon, uiLock = InfantSelectHairColor_ItemLock1, uiDef = InfantSelectHairColor_SuperListItemActionDef1, uiView = InfantSelectHairColor_SuperListItemActionTry1},
		{uiItem = InfantSelectHairColor_Item_Two, uiIcon = InfantSelectHairColor_TwoIcon, uiLock = InfantSelectHairColor_ItemLock2, uiDef = InfantSelectHairColor_SuperListItemActionDef2, uiView = InfantSelectHairColor_SuperListItemActionTry2},
		{uiItem = InfantSelectHairColor_Item_Three, uiIcon = InfantSelectHairColor_ThreeIcon, uiLock = InfantSelectHairColor_ItemLock3, uiDef = InfantSelectHairColor_SuperListItemActionDef3, uiView = InfantSelectHairColor_SuperListItemActionTry3},
		{uiItem = InfantSelectHairColor_Item_Four, uiIcon = InfantSelectHairColor_FourIcon, uiLock = InfantSelectHairColor_ItemLock4, uiDef = InfantSelectHairColor_SuperListItemActionDef4, uiView = InfantSelectHairColor_SuperListItemActionTry4},
		{uiItem = InfantSelectHairColor_Item_Five, uiIcon = InfantSelectHairColor_FiveIcon, uiLock = InfantSelectHairColor_ItemLock5, uiDef = InfantSelectHairColor_SuperListItemActionDef5, uiView = InfantSelectHairColor_SuperListItemActionTry5},
		{uiItem = InfantSelectHairColor_Item_Six, uiIcon = InfantSelectHairColor_SixIcon, uiLock = InfantSelectHairColor_ItemLock6, uiDef = InfantSelectHairColor_SuperListItemActionDef6, uiView = InfantSelectHairColor_SuperListItemActionTry6},
		{uiItem = InfantSelectHairColor_Item_Seven, uiIcon = InfantSelectHairColor_SevenIcon, uiLock = InfantSelectHairColor_ItemLock7, uiDef = InfantSelectHairColor_SuperListItemActionDef7, uiView = InfantSelectHairColor_SuperListItemActionTry7},
		{uiItem = InfantSelectHairColor_Item_Eight, uiIcon = InfantSelectHairColor_EightIcon, uiLock = InfantSelectHairColor_ItemLock8, uiDef = InfantSelectHairColor_SuperListItemActionDef8, uiView = InfantSelectHairColor_SuperListItemActionTry8},
		{uiItem = InfantSelectHairColor_Item_Nine, uiIcon = InfantSelectHairColor_NineIcon, uiLock = InfantSelectHairColor_ItemLock9, uiDef = InfantSelectHairColor_SuperListItemActionDef9, uiView = InfantSelectHairColor_SuperListItemActionTry9},
		{uiItem = InfantSelectHairColor_Item_Ten, uiIcon = InfantSelectHairColor_TenIcon, uiLock = InfantSelectHairColor_ItemLock10, uiDef = InfantSelectHairColor_SuperListItemActionDef10, uiView = InfantSelectHairColor_SuperListItemActionTry10},
		{uiItem = InfantSelectHairColor_Item_Eleven, uiIcon = InfantSelectHairColor_ElevenIcon, uiLock = InfantSelectHairColor_ItemLock11, uiDef = InfantSelectHairColor_SuperListItemActionDef11, uiView = InfantSelectHairColor_SuperListItemActionTry11},
		{uiItem = InfantSelectHairColor_Item_Twelve, uiIcon = InfantSelectHairColor_TwelveIcon, uiLock = InfantSelectHairColor_ItemLock12, uiDef = InfantSelectHairColor_SuperListItemActionDef12, uiView = InfantSelectHairColor_SuperListItemActionTry12},
		{uiItem = InfantSelectHairColor_Item_Thirteen, uiIcon = InfantSelectHairColor_ThirteenIcon, uiLock = InfantSelectHairColor_ItemLock13, uiDef = InfantSelectHairColor_SuperListItemActionDef13, uiView = InfantSelectHairColor_SuperListItemActionTry13},
		{uiItem = InfantSelectHairColor_Item_Fourteen, uiIcon = InfantSelectHairColor_FourteenIcon, uiLock = InfantSelectHairColor_ItemLock14, uiDef = InfantSelectHairColor_SuperListItemActionDef14, uiView = InfantSelectHairColor_SuperListItemActionTry14},
		{uiItem = InfantSelectHairColor_Item_Fifteen, uiIcon = InfantSelectHairColor_FifteenIcon, uiLock = InfantSelectHairColor_ItemLock15, uiDef = InfantSelectHairColor_SuperListItemActionDef15, uiView = InfantSelectHairColor_SuperListItemActionTry15},
		{uiItem = InfantSelectHairColor_Item_Sixteen, uiIcon = InfantSelectHairColor_SixteenIcon, uiLock = InfantSelectHairColor_ItemLock16, uiDef = InfantSelectHairColor_SuperListItemActionDef16, uiView = InfantSelectHairColor_SuperListItemActionTry16},
		{uiItem = InfantSelectHairColor_Item_Seventeen, uiIcon = InfantSelectHairColor_SeventeenIcon, uiLock = InfantSelectHairColor_ItemLock17, uiDef = InfantSelectHairColor_SuperListItemActionDef17, uiView = InfantSelectHairColor_SuperListItemActionTry17},
		{uiItem = InfantSelectHairColor_Item_Eighteen, uiIcon = InfantSelectHairColor_EighteenIcon, uiLock = InfantSelectHairColor_ItemLock18, uiDef = InfantSelectHairColor_SuperListItemActionDef18, uiView = InfantSelectHairColor_SuperListItemActionTry18},
		{uiItem = InfantSelectHairColor_Item_Nineteen, uiIcon = InfantSelectHairColor_NineteenIcon, uiLock = InfantSelectHairColor_ItemLock19, uiDef = InfantSelectHairColor_SuperListItemActionDef19, uiView = InfantSelectHairColor_SuperListItemActionTry19},
		{uiItem = InfantSelectHairColor_Item_Twenty, uiIcon = InfantSelectHairColor_TwentyIcon, uiLock = InfantSelectHairColor_ItemLock20, uiDef = InfantSelectHairColor_SuperListItemActionDef20, uiView = InfantSelectHairColor_SuperListItemActionTry20},
	}
end

function InfantSelectHairColor_OnEvent( event )
	if event == "UI_COMMAND" and tonumber(arg0) == 890986 then
		if( Get_XParam_INT_Count() < 1 ) then
			return
		end
		
		local servid = Get_XParam_INT(0)
		if servid == -1 then
			InfantSelectHairColor_OnHiden()
			return
		end
		
		InfantSelectHairColor_CaredObjId = DataPool:GetNPCIDByServerID(servid)
		if InfantSelectHairColor_CaredObjId == -1 then
			return
		end
		this:CareObject( InfantSelectHairColor_CaredObjId, 1, "InfantSelectHairColor" )
		
		if not this:IsVisible() then
			--yuanbaoPay
			if g_InfantSelectHairColor_YuanbaoPay == 1 or g_InfantSelectHairColor_YuanbaoPay == 0 then
				InfantSelectHairColor_Blank_Queren:SetCheck(g_InfantSelectHairColor_YuanbaoPay)
			end
			InfantSelectHairColor_OnShow()
		end
		
		if IsWindowShow("InfantSelectHairStyle") then
			CloseWindow("InfantSelectHairStyle", true)
		end
		InfantSelectHairColor_Update()
		
	elseif event == "OBJECT_CARED_EVENT" then
		if not this:IsVisible() then
			return
		end
		if tonumber(arg0) ~= InfantSelectHairColor_CaredObjId then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if ( arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE ) or arg1=="destroy" then
			InfantSelectHairColor_OnHiden()
		end
	elseif event == "REFRESH_INFANT_HAIRCOLOR" and tonumber(arg0) == 1 then
		InfantSelectHairColor_InitAllColor()
	end
end

-- 
function InfantSelectHairColor_OnShow() 
	g_InfantSelectHairColor_SelectIndex = -1
	g_InfantSelectHairColor_CameraLevel = 0
	InfantSelectHairColor_InitAllColor()
	InfantSelectHairColor_SetCameraPosition()
	InfantSelectHairColor_UpdateZoomButton()
	this:Show()
end
function InfantSelectHairColor_Blank_Queren_Clicked() 
	g_InfantSelectHairColor_YuanbaoPay = InfantSelectHairColor_Blank_Queren:GetCheck();
end

function InfantSelectHairColor_OnOk()
	
	local r,g,b = Infant:GetInfantHairColorRGBA(0)
	
	local nr = tonumber( InfantSelectHairColor_Red_Num:GetText() )
	if not nr or nr > 200 then
		return
	end
	
	local ng = tonumber( InfantSelectHairColor_Green_Num:GetText() )
	if not ng or ng > 200 then
		return
	end
	
	local nb = tonumber( InfantSelectHairColor_Blue_Num:GetText() )
	if not nb or nb > 200 then
		return
	end
	
	
	if nr == r and ng == g and nb == b then
		PushDebugMessage("#{ZNSZ_140718_65}")
		return
	end
	
	local bright = InfantSelectHairColor_Bright_Num:GetText()
	if not tonumber(bright) or tonumber(bright) > 126 then
		PushDebugMessage("#{ZNSZ_140718_66}")
		return
	end
	
	local nMoney = Player:GetData("MONEY")
	local nMoneyJZ = Player:GetData("MONEY_JZ")
	if nMoney + nMoneyJZ < 50000 then
		PushDebugMessage("#{ZNSZ_140718_47}")
		return
	end
	
	local Ogre_Color = Infant:MakeRGBAData(nr, ng, nb, 255)
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnAddInfantHairColor")
		Set_XSCRIPT_ScriptID(890986)
		Set_XSCRIPT_Parameter(0,Ogre_Color)
		Set_XSCRIPT_Parameter(1,g_InfantSelectHairColor_YuanbaoPay)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function InfantSelectHairColor_OnHiden()
	InfantSelectHairColor_Model:SetFakeObject("")
	this:Hide()
end

function InfantSelectHairColor_InitAllColor()
	local nCount, nMaxCount = Exterior:LuaFnGetChildHairColorCount()
	-- PushDebugMessage("InfantSelectHairColor_InitAllColor:"..nCount..":"..nMaxCount)
	for i=0,g_InfantSelectHairColor_MaxNum-1 do 
		g_InfantSelectHairColor_Array[i+1].uiLock:Hide()
		g_InfantSelectHairColor_Array[i+1].uiDef:Hide()
		g_InfantSelectHairColor_Array[i+1].uiView:Hide()

		if i < nCount then 
			local r,g,b,a = Exterior:LuaFnEnumChildHairColor(i)
			local imageColor = string.format("%02X%02X%02X%02X", 255, r, g, b)
			g_InfantSelectHairColor_Array[i+1].uiIcon:SetImageColor(imageColor)
			if i == Exterior:LuaFnGetChildExteriorInUse("HAIRCOLOR") then
				g_InfantSelectHairColor_Array[i+1].uiItem:SetPushed(1)
				g_InfantSelectHairColor_Array[i+1].uiDef:Show()
				g_InfantSelectHairColor_SelectIndex = i
			else
				g_InfantSelectHairColor_Array[i+1].uiItem:SetPushed(0)
			end
		else
			g_InfantSelectHairColor_Array[i+1].uiIcon:SetImageColor("00FFFFFF")
			g_InfantSelectHairColor_Array[i+1].uiLock:Show()
		end

	end
end

function InfantSelectHairColor_Update()

	local r,g,b = Infant:GetInfantHairColorRGBA(0)
	InfantSelectHairColor_Red_Num:SetText( r )
	InfantSelectHairColor_Green_Num:SetText( g )
	InfantSelectHairColor_Blue_Num:SetText( b )
	
	InfantSelectHairColor_Model:SetFakeObject("")
	Infant:SetSpecialObjProperty(7,"CopyFrom","0")
	Infant:SetSpecialObjProperty(7,"Dir","0.0")
	
	--强制成年模式
	local s = Infant:GetInfantSex(0)
	if s == 0 then
		Infant:SetSpecialObjProperty(7,"RaceId","16542")
	else
		Infant:SetSpecialObjProperty(7,"RaceId","16543")
	end
	
	InfantSelectHairColor_Model:SetFakeObject( "Special_Infant_7" )
	
	FakeObj_SetCamera( "Special_Infant_7", InfantSelectHairColor_CameraHeight, 1.09 )
	FakeObj_SetCamera( "Special_Infant_7", InfantSelectHairColor_CameraDistance, 1.30 )
	
	FakeObj_RestoreCamera( "Special_Infant_7" )
end

function InfantSelectHairColor_Text_Changed(mode)

	if g_update_type == -1 then
		g_update_type = 1
	else
		return
	end
	
	local nRed = tonumber( InfantSelectHairColor_Red_Num:GetText() )
	if not nRed then
		nRed = 0
	elseif nRed > 200 then
		nRed = 200
	end
		
	local nGreen = tonumber( InfantSelectHairColor_Green_Num:GetText() )
	if not nGreen then
		nGreen = 0
	elseif nGreen > 200 then
		nGreen = 200
	end
	
	local nBlue = tonumber( InfantSelectHairColor_Blue_Num:GetText() )
	if not nBlue then
		nBlue = 0
	elseif nBlue > 200 then
		nBlue = 200
	end
	
	if mode == 0 then
		InfantSelectHairColor_Red:SetPosition( nRed / 200 )
		InfantSelectHairColor_Red_Num:SetText( nRed )
		
		InfantSelectHairColor_Green:SetPosition( nGreen / 200 )
		InfantSelectHairColor_Green_Num:SetText( nGreen )
		
		InfantSelectHairColor_Blue:SetPosition( nBlue / 200 )
		InfantSelectHairColor_Blue_Num:SetText( nBlue )
		
		local Lumination = Infant:GetHairColorBright(nRed,nGreen,nBlue,255)
		InfantSelectHairColor_Bright_Num:SetText(Lumination)
		InfantSelectHairColor_Bright:SetPosition(Lumination / 240)
		
	elseif mode == 1 then
		local Lumination = tonumber( InfantSelectHairColor_Bright_Num:GetText() )
		if not Lumination then
			Lumination = 0
		end
		
		nRed, nGreen, nBlue = Infant:SetHairColorBright(nRed,nGreen,nBlue,255,Lumination)
		if nRed > 200 then
			nRed = 200
		end
		
		if nGreen > 200 then
			nGreen = 200
		end
		
		if nBlue > 200 then
			nBlue = 200
		end
		
		InfantSelectHairColor_Red:SetPosition( nRed / 200 )
		InfantSelectHairColor_Red_Num:SetText( nRed )
		
		InfantSelectHairColor_Green:SetPosition( nGreen / 200 )
		InfantSelectHairColor_Green_Num:SetText( nGreen )
		
		InfantSelectHairColor_Blue:SetPosition( nBlue / 200 )
		InfantSelectHairColor_Blue_Num:SetText( nBlue )
		
		InfantSelectHairColor_Bright:SetPosition(Lumination / 240)
	end
	
	local nRgb = math.floor(nRed,1) * 65536 + math.floor(nGreen,1) * 256 + math.floor(nBlue,1)
	Infant:SetSpecialObjProperty( 7, "HairColor", tostring( nRgb ) )
	Infant:SetFittingProperty( "HairColor", tostring( nRgb ) )
	g_update_type = -1
	--]]--
end

function InfantSelectHairColor_Text_Lost(mode)
	
end

function InfantSelectHairColor_Slider_Changed(mode)

	if g_update_type == -1 then
		g_update_type = 0
	else
		return
	end
	
	local nRed = InfantSelectHairColor_Red:GetPosition() * 200
	local nGreen = InfantSelectHairColor_Green:GetPosition() * 200
	local nBlue = InfantSelectHairColor_Blue:GetPosition() * 200
	
	if mode == 0 then
		InfantSelectHairColor_Red_Num:SetText( nRed )
		InfantSelectHairColor_Green_Num:SetText( nGreen )	
		InfantSelectHairColor_Blue_Num:SetText( nBlue )
		
		local Lumination = Infant:GetHairColorBright(nRed,nGreen,nBlue,255)
		InfantSelectHairColor_Bright_Num:SetText(Lumination)
		InfantSelectHairColor_Bright:SetPosition(Lumination / 240)
		
	elseif mode == 1 then
		local Lumination = InfantSelectHairColor_Bright:GetPosition() * 240
		
		nRed, nGreen, nBlue = Infant:SetHairColorBright(nRed,nGreen,nBlue,255,Lumination)
		if nRed > 200 then
			nRed = 200
		end
		
		if nGreen > 200 then
			nGreen = 200
		end
		
		if nBlue > 200 then
			nBlue = 200
		end
		
		InfantSelectHairColor_Red:SetPosition( nRed / 200 )
		InfantSelectHairColor_Red_Num:SetText( nRed )
		
		InfantSelectHairColor_Green:SetPosition( nGreen / 200 )
		InfantSelectHairColor_Green_Num:SetText( nGreen )
		
		InfantSelectHairColor_Blue:SetPosition( nBlue / 200 )
		InfantSelectHairColor_Blue_Num:SetText( nBlue )
		
		InfantSelectHairColor_Bright_Num:SetText( Lumination )
	end
	
	local nRgb = math.floor(nRed,1) * 65536 + math.floor(nGreen,1) * 256 + math.floor(nBlue,1)
	Infant:SetSpecialObjProperty( 7, "HairColor", tostring( nRgb ) )
	Infant:SetFittingProperty( "HairColor", tostring( nRgb ) )
	
	g_update_type = -1
	--]]--
end

function InfantSelectHairColor_Model_OnLeft(start)

	local mouse_button = CEArg:GetValue("MouseButton")
	if mouse_button == "LeftButton" then
		--向左旋转开始
		if(start == 1) then
			InfantSelectHairColor_Model:RotateBegin(-0.3)
		--向左旋转结束
		else
			InfantSelectHairColor_Model:RotateEnd()
		end
	end
end

function InfantSelectHairColor_Model_OnRight(start)
	
	local mouse_button = CEArg:GetValue("MouseButton")
	if mouse_button == "LeftButton" then
		--向右旋转开始
		if(start == 1) then
			InfantSelectHairColor_Model:RotateBegin(0.3)
		--向右旋转结束
		else
			InfantSelectHairColor_Model:RotateEnd()
		end
	end
end

function InfantSelectHairColor_OnHiden_Internel()
	Infant:ClearFittingProperty()
	InfantSelectHairColor_Model:SetFakeObject("")
	if InfantSelectHairColor_CaredObjId ~= -1 then
		this:CareObject(InfantSelectHairColor_CaredObjId, 0, "InfantSelectHairColor")
		InfantSelectHairColor_CaredObjId = -1
	end
end

function InfantSelectHairColor_GXHClicked(nIndex)
	nIndex = nIndex - 1
	local nCount, nMaxCount = Exterior:LuaFnGetChildHairColorCount()
	-- PushDebugMessage("InfantSelectHairColor_GXHClicked:"..nIndex..":"..nCount)
	if nIndex >= nCount then 
		return
	end
	for i=1,g_InfantSelectHairColor_MaxNum do
		g_InfantSelectHairColor_Array[i].uiItem:SetPushed(0)
		g_InfantSelectHairColor_Array[i].uiView:Hide()
	end
	g_InfantSelectHairColor_SelectIndex = nIndex
	g_InfantSelectHairColor_Array[nIndex+1].uiItem:SetPushed(1)
	if nIndex ~= Exterior:LuaFnGetChildExteriorInUse("HAIRCOLOR") then
		g_InfantSelectHairColor_Array[nIndex+1].uiView:Show()
	end
	local nRed,nGreen,nBlue,nAlpha = Exterior:LuaFnEnumChildHairColor(g_InfantSelectHairColor_SelectIndex)
	local nRgb = math.floor(nRed,1) * 65536 + math.floor(nGreen,1) * 256 + math.floor(nBlue,1)
	Infant:SetSpecialObjProperty( 7, "HairColor", tostring( nRgb ) )
	Infant:SetFittingProperty( "HairColor", tostring( nRgb ) )

	local Lumination = Infant:GetHairColorBright(nRed,nGreen,nBlue,255)
	InfantSelectHairColor_Bright_Num:SetText( Lumination )

	InfantSelectHairColor_Red_Num:SetText( nRed )
	InfantSelectHairColor_Green_Num:SetText( nGreen )
	InfantSelectHairColor_Blue_Num:SetText( nBlue )
end
function InfantSelectHairColor_GXHChange()
	local nCount, nMaxCount = Exterior:LuaFnGetChildHairColorCount()

	if g_InfantSelectHairColor_SelectIndex < 0 or g_InfantSelectHairColor_SelectIndex >= nCount then 
		PushDebugMessage("#{WGTJ_210112_01}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnChangeInfantHairColor")
		Set_XSCRIPT_ScriptID(890986)
		Set_XSCRIPT_Parameter(0,g_InfantSelectHairColor_SelectIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function InfantSelectHairColor_UpdateZoomButton()
	-- InfantSelectHairColor_Plus:Enable()
	-- InfantSelectHairColor_Subtract:Enable()

	-- if g_InfantSelectHairColor_CameraLevel == 0 then 
	-- 	InfantSelectHairColor_Plus:Disable()
	-- elseif g_InfantSelectHairColor_CameraLevel == 2 then
	-- 	InfantSelectHairColor_Subtract:Disable()
	-- end
end
function InfantSelectHairColor_SetCameraPosition()
	if g_InfantSelectHairColor_CameraLevel > -1 and g_InfantSelectHairColor_CameraLevel < 3 then
		FakeObj_SetCamera( "Special_Infant_7", InfantSelectHairColor_CameraHeight, g_InfantSelectHairColor_CameraPosition[g_InfantSelectHairColor_CameraLevel].fHeight )
		FakeObj_SetCamera( "Special_Infant_7", InfantSelectHairColor_CameraDistance, g_InfantSelectHairColor_CameraPosition[g_InfantSelectHairColor_CameraLevel].fDistance )
		FakeObj_RestoreCamera( "Special_Infant_7" )
	end
end
function InfantSelectHairColor_ZoomIn()
	if g_InfantSelectHairColor_CameraLevel < 1  or g_InfantSelectHairColor_CameraLevel > 2 then
		return
	end
	
	g_InfantSelectHairColor_CameraLevel = g_InfantSelectHairColor_CameraLevel - 1
	InfantSelectHairColor_SetCameraPosition()
	InfantSelectHairColor_UpdateZoomButton()
end
function InfantSelectHairColor_ZoomOut()
	if g_InfantSelectHairColor_CameraLevel < 0  or g_InfantSelectHairColor_CameraLevel > 1 then
		return
	end
	
	g_InfantSelectHairColor_CameraLevel = g_InfantSelectHairColor_CameraLevel + 1
	InfantSelectHairColor_SetCameraPosition()
	InfantSelectHairColor_UpdateZoomButton()
end