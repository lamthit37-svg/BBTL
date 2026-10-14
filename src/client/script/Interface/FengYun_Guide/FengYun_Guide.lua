--FengYun_Guide.lua
local g_FengYun_Guide_Frame_UnifiedPosition
local g_FengYun_Guide_Event = {
	--begtime-endtime 活动总持续时间 只是用来计算悬浮提示用的
	--btntips_unbeg   未开启的按钮悬浮提示
	--btntips_doing   进行中的按钮悬浮提示
	--btntips_end     已结束的按钮悬浮提示
	--风云传
	[1] = { begtime = 20260417, endtime = 20260520,
		btntips_unbeg = "#{FYWS_260107_01}",
		btntips_doing = "#{FYWS_260107_02}",
		btntips_end = "#{FYWS_260107_03}",
	},
	--达成进度活动
	[2] = { begtime = 20260417, endtime = 20260520,
		btntips_unbeg = "#{FYJD_250113_04}",
		btntips_doing = "#{FYJD_250113_05}",
		btntips_end = "#{FYJD_250113_06}",
	},
	--无名之道
	[3] = { begtime = 20260417, endtime = 20260520,
		btntips_unbeg = "#{FYDK_260129_01}",
		btntips_doing = "#{FYDK_260129_02}",
		btntips_end = "#{FYDK_260129_03}",
	},
	--PVE一阶段 血战凌云窟
	[4] = { begtime = 20260417, endtime = 20260505,
		btntips_unbeg = "#{FYZH_260106_5}",
		btntips_doing = "#{FYPVE_260108_01}",
		btntips_end = "#{FYPVE_260108_139}",
		lvlimit = 60,
	},
	--PVE二阶段 决战天下会
	[5] = { begtime = 20260506, endtime = 20260520,
		btntips_unbeg = "#{FYPVE_260108_139}",
		btntips_doing = "#{FYPVE_260108_139}",
		btntips_end = "#{FYZH_260106_7}",
		lvlimit = 60,
	},
	--PVP 剑祭大会
	[6] = { begtime = 20260417, endtime = 20260524,
		btntips_unbeg = "#{FYPVP_260106_178}",
		btntips_doing = "#{FYPVP_260106_179}",
		btntips_end = "#{FYPVP_260106_180}",
	},
	--紫禁·群雄争霸
	[7] = { begtime = 20260504, endtime = 20260524,
		btntips_unbeg = "#{FYZH_260106_5}",
		btntips_doing = "#{DFXD_250326_151}",
		btntips_end = "#{FYZH_260106_7}",
	},
	--凌霄破妄
	[8] = { begtime = 20260417, endtime = 20260520,
		btntips_unbeg = "#{FYZH_260106_5}",
		btntips_doing = "#{BXDR_20240920_4}",
		btntips_end = "#{FYZH_260106_7}",
	},
}

local g_FengYun_Guide_Button_Guide_StateTemp = { 1, 1, 1, 1, 1, 1, 1, 1, }
local g_FengYun_Guide_Tips_Guide_StateTemp = { 0, 0, 0, 0, 0, 0, 0, 0, }

local g_FengYun_Guide_Button = {}
local g_FengYun_Guide_Tip = {}
local g_FengYun_Guide_Image = {}

local g_FengYun_Guide_UICOM_Open       = 30015001
local g_FengYun_Guide_UICOM_Close      = 30015002
local g_FengYun_Guide_UICOM_RefreshRed = 30015003
local g_FengYun_Guide_QuickEnterId     = 86
local g_FengYun_Guide_ButtonNum        = 8


local g_FengYun_Guide_Stage = 0
local g_FengYun_Guide_Stage1 = 1
local g_FengYun_Guide_Stage2 = 2
local g_FengYun_Guide_PVPStageInterval = 0

function FengYun_Guide_PreLoad()
	--第二个参数代表界面隐藏时事件是否有效,默认为true
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)

end

function FengYun_Guide_OnLoad()
	FengYun_Guide_LoadControl()
	g_FengYun_Guide_Frame_UnifiedPosition = FengYun_Guide_Frame:GetProperty("UnifiedPosition")
end

