--******************
--帮会商城客户端界面
--******************

local g_clientNpcId = -1;
local MAX_OBJ_DISTANCE = 3.0;

local g_CurPage = 1;			--当前在第几页
local g_CntPerPage = 18

local g_BangHuiItemName={}
local g_BangHuiItemIntr1={}
local g_BangHuiItemIntr2={}
local g_BangHui_Shop_Frame_UnifiedPosition;

--有点乱：开启 打开 server端；购买 world端
local g_BangHuiMaintainSt=0

function BangHui_Shop_PreLoad()
	this:RegisterEvent("OBJECT_CARED_EVENT",false);

	this:RegisterEvent("GUILDSHOP_UI");
	this:RegisterEvent("UI_COMMAND");

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_SELFGUILDCONTRI", false)

end

function BangHui_Shop_OnLoad()
	g_BangHuiItemName={
	BangHui_Shop_Item1,BangHui_Shop_Item2,BangHui_Shop_Item3,BangHui_Shop_Item4,BangHui_Shop_Item5,BangHui_Shop_Item6,
	BangHui_Shop_Item7,BangHui_Shop_Item8,BangHui_Shop_Item9,BangHui_Shop_Item10,BangHui_Shop_Item11,BangHui_Shop_Item12,
	BangHui_Shop_Item13,BangHui_Shop_Item14,BangHui_Shop_Item15,BangHui_Shop_Item16,BangHui_Shop_Item17,BangHui_Shop_Item18
	}
	g_BangHuiItemIntr1={
	BangHui_Shop_ItemInfo1_Text,BangHui_Shop_ItemInfo2_Text,BangHui_Shop_ItemInfo3_Text,BangHui_Shop_ItemInfo4_Text,BangHui_Shop_ItemInfo5_Text,BangHui_Shop_ItemInfo6_Text,
	BangHui_Shop_ItemInfo7_Text,BangHui_Shop_ItemInfo8_Text,BangHui_Shop_ItemInfo9_Text,BangHui_Shop_ItemInfo10_Text,BangHui_Shop_ItemInfo11_Text,BangHui_Shop_ItemInfo12_Text,
	BangHui_Shop_ItemInfo13_Text,BangHui_Shop_ItemInfo14_Text,BangHui_Shop_ItemInfo15_Text,BangHui_Shop_ItemInfo16_Text,BangHui_Shop_ItemInfo17_Text,BangHui_Shop_ItemInfo18_Text
	}
	g_BangHuiItemIntr2={
	BangHui_Shop_ItemInfo1_GB,BangHui_Shop_ItemInfo2_GB,BangHui_Shop_ItemInfo3_GB,BangHui_Shop_ItemInfo4_GB,BangHui_Shop_ItemInfo5_GB,BangHui_Shop_ItemInfo6_GB,
	BangHui_Shop_ItemInfo7_GB,BangHui_Shop_ItemInfo8_GB,BangHui_Shop_ItemInfo9_GB,BangHui_Shop_ItemInfo10_GB,BangHui_Shop_ItemInfo11_GB,BangHui_Shop_ItemInfo12_GB,
	BangHui_Shop_ItemInfo13_GB,BangHui_Shop_ItemInfo14_GB,BangHui_Shop_ItemInfo15_GB,BangHui_Shop_ItemInfo16_GB,BangHui_Shop_ItemInfo17_GB,BangHui_Shop_ItemInfo18_GB
	}
	BangHui_Shop_querengoumai:SetCheck(1)
	NpcShop:SetGuildShopBuyDirectly(1)
	g_BangHui_Shop_Frame_UnifiedPosition=BangHui_Shop_ShopFrame:GetProperty("UnifiedPosition");
end

