--贺新春
-- !!!reloadscript =HeXinChun
local g_HeXinChun_Frame_UnifiedXPosition
local g_HeXinChun_Frame_UnifiedYPosition

local g_HeXinChun_RewardDayCount = 8
local g_HeXinChun_DayAchieveCount = 3

local g_HeXinChun_DayRewardState = 
{
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
	[7] = 0,
	[8] = 0,
}

local g_HeXinChun_AchieveState = 
{
	[1] = 0, --辞旧岁
	[2] = 0, --打年兽
	[3] = 0, --团圆宴
}

-- local g_HeXinChun_AchieveEvent2Name = 
-- {
	-- [1] = "#{CJYJ_180104_36}",  --大扫除
	-- [2] = "#{CJYJ_180104_34}",  --写春联
	-- [3] = "#{CJYJ_180104_35}",  --贴倒福
-- }

local g_HeXinChun_DayRewardButtons = {}
-- local g_HeXinChun_AchieveButtons = {}

local g_HeXinChun_FinalRewardState = 0


local g_HeXinChun_CiJiuSuiTypeName = 
{
	[1] = "#{CJYJ_180104_36}",
	[2] = "#{CJYJ_180104_35}",
	[3] = "#{CJYJ_180104_34}",
}

local g_HeXinChun_CiJiuSuiDesc = 
{
	[1] = "#{CJYJ_180104_50}",
	[2] = "#{CJYJ_180104_47}",
	[3] = "#{CJYJ_180104_49}",
}

local g_HeXinChun_FlexTips = {}
local g_HeXinChun_FlexState = 
{
	[1] = 0,
	[2] = 0,
}

local g_HeXinChun_DataRefreshTime = 0

local g_HeXinChun_BeginTime = 20260216
local g_HeXinChun_EndTime = 20260223

local g_HeXinChun_ZhanJiangHuBegin = 20260224
local g_HeXinChun_ZhanJiangHuEnd = 20260303

local g_HeXinChun_LableDesc = nil

local g_HeXinChun_Day2Name = 
{
	[1] = "#{CJYJ_180104_22}",
	[2] = "#{CJYJ_180104_23}",
	[3] = "#{CJYJ_180104_24}",
	[4] = "#{CJYJ_180104_25}",
	[5] = "#{CJYJ_180104_26}",
	[6] = "#{CJYJ_180104_27}",
	[7] = "#{CJYJ_180104_28}",
	[8] = "#{CJYJ_180104_29}",
}

local g_HeXinChun_CampainId = 
{
	[1] = {id=39920181,count=1},
	[2] = {id=39920565,count=1},
	[3] = {id=39920490,count=3},
	[4] = {id=39920085,count=10},
	[5] = {id=39921051,count=4},
	[6] = {id=39920329,count=2},
	[7] = {id=39920566,count=1},
	[8] = {id=39923190,count=1},
	[9] = {id=39921373,count=1},
}

local g_HeXinChun_CampainId_KaJi = 
{
	[1] = {id=39920181,count=1},
	[2] = {id=39920565,count=1},
	[3] = {id=39920490,count=3},
	[4] = {id=39920085,count=10},
	[5] = {id=39921051,count=4},
	[6] = {id=39920329,count=2},
	[7] = {id=39920566,count=1},
	[8] = {id=39923234,count=1},
	[9] = {id=39923678,count=1},
}

local g_HeXinChun_CampainId_DZD = 
{
	[1] = {id=39920181,count=1},
	[2] = {id=39920565,count=1},
	[3] = {id=39920490,count=3},
	[4] = {id=39920085,count=10},
	[5] = {id=39921051,count=4},
	[6] = {id=39920329,count=2},
	[7] = {id=39920566,count=1},
	[8] = {id=39923234,count=1},
	[9] = {id=39921373,count=1},
}

