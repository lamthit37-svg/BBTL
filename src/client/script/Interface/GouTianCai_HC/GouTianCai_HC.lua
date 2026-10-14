-- 中级、高级勾天彩合成数量输入UI

-- 保存UI默认位置
local GouTianCai_HC_UnifiedPosition = nil

-- UICommand
local GouTianCai_HC_UICommand_Index = 2021102201

local GouTianCai_HC_TargetId = -1
local GouTianCai_HC_MergeType = -1
local GouTianCai_HC_MaxNum = -1

-- 关注NPC
local GouTianCai_HC_CareObjId = -1
local GouTianCai_HC_CareObjSvrId = -1
local GouTianCai_HC_MAX_OBJ_DISTANCE = 5.0



function GouTianCai_HC_PreLoad()
    this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func GouTianCai_HC_PreLoad()

function GouTianCai_HC_OnEvent(event)
    if (event == "UI_COMMAND") then
        if (tonumber(arg0) == GouTianCai_HC_UICommand_Index) then
            local targetSvrId = Get_XParam_INT(0)
            local mergeType = Get_XParam_INT(1)
            local totalNum = Get_XParam_INT(2)
            local strMsg = Get_XParam_STR(0)

            -- 开启UI
            GouTianCai_HC_Show()

            -- 设置要关注的NPCID
            local targetId = DataPool:GetNPCIDByServerID(tonumber(targetSvrId))
            GouTianCai_HC_BeginCareObject(tonumber(targetSvrId), targetId)

            -- 设置可合成的最大值
            GouTianCai_HC_MaxNum = tonumber(totalNum)

            -- 更新UI数据
            GouTianCai_HC_UpdateInfo(tonumber(mergeType), strMsg)
        end
    elseif (event == "OBJECT_CARED_EVENT") then
		-- 这个事件目前已经被干掉了
		-- 要调整关注距离直接去改代码吧 ObjectManager.cpp CObjectManager::Tick(VOID)
		if(tonumber(arg0) ~= GouTianCai_HC_CareObjId) then
			return
		end

		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2) > GouTianCai_HC_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			-- 关闭
			GouTianCai_HC_Hide()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		GouTianCai_HC_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		GouTianCai_HC_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		GouTianCai_HC_UnifiedPos()
	end
end -- end func GouTianCai_HC_OnEvent()

function GouTianCai_HC_OnLoad()
	GouTianCai_HC_UnifiedPosition = GouTianCai_HC_Frame:GetProperty("UnifiedPosition")
end -- end func GouTianCai_HC_OnLoad()

-- 界面默认位置
function GouTianCai_HC_UnifiedPos()
	if (GouTianCai_HC_UnifiedPosition ~= nil) then
		GouTianCai_HC_Frame:SetProperty("UnifiedPosition", GouTianCai_HC_UnifiedPosition)
	end
end -- end func GouTianCai_HC_UnifiedPos()

-- 开启NPC关注
function GouTianCai_HC_BeginCareObject(objSvrId, objId)
	GouTianCai_HC_CareObjId = objId
	GouTianCai_HC_CareObjSvrId = objSvrId
	if (GouTianCai_HC_CareObjId >= 0) then
		this:CareObject(GouTianCai_HC_CareObjId, 1, "GouTianCai_HC")
	end
end -- end func GouTianCai_HC_BeginCareObject()

-- 取消NPC关注
function GouTianCai_HC_StopCareObject(objId)
	if (objId >= 0) then
		this:CareObject(objId, 0, " GouTianCai_HC")
    end
    
    GouTianCai_HC_CareObjId = -1
	GouTianCai_HC_CareObjSvrId = -1
end -- end func GouTianCai_HC_StopCareObject()

-- 打开UI
function GouTianCai_HC_Show()
    GouTianCai_HC_MergeType = -1
    GouTianCai_HC_MaxNum = -1
    this:Show()
end -- end func GouTianCai_HC_Show()

-- 关闭UI
function GouTianCai_HC_Hide()
    GouTianCai_HC_StopCareObject(GouTianCai_HC_CareObjId)
    GouTianCai_HC_MergeType = -1
    GouTianCai_HC_MaxNum = -1
    this:Hide()
end -- end func GouTianCai_HC_Hide()

-- 关闭按钮事件
function GouTianCai_HC_OnClose()
    GouTianCai_HC_Hide()
end -- end func GouTianCai_HC_OnClose()

-- 确定按钮事件
function GouTianCai_HC_OnOK()
    -- 获取输入的合成数量
    local numText = GouTianCai_HC_InputValue:GetText()
    if (numText == nil or numText == "") then
        PushDebugMessage("#{GTCHC_211025_05}")
        return
    end
    local mergeNum = tonumber(numText)
    if (mergeNum < 1) then
        PushDebugMessage("#{GTCHC_211025_05}")
        return
    end

    -- 执行脚本
	Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("GoutiancaiMerge_New")
        Set_XSCRIPT_ScriptID(890674)
        Set_XSCRIPT_Parameter(0, GouTianCai_HC_CareObjSvrId)
        Set_XSCRIPT_Parameter(1, GouTianCai_HC_MergeType)
        Set_XSCRIPT_Parameter(2, mergeNum)
        Set_XSCRIPT_ParamCount(3)
    Send_XSCRIPT()

    -- 关闭UI
    GouTianCai_HC_Hide()
end -- end func GouTianCai_HC_OnOK()

-- 取消按钮事件
function GouTianCai_HC_OnCancel()
    GouTianCai_HC_Hide()
end -- end func GouTianCai_HC_OnCancel()

-- 合成数量输入事件
function GouTianCai_HC_OnMegerNumTextChange()
    local numText = GouTianCai_HC_InputValue:GetText()
    if (numText == nil or  numText == "") then
        return
    end

    local mergeNum = tonumber(numText)
    if (mergeNum < 1) then
        --GouTianCai_HC_InputValue:SetProperty("DefaultEditBox", "True")
        GouTianCai_HC_InputValue:SetText(tostring(GouTianCai_HC_MaxNum))
        --GouTianCai_HC_InputValue:SetSelected(0, -1)

        PushDebugMessage("#{GTCHC_211025_05}")
        return
    end

    if (GouTianCai_HC_MaxNum ~= nil and GouTianCai_HC_MaxNum > 0) then
        if (mergeNum > GouTianCai_HC_MaxNum) then
            GouTianCai_HC_InputValue:SetText(tostring(GouTianCai_HC_MaxNum))
            return
        end
    end
end -- end func GouTianCai_HC_OnMegerNumTextChange()

-- 刷新UI数据
function GouTianCai_HC_UpdateInfo(mergeType, msg)
    GouTianCai_HC_MergeType = mergeType

    -- 设置提示内容
    GouTianCai_HC_Info:SetText(msg)

    -- 设置数量默认值
    GouTianCai_HC_InputValue:SetProperty("DefaultEditBox", "True")
    GouTianCai_HC_InputValue:SetText(tostring(GouTianCai_HC_MaxNum))
    GouTianCai_HC_InputValue:SetSelected(0, -1)

    return 1
end -- end func GouTianCai_HC_UpdateInfo()