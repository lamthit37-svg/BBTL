local g_Chengxiongdatu_Type = ""
local g_Chengxiongdatu_CheckBtn = {}
local g_Chengxiongdatu_Data = {
	ChengX = {
		title = "#{CXDT_240306_1}", --惩凶打图设置
		btn1 = "#{CXDT_240306_2}",  --收费传送
		btn2 = "#{CXDT_240306_3}",  --定位回城
		btn1_tip = "#{CXDT_240306_7}", --按钮1显示悬浮tips
		btn2_tip = "#{CXDT_240306_8}", --按钮2显示悬浮tips
		data = {0, 0}
	}
}
local g_Chengxiongdatu_Frame_UnifiedPosition = nil

-- PreLoad
function Chengxiongdatu_PreLoad()
	this:RegisterEvent("OPEN_CFGWINDOW_CXDT")
	this:RegisterEvent("RESET_ALLUI") --返回登录界面时重置UI
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) --切场景
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
end

-- OnLoad
function Chengxiongdatu_OnLoad()
	g_Chengxiongdatu_Frame_UnifiedPosition = Chengxiongdatu_Frame:GetProperty("UnifiedPosition")
	g_Chengxiongdatu_CheckBtn[1]  = Chengxiongdatu_Fufeichuansong_Bind
	g_Chengxiongdatu_CheckBtn[2]  = Chengxiongdatu_Dingweihuicheng_Bind
end

-- OnEvent
function Chengxiongdatu_OnEvent(event)
	if event == "OPEN_CFGWINDOW_CXDT" then
		if g_Chengxiongdatu_Data[arg0] then
			Chengxiongdatu_Fresh(arg0)
			this:Show()
		end

	elseif event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Chengxiongdatu_Frame:SetProperty("UnifiedPosition", g_Chengxiongdatu_Frame_UnifiedPosition)

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Chengxiongdatu_Close()

	-- 退出到主界面时，重置所有数据
	elseif event == "RESET_ALLUI" then
		for k, v in pairs(g_Chengxiongdatu_Data) do
			for i = 1, table.getn(v.data) do
				v.data[i] = 0
			end
		end
		Chengxiongdatu_Frame:SetProperty("UnifiedPosition", g_Chengxiongdatu_Frame_UnifiedPosition)
		Chengxiongdatu_Close()
	end
end

-- 根据 g_Chengxiongdatu_Data[title] 刷新UI
function Chengxiongdatu_Fresh(name)
	g_Chengxiongdatu_Type = name
	local info = g_Chengxiongdatu_Data[name]
	for i = 1, table.getn(g_Chengxiongdatu_CheckBtn) do
		info.data[i] = BattleAssist:GetNeiGuaCfgData(i - 1)
		g_Chengxiongdatu_CheckBtn[i]:SetCheck(info.data[i])
	end
	-- 以后复用这个界面时，要根据info来设置控件上的各种文字
end

-- 关闭界面
function Chengxiongdatu_Close()
	g_Chengxiongdatu_Type = ""
	this:Hide()
end

-- 点击确定
function Chengxiongdatu_Submit()
	local data = g_Chengxiongdatu_Data[g_Chengxiongdatu_Type].data
	for i = 1, table.getn(g_Chengxiongdatu_CheckBtn) do
		local old_data = data[i]
		data[i] = g_Chengxiongdatu_CheckBtn[i]:GetCheck()
		if old_data ~= data[i] then
			BattleAssist:SetNeiGuaCfgData(i - 1, data[i])
			-- Server 数据设置
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("SetZDHConfig")
				Set_XSCRIPT_ScriptID(504000)
				Set_XSCRIPT_Parameter(0, i)
				Set_XSCRIPT_Parameter(1, data[i])
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		end
	end
	Chengxiongdatu_Close()
end

-- 点击CheckButton
function Chengxiongdatu_SetCheck(nIdx)
end