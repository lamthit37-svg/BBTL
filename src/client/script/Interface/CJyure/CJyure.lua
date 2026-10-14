-- 春节预热界面 Created by wanghongao
-- !!!reloadscript =CJyure

local g_CJyure_Frame_UnifiedXPosition
local g_CJyure_Frame_UnifiedYPosition

local g_CJyure_UIList = {}
local g_CJyure_ThreadID = { 0, 0, 0, 0 }

function CJyure_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)
end

function CJyure_OnLoad()
	g_CJyure_UIList = {
		[1] = {
			btn = CJyure_Client2_Button1,
			img = CJyure_image1,
			info = CJyure_Client2_Button1_Image
		},
		[2] = {
			btn = CJyure_Client2_Button2,
			img = CJyure_image2,
			info = CJyure_Client2_Button2_Image
		},
		[3] = {
			btn = CJyure_Client2_Button3,
			img = CJyure_image3,
			info = CJyure_Client2_Button3_Image
		},
		[4] = {
			btn = CJyure_Client2_Button4,
			img = CJyure_image4,
			info = CJyure_Client2_Button4_Image
		}
	}

	g_CJyure_Frame_UnifiedXPosition	= CJyure_Frame : GetProperty("UnifiedXPosition")
	g_CJyure_Frame_UnifiedYPosition	= CJyure_Frame : GetProperty("UnifiedYPosition")
end

function CJyure_OnEvent(event)
	if event == "UI_COMMAND" then
		if tonumber(arg0) == 5051031 then
			local ui_type = Get_XParam_INT(0) --打开界面1还是界面2
			if ui_type == 2 then
				CJyure_InitUI()
			end
			CJyure_ShowWindow(ui_type) --打开界面

		elseif tonumber(arg0) == 5051033 then
			CJyure_InitUI()
			local index = Get_XParam_INT(0)
			if index == 5 then --领取礼包成功 
				Lua_ShowQuickEnterPointTip(28, 0)
			elseif g_CJyure_ThreadID[index] ~= nil then --习得第index个技巧
				CJyure_ShowWindow(2) --打开界面
			end
		end

	elseif (event == "ADJEST_UI_POS" ) then
		CJyure_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		CJyure_Frame_On_ResetPos()

	elseif (event == "PLAYER_ENTERING_WORLD") then
		this:Hide()
	end
end

function CJyure_InitUI()
	local all_learned = 1
	for i = 1, 4 do
		g_CJyure_ThreadID[i] = Get_XParam_INT(i) --设置线索ID
		local is_learned = Get_XParam_INT(i + 4)
		CJyure_SetImageVisible(i, is_learned) --设置线索完成情况（0或1）
		if all_learned == 1 and is_learned == 0 then
			all_learned = 0
		end
	end
	if Get_XParam_INT(9) == 1 then --已领取礼包
		CJyure_Client2_GetButton:Hide()
		CJyure_Client2_GetButton_Disabled:Show()
		CJyure_Client2_GetButton_Tips:Hide()
		CJyure_Client2_GetButton_YiLingQu2:Show()
	else
		CJyure_Client2_GetButton:Show()
		CJyure_Client2_GetButton_Disabled:Hide()
		CJyure_Client2_GetButton_YiLingQu2:Hide()
		if all_learned == 1 then --开启红点
			CJyure_Client2_GetButton_Tips:Show() 
			Lua_ShowQuickEnterPointTip(28, 1)
		else
			CJyure_Client2_GetButton_Tips:Hide()
		end
	end
end

function CJyure_ShowWindow(ui_type)
	PushEvent("UI_COMMAND", 5051032, 0) --关闭二级界面
	if ui_type == 1 then
		CJyure_Client1BK:Show()
		CJyure_Client2BK:Hide()
		this:Show()
	elseif ui_type == 2 then
		CJyure_Client1BK:Hide()
		CJyure_Client2BK:Show()
		this:Show()
		-- PushDebugMessage("thread "..g_CJyure_ThreadID[1]..","..g_CJyure_ThreadID[2]..","..g_CJyure_ThreadID[3]..","..g_CJyure_ThreadID[4])
	end
end

function CJyure_SetImageVisible(id, is_show)
	if is_show == 1 then
		g_CJyure_UIList[id].img:Show()
		g_CJyure_UIList[id].info:Show()
		g_CJyure_UIList[id].btn:Hide()
	elseif is_show == 0 then
		g_CJyure_UIList[id].img:Hide()
		g_CJyure_UIList[id].info:Hide()
		g_CJyure_UIList[id].btn:Show()
	end
end

function CJyure_CloseClicked()
	PushEvent("UI_COMMAND", 5051032, 0) --关闭二级界面
	this:Hide()
end

function CJyure_OnHelpClick()
	PushEvent("OPEN_HUODONGTEXT_HELP", "", "#{CJYR_211125_42}")
end

-- 恢复界面的默认相对位置
function CJyure_Frame_On_ResetPos()
	CJyure_Frame : SetProperty("UnifiedXPosition", g_CJyure_Frame_UnifiedXPosition);
	CJyure_Frame : SetProperty("UnifiedYPosition", g_CJyure_Frame_UnifiedYPosition);
end

function CJyure_OKClicked(id)
	if id == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenSpringWarmUpUI")
			Set_XSCRIPT_ScriptID(505103)
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif id == 5 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetGiftCallbyUI")
			Set_XSCRIPT_ScriptID(505103)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	else
		PushEvent("UI_COMMAND", 5051032, g_CJyure_ThreadID[id])
	end
end
