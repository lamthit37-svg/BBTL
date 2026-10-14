--!!!reloadscript =NewExterior_Ride
local g_NewExterior_Ride_UnifiedPosition = ""

local EXTERIORFILTTING_TOTALKIND = 6;
local g_TargetExteriorIndex = 0		--定位的外观索引，从1开始
local g_TargetExteriorID = 0			--定位的外观ID

local g_CurSelExteriorID = 0			--当前选择的外观ID，从1开始

local g_Ride_FangAn_Max = 5

local g_NeedChangeScrollSize = 1
local g_NeedChangeCollectionListScrollSize = 1

local g_Distance = 1
local g_Distance_Ori = 1
local g_Distance_Max = 3
local g_InitList = 0
local g_ExteriorType = 0 --坐骑
local g_MaxBarNum = 0
local g_BarList = {}
local g_ViewMode = 0 --0是角色骑马1是只有马

local g_CameraPosition =
{
	--女性相关位置
	[0] = {fHeight = 0.85, fDistance = 7.2, fPitch=0.1},
	--男性相关位置
	[1] = {fHeight = 0.85, fDistance = 7.5, fPitch=0.28},
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

local g_CurSubPage = 0

local g_RideCollectionBarList = {}
local g_MaxRideCollectionCount = 0

local g_MaxSeriesRideCount = 30
--=========
--PreLoad==
--=========
function NewExterior_Ride_PreLoad()
	this:RegisterEvent("OPEN_EXTERIOR")
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
	this:RegisterEvent("REMOVE_EXTERIOR", false)
	
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
function NewExterior_Ride_OnLoad()
	g_NewExterior_Ride_UnifiedPosition = NewExterior_Ride_Frame:GetProperty("UnifiedPosition")
end
--=========
--OnEvent
--=========
function NewExterior_Ride_OnEvent(event)

	if event == "OPEN_EXTERIOR" then
		if tonumber(arg0) == g_ExteriorType then
			if this:IsVisible() then
				if tonumber(arg1) == 0 then
					NewExterior_Ride_SavePosition()
					this:Hide()
				end
			else
				NewExterior_Ride_SetPosition()
				NewExterior_Ride_CloseSameGroupWindow()
				this:Show()
				g_CurSubPage = 0
				NewExterior_Ride_Show()
			end	
		end		
		return
	end
	
	if ( event == "OPEN_STALL_SALE" ) -- 开始摆摊，还原试穿
		or ( event == "PROGRESSBAR_SHOW" )		-- 读进度条中，还原试穿
		or ( event == "MODELID_CHANGE" ) -- 变身 关闭界面
		then
		NewExterior_Ride_CloseClick()
		return
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 80081701 ) then
		if (this:IsVisible()) then
			NewExterior_Ride_CloseClick()
			return
		end
	end
	
	if event == "EXERIOR_SAVEALL_RET" then
		Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
		Exterior:LuaFnInitCurrentExteriorSet()
		NewExterior_Ride_Show()	
	end
	
	if event == "UPDATE_EXTERIOR_RIDE" then
		local defExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
		Exterior:LuaFnSetCurrentExteriorSetInfo("RIDE", defExteriorID)
		NewExterior_Ride_Show()
		--Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
		--Exterior:LuaFnInitCurrentExteriorSet()
		--NewExterior_Ride_Show()	
	end
	
	if event == "ADD_EXTERIOR" or event == "UPDATE_EXTERIOR" or event == "REMOVE_EXTERIOR"  or event == "EXTERIOR_OUTTIME" or event == "EXTERIOR_ID_CHANGED" then
		if tonumber(arg0) == g_ExteriorType then
			NewExterior_Ride_Show()
		else
			--左侧
			NewExterior_Ride_UpdateLeftBtn()
			NewExterior_Ride_UpdateRedPoint()
			--更新一下模型
			Exterior:LuaFnUpdateExteriorPlayerData()
			Exterior:LuaFnUpdateExteriorPlayerData()
		end
		return
	end
	
	if event == "EXTERIOR_FUTI_VISUAL_INDEX" or event == "EXTERIOR_HAIR_COLOR_INDEX" then
		--左侧
		NewExterior_Ride_UpdateLeftBtn()
		NewExterior_Ride_UpdateRedPoint()
		--更新一下模型
		Exterior:LuaFnUpdateExteriorPlayerData()
		return
	end
	
	if event == "UPDATE_EXTERIOR_FASHION" then
		if tonumber(arg0) == 1 then
			--左侧
			NewExterior_Ride_UpdateLeftBtn()
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
		NewExterior_Ride_Frame:SetProperty("UnifiedPosition", g_NewExterior_Ride_UnifiedPosition)
	end
	
	if event == "UPDATE_REDPOINT_IN_UI" and this:IsVisible() then
		--NewExterior_Ride_UpdateRedPoint()
	end

end

function NewExterior_Ride_InitList()
	
	if g_InitList == 0 then		
		g_MaxBarNum = Exterior:LuaFnGetExteriorMaxCount(g_ExteriorType)
		
		for i = 1, g_MaxBarNum do
			local bar = NewExterior_Ride_SuperList:AddChild("NewExterior_Ride_SuperListItem")
			g_BarList[i] = bar	
			bar:GetSubItem("NewExterior_Ride_SuperListItemAction"):SetEvent("MouseLButtonDown", string.format("NewExterior_Ride_ItemClicked(%d)", i))
			bar:GetSubItem("NewExterior_Ride_SuperListItemAction"):SetEvent("MouseMove", string.format("NewExterior_Ride_ItemMouseMove(%d)", i))
			bar:GetSubItem("NewExterior_Ride_SuperListItemAction"):SetProperty("Empty", "False")
			bar:GetSubItem("NewExterior_Ride_SuperListItemAction"):SetProperty("UseDefaultTooltip", "True")
			bar:GetSubItem("NewExterior_Ride_SuperListItemAction"):SetEvent("MouseRClick", string.format("NewExterior_Ride_ItemRClicked(%d)", i))
		end
		
		g_MaxRideCollectionCount = DataPool:LuaFnGetRideCollectionMaxCount()
		for i = 1,  g_MaxRideCollectionCount do
			local bar = NewExterior_Ride_SuperList2:AddChild("NewExterior_Ride_SuperList2Item")
			g_RideCollectionBarList[i] = bar	
			bar:GetSubItem("NewExterior_Ride_SuperList2ItemAction"):SetProperty("Empty", "False")
			bar:GetSubItem("NewExterior_Ride_SuperList2ItemAction"):SetProperty("UseDefaultTooltip", "True")
		end
		g_InitList = 1
	end
end

