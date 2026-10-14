
local g_Ctrl = {}
local g_Animate = {}
function JBZFMessageBall_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("UPDATA_BROTHERSPIRIT");
end

function JBZFMessageBall_OnLoad()

	g_Animate[0] = JBZFMessageBall_Button_Action1_Mask;
	g_Animate[1] = JBZFMessageBall_Button_Action2_Mask;
	g_Animate[2] = JBZFMessageBall_Button_Action3_Mask;
	g_Animate[3] = JBZFMessageBall_Button_Action4_Mask;
	g_Animate[4] = JBZFMessageBall_Button_Action5_Mask;
	
 g_Ctrl={g_Animate}
 this:Show()
end

function JBZFMessageBall_OnEvent(event)

	if (event == "UI_COMMAND") then
		-- this:Show()
	elseif (event == "UPDATA_BROTHERSPIRIT") then
		PushDebugMessage("aaaaaxxxxxxxxxxxx")
		local index = tonumber(arg0)
		g_Animate[index]:Show()
	
	end
end




function JBZFMessageBall_Clicked(nIndex)	
	PushEvent("BROTHERSPIRIT_CONFIRM",nIndex)
	g_Animate[nIndex]:Hide()
end