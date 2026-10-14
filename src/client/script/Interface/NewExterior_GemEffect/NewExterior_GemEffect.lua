--!!!reloadscript =NewExterior_GemEffect

local EXTERIORFILTTING_TOTALKIND = 6
local g_NewExterior_GemEffect_UnifiedPosition = ""

local g_GemEffect_Name = "GEMEFFECT"

local g_CurSelExteriorType = 0
local g_NeedChangeScrollSize = {1,1,1}
local g_TargetExteriorIndex = {0,0,0}        --定位的外观索引，从1开始
local g_TargetExteriorID = {0,0,0}           --定位的外观ID
local g_CurSelExteriorID = {0,0,0}           --当前选择的外观ID，从1开始
local g_CurSelExteriorSubID = {0,0,0}        --当前选择的外观ID，从1开始
local g_MaxBarNum = {0,0,0}

local g_Distance = 1
local g_Distance_Ori = 2
local g_Distance_Max = 4
local g_InitList = 0
local g_PlayerfashionDepotType = 1           --仓库类型 1 玩家时装仓库 2 子女时装仓库
local g_GemEffectTypeMax = 3
local g_BarList = {}
local g_PlayerFashionInfoList = {}
local g_GemEffectList = {}
local g_SuperList = {}

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
local g_Bar_Names = 
{
    [1] = {
        ["list"] = "NewExterior_GemEffect_SuperList",
        ["item"] = "NewExterior_GemEffect_SuperListItem",
        ["action"] = "NewExterior_GemEffect_SuperListItemAction",
        ["try"] = "NewExterior_GemEffect_SuperListItemActionTry",
        ["lock"] = "NewExterior_GemEffect_SuperListItemActionLock1",
    },
    [2] = {
        ["list"] = "NewExterior_GemEffect_SuperList2",
        ["item"] = "NewExterior_GemEffect_SuperListItem2",
        ["action"] = "NewExterior_GemEffect_SuperListItemAction2",
        ["try"] = "NewExterior_GemEffect_SuperListItemActionTry2",
        ["lock"] = "NewExterior_GemEffect_SuperListItemActionLock2",
    },
    [3] = {
        ["list"] = "NewExterior_GemEffect_SuperList3",
        ["item"] = "NewExterior_GemEffect_SuperListItem3",
        ["action"] = "NewExterior_GemEffect_SuperListItemAction3",
        ["try"] = "NewExterior_GemEffect_SuperListItemActionTry3",
        ["lock"] = "NewExterior_GemEffect_SuperListItemActionLock3",
    }
}

local g_sexButtonInfo = {
    [0] = { imgH = "set:DressPreview01 image:DressPreview_Male_Hover", imgN = "set:DressPreview01 image:DressPreview_Male_Normal", imgP = "set:DressPreview01 image:DressPreview_Male_Pushed"  },
    [1] = { imgH = "set:DressPreview01 image:DressPreview_Female_Hover", imgN = "set:DressPreview01 image:DressPreview_Female_Normal", imgP = "set:DressPreview01 image:DressPreview_Female_Pushed"  },
}
local g_PlayerRace = {
    SEX_INVALID	= -1,
    SEX_FEMALE = 0,
    SEX_MALE = 1,
    SEX_NUMBERS = 2,
}
--=========
--PreLoad==
--=========
function NewExterior_GemEffect_PreLoad()

    this:RegisterEvent("OPEN_EXTERIOR_GEMEFFECT")
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
    this:RegisterEvent("UPDATE_EXTERIOR_GEMEFFECT",false)
end

--=========
--OnLoad
--=========
function NewExterior_GemEffect_OnLoad()
    g_NewExterior_GemEffect_UnifiedPosition = NewExterior_GemEffect_Frame:GetProperty("UnifiedPosition")
    
    g_GemEffectList = {
        {
            action=NewExterior_GemEffect_LevelListItemAction,
            try=NewExterior_GemEffect_LevelListItemActionTry,
            lock=NewExterior_GemEffect_ButtonTimeLock,
        },
        {
            action=NewExterior_GemEffect_LevelListItemAction2,
            try=NewExterior_GemEffect_LevelListItemActionTry2,
            lock=NewExterior_GemEffect_ButtonTimeLock2,
        },
        {
            action=NewExterior_GemEffect_LevelListItemAction3,
            try=NewExterior_GemEffect_LevelListItemActionTry3,
            lock=NewExterior_GemEffect_ButtonTimeLock3,
        },
        {
            action=NewExterior_GemEffect_LevelListItemAction4,
            try=NewExterior_GemEffect_LevelListItemActionTry4,
            lock=NewExterior_GemEffect_ButtonTimeLock4,
        },
    }
    g_SuperList = 
    {
        NewExterior_GemEffect_SuperList,
        NewExterior_GemEffect_SuperList2,
        NewExterior_GemEffect_SuperList3,
    }
end

--=========
--OnEvent
--=========
function NewExterior_GemEffect_OnEvent(event)
    
    if event == "OPEN_EXTERIOR_GEMEFFECT" then
        if this:IsVisible() then
            if tonumber(arg0) == 0 then
                NewExterior_GemEffect_SavePosition()
                this:Hide()
            end
        else
            -- 关闭一些关联UI
            NewExterior_GemEffect_CloseOtherWindow()
                    
            NewExterior_GemEffect_SetPosition()
            NewExterior_GemEffect_CloseSameGroupWindow()
            this:Show()
            NewExterior_GemEffect_Show()
        end
        return
    end
    
    if event == "EXERIOR_SAVEALL_RET" then
        Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
        Exterior:LuaFnInitCurrentExteriorSet()
        NewExterior_GemEffect_Show()
    end
    
    if ( event == "OPEN_STALL_SALE" ) -- 开始摆摊，还原试穿
        or ( event == "PROGRESSBAR_SHOW" )        -- 读进度条中，还原试穿
        or ( event == "MODELID_CHANGE" ) -- 变身 关闭界面
        then
        NewExterior_GemEffect_CloseClick()    
        return
    end
    
    if event == "ADD_EXTERIOR" or event == "UPDATE_EXTERIOR" or event == "EXTERIOR_OUTTIME" or event == "EXTERIOR_ID_CHANGED" then
        --左侧
        NewExterior_GemEffect_UpdateLeftBtn()
        NewExterior_GemEffect_UpdateRedPoint()
        --模型
        Exterior:LuaFnUpdateExteriorPlayerData()
        Exterior:LuaFnUpdateExteriorPlayerData()
    end
    
    if event == "UPDATE_EXTERIOR_FASHION" then
        if tonumber(arg0) == 1 then
            --init
            NewExterior_GemEffect_InitList()    
            --列表
            NewExterior_GemEffect_UpdateList()
            --左侧
            NewExterior_GemEffect_UpdateLeftBtn()
            --模型
            NewExterior_GemEffect_UpdateObj()
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
            NewExterior_GemEffect_CloseClick()
            return
        end
    end

    if ( event == "UI_COMMAND" and tonumber(arg0) == 80081701 ) then
		if this:IsVisible() then
			NewExterior_GemEffect_CloseClick()
            return
		end
	end
    
    if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
        this:Hide()
    end
    
    -- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
    if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
        NewExterior_GemEffect_Frame:SetProperty("UnifiedPosition", g_NewExterior_GemEffect_UnifiedPosition)
    end

