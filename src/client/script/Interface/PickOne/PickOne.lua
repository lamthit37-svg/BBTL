
local g_PickOne_UnifiedPosition;

local g_PickOne_List = {};
local g_UICommandType =0;

function PickOne_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("OPEN_YUANBAOSHOP",false)
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function PickOne_OnLoad()
	g_PickOne_UnifiedPosition = PickOne:GetProperty("UnifiedPosition")
	
	g_PickOne_List[1] = PickOne_Yuanbao_Icon
	g_PickOne_List[2] = PickOne_Yuanbao2_Icon
	
end

function PickOne_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89308501 ) then	
		if Get_XParam_INT(0) == 0 then
			PickOne_Close()
			return
		end
		
		PickOne_Init()
		g_UICommandType = 89308501
		this:Show()
	
	elseif (event == "OPEN_YUANBAOSHOP" ) then
		PickOne_Close()
		
	elseif (event == "ADJEST_UI_POS" ) then
		PickOne_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PickOne_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		PickOne_Close()
	end

end

--=========================================================
--初始化界面
--=========================================================
function PickOne_Init()	
	
	--DataPool:Lua_ClearXiGuaShopActionItem();	
		DataPool:Lua_SetXiGuaShopActionItem( 10, 39921694, 1 );
		DataPool:Lua_SetXiGuaShopActionItem( 11, 39925319, 1 );
	DataPool:Lua_UpdateXiGuaShopActionItem();
	for i=1, 2 do
		local theAction = EnumAction( i+9, "xiguashop_item");
		if theAction:GetID() ~= 0 then
			g_PickOne_List[i]:SetActionItem( theAction:GetID() );
		else
			g_PickOne_List[i]:SetActionItem( -1 );
		end
	end
	
end
	
--=========================================================
--购买时装
--=========================================================
function PickOne_FashionBuy()
	if g_UICommandType == 89308501 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnChooseLeft" )
			Set_XSCRIPT_ScriptID(893085)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	end

end

--=========================================================
--购买礼盒
--=========================================================
function PickOne_FashionLiHeBuy()
	if g_UICommandType == 89308501 then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnChooseRight" )
			Set_XSCRIPT_ScriptID(893085)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end

--=========================================================
--关闭
--=========================================================
function PickOne_Close()
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function PickOne_On_ResetPos()
	PickOne:SetProperty("UnifiedPosition", g_PickOne_UnifiedPosition);
end
