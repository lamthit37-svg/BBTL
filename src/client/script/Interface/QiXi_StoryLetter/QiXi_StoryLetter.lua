--2026七夕剧情副本任务

local g_QiXi_StoryLetter_Frame_UnifiedPosition

--观首、观脊、观尾：点击标记
--作为图片3个蒙版显隐的标记
local g_QiXi_StoryLetter_Button1_Finish
local g_QiXi_StoryLetter_Button2_Finish
local g_QiXi_StoryLetter_Button3_Finish

--活动时间
local g_QiXi_StoryLetter_StartDay
local g_QiXi_StoryLetter_EndDay

--MD
local g_QiXi_StoryLetter_MD = 3493 --龙门老玩家的标记

--MF
local g_QiXi_StoryLetter_MF1 = 5660 --第1个界面的按钮点击标记
local g_QiXi_StoryLetter_MF2 = 5661 --第2个界面前3个按钮的点击标记
local g_QiXi_StoryLetter_MF3 = 5664 --第2个界面第4个按钮的点击标记

local g_QiXi_StoryLetter_Animate --动画是否正在播放：1，是；0，否

--界面编号
local g_QiXi_StoryLetter_UIIndex

--=========
-- PreLoad()
--=========
function QiXi_StoryLetter_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	
end

--=========
-- OnLoad()
--=========
function QiXi_StoryLetter_OnLoad()
	g_QiXi_StoryLetter_Frame_UnifiedPosition = QiXi_StoryLetter_Frame:GetProperty("UnifiedPosition")

	g_QiXi_StoryLetter_Button1_Finish = 0
	g_QiXi_StoryLetter_Button2_Finish = 0
	g_QiXi_StoryLetter_Button3_Finish = 0

	g_QiXi_StoryLetter_StartDay	 = 0
	g_QiXi_StoryLetter_EndDay = 0
	
	g_QiXi_StoryLetter_UIIndex = 1
	g_QiXi_StoryLetter_Animate = 0
	
	QiXi_StoryLetter_TextMask_1_Animate:Hide()
	QiXi_StoryLetter_TextMask_2_Animate:Hide()
	QiXi_StoryLetter_TextMask_3_Animate:Hide()	
end

--=========
-- Event
--=========
function QiXi_StoryLetter_OnEvent(event)
	if event == "UI_COMMAND" then
		local commandIndex = tonumber(arg0)
 		if commandIndex == 50520101 then		
			local operInd = Get_XParam_INT(0)
			--关闭
			if operInd == 0 then
				QiXi_StoryLetter_Close()
			--打开
			elseif operInd == 1 then
				g_QiXi_StoryLetter_Button1_Finish = 0
				g_QiXi_StoryLetter_Button2_Finish = 0
				g_QiXi_StoryLetter_Button3_Finish = 0
				g_QiXi_StoryLetter_UIIndex = 1
				g_QiXi_StoryLetter_Animate = 0
				-- QiXi_StoryLetter_TextMask_1_Animate:Hide()
				-- QiXi_StoryLetter_TextMask_2_Animate:Hide()
				-- QiXi_StoryLetter_TextMask_3_Animate:Hide()					
				local md = DataPool:GetPlayerMission_DataRound(g_QiXi_StoryLetter_MD)
				local mf1 = Pneuma:GetMF(g_QiXi_StoryLetter_MF1)
				local mf2 = Pneuma:GetMF(g_QiXi_StoryLetter_MF2)
				local mf3 = Pneuma:GetMF(g_QiXi_StoryLetter_MF3)
				if md>0 then
					g_QiXi_StoryLetter_UIIndex = 3
				elseif mf3==1 then
					g_QiXi_StoryLetter_UIIndex = 3
				elseif mf2==1 then
					g_QiXi_StoryLetter_UIIndex = 2
					g_QiXi_StoryLetter_Button1_Finish = 1
					g_QiXi_StoryLetter_Button2_Finish = 1
					g_QiXi_StoryLetter_Button3_Finish = 1					
				elseif mf1==1 then
					g_QiXi_StoryLetter_UIIndex = 2
				else
					g_QiXi_StoryLetter_UIIndex = 1
				end
				g_QiXi_StoryLetter_StartDay = Get_XParam_INT(1)
				g_QiXi_StoryLetter_EndDay = Get_XParam_INT(2)
				QiXi_StoryLetter_Update_Data()
				this:Show()
			--关闭 并 寻路
			elseif operInd == 2 then
				QiXi_StoryLetter_Close()
				AutoRuntoTargetExWithName(253, 250, 0, "卢氏女")
			end
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		QiXi_StoryLetter_Close()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		QiXi_StoryLetter_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		QiXi_StoryLetter_On_ResetPos()
	end

end

--===========
--按钮：观首
--===========
function QiXi_StoryLetter_OpenBtn_1_OnClick()
	--活动时间
	local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay<g_QiXi_StoryLetter_StartDay or curDay>g_QiXi_StoryLetter_EndDay then
		PushDebugMessage("#{XYYJ_260529_11}")
		this:Hide()
		return
	end
	--玩家等级
	local curLevel = Player:GetLevel()
	if curLevel<30 then
		PushDebugMessage("#{XYYJ_260529_201}")
		this:Hide()
		return		
	end
	
	--动画正在播放
	if g_QiXi_StoryLetter_Animate>0 then
		PushDebugMessage("#{XYYJ_260529_124}")
		return
	end
	
	if g_QiXi_StoryLetter_Button1_Finish == 0 then
		PushDebugMessage("#{XYYJ_260529_109}")
	end
	g_QiXi_StoryLetter_Button1_Finish = 1
	QiXi_StoryLetter_TextMask_1:Show()
	QiXi_StoryLetter_PlayAnimate(1)
	QiXi_StoryLetter_OpenBtn_1:Hide()
	if g_QiXi_StoryLetter_Button1_Finish==1 and g_QiXi_StoryLetter_Button2_Finish==1 and g_QiXi_StoryLetter_Button3_Finish==1 then
		local mf2 = Pneuma:GetMF(g_QiXi_StoryLetter_MF2)
		if mf2==0 then
			PushDebugMessage("#{XYYJ_260529_92}")
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("SetMFOpenNextUI")
				Set_XSCRIPT_ScriptID(505201)
				Set_XSCRIPT_Parameter(0, 2)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()	
		end
	end	
	QiXi_StoryLetter_Update_Data()
end

--===========
--按钮：观脊
--===========
function QiXi_StoryLetter_OpenBtn_2_OnClick()
	--活动时间
	local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay<g_QiXi_StoryLetter_StartDay or curDay>g_QiXi_StoryLetter_EndDay then
		PushDebugMessage("#{XYYJ_260529_11}")
		this:Hide()
		return
	end
	--玩家等级
	local curLevel = Player:GetLevel()
	if curLevel<30 then
		PushDebugMessage("#{XYYJ_260529_201}")
		this:Hide()
		return		
	end
	
	--动画正在播放
	if g_QiXi_StoryLetter_Animate>0 then
		PushDebugMessage("#{XYYJ_260529_124}")
		return
	end
	
	if g_QiXi_StoryLetter_Button2_Finish == 0 then
		PushDebugMessage("#{XYYJ_260529_110}")
	end	
	g_QiXi_StoryLetter_Button2_Finish = 1
	QiXi_StoryLetter_TextMask_2:Show()
	QiXi_StoryLetter_PlayAnimate(2)	
	QiXi_StoryLetter_OpenBtn_2:Hide()
	if g_QiXi_StoryLetter_Button1_Finish==1 and g_QiXi_StoryLetter_Button2_Finish==1 and g_QiXi_StoryLetter_Button3_Finish==1 then
		local mf2 = Pneuma:GetMF(g_QiXi_StoryLetter_MF2)
		if mf2==0 then
			PushDebugMessage("#{XYYJ_260529_92}")
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("SetMFOpenNextUI")
				Set_XSCRIPT_ScriptID(505201)
				Set_XSCRIPT_Parameter(0, 2)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()	
		end
	end	
	QiXi_StoryLetter_Update_Data()
end

--===========
--按钮：观尾
--===========
function QiXi_StoryLetter_OpenBtn_3_OnClick()
	--活动时间
	local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay<g_QiXi_StoryLetter_StartDay or curDay>g_QiXi_StoryLetter_EndDay then
		PushDebugMessage("#{XYYJ_260529_11}")
		this:Hide()
		return
	end
	--玩家等级
	local curLevel = Player:GetLevel()
	if curLevel<30 then
		PushDebugMessage("#{XYYJ_260529_201}")
		this:Hide()
		return		
	end
	if g_QiXi_StoryLetter_Button3_Finish == 0 then
		PushDebugMessage("#{XYYJ_260529_111}")
	end
	
	--动画正在播放
	if g_QiXi_StoryLetter_Animate>0 then
		PushDebugMessage("#{XYYJ_260529_124}")
		return
	end
	
	g_QiXi_StoryLetter_Button3_Finish = 1
	QiXi_StoryLetter_TextMask_3:Show()
	QiXi_StoryLetter_PlayAnimate(3)	
	QiXi_StoryLetter_OpenBtn_3:Hide()
	if g_QiXi_StoryLetter_Button1_Finish==1 and g_QiXi_StoryLetter_Button2_Finish==1 and g_QiXi_StoryLetter_Button3_Finish==1 then
		local mf2 = Pneuma:GetMF(g_QiXi_StoryLetter_MF2)
		if mf2==0 then
			PushDebugMessage("#{XYYJ_260529_92}")
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("SetMFOpenNextUI")
				Set_XSCRIPT_ScriptID(505201)
				Set_XSCRIPT_Parameter(0, 2)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()	
		end
	end	
	QiXi_StoryLetter_Update_Data()
end

--===========
--按钮：奇怪
--===========
function QiXi_StoryLetter_GoBtn_OnClick()
	local md = DataPool:GetPlayerMission_DataRound(g_QiXi_StoryLetter_MD)
	local mf3 = Pneuma:GetMF(g_QiXi_StoryLetter_MF3)
	if md>0 or mf3>0 then
		--活动时间
		local curDay = tonumber(DataPool:GetServerDayTime())
		if curDay<g_QiXi_StoryLetter_StartDay or curDay>g_QiXi_StoryLetter_EndDay then
			PushDebugMessage("#{XYYJ_260529_11}")
			this:Hide()
			return
		end
		--玩家等级
		local curLevel = Player:GetLevel()
		if curLevel<30 then
			PushDebugMessage("#{XYYJ_260529_24}")
			this:Hide()
			return		
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("DoSomething")
			Set_XSCRIPT_ScriptID(505201)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end

--=========
-- 重置
--=========
function QiXi_StoryLetter_On_ResetPos()

	QiXi_StoryLetter_Frame:SetProperty("UnifiedPosition", g_QiXi_StoryLetter_Frame_UnifiedPosition)

end

function QiXi_StoryLetter_Close()
	this:Hide()
end

--界面1：按钮
function QiXi_StoryLetter_Stage1_OpenBtn_OnClick()
	--策划没给任何判断
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SetMFOpenNextUI")
		Set_XSCRIPT_ScriptID(505201)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

--界面2：第4个按钮
function QiXi_StoryLetter_JieMiBtn_OnClick()
	--策划没给任何判断
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SetMFOpenNextUI")
		Set_XSCRIPT_ScriptID(505201)
		Set_XSCRIPT_Parameter(0, 3)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

--播动画
function QiXi_StoryLetter_PlayAnimate(nIndex)
	if g_QiXi_StoryLetter_Animate > 0 then
		return
	end
	KillTimer("QiXi_StoryLetter_Timer()")
	if nIndex==1 then
		g_QiXi_StoryLetter_Animate = 1
		QiXi_StoryLetter_TextMask_1_Animate:Show()
		QiXi_StoryLetter_TextMask_1_Animate:Play(true)
		SetTimer("QiXi_StoryLetter", "QiXi_StoryLetter_Timer()", 3000)
	elseif nIndex==2 then
		g_QiXi_StoryLetter_Animate = 2
		QiXi_StoryLetter_TextMask_2_Animate:Show()
		QiXi_StoryLetter_TextMask_2_Animate:Play(true)
		SetTimer("QiXi_StoryLetter", "QiXi_StoryLetter_Timer()", 3000)
	elseif nIndex==3 then
		g_QiXi_StoryLetter_Animate = 3
		QiXi_StoryLetter_TextMask_3_Animate:Show()
		QiXi_StoryLetter_TextMask_3_Animate:Play(true)	
		SetTimer("QiXi_StoryLetter", "QiXi_StoryLetter_Timer()", 3000)
	end
end

--**********************************
--客户端计时器
--**********************************
function QiXi_StoryLetter_Timer()
	KillTimer("QiXi_StoryLetter_Timer()")
	if g_QiXi_StoryLetter_Animate == 1 then
		QiXi_StoryLetter_TextMask_1_Animate:Hide()
		QiXi_StoryLetter_TextMask_1_Animate:Play(false)
	elseif g_QiXi_StoryLetter_Animate == 2 then
		QiXi_StoryLetter_TextMask_2_Animate:Hide()
		QiXi_StoryLetter_TextMask_2_Animate:Play(false)	
	elseif g_QiXi_StoryLetter_Animate == 3 then
		QiXi_StoryLetter_TextMask_3_Animate:Hide()
		QiXi_StoryLetter_TextMask_3_Animate:Play(false)	
	end
	g_QiXi_StoryLetter_Animate = 0
end

--=============
-- 刷新界面数据
--=============
function QiXi_StoryLetter_Update_Data()
	if g_QiXi_StoryLetter_UIIndex==1 then
		QiXi_StoryLetter_Stage1:Show()
		QiXi_StoryLetter_Stage2:Hide()
	elseif g_QiXi_StoryLetter_UIIndex==2 then
		QiXi_StoryLetter_Stage1:Hide()
		QiXi_StoryLetter_Stage2:Show()	
		QiXi_StoryLetter_Client1:Show()
		QiXi_StoryLetter_Client2:Hide()
		local mf2 = Pneuma:GetMF(g_QiXi_StoryLetter_MF2)
		if mf2==1 then
			QiXi_StoryLetter_JieMiBtn:Show()
			QiXi_StoryLetter_TipBK:Hide()
			QiXi_StoryLetter_TextMask_1:Show()
			QiXi_StoryLetter_TextMask_2:Show()
			QiXi_StoryLetter_TextMask_3:Show()
			QiXi_StoryLetter_OpenBtn_1:Hide()
			QiXi_StoryLetter_OpenBtn_2:Hide()
			QiXi_StoryLetter_OpenBtn_3:Hide()
		else
			QiXi_StoryLetter_JieMiBtn:Hide()
			QiXi_StoryLetter_TipBK:Show()
			if g_QiXi_StoryLetter_Button1_Finish==1 then
				QiXi_StoryLetter_TextMask_1:Show()
				QiXi_StoryLetter_OpenBtn_1:Hide()
			else
				QiXi_StoryLetter_TextMask_1:Hide()
				QiXi_StoryLetter_OpenBtn_1:Show()
			end
			if g_QiXi_StoryLetter_Button2_Finish==1 then
				QiXi_StoryLetter_TextMask_2:Show()
				QiXi_StoryLetter_OpenBtn_2:Hide()
			else
				QiXi_StoryLetter_TextMask_2:Hide()
				QiXi_StoryLetter_OpenBtn_2:Show()
			end			
			if g_QiXi_StoryLetter_Button3_Finish==1 then
				QiXi_StoryLetter_TextMask_3:Show()
				QiXi_StoryLetter_OpenBtn_3:Hide()
			else
				QiXi_StoryLetter_TextMask_3:Hide()
				QiXi_StoryLetter_OpenBtn_3:Show()
			end			
		end
	elseif g_QiXi_StoryLetter_UIIndex==3 then
		QiXi_StoryLetter_Stage1:Hide()
		QiXi_StoryLetter_Stage2:Show()	
		QiXi_StoryLetter_Client1:Hide()
		QiXi_StoryLetter_Client2:Show()
	end
end