end

function NewExterior_GemEffect_InitList()
    
    if g_InitList == 0 then
        DressStyleScript:InitGemEffectInfo()
        for i=1, g_GemEffectTypeMax do
            g_BarList[i] = {}
            local name = g_Bar_Names[i]
            local barlist = g_BarList[i]
            g_MaxBarNum[i] = DressStyleScript:GetGemEffectMax(i-1)
            for j=1, g_MaxBarNum[i] do
                local bar = g_SuperList[i]:AddChild(name["item"])
                bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
                barlist[j] = bar

                bar:GetSubItem(name["action"]):SetEvent("MouseLButtonDown", string.format("NewExterior_GemEffect_ItemClicked(%d,%d)", i,j))
                bar:GetSubItem(name["action"]):SetEvent("MouseMove", string.format("NewExterior_GemEffect_ItemMouseMove(%d,%d)", i,j))
                bar:GetSubItem(name["action"]):SetProperty("Empty", "False")
                bar:GetSubItem(name["action"]):SetProperty("UseDefaultTooltip", "True")
                bar:GetSubItem(name["try"]):Hide()
                bar:GetSubItem(name["lock"]):Hide()
            end
        end
        g_InitList = 1
    end    
end

function NewExterior_GemEffect_Show()
    
    g_Distance = g_Distance_Ori
    g_NeedChangeScrollSize = {1,1,1}
    
    NewExterior_GemEffect_InitList()    
    
    NewExterior_GemEffect_CleanUp()
    
    Exterior:LuaFnInitCurrentExteriorSet()
    
    EXTERIORFILTTING_TOTALKIND = Exterior:LuaFnGetExteriorPlayerFittingCount()

    NewExterior_GemEffect_InitExteriorData()
    --列表
    NewExterior_GemEffect_UpdateList()
    --左侧
    NewExterior_GemEffect_UpdateLeftBtn()
    --模型
    NewExterior_GemEffect_UpdateObj()
    --红点
    NewExterior_GemEffect_UpdateRedPoint()
    --选项
    NewExterior_GemEffect_ShowFashionWeaponCheckButton()
    --性别
    NewExterior_GemEffect_GenderUpdate()
    --图鉴
    NewExterior_GemEffect_PageButtonUpdate()
end

-- 对一些数据进行初始化
function NewExterior_GemEffect_InitExteriorData()
    g_CurSelExteriorType = 0
    g_CurSelExteriorID = {0,0,0}
    g_CurSelExteriorSubID = {0,0,0}
    g_TargetExteriorID = {0,0,0}
    g_TargetExteriorIndex = {-1,-1,-1}

    for i=1, g_GemEffectTypeMax do
        local cacheExteriorID,cacheExteriorSubID = Exterior:LuaFnGetCurrentExteriorSetInfo(g_GemEffect_Name, i-1)
        if cacheExteriorID ~= nil and cacheExteriorID > 0 then
            g_CurSelExteriorID[i] = cacheExteriorID
            g_CurSelExteriorSubID[i] = cacheExteriorSubID
            g_TargetExteriorIndex[i] = DressStyleScript:GetGemEffectIdx(i-1, cacheExteriorID) + 1
        end
    end
end

