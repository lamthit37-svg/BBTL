local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_NotifyIdx = 0 --默认提示为空 看不到
local g_NotifyMsg =
{
	[1] = {freshIdx=50,str = "#{FQBS_140508_5}"}, --6月19日至6月26日宝石理财计划期间，可以通过分期付款的方式来购买5级、6级、7级宝石。
	[2] = {freshIdx=51,str = "#{FQBS_140508_6}"}, --您当前通过分期付款购买的宝石中，有一个即将失效，请尽快还款以保证宝石的正常使用。
	[3] = {freshIdx=52,str = "#{FQBS_140508_7}"}, --您当前通过分期付款购买的宝石中，有一个已经失效了，请尽快还款以保证宝石的正常使用。
}
local g_BPG_flashdown = 10*1000; --10s闪烁

function BudgetPlanGem_button_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("PLAYER_ENTERING_WORLD");

	this:RegisterEvent("UI_SHOW_2DHEAD")	--显示2D头像

end

function BudgetPlanGem_button_OnLoad()
	BudgetPlanGem_button_UpdateShow2DHead()
	-- 保存界面的默认相对位置
	--g_Frame_UnifiedXPosition	= BudgetPlanGem_button_AnNiu_Frame:GetProperty("UnifiedXPosition");
	--g_Frame_UnifiedYPosition	= BudgetPlanGem_button_AnNiu_Frame:GetProperty("UnifiedYPosition");
	BudgetPlanGem_button_Animate:Hide()
	g_NotifyIdx = 0
end

function BudgetPlanGem_button_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BudgetPlanGem_button_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BudgetPlanGem_button_ResetPos()

	elseif (event == "UI_COMMAND" and tonumber(arg0) == 201405201 ) then

		g_NotifyIdx = Get_XParam_INT(0)
		if g_NotifyIdx ~= nil and g_NotifyMsg[g_NotifyIdx] ~= nil then
			--BudgetPlanGem_button:SetToolTip(g_NotifyMsg[g_NotifyIdx].str)
			--开启tips
			local fX = 0
			local fY = 0

			fX, fY = this:GetChildOffset("BudgetPlanGem_button_BTN")

			fX = fX + 13
			fY = fY + 13

			OpenFreshManGuide(1, g_NotifyMsg[g_NotifyIdx].freshIdx , fX, fY, "BudgetPlanGem_button", "southeast")

			BudgetPlanGem_button_Animate:Show()
			SetTimer("BudgetPlanGem_button", "BudgetPlanGem_button_g_BPG_flashdown()",g_BPG_flashdown)
		end
		BudgetPlanGem_button_UpdateShow2DHead()
		this:Show()
	elseif ( event == "PLAYER_ENTERING_WORLD") then

		BudgetPlanGem_button_UpdateShow2DHead()
		return

	elseif ( event == "UI_SHOW_2DHEAD") then

		BudgetPlanGem_button_UpdateShow2DHead()
		return

	end
end

function BudgetPlanGem_button_g_BPG_flashdown()
	BudgetPlanGem_button_Animate:Hide();
	KillTimer("BudgetPlanGem_button_g_BPG_flashdown()");
end


--邮件提示
function BudgetPlanGem_button_BTN_Clicked()
	--g_NotifyIdx = 0
	BudgetPlanGem_button_g_BPG_flashdown()
	CloseFreshManGuide()
	if  Player:GetData("LEVEL") < 15 then
		PushDebugMessage("#{FQBS_140508_8}") --当你的等级达到15级时，才能使用该功能。
		return
	end
	BudgetPlanGem:AskBudgetPlanGemInfo()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BudgetPlanGem_button_ResetPos()
	--BudgetPlanGem_button_AnNiu_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	--BudgetPlanGem_button_AnNiu_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
	BudgetPlanGem_button_UpdateShow2DHead()
end


function BudgetPlanGem_button_UpdateShow2DHead()
    if SystemSetup:IsClassic() == 1 then
		BudgetPlanGem_button_AnNiu_Frame:SetProperty("UnifiedPosition", "{{0.000000,233.000000},{0.000000,54.000000}}");
    end
end




