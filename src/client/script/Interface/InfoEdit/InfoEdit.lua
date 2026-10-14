
--是否预览状态
local currentmode = 0;

local g_ChatBtn ={};

local isFirstClick = false;
local g_InfoEdit_Frame_UnifiedXPosition;
local g_InfoEdit_Frame_UnifiedYPosition;
--===============================================
-- OnLoad()
--===============================================
function InfoEdit_PreLoad()

	this:RegisterEvent("OPEN_EMAIL_WRITE",true);
	this:RegisterEvent("OPEN_EMAIL_ZHENGYOU",true);
	this:RegisterEvent("SEND_MAIL",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function InfoEdit_OnLoad()
	g_InfoEdit_Frame_UnifiedXPosition	= InfoEdit_Frame:GetProperty("UnifiedXPosition");
	g_InfoEdit_Frame_UnifiedYPosition	= InfoEdit_Frame:GetProperty("UnifiedYPosition");
end

--===============================================
-- OnEvent()
--===============================================
function InfoEdit_OnEvent( event )
	
	if ( event == "OPEN_EMAIL_WRITE" ) then
		InfoEdit_Show();
		InfoEdit_Target:SetText( arg1 );
		InfoEdit_EditInfo:SetText(arg2);
		InfoEdit_History:Enable();
		if arg1 ~= ""  then 
			if IsWindowShow("PetFriendSearch") or IsWindowShow("PetZhengYou") then
				InfoEdit_EditInfo:SetProperty("SelectionStart",0);
				InfoEdit_EditInfo:SetProperty("SelectionLength", -1);
				isFirstClick = true;
			end
		end
	elseif  ( event == "OPEN_EMAIL_ZHENGYOU" ) then
		InfoEdit_Show();
		InfoEdit_Target:SetText( arg1 );
		InfoEdit_EditInfo:SetText(arg2);
		InfoEdit_History:Disable();
		if arg1 ~= ""  then 
			if IsWindowShow("PetFriendSearch") or IsWindowShow("PetZhengYou") then
				InfoEdit_EditInfo:SetProperty("SelectionStart",0);
				InfoEdit_EditInfo:SetProperty("SelectionLength", -1);
				isFirstClick = true;
			end
		end	 	
	elseif( event == "SEND_MAIL" ) then
		InfoEdit_SendMail();
	elseif (event == "ADJEST_UI_POS" ) then
		InfoEdit_Frame_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		InfoEdit_Frame_ResetPos()
	end

end

function InfoEdit_Empty()
	if isFirstClick == true then
		isFirstClick = false;
		InfoEdit_EditInfo:SetText("");
	end
end

--===============================================
-- UpdateFrame()
--===============================================
function InfoEdit_Update()
	InfoEdit_History:SetText("历史信件") -- zchw
	InfoEdit_Preview:SetText( "预览" );
	InfoEdit_PreviewInfo:Hide();
	InfoEdit_EditInfo:Show();
	InfoEdit_EditInfo:SetForce();
end

function InfoEdit_Show()
	this:Show();
	InfoEdit_Update();
	InfoEdit_EditInfo:SetText("");
	
end

function InfoEdit_Hide()
	this:Hide();
end

function InfoEdit_ClosePreviewClick()
	
	InfoEdit_Preview:SetText( "预览" );
	InfoEdit_PreviewInfo:Hide();
	InfoEdit_EditInfo:Show();
		
	
end
function InfoEdit_PreviewClick()
	if( InfoEdit_PreviewInfo:IsVisible() ) then
		InfoEdit_ClosePreviewClick();
	else
		local strTemp = DataPool:CheckRMBFace(InfoEdit_EditInfo:GetText() )
		InfoEdit_PreviewInfo:SetText( strTemp );
		InfoEdit_Preview:SetText( "返回" );
		InfoEdit_PreviewInfo:Show();
		InfoEdit_EditInfo:Hide();
	end
	
end

function InfoEdit_SendMail()	
	local SendRet = nil	--标识发邮件是否成功--add by xindefeng
	
	if isFirstClick then
		isFirstClick = false;
	end
	local szValue= InfoEdit_EditInfo:GetText();
	if( szValue == "" ) then
		PushDebugMessage("不能发送空邮件");
		return;
	end
	if( this:IsVisible() ) then
		SendRet = DataPool:SendMail( InfoEdit_Target:GetText(), InfoEdit_EditInfo:GetText() )	--modify by xindefeng
		
		local nchannel,nindex;
		nchannel, nindex  = DataPool:GetFriendByName( InfoEdit_Target:GetText() );
		if( tonumber( nchannel ) == -1 ) then
			DataPool:AddFriend( 7, InfoEdit_Target:GetText() );
		end
	end
		
	if(SendRet == 0)then	--如果发邮件成功,关闭界面--modify by xindefeng
		InfoEdit_Hide()
	end
	
end

function InfoEdit_OnHidden()
	InfoEdit_EditInfo:SetProperty("DefaultEditBox", "False");
end

function InfoEdit_GetBtnScreenPosX(btn)
	InfoEdit_PrepareBtnCtl();
	local barxpos = InfoEdit_Frame:GetProperty("AbsoluteXPosition");
	local btnxpos = g_ChatBtn[btn]:GetProperty("AbsoluteXPosition");
	
	return barxpos+btnxpos;
end
function InfoEdit_GetBtnScreenPosY(btn)
	InfoEdit_PrepareBtnCtl();
	local barxpos = InfoEdit_Frame:GetProperty("AbsoluteYPosition");
	local btnxpos = InfoEdit_Frame:GetProperty("AbsoluteHeight");
	return barxpos+btnxpos+2;
end
function InfoEdit_SelectTextColor()
	Talk:SelectTextColor("select", InfoEdit_GetBtnScreenPosX("color"),InfoEdit_GetBtnScreenPosY("color"));
end

function InfoEdit_SelectFaceMotion()
-- changed by lx	2010-11-3
-- for TT83449 写邮件时打开表情包时，表情包位置修改
--	Talk:SelectFaceMotion("select", InfoEdit_GetBtnScreenPosX("face"),InfoEdit_GetBtnScreenPosY("face"));
--	常数分别为表情包窗口宽度和高度
	local posX = InfoEdit_Frame:GetProperty("AbsoluteXPosition") + InfoEdit_Frame_Client:GetProperty("AbsoluteXPosition");
	if SystemSetup:IsClassic() == 1 then
		posX = posX + InfoEdit_ChatButton_Frame:GetProperty("AbsoluteXPosition") + InfoEdit_Face:GetProperty("AbsoluteXPosition");
	else
		posX = posX - InfoEdit_Frame_Client:GetProperty("AbsoluteXPosition") + InfoEdit_Face:GetProperty("AbsoluteXPosition") - 8;
	end
	
	local posY = InfoEdit_Frame:GetProperty("AbsoluteYPosition") + InfoEdit_Frame_Client:GetProperty("AbsoluteYPosition");
	if SystemSetup:IsClassic() == 1 then
		posY = posY + InfoEdit_ChatButton_Frame:GetProperty("AbsoluteYPosition") + InfoEdit_Face:GetProperty("AbsoluteYPosition");
		posY = posY - 307;
	else
		posY = posY - InfoEdit_Frame_Client:GetProperty("AbsoluteYPosition") + InfoEdit_Face:GetProperty("AbsoluteYPosition");
		posY = posY - 320;
	end

	Talk:SelectFaceMotion("select", posX, posY);
end

function InfoEdit_PrepareBtnCtl()
	g_ChatBtn = {
								color		= InfoEdit_LetterColor,
								face		= InfoEdit_Face,

							};
end

-- add by zchw
function InfoEdit_MailHistory()
	local _Group,_Index = DataPool:GetFriendByName(InfoEdit_Target:GetText()); --Modify by WangShibo . 解决一个邮件bug 2009-11-17
	DataPool:OpenHistroy( _Group,_Index); --Friend:GetCurrentTeam(), Friend:GetCurrentSelect() );
end
function InfoEdit_Frame_ResetPos()

	InfoEdit_Frame:SetProperty("UnifiedXPosition", g_InfoEdit_Frame_UnifiedXPosition);
	InfoEdit_Frame:SetProperty("UnifiedYPosition", g_InfoEdit_Frame_UnifiedYPosition);

end
