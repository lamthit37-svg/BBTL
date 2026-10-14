
local g_Ctrl = {}
local g_Animate = {}
local g_UpDataTime = {}
local g_TimerCount = {}
local g_UpdataCooldown = 30*1000;
function JBZFMessageBall_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("UPDATA_BROTHERSPIRIT");
	this:RegisterEvent("RESET_ALLUI")
end

function JBZFMessageBall_OnLoad()

	g_Animate[0] = JBZFMessageBall_Button_Action1_Mask;
	g_Animate[1] = JBZFMessageBall_Button_Action2_Mask;
	g_Animate[2] = JBZFMessageBall_Button_Action3_Mask;
	g_Animate[3] = JBZFMessageBall_Button_Action4_Mask;
	g_Animate[4] = JBZFMessageBall_Button_Action5_Mask;
	
	g_Ctrl={g_Animate}
	
	this:Show()
	
	for i = 0,4 do
		g_UpDataTime[i] = 0
		g_TimerCount[i] = 0
	end
end

function JBZFMessageBall_OnEvent(event)

	if (event == "UI_COMMAND") then
		-- this:Show()
	elseif (event == "UPDATA_BROTHERSPIRIT") then
		
		this:Show()
		local index = tonumber(arg0)
		g_Animate[index]:Show()

		--Kill原来的
		g_UpDataTime[index] = g_UpDataTime[index]+1
		KillTimer("JBZFMessageBall_OnTimer("..index..")");
		SetTimer("JBZFMessageBall","JBZFMessageBall_OnTimer("..index..")",g_UpdataCooldown);
		local strName = DataPool:Lua_GetQueryBrotherSpiritInfo(tonumber(index))
		local strtips = ScriptGlobal_Format("#{JBGXW_150526_226}",strName)
		g_Animate[index]:SetToolTip(strtips)
	elseif (event == "RESET_ALLUI") then
		JBZFMessageBall_CleanTimerData(-1)
	end
end

function JBZFMessageBall_OnTimer(nIndex)
		g_Animate[nIndex]:Hide()
		JBZFMessageBall_CleanTimerData(nIndex)
		KillTimer("JBZFMessageBall_OnTimer("..nIndex..")");	
end

function JBZFMessageBall_CleanTimerData(nIndex)
	if nIndex == -1 then
		for i = 0,4 do
			g_UpDataTime[i] = 0
			g_TimerCount[i] = 0
		end
	else
		g_UpDataTime[nIndex] = 0
		g_TimerCount[nIndex] = 0
	
	end
end

function JBZFMessageBall_Clicked(nIndex)	
	g_Animate[nIndex]:Hide()
	JBZFMessageBall_CleanTimerData(nIndex)
	KillTimer("JBZFMessageBall_OnTimer("..nIndex..")");
	DataPool:Lua_SendBrotherRetSpirit(nIndex,1)	
end