

function Assistant_PreLoad()
	this:RegisterEvent( "HIDE_TLBB_MAIN", true )
	this:RegisterEvent( "OPEN_MINMAP" , true )
	this:RegisterEvent( "BATTLE_ASSIST_EVENT" , true )
	this:RegisterEvent( "HIDE_ON_SCENE_TRANSED", true )
end


function Assistant_OnLoad()

end

function Assistant_SetState( nState )
	if not nState or nState == 0 then
		Assistant_Icon:SetProperty("PushedImage","set:RosebangUI image:Rose_Pushed")
		Assistant_Icon:SetProperty("NormalImage","set:RosebangUI image:Rose_Normal")
		Assistant_Icon:SetProperty("HoverImage","set:RosebangUI image:Rose_Hover")
		Assistant_Icon:SetProperty("DisabledImage","set:RosebangUI image:Rose_Pushed")
	else
		Assistant_Icon:SetProperty("PushedImage","set:ValentinePoem1 image:ValentinePoem1_04_Pushed")
		Assistant_Icon:SetProperty("NormalImage","set:ValentinePoem1 image:ValentinePoem1_04_Normal")
		Assistant_Icon:SetProperty("HoverImage","set:ValentinePoem1 image:ValentinePoem1_04_Hover")
		Assistant_Icon:SetProperty("DisabledImage","set:ValentinePoem1 image:ValentinePoem1_04_Disable")
	end
end

function Assistant_Update()
	if BattleAssist:IsWorking() == "true" then
		Assistant_SetState(1)
	else
		Assistant_SetState(0)
	end
end

function Assistant_OnEvent( event )
	if event == "HIDE_TLBB_MAIN" then
		this:Hide()
		return
	elseif event == "OPEN_MINMAP" then
		Assistant_Update()
		this:Show()
		return
	elseif event == "BATTLE_ASSIST_EVENT" then
		Assistant_Update()
		return
	end
end

function Assistant_OnClick()
	local b = BattleAssist:IsWorking()
	if b == "true" then
		BattleAssist:Stop()
	else
		BattleAssist:Start("Farm")
	end
end
