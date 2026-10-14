--******************************************************************************
-- 界面
--******************************************************************************
local g_Jinfengsq_Mini_Frame_UnifiedXPosition;
local g_Jinfengsq_Mini_Frame_UnifiedYPosition;

local g_Jinfengsq_Mini_Max = 70

--===============================================
-- OnLoad()
--===============================================
function Jinfengsq_Mini_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
	this:RegisterEvent("JFSQ_CHANGEUI",true);
end

function Jinfengsq_Mini_OnLoad()
	-- 保存界面的默认相对位置
	g_Jinfengsq_Mini_Frame_UnifiedXPosition = Jinfengsq_Mini_Frame:GetProperty("UnifiedXPosition");
	g_Jinfengsq_Mini_Frame_UnifiedYPosition = Jinfengsq_Mini_Frame:GetProperty("UnifiedYPosition");
end


--===============================================
-- OnEvent()
--===============================================

function Jinfengsq_Mini_OnEvent(event)
	if(event == "JFSQ_CHANGEUI") then
		local operate = tonumber(arg0)
		if operate == 0 then
			--g_Jinfengsq_Mini_Frame_UnifiedXPosition = tonumber(arg1)
			--g_Jinfengsq_Mini_Frame_UnifiedYPosition = tonumber(arg2)
			--Jinfengsq_Mini_Frame_On_ResetPos()
			this:Show()
		else
			this:Hide()
		end
		return
	end

	if(event == "UI_COMMAND") then
		local arg = tonumber(arg0)
		if arg == 89288502 then
			local param = Get_XParam_INT(0)
			if param == 0 then
				this:Hide()
				return
			elseif param == 1 then
				SetTimer("Jinfengsq_Mini","Jinfengsq_Mini_Close_daojishi()", 75*1000)				
			end
		elseif arg == 89288503 then
			if Get_XParam_INT(0) >= g_Jinfengsq_Mini_Max then
				Jinfengsq_Mini_Close_daojishi2()
			end
		elseif arg == 89288504 then
			Jinfengsq_Mini_Close_daojishi2()		
		end
	end
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" and this:IsVisible()) then
		Jinfengsq_Mini_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		Jinfengsq_Mini_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	end
end

function Jinfengsq_Mini_Close_daojishi()
	--停止倒计时文字显示
	KillTimer("Jinfengsq_Mini_Close_daojishi()")
	
	--关闭界面
	this:Hide()
end

function Jinfengsq_Mini_Close_daojishi2()
	--开启5秒倒计时
	SetTimer("Jinfengsq_Mini","Jinfengsq_Mini_Close_daojishi3()", 10*1000)	
end

function Jinfengsq_Mini_Close_daojishi3()
	--停止倒计时文字显示
	KillTimer("Jinfengsq_Mini_Close_daojishi3()")
	
	--关闭界面
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Jinfengsq_Mini_Frame_On_ResetPos()
	Jinfengsq_Mini_Frame : SetProperty("UnifiedXPosition", g_Jinfengsq_Mini_Frame_UnifiedXPosition);
	Jinfengsq_Mini_Frame : SetProperty("UnifiedYPosition", g_Jinfengsq_Mini_Frame_UnifiedYPosition);
end

function Jinfengsq_Mini_Cliecked()
	PushEvent( "JFSQ_CHANGEUI", 1)--g_Jinfengsq_Mini_Frame_UnifiedXPosition, g_Jinfengsq_Mini_Frame_UnifiedYPosition )
end