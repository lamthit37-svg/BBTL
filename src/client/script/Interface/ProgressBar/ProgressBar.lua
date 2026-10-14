
function ProgressBar_PreLoad()
	this:RegisterEvent("PROGRESSBAR_SHOW", true);
	this:RegisterEvent("PROGRESSBAR_HIDE", false);
	this:RegisterEvent("PROGRESSBAR_WIDTH", false);
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false);
	this:RegisterEvent("PROGRESSBAR_BREAK", false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

function ProgressBar_OnLoad()
end

-- OnEvent
function ProgressBar_OnEvent(event)
	if ( event == "PROGRESSBAR_SHOW" ) then
		ProgressBar_Progress:SetText( arg0 );
		this:Show();
		ProgressBar_Progress:SetProperty( "SetFadeState","0" );
		return;
	elseif ( event == "PROGRESSBAR_HIDE" ) then
		Progress_Break();
		return;
	elseif ( event == "PROGRESSBAR_WIDTH" ) then
		ProgressBar_SetWidth(arg0);
		return;
	elseif ( event == "PLAYER_LEAVE_WORLD" ) then
		Progress_Break();
		return;
	elseif( event == "PROGRESSBAR_BREAK" ) then
		Progress_Break();
	end

	if event == "HIDE_ON_SCENE_TRANSED"  then
		this:Hide()
	end
end


function ProgressBar_SetWidth(arg0)
	if arg0 ~= nil then
		ProgressBar_Progress:SetProgress(tonumber(arg0) * 100, 100);
	end
end

function Progress_Break()
	ProgressBar_Progress:SetProperty( "SetFadeState","2" );
end

function Progress_close()
	this:Hide();
end
