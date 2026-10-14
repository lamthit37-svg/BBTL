
local g_GemEffectPreview_Frame_UnifiedPosition

local g_CameraPosition =
{
	--女性相关位置
	[0] = {{fHeight = 0.78, fDistance = 12, fPitch=0.2, fXOffset= 0 }, {fHeight = 0.78, fDistance = 7.2, fPitch=0.2, fXOffset= 0 },
	       {fHeight = 1.55, fDistance = 2.5, fPitch=0.20, fXOffset= 0 }, {fHeight = 1.55, fDistance = 1.7, fPitch=0.20, fXOffset= 0 }},
	--男性相关位置
	[1] = {{fHeight = 0.78, fDistance = 12, fPitch=0.28, fXOffset= 0 }, {fHeight = 0.78, fDistance = 7.5, fPitch=0.28, fXOffset= 0 }, 
	       {fHeight = 1.65, fDistance = 2.7, fPitch=0.28, fXOffset= 0 }, {fHeight = 1.70, fDistance = 1.9, fPitch=0.28, fXOffset= 0 }},
}

local g_CameraPosition_IV =
{
	--女性相关位置
	[0] = {{fHeight = 0.78, fDistance = 12, fPitch=0.2, fXOffset= 0 }, {fHeight = 0.78, fDistance = 7.2, fPitch=0.2, fXOffset= 0 },
	       {fHeight = 1.55, fDistance = 2.5, fPitch=0.10, fXOffset= 0 }, {fHeight = 1.62, fDistance = 1.8, fPitch=0.10, fXOffset= 0 }},
	--男性相关位置
	[1] = {{fHeight = 0.78, fDistance = 12, fPitch=0.28, fXOffset= 0 }, {fHeight = 0.78, fDistance = 7.5, fPitch=0.28, fXOffset= 0 }, 
	       {fHeight = 1.70, fDistance = 2.7, fPitch=0.05, fXOffset= 0 }, {fHeight = 1.78, fDistance = 1.9, fPitch=0.05, fXOffset= 0 }},
}

local g_SpecialCameraParam =
{
	[50231019] = 
	{
		[0] = {{fHeight = 0.78, fDistance = 12, fPitch=0.2, fXOffset= 0 }, {fHeight = 0.78, fDistance = 7.2, fPitch=0.2, fXOffset= 0 },
			   {fHeight = 1.55, fDistance = 2.5, fPitch=0.20, fXOffset= 0 }, {fHeight = 1.55, fDistance = 1.7, fPitch=0.20, fXOffset= 0 }},
		[1] = {{fHeight = 0.78, fDistance = 12, fPitch=0.28, fXOffset= 0 }, {fHeight = 0.78, fDistance = 7.5, fPitch=0.28, fXOffset= 0 }, 
			   {fHeight = 1.65, fDistance = 2.7, fPitch=0.28, fXOffset= 0 }, {fHeight = 1.70, fDistance = 1.9, fPitch=0.28, fXOffset= 0 }},
	},
	[50232019] = 
	{
		[0] = {{fHeight = 0.78, fDistance = 12, fPitch=0.2, fXOffset= 0 }, {fHeight = 0.78, fDistance = 7.2, fPitch=0.2, fXOffset= 0 },
			   {fHeight = 1.55, fDistance = 2.5, fPitch=0.20, fXOffset= 0 }, {fHeight = 1.55, fDistance = 1.7, fPitch=0.20, fXOffset= 0 }},
		[1] = {{fHeight = 0.78, fDistance = 12, fPitch=0.28, fXOffset= 0 }, {fHeight = 0.78, fDistance = 7.5, fPitch=0.28, fXOffset= 0 }, 
			   {fHeight = 1.65, fDistance = 2.7, fPitch=0.28, fXOffset= 0 }, {fHeight = 1.70, fDistance = 1.9, fPitch=0.28, fXOffset= 0 }},
	},
	[50233019] = 
	{
		[0] = {{fHeight = 0.78, fDistance = 12, fPitch=0.2, fXOffset= 0 }, {fHeight = 0.78, fDistance = 7.2, fPitch=0.2, fXOffset= 0 },
			   {fHeight = 1.55, fDistance = 2.5, fPitch=0.20, fXOffset= 0 }, {fHeight = 1.55, fDistance = 1.7, fPitch=0.20, fXOffset= 0 }},
		[1] = {{fHeight = 0.78, fDistance = 12, fPitch=0.28, fXOffset= 0 }, {fHeight = 0.78, fDistance = 7.5, fPitch=0.28, fXOffset= 0 }, 
			   {fHeight = 1.65, fDistance = 2.7, fPitch=0.28, fXOffset= 0 }, {fHeight = 1.70, fDistance = 1.9, fPitch=0.28, fXOffset= 0 }},
	},
}

