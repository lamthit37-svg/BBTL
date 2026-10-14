
local g_PlayerZhengyou_Frame_UnifiedPosition;
--OnLoad

function PlayerZhengyou_PreLoad()
	this:RegisterEvent("OPEN_WINDOW");
	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function PlayerZhengyou_OnLoad()
    PlayerZhengyou_DragTitle:SetText("#{ZYPT_081103_099}");
    g_PlayerZhengyou_Frame_UnifiedPosition=PlayerZhengyou_Frame:GetProperty("UnifiedPosition");
end

function PlayerZhengyou_OnEvent(event)
	if(event == "OPEN_WINDOW") then
		if( arg0 == "ZhengyouWindow") then
			--如果已经显示就应该关掉
			if ( this:IsVisible() ) then
			   this:Hide();
			   return;
			end
			this:Show();
		end
	
	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "ZhengyouWindow") then
			this:Hide();
		end	
		
	elseif (event == "ADJEST_UI_POS" ) then
		PlayerZhengyou_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PlayerZhengyou_Frame_On_ResetPos()
		
	end
	
end

function OnPlayerZhengyouClicked()
  CloseWindow("Show_Pet_Friends");
	OpenWindow("PlayerZhengyouPTWindow");
end

function OnPetZhengyouClicked()
  CloseWindow("PlayerZhengyouPTWindow");
	OpenWindow("Show_Pet_Friends");
end

--function OnTeamBoardClicked()
--  CloseWindow("PlayerZhengyouPTWindow");
--	OpenWindow("TeamPTWindow");
--end

function PlayerZhengyou_Frame_On_ResetPos()
  PlayerZhengyou_Frame:SetProperty("UnifiedPosition", g_PlayerZhengyou_Frame_UnifiedPosition);
end