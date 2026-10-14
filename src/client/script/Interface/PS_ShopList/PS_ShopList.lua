local MAX_OBJ_DISTANCE = 3.0;
local g_ShopType = 0;			--商店类型，显示物品、珍兽、还是回收
local g_nShopIndex = {};

local g_SearchMode_SaleOut = -1; --盘出商店的排序分类：-1-默认排序 0-金币盘出 1-元宝盘出
--盘出商店的排序分类
local g_SearchItem_SaleOut = 
{
	[1] = "#{DPPC_150327_8}",--默认排列
	[2] = "#{DPPC_150327_9}",--金币盘出
	[3] = "#{DPPC_150327_10}",--元宝盘出
}

local g_StallNum = 0;  -- 存，当前这个商店有多少个柜台
local g_nCurStallIndex = -1;

--标志当前是珍兽界面还是物品界面

local g_PetIndex = {};

local STALL_ITEM = 0;
local STALL_PET  = 1;
local STALL_RECYCLE = 2;

--显示商店物品相关
local PS_BUTTON_NUM = 20;
local PS_ITEMSTALL_NUM = 10;
local PS_ITEMBUTTON = {};
local PS_ITEMSTALL_BOTTON = {};
local g_nCurSelectItem = -1;

local g_RecycleItems = {}; --回购物品

-- 界面的默认相对位置
local g_PS_ShopList_Frame_UnifiedXPosition;
local g_PS_ShopList_Frame_UnifiedYPosition;

local PAGE_HOVER ={}
local PAGE_NORMAL ={}

local g_Owner = "other"
local g_boolOwn = false

local g_IsSaleOutFarme = 0	--是否是盘出的界面
local g_bSearch = 0				--是否是从搜索过来的

--===============================================
-- OnLoad
--===============================================
function PS_ShopList_PreLoad()
	this:RegisterEvent("PS_OPEN_SHOPLIST", true);						-- 打开所有商店的列表
	this:RegisterEvent("PS_UPDATE_SEARCH_SHOPLIST", false);	-- 打开分类招招后的列表
	this:RegisterEvent("PS_OPEN_RECYCLESHOPLIST",true);	-- 打开分类招招后的列表
	this:RegisterEvent("OBJECT_CARED_EVENT", false);
	this:RegisterEvent("PS_UPDATE_SEARCH_RECYCLESHOPLIST", false);
	this:RegisterEvent("PS_CLOSE_SHOPLIST", false);	-- 关闭界面
	this:RegisterEvent("BUYPSSUCCESS_CLOSE_SHOPLIST", false) --购买商店成功后关闭商店列表界面
	this:RegisterEvent("PS_OPEN_OTHER_SHOP", true); --更新商店物品用的
	this:RegisterEvent("PS_OTHER_SELECT", false);
	this:RegisterEvent("PS_UPDATE_OTHER_SHOP", false); --更新购买商店，用于买完东西刷新
	this:RegisterEvent("OPEN_RECYCLESHOP_BUYER", true); --打开收购商店
	this:RegisterEvent("PS_OPEN_OTHER_TRANS", true);
	this:RegisterEvent("PS_UPDATE_OTHER_TRANS", false);
	this:RegisterEvent("PS_OPEN_MY_SHOP", true);
	this:RegisterEvent("PS_UPDATE_MY_SHOP", false);
	this:RegisterEvent("PS_SELF_SELECT", false);
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("CLOSE_WINDOW", false)

end


function PS_ShopList_OnLoad()

	PS_ITEMBUTTON[1] = PS_ShopList_Shop_Item1;
	PS_ITEMBUTTON[2] = PS_ShopList_Shop_Item2;
	PS_ITEMBUTTON[3] = PS_ShopList_Shop_Item3;
	PS_ITEMBUTTON[4] = PS_ShopList_Shop_Item4;
	PS_ITEMBUTTON[5] = PS_ShopList_Shop_Item5;
	PS_ITEMBUTTON[6] = PS_ShopList_Shop_Item6;
	PS_ITEMBUTTON[7] = PS_ShopList_Shop_Item7;
	PS_ITEMBUTTON[8] = PS_ShopList_Shop_Item8;
	PS_ITEMBUTTON[9] = PS_ShopList_Shop_Item9;
	PS_ITEMBUTTON[10] = PS_ShopList_Shop_Item10;
	PS_ITEMBUTTON[11] = PS_ShopList_Shop_Item11;
	PS_ITEMBUTTON[12] = PS_ShopList_Shop_Item12;
	PS_ITEMBUTTON[13] = PS_ShopList_Shop_Item13;
	PS_ITEMBUTTON[14] = PS_ShopList_Shop_Item14;
	PS_ITEMBUTTON[15] = PS_ShopList_Shop_Item15;
	PS_ITEMBUTTON[16] = PS_ShopList_Shop_Item16;
	PS_ITEMBUTTON[17] = PS_ShopList_Shop_Item17;
	PS_ITEMBUTTON[18] = PS_ShopList_Shop_Item18;
	PS_ITEMBUTTON[19] = PS_ShopList_Shop_Item19;
	PS_ITEMBUTTON[20] = PS_ShopList_Shop_Item20;
	
	PS_ITEMSTALL_BOTTON[1]   = PS_ShopList_Shop_Page1;
	PS_ITEMSTALL_BOTTON[2]   = PS_ShopList_Shop_Page2;
	PS_ITEMSTALL_BOTTON[3]   = PS_ShopList_Shop_Page3;
	PS_ITEMSTALL_BOTTON[4]   = PS_ShopList_Shop_Page4;
	PS_ITEMSTALL_BOTTON[5]   = PS_ShopList_Shop_Page5;
	PS_ITEMSTALL_BOTTON[6]   = PS_ShopList_Shop_Page6;
	PS_ITEMSTALL_BOTTON[7]   = PS_ShopList_Shop_Page7;
	PS_ITEMSTALL_BOTTON[8]   = PS_ShopList_Shop_Page8;
	PS_ITEMSTALL_BOTTON[9]   = PS_ShopList_Shop_Page9;
	PS_ITEMSTALL_BOTTON[10]  = PS_ShopList_Shop_Page10;
	
	PAGE_HOVER[1] = "set:FuJiangTianLong image:Btn_1_Hover"
	PAGE_HOVER[2] = "set:FuJiangTianLong image:Btn_2_Hover"
	PAGE_HOVER[3] = "set:FuJiangTianLong image:Btn_3_Hover"
	PAGE_HOVER[4] = "set:FuJiangTianLong image:Btn_4_Hover"
	PAGE_HOVER[5] = "set:FuJiangTianLong image:Btn_5_Hover"
	PAGE_HOVER[6] = "set:FuJiangTianLong image:Btn_6_Hover"
	PAGE_HOVER[7] = "set:FuJiangTianLong image:Btn_7_Hover"
	PAGE_HOVER[8] = "set:FuJiangTianLong image:Btn_8_Hover"
	PAGE_HOVER[9] = "set:FuJiangTianLong image:Btn_9_Hover"
	PAGE_HOVER[10] = "set:FuJiangTianLong image:Btn_10_Hover"
	
	PAGE_NORMAL[1] = "set:FuJiangTianLong image:Btn_1_Normal"
	PAGE_NORMAL[2] = "set:FuJiangTianLong image:Btn_2_Normal"
	PAGE_NORMAL[3] = "set:FuJiangTianLong image:Btn_3_Normal"
	PAGE_NORMAL[4] = "set:FuJiangTianLong image:Btn_4_Normal"
	PAGE_NORMAL[5] = "set:FuJiangTianLong image:Btn_5_Normal"
	PAGE_NORMAL[6] = "set:FuJiangTianLong image:Btn_6_Normal"
	PAGE_NORMAL[7] = "set:FuJiangTianLong image:Btn_7_Normal"
	PAGE_NORMAL[8] = "set:FuJiangTianLong image:Btn_8_Normal"
	PAGE_NORMAL[9] = "set:FuJiangTianLong image:Btn_9_Normal"
	PAGE_NORMAL[10] = "set:FuJiangTianLong image:Btn_10_Normal"

	
	
	g_RecycleItems[1] = PS_ShopList_Recycle_Item1;
	g_RecycleItems[2] = PS_ShopList_Recycle_Item2;
	g_RecycleItems[3] = PS_ShopList_Recycle_Item3;
	g_RecycleItems[4] = PS_ShopList_Recycle_Item4;
	g_RecycleItems[5] = PS_ShopList_Recycle_Item5;
	g_RecycleItems[6] = PS_ShopList_Recycle_Item6;
	g_RecycleItems[7] = PS_ShopList_Recycle_Item7;
	g_RecycleItems[8] = PS_ShopList_Recycle_Item8;
	g_RecycleItems[9] = PS_ShopList_Recycle_Item9;
	g_RecycleItems[10] = PS_ShopList_Recycle_Item10;
	g_RecycleItems[11] = PS_ShopList_Recycle_Item11;
	g_RecycleItems[12] = PS_ShopList_Recycle_Item12;
	g_RecycleItems[13] = PS_ShopList_Recycle_Item13;
	g_RecycleItems[14] = PS_ShopList_Recycle_Item14;
	g_RecycleItems[15] = PS_ShopList_Recycle_Item15;
	g_RecycleItems[16] = PS_ShopList_Recycle_Item16;
	g_RecycleItems[17] = PS_ShopList_Recycle_Item17;
	g_RecycleItems[18] = PS_ShopList_Recycle_Item18;
	g_RecycleItems[19] = PS_ShopList_Recycle_Item19;
	g_RecycleItems[20] = PS_ShopList_Recycle_Item20;

	
		-- 保存界面的默认相对位置
	g_PS_ShopList_Frame_UnifiedXPosition	= PS_ShopList_Frame : GetProperty("UnifiedXPosition");
	g_PS_ShopList_Frame_UnifiedYPosition	= PS_ShopList_Frame : GetProperty("UnifiedYPosition");
	
	
	for i=1 ,20   do
		g_PetIndex[i] = -1;
	end
		
