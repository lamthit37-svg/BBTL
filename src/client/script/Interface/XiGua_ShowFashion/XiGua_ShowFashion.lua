-- 时装兑换

local g_Frame_UnifiedPosition

local g_XiGua_ShowFashion_CurYLZ = 0

--=========
-- PreLoad
--=========
function XiGua_ShowFashion_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)

end

--=========
-- OnLoad
--=========
function XiGua_ShowFashion_OnLoad()

	g_Frame_UnifiedPosition = XiGua_ShowFashion_Frame:GetProperty("UnifiedPosition") 
		
end

--=========
-- OnEvent
--=========
function XiGua_ShowFashion_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 88808202 then

		if 1 == 1 then
			XiGua_ShowFashion_OnHiden()
			return
		end
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			g_XiGua_ShowFashion_CurYLZ = Get_XParam_INT(1)
			XiGua_ShowFashion_HaveText:SetText(ScriptGlobal_Format("#{MZXB_200609_80}", tostring(g_XiGua_ShowFashion_CurYLZ)) )
			
			XiGua_ShowFashion_Update()			
		else
			XiGua_ShowFashion_OnHiden()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		XiGua_ShowFashion_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		XiGua_ShowFashion_On_ResetPos()
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
	
		XiGua_ShowFashion_OnHiden();
		
	elseif event == "PACKAGE_ITEM_CHANGED_EX" then
	
		XiGua_ShowFashion_UpdateYuLianZiValue()
		
	end

end

function XiGua_ShowFashion_UpdateYuLianZiValue()	

	if IsWindowShow("XiGua_ShowFashion") then		
		g_XiGua_ShowFashion_CurYLZ = PlayerPackage:CountAvailableItemByIDTable(38004800)
		XiGua_ShowFashion_HaveText:SetText(ScriptGlobal_Format("#{MZXB_200609_80}", tostring(g_XiGua_ShowFashion_CurYLZ)) )
	end
	
end	

--=========
-- 打开
--=========
function XiGua_ShowFashion_Update()		

	this:Show()

	local theAction = DataPool:CreateActionItemForShow(10126161, 1)
	if theAction:GetID() ~= 0 then
		XiGua_ShowFashion_Clothe:SetActionItem(theAction:GetID())
	end
	
end

--=========
-- 关闭
--=========
function XiGua_ShowFashion_OnHiden()
	
	if(IsWindowShow("XiGua_FashionShow")) then
		CloseWindow("XiGua_FashionShow", true)
	end

	this:Hide()

end

--=========
-- 重置
--=========
function XiGua_ShowFashion_On_ResetPos()

	XiGua_ShowFashion_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 兑换
--=========
function XiGua_ShowFashion_ExChange()

    Clear_XSCRIPT()
    	Set_XSCRIPT_Function_Name("OnDuiHuanFashion")
    	Set_XSCRIPT_ScriptID(888082)
    	Set_XSCRIPT_Parameter(0,1);
    	Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()		
	
end

function XiGua_ShowFashion_Help()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowHelpText")
		Set_XSCRIPT_ScriptID(888082)
		Set_XSCRIPT_Parameter(0, 2)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

function XiGua_ShowFashion_ShowFashion()

	PushEvent("UI_COMMAND", 88808204, 1)
	
end