local g_sexButtonInfo = {
	[0] = { imgH = "set:DressPreview01 image:DressPreview_Male_Hover", imgN = "set:DressPreview01 image:DressPreview_Male_Normal", imgP = "set:DressPreview01 image:DressPreview_Male_Pushed"  },
	[1] = { imgH = "set:DressPreview01 image:DressPreview_Female_Hover", imgN = "set:DressPreview01 image:DressPreview_Female_Normal", imgP = "set:DressPreview01 image:DressPreview_Female_Pushed"  },
}

local g_previewParam = 1
local g_previewDress = -1
local g_previewDressViusal = 0
local g_previewFace = -1
local g_previewHair = -1

local g_previewGemEffectIndex = -1 --配饰id


local g_curSex = 0
local g_Distance_Max = 4

local g_Distance = 1
local g_IsShowSingleSuit = 0  --默认全展示

local g_DressGemUITalbe = {}
local g_Dress_Gem_Type =
{
	[1] = 31,
	[2] = 32,
	[3] = 33,
}
local g_Dress_Gem_ItemIndex =
{
	[1] = -1,
	[2] = -1,
	[3] = -1,
}
local g_DressGemQuality = {0,0,0}
local g_DressGemType = -1
local g_DressGemGemIdx = -1
local g_DressGemCurIndex = -1

local g_CoboListStr=
{
	[0] = "#{SZZS_240821_12}",
	[1] = "#{SZZS_240821_7}",
	[2] = "#{SZZS_240821_8}",
	[3] = "#{SZZS_240821_9}",
	[4] = "#{SZZS_240821_10}",
}

function GemEffectPreview_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("CLOSE_GEMEFFECTPREVIEW")
	this:RegisterEvent("OPEN_GEMEFFECTPREVIEW")

	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("FASHION_DEPOT_OP", false)				-- 华裳阁
	this:RegisterEvent("OPEN_STALL_SALE", false)
	this:RegisterEvent("MODELID_CHANGE", false)
	this:RegisterEvent("OPEN_EQUIP", false)
	this:RegisterEvent("YIGUI_OPEN", false)
end

function GemEffectPreview_OnLoad() 
	g_GemEffectPreview_Frame_UnifiedPosition = GemEffectPreview_Frame:GetProperty("UnifiedPosition");
	g_DressGemUITalbe = 
	{
		[1]={
			ActionItem = GemEffectPreview_Shoulder_Item,
			ComboList = GemEffectPreview_ShoulderList,
		},
		[2]={
			ActionItem = GemEffectPreview_Waist_Item,
			ComboList = GemEffectPreview_WaistList,
		},
		[3]={
			ActionItem = GemEffectPreview_Foot_Item,
			ComboList = GemEffectPreview_FootList,
		},
	}
end

function GemEffectPreview_ResetParam()
	g_Dress_Gem_ItemIndex ={-1,-1,-1}
	g_DressGemQuality = {0,0,0}
	g_DressGemType = -1
	g_DressGemGemIdx = -1
	g_DressGemCurIndex = -1
end

