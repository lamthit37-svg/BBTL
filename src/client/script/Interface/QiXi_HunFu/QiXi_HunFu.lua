-- 2019七夕制婚服

local g_Frame_UnifiedPosition
local g_MaxSucNum = 10
local g_FourthSucNum = 8
local g_MidSucNum = 6
local g_SecondSucNum = 4
local g_StartSucNum = 2
local g_StartTime = 20230814
local g_MidTime = 20230827
local g_EndTime = 20230830
local g_NowPro = -1
local g_FlashUI = -1
function QiXi_HunFu_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)

end

function QiXi_HunFu_OnLoad()
	
	g_Frame_UnifiedPosition = QiXi_HunFu_Frame:GetProperty("UnifiedPosition") 
	
	QiXi_HunFu_Clear()
	
end

function QiXi_HunFu_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 893126001 then
		
		local index = Get_XParam_INT(0)
		
		-- 1.代表游戏成功后主动弹开界面，2.代表玩家在npc处主动查看界面，3.代表从整合界面的打开
		if  index == nil or index < 1 or index > 3 then
			return 
		end
		
		local sucnum = Get_XParam_INT(1)
		
		if sucnum == nil or sucnum < 0 then
			return 
		end
		local isget1 = Get_XParam_INT(2)
		local isget2 = Get_XParam_INT(3)
		local isget3 = Get_XParam_INT(4)
		local isget4 = Get_XParam_INT(5)
		local isget5 = Get_XParam_INT(6)
		QiXi_HunFu_Clear()
		QiXi_HunFu_Updata(index, sucnum, isget1, isget2, isget3, isget4, isget5)
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		QiXi_HunFu_On_ResetPos()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
	
		QiXi_HunFu_OnClosed()
		
	elseif event == "ADJEST_UI_POS" then
	
		QiXi_HunFu_On_ResetPos()

	end
	
end

--=========
-- Updata
--=========
-- 1.代表游戏成功后主动弹开界面，2.代表玩家在npc处主动查看界面，3.代表从整合界面的打开
function QiXi_HunFu_Updata(index, sucnum, isget1, isget2, isget3, isget4, isget5)

	if index == 1 then
		if sucnum > g_MaxSucNum then
		
			QiXi_HunFu_Progress1:Show()
			QiXi_HunFu_Progress2:Show()
			QiXi_HunFu_Progress0:Show()
			QiXi_HunFu_Progress3:Show()
			QiXi_HunFu_Progress4:Show()
			
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			if isget2 == 0 then
				QiXi_HunFu_Animate2:Play(true)
				QiXi_HunFu_Get2:Show()
			elseif isget2 == 1 then
				QiXi_HunFu_Prize_Pic2_Yes:Show()
			end
			
			if isget3 == 0 then
				QiXi_HunFu_Animate3:Play(true)
				QiXi_HunFu_Get3:Show()
			elseif isget3 == 1 then
				QiXi_HunFu_Prize_Pic3_Yes:Show()
			end
			
			if isget4 == 0 then
				QiXi_HunFu_Animate4:Play(true)
				QiXi_HunFu_Get4:Show()
			elseif isget4 == 1 then
				QiXi_HunFu_Prize_Pic4_Yes:Show()
			end
			
			if isget5 == 0 then
				QiXi_HunFu_Animate5:Play(true)
				QiXi_HunFu_Get5:Show()
			elseif isget5 == 1 then
				QiXi_HunFu_Prize_Pic5_Yes:Show()
			end
			
			QiXi_HunFu_Progress_Animate:Play(true)
			
		elseif sucnum == g_MaxSucNum then
		
			g_NowPro = 3
		
			QiXi_HunFu_Progress1:Show()
			QiXi_HunFu_Progress0:Show()
			QiXi_HunFu_Progress3:Show()
			QiXi_HunFu_Progress4:Show()
			
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			if isget2 == 0 then
				QiXi_HunFu_Animate2:Play(true)
				QiXi_HunFu_Get2:Show()
			elseif isget2 == 1 then
				QiXi_HunFu_Prize_Pic2_Yes:Show()
			end
			
			if isget3 == 0 then
				QiXi_HunFu_Animate3:Play(true)
				QiXi_HunFu_Get3:Show()
			elseif isget3 == 1 then
				QiXi_HunFu_Prize_Pic3_Yes:Show()
			end
			
			if isget4 == 0 then
				QiXi_HunFu_Animate4:Play(true)
				QiXi_HunFu_Get4:Show()
			elseif isget4 == 1 then
				QiXi_HunFu_Prize_Pic4_Yes:Show()
			end
			
			if isget5 == 0 then
				QiXi_HunFu_Animate5:Play(true)
				QiXi_HunFu_Get5:Show()
			elseif isget5 == 1 then
				QiXi_HunFu_Prize_Pic5_Yes:Show()
			end
			
			QiXi_HunFu_Progress_Animate:Play(true)
			SetTimer("QiXi_HunFu","QiXi_HunFu_Timer()", 1*1800)
			
		elseif sucnum > g_FourthSucNum then
		
			QiXi_HunFu_Progress0:Show()
			QiXi_HunFu_Progress1:Show()
			QiXi_HunFu_Progress2:Hide()
			QiXi_HunFu_Progress3:Show()
			QiXi_HunFu_Progress4:Show()
			
			
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			if isget2 == 0 then
				QiXi_HunFu_Animate2:Play(true)
				QiXi_HunFu_Get2:Show()
			elseif isget2 == 1 then
				QiXi_HunFu_Prize_Pic2_Yes:Show()
			end
			
			if isget3 == 0 then
				QiXi_HunFu_Animate3:Play(true)
				QiXi_HunFu_Get3:Show()
			elseif isget3 == 1 then
				QiXi_HunFu_Prize_Pic3_Yes:Show()
			end
			
			if isget4 == 0 then
				QiXi_HunFu_Animate4:Play(true)
				QiXi_HunFu_Get4:Show()
			elseif isget4 == 1 then
				QiXi_HunFu_Prize_Pic4_Yes:Show()
			end
			
			QiXi_HunFu_Prize_Pic5_No:Show()
			
			QiXi_HunFu_Progress_Animate:Play(true)
			
		elseif sucnum == g_FourthSucNum then
		
			g_NowPro = 4
		
			QiXi_HunFu_Progress0:Show()
			QiXi_HunFu_Progress1:Show()
			QiXi_HunFu_Progress3:Show()
			
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			if isget2 == 0 then
				QiXi_HunFu_Animate2:Play(true)
				QiXi_HunFu_Get2:Show()
			elseif isget2 == 1 then
				QiXi_HunFu_Prize_Pic2_Yes:Show()
			end
			
			if isget3 == 0 then
				QiXi_HunFu_Animate3:Play(true)
				QiXi_HunFu_Get3:Show()
			elseif isget3 == 1 then
				QiXi_HunFu_Prize_Pic3_Yes:Show()
			end
			
			if isget4 == 0 then
				QiXi_HunFu_Animate4:Play(true)
				QiXi_HunFu_Get4:Show()
			elseif isget4 == 1 then
				QiXi_HunFu_Prize_Pic4_Yes:Show()
			end
			
			QiXi_HunFu_Prize_Pic5_No:Show()
			
			QiXi_HunFu_Progress_Animate:Play(true)
			SetTimer("QiXi_HunFu","QiXi_HunFu_Timer()", 1*1800)
			
			
			
			
		elseif sucnum > g_MidSucNum then
		
			QiXi_HunFu_Progress0:Show()
			QiXi_HunFu_Progress1:Show()
			QiXi_HunFu_Progress3:Show()
			
			
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			if isget2 == 0 then
				QiXi_HunFu_Animate2:Play(true)
				QiXi_HunFu_Get2:Show()
			elseif isget2 == 1 then
				QiXi_HunFu_Prize_Pic2_Yes:Show()
			end
			
			if isget3 == 0 then
				QiXi_HunFu_Animate3:Play(true)
				QiXi_HunFu_Get3:Show()
			elseif isget3 == 1 then
				QiXi_HunFu_Prize_Pic3_Yes:Show()
			end
			
			
			QiXi_HunFu_Prize_Pic4_No:Show()
			QiXi_HunFu_Prize_Pic5_No:Show()
			
			QiXi_HunFu_Progress_Animate:Play(true)
			
		elseif sucnum == g_MidSucNum then
		
			g_NowPro = 2
		
			QiXi_HunFu_Progress0:Show()
			QiXi_HunFu_Progress3:Show()
			
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			if isget2 == 0 then
				QiXi_HunFu_Animate2:Play(true)
				QiXi_HunFu_Get2:Show()
			elseif isget2 == 1 then
				QiXi_HunFu_Prize_Pic2_Yes:Show()
			end
			
			if isget3 == 0 then
				QiXi_HunFu_Animate3:Play(true)
				QiXi_HunFu_Get3:Show()
			elseif isget3 == 1 then
				QiXi_HunFu_Prize_Pic3_Yes:Show()
			end
			
			
			QiXi_HunFu_Prize_Pic4_No:Show()
			QiXi_HunFu_Prize_Pic5_No:Show()
			
			QiXi_HunFu_Progress_Animate:Play(true)
			SetTimer("QiXi_HunFu","QiXi_HunFu_Timer()", 1*1800)
			
		elseif sucnum > g_SecondSucNum then
		
			QiXi_HunFu_Progress0:Show()
			QiXi_HunFu_Progress1:Hide()
			QiXi_HunFu_Progress2:Hide()
			QiXi_HunFu_Progress3:Show()
			QiXi_HunFu_Progress4:Hide()
			
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			if isget2 == 0 then
				QiXi_HunFu_Animate2:Play(true)
				QiXi_HunFu_Get2:Show()
			elseif isget2 == 1 then
				QiXi_HunFu_Prize_Pic2_Yes:Show()
			end
			
			
			QiXi_HunFu_Prize_Pic3_No:Show()
			QiXi_HunFu_Prize_Pic4_No:Show()
			QiXi_HunFu_Prize_Pic5_No:Show()
			QiXi_HunFu_Progress_Animate:Play(true)
			
		elseif sucnum == g_SecondSucNum then
		
			g_NowPro = 5
			
			QiXi_HunFu_Progress0:Show()
				
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			if isget2 == 0 then
				QiXi_HunFu_Animate2:Play(true)
				QiXi_HunFu_Get2:Show()
			elseif isget2 == 1 then
				QiXi_HunFu_Prize_Pic2_Yes:Show()
			end
			
			
			QiXi_HunFu_Prize_Pic3_No:Show()
			QiXi_HunFu_Prize_Pic4_No:Show()
			QiXi_HunFu_Prize_Pic5_No:Show()
			
			QiXi_HunFu_Progress_Animate:Play(true)
			SetTimer("QiXi_HunFu","QiXi_HunFu_Timer()", 1*1800)
			
			
			
		elseif sucnum > g_StartSucNum then
		
			QiXi_HunFu_Progress0:Show()
			QiXi_HunFu_Progress1:Hide()
			QiXi_HunFu_Progress2:Hide()
			QiXi_HunFu_Progress3:Hide()
			QiXi_HunFu_Progress4:Hide()
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			
			QiXi_HunFu_Prize_Pic2_No:Show()
			QiXi_HunFu_Prize_Pic3_No:Show()
			QiXi_HunFu_Prize_Pic4_No:Show()
			QiXi_HunFu_Prize_Pic5_No:Show()
			QiXi_HunFu_Progress_Animate:Play(true)
			
		elseif sucnum == g_StartSucNum then
		
			g_NowPro = 1
				
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			
			QiXi_HunFu_Prize_Pic2_No:Show()
			QiXi_HunFu_Prize_Pic3_No:Show()
			QiXi_HunFu_Prize_Pic4_No:Show()
			QiXi_HunFu_Prize_Pic5_No:Show()
			
			QiXi_HunFu_Progress_Animate:Play(true)
			SetTimer("QiXi_HunFu","QiXi_HunFu_Timer()", 1*1800)
			
		else
		
			QiXi_HunFu_Progress0:Hide()
			QiXi_HunFu_Progress1:Hide()
			QiXi_HunFu_Progress2:Hide()
			QiXi_HunFu_Progress3:Hide()
			QiXi_HunFu_Progress4:Hide()
			QiXi_HunFu_Prize_Pic1_No:Show()
			QiXi_HunFu_Prize_Pic2_No:Show()
			QiXi_HunFu_Prize_Pic3_No:Show()
			QiXi_HunFu_Prize_Pic4_No:Show()
			QiXi_HunFu_Prize_Pic5_No:Show()
			QiXi_HunFu_Progress_Animate:Play(true)
			
		end
	else
	
		if sucnum >= g_MaxSucNum then
		
			QiXi_HunFu_Progress1:Show()
			QiXi_HunFu_Progress2:Show()
			QiXi_HunFu_Progress0:Show()
			QiXi_HunFu_Progress3:Show()
			QiXi_HunFu_Progress4:Show()
			
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			if isget2 == 0 then
				QiXi_HunFu_Animate2:Play(true)
				QiXi_HunFu_Get2:Show()
			elseif isget2 == 1 then
				QiXi_HunFu_Prize_Pic2_Yes:Show()
			end
			
			if isget3 == 0 then
				QiXi_HunFu_Animate3:Play(true)
				QiXi_HunFu_Get3:Show()
			elseif isget3 == 1 then
				QiXi_HunFu_Prize_Pic3_Yes:Show()
			end
			
			if isget4 == 0 then
				QiXi_HunFu_Animate4:Play(true)
				QiXi_HunFu_Get4:Show()
			elseif isget4 == 1 then
				QiXi_HunFu_Prize_Pic4_Yes:Show()
			end
			
			if isget5 == 0 then
				QiXi_HunFu_Animate5:Play(true)
				QiXi_HunFu_Get5:Show()
			elseif isget5 == 1 then
				QiXi_HunFu_Prize_Pic5_Yes:Show()
			end
			
		elseif sucnum >= g_FourthSucNum then
		
			QiXi_HunFu_Progress0:Show()
			QiXi_HunFu_Progress1:Show()
			QiXi_HunFu_Progress2:Hide()
			QiXi_HunFu_Progress3:Show()
			QiXi_HunFu_Progress4:Show()
			
			
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			if isget2 == 0 then
				QiXi_HunFu_Animate2:Play(true)
				QiXi_HunFu_Get2:Show()
			elseif isget2 == 1 then
				QiXi_HunFu_Prize_Pic2_Yes:Show()
			end
			
			if isget3 == 0 then
				QiXi_HunFu_Animate3:Play(true)
				QiXi_HunFu_Get3:Show()
			elseif isget3 == 1 then
				QiXi_HunFu_Prize_Pic3_Yes:Show()
			end
			
			if isget4 == 0 then
				QiXi_HunFu_Animate4:Play(true)
				QiXi_HunFu_Get4:Show()
			elseif isget4 == 1 then
				QiXi_HunFu_Prize_Pic4_Yes:Show()
			end
			
			QiXi_HunFu_Prize_Pic5_No:Show()
			
			
		elseif sucnum >= g_MidSucNum then
		
			QiXi_HunFu_Progress0:Show()
			QiXi_HunFu_Progress1:Show()
			QiXi_HunFu_Progress2:Hide()
			QiXi_HunFu_Progress3:Show()
			QiXi_HunFu_Progress4:Hide()
			
			
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			if isget2 == 0 then
				QiXi_HunFu_Animate2:Play(true)
				QiXi_HunFu_Get2:Show()
			elseif isget2 == 1 then
				QiXi_HunFu_Prize_Pic2_Yes:Show()
			end
			
			if isget3 == 0 then
				QiXi_HunFu_Animate3:Play(true)
				QiXi_HunFu_Get3:Show()
			elseif isget3 == 1 then
				QiXi_HunFu_Prize_Pic3_Yes:Show()
			end
			
			
			QiXi_HunFu_Prize_Pic4_No:Show()
			QiXi_HunFu_Prize_Pic5_No:Show()
			
		elseif sucnum >= g_SecondSucNum then
		
			QiXi_HunFu_Progress0:Show()
			QiXi_HunFu_Progress1:Hide()
			QiXi_HunFu_Progress2:Hide()
			QiXi_HunFu_Progress3:Show()
			QiXi_HunFu_Progress4:Hide()
			
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			if isget2 == 0 then
				QiXi_HunFu_Animate2:Play(true)
				QiXi_HunFu_Get2:Show()
			elseif isget2 == 1 then
				QiXi_HunFu_Prize_Pic2_Yes:Show()
			end
			
			
			QiXi_HunFu_Prize_Pic3_No:Show()
			QiXi_HunFu_Prize_Pic4_No:Show()
			QiXi_HunFu_Prize_Pic5_No:Show()
			
		elseif sucnum >= g_StartSucNum then
		
			QiXi_HunFu_Progress0:Show()
			QiXi_HunFu_Progress1:Hide()
			QiXi_HunFu_Progress2:Hide()
			QiXi_HunFu_Progress3:Hide()
			QiXi_HunFu_Progress4:Hide()
			if isget1 == 0 then
				QiXi_HunFu_Animate1:Play(true)
				QiXi_HunFu_Get1:Show()
			elseif isget1 == 1 then
				QiXi_HunFu_Prize_Pic1_Yes:Show()
			end
			
			
			QiXi_HunFu_Prize_Pic2_No:Show()
			QiXi_HunFu_Prize_Pic3_No:Show()
			QiXi_HunFu_Prize_Pic4_No:Show()
			QiXi_HunFu_Prize_Pic5_No:Show()
			
		else
		
			QiXi_HunFu_Progress0:Hide()
			QiXi_HunFu_Progress1:Hide()
			QiXi_HunFu_Progress2:Hide()
			QiXi_HunFu_Progress3:Hide()
			QiXi_HunFu_Progress4:Hide()
			QiXi_HunFu_Prize_Pic1_No:Show()
			QiXi_HunFu_Prize_Pic2_No:Show()
			QiXi_HunFu_Prize_Pic3_No:Show()
			QiXi_HunFu_Prize_Pic4_No:Show()
			QiXi_HunFu_Prize_Pic5_No:Show()
			
		end
	end
	
	if index == 1 then
		QiXi_HunFu_Go:Hide()
		--QiXi_HunFu_Progress_Animate:Play(true)
	elseif index == 2 then
		if g_FlashUI == 1 then
			QiXi_HunFu_Go:Show()
			g_FlashUI = -1
		else
			QiXi_HunFu_Go:Hide()		
		end
		--QiXi_HunFu_Progress_Animate:Play(false)
	elseif index == 3 then
		local curDay = tonumber(DataPool:GetServerDayTime())
		if curDay >= g_StartTime and curDay <= g_MidTime then
			QiXi_HunFu_Go:Show()
		else
			QiXi_HunFu_Go:Hide()
		end
		--QiXi_HunFu_Progress_Animate:Play(false)
	end
		
	local text = ScriptGlobal_Format("#{QXHF_190620_113}",sucnum)
	QiXi_HunFu_Jihuo:SetText(text)
	
	this:Show()
end

--=========
-- 重置
--=========
function QiXi_HunFu_On_ResetPos()

	QiXi_HunFu_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 关闭
--=========
function QiXi_HunFu_OnClosed()
	
	QiXi_HunFu_Clear()
	this:Hide()
	g_FlashUI = -1
	
end

function QiXi_HunFu_Clear()

	QiXi_HunFu_Go:Hide()
	QiXi_HunFu_Get1:Hide()
	QiXi_HunFu_Get2:Hide()
	QiXi_HunFu_Get3:Hide()
	QiXi_HunFu_Get4:Hide()
	QiXi_HunFu_Get5:Hide()
	QiXi_HunFu_Animate1:Play(false)
	QiXi_HunFu_Animate2:Play(false)
	QiXi_HunFu_Animate3:Play(false)
	QiXi_HunFu_Animate4:Play(false)
	QiXi_HunFu_Animate5:Play(false)
	QiXi_HunFu_Progress1:Hide()
	QiXi_HunFu_Progress2:Hide()
	QiXi_HunFu_Progress0:Hide()
	QiXi_HunFu_Progress3:Hide()
	QiXi_HunFu_Progress4:Hide()
	QiXi_HunFu_Progress_Animate:Play(false)
	QiXi_HunFu_Prize_Pic1_Yes:Hide()
	QiXi_HunFu_Prize_Pic1_No:Hide()
	QiXi_HunFu_Prize_Pic2_Yes:Hide()
	QiXi_HunFu_Prize_Pic2_No:Hide()
	QiXi_HunFu_Prize_Pic3_Yes:Hide()
	QiXi_HunFu_Prize_Pic3_No:Hide()
	QiXi_HunFu_Prize_Pic4_Yes:Hide()
	QiXi_HunFu_Prize_Pic4_No:Hide()
	QiXi_HunFu_Prize_Pic5_Yes:Hide()
	QiXi_HunFu_Prize_Pic5_No:Hide()
	g_NowPro = -1
	
	
end

function QiXi_HunFu_Client_HelpClicked()
	PushEvent( "OPEN_HUODONGTEXT_HELP", 1316, "#{QXHF_190620_73}")
end

function QiXi_HunFu_Go_Click()

	AutoRunToTargetEx(328,306,1)
	SetAutoRunTargetNPCName( "溪娘" )
	PushDebugMessage("#{QXHF_190620_76}")

end

function QiXi_HunFu_Award_Click(index)

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetAward" )
		Set_XSCRIPT_ScriptID( 893126 )
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
	if index == 1 then
		QiXi_HunFu_Animate1:Play(false)
	elseif index == 2 then
		QiXi_HunFu_Animate2:Play(false)
	elseif index == 3 then
		QiXi_HunFu_Animate3:Play(false)
	elseif index == 4 then
		QiXi_HunFu_Animate4:Play(false)
	elseif index == 5 then
		QiXi_HunFu_Animate5:Play(false)
	end
	if QiXi_HunFu_Go:IsVisible() then
		g_FlashUI = 1
	end
	
end

function QiXi_HunFu_Timer()
	
	KillTimer("ZhouNian12_RuiHe_Timer()")
	if g_NowPro == -1 then
		return
	end
	if g_NowPro == 1 then
		QiXi_HunFu_Progress0:Show()
	elseif g_NowPro == 2 then
		QiXi_HunFu_Progress1:Show()
	elseif g_NowPro == 3 then
		QiXi_HunFu_Progress2:Show()
	elseif g_NowPro == 4 then
		QiXi_HunFu_Progress4:Show()
	elseif g_NowPro == 5 then
		QiXi_HunFu_Progress3:Show()
	end
	
end

