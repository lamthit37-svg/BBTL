local g_Xianchangzhiwu_Type = ""
local g_Xianchangzhiwu_CheckBtn = {}
local g_Cehngxiongdatu_Btn_Text = {}
local g_Xianchangzhiwu_Data = {
	XianCh = {
		title = "#{ZWZDH_241024_10}", --闲常治务设置
		btn1 = "#{ZWZDH_241024_12}",  --是
		btn2 = "#{ZWZDH_241024_13}",  --否
		text = "#{ZWZDH_241024_11}",  --是否需要自动使用背包内未加锁的荣赏令？
		cfg_id = 2, --XCZW_USE_ITEM
		data = 0
	}
}
local g_Xianchangzhiwu_Frame_UnifiedPosition = nil

-- PreLoad
function Xianchangzhiwu_PreLoad()
	this:RegisterEvent("OPEN_CFGWINDOW_CXDT")
	this:RegisterEvent("RESET_ALLUI") --返回登录界面时重置UI
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) --切场景
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
end

-- OnLoad
function Xianchangzhiwu_OnLoad()
	g_Xianchangzhiwu_Frame_UnifiedPosition = Xianchangzhiwu_Frame:GetProperty("UnifiedPosition")
	g_Xianchangzhiwu_CheckBtn[1]  = Xianchangzhiwu_Fufeichuansong_Bind
	g_Xianchangzhiwu_CheckBtn[2]  = Xianchangzhiwu_Dingweihuicheng_Bind
	g_Cehngxiongdatu_Btn_Text[1]  = Xianchangzhiwu_Fufeichuansong_Text
	g_Cehngxiongdatu_Btn_Text[2]  = Xianchangzhiwu_Dingweihuicheng_Text
end

-- OnEvent
function Xianchangzhiwu_OnEvent(event)
	if event == "OPEN_CFGWINDOW_CXDT" then
		if g_Xianchangzhiwu_Data[arg0] then
			Xianchangzhiwu_Fresh(arg0)
			this:Show()
		end

	elseif event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Xianchangzhiwu_Frame:SetProperty("UnifiedPosition", g_Xianchangzhiwu_Frame_UnifiedPosition)

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Xianchangzhiwu_Close()

	-- 退出到主界面时，重置所有数据
	elseif event == "RESET_ALLUI" then
		for k, v in pairs(g_Xianchangzhiwu_Data) do
			if type(v.data) == "number" then
				v.data = 0
			else
				for i = 1, table.getn(v.data) do
					v.data[i] = 0
				end
			end
		end
		Xianchangzhiwu_Frame:SetProperty("UnifiedPosition", g_Xianchangzhiwu_Frame_UnifiedPosition)
		Xianchangzhiwu_Close()
	end
end

-- 根据 g_Xianchangzhiwu_Data[title] 刷新UI
function Xianchangzhiwu_Fresh(name)
	g_Xianchangzhiwu_Type = name
	local info = g_Xianchangzhiwu_Data[name]

	-- 根据info来设置控件上的各种文字
	Xianchangzhiwu_PageName:SetText(info.title)
	Xianchangzhiwu_Text1:SetText(info.text)
	g_Cehngxiongdatu_Btn_Text[1]:SetText(info.btn1)
	g_Cehngxiongdatu_Btn_Text[2]:SetText(info.btn2)

	-- 设置 check button
	local btn_cnt = 2 --table.getn(g_Xianchangzhiwu_CheckBtn)
	if type(info.data) == "number" then
		info.data = BattleAssist:GetNeiGuaCfgData(info.cfg_id)
		local c2 = 0; if info.data == 0 then c2 = 1 end
		g_Xianchangzhiwu_CheckBtn[1]:SetCheck(info.data)
		g_Xianchangzhiwu_CheckBtn[2]:SetCheck(c2)

	elseif table.getn(info.data) == btn_cnt then
		for i = 1, btn_cnt do
			info.data[i] = BattleAssist:GetNeiGuaCfgData(info.cfg_id[i])
			g_Xianchangzhiwu_CheckBtn[i]:SetCheck(info.data[i])
		end
	end
end

-- 关闭界面
function Xianchangzhiwu_Close()
	g_Xianchangzhiwu_Type = ""
	this:Hide()
end

-- 点击确定
function Xianchangzhiwu_Submit()
	local info = g_Xianchangzhiwu_Data[g_Xianchangzhiwu_Type]
	if type(info.data) == "number" then
		local old_data = info.data
		info.data = g_Xianchangzhiwu_CheckBtn[1]:GetCheck()
		if info.data ~= old_data then
			XianChangzhiwu_UpdateCfgData(info.cfg_id, info.data)
		end
	else
		for i = 1, 2 do
			local old_data = info.data[i]
			info.data[i] = g_Xianchangzhiwu_CheckBtn[i]:GetCheck()
			if old_data ~= info.data[i] then
				XianChangzhiwu_UpdateCfgData(info.cfg_id[i], info.data[i])
			end
		end
	end
	Xianchangzhiwu_Close()
end

-- 点击CheckButton
function Xianchangzhiwu_SetCheck(nIdx)
	local data = g_Xianchangzhiwu_Data[g_Xianchangzhiwu_Type].data
	if type(data) == "number" then
		local mine = g_Xianchangzhiwu_CheckBtn[nIdx]
		local other
		if nIdx == 1 then
			other = g_Xianchangzhiwu_CheckBtn[2]
		elseif nIdx == 2 then
			other = g_Xianchangzhiwu_CheckBtn[1]
		else
			return
		end
		if mine:GetCheck() == 1 then
			other:SetCheck(0)
		else
			other:SetCheck(1)
		end
	end
end

-- 更改配置数据
function XianChangzhiwu_UpdateCfgData(id, value)
	BattleAssist:SetNeiGuaCfgData(id, value)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SetZDHConfig")
		Set_XSCRIPT_ScriptID(504000)
		Set_XSCRIPT_Parameter(0, id + 1)
		Set_XSCRIPT_Parameter(1, value)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end