
local g_TargetShop_Dresser_Frame_UnifiedPosition
local g_clientNpcId = -1

--相机初始值
local g_Camera_MaxHeight = 1.6
local g_Camera_MinHeight = 1.1
local g_Camera_StepHeight = 0.25
local g_Camera_MaxDist = 7
local g_Camera_MinDist = 2
local g_Camera_StepDist = 2.5
local g_Camera_CurHeight = 1.1
local g_Camera_CurDist = 7
local g_Camera_CurPitch = 0.1

local g_Distance = 1
local g_Distance_Max = 3

local g_CameraPosition =
{
	--女性相关位置
	[0] = {{fHeight = 1.1, fDistance = 7}, {fHeight = 1.35, fDistance = 4.5}, {fHeight = 1.6, fDistance = 2}},
	--男性相关位置
	[1] = {{fHeight = 1, fDistance = 6}, {fHeight = 1.65, fDistance = 2.2}, {fHeight = 1.82, fDistance = 1.2}},
}

local g_TargetShop_Dresser_ClickDress = 0
local g_TargetShop_Dresser_DressList = {}
local g_TargetShop_Dresser_DressPage = 0
local g_TargetShop_Dresser_WeaponList = {}
local g_TargetShop_Dresser_WeaponPage = 0
local g_TargetShop_Dresser_RideList = {}
local g_TargetShop_Dresser_RidePage = 0

local g_TargetShop_Dresser_ButtonList = {}

function TargetShop_Dresser_PreLoad()
	this:RegisterEvent("TARGET_DRESS")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
	this:RegisterEvent("CLOSE_TARGET_EQUIP");
end


function TargetShop_Dresser_OnLoad() 
	g_TargetShop_Dresser_Frame_UnifiedPosition = TargetShop_Dresser_Frame:GetProperty("UnifiedPosition")
	
	g_TargetShop_Dresser_DressList[1] = TargetShop_Dresser_DecorateCloth_Item1
	g_TargetShop_Dresser_DressList[2] = TargetShop_Dresser_DecorateCloth_Item2
	g_TargetShop_Dresser_DressList[3] = TargetShop_Dresser_DecorateCloth_Item3
	g_TargetShop_Dresser_DressList[4] = TargetShop_Dresser_DecorateCloth_Item4
	g_TargetShop_Dresser_DressList[5] = TargetShop_Dresser_DecorateCloth_Item5
	
	g_TargetShop_Dresser_WeaponList[1] = TargetShop_Dresser_DecorateWeapon_Item1
	g_TargetShop_Dresser_WeaponList[2] = TargetShop_Dresser_DecorateWeapon_Item2
	g_TargetShop_Dresser_WeaponList[3] = TargetShop_Dresser_DecorateWeapon_Item3
	g_TargetShop_Dresser_WeaponList[4] = TargetShop_Dresser_DecorateWeapon_Item4
	g_TargetShop_Dresser_WeaponList[5] = TargetShop_Dresser_DecorateWeapon_Item5
	
	g_TargetShop_Dresser_RideList[1] = TargetShop_Dresser_DecorateRide_Item1
	g_TargetShop_Dresser_RideList[2] = TargetShop_Dresser_DecorateRide_Item2
	g_TargetShop_Dresser_RideList[3] = TargetShop_Dresser_DecorateRide_Item3
	g_TargetShop_Dresser_RideList[4] = TargetShop_Dresser_DecorateRide_Item4
	g_TargetShop_Dresser_RideList[5] = TargetShop_Dresser_DecorateRide_Item5
	
	g_TargetShop_Dresser_ButtonList[1] = { TargetShop_Dresser_DecorateCloth_BankFrontBtn, TargetShop_Dresser_DecorateCloth_BankNextBtn }
	g_TargetShop_Dresser_ButtonList[2] = { TargetShop_Dresser_DecorateWeapon_BankFrontBtn, TargetShop_Dresser_DecorateWeapon_BankNextBtn }
	g_TargetShop_Dresser_ButtonList[3] = { TargetShop_Dresser_DecorateRide_BankFrontBtn, TargetShop_Dresser_DecorateRide_BankNextBtn }
