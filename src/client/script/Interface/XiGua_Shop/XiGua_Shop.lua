
local g_XiGua_Shop_UnifiedPosition;

local g_XiGua_Shop_YBList = {};
local g_XiGua_Shop_DBList = {};

local g_XiGua_Shop_nContentButton = {}

local g_XiGua_Shop_ReFreshNum = -1;
local g_XiGua_Shop_DBCount = -1;
local g_XiGua_Shop_IsHaveBuy = 0;
local g_XiGua_Shop_Page = 1;
local g_XiGua_Shop_CurSelect = 0;
local g_XiGua_Shop_CurSelectItem = 0;

local g_XiGua_Shop_ShopCost = 0;
local g_XiGua_Shop_GetfanliValue = 0;
local g_XiGua_Shop_Getfanli = {0,0,0,0,0,0}
local g_XiGua_Shop_ChooseValue = 0;
local g_XiGua_Shop_ChooseItem = {0,0,0,0,0,0}

local g_XiGua_Shop_YBItem = "";
local g_XiGua_Shop_DBItem = "";

local g_XiGua_Shop_YBItemList = {
[1] = {39920085, 2, 60, 2, 0, 8.6, 1}, 
[2] = {39920089, 1, 85, 5, 0, 8.5, 1}, 
[3] = {39921313, 2, 170, 17, 0, 8.5, 1}, 
[4] = {39920162, 20, 280, 41, 0, 7.0, 1},
}; -- id num cost idx canbuy
local g_XiGua_Shop_DBItemList = {
[1] = {39920462, 1, 85, 2, 0}, 
[2] = {39920329, 1, 40, 4, 0}, 
[3] = {39920163, 1, 2, 11, 0}, 
[4] = {39920332, 1, 20, 18, 0},
};

local g_XiGua_Shop_FanLi = {
[1] = { costnum = 4000, imageshow = "set:Spring24 image:1", showyulan = 0, fixedId = 39922699, fixedNum = 5,  --固定奖励
		chooseList = {
			[1] = {id = 39920181, cnt = 1, },  --可选奖励
			[2] = {id = 39922174, cnt = 1, },
			} 
		},
[2] = { costnum = 8000, imageshow = "set:Spring24 image:2", showyulan = 0, fixedId = 39922699, fixedNum = 5,  --固定奖励 
		chooseList = {
			[1] = {id = 39920490, cnt = 2, }, --可选奖励
			[2] = {id = 39920311, cnt = 2, },
			} 
		},
[3] = { costnum = 20000, imageshow = "set:Spring24 image:3", showyulan = 0, fixedId = 39922699, fixedNum = 5,   --固定奖励 
		chooseList = {
			[1] = {id = 39920162, cnt = 20, },  --可选奖励
			[2] = {id = 39922684, cnt = 20, },
			} 
		},
[4] = { costnum = 40000, imageshow = "set:Spring24 image:4", showyulan = 0, fixedId = 39922699, fixedNum = 5,   --固定奖励  
		chooseList = {
			[1] = {id = 39920093, cnt = 1, },  --可选奖励
			[2] = {id = 39922685, cnt = 10, }, -- 可选奖励预览
			}
		},
[5] = { costnum = 72000, imageshow = "set:Spring24 image:5", showyulan = 1, fixedId = 39922699, fixedNum = 10,   --固定奖励 
		chooseList = { 
			[1] = {id = 39922656, cnt = 1, },  --可选奖励
			[2] = {id = 39922658, cnt = 1, }, -- 可选奖励预览
			} 
		},
[6] = { costnum = 120000, imageshow = "set:Spring24 image:6", showyulan = 0, fixedId = 39922699, fixedNum = 10,   --固定奖励  
		chooseList = {
			[1] = {id = 39921777, cnt = 1, },  --可选奖励
			[2] = {id = 39922219, cnt = 1, }, -- 可选奖励预览
			} 
		},
}

function XiGua_Shop_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	
	this:RegisterEvent("UPDATE_YUANBAO")
end

