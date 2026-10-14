--!!!reloadscript =NewExterior_Show

local g_NewExterior_Show_UnifiedPosition = ""

local g_NewExterior_Show_CurPage = 1
local g_NewExterior_Show_DressPage = 1
local g_NewExterior_Show_WeaponPage = 2
local g_NewExterior_Show_RidePage = 3

local g_NewExterior_ExteriorTypeRide = 0
local g_NewExterior_ExteriorTypeWeapon = 1


local g_NeedChangeScrollSize = 1

local g_CurSelExteriorIndex = 0			--当前选择的外观索引，从1开始
local g_CurSelExteriorID = 0			--当前选择的外观ID，从1开始
local g_CurSelShowExteriorID = 0		--当前选择的外观ID，从1开始
local g_CurSelShowExteriorIndex = 0		--当前选择的外观索引，从1开始
local g_TargetExteriorIndex = 0			--定位的外观索引，从1开始
local g_TargetExteriorID = 0			--定位的外观ID
local g_TargetExteriorIdx = 0			--定位的外观索引

local g_CurSelWeaponLevel = 0
local g_CurWeaponSelExteriorID = 0		--当前选择的外观ID，从1开始
local g_CurWeaponSelShowExteriorID = 0	--当前选择的外观ID，从1开始
local g_TargetWeaponExteriorIndex = 0	--定位的外观索引，从1开始
local g_TargetWeaponExteriorID = 0		--定位的外观ID

local g_CurRideSelExteriorID = 0		--当前选择的外观ID，从1开始
local g_CurRideSelShowExteriorID = 0	--当前选择的外观ID，从1开始
local g_TargetRideExteriorIndex = 0		--定位的外观索引，从1开始
local g_TargetRideExteriorID = 0		--定位的外观ID

local g_Distance = 1
local g_Distance_Ori = 2
local g_Distance_Max = 4

local m_PlayerfashionDepotType = 1 	--仓库类型 1 玩家时装仓库 2 子女时装仓库
local g_ExteriorType = 0 	--图鉴类型  0是坐骑 1是幻武
local g_MaxShowBarNum = 10 

local g_InitFashionList = 0
local g_MaxFashionBarNum = 300		-- 时装最大是200 
local g_FashionBarList = {}
local g_FashionShowBarList = {}

local g_PlayerFashionInfoList = {}
local g_PlayerFashionShowInfoList = {}

local g_InitWeaponList = 0
local g_MaxWeaponBarNum = 0			-- 坐骑和幻武是读表数据
local g_WeaponBarList = {}
local g_WeaponShowBarList = {}

local g_PlayerWeaponShowInfoList = {}
	
local g_NewExterior_Show_LevelImage = {
	"set:Rune_Star01 image:Rune_Level01", 
	"set:Rune_Star01 image:Rune_Level02", 
	"set:Rune_Star01 image:Rune_Level03", 
	"set:Rune_Star01 image:Rune_Level04", 
	"set:Rune_Star01 image:Rune_Level05",
}

local g_NewExterior_Show_Op_Open = 2
local g_NewExterior_Show_Op_Update = 3
local g_NewExterior_Show_Op_Remove = 4

local g_InitRideList = 0
local g_MaxRideBarNum = 0			-- 坐骑和幻武是读表数据
local g_RideBarList = {}
local g_RideShowBarList = {}

local g_PlayerRideShowInfoList = {}

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
}

--=========
--PreLoad==
--=========
function NewExterior_Show_PreLoad()

	this:RegisterEvent("OPEN_EXTERIOR_YIRONGGE")
	this:RegisterEvent("UPDATE_EXTERIOR_YIRONGGE",false)
	this:RegisterEvent("CLOSE_EXTERIOR_YIRONGGE",false)
		
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
function NewExterior_Show_OnLoad()

	g_NewExterior_Show_UnifiedPosition = NewExterior_Show_Frame:GetProperty("UnifiedPosition")
	
end

--=========
--OnEvent
--=========
function NewExterior_Show_OnEvent(event)
	
	if event == "OPEN_EXTERIOR_YIRONGGE" then
		if this:IsVisible() and tonumber(arg0) == 0 then
			NewExterior_Show_CloseUI()	
			return
		else				
			g_NewExterior_Show_CurPage = tonumber(arg0)
			if g_NewExterior_Show_CurPage < g_NewExterior_Show_DressPage or g_NewExterior_Show_CurPage > g_NewExterior_Show_RidePage then
				g_NewExterior_Show_CurPage = g_NewExterior_Show_DressPage
			end
			
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
			NewExterior_Show_SetPosition()
			NewExterior_Show_CloseSameGroupWindow()
			this:Show()
				
			NewExterior_Show_ChangePage(g_NewExterior_Show_CurPage)
		end	
		return
	end
	
	if event == "UPDATE_EXTERIOR_YIRONGGE" and this:IsVisible() then				
		g_NewExterior_Show_CurPage = tonumber(arg0)
		if g_NewExterior_Show_CurPage >= g_NewExterior_Show_DressPage and g_NewExterior_Show_CurPage <= g_NewExterior_Show_RidePage then				
			NewExterior_Show_ChangePage(g_NewExterior_Show_CurPage)
		end		
	end
		
	if event == "CLOSE_EXTERIOR_YIRONGGE" and this:IsVisible() then
		if tonumber(arg0) == 0 then
			if tonumber(arg1) == 1 then
				NewExterior_Show_CloseUI()	
			elseif tonumber(arg1) == 2 then
				NewExterior_Show_OpenExteriorUI()
			end
			return
		end
	end
	
	if ( event == "OPEN_STALL_SALE" ) 		-- 开始摆摊，还原试穿
		or ( event == "PROGRESSBAR_SHOW" )	-- 读进度条中，还原试穿
		or ( event == "MODELID_CHANGE" ) 	-- 变身 关闭界面
		then
		NewExterior_Show_CloseUI()	
		return
	end	

	if event == "ORNAMENTS_DISPLAYUPDATE" then
		-- 刷新模型
		Exterior:LuaFnUpdateExteriorYiRongGeData(g_NewExterior_Show_CurPage)
		return
	end

	-- FakeObject模型界面互斥
	if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
	   ( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
		if (this:IsVisible()) then
			NewExterior_Show_CloseUI()
			return
		end
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 80081701 ) then
		if (this:IsVisible()) then
			NewExterior_Show_CloseUI()
			return
		end
	end
	
	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
		NewExterior_Show_CloseUI()
		return
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		NewExterior_Show_Frame:SetProperty("UnifiedPosition", g_NewExterior_Show_UnifiedPosition)
	end

end

function NewExterior_Show_ChangePage(nCurPage)
	
	if nCurPage == g_NewExterior_Show_WeaponPage then
		NewExterior_Show_Weapon()
	elseif nCurPage == g_NewExterior_Show_RidePage then
		NewExterior_Show_Ride()
	else
		-- 默认就打开时装设置界面
		NewExterior_Show_Dress()
	end
	
end

--左侧
function NewExterior_Show_UpdateLeftBtn()
	
	NewExterior_Show_CleanUp_LeftButton()
	
	local sex = GetMySelfRaceId()
	
	--时装
	local cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurExteriorYiRongGeSetInfo("FASHION")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(m_PlayerfashionDepotType, cacheExteriorIdx)
		if theAction:GetID() ~= 0 then
			NewExterior_Show_Dress_LeftBtn:SetActionItem(theAction:GetID())
			NewExterior_Show_Dress_ActionImg:Show()
			
			local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
			if nCurFashionId ~= nil and nCurFashionId > 0 then
				if nCurFashionIdx == cacheExteriorIdx then
					NewExterior_Show_Dress_ActionImg:Hide()
				end
			end
		end
	else
		local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
		if nCurFashionId ~= nil and nCurFashionId > 0 then
			local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(m_PlayerfashionDepotType, nCurFashionIdx)
			if theAction:GetID() ~= 0 then
				NewExterior_Show_Dress_LeftBtn:SetActionItem(theAction:GetID())
			end
		end			
	end
	
	--坐骑
	local edType = 0	
	local cacheExteriorID = Exterior:LuaFnGetCurExteriorYiRongGeSetInfo("RIDE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Name")
		local strIcon = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Show_Ride_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Show_Ride_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Show_Ride_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Show_Ride_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Show_Ride_LockImg:Show()
		end
	end
	
	--幻武
	edType = 1
	cacheExteriorID = Exterior:LuaFnGetCurExteriorYiRongGeSetInfo("WEAPON")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		local strName 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Name")
		local strIcon 	= Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Icon")
		local strImage = GetIconFullName(strIcon)
		
		NewExterior_Show_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
		NewExterior_Show_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
		NewExterior_Show_Weapon_LeftBtn:SetToolTip(strTemp)
		--试穿
		if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
			NewExterior_Show_Weapon_ActionImg:Show()
		end
		--未激活
		if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
			NewExterior_Show_Weapon_LockImg:Show()
		end
	end
	
end

function NewExterior_Show_Dress()
	
	g_Distance = g_Distance_Ori
	g_NeedChangeScrollSize = 1
	
	NewExterior_Show_Weapon_Active:Hide()
	NewExterior_Show_Weapon_FenYe:Hide()
	
	NewExterior_Show_Ride_FenYe:Hide()
	NewExterior_Show_Ride_Active:Hide()
		
	NewExterior_Show_Dress_Active:Show()
	NewExterior_Show_Dress_FenYe:Show()
	NewExterior_Show_Dress_InitList()
	
	NewExterior_Show_CleanUp()
	
	NewExterior_Show_Dress_FakeObject:AttachWindowEx("Exterior_Player")		
	g_NewExterior_Show_CurPage = g_NewExterior_Show_DressPage
	
	Exterior:LuaFnInitCurExteriorYiRongGeSet()
	
	-- 下面的预览定位
	g_CurSelShowExteriorID = 0
	g_CurSelShowExteriorIndex = -1
	-- 上面的预览定位
	g_CurSelExteriorID = 0
	g_CurSelExteriorIndex = -1
	-- 滑轮定位
	g_TargetExteriorID = 0
	g_TargetExteriorIdx = -1
	
	--时装
	local cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurExteriorYiRongGeSetInfo("FASHION")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		g_TargetExteriorID = cacheExteriorID
		g_TargetExteriorIdx = cacheExteriorIdx + 1
		
		g_CurSelExteriorID = cacheExteriorID
		g_CurSelExteriorIndex = cacheExteriorIdx + 1
		
		local OpPos = Exterior:LuaFnCheckFashionInExteriorYiRongGe(g_NewExterior_Show_DressPage, cacheExteriorIdx, cacheExteriorID)
		if OpPos ~= -1 then	
			g_CurSelShowExteriorID = cacheExteriorID
			g_CurSelShowExteriorIndex = cacheExteriorIdx + 1
		end
	end
	
	--左侧
	NewExterior_Show_UpdateLeftBtn()
			
	--列表 排序
	NewExterior_Show_Dress_UpdateList()
		
	--模型
	NewExterior_Show_Dress_UpdateObj()
	
