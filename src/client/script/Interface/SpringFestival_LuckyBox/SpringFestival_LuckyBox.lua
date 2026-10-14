
local g_Frame_UnifiedPosition

local g_SpringFestival_LuckyBox_CurCut = 100
local g_SpringFestival_LuckyBox_ChouJiang = 1
local g_SpringFestival_LuckyBox_TodayCut = 0
local g_SpringFestival_LuckyBox_OldCut = 0
local g_SpringFestival_LuckyBox_bagIndex = -1

--=========
-- PreLoad
--=========
function SpringFestival_LuckyBox_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

--=========
-- OnLoad
--=========
function SpringFestival_LuckyBox_OnLoad()

	g_Frame_UnifiedPosition = SpringFestival_LuckyBox_Frame:GetProperty("UnifiedPosition") 
		
end

--=========
-- OnEvent
--=========
function SpringFestival_LuckyBox_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 89332403 then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			if IsWindowShow("SpringFestival_LuckyBox") then
				SpringFestival_LuckyBox_OnHiden()
				return
			end
		end
		if bShow > 0 then			
			g_SpringFestival_LuckyBox_ChouJiang = Get_XParam_INT(1)
			g_SpringFestival_LuckyBox_CurCut = Get_XParam_INT(2)
			g_SpringFestival_LuckyBox_TodayCut = Get_XParam_INT(3)
			g_SpringFestival_LuckyBox_OldCut = Get_XParam_INT(4)
			g_SpringFestival_LuckyBox_bagIndex = Get_XParam_INT(5)
			
			SpringFestival_LuckyBox_Update( bShow )	
		else
			SpringFestival_LuckyBox_OnHiden()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_LuckyBox_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		SpringFestival_LuckyBox_On_ResetPos()
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
	
		SpringFestival_LuckyBox_OnHiden();

	end

end

function SpringFestival_LuckyBox_TimerProc()
	
	KillTimer("SpringFestival_LuckyBox_TimerProc()")
	
	SpringFestival_LuckyBox_Animate:Hide()
	SpringFestival_LuckyBox_Animate2:Hide()
	SpringFestival_LuckyBox_Animate3:Hide()
	
	SpringFestival_LuckyBox_Text5:Hide()
	
	if g_SpringFestival_LuckyBox_OldCut <= g_SpringFestival_LuckyBox_TodayCut then
		SpringFestival_LuckyBox_Animate3:Show()
		SpringFestival_LuckyBox_Animate3:Play(true)
	else
		SpringFestival_LuckyBox_Animate2:Show()
		SpringFestival_LuckyBox_Animate2:Play(true)
	end
	
	SetTimer("SpringFestival_LuckyBox", "SpringFestival_LuckyBox_TimerProc2()", 1000)

end

function SpringFestival_LuckyBox_TimerProc2()

	KillTimer("SpringFestival_LuckyBox_TimerProc2()")
	
	if g_SpringFestival_LuckyBox_OldCut <= g_SpringFestival_LuckyBox_TodayCut then
		-- 显示已抽取
		SpringFestival_LuckyBox_Image2:Hide()
		SpringFestival_LuckyBox_Image3:Show()
		-- 隐藏新折扣
		SpringFestival_LuckyBox_Text5:Hide()
		-- 旧折扣划线
		SpringFestival_LuckyBox_PriceText1:Hide()
	else
		-- 显示已替换
		SpringFestival_LuckyBox_Image2:Show()
		SpringFestival_LuckyBox_Image3:Hide()
		if g_SpringFestival_LuckyBox_OldCut == 100 then
			-- 旧折扣划线
			SpringFestival_LuckyBox_PriceText1:Hide()
			-- 隐藏新折扣
			SpringFestival_LuckyBox_Text5:Hide()
			-- 不划线 直接显示折扣
			str = ScriptGlobal_Format("#{SZYG_191126_85}", g_SpringFestival_LuckyBox_TodayCut/10)
			SpringFestival_LuckyBox_Text2:SetText( str )
		else
			-- 旧折扣划线
			SpringFestival_LuckyBox_PriceText1:Show()
			-- 显示新折扣
			SpringFestival_LuckyBox_Text5:Show()	
			str = ScriptGlobal_Format("#{SZYG_191126_85}", g_SpringFestival_LuckyBox_TodayCut/10)	
			SpringFestival_LuckyBox_Text5:SetText( str )
		end
	end
	
	-- 今天的折扣
	SpringFestival_LuckyBox_Text4:Show()
	str = ScriptGlobal_Format("#{SZYG_191126_85}", g_SpringFestival_LuckyBox_TodayCut/10)
	SpringFestival_LuckyBox_Text4:SetText( str )
end

--=========
-- 打开
--=========
function SpringFestival_LuckyBox_Update( bShow )	
	
	local str = ""	
			
	SpringFestival_LuckyBox_Animate:Hide()
	SpringFestival_LuckyBox_Animate2:Hide()
	SpringFestival_LuckyBox_Animate3:Hide()
	if bShow == 2 then
		SpringFestival_LuckyBox_Animate:Show()
		SpringFestival_LuckyBox_Animate:Play(true)
				
		SetTimer("SpringFestival_LuckyBox", "SpringFestival_LuckyBox_TimerProc()", 3000)
	
		-- 原来的折扣
		if g_SpringFestival_LuckyBox_OldCut == 100 then
			str = "#{SZYG_191126_152}"
		else
			str = ScriptGlobal_Format("#{SZYG_191126_85}", g_SpringFestival_LuckyBox_OldCut/10)
		end
		SpringFestival_LuckyBox_Text2:SetText( str )	
		
		SpringFestival_LuckyBox_Text4:Hide()
		
	else
		-- 划线不显示
		SpringFestival_LuckyBox_PriceText1:Hide()
		SpringFestival_LuckyBox_Text5:Hide()
		
		-- 原来的折扣
		if g_SpringFestival_LuckyBox_CurCut == 100 then
			str = "#{SZYG_191126_152}"
		else
			str = ScriptGlobal_Format("#{SZYG_191126_85}", g_SpringFestival_LuckyBox_CurCut/10)
		end
		SpringFestival_LuckyBox_Text2:SetText( str )	
	
		-- 今日抽取折扣
		SpringFestival_LuckyBox_Text4:Show()
		SpringFestival_LuckyBox_Image2:Hide()
		SpringFestival_LuckyBox_Image3:Hide()
		if g_SpringFestival_LuckyBox_TodayCut > 0 and g_SpringFestival_LuckyBox_ChouJiang == 1 then
			str = ScriptGlobal_Format("#{SZYG_191126_164}", g_SpringFestival_LuckyBox_TodayCut/10)
			SpringFestival_LuckyBox_Text4:SetText( str )
			if g_SpringFestival_LuckyBox_TodayCut == g_SpringFestival_LuckyBox_CurCut then
				SpringFestival_LuckyBox_Image2:Show()
			else
				SpringFestival_LuckyBox_Image3:Show()
			end
		else
			SpringFestival_LuckyBox_Text4:SetText( "#{SZYG_191126_161}" )
		end
	end
		
	-- 按钮 及 下面的文字
	SpringFestival_LuckyBox_Text:Hide()
	if g_SpringFestival_LuckyBox_ChouJiang == 1 then
		str = ScriptGlobal_Format("#{SZYG_191126_119}", 0)
		SpringFestival_LuckyBox_Button:Disable()
	else
		str = ScriptGlobal_Format("#{SZYG_191126_83}", 1)
		SpringFestival_LuckyBox_Button:Enable()
	end
	SpringFestival_LuckyBox_Text:SetText( str )

	this:Show()
	
end

--=========
-- 关闭
--=========
function SpringFestival_LuckyBox_OnHiden()

	this:Hide()

end

--=========
-- 重置
--=========
function SpringFestival_LuckyBox_On_ResetPos()

	SpringFestival_LuckyBox_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 帮助
--=========
function SpringFestival_LuckyBox_HelpClick()

    Clear_XSCRIPT()
    	Set_XSCRIPT_Function_Name("OnShowFashionHelp")
    	Set_XSCRIPT_ScriptID(893324)
    	Set_XSCRIPT_Parameter(0, 5);
    	Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()		
	
end

--=========
-- 确认
--=========
function SpringFestival_LuckyBox_ClickOK()
	
    Clear_XSCRIPT()
    	Set_XSCRIPT_Function_Name("OnChouJiang")
    	Set_XSCRIPT_ScriptID(893324)
		Set_XSCRIPT_Parameter(0, g_SpringFestival_LuckyBox_bagIndex)
    	Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()		
	
end

