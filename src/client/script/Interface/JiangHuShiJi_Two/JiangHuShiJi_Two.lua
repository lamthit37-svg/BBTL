local g_JiangHuShiJi_Two_UnifiedPosition   
local g_JiangHuShiJi_Two_isShow = 0;   
local g_JiangHuShiJi_Two_isredflash = 0;   
--=========
-- PreLoad()
--=========
function JiangHuShiJi_Two_PreLoad() 
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)  
	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
end

--=========
-- OnLoad()
--=========
function JiangHuShiJi_Two_OnLoad() 
	g_JiangHuShiJi_Two_UnifiedPosition = JiangHuShiJi_Two_Frame:GetProperty("UnifiedPosition") 
end

--=========
-- Event
--=========
function JiangHuShiJi_Two_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 88892805) then
        g_JiangHuShiJi_Two_isShow 		= Get_XParam_INT(0)   
        g_JiangHuShiJi_Two_isredflash 		= Get_XParam_INT(1)   
        if g_JiangHuShiJi_Two_isShow == 1 then  
            this:Show()
            if g_JiangHuShiJi_Two_isredflash == 0 then
                JiangHuShiJi_Two_Tips:Show()  
                JiangHuShiJi_Two_JiangLi_Btn_Animate:Show()
            end
        else
            this:Hide()
        end
	end

end
 

--=========
-- 重置
--=========
function JiangHuShiJi_Two_On_ResetPos()
	JiangHuShiJi_Two_Frame:SetProperty("UnifiedPosition", g_JiangHuShiJi_Two_UnifiedPosition) 
end

function JiangHuShiJi_Two_OnHiden()
    this:Hide()
end

function JiangHuShiJi_Two_JiangLi_Btn_Click() 
    JiangHuShiJi_Two_JiangLi_Btn_Animate:Hide()
    JiangHuShiJi_Two_Tips:Hide()
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name( "OpenXianShi" ); 					-- 脚本函数名称
    Set_XSCRIPT_ScriptID( 888928 );											-- 脚本编号 
    Set_XSCRIPT_ParamCount( 0 ); 	-- 参数个数 
    Send_XSCRIPT() 
end