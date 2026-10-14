--NewExterior_InfantDressBox.lua
--!!!reloadscript =NewExterior_InfantDressBox
--2020Q4 新图鉴子女时装
local g_Frame_UnifiedPosition
local g_nSelectedFashionIndex = 0
local g_nSelectedFashionUniID = 0

local NewExterior_InfantDressBox_CameraHeight = 1		--摄影机高度
local NewExterior_InfantDressBox_CameraDistance = 2		--摄影机距离
local NewExterior_InfantDressBox_CameraPitch = 3			--摄影机角度
local g_NewExterior_InfantDressBox_CameraLevel = 0
local g_NewExterior_InfantDressBox_CameraPosition =
{
	[0] = {fHeight = 0.6, fDistance = 4, },
	[1] = {fHeight = 0.6, fDistance = 5, },
	[2] = {fHeight = 0.6, fDistance = 6, }, 
}

local m_fashionDepotType = 2
local g_InitList = 0
local g_MaxBarNum = 200
local g_BarList = {}
local g_ChildFashionInfoList = {}

--===============================================
-- OnLoad()
--===============================================
function NewExterior_InfantDressBox_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_EXTERIOR_FASHION")
	this:RegisterEvent("UPDATE_EXTERIOR_FASHION", false)
	this:RegisterEvent("UPDATE_INFANT_CARD", false)
	this:RegisterEvent("REFRESH_INFANT_HAIRCOLOR",false)
	this:RegisterEvent("REFRESH_INFANT_HAIRSTYLE",false)
	this:RegisterEvent("UPDATE_INFANT_EXTERIORSETINFO", false)
	this:RegisterEvent("UPDATE_EXTERIOR_TIP", false)
	this:RegisterEvent("EXTERIOR_FASHION_OP", false)
end
function NewExterior_InfantDressBox_OnLoad()
	g_Frame_UnifiedPosition = NewExterior_InfantDressBox_Frame:GetProperty("UnifiedPosition")
	NewExterior_InfantDressBox_HairStyle_LeftBtn:SetProperty("Empty", "FALSE")
	NewExterior_InfantDressBox_HairStyle_LeftBtn:SetProperty("UseDefaultTooltip", "True")
	NewExterior_InfantDressBox_Dress_Tip:Hide()
	NewExterior_InfantDressBox_Dress_LockImg:Hide()
end

