--NewExterior_InfantHairStyle.lua
--!!!reloadscript =NewExterior_InfantHairStyle
--2020Q4 新图鉴子女发型发色
local g_Frame_UnifiedPosition
local g_ExteriorType = 7

local NewExterior_InfantHairStyle_CameraHeight = 1		--摄影机高度
local NewExterior_InfantHairStyle_CameraDistance = 2		--摄影机距离
local NewExterior_InfantHairStyle_CameraPitch = 3			--摄影机角度
local g_NewExterior_InfantHairStyle_CameraLevel = 0
local g_NewExterior_InfantHairStyle_CameraPosition =
{
	[0] = {fHeight = 0.6, fDistance = 4, },
	[1] = {fHeight = 0.6, fDistance = 5, },
	[2] = {fHeight = 0.6, fDistance = 6, }, 
}
local g_nHairStyleInit = 0
local g_ChildHairStyleUIList = {}
local g_ChildHairStyleInfoList = {}
local g_nSelectedHairStyleIndex = -1
local g_nSelectedHairStyleUniID = -1

local g_nHairColorInit = 0
local g_nHairColorMaxNum = 20
local g_ChildHairColorUIList = {}
local g_ChildHairColorInfoList = {}
local g_nSelectedHairColorIndex = -1
local g_nSelectedHairColorUniID = -1
--===============================================
-- OnLoad()
--===============================================
function NewExterior_InfantHairStyle_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_EXTERIOR")
	this:RegisterEvent("OPEN_EXTERIOR_FASHION")
	this:RegisterEvent("UPDATE_EXTERIOR_FASHION",false)
	this:RegisterEvent("REFRESH_INFANT_HAIRCOLOR",false)
	this:RegisterEvent("REFRESH_INFANT_HAIRSTYLE",false)
	this:RegisterEvent("UPDATE_INFANT_EXTERIORSETINFO", false)
	this:RegisterEvent("UPDATE_EXTERIOR_TIP", false)
end
function NewExterior_InfantHairStyle_OnLoad()
	g_Frame_UnifiedPosition = NewExterior_InfantHairStyle_Frame:GetProperty("UnifiedPosition")
	NewExterior_InfantHairStyle_HairStyle_LeftBtn:SetProperty("Empty", "FALSE")
	NewExterior_InfantHairStyle_HairStyle_LeftBtn:SetProperty("UseDefaultTooltip", "True")
	NewExterior_InfantHairStyle_Dress_Tip:Hide()
	NewExterior_InfantHairStyle_Dress_LockImg:Hide()
end

--===============================================
-- OnEvent()
--===============================================
function NewExterior_InfantHairStyle_OnEvent(event)
if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		NewExterior_InfantHairStyle_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		NewExterior_InfantHairStyle_OnHide()
	-- elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15840001 ) then
	-- 	if this:IsVisible() then
	-- 		return
	-- 	end
	-- 	local npcObjId = Get_XParam_INT(0)
	-- 	g_clientNpcId = DataPool : GetNPCIDByServerID(npcObjId)
	-- 	if g_clientNpcId ~= -1 then
	-- 		this:CareObject( g_clientNpcId, 1, "NewExterior_InfantHairStyle" )
	-- 	end
	-- 	NewExterior_InfantHairStyle_OnShow()
	elseif event == "OPEN_EXTERIOR" then
		if tonumber(arg0) == g_ExteriorType then
			if this:IsVisible() then
				NewExterior_InfantHairStyle_OnHide()
			else
				NewExterior_InfantHairStyle_OnShow()
			end
			return
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 80081701 ) then
		if this:IsVisible() then
			NewExterior_InfantHairStyle_CloseClick()
			return
		end
	elseif event == "OPEN_EXTERIOR_FASHION" and tonumber(arg0) == 2 and tonumber(arg1) == 1 then
		g_nSelectedHairStyleUniID = Exterior:LuaFnGetChildExteriorInUse("HAIR")
		g_nSelectedHairColorUniID = Exterior:LuaFnGetChildExteriorInUse("HAIRCOLOR")
	elseif event == "UPDATE_EXTERIOR_FASHION" and  tonumber(arg0) == 2 then 
		-- 子女时装有更改 主动刷一下左侧状态和模型
		-- NewExterior_InfantHairStyle_UpdateLeftAction()
		if tonumber(arg1) == 1 then 
			Exterior:LuaFnSetCurrentChildExteriorSetInfo("FASHION", -1)
		end
	elseif event == "REFRESH_INFANT_HAIRCOLOR" and tonumber(arg0) == 1 then
		-- 子女发色有更改 主动刷一下列表(列表最后的默认选中会更新左侧状态和模型)
		NewExterior_InfantHairStyle_InitHairColor()
	elseif event == "REFRESH_INFANT_HAIRSTYLE" and tonumber(arg0) == 1 then
		-- 子女发型有更改 主动刷一下列表(列表最后的默认选中会更新左侧状态和模型)
		NewExterior_InfantHairStyle_InitHairStyle()
	elseif event == "UPDATE_INFANT_EXTERIORSETINFO" then 
		if tonumber(arg0) == 2 then 
			g_nSelectedHairStyleUniID = -1
			NewExterior_InfantHairStyle_InitHairStyle()
		end
		NewExterior_InfantHairStyle_UpdateLeftAction()
	elseif event == "UPDATE_EXTERIOR_TIP" then 
		NewExterior_InfantHairStyle_UpdateRedPoint()
	end
