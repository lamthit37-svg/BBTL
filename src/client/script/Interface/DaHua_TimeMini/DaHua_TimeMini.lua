
function DaHua_TimeMini_PreLoad()
	this:RegisterEvent("QIXIPVE_XXS_MINI");
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

function DaHua_TimeMini_OnLoad()
end

function DaHua_TimeMini_OnEvent(event)
	if (event=="SCENE_TRANSED") then
		this:Hide()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif (event=="QIXIPVE_XXS_MINI") then
		if arg0=="0" then
			this:Show()
		end
	end
end

function DaHua_TimeMini_Open()
	this:Hide()
	PushEvent("QIXIPVE_XXS_MINI",1)
end

