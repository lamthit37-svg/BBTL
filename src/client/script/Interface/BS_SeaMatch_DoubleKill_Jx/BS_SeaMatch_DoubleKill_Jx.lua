-- 试剑天下击杀播报UI
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_Image = {
						[1] = "set:BW_Match5  image:Killnamered",
						[2] = "set:BW_Match5  image:Killnameblue",
}

local g_Timer = -1

function BS_SeaMatch_DoubleKill_Jx_PreLoad()

	this:RegisterEvent("SJTX_KILL_SHOW")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED2018",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

function BS_SeaMatch_DoubleKill_Jx_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BS_SeaMatch_DoubleKill_Jx_Jx:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BS_SeaMatch_DoubleKill_Jx_Jx:GetProperty("UnifiedYPosition");
	BS_SeaMatch_DoubleKill_Jx_CtrlList_InitData()
	g_Timer = 3
	
end

function BS_SeaMatch_DoubleKill_Jx_CtrlList_InitData()

	BS_SeaMatch_DoubleKill_Jx_Left_Text:SetText("")
	BS_SeaMatch_DoubleKill_Jx_Right_Text:SetText("")
	
end

function BS_SeaMatch_DoubleKill_Jx_OnEvent(event)
	if( event == "SJTX_KILL_SHOW") then
		local matchType = SJTX:LuaFnGetSJTXSceneMatchType()
		if matchType ~= 1 then
			return
		end
		--读取数据显示
		g_Timer = 3
		BS_SeaMatch_DoubleKill_Jx_CtrlList_InitData()
		if tonumber(arg0) == 0 then
			BS_SeaMatch_DoubleKill_Jx_Left:SetProperty("Image", g_Image[1])
			BS_SeaMatch_DoubleKill_Jx_Right:SetProperty("Image", g_Image[2])
		elseif tonumber(arg0) == 1 then
			BS_SeaMatch_DoubleKill_Jx_Left:SetProperty("Image", g_Image[2])
			BS_SeaMatch_DoubleKill_Jx_Right:SetProperty("Image", g_Image[1])
		end
		BS_SeaMatch_DoubleKill_Jx_Left_Text:SetText(arg1)
		BS_SeaMatch_DoubleKill_Jx_Right_Text:SetText(arg2)
		KillTimer("BS_SeaMatch_DoubleKill_Jx_Timer()")
		SetTimer("BS_SeaMatch_DoubleKill_Jx","BS_SeaMatch_DoubleKill_Jx_Timer()", 1000)
		this:Show()
	elseif( event == "ADJEST_UI_POS" ) then
		BS_SeaMatch_DoubleKill_Jx_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BS_SeaMatch_DoubleKill_Jx_CtrlList_InitData()
		this:Hide()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BS_SeaMatch_DoubleKill_Jx_ResetPos()
	BS_SeaMatch_DoubleKill_Jx_Jx:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BS_SeaMatch_DoubleKill_Jx_Jx:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BS_SeaMatch_DoubleKill_Jx_Timer()
	g_Timer = g_Timer - 1 
	--PushDebugMessage(g_Timer)
	if g_Timer == 0 then
		KillTimer("BS_SeaMatch_DoubleKill_Jx_Timer()")
		this:Hide()
	end
end
