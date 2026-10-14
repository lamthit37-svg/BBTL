
function QiXi_PVPTimeMini_PreLoad()
	this:RegisterEvent("QIXI_PVP_MINI");
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

function QiXi_PVPTimeMini_OnLoad()
end

function QiXi_PVPTimeMini_OnEvent(event)
	if (event=="SCENE_TRANSED") then
		this:Hide()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif (event=="QIXI_PVP_MINI") then
		
		if arg0=="0" then
			this:Show()
		else
			this:Hide()
		end
	end
end

function QiXi_PVPTimeMini_Open()
	this:Hide()
	PushEvent("QIXI_PVP_MINI",1)
end

