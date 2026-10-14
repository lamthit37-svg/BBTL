--!!!reloadscript =NewExterior_DressBox

local EXTERIORFILTTING_TOTALKIND = 6;
local g_NewExterior_DressBox_UnifiedPosition = ""

local g_TargetExteriorIndex = 0		--定位的外观索引，从1开始
local g_TargetExteriorID = 0		--定位的外观ID

local g_NeedChangeScrollSize = 1

local g_CurSelExteriorIndex = 0		--当前选择的外观索引，从1开始
local g_CurSelExteriorID = 0		--当前选择的外观ID，从1开始
local g_actionVisualID = 0
local g_DressBox_FangAn_Max = 5

local g_Distance = 1
local g_Distance_Ori = 2
local g_Distance_Max = 4
local g_InitList = 0
local m_PlayerfashionDepotType = 1 	--仓库类型 1 玩家时装仓库 2 子女时装仓库
local g_ExteriorType = 8 --时装
local g_MaxBarNum = 300
local g_BarList = {}
local g_PlayerFashionInfoList = {}

local g_ActionButtonList = {}
local g_TransformButtonList = {}

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

local g_SpecialFashionCamera = {
-- 桃花醉
[1] = {startid = 10126405, endid = 10126420, fHeight = 1.9, fDistance = 20, fPitch = -1, timecount = 21000},
-- 千里江山
[2] = {startid = 10126295, endid = 10126310, fHeight = -1, fDistance = -1, fPitch = -1, timecount = 42000},
-- 桃花醉-新加了一套
[3] = {startid = 10126771, endid = 10126773, fHeight = 1.9, fDistance = 20, fPitch = -1, timecount = 21000},
}

