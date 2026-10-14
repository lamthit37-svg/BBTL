local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;


function BangHui_Fight_Score_Tiny_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("BHSDZD_SHOW_MINI_BOX")
	this:RegisterEvent("BHSDZD_COPYDATA_FIRST_TIME")
	this:RegisterEvent("BHSDZD_SHOW_PK_RESULT")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BangHui_Fight_Score_Tiny_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BangHui_Fight_Score_Tiny_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BangHui_Fight_Score_Tiny_Frame:GetProperty("UnifiedYPosition");
end

function BangHui_Fight_Score_Tiny_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BangHui_Fight_Score_Tiny_ResetPos()

	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	elseif( event == "BHSDZD_SHOW_MINI_BOX" ) then
		this:Show();
	elseif(event == "BHSDZD_COPYDATA_FIRST_TIME"	) then
		--保证两个UI是互斥显示的。
		if (this:IsVisible())  then
			this:Hide()
		end
	elseif(event == "BHSDZD_SHOW_PK_RESULT")	 then
		this:Hide()
	end
end

function BangHui_Fight_Score_Tiny_ResetPos()

	BangHui_Fight_Score_Tiny_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BangHui_Fight_Score_Tiny_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);

end

function BangHui_Fight_Score_Tiny_OnShowNormalUI()
	this:Hide()
	PushEvent( "BHSDZD_SHOW_FULLDATA_BOX", 1 )
end