--===============================================
-- OnEvent()
--===============================================
function NewExterior_InfantDressBox_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		NewExterior_InfantDressBox_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		NewExterior_InfantDressBox_OnHide()
	elseif event == "OPEN_EXTERIOR_FASHION" and tonumber(arg0) == 2 then
		local InfantCount = Infant:GetInfantCount();
		if InfantCount <= 0 then
			PushDebugMessage("#{WGTJ_201222_99}");
			return 
		end
		if Infant:GetInfantLevel(0) < 91 then 
			PushDebugMessage("#{WGTJ_201222_100}");
			return
		end
		if tonumber(arg1) == 1 then 
			Exterior:LuaFnSetCurrentChildExteriorSetInfo("RESET", 0)
			g_nSelectedFashionUniID = -1
		end
		NewExterior_InfantDressBox_OnShow()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15830001 ) then
		if this:IsVisible() then
			return
		end
		NewExterior_InfantDressBox_OnShow()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 80081701 ) then
		if this:IsVisible() then
			NewExterior_InfantDressBox_CloseClick()
			return
		end
	elseif event=="UPDATE_INFANT_CARD" then
		-- 更新子女图鉴时(穿上和卸下) 之前会在 GCUseInfantCardResult 
		-- 这个消息发送 UPDATE_EXTERIOR_FASHION 更新
	elseif event == "UPDATE_EXTERIOR_FASHION" and tonumber(arg0) == 2 then 
		-- 子女时装有更改 主动刷一下列表(列表最后的默认选中会更新左侧状态和模型)
		if tonumber(arg1) == 1 then 
			g_nSelectedFashionUniID = -1  --退出预览状态
			Infant:ClearFittingProperty()
		end
		NewExterior_InfantDressBox_Init()
	elseif event == "REFRESH_INFANT_HAIRCOLOR" and tonumber(arg0) == 1 then
		-- 子女发色有更改 主动刷一下左侧状态和模型
		Exterior:LuaFnSetCurrentChildExteriorSetInfo("HAIRCOLOR", -1)
		-- NewExterior_InfantDressBox_UpdateLeftAction()
	elseif event == "REFRESH_INFANT_HAIRSTYLE" and tonumber(arg0) == 1 then
		-- 子女发型有更改 主动刷一下左侧状态和模型
		Exterior:LuaFnSetCurrentChildExteriorSetInfo("HAIR", -1)
		-- NewExterior_InfantDressBox_UpdateLeftAction()
	elseif  event=="UPDATE_INFANT_EXTERIORSETINFO" then 
		-- 选中展示物品进行模型展示
		NewExterior_InfantDressBox_UpdateLeftAction()
		NewExterior_InfantDressBox_Init()
	elseif event == "UPDATE_EXTERIOR_TIP" then 
		NewExterior_InfantDressBox_UpdateRedPoint()
	elseif event == "EXTERIOR_FASHION_OP" then
		if tonumber(arg0) ~= 2 then return end
		if not this:IsVisible() then return end
		if tonumber(arg1) == 2 then 
			-- enFashionDepotOPType_BagMoveToDressBox 背包拖拽存入衣柜
			local nSourcePos = tonumber(arg2)
			local targetPos = tonumber(arg3)
			local theAction, bLocked, bProtect, nElapsedTime = PlayerPackage:EnumItem("base", nSourcePos);
			if theAction:GetID() ~= 0  then 
				local opResult = FashionDepot:LuaFnJudgeBagItem(2, nSourcePos)
				if opResult == 100 then --不是子女时装
					PushDebugMessage("#{HCG_190117_32}")
					return
				end
				
				if opResult == 102 then --解除锁定倒计时中 -使用了二级密码进行了解锁 需要二次确认
					PushEvent("EXTERIOR_INFANT_CONFIRM", 1000, 2, 1, nSourcePos, targetPos) --二次确认
					return
				end
				
				--计时时装 
				if opResult == 101 or opResult == 1 then 
					Exterior:LuaFnExteriorFashionOperation(2, 1, nSourcePos, targetPos)
				end
			end
		elseif tonumber(arg1) == 3 then 
			-- enFashionDepotOPType_Move 衣柜内拖拽
			local nSourcePos = tonumber(arg2)
			local targetPos = tonumber(arg3)
			if nSourcePos == targetPos then --相同格子不用进行移动
				return
			end
			Exterior:LuaFnExteriorFashionOperation(2, 3, nSourcePos, targetPos)
		elseif tonumber(arg1) == 4 then 
			-- enFashionDepotOPType_TakeOut 衣柜内拖拽到背包
			local nSourcePos = tonumber(arg2)
			local targetPos = tonumber(arg3)
			local theAction, bLocked, bProtect, nElapsedTime = PlayerPackage:EnumItem("base", targetPos);
			if theAction:GetID() ~= 0  then 
				local opResult = FashionDepot:LuaFnJudgeBagItem(2, targetPos)
				if opResult == 100 then --不是子女时装
					PushDebugMessage("#{HCG_190117_32}")
					return
				end
				
				if opResult == 102 then --解除锁定倒计时中 -使用了二级密码进行了解锁 需要二次确认
					PushEvent("EXTERIOR_INFANT_CONFIRM", 1000, 2, 2, nSourcePos, targetPos) --二次确认
					return
				end
				
				--计时时装 
				if opResult == 101 or opResult == 1 then 
					Exterior:LuaFnExteriorFashionOperation(2, 2, nSourcePos, targetPos)
				end
			else
				Exterior:LuaFnExteriorFashionOperation(2, 2, nSourcePos, targetPos)
			end
		elseif tonumber(arg1) == 6 then 
			NewExterior_InfantDressBox_SuperListArrangeBtn:Disable()
		elseif tonumber(arg1) == 7 then 
			NewExterior_InfantDressBox_SuperListArrangeBtn:Enable()
			NewExterior_InfantDressBox_Init()
		end

	end