local g_NumberingFashionCamera = { fHeight = 1.9, fDistance = 20, timecount1 = 9000, timecount2 = 10000 }

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
function NewExterior_DressBox_PreLoad()

	this:RegisterEvent("OPEN_EXTERIOR_FASHION")
	this:RegisterEvent("UPDATE_EXTERIOR_FASHION",false)
	this:RegisterEvent("EXTERIOR_FASHION_OP", false)
	this:RegisterEvent("UPDATE_EXTERIOR_SHARESTYLE",false)
	
	this:RegisterEvent("ADD_EXTERIOR",false)
	this:RegisterEvent("UPDATE_EXTERIOR",false)
	this:RegisterEvent("EXTERIOR_OUTTIME",false)
	this:RegisterEvent("EXTERIOR_ID_CHANGED",false)
	this:RegisterEvent("EXERIOR_SAVEALL_RET", false)
	
	this:RegisterEvent("ON_SCENE_TRANS",false)
	this:RegisterEvent("ON_SERVER_TRANS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("ADJEST_UI_POS",false)	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("OPEN_STALL_SALE",false)
	this:RegisterEvent("PROGRESSBAR_SHOW",false)
	this:RegisterEvent("MODELID_CHANGE",false)
	this:RegisterEvent("ORNAMENTS_DISPLAYUPDATE",false)

	this:RegisterEvent("UI_COMMAND")
	
end

--=========
--OnLoad
--=========
function NewExterior_DressBox_OnLoad()
	g_NewExterior_DressBox_UnifiedPosition = NewExterior_DressBox_Frame:GetProperty("UnifiedPosition")
	
	g_ActionButtonList = {
		NewExterior_DressBox_FashionAction_MidBtn1,
		NewExterior_DressBox_FashionAction_MidBtn2,
		NewExterior_DressBox_FashionAction_MidBtn3,
		NewExterior_DressBox_FashionAction_MidBtn4,
		NewExterior_DressBox_FashionAction_MidBtn5,
	}
	
	g_TransformButtonList = {
		NewExterior_DressBox_Transform_MidBtn1,
		NewExterior_DressBox_Transform_MidBtn2,
		NewExterior_DressBox_Transform_MidBtn3,
		NewExterior_DressBox_Transform_MidBtn4,
		NewExterior_DressBox_Transform_MidBtn5,
	}
end

--=========
--OnEvent
--=========
function NewExterior_DressBox_OnEvent(event)
	
	if event == "OPEN_EXTERIOR_FASHION" then
		if this:IsVisible() then
			if tonumber(arg0) == 0 then
				NewExterior_DressBox_SavePosition()
				this:Hide()
			end
		else
			if tonumber(arg0) == m_PlayerfashionDepotType then			
				--关闭元宝商店相关界面
				if IsWindowShow("VIP_Shop") then
					CloseWindow("VIP_Shop", true)
				end
				if(IsWindowShow("YuanbaoShop")) then
					CloseWindow("YuanbaoShop", true)
				end
				if(IsWindowShow("ShowShop")) then
					CloseWindow("ShowShop", true)
				end
				if(IsWindowShow("XuanShop")) then
					CloseWindow("XuanShop", true)
				end
				
				PushEvent( "CLOSE_DRESSPREVIEW") 
				PushEvent( "CLOSE_GEMEFFECTPREVIEW")
				EXTERIORFILTTING_TOTALKIND = Exterior:LuaFnGetExteriorPlayerFittingCount()
				
				if tonumber(arg1) == 1 then	
					Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")					
					Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
				end
				
				--m_PlayerfashionDepotType = tonumber(arg0)
			
				NewExterior_DressBox_SetPosition()
				NewExterior_DressBox_CloseSameGroupWindow()
				this:Show()
				NewExterior_DressBox_Show()
					
				--if g_TargetExteriorIndex ~= 0 then
				--	NewExterior_DressBox_SuperList:SetScrollPosition4Index(g_TargetExteriorIndex - 1)
				--	g_TargetExteriorID = 0
				--	g_TargetExteriorIndex = 0
				--else
				--	NewExterior_DressBox_SuperList:SetScrollPosition4Index(0)
				--end
			end
		end	
		return
	end
	
	if event == "EXERIOR_SAVEALL_RET" then
		Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
		Exterior:LuaFnInitCurrentExteriorSet()
		NewExterior_DressBox_Show()
	end
	
	if ( event == "OPEN_STALL_SALE" ) -- 开始摆摊，还原试穿
		or ( event == "PROGRESSBAR_SHOW" )		-- 读进度条中，还原试穿
		or ( event == "MODELID_CHANGE" ) -- 变身 关闭界面
		then
		NewExterior_DressBox_CloseClick()	
		return
	end
	
	if event == "ADD_EXTERIOR" or event == "UPDATE_EXTERIOR" or event == "EXTERIOR_OUTTIME" or event == "EXTERIOR_ID_CHANGED" then
		--左侧
		NewExterior_DressBox_UpdateLeftBtn()
		NewExterior_DressBox_UpdateRedPoint()
		--模型
		Exterior:LuaFnUpdateExteriorPlayerData()
		Exterior:LuaFnUpdateExteriorPlayerData()
	end
	
	if event == "EXTERIOR_FASHION_OP" then
		if tonumber(arg0) == 1 then
			if tonumber(arg1) == 1 and (this:IsVisible()) then
				-- enFashionDepotOPType_DepositOnly 背包右键存入衣柜 
				local nSourcePos = tonumber(arg2)
				local targetPos = -1
				--Optype enCGFashionDepotOperationType_Deposit = 1
				NewExterior_DressBox_BagToFashionDepot(1, nSourcePos, targetPos)
				return
			end
			if tonumber(arg1) == 2 and (this:IsVisible()) then
				-- enFashionDepotOPType_BagMoveToDressBox 背包拖拽存入衣柜
				local nSourcePos = tonumber(arg2)
				local targetPos = tonumber(arg3)
				--Optype enCGFashionDepotOperationType_Deposit = 1
				NewExterior_DressBox_BagToFashionDepot(1, nSourcePos, targetPos)
				return
			end
			if tonumber(arg1) == 3 and (this:IsVisible()) then
				-- enFashionDepotOPType_Move 衣柜内拖拽
				local nSourcePos = tonumber(arg2)
				local targetPos = tonumber(arg3)
				if nSourcePos == targetPos then --相同格子不用进行移动
					return
				end
				Exterior:LuaFnExteriorFashionOperation(m_PlayerfashionDepotType, 3, nSourcePos, targetPos)
			end
			if tonumber(arg1) == 4 and (this:IsVisible()) then
				-- enFashionDepotOPType_TakeOut 右键衣柜时装取出到背包
				local nSourcePos = tonumber(arg2)
				local targetPos = tonumber(arg3)
				NewExterior_DressBox_FashionDepotToBag(nSourcePos, targetPos)
			end
			
			if tonumber(arg1) == 6 and (this:IsVisible()) then
				NewExterior_DressBox_SuperListArrangeBtn:Disable()
			end
			if tonumber(arg1) == 7 and (this:IsVisible()) then
				NewExterior_DressBox_SuperListArrangeBtn:Enable()
				NewExterior_DressBox_Show()
			end
		end
		return
	end
	
	if event == "UPDATE_EXTERIOR_FASHION" then
		if tonumber(arg0) == 1 then
			--init
			NewExterior_DressBox_InitList()	
			--列表
			NewExterior_DressBox_UpdateList()
			--搭配方案
			NewExterior_DressBox_UpdateFangAn()
			--左侧
			NewExterior_DressBox_UpdateLeftBtn()
			--模型
			NewExterior_DressBox_UpdateObj()
		end
		return
	end
	
	if event == "UPDATE_EXTERIOR_SHARESTYLE" then
		if this:IsVisible() and arg0 then
			--init
			NewExterior_DressBox_InitList()	
			--列表
			NewExterior_DressBox_UpdateList()
			--搭配方案
			NewExterior_DressBox_UpdateFangAn()
			--左侧
			NewExterior_DressBox_UpdateLeftBtn()
			--模型
			NewExterior_DressBox_UpdateObj()
		end
		return
	end

	if event == "ORNAMENTS_DISPLAYUPDATE" then
		-- 刷新模型
		Exterior:LuaFnUpdateExteriorPlayerData()
		return
	end

	-- FakeObject模型界面互斥
	if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
	   ( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
		if (this:IsVisible()) then
			NewExterior_DressBox_CloseClick()
			return
		end
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 80081701 ) then
		local bagIdx = Get_XParam_INT(0)
		if bagIdx == nil or bagIdx < 0 then
			return
		end
		if this:IsVisible() then
			NewExterior_DressBox_CloseClick()
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetClick" )
			Set_XSCRIPT_ScriptID( 800817 )
			Set_XSCRIPT_Parameter(0,bagIdx)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
	
	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		NewExterior_DressBox_Frame:SetProperty("UnifiedPosition", g_NewExterior_DressBox_UnifiedPosition)
	end

end

function NewExterior_DressBox_InitList()
	
	if g_InitList == 0 then				
		for i = 1, g_MaxBarNum do
			local bar = NewExterior_DressBox_SuperList:AddChild("NewExterior_DressBox_SuperListItem")
			
			bar:GetSubItem("NewExterior_DressBox_SuperListItemAction"):SetEvent("Clicked", string.format("NewExterior_DressBox_ItemClicked(%d)", i))
			bar:GetSubItem("NewExterior_DressBox_SuperListItemAction"):SetEvent("RBClicked", string.format("NewExterior_DressBox_ItemBtnClicked(%d)", i))
			--bar:GetSubItem("NewExterior_DressBox_SuperListItemAction"):SetEvent("MouseMove", string.format("NewExterior_DressBox_ItemMouseMove(%d)", i))
			bar:GetSubItem("NewExterior_DressBox_SuperListItemAction"):SetProperty("DraggingEnabled", "True")
			local kidx = i-1
			bar:GetSubItem("NewExterior_DressBox_SuperListItemAction"):SetProperty("DragAcceptName", "K"..tostring(kidx))
			--小红点 不需要
			bar:GetSubItem("NewExterior_DressBox_SuperListItemActionTip"):Hide()
			--小锁 不需要
			--bar:GetSubItem("NewExterior_DressBox_SuperListItemActionLock"):Hide()
			--限时 不需要
			bar:GetSubItem("NewExterior_DressBox_SuperListItemActionTime"):Hide()
			--试穿标识
			bar:GetSubItem("NewExterior_DressBox_SuperListItemActionTry"):Hide()
			--当前装备中
			bar:GetSubItem("NewExterior_DressBox_SuperListItemActionEqu"):Hide()
			--当前特殊染色时装
			bar:GetSubItem("NewExterior_DressBox_SuperListItemActionLuxury"):Hide()
			
			table.insert(g_BarList, bar)
			table.insert(g_PlayerFashionInfoList, {})
		end
		g_InitList = 1
	end
		
	-- 填充时装数据
	local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
	for i=1, g_MaxBarNum do 
		local nVecIndex = i-1
		local nExteriorID = FashionDepot:LuaFnGetFashionId(m_PlayerfashionDepotType, nVecIndex)

		g_PlayerFashionInfoList[i].nVecIndex = nVecIndex
		
		if nCurFashionId ~= nil and nCurFashionId > 0 and nCurFashionId == nExteriorID and nCurFashionIdx == nVecIndex then
			g_PlayerFashionInfoList[i].bDressUp = 1
		else
			g_PlayerFashionInfoList[i].bDressUp = 0
		end
		
		if nExteriorID and nExteriorID > 0 then
			g_PlayerFashionInfoList[i].nExteriorID = nExteriorID
		else
			g_PlayerFashionInfoList[i].nExteriorID = -1
		end
	end
	
end

function NewExterior_DressBox_Show()
	
	g_Distance = g_Distance_Ori
	g_NeedChangeScrollSize = 1
	
	NewExterior_DressBox_InitList()	
	
	NewExterior_DressBox_CleanUp()
	
	Exterior:LuaFnInitCurrentExteriorSet()
	
	g_CurSelExteriorID = 0
	g_CurSelExteriorIndex = -1
	g_TargetExteriorID = 0
	g_TargetExteriorIndex = -1
			
	--列表 排序
	NewExterior_DressBox_UpdateList()
	--搭配方案
	NewExterior_DressBox_UpdateFangAn()
	--左侧
	NewExterior_DressBox_UpdateLeftBtn()
	--模型
	NewExterior_DressBox_UpdateObj()
	
	NewExterior_DressBox_UpdateRedPoint()
	
	NewExterior_DressBox_ShowFashionWeaponCheckButton()

	NewExterior_DressBox_GenderUpdate()
	--图鉴
	NewExterior_DressBox_PageButtonUpdate()
end

--左侧
function NewExterior_DressBox_UpdateLeftBtnForStyle()
	
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
		
		NewExterior_DressBox_Ride_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_Ride_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_DressBox_Ride_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_Ride_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_DressBox_Ride_LockImg:Show()
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
		
		NewExterior_DressBox_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_DressBox_Weapon_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_Weapon_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_DressBox_Weapon_LockImg:Show()
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
		NewExterior_DressBox_PetPossJian_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_PetPossJian_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_DressBox_PetPossJian_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_PetPossJian_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorFutiVisualIndex() ~= cacheVisualIndex then
				NewExterior_DressBox_PetPossJian_ActionImg:Show()
			end
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 
			or Exterior:LuaFnIsExteriorFutiVisualUnlocked(cacheExteriorID, cacheVisualIndex) ~= 1 
		then
			NewExterior_DressBox_PetPossJian_LockImg:Show()
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
		NewExterior_DressBox_FaceStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_FaceStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_82}", strName)
		NewExterior_DressBox_FaceStyle_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_FaceStyle_ActionImg:Show()
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_DressBox_FaceStyle_LockImg:Show()
		end
	end
	
	-- 发型
	edType = 4
	local cacheColorValue = -1
	local cacheColorIndex = -1
	cacheExteriorID, cacheColorValue = Exterior:LuaFnGetCurExteriorShareInfo("HAIR")
	if cacheExteriorID == nil or cacheExteriorID <= 0 then
		cacheExteriorID, cacheColorIndex = Exterior:LuaFnGetCurrentExteriorSetInfo("HAIR")
	end
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_DressBox_HairStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_HairStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_81}", strName)
		NewExterior_DressBox_HairStyle_LeftBtn:SetToolTip(strTemp)
		
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_HairStyle_ActionImg:Show()
		else
			if cacheColorValue >= 0 and Exterior:LuaFnIsHaveHairColorValue(cacheColorValue) ~= 1 then
				NewExterior_DressBox_HairStyle_ActionImg:Show()
			end
			
			if cacheColorIndex >= 0 and Exterior:LuaFnGetExteriorHairColorIndex() ~= cacheColorIndex then
				NewExterior_DressBox_HairStyle_ActionImg:Show()
			end
		end		
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_DressBox_HairStyle_LockImg:Show()
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
		NewExterior_DressBox_PlayerFrame_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_PlayerFrame_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_79}", strName)
		strHeadTip = strTemp
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_PlayerFrame_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_DressBox_PlayerFrame_LockImg:Show()
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
			NewExterior_DressBox_PlayerFrame_Mask:Hide()
			NewExterior_DressBox_PlayerFrame_Mask_Animate:Show()
			
			local strFrameAnimate = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameAnimate")
			NewExterior_DressBox_PlayerFrame_Mask_Animate:SetProperty("Animate", strFrameAnimate)
		else
			NewExterior_DressBox_PlayerFrame_Mask:Show()
			NewExterior_DressBox_PlayerFrame_Mask_Animate:Hide()
			
			local strIcon = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameIcon")
			local strImage = GetIconFullName(strIcon)
			NewExterior_DressBox_PlayerFrame_Mask:SetProperty("Image", strImage)
		end

		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_85}", strName)
		NewExterior_DressBox_PlayerFrame_LeftBtn:SetToolTip(strHeadTip.."#r"..strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_PlayerFrame_ActionImg:Show()
		end	
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_DressBox_PlayerFrame_LockImg:Show()
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
		
		NewExterior_DressBox_Widget_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_Widget_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_DressBox_Widget_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_DressBox_Widget_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= g_OrnamentState.TIME and nState ~= g_OrnamentState.FOREVER ) then
			NewExterior_DressBox_Widget_LockImg:Show()
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
		
		NewExterior_DressBox_Headdress_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_Headdress_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_DressBox_Headdress_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_DressBox_Headdress_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= g_OrnamentState.TIME and nState ~= g_OrnamentState.FOREVER ) then
			NewExterior_DressBox_Headdress_LockImg:Show()
		end
	end
