
local g_Frame_UnifiedPosition
local g_CalenderDay = 0
local g_CalenderOpened = 0

local g_Day_ChuXiEve = 20260215--20250127--20240208--20230120--20220130--除夕前一天

local g_ylimag1="set:Spring1 image:Spring1_1"
local g_ylimag2="set:Spring1 image:Spring1_2"
local g_ylimag3="set:Spring1 image:Spring1_3"
local g_ylimag4="set:Spring1 image:Spring1_4"
local g_ylimag5="set:Spring1 image:Spring1_5"
local g_ylimag6="set:Spring1 image:Spring1_6"
local g_ylimag7="set:Spring1 image:Spring1_7"
local g_ylimag8="set:Spring1 image:Spring1_8"
local g_ylimag9="set:Spring1 image:Spring1_9"
local g_ylimag10="set:Spring1 image:Spring1_10"
local g_ylimagN="set:Spring1 image:Spring1_N"
local g_ylimagC="set:Spring1 image:Spring1_chu"--除
local g_ylimagX="set:Spring1 image:Spring1_xi"--夕
local g_ylimagCH="set:Spring1 image:Spring1_CH"--初

--[20230108-20230121]
--[20240124-20240209]
--[20250115-20250128]
--[20260204-20260216]
local g_dayInfo = {
[20260204]={mon=2,	mday=4,	dayimg1=g_ylimag10,	dayimg2=g_ylimag7},--前一天开始显示
[20260205]={mon=2,	mday=5,	dayimg1=g_ylimag10,	dayimg2=g_ylimag8},
[20260206]={mon=2,	mday=6,	dayimg1=g_ylimag10,	dayimg2=g_ylimag9},
[20260207]={mon=2,	mday=7,	dayimg1=g_ylimag2,	dayimg2=g_ylimag10},
[20260208]={mon=2,	mday=8,	dayimg1=g_ylimagN,	dayimg2=g_ylimag1},
[20260209]={mon=2,	mday=9,	dayimg1=g_ylimagN,	dayimg2=g_ylimag2},
[20260210]={mon=2,	mday=10,	dayimg1=g_ylimagN,	dayimg2=g_ylimag3},
[20260211]={mon=2,	mday=11,	dayimg1=g_ylimagN,	dayimg2=g_ylimag4},
[20260212]={mon=2,	mday=12,	dayimg1=g_ylimagN,	dayimg2=g_ylimag5},
[20260213]={mon=2,	mday=13,	dayimg1=g_ylimagN,	dayimg2=g_ylimag6},
[20260214]={mon=2,	mday=14,	dayimg1=g_ylimagN,	dayimg2=g_ylimag7},
[20260215]={mon=2,	mday=15,	dayimg1=g_ylimagN,	dayimg2=g_ylimag8},
[20260216]={mon=2,	mday=16,	dayimg1=g_ylimagC,	dayimg2=g_ylimagX},
}

-- 888333 今日福星点和成语编号
local g_TodayLuckyPoint = 0
local g_TodayWordNumber = 0
local g_LuckyImages = {
	[1] = {set ="Calender1" ,image="Shunfengshunshui"},
	[2] = {set ="Calender1" ,image="Shunfengshunshui"},
	[3] = {set ="Calender1" ,image="Haoyunlianlian"},
	[4] = {set ="Calender1" ,image="Haoyunlianlian"},
	[5] = {set ="Calender1" ,image="Hongyudangtou"},
	[6] = {set ="Calender1" ,image="Hongyudangtou"},
}