local g_HeXinChun_DateIamge = 
{
	[1] = {nor="set:hexinchun07 image:Day1",cur="set:hexinchun07 image:G_Day1"},
	[2] = {nor="set:hexinchun07 image:Day2",cur="set:hexinchun07 image:G_Day2"},
	[3] = {nor="set:hexinchun07 image:Day3",cur="set:hexinchun07 image:G_Day3"},
	[4] = {nor="set:hexinchun07 image:Day4",cur="set:hexinchun07 image:G_Day4"},
	[5] = {nor="set:hexinchun07 image:Day5",cur="set:hexinchun07 image:G_Day5"},
	[6] = {nor="set:hexinchun07 image:Day6",cur="set:hexinchun07 image:G_Day6"},
	[7] = {nor="set:hexinchun07 image:Day7",cur="set:hexinchun07 image:G_Day7"},
	[8] = {nor="set:hexinchun07 image:Day8",cur="set:hexinchun07 image:G_Day8"},
}
--===============================================
-- OnLoad()
--===============================================
function HeXinChun_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)	
	this:RegisterEvent("OPEN_HEXINCHUN",true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("XINCHUNYINGJING_FLEX_UPDATE",true)
	
	this:RegisterEvent("PLAYER_ENTERING_WORLD",true)
end

function HeXinChun_OnLoad()
	g_HeXinChun_DayRewardButtons = 
	{
		[1] = {FinshFlag=HeXinChun_FinishImage1,Btn=HeXinChun_Button1,Date=HeXinChun_Date1,Ani=HeXinChun_ButtonAnimate1,Icon=HeXinChun_Icon1,IconNum=HeXinChun_Button1_Num,FlexTip=HeXinChun_ButtonTips1,},
		[2] = {FinshFlag=HeXinChun_FinishImage2,Btn=HeXinChun_Button2,Date=HeXinChun_Date2,Ani=HeXinChun_ButtonAnimate2,Icon=HeXinChun_Icon2,IconNum=HeXinChun_Button2_Num,FlexTip=HeXinChun_ButtonTips2,},
		[3] = {FinshFlag=HeXinChun_FinishImage3,Btn=HeXinChun_Button3,Date=HeXinChun_Date3,Ani=HeXinChun_ButtonAnimate3,Icon=HeXinChun_Icon3,IconNum=HeXinChun_Button3_Num,FlexTip=HeXinChun_ButtonTips3,},
		[4] = {FinshFlag=HeXinChun_FinishImage4,Btn=HeXinChun_Button4,Date=HeXinChun_Date4,Ani=HeXinChun_ButtonAnimate4,Icon=HeXinChun_Icon4,IconNum=HeXinChun_Button4_Num,FlexTip=HeXinChun_ButtonTips4,},
		[5] = {FinshFlag=HeXinChun_FinishImage5,Btn=HeXinChun_Button5,Date=HeXinChun_Date5,Ani=HeXinChun_ButtonAnimate5,Icon=HeXinChun_Icon5,IconNum=HeXinChun_Button5_Num,FlexTip=HeXinChun_ButtonTips5,},
		[6] = {FinshFlag=HeXinChun_FinishImage6,Btn=HeXinChun_Button6,Date=HeXinChun_Date6,Ani=HeXinChun_ButtonAnimate6,Icon=HeXinChun_Icon6,IconNum=HeXinChun_Button6_Num,FlexTip=HeXinChun_ButtonTips6,},
		[7] = {FinshFlag=HeXinChun_FinishImage7,Btn=HeXinChun_Button7,Date=HeXinChun_Date7,Ani=HeXinChun_ButtonAnimate7,Icon=HeXinChun_Icon7,IconNum=HeXinChun_Button7_Num,FlexTip=HeXinChun_ButtonTips7,},
		[8] = {FinshFlag=HeXinChun_FinishImage8,Btn=HeXinChun_Button8,Date=HeXinChun_Date8,Ani=HeXinChun_ButtonAnimate8,Icon=HeXinChun_Icon8,IconNum=HeXinChun_Button8_Num,FlexTip=HeXinChun_ButtonTips8,},
	}
	-- g_HeXinChun_AchieveButtons = 
	-- {
		-- [1] = {Name=HeXinChun_TYYtext1,Desc=HeXinChun_TYYtext2,Image=HeXinChun_Image3,DateDead=HeXinChun_TYYOverImage},
		-- [2] = {Name=HeXinChun_DNStext1,Desc=HeXinChun_DNStext2,Image=HeXinChun_Image2,DateDead=HeXinChun_DNSOverImage},
		-- [3] = {Name=HeXinChun_CJStext1,Desc=HeXinChun_CJStext2,Image=HeXinChun_Image1,DateDead=HeXinChun_CJSOverImage},
	-- }
	g_HeXinChun_FlexTips = 
	{
		[1] = HeXinChun_FenYe1_Tips,
		[2] = HeXinChun_FenYe2_Tips,
	}
	g_HeXinChun_LableDesc = HeXinChun_Explain
	-- 保存界面的默认相对位置
	g_HeXinChun_Frame_UnifiedXPosition	= HeXinChun_Frame : GetProperty("UnifiedXPosition");
	g_HeXinChun_Frame_UnifiedYPosition	= HeXinChun_Frame : GetProperty("UnifiedYPosition");
	
	g_HeXinChun_FlexState[1] = 0
	g_HeXinChun_FlexState[2] = 0
	
end
--===============================================
-- OnEvent()
--===============================================
function HeXinChun_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 2018010601) then	
		local bOpen = Get_XParam_INT(0)
		local nIndex = 1
		local nFlexFlag = 0
		--g_HeXinChun_FlexState[1] = 0
		for i=1,g_HeXinChun_RewardDayCount do
			g_HeXinChun_DayRewardState[i] = Get_XParam_INT(nIndex)
			if(g_HeXinChun_DayRewardState[i] == 1) then
				nFlexFlag = 1
			end
			nIndex = nIndex + 1
		end
		g_HeXinChun_FinalRewardState = Get_XParam_INT(nIndex)
		if(g_HeXinChun_FinalRewardState == 1) then
			nFlexFlag = 1
		end
		if(bOpen == 1) then
			HeXinChun_FenYe1:SetCheck(1)
			HeXinChun_FenYe2:SetCheck(0)
			if(IsWindowShow("ZhanJiangHu") == true) then
				CloseWindow("ZhanJiangHu",true)
			end
			this:Show()
		end
		local bRrefrshTip = 0
		if(nFlexFlag ~= g_HeXinChun_FlexState[1]) then
			bRrefrshTip = 1
			g_HeXinChun_FlexState[1] = nFlexFlag
		end
		g_HeXinChun_DataRefreshTime = OSAPI:GetTickCount()
		if(this:IsVisible()) then
			HeXinChun_RefreshAll()
		end
		if(bRrefrshTip == 1) then
			PushEvent("XINCHUNYINGJING_FLEX_UPDATE",1,g_HeXinChun_FlexState[1])
			Lua_ShowQuickEnterPointTipByBinary(13, 1, g_HeXinChun_FlexState[1])
		end
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 2018010602) then	
		local nIndex = 0
		for i=1,g_HeXinChun_DayAchieveCount do
			g_HeXinChun_AchieveState[i] = Get_XParam_INT(nIndex)
			nIndex = nIndex + 1
			if(g_HeXinChun_AchieveState[i] == 1) then
			end
		end
		if(this:IsVisible()) then
			HeXinChun_RefreshAchieve()
		end

	elseif(event == "OPEN_HEXINCHUN") then
		local bOpen = tonumber(arg0)
		if(bOpen == 0) then
			HeXinChun_OnHiden()
			return
		end
		if(tonumber(arg1) ~= -1 and tonumber(arg2) ~= -1) then
			g_HeXinChun_Frame_UnifiedXPosition = arg1
			g_HeXinChun_Frame_UnifiedYPosition = arg2
			HeXinChun_Frame_On_ResetPos()
		end
		local nCur = OSAPI:GetTickCount()
		if((g_HeXinChun_DataRefreshTime <= 0) or (nCur - g_HeXinChun_DataRefreshTime >= 300000)) then
			HeXinChun_AskData(1)
			return
		end
		if(IsWindowShow("ZhanJiangHu") == true) then
			CloseWindow("ZhanJiangHu",true)
		end
		HeXinChun_FenYe1:SetCheck(1)
		HeXinChun_FenYe2:SetCheck(0)
		this:Show()
		HeXinChun_RefreshAll()
		
	elseif (event == "XINCHUNYINGJING_FLEX_UPDATE") then
		if(tonumber(arg0) ~= 2 )then
			return
		end
		g_HeXinChun_FlexState[2] = tonumber(arg1)
		if(this:IsVisible()) then
			HeXinChun_RefreshAll()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		HeXinChun_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		HeXinChun_Frame_On_ResetPos()
	elseif (event == "PLAYER_ENTERING_WORLD") then
		HeXinChun_AskData(0)
		HeXinChun_OnHiden()
	end
