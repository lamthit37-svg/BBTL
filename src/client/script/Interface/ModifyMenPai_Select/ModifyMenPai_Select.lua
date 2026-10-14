
--- 转门派选择框
local g_ModifyMenPai_Select_Frame_UnifiedXPosition;
local g_ModifyMenPai_Select_Frame_UnifiedYPosition;
local g_menpaiId = 9
local g_switch
local g_targetId
local g_select
local MP_SHAOLIN  = 0
local MP_MINGJIAO = 1
local MP_GAIBANG  = 2
local MP_WUDANG   = 3
local MP_EMEI     = 4
local MP_XINGSU   = 5
local MP_DALI     = 6
local MP_TIANSHAN = 7
local MP_XIAOYAO  = 8
local MP_WUMENPAI = 9
local MP_GUSU     = 10
local MP_TANGMEN  = 11 
local MP_GUIGU    = 12 
local MP_TAOHUADAO    = 13  --桃花岛
local MP_HONGMING    = 14 
local MP_ERENGU = 15 
local MP_COUNT    = 16  --用来做判断使用的，最大不能超过这个数，如果需要新增门派，在这个宏之前增加，并修改这个宏的值

local g_maxImagePerPage = 4
local g_currentPage = 1
local g_switchMPList_dingzhimenpai = {
    [MP_SHAOLIN] = {MP_WUDANG, MP_EMEI, MP_DALI, MP_GUSU, MP_TANGMEN,MP_GUIGU,MP_HONGMING},
	[MP_MINGJIAO] = {MP_GAIBANG, MP_DALI, MP_XIAOYAO,MP_GUIGU,MP_HONGMING},
	[MP_GAIBANG] = {MP_MINGJIAO, MP_XINGSU, MP_DALI, MP_XIAOYAO, MP_TANGMEN,MP_GUIGU,MP_TAOHUADAO,MP_HONGMING},
	[MP_WUDANG] = {MP_SHAOLIN, MP_EMEI, MP_DALI, MP_TIANSHAN, MP_GUSU, MP_TANGMEN,MP_GUIGU,MP_TAOHUADAO,MP_HONGMING},
	[MP_EMEI] = {MP_SHAOLIN, MP_WUDANG, MP_DALI, MP_TIANSHAN, MP_GUSU, MP_TANGMEN,MP_GUIGU,MP_TAOHUADAO,MP_HONGMING},
	[MP_XINGSU] = {MP_GAIBANG, MP_DALI, MP_XIAOYAO, MP_TANGMEN,MP_TAOHUADAO},
	[MP_DALI] = {MP_SHAOLIN, MP_MINGJIAO, MP_GAIBANG, MP_WUDANG, MP_EMEI, MP_XINGSU, MP_TIANSHAN, MP_XIAOYAO, MP_GUSU, MP_TANGMEN,MP_GUIGU,MP_TAOHUADAO,MP_HONGMING},
	[MP_TIANSHAN] = {MP_WUDANG, MP_EMEI, MP_DALI,MP_TAOHUADAO},
	[MP_XIAOYAO] = {MP_MINGJIAO, MP_GAIBANG, MP_XINGSU, MP_DALI, MP_TANGMEN,MP_GUIGU,MP_TAOHUADAO,MP_HONGMING},
	[MP_GUSU] = {MP_SHAOLIN, MP_WUDANG, MP_EMEI, MP_DALI, MP_TANGMEN,MP_GUIGU,MP_HONGMING },
	[MP_TANGMEN] = {MP_SHAOLIN, MP_GAIBANG, MP_WUDANG, MP_EMEI, MP_XINGSU, MP_DALI, MP_XIAOYAO, MP_GUSU,MP_GUIGU,MP_TAOHUADAO,MP_HONGMING},
	[MP_GUIGU] = {MP_SHAOLIN, MP_MINGJIAO, MP_GAIBANG, MP_WUDANG, MP_EMEI, MP_DALI, MP_XIAOYAO, MP_GUSU, MP_TANGMEN,MP_HONGMING},
	[MP_TAOHUADAO] = {MP_GAIBANG, MP_WUDANG, MP_EMEI, MP_XINGSU, MP_DALI, MP_TIANSHAN, MP_XIAOYAO, MP_TANGMEN},
    [MP_HONGMING] = {MP_SHAOLIN, MP_MINGJIAO, MP_GAIBANG, MP_WUDANG, MP_EMEI, MP_DALI, MP_XIAOYAO, MP_GUSU, MP_TANGMEN,MP_GUIGU},
    [MP_ERENGU] = {MP_TANGMEN, MP_EMEI, MP_GAIBANG, MP_TIANSHAN, MP_DALI, MP_WUDANG, MP_XINGSU, MP_XIAOYAO,MP_TAOHUADAO},

}
local g_switchMPList = {
    [MP_SHAOLIN] = {MP_WUDANG, MP_EMEI, MP_DALI, MP_GUSU, MP_TANGMEN, MP_GUIGU},
    [MP_MINGJIAO] = {MP_GAIBANG, MP_DALI, MP_XIAOYAO, MP_GUIGU},
    [MP_GAIBANG] = {MP_MINGJIAO, MP_XINGSU, MP_DALI, MP_XIAOYAO, MP_TANGMEN, MP_GUIGU},
    [MP_WUDANG] = {MP_SHAOLIN, MP_EMEI, MP_DALI, MP_TIANSHAN, MP_GUSU, MP_TANGMEN, MP_GUIGU},
    [MP_EMEI] = {MP_SHAOLIN, MP_WUDANG, MP_DALI, MP_TIANSHAN, MP_GUSU, MP_TANGMEN, MP_GUIGU},
    [MP_XINGSU] = {MP_GAIBANG, MP_DALI, MP_XIAOYAO, MP_TANGMEN},
    [MP_DALI] = {MP_SHAOLIN, MP_MINGJIAO, MP_GAIBANG, MP_WUDANG, MP_EMEI, MP_XINGSU, MP_TIANSHAN, MP_XIAOYAO, MP_GUSU, MP_TANGMEN, MP_GUIGU},
    [MP_TIANSHAN] = {MP_WUDANG, MP_EMEI, MP_DALI},
    [MP_XIAOYAO] = {MP_MINGJIAO, MP_GAIBANG, MP_XINGSU, MP_DALI, MP_TANGMEN, MP_GUIGU},
    [MP_GUSU] = {MP_SHAOLIN, MP_WUDANG, MP_EMEI, MP_DALI, MP_TANGMEN, MP_GUIGU},
    [MP_TANGMEN] = {MP_SHAOLIN, MP_GAIBANG, MP_WUDANG, MP_EMEI, MP_XINGSU, MP_DALI, MP_XIAOYAO, MP_GUSU, MP_GUIGU},
    [MP_GUIGU] = {MP_SHAOLIN, MP_MINGJIAO, MP_GAIBANG, MP_WUDANG, MP_EMEI, MP_DALI, MP_XIAOYAO, MP_GUSU, MP_TANGMEN},
    [MP_TAOHUADAO] = {MP_GAIBANG, MP_WUDANG, MP_EMEI, MP_XINGSU, MP_DALI, MP_TIANSHAN, MP_XIAOYAO, MP_TANGMEN},
    [MP_HONGMING] = {MP_SHAOLIN, MP_MINGJIAO, MP_GAIBANG, MP_WUDANG, MP_EMEI, MP_DALI, MP_XIAOYAO, MP_GUSU, MP_TANGMEN,MP_GUIGU},
    [MP_ERENGU] = {MP_TANGMEN, MP_EMEI, MP_GAIBANG, MP_TIANSHAN, MP_DALI, MP_WUDANG, MP_XINGSU, MP_XIAOYAO},
}