end

--模型 —— 时装
function NewExterior_Show_Dress_UpdateObj()
	
	local cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurExteriorYiRongGeSetInfo("FASHION")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		Exterior:LuaFnUpdateExteriorYiRongGeData(g_NewExterior_Show_DressPage)	
		Exterior:LuaFnUpdateExteriorAvatarFashion(cacheExteriorID, cacheExteriorIdx)			
	else	
		Exterior:LuaFnUpdateExteriorYiRongGeData(g_NewExterior_Show_DressPage)			
	end
	
	NewExterior_Show_UpdateCamera(g_NewExterior_Show_DressPage)
	
end

--列表 
function NewExterior_Show_Dress_InitList()
	
	if g_InitFashionList == 0 then				
		for i = 1, g_MaxFashionBarNum do
			local bar = NewExterior_Show_Dress_SuperList:AddChild("NewExterior_Show_Dress_SuperListItem")
		
			bar:GetSubItem("NewExterior_Show_Dress_SuperListItemAction"):SetEvent("Clicked", string.format("NewExterior_Show_Dress_ItemUpClicked(%d)", i))
			bar:GetSubItem("NewExterior_Show_Dress_SuperListItemAction"):SetProperty("DraggingEnabled", "False")
			bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionAdd"):SetEvent("Clicked", string.format("NewExterior_Show_Dress_ItemAddClicked(%d)", i))
						
			table.insert(g_FashionBarList, bar)
			table.insert(g_PlayerFashionInfoList, {})
		end
					
		for i = 1, g_MaxShowBarNum do
			local showbar = NewExterior_Show_Dress_List:AddChild("NewExterior_Show_Dress_ListItem")
			showbar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
		
			showbar:GetSubItem("NewExterior_Show_Dress_ListItemAction"):SetEvent("Clicked", string.format("NewExterior_Show_Dress_ItemDownClicked(%d)", i))
			showbar:GetSubItem("NewExterior_Show_Dress_ListItemAction"):SetEvent("MouseRClick", string.format("NewExterior_Show_Dress_ItemRemoveClicked(%d)", i))
			showbar:GetSubItem("NewExterior_Show_Dress_ListItemAction"):SetProperty("DraggingEnabled", "False")
			showbar:GetSubItem("NewExterior_Show_Dress_ListItemActionRemove"):SetEvent("Clicked", string.format("NewExterior_Show_Dress_ItemRemoveClicked(%d)", i))
						
			showbar:GetSubItem("NewExterior_Show_Dress_ListItemActionRemove"):Hide()
			showbar:GetSubItem("NewExterior_Show_Dress_ListItemActionTry"):Hide()
			showbar:GetSubItem("NewExterior_Show_Dress_ListItemActionDef"):Hide()
			
			table.insert(g_FashionShowBarList, showbar)
			table.insert(g_PlayerFashionShowInfoList, {})
		end
		g_InitFashionList = 1
	end
		
	-- 填充时装数据
	local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
	for i=1, g_MaxFashionBarNum do 
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
		
		local OpPos = Exterior:LuaFnCheckFashionInExteriorYiRongGe(g_NewExterior_Show_DressPage, nVecIndex, nExteriorID)
		if OpPos ~= -1 then
			g_PlayerFashionInfoList[i].bInYiRongGe = 1
		else
			g_PlayerFashionInfoList[i].bInYiRongGe = 0
		end
	end
	
	for i = 1, g_MaxShowBarNum do
		local nFashionIdx, nFashionId = Exterior:LuaFnGetExteriorYiRongGeData(g_NewExterior_Show_DressPage, i-1)
		local nExteriorID = FashionDepot:LuaFnGetFashionId(m_PlayerfashionDepotType, nFashionIdx)
		if nExteriorID > 0 and nExteriorID == nFashionId then
			g_PlayerFashionShowInfoList[i].nVecIndex = nFashionIdx
			g_PlayerFashionShowInfoList[i].nExteriorID = nFashionId
			if nCurFashionId ~= nil and nCurFashionId > 0 and nCurFashionId == nFashionId and nCurFashionIdx == nFashionIdx then
				g_PlayerFashionShowInfoList[i].bDressUp = 1
			else
				g_PlayerFashionShowInfoList[i].bDressUp = 0
			end
		else
			g_PlayerFashionShowInfoList[i].nVecIndex = -1
			g_PlayerFashionShowInfoList[i].nExteriorID = -1
			g_PlayerFashionShowInfoList[i].bDressUp = 0
		end
	end
end

--列表 列表
function NewExterior_Show_Dress_UpdateList()
			
	-- 显示
	for i, v in pairs(g_PlayerFashionInfoList) do 
	
		local bar = g_FashionBarList[i]
		bar:Show()
	
		local ctrlAction = bar:GetSubItem("NewExterior_Show_Dress_SuperListItemAction")
		local nVecIndex = v.nVecIndex
		local nExteriorID = FashionDepot:LuaFnGetFashionId(m_PlayerfashionDepotType, nVecIndex)
		local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(m_PlayerfashionDepotType, nVecIndex)
		if theAction:GetID() ~= 0 then
			ctrlAction:SetActionItem(theAction:GetID())
		else
			ctrlAction:SetActionItem(-1)
		end
		
		bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionShow"):Hide()
		bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionAdd"):Hide()
		if nExteriorID and nExteriorID > 0 then
			if Exterior:LuaFnCheckFashionInExteriorYiRongGe(g_NewExterior_Show_DressPage, nVecIndex, nExteriorID) ~= -1 then	
				bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionShow"):Show()
				bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionShow"):SetToolTip("#{CKWG_220509_41}")
			else
				bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionAdd"):Show()
				bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionAdd"):SetToolTip("#{CKWG_220509_10}")
			end 
				
			if g_TargetExteriorID == nExteriorID and g_TargetExteriorIdx == nVecIndex + 1 then
			--	g_TargetExteriorIndex = i
			end
		end
		
		bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionDef"):Hide()
		local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
		if nCurFashionId ~= nil and nCurFashionId > 0 then
			if nCurFashionId == nExteriorID and v.bDressUp == 1 then
				bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionDef"):Show()
			end
		end
		
		bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionLuxury"):Hide()
		local nFashionNumber = Exterior:LuaFnGetNumberingFashionInfo(nExteriorID, "Number")
		if nFashionNumber ~= nil and nFashionNumber > 0 then
			bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionLuxury"):Show()
		end
		
		if g_CurSelExteriorID == nExteriorID and g_CurSelExteriorIndex == nVecIndex + 1 then
			ctrlAction:SetPushed(1)
			bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionTry"):Show()
			if v.bDressUp == 1 then
				bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionTry"):Hide()
			end
		else
			ctrlAction:SetPushed(0)
			bar:GetSubItem("NewExterior_Show_Dress_SuperListItemActionTry"):Hide()
		end	
	end
	
	if g_NeedChangeScrollSize == 1 then
		NewExterior_Show_Dress_SuperList:RefreshLayout()
		g_NeedChangeScrollSize = 0
	end
	
	if g_TargetExteriorIndex ~= 0 then
	--	NewExterior_Show_Dress_SuperList:SetScrollPosition4Index(g_TargetExteriorIndex - 1)
		g_TargetExteriorID = 0
		g_TargetExteriorIdx = -1 
		g_TargetExteriorIndex = 0
	else
	--	NewExterior_Show_Dress_SuperList:SetScrollPosition4Index(0)
	end
	
	-- 显示易容阁数据
	NewExterior_Show_Dress_UpdateDownList()
	
end

--时装 列表
function NewExterior_Show_Dress_UpdateDownList()

	for i = 1, g_MaxShowBarNum do
		if g_FashionShowBarList[i] ~= nil then
			local ctrlAction = g_FashionShowBarList[i]:GetSubItem("NewExterior_Show_Dress_ListItemAction")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
			g_FashionShowBarList[i]:GetSubItem("NewExterior_Show_Dress_ListItemActionRemove"):Hide()
			g_FashionShowBarList[i]:GetSubItem("NewExterior_Show_Dress_ListItemActionTry"):Hide()
			g_FashionShowBarList[i]:GetSubItem("NewExterior_Show_Dress_ListItemActionDef"):Hide()
			g_FashionShowBarList[i]:GetSubItem("NewExterior_Show_Dress_ListItemActionLuxury"):Hide()
		end
	end
	
	-- 显示易容阁数据
	for i, v in pairs(g_PlayerFashionShowInfoList) do 
		
		local bar = g_FashionShowBarList[i]
		bar:Show()
			
		local nVecIndex = v.nVecIndex
		local nExteriorID = FashionDepot:LuaFnGetFashionId(m_PlayerfashionDepotType, nVecIndex)
		local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(m_PlayerfashionDepotType, nVecIndex)
		local ctrlAction = bar:GetSubItem("NewExterior_Show_Dress_ListItemAction")
		if theAction:GetID() ~= 0 then
			ctrlAction:SetActionItem(theAction:GetID())
		else
			ctrlAction:SetActionItem(-1)
		end
		
		bar:GetSubItem("NewExterior_Show_Dress_ListItemActionRemove"):Hide()
		if nExteriorID and nExteriorID > 0 then
			bar:GetSubItem("NewExterior_Show_Dress_ListItemActionRemove"):Show()
			bar:GetSubItem("NewExterior_Show_Dress_ListItemActionRemove"):SetToolTip("#{CKWG_220509_11}")
		end 
		
		bar:GetSubItem("NewExterior_Show_Dress_ListItemActionDef"):Hide()
		local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
		if nCurFashionId ~= nil and nCurFashionId > 0 then
			if nCurFashionId == nExteriorID and v.bDressUp == 1 then
				bar:GetSubItem("NewExterior_Show_Dress_ListItemActionDef"):Show()
			end
		end
		
		bar:GetSubItem("NewExterior_Show_Dress_ListItemActionTry"):Hide()
		local cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurExteriorYiRongGeSetInfo("FASHION")
		if cacheExteriorID ~= nil and cacheExteriorID > 0 then
			if cacheExteriorID == nExteriorID and cacheExteriorIdx == nVecIndex and v.bDressUp == 0 then
				bar:GetSubItem("NewExterior_Show_Dress_ListItemActionTry"):Show()
			end
		end
				
		bar:GetSubItem("NewExterior_Show_Dress_ListItemActionLuxury"):Hide()
		local nFashionNumber = Exterior:LuaFnGetNumberingFashionInfo(nExteriorID, "Number")
		if nFashionNumber ~= nil and nFashionNumber > 0 then
			bar:GetSubItem("NewExterior_Show_Dress_ListItemActionLuxury"):Show()
		end
	
	end
	