end

--左侧
function NewExterior_DressBox_UpdateLeftBtn()
	
	for i = 1, table.getn(g_ActionButtonList) do
		g_ActionButtonList[i]:Hide()
	end
	
	for i = 1, table.getn(g_TransformButtonList) do
		g_TransformButtonList[i]:Hide()
	end
	
	NewExterior_DressBox_CleanUp_LeftButton()
			
	local g_CurSelShareStyleIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("STYLE")	
	if g_CurSelShareStyleIdx > 0 and g_CurSelShareStyleIdx <= g_DressBox_FangAn_Max then
		NewExterior_DressBox_UpdateLeftBtnForStyle()
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
			NewExterior_DressBox_Dress_LeftBtn:SetActionItem(-1)
			NewExterior_DressBox_Dress_LeftBtn:SetProperty("Empty", "False")
			NewExterior_DressBox_Dress_LeftBtn:SetProperty("NormalImage", strImage)
			NewExterior_DressBox_Dress_LeftBtn:SetProperty("HoverImage", strImage)
			NewExterior_DressBox_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "True")
			-- 文字tips
			local strToolTip = DressStyleScript:GetDressStyleToolTips(cacheExteriorID, cacheExteriorIdx)
			NewExterior_DressBox_Dress_LeftBtn:SetToolTip(strToolTip)
			-- 试穿
			NewExterior_DressBox_Dress_ActionImg:Show()
		end
	else
		--时装
		cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
		if cacheExteriorID ~= nil and cacheExteriorID > 0 then
			local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(m_PlayerfashionDepotType, cacheExteriorIdx)
			--local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, cacheExteriorID, 0)
			if theAction:GetID() ~= 0 then
				NewExterior_DressBox_Dress_LeftBtn:SetActionItem(theAction:GetID())
				NewExterior_DressBox_Dress_ActionImg:Show()
				
				local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
				if nCurFashionId ~= nil and nCurFashionId > 0 then
					if nCurFashionIdx == cacheExteriorIdx then
						NewExterior_DressBox_Dress_ActionImg:Hide()
				
						-- 只对装备时装进行判断
						local tipslist = {"","","","",""}
						local nTranformDressCount = 0
						nTranformDressCount, tipslist[1], tipslist[2], tipslist[3], tipslist[4], tipslist[5] = Exterior:LuaFnGetDressTransformTips(nCurFashionId)
						if nTranformDressCount > 0 and nTranformDressCount < table.getn(g_TransformButtonList) then
							for i = 1, nTranformDressCount do
								g_TransformButtonList[i]:Show()
								if tipslist[i] ~= "" then
									local strtips = ScriptGlobal_Format("#{QXWG_230427_03}", tipslist[i])
									g_TransformButtonList[i]:SetToolTip(strtips)
								end
							end
						end
					end
				end
				
				local actionVisualID = FashionActionUI:GetFashionEquipVisual(cacheExteriorID)
				local ActionNum = FashionActionUI:GetFashionActionActionNum(cacheExteriorID, actionVisualID)
				for i = 1, ActionNum do
					g_ActionButtonList[i]:Show()
				end
			end
		else
			local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
			if nCurFashionId ~= nil and nCurFashionId > 0 then
				local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(m_PlayerfashionDepotType, nCurFashionIdx)
				--local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, nCurFashionId, 0)
				if theAction:GetID() ~= 0 then
					NewExterior_DressBox_Dress_LeftBtn:SetActionItem(theAction:GetID())
				end
				
				local actionVisualID = FashionActionUI:GetFashionEquipVisual(nCurFashionId)
				local ActionNum = FashionActionUI:GetFashionActionActionNum(nCurFashionId, actionVisualID)
				for i = 1, ActionNum do
					g_ActionButtonList[i]:Show()
				end
				
				-- 只对装备时装进行判断
				local tipslist = {"","","","",""}
				local nTranformDressCount = 0
				nTranformDressCount, tipslist[1], tipslist[2], tipslist[3], tipslist[4], tipslist[5] = Exterior:LuaFnGetDressTransformTips(nCurFashionId)
				if nTranformDressCount > 0 and nTranformDressCount < table.getn(g_TransformButtonList) then
					for i = 1, nTranformDressCount do
						g_TransformButtonList[i]:Show()
						if tipslist[i] ~= "" then
							local strtips = ScriptGlobal_Format("#{QXWG_230427_03}", tipslist[i])
							g_TransformButtonList[i]:SetToolTip(strtips)
						end
					end
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
		
		NewExterior_DressBox_Ride_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_Ride_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_DressBox_Ride_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_Ride_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_DressBox_Ride_LockImg:Show()
		end
	end
	
	--幻武
	edType = 1
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Name")
		local strIcon 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_DressBox_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_DressBox_Weapon_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_Weapon_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_DressBox_Weapon_LockImg:Show()
		end
	end
	
	--附体
	edType = 2
	local cacheVisualIndex = 0
	cacheExteriorID, cacheVisualIndex, _ = Exterior:LuaFnGetCurrentExteriorSetInfo("FUTI")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "Name")
		local strImage 	= Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "VisualIcon", cacheVisualIndex)
		NewExterior_DressBox_PetPossJian_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_PetPossJian_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_DressBox_PetPossJian_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_PetPossJian_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorFutiVisualIndex() ~= cacheVisualIndex then
				NewExterior_DressBox_PetPossJian_ActionImg:Show()
			end
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 or Exterior:LuaFnIsExteriorFutiVisualUnlocked(cacheExteriorID, cacheVisualIndex) ~= 1 then
			NewExterior_DressBox_PetPossJian_LockImg:Show()
		end
	end
	
	--脸型
	edType = 3
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FACE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_DressBox_FaceStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_FaceStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_82}", strName)
		NewExterior_DressBox_FaceStyle_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_FaceStyle_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_DressBox_FaceStyle_LockImg:Show()
		end
	end
	
	--发型
	edType = 4
	cacheExteriorID, cacheColorIndex = Exterior:LuaFnGetCurrentExteriorSetInfo("HAIR")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Name", sex)
		local strIcon 	= Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Icon", sex)
		local strImage = GetIconFullName(strIcon)		
		NewExterior_DressBox_HairStyle_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_HairStyle_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_81}", strName)
		NewExterior_DressBox_HairStyle_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_HairStyle_ActionImg:Show()
		else
			if Exterior:LuaFnGetExteriorHairColorIndex() ~= cacheColorIndex then
				NewExterior_DressBox_HairStyle_ActionImg:Show()
			end
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_DressBox_HairStyle_LockImg:Show()
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
		NewExterior_DressBox_PlayerFrame_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_PlayerFrame_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_79}", strName)
		strHeadTip = strTemp
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_PlayerFrame_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_DressBox_PlayerFrame_LockImg:Show()
		end		
	end
	
	--头像框
	edType = 6
	cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FRAME")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Name")
		local iFrameType = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Type")
		if iFrameType == 1 then
			NewExterior_DressBox_PlayerFrame_Mask:Hide()
			NewExterior_DressBox_PlayerFrame_Mask_Animate:Show()
			
			local strFrameAnimate = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameAnimate")
			NewExterior_DressBox_PlayerFrame_Mask_Animate:SetProperty("Animate", strFrameAnimate)
		else
			NewExterior_DressBox_PlayerFrame_Mask:Show()
			NewExterior_DressBox_PlayerFrame_Mask_Animate:Hide()
			
			local strIcon 	= Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameIcon")
			local strImage = GetIconFullName(strIcon)
			NewExterior_DressBox_PlayerFrame_Mask:SetProperty("Image", strImage)
		end

		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_85}", strName)
		NewExterior_DressBox_PlayerFrame_LeftBtn:SetToolTip(strHeadTip.."#r"..strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_DressBox_PlayerFrame_ActionImg:Show()
		end	
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_DressBox_PlayerFrame_LockImg:Show()
		end	
	end
	
	local edOrnamentsType, cacheExteriorX, cacheExteriorY, cacheExteriorZ = 0, 0, 0, 0
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsBack")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_DressBox_Widget_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_Widget_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_DressBox_Widget_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_DressBox_Widget_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
			NewExterior_DressBox_Widget_LockImg:Show()
		end
	end

	edOrnamentsType= 1
	cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsHead")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
		local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_DressBox_Headdress_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_DressBox_Headdress_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
		NewExterior_DressBox_Headdress_LeftBtn:SetToolTip(strTemp)
		--试穿
		if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
			NewExterior_DressBox_Headdress_ActionImg:Show()
		end
		--未激活
		local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
		if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
			NewExterior_DressBox_Headdress_LockImg:Show()
		end
	end
end

--模型
function NewExterior_DressBox_UpdateObj()
	
	local cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		NewExterior_DressBox_FakeObject:DetachWindowEx()
		NewExterior_DressBox_FakeObject:AttachWindowEx("Exterior_Player")
		Exterior:LuaFnUpdateExteriorPlayerData()
		--Exterior:LuaFnUpdateExteriorAvatarFashion(cacheExteriorID, cacheExteriorIdx)	
	else	
		NewExterior_DressBox_FakeObject:DetachWindowEx()
		NewExterior_DressBox_FakeObject:AttachWindowEx("Exterior_Player")
		Exterior:LuaFnUpdateExteriorPlayerData()
	end

	NewExterior_DressBox_ActionEnd()
	
	NewExterior_DressBox_UpdateCamera()
	
end

--列表
function NewExterior_DressBox_UpdateList()
			
	-- 显示
	for i, v in pairs(g_PlayerFashionInfoList) do 
	
		local bar = g_BarList[i]
		bar:Show()
	
		local ctrlAction = bar:GetSubItem("NewExterior_DressBox_SuperListItemAction")
		local nVecIndex = v.nVecIndex
		local nExteriorID = FashionDepot:LuaFnGetFashionId(m_PlayerfashionDepotType, nVecIndex)
		-- ActionButton
		local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(m_PlayerfashionDepotType, nVecIndex)
		if theAction:GetID() ~= 0 then
			ctrlAction:SetActionItem(theAction:GetID())
		else
			ctrlAction:SetActionItem(-1)
		end
		
		bar:GetSubItem("NewExterior_DressBox_SuperListItemActionEqu"):Hide()
		local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
		if nCurFashionId ~= nil and nCurFashionId > 0 then
			if nCurFashionId == nExteriorID and v.bDressUp == 1 then
				bar:GetSubItem("NewExterior_DressBox_SuperListItemActionEqu"):Show()
			end
		end
		
		bar:GetSubItem("NewExterior_DressBox_SuperListItemActionTry"):Hide()
		local cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
		if cacheExteriorID ~= nil and cacheExteriorID > 0 then
			if cacheExteriorID == nExteriorID and cacheExteriorIdx == nVecIndex and v.bDressUp == 0 then
				bar:GetSubItem("NewExterior_DressBox_SuperListItemActionTry"):Show()
			end

			if cacheExteriorID == nExteriorID and cacheExteriorIdx == nVecIndex and v.bDressUp == 1 then
				g_TargetExteriorID = nCurFashionId
				g_TargetExteriorIndex = i
				g_CurSelExteriorID = nCurFashionId
				g_CurSelExteriorIndex = nVecIndex + 1
			end
		end
		
		bar:GetSubItem("NewExterior_DressBox_SuperListItemActionLuxury"):Hide()
		local nTranformDressCount = Exterior:LuaFnGetDressTransformInfo(nExteriorID)
		if nTranformDressCount > 0 then
			bar:GetSubItem("NewExterior_DressBox_SuperListItemActionLuxury"):Show()
		end
		
		local nFashionNumber = Exterior:LuaFnGetNumberingFashionInfo(nExteriorID, "Number")
		if nFashionNumber ~= nil and nFashionNumber > 0 then
			bar:GetSubItem("NewExterior_DressBox_SuperListItemActionLuxury"):Show()
		end
		
		if g_TargetExteriorID == 0 then			
			if g_CurSelExteriorID == nExteriorID and g_CurSelExteriorIndex == (nVecIndex+1) then
				ctrlAction:SetPushed(1)
			else
				ctrlAction:SetPushed(0)
			end
		else
			if g_TargetExteriorID == nExteriorID and g_TargetExteriorIndex == i then
				ctrlAction:SetPushed(1)				
				g_CurSelExteriorID = g_TargetExteriorID	
				g_CurSelExteriorIndex = nVecIndex + 1
			else
				ctrlAction:SetPushed(0)
			end
		end
	end
	
	if g_NeedChangeScrollSize == 1 then
		NewExterior_DressBox_SuperList:RefreshLayout()
		g_NeedChangeScrollSize = 0
	end

end

function NewExterior_DressBox_ItemBtnClicked(nIndex)
	
	local tabInfo = g_PlayerFashionInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		return
	end
	
	Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	-- 右键从衣柜到背包
	Exterior:LuaFnExteriorFashionTakeOut(tabInfo.nVecIndex, -1)
	
	Exterior:LuaFnSetCurrentExteriorSetInfo("DRESSSTYLE", 0, 0)
	for i=1, 3 do
		Exterior:LuaFnSetCurrentExteriorSetInfo("RESETDRESSSTYLE", i-1, 0, 0)
	end
	--if g_BarList[nIndex] ~= nil then		
	--	local ctrlAction = g_BarList[nIndex]:GetSubItem("NewExterior_DressBox_SuperListItemAction")
	--	if ctrlAction ~= nil then
	--		PushDebugMessage("NewExterior_DressBox_ItemBtnClicked nIndex="..nIndex)
	--		ctrlAction:DoAction()
	--	end
	--end
end

--时装动作
function NewExterior_DressBox_onAction(nIndex)
	if not nIndex then 
		return
	end
	
	local tabInfo = g_PlayerFashionInfoList[g_CurSelExteriorIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		return
	end
	
	local nHaveReSet = 0
	for i = 1, table.getn(g_SpecialFashionCamera) do
		if tabInfo.nExteriorID >= g_SpecialFashionCamera[i].startid and tabInfo.nExteriorID <= g_SpecialFashionCamera[i].endid then
			local fHeight, fDistance, fPitch = NewExterior_DressBox_FakeObject:GetCameraEx()
			if g_SpecialFashionCamera[i].fDistance ~= -1 then
				fDistance = g_SpecialFashionCamera[i].fDistance
			end
			if g_SpecialFashionCamera[i].fHeight ~= -1 then
				fHeight = g_SpecialFashionCamera[i].fHeight
			end
			if g_SpecialFashionCamera[i].fPitch ~= -1 then
				fPitch = g_SpecialFashionCamera[i].fPitch
			end
			NewExterior_DressBox_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)
			NewExterior_DressBox_Model_Plus:Disable()
			NewExterior_DressBox_Model_Subtract:Disable()
			NewExterior_DressBox_Model_TurnLeft:Disable()
			NewExterior_DressBox_Model_TurnRight:Disable()
			NewExterior_DressBox_GenderChange_Btn:Disable()
			
			SetTimer("NewExterior_DressBox","NewExterior_DressBox_ActionEnd()", g_SpecialFashionCamera[i].timecount)
			
			nHaveReSet = 1
		end		
	end
				
	if nHaveReSet == 0 then
		local nFashionNumber = Exterior:LuaFnGetNumberingFashionInfo(tabInfo.nExteriorID, "Number")
		if nFashionNumber ~= nil and nFashionNumber > 0 then
			local fHeight, fDistance, fPitch = NewExterior_DressBox_FakeObject:GetCameraEx()
			
			fHeight = g_NumberingFashionCamera.fHeight
			fDistance = g_NumberingFashionCamera.fDistance
			
			NewExterior_DressBox_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)			
			NewExterior_DressBox_Model_Plus:Disable()
			NewExterior_DressBox_Model_Subtract:Disable()
			NewExterior_DressBox_Model_TurnLeft:Disable()
			NewExterior_DressBox_Model_TurnRight:Disable()
			NewExterior_DressBox_GenderChange_Btn:Disable()
			
			local timecount = g_NumberingFashionCamera.timecount1
			if nIndex == 2 then
				timecount = g_NumberingFashionCamera.timecount2
			end
			
			SetTimer("NewExterior_DressBox","NewExterior_DressBox_ActionEnd()", timecount)
		end
	end
	
	Exterior:LuaFnExteriorAvatarPlayAction(1, g_CurSelExteriorIndex-1, nIndex-1)
