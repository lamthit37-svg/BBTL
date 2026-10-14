local g_Anniversary_Frame_UnifiedPosition;


--===============================================
-- 这一段是为了动态显示Button Tips ---------begin
--===============================================
--local g_Anniversary_Event = {
--	[1] = {text="",  isShow=0  ,Tooltips="#{ZNJM_150430_9}"},	 	--七日签
--	[2] = {text="",  isShow=0  ,Tooltips="#{SYZN_180313_06}"},		--喜相迎
--	[3] = {text="",  isShow=0 ,Tooltips="#{ZNJM_150430_18}"},	 	--飞凰礼
--	[4] = {text="",  isShow=0 ,Tooltips="#{ZNJM_150430_23}"},	 	--开门令
--	[5] = {text="",  isShow=0 ,Tooltips="#{ZNJM_150430_10}"},	 	--灯如昼
--	[6] = {text="",  isShow=0 ,Tooltips="#{ZNJM_150430_21}"},		--龙征途
--
--};


--local g_Button_StateTemp = {1,1,1,1,1,1}
--local g_Tips_StateTemp = {0,0,0,0,0,0}

--local g_Anniversary_Button =
--{
--}
--
--local g_Anniversary_Tip =
--{
--}

local g_Anniversary_Frames =
{
}
local g_Xingqi =
{

}

local g_TimeDRegion = {
	[1] = {BeginTime=20180501,EndTime=20180503,Index=2},  --灯
	[2] = {BeginTime=20180504,EndTime=20180508,Index=1},  --七
	[3] = {BeginTime=20180511,EndTime=20180514,Index=2},  --灯
	[4] = {BeginTime=20180509,EndTime=20180509,Index=3},  --礼
	[5] = {BeginTime=20180510,EndTime=20180510,Index=1},  --七
}

local g_TimeLimitDRegion = {
	[1] = {BeginTime=20200501,EndTime=20200515,Index=1},  --七
	[2] = {BeginTime=20180501,EndTime=20180514,Index=2},  --灯
	[3] = {BeginTime=20200501,EndTime=20200509,Index=3},  --礼
	[4] = {BeginTime=20180501,EndTime=20180514,Index=4},  --贺
	[5] = {BeginTime=20180501,EndTime=20180514,Index=5},  --锦
	[6] = {BeginTime=20180501,EndTime=20180514,Index=6},  --途
}


local g_EventIndex = -1 --当前选中的选项
local g_Anniversary_ButtonCDTime = 1; --按钮冷却时间
local g_Anniversary_ButtonLastTime = 0;
local g_Anniversary_LastClickedId = -1; --上次选中的选项
local g_Anniversary_EventIndex = -1 --当前选中的选项



--七日签 begin
local g_7HIT_TIMES =
{
	[1] = {TIMES=20260506}, 
	[2] = {TIMES=20260507},  
	[3] = {TIMES=20260508},  
	[4] = {TIMES=20260509},  
	[5] = {TIMES=20260510}, 
	[6] = {TIMES=20260511}, 
	[7] = {TIMES=20260512}, 
}

local g_DayTime =
{
	[0] = {Day="6"},
	[1] = {Day="7"},
	[2] = {Day="8"},
	[3] = {Day="9"},
	[4] = {Day="10"},
	[5] = {Day="11"},
	[6] = {Day="12"},
}

local g_7HIT_BUTTON_STATUS =
{
    [0] = {BUTTON="#{KLHB_180313_75}"}, --待解
	[1] = {BUTTON="#{KLHB_180313_74}"}, --小吉
	[2] = {BUTTON="#{KLHB_180313_73}"},  --吉
	[3] = {BUTTON="#{KLHB_180313_72}"},  --大吉
}

local g_7HIT_BUTTON_SIGN =
{
	["BuLing"] = {BUTTON=""},
	["YiLing"] = {BUTTON="set:Sign image:Sign_ok"},
}
local g_7HIT_Frames =
{
	[1] = {DRAW="#{SYZN_180313_25}",Fortune="#{SYZN_180313_30}"},
	[2] = {DRAW="#{SYZN_180313_26}",Fortune="#{SYZN_180313_31}"},
	[3] = {DRAW="#{SYZN_180313_27}",Fortune="#{SYZN_180313_32}"},
	[4] = {DRAW="#{SYZN_180313_28}",Fortune="#{SYZN_180313_33}"},
	[5] = {DRAW="#{SYZN_180313_29}",Fortune="#{SYZN_180313_34}"},
}
local g_7HITActionButton={}
local g_Anniversary_7HIT_Button ={}
local g_7HITActionButton_Mask ={}
local g_7HITActionButton_OutSide ={}
local g_Anniversary_7HIT_ButtonTips={}
local g_Anniversary_7HIT_Red ={}
local g_Anniversary_7HIT_Animate ={}
local g_Anniversary_7HIT_Resign ={}
local Anniversary_7HIT_ButtonText ={}
--七日签 end


-- 武林之巅活动时间
local Anniversary_g_WLZD_StartTime = 20200522
local Anniversary_g_WLZD_EndTime = 20200607


--开门令活动时间和等级限制
local g_KaiMenLing_StartTime = 20260506 --20250506 --20230505 --20210506 --20200504 --20190506 --20180504
local g_KaiMenLing_59Time = 20260509 --20250509 --20230509 --20210509 --20200509 --20190509 --20180509
local g_KaiMenLing_EndTime = 20260512 --20250512 --20230511 --20210512 --20200510 --20190512 --20180510
local g_KaiMenLing_LevelLimit = 30
local g_KaiMenLing_RewardLimit = 1
--口令长度 暂定7个中文字符 等策划定
local g_KaiMenLing_StrLimit = 7
local g_KaiMenLing_PerRet = 0

--活动时间段
g_Anniversary_KML_ActiveTime_Begin=1900
g_Anniversary_KML_ActiveTime_End=2310
g_Anniversary_KML_UnActiveTime1=0000
g_Anniversary_KML_UnActiveTime2=2400

g_Anniversary_7KML_RedPointFlag = 0
g_Anniversary_KML_MF = 5520
g_Anniversary_KML_DateMD = 3432
g_Anniversary_KML_7HITMD = 3433

--每日口令
g_Anniversary_KML_CommandEnum =
{
	[1] = "侠客丹心",
	[2] = "银鞍白马",
	[3] = "纵横江湖",
	[4] = "十九周年",
	[5] = "风云际会",
	[6] = "群雄争霸",
	[7] = "问鼎天下",
}

--关联控件 开门令
local g_KaiMenLing_RemainTips;
local g_KaiMenLing_EditBox;
local g_KaiMenLing_Command_Button;
local g_KaiMenLing_Help_Button;
local g_KaiMenLing_59Tips;
local g_KaiMenLing_TodayRemainTips;
local g_Anniversary_KMLTip


local g_ZidianLottery_ActionButton = {};
local g_ZidianLottery_ActionButton2 = {};
local g_bIsDownTickStart=0
local g_Anniversary_DiffDay=0
local g_Anniversary_ActivePoint=0
local g_Anniversary_Limit=0
local g_Anniversary_IsShowTick =0

--周年愿 Begin
local g_Anniversary_ZNY_Name = {};
local g_Anniversary_ZNY_RewardAction = {};

--重开需要改
--MD_ZHOUNIANYUAN_DATA_2025=3177        --灯如昼活动 2025
local g_Anniversary_ZNY_DATA = 3368 
--重开需要改

--local g_Anniversary_WJDH_Total = 2271 --万家灯火总数量
--local g_Anniversary_WJDH_DayNum = 1530	--万家灯火每日数量

local g_Anniversary_ZNY_RewardList ={
	[1] = {38002789, 10141520, 38006315},
	--[2] = {38005776, 10146876, 39910125},
	--[3] = {38002789, 10141520, 20501005},
}


-- --重开需要改
-- local g_ZNY_StartDayTime	=	20250410	--活动开始时间
-- local g_ZNY_EndDayTime	=	20250430	--活动结束时间
-- --重开需要改

--local g_ZNY_XuYuanDayTime =   20220509    --许愿时间
local g_ZNY_AwardTime	=	21	--抽奖时间

local g_KJ_DENGRUZHOU	= 57
local g_ZNY_Max_HuoYue = 450
local g_ZNY_Max_HuoYue_KaJi = 150
--周年愿 End

--妙手织锦
local g_Anniversary_ZhiBu_StartTime = 20190426
local g_Anniversary_ZhiBu_EndTime = 20190515
--画意洞天
local g_Anniversary_HYDT_StartTime =20190426
local g_Anniversary_HYDT_EndTime =20190522
--返场时装
local g_Anniversary_FanChang_Fashion =39921696
local g_Anniversary_FanChang_ZhenShou =39921192
--===============================================
-- PreLoad()
--===============================================
function Anniversary_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OPEN_ANNIVERSARY_BEFORE",true)		--
	this:RegisterEvent("OPEN_ANNIVERSARY",true)		--
	this:RegisterEvent("PLAYER_LEAVE_WORLD")		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化
	this:RegisterEvent("ON_SCENE_TRANS",true)  				--场景转移（切场景前调用）
	this:RegisterEvent("PLAYER_ENTERING_WORLD",true)		-- 进入游戏世界
	this:RegisterEvent("UPDATE_ZHOUNIANYUAN_NAME",false )
	this:RegisterEvent("RESET_ALLUI")  --返回登录界面
	this:RegisterEvent("TODAY_ACTIVE_POINT",false)