end

function TargetShop_Dresser_OnEvent(event)
	if event == "TARGET_DRESS" then
		
		TargetShop_Dresser_CleanUp()		
		g_clientNpcId = tonumber(arg0)
		this:CareObject( g_clientNpcId, 1, "TargetShop_Dresser" )
		TargetShop_Dresser_Update()
		this:Show()
	elseif event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		TargetShop_Dresser_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()		
	elseif "CLOSE_TARGET_EQUIP" == event then
		this:Hide()
end
end

function TargetShop_Dresser_Frame_On_ResetPos()
  TargetShop_Dresser_Frame:SetProperty("UnifiedPosition", g_TargetShop_Dresser_Frame_UnifiedPosition)
end

function TargetShop_Dresser_OnClose()
	this:Hide()
end

function TargetShop_Dresser_OnHiden()
	this:CareObject( g_clientNpcId, 0, "TargetShop_Dresser" )
	g_clientNpcId = -1
	
	TargetShop_Dresser_CleanUp()	
	TargetShop_Dresser_FakeObject:DetachWindowEx()
end

function TargetShop_Dresser_CleanUp()

	TargetShop_Dresser_DecorateCloth_Item:SetActionItem(-1)
	
	TargetShop_Dresser_DecorateWeapon_Item:SetProperty("Empty", "False")
	TargetShop_Dresser_DecorateWeapon_Item:SetProperty("UseDefaultTooltip", "True")
	TargetShop_Dresser_DecorateWeapon_Item:SetProperty("NormalImage", "")
	TargetShop_Dresser_DecorateWeapon_Item:SetProperty("HoverImage", "")
	TargetShop_Dresser_DecorateWeapon_Item:SetToolTip("")
	
	TargetShop_Dresser_DecorateRide_Item:SetProperty("Empty", "False")
	TargetShop_Dresser_DecorateRide_Item:SetProperty("UseDefaultTooltip", "True")
	TargetShop_Dresser_DecorateRide_Item:SetProperty("NormalImage", "")
	TargetShop_Dresser_DecorateRide_Item:SetProperty("HoverImage", "")
	TargetShop_Dresser_DecorateRide_Item:SetToolTip("")
	
	for i = 1, 5 do
		g_TargetShop_Dresser_DressList[i]:SetActionItem(-1)
		g_TargetShop_Dresser_DressList[i]:SetProperty("BackImage", "")
			
		g_TargetShop_Dresser_WeaponList[i]:SetProperty("Empty", "False")
		g_TargetShop_Dresser_WeaponList[i]:SetProperty("UseDefaultTooltip", "True")
		g_TargetShop_Dresser_WeaponList[i]:SetProperty("NormalImage", "")
		g_TargetShop_Dresser_WeaponList[i]:SetProperty("HoverImage", "")
		g_TargetShop_Dresser_WeaponList[i]:SetToolTip("")
		
		g_TargetShop_Dresser_RideList[i]:SetProperty("Empty", "False")
		g_TargetShop_Dresser_RideList[i]:SetProperty("UseDefaultTooltip", "True")
		g_TargetShop_Dresser_RideList[i]:SetProperty("NormalImage", "")
		g_TargetShop_Dresser_RideList[i]:SetProperty("HoverImage", "")
		g_TargetShop_Dresser_RideList[i]:SetToolTip("")
	end
	
	TargetShop_Dresser_Futi_Item:SetProperty("Empty", "False")
	TargetShop_Dresser_Futi_Item:SetProperty("UseDefaultTooltip", "True")
	TargetShop_Dresser_Futi_Item:SetProperty("NormalImage", "")
	TargetShop_Dresser_Futi_Item:SetProperty("HoverImage", "")
	TargetShop_Dresser_Futi_Item:SetToolTip("")
	TargetShop_Dresser_Futi_ItemMask:Hide()
	
	for idx = 1, 3 do
		g_TargetShop_Dresser_ButtonList[idx][1]:Enable()
		g_TargetShop_Dresser_ButtonList[idx][2]:Enable()
	end
	
	TargetShop_Dresser_Head_Item_HeadFrame:SetProperty("Image", "")
	TargetShop_Dresser_Head_Item_HeadFrame_Animate:SetProperty("Animate", "")
