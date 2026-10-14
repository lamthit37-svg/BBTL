--周年情怀任务领取界面
--!!!reloadscript =Sixteen_anniversary_Letter

local g_Frame_Pos = nil
local g_Level = 30
local g_BeginDay = 0
local g_EndDay = 0

function Sixteen_anniversary_Letter_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
end


function Sixteen_anniversary_Letter_OnLoad()
	g_Frame_Pos = Sixteen_anniversary_Letter_Frame:GetProperty("UnifiedPosition")
end

function Sixteen_anniversary_Letter_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == 99847201 )  then 
		g_BeginDay = Get_XParam_INT(0)
		g_EndDay = Get_XParam_INT(1)

		Sixteen_anniversary_Letter_Open()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Sixteen_anniversary_Letter_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Sixteen_anniversary_Letter_Closed()

	end
end


--=========
-- 重置
--=========
function Sixteen_anniversary_Letter_On_ResetPos()
	Sixteen_anniversary_Letter_Frame:SetProperty("UnifiedPosition", g_Frame_Pos)
end



--=========
-- 关闭
--=========
function Sixteen_anniversary_Letter_Closed()
	this:Hide()
end

--=========
-- 打开
--=========
function Sixteen_anniversary_Letter_Open()
	this:Show()
end


function Sixteen_anniversary_Letter_Goto_Click()
	local curDay = DataPool:GetServerDayTime()
	if curDay < g_BeginDay or curDay > g_EndDay then
		PushDebugMessage("#{QHRW_230317_04}")
		return
	end
	
	local nLevel = Player:GetLevel()
	if nLevel < g_Level then
		PushDebugMessage("#{QHRW_230317_03}")
		return
	end

	AutoRuntoTargetExWithName(160, 158.5, 2, "赵天师")--tNpc.x, tNpc.z, tNpc.sceneId, tNpc.name
	
	Sixteen_anniversary_Letter_Closed()
end


