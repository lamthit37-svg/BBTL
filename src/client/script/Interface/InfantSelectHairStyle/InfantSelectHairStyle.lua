-- InfantSelectHairStyle.lua
-- !!!reloadscript =InfantSelectHairStyle
-- 子女选择发型界面

local InfantSelectHairStyle_CameraHeight = 1		--摄影机高度
local InfantSelectHairStyle_CameraDistance = 2		--摄影机距离
local InfantSelectHairStyle_CameraPitch = 3			--摄影机角度
local InfantSelectHairStyle_CaredObjId = -1		--关注ncp的ObjId

local g_nSelectedIndex = -1
local g_nSelectedExteriorID = -1
local g_InfantSelectHairStyle_YuanbaoPay=1

local g_ExteriorType = 7	--子女发型
local g_MaxBarNum = 0
local g_UIList = {} 
local g_InfoList = {} --所有图鉴信息

local g_InfantSelectHairStyle_CameraLevel = 0
local g_InfantSelectHairStyle_CameraPosition =
{
	[0] = {fHeight = 1.09, fDistance = 1.30, },
	[1] = {fHeight = 0.90, fDistance = 2.30, },
	[2] = {fHeight = 0.63, fDistance = 3.30, }, 
}

function InfantSelectHairStyle_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

this:RegisterEvent("PROGRESSBAR_SHOW")
	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_WINDOW")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("ADD_EXTERIOR", false)
	this:RegisterEvent("REFRESH_INFANT_HAIRSTYLE", false)
end

function InfantSelectHairStyle_OnLoad()
end

function InfantSelectHairStyle_OnEvent( event )
	if event == "UI_COMMAND" and tonumber(arg0) == 890987 then
		if( Get_XParam_INT_Count() < 1 ) then
			return
		end
		
		local servid = Get_XParam_INT(0)
		if servid == -1 then
			InfantSelectHairStyle_OnHiden()
			return
		end
		
		InfantSelectHairStyle_CaredObjId = DataPool:GetNPCIDByServerID(servid)
		if InfantSelectHairStyle_CaredObjId == -1 then
			return
		end
		this:CareObject( InfantSelectHairStyle_CaredObjId, 1, "InfantSelectHairStyle" )
		
		if not this:IsVisible() then
			--yuanbaoPay
			if g_InfantSelectHairStyle_YuanbaoPay == 1 or g_InfantSelectHairStyle_YuanbaoPay == 0 then
				InfantSelectHairStyle_Blank_Queren:SetCheck(g_InfantSelectHairStyle_YuanbaoPay)
			end
			InfantSelectHairStyle_OnShow()
		end
		
		if IsWindowShow("InfantSelectHairColor") then
			CloseWindow("InfantSelectHairColor", true)
		end
		
		InfantSelectHairStyle_UpdateItems()
	elseif event == "OBJECT_CARED_EVENT" then
		if not this:IsVisible() then
			return
		end
		if tonumber(arg0) ~= InfantSelectHairStyle_CaredObjId then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if ( arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE ) or arg1=="destroy" then
			InfantSelectHairStyle_OnHiden()
		end
	elseif event == "ADD_EXTERIOR" and tonumber(arg0) == g_ExteriorType then 
		if not this:IsVisible() then return end
		-- InfantSelectHairStyle_UpdateItems()
	elseif event == "REFRESH_INFANT_HAIRSTYLE" and tonumber(arg0) == 1 then
		if not this:IsVisible() then return end
		InfantSelectHairStyle_UpdateItems()
	end
end

-- 
function InfantSelectHairStyle_OnShow()
	this:Show()
	g_nSelectedIndex = -1
	g_InfantSelectHairStyle_CameraLevel = 0
	InfantSelectHairStyle_SetCameraPosition()
	InfantSelectHairStyle_UpdateModel()
	InfantSelectHairStyle_UpdateZoomButton()
end
function InfantSelectHairStyle_Blank_Queren_Clicked() 
	g_InfantSelectHairStyle_YuanbaoPay = InfantSelectHairStyle_Blank_Queren:GetCheck();