--左侧
function NewExterior_GemEffect_UpdateLeftBtn()
    
    NewExterior_GemEffect_CleanUp_LeftButton()
    
    local sex = Exterior:LuaFnGetExteriorRaceID()
    
    local cacheExteriorID,cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("DRESSSTYLE")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        --图鉴
        local cacheID,dressExteriorID,specialExteriorID = DressStyleScript:GetDressStyleInfo(cacheExteriorID, "ID")
        if cacheID ~= nil then
            -- 获取图标
            local strIcon = DataPool:LuaFnGetItemIconByTableIndex(dressExteriorID)
            local strImage = GetIconFullName(strIcon)
            -- 设置action
            NewExterior_GemEffect_Dress_LeftBtn:SetActionItem(-1)
            NewExterior_GemEffect_Dress_LeftBtn:SetProperty("Empty", "False")
            NewExterior_GemEffect_Dress_LeftBtn:SetProperty("NormalImage", strImage)
            NewExterior_GemEffect_Dress_LeftBtn:SetProperty("HoverImage", strImage)
            NewExterior_GemEffect_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "True")
            -- 文字tips
            local strToolTip = DressStyleScript:GetDressStyleToolTips(cacheExteriorID, cacheExteriorIdx)
            NewExterior_GemEffect_Dress_LeftBtn:SetToolTip(strToolTip)
            -- 试穿
            NewExterior_GemEffect_Dress_ActionImg:Show()
        end
    else
        --时装
        cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
        if cacheExteriorID ~= nil and cacheExteriorID > 0 then
            local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(g_PlayerfashionDepotType, cacheExteriorIdx)
            --local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, cacheExteriorID, 0)
            if theAction:GetID() ~= 0 then
                NewExterior_GemEffect_Dress_LeftBtn:SetActionItem(theAction:GetID())
                NewExterior_GemEffect_Dress_ActionImg:Show()
                
                local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
                if nCurFashionId ~= nil and nCurFashionId > 0 then
                    if nCurFashionIdx == cacheExteriorIdx then
                        NewExterior_GemEffect_Dress_ActionImg:Hide()
                    end
                end
            end
        else
            local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
            if nCurFashionId ~= nil and nCurFashionId > 0 then
                local theAction, bLocked = FashionDepot:LuaFnGetFashionDepotItem(g_PlayerfashionDepotType, nCurFashionIdx)
                --local theAction = Exterior:LuaFnEnumExteriorFashionAction(1, nCurFashionId, 0)
                if theAction:GetID() ~= 0 then
                    NewExterior_GemEffect_Dress_LeftBtn:SetActionItem(theAction:GetID())
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
        
        NewExterior_GemEffect_Ride_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_GemEffect_Ride_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
        NewExterior_GemEffect_Ride_LeftBtn:SetToolTip(strTemp)
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_GemEffect_Ride_ActionImg:Show()
        end
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
            NewExterior_GemEffect_Ride_LockImg:Show()
        end
    end
    
    --幻武
    edType = 1
    cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("WEAPON")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName     = Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Name")
        local strIcon     = Exterior:LuaFnGetExteriorWeaponInfo(cacheExteriorID, "Icon")
        local strImage = GetIconFullName(strIcon)
        
        NewExterior_GemEffect_Weapon_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_GemEffect_Weapon_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
        NewExterior_GemEffect_Weapon_LeftBtn:SetToolTip(strTemp)
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_GemEffect_Weapon_ActionImg:Show()
        end
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
            NewExterior_GemEffect_Weapon_LockImg:Show()
        end
    end
    
    --附体
    edType = 2
    local cacheVisualIndex = 0
    cacheExteriorID, cacheVisualIndex, _ = Exterior:LuaFnGetCurrentExteriorSetInfo("FUTI")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName     = Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "Name")
        local strImage     = Exterior:LuaFnGetExteriorFutiInfo(cacheExteriorID, "VisualIcon", cacheVisualIndex)
        NewExterior_GemEffect_PetPossJian_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_GemEffect_PetPossJian_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_83}", strName)
        NewExterior_GemEffect_PetPossJian_LeftBtn:SetToolTip(strTemp)
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_GemEffect_PetPossJian_ActionImg:Show()
        else
            if Exterior:LuaFnGetExteriorFutiVisualIndex() ~= cacheVisualIndex then
                NewExterior_GemEffect_PetPossJian_ActionImg:Show()
            end
        end
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 or Exterior:LuaFnIsExteriorFutiVisualUnlocked(cacheExteriorID, cacheVisualIndex) ~= 1 then
            NewExterior_GemEffect_PetPossJian_LockImg:Show()
        end
    end
    
    --脸型
    edType = 3
    cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FACE")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName     = Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Name", sex)
        local strIcon     = Exterior:LuaFnGetExteriorFaceInfo(cacheExteriorID, "Icon", sex)
        local strImage = GetIconFullName(strIcon)        
        NewExterior_GemEffect_FaceStyle_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_GemEffect_FaceStyle_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_82}", strName)
        NewExterior_GemEffect_FaceStyle_LeftBtn:SetToolTip(strTemp)
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_GemEffect_FaceStyle_ActionImg:Show()
        end
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
            NewExterior_GemEffect_FaceStyle_LockImg:Show()
        end
    end
    
    --发型
    edType = 4
    cacheExteriorID, cacheColorIndex = Exterior:LuaFnGetCurrentExteriorSetInfo("HAIR")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName = Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Name", sex)
        local strIcon = Exterior:LuaFnGetExteriorHairInfo(cacheExteriorID, "Icon", sex)
        local strImage = GetIconFullName(strIcon)        
        NewExterior_GemEffect_HairStyle_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_GemEffect_HairStyle_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_81}", strName)
        NewExterior_GemEffect_HairStyle_LeftBtn:SetToolTip(strTemp)
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_GemEffect_HairStyle_ActionImg:Show()
        else
            if Exterior:LuaFnGetExteriorHairColorIndex() ~= cacheColorIndex then
                NewExterior_GemEffect_HairStyle_ActionImg:Show()
            end
        end
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
            NewExterior_GemEffect_HairStyle_LockImg:Show()
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
        NewExterior_GemEffect_PlayerFrame_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_GemEffect_PlayerFrame_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_79}", strName)
        strHeadTip = strTemp
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_GemEffect_PlayerFrame_ActionImg:Show()
        end
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
            NewExterior_GemEffect_PlayerFrame_LockImg:Show()
        end        
    end
    
    --头像框
    edType = 6
    cacheExteriorID = Exterior:LuaFnGetCurrentExteriorSetInfo("FRAME")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Name")
        local iFrameType = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "Type")
        if iFrameType == 1 then
            NewExterior_GemEffect_PlayerFrame_Mask:Hide()
            NewExterior_GemEffect_PlayerFrame_Mask_Animate:Show()
            
            local strFrameAnimate = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameAnimate")
            NewExterior_GemEffect_PlayerFrame_Mask_Animate:SetProperty("Animate", strFrameAnimate)
        else
            NewExterior_GemEffect_PlayerFrame_Mask:Show()
            NewExterior_GemEffect_PlayerFrame_Mask_Animate:Hide()
            
            local strIcon = Exterior:LuaFnGetExteriorFrameInfo(cacheExteriorID, "FrameIcon")
            local strImage = GetIconFullName(strIcon)
            NewExterior_GemEffect_PlayerFrame_Mask:SetProperty("Image", strImage)
        end

        local strTemp = ScriptGlobal_Format("#{WGTJ_201222_85}", strName)
        NewExterior_GemEffect_PlayerFrame_LeftBtn:SetToolTip(strHeadTip.."#r"..strTemp)
        --试穿
        if Exterior:LuaFnGetExteriorInUse(edType) ~= cacheExteriorID then
            NewExterior_GemEffect_PlayerFrame_ActionImg:Show()
        end    
        --未激活
        if Exterior:LuaFnIsHaveExterior(edType, cacheExteriorID) ~= 1 then
            NewExterior_GemEffect_PlayerFrame_LockImg:Show()
        end    
    end
    
    local edOrnamentsType, cacheExteriorX, cacheExteriorY, cacheExteriorZ = 0, 0, 0, 0
    cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsBack")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
        local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
        local strImage = GetIconFullName(strIcon)
        
        NewExterior_GemEffect_Widget_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_GemEffect_Widget_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
        NewExterior_GemEffect_Widget_LeftBtn:SetToolTip(strTemp)
        --试穿
        if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
            NewExterior_GemEffect_Widget_ActionImg:Show()
        end
        --未激活
        local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
        if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
            NewExterior_GemEffect_Widget_LockImg:Show()
        end
    end

    edOrnamentsType= 1
    cacheExteriorID, cacheExteriorX, cacheExteriorY, cacheExteriorZ = Exterior:LuaFnGetCurrentExteriorSetInfo("OrnamentsHead")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        local strName = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Name")
        local strIcon = OrnamentsScript:GetOrnamentsInfo(edOrnamentsType, cacheExteriorID, "Icon")
        local strImage = GetIconFullName(strIcon)
        
        NewExterior_GemEffect_Headdress_LeftBtn:SetProperty("NormalImage", strImage)
        NewExterior_GemEffect_Headdress_LeftBtn:SetProperty("HoverImage", strImage)
        
        local strTemp = ScriptGlobal_Format("#{BGTS_220125_49}", strName)
        NewExterior_GemEffect_Headdress_LeftBtn:SetToolTip(strTemp)
        --试穿
        if OrnamentsScript:GetOrnamentsUseID(edOrnamentsType) ~= cacheExteriorID then
            NewExterior_GemEffect_Headdress_ActionImg:Show()
        end
        --未激活
        local nIdx, nX, nY, nZ, nState = OrnamentsScript:GetPlayerOrnamentsInfo(edOrnamentsType, cacheExteriorID, 0)
        if nIdx < 0 or (nState ~= 2 and nState ~= 4 ) then
            NewExterior_GemEffect_Headdress_LockImg:Show()
        end
    end