end

function NewExterior_Show_Dress_ItemUpClicked(nIndex)

	local tabInfo = g_PlayerFashionInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		return
	end
	
	local nVecIndex = tabInfo.nVecIndex+1
	if g_CurSelExteriorID ~= tabInfo.nExteriorID or g_CurSelExteriorIndex ~= nVecIndex then	
		g_CurSelExteriorID = tabInfo.nExteriorID
		g_CurSelExteriorIndex = nVecIndex				
		Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("FASHION", g_CurSelExteriorID, nVecIndex-1)		
		NewExterior_Show_Dress_SetItemUpSelected(nIndex)
			
		local nShowIdx = Exterior:LuaFnCheckFashionInExteriorYiRongGe(g_NewExterior_Show_DressPage, nVecIndex-1, g_CurSelExteriorID) + 1
		if nShowIdx > 0 and nShowIdx <= g_MaxShowBarNum then	
			g_CurSelShowExteriorID = g_CurSelExteriorID
			g_CurSelShowExteriorIndex = nVecIndex	
			NewExterior_Show_Dress_SetItemDownSelected(nShowIdx)	
		else
			NewExterior_Show_Dress_SetItemDownUnSelected()
		end
			
		NewExterior_Show_Dress_UpdateObj()	
		NewExterior_Show_UpdateLeftBtn()
	else
		local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
		Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("FASHION", nCurFashionId, nCurFashionIdx)			
		NewExterior_Show_Dress()
	end	
	
end