end

--===============================================
-- OnEvent()
--===============================================
function Anniversary_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == 20180330) then --七日签点击
		Anniversary_Project_Clicked(1,1)

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 23200501) then --更新开门令状态
		--打开界面

		--传入变量  INT(0)是否在活动期间 0没开始 1开始了  -1结束了
		--INT(1)是否输入过今日口令  INT(2) 当日口令索引   INT(3)第一次传令标记  INT(4)第二次传令标记
		--INT(5)第三次传令标记  INT(6)第四次传令标记   INT(7)第五次传令标记
		Open_Anniversary_KML_Data(Get_XParam_INT(0),Get_XParam_INT(1), Get_XParam_INT(2), Get_XParam_INT(3))

	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50603602) then
		g_bIsDownTickStart = Get_XParam_INT(0);
		g_Anniversary_ActivePoint = Get_XParam_INT(1);
		g_Anniversary_DiffDay = Get_XParam_INT(2);
		g_Anniversary_Limit = Get_XParam_INT(3);
		Anniversary_OpenZiDian()

		this:Show()		
		Anniversary_Page3:Show()

	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 50603605 ) then
		g_bIsDownTickStart = Get_XParam_INT( 0 );		--是否开始的标志
		g_Anniversary_ActivePoint = Get_XParam_INT( 1 );		--倒计时时间
		g_Anniversary_DiffDay = Get_XParam_INT( 2 );
		g_Anniversary_Limit = Get_XParam_INT(3);
		Anniversary_Zidian_ShowDownTick()

	elseif (event == "OPEN_ANNIVERSARY") then
		--PushDebugMessage("OPEN_ANNIVERSARY")
		local nClick =  tonumber(arg0)
		Anniversary_Project_Clicked(nClick,1)
	elseif (event == "PLAYER_LEAVE_WORLD") then
		Anniversary_Close()
	elseif(event == "RESET_ALLUI") then
		KillTimer("Anniversary_UpdateKMLRedPoint()")
	elseif (event == "ADJEST_UI_POS") then
		Anniversary_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Anniversary_On_ResetPos()
	elseif (event == "ON_SCENE_TRANS" ) then				-- 开门令小红点每5秒检测切场景前kill
		KillTimer("Anniversary_UpdateKMLRedPoint()")
	elseif (event == "PLAYER_ENTERING_WORLD" ) then				-- 开门令小红点每5秒检测进入场景set
		SetTimer("Anniversary","Anniversary_UpdateKMLRedPoint()", 5000) --5秒刷新
		Anniversary_GetButtonStatus()
	elseif(event == "UPDATE_ZHOUNIANYUAN_NAME") then
		Anniversary_ZNY_Update(arg0, arg1, arg2, 1)

	elseif( event == "UI_COMMAND" and tonumber( arg0 ) == 89272602 ) then
		if this:IsVisible() then
			AskServerTimeAgain()
			local time = Get_XParam_INT(0)
			Anniversary_ZNY_UpdateButton(time)
		end

	elseif( event == "UI_COMMAND" and tonumber( arg0 ) == 89272309 ) then --灯如昼界面
		Anniversary_Project_Clicked(5,0)
	-- 龙征图点数刷新
	elseif( event == "UI_COMMAND" and tonumber( arg0 ) == 920190412 ) then
		if this:IsVisible() then
			local nPoint1 = Get_XParam_INT(0)
			local nPoint2 = Get_XParam_INT(1)
			local nPoint3 = Get_XParam_INT(2)
			local nPoint4 = Get_XParam_INT(3)
			if nil == nPoint1 then
				nPoint1 = 0
			end
			if nil == nPoint2 then
				nPoint2 = 0
			end
			if nil == nPoint3 then
				nPoint3 = 0
			end
			if nil == nPoint4 then
				nPoint4 = 0
			end
			local strPoint1 = ScriptGlobal_Format("#{LZWZ_180313_217}", nPoint1)
			local strPoint2 = ScriptGlobal_Format("#{LZWZ_180313_217}", nPoint2)
			local strPoint3 = ScriptGlobal_Format("#{LZWZ_180313_217}", nPoint3)
			local strPoint4 = ScriptGlobal_Format("#{LZWZ_180313_217}", nPoint4)

			Anniversary_LZT_SkyText01		: SetText(strPoint1)
			Anniversary_LZT_EarthText01		: SetText(strPoint2)
			Anniversary_LZT_PeopleText01	: SetText(strPoint3)
			Anniversary_LZT_SunText01		: SetText(strPoint4)
		end
	elseif ( event == "TODAY_ACTIVE_POINT" ) then
		local nTodayPoint = Player:GetData("TODAYACTIVEPOINT")
		local kjtype   = KaJi:LuaFnGetKaJiType(g_KJ_DENGRUZHOU)
		if kjtype == 1 then
			if nTodayPoint > g_ZNY_Max_HuoYue_KaJi then
				nTodayPoint = g_ZNY_Max_HuoYue_KaJi
			end
			Anniversary_Page2_ItemTimes2:SetText(ScriptGlobal_Format("#{HDRZ_230403_13}", nTodayPoint))
		else
			if nTodayPoint > g_ZNY_Max_HuoYue then
				nTodayPoint = g_ZNY_Max_HuoYue
			end
			Anniversary_Page2_ItemTimes2:SetText(ScriptGlobal_Format("#{HDRZ_210309_05}", nTodayPoint))
		end
	end
end