end

--             !!!reloadscript =PS_ShopList
function PS_ShopList_OnEvent(event)
	if ( event == "PS_OPEN_SHOPLIST") then

		if ( IsWindowShow("PS_ShopSearch") ) then
			CloseWindow("PS_ShopSearch")
		end
		
		if ( IsWindowShow("PS_ShopMag") ) then
			CloseWindow("PS_ShopMag")
		end
		g_ShopType = 0		
		g_SearchMode_SaleOut = -1		
		
		local search = -1
		
		if  PlayerShop:IsCoopertiveList() == 1 then
			PS_ShopList_Check_Item3:Hide()
			PS_ShopList_Check_Item4:Hide()		
			PS_ShopList_ShopIDText:Hide()
			PS_ShopList_ShopID:Hide()
			PS_ShopList_Find:Hide()
			PS_ShopList_Shop_Button_Buy:Hide()
			PS_ShopList_Transfer:Hide()
			PS_ShopList_SaleOut_SearchModeFrame:Hide()
			PS_ShopList_DragTitle:SetText("#{JZSHYH_140214_88}")
			PS_ShopList_Button_Manage_Tips:Hide()
			PS_ShopList_Button_Manage:Enable()
			PS_ShopList_Button_Manage:Show()
			PS_ShopList_Button_Remove:Hide()
			PS_ShopList_Button_Manage:SetText("#{INTERFACE_XML_306}")
			g_IsSaleOutFarme = 0
		else
			PS_ShopList_Check_Item3:Show()
			PS_ShopList_Check_Item4:Show()		
			PS_ShopList_ShopIDText:Show()
			PS_ShopList_ShopID:Show()
			PS_ShopList_Find:Show()
			PS_ShopList_Shop_Button_Buy:Show()
			PS_ShopList_Transfer:Hide()
			PS_ShopList_SaleOut_SearchModeFrame:Hide()
			PS_ShopList_Button_Remove:Show()
			PS_ShopList_DragTitle:SetText("#{JZSHYH_140214_02}")
			PS_ShopList_Button_Manage_Tips:Hide()
		end
		
		if (arg0 ~= nil and tostring(arg0) == "PS_ShopSearch_Frame" ) then
			local index = tonumber(arg1)
			if index >= 0 and index < 3 then
				g_ShopType = index
				if (arg2 and arg3) then
					PS_ShopList_Frame:SetProperty("UnifiedXPosition", tostring(arg2));
					PS_ShopList_Frame:SetProperty("UnifiedYPosition", tostring(arg3));
				end
			end
			
			if  (arg4  ~= nil and tonumber(arg4) > 0 ) then
				search = tonumber(arg4);
			end
		else
			if tonumber(arg0) > 0 and  PlayerShop:IsCoopertiveList() ~= 1 then		--如果从盘出商店选进来，不显示搜索
				local isSaleOut = tonumber(arg1);
				if isSaleOut > 0 then
					PS_ShopList_Check_Item3:Hide()
					PS_ShopList_Check_Item4:Hide()
					PS_ShopList_ShopIDText:Hide()
					PS_ShopList_ShopID:Hide()
					PS_ShopList_Find:Hide()
					PS_ShopList_Button_Remove:Hide()
					PS_ShopList_Shop_Bk:Hide()
					PS_ShopList_Button_Manage_Tips:Hide()
					PS_ShopList_Button_Manage:Enable()
					PS_ShopList_Button_Manage:Show()
					PS_ShopList_Button_Manage:SetText("#{JZSHYH_140214_81}")
					PS_ShopList_DragTitle:SetText("#{JZSHYH_140214_89}")
					PS_ShopList_Transfer:Show()
					PS_ShopList_SaleOut_SearchModeFrame:Show()
					PS_ShopList_SaleOut_SearchMode:ResetList()
					for i=1,3 do
						PS_ShopList_SaleOut_SearchMode:AddTextItem(g_SearchItem_SaleOut[i], i)
					end
					PS_ShopList_SaleOut_SearchMode:SetCurrentSelect(0)
					PS_ShopList_ShopInfo:Hide()
					PS_ShopList_Transfer_Sale_Name:Show()
					PS_ShopList_Transfer_Self_Name:Show()
					PS_ShopList_Transfer_Sale_Yuanbao:SetText("")		
					PS_ShopList_Transfer_Self_Yuanbao:SetText("")
					PS_ShopList_Transfer_Sale_Name_Yuanbao:Hide()
					PS_ShopList_Transfer_Self_Name_Yuanbao:Hide()
					PS_ShopList_Transfer_CurBase_Money:SetProperty("MoneyNumber", tostring(0));
					
					PS_ShopList_Transfer_Gain_Money:SetProperty("MoneyNumber", tostring(0));
					
					PS_ShopList_Transfer_Sale_Money:SetProperty("MoneyNumber", tostring(0));

					PS_ShopList_Transfer_Self_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
					g_IsSaleOutFarme = 1
				else
					PS_ShopList_Check_Item3:Show()
					PS_ShopList_Check_Item4:Show()
					PS_ShopList_ShopIDText:Show()
					PS_ShopList_ShopID:Show()
					PS_ShopList_Find:Show()					
					PS_ShopList_Button_Remove:Show()
					PS_ShopList_Shop_Bk:Show()
					PS_ShopList_Button_Manage_Tips:Hide()
					PS_ShopList_Button_Manage:Enable()
					PS_ShopList_Button_Manage:Show()
					PS_ShopList_Button_Manage:SetText("#{INTERFACE_XML_306}")
					PS_ShopList_DragTitle:SetText("#{JZSHYH_140214_02}")
					PS_ShopList_Transfer:Hide()
					PS_ShopList_SaleOut_SearchModeFrame:Hide()
					PS_ShopList_ShopInfo:Show()
					g_IsSaleOutFarme = 0
					
				end
			end
		end
		

		
		this:Show();
		

		objCared = PlayerShop:GetNpcId();
		this:CareObject(objCared, 1, "PS_Shoplist");
		PS_ShopList_ShopID:SetText("")
		
		PS_ShopList_SearchLogic();
		PS_ShopList_UpdateFrameBase();
		
		if(search > 0 ) then
			PS_ShopList_ShopID:SetText(search)
			PS_ShopList_Find_Clicked()
		end
		
	
	elseif ( event == "OBJECT_CARED_EVENT" ) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();

			--取消关心
			this:CareObject(objCared, 0, "PS_Shoplist");
		end	
		
	elseif (event == "PS_OPEN_OTHER_SHOP") then		--打开商店

		g_nCurStallIndex = 1;
		
		g_Owner = "other"
		g_boolOwn = false
		g_StallNum = PlayerShop:GetStallNum(g_Owner);
		PS_ShopList_UpdateDetailShopInfo()
		PS_Shop_UpdateStall()
	elseif ( event == "PS_OPEN_OTHER_TRANS") then
		g_nCurStallIndex = 1;
		g_Owner = "other"
		g_boolOwn = false
		g_StallNum = PlayerShop:GetStallNum(g_Owner);
		PS_ShopList_UpdateDetailShopInfo()
		PS_Shop_UpdateStall()
	elseif (event == "PS_OPEN_MY_SHOP") then
		if(this:IsVisible() ) then
			g_nCurStallIndex = 1;
			g_Owner = "self"
			g_boolOwn = true
			g_StallNum = PlayerShop:GetStallNum(g_Owner);
			PS_ShopList_UpdateDetailShopInfo()
			PS_Shop_UpdateStall()	
		end
	elseif ( event == "PS_UPDATE_OTHER_TRANS") then
		PS_ShopList_UpdateDetailShopInfo();
		PS_Shop_UpdateStall()		
	elseif ( event == "PS_UPDATE_MY_SHOP") then
		if(this:IsVisible() and g_nCurStallIndex ~=-1) then
			PS_ShopList_UpdateDetailShopInfo();
			PS_Shop_UpdateStall()		
		end
	elseif ( event == "PS_OTHER_SELECT") then
		if(this:IsVisible() and g_nCurStallIndex ~=-1) then
			g_nCurSelectItem = PlayerShop:GetSelectIndex("other");
			PS_Shop_UpdateStall()
			PS_ShopList_UpdateDetailShopInfo();
		end
	elseif ( event == "PS_SELF_SELECT") then
		if(this:IsVisible() and g_nCurStallIndex ~=-1) then
			g_nCurSelectItem = PlayerShop:GetSelectIndex("self");
			PS_Shop_UpdateStall()
			PS_ShopList_UpdateDetailShopInfo();
		end
	elseif event == "BUYPSSUCCESS_CLOSE_SHOPLIST" then --购买商店成功后关闭商店列表界面
		--隐藏界面		
		this:Hide();		
		this:CareObject(objCared, 0, "PS_Shoplist");

	elseif ( event == "PS_UPDATE_OTHER_SHOP") then
		PS_ShopList_UpdateDetailShopInfo();
		PS_Shop_UpdateStall()
	elseif ( event == "OPEN_RECYCLESHOP_BUYER" ) then
		PS_ShopList_UpdateDetailRecycleShopInfo();
		PS_ShopList_UpdateRecycleStall();
	elseif ( event == "PS_UPDATE_SEARCH_RECYCLESHOPLIST") then
		PS_ShopList_UpdateFrameBase();
		PS_ShopList_UpdateDetailRecycleShopInfo();
		PS_ShopList_UpdateRecycleStall();
		PS_ShopList_RecycleShopList:SetSelectItem(0);
	elseif (event == "PS_UPDATE_SEARCH_SHOPLIST") then
		g_Selectindex = -1;
		PS_ShopList_UpdateFrame()	
	elseif (event == "ADJEST_UI_POS") then
		PS_ShopList_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PS_ShopList_Frame_On_ResetPos()
	elseif (event == "CLOSE_WINDOW") then
		if this:IsVisible()  and tostring(arg0) == "PS_ShopList" then
			if PlayerShop:IsCoopertiveList() == 1 or g_IsSaleOutFarme == 1 then
				this:Hide()
			end
		elseif this:IsVisible() and tostring(arg0) == "PS_ShopListQuick" then
			this:Hide()
		end
	end