end


--===============================================
-- OnHiden
--===============================================
function HeXinChun_OnHiden()
	this:Hide()
end

function HeXinChun_Quit_Clicked()
	HeXinChun_OnHiden()
end

function HeXinChun_RefreshAll()
	HeXinChun_RefreshDays()
	HeXinChun_RefreshAchieve()
end


function HeXinChun_RefreshDays()

	local info = {id=0,count=0}
	if Player:GetData("IsOriginalJD") == 1 then
		info = g_HeXinChun_CampainId_DZD
	else
		--卡级服
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(50) > 0 then
			info = g_HeXinChun_CampainId_KaJi
		else
			info = g_HeXinChun_CampainId
		end
	end

	local nCurDay = tonumber(DataPool:GetServerDayTime());
	for i=1,g_HeXinChun_RewardDayCount do
		local nState = g_HeXinChun_DayRewardState[i]
		g_HeXinChun_DayRewardButtons[i].Btn:SetToolTip("")
		if(nState == 2) then
			g_HeXinChun_DayRewardButtons[i].FinshFlag:Show()
			g_HeXinChun_DayRewardButtons[i].Btn:SetToolTip("#{CJYJ_180129_168}")
		else
			g_HeXinChun_DayRewardButtons[i].FinshFlag:Hide()
		end
		if(nState == -1 ) then
			g_HeXinChun_DayRewardButtons[i].Btn:Enable()
			g_HeXinChun_DayRewardButtons[i].Btn:SetToolTip(ScriptGlobal_Format("#{CJYJ_180104_30}",g_HeXinChun_Day2Name[i]))
		else
			g_HeXinChun_DayRewardButtons[i].Btn:Enable()
			--g_HeXinChun_DayRewardButtons[i].Btn:SetCheck(1)
		end
		if(nState == 1) then
			g_HeXinChun_DayRewardButtons[i].Ani:Show()
			g_HeXinChun_DayRewardButtons[i].FlexTip:Show()
			g_HeXinChun_DayRewardButtons[i].Btn:SetToolTip("#{CJYJ_180104_31}")
		else
			g_HeXinChun_DayRewardButtons[i].Ani:Hide()
			g_HeXinChun_DayRewardButtons[i].FlexTip:Hide()
			if(nState == 0) then
				local nCurDay = tonumber(DataPool:GetServerDayTime());
				local nIndexDay = DataPool:DiffDayCount(g_HeXinChun_BeginTime,nCurDay) + 1
				if(i < nIndexDay) then
					g_HeXinChun_DayRewardButtons[i].Btn:SetToolTip("#{CJYJ_180129_169}")
				else
					g_HeXinChun_DayRewardButtons[i].Btn:SetToolTip(ScriptGlobal_Format("#{CJYJ_180104_30}",g_HeXinChun_Day2Name[i]))
				end
			end
		end
		local theAction = DataPool:CreateActionItemForShow(info[i].id, info[i].count)
		if theAction:GetID() ~= 0 then
			g_HeXinChun_DayRewardButtons[i].Icon:SetActionItem(theAction:GetID())
			--g_HeXinChun_DayRewardButtons[i].IconNum:SetText(""..info[i].count)
			g_HeXinChun_DayRewardButtons[i].IconNum:SetText("")
		end
		if(DataPool:DiffDayCount(g_HeXinChun_BeginTime,nCurDay) + 1 == i) then
			g_HeXinChun_DayRewardButtons[i].Date:SetProperty("Image",g_HeXinChun_DateIamge[i].cur)
		else
			g_HeXinChun_DayRewardButtons[i].Date:SetProperty("Image",g_HeXinChun_DateIamge[i].nor)
		end
	end
	if(g_HeXinChun_FinalRewardState == 2 ) then
		HeXinChun_TotalFinishImage:Show()
	else
		HeXinChun_TotalFinishImage:Hide()
	end
	
	if(g_HeXinChun_FinalRewardState == 1) then
		HeXinChun_Frame_TotalButton:Enable()
		HeXinChun_TotalButtonAnimate:Show()
		HeXinChun_Hongdiantips:Show()
		HeXinChun_Frame_TotalButton:SetToolTip("#{CJYJ_180104_13}")
	else
		HeXinChun_Frame_TotalButton:Enable()
		HeXinChun_TotalButtonAnimate:Hide()
		HeXinChun_Hongdiantips:Hide()
		HeXinChun_Frame_TotalButton:SetToolTip("#{CJYJ_180104_12}")
	end
	local theAction1 = DataPool:CreateActionItemForShow(info[9].id, info[9].count)
	if theAction1:GetID() ~= 0 then
		HeXinChun_TotalIcon:SetActionItem(theAction1:GetID())
	end
	
	if(nCurDay >= g_HeXinChun_BeginTime and nCurDay <= g_HeXinChun_EndTime) then
		g_HeXinChun_LableDesc:SetText("#{CJYJ_180111_96}")
	elseif(nCurDay >= g_HeXinChun_ZhanJiangHuBegin and nCurDay <= g_HeXinChun_ZhanJiangHuEnd) then
		g_HeXinChun_LableDesc:SetText("#{CJYJ_180111_97}")
	end
	for i=1,table.getn(g_HeXinChun_FlexTips) do
		if(g_HeXinChun_FlexState[i] == 1) then
			g_HeXinChun_FlexTips[i]:Show()
		else
			g_HeXinChun_FlexTips[i]:Hide()
		end
	end
	
