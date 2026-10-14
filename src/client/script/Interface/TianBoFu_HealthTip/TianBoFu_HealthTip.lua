--=========================================================
-- 叶二娘 血量差UI
--=========================================================
--控件列表
local m_Controls = {} 				--控件列表
local g_Frame_UnifiedPosition

local yerniang_image = 
{  
    [0] = "Ceng0",
    [1] = "Ceng1",
    [2] = "Ceng2",
    [3] = "Ceng3",
    [4] = "Ceng4",
    [5] = "Ceng5",
    [6] = "Ceng6",
    [7] = "Ceng7",
    [8] = "Ceng8",
    [9] = "Ceng9",
}

function TianBoFu_HealthTip_PreLoad()

    this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("ADJEST_UI_POS",false)           -- 游戏窗口尺寸发生了变化
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		    -- 离开场景

end

function TianBoFu_HealthTip_OnLoad()

    m_Controls = 
    {
		m_Frame = TianBoFu_HealthTip_Frame,
    }
    
    g_Frame_UnifiedPosition=m_Controls.m_Frame:GetProperty("UnifiedPosition")

end

function TianBoFu_HealthTip_OnEvent(event)

    if ( event == "UI_COMMAND" and tonumber(arg0) == 99805002 ) then
        local isOn = Get_XParam_INT(0) 
        local Dif1 = Get_XParam_INT(1)
        local Dif2 = Get_XParam_INT(2)  
        --关闭
        if isOn == 0 then
            -- Close()
            TianBoFu_HealthTip_OnClosed()
        --打开
        elseif isOn == 1 then
            -- Open()
            TianBoFu_HealthTip_Open(Dif1,Dif2)
        --狂暴
        elseif isOn == 2 or isOn == 3 then
            TianBoFu_HealthTip_KuangBao(isOn)
        end
    elseif (event == "ADJEST_UI_POS") then
		TianBoFu_HealthTip_Frame_On_ResetPos()    
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
        TianBoFu_HealthTip_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        TianBoFu_HealthTip_OnClosed()
    end
    
end

function TianBoFu_HealthTip_Frame_On_ResetPos()
    m_Controls.m_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--===============================================
-- Close()
--===============================================
function TianBoFu_HealthTip_OnClosed()
	this:Hide()
end


--===============================================
-- Open()
--===============================================
function TianBoFu_HealthTip_Open(Dif1,Dif2)

    -- --十位
    -- TianBoFu_HealthTip_1BKG:Show()
    -- TianBoFu_HealthTip_1BKG:SetImage("GuanShanHai03",yerniang_image[Dif1])
    -- --个位
    -- TianBoFu_HealthTip_2BKG:Show()
    -- TianBoFu_HealthTip_2BKG:SetImage("GuanShanHai03",yerniang_image[Dif2])

    --图片
    --TianBoFu_HealthTip_Frenzy:Hide()
    --%号
    TianBoFu_HealthTip_ClentText:Show()
    
    local baifenbi = Dif1*10 + Dif2
    TianBoFu_HealthTip_ClentText:SetText(ScriptGlobal_Format("#{YTTBF_220524_252}",baifenbi))   

	this:Show()
end

--===============================================
-- 狂暴()
--===============================================
function TianBoFu_HealthTip_KuangBao(KB)

    -- --十位
    -- TianBoFu_HealthTip_1BKG:Hide()
    -- --个位
    -- TianBoFu_HealthTip_2BKG:Hide()

    --图片
    --TianBoFu_HealthTip_Frenzy:Show()
    --%号
    TianBoFu_HealthTip_ClentText:Show()

    if KB == 3 then
        TianBoFu_HealthTip_ClentText:SetText("#{YTTBF_220524_285}")  
    else
        TianBoFu_HealthTip_ClentText:SetText("#{YTTBF_220524_284}")  
    end
    
	this:Show()
end

