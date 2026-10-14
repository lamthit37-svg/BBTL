--!!!reloadscript =NewExterior_Facestyle
local g_NewExterior_Facestyle_UnifiedPosition = ""

local EXTERIORFILTTING_TOTALKIND = 6;
local g_TargetExteriorIndex = 0		--定位的外观索引，从1开始
local g_TargetExteriorID = 0			--定位的外观ID

local g_CurSelExteriorID = 0			--当前选择的外观ID，从1开始

local g_Facestyle_FangAn_Max = 5

local g_NeedChangeScrollSize = 1

local g_Distance = 1
local g_Distance_Ori = 4
local g_Distance_Max = 4
local g_Distance_BigHead = 3
local g_InitList = 0
local g_ExteriorType = 3 --脸型
local g_MaxBarNum = 0
local g_BarList = {}

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
function NewExterior_Facestyle_PreLoad()
	this:RegisterEvent("OPEN_EXTERIOR")
	this:RegisterEvent("ADD_EXTERIOR", false)
	this:RegisterEvent("REMOVE_EXTERIOR", false)
	this:RegisterEvent("UPDATE_EXTERIOR", false)
	this:RegisterEvent("EXTERIOR_OUTTIME", false)	
	this:RegisterEvent("EXTERIOR_ID_CHANGED", false)
	this:RegisterEvent("EXTERIOR_FUTI_VISUAL_INDEX", false)
	this:RegisterEvent("EXTERIOR_HAIR_COLOR_INDEX", false)
	
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
	this:RegisterEvent("UI_COMMAND")
end

--=========
--OnLoad
--=========
function NewExterior_Facestyle_OnLoad()
	g_NewExterior_Facestyle_UnifiedPosition = NewExterior_Facestyle_Frame:GetProperty("UnifiedPosition")
end
--=========
--OnEvent
--=========
function NewExterior_Facestyle_OnEvent(event)

	if event == "OPEN_EXTERIOR" then
		if tonumber(arg0) == g_ExteriorType then
			if this:IsVisible() then
				if tonumber(arg1) == 0 then
					NewExterior_Facestyle_SavePosition()
					this:Hide()
				end
			else
				NewExterior_Facestyle_SetPosition()
				NewExterior_Facestyle_CloseSameGroupWindow()
				this:Show()
				NewExterior_Facestyle_Show()
			end	
		end
		return
	end
	
	if ( event == "OPEN_STALL_SALE" ) -- 开始摆摊，还原试穿
		or ( event == "PROGRESSBAR_SHOW" )		-- 读进度条中，还原试穿
		or ( event == "MODELID_CHANGE" ) -- 变身 关闭界面
		then
		NewExterior_Facestyle_CloseClick()
		return
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 80081701 ) then
		if (this:IsVisible()) then
			NewExterior_Facestyle_CloseClick()
			return
		end
	end
	
	if event == "EXERIOR_SAVEALL_RET" then
		Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
		Exterior:LuaFnInitCurrentExteriorSet()
		NewExterior_Facestyle_Show()
	end
	
	if event == "ADD_EXTERIOR" or event == "REMOVE_EXTERIOR" or event == "UPDATE_EXTERIOR" or event == "EXTERIOR_OUTTIME" or event == "EXTERIOR_ID_CHANGED" then
		if tonumber(arg0) == g_ExteriorType then
			NewExterior_Facestyle_Show()
		else
			--左侧
			NewExterior_Facestyle_UpdateLeftBtn()
			NewExterior_Facestyle_UpdateRedPoint()
			--更新一下模型
			Exterior:LuaFnUpdateExteriorPlayerData()
			Exterior:LuaFnUpdateExteriorPlayerData()
		end
		return
	end
	
	if event == "EXTERIOR_FUTI_VISUAL_INDEX" or event == "EXTERIOR_HAIR_COLOR_INDEX" then
		--左侧
		NewExterior_Facestyle_UpdateLeftBtn()
		NewExterior_Facestyle_UpdateRedPoint()
		--更新一下模型
		Exterior:LuaFnUpdateExteriorPlayerData()
		return
	end

	if event == "UPDATE_EXTERIOR_FASHION" then
		if tonumber(arg0) == 1 then
			--左侧
			NewExterior_Facestyle_UpdateLeftBtn()
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

	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		NewExterior_Facestyle_Frame:SetProperty("UnifiedPosition", g_NewExterior_Facestyle_UnifiedPosition)
	end

end

function NewExterior_Facestyle_InitList()
	
	if g_InitList == 0 then		
		g_MaxBarNum = Exterior:LuaFnGetExteriorMaxCount(g_ExteriorType)
		
		for i = 1, g_MaxBarNum do
			local bar = NewExterior_Facestyle_SuperList:AddChild("NewExterior_Facestyle_SuperListItem")
			g_BarList[i] = bar	
			bar:GetSubItem("NewExterior_Facestyle_SuperListItemAction"):SetEvent("MouseLButtonDown", string.format("NewExterior_Facestyle_ItemClicked(%d)", i))
			bar:GetSubItem("NewExterior_Facestyle_SuperListItemAction"):SetEvent("MouseMove", string.format("NewExterior_Facestyle_ItemMouseMove(%d)", i))
			bar:GetSubItem("NewExterior_Facestyle_SuperListItemAction"):SetProperty("Empty", "False")
			bar:GetSubItem("NewExterior_Facestyle_SuperListItemAction"):SetProperty("UseDefaultTooltip", "True")
		end
		g_InitList = 1
	end
end