end

--模型
function NewExterior_GemEffect_UpdateObj()
    
    local cacheExteriorID, cacheExteriorSubID = Exterior:LuaFnGetCurrentExteriorSetInfo(g_GemEffect_Name)
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        NewExterior_GemEffect_FakeObject:DetachWindowEx()
        NewExterior_GemEffect_FakeObject:AttachWindowEx("Exterior_Player")
        Exterior:LuaFnUpdateExteriorPlayerData()
        --Exterior:LuaFnUpdateExteriorAvatarFashion(cacheExteriorID, cacheExteriorIdx)    
    else
        NewExterior_GemEffect_FakeObject:DetachWindowEx()
        NewExterior_GemEffect_FakeObject:AttachWindowEx("Exterior_Player")
        Exterior:LuaFnUpdateExteriorPlayerData()
    end

    NewExterior_GemEffect_ActionEnd()
    
    NewExterior_GemEffect_UpdateCamera()
    
end

--列表
function NewExterior_GemEffect_UpdateList()

    -- 显示
    for i=1, g_GemEffectTypeMax do
        for j=1, g_MaxBarNum[i] do 
            NewExterior_GemEffect_SetItem(i, j)
        end
        if g_NeedChangeScrollSize[i] == 1 then
            g_NeedChangeScrollSize[i] = 0
            g_SuperList[i]:RefreshLayout()
        end
    
        if g_TargetExteriorIndex[i] ~= 0 then
            g_SuperList[i]:SetScrollPosition4Index(g_TargetExteriorIndex[i] - 1)
            g_TargetExteriorID[i] = 0
            g_TargetExteriorIndex[i] = 0
        else
            g_SuperList[i]:SetScrollPosition4Index(0)
        end
    end

    NewExterior_GemEffect_UpdateLevel()
end

function NewExterior_GemEffect_SetItem(pos, index)
    local barlist = g_BarList[pos]
    if barlist == nil then
        return
    end
    local bar = barlist[index]
    if bar == nil then
        return
    end
    bar:Show()
    local name = g_Bar_Names[pos]

    local ctrlAction = bar:GetSubItem(name["action"])
    if ctrlAction ~= nil then
        local cacheExteriorID = DressStyleScript:GetGemEffectInfoByIdx(pos-1, index-1, "ID")
        if cacheExteriorID ~= nil then
            -- 图标
            local itemID = DressStyleScript:GetGemEffectInfoByIdx(pos-1, index-1, "MAXID")
            local strIcon = DataPool:LuaFnGetItemIconByTableIndex(itemID)
            local strImage = GetIconFullName(strIcon)
            ctrlAction:SetProperty("NormalImage", strImage)
            ctrlAction:SetProperty("HoverImage", strImage)
            -- Tips
            local strToolTip = DressStyleScript:GetGemEffectToolTips(cacheExteriorID)
            ctrlAction:SetToolTip(strToolTip)
            -- 选中状态
            if cacheExteriorID ==  g_CurSelExteriorID[pos] then
                ctrlAction:SetPushed(1)
            else
                ctrlAction:SetPushed(0)
            end
            local uiTry = bar:GetSubItem(name["try"])
            if uiTry ~= nil then
                if cacheExteriorID ==  g_CurSelExteriorID[pos] then
                    uiTry:Show()
                else
                    uiTry:Hide()
                end
            end
            local lockUI = bar:GetSubItem(name["lock"])
            if lockUI ~= nil then
                local active = DressStyleScript:GetGemEffectActiveInfo(cacheExteriorID, -1, "Active")
                if active > 0 then
                    lockUI:Hide()
                else
                    lockUI:Show()
                end
            end
        end
    end
end

function NewExterior_GemEffect_ActionEnd()
    NewExterior_GemEffect_Model_Plus:Enable()
    NewExterior_GemEffect_Model_Subtract:Enable()
    NewExterior_GemEffect_Model_TurnLeft:Enable()
    NewExterior_GemEffect_Model_TurnRight:Enable()
    
    NewExterior_GemEffect_UpdateCamera()
end

function NewExterior_GemEffect_ItemClicked(nPos, nIndex)
    local isInValid = NewExterior_GemEffect_PreviewTips()
    if isInValid > 0 then
        NewExterior_GemEffect_SetItemSelected(nPos, -1)
        NewExterior_GemEffect_CloseTuJing()
        return
    end
    local cacheExteriorID = DressStyleScript:GetGemEffectInfoByIdx(nPos-1, nIndex-1, "ID")
    if cacheExteriorID ~= nil and g_CurSelExteriorID[nPos] ~= cacheExteriorID then
        -- 进行内容选中
        g_CurSelExteriorID[nPos] = cacheExteriorID

        g_CurSelExteriorType = nPos
        local nSubMax = DressStyleScript:GetGemEffectInfo(g_CurSelExteriorID[nPos], "GemMax")
        if nSubMax == nil or g_CurSelExteriorSubID[nPos] >= nSubMax then
            g_CurSelExteriorSubID[nPos] = 0
        end

        -- 进行赋值处理
        Exterior:LuaFnSetCurrentExteriorSetInfo(g_GemEffect_Name, nPos-1, g_CurSelExteriorID[nPos], g_CurSelExteriorSubID[nPos])
        -- 设置选中状态
        NewExterior_GemEffect_SetItemSelected(nPos, nIndex)
        -- 刷新染色信息
        NewExterior_GemEffect_UpdateLevel()
        -- 刷新模型
        NewExterior_GemEffect_UpdateLeftBtn()
        -- 模型
        NewExterior_GemEffect_UpdateObj()
    else
        g_CurSelExteriorID[nPos] = cacheExteriorID
        g_CurSelExteriorID[nPos] = 0
        g_CurSelExteriorType = 0

        -- 进行赋值处理
        Exterior:LuaFnSetCurrentExteriorSetInfo(g_GemEffect_Name, nPos-1, g_CurSelExteriorID[nPos], g_CurSelExteriorSubID[nPos])
        NewExterior_GemEffect_SetItemSelected(nPos, -1)
        -- 刷新染色信息
        NewExterior_GemEffect_UpdateLevel()
        -- 刷新模型
        NewExterior_GemEffect_UpdateLeftBtn()
        -- 模型
        NewExterior_GemEffect_UpdateObj()
    end
    NewExterior_GemEffect_CloseTuJing()