end
function NewExterior_InfantHairStyle_CloseClick()
	Exterior:LuaFnSetCurrentChildExteriorSetInfo("RESET", 0)
	NewExterior_InfantHairStyle_OnHide()
end
function NewExterior_InfantHairStyle_OnHide()
	if IsWindowShow("NewExterior_InfantDressBox") then
	else	
		Infant:ClearFittingProperty()
	end	

	NewExterior_InfantHairStyle_SetPosition()
	NewExterior_InfantHairStyle_FakeObject:SetFakeObject("")
	this:Hide()
end
function NewExterior_InfantHairStyle_OnShow()
	NewExterior_InfantHairStyle_SetPosition()
	g_NewExterior_InfantHairStyle_CameraLevel = 0

	NewExterior_InfantHairStyle_UpdateModel()
	NewExterior_InfantHairStyle_Init()
	this:Show()
end
--===============================================
-- 左侧Action逻辑
--===============================================
function NewExterior_InfantHairStyle_UpdateLeftAction()
	local uiLeftDressAction = NewExterior_InfantHairStyle_Dress_LeftBtn
	local uiLeftDressLock = NewExterior_InfantHairStyle_Dress_ActionImg
	local uiLeftHairStyleAction = NewExterior_InfantHairStyle_HairStyle_LeftBtn
	local uiLeftHairStyleLock = NewExterior_InfantHairStyle_HairStyle_ActionImg
	local uiLeftHairStyleMask = NewExterior_InfantHairStyle_HairStyle_LockImg

	local useIndex, setIndex, nRealIndex = -1,-1,-1
	-- 子女时装
	useIndex = Exterior:LuaFnGetChildExteriorInUse("FASHION")
	setIndex = Exterior:LuaFnGetCurrentChildExteriorSetInfo("FASHION")
	-- PushDebugMessage("LuaFnGetChildExteriorInUse:"..useIndex..":"..setIndex)
	if setIndex >= 0 then 
		nRealIndex = setIndex
		uiLeftDressLock:Show()
	elseif useIndex >= 0 then
		nRealIndex = useIndex
		uiLeftDressLock:Hide()
	else
		nRealIndex = -1
		uiLeftDressLock:Hide()
	end
	if nRealIndex >= 0 then 
		local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(2, nRealIndex)
		uiLeftDressAction:SetActionItem(theAction:GetID())
		-- local nExteriorID = FashionDepot:LuaFnGetFashionId(2, nRealIndex)
		local bOk, ItemTableIndex, VisualId, DressName, nRare, szRareDesc = Infant:GetInfantExteriorItemInfo(nRealIndex)
		Infant:SetSpecialObjProperty(7,"BodyVisual", tostring( VisualId ) )
		Infant:SetFittingProperty( "BodyVisual", tostring( VisualId ) )
	else
		uiLeftDressAction:SetActionItem(-1)
		Infant:SetSpecialObjProperty(7,"BodyVisual", tostring( -1 ) )
		Infant:SetFittingProperty( "BodyVisual", tostring( -1 ) )
	end

	-- 子女发型
	useIndex = Exterior:LuaFnGetChildExteriorInUse("HAIR")
	setIndex = Exterior:LuaFnGetCurrentChildExteriorSetInfo("HAIR")
	-- PushDebugMessage("LuaFnGetChildExteriorInUse:"..useIndex..":"..setIndex)
	if setIndex >= 0 then 
		nRealIndex = setIndex
		uiLeftHairStyleLock:Show()
	elseif useIndex >= 0 then 
		nRealIndex = useIndex
		uiLeftHairStyleLock:Hide()
	else
		nRealIndex = -1
		uiLeftHairStyleLock:Show()
	end
	if nRealIndex >= 0 then 
		if Exterior:LuaFnIsHaveExterior(7, nRealIndex) == 1 then
			uiLeftHairStyleMask:Hide()
		else
			uiLeftHairStyleMask:Show()
		end
		local nRet, nHairId, strName, nVisibleID, nItemID, nCost, strIconName = Exterior:LuaFnGetExteriorChildHairStyleInfo(nRealIndex) 
		local IconFile = GetIconFullName( strIconName )
		uiLeftHairStyleAction:SetProperty( "NormalImage", IconFile )
		uiLeftHairStyleAction:SetProperty( "HoverImage", IconFile )
		uiLeftHairStyleAction:SetToolTip( strName )
		Infant:SetSpecialObjProperty(7,"HairVisual", tostring( nVisibleID ) )
		Infant:SetFittingProperty( "HairVisual", tostring( nVisibleID ) )
	else
		uiLeftHairStyleAction:SetAction(-1)
		uiLeftHairStyleAction:SetToolTip( "" )
		-- local nRet, nHairId, strName, nVisibleID, nItemID, nCost, strIconName = Exterior:LuaFnGetExteriorChildHairStyleInfo(useIndex) 
		-- local MyHairStyle = Infant:GetInfantHairStyle(0)
		-- if MyHairStyle == -1 then MyHairStyle = 20000 end
		Infant:SetSpecialObjProperty(7,"HairVisual", tostring( -1 ) )
		Infant:SetFittingProperty( "HairVisual", tostring( -1 ) )

	end

	useIndex = Exterior:LuaFnGetChildExteriorInUse("HAIRCOLOR")
	setIndex = Exterior:LuaFnGetCurrentChildExteriorSetInfo("HAIRCOLOR")
	if setIndex >= 0 then 
		nRealIndex = setIndex
	elseif useIndex >= 0 then 
		nRealIndex = useIndex
	else
		nRealIndex = -1
	end
	if nRealIndex >= 0 then 
		local nRed,nGreen,nBlue,nAlpha = Exterior:LuaFnEnumChildHairColor(nRealIndex)
		local nRgb = math.floor(nRed,1) * 65536 + math.floor(nGreen,1) * 256 + math.floor(nBlue,1)
		Infant:SetSpecialObjProperty( 7, "HairColor", tostring( nRgb ) )
		Infant:SetFittingProperty( "HairColor", tostring( nRgb ) )
	else
		-- local nRed,nGreen,nBlue,nAlpha = Exterior:LuaFnEnumChildHairColor(useIndex)
		-- local nRed,nGreen,nBlue = Infant:GetInfantHairColorRGBA(0)
		-- local nRgb = math.floor(nRed,1) * 65536 + math.floor(nGreen,1) * 256 + math.floor(nBlue,1)
		Infant:SetSpecialObjProperty( 7, "HairColor", tostring( -1 ) )
		Infant:SetFittingProperty( "HairColor", tostring( -1 ) )
	end