function NewExterior_Facestyle_Show()
	
	g_Distance = g_Distance_Ori
	g_NeedChangeScrollSize = 1
				
	EXTERIORFILTTING_TOTALKIND = Exterior:LuaFnGetExteriorPlayerFittingCount()
	
	NewExterior_Facestyle_InitList()
	
	NewExterior_Facestyle_CleanUp()
	
	NewExterior_Facestyle_FakeObject:AttachWindowEx("Exterior_Player")
	Exterior:LuaFnUpdateExteriorPlayerData()
	
	g_CurSelExteriorID = 0

	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FACE")
	if cacheExteriorID > 0 then
		g_TargetExteriorID = cacheExteriorID
		g_CurSelExteriorID = cacheExteriorID
	end	

	-- 如果穿戴或者试穿大头特效，调整一下摄像机位置
	local cacheHeadID,_,_,_ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsHead")
	if cacheHeadID > 0 and OrnamentsScript:IsBigOrnamentsHead(cacheHeadID) > 0 then
		g_Distance = g_Distance_BigHead
	end

	--列表
	NewExterior_Facestyle_UpdateList()
	--搭配方案
	NewExterior_Facestyle_UpdateFangAn()
	--左侧
	NewExterior_Facestyle_UpdateLeftBtn()
	--模型
	NewExterior_Facestyle_UpdateObj()

	NewExterior_Facestyle_RemoveTip(g_CurSelExteriorID)
	NewExterior_Facestyle_UpdateRedPoint()

	NewExterior_Facestyle_ShowFashionWeaponCheckButton()
	NewExterior_Facestyle_GenderUpdate()

end

--左侧
function NewExterior_Facestyle_UpdateLeftBtnForStyle()
	
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
		
		NewExterior_Facestyle_Ride_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_Ride_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Facestyle_Ride_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_Ride_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Facestyle_Ride_LockImg:Show()
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
		
		NewExterior_Facestyle_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Facestyle_Weapon_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_Weapon_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Facestyle_Weapon_LockImg:Show()
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
		NewExterior_Facestyle_PetPossJian_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_PetPossJian_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Facestyle_PetPossJian_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_PetPossJian_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorFutiVisualIndex() ~= cacheVisualIndex then
				NewExterior_Facestyle_PetPossJian_ActionImg:Show()
			end
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 
			or Exterior:LuaFnIsExteriorFutiVisualUnlocked(cacheExteriorID, cacheVisualIndex) ~= 1 
		then
			NewExterior_Facestyle_PetPossJian_LockImg:Show()
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
		NewExterior_Facestyle_FaceStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_FaceStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_82}", strName)
		NewExterior_Facestyle_FaceStyle_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_FaceStyle_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Facestyle_FaceStyle_LockImg:Show()
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
		NewExterior_Facestyle_HairStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_HairStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_81}", strName)
		NewExterior_Facestyle_HairStyle_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_HairStyle_ActionImg:Show()
		else
			if cacheColorValue ~= 0 and Exterior:LuaFnIsHaveHairColorValue(cacheColorValue) ~= 1 then
				NewExterior_Facestyle_HairStyle_ActionImg:Show()
			end
			
			if cacheColorIndex ~= 0 and Exterior:LuaFnGetExteriorHairColorIndex() ~= cacheColorIndex then
				NewExterior_Facestyle_HairStyle_ActionImg:Show()
			end
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Facestyle_HairStyle_LockImg:Show()
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
		NewExterior_Facestyle_PlayerFrame_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_PlayerFrame_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_79}", strName)
		strHeadTip = strTemp
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_PlayerFrame_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Facestyle_PlayerFrame_LockImg:Show()
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
			NewExterior_Facestyle_PlayerFrame_Mask:Hide()
			NewExterior_Facestyle_PlayerFrame_Mask_Animate:Show()
			
			local strFrameAnimate = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameAnimate")
			NewExterior_Facestyle_PlayerFrame_Mask_Animate:SetProperty("Animate", strFrameAnimate)
		else
			NewExterior_Facestyle_PlayerFrame_Mask:Show()
			NewExterior_Facestyle_PlayerFrame_Mask_Animate:Hide()
			
			local strIcon = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameIcon")
			local strImage = GetIconFullName(strIcon)
			NewExterior_Facestyle_PlayerFrame_Mask:SetProperty("Image", strImage)
		end

		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_85}", strName)
		NewExterior_Facestyle_PlayerFrame_LeftBtn:SetToolTip(strHeadTip.."#r"..strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_PlayerFrame_ActionImg:Show()
		end	
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Facestyle_PlayerFrame_LockImg:Show()
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
		
		NewExterior_Facestyle_Widget_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_Widget_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Facestyle_Widget_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Facestyle_Widget_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= g_OrnamentState.TIME and nState ~= g_OrnamentState.FOREVER ) then
			NewExterior_Facestyle_Widget_LockImg:Show()
		end
	end

	-- 背饰
	edOrnamentsType= 1
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurExteriorShareInfo("OrnamentsHead")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsHead")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Facestyle_Headdress_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_Headdress_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Facestyle_Headdress_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Facestyle_Headdress_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= g_OrnamentState.TIME and nState ~= g_OrnamentState.FOREVER ) then
			NewExterior_Facestyle_Headdress_LockImg:Show()
		end
	end
end

