

local CU_YUANBAO			= 5	-- 钱
local g_MaxBuyNum_PerTime = 7500		-- 这个不是常量，打开窗口的时候会根据商店重新初始化，但最大7500
local g_bFromRecentBooth = 0
local g_MaxInt = 2147483647
local ShopUnitID = {
		YuanBao = 5,			--元宝
		Bind = 9,					--绑定元宝
		GiftToken = 10,		--返券
}

-- 七夕付费商店批量购买
local g_Token_Shop_MBuy_Flag = false
local g_Token_Shop_MBuy_IDX = -1
local g_Token_Shop_MBuy_MaxNum = 1
local g_Token_Shop_MBuy_ItemId = -1
local g_Token_Shop_MBuy_ItemNum = 0
local g_Token_Shop_MBuy_ItemPrice = 0
local g_Token_Shop_MBuy_CareObj = nil
local g_Token_Shop_MBuy_target = -1

local g_Token_Shop_MBuy_UnifiedPosition;

function Token_Shop_MBuy_PreLoad()

	this:RegisterEvent("UPDATE_YUANBAO");
	this:RegisterEvent("CLOSE_BOOTH");
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	
end

function Token_Shop_MBuy_OnLoad()

	g_Token_Shop_MBuy_UnifiedPosition = Token_Shop_MBuy_Frame:GetProperty("UnifiedPosition")

end

function Token_Shop_MBuy_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89292120 ) then
		g_bFromRecentBooth = 0
		g_Token_Shop_MBuy_Flag = true
		g_Token_Shop_MBuy_target = Get_XParam_INT(0)	
		g_Token_Shop_MBuy_CareObj = Target:GetServerId2ClientId( tonumber( g_Token_Shop_MBuy_target ) );
		if g_Token_Shop_MBuy_CareObj then
			this:CareObject(g_Token_Shop_MBuy_CareObj, 1, "Token_Shop_MBuy")
		end
		
		g_Token_Shop_MBuy_IDX = Get_XParam_INT(1)
		g_Token_Shop_MBuy_MaxNum = Get_XParam_INT(2)
		g_Token_Shop_MBuy_ItemId = Get_XParam_INT(3)
		g_Token_Shop_MBuy_ItemNum = Get_XParam_INT(4)
		g_Token_Shop_MBuy_ItemPrice = Get_XParam_INT(5)
		Token_Shop_MBuy_OpenByQiXiFuFeiShop()
		return
	elseif(event == "CLOSE_BOOTH") then
		Token_Shop_MBuy_OnHide()
		
	elseif( event == "UPDATE_YUANBAO" and this:IsVisible() ) then
		--需要花费
		local num = tonumber(Token_Shop_MBuy_InputNum:GetText());
		if(nil == num or(num and num < 0)) then
			Token_Shop_MBuy_Price_Yuanbao:SetText("0")
			num = 0
		end

		if(num > g_MaxBuyNum_PerTime) then
			num = g_MaxBuyNum_PerTime;
		end

		Token_Shop_MBuy_UpdateCurMoney(num)
		
	elseif (event == "ADJEST_UI_POS" ) then
		Token_Shop_MBuy_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Token_Shop_MBuy_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Token_Shop_MBuy_OnHide()
		
	end
end

function Token_Shop_MBuy_OpenByQiXiFuFeiShop()

	if g_Token_Shop_MBuy_ItemId == nil or g_Token_Shop_MBuy_ItemNum == nil then
		return
	end
	
	local theAction = DataPool:CreateBindActionItemForShow(g_Token_Shop_MBuy_ItemId, g_Token_Shop_MBuy_ItemNum)
	if theAction:GetID() ~= 0 then
		Token_Shop_MBuy_Item:SetActionItem(theAction:GetID());		
		Token_Shop_MBuy_ItemInfo_Text:SetText( theAction:GetName() );
		Token_Shop_MBuy_ItemInfo_GB:SetText("#cfff263".."#{YBSD_081225_101}" .. tostring(g_Token_Shop_MBuy_ItemPrice))
	else
		Token_Shop_MBuy_Item:SetActionItem(-1);
		Token_Shop_MBuy_ItemInfo_Text:SetText("");
		Token_Shop_MBuy_ItemInfo_GB:SetText("");
	end
	Token_Shop_MBuy_InputNum:SetProperty("DefaultEditBox", "True");
	Token_Shop_MBuy_InputNum:SetText(tostring(1));
	Token_Shop_MBuy_InputNum:SetSelected( 0, -1 );

	Token_Shop_MBuy_UpdateCurMoney(1)
	this:Show();

