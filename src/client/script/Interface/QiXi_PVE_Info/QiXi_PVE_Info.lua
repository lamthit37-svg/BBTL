
local g_QiXi_PVE_Info_UnifiedPosition

local g_QiXi_PVE_Info_UICommand = 05123801
local g_QiXi_PVE_Info_UICommand_CorrectTime = 05123806
local g_QiXi_PVE_Info_opType = {
	show = 1,						
	update = 2,	
	updatemohua = 3,
    updateTime = 4,
    close = 999,				
}

local g_TotalLevelNum = 4
local g_MaxMoHuaZhi = 100

local g_Data = {
    curActStage = 0,
    curMoHuaZhi = 0,
    levelInfo = "",
    levelDesc = "",
    stepName = "",
    E4State = -1, 

    stageindex = -1,
    subInfo = "",
    subInfo1 = "",
    subInfo2 = "",
    param1_1 =-1,
    param1_2 =-1,
    param2_1 =-1,
    param2_2 =-1,
    param3_1 =-1,
    param3_2 =-1,

}

local g_UI_Items = {
}

local g_PointInfo = {
    {v = 30,u = "#{QXFB_260529_325}",r="#{QXFB_260529_326}"},
    {v = 60,u = "#{QXFB_260529_325}",r="#{QXFB_260529_326}"},
    {v = 90,u = "#{QXFB_260529_325}",r="#{QXFB_260529_326}"},
    {v = 100,u = "#{QXFB_260529_325}",r="#{QXFB_260529_326}"},
}

local g_StageTitleText = {
    ["1"] = "#{QXFB_260529_378}",
    ["2"] = "#{QXFB_260529_379}",
    ["3"] = "#{QXFB_260529_380}",
    ["4"] = "#{QXFB_260529_381}",
}


function QiXi_PVE_Info_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	--离开场景，自动关闭
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS", false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)		
end
--界面21点50到24点显示
function QiXi_PVE_Info_OnLoad()
	g_QiXi_PVE_Info_UnifiedPosition = QiXi_PVE_Info_Frame:GetProperty("UnifiedPosition")
    g_UI_Items.topProgress = QiXi_PVE_Info_TopProgress
    g_UI_Items.topText = QiXi_PVE_Info_TopText
    g_UI_Items.topBK1 = QiXi_PVE_Info_TopBK1
    g_UI_Items.topBK2 = QiXi_PVE_Info_TopBK2
    g_UI_Items.levelMissionText = QiXi_PVE_Info_MissionText
    g_UI_Items.levelSubMissionText = QiXi_PVE_Info_MissionDetail
    g_UI_Items.levelSubMissionTextParam = QiXi_PVE_Info_MissionDetail_1
    g_UI_Items.levelSubMissionText1 = QiXi_PVE_Info_MissionDetail2
    g_UI_Items.levelSubMissionTextParam1 = QiXi_PVE_Info_MissionDetail2_1
    g_UI_Items.levelSubMissionText2 = QiXi_PVE_Info_MissionDetail3
    g_UI_Items.levelSubMissionTextParam2 = QiXi_PVE_Info_MissionDetail3_1

    g_UI_Items.StageTitle = QiXi_PVE_Info_MissionTitle
    
    g_UI_Items.levelMissionBK = {
        QiXi_PVE_Info_MissionDetail_BK,
        QiXi_PVE_Info_MissionDetail2_BK,
        QiXi_PVE_Info_MissionDetail3_BK,
    }
    g_UI_Items.levelMissionPresentBK = {
        QiXi_PVE_Info_MissionDetail_PresentBK,
        QiXi_PVE_Info_MissionDetail2_PresentBK,
        QiXi_PVE_Info_MissionDetail3_PresentBK,
    }

    g_UI_Items.levelDescText = QiXi_PVE_Info_MissionDetail_Text

    g_UI_Items.levelMissionTimer = {
        QiXi_PVE_Info_MissionDetail_Time,
        QiXi_PVE_Info_MissionDetail2_Time,
        QiXi_PVE_Info_MissionDetail3_Time,
    }



    g_UI_Items.S3TimeBK = QiXi_PVE_Info_MissionDetail_TimeBK
    g_UI_Items.S3TimeText = QiXi_PVE_Info_MissionDetail_TimeText
    g_UI_Items.S3Timer = QiXi_PVE_Info_MissionDetail_TimeNum

    g_UI_Items.Points = {}
    for i=1,4 do
        g_UI_Items.Points[i] = {}
        g_UI_Items.Points[i].Arrow = _G["QiXi_PVE_Info_TopProgress_ArrowUp"..i]
    end

end

local function SetMoHuaZhi(value)
    if value and value <= g_MaxMoHuaZhi and value >= 0 then
        g_UI_Items.topProgress:SetProgress(value,g_MaxMoHuaZhi)
        g_UI_Items.topText:SetText(ScriptGlobal_Format("#{QXFB_260529_217}",value))
        for i=1,4 do
            if value < g_PointInfo[i].v then
                g_UI_Items.Points[i].Arrow:SetToolTip(g_PointInfo[i].u)
            else
                g_UI_Items.Points[i].Arrow:SetToolTip(g_PointInfo[i].r)
            end
        end
    end