end

function PS_ShopList_CleanFrame()


end

--================================================
-- 恢复界面的默认相对位置
--================================================
function PS_ShopList_Frame_On_ResetPos()

	PS_ShopList_Frame : SetProperty("UnifiedXPosition", g_PS_ShopList_Frame_UnifiedXPosition);
	PS_ShopList_Frame : SetProperty("UnifiedYPosition", g_PS_ShopList_Frame_UnifiedYPosition);

end



function PS_ShopList_ChangeTabIndex(nType)
	if nType < 0 or nType > 3 then
		return
	end
	
	if g_ShopType == nType then 
		return
	end
	g_ShopType = nType
	
	--重置盘出商店搜索选项
	if g_IsSaleOutFarme == 1 then
		g_SearchMode_SaleOut = -1		
		PS_ShopList_SaleOut_SearchMode:SetCurrentSelect(0)
	end
			
	PS_ShopList_SearchLogic()
	-- PS_ShopList_UpdateFrame()
	
end

--修改盘出商店的查找类型
function PS_ShopList_SaleOut_SearchModeChanged()
	--获得当前选项
	local str,nMode = PS_ShopList_SaleOut_SearchMode:GetCurrentSelect()
	--有效性判断
	if nMode <= 0 or nMode > 3 then
		return
	end
	
	--设置盘出商店搜索类型
	if g_SearchMode_SaleOut == nMode - 2 then 
		return
	end
	g_SearchMode_SaleOut = nMode - 2
	
	--搜索商店
	PS_ShopList_SearchLogic()	
end

--设置商店界面的样式
function PS_ShopList_SetShopFrameType()
	if g_ShopType == 0 then

		PS_ShopList_PetSHopFromeHide()
		PS_ShopList_RecycleShopFrameHide()
		PS_ShopList_ItemShopFrameShow()
		
	elseif g_ShopType == 1 then
		PS_ShopList_ItemShopFrameHide()
		PS_ShopList_RecycleShopFrameHide()
		PS_ShopList_PetSHopFromeShow()	
	elseif g_ShopType == 2 then
		PS_ShopList_ItemShopFrameHide()
		PS_ShopList_PetSHopFromeHide()
		PS_ShopList_RecycleShopFrameShow()
	end
end


--显示物品商店界面
function PS_ShopList_ItemShopFrameShow()
	PS_ShopList_Check_Item1:SetCheck(1)
	PS_ShopList_ShopList:Show()
	PS_ShopList_Shop_Frame_Client:Show()
	PS_ShopList_Quantity:Hide()
	PS_ShopList_Shop_PageList:Show()
	PS_ShopList_Shop_PetList_Client:Show()
	
	PS_ShopList_CleanItemFrame()
end

--清空数据

function PS_ShopList_CleanItemFrame()
	PS_ShopList_Shop_Commonitem:SetText("")
	PS_ShopList_ShopOwner:SetText("")
	PS_ShopList_ShopOwnerID:SetText("")
	PS_ShopList_DPID:SetText("")
	PS_ShopList_Since:SetText("")
	PS_ShopList_Shop_Price:SetProperty("MoneyNumber", tostring(0));
	
	g_StallNum = 0
	for i=1 ,PS_ITEMSTALL_NUM  do
		PS_ITEMSTALL_BOTTON[i]:SetProperty("NormalImage", PAGE_NORMAL[i])
		PS_ITEMSTALL_BOTTON[i]:Disable();
	end
	
	for i = 1, PS_BUTTON_NUM do
		PS_ITEMBUTTON[i]:SetActionItem(-1);
	end
	
	PS_ShopList_Shop_Item_Num:SetText("")
	
	PS_ShopList_Shop_Next:Disable();
	PS_ShopList_Shop_Last:Disable();
	
	PS_ShopList_Shop_PageNum:SetText("")
	
	PS_ShopList_ShopInfo:SetText("")
	
end

--隐藏物品商店界面
function PS_ShopList_ItemShopFrameHide()
	PS_ShopList_Check_Item1:SetCheck(0)
	PS_ShopList_ShopList:Hide()
	PS_ShopList_Shop_PetList_Client:Hide()