function NewExterior_Show_Dress_SetItemUpSelected(nIndex)

	local tabInfo = g_PlayerFashionInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		return
	end
	
	for i = 1, g_MaxFashionBarNum do		
		if g_FashionBarList[i] ~= nil then	
			g_FashionBarList[i]:GetSubItem("NewExterior_Show_Dress_SuperListItemActionTry"):Hide()
			
			local ctrlAction = g_FashionBarList[i]:GetSubItem("NewExterior_Show_Dress_SuperListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
					if tabInfo.bDressUp == 0 then
						g_FashionBarList[i]:GetSubItem("NewExterior_Show_Dress_SuperListItemActionTry"):Show()
					end
	
					local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
					if nCurFashionId ~= nil and nCurFashionId > 0 then
						if nCurFashionIdx == tabInfo.nVecIndex then
						g_FashionBarList[i]:GetSubItem("NewExterior_Show_Dress_SuperListItemActionTry"):Hide()
						end
					end
					
				else
					ctrlAction:SetPushed(0)	
				end
			end
		end
	end
	
end

function NewExterior_Show_Dress_ItemDownClicked(nIndex)

	local tabInfo = g_PlayerFashionShowInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		return
	end
	
	local nVecIndex = tabInfo.nVecIndex+1
	if g_CurSelShowExteriorID ~= tabInfo.nExteriorID or g_CurSelShowExteriorIndex ~= nVecIndex then	
		g_CurSelShowExteriorID = tabInfo.nExteriorID
		g_CurSelShowExteriorIndex = nVecIndex
				
		Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("FASHION", g_CurSelShowExteriorID, nVecIndex-1)		
		NewExterior_Show_Dress_SetItemDownSelected(nIndex)
		
		for idx = 1, g_MaxFashionBarNum do				
			if g_CurSelShowExteriorID == g_PlayerFashionInfoList[idx].nExteriorID and g_CurSelShowExteriorIndex == g_PlayerFashionInfoList[idx].nVecIndex+1 then
				NewExterior_Show_Dress_SetItemUpSelected(idx)	
			end
		end
			
		NewExterior_Show_Dress_UpdateObj()	
		NewExterior_Show_UpdateLeftBtn()
	else
		local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
		Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("FASHION", nCurFashionId, nCurFashionIdx)			
		NewExterior_Show_Dress()
	end	
	
end

function NewExterior_Show_Dress_SetItemDownSelected(nIndex)

	local tabInfo = g_PlayerFashionShowInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		return
	end
	
	for i = 1, g_MaxShowBarNum do		
		if g_FashionShowBarList[i] ~= nil then	
			g_FashionShowBarList[i]:GetSubItem("NewExterior_Show_Dress_ListItemActionTry"):Hide()
			
			local ctrlAction = g_FashionShowBarList[i]:GetSubItem("NewExterior_Show_Dress_ListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
					if tabInfo.bDressUp == 0 then
						g_FashionShowBarList[i]:GetSubItem("NewExterior_Show_Dress_ListItemActionTry"):Show()
					end
	
					local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
					if nCurFashionId ~= nil and nCurFashionId > 0 then
						if nCurFashionIdx == tabInfo.nVecIndex then
						g_FashionShowBarList[i]:GetSubItem("NewExterior_Show_Dress_ListItemActionTry"):Hide()
						end
					end
					
				else
					ctrlAction:SetPushed(0)	
				end
			end
		end
	end
	
end

function NewExterior_Show_Dress_SetItemDownUnSelected()
	g_CurSelShowExteriorID = 0
	g_CurSelShowExteriorIndex = -1
	for i = 1, g_MaxShowBarNum do		
		if g_FashionShowBarList[i] ~= nil then	
			local ctrlAction = g_FashionShowBarList[i]:GetSubItem("NewExterior_Show_Dress_ListItemAction")
			if ctrlAction ~= nil then
				ctrlAction:SetPushed(0)	
				g_FashionShowBarList[i]:GetSubItem("NewExterior_Show_Dress_ListItemActionTry"):Hide()
			end
		end
	end
end

-- 增加预览
function NewExterior_Show_Dress_ItemAddClicked(nIndex)

	local tabInfo = g_PlayerFashionInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 or tabInfo.nVecIndex < 0 then 
		return
	end
	
	local nExteriorID = FashionDepot:LuaFnGetFashionId(m_PlayerfashionDepotType, tabInfo.nVecIndex)	
	Exterior:LuaFnSetExteriorYiRongGeData(g_NewExterior_Show_DressPage, g_NewExterior_Show_Op_Update, tabInfo.nVecIndex, nExteriorID)	
	
	--Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("FASHION", nExteriorID, tabInfo.nVecIndex)	
end

-- 移除预览
function NewExterior_Show_Dress_ItemRemoveClicked(nIndex)

	local tabInfo = g_PlayerFashionShowInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 or tabInfo.nVecIndex < 0 then 
		return
	end
	
	local nExteriorID = FashionDepot:LuaFnGetFashionId(m_PlayerfashionDepotType, tabInfo.nVecIndex)	
	Exterior:LuaFnSetExteriorYiRongGeData(g_NewExterior_Show_DressPage, g_NewExterior_Show_Op_Remove, tabInfo.nVecIndex, nExteriorID)	
	
	--Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("FASHION", nExteriorID, tabInfo.nVecIndex)	
end

-- 幻武
function NewExterior_Show_Weapon()
	
	g_Distance = g_Distance_Ori
	g_NeedChangeScrollSize = 1
	
	NewExterior_Show_Dress_FenYe:Hide()
	NewExterior_Show_Dress_Active:Hide()
		
	NewExterior_Show_Ride_FenYe:Hide()
	NewExterior_Show_Ride_Active:Hide()
	
	NewExterior_Show_Weapon_Active:Show()
	NewExterior_Show_Weapon_FenYe:Show()
	NewExterior_Show_Weapon_InitList()
	
	NewExterior_Show_CleanUp()
	
	Exterior:LuaFnInitCurExteriorYiRongGeSet()
	
	NewExterior_Show_Weapon_FakeObject:AttachWindowEx("Exterior_Player")		
	g_NewExterior_Show_CurPage = g_NewExterior_Show_WeaponPage
	
	g_TargetWeaponExteriorID = 0
	g_CurWeaponSelExteriorID = 0	
	g_CurWeaponSelShowExteriorID = 0
	g_CurSelWeaponLevel = 0

	local group = 0 
	local level = 0
	local cacheExteriorID = Exterior:LuaFnGetCurExteriorYiRongGeSetInfo("WEAPON")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		group, level = Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Group")
		if group ~= nil and level ~= nil then
			g_TargetWeaponExteriorID = group
			g_CurWeaponSelExteriorID = group
			g_CurSelWeaponLevel = level + 1
			
			if Exterior:LuaFnCheckInExteriorYiRongGe(g_NewExterior_Show_WeaponPage, group) ~= -1 then			
				g_CurWeaponSelShowExteriorID = group
			end
		end			
	end	
	
	--左侧
	NewExterior_Show_UpdateLeftBtn()
			
	--列表 排序
	NewExterior_Show_Weapon_UpdateList()
		
	--模型
	NewExterior_Show_Weapon_UpdateObj()
	
end

--模型 —— 幻武
function NewExterior_Show_Weapon_UpdateObj()

	local cacheExteriorID = Exterior:LuaFnGetCurExteriorYiRongGeSetInfo("WEAPON")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then	
		Exterior:LuaFnUpdateExteriorAvatarWeapon(cacheExteriorID)
		Exterior:LuaFnUpdateExteriorYiRongGeData(g_NewExterior_Show_WeaponPage)			
	else	
		Exterior:LuaFnUpdateExteriorYiRongGeData(g_NewExterior_Show_WeaponPage)			
	end
	
	NewExterior_Show_UpdateCamera(g_NewExterior_Show_WeaponPage)
	
end

-- 幻武 
function NewExterior_Show_Weapon_InitList()
	
	if g_InitWeaponList == 0 then	
		
		g_MaxWeaponBarNum = Exterior:LuaFnGetExteriorWeaponGroupCount()
		
		for i = 1, g_MaxWeaponBarNum do
			local bar = NewExterior_Show_Weapon_SuperList:AddChild("NewExterior_Show_Weapon_SuperListItem")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemAction"):SetEvent("MouseLButtonDown", string.format("NewExterior_Show_Weapon_ItemUpClicked(%d)", i))
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemAction"):SetProperty("DraggingEnabled", "False")
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemAction"):SetProperty("Empty", "False")
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemAction"):SetProperty("UseDefaultTooltip", "True")
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionAdd"):SetEvent("Clicked", string.format("NewExterior_Show_Weapon_ItemAddClicked(%d)", i))
			
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionNumber"):Hide()
			
			g_WeaponBarList[i] = bar
		end
		
		for i = 1, g_MaxShowBarNum do
			local showbar = NewExterior_Show_Weapon_List:AddChild("NewExterior_Show_Weapon_ListItem")
			showbar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			showbar:GetSubItem("NewExterior_Show_Weapon_ListItemAction"):SetEvent("MouseLButtonDown", string.format("NewExterior_Show_Weapon_ItemDownClicked(%d)", i))
			showbar:GetSubItem("NewExterior_Show_Weapon_ListItemAction"):SetEvent("MouseRClick", string.format("NewExterior_Show_Weapon_ItemRemoveClicked(%d)", i))
			showbar:GetSubItem("NewExterior_Show_Weapon_ListItemAction"):SetProperty("DraggingEnabled", "False")
			showbar:GetSubItem("NewExterior_Show_Weapon_ListItemAction"):SetProperty("Empty", "False")
			showbar:GetSubItem("NewExterior_Show_Weapon_ListItemAction"):SetProperty("UseDefaultTooltip", "True")
			showbar:GetSubItem("NewExterior_Show_Weapon_ListItemActionRemove"):SetEvent("Clicked", string.format("NewExterior_Show_Weapon_ItemRemoveClicked(%d)", i))
			
			showbar:GetSubItem("NewExterior_Show_Weapon_ListItemActionRemove"):Hide()
			showbar:GetSubItem("NewExterior_Show_Weaponn_ListItemActionDong"):Hide()
			showbar:GetSubItem("NewExterior_Show_Weapon_ListItemActionTry"):Hide()
			showbar:GetSubItem("NewExterior_Show_Weapon_ListItemActionDef"):Hide()
			showbar:GetSubItem("NewExterior_Show_Weapon_ListItemActionNumber"):Hide()
		
			g_WeaponShowBarList[i] = showbar	
			table.insert(g_PlayerWeaponShowInfoList, {})
		end
		
		g_InitWeaponList = 1
	end
	
end

-- 幻武 列表
function NewExterior_Show_Weapon_UpdateList()	
	-- 初始化数据
	Exterior:LuaFnInitExteriorWeaponGroupList()
	
	local count = Exterior:LuaFnGetWeaponGroupListCount(0)
	
	-- 填充上面的数据	
	for i = 1, g_MaxWeaponBarNum do	
		NewExterior_Show_Weapon_SetItemUp(i, count)
	end
	
	-- 填充下面的数据	
	NewExterior_Show_Weapon_UpdateDownList()
		
	if g_NeedChangeScrollSize == 1 then
		NewExterior_Show_Weapon_SuperList:RefreshLayout()
		g_NeedChangeScrollSize = 0
	end
	
	if g_TargetWeaponExteriorIndex ~= 0 then
	--	NewExterior_Show_Weapon_SuperList:SetScrollPosition4Index(g_TargetWeaponExteriorIndex - 1)
		g_TargetWeaponExteriorID = 0
		g_TargetWeaponExteriorIndex = 0
	else
	--	NewExterior_Show_Weapon_SuperList:SetScrollPosition4Index(0)
	end
	
end

-- 幻武 列表
function NewExterior_Show_Weapon_UpdateDownList()

	for i = 1, g_MaxShowBarNum do
		if g_WeaponShowBarList[i] ~= nil then
			local ctrlAction = g_WeaponShowBarList[i]:GetSubItem("NewExterior_Show_Weapon_ListItemAction")			
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
				ctrlAction:SetPushed(0)
			end
			g_WeaponShowBarList[i]:GetSubItem("NewExterior_Show_Weaponn_ListItemActionDong"):Hide()
			g_WeaponShowBarList[i]:GetSubItem("NewExterior_Show_Weapon_ListItemActionRemove"):Hide()
			g_WeaponShowBarList[i]:GetSubItem("NewExterior_Show_Weapon_ListItemActionTry"):Hide()
			g_WeaponShowBarList[i]:GetSubItem("NewExterior_Show_Weapon_ListItemActionDef"):Hide()
			g_WeaponShowBarList[i]:GetSubItem("NewExterior_Show_Weapon_ListItemActionNumber"):Hide()
		end
	end
	
	local ShowIndex = 1
	for i = 1, g_MaxShowBarNum do
		local nGroupID = Exterior:LuaFnGetExteriorYiRongGeData(g_NewExterior_Show_WeaponPage, i-1)
		if nGroupID > 0 and Exterior:LuaFnIsHaveExteriorWeaponGroup(nGroupID) == 1 then
			NewExterior_Show_Weapon_SetItemDown(nGroupID, ShowIndex)
			ShowIndex = ShowIndex + 1
		else
			g_PlayerWeaponShowInfoList[i].nExteriorID = -1
		end
	end
	
end

function NewExterior_Show_Weapon_SetItemUp(index, max_count)
	
	if g_WeaponBarList[index] == nil then
		return
	end
	
	if index > max_count then
		g_WeaponBarList[index]:Hide()
		return
	end
	
	local bar = g_WeaponBarList[index]
	bar:Show()
	
	local nMyMenpai = Player:GetData("MEMPAI")
	local nGroupID 	= Exterior:LuaFnGetWeaponGroupIDFromList(index - 1)
	local strIcon 	= Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "Icon")
	local strName 	= Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "Name")
	local strImage = GetIconFullName(strIcon)
	local nMenpai 	= Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "Menpai")
	
	local ctrlAction = bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemAction")
	if ctrlAction ~= nil then	

		ctrlAction:SetProperty("NormalImage", strImage)
		ctrlAction:SetProperty("HoverImage", strImage)
		
		local strTemp = Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "ToolTips")
		if nGroupID == 32 then
			strTemp = strTemp.."#r#{WGTJ_201222_146}"
		elseif nGroupID == 31 then
			strTemp = strTemp.."#r#{WGTJ_201222_145}"
		end
		ctrlAction:SetToolTip(strTemp)
		
		if g_CurWeaponSelExteriorID == nGroupID then
			ctrlAction:SetPushed(1)
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionTry"):Show()			
			local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurWeaponSelExteriorID, g_CurSelWeaponLevel - 1)
			if Exterior:LuaFnGetExteriorInUse(1) == nExteriorWeaponID then
				bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionTry"):Hide()
			end
		else
			ctrlAction:SetPushed(0)
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionTry"):Hide()
		end	

		if g_TargetWeaponExteriorID == nGroupID then
		--	g_TargetWeaponExteriorIndex = index
		end
	end
	
	--非本门派蒙红 
	if nMyMenpai == nMenpai or nMenpai == -1 then			
		bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionMark"):Hide()
	else
		bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionMark"):Show()
	end	
	
	--加减号
	bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionShow"):Hide()
	bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionAdd"):Hide()
	if Exterior:LuaFnIsHaveExteriorWeaponGroup(nGroupID) == 1 then
		if Exterior:LuaFnCheckInExteriorYiRongGe(g_NewExterior_Show_WeaponPage, nGroupID) ~= -1 then	
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionShow"):Show()
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionShow"):SetToolTip("#{CKWG_220509_41}")
		else
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionAdd"):Show()
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionAdd"):SetToolTip("#{CKWG_220509_10}")
		end
	end

	--使用中
	if Exterior:LuaFnGetWeaponGroupInUse() == nGroupID then
		bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionDef"):Show()
	else
		bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionDef"):Hide()
	end
	
	--锁
	if Exterior:LuaFnIsHaveExteriorWeaponGroup(nGroupID) == 1 then
		bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionLock"):Hide()
	else		
		bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionLock"):Show()
	end	
	
	bar:GetSubItem("NewExterior_Show_Weaponn_SuperListItemActionDong"):Hide()
	for i = 1, 5 do	
		local nID = Exterior:LuaFnGetWeaponIDFromGroup(nGroupID, i - 1)
		if nID ~= nil and nID > 0 then	
			local ActionNum = Exterior:LuaFnGetExteriorWeaponActionNum(nID)
			if ActionNum > 0 then
				bar:GetSubItem("NewExterior_Show_Weaponn_SuperListItemActionDong"):Show()
				break
			end
		end
	end
	
	local nWeaponLevel = 0
	for i = 1, 5 do	
		local nID = Exterior:LuaFnGetWeaponIDFromGroup(nGroupID, i - 1)
		if nID ~= nil and nID > 0 then	
			if nWeaponLevel < i then
				nWeaponLevel = i
			end
		end
	end		
		
	for i = 1, 5 do
		local nID = Exterior:LuaFnGetWeaponIDFromGroup(nGroupID, i - 1)
		if Exterior:LuaFnIsHaveExterior(1, nID) == 1 then
			nWeaponLevel = i
		end
	end
	
	bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionNumber"):Hide()
	if Exterior:LuaFnIsHaveExteriorWeaponGroup(nGroupID) == 1 then
		if g_NewExterior_Show_LevelImage[nWeaponLevel] ~= nil then
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionNumber"):Show()
			bar:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionNumber"):SetProperty("Image", g_NewExterior_Show_LevelImage[nWeaponLevel])
		end
	end
end