end

function NewExterior_DressBox_ActionEnd()
	KillTimer("NewExterior_DressBox_ActionEnd()");
	
	NewExterior_DressBox_Model_Plus:Enable()
	NewExterior_DressBox_Model_Subtract:Enable()
	NewExterior_DressBox_Model_TurnLeft:Enable()
	NewExterior_DressBox_Model_TurnRight:Enable()
	NewExterior_DressBox_GenderChange_Btn:Enable()

	NewExterior_DressBox_UpdateCamera()
end

function NewExterior_DressBox_MakeHyperlink(nVecIndex)
	local ret = Exterior:LuaFnExteriorFashionDepotItemClick(m_PlayerfashionDepotType, nVecIndex)
	return ret
end

function NewExterior_DressBox_ItemClicked(nIndex)

	local tabInfo = g_PlayerFashionInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		return
	end
	
	if NewExterior_DressBox_MakeHyperlink(tabInfo.nVecIndex) == 1 then
		return
	end
	
	for i = 1, table.getn(g_ActionButtonList) do
		g_ActionButtonList[i]:Hide()
	end
	
	for i = 1, table.getn(g_TransformButtonList) do
		g_TransformButtonList[i]:Hide()
	end
	
	local nVecIndex = tabInfo.nVecIndex+1
	--local nExteriorID = FashionDepot:LuaFnGetFashionId(m_PlayerfashionDepotType, nIndex-1)
	if g_CurSelExteriorID ~= tabInfo.nExteriorID or g_CurSelExteriorIndex ~= nVecIndex then	
		g_CurSelExteriorID = tabInfo.nExteriorID
		g_CurSelExteriorIndex = nVecIndex
		
		g_actionVisualID = FashionActionUI:GetFashionEquipVisual(g_CurSelExteriorID)
		local ActionNum = FashionActionUI:GetFashionActionActionNum(g_CurSelExteriorID, g_actionVisualID)
		for i = 1, ActionNum do
			g_ActionButtonList[i]:Show()
		end
		
		local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
		if nCurFashionId ~= nil and nCurFashionId > 0 and nCurFashionId == g_CurSelExteriorID then
			local tipslist = {"","","","",""}
			local nTranformDressCount = 0
			nTranformDressCount, tipslist[1], tipslist[2], tipslist[3], tipslist[4], tipslist[5] = Exterior:LuaFnGetDressTransformTips(nCurFashionId)
			if nTranformDressCount > 0 and nTranformDressCount < table.getn(g_TransformButtonList) then
				for i = 1, nTranformDressCount do
					g_TransformButtonList[i]:Show()
					if tipslist[i] ~= "" then
						local strtips = ScriptGlobal_Format("#{QXWG_230427_03}", tipslist[i])
						g_TransformButtonList[i]:SetToolTip(strtips)
					end
				end
			end
		end
		
		Exterior:LuaFnSetCurrentExteriorSetInfo("FASHION", g_CurSelExteriorID, nVecIndex-1)
		Exterior:LuaFnSetCurrentExteriorSetInfo("DRESSSTYLE", 0, 0)
		Exterior:LuaFnSetCurExteriorShareInfo("FASHION", g_CurSelExteriorID, nVecIndex-1)
		NewExterior_DressBox_SetItemSelected(nIndex)
			
		NewExterior_DressBox_UpdateObj()	
		NewExterior_DressBox_UpdateLeftBtn()
	else
		g_CurSelExteriorID = 0
		g_CurSelExteriorIndex = -1
		local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
		if nCurFashionId ~= nil and nCurFashionId > 0 then
			g_CurSelExteriorID = nCurFashionId
			g_CurSelExteriorIndex = nCurFashionIdx	

			-- 只对装备时装进行判断
			local tipslist = {"","","","",""}
			local nTranformDressCount = 0
			nTranformDressCount, tipslist[1], tipslist[2], tipslist[3], tipslist[4], tipslist[5] = Exterior:LuaFnGetDressTransformTips(nCurFashionId)
			if nTranformDressCount > 0 and nTranformDressCount < table.getn(g_TransformButtonList) then
				for i = 1, nTranformDressCount do
					g_TransformButtonList[i]:Show()
					if tipslist[i] ~= "" then
						local strtips = ScriptGlobal_Format("#{QXWG_230427_03}", tipslist[i])
						g_TransformButtonList[i]:SetToolTip(strtips)
					end
				end	
			end
		end
		Exterior:LuaFnSetCurrentExteriorSetInfo("FASHION", g_CurSelExteriorID, g_CurSelExteriorIndex)
		Exterior:LuaFnSetCurrentExteriorSetInfo("DRESSSTYLE", 0, 0)
		Exterior:LuaFnSetCurExteriorShareInfo("FASHION", g_CurSelExteriorID, g_CurSelExteriorIndex)
		NewExterior_DressBox_Show()
	end	
