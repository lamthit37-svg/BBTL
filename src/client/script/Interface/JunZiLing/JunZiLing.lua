-- JunZiLing
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_ItemID = 0
local g_MaxAddNum = 200
local g_CurMaxAddNum = 0
local g_MinAddNum = 0
local g_AddNum = 0
local g_PerNeedYB = 0
local g_ButtonLastTime =0
local g_ButtonCDTime = 2

local g_YBNum_TLZ = 100


function JunZiLing_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
    this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("UPDATE_YUANBAO",false)
end

function JunZiLing_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		JunZiLing_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		JunZiLing_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
        this:Hide()
    elseif (event == "UPDATE_YUANBAO") then
        JunZiLing_UpdateYuanBao()
    elseif event == "UI_COMMAND" and (tonumber(arg0) == 99961401) then	--服务端传数据
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
            g_ItemID = Get_XParam_INT(1)
            JunZiLing_Open()
        end
	end
end

function JunZiLing_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= JunZiLing_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= JunZiLing_Frame:GetProperty("UnifiedYPosition")
end

function JunZiLing_Open()
    g_AddNum = 1
    JunZiLing_InputNum:SetProperty("DefaultEditBox", "True")
    JunZiLing_InputNum:SetText("1")
    JunZiLing_InputNum:SetSelected(0, -1)
    local nHaveYuanbao =  Player:GetData( "YUANBAO" )
    g_PerNeedYB = g_YBNum_TLZ

	if nHaveYuanbao >= g_PerNeedYB then
		JunZiLing_Cash_Yuanbao:SetText(ScriptGlobal_Format("#{SFDJ_240117_87}",tostring(nHaveYuanbao)))
	else
		JunZiLing_Cash_Yuanbao:SetText(ScriptGlobal_Format("#{SFDJ_240117_89}",tostring(nHaveYuanbao)))
	end
    JunZiLing_Price_Yuanbao:SetText(tostring(g_PerNeedYB))
    this:Show()
end

function JunZiLing_EditEnter()
    if g_CurMaxAddNum == 0 then
        g_CurMaxAddNum = 1
    end
    
    if g_PerNeedYB == 0 then
        return
    end
    
    --获取数量
    local num = tonumber(JunZiLing_InputNum:GetText())
    local nHaveYuanbao =  Player:GetData( "YUANBAO" )
    local nHaveMaxNum = math.floor(nHaveYuanbao / g_PerNeedYB)
    if nHaveMaxNum <= g_MaxAddNum then
        g_CurMaxAddNum = nHaveMaxNum
    elseif nHaveMaxNum > g_MaxAddNum then
        g_CurMaxAddNum = g_MaxAddNum
    end
    
    if nil == num then
        num = 0
    elseif num > g_CurMaxAddNum then
        num = g_CurMaxAddNum
        JunZiLing_InputNum:SetText(tostring(num))
    elseif num < g_MinAddNum then
        num = g_MinAddNum
        JunZiLing_InputNum:SetText(tostring(num))

    end

    --计算所需元宝数
    --刷新玩家元宝数

    local nNeedYuanbao = num * g_PerNeedYB

    JunZiLing_Price_Yuanbao:SetText(tostring(nNeedYuanbao))
	
   if nHaveYuanbao >= nNeedYuanbao then
		JunZiLing_Cash_Yuanbao:SetText(ScriptGlobal_Format("#{SFDJ_240117_87}",tostring(nHaveYuanbao)))
	else
		JunZiLing_Cash_Yuanbao:SetText(ScriptGlobal_Format("#{SFDJ_240117_89}",tostring(nHaveYuanbao)))
	end

    g_AddNum = num
end

function JunZiLing_UpdateYuanBao()
    local nHaveYuanbao =  Player:GetData( "YUANBAO" )
    local nNeedYuanbao = g_AddNum * g_PerNeedYB

    if nHaveYuanbao >= nNeedYuanbao then
		JunZiLing_Cash_Yuanbao:SetText(ScriptGlobal_Format("#{SFDJ_240117_87}",tostring(nHaveYuanbao)))
	else
		JunZiLing_Cash_Yuanbao:SetText(ScriptGlobal_Format("#{SFDJ_240117_89}",tostring(nHaveYuanbao)))
	end
end

function JunZiLing_OnMax()
    if g_PerNeedYB == 0 then
        return
    end
    
    local nHaveYuanbao =  Player:GetData( "YUANBAO" )
    local nHaveMaxNum = math.floor(nHaveYuanbao / g_PerNeedYB)
    if nHaveMaxNum <= g_MaxAddNum then
        g_CurMaxAddNum = nHaveMaxNum
    elseif nHaveMaxNum > g_MaxAddNum then
        g_CurMaxAddNum = g_MaxAddNum
    end
    
    JunZiLing_InputNum:SetText(tostring(g_CurMaxAddNum))
    JunZiLing_EditEnter()
end

function JunZiLing_OK_Clicked()
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then
 	 	PushDebugMessage("#{SFDJ_240117_152}"); --不可连续点击，请稍等片刻后再点击
   		return;
   	end
   	g_ButtonLastTime = curTime;
	
    if "" == JunZiLing_InputNum:GetText() then
        PushDebugMessage("#{SFDJ_240117_153}")
        return 
    end
    
    if g_AddNum == nil or g_AddNum <= 0 then
        PushDebugMessage("#{SFDJ_240117_168}")
        return       
    end
    
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name( "OnCreateNpcOnce" )
    Set_XSCRIPT_ScriptID( 999614 )
    Set_XSCRIPT_Parameter(0,g_ItemID)
    Set_XSCRIPT_Parameter(1,g_AddNum)
    Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end

function JunZiLing_Close_Clicked()
    this:Hide()
end

--================================================
-- 界面的默认相对位置
--================================================
function JunZiLing_ResetPos()
	JunZiLing_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	JunZiLing_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function JunZiLing_OnHiden()
    JunZiLing_InputNum:SetProperty("DefaultEditBox", "False")
end