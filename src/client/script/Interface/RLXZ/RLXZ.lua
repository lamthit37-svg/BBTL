--!!!reloadscript =RLXZ

local g_RLXZ_Frame_UnifiedPosition = ""
local m_ObjServerId = -1
local g_RLXZ_Frame_UICommandIndex = 99955201
local g_PlayerSex = 0
local g_isJianDanActive = 0
local g_JianDanLeftDay = 0
function RLXZ_PreLoad()
    this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED")
    this:RegisterEvent("ADJEST_UI_POS")
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) --进场景关闭界面
end

function RLXZ_OnLoad()
    g_RLXZ_Frame_UnifiedPosition = RLXZ_Frame:GetProperty("UnifiedPosition")
end

function RLXZ_OnEvent(event)
    if (event == "UI_COMMAND" and tonumber(arg0) == g_RLXZ_Frame_UICommandIndex) then
        g_PlayerSex = Get_XParam_INT(0)
        g_isJianDanActive = Get_XParam_INT(1)
        g_JianDanLeftDay = Get_XParam_INT(2)
        RLXZ_Update()
        this:Show()
        return
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        RLXZ_Close()
    end
end

function RLXZ_Update()
    if g_PlayerSex == 0 then
        RLXZ_YZBtn:Show()
        if g_isJianDanActive == 0 then
            RLXZ_YZZT_Tips:SetText("#{RLXZ_241106_7}")
        else
            RLXZ_YZZT_Tips:SetText(ScriptGlobal_Format("#{RLXZ_241106_12}", g_JianDanLeftDay))
        end
    else
        RLXZ_YZZT_Tips:SetText("#{RLXZ_241106_8}")
        RLXZ_YZBtn:Hide()
    end
end

function RLXZ_YZ()
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("BuyJianDan")
    Set_XSCRIPT_ScriptID(999552)
	Set_XSCRIPT_Parameter(0,0)
    Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()
end

function RLXZ_Close() --关闭人脸验证防沉迷界面
    if (IsWindowShow("RLXZ")) then
        CloseWindow("RLXZ", true)
    end

    this:Hide()
end
function RLXZ_OnHidden() --关闭人脸验证防沉迷界面
    if (IsWindowShow("RLXZ")) then
        CloseWindow("RLXZ", true)
    end

    this:Hide()
end
--点击help按钮
function RLXZ_ClickHelp()
	PushEvent("QUEST_HELP_MSG", "#{RLXZ_241106_4}")
end
function RLXZ_CYYZ()
	PushDebugMessage("#{RLXZ_241106_24}")
end