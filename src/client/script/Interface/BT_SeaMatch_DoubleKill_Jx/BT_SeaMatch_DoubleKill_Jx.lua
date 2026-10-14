-- 试剑天下击杀播报UI
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_Image = {
						[1] = "set:BW_Match5  image:Killnamered",
						[2] = "set:BW_Match5  image:Killnameblue",
}

local g_Timer = -1

function BT_SeaMatch_DoubleKill_Jx_PreLoad()

	this:RegisterEvent("DFS_KILL_SHOW")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

function BT_SeaMatch_DoubleKill_Jx_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BT_SeaMatch_DoubleKill_Jx:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BT_SeaMatch_DoubleKill_Jx:GetProperty("UnifiedYPosition");
	BT_SeaMatch_DoubleKill_Jx_CtrlList_InitData()
	g_Timer = 3
	
end

function BT_SeaMatch_DoubleKill_Jx_CtrlList_InitData()

	BT_SeaMatch_DoubleKill_Jx_Left_Text:SetText("")
	BT_SeaMatch_DoubleKill_Jx_Right_Text:SetText("")
	
end

function BT_SeaMatch_DoubleKill_Jx_OnEvent(event)
	if( event == "DFS_KILL_SHOW") then
		local matchType = DFS:LuaFnGetDfsSceneMatchType()
		if matchType ~= 3 then
			return
		end
		--读取数据显示
		g_Timer = 3
		BT_SeaMatch_DoubleKill_Jx_CtrlList_InitData()
		if tonumber(arg0) == 0 then
			BT_SeaMatch_DoubleKill_Jx_Left:SetProperty("Image", g_Image[1])
			BT_SeaMatch_DoubleKill_Jx_Right:SetProperty("Image", g_Image[2])
		elseif tonumber(arg0) == 1 then
			BT_SeaMatch_DoubleKill_Jx_Left:SetProperty("Image", g_Image[2])
			BT_SeaMatch_DoubleKill_Jx_Right:SetProperty("Image", g_Image[1])
		end
		BT_SeaMatch_DoubleKill_Jx_Left_Text:SetText(arg1)
		BT_SeaMatch_DoubleKill_Jx_Right_Text:SetText(arg2)
		KillTimer("BT_SeaMatch_DoubleKill_Jx_Timer()")
		SetTimer("BT_SeaMatch_DoubleKill_Jx","BT_SeaMatch_DoubleKill_Jx_Timer()", 1000)
		this:Show()
	elseif( event == "ADJEST_UI_POS" ) then
		BT_SeaMatch_DoubleKill_Jx_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		BT_SeaMatch_DoubleKill_Jx_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BT_SeaMatch_DoubleKill_Jx_CtrlList_InitData()
		this:Hide()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BT_SeaMatch_DoubleKill_Jx_ResetPos()
	BT_SeaMatch_DoubleKill_Jx:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BT_SeaMatch_DoubleKill_Jx:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BT_SeaMatch_DoubleKill_Jx_Timer()
	g_Timer = g_Timer - 1 
	--PushDebugMessage(g_Timer)
	if g_Timer == 0 then
		KillTimer("BT_SeaMatch_DoubleKill_Jx_Timer()")
		this:Hide()
	end
end