function XiGua_Shop_OnLoad()
	g_XiGua_Shop_UnifiedPosition = XiGua_Shop:GetProperty("UnifiedPosition")
	
	g_XiGua_Shop_YBList[1] = {XiGua_Shop_Yuanbao1_Icon, XiGua_Shop_Yuanbao1_Item, XiGua_Shop_Yuanbao1_Count, 
								XiGua_Shop_Yuanbao1_Icon_Mask, XiGua_Shop_Yuanbao1_Discount, XiGua_Shop_Yuanbao1_Unbind, XiGua_Shop_Yuanbao1_DiscountBK}
	g_XiGua_Shop_YBList[2] = {XiGua_Shop_Yuanbao2_Icon, XiGua_Shop_Yuanbao2_Item, XiGua_Shop_Yuanbao2_Count,  
								XiGua_Shop_Yuanbao2_Icon_Mask, XiGua_Shop_Yuanbao2_Discount, XiGua_Shop_Yuanbao2_Unbind, XiGua_Shop_Yuanbao2_DiscountBK}
	g_XiGua_Shop_YBList[3] = {XiGua_Shop_Yuanbao3_Icon, XiGua_Shop_Yuanbao3_Item, XiGua_Shop_Yuanbao3_Count,  
								XiGua_Shop_Yuanbao3_Icon_Mask, XiGua_Shop_Yuanbao3_Discount, XiGua_Shop_Yuanbao3_Unbind, XiGua_Shop_Yuanbao3_DiscountBK}
	g_XiGua_Shop_YBList[4] = {XiGua_Shop_Yuanbao4_Icon, XiGua_Shop_Yuanbao4_Item, XiGua_Shop_Yuanbao4_Count,  
								XiGua_Shop_Yuanbao4_Icon_Mask, XiGua_Shop_Yuanbao4_Discount, XiGua_Shop_Yuanbao4_Unbind, XiGua_Shop_Yuanbao4_DiscountBK}	
	
	g_XiGua_Shop_DBList[1] = {XiGua_Shop_Cuiyi1_Icon, XiGua_Shop_Cuiyi1_Item, XiGua_Shop_Cuiyi1_Count, XiGua_Shop_Cuiyi1_Icon_Mask}
	g_XiGua_Shop_DBList[2] = {XiGua_Shop_Cuiyi2_Icon, XiGua_Shop_Cuiyi2_Item, XiGua_Shop_Cuiyi2_Count, XiGua_Shop_Cuiyi2_Icon_Mask}
	g_XiGua_Shop_DBList[3] = {XiGua_Shop_Cuiyi3_Icon, XiGua_Shop_Cuiyi3_Item, XiGua_Shop_Cuiyi3_Count, XiGua_Shop_Cuiyi3_Icon_Mask}
	g_XiGua_Shop_DBList[4] = {XiGua_Shop_Cuiyi4_Icon, XiGua_Shop_Cuiyi4_Item, XiGua_Shop_Cuiyi4_Count, XiGua_Shop_Cuiyi4_Icon_Mask}
	
end

function XiGua_Shop_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89286604 ) then
	
		g_XiGua_Shop_ReFreshNum = Get_XParam_INT(0)		
		g_XiGua_Shop_DBCount = Get_XParam_INT(1)
		g_XiGua_Shop_IsHaveBuy = Get_XParam_INT(2)
		g_XiGua_Shop_Page = Get_XParam_INT(3)
		g_XiGua_Shop_ShopCost = Get_XParam_INT(4)
		g_XiGua_Shop_GetfanliValue = Get_XParam_INT(5)
		g_XiGua_Shop_ChooseValue = Get_XParam_INT(6)
	
		XiGua_Shop_UpdateFanLiData()
		
		g_XiGua_Shop_YBItem = Get_XParam_STR(0)
		g_XiGua_Shop_DBItem = Get_XParam_STR(1)
		
		XiGua_Shop_Update()
		
		XiGua_Shop_Init()
		
		XiGua_Shop_FanLiUpdate()
		
		this:Show()
	    
	elseif( event == "UI_COMMAND" 
			and tonumber(arg0) == 89286901 
			and IsWindowShow("XiGua_Shop") ) then

		g_XiGua_Shop_ReFreshNum = Get_XParam_INT(0)		
		g_XiGua_Shop_DBCount = Get_XParam_INT(1)	
		g_XiGua_Shop_IsHaveBuy = Get_XParam_INT(2)
		
		g_XiGua_Shop_Page = 1
		
		g_XiGua_Shop_ShopCost = Get_XParam_INT(3)
		g_XiGua_Shop_GetfanliValue = Get_XParam_INT(4)
		g_XiGua_Shop_ChooseValue = Get_XParam_INT(5)
		
		XiGua_Shop_UpdateFanLiData()
		
		g_XiGua_Shop_YBItem = Get_XParam_STR(0)
		g_XiGua_Shop_DBItem = Get_XParam_STR(1)
		
		XiGua_Shop_Update()
		
		XiGua_Shop_Init()
		
	elseif (event == "ADJEST_UI_POS" ) then
		XiGua_Shop_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XiGua_Shop_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
		
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		XiGua_Shop_YuanbaoUpdate()
	end