end

function QiXi_PVE_Info_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_QiXi_PVE_Info_UICommand then
		local opType =  Get_XParam_INT( 0 )
		if opType == g_QiXi_PVE_Info_opType.show then
     

            g_Data.levelInfo = Get_XParam_STR( 0 )
            g_Data.stepName = Get_XParam_STR( 1 )
            g_Data.subInfo = Get_XParam_STR( 2 )
            g_Data.subInfo1 = Get_XParam_STR( 3 )
            g_Data.subInfo2 = Get_XParam_STR( 4 )
            g_Data.levelDesc = Get_XParam_STR( 5 )

            g_Data.curActStage = Get_XParam_INT( 1 )
            g_Data.curMoHuaZhi = Get_XParam_INT( 2 )
            g_Data.stageindex = Get_XParam_INT( 3 )
            g_Data.param1_1 = Get_XParam_INT( 4 )
            g_Data.param1_2 = Get_XParam_INT( 5 )
            g_Data.param2_1 = Get_XParam_INT( 6 )
            g_Data.param2_2 = Get_XParam_INT( 7 )
            g_Data.param3_1 = Get_XParam_INT( 8 )
            g_Data.param3_2 = Get_XParam_INT( 9 )

            local leftSec = Get_XParam_INT( 10 )

            if g_Data.stepName == "E4" then
                g_Data.E4State =  Get_XParam_INT( 11 )
            end
            
			QiXi_PVE_Info_Show()
			QiXi_PVE_Info_InitFrame()
            QiXi_PVE_Info_UpdateTime(leftSec)
        

		elseif opType == g_QiXi_PVE_Info_opType.update then

            g_Data.levelInfo = Get_XParam_STR( 0 )
            g_Data.stepName = Get_XParam_STR( 1 )
            g_Data.subInfo = Get_XParam_STR( 2 )
            g_Data.subInfo1 = Get_XParam_STR( 3 )
            g_Data.subInfo2 = Get_XParam_STR( 4 )
            g_Data.levelDesc = Get_XParam_STR( 5 )

            g_Data.curActStage = Get_XParam_INT( 1 )
            g_Data.curMoHuaZhi = Get_XParam_INT( 2 )
            g_Data.stageindex = Get_XParam_INT( 3 )
            g_Data.param1_1 = Get_XParam_INT( 4 )
            g_Data.param1_2 = Get_XParam_INT( 5 )
            g_Data.param2_1 = Get_XParam_INT( 6 )
            g_Data.param2_2 = Get_XParam_INT( 7 )
            g_Data.param3_1 = Get_XParam_INT( 8 )
            g_Data.param3_2 = Get_XParam_INT( 9 )

            local leftSec = Get_XParam_INT( 10 )

            if g_Data.stepName == "E4" then
                g_Data.E4State =  Get_XParam_INT( 11 )
            end

            QiXi_PVE_Info_CheckUI()
            if (this:IsVisible()) then
                QiXi_PVE_Info_InitFrame()
                QiXi_PVE_Info_UpdateTime(leftSec)
			end
		elseif opType == g_QiXi_PVE_Info_opType.updatemohua then
            g_Data.curMoHuaZhi = Get_XParam_INT( 1 )
            QiXi_PVE_Info_CheckUI()
			if (this:IsVisible()) then
                SetMoHuaZhi(g_Data.curMoHuaZhi)
			end
      

		elseif opType == g_QiXi_PVE_Info_opType.close then
			if (this:IsVisible()) then
				QiXi_PVE_Info_Hide()
			end
		else
			if (this:IsVisible()) then
				QiXi_PVE_Info_Hide()
			end
		end
	-- 游戏窗口尺寸发生了变化
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_QiXi_PVE_Info_UICommand_CorrectTime then
		local opType =  Get_XParam_INT( 0 )
        if opType == g_QiXi_PVE_Info_opType.updateTime then

            local leftSec =  Get_XParam_INT( 1 )
            QiXi_PVE_Info_UpdateTime(leftSec)
        end
	elseif event == "ADJEST_UI_POS" then
		QiXi_PVE_Info_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		QiXi_PVE_Info_On_ResetPos()
	elseif event == "PLAYER_LEAVE_WORLD" then
		QiXi_PVE_Info_Hide()
	end	
end

function QiXi_PVE_Info_CheckUI()
    if( not IsWindowShow("QiXi_PVE_InfoMini"))  and (not this:IsVisible())then
	    PushEvent("OPEN_QiXi_PVE_InfoMini",g_Data.curMoHuaZhi,g_Data.stepName)
	end
end

--显示UI
function QiXi_PVE_Info_Show()

	if(IsWindowShow("QiXi_PVE_InfoMini")) then
		CloseWindow("QiXi_PVE_InfoMini", true)
	end
	this:Show()
	--SetTimer("QiXi_PVE_Info","QiXi_PVE_Info_Timer()", 1000)
end

--隐藏UI
function QiXi_PVE_Info_Hide()
	this:Hide()
end



