

function WuLin_Anger_PreLoad()
	this:RegisterEvent("REFRESH_SONGLIAOWAR_SINGLE_SCORE");
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
	this:RegisterEvent("SONGLIAOSINGLE_MINI");
	this:RegisterEvent("UI_COMMAND");
end

function WuLin_Anger_OnLoad()
end

function WuLin_Anger_OnEvent(event)
	if (event=="SCENE_TRANSED") then
		WuLin_Anger_Client_Progress:SetProgress(0)
		this:Hide()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20200302 then
		local nOpen = Get_XParam_INT(0)		
		local nProcess = Get_XParam_INT(1)		
		if nOpen ==  1 then
			this:Show()
		else
			this:Hide()
		end
		
		WuLin_Anger_Client_Progress:SetProgress(nProcess,100)
	end
end
