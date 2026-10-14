local g_unifiedposistion
local g_dir_type = {
	player	= {type=0, x=0, z=0,h=0,p=0,},			-- 主视角
	east	= {type=1, x=148, z=148, h=1050,p=-51,},	-- 东
	north	= {type=2, x=148, z=108, h=1050, p=-40,},		-- 北
	west	= {type=3, x=108, z=108, h=1050, p=-43,},		-- 西
	south	= {type=4, x=108, z=148, h=1050, p=-51,},		-- 南
	center	= {type=5, x=128, z=128, h=2100, p=-87,},		-- 中心
}
function ZBS_Camera_PreLoad()

	this:RegisterEvent("ZBS_GMVISABLE_SHOW")
	this:RegisterEvent("ON_SCENE_TRANS")
	this:RegisterEvent("ZBS_GMVISABLE_TINYSHOW",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function ZBS_Camera_OnLoad()
	g_unifiedposistion	= ZBS_Camera_Frame:GetProperty("UnifiedPosition")
end

function ZBS_Camera_OnEvent(event)

	if( event == "ZBS_GMVISABLE_SHOW" ) then
		ZBS_Camera_OnShow()
	elseif( event == "ADJEST_UI_POS" ) then
		ZBS_Camera_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		ZBS_Camera_ResetPos()
	elseif( event == "ON_SCENE_TRANS" ) then
		ZBS_Camera_Close()
	elseif( event == "ZBS_GMVISABLE_TINYSHOW" ) then
		this:Hide()
	end
end


function ZBS_Camera_OnShow()
	PushEvent("OPEN_NORMAL_WATCH")
	PushEvent("OPEN_MINI_WATCH")

	this:Show()
end

function ZBS_Camera_Close()
	local bRet = ZBS:CancelGMWatch()
	if bRet > 0 then
		PushEvent("OPEN_MINIMAP")
	end
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ZBS_Camera_ResetPos()
	ZBS_Camera_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

--================================================
--东
function ZBS_Camera_East_Clicked()
	local data = g_dir_type.east
	if data ~= nil then
		ZBS:SetPlayerWatchPosDirection(data.type,data.x,data.z,data.h,data.p)
	end
end

--西
function ZBS_Camera_West_Clicked()
	local data = g_dir_type.west
	if data ~= nil then
		ZBS:SetPlayerWatchPosDirection(data.type,data.x,data.z,data.h,data.p)
	end
end

--南
function ZBS_Camera_South_Clicked()
	local data = g_dir_type.south
	if data ~= nil then
		ZBS:SetPlayerWatchPosDirection(data.type,data.x,data.z,data.h,data.p)
	end
end

--北
function ZBS_Camera_North_Clicked()
	local data = g_dir_type.north
	if data ~= nil then
		ZBS:SetPlayerWatchPosDirection(data.type,data.x,data.z,data.h,data.p)
	end
end

--中心
function ZBS_Camera_Center_Clicked()
	local data = g_dir_type.center
	if data ~= nil then
		ZBS:SetPlayerWatchPosDirection(data.type,data.x,data.z,data.h,data.p)
	end
end

--玩家视角
function ZBS_Camera_Player_Clicked()
	local data = g_dir_type.player
	if data ~= nil then
		ZBS:SetPlayerWatchPosDirection(data.type,data.x,data.z)
	end
end
--================================================
function ZBS_Camera_OnShowTinyUI()
	this:Hide()
	PushEvent( "ZBS_GMVISABLE_TINYSHOW" )
end