--=========
--PreLoad==
--=========
function SpringFirst_Calender_PreLoad()
	this:RegisterEvent("LAYUE_SIRILI_OPEN", true)
	this:RegisterEvent("SIRILIEX_JRLCD_UI",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
end
--=========
--OnLoad
--=========
function SpringFirst_Calender_OnLoad()
	g_Frame_UnifiedPosition = SpringFirst_Calender_FrameNULL:GetProperty("UnifiedPosition")

end
--=========
--OnEvent
--=========
function SpringFirst_Calender_OnEvent(event)
	if event == "LAYUE_SIRILI_OPEN" then
--PushDebugMessage("event="..event.." arg0="..arg0.." arg1="..arg1)
		local nFlag = tonumber(arg0)
		g_CalenderOpened=math.mod(nFlag,10)
		g_CalenderDay = tonumber(arg1)
--		g_TodayLuckyPoint = tonumber(arg2)
--		g_TodayWordNumber = tonumber(arg3)

		if nFlag==11 then
			SpringFirst_Calender_Clean()
			SpringFirst_Calender_PlayEffect()
		else
			SpringFirst_Calender_Clean()
			SpringFirst_Calender_Update()
			this:Show()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then
		SpringFirst_Calender_On_ResetPos()
	elseif event == "SIRILIEX_JRLCD_UI" then
			-- 0:关闭1:打开2:刷新3:鼠标选完人了4:服务端要求选人
			local Opt = tonumber(arg0)
			if 4 == Opt then
				--鼠标进入点人状态 关闭界面
				MouseEnterShareLucky()
				if this:IsVisible() then
					SpringFirst_Calender_OnCloseClicked()
				end
				return 
			end
	end

end

function SpringFirst_Calender_Clean()
	SpringFirst_Calender_Animate1:Hide()
	SpringFirst_Calender_Animate2:Hide()
end

function SpringFirst_Calender_Update()
	if g_dayInfo[g_CalenderDay] == nil then
		return
	end
	SpringFirst_Calender_Lunar:SetProperty("Image", g_dayInfo[g_CalenderDay].dayimg1 )
	SpringFirst_Calender_Lunar1:SetProperty("Image", g_dayInfo[g_CalenderDay].dayimg2 )

	local yl=ScriptGlobal_Format("#{LYYJ_181206_6}",g_dayInfo[g_CalenderDay].mon,g_dayInfo[g_CalenderDay].mday)
	SpringFirst_Calender_Day:SetText(yl)

	if g_CalenderOpened==0 then
		--可以撕
		SpringFirst_Calender_TimeBK:Show()
		--可以撕的特效
		SpringFirst_Calender_ButtonAnimate1:Show()
		SpringFirst_Calender_ButtonAnimate1:Play(true)
		SpringFirst_Calender_ButtonAnimate:Hide()
		KillTimer("SpringFirst_Calender_TearEffect()")
		SetTimer("SpringFirst_Calender","SpringFirst_Calender_TearEffect()", 1200)

		if g_CalenderDay == g_Day_ChuXiEve then--除夕前一天
			SpringFirst_Calender_Button:SetToolTip("#{LYYJ_181206_10}")
		else
			if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(52) > 0 then
				SpringFirst_Calender_Button:SetToolTip("#{LYYJKJ_211210_2}")
			else
				SpringFirst_Calender_Button:SetToolTip("#{LYYJ_181206_9}")
			end
		end

	else
		--不能撕
		SpringFirst_Calender_TimeBK:Hide()
	end
	--************************
	--EX 今日运势
	if g_TodayLuckyPoint > 0 then
		SpringFirst_Calender_SurplusImage:SetImage("Calender1",string.format("%.1f", g_TodayLuckyPoint/10 ))
		--运势文字图
		if g_LuckyImages[g_TodayWordNumber] ~=nil then
			SpringFirst_Calender_Lot_Item:SetImage(g_LuckyImages[g_TodayWordNumber].set,g_LuckyImages[g_TodayWordNumber].image)
		end
		SpringFirst_Calender_Lot_Client:Show()
	else
		SpringFirst_Calender_Lot_Client:Hide()
	end
	--************************
end
function SpringFirst_Calender_TearEffect()
	SpringFirst_Calender_ButtonAnimate1:Hide()
	SpringFirst_Calender_ButtonAnimate:Show()
	KillTimer("SpringFirst_Calender_TearEffect()")
end

function SpringFirst_Calender_PlayEffect()
--PushDebugMessage("SpringFirst_Calender_PlayEffect")
	SpringFirst_Calender_Animate1:Show();
	SpringFirst_Calender_Animate1:Play(true);
	KillTimer("SpringFirst_Calender_LotteryTick()")
	SetTimer("SpringFirst_Calender","SpringFirst_Calender_LotteryTick()", 600)
end
function SpringFirst_Calender_LotteryTick()
	SpringFirst_Calender_Animate2:Show();
	SpringFirst_Calender_Animate2:Play(true);
	KillTimer("SpringFirst_Calender_LotteryTick()")
	--更新日期
	KillTimer("SpringFirst_Calender_UpdateTick()")
	SetTimer("SpringFirst_Calender","SpringFirst_Calender_UpdateTick()", 300)
end
function SpringFirst_Calender_UpdateTick()
	KillTimer("SpringFirst_Calender_UpdateTick()")
	SpringFirst_Calender_Update()
end
--=========
--OnClose "X"
--=========
function SpringFirst_Calender_OnCloseClicked()
	this:Hide()
end
--=========
--handle Hide Event
--=========
function SpringFirst_Calender_OnHiden()
	KillTimer("SpringFirst_Calender_TearEffect()")
	KillTimer("SpringFirst_Calender_LotteryTick()")
	KillTimer("SpringFirst_Calender_UpdateTick()")
end

function SpringFirst_Calender_On_ResetPos()
	SpringFirst_Calender_FrameNULL:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

function SpringFirst_Calender_OnTearClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID( 890801 )
		Set_XSCRIPT_Function_Name( "OnLaYueSiRiLi" )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
end

--打开界面
function SpringFirst_Calender_AskOpenUI()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID( 890801 )
		Set_XSCRIPT_Function_Name( "OnOpenLaYueSiRiLiUI" )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
end

function SpringFirst_Calender_OnHelpClicked()
	PushEvent("LAYUE_SIRILI_HELP")
end

function SpringFirst_Calender_ShareClick()
	if IsInTServer()  == 1 then
		PushDebugMessage("#{SRLQY_201230_42}")
		return
	end
	Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( 888333 )
    Set_XSCRIPT_Function_Name( "OnSharedToPlayer" )
    Set_XSCRIPT_Parameter(0, 0)
    Set_XSCRIPT_ParamCount( 1 )
    Send_XSCRIPT()
end