end



function HeXinChun_RefreshAchieve()
	-- local nCurDay = tonumber(DataPool:GetServerDayTime());
	-- for i=1,g_HeXinChun_DayAchieveCount do
		-- if(g_HeXinChun_AchieveState[i] == 1) then
			-- g_HeXinChun_AchieveButtons[i].Desc:SetText("#{CJYJ_180104_48}")
		-- else
			-- g_HeXinChun_AchieveButtons[i].Desc:SetText(g_HeXinChun_CiJiuSuiDesc[i])
		-- end
		-- if(HeXinChun_ZhanJiangHuIsOpen() == 1) then
			-- g_HeXinChun_AchieveButtons[i].Image:Disable()
		-- else
			-- g_HeXinChun_AchieveButtons[i].Image:Enable()
		-- end
		-- g_HeXinChun_AchieveButtons[i].Name:SetText(g_HeXinChun_CiJiuSuiTypeName[i])
		-- if(nCurDay >= g_HeXinChun_BeginTime and nCurDay <= g_HeXinChun_EndTime) then
			-- g_HeXinChun_AchieveButtons[i].DateDead:Hide()
		-- elseif(nCurDay >= g_HeXinChun_ZhanJiangHuBegin and nCurDay <= g_HeXinChun_ZhanJiangHuEnd) then
			-- g_HeXinChun_AchieveButtons[i].Desc:SetText("#{CJYJ_180104_51}")
			-- g_HeXinChun_AchieveButtons[i].DateDead:Show()
		-- end
		
	-- end
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function HeXinChun_Frame_On_ResetPos()
	HeXinChun_Frame : SetProperty("UnifiedXPosition", g_HeXinChun_Frame_UnifiedXPosition);
	HeXinChun_Frame : SetProperty("UnifiedYPosition", g_HeXinChun_Frame_UnifiedYPosition);
