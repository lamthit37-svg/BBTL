
local g_PayTopList_Duihuan_UnifiedPosition = nil
local g_CurJifenData = 1057;
local g_TotalJifenData = 1058;
local g_PayTopList_Duihuan_ActionCtrl = {};
local g_PayTopList_Duihuan_ActionMask = {};
local g_PayTopList_Duihuan_ActionBuyLimit = {};
local g_PayTopList_Duihuan_ActionBuyLimitNumBK = {};
local g_PayTopList_Duihuan_ActionBuyLimitNum = {};
local g_PayTopList_Duihuan_ActionAnimate = {};
local g_PayTopList_Duihuan_ActionDes = {};
local g_PayTopList_Duihuan_ActionButton = {};
local g_PayTopList_Duihuan_ItemId = {
	[1] = {ItemId=38005657, KaJiItemId=38005657, OriJDItemId=38005657, MF=5312, Price=400000, szDes="#{MDJH_251125_04}"},
	[2] = {ItemId=38005645, KaJiItemId=38008658, OriJDItemId=38008654, MF=-1, Price=2000, szDes="#{MDJH_141014_36}"},
	[3] = {ItemId=38005646, KaJiItemId=38008659, OriJDItemId=38008655, MF=-1, Price=8000, szDes="#{MDJH_141014_37}"},
	[4] = {ItemId=38005647, KaJiItemId=38008660, OriJDItemId=38008656, MF=-1, Price=20000, szDes="#{MDJH_141014_38}"},
	[5] = {ItemId=38008050, KaJiItemId=38008661, OriJDItemId=38008657, MF=-1, Price=20000, szDes="#{MDJH_141014_38}"},
};

function PayTopList_Duihuan_PreLoad()

	this:RegisterEvent("UI_COMMAND")
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("FATIE_SECCONFIRM");	
	this:RegisterEvent("UI_COMMAND");	
end

