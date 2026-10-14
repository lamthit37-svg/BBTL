--!!!reloadscript =NewExterior_DressStyle

local EXTERIORFILTTING_TOTALKIND = 6
local g_NewExterior_DressStyle_UnifiedPosition = ""

local g_DressStyle_Name = "DRESSSTYLE"

local g_NeedChangeScrollSize = 1
local g_TargetExteriorIndex = 0        --定位的外观索引，从1开始
local g_TargetExteriorID = 0           --定位的外观ID
local g_CurSelExteriorIndex = 0        --当前选择的外观索引，从1开始
local g_CurSelExteriorID = 0           --当前选择的外观ID，从1开始
local g_CurSelExteriorSubID = 0        --当前选择的外观ID，从1开始

local g_ActionVisualID = 0

local g_Distance = 1
local g_Distance_Ori = 2
local g_Distance_Max = 4
local g_InitList = 0
local g_PlayerfashionDepotType = 1     --仓库类型 1 玩家时装仓库 2 子女时装仓库
local g_MaxBarNum = 300
local g_MaxSubNum = 0
local g_TransFormType = 2
local g_BarList = {}
local g_PlayerFashionInfoList = {}
local g_ActionButtonList = {}
local g_DressColorList = {}
local g_TransformButtonList = {}

local g_PlayerRace = {
    SEX_INVALID	= -1,
    SEX_FEMALE = 0,
    SEX_MALE = 1,
    SEX_NUMBERS = 2,
}

local g_CameraPosition =
{
    --女性相关位置
    [0] = {{fHeight = 0.85, fDistance = 12, fPitch=0.1, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.2, fPitch=0.1, fXOffset= 0 },
            {fHeight = 1.55, fDistance = 2.5, fPitch=0.10, fXOffset= 0 }, {fHeight = 1.55, fDistance = 1.7, fPitch=0.10, fXOffset= 0 }},
    --男性相关位置
    [1] = {{fHeight = 0.85, fDistance = 12, fPitch=0.28, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.5, fPitch=0.28, fXOffset= 0 }, 
            {fHeight = 1.65, fDistance = 2.7, fPitch=0.28, fXOffset= 0 }, {fHeight = 1.70, fDistance = 1.9, fPitch=0.28, fXOffset= 0 }},
}

local g_CameraPosition_IV =
{
    --女性相关位置
    [0] = {{fHeight = 0.85, fDistance = 12, fPitch=0.2, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.2, fPitch=0.2, fXOffset= 0 },
            {fHeight = 1.55, fDistance = 2.5, fPitch=0.10, fXOffset= 0 }, {fHeight = 1.62, fDistance = 1.8, fPitch=0.10, fXOffset= 0 }},
    --男性相关位置
    [1] = {{fHeight = 0.85, fDistance = 12, fPitch=0.28, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.5, fPitch=0.28, fXOffset= 0 }, 
            {fHeight = 1.70, fDistance = 2.7, fPitch=0.05, fXOffset= 0 }, {fHeight = 1.78, fDistance = 1.9, fPitch=0.05, fXOffset= 0 }},
}

local g_SpecialFashionCamera = {
    -- 桃花醉
    [1] = {startid = 10126405, endid = 10126420, fHeight = 1.9, fDistance = 20, fPitch = -1, timecount = 21000},
    -- 千里江山
    [2] = {startid = 10126295, endid = 10126310, fHeight = -1, fDistance = -1, fPitch = -1, timecount = 42000},
    -- 桃花醉-新加了一套
    [3] = {startid = 10126771, endid = 10126773, fHeight = 1.9, fDistance = 20, fPitch = -1, timecount = 21000},
}

