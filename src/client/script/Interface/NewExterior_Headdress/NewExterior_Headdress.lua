--!!!reloadscript =NewExterior_Headdress
local g_NewExterior_Headdress_UnifiedPosition = ""

local EXTERIORFILTTING_TOTALKIND	= 8
local g_TargetExteriorIndex			= 0		--定位的外观索引，从1开始
local g_TargetExteriorID			= 0		--定位的外观ID

local g_CurSelExteriorID			= 0		--当前选择的外观ID，从1开始
local g_CurSelExteriorX				= 0		--当前选择的外观ID，从1开始
local g_CurSelExteriorY				= 0		--当前选择的外观ID，从1开始
local g_CurSelExteriorZ				= 0		--当前选择的外观ID，从1开始
local g_CurSelExteriorIndex			= 0		--当前选择的外观索引

local g_Headdress_FangAn_Max = 5

local g_NeedChangeScrollSize		= 1

local g_Distance					= 1
local g_Distance_Ori				= 3
local g_Distance_Max				= 4
local g_InitList					= 0
local g_ExteriorType				= 1 	--头挂
local g_MaxBarNum					= 0
local g_BarList						= {}
local g_ViewMode					= 0 --0是角色骑马1是只有马

local g_SliderChange				= 0
local g_TextChange					= 0
local g_CameraPosition =
{
	--女性相关位置
	[0] = {{fHeight = 0.85, fDistance = 12, fPitch=0.1, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.2, fPitch=0.1, fXOffset= 0 },
	       {fHeight = 1.55, fDistance = 2.5, fPitch=0.10, fXOffset= 0 }, {fHeight = 1.55, fDistance = 1.7, fPitch=0.10, fXOffset= 0 }},
	--男性相关位置
	[1] = {{fHeight = 0.85, fDistance = 12, fPitch=0.28, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.5, fPitch=0.28, fXOffset= 0 }, 
	       {fHeight = 1.65, fDistance = 2.7, fPitch=0.28, fXOffset= 0 }, {fHeight = 1.70, fDistance = 1.9, fPitch=0.28, fXOffset= 0 }},
}

local g_CameraPosition_IV =
{
	--女性相关位置
	[0] = {{fHeight = 0.85, fDistance = 12, fPitch=0.2, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.2, fPitch=0.2, fXOffset= 0 },
	       {fHeight = 1.55, fDistance = 2.5, fPitch=0.10, fXOffset= 0 }, {fHeight = 1.62, fDistance = 1.8, fPitch=0.10, fXOffset= 0 }},
	--男性相关位置
	[1] = {{fHeight = 0.85, fDistance = 12, fPitch=0.28, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.5, fPitch=0.28, fXOffset= 0 }, 
	       {fHeight = 1.70, fDistance = 2.7, fPitch=0.05, fXOffset= 0 }, {fHeight = 1.78, fDistance = 1.9, fPitch=0.05, fXOffset= 0 }},
}

local g_OrnamentState				= {
	INVALID	= 0,	-- 无效
	EMPTY	= 1,	-- 空闲
	TIME	= 2,	-- 限时
	TIMEOUT	= 3,	-- 过期
	FOREVER	= 4,	-- 永久
}

local g_OrnamentPosXMax				= 255
local g_OrnamentPosYMax				= 255
local g_OrnamentPosZMax				= 255
local g_OrnamentPosXMin				= 0
local g_OrnamentPosYMin				= 0
local g_OrnamentPosZMin				= 0
local g_OrnamentPosMax				= 255
local g_OrnamentPosAdjust			= 1		-- 是否可调节

local g_Ornaments_Name				= "OrnamentsHead"

local g_sexButtonInfo = {
    [0] = { imgH = "set:DressPreview01 image:DressPreview_Male_Hover", imgN = "set:DressPreview01 image:DressPreview_Male_Normal", imgP = "set:DressPreview01 image:DressPreview_Male_Pushed"  },
    [1] = { imgH = "set:DressPreview01 image:DressPreview_Female_Hover", imgN = "set:DressPreview01 image:DressPreview_Female_Normal", imgP = "set:DressPreview01 image:DressPreview_Female_Pushed"  },
}
local g_PlayerRace = {
    SEX_INVALID	= -1,
    SEX_FEMALE = 0,
    SEX_MALE = 1,
    SEX_NUMBERS = 2,
}
--=========
--PreLoad==
--=========
function NewExterior_Headdress_PreLoad()
	this:RegisterEvent("ORNAMENTS_OPEN_HEAD")
	this:RegisterEvent("UI_COMMAND", false)
	this:RegisterEvent("ORNAMENTS_POS_UPDATE", false)
	this:RegisterEvent("ADD_EXTERIOR", false)
	this:RegisterEvent("UPDATE_EXTERIOR", false)
	this:RegisterEvent("EXTERIOR_OUTTIME", false)	
	this:RegisterEvent("EXTERIOR_ID_CHANGED", false)
	this:RegisterEvent("EXTERIOR_FUTI_VISUAL_INDEX", false)
	this:RegisterEvent("EXTERIOR_HAIR_COLOR_INDEX", false)
	
	this:RegisterEvent("UPDATE_EXTERIOR_RIDE", false)
	
	this:RegisterEvent("UNIT_LEVEL",false)
	
	this:RegisterEvent("ON_SCENE_TRANS",false)
	this:RegisterEvent("ON_SERVER_TRANS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("ADJEST_UI_POS",false)	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("UPDATE_EXTERIOR_FASHION", false)
	
	this:RegisterEvent("EXERIOR_SAVEALL_RET", false)
	
	this:RegisterEvent("OPEN_STALL_SALE",false)
	this:RegisterEvent("PROGRESSBAR_SHOW",false)
	this:RegisterEvent("MODELID_CHANGE",false)
	this:RegisterEvent("ORNAMENTS_DISPLAYUPDATE",false)
end

--=========
--OnLoad
--=========
function NewExterior_Headdress_OnLoad()
	g_NewExterior_Headdress_UnifiedPosition = NewExterior_Headdress_Frame:GetProperty("UnifiedPosition")

	NewExterior_Headdress_X:SetProperty( "DocumentSize", tostring(g_OrnamentPosMax) )
	NewExterior_Headdress_X:SetProperty( "PageSize","0" )
	NewExterior_Headdress_X:SetProperty( "StepSize","1" )

	NewExterior_Headdress_Y:SetProperty( "DocumentSize",tostring(g_OrnamentPosMax) )
	NewExterior_Headdress_Y:SetProperty( "PageSize","0" )
	NewExterior_Headdress_Y:SetProperty( "StepSize","1" )

	NewExterior_Headdress_Z:SetProperty( "DocumentSize", tostring(g_OrnamentPosMax) )
	NewExterior_Headdress_Z:SetProperty( "PageSize","0" )
	NewExterior_Headdress_Z:SetProperty( "StepSize","1" )
end
--=========
--OnEvent
--=========
function NewExterior_Headdress_OnEvent(event)

	if event == "ORNAMENTS_OPEN_HEAD" then
		if this:IsVisible() then
			if tonumber(arg0) == 0 then
				NewExterior_Headdress_SavePosition()
				this:Hide()
			end
		else
			NewExterior_Headdress_SetPosition()
			NewExterior_Headdress_CloseSameGroupWindow()
			this:Show()
			NewExterior_Headdress_Show()
		end	
		return
	end

	if event == "UI_COMMAND" and tonumber(arg0) == 88896104 then
		NewExterior_Headdress_ResetPosition()
		return
	end

	if event == "ORNAMENTS_POS_UPDATE" then
		if tonumber(arg0) == g_ExteriorType and tonumber(arg1) <= 0 then
			NewExterior_Headdress_Show()
		else
			NewExterior_Headdress_UpdateLeftBtn()
			NewExterior_Headdress_UpdateRedPoint()
			Exterior:LuaFnUpdateExteriorPlayerData()
		end
		return
	end

	if ( event == "OPEN_STALL_SALE" ) -- 开始摆摊，还原试穿
		or ( event == "PROGRESSBAR_SHOW" )		-- 读进度条中，还原试穿
		or ( event == "MODELID_CHANGE" ) -- 变身 关闭界面
		then
		NewExterior_Headdress_CloseClick()
		return
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 80081701 ) then
		if (this:IsVisible()) then
			NewExterior_Headdress_CloseClick()
			return
		end
	end
	
	if event == "EXERIOR_SAVEALL_RET" then
		Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
		Exterior:LuaFnInitCurrentExteriorSet()
		NewExterior_Headdress_Show()	
	end
	
	if event == "UPDATE_EXTERIOR_RIDE" then
		local defExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
		Exterior:LuaFnSetCurrentExteriorSetInfo("RIDE", defExteriorID)
		NewExterior_Headdress_Show()
		--Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
		--Exterior:LuaFnInitCurrentExteriorSet()
		--NewExterior_Headdress_Show()	
	end
	
	if event == "ADD_EXTERIOR" or event == "UPDATE_EXTERIOR" or event == "EXTERIOR_OUTTIME" or event == "EXTERIOR_ID_CHANGED" then
		if tonumber(arg0) == g_ExteriorType then
			NewExterior_Headdress_Show()
		else
			--左侧
			NewExterior_Headdress_UpdateLeftBtn()
			NewExterior_Headdress_UpdateRedPoint()
			--更新一下模型
			Exterior:LuaFnUpdateExteriorPlayerData()
			Exterior:LuaFnUpdateExteriorPlayerData()
		end
		return
	end
	
	if event == "EXTERIOR_FUTI_VISUAL_INDEX" or event == "EXTERIOR_HAIR_COLOR_INDEX" then
		--左侧
		NewExterior_Headdress_UpdateLeftBtn()
		NewExterior_Headdress_UpdateRedPoint()
		--更新一下模型
		Exterior:LuaFnUpdateExteriorPlayerData()
		return
	end
	
	if event == "UPDATE_EXTERIOR_FASHION" then
		if tonumber(arg0) == 1 then
			--左侧
			NewExterior_Headdress_UpdateLeftBtn()
			--更新一下模型
			Exterior:LuaFnUpdateExteriorPlayerData()
		end
		return
	end	
	
	if event == "ORNAMENTS_DISPLAYUPDATE" then
		-- 刷新模型
		Exterior:LuaFnUpdateExteriorPlayerData()
		return
	end

	if event == "UNIT_LEVEL" and arg0 == "player" then
	
	end
	
	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		NewExterior_Headdress_Frame:SetProperty("UnifiedPosition", g_NewExterior_Headdress_UnifiedPosition)
	end
	
	if event == "UPDATE_REDPOINT_IN_UI" and this:IsVisible() then
		--NewExterior_Headdress_UpdateRedPoint()
	end