--===============================================
-- OnLoad()
--===============================================
function Anniversary_OnLoad()
	Anniversary_SetButtonPos()
	g_Anniversary_Frame_UnifiedPosition = Anniversary_Frame_BK:GetProperty("UnifiedPosition")


	--7HIT领奖框
	g_7HITActionButton[1] =  Anniversary_Page1_one
	g_7HITActionButton[2] =  Anniversary_Page1_two
	g_7HITActionButton[3] =  Anniversary_Page1_three
	g_7HITActionButton[4] =  Anniversary_Page1_four
	g_7HITActionButton[5] =  Anniversary_Page1_five
	g_7HITActionButton[6] =  Anniversary_Page1_six
	g_7HITActionButton[7] =  Anniversary_Page1_seven

	g_7HITActionButton_OutSide[1] =  Anniversary_Page1_one_Button
	g_7HITActionButton_OutSide[2] =  Anniversary_Page1_two_Button
	g_7HITActionButton_OutSide[3] =  Anniversary_Page1_three_Button
	g_7HITActionButton_OutSide[4] =  Anniversary_Page1_four_Button
	g_7HITActionButton_OutSide[5] =  Anniversary_Page1_five_Button
	g_7HITActionButton_OutSide[6] =  Anniversary_Page1_six_Button
	g_7HITActionButton_OutSide[7] =  Anniversary_Page1_seven_Button

	g_Xingqi[1] =  Anniversary_Page1_oneText
	g_Xingqi[2] =  Anniversary_Page1_twoText
	g_Xingqi[3] =  Anniversary_Page1_threeText
	g_Xingqi[4] =  Anniversary_Page1_fourText
	g_Xingqi[5] =  Anniversary_Page1_fiveText
	g_Xingqi[6] =  Anniversary_Page1_sixText
	g_Xingqi[7] =  Anniversary_Page1_sevenText

	g_7HITActionButton_Mask[1] =  Anniversary_Page1_oneMark
	g_7HITActionButton_Mask[2] =  Anniversary_Page1_twoMark
	g_7HITActionButton_Mask[3] =  Anniversary_Page1_threeMark
	g_7HITActionButton_Mask[4] =  Anniversary_Page1_fourMark
	g_7HITActionButton_Mask[5] =  Anniversary_Page1_fiveMark
	g_7HITActionButton_Mask[6] =  Anniversary_Page1_sixMark
	g_7HITActionButton_Mask[7] =  Anniversary_Page1_sevenMark

	g_Anniversary_7HIT_Red[1] =  Anniversary_Page1_one_Tips
	g_Anniversary_7HIT_Red[2] =  Anniversary_Page1_two_Tips
	g_Anniversary_7HIT_Red[3] =  Anniversary_Page1_threeTips
	g_Anniversary_7HIT_Red[4] =  Anniversary_Page1_four_Tips
	g_Anniversary_7HIT_Red[5] =  Anniversary_Page1_five_Tips
	g_Anniversary_7HIT_Red[6] =  Anniversary_Page1_six_Tips
	g_Anniversary_7HIT_Red[7] =  Anniversary_Page1_seven_Tips

	--g_Anniversary_7HIT_Animate[1] =  Anniversary_Page1_oneAnimate
	--g_Anniversary_7HIT_Animate[2] =  Anniversary_Page1_twoAnimate
	--g_Anniversary_7HIT_Animate[3] =  Anniversary_Page1_threeAnimate
	--g_Anniversary_7HIT_Animate[4] =  Anniversary_Page1_fourAnimate
	--g_Anniversary_7HIT_Animate[5] =  Anniversary_Page1_fiveAnimate
	--g_Anniversary_7HIT_Animate[6] =  Anniversary_Page1_sixAnimate
	--g_Anniversary_7HIT_Animate[7] =  Anniversary_Page1_sevenAnimate

	g_Anniversary_7HIT_Resign[1] =  Anniversary_Page1_oneResign
	g_Anniversary_7HIT_Resign[2] =  Anniversary_Page1_twoResign
	g_Anniversary_7HIT_Resign[3] =  Anniversary_Page1_threeResign
	g_Anniversary_7HIT_Resign[4] =  Anniversary_Page1_fourResign
	g_Anniversary_7HIT_Resign[5] =  Anniversary_Page1_fiveResign
	g_Anniversary_7HIT_Resign[6] =  Anniversary_Page1_sixResign
	g_Anniversary_7HIT_Resign[7] =  Anniversary_Page1_sevevResign

	g_Anniversary_7HIT_Button[1] = Anniversary_Page1_one_LotteryButton
	g_Anniversary_7HIT_Button[2] = Anniversary_Page1_two_LotteryButton
	g_Anniversary_7HIT_Button[3] = Anniversary_Page1_three_LotteryButton
	g_Anniversary_7HIT_Button[4] = Anniversary_Page1_four_LotteryButton
	g_Anniversary_7HIT_Button[5] = Anniversary_Page1_five_LotteryButton
	g_Anniversary_7HIT_Button[6] = Anniversary_Page1_six_LotteryButton
	g_Anniversary_7HIT_Button[7] = Anniversary_Page1_seven_LotteryButton

	--开门令控件
	g_KaiMenLing_59Tips = Anniversary_Page1_Text4
	g_KaiMenLing_RemainTips = Anniversary_Page1_Main1_Text
	g_KaiMenLing_EditBox = Anniversary_Page1_KouLingNum
	g_KaiMenLing_Command_Button = Anniversary_Page4_ChuanLing_Button
	g_KaiMenLing_Help_Button = Anniversary_Page4_ChuanLing_Button_Help
	g_Anniversary_KMLTip = Anniversary_Page4_ChuanLing_Button_Tips
	g_KaiMenLing_TodayRemainTips = Anniversary_Page1_Main1_Times

	g_ZidianLottery_ActionButton[1] = Anniversary_Page3_Button1;
	g_ZidianLottery_ActionButton[2] = Anniversary_Page3_Button2;
	g_ZidianLottery_ActionButton[3] = Anniversary_Page3_Button3;
	g_ZidianLottery_ActionButton[4] = Anniversary_Page3_Button4;
	g_ZidianLottery_ActionButton[5] = Anniversary_Page3_Button5;
	
	g_ZidianLottery_ActionButton2[1] = Anniversary_Page3_BK2_Button1;
	g_ZidianLottery_ActionButton2[2] = Anniversary_Page3_BK2_Button2;
	g_ZidianLottery_ActionButton2[3] = Anniversary_Page3_BK2_Button3;
	g_ZidianLottery_ActionButton2[4] = Anniversary_Page3_BK2_Button4;


	Anniversary_7HIT_ButtonText[1] = Anniversary_Page1_one_LotteryButtonText
	Anniversary_7HIT_ButtonText[2] = Anniversary_Page1_two_LotteryButtonText
	Anniversary_7HIT_ButtonText[3] = Anniversary_Page1_three_LotteryButtonText
	Anniversary_7HIT_ButtonText[4] = Anniversary_Page1_four_LotteryButtonText
	Anniversary_7HIT_ButtonText[5] = Anniversary_Page1_five_LotteryButtonText
	Anniversary_7HIT_ButtonText[6] = Anniversary_Page1_six_LotteryButtonText
	Anniversary_7HIT_ButtonText[7] = Anniversary_Page1_seven_LotteryButtonText

	--周年愿 Begin
	g_Anniversary_ZNY_Name[1] = Anniversary_Page2_Name1;
	g_Anniversary_ZNY_Name[2] = Anniversary_Page2_Name2;
	g_Anniversary_ZNY_Name[3] = Anniversary_Page2_Name3;


	g_Anniversary_ZNY_RewardAction[1] = Anniversary_Page2_RewardIcon1;
	g_Anniversary_ZNY_RewardAction[2] = Anniversary_Page2_RewardIcon2;
	g_Anniversary_ZNY_RewardAction[3] = Anniversary_Page2_RewardIcon3;

	--周年愿 End

end
--===============================================
-- SetButtonPos()
--===============================================
function Anniversary_SetButtonPos()
	g_Anniversary_Frames =
	{
		[1] = Anniversary_Page1,
		[2] = Anniversary_Page5,
		[3] = Anniversary_LZT,			-- 江湖美卷 龙征途和聚义令共用的界面
		[4] = Anniversary_Page3,
		[5] = Anniversary_Page2,
		[6] = Anniversary_Page4,
		[7] = Anniversary_Page7, --, Anniversary_Page8
		[8] = nil,
		[9] = nil,
		[10] = Anniversary_Page9,
		[11] = Anniversary_Page10,
	}

end

--===============================================
-- Hide()
--===============================================
function Anniversary_Hide()

end

--===============================================
-- Close()
--===============================================
function Anniversary_Close()
		
	for i = 1 , table.getn(g_ZidianLottery_ActionButton) do
		g_ZidianLottery_ActionButton[i]:SetActionItem(-1)
	end
		
	for i = 1 , table.getn(g_ZidianLottery_ActionButton2) do
		g_ZidianLottery_ActionButton2[i]:SetActionItem(-1)
	end
	
	DataPool:Lua_ClearZiDianZengYingHaoActionItem();

	this:Hide();
end
--===============================================
-- ResetPos()
--===============================================
function Anniversary_On_ResetPos()
	Anniversary_Frame_BK:SetProperty("UnifiedPosition", g_Anniversary_Frame_UnifiedPosition)
end

--===============================================
-- Open()
--===============================================
function  Anniversary_Open(nAnniversary)

--		for index=1,table.getn(g_Anniversary_Event) do
--			local event = g_Anniversary_Event[index]
--			event.isShow = 0
--		end
--
--		for index=1,table.getn(g_Anniversary_Button) do
--			g_Anniversary_Button[index]:Hide()
--			g_Anniversary_Tip[index]:Hide()
--		end
--
--		for index=1,table.getn(g_Anniversary_Button)  do
--			 local ButtonState,TipsState = DataPool:Lua_GetAnniversaryButtonState(index-1)
--			 g_Button_StateTemp[index] 	 = ButtonState
--			 g_Tips_StateTemp[index] 	   = TipsState
--		end
--
--		local buttonId = 1
--		for index=1,table.getn(g_Anniversary_Event) do
--			local isButtonShow = g_Button_StateTemp[index]
--			local isTipsShow   = g_Tips_StateTemp[index]
--			local event  = g_Anniversary_Event[index]
--
--			if isButtonShow == 1 then
--				g_Anniversary_Button[buttonId]:SetText(event.text)
--				g_Anniversary_Button[buttonId]:SetToolTip(event.Tooltips)
--				g_Anniversary_Button[buttonId]:Show()
--
--				if isTipsShow == 1 then
--					g_Anniversary_Tip[buttonId]:Show()
--				end
--				event.isShow = 1
--				buttonId = buttonId+1
--			end
--		end
--
--	if nAnniversary == 0 then   --如果等于0
--		local curDay = tonumber(DataPool:GetServerDayTime());
--		local nIsBreak = 0
--		for index=1,table.getn(g_TimeDRegion)  do
--			if curDay >= g_TimeDRegion[index].BeginTime and curDay <= g_TimeDRegion[index].EndTime then
--				local localbuttonId = 0
--				for j_index=1,table.getn(g_Anniversary_Event) - 1 do  --时间里面索引
--					local event = g_Anniversary_Event[j_index]
--					if event.isShow == 1   then--界面能展示
--						localbuttonId = localbuttonId + 1
--						if g_TimeDRegion[index].Index == j_index then
--							nIsBreak = 1
--							Anniversary_Project_Clicked( localbuttonId ,0)
--							break
--						end
--					end
--				end
--			end
--		end
--
--		if nIsBreak == 0 then
--			Anniversary_Project_Clicked( 2 ,0)
--		end
--		Anniversary_ShowButtonTips()
--		this:Show()
--	else --灯如昼 --策划加的需求 如果是灯如昼
--
--		Anniversary_Project_Clicked( 2 ,0)
--		Anniversary_ShowButtonTips()
--		this:Show()
--	end


end
function Anniversary_GetButtonStatus()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowButtonTips" )
		Set_XSCRIPT_ScriptID(232004)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