function NewExterior_Show_Weapon_SetItemDown(nGroupID, index)
	
	if index > g_MaxShowBarNum then
		return
	end
	
	if g_WeaponShowBarList[index] == nil then
		return
	end
	
	local bar = g_WeaponShowBarList[index]
	bar:Show()
	
	g_PlayerWeaponShowInfoList[index].nExteriorID = nGroupID
		
	local strIcon 	= Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "Icon")
	local strName 	= Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "Name")
	local strImage = GetIconFullName(strIcon)
	
	local ctrlAction = bar:GetSubItem("NewExterior_Show_Weapon_ListItemAction")
	if ctrlAction ~= nil then	

		ctrlAction:SetProperty("NormalImage", strImage)
		ctrlAction:SetProperty("HoverImage", strImage)
		
		local strTemp = Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "ToolTips")
		if nGroupID == 32 then
			strTemp = strTemp.."#r#{WGTJ_201222_146}"
		elseif nGroupID == 31 then
			strTemp = strTemp.."#r#{WGTJ_201222_145}"
		end
		ctrlAction:SetToolTip(strTemp)
		
		if g_CurWeaponSelExteriorID == nGroupID then
			ctrlAction:SetPushed(1)
			bar:GetSubItem("NewExterior_Show_Weapon_ListItemActionTry"):Show()			
			local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurWeaponSelExteriorID, g_CurSelWeaponLevel - 1)
			if Exterior:LuaFnGetExteriorInUse(1) == nExteriorWeaponID then
				bar:GetSubItem("NewExterior_Show_Weapon_ListItemActionTry"):Hide()
			end
		else
			ctrlAction:SetPushed(0)
			bar:GetSubItem("NewExterior_Show_Weapon_ListItemActionTry"):Hide()
		end		
	end

	bar:GetSubItem("NewExterior_Show_Weapon_ListItemActionRemove"):Show()
	bar:GetSubItem("NewExterior_Show_Weapon_ListItemActionRemove"):SetToolTip("#{CKWG_220509_11}")
	
	--使用中
	if Exterior:LuaFnGetWeaponGroupInUse() == nGroupID then
		bar:GetSubItem("NewExterior_Show_Weapon_ListItemActionDef"):Show()
	else
		bar:GetSubItem("NewExterior_Show_Weapon_ListItemActionDef"):Hide()
	end
	
	bar:GetSubItem("NewExterior_Show_Weaponn_ListItemActionDong"):Hide()
	for i = 1, 5 do	
		local nID = Exterior:LuaFnGetWeaponIDFromGroup(nGroupID, i - 1)
		if nID ~= nil and nID > 0 then	
			local ActionNum = Exterior:LuaFnGetExteriorWeaponActionNum(nID)
			if ActionNum > 0 then
				bar:GetSubItem("NewExterior_Show_Weaponn_ListItemActionDong"):Show()
				break
			end
		end
	end
	
	local nWeaponLevel = 0
	for i = 1, 5 do	
		local nID = Exterior:LuaFnGetWeaponIDFromGroup(nGroupID, i - 1)
		if nID ~= nil and nID > 0 then	
			if nWeaponLevel < i then
				nWeaponLevel = i
			end
		end
	end		
		
	for i = 1, 5 do
		local nID = Exterior:LuaFnGetWeaponIDFromGroup(nGroupID, i - 1)
		if Exterior:LuaFnIsHaveExterior(1, nID) == 1 then
			nWeaponLevel = i
		end
	end
	
	bar:GetSubItem("NewExterior_Show_Weapon_ListItemActionNumber"):Hide()
	if g_NewExterior_Show_LevelImage[nWeaponLevel] ~= nil then
		bar:GetSubItem("NewExterior_Show_Weapon_ListItemActionNumber"):Show()
		bar:GetSubItem("NewExterior_Show_Weapon_ListItemActionNumber"):SetProperty("Image", g_NewExterior_Show_LevelImage[nWeaponLevel])
	end
	
end

function NewExterior_Show_Weapon_ItemUpClicked(nIndex)
	
	local nGroupID 	= Exterior:LuaFnGetWeaponGroupIDFromList(nIndex - 1)		
	if g_CurWeaponSelExteriorID ~= nGroupID then
		g_CurWeaponSelExteriorID = nGroupID
		NewExterior_Show_Weapon_SetItemUpSelected(nIndex)
		
		local nShowIdx = Exterior:LuaFnCheckInExteriorYiRongGe(g_NewExterior_Show_WeaponPage, g_CurWeaponSelExteriorID) + 1
		if nShowIdx > 0 and nShowIdx <= g_MaxShowBarNum then	
			g_CurWeaponSelShowExteriorID = nGroupID
			NewExterior_Show_Weapon_SetItemDownSelected(nShowIdx)	
		else
			NewExterior_Show_Weapon_SetItemDownUnSelected()
		end	
		
		g_CurSelWeaponLevel = 1
		for i = 1, 5 do
			local nID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurWeaponSelExteriorID, i - 1)
			if nID > 0 then
				g_CurSelWeaponLevel = i
				break
			end			
		end
		
		for i = 1, 5 do
			local nID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurWeaponSelExteriorID, i - 1)
			if Exterior:LuaFnIsHaveExterior(1, nID) == 1 then
				g_CurSelWeaponLevel = i
			end
		end
		
		local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurWeaponSelExteriorID, g_CurSelWeaponLevel - 1)
		Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("WEAPON", nExteriorWeaponID)
		
		NewExterior_Show_UpdateLeftBtn()		
		NewExterior_Show_Weapon_UpdateObj()		
	else
		local defExteriorID = Exterior:LuaFnGetExteriorInUse(1)
		Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("WEAPON", defExteriorID)
		NewExterior_Show_Weapon()
	end	
	
end

function NewExterior_Show_Weapon_SetItemUpSelected(nIndex)
		
	for i = 1, g_MaxWeaponBarNum do		
		if g_WeaponBarList[i] ~= nil then	
			local ctrlAction = g_WeaponBarList[i]:GetSubItem("NewExterior_Show_Weapon_SuperListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
					g_WeaponBarList[i]:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionTry"):Show()
					local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurWeaponSelExteriorID, nIndex - 1)
					if Exterior:LuaFnGetExteriorInUse(1) == nExteriorWeaponID then
						g_WeaponBarList[i]:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionTry"):Hide()
					end
				else
					ctrlAction:SetPushed(0)	
					g_WeaponBarList[i]:GetSubItem("NewExterior_Show_Weapon_SuperListItemActionTry"):Hide()
				end
			end
		end
	end	
	
end

function NewExterior_Show_Weapon_ItemDownClicked(nIndex)

	if g_PlayerWeaponShowInfoList[nIndex] == nil then
		return
	end
	
	if g_PlayerWeaponShowInfoList[nIndex].nExteriorID == -1 then
		return
	end
	
	local nGroupID 	= g_PlayerWeaponShowInfoList[nIndex].nExteriorID
	
	if g_CurWeaponSelShowExteriorID ~= nGroupID then
		g_CurWeaponSelShowExteriorID = nGroupID
		NewExterior_Show_Weapon_SetItemDownSelected(nIndex)	
		
		g_CurWeaponSelExteriorID = nGroupID
		for idx = 1, g_MaxWeaponBarNum do	
			if nGroupID == Exterior:LuaFnGetWeaponGroupIDFromList(idx - 1) then
				NewExterior_Show_Weapon_SetItemUpSelected(idx)	
			end
		end
		
		g_CurSelWeaponLevel = 1
		for i = 1, 5 do
			local nID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurWeaponSelShowExteriorID, i - 1)
			if nID > 0 then
				g_CurSelWeaponLevel = i
				break
			end			
		end
		
		for i = 1, 5 do
			local nID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurWeaponSelShowExteriorID, i - 1)
			if Exterior:LuaFnIsHaveExterior(1, nID) == 1 then
				g_CurSelWeaponLevel = i
			end
		end
		
		local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurWeaponSelShowExteriorID, g_CurSelWeaponLevel - 1)
		Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("WEAPON", nExteriorWeaponID)
		
		NewExterior_Show_UpdateLeftBtn()		
		NewExterior_Show_Weapon_UpdateObj()		
	else
		local defExteriorID = Exterior:LuaFnGetExteriorInUse(1)
		Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("WEAPON", defExteriorID)
		NewExterior_Show_Weapon()
	end	
	
end

function NewExterior_Show_Weapon_SetItemDownSelected(nIndex)
	
	for i = 1, g_MaxShowBarNum do		
		if g_WeaponShowBarList[i] ~= nil then	
			local ctrlAction = g_WeaponShowBarList[i]:GetSubItem("NewExterior_Show_Weapon_ListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
					g_WeaponShowBarList[i]:GetSubItem("NewExterior_Show_Weapon_ListItemActionTry"):Show()
					local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurWeaponSelShowExteriorID, nIndex - 1)
					if Exterior:LuaFnGetExteriorInUse(1) == nExteriorWeaponID then
						g_WeaponShowBarList[i]:GetSubItem("NewExterior_Show_Weapon_ListItemActionTry"):Hide()
					end
				else
					ctrlAction:SetPushed(0)	
					g_WeaponShowBarList[i]:GetSubItem("NewExterior_Show_Weapon_ListItemActionTry"):Hide()
				end
			end
		end
	end
	
end

function NewExterior_Show_Weapon_SetItemDownUnSelected()
	g_CurWeaponSelShowExteriorID = 0
	for i = 1, g_MaxShowBarNum do		
		if g_WeaponShowBarList[i] ~= nil then	
			local ctrlAction = g_WeaponShowBarList[i]:GetSubItem("NewExterior_Show_Weapon_ListItemAction")
			if ctrlAction ~= nil then
				ctrlAction:SetPushed(0)	
				g_WeaponShowBarList[i]:GetSubItem("NewExterior_Show_Weapon_ListItemActionTry"):Hide()
			end
		end
	end
end

-- 增加预览
function NewExterior_Show_Weapon_ItemAddClicked(nIndex)

	local nGroupID 	= Exterior:LuaFnGetWeaponGroupIDFromList(nIndex - 1)	
	
	Exterior:LuaFnSetExteriorYiRongGeData(g_NewExterior_Show_WeaponPage, g_NewExterior_Show_Op_Update, nGroupID)	
	
	NewExterior_Show_Weapon_ItemClicked( nGroupID )
	
end

-- 移除预览
function NewExterior_Show_Weapon_ItemRemoveClicked(nIndex)

	local tabInfo = g_PlayerWeaponShowInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		return
	end
	
	Exterior:LuaFnSetExteriorYiRongGeData(g_NewExterior_Show_WeaponPage, g_NewExterior_Show_Op_Remove, tabInfo.nExteriorID)	
	
	NewExterior_Show_Weapon_ItemClicked( tabInfo.nExteriorID )
	