end
function NewExterior_InfantDressBox_OnHide()
	if IsWindowShow("NewExterior_InfantHairStyle") then
	else	
		Infant:ClearFittingProperty()
	end	
	NewExterior_InfantDressBox_SetPosition()
	NewExterior_InfantDressBox_FakeObject:SetFakeObject("")
	this:Hide()
end
function NewExterior_InfantDressBox_OnShow()
	NewExterior_InfantDressBox_SetPosition()
	g_NewExterior_InfantDressBox_CameraLevel = 0

	NewExterior_InfantDressBox_Init()
	NewExterior_InfantDressBox_UpdateModel()
	NewExterior_InfantDressBox_UpdateRedPoint()
	this:Show()
end
function NewExterior_InfantDressBox_CloseClick()
	Exterior:LuaFnSetCurrentChildExteriorSetInfo("RESET", 0)
	NewExterior_InfantDressBox_OnHide()
end
--===============================================
-- 左侧Action逻辑
--===============================================
function NewExterior_InfantDressBox_UpdateLeftAction()
	local uiLeftDressAction = NewExterior_InfantDressBox_Dress_LeftBtn
	local uiLeftDressLock = NewExterior_InfantDressBox_Dress_ActionImg
	local uiLeftHairStyleAction = NewExterior_InfantDressBox_HairStyle_LeftBtn
	local uiLeftHairStyleLock = NewExterior_InfantDressBox_HairStyle_ActionImg
	local uiLeftHairStyleMask = NewExterior_InfantDressBox_HairStyle_LockImg

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

function NewExterior_InfantDressBox_LeftDressClick()
	local useIndex = Exterior:LuaFnGetChildExteriorInUse("FASHION")
	local setIndex = Exterior:LuaFnGetCurrentChildExteriorSetInfo("FASHION")
	if setIndex >= 0 then 
		g_nSelectedFashionUniID = -1
		Exterior:LuaFnSetCurrentChildExteriorSetInfo("FASHION", -1)
	elseif useIndex >= 0 then 
		Exterior:LuaFnUnUseChildExteriorFashion(2)
	end
end

--===============================================
-- 页签逻辑
--===============================================
	function NewExterior_InfantDressBox_SetPosition()
		local nExteriorUnionPos = Variable:GetVariable("ExteriorUnionPos")
		if nExteriorUnionPos ~= nil then
			NewExterior_InfantDressBox_Frame:SetProperty("UnifiedPosition", nExteriorUnionPos)
		end
	end
	function NewExterior_InfantDressBox_SavePosition()
		Variable:SetVariable("ExteriorUnionPos", NewExterior_InfantDressBox_Frame:GetProperty("UnifiedPosition"), 1)
	end

	function NewExterior_InfantDressBox_OpenFashion()
		local useIndex = Exterior:LuaFnGetChildExteriorInUse("FASHION")
		Exterior:LuaFnExteriorFashionDepotItemClick(m_fashionDepotType, useIndex)

	end

	function NewExterior_InfantDressBox_OpenHair()
		NewExterior_InfantDressBox_SavePosition()
		NewExterior_InfantDressBox_FakeObject:SetFakeObject("")
		-- 打开子女发型界面
		Exterior:LuaFnAskOpenExterior(7)
	end
	function NewExterior_InfantDressBox_GoBack()
		NewExterior_InfantDressBox_SavePosition()
		-- 返回人物时装界面
		PushEvent("OPEN_EXTERIOR_FASHION", 1, 1)
	end
