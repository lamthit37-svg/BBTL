local g_Anniversary2022_Frame_UnifiedXPosition
local g_Anniversary2022_Frame_UnifiedYPosition

local g_Anniversary2022_ButtonList={}
local g_Anniversary2022_PlayerList={}
local g_Anniversary2022_ButtonListOpen={}

local g_Anniversary2022_LastSignDate =0
local g_Anniversary2022_SignStep =0

local g_Anniversary2022_SignStepMax =5

g_Anniversary2022_ButtonTips_Undo={
	[1]="#{BSLK_220211_10}",
	[2]="#{BSLK_220211_14}",
	[3]="#{BSLK_220211_18}",
	[4]="#{BSLK_220211_22}",
	[5]="#{BSLK_220211_26}",
	[6]="#{BSLK_220211_30}",
	[7]="#{BSLK_220211_34}",
	[8]="#{BSLK_220211_38}",
}

g_Anniversary2022_ButtonTips_KAJI_Undo={
	[1]="#{BSLK_220211_11}",
	[2]="#{BSLK_220211_15}",
	[3]="#{BSLK_220211_19}",
	[4]="#{BSLK_220211_23}",
	[5]="#{BSLK_220211_27}",
	[6]="#{BSLK_220211_31}",
	[7]="#{BSLK_220211_35}",
	[8]="#{BSLK_220211_39}",
}

g_Anniversary2022_ButtonTips_do={
	[1]="#{BSLK_220211_12}",
	[2]="#{BSLK_220211_16}",
	[3]="#{BSLK_220211_20}",
	[4]="#{BSLK_220211_24}",
	[5]="#{BSLK_220211_28}",
	[6]="#{BSLK_220211_32}",
	[7]="#{BSLK_220211_36}",
	[8]="#{BSLK_220211_40}",
}

g_Anniversary2022_ButtonTips_KAJI_do={
	[1]="#{BSLK_220211_13}",
	[2]="#{BSLK_220211_17}",
	[3]="#{BSLK_220211_21}",
	[4]="#{BSLK_220211_25}",
	[5]="#{BSLK_220211_29}",
	[6]="#{BSLK_220211_33}",
	[7]="#{BSLK_220211_37}",
	[8]="#{BSLK_220211_41}",
}

g_Anniversary2022_SignPosUnifiedPosition={
	[0]="{{0.000000,54.000000},{0.000000,65.000000}}",
	[1]="{{0.000000,237.000000},{0.000000,80.000000}}",
	[2]="{{0.000000,387.000000},{0.000000,103.000000}}",
	[3]="{{0.000000,542.000000},{0.000000,130.000000}}",
	[4]="{{0.000000,312.000000},{0.000000,220.000000}}",
	[5]="{{0.000000,444.000000},{0.000000,279.000000}}",
}