function NewExterior_Facestyle_UpdateLeftBtn()
	
	NewExterior_Facestyle_CleanUp_LeftButton()
		
	local g_CurSelShareStyleIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("STYLE")	
	if g_CurSelShareStyleIdx > 0 and g_CurSelShareStyleIdx <= g_Facestyle_FangAn_Max then
		NewExterior_Facestyle_UpdateLeftBtnForStyle()
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
			NewExterior_Facestyle_Dress_LeftBtn:SetActionItem(-1)
			NewExterior_Facestyle_Dress_LeftBtn:SetProperty("Empty", "False")
			NewExterior_Facestyle_Dress_LeftBtn:SetProperty("NormalImage", strImage)
			NewExterior_Facestyle_Dress_LeftBtn:SetProperty("HoverImage", strImage)
			NewExterior_Facestyle_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "True")
			-- 文字tips
			local strToolTip = DressStyleScript:GetDressStyleToolTips(cacheExteriorID, cacheExteriorIdx)
			NewExterior_Facestyle_Dress_LeftBtn:SetToolTip(strToolTip)
			-- 试穿
			NewExterior_Facestyle_Dress_ActionImg:Show()
		end
	else
		--时装
		NewExterior_Facestyle_Dress_LeftBtn:SetActionItem(-1)
		cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
		if cacheExteriorID ~= nil and cacheExteriorID > 0 then
			local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(1, cacheExteriorIdx)
			--local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, cacheExteriorID, 0)
			if theAction:GetID() ~= 0 then
				NewExterior_Facestyle_Dress_LeftBtn:SetActionItem(theAction:GetID())
				NewExterior_Facestyle_Dress_ActionImg:Show()
				
				local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
				if nCurFashionId ~= nil and nCurFashionId > 0 then
					if nCurFashionIdx == cacheExteriorIdx then
						NewExterior_Facestyle_Dress_ActionImg:Hide()
					end
				end
			end
		else
			local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
			if nCurFashionId ~= nil and nCurFashionId > 0 then
				local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(1, nCurFashionIdx)
				--local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, nCurFashionId, 0)
				if theAction:GetID() ~= 0 then
					NewExterior_Facestyle_Dress_LeftBtn:SetActionItem(theAction:GetID())
				end
			end			
		end
	end
	--坐骑
	local edType = 0
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("RIDE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Name")
		local strIcon = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Facestyle_Ride_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_Ride_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Facestyle_Ride_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_Ride_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Facestyle_Ride_LockImg:Show()
		end
	end
	
	--幻武
	edType = 1
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Name")
		local strIcon 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Facestyle_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Facestyle_Weapon_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_Weapon_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Facestyle_Weapon_LockImg:Show()
		end
	end
	
	--附体
	edType = 2
	local cacheVisualIndex = 0	
	cacheExteriorID, cacheVisualIndex, _ = Exterior:LuaFnGetCurrentExteriorSetInfo("FUTI")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "Name")
		local strImage 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "VisualIcon", cacheVisualIndex)		
		NewExterior_Facestyle_PetPossJian_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_PetPossJian_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Facestyle_PetPossJian_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_PetPossJian_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorFutiVisualIndex() ~= cacheVisualIndex then
				NewExterior_Facestyle_PetPossJian_ActionImg:Show()
			end
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 or Exterior:LuaFnIsExteriorFutiVisualUnlocked(cacheExteriorID, cacheVisualIndex) ~= 1 then
			NewExterior_Facestyle_PetPossJian_LockImg:Show()
		end
	end
	
	--脸型
	edType = 3
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FACE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Facestyle_FaceStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_FaceStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_82}", strName)
		NewExterior_Facestyle_FaceStyle_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_FaceStyle_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Facestyle_FaceStyle_LockImg:Show()
		end
	end
	
	--发型
	edType = 4
	cacheExteriorID, cacheColorIndex = Exterior:LuaFnGetCurrentExteriorSetInfo("HAIR")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Facestyle_HairStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_HairStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_81}", strName)
		NewExterior_Facestyle_HairStyle_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_HairStyle_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorHairColorIndex() ~= cacheColorIndex then
			NewExterior_Facestyle_HairStyle_ActionImg:Show()
		end
	end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Facestyle_HairStyle_LockImg:Show()
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
		NewExterior_Facestyle_PlayerFrame_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_PlayerFrame_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_79}", strName)
		strHeadTip = strTemp
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_PlayerFrame_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Facestyle_PlayerFrame_LockImg:Show()
		end
	end
	
	--头像框
	edType = 6
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FRAME")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Name")
		local iFrameType = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Type")
		if iFrameType == 1 then
			NewExterior_Facestyle_PlayerFrame_Mask:Hide()
			NewExterior_Facestyle_PlayerFrame_Mask_Animate:Show()
			
			local strFrameAnimate = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameAnimate")
			NewExterior_Facestyle_PlayerFrame_Mask_Animate:SetProperty("Animate", strFrameAnimate)
		else
			NewExterior_Facestyle_PlayerFrame_Mask:Show()
			NewExterior_Facestyle_PlayerFrame_Mask_Animate:Hide()
			
			local strIcon 	= Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameIcon")
			local strImage = GetIconFullName(strIcon)
			NewExterior_Facestyle_PlayerFrame_Mask:SetProperty("Image", strImage)
		end

		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_85}", strName)
		NewExterior_Facestyle_PlayerFrame_LeftBtn:SetToolTip(strHeadTip.."#r"..strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Facestyle_PlayerFrame_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Facestyle_PlayerFrame_LockImg:Show()
		end
	end
	
	local edOrnamentsType, cacheExteriorX, cacheExteriorY, cacheExteriorZ = 0, 0, 0, 0
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsBack")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Facestyle_Widget_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_Widget_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Facestyle_Widget_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Facestyle_Widget_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
			NewExterior_Facestyle_Widget_LockImg:Show()
		end
	end

	edOrnamentsType= 1
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsHead")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Facestyle_Headdress_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Facestyle_Headdress_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Facestyle_Headdress_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Facestyle_Headdress_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
			NewExterior_Facestyle_Headdress_LockImg:Show()
		end
	end
end

function NewExterior_Facestyle_UpdateList()
	
	NewExterior_Facestyle_UpdateCheckButton()
	NewExterior_Facestyle_UpdateRedPoint()
	
	Exterior:LuaFnInitExteriorList(g_ExteriorType)
	local count = Exterior:LuaFnGetExteriorListCount(g_ExteriorType, 0)
	
	for i = 1, g_MaxBarNum do	
		NewExterior_Facestyle_SetItem(i, count)
	end
	
	if g_NeedChangeScrollSize == 1 then
		NewExterior_Facestyle_SuperList:RefreshLayout()
		g_NeedChangeScrollSize = 0
	end
	
	if g_TargetExteriorIndex ~= 0 then
		NewExterior_Facestyle_SuperList:SetScrollPosition4Index(g_TargetExteriorIndex - 1)
		g_TargetExteriorID = 0
		g_TargetExteriorIndex = 0
	else
		NewExterior_Facestyle_SuperList:SetScrollPosition4Index(0)
	end	
	
end

function NewExterior_Facestyle_SetItem(index, max_count)
	
	if g_BarList[index] == nil then
		return
	end
	
	if index > max_count then
		g_BarList[index]:Hide()
		return
	end
	
	local bar = g_BarList[index]
	bar:Show()
	
	local sex = Exterior:LuaFnGetExteriorRaceID()
	local nMyMenpai = Player:GetData("MEMPAI")
	
	local nExteriorID 	= Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, index - 1)
	local strName 	= Exterior:LuaFnGetExteriorFaceInfo(nExteriorID, "Name", sex)
	local strIcon 	= Exterior:LuaFnGetExteriorFaceInfo(nExteriorID, "Icon", sex)	
	local strImage = GetIconFullName(strIcon)
	local nMenpai 	= Exterior:LuaFnGetExteriorFaceInfo(nExteriorID, "Menpai", sex)
	
	local ctrlAction = bar:GetSubItem("NewExterior_Facestyle_SuperListItemAction")
	if ctrlAction ~= nil then
	
		ctrlAction:SetProperty("NormalImage", strImage)
		ctrlAction:SetProperty("HoverImage", strImage)
		
		local strTemp = Exterior:LuaFnGetExteriorFaceInfo(nExteriorID, "ToolTips", sex) --ScriptGlobal_Format("#{WGTJ_201222_82}", strName)
		ctrlAction:SetToolTip(strTemp)
		
			if g_CurSelExteriorID == nExteriorID then
				ctrlAction:SetPushed(1)
			bar:GetSubItem("NewExterior_Facestyle_SuperListItemActionTry"):Show()
			if Exterior:LuaFnGetExteriorInUse(g_ExteriorType) == nExteriorID then
				bar:GetSubItem("NewExterior_Facestyle_SuperListItemActionTry"):Hide()
			end
			else
				ctrlAction:SetPushed(0)
			bar:GetSubItem("NewExterior_Facestyle_SuperListItemActionTry"):Hide()
			end
			
			if g_TargetExteriorID == nExteriorID then
				g_TargetExteriorIndex = index
		end
	end
	
	--非本门派蒙红 
	if nMyMenpai == nMenpai or nMenpai == -1 then			
		bar:GetSubItem("NewExterior_FaceStyle_SuperListItemActionMark"):Hide()
	else
		bar:GetSubItem("NewExterior_FaceStyle_SuperListItemActionMark"):Show()
	end	
		
	bar:GetSubItem("NewExterior_Facestyle_SuperListItemActionTime"):Hide()
	--锁
	if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorID) == 1 then			
		bar:GetSubItem("NewExterior_Facestyle_SuperListItemActionLock"):Hide()
	else
		bar:GetSubItem("NewExterior_Facestyle_SuperListItemActionLock"):Show()
	end	

	--使用中
	if Exterior:LuaFnGetExteriorInUse(g_ExteriorType) == nExteriorID then
		bar:GetSubItem("NewExterior_Facestyle_SuperListItemActionDef"):Show()
	else
		bar:GetSubItem("NewExterior_Facestyle_SuperListItemActionDef"):Hide()
	end
	
	--红点
	local nTip = Exterior:LuaFnGetExteriorTip(g_ExteriorType, nExteriorID)
	if nTip == 1 then
		bar:GetSubItem("NewExterior_Facestyle_SuperListItemActionTip"):Show()
	else
		bar:GetSubItem("NewExterior_Facestyle_SuperListItemActionTip"):Hide()
	end