end

function NewExterior_GemEffect_SubItemClicked(nSubIndex)
    -- 显示提示
    local isInValid = NewExterior_GemEffect_PreviewTips()
    if isInValid < 1 then
        local selType = g_CurSelExteriorID[g_CurSelExteriorType]
        if g_CurSelExteriorType > 0 and selType ~= nil and selType > 0 then
            -- 进行内容选中
            g_CurSelExteriorSubID[g_CurSelExteriorType] = nSubIndex
            -- 进行赋值处理
            Exterior:LuaFnSetCurrentExteriorSetInfo(g_GemEffect_Name, g_CurSelExteriorType-1, selType, g_CurSelExteriorSubID[g_CurSelExteriorType])
            -- 刷新染色信息
            NewExterior_GemEffect_UpdateLevel()
            -- 刷新模型
            NewExterior_GemEffect_UpdateLeftBtn()
            -- 模型
            NewExterior_GemEffect_UpdateObj()
        else
            NewExterior_GemEffect_Show()
        end
    end
    NewExterior_GemEffect_CloseTuJing()
end

function NewExterior_GemEffect_ItemMouseMove(nPos, nIndex)
end

function NewExterior_GemEffect_SetItemSelected(nPos, nIndex)
    if nPos < 1 or nPos > g_GemEffectTypeMax then
        return
    end

    local name = g_Bar_Names[nPos]
    local barlist = g_BarList[nPos]
    for i=1, g_MaxBarNum[nPos] do        
        if barlist[i] ~= nil then    
            local ctrlAction = barlist[i]:GetSubItem(name["action"])
            if ctrlAction ~= nil then
                if i == nIndex then
                    ctrlAction:SetPushed(1)
                    barlist[i]:GetSubItem(name["try"]):Show()
                else
                    ctrlAction:SetPushed(0)    
                    barlist[i]:GetSubItem(name["try"]):Hide()
                end
            end
        end
    end
end

function NewExterior_GemEffect_CloseClick()    
    Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
        
    NewExterior_GemEffect_SavePosition()
    this:Hide()
end

function NewExterior_GemEffect_OnHidden()
    
    if IsWindowShow("NewExterior_Ride") 
        or IsWindowShow("NewExterior_Weapon")  
        or IsWindowShow("NewExterior_PetPossJian")
        or IsWindowShow("NewExterior_Facestyle") 
        or IsWindowShow("NewExterior_HairStyle") 
        or IsWindowShow("NewExterior_PlayerFrame") 
        or IsWindowShow("NewExterior_Widget") 
        or IsWindowShow("NewExterior_Headdress")
        or IsWindowShow("NewExterior_DressBox")
        or IsWindowShow("NewExterior_DressStyle")
        then
    else    
        Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
    end    
    
    NewExterior_GemEffect_CleanUp()
        
    if IsWindowShow("NewExterior_PlanSetting") then
        CloseWindow("NewExterior_PlanSetting", true)
    end
    NewExterior_GemEffect_CloseTuJing()
end
    
function NewExterior_GemEffect_CleanUp_LeftButton()

    NewExterior_GemEffect_Dress_LeftBtn:SetActionItem(-1)
    NewExterior_GemEffect_Dress_LeftBtn:SetProperty("UseDefaultTooltip", "False")
	NewExterior_GemEffect_Dress_LeftBtn:SetProperty("NormalImage", "")
	NewExterior_GemEffect_Dress_LeftBtn:SetProperty("HoverImage", "")
    NewExterior_GemEffect_Dress_LeftBtn:SetProperty("Empty", "True")
    
    local ctrl_list = {
        [1] = NewExterior_GemEffect_Weapon_LeftBtn,
        [2] = NewExterior_GemEffect_PetPossJian_LeftBtn,
        [3] = NewExterior_GemEffect_FaceStyle_LeftBtn,
        [4] = NewExterior_GemEffect_HairStyle_LeftBtn,
        [5] = NewExterior_GemEffect_PlayerFrame_LeftBtn,
        [6] = NewExterior_GemEffect_Ride_LeftBtn,
        [7] = NewExterior_GemEffect_Widget_LeftBtn,
        [8] = NewExterior_GemEffect_Headdress_LeftBtn,
    }
    
    for i = 1 ,8 do
        ctrl_list[i]:SetProperty("Empty", "False")
        ctrl_list[i]:SetProperty("UseDefaultTooltip", "True")
        ctrl_list[i]:SetProperty("NormalImage", "")
        ctrl_list[i]:SetProperty("HoverImage", "")
        ctrl_list[i]:SetToolTip("")
    end
    
    NewExterior_GemEffect_PlayerFrame_Mask:SetProperty("Image", "")
    NewExterior_GemEffect_PlayerFrame_Mask_Animate:SetProperty("Animate", "")

    NewExterior_GemEffect_Dress_ActionImg:Hide()
    NewExterior_GemEffect_Weapon_ActionImg:Hide()
    NewExterior_GemEffect_PetPossJian_ActionImg:Hide()
    NewExterior_GemEffect_FaceStyle_ActionImg:Hide()
    NewExterior_GemEffect_HairStyle_ActionImg:Hide()
    NewExterior_GemEffect_PlayerFrame_ActionImg:Hide()
    NewExterior_GemEffect_Ride_ActionImg:Hide()    
    NewExterior_GemEffect_Widget_ActionImg:Hide()
    NewExterior_GemEffect_Headdress_ActionImg:Hide()

    NewExterior_GemEffect_Dress_LockImg:Hide()
    NewExterior_GemEffect_Weapon_LockImg:Hide()
    NewExterior_GemEffect_PetPossJian_LockImg:Hide()
    NewExterior_GemEffect_FaceStyle_LockImg:Hide()
    NewExterior_GemEffect_HairStyle_LockImg:Hide()
    NewExterior_GemEffect_PlayerFrame_LockImg:Hide()
    NewExterior_GemEffect_Ride_LockImg:Hide()
    NewExterior_GemEffect_Widget_LockImg:Hide()
    NewExterior_GemEffect_Headdress_LockImg:Hide()
end

function NewExterior_GemEffect_CleanUp()
    for i=1, g_GemEffectTypeMax do
        local name = g_Bar_Names[i]
        local barlist = g_BarList[i]
        for j=1, g_MaxBarNum[i] do
            if barlist[i] then
                local ctrlAction = barlist[i]:GetSubItem(name["action"])            
                if ctrlAction then
                    ctrlAction:SetProperty("NormalImage", "")
                    ctrlAction:SetProperty("HoverImage", "")
                    ctrlAction:SetToolTip("")
                end
            end
        end
    end

    NewExterior_GemEffect_FakeObject:DetachWindowEx()
    
    NewExterior_GemEffect_CleanUp_LeftButton()