--===============================================
-- Clicked() 找到真正的函数
--===============================================
function Anniversary_Project_Clicked(g_EventIndex,isServer)
	g_Anniversary_LastClickedId = clickId
	-- for index=1,table.getn(g_Anniversary_Frames) do
	-- 	if nil ~= g_Anniversary_Frames[index] then
	-- 		if index~=g_EventIndex then
	-- 			g_Anniversary_Frames[index]:Hide()
	-- 		else
	-- 			g_Anniversary_Frames[index]:Show()
	-- 		end
	-- 	end
	-- end
	for k,v in pairs(g_Anniversary_Frames) do
		if nil ~= v then
			if g_EventIndex ~= k then
				v:Hide()
			else
				v:Show()
			end
		end
	end

	if 1==g_EventIndex then--七日签
		Anniversary_7Hit_Show()
	elseif 2 == g_EventIndex then --天降洪福和花车
		-- Anniversary_DragTitle : SetText("#{ZNXY_180323_24}")
		-- Clear_XSCRIPT()
		-- 	Set_XSCRIPT_Function_Name( "GetRedPoint" )
		-- 	Set_XSCRIPT_ScriptID(890676)
		-- 	Set_XSCRIPT_Parameter(0, g_EventIndex)
		-- 	Set_XSCRIPT_ParamCount(1)
		-- Send_XSCRIPT()

	-- 江湖美卷 龙征途和聚义令共用的界面
	elseif 3 == g_EventIndex then

		-- Anniversary_DragTitle : SetText("#{ZNQFC_190312_05}")
		Anniversary_DragTitle : SetText("#{SYZN_180313_72}")

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientClicked" )
			Set_XSCRIPT_ScriptID(892423)
			Set_XSCRIPT_Parameter(0, g_EventIndex)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()

	elseif 4 == g_EventIndex then --飞凰礼
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnShowClientUI" )
			Set_XSCRIPT_ScriptID( 506036 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		
		return
	elseif 5 == g_EventIndex then --灯如昼
		if (IsInTServer() == 1) then
			PushDebugMessage("#{HDRZ_180322_237}")
			return
		end	
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetRedPoint" )
			Set_XSCRIPT_ScriptID(892723)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		
		local nLevel = Player:GetLevel();
		if nLevel < 30 then
			PushDebugMessage("#{HDRZ_180322_232}")
			return
		end	

		Anniversary_ZNY_Show()
	elseif 6 == g_EventIndex then --蹴鞠
		Anniversary_DragTitle:SetText("#{SEZN_190326_61}")
		Anniversary_CuJu_Show()
		
	-- elseif 7 == g_EventIndex then--返场
--		Anniversary_DragTitle:SetText("#{SEZN_190326_60}")
--		local curDay = tonumber(DataPool:GetServerDayTime());
--		if curDay < 20190426 and curDay > 20190506 then
--			PushDebugMessage("#{ZNQFC_190312_09}")
--			return
--		end
--		if 20190426 <= curDay and curDay <=20190502 then
--			Anniversary_Page8_Text1:SetText("#{ZNQFC_190312_05}")
--		elseif 20190503 <= curDay and curDay <=20190506 then
--			Anniversary_Page8_Text1:SetText("#{ZNQFC_190312_10}")
--		end
--		Clear_XSCRIPT()
--			Set_XSCRIPT_Function_Name( "ClientClicked" )
--			Set_XSCRIPT_ScriptID(893057)
--			Set_XSCRIPT_Parameter(0, g_EventIndex)
--			Set_XSCRIPT_ParamCount(1)
--		Send_XSCRIPT()
		--5.6返场
		---写法改变了 下面的可以注释掉
		-- Clear_XSCRIPT()
		-- 	Set_XSCRIPT_Function_Name( "ClickButton" )
		-- 	Set_XSCRIPT_ScriptID(893058)
		-- 	Set_XSCRIPT_Parameter(0, g_EventIndex)
		-- 	Set_XSCRIPT_ParamCount(1)
		-- Send_XSCRIPT()
		-- Anniversary_FanChang_Show() 
	elseif 8 == g_EventIndex then--妙手织锦
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetRedPoint" )
			Set_XSCRIPT_ScriptID(893070)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
		local curDay = DataPool:GetServerDayTime()
		if curDay < g_Anniversary_ZhiBu_StartTime or curDay > g_Anniversary_ZhiBu_EndTime then
			PushDebugMessage("#{SEZN_190326_49}")
			return
		end
		local nLevel = Player:GetLevel();
		if nLevel < 30 then
			PushDebugMessage("#{MSZJ_190325_9}")
			return
		end
		local bRet = AutoRuntoTargetExWithName(241, 269, 0, "鹤舞")
		if 0 == bRet then
			PushDebugMessage("无法自动寻路")
			return
		end
		PushDebugMessage("#{SEZN_190326_62}")
		return
	elseif 10 == g_EventIndex then	-- 新副本H5预热游戏内部分·程序制作

		Anniversary_DragTitle : SetText("#{FBH5_200402_03}")
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientClicked" )
			Set_XSCRIPT_ScriptID(790033)
			Set_XSCRIPT_Parameter(0, g_EventIndex)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()

	-- elseif 10 == g_EventIndex  then --画意洞天 
	-- 	Anniversary_HuaYiDongTian_Show()
	-- 	return
	elseif 11 == g_EventIndex then
		-- 武林之巅（爬塔）促参与
		Anniversary_DragTitle : SetText("#{XFBZL_200331_06}")
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientClicked" )
			Set_XSCRIPT_ScriptID(893398)
			Set_XSCRIPT_Parameter(0, g_EventIndex)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		
	elseif 12 == g_EventIndex then
		--清空购物车
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID(888392)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()

		--关闭引导界面
		PushEvent( "CLOSE_ANNIVERSARY_GUIDE" )

		return
		
	else
		return
	end
	--关闭引导界面
	PushEvent( "CLOSE_ANNIVERSARY_GUIDE" )
	this:Show()
end
--===============================================
-- 七日签
--===============================================
function Anniversary_7Hit_Show()

		Anniversary_DragTitle:SetText("#{KLHB_180313_81}")
		--领奖物品更新
		--Ps:anniversary_7hit.txt中的行数。就一行所以为0. 正式服是0 卡级服是1 删减服是2
		local kjtype   = KaJi:LuaFnGetKaJiType(69)
		if KaJi:LuaFnIsKaJiServer() == 1 and kjtype == 1 then
			DataPool:Lua_UpdateAnniversaryBonusItem(1)
		elseif 1 == Player:GetData("IsOriginalJD") then
			DataPool:Lua_UpdateAnniversaryBonusItem(2)
		else
			DataPool:Lua_UpdateAnniversaryBonusItem(0)
		end

		for i = 1 , 7 do
			local theAction = EnumAction(i-1, "anniversary_item");
			g_7HITActionButton[i]:SetActionItem(-1);
			g_7HITActionButton[i]:SetActionItem(theAction:GetID());
			g_7HITActionButton_Mask[i]:Hide()
		end

		local nLocalAnniversary= {}
		local nLocalAnniversaryGetBonus= {}
		for i=0,6 do
			local temp = DataPool:Lua_GetAnniversary7HIT(i, g_Anniversary_KML_7HITMD)
			table.insert(nLocalAnniversary,temp)

		end

		for i=0,6 do
			local temp = DataPool:Lua_GetAnniversary7HIT(i, g_Anniversary_KML_DateMD)
			table.insert(nLocalAnniversaryGetBonus,temp)
		end

		local curDay = DataPool:GetServerDayTime()

		--Anniversary_Page1_Lottery_Info2:SetText("#{SYZN_180313_20}")
		for i=1,7  do
			    --按钮状态
				local Status = nLocalAnniversary[i]
				g_Anniversary_7HIT_Button[i]:Enable()
				if curDay == g_7HIT_TIMES[i].TIMES then  --当天
					if Status >  0 then --已领取 		--点击穿透 悬浮Tips穿透
						Anniversary_7HIT_ButtonText[i]:SetText(g_7HIT_BUTTON_STATUS[Status].BUTTON)
						g_Anniversary_7HIT_Button[i]:SetToolTip("#{KLHB_180313_26}")

						Anniversary_7HIT_ButtonText[i]:SetProperty("MouseLButtonHollow","True")
						Anniversary_7HIT_ButtonText[i]:SetProperty("MouseMoveHollow","True")
						Anniversary_7HIT_ButtonText[i]:SetProperty("MouseHollow","True")
					else --未领取  --点击穿透 悬停Tips穿透
						Anniversary_7HIT_ButtonText[i]:SetProperty("MouseLButtonHollow","True")
						Anniversary_7HIT_ButtonText[i]:SetProperty("MouseMoveHollow","True")
						Anniversary_7HIT_ButtonText[i]:SetProperty("MouseHollow","True")
					end
				elseif tonumber(curDay) > tonumber(g_7HIT_TIMES[i].TIMES) then --时间过了
					--g_Anniversary_7HIT_Button[i]:Enable()
					if Status >  0 then --已领取 											--状态3 定义：签被抽或被补抽之后，变为状态3；        点击穿透 悬浮Tips穿透
						Anniversary_7HIT_ButtonText[i]:SetText(g_7HIT_BUTTON_STATUS[Status].BUTTON)
						g_Anniversary_7HIT_Button[i]:SetToolTip("#{KLHB_180313_26}")

						Anniversary_7HIT_ButtonText[i]:SetProperty("MouseLButtonHollow","True")
						Anniversary_7HIT_ButtonText[i]:SetProperty("MouseMoveHollow","True")
						Anniversary_7HIT_ButtonText[i]:SetProperty("MouseHollow","True")
					else
						Anniversary_7HIT_ButtonText[i]:SetProperty("MouseLButtonHollow","True")
						Anniversary_7HIT_ButtonText[i]:SetProperty("MouseMoveHollow","True")
						Anniversary_7HIT_ButtonText[i]:SetProperty("MouseHollow","True")
					end
				elseif curDay < g_7HIT_TIMES[i].TIMES then  --未到展示时间 						--状态1 定义：当时间未到该签可开抽的时间时，该签为状态1         点击穿透悬浮 不穿透
					Anniversary_7HIT_ButtonText[i]:SetText(g_7HIT_BUTTON_STATUS[0].BUTTON)
					g_Anniversary_7HIT_Button[i]:SetToolTip("#{KLHB_180313_25}")   --现在还不是查看这支签文的时候    按钮的处理
					local tooltip = ScriptGlobal_Format("#{KLHB_180313_29}",g_DayTime[i-1].Day)
					g_7HITActionButton[i]:SetToolTip(tooltip)

				end

				--物品领取状态
				g_Anniversary_7HIT_Red[i]:Hide()
				--g_7HITActionButton_Mask[i]:Hide()
				--g_Anniversary_7HIT_Animate[i]:Hide()
				g_Anniversary_7HIT_Resign[i]:Hide();
				local BonusStatus = nLocalAnniversaryGetBonus[i]
				if curDay == g_7HIT_TIMES[i].TIMES then  --当天
					if BonusStatus ==  0 then --未领取												--状态2 --每个签都只可在对应的日期0时至24时抽，若在当日且未抽，则该签为
						--g_Anniversary_7HIT_Animate[i]:Show()
						g_7HITActionButton_OutSide[i]:SetToolTip("#{KLHB_180313_27}")
						g_Anniversary_7HIT_Red[i]:Show()
					elseif BonusStatus >  0 then --已领取
						g_7HITActionButton_Mask[i]:SetProperty("Image",g_7HIT_BUTTON_SIGN["YiLing"].BUTTON)										--状态3 定义：签被抽或被补抽之后，变为状态3；
						g_7HITActionButton_OutSide[i]:SetToolTip("#{KLHB_180313_30}")
						g_7HITActionButton_Mask[i]:Show()
					end
				elseif tonumber(curDay) > tonumber(g_7HIT_TIMES[i].TIMES) then --时间过了
					if BonusStatus ==  0 then --未领取
						g_Anniversary_7HIT_Resign[i]:Show();
						--g_7HITActionButton_Mask[i]:SetProperty("Image",g_7HIT_BUTTON_SIGN["BuLing"].BUTTON)
						--g_7HITActionButton_Mask[i]:Show()
						g_7HITActionButton_OutSide[i]:SetToolTip("#{KLHB_180313_28}")

					elseif BonusStatus >  0 then --已领取

						g_7HITActionButton_Mask[i]:SetProperty("Image",g_7HIT_BUTTON_SIGN["YiLing"].BUTTON)										--状态3 定义：签被抽或被补抽之后，变为状态3；
						g_7HITActionButton_OutSide[i]:SetToolTip("#{KLHB_180313_30}")
						g_7HITActionButton_Mask[i]:Show()
					end
				elseif curDay < g_7HIT_TIMES[i].TIMES then  --未到展示时间 						--状态1 定义：当时间未到该签可开抽的时间时，该签为状态1
					g_7HITActionButton[i]:SetToolTip("#{KLHB_180313_25}")   --现在还不是查看这支签文的时候    按钮的处理
					local tooltip = ScriptGlobal_Format("#{KLHB_180313_29}",g_DayTime[i-1].Day)
					g_7HITActionButton_OutSide[i]:SetToolTip(tooltip)
				end

				local xingqi = ScriptGlobal_Format("#{KLHB_180313_31}",g_DayTime[i-1].Day)
				g_Xingqi[i]:SetText(xingqi)


		end

	--刷新开门令状态
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("UpdateKaiMenLing")
		Set_XSCRIPT_ScriptID(232005)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


function Anniversary_GetItemPrize(Key)

	local curDay = tonumber(DataPool:GetServerDayTime());
	local nLocalAnniversary= {}
	for i=0,6 do
		local temp = DataPool:Lua_GetAnniversary7HIT(i,g_Anniversary_KML_DateMD)
		table.insert(nLocalAnniversary,temp)
	end
	if  0 == nLocalAnniversary[Key] and curDay == g_7HIT_TIMES[Key].TIMES then  --当天未领


		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "7HITDayGetBonus" )
			Set_XSCRIPT_ScriptID(232005)
			Set_XSCRIPT_Parameter(0, Key-1)
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_Parameter(2, 0)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()

	elseif   nLocalAnniversary[Key] ==0 and curDay < g_7HIT_TIMES[Key].TIMES then  --日期未到 未领取
		local Str = ScriptGlobal_Format("#{BZNMR_150129_27}",g_DayTime[Key-1].Day)
		PushDebugMessage(Str)
	elseif  nLocalAnniversary[Key] >0 and nLocalAnniversary[Key] <=4 and curDay >= g_7HIT_TIMES[Key].TIMES then  --当天已领取
		PushDebugMessage("#{BZNMR_150129_28}")
	elseif   0 == nLocalAnniversary[Key] and curDay > g_7HIT_TIMES[Key].TIMES then --未领
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "7HITDayGetBonus" )
			Set_XSCRIPT_ScriptID(232005)
			Set_XSCRIPT_Parameter(0, Key-1)
			Set_XSCRIPT_Parameter(1, 2) -- 是不是补领标记，2是补领操作
			Set_XSCRIPT_Parameter(2, 0) --元宝二次确认标记
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()



	--elseif  nLocalAnniversary[Key] == 5 and curDay > g_7HIT_TIMES[Key].TIMES then --领了 解签
	--		--Anniversary_Page1_Lottery_Info1:SetText("#{SYZN_180313_23}")--上
	--		local tooltip = ScriptGlobal_Format("#{SYZN_180313_35}",g_7HIT_Frames[5].DRAW,g_7HIT_Frames[5].Fortune)
			--Anniversary_Page1_Lottery_Info2:SetText(tooltip)
	--elseif  nLocalAnniversary[Key] > 0 and nLocalAnniversary[Key] <=4 and curDay > g_7HIT_TIMES[Key].TIMES then --领了 解签
	--		local status = nLocalAnniversary[Key]
			--Anniversary_Page1_Lottery_Info1:SetText("#{SYZN_180313_24}")--上上
	--		local tooltip = ScriptGlobal_Format("#{SYZN_180313_35}",g_7HIT_Frames[status].DRAW,g_7HIT_Frames[status].Fortune)
	--		--Anniversary_Page1_Lottery_Info2:SetText(tooltip)
	end