end

function NewExterior_DressBox_SetItemSelected(nIndex)

	local tabInfo = g_PlayerFashionInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		return
	end
	
	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			g_BarList[i]:GetSubItem("NewExterior_DressBox_SuperListItemActionTry"):Hide()
			
			local ctrlAction = g_BarList[i]:GetSubItem("NewExterior_DressBox_SuperListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
					if tabInfo.bDressUp == 0 then
						g_BarList[i]:GetSubItem("NewExterior_DressBox_SuperListItemActionTry"):Show()
					end
	
					local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
					if nCurFashionId ~= nil and nCurFashionId > 0 then
						if nCurFashionIdx == tabInfo.nVecIndex then
						g_BarList[i]:GetSubItem("NewExterior_DressBox_SuperListItemActionTry"):Hide()
						end
					end
					
				else
					ctrlAction:SetPushed(0)	
				end
			end
		end
	end
end

function NewExterior_DressBox_CloseClick()	
	Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
		
	NewExterior_DressBox_SavePosition()
	this:Hide()
end

function NewExterior_DressBox_OnHidden()
	
	if IsWindowShow("NewExterior_Ride") 
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
	
	NewExterior_DressBox_CleanUp()
	
	if IsWindowShow("NewExterior_PlanSetting") then
		CloseWindow("NewExterior_PlanSetting", true)
	end
	
	NewExterior_Ride_CloseTuJing()
end
	
function NewExterior_DressBox_CleanUp_LeftButton()

	NewExterior_DressBox_Dress_LeftBtn:SetActionItem(-1)
	NewExterior_DressBox_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "False")
	NewExterior_DressBox_Dress_LeftBtn:SetProperty("NormalImage", "")
	NewExterior_DressBox_Dress_LeftBtn:SetProperty("HoverImage", "")
	NewExterior_DressBox_Dress_LeftBtn:SetProperty("Empty", "True")
	
	local ctrl_list = {
		[1] = NewExterior_DressBox_Weapon_LeftBtn,
		[2] = NewExterior_DressBox_PetPossJian_LeftBtn,
		[3] = NewExterior_DressBox_FaceStyle_LeftBtn,
		[4] = NewExterior_DressBox_HairStyle_LeftBtn,
		[5] = NewExterior_DressBox_PlayerFrame_LeftBtn,
		[6] = NewExterior_DressBox_Ride_LeftBtn,
		[7] = NewExterior_DressBox_Widget_LeftBtn,
		[8] = NewExterior_DressBox_Headdress_LeftBtn,
	}
	
	for i = 1 ,8 do
		ctrl_list[i]:SetProperty("Empty", "False")
		ctrl_list[i]:SetProperty("UseDefaultTooltip", "True")
		ctrl_list[i]:SetProperty("NormalImage", "")
		ctrl_list[i]:SetProperty("HoverImage", "")
		ctrl_list[i]:SetToolTip("")
	end
	
	NewExterior_DressBox_PlayerFrame_Mask:SetProperty("Image", "")
	NewExterior_DressBox_PlayerFrame_Mask_Animate:SetProperty("Animate", "")

	NewExterior_DressBox_Dress_ActionImg:Hide()
	NewExterior_DressBox_Weapon_ActionImg:Hide()
	NewExterior_DressBox_PetPossJian_ActionImg:Hide()
	NewExterior_DressBox_FaceStyle_ActionImg:Hide()
	NewExterior_DressBox_HairStyle_ActionImg:Hide()
	NewExterior_DressBox_PlayerFrame_ActionImg:Hide()
	NewExterior_DressBox_Ride_ActionImg:Hide()	
	NewExterior_DressBox_Widget_ActionImg:Hide()
	NewExterior_DressBox_Headdress_ActionImg:Hide()

	NewExterior_DressBox_Dress_LockImg:Hide()
	NewExterior_DressBox_Weapon_LockImg:Hide()
	NewExterior_DressBox_PetPossJian_LockImg:Hide()
	NewExterior_DressBox_FaceStyle_LockImg:Hide()
	NewExterior_DressBox_HairStyle_LockImg:Hide()
	NewExterior_DressBox_PlayerFrame_LockImg:Hide()
	NewExterior_DressBox_Ride_LockImg:Hide()
	NewExterior_DressBox_Widget_LockImg:Hide()
	NewExterior_DressBox_Headdress_LockImg:Hide()