function BangHui_Shop_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 20140512) then
		g_BangHuiMaintainSt = Get_XParam_INT(0);
		local npcData = Get_XParam_INT(1);
		if npcData>=0 then
			g_clientNpcId = Target:GetServerId2ClientId(npcData);
		end
	elseif ( event == "GUILDSHOP_UI") then
		if (arg0 == "open") then
			if g_clientNpcId<0 then
				return
			end
			this:CareObject(g_clientNpcId, 1, "BangHui_Shop");
			BangHui_Shop_Clear();
			BangHui_Shop_Update();
			this:Show();
		elseif (arg0=="update") then
			BangHui_Shop_Update();
		end
	elseif ( event == "OBJECT_CARED_EVENT") then
		BangHui_Shop_CareEventHandle(arg0,arg1,arg2);
	elseif (event == "ADJEST_UI_POS") then
		BangHui_Shop_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BangHui_Shop_Frame_On_ResetPos()
	elseif (event == "UPDATE_SELFGUILDCONTRI" and this:IsVisible()) then
		BangHui_Shop_ContriUpdate()
	end
end

function BangHui_Shop_ContriUpdate()
	local guildContri = Guild:GetGuildContri()
	BangHui_Shop_GongXianDu:SetText( ScriptGlobal_Format( "#{BHSC_140509_61}", guildContri) )
end

function BangHui_Shop_CareEventHandle(careId, op, distance)
		if(nil == careId or nil == op or nil == distance) then
			return;
		end

		if(tonumber(careId) ~= g_clientNpcId) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(op == "distance" and tonumber(distance)>MAX_OBJ_DISTANCE or op=="destroy") then
			this:Hide();
		end
end

function BangHui_Shop_Clear()
	g_CurPage = 1;--[1,5]
	-- 关闭UI
	if ( IsWindowShow( "NEWShop_MBuy" ) ) then
		CloseWindow( "NEWShop_MBuy", true );
	end
	SetDefaultMouse();
end

--0 打开；1 更新
function BangHui_Shop_Update()
	--根据不同的维护状态显示不同的文字
	local nShopLevel=City:GetGuildShopInfo(0,"shoplevel")
	if g_BangHuiMaintainSt<=1 then
		local topUIMsg=ScriptGlobal_Format( "#{BHSC_140509_40}", nShopLevel)
		BangHui_Shop_BK1_Text:SetText(topUIMsg)--处于低维护状态
	else
		local topUIMsg=ScriptGlobal_Format( "#{BHSC_140509_39}", nShopLevel)
		BangHui_Shop_BK1_Text:SetText(topUIMsg)
	end

	local TotalCnt=City:GetGuildShopInfo(0,"total")
	local nTotalPage=math.ceil(TotalCnt/g_CntPerPage)
	local nStartIdx=1+(g_CurPage-1)*g_CntPerPage
	local uiIdx=1
	for i=nStartIdx,nStartIdx+g_CntPerPage-1 do
		local theAction, isSoldOut = City:EnumGuildShop(i);
		if theAction:GetID() ~= 0 then
			--设置ActionItem
			g_BangHuiItemName[uiIdx]:SetActionItem(theAction:GetID());
			g_BangHuiItemIntr1[uiIdx]:SetText(theAction:GetItemColorInShop()..theAction:GetName());
			local contribute = City:GetGuildShopInfo(i, "contribute");
			local szShow=ScriptGlobal_Format( "#{BHSC_140509_42}", contribute)
			g_BangHuiItemIntr2[uiIdx]:SetText(szShow)
		else
			g_BangHuiItemName[uiIdx]:SetActionItem(-1);
			g_BangHuiItemIntr1[uiIdx]:SetText("");
			g_BangHuiItemIntr2[uiIdx]:SetText("")
		end
		uiIdx=uiIdx+1
	end

	--page的处理
	if nTotalPage<=1 then
		BangHui_Shop_UpPage:Hide()
		BangHui_Shop_DownPage:Hide()
		BangHui_Shop_CurrentlyPage:Hide()
	else
		BangHui_Shop_UpPage:Show()
		BangHui_Shop_DownPage:Show()
		BangHui_Shop_CurrentlyPage:Show()
		if g_CurPage<=1 then
			BangHui_Shop_UpPage:Disable()
		else
			BangHui_Shop_UpPage:Enable()
		end
		if g_CurPage>=nTotalPage then
			BangHui_Shop_DownPage:Disable()
		else
			BangHui_Shop_DownPage:Enable()
		end
		BangHui_Shop_CurrentlyPage:SetText(tostring(g_CurPage).."/"..tostring(nTotalPage))
	end
	--帮贡显示
	BangHui_Shop_ContriUpdate()