end


--显示收购商店界面
function PS_ShopList_RecycleShopFrameShow()
	PS_ShopList_RecycleShopList:Show()
	PS_ShopList_Recycle_Frame_Client:Show()
	PS_ShopList_Shop_Frame_Client:Hide()
	PS_ShopList_Recycle_PetList:Hide() --根本没有回收珍兽的功能啊，直接屏蔽也不再显示了
	PS_ShopList_CleanRecycleFrame()
end

function PS_ShopList_CleanRecycleFrame()
	PS_ShopList_Recycle_Commonitem:SetText("")
	PS_ShopList_Recycle_Nub1:SetText("")
	PS_ShopList_Recycle_Nub2:SetText("")
	PS_ShopList_Recycle_Item_Num:SetText("")
	PS_ShopList_Recycle_Price:SetProperty("MoneyNumber", tostring(0));
	
	PS_ShopList_ShopInfo:SetText("")
	
	for i=1, PS_BUTTON_NUM do
			g_RecycleItems[i]:SetActionItem(-1);
	end
end

--隐藏收购商店界面
function PS_ShopList_RecycleShopFrameHide()
	PS_ShopList_RecycleShopList:Hide()
	PS_ShopList_Recycle_Frame_Client:Hide()
	PS_ShopList_Shop_Frame_Client:Show()
end

--隐藏珍兽商店
function PS_ShopList_PetSHopFromeHide()
	PS_ShopList_ShopList:Hide()
	PS_ShopList_Shop_PageList:Hide()
	PS_ShopList_Shop_PetList:Hide()
end

--显示珍兽商店
function PS_ShopList_PetSHopFromeShow()
	PS_ShopList_Check_Item2:SetCheck(1)
	PS_ShopList_ShopList:Show()
	PS_ShopList_Shop_PageList:Show()
	PS_ShopList_Shop_PetList:Show()
	
	PS_ShopList_CleanPetFrame()
end

function PS_ShopList_CleanPetFrame()
	PS_ShopList_Shop_Commonitem:SetText("")
	PS_ShopList_ShopOwner:SetText("")
	PS_ShopList_ShopOwnerID:SetText("")
	PS_ShopList_DPID:SetText("")
	PS_ShopList_Since:SetText("")
	PS_ShopList_Shop_Price:SetProperty("MoneyNumber", tostring(0));
	
	for i=1 ,PS_ITEMSTALL_NUM  do
		PS_ITEMSTALL_BOTTON[i]:SetProperty("NormalImage", PAGE_NORMAL[i])
		PS_ITEMSTALL_BOTTON[i]:Disable();
	end
	
	PS_ShopList_Shop_Item_Num:SetText("")
	
	PS_ShopList_Shop_Next:Disable();
	PS_ShopList_Shop_Last:Disable();
	
	PS_ShopList_Shop_PageNum:SetText("")
	
	PS_ShopList_ShopInfo:SetText("")
	
	PS_ShopList_Shop_PetList:ClearListBox();
end


function PS_Shop_UpdateStall()
	if(g_ShopType == STALL_ITEM) then
		PS_ShopList_UpdateItemStall()
	elseif (g_ShopType == STALL_PET) then
		PS_ShopList_UpdatePetStall()
	end
end

function PS_ShopList_SearchLogic()

	if g_ShopType == STALL_ITEM then
		PlayerShop:FindShop("item",-1,g_SearchMode_SaleOut);
	elseif g_ShopType == STALL_PET then
		PlayerShop:FindShop("pet",-1,g_SearchMode_SaleOut);	
	elseif g_ShopType == STALL_RECYCLE then
		PlayerShop:FindShop("recycleshop",0);
	else
		PS_ShopList_Check_Item4:SetCheck(1)
		PushEvent("OPEN_PLAYERSHOP_SEARCH", "PS_ShopList_Frame", tostring(g_ShopType), PS_ShopList_Frame:GetProperty("UnifiedXPosition"), PS_ShopList_Frame:GetProperty("UnifiedYPosition"))
	
	end
end


function PS_ShopList_UpdateFrameBase()
	PS_ShopList_SetShopFrameType()
	local ListCtr;
	if g_ShopType == STALL_ITEM then
		ListCtr = PS_ShopList_ShopList
		ListCtr:RemoveAllItem();
		ListCtr:SetProperty("SortDirection", "None")
		PS_ShopList_Check_Item1:SetCheck(1)
	elseif g_ShopType == STALL_PET then
		ListCtr = PS_ShopList_ShopList
		ListCtr:RemoveAllItem();
		ListCtr:SetProperty("SortDirection", "None")
		PS_ShopList_Check_Item2:SetCheck(1)
	elseif g_ShopType == STALL_RECYCLE then
		ListCtr = PS_ShopList_RecycleShopList
		ListCtr:RemoveAllItem();
		ListCtr:SetProperty("SortDirection", "None")
		PS_ShopList_Check_Item3:SetCheck(1)
	else
		PS_ShopList_Check_Item4:SetCheck(1)
	end
	
	
	local nNum = PlayerShop:GetShopNum("search")
	
	
	for i = 0, nNum-1 do
		local nIndex = PlayerShop:EnumSearchShopIndex(i);
		
		local szShopName,OpenNum,SaleNum,szType,nIsFavor,nRecItemnum, nFrezeType, nShopIndex = PlayerShop:EnumShop(nIndex);
		
		if g_bSearch == 1 then
			PS_ShopList_TableSet(szType)
			g_bSearch = 0
		end
				-- 为了支持排序, 改成 00/00 的统一格式, 注意得到的 SaleNum 和 OpenNum 是字符串
		local strSaleNum = SaleNum
		local strOpenNum = OpenNum
		if (tonumber(SaleNum) < 10) then
			strSaleNum = "0" .. tostring(SaleNum)
		end
		if (tonumber(OpenNum) < 10) then
			strOpenNum = "0" .. tostring(OpenNum)
		end
		local szState = strSaleNum.."/"..strOpenNum

		if g_ShopType ==0 and szShopName == g_LastSelect_NormalShop then
			g_Selectindex = i;
		end

		if g_ShopType ==1 and szShopName == g_LastSelect_RecycleShop then
			g_Selectindex = i;
		end

		-- 为了让排序能够正常按照字符串比较, 统一 shopindex 的长度
		local strShopIndex = nShopIndex
		if (tonumber(nShopIndex) < 10) then
			strShopIndex = "00" .. strShopIndex
		elseif (tonumber(nShopIndex) < 100) then
			strShopIndex = "0" .. strShopIndex
		end

		if nFrezeType == 1 then
			strShopIndex = "#cCCCCCC" .. strShopIndex
			szShopName = "#cCCCCCC" .. szShopName
			szState    = "#cCCCCCC" .. szState
			szType     = "#cCCCCCC" .. szType
			nRecItemnum =  "#cCCCCCC" .. nRecItemnum
		elseif nIsFavor == 1 then
			strShopIndex = "#B" .. strShopIndex
			szShopName = "#B" .. szShopName;
			szState    = "#B" .. szState;
			szType     = "#B" .. szType;
			nRecItemnum =  "#B" .. nRecItemnum;
		end
		
		g_nShopIndex[i] = nIndex;
		
		if ListCtr == nil then
			return;
		end
		
		if ( g_ShopType == STALL_ITEM or g_ShopType == STALL_PET ) then
			ListCtr:AddNewItem(strShopIndex, 0, i)
			ListCtr:AddNewItem(szShopName, 1, i);
			ListCtr:AddNewItem(szState, 2, i);
			ListCtr:AddNewItem(szType, 3, i);
		else
			-- 材料收购
			ListCtr:AddNewItem(strShopIndex, 0, i)
			ListCtr:AddNewItem(szShopName, 1, i);
			ListCtr:AddNewItem(nRecItemnum, 2, i);		
		
		end
		

		
	end
	
		--商业指数
	local szTemp = PlayerShop:GetCommercialFactor();
	PS_ShopList_Commerce:SetText("商业指数：" .. szTemp);
end