end

--=========================================================
--元宝刷新
--=========================================================
function XiGua_Shop_YuanbaoUpdate()
	XiGua_Shop_Remain1_Text:SetText(ScriptGlobal_Format("#{XGSD_180608_81}",tostring(Player:GetData("YUANBAO"))))
end

--=========================================================
--初始化界面
--=========================================================
function XiGua_Shop_Init()

	XiGua_Shop_Refresh2_Text:SetText(ScriptGlobal_Format("#{XGSD_180608_34}",g_XiGua_Shop_ReFreshNum, 300))
	XiGua_Shop_Remain1_Text:SetText(ScriptGlobal_Format("#{XGSD_180608_81}",tostring(Player:GetData("YUANBAO"))))
	XiGua_Shop_Remain2_Text:SetText(ScriptGlobal_Format("#{XGSD_180608_82}",g_XiGua_Shop_DBCount))

	DataPool:Lua_ClearXiGuaShopActionItem();	
		for i = 1, table.getn(g_XiGua_Shop_YBItemList) do
			DataPool:Lua_SetXiGuaShopActionItem( i-1, g_XiGua_Shop_YBItemList[i][1], g_XiGua_Shop_YBItemList[i][2] );
			
			g_XiGua_Shop_YBList[i][2]:SetText("#cfff263"..DataPool:Lua_GetItemNameByIndex(g_XiGua_Shop_YBItemList[i][1]))
			local textShow = ScriptGlobal_Format("#{XGSD_180608_32}",g_XiGua_Shop_YBItemList[i][3])
			g_XiGua_Shop_YBList[i][3]:SetText(textShow)
		end
		for i = 1, table.getn(g_XiGua_Shop_DBItemList) do
			DataPool:Lua_SetXiGuaShopActionItem( i+3, g_XiGua_Shop_DBItemList[i][1], g_XiGua_Shop_DBItemList[i][2] );
			
			g_XiGua_Shop_DBList[i][2]:SetText("#cfff263"..DataPool:Lua_GetItemNameByIndex(g_XiGua_Shop_DBItemList[i][1]))
			local textShow = ScriptGlobal_Format("#{XGSD_180608_33}",g_XiGua_Shop_DBItemList[i][3])
			g_XiGua_Shop_DBList[i][3]:SetText(textShow)
		end
	DataPool:Lua_UpdateXiGuaShopActionItem();
	for i=1, 4 do
		local theAction = EnumAction( i-1, "xiguashop_item");
		if theAction:GetID() ~= 0 then
			g_XiGua_Shop_YBList[i][1]:SetActionItem( theAction:GetID() );
		else
			g_XiGua_Shop_YBList[i][1]:SetActionItem( -1 );
		end
	end
	for i=5, 8 do
		local theAction = EnumAction( i-1, "xiguashop_item");
		if theAction:GetID() ~= 0 then
			g_XiGua_Shop_DBList[i-4][1]:SetActionItem( theAction:GetID() );
		else
			g_XiGua_Shop_DBList[i-4][1]:SetActionItem( -1 );
		end
	end
	
	for idx = 1, 4 do
		if g_XiGua_Shop_YBItemList[idx][5] == 0 then
			--未购买
			g_XiGua_Shop_YBList[idx][4]:Hide()
		else
			--已购买
			g_XiGua_Shop_YBList[idx][4]:Show()
		end
		if g_XiGua_Shop_DBItemList[idx][5] == 0 then
			--未购买
			g_XiGua_Shop_DBList[idx][4]:Hide()
		else
			--已购买
			g_XiGua_Shop_DBList[idx][4]:Show()
		end
		
		--显示折扣
		if g_XiGua_Shop_YBItemList[idx][6] ~= 10 then
			g_XiGua_Shop_YBList[idx][5]:Show()	
			g_XiGua_Shop_YBList[idx][7]:Show()	
			local msgstr = ScriptGlobal_Format("#{XGSD_180608_94}", g_XiGua_Shop_YBItemList[idx][6])
			g_XiGua_Shop_YBList[idx][5]:SetText(msgstr)
		else
			g_XiGua_Shop_YBList[idx][5]:Hide()		
			g_XiGua_Shop_YBList[idx][7]:Hide()		
		end
		
		if g_XiGua_Shop_YBItemList[idx][7] == 0 then
			--非绑
			g_XiGua_Shop_YBList[idx][6]:Show()
		else
			--绑定
			g_XiGua_Shop_YBList[idx][6]:Hide()
		end
	end
	
	XiGua_Shop_ShowPage()
	
	XiGua_Shop_ShowTips()
	