function GemEffectPreview_OnEvent(event) 
	if event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 2024082101 then
		if( tonumber( IsInStall() ) == 1 ) then
			PushDebugMessage("#{ETQWF_131106_4}")			--摆摊状态无法进行这种操作。
			return
		end		
		GemEffectPreview_ResetParam()
		local hairID, cacheColorValue = Exterior:LuaFnGetCurrentExteriorSetInfo("HAIR")
		g_previewDress,g_previewDressViusal = Exterior:LuaFnGetCurFashionItemIndex()
		g_previewHair = hairID
		g_previewFace = Exterior:LuaFnGetCurrentExteriorSetInfo("FACE")

		if g_previewDress > 0 then
			PushEvent( "CLOSE_DRESSPREVIEW")
			g_previewGemEffectIndex = Get_XParam_INT(0)
			g_IsShowSingleSuit = Get_XParam_INT(1)
			GemEffectPreview_Frame:SetForce()
			GemEffectPreview_Open()
		else
			PushDebugMessage("#{SZZS_240821_1}")
		end
	elseif (event == "OPEN_GEMEFFECTPREVIEW" ) then
		if( tonumber( IsInStall() ) == 1 ) then
			PushDebugMessage("#{ETQWF_131106_4}")			--摆摊状态无法进行这种操作。
			return
		end		
		GemEffectPreview_ResetParam()
		local hairID, cacheColorValue = Exterior:LuaFnGetCurrentExteriorSetInfo("HAIR")
		g_previewDress,g_previewDressViusal = Exterior:LuaFnGetCurFashionItemIndex()
		g_previewHair = hairID
		g_previewFace = Exterior:LuaFnGetCurrentExteriorSetInfo("FACE")

		if g_previewDress > 0 then
			PushEvent( "CLOSE_DRESSPREVIEW")
			g_previewGemEffectIndex = tonumber(arg0) 
			g_IsShowSingleSuit = tonumber(arg1)
			GemEffectPreview_Frame:SetForce()
			GemEffectPreview_Open()
		else
			PushDebugMessage("#{SZZS_240821_1}")
		end
	elseif (event == "ADJEST_UI_POS" ) then
		GemEffectPreview_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		GemEffectPreview_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
		return
	elseif (event == "OPEN_STALL_SALE" ) or ( event == "MODELID_CHANGE" ) then
		if (this:IsVisible()) then 
			this:Hide()
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20120406) then
		-- 不能和变性界面同时存在  还有加一堆其他的互斥
		if (this:IsVisible()) then 
			this:Hide()
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 120203161) then
		if (this:IsVisible()) then 
			this:Hide()
		end
		-- 试衣的时候不能打开角色资料窗口
	elseif ( event == "OPEN_EQUIP" ) then
		if (this:IsVisible()) then 
			this:Hide()
		end
	elseif ( event == "YIGUI_OPEN" ) then
			-- 试衣的时候不能打开衣柜
		if (this:IsVisible()) then 
			this:Hide()
		end
	elseif (event == "FASHION_DEPOT_OP" and tonumber(arg0) == 1) then --华裳阁
		if (this:IsVisible()) then 
			this:Hide()
		end
	elseif (event == "CLOSE_GEMEFFECTPREVIEW") then 
		if (this:IsVisible()) then 
			this:Hide()
		end
	end

end

function GemEffectPreview_Open()
	local IsGemOnDress,DressGemQuality,DressGemType,DressGemGemIdx = DressGem:IsGemOnDressByItemIndex(g_previewGemEffectIndex)
	for i = 1,3 do
		g_DressGemQuality[i] = DressGemQuality
	end
	for i = 1,3 do
		if g_Dress_Gem_Type[i] == DressGemType then
			g_DressGemCurIndex = i
			break
		end
	end
	g_DressGemType = DressGemType
	g_DressGemGemIdx = DressGemGemIdx
	if IsGemOnDress < 1 then
		PushDebugMessage("传入的坠饰参数有问题1")
		return
	else
		local result = 0 
		for i = 1,3 do
			if g_Dress_Gem_Type[i] == DressGemType then
				result = 1
				break
			end
		end 
		if result == 0 then
			PushDebugMessage("传入的坠饰参数有问题2")
			return
		end
	end

	g_curSex = Player:GetMySex()
	GemEffectPreview_ResetCamera()

	local theActionButton_Dress = DataPool:CreateActionItemForShow(g_previewDress, 1)
	if theActionButton_Dress:GetID() ~= 0 then
		GemEffectPreview_DressBtn:SetActionItem(theActionButton_Dress:GetID());
		local nGemName,nGemInfo = DressGem:GetItemNameByProperty( g_DressGemQuality[g_DressGemCurIndex],g_DressGemType,g_DressGemGemIdx)
		local str = ScriptGlobal_Format("#{SZZS_240821_2}",nGemName)
		GemEffectPreview_GemEffectName:SetText( str )
	end	

	--g_previewDressViusal = Exterior:LuaFnGetPreviewDressStdVisualID(g_previewDress)

	GemEffectPreview_UpdateSex()
	GemEffectPreview_InitGemEffect()
	GemEffectPreview_UpdateObj(1)
	GemEffectPreview_UpdateCamera()

	this:Show()
end

