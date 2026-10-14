
local g_YuanXiao_ShopBuy_Frame_UnifiedPosition;

local g_YuanXiao_ShopBuy_index = -1;
local g_YuanXiao_ShopBuy_showid = -1;
local g_YuanXiao_ShopBuy_itemIdx = -1;
local g_YuanXiao_ShopBuy_Coupon = -1;
local g_YuanXiao_ShopBuy_Num = -1;
local g_YuanXiao_ShopBuy_Cost = -1;

function YuanXiao_ShopBuy_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("OPEN_YUANBAOSHOP",false);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function YuanXiao_ShopBuy_OnLoad()
	g_YuanXiao_ShopBuy_Frame_UnifiedPosition = YuanXiao_ShopBuy_Frame:GetProperty("UnifiedPosition")
end

function YuanXiao_ShopBuy_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89071302 ) then
	
		YuanXiao_ShopBuy_Close()
		
		if Get_XParam_INT(0) == 0 then			
			return
		end
		
		g_YuanXiao_ShopBuy_index = Get_XParam_INT(1)
		g_YuanXiao_ShopBuy_showid = Get_XParam_INT(2)
		g_YuanXiao_ShopBuy_itemIdx = Get_XParam_INT(3)
		g_YuanXiao_ShopBuy_Coupon = Get_XParam_INT(4)
		g_YuanXiao_ShopBuy_Num = Get_XParam_INT(5)
		g_YuanXiao_ShopBuy_Cost = Get_XParam_INT(6)
		
		--local szItemName = DataPool:Lua_GetItemNameByIndex(g_YuanXiao_ShopBuy_showid)
		--local str = ScriptGlobal_Format("#{MHSD_181126_100}", 
		--							g_YuanXiao_ShopBuy_Cost-g_YuanXiao_ShopBuy_Coupon, 
		--							g_YuanXiao_ShopBuy_Coupon, 
		--							g_YuanXiao_ShopBuy_Num, 
		--							szItemName, 
		--							g_YuanXiao_ShopBuy_Cost)
		--YuanXiao_ShopBuy_Text1:SetText(str)
		local str = ScriptGlobal_Format("#{MHSD_181126_136}", g_YuanXiao_ShopBuy_Cost)
		YuanXiao_ShopBuy_YuanBaoText:SetText(str)
		str = ScriptGlobal_Format("#{MHSD_181126_137}", g_YuanXiao_ShopBuy_Cost-g_YuanXiao_ShopBuy_Coupon, g_YuanXiao_ShopBuy_Coupon)
		YuanXiao_ShopBuy_DisCountText:SetText(str)
		
		DataPool:Lua_SetXiGuaShopActionItem( 8, g_YuanXiao_ShopBuy_showid, g_YuanXiao_ShopBuy_Num );
		DataPool:Lua_UpdateXiGuaShopActionItem();
		local theAction = EnumAction( 8, "xiguashop_item");
		if theAction:GetID() ~= 0 then
			YuanXiao_ShopBuy_Item:SetActionItem( theAction:GetID() );
		else
			YuanXiao_ShopBuy_Item:SetActionItem( -1 );
		end
			
		this:Show()
	
	elseif (event == "OPEN_YUANBAOSHOP" ) then
		YuanXiao_ShopBuy_Close()
		
	elseif (event == "ADJEST_UI_POS" ) then
		YuanXiao_ShopBuy_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		YuanXiao_ShopBuy_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		YuanXiao_ShopBuy_Close()
	end

end

--=========================================================
--打折购买
--=========================================================
function YuanXiao_ShopBuy_DisCountClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyItembyCoupon" )
		Set_XSCRIPT_ScriptID(890713)
		Set_XSCRIPT_Parameter(0, g_YuanXiao_ShopBuy_index)
		Set_XSCRIPT_Parameter(1, g_YuanXiao_ShopBuy_showid)
		Set_XSCRIPT_Parameter(2, g_YuanXiao_ShopBuy_itemIdx)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
end

--=========================================================
--元宝购买
--=========================================================
function YuanXiao_ShopBuy_YuanBaoClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyItemOnlyYuanbao" )
		Set_XSCRIPT_ScriptID(890713)
		Set_XSCRIPT_Parameter(0, g_YuanXiao_ShopBuy_index)
		Set_XSCRIPT_Parameter(1, g_YuanXiao_ShopBuy_showid)
		Set_XSCRIPT_Parameter(2, g_YuanXiao_ShopBuy_itemIdx)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
end

--=========================================================
--关闭
--=========================================================
function YuanXiao_ShopBuy_Close()
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function YuanXiao_ShopBuy_On_ResetPos()
	YuanXiao_ShopBuy_Frame:SetProperty("UnifiedPosition", g_YuanXiao_ShopBuy_Frame_UnifiedPosition);
end
