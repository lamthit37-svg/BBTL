----------------------
-- GSRecord ---
----------------------
local g_Count = 10   --一页显示的聊天条数
local g_CurPage = 1  --当前显示的页面
--===============================================
-- PreLoad()
--===============================================
function GSRecord_PreLoad()
	this:RegisterEvent("OPEN_GSRECORD");
	this:RegisterEvent("GS_CANCELBIND");
	this:RegisterEvent("GSCHAT_CLOSE");
end

--===============================================
-- OnLoad()
--===============================================
function GSRecord_OnLoad()

end

--===============================================
-- OnEvent()
--===============================================
function GSRecord_OnEvent(event)

	if( event == "OPEN_GSRECORD" ) then
		GSRecord_OnInit()
	elseif ( event == "GS_CANCELBIND" ) then
		GSRecord_Edit:RemoveAllChatString()
		this:Hide()	
	elseif ( event == "GSCHAT_CLOSE" ) then
		GSRecord_Close_Clicked()
	end
end

function GSRecord_OnInit()
	GSRecord_Edit:RemoveAllChatString()
	local chatcount = Talk:GetGSIMChatCount()
	local page = math.ceil(chatcount/g_Count)
	local showcount = 0
	local msg
	GSRecord_Blank_Text:SetText("1/"..page)

	if chatcount <= g_Count then
		 showcount = chatcount
	else
		 showcount = g_Count
	end

	for i = 0 , showcount-1 do
		 	msg = Talk:GetGSIMChatByIndex(chatcount-1-i)  --要求倒着显示
		 	GSRecord_Edit:InsertChatString(msg)
	end
	g_CurPage = 1
	this:Show()
	GSRecord_Firstpage:Disable()
	GSRecord_Beforepage:Disable()
	GSRecord_Nextpage:Enable()
	GSRecord_Lastpage:Enable()
	if (page <= 1) then
		GSRecord_Nextpage:Disable()
		GSRecord_Lastpage:Disable()
	end
end

function GSRecord_Close_Clicked()
	this:Hide()
end

--首页
function GSRecord_Firstpage_Clicked()
	GSRecord_Edit:RemoveAllChatString()
	GSRecord_OnInit()
end

--上一页
function GSRecord_Beforepage_Clicked()
	if g_CurPage <= 1 then
		return
	end
	
	GSRecord_Edit:RemoveAllChatString()
	g_CurPage = g_CurPage - 1
	if g_CurPage == 1 then
		GSRecord_Firstpage_Clicked()
	else
		GSRecord_ShowCurPage()
	end
end

--下一页
function GSRecord_Nextpage_Clicked()
	local chatcount = Talk:GetGSIMChatCount()
	local page = math.ceil(chatcount/g_Count)
	local showcount = math.mod(chatcount,g_Count)
	
	if g_CurPage >= page then
		return
	end
	
	GSRecord_Edit:RemoveAllChatString()
	g_CurPage = g_CurPage + 1
	if g_CurPage == page then
		GSRecord_Lastpage_Clicked()
	else
		GSRecord_ShowCurPage()
	end
end

--尾页
function GSRecord_Lastpage_Clicked()
	GSRecord_Edit:RemoveAllChatString()
	local chatcount = Talk:GetGSIMChatCount()
	local page = math.ceil(chatcount/g_Count)
	local showcount = math.mod(chatcount,g_Count)
	local msg
	GSRecord_Blank_Text:SetText(page.."/"..page)

	if showcount == 0 then
		 showcount = g_Count
	end

	for i = 0 , showcount-1 do
		 	msg = Talk:GetGSIMChatByIndex(showcount-1-i)
		 	GSRecord_Edit:InsertChatString(msg)
	end
	g_CurPage = page
	GSRecord_Firstpage:Enable()
	GSRecord_Beforepage:Enable()
	GSRecord_Lastpage:Disable()
	GSRecord_Nextpage:Disable()
end

function GSRecord_ShowCurPage()
	GSRecord_Edit:RemoveAllChatString()
	local chatcount = Talk:GetGSIMChatCount()
	local page = math.ceil(chatcount/g_Count)
	local showcount = g_CurPage
	local msg
	GSRecord_Blank_Text:SetText(g_CurPage.."/"..page)

	for i = 0 , g_Count-1 do
		 	msg = Talk:GetGSIMChatByIndex(chatcount-(g_CurPage-1)*g_Count-i-1)  --倒着显示
		 	GSRecord_Edit:InsertChatString(msg)
	end
	GSRecord_Firstpage:Enable()
	GSRecord_Beforepage:Enable()
	GSRecord_Lastpage:Enable()
	GSRecord_Nextpage:Enable()
end