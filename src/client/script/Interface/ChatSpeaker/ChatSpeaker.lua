
local LEVEL_LIMIT = 15;			--player level limit
local g_SpeakerType = 0
local g_ChatSpeaker_Frame_UnifiedPosition;

function ChatSpeaker_PreLoad()
	this:RegisterEvent( "UI_COMMAND" ,true)
	this:RegisterEvent( "SHOW_SPEAKER_INPUTBOX" ,true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end
	
function ChatSpeaker_OnLoad()
	  g_ChatSpeaker_Frame_UnifiedPosition=ChatSpeaker_Frame:GetProperty("UnifiedPosition");
end

function ChatSpeaker_OnEvent(event)
	
	if( event == "UI_COMMAND" ) then
		if( tonumber( arg0 ) == 5422 ) then
			local nType = Get_XParam_INT( 0 )
			if nType == 0 then
				g_SpeakerType = 0
				ChatSpeaker_Open(0);
			else
				g_SpeakerType = 2
				ChatSpeaker_Open(2);	
			end
		end
	end
	if( event == "SHOW_SPEAKER_INPUTBOX" ) then
		if( tonumber( arg0 ) == 0 ) then
			g_SpeakerType = 0
			ChatSpeaker_Open(0);
		end
			
	elseif (event == "ADJEST_UI_POS" ) then
		ChatSpeaker_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ChatSpeaker_Frame_On_ResetPos()
	end
end
function ChatSpeaker_Open(nType)
	this:Hide()
	if nType == 0 then
		ChatSpeaker_Frame_Title:SetText("#{INTERFACE_XML_1021}")
		ChatSpeaker_Text:SetText("#{INTERFACE_XML_982}")
	elseif nType == 2 then
		ChatSpeaker_Frame_Title:SetText("传音入密")
		ChatSpeaker_Text:SetText("#{CYRM_140825_02}")
	else
		ChatSpeaker_Frame_Title:SetText("#{QLCY_101119_08}")
	end
	
	local level = Player:GetData("LEVEL");
	if level < LEVEL_LIMIT then
		if nType == 0 then
			PushDebugMessage("您的等级不足15级，不能使用喇叭发言。");
		elseif nType == 2 then
			PushDebugMessage("您的等级不足15级，不能使用传音入密发言。");
		end
		return;
	end
	ChatSpeaker_Edit:SetProperty("DefaultEditBox", "True");
	this:Show();
end

function ChatSpeaker_Hide()
	this:Hide()
end

function ChatSpeaker_SendMessage()
	local text = ChatSpeaker_Edit:GetText();
	if( text == "" ) then
		return;
	end
	Player:SendSpeakerMessage( g_SpeakerType , text );
	ChatSpeaker_Hide();
end

function ChatSpeaker_GetBtnScreenPosX(btn)
	ChatSpeaker_PrepareBtnCtl();
	local barxpos = ChatSpeaker_Frame:GetProperty("AbsoluteXPosition");
	local btnxpos = g_ChatBtn[btn]:GetProperty("AbsoluteXPosition");
	
	return barxpos+btnxpos;
end
function ChatSpeaker_GetBtnScreenPosY(btn)
	ChatSpeaker_PrepareBtnCtl();
	local barxpos = ChatSpeaker_Frame:GetProperty("AbsoluteYPosition");
	local btnxpos = ChatSpeaker_Frame:GetProperty("AbsoluteHeight");
	return barxpos+btnxpos+2;
end

function ChatSpeaker_SelectTextColor()
	Talk:SelectTextColor("select", ChatSpeaker_GetBtnScreenPosX("color"),ChatSpeaker_GetBtnScreenPosY("color"));
end

function ChatSpeaker_SelectFaceMotion()
	Talk:SelectFaceMotion("select", ChatSpeaker_GetBtnScreenPosX("face"),ChatSpeaker_GetBtnScreenPosY("face"));
end

function ChatSpeaker_PrepareBtnCtl()
	g_ChatBtn = {
								color		= ChatSpeaker_LetterColor,
								face		= ChatSpeaker_Face,

							};
end


function ChatSpeaker_Frame_On_ResetPos()
  ChatSpeaker_Frame:SetProperty("UnifiedPosition", g_ChatSpeaker_Frame_UnifiedPosition);
end