function PS_ShopList_TableSet(szType)
		local shoptype = STALL_ITEM
		if g_ShopType == STALL_RECYCLE then
			return
		end
		if szType == "珍兽店" then
			shoptype = STALL_PET
			if g_ShopType ~= shoptype then
				PS_ShopList_ItemShopFrameHide()
				PS_ShopList_RecycleShopFrameHide()
				PS_ShopList_PetSHopFromeShow()	--需要从其他界面切换过来
				g_ShopType = shoptype
			end
		else
			shoptype = STALL_ITEM
			if g_ShopType ~= shoptype then
				PS_ShopList_PetSHopFromeHide()
				PS_ShopList_RecycleShopFrameHide()
				PS_ShopList_ItemShopFrameShow()
				g_ShopType = shoptype
			end
		end	
end

function PS_ShopList_UpdateFrame()



	PS_ShopList_UpdateFrameBase()	

	local nNum = PlayerShop:GetShopNum("search")
	
	if nNum > 0 then
		PS_ShopList_ShopList:SetSelectItem(0);
		PS_ShopList_RecycleShopList:SetSelectItem(0);
	end

	-- PS_ShopList_SelectChanged();
	
	
	

end


--===============================================
-- 点击列表
--===============================================
function PS_ShopList_SelectChanged()
	local nIndex = PS_ShopList_ShopList:GetSelectItem();

	g_Selectindex = nIndex;

	if(g_Selectindex == -1)  then
		return;
	end
	PlayerShop:SetCurSelShopIdx(g_nShopIndex[nIndex]);

	local szShopName,OpenNum,SaleNum,szType,nIsFavor,nRecItemnum, nFrezeType = PlayerShop:EnumShop(g_nShopIndex[nIndex]);

	g_LastSelect_NormalShop = szShopName;
	
	
	--更新显示的信息
	local strOwner = PlayerShop:EnumShopInfo("ownerguid",g_nShopIndex[nIndex]);
	local guid = Player:GetGUID()
	PlayerShop:SetServerOpen(1) 
	if strOwner == guid then
		PS_ShopList_Shop_Button_Buy_Tips:Show()
		
		PushDebugMessage("#{JZSHYH_140214_86}")
		
		if(g_IsSaleOutFarme == 1 )then
			PS_ShopList_Button_Manage_Tips:Show()
			PS_ShopList_Button_Manage:Disable()
		end
		
	else
		
		if(PlayerShop:IsCoopertiveList() == 1) then
			PlayerShop:SetServerOpen(1) 
		end
		if(g_IsSaleOutFarme == 1 ) then
			PS_ShopList_Button_Manage_Tips:Hide()
			PS_ShopList_Button_Manage:Enable()	
		end
		PS_ShopList_Shop_Button_Buy_Tips:Hide()
	end
	--更新显示的基本信息

	PS_ShopList_UpdateShopInfo()
	PS_ShopListAccept_Clicked("buy")

end


--===============================================
-- 更新商店的信息  用于获得查看商店协议带回来的数据
--===============================================

function PS_ShopList_UpdateShopInfo()

	if g_Selectindex == -1    then
		return;
	end
	
	
	--更新信息
	--开店时间

	
	local szSince = PlayerShop:EnumShopInfo("since",g_nShopIndex[g_Selectindex]);
	PS_ShopList_Since:SetText("创建时间：".. szSince);
	

	
	-- 店主名字 --改为超链接 by wangdw
	local szName = PlayerShop:EnumShopInfo("ownername",g_nShopIndex[g_Selectindex]);
	PS_ShopList_ShopOwner:SetChatString("#Y店主：#{_INFOUSR".. szName .. "}");
	

	-- 店铺ID
	local shopIndex = PlayerShop:EnumShopInfo("shopindex", g_nShopIndex[g_Selectindex])
	if (tonumber(shopIndex) <= 0) then
		PS_ShopList_DPID:SetText("#Y店铺ID：")
	else
		PS_ShopList_DPID:SetText("#Y店铺ID：" .. shopIndex)
	end
	
	-- 店主ID
	local szID = PlayerShop:EnumShopInfo("ownerid",g_nShopIndex[g_Selectindex]);
	local szIDText = ConvertGuidToShow(szID)
	PS_ShopList_ShopOwnerID:SetText("店主ID：".. szIDText);
	
	-- 介绍
	local szInfo = "";
	if(g_ShopType == 0 or g_ShopType == 1)then
		 szInfo = PlayerShop:EnumShopInfo("desc",g_nShopIndex[g_Selectindex]);
	else
		 szInfo = PlayerShop:EnumShopInfo("recdesc",g_nShopIndex[g_Selectindex]);
	end
	
	
	PS_ShopList_ShopInfo:SetText(szInfo);
	
	
	-- 加入/去除 名店
	if( g_Selectindex == -1 )   then
		return;
	end
	local szShopName,OpenNum,SaleNum,szType,nIsFavor = PlayerShop:EnumShop(g_nShopIndex[g_Selectindex]);
	if(nIsFavor == 1)   then
		PS_ShopList_Button_Remove:SetText("去除名店");
	else
		PS_ShopList_Button_Remove:SetText("#{INTERFACE_XML_353}");
	end
	
	--合作店铺数·这个在查看所有商店的原来接口中无法获取
	-- local cooperativeNum = PlayerShop:GetShopNum("all");
	-- PS_ShopList_Quantity:SetText("合作店铺数:"..cooperativeNum);
	
end

--===============================================
-- 更新商店详细的信息  相当于过去打开商店的操作
--===============================================

function PS_ShopList_UpdateDetailShopInfo()
		
		if(g_nCurStallIndex <= 0) then
			
			return
		end
		
		

		local actIndex = PlayerShop:UIIndexToLogicIndex(g_nCurStallIndex-1, g_boolOwn)
		PlayerShop:SetCurSelectPage(g_Owner,actIndex);
		--界面控件的一些更新
		if( g_nCurStallIndex == 1 )  then
			PS_ShopList_Shop_Last:Disable();
		else
			PS_ShopList_Shop_Last:Enable();
		end
		if( g_nCurStallIndex == g_StallNum )   then
			PS_ShopList_Shop_Next:Disable();
		else
			PS_ShopList_Shop_Next:Enable();
		end
		PS_ShopList_Shop_PageNum:SetText( tostring(g_nCurStallIndex).."/".. tostring(g_StallNum));


	--提示这个柜台当前的状态是Open还是Close
	local actIndex = PlayerShop:UIIndexToLogicIndex(g_nCurStallIndex-1, g_boolOwn)
	local g_bCurStallOpen = PlayerShop:IsOpenStall(g_Owner,actIndex);

	if (g_bCurStallOpen == 2)  then 
		PS_ShopList_Shop_State:SetText("#G开张");
	else
		PS_ShopList_Shop_State:SetText("#R打烊");
	end		
	
	
	--能够点击的1234567890
	for i=1 ,PS_ITEMSTALL_NUM  do
		PS_ITEMSTALL_BOTTON[i]:SetProperty("NormalImage", PAGE_NORMAL[i])
		PS_ITEMSTALL_BOTTON[i]:Disable();
	end
	for i=1 ,g_StallNum  do
		PS_ITEMSTALL_BOTTON[i]:Enable();
	end
	

	-- PS_ITEMSTALL_BOTTON[g_nCurStallIndex]:SetCheck(1);	
	PS_ITEMSTALL_BOTTON[g_nCurStallIndex]:SetProperty("NormalImage", PAGE_HOVER[g_nCurStallIndex])
	if g_IsSaleOutFarme == 0 then
		if g_boolOwn == true then
			PS_ShopList_Shop_Button_Buy:Disable()
			PS_ShopList_Shop_Button_Buy_Tips:Show()
			PS_ShopList_Button_Manage:Show()
		else
			PS_ShopList_Shop_Button_Buy:Enable()
			PS_ShopList_Shop_Button_Buy_Tips:Hide()
			PS_ShopList_Button_Manage:Hide()
		end
	end
	

	if ( g_ShopType ==  STALL_ITEM ) then
			
	
			local nMoney = PlayerShop:GetObjPrice(g_Owner,"item");
			PS_ShopList_Shop_Price:SetProperty("MoneyNumber", tostring(nMoney));
			local szItemName;
			local szNum;
			szItemName,szNum = PlayerShop:GetObjName(g_Owner,"item");
			
			PS_ShopList_Shop_Commonitem:SetText(szItemName);
			PS_ShopList_Shop_Item_Num:SetText(szNum);
	end
