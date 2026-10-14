
local locTarSceneName = nil;


function SceneTransB_PreLoad()
	this:RegisterEvent("OPEN_SCENETRANSB_WAITTIME");
	this:RegisterEvent("LEFTTRANSBWAITTIME_CHANGE");
	this:RegisterEvent("CLOSE_SCENETRANSB_WAITTIME");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function SceneTransB_OnLoad()

end

function SceneTransB_OnEvent(event)
	if ( event == "OPEN_SCENETRANSB_WAITTIME") then
		if( this:IsVisible() ) then
			return;
		else
			locTarSceneName = arg0;
			SceneTransB_WaitTime_Open();
		end
	elseif(event == "LEFTTRANSBWAITTIME_CHANGE") then
		if( this:IsVisible() ) then
			SceneTransB_UpdateLeftTime(tonumber(arg0));
		end
	elseif(event == "CLOSE_SCENETRANSB_WAITTIME") then
		if( this:IsVisible() ) then
			DataPool:SetCanUseHotKey(1)
			this:Hide();
		end
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		if( this:IsVisible() ) then
			DataPool:SetCanUseHotKey(1)
			this:Hide();
		end
	end
end

function SceneTransB_WaitTime_Open()

	local lefttime =DataPool:GetTransBWaitTime();
	SceneTransB_UpdateLeftTime(tonumber(lefttime));

	this:Show();

	DataPool:SetCanUseHotKey(0)
end

function SceneTransB_UpdateLeftTime(lefttime)
	local iTime = math.floor( lefttime / 1000 )
	local iSec = math.mod( iTime, 60 )
	local iMin = math.floor( iTime / 60 )

	local strTemp = ScriptGlobal_Format("#{TFJCGZ_20200817_07}", iMin, iSec, locTarSceneName)
	SceneTransB_TargetScene:SetText(strTemp);
end
