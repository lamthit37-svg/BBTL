local g_ChatSign_UnifiedPosition
local g_ChatSign_BarList = {}
local g_ChatSign_CurSelect = -1
local g_ChatSign_SelectID = -1
local g_ChatSign_MaxIndex = -1

function ChatSign_PreLoad()
	this:RegisterEvent("OPEN_CHATSYMBOL",true)
	this:RegisterEvent("UPDATE_CHATSYMBOL",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end


function ChatSign_OnLoad()
	g_ChatSign_UnifiedPosition=ChatSign_Frame:GetProperty("UnifiedPosition")
	g_ChatSign_CurSelect = -1
	g_ChatSign_SelectID = -1
	g_ChatSign_MaxIndex = -1
end

function ChatSign_On_ResetPos()
	ChatSign_Frame:SetProperty("UnifiedPosition", g_ChatSign_UnifiedPosition)
end

function ChatSign_OnEvent(event)
	if (event == "OPEN_CHATSYMBOL" ) then
		this:TogleShow()
		ChatSign_Clear()
		ChatSign_Update()
	elseif (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		ChatSign_On_ResetPos()
	elseif (event == "UPDATE_CHATSYMBOL" ) then
		ChatSign_Clear()
		ChatSign_Update()
	end
	
end

function ChatSign_Update()
	ChatSign_List:Clear()
	g_ChatSign_BarList={}	
	--显示当前标识
	local curID = Player:LuaFnGetChatSymbolData("CURID")
	local curIdx = 1
	if curID > 0 then		
		ChatSign_SetItem(curIdx, curID, 1)
		curIdx = curIdx + 1
	end
	
	--显示已激活的标识 
	local idMax = Player:LuaFnGetChatSymbolData("TABLE_IDMAX")
	for x=1,idMax do
		local szName,szComCon,isActive,tblPeriod,periodDur,menpaiID,szImage,szAnimate,autoGet,imageIdx,symbolMark,markImage = Player:LuaFnGetChatSymbolData("INFO_BYID",x)		
		local isctShow,n2026show = Player:LuaFnGetChatSymbolData("SHOW_BYID",x)
		local isShow = 1
		if Player:GetData("IsOriginalJD") == 1 and isctShow == 0 then
			isShow = 0
		elseif Player:GetData("IsOriginalJD") ~= 1 and isctShow == 2 then
			isShow = 0
		end
		if Player:GetData("Is2606S") == 1 and n2026show == 0 then
			isShow = 0
		elseif Player:GetData("Is2606S") ~= 1 and n2026show == 2 then
			isShow = 0
		end
		if szName ~= nil and x ~= curID and isActive == 1 and isShow == 1 then
			ChatSign_SetItem(curIdx, x, 2)
			curIdx = curIdx + 1
		end
	end
	
	--显示未激活的标识 
	for x=1,idMax do
		local szName,szComCon,isActive,tblPeriod,periodDur,menpaiID,szImage,szAnimate,autoGet,imageIdx,symbolMark,markImage = Player:LuaFnGetChatSymbolData("INFO_BYID",x)
		local isctShow,n2026show = Player:LuaFnGetChatSymbolData("SHOW_BYID",x)
		local isShow = 1
		if Player:GetData("IsOriginalJD") == 1 and isctShow == 0 then
			isShow = 0
		elseif Player:GetData("IsOriginalJD") ~= 1 and isctShow == 2 then
			isShow = 0
		end
		if Player:GetData("Is2606S") == 1 and n2026show == 0 then
			isShow = 0
		elseif Player:GetData("Is2606S") ~= 1 and n2026show == 2 then
			isShow = 0
		end
		if x ~= curID and isActive == 0 and (menpaiID == -1 or menpaiID == Player:GetData("MEMPAI")) and isShow == 1 then
			ChatSign_SetItem(curIdx, x, 3)			
			curIdx = curIdx + 1
		end		
	end
end

function ChatSign_ItemClicked(curIdx, id)
	g_ChatSign_CurSelect = curIdx
	g_ChatSign_SelectID = id
	local szName,szComCon,isActive,tblPeriod,periodDur,menpaiID,szImage,szAnimate,autoGet,imageIdx = Player:LuaFnGetChatSymbolData("INFO_BYID",id)
	local curID = Player:LuaFnGetChatSymbolData("CURID")
	ChatSign_Info1_Text:SetText(ScriptGlobal_Format("#{LTBS_230508_04}",szName))
	if tblPeriod <= 0 then
		if autoGet ~= 0 then
			ChatSign_Info2_Text1:SetText("#{LTBS_230508_08}")
			ChatSign_Info2_Text2:SetText("")
		else
			ChatSign_Info2_Text1:SetText("#{LTBS_230508_06}")
			ChatSign_Info2_Text2:SetText("")
		end
	else
		local periodStr=""
		local periodDay = 0
		local periodHour = 0
		periodDay = math.floor(tblPeriod/24)
		periodHour = math.mod(tblPeriod,24)
		
		if periodDay == 0 then
			periodStr=periodHour.."小时"
		elseif periodHour == 0 then
			periodStr=periodDay.."天"
		else
			periodStr=periodDay.."天"..periodHour.."小时"
		end
		ChatSign_Info2_Text1:SetText("#cfff263"..periodStr)
		
		if isActive == 1 and periodDur > 0 then
			local year,mon,day = ANSI2TM(periodDur)
			local hr,min,sec = Lua_ANSI2TMHMS(periodDur)
			local strDur = ScriptGlobal_Format("#{LTBS_230508_09}",tostring(year),tostring(mon),tostring(day),tostring(hr))	
			ChatSign_Info2_Text2:SetText(strDur)
		else
			ChatSign_Info2_Text2:SetText("")
		end
	end		
	
	ChatSign_Info3_Text:SetText(ScriptGlobal_Format("#{LTBS_230508_11}",szComCon))	
	ChatSign_ChatSignAnimate:Hide()
	ChatSign_ChatSignAnimate2:Hide()
	if imageIdx == 0 then
		ChatSign_ChatSignAnimate:Show()
		ChatSign_ChatSignAnimate:SetProperty("Animate", szAnimate)
	else
		ChatSign_ChatSignAnimate2:Show()
		ChatSign_ChatSignAnimate2:SetProperty("Animate", szAnimate)
	end
	
	ChatSign_OK_DisabledTips:Hide()
	if isActive == 0 then
		ChatSign_OK:SetText("#{LTBS_230508_14}")
		ChatSign_OK:Disable()
		--ChatSign_OK:SetToolTip("#{LTBS_230508_46}")
		ChatSign_OK_DisabledTips:Show()
		ChatSign_OK_DisabledTips:SetToolTip("#{LTBS_230508_46}")
	elseif curID == id then
		ChatSign_OK:SetText("#{LTBS_230508_13}")
		ChatSign_OK:Enable()
		ChatSign_OK:SetToolTip("#{LTBS_230508_45}")
	else
		ChatSign_OK:SetText("#{LTBS_230508_12}")
		ChatSign_OK:Enable()
		ChatSign_OK:SetToolTip("#{LTBS_230508_44}")
	end
	
	for i = 1, g_ChatSign_MaxIndex do		
		if g_ChatSign_BarList[i] ~= nil then		
			if i == curIdx then
				g_ChatSign_BarList[i]:GetSubItem("ChatSign_ListItemCheck"):SetCheck(1)
			else
				g_ChatSign_BarList[i]:GetSubItem("ChatSign_ListItemCheck"):SetCheck(0)
			end
		end
	end
end

function ChatSign_SetItem(curIdx, id, tp)
	if g_ChatSign_MaxIndex < curIdx then
		g_ChatSign_MaxIndex = curIdx
	end
	
	local szName,szComCon,isActive,tblPeriod,periodDur,menpaiID,szImage,szAnimate,autoGet,imageIdx,symbolMark,markImage = Player:LuaFnGetChatSymbolData("INFO_BYID",id)
	local bar = ChatSign_List:AddChild("ChatSign_ListItem")
	bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
	g_ChatSign_BarList[curIdx] = bar	
	bar:GetSubItem("ChatSign_ListItemCheck"):SetEvent("MouseLButtonDown", string.format("ChatSign_ItemClicked(%d, %d)", curIdx, id))
	if g_ChatSign_CurSelect == -1 then		
		ChatSign_ItemClicked(curIdx, id)
	end
	
	bar:GetSubItem("ChatSign_ListItem_ChatSignImage"):Hide()
	bar:GetSubItem("ChatSign_ListItem_ChatSignImage2"):Hide()
	if imageIdx == 0 then
		bar:GetSubItem("ChatSign_ListItem_ChatSignImage"):Show()
		bar:GetSubItem("ChatSign_ListItem_ChatSignImage"):SetProperty("Image", szImage or "")
	else
		bar:GetSubItem("ChatSign_ListItem_ChatSignImage2"):Show()
		bar:GetSubItem("ChatSign_ListItem_ChatSignImage2"):SetProperty("Image", szImage or "")
	end

	if symbolMark == 0 then
		bar:GetSubItem("ChatSign_ListItem_ChatSignMark"):Hide()
	else
		bar:GetSubItem("ChatSign_ListItem_ChatSignMark"):Show()
		bar:GetSubItem("ChatSign_ListItem_ChatSignMark"):SetProperty("Image", markImage or "")
	end
	
	if isActive == 1 then
		bar:GetSubItem("ChatSign_ListItem_ChatSignLocked"):Hide()
	else
		bar:GetSubItem("ChatSign_ListItem_ChatSignLocked"):Show()
	end
	
	if tp == 1 then
		bar:GetSubItem("ChatSign_ListItem_Used"):Show()
	else
		bar:GetSubItem("ChatSign_ListItem_Used"):Hide()
	end
end

function ChatSign_OK_CLicked()
	local szName,szComCon,isActive,tblPeriod,periodDur,menpaiID,szImage,szAnimate,autoGet,imageIdx,symbolMark,markImage = Player:LuaFnGetChatSymbolData("INFO_BYID",g_ChatSign_SelectID)
	local curID = Player:LuaFnGetChatSymbolData("CURID")
	local isctShow,n2026show = Player:LuaFnGetChatSymbolData("SHOW_BYID",g_ChatSign_SelectID)
	
	if Player:GetData("IsOriginalJD") == 1 and isctShow == 0 then
		return
	elseif Player:GetData("IsOriginalJD") ~= 1 and isctShow == 2 then
		return
	end
	
	if Player:GetData("Is2606S") == 1 and n2026show == 0 then
		return
	elseif Player:GetData("Is2606S") ~= 1 and n2026show == 2 then
		return
	end
	
	if g_ChatSign_SelectID == curID then
		--取消佩戴
		if isActive == 0 then
			PushDebugMessage("#{LTBS_230508_15}")
			return
		end
		Player:LuaFnGetChatSymbolData("SET_CURSYMBOL",-1)
		PushDebugMessage(ScriptGlobal_Format("#{LTBS_230508_19}",szName))
		ChatSign_OK:SetText("#{LTBS_230508_12}")
	else
		--佩戴
		if isActive == 0 then
			PushDebugMessage("#{LTBS_230508_15}")
			return
		end
		Player:LuaFnGetChatSymbolData("SET_CURSYMBOL",g_ChatSign_SelectID)
		PushDebugMessage(ScriptGlobal_Format("#{LTBS_230508_17}",szName))
		ChatSign_OK:SetText("#{LTBS_230508_13}")
	end
end

function ChatSign_Clear()
	g_ChatSign_CurSelect = -1
	g_ChatSign_SelectID = -1
	ChatSign_List:Clear()
end

function ChatSign_OnClose()
	g_ChatSign_BarList={}
	ChatSign_Clear()
	this:Hide()
end
