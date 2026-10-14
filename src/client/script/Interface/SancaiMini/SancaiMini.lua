local g_bSingleFuBen = 0;
local g_Frame_UnifiedXPosition_SancaiMini;
local g_Frame_UnifiedYPosition_SancaiMini;

function SancaiMini_PreLoad()
	this:RegisterEvent("SCENE_TRANSED")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("3HUAN_OPEN_UI_MINI")
	this:RegisterEvent("3HUAN_OPEN_UI_RESULT")
	this:RegisterEvent("OPEN_SINGLESANCAIXIAGU_MINI_UI")	-- 老三环单人副本界面
end

function SancaiMini_OnLoad()
	g_Frame_UnifiedXPosition_SancaiMini	= SancaiMini_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition_SancaiMini	= SancaiMini_Frame:GetProperty("UnifiedYPosition");	
end


function SancaiMini_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
			SancaiMini_ResetPos()		
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
			SancaiMini_ResetPos()
	elseif( event == "SCENE_TRANSED" ) then
		local curSceneID = GetSceneID()
		if (curSceneID ==653) then
			this:Show()
			PushEvent("3HUAN_OPEN_UI_RESULT",  1 )
		else
			this:Hide()
			PushEvent("3HUAN_OPEN_UI_RESULT",  0 )
		end
	elseif( event == "3HUAN_OPEN_UI_MINI" ) then
		g_bSingleFuBen = 0;
		local operate = tonumber(arg0)
		local step = tonumber(arg1)
		if operate == 1 then
			if step == 1 then
				SancaiMini_PageHeader:SetText("#{LSHYH_150210_109}")
			elseif step == 2 then
				SancaiMini_PageHeader:SetText("#{LSHYH_150210_110}")
			elseif step == 3 then
				SancaiMini_PageHeader:SetText("#{LSHYH_150210_111}")
			end
			this:Show()
		else
			this:Hide()
		end
	elseif ( event == "OPEN_SINGLESANCAIXIAGU_MINI_UI" ) then
		g_bSingleFuBen = 1;
		local operate = tonumber( arg0 );
		local step = tonumber( arg1 );
		if operate == 1 then
			if step == 1 then
				SancaiMini_PageHeader:SetText("#{LSHYH_150210_109}")
			elseif step == 2 then
				SancaiMini_PageHeader:SetText("#{LSHYH_150210_110}")
			elseif step == 3 then
				SancaiMini_PageHeader:SetText("#{LSHYH_150210_111}")
			end
			this:Show()
		else
			this:Hide()
		end
	end
	
end

function SancaiMini_ResetPos()
	SancaiMini_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition_SancaiMini);
	SancaiMini_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition_SancaiMini);
end

function SancaiMini_Cliecked()
	if ( g_bSingleFuBen == 0 ) then
		PushEvent("3HUAN_OPEN_UI_RESULT",  1 )
	elseif ( g_bSingleFuBen == 1 ) then
		PushEvent( "OPEN_SINGLESANCAIXIAGU_ORIGINAL_UI" );
	end
	this:Hide()
end