end

function TargetShop_Dresser_Update()
	
	local strName = CachedTarget:GetData("NAME", 1)
	if strName == nil then
		return
	end
	local Title = ScriptGlobal_Format( "#{DECOW_160126_123}", strName )
	TargetShop_Dresser_DragTitle:SetText(Title)
	
	TargetShop_Dresser_FakeObject:AttachWindowEx("Exterior_Target")
	Exterior:LuaFnUpdateOtherExteriorAvatar()
	
	g_Distance = 1
	TargetShop_Dresser_UpdateCamera()
	 
	local sex = CachedTarget:GetData("RACE")
	
	--时装
	g_TargetShop_Dresser_DressPage = 1
	g_TargetShop_Dresser_ButtonList[1][1]:Disable()
	TargetShop_Dresser_UpdateDress()
	
	--当前时装
	local ActionDress = EnumAction(16, "targetequip")
	if ActionDress:GetID() == 0 then
		TargetShop_Dresser_DecorateCloth_Item:Hide()
		TargetShop_Dresser_DecorateCloth_Item:SetActionItem(-1)
		TargetShop_Dresser_DecorateCloth_Null:Show()	--尚无装备 
	else	 
		TargetShop_Dresser_DecorateCloth_Item:Show()
		TargetShop_Dresser_DecorateCloth_Item:SetActionItem(ActionDress:GetID())
		TargetShop_Dresser_DecorateCloth_Null:Hide()	--尚无装备
	end	
	
	--坐骑
	g_TargetShop_Dresser_RidePage = 1
	g_TargetShop_Dresser_ButtonList[2][1]:Disable()
	TargetShop_Dresser_UpdateRide()
	
	--当前坐骑
	local edType = 0	
	local nExteriorID = Exterior:LuaFnGetOtherExteriorInUse(edType)
	if nExteriorID ~= nil and nExteriorID > 0 then
		local strName = Exterior:LuaFnGetExteriorRideInfo(nExteriorID, "Name")
		local strIcon = Exterior:LuaFnGetExteriorRideInfo(nExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
				
		TargetShop_Dresser_DecorateRide_Item:Show()		
		TargetShop_Dresser_DecorateRide_Item:SetProperty("NormalImage", strImage)
		TargetShop_Dresser_DecorateRide_Item:SetProperty("HoverImage", strImage)
		TargetShop_Dresser_DecorateRide_Null:Hide()	--尚无装备 
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		TargetShop_Dresser_DecorateRide_Item:SetToolTip(strTemp)
	else
		TargetShop_Dresser_DecorateRide_Item:Hide()
		TargetShop_Dresser_DecorateRide_Null:Show()	--尚无装备 
	end
	
	--幻武
	g_TargetShop_Dresser_WeaponPage = 1
	g_TargetShop_Dresser_ButtonList[3][1]:Disable()
	TargetShop_Dresser_UpdateWeapon()
	
	--当前幻武
	edType = 1
	nExteriorID = Exterior:LuaFnGetOtherExteriorInUse(edType)
	if nExteriorID ~= nil and nExteriorID > 0 then
		local strName = Exterior:LuaFnGetExteriorWeaponInfo(nExteriorID, "Name")
		local strIcon = Exterior:LuaFnGetExteriorWeaponInfo(nExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)	
		
		TargetShop_Dresser_DecorateWeapon_Item:Show()
		TargetShop_Dresser_DecorateWeapon_Item:SetProperty("NormalImage", strImage)
		TargetShop_Dresser_DecorateWeapon_Item:SetProperty("HoverImage", strImage)	
		TargetShop_Dresser_DecorateWeapon_Null:Hide()
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		TargetShop_Dresser_DecorateWeapon_Item:SetToolTip(strTemp)
	else
		TargetShop_Dresser_DecorateWeapon_Item:Hide()
		TargetShop_Dresser_DecorateWeapon_Null:Show()
	end
	
	--附体
	edType = 2
	nExteriorID = Exterior:LuaFnGetOtherExteriorInUse(edType)
	local nVisualIndex = Exterior:LuaFnGetOtherExteriorFutiViusalIndex()
	if nExteriorID ~= nil and nExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFutiInfo(nExteriorID, "Name")
		local strImage 	= Exterior:LuaFnGetExteriorFutiInfo(nExteriorID, "VisualIcon", nVisualIndex)
		local strVisualName = Exterior:LuaFnGetExteriorFutiInfo(nExteriorID, "VisualName", nVisualIndex)

		TargetShop_Dresser_Futi_Name:SetText(strName)
		TargetShop_Dresser_Futi_Item:SetProperty("NormalImage", strImage)
		TargetShop_Dresser_Futi_Item:SetProperty("HoverImage", strImage)
		TargetShop_Dresser_Futi_Item:SetToolTip(strVisualName)
	end
	
	--脸型
	edType = 3
	nExteriorID = Exterior:LuaFnGetOtherExteriorInUse(edType)
	if nExteriorID ~= nil and nExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFaceInfo(nExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorFaceInfo(nExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		
		TargetShop_Dresser_Face_Name:SetText(strName)
	end
	
	--发型
	edType = 4
	nExteriorID = Exterior:LuaFnGetOtherExteriorInUse(edType)
	if nExteriorID ~= nil and nExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorHairInfo(nExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorHairInfo(nExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
	
		TargetShop_Dresser_Hair_Name:SetText(strName)
	end
	
	--头像
	edType = 5
	local strHeadTip = ""
	nExteriorID = Exterior:LuaFnGetOtherExteriorInUse(edType)
	if nExteriorID ~= nil and nExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorPortraitInfo(nExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorPortraitInfo(nExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		
		TargetShop_Dresser_Head_Item:SetProperty("Image", strImage)	
	end
	
	--头像框
	edType = 6
	nExteriorID = Exterior:LuaFnGetOtherExteriorInUse(edType)
	if nExteriorID ~= nil and nExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFrameInfo(nExteriorID, "Name")
		local iType 	= Exterior:LuaFnGetExteriorFrameInfo(nExteriorID, "Type")
		
		if iType == 1 then
			TargetShop_Dresser_Head_Item_HeadFrame:SetProperty("Image", "")
			TargetShop_Dresser_Head_Item_HeadFrame:Hide()
			
			TargetShop_Dresser_Head_Item_HeadFrame_Animate:Show()
			local strAnimate = Exterior:LuaFnGetExteriorFrameInfo(nExteriorID, "FrameAnimate")
			TargetShop_Dresser_Head_Item_HeadFrame_Animate:SetProperty("Animate", tostring(strAnimate))
		else
			TargetShop_Dresser_Head_Item_HeadFrame_Animate:SetProperty("Animate", "")
			TargetShop_Dresser_Head_Item_HeadFrame_Animate:Hide()
			
			TargetShop_Dresser_Head_Item_HeadFrame:Show()
			local strIcon 	= Exterior:LuaFnGetExteriorFrameInfo(nExteriorID, "FrameIcon")
			local strImage = GetIconFullName(strIcon)
			TargetShop_Dresser_Head_Item_HeadFrame:SetProperty("Image", strImage)
		end
	end
	
	--发色
	local _, uRed, uGreee, uBlue, _ = CachedTarget:GetData("HairInfo")
	local imgColor = string.format("%02X%02X%02X%02X", 255, uRed, uGreee, uBlue)
	TargetShop_Dresser_ColorHair_ItemMask:SetImageColor(imgColor)	

	-- 背挂
	local nOrnamentsType = 0
	nExteriorID = OrnamentsScript:GetOtherOrnamentsIDInUse(nOrnamentsType)
	if nExteriorID ~= nil and nExteriorID > 0 then
		local strTips = OrnamentsScript:GetOrnamentsInfo(nOrnamentsType, nExteriorID, "Desc")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(nOrnamentsType, nExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)

		TargetShop_Dresser_Widget_Text_Item:SetProperty("Image", strImage)
		TargetShop_Dresser_Widget_Text_Item:SetToolTip(strTips)
		TargetShop_Dresser_Widget_Text_Null:Hide()
		TargetShop_Dresser_Widget_Text_Item:Show()
	else
		TargetShop_Dresser_Widget_Text_Null:Show()
		TargetShop_Dresser_Widget_Text_Item:Hide()
	end

	-- 头挂
	nOrnamentsType = 1 
	nExteriorID = OrnamentsScript:GetOtherOrnamentsIDInUse(nOrnamentsType)
	if nExteriorID ~= nil and nExteriorID > 0 then
		local strTips = OrnamentsScript:GetOrnamentsInfo(nOrnamentsType, nExteriorID, "Desc")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(nOrnamentsType, nExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)

		TargetShop_Dresser_HeadDress_Text_Item:SetProperty("Image", strImage)
		TargetShop_Dresser_HeadDress_Text_Item:SetToolTip(strTips)
		TargetShop_Dresser_HeadDress_Text_Null:Hide()
		TargetShop_Dresser_HeadDress_Text_Item:Show()
	else
		TargetShop_Dresser_HeadDress_Text_Null:Show()
		TargetShop_Dresser_HeadDress_Text_Item:Hide()
	end
end

function TargetShop_Dresser_UpdateCamera()
	local sex = 0
	if sex ~= 0 and sex ~= 1 then 
		return
	end
	
	if g_Distance < 1 or g_Distance > 3 then
		return
	end
	
	local fHeight, fDistance, fPitch = TargetShop_Dresser_FakeObject:GetCameraEx()
	fHeight = g_CameraPosition[sex][g_Distance].fHeight
	fDistance = g_CameraPosition[sex][g_Distance].fDistance
	TargetShop_Dresser_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)
end

--玩家左旋转
function TargetShop_Dresser_TurnLeft(Index)
	if Index == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		TargetShop_Dresser_FakeObject:RotateBeginEx("Exterior_Target", -0.3)
	else
		TargetShop_Dresser_FakeObject:RotateEndEx()
	end
end

--玩家右旋转
function TargetShop_Dresser_TurnRight(Index)
	if Index == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		TargetShop_Dresser_FakeObject:RotateBeginEx("Exterior_Target", 0.3)
	else
		TargetShop_Dresser_FakeObject:RotateEndEx()
	end
end

--玩家放大
function TargetShop_Dresser_ZoomIn()
	if g_Distance == g_Distance_Max then
		return
	end	
	g_Distance = g_Distance + 1
	TargetShop_Dresser_UpdateCamera()	
end

--玩家缩小
function TargetShop_Dresser_ZoomOut()
	if g_Distance == 1 then
		return
	end	
	g_Distance = g_Distance - 1
	TargetShop_Dresser_UpdateCamera()
end

function TargetShop_Dresser_UpdateDress()

	if g_TargetShop_Dresser_DressPage ~= 1 and g_TargetShop_Dresser_DressPage ~= 2 then
		g_TargetShop_Dresser_DressPage = 1
	end
	
	for i = 1, 5 do
		g_TargetShop_Dresser_DressList[i]:SetActionItem(-1)
		g_TargetShop_Dresser_DressList[i]:SetProperty("BackImage", "")
	end
	
	for i = 1, 5 do
		local nIdx = i - 1 + (g_TargetShop_Dresser_DressPage-1)*5		
		local theAction = EnumAction( nIdx, "fashion_other");
		if theAction:GetID() ~= 0 then
			g_TargetShop_Dresser_DressList[i]:SetActionItem(theAction:GetID())
		else
			g_TargetShop_Dresser_DressList[i]:SetActionItem(-1)
		end
	end
		
end

function TargetShop_Dresser_UpdateWeapon()

	if g_TargetShop_Dresser_WeaponPage ~= 1 and g_TargetShop_Dresser_WeaponPage ~= 2 then
		g_TargetShop_Dresser_WeaponPage = 1
	end
	
	for i = 1, 5 do			
		g_TargetShop_Dresser_WeaponList[i]:SetProperty("Empty", "False")
		g_TargetShop_Dresser_WeaponList[i]:SetProperty("UseDefaultTooltip", "True")
		g_TargetShop_Dresser_WeaponList[i]:SetProperty("NormalImage", "")
		g_TargetShop_Dresser_WeaponList[i]:SetProperty("HoverImage", "")
		g_TargetShop_Dresser_WeaponList[i]:SetToolTip("")
	end
	
	for i = 1, 5 do		
		local nIdx = i - 1 + (g_TargetShop_Dresser_WeaponPage-1)*5
		local nGroupID = Exterior:LuaFnGetOtherExteriorYiRongGeData(2, nIdx)	
		if nGroupID >= 0 then
			local strIcon 	= Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "Icon")
			local strImage = GetIconFullName(strIcon)
			
			g_TargetShop_Dresser_WeaponList[i]:SetProperty("NormalImage", strImage)
			g_TargetShop_Dresser_WeaponList[i]:SetProperty("HoverImage", strImage)
			
			local strTemp = Exterior:LuaFnGetOtherWeaponToolTip(nIdx)
			--Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "ToolTips")			
			if nGroupID == 32 then
				strTemp = strTemp.."#r#{WGTJ_201222_146}"
			elseif nGroupID == 31 then
				strTemp = strTemp.."#r#{WGTJ_201222_145}"
			end
			g_TargetShop_Dresser_WeaponList[i]:SetToolTip(strTemp)
		else		
			g_TargetShop_Dresser_WeaponList[i]:SetProperty("Image", "")
		end		
	end
		
end

function TargetShop_Dresser_UpdateRide()

	if g_TargetShop_Dresser_RidePage ~= 1 and g_TargetShop_Dresser_RidePage ~= 2 then
		g_TargetShop_Dresser_RidePage = 1
	end
	
	for i = 1, 5 do		
		g_TargetShop_Dresser_RideList[i]:SetProperty("Empty", "False")
		g_TargetShop_Dresser_RideList[i]:SetProperty("UseDefaultTooltip", "True")
		g_TargetShop_Dresser_RideList[i]:SetProperty("NormalImage", "")
		g_TargetShop_Dresser_RideList[i]:SetProperty("HoverImage", "")
		g_TargetShop_Dresser_RideList[i]:SetToolTip("")
	end
	
	for i = 1, 5 do		
		local nIdx = i - 1 + (g_TargetShop_Dresser_RidePage-1)*5
		local nExteriorID = Exterior:LuaFnGetOtherExteriorYiRongGeData(3, nIdx)	
		if nExteriorID >= 0 then
			local strIcon	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Icon")
			local strImage	= GetIconFullName(strIcon)
		
			g_TargetShop_Dresser_RideList[i]:SetProperty("NormalImage", strImage)
			g_TargetShop_Dresser_RideList[i]:SetProperty("HoverImage", strImage)
		
			local strTemp = Exterior:LuaFnGetOtherRideToolTip(nIdx)
			g_TargetShop_Dresser_RideList[i]:SetToolTip(strTemp)
		else		
			g_TargetShop_Dresser_RideList[i]:SetProperty("Image", "")
		end		
	end	
		
end

function TargetShop_Dresser_ClickFrontBtn(idx)
	if g_TargetShop_Dresser_ButtonList[idx] ~= nil then
		g_TargetShop_Dresser_ButtonList[idx][1]:Enable()
		g_TargetShop_Dresser_ButtonList[idx][2]:Enable()
	end

	if idx == 1 then
		-- 时装
		if g_TargetShop_Dresser_DressPage == 2 then
			g_TargetShop_Dresser_DressPage = 1
			TargetShop_Dresser_UpdateDress()
			
			g_TargetShop_Dresser_ButtonList[idx][1]:Disable()
			
			TargetShop_Dresser_ClickDressBtn(g_TargetShop_Dresser_ClickDress)
		end
	elseif idx == 2 then
		-- 幻武
		if g_TargetShop_Dresser_WeaponPage == 2 then
			g_TargetShop_Dresser_WeaponPage = 1
			TargetShop_Dresser_UpdateWeapon()
			
			g_TargetShop_Dresser_ButtonList[idx][1]:Disable()
		end
	elseif idx == 3 then
		-- 坐骑
		if g_TargetShop_Dresser_RidePage == 2 then
			g_TargetShop_Dresser_RidePage = 1
			TargetShop_Dresser_UpdateRide()
			
			g_TargetShop_Dresser_ButtonList[idx][1]:Disable()
		end
	else
		-- error
	end
	
end

function TargetShop_Dresser_ClickNextBtn(idx)
	if g_TargetShop_Dresser_ButtonList[idx] ~= nil then
		g_TargetShop_Dresser_ButtonList[idx][1]:Enable()
		g_TargetShop_Dresser_ButtonList[idx][2]:Enable()
	end

	if idx == 1 then
		-- 时装
		if g_TargetShop_Dresser_DressPage == 1 then
			g_TargetShop_Dresser_DressPage = 2
			TargetShop_Dresser_UpdateDress()
			
			g_TargetShop_Dresser_ButtonList[idx][2]:Disable()
			
			TargetShop_Dresser_ClickDressBtn(g_TargetShop_Dresser_ClickDress)
		end
	elseif idx == 2 then
		-- 幻武
		if g_TargetShop_Dresser_WeaponPage == 1 then
			g_TargetShop_Dresser_WeaponPage = 2
			TargetShop_Dresser_UpdateWeapon()
			
			g_TargetShop_Dresser_ButtonList[idx][2]:Disable()
		end
	elseif idx == 3 then
		-- 坐骑
		if g_TargetShop_Dresser_RidePage == 1 then
			g_TargetShop_Dresser_RidePage = 2
			TargetShop_Dresser_UpdateRide()
			
			g_TargetShop_Dresser_ButtonList[idx][2]:Disable()
		end
	else
		-- error
	end
end

function TargetShop_Dresser_ClickDressBtn(idx)

	if g_TargetShop_Dresser_DressPage ~= 1 and g_TargetShop_Dresser_DressPage ~= 2 then
		return
	end
	
	if g_TargetShop_Dresser_ClickDress == idx then
		g_TargetShop_Dresser_ClickDress = 0
		Exterior:LuaFnUpdateOtherExteriorAvatar()		
		for i = 1, 5 do
			g_TargetShop_Dresser_DressList[i]:SetProperty("BackImage", "")
		end
		return
	end
	
	g_TargetShop_Dresser_ClickDress = idx
	
	if idx >= 1 and idx <= 5 then	
		local nFashionIdx = idx - 1 + (g_TargetShop_Dresser_DressPage-1)*5		
		local nRet = Exterior:LuaFnUpdateOtherExteriorAvatarFashion(nFashionIdx)
		if nRet == 1 then
			for i = 1, 5 do
				if i == idx then
					g_TargetShop_Dresser_DressList[i]:SetProperty("BackImage", "set:CommonFrame image:ActionButtonPushed")
				else
					g_TargetShop_Dresser_DressList[i]:SetProperty("BackImage", "")
				end
			end
		end
	end	
	
end



