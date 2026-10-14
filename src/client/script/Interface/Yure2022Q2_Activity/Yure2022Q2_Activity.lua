--版本预热活动


local g_Yure2022Q2_Activity_Frame_UnifiedPosition_Load
local g_UI_Items = {}
local g_MissionGroupNum = 6
local g_UICOMMAND = 99810201
local g_MisGoto = {
	[1] = {{220,171,"名士乔峰"}},
	[2] = {{308,244,"穆小妹"},{207,269 ,"杨小弟"}},
	[3] = {{308,244,"穆小妹"},{207,269 ,"杨小弟"}},
	[4] = {{308,244,"穆小妹"},{207,269 ,"杨小弟"}},
	[5] = {{308,244,"穆小妹"},{207,269 ,"杨小弟"}},
	[6] = {{308,244,"穆小妹"}},
}
local g_Time = {20220721,20220728}

--------------------------
local g_MissionState = {}
local g_CurMis = 0
local g_btnHover = {}


function Yure2022Q2_Activity_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	--this:RegisterEvent("ADJEST_UI_POS",false)

end

function Yure2022Q2_Activity_OnLoad()
	Yure2022Q2_Activity_LoadControl()
	g_Yure2022Q2_Activity_Frame_UnifiedPosition_Load = Yure2022Q2_Activity_Frame:GetProperty("UnifiedPosition")
	for i=1,g_MissionGroupNum do
		g_btnHover[i] = {}
		g_btnHover[i].nomal = g_UI_Items.misInfo[i].btn:GetProperty("NormalImage")
		g_btnHover[i].hover = g_UI_Items.misInfo[i].btn:GetProperty("HoverImage")
	end
end
--=========
-- 装载控件
--=========
function Yure2022Q2_Activity_LoadControl()
	g_UI_Items.misInfo={}
	for i=1,g_MissionGroupNum do
		g_UI_Items.misInfo[i] = 
		{
			btn = _G[string.format( "Yure2022Q2_Activity_Button%d_Btn",i)],
			ok = _G[string.format( "Yure2022Q2_Activity_Button%d_OKImage",i)],
			now = _G[string.format( "Yure2022Q2_Activity_Button%d_NowImage",i)],
			lock = _G[string.format( "Yure2022Q2_Activity_Button%d_LockImage",i)],
		}
	end
	--g_UI_Items.gotoBtn = Yure2022Q2_Activity_Goto
end
--=========
-- Event
--=========
function Yure2022Q2_Activity_OnEvent(event)


	if (event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND )  then 
		local opt = Get_XParam_INT(0)
		if opt == 1 then
			Yure2022Q2_Activity_Open()
		elseif opt == 2 then
			--刷新
			if(IsWindowShow("Yure2022Q2_Activity")) then
				Yure2022Q2_Activity_Open()
			end
		end

	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Yure2022Q2_Activity_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Yure2022Q2_Activity_Close()

	-- elseif event == "ADJEST_UI_POS" then

	-- 	Yure2022Q2_Activity_On_AdjustPos()


	end

end


--=========
-- 重置
--=========
function Yure2022Q2_Activity_On_ResetPos()

	Yure2022Q2_Activity_Frame:SetProperty("UnifiedPosition", g_Yure2022Q2_Activity_Frame_UnifiedPosition_Load)

end



--=========
-- 关闭
--=========
function Yure2022Q2_Activity_Close()
	g_CurMis = 0
	g_MissionState = {}
	this:Hide()
end

--=========
-- 打开
--=========
function Yure2022Q2_Activity_Open()
	g_CurMis = 0
	g_MissionState = {}
	local curMis = 0
	local misUnLockIndex = Get_XParam_INT(1)
	if misUnLockIndex > g_MissionGroupNum then
		misUnLockIndex = g_MissionGroupNum
	end
	for i = 1, g_MissionGroupNum do
		g_MissionState[i] =  Get_XParam_INT(1+i)
	end
	--PushDebugMessage(misUnLockIndex.."||"..g_MissionState[1]..","..g_MissionState[2]..","..g_MissionState[3]..","..g_MissionState[4]..","..g_MissionState[5]..","..g_MissionState[6])
	for i = 1, g_MissionGroupNum do

		if i <= misUnLockIndex then
			g_UI_Items.misInfo[i].now:Hide()
			g_UI_Items.misInfo[i].ok:Hide()
			g_UI_Items.misInfo[i].lock:Hide()
			g_UI_Items.misInfo[i].btn:Show()
			g_UI_Items.misInfo[i].btn:SetProperty("NormalImage",g_btnHover[i].nomal)
			
			--最后一个任务完成了就show ok
			local GroupOkState = math.pow(10,table.getn(g_MisGoto[i])-1) 
			if g_MissionState[i] >= GroupOkState then
				g_UI_Items.misInfo[i].ok:Show()
				g_UI_Items.misInfo[i].btn:SetToolTip("#{BBYRHD_220523_10}")
			elseif curMis == 0 then
				g_UI_Items.misInfo[i].now:Show()
				g_UI_Items.misInfo[i].btn:SetProperty("NormalImage",g_btnHover[i].hover)
				g_UI_Items.misInfo[i].btn:SetToolTip("#{BBYRHD_220523_09}")
				curMis = i
			else
				g_UI_Items.misInfo[i].btn:SetToolTip("#{BBYRHD_220523_192}")
			end
		else
			g_UI_Items.misInfo[i].lock:Show()
			g_UI_Items.misInfo[i].now:Hide()
			g_UI_Items.misInfo[i].ok:Hide()
			g_UI_Items.misInfo[i].btn:Hide()
			g_UI_Items.misInfo[i].lock:SetToolTip(ScriptGlobal_Format("#{BBYRHD_220523_08}","7",tostring(19+i)))
		end
	end

	g_CurMis = curMis


	this:Show()
end





function Yure2022Q2_Activity_GotoClick()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{BBYRHD_220523_12}")
		return
	end
	local curDay = DataPool:GetServerDayTime()
	if curDay < g_Time[1] or curDay > g_Time[2] then
		PushDebugMessage("#{BBYRHD_220523_11}")
		return
	end
	if DataPool:Lua_IsMissionHaveDone(1994) == 1 then
		PushDebugMessage("#{BBYRHD_220523_191}")
		return
	end

	if g_CurMis > 0 and g_CurMis <= g_MissionGroupNum then
		local curMisGroupGotoInfo =g_MisGoto[g_CurMis]
		local curGroupState = g_MissionState[g_CurMis]
		if curGroupState ~= nil then
			for i,info in curMisGroupGotoInfo do
				local curMisState = math.mod(curGroupState,10)
				curGroupState = math.floor(curGroupState/10)
				if curMisState == 0 then
					AutoRuntoTargetExWithName(curMisGroupGotoInfo[i][1], curMisGroupGotoInfo[i][2],0, curMisGroupGotoInfo[i][3])--tNpc.x, tNpc.z, tNpc.sceneId, tNpc.name
					return 
				end
			end
		else
			PushDebugMessage("请重新打开界面")
			return 
		end
	end
	PushDebugMessage("#{BBYRHD_220523_13}")
end

function Yure2022Q2_Activity_HelpClicked()
	-- 借用一下别人的通道
	PushEvent("OPEN_SWEEPPAGE_QUEST", "Yure2022Q2_Activity_Help")
end