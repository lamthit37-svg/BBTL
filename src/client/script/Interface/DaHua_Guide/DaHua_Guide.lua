--dahuaxiyou 整合界面
local g_DaHua_Guide_Frame_UnifiedPosition

local g_DaHua_Guide_Event = {
	--PVP
	[1] = { begtime = 20240801, endtime = 20240915,
		btntips_unbeg = "#{XYZH_240516_6}",
		btntips_doing = "#{LLKC_240517_182}",
		btntips_end = "#{XYZH_240516_8}",
	},
	--活动商店
	[2] = { begtime = 20240801, endtime = 20240915,
		btntips_unbeg = "#{DHSD_20240522_1}",
		btntips_doing = "#{DHSD_20240522_2}",
		btntips_end = "#{DHSD_20240522_3}",
	},
	--主线任务
	[3] = { begtime = 20240801, endtime = 20240915,
		btntips_unbeg = "#{XYZH_240516_6}",
		btntips_doing = "#{DHGS_240521_03}",
		btntips_end = "#{XYZH_240516_8}",
	},
	--打卡
	[4] = { begtime = 20240801, endtime = 20240915,
		btntips_unbeg = "#{DHDK_240520_4}",
		btntips_doing = "#{DHDK_240520_5}",
		btntips_end = "#{DHDK_240520_6}",
	},
	--PVE
	[5] = { begtime = 20240801, endtime = 20240915,
		btntips_unbeg = "#{XYZH_240516_6}",
		btntips_doing = "#{XYZH_240516_7}",
		btntips_end = "#{XYZH_240516_8}",
	},
	--
	[6] = { begtime = 20240905, endtime = 20240915,
		btntips_unbeg = "#{DHLS_240611_113}",
		btntips_doing = "#{DHLS_240611_113}",
		btntips_end = "#{DHLS_240611_113}",
	},
}

local g_DaHua_Guide_Button_Guide_StateTemp = { 1, 1, 1, 1, 1, 1, }
local g_DaHua_Guide_Tips_Guide_StateTemp = { 0, 0, 0, 0, 0, 0, }

local g_DaHua_Guide_Button = {}
local g_DaHua_Guide_Tip = {}

local g_DaHua_Guide_UICOM_Open       = 80081801
local g_DaHua_Guide_UICOM_Close      = 80081802
local g_DaHua_Guide_UICOM_RefreshRed = 80081803
local g_DaHua_Guide_QuickEnterId     = 59


local g_DaHua_Guide_Stage = 0
local g_DaHua_Guide_Stage1 = 1
local g_DaHua_Guide_Stage2 = 2
local g_DaHua_Guide_Stage3 = 3

local g_DaHua_Guide_StageImg = {
	[1] = "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever",
	[2] = "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever",
	[3] = "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever",
}

local g_DaHua_Guide_PVEBtnImg = {
	[1] = {
		PushedImage="set:DaHua_Guide image:Btn_DZNMW_Pushed",
		NormalImage="set:DaHua_Guide image:Btn_DZNMW_Normal",
		HoverImage="set:DaHua_Guide image:Btn_DZNMW_Hover",
		DisabledImage="set:DaHua_Guide image:Btn_DZNMW_Disabled",
	},
	[2] = {
		PushedImage="set:DaHua_Guide image:Btn_DZSWK_Pushed",
		NormalImage="set:DaHua_Guide image:Btn_DZSWK_Normal",
		HoverImage="set:DaHua_Guide image:Btn_DZSWK_Hover",
		DisabledImage="set:DaHua_Guide image:Btn_DZSWK_Disabled",
	},
	[3] = {
		PushedImage="set:DaHua_Guide image:Btn_DZELS_Pushed",
		NormalImage="set:DaHua_Guide image:Btn_DZELS_Normal",
		HoverImage="set:DaHua_Guide image:Btn_DZELS_Hover",
		DisabledImage="set:DaHua_Guide image:Btn_DZELS_Disabled",
	},
}

local g_DaHua_Guide_PVEBtnTipsStr = {
	[1] = "#{QXPVE_240522_127}",
	[2] = "#{QXPVE_240522_128}",
	[3] = "#{QXPVE_240522_129}",
}

function DaHua_Guide_PreLoad()
	--第二个参数代表界面隐藏时事件是否有效,默认为true
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) --进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS", false)

end

