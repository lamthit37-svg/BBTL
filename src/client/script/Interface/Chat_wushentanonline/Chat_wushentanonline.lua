--Chat_wushentanonline
--武神坛
local g_bIsShowWuShenTanMsg=0;
local g_MaxWuShenTanMsg=12;
local g_WuShenTanMsgCurIndex=1;
local g_WuShenTanMsgEndIndex=1;
local g_WuShenTanMsg={};

function Chat_wushentanonline_PreLoad()
	this:RegisterEvent("SHOW_WUSHENTAN_CHAMPION_LOGIN",true);
end

function Chat_wushentanonline_OnLoad()
	this:Show()
end

function Chat_wushentanonline_OnEvent(event)
	if (event == "SHOW_WUSHENTAN_CHAMPION_LOGIN") then
		Chat_wushentanonline_InsertWuShenTanLoginMsg( arg0, arg1, arg2 )
	end
end

function Chat_wushentanonline_InsertWuShenTanLoginMsg( szName, szContex, nWorldId )

	local nInsertIndex = g_WuShenTanMsgEndIndex;
	if nInsertIndex >= g_MaxWuShenTanMsg then
		nInsertIndex = 1;
	end
	
	g_WuShenTanMsg[nInsertIndex] = {};	
	g_WuShenTanMsg[nInsertIndex].IsSet = 1;
	g_WuShenTanMsg[nInsertIndex].Contex = szContex;
	g_WuShenTanMsgEndIndex = nInsertIndex + 1;
	
	if g_bIsShowWuShenTanMsg == 0 then
		Chat_wushentanonline_ShowWuShenTanLoginMsg();
		KillTimer("Chat_wushentanonline_ShowWuShenTanLoginMsg()");
		SetTimer("Chat_wushentanonline","Chat_wushentanonline_ShowWuShenTanLoginMsg()", 30000);
	end
end

function Chat_wushentanonline_ShowWuShenTanLoginMsg()
	
	Chat_wushentanonline:Hide();
	
	g_bIsShowWuShenTanMsg = 0;
	local nShowIndex = g_WuShenTanMsgCurIndex
	if nShowIndex >= g_MaxWuShenTanMsg then
		nShowIndex = 1;
	end
	
	--寻找下一个
	for i=1, g_MaxWuShenTanMsg do
		if g_WuShenTanMsg[nShowIndex] ~= nil and g_WuShenTanMsg[nShowIndex].IsSet ~= nil and g_WuShenTanMsg[nShowIndex].IsSet == 1 then
			break
		else
			nShowIndex = nShowIndex + 1
			if nShowIndex >= g_MaxWuShenTanMsg then
				nShowIndex = 1;
			end
		end
	end
	
	
	if g_WuShenTanMsg[nShowIndex] == nil or g_WuShenTanMsg[nShowIndex].IsSet == nil or g_WuShenTanMsg[nShowIndex].IsSet == 0 then
		KillTimer("Chat_wushentanonline_ShowWuShenTanLoginMsg()");
		return
	end
	
	g_bIsShowWuShenTanMsg = 1;
	g_WuShenTanMsgCurIndex = nShowIndex + 1;	
	
	local szCurSpeakerContex = g_WuShenTanMsg[nShowIndex].Contex
	
	g_WuShenTanMsg[nShowIndex].IsSet = 0;	
	g_WuShenTanMsg[nShowIndex].Contex = "";

	Chat_wushentanonline_Text:SetText( tostring(szCurSpeakerContex) );
	Chat_wushentanonline:Show();
		
end