end


function HeXinChun_ClickReward(nIndex)
	if(nIndex == nil or nIndex < 1 or nIndex > 9) then
		return
	end
	
	local nState = g_HeXinChun_DayRewardState[nIndex]
	if(nIndex == 9) then
		nState = g_HeXinChun_FinalRewardState
	end
	if(nState == -1) then
		PushDebugMessage("#{CJYJ_180127_149}")
		return
	end
	if(nState == 2) then
		if(nIndex == 9) then
			PushDebugMessage("#{CJYJ_180104_77}")
		else
			PushDebugMessage("#{CJYJ_180104_71}")
		end
		
		return
	end
	if(nState == 0) then
		local nCurDay = tonumber(DataPool:GetServerDayTime());
		local nIndexDay = DataPool:DiffDayCount(g_HeXinChun_BeginTime,nCurDay) + 1
		if(nIndex == 9) then
			if(nCurDay >= g_HeXinChun_BeginTime and nCurDay <= g_HeXinChun_EndTime) then
				PushDebugMessage("#{CJYJ_180104_78}")
			elseif(nCurDay >= g_HeXinChun_ZhanJiangHuBegin and nCurDay <= g_HeXinChun_ZhanJiangHuEnd) then
				PushDebugMessage("#{CJYJ_180104_78}")
			end
			
		else
			if(nIndex ~= nIndexDay) then
				if(nCurDay >= g_HeXinChun_BeginTime and nCurDay <= g_HeXinChun_EndTime) then
					if(nIndex > nIndexDay) then
						PushDebugMessage("#{CJYJ_180127_149}")
					else
						PushDebugMessage("#{CJYJ_180122_136}")
					end
				elseif(nCurDay >= g_HeXinChun_ZhanJiangHuBegin and nCurDay <= g_HeXinChun_ZhanJiangHuEnd) then
					PushDebugMessage("#{CJYJ_180125_146}")
				end
				return
			else
				-- PushDebugMessage(HeXinChun_GetUmComplteMessage())
			end
		end
		return		
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetReward")
		Set_XSCRIPT_ScriptID(892663)
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function HeXinChun_ChangeTabIndex()
	if(HeXinChun_ZhanJiangHuIsOpen() ~= 1) then
		--非卡级服
		if KaJi:LuaFnIsKaJiServer() ~= 1 then	
			PushDebugMessage("#{CJYJ_180119_133}")
		--卡级服
		else
			PushDebugMessage("#{CJYJ_1211125_04}")
		end
		HeXinChun_FenYe1:SetCheck(1)
		HeXinChun_FenYe2:SetCheck(0)
		return
	end
	local X = HeXinChun_Frame : GetProperty("UnifiedXPosition");
	local Y = HeXinChun_Frame : GetProperty("UnifiedYPosition");	
	PushEvent("OPEN_ZHANJIANGHU",1,X,Y)
	--HeXinChun_OnHiden()