local g_switchImage = {
  [MP_SHAOLIN] = "set:ModifyMenPai2 image:Modify_ShaoLin",
  [MP_MINGJIAO] = "set:ModifyMenPai2 image:Modify_MingJiao",
  [MP_GAIBANG] = "set:ModifyMenPai image:Modify_GaiBang",
  [MP_WUDANG] = "set:ModifyMenPai4 image:Modify_WuDang",
  [MP_EMEI] = "set:ModifyMenPai image:Modify_Emei",
  [MP_XINGSU] = "set:ModifyMenPai4 image:Modify_XingXiu",
  [MP_DALI] = "set:ModifyMenPai3 image:Modify_TianLong",
  [MP_TIANSHAN] = "set:ModifyMenPai3 image:Modify_TianShan",
  [MP_XIAOYAO] = "set:ModifyMenPai4 image:Modify_XiaoYao",
  [MP_GUSU] = "set:ModifyMenPai2 image:Modify_MuRong",
  [MP_TANGMEN] = "set:ModifyMenPai3 image:Modify_TangMen",
  [MP_GUIGU] = "set:ModifyMenPai image:Modify_GuiGu",
  [MP_TAOHUADAO] = "set:ModifyMenPai14 image:Modify_TaoHuaDao",
  [MP_HONGMING] = "set:ModifyMenPai14 image:Modify_HongMing",
  [MP_ERENGU] = "set:ModifyMenPai14 image:Modify_ERenGu",
}