end
			--



function PS_ShopListAccept_Clicked(szType)

		if g_Selectindex >= 0 then
			if g_ShopType == STALL_ITEM or g_ShopType == STALL_PET then
				if(szType == "buy") then
					PlayerShop:AskOpenShop("buy",g_nShopIndex[g_Selectindex]);
				else
					if g_IsSaleOutFarme == 0 then
						PlayerShop:AskOpenShop("manage",g_nShopIndex[g_Selectindex]);
						this:Hide();
					else
						PS_ShopList_BuyShop()
					end
				end
			else
				if(szType == "buy") then
					PlayerShop:OpenRecycleShopDLG2(g_nShopIndex[g_Selectindex],"buy");
				else
					PlayerShop:AskOpenShop("manage",g_nShopIndex[g_Selectindex]);
					this:Hide();
				end
			end
		else
			if ( PlayerShop:GetShopListType() == "coopertive" )	then
				PushDebugMessage("#{HZDP_131202_07}");
			else
				PushDebugMessage("请选择一个商店");
			end
			return;		
		end
	
end

function PS_ShopList_BuyShop()
	--获得盘出方式和盘出价格
	local bSaleType = PlayerShop:GetSaleType("other");
	local nSaleOutMoney = PlayerShop:GetMoney("saleout","other");
	
	--判断金钱和元宝
	if bSaleType == 0 then--金币盘出
		local HaveMoney = Player:GetData("MONEY");
		if(tonumber(HaveMoney)<tonumber(nSaleOutMoney))then
			PushDebugMessage("#{GMGameInterface_Script_PlayerShop_NOMONEY}")
			return
		end
	elseif bSaleType == 1 then--元宝盘出
		local HaveMoney = Player:GetData("YUANBAO");
		if(tonumber(HaveMoney)<tonumber(nSaleOutMoney))then
			PushDebugMessage("#{DPPC_150327_13}")
			return
		end
	end
	
	--判断等级
	local nlevel = Player:GetData( "LEVEL" );
	if(nlevel<50)then
		PushDebugMessage("#{GMGameInterface_Script_PlayerShop_12}")
		return
	end
	--判断VIP等级
	local nVipLevel = DataPool:GetAccVipLevel()
	if(nVipLevel<2)then
		PushDebugMessage("#{RCYH_180522_19}")
		return
	end
	--判断装备最高评分
	local nEquipScoreH = Player:GetData( "EQUIPSCOREHH" );
	if(nEquipScoreH<5000)then
		PushDebugMessage("#{RCYH_180522_20}")
		return
	end
	local szName = PlayerShop:GetShopInfo("other","ownername");
	local shopIndex = PlayerShop:EnumShopInfo("shopindex", g_nShopIndex[g_Selectindex])
	local _,_,_,_,_,_, nFrezeType = PlayerShop:EnumShop(g_nShopIndex[g_Selectindex])
	if nFrezeType == 1  then
		PushDebugMessage("#{GCPlayerShopErrorHandler_ERR_SHOP_FREEZE}")
		return
	end
	PushEvent("OPEN_PS_MESSAGE_FRAME", "ps_buy", bSaleType, nSaleOutMoney, szName, shopIndex)
	--购买商店
	-- PlayerShop:BuyShop();
			
	--隐藏界面		
	-- this:Hide();
						
	--this:CareObject(objCared, 0, "PS_Shoplist");
end

function PS_ShopList_UpdateItemStall()

	if PlayerShop:GetSelfPlaceNew() == "boss" then
		
		-- 注意当前绘制的是第g_nCurStallIndex个柜台上的物品
		g_nCurSelectItem = PlayerShop:GetSelectIndex("self");
		for i=1, PS_BUTTON_NUM    do
			local actIndex = PlayerShop:UIIndexToLogicIndex(g_nCurStallIndex-1, true)
			local theAction, bLocked = PlayerShop:EnumItem(actIndex, i-1, "self");
			
			if theAction:GetID() ~= 0 then
				PS_ITEMBUTTON[i]:SetActionItem(theAction:GetID());
				if g_nCurSelectItem == i   then
					PS_ITEMBUTTON[i]:SetPushed(1);
				else
					PS_ITEMBUTTON[i]:SetPushed(0);
				end
				if(bLocked == true) then 
					PS_ITEMBUTTON[i]:Disable();
				else
					PS_ITEMBUTTON[i]:Enable();
				end
			else
				PS_ITEMBUTTON[i]:SetActionItem(-1);
			end
		end
		
		--卖出的商店
		if g_IsSaleOutFarme == 1 then
			--当前本金
			local nBaseMoney = PlayerShop:GetMoney("base","self");
			PS_ShopList_Transfer_CurBase_Money:SetProperty("MoneyNumber", tostring(nBaseMoney));
			
			--赢利资金
			local nProfitMoney = PlayerShop:GetMoney("profit","self");
			PS_ShopList_Transfer_Gain_Money:SetProperty("MoneyNumber", tostring(nProfitMoney));
			
			--设置盘店信息	
			local bSaleType = PlayerShop:GetSaleType("self");
			if bSaleType == 0 then--金币盘出
				--界面显示隐藏
				PS_ShopList_Transfer_Sale_Name:Show()
				PS_ShopList_Transfer_Self_Name:Show()
				PS_ShopList_Transfer_Sale_Yuanbao:SetText("")		
				PS_ShopList_Transfer_Self_Yuanbao:SetText("")
				PS_ShopList_Transfer_Sale_Name_Yuanbao:Hide()
				PS_ShopList_Transfer_Self_Name_Yuanbao:Hide()
				--盘出店价格
				local nSaleOutMoney = PlayerShop:GetMoney("saleout","self");
				PS_ShopList_Transfer_Sale_Money:SetProperty("MoneyNumber", tostring(nSaleOutMoney));				
				--身上现金
				PS_ShopList_Transfer_Self_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
			elseif bSaleType == 1 then--元宝盘出
				--界面显示隐藏
				PS_ShopList_Transfer_Sale_Name_Yuanbao:Show()
				PS_ShopList_Transfer_Self_Name_Yuanbao:Show()
				PS_ShopList_Transfer_Sale_Money:SetProperty("MoneyNumber", tostring(0));
				PS_ShopList_Transfer_Self_Money:SetProperty("MoneyNumber", tostring(0));
				PS_ShopList_Transfer_Sale_Name:Hide()
				PS_ShopList_Transfer_Self_Name:Hide()
				--盘出店价格
				local nSaleOutYuanbao = PlayerShop:GetMoney("saleout","self");
				if nSaleOutYuanbao > 100000 then
					nSaleOutYuanbao = 100000
				end
				PS_ShopList_Transfer_Sale_Yuanbao:SetText(tostring(nSaleOutYuanbao));				
				--身上现金
				PS_ShopList_Transfer_Self_Yuanbao:SetText(tostring(Player:GetData("YUANBAO")));
			end
		end
	
	else

		--注意当前绘制的是第g_nCurStallIndex个柜台上的物品
		g_nCurSelectItem = PlayerShop:GetSelectIndex(g_Owner);
		
		for i = 1, PS_BUTTON_NUM do
			local actIndex = PlayerShop:UIIndexToLogicIndex(g_nCurStallIndex-1, g_boolOwn)
			local theAction,bLocked = PlayerShop:EnumItem(actIndex, i - 1, g_Owner)
			
			if theAction:GetID() ~= 0 then
				PS_ITEMBUTTON[i]:SetActionItem(theAction:GetID());
				
				if (g_nCurSelectItem == i )   then 
					PS_ITEMBUTTON[i]:SetPushed(1);
				else
					PS_ITEMBUTTON[i]:SetPushed(0);
				end
				if(bLocked == true) then 
					PS_ITEMBUTTON[i]:Disable();
				else
					PS_ITEMBUTTON[i]:Enable();
				end
				
			else
				PS_ITEMBUTTON[i]:SetActionItem(-1);
			end
			
		end
		
			--卖出的商店
		if g_IsSaleOutFarme == 1 then
			--当前本金
			local nBaseMoney = PlayerShop:GetMoney("base","other");
			PS_ShopList_Transfer_CurBase_Money:SetProperty("MoneyNumber", tostring(nBaseMoney));
			
			--赢利资金
			local nProfitMoney = PlayerShop:GetMoney("profit","other");
			PS_ShopList_Transfer_Gain_Money:SetProperty("MoneyNumber", tostring(nProfitMoney));
			
			--设置盘店信息	
			local bSaleType = PlayerShop:GetSaleType("other");
			if bSaleType == 0 then--金币盘出
				--界面显示隐藏
				PS_ShopList_Transfer_Sale_Name:Show()
				PS_ShopList_Transfer_Self_Name:Show()
				PS_ShopList_Transfer_Sale_Yuanbao:SetText("")		
				PS_ShopList_Transfer_Self_Yuanbao:SetText("")
				PS_ShopList_Transfer_Sale_Name_Yuanbao:Hide()
				PS_ShopList_Transfer_Self_Name_Yuanbao:Hide()
				--盘出店价格
				local nSaleOutMoney = PlayerShop:GetMoney("saleout","other");
				PS_ShopList_Transfer_Sale_Money:SetProperty("MoneyNumber", tostring(nSaleOutMoney));				
				--身上现金
				PS_ShopList_Transfer_Self_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
			elseif bSaleType == 1 then--元宝盘出
				--界面显示隐藏
				PS_ShopList_Transfer_Sale_Name_Yuanbao:Show()
				PS_ShopList_Transfer_Self_Name_Yuanbao:Show()
				PS_ShopList_Transfer_Sale_Money:SetProperty("MoneyNumber", tostring(0));
				PS_ShopList_Transfer_Self_Money:SetProperty("MoneyNumber", tostring(0));
				PS_ShopList_Transfer_Sale_Name:Hide()
				PS_ShopList_Transfer_Self_Name:Hide()
				--盘出店价格
				local nSaleOutYuanbao = PlayerShop:GetMoney("saleout","other");
				if nSaleOutYuanbao > 100000 then
					nSaleOutYuanbao = 100000
				end
				PS_ShopList_Transfer_Sale_Yuanbao:SetText(tostring(nSaleOutYuanbao));				
				--身上现金
				PS_ShopList_Transfer_Self_Yuanbao:SetText(tostring(Player:GetData("YUANBAO")));
			end
		end
	end