end

function NewExterior_InfantHairStyle_LeftDressClick()
	local useIndex = Exterior:LuaFnGetChildExteriorInUse("FASHION")
	local setIndex = Exterior:LuaFnGetCurrentChildExteriorSetInfo("FASHION")
	-- PushDebugMessage("NewExterior_InfantHairStyle_LeftDressClick:"..useIndex..":"..setIndex)
	if useIndex >= 0 then 
		Exterior:LuaFnUnUseChildExteriorFashion(2)
	elseif setIndex >= 0 then 
		Exterior:LuaFnSetCurrentChildExteriorSetInfo("FASHION", -1)
	end
end
--===============================================
-- 页签逻辑
--===============================================
function NewExterior_InfantHairStyle_SetPosition()
	local nExteriorUnionPos = Variable:GetVariable("ExteriorUnionPos")
	if nExteriorUnionPos ~= nil then
		NewExterior_InfantHairStyle_Frame:SetProperty("UnifiedPosition", nExteriorUnionPos)
	end
end
function NewExterior_InfantHairStyle_SavePosition()
	Variable:SetVariable("ExteriorUnionPos", NewExterior_InfantHairStyle_Frame:GetProperty("UnifiedPosition"), 1)
end
function NewExterior_InfantHairStyle_OpenFashion()
	NewExterior_InfantHairStyle_SavePosition()
	NewExterior_InfantHairStyle_FakeObject:SetFakeObject("")
	-- 打开子女时装界面
	PushEvent("OPEN_EXTERIOR_FASHION", 2, 0)
