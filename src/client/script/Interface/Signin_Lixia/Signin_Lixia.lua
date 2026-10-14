
local g_Signin_Lixia_UnifiedPosition;

local g_Signin_Lixia_List = {};
local g_Item = {10102829, 10105102}
function Signin_Lixia_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function Signin_Lixia_OnLoad()
	g_Signin_Lixia_UnifiedPosition = Signin_Lixia:GetProperty("UnifiedPosition")
	
	g_Signin_Lixia_List[1] = Signin_Lixia_Yuanbao_Icon
	g_Signin_Lixia_List[2] = Signin_Lixia_Yuanbao2_Icon
	
end

function Signin_Lixia_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 88873901 ) then	
		if Get_XParam_INT(0) == 0 then
			Signin_Lixia_Close()
			return
		end
		
		Signin_Lixia_Init()
		this:Show()
	elseif (event == "ADJEST_UI_POS" ) then
		Signin_Lixia_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Signin_Lixia_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Signin_Lixia_Close()
	end

end

function Signin_Lixia_Init()	
	-- 隐藏预览按钮
	Signin_Lixia_Preview_Btn:Hide()
	for i = 1, 2 do
		local itemAction = DataPool:CreateBindActionItemForShow(g_Item[i], 1)
		if itemAction:GetID() ~= 0 then
			g_Signin_Lixia_List[i]:SetActionItem( itemAction:GetID() );
		else
			g_Signin_Lixia_List[i]:SetActionItem( -1 );
		end
	end
	if Exterior:LuaFnIsHaveExterior(1, 419) == 1 then
		Signin_Lixia_Yuanbao_Icon_SelectBk:Show()
	else
		Signin_Lixia_Yuanbao_Icon_SelectBk:Hide()
	end
	if Exterior:LuaFnIsHaveExterior(1, 424) == 1 then
		Signin_Lixia_Yuanbao2_Icon_SelectBk:Show()
	else
		Signin_Lixia_Yuanbao2_Icon_SelectBk:Hide()
	end
end

function Signin_Lixia_Choose(idx)

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Choose" )
		Set_XSCRIPT_ScriptID(888739)
		Set_XSCRIPT_Parameter(0,idx)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	

end

--=========================================================
--关闭
--=========================================================
function Signin_Lixia_Close()
	
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function Signin_Lixia_On_ResetPos()
	Signin_Lixia:SetProperty("UnifiedPosition", g_Signin_Lixia_UnifiedPosition);
end

