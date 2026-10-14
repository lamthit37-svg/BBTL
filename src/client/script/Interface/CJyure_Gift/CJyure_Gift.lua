-- 春节预热界面2的二级界面（线索提示） Created by wanghongao
-- !!!reloadscript =CJyure_Gift

local g_CJyure_Gift_Frame_UnifiedXPosition
local g_CJyure_Gift_Frame_UnifiedYPosition

local g_CJyure_Gift_ThreadStrList = {
	[1] = "#{CJYR_211125_23}",
	[2] = "#{CJYR_211125_24}",
	[3] = "#{CJYR_211125_43}",
	[4] = "#{CJYR_211125_44}",
	[5] = "#{CJYR_211125_45}",
	[6] = "#{CJYR_211125_46}",
	[7] = "#{CJYR_211125_47}",
	[8] = "#{CJYR_211125_48}",
	[9] = "#{CJYR_211125_49}",
	[10] = "#{CJYR_211125_50}",
	[11] = "#{CJYR_211125_58}",
	[12] = "#{CJYR_211125_59}"
}

function CJyure_Gift_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)
end

function CJyure_Gift_OnLoad()
	-- 保存界面的默认相对位置
	g_CJyure_Gift_Frame_UnifiedXPosition = CJyure_Gift_Frame : GetProperty("UnifiedXPosition");
	g_CJyure_Gift_Frame_UnifiedYPosition = CJyure_Gift_Frame : GetProperty("UnifiedYPosition");
end

function CJyure_Gift_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 5051032) then
		if this:IsVisible() then
			this:Hide()
		end
		local thread_id = tonumber(arg1)
		if thread_id == 0 then
			return
		elseif g_CJyure_Gift_ThreadStrList[thread_id] ~= nil then --提示线索
			CJyure_Gift_LetterText:SetText(g_CJyure_Gift_ThreadStrList[thread_id])
			this:Show()
		end

	elseif (event == "ADJEST_UI_POS" ) then
		CJyure_Gift_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		CJyure_Gift_Frame_On_ResetPos()

	elseif (event == "PLAYER_ENTERING_WORLD") then
		this:Hide()
	end
end

function CJyure_Gift_Close()
	this:Hide()
end

function CJyure_Gift_Frame_On_ResetPos()
	CJyure_Gift_Frame : SetProperty("UnifiedXPosition", g_CJyure_Gift_Frame_UnifiedXPosition)
	CJyure_Gift_Frame : SetProperty("UnifiedYPosition", g_CJyure_Gift_Frame_UnifiedYPosition);
end