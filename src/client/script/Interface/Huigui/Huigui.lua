
local g_Huigui_Frame_UnifiedXPosition;
local g_Huigui_Frame_UnifiedYPosition;

local g_Huigui_CostYuanbaoLevel2 = 120000
local g_Huigui_CostYuanbaoLevel3 = 240000

local g_Huigui_CostYuanbaoNum = 0

local g_ActionButton={};

function Huigui_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Huigui_OnLoad()
	g_Huigui_Frame_UnifiedXPosition	= Huigui_Frame:GetProperty("UnifiedXPosition");
	g_Huigui_Frame_UnifiedYPosition	= Huigui_Frame:GetProperty("UnifiedYPosition");
	
	g_ActionButton[0] = Huigui_Item_Icon0;
	g_ActionButton[1] = Huigui_Item_Icon1;
	g_ActionButton[2] = Huigui_Item_Icon3;
	g_ActionButton[3] = Huigui_Item_Icon4;
	g_ActionButton[4] = Huigui_Item_Icon2;
	g_ActionButton[5] = Huigui_Item_Icon5;
	g_ActionButton[6] = Huigui_Item_Icon6;
end

function Huigui_OnEvent( event )
	if event == "UI_COMMAND" and tonumber(arg0) == 891682 then
		if not this:IsVisible() then
			this:Show()
		end
		Huigui_updateFrame(Get_XParam_INT(0), Get_XParam_INT(1), Get_XParam_INT(2), Get_XParam_INT(3))
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Huigui_Frame:SetProperty("UnifiedXPosition", g_Huigui_Frame_UnifiedXPosition);
		Huigui_Frame:SetProperty("UnifiedYPosition", g_Huigui_Frame_UnifiedYPosition);
	end
end

function Huigui_updateFrame( costYuanbao, level1, level2, level3)
	DataPool:Lua_ClearRongYaoActionItem();
	DataPool:Lua_SetRongYaoActionItem( 0, 39920968, 1 );
	DataPool:Lua_SetRongYaoActionItem( 1, 39920565, 1 );
	DataPool:Lua_SetRongYaoActionItem( 2, 39920566, 1 );
	DataPool:Lua_SetRongYaoActionItem( 3, 38001480, 1 );
	DataPool:Lua_SetRongYaoActionItem( 4, 10124809, 1 );
	DataPool:Lua_SetRongYaoActionItem( 5, 10141760, 1 );
	DataPool:Lua_SetRongYaoActionItem( 6, 38001481, 1 );

	DataPool:Lua_UpdateRongYaoActionItem();
			
	for i=0, 6 do
		local theAction = EnumAction( i, "RongYao_item");
		if theAction:GetID() ~= 0 then
				g_ActionButton[i]:SetActionItem( theAction:GetID() );
		else
				g_ActionButton[i]:SetActionItem( -1 );
		end
	end	
			
	if costYuanbao < g_Huigui_CostYuanbaoLevel2 then
		Huigui_Item_Info1:SetText(  ScriptGlobal_Format( "#{RYHG_150911_18}", costYuanbao) )
	else
		Huigui_Item_Info1:SetText(  ScriptGlobal_Format( "#{RYHG_150911_19}", costYuanbao) )
	end
	
	if costYuanbao < g_Huigui_CostYuanbaoLevel3 then
		Huigui_Item_Info2:SetText(  ScriptGlobal_Format( "#{RYHG_150911_22}", costYuanbao) )
	else
		Huigui_Item_Info2:SetText(  ScriptGlobal_Format( "#{RYHG_150911_23}", costYuanbao) )
	end
	
	if level1 == 1 then
		Huigui_Item_Button0:Disable()
		Huigui_Item_Button0_tips:Show()
	else
		Huigui_Item_Button0:Enable()
		Huigui_Item_Button0_tips:Hide()
	end

	if level2 == 1 then
		Huigui_Item_Button1:Disable()
		Huigui_Item_Button1_tips:Show()
	else
		Huigui_Item_Button1:Enable()
		Huigui_Item_Button1_tips:Hide()
	end

	if level3 == 1 then
		Huigui_Item_Button2:Disable()
		Huigui_Item_Button2_tips:Show()
	else
		Huigui_Item_Button2:Enable()
		Huigui_Item_Button2_tips:Hide()
	end
	
	g_Huigui_CostYuanbaoNum = costYuanbao
end

function Huigui_OnGet( nIndex )
	if nIndex < 1 or nIndex > 3 then
		return
	end
	
	if nIndex == 2 and g_Huigui_CostYuanbaoNum < g_Huigui_CostYuanbaoLevel2 then
		PushDebugMessage(ScriptGlobal_Format("#{RYHG_150911_27}", g_Huigui_CostYuanbaoLevel2)) 
		return
	elseif nIndex == 3 and g_Huigui_CostYuanbaoNum < g_Huigui_CostYuanbaoLevel3 then
		PushDebugMessage(ScriptGlobal_Format("#{RYHG_150911_27}", g_Huigui_CostYuanbaoLevel3)) 
		return
	end
	
	Clear_XSCRIPT()
 		Set_XSCRIPT_Function_Name("onGetAward")
 		Set_XSCRIPT_ScriptID(891682)
 		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
 	Send_XSCRIPT()
end

function Huigui_CloseClicked()
	this:Hide()
end