--端午节
local g_DuanWu_Guide_Event = {
	[1] = {begtime=20230615,endtime =20230702,btntips_unbeg="",btntips_doing="#{QHNF_190429_05}",btntips_end="#{QHNF_190429_126}",},	 	--龙舟竞渡,废弃
	[2] = {begtime=20230615,endtime =20230705,btntips_unbeg="",btntips_doing="#{QHNF_190429_61}",btntips_end="#{QHNF_190429_126}",},		--兑换pbr:榴花先魁,废弃
	[3] = {begtime=20210614,endtime =20210630,btntips_unbeg="",btntips_doing="#{QHNF_190429_12}",btntips_end="#{QHNF_190429_126}",},		--端午商店,废弃
	[4] = {begtime=20210614,endtime =20210630,btntips_unbeg="",btntips_doing="#{MHZD_190501_05}",btntips_end="#{QHNF_190429_126}",},		--竞拍pbr: 华堂竞宝,废弃
	[5] = {begtime=20260618,endtime =20260701,btntips_unbeg="",btntips_doing="#{QHNF_190429_09}",btntips_end="#{QHNF_190429_126}",},		--粽籺飘香
	[6] = {begtime=20260618,endtime =20260701,btntips_unbeg="",btntips_doing="#{QHNF_190429_07}",btntips_end="#{QHNF_190429_126}",},		--子何归兮
	[7] = {begtime=20250529,endtime =20250615,btntips_unbeg="",btntips_doing="#{DWKC_190502_1}",btntips_end="#{QHNF_190429_126}",},		--如意宝舟,卡级服不开
	[8] = {begtime=20250529,endtime =20250615,btntips_unbeg="",btntips_doing="#{QHNF_190429_138}",btntips_end="#{QHNF_190429_139}",},		-- 银锤金案 vega,卡级服不开
	[9] = {begtime=20260618,endtime =20260701,btntips_unbeg="",btntips_doing="#{DWLB_210427_01}",btntips_end="#{QHNF_190429_126}",},		-- 端午礼包
	[10] = {begtime=20260618,endtime =20260701,btntips_unbeg="",btntips_doing="#{ZZZH_220418_1}",btntips_end="#{QHNF_190429_126}",},		-- 蒸粽子活动设计
};

local g_DuanWu_Guide_Frame_UnifiedPosition
local g_Button_Guide_StateTemp = {0,0,0,0,1,1,0,0,1,1}
local g_Tips_Guide_StateTemp = {0,0,0,0,0,0,0,0,0,0}

local g_DuanWu_Guide_Button ={
}

local g_DuanWu_Guide_Tip = {
}

function DuanWu_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)

end

function DuanWu_Guide_OnLoad()
	DuanWu_Guide_LoadControl()
	g_DuanWu_Guide_Frame_UnifiedPosition = DuanWu_Guide_Frame:GetProperty("UnifiedPosition")

end
--=========
-- 装载控件
--=========
function DuanWu_Guide_LoadControl()

	g_DuanWu_Guide_Button[1] 	= DuanWu_Guide_Btn1; --
	g_DuanWu_Guide_Button[2] 	= DuanWu_Guide_Btn2; --
	g_DuanWu_Guide_Button[3] 	= DuanWu_Guide_Btn3;
	g_DuanWu_Guide_Button[4] 	= DuanWu_Guide_Btn4;
	g_DuanWu_Guide_Button[5] 	= DuanWu_Guide_Btn5;
	g_DuanWu_Guide_Button[6] 	= DuanWu_Guide_Btn6;
	g_DuanWu_Guide_Button[7] 	= DuanWu_Guide_Btn7;
	g_DuanWu_Guide_Button[8] 	= DuanWu_Guide_Btn8;
	g_DuanWu_Guide_Button[9] 	= DuanWu_Guide_BtnGift;
	g_DuanWu_Guide_Button[10] 	= DuanWu_Guide_Btn9;

	g_DuanWu_Guide_Tip[1] 		= DuanWu_Guide_Btn1_Tips;
	g_DuanWu_Guide_Tip[2] 		= DuanWu_Guide_Btn2_Tips;
	g_DuanWu_Guide_Tip[3] 		= DuanWu_Guide_Btn3_Tips;
	g_DuanWu_Guide_Tip[4] 		= DuanWu_Guide_Btn4_Tips;
	g_DuanWu_Guide_Tip[5] 		= DuanWu_Guide_Btn5_Tips;
	g_DuanWu_Guide_Tip[6] 		= DuanWu_Guide_Btn6_Tips;
	g_DuanWu_Guide_Tip[7] 		= DuanWu_Guide_Btn7_Tips;
	g_DuanWu_Guide_Tip[8] 		= DuanWu_Guide_Btn8_Tips;
	g_DuanWu_Guide_Tip[9] 		= DuanWu_Guide_BtnGift_Tips;
	g_DuanWu_Guide_Tip[10] 		= DuanWu_Guide_Btn9_Tips;

end
--=========
-- Event
--=========
function DuanWu_Guide_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 89311701) then --
		if this:IsVisible() then
			DuanWu_Guide_Close()
			return
		end
		AskServerTimeAgain()
		DuanWu_Guide_Open()
		this:Show()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
		DuanWu_Guide_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		DuanWu_Guide_Close()

	elseif event == "ADJEST_UI_POS" then

		DuanWu_Guide_On_ResetPos()

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89311702) then --显示小红点

		for index=1,table.getn(g_DuanWu_Guide_Button)  do
			local DataState = Get_XParam_INT(index-1)
			local TipsState = math.mod(DataState, 10)
			local ButtonState = math.floor(DataState / 10)

			g_Button_Guide_StateTemp[index] = ButtonState
			g_Tips_Guide_StateTemp[index]  = TipsState
		end
		DuanWu_Guide_ShowButtonTips()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 44000106 then --显示小红点

		g_Tips_Guide_StateTemp[4] = Get_XParam_INT(0)
		DuanWu_Guide_ShowButtonTips()

	elseif event == "UI_COMMAND"  and tonumber(arg0) == 44000306 then
		g_Tips_Guide_StateTemp[8] = Get_XParam_INT(1)
		DuanWu_Guide_ShowButtonTips()

	elseif event == "UI_COMMAND"  and tonumber(arg0) == 50509701 then --隐藏节日礼包按钮
		g_Tips_Guide_StateTemp[9] = 0
		g_Button_Guide_StateTemp[9] = 0
		if g_DuanWu_Guide_Button[9] ~= nil then
			g_DuanWu_Guide_Button[9]:Hide()
		end
	end

end

--=========
-- 重置
--=========
function DuanWu_Guide_On_ResetPos()

	DuanWu_Guide_Frame:SetProperty("UnifiedPosition", g_DuanWu_Guide_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function DuanWu_Guide_Close()
	this:Hide()
end

--=========
-- 打开
--=========
function DuanWu_Guide_Open()
	for index=1,table.getn(g_DuanWu_Guide_Tip) do
		g_DuanWu_Guide_Tip[index]:Hide()
		g_DuanWu_Guide_Button[index]:Hide()
	end

	for index=1,table.getn(g_DuanWu_Guide_Tip)  do
		 local DataState = Get_XParam_INT(index-1)
		 local TipsState = math.mod(DataState, 10)
		 local ButtonState = math.floor(DataState / 10)

		 g_Button_Guide_StateTemp[index] = ButtonState
		 g_Tips_Guide_StateTemp[index] 	    = TipsState

		-- 领礼包按钮的显隐与红点显隐同步
		if index == 9 then
			g_Button_Guide_StateTemp[index] = TipsState
		end
	end

	local curDay = DataPool:GetServerDayTime()
	for index=1,table.getn(g_DuanWu_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   	= g_Tips_Guide_StateTemp[index]
		local event  			= g_DuanWu_Guide_Event[index]

		if isButtonShow == 1 then
			g_DuanWu_Guide_Button[index]:Show()
			if curDay < event.begtime then
				g_DuanWu_Guide_Button[index]:SetToolTip(event.btntips_unbeg)
			elseif curDay >= event.begtime and curDay <= event.endtime then
				g_DuanWu_Guide_Button[index]:SetToolTip(event.btntips_doing)
			elseif curDay > event.endtime then
				g_DuanWu_Guide_Button[index]:SetToolTip(event.btntips_end)
			end
			if isTipsShow == 1 then
				g_DuanWu_Guide_Tip[index]:Show()
			end
			event.isShow = 1
		end
	end
	--DuanWu_Guide_Btn7:Hide()
	--设置小红点
	DuanWu_Guide_ShowButtonTips()
end

--===============================================
-- 设置Button 小红点
--===============================================
function DuanWu_Guide_ShowButtonTips()

	for index=1,table.getn(g_DuanWu_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   = g_Tips_Guide_StateTemp[index]
		
		if isButtonShow == 1 then
			if isTipsShow == 1 then
				g_DuanWu_Guide_Tip[index]:Show()
			else
				g_DuanWu_Guide_Tip[index]:Hide()
			end
		end
	end

	local IsShowMiniMapPoint = 0
	for index=1,table.getn(g_Tips_Guide_StateTemp) do
		if g_Tips_Guide_StateTemp[index] == 1 then
			IsShowMiniMapPoint = 1
			break
		end
	end

	--PushEvent("2019DUANWU_TIPS",  IsShowMiniMapPoint)
	Lua_ShowQuickEnterPointTip(16, IsShowMiniMapPoint)

end

--===============================================
-- 打开各个功能界面
--===============================================
function DuanWu_Guide_Clicked( clickId )
	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then
		if curDay < g_DuanWu_Guide_Event[clickId].begtime then
			PushDebugMessage("#{QHNF_190429_01}")
			return
		elseif curDay > g_DuanWu_Guide_Event[clickId].endtime then
			PushDebugMessage("#{QHNF_190429_01}")
			return
		else
			local nLevel = Player:GetLevel();
			if nLevel < 30 then
				PushDebugMessage("#{QHNF_190429_02}")
				return
			end
		end
		local bRet = AutoRuntoTargetExWithName(269, 185, 1, "赛龙舟")
		if 0 == bRet then
			PushDebugMessage("无法自动寻路")
			return
		end
		PushDebugMessage("#{QHNF_190429_06}")

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetRedPoint")
			Set_XSCRIPT_ScriptID(891137)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()

	elseif clickId == 2 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("ClickButton")
				Set_XSCRIPT_ScriptID(893118)
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()

			local nLevel = Player:GetLevel();
			if nLevel < 30 then
				PushDebugMessage("#{DWDH_190502_08}")
				return
			end

			local curDay = DataPool:GetServerDayTime()
			if curDay < g_DuanWu_Guide_Event[clickId].begtime or curDay > g_DuanWu_Guide_Event[clickId].endtime then
				PushDebugMessage("#{DWDH_190502_07}")
				return
			end
			local bRet = AutoRuntoTargetExWithName(347, 197, 1, "包宗之")
			if 0 == bRet then
				PushDebugMessage("无法自动寻路")
				return
			end
			PushDebugMessage("#{QHNF_190429_97}")
	elseif clickId == 3 then
		--更新红点
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetRedPoint" )
			Set_XSCRIPT_ScriptID(505083)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		local nLevel = Player:GetLevel();
		if nLevel < 30 then
			PushDebugMessage("#{QHNF_190429_02}")
			return
		end

		local curDay = DataPool:GetServerDayTime()
		if curDay < g_DuanWu_Guide_Event[clickId].begtime or curDay > g_DuanWu_Guide_Event[clickId].endtime then
			PushDebugMessage("#{QHNF_190429_01}")
			return
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenCreditShop" )
			Set_XSCRIPT_ScriptID( 505083 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()

	elseif clickId == 4 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID(440001)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 5 then
		if curDay < g_DuanWu_Guide_Event[clickId].begtime then
			PushDebugMessage("#{QHNF_190429_01}")
			return
		elseif curDay > g_DuanWu_Guide_Event[clickId].endtime then
			PushDebugMessage("#{QHNF_190429_01}")
			return
		else
			local nLevel = Player:GetLevel();
			if nLevel < 30 then
				PushDebugMessage("#{QHNF_190429_02}")
				return
			end
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpen" )
			Set_XSCRIPT_ScriptID(505088)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()

	elseif clickId == 6 then
		if curDay < g_DuanWu_Guide_Event[clickId].begtime then
			PushDebugMessage("#{QHNF_190429_01}")
			return
		elseif curDay > g_DuanWu_Guide_Event[clickId].endtime then
			PushDebugMessage("#{QHNF_190429_01}")
			return
		else
			local nLevel = Player:GetLevel();
			if nLevel < 30 then
				PushDebugMessage("#{QHNF_190429_02}")
				return
			end
		end
		local bRet = AutoRuntoTargetExWithName(347, 197, 1, "包宗之")
		if 0 == bRet then
			PushDebugMessage("无法自动寻路")
			return
		end
		PushDebugMessage("#{QHNF_190429_08}")
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetRedPoint")
			Set_XSCRIPT_ScriptID(891153)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 7 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID(505087)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 8 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowClientUI")
			Set_XSCRIPT_ScriptID(440003)
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_Parameter(2, 0)
			Set_XSCRIPT_Parameter(3, 0)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif clickId == 9 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID( 505097)
			Set_XSCRIPT_ParamCount( 0 )
		Send_XSCRIPT()
	elseif clickId == 10 then
		if curDay < g_DuanWu_Guide_Event[clickId].begtime then
			PushDebugMessage("#{ZZZH_220418_2}")
			return
		elseif curDay > g_DuanWu_Guide_Event[clickId].endtime then
			PushDebugMessage("#{ZZZH_220418_2}")
			return
		else
			local nLevel = Player:GetLevel();
			if nLevel < 30 then
				PushDebugMessage("#{ZZZH_220418_3}")
				return
			end
		end
		local bRet = AutoRuntoTargetExWithName(296, 188, 1, "邢护卫")
		if 0 == bRet then
			PushDebugMessage("无法自动寻路")
			return
		end
		PushDebugMessage("#{ZZZH_220418_91}")
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetRedPoint")
			Set_XSCRIPT_ScriptID(998018)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end

	--关闭本界面
	--改为互斥关闭
	--this:Hide()

end