end


--买东西
function PS_ShopList_Buy_Clicked()
	if( g_ShopType == STALL_ITEM) then
		PlayerShop:BuyItem("item");
	elseif (g_ShopType == STALL_PET) then
		local nIndex = PS_ShopList_Shop_PetList:GetFirstSelectItem();
		if( nIndex == -1 )  then 
			PushDebugMessage("请先选中一个珍兽。");
			return;
		end
		PlayerShop:BuyItem("pet");	
	end
end

--物品商店下一柜台
function PS_ShopList_Shop_Next_Click()
	if(g_nCurStallIndex == g_StallNum) then
		return;
	end
	
	g_nCurStallIndex = g_nCurStallIndex + 1;
	
	
	PS_ShopList_Shop_Next:Disable();
	PS_ShopList_Shop_Last:Disable();
	
	-- local i;
	-- for  i = 1 ,PS_BUTTON_NUM  do  
		-- PS_ITEMBUTTON[i]:Disable();
	-- end
	
	local actIndex = PlayerShop:UIIndexToLogicIndex(g_nCurStallIndex-1, g_boolOwn)
	PlayerShop:AskStallData(g_Owner,actIndex);
	
	

end


--物品商店上一柜台
function PS_ShopList_Shop_Last_Click()
	if(g_nCurStallIndex == 1) then
		return;
	end
	
	g_nCurStallIndex = g_nCurStallIndex - 1;
	
	
	PS_ShopList_Shop_Next:Disable();
	PS_ShopList_Shop_Last:Disable();
	
	local i;
	for  i = 1 ,PS_BUTTON_NUM  do  
		PS_ITEMBUTTON[i]:Disable();
	end
	
	local actIndex = PlayerShop:UIIndexToLogicIndex(g_nCurStallIndex-1, g_boolOwn)
	PlayerShop:AskStallData(g_Owner,actIndex);
	
	

end


function PS_ShopList_UpdatePetStall()
	PS_ShopList_Shop_Commonitem:SetText("");	
	PS_ShopList_Shop_Price:SetProperty("MoneyNumber", tostring(0));
	PS_ShopList_Shop_PetList:ClearListBox();
	local PetInListIndex = 0
	
	for i=1,  20  do
		local actIndex = PlayerShop:UIIndexToLogicIndex(g_nCurStallIndex-1, g_boolOwn)
		local szPetName, szType
		local bOnSale = 0
		if g_boolOwn == true then
			szPetName,bOnSale,szType = PlayerShop:EnumPet(g_Owner,actIndex, i-1);
		
		else
			szPetName, szType = PlayerShop:EnumPet(g_Owner,actIndex, i-1);
		end
 
		if (szPetName ~= "")   then
			
			if(bOnSale ~= 0)  then
				-- 红色表示现在的物品是处于上架的状态
				szType = "#c808080" .. szType;
			else
				szType = "#cffff00" .. szType;
			end		
			PS_ShopList_Shop_PetList:AddItem(szType .. "#W(" .. szPetName .. ")", PetInListIndex);
			g_PetIndex[PetInListIndex] = i-1;
			
			PetInListIndex = PetInListIndex + 1 ;
		end
	end
	
			--卖出的商店
		if g_IsSaleOutFarme == 1 then
			--当前本金
			local nBaseMoney = PlayerShop:GetMoney("base","other");
			PS_ShopList_Transfer_CurBase_Money:SetProperty("MoneyNumber", tostring(nBaseMoney));
			
			--赢利资金
			local nProfitMoney = PlayerShop:GetMoney("profit","other");
			PS_ShopList_Transfer_Gain_Money:SetProperty("MoneyNumber", tostring(nProfitMoney));
			
			--设置盘店信息	
			local bSaleType = PlayerShop:GetSaleType("other");
			if bSaleType == 0 then--金币盘出
				--界面显示隐藏
				PS_ShopList_Transfer_Sale_Name:Show()
				PS_ShopList_Transfer_Self_Name:Show()
				PS_ShopList_Transfer_Sale_Yuanbao:SetText("")		
				PS_ShopList_Transfer_Self_Yuanbao:SetText("")
				PS_ShopList_Transfer_Sale_Name_Yuanbao:Hide()
				PS_ShopList_Transfer_Self_Name_Yuanbao:Hide()
				--盘出店价格
				local nSaleOutMoney = PlayerShop:GetMoney("saleout","other");
				PS_ShopList_Transfer_Sale_Money:SetProperty("MoneyNumber", tostring(nSaleOutMoney));				
				--身上现金
				PS_ShopList_Transfer_Self_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
			elseif bSaleType == 1 then--元宝盘出
				--界面显示隐藏
				PS_ShopList_Transfer_Sale_Name_Yuanbao:Show()
				PS_ShopList_Transfer_Self_Name_Yuanbao:Show()
				PS_ShopList_Transfer_Sale_Money:SetProperty("MoneyNumber", tostring(0));
				PS_ShopList_Transfer_Self_Money:SetProperty("MoneyNumber", tostring(0));
				PS_ShopList_Transfer_Sale_Name:Hide()
				PS_ShopList_Transfer_Self_Name:Hide()
				--盘出店价格
				local nSaleOutYuanbao = PlayerShop:GetMoney("saleout","other");
				if nSaleOutYuanbao > 100000 then
					nSaleOutYuanbao = 100000
				end
				PS_ShopList_Transfer_Sale_Yuanbao:SetText(tostring(nSaleOutYuanbao));				
				--身上现金
				PS_ShopList_Transfer_Self_Yuanbao:SetText(tostring(Player:GetData("YUANBAO")));
			end
		end	
	
	

