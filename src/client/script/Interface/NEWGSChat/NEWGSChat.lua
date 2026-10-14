----------------------
-- NEWGSChat ---
----------------------
local g_Minopen = 0
local g_NEWGSChat_Frame_UnifiedXPosition;
local g_NEWGSChat_Frame_UnifiedYPosition;
--===============================================
-- PreLoad()
--===============================================
function NEWGSChat_PreLoad()
	this:RegisterEvent("OPEN_GSIM_NEW");
	this:RegisterEvent("WRITE_GSIM_MSG_NEW");
	this:RegisterEvent("GS_CANCELBIND_NEW");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	this:RegisterEvent("GS_REFRESHCHAT_NEW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);	--切场景	
end

--===============================================
-- OnLoad()
--===============================================
function NEWGSChat_OnLoad()
	NEWGSChat_HistoryContent__auto_parent__:SetProperty("MouseLButtonHollow", "False")
	NEWGSChat_HistoryContent__auto_parent__:SetProperty("MouseRButtonHollow", "False")
	g_NEWGSChat_Frame_UnifiedXPosition	= NEWGSChat_Frame:GetProperty("UnifiedXPosition");
	g_NEWGSChat_Frame_UnifiedYPosition	= NEWGSChat_Frame:GetProperty("UnifiedYPosition");
end

--===============================================
-- OnEvent()
--===============================================
function NEWGSChat_OnEvent(event)

	if( event == "OPEN_GSIM_NEW" ) then
		local isTips = tonumber(arg0)
		NEWGSChat_OnInit(isTips)
	elseif ( event == "WRITE_GSIM_MSG_NEW" ) then
		NEWGSChat_OnSendMsg(arg0)
	elseif ( event == "GS_CANCELBIND_NEW" ) then
		NEWGSChat_Close_Clicked()
	elseif( event == "ADJEST_UI_POS" ) then
		NEWGSChat_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		NEWGSChat_ResetPos()
	elseif( event == "GS_REFRESHCHAT_NEW" ) then
		NEWGSChat_Refresh()
	--elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then		
	--	NEWGSChat_Close_Clicked()
	end
end

function NEWGSChat_OnInit(istips)

	if Talk:IshaveGSIMMsgNew() ~= 0 then
		PushEvent("HAVE_GSIM_MSG_NEW", 0)  --点开了 小手就别闪了
	end

	local isConnectGS = Talk:IsInGSService()
	if isConnectGS ~= 2 then
		 return
	end

	local mGSState = Talk:GetNewGSState()
	local mGSName = Talk:GetNewGSName()
	local mGSPic = Talk:GetNewGSPic()
	local mGSmood = Talk:GetNewGSMood()
	local col = "#G"
	local statename = ""
	local gschat =""

	if mGSState ==0 then  
		 col = "#G"
		 statename = "[在线]"
		 gschat =ScriptGlobal_Format( "#{GS_130923_08}", mGSName)
	elseif mGSState ==1 then
	   col = "#cff0000"
	   statename = "[忙碌]"
	   gschat = "#{GS_130923_09}"
	elseif mGSState ==2 then
		 col = "#Y"
		 statename = "[离开]"
	   gschat = "#{GS_130923_10}"
	elseif mGSState ==3 then
		 col = "#c787777"
		 statename = "[离线]"
	   gschat = "#{GS_130923_10}"
	end
	
	local isRet = Talk:GetGSInfoIsRetNew()
	if isRet == 0 then
		gschat = "#{GSQD_150511_03}"
	end
	
	if istips ==1 and (not this:IsVisible()) and g_Minopen == 0 and Talk:IshaveGSIMMsgNew() == 0 then
		NEWGSChat_HistoryContent:InsertChatString(gschat)
	end
	
	NEWGSChat_Text_1:SetText(col..mGSName)
	NEWGSChat_Text_2:SetText(col..statename)
	NEWGSChat_Text_XQ:SetText(col..mGSmood)
	NEWGSChat_Head:SetProperty("Image", mGSPic)
	Talk:haveReadGSIMMsgNew()
	
	local mflag = Talk:IsCanScoreNew()
	if mflag == 1 then
		NEWGSChat_Evaluate:SetText("#gFF0FA0".."服务评价")
		NEWGSChat_Evaluate:Enable()
	else
		NEWGSChat_Evaluate:SetText("#cbbbbbb".."服务评价")
		NEWGSChat_Evaluate:Disable()
	end
		
	this:Show()
	g_Minopen = 0
end

function NEWGSChat_Close_Clicked()
	NEWGSChat_HistoryContent:RemoveAllChatString()
	PushEvent("GSCHAT_CLOSE_NEW")
	this:Hide()
end


function NEWGSChat_Evaluate_Clicked()
	local mflag = Talk:IsCanScoreNew()
	if mflag == 1 then
		PushEvent("OPEN_GSEVALUATE_NEW")
	else
		PushDebugMessage("#{GSQD_150511_10}")
	end
end

function NEWGSChat_Record_Clicked()
	PushEvent("OPEN_GSRECORD_NEW")
end

function NEWGSChat_Mini_Clicked()
	g_Minopen = 1
	this:Hide()
	PushEvent("UPDATE_MIN_WINDOW_GSCHAT_NEW",0)  --最小化
end

function NEWGSChat_OnSendMsg(msg)
	NEWGSChat_HistoryContent:InsertChatString(msg)
	if (not this:IsVisible()) then
		PushEvent("UPDATE_MIN_WINDOW_GSCHAT_NEW", 1) ---如果已经是最小化的时候 闪
	else
		Talk:haveReadGSIMMsgNew()
	end

end

function NEWGSChat_Send_Clicked()
	if NEWGSChat_Edit:GetText() == nil or NEWGSChat_Edit:GetText() == "" then
		return
	end
	
	local lefttime = Talk:GSChat_SendMsgNew(NEWGSChat_Edit:GetText())
	if lefttime ==0 then
		  NEWGSChat_Edit:SetText("")
	else
			local str = ScriptGlobal_Format("#{GS_130923_12}", tostring(lefttime))
			PushDebugMessage(str)
	end
	
end

--点击字体颜色
function NEWGSChat_SelectTextColor()
	local yPos = NEWGSChat_Frame:GetProperty("AbsoluteYPosition")+NEWGSChat_LetterColor:GetProperty("AbsoluteYPosition")
	local xPos = NEWGSChat_Frame:GetProperty("AbsoluteXPosition")+NEWGSChat_LetterColor:GetProperty("AbsoluteXPosition")
	Talk:SelectTextColor("select", xPos, yPos);
end

function NEWGSChat_SelectFaceMotion()
	local yPos = NEWGSChat_Frame:GetProperty("AbsoluteYPosition")+NEWGSChat_Face:GetProperty("AbsoluteYPosition")
	local xPos = NEWGSChat_Frame:GetProperty("AbsoluteXPosition")+NEWGSChat_Face:GetProperty("AbsoluteXPosition")
	Talk:SelectFaceMotion("select", xPos, yPos);
end

function NEWGSChat_Clean_Clicked()
	NEWGSChat_HistoryContent:RemoveAllChatString()
end

-- 重置位置
function NEWGSChat_ResetPos()
	NEWGSChat_Frame:SetProperty("UnifiedXPosition", g_NEWGSChat_Frame_UnifiedXPosition);
	NEWGSChat_Frame:SetProperty("UnifiedYPosition", g_NEWGSChat_Frame_UnifiedYPosition);
end

function NEWGSChat_Refresh()

	if this:IsVisible() then
		local mGSState = Talk:GetNewGSState()
		local mGSName = Talk:GetNewGSName()
		local mGSmood = Talk:GetNewGSMood()
		local col = "#G"
		local statename = ""
	
		if mGSState ==0 then  
			 col = "#G"
			 statename = "[在线]"
			 gschat =ScriptGlobal_Format( "#{GS_130923_08}", mGSName)
		elseif mGSState ==1 then
		   col = "#cff0000"
		   statename = "[忙碌]"
		   gschat = "#{GS_130923_09}"
		elseif mGSState ==2 then
			 col = "#Y"
			 statename = "[离开]"
		   gschat = "#{GS_130923_10}"
		elseif mGSState ==3 then
			 col = "#c787777"
			 statename = "[离线]"
		   gschat = "#{GS_130923_10}"
		end
		
		NEWGSChat_Text_1:SetText(col..mGSName)
		NEWGSChat_Text_2:SetText(col..statename)
		NEWGSChat_Text_XQ:SetText(col..mGSmood)		
		
		local mflag = Talk:IsCanScoreNew()
		
		if mflag == 1 then
			NEWGSChat_Evaluate:SetText("#gFF0FA0".."服务评价")
			NEWGSChat_Evaluate:Enable()
		else
			NEWGSChat_Evaluate:SetText("#cbbbbbb".."服务评价")
			NEWGSChat_Evaluate:Disable()
		end		
	end

end