end

function BangHui_Shop_PageUp()
	--前一页
	if g_CurPage<=1 then
		return
	end
	g_CurPage=g_CurPage-1
	BangHui_Shop_Update()
end

function BangHui_Shop_PageDown()
	--后一页
	local TotalCnt=City:GetGuildShopInfo(0,"total")
	local nTotalPage=math.ceil(TotalCnt/g_CntPerPage)
	if g_CurPage>=nTotalPage then
		return
	end
	g_CurPage=g_CurPage+1
	BangHui_Shop_Update()
end

function BangHui_Shop_GoodButton_Clicked(idx)
	-- 安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{BHSC_140509_27}")
		return
	end
	-- 二级密码 电话密保检查
	if GetAuthorizedSafeFlag() == 0 and CheckPhoneMibaoAndMinorPassword() ~= 1 then --非授权安全模式下需要验证
		return
	end
	-- 入帮时间7日与否 world端检测 不同意再单做
	-- 限购，都描红了，客户端不再额外处理
	-- 检测是否为低维护 world端做

	local nItemIdx=idx+(g_CurPage-1)*g_CntPerPage
	-- 批量购买
	local bMultiBuy = City:IsGuildShopMultiBuy( nItemIdx, g_clientNpcId );
	if ( bMultiBuy == 1 ) then
		SetDefaultMouse();
		return
	end

	local check  = tonumber(NpcShop:GetGuildShopBuyDirectly());
	if check>=1 then
		--确认框 道具索引 消耗帮贡值 道具名称
		local theAction, isSoldOut = City:EnumGuildShop(nItemIdx);
		if theAction:GetID() ~= 0 then
			local itemName=theAction:GetName()
			local contribute = City:GetGuildShopInfo(nItemIdx, "contribute");
			PushEvent( "GUILDSHOP_ITEM_SURE", nItemIdx, contribute, itemName, g_clientNpcId )
		end
		return
	end
	City:DoGuildShopBuy(nItemIdx, 1)
end

function BangHui_Shop_Close()
	BangHui_Shop_Clear()
	g_clientNpcId=-1
	this:Hide()
end

function BangHui_Shop_querengoumai_Clicked()

	local check  = tonumber(NpcShop:GetGuildShopBuyDirectly());
	if(check>=1)then
		BangHui_Shop_querengoumai:SetCheck(0);
		NpcShop:SetGuildShopBuyDirectly(0)
	else
		BangHui_Shop_querengoumai:SetCheck(1);
		NpcShop:SetGuildShopBuyDirectly(1)
	end

end

function BangHui_Shop_Frame_On_ResetPos()
	BangHui_Shop_ShopFrame:SetProperty("UnifiedPosition", g_BangHui_Shop_Frame_UnifiedPosition);
end

function BangHui_Shop_MultiBuyItem()
	-- 安全时间
	if ( tonumber( DataPool:GetLeftProtectTime() ) > 0 ) then
		PushDebugMessage( "#{BHSC_140509_27}" );
		return
	end

	-- 电话密保、硬件密保、畅游+保护状态
	if GetAuthorizedSafeFlag() == 0 and CheckPhoneMibaoAndMinorPassword() ~= 1 then --非授权安全模式下需要验证
		return
	end

	-- 关闭UI
	if ( IsWindowShow( "NEWShop_MBuy" ) ) then
		CloseWindow( "NEWShop_MBuy", true );
	end

	-- 进入批量购买状态
	PrepearBuyMult();
	-- 醒目提示
	PushDebugMessage( "#{PLGM_150306_03}" );
end