local g_sexButtonInfo = {
    [0] = { imgH = "set:DressPreview01 image:DressPreview_Male_Hover", imgN = "set:DressPreview01 image:DressPreview_Male_Normal", imgP = "set:DressPreview01 image:DressPreview_Male_Pushed"  },
    [1] = { imgH = "set:DressPreview01 image:DressPreview_Female_Hover", imgN = "set:DressPreview01 image:DressPreview_Female_Normal", imgP = "set:DressPreview01 image:DressPreview_Female_Pushed"  },
}
--=========
--PreLoad==
--=========
function NewExterior_DressStyle_PreLoad()

    this:RegisterEvent("OPEN_EXTERIOR_DRESSSTYLE")
    this:RegisterEvent("UPDATE_EXTERIOR_FASHION",false)
    
    this:RegisterEvent("ADD_EXTERIOR",false)
    this:RegisterEvent("UPDATE_EXTERIOR",false)
    this:RegisterEvent("EXTERIOR_OUTTIME",false)
    this:RegisterEvent("EXTERIOR_ID_CHANGED",false)
    this:RegisterEvent("EXERIOR_SAVEALL_RET", false)
    
    this:RegisterEvent("ON_SCENE_TRANS",false)
    this:RegisterEvent("ON_SERVER_TRANS",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

    this:RegisterEvent("ADJEST_UI_POS",false)    
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    
    this:RegisterEvent("OPEN_STALL_SALE",false)
    this:RegisterEvent("PROGRESSBAR_SHOW",false)
    this:RegisterEvent("MODELID_CHANGE",false)
    this:RegisterEvent("ORNAMENTS_DISPLAYUPDATE",false)

    this:RegisterEvent("UI_COMMAND",false)
    this:RegisterEvent("UPDATE_EXTERIOR_DRESSSTYLE",false)
end

--=========
--OnLoad
--=========
function NewExterior_DressStyle_OnLoad()
    g_NewExterior_DressStyle_UnifiedPosition = NewExterior_DressStyle_Frame:GetProperty("UnifiedPosition")
    
    g_ActionButtonList = {
        NewExterior_DressStyle_FashionAction_MidBtn1,
        NewExterior_DressStyle_FashionAction_MidBtn2,
        NewExterior_DressStyle_FashionAction_MidBtn3,
        NewExterior_DressStyle_FashionAction_MidBtn4,
        NewExterior_DressStyle_FashionAction_MidBtn5,
    }
    g_DressColorList = {
        color = {
            NewExterior_DressStyle_DressColour10,
            NewExterior_DressStyle_DressColour2,
            NewExterior_DressStyle_DressColour3,
            NewExterior_DressStyle_DressColour4,
            NewExterior_DressStyle_DressColour5,
            NewExterior_DressStyle_DressColour6,
            NewExterior_DressStyle_DressColour7,
            NewExterior_DressStyle_DressColour8,
            NewExterior_DressStyle_DressColour9,
        },
        lock = {
            NewExterior_DressStyle_ButtonTimeLock10,
            NewExterior_DressStyle_ButtonTimeLock2,
            NewExterior_DressStyle_ButtonTimeLock3,
            NewExterior_DressStyle_ButtonTimeLock4,
            NewExterior_DressStyle_ButtonTimeLock5,
            NewExterior_DressStyle_ButtonTimeLock6,
            NewExterior_DressStyle_ButtonTimeLock7,
            NewExterior_DressStyle_ButtonTimeLock8,
            NewExterior_DressStyle_ButtonTimeLock9,
            --NewExterior_DressStyle_ButtonTimeLock10,
        },
    }
    g_TransformButtonList = {
        NewExterior_DressStyle_Transform_MidBtn1,
        NewExterior_DressStyle_Transform_MidBtn2,
        NewExterior_DressStyle_Transform_MidBtn3,
        NewExterior_DressStyle_Transform_MidBtn4,
        NewExterior_DressStyle_Transform_MidBtn5,
    }
end

--=========
--OnEvent
--=========
function NewExterior_DressStyle_OnEvent(event)
    
    if event == "OPEN_EXTERIOR_DRESSSTYLE" then
        if this:IsVisible() then
            if tonumber(arg0) == 0 then
                NewExterior_DressStyle_SavePosition()
                this:Hide()
            end
        else
            -- 关闭一些关联UI
            NewExterior_DressStyle_CloseOtherWindow()
                    
            NewExterior_DressStyle_SetPosition()
            NewExterior_DressStyle_CloseSameGroupWindow()
            this:Show()
            NewExterior_DressStyle_Show()
        end
        return
    end
    
    if event == "EXERIOR_SAVEALL_RET" then
        Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
        Exterior:LuaFnInitCurrentExteriorSet()
        NewExterior_DressStyle_Show()
    end
    
    if ( event == "OPEN_STALL_SALE" ) -- 开始摆摊，还原试穿
        or ( event == "PROGRESSBAR_SHOW" )        -- 读进度条中，还原试穿
        or ( event == "MODELID_CHANGE" ) -- 变身 关闭界面
        then
        NewExterior_DressStyle_CloseClick()    
        return
    end
    
    if event == "ADD_EXTERIOR" or event == "UPDATE_EXTERIOR" or event == "EXTERIOR_OUTTIME" or event == "EXTERIOR_ID_CHANGED" then
        --左侧
        NewExterior_DressStyle_UpdateLeftBtn()
        NewExterior_DressStyle_UpdateRedPoint()
        --模型
        Exterior:LuaFnUpdateExteriorPlayerData()
        Exterior:LuaFnUpdateExteriorPlayerData()
    end
    
    if event == "UPDATE_EXTERIOR_FASHION" then
        if tonumber(arg0) == 1 then
            --init
            --NewExterior_DressStyle_InitList()    
            --列表
            --NewExterior_DressStyle_UpdateList()
            --左侧
            --NewExterior_DressStyle_UpdateLeftBtn()
            --模型
            --NewExterior_DressStyle_UpdateObj()
            NewExterior_DressStyle_Show()
        end
        return
    end

    if event == "ORNAMENTS_DISPLAYUPDATE" then
        -- 刷新模型
        Exterior:LuaFnUpdateExteriorPlayerData()
        return
    end

    -- FakeObject模型界面互斥
    if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
       ( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
        if (this:IsVisible()) then
            NewExterior_DressStyle_CloseClick()
            return
        end
    end

    if ( event == "UI_COMMAND" and tonumber(arg0) == 80081701 ) then
		if this:IsVisible() then
			NewExterior_DressStyle_CloseClick()
            return
		end
	end
    
    if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
        this:Hide()
    end
    
    -- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
    if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
        NewExterior_DressStyle_Frame:SetProperty("UnifiedPosition", g_NewExterior_DressStyle_UnifiedPosition)
    end

end

function NewExterior_DressStyle_InitList()
    DressStyleScript:InitDressStyleInfo()
    if g_InitList == 0 then
        g_MaxBarNum = DressStyleScript:GetDressStyleMax()
        for i=1, g_MaxBarNum do
            local bar = NewExterior_DressStyle_SuperList:AddChild("NewExterior_DressStyle_SuperListItem")
            bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
            g_BarList[i] = bar

            bar:GetSubItem("NewExterior_DressStyle_SuperListItemAction"):SetEvent("MouseLButtonDown", string.format("NewExterior_DressStyle_ItemClicked(%d)", i))
            bar:GetSubItem("NewExterior_DressStyle_SuperListItemAction"):SetEvent("MouseMove", string.format("NewExterior_DressStyle_ItemMouseMove(%d)", i))
            bar:GetSubItem("NewExterior_DressStyle_SuperListItemAction"):SetProperty("Empty", "False")
            bar:GetSubItem("NewExterior_DressStyle_SuperListItemAction"):SetProperty("UseDefaultTooltip", "True")
            bar:GetSubItem("NewExterior_DressStyle_SuperListItemActionTry"):Hide()
            bar:GetSubItem("NewExterior_DressStyle_SuperListItemActionMark"):Hide()
            bar:GetSubItem("NewExterior_DressStyle_SuperListItemActionLuxury"):Hide()
            bar:GetSubItem("NewExterior_DressStyle_SuperListItemActionLock"):Hide()
        end
        g_InitList = 1
    end    
end

function NewExterior_DressStyle_Show()
    
    g_Distance = g_Distance_Ori
    g_NeedChangeScrollSize = 1
    
    NewExterior_DressStyle_InitList()    
    
    NewExterior_DressStyle_CleanUp()
    
    Exterior:LuaFnInitCurrentExteriorSet()
    
    EXTERIORFILTTING_TOTALKIND = Exterior:LuaFnGetExteriorPlayerFittingCount()

    NewExterior_DressStyle_InitExteriorData()
    --列表
    NewExterior_DressStyle_UpdateList()
    --左侧
    NewExterior_DressStyle_UpdateLeftBtn()
    --模型
    NewExterior_DressStyle_UpdateObj()
    --红点
    NewExterior_DressStyle_UpdateRedPoint()
    --选项
    NewExterior_DressStyle_ShowFashionWeaponCheckButton()
    --性别
    NewExterior_DressStyle_GenderUpdate()
    --图鉴页签
    NewExterior_DressStyle_PageButtonUpdate()
end

-- 对一些数据进行初始化
function NewExterior_DressStyle_InitExteriorData()
    g_CurSelExteriorID = 0
    g_CurSelExteriorSubID = 0
    g_CurSelExteriorIndex = -1
    g_TargetExteriorID = 0
    g_TargetExteriorIndex = -1

    local cacheExteriorID,cacheExteriorSubID = Exterior:LuaFnGetCurrentExteriorSetInfo(g_DressStyle_Name)
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        g_CurSelExteriorID = cacheExteriorID
        g_TargetExteriorIndex = DressStyleScript:GetDressStyleIdx(cacheExteriorID) + 1
        g_CurSelExteriorSubID = cacheExteriorSubID
    end
end

--左侧
function NewExterior_DressStyle_UpdateLeftBtn()
    
    NewExterior_DressStyle_CleanUp_LeftButton()
    
    local sex = Exterior:LuaFnGetExteriorRaceID()
    
    local cacheExteriorID,cacheExteriorSubID = Exterior:LuaFnGetCurrentExteriorSetInfo("DRESSSTYLE")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        --图鉴
        local cacheID,dressExteriorID,specialExteriorID = DressStyleScript:GetDressStyleInfo(cacheExteriorID, "ID")
        if cacheID ~= nil then
            -- 获取图标
            local strIcon 	= DataPool:LuaFnGetItemIconByTableIndex(dressExteriorID)
            local strImage = GetIconFullName(strIcon)
            -- 设置action
            NewExterior_DressStyle_Dress_LeftBtn:SetActionItem(-1)
            NewExterior_DressStyle_Dress_LeftBtn:SetProperty("Empty", "False")
            NewExterior_DressStyle_Dress_LeftBtn:SetProperty("NormalImage", strImage)
            NewExterior_DressStyle_Dress_LeftBtn:SetProperty("HoverImage", strImage)
            NewExterior_DressStyle_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "True")
            -- 文字tips
            local strToolTip = DressStyleScript:GetDressStyleToolTips(cacheExteriorID, cacheExteriorSubID)
            NewExterior_DressStyle_Dress_LeftBtn:SetToolTip(strToolTip)
            -- 试穿
            NewExterior_DressStyle_Dress_ActionImg:Show()

            local actionVisualID = FashionActionUI:GetFashionEquipVisual(dressExteriorID)
            local ActionNum = FashionActionUI:GetFashionActionActionNum(dressExteriorID, actionVisualID)
            for i=1, ActionNum do
                g_ActionButtonList[i]:Show()
            end
            if specialExteriorID == g_TransFormType then
                local tipslist = {"","","","",""}
                local nTranformDressCount = 0
                nTranformDressCount, tipslist[1], tipslist[2], tipslist[3], tipslist[4], tipslist[5] = Exterior:LuaFnGetDressTransformTips(dressExteriorID)
                if nTranformDressCount > 0 and nTranformDressCount < table.getn(g_TransformButtonList) then
                    for i = 1, nTranformDressCount do
                        g_TransformButtonList[i]:Show()
                        if tipslist[i] ~= "" then
                            local strtips = ScriptGlobal_Format("#{QXWG_230427_03}", tipslist[i])
                            g_TransformButtonList[i]:SetToolTip(strtips)
                        end
                    end
                end
            end
        end
    else
        --时装
        cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
        if cacheExteriorID ~= nil and cacheExteriorID > 0 then
            local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(g_PlayerfashionDepotType, cacheExteriorIdx)
            --local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, cacheExteriorID, 0)
            if theAction:GetID() ~= 0 then
                NewExterior_DressStyle_Dress_LeftBtn:SetActionItem(theAction:GetID())
                NewExterior_DressStyle_Dress_ActionImg:Show()
                
                local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
                if nCurFashionId ~= nil and nCurFashionId > 0 then
                    if nCurFashionIdx == cacheExteriorIdx then
                        NewExterior_DressStyle_Dress_ActionImg:Hide()
                    end
                end
            end
        else
            local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
            if nCurFashionId ~= nil and nCurFashionId > 0 then
                local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(g_PlayerfashionDepotType, nCurFashionIdx)
                --local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, nCurFashionId, 0)
                if theAction:GetID() ~= 0 then
                    NewExterior_DressStyle_Dress_LeftBtn:SetActionItem(theAction:GetID())
                end
            end
        end
    end
    
    --坐骑
    local edType = 0    
    cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("RIDE")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Name")
        local strIcon = Exterior:LuaFnGetExteriorRideInfo(cacheExteriorID, "Icon")
        local strImage = GetIconFullName(strIcon)
        
        NewExterior_DressStyle_Ride_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_DressStyle_Ride_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
        NewExterior_DressStyle_Ride_LeftBtn:SetToolTip(strTemp)
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_DressStyle_Ride_ActionImg:Show()
        end
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
            NewExterior_DressStyle_Ride_LockImg:Show()
        end
    end
    
    --幻武
    edType = 1
    cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName     = Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Name")
        local strIcon     = Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Icon")
        local strImage = GetIconFullName(strIcon)
        
        NewExterior_DressStyle_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_DressStyle_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
        NewExterior_DressStyle_Weapon_LeftBtn:SetToolTip(strTemp)
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_DressStyle_Weapon_ActionImg:Show()
        end
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
            NewExterior_DressStyle_Weapon_LockImg:Show()
        end
    end
    
    --附体
    edType = 2
    local cacheVisualIndex = 0
    cacheExteriorID, cacheVisualIndex, _ = Exterior:LuaFnGetCurrentExteriorSetInfo("FUTI")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName     = Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "Name")
        local strImage     = Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "VisualIcon", cacheVisualIndex)
        NewExterior_DressStyle_PetPossJian_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_DressStyle_PetPossJian_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
        NewExterior_DressStyle_PetPossJian_LeftBtn:SetToolTip(strTemp)
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_DressStyle_PetPossJian_ActionImg:Show()
        else
            if Exterior:LuaFnGetExteriorFutiVisualIndex() ~= cacheVisualIndex then
                NewExterior_DressStyle_PetPossJian_ActionImg:Show()
            end
        end
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 or Exterior:LuaFnIsExteriorFutiVisualUnlocked(cacheExteriorID, cacheVisualIndex) ~= 1 then
            NewExterior_DressStyle_PetPossJian_LockImg:Show()
        end
    end
    
    --脸型
    edType = 3
    cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FACE")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName     = Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Name", sex)
        local strIcon     = Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Icon", sex)
        local strImage = GetIconFullName(strIcon)        
        NewExterior_DressStyle_FaceStyle_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_DressStyle_FaceStyle_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_82}", strName)
        NewExterior_DressStyle_FaceStyle_LeftBtn:SetToolTip(strTemp)
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_DressStyle_FaceStyle_ActionImg:Show()
        end
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
            NewExterior_DressStyle_FaceStyle_LockImg:Show()
        end
    end
    
    --发型
    edType = 4
    cacheExteriorID, cacheColorIndex = Exterior:LuaFnGetCurrentExteriorSetInfo("HAIR")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName = Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Name", sex)
        local strIcon = Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Icon", sex)
        local strImage = GetIconFullName(strIcon)        
        NewExterior_DressStyle_HairStyle_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_DressStyle_HairStyle_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_81}", strName)
        NewExterior_DressStyle_HairStyle_LeftBtn:SetToolTip(strTemp)
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_DressStyle_HairStyle_ActionImg:Show()
        else
            if Exterior:LuaFnGetExteriorHairColorIndex() ~= cacheColorIndex then
                NewExterior_DressStyle_HairStyle_ActionImg:Show()
            end
        end
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
            NewExterior_DressStyle_HairStyle_LockImg:Show()
        end
    end
    
    --头像
    edType = 5
    local strHeadTip = ""
    cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("PORTRAIT")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName = Exterior:LuaFnGetExteriorPortraitInfo(cacheExteriorID, "Name", sex)
        local strIcon = Exterior:LuaFnGetExteriorPortraitInfo(cacheExteriorID, "Icon", sex)
        local strImage = GetIconFullName(strIcon)        
        NewExterior_DressStyle_PlayerFrame_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_DressStyle_PlayerFrame_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_79}", strName)
        strHeadTip = strTemp
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_DressStyle_PlayerFrame_ActionImg:Show()
        end
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
            NewExterior_DressStyle_PlayerFrame_LockImg:Show()
        end        
    end
    
    --头像框
    edType = 6
    cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FRAME")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Name")
        local iFrameType = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Type")
        if iFrameType == 1 then
            NewExterior_DressStyle_PlayerFrame_Mask:Hide()
            NewExterior_DressStyle_PlayerFrame_Mask_Animate:Show()
            
            local strFrameAnimate = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameAnimate")
            NewExterior_DressStyle_PlayerFrame_Mask_Animate:SetProperty("Animate", strFrameAnimate)
        else
            NewExterior_DressStyle_PlayerFrame_Mask:Show()
            NewExterior_DressStyle_PlayerFrame_Mask_Animate:Hide()
            
            local strIcon = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameIcon")
            local strImage = GetIconFullName(strIcon)
            NewExterior_DressStyle_PlayerFrame_Mask:SetProperty("Image", strImage)
        end

        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_85}", strName)
        NewExterior_DressStyle_PlayerFrame_LeftBtn:SetToolTip(strHeadTip.."#r"..strTemp)
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_DressStyle_PlayerFrame_ActionImg:Show()
        end    
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
            NewExterior_DressStyle_PlayerFrame_LockImg:Show()
        end    
    end
    
    local edOrnamentsType, cacheExteriorX, cacheExteriorY, cacheExteriorZ = 0, 0, 0, 0
    cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsBack")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
        local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
        local strImage = GetIconFullName(strIcon)
        
        NewExterior_DressStyle_Widget_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_DressStyle_Widget_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
        NewExterior_DressStyle_Widget_LeftBtn:SetToolTip(strTemp)
        --试穿
        if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
            NewExterior_DressStyle_Widget_ActionImg:Show()
        end
        --未激活
        local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
        if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
            NewExterior_DressStyle_Widget_LockImg:Show()
        end
    end

    edOrnamentsType= 1
    cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsHead")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
        local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
        local strImage = GetIconFullName(strIcon)
        
        NewExterior_DressStyle_Headdress_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_DressStyle_Headdress_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
        NewExterior_DressStyle_Headdress_LeftBtn:SetToolTip(strTemp)
        --试穿
        if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
            NewExterior_DressStyle_Headdress_ActionImg:Show()
        end
        --未激活
        local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
        if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
            NewExterior_DressStyle_Headdress_LockImg:Show()
        end
    end
