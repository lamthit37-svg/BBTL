
local g_InputMood_Frame_UnifiedPosition;
--===============================================
-- OnLoad
--===============================================
function InputMood_PreLoad()
	this:RegisterEvent("MOOD_SET",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function InputMood_OnLoad()
 g_InputMood_Frame_UnifiedPosition=InputMood_Frame:GetProperty("UnifiedPosition");
end

--===============================================
-- OnEvent
--===============================================
function InputMood_OnEvent(event)
	if ( event == "MOOD_SET" ) then
		InputMood_Input:SetText( "" );
		this:Show();
		InputMood_Input:SetProperty("DefaultEditBox", "True");
		InputMood_Input:SetText(DataPool:GetMood());
		InputMood_Input:SetSelected( 0, -1 );
		
	elseif (event == "ADJEST_UI_POS" ) then
		InputMood_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		InputMood_Frame_On_ResetPos()
		
	end
end

--===============================================
-- 确定
--===============================================
function InputMood_EventOK()
	local strMood = InputMood_Input:GetText();
	if( strMood == "" ) then 
		PushDebugMessage("心情不能为空");
		return;
	end
	DataPool:SetMood( strMood );
	this:Hide();
end

--===============================================
-- 取消
--===============================================
function InputMood_EventCancel()
	this:Hide();
end

--===============================================
-- 关闭自动执行
--===============================================
function InputMood_OnHiden()
	InputMood_Input:SetProperty("DefaultEditBox", "False");
end

function InputMood_Frame_On_ResetPos()
  InputMood_Frame:SetProperty("UnifiedPosition", g_InputMood_Frame_UnifiedPosition);
end

function InputMood_ShowMood_Clicked()
	local curSceneID = GetSceneID(); --
	
	if curSceneID == 868 then --zypvp
		return 
	end
	if curSceneID == 1008 then --
		return 
	end
	local strMood = InputMood_Input:GetText();
	if( strMood == "" ) then 
		PushDebugMessage("心情不能为空");
		return;
	end
	DataPool:SetMood( strMood );
	Friend:ViewFeel();
end