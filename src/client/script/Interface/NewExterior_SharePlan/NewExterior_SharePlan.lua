
--!!!reloadscript =NewExterior_SharePlan

local g_NewExterior_SharePlan_UnifiedPosition = ""

local g_SharePlan_Distance = 1
local g_SharePlan_Distance_Ori = 2
local g_SharePlan_Distance_Max = 4

local g_CameraHeight = 1     --摄影机高度
local g_CameraDistance = 2   --摄影机距离
local g_CameraPitch = 3      --摄影机角度
local g_CameraPosition =
{
	--女性相关位置
	[0] = {
		{fHeight = 0.82, fDistance = 8,   fPitch=0.1},
		{fHeight = 0.82, fDistance = 6.5, fPitch=0.1},
		{fHeight = 1.5,  fDistance = 2.5, fPitch=0.1},
		{fHeight = 1.57, fDistance = 1.7, fPitch=0.1}
	},
	--男性相关位置
	[1] = {
		{fHeight = 0.91,  fDistance = 8.8, fPitch=0.2},
		{fHeight = 0.91,  fDistance = 7.1, fPitch=0.2},
		{fHeight = 1.67,  fDistance = 2.5, fPitch=0.2},
		{fHeight = 1.745, fDistance = 1.7, fPitch=0.2}
	},
}

local g_NewExterior_SharePlan_ViewMode = 0 --0是角色 1是上坐骑

local g_NewExterior_SharePlan_Button = {}

