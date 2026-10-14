local g_QiXi_PVE_Stage_UnifiedPosition
local g_QiXi_PVE_Stage_UICommand = 05123807
local g_QiXi_PVE_Stage_opType = {
	show = 1,						
	update = 2,	
    close = 999,				
}

local g_TotalLevelNum = 4

local g_Data = {
    curActStage = 0,
    reachEnding = 0,
    stepName = ""
}
local g_UI_Items = {
}

function QiXi_PVE_Stage_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	--离开场景，自动关闭
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS", false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)		
end


function QiXi_PVE_Stage_OnLoad()
	g_QiXi_PVE_Stage_UnifiedPosition = QiXi_PVE_Stage_Frame:GetProperty("UnifiedPosition")
   
    g_UI_Items.ending1opendBtn  = QiXi_PVE_Stage_Ending1
    g_UI_Items.ending2opendBtn  = QiXi_PVE_Stage_Ending2
    g_UI_Items.ending1LockedBtn  = QiXi_PVE_Stage_LockEnding1
    g_UI_Items.ending2LockedBtn  = QiXi_PVE_Stage_LockEnding2

    g_UI_Items.KeyIcons = {}
    for i=1,g_TotalLevelNum do
        g_UI_Items.KeyIcons[i] = {
            opened = _G["QiXi_PVE_Stage_ClueIconFinished"..i],
            closed = _G["QiXi_PVE_Stage_ClueIcon"..i],
            btgoto =  _G["QiXi_PVE_Stage_ClueGoto"..i],
        }
    end
end


function QiXi_PVE_Stage_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_QiXi_PVE_Stage_UICommand then  
        local opType =  Get_XParam_INT( 0 )
		if opType == g_QiXi_PVE_Stage_opType.show then
            g_Data.curActStage = Get_XParam_INT( 1 )
            g_Data.reachEnding = Get_XParam_INT( 2 )
            g_Data.stepName = Get_XParam_STR( 0 )

            QiXi_PVE_Stage_Show()
            QiXi_PVE_Stage_Init()

        elseif opType == g_QiXi_PVE_Stage_opType.update then
            g_Data.curActStage = Get_XParam_INT( 1 )
            g_Data.reachEnding = Get_XParam_INT( 2 )
            g_Data.stepName = Get_XParam_STR( 0 )

            if (this:IsVisible()) then
                QiXi_PVE_Stage_Init()
			end
        end
	
	elseif event == "ADJEST_UI_POS" then
		QiXi_PVE_Stage_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		QiXi_PVE_Stage_On_ResetPos()
	elseif event == "PLAYER_LEAVE_WORLD" then
		QiXi_PVE_Stage_Hide()
	end	
end


--隐藏UI
function QiXi_PVE_Stage_Hide()
	this:Hide()
end


function QiXi_PVE_Stage_On_ResetPos()
	QiXi_PVE_Stage_Frame:SetProperty("UnifiedPosition", g_QiXi_PVE_Stage_UnifiedPosition)
end



local function SetActStage()

    for i=1,g_TotalLevelNum do
        if i <= g_Data.curActStage then
            g_UI_Items.KeyIcons[i].opened:Show()
            g_UI_Items.KeyIcons[i].closed:Hide()
        else
            g_UI_Items.KeyIcons[i].opened:Hide()
            g_UI_Items.KeyIcons[i].closed:Show()
        end
    end

    -- local curStageStr = string.sub(g_Data.stepName,2,2) 
    -- local curStateStr = string.sub(g_Data.stepName,1,1) 
    -- local curStage = tonumber(curStageStr)
    if g_Data.stepName == "W1" and g_Data.curActStage > 1 then
        g_UI_Items.KeyIcons[1].btgoto:Enable()
    else
        g_UI_Items.KeyIcons[1].btgoto:Disable()
    end

    if g_Data.stepName == "W2" and g_Data.curActStage > 2 then
        g_UI_Items.KeyIcons[2].btgoto:Enable()
    else
        g_UI_Items.KeyIcons[2].btgoto:Disable()
    end

    if g_Data.stepName == "W3" and g_Data.curActStage > 3 then
        g_UI_Items.KeyIcons[3].btgoto:Enable()
    else
        g_UI_Items.KeyIcons[3].btgoto:Disable()
    end

    g_UI_Items.KeyIcons[4].btgoto:Hide()
end


local function SetEndingInfo()
    -- if g_Data.stepName ~= "E4" then
    --     g_UI_Items.ending1opendBtn:Hide()
    --     g_UI_Items.ending2opendBtn:Hide()
    --     g_UI_Items.ending1LockedBtn:Show()
    --     g_UI_Items.ending2LockedBtn:Show()
    --     return
    -- end
    if g_Data.reachEnding == 1 then
        g_UI_Items.ending1opendBtn:Show()
        g_UI_Items.ending2opendBtn:Hide()
        g_UI_Items.ending1LockedBtn:Hide()
        g_UI_Items.ending2LockedBtn:Show()
    elseif g_Data.reachEnding == 2 then
        g_UI_Items.ending1opendBtn:Hide()
        g_UI_Items.ending2opendBtn:Show()
        g_UI_Items.ending1LockedBtn:Show()
        g_UI_Items.ending2LockedBtn:Hide()
    elseif g_Data.reachEnding == 3 then
        g_UI_Items.ending1opendBtn:Show()
        g_UI_Items.ending2opendBtn:Show()
        g_UI_Items.ending1LockedBtn:Hide()
        g_UI_Items.ending2LockedBtn:Hide()
    else
        g_UI_Items.ending1opendBtn:Hide()
        g_UI_Items.ending2opendBtn:Hide()
        g_UI_Items.ending1LockedBtn:Show()
        g_UI_Items.ending2LockedBtn:Show()
    end
end

function QiXi_PVE_Stage_Show()
    if(IsWindowShow("QiXi_PVE_StageMini")) then
		CloseWindow("QiXi_PVE_StageMini", true)
	end
	this:Show()
end


function QiXi_PVE_Stage_Init()
    SetActStage()
    SetEndingInfo()
end

function QiXi_PVE_Stage_Close()
    PushEvent("OPEN_QiXi_PVE_StageMini")
	this:Hide()
end



function QiXi_PVE_Stage_EndingClicked(index)
    if index == 1 or index == 2  then
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("PlayEndingMoive")
        Set_XSCRIPT_ScriptID(051238)
        Set_XSCRIPT_Parameter(0,index)    
        Set_XSCRIPT_ParamCount(1)
        Send_XSCRIPT()
    end
end

function QiXi_PVE_Stage_LockEndingClicked(index)
    PushDebugMessage("未解锁")
end

function QiXi_PVE_Stage_OnHide()
end

function QiXi_PVE_Stage_ClueGoto_Clicked(index)
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("ClientTravelToLevel")
    Set_XSCRIPT_ScriptID(051238)
    Set_XSCRIPT_Parameter(0,index)    
    Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()
end