end


function PS_ShopList_Shop_PetList_Selected()

	local nIndex = PS_ShopList_Shop_PetList:GetFirstSelectItem();
	
	if( nIndex == -1 )  then 
		return;
	end
	
	if (g_nCurStallIndex <= 0) then
		return;
	end	
	--通知C＋＋
	local actIndex = PlayerShop:UIIndexToLogicIndex(g_nCurStallIndex-1, g_boolOwn)
	PlayerShop:SetCurSelectPetIndex(g_Owner,actIndex,g_PetIndex[nIndex]);	
	
		--珍兽
	local nMoney = PlayerShop:GetObjPrice(g_Owner,"pet");
	--价格
	PS_ShopList_Shop_Price:SetProperty("MoneyNumber", tostring(nMoney));
	--名称
	local szPetName = PlayerShop:GetObjName(g_Owner,"pet");
	PS_ShopList_Shop_Commonitem:SetText(szPetName);	
end


function PS_ShopList_Shop_PetList_RClick()

	local nIndex = PS_ShopList_Shop_PetList:GetFirstSelectItem();
	
	if( nIndex == -1 )   then
		return;
	end
	
	PlayerShop:ViewPetDesc(g_Owner,g_PetIndex[nIndex]);
end


function PS_RecycleShopList_SelectChanged()
	local nIndex = PS_ShopList_RecycleShopList:GetSelectItem();
		g_Selectindex = nIndex;

	if(g_Selectindex == -1)  then
		return;
	end
	
	PlayerShop:SetCurSelShopIdx(g_nShopIndex[nIndex]);
	
		local szShopName,OpenNum,SaleNum,szType,nIsFavor,nRecItemnum, nFrezeType = PlayerShop:EnumShop(g_nShopIndex[nIndex]);

	g_LastSelect_RecycleShop = szShopName;

	--更新显示的信息
	PS_ShopList_UpdateShopInfo()
	PS_ShopListAccept_Clicked("buy")
	
	

end


function PS_ShopList_UpdateDetailRecycleShopInfo()
	
	for i =1, PS_BUTTON_NUM do
		g_RecycleItems[i]:SetProperty("DragAcceptName", "X"..tostring(i-1));
	end
	
end

function PS_ShopList_UpdateRecycleStall()

	local HaveNum = 0;
	for i=1, PS_BUTTON_NUM do
		g_RecycleItems[i]:SetProperty("DraggingEnabled","False")
		g_RecycleItems[i]:SetProperty("CornerChar", "TopRight")
	end
	
	local Count = 0;
	
		for i=1, PS_BUTTON_NUM    do
		local theAction, bLocked = PlayerShop:EnumRecycleItemAction(i-1, 3);
		if theAction:GetID() ~= 0 then
			HaveNum = HaveNum + 1;
			g_RecycleItems[i]:SetActionItem(theAction:GetID());
			if g_nCurSelectItem == i   then
				g_RecycleItems[i]:SetPushed(1);
			else
				g_RecycleItems[i]:SetPushed(0);
			end
			--开放拖动功能
			
			local needToGet =  PlayerShop:GetRecycleItem(i-1,3,"needtoget");
			local needToRec =  PlayerShop:GetRecycleItem(i-1,3,"needtorecycle");

			if(needToRec<=0)then
				g_RecycleItems[i]:SetActionItem(-1);
			end

		else
			g_RecycleItems[i]:SetActionItem(-1);
		end
	end
	
	
end


function PS_ShopList_Frame_OnHiden()
	PlayerShop:SetServerOpen(0) 
end

function PS_ShopList_RecycleShop_Item_Click(idx)

	local Type = 3;
	g_nCurSelectItem = idx;
	local theAction, bLocked = PlayerShop:EnumRecycleItemAction(idx-1, Type);
	PS_ShopList_Recycle_Commonitem:SetText("");
	if theAction:GetID() ~= 0 then
		--name
		local name = PlayerShop:GetRecycleItem(idx-1,Type,"name");
		PS_ShopList_Recycle_Commonitem:SetText(name);
		--收购价
		local price = PlayerShop:GetRecycleItem(idx-1,Type,"price");
		PS_ShopList_Recycle_Price:SetProperty("MoneyNumber", tostring(price));
		--数量
		local numToget = PlayerShop:GetRecycleItem(idx-1,Type,"needtoget");
		PS_ShopList_Recycle_Nub1:SetText(numToget);
		local numTorec = PlayerShop:GetRecycleItem(idx-1,Type,"needtorecycle");
		PS_ShopList_Recycle_Nub2:SetText(numTorec);
		
		for i=1, PS_BUTTON_NUM    do
			if g_nCurSelectItem == i then
				g_RecycleItems[i]:SetPushed(1);
			else
				g_RecycleItems[i]:SetPushed(0);
			end
		end
	end
	
end


function PS_ShopList_RecycleShop_Sell_Click()
	PlayerShop:RecycleShop_EnterSell();
end


--查找
function PS_ShopList_Find_Clicked()

	
	local shopID = PS_ShopList_ShopID:GetText()
	if shopID and shopID ~= "" and tonumber(shopID) >= 0 then
		PlayerShop:FindShop("shopid", tonumber(shopID))
		g_bSearch = 1
	else
		PushDebugMessage("#{JZSHYH_140214_09}")
	end
end


function PS_ShopList_Search_UpdateFrame()
	
end

function PS_ShopList_Shop_Page_Click(index)
	g_nCurStallIndex = index;

	--向服务器请求数据
	PS_ShopList_Shop_Last:Disable();	
	PS_ShopList_Shop_Next:Disable();
	-- local i;
	-- for  i = 1 ,PS_ITEMSTALL_NUM  do  
		-- PS_ITEMSTALL_BOTTON[i]:Disable();
	-- end
	
	
	local actIndex = PlayerShop:UIIndexToLogicIndex(g_nCurStallIndex-1, g_boolOwn)
	PlayerShop:AskStallData(g_Owner,actIndex);
	

	
end

--===============================================
-- 加入/去除 名店
--===============================================
function PS_ShopList_Favor_Clicked()

	if g_ShopType == STALL_ITEM or g_ShopType == STALL_PET then
		local selectIndex = PS_ShopList_ShopList:GetSelectItem();
		if(selectIndex < 0)     then
			return;
		end
		
		PlayerShop:AddFavor(g_nShopIndex[selectIndex]);
	else
		local selectIndex = PS_ShopList_RecycleShopList:GetSelectItem();
		if(selectIndex < 0)     then
			return;
		end
		
		PlayerShop:AddFavor(g_nShopIndex[selectIndex]);	
	end
	

	-- local totalCount = PS_ShopList_ShopList:GetItemCount();

	-- 加入名店后，自动选中下一个店，如果已经是最后一个店了，则选中前一个，如果只有一个店，则选中自己
	-- if(selectIndex + 1 < totalCount) then
		-- local szShopName,OpenNum,SaleNum,szType,nIsFavor,nRecItemnum, nFrezeType = PlayerShop:EnumShop(g_nShopIndex[selectIndex + 1]);
		-- g_LastSelect_NormalShop = szShopName;
	-- elseif(selectIndex - 1 >= 0) then
		-- local szShopName,OpenNum,SaleNum,szType,nIsFavor,nRecItemnum, nFrezeType = PlayerShop:EnumShop(g_nShopIndex[selectIndex - 1]);
		-- g_LastSelect_NormalShop = szShopName;
	-- else
		-- local szShopName,OpenNum,SaleNum,szType,nIsFavor,nRecItemnum, nFrezeType = PlayerShop:EnumShop(g_nShopIndex[selectIndex]);
		-- g_LastSelect_NormalShop = szShopName;
	-- end
end


--
function PS_ShopListRefuse_Clicked()
	this:Hide();
	--取消关心
	this:CareObject(objCared, 0, "PS_Shoplist");
end
