local g_ItemInfo = nil
local g_Shengmingxianhe_UnifiedPosition = nil
local g_Index = 0
function Shengmingxianhe_PreLoad()

	this:RegisterEvent("OPEN_SHENGMINGXIANHE");
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function Shengmingxianhe_OnLoad()
	g_Shengmingxianhe_UnifiedPosition = Shengmingxianhe_Frame:GetProperty("UnifiedPosition")

	
	g_ItemInfo = { [1] = {3,800,15,3,800,15},
							 [2] = {2,600,12,2,600,12},
							 [3] = {1,400,10,1,400,10},
							 [4] = {1,320,8,1,320,8},
							 [5] = {1,280,6,1,280,6},
							 [6] = {1,240,5,1,240,5},
							 [7] = {1,200,4,1,200,4},
							 [8] = {1,160,3,1,160,3},
							 [9] = {1,120,2,1,120,2},
							 [10]={1,100,1,1,100,1},
							 }
end

--===============================================
-- OnEvent()
--===============================================
function Shengmingxianhe_OnEvent(event)
	if (event == "OPEN_SHENGMINGXIANHE") then
		
		local index = tonumber(arg0)
		local strinfo = ScriptGlobal_Format("#{MDJH_140303_09}",g_ItemInfo[index][1],g_ItemInfo[index][2],g_ItemInfo[index][3],g_ItemInfo[index][4],g_ItemInfo[index][5],g_ItemInfo[index][6])
		Shengmingxianhe_ItemInfo:SetText(strinfo)
		g_Index = index
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		Shengmingxianhe_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		Shengmingxianhe_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function Shengmingxianhe_ResetPos()
		Shengmingxianhe_Frame:SetProperty("UnifiedPosition",g_Shengmingxianhe_UnifiedPosition)
end

function Shengmingxianhe_Jiangli1_Button()
	PushEvent("SHENGMINGXIANHE_CONFIRM",tostring(0), tostring(g_ItemInfo[g_Index][1]),tostring(g_ItemInfo[g_Index][2]),tostring(g_ItemInfo[g_Index][3]))
end


function Shengmingxianhe_Jiangli2_Button()
	PushEvent("SHENGMINGXIANHE_CONFIRM",tostring(1),tostring(g_ItemInfo[g_Index][1]),tostring(g_ItemInfo[g_Index][2]),tostring(g_ItemInfo[g_Index][3]))
end

function Shengmingxianhe_Close_Button()
	this:Hide()
end