local g_select_Button = {}

local g_ModifyMenPai_Flag = 0
local g_ModifyMenPai_FreeSwitch_Flag = 0
function ModifyMenPai_Select_PreLoad()
	this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false) -- 游戏分辨率发生了变化
end

function ModifyMenPai_Select_OnLoad()
    g_ModifyMenPai_Select_Frame_UnifiedXPosition = ModifyMenPai_Select_FrameNULL:GetProperty("UnifiedXPosition");
    g_ModifyMenPai_Select_Frame_UnifiedYPosition = ModifyMenPai_Select_FrameNULL:GetProperty("UnifiedYPosition");
    g_select_Button = {
      [1] = ModifyMenPai_Select_Button1_BK,
      [2] = ModifyMenPai_Select_Button2_BK,
      [3] = ModifyMenPai_Select_Button3_BK,
      [4] = ModifyMenPai_Select_Button4_BK,
    }
end

-- OnEvent
function ModifyMenPai_Select_OnEvent(event)
    if ( event == "UI_COMMAND" and tonumber(arg0) == 2115 ) then
        g_switch = Get_XParam_INT(0)
        if g_switch == 22 then
            g_menpaiId = Get_XParam_INT(1)
            g_targetId = Get_XParam_INT(2)
            g_ModifyMenPai_FreeSwitch_Flag = Get_XParam_INT(3)
            g_ModifyMenPai_Flag = Get_XParam_INT(4) 
            local g_objCared = DataPool : GetNPCIDByServerID(tonumber(g_targetId))
            this:CareObject(g_objCared, 1, "ModifyMenPai_Select");
            if (this:IsVisible()) then  
                return
            end
            
            local tarList = g_switchMPList[g_menpaiId] 
            tarList = ModifyMenPai_Check_DZMP(g_menpaiId) 
            local num = table.getn(tarList)

            for i = 1, g_maxImagePerPage do
                if i <= num then
                   local image = tarList[i]
                   g_select_Button[i]:SetProperty("Image", g_switchImage[image])
                   g_select_Button[i]:Show()
                else
                   g_select_Button[i]:Hide()
                end
            end
            if num <= g_maxImagePerPage then 
                ModifyMenPai_Select_Next:Disable() --下一页不可用
            else
                ModifyMenPai_Select_Next:Enable()
            end
            ModifyMenPai_Select_Pre:Disable() --上一页不可用
            g_currentPage = 1
            g_select = 0
            --ModifyMenPai_Select_Button1_BK:SetProperty("Image", "set:ModifyMenPai image:Modify_Emei")
            ModifyMenPai_Select_Button1:SetCheck(0)
            ModifyMenPai_Select_Button2:SetCheck(0)
            ModifyMenPai_Select_Button3:SetCheck(0)
            ModifyMenPai_Select_Button4:SetCheck(0)--先清一清
            ModifyMenPai_Select_Text:SetText(ScriptGlobal_Format("#{MPZH_180719_95}", num))
            if g_ModifyMenPai_Flag == 1 then 
                if Lua_IsDingZhiMenPaiFoverForbid() == 0  then
                    ModifyMenPai_Select_Text:SetText(ScriptGlobal_Format("#{MPZH_180719_95}", num).."#r".."#{MPZH_200707_05}")
                else
                    ModifyMenPai_Select_Text:SetText(ScriptGlobal_Format("#{MPZH_180719_95}", num).."#r".."#{DZMP_250310_01}")
                end
            end
            this:Show()
        end
        if g_switch == 44 then
            if (this:IsVisible()) then  
                ModifyMenPai_Select_OnClosed()
                return
            end
        end
    elseif (event == "ADJEST_UI_POS" ) then
        ModifyMenPai_Select_ResetPos()
    elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
        -- 恢复默认位置
        ModifyMenPai_Select_ResetPos()
	end

    if ( event == "UI_COMMAND" and tonumber(arg0) == 211599 ) then
        if (this:IsVisible()) then  
            ModifyMenPai_Select_OnClosed()
            return
        end
    end