end

function Anniversary_GetItemQianWen(Key)

	local curDay = tonumber(DataPool:GetServerDayTime());
	local nLocalAnniversary= {}
	for i=0,6 do
		local temp = DataPool:Lua_GetAnniversary7HIT(i, g_Anniversary_KML_7HITMD)
		table.insert(nLocalAnniversary,temp)
	end

	if   nLocalAnniversary[Key] >0 and nLocalAnniversary[Key] <=4 then  --当天领取
		local nAnniversary = nLocalAnniversary[Key]

		PushEvent("UPDATE_QIANWEN",  nAnniversary)
	else

		local tooltip = ScriptGlobal_Format("#{KLHB_180313_77}",g_DayTime[Key-1].Day)
		PushDebugMessage(tooltip)
	end

end

--===============================================
-- 开门令-begin
--===============================================

--==================================
--检查是否在满足活动时间和等级
--==================================
function KaiMenLing_IsOnActiveDay()
	--活动时间和等级判断
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nLevel = Player:GetLevel();
	if curDay < g_KaiMenLing_StartTime or curDay > g_KaiMenLing_EndTime then
		PushDebugMessage("#{KLHB_180313_10}"); --现在不是活动时间，无法进行此操作
		return 0
	end
	if nLevel < g_KaiMenLing_LevelLimit then
		PushDebugMessage("#{KLHB_180313_11}"); --您的等级不足50级，无法参与该活动
		return 0
	end
	return 1
end

--==================================
--检查是否在活动的每日输入口令时间段
--==================================
function Anniversary_KML_IsInActiveTime()
	--return 0 在活动开始前
	--return -1 活动结束了
	local curDay = tonumber(DataPool:GetServerDayTime());
	if curDay < g_KaiMenLing_StartTime then
		return 0
	elseif curDay > g_KaiMenLing_EndTime then
		return -1
	end

	--1在第一时间段 2在第二时间段 3在第三时间段
	--11提示的下次是第一时间段 12提示的下次是第二时间段 13提示的下次是第三时间段
	--活动时间段的计算
	local CurTime =  tonumber(DataPool:GetServerMinuteTime());
	local curHour = math.floor(CurTime/10000)
	if curHour >= g_Anniversary_KML_ActiveTime_Begin then
		curHour = curHour - g_Anniversary_KML_ActiveTime_Begin
	end
	temp = math.mod(CurTime, 10000)
	local curMin = math.floor(temp/100)
	local CurTimeUse = curHour*100 + curMin

	if CurTimeUse >= g_Anniversary_KML_UnActiveTime1 and CurTimeUse < g_Anniversary_KML_ActiveTime_Begin then
		return 11
	elseif CurTimeUse >= g_Anniversary_KML_ActiveTime_Begin and CurTimeUse <= g_Anniversary_KML_ActiveTime_End then
		return 1
	elseif CurTimeUse > g_Anniversary_KML_ActiveTime_End and CurTimeUse <= g_Anniversary_KML_UnActiveTime2 then
		return 12
	end

	return 0