end

--模型
function NewExterior_DressStyle_UpdateObj()
    
    local cacheExteriorID, cacheExteriorSubID = Exterior:LuaFnGetCurrentExteriorSetInfo(g_DressStyle_Name)
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        NewExterior_DressStyle_FakeObject:DetachWindowEx()
        NewExterior_DressStyle_FakeObject:AttachWindowEx("Exterior_Player")
        Exterior:LuaFnUpdateExteriorPlayerData()
        --Exterior:LuaFnUpdateExteriorAvatarFashion(cacheExteriorID, cacheExteriorIdx)    
    else
        NewExterior_DressStyle_FakeObject:DetachWindowEx()
        NewExterior_DressStyle_FakeObject:AttachWindowEx("Exterior_Player")
        Exterior:LuaFnUpdateExteriorPlayerData()
    end

    NewExterior_DressStyle_ActionEnd()
    
    NewExterior_DressStyle_UpdateCamera()
    
end

--列表
function NewExterior_DressStyle_UpdateList()

    -- 显示
    for i=1, g_MaxBarNum do 
        NewExterior_DressStyle_SetItem(i)
    end
    
    if g_NeedChangeScrollSize == 1 then
        NewExterior_DressStyle_SuperList:RefreshLayout()
        g_NeedChangeScrollSize = 0
    end

    if g_TargetExteriorIndex ~= 0 then
        NewExterior_DressStyle_SuperList:SetScrollPosition4Index(g_TargetExteriorIndex - 1)
        g_TargetExteriorID = 0
        g_TargetExteriorIndex = 0
    else
        NewExterior_DressStyle_SuperList:SetScrollPosition4Index(0)
    end

    NewExterior_DressStyle_UpdateColor()