--===============================================
-- 模型缩放转向逻辑
--===============================================
	function NewExterior_InfantDressBox_UpdateZoomButton()
		-- NewExterior_InfantDressBox_Model_Plus:Enable()
		-- NewExterior_InfantDressBox_Model_Subtract:Enable()
		
		-- if g_NewExterior_InfantDressBox_CameraLevel == 0 then 
		-- 	NewExterior_InfantDressBox_Model_Plus:Disable()
		-- elseif g_NewExterior_InfantDressBox_CameraLevel == 2 then
		-- 	NewExterior_InfantDressBox_Model_Subtract:Disable()
		-- end
	end
	function NewExterior_InfantDressBox_SetCameraPosition()
		if g_NewExterior_InfantDressBox_CameraLevel > -1 and g_NewExterior_InfantDressBox_CameraLevel < 3 then
			FakeObj_SetCamera( "Special_Infant_7", NewExterior_InfantDressBox_CameraHeight, g_NewExterior_InfantDressBox_CameraPosition[g_NewExterior_InfantDressBox_CameraLevel].fHeight )
			FakeObj_SetCamera( "Special_Infant_7", NewExterior_InfantDressBox_CameraDistance, g_NewExterior_InfantDressBox_CameraPosition[g_NewExterior_InfantDressBox_CameraLevel].fDistance )
			FakeObj_RestoreCamera( "Special_Infant_7" )
		end
	end
	function NewExterior_InfantDressBox_ZoomIn()
		if g_NewExterior_InfantDressBox_CameraLevel < 1  or g_NewExterior_InfantDressBox_CameraLevel > 2 then
			return
		end
		
		g_NewExterior_InfantDressBox_CameraLevel = g_NewExterior_InfantDressBox_CameraLevel - 1
		NewExterior_InfantDressBox_SetCameraPosition()
		NewExterior_InfantDressBox_UpdateZoomButton()
	end
	function NewExterior_InfantDressBox_ZoomOut()
		if g_NewExterior_InfantDressBox_CameraLevel < 0  or g_NewExterior_InfantDressBox_CameraLevel > 1 then
			return
		end
		
		g_NewExterior_InfantDressBox_CameraLevel = g_NewExterior_InfantDressBox_CameraLevel + 1
		NewExterior_InfantDressBox_SetCameraPosition()
		NewExterior_InfantDressBox_UpdateZoomButton()
	end
	function NewExterior_InfantDressBox_TurnRight(start)
		local mouse_button = CEArg:GetValue("MouseButton");
		if(mouse_button == "LeftButton") then
			--向右旋转开始
			if(start == 1) then
				NewExterior_InfantDressBox_FakeObject:RotateBegin(0.3);
			--向右旋转结束
			else
				NewExterior_InfantDressBox_FakeObject:RotateEnd();
			end
		end
	end
	function NewExterior_InfantDressBox_TurnLeft(start)
		local mouse_button = CEArg:GetValue("MouseButton");
		if(mouse_button == "LeftButton") then
			--向左旋转开始
			if(start == 1) then
				NewExterior_InfantDressBox_FakeObject:RotateBegin(-0.3);
			--向左旋转结束
			else
				NewExterior_InfantDressBox_FakeObject:RotateEnd();
			end
		end
	end
	function NewExterior_InfantDressBox_UpdateModel()
		NewExterior_InfantDressBox_FakeObject:SetFakeObject("")
		Infant:SetSpecialObjProperty(7,"CopyFrom","0")
		Infant:SetSpecialObjProperty(7,"Dir","0.0")
		
		--强制成年模式
		local s = Infant:GetInfantSex(0)
		if s == 0 then
			Infant:SetSpecialObjProperty(7,"RaceId","16542")
		else
			Infant:SetSpecialObjProperty(7,"RaceId","16543")
		end
		
		NewExterior_InfantDressBox_FakeObject:SetFakeObject( "Special_Infant_7" )

		NewExterior_InfantDressBox_SetCameraPosition()
		NewExterior_InfantDressBox_UpdateZoomButton()
	end