end
function NewExterior_InfantHairStyle_OpenHair()
end
function NewExterior_InfantHairStyle_GoBack()
	NewExterior_InfantHairStyle_SavePosition()
	-- 返回人物时装界面
	PushEvent("OPEN_EXTERIOR_FASHION", 1, 1)
end
--===============================================
-- 模型缩放转向逻辑
--===============================================
function NewExterior_InfantHairStyle_UpdateZoomButton()
	-- NewExterior_InfantHairStyle_Model_Plus:Enable()
	-- NewExterior_InfantHairStyle_Model_Subtract:Enable()
	
	-- if g_NewExterior_InfantHairStyle_CameraLevel == 0 then 
	-- 	NewExterior_InfantHairStyle_Model_Plus:Disable()
	-- elseif g_NewExterior_InfantHairStyle_CameraLevel == 2 then
	-- 	NewExterior_InfantHairStyle_Model_Subtract:Disable()
	-- end
end
function NewExterior_InfantHairStyle_SetCameraPosition()
	if g_NewExterior_InfantHairStyle_CameraLevel > -1 and g_NewExterior_InfantHairStyle_CameraLevel < 3 then
		FakeObj_SetCamera( "Special_Infant_7", NewExterior_InfantHairStyle_CameraHeight, g_NewExterior_InfantHairStyle_CameraPosition[g_NewExterior_InfantHairStyle_CameraLevel].fHeight )
		FakeObj_SetCamera( "Special_Infant_7", NewExterior_InfantHairStyle_CameraDistance, g_NewExterior_InfantHairStyle_CameraPosition[g_NewExterior_InfantHairStyle_CameraLevel].fDistance )
		FakeObj_RestoreCamera( "Special_Infant_7" )
	end
end
function NewExterior_InfantHairStyle_ZoomIn()
	if g_NewExterior_InfantHairStyle_CameraLevel < 1  or g_NewExterior_InfantHairStyle_CameraLevel > 2 then
		return
	end
	
	g_NewExterior_InfantHairStyle_CameraLevel = g_NewExterior_InfantHairStyle_CameraLevel - 1
	NewExterior_InfantHairStyle_SetCameraPosition()
	NewExterior_InfantHairStyle_UpdateZoomButton()
end
function NewExterior_InfantHairStyle_ZoomOut()
	if g_NewExterior_InfantHairStyle_CameraLevel < 0  or g_NewExterior_InfantHairStyle_CameraLevel > 1 then
		return
	end
	
	g_NewExterior_InfantHairStyle_CameraLevel = g_NewExterior_InfantHairStyle_CameraLevel + 1
	NewExterior_InfantHairStyle_SetCameraPosition()
	NewExterior_InfantHairStyle_UpdateZoomButton()
end
function NewExterior_InfantHairStyle_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			NewExterior_InfantHairStyle_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			NewExterior_InfantHairStyle_FakeObject:RotateEnd();
		end
	end
end
function NewExterior_InfantHairStyle_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			NewExterior_InfantHairStyle_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			NewExterior_InfantHairStyle_FakeObject:RotateEnd();
		end
	end
end
function NewExterior_InfantHairStyle_UpdateModel()
	NewExterior_InfantHairStyle_FakeObject:SetFakeObject("")
	Infant:SetSpecialObjProperty(7,"CopyFrom","0")
	Infant:SetSpecialObjProperty(7,"Dir","0.0")
	
	--强制成年模式
	local s = Infant:GetInfantSex(0)
	if s == 0 then
		Infant:SetSpecialObjProperty(7,"RaceId","16542")
	else
		Infant:SetSpecialObjProperty(7,"RaceId","16543")
	end
	
	NewExterior_InfantHairStyle_FakeObject:SetFakeObject( "Special_Infant_7" )

	NewExterior_InfantHairStyle_SetCameraPosition()
	NewExterior_InfantHairStyle_UpdateZoomButton()