end

function NewExterior_Facestyle_UpdateObj()	
	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FACE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then			
		Exterior:LuaFnUpdateExteriorAvatarFace(cacheExteriorID)		
		Exterior:LuaFnUpdateExteriorPlayerData()
		NewExterior_Facestyle_UpdateCamera()
	end		
end
		
function NewExterior_Facestyle_UpdateOpBtn()	

end

function NewExterior_Facestyle_ItemClicked(nIndex)
	
	local nExteriorID 	= Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, nIndex - 1)	
	if g_CurSelExteriorID ~= nExteriorID then
		g_CurSelExteriorID = nExteriorID
		Exterior:LuaFnSetCurrentExteriorSetInfo("FACE", g_CurSelExteriorID)
		
		Exterior:LuaFnSetCurExteriorShareInfo("FACE", g_CurSelExteriorID)
		
		NewExterior_Facestyle_SetItemSelected(nIndex)
		NewExterior_Facestyle_UpdateObj()
		NewExterior_Facestyle_UpdateLeftBtn()
	
		NewExterior_Facestyle_RemoveTip(g_CurSelExteriorID)
		NewExterior_Facestyle_UpdateRedPoint()
	else
		local defExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
		Exterior:LuaFnSetCurrentExteriorSetInfo("FACE", defExteriorID)
		NewExterior_Facestyle_Show()
		
		Exterior:LuaFnSetCurExteriorShareInfo("FACE", defExteriorID)
	end	
	
	NewExterior_Facestyle_CloseTuJing()
