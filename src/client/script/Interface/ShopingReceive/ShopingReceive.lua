--清空购物车 获得奖励界面
local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

function ShopingReceive_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("UI_COMMAND")
end

function ShopingReceive_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= ShopingReceive_FrameNULL:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= ShopingReceive_FrameNULL:GetProperty("UnifiedYPosition");
end

function ShopingReceive_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		ShopingReceive_ResetPos()
	
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		ShopingReceive_ResetPos()
		
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88839202 then
		ShopingReceive_Open()
		
	end
	
end

function ShopingReceive_ResetPos()
	ShopingReceive_FrameNULL:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ShopingReceive_FrameNULL:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function ShopingReceive_Open()
	local itemPos = Get_XParam_INT(0)
	
	local poolId, ShowItemId, ItemCount = Lua_GetGouWuCheItemInfo(itemPos)--获得表里的道具
	local theAction = DataPool:CreateActionItemForShow(ShowItemId, ItemCount)
	if theAction ~= nil then
		ShopingReceive_Congratulation_Lace1Item3:SetActionItem(theAction:GetID())
	end
	this:Show();
	
	SetTimer("ShopingReceive", "ShopingReceive_AutoClick_Timer()", 2000)
end

function ShopingReceive_AutoClick_Timer()
	ShopingReceive_Close()
end

function ShopingReceive_Close()
	KillTimer("ShopingReceive_AutoClick_Timer()")
	ShopingReceive_Congratulation_Lace1Item3:SetActionItem(-1)
	this:Hide();
end

function ShopingReceive_OnHiden()
	ShopingReceive_Close()
end
