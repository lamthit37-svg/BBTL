
--===============================================
-- OnLoad()
--===============================================
function ScrollInfo_PreLoad()

	--this:RegisterEvent("GAMELOGIN_OPEN_COUNT_INPUT");
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false);
	this:RegisterEvent("SET_SCROLLINFO",true);
	this:RegisterEvent("HIDE_TLBB_MAIN",false);
	this:RegisterEvent("UI_SHOW_2DHEAD",true)	--显示2D头像
	this:RegisterEvent("SCENE_TRANSED",false)
	this:RegisterEvent("SET_SCROLLINFO_FIRST",true);
	this:RegisterEvent("HIDE_THIS_UI",true)				-- 隐藏界面

end

function ScrollInfo_OnLoad()
	ScrollInfo_FrameBak1:Show();
	ScrollInfo_Background_RedLine1:Show();
	ScrollInfo_Background_RedLine2:Show();
end

--===============================================
-- OnEvent()
--===============================================
function ScrollInfo_OnEvent(event)

	if ( event == "SET_SCROLLINFO" ) then
		--AxTrace( 0,0,"SetScrollInfo = "..arg0 );
		local nCurScene = GetSceneID()
		if (nCurScene < 303 or nCurScene >306 )  then
			ScrollInfo_Frame:SetScrollInfo( arg0,arg1 );
		else
			ScrollInfo_Frame:Clear();
		end
	elseif ( event == "SET_SCROLLINFO_FIRST" ) then
		--AxTrace( 0,0,"SetScrollInfo = "..arg0 );
		local nCurScene = GetSceneID()
		if (nCurScene < 303 or nCurScene >306 )  then
			ScrollInfo_Frame:SetScrollInfoFirst( arg0,arg1 );
		else
			ScrollInfo_Frame:Clear();
		end
	elseif( event == "SCENE_TRANSED") then
		local nCurScene = GetSceneID()
		if (nCurScene >= 303 and nCurScene <=306 )  then
			ScrollInfo_Frame:Clear();
		end
	elseif( event == "PLAYER_ENTERING_WORLD" ) then
		--AxTrace( 0,0,"Show ScrollInfo" );
		--this:Show();
	elseif( event =="GAMELOGIN_OPEN_COUNT_INPUT" ) then
		--AxTrace( 0,0,"Show ScrollInfo" );
		--this:Show();
	elseif(event =="HIDE_TLBB_MAIN" ) then
		ScrollInfo_Frame:Clear();
	end

	if ( event == "UI_SHOW_2DHEAD" ) then
		ScrollInfo_UpdateShow2DHead();
		return;
	end

	if event == "HIDE_THIS_UI" then
		if this:IsVisible() then
			this:Hide()
		else
			this:Show()
		end
	end
end

function ScrollInfo_UpdateShow2DHead()
	ScrollInfo_FrameBak:SetProperty("UnifiedPosition", "{{0.000000,170.000000},{0.000000,99.000000}}");
end