end

function NewExterior_DressStyle_SetItem(index)
    local bar = g_BarList[index]
    if bar == nil then
        return
    end

    local bar = g_BarList[index]
    bar:Show()

    local ctrlAction = bar:GetSubItem("NewExterior_DressStyle_SuperListItemAction")
    if ctrlAction ~= nil then
        local cacheExteriorID,dressExteriorID,specialExteriorID = DressStyleScript:GetDressStyleInfoByIdx(index-1, "ID")
        if cacheExteriorID ~= nil then
            -- 图标
            local strIcon 	= DataPool:LuaFnGetItemIconByTableIndex(dressExteriorID)
            local strImage = GetIconFullName(strIcon)
            ctrlAction:SetProperty("NormalImage", strImage)
            ctrlAction:SetProperty("HoverImage", strImage)
            -- Tips
            local strToolTip = DressStyleScript:GetDressStyleToolTips(cacheExteriorID, 0)
            ctrlAction:SetToolTip(strToolTip)
            -- 选中状态
            if cacheExteriorID == g_CurSelExteriorID then
                ctrlAction:SetPushed(1)
            else
                ctrlAction:SetPushed(0)
            end
            -- 试穿
            local tryUI = bar:GetSubItem("NewExterior_DressStyle_SuperListItemActionTry")
            if tryUI ~= nil then
                if cacheExteriorID == g_CurSelExteriorID then
                    tryUI:Show()
                else
                    tryUI:Hide()
                end
            end
            -- 蒙红
            local markUI = bar:GetSubItem("NewExterior_DressStyle_SuperListItemActionMark")
            if markUI ~= nil then
                local playerMP = Player:GetData("MEMPAI")
                local limitMP = Lua_GetMenpaiLimitFlag(dressExteriorID)
                if limitMP ~= -1 and playerMP ~= limitMP then
                    markUI:Show()
                else
                    markUI:Hide()
                end
            end
            -- 品质框
            local luxuryUI = bar:GetSubItem("NewExterior_DressStyle_SuperListItemActionLuxury")
            if luxuryUI ~= nil then
                local quality = DressStyleScript:GetDressStyleInfo(cacheExteriorID, "Quality")
                if quality > 0 then
                    luxuryUI:Show()
                else
                    luxuryUI:Hide()
                end
            end
            -- 是否获得
            local lockUI = bar:GetSubItem("NewExterior_DressStyle_SuperListItemActionLock")
            if lockUI ~= nil then
                local active = DressStyleScript:GetDressStyleActiveInfo(cacheExteriorID, -1, "Active")
                if active > 0 then
                    lockUI:Hide()
                else
                    lockUI:Show()
                end
            end
        end
    end
end

--时装动作
function NewExterior_DressStyle_onAction(nIndex)
    if not nIndex then 
        return
    end
    
    local cacheExteriorID, cacheExteriorSubID = Exterior:LuaFnGetCurrentExteriorSetInfo(g_DressStyle_Name)
    if cacheExteriorID == nil or cacheExteriorID <= 0 then
        return
    end
    
    local cacheID,dressExteriorID,specialExteriorID = DressStyleScript:GetDressStyleInfo(cacheExteriorID, "ID")
    if cacheID == nil or cacheID <= 0 then
        return
    end

    for i = 1, table.getn(g_SpecialFashionCamera) do
        if dressExteriorID >= g_SpecialFashionCamera[i].startid and dressExteriorID <= g_SpecialFashionCamera[i].endid then
            local fHeight, fDistance, fPitch = NewExterior_DressStyle_FakeObject:GetCameraEx()
            if g_SpecialFashionCamera[i].fDistance ~= -1 then
                fDistance = g_SpecialFashionCamera[i].fDistance
            end
            if g_SpecialFashionCamera[i].fHeight ~= -1 then
                fHeight = g_SpecialFashionCamera[i].fHeight
            end
            if g_SpecialFashionCamera[i].fPitch ~= -1 then
                fPitch = g_SpecialFashionCamera[i].fPitch
            end
            NewExterior_DressStyle_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)
            NewExterior_DressStyle_Model_Plus:Disable()
            NewExterior_DressStyle_Model_Subtract:Disable()
            NewExterior_DressStyle_Model_TurnLeft:Disable()
            NewExterior_DressStyle_Model_TurnRight:Disable()
            NewExterior_DressStyle_GenderChange_Btn:Disable()

            SetTimer("NewExterior_DressStyle","NewExterior_DressStyle_ActionEnd()", g_SpecialFashionCamera[i].timecount)
        end        
    end
    
    Exterior:LuaFnExteriorAvatarPlayAction(4, cacheExteriorID, nIndex-1)