end
--===============================================
-- 功能逻辑
--===============================================
function NewExterior_InfantHairStyle_Init()
	NewExterior_InfantHairStyle_InitHairStyle()
	NewExterior_InfantHairStyle_InitHairColor()
	NewExterior_InfantHairStyle_UpdateRedPoint()
end
function NewExterior_InfantHairStyle_InitHairStyle()
	if g_nHairStyleInit == 0 then 
		-- 初始化子女发型UI列表
		g_ChildHairStyleUIList = {}
		NewExterior_InfantHairStyle_SuperList:Clear()
		Exterior:LuaFnInitExteriorList(g_ExteriorType)
		local nAllNum = Exterior:LuaFnGetExteriorListCount(g_ExteriorType, 0)
		for i=1,nAllNum do 
			local bar = NewExterior_InfantHairStyle_SuperList:AddChild("NewExterior_InfantHairStyle_SuperListItem")
			bar:GetSubItem("NewExterior_InfantHairStyle_SuperListItemAction"):SetEvent("MouseLButtonDown", string.format("NewExterior_InfantHairStyle_OnHairStyleClick(%d)", i))
			local tabInfo = {}
			tabInfo.uiBar = bar
			tabInfo.uiAction = bar:GetSubItem("NewExterior_InfantHairStyle_SuperListItemAction")
			tabInfo.uiAction:SetProperty("Empty", "FALSE")
			tabInfo.uiAction:SetProperty("UseDefaultTooltip", "True")
			tabInfo.uiActionTip = bar:GetSubItem("NewExterior_InfantHairStyle_SuperListItemActionTip")
			tabInfo.uiActionDef = bar:GetSubItem("NewExterior_InfantHairStyle_SuperListItemActionDef")
			tabInfo.uiActionView = bar:GetSubItem("NewExterior_InfantHairStyle_SuperListItemActionView")
			tabInfo.uiActionLock = bar:GetSubItem("NewExterior_InfantHairStyle_SuperListItemActionLock")
			table.insert( g_ChildHairStyleUIList, tabInfo )
		end
		g_nHairStyleInit = 1
	end
	g_ChildHairStyleInfoList = {}
	local nAllNum = Exterior:LuaFnGetExteriorListCount(g_ExteriorType, 0)
	-- 子女发型图鉴信息
	for i=1,nAllNum do 
		local nExteriorId = Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, i-1)
		local nRet, nHairId, strName, nVisibleID, nItemID, nCost, strIconName = Exterior:LuaFnGetExteriorChildHairStyleInfo(nExteriorId) 
		local tabInfo = {}
		tabInfo.nVecIndex = i-1
		tabInfo.nExteriorId = nExteriorId
		tabInfo.nHairId = nHairId
		tabInfo.nVisibleID = nVisibleID
		tabInfo.strIconName = strIconName
		tabInfo.strName = strName
		if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorId) == 1 then
			tabInfo.isUnLock = 1	
		else
			tabInfo.isUnLock = 0
		end
		if tabInfo.nExteriorId==Exterior:LuaFnGetChildExteriorInUse("HAIR") then 
			tabInfo.bDressUp = 1
		else
			tabInfo.bDressUp = 0
		end

		table.insert(g_ChildHairStyleInfoList, tabInfo)
	end
	-- 排序
	table.sort(g_ChildHairStyleInfoList, function(a, b)
			if a.bDressUp ~= b.bDressUp then 
				return a.bDressUp > b.bDressUp
			end
			if a.isUnLock ~= b.isUnLock then
				return a.isUnLock > b.isUnLock
			end
			return a.nExteriorId < b.nExteriorId
		end)
	-- 刷新UI信息展示
	local nSelectIndex = -1
	for i=1,nAllNum do 
		local tabUIInfo = g_ChildHairStyleUIList[i]
		tabUIInfo.uiActionTip:Hide()
		tabUIInfo.uiActionDef:Hide()
		tabUIInfo.uiActionView:Hide()
		tabUIInfo.uiActionLock:Show()

		local tabInfo = g_ChildHairStyleInfoList[i]
		local IconFile = GetIconFullName( tabInfo.strIconName )
		tabUIInfo.uiAction:SetProperty( "NormalImage", IconFile )
		tabUIInfo.uiAction:SetProperty( "HoverImage", IconFile )
		tabUIInfo.uiAction:SetToolTip( tabInfo.strName )	
		if tabInfo.isUnLock == 1 then 
			tabUIInfo.uiActionLock:Hide()
		end
		if tabInfo.bDressUp == 1 then 
			tabUIInfo.uiActionDef:Show()
		end
		if tabInfo.nExteriorId == g_nSelectedHairStyleUniID then 
			nSelectIndex = i
		end
		if Exterior:LuaFnGetExteriorTip(7, tabInfo.nExteriorId) == 1 then 
			tabUIInfo.uiActionTip:Show()
		end
	end
	NewExterior_InfantHairStyle_OnHairStyleClick(nSelectIndex)