function NewExterior_Ride_Show()
	
	--显示分页
	NewExterior_Ride_ShowSubPage()
	
	g_NeedChangeScrollSize = 1
	g_NeedChangeCollectionListScrollSize = 1

	EXTERIORFILTTING_TOTALKIND = Exterior:LuaFnGetExteriorPlayerFittingCount()
	
	NewExterior_Ride_InitList()
	
	NewExterior_Ride_CleanUp()
	
	Exterior:LuaFnInitCurrentExteriorSet()
	Exterior:LuaFnUpdateExteriorPlayerData()
	
	g_CurSelExteriorID = 0
	
	--坐骑
	g_ViewMode = 0
	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("RIDE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		g_ViewMode = 1
		g_TargetExteriorID = cacheExteriorID
		g_CurSelExteriorID = cacheExteriorID
	end
	
	--列表
	NewExterior_Ride_UpdateList()
	NewExterior_Ride_UpdateRideCollectionList()
	--搭配方案
	NewExterior_Ride_UpdateFangAn()
	--左侧
	NewExterior_Ride_UpdateLeftBtn()
	--模型
	NewExterior_Ride_UpdateObj()
	
	NewExterior_Ride_RemoveTip(g_CurSelExteriorID)
	NewExterior_Ride_UpdateRedPoint()
	
	NewExterior_Ride_Model_Plus:Hide()
	NewExterior_Ride_Model_Subtract:Hide()
	
	local max_speed = Exterior:LuaFnGetExteriorRideMaxSpeed()
	local strTemp = ScriptGlobal_Format("#{WGTJ_201222_111}", tostring(max_speed))
	NewExterior_Ride_Text1:SetText(strTemp)
	
	NewExterior_Ride_ShowFashionWeaponCheckButton()
	NewExterior_Ride_GenderUpdate()
end

--左侧
function NewExterior_Ride_UpdateLeftBtnForStyle()
	
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
		
		NewExterior_Ride_Ride_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_Ride_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Ride_Ride_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_Ride_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Ride_Ride_LockImg:Show()
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
		
		NewExterior_Ride_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Ride_Weapon_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_Weapon_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Ride_Weapon_LockImg:Show()
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
		NewExterior_Ride_PetPossJian_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_PetPossJian_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Ride_PetPossJian_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_PetPossJian_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorFutiVisualIndex() ~= cacheVisualIndex then
				NewExterior_Ride_PetPossJian_ActionImg:Show()
			end
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 
			or Exterior:LuaFnIsExteriorFutiVisualUnlocked(cacheExteriorID, cacheVisualIndex) ~= 1 
		then
			NewExterior_Ride_PetPossJian_LockImg:Show()
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
		NewExterior_Ride_FaceStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_FaceStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_82}", strName)
		NewExterior_Ride_FaceStyle_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_FaceStyle_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Ride_FaceStyle_LockImg:Show()
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
		NewExterior_Ride_HairStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_HairStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_81}", strName)
		NewExterior_Ride_HairStyle_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_HairStyle_ActionImg:Show()
		else
			if cacheColorValue ~= 0 and Exterior:LuaFnIsHaveHairColorValue(cacheColorValue) ~= 1 then
				NewExterior_Ride_HairStyle_ActionImg:Show()
			end
			
			if cacheColorIndex ~= 0 and Exterior:LuaFnGetExteriorHairColorIndex() ~= cacheColorIndex then
				NewExterior_Ride_HairStyle_ActionImg:Show()
			end
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Ride_HairStyle_LockImg:Show()
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
		NewExterior_Ride_PlayerFrame_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_PlayerFrame_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_79}", strName)
		strHeadTip = strTemp
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_PlayerFrame_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Ride_PlayerFrame_LockImg:Show()
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
			NewExterior_Ride_PlayerFrame_Mask:Hide()
			NewExterior_Ride_PlayerFrame_Mask_Animate:Show()
			
			local strFrameAnimate = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameAnimate")
			NewExterior_Ride_PlayerFrame_Mask_Animate:SetProperty("Animate", strFrameAnimate)
		else
			NewExterior_Ride_PlayerFrame_Mask:Show()
			NewExterior_Ride_PlayerFrame_Mask_Animate:Hide()
			
			local strIcon = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameIcon")
			local strImage = GetIconFullName(strIcon)
			NewExterior_Ride_PlayerFrame_Mask:SetProperty("Image", strImage)
		end

		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_85}", strName)
		NewExterior_Ride_PlayerFrame_LeftBtn:SetToolTip(strHeadTip.."#r"..strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_PlayerFrame_ActionImg:Show()
		end	
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Ride_PlayerFrame_LockImg:Show()
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
		
		NewExterior_Ride_Widget_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_Widget_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Ride_Widget_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Ride_Widget_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= g_OrnamentState.TIME and nState ~= g_OrnamentState.FOREVER ) then
			NewExterior_Ride_Widget_LockImg:Show()
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
		
		NewExterior_Ride_Headdress_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_Headdress_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Ride_Headdress_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Ride_Headdress_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= g_OrnamentState.TIME and nState ~= g_OrnamentState.FOREVER ) then
			NewExterior_Ride_Headdress_LockImg:Show()
		end
	end
end