end

function NewExterior_DressStyle_ActionEnd()
    KillTimer("NewExterior_DressStyle_ActionEnd()");
    
    NewExterior_DressStyle_Model_Plus:Enable()
    NewExterior_DressStyle_Model_Subtract:Enable()
    NewExterior_DressStyle_Model_TurnLeft:Enable()
    NewExterior_DressStyle_Model_TurnRight:Enable()
    NewExterior_DressStyle_GenderChange_Btn:Enable()

    NewExterior_DressStyle_UpdateCamera()
end

function NewExterior_DressStyle_ItemClicked(nIndex)
    local cacheExteriorID,dressExteriorID,specialExteriorID = DressStyleScript:GetDressStyleInfoByIdx(nIndex-1, "ID")
    if g_CurSelExteriorID ~= cacheExteriorID then
        -- 进行内容选中
        g_CurSelExteriorID = cacheExteriorID
        g_CurSelExteriorSubID = 0
        g_CurSelExteriorIndex = nIndex
        -- 进行赋值处理
        Exterior:LuaFnSetCurrentExteriorSetInfo(g_DressStyle_Name, g_CurSelExteriorID, g_CurSelExteriorSubID)
        -- 对现有时装进行还原
        local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
        if nCurFashionId ~= nil and nCurFashionId > 0 then
            Exterior:LuaFnSetCurrentExteriorSetInfo("FASHION", nCurFashionId, nCurFashionIdx)
        else
            Exterior:LuaFnSetCurrentExteriorSetInfo("FASHION", 0, -1)
        end
        -- 动作按钮隐藏
        NewExterior_DressStyle_UpdateActionBtn(-1)
        -- 设置选中状态
        NewExterior_DressStyle_SetItemSelected(nIndex)
        -- 刷新染色信息
        NewExterior_DressStyle_UpdateColor()
        -- 刷新模型
        NewExterior_DressStyle_UpdateLeftBtn()
        -- 模型
        NewExterior_DressStyle_UpdateObj()
    else
        g_CurSelExteriorID = 0
        g_CurSelExteriorSubID = 0
        g_CurSelExteriorIndex = 0
        Exterior:LuaFnSetCurrentExteriorSetInfo(g_DressStyle_Name, g_CurSelExteriorID, g_CurSelExteriorSubID)
        -- 动作按钮隐藏
        NewExterior_DressStyle_UpdateActionBtn(-1)
        -- 设置选中状态
        NewExterior_DressStyle_SetItemSelected(-1)
        -- 刷新染色信息
        NewExterior_DressStyle_UpdateColor()
        -- 刷新模型
        NewExterior_DressStyle_UpdateLeftBtn()
        -- 模型
        NewExterior_DressStyle_UpdateObj()
    end

    NewExterior_DressStyle_CloseTuJing()
end

function NewExterior_DressStyle_SubItemClicked(nSubIndex)
    if g_CurSelExteriorID > 0 then
        -- 进行内容选中
        g_CurSelExteriorSubID = nSubIndex
        -- 进行赋值处理
        Exterior:LuaFnSetCurrentExteriorSetInfo(g_DressStyle_Name, g_CurSelExteriorID, g_CurSelExteriorSubID)
        -- 选中框进行处理
        NewExterior_DressStyle_SetItem(g_CurSelExteriorIndex)
        -- 刷新染色信息
        NewExterior_DressStyle_UpdateColor()
        -- 刷新模型
        NewExterior_DressStyle_UpdateLeftBtn()
        -- 模型
        NewExterior_DressStyle_UpdateObj()
    else

    end
    NewExterior_DressStyle_CloseTuJing()
end

function NewExterior_DressStyle_ItemMouseMove(nIndex)
end

function NewExterior_DressStyle_SetItemSelected(nIndex)
    for i = 1, g_MaxBarNum do        
        if g_BarList[i] ~= nil then    
            local ctrlAction = g_BarList[i]:GetSubItem("NewExterior_DressStyle_SuperListItemAction")
            if ctrlAction ~= nil then
                if i == nIndex then
                    ctrlAction:SetPushed(1)
                    g_BarList[i]:GetSubItem("NewExterior_DressStyle_SuperListItemActionTry"):Show()
                else
                    ctrlAction:SetPushed(0)    
                    g_BarList[i]:GetSubItem("NewExterior_DressStyle_SuperListItemActionTry"):Hide()
                end
            end
        end
    end
end

function NewExterior_DressStyle_CloseClick()    
    Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
        
    NewExterior_DressStyle_SavePosition()
    this:Hide()
end

function NewExterior_DressStyle_OnHidden()
    
    if IsWindowShow("NewExterior_Ride") 
        or IsWindowShow("NewExterior_Weapon")  
        or IsWindowShow("NewExterior_PetPossJian")
        or IsWindowShow("NewExterior_Facestyle") 
        or IsWindowShow("NewExterior_HairStyle") 
        or IsWindowShow("NewExterior_PlayerFrame") 
        or IsWindowShow("NewExterior_Widget") 
        or IsWindowShow("NewExterior_Headdress")
        or IsWindowShow("NewExterior_DressBox")
		or IsWindowShow("NewExterior_GemEffect")
        then
    else    
        Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
    end    
    
    NewExterior_DressStyle_CleanUp()
	
	if IsWindowShow("NewExterior_PlanSetting") then
		CloseWindow("NewExterior_PlanSetting", true)
	end
	
	NewExterior_DressStyle_CloseTuJing()
end
    
function NewExterior_DressStyle_CleanUp_LeftButton()

    NewExterior_DressStyle_Dress_LeftBtn:SetActionItem(-1)
    NewExterior_DressStyle_Dress_LeftBtn:SetProperty("NormalImage", "")
    NewExterior_DressStyle_Dress_LeftBtn:SetProperty("HoverImage", "")
    NewExterior_DressStyle_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "False")
    NewExterior_DressStyle_Dress_LeftBtn:SetProperty("Empty", "True")

    local ctrl_list = {
        [1] = NewExterior_DressStyle_Weapon_LeftBtn,
        [2] = NewExterior_DressStyle_PetPossJian_LeftBtn,
        [3] = NewExterior_DressStyle_FaceStyle_LeftBtn,
        [4] = NewExterior_DressStyle_HairStyle_LeftBtn,
        [5] = NewExterior_DressStyle_PlayerFrame_LeftBtn,
        [6] = NewExterior_DressStyle_Ride_LeftBtn,
        [7] = NewExterior_DressStyle_Widget_LeftBtn,
        [8] = NewExterior_DressStyle_Headdress_LeftBtn,
    }
    
    for i = 1 ,8 do
        ctrl_list[i]:SetProperty("Empty", "False")
        ctrl_list[i]:SetProperty("UseDefaultTooltip", "True")
        ctrl_list[i]:SetProperty("NormalImage", "")
        ctrl_list[i]:SetProperty("HoverImage", "")
        ctrl_list[i]:SetToolTip("")
    end

    NewExterior_DressStyle_PlayerFrame_Mask:SetProperty("Image", "")
    NewExterior_DressStyle_PlayerFrame_Mask_Animate:SetProperty("Animate", "")

    NewExterior_DressStyle_Dress_ActionImg:Hide()
    NewExterior_DressStyle_Weapon_ActionImg:Hide()
    NewExterior_DressStyle_PetPossJian_ActionImg:Hide()
    NewExterior_DressStyle_FaceStyle_ActionImg:Hide()
    NewExterior_DressStyle_HairStyle_ActionImg:Hide()
    NewExterior_DressStyle_PlayerFrame_ActionImg:Hide()
    NewExterior_DressStyle_Ride_ActionImg:Hide()    
    NewExterior_DressStyle_Widget_ActionImg:Hide()
    NewExterior_DressStyle_Headdress_ActionImg:Hide()

    NewExterior_DressStyle_Dress_LockImg:Hide()
    NewExterior_DressStyle_Weapon_LockImg:Hide()
    NewExterior_DressStyle_PetPossJian_LockImg:Hide()
    NewExterior_DressStyle_FaceStyle_LockImg:Hide()
    NewExterior_DressStyle_HairStyle_LockImg:Hide()
    NewExterior_DressStyle_PlayerFrame_LockImg:Hide()
    NewExterior_DressStyle_Ride_LockImg:Hide()
    NewExterior_DressStyle_Widget_LockImg:Hide()
    NewExterior_DressStyle_Headdress_LockImg:Hide()

    NewExterior_DressStyle_UpdateActionBtn(-1)