function GemEffectPreview_InitGemEffect()
	for i = 1, 3 do
		local ItemID = DressGem:GetIndexIDByProperty( g_DressGemQuality[i], g_Dress_Gem_Type[i], g_DressGemGemIdx)
		
		if (g_IsShowSingleSuit == 0) or (g_IsShowSingleSuit ~= 0 and i==g_DressGemCurIndex) then
			if ItemID ~= nil and ItemID > 0 then
				g_Dress_Gem_ItemIndex[i] = ItemID
				local theAction = DataPool:CreateActionItemForShow(ItemID, 1)
				if theAction:GetID() ~= 0 then
					g_DressGemUITalbe[i].ActionItem:SetActionItem(theAction:GetID())
				end
			end
		else
			g_DressGemUITalbe[i].ActionItem:SetActionItem(-1)
		end

		g_DressGemUITalbe[i].ComboList:ResetList()
		g_DressGemUITalbe[i].ComboList:ResetLastSelectIndex()
		for j = 0 , 4 do 
			g_DressGemUITalbe[i].ComboList:AddTextItem(g_CoboListStr[j] ,j) 
		end
		if (g_IsShowSingleSuit == 0) or (g_IsShowSingleSuit ~= 0 and i==g_DressGemCurIndex) then
			g_DressGemUITalbe[i].ComboList:SetText(g_CoboListStr[g_DressGemQuality[i]])
		else
			g_DressGemUITalbe[i].ComboList:SetText(g_CoboListStr[0])
		end
	end
	
end

function GemEffectPreview_SelectedChanged(gemType)
	-- PushDebugMessage("gemType:"..tostring(gemType))
	-- 参数无效
	if gemType == nil or gemType <= 0 or gemType > table.getn(g_Dress_Gem_Type) then
		return
	end

	-- 获得选项
	local __txt, id = g_DressGemUITalbe[gemType].ComboList:GetCurrentSelect()
	if id == -1 then 
		return
	end
	if id==0 then
		g_DressGemUITalbe[gemType].ActionItem:SetActionItem(-1)
		g_Dress_Gem_ItemIndex[gemType] = -1
	else
		local ItemID = DressGem:GetIndexIDByProperty( id, g_Dress_Gem_Type[gemType], g_DressGemGemIdx)
		g_Dress_Gem_ItemIndex[gemType] = ItemID
		if ItemID ~= nil and ItemID > 0 then
			local theAction = DataPool:CreateActionItemForShow(ItemID, 1)
			if theAction:GetID() ~= 0 then
				g_DressGemUITalbe[gemType].ActionItem:SetActionItem(theAction:GetID())
			end
		end
	end
	GemEffectPreview_UpdateObj(1)
	GemEffectPreview_UpdateCamera()
end

function GemEffectPreview_UpdateSex()
	local charFaceId,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,menpaiid,afterchangesex = Exterior:LuaFnGetFaceStylePreviewInfo(g_previewFace,g_curSex)
	if charFaceId >= 0 then
		GemEffectPreview_FaceBtn:Enable()
		GemEffectPreview_FaceBtn:SetProperty("Empty", "FALSE")
		GemEffectPreview_FaceBtn:SetProperty("UseDefaultTooltip", "True")
		IconFile = GetIconFullName(IconFile)
		GemEffectPreview_FaceBtn:SetProperty("NormalImage", IconFile)
		GemEffectPreview_FaceBtn:SetProperty("HoverImage", IconFile)
		GemEffectPreview_FaceBtn:SetToolTip(StyleName)
	end

	local charHairId,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,menpaiid,afterchangesex = Exterior:LuaFnGetHairStylePreviewInfo(g_previewHair,g_curSex)
	if charHairId >= 0 then
		GemEffectPreview_HairBtn:Enable()
		GemEffectPreview_HairBtn:SetProperty("Empty", "FALSE")
		GemEffectPreview_HairBtn:SetProperty("UseDefaultTooltip", "True")
		IconFile = GetIconFullName(IconFile)
		GemEffectPreview_HairBtn:SetProperty("NormalImage", IconFile)
		GemEffectPreview_HairBtn:SetProperty("HoverImage", IconFile)
		GemEffectPreview_HairBtn:SetToolTip(StyleName)
	end

	GemEffectPreview_GenderChange_Btn:SetProperty("HoverImage", g_sexButtonInfo[g_curSex].imgH)
	GemEffectPreview_GenderChange_Btn:SetProperty("NormalImage", g_sexButtonInfo[g_curSex].imgN)
	GemEffectPreview_GenderChange_Btn:SetProperty("PushedImage", g_sexButtonInfo[g_curSex].imgP)
end

