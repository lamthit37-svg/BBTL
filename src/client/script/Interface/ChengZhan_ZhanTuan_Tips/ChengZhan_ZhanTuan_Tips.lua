--!!!reloadscript =ChengZhan_ZhanTuan_Tips

local g_ChengZhan_ZhanTuan_Tips_Frame_UnifiedXPosition
local g_ChengZhan_ZhanTuan_Tips_Frame_UnifiedYPosition

local g_ChengZhan_ZhanTuan_Tips_Step1 = 0
local g_ChengZhan_ZhanTuan_Tips_Step2 = 0
local g_ChengZhan_ZhanTuan_Tips_nStr = ""
local g_ChengZhan_ZhanTuan_Tips_Max = 1000

local g_ChengZhan_ZhanTuan_Tips_Str = 
{
[1] = {"#{ZTPVP_260515_51}", "#{ZTPVP_260515_52}", "#{ZTPVP_260515_53}"}, --300/180/60
[2] = {"#{ZTPVP_260515_55}", "#{ZTPVP_260515_56}", "#{ZTPVP_260515_54}"}, --%s0的占领进度更高/势均力敌
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function ChengZhan_ZhanTuan_Tips_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function ChengZhan_ZhanTuan_Tips_OnLoad()
	-- 保存界面的默认相对位置
	g_ChengZhan_ZhanTuan_Tips_Frame_UnifiedXPosition	= ChengZhan_ZhanTuan_Tips_Frame:GetProperty("UnifiedXPosition");
	g_ChengZhan_ZhanTuan_Tips_Frame_UnifiedYPosition	= ChengZhan_ZhanTuan_Tips_Frame:GetProperty("UnifiedYPosition");
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ChengZhan_ZhanTuan_Tips_ResetPos()
	ChengZhan_ZhanTuan_Tips_Frame:SetProperty("UnifiedXPosition", g_ChengZhan_ZhanTuan_Tips_Frame_UnifiedXPosition);
	ChengZhan_ZhanTuan_Tips_Frame:SetProperty("UnifiedYPosition", g_ChengZhan_ZhanTuan_Tips_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function ChengZhan_ZhanTuan_Tips_OnEvent(event)
	if event == "UI_COMMAND" and (tonumber(arg0) == 90001603) then

		g_ChengZhan_ZhanTuan_Tips_nStr  = Get_XParam_STR(0);
		g_ChengZhan_ZhanTuan_Tips_Step1 = Get_XParam_INT(0);
		g_ChengZhan_ZhanTuan_Tips_Step2 = Get_XParam_INT(1);

		if (this:IsVisible()) then
			ChengZhan_ZhanTuan_Tips_Update()
			return
		end
		--打开界面
		ChengZhan_ZhanTuan_Tips_Show()
		ChengZhan_ZhanTuan_Tips_Update()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ChengZhan_ZhanTuan_Tips_OnHide()
	elseif event == "ADJEST_UI_POS" then
		ChengZhan_ZhanTuan_Tips_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ChengZhan_ZhanTuan_Tips_ResetPos()
	end
end

--显示UI
function ChengZhan_ZhanTuan_Tips_Show()
	this:Show()
end

--隐藏UI
function ChengZhan_ZhanTuan_Tips_OnHide()
	this:Hide()
end

function ChengZhan_ZhanTuan_Tips_Update()
	if g_ChengZhan_ZhanTuan_Tips_Step1 == 1 then
		local str = ScriptGlobal_Format("#{ZTPVP_260515_47}",g_ChengZhan_ZhanTuan_Tips_nStr,g_ChengZhan_ZhanTuan_Tips_Step2)
		ChengZhan_ZhanTuan_Tips_Text:SetText(str)
		return
	elseif g_ChengZhan_ZhanTuan_Tips_Step1 == 2 then
		if g_ChengZhan_ZhanTuan_Tips_Step2 >= 1 and g_ChengZhan_ZhanTuan_Tips_Step2 <=3 then
			ChengZhan_ZhanTuan_Tips_Text:SetText(g_ChengZhan_ZhanTuan_Tips_Str[1][g_ChengZhan_ZhanTuan_Tips_Step2])
		end
		return
	elseif g_ChengZhan_ZhanTuan_Tips_Step1 == 3 then
		if g_ChengZhan_ZhanTuan_Tips_Step2 == 0 then
			ChengZhan_ZhanTuan_Tips_Text:SetText(g_ChengZhan_ZhanTuan_Tips_Str[2][2])
		elseif g_ChengZhan_ZhanTuan_Tips_Step2 == 1 then
			ChengZhan_ZhanTuan_Tips_Text:SetText(ScriptGlobal_Format(g_ChengZhan_ZhanTuan_Tips_Str[2][1],g_ChengZhan_ZhanTuan_Tips_nStr))
		elseif g_ChengZhan_ZhanTuan_Tips_Step2 == 2 then
			ChengZhan_ZhanTuan_Tips_Text:SetText(ScriptGlobal_Format(g_ChengZhan_ZhanTuan_Tips_Str[2][3],g_ChengZhan_ZhanTuan_Tips_nStr))
		end
		return
	else
		ChengZhan_ZhanTuan_Tips_OnHide()
		return
	end
end


function ChengZhan_ZhanTuan_Tips_CloseClicked()

end