end


--================================================
-- 显示传口令界面 nIsHaveCommand 是否输入过今日口令
--nTodayCommandIndex 今日口令
--================================================
function KaiMenLing_InPutCommand(nIsHaveCommand,nTodayCommandIndex)
	--tips 请输入开门口令：
	g_KaiMenLing_RemainTips:SetText( "#{KLHB_180313_07}" )
	--传令按钮可响应
	g_KaiMenLing_Command_Button:Show()
	g_KaiMenLing_Command_Button:Enable()
	g_KaiMenLing_Command_Button:SetText("#{KLHB_180313_76}")
	g_KaiMenLing_Help_Button:Show()

	if nIsHaveCommand == 0 then
		g_KaiMenLing_EditBox:Enable()
		g_KaiMenLing_EditBox:SetText("")
		g_KaiMenLing_EditBox:SetProperty("DefaultEditBox", "True");
	else
		g_KaiMenLing_EditBox:Disable()
		g_KaiMenLing_EditBox:SetText(tostring(g_Anniversary_KML_CommandEnum[nTodayCommandIndex]));
		g_KaiMenLing_EditBox:SetProperty("DefaultEditBox", "False");
	end
end


--================================================
-- 显示非活动期间传口令界面
--================================================
function KaiMenLing_ShowNextTips(nNextTips,nIsHaveCommand)
	--tips 下一次开启时间：下次开门有礼时间为：%s0：00-%s1：10
	if nNextTips == 1 then
		--local tips = ScriptGlobal_Format("#{KLHB_180313_04}",string.sub(g_Anniversary_KML_ActiveTime_Begin,1,2),string.sub(g_Anniversary_KML_ActiveTime_Begin,1,2))
		g_KaiMenLing_RemainTips:SetText("#{KLHB_180313_04}")
	elseif nNextTips == 6 then
		--五次已发放
		g_KaiMenLing_RemainTips:SetText( "#{KLHB_180313_05}" )
	elseif nNextTips == 7 then
		--三次已领取
		g_KaiMenLing_RemainTips:SetText( "#{KLHB_180313_78}" )
	end
	--传令按钮可响应
	g_KaiMenLing_Command_Button:Show()
	g_KaiMenLing_Command_Button:Enable()
	g_KaiMenLing_Command_Button:SetText("#{KLHB_180313_76}")
	g_KaiMenLing_Help_Button:Show()
	g_KaiMenLing_EditBox:Disable()
	if nIsHaveCommand == 0 then
		g_KaiMenLing_EditBox:SetText("暂不可输入口令" ) --暂不可输入口令
	else
		local nTodayCommand,nIndex = GetTodayCommand()
		g_KaiMenLing_EditBox:SetText(nTodayCommand) --已经正确校验过一次口令
	end
	g_KaiMenLing_EditBox:SetProperty("DefaultEditBox", "False")
end

--==================================
--获得当日口令接口
--==================================
function GetTodayCommand()
	local curDayIndex =tonumber(DataPool:GetServerDayTime()) - g_KaiMenLing_StartTime + 1
	local DayIndexMix =g_KaiMenLing_EndTime - g_KaiMenLing_StartTime + 1
	if  0 < curDayIndex  and curDayIndex <= DayIndexMix  then
		return  g_Anniversary_KML_CommandEnum[curDayIndex],curDayIndex
	end

	return "",0
end

--================================================
-- 初始化界面显示
--传入变量
--INT(0)是否输入过今日口令  INT(1) 当日口令索引   INT(2)第一次传令标记  INT(3)第二次传令标记
--INT(4)第三次传令标记  INT(5)第四次传令标记   INT(6)第五次传令标记
--================================================
function Open_Anniversary_KML_Data(nRet,nIsHaveCommand , nTodayCommandIndex ,  nCommand_State )

--	PushDebugMessage("Open_Anniversary_KML_Data "..--nRet="..nRet.." nIsHaveCommand="..nIsHaveCommand.." nTodayIndex="..nTodayCommandIndex..
--						" nCommand="..nCommand_State)

	g_KaiMenLing_PerRet = nRet
	local curClient = Anniversary_KMLRedPointState()
	if curClient == 1 then
		g_Anniversary_KMLTip:Show()
	else
		g_Anniversary_KMLTip:Hide()
	end

	g_KaiMenLing_Help_Button:SetToolTip("#{KLHB_180313_70}")
	if nRet == 0 then
		--活动没开始
		g_KaiMenLing_RemainTips:SetText("#{KLHB_180313_63}")
		g_KaiMenLing_EditBox:Disable()
		g_KaiMenLing_EditBox:SetText("")
		g_KaiMenLing_Command_Button:Hide()
		g_KaiMenLing_Command_Button:Disable()
		g_KaiMenLing_Command_Button:SetText("")
		g_KaiMenLing_Help_Button:Hide()
		g_KaiMenLing_TodayRemainTips:Hide()
		return
	elseif nRet == -1 then
		--活动结束了
		g_KaiMenLing_RemainTips:SetText("#{KLHB_180313_64}")
		g_KaiMenLing_EditBox:Disable()
		g_KaiMenLing_EditBox:SetText("")
		g_KaiMenLing_Command_Button:Hide()
		g_KaiMenLing_Command_Button:Disable()
		g_KaiMenLing_Command_Button:SetText("")
		g_KaiMenLing_Help_Button:Hide()
		g_KaiMenLing_TodayRemainTips:Hide()
		g_KaiMenLing_59Tips:Hide()
		return
	end

	--只显示开门令界面
	local curDay = tonumber(DataPool:GetServerDayTime());
	if curDay >= g_KaiMenLing_StartTime and curDay < g_KaiMenLing_59Time then
		g_KaiMenLing_59Tips:Show()
		g_KaiMenLing_59Tips:SetText( "#{KLHB_180313_02}" )
	elseif curDay == g_KaiMenLing_59Time then
		g_KaiMenLing_59Tips:Show()
		g_KaiMenLing_59Tips:SetText( "#{KLHB_180313_03}" )
	else
		g_KaiMenLing_59Tips:Hide()
	end

	local nCount = nCommand_State
	local todayRemain = ScriptGlobal_Format("#{KLHB_180313_79}",nCount)
	--今日领取0/3
	g_KaiMenLing_TodayRemainTips:SetText(todayRemain)
	if nRet < 16 and nCount >= g_KaiMenLing_RewardLimit then
		--今日已经领取过三次
		KaiMenLing_ShowNextTips(7,nIsHaveCommand)
		return
	end

	if nRet < 10 then
		--活动时间段
		if (nRet == 1 and nCommand_State == 0) then
			KaiMenLing_InPutCommand(nIsHaveCommand,nTodayCommandIndex)
			return
		else
			--非输入口令活动时间段
			KaiMenLing_ShowNextTips(nRet + 1,nIsHaveCommand)
		end
	else
		--非输入口令活动时间段
		KaiMenLing_ShowNextTips(nRet-10,nIsHaveCommand)
		return
	end

end


--================================================
-- 传口令按钮
--================================================
function KaiMenLing_Button_Clicked()
	--活动时间和等级判断
	if KaiMenLing_IsOnActiveDay() == 0 then
		return
	end

	--时段是否有改变 有改变先刷新
	local nRet = Anniversary_KML_IsInActiveTime()
	if g_KaiMenLing_PerRet~= nRet then
		--刷新界面
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UpdateKaiMenLing" )
			Set_XSCRIPT_ScriptID(232005)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		return
	end


	if nRet == 0 then
		--活动还没开始
		PushDebugMessage("#{KLHB_180313_61}")
		return
	end

	if nRet == -1 then
		--活动结束了
		PushDebugMessage("#{KLHB_180313_62}")
		return
	end

	if nRet > 10 then
		--活动时间段
		PushDebugMessage("#{KLHB_180313_12}")
		return
	end


	-- 得到输入的字符串
	local txt = g_KaiMenLing_EditBox:GetItemElementsString();
	--local str = g_KaiMenLing_EditBox:GetText();

	if (txt==nil or txt=="") then
		--请先输入口令！
		PushDebugMessage("#{KLHB_180313_16}")
		return
	end

	if tonumber(string.len(txt)) > tonumber(g_KaiMenLing_StrLimit*2) then
		--少侠的口令貌似不太对哦
		PushDebugMessage("#{KLHB_180313_17}")
		return
	end

	local nTodayCommand,nIndex = GetTodayCommand()
	if txt ~= nTodayCommand then
		PushDebugMessage("#{KLHB_180313_17}")
		return
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "CheckCommand" )
			Set_XSCRIPT_ScriptID(232005)
			Set_XSCRIPT_Parameter(0,nIndex)
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end

end


--================================================
-- 开门令活动说明
--================================================
function Anniversary_KML_Help_Clicked()
	--弹出说明
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("KMLHelp")
		Set_XSCRIPT_ScriptID(232005)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--================================================