end

--左转
function NewExterior_GemEffect_FakeObject_TurnLeft(idx)
    
    if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
        NewExterior_GemEffect_FakeObject:RotateBeginEx("Exterior_Player", -0.3)
    else
        NewExterior_GemEffect_FakeObject:RotateEndEx()
    end
    
end

--右转
function NewExterior_GemEffect_FakeObject_TurnRight(idx)
    
    if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
        NewExterior_GemEffect_FakeObject:RotateBeginEx("Exterior_Player", 0.3)
    else
        NewExterior_GemEffect_FakeObject:RotateEndEx()
    end
    
end

--缩小
function NewExterior_GemEffect_ZoomOut()

    if g_Distance == 1 then
        return
    end
    
    g_Distance = g_Distance - 1    

    NewExterior_GemEffect_UpdateCamera()
    
end

--放大
function NewExterior_GemEffect_ZoomIn()

    if g_Distance == g_Distance_Max then
        return
    end
    
    g_Distance = g_Distance + 1    
    
    NewExterior_GemEffect_UpdateCamera()
    
end

function NewExterior_GemEffect_UpdateCamera()

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
    
    local fHeight, fDistance, fPitch = NewExterior_GemEffect_FakeObject:GetCameraEx()
    fHeight = cameraInfo[sex][g_Distance].fHeight
    fDistance = cameraInfo[sex][g_Distance].fDistance
    fPitch = cameraInfo[sex][g_Distance].fPitch
    fXOffset = cameraInfo[sex][g_Distance].fXOffset
    NewExterior_GemEffect_FakeObject:SetCameraEx(fHeight, fDistance, fPitch, fXOffset)
    
end

--卸下时装 
function NewExterior_GemEffect_ActionToDressBox()
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
        NewExterior_GemEffect_Show()
    end
    Exterior:LuaFnUnUseExteriorFashion(g_PlayerfashionDepotType)
end

--保存
function NewExterior_GemEffect_DressChange_Save()

    if Exterior:LuaFnIsHaveExteriorChange() == 0 then
        if Exterior:LuaFnIsHaveDressStyleChange() == 1 then
            local selfSex = GetMySelfRaceId()
            Exterior:LuaFnSetCurrentExteriorSetInfo("RESETDRESSSTYLE")
            Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", selfSex)
            Exterior:LuaFnInitCurrentExteriorSet()
            NewExterior_GemEffect_Show()
        else
            PushDebugMessage("#{WGJM_210104_02}")
        end
        return
    end
        
    Exterior:LuaFnRestoreExteriorPlayerFittingData(EXTERIORFILTTING_TOTALKIND)
    Exterior:LuaFnSaveExteriorAllChange(1)
end

--还原
function NewExterior_GemEffect_Undo()

    if Exterior:LuaFnIsHaveExteriorChange() == 0 and Exterior:LuaFnIsHaveDressStyleChange() == 0 then
        PushDebugMessage("#{WGJM_210104_01}")
        return
    end    
    
    Exterior:LuaFnSetCurrentExteriorSetInfo("RESET")
    Exterior:LuaFnInitCurrentExteriorSet()
    NewExterior_GemEffect_Show()
    
end

--整理
function NewExterior_GemEffect_ClickClearUpBtn()

end

--打开展示柜
function NewExterior_GemEffect_OpenYiRongGe()
    NewExterior_GemEffect_SavePosition()
    Exterior:LuaFnAskExteriorYiRongGeInfo(1, 2)
end

--切换子女时装
function NewExterior_GemEffect_OpenInfant()    
    NewExterior_GemEffect_SavePosition()
    Exterior:LuaFnInitExteriorFashionList(2, 1)
end

--时装
function NewExterior_GemEffect_OpenFashion()
    local cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
    Exterior:LuaFnExteriorFashionDepotItemClick(g_PlayerfashionDepotType, cacheExteriorIdx)
    --NewExterior_GemEffect_SavePosition()
    --PushEvent("OPEN_EXTERIOR_FASHION", 1, 0)
end

--幻武
function NewExterior_GemEffect_OpenWeapon()
    NewExterior_GemEffect_SavePosition()
    Exterior:LuaFnAskOpenExterior(1)
end

--附体
function NewExterior_GemEffect_OpenFuti()
    NewExterior_GemEffect_SavePosition()
    Exterior:LuaFnAskOpenExterior(2)
end

--坐骑
function NewExterior_GemEffect_OpenRide()
    NewExterior_GemEffect_SavePosition()
    Exterior:LuaFnAskOpenExterior(0)
end

--发型
function NewExterior_GemEffect_OpenHair()
    NewExterior_GemEffect_SavePosition()    
    Exterior:LuaFnAskOpenExterior(4)
end

--脸型
function NewExterior_GemEffect_OpenFace()
    NewExterior_GemEffect_SavePosition()    
    Exterior:LuaFnAskOpenExterior(3)
end

--头像
function NewExterior_GemEffect_OpenPortrait()
    NewExterior_GemEffect_SavePosition()    
    Exterior:LuaFnAskOpenExterior(5)
end

--头像框
function NewExterior_GemEffect_OpenFrame()
    NewExterior_GemEffect_SavePosition()    
    Exterior:LuaFnAskOpenExterior(6)
end

function NewExterior_GemEffect_OpenOrnamentsBack()
    NewExterior_GemEffect_SavePosition()    
    OrnamentsScript:AskOrnamentsInfo(0)
end

function NewExterior_GemEffect_OpenOrnamentsHead()
    NewExterior_GemEffect_SavePosition()    
    OrnamentsScript:AskOrnamentsInfo(1)
end

function NewExterior_GemEffect_TakeOffRide()
    local defExteriorID = Exterior:LuaFnGetExteriorInUse(0)
    if defExteriorID == 0 then
        Exterior:LuaFnSetCurrentExteriorSetInfo("RIDE", 0)
        NewExterior_GemEffect_UpdateLeftBtn()
    else
        Exterior:LuaFnSetExteriorInUse(0, 0, 0)
    end
end

function NewExterior_GemEffect_TakeOffWeapon()
    local defExteriorID = Exterior:LuaFnGetExteriorInUse(1)
    if defExteriorID == 0 then
        Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
        NewExterior_GemEffect_UpdateLeftBtn()
        Exterior:LuaFnRestoreExteriorPlayerFittingData(1)
        Exterior:LuaFnUpdateExteriorPlayerData()
    else
        Exterior:LuaFnSetCurrentExteriorSetInfo("WEAPON", 0)
        Exterior:LuaFnSetExteriorInUse(1, 0, 0)
    end