function DaHua_Guide_OnLoad()
	DaHua_Guide_LoadControl()
	g_DaHua_Guide_Frame_UnifiedPosition = DaHua_Guide_Frame_BK:GetProperty("UnifiedPosition")
end

-- 装载控件
function DaHua_Guide_LoadControl()
	g_DaHua_Guide_Button[1] = DaHua_Guide_PVPActivityBtn
	g_DaHua_Guide_Button[2] = DaHua_Guide_ShopBtn
	g_DaHua_Guide_Button[3] = DaHua_Guide_MainStoryBtn
	g_DaHua_Guide_Button[4] = DaHua_Guide_DailyMissionBtn
	g_DaHua_Guide_Button[5] = DaHua_Guide_PveActivityBtn1
	g_DaHua_Guide_Button[6] = DaHua_Guide_ShopActivityBtn

	g_DaHua_Guide_Tip[1] = DaHua_Guide_PVPActivity_Tips
	g_DaHua_Guide_Tip[2] = DaHua_Guide_Shop_Tips
	g_DaHua_Guide_Tip[3] = DaHua_Guide_MainStory_Tips
	g_DaHua_Guide_Tip[4] = DaHua_Guide_DailyMission_Tips
	g_DaHua_Guide_Tip[5] = DaHua_Guide_PveActivityBtn_Tips
	g_DaHua_Guide_Tip[6] = DaHua_Guide_ShopActivityBtn_Tips
end

-- Event
function DaHua_Guide_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_DaHua_Guide_UICOM_Open then
		if this:IsVisible() then
			DaHua_Guide_Close()
			return
		end
		g_DaHua_Guide_Stage = Get_XParam_INT(0)
		if g_DaHua_Guide_Stage ~= g_DaHua_Guide_Stage1 and g_DaHua_Guide_Stage ~= g_DaHua_Guide_Stage2 and
			g_DaHua_Guide_Stage ~= g_DaHua_Guide_Stage3 then
			DaHua_Guide_Close()
			return
		end
		AskServerTimeAgain()
		DaHua_Guide_Update()
		this:Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_DaHua_Guide_UICOM_Close then
		DaHua_Guide_Close()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_DaHua_Guide_UICOM_RefreshRed then
		if this:IsVisible() then
			g_DaHua_Guide_Stage = Get_XParam_INT(0)
			if g_DaHua_Guide_Stage ~= g_DaHua_Guide_Stage1 and g_DaHua_Guide_Stage ~= g_DaHua_Guide_Stage2 and
				g_DaHua_Guide_Stage ~= g_DaHua_Guide_Stage3 then
				DaHua_Guide_Close()
				return
			end
			DaHua_Guide_Update()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		DaHua_Guide_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		DaHua_Guide_Close()
	elseif event == "ADJEST_UI_POS" then
		DaHua_Guide_On_ResetPos()
	end

end

-- 重置界面位置
function DaHua_Guide_On_ResetPos()
	DaHua_Guide_Frame_BK:SetProperty("UnifiedPosition", g_DaHua_Guide_Frame_UnifiedPosition)
end

function DaHua_Guide_OnHidden()
	DaHua_Guide_Close()
end

-- 关闭
function DaHua_Guide_Close()
	g_DaHua_Guide_Stage = 0
	this:Hide()
end