end
function NewExterior_InfantHairStyle_InitHairColor()
	if g_nHairColorInit == 0 then 
		-- 所有UI信息
		g_ChildHairColorUIList ={}
		NewExterior_InfantHairStyle_ColorList:Clear()
		for i=1,g_nHairColorMaxNum do 
			local bar = NewExterior_InfantHairStyle_ColorList:AddChild("NewExterior_InfantHairStyle_ColorListItem")
			bar:GetSubItem("NewExterior_InfantHairStyle_ColorListItemAction"):SetEvent("MouseLButtonDown", string.format("NewExterior_InfantHairStyle_OnHairColorClick(%d)", i))
			local tabInfo = {}
			tabInfo.uiBar = bar
			tabInfo.uiAction = bar:GetSubItem("NewExterior_InfantHairStyle_ColorListItemAction")
			tabInfo.uiActionColor = bar:GetSubItem("NewExterior_InfantHairStyle_ColorListColor")
			tabInfo.uiActionTip = bar:GetSubItem("NewExterior_InfantHairStyle_ColorListItemActionTip")
			tabInfo.uiActionDef = bar:GetSubItem("NewExterior_InfantHairStyle_ColorListItemActionDef")
			tabInfo.uiActionView = bar:GetSubItem("NewExterior_InfantHairStyle_ColorListItemActionView")
			tabInfo.uiActionLock = bar:GetSubItem("NewExterior_InfantHairStyle_ColorListItemActionLock")
			table.insert(g_ChildHairColorUIList, tabInfo)
		end
		g_nHairColorInit = 1
	end

	-- 所有发色信息
	g_ChildHairColorInfoList = {}
	local nCount, nMaxCount = Exterior:LuaFnGetChildHairColorCount()
	for i=0,nCount-1 do 
		local nVecIndex = i
		local tabInfo = {}
		local r,g,b,a = Exterior:LuaFnEnumChildHairColor(nVecIndex)
		local imageColor = string.format("%02X%02X%02X%02X", 255, r, g, b)
		tabInfo.nVecIndex = nVecIndex
		tabInfo.imageColor = imageColor
		if tabInfo.nVecIndex == Exterior:LuaFnGetChildExteriorInUse("HAIRCOLOR") then 
			tabInfo.bDressUp = 1
		else
			tabInfo.bDressUp = 0
		end
		table.insert(g_ChildHairColorInfoList, tabInfo)
	end
	-- 排序
	-- 显示
	local nSelectIndex = -1
	for i=1,g_nHairColorMaxNum do 
		local tabUIInfo = g_ChildHairColorUIList[i]
		tabUIInfo.uiActionColor:SetImageColor("00FFFFFF")
		tabUIInfo.uiActionTip:Hide()
		tabUIInfo.uiActionDef:Hide()
		tabUIInfo.uiActionView:Hide()
		tabUIInfo.uiActionLock:Show()

		local tabInfo = g_ChildHairColorInfoList[i]
		if tabInfo then 
			tabUIInfo.uiActionColor:SetImageColor(tabInfo.imageColor)
			tabUIInfo.uiActionLock:Hide()
			if tabInfo.bDressUp == 1 then 
				tabUIInfo.uiActionDef:Show()
			end
			if tabInfo.nVecIndex == g_nSelectedHairColorUniID then 
				nSelectIndex = i
			end
			if Exterior:LuaFnEnumInfantExteriorHairColorTip(tabInfo.nVecIndex) == 1 then 
				tabUIInfo.uiActionTip:Show()
			end
		end
	end
	NewExterior_InfantHairStyle_OnHairColorClick(nSelectIndex)