-- 开门令+七日签小红点更新
--================================================
function Anniversary_UpdateKMLRedPoint()
	--只在活动时间10+1分钟内更新
	local flag = DataPool:Lua_IsGameRunning()
	if flag ~= 1 then
		KillTimer("Anniversary_UpdateKMLRedPoint()")
		return
	end
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nLevel = Player:GetLevel();
	if curDay < g_KaiMenLing_StartTime or curDay > g_KaiMenLing_EndTime then
		KillTimer("Anniversary_UpdateKMLRedPoint()")
		return
	end
	if nLevel < g_KaiMenLing_LevelLimit then
		return
	end
	
	local curClient = Anniversary_KMLRedPointState()
	if curClient ~= g_Anniversary_7KML_RedPointFlag then
		--跟服务器请求下同步
		Anniversary_GetButtonStatus()
		g_Anniversary_7KML_RedPointFlag = curClient
			
		if this:IsVisible() then		
			--刷新开门令状态
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("UpdateKaiMenLing")
				Set_XSCRIPT_ScriptID(232005)
				Set_XSCRIPT_Parameter(0, 0)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end
	end
end

--================================================
-- 开门令+七日签小红点状态
--================================================
function Anniversary_KMLRedPointState()
	local nKMLflag = 0
	if Player:GetLevel() < g_KaiMenLing_LevelLimit then
		return nKMLflag
	end
	local nRet = Anniversary_KML_IsInActiveTime()
	local MF = Pneuma:GetMF(g_Anniversary_KML_MF)
	local total = MF
	if total >= g_KaiMenLing_RewardLimit then
		return nKMLflag
	end
	if nRet==1 and MF == 0 then
		nKMLflag = 1
	end
	return nKMLflag
end


--===============================================
-- 开门令-end
--===============================================

--===============================================
-- 飞凰礼start
--===============================================
function Anniversary_OpenZiDian()
	Anniversary_DragTitle:SetText("#{ZDZYH_180418_56}")	
	Anniversary_Page3_Text1:SetText(ScriptGlobal_Format("#{ZDZYH_151012_9}", g_Anniversary_Limit))
	
	Anniversary_Zidian_ShowDownTick()

	-- 底图修改
	Anniversary_Page3_BK:Hide()
	Anniversary_Page3_BK2:Hide()
	if g_Anniversary_DiffDay <= 1 then
		Anniversary_Page3_BK2:Show()
		Anniversary_Page3_Left_Image:SetProperty("Image", "set:Anniversary23 image:Anniversary_ditu2")
	elseif g_Anniversary_DiffDay >= 3 then
		Anniversary_Page3_BK2:Show()
		Anniversary_Page3_Left_Image:SetProperty("Image", "set:Anniversary23 image:Anniversary_ditu4")
	else
		Anniversary_Page3_BK:Show()
		Anniversary_Page3_Left_Image:SetProperty("Image", "set:Anniversary23 image:Anniversary_ditu5")
	end
	
	-- 道具修改
	if g_Anniversary_DiffDay <= 1 then -- 第一天
		DataPool:Lua_ClearZiDianZengYingHaoActionItem();
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 0, 39921692 );		--坐骑：霞上仙（90天，绑定） 
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 1, 39921674 );		--坐骑：霞上仙（30天，绑定）
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 2, 39925322 );		--新主题坐骑（7天，绑定）
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 3, 39921404 );		--飞凰献礼礼包
		DataPool:Lua_UpdateZiDianZengYingHaoActionItem();
		for i = 1 , 4 do
			local theAction = EnumAction(i - 1, "zidianzengyinghao")
			if theAction:GetID() ~= 0 then
				g_ZidianLottery_ActionButton2[i]:SetActionItem(theAction:GetID())
			end
		end	
	elseif g_Anniversary_DiffDay >= 3 then -- 第三天
		DataPool:Lua_ClearZiDianZengYingHaoActionItem();
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 0, 39923623 );		--坐骑：天马（90天，绑定） 
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 1, 39921287 );		--坐骑：天马（30天，绑定）
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 2, 39925322 );		--新主题坐骑（7天，绑定）
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 3, 39921404 );		--飞凰献礼礼包
		DataPool:Lua_UpdateZiDianZengYingHaoActionItem();
		for i = 1 , 4 do
			local theAction = EnumAction(i - 1, "zidianzengyinghao")
			if theAction:GetID() ~= 0 then
				g_ZidianLottery_ActionButton2[i]:SetActionItem(theAction:GetID())
			end
		end	
	else
		DataPool:Lua_ClearZiDianZengYingHaoActionItem();
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 0, 39921694 );		--飞凰羽翼永久
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 1, 39925319 );		--坐骑：新坐骑（永久，装绑）
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 2, 39925320 );		--坐骑：新坐骑（90天，绑定） 
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 3, 39925321 );		--坐骑：新坐骑（30天，绑定）
		DataPool:Lua_SetZiDianZengYingHaoActionItem( 4, 39921404 );		--飞凰献礼礼包
		DataPool:Lua_UpdateZiDianZengYingHaoActionItem();
		for i = 1 , 5 do
			local theAction = EnumAction(i - 1, "zidianzengyinghao")
			if theAction:GetID() ~= 0 then
				g_ZidianLottery_ActionButton[i]:SetActionItem(theAction:GetID())
			end
		end	
	end
	