end
function Token_Shop_MBuy_UpdateCurMoney(num)

	if g_Token_Shop_MBuy_ItemPrice > 0 and Division(g_MaxInt, g_Token_Shop_MBuy_ItemPrice) < num then
		Token_Shop_MBuy_Price_Yuanbao:SetText("0")
		PushDebugMessage("#{FFSDGZ_120615_127}")
		return
	end
	
	local playerCoin_yuanbao = Player:GetData("YUANBAO");
	Token_Shop_MBuy_Price:SetText("#{FFSDGZ_120615_24}")
	Token_Shop_MBuy_Cash:SetText("#{FFSDGZ_120615_25}")
	--需要花费
	local needYuanBaoColor = ""
	local nNeedMoney = Lua_Multiply(num, g_Token_Shop_MBuy_ItemPrice)
	if playerCoin_yuanbao >= nNeedMoney then
		needYuanBaoColor="#cfff263"
		Token_Shop_MBuy_Buy:Enable()
	else
		needYuanBaoColor="#cff0000"
		Token_Shop_MBuy_Buy:Disable()
	end
		
	--身体携带
	Token_Shop_MBuy_Price_Yuanbao:SetText(needYuanBaoColor..tostring( nNeedMoney ))
	--数量
	Token_Shop_MBuy_Cash_Yuanbao:SetText("#cfff263"..tostring(playerCoin_yuanbao))
end

function Token_Shop_MBuy_CalMax()

	if g_Token_Shop_MBuy_ItemId < 0 or g_Token_Shop_MBuy_ItemPrice <= 0 then
		return 0
	end

    local num = CalcItemSpace_BindProperty(g_Token_Shop_MBuy_ItemId)
    if num <= 0 then
		Token_Shop_MBuy_InputNum:SetText("1");
        return 0
    end

    if num > g_Token_Shop_MBuy_MaxNum and g_Token_Shop_MBuy_MaxNum >= 0 then --不能超过限购数
        num = g_Token_Shop_MBuy_MaxNum
    end

	local playerCnt = Player:GetData("YUANBAO") --玩家拥有元宝
	local danJia = g_Token_Shop_MBuy_ItemPrice --单价

	local max_cnt = math.floor(playerCnt / danJia)
	if num > max_cnt then --不能超过财力承受范围
		num = max_cnt
	end
	
	if num > g_MaxBuyNum_PerTime then
		num = g_MaxBuyNum_PerTime
	end

	if num < 0 then
		num = 0
	end
	
	Token_Shop_MBuy_InputNum:SetText(tostring(num));
end

function Token_Shop_MBuy_TextChanged()
	local num = tonumber(Token_Shop_MBuy_InputNum:GetText());
	if(nil == num or(num and num < 0)) then
		Token_Shop_MBuy_Price_Yuanbao:SetText("0")
		return;
	end

	if(num > g_Token_Shop_MBuy_MaxNum) then
		num = g_Token_Shop_MBuy_MaxNum;
		Token_Shop_MBuy_InputNum:SetText(tostring(num))
	end

	if(num > g_MaxBuyNum_PerTime) then
		num = g_MaxBuyNum_PerTime;
		Token_Shop_MBuy_InputNum:SetText(tostring(num))
	end

	Token_Shop_MBuy_UpdateCurMoney(num)
end

function Token_Shop_MBuy_Close_Clicked()
	if g_Token_Shop_MBuy_PetNeiDanShop_Flag then
		-- 内丹商店批量购买宝图
		PushEvent("NEIDAN_SHOP_UPDATE", "on_cancle")
	end

	if g_Token_Shop_MBuy_ZongMenShop_Flag then
		PushEvent("UPDATE_ZONGMEN_SHOPINFO", "on_cancle")
	end

	if g_Token_Shop_MBuy_DaHuaQiXiShop_Flag then
		PushEvent("DAHUAQIXI_SHOP_UPDATE", "on_cancel")
	end

	Token_Shop_MBuy_OnHide()
end

function Token_Shop_MBuy_OnHide()
	
	if g_Token_Shop_MBuy_CareObj then
		this:CareObject( g_Token_Shop_MBuy_CareObj, 0, "Token_Shop_MBuy" )
		g_Token_Shop_MBuy_CareObj = nil
	end

	this:Hide()
end

function Token_Shop_MBuy_BuyMulti_Clicked()
	local num = tonumber(Token_Shop_MBuy_InputNum:GetText());

	if num ~= nil and num > 0 then
		if g_Token_Shop_MBuy_IDX > 0 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnBuyFanLiItemByNPC" )
				Set_XSCRIPT_ScriptID(892921)
				Set_XSCRIPT_Parameter(0, g_Token_Shop_MBuy_target)
				Set_XSCRIPT_Parameter(1, g_Token_Shop_MBuy_IDX)
				Set_XSCRIPT_Parameter(2, 0)
				Set_XSCRIPT_Parameter(3, num)
				Set_XSCRIPT_ParamCount(4)
			Send_XSCRIPT()	
		end
		Token_Shop_MBuy_OnHide()
	else
		PushDebugMessage("#{FFSDGZ_120615_47}")
	end
end

function Token_Shop_MBuy_HideUI_XianGou()
	Token_Shop_MBuy_Item_Num:Hide()
	Token_Shop_MBuy_Item_IconMark1:Hide()
	Token_Shop_MBuy_Item_IconMark2:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function Token_Shop_MBuy_On_ResetPos()
	Token_Shop_MBuy_Frame:SetProperty("UnifiedPosition", g_Token_Shop_MBuy_UnifiedPosition);
end