--左侧
function NewExterior_Ride_UpdateLeftBtn()
	
	NewExterior_Ride_CleanUp_LeftButton()
		
	local g_CurSelShareStyleIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("STYLE")	
	if g_CurSelShareStyleIdx > 0 and g_CurSelShareStyleIdx <= g_Ride_FangAn_Max then
		NewExterior_Ride_UpdateLeftBtnForStyle()
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
			NewExterior_Ride_Dress_LeftBtn:SetActionItem(-1)
			NewExterior_Ride_Dress_LeftBtn:SetProperty("Empty", "False")
			NewExterior_Ride_Dress_LeftBtn:SetProperty("NormalImage", strImage)
			NewExterior_Ride_Dress_LeftBtn:SetProperty("HoverImage", strImage)
			NewExterior_Ride_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "True")
			-- 文字tips
			local strToolTip = DressStyleScript:GetDressStyleToolTips(cacheExteriorID, cacheExteriorIdx)
			NewExterior_Ride_Dress_LeftBtn:SetToolTip(strToolTip)
			-- 试穿
			NewExterior_Ride_Dress_ActionImg:Show()
		end
	else
		--时装
		NewExterior_Ride_Dress_LeftBtn:SetActionItem(-1)
		cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
		if cacheExteriorID ~= nil and cacheExteriorID > 0 then
			local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(1, cacheExteriorIdx)
			--local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, cacheExteriorID, 0)
			if theAction:GetID() ~= 0 then
				NewExterior_Ride_Dress_LeftBtn:SetActionItem(theAction:GetID())
				NewExterior_Ride_Dress_ActionImg:Show()
				
				local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
				if nCurFashionId ~= nil and nCurFashionId > 0 then
					if nCurFashionIdx == cacheExteriorIdx then
						NewExterior_Ride_Dress_ActionImg:Hide()
					end
				end
			end
		else
			local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
			if nCurFashionId ~= nil and nCurFashionId > 0 then
				local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(1, nCurFashionIdx)
				--local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, nCurFashionId, 0)
				if theAction:GetID() ~= 0 then
					NewExterior_Ride_Dress_LeftBtn:SetActionItem(theAction:GetID())
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
		
		NewExterior_Ride_Ride_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_Ride_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Ride_Ride_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_Ride_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Ride_Ride_LockImg:Show()
		end
	end
	
	--幻武
	edType = 1
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Name")
		local strIcon 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Ride_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Ride_Weapon_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_Weapon_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Ride_Weapon_LockImg:Show()
		end
	end
	
	--附体
	edType = 2
	local cacheVisualIndex = 0
	cacheExteriorID, cacheVisualIndex, _ = Exterior:LuaFnGetCurrentExteriorSetInfo("FUTI")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "Name")
		local strImage 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "VisualIcon", cacheVisualIndex)
		NewExterior_Ride_PetPossJian_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_PetPossJian_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Ride_PetPossJian_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_PetPossJian_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorFutiVisualIndex() ~= cacheVisualIndex then
				NewExterior_Ride_PetPossJian_ActionImg:Show()
			end
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 or Exterior:LuaFnIsExteriorFutiVisualUnlocked(cacheExteriorID, cacheVisualIndex) ~= 1 then
			NewExterior_Ride_PetPossJian_LockImg:Show()
		end
	end
	
	--脸型
	edType = 3
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FACE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Ride_FaceStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_FaceStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_82}", strName)
		NewExterior_Ride_FaceStyle_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_FaceStyle_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Ride_FaceStyle_LockImg:Show()
		end
	end
	
	--发型
	edType = 4
	cacheExteriorID, cacheColorIndex = Exterior:LuaFnGetCurrentExteriorSetInfo("HAIR")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_Ride_HairStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_HairStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_81}", strName)
		NewExterior_Ride_HairStyle_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_HairStyle_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorHairColorIndex() ~= cacheColorIndex then
				NewExterior_Ride_HairStyle_ActionImg:Show()
			end
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Ride_HairStyle_LockImg:Show()
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
		NewExterior_Ride_PlayerFrame_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_PlayerFrame_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_79}", strName)
		strHeadTip = strTemp
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_PlayerFrame_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Ride_PlayerFrame_LockImg:Show()
		end		
	end
	
	--头像框
	edType = 6
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FRAME")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Name")
		local iFrameType = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Type")
		if iFrameType == 1 then
			NewExterior_Ride_PlayerFrame_Mask:Hide()
			NewExterior_Ride_PlayerFrame_Mask_Animate:Show()
			
			local strFrameAnimate = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameAnimate")
			NewExterior_Ride_PlayerFrame_Mask_Animate:SetProperty("Animate", strFrameAnimate)
		else
			NewExterior_Ride_PlayerFrame_Mask:Show()
			NewExterior_Ride_PlayerFrame_Mask_Animate:Hide()
			
			local strIcon 	= Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameIcon")
			local strImage = GetIconFullName(strIcon)
			NewExterior_Ride_PlayerFrame_Mask:SetProperty("Image", strImage)
		end

		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_85}", strName)
		NewExterior_Ride_PlayerFrame_LeftBtn:SetToolTip(strHeadTip.."#r"..strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Ride_PlayerFrame_ActionImg:Show()
		end	
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Ride_PlayerFrame_LockImg:Show()
		end		
	end
	
	local edOrnamentsType, cacheExteriorX, cacheExteriorY, cacheExteriorZ = 0, 0, 0, 0
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsBack")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Ride_Widget_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_Widget_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Ride_Widget_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Ride_Widget_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
			NewExterior_Ride_Widget_LockImg:Show()
		end
	end

	edOrnamentsType= 1
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsHead")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Ride_Headdress_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Ride_Headdress_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_Ride_Headdress_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_Ride_Headdress_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
			NewExterior_Ride_Headdress_LockImg:Show()
		end
	end
end
--列表
function NewExterior_Ride_UpdateList()
	
	NewExterior_Ride_UpdateCheckButton()
	NewExterior_Ride_UpdateRedPoint()
	
	Exterior:LuaFnInitExteriorList(g_ExteriorType)
	local count = Exterior:LuaFnGetExteriorListCount(g_ExteriorType, 0)
	
	for i = 1, g_MaxBarNum do	
		NewExterior_Ride_SetItem(i, count)
	end
	
	if g_NeedChangeScrollSize == 1 then
		NewExterior_Ride_SuperList:RefreshLayout()
		g_NeedChangeScrollSize = 0
	end
	
	if g_TargetExteriorIndex ~= 0 then
		NewExterior_Ride_SuperList:SetScrollPosition4Index(g_TargetExteriorIndex - 1)
		g_TargetExteriorID = 0
		g_TargetExteriorIndex = 0
	else
		NewExterior_Ride_SuperList:SetScrollPosition4Index(0)
	end

end

function NewExterior_Ride_SetItem(index, max_count)
	
	if g_BarList[index] == nil then
		return
	end
	
	if index > max_count then
		g_BarList[index]:Hide()
		return
	end
	
	local bar = g_BarList[index]
	bar:Show()
	
	local nMyMenpai = Player:GetData("MEMPAI")
	local nExteriorID 	= Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, index - 1)
	local strIcon 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Icon")
	local strName 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Name")
	local nQuality 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Quality")
	local strImage = GetIconFullName(strIcon)
	local nLuxury 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Luxury")
	local nMenpai 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Menpai")
	local iReverseItem, iExpendItem, iExpendNum = Exterior:LuaFnGetExteriorRideInfo(nExteriorID, "ReverseItem")	
	
	local ctrlAction = bar:GetSubItem("NewExterior_Ride_SuperListItemAction")
	if ctrlAction ~= nil then
	
		ctrlAction:SetProperty("NormalImage", strImage)
		ctrlAction:SetProperty("HoverImage", strImage)
		
		local strTemp = Exterior:LuaFnGetRideToolTip(nExteriorID)
		ctrlAction:SetToolTip(strTemp)
		
		if g_CurSelExteriorID == nExteriorID then
			ctrlAction:SetPushed(1)
			bar:GetSubItem("NewExterior_Ride_SuperListItemActionTry"):Show()
			if Exterior:LuaFnGetExteriorInUse(g_ExteriorType) == nExteriorID then
				bar:GetSubItem("NewExterior_Ride_SuperListItemActionTry"):Hide()
			end
		else
			ctrlAction:SetPushed(0)
			bar:GetSubItem("NewExterior_Ride_SuperListItemActionTry"):Hide()
		end			

		if g_TargetExteriorID == nExteriorID then
			g_TargetExteriorIndex = index
		end

	end
	
	--非本门派蒙红 
	if nMyMenpai == nMenpai or nMenpai == -1 then			
		bar:GetSubItem("NewExterior_Ride_SuperListItemActionMark"):Hide()
	else
		bar:GetSubItem("NewExterior_Ride_SuperListItemActionMark"):Show()
	end	

	--解锁&限时标志
	if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorID) == 1 then
		bar:GetSubItem("NewExterior_Ride_SuperListItemActionLock"):Hide()
		local nLeftTime = Exterior:LuaFnGetExteriorLeftTime(g_ExteriorType, nExteriorID)
		if nLeftTime and nLeftTime < 0 then
			bar:GetSubItem("NewExterior_Ride_SuperListItemActionTime"):Hide()
		elseif nLeftTime and nLeftTime == 0 then
			bar:GetSubItem("NewExterior_Ride_SuperListItemActionTime"):Show()
		elseif nLeftTime and nLeftTime > 0 then
			bar:GetSubItem("NewExterior_Ride_SuperListItemActionTime"):Show()
		end
	else
		bar:GetSubItem("NewExterior_Ride_SuperListItemActionTime"):Hide()
		bar:GetSubItem("NewExterior_Ride_SuperListItemActionLock"):Show()
	end	

	--使用中
	if Exterior:LuaFnGetExteriorInUse(g_ExteriorType) == nExteriorID then
		bar:GetSubItem("NewExterior_Ride_SuperListItemActionDef"):Show()
	else
		bar:GetSubItem("NewExterior_Ride_SuperListItemActionDef"):Hide()
	end
	
	--红点
	local nTip = Exterior:LuaFnGetExteriorTip(g_ExteriorType, nExteriorID)
	if nTip == 1 then
		bar:GetSubItem("NewExterior_Ride_SuperListItemActionTip"):Show()
	else
		bar:GetSubItem("NewExterior_Ride_SuperListItemActionTip"):Hide()
	end
	
	--奢侈品
	if nLuxury == 1 then
		bar:GetSubItem("NewExterior_Ride_SuperListItemActionLuxury"):Show()
	else
		bar:GetSubItem("NewExterior_Ride_SuperListItemActionLuxury"):Hide()
	end
	
	-- 可取出
	if iReverseItem == nil or iReverseItem <= 0 then
		bar:GetSubItem("NewExterior_Ride_SuperListItemActionTakeout"):Hide()
	else
		bar:GetSubItem("NewExterior_Ride_SuperListItemActionTakeout"):Show()
	end
