local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

--******************************
--战令补充进度界面
--******************************

local g_CurMonthPoint = 0
local g_MaxAddNum = 0
local g_MinAddNum = 0
local g_AddNum = 0


function Fuli_ZhanLing_Replenish_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
    this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("UPDATE_YUANBAO",false)
end

function Fuli_ZhanLing_Replenish_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		Fuli_ZhanLing_Replenish_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Fuli_ZhanLing_Replenish_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
        this:Hide()
    elseif (event == "UPDATE_YUANBAO") then
        Fuli_ZhanLing_Replenish_UpdateYuanBao()
    elseif event == "UI_COMMAND" and (tonumber(arg0) == 79002903) then	--服务端传数据
        local optType = Get_XParam_INT(0)	--界面操作类型（0 关闭，1打开， 2刷新）
        if 0 == optType then
            --关闭
            this:Hide()
        end 
        if  2 == optType and not this:IsVisible() then
            return 
        end
        if 1 == optType or 2 == optType then
            --打开或刷新
            g_CurMonthPoint = Get_XParam_INT(1)
            g_MaxAddNum = Get_XParam_INT(2)
            g_MinAddNum = Get_XParam_INT(3)
            Fuli_ZhanLing_Replenish_Open()
        end
	end
end

function Fuli_ZhanLing_Replenish_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Fuli_ZhanLing_Replenish_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= Fuli_ZhanLing_Replenish_Frame:GetProperty("UnifiedYPosition")
end

function Fuli_ZhanLing_Replenish_Open()
    g_AddNum = 1
    Fuli_ZhanLing_Replenish_ItemNumberInput:SetProperty("DefaultEditBox", "True")
    Fuli_ZhanLing_Replenish_ItemNumberInput:SetText("1")
    Fuli_ZhanLing_Replenish_ItemNumberInput:SetSelected(0, -1)
    local nHaveYuanbao =  Player:GetData( "YUANBAO" )
    local strMsg = "#{TLZL_190802_155}"
    if 4 > nHaveYuanbao then
        strMsg = "#{TLZL_190802_154}"
    end
    Fuli_ZhanLing_Replenish_Cash1:SetText(ScriptGlobal_Format(strMsg,tostring(nHaveYuanbao)))
    Fuli_ZhanLing_Replenish_Price1:SetText("#L4")
    local pointStr = "#cff0000"..tostring(g_CurMonthPoint)
    if g_CurMonthPoint >= 5000 then
        pointStr = "#M"..tostring(g_CurMonthPoint)
    end
    Fuli_ZhanLing_Replenish_InfoText:SetText(ScriptGlobal_Format("#{TLZL_190802_148}",pointStr))
    this:Show()
end

function Fuli_ZhanLing_Replenish_EditEnter()
    if g_MaxAddNum == 0 then
        g_MaxAddNum = 1
    end
    --获取数量
    local num = tonumber(Fuli_ZhanLing_Replenish_ItemNumberInput:GetText())
    
    if nil == num then
        num = 0
    elseif num > g_MaxAddNum then
        num = g_MaxAddNum
        Fuli_ZhanLing_Replenish_ItemNumberInput:SetText(tostring(num))
    elseif num < g_MinAddNum then
        num = g_MinAddNum
        Fuli_ZhanLing_Replenish_ItemNumberInput:SetText(tostring(num))

    end

    --计算所需元宝数
    --刷新玩家元宝数
    local nHaveYuanbao =  Player:GetData( "YUANBAO" )
    local nNeedYuanbao = num * 4
    local strMsg = "#{TLZL_190802_155}"
    if nNeedYuanbao > nHaveYuanbao then
        strMsg = "#{TLZL_190802_154}"
    end
    Fuli_ZhanLing_Replenish_Price1:SetText("#L"..tostring(nNeedYuanbao))

    Fuli_ZhanLing_Replenish_Cash1:SetText(ScriptGlobal_Format(strMsg,tostring(nHaveYuanbao)))

    g_AddNum = num
end

function Fuli_ZhanLing_Replenish_UpdateYuanBao()
    local strMsg = "#{TLZL_190802_155}"
    local nHaveYuanbao =  Player:GetData( "YUANBAO" )
    local nNeedYuanbao = g_AddNum * 4
    if nNeedYuanbao > nHaveYuanbao then
        strMsg = "#{TLZL_190802_154}"
    end
    Fuli_ZhanLing_Replenish_Cash1:SetText(ScriptGlobal_Format(strMsg,tostring(nHaveYuanbao)))
end

function Fuli_ZhanLing_Replenish_OnMax()
    Fuli_ZhanLing_Replenish_ItemNumberInput:SetText(tostring(g_MaxAddNum))
    Fuli_ZhanLing_Replenish_EditEnter()
end

function Fuli_ZhanLing_Replenish_OK_Clicked()
    if "" == Fuli_ZhanLing_Replenish_ItemNumberInput:GetText() then
        PushDebugMessage("#{TLZL_190802_159}")
        return 
    end
    --通知服务端脚本传数据
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name( "AskAddProgress" )
    Set_XSCRIPT_ScriptID( 790029 )
    Set_XSCRIPT_Parameter(0,g_AddNum)
    Set_XSCRIPT_Parameter(1,1)
    Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end

function Fuli_ZhanLing_Replenish_Close_Clicked()
    this:Hide()
end

--================================================
-- 界面的默认相对位置
--================================================
function Fuli_ZhanLing_Replenish_ResetPos()
	Fuli_ZhanLing_Replenish_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Fuli_ZhanLing_Replenish_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Fuli_ZhanLing_Replenish_OnHiden()
    Fuli_ZhanLing_Replenish_ItemNumberInput:SetProperty("DefaultEditBox", "False")
end