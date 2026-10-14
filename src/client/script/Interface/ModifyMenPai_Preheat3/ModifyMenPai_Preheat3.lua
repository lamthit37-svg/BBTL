local adjest_pos
local last_step
local cur_show
local open
local show_step
local pics = {}

local function MMPP3_Text_Refresh()
    ModifyMenPai_Preheat3_ClientPic0Text:SetText("")

    local show = ""
    if show_step == 0 then
        show = "#{ZPRW_180928_246}"
    elseif show_step == 1 then
        show = "#{ZPRW_180928_247}"
    elseif show_step == 2 then
        show = "#{ZPRW_180928_248}"
    elseif show_step == 3 then
        show = "#{ZPRW_180928_249}"
    elseif show_step == 4 then
        show = "#{ZPRW_180928_250}"
    elseif show_step == 5 then
        show = "#{ZPRW_180928_251}"
    elseif show_step == 6 then
        show = "#{ZPRW_180928_252}"
    end

    ModifyMenPai_Preheat3_ClientPic0Text:SetText(show)
end

local function MMPP3_Button_Refresh()
    ModifyMenPai_Preheat3_UpPage:Enable()
    ModifyMenPai_Preheat3_DownPage:Enable()

    if cur_show == 0 then
        ModifyMenPai_Preheat3_UpPage:Disable()
    end

    if cur_show == 3 then
        ModifyMenPai_Preheat3_DownPage:Disable()
    end

    if cur_show >= last_step then
        ModifyMenPai_Preheat3_DownPage:Disable()
    end
end

function ModifyMenPai_Preheat3_OnLoad()
    adjest_pos = ModifyMenPai_Preheat3_Frame:GetProperty("UnifiedPosition")
    pics =
    {
        [0] = ModifyMenPai_Preheat3_ClientPic0,
        [1] = ModifyMenPai_Preheat3_ClientPic1,
        [2] = ModifyMenPai_Preheat3_ClientPic2,
        [3] = ModifyMenPai_Preheat3_ClientPic3,
    }
end

function ModifyMenPai_Preheat3_OnEvent(event)
    local function parse_data()
        open = Get_XParam_INT(0)
        if open == 1 then
            last_step = Get_XParam_INT(1)
            show_step = Get_XParam_INT(2)
            assert(last_step >= 0 and last_step <= 3)
            cur_show = last_step
        end
    end

    if event == "UI_COMMAND" then
        local cmd = tonumber(arg0)
        if cmd == 2018101201 then
            parse_data()

            if open == 0 then
                this:Hide()
                return
            elseif open == 1 then
                MMPP3_Text_Refresh()
                MMPP3_Button_Refresh()
                MMPP3_Init_Show()
            else
                if this:IsVisible() then
                    MMPP3_Text_Refresh()
                end
            end
        end
    end

    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
            event == "VIEW_RESOLUTION_CHANGED" then
            MMPP3_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            MMPP3_Clear()
            this:Hide()
        end
    end
end

function ModifyMenPai_Preheat3_ResetPos()
	ModifyMenPai_Preheat3_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ModifyMenPai_Preheat3_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function ModifyMenPai_Preheat3_Close()
    MMPP3_Clear()
	this:Hide()
end

function MMPP3_Show_Which(which)
    assert(which >= 0 and which <= 3)
    if which < 0 or which > 3 then
        return
    end

    for i = 0, 3 do
        pics[i]:Hide()
    end

    pics[which]:Show()
end

function MMPP3_Init_Show()
    this:Show()
    MMPP3_Show_Which(cur_show)
end

function MMPP3_Refresh()
end

function ModifyMenPai_Preheat3_Left_Clicked()
    local which = cur_show - 1
    if which >= 0 then
        MMPP3_Show_Which(which)
        cur_show = which
    end

    MMPP3_Button_Refresh()
end

function ModifyMenPai_Preheat3_Right_Clicked()
    local which = cur_show + 1
    if cur_show < 4 then
        MMPP3_Show_Which(which)
        cur_show = which
    end

    MMPP3_Button_Refresh()
end

function MMPP3_Clear()
end

function ModifyMenPai_Preheat3_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function MMPP3_ResetPos()
    ModifyMenPai_Preheat3_Frame:SetProperty("UnifiedPosition", adjest_pos)
end

function ModifyMenPai_Preheat3_OnHiden()
    this:Hide()
end

function ModifyMenPai_Preheat3_OnShown()
    MMPP3_Clear()
end

