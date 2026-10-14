-- !!!reloadscript =Frozen_Dance_Map
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

-- 与GameDefine2.h中的BXJWUHUI_MINIMAP_ICONTYPE一致
local IconType =
{
	INVALID		= -1, -- 无效
	ALL 		=  0, -- 所有 -- 无法使用 x331179_ShowAllIconByType()
	YOUDENG 	=  1, -- 油灯
	JINBI 		=  2, -- 金币
	JINDING 	=  3, -- 金锭
	TRAP 		=  4, -- 陷阱未激活
	TRAP_ACTIVE =  5, -- 陷阱已激活
}

local UIIcons = {
	[IconType.YOUDENG] = {}, -- {[1] = {objId=?, icon=?}, ...}
	[IconType.JINBI] = {},
	[IconType.JINDING] = {},
	[IconType.TRAP] = {},
	[IconType.TRAP_ACTIVE] = {},
}
-- 角色自己的图标
local SelfIcon

-- 窗口大小
local windowX, windowZ
-- 场景大小
local sceneX, sceneZ
-- 相对缩放系数（windowX/sceneX, windowZ/sceneZ)
local relativeFactorX, relativeFactorZ


--预加载函数，可以而且只能在这里注册脚本关心的事件
function Frozen_Dance_Map_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	
	this:RegisterEvent("BXJWUHUI_MINIMAP_ADDICON", true)
	this:RegisterEvent("BXJWUHUI_MINIMAP_REMOVEICON", true)
	this:RegisterEvent("BXJWUHUI_MINIMAP_SHOWICONS", true)
	this:RegisterEvent("BXJWUHUI_MINIMAP_REMOVEICONS", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Frozen_Dance_Map_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= Frozen_Dance_Map_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= Frozen_Dance_Map_Frame:GetProperty("UnifiedYPosition");

	sceneX, sceneZ = GetSceneSize()
	windowX, windowZ = Frozen_Dance_Map_Client:GetWindowSize()
	if sceneX ~= 0 then
		relativeFactorX = windowX / sceneX
	else
		relativeFactorX = 1
	end
	if sceneZ ~= 0 then
		relativeFactorZ = windowZ / sceneZ
	else
		relativeFactorZ = 1
	end
	
	SelfIcon = Frozen_Dance_Map_Player
	table.insert(UIIcons[IconType.YOUDENG], {objId = -1, icon = Frozen_Dance_Map_Light1})
	table.insert(UIIcons[IconType.YOUDENG], {objId = -1, icon = Frozen_Dance_Map_Light2})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small1})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small2})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small3})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small4})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small5})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small6})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small7})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small8})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small9})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small10})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small11})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small12})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small13})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small14})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small15})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small16})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small17})
	table.insert(UIIcons[IconType.JINBI], {objId = -1, icon = Frozen_Dance_Map_Gold_Small18})
	table.insert(UIIcons[IconType.JINDING], {objId = -1, icon = Frozen_Dance_Map_Gold_Big1})
	table.insert(UIIcons[IconType.JINDING], {objId = -1, icon = Frozen_Dance_Map_Gold_Big2})
	table.insert(UIIcons[IconType.JINDING], {objId = -1, icon = Frozen_Dance_Map_Gold_Big3})
	table.insert(UIIcons[IconType.JINDING], {objId = -1, icon = Frozen_Dance_Map_Gold_Big4})
	table.insert(UIIcons[IconType.JINDING], {objId = -1, icon = Frozen_Dance_Map_Gold_Big5})
	table.insert(UIIcons[IconType.JINDING], {objId = -1, icon = Frozen_Dance_Map_Gold_Big6})
	table.insert(UIIcons[IconType.JINDING], {objId = -1, icon = Frozen_Dance_Map_Gold_Big7})
	table.insert(UIIcons[IconType.JINDING], {objId = -1, icon = Frozen_Dance_Map_Gold_Big8})
	table.insert(UIIcons[IconType.JINDING], {objId = -1, icon = Frozen_Dance_Map_Gold_Big9})
	table.insert(UIIcons[IconType.TRAP], {objId = -1, icon = Frozen_Dance_Map_Trap1})
	table.insert(UIIcons[IconType.TRAP], {objId = -1, icon = Frozen_Dance_Map_Trap2})
	table.insert(UIIcons[IconType.TRAP], {objId = -1, icon = Frozen_Dance_Map_Trap3})
	table.insert(UIIcons[IconType.TRAP], {objId = -1, icon = Frozen_Dance_Map_Trap4})
	table.insert(UIIcons[IconType.TRAP], {objId = -1, icon = Frozen_Dance_Map_Trap5})
	table.insert(UIIcons[IconType.TRAP], {objId = -1, icon = Frozen_Dance_Map_Trap6})
	table.insert(UIIcons[IconType.TRAP], {objId = -1, icon = Frozen_Dance_Map_Trap7})
	table.insert(UIIcons[IconType.TRAP], {objId = -1, icon = Frozen_Dance_Map_Trap8})
	table.insert(UIIcons[IconType.TRAP], {objId = -1, icon = Frozen_Dance_Map_Trap9})
	table.insert(UIIcons[IconType.TRAP], {objId = -1, icon = Frozen_Dance_Map_Trap10})
	table.insert(UIIcons[IconType.TRAP], {objId = -1, icon = Frozen_Dance_Map_Trap11})
	table.insert(UIIcons[IconType.TRAP], {objId = -1, icon = Frozen_Dance_Map_Trap12})
	table.insert(UIIcons[IconType.TRAP_ACTIVE], {objId = -1, icon = Frozen_Dance_Map_Trap_Active1})
	table.insert(UIIcons[IconType.TRAP_ACTIVE], {objId = -1, icon = Frozen_Dance_Map_Trap_Active2})
	table.insert(UIIcons[IconType.TRAP_ACTIVE], {objId = -1, icon = Frozen_Dance_Map_Trap_Active3})
	table.insert(UIIcons[IconType.TRAP_ACTIVE], {objId = -1, icon = Frozen_Dance_Map_Trap_Active4})
	table.insert(UIIcons[IconType.TRAP_ACTIVE], {objId = -1, icon = Frozen_Dance_Map_Trap_Active5})
	table.insert(UIIcons[IconType.TRAP_ACTIVE], {objId = -1, icon = Frozen_Dance_Map_Trap_Active6})
	table.insert(UIIcons[IconType.TRAP_ACTIVE], {objId = -1, icon = Frozen_Dance_Map_Trap_Active7})
	table.insert(UIIcons[IconType.TRAP_ACTIVE], {objId = -1, icon = Frozen_Dance_Map_Trap_Active8})
	table.insert(UIIcons[IconType.TRAP_ACTIVE], {objId = -1, icon = Frozen_Dance_Map_Trap_Active9})
	table.insert(UIIcons[IconType.TRAP_ACTIVE], {objId = -1, icon = Frozen_Dance_Map_Trap_Active10})
	table.insert(UIIcons[IconType.TRAP_ACTIVE], {objId = -1, icon = Frozen_Dance_Map_Trap_Active11})
	table.insert(UIIcons[IconType.TRAP_ACTIVE], {objId = -1, icon = Frozen_Dance_Map_Trap_Active12})

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_Dance_Map_ResetPos()
	Frozen_Dance_Map_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	Frozen_Dance_Map_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end