end

function ModifyMenPai_Select_ResetPos()
    ModifyMenPai_Select_FrameNULL : SetProperty("UnifiedXPosition", g_ModifyMenPai_Select_Frame_UnifiedXPosition);
    ModifyMenPai_Select_FrameNULL : SetProperty("UnifiedYPosition", g_ModifyMenPai_Select_Frame_UnifiedYPosition);
end


function ModifyMenPai_Select_Clear()
    g_currentPage = 1
    g_targetId = 0
    g_menpaiId = 9
    g_switch = 0
    g_maxImagePerPage = 4
    g_select = 0
    SetDefaultMouse()
    ModifyMenPai_Select_Button1:SetCheck(0)
    ModifyMenPai_Select_Button2:SetCheck(0)
    ModifyMenPai_Select_Button3:SetCheck(0)
    ModifyMenPai_Select_Button4:SetCheck(0)
    return
end

function ModifyMenPai_SelectFrame_CloseWindow()
    ModifyMenPai_Select_Clear()
    this:Hide()
    return
end

function ModifyMenPai_Select_Button1_Clicked()
    if g_select == 1 then
        g_select = 0
        return
    end
    g_select = 1
    ModifyMenPai_Select_Button2:SetCheck(0)
    ModifyMenPai_Select_Button3:SetCheck(0)
    ModifyMenPai_Select_Button4:SetCheck(0)
    return
end

function ModifyMenPai_Select_Button2_Clicked()
    if g_select == 2 then
        g_select = 0
        return
    end
    g_select = 2
    ModifyMenPai_Select_Button1:SetCheck(0)
    ModifyMenPai_Select_Button3:SetCheck(0)
    ModifyMenPai_Select_Button4:SetCheck(0)
    return
end

function ModifyMenPai_Select_Button3_Clicked()
    if g_select == 3 then
        g_select = 0
        return
    end
    g_select = 3
    ModifyMenPai_Select_Button1:SetCheck(0)
    ModifyMenPai_Select_Button2:SetCheck(0)
    ModifyMenPai_Select_Button4:SetCheck(0)
    return
end

function ModifyMenPai_Select_Button4_Clicked()
    if g_select == 4 then
        g_select = 0
        return
    end
    g_select = 4
    ModifyMenPai_Select_Button1:SetCheck(0)
    ModifyMenPai_Select_Button2:SetCheck(0)
    ModifyMenPai_Select_Button3:SetCheck(0)
    return
end

function ModifyMenPai_Select_Comfirm(selectId)

    if g_select <= 0 or g_select > 4 then
        SetNotifyTip("#{MPZH_180719_108}")
        return
    end 
    local tarList = g_switchMPList[g_menpaiId]
    tarList = ModifyMenPai_Check_DZMP(g_menpaiId) 
    local index = (g_currentPage - 1) * 4 + g_select
    local tarMPId = tarList[index]
    Clear_XSCRIPT();
	    Set_XSCRIPT_Function_Name("OnContinueCheck");
		Set_XSCRIPT_ScriptID(002115);
        Set_XSCRIPT_Parameter(0, g_targetId);
        Set_XSCRIPT_Parameter(1, tarMPId);
        Set_XSCRIPT_Parameter(2, 1);
        Set_XSCRIPT_Parameter(3, 0);
		Set_XSCRIPT_ParamCount(4);
    Send_XSCRIPT();
    return
end

function ModifyMenPai_Select_OnClosed()
    ModifyMenPai_Select_Clear()
    this:Hide()
