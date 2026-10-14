-- 上缴乱匪密函兑换奖励数量输入UI

local LuanFeiMiHan_UnifiedPosition = nil
local LuanFeiMiHan_MiHanNum = -1
local LuanFeiMiHan_MaxNum = -1
local LuanFeiMiHan_ServerNPCObjId = -1
local LuanFeiMiHan_CareObjId = -1

-- 兑换的奖励类型及其物品ID
local LuanFeiMiHan_ItemType = -1
local LuanFeiMiHan_ItemId = {
    38000571, 30900045, 20502003, 20501003, 30008130, 38000382
}

function LuanFeiMiHan_PreLoad()
    this:RegisterEvent("UI_COMMAND")
    -- this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)    -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS", false)              -- 窗口尺寸发生变化
end

function LuanFeiMiHan_OnEvent(event)
    if (event == "UI_COMMAND") then
        if (tonumber(arg0) == 51370001) then
            -- 当前拥有的密函数量
            LuanFeiMiHan_MiHanNum = Get_XParam_INT(0)

            -- 兑换的奖励类型
            LuanFeiMiHan_ItemType = Get_XParam_INT(1)
            if not LuanFeiMiHan_ItemId[LuanFeiMiHan_ItemType] then
                PushDebugMessage("[LuanFeiMiHan] invalid item type")
                return
            end

            -- 可兑换的最大值
            LuanFeiMiHan_MaxNum = Get_XParam_INT(2)

            -- 设置要关注的NPCID
            LuanFeiMiHan_ServerNPCObjId = Get_XParam_INT(3)
            local targetId = DataPool:GetNPCIDByServerID(LuanFeiMiHan_ServerNPCObjId)
            LuanFeiMiHan_BeginCareObject(targetId)

            -- 显示界面
            this:Show()

            -- 更新UI数据
            LuanFeiMiHan_UpdateInfo()
        end

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		LuanFeiMiHan_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		LuanFeiMiHan_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		LuanFeiMiHan_UnifiedPos()

    -- elseif (event == "OBJECT_CARED_EVENT") then
		-- 这个事件目前已经被干掉了
		-- 要调整关注距离直接去改代码吧 ObjectManager.cpp CObjectManager::Tick(VOID)
	end
end

function LuanFeiMiHan_OnLoad()
	LuanFeiMiHan_UnifiedPosition = LuanFeiMiHan_Frame:GetProperty("UnifiedPosition")
end

-- 界面默认位置
function LuanFeiMiHan_UnifiedPos()
	if (LuanFeiMiHan_UnifiedPosition ~= nil) then
		LuanFeiMiHan_Frame:SetProperty("UnifiedPosition", LuanFeiMiHan_UnifiedPosition)
	end
end

-- 开启NPC关注
function LuanFeiMiHan_BeginCareObject(objId)
	LuanFeiMiHan_CareObjId = objId
	if (LuanFeiMiHan_CareObjId >= 0) then
		this:CareObject(LuanFeiMiHan_CareObjId, 1, "LuanFeiMiHan")
	end
end

-- 取消NPC关注
function LuanFeiMiHan_StopCareObject(objId)
	if (objId >= 0) then
		this:CareObject(objId, 0, "LuanFeiMiHan")
    end
    LuanFeiMiHan_CareObjId = -1
    LuanFeiMiHan_ServerNPCObjId = -1
end

-- 关闭UI
function LuanFeiMiHan_Hide()
    LuanFeiMiHan_StopCareObject(LuanFeiMiHan_CareObjId)
    LuanFeiMiHan_MiHanNum = -1
    LuanFeiMiHan_ItemType = -1
    LuanFeiMiHan_MaxNum = -1
    this:Hide()
end

-- 关闭、取消按钮事件
function LuanFeiMiHan_Close_Clicked()
    LuanFeiMiHan_Hide()
end

-- 确定按钮事件
function LuanFeiMiHan_Btn_OK_Clicked()
    -- 获取输入的兑换数量
    local numText = LuanFeiMiHan_Input_Num:GetText()
    if (numText == nil or numText == "") then
        return
    end
    local num = tonumber(numText)
    if (num < 1) then
        local itemName = DataPool:Lua_GetItemNameByIndex(LuanFeiMiHan_ItemId[LuanFeiMiHan_ItemType])
        PushDebugMessage(ScriptGlobal_Format("#{LFMH_240828_14}", itemName))
        return
    end

    -- 执行脚本
	Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("OnClientExchange")
        Set_XSCRIPT_ScriptID(005137)
        Set_XSCRIPT_Parameter(0, LuanFeiMiHan_ItemType)
        Set_XSCRIPT_Parameter(1, num)
        Set_XSCRIPT_Parameter(2, LuanFeiMiHan_ServerNPCObjId)
        Set_XSCRIPT_ParamCount(3)
    Send_XSCRIPT()

    -- 关闭UI
    LuanFeiMiHan_Hide()
end


-- 兑换数量输入事件
function LuanFeiMiHan_OnInputNumTextChange()
    local numText = LuanFeiMiHan_Input_Num:GetText()
    if (numText == nil or numText == "") then
        return
    end

    local num = tonumber(numText)
    if not num or num < 0 then
        --LuanFeiMiHan_Input_Num:SetProperty("DefaultEditBox", "True")
        LuanFeiMiHan_Input_Num:SetText("0")
        --LuanFeiMiHan_Input_Num:SetSelected(0, -1)
        return
    end

    if (LuanFeiMiHan_MaxNum ~= nil and LuanFeiMiHan_MaxNum > 0) then
        if (num > LuanFeiMiHan_MaxNum) then
            LuanFeiMiHan_Input_Num:SetText(tostring(LuanFeiMiHan_MaxNum))
            return
        end
    end
end

-- 刷新UI数据
function LuanFeiMiHan_UpdateInfo()
    -- 设置标题
    local itemName = DataPool:Lua_GetItemNameByIndex(LuanFeiMiHan_ItemId[LuanFeiMiHan_ItemType])
    LuanFeiMiHan_DragTitle:SetText(ScriptGlobal_Format("#{LFMH_240828_9}", itemName))

    -- 设置提示内容
    local msg = ScriptGlobal_Format("#{LFMH_240828_10}", LuanFeiMiHan_MiHanNum, LuanFeiMiHan_MaxNum, itemName)
    LuanFeiMiHan_Info_Text:SetText(msg)

    -- 设置数量默认值
    LuanFeiMiHan_Input_Num:SetProperty("DefaultEditBox", "True")
    LuanFeiMiHan_Input_Num:SetText(tostring(LuanFeiMiHan_MaxNum))
    LuanFeiMiHan_Input_Num:SetSelected(0, -1)

    return 1
end