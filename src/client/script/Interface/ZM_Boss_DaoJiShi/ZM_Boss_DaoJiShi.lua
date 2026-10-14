-- 倒计时

function ZM_Boss_DaoJiShi_PreLoad()
	 this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end
local g_Timer = -1
function ZM_Boss_DaoJiShi_OnLoad()
	g_Timer = 3
end

function ZM_Boss_DaoJiShi_OnEvent(event)

	if event == "UI_COMMAND" and (tonumber(arg0) == 999029001 or tonumber(arg0) == 999029005) then
	   
		--SetTimer("ZM_Boss_DaoJiShi","ZM_Boss_DaoJiShi_Timer()", 1*1000)
		ZM_Boss_DaoJiShi_Animate_Time:Play(true)
		ZM_Boss_DaoJiShi_Animate_Time:Show()
		ZM_Boss_DaoJiShi_Animate_Start:Hide()
		ZM_Boss_DaoJiShi_Animate_End:Hide()
		ZM_Boss_DaoJiShi_ImageBK:Hide()
		this:Show()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 999029007  ) then
		if g_Timer > 0 then
			KillTimer("ZM_Boss_DaoJiShi_Timer()")
		end
		g_Timer = 3
		SetTimer("ZM_Boss_DaoJiShi","ZM_Boss_DaoJiShi_Timer()", 1*1000)
		ZM_Boss_DaoJiShi_Animate_Time:Play(false)
		ZM_Boss_DaoJiShi_Animate_Time:Show()
		ZM_Boss_DaoJiShi_Animate_Start:Show()
		ZM_Boss_DaoJiShi_Animate_End:Hide()
		ZM_Boss_DaoJiShi_ImageBK:Hide()
		this:Show()

	elseif( event == "UI_COMMAND" and tonumber(arg0) == 999029008  ) then
		if g_Timer > 0 then
			KillTimer("ZM_Boss_DaoJiShi_Timer()")
		end
		g_Timer = 3
	
		SetTimer("ZM_Boss_DaoJiShi","ZM_Boss_DaoJiShi_Timer()", 1*1000)
		ZM_Boss_DaoJiShi_Animate_Time:Play(false)
		ZM_Boss_DaoJiShi_Animate_Time:Show()
		ZM_Boss_DaoJiShi_Animate_Start:Hide()
		ZM_Boss_DaoJiShi_Animate_End:Show()
		ZM_Boss_DaoJiShi_ImageBK:Hide()
		this:Show()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 999030001  ) then
		if g_Timer > 0 then
			KillTimer("ZM_Boss_DaoJiShi_Timer()")
		end
		g_Timer = 6
	
		SetTimer("ZM_Boss_DaoJiShi","ZM_Boss_DaoJiShi_Timer()", 1*1000)
		ZM_Boss_DaoJiShi_Animate_Time:Play(false)
		ZM_Boss_DaoJiShi_Animate_Time:Hide()
		ZM_Boss_DaoJiShi_Animate_Start:Hide()
		ZM_Boss_DaoJiShi_Animate_End:Hide()
		ZM_Boss_DaoJiShi_ImageBK:Show()
		ZM_Boss_DaoJiShi_Text:SetText("#{ZMB_230124_235}")
		this:Show()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 999030002  ) then
		if g_Timer > 0 then
			KillTimer("ZM_Boss_DaoJiShi_Timer()")
		end
		g_Timer = 6
	
		SetTimer("ZM_Boss_DaoJiShi","ZM_Boss_DaoJiShi_Timer()", 1*1000)
		ZM_Boss_DaoJiShi_Animate_Time:Play(false)
		ZM_Boss_DaoJiShi_Animate_Time:Hide()
		ZM_Boss_DaoJiShi_Animate_Start:Hide()
		ZM_Boss_DaoJiShi_Animate_End:Hide()
		ZM_Boss_DaoJiShi_ImageBK:Show()
		ZM_Boss_DaoJiShi_Text:SetText("#{ZMB_230124_247}")
		this:Show()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 999030003  ) then
		if g_Timer > 0 then
			KillTimer("ZM_Boss_DaoJiShi_Timer()")
		end
		g_Timer = 6
	
		SetTimer("ZM_Boss_DaoJiShi","ZM_Boss_DaoJiShi_Timer()", 1*1000)
		ZM_Boss_DaoJiShi_Animate_Time:Play(false)
		ZM_Boss_DaoJiShi_Animate_Time:Hide()
		ZM_Boss_DaoJiShi_Animate_Start:Hide()
		ZM_Boss_DaoJiShi_Animate_End:Hide()
		ZM_Boss_DaoJiShi_ImageBK:Show()
		ZM_Boss_DaoJiShi_Text:SetText("#{ZMB_230124_248}")
		this:Show()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 999030004  ) then
		if g_Timer > 0 then
			KillTimer("ZM_Boss_DaoJiShi_Timer()")
		end
		g_Timer = 6
	
		SetTimer("ZM_Boss_DaoJiShi","ZM_Boss_DaoJiShi_Timer()", 1*1000)
		ZM_Boss_DaoJiShi_Animate_Time:Play(false)
		ZM_Boss_DaoJiShi_Animate_Time:Hide()
		ZM_Boss_DaoJiShi_Animate_Start:Hide()
		ZM_Boss_DaoJiShi_Animate_End:Hide()
		ZM_Boss_DaoJiShi_ImageBK:Show()
		ZM_Boss_DaoJiShi_Text:SetText("#{ZMB_230124_249}")
		this:Show()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 999030005  ) then
		if g_Timer > 0 then
			KillTimer("ZM_Boss_DaoJiShi_Timer()")
		end
		g_Timer = 6
	
		SetTimer("ZM_Boss_DaoJiShi","ZM_Boss_DaoJiShi_Timer()", 1*1000)
		ZM_Boss_DaoJiShi_Animate_Time:Play(false)
		ZM_Boss_DaoJiShi_Animate_Time:Hide()
		ZM_Boss_DaoJiShi_Animate_Start:Hide()
		ZM_Boss_DaoJiShi_Animate_End:Hide()
		ZM_Boss_DaoJiShi_ImageBK:Show()
		ZM_Boss_DaoJiShi_Text:SetText("#{ZMB_230124_253}")
		this:Show()
	
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function ZM_Boss_DaoJiShi_Timer()
	g_Timer = g_Timer - 1 
	if g_Timer == 0 then
		KillTimer("ZM_Boss_DaoJiShi_Timer()")
		this:Hide()
	end
end