end

function ModifyMenPai_Select_Next_Clicked()
    local tarList = g_switchMPList[g_menpaiId]
    tarList = ModifyMenPai_Check_DZMP(g_menpaiId) 
    local num = table.getn(tarList)
    local prePage = g_currentPage
    local currentPage = g_currentPage + 1
    local maxImage = g_maxImagePerPage * currentPage
    if num <= (prePage * g_maxImagePerPage) then 
        return
    end

    if num > (currentPage * g_maxImagePerPage) then --还有下一页
        for i = (prePage * g_maxImagePerPage + 1), maxImage do
            local index = i - (prePage * g_maxImagePerPage)
            local imageIndex = tarList[i]
            g_select_Button[index]:SetProperty("Image", g_switchImage[imageIndex])
        end
        ModifyMenPai_Select_Next:Enable()--下一页可用
    else
        for i = (prePage * g_maxImagePerPage + 1), maxImage do
            if i <= num then
                local index = i - (prePage * g_maxImagePerPage)
                local imageIndex = tarList[i]
                g_select_Button[index]:SetProperty("Image", g_switchImage[imageIndex])
                g_select_Button[index]:Show()
            else
                local index = i - (prePage * g_maxImagePerPage)
                g_select_Button[index]:Hide()
            end
        end
        ModifyMenPai_Select_Next:Disable()--下一页不可用
    end

    ModifyMenPai_Select_Pre:Enable()--上一页可用
    g_currentPage = g_currentPage + 1
    ModifyMenPai_Select_Button1:SetCheck(0)
    ModifyMenPai_Select_Button2:SetCheck(0)
    ModifyMenPai_Select_Button3:SetCheck(0)
    ModifyMenPai_Select_Button4:SetCheck(0)
    g_select = 0
    return
end

function ModifyMenPai_Select_Pre_Clicked()
    if g_currentPage == 1 then
        return
    end
    local tarList = g_switchMPList[g_menpaiId]
    tarList = ModifyMenPai_Check_DZMP(g_menpaiId) 
    local num = table.getn(tarList)
    local prePage = g_currentPage --2
    local currentPage = g_currentPage - 1 --1
    local indexStart = (currentPage - 1) * g_maxImagePerPage + 1
    for i = indexStart, (indexStart - 1 + g_maxImagePerPage) do
        local index = i - ((currentPage - 1) * g_maxImagePerPage)
        local imageIndex = tarList[i]
        g_select_Button[index]:SetProperty("Image", g_switchImage[imageIndex])
        g_select_Button[index]:Show()
    end
    if indexStart == 1 then 
        ModifyMenPai_Select_Pre:Disable()
    end
    ModifyMenPai_Select_Next:Enable()
    g_currentPage = g_currentPage - 1
    ModifyMenPai_Select_Button1:SetCheck(0)
    ModifyMenPai_Select_Button2:SetCheck(0)
    ModifyMenPai_Select_Button3:SetCheck(0)
    ModifyMenPai_Select_Button4:SetCheck(0)
    g_select = 0
    return
end

function ModifyMenPai_Check_DZMP(g_menpaiId) 
    local tarList = g_switchMPList[g_menpaiId] 
    local tarList_can_switch = g_switchMPList_dingzhimenpai[g_menpaiId] 
    local zwid = DataPool:GetSelfZoneWorldID()
	local MenPaiInfo = Lua_GetDingZhiMenPaiSvrInfo(zwid)
	if type(MenPaiInfo) ~= "table" then
		return tarList
    end 
    local cj_tarList = {}
    if Lua_GetDingZhiMenPaiCJFlag() == 1 then 
        for index, value in ipairs(tarList) do
            if Lua_IsCJDingZhiMenPaiOpen(zwid, value) == 1 then
                cj_tarList[table.getn(cj_tarList)+1] = value
            end
        end
        return cj_tarList
    end
    if g_ModifyMenPai_FreeSwitch_Flag == 1 or DataPool:Lua_IsNewServerPlayer() == 1 or g_ModifyMenPai_Flag == 0 or Lua_IsDingZhiMenPaiFoverForbid() == 1 then
		return tarList 
    end

     
    return tarList_can_switch 
end 