end

function NewExterior_Facestyle_ItemMouseMove(nIndex)

end

function NewExterior_Facestyle_SetItemSelected(nIndex)
	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("NewExterior_Facestyle_SuperListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
					g_BarList[i]:GetSubItem("NewExterior_Facestyle_SuperListItemActionTry"):Show()
					if Exterior:LuaFnGetExteriorInUse(g_ExteriorType) == g_CurSelExteriorID then
						g_BarList[i]:GetSubItem("NewExterior_Facestyle_SuperListItemActionTry"):Hide()
					end
				else
					ctrlAction:SetPushed(0)	
					g_BarList[i]:GetSubItem("NewExterior_Facestyle_SuperListItemActionTry"):Hide()
				end
			end
		end
	end
end

function NewExterior_Facestyle_TryExterior()
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
			NewExterior_Facestyle_Show()
		else
			PushDebugMessage("#{WGTJ_201222_72}")
		end
		return
	end

	Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	Exterior:LuaFnSaveExteriorAllChange(1)
end

function NewExterior_Facestyle_TakeOffRide()
	local defExteriorID = Exterior:LuaFnGetExteriorInUse(0)
	if defExteriorID == 0 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("RIDE", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("RIDE", 0)
		NewExterior_Facestyle_UpdateLeftBtn()
	else
		Exterior:LuaFnSetExteriorInUse(0, 0, 0)
	end
end

function NewExterior_Facestyle_TakeOffWeapon()
	local defExteriorID = Exterior:LuaFnGetExteriorInUse(1)
	if defExteriorID == 0 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("WEAPON", 0, 0)
		NewExterior_Facestyle_UpdateLeftBtn()
		Exterior:LuaFnRestoreExteriorPlayerFittingData(1)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("WEAPON", 0, 0)
		Exterior:LuaFnSetExteriorInUse(1, 0, 0)
	end
end

function NewExterior_Facestyle_RemovePreview()
	if Exterior:LuaFnIsHaveExteriorChange() == 1 or Exterior:LuaFnIsHaveDressStyleChange() == 1 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
		Exterior:LuaFnInitCurrentExteriorSet()
		NewExterior_Facestyle_Show()
		PushDebugMessage("#{WGTJ_201222_98}")
	else
		PushDebugMessage("#{WGTJ_201222_76}")
	end
end

function NewExterior_Facestyle_Goto()
	AutoRuntoTargetExWithName(350, 270, 0, "颜如玉")
end

function NewExterior_Facestyle_CloseClick()
	Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	
	NewExterior_Facestyle_SavePosition()
	this:Hide()
end

function NewExterior_Facestyle_OnHidden()
	
	if IsWindowShow("NewExterior_DressBox") 
		or IsWindowShow("NewExterior_Ride") 
		or IsWindowShow("NewExterior_Weapon")  
		or IsWindowShow("NewExterior_PetPossJian")
		or IsWindowShow("NewExterior_HairStyle") 
		or IsWindowShow("NewExterior_PlayerFrame")
		or IsWindowShow("NewExterior_Widget") 
		or IsWindowShow("NewExterior_Headdress")
		or IsWindowShow("NewExterior_DressStyle")
		or IsWindowShow("NewExterior_GemEffect") then
	else	
		Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	end	
	
	NewExterior_Facestyle_CleanUp()
	
	if IsWindowShow("NewExterior_PlanSetting") then
		CloseWindow("NewExterior_PlanSetting", true)
	end
	
	NewExterior_Facestyle_CloseTuJing()
end

function NewExterior_Facestyle_CleanUp()
	for i = 1, g_MaxBarNum do
		if g_BarList[i] then
			local ctrlAction = g_BarList[i]:GetSubItem("NewExterior_Facestyle_SuperListItemAction")			
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
			end
		end
	end
	NewExterior_Facestyle_FakeObject:DetachWindowEx()
end

function NewExterior_Facestyle_CleanUp_LeftButton()
	
	NewExterior_Facestyle_Dress_LeftBtn:SetActionItem(-1)
	NewExterior_Facestyle_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "False")
	NewExterior_Facestyle_Dress_LeftBtn:SetProperty("NormalImage", "")
	NewExterior_Facestyle_Dress_LeftBtn:SetProperty("HoverImage", "")
	NewExterior_Facestyle_Dress_LeftBtn:SetProperty("Empty", "True")

	local ctrl_list = {
		[1] = NewExterior_Facestyle_Weapon_LeftBtn,
		[2] = NewExterior_Facestyle_PetPossJian_LeftBtn,
		[3] = NewExterior_Facestyle_FaceStyle_LeftBtn,
		[4] = NewExterior_Facestyle_HairStyle_LeftBtn,
		[5] = NewExterior_Facestyle_PlayerFrame_LeftBtn,
		[6] = NewExterior_Facestyle_Ride_LeftBtn,	
		[7] = NewExterior_Facestyle_Widget_LeftBtn,	
		[8] = NewExterior_Facestyle_Headdress_LeftBtn,	
	}
	
	for i = 1 ,8 do
		ctrl_list[i]:SetProperty("Empty", "False")
		ctrl_list[i]:SetProperty("UseDefaultTooltip", "True")
		ctrl_list[i]:SetProperty("NormalImage", "")
		ctrl_list[i]:SetProperty("HoverImage", "")
		ctrl_list[i]:SetToolTip("")
	end
	
	NewExterior_Facestyle_PlayerFrame_Mask:SetProperty("Image", "")
	NewExterior_Facestyle_PlayerFrame_Mask_Animate:SetProperty("Animate", "")
	
	NewExterior_Facestyle_Dress_ActionImg:Hide()
	NewExterior_Facestyle_Weapon_ActionImg:Hide()
	NewExterior_Facestyle_PetPossJian_ActionImg:Hide()
	NewExterior_Facestyle_FaceStyle_ActionImg:Hide()
	NewExterior_Facestyle_HairStyle_ActionImg:Hide()
	NewExterior_Facestyle_PlayerFrame_ActionImg:Hide()
	NewExterior_Facestyle_Ride_ActionImg:Hide()
	NewExterior_Facestyle_Widget_ActionImg:Hide()
	NewExterior_Facestyle_Headdress_ActionImg:Hide()

	NewExterior_Facestyle_Dress_LockImg:Hide()
	NewExterior_Facestyle_Weapon_LockImg:Hide()
	NewExterior_Facestyle_PetPossJian_LockImg:Hide()
	NewExterior_Facestyle_FaceStyle_LockImg:Hide()
	NewExterior_Facestyle_HairStyle_LockImg:Hide()
	NewExterior_Facestyle_PlayerFrame_LockImg:Hide()
	NewExterior_Facestyle_Ride_LockImg:Hide()
	NewExterior_Facestyle_Widget_LockImg:Hide()
	NewExterior_Facestyle_Headdress_LockImg:Hide()
end

function NewExterior_Facestyle_FakeObject_TurnLeft(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		NewExterior_Facestyle_FakeObject:RotateBeginEx("Exterior_Player", -0.3)
	else
		NewExterior_Facestyle_FakeObject:RotateEndEx()
	end
end

function NewExterior_Facestyle_FakeObject_TurnRight(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		NewExterior_Facestyle_FakeObject:RotateBeginEx("Exterior_Player", 0.3)
	else
		NewExterior_Facestyle_FakeObject:RotateEndEx()
	end
end
--缩小
function NewExterior_Facestyle_ZoomOut()
	if g_Distance == 1 then
		return
	end
	g_Distance = g_Distance - 1
	NewExterior_Facestyle_UpdateCamera()
end
--放大
function NewExterior_Facestyle_ZoomIn()
	if g_Distance == g_Distance_Max then
		return
	end	
	g_Distance = g_Distance + 1
	NewExterior_Facestyle_UpdateCamera()
end

function NewExterior_Facestyle_UpdateCamera()
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
	
	local fHeight, fDistance, fPitch = NewExterior_Facestyle_FakeObject:GetCameraEx()
	fHeight = cameraInfo[sex][g_Distance].fHeight
	fDistance = cameraInfo[sex][g_Distance].fDistance
	fPitch = cameraInfo[sex][g_Distance].fPitch
	fXOffset = cameraInfo[sex][g_Distance].fXOffset
	NewExterior_Facestyle_FakeObject:SetCameraEx(fHeight, fDistance, fPitch, fXOffset)	

end

function NewExterior_Facestyle_UpdateCheckButton()
--	NewExterior_Facestyle_ButtonHuanwu:SetCheck(0)
--	NewExterior_Facestyle_ButtonZhuangrong:SetCheck(0)
--	NewExterior_Facestyle_ButtonFuti:SetCheck(0)
--	NewExterior_Facestyle_ButtonZuoqi:SetCheck(1)
end

--右键取下时装
function NewExterior_Facestyle_ActionToDressBox()
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
		NewExterior_Facestyle_Show()
	end

	Exterior:LuaFnUnUseExteriorFashion(1)
end
--时装
function NewExterior_Facestyle_OpenFashion()
	NewExterior_Facestyle_SavePosition()
	PushEvent("OPEN_EXTERIOR_FASHION", 1, 0)
end
--幻武
function NewExterior_Facestyle_OpenWeapon()
	NewExterior_Facestyle_SavePosition()
	Exterior:LuaFnAskOpenExterior(1)
end
--附体
function NewExterior_Facestyle_OpenFuti()
	NewExterior_Facestyle_SavePosition()
	Exterior:LuaFnAskOpenExterior(2)
end
--坐骑
function NewExterior_Facestyle_OpenRide()
	NewExterior_Facestyle_SavePosition()
	Exterior:LuaFnAskOpenExterior(0)
end
--发型
function NewExterior_Facestyle_OpenHair()
	NewExterior_Facestyle_SavePosition()	
	Exterior:LuaFnAskOpenExterior(4)
end
--脸型
function NewExterior_Facestyle_OpenFace()
	--NewExterior_Facestyle_SavePosition()	
	--Exterior:LuaFnAskOpenExterior(3)
end
--头像
function NewExterior_Facestyle_OpenPortrait()
	NewExterior_Facestyle_SavePosition()	
	Exterior:LuaFnAskOpenExterior(5)
end
--打开展示柜
function NewExterior_Facestyle_OpenYiRongGe()
	NewExterior_Facestyle_SavePosition()
	Exterior:LuaFnAskExteriorYiRongGeInfo(1, 2)
end

function NewExterior_Facestyle_OpenInfant()
	NewExterior_Facestyle_SavePosition()
	Exterior:LuaFnInitExteriorFashionList(2, 1)
end

function NewExterior_Facestyle_OpenOrnamentsBack()
	NewExterior_Facestyle_SavePosition()	
	OrnamentsScript:AskOrnamentsInfo(0)
end

function NewExterior_Facestyle_OpenOrnamentsHead()
	NewExterior_Facestyle_SavePosition()	
	OrnamentsScript:AskOrnamentsInfo(1)
end

function NewExterior_Facestyle_CloseSameGroupWindow()
	CloseWindow("SelfEquip", true)
	CloseWindow("NewExterior_Ride", true)
	CloseWindow("NewExterior_Weapon", true)
	CloseWindow("NewExterior_PetPossJian", true)
	--CloseWindow("NewExterior_Facestyle", true)
	CloseWindow("NewExterior_HairStyle", true)
	CloseWindow("NewExterior_PlayerFrame", true)
	CloseWindow("NewExterior_DressBox", true)
	CloseWindow("NewExterior_Widget", true)
	CloseWindow("NewExterior_Headdress", true)
	CloseWindow("NewExterior_DressStyle", true)
	CloseWindow("NewExterior_GemEffect", true)
	CloseWindow("NewExterior_PlanSetting", true)
	CloseWindow("NewExterior_TuJing", true)
end

function NewExterior_Facestyle_SavePosition()
	Variable:SetVariable("ExteriorUnionPos", NewExterior_Facestyle_Frame:GetProperty("UnifiedPosition"), 1)
end

function NewExterior_Facestyle_SetPosition()
	
	local nExteriorUnionPos = Variable:GetVariable("ExteriorUnionPos")
	if nExteriorUnionPos ~= nil then
		NewExterior_Facestyle_Frame:SetProperty("UnifiedPosition", nExteriorUnionPos)
	end

end

function NewExterior_Facestyle_RemoveTip(nExteriorID)
	local nTip = Exterior:LuaFnGetExteriorTip(g_ExteriorType, nExteriorID)
	if nTip == 1 then
		Exterior:LuaFnRemoveExteriorTip(g_ExteriorType, nExteriorID)
	
		for i = 1, g_MaxBarNum do
			if g_BarList[i] then
				local nID = Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, i - 1)
				if Exterior:LuaFnGetExteriorTip(g_ExteriorType, nID) == 1 then
					g_BarList[i]:GetSubItem("NewExterior_Facestyle_SuperListItemActionTip"):Show()
				else
					g_BarList[i]:GetSubItem("NewExterior_Facestyle_SuperListItemActionTip"):Hide()
				end
			end
		end
	--	NewExterior_Ride_UpdateCheckButton()
	end	
end

function NewExterior_Facestyle_UpdateRedPoint()

	NewExterior_Facestyle_Dress_Tip:Hide()
	
	if Exterior:LuaFnIsHaveExteriorShowTip(0) == 1 then
		NewExterior_Facestyle_Ride_Tip:Show()
	else
		NewExterior_Facestyle_Ride_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(1) == 1 then
		NewExterior_Facestyle_Weapon_Tip:Show()
	else
		NewExterior_Facestyle_Weapon_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(2) == 1 then
		NewExterior_Facestyle_PetPossJian_Tip:Show()
	else
		NewExterior_Facestyle_PetPossJian_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(3) == 1 then
		NewExterior_Facestyle_FaceStyle_Tip:Show()
	else
		NewExterior_Facestyle_FaceStyle_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(4) == 1 or Exterior:LuaFnIsHaveHairColorShowTip() == 1 then
		NewExterior_Facestyle_HairStyle_Tip:Show()
	else
		NewExterior_Facestyle_HairStyle_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(5) == 1 or Exterior:LuaFnIsHaveExteriorShowTip(6) == 1 then
		NewExterior_Facestyle_PlayerFrame_Tip:Show()
	else
		NewExterior_Facestyle_PlayerFrame_Tip:Hide()
	end

	if Pneuma:GetMF(2959)== 1 or Exterior:LuaFnIsHaveExteriorShowTip(7) == 1 or Exterior:LuaFnIsHaveInfantHairColorShowTip() == 1 then 
		NewExterior_Facestyle_SwitchBtn_Tip:Show()
	else
		NewExterior_Facestyle_SwitchBtn_Tip:Hide()
	end

	if OrnamentsScript:IsHaveOrnamentsShowTip(0) == 1 then
		NewExterior_Facestyle_Widget_Tip:Show()
	else
		NewExterior_Facestyle_Widget_Tip:Hide()
	end

	if OrnamentsScript:IsHaveOrnamentsShowTip(1) == 1 then
		NewExterior_Facestyle_Headdress_Tip:Show()
	else
		NewExterior_Facestyle_Headdress_Tip:Hide()
	end
end

function NewExterior_Facestyle_ShowFashionWeaponCheckButton()
	local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
	NewExterior_Facestyle_Dress_Type:SetCheck(IsDisplay)
	
	IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
	NewExterior_Facestyle_Weapon_Type:SetCheck(IsDisplay)

	IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
	NewExterior_Facestyl_Widget_Type:SetCheck(IsDisplay)
	
	IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
	NewExterior_Facestyl_Headdress_Type:SetCheck(IsDisplay)

	IsDisplay = SystemSetup:Lua_GetFuTiDisplayState()
	NewExterior_Facestyl_PetPossJian_Type:SetCheck(IsDisplay)
end

function NewExterior_Facestyle_FashionDisplay()
	local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
	if IsDisplay == 1 then
		NewExterior_Facestyle_Dress_Type:SetCheck(0)
		SystemSetup:LuaFnCloseFashionDisplay(1)
	else
		NewExterior_Facestyle_Dress_Type:SetCheck(1)
		SystemSetup:LuaFnCloseFashionDisplay(0)
	end	
end

function NewExterior_Facestyle_ExteriorWeaponDisplay()
	local IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
	if IsDisplay == 1 then
		NewExterior_Facestyle_Weapon_Type:SetCheck(0)
		SystemSetup:LuaFnCloseExteriorWeaponDisplay(1)
	else
		NewExterior_Facestyle_Weapon_Type:SetCheck(1)
		SystemSetup:LuaFnCloseExteriorWeaponDisplay(0)
	end	
end

function NewExterior_Facestyle_OrnamentsBackDisplay()
	local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
	if IsDisplay == 1 then
		NewExterior_Facestyl_Widget_Type:SetCheck(0)
		SystemSetup:SetOrnamentsDisplayState(0, 1)
		OrnamentsScript:ResetOrnamentsUseInfo(0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		NewExterior_Facestyl_Widget_Type:SetCheck(1)
		SystemSetup:SetOrnamentsDisplayState(0, 0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	end	
end

function NewExterior_Facestyle_OrnamentsHeadDisplay()
	local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
	if IsDisplay == 1 then
		NewExterior_Facestyl_Headdress_Type:SetCheck(0)
		SystemSetup:SetOrnamentsDisplayState(1, 1)
		OrnamentsScript:ResetOrnamentsUseInfo(1)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		NewExterior_Facestyl_Headdress_Type:SetCheck(1)
		SystemSetup:SetOrnamentsDisplayState(1, 0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	end	
end

function NewExterior_Facestyle_ActionToOrnamentsBack()
	local useID = OrnamentsScript:GetOrnamentsUseID(0)
	if useID > 0 then
		OrnamentsScript:TakeOffOrnaments(0)
	end
	Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSBACK", 0, 0, 0, 0)
	Exterior:LuaFnSetCurExteriorShareInfo("ORNAMENTSBACK", 0, 0, 0, 0)
	NewExterior_Facestyle_UpdateLeftBtn()
	Exterior:LuaFnRestoreExteriorPlayerFittingData(6)
	Exterior:LuaFnUpdateExteriorPlayerData()
end

function NewExterior_Facestyle_ActionToOrnamentsHead()
	local useID = OrnamentsScript:GetOrnamentsUseID(1)
	if useID > 0 then
		OrnamentsScript:TakeOffOrnaments(1)
	end
	Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSHEAD", 0, 0, 0, 0)
	Exterior:LuaFnSetCurExteriorShareInfo("ORNAMENTSHEAD", 0, 0, 0, 0)
	NewExterior_Facestyle_UpdateLeftBtn()
	Exterior:LuaFnRestoreExteriorPlayerFittingData(7)
	Exterior:LuaFnUpdateExteriorPlayerData()
end

-- 来源
function NewExterior_Facestyle_CloseTuJing()
	if IsWindowShow("NewExterior_TuJing") then
		CloseWindow("NewExterior_TuJing", true)
	end
end

-- 来源
function NewExterior_Facestyle_ClickTuJing()
	if g_CurSelExteriorID > 0 then		
		PushEvent("OPEN_EXTERIOR_TUJING", g_ExteriorType, g_CurSelExteriorID, -1, -1)
	else
		PushDebugMessage("#{SZDP_230509_64}")
	end
end

--方案
function NewExterior_Facestyle_UpdateFangAn()
	
	local g_CurSelShareStyleIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("STYLE")	
	if g_CurSelShareStyleIdx > 0 then
		Exterior:LuaFnTryExteriorShareInfo(g_CurSelShareStyleIdx-1)
	end
	
end

-- 更改性别
function NewExterior_Facestyle_ChangeSex()
	local sex = Exterior:LuaFnGetExteriorRaceID()
	if sex ~= nil then
		if sex == g_PlayerRace.SEX_FEMALE then
			Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_MALE)
		elseif sex == g_PlayerRace.SEX_MALE then
			Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_FEMALE)
		end
		NewExterior_Facestyle_Show()
	end
end

function NewExterior_Facestyle_GenderUpdate()
	local sex = Exterior:LuaFnGetExteriorRaceID()
	if sex ~= nil and g_sexButtonInfo[sex] ~= nil then
		NewExterior_Facestyle_GenderChange_Btn:SetProperty("HoverImage", g_sexButtonInfo[sex].imgH)
		NewExterior_Facestyle_GenderChange_Btn:SetProperty("NormalImage", g_sexButtonInfo[sex].imgN)
		NewExterior_Facestyle_GenderChange_Btn:SetProperty("PushedImage", g_sexButtonInfo[sex].imgP)
	end
end

function NewExterior_Facestyle_PetPossJianDisplay()
	local IsDisplay = SystemSetup:Lua_GetFuTiDisplayState()
	if IsDisplay == 1 then
		NewExterior_Facestyl_PetPossJian_Type:SetCheck(0)
		SystemSetup:Lua_SetFuTiDisplayState(1)
	else
		NewExterior_Facestyl_PetPossJian_Type:SetCheck(1)
		SystemSetup:Lua_SetFuTiDisplayState(0)
	end	
end

--!!!reloadscript =NewExterior_Facestyle