end

function NewExterior_DressStyle_CleanUp()
    for i = 1, g_MaxBarNum do
        if g_BarList[i] then
            local ctrlAction = g_BarList[i]:GetSubItem("NewExterior_DressStyle_SuperListItemAction")            
            if ctrlAction then
                ctrlAction:SetProperty("NormalImage", "")
                ctrlAction:SetProperty("HoverImage", "")
                ctrlAction:SetToolTip("")
            end
        end
    end
    NewExterior_DressStyle_FakeObject:DetachWindowEx()
    
    NewExterior_DressStyle_CleanUp_LeftButton()
end

--左转
function NewExterior_DressStyle_FakeObject_TurnLeft(idx)
    
    if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
        NewExterior_DressStyle_FakeObject:RotateBeginEx("Exterior_Player", -0.3)
    else
        NewExterior_DressStyle_FakeObject:RotateEndEx()
    end
    
end

--右转
function NewExterior_DressStyle_FakeObject_TurnRight(idx)
    
    if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
        NewExterior_DressStyle_FakeObject:RotateBeginEx("Exterior_Player", 0.3)
    else
        NewExterior_DressStyle_FakeObject:RotateEndEx()
    end
    
end

--缩小
function NewExterior_DressStyle_ZoomOut()

    if g_Distance == 1 then
        return
    end
    
    g_Distance = g_Distance - 1    

    NewExterior_DressStyle_UpdateCamera()
    
end

--放大
function NewExterior_DressStyle_ZoomIn()

    if g_Distance == g_Distance_Max then
        return
    end
    
    g_Distance = g_Distance + 1    
    
    NewExterior_DressStyle_UpdateCamera()
    
end

function NewExterior_DressStyle_UpdateCamera()

    local sex = Exterior:LuaFnGetExteriorRaceID()
    if sex ~= 0 and sex ~= 1 then 
        return
    end
        
    if g_Distance < 1 or g_Distance > g_Distance_Max then
        return
    end
    
    local isIVMode = LuaFnGetCurModelState()
    local cameraInfo = g_CameraPosition
    if isIVMode == 1 then
        cameraInfo = g_CameraPosition_IV
    end
    
    local fHeight, fDistance, fPitch = NewExterior_DressStyle_FakeObject:GetCameraEx()
    fHeight = cameraInfo[sex][g_Distance].fHeight
    fDistance = cameraInfo[sex][g_Distance].fDistance
    fPitch = cameraInfo[sex][g_Distance].fPitch
    fXOffset = cameraInfo[sex][g_Distance].fXOffset
    NewExterior_DressStyle_FakeObject:SetCameraEx(fHeight, fDistance, fPitch, fXOffset)
    
end

--卸下时装 
function NewExterior_DressStyle_ActionToDressBox()
    local isShow = 0
    local cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        cacheExteriorID = 0
        cacheExteriorIdx = -1
        Exterior:LuaFnSetCurrentExteriorSetInfo("FASHION", cacheExteriorID, cacheExteriorIdx)            
        isShow = 1
        --return
    end
    local cacheID,cacheSubID = Exterior:LuaFnGetCurrentExteriorSetInfo("DRESSSTYLE")
    if cacheID ~= nil and cacheID > 0 then
        Exterior:LuaFnSetCurrentExteriorSetInfo("DRESSSTYLE", 0, 0)
        isShow = 1
    end

    if isShow > 0 then
        for i=1, 3 do
            Exterior:LuaFnSetCurrentExteriorSetInfo("GEMEFFECT", i-1, 0, 0)
        end
        NewExterior_DressStyle_Show()
    end
    Exterior:LuaFnUnUseExteriorFashion(g_PlayerfashionDepotType)
end

--保存
function NewExterior_DressStyle_DressChange_Save()

    if Exterior:LuaFnIsHaveExteriorChange() == 0 then
        if Exterior:LuaFnIsHaveDressStyleChange() == 1 then
            local selfSex = GetMySelfRaceId()
            Exterior:LuaFnSetCurrentExteriorSetInfo("RESETDRESSSTYLE")
            Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", selfSex)
            Exterior:LuaFnInitCurrentExteriorSet()
            NewExterior_DressStyle_Show()
        else
            PushDebugMessage("#{WGJM_210104_02}")
        end
        return
    end
        
    Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
    Exterior:LuaFnSaveExteriorAllChange(1)
end

--还原
function NewExterior_DressStyle_Undo()

    if Exterior:LuaFnIsHaveExteriorChange() == 0 and Exterior:LuaFnIsHaveDressStyleChange() == 0 then
        PushDebugMessage("#{WGJM_210104_01}")
        return
    end    
    
    Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
    Exterior:LuaFnInitCurrentExteriorSet()
    NewExterior_DressStyle_Show()
    
end

--整理
function NewExterior_DressStyle_ClickClearUpBtn()

end

--打开展示柜
function NewExterior_DressStyle_OpenYiRongGe()
    NewExterior_DressStyle_SavePosition()
    Exterior:LuaFnAskExteriorYiRongGeInfo(1, 2)
end

--切换子女时装
function NewExterior_DressStyle_OpenInfant()    
    NewExterior_DressStyle_SavePosition()
    Exterior:LuaFnInitExteriorFashionList(2, 1)
end

--时装
function NewExterior_DressStyle_OpenFashion()
    local cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
    Exterior:LuaFnExteriorFashionDepotItemClick(g_PlayerfashionDepotType, cacheExteriorIdx)
    --NewExterior_DressStyle_SavePosition()
    --PushEvent("OPEN_EXTERIOR_FASHION", 1, 0)
end

--幻武
function NewExterior_DressStyle_OpenWeapon()
    NewExterior_DressStyle_SavePosition()
    Exterior:LuaFnAskOpenExterior(1)
end

--附体
function NewExterior_DressStyle_OpenFuti()
    NewExterior_DressStyle_SavePosition()
    Exterior:LuaFnAskOpenExterior(2)
end

--坐骑
function NewExterior_DressStyle_OpenRide()
    NewExterior_DressStyle_SavePosition()
    Exterior:LuaFnAskOpenExterior(0)
end

--发型
function NewExterior_DressStyle_OpenHair()
    NewExterior_DressStyle_SavePosition()    
    Exterior:LuaFnAskOpenExterior(4)
end

--脸型
function NewExterior_DressStyle_OpenFace()
    NewExterior_DressStyle_SavePosition()    
    Exterior:LuaFnAskOpenExterior(3)