end

--=========================================================
--更新界面
--=========================================================
function XiGua_Shop_Update()
	
	local strItem = g_XiGua_Shop_YBItem
	for i = 1, 4 do
		local iPos = string.find( strItem, "-" );
		if ( iPos == nil ) then
			XiGua_Shop_Close()
		else
			local tempstr = string.sub(strItem, 1, iPos-1)
			local temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_XiGua_Shop_YBItemList[i][1] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_XiGua_Shop_YBItemList[i][2] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_XiGua_Shop_YBItemList[i][3] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_XiGua_Shop_YBItemList[i][4] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_XiGua_Shop_YBItemList[i][6] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_XiGua_Shop_YBItemList[i][7] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
		end
		strItem = string.sub(strItem, iPos+1, string.len(strItem))
	end

	local strDBItem = g_XiGua_Shop_DBItem
	for i = 1, 4 do
		local iPos = string.find( strDBItem, "-" );
		if ( iPos == nil ) then
			XiGua_Shop_Close()
		else
			local tempstr = string.sub(strDBItem, 1, iPos-1)
			local temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_XiGua_Shop_DBItemList[i][1] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_XiGua_Shop_DBItemList[i][2] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_XiGua_Shop_DBItemList[i][3] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_XiGua_Shop_DBItemList[i][4] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
		end
		strDBItem = string.sub(strDBItem, iPos+1, string.len(strDBItem))
	end
	
	if g_XiGua_Shop_IsHaveBuy ~= nil and g_XiGua_Shop_IsHaveBuy >= 0 then	
		g_XiGua_Shop_YBItemList[1][5] = math.floor(g_XiGua_Shop_IsHaveBuy/10000000)
		g_XiGua_Shop_YBItemList[2][5] = math.floor(math.mod(g_XiGua_Shop_IsHaveBuy/1000000, 10))
		g_XiGua_Shop_YBItemList[3][5] = math.floor(math.mod(g_XiGua_Shop_IsHaveBuy/100000, 10))
		g_XiGua_Shop_YBItemList[4][5] = math.floor(math.mod(g_XiGua_Shop_IsHaveBuy/10000, 10))
		
		g_XiGua_Shop_DBItemList[1][5] = math.floor(math.mod(g_XiGua_Shop_IsHaveBuy/1000, 10))
		g_XiGua_Shop_DBItemList[2][5] = math.floor(math.mod(g_XiGua_Shop_IsHaveBuy/100,10))
		g_XiGua_Shop_DBItemList[3][5] = math.floor(math.mod(g_XiGua_Shop_IsHaveBuy/10,10))
		g_XiGua_Shop_DBItemList[4][5] = math.floor(math.mod(g_XiGua_Shop_IsHaveBuy,10))
	end
	
