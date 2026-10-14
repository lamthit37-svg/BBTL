-- 玩家血条积分UI 最小化UI
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;


function NoDiffMatch_Score_Tiny_PreLoad()

	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("CORPS_SHOW_MINI_BOX_2018")
	this:RegisterEvent("CORPS_COPYDATA_FIRST_TIME_2018",false)
	this:RegisterEvent("SHOW_PK_RESULT_2018")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NoDiffMatch_Score_Tiny_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_Score_Tiny_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_Score_Tiny_Frame:GetProperty("UnifiedYPosition");
end

function NoDiffMatch_Score_Tiny_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_Score_Tiny_ResetPos()

	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	elseif( event == "CORPS_SHOW_MINI_BOX_2018" ) then
		this:Show();
	elseif(event == "CORPS_COPYDATA_FIRST_TIME_2018"	) then
		--保证两个UI是互斥显示的。
		if (this:IsVisible())  then
			this:Hide()
		end
	elseif(event == "SHOW_PK_RESULT_2018")	 then
		this:Hide()
	end
end

function NoDiffMatch_Score_Tiny_ResetPos()

	NoDiffMatch_Score_Tiny_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_Score_Tiny_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);

end

function NoDiffMatch_Score_Tiny_OnShowNormalUI()
	this:Hide()
	PushEvent( "SHOW_FULLDATA_BOX_2018", 1 )
end