-- 装载控件
function FengYun_Guide_LoadControl()
	g_FengYun_Guide_Button[1] = FengYun_Guide_DaKaActivityBtn
	g_FengYun_Guide_Button[2] = FengYun_Guide_JinDuBtn
	g_FengYun_Guide_Button[3] = FengYun_Guide_ZhuBaoActivityBtn
	g_FengYun_Guide_Button[4] = FengYun_Guide_PVE1ActivityBtn
	g_FengYun_Guide_Button[5] = FengYun_Guide_PVE2ActivityBtn
	g_FengYun_Guide_Button[6] = FengYun_Guide_PVP1ActivityBtn1
	g_FengYun_Guide_Button[7] = FengYun_Guide_ZiJinActivityBtn
	g_FengYun_Guide_Button[8] = FengYun_Guide_40mActivityBtn

	g_FengYun_Guide_Tip[1] = FengYun_Guide_DaKaActivity_Tips
	g_FengYun_Guide_Tip[2] = FengYun_Guide_JinDu_Tips
	g_FengYun_Guide_Tip[3] = FengYun_Guide_ZhuBaoActivity_Tips
	g_FengYun_Guide_Tip[4] = FengYun_Guide_PVE1Activity_Tips
	g_FengYun_Guide_Tip[5] = FengYun_Guide_PVE2ActivityBtn_Tips
	g_FengYun_Guide_Tip[6] = FengYun_Guide_PVP1Activity_Tips
	g_FengYun_Guide_Tip[7] = FengYun_Guide_ZiJinActivityBtn_Tips
	g_FengYun_Guide_Tip[8] = FengYun_Guide_40mActivityBtn_Tips

	g_FengYun_Guide_Image[1] = nil
	g_FengYun_Guide_Image[2] = FengYun_Guide_JinDu_Image
	g_FengYun_Guide_Image[3] = FengYun_Guide_ZhuBaoActivity_Image
	g_FengYun_Guide_Image[4] = FengYun_Guide_PVE2Activity_Image
	g_FengYun_Guide_Image[5] = FengYun_Guide_PVE2Activity_Image
	g_FengYun_Guide_Image[6] = FengYun_Guide_PVP1Activity_Image
	g_FengYun_Guide_Image[7] = nil
	g_FengYun_Guide_Image[8] = FengYun_Guide_40mActivity_Image
end

-- Event
function FengYun_Guide_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_FengYun_Guide_UICOM_Open then
		if this:IsVisible() then
			FengYun_Guide_Close()
			return
		end
		g_FengYun_Guide_Stage = Get_XParam_INT(0)
		if g_FengYun_Guide_Stage ~= g_FengYun_Guide_Stage1 and
			g_FengYun_Guide_Stage ~= g_FengYun_Guide_Stage2 then
			FengYun_Guide_Close()
			return
		end
		AskServerTimeAgain()
		FengYun_Guide_Update()
		this:Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_FengYun_Guide_UICOM_Close then
		FengYun_Guide_Close()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_FengYun_Guide_UICOM_RefreshRed then
		if this:IsVisible() then
			g_FengYun_Guide_Stage = Get_XParam_INT(0)
			if g_FengYun_Guide_Stage ~= g_FengYun_Guide_Stage1 and
				g_FengYun_Guide_Stage ~= g_FengYun_Guide_Stage2 then
				FengYun_Guide_Close()
				return
			end
			FengYun_Guide_Update()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		FengYun_Guide_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		FengYun_Guide_Close()
	elseif event == "ADJEST_UI_POS" then
		FengYun_Guide_On_ResetPos()
	end

end

-- 重置界面位置
function FengYun_Guide_On_ResetPos()
	FengYun_Guide_Frame:SetProperty("UnifiedPosition", g_FengYun_Guide_Frame_UnifiedPosition)
end

function FengYun_Guide_OnHidden()
	FengYun_Guide_Close()
end

-- 关闭
function FengYun_Guide_Close()
	g_FengYun_Guide_Stage = 0
	g_FengYun_Guide_PVPStageInterval = 0
	this:Hide()
end