end

function XiGua_Shop_UpdateFanLiData()
	
	for i = 1, table.getn(g_XiGua_Shop_FanLi) do
		g_XiGua_Shop_Getfanli[i] = math.mod(g_XiGua_Shop_GetfanliValue, 10)
		g_XiGua_Shop_GetfanliValue = math.floor(g_XiGua_Shop_GetfanliValue / 10)
			
		g_XiGua_Shop_ChooseItem[i] = math.mod(g_XiGua_Shop_ChooseValue, 10)
		g_XiGua_Shop_ChooseValue = math.floor(g_XiGua_Shop_ChooseValue / 10)
	end
	
end

--=========================================================
--刷新返利界面
--=========================================================
function XiGua_Shop_FanLiUpdate()

	for i = 1, table.getn(g_XiGua_Shop_nContentButton) do
		g_XiGua_Shop_nContentButton[i]:GetSubItem("XiGua_Shop_Reward_BasicItem1"):SetActionItem(-1)
		g_XiGua_Shop_nContentButton[i]:GetSubItem("XiGua_Shop_Reward_BasicItem2"):SetActionItem(-1)
		g_XiGua_Shop_nContentButton[i]:GetSubItem("XiGua_Shop_Reward_BasicItem3"):SetActionItem(-1)
	end

	XiGua_Shop_UpFrame_RewardList:Clear()
	
	g_XiGua_Shop_nContentButton = {}

	for i = 1, table.getn(g_XiGua_Shop_FanLi) do
		local bar = XiGua_Shop_UpFrame_RewardList:AddChild("XiGua_Shop_UpFrame_RewardContent")
		if nil ~= bar then
			-- 累计元宝
			local strmsg = ""
			if g_XiGua_Shop_ShopCost < g_XiGua_Shop_FanLi[i].costnum then
				strmsg = ScriptGlobal_Format("#{XGSD_200609_34}", g_XiGua_Shop_ShopCost, g_XiGua_Shop_FanLi[i].costnum)
			else
				strmsg = ScriptGlobal_Format("#{XGSD_200609_35}", g_XiGua_Shop_FanLi[i].costnum, g_XiGua_Shop_FanLi[i].costnum)
			end
			bar:GetSubItem("XiGua_Shop_UpFrame_Reward_PointText2"):SetText(strmsg)
			
			-- 隐藏对号
			bar:GetSubItem("XiGua_Shop_Reward_BasicItem2_Mask"):Hide()
			bar:GetSubItem("XiGua_Shop_Reward_BasicItem3_Mask"):Hide()
			local nChooseIdx = g_XiGua_Shop_ChooseItem[i]
			if g_XiGua_Shop_FanLi[i].chooseList[nChooseIdx] ~= nil then
				if nChooseIdx == 1 then
					bar:GetSubItem("XiGua_Shop_Reward_BasicItem2_Mask"):Show()
				else
					bar:GetSubItem("XiGua_Shop_Reward_BasicItem3_Mask"):Show()
				end
			end
									
			--action
			local theAction = DataPool:CreateActionItemForShow(g_XiGua_Shop_FanLi[i].fixedId, g_XiGua_Shop_FanLi[i].fixedNum)
			if theAction:GetID() ~= 0 then
				bar:GetSubItem("XiGua_Shop_Reward_BasicItem1"):SetActionItem(theAction:GetID());
			end
			
			theAction = DataPool:CreateActionItemForShow(g_XiGua_Shop_FanLi[i].chooseList[1].id, g_XiGua_Shop_FanLi[i].chooseList[1].cnt)
			if theAction:GetID() ~= 0 then
				bar:GetSubItem("XiGua_Shop_Reward_BasicItem2"):SetActionItem(theAction:GetID());
			end
			
			theAction = DataPool:CreateActionItemForShow(g_XiGua_Shop_FanLi[i].chooseList[2].id, g_XiGua_Shop_FanLi[i].chooseList[2].cnt)
			if theAction:GetID() ~= 0 then
				bar:GetSubItem("XiGua_Shop_Reward_BasicItem3"):SetActionItem(theAction:GetID());
			end
			
			--预览
			if g_XiGua_Shop_FanLi[i].showyulan == 1 then
				bar:GetSubItem("XiGua_Shop_Reward_Preview_Btn"):Show()
				bar:SetSubItemEvent("XiGua_Shop_Reward_Preview_Btn", "Clicked", "XiGua_Shop_Reward_Preview("..i..")")	
			else
				bar:GetSubItem("XiGua_Shop_Reward_Preview_Btn"):Hide()
			end
			
			--按钮
			if g_XiGua_Shop_Getfanli[i] ~= nil then
				if g_XiGua_Shop_Getfanli[i] == 1 then	-- 已领取
					bar:GetSubItem("XiGua_Shop_Reward_Button"):Hide()
					bar:GetSubItem("XiGua_Shop_Reward_BasicItemReceived"):Show()
					bar:GetSubItem("XiGua_Shop_Reward_BasicItemNotReach"):Hide()
				else
					if g_XiGua_Shop_ShopCost < g_XiGua_Shop_FanLi[i].costnum then	-- 未达成
						bar:GetSubItem("XiGua_Shop_Reward_Button"):Hide()
						bar:GetSubItem("XiGua_Shop_Reward_BasicItemReceived"):Hide()
						bar:GetSubItem("XiGua_Shop_Reward_BasicItemNotReach"):Show()
					else
						bar:GetSubItem("XiGua_Shop_Reward_Button"):Show()
						bar:GetSubItem("XiGua_Shop_Reward_BasicItemReceived"):Hide()
						bar:GetSubItem("XiGua_Shop_Reward_BasicItemNotReach"):Hide()
					end
				end
			end
			bar:SetSubItemEvent("XiGua_Shop_Reward_Button", "Clicked", "XiGua_Shop_Reward_Click("..i..")")	
			
			--首列图片
			bar:GetSubItem("XiGua_Shop_Reward_BasicItemLevel"):SetProperty("Image", g_XiGua_Shop_FanLi[i].imageshow)
			
			g_XiGua_Shop_nContentButton[i] = bar
		end
	end
	