end

function HeXinChun_AskData(bOpen)
	-- local curDay = tonumber(DataPool:GetServerDayTime());
	-- if(curDay >= g_HeXinChun_BeginTime and curDay <= g_HeXinChun_EndTime) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenUI")
			Set_XSCRIPT_ScriptID(892663)
			Set_XSCRIPT_Parameter(0,bOpen)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	-- end
end

function HeXinChun_ZhanJiangHuIsOpen()
	local curDay = tonumber(DataPool:GetServerDayTime());
	if(curDay < g_HeXinChun_ZhanJiangHuBegin or curDay > g_HeXinChun_ZhanJiangHuEnd) then
		return 0
	end
	return 1
end

function HeXinChun_GetUmComplteMessage()
	-- local szUnFinsh = ""
	-- for i=1,table.getn(g_HeXinChun_AchieveState) do
		-- if(g_HeXinChun_AchieveState[i] ~= 1) then
			-- if(szUnFinsh == "") then
				-- szUnFinsh = g_HeXinChun_AchieveEvent2Name[i]
			-- else
				-- szUnFinsh = szUnFinsh.."#{CJYJ_180104_38}"..g_HeXinChun_AchieveEvent2Name[i]
			-- end
		-- end
	-- end
	-- if(szUnFinsh ~= "") then
		-- return ScriptGlobal_Format("#{CJYJ_180104_72}",szUnFinsh)
	-- end
	-- return ""
end

function HeXinChun_HelpClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NpcText")
		Set_XSCRIPT_ScriptID(892663)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