end

--头像
function NewExterior_DressStyle_OpenPortrait()
    NewExterior_DressStyle_SavePosition()    
    Exterior:LuaFnAskOpenExterior(5)
end

--头像框
function NewExterior_DressStyle_OpenFrame()
    NewExterior_DressStyle_SavePosition()    
    Exterior:LuaFnAskOpenExterior(6)
end

function NewExterior_DressStyle_OpenOrnamentsBack()
    NewExterior_DressStyle_SavePosition()    
    OrnamentsScript:AskOrnamentsInfo(0)
end

function NewExterior_DressStyle_OpenOrnamentsHead()
    NewExterior_DressStyle_SavePosition()    
    OrnamentsScript:AskOrnamentsInfo(1)
end

function NewExterior_DressStyle_TakeOffRide()
    local defExteriorID = Exterior:LuaFnGetExteriorInUse(0)
    if defExteriorID == 0 then
        Exterior:LuaFnSetCurrentExteriorSetInfo("RIDE", 0)
        NewExterior_DressStyle_UpdateLeftBtn()
    else
        Exterior:LuaFnSetExteriorInUse(0, 0, 0)
    end
end

function NewExterior_DressStyle_TakeOffWeapon()
    local defExteriorID = Exterior:LuaFnGetExteriorInUse(1)
    if defExteriorID == 0 then
        Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
        NewExterior_DressStyle_UpdateLeftBtn()
        Exterior:LuaFnRestoreExteriorPlayerFittingData(1)
        Exterior:LuaFnUpdateExteriorPlayerData()
    else
        Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
        Exterior:LuaFnSetExteriorInUse(1, 0, 0)
    end
end

function NewExterior_DressStyle_UpdateRedPoint()

    NewExterior_DressStyle_Dress_Tip:Hide()
    
    if Exterior:LuaFnIsHaveExteriorShowTip(0) == 1 then
        NewExterior_DressStyle_Ride_Tip:Show()
    else
        NewExterior_DressStyle_Ride_Tip:Hide()
    end
    
    if Exterior:LuaFnIsHaveExteriorShowTip(1) == 1 then
        NewExterior_DressStyle_Weapon_Tip:Show()
    else
        NewExterior_DressStyle_Weapon_Tip:Hide()
    end
    
    if Exterior:LuaFnIsHaveExteriorShowTip(2) == 1 then
        NewExterior_DressStyle_PetPossJian_Tip:Show()
    else
        NewExterior_DressStyle_PetPossJian_Tip:Hide()
    end
    
    if Exterior:LuaFnIsHaveExteriorShowTip(3) == 1 then
        NewExterior_DressStyle_FaceStyle_Tip:Show()
    else
        NewExterior_DressStyle_FaceStyle_Tip:Hide()
    end
    
    if Exterior:LuaFnIsHaveExteriorShowTip(4) == 1 or Exterior:LuaFnIsHaveHairColorShowTip() == 1 then
        NewExterior_DressStyle_HairStyle_Tip:Show()
    else
        NewExterior_DressStyle_HairStyle_Tip:Hide()
    end
    
    if Exterior:LuaFnIsHaveExteriorShowTip(5) == 1 or Exterior:LuaFnIsHaveExteriorShowTip(6) == 1 then
        NewExterior_DressStyle_PlayerFrame_Tip:Show()
    else
        NewExterior_DressStyle_PlayerFrame_Tip:Hide()
    end

    if Pneuma:GetMF(2959)== 1 or Exterior:LuaFnIsHaveExteriorShowTip(7) == 1 or Exterior:LuaFnIsHaveInfantHairColorShowTip() == 1 then 
        NewExterior_DressStyle_SwitchBtn_Tip:Show()
    else
        NewExterior_DressStyle_SwitchBtn_Tip:Hide()
    end

    if OrnamentsScript:IsHaveOrnamentsShowTip(0) == 1 then
        NewExterior_DressStyle_Widget_Tip:Show()
    else
        NewExterior_DressStyle_Widget_Tip:Hide()
    end

    if OrnamentsScript:IsHaveOrnamentsShowTip(1) == 1 then
        NewExterior_DressStyle_Headdress_Tip:Show()
    else
        NewExterior_DressStyle_Headdress_Tip:Hide()
    end
end

function NewExterior_DressStyle_UpdateColor()
    for i, ui in (g_DressColorList.color or {}) do
        ui:SetCheck(0)
        ui:Hide()
    end
    for i, ui in (g_DressColorList.lock or {}) do
        ui:Hide()
    end
    NewExterior_DressStyle_DressColour1:SetCheck(0)
    NewExterior_DressStyle_DressColour1:Hide()
    NewExterior_DressStyle_ButtonTimeLock1:Hide()

    local tips = "#{SZTJ_230505_17}"
    if g_CurSelExteriorID > 0 then
        local isLongBtn = 0
        local nSelSubID = g_CurSelExteriorSubID + 1
        g_MaxSubNum = DressStyleScript:GetDressStyleColorMax(g_CurSelExteriorID)
        if g_MaxSubNum == 1 then
            isLongBtn = DressStyleScript:GetDressStyleInfo(g_CurSelExteriorID, "LongStyle")
        end
        if isLongBtn > 0 then
            local szName = DressStyleScript:GetDressStyleSubInfo(g_CurSelExteriorID, 0, "Desc")
            NewExterior_DressStyle_DressColour1:SetText(szName)
            NewExterior_DressStyle_DressColour1:SetCheck(1)
            NewExterior_DressStyle_DressColour1:Show()
            local active = DressStyleScript:GetDressStyleActiveInfo(g_CurSelExteriorID, 0, "Active")
            if active < 1 then
                NewExterior_DressStyle_ButtonTimeLock1:Show()
            end
        else
            for i, ui in (g_DressColorList.color or {}) do
                if i > g_MaxSubNum then
                    ui:Hide()
                else
                    -- 进行按钮状态处理
                    if nSelSubID == i then
                        ui:SetCheck(1)
                    end
                    local szName = DressStyleScript:GetDressStyleSubInfo(g_CurSelExteriorID, i-1, "Desc")
                    if szName ~= nil then
                        ui:SetText(szName)
                    end
                    ui:Show()
                end
            end
            for i, ui in (g_DressColorList.lock or {}) do
                if i <= g_MaxSubNum then
                    local active = DressStyleScript:GetDressStyleActiveInfo(g_CurSelExteriorID, i-1, "SubActive")
                    if active < 1 then
                        ui:Show()
                    end
                end
            end
        end
        --tips = "等待来源功能"
    end
    --NewExterior_DressStyle_GetTip:SetText(tips)
end

function NewExterior_DressStyle_UpdateActionBtn(showType)
    if showType < 0 then
        for _, ui in (g_ActionButtonList or {}) do
            ui:Hide()
        end
        for _, ui in (g_TransformButtonList or {}) do
            ui:Hide()
        end
    end
end

function NewExterior_DressStyle_GenderUpdate()
    local sex = Exterior:LuaFnGetExteriorRaceID()
    if sex ~= nil and g_sexButtonInfo[sex] ~= nil then
        NewExterior_DressStyle_GenderChange_Btn:SetProperty("HoverImage", g_sexButtonInfo[sex].imgH)
        NewExterior_DressStyle_GenderChange_Btn:SetProperty("NormalImage", g_sexButtonInfo[sex].imgN)
        NewExterior_DressStyle_GenderChange_Btn:SetProperty("PushedImage", g_sexButtonInfo[sex].imgP)
    end