end

function InfantSelectHairStyle_UpdateItems()
	InfantSelectHairStyle_Notice:SetText("")
	-- 初始化所有图鉴信息
	InfantSelectHairStyle_StyleList:Clear()
	g_UIList = {}
	g_InfoList = {}
	Exterior:LuaFnInitExteriorList(g_ExteriorType)
	g_MaxBarNum = Exterior:LuaFnGetExteriorListCount(g_ExteriorType, 0)
	for i=1,g_MaxBarNum do 
		local nExteriorId = Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, i-1)
		local nRet, nHairId, strName, nVisibleID, nItemID, nCost, strIconName = Exterior:LuaFnGetExteriorChildHairStyleInfo(nExteriorId)
		local bar = InfantSelectHairStyle_StyleList:AddChild("InfantSelectHairStyle_SuperListItem")
		bar:GetSubItem("InfantSelectHairStyle_Style1"):SetEvent("MouseLButtonDown", string.format("InfantSelectHairstyle_Clicked(%d)", i))
		-- bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
		local tabInfo = {}
		tabInfo.uiBar = bar	
		tabInfo.uiAction = bar:GetSubItem("InfantSelectHairStyle_Style1")
		tabInfo.uiLock = bar:GetSubItem("InfantSelectHairStyle_SuperListItemActionLock1")
		tabInfo.uiDef = bar:GetSubItem("InfantSelectHairstyle_SuperListItemActionDef1")
		tabInfo.uiView = bar:GetSubItem("InfantSelectHairStyle_SuperListItemActionTry1")

		table.insert( g_UIList, tabInfo )
		table.insert( g_InfoList, {} )
	end
	for i=1,g_MaxBarNum do 
		local nExteriorId = Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, i-1)
		local nRet, nHairId, strName, nVisibleID, nItemID, nCost, strIconName = Exterior:LuaFnGetExteriorChildHairStyleInfo(nExteriorId)
		g_InfoList[i].nIndex = i
		g_InfoList[i].nExteriorId = nExteriorId
		g_InfoList[i].nHairId = nHairId
		g_InfoList[i].nVisibleID = nVisibleID
		g_InfoList[i].nCost = nCost
		g_InfoList[i].strIconName = strIconName
		g_InfoList[i].strName = strName
		if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorId) == 1 then
			g_InfoList[i].isUnLock = 1	
		else
			g_InfoList[i].isUnLock = 0
		end
		if nExteriorId==Exterior:LuaFnGetChildExteriorInUse("HAIR") then 
			g_InfoList[i].bDressUp = 1
		else
			g_InfoList[i].bDressUp = 0
		end
	end
	-- 排序
	table.sort(g_InfoList, function(a, b)
			if a.bDressUp ~= b.bDressUp then 
				return a.bDressUp > b.bDressUp
			end
			if a.isUnLock ~= b.isUnLock then
				return a.isUnLock > b.isUnLock
			end
			return a.nExteriorId < b.nExteriorId
		end)
	-- 刷新UI信息展示
	g_nSelectedIndex = -1
	for i, v in pairs(g_InfoList) do
		local tabUIInfo = g_UIList[i]
		local IconFile = GetIconFullName( v.strIconName )
		tabUIInfo.uiAction:SetProperty( "NormalImage", IconFile )
		tabUIInfo.uiAction:SetProperty( "HoverImage", IconFile )
		tabUIInfo.uiAction:SetToolTip( v.strName )	
		tabUIInfo.uiLock:Hide()
		tabUIInfo.uiDef:Hide()
		tabUIInfo.uiView:Hide()
		if v.isUnLock == 1 then 
			tabUIInfo.uiLock:Hide()
		else
			tabUIInfo.uiLock:Show()
		end
		if v.nExteriorId == Exterior:LuaFnGetChildExteriorInUse("HAIR") then 
			g_nSelectedIndex = i
			tabUIInfo.uiDef:Show()
		end
	end

	InfantSelectHairstyle_Clicked(g_nSelectedIndex)