end

--=========================================================
--刷新商店
--=========================================================
function XiGua_Shop_ReFresh_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnReFreshXiGuaShop" )
		Set_XSCRIPT_ScriptID(892869)
		Set_XSCRIPT_Parameter(0,1) --暂时只有代币刷新 1、表示代币刷新
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

--=========================================================
--商店说明
--=========================================================
function XiGua_Shop_Help_Clicked( index )

	if index ~= 1 and index ~= 2 then
		return 
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowHelpText" )
		Set_XSCRIPT_ScriptID(892866)
		Set_XSCRIPT_Parameter(0,index) --1、表示元宝 2、表示代币
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

--=========================================================
--代币购买
--=========================================================
function XiGua_Shop_CuiyiBuy( index )

	if index < 1 or index > 4 then
		return 
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnXiGuaShopBuy" )
		Set_XSCRIPT_ScriptID(892869)
		Set_XSCRIPT_Parameter(0,1) --1、表示代币 2、表示元宝
		Set_XSCRIPT_Parameter(1,index) 
		Set_XSCRIPT_Parameter(2,g_XiGua_Shop_DBItemList[index][4])
		Set_XSCRIPT_Parameter(3,g_XiGua_Shop_DBItemList[index][1])
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()	

end

--=========================================================
--元宝购买
--=========================================================
function XiGua_Shop_YuanbaoBuy( index )

	if index < 1 or index > 4 then
		return 
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnXiGuaShopBuy" )
		Set_XSCRIPT_ScriptID(892869)
		Set_XSCRIPT_Parameter(0,2) --1、表示代币 2、表示元宝
		Set_XSCRIPT_Parameter(1,index) 
		Set_XSCRIPT_Parameter(2,g_XiGua_Shop_YBItemList[index][4])
		Set_XSCRIPT_Parameter(3,g_XiGua_Shop_YBItemList[index][1])
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()	

end

