-- 击杀播报UI
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_Image = {
						[1] = "set:BW_Match5  image:Killnamered",
						[2] = "set:BW_Match5  image:Killnameblue",
}

local g_Timer = -1

function BW_Match_DoubleKill_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED2018",false)
	this:RegisterEvent("BWTROOPS_KILL_SHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

function BW_Match_DoubleKill_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BW_Match_DoubleKill:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BW_Match_DoubleKill:GetProperty("UnifiedYPosition");
	BW_Match_DoubleKill_CtrlList_InitData()
	g_Timer = 3
	
end

function BW_Match_DoubleKill_CtrlList_InitData()

	BW_Match_DoubleKill_Left_Text:SetText("")
	BW_Match_DoubleKill_Right_Text:SetText("")
	
end

function BW_Match_DoubleKill_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BW_Match_DoubleKill_ResetPos()
	elseif( event == "BWTROOPS_KILL_SHOW") then
		--读取数据显示
		--PushDebugMessage("11111")
		if g_Timer > 0 then
			KillTimer("BW_Match_DoubleKill_Timer()")
		end
		g_Timer = 3
		BW_Match_DoubleKill_CtrlList_InitData()
		if tonumber(arg0) == 0 then
			BW_Match_DoubleKill_Left:SetProperty("Image", g_Image[1])
			BW_Match_DoubleKill_Right:SetProperty("Image", g_Image[2])
		elseif tonumber(arg0) == 1 then
			BW_Match_DoubleKill_Left:SetProperty("Image", g_Image[2])
			BW_Match_DoubleKill_Right:SetProperty("Image", g_Image[1])
		end
		BW_Match_DoubleKill_Left_Text:SetText(arg1)
		BW_Match_DoubleKill_Right_Text:SetText(arg2)
		SetTimer("BW_Match_DoubleKill","BW_Match_DoubleKill_Timer()", 1*1000)
		this:Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BW_Match_DoubleKill_CtrlList_InitData()
		this:Hide()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BW_Match_DoubleKill_ResetPos()
	BW_Match_DoubleKill:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BW_Match_DoubleKill:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BW_Match_DoubleKill_Timer()
	g_Timer = g_Timer - 1 
	if g_Timer == 0 then
		KillTimer("BW_Match_DoubleKill_Timer()")
		this:Hide()
	end
end