--===============================================
-- OnLoad()
--===============================================
function PayTopList_Duihuan_OnLoad()
	g_PayTopList_Duihuan_UnifiedPosition = PayTopList_Duihuan_Frame:GetProperty("UnifiedPosition")
	
	g_PayTopList_Duihuan_ActionCtrl[1] = PayTopList_Duihuan_Exchange1_Icon;
	g_PayTopList_Duihuan_ActionCtrl[2] = PayTopList_Duihuan_Exchange2_Icon;
	g_PayTopList_Duihuan_ActionCtrl[3] = PayTopList_Duihuan_Exchange3_Icon;
	g_PayTopList_Duihuan_ActionCtrl[4] = PayTopList_Duihuan_Exchange4_Icon;
	g_PayTopList_Duihuan_ActionCtrl[5] = PayTopList_Duihuan_Exchange5_Icon;
	
	g_PayTopList_Duihuan_ActionMask[1] = PayTopList_Duihuan_Exchange1_Icon_Mask;
	g_PayTopList_Duihuan_ActionMask[2] = PayTopList_Duihuan_Exchange2_Icon_Mask;
	g_PayTopList_Duihuan_ActionMask[3] = PayTopList_Duihuan_Exchange3_Icon_Mask;
	g_PayTopList_Duihuan_ActionMask[4] = PayTopList_Duihuan_Exchange4_Icon_Mask;
	g_PayTopList_Duihuan_ActionMask[5] = PayTopList_Duihuan_Exchange5_Icon_Mask;
	
	g_PayTopList_Duihuan_ActionBuyLimit[1] = PayTopList_Duihuan_Exchange1_Icon_BuyLimit;
	g_PayTopList_Duihuan_ActionBuyLimit[2] = PayTopList_Duihuan_Exchange2_Icon_BuyLimit;
	g_PayTopList_Duihuan_ActionBuyLimit[3] = PayTopList_Duihuan_Exchange3_Icon_BuyLimit;
	g_PayTopList_Duihuan_ActionBuyLimit[4] = PayTopList_Duihuan_Exchange4_Icon_BuyLimit;
	g_PayTopList_Duihuan_ActionBuyLimit[5] = PayTopList_Duihuan_Exchange5_Icon_BuyLimit;
	
	g_PayTopList_Duihuan_ActionBuyLimitNumBK[1] = PayTopList_Duihuan_Exchange1_Icon_BuyLimitNumBK;
	g_PayTopList_Duihuan_ActionBuyLimitNumBK[2] = PayTopList_Duihuan_Exchange2_Icon_BuyLimitNumBK;
	g_PayTopList_Duihuan_ActionBuyLimitNumBK[3] = PayTopList_Duihuan_Exchange3_Icon_BuyLimitNumBK;
	g_PayTopList_Duihuan_ActionBuyLimitNumBK[4] = PayTopList_Duihuan_Exchange4_Icon_BuyLimitNumBK;
	g_PayTopList_Duihuan_ActionBuyLimitNumBK[5] = PayTopList_Duihuan_Exchange5_Icon_BuyLimitNumBK;
	
	g_PayTopList_Duihuan_ActionBuyLimitNum[1] = PayTopList_Duihuan_Exchange1_Icon_BuyLimitNum;
	g_PayTopList_Duihuan_ActionBuyLimitNum[2] = PayTopList_Duihuan_Exchange2_Icon_BuyLimitNum;
	g_PayTopList_Duihuan_ActionBuyLimitNum[3] = PayTopList_Duihuan_Exchange3_Icon_BuyLimitNum;
	g_PayTopList_Duihuan_ActionBuyLimitNum[4] = PayTopList_Duihuan_Exchange4_Icon_BuyLimitNum;
	g_PayTopList_Duihuan_ActionBuyLimitNum[5] = PayTopList_Duihuan_Exchange5_Icon_BuyLimitNum;
	
	g_PayTopList_Duihuan_ActionAnimate[1] = PayTopList_Duihuan_Exchange1_Icon_Animate;
	g_PayTopList_Duihuan_ActionAnimate[2] = PayTopList_Duihuan_Exchange2_Icon_Animate;
	g_PayTopList_Duihuan_ActionAnimate[3] = PayTopList_Duihuan_Exchange3_Icon_Animate;
	g_PayTopList_Duihuan_ActionAnimate[4] = PayTopList_Duihuan_Exchange4_Icon_Animate;
	g_PayTopList_Duihuan_ActionAnimate[5] = PayTopList_Duihuan_Exchange5_Icon_Animate;
	
	g_PayTopList_Duihuan_ActionDes[1] = PayTopList_Duihuan_Exchange1_Des;
	g_PayTopList_Duihuan_ActionDes[2] = PayTopList_Duihuan_Exchange2_Des;
	g_PayTopList_Duihuan_ActionDes[3] = PayTopList_Duihuan_Exchange3_Des;
	g_PayTopList_Duihuan_ActionDes[4] = PayTopList_Duihuan_Exchange4_Des;
	g_PayTopList_Duihuan_ActionDes[5] = PayTopList_Duihuan_Exchange5_Des;
	
	g_PayTopList_Duihuan_ActionButton[1] = PayTopList_Duihuan_Exchange1_Button;
	g_PayTopList_Duihuan_ActionButton[2] = PayTopList_Duihuan_Exchange2_Button;
	g_PayTopList_Duihuan_ActionButton[3] = PayTopList_Duihuan_Exchange3_Button;
	g_PayTopList_Duihuan_ActionButton[4] = PayTopList_Duihuan_Exchange4_Button;
	g_PayTopList_Duihuan_ActionButton[5] = PayTopList_Duihuan_Exchange5_Button;
	
end

--===============================================
-- OnEvent()
--===============================================
function PayTopList_Duihuan_OnEvent(event)
	if ( event == "FATIE_SECCONFIRM" and arg0 == "PayTopList_DuiHuan_Open") then
		PayTopList_Duihuan_Open()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		PayTopList_Duihuan_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		PayTopList_Duihuan_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif (event  == "UI_COMMAND") and (tonumber(arg0) == 20160512) then		
		if (this:IsVisible()) then
			PayTopList_Duihuan_Open()
		end
	end
end

function PayTopList_Duihuan_ResetPos()
		PayTopList_Duihuan_Frame:SetProperty("UnifiedPosition",g_PayTopList_Duihuan_UnifiedPosition)
end

function PayTopList_Duihuan_OnHiden()
	this:Hide()
	PushEvent("CLOSE_BOOTH") --关闭批量购买窗口Shop_MBuy
	
	for i = 1 , table.getn(g_PayTopList_Duihuan_ActionCtrl) do
		g_PayTopList_Duihuan_ActionCtrl[i]:SetActionItem(-1)
	end
	DataPool:Lua_ClearMingDongDuiHuanActionItem();
end

