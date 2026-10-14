--ZhenYuanGilt_AnNiu.lua
--皇朝御礼

local g_PlayWarning = 10*1000		--10s闪烁按钮冷却
local g_InPlayWarning = 1			--是否在闪烁冷却

function ZhenYuanGilt_AnNiu_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	--this:RegisterEvent("SWITCH_MENU_BUTTON");
	--this:RegisterEvent("FRESHMAN_CHANGESTATE");
end

function ZhenYuanGilt_AnNiu_OnLoad()
end

function ZhenYuanGilt_AnNiu_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88995801 ) then
		local nType = Get_XParam_INT(0)--0表示关闭
		if nType == 0 then
			--FlashPacketButton()
			this:Hide()
		else
			this:Show()	
			local bIsFlash = Get_XParam_INT(1)--0表示不闪烁
			ZhenYuanGilt_AnNiu_ShowIcon(bIsFlash)
		end
	end
	
	--[[
	if (event == "SWITCH_MENU_BUTTON") then
		ZhenYuanGilt_AnNiu_UpdatePos()
	end
	
	if (event == "FRESHMAN_CHANGESTATE") then
		ZhenYuanGilt_AnNiu_UpdatePos()
	end	
	--]]
	
end

function ZhenYuanGilt_AnNiu_ButtonClick()

	--图标闪烁消失			
	ZhenYuanGilt_AnNiu_BK : PlayWarning( 0 )
	--浮动tips消失
	CloseFreshManGuide()
	
	local isInHell = IsInHell()
	if isInHell == 1 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnOpenBuyGiftUI" )
		Set_XSCRIPT_ScriptID( 889958 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--[[
function ZhenYuanGilt_AnNiu_UpdatePos()
	
	if IsWindowShow("FreshmanWatch") == true then		--新人领奖界面已打开
		if IsWindowShow("MainMenuBar_4") == true then		--主快捷栏上有两排快捷栏
			ZhenYuanGilt_AnNiu_Frame:SetProperty("UnifiedPosition", "{{0.500000,-43.000000},{1.000000,-336.000000}}");
	  elseif IsWindowShow("MainMenuBar_2") == true then		--主快捷栏上有上方快捷栏
	    ZhenYuanGilt_AnNiu_Frame:SetProperty("UnifiedPosition", "{{0.500000,-43.000000},{1.000000,-300.000000}}");
		else 																							--主快捷栏上没有快捷栏
			ZhenYuanGilt_AnNiu_Frame:SetProperty("UnifiedPosition", "{{0.500000,10.000000},{1.000000,-264.000000}}");
		end
	else
		if IsWindowShow("MainMenuBar_4") == true then		--主快捷栏上有两排快捷栏
			ZhenYuanGilt_AnNiu_Frame:SetProperty("UnifiedPosition", "{{0.500000,-43.000000},{1.000000,-336.000000}}");
	  elseif IsWindowShow("MainMenuBar_2") == true then		--主快捷栏上有上方快捷栏
	    ZhenYuanGilt_AnNiu_Frame:SetProperty("UnifiedPosition", "{{0.500000,-43.000000},{1.000000,-300.000000}}");
		else 																							--主快捷栏上没有快捷栏
			ZhenYuanGilt_AnNiu_Frame:SetProperty("UnifiedPosition", "{{0.500000,-43.000000},{1.000000,-264.000000}}");
		end
	end
	
end
--]]

function ZhenYuanGilt_AnNiu_ShowIcon(bFlash)

	if bFlash == nil then
		return
	end
	
	if bFlash ~= 0 then
	
		--图标闪烁			
		ZhenYuanGilt_AnNiu_BK : PlayWarning( 1 )
		--开启tips
		local fX, fY = this:GetChildOffset("ZhenYuanGilt_AnNiu_BK")
		OpenFreshManGuide(1, 65, fX , fY + 15, "ZhenYuanGilt_AnNiu", "northwest")
		ZhenYuanGilt_AnNiu_BK : SetToolTip("")
		--设置闪烁冷却时间
		g_InPlayWarning = 1
		SetTimer("ZhenYuanGilt_AnNiu", "ZhenYuanGilt_AnNiu_g_PlayWarning()",g_PlayWarning)
	end
	
end

function ZhenYuanGilt_AnNiu_g_PlayWarning()
	--图标闪烁消失			
	ZhenYuanGilt_AnNiu_BK : PlayWarning( 0 )
	--浮动tips消失
	CloseFreshManGuide()
	ZhenYuanGilt_AnNiu_BK : SetToolTip("#{HCYL_150304_02}")
	--闪烁计时停止
	g_InPlayWarning = 0
	KillTimer("ZhenYuanGilt_AnNiu_g_PlayWarning()")
end

