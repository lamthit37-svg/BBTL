--
-- 周活跃奖励界面 by 刘博
--
-- 好友界面的默认位置
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_FrameInfo = -1

local g_WeekActiveMD = 809

local WEEK_TBL_Anim = {}
local WEEK_TBL_Head = {}
local WEEK_TBL_Kong = {}

--周活跃宝箱名字
local g_TextWeekBox = {
	[1] = "#{ZHYTS_120105_20}",
	[2] = "#{ZHYTS_120105_21}",	
	[3] = "#{ZHYTS_120105_22}",	
	[4] = "#{ZHYTS_120105_23}",	
}

local g_StartTime = 20140127 --包含这一天
local g_EndTime = 20140209   --包含这一天

function Weekhuoyuehaoli_PreLoad()

	-- 注册事件
	this:RegisterEvent("UI_COMMAND")

	-- 打开抽奖窗口
	this:RegisterEvent("OPEN_WEEKHUOYUEHAOLI")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	-- 退出游戏
	this:RegisterEvent("QUEST_QUIT_GAME")

	-- 返回登陆界面
	this:RegisterEvent("QUEST_SERVER_LOGIN")

	-- 离开此场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	this:RegisterEvent("OPEN_HUOYUEHAOLI")
	
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")
end

function Weekhuoyuehaoli_OnLoad()
		--默认是这个

		WEEK_TBL_Anim[1] = Weekhuoyuehaoli_1_Ani
		WEEK_TBL_Anim[2] = Weekhuoyuehaoli_2_Ani
		WEEK_TBL_Anim[3] = Weekhuoyuehaoli_3_Ani
		--WEEK_TBL_Anim[4] = Weekhuoyuehaoli_4_Ani
	
		WEEK_TBL_Head[1] = Weekhuoyuehaoli_1
		WEEK_TBL_Head[2] = Weekhuoyuehaoli_2
		WEEK_TBL_Head[3] = Weekhuoyuehaoli_3
		--WEEK_TBL_Head[4] = Weekhuoyuehaoli_4
	
		WEEK_TBL_Kong[1] = Weekhuoyuehaoli_1_kong
		WEEK_TBL_Kong[2] = Weekhuoyuehaoli_2_kong
		WEEK_TBL_Kong[3] = Weekhuoyuehaoli_3_kong
		--WEEK_TBL_Kong[4] = Weekhuoyuehaoli_4_kong
		
	-- 保存好友界面的默认相对位置
	g_Frame_UnifiedXPosition	= Weekhuoyuehaoli_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Weekhuoyuehaoli_Frame:GetProperty("UnifiedYPosition");

end

function Weekhuoyuehaoli_OnEvent( event )

	if ( event == "UI_COMMAND" and tonumber(arg0) == 20130115 )then
		local pos = Get_XParam_INT(0)
		WEEK_TBL_Anim[pos]:Show()
		WeekHuoyuehaoli_Timer_StopWatch1:SetProperty("Timer", "1")
	elseif( event == "ADJEST_UI_POS" ) then
		Weekhuoyuehaoli_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Weekhuoyuehaoli_ResetPos()

	-- 打开抽奖窗口
	elseif ( event == "OPEN_WEEKHUOYUEHAOLI" ) then
		if not this:IsVisible() then
			Weekhuoyuehaoli_InIt(-1)
		else
			Weekhuoyuehaoli_Hide()
		end
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
			
	elseif event == "OPEN_HUOYUEHAOLI" then
		if this:IsVisible() or IsWindowShow("Huoyuehaoli")==true then
			Weekhuoyuehaoli_Hide()
			if IsWindowShow("Huoyuehaoli")==true then 
				OpenHuoYueHaoLi()
			end
		end
	elseif event == "UPDATE_REDPOINT_IN_UI" then
		if this:IsVisible() then
			Weekhuoyuehaoli_UpdateRedPointInUI()
		end
	end

end

--================================================
-- 初始化界面信息
--================================================
function Weekhuoyuehaoli_InIt(selectBox)

	--今日活跃值
	local nToadyActivePoint = Player:GetData("TODAYACTIVEPOINT")
	
	--本周活跃天
	local nActiveDay = 0;
	for i = 0,6 do
		if(1 == DataPool:GetPlayerMission_DataBinary(g_WeekActiveMD,i)) then
			nActiveDay = nActiveDay + 1;
		end
	end
	
	--由于策划变动,原有的7天周活跃砍为5天,这里修正界面显示
	if nActiveDay > 5 then
		nActiveDay = 5;
	end
	
	local msg = ScriptGlobal_Format("#{ZHYTS_120105_07}",nToadyActivePoint,nActiveDay)
	local myDayTime = tonumber(GetTime2Day())
	if (myDayTime >= g_StartTime and myDayTime <= g_EndTime) then
		msg = ScriptGlobal_Format("#{CJHL_131226_01}",nToadyActivePoint,nActiveDay)
	end	
	Weekhuoyuehaoli_detail:SetText(msg)
	
	msg = DataPool:GetWeekHuoyueNotice(0)
	if string.len(msg) == 0 then
		Weekhuoyuehaoli_sp:Hide();
	else
		Weekhuoyuehaoli_sp:Show();
		Weekhuoyuehaoli_sp_text:SetText(msg);
	end
	msg = DataPool:GetWeekHuoyueNotice(1)
	Weekhuoyuehaoli_1:SetToolTip(msg)
	Weekhuoyuehaoli_1_kong:SetToolTip(msg)
	msg = DataPool:GetWeekHuoyueNotice(2)
	Weekhuoyuehaoli_2:SetToolTip(msg)
	Weekhuoyuehaoli_2_kong:SetToolTip(msg)
	msg = DataPool:GetWeekHuoyueNotice(3)
	Weekhuoyuehaoli_3:SetToolTip(msg)
	Weekhuoyuehaoli_3_kong:SetToolTip(msg)
	--msg = DataPool:GetWeekHuoyueNotice(4)
	--Weekhuoyuehaoli_4:SetToolTip(msg)
	--Weekhuoyuehaoli_4_kong:SetToolTip(msg)
	
	--刷新宝箱状态

	Weekhuoyuehaoli_SetBox();