end

function NewExterior_Headdress_InitList()
	
	if g_InitList == 0 then		
		g_MaxBarNum = OrnamentsScript:GetOrnamentsMaxCount(g_ExteriorType)
		
		for i = 1, g_MaxBarNum do
			local bar = NewExterior_Headdress_SuperList:AddChild("NewExterior_Headdress_SuperListItem")
			g_BarList[i] = bar	
			bar:GetSubItem("NewExterior_Headdress_SuperListItemAction"):SetEvent("MouseLButtonDown", string.format("NewExterior_Headdress_ItemClicked(%d)", i))
			bar:GetSubItem("NewExterior_Headdress_SuperListItemAction"):SetEvent("MouseMove", string.format("NewExterior_Headdress_ItemMouseMove(%d)", i))
			bar:GetSubItem("NewExterior_Headdress_SuperListItemAction"):SetProperty("Empty", "False")
			bar:GetSubItem("NewExterior_Headdress_SuperListItemAction"):SetProperty("UseDefaultTooltip", "True")
		end
		g_InitList = 1
	end
end

function NewExterior_Headdress_Show()
		
	g_Distance = g_Distance_Ori

	g_NeedChangeScrollSize = 1
				
	EXTERIORFILTTING_TOTALKIND = Exterior:LuaFnGetExteriorPlayerFittingCount()
	
	NewExterior_Headdress_InitList()
	
	NewExterior_Headdress_CleanUp()
	
	Exterior:LuaFnInitCurrentExteriorSet()
	Exterior:LuaFnUpdateExteriorPlayerData()
	
	g_CurSelExteriorID = 0
	g_CurSelExteriorIndex = 0
	
	g_SliderChange = 0
	g_TextChange = 0

	--坐骑
	g_ViewMode = 0
	local cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo(g_Ornaments_Name)
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		g_ViewMode = 1
		g_TargetExteriorID = cacheExteriorID
		g_CurSelExteriorID = cacheExteriorID
		g_CurSelExteriorX = cacheExteriorX
		g_CurSelExteriorY = cacheExteriorY
		g_CurSelExteriorZ = cacheExteriorZ
		g_OrnamentPosXMin, g_OrnamentPosXMax, g_OrnamentPosYMin, 
		g_OrnamentPosYMax,g_OrnamentPosZMin, g_OrnamentPosZMax,
		g_OrnamentPosAdjust = OrnamentsScript:GetOrnamentsInfo(g_ExteriorType, g_CurSelExteriorID, "Pos")
	end
	
	--列表
	NewExterior_Headdress_UpdateList()
	--搭配方案
	NewExterior_Headdress_UpdateFangAn()
	--左侧
	NewExterior_Headdress_UpdateLeftBtn()
	--模型
	NewExterior_Headdress_UpdateObj()
	
	NewExterior_Headdress_RemoveTip(g_CurSelExteriorID)
	NewExterior_Headdress_UpdateRedPoint()
	NewExterior_Headdress_UpdateSlider()

	--NewExterior_Headdress_Model_Plus:Hide()
	--NewExterior_Headdress_Model_Subtract:Hide()
	
	NewExterior_Headdress_ShowFashionWeaponCheckButton()
	NewExterior_Headdress_GenderUpdate()
end

