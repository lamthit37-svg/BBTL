
function MsgButton_MenpaiBook_PreLoad()
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK")		--用这个作为升级的事件
	this:RegisterEvent("UNIT_LEVEL")
	this:RegisterEvent("JOIN_NEW_MENPAI")
	this:RegisterEvent("UI_SHOW_2DHEAD")
	this:RegisterEvent("RESET_ALLUI")
	this:RegisterEvent("ON_SCENE_TRANS")
	this:RegisterEvent("ON_SERVER_TRANS")
	this:RegisterEvent("HIDE_THIS_UI")
	
	g_needpop = 0
end

function MsgButton_MenpaiBook_OnLoad()
end

function MsgButton_MenpaiBook_OnEvent(event)

	if IsZbs2018SpeicalServer() >= 1 then
		this:Hide()
		return
	end
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		return
	end
	if event == "UPDATE_WILLGET_MISSION_TRACK" then
		g_needpop = 1
	end

	if event == "UNIT_LEVEL" and arg0 == "player" then
		local level = Player:GetData("LEVEL")
		local menpai = Player:GetData("MEMPAI");
		if menpai == 9 then
			if level >= 10 then
				this:Show()
			end
			if level == 10 and g_needpop == 1 then
				local nPosX = tonumber(MsgButton_MenpaiBook_Frame:GetProperty("AbsoluteXPosition"))
				local nPosY = tonumber(MsgButton_MenpaiBook_Frame:GetProperty("AbsoluteYPosition"))
				local fX, fY = this:GetChildOffset("MsgButton_MenpaiBook_Frame_Button")
				local fH = tonumber(MsgButton_MenpaiBook_Frame_Button:GetProperty("AbsoluteHeight"))
				local fW = tonumber(MsgButton_MenpaiBook_Frame_Button:GetProperty("AbsoluteWidth"))
				fX = tonumber(fX + nPosX + fW - 5)
				fY = math.floor(tonumber(fY + nPosY + (fH * 0.5)))
				OpenFreshManGuideNew(1, fX, fY, fW, fH, 20, 3, "PlayerFrame")
			end
		end
		g_needpop = 0
	end
	
	if (event == "JOIN_NEW_MENPAI") then
		this:Hide()
	end
	
	if (event == "RESET_ALLUI") then
		this:Hide()
		g_needpop = 0
	end
	
	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" then
		local level = Player:GetData("LEVEL")
		local menpai = Player:GetData("MEMPAI")
		if menpai == 9 and level >= 10 then
			this:Show()
		end
		g_needpop = 0
	end
	
	if (event == "UI_SHOW_2DHEAD")  then
		MsgButton_MenpaiBook_UpdateShow2DHead()
	end
	
	if event == "HIDE_THIS_UI" then
		if this:IsVisible() then
			this:Hide()
		end
	end
	
end

function MsgButton_MenpaiBook_Frame_MenpaiClick()
	PushEvent("OPEN_WLBOOK")
end

function MsgButton_MenpaiBook_UpdateShow2DHead()
    if SystemSetup:IsClassic() == 1 then
		MsgButton_MenpaiBook_Frame:SetProperty("UnifiedPosition", "{{0.000000,3.000000},{0.000000,100.000000}}")
    end
end