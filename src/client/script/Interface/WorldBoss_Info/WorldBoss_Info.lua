local g_WorldBoss_Info_UnifiedPosition;
local g_UICOMMAND = 89039001
local g_ExeScript = 890390
local g_TeamWithLeader = 0
local g_RankIndex = 0

local g_ActivityTimeSetting = {beginTime = 200000,createBossTime = 200100,endTime = 203000}

function WorldBoss_Info_PreLoad()
	this:RegisterEvent("BOSSINVADEOPENMINI")

	this:RegisterEvent("UI_COMMAND")
	--离开场景，自动关闭
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")	
end
function WorldBoss_Info_OnLoad()	
	g_WorldBoss_Info_UnifiedPosition  =WorldBoss_Info_Frame:GetProperty("UnifiedPosition");
end

function WorldBoss_Info_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
		local opt =  Get_XParam_INT( 0 );
		if opt == 1 or --打开
		opt == 2  --服务器刷新
		then
			local point = Get_XParam_INT( 1 )
			g_TeamWithLeader = Get_XParam_INT( 2 )
			local nowTime = DataPool:GetServerMinuteTime()
			local leftSec = 0
			local endTime = g_ActivityTimeSetting.endTime
			local rankIndexNow = Get_XParam_INT( 3 )
			if endTime > nowTime then
				local endSec = math.mod(endTime,100)
				endTime =  math.floor(endTime/100)
				local endMin = math.mod(endTime,100)
				local endHour = math.floor(endTime/100)

				local nowSec = math.mod(nowTime,100)
				nowTime =  math.floor(nowTime/100)
				local nowMin = math.mod(nowTime,100)
				local nowHour = math.floor(nowTime/100)

				leftSec = (endHour*3600+endMin*60+endSec) - (nowHour*3600+nowMin*60+nowSec)

			end
			if g_TeamWithLeader == 0 then
				WorldBoss_Info_BasicInfo2:SetText("#{SJBS_240124_203}")
				WorldBoss_Info_BasicInfo5:SetText("#{SJBS_240124_228}")
			else
				WorldBoss_Info_BasicInfo2:SetText(ScriptGlobal_Format("#{SJBS_240124_100}",point))
				if rankIndexNow > 0 then
					WorldBoss_Info_BasicInfo5:SetText(ScriptGlobal_Format("#{SJBS_240124_227}",rankIndexNow))
				else
					WorldBoss_Info_BasicInfo5:SetText("#{SJBS_240124_228}")
				end
			end
			if leftSec > 0  then
				WorldBoss_Info_BasicInfo1:SetText("#{SJBS_240124_99}")
				WorldBoss_Info_TimeWatch:SetProperty("Timer", tostring(leftSec))
				WorldBoss_Info_TimeWatch:Show()
			else
				WorldBoss_Info_BasicInfo1:SetText("#{SJBS_240124_99}".."#{SJBS_240124_234}")
				WorldBoss_Info_TimeWatch:Hide()
			end
			
			
			if opt == 1  then
				this:Show()
				if(IsWindowShow("WorldBoss_InfoMini")) then
					CloseWindow("WorldBoss_InfoMini", true)
				end
			end
		
		else
			if(IsWindowShow("WorldBoss_InfoMini")) then
				CloseWindow("WorldBoss_InfoMini", true)
			end
			this:Hide()
		end
	elseif  event == "UI_COMMAND" and tonumber(arg0) == 89039004  then
		--刷新战况信息的排名栏
		local rankIndexNow = Get_XParam_INT(0)
		if rankIndexNow > 0 then
			WorldBoss_Info_BasicInfo5:SetText(ScriptGlobal_Format("#{SJBS_240124_227}",rankIndexNow))
		else
			WorldBoss_Info_BasicInfo5:SetText("#{SJBS_240124_228}")
		end
	else 
	    
		if event == "BOSSINVADEOPENMINI" and tonumber(arg0) == 3  then
			--只在客户端刷新时间 其他的都在该刷新的时候刷新了
			local nowTime = DataPool:GetServerMinuteTime()
			local leftSec = 0
			local endTime = g_ActivityTimeSetting.endTime
			if endTime > nowTime then
				local endSec = math.mod(endTime,100)
				endTime =  math.floor(endTime/100)
				local endMin = math.mod(endTime,100)
				local endHour = math.floor(endTime/100)

				local nowSec = math.mod(nowTime,100)
				nowTime =  math.floor(nowTime/100)
				local nowMin = math.mod(nowTime,100)
				local nowHour = math.floor(nowTime/100)

				leftSec = (endHour*3600+endMin*60+endSec) - (nowHour*3600+nowMin*60+nowSec)

			end
			
			if leftSec > 0  then
				WorldBoss_Info_BasicInfo1:SetText("#{SJBS_240124_99}")
				WorldBoss_Info_TimeWatch:SetProperty("Timer", tostring(leftSec))
				WorldBoss_Info_TimeWatch:Show()
			else
				WorldBoss_Info_BasicInfo1:SetText("#{SJBS_240124_99}".."#{SJBS_240124_234}")
				WorldBoss_Info_TimeWatch:Hide()
			end
			this:Show()
		end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		WorldBoss_Info_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WorldBoss_Info_On_ResetPos()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		this:Hide()
	end
end


function WorldBoss_Info_On_ResetPos()
	WorldBoss_Info_Frame:SetProperty("UnifiedPosition", g_WorldBoss_Info_UnifiedPosition);
end


function WorldBoss_Info_ListClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AskOpenSceneRankList" )
		Set_XSCRIPT_ScriptID(g_ExeScript)
		Set_XSCRIPT_Parameter(0,0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function WorldBoss_Info_CloseClicked()
	PushEvent("BOSSINVADEOPENMINI",1)
	this:Hide()
end

function WorldBoss_Info_OnTimer()
	
end

function WorldBoss_Info_Help_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowHelpInfo" )
		Set_XSCRIPT_ScriptID(g_ExeScript)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end	