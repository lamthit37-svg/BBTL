local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;


function BW_Match_FightMiNi_PreLoad()

	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("BWTROOPS_SHOW_MINI_BOX2018")
	this:RegisterEvent("BWTROOPS_COPYDATA_FIRST_TIME2018")
	this:RegisterEvent("BWTROOPS_RESULT_SHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BW_Match_FightMiNi_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BW_Match_FightMiNi_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BW_Match_FightMiNi_Frame:GetProperty("UnifiedYPosition");
end

function BW_Match_FightMiNi_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BW_Match_FightMiNi_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		BW_Match_FightMiNi_ResetPos()

	--elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
	--	this:Hide();
	elseif( event == "BWTROOPS_SHOW_MINI_BOX2018" ) then
		this:Show();
	elseif(event == "BWTROOPS_COPYDATA_FIRST_TIME2018"	) then
		--保证两个UI是互斥显示的。
		if (this:IsVisible())  then
			this:Hide()
		end
	elseif(event == "BWTROOPS_RESULT_SHOW")	 then
		this:Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
	
end

function BW_Match_FightMiNi_ResetPos()

	BW_Match_FightMiNi_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BW_Match_FightMiNi_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);

end

function BW_Match_FightMiNi_OnShowNormalUI()
	this:Hide()
	PushEvent( "BWTROOPS_SHOW_FULLDATA_BOX2018" )
end