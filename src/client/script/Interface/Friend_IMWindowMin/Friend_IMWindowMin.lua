
local g_MinWinFrame = {}
local g_MinWinType = 0
local g_isGSMINIMOpen = 0
local g_isGSMINIMOpenType = 0 --0 老的GS系统 1 新的gs系统

function Friend_IMWindowMin_PreLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD");
	this:RegisterEvent("UPDATE_MIN_WINDOW");
	this:RegisterEvent("UPDATE_MIN_WINDOW_CY");
	this:RegisterEvent("UPDATE_MIN_WINDOW_GMCHAT");
	this:RegisterEvent("GMCHAT_CONNECTINFO_CLOSE");
	this:RegisterEvent("GMCHAT_CONFIRM_STOPCHAT");
	this:RegisterEvent("GMCHAT_CONFIRM_CANCELCONNECT");
	this:RegisterEvent("UPDATE_MIN_WINDOW_GSCHAT");	
	this:RegisterEvent("UPDATE_MIN_WINDOW_GSCHAT_NEW");		
	this:RegisterEvent("GS_CANCELBIND");
	this:RegisterEvent("OPEN_GSIM");
	this:RegisterEvent("UNIT_RACE_ID");
end


function Friend_IMWindowMin_OnLoad()
--nType
-- -1 	NULL
-- 0  	1V1 聊天
-- 1 	群聊
-- 2 	飞信
-- 9	畅游精灵
-- 10	GM聊天
-- 11 GS聊天
	g_MinWinFrame = {
		{ctrl = Friend_IMWindowMin_IM1, flash = Friend_IMWindowMin_Flash1 ,bShow = 0 , id = "", sName = "", sRemark = "" , nType = -1 },
		{ctrl = Friend_IMWindowMin_IM2, flash = Friend_IMWindowMin_Flash2 ,bShow = 0 , id = "", sName = "", sRemark = "" , nType = -1 },
		{ctrl = Friend_IMWindowMin_IM3, flash = Friend_IMWindowMin_Flash3 ,bShow = 0 , id = "", sName = "", sRemark = "" , nType = -1 },
		{ctrl = Friend_IMWindowMin_IM4, flash = Friend_IMWindowMin_Flash4 ,bShow = 0 , id = "", sName = "", sRemark = "" , nType = -1 },
		{ctrl = Friend_IMWindowMin_IM5, flash = Friend_IMWindowMin_Flash5 ,bShow = 0 , id = "", sName = "", sRemark = "" , nType = -1 },
		{ctrl = Friend_IMWindowMin_IM6, flash = Friend_IMWindowMin_Flash6 ,bShow = 0 , id = "", sName = "", sRemark = "" , nType = -1 },
		{ctrl = Friend_IMWindowMin_IM7, flash = Friend_IMWindowMin_Flash7 ,bShow = 0 , id = "", sName = "", sRemark = "" , nType = -1 },
		{ctrl = Friend_IMWindowMin_IM8, flash = Friend_IMWindowMin_Flash8 ,bShow = 0 , id = "", sName = "", sRemark = "" , nType = -1 },

		--..在前边加哦，别加错了
		{ctrl = Friend_IMWindowMin_IMCY, flash = Friend_IMWindowMin_FlashCY ,bShow = 0 , id = "", sName = "" , nType = 9 }, --特殊处理畅游精灵最小化
		{ctrl = Friend_IMWindowMin_IMGMChat, flash = Friend_IMWindowMin_FlashGMChat ,bShow = 0 , id = "", sName = "" , nType = 10 }, --特殊GM聊天界面最小化
		{ctrl = Friend_IMWindowMin_IMGSChat, flash = Friend_IMWindowMin_FlashGSChat ,bShow = 0 , id = "", sName = "" , nType = 10 }, --特殊GS聊天界面最小化
	}

	g_MinWinFrame[9].ctrl:Hide()
	g_MinWinFrame[9].flash:Hide()
	g_MinWinFrame[10].ctrl:Hide()
	g_MinWinFrame[10].flash:Hide()
	g_MinWinFrame[11].ctrl:Hide()
	g_MinWinFrame[11].flash:Hide()

end

