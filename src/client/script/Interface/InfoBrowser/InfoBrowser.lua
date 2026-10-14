local nCurrentMail = 0;
local nPlayerMail = 0;
local g_InfoBrowser_Frame_UnifiedXPosition;
local g_InfoBrowser_Frame_UnifiedYPosition;
local g_IsSystemMail = false
local g_IsGSMail = 0 
--===============================================
-- OnLoad()
--===============================================
function InfoBrowser_PreLoad()
	this:RegisterEvent("OPEN_EMAIL",true);
	this:RegisterEvent("UPDATE_EMAIL",true);
	this:RegisterEvent("HAVE_MAIL",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function InfoBrowser_OnLoad()
	Variable:SetVariable( "IsInfoBrowerShow","False", 1 );
	g_InfoBrowser_Frame_UnifiedXPosition	= InfoBrowser_Frame:GetProperty("UnifiedXPosition");
	g_InfoBrowser_Frame_UnifiedYPosition	= InfoBrowser_Frame:GetProperty("UnifiedYPosition");
	
end

--===============================================
-- OnEvent()
--===============================================
function InfoBrowser_OnEvent( event )
	--显示系统邮件的时候必定会关闭本界面
	if( event == "OPEN_EMAIL" ) then
		SystemInfo_NextPage();
		
	elseif( event == "UPDATE_EMAIL" ) then

		nCurrentMail = tonumber( arg0 );		
		nPlayerMail = tonumber( arg1 );
		-- [ QUFEI 2007-09-15 17:05 UPDATE BugID #25107 ]
		-- 收到无效邮件时关闭邮件读取窗口
		if nPlayerMail == 5 then
			g_IsGSMail = 1
		else
			g_IsGSMail = 0
		end				
		if( nCurrentMail < 100000 ) then
			Update_Player_Mail();
		elseif( nCurrentMail >= 100000 and nCurrentMail < 300000 ) then
			nCurrentMail = nCurrentMail - 100000;
			InfoBrowser_Close()			
		else
			nCurrentMail = nCurrentMail - 300000;
			Update_System_Mail();
		end
		
	elseif( event == "HAVE_MAIL" ) then
		if( this:IsVisible() ) then
			InfoBrowser_Update();
		end
	elseif (event == "ADJEST_UI_POS" ) then
		InfoBrowser_Frame_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		InfoBrowser_Frame_ResetPos()
	end

end
function Update_System_Mail()

	SystemInfo_Show();
	SystemInfo_Update();
end

function Update_Player_Mail()

	InfoBrowser_Show();
	InfoBrowser_Update();
end

function InfoBrower_DisableButton()
	InfoBrowser_Next:Disable();
	InfoBrowser_ReadAll:Disable()
	InfoBrowser_AddFriend:Disable();
	InfoBrowser_ExamineData:Disable();
	InfoBrowser_AddFriend:Disable();
	InfoBrowser_Respondence:Disable();
	InfoBrowser_ExamineData:Disable();
	-- InfoBrowser_Next:Disable();
	InfoBrowser_PlayerHead:SetProperty("Image", "");
	InfoBrowser_PlayerHead_Frame:SetProperty("Image", "")
	InfoBrowser_PlayerHead_Animate:SetProperty("Animate", "")

end
--===============================================
-- UpdateFrame()
--===============================================
function InfoBrowser_Update()
	if g_IsGSMail == 0 then
		InfoBrower_UpdateButton();
		Variable:SetVariable( "IsInfoBrowerShow","True", 1 );
		local sender  = DataPool:GetMail( nCurrentMail,"SENDER" );
		local context = DataPool:GetMail( nCurrentMail,"CONTEX" );
		local time	  = DataPool:GetMail( nCurrentMail,"TIME" );
	
		
		InfoBrowser_From:SetText( "名字:"..sender.."#b#c0000FF#effffff(玩家)" );
		InfoBrowser_Time:SetText( "时间:"..time );
		InfoBrowser_Context:SetText( context );
		local strFaceImage = DataPool:GetMail( nCurrentMail,"PORTRAIT" );
	
		InfoBrowser_PlayerHead:SetProperty("Image", tostring(strFaceImage));
		
		local nHeadFrameType = DataPool:GetMail(nCurrentMail, "HEADFRAMETYPE")
		if nHeadFrameType == 1 then
			InfoBrowser_PlayerHead_Frame:SetProperty("Image", "")
			InfoBrowser_PlayerHead_Frame:Hide()

			InfoBrowser_PlayerHead_Animate:Show()
			local strHeadFrameAnimate = DataPool:GetMail(nCurrentMail, "HEADFRAMEANIMATE")
			InfoBrowser_PlayerHead_Animate:SetProperty("Animate", tostring(strHeadFrameAnimate))		
		else
			InfoBrowser_PlayerHead_Animate:SetProperty("Animate", "")
			InfoBrowser_PlayerHead_Animate:Hide()
				
			InfoBrowser_PlayerHead_Frame:Show()				
			local strHeadFrameImage = DataPool:GetMail(nCurrentMail, "HEADFRAME")
			local IconFile = GetIconFullName(strHeadFrameImage)
			InfoBrowser_PlayerHead_Frame:SetProperty("Image", IconFile)
		end

		if nPlayerMail == 0 then
			local nchannel,nindex;
			nchannel, nindex  = DataPool:GetFriendByName( sender );
			if( tonumber( nchannel ) == -1 ) then
				DataPool:AddFriend( 13, sender );
			end		
		end
	elseif g_IsGSMail == 1 then
		InfoBrower_UpdateButton();
		Variable:SetVariable( "IsInfoBrowerShow","True", 1 );
		local sender  = DataPool:GetMail( nCurrentMail,"SENDER" );
		local context = DataPool:GetMail( nCurrentMail,"CONTEX" );
		local time	  = DataPool:GetMail( nCurrentMail,"TIME" );
	
		InfoBrowser_Fromwanjia:SetText("#b#cFF0000#effffffGM留言")
		InfoBrowser_From:SetText( "名字:"..sender);
		InfoBrowser_Time:SetText( "时间:"..time );
		InfoBrowser_Context:SetText( context );
		local strFaceImage = DataPool:GetMail( nCurrentMail,"PORTRAIT" );
	
		InfoBrowser_PlayerHead:SetProperty("Image", tostring(strFaceImage));
		InfoBrowser_Report:Hide()
		InfoBrowser_ExamineData:Hide()
		InfoBrowser_AddFriend:Hide()
		InfoBrowser_Respondence:Hide()
		InfoBrowser_HistoryInfo:Hide()
		
		if nPlayerMail == 0 then
			local nchannel,nindex;
			nchannel, nindex  = DataPool:GetFriendByName( sender );
			if( tonumber( nchannel ) == -1 ) then
				DataPool:AddFriend( 13, sender );
			end		
		end		
	end
	
end

function InfoBrower_UpdateButton()
	InfoBrower_DisableButton();
	if( DataPool:GetMailNumber() == 0 ) then
		InfoBrowser_Next:Disable();
		InfoBrowser_ReadAll:Disable()
	else
		InfoBrowser_Next:Enable();
		InfoBrowser_ReadAll:Enable()
	end

	local nchannel,nindex;
	nchannel, nindex  = DataPool:GetFriendByName( DataPool:GetMail( nCurrentMail,"SENDER" ) );
	
	if( tonumber( nchannel ) == -1 ) then
		InfoBrowser_AddFriend:Enable();
	else
		InfoBrowser_AddFriend:Disable();
	end
	
	InfoBrowser_ExamineData:Enable();
	
	InfoBrowser_Respondence:Enable();

end

function InfoBrowser_Close()
	this:Hide();
	Variable:SetVariable( "IsInfoBrowerShow","False", 1 );
end

function InfoBrowser_Show()
	this:Show();
	Variable:SetVariable( "IsInfoBrowerShow","True", 1 );
	InfoBrowser_Frame_Title:SetText( "#gFF0FA0信件浏览" );
	InfoBrowser_Frame_System:Hide();
	InfoBrowser_Frame_Player:Show();
	InfoBrowser_Respondence:Show();
	InfoBrowser_AddFriend:Show();
	InfoBrowser_Report:Show();
	InfoBrowser_ExamineData:Show()
	InfoBrowser_HistoryInfo:Show()
	--投诉按钮show
	g_IsSystemMail = false;
end

function SystemInfo_Show()
	this:Show();
	Variable:SetVariable( "IsInfoBrowerShow","True", 1 );
	InfoBrowser_Frame_Player:Hide();
	InfoBrowser_Frame_Title:SetText( "#gFF0FA0系统信息" );
	InfoBrowser_Frame_System:Show();
	InfoBrowser_AddFriend:Hide();
	InfoBrowser_Respondence:Hide();
	InfoBrowser_HistoryInfo:Show();
	--投诉按钮hide
	g_IsSystemMail = true;
end


function InfoBrowser_NextMail()
	DataPool:GetNextMail();
end

-- 获取所有的邮件，只显示最后一个
function InfoBrowser_ReadAllMail()
	DataPool:GetAllMail()
end

function InfoBrowser_AddToFriend()
	local sender  = DataPool:GetMail( nCurrentMail, "SENDER" );
	DataPool:AddFriendAndGrouping( sender );
end

function InfoBrowser_PlayerInfo()
	local name = DataPool:GetMail( nCurrentMail, "SENDER" )
	if( Friend:IsPlayerIsFriend( name ) == 1 ) then	
		DataPool:ShowFriendInfo( name );
	else
		DataPool:ShowChatInfo( name );
	end

	
end

function InfoBrowser_MailBack()
	local sender  = DataPool:GetMail( nCurrentMail, "SENDER" );
	local nchannel,nindex;
	nchannel, nindex  = DataPool:GetFriendByName( sender );
	if( tonumber( nchannel ) == -1 ) then
		DataPool:AddFriend( 13, sender );
	end	
	DataPool:OpenMail( sender );
end

function InfoBrowser_Help()
end

function SystemInfo_Update()
	
		Variable:SetVariable( "IsInfoBrowerShow","True", 1 );
		InfoBrower_UpdateButton();
		local sender  = DataPool:GetMail( nCurrentMail,"SENDER" );
		local context = DataPool:GetMail( nCurrentMail,"CONTEX" );
		local time	  = DataPool:GetMail( nCurrentMail,"TIME" );
	
		
		SystemInfo_From:SetText( "#b#cFF0000#effffff系统邮件" );
		SystemInfo_Time:SetText( "时间:"..time );
		SystemInfo_Context:SetText( context );
		InfoBrowser_Report:Hide();
end


function SystemInfo_NextPage()
	InfoBrower_DisableButton();
	local mailnumber = DataPool:GetMailNumber();

	if( mailnumber > 0 ) then
		InfoBrowser_NextMail();
	end
end
function InfoBrowser_OnHiden()	
	Variable:SetVariable( "IsInfoBrowerShow","False", 1 );
end

function InfoBrowser_toushu()
	local MailTime = DataPool:GetMailTimeInt(nCurrentMail);
	local sender  = DataPool:GetMail( nCurrentMail,"SENDER" );
	local context = DataPool:GetMail( nCurrentMail,"CONTEX" );
	Talk:DisclosureToGM("mail",sender,context,MailTime);
end
function InfoBrowser_Frame_ResetPos()
	InfoBrowser_Frame:SetProperty("UnifiedXPosition", g_InfoBrowser_Frame_UnifiedXPosition);
	InfoBrowser_Frame:SetProperty("UnifiedYPosition", g_InfoBrowser_Frame_UnifiedYPosition);
end

--系统消息
function InfoBrowser_OpenHistroyInfo()
	if g_IsSystemMail == false then
		local _Group,_Index = DataPool:GetFriendByName( DataPool:GetMail( nCurrentMail,"SENDER" ) );
		DataPool:OpenHistroy( _Group,_Index); --Friend:GetCurrentTeam(), Friend:GetCurrentSelect() );
	else
		DataPool:OpenSystemHistroy();
	end 	
end