--响应事件的函数，当注册的事件发生时会调用的函数
function Frozen_Dance_Map_OnEvent(event)
	if event == "UI_COMMAND" then
		local cmdId = tonumber(arg0)
		if cmdId == 33117901 then -- 界面：打开 1 关闭 0
			local opType = Get_XParam_INT(0)
			if opType == 1 then
				if this:IsVisible() then
					return
				end
				Frozen_Dance_Map_Show()
			elseif opType == 0 then
				if not this:IsVisible() then
					return
				end
				Frozen_Dance_Map_Hide()
			end
		end	
	elseif event == "BXJWUHUI_MINIMAP_ADDICON" then -- 新增图标(用Type区分)
		local type = tonumber(arg0)
		local objId = tonumber(arg1)
		local x = tonumber(arg2)
		local z = tonumber(arg3)
		Frozen_Dance_Map_AddIcon(type, objId, x, z)
	elseif event == "BXJWUHUI_MINIMAP_REMOVEICON" then -- 删除某类型的图标(用Type区分)
		local type = tonumber(arg0)
		local objId = tonumber(arg1)
		
		if not UIIcons[type] then
			return
		end
		for i = 1, table.getn(UIIcons[type]) do
			if UIIcons[type][i].objId == objId then
				UIIcons[type][i].objId = -1
				UIIcons[type][i].icon:Hide()
				if type == IconType.TRAP then
					local trapActive = tonumber(arg2)
					if trapActive == 1 then -- 需要创建激活的陷阱
						local posProperty = UIIcons[type][i].icon:GetProperty("UnifiedPosition")
						Frozen_Dance_Map_AddIcon_ActiveTrap(objId, posProperty)
					end
				end
				break
			end
		end
	elseif event == "BXJWUHUI_MINIMAP_SHOWICONS" then
		if not this:IsVisible() then
			return
		end
		local type = tonumber(arg0)
		Frozen_Dance_Map_ClearDataByType(type)

		local allTypeData = Lua_BXJWuHuiShowAllIconByType(type)
		for i = 1, table.getn(allTypeData) do
			if allTypeData[i].objId ~= -1 then
				Frozen_Dance_Map_AddIcon(type, allTypeData[i].objId, allTypeData[i].x, allTypeData[i].z)
			end
		end
		
	elseif event == "BXJWUHUI_MINIMAP_REMOVEICONS" then
		if not this:IsVisible() then
			return
		end
		local type = tonumber(arg0)
		if not UIIcons[type] then
			return
		end
		for i = 1, table.getn(UIIcons[type]) do
			UIIcons[type][i].objId = -1
			UIIcons[type][i].icon:Hide()
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		if GetSceneID() == 1045 then
			return
		end
		Frozen_Dance_Map_Hide()
	elseif event == "ADJEST_UI_POS" then
		Frozen_Dance_Map_ResetPos()
	end
