-- 
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_GameItemImage = {
	[1] = "set:ZhouchangPVE2 image:ZhouchangPVE_ZBF_B",
	[2] = "set:ZhouchangPVE2 image:ZhouchangPVE_ZBS_B",
	[3] = "set:ZhouchangPVE2 image:ZhouchangPVE_SSL_B",
}

local g_BK = {
	[1] = "set:RouGe1 image:Congratulation",
	[2] = "set:RouGe1 image:Success",
}

local g_GameItemText = {
	[1] = "#{FHCL_240708_459}",
	[2] = "#{FHCL_240708_460}",
	[3] = "#{FHCL_240708_461}",
}

local g_GameItemTipsText = {
	[1] = "#{FHCL_240708_456}",
	[2] = "#{FHCL_240708_457}",
	[3] = "#{FHCL_240708_458}",
}

local g_Timer = -1

function ZhouchangPVE_Show_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND",true)

end

function ZhouchangPVE_Show_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= ZhouchangPVE_Show_MainFrame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= ZhouchangPVE_Show_MainFrame:GetProperty("UnifiedYPosition");
	
	g_Timer = 3
	
end



function ZhouchangPVE_Show_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		ZhouchangPVE_Show_ResetPos()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 331105007  ) then
		local nGameItem  = Get_XParam_INT(0) 
		if g_GameItemImage[nGameItem] ~= nil then
			ZhouchangPVE_Show_Client1_Image:SetProperty("Image", g_GameItemImage[nGameItem])
			ZhouchangPVE_Show_Client1_Image:SetToolTip(g_GameItemTipsText[nGameItem])
			ZhouchangPVE_Show_Client1_Image:Show()
			ZhouchangPVE_Show_Client1_Text:SetText(g_GameItemText[nGameItem])
			ZhouchangPVE_Show_Client1_Text:Show()
			ZhouchangPVE_Show_Client2_Text:Hide()
			ZhouchangPVE_Show_BK:SetProperty("Image", g_BK[1])
			this:Show()
		end
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 331105011  ) then
		local nPoints = Get_XParam_INT(0)	
		ZhouchangPVE_Show_Client1_Image:Hide()
		ZhouchangPVE_Show_Client1_Text:Hide()
		ZhouchangPVE_Show_Client2_Text:Show()
		ZhouchangPVE_Show_BK:SetProperty("Image", g_BK[2])
		ZhouchangPVE_Show_Client2_Text:SetText(ScriptGlobal_Format("#{FHCL_240708_489}", nPoints))
		this:Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ZhouchangPVE_Show_ResetPos()
	ZhouchangPVE_Show_MainFrame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ZhouchangPVE_Show_MainFrame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function ZhouchangPVE_Show_Confirm()
	this:Hide()
end