function Friend_IMWindowMin_OnEvent(event)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		this:Show();
		Friend_IMWindowMin_Update()
	elseif ( event == "UPDATE_MIN_WINDOW" ) then
		Friend_IMWindowMin_Update()
	elseif (event == "UNIT_RACE_ID") then
		Friend_IMWindowMin_Update()
	elseif ( event == "UPDATE_MIN_WINDOW_CY") then --处理畅游精灵
		if arg0 == nil then
			return
		end
		local message = tonumber(arg0)
		if message == 95786 then
			g_MinWinFrame[9].ctrl:Show()
			g_MinWinFrame[9].ctrl:SetText("畅游精灵")
		elseif message == 95787 then
			Friend_IMWindowMin_PopCY(9)
		elseif message == 95789 then
			Helper:SendMessage(message)
		end
	elseif ( event == "UPDATE_MIN_WINDOW_GMCHAT") then --处理GM聊天
		local nType = tonumber(arg0)
		local nShine = tonumber(arg1)

		g_MinWinFrame[10].ctrl:Show()

		g_MinWinType = nType
		if g_MinWinType == 1 then
			g_MinWinFrame[10].ctrl:SetText("#{GMGJTX_XML_111128_39}")
		elseif g_MinWinType == 2 then
			g_MinWinFrame[10].ctrl:SetText("#{GMGJTX_XML_111128_38}")
		end

		if nShine == 1 then
			g_MinWinFrame[10].flash:Show()
		end
	elseif ( event == "GMCHAT_CONNECTINFO_CLOSE") or
				 (event == "GMCHAT_CONFIRM_STOPCHAT") or
				 (event == "GMCHAT_CONFIRM_CANCELCONNECT")then --关闭连接界面同时关闭mini窗口
		g_MinWinFrame[10].ctrl:Hide()
		g_MinWinFrame[10].flash:Hide()
	elseif ( event == "UPDATE_MIN_WINDOW_GSCHAT") then --处理GS聊天
			g_isGSMINIMOpenType = 0
			local mGSName = Talk:GetGSName()
			local ntype = tonumber(arg0)
			if ntype == 0 then
				g_MinWinFrame[11].ctrl:Show()
				g_MinWinFrame[11].ctrl:SetText(mGSName)
				g_isGSMINIMOpen = 1
			elseif ntype == 1 then
					if g_isGSMINIMOpen == 1 then
						g_MinWinFrame[11].ctrl:Show()
						g_MinWinFrame[11].ctrl:SetText(mGSName)
						g_MinWinFrame[11].flash:Show()
					else 
						PushEvent("HAVE_GSIM_MSG", 1)  --闪小手
					end
			end
	elseif ( event == "UPDATE_MIN_WINDOW_GSCHAT_NEW") then --处理新的GS系统聊天
			g_isGSMINIMOpenType = 1
			local mGSName = Talk:GetNewGSName()
			local ntype = tonumber(arg0)
			if ntype == 0 then
				g_MinWinFrame[11].ctrl:Show()
				g_MinWinFrame[11].ctrl:SetText(mGSName)
				g_isGSMINIMOpen = 1
			elseif ntype == 1 then
					if g_isGSMINIMOpen == 1 then
						g_MinWinFrame[11].ctrl:Show()
						g_MinWinFrame[11].ctrl:SetText(mGSName)
						g_MinWinFrame[11].flash:Show()
					else 
						PushEvent("HAVE_GSIM_MSG_NEW", 1)  --闪小手
					end
			end
	elseif ( event == "GS_CANCELBIND" or event == "OPEN_GSIM" or event == "GS_CANCELBIND_NEW") then
			g_MinWinFrame[11].ctrl:Hide()
			g_MinWinFrame[11].flash:Hide()
	end
end

function Friend_IMWindowMin_Update()
	--clear
	for i = 0 , 7 do
		g_MinWinFrame[i+1].bShow = 0
		g_MinWinFrame[i+1].id = ""
		g_MinWinFrame[i+1].sName = ""
		g_MinWinFrame[i+1].nType = -1
		g_MinWinFrame[i+1].ctrl:Hide()
		g_MinWinFrame[i+1].flash:Hide()
	end

	local normalchat = 0

	for i = 0 , 4 do
		local isShow, id, szName, szRemark, nType, isShine= DataPool:GetMinWindowInfo(i)
		if 	isShow > 0 then
			g_MinWinFrame[i+1].bShow = isShow
			g_MinWinFrame[i+1].id = id
			g_MinWinFrame[i+1].sName = szName
			g_MinWinFrame[i+1].sRemark = szRemark
			g_MinWinFrame[i+1].nType = nType
			g_MinWinFrame[i+1].ctrl:Show()
--			if(szRemark == "") then
--				g_MinWinFrame[i+1].ctrl:SetText(tostring(szName))
--			else
--				g_MinWinFrame[i+1].ctrl:SetText(tostring(szRemark))
--			end
			g_MinWinFrame[i+1].ctrl:SetText(tostring(szName))
			if isShine == 1 then
				g_MinWinFrame[i+1].flash:Show()
			else
				g_MinWinFrame[i+1].flash:Hide()
			end
			normalchat = normalchat + 1
		end
	end
end

function Friend_IMWindowMin_Pop(index)
	DataPool:PopMinWindow(g_MinWinFrame[index].nType , g_MinWinFrame[index].id ,g_MinWinFrame[index].sName ,g_MinWinFrame[index].sRemark)
end

function Friend_IMWindowMin_PopCY(index)
	g_MinWinFrame[index].ctrl:Hide()
	g_MinWinFrame[index].flash:Hide()
	Helper:SendMessage(95787)
end

function Friend_IMWindowMin_PopGMChat(index)
	g_MinWinFrame[index].ctrl:Hide()
	g_MinWinFrame[index].flash:Hide()

	if g_MinWinType == 1 then
		PushEvent("GMCHAT_CONNECTINFO_OPEN")
	elseif g_MinWinType == 2 then
		PushEvent("GMCHAT_CHATWND_OPEN")
	end
	if index == 11 then --GS聊天
		if g_isGSMINIMOpenType == 0 then
			PushEvent("OPEN_GSIM",0)
		elseif g_isGSMINIMOpenType == 1 then
			PushEvent("OPEN_GSIM_NEW",0)
		end
		g_isGSMINIMOpen = 0
	end
end