--===============================================
-- 功能逻辑
--===============================================
function NewExterior_InfantDressBox_Init()
	-- 初始化UI列表
	if g_InitList == 0 then 
		NewExterior_InfantDressBox_SuperList:Clear()
		for i=1,g_MaxBarNum do 
			local bar = NewExterior_InfantDressBox_SuperList:AddChild("NewExterior_InfantDressBox_SuperListItem")
			bar:GetSubItem("NewExterior_InfantDressBox_SuperListItemAction"):SetEvent("Clicked", string.format("NewExterior_InfantDressBox_OnFashionClick(%d)", i))
			bar:GetSubItem("NewExterior_InfantDressBox_SuperListItemAction"):SetEvent("RBClicked", string.format("NewExterior_InfantDressBox_OnTakeOutClick(%d)", i))
			bar:GetSubItem("NewExterior_InfantDressBox_SuperListItemAction"):SetProperty("DraggingEnabled", "True")
			bar:GetSubItem("NewExterior_InfantDressBox_SuperListItemAction"):SetProperty("DragAcceptName", "k"..tostring(i-1))
			local tabInfo = {}
			tabInfo.uiBar = bar
			tabInfo.uiAction = bar:GetSubItem("NewExterior_InfantDressBox_SuperListItemAction")
			tabInfo.uiActionImgTime = bar:GetSubItem("NewExterior_InfantDressBox_SuperListItemActionImgTime")
			tabInfo.uiActionImgTip = bar:GetSubItem("NewExterior_InfantDressBox_SuperListItemActionTip")
			tabInfo.uiActionImgView = bar:GetSubItem("NewExterior_InfantDressBox_SuperListItemActionImgView")
			tabInfo.uiActionImgDef = bar:GetSubItem("NewExterior_InfantDressBox_SuperListItemActionImgDef")
			tabInfo.uiActionLock = bar:GetSubItem("NewExterior_InfantDressBox_SuperListItemActionLock")
			table.insert(g_BarList, tabInfo)
		end
		g_InitList = 1
	end
	-- PushDebugMessage("NewExterior_InfantDressBox_Init:"..Exterior:LuaFnGetChildExteriorInUse("FASHION")..":"..Exterior:LuaFnGetCurrentChildExteriorSetInfo("FASHION"))
	-- 填充解锁子女时装数据
	g_ChildFashionInfoList = {}
	for i=1,g_MaxBarNum do 
		local nVecIndex = i-1
		local nExteriorID = FashionDepot:LuaFnGetFashionId(m_fashionDepotType, nVecIndex)
		if nExteriorID and nExteriorID > 0 then
			local tabInfo = {}
			tabInfo.nVecIndex = nVecIndex
			tabInfo.nExteriorID = nExteriorID
			if tabInfo.nVecIndex==Exterior:LuaFnGetChildExteriorInUse("FASHION") then 
				tabInfo.bDressUp = 1
			else
				tabInfo.bDressUp = 0
			end
			local bOk, ItemTableIndex, VisualId, DressName, nRare, szRareDesc = Infant:GetInfantExteriorItemInfo(nVecIndex)
			tabInfo.nVisualId = VisualId
			-- table.insert(g_ChildFashionInfoList, tabInfo)
			g_ChildFashionInfoList[i] = tabInfo
		end
	end
	-- 排序
	-- table.sort(g_ChildFashionInfoList, function(a,b)
	-- 		if a.bDressUp ~= b.bDressUp then 
	-- 			return a.bDressUp > b.bDressUp
	-- 		end
	-- 		if a.nExteriorID ~= b.nExteriorID then 
	-- 			return a.nExteriorID > b.nExteriorID
	-- 		end
	-- 		return a.nVecIndex < b.nVecIndex
	-- 	end)
	-- 显示
	local nSelectIndex = -1
	for i=1,g_MaxBarNum do 
		local tabUI = g_BarList[i]
		tabUI.uiAction:SetActionItem(-1)
		tabUI.uiActionImgTime:Hide()
		tabUI.uiActionImgTip:Hide()
		tabUI.uiActionImgView:Hide()
		tabUI.uiActionImgDef:Hide()
		tabUI.uiActionLock:Hide()
		local tabInfo = g_ChildFashionInfoList[i]
		if tabInfo then 
			local nVecIndex = tabInfo.nVecIndex
			local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(m_fashionDepotType, nVecIndex)
			tabUI.uiAction:SetActionItem(theAction:GetID())
			if nVecIndex == g_nSelectedFashionUniID then 
				nSelectIndex = i
			end
			if tabInfo.bDressUp == 1 then 
				tabUI.uiActionImgDef:Show()
			end
		end
	end
	NewExterior_InfantDressBox_OnFashionClick(nSelectIndex)
end
function NewExterior_InfantDressBox_OnFashionClear()
	if g_nSelectedFashionIndex > 0 then 
		g_BarList[g_nSelectedFashionIndex].uiAction:SetPushed(0)
		g_BarList[g_nSelectedFashionIndex].uiActionImgView:Hide()
	end
	g_nSelectedFashionIndex = -1
	g_nSelectedFashionUniID = -1
end