--=========
--PreLoad==
--=========
function NewExterior_SharePlan_PreLoad()

	this:RegisterEvent("OPEN_EXTERIOR_SHAREUI")
		
	this:RegisterEvent("ON_SCENE_TRANS",false)
	this:RegisterEvent("ON_SERVER_TRANS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("ADJEST_UI_POS",false)	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("OPEN_STALL_SALE",false)
	this:RegisterEvent("PROGRESSBAR_SHOW",false)
	this:RegisterEvent("MODELID_CHANGE",false)
	
end

--=========
--OnLoad
--=========
function NewExterior_SharePlan_OnLoad()

	g_NewExterior_SharePlan_UnifiedPosition = NewExterior_SharePlan_Frame:GetProperty("UnifiedPosition")
	
	g_NewExterior_SharePlan_Button[1] = NewExterior_SharePlan_Dress_LeftBtn
	g_NewExterior_SharePlan_Button[2] = NewExterior_SharePlan_Ride_LeftBtn
	g_NewExterior_SharePlan_Button[3] = NewExterior_SharePlan_FaceStyle_LeftBtn
	g_NewExterior_SharePlan_Button[4] = NewExterior_SharePlan_HairStyle_LeftBtn
	g_NewExterior_SharePlan_Button[5] = NewExterior_SharePlan_Weapon_LeftBtn
	g_NewExterior_SharePlan_Button[6] = NewExterior_SharePlan_PetSoul_LeftBtn
	
end

--=========
--OnEvent
--=========
function NewExterior_SharePlan_OnEvent(event)
	
	if event == "OPEN_EXTERIOR_SHAREUI" then
		if this:IsVisible() then
			NewExterior_SharePlan_Close()	
			return
		end	
		
		NewExterior_SharePlan_Show()				
		return
	end
	
	if event == "OPEN_STALL_SALE"			-- 开始摆摊，还原试穿
		or event == "PROGRESSBAR_SHOW"		-- 读进度条中，还原试穿
		or event == "MODELID_CHANGE" 		-- 变身 关闭界面
	then
		NewExterior_SharePlan_Close()	
		return
	end
	
	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
		if this:IsVisible() then
			NewExterior_SharePlan_Close()	
		end
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		NewExterior_SharePlan_On_ResetPos()
	end
	
end

function NewExterior_SharePlan_Show()		
				
	this:Show()
	
	g_SharePlan_Distance = g_SharePlan_Distance_Ori
	
	NewExterior_SharePlan_CleanUp()
		
	local theDragTitle = Exterior:LuaFnGetExteriorOtherShareLinkInfo("NAME")
	NewExterior_SharePlan_TitleText:SetText(theDragTitle)
				
	--左侧
	NewExterior_SharePlan_UpdateBtn()
	
	--模型
	NewExterior_SharePlan_UpdateObj()
	
end

--左侧
function NewExterior_SharePlan_UpdateBtn()
	
	local sex = Exterior:LuaFnGetExteriorOtherShareLinkInfo("SEX")
	
	--时装
	local theAction, bLocked = Exterior:LuaFnGetExteriorOtherShareLinkInfo("DRESS")
	if theAction ~= nil and theAction:GetID() ~= 0 then
		NewExterior_SharePlan_Dress_LeftBtn:SetActionItem(theAction:GetID())
	else
		NewExterior_SharePlan_Dress_LeftBtn:SetActionItem(-1)	
	end
	
	--坐骑
	local edType = 0	
	local cacheExteriorID, nRideTime = Exterior:LuaFnGetExteriorOtherShareLinkInfo("RIDE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Name")
		local strIcon = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_SharePlan_Ride_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_SharePlan_Ride_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{SZDP_230509_02}", strName)
		NewExterior_SharePlan_Ride_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_SharePlan_Ride_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_SharePlan_Ride_LockImg:Show()
		end
	end
	
	--幻武
	edType = 1
	local cacheExteriorLevel = 0
	cacheExteriorID, cacheExteriorLevel, _ = Exterior:LuaFnGetExteriorOtherShareLinkInfo("WEAPON")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Name")
		local strIcon 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_SharePlan_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_SharePlan_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{SZDP_230509_02}", strName)
		NewExterior_SharePlan_Weapon_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_SharePlan_Weapon_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_SharePlan_Weapon_LockImg:Show()
		end
	end
	
	--附体
	edType = 2
	local cacheVisualIndex, cacheExteriorRHD = 0, 0
	cacheExteriorID, cacheVisualIndex, cacheExteriorRHD = Exterior:LuaFnGetExteriorOtherShareLinkInfo("FUTI")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "Name")
		local strImage 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "VisualIcon", cacheVisualIndex)
		NewExterior_SharePlan_PetPossJian_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_SharePlan_PetPossJian_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{SZDP_230509_02}", strName)
		NewExterior_SharePlan_PetPossJian_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_SharePlan_PetPossJian_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorFutiVisualIndex() ~= cacheVisualIndex then
				NewExterior_SharePlan_PetPossJian_ActionImg:Show()
			end
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 
			or Exterior:LuaFnIsExteriorFutiVisualUnlocked(cacheExteriorID, cacheVisualIndex) ~= 1 
		then
			NewExterior_SharePlan_PetPossJian_LockImg:Show()
		end
	end
	
	--脸型
	edType = 3
	cacheExteriorID = Exterior:LuaFnGetExteriorOtherShareLinkInfo("FACE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_SharePlan_FaceStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_SharePlan_FaceStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{SZDP_230509_02}", strName)
		NewExterior_SharePlan_FaceStyle_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_SharePlan_FaceStyle_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_SharePlan_FaceStyle_LockImg:Show()
		end
	end
	
	--发型
	edType = 4
	local cacheColorValue = 0
	cacheExteriorID, cacheColorValue = Exterior:LuaFnGetExteriorOtherShareLinkInfo("HAIR")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_SharePlan_HairStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_SharePlan_HairStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{SZDP_230509_02}", strName)
		NewExterior_SharePlan_HairStyle_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_SharePlan_HairStyle_ActionImg:Show()
		else
			if cacheColorValue ~= 0 and Exterior:LuaFnIsHaveHairColorValue(cacheColorValue) ~= 1 then
				NewExterior_SharePlan_HairStyle_ActionImg:Show()
			end
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_SharePlan_HairStyle_LockImg:Show()
		end
	end
	
	--头像
	edType = 5
	local strHeadTip = ""
	cacheExteriorID = Exterior:LuaFnGetExteriorOtherShareLinkInfo("PORTRAIT")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorPortraitInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorPortraitInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_SharePlan_PlayerFrame_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_SharePlan_PlayerFrame_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{SZDP_230509_02}", strName)
		strHeadTip = strTemp
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_SharePlan_PlayerFrame_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_SharePlan_PlayerFrame_LockImg:Show()
		end		
	end
	
	--头像框
	edType = 6
	cacheExteriorID = Exterior:LuaFnGetExteriorOtherShareLinkInfo("FRAME")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Name")
		local iFrameType = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Type")
		if iFrameType == 1 then
			NewExterior_SharePlan_PlayerFrame_Mask:Hide()
			NewExterior_SharePlan_PlayerFrame_Mask_Animate:Show()
			
			local strFrameAnimate = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameAnimate")
			NewExterior_SharePlan_PlayerFrame_Mask_Animate:SetProperty("Animate", strFrameAnimate)
		else
			NewExterior_SharePlan_PlayerFrame_Mask:Show()
			NewExterior_SharePlan_PlayerFrame_Mask_Animate:Hide()
			
			local strIcon 	= Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameIcon")
			local strImage = GetIconFullName(strIcon)
			NewExterior_SharePlan_PlayerFrame_Mask:SetProperty("Image", strImage)
		end

		local strTemp = ScriptGlobal_Format("#{SZDP_230509_02}", strName)
		NewExterior_SharePlan_PlayerFrame_LeftBtn:SetToolTip(strHeadTip.."#r"..strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_SharePlan_PlayerFrame_ActionImg:Show()
		end	
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_SharePlan_PlayerFrame_LockImg:Show()
		end	
	end
	
	local edOrnamentsType, cacheExteriorX, cacheExteriorY, cacheExteriorZ = 0, 0, 0, 0
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetExteriorOtherShareLinkInfo("OrnamentsBack")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_SharePlan_Widget_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_SharePlan_Widget_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{SZDP_230509_02}", strName)
		NewExterior_SharePlan_Widget_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_SharePlan_Widget_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
			NewExterior_SharePlan_Widget_LockImg:Show()
		end
	end

	edOrnamentsType = 1
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetExteriorOtherShareLinkInfo("OrnamentsHead")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_SharePlan_Headdress_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_SharePlan_Headdress_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{SZDP_230509_02}", strName)
		NewExterior_SharePlan_Headdress_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_SharePlan_Headdress_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
			NewExterior_SharePlan_Headdress_LockImg:Show()
		end
	end
		
end

--模型
function NewExterior_SharePlan_UpdateObj()

	NewExterior_SharePlan_FakeObject:DetachWindowEx()
	NewExterior_SharePlan_FakeObject:AttachWindowEx("Exterior_OtherShare")
		
	Exterior:LuaFnExteriorOtherShareLinkAvatar()
	
	if g_NewExterior_SharePlan_ViewMode == 0 then	
		Exterior:LuaFnExteriorOtherShareLinkAvatarMount(-1)	
		
		NewExterior_SharePlan_UpdateCamera()
	else
		local nRideId, nRideTime = Exterior:LuaFnGetExteriorOtherShareLinkInfo("RIDE")
		if nRideId ~= nil and nRideId > 0 then		
			local nMountId = Exterior:LuaFnGetExteriorRideInfo(nRideId, "MountId")	
			Exterior:LuaFnExteriorOtherShareLinkAvatarMount(nMountId)	
			
			local fHeight, fDistance, fPitch = NewExterior_SharePlan_FakeObject:GetCameraEx()
			fHeight, fDistance = Exterior:LuaFnGetExteriorRideCameraParam(nMountId, 1)
			NewExterior_SharePlan_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)
		end
	end
	