end

function NewExterior_GemEffect_UpdateRedPoint()

    NewExterior_GemEffect_Dress_Tip:Hide()
    
    if Exterior:LuaFnIsHaveExteriorShowTip(0) == 1 then
        NewExterior_GemEffect_Ride_Tip:Show()
    else
        NewExterior_GemEffect_Ride_Tip:Hide()
    end
    
    if Exterior:LuaFnIsHaveExteriorShowTip(1) == 1 then
        NewExterior_GemEffect_Weapon_Tip:Show()
    else
        NewExterior_GemEffect_Weapon_Tip:Hide()
    end
    
    if Exterior:LuaFnIsHaveExteriorShowTip(2) == 1 then
        NewExterior_GemEffect_PetPossJian_Tip:Show()
    else
        NewExterior_GemEffect_PetPossJian_Tip:Hide()
    end
    
    if Exterior:LuaFnIsHaveExteriorShowTip(3) == 1 then
        NewExterior_GemEffect_FaceStyle_Tip:Show()
    else
        NewExterior_GemEffect_FaceStyle_Tip:Hide()
    end
    
    if Exterior:LuaFnIsHaveExteriorShowTip(4) == 1 or Exterior:LuaFnIsHaveHairColorShowTip() == 1 then
        NewExterior_GemEffect_HairStyle_Tip:Show()
    else
        NewExterior_GemEffect_HairStyle_Tip:Hide()
    end
    
    if Exterior:LuaFnIsHaveExteriorShowTip(5) == 1 or Exterior:LuaFnIsHaveExteriorShowTip(6) == 1 then
        NewExterior_GemEffect_PlayerFrame_Tip:Show()
    else
        NewExterior_GemEffect_PlayerFrame_Tip:Hide()
    end

    if Pneuma:GetMF(2959)== 1 or Exterior:LuaFnIsHaveExteriorShowTip(7) == 1 or Exterior:LuaFnIsHaveInfantHairColorShowTip() == 1 then 
        NewExterior_GemEffect_SwitchBtn_Tip:Show()
    else
        NewExterior_GemEffect_SwitchBtn_Tip:Hide()
    end

    if OrnamentsScript:IsHaveOrnamentsShowTip(0) == 1 then
        NewExterior_GemEffect_Widget_Tip:Show()
    else
        NewExterior_GemEffect_Widget_Tip:Hide()
    end

    if OrnamentsScript:IsHaveOrnamentsShowTip(1) == 1 then
        NewExterior_GemEffect_Headdress_Tip:Show()
    else
        NewExterior_GemEffect_Headdress_Tip:Hide()
    end
end

function NewExterior_GemEffect_UpdateLevel()

    for i, ui in (g_GemEffectList or {}) do
        ui.action:SetProperty("Empty", "False")
        ui.action:SetProperty("UseDefaultTooltip", "True")
        ui.action:SetProperty("NormalImage", "")
        ui.action:SetProperty("HoverImage", "")
        ui.action:SetToolTip("")
        ui.action:Hide()
    end

    local szTips = "#{SZTJ_230505_32}"
    local nType = g_CurSelExteriorType
    local nSelID = g_CurSelExteriorID[nType]
    if nType > 0 and nSelID ~= nil and nSelID > 0 then
        local nSelSubID = g_CurSelExteriorSubID[nType] + 1
        local nSubMax = DressStyleScript:GetGemEffectInfo(nSelID, "GemMax")
        for i, ui in (g_GemEffectList or {}) do
            if nSubMax ~= nil and i <= nSubMax then
                -- 进行按钮状态处理
                if nSelSubID == i then
                    ui.try:Show()
                    ui.action:SetPushed(1)
                else
                    ui.try:Hide()
                    ui.action:SetPushed(0)
                end
                local active = DressStyleScript:GetGemEffectActiveInfo(nSelID, i-1, "SubActive")
                if active < 1 then
                    ui.lock:Show()
                else
                    ui.lock:Hide()
                end
                local nGemID = DressStyleScript:GetGemEffectInfo(nSelID, "GemID", i-1)
                if nGemID ~= nil and nGemID > 0 then
                    local strName = DataPool:Lua_GetItemNameByIndex(nGemID)
                    local strIcon = DataPool:LuaFnGetItemIconByTableIndex(nGemID)
                    local strImage = GetIconFullName(strIcon)
                    ui.action:SetProperty("NormalImage", strImage)
                    ui.action:SetProperty("HoverImage", strImage)
                    ui.action:SetToolTip(strName)
                    ui.action:Show()
                end
            end
        end
        --szTips = "等待来源功能"
    end
    --NewExterior_GemEffect_GetTip:SetText(szTips)
end

function NewExterior_GemEffect_CloseSameGroupWindow()
    CloseWindow("SelfEquip", true)
    --CloseWindow("NewExterior_GemEffect", true)
    CloseWindow("NewExterior_Ride", true)
    CloseWindow("NewExterior_Weapon", true)
    CloseWindow("NewExterior_PetPossJian", true)
    CloseWindow("NewExterior_Facestyle", true)
    CloseWindow("NewExterior_HairStyle", true)
    CloseWindow("NewExterior_PlayerFrame", true)
    CloseWindow("NewExterior_Widget", true)
    CloseWindow("NewExterior_Headdress", true)
    CloseWindow("NewExterior_DressBox", true)
    CloseWindow("NewExterior_DressStyle", true)
	CloseWindow("NewExterior_PlanSetting", true)
	CloseWindow("NewExterior_TuJing", true)
end

function NewExterior_GemEffect_CloseOtherWindow()
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

function NewExterior_GemEffect_GenderUpdate()
    local sex = Exterior:LuaFnGetExteriorRaceID()
    if sex ~= nil and g_sexButtonInfo[sex] ~= nil then
        NewExterior_GemEffect_GenderChange_Btn:SetProperty("HoverImage", g_sexButtonInfo[sex].imgH)
        NewExterior_GemEffect_GenderChange_Btn:SetProperty("NormalImage", g_sexButtonInfo[sex].imgN)
        NewExterior_GemEffect_GenderChange_Btn:SetProperty("PushedImage", g_sexButtonInfo[sex].imgP)
    end
end

function NewExterior_GemEffect_SavePosition()
    Variable:SetVariable("ExteriorUnionPos", NewExterior_GemEffect_Frame:GetProperty("UnifiedPosition"), 1)
end

function NewExterior_GemEffect_SetPosition()
    
    local nExteriorUnionPos = Variable:GetVariable("ExteriorUnionPos")
    if nExteriorUnionPos ~= nil then
        NewExterior_GemEffect_Frame:SetProperty("UnifiedPosition", nExteriorUnionPos)
    end

end