end

function NewExterior_DressBox_CleanUp()
	for i = 1, g_MaxBarNum do
		if g_BarList[i] then
			local ctrlAction = g_BarList[i]:GetSubItem("NewExterior_DressBox_SuperListItemAction")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end
	end
	NewExterior_DressBox_FakeObject:DetachWindowEx()
	
	NewExterior_DressBox_FangAn_Choice:ResetList()
	
	NewExterior_DressBox_CleanUp_LeftButton()
end

--左转
function NewExterior_DressBox_FakeObject_TurnLeft(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		NewExterior_DressBox_FakeObject:RotateBeginEx("Exterior_Player", -0.3)
	else
		NewExterior_DressBox_FakeObject:RotateEndEx()
	end
	
end

--右转
function NewExterior_DressBox_FakeObject_TurnRight(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		NewExterior_DressBox_FakeObject:RotateBeginEx("Exterior_Player", 0.3)
	else
		NewExterior_DressBox_FakeObject:RotateEndEx()
	end
	
end

--缩小
function NewExterior_DressBox_ZoomOut()

	if g_Distance == 1 then
		return
	end
	
	g_Distance = g_Distance - 1	

	NewExterior_DressBox_UpdateCamera()
	
end

--放大
function NewExterior_DressBox_ZoomIn()

	if g_Distance == g_Distance_Max then
		return
	end
	
	g_Distance = g_Distance + 1	
	
	NewExterior_DressBox_UpdateCamera()
	
end

function NewExterior_DressBox_UpdateCamera()

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
	
	local fHeight, fDistance, fPitch = NewExterior_DressBox_FakeObject:GetCameraEx()
	fHeight = cameraInfo[sex][g_Distance].fHeight
	fDistance = cameraInfo[sex][g_Distance].fDistance
	fPitch = cameraInfo[sex][g_Distance].fPitch
	fXOffset = cameraInfo[sex][g_Distance].fXOffset
	NewExterior_DressBox_FakeObject:SetCameraEx(fHeight, fDistance, fPitch, fXOffset)
	
end

--时装仓库到背包
function NewExterior_DressBox_FashionDepotToBag(nSourcePos, targetPos)
	if targetPos ~= -1 then
		local theAction, bLocked, bProtect, nElapsedTime = PlayerPackage:EnumItem("base", targetPos);
		if theAction:GetID() ~= 0  then 
			local opResult = FashionDepot:LuaFnJudgeBagItem(m_PlayerfashionDepotType, targetPos)
			if opResult == 2 then --不是时装
				PushDebugMessage("#{HCG_190117_18}")
				return
			end
			
			if opResult == 5 then --解除锁定倒计时中 -使用了二级密码进行了解锁 需要二次确认 enCGFashionDepotOperationType_TakeOut=2
				PushEvent("EXTERIOR_FASHION_CONFIRM", 1000, m_PlayerfashionDepotType, 2, nSourcePos, targetPos) --二次确认
				return
			end
			
			--镶嵌有 密语金丝 --计时时装 
			if opResult == 3 or opResult == 4 or opResult == 1 then 
				Exterior:LuaFnExteriorFashionTakeOut(nSourcePos, targetPos)
				return
			end
		end
	end	
	Exterior:LuaFnExteriorFashionTakeOut(nSourcePos, targetPos)
end

--背包到时装仓库
function NewExterior_DressBox_BagToFashionDepot(opType, nSourcePos, targetPos)

	local theAction, bLocked, bProtect, nElapsedTime = PlayerPackage:EnumItem("base", nSourcePos);
	if theAction:GetID() ~= 0  then 
		local opResult = FashionDepot:LuaFnJudgeBagItem(m_PlayerfashionDepotType, nSourcePos)
		if opResult == 2 then --不是时装
			PushDebugMessage("#{HCG_190117_18}")
			return
		end
		
		if opResult == 5 then --解除锁定倒计时中 -使用了二级密码进行了解锁 需要二次确认
			PushEvent("EXTERIOR_FASHION_CONFIRM", 1000, m_PlayerfashionDepotType, opType, nSourcePos, targetPos) --二次确认
			return
		end
		
		--镶嵌有 密语金丝 --计时时装 
		if opResult == 3 or opResult == 4 or opResult == 1 then 
			Exterior:LuaFnExteriorFashionOperation(m_PlayerfashionDepotType, opType, nSourcePos, targetPos)
		end
	end
	
end

--卸下时装 
function NewExterior_DressBox_ActionToDressBox()
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
        NewExterior_DressBox_Show()
    end
	Exterior:LuaFnUnUseExteriorFashion(m_PlayerfashionDepotType)
end

--保存
function NewExterior_DressBox_DressChange_Save()
	
	local selfSex = GetMySelfRaceId()
	local selectSex = Exterior:LuaFnGetExteriorRaceID()
	if selfSex ~= selectSex then
		PushDebugMessage("#{SZTJ_231030_01}")
		return
	end

	if Exterior:LuaFnIsHaveExteriorChange() == 0 then
		if Exterior:LuaFnIsHaveDressStyleChange() == 1 then
			Exterior:LuaFnSetCurrentExteriorSetInfo("RESETDRESSSTYLE")
			Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", selfSex)
			Exterior:LuaFnInitCurrentExteriorSet()
			NewExterior_DressBox_Show()
		else
			PushDebugMessage("#{WGJM_210104_02}")
		end
		return
	end
		
	Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
	Exterior:LuaFnSaveExteriorAllChange(1)
end

--还原
function NewExterior_DressBox_Undo()

	if Exterior:LuaFnIsHaveDressStyleChange() == 0 and Exterior:LuaFnIsHaveExteriorChange() == 0 then
		PushDebugMessage("#{WGJM_210104_01}")
		return
	end	
	
	Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
	Exterior:LuaFnInitCurrentExteriorSet()
	NewExterior_DressBox_Show()
	
end

--整理
function NewExterior_DressBox_ClickClearUpBtn()

	g_CurSelExteriorID = 0
	g_CurSelExteriorIndex = -1
	
	local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
	if nCurFashionId ~= nil and nCurFashionId > 0 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("FASHION", nCurFashionId, nCurFashionIdx)
	else
		Exterior:LuaFnSetCurrentExteriorSetInfo("FASHION", g_CurSelExteriorID, g_CurSelExteriorIndex)
	end
	Exterior:LuaFnSetCurrentExteriorSetInfo("DRESSSTYLE", 0, 0)
	for i=1, 3 do
		Exterior:LuaFnSetCurrentExteriorSetInfo("RESETDRESSSTYLE", i-1, 0, 0)
	end
	Exterior:LuaFnInitCurrentExteriorSet()		
		
	FashionDepot:LuaFnRefreshFashionDepot(1)
end

--打开展示柜
function NewExterior_DressBox_OpenYiRongGe()
	NewExterior_DressBox_SavePosition()
	Exterior:LuaFnAskExteriorYiRongGeInfo(1, 2)
end

--切换子女时装
function NewExterior_DressBox_OpenInfant()	
	NewExterior_DressBox_SavePosition()
	Exterior:LuaFnInitExteriorFashionList(2, 1)
end

--时装
function NewExterior_DressBox_OpenFashion()
	local cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
	Exterior:LuaFnExteriorFashionDepotItemClick(m_PlayerfashionDepotType, cacheExteriorIdx)
	--NewExterior_DressBox_SavePosition()
	--PushEvent("OPEN_EXTERIOR_FASHION", 1, 0)
	NewExterior_DressBox_PageButtonUpdate()
end

--幻武
function NewExterior_DressBox_OpenWeapon()
	NewExterior_DressBox_SavePosition()
	Exterior:LuaFnAskOpenExterior(1)
end

--附体
function NewExterior_DressBox_OpenFuti()
	NewExterior_DressBox_SavePosition()
	Exterior:LuaFnAskOpenExterior(2)
end

--坐骑
function NewExterior_DressBox_OpenRide()
	NewExterior_DressBox_SavePosition()
	Exterior:LuaFnAskOpenExterior(0)
end

--发型
function NewExterior_DressBox_OpenHair()
	NewExterior_DressBox_SavePosition()	
	Exterior:LuaFnAskOpenExterior(4)
end

--脸型
function NewExterior_DressBox_OpenFace()
	NewExterior_DressBox_SavePosition()	
	Exterior:LuaFnAskOpenExterior(3)
end

--头像
function NewExterior_DressBox_OpenPortrait()
	NewExterior_DressBox_SavePosition()	
	Exterior:LuaFnAskOpenExterior(5)
end

--头像框
function NewExterior_DressBox_OpenFrame()
	NewExterior_DressBox_SavePosition()	
	Exterior:LuaFnAskOpenExterior(6)
end

function NewExterior_DressBox_OpenOrnamentsBack()
	NewExterior_DressBox_SavePosition()	
	OrnamentsScript:AskOrnamentsInfo(0)
end

function NewExterior_DressBox_OpenOrnamentsHead()
	NewExterior_DressBox_SavePosition()	
	OrnamentsScript:AskOrnamentsInfo(1)
end

function NewExterior_DressBox_TakeOffRide()
	local defExteriorID = Exterior:LuaFnGetExteriorInUse(0)
	if defExteriorID == 0 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("RIDE", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("RIDE", 0)
		NewExterior_DressBox_UpdateLeftBtn()
	else
		Exterior:LuaFnSetExteriorInUse(0, 0, 0)
	end
end

function NewExterior_DressBox_TakeOffWeapon()
	local defExteriorID = Exterior:LuaFnGetExteriorInUse(1)
	if defExteriorID == 0 then
		Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("WEAPON", 0, 0)
		NewExterior_DressBox_UpdateLeftBtn()
		Exterior:LuaFnRestoreExteriorPlayerFittingData(1)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
		Exterior:LuaFnSetCurExteriorShareInfo("WEAPON", 0, 0)
		Exterior:LuaFnSetExteriorInUse(1, 0, 0)
	end
end

function NewExterior_DressBox_UpdateRedPoint()

	NewExterior_DressBox_Dress_Tip:Hide()
	
	if Exterior:LuaFnIsHaveExteriorShowTip(0) == 1 then
		NewExterior_DressBox_Ride_Tip:Show()
	else
		NewExterior_DressBox_Ride_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(1) == 1 then
		NewExterior_DressBox_Weapon_Tip:Show()
	else
		NewExterior_DressBox_Weapon_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(2) == 1 then
		NewExterior_DressBox_PetPossJian_Tip:Show()
	else
		NewExterior_DressBox_PetPossJian_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(3) == 1 then
		NewExterior_DressBox_FaceStyle_Tip:Show()
	else
		NewExterior_DressBox_FaceStyle_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(4) == 1 or Exterior:LuaFnIsHaveHairColorShowTip() == 1 then
		NewExterior_DressBox_HairStyle_Tip:Show()
	else
		NewExterior_DressBox_HairStyle_Tip:Hide()
	end
	
	if Exterior:LuaFnIsHaveExteriorShowTip(5) == 1 or Exterior:LuaFnIsHaveExteriorShowTip(6) == 1 then
		NewExterior_DressBox_PlayerFrame_Tip:Show()
	else
		NewExterior_DressBox_PlayerFrame_Tip:Hide()
	end

	if Pneuma:GetMF(2959)== 1 or Exterior:LuaFnIsHaveExteriorShowTip(7) == 1 or Exterior:LuaFnIsHaveInfantHairColorShowTip() == 1 then 
		NewExterior_DressBox_SwitchBtn_Tip:Show()
	else
		NewExterior_DressBox_SwitchBtn_Tip:Hide()
	end

	if OrnamentsScript:IsHaveOrnamentsShowTip(0) == 1 then
		NewExterior_DressBox_Widget_Tip:Show()
	else
		NewExterior_DressBox_Widget_Tip:Hide()
	end

	if OrnamentsScript:IsHaveOrnamentsShowTip(1) == 1 then
		NewExterior_DressBox_Headdress_Tip:Show()
	else
		NewExterior_DressBox_Headdress_Tip:Hide()
	end
end

function NewExterior_DressBox_CloseSameGroupWindow()
	CloseWindow("SelfEquip", true)
	--CloseWindow("NewExterior_DressBox", true)
	CloseWindow("NewExterior_Ride", true)
	CloseWindow("NewExterior_Weapon", true)
	CloseWindow("NewExterior_PetPossJian", true)
	CloseWindow("NewExterior_Facestyle", true)
	CloseWindow("NewExterior_HairStyle", true)
	CloseWindow("NewExterior_PlayerFrame", true)
	CloseWindow("NewExterior_Widget", true)
	CloseWindow("NewExterior_Headdress", true)
	CloseWindow("NewExterior_DressStyle", true)
	CloseWindow("NewExterior_GemEffect", true)
	CloseWindow("NewExterior_PlanSetting", true)
	CloseWindow("NewExterior_TuJing", true)
end

function NewExterior_DressBox_SavePosition()
	Variable:SetVariable("ExteriorUnionPos", NewExterior_DressBox_Frame:GetProperty("UnifiedPosition"), 1)
end

function NewExterior_DressBox_SetPosition()
	
	local nExteriorUnionPos = Variable:GetVariable("ExteriorUnionPos")
	if nExteriorUnionPos ~= nil then
		NewExterior_DressBox_Frame:SetProperty("UnifiedPosition", nExteriorUnionPos)
	end

end

function NewExterior_DressBox_ShowFashionWeaponCheckButton()
	local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
	NewExterior_DressBox_Dress_Type:SetCheck(IsDisplay)
	
	IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
	NewExterior_DressBox_Weapon_Type:SetCheck(IsDisplay)

	IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
	NewExterior_DressBox_Widget_Type:SetCheck(IsDisplay)
	
	IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
	NewExterior_DressBox_Headdress_Type:SetCheck(IsDisplay)

	IsDisplay = SystemSetup:Lua_GetFuTiDisplayState()
	NewExterior_DressBox_PetPossJian_Type:SetCheck(IsDisplay)
end

function NewExterior_DressBox_FashionDisplay()
	--判断是否在争霸赛场景
	local IsZbsScene = IsZbsSpeicalScene()
	if IsZbsScene == 1 then
		PushDebugMessage("#{YCXX_230517_05}")
		local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
		if IsDisplay == 1 then
			NewExterior_DressBox_Dress_Type:SetCheck(1)
		else
			NewExterior_DressBox_Dress_Type:SetCheck(0)
		end
		return
	end
	local IsANScene = ANS:IsHideNameScene()
	if IsANScene == 1 then
		PushDebugMessage("#{XXYC_240408_3}")
		local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
		if IsDisplay == 1 then
			NewExterior_DressBox_Dress_Type:SetCheck(1)
		else
			NewExterior_DressBox_Dress_Type:SetCheck(0)
		end
		return
	end

	local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
	if IsDisplay == 1 then
		NewExterior_DressBox_Dress_Type:SetCheck(0)
		SystemSetup:LuaFnCloseFashionDisplay(1)
	else
		NewExterior_DressBox_Dress_Type:SetCheck(1)
		SystemSetup:LuaFnCloseFashionDisplay(0)
	end	
end

function NewExterior_DressBox_ExteriorWeaponDisplay()
	local IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
	if IsDisplay == 1 then
		NewExterior_DressBox_Weapon_Type:SetCheck(0)
		SystemSetup:LuaFnCloseExteriorWeaponDisplay(1)
	else
		NewExterior_DressBox_Weapon_Type:SetCheck(1)
		SystemSetup:LuaFnCloseExteriorWeaponDisplay(0)
	end	
end

function NewExterior_DressBox_OrnamentsBackDisplay()
	local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
	if IsDisplay == 1 then
		NewExterior_DressBox_Widget_Type:SetCheck(0)
		SystemSetup:SetOrnamentsDisplayState(0, 1)
		OrnamentsScript:ResetOrnamentsUseInfo(0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		NewExterior_DressBox_Widget_Type:SetCheck(1)
		SystemSetup:SetOrnamentsDisplayState(0, 0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	end	
end

function NewExterior_DressBox_OrnamentsHeadDisplay()
	local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
	if IsDisplay == 1 then
		NewExterior_DressBox_Headdress_Type:SetCheck(0)
		SystemSetup:SetOrnamentsDisplayState(1, 1)
		OrnamentsScript:ResetOrnamentsUseInfo(1)
		Exterior:LuaFnUpdateExteriorPlayerData()
	else
		NewExterior_DressBox_Headdress_Type:SetCheck(1)
		SystemSetup:SetOrnamentsDisplayState(1, 0)
		Exterior:LuaFnUpdateExteriorPlayerData()
	end	
end

function NewExterior_DressBox_ActionToOrnamentsBack()
	local useID = OrnamentsScript:GetOrnamentsUseID(0)
	if useID > 0 then
		OrnamentsScript:TakeOffOrnaments(0)
	end
	Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSBACK", 0, 0, 0, 0)
	Exterior:LuaFnSetCurExteriorShareInfo("ORNAMENTSBACK", 0, 0, 0, 0)
	NewExterior_DressBox_UpdateLeftBtn()
	Exterior:LuaFnRestoreExteriorPlayerFittingData(6)
	Exterior:LuaFnUpdateExteriorPlayerData()
end

function NewExterior_DressBox_ActionToOrnamentsHead()
	local useID = OrnamentsScript:GetOrnamentsUseID(1)
	if useID > 0 then
		OrnamentsScript:TakeOffOrnaments(1)
	end
	Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSHEAD", 0, 0, 0, 0)
	Exterior:LuaFnSetCurExteriorShareInfo("ORNAMENTSHEAD", 0, 0, 0, 0)
	NewExterior_DressBox_UpdateLeftBtn()
	Exterior:LuaFnRestoreExteriorPlayerFittingData(7)
	Exterior:LuaFnUpdateExteriorPlayerData()
end

--时装切换
function NewExterior_DressBox_OnTransform(nIndex)
	if not nIndex then 
		return
	end
	
	-- 只对装备时装进行判断
	local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
	if nCurFashionId ~= nil and nCurFashionId > 0 then
		local tipslist = {"","","","",""}
		local nTranformDressCount = 0
		nTranformDressCount, tipslist[1], tipslist[2], tipslist[3], tipslist[4], tipslist[5] = Exterior:LuaFnGetDressTransformTips(nCurFashionId)
		if nTranformDressCount <= 0 then
			return
		end
		
		if nIndex < 1 or nIndex > nTranformDressCount then
			return
		end
		
		if tipslist[nIndex] == nil then
			return
		end
		
		local Idlist = {0}
		nTranformDressCount, Idlist[1], Idlist[2], Idlist[3], Idlist[4], Idlist[5]  = Exterior:LuaFnGetDressTransformInfo(nCurFashionId)
		if Idlist[nIndex] == nil then
			return
		end
		
		if nCurFashionId == Idlist[nIndex] then
			PushDebugMessage("#{QXWG_230427_04}")
			return
		end
	
		-- 二次确认 去掉
		--PushEvent("TRANSFORM_FASHION_CONFIRM", nIndex, tipslist[nIndex])
		Exterior:LuaFnDoDressTransform(nIndex)		
	end
	
end

-- 来源
function NewExterior_Ride_CloseTuJing()
	if IsWindowShow("NewExterior_TuJing") then
		CloseWindow("NewExterior_TuJing", true)
	end
end

--方案
function NewExterior_DressBox_UpdateFangAn()

	if 1 == 1 then
		NewExterior_DressBox_FangAn_Choice:Hide()
		NewExterior_DressBox_FangAn_Setting:Hide()
		NewExterior_DressBox_FangAn_Save:Hide()
		NewExterior_DressBox_FangAn_Share:Hide()
		return
	end
	
	NewExterior_DressBox_FangAn_Choice:ResetList()

	NewExterior_DressBox_FangAn_Choice:AddTextItem("#{SZDP_230509_55}" ,0)	--当前形象
	--local nCount = Exterior:LuaFnGetExteriorShareInfoCount()
	for i = 1, g_DressBox_FangAn_Max do
		local namestr = Exterior:LuaFnGetExteriorShareInfo(i-1, "NAME")
		NewExterior_DressBox_FangAn_Choice:AddTextItem(namestr, i)
	end		
	
	local g_CurSelShareStyleIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("STYLE")
	if g_CurSelShareStyleIdx > 0 and g_CurSelShareStyleIdx <= g_DressBox_FangAn_Max then
		NewExterior_DressBox_FangAn_Choice:SetCurrentSelect(g_CurSelShareStyleIdx)
		NewExterior_DressBox_FangAn_Setting:Enable()			-- 设置按钮置灰 （ 只支持1-10 ）
	else
		NewExterior_DressBox_FangAn_Choice:SetCurrentSelect(0)	-- 分享按钮 可以分享当前形象
		NewExterior_DressBox_FangAn_Setting:Disable()			-- 设置按钮置灰 （ 只支持1-10 ）
	end
		
	Exterior:LuaFnTryExteriorShareInfo(g_CurSelShareStyleIdx-1)
	
end

function NewExterior_DressBox_FangAn_Changed()

	local str, nIndex = NewExterior_DressBox_FangAn_Choice:GetCurrentSelect()
	
	if nIndex == 0 then	
		Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
		Exterior:LuaFnInitCurrentExteriorSet()
		NewExterior_DressBox_Show()
		return
	end
	
	if nIndex > 0 and nIndex <= g_DressBox_FangAn_Max then
		Exterior:LuaFnSetCurrentExteriorSetInfo("STYLE", nIndex)
		
		NewExterior_DressBox_FangAn_Setting:Enable()
		
		--选择方案：-- 设置 （1-10）-- 试穿方案内容，obj刷新		
		Exterior:LuaFnTryExteriorShareInfo(nIndex-1)		
		--列表 排序 
		NewExterior_DressBox_UpdateList()
		--左侧
		NewExterior_DressBox_UpdateLeftBtn()
		--模型
		NewExterior_DressBox_UpdateObj()
	end
	
end

--设置方案
function NewExterior_DressBox_FangAnSettingClicked()

	local g_CurSelShareStyleIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("STYLE")
	if g_CurSelShareStyleIdx > 0 and g_CurSelShareStyleIdx <= g_DressBox_FangAn_Max then
		PushEvent("SET_SHARESTYLE_NAME", g_CurSelShareStyleIdx)
	else
		PushDebugMessage("#{SZDP_230509_59}")
	end
	
end

--保存方案
function NewExterior_DressBox_FangAnSaveClicked()

	local g_CurSelShareStyleIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("STYLE")
	if g_CurSelShareStyleIdx > 0 and g_CurSelShareStyleIdx <= g_DressBox_FangAn_Max then
		-- 保存 不去重 直接覆盖
		--Exterior:LuaFnSaveExteriorShareInfo(g_CurSelShareStyleIdx-1)
		if Exterior:LuaFnIsHaveExteriorShareChange(g_CurSelShareStyleIdx-1) == 1 then
			PushEvent("SAVE_SHARESTYLE_CONFIRM", g_CurSelShareStyleIdx)
		else
			PushDebugMessage("#{SZDP_230509_17}")
		end
	else
		PushDebugMessage("#{SZDP_230509_60}")
	end
	
end

--分享
function NewExterior_DressBox_FangAnShareClicked()

	local g_CurSelShareStyleIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("STYLE")
	if g_CurSelShareStyleIdx > 0 and g_CurSelShareStyleIdx <= g_DressBox_FangAn_Max then	
		-- 分享 （1-10）
		Exterior:LuaFnExteriorShareClick(g_CurSelShareStyleIdx-1)
	else
		PushDebugMessage("#{SZDP_230509_57}")
	end
	
end

-- 打开时装图鉴
function NewExterior_DressBox_OpenDressStyle()
	NewExterior_DressBox_SavePosition()
	PushEvent("OPEN_EXTERIOR_DRESSSTYLE")
	--PushDebugMessage("#{SZTJ_230505_42}")
end

-- 打开配饰图鉴
function NewExterior_DressBox_OpenGemEffect()
	NewExterior_DressBox_SavePosition()
	PushEvent("OPEN_EXTERIOR_GEMEFFECT")
	--PushDebugMessage("#{SZTJ_230505_42}")
end

-- 更改性别
function NewExterior_DressBox_ChangeSex()
	local sex = Exterior:LuaFnGetExteriorRaceID()
	if sex ~= nil then
		if sex == g_PlayerRace.SEX_FEMALE then
			Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_MALE)
		elseif sex == g_PlayerRace.SEX_MALE then
			Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_FEMALE)
		end
		NewExterior_DressBox_Show()
	end
end

function NewExterior_DressBox_GenderUpdate()
	local sex = Exterior:LuaFnGetExteriorRaceID()
	if sex ~= nil and g_sexButtonInfo[sex] ~= nil then
		NewExterior_DressBox_GenderChange_Btn:SetProperty("HoverImage", g_sexButtonInfo[sex].imgH)
		NewExterior_DressBox_GenderChange_Btn:SetProperty("NormalImage", g_sexButtonInfo[sex].imgN)
		NewExterior_DressBox_GenderChange_Btn:SetProperty("PushedImage", g_sexButtonInfo[sex].imgP)
	end
end

-- 图鉴页签
function NewExterior_DressBox_PageButtonUpdate()
    NewExterior_DressBox_GoTo_DressBox:SetCheck(1)
    NewExterior_DressBox_GoTo_DressStyle:SetCheck(0)
    NewExterior_DressBox_GoTo_GemEffect:SetCheck(0)
end

function NewExterior_DressBox_PetPossJianDisplay()
	local IsDisplay = SystemSetup:Lua_GetFuTiDisplayState()
	if IsDisplay == 1 then
		NewExterior_DressBox_PetPossJian_Type:SetCheck(0)
		SystemSetup:Lua_SetFuTiDisplayState(1)
	else
		NewExterior_DressBox_PetPossJian_Type:SetCheck(1)
		SystemSetup:Lua_SetFuTiDisplayState(0)
	end	
end

--!!!reloadscript =NewExterior_DressBox