end
--模型
function NewExterior_Ride_UpdateObj()
	
	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("RIDE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then				
		
		local nMountId = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "MountId")		
		if g_ViewMode == 0 then
			NewExterior_Ride_FakeObject:DetachWindowEx()
			NewExterior_Ride_FakeObject:AttachWindowEx("Exterior_Player")
			Exterior:LuaFnUpdateExteriorPlayerData()
			Exterior:LuaFnUpdateExteriorAvatarMount(nMountId)
			local fHeight, fDistance, fPitch = NewExterior_Ride_FakeObject:GetCameraEx()
			fHeight, fDistance = Exterior:LuaFnGetExteriorRideCameraParam(nMountId,0)
			NewExterior_Ride_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)			
		else
			NewExterior_Ride_FakeObject:DetachWindowEx()
			NewExterior_Ride_FakeObject:AttachWindowEx("Exterior_Ride")
			Exterior:LuaFnUpdateExteriorAvatarMount(nMountId)
			Exterior:LuaFnUpdateExteriorPlayerData()
			local fHeight, fDistance, fPitch = NewExterior_Ride_FakeObject:GetCameraEx()
			fHeight, fDistance = Exterior:LuaFnGetExteriorRideCameraParam(nMountId,1)
			NewExterior_Ride_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)
		end		
	else	
		g_ViewMode = 0
		NewExterior_Ride_FakeObject:DetachWindowEx()
		NewExterior_Ride_FakeObject:AttachWindowEx("Exterior_Player")
		Exterior:LuaFnUpdateExteriorPlayerData()
	
		local sex = Exterior:LuaFnGetExteriorRaceID()
		if sex == 0 or sex == 1 then 
			local fHeight = g_CameraPosition[sex].fHeight
			local fDistance = g_CameraPosition[sex].fDistance
			local fPitch = g_CameraPosition[sex].fPitch
			NewExterior_Ride_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)		
		end			
	end
		
end

function NewExterior_Ride_UpdateOpBtn()
	
end

function NewExterior_Ride_MountHorse()
--	Player:UseSkillInLua_Const()
end

function NewExterior_Ride_MakeHyperlink(nExteriorID)
	local ret = Exterior:LuaFnExteriorRideItemClick(nExteriorID)
	if ret == 2 then
		PushDebugMessage("#{WGTJ_201222_132}")
	end
	return ret
end

function NewExterior_Ride_ItemClicked(nIndex)
	local nExteriorID 	= Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, nIndex - 1)	
	local ret = NewExterior_Ride_MakeHyperlink(nExteriorID)
	if ret == 1 or ret == 2 then
		return
	end
	if g_CurSelExteriorID ~= nExteriorID then
		g_CurSelExteriorID = nExteriorID		
		Exterior:LuaFnSetCurrentExteriorSetInfo("RIDE", g_CurSelExteriorID)
	
		Exterior:LuaFnSetCurExteriorShareInfo("RIDE", g_CurSelExteriorID)
		
		NewExterior_Ride_SetItemSelected(nIndex)
		
		NewExterior_Ride_UpdateObj()
	
		NewExterior_Ride_UpdateLeftBtn()
	
	NewExterior_Ride_RemoveTip(g_CurSelExteriorID)
	NewExterior_Ride_UpdateRedPoint()
	else
		local defExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
		Exterior:LuaFnSetCurrentExteriorSetInfo("RIDE", defExteriorID)
		Exterior:LuaFnSetCurExteriorShareInfo("RIDE", defExteriorID)
		NewExterior_Ride_Show()
	end	
		
	NewExterior_Ride_CloseTuJing()
end

function NewExterior_Ride_ItemRClicked(nIndex)

	local nExteriorID 	= Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, nIndex - 1)	
	local iReverseItem, iExpendItem, iExpendNum = Exterior:LuaFnGetExteriorRideInfo(nExteriorID, "ReverseItem")	
	if iReverseItem == nil or iReverseItem <= 0 then
		PushDebugMessage("#{QCZJ_220425_2}")
		return
	end
	
	if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorID) ~= 1 then
		PushDebugMessage("#{QCZJ_220425_3}")
		return
	end
	
	local nLeftTime = Exterior:LuaFnGetExteriorLeftTime(g_ExteriorType, nExteriorID)
	if nLeftTime and nLeftTime >= 0 then
		PushDebugMessage("#{QCZJ_220425_3}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ReverseExteriorRideToItem")
		Set_XSCRIPT_ScriptID(999900)
		Set_XSCRIPT_Parameter(0, nExteriorID)
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function NewExterior_Ride_ItemMouseMove(nIndex)

end

