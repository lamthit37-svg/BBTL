----------------------
-- NEWGSRecord ---
----------------------
local g_Count = 10   --一页显示的聊天条数
local g_CurPage = 1  --当前显示的页面
--===============================================
-- PreLoad()
--===============================================
function NEWGSRecord_PreLoad()
	this:RegisterEvent("OPEN_GSRECORD_NEW");
	this:RegisterEvent("GS_CANCELBIND_NEW");
	this:RegisterEvent("GSCHAT_CLOSE_NEW");
end

--===============================================
-- OnLoad()
--===============================================
function NEWGSRecord_OnLoad()

end

--===============================================
-- OnEvent()
--===============================================
function NEWGSRecord_OnEvent(event)

	if( event == "OPEN_GSRECORD_NEW" ) then
		NEWGSRecord_OnInit()
	elseif ( event == "GS_CANCELBIND_NEW" ) then
		NEWGSRecord_Edit:RemoveAllChatString()
		this:Hide()	
	elseif ( event == "GSCHAT_CLOSE_NEW" ) then
		NEWGSRecord_Close_Clicked()
	end
end

function NEWGSRecord_OnInit()
	NEWGSRecord_Edit:RemoveAllChatString()
	local chatcount = Talk:GetNewGSIMChatCount()
	local page = math.ceil(chatcount/g_Count)
	local showcount = 0
	local msg
	NEWGSRecord_Blank_Text:SetText("1/"..page)

	if chatcount <= g_Count then
		 showcount = chatcount
	else
		 showcount = g_Count
	end

	for i = 0 , showcount-1 do
		 	msg = Talk:GetNewGSIMChatByIndex(chatcount-1-i)  --要求倒着显示
		 	NEWGSRecord_Edit:InsertChatString(msg)
	end
	g_CurPage = 1
	this:Show()
	NEWGSRecord_Firstpage:Disable()
	NEWGSRecord_Beforepage:Disable()
	NEWGSRecord_Nextpage:Enable()
	NEWGSRecord_Lastpage:Enable()
	if (page <= 1) then
		NEWGSRecord_Nextpage:Disable()
		NEWGSRecord_Lastpage:Disable()
	end
end

function NEWGSRecord_Close_Clicked()
	this:Hide()
end

--首页
function NEWGSRecord_Firstpage_Clicked()
	NEWGSRecord_Edit:RemoveAllChatString()
	NEWGSRecord_OnInit()
end

--上一页
function NEWGSRecord_Beforepage_Clicked()
	if g_CurPage <= 1 then
		return
	end
	
	NEWGSRecord_Edit:RemoveAllChatString()
	g_CurPage = g_CurPage - 1
	if g_CurPage == 1 then
		NEWGSRecord_Firstpage_Clicked()
	else
		NEWGSRecord_ShowCurPage()
	end
end

--下一页
function NEWGSRecord_Nextpage_Clicked()
	local chatcount = Talk:GetNewGSIMChatCount()
	local page = math.ceil(chatcount/g_Count)
	local showcount = math.mod(chatcount,g_Count)
	
	if g_CurPage >= page then
		return
	end
	
	NEWGSRecord_Edit:RemoveAllChatString()
	g_CurPage = g_CurPage + 1
	if g_CurPage == page then
		NEWGSRecord_Lastpage_Clicked()
	else
		NEWGSRecord_ShowCurPage()
	end
end

--尾页
function NEWGSRecord_Lastpage_Clicked()
	NEWGSRecord_Edit:RemoveAllChatString()
	local chatcount = Talk:GetNewGSIMChatCount()
	local page = math.ceil(chatcount/g_Count)
	local showcount = math.mod(chatcount,g_Count)
	local msg
	NEWGSRecord_Blank_Text:SetText(page.."/"..page)

	if showcount == 0 then
		 showcount = g_Count
	end

	for i = 0 , showcount-1 do
		 	msg = Talk:GetNewGSIMChatByIndex(showcount-1-i)
		 	NEWGSRecord_Edit:InsertChatString(msg)
	end
	g_CurPage = page
	NEWGSRecord_Firstpage:Enable()
	NEWGSRecord_Beforepage:Enable()
	NEWGSRecord_Lastpage:Disable()
	NEWGSRecord_Nextpage:Disable()
end

function NEWGSRecord_ShowCurPage()
	NEWGSRecord_Edit:RemoveAllChatString()
	local chatcount = Talk:GetNewGSIMChatCount()
	local page = math.ceil(chatcount/g_Count)
	local showcount = g_CurPage
	local msg
	NEWGSRecord_Blank_Text:SetText(g_CurPage.."/"..page)

	for i = 0 , g_Count-1 do
		 	msg = Talk:GetNewGSIMChatByIndex(chatcount-(g_CurPage-1)*g_Count-i-1)  --倒着显示
		 	NEWGSRecord_Edit:InsertChatString(msg)
	end
	NEWGSRecord_Firstpage:Enable()
	NEWGSRecord_Beforepage:Enable()
	NEWGSRecord_Lastpage:Enable()
	NEWGSRecord_Nextpage:Enable()
end