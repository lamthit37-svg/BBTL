----------------------
-- GSChat ---
----------------------
local g_Minopen = 0
local g_GSChat_Frame_UnifiedXPosition;
local g_GSChat_Frame_UnifiedYPosition;
--===============================================
-- PreLoad()
--===============================================
function GSChat_PreLoad()
	this:RegisterEvent("OPEN_GSIM");
	this:RegisterEvent("WRITE_GSIM_MSG");
	this:RegisterEvent("GS_CANCELBIND");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
end

--===============================================
-- OnLoad()
--===============================================
function GSChat_OnLoad()
	GSChat_HistoryContent__auto_parent__:SetProperty("MouseLButtonHollow", "False")
	GSChat_HistoryContent__auto_parent__:SetProperty("MouseRButtonHollow", "False")
	g_GSChat_Frame_UnifiedXPosition	= GSChat_Frame:GetProperty("UnifiedXPosition");
	g_GSChat_Frame_UnifiedYPosition	= GSChat_Frame:GetProperty("UnifiedYPosition");
end

--===============================================
-- OnEvent()
--===============================================
function GSChat_OnEvent(event)

	if( event == "OPEN_GSIM" ) then
		local isTips = tonumber(arg0)
		GSChat_OnInit(isTips)
	elseif ( event == "WRITE_GSIM_MSG" ) then
		GSChat_OnSendMsg(arg0)
	elseif ( event == "GS_CANCELBIND" ) then
		GSChat_Close_Clicked()
	elseif( event == "ADJEST_UI_POS" ) then
		GSChat_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		GSChat_ResetPos()
	end
end

function GSChat_OnInit(istips)

	if Talk:IshaveGSIMMsg() ~= 0 then
		PushEvent("HAVE_GSIM_MSG", 0)  --点开了 小手就别闪了
	end

	local isConnectGS = Talk:IsInGSService()
	if isConnectGS ~= 1 then
		 return
	end

	local mGSState = Talk:GetGSState()
	local mGSName = Talk:GetGSName()
	local mGSPic = Talk:GetGSPic()
	local col = "#G"
	local statename = ""
	local gschat =""

	if mGSState ==0 then  
		 col = "#G"
		 statename = "[空闲]"
		 gschat =ScriptGlobal_Format( "#{GS_130923_08}", mGSName)
	elseif mGSState ==1 then
	   col = "#R"
	   statename = "[忙碌]"
	   gschat = "#{GS_130923_09}"
	elseif mGSState ==2 then
		 col = "#c808080"
		 statename = "[离线]"
	   gschat = "#{GS_130923_10}"
	end
	
	if istips ==1 and (not this:IsVisible()) and g_Minopen == 0 and Talk:IshaveGSIMMsg() == 0 then
		GSChat_HistoryContent:InsertChatString(gschat)
	end
	
	GSChat_Text_1:SetText(col..mGSName)
	GSChat_Text_2:SetText(col..statename)
	GSChat_Head:SetProperty("Image", mGSPic)
	Talk:haveReadGSIMMsg()
	this:Show()
	g_Minopen = 0
end

function GSChat_Close_Clicked()
	GSChat_HistoryContent:RemoveAllChatString()
	PushEvent("GSCHAT_CLOSE")
	this:Hide()
end


function GSChat_Evaluate_Clicked()
	local mflag = Talk:IsCanScore()
	if mflag == 1 then
		PushEvent("OPEN_GSEVALUATE")
	end
end

function GSChat_Record_Clicked()
	PushEvent("OPEN_GSRECORD")
end

function GSChat_Mini_Clicked()
	g_Minopen = 1
	this:Hide()
	PushEvent("UPDATE_MIN_WINDOW_GSCHAT",0)  --最小化
end

function GSChat_OnSendMsg(msg)
	GSChat_HistoryContent:InsertChatString(msg)
	if (not this:IsVisible()) then
		PushEvent("UPDATE_MIN_WINDOW_GSCHAT", 1) ---如果已经是最小化的时候 闪
	else
		Talk:haveReadGSIMMsg()
	end

end

function GSChat_Send_Clicked()
	if GSChat_Edit:GetText() == nil or GSChat_Edit:GetText() == "" then
		return
	end
	
	local lefttime = Talk:GSChat_SendMsg(GSChat_Edit:GetText())
	if lefttime ==0 then
		  GSChat_Edit:SetText("")
	else
			local str = ScriptGlobal_Format("#{GS_130923_12}", tostring(lefttime))
			PushDebugMessage(str)
	end
	
end

--点击字体颜色
function GSChat_SelectTextColor()
	local yPos = GSChat_Frame:GetProperty("AbsoluteYPosition")+GSChat_LetterColor:GetProperty("AbsoluteYPosition")
	local xPos = GSChat_Frame:GetProperty("AbsoluteXPosition")+GSChat_LetterColor:GetProperty("AbsoluteXPosition")
	Talk:SelectTextColor("select", xPos, yPos);
end

function GSChat_SelectFaceMotion()
	local yPos = GSChat_Frame:GetProperty("AbsoluteYPosition")+GSChat_Face:GetProperty("AbsoluteYPosition")
	local xPos = GSChat_Frame:GetProperty("AbsoluteXPosition")+GSChat_Face:GetProperty("AbsoluteXPosition")
	Talk:SelectFaceMotion("select", xPos, yPos);
end

function GSChat_Clean_Clicked()
	GSChat_HistoryContent:RemoveAllChatString()
end

-- 重置位置
function GSChat_ResetPos()
	GSChat_Frame:SetProperty("UnifiedXPosition", g_GSChat_Frame_UnifiedXPosition);
	GSChat_Frame:SetProperty("UnifiedYPosition", g_GSChat_Frame_UnifiedYPosition);
end