end
function NewExterior_InfantHairStyle_OnHairStyleClear()
	if g_nSelectedHairStyleIndex > 0 then 
		g_ChildHairStyleUIList[g_nSelectedHairStyleIndex].uiAction:SetPushed(0)
		g_ChildHairStyleUIList[g_nSelectedHairStyleIndex].uiActionView:Hide()
	end
	g_nSelectedHairStyleIndex = -1
	g_nSelectedHairStyleUniID = -1
end
function NewExterior_InfantHairStyle_OnHairStyleClick(nIndex)
	if nIndex == -1 then 
		NewExterior_InfantHairStyle_OnHairStyleClear()
		Exterior:LuaFnSetCurrentChildExteriorSetInfo("HAIR", -1)
	end
	local tabInfo = g_ChildHairStyleInfoList[nIndex]
	if not tabInfo  then return end
	if g_nSelectedHairStyleIndex > 0 then 
		g_ChildHairStyleUIList[g_nSelectedHairStyleIndex].uiAction:SetPushed(0)
		g_ChildHairStyleUIList[g_nSelectedHairStyleIndex].uiActionView:Hide()
	end
	g_nSelectedHairStyleIndex = nIndex
	g_nSelectedHairStyleUniID = tabInfo.nExteriorId
	g_ChildHairStyleUIList[g_nSelectedHairStyleIndex].uiAction:SetPushed(1)
	if tabInfo.nExteriorId ~= Exterior:LuaFnGetChildExteriorInUse("HAIR") then
		g_ChildHairStyleUIList[g_nSelectedHairStyleIndex].uiActionView:Show()
	end
	-- Infant:SetSpecialObjProperty(7,"HairVisual", tostring( tabInfo.nVisibleID ) )
	-- Infant:SetFittingProperty( "HairVisual", tostring( tabInfo.nVisibleID ) )

	Exterior:LuaFnSetCurrentChildExteriorSetInfo("HAIR", tabInfo.nExteriorId)

	if Exterior:LuaFnGetExteriorTip(7, tabInfo.nExteriorId) == 1 then 
		g_ChildHairStyleUIList[g_nSelectedHairStyleIndex].uiActionTip:Hide()
		Exterior:LuaFnRemoveExteriorTip(7, tabInfo.nExteriorId)
	end	
end
function NewExterior_InfantHairStyle_OnHairColorClear()
	if g_nSelectedHairColorIndex > 0 then 
		g_ChildHairColorUIList[g_nSelectedHairColorIndex].uiAction:SetPushed(0)
		g_ChildHairColorUIList[g_nSelectedHairColorIndex].uiActionView:Hide()
	end
	g_nSelectedHairColorIndex = -1
	g_nSelectedHairColorUniID = -1
end
function NewExterior_InfantHairStyle_OnHairColorClick(nIndex)
	if nIndex == -1 then 
		NewExterior_InfantHairStyle_OnHairColorClear()
		Exterior:LuaFnSetCurrentChildExteriorSetInfo("HAIRCOLOR", -1)

	end
	local tabInfo = g_ChildHairColorInfoList[nIndex]
	if not tabInfo then return end
	if g_nSelectedHairColorIndex > 0 then 
		g_ChildHairColorUIList[g_nSelectedHairColorIndex].uiAction:SetPushed(0)
		g_ChildHairColorUIList[g_nSelectedHairColorIndex].uiActionView:Hide()
	end
	g_nSelectedHairColorIndex = nIndex
	g_nSelectedHairColorUniID = tabInfo.nVecIndex

	g_ChildHairColorUIList[g_nSelectedHairColorIndex].uiAction:SetPushed(1)
	if tabInfo.nVecIndex ~= Exterior:LuaFnGetChildExteriorInUse("HAIRCOLOR") then 
		g_ChildHairColorUIList[g_nSelectedHairColorIndex].uiActionView:Show()
	end
	-- 设置模型发色
	-- local nRed,nGreen,nBlue,nAlpha = Exterior:LuaFnEnumChildHairColor(tabInfo.nVecIndex)
	-- local nRgb = math.floor(nRed,1) * 65536 + math.floor(nGreen,1) * 256 + math.floor(nBlue,1)
	-- Infant:SetSpecialObjProperty( 7, "HairColor", tostring( nRgb ) )

	Exterior:LuaFnSetCurrentChildExteriorSetInfo("HAIRCOLOR", tabInfo.nVecIndex)

	if Exterior:LuaFnEnumInfantExteriorHairColorTip(tabInfo.nVecIndex)==1 then 
		g_ChildHairColorUIList[g_nSelectedHairColorIndex].uiActionTip:Hide()
		Exterior:LuaFnRemoveInfantHairColorTip(tabInfo.nVecIndex)
	end	