--=========================================================
--关闭
--=========================================================
function XiGua_Shop_Close()

	for i = 1, table.getn(g_XiGua_Shop_nContentButton) do
		g_XiGua_Shop_nContentButton[i]:GetSubItem("XiGua_Shop_Reward_BasicItem1"):SetActionItem(-1)
		g_XiGua_Shop_nContentButton[i]:GetSubItem("XiGua_Shop_Reward_BasicItem2"):SetActionItem(-1)
		g_XiGua_Shop_nContentButton[i]:GetSubItem("XiGua_Shop_Reward_BasicItem3"):SetActionItem(-1)
	end

	XiGua_Shop_UpFrame_RewardList:Clear()
	
	g_XiGua_Shop_nContentButton = {}
	
	if(IsWindowShow("XiGua_Shop_Choose")) then
		CloseWindow("XiGua_Shop_Choose", true)
	end
	
	if(IsWindowShow("XiGua_Preview")) then
		CloseWindow("XiGua_Preview", true)
	end
	
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function XiGua_Shop_On_ResetPos()
	XiGua_Shop:SetProperty("UnifiedPosition", g_XiGua_Shop_UnifiedPosition);
end

--=========================================================
--显示页签
--=========================================================
function XiGua_Shop_ShowPage()

	if g_XiGua_Shop_Page == 2 then
		XiGua_Shop_Frame:Hide()
		XiGua_Shop_Frame2:Show()
		
		XiGua_Shop_Left_Buttontab01:SetCheck(0)
		XiGua_Shop_Left1_Buttontab02:SetCheck(1)
	else
		XiGua_Shop_Frame:Show()
		XiGua_Shop_Frame2:Hide()
		
		XiGua_Shop_Left_Buttontab01:SetCheck(1)
		XiGua_Shop_Left1_Buttontab02:SetCheck(0)
	end
	
end

--=========================================================
--刷新小红点
--=========================================================
function XiGua_Shop_ShowTips()

	XiGua_Shop_Left_Buttontab01_Tips:Hide()
	
	XiGua_Shop_Left1_Buttontab02_Tips:Hide()
	for i = 1, table.getn(g_XiGua_Shop_FanLi) do
		if g_XiGua_Shop_ShopCost >= g_XiGua_Shop_FanLi[i].costnum and g_XiGua_Shop_Getfanli[i] == 0 then
			XiGua_Shop_Left1_Buttontab02_Tips:Show()
		end
	end
	
end

--=========================================================
--切换页签
--=========================================================
function XiGua_Shop_Page( btn )

	if btn ~= 1 and btn ~= 2 then
		return
	end
	
	if btn == 1 then	
		if(IsWindowShow("XiGua_Shop_Choose")) then
			CloseWindow("XiGua_Shop_Choose", true)
		end
		
		if(IsWindowShow("XiGua_Preview")) then
			CloseWindow("XiGua_Preview", true)
		end
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnOpenXiGuaShop" )
		Set_XSCRIPT_ScriptID(892866)
		Set_XSCRIPT_Parameter(0, btn) --1、表示觅宝阁 2、表示返利
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
	
end

--=========================================================
--返利预览
--=========================================================
function XiGua_Shop_Reward_Preview( nIdx )
	if g_XiGua_Shop_FanLi[nIdx] ~= nil and g_XiGua_Shop_FanLi[nIdx].showyulan == 1 then
		PushEvent( "UI_COMMAND", 2020062901 )
	end
end

--=========================================================
--领取返利
--=========================================================
function XiGua_Shop_Reward_Click( Idx )

	if Idx < 1 or Idx > table.getn(g_XiGua_Shop_FanLi) then
		return 
	end
	
	if g_XiGua_Shop_CurSelect ~= Idx then
		g_XiGua_Shop_CurSelect = Idx
		g_XiGua_Shop_CurSelectItem = 0
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetXiGuaShopFanLi" )
		Set_XSCRIPT_ScriptID(892866)
		Set_XSCRIPT_Parameter(0, Idx)
		Set_XSCRIPT_Parameter(1, g_XiGua_Shop_CurSelectItem)
		Set_XSCRIPT_Parameter(2, 1)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
	
end