function PayTopList_Duihuan_Open()
	PushEvent("CLOSE_BOOTH") --关闭批量购买窗口Shop_MBuy
	
	PayTopList_Duihuan_Tab1:SetCheck(0)
	PayTopList_Duihuan_Tab2:SetCheck(0)
	PayTopList_Duihuan_Tab3:SetCheck(1)

	local curJifen =  DataPool:GetPlayerMission_DataRound(g_CurJifenData);
	local totalJifen =  DataPool:GetPlayerMission_DataRound(g_TotalJifenData);

	local curJifenStr = ScriptGlobal_Format("#{MDJH_130507_41}", curJifen)
	local totalJifenStr = ScriptGlobal_Format("#{MDJH_130507_40}", totalJifen)
	PayTopList_Duihuan_GetNumText:SetText(totalJifenStr)
	PayTopList_Duihuan_AvailNumText:SetText(curJifenStr)

	local nServerType = 1
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(49) > 0 then  --卡级
		nServerType = 2
	elseif Player:GetData("IsOriginalJD") == 1 then--删减服
		nServerType = 3
	end
	
	DataPool:Lua_ClearMingDongDuiHuanActionItem();
		for i=1, table.getn(g_PayTopList_Duihuan_ItemId) do
			if nServerType == 1 then
				DataPool:Lua_SetMingDongDuiHuanActionItem( i-1, g_PayTopList_Duihuan_ItemId[i].ItemId );
			elseif nServerType == 2 then
				DataPool:Lua_SetMingDongDuiHuanActionItem( i-1, g_PayTopList_Duihuan_ItemId[i].KaJiItemId );
			else
				DataPool:Lua_SetMingDongDuiHuanActionItem( i-1, g_PayTopList_Duihuan_ItemId[i].OriJDItemId );
			end
		end
	DataPool:Lua_UpdateMingDongDuiHuanActionItem();
				
	for i=1, table.getn(g_PayTopList_Duihuan_ActionCtrl) do
		local theAction = EnumAction(i - 1, "mingdongduihuan")
		if theAction:GetID() ~= 0 then	
			g_PayTopList_Duihuan_ActionCtrl[i]:SetActionItem(theAction:GetID())
		end
		
		if g_PayTopList_Duihuan_ItemId[i] ~= nil then
			g_PayTopList_Duihuan_ActionDes[i]:SetText( g_PayTopList_Duihuan_ItemId[i].szDes );
		end
		
		if g_PayTopList_Duihuan_ItemId[i] ~= nil and g_PayTopList_Duihuan_ItemId[i].MF > 0 then
			local nCanBuyCount = 1 - tonumber(Pneuma:GetMF(g_PayTopList_Duihuan_ItemId[i].MF));
			g_PayTopList_Duihuan_ActionBuyLimit[i]:SetText( nCanBuyCount )
			
			if nCanBuyCount > 0 then
				g_PayTopList_Duihuan_ActionMask[i]:Hide();
				g_PayTopList_Duihuan_ActionAnimate[i]:Show();
				g_PayTopList_Duihuan_ActionButton[i]:Enable()				
			else
				g_PayTopList_Duihuan_ActionMask[i]:Show();
				g_PayTopList_Duihuan_ActionAnimate[i]:Hide()
				g_PayTopList_Duihuan_ActionButton[i]:Disable()
			end
			
			g_PayTopList_Duihuan_ActionBuyLimitNum[i]:SetText( nCanBuyCount );
			g_PayTopList_Duihuan_ActionBuyLimit[i]:Show()
			g_PayTopList_Duihuan_ActionBuyLimitNumBK[i]:Show()
			
		else
			g_PayTopList_Duihuan_ActionMask[i]:Hide()
			g_PayTopList_Duihuan_ActionBuyLimit[i]:Hide()
			g_PayTopList_Duihuan_ActionBuyLimitNumBK[i]:Hide()
			g_PayTopList_Duihuan_ActionAnimate[i]:Hide()
			g_PayTopList_Duihuan_ActionButton[i]:Enable()
		end
		
	end	
								
	this:Show()
end

function PayTopList_Duihuan_Benqu()
	PushEvent("CLOSE_BOOTH") --关闭批量购买窗口Shop_MBuy
	PushEvent("FATIE_SECCONFIRM","PayTopList_BenQu_Open")
end

function PayTopList_Duihuan_Zhanqu()
	PushEvent("CLOSE_BOOTH") --关闭批量购买窗口Shop_MBuy
	PushEvent("FATIE_SECCONFIRM","PayTopList_ZhanQu_Open")
end

function PayTopList_Duihuan_Click(index)
	
	if g_PayTopList_Duihuan_ItemId[index] == nil then
		return
	end
	
	local nItemId = g_PayTopList_Duihuan_ItemId[index].ItemId
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(49) > 0 then  --卡级
		nItemId = g_PayTopList_Duihuan_ItemId[index].KaJiItemId
	elseif Player:GetData("IsOriginalJD") == 1 then--删减服
		nItemId = g_PayTopList_Duihuan_ItemId[index].OriJDItemId
	end
	
	PushEvent("OPEN_YUANBAOSHOP_MULTI_BUYWND", nItemId, 890084, index, g_PayTopList_Duihuan_ItemId[index].Price)
	

end