function NewExterior_GemEffect_ShowFashionWeaponCheckButton()
    local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
    NewExterior_GemEffect_Dress_Type:SetCheck(IsDisplay)
    
    IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
    NewExterior_GemEffect_Weapon_Type:SetCheck(IsDisplay)

    IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
    NewExterior_GemEffect_Widget_Type:SetCheck(IsDisplay)
    
    IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
    NewExterior_GemEffect_Headdress_Type:SetCheck(IsDisplay)
end

function NewExterior_GemEffect_FashionDisplay()
    local IsDisplay = SystemSetup:LuaFnIsFashionDisplay()
    if IsDisplay == 1 then
        NewExterior_GemEffect_Dress_Type:SetCheck(0)
        SystemSetup:LuaFnCloseFashionDisplay(1)
    else
        NewExterior_GemEffect_Dress_Type:SetCheck(1)
        SystemSetup:LuaFnCloseFashionDisplay(0)
    end    
end

function NewExterior_GemEffect_ExteriorWeaponDisplay()
    local IsDisplay = SystemSetup:LuaFnIsExteriorWeaponDisplay()
    if IsDisplay == 1 then
        NewExterior_GemEffect_Weapon_Type:SetCheck(0)
        SystemSetup:LuaFnCloseExteriorWeaponDisplay(1)
    else
        NewExterior_GemEffect_Weapon_Type:SetCheck(1)
        SystemSetup:LuaFnCloseExteriorWeaponDisplay(0)
    end    
end

function NewExterior_GemEffect_OrnamentsBackDisplay()
    local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(0)
    if IsDisplay == 1 then
        NewExterior_GemEffect_Widget_Type:SetCheck(0)
        SystemSetup:SetOrnamentsDisplayState(0, 1)
        OrnamentsScript:ResetOrnamentsUseInfo(0)
		Exterior:LuaFnUpdateExteriorPlayerData()
    else
        NewExterior_GemEffect_Widget_Type:SetCheck(1)
        SystemSetup:SetOrnamentsDisplayState(0, 0)
        Exterior:LuaFnUpdateExteriorPlayerData()
    end    
end

function NewExterior_GemEffect_OrnamentsHeadDisplay()
    local IsDisplay = OrnamentsScript:GetOrnamentsDisplayState(1)
    if IsDisplay == 1 then
        NewExterior_GemEffect_Headdress_Type:SetCheck(0)
        SystemSetup:SetOrnamentsDisplayState(1, 1)
        OrnamentsScript:ResetOrnamentsUseInfo(1)
		Exterior:LuaFnUpdateExteriorPlayerData()
    else
        NewExterior_GemEffect_Headdress_Type:SetCheck(1)
        SystemSetup:SetOrnamentsDisplayState(1, 0)
        Exterior:LuaFnUpdateExteriorPlayerData()
    end    
end

function NewExterior_GemEffect_ActionToOrnamentsBack()
    local useID = OrnamentsScript:GetOrnamentsUseID(0)
    if useID > 0 then
        OrnamentsScript:TakeOffOrnaments(0)
    end
    Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSBACK", 0, 0, 0, 0)
    NewExterior_GemEffect_UpdateLeftBtn()
    Exterior:LuaFnRestoreExteriorPlayerFittingData(6)
    Exterior:LuaFnUpdateExteriorPlayerData()
end

function NewExterior_GemEffect_ActionToOrnamentsHead()
    local useID = OrnamentsScript:GetOrnamentsUseID(1)
    if useID > 0 then
        OrnamentsScript:TakeOffOrnaments(1)
    end
    Exterior:LuaFnSetCurrentExteriorSetInfo("ORNAMENTSHEAD", 0, 0, 0, 0)
    NewExterior_GemEffect_UpdateLeftBtn()
    Exterior:LuaFnRestoreExteriorPlayerFittingData(7)
    Exterior:LuaFnUpdateExteriorPlayerData()
end

function NewExterior_GemEffect_OpenFashion()
    NewExterior_GemEffect_SavePosition()
    PushEvent("OPEN_EXTERIOR_FASHION", 1, 0)
end

function NewExterior_GemEffect_OpenDressStyle()
    NewExterior_GemEffect_SavePosition()
    PushEvent("OPEN_EXTERIOR_DRESSSTYLE")
end

function NewExterior_GemEffect_PreviewTips()
    local needTips = 1
    local cacheExteriorID,cacheExteriorSubID = Exterior:LuaFnGetCurrentExteriorSetInfo("DRESSSTYLE")
    if cacheExteriorID ~= nil and cacheExteriorID > 0 then
        needTips = 0
    else
        --时装
        cacheExteriorID, cacheExteriorIdx = Exterior:LuaFnGetCurrentExteriorSetInfo("FASHION")
        if cacheExteriorID ~= nil and cacheExteriorID > 0 then
            needTips = 0
        else
            local nCurFashionId, nCurFashionIdx = Exterior:LuaFnGetExteriorFashionInUse()
            if nCurFashionId ~= nil and nCurFashionId > 0 then
                needTips = 0
            end
        end
    end
    if needTips > 0 then
        PushDebugMessage("#{SZTJ_230505_41}")
    end

    return needTips
end

-- 关闭来源
function NewExterior_GemEffect_CloseTuJing()
	if IsWindowShow("NewExterior_TuJing") then
		CloseWindow("NewExterior_TuJing", true)
	end
end

-- 来源
function NewExterior_GemEffect_ClickTuJing()
	if g_CurSelExteriorID[g_CurSelExteriorType] ~= nil and g_CurSelExteriorID[g_CurSelExteriorType] > 0 then		
		PushEvent("OPEN_EXTERIOR_TUJING", 103, g_CurSelExteriorID[g_CurSelExteriorType], -1, -1)
	else
		PushDebugMessage("#{SZDP_230509_64}")
	end
end

-- 更改性别
function NewExterior_GemEffect_ChangeSex()
    local sex = Exterior:LuaFnGetExteriorRaceID()
    if sex ~= nil then
        if sex == g_PlayerRace.SEX_FEMALE then
            Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_MALE)
        elseif sex == g_PlayerRace.SEX_MALE then
            Exterior:LuaFnSetCurrentExteriorSetInfo("SEX", g_PlayerRace.SEX_FEMALE)
        end
        NewExterior_GemEffect_Show()
    end
end

-- 图鉴页签
function NewExterior_GemEffect_PageButtonUpdate()
    NewExterior_GemEffect_GoTo_DressBox:SetCheck(0)
    NewExterior_GemEffect_GoTo_DressStyle:SetCheck(0)
    NewExterior_GemEffect_GoTo_GemEffect:SetCheck(1)
end
--!!!reloadscript =NewExterior_GemEffect