-- 刷新界面
function FengYun_Guide_Update()
	for index = 1, g_FengYun_Guide_ButtonNum do
		g_FengYun_Guide_Tip[index]:Hide()
		g_FengYun_Guide_Button[index]:Hide()
		if g_FengYun_Guide_Image[index] ~= nil then
			g_FengYun_Guide_Image[index]:Hide()
		end
	end
	local curDay = DataPool:GetServerDayTime()
	local IsShowMiniMapPoint = 0
	for index = 1, g_FengYun_Guide_ButtonNum do
		local DataState = Get_XParam_INT(index)
		local TipsState = math.mod(DataState, 10)
		local ButtonState = math.floor(DataState / 10)

		g_FengYun_Guide_Tips_Guide_StateTemp[index] = TipsState
		g_FengYun_Guide_Button_Guide_StateTemp[index] = ButtonState

		local isButtonShow = g_FengYun_Guide_Button_Guide_StateTemp[index]
		local isTipsShow = g_FengYun_Guide_Tips_Guide_StateTemp[index]
		local event = g_FengYun_Guide_Event[index]

		if isButtonShow == 1 then
			--按钮的显隐跟阶段无关 按钮的显隐完全交给GetButtonState传回的值
			g_FengYun_Guide_Button[index]:Show()
			if g_FengYun_Guide_Image[index] ~= nil then
				g_FengYun_Guide_Image[index]:Show()
			end
			if curDay < event.begtime then
				g_FengYun_Guide_Button[index]:SetToolTip(event.btntips_unbeg)
			elseif curDay >= event.begtime and curDay <= event.endtime then
				g_FengYun_Guide_Button[index]:SetToolTip(event.btntips_doing)
			elseif curDay > event.endtime then
				g_FengYun_Guide_Button[index]:SetToolTip(event.btntips_end)
			end
			if isTipsShow == 1 then
				g_FengYun_Guide_Tip[index]:Show()
				IsShowMiniMapPoint = 1
			end
		end
	end
	g_FengYun_Guide_PVPStageInterval = Get_XParam_INT(g_FengYun_Guide_ButtonNum+1)
	Lua_ShowQuickEnterPointTip(g_FengYun_Guide_QuickEnterId, IsShowMiniMapPoint)

	--特写 根据阶段控制PVE一二阶段按钮显隐
	if g_FengYun_Guide_Stage == g_FengYun_Guide_Stage1  then
		--隐藏PVE的二阶段的按钮
		g_FengYun_Guide_Tip[5]:Hide()
		g_FengYun_Guide_Button[5]:Hide()
	elseif g_FengYun_Guide_Stage == g_FengYun_Guide_Stage2 then
		--隐藏PVE的一阶段的按钮
		g_FengYun_Guide_Tip[4]:Hide()
		g_FengYun_Guide_Button[4]:Hide()
	end
	if g_FengYun_Guide_PVPStageInterval == 1 then
		g_FengYun_Guide_Tip[4]:Hide()
		g_FengYun_Guide_Button[4]:Hide()
		g_FengYun_Guide_Button[5]:Show()
		local isTipsShow = g_FengYun_Guide_Tips_Guide_StateTemp[5]
		if isTipsShow ~= nil and isTipsShow > 0 then
			g_FengYun_Guide_Tip[5]:Show()
		end
	end
end

-- 打开各个功能界面
function FengYun_Guide_Clicked(clickId)
	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then
		--不给礼包了 参数 1 悬空
	elseif clickId == 2 then
		--风云传
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenStoryGuideUI")
		Set_XSCRIPT_ScriptID(300152)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 3 then
		--达成进度活动
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenJinDuUI")
		Set_XSCRIPT_ScriptID(999841)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 4 then
		--无名之道
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenUI")
		Set_XSCRIPT_ScriptID(893602)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 5 then
		--PVE一阶段 血战凌云窟
		local event = g_FengYun_Guide_Event[4]
		if event ~= nil and event.lvlimit ~= nil and Player:GetLevel() < event.lvlimit then
			PushDebugMessage("#{FYPVE_260108_02}")
			return
		end
		PushEvent("FYPVE_TRYTOOPENMAIN")
	elseif clickId == 6 then
		--PVE二阶段 决战天下会
		local event = g_FengYun_Guide_Event[5]
		if event ~= nil and event.lvlimit ~= nil and Player:GetLevel() < event.lvlimit then
			PushDebugMessage("#{FYPVE_260108_02}")
			return
		end
		PushEvent("FYPVE_TRYTOOPENMAIN")	
	elseif clickId == 7 then
		--PVP 剑祭天下
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(820109)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif clickId == 8 then
		--紫禁·群雄争霸
		AutoRuntoTargetExWithName(312,273,0,"统战禁军")
		-- Clear_XSCRIPT()
		-- 	Set_XSCRIPT_Function_Name("GOTO")
		-- 	Set_XSCRIPT_ScriptID(820066)
		-- 	Set_XSCRIPT_ParamCount(0)
		-- Send_XSCRIPT()
	elseif clickId == 9 then
		--凌霄破妄
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(820041)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	end

	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("ShowButtonTips")
	Set_XSCRIPT_ScriptID(300150)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