end

function NewExterior_Show_Weapon_ItemClicked( nGroupID )
		
	g_CurSelWeaponLevel = 1
	for i = 1, 5 do
		local nID = Exterior:LuaFnGetWeaponIDFromGroup(nGroupID, i - 1)
		if nID > 0 then
			g_CurSelWeaponLevel = i
			break
		end			
	end
		
	for i = 1, 5 do
		local nID = Exterior:LuaFnGetWeaponIDFromGroup(nGroupID, i - 1)
		if Exterior:LuaFnIsHaveExterior(1, nID) == 1 then
			g_CurSelWeaponLevel = i
		end
	end
		
	local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(nGroupID, g_CurSelWeaponLevel - 1)
	--Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("WEAPON", nExteriorWeaponID)
	
end

function NewExterior_Show_Ride()
	
	g_Distance = g_Distance_Ori
	g_NeedChangeScrollSize = 1
		
	NewExterior_Show_Dress_FenYe:Hide()
	NewExterior_Show_Dress_Active:Hide()
	
	NewExterior_Show_Weapon_FenYe:Hide()
	NewExterior_Show_Weapon_Active:Hide()
	
	NewExterior_Show_Ride_Active:Show()
	NewExterior_Show_Ride_FenYe:Show()
	NewExterior_Show_Ride_InitList()
	
	NewExterior_Show_CleanUp()
	
	Exterior:LuaFnInitCurExteriorYiRongGeSet()
	
	NewExterior_Show_Ride_FakeObject:AttachWindowEx("Exterior_Player")		
	g_NewExterior_Show_CurPage = g_NewExterior_Show_RidePage
	
	g_CurRideSelExteriorID = 0
	g_CurRideSelShowExteriorID = 0
	
	--坐骑
	local cacheExteriorID = Exterior:LuaFnGetCurExteriorYiRongGeSetInfo("RIDE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then
		g_TargetRideExteriorID = cacheExteriorID
		g_CurRideSelExteriorID = cacheExteriorID
		
		if Exterior:LuaFnCheckInExteriorYiRongGe(g_NewExterior_Show_RidePage, cacheExteriorID) ~= -1 then			
			g_CurRideSelShowExteriorID = cacheExteriorID
		end
	end
	
	--左侧
	NewExterior_Show_UpdateLeftBtn()
			
	--列表 排序
	NewExterior_Show_Ride_UpdateList()
		
	--模型
	NewExterior_Show_Ride_UpdateObj()
	
end

--模型 —— 坐骑
function NewExterior_Show_Ride_UpdateObj()
		
	local cacheExteriorID = Exterior:LuaFnGetCurExteriorYiRongGeSetInfo("RIDE")
	if cacheExteriorID ~= nil and cacheExteriorID > 0 then	
		local nMountId = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "MountId")	
		
		Exterior:LuaFnUpdateExteriorYiRongGeData(g_NewExterior_Show_RidePage)		
		Exterior:LuaFnUpdateExteriorAvatarMount(nMountId)
		
		local fHeight, fDistance, fPitch = NewExterior_Show_Ride_FakeObject:GetCameraEx()
		fHeight, fDistance = Exterior:LuaFnGetExteriorRideCameraParam(nMountId, 0)
		NewExterior_Show_Ride_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)
	else			
		Exterior:LuaFnUpdateExteriorYiRongGeData(g_NewExterior_Show_RidePage)
		
		NewExterior_Show_UpdateCamera(g_NewExterior_Show_RidePage)		
	end
	
end

--坐骑
function NewExterior_Show_Ride_InitList()
	
	if g_InitRideList == 0 then	
	
		g_MaxRideBarNum = Exterior:LuaFnGetExteriorMaxCount(g_NewExterior_ExteriorTypeRide)		
		for i = 1, g_MaxRideBarNum do
			local bar = NewExterior_Show_Ride_SuperList:AddChild("NewExterior_Show_Ride_SuperListItem")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemAction"):SetEvent("MouseLButtonDown", string.format("NewExterior_Show_Ride_ItemUpClicked(%d)", i))
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemAction"):SetProperty("DraggingEnabled", "False")
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemAction"):SetProperty("Empty", "False")
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemAction"):SetProperty("UseDefaultTooltip", "True")
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionAdd"):SetEvent("Clicked", string.format("NewExterior_Show_Ride_ItemAddClicked(%d)", i))
			
			g_RideBarList[i] = bar	
		end
		
		for i = 1, g_MaxShowBarNum do
			local showbar = NewExterior_Show_Ride_List:AddChild("NewExterior_Show_Ride_ListItem")
			showbar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			
			showbar:GetSubItem("NewExterior_Show_Ride_ListItemAction"):SetEvent("MouseLButtonDown", string.format("NewExterior_Show_Ride_ItemDownClicked(%d)", i))
			showbar:GetSubItem("NewExterior_Show_Ride_ListItemAction"):SetEvent("MouseRClick", string.format("NewExterior_Show_Ride_ItemRemoveClicked(%d)", i))
			showbar:GetSubItem("NewExterior_Show_Ride_ListItemAction"):SetProperty("DraggingEnabled", "False")
			showbar:GetSubItem("NewExterior_Show_Ride_ListItemAction"):SetProperty("Empty", "False")
			showbar:GetSubItem("NewExterior_Show_Ride_ListItemAction"):SetProperty("UseDefaultTooltip", "True")
			showbar:GetSubItem("NewExterior_Show_Ride_ListItemActionRemove"):SetEvent("Clicked", string.format("NewExterior_Show_Ride_ItemRemoveClicked(%d)", i))
			
			showbar:GetSubItem("NewExterior_Show_Ride_ListItemActionRemove"):Hide()
			showbar:GetSubItem("NewExterior_Show_Ride_ListItemActionTime"):Hide()
			showbar:GetSubItem("NewExterior_Show_Ride_ListItemActionTry"):Hide()
			showbar:GetSubItem("NewExterior_Show_Ride_ListItemActionDef"):Hide()
			showbar:GetSubItem("NewExterior_Show_Ride_ListItemActionLuxury"):Hide()
			
			g_RideShowBarList[i] = showbar	
			table.insert(g_PlayerRideShowInfoList, {})
		end
		
		g_InitRideList = 1
	end
	
end

--坐骑 列表
function NewExterior_Show_Ride_UpdateList()
	-- 初始化数据
	Exterior:LuaFnInitExteriorList(g_NewExterior_ExteriorTypeRide)
	
	-- 图鉴中坐骑数量
	local count = Exterior:LuaFnGetExteriorListCount(g_NewExterior_ExteriorTypeRide, 0)
	
	-- 填充上面的数据	
	for i = 1, g_MaxRideBarNum do	
		NewExterior_Show_Ride_SetItemUp(i, count)
	end
	
	-- 填充下面的数据
	NewExterior_Show_Ride_UpdateDownList()
	
	if g_NeedChangeScrollSize == 1 then
		NewExterior_Show_Ride_SuperList:RefreshLayout()
		g_NeedChangeScrollSize = 0
	end
	
	if g_TargetRideExteriorIndex ~= 0 then
	--	NewExterior_Show_Ride_SuperList:SetScrollPosition4Index(g_TargetRideExteriorIndex - 1)
		g_TargetRideExteriorID = 0
		g_TargetRideExteriorIndex = 0
	else
	--	NewExterior_Show_Ride_SuperList:SetScrollPosition4Index(0)
	end

end

--坐骑 列表
function NewExterior_Show_Ride_UpdateDownList()

	for i = 1, g_MaxShowBarNum do
		if g_RideShowBarList[i] ~= nil then
			local ctrlAction = g_RideShowBarList[i]:GetSubItem("NewExterior_Show_Ride_ListItemAction")			
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
				ctrlAction:SetPushed(0)
			end
			g_RideShowBarList[i]:GetSubItem("NewExterior_Show_Ride_ListItemActionRemove"):Hide()
			g_RideShowBarList[i]:GetSubItem("NewExterior_Show_Ride_ListItemActionTime"):Hide()
			g_RideShowBarList[i]:GetSubItem("NewExterior_Show_Ride_ListItemActionTry"):Hide()
			g_RideShowBarList[i]:GetSubItem("NewExterior_Show_Ride_ListItemActionDef"):Hide()
			g_RideShowBarList[i]:GetSubItem("NewExterior_Show_Ride_ListItemActionLuxury"):Hide()
		end
	end
		
	-- 填充下面的数据	
	local rideIdx = 1
	for i = 1, g_MaxShowBarNum do
		local nExteriorID = Exterior:LuaFnGetExteriorYiRongGeData(g_NewExterior_Show_RidePage, i-1)
		if nExteriorID > 0 and Exterior:LuaFnIsHaveExterior(g_NewExterior_ExteriorTypeRide, nExteriorID) == 1 then
			NewExterior_Show_Ride_SetItemDown(nExteriorID, rideIdx)
			rideIdx = rideIdx + 1
		else
			g_PlayerRideShowInfoList[i].nExteriorID = -1
		end
	end
	
end