local function SetLevelInfo()
 
    if g_Data.levelInfo then
        g_UI_Items.levelMissionText:SetText(g_Data.levelInfo)
    end
    local doneformat = "#{QXFB_260529_329}"
    local gongingformat = "#{QXFB_260529_138}"

    for _,v in ipairs(g_UI_Items.levelMissionBK or {}) do
        v:Hide()
    end

  

    if not g_Data.levelDesc or g_Data.levelDesc =="" then
        g_UI_Items.levelDescText:Hide()
    else
        g_UI_Items.levelDescText:SetText(g_Data.levelDesc)
        g_UI_Items.levelDescText:Show()
    end


    if not g_Data.subInfo or g_Data.subInfo == "" then
    else
        g_UI_Items.levelMissionBK[1]:Show()
        g_UI_Items.levelSubMissionText:SetText(g_Data.subInfo)

        local t2 = gongingformat
        if g_Data.param1_1 >= g_Data.param1_2 then
            t2 = doneformat
        end
        g_UI_Items.levelSubMissionTextParam:SetText(ScriptGlobal_Format(t2,g_Data.param1_1,g_Data.param1_2))
    end

    if not g_Data.subInfo1 or g_Data.subInfo1 == "" then
        
    else
        g_UI_Items.levelMissionBK[2]:Show()
        g_UI_Items.levelSubMissionText1:SetText(g_Data.subInfo1)

        local t2 = gongingformat
        if g_Data.param2_1 >= g_Data.param2_2 then
            t2 = doneformat
        end
        g_UI_Items.levelSubMissionTextParam1:SetText(ScriptGlobal_Format(t2,g_Data.param2_1,g_Data.param2_2))
    end

    if not g_Data.subInfo2 or g_Data.subInfo2 == "" then
       
    else
        g_UI_Items.levelMissionBK[3]:Show()
        g_UI_Items.levelSubMissionText2:SetText(g_Data.subInfo2)

        local t2 = gongingformat
        if g_Data.param3_1 >= g_Data.param3_2 then
            t2 = doneformat
        end
        g_UI_Items.levelSubMissionTextParam2:SetText(ScriptGlobal_Format(t2,g_Data.param3_1,g_Data.param3_2))
    end



    if g_Data.stepName == "E4" then
        if g_Data.E4State ~= 1 then
            g_UI_Items.levelMissionText:SetText("#{QXFB_260529_249}")
            g_UI_Items.levelDescText:Show()
            g_UI_Items.levelDescText:SetText("#{QXFB_260529_376}")
        end
    end

    if g_Data.stepName == "E4" or (g_Data.stepName == "S4" and g_Data.curMoHuaZhi == 0) then
        for i=1,4 do
			g_UI_Items.Points[i].Arrow:Hide()
		end
        g_UI_Items.topBK2:Show()
        g_UI_Items.topBK1:Hide()
    else
        for i=1,4 do
			g_UI_Items.Points[i].Arrow:Show()
		end
        g_UI_Items.topBK1:Show()
        g_UI_Items.topBK2:Hide()
    end 

    local curStageStr = string.sub(g_Data.stepName,2,2) 
    if g_StageTitleText[curStageStr] then
        g_UI_Items.StageTitle:SetText(ScriptGlobal_Format("#{QXFB_260529_377}",g_StageTitleText[curStageStr]))
    end
end



function QiXi_PVE_Info_On_ResetPos()
	QiXi_PVE_Info_Frame:SetProperty("UnifiedPosition", g_QiXi_PVE_Info_UnifiedPosition)
end

function QiXi_PVE_Info_InitFrame()
    SetMoHuaZhi(g_Data.curMoHuaZhi)
    SetLevelInfo()
end

function QiXi_PVE_Info_UpdateTime(leftSec)
    for i,v in ipairs(g_UI_Items.levelMissionTimer or {}) do
        if i == g_Data.stageindex and leftSec > 0 then
            v:Show()
            v:SetProperty("Timer", tostring(leftSec))
        else
            v:SetProperty("Timer", "0")
            v:Hide()
        end
    end
    for i,v in ipairs(g_UI_Items.levelMissionPresentBK or {}) do
        if i == g_Data.stageindex and leftSec > 0 then
            v:Show()
        else
            v:Hide()
        end
    end

    if g_Data.stepName=="S3" and leftSec > 0 then
        g_UI_Items.levelMissionBK[3]:Hide()
        g_UI_Items.S3TimeBK:Show()
        g_UI_Items.S3TimeText:SetText("#{QXFB_260529_360}")
        g_UI_Items.S3Timer:SetProperty("Timer", tostring(leftSec))
    else
        g_UI_Items.S3TimeBK:Hide()
        g_UI_Items.S3Timer:SetProperty("Timer", "0")
    end

end


function QiXi_PVE_Info_OnHide()
	
end
function QiXi_PVE_Info_Close()
    PushEvent("OPEN_QiXi_PVE_InfoMini",g_Data.curMoHuaZhi,g_Data.stepName)
	this:Hide()
end
    

function QiXi_PVE_Info_TopHelp_Clicked()
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("UIHelp")
        Set_XSCRIPT_ScriptID(051238)
        Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end