--	if selectBox >= 1 and selectBox <= 4 then
--		WEEK_TBL_Kong[selectBox]:Show()
--		WEEK_TBL_Head[selectBox]:Hide()
--		WEEK_TBL_Anim[selectBox]:Hide()
--	end
	Weekhuoyuehaoli_FenYe1:SetCheck(0)
	Weekhuoyuehaoli_FenYe2:SetCheck(1)
	
	Weekhuoyuehaoli_UpdateRedPointInUI()
	
	this:Show()
end

--================================================
-- 恢复好礼界面的默认相对位置
--================================================
function Weekhuoyuehaoli_ResetPos()
	Weekhuoyuehaoli_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Weekhuoyuehaoli_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

-- 窗口关闭
function Weekhuoyuehaoli_Hide()
	this:Hide();
end

--================================================
-- 选择抽奖按钮
--================================================
function Weekhuoyuehaoli_PlayHead(pos_ui)

	-- 客户端等级限制
	if  Player:GetData("LEVEL") < 30 then
		PushDebugMessage("#{HYHL_101230_34}")
		return
	end
	
	-- 向服务器发送抽奖消息
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("WeekHuoyuePrize");
		Set_XSCRIPT_ScriptID(889337);
		Set_XSCRIPT_Parameter(0,pos_ui);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();

end

--function Weekhuoyuehaoli_ToHuoyuehaoli()
	--Weekhuoyuehaoli_Hide();
	--OpenHuoYueHaoLi()
--end

-- 设置宝箱状态
function Weekhuoyuehaoli_SetBox()
	for i = 1,3 do
		local flag = DataPool:GetPlayerMission_DataBinary(g_WeekActiveMD,i+6)
		if flag == 1 then
				WEEK_TBL_Kong[i]:Show()
				WEEK_TBL_Head[i]:Hide()
				WEEK_TBL_Anim[i]:Hide()
		else
				WEEK_TBL_Kong[i]:Hide()
				WEEK_TBL_Head[i]:Show()
				WEEK_TBL_Anim[i]:Hide()
		end
	end
end

function WeekHuoyuehaoli_HFPlayKong( pos_ui )
	-- 特定情况限制
	if g_TextWeekBox[pos_ui] == nil then
		return
	end
	local msg  = ScriptGlobal_Format("#{ZHYTS_120105_08}",g_TextWeekBox[pos_ui])
	PushDebugMessage(msg)
end

--================================================
-- 小火球动画结束
--================================================
function WeekHuoyuehaoli_TimeReach1()

	Weekhuoyuehaoli_InIt(-1)
	WeekHuoyuehaoli_Timer_StopWatch1:SetProperty("Timer", "-1")

end

function Weekhuoyuehaoli_OpenDayGift()
	Weekhuoyuehaoli_FenYe1:SetCheck(1)
	Weekhuoyuehaoli_FenYe2:SetCheck(0)
	if IsWindowShow("Huoyuehaoli") then return end
	Weekhuoyuehaoli_Hide()
	OpenHuoYueHaoLi()
end

function Weekhuoyuehaoli_OpenWeekGift()
	Weekhuoyuehaoli_FenYe1:SetCheck(0)
	Weekhuoyuehaoli_FenYe2:SetCheck(1)
	if IsWindowShow("Weekhuoyuehaoli") then return end
	Weekhuoyuehaoli_Hide()
	OpenWeekHuoyuehaoli()
end

function Weekhuoyuehaoli_UpdateRedPointInUI()

	Weekhuoyuehaoli_FenYe1tips:Hide()
	Weekhuoyuehaoli_FenYe2tips:Hide()
	if DataPool:Lua_IsRedPointInUIShow( 0 ) == 1 then
	
		Weekhuoyuehaoli_FenYe1tips:Show()
		
	end
	
	if DataPool:Lua_IsRedPointInUIShow( 1 ) == 1 then
	
		Weekhuoyuehaoli_FenYe2tips:Show()
		
	end 
end