function NewExterior_Show_Ride_SetItemUp(index, max_count)
	
	if g_RideBarList[index] == nil then
		return
	end
	
	if index > max_count then
		g_RideBarList[index]:Hide()
		return
	end
	
	local bar = g_RideBarList[index]
	bar:Show()
	
	local nMyMenpai = Player:GetData("MEMPAI")
	local nExteriorID 	= Exterior:LuaFnGetExteriorIDFromList(g_NewExterior_ExteriorTypeRide, index - 1)
	local strIcon 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Icon")
	local strName 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Name")
	local nQuality 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Quality")
	local strImage = GetIconFullName(strIcon)
	local nLuxury 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Luxury")
	local nMenpai 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Menpai")
	
	local ctrlAction = bar:GetSubItem("NewExterior_Show_Ride_SuperListItemAction")
	if ctrlAction ~= nil then	
		ctrlAction:SetProperty("NormalImage", strImage)
		ctrlAction:SetProperty("HoverImage", strImage)
		
		local strTemp = Exterior:LuaFnGetRideToolTip(nExteriorID)
		ctrlAction:SetToolTip(strTemp)
		
		if g_CurRideSelExteriorID == nExteriorID then
			ctrlAction:SetPushed(1)
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionTry"):Show()
			if Exterior:LuaFnGetExteriorInUse(g_NewExterior_ExteriorTypeRide) == nExteriorID then
				bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionTry"):Hide()
			end
		else
			ctrlAction:SetPushed(0)
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionTry"):Hide()
		end			

		if g_TargetRideExteriorID == nExteriorID then
		--	g_TargetRideExteriorIndex = index
		end
	end
	
	--非本门派蒙红 
	if nMyMenpai == nMenpai or nMenpai == -1 then			
		bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionMark"):Hide()
	else
		bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionMark"):Show()
	end	
	
	--加减号
	bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionShow"):Hide()
	bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionAdd"):Hide()
	if Exterior:LuaFnIsHaveExterior(g_NewExterior_ExteriorTypeRide, nExteriorID) == 1 then
		if Exterior:LuaFnCheckInExteriorYiRongGe(g_NewExterior_Show_RidePage, nExteriorID) ~= -1 then	
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionShow"):Show()
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionShow"):SetToolTip("#{CKWG_220509_41}")
		else
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionAdd"):Show()
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionAdd"):SetToolTip("#{CKWG_220509_10}")
		end
	end

	--限时标志
	if Exterior:LuaFnIsHaveExterior(g_NewExterior_ExteriorTypeRide, nExteriorID) == 1 then
		bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionLock"):Hide()
		local nLeftTime = Exterior:LuaFnGetExteriorLeftTime(g_NewExterior_ExteriorTypeRide, nExteriorID)
		if nLeftTime and nLeftTime < 0 then
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionTime"):Hide()
		elseif nLeftTime and nLeftTime == 0 then
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionTime"):Show()
		elseif nLeftTime and nLeftTime > 0 then
			bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionTime"):Show()
		end
	else
		bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionTime"):Hide()
		bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionLock"):Show()
	end	

	--使用中
	if Exterior:LuaFnGetExteriorInUse(g_NewExterior_ExteriorTypeRide) == nExteriorID then
		bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionDef"):Show()
	else
		bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionDef"):Hide()
	end
	
	--奢侈品
	if nLuxury == 1 then
		bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionLuxury"):Show()
	else
		bar:GetSubItem("NewExterior_Show_Ride_SuperListItemActionLuxury"):Hide()
	end
	
end

function NewExterior_Show_Ride_SetItemDown(nExteriorID, index)
	
	if g_RideShowBarList[index] == nil then
		return
	end
	
	if index > g_MaxShowBarNum then
		return
	end	
	
	local bar = g_RideShowBarList[index]
	bar:Show()
	
	g_PlayerRideShowInfoList[index].nExteriorID = nExteriorID
	
	local strIcon 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Icon")
	local strName 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Name")
	local nQuality 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Quality")
	local strImage	= GetIconFullName(strIcon)
	local nLuxury 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Luxury")
	local nMenpai 	= Exterior:LuaFnGetExteriorRideInfo(nExteriorID,"Menpai")
	
	local ctrlAction = bar:GetSubItem("NewExterior_Show_Ride_ListItemAction")
	if ctrlAction ~= nil then	
	
		ctrlAction:SetProperty("NormalImage", strImage)
		ctrlAction:SetProperty("HoverImage", strImage)
		
		local strTemp = Exterior:LuaFnGetRideToolTip(nExteriorID)
		ctrlAction:SetToolTip(strTemp)
		
		if g_CurRideSelShowExteriorID == nExteriorID then
			ctrlAction:SetPushed(1)
			bar:GetSubItem("NewExterior_Show_Ride_ListItemActionTry"):Show()
			if Exterior:LuaFnGetExteriorInUse(g_NewExterior_ExteriorTypeRide) == nExteriorID then
				bar:GetSubItem("NewExterior_Show_Ride_ListItemActionTry"):Hide()
			end
		else
			ctrlAction:SetPushed(0)
			bar:GetSubItem("NewExterior_Show_Ride_ListItemActionTry"):Hide()
		end	
	end
		
	--移除控件
	bar:GetSubItem("NewExterior_Show_Ride_ListItemActionRemove"):Show()
	bar:GetSubItem("NewExterior_Show_Ride_ListItemActionRemove"):SetToolTip("#{CKWG_220509_11}")

	--限时标志
	local nLeftTime = Exterior:LuaFnGetExteriorLeftTime(g_NewExterior_ExteriorTypeRide, nExteriorID)
	if nLeftTime and nLeftTime < 0 then
		bar:GetSubItem("NewExterior_Show_Ride_ListItemActionTime"):Hide()
	elseif nLeftTime and nLeftTime == 0 then
		bar:GetSubItem("NewExterior_Show_Ride_ListItemActionTime"):Show()
	elseif nLeftTime and nLeftTime > 0 then
		bar:GetSubItem("NewExterior_Show_Ride_ListItemActionTime"):Show()
	end

	--使用中
	if Exterior:LuaFnGetExteriorInUse(g_NewExterior_ExteriorTypeRide) == nExteriorID then
		bar:GetSubItem("NewExterior_Show_Ride_ListItemActionDef"):Show()
	else
		bar:GetSubItem("NewExterior_Show_Ride_ListItemActionDef"):Hide()
	end
	
	--奢侈品
	if nLuxury == 1 then
		bar:GetSubItem("NewExterior_Show_Ride_ListItemActionLuxury"):Show()
	else
		bar:GetSubItem("NewExterior_Show_Ride_ListItemActionLuxury"):Hide()
	end
	
end

function NewExterior_Show_Ride_ItemUpClicked(nIndex)

	local nExteriorID = Exterior:LuaFnGetExteriorIDFromList(g_NewExterior_ExteriorTypeRide, nIndex - 1)		
	if g_CurRideSelExteriorID ~= nExteriorID then
		g_CurRideSelExteriorID = nExteriorID		
		Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("RIDE", g_CurRideSelExteriorID)		
		NewExterior_Show_Ride_SetItemUpSelected(nIndex)	
		
		local nShowIdx = Exterior:LuaFnCheckInExteriorYiRongGe(g_NewExterior_Show_RidePage, g_CurRideSelExteriorID) + 1
		if nShowIdx > 0 and nShowIdx <= g_MaxShowBarNum then			
			g_CurRideSelShowExteriorID = nExteriorID	
			NewExterior_Show_Ride_SetItemDownSelected(nShowIdx)	
		else
			NewExterior_Show_Ride_SetItemDownUnSelected()
		end		
		
		NewExterior_Show_Ride_UpdateObj()	
		NewExterior_Show_UpdateLeftBtn()
	else
		local defExteriorID = Exterior:LuaFnGetExteriorInUse(g_NewExterior_ExteriorTypeRide)
		Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("RIDE", defExteriorID)
		NewExterior_Show_Ride()
	end	
end