-- 刷新界面
function DaHua_Guide_Update()
	for index = 1, table.getn(g_DaHua_Guide_Button) do
		g_DaHua_Guide_Tip[index]:Hide()
		g_DaHua_Guide_Button[index]:Hide()
	end

	for index = 1, table.getn(g_DaHua_Guide_Button_Guide_StateTemp) do
		local DataState = Get_XParam_INT(index)
		local TipsState = math.mod(DataState, 10)
		local ButtonState = math.floor(DataState / 10)

		g_DaHua_Guide_Tips_Guide_StateTemp[index] = TipsState
		g_DaHua_Guide_Button_Guide_StateTemp[index] = ButtonState
	end

	local curDay = DataPool:GetServerDayTime()
	for index = 1, table.getn(g_DaHua_Guide_Event) do
		local isButtonShow = g_DaHua_Guide_Button_Guide_StateTemp[index]
		local isTipsShow = g_DaHua_Guide_Tips_Guide_StateTemp[index]
		local event = g_DaHua_Guide_Event[index]

		if isButtonShow == 1 then
			--跟阶段这个属性无所谓了 按钮的显隐完全交给GetButtonState传回的值
			g_DaHua_Guide_Button[index]:Show()
			if curDay < event.begtime then
				g_DaHua_Guide_Button[index]:SetToolTip(event.btntips_unbeg)
			elseif curDay >= event.begtime and curDay <= event.endtime then
				g_DaHua_Guide_Button[index]:SetToolTip(event.btntips_doing)
			elseif curDay > event.endtime then
				g_DaHua_Guide_Button[index]:SetToolTip(event.btntips_end)
			end
			if isTipsShow == 1 then
				g_DaHua_Guide_Tip[index]:Show()
			end
		end
	end

	local IsShowMiniMapPoint = 0
	for index = 1, table.getn(g_DaHua_Guide_Tips_Guide_StateTemp) do
		if g_DaHua_Guide_Tips_Guide_StateTemp[index] == 1 then
			IsShowMiniMapPoint = 1
			break
		end
	end

	Lua_ShowQuickEnterPointTip(g_DaHua_Guide_QuickEnterId, IsShowMiniMapPoint)

	--根据阶段切底图
	local img = g_DaHua_Guide_StageImg[g_DaHua_Guide_Stage]
	if img ~= nil then
		--ActivitySchedule_MBuy2_Item_BuyLimi:SetProperty("Image", img)
	end

	--根据阶段切换PVE按钮的悬浮提示以及样式
	local pveTip = g_DaHua_Guide_PVEBtnTipsStr[g_DaHua_Guide_Stage]
	if pveTip ~= nil then
		local tips = ScriptGlobal_Format("#{QXPVE_240522_6}",pveTip)
		g_DaHua_Guide_Button[5]:SetToolTip(tips)
	end
	local PushedImage = g_DaHua_Guide_PVEBtnImg[g_DaHua_Guide_Stage].PushedImage
	local NormalImage = g_DaHua_Guide_PVEBtnImg[g_DaHua_Guide_Stage].NormalImage
	local HoverImage = g_DaHua_Guide_PVEBtnImg[g_DaHua_Guide_Stage].HoverImage
	local DisabledImage = g_DaHua_Guide_PVEBtnImg[g_DaHua_Guide_Stage].DisabledImage
	if PushedImage~=nil and NormalImage~=nil and HoverImage~=nil and DisabledImage~=nil then
		g_DaHua_Guide_Button[5]:SetProperty("PushedImage",PushedImage)
		g_DaHua_Guide_Button[5]:SetProperty("NormalImage",NormalImage)
		g_DaHua_Guide_Button[5]:SetProperty("HoverImage",HoverImage)
		g_DaHua_Guide_Button[5]:SetProperty("DisabledImage",DisabledImage)
	end
end

-- 打开各个功能界面
function DaHua_Guide_Clicked(clickId)
	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then
		--PVP
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(820023)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 2 then
		--活动商店
		if IsInTServer() == 1 then
			PushDebugMessage("#{DHSD_20240522_4}") -- 无法在天荒古境或汴京参与该活动。
			return
		end

		local curDay = tonumber(DataPool:GetServerDayTime())
		if(curDay < g_DaHua_Guide_Event[clickId].begtime and curDay > g_DaHua_Guide_Event[clickId].endtime) then
			PushDebugMessage("#{DHSD_20240522_5}") -- 当前不在活动时间内，无法参与活动。
			return
		end

		local level = Player:GetData("LEVEL")
		if level < 30 then
			PushDebugMessage("#{DHSD_20240522_6}") -- 您的等级不足30级，无法参与活动。
			return
		end
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnClientAskData")
			Set_XSCRIPT_ScriptID(999236)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 3 then
		--主线任务
		--大话西游第一阶段主线剧情
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("FlushUI")
			Set_XSCRIPT_ScriptID(999132)
			Set_XSCRIPT_Parameter( 0, 1 )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()			
	elseif clickId == 4 then
		--打卡
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenWindowRequest")
			Set_XSCRIPT_ScriptID(999137)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 5 then
		--PVE1
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenGotoUI")
			Set_XSCRIPT_ScriptID(051128)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 6 then		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenChouJiang")
			Set_XSCRIPT_ScriptID( 501002 ) 
			Set_XSCRIPT_ParamCount( 0 ); 
		Send_XSCRIPT() 
	end
end