function GemEffectPreview_UpdateObj(param)   --1预览 0取消
	GemEffectPreview_FakeObject:DetachWindowEx()
	GemEffectPreview_FakeObject:AttachWindowEx("GemEffectPreview_Player")
	Exterior:LuaFnUpdateDressGemEffect(g_previewDress, g_previewDressViusal, g_previewFace, g_previewHair, g_curSex, g_Dress_Gem_ItemIndex[1], g_Dress_Gem_ItemIndex[2], g_Dress_Gem_ItemIndex[3], param)
end


function GemEffectPreview_Frame_On_ResetPos()
	GemEffectPreview_Frame:SetProperty("UnifiedPosition", g_GemEffectPreview_Frame_UnifiedPosition);
end

function GemEffectPreview_OnHiden()
	GemEffectPreview_UpdateObj(0)
	SetDefaultMouse()
	GemEffectPreview_FakeObject:DetachWindowEx()
	g_previewFace = -1
	g_previewHair = -1
	g_previewDress = -1
end

function GemEffectPreview_ChangeSex()
	if g_curSex == 0 or g_curSex == 1 then
		g_curSex = 1 - g_curSex
	else 
		g_curSex = Player:GetMySex()
	end
	GemEffectPreview_UpdateSex()
	GemEffectPreview_UpdateObj(1)
	GemEffectPreview_UpdateCamera()
end

--缩小
function GemEffectPreview_FakeObject_ZoomOut()
	if g_Distance == 1 then
		return
	end	
	g_Distance = g_Distance - 1	
	GemEffectPreview_UpdateCamera()
end

--放大
function GemEffectPreview_FakeObject_ZoomIn()
	if g_Distance == g_Distance_Max then
		return
	end
	g_Distance = g_Distance + 1	
	GemEffectPreview_UpdateCamera()
end

--左转
function GemEffectPreview_FakeObject_TurnLeft(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		GemEffectPreview_FakeObject:RotateBeginEx("GemEffectPreview_Player", -0.3)
	else
		GemEffectPreview_FakeObject:RotateEndEx()
	end
	
end

--右转
function GemEffectPreview_FakeObject_TurnRight(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		GemEffectPreview_FakeObject:RotateBeginEx("GemEffectPreview_Player", 0.3)
	else
		GemEffectPreview_FakeObject:RotateEndEx()
	end
	
end


function GemEffectPreview_ResetCamera()
	local sex = GetMySelfRaceId()
	if sex ~= 0 and sex ~= 1 then 
		return
	end
	local fHeight, fDistance, fPitch = GemEffectPreview_FakeObject:GetCameraEx()
	if g_SpecialCameraParam[g_previewGemEffectIndex] == nil then
		g_Distance = 2
		fHeight = g_CameraPosition[sex][g_Distance].fHeight
		fDistance = g_CameraPosition[sex][g_Distance].fDistance
		fPitch = g_CameraPosition[sex][g_Distance].fPitch
		GemEffectPreview_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)
	else
		g_Distance = 1
		fHeight = g_SpecialCameraParam[sex][g_Distance].fHeight
		fDistance = g_SpecialCameraParam[sex][g_Distance].fDistance
		fPitch = g_SpecialCameraParam[sex][g_Distance].fPitch
		GemEffectPreview_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)
	end
	
end

function GemEffectPreview_UpdateCamera()
	if g_curSex ~= 0 and g_curSex ~= 1 then 
		g_curSex = GetMySelfRaceId()
	end
		
	if g_Distance < 1 or g_Distance > g_Distance_Max then
		g_Distance = 2
	end
	
	local isIVMode = LuaFnGetCurModelState()
	local cameraInfo = g_CameraPosition
	if isIVMode == 1 then
		cameraInfo = g_CameraPosition_IV
	end
	if g_SpecialCameraParam[g_previewGemEffectIndex] ~= nil then
		cameraInfo = g_SpecialCameraParam[g_previewGemEffectIndex]
	end
	local fHeight, fDistance, fPitch = GemEffectPreview_FakeObject:GetCameraEx()
	local fXOffset = 0	
	
	fHeight = cameraInfo[g_curSex][g_Distance].fHeight
	fDistance = cameraInfo[g_curSex][g_Distance].fDistance
	fPitch = cameraInfo[g_curSex][g_Distance].fPitch
	fXOffset = cameraInfo[g_curSex][g_Distance].fXOffset
	GemEffectPreview_FakeObject:SetCameraEx(fHeight, fDistance, fPitch, fXOffset)	
end