function NewExterior_Show_Ride_SetItemUpSelected(nIndex)
	for i = 1, g_MaxRideBarNum do		
		if g_RideBarList[i] ~= nil then	
			local ctrlAction = g_RideBarList[i]:GetSubItem("NewExterior_Show_Ride_SuperListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
					g_RideBarList[i]:GetSubItem("NewExterior_Show_Ride_SuperListItemActionTry"):Show()
					if Exterior:LuaFnGetExteriorInUse(g_NewExterior_ExteriorTypeRide) == g_CurRideSelExteriorID then
						g_RideBarList[i]:GetSubItem("NewExterior_Show_Ride_SuperListItemActionTry"):Hide()
					end
				else
					ctrlAction:SetPushed(0)	
					g_RideBarList[i]:GetSubItem("NewExterior_Show_Ride_SuperListItemActionTry"):Hide()
				end
			end
		end
	end
end

function NewExterior_Show_Ride_ItemDownClicked(nIndex)
	
	local tabInfo = g_PlayerRideShowInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		return
	end
	
	local nExteriorID = tabInfo.nExteriorID
	if g_CurRideSelShowExteriorID ~= nExteriorID then
		g_CurRideSelShowExteriorID = nExteriorID		
		g_CurRideSelExteriorID = nExteriorID				
		Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("RIDE", g_CurRideSelShowExteriorID)		
		NewExterior_Show_Ride_SetItemDownSelected(nIndex)	
		
		for idx = 1, g_MaxRideBarNum do	
			if nExteriorID == Exterior:LuaFnGetExteriorIDFromList(g_NewExterior_ExteriorTypeRide, idx - 1) then
				NewExterior_Show_Ride_SetItemUpSelected(idx)	
			end
		end
		
		NewExterior_Show_Ride_UpdateObj()	
		NewExterior_Show_UpdateLeftBtn()
	else
		local defExteriorID = Exterior:LuaFnGetExteriorInUse(g_NewExterior_ExteriorTypeRide)
		Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("RIDE", defExteriorID)
		NewExterior_Show_Ride()
	end	
	
end

function NewExterior_Show_Ride_SetItemDownSelected(nIndex)
	for i = 1, g_MaxShowBarNum do		
		if g_RideShowBarList[i] ~= nil then	
			local ctrlAction = g_RideShowBarList[i]:GetSubItem("NewExterior_Show_Ride_ListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
					g_RideShowBarList[i]:GetSubItem("NewExterior_Show_Ride_ListItemActionTry"):Show()
					if Exterior:LuaFnGetExteriorInUse(g_NewExterior_ExteriorTypeRide) == g_CurRideSelShowExteriorID then
						g_RideShowBarList[i]:GetSubItem("NewExterior_Show_Ride_ListItemActionTry"):Hide()
					end
				else
					ctrlAction:SetPushed(0)	
					g_RideShowBarList[i]:GetSubItem("NewExterior_Show_Ride_ListItemActionTry"):Hide()
				end
			end
		end
	end
end

function NewExterior_Show_Ride_SetItemDownUnSelected()
	g_CurRideSelShowExteriorID = 0
	for i = 1, g_MaxShowBarNum do		
		if g_RideShowBarList[i] ~= nil then	
			local ctrlAction = g_RideShowBarList[i]:GetSubItem("NewExterior_Show_Ride_ListItemAction")
			if ctrlAction ~= nil then
				ctrlAction:SetPushed(0)	
				g_RideShowBarList[i]:GetSubItem("NewExterior_Show_Ride_ListItemActionTry"):Hide()
			end
		end
	end
end

-- 增加预览
function NewExterior_Show_Ride_ItemAddClicked(nIndex)
	
	local nExteriorID = Exterior:LuaFnGetExteriorIDFromList(g_NewExterior_ExteriorTypeRide, nIndex - 1)		
	Exterior:LuaFnSetExteriorYiRongGeData(g_NewExterior_Show_RidePage, g_NewExterior_Show_Op_Update, nExteriorID)	
	
	--Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("RIDE", nExteriorID)	
	
end

-- 移除预览
function NewExterior_Show_Ride_ItemRemoveClicked(nIndex)

	local tabInfo = g_PlayerRideShowInfoList[nIndex]
	if not tabInfo or tabInfo.nExteriorID < 0 then 
		return
	end
	
	Exterior:LuaFnSetExteriorYiRongGeData(g_NewExterior_Show_RidePage, g_NewExterior_Show_Op_Remove, tabInfo.nExteriorID)
		
	--Exterior:LuaFnSetCurExteriorYiRongGeSetInfo("RIDE", tabInfo.nExteriorID)	
end

-- 关闭界面
function NewExterior_Show_CloseUI()
	
	NewExterior_Show_CleanUp()
		
	NewExterior_Show_SavePosition()
	
	this:Hide()
	
end

-- 关闭界面
function NewExterior_Show_CloseClick()	
	
	NewExterior_Show_CloseUI()
	
end

function NewExterior_Show_OnHidden()
	
	NewExterior_Show_CloseUI()
	
end

function NewExterior_Show_CleanUp()
	
	NewExterior_Show_Dress_FakeObject:DetachWindowEx()
	NewExterior_Show_Weapon_FakeObject:DetachWindowEx()
	NewExterior_Show_Ride_FakeObject:DetachWindowEx()

	for i = 1, g_MaxShowBarNum do
		if g_FashionShowBarList[i] ~= nil then
			local ctrlAction = g_FashionShowBarList[i]:GetSubItem("NewExterior_Show_Dress_ListItemAction")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end
		if g_WeaponShowBarList[i] ~= nil then
			local ctrlAction = g_WeaponShowBarList[i]:GetSubItem("NewExterior_Show_Weapon_ListItemAction")			
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
			end
		end
		if g_RideShowBarList[i] ~= nil then
			local ctrlAction = g_RideShowBarList[i]:GetSubItem("NewExterior_Show_Ride_ListItemAction")			
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
			end
		end
	end
	
	for i = 1, g_MaxFashionBarNum do
		if g_FashionBarList[i] then
			local ctrlAction = g_FashionBarList[i]:GetSubItem("NewExterior_Show_Dress_SuperListItemAction")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end
	end
	
	for i = 1, g_MaxWeaponBarNum do
		if g_WeaponBarList[i] then
			local ctrlAction = g_WeaponBarList[i]:GetSubItem("NewExterior_Show_Weapon_SuperListItemAction")			
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
			end
		end
	end
	
	for i = 1, g_MaxRideBarNum do
		if g_RideBarList[i] then
			local ctrlAction = g_RideBarList[i]:GetSubItem("NewExterior_Show_Ride_SuperListItemAction")			
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
			end
		end
	end
	
	NewExterior_Show_CleanUp_LeftButton()
	
end
	
function NewExterior_Show_CleanUp_LeftButton()

	NewExterior_Show_Dress_LeftBtn:SetActionItem(-1)
	
	local ctrl_list = {
		[1] = NewExterior_Show_Weapon_LeftBtn,
		[2] = NewExterior_Show_Ride_LeftBtn,
	}
	
	for i = 1, table.getn(ctrl_list) do
		ctrl_list[i]:SetProperty("Empty", "False")
		ctrl_list[i]:SetProperty("UseDefaultTooltip", "True")
		ctrl_list[i]:SetProperty("NormalImage", "")
		ctrl_list[i]:SetProperty("HoverImage", "")
		ctrl_list[i]:SetToolTip("")
	end
	
	NewExterior_Show_Dress_ActionImg:Hide()
	NewExterior_Show_Weapon_ActionImg:Hide()
	NewExterior_Show_Ride_ActionImg:Hide()	

	NewExterior_Show_Dress_LockImg:Hide()
	NewExterior_Show_Weapon_LockImg:Hide()
	NewExterior_Show_Ride_LockImg:Hide()
	
end

--左转
function NewExterior_Show_FakeObject_TurnLeft(curPage, idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		if curPage == g_NewExterior_Show_WeaponPage then
			NewExterior_Show_Weapon_FakeObject:RotateBeginEx("Exterior_Player", -0.3)
		elseif curPage == g_NewExterior_Show_RidePage then
			NewExterior_Show_Ride_FakeObject:RotateBeginEx("Exterior_Player", -0.3)
		else
			NewExterior_Show_Dress_FakeObject:RotateBeginEx("Exterior_Player", -0.3)
		end
	else
		if curPage == g_NewExterior_Show_WeaponPage then
			NewExterior_Show_Weapon_FakeObject:RotateEndEx()
		elseif curPage == g_NewExterior_Show_RidePage then
			NewExterior_Show_Ride_FakeObject:RotateEndEx()
		else
			NewExterior_Show_Dress_FakeObject:RotateEndEx()
		end
	end
	
end

--右转
function NewExterior_Show_FakeObject_TurnRight(curPage, idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		if curPage == g_NewExterior_Show_WeaponPage then
			NewExterior_Show_Weapon_FakeObject:RotateBeginEx("Exterior_Player", 0.3)
		elseif curPage == g_NewExterior_Show_RidePage then
			NewExterior_Show_Ride_FakeObject:RotateBeginEx("Exterior_Player", 0.3)
		else
			NewExterior_Show_Dress_FakeObject:RotateBeginEx("Exterior_Player", 0.3)
		end
	else
		if curPage == g_NewExterior_Show_WeaponPage then
			NewExterior_Show_Weapon_FakeObject:RotateEndEx()
		elseif curPage == g_NewExterior_Show_RidePage then
			NewExterior_Show_Ride_FakeObject:RotateEndEx()
		else
			NewExterior_Show_Dress_FakeObject:RotateEndEx()
		end
	end
	
end

--缩小
function NewExterior_Show_ZoomOut(curPage)

	if g_Distance == 1 then
		return
	end
	
	g_Distance = g_Distance - 1	

	NewExterior_Show_UpdateCamera(curPage)
	
end

--放大
function NewExterior_Show_ZoomIn(curPage)

	if g_Distance == g_Distance_Max then
		return
	end
	
	g_Distance = g_Distance + 1	
	
	NewExterior_Show_UpdateCamera(curPage)
	
end

function NewExterior_Show_UpdateCamera(curPage)

	local sex = GetMySelfRaceId()
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
	
	if curPage == g_NewExterior_Show_WeaponPage then
	
		local fHeight, fDistance, fPitch = NewExterior_Show_Weapon_FakeObject:GetCameraEx()
		fHeight = cameraInfo[sex][g_Distance].fHeight
		fDistance = cameraInfo[sex][g_Distance].fDistance
		fPitch = cameraInfo[sex][g_Distance].fPitch
		fXOffset = cameraInfo[sex][g_Distance].fXOffset
		NewExterior_Show_Weapon_FakeObject:SetCameraEx(fHeight, fDistance, fPitch, fXOffset)
		
	elseif curPage == g_NewExterior_Show_RidePage then
	
		local fHeight, fDistance, fPitch = NewExterior_Show_Ride_FakeObject:GetCameraEx()
		fHeight = cameraInfo[sex][g_Distance].fHeight
		fDistance = cameraInfo[sex][g_Distance].fDistance
		fPitch = cameraInfo[sex][g_Distance].fPitch
		fXOffset = cameraInfo[sex][g_Distance].fXOffset
		NewExterior_Show_Ride_FakeObject:SetCameraEx(fHeight, fDistance, fPitch, fXOffset)
		
	else
	
		local fHeight, fDistance, fPitch = NewExterior_Show_Dress_FakeObject:GetCameraEx()
		fHeight = cameraInfo[sex][g_Distance].fHeight
		fDistance = cameraInfo[sex][g_Distance].fDistance
		fPitch = cameraInfo[sex][g_Distance].fPitch
		fXOffset = cameraInfo[sex][g_Distance].fXOffset
		NewExterior_Show_Dress_FakeObject:SetCameraEx(fHeight, fDistance, fPitch, fXOffset)
		
	end
	
end

--时装
function NewExterior_Show_OpenFashion()

	NewExterior_Show_SavePosition()
	
	if g_NewExterior_Show_CurPage ~= g_NewExterior_Show_DressPage then
		Exterior:LuaFnAskExteriorYiRongGeInfo(g_NewExterior_Show_DressPage, g_NewExterior_Show_Op_Open)
	end
	
end

--幻武
function NewExterior_Show_OpenWeapon()

	NewExterior_Show_SavePosition()
	
	if g_NewExterior_Show_CurPage ~= g_NewExterior_Show_WeaponPage then
		Exterior:LuaFnAskExteriorYiRongGeInfo(g_NewExterior_Show_WeaponPage, g_NewExterior_Show_Op_Open)
	end
	
end

--坐骑
function NewExterior_Show_OpenRide()

	NewExterior_Show_SavePosition()
	
	if g_NewExterior_Show_CurPage ~= g_NewExterior_Show_RidePage then
		Exterior:LuaFnAskExteriorYiRongGeInfo(g_NewExterior_Show_RidePage, g_NewExterior_Show_Op_Open)
	end
	
end

--图鉴
function NewExterior_Show_OpenExteriorUI()

	NewExterior_Show_SavePosition()
	PushEvent("OPEN_EXTERIOR_FASHION", 1, 0)
	
end

function NewExterior_Show_OpenExterior()
	
	NewExterior_Show_OpenExteriorUI()
	
end

function NewExterior_Show_CloseSameGroupWindow()

	CloseWindow("SelfEquip", true)
	CloseWindow("NewExterior_DressBox", true)
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
end

function NewExterior_Show_SavePosition()

	Variable:SetVariable("ExteriorUnionPos", NewExterior_Show_Frame:GetProperty("UnifiedPosition"), 1)
	
end

function NewExterior_Show_SetPosition()
	
	local nExteriorUnionPos = Variable:GetVariable("ExteriorUnionPos")
	if nExteriorUnionPos ~= nil then
		NewExterior_Show_Frame:SetProperty("UnifiedPosition", nExteriorUnionPos)
	end

end

--!!!reloadscript =NewExterior_Show