function NewExterior_Ride_SetItemSelected(nIndex)
	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("NewExterior_Ride_SuperListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
					g_BarList[i]:GetSubItem("NewExterior_Ride_SuperListItemActionTry"):Show()
					if Exterior:LuaFnGetExteriorInUse(g_ExteriorType) == g_CurSelExteriorID then
						g_BarList[i]:GetSubItem("NewExterior_Ride_SuperListItemActionTry"):Hide()
					end
				else
					ctrlAction:SetPushed(0)	
					g_BarList[i]:GetSubItem("NewExterior_Ride_SuperListItemActionTry"):Hide()
				end
			end
		end
	end
end

function NewExterior_Ride_UpdateRideCollectionList()

	local nMyMenpai = Player:GetData("MEMPAI")	
	DataPool:LuaFnInitRideCollectionList()	
	local count = DataPool:LuaFnGetRideCollectionListCount()
	
	local iActiveCollectionCount = 0
	
	for i = 1, g_MaxRideCollectionCount do
		NewExterior_Ride_RideCollection_SetItem(i, count)
	end
	
	local all_num = 0
	for i = 1, count do
		local id, id_type = DataPool:LuaFnEnumRideCollectionFromList(i - 1)
		if id_type == 0 then
			all_num = all_num + 1
			if Exterior:LuaFnIsHaveExterior(g_ExteriorType, id) == 1 then
				iActiveCollectionCount = iActiveCollectionCount + 1
			end
		elseif id_type == 1 then
			local max_count = DataPool:LuaFnGetRideSeriesInfo(id, "MAXCOUNT")
			all_num = all_num + max_count
			local a = NewExterior_Ride_GetRideSeriesActiveCount(id)
			iActiveCollectionCount = iActiveCollectionCount + a
		end
	end
	
	local strTemp = ScriptGlobal_Format("#{ZQDC_250326_4}", tostring(iActiveCollectionCount), tostring(all_num))
	NewExterior_Ride_SuperList2_RideNum:SetText(strTemp)

	if g_NeedChangeCollectionListScrollSize == 1 then
		NewExterior_Ride_SuperList2:RefreshLayout()
		g_NeedChangeCollectionListScrollSize = 0
	end
	
	NewExterior_Ride_SuperList3Text_Desc:ClearAllElement()
	NewExterior_Ride_SuperList3Text_Desc:AddTextElement("#{ZQDC_250326_14}")
	local questTip = NewExterior_Ride_GetCollectionSeriesTip(iActiveCollectionCount)
	NewExterior_Ride_SuperList3Text_Desc:AddTextElement(questTip)
end

function NewExterior_Ride_SuperList2Title2_Help_OnClicked()
	PushEvent("OPEN_SWEEPPAGE_QUEST", "NewExterior_Ride_Collection_Help")
end

function NewExterior_Ride_RideCollection_SetItem(index, max_count)

	if g_RideCollectionBarList[index] == nil then
		return
	end
	
	if index > max_count then
		g_RideCollectionBarList[index]:Hide()
		return
	end

	local bar = g_RideCollectionBarList[index]
	bar:Show()
	
	local nMyMenpai = Player:GetData("MEMPAI")
	local id, id_type = DataPool:LuaFnEnumRideCollectionFromList(index - 1)

	local nExteriorID = 0
	if id_type == 0 then
		nExteriorID = id
	elseif id_type == 1 then
		nExteriorID = DataPool:LuaFnEnumRideSeriesExteriorRideId(id, 0)
		for i = 1, g_MaxSeriesRideCount do
			local ride_id = DataPool:LuaFnEnumRideSeriesExteriorRideId(id, i - 1)
			if ride_id > 0 then
				if Exterior:LuaFnIsHaveExterior(g_ExteriorType, ride_id) == 1 then
					nExteriorID = ride_id
					break
				end
			end
		end
	end
	
	local strIcon 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID, "Icon")
	local strName 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID, "Name")
	local nQuality 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID, "Quality")
	local strImage = GetIconFullName(strIcon)
	local nLuxury 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID, "Luxury")
	local nMenpai 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID, "Menpai")
	
	local ctrlAction = bar:GetSubItem("NewExterior_Ride_SuperList2ItemAction")
	if ctrlAction ~= nil then
		ctrlAction:SetProperty("NormalImage", strImage)
		ctrlAction:SetProperty("HoverImage", strImage)
		
		if id_type == 0 then
			local strTemp = Exterior:LuaFnGetRideToolTip(nExteriorID)
			ctrlAction:SetToolTip(strTemp)
		elseif id_type == 1 then
			local series_name = DataPool:LuaFnGetRideSeriesInfo(id, "NAME")
			local max_count = DataPool:LuaFnGetRideSeriesInfo(id, "MAXCOUNT")
			local strTemp = ScriptGlobal_Format("#{ZQDC_250326_10}", tostring(series_name), tostring(max_count))
			for i = 1, g_MaxSeriesRideCount do
				local ride_id = DataPool:LuaFnEnumRideSeriesExteriorRideId(id, i - 1)
				if tonumber(ride_id) ~= nil and tonumber(ride_id) > 0 then
					local ride_name	= Exterior:LuaFnGetExteriorRideInfo(ride_id, "Name")
					if Exterior:LuaFnIsHaveExterior(g_ExteriorType, ride_id) == 1 then
						strTemp = strTemp.."#r#G"..tostring(ride_name)
					else
						strTemp = strTemp.."#r#c808080"..tostring(ride_name)
					end
				end
			end			
			ctrlAction:SetToolTip(strTemp)
		end
	end
	
	--非本门派蒙红 
	if nMyMenpai == nMenpai or nMenpai == -1 then			
		bar:GetSubItem("NewExterior_Ride_SuperList2ItemActionMark"):Hide()
	else
		bar:GetSubItem("NewExterior_Ride_SuperList2ItemActionMark"):Show()
	end	
	
	--解锁&限时标志
	if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorID) == 1 then
		bar:GetSubItem("NewExterior_Ride_SuperList2ItemActionLock"):Hide()
		if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorID) == 1 then
			local nLeftTime = Exterior:LuaFnGetExteriorLeftTime(g_ExteriorType, nExteriorID)
			if nLeftTime and nLeftTime < 0 then
				bar:GetSubItem("NewExterior_Ride_SuperList2ItemActionTime"):Hide()
			elseif nLeftTime and nLeftTime == 0 then
				bar:GetSubItem("NewExterior_Ride_SuperList2ItemActionTime"):Show()
			elseif nLeftTime and nLeftTime > 0 then
				bar:GetSubItem("NewExterior_Ride_SuperList2ItemActionTime"):Show()
			end
		else
			bar:GetSubItem("NewExterior_Ride_SuperList2ItemActionTime"):Show()
		end
	else
		bar:GetSubItem("NewExterior_Ride_SuperList2ItemActionTime"):Hide()
		bar:GetSubItem("NewExterior_Ride_SuperList2ItemActionLock"):Show()
	end

	--奢侈品
	if nLuxury == 1 or nLuxury == 2 then
		bar:GetSubItem("NewExterior_Ride_SuperList2ItemActionLuxury"):Show()
	else
		bar:GetSubItem("NewExterior_Ride_SuperList2ItemActionLuxury"):Hide()
	end
end

function NewExterior_Ride_GetRideSeriesActiveCount(cid)
	local count_type = DataPool:LuaFnGetRideSeriesInfo(cid, "COUNTTYPE")
	local ride_count = DataPool:LuaFnGetRideSeriesInfo(cid, "RIDECOUNT")
	local min_req = DataPool:LuaFnGetRideSeriesInfo(cid, "MINIREQ")
	local max_count = DataPool:LuaFnGetRideSeriesInfo(cid, "MAXCOUNT")
	local have_count = 0
	for index = 1, g_MaxSeriesRideCount do
		if index <= ride_count then
			local nExteriorID = DataPool:LuaFnEnumRideSeriesExteriorRideId(cid, index - 1)
			if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorID) == 1 then
				have_count = have_count + 1
			end
		end
	end
	
	if count_type == 0 then
		if have_count >= min_req then
			return 1
		end
	elseif count_type == 1 then
		if have_count > max_count then
			return max_count
		end
		return have_count
	end
	return 0
end

function NewExterior_Ride_GetCollectionSeriesTip(active_count)

	local g_TipEffectString = {"#{ZQDC_250326_15}", "#{ZQDC_250326_16}", "#{ZQDC_250326_26}"}
	local g_TipEffectString_Lock = {"#{ZQDC_250326_17}", "#{ZQDC_250326_18}", "#{ZQDC_250326_27}"}
	
	local questTip = ""
	local bFirstLine = 1
	for i = 1, 6 do
		local effect_type, effect_value, rep_count = DataPool:LuaFnEnumRideCollectionEffect(0, i - 1)
		if tonumber(effect_type) ~= nil and tonumber(effect_value) ~= nil and tonumber(rep_count) ~= nil then
			if active_count >= rep_count then
				if g_TipEffectString[effect_type] ~= nil then
					local strTemp = ScriptGlobal_Format(g_TipEffectString[effect_type], tostring(rep_count), tostring(effect_value))
					if bFirstLine == 1 then
						bFirstLine = 0
						questTip = questTip..strTemp
					else
						questTip = questTip.."#r"..strTemp
					end
				end
			else
				if g_TipEffectString_Lock[effect_type] ~= nil then
					local strTemp = ScriptGlobal_Format(g_TipEffectString_Lock[effect_type], tostring(rep_count), tostring(effect_value))
					if bFirstLine == 1 then
						bFirstLine = 0
						questTip = questTip..strTemp
					else
						questTip = questTip.."#r"..strTemp
					end
				end
			end
		end		
	end
	
	return questTip
end

function NewExterior_Ride_OpenRidePage()
	if g_CurSubPage ~= 0 then
		g_CurSubPage = 0
		NewExterior_Ride_ShowSubPage()
	--	NewExterior_Ride_SuperListTit_Text:SetText("#{WGTJ_201222_177}")
	end
end

function NewExterior_Ride_OpenCollectPage()
	if g_CurSubPage ~= 1 then
		g_CurSubPage = 1
		NewExterior_Ride_ShowSubPage()
	--	NewExterior_Ride_SuperListTit_Text:SetText("#{ZJYK_231019_32}")
	end
end

function NewExterior_Ride_TryExterior()
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
			NewExterior_Ride_Show()
		else
			PushDebugMessage("#{WGTJ_201222_72}")
		end
		return
	end
	
	Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	Exterior:LuaFnSaveExteriorAllChange(1)
end

function NewExterior_Ride_TakeOffRide()
	local defExteriorID = Exterior:LuaFnGetExteriorInUse(0)
	if defExteriorID == 0 then
		g_CurSelExteriorID = 0
		Exterior:LuaFnSetCurrentExteriorSetInfo("RIDE", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("RIDE", 0)
		--列表
		NewExterior_Ride_UpdateList()
		--左侧
		NewExterior_Ride_UpdateLeftBtn()
		--模型
		NewExterior_Ride_UpdateObj()
	else
		Exterior:LuaFnSetExteriorInUse(0, 0, 0)
	end
end

function NewExterior_Ride_TakeOffWeapon()
	local defExteriorID = Exterior:LuaFnGetExteriorInUse(1)
	if defExteriorID == 0 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("WEAPON", 0, 0)
		NewExterior_Ride_UpdateLeftBtn()
		Exterior:LuaFnRestoreExteriorPlayerFittingData(1)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("WEAPON", 0, 0)
		Exterior:LuaFnSetExteriorInUse(1, 0, 0)
	end
end

function NewExterior_Ride_ReviewClick()

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

function NewExterior_Ride_RemovePreview()
	if Exterior:LuaFnIsHaveExteriorChange() == 1 or Exterior:LuaFnIsHaveDressStyleChange() == 1 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
		Exterior:LuaFnInitCurrentExteriorSet()
		NewExterior_Ride_Show()
		PushDebugMessage("#{WGTJ_201222_98}")
	else
		PushDebugMessage("#{WGTJ_201222_76}")
	end
end

function NewExterior_Ride_CloseClick()
	Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	
	NewExterior_Ride_SavePosition()
	this:Hide()
end

function NewExterior_Ride_OnHidden()
	
	if IsWindowShow("NewExterior_DressBox") 
		or IsWindowShow("NewExterior_Weapon")  
		or IsWindowShow("NewExterior_PetPossJian")
		or IsWindowShow("NewExterior_Facestyle") 
		or IsWindowShow("NewExterior_HairStyle") 
		or IsWindowShow("NewExterior_PlayerFrame")
		or IsWindowShow("NewExterior_Widget") 
		or IsWindowShow("NewExterior_Headdress")
		or IsWindowShow("NewExterior_DressStyle")
		or IsWindowShow("NewExterior_GemEffect") then
	else	
		Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	end	
		
	if IsWindowShow("NewExterior_Ride_TakeOut") then
		CloseWindow("NewExterior_Ride_TakeOut", true);
	end
	
	NewExterior_Ride_CleanUp()
	
	if IsWindowShow("NewExterior_PlanSetting") then
		CloseWindow("NewExterior_PlanSetting", true)
	end
	
	NewExterior_Ride_CloseTuJing()
end

function NewExterior_Ride_CleanUp()
	for i = 1, g_MaxBarNum do
		if g_BarList[i] then
			local ctrlAction = g_BarList[i]:GetSubItem("NewExterior_Ride_SuperListItemAction")			
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
			end
		end
	end
	NewExterior_Ride_FakeObject:DetachWindowEx()
	
	NewExterior_Ride_CleanUp_LeftButton()
	
	SetDefaultMouse();
end

function NewExterior_Ride_CleanUp_LeftButton()
	NewExterior_Ride_Dress_LeftBtn:SetActionItem(-1)
	NewExterior_Ride_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "False")
	NewExterior_Ride_Dress_LeftBtn:SetProperty("NormalImage", "")
	NewExterior_Ride_Dress_LeftBtn:SetProperty("HoverImage", "")
	NewExterior_Ride_Dress_LeftBtn:SetProperty("Empty", "True")

	local ctrl_list = {
		[1] = NewExterior_Ride_Weapon_LeftBtn,
		[2] = NewExterior_Ride_PetPossJian_LeftBtn,
		[3] = NewExterior_Ride_FaceStyle_LeftBtn,
		[4] = NewExterior_Ride_HairStyle_LeftBtn,
		[5] = NewExterior_Ride_PlayerFrame_LeftBtn,
		[6] = NewExterior_Ride_Ride_LeftBtn,	
		[7] = NewExterior_Ride_Widget_LeftBtn,	
		[8] = NewExterior_Ride_Headdress_LeftBtn,	
	}
	
	for i = 1 ,8 do
		ctrl_list[i]:SetProperty("Empty", "False")
		ctrl_list[i]:SetProperty("UseDefaultTooltip", "True")
		ctrl_list[i]:SetProperty("NormalImage", "")
		ctrl_list[i]:SetProperty("HoverImage", "")
		ctrl_list[i]:SetToolTip("")
	end
	
	NewExterior_Ride_PlayerFrame_Mask:SetProperty("Image", "")
	NewExterior_Ride_PlayerFrame_Mask_Animate:SetProperty("Animate", "")
	
	NewExterior_Ride_Dress_ActionImg:Hide()
	NewExterior_Ride_Weapon_ActionImg:Hide()
	NewExterior_Ride_PetPossJian_ActionImg:Hide()
	NewExterior_Ride_FaceStyle_ActionImg:Hide()
	NewExterior_Ride_HairStyle_ActionImg:Hide()
	NewExterior_Ride_PlayerFrame_ActionImg:Hide()
	NewExterior_Ride_Ride_ActionImg:Hide()
	NewExterior_Ride_Widget_ActionImg:Hide()
	NewExterior_Ride_Headdress_ActionImg:Hide()

	NewExterior_Ride_Dress_LockImg:Hide()
	NewExterior_Ride_Weapon_LockImg:Hide()
	NewExterior_Ride_PetPossJian_LockImg:Hide()
	NewExterior_Ride_FaceStyle_LockImg:Hide()
	NewExterior_Ride_HairStyle_LockImg:Hide()
	NewExterior_Ride_PlayerFrame_LockImg:Hide()
	NewExterior_Ride_Ride_LockImg:Hide()
	NewExterior_Ride_Widget_LockImg:Hide()
	NewExterior_Ride_Headdress_LockImg:Hide()
end