end
function Anniversary_Zidian_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetPrize" )
		Set_XSCRIPT_ScriptID( 506036 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
function Anniversary_Zidian_HelpClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnZiDianShowHelp" )
		Set_XSCRIPT_ScriptID( 506036 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Anniversary_Zidian_ShowDownTick()

	Anniversary_Page3_Button:Enable();
	local strTime = "";
	if g_bIsDownTickStart == 0 then	--未开始
		strTime = "#{ZDZYH_151012_31}";
	elseif g_bIsDownTickStart == 3 then	--已领奖
		strTime = "#{ZDZYH_151012_34}";
	elseif g_bIsDownTickStart >= 1 then	--时间数字
		strTime = ScriptGlobal_Format("#{ZDZYH_230315_23}", g_Anniversary_ActivePoint)
		if g_Anniversary_ActivePoint >= g_Anniversary_Limit then	--可领奖
			strTime = "#{ZDZYH_151012_33}";
		end
	end

	--strText = ScriptGlobal_Format("#{ZDZYH_180320_47}", strTime )
	Anniversary_Page3_Text2:SetText( strTime );

end
--===============================================
-- 飞凰礼end
--===============================================

--===============================================
-- 周年愿 Begin
--======================================================
function Anniversary_ZNY_Show()
	AskServerTimeAgain()
	local curTime = tonumber(DataPool:GetServerMinuteTime())

	local curHour = math.floor(curTime/10000)
	if curHour >= 1900 then
		curHour = curHour - 1900
	end
	local curLeft = math.mod(curTime, 10000)
	local nMin = math.floor(curLeft/100)
	local nHourMinute = curHour * 100 + nMin

	if nHourMinute < g_ZNY_AwardTime * 100  then    --减少服务器时间同步延迟
		Anniversary_ZNY_Update("", "", "", 0)
	else
		DataPool:Lua_AskZhouNianYuanRankName()
	end
	Anniversary_DragTitle:SetText("#{HDRZ_180322_223}")
end

function Anniversary_ZNY_Update(nName1, nName2, nName3, flag)
	--显示奖励
	Anniversary_ZNY_UpdateReward()

	local nName = {}
	nName[1] = nName1;
	nName[2] = nName2;
	nName[3] = nName3;

	for i = 1, 3 do
		if nName[i] == "" then
			if flag == 1 then --如果没抽到，一般不会出现
				g_Anniversary_ZNY_Name[i]:SetText("#{HDRZ_180322_215}")
			else
				g_Anniversary_ZNY_Name[i]:SetText("#{HDRZ_180322_90}")
			end
		else
			g_Anniversary_ZNY_Name[i]:SetText(nName[i])
		end
	end

	
	-- 活跃值
	local nTodayPoint = Player:GetData("TODAYACTIVEPOINT")
	local kjtype   = KaJi:LuaFnGetKaJiType(g_KJ_DENGRUZHOU)
	if kjtype == 1 then
		if nTodayPoint > g_ZNY_Max_HuoYue_KaJi then
			nTodayPoint = g_ZNY_Max_HuoYue_KaJi
		end
		Anniversary_Page2_ItemTimes2:SetText(ScriptGlobal_Format("#{HDRZ_230403_13}", nTodayPoint))
	else
		if nTodayPoint > g_ZNY_Max_HuoYue then
			nTodayPoint = g_ZNY_Max_HuoYue
		end
		Anniversary_Page2_ItemTimes2:SetText(ScriptGlobal_Format("#{HDRZ_210309_05}", nTodayPoint))
	end
	
	Anniversary_ZNY_UpdateButton(0)
end

function Anniversary_ZNY_UpdateReward()
	local nServerTime = DataPool:GetServerDayTime()
	local Index = 1
	--if nServerTime == g_ZNY_XuYuanDayTime then
	--	Index = 2
	--elseif nServerTime > g_ZNY_XuYuanDayTime and nServerTime <= g_ZNY_EndDayTime then
	--	Index = 3
	--end

	for i = 1, 3 do
		local GiftItemID = g_Anniversary_ZNY_RewardList[Index][i]
		local theAction = DataPool:CreateBindActionItemForShow(GiftItemID, 1)
		if theAction:GetID() ~= 0 then
			g_Anniversary_ZNY_RewardAction[i]:SetActionItem(theAction:GetID());
			g_Anniversary_ZNY_RewardAction[i]:Show();
		end
	end
end

function Anniversary_ZNY_UpdateButton(time)
	local curTime = tonumber(DataPool:GetServerMinuteTime())
	local nHour =  math.floor(curTime/10000)
	if nHour >= 1900 then
		nHour = nHour - 1900
	end
		
	local nMD_ZNY_DATA = DataPool:GetPlayerMission_DataRound(g_Anniversary_ZNY_DATA)

	local nServerTime = DataPool:GetServerDayTime()
	local nServerDayTime = DataPool:DateTime2DayTime(nServerTime)
	local nDayTime = math.mod(math.floor(nMD_ZNY_DATA/1000), 100000)

	--服务器下发的优先
	if time > 0 then
		nHour = time
	end

	if nHour < g_ZNY_AwardTime then
		if nDayTime == nServerDayTime then --已许愿
			Anniversary_Page2_RewardButton:Enable()
			--Anniversary_Page2_RewardButton:SetText("#{HDRZ_180322_91}") HDRZ_180322_91	#Y领奖
			
			Anniversary_Page2_RewardButton:SetProperty("PushedImage","set:Anniversary_Dengruzhou image:Get_Pushed") --领奖
			Anniversary_Page2_RewardButton:SetProperty("NormalImage","set:Anniversary_Dengruzhou image:Get_Normal")
			Anniversary_Page2_RewardButton:SetProperty("HoverImage","set:Anniversary_Dengruzhou image:Get_Hover")

			Anniversary_Page2_RewardButton:SetToolTip("#{HDRZ_180322_122}")
		else
			Anniversary_Page2_RewardButton:Enable()
			--Anniversary_Page2_RewardButton:SetText("#{HDRZ_180322_214}") HDRZ_180322_214	#Y许灯愿
			Anniversary_Page2_RewardButton:SetProperty("PushedImage","set:Anniversary_Dengruzhou image:Do_Pushed") --许灯愿
			Anniversary_Page2_RewardButton:SetProperty("NormalImage","set:Anniversary_Dengruzhou image:Do_Normal")
			Anniversary_Page2_RewardButton:SetProperty("HoverImage","set:Anniversary_Dengruzhou image:Do_Hover")
			
			Anniversary_Page2_RewardButton:SetToolTip("#{HDRZ_180322_154}")
		end
		Anniversary_Page2_RewardButtonTips:Hide()
	else

		local nPrizeRank = math.floor(math.mod(nMD_ZNY_DATA, 100)/10)
		local nRevPrizeFlag = math.floor(math.mod(nMD_ZNY_DATA, 1000)/100)
		if nRevPrizeFlag == 0 then
			Anniversary_Page2_RewardButton:Enable()
			--Anniversary_Page2_RewardButton:SetText("#{HDRZ_180322_91}") --领奖
			Anniversary_Page2_RewardButton:SetProperty("PushedImage","set:Anniversary_Dengruzhou image:Get_Pushed") --领奖
			Anniversary_Page2_RewardButton:SetProperty("NormalImage","set:Anniversary_Dengruzhou image:Get_Normal")
			Anniversary_Page2_RewardButton:SetProperty("HoverImage","set:Anniversary_Dengruzhou image:Get_Hover")
			
			if nDayTime == nServerDayTime and nPrizeRank > 0 then
				Anniversary_Page2_RewardButtonTips:Show()
			else
				Anniversary_Page2_RewardButtonTips:Hide()
			end
		else
			if nDayTime == nServerDayTime then
				Anniversary_Page2_RewardButton:Disable()
				--Anniversary_Page2_RewardButton:SetText("#{HDRZ_180322_157}") --已领奖

				Anniversary_Page2_RewardButton:SetProperty("DisabledImage","set:Anniversary_Dengruzhou image:Done") --已领奖

				Anniversary_Page2_RewardButtonTips:Hide()
			else
				Anniversary_Page2_RewardButton:Enable()
				--Anniversary_Page2_RewardButton:SetText("#{HDRZ_180322_91}")
				Anniversary_Page2_RewardButton:SetProperty("PushedImage","set:Anniversary_Dengruzhou image:Get_Pushed") --领奖
				Anniversary_Page2_RewardButton:SetProperty("NormalImage","set:Anniversary_Dengruzhou image:Get_Normal")
				Anniversary_Page2_RewardButton:SetProperty("HoverImage","set:Anniversary_Dengruzhou image:Get_Hover")
			end
		end
	end
end

function Anniversary_ZNY_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("EnterForToday")
		Set_XSCRIPT_ScriptID(892726)
		Set_XSCRIPT_Parameter(0,0);
		Set_XSCRIPT_Parameter(1,0);
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function  Anniversary_Page2_Help_Clicked()
	PushEvent("OPEN_ZHOUNIANYUAN_HELP")
end
--===============================================
-- 周年愿 End
--======================================================


--===============================================
--  蹴鞠 Begin
--======================================================
function Anniversary_CuJu_Show()
	Anniversary_DragTitle : SetText("#{SEZN_190326_61}")
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClickButton")
		Set_XSCRIPT_ScriptID(402040) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
end    
--===============================================
--  蹴鞠 end
--======================================================

--===============================================
-- 画意洞天 Begin
--======================================================
function Anniversary_HuaYiDongTian_Show() 
		
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClickButton")
		Set_XSCRIPT_ScriptID(893086) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
	local nLevel = Player:GetLevel();
	if nLevel < 30 then
		PushDebugMessage("#{SEZN_190326_58}")
		return
	end
	
	local curDay = DataPool:GetServerDayTime()
	if curDay < g_Anniversary_HYDT_StartTime or curDay > g_Anniversary_HYDT_EndTime then
		PushDebugMessage("#{SEZN_190326_57}") 
		return
	end
	local bRet = AutoRuntoTargetExWithName(241, 269, 0, "鹤舞") 
	if 0 == bRet then
		PushDebugMessage("无法自动寻路")
		return
	end
	PushDebugMessage("#{SEZN_190326_62}") 
	return
end
--===============================================
-- 画意洞天 end
--======================================================

--===============================================
-- 周年返场购买 Begin
--======================================================
function Anniversary_ShiZhuangZhenShou_Click(index)
	if index == 1 then 
    	Clear_XSCRIPT()
    		Set_XSCRIPT_Function_Name("BuyFashionGift")
    		Set_XSCRIPT_ScriptID(893058)
    		Set_XSCRIPT_Parameter(0,0);
    		Set_XSCRIPT_ParamCount(1)
    	Send_XSCRIPT()
	elseif index == 2 then
    	Clear_XSCRIPT()
    		Set_XSCRIPT_Function_Name("BuyZhenShouLong")
    		Set_XSCRIPT_ScriptID(893058)
    		Set_XSCRIPT_Parameter(0,0);
    		Set_XSCRIPT_ParamCount(1)
    	Send_XSCRIPT()	
	end
end

function Anniversary_FanChang_Show()
	Anniversary_DragTitle:SetText("#{SEZN_190326_60}")
	Anniversary_Page7_Lace1_Yuanbao_text:SetText( ScriptGlobal_Format("#{ZNJB_190315_02}",46888) )
	Anniversary_Page7_Lace2_Yuanbao_text:SetText( ScriptGlobal_Format("#{ZNJB_190315_02}",15000) ) 
	--展示道具
	local theAction_Fashion = DataPool:CreateActionItemForShow(g_Anniversary_FanChang_Fashion, 1)
	if theAction_Fashion:GetID() ~= 0 then
		Anniversary_Page7_Lace1Icon:SetActionItem(theAction_Fashion:GetID());
		Anniversary_Page7_Lace1Icon:Show();
	end
	--	
	local theAction_ZhenShou = DataPool:CreateActionItemForShow(g_Anniversary_FanChang_ZhenShou, 1)
	if theAction_ZhenShou:GetID() ~= 0 then
		Anniversary_Page7_Lace2Icon:SetActionItem(theAction_ZhenShou:GetID());
		Anniversary_Page7_Lace2Icon:Show();
	end
end
--===============================================
-- 周年返场购买 End
--======================================================

--===============================================
-- 武林之巅
--======================================================
function Anniversary_WuLinZhiDian()
	local curDay = DataPool:GetServerDayTime()
	if curDay < Anniversary_g_WLZD_StartTime or curDay > Anniversary_g_WLZD_EndTime then
		PushDebugMessage("#{XFBZL_200331_03}")
		return
	end
	local nLevel = Player:GetLevel();
	if nLevel < 75 then
		PushDebugMessage("#{XFBZL_200331_04}")
		return
	end

	local bRet = AutoRuntoTargetExWithName(211, 51, 2, "武林")
	if 0 == bRet then
		PushDebugMessage("无法自动寻路")
		return
	end
	PushDebugMessage("#{XFBZL_200331_09}")
	this:Hide()
end -- end func Anniversary_WuLinZhiDian()