end

function NewExterior_DressStyle_CloseSameGroupWindow()
    CloseWindow("SelfEquip", true)
    --CloseWindow("NewExterior_DressStyle", true)
    CloseWindow("NewExterior_Ride", true)
    CloseWindow("NewExterior_Weapon", true)
    CloseWindow("NewExterior_PetPossJian", true)
    CloseWindow("NewExterior_Facestyle", true)
    CloseWindow("NewExterior_HairStyle", true)
    CloseWindow("NewExterior_PlayerFrame", true)
    CloseWindow("NewExterior_Widget", true)
    CloseWindow("NewExterior_Headdress", true)
    CloseWindow("NewExterior_DressBox", true)
    CloseWindow("NewExterior_GemEffect", true)
	CloseWindow("NewExterior_PlanSetting", true)
	CloseWindow("NewExterior_TuJing", true)
end

function NewExterior_DressStyle_CloseOtherWindow()
    --关闭元宝商店相关界面
    if IsWindowShow("VIP_Shop") then
        CloseWindow("VIP_Shop", true)
    end
    if(IsWindowShow("YuanbaoShop")) then
        CloseWindow("YuanbaoShop", true)
    end
    if(IsWindowShow("ShowShop")) then
        CloseWindow("ShowShop", true)
    end
    if(IsWindowShow("XuanShop")) then
        CloseWindow("XuanShop", true)
    end
        
    PushEvent( "CLOSE_DRESSPREVIEW") 
    PushEvent( "CLOSE_GEMEFFECTPREVIEW")
end

function NewExterior_DressStyle_SavePosition()
    Variable:SetVariable("ExteriorUnionPos", NewExterior_DressStyle_Frame:GetProperty("UnifiedPosition"), 1)
end

function NewExterior_DressStyle_SetPosition()
    
    local nExteriorUnionPos = Variable:GetVariable("ExteriorUnionPos")
    if nExteriorUnionPos ~= nil then
        NewExterior_DressStyle_Frame:SetProperty("UnifiedPosition", nExteriorUnionPos)
    end

end

function NewExterior_DressStyle_ShowFashionWeaponCheckButton()
    local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
    NewExterior_DressStyle_Dress_Type:SetCheck(IsDisplay)
    
    IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
    NewExterior_DressStyle_Weapon_Type:SetCheck(IsDisplay)

    IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
    NewExterior_DressStyle_Widget_Type:SetCheck(IsDisplay)
    
    IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
    NewExterior_DressStyle_Headdress_Type:SetCheck(IsDisplay)
end

function NewExterior_DressStyle_FashionDisplay()
    local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
    if IsDisplay == 1 then
        NewExterior_DressStyle_Dress_Type:SetCheck(0)
        SystemSetup:LuaFnCloseFashionDisplay(1)
    else
        NewExterior_DressStyle_Dress_Type:SetCheck(1)
        SystemSetup:LuaFnCloseFashionDisplay(0)
    end    
end

function NewExterior_DressStyle_ExteriorWeaponDisplay()
    local IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
    if IsDisplay == 1 then
        NewExterior_DressStyle_Weapon_Type:SetCheck(0)
        SystemSetup:LuaFnCloseExteriorWeaponDisplay(1)
    else
        NewExterior_DressStyle_Weapon_Type:SetCheck(1)
        SystemSetup:LuaFnCloseExteriorWeaponDisplay(0)
    end    
end

function NewExterior_DressStyle_OrnamentsBackDisplay()
    local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
    if IsDisplay == 1 then
        NewExterior_DressStyle_Widget_Type:SetCheck(0)
        SystemSetup:SetOrnamentsDisplayState(0, 1)
        OrnamentsScript:ResetOrnamentsUseInfo(0)
		Exterior:LuaFnUpdateExteriorPlayerData()
    else
        NewExterior_DressStyle_Widget_Type:SetCheck(1)
        SystemSetup:SetOrnamentsDisplayState(0, 0)
        Exterior:LuaFnUpdateExteriorPlayerData()
    end    
end

function NewExterior_DressStyle_OrnamentsHeadDisplay()
    local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
    if IsDisplay == 1 then
        NewExterior_DressStyle_Headdress_Type:SetCheck(0)
        SystemSetup:SetOrnamentsDisplayState(1, 1)
        OrnamentsScript:ResetOrnamentsUseInfo(1)
		Exterior:LuaFnUpdateExteriorPlayerData()
    else
        NewExterior_DressStyle_Headdress_Type:SetCheck(1)
        SystemSetup:SetOrnamentsDisplayState(1, 0)
        Exterior:LuaFnUpdateExteriorPlayerData()
    end    
end

function NewExterior_DressStyle_ActionToOrnamentsBack()
    local useID = OrnamentsScript:GetOrnamentsUseID(0)
    if useID > 0 then
        OrnamentsScript:TakeOffOrnaments(0)
    end
    Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSBACK", 0, 0, 0, 0)
    NewExterior_DressStyle_UpdateLeftBtn()
    Exterior:LuaFnRestoreExteriorPlayerFittingData(6)
    Exterior:LuaFnUpdateExteriorPlayerData()
end

function NewExterior_DressStyle_ActionToOrnamentsHead()
    local useID = OrnamentsScript:GetOrnamentsUseID(1)
    if useID > 0 then
        OrnamentsScript:TakeOffOrnaments(1)
    end
    Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSHEAD", 0, 0, 0, 0)
    NewExterior_DressStyle_UpdateLeftBtn()
    Exterior:LuaFnRestoreExteriorPlayerFittingData(7)
    Exterior:LuaFnUpdateExteriorPlayerData()
end

function NewExterior_DressStyle_OpenFashion()
    NewExterior_DressStyle_SavePosition()
    PushEvent("OPEN_EXTERIOR_FASHION", 1, 0)
end

-- 打开配饰图鉴
function NewExterior_DressStyle_OpenGemEffect()
    NewExterior_DressStyle_SavePosition()
    PushEvent("OPEN_EXTERIOR_GEMEFFECT")
end

-- 更改性别
function NewExterior_DressStyle_ChangeSex()
    local sex = Exterior:LuaFnGetExteriorRaceID()
    if sex ~= nil then
        if sex == g_PlayerRace.SEX_FEMALE then
            Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_MALE)
        elseif sex == g_PlayerRace.SEX_MALE then
            Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_FEMALE)
        end
        NewExterior_DressStyle_Show()
    end
end


function NewExterior_DressStyle_OnTransform(nIndex)
    NewExterior_DressStyle_SubItemClicked(nIndex-1)
end

-- 关闭来源
function NewExterior_DressStyle_CloseTuJing()
	if IsWindowShow("NewExterior_TuJing") then
		CloseWindow("NewExterior_TuJing", true)
	end
end

-- 来源
function NewExterior_DressStyle_ClickTuJing()
	if g_CurSelExteriorID > 0 then		
		PushEvent("OPEN_EXTERIOR_TUJING", 102, g_CurSelExteriorID, -1, -1)
	else
		PushDebugMessage("#{SZDP_230509_64}")
	end
end

-- 图鉴页签
function NewExterior_DressStyle_PageButtonUpdate()
    NewExterior_DressStyle_GoTo_DressBox:SetCheck(0)
    NewExterior_DressStyle_GoTo_DressStyle:SetCheck(1)
    NewExterior_DressStyle_GoTo_GemEffect:SetCheck(0)
end
--!!!reloadscript =NewExterior_DressStyle