end

--试乘
function NewExterior_SharePlan_ViewModeClicked()

	local nRideId, nRideTime = Exterior:LuaFnGetExteriorOtherShareLinkInfo("RIDE")
	if nRideId ~= nil and nRideId > 0 then
		if g_NewExterior_SharePlan_ViewMode == 0 then
			g_NewExterior_SharePlan_ViewMode = 1	

			NewExterior_SharePlan_Model_Plus:Hide()
			NewExterior_SharePlan_Model_Subtract:Hide()
		else
			g_NewExterior_SharePlan_ViewMode = 0
			
			NewExterior_SharePlan_Model_Plus:Show()
			NewExterior_SharePlan_Model_Subtract:Show()
		end	
			
		NewExterior_SharePlan_UpdateObj()
	end	
	
end

--导入
function NewExterior_SharePlan_ImportClicked()

end

--界面位置
function NewExterior_SharePlan_On_ResetPos()

	NewExterior_SharePlan_Frame:SetProperty("UnifiedPosition", g_NewExterior_SharePlan_UnifiedPosition);
	
end

--关闭按钮
function NewExterior_SharePlan_Close()	
		
	this:Hide()
	
end

--esc
function NewExterior_SharePlan_OnHidden()
	
	NewExterior_SharePlan_CleanUp()
	
end