end

function Frozen_Dance_Map_AddIcon(type, objId, x, z)
	if not UIIcons[type] then
		return
	end
	for i = 1, table.getn(UIIcons[type]) do
		if UIIcons[type][i].objId == objId then
			return
		end
		if UIIcons[type][i].objId == -1 then
			UIIcons[type][i].objId = objId
			local newX = x * relativeFactorX
			local newZ = z * relativeFactorZ
			local szPosition = string.format("{{-0.50, %s},{-0.50, %s}}", newX, newZ)
			UIIcons[type][i].icon:SetProperty("UnifiedPosition", szPosition)
			UIIcons[type][i].icon:Show()
			return
		end
	end
end

function Frozen_Dance_Map_AddIcon_ActiveTrap(objId, posProperty)
	for i = 1, table.getn(UIIcons[IconType.TRAP_ACTIVE]) do
		if UIIcons[IconType.TRAP_ACTIVE][i].objId == objId then
			return
		end
		if UIIcons[IconType.TRAP_ACTIVE][i].objId == -1 then
			UIIcons[IconType.TRAP_ACTIVE][i].objId = objId
			UIIcons[IconType.TRAP_ACTIVE][i].icon:SetProperty("UnifiedPosition", posProperty)
			UIIcons[IconType.TRAP_ACTIVE][i].icon:Show()
			UIIcons[IconType.TRAP_ACTIVE][i].time = tonumber(DataPool:GetCurrentServerTime())
			return
		end
	end
end

-- function Frozen_Dance_Map_GotoDirectly()
-- 	local coordinatex,coordinatey;
-- 	coordinatex, coordinatey = MiniMap_MapArea:GetMouseScenePos();
-- 	AutoRunToTarget(coordinatex, coordinatey);
-- end

function Frozen_Dance_Map_UpdateMyIcon()
	local x, z, dir = Player:GetPos()
	if not SelfIcon or not relativeFactorX or not x then
		return
	end
	local newX = x * relativeFactorX
	local newZ = z * relativeFactorZ
	local szPosition = string.format("{{-0.50, %s},{-0.50, %s}}", newX, newZ)
	SelfIcon:SetProperty("UnifiedPosition", szPosition)
	
	dir = math.floor(math.mod(dir * (-1) + 180, 360))
	if dir < 0 then
		dir = dir + 360
	end
	local frame = math.floor(dir * 30 / 360)
	local frameStr = ""
	if frame < 10 then
		frameStr = "0" .. frame
	else
		frameStr = tostring(frame)
	end
	SelfIcon:SetProperty("Image", "set:MiniMap_Arrow image:Arrow_000" .. frameStr)
	SelfIcon:Show()
end

function Frozen_Dance_Map_TimerProc()
	Frozen_Dance_Map_UpdateMyIcon()
	local currTime = tonumber(DataPool:GetCurrentServerTime())
	-- 删除到时的已激活陷阱图标
	for k, v in pairs(UIIcons[IconType.TRAP_ACTIVE]) do
		if v.objId ~= -1 then
			if currTime - v.time >= 5 then
				Lua_BXJWuHuiSceneMapClearActiveTrap(v.objId)
				v.objId = -1
				v.icon:Hide()
			end
		end
	end
end

--显示UI
function Frozen_Dance_Map_Show()
	Frozen_Dance_Map_ClearData()
	if UIIcons[IconType.YOUDENG][1].objId ~= -1 then
		UIIcons[IconType.YOUDENG][1].icon:Show()
		UIIcons[IconType.YOUDENG][2].icon:Show()
	end
	this:Show()
	SetTimer("Frozen_Dance_Map", "Frozen_Dance_Map_TimerProc()", 1000)
end

--隐藏UI
function Frozen_Dance_Map_Hide()
	Lua_BXJWuHuiSceneMapClear()
	Frozen_Dance_Map_ClearData()
	KillTimer("Biwuzhaoqin_Tips_TimerProc()")

	this:Hide()
end

--清除数据
function Frozen_Dance_Map_ClearData()
	Frozen_Dance_Map_ClearDataByType(IconType.YOUDENG)
	Frozen_Dance_Map_ClearDataByType(IconType.JINBI)
	Frozen_Dance_Map_ClearDataByType(IconType.JINDING)
	Frozen_Dance_Map_ClearDataByType(IconType.TRAP)
	Frozen_Dance_Map_ClearDataByType(IconType.TRAP_ACTIVE)
end

function Frozen_Dance_Map_ClearDataByType(type)
	if not UIIcons[type] then
		return
	end
	for i = 1, table.getn(UIIcons[type]) do
		UIIcons[type][i].objId = -1
		UIIcons[type][i].icon:Hide()
	end
end