--左侧
function NewExterior_Headdress_UpdateLeftBtnForStyle()
	
	local sex = Exterior:LuaFnGetExteriorRaceID()
	
	-- 时装
	local cacheExteriorID, cacheExteriorIdx, gem1, gem2, gem3 = Exterior:LuaFnGetCurExteriorShareInfo("FASHION")
		
	-- 坐骑
	local edType = 0	
	cacheExteriorID = Exterior:LuaFnGetCurExteriorShareInfo("RIDE")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("RIDE")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Name")
		local strIcon = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Headdress_Ride_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_Ride_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Headdress_Ride_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_Ride_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Headdress_Ride_LockImg:Show()
		end
	end
	
	-- 幻武
	edType = 1
	cacheExteriorID = Exterior:LuaFnGetCurExteriorShareInfo("WEAPON")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Name")
		local strIcon 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Headdress_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Headdress_Weapon_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_Weapon_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Headdress_Weapon_LockImg:Show()
		end
	end
	
	-- 附体
	edType = 2
	local cacheVisualIndex = 0
	cacheExteriorID, cacheVisualIndex, _ = Exterior:LuaFnGetCurExteriorShareInfo("FUTI")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID, cacheVisualIndex, _ = Exterior:LuaFnGetCurrentExteriorSetInfo("FUTI")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "Name")
		local strImage 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "VisualIcon", cacheVisualIndex)
		NewExterior_Headdress_PetPossJian_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_PetPossJian_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Headdress_PetPossJian_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_PetPossJian_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorFutiVisualIndex() ~= cacheVisualIndex then
				NewExterior_Headdress_PetPossJian_ActionImg:Show()
			end
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 
			or Exterior:LuaFnIsExteriorFutiVisualUnlocked(cacheExteriorID, cacheVisualIndex) ~= 1 
		then
			NewExterior_Headdress_PetPossJian_LockImg:Show()
		end
	end
	
	-- 脸型
	edType = 3
	cacheExteriorID = Exterior:LuaFnGetCurExteriorShareInfo("FACE")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FACE")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Headdress_FaceStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_FaceStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_82}", strName)
		NewExterior_Headdress_FaceStyle_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_FaceStyle_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Headdress_FaceStyle_LockImg:Show()
		end
	end
	
	-- 发型
	edType = 4
	local cacheColorValue = 0
	local cacheColorIndex = 0
	cacheExteriorID, cacheColorValue = Exterior:LuaFnGetCurExteriorShareInfo("HAIR")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID, cacheColorIndex = Exterior:LuaFnGetCurrentExteriorSetInfo("HAIR")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Headdress_HairStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_HairStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_81}", strName)
		NewExterior_Headdress_HairStyle_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_HairStyle_ActionImg:Show()
		else
			if cacheColorValue ~= 0 and Exterior:LuaFnIsHaveHairColorValue(cacheColorValue) ~= 1 then
				NewExterior_Headdress_HairStyle_ActionImg:Show()
			end
			
			if cacheColorIndex ~= 0 and Exterior:LuaFnGetExteriorHairColorIndex() ~= cacheColorIndex then
				NewExterior_Headdress_HairStyle_ActionImg:Show()
			end
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Headdress_HairStyle_LockImg:Show()
		end
	end
	
	-- 头像
	edType = 5
	local strHeadTip = ""
	cacheExteriorID = Exterior:LuaFnGetCurExteriorShareInfo("PORTRAIT")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("PORTRAIT")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorPortraitInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorPortraitInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Headdress_PlayerFrame_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_PlayerFrame_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_79}", strName)
		strHeadTip = strTemp
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_PlayerFrame_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Headdress_PlayerFrame_LockImg:Show()
		end		
	end
	
	-- 头像框
	edType = 6
	cacheExteriorID = Exterior:LuaFnGetCurExteriorShareInfo("FRAME")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FRAME")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Name")
		local iFrameType = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Type")
		if iFrameType == 1 then
			NewExterior_Headdress_PlayerFrame_Mask:Hide()
			NewExterior_Headdress_PlayerFrame_Mask_Animate:Show()
			
			local strFrameAnimate = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameAnimate")
			NewExterior_Headdress_PlayerFrame_Mask_Animate:SetProperty("Animate", strFrameAnimate)
		else
			NewExterior_Headdress_PlayerFrame_Mask:Show()
			NewExterior_Headdress_PlayerFrame_Mask_Animate:Hide()
			
			local strIcon = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameIcon")
			local strImage = GetIconFullName(strIcon)
			NewExterior_Headdress_PlayerFrame_Mask:SetProperty("Image", strImage)
		end

		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_85}", strName)
		NewExterior_Headdress_PlayerFrame_LeftBtn:SetToolTip(strHeadTip.."#r"..strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_PlayerFrame_ActionImg:Show()
		end	
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Headdress_PlayerFrame_LockImg:Show()
		end		
	end
	
	-- 背饰
	local edOrnamentsType, cacheExteriorX, cacheExteriorY, cacheExteriorZ = 0, 0, 0, 0
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurExteriorShareInfo("OrnamentsBack")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsBack")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Headdress_Widget_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_Widget_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Headdress_Widget_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Headdress_Widget_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= g_OrnamentState.TIME and nState ~= g_OrnamentState.FOREVER ) then
			NewExterior_Headdress_Widget_LockImg:Show()
		end
	end

	-- 头饰
	edOrnamentsType= 1
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurExteriorShareInfo("OrnamentsHead")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsHead")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Headdress_Headdress_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_Headdress_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Headdress_Headdress_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Headdress_Headdress_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= g_OrnamentState.TIME and nState ~= g_OrnamentState.FOREVER ) then
			NewExterior_Headdress_Headdress_LockImg:Show()
		end
	end
end

--左侧
function NewExterior_Headdress_UpdateLeftBtn()
	
	NewExterior_Headdress_CleanUp_LeftButton()
		
	local g_CurSelShareStyleIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("STYLE")	
	if g_CurSelShareStyleIdx > 0 and g_CurSelShareStyleIdx <= g_Headdress_FangAn_Max then
		NewExterior_Headdress_UpdateLeftBtnForStyle()
		return
	end
	
	local sex = Exterior:LuaFnGetExteriorRaceID()
	--图鉴
	local cacheExteriorID,cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("DRESSSTYLE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local cacheID,dressExteriorID,specialExteriorID = DressStyleScript:GetDressStyleInfo(cacheExteriorID, "ID")
		if cacheID ~= nil then
			-- 获取图标
			local strIcon 	= DataPool:LuaFnGetItemIconByTableIndex(dressExteriorID)
			local strImage = GetIconFullName(strIcon)
			-- 设置action
			NewExterior_Headdress_Dress_LeftBtn:SetActionItem(-1)
			NewExterior_Headdress_Dress_LeftBtn:SetProperty("Empty", "False")
			NewExterior_Headdress_Dress_LeftBtn:SetProperty("NormalImage", strImage)
			NewExterior_Headdress_Dress_LeftBtn:SetProperty("HoverImage", strImage)
			NewExterior_Headdress_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "True")
			-- 文字tips
			local strToolTip = DressStyleScript:GetDressStyleToolTips(cacheExteriorID, cacheExteriorIdx)
			NewExterior_Headdress_Dress_LeftBtn:SetToolTip(strToolTip)
			-- 试穿
			NewExterior_Headdress_Dress_ActionImg:Show()
		end
	else
		--时装
		NewExterior_Headdress_Dress_LeftBtn:SetActionItem(-1)
		cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
		if cacheExteriorID ~= nil and cacheExteriorID > 0 then
			local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(1, cacheExteriorIdx)
			--local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, cacheExteriorID, 0)
			if theAction:GetID() ~= 0 then
				NewExterior_Headdress_Dress_LeftBtn:SetActionItem(theAction:GetID())
				NewExterior_Headdress_Dress_ActionImg:Show()
				
				local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
				if nCurFashionId ~= nil and nCurFashionId > 0 then
					if nCurFashionIdx == cacheExteriorIdx then
						NewExterior_Headdress_Dress_ActionImg:Hide()
					end
				end
			end
		else
			local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
			if nCurFashionId ~= nil and nCurFashionId > 0 then
				local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(1, nCurFashionIdx)
				--local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, nCurFashionId, 0)
				if theAction:GetID() ~= 0 then
					NewExterior_Headdress_Dress_LeftBtn:SetActionItem(theAction:GetID())
				end
			end			
		end
	end
	--坐骑
	local edType = 0	
	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("RIDE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Name")
		local strIcon = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Headdress_Ride_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_Ride_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Headdress_Ride_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_Ride_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Headdress_Ride_LockImg:Show()
		end
	end
	
	--幻武
	edType = 1
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Name")
		local strIcon 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Headdress_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Headdress_Weapon_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_Weapon_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Headdress_Weapon_LockImg:Show()
		end
	end
	
	--附体
	edType = 2
	local cacheVisualIndex = 0
	cacheExteriorID, cacheVisualIndex, _ = Exterior:LuaFnGetCurrentExteriorSetInfo("FUTI")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "Name")
		local strImage 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "VisualIcon", cacheVisualIndex)
		NewExterior_Headdress_PetPossJian_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_PetPossJian_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Headdress_PetPossJian_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_PetPossJian_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorFutiVisualIndex() ~= cacheVisualIndex then
				NewExterior_Headdress_PetPossJian_ActionImg:Show()
			end
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 or Exterior:LuaFnIsExteriorFutiVisualUnlocked(cacheExteriorID, cacheVisualIndex) ~= 1 then
			NewExterior_Headdress_PetPossJian_LockImg:Show()
		end
	end
	
	--脸型
	edType = 3
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FACE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Headdress_FaceStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_FaceStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_82}", strName)
		NewExterior_Headdress_FaceStyle_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_FaceStyle_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Headdress_FaceStyle_LockImg:Show()
		end
	end
	
	--发型
	edType = 4
	local cacheColorIndex = 0
	cacheExteriorID, cacheColorIndex = Exterior:LuaFnGetCurrentExteriorSetInfo("HAIR")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Headdress_HairStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_HairStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_81}", strName)
		NewExterior_Headdress_HairStyle_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_HairStyle_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorHairColorIndex() ~= cacheColorIndex then
				NewExterior_Headdress_HairStyle_ActionImg:Show()
			end
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Headdress_HairStyle_LockImg:Show()
		end
	end
	
	--头像
	edType = 5
	local strHeadTip = ""
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("PORTRAIT")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorPortraitInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorPortraitInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Headdress_PlayerFrame_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_PlayerFrame_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_79}", strName)
		strHeadTip = strTemp
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_PlayerFrame_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Headdress_PlayerFrame_LockImg:Show()
		end		
	end
	
	--头像框
	edType = 6
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FRAME")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Name")
		local iFrameType = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Type")
		if iFrameType == 1 then
			NewExterior_Headdress_PlayerFrame_Mask:Hide()
			NewExterior_Headdress_PlayerFrame_Mask_Animate:Show()
			
			local strFrameAnimate = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameAnimate")
			NewExterior_Headdress_PlayerFrame_Mask_Animate:SetProperty("Animate", strFrameAnimate)
		else
			NewExterior_Headdress_PlayerFrame_Mask:Show()
			NewExterior_Headdress_PlayerFrame_Mask_Animate:Hide()
			
			local strIcon = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameIcon")
			local strImage = GetIconFullName(strIcon)
			NewExterior_Headdress_PlayerFrame_Mask:SetProperty("Image", strImage)
		end

		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_85}", strName)
		NewExterior_Headdress_PlayerFrame_LeftBtn:SetToolTip(strHeadTip.."#r"..strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Headdress_PlayerFrame_ActionImg:Show()
		end	
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Headdress_PlayerFrame_LockImg:Show()
		end		
	end
	
	local edOrnamentsType, cacheExteriorX, cacheExteriorY, cacheExteriorZ = 0, 0, 0, 0
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsBack")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Headdress_Widget_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_Widget_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Headdress_Widget_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Headdress_Widget_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= g_OrnamentState.TIME and nState ~= g_OrnamentState.FOREVER ) then
			NewExterior_Headdress_Widget_LockImg:Show()
		end
	end

	edOrnamentsType= 1
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsHead")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Headdress_Headdress_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Headdress_Headdress_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Headdress_Headdress_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Headdress_Headdress_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= g_OrnamentState.TIME and nState ~= g_OrnamentState.FOREVER ) then
			NewExterior_Headdress_Headdress_LockImg:Show()
		end
	end
end
--列表
function NewExterior_Headdress_UpdateList()
	
	NewExterior_Headdress_UpdateCheckButton()
	NewExterior_Headdress_UpdateRedPoint()
	
	OrnamentsScript:InitOrnamentsListInfo(g_ExteriorType)
	local count = OrnamentsScript:GetOrnamentsMaxCount(g_ExteriorType)
	
	for i = 1, g_MaxBarNum do	
		NewExterior_Headdress_SetItem(i, count)
	end
	
	if g_NeedChangeScrollSize == 1 then
		NewExterior_Headdress_SuperList:RefreshLayout()
		g_NeedChangeScrollSize = 0
	end
	
	if g_TargetExteriorIndex ~= 0 then
		NewExterior_Headdress_SuperList:SetScrollPosition4Index(g_TargetExteriorIndex - 1)
		g_TargetExteriorID = 0
		g_TargetExteriorIndex = 0
	else
		NewExterior_Headdress_SuperList:SetScrollPosition4Index(0)
	end

end

function NewExterior_Headdress_SetItem(index, max_count)
	
	if g_BarList[index] == nil then
		return
	end
	
	if index > max_count then
		g_BarList[index]:Hide()
		return
	end
	
	local bar = g_BarList[index]
	bar:Show()
	
	local nExteriorID = OrnamentsScript:GetOrnamentsListID(g_ExteriorType, index - 1)
	local strIcon 	= OrnamentsScript:GetOrnamentsInfo(g_ExteriorType, nExteriorID, "Icon")
	local strName 	= OrnamentsScript:GetOrnamentsInfo(g_ExteriorType, nExteriorID, "Name")
	local strImage	= GetIconFullName(strIcon)
	local strDesc 	= OrnamentsScript:GetOrnamentsInfo(g_ExteriorType, nExteriorID, "Desc")
	local nActionID = OrnamentsScript:GetOrnamentsInfo(g_ExteriorType, nExteriorID, "ActionNum")
	local nAdjust	= OrnamentsScript:GetOrnamentsInfo(g_ExteriorType, nExteriorID, "Adjust")

	local ctrlAction = bar:GetSubItem("NewExterior_Headdress_SuperListItemAction")
	if ctrlAction ~= nil then
	
		ctrlAction:SetProperty("NormalImage", strImage)
		ctrlAction:SetProperty("HoverImage", strImage)
		
		local strToolTip = OrnamentsScript:GetOrnamentsToolTip(g_ExteriorType, nExteriorID)
		if nAdjust < 1 then
			strToolTip = strToolTip.."#{BGTS_220125_63}"
		end
		ctrlAction:SetToolTip(strToolTip)
		
		if g_CurSelExteriorID == nExteriorID then
			ctrlAction:SetPushed(1)
			bar:GetSubItem("NewExterior_Headdress_SuperListItemActionTry"):Show()
			if OrnamentsScript:GetOrnamentsUseID(g_ExteriorType) == nExteriorID then
				bar:GetSubItem("NewExterior_Headdress_SuperListItemActionTry"):Hide()
			end
			g_CurSelExteriorIndex = index
		else
			ctrlAction:SetPushed(0)
			bar:GetSubItem("NewExterior_Headdress_SuperListItemActionTry"):Hide()
		end			

		if g_TargetExteriorID == nExteriorID then
			g_TargetExteriorIndex = index
		end

	end
	
	-- 动作标识
	if nActionID > 0 then
		bar:GetSubItem("NewExterior_Headdress_SuperListItemActionButton"):Show()
	else
		bar:GetSubItem("NewExterior_Headdress_SuperListItemActionButton"):Hide()
	end

	--解锁&限时标志
	local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(g_ExteriorType, nExteriorID, 0)
	if nIdx > 0 and nState == g_OrnamentState.TIME then
		bar:GetSubItem("NewExterior_Headdress_SuperListItemActionTime"):Show()
	else
		bar:GetSubItem("NewExterior_Headdress_SuperListItemActionTime"):Hide()
		--bar:GetSubItem("NewExterior_Headdress_SuperListItemActionLock"):Show()
	end	

	if nIdx > 0 and (nState == g_OrnamentState.TIME or nState == g_OrnamentState.FOREVER) then
		bar:GetSubItem("NewExterior_Headdress_SuperListItemActionLock"):Hide()
	else
		bar:GetSubItem("NewExterior_Headdress_SuperListItemActionLock"):Show()
	end

	--使用中
	if OrnamentsScript:GetOrnamentsUseID(g_ExteriorType) == nExteriorID then
		bar:GetSubItem("NewExterior_Headdress_SuperListItemActionEqu"):Show()
	else
		bar:GetSubItem("NewExterior_Headdress_SuperListItemActionEqu"):Hide()
	end
	
	--红点
	local nTip = OrnamentsScript:GetPlayerOrnamentsTip(g_ExteriorType, nExteriorID)
	if nTip == 1 then
		bar:GetSubItem("NewExterior_Headdress_SuperListItemActionTip"):Show()
	else
		bar:GetSubItem("NewExterior_Headdress_SuperListItemActionTip"):Hide()
	end
	
end
--模型
function NewExterior_Headdress_UpdateObj()
	local cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo(g_Ornaments_Name)
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		NewExterior_Headdress_FakeObject:DetachWindowEx()
		NewExterior_Headdress_FakeObject:AttachWindowEx("Exterior_Player")
		--Exterior:LuaFnUpdateOrnamentsFashion(g_ExteriorType, cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ)	
		Exterior:LuaFnUpdateExteriorPlayerData()

		local actionID = OrnamentsScript:GetOrnamentsInfo(g_ExteriorType, cacheExteriorID, "ActionNum")
		if actionID ~= nil and actionID > 0 then
			NewExterior_Headdress_Model_Animate:Show()
		else
			NewExterior_Headdress_Model_Animate:Hide()
		end
	else	
		NewExterior_Headdress_FakeObject:DetachWindowEx()
		NewExterior_Headdress_FakeObject:AttachWindowEx("Exterior_Player")
		Exterior:LuaFnUpdateExteriorPlayerData()

		NewExterior_Headdress_Model_Animate:Hide()
	end

	
	NewExterior_Headdress_UpdateCamera()
		
end

function NewExterior_Headdress_UpdateOpBtn()
	
end

function NewExterior_Headdress_MountHorse()
--	Player:UseSkillInLua_Const()
end

function NewExterior_Headdress_UpdateSlider()
	if g_CurSelExteriorID > 0 then

		NewExterior_Headdress_CalSliderChange(g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ)
		g_TextChange = 3

		NewExterior_Headdress_X_NumericalValue : SetText(tostring(g_CurSelExteriorX))
		NewExterior_Headdress_X :SetPosition(g_CurSelExteriorX)

		NewExterior_Headdress_Y_NumericalValue : SetText(tostring(g_CurSelExteriorY))
		NewExterior_Headdress_Y :SetPosition(g_CurSelExteriorY)

		NewExterior_Headdress_Z_NumericalValue : SetText(tostring(g_CurSelExteriorZ))
		NewExterior_Headdress_Z :SetPosition(g_CurSelExteriorZ)

		NewExterior_Headdress_AdjustUIShow()
		NewExterior_Headdress_XYZList:Show()
	else
		NewExterior_Headdress_XYZList:Hide()
	end
end

function NewExterior_Headdress_ItemClicked(nIndex)
	local nExteriorID = OrnamentsScript:GetOrnamentsListID(g_ExteriorType, nIndex - 1)
	if g_CurSelExteriorID ~= nExteriorID then
		g_CurSelExteriorID = nExteriorID
		g_CurSelExteriorIndex = nIndex
		g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ = OrnamentsScript:GetOrnamentsDestPos(g_ExteriorType, g_CurSelExteriorID)
		Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSHEAD", g_CurSelExteriorID, g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ)
	
		Exterior:LuaFnSetCurExteriorShareInfo(g_Ornaments_Name, g_CurSelExteriorID, g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ)

		g_OrnamentPosXMin, g_OrnamentPosXMax, g_OrnamentPosYMin, 
		g_OrnamentPosYMax,g_OrnamentPosZMin, g_OrnamentPosZMax,
		g_OrnamentPosAdjust = OrnamentsScript:GetOrnamentsInfo(g_ExteriorType, g_CurSelExteriorID, "Pos")

		NewExterior_Headdress_SetItemSelected(nIndex)
		
		NewExterior_Headdress_UpdateObj()
	
		NewExterior_Headdress_UpdateLeftBtn()
	
		NewExterior_Headdress_RemoveTip(g_CurSelExteriorID)
		NewExterior_Headdress_UpdateRedPoint()

		NewExterior_Headdress_UpdateSlider()
	else
		local defExteriorID = OrnamentsScript:GetOrnamentsUseID(g_ExteriorType)
		local X, Y, Z = OrnamentsScript:GetOrnamentsDestPos(g_ExteriorType, defExteriorID)
		Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSHEAD", defExteriorID, X, Y, Z)
		NewExterior_Headdress_Show()
		Exterior:LuaFnSetCurExteriorShareInfo(g_Ornaments_Name, defExteriorID, X, Y, Z)
	end	
	
	NewExterior_Headdress_CloseTuJing()
end

function NewExterior_Headdress_ItemMouseMove(nIndex)

end

function NewExterior_Headdress_SetItemSelected(nIndex)
	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("NewExterior_Headdress_SuperListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
					g_BarList[i]:GetSubItem("NewExterior_Headdress_SuperListItemActionTry"):Show()
					if OrnamentsScript:GetOrnamentsUseID(g_ExteriorType) == g_CurSelExteriorID then
						g_BarList[i]:GetSubItem("NewExterior_Headdress_SuperListItemActionTry"):Hide()
					end
				else
					ctrlAction:SetPushed(0)	
					g_BarList[i]:GetSubItem("NewExterior_Headdress_SuperListItemActionTry"):Hide()
				end
			end
		end
	end
end

function NewExterior_Headdress_TryExterior()
	local selfSex = GetMySelfRaceId()
	local selectSex = Exterior:LuaFnGetExteriorRaceID()
	if selfSex ~= selectSex then
		PushDebugMessage("#{SZTJ_231030_01}")
		return
	end
	
	if Exterior:LuaFnIsHaveExteriorChange() ~= 1 then
		if Exterior:LuaFnIsHaveDressStyleChange() == 1 then
			Exterior:LuaFnSetCurrentExteriorSetInfo("RESETDRESSSTYLE")
			Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", selfSex)
			Exterior:LuaFnInitCurrentExteriorSet()
			NewExterior_Headdress_Show()
		else
			PushDebugMessage("#{WGTJ_201222_72}")
		end
		return
	end
	
	Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	Exterior:LuaFnSaveExteriorAllChange(1)
end

function NewExterior_Headdress_TakeOffRide()
	local defExteriorID = Exterior:LuaFnGetExteriorInUse(0)
	if defExteriorID == 0 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("RIDE", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("RIDE", 0)
		NewExterior_Headdress_UpdateLeftBtn()
	else
		Exterior:LuaFnSetExteriorInUse(0, 0, 0)
	end
end

function NewExterior_Headdress_TakeOffWeapon()
	local defExteriorID = Exterior:LuaFnGetExteriorInUse(1)
	if defExteriorID == 0 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("WEAPON", 0, 0)
		NewExterior_Headdress_UpdateLeftBtn()
		Exterior:LuaFnRestoreExteriorPlayerFittingData(1)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("WEAPON", 0, 0)
		Exterior:LuaFnSetExteriorInUse(1, 0, 0)
	end
end

function NewExterior_Headdress_ReviewClick()

	--if IsIdleLogic() ~= 1 and IsMoveLogic() ~= 1 then
	--	SetNotifyTip("#{YBSD_081225_100}");
	--	return
	--end

	local ret = Exterior:MouseCmd_ExteriorFittingSet();
	
	if ret == 1 then
		StopMove();
		PushDebugMessage("#{WGTJ_201222_148}")
	end
	
end

function NewExterior_Headdress_Undo()
	if Exterior:LuaFnIsHaveExteriorChange() == 0 and Exterior:LuaFnIsHaveDressStyleChange() == 0 then
		PushDebugMessage("#{WGTJ_201222_76}")
		return
	end	
	
	Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
	Exterior:LuaFnInitCurrentExteriorSet()
	NewExterior_Headdress_Show()
	PushDebugMessage("#{WGTJ_201222_98}")
end

function NewExterior_Headdress_CloseClick()
	Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	
	NewExterior_Headdress_SavePosition()
	this:Hide()
end

function NewExterior_Headdress_OnHidden()
	if IsWindowShow("NewExterior_DressBox") 
		or IsWindowShow("NewExterior_Weapon")  
		or IsWindowShow("NewExterior_PetPossJian")
		or IsWindowShow("NewExterior_Facestyle") 
		or IsWindowShow("NewExterior_HairStyle") 
		or IsWindowShow("NewExterior_PlayerFrame") 
		or IsWindowShow("NewExterior_Ride") 
		or IsWindowShow("NewExterior_Widget")
		or IsWindowShow("NewExterior_DressStyle")
		or IsWindowShow("NewExterior_GemEffect") then
	else	
		Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	end	
	
	NewExterior_Headdress_CleanUp()
	
	if IsWindowShow("NewExterior_PlanSetting") then
		CloseWindow("NewExterior_PlanSetting", true)
	end
	
	NewExterior_Headdress_CloseTuJing()
end

function NewExterior_Headdress_CleanUp()
	for i = 1, g_MaxBarNum do
		if g_BarList[i] then
			local ctrlAction = g_BarList[i]:GetSubItem("NewExterior_Headdress_SuperListItemAction")			
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
			end
		end
	end
	NewExterior_Headdress_FakeObject:DetachWindowEx()
	
	NewExterior_Headdress_CleanUp_LeftButton()
	
	SetDefaultMouse();
end

function NewExterior_Headdress_CleanUp_LeftButton()
	NewExterior_Headdress_Dress_LeftBtn:SetActionItem(-1)
	NewExterior_Headdress_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "False")
	NewExterior_Headdress_Dress_LeftBtn:SetProperty("NormalImage", "")
	NewExterior_Headdress_Dress_LeftBtn:SetProperty("HoverImage", "")
	NewExterior_Headdress_Dress_LeftBtn:SetProperty("Empty", "True")
	local ctrl_list = {
		[1] = NewExterior_Headdress_Weapon_LeftBtn,
		[2] = NewExterior_Headdress_PetPossJian_LeftBtn,
		[3] = NewExterior_Headdress_FaceStyle_LeftBtn,
		[4] = NewExterior_Headdress_HairStyle_LeftBtn,
		[5] = NewExterior_Headdress_PlayerFrame_LeftBtn,
		[6] = NewExterior_Headdress_Ride_LeftBtn,
		[7] = NewExterior_Headdress_Widget_LeftBtn,
		[8] = NewExterior_Headdress_Headdress_LeftBtn,
	}
	
	for i = 1, 8 do
		ctrl_list[i]:SetProperty("Empty", "False")
		ctrl_list[i]:SetProperty("UseDefaultTooltip", "True")
		ctrl_list[i]:SetProperty("NormalImage", "")
		ctrl_list[i]:SetProperty("HoverImage", "")
		ctrl_list[i]:SetToolTip("")
	end
	
	NewExterior_Headdress_PlayerFrame_Mask:SetProperty("Image", "")
	NewExterior_Headdress_PlayerFrame_Mask_Animate:SetProperty("Animate", "")
	
	NewExterior_Headdress_Dress_ActionImg:Hide()
	NewExterior_Headdress_Weapon_ActionImg:Hide()
	NewExterior_Headdress_PetPossJian_ActionImg:Hide()
	NewExterior_Headdress_FaceStyle_ActionImg:Hide()
	NewExterior_Headdress_HairStyle_ActionImg:Hide()
	NewExterior_Headdress_PlayerFrame_ActionImg:Hide()
	NewExterior_Headdress_Ride_ActionImg:Hide()
	NewExterior_Headdress_Widget_ActionImg:Hide()
	NewExterior_Headdress_Headdress_ActionImg:Hide()

	NewExterior_Headdress_Dress_LockImg:Hide()
	NewExterior_Headdress_Weapon_LockImg:Hide()
	NewExterior_Headdress_PetPossJian_LockImg:Hide()
	NewExterior_Headdress_FaceStyle_LockImg:Hide()
	NewExterior_Headdress_HairStyle_LockImg:Hide()
	NewExterior_Headdress_PlayerFrame_LockImg:Hide()
	NewExterior_Headdress_Ride_LockImg:Hide()
	NewExterior_Headdress_Widget_LockImg:Hide()
	NewExterior_Headdress_Headdress_LockImg:Hide()
end

function NewExterior_Headdress_UpdateCamera()
	local sex = Exterior:LuaFnGetExteriorRaceID()
	if sex ~= 0 and sex ~= 1 then 
		return
	end
		
	if g_Distance < 1 or g_Distance > g_Distance_Max then
		return
	end
	
	local isIVMode = LuaFnGetCurModelState()
	local cameraInfo = g_CameraPosition
	if isIVMode == 1 then
		cameraInfo = g_CameraPosition_IV
	end
	
	local fHeight, fDistance, fPitch = NewExterior_Headdress_FakeObject:GetCameraEx()
	fHeight = cameraInfo[sex][g_Distance].fHeight
	fDistance = cameraInfo[sex][g_Distance].fDistance
	fPitch = cameraInfo[sex][g_Distance].fPitch
	local fXOffset = cameraInfo[sex][g_Distance].fXOffset
	NewExterior_Headdress_FakeObject:SetCameraEx(fHeight, fDistance, fPitch, fXOffset)	
end


function NewExterior_Headdress_FakeObject_TurnLeft(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		NewExterior_Headdress_FakeObject:RotateBeginEx("Exterior_Player", -0.3)
	else
		NewExterior_Headdress_FakeObject:RotateEndEx()
	end
end

function NewExterior_Headdress_FakeObject_TurnRight(idx)
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		NewExterior_Headdress_FakeObject:RotateBeginEx("Exterior_Player", 0.3)
	else
		NewExterior_Headdress_FakeObject:RotateEndEx()
	end
end

--缩小
function NewExterior_Headdress_ZoomOut()
	if g_Distance == 1 then
		return
	end
	
	g_Distance = g_Distance - 1	

	NewExterior_Headdress_UpdateCamera()
end

--放大
function NewExterior_Headdress_ZoomIn()
	if g_Distance == g_Distance_Max then
		return
	end
	
	g_Distance = g_Distance + 1

	NewExterior_Headdress_UpdateCamera()
end

function NewExterior_Headdress_SwithViewMode()
	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("RIDE")
	if cacheExteriorID > 0 then
		if g_ViewMode == 0 then
			g_ViewMode = 1
		else
			g_ViewMode = 0
		end	
		NewExterior_Headdress_UpdateObj()
	end	
end

function NewExterior_Headdress_UpdateCheckButton()
--	NewExterior_Headdress_ButtonHuanwu:SetCheck(0)
--	NewExterior_Headdress_ButtonZhuangrong:SetCheck(0)
--	NewExterior_Headdress_ButtonFuti:SetCheck(0)
--	NewExterior_Headdress_ButtonZuoqi:SetCheck(1)
end

--右键取下时装
function NewExterior_Headdress_ActionToDressBox()
	local isShow = 0
	local cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		cacheExteriorID = 0
		cacheExteriorIdx = -1
		Exterior:LuaFnSetCurrentExteriorSetInfo("FASHION", cacheExteriorID, cacheExteriorIdx)            
		isShow = 1
		--return
	end
	local gem1, gem2, gem3 = 0,0,0
	cacheExteriorID, cacheExteriorIdx, gem1, gem2, gem3 = Exterior:LuaFnGetCurExteriorShareInfo("FASHION")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		cacheExteriorID = 0
		cacheExteriorIdx = -1
		Exterior:LuaFnSetCurExteriorShareInfo("FASHION", cacheExteriorID, cacheExteriorIdx)            
		isShow = 1
	end
	local cacheID,cacheSubID = Exterior:LuaFnGetCurrentExteriorSetInfo("DRESSSTYLE")
	if cacheID ~= nil and cacheID > 0 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("DRESSSTYLE", 0, 0)
		isShow = 1
	end

	if isShow > 0 then
		for i=1, 3 do
            Exterior:LuaFnSetCurrentExteriorSetInfo("GEMEFFECT", i-1, 0, 0)
        end
		NewExterior_Headdress_Show()
	end
	Exterior:LuaFnUnUseExteriorFashion(1)
end
--时装
function NewExterior_Headdress_OpenFashion()
	NewExterior_Headdress_SavePosition()
	PushEvent("OPEN_EXTERIOR_FASHION", 1, 0)
end
--幻武
function NewExterior_Headdress_OpenWeapon()
	NewExterior_Headdress_SavePosition()
	Exterior:LuaFnAskOpenExterior(1)
end
--附体
function NewExterior_Headdress_OpenFuti()
	NewExterior_Headdress_SavePosition()
	Exterior:LuaFnAskOpenExterior(2)
end
--坐骑
function NewExterior_Headdress_OpenRide()
	NewExterior_Headdress_SavePosition()
	Exterior:LuaFnAskOpenExterior(0)
	--local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("RIDE")
	--Exterior:LuaFnExteriorRideItemClick(cacheExteriorID)
end
--发型
function NewExterior_Headdress_OpenHair()
	NewExterior_Headdress_SavePosition()	
	Exterior:LuaFnAskOpenExterior(4)
end
--脸型
function NewExterior_Headdress_OpenFace()
	NewExterior_Headdress_SavePosition()	
	Exterior:LuaFnAskOpenExterior(3)
end
--头像
function NewExterior_Headdress_OpenPortrait()
	NewExterior_Headdress_SavePosition()	
	Exterior:LuaFnAskOpenExterior(5)
end
--打开展示柜
function NewExterior_Headdress_OpenYiRongGe()
	NewExterior_Headdress_SavePosition()
	Exterior:LuaFnAskExteriorYiRongGeInfo(1, 2)
end

function NewExterior_Headdress_OpenInfant()
	NewExterior_Headdress_SavePosition()
	Exterior:LuaFnInitExteriorFashionList(2, 1)
end

function NewExterior_Headdress_OpenOrnamentsBack()
	NewExterior_Headdress_SavePosition()	
	OrnamentsScript:AskOrnamentsInfo(0)
end

function NewExterior_Headdress_OpenOrnamentsHead()
	--NewExterior_Headdress_SavePosition()	
	--OrnamentsScript:AskOrnamentsInfo(1)
end

function NewExterior_Headdress_ActionToOrnamentsBack()
	local useID = OrnamentsScript:GetOrnamentsUseID(0)
	if useID > 0 then
		OrnamentsScript:TakeOffOrnaments(0)
	end
	Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSBACK", 0, 0, 0, 0)
	Exterior:LuaFnSetCurExteriorShareInfo("ORNAMENTSBACK", 0, 0, 0, 0)
	NewExterior_Headdress_UpdateLeftBtn()
	Exterior:LuaFnRestoreExteriorPlayerFittingData(6)
	Exterior:LuaFnUpdateExteriorPlayerData()
end

function NewExterior_Headdress_ActionToOrnamentsHead()
	local useID = OrnamentsScript:GetOrnamentsUseID(1)
	if useID > 0 then
		OrnamentsScript:TakeOffOrnaments(1)
	end
	Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSHEAD", 0, 0, 0, 0)
	Exterior:LuaFnSetCurExteriorShareInfo("ORNAMENTSHEAD", 0, 0, 0, 0)
	NewExterior_Headdress_Show()
end

function NewExterior_Headdress_CloseSameGroupWindow()
	CloseWindow("SelfEquip", true)
	CloseWindow("NewExterior_DressBox", true)
	CloseWindow("NewExterior_Ride", true)
	CloseWindow("NewExterior_Weapon", true)
	CloseWindow("NewExterior_PetPossJian", true)
	CloseWindow("NewExterior_Facestyle", true)
	CloseWindow("NewExterior_HairStyle", true)
	CloseWindow("NewExterior_PlayerFrame", true)
	CloseWindow("NewExterior_Widget", true)
	--CloseWindow("NewExterior_Headdress", true)
	CloseWindow("NewExterior_DressStyle", true)
	CloseWindow("NewExterior_GemEffect", true)
	CloseWindow("NewExterior_PlanSetting", true)
	CloseWindow("NewExterior_TuJing", true)
end

function NewExterior_Headdress_SavePosition()
	Variable:SetVariable("ExteriorUnionPos", NewExterior_Headdress_Frame:GetProperty("UnifiedPosition"), 1)
end

function NewExterior_Headdress_SetPosition()
	
	local nExteriorUnionPos = Variable:GetVariable("ExteriorUnionPos")
	if nExteriorUnionPos ~= nil then
		NewExterior_Headdress_Frame:SetProperty("UnifiedPosition", nExteriorUnionPos)
	end

end

function NewExterior_Headdress_RemoveTip(nExteriorID)
	local nTip = OrnamentsScript:GetPlayerOrnamentsTip(g_ExteriorType, nExteriorID)
	if nTip == 1 then
		OrnamentsScript:RemoveOrnamentsTip(g_ExteriorType, nExteriorID)
		for i = 1, g_MaxBarNum do
			if g_BarList[i] then
				local nID = OrnamentsScript:GetOrnamentsListID(g_ExteriorType, i - 1)
				if OrnamentsScript:RemoveOrnamentsTip(g_ExteriorType, nID) == 1 then
					g_BarList[i]:GetSubItem("NewExterior_Headdress_SuperListItemActionTip"):Show()
				else
					g_BarList[i]:GetSubItem("NewExterior_Headdress_SuperListItemActionTip"):Hide()
				end
			end
		end
	--	NewExterior_Widget_UpdateCheckButton()		
	end
end

function NewExterior_Headdress_UpdateRedPoint()

	NewExterior_Headdress_Dress_Tip:Hide()
	
	if Exterior:LuaFnIsHaveExteriorShowTip(0) == 1 then
		NewExterior_Headdress_Ride_Tip:Show()
	else
		NewExterior_Headdress_Ride_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(1) == 1 then
		NewExterior_Headdress_Weapon_Tip:Show()
	else
		NewExterior_Headdress_Weapon_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(2) == 1 then
		NewExterior_Headdress_PetPossJian_Tip:Show()
	else
		NewExterior_Headdress_PetPossJian_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(3) == 1 then
		NewExterior_Headdress_FaceStyle_Tip:Show()
	else
		NewExterior_Headdress_FaceStyle_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(4) == 1 or Exterior:LuaFnIsHaveHairColorShowTip() == 1 then
		NewExterior_Headdress_HairStyle_Tip:Show()
	else
		NewExterior_Headdress_HairStyle_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(5) == 1 or Exterior:LuaFnIsHaveExteriorShowTip(6) == 1 then
		NewExterior_Headdress_PlayerFrame_Tip:Show()
	else
		NewExterior_Headdress_PlayerFrame_Tip:Hide()
	end

	if Pneuma:GetMF(2959)== 1 or Exterior:LuaFnIsHaveExteriorShowTip(7) == 1 or Exterior:LuaFnIsHaveInfantHairColorShowTip() == 1 then 
		NewExterior_Headdress_SwitchBtn_Tip:Show()
	else
		NewExterior_Headdress_SwitchBtn_Tip:Hide()
	end

	if OrnamentsScript:IsHaveOrnamentsShowTip(0) == 1 then
		NewExterior_Headdress_Widget_Tip:Show()
	else
		NewExterior_Headdress_Widget_Tip:Hide()
	end

	if OrnamentsScript:IsHaveOrnamentsShowTip(1) == 1 then
		NewExterior_Headdress_Headdress_Tip:Show()
	else
		NewExterior_Headdress_Headdress_Tip:Hide()
	end
end

function NewExterior_Headdress_ShowFashionWeaponCheckButton()
	local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
	NewExterior_Headdress_Dress_Type:SetCheck(IsDisplay)
	
	IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
	NewExterior_Headdress_Weapon_Type:SetCheck(IsDisplay)

	IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
	NewExterior_Headdress_Widget_Type:SetCheck(IsDisplay)
	
	IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
	NewExterior_Headdress_Headdress_Type:SetCheck(IsDisplay)

	IsDisplay = SystemSetup:Lua_GetFuTiDisplayState()
	NewExterior_Headdress_PetPossJian_Type:SetCheck(IsDisplay)
end

function NewExterior_Headdress_FashionDisplay()
	local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
	if IsDisplay == 1 then
		NewExterior_Headdress_Dress_Type:SetCheck(0)
		SystemSetup:LuaFnCloseFashionDisplay(1)
	else
		NewExterior_Headdress_Dress_Type:SetCheck(1)
		SystemSetup:LuaFnCloseFashionDisplay(0)
	end	
end

function NewExterior_Headdress_ExteriorWeaponDisplay()
	local IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
	if IsDisplay == 1 then
		NewExterior_Headdress_Weapon_Type:SetCheck(0)
		SystemSetup:LuaFnCloseExteriorWeaponDisplay(1)
	else
		NewExterior_Headdress_Weapon_Type:SetCheck(1)
		SystemSetup:LuaFnCloseExteriorWeaponDisplay(0)
	end	
end

function NewExterior_Headdress_OrnamentsBackDisplay()
	local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
	if IsDisplay == 1 then
		NewExterior_Headdress_Widget_Type:SetCheck(0)
		SystemSetup:SetOrnamentsDisplayState(0, 1)
		OrnamentsScript:ResetOrnamentsUseInfo(0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		NewExterior_Headdress_Widget_Type:SetCheck(1)
		SystemSetup:SetOrnamentsDisplayState(0, 0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	end	
end

function NewExterior_Headdress_OrnamentsHeadDisplay()
	local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
	if IsDisplay == 1 then
		NewExterior_Headdress_Headdress_Type:SetCheck(0)
		SystemSetup:SetOrnamentsDisplayState(1, 1)
		OrnamentsScript:ResetOrnamentsUseInfo(1)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		NewExterior_Headdress_Headdress_Type:SetCheck(1)
		SystemSetup:SetOrnamentsDisplayState(1, 0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	end	
end

-- 附体
function NewExterior_Headdress_ExteriorPetPossDisplay()
	local IsDisplay = SystemSetup:Lua_GetFuTiDisplayState()
	if IsDisplay == 1 then
		--NewExterior_Headdress_Weapon_Type:SetCheck(0)
		SystemSetup:Lua_SetFuTiDisplayState(1)
	else
		--NewExterior_Headdress_Weapon_Type:SetCheck(1)
		SystemSetup:Lua_SetFuTiDisplayState(0)
	end	
end

function NewExterior_Headdress_Position_Change()
	--PushDebugMessage("NewExterior_Headdress_Position_Change")
	if g_CurSelExteriorID < 0 then
		return
	end

	if g_TextChange > 0 then
		g_TextChange = g_TextChange - 1
		return
	end

	g_TextChange = 0
	

	local curXTest = NewExterior_Headdress_X_NumericalValue : GetText()
	local curX = 0
	if curXTest ~= "" then
		curX = tonumber(curXTest)
	end

	local curYTest = NewExterior_Headdress_Y_NumericalValue : GetText()
	local curY = 0
	if curYTest ~= "" then
		curY = tonumber(curYTest)
	end

	local curZTest = NewExterior_Headdress_Z_NumericalValue : GetText()
	local curZ = 0
	if curZTest ~= "" then
		curZ = tonumber(curZTest)
	end

	local cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsHead")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		if curX < g_OrnamentPosXMin or curX > g_OrnamentPosXMax then
			local strTip = ScriptGlobal_Format("#{BGTS_220125_45}", g_OrnamentPosXMin, g_OrnamentPosXMax)
			PushDebugMessage(strTip)
			curX = cacheExteriorX
			NewExterior_Headdress_X_NumericalValue:SetTextOriginal(tostring(curX))
		end
		if curY < g_OrnamentPosYMin or curY > g_OrnamentPosYMax then
			local strTip = ScriptGlobal_Format("#{BGTS_220125_46}", g_OrnamentPosYMin, g_OrnamentPosYMax)
			PushDebugMessage(strTip)
			curY = cacheExteriorY
			NewExterior_Headdress_Y_NumericalValue:SetTextOriginal(tostring(curY))
		end
		if curZ < g_OrnamentPosZMin or curZ > g_OrnamentPosZMax then
			local strTip = ScriptGlobal_Format("#{BGTS_220125_47}", g_OrnamentPosZMin, g_OrnamentPosZMax)
			PushDebugMessage(strTip)
			curZ = cacheExteriorZ
			NewExterior_Headdress_Z_NumericalValue:SetTextOriginal(tostring(curZ))
		end
	end

	NewExterior_Headdress_CalSliderChange(curX, curY, curZ)

	NewExterior_Headdress_X:SetPosition(curX)
	NewExterior_Headdress_Y:SetPosition(curY)
	NewExterior_Headdress_Z:SetPosition(curZ)

	g_CurSelExteriorX = curX
	g_CurSelExteriorY = curY
	g_CurSelExteriorZ = curZ
	Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSHEAD", g_CurSelExteriorID, g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ)
	Exterior:LuaFnSetCurExteriorShareInfo(g_Ornaments_Name, g_CurSelExteriorID, g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ)
	Exterior:LuaFnUpdateOrnamentsFashion(g_ExteriorType, g_CurSelExteriorID, g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ)
end

function NewExterior_Headdress_SliderChanged()

	if g_CurSelExteriorID <= 0 then
		return
	end

	if g_SliderChange > 0 then
		g_SliderChange = g_SliderChange - 1
		return
	end

	g_SliderChange = 0
	g_TextChange = 3

	local curX = math.floor (NewExterior_Headdress_X :GetPosition() + 0.5) 
	NewExterior_Headdress_X_NumericalValue : SetText(curX)

	local curY = math.floor (NewExterior_Headdress_Y :GetPosition() + 0.5)
	NewExterior_Headdress_Y_NumericalValue : SetText(curY)

	local curZ = math.floor (NewExterior_Headdress_Z :GetPosition() + 0.5)
	NewExterior_Headdress_Z_NumericalValue : SetText(curZ)

	g_CurSelExteriorX = curX
	g_CurSelExteriorY = curY
	g_CurSelExteriorZ = curZ
	Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSHEAD", g_CurSelExteriorID, g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ)
	Exterior:LuaFnSetCurExteriorShareInfo(g_Ornaments_Name, g_CurSelExteriorID, g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ)
	Exterior:LuaFnUpdateOrnamentsFashion(g_ExteriorType, g_CurSelExteriorID, g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ)
end


function NewExterior_Headdress_SavePosition_OnClick()
	if g_CurSelExteriorID <= 0 then
		return
	end

	local selfSex = GetMySelfRaceId()
	local selectSex = Exterior:LuaFnGetExteriorRaceID()
	if selfSex ~= selectSex then
		PushDebugMessage("#{SZTJ_231030_01}")
		return
	end

	local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(g_ExteriorType, g_CurSelExteriorID, 0)

	if nIdx > 0 and (nState == g_OrnamentState.TIME or nState == g_OrnamentState.FOREVER ) then
		local bOk = 1
		local curX = g_OrnamentPosXMax + g_OrnamentPosXMax
		local curXTest = NewExterior_Headdress_X_NumericalValue:GetText()
		if curXTest ~= "" then
			curX = tonumber(curXTest)
		end
		if curX < g_OrnamentPosXMin or curX > g_OrnamentPosXMax then
			local strTip = ScriptGlobal_Format("#{BGTS_220125_45}",g_OrnamentPosXMin, g_OrnamentPosXMax)
			PushDebugMessage(strTip)
			bOk = 0
		end

		local curY = g_OrnamentPosYMax + g_OrnamentPosYMax
		local curYTest = NewExterior_Headdress_Y_NumericalValue : GetText()
		if curYTest ~= "" then
			curY = tonumber(curYTest)
		end
		if curY < g_OrnamentPosYMin or curY > g_OrnamentPosYMax then
			local strTip = ScriptGlobal_Format("#{BGTS_220125_46}",g_OrnamentPosYMin, g_OrnamentPosYMax)
			PushDebugMessage(strTip)
			bOk = 0
		end

		local curZ = g_OrnamentPosZMax + g_OrnamentPosZMax
		local curZTest = NewExterior_Headdress_Z_NumericalValue : GetText()
		if curZTest ~= "" then
			curZ = tonumber(curZTest)
		end
		if curZ < g_OrnamentPosZMin or curZ > g_OrnamentPosZMax then
			local strTip = ScriptGlobal_Format("#{BGTS_220125_47}",g_OrnamentPosZMin, g_OrnamentPosZMax)
			PushDebugMessage(strTip)
			bOk = 0
		end

		if bOk > 0 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "ChangeOrnamentsPos" )
				Set_XSCRIPT_ScriptID( 888961 )
				Set_XSCRIPT_Parameter( 0, g_ExteriorType )
				Set_XSCRIPT_Parameter( 1, g_CurSelExteriorID )
				Set_XSCRIPT_Parameter( 2, curX )
				Set_XSCRIPT_Parameter( 3, curY )
				Set_XSCRIPT_Parameter( 4, curZ )
				Set_XSCRIPT_ParamCount( 5 )
			Send_XSCRIPT()
		else
			NewExterior_Headdress_ResetPosition()
		end
	else
		PushDebugMessage("#{BGTS_220125_48}")
		return
	end

end

function NewExterior_Headdress_ResetPosition()
	if g_CurSelExteriorID <= 0 then
		return
	end

	g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ = OrnamentsScript:GetOrnamentsDestPos(g_ExteriorType, g_CurSelExteriorID)
	Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSHEAD", g_CurSelExteriorID, g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ)
	Exterior:LuaFnSetCurExteriorShareInfo(g_Ornaments_Name, g_CurSelExteriorID, g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ)
	Exterior:LuaFnUpdateOrnamentsFashion(g_ExteriorType, g_CurSelExteriorID, g_CurSelExteriorX, g_CurSelExteriorY, g_CurSelExteriorZ)
	NewExterior_Headdress_UpdateSlider()
end

function NewExterior_Headdress_DoAction(index)	
	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo(g_Ornaments_Name)
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		--NewExterior_Widget_Model_Plus:Disable()
		--NewExterior_Widget_Model_Subtract:Disable()
		--NewExterior_Widget_Model_TurnLeft:Disable()
		--NewExterior_Widget_Model_TurnRight:Disable()
		--SetTimer("NewExterior_Widget","NewExterior_Widget_ActionEnd()", 10000)
		Exterior:LuaFnExteriorAvatarPlayAction(3, cacheExteriorID, index - 1)
	end	
end

function NewExterior_Headdress_ActionEnd()
	--KillTimer("NewExterior_Widget_ActionEnd()")
	
	--NewExterior_Widget_Model_Plus:Enable()
	--NewExterior_Widget_Model_Subtract:Enable()
	--NewExterior_Widget_Model_TurnLeft:Enable()
	--NewExterior_Widget_Model_TurnRight:Enable()
	
	--NewExterior_Widget_UpdateCamera()
end

function NewExterior_Headdress_Goto()
	AutoRuntoTargetExWithName(337, 270, 0, "贝师师")
	NewExterior_Headdress_CloseClick()
end

function NewExterior_Headdress_CalSliderChange(x, y, z)
	g_SliderChange = 0
	local curX = NewExterior_Headdress_X :GetPosition()
	local curY = NewExterior_Headdress_Y :GetPosition()
	local curZ = NewExterior_Headdress_Z :GetPosition()
	if curX ~= x then
		g_SliderChange = g_SliderChange + 1
	end
	if curY ~= y then
		g_SliderChange = g_SliderChange + 1
	end
	if curZ ~= z then
		g_SliderChange = g_SliderChange + 1
	end
end

function NewExterior_Headdress_AdjustUIShow()
	if g_OrnamentPosAdjust > 0 then
		NewExterior_Headdress_X:Enable()
		NewExterior_Headdress_Y:Enable()
		NewExterior_Headdress_Z:Enable()
		NewExterior_Headdress_X_NumericalValue:Enable()
		NewExterior_Headdress_Y_NumericalValue:Enable()
		NewExterior_Headdress_Z_NumericalValue:Enable()
		NewExterior_Headdress_XYZ_Btn_L:Enable()
		NewExterior_Headdress_XYZ_Btn_R:Enable()
		-- 对tipsUI进行显隐处理
		NewExterior_Headdress_XYZ_Mask:Hide()
	else
		NewExterior_Headdress_X:Disable()
		NewExterior_Headdress_Y:Disable()
		NewExterior_Headdress_Z:Disable()
		NewExterior_Headdress_X_NumericalValue:Disable()
		NewExterior_Headdress_Y_NumericalValue:Disable()
		NewExterior_Headdress_Z_NumericalValue:Disable()
		NewExterior_Headdress_XYZ_Btn_L:Disable()
		NewExterior_Headdress_XYZ_Btn_R:Disable()
		-- 对tipsUI进行显隐处理
		NewExterior_Headdress_XYZ_Mask:Show()
	end
end

-- 来源
function NewExterior_Headdress_CloseTuJing()
	if IsWindowShow("NewExterior_TuJing") then
		CloseWindow("NewExterior_TuJing", true)
	end
end

-- 来源
function NewExterior_Headdress_ClickTuJing()
	if g_CurSelExteriorID > 0 then		
		PushEvent("OPEN_EXTERIOR_TUJING", 100, g_CurSelExteriorID, -1, -1)
	else
		PushDebugMessage("#{SZDP_230509_64}")
	end
end

--方案
function NewExterior_Headdress_UpdateFangAn()

	local g_CurSelShareStyleIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("STYLE")	
	if g_CurSelShareStyleIdx > 0 and g_CurSelShareStyleIdx <= g_Headdress_FangAn_Max then
		Exterior:LuaFnTryExteriorShareInfo(g_CurSelShareStyleIdx-1)
	end	
	
end

function NewExterior_Headdress_ChangeSex()
	local sex = Exterior:LuaFnGetExteriorRaceID()
	if sex ~= nil then
		if sex == g_PlayerRace.SEX_FEMALE then
			Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_MALE)
		elseif sex == g_PlayerRace.SEX_MALE then
			Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_FEMALE)
		end

		local select = g_CurSelExteriorIndex
		NewExterior_Headdress_Show()
		if select == nil or select < 1 then
			select = 1
		elseif select == g_CurSelExteriorIndex and g_MaxBarNum > 1 then
			if select == 1 then
				NewExterior_Headdress_ItemClicked(2)
			else
				NewExterior_Headdress_ItemClicked(1)
			end
		end
		NewExterior_Headdress_ItemClicked(select)
	end
end

function NewExterior_Headdress_GenderUpdate()
	local sex = Exterior:LuaFnGetExteriorRaceID()
	if sex ~= nil and g_sexButtonInfo[sex] ~= nil then
		NewExterior_Headdress_GenderChange_Btn:SetProperty("HoverImage", g_sexButtonInfo[sex].imgH)
		NewExterior_Headdress_GenderChange_Btn:SetProperty("NormalImage", g_sexButtonInfo[sex].imgN)
		NewExterior_Headdress_GenderChange_Btn:SetProperty("PushedImage", g_sexButtonInfo[sex].imgP)
	end
end

function NewExterior_Headdress_PetPossJianDisplay()
	local IsDisplay = SystemSetup:Lua_GetFuTiDisplayState()
	if IsDisplay == 1 then
		NewExterior_Headdress_PetPossJian_Type:SetCheck(0)
		SystemSetup:Lua_SetFuTiDisplayState(1)
	else
		NewExterior_Headdress_PetPossJian_Type:SetCheck(1)
		SystemSetup:Lua_SetFuTiDisplayState(0)
	end	
end

--!!!reloadscript =NewExterior_Headdress