end

function InfantSelectHairstyle_Clicked(btn_id)
	local tabInfo = g_InfoList[btn_id]
	if tabInfo then 
		g_nSelectedIndex = btn_id
		for i, v in pairs(g_InfoList) do 
			if v.nExteriorId == tabInfo.nExteriorId then 
				g_UIList[i].uiAction:SetPushed(1)
				if v.nExteriorId ~= Exterior:LuaFnGetChildExteriorInUse("HAIR") then 
					g_UIList[i].uiView:Show()
				end
			else
				g_UIList[i].uiAction:SetPushed(0)
				g_UIList[i].uiView:Hide()
			end
		end
		Infant:SetSpecialObjProperty(7,"HairVisual", tostring( tabInfo.nVisibleID ) )
		Infant:SetFittingProperty( "HairVisual", tostring( tabInfo.nVisibleID ) )
	else
		g_nSelectedIndex = -1
		for i, v in pairs(g_UIList) do
			v.uiAction:SetPushed(0)
			g_UIList[i].uiView:Hide()
		end
	end
	
	if g_nSelectedIndex >= 0 then
		if tabInfo.isUnLock ==1 then 
			if tabInfo.nExteriorId == Exterior:LuaFnGetChildExteriorInUse("HAIR") then 
				InfantSelectHairStyle_Text : SetText("#{WGTJ_210112_14}")
			else
				InfantSelectHairStyle_Text : SetText("#{GXHDZ_141121_21}")
			end
			InfantSelectHairStyle_Accept:SetText("更换")
		else
			local ShowMsg = string.format("%s1\n%s#{_EXCHG%d}\n%s",
				"#{ZNSZ_140718_40}",
				"#{ZNSZ_140718_41}", tabInfo.nCost,
				"#{ZNSZ_140718_42}"
				)
				
			InfantSelectHairStyle_Text:SetText(ShowMsg)
			InfantSelectHairStyle_Accept:SetText("确定")
		end
	else
		InfantSelectHairStyle_Text:SetText("#{ZNSZ_140718_42}")
		InfantSelectHairStyle_Accept:SetText("确定")
	end
end

function InfantSelectHairStyle_UpdateModel()

	InfantSelectHairStyle_Model:SetFakeObject("")
	Infant:SetSpecialObjProperty(7,"CopyFrom","0")
	Infant:SetSpecialObjProperty(7,"Dir","0.0")
	
	--强制成年模式
	local s = Infant:GetInfantSex(0)
	if s == 0 then
		Infant:SetSpecialObjProperty(7,"RaceId","16542")
	else
		Infant:SetSpecialObjProperty(7,"RaceId","16543")
	end
	
	InfantSelectHairStyle_Model:SetFakeObject( "Special_Infant_7" )
	
	FakeObj_SetCamera( "Special_Infant_7", InfantSelectHairStyle_CameraHeight, 1.09 )
	FakeObj_SetCamera( "Special_Infant_7", InfantSelectHairStyle_CameraDistance, 1.30 )
	
	FakeObj_RestoreCamera( "Special_Infant_7" )
end

function InfantSelectHairStyle_OnHiden()
	InfantSelectHairStyle_Model:SetFakeObject("")
	this:Hide()
end

function InfantSelectHairStyle_Model_OnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton")
	if mouse_button == "LeftButton" then
		--向左旋转开始
		if(start == 1) then
			InfantSelectHairStyle_Model:RotateBegin(-0.3)
		--向左旋转结束
		else
			InfantSelectHairStyle_Model:RotateEnd()
		end
	end
end

function InfantSelectHairStyle_Model_OnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton")
	if mouse_button == "LeftButton" then
		--向右旋转开始
		if(start == 1) then
			InfantSelectHairStyle_Model:RotateBegin(0.3)
		--向右旋转结束
		else
			InfantSelectHairStyle_Model:RotateEnd()
		end
	end
end