end
function NewExterior_InfantHairStyle_DressUp()
	-- if g_nSelectedHairStyleIndex < 0 and g_nSelectedHairColorIndex < 0 then 
	-- 	PushDebugMessage("#{WGJM_210104_02}")
	-- 	return
	-- end
	-- NewExterior_InfantHairStyle_DirectChangeHairStyle()
	-- NewExterior_InfantHairStyle_DirectChangeHairColor()

	if Exterior:LuaFnIsHaveInfantExteriorChange() == 0 then
		PushDebugMessage("#{WGJM_210104_02}")
		return
	end

	Exterior:LuaFnSaveInfantExteriorAllChange(1)
end
function NewExterior_InfantHairStyle_DirectChangeHairStyle()
	if g_nSelectedHairStyleIndex < 0 then 
		return
	end
	local tabInfo = g_ChildHairStyleInfoList[g_nSelectedHairStyleIndex]
	if not tabInfo then 
		PushDebugMessage("InfantSelectHairStyle_OnOk: tabInfo nil:"..(g_nSelectedHairStyleIndex or "nil"))
		return
	end

	local MyHairStyle = Infant:GetInfantHairStyle(0)
	if not MyHairStyle then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnExteriorInfantHairStyle")
		Set_XSCRIPT_ScriptID(890987)
		Set_XSCRIPT_Parameter(0,tabInfo.nExteriorId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
function NewExterior_InfantHairStyle_DirectChangeHairColor()
	if g_nSelectedHairColorIndex < 0 then 
		return
	end
	local tabInfo = g_ChildHairColorInfoList[g_nSelectedHairColorIndex]
	if not tabInfo then 
		PushDebugMessage("InfantSelectHairColor_OnOk: tabInfo nil:"..(g_nSelectedHairColorIndex or "nil"))
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnExteriorInfantHairColor")
		Set_XSCRIPT_ScriptID(890986)
		Set_XSCRIPT_Parameter(0,tabInfo.nVecIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
function NewExterior_InfantHairStyle_Undo()
	local setIndex_fashion = Exterior:LuaFnGetCurrentChildExteriorSetInfo("FASHION")
	local setIndex_hairstyle = Exterior:LuaFnGetCurrentChildExteriorSetInfo("HAIR")
	local setIndex_haircolor = Exterior:LuaFnGetCurrentChildExteriorSetInfo("HAIRCOLOR")
	if setIndex_fashion<0 and setIndex_hairstyle<0 and setIndex_haircolor<0 then 
		PushDebugMessage("#{WGTJ_201222_76}")
		return
	end

	Exterior:LuaFnSetCurrentChildExteriorSetInfo("RESET", 1)
	Infant:ClearFittingProperty()
	-- NewExterior_InfantHairStyle_OnHairStyleClear()
	-- NewExterior_InfantHairStyle_OnHairColorClear()
	g_nSelectedHairStyleUniID = Exterior:LuaFnGetChildExteriorInUse("HAIR")
	g_nSelectedHairColorUniID = Exterior:LuaFnGetChildExteriorInUse("HAIRCOLOR")
	NewExterior_InfantHairStyle_InitHairStyle()
	NewExterior_InfantHairStyle_InitHairColor()

	PushDebugMessage("#{WGTJ_201222_98}")
end
function NewExterior_InfantHairStyle_Goto()
	AutoRunToTargetEx(348,271,0)
	-- SetAutoRunTargetNPCName("燕如雪")
end

function NewExterior_InfantHairStyle_UpdateRedPoint()
	if Exterior:LuaFnIsHaveExteriorShowTip(7) == 1 then
        NewExterior_InfantHairStyle_HairStyle_Tip:Show()
		return
	end

	if Exterior:LuaFnIsHaveInfantHairColorShowTip() == 1 then
		NewExterior_InfantHairStyle_HairStyle_Tip:Show()
		return
    end

    NewExterior_InfantHairStyle_HairStyle_Tip:Hide()
end