--清空
function NewExterior_SharePlan_CleanUp()
	
	g_NewExterior_SharePlan_ViewMode = 0

	NewExterior_SharePlan_FakeObject:DetachWindowEx()
		
	local ctrl_list = {
		[1] = NewExterior_SharePlan_Weapon_LeftBtn,
		[2] = NewExterior_SharePlan_Ride_LeftBtn,
		[3] = NewExterior_SharePlan_FaceStyle_LeftBtn,
		[4] = NewExterior_SharePlan_HairStyle_LeftBtn,
		[5] = NewExterior_SharePlan_PetPossJian_LeftBtn,
		[6] = NewExterior_SharePlan_PlayerFrame_LeftBtn,
		[7] = NewExterior_SharePlan_Widget_LeftBtn,
		[8] = NewExterior_SharePlan_Headdress_LeftBtn,
	}
	
	for i = 1 ,8 do
		ctrl_list[i]:SetProperty("Empty", "False")
		ctrl_list[i]:SetProperty("UseDefaultTooltip", "True")
		ctrl_list[i]:SetProperty("NormalImage", "")
		ctrl_list[i]:SetProperty("HoverImage", "")
		ctrl_list[i]:SetToolTip("")
	end
	
	NewExterior_SharePlan_PlayerFrame_Mask:SetProperty("Image", "")
	NewExterior_SharePlan_PlayerFrame_Mask_Animate:SetProperty("Animate", "")

	NewExterior_SharePlan_Dress_LockImg:Hide()
	NewExterior_SharePlan_Weapon_LockImg:Hide()
	NewExterior_SharePlan_Ride_LockImg:Hide()
	NewExterior_SharePlan_FaceStyle_LockImg:Hide()
	NewExterior_SharePlan_HairStyle_LockImg:Hide()
	NewExterior_SharePlan_PetPossJian_LockImg:Hide()
	NewExterior_SharePlan_PlayerFrame_LockImg:Hide()
	NewExterior_SharePlan_Widget_LockImg:Hide()
	NewExterior_SharePlan_Headdress_LockImg:Hide()
	
	NewExterior_SharePlan_Dress_ActionImg:Hide()
	NewExterior_SharePlan_Weapon_ActionImg:Hide()
	NewExterior_SharePlan_Ride_ActionImg:Hide()	
	NewExterior_SharePlan_FaceStyle_ActionImg:Hide()
	NewExterior_SharePlan_HairStyle_ActionImg:Hide()
	NewExterior_SharePlan_PetPossJian_ActionImg:Hide()
	NewExterior_SharePlan_PlayerFrame_ActionImg:Hide()
	NewExterior_SharePlan_Widget_ActionImg:Hide()
	NewExterior_SharePlan_Headdress_ActionImg:Hide()
	
	NewExterior_SharePlan_Model_Plus:Show()
	NewExterior_SharePlan_Model_Subtract:Show()
			
end

--摄像机
function NewExterior_SharePlan_UpdateCamera()

	local sex = Exterior:LuaFnGetExteriorOtherShareLinkInfo("SEX")
	if g_CameraPosition[sex] == nil then 
		return
	end
		
	if g_SharePlan_Distance < 1 or g_SharePlan_Distance > g_SharePlan_Distance_Max then
		return
	end

	local fHeight, fDistance, fPitch = NewExterior_SharePlan_FakeObject:GetCameraEx()
	fHeight = g_CameraPosition[sex][g_SharePlan_Distance].fHeight
	fDistance = g_CameraPosition[sex][g_SharePlan_Distance].fDistance
	fPitch = g_CameraPosition[sex][g_SharePlan_Distance].fPitch

	NewExterior_SharePlan_FakeObject:SetCameraEx(fHeight, fDistance, fPitch, 0)	

end

--左转
function NewExterior_SharePlan_FakeObject_TurnLeft(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		NewExterior_SharePlan_FakeObject:RotateBeginEx("Exterior_OtherShare", -0.3)
	else
		NewExterior_SharePlan_FakeObject:RotateEndEx()
	end
	
end

--右转
function NewExterior_SharePlan_FakeObject_TurnRight(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		NewExterior_SharePlan_FakeObject:RotateBeginEx("Exterior_OtherShare", 0.3)
	else
		NewExterior_SharePlan_FakeObject:RotateEndEx()
	end
	
end

--缩小
function NewExterior_SharePlan_ZoomOut()

	if g_SharePlan_Distance == 1 then
		return
	end
	
	g_SharePlan_Distance = g_SharePlan_Distance - 1	

	NewExterior_SharePlan_UpdateCamera()
	
end

--放大
function NewExterior_SharePlan_ZoomIn()

	if g_SharePlan_Distance == g_SharePlan_Distance_Max then
		return
	end
	
	g_SharePlan_Distance = g_SharePlan_Distance + 1	
	
	NewExterior_SharePlan_UpdateCamera()

end

--!!!reloadscript =NewExterior_SharePlan