function NewExterior_InfantDressBox_MakeHyperlink(nVecIndex)
	local ret = Exterior:LuaFnExteriorFashionDepotItemClick(m_fashionDepotType, nVecIndex)
	return ret
end

function NewExterior_InfantDressBox_OnFashionClick(nIndex)
	if nIndex == -1 then 
		NewExterior_InfantDressBox_OnFashionClear()
		Exterior:LuaFnSetCurrentChildExteriorSetInfo("FASHION", -1)
	end

	local tabInfo = g_ChildFashionInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		return
	end

	if NewExterior_InfantDressBox_MakeHyperlink(tabInfo.nVecIndex) == 1 then
		return
	end

	if g_nSelectedFashionIndex > 0 then 
		g_BarList[g_nSelectedFashionIndex].uiAction:SetPushed(0)
		g_BarList[g_nSelectedFashionIndex].uiActionImgView:Hide()
	end

	g_nSelectedFashionIndex = nIndex
	g_nSelectedFashionUniID = tabInfo.nVecIndex
	g_BarList[nIndex].uiAction:SetPushed(1)
	if tabInfo.nVecIndex ~= Exterior:LuaFnGetChildExteriorInUse("FASHION") then
		g_BarList[nIndex].uiActionImgView:Show()
	end

	Infant:SetSpecialObjProperty(7,"BodyVisual", tostring( tabInfo.nVisualId ) )

	Exterior:LuaFnSetCurrentChildExteriorSetInfo("FASHION", tabInfo.nVecIndex)
end
function NewExterior_InfantDressBox_OnTakeOutClick(nIndex)
	local tabInfo = g_ChildFashionInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		return
	end
	Exterior:LuaFnTakeOutChildExteriorFashion(m_fashionDepotType, tabInfo.nVecIndex)
end
function NewExterior_InfantDressBox_Undo()
	local setIndex_fashion = Exterior:LuaFnGetCurrentChildExteriorSetInfo("FASHION")
	local setIndex_hairstyle = Exterior:LuaFnGetCurrentChildExteriorSetInfo("HAIR")
	local setIndex_haircolor = Exterior:LuaFnGetCurrentChildExteriorSetInfo("HAIRCOLOR")
	if setIndex_fashion<0 and setIndex_hairstyle<0 and setIndex_haircolor<0 then 
		PushDebugMessage("#{WGTJ_201222_76}")
		return
	end
	Exterior:LuaFnSetCurrentChildExteriorSetInfo("RESET", 1)
	NewExterior_InfantDressBox_OnFashionClear()
	Infant:ClearFittingProperty()
	PushDebugMessage("#{WGTJ_201222_98}")
end
function NewExterior_InfantDressBox_DressUp()
	-- local tabInfo = g_ChildFashionInfoList[g_nSelectedFashionIndex]
	-- if not tabInfo or tabInfo.nExteriorID < 0 then 
	-- 	return
	-- end
	-- Exterior:LuaFnUseChildExteriorFashion(m_fashionDepotType, tabInfo.nVecIndex)

	if Exterior:LuaFnIsHaveInfantExteriorChange() == 0 then
		PushDebugMessage("#{WGJM_210104_02}")
		return
	end

	Exterior:LuaFnSaveInfantExteriorAllChange(1)
end
function NewExterior_InfantDressBox_DressBoxToBag()
	local tabInfo = g_ChildFashionInfoList[g_nSelectedFashionIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		PushDebugMessage("#{WGJM_210104_06}")
		return
	end
	Exterior:LuaFnTakeOutChildExteriorFashion(m_fashionDepotType, tabInfo.nVecIndex)
end

function NewExterior_InfantDressBox_UpdateRedPoint()
	if Exterior:LuaFnIsHaveExteriorShowTip(7) == 1 then
        NewExterior_InfantDressBox_HairStyle_Tip:Show()
		return
	end

	if Exterior:LuaFnIsHaveInfantHairColorShowTip() == 1 then
		NewExterior_InfantDressBox_HairStyle_Tip:Show()
		return
    end

    NewExterior_InfantDressBox_HairStyle_Tip:Hide()
end

--整理
function NewExterior_InfantDressBox_ClickClearUpBtn()

	FashionDepot:LuaFnRefreshFashionDepot(2)
end