g_Anniversary2022_SignPos={
	[0]={posx=54,posY=65},
	[1]={posx=237,posY=80},
	[2]={posx=387,posY=103},
	[3]={posx=542,posY=130},
	[4]={posx=312,posY=220},
	[5]={posx=444,posY=279},
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Anniversary2022_Yure_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Anniversary2022_Yure_OnLoad()
	-- 保存界面的默认相对位置
	g_Anniversary2022_Frame_UnifiedXPosition	= Anniversary2022_Yure_FrameNULL:GetProperty("UnifiedXPosition");
	g_Anniversary2022_Frame_UnifiedYPosition	= Anniversary2022_Yure_FrameNULL:GetProperty("UnifiedYPosition");

	g_Anniversary2022_ButtonList[1]=Anniversary2022_Yure_Day1
	g_Anniversary2022_ButtonList[2]=Anniversary2022_Yure_Day2
	g_Anniversary2022_ButtonList[3]=Anniversary2022_Yure_Day3
	g_Anniversary2022_ButtonList[4]=Anniversary2022_Yure_Day4
	g_Anniversary2022_ButtonList[5]=Anniversary2022_Yure_Day5


	g_Anniversary2022_ButtonListOpen[1]=Anniversary2022_Yure_Day1_Open
	g_Anniversary2022_ButtonListOpen[2]=Anniversary2022_Yure_Day2_Open
	g_Anniversary2022_ButtonListOpen[3]=Anniversary2022_Yure_Day3_Open
	g_Anniversary2022_ButtonListOpen[4]=Anniversary2022_Yure_Day4_Open
	g_Anniversary2022_ButtonListOpen[5]=Anniversary2022_Yure_Day5_Open




end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Anniversary2022_Yure_ResetPos()
	Anniversary2022_Yure_FrameNULL:SetProperty("UnifiedXPosition", g_Anniversary2022_Frame_UnifiedXPosition);
	Anniversary2022_Yure_FrameNULL:SetProperty("UnifiedYPosition", g_Anniversary2022_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Anniversary2022_Yure_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 88896401 then

		local g_Anniversary2022_LastSignDate = tonumber(Get_XParam_INT(0))
		local g_Anniversary2022_SignStep = tonumber(Get_XParam_INT(1))
		local g_Anniversary2022_refresh = tonumber(Get_XParam_INT(2))
		if g_Anniversary2022_refresh == 1 then
			if (this:IsVisible()) then
			--	return
			end
			Anniversary2022_Yure_Show(g_Anniversary2022_LastSignDate,g_Anniversary2022_SignStep)
		elseif g_Anniversary2022_refresh == 2 then
			if (this:IsVisible()) then
				Anniversary2022_Yure_Refresh(g_Anniversary2022_LastSignDate,g_Anniversary2022_SignStep)
			end
		elseif g_Anniversary2022_refresh == 3 then
			if (this:IsVisible()) then
				Anniversary2022_Yure_SignMove(g_Anniversary2022_LastSignDate,g_Anniversary2022_SignStep)
			end
		end

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Anniversary2022_Yure_Hide()
	elseif event == "ADJEST_UI_POS" then
		Anniversary2022_Yure_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Anniversary2022_Yure_ResetPos()
	end
end

--显示UI
function Anniversary2022_Yure_Show(LastSignDate,SignStep)

	--宝箱和tooltips显示
	for i = 1, table.getn(g_Anniversary2022_ButtonList) do
	--已完成签到
		if i<= SignStep then
			g_Anniversary2022_ButtonList[i]:Hide()
			g_Anniversary2022_ButtonListOpen[i]:Show()
		--	g_Anniversary2022_ButtonList[i]:SetImage("CircularTaskTool78","CircularTaskTool78_13")
		--	if KaJi:LuaFnIsKaJiServer() ~= 1 then
				g_Anniversary2022_ButtonListOpen[i]:SetToolTip(g_Anniversary2022_ButtonTips_do[i])
		--	else
		--		g_Anniversary2022_ButtonList[i]:SetToolTip(g_Anniversary2022_ButtonTips_KAJI_do[i])
		--	end
	--未完成签到
		else
			g_Anniversary2022_ButtonListOpen[i]:Hide()
			g_Anniversary2022_ButtonList[i]:Show()
		--	g_Anniversary2022_ButtonList[i]:SetImage("JinLi3","JinLiBook_BoxBtn2_Normal")
		--	if KaJi:LuaFnIsKaJiServer() ~= 1 then
				g_Anniversary2022_ButtonList[i]:SetToolTip(g_Anniversary2022_ButtonTips_Undo[i])
		--	else
		--		g_Anniversary2022_ButtonList[i]:SetToolTip(g_Anniversary2022_ButtonTips_KAJI_Undo[i])
		--	end
		end
	end

	Anniversary2022_Yure_Start:Show()
	Anniversary2022_Yure_Start:SetProperty("UnifiedPosition", g_Anniversary2022_SignPosUnifiedPosition[SignStep]);
	if SignStep == 3 then
		Anniversary2022_Yure_Start:SetProperty("Animate", "Anniversary2022_Yure_PandaLeft")
	else
		Anniversary2022_Yure_Start:SetProperty("Animate", "Anniversary2022_Yure_Panda")
	end


	local curDay = tonumber(DataPool:GetServerDayTime());
	if SignStep == g_Anniversary2022_SignStepMax then
		Anniversary2022_Yure_ButtonImage:SetImage("Anniversary2022_Yure","Anniversary2022_Yure_Over")
		Anniversary2022_Yure_ButtonImage:Show()
		Anniversary2022_Yure_Guide_Button:Disable()
		Anniversary2022_Yure_Guide_Tips:Hide()
	elseif LastSignDate == curDay then
		Anniversary2022_Yure_ButtonImage:SetImage("Anniversary2022_Yure","Anniversary2022_Yure_TodayOK")
		Anniversary2022_Yure_ButtonImage:Show()
		Anniversary2022_Yure_Guide_Button:Disable()
		Anniversary2022_Yure_Guide_Tips:Hide()
	else
		Anniversary2022_Yure_ButtonImage:Hide()
		Anniversary2022_Yure_Guide_Button:Enable()
		Anniversary2022_Yure_Guide_Tips:Show()
	end

	this:Show()
end
--刷新界面
function Anniversary2022_Yure_Refresh(LastSignDate,SignStep)
		--宝箱和tooltips显示
	for i = 1, table.getn(g_Anniversary2022_ButtonList) do
	--完成签到
		if i<= SignStep then
			g_Anniversary2022_ButtonList[i]:Hide()
			g_Anniversary2022_ButtonListOpen[i]:Show()
			g_Anniversary2022_ButtonListOpen[i]:SetToolTip(g_Anniversary2022_ButtonTips_do[i])
	--未完成签到
		else
			g_Anniversary2022_ButtonListOpen[i]:Hide()
			g_Anniversary2022_ButtonList[i]:Show()
			g_Anniversary2022_ButtonList[i]:SetToolTip(g_Anniversary2022_ButtonTips_Undo[i])
		end
	end


--	Anniversary2022_Yure_Start:Show()
--	Anniversary2022_Yure_Start:SetProperty("UnifiedPosition", g_Anniversary2022_SignPosUnifiedPosition[SignStep]);


	local curDay = tonumber(DataPool:GetServerDayTime());
	if SignStep == g_Anniversary2022_SignStepMax then
		Anniversary2022_Yure_ButtonImage:SetImage("YanMen2025","YanMen2025_Yure_Down")
		Anniversary2022_Yure_ButtonImage:Show()
		Anniversary2022_Yure_Guide_Button:Disable()
		Anniversary2022_Yure_Guide_Tips:Hide()
	elseif LastSignDate == curDay then
		Anniversary2022_Yure_ButtonImage:SetImage("YanMen2025","YanMen2025_Yure_TodayDown")
		Anniversary2022_Yure_ButtonImage:Show()
		Anniversary2022_Yure_Guide_Button:Disable()
		Anniversary2022_Yure_Guide_Tips:Hide()
	else
		Anniversary2022_Yure_ButtonImage:Hide()
		Anniversary2022_Yure_Guide_Button:Enable()
		Anniversary2022_Yure_Guide_Tips:Show()
	end
end


function Anniversary2022_Yure_SignMove(LastSignDate,SignStep)
	if SignStep < 1 or SignStep > 5 then
		return
	end
	local posX_from = g_Anniversary2022_SignPos[SignStep-1].posx
	local posY_from = g_Anniversary2022_SignPos[SignStep-1].posY

	local posX_To = g_Anniversary2022_SignPos[SignStep].posx
	local posY_To = g_Anniversary2022_SignPos[SignStep].posY

	local  from_to = string.format("curve:Liner mode:Once duration:1 startx:%s starty:%s endx:%s endy:%s",0 ,0 , posX_To-posX_from, posY_To-posY_from)

	Anniversary2022_Yure_Start:Tween_SetInfo("Position", from_to)

	Anniversary2022_Yure_Start:Tween_Play("Position", true, true)

	Anniversary2022_Yure_Refresh(LastSignDate,SignStep)

end

--隐藏UI
function Anniversary2022_Yure_Hide()
	this:Hide()
end

--关闭界面
function Anniversary2022_Yure_Close()
	this:Hide()
end

function Anniversary2022_Yure_Help_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("2022YuReHelp")
		Set_XSCRIPT_ScriptID(888964)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

function Anniversary2022_Yure_Guide_Clicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnSignClick")
		Set_XSCRIPT_ScriptID(888964)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


