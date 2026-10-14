-- 过渡界面，更新公告、排行榜、服务器编年史

local g_Updatetransition_Frame_UnifiedPosition;

function Updatetransition_PreLoad()
	this:RegisterEvent("OPEN_WINDOW");
	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Updatetransition_OnLoad()
    g_Updatetransition_Frame_UnifiedPosition=Updatetransition_Frame:GetProperty("UnifiedPosition");
end

function Updatetransition_OnEvent(event)
	if(event == "OPEN_WINDOW") then
		if( arg0 == "UpdatetransitionWindow") then
			--如果已经显示就应该关掉
			if ( this:IsVisible() ) then
			   this:Hide();
			   return;
			end
			this:Show();
		end
	
	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "UpdatetransitionWindow") then
			this:Hide();
		end	
		
	elseif (event == "ADJEST_UI_POS" ) then
		Updatetransition_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Updatetransition_Frame_On_ResetPos()		
	end
	
end

-- 排行榜
function OnRankingClicked()
	Helper:GotoPaihang();
end

-- 更新公告
function Updatetransition_OnUpdateBtnClicked()
	Helper:GotoRecUpdate();
end

-- -- 服务器编年史
-- function OnAnnalsClicked()
-- 	OpenWindow("ServerChronicle");
-- end

function Updatetransition_Frame_On_ResetPos()
  Updatetransition_Frame:SetProperty("UnifiedPosition", g_Updatetransition_Frame_UnifiedPosition);
end