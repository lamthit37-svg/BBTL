--邮件提示框
local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition
--===============================================
-- OnLoad()
--===============================================
function MessageBox_Mail_PreLoad()

	--显示文字内容
	this:RegisterEvent("UPDATE_MESSAGEMAIL")	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	
end

function MessageBox_Mail_OnLoad()
	g_Frame_UnifiedXPosition	= MessageBox_Mail_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= MessageBox_Mail_Frame:GetProperty("UnifiedYPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function MessageBox_Mail_OnEvent(event)
	if (event =="UPDATE_MESSAGEMAIL") then
		MessageBox_Mail_UpdaeMailBox(tonumber(arg0))
	elseif( event == "ADJEST_UI_POS" ) then
		MessageBox_Mail_Frame_On_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		MessageBox_Mail_Frame_On_ResetPos()
	end
end

--===============================================
-- 点击确定（IDOK）
--===============================================
function MessageBox_Mail_OK_Clicked()
	PushEvent("MAILNEW_TIPS",1,0)
	this:Hide()
end

--===============================================
-- 点击取消
--===============================================
function MessageBox_Mail_Cancel_Clicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function MessageBox_Mail_Frame_On_ResetPos()
  MessageBox_Mail_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition)
	MessageBox_Mail_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition)
end

--================================================
-- 邮件提示内容
--================================================
function MessageBox_Mail_UpdaeMailBox(arg0)
	local MailText =""
	if arg0 == 3 then
		MailText = "#{FJYX_110426_143}"
	elseif arg0 == 1 then
		MailText = "#{FJYX_110426_144}"
	elseif arg0 == 2 then
		MailText = "#{FJYX_110426_145}"
	end
	this:Show()

	MessageBox_Mail_Text:SetText(MailText)
	local nWidth, nHeight = MessageBox_Mail_Text:GetWindowSize()
	local nTitleHeight = 23
	local nBottomHeight = 25
	local nWindowHeight = nTitleHeight + nBottomHeight + nHeight
	MessageBox_Mail_Frame:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) )
end
