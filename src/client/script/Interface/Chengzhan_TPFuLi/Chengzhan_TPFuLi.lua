-- !!!reloadscript =Chengzhan_TPFuLi
local m_Frame_UnifiedPosition
local m_bagIndex = -1
local m_cdTime = 0
local m_exeScriptId = 0
local m_exeScriptFunc = ""
--预加载函数，可以而且只能在这里注册脚本关心的事件
function Chengzhan_TPFuLi_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Chengzhan_TPFuLi_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedPosition	= Chengzhan_TPFuLi_Frame:GetProperty("UnifiedPosition");
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Chengzhan_TPFuLi_ResetPos()
	Chengzhan_TPFuLi_Frame:SetProperty("UnifiedPosition", m_Frame_UnifiedPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Chengzhan_TPFuLi_OnEvent(event)
	if( event == "UI_COMMAND" ) and tonumber(arg0) == 900025001 then--
		if nil ~= arg1 and tonumber(arg1) == 2 then
			m_bagIndex = tonumber(arg2)
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnTuanZhangCall")
				Set_XSCRIPT_ScriptID(900025)
				Set_XSCRIPT_Parameter(0, m_bagIndex)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()			
		else
			m_bagIndex = Get_XParam_INT(0)
			m_cdTime = Get_XParam_INT(1)
			m_exeScriptId = Get_XParam_INT(2)
			m_exeScriptFunc = Get_XParam_STR(0)
			if (this:IsVisible()) then
				Chengzhan_TPFuLi_Update()
				return
			end
			Chengzhan_TPFuLi_Show()
			Chengzhan_TPFuLi_Update()
		end
	elseif( event == "UI_COMMAND" ) and tonumber(arg0) == 900025002 then--
		Chengzhan_TPFuLi_Hide()
	elseif event == "ADJEST_UI_POS" then
		Chengzhan_TPFuLi_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Chengzhan_TPFuLi_Hide()
	end
end

--显示UI
function Chengzhan_TPFuLi_Show()
	Chengzhan_TPFuLi_ClearData()
	this:Show()
	
end
--隐藏UI
function Chengzhan_TPFuLi_Hide()
	Chengzhan_TPFuLi_ClearData()

	this:Hide()
end

--清除数据
function Chengzhan_TPFuLi_ClearData()
end
--更新
function Chengzhan_TPFuLi_Update()
	if m_cdTime > 0 then
		Chengzhan_TPFuLi_ShengYu:Show()
		Chengzhan_TPFuLi_ShengYu_Timer:Show()
		Chengzhan_TPFuLi_ShengYu_Timer:SetProperty("Timer", tostring(m_cdTime))
	else
		Chengzhan_TPFuLi_ShengYu:Hide()
		Chengzhan_TPFuLi_ShengYu_Timer:Hide()
	end
end
--##############点击事件##############
function Chengzhan_TPFuLi_CloseFrame()
	Chengzhan_TPFuLi_Hide()
end
function Chengzhan_TPFuLi_Click(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name(m_exeScriptFunc)
		Set_XSCRIPT_ScriptID(m_exeScriptId)
		Set_XSCRIPT_Parameter(0, m_bagIndex)
		Set_XSCRIPT_Parameter(1, index)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()			
end
function Chengzhan_TPFuLi_ShengYu_Timer_TimeOut()
	Chengzhan_TPFuLi_ShengYu:Hide()
	Chengzhan_TPFuLi_ShengYu_Timer:Hide()
end
--####################################