function InfantSelectHairStyle_OnHiden_Internel()
	Infant:ClearFittingProperty()
	InfantSelectHairStyle_Model:SetFakeObject("")
	g_nSelectedIndex = -1
	g_nPage = 0
	if InfantSelectHairStyle_CaredObjId ~= -1 then
		this:CareObject(InfantSelectHairStyle_CaredObjId, 0, "InfantSelectHairStyle")
		InfantSelectHairStyle_CaredObjId = -1
	end
end

function InfantSelectHairStyle_OnOk()
	
	if g_nSelectedIndex < 0 then
		PushDebugMessage("#{ZNSZ_140718_43}")
		return
	end
	
	local tabInfo = g_InfoList[g_nSelectedIndex]
	if not tabInfo then 
		PushDebugMessage("InfantSelectHairStyle_OnOk: tabInfo nil:"..(g_nSelectedIndex or "nil"))
		return
	end

	local MyHairStyle = Infant:GetInfantHairStyle(0)
	if not MyHairStyle then
		return
	end
	
	if MyHairStyle == -1 then
		MyHairStyle = 20000
	end
	
	if MyHairStyle == tabInfo.nVisibleID then
		PushDebugMessage("#{ZNSZ_140718_44}")
		return
	end
	
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZNSZ_140718_46}")
		return
	end
	
	local playerMoney = Player:GetData("MONEY")
	local playerJZ = Player:GetData("MONEY_JZ")
	if tabInfo.isUnlock==0 and playerJZ + playerMoney < tabInfo.nCost then
		PushDebugMessage("#{ZNSZ_140718_47}")
		return 
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnChangeInfantHairStype")
		Set_XSCRIPT_ScriptID(890987)
		Set_XSCRIPT_Parameter(0,tabInfo.nExteriorId)
		Set_XSCRIPT_Parameter(1,g_InfantSelectHairStyle_YuanbaoPay)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
end

function InfantSelectHairStyle_OnCancel()
	InfantSelectHairStyle_OnHiden()
end

function InfantSelectHairStyle_UpdateZoomButton()
	-- InfantSelectHairStyle_Plus:Enable()
	-- InfantSelectHairStyle_Subtract:Enable()

	-- if g_InfantSelectHairStyle_CameraLevel == 0 then 
	-- 	InfantSelectHairStyle_Plus:Disable()
	-- elseif g_InfantSelectHairStyle_CameraLevel == 2 then
	-- 	InfantSelectHairStyle_Subtract:Disable()
	-- end
end
function InfantSelectHairStyle_SetCameraPosition()
	if g_InfantSelectHairStyle_CameraLevel > -1 and g_InfantSelectHairStyle_CameraLevel < 3 then
		FakeObj_SetCamera( "Special_Infant_7", InfantSelectHairStyle_CameraHeight, g_InfantSelectHairStyle_CameraPosition[g_InfantSelectHairStyle_CameraLevel].fHeight )
		FakeObj_SetCamera( "Special_Infant_7", InfantSelectHairStyle_CameraDistance, g_InfantSelectHairStyle_CameraPosition[g_InfantSelectHairStyle_CameraLevel].fDistance )
		FakeObj_RestoreCamera( "Special_Infant_7" )
	end
end
function InfantSelectHairStyle_ZoomIn()
	if g_InfantSelectHairStyle_CameraLevel < 1  or g_InfantSelectHairStyle_CameraLevel > 2 then
		return
	end
	
	g_InfantSelectHairStyle_CameraLevel = g_InfantSelectHairStyle_CameraLevel - 1
	InfantSelectHairStyle_SetCameraPosition()
	InfantSelectHairStyle_UpdateZoomButton()
end
function InfantSelectHairStyle_ZoomOut()
	if g_InfantSelectHairStyle_CameraLevel < 0  or g_InfantSelectHairStyle_CameraLevel > 1 then
		return
	end
	
	g_InfantSelectHairStyle_CameraLevel = g_InfantSelectHairStyle_CameraLevel + 1
	InfantSelectHairStyle_SetCameraPosition()
	InfantSelectHairStyle_UpdateZoomButton()
end
