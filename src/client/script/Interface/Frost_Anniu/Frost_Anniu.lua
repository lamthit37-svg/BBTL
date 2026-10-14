--霜叶红于二月花倒计时

local g_TicketGainCount = 0		--当前领取次数
local g_Controls = {} 			--控件列表
local g_Frame_UnifiedPosition = "";

function Frost_Anniu_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("FROSTLEAF_UPDATE")
	this:RegisterEvent("SWITCH_MENU_BUTTON");
	this:RegisterEvent("FRESHMAN_CHANGESTATE");
end

function Frost_Anniu_OnLoad()
	g_Controls = {
					m_Frame = Frost_Anniu_Frame,
					m_DownTickWatch = Frost_Anniu_Time_Text,
					m_DownTickText = Frost_Anniu_Text,
					m_FlashAnimate = Frost_Anniu_BK,
					m_TipText = Frost_Anniu_Remainder,
					m_FinishText = Frost_Anniu_Finish,
					m_DaoJishi = Frost_Anniu_DaoJiShi,
					
				}	
	g_Frame_UnifiedPosition=g_Controls.m_Frame:GetProperty("UnifiedPosition");
end

function  Frost_Anniu_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 891414 ) then
	--		local nGainTicketCount = Get_XParam_INT(0)
	--		local nDownTick = Get_XParam_INT(1)
	--		local nOperate = Get_XParam_INT(2) --1更新并显示 0隐藏
	--		g_TicketGainCount = nGainTicketCount
	--		if nOperate == 2 then
				--最后一次领奖
	--			g_Controls.m_DownTickWatch:SetProperty("Timer",tostring(0));
	--			g_Controls.m_FinishText:Show()
	--			g_Controls.m_DownTickText:Hide()
	--			g_Controls.m_FlashAnimate:PlayWarning(0)
	--			g_Controls.m_DaoJishi:Hide()
	--			local strTemp = ScriptGlobal_Format("#{YNZJ_141225_45}",4 - g_TicketGainCount)
	--			g_Controls.m_TipText:SetText(strTemp)
	--			this:Show()
	--			return
	--		end
	--		if nOperate == 0 then
	--			this:Hide();
	--			g_Controls.m_DownTickWatch:SetProperty("Timer",tostring(0));
	--			return
	--		end
	--		if nOperate == 1 then
	--			g_Controls.m_DownTickWatch:SetProperty("Timer",tostring(nDownTick));
	--			if nDownTick <= 0 then
	--				g_Controls.m_DownTickText:Show()
	--				g_Controls.m_FlashAnimate:PlayWarning(1)
	--			else
	--				g_Controls.m_DownTickText:Hide()
	--				g_Controls.m_FlashAnimate:PlayWarning(0)
	--			end
	--			local strTemp = ScriptGlobal_Format("#{YNZJ_141225_45}",4 - g_TicketGainCount)
	--			g_Controls.m_TipText:SetText(strTemp)
	--			g_Controls.m_FinishText:Hide()
	--			g_Controls.m_DaoJishi:Show()
	--			this:Show();
	--		end	
	elseif (event == "SWITCH_MENU_BUTTON") then
		Frost_Anniu_UpdatePos()
	elseif (event == "FRESHMAN_CHANGESTATE") then
		Frost_Anniu_UpdatePos()
	--elseif (event == "FROSTLEAF_UPDATE") then
	--	Clear_XSCRIPT()
	--		Set_XSCRIPT_Function_Name( "FrostLeafUpdate" )
	--		Set_XSCRIPT_ScriptID( 891414 )
	--	Send_XSCRIPT()
	end
end

function Frost_Anniu_TimeOut()
	--播放按钮闪动动画
	g_Controls.m_FlashAnimate:PlayWarning(1)
	--更新计时器时间
	g_Controls.m_DownTickText:Show()
end

function Frost_Anniu_TimeOut1()
end

-- 领取道具
function  Frost_Anniu_Bn2Click()
  --在地府中不能领取
  local isInHell = IsInHell()
  if isInHell == 1 then
    return
  end
  
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGuideItem" )
		Set_XSCRIPT_ScriptID( 891414 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--鼠标进入
function Frost_Anniu_MouseEnter()
	--显示提示
	g_Controls.m_FlashAnimate:SetToolTip("霜叶红于二月花")
end

--鼠标离开
function Frost_Anniu_MouseLeave()
	
end

function Frost_Anniu_UpdatePos()
	--暂时留着
	--if IsWindowShow("FreshmanWatch") == true then																					--新人领奖界面已打开
	--	if IsWindowShow("MainMenuBar_4") == true then																				--主快捷栏上有两排快捷栏
	--		g_Controls.m_Frame:SetProperty("UnifiedPosition", "{{0.500000,-60.000000},{1.000000,-345.000000}}");
	--	elseif IsWindowShow("MainMenuBar_2") == true then																			--主快捷栏上有上方快捷栏
	--		g_Controls.m_Frame:SetProperty("UnifiedPosition", "{{0.500000,-60.000000},{1.000000,-309.000000}}");
	--	else 																														--主快捷栏上没有快捷栏
	--		g_Controls.m_Frame:SetProperty("UnifiedPosition", "{{0.500000,-60.000000},{1.000000,-273.000000}}");
	--	end
	--else
	--	if IsWindowShow("MainMenuBar_4") == true then																				--主快捷栏上有两排快捷栏
	--		g_Controls.m_Frame:SetProperty("UnifiedPosition", "{{0.500000,-60.000000},{1.000000,-228.000000}}");
	--	elseif IsWindowShow("MainMenuBar_2") == true then																			--主快捷栏上有上方快捷栏
	--		g_Controls.m_Frame:SetProperty("UnifiedPosition", "{{0.500000,-60.000000},{1.000000,-192.000000}}");
	--	else 																														--主快捷栏上没有快捷栏
	--		g_Controls.m_Frame:SetProperty("UnifiedPosition", "{{0.500000,-60.000000},{1.000000,-156.000000}}");
	--	end
	--end
	g_Controls.m_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end


