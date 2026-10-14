-- 2019Q1周年庆-瑞黑图
local g_Frame_UnifiedPosition
function ZhouNian12_RuiHe_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)

end

local g_Progress = {}

local g_ProgressAnim = {}

local g_GetAwardLimit = 4

local g_NowShowIndex = -1

function ZhouNian12_RuiHe_OnLoad()
	
	g_Frame_UnifiedPosition = ZhouNian12_RuiHe_Frame:GetProperty("UnifiedPosition") 
	
	g_Progress[1] = ZhouNian12_RuiHe_Progress1
	g_Progress[2] = ZhouNian12_RuiHe_Progress2
	g_Progress[3] = ZhouNian12_RuiHe_Progress3 
	g_Progress[4] = ZhouNian12_RuiHe_Progress4

	g_ProgressAnim[1] = ZhouNian12_RuiHe_Progress1_Animate
	g_ProgressAnim[2] = ZhouNian12_RuiHe_Progress2_Animate
	g_ProgressAnim[3] = ZhouNian12_RuiHe_Progress3_Animate
	g_ProgressAnim[4] = ZhouNian12_RuiHe_Progress4_Animate
	g_ProgressAnim[5] = ZhouNian12_RuiHe_Progress3_Animate1
	
	ZhouNian12_RuiHe_Clear()
	
end

function ZhouNian12_RuiHe_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 89306602 then
		
		local index = Get_XParam_INT(0)
		
		-- 更新界面index：1代表整合界面打开，2代表玩家通过npc或者再玩一次界面查看，3代表领奖之后主动弹出,isGetAward是否领奖，nGetNum领全奖的次数 
		-- 4代表通知客户端去关闭领取按钮的特效
		if index < 1 or index > 4 then
			return 
		end
		
		if index == 4 then
			local buttonindex = Get_XParam_INT(1)
			if buttonindex == 1 then
				ZhouNian12_RuiHe_Animate2:Play(false)
			elseif buttonindex == 2 then
				ZhouNian12_RuiHe_Animate1:Play(false)
			end	
			return
		end
		
		local misdata = Get_XParam_INT(1)
		local nGetNum = 0 
		nGetNum = Get_XParam_INT(2)
		-- 因为领最高奖励4次就可以完成这个活动了
		if nGetNum > 4 then
			nGetNum = 4
		end
		local misdata2days = math.mod(misdata,10)
		local misdata4days = math.floor(math.mod(misdata,100)/10)
		ZhouNian12_RuiHe_Clear()
		ZhouNian12_RuiHe_Update(index, misdata2days, misdata4days, nGetNum)
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		ZhouNian12_RuiHe_On_ResetPos()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
	
		ZhouNian12_RuiHe_OnClosed()
		
	elseif event == "ADJEST_UI_POS" then
	
		ZhouNian12_RuiHe_On_ResetPos()

	end
	
end

--=========
-- 重置
--=========
function ZhouNian12_RuiHe_On_ResetPos()

	ZhouNian12_RuiHe_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 关闭
--=========
function ZhouNian12_RuiHe_OnClosed()
	
	ZhouNian12_RuiHe_Clear()
	this:Hide()
	
end

--=========
-- 更新界面index：1代表整合界面打开，2代表玩家通过npc或者再玩一次界面查看，3代表领奖之后主动弹出,isGetAward是否领奖，nGetNum领全奖的次数
--=========
function ZhouNian12_RuiHe_Update(index, misdata2days, misdata4days, nGetNum)
	
	if index == 1 then
	
		for i = 1, nGetNum do
			g_Progress[i]:Show()
		end

		if nGetNum == g_GetAwardLimit and misdata4days == 0 then
			ZhouNian12_RuiHe_Animate1:Play(true)
		end
		
		if misdata2days == 0 and nGetNum >= 2 then
			ZhouNian12_RuiHe_Animate2:Play(true)
		end
		
		if nGetNum == 4 then
			g_ProgressAnim[4]:Play(true)
		end
		
		ZhouNian12_RuiHe_Go:Show()
	
	elseif index == 2 then
	
		for i = 1, nGetNum do
			g_Progress[i]:Show()
		end
		
		if nGetNum == g_GetAwardLimit and misdata4days == 0 then
			ZhouNian12_RuiHe_Animate1:Play(true)
		end
		
		if misdata2days == 0 and nGetNum >= 2 then
			ZhouNian12_RuiHe_Animate2:Play(true)
		end
		
		if nGetNum == 4 then
			g_ProgressAnim[4]:Play(true)
		end
	
	elseif index == 3 then
	
		for i = 1, nGetNum-1 do
			g_Progress[i]:Show()
		end
		
		g_NowShowIndex = nGetNum
		SetTimer("ZhouNian12_RuiHe","ZhouNian12_RuiHe_Timer()", 1*1800)
		g_ProgressAnim[nGetNum]:Play(true)
		
		if nGetNum == g_GetAwardLimit and misdata4days == 0 then
			ZhouNian12_RuiHe_Animate1:Play(true)
		end
		
		if misdata2days == 0 and nGetNum >= 2 then
			ZhouNian12_RuiHe_Animate2:Play(true)
		end
		
	end
	if nGetNum == 4 then
		ZhouNian12_RuiHe_Jihuo:SetText("#{ZNYR_190316_100}")
	elseif nGetNum == 3 then
		ZhouNian12_RuiHe_Jihuo:SetText("#{ZNYR_190316_99}")
	elseif nGetNum == 2 then
		ZhouNian12_RuiHe_Jihuo:SetText("#{ZNYR_190316_98}")
	elseif nGetNum == 1 then
		ZhouNian12_RuiHe_Jihuo:SetText("#{ZNYR_190316_97}")
	elseif  nGetNum == 0 then
		ZhouNian12_RuiHe_Jihuo:SetText("#{ZNYR_190316_101}")
	end
	this:Show()
end

function ZhouNian12_RuiHe_Timer()
	
	KillTimer("ZhouNian12_RuiHe_Timer()")
	if g_NowShowIndex == -1 then
		return
	end
	g_Progress[g_NowShowIndex]:Show()
	if g_NowShowIndex ~= 4 then
		g_ProgressAnim[g_NowShowIndex]:Play(false)
	end
	if g_NowShowIndex == 3 then
		g_ProgressAnim[5]:Play(true)
	end
	
end

function ZhouNian12_RuiHe_Clear()
	
	g_NowShowIndex = -1
	
	for i = 1, 4 do
		g_Progress[i]:Hide()
	end
	
	for i = 1, 5 do
		g_ProgressAnim[i]:Play(false)
	end
	
	ZhouNian12_RuiHe_Go:Hide()
	ZhouNian12_RuiHe_Animate1:Play(false)
	ZhouNian12_RuiHe_Animate2:Play(false)
	-- ZhouNian12_RuiHe_Get:Hide()
	
end

function ZhouNian12_RuiHe_Client_HelpClicked()
	PushEvent( "OPEN_HUODONGTEXT_HELP", 1288, "#{ZNYR_190316_55}")
end

function ZhouNian12_RuiHe_Go_Click()

	AutoRunToTargetEx(242,269,0)
	SetAutoRunTargetNPCName( "鹤舞" )

end

function ZhouNian12_RuiHe_Award(index)

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetRuiHeAward" )
		Set_XSCRIPT_ScriptID( 893066 )
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end