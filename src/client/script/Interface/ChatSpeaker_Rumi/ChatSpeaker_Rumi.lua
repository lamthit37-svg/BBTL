
local LEVEL_LIMIT = 15;			--player level limit
local g_SpeakerType = 0
local g_ChatSpeaker_Rumi_Frame_UnifiedPosition;

function ChatSpeaker_Rumi_PreLoad()
	this:RegisterEvent( "UI_COMMAND" )
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end
	
function ChatSpeaker_Rumi_OnLoad()
	  g_ChatSpeaker_Rumi_Frame_UnifiedPosition=ChatSpeaker_Rumi_Frame:GetProperty("UnifiedPosition");
end

function ChatSpeaker_Rumi_OnEvent(event)
	
	if( event == "UI_COMMAND" ) then
		if( tonumber( arg0 ) == 890982 ) then
			local nType = Get_XParam_INT( 0 )
			if nType == 0 then
				g_SpeakerType = 2
				ChatSpeaker_Rumi_Open(0);
			end
		end
	end
		
	if (event == "ADJEST_UI_POS" ) then
		ChatSpeaker_Rumi_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ChatSpeaker_Rumi_Frame_On_ResetPos()
	end
end
function ChatSpeaker_Rumi_Open(nType)
	this:Hide()
	if nType == 0 then
		ChatSpeaker_Rumi_Text:SetText("#{CYRM_140825_02}")
	end
	local level = Player:GetData("LEVEL");
	if level < LEVEL_LIMIT then
		if nType == 0 then
			PushDebugMessage("您的等级不足15级，不能使用传音入密发言。");
		end
		return;
	end
	ChatSpeaker_Rumi_Edit:SetProperty("DefaultEditBox", "True");
	this:Show();
end

function ChatSpeaker_Rumi_Hide()
	this:Hide()
end

function ChatSpeaker_Rumi_SendMessage()
	local text = ChatSpeaker_Rumi_Edit:GetText();
	if( text == "" ) then
		return;
	end
	Player:SendSpeakerMessage( g_SpeakerType , text );
	ChatSpeaker_Rumi_Hide();
end

function ChatSpeaker_Rumi_GetBtnScreenPosX(btn)
	ChatSpeaker_Rumi_PrepareBtnCtl();
	local barxpos = ChatSpeaker_Rumi_Frame:GetProperty("AbsoluteXPosition");
	local btnxpos = g_ChatBtn[btn]:GetProperty("AbsoluteXPosition");
	
	return barxpos+btnxpos;
end
function ChatSpeaker_Rumi_GetBtnScreenPosY(btn)
	ChatSpeaker_Rumi_PrepareBtnCtl();
	local barxpos = ChatSpeaker_Rumi_Frame:GetProperty("AbsoluteYPosition");
	local btnxpos = ChatSpeaker_Rumi_Frame:GetProperty("AbsoluteHeight");
	return barxpos+btnxpos+2;
end

function ChatSpeaker_Rumi_SelectTextColor()
	Talk:SelectTextColor("select", ChatSpeaker_Rumi_GetBtnScreenPosX("color"),ChatSpeaker_Rumi_GetBtnScreenPosY("color"));
end

function ChatSpeaker_Rumi_SelectFaceMotion()
	Talk:SelectFaceMotion("select", ChatSpeaker_Rumi_GetBtnScreenPosX("face"),ChatSpeaker_Rumi_GetBtnScreenPosY("face"));
end

function ChatSpeaker_Rumi_PrepareBtnCtl()
	g_ChatBtn = {
								color		= ChatSpeaker_Rumi_LetterColor,
								face		= ChatSpeaker_Rumi_Face,

							};
end


function ChatSpeaker_Rumi_Frame_On_ResetPos()
  ChatSpeaker_Rumi_Frame:SetProperty("UnifiedPosition", g_ChatSpeaker_Rumi_Frame_UnifiedPosition);
end