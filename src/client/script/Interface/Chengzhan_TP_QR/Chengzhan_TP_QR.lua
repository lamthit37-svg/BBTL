-- !!!reloadscript =Chengzhan_TP_QR
local m_Frame_UnifiedPosition

local m_targetPosX = -1
local m_targetPosZ = -1
local m_exeScriptId = 0
local m_exeScriptFunc = ""
local m_desc = ""
--预加载函数，可以而且只能在这里注册脚本关心的事件
function Chengzhan_TP_QR_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Chengzhan_TP_QR_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedPosition	= Chengzhan_TP_QR_Frame:GetProperty("UnifiedPosition");
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Chengzhan_TP_QR_ResetPos()
	Chengzhan_TP_QR_Frame:SetProperty("UnifiedPosition", m_Frame_UnifiedPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Chengzhan_TP_QR_OnEvent(event)
	if( event == "UI_COMMAND" ) and tonumber(arg0) == 900025003 then--
		m_targetPosX = Get_XParam_INT(0)
		m_targetPosZ = Get_XParam_INT(1)
		m_exeScriptId = Get_XParam_INT(2)
		m_exeScriptFunc = Get_XParam_STR(0)
		m_desc = Get_XParam_STR(1)
		if (this:IsVisible()) then
			Chengzhan_TP_QR_Update()
			return
		end
		Chengzhan_TP_QR_Show()
		Chengzhan_TP_QR_Update()
	elseif event == "ADJEST_UI_POS" then
		Chengzhan_TP_QR_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Chengzhan_TP_QR_Hide()
	end
end

--显示UI
function Chengzhan_TP_QR_Show()
	Chengzhan_TP_QR_ClearData()
	this:Show()
	
end
--隐藏UI
function Chengzhan_TP_QR_Hide()
	Chengzhan_TP_QR_ClearData()

	this:Hide()
end

--清除数据
function Chengzhan_TP_QR_ClearData()
end
--更新
function Chengzhan_TP_QR_Update()
	Chengzhan_TP_QR_Text:SetText(m_desc)
	Chengzhan_TP_QR_StopWatch:SetProperty("Timer", tostring(30))
end
--##############点击事件##############
function Chengzhan_TP_QR_CloseFunc()
	Chengzhan_TP_QR_Hide()
end
function Chengzhan_TP_QR_OK_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name(m_exeScriptFunc)
		Set_XSCRIPT_ScriptID(m_exeScriptId)
		Set_XSCRIPT_Parameter(0, m_targetPosX)
		Set_XSCRIPT_Parameter(1, m_targetPosZ)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()			
	Chengzhan_TP_QR_Hide()
end
function Chengzhan_TP_QR_TimeOut()
	Chengzhan_TP_QR_Hide()
end
--####################################