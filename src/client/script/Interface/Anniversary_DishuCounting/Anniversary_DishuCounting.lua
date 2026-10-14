local g_DiShu_StartTime = 0 --开始时间
local g_DiShu_CountTime = 0 --BUFF剩余时间

function Anniversary_DishuCounting_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
    
end


function Anniversary_DishuCounting_OnLoad()

	g_DiShu_StartTime = 0
    g_DiShu_CountTime = 0
    
end


function Anniversary_DishuCounting_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99844503) then		
        local startTime = Get_XParam_INT(0)
        local remainingtTime = Get_XParam_INT(1)
        local score = Get_XParam_INT(2)

        if this:IsVisible() then	-- 如果界面开着，则不处理
			return
        end
        
		if startTime <= 0 or remainingtTime <= 0 then
			return
        end
        
        Anniversary_DishuCounting_TeamScore:SetText(ScriptGlobal_Format("#{CSDS_230216_106}",score))

		g_DiShu_StartTime = startTime
        g_DiShu_CountTime = remainingtTime

		KillTimer("Anniversary_DishuCounting_TimerProc()")
		SetTimer("Anniversary_DishuCounting","Anniversary_DishuCounting_TimerProc()", 1000)	
        this:Show()
    --关闭界面
    elseif (event == "UI_COMMAND" and tonumber(arg0) == 99844505) then
        local score = Get_XParam_INT(0)
        if this:IsVisible() then	-- 如果开着，则处理
			Anniversary_DishuCounting_TeamScore:SetText(ScriptGlobal_Format("#{CSDS_230216_106}",score))
        end
        
	--关闭界面
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99844504) then
		KillTimer("Anniversary_DishuCounting_TimerProc()")
        Anniversary_DishuCounting_Time:SetText(ScriptGlobal_Format("#{CSDS_230216_104}",0))
        g_DiShu_StartTime = 0 
		g_DiShu_CountTime = 0
		this:Hide()
	elseif event=="HIDE_ON_SCENE_TRANSED"  then
		KillTimer("Anniversary_DishuCounting_TimerProc()")
		Anniversary_DishuCounting_Time:SetText(ScriptGlobal_Format("#{CSDS_230216_104}",0))
        g_DiShu_StartTime = 0 
		g_DiShu_CountTime = 0
		this:Hide()
    end
    
end


function Anniversary_DishuCounting_TimerProc()

	local countTime = DataPool:GetCurrentServerTime() - g_DiShu_StartTime
    countTime = g_DiShu_CountTime - countTime
    if countTime <= 0 then
		KillTimer("Anniversary_DishuCounting_TimerProc()")
		Anniversary_DishuCounting_Time:SetText(ScriptGlobal_Format("#{CSDS_230216_104}",0))
        g_DiShu_StartTime = 0 
        g_DiShu_CountTime = 0
        countTime = 0
		this:Hide()
    end

    --剩余时间
    Anniversary_DishuCounting_Time:SetText(ScriptGlobal_Format("#{CSDS_230216_104}",countTime))
	
end