function NewExterior_Ride_FakeObject_TurnLeft(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		if g_ViewMode == 0 then
			NewExterior_Ride_FakeObject:RotateBeginEx("Exterior_Player", -0.3)
		else
			NewExterior_Ride_FakeObject:RotateBeginEx("Exterior_Ride", -0.3)
		end
	else
		NewExterior_Ride_FakeObject:RotateEndEx()
	end
end

function NewExterior_Ride_FakeObject_TurnRight(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		if g_ViewMode == 0 then
			NewExterior_Ride_FakeObject:RotateBeginEx("Exterior_Player", 0.3)
		else
			NewExterior_Ride_FakeObject:RotateBeginEx("Exterior_Ride", 0.3)
		end		
	else
		NewExterior_Ride_FakeObject:RotateEndEx()
	end
end
--缩小
function NewExterior_Ride_ZoomOut()
--	if g_Distance == 1 then
--		return
--	end
	
--	g_Distance = g_Distance - 1	

end
--放大
function NewExterior_Ride_ZoomIn()
--	if g_Distance == g_Distance_Max then
--		return
--	end
	
--	g_Distance = g_Distance + 1	
end

function NewExterior_Ride_SwithViewMode()
	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("RIDE")
	if cacheExteriorID > 0 then
		if g_ViewMode == 0 then
			g_ViewMode = 1
		else
			g_ViewMode = 0
		end	
		NewExterior_Ride_UpdateObj()
	end	
end

function NewExterior_Ride_UpdateCheckButton()
--	NewExterior_Ride_ButtonHuanwu:SetCheck(0)
--	NewExterior_Ride_ButtonZhuangrong:SetCheck(0)
--	NewExterior_Ride_ButtonFuti:SetCheck(0)
--	NewExterior_Ride_ButtonZuoqi:SetCheck(1)
end

--右键取下时装
function NewExterior_Ride_ActionToDressBox()
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
		NewExterior_Ride_Show()
	end
	Exterior:LuaFnUnUseExteriorFashion(1)
end
--时装
function NewExterior_Ride_OpenFashion()
	NewExterior_Ride_SavePosition()
	PushEvent("OPEN_EXTERIOR_FASHION", 1, 0)
end
--幻武
function NewExterior_Ride_OpenWeapon()
	NewExterior_Ride_SavePosition()
	Exterior:LuaFnAskOpenExterior(1)
end
--附体
function NewExterior_Ride_OpenFuti()
	NewExterior_Ride_SavePosition()
	Exterior:LuaFnAskOpenExterior(2)
end
--坐骑
function NewExterior_Ride_OpenRide()
	--NewExterior_Ride_SavePosition()
	--Exterior:LuaFnAskOpenExterior(0)
	local cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("RIDE")
	Exterior:LuaFnExteriorRideItemClick(cacheExteriorID)
end
--发型
function NewExterior_Ride_OpenHair()
	NewExterior_Ride_SavePosition()	
	Exterior:LuaFnAskOpenExterior(4)
end
--脸型
function NewExterior_Ride_OpenFace()
	NewExterior_Ride_SavePosition()	
	Exterior:LuaFnAskOpenExterior(3)
end
--头像
function NewExterior_Ride_OpenPortrait()
	NewExterior_Ride_SavePosition()	
	Exterior:LuaFnAskOpenExterior(5)
end

--打开展示柜
function NewExterior_Ride_OpenYiRongGe()
	NewExterior_Ride_SavePosition()
	Exterior:LuaFnAskExteriorYiRongGeInfo(1, 2)
end

function NewExterior_Ride_OpenInfant()
	NewExterior_Ride_SavePosition()
	Exterior:LuaFnInitExteriorFashionList(2, 1)
end

function NewExterior_Ride_OpenOrnamentsBack()
	NewExterior_Ride_SavePosition()	
	OrnamentsScript:AskOrnamentsInfo(0)
end

function NewExterior_Ride_OpenOrnamentsHead()
	NewExterior_Ride_SavePosition()	
	OrnamentsScript:AskOrnamentsInfo(1)
end

function NewExterior_Ride_CloseSameGroupWindow()
	CloseWindow("SelfEquip", true)
	--CloseWindow("NewExterior_Ride", true)
	CloseWindow("NewExterior_Weapon", true)
	CloseWindow("NewExterior_PetPossJian", true)
	CloseWindow("NewExterior_Facestyle", true)
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

function NewExterior_Ride_SavePosition()
	Variable:SetVariable("ExteriorUnionPos", NewExterior_Ride_Frame:GetProperty("UnifiedPosition"), 1)
end

function NewExterior_Ride_SetPosition()
	
	local nExteriorUnionPos = Variable:GetVariable("ExteriorUnionPos")
	if nExteriorUnionPos ~= nil then
		NewExterior_Ride_Frame:SetProperty("UnifiedPosition", nExteriorUnionPos)
	end

end

function NewExterior_Ride_RemoveTip(nExteriorID)
	local nTip = Exterior:LuaFnGetExteriorTip(g_ExteriorType, nExteriorID)
	if nTip == 1 then
		Exterior:LuaFnRemoveExteriorTip(g_ExteriorType, nExteriorID)
		for i = 1, g_MaxBarNum do
			if g_BarList[i] then
				local nID = Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, i - 1)
				if Exterior:LuaFnGetExteriorTip(g_ExteriorType, nID) == 1 then
					g_BarList[i]:GetSubItem("NewExterior_Ride_SuperListItemActionTip"):Show()
				else
					g_BarList[i]:GetSubItem("NewExterior_Ride_SuperListItemActionTip"):Hide()
				end
			end
		end
	--	NewExterior_Ride_UpdateCheckButton()		
	end
end

function NewExterior_Ride_OpenAchievement()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("open")
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Parameter(0, -1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function NewExterior_Ride_OpenAchievementShop()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("open_shop")
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Parameter(0, -1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function NewExterior_Ride_UpdateRedPoint()

	NewExterior_Ride_Dress_Tip:Hide()
	
	if Exterior:LuaFnIsHaveExteriorShowTip(0) == 1 then
		NewExterior_Ride_Ride_Tip:Show()
	else
		NewExterior_Ride_Ride_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(1) == 1 then
		NewExterior_Ride_Weapon_Tip:Show()
	else
		NewExterior_Ride_Weapon_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(2) == 1 then
		NewExterior_Ride_PetPossJian_Tip:Show()
	else
		NewExterior_Ride_PetPossJian_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(3) == 1 then
		NewExterior_Ride_FaceStyle_Tip:Show()
	else
		NewExterior_Ride_FaceStyle_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(4) == 1 or Exterior:LuaFnIsHaveHairColorShowTip() == 1 then
		NewExterior_Ride_HairStyle_Tip:Show()
	else
		NewExterior_Ride_HairStyle_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(5) == 1 or Exterior:LuaFnIsHaveExteriorShowTip(6) == 1 then
		NewExterior_Ride_PlayerFrame_Tip:Show()
	else
		NewExterior_Ride_PlayerFrame_Tip:Hide()
	end

	if Pneuma:GetMF(2959)== 1 or Exterior:LuaFnIsHaveExteriorShowTip(7) == 1 or Exterior:LuaFnIsHaveInfantHairColorShowTip() == 1 then 
		NewExterior_Ride_SwitchBtn_Tip:Show()
	else
		NewExterior_Ride_SwitchBtn_Tip:Hide()
	end

	if OrnamentsScript:IsHaveOrnamentsShowTip(0) == 1 then
		NewExterior_Ride_Widget_Tip:Show()
	else
		NewExterior_Ride_Widget_Tip:Hide()
	end

	if OrnamentsScript:IsHaveOrnamentsShowTip(1) == 1 then
		NewExterior_Ride_Headdress_Tip:Show()
	else
		NewExterior_Ride_Headdress_Tip:Hide()
	end
end

function NewExterior_Ride_ShowFashionWeaponCheckButton()
	local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
	NewExterior_Ride_Dress_Type:SetCheck(IsDisplay)
	
	IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
	NewExterior_Ride_Weapon_Type:SetCheck(IsDisplay)

	IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
	NewExterior_Ride_Widget_Type:SetCheck(IsDisplay)
	
	IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
	NewExterior_Ride_Headdress_Type:SetCheck(IsDisplay)

	IsDisplay = SystemSetup:Lua_GetFuTiDisplayState()
	NewExterior_Ride_PetPossJian_Type:SetCheck(IsDisplay)
end

function NewExterior_Ride_FashionDisplay()
	local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
	if IsDisplay == 1 then
		NewExterior_Ride_Dress_Type:SetCheck(0)
		SystemSetup:LuaFnCloseFashionDisplay(1)
	else
		NewExterior_Ride_Dress_Type:SetCheck(1)
		SystemSetup:LuaFnCloseFashionDisplay(0)
	end	
end

function NewExterior_Ride_ExteriorWeaponDisplay()
	local IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
	if IsDisplay == 1 then
		NewExterior_Ride_Weapon_Type:SetCheck(0)
		SystemSetup:LuaFnCloseExteriorWeaponDisplay(1)
	else
		NewExterior_Ride_Weapon_Type:SetCheck(1)
		SystemSetup:LuaFnCloseExteriorWeaponDisplay(0)
	end	
end

function NewExterior_Ride_OrnamentsBackDisplay()
	local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
	if IsDisplay == 1 then
		NewExterior_Ride_Widget_Type:SetCheck(0)
		SystemSetup:SetOrnamentsDisplayState(0, 1)
		OrnamentsScript:ResetOrnamentsUseInfo(0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		NewExterior_Ride_Widget_Type:SetCheck(1)
		SystemSetup:SetOrnamentsDisplayState(0, 0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	end	
end

function NewExterior_Ride_OrnamentsHeadDisplay()
	local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
	if IsDisplay == 1 then
		NewExterior_Ride_Headdress_Type:SetCheck(0)
		SystemSetup:SetOrnamentsDisplayState(1, 1)
		OrnamentsScript:ResetOrnamentsUseInfo(1)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		NewExterior_Ride_Headdress_Type:SetCheck(1)
		SystemSetup:SetOrnamentsDisplayState(1, 0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	end	
end

function NewExterior_Ride_ActionToOrnamentsBack()
	local useID = OrnamentsScript:GetOrnamentsUseID(0)
	if useID > 0 then
		OrnamentsScript:TakeOffOrnaments(0)
	end
	Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSBACK", 0, 0, 0, 0)
	Exterior:LuaFnSetCurExteriorShareInfo("ORNAMENTSBACK", 0, 0, 0, 0)
	NewExterior_Ride_UpdateLeftBtn()
	Exterior:LuaFnRestoreExteriorPlayerFittingData(6)
	Exterior:LuaFnUpdateExteriorPlayerData()
end

function NewExterior_Ride_ActionToOrnamentsHead()
	local useID = OrnamentsScript:GetOrnamentsUseID(1)
	if useID > 0 then
		OrnamentsScript:TakeOffOrnaments(1)
	end
	Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSHEAD", 0, 0, 0, 0)
	Exterior:LuaFnSetCurExteriorShareInfo("ORNAMENTSHEAD", 0, 0, 0, 0)
	NewExterior_Ride_UpdateLeftBtn()
	Exterior:LuaFnRestoreExteriorPlayerFittingData(7)
	Exterior:LuaFnUpdateExteriorPlayerData()
end

-- 来源
function NewExterior_Ride_CloseTuJing()
	if IsWindowShow("NewExterior_TuJing") then
		CloseWindow("NewExterior_TuJing", true)
	end
end

-- 来源
function NewExterior_Ride_ClickTuJing()
	if g_CurSelExteriorID > 0 then		
		PushEvent("OPEN_EXTERIOR_TUJING", g_ExteriorType, g_CurSelExteriorID, -1, -1)
	else
		PushDebugMessage("#{SZDP_230509_64}")
	end
end

--方案
function NewExterior_Ride_UpdateFangAn()
	
	local g_CurSelShareStyleIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("STYLE")	
	if g_CurSelShareStyleIdx > 0 then
		Exterior:LuaFnTryExteriorShareInfo(g_CurSelShareStyleIdx-1)
	end
	
end

function NewExterior_Ride_ChangeSex()
	local sex = Exterior:LuaFnGetExteriorRaceID()
	if sex ~= nil then
		if sex == g_PlayerRace.SEX_FEMALE then
			Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_MALE)
		elseif sex == g_PlayerRace.SEX_MALE then
			Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_FEMALE)
		end
		NewExterior_Ride_Show()
	end
end

function NewExterior_Ride_GenderUpdate()
	local sex = Exterior:LuaFnGetExteriorRaceID()
	if sex ~= nil and g_sexButtonInfo[sex] ~= nil then
		NewExterior_Ride_GenderChange_Btn:SetProperty("HoverImage", g_sexButtonInfo[sex].imgH)
		NewExterior_Ride_GenderChange_Btn:SetProperty("NormalImage", g_sexButtonInfo[sex].imgN)
		NewExterior_Ride_GenderChange_Btn:SetProperty("PushedImage", g_sexButtonInfo[sex].imgP)
	end
end

function NewExterior_Ride_PetPossJianDisplay()
	local IsDisplay = SystemSetup:Lua_GetFuTiDisplayState()
	if IsDisplay == 1 then
		NewExterior_Ride_PetPossJian_Type:SetCheck(0)
		SystemSetup:Lua_SetFuTiDisplayState(1)
	else
		NewExterior_Ride_PetPossJian_Type:SetCheck(1)
		SystemSetup:Lua_SetFuTiDisplayState(0)
	end	
end

function NewExterior_Ride_ShowSubPage()
	if g_CurSubPage == 0 then
		NewExterior_Ride_SuperList_Page1:SetCheck(1)
		NewExterior_Ride_SuperList_Page2:SetCheck(0)
		--坐骑
		NewExterior_Ride_SuperList_Client:Show()
		--典藏
		NewExterior_Ride_SuperList2_Client:Hide()
	--	NewExterior_Ride_SuperList3Text_Desc:Hide()
	--	NewExterior_Ride_SuperList3Title:Hide()
	--	NewExterior_Ride_SuperListTit_Text2:Hide()
	elseif g_CurSubPage == 1 then
		NewExterior_Ride_SuperList_Page1:SetCheck(0)
		NewExterior_Ride_SuperList_Page2:SetCheck(1)
		--坐骑
		NewExterior_Ride_SuperList_Client:Hide()
		--典藏
		NewExterior_Ride_SuperList2_Client:Show()
	--	NewExterior_Ride_SuperList3Text_Desc:Show()
	--	NewExterior_Ride_SuperList3Title:Show()
	--	NewExterior_Ride_SuperListTit_Text2:Show()
	end
end

--!!!reloadscript =NewExterior_Ride