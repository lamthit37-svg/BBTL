
local g_Token_Weapon_UnifiedPosition;

local g_Token_Weapon_List = {};

local g_Token_Weapon_ShopId = 0;
local g_Token_Weapon_idx1 = 0;
local g_Token_Weapon_item1 = 0;
local g_Token_Weapon_show1 = 0;
local g_Token_Weapon_cost1 = 0;
local g_Token_Weapon_idx2 = 0;
local g_Token_Weapon_item2 = 0;
local g_Token_Weapon_show2 = 0;
local g_Token_Weapon_cost2 = 0;
local g_Token_Weapon_ret = 0;

function Token_Weapon_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function Token_Weapon_OnLoad()
	g_Token_Weapon_UnifiedPosition = Token_Weapon:GetProperty("UnifiedPosition")
	
	g_Token_Weapon_List[1] = Token_Weapon_Yuanbao_Icon
	g_Token_Weapon_List[2] = Token_Weapon_Yuanbao2_Icon
	
end

function Token_Weapon_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89292107 ) then	
		if Get_XParam_INT(0) == 0 then
			this:Hide()
			return
		end
		
		g_Token_Weapon_ShopId = Get_XParam_INT(1)
		g_Token_Weapon_idx1 = Get_XParam_INT(2)
		g_Token_Weapon_idx2 = Get_XParam_INT(3)
		g_Token_Weapon_item1 = Get_XParam_INT(4)
		g_Token_Weapon_item2 = Get_XParam_INT(5)
		g_Token_Weapon_cost1 = Get_XParam_INT(6)
		g_Token_Weapon_cost2 = Get_XParam_INT(7)
		g_Token_Weapon_show1 = Get_XParam_INT(8)
		g_Token_Weapon_show2 = Get_XParam_INT(9)
		g_Token_Weapon_ret = Get_XParam_INT(10)
		
		Token_Weapon_OnTextInit()
		
		Token_Weapon_Init()
		
		this:Show()
		
		this:Activate()
		
	elseif (event == "ADJEST_UI_POS" ) then
		Token_Weapon_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Token_Weapon_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--=========================================================
--初始化界面
--=========================================================
function Token_Weapon_OnTextInit()
	
	if g_Token_Weapon_ShopId == 3 or g_Token_Weapon_ShopId == 4 then
		if g_Token_Weapon_item1 == 10125133 then
			Token_Weapon_DragTitle:SetText("#{XGSD_180608_71}")
		elseif g_Token_Weapon_item1 == 10125219 then 
			Token_Weapon_DragTitle:SetText("#{QXSD_220613_12}")
		elseif g_Token_Weapon_item1 == 38005951 then 
			Token_Weapon_DragTitle:SetText("#{QXSD_220613_13}")
		else
			Token_Weapon_DragTitle:SetText("#{QXSD_190615_53}")
		end
		
		if g_Token_Weapon_item1 == 38005951 then 
			Token_Weapon_Jinfen_text:SetText(ScriptGlobal_Format("#{QXSD_190615_55}", DataPool:Lua_GetItemNameByIndex( g_Token_Weapon_item1 )))
		else
			Token_Weapon_Jinfen_text:SetText(ScriptGlobal_Format("#{QXSD_190615_54}", DataPool:Lua_GetItemNameByIndex( g_Token_Weapon_item1 )))
		end
		Token_Weapon_Yuanbao_text:SetText(ScriptGlobal_Format("#{QXSD_190615_56}", g_Token_Weapon_cost1))
		
		Token_Weapon_Giftbox_text:SetText(ScriptGlobal_Format("#{QXSD_190615_55}", DataPool:Lua_GetItemNameByIndex( g_Token_Weapon_item2 )))
		Token_Weapon_Yuanbao2_text:SetText(ScriptGlobal_Format("#{QXSD_190615_56}", g_Token_Weapon_cost2))
		
		Token_Weapon_ReFresh_Btn:SetText("#{QXSD_190615_59}")
		if g_Token_Weapon_item1 == 38005951 then 
			Token_Weapon_ReFresh_Btn:SetToolTip(ScriptGlobal_Format("#{QXSD_220613_28}", g_Token_Weapon_cost1, DataPool:Lua_GetItemNameByIndex( g_Token_Weapon_item1 )))
		else
			Token_Weapon_ReFresh_Btn:SetToolTip(ScriptGlobal_Format("#{QXSD_190615_60}", g_Token_Weapon_cost1, DataPool:Lua_GetItemNameByIndex( g_Token_Weapon_item1 )))
		end
		Token_Weapon_ReFresh_Btn2:SetText("#{QXSD_190615_61}")
		
		if g_Token_Weapon_item1 == 38005951 then 
			Token_Weapon_ReFresh_Btn2:SetToolTip(ScriptGlobal_Format("#{QXSD_220613_29}", g_Token_Weapon_cost2, DataPool:Lua_GetItemNameByIndex( g_Token_Weapon_item2 ), DataPool:Lua_GetItemNameByIndex( g_Token_Weapon_item1 )))	
		else
			Token_Weapon_ReFresh_Btn2:SetToolTip(ScriptGlobal_Format("#{QXSD_190615_71}", g_Token_Weapon_cost2, DataPool:Lua_GetItemNameByIndex( g_Token_Weapon_item2 ), DataPool:Lua_GetItemNameByIndex( g_Token_Weapon_item1 )))	
		end	
		
		if g_Token_Weapon_item1 == 38005951 then 
			Token_Weapon_Refresh1_Text:SetText(ScriptGlobal_Format("#{QXSD_220613_26}", DataPool:Lua_GetItemNameByIndex( g_Token_Weapon_item2 ), DataPool:Lua_GetItemNameByIndex( g_Token_Weapon_item1 )))
		else
			Token_Weapon_Refresh1_Text:SetText(ScriptGlobal_Format("#{QXSD_190615_58}", DataPool:Lua_GetItemNameByIndex( g_Token_Weapon_item1 )))
		end
		
		Token_Weapon_Preview_Btn:Hide()
	else
		Token_Weapon_DragTitle:SetText("#{SJSD_180817_56}")
		
		Token_Weapon_Jinfen_text:SetText("#{SJSD_180817_57}")
		Token_Weapon_Yuanbao_text:SetText("#{SJSD_180817_58}")
		
		Token_Weapon_Giftbox_text:SetText("#{SJSD_180817_61}")
		Token_Weapon_Yuanbao2_text:SetText("#{SJSD_180817_64}")
		
		Token_Weapon_ReFresh_Btn:SetText("#{SJSD_180817_59}")
		Token_Weapon_ReFresh_Btn:SetToolTip("#{SJSD_180817_60}")		
		Token_Weapon_ReFresh_Btn2:SetText("#{SJSD_180817_65}")
		Token_Weapon_ReFresh_Btn2:SetToolTip("#{SJSD_180817_66}")		
		
		Token_Weapon_Refresh1_Text:SetText("#{SJSD_180817_67}")
		
		Token_Weapon_Preview_Btn:Show()
	end
	
end

function Token_Weapon_Init()	
	local theActionlist = {10105023, 39921530}
	--DataPool:Lua_ClearXiGuaShopActionItem();	
	if g_Token_Weapon_ShopId == 3 or g_Token_Weapon_ShopId == 4 then
		--DataPool:Lua_SetXiGuaShopActionItem( 8, g_Token_Weapon_item1, 1 );
		--DataPool:Lua_SetXiGuaShopActionItem( 9, g_Token_Weapon_item2, 1 );
		theActionlist[1] = g_Token_Weapon_item1	--DataPool:CreateActionItemForShow(g_Token_Weapon_item1, 1)
		theActionlist[2] = g_Token_Weapon_item2	--DataPool:CreateActionItemForShow(g_Token_Weapon_item2, 1)
	else
		--DataPool:Lua_SetXiGuaShopActionItem( 8, 10105023, 1 );
		--DataPool:Lua_SetXiGuaShopActionItem( 9, 39921530, 1 );
		theActionlist[1] = 10105023	--DataPool:CreateActionItemForShow(10105023, 1)
		theActionlist[2] = 39921530	--DataPool:CreateActionItemForShow(39921530, 1)
	end			
	DataPool:Lua_UpdateXiGuaShopActionItem();
	for i=1, 2 do
		--local theAction = EnumAction( i+7, "xiguashop_item");
		local theAction = DataPool:CreateActionItemForShow(theActionlist[i], 1)
		if theAction:GetID() ~= 0 then
			g_Token_Weapon_List[i]:SetActionItem( theAction:GetID() );
		else
			g_Token_Weapon_List[i]:SetActionItem( -1 );
		end
	end
	
end
	
--=========================================================
--购买时装
--=========================================================
function Token_Weapon_WeaponBuy()	
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnCommonShopBuy" )
		Set_XSCRIPT_ScriptID(892921)
		Set_XSCRIPT_Parameter(0,2) --1、表示代币 2、表示元宝
		Set_XSCRIPT_Parameter(1,-1) 
		if g_Token_Weapon_ShopId == 3 or g_Token_Weapon_ShopId == 4 then
			Set_XSCRIPT_Parameter(2,g_Token_Weapon_idx1)
			Set_XSCRIPT_Parameter(3,g_Token_Weapon_show1)
		else
			Set_XSCRIPT_Parameter(2,53)
			Set_XSCRIPT_Parameter(3,39921535)
		end
		Set_XSCRIPT_Parameter(4,g_Token_Weapon_ret)
		Set_XSCRIPT_Parameter(5,0)
		Set_XSCRIPT_ParamCount(6)
	Send_XSCRIPT()	

end

--=========================================================
--购买礼盒
--=========================================================
function Token_Weapon_WeaponLiHeBuy()	
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnCommonShopBuy" )
		Set_XSCRIPT_ScriptID(892921)
		Set_XSCRIPT_Parameter(0,2) --1、表示代币 2、表示元宝
		Set_XSCRIPT_Parameter(1,-1) 
		if g_Token_Weapon_ShopId == 3 or g_Token_Weapon_ShopId == 4 then
			Set_XSCRIPT_Parameter(2,g_Token_Weapon_idx2)
			Set_XSCRIPT_Parameter(3,g_Token_Weapon_show2)
		else
			Set_XSCRIPT_Parameter(2,49)
			Set_XSCRIPT_Parameter(3,39921535)
		end
		Set_XSCRIPT_Parameter(4,g_Token_Weapon_ret) 
		Set_XSCRIPT_Parameter(5,0)
		Set_XSCRIPT_ParamCount(6)
	Send_XSCRIPT()	

end

--=========================================================
--预览
--=========================================================
function Token_Weapon_WeaponShow()
	PushEvent("UI_COMMAND", 89292108, g_Token_Weapon_ShopId)
end

--=========================================================
--关闭
--=========================================================
function Token_Weapon_Close()
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function Token_Weapon_On_ResetPos()
	Token_Weapon:SetProperty("UnifiedPosition", g_Token_Weapon_UnifiedPosition);
end
