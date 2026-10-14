--
-- 周商店界面
--
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_FrameInfo = -1

-- 界面显示
local g_WeeklyShop_DayItem ={}
local g_WeeklyShop_WeekItem ={}
local g_WeeklyShop_SpeicalItem = {}

--周 
local g_WeekLyShopWeekCommonItemPic = {}
local g_WeekLyShopWeekCommonItemPrice = {} 
local g_WeekLyShopWeekCommonItemName = {} 
local g_WeekLyShopWeekCommonItemZheKou = {} 
local g_WeekLyShopWeekCommonItemBuy = {}
local g_WeekLyShopWeekCommonItemMask = {}

--特殊
local g_WeekLyShopWeekSpecialItemPic = {}
local g_WeekLyShopWeekSpecialItemPrice = {} 
local g_WeekLyShopWeekSpecialItemName = {} 
local g_WeekLyShopWeekSpecialItemZheKou = {} 
local g_WeekLyShopWeekSpecialItemBuy = {} 
local g_WeekLyShopWeekSpecialItemMask = {}

local g_WeekLyShopDayInfo = {}
local g_WeekLyShopCommonInfo  = {}
local g_WeekLyShopSpecialInfo = {}

local objCared = -1
local g_Object = -1

local g_WeeklyShopSelecetPage = 1
local g_WeeklyShopCommonPage = 1
local g_WeeklyShopCommonText = 
{
	[1] = "#{ZXSD_20250117_12}",
	[2] = "#{ZXSD_20250117_13}",
	[3] = "#{ZXSD_20250117_14}",
}

local g_WeeklyShop_Shop_BuyConfirm = 0

function WeeklyShop_PreLoad()

	-- 注册事件
	this:RegisterEvent("UI_COMMAND")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	-- 退出游戏
	this:RegisterEvent("QUEST_QUIT_GAME")

	-- 返回登陆界面
	this:RegisterEvent("QUEST_SERVER_LOGIN")

	-- 离开此场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	this:RegisterEvent("WEEK_SHOP_UPDATE_INFO",true)

	this:RegisterEvent("UPDATE_YUANBAO",false)
	
	--距离NPC距离
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
end

function WeeklyShop_OnLoad()

	-- 界面显示
	g_WeeklyShop_DayItem[1] = WeeklyShop_Item1Frame_List1

	g_WeeklyShop_WeekItem[1] = WeeklyShop_Item1Frame
	g_WeeklyShop_WeekItem[2] = WeeklyShop_Item2Frame
	g_WeeklyShop_WeekItem[3] = WeeklyShop_Item3Frame
	g_WeeklyShop_WeekItem[4] = WeeklyShop_Item4Frame
	g_WeeklyShop_WeekItem[5] = WeeklyShop_Item5Frame
	g_WeeklyShop_WeekItem[6] = WeeklyShop_Item6Frame

	g_WeeklyShop_SpeicalItem[1] = WeeklyShop_Item1Frame_List3
	g_WeeklyShop_SpeicalItem[2] = WeeklyShop_Item2Frame_List3
	g_WeeklyShop_SpeicalItem[3] = WeeklyShop_Item3Frame_List3
	g_WeeklyShop_SpeicalItem[4] = WeeklyShop_Item4Frame_List3
	g_WeeklyShop_SpeicalItem[5] = WeeklyShop_Item5Frame_List3
	g_WeeklyShop_SpeicalItem[6] = WeeklyShop_Item6Frame_List3


	g_WeekLyShopWeekCommonItemPic[1]=WeeklyShop_Item1
	g_WeekLyShopWeekCommonItemPic[2]=WeeklyShop_Item2
	g_WeekLyShopWeekCommonItemPic[3]=WeeklyShop_Item3
	g_WeekLyShopWeekCommonItemPic[4]=WeeklyShop_Item4
	g_WeekLyShopWeekCommonItemPic[5]=WeeklyShop_Item5
	g_WeekLyShopWeekCommonItemPic[6]=WeeklyShop_Item6

	g_WeekLyShopWeekCommonItemPrice[1] =WeeklyShop_Item1Info_Dynamic
	g_WeekLyShopWeekCommonItemPrice[2] =WeeklyShop_Item2Info_Dynamic
	g_WeekLyShopWeekCommonItemPrice[3] =WeeklyShop_Item3Info_Dynamic
	g_WeekLyShopWeekCommonItemPrice[4] =WeeklyShop_Item4Info_Dynamic
	g_WeekLyShopWeekCommonItemPrice[5] =WeeklyShop_Item5Info_Dynamic
	g_WeekLyShopWeekCommonItemPrice[6] =WeeklyShop_Item6Info_Dynamic

	g_WeekLyShopWeekCommonItemName[1] = WeeklyShop_Item1Text
	g_WeekLyShopWeekCommonItemName[2] = WeeklyShop_Item2Text
	g_WeekLyShopWeekCommonItemName[3] = WeeklyShop_Item3Text
	g_WeekLyShopWeekCommonItemName[4] = WeeklyShop_Item4Text
	g_WeekLyShopWeekCommonItemName[5] = WeeklyShop_Item5Text
	g_WeekLyShopWeekCommonItemName[6] = WeeklyShop_Item6Text

	g_WeekLyShopWeekCommonItemZheKou[1] = WeeklyShop_Item1Info_List2_DiscountText
	g_WeekLyShopWeekCommonItemZheKou[2] = WeeklyShop_Item2Info_List2_DiscountText
	g_WeekLyShopWeekCommonItemZheKou[3] = WeeklyShop_Item3Info_List2_DiscountText
	g_WeekLyShopWeekCommonItemZheKou[4] = WeeklyShop_Item4Info_List2_DiscountText
	g_WeekLyShopWeekCommonItemZheKou[5] = WeeklyShop_Item5Info_List2_DiscountText
	g_WeekLyShopWeekCommonItemZheKou[6] = WeeklyShop_Item6Info_List2_DiscountText

	g_WeekLyShopWeekCommonItemBuy[1] =WeeklyShop_Item1_List2_BuyImage
	g_WeekLyShopWeekCommonItemBuy[2] =WeeklyShop_Item2_List2_BuyImage
	g_WeekLyShopWeekCommonItemBuy[3] =WeeklyShop_Item3_List2_BuyImage
	g_WeekLyShopWeekCommonItemBuy[4] =WeeklyShop_Item4_List2_BuyImage
	g_WeekLyShopWeekCommonItemBuy[5] =WeeklyShop_Item5_List2_BuyImage
	g_WeekLyShopWeekCommonItemBuy[6] =WeeklyShop_Item6_List2_BuyImage

	g_WeekLyShopWeekCommonItemMask[1]=WeeklyShop_Item1_Mask
	g_WeekLyShopWeekCommonItemMask[2]=WeeklyShop_Item2_Mask
	g_WeekLyShopWeekCommonItemMask[3]=WeeklyShop_Item3_Mask
	g_WeekLyShopWeekCommonItemMask[4]=WeeklyShop_Item4_Mask
	g_WeekLyShopWeekCommonItemMask[5]=WeeklyShop_Item5_Mask
	g_WeekLyShopWeekCommonItemMask[6]=WeeklyShop_Item6_Mask

	--特殊
	g_WeekLyShopWeekSpecialItemPic[1] = WeeklyShop_Item1_List3
	g_WeekLyShopWeekSpecialItemPic[2] = WeeklyShop_Item2_List3
	g_WeekLyShopWeekSpecialItemPic[3] = WeeklyShop_Item3_List3
	g_WeekLyShopWeekSpecialItemPic[4] = WeeklyShop_Item4_List3
	g_WeekLyShopWeekSpecialItemPic[5] = WeeklyShop_Item5_List3
	g_WeekLyShopWeekSpecialItemPic[6] = WeeklyShop_Item6_List3

	g_WeekLyShopWeekSpecialItemPrice[1]=WeeklyShop_Item1Info_Dynamic_List3
	g_WeekLyShopWeekSpecialItemPrice[2]=WeeklyShop_Item2Info_Dynamic_List3
	g_WeekLyShopWeekSpecialItemPrice[3]=WeeklyShop_Item3Info_Dynamic_List3
	g_WeekLyShopWeekSpecialItemPrice[4]=WeeklyShop_Item4Info_Dynamic_List3
	g_WeekLyShopWeekSpecialItemPrice[5]=WeeklyShop_Item5Info_Dynamic_List3
	g_WeekLyShopWeekSpecialItemPrice[6]=WeeklyShop_Item6Info_Dynamic_List3

	g_WeekLyShopWeekSpecialItemName[1] = WeeklyShop_Item1Text_List3
	g_WeekLyShopWeekSpecialItemName[2] = WeeklyShop_Item2Text_List3
	g_WeekLyShopWeekSpecialItemName[3] = WeeklyShop_Item3Text_List3
	g_WeekLyShopWeekSpecialItemName[4] = WeeklyShop_Item4Text_List3
	g_WeekLyShopWeekSpecialItemName[5] = WeeklyShop_Item5Text_List3
	g_WeekLyShopWeekSpecialItemName[6] = WeeklyShop_Item6Text_List3

	g_WeekLyShopWeekSpecialItemZheKou[1] = WeeklyShop_Item1Info_List3_DiscountText
	g_WeekLyShopWeekSpecialItemZheKou[2] = WeeklyShop_Item2Info_List3_DiscountText
	g_WeekLyShopWeekSpecialItemZheKou[3] = WeeklyShop_Item3Info_List3_DiscountText
	g_WeekLyShopWeekSpecialItemZheKou[4] = WeeklyShop_Item4Info_List3_DiscountText
	g_WeekLyShopWeekSpecialItemZheKou[5] = WeeklyShop_Item5Info_List3_DiscountText
	g_WeekLyShopWeekSpecialItemZheKou[6] = WeeklyShop_Item6Info_List3_DiscountText


	g_WeekLyShopWeekSpecialItemBuy[1] = WeeklyShop_Item1_List3_BuyImage
	g_WeekLyShopWeekSpecialItemBuy[2] = WeeklyShop_Item2_List3_BuyImage
	g_WeekLyShopWeekSpecialItemBuy[3] = WeeklyShop_Item3_List3_BuyImage
	g_WeekLyShopWeekSpecialItemBuy[4] = WeeklyShop_Item4_List3_BuyImage
	g_WeekLyShopWeekSpecialItemBuy[5] = WeeklyShop_Item5_List3_BuyImage
	g_WeekLyShopWeekSpecialItemBuy[6] = WeeklyShop_Item6_List3_BuyImage


	g_WeekLyShopWeekSpecialItemMask[1] = WeeklyShop_Item1_Mask_List3
	g_WeekLyShopWeekSpecialItemMask[2] = WeeklyShop_Item2_Mask_List3
	g_WeekLyShopWeekSpecialItemMask[3] = WeeklyShop_Item3_Mask_List3
	g_WeekLyShopWeekSpecialItemMask[4] = WeeklyShop_Item4_Mask_List3
	g_WeekLyShopWeekSpecialItemMask[5] = WeeklyShop_Item5_Mask_List3
	g_WeekLyShopWeekSpecialItemMask[6] = WeeklyShop_Item6_Mask_List3


	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= WeeklyShop_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= WeeklyShop_Frame:GetProperty("UnifiedYPosition");

end

function WeeklyShop_OnEvent( event )

	--刷新元宝
	if event == "UPDATE_YUANBAO" then
		local nHaveYB = Player:GetData("YUANBAO")
		local strYuanBao = ScriptGlobal_Format("#{ZXSD_20250117_10}", tostring(nHaveYB))
		WeeklyShop_YuanBaoNum:SetText(strYuanBao)
		return
	elseif( event == "ADJEST_UI_POS" ) then
		WeeklyShop_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		WeeklyShop_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif event == "WEEK_SHOP_UPDATE_INFO" then
		local nShowType  = tonumber(arg0) 
		local  tempOjb  = tonumber(arg1) 
		if this:IsVisible() or nShowType == 1 then
			if not this:IsVisible() then
				g_WeeklyShopSelecetPage = 1
			
				if tempOjb ~= -1 then
					objCared = DataPool : GetNPCIDByServerID(tempOjb);
					if objCared ~= -1 then
						WeeklyShop_BeginCareObject(objCared)
					end
				end
				
				local bConfirm = Variable:GetVariable("WeeklyShopBuyConfirm")
				if bConfirm == nil then
					Variable:SetVariable("WeeklyShopBuyConfirm","1",0)
					bConfirm = 1
				end
					
				local mark = tonumber(bConfirm)
				if mark == 1 then
					WeeklyShop_querengoumaiBind:SetCheck(1)
				else
					WeeklyShop_querengoumaiBind:SetCheck(0)
				end
				g_WeeklyShop_Shop_BuyConfirm = WeeklyShop_querengoumaiBind : GetCheck()
				this:Show()	
			end	

			WeeklyShop_InIt(g_WeeklyShopSelecetPage)
		end	
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared and objCared ~= -1) then
			return
		end

		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			WeeklyShop_OnClose()
		end
	end

end

--================================================
-- 初始化界面信息
--================================================
function WeeklyShop_InIt(nCurlPage)

	-- 元宝
	local nHaveYB = Player:GetData("YUANBAO")
	local strYuanBao = ScriptGlobal_Format("#{ZXSD_20250117_10}", tostring(nHaveYB))
	WeeklyShop_YuanBaoNum:SetText(strYuanBao)
	local nSpecialTime, nCloseTime, nCommonBuy, nRedPoint1,nRedPoint2,nRedPoint3 = DataPool:GetWeekShopInfo()

	if nRedPoint1 == 0  or nCurlPage == 1 then
		WeeklyShop_Tab_Button01_Tips:Hide()
	else
		WeeklyShop_Tab_Button01_Tips:Show()
	end

	if nRedPoint2 == 0  or nCurlPage == 2 then
		WeeklyShop_Tab_Button02_Tips:Hide()
	else
		WeeklyShop_Tab_Button02_Tips:Show()
	end

	if nRedPoint3 == 0 or nCurlPage == 3 then
		WeeklyShop_Tab_Button03_Tips:Hide()
	else
		WeeklyShop_Tab_Button03_Tips:Show()
	end
	-- 
	if nCurlPage == 3 then  -- 珍宝阁
		g_WeeklyShopCommonPage = 1
		WeeklyShop_HideCommonInfo()
		WeeklyShop_HideDayInfo()
		WeeklyShop_ShowSpecialInfo()
		WeeklyShop_Tab_Button03:SetCheck(1)
		WeeklyShop_Tab_Button02:SetCheck(0)
		WeeklyShop_Tab_Button01:SetCheck(0)
	elseif nCurlPage == 2 then -- 常规商店
		
		WeeklyShop_HideDayInfo()
		WeeklyShop_HideSpecialInfo()
		WeeklyShop_ShowCommonInfo()
		WeeklyShop_Tab_Button03:SetCheck(0)
		WeeklyShop_Tab_Button02:SetCheck(1)
		WeeklyShop_Tab_Button01:SetCheck(0)
	else -- 每日
		g_WeeklyShopCommonPage = 1
		WeeklyShop_HideSpecialInfo()
		WeeklyShop_HideCommonInfo()
		WeeklyShop_ShowDayInfo()
		WeeklyShop_Tab_Button03:SetCheck(0)
		WeeklyShop_Tab_Button02:SetCheck(0)
		WeeklyShop_Tab_Button01:SetCheck(1)
	end
	WeeklyShop_RedPointChange(nCurlPage)
	this:Show()
end

function WeeklyShop_RedPointChange(nPage)
	local nSpecialTime, nCloseTime, nCommonBuy, nRedPoint1,nRedPoint2,nRedPoint3 = DataPool:GetWeekShopInfo()

	if nPage == 1 and  nRedPoint1 == 0 then
		return
	end

	if nPage == 2 and  nRedPoint2 == 0 then
		return
	end

	if nPage == 3 and  nRedPoint3 == 0 then
		return
	end

	-- 向服务器发送抽奖消息
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnWeekShopRedPoint")
		Set_XSCRIPT_ScriptID(999632)
		Set_XSCRIPT_Parameter(0,nPage-1)     --类型
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT();
end

-- 显示每日超值
function WeeklyShop_ShowDayInfo()

	WeeklyShop_Info:SetText("#{ZXSD_20250117_9}")

	local nId,nBuyCount,nItemId,nCount,nPirce,nZheKou,nMaxBuy = DataPool:GetWeekShopDayInfo()

	WeeklyShop_Item1_List1:SetActionItem(-1)
	WeeklyShop_Item1Text_List1:SetText("")
	WeeklyShop_Item1_List1_BuyImage:Hide()
	WeeklyShop_Item1Info_Dynamic_List1:SetText("")
	WeeklyShop_Item1Info_List1_DiscountText:SetText("")
	WeeklyShop_DiscountText:SetText("")
	if nId ~= nil then
		local	theAction = DataPool:CreateActionItemForShow(nItemId, nCount)
		if theAction:GetID() ~= 0 then
			WeeklyShop_Item1_List1:SetActionItem(theAction:GetID())
			local itemName = ScriptGlobal_Format("#{ZXSD_20250117_48}",theAction:GetName()) 
			WeeklyShop_Item1Text_List1:SetText(itemName)
			local msg = ScriptGlobal_Format("#{ZXSD_20250117_10}",nPirce)
			WeeklyShop_Item1Info_Dynamic_List1:SetText(msg)

			-- 已购买标签
			if nBuyCount >= nMaxBuy then
				WeeklyShop_Item1_List1_BuyImage:Show()
			end

			WeeklyShop_Item1Info_List1_DiscountText:SetText( string.format("%.1f",nZheKou/10))
		end	
	end

	WeeklyShop_UpdataInfo(0,0,nId,nBuyCount,nItemId,nCount,nPirce,nMaxBuy)

	WeeklyShop_ItemList_1:Show()
	WeeklyShop_Item1Frame_List1:Show()
	WeeklyShop_ItemClient_1:Show()
end

function WeeklyShop_HideDayInfo()
	WeeklyShop_ItemList_1:Hide()
	WeeklyShop_Item1Frame_List1:Hide()
	WeeklyShop_ItemClient_1:Hide()
end

-- 显示常规商店
function WeeklyShop_ShowCommonInfo()

	WeeklyShop_Info:SetText("#{ZXSD_20250117_11}")

	g_WeekLyShopCommonInfo = {}
	-- 标题修改
	WeeklyShop_WeeklyShop_ItemList_2_Title:SetText(g_WeeklyShopCommonText[g_WeeklyShopCommonPage])
	WeeklyShop_WeeklyShop_ItemList_2_Title:Show()

	WeeklyShop_WeeklyShop_ItemList_2_Title_Tips:Hide()

	local nBuyCommont,nLimitBuy,nCommonBuy,nOpenLimit = DataPool:GetWeekShopCommonBuyInfo(g_WeeklyShopCommonPage-1)

	local nbCanBuy = 1
	if g_WeeklyShopCommonPage > 1 then
		local nBuyCommont2,nLimitBuy2,nCommonBuy2,nOpenLimit2 = DataPool:GetWeekShopCommonBuyInfo(g_WeeklyShopCommonPage-2)
		if nBuyCommont2 < nLimitBuy2 then
			nbCanBuy = 0
			local msg = ScriptGlobal_Format("#{ZXSD_20250117_15}",nLimitBuy2 - nBuyCommont2, g_WeeklyShopCommonText[g_WeeklyShopCommonPage-1])
			WeeklyShop_WeeklyShop_ItemList_2_Title_Tips:SetText(msg)
	
			WeeklyShop_WeeklyShop_ItemList_2_Title_Tips:Show()
		else
			WeeklyShop_WeeklyShop_ItemList_2_Title_Tips:Hide()
		end
	end

	-- 上页
	if g_WeeklyShopCommonPage == 1 then
		WeeklyShop_UpPage:Disable()
	else
		WeeklyShop_UpPage:Enable()
	end
	WeeklyShop_UpPage:Show()

	-- 下页
	if g_WeeklyShopCommonPage == 3 then
		WeeklyShop_DownPage:Disable()
	else
		WeeklyShop_DownPage:Enable()
	end
	WeeklyShop_DownPage:Show()

	-- 页数
	local msg = ScriptGlobal_Format("#{ZXSD_20250117_18}",g_WeeklyShopCommonPage)
	WeeklyShop_CurrentlyPage:SetText(msg)
	WeeklyShop_CurrentlyPage:Show()
	
	--开启进度
	msg = ScriptGlobal_Format("#{ZXSD_20250117_19}",nCommonBuy)
	WeeklyShop_ItemClient_2_Tips:SetText(msg)
	WeeklyShop_ItemClient_2_Tips:Show()

	--道具信息
	local nCommonCount =DataPool:GetWeekShopCommonCount()
	for i = 1,  nCommonCount do 
		local nId,nBuyCount,nItemId,nCount,nPirce,nZheKou,nMaxBuy = DataPool:GetWeekShopCommonInfo(i-1, g_WeeklyShopCommonPage-1)

		g_WeeklyShop_WeekItem[i]:Hide()
		g_WeekLyShopWeekCommonItemPic[i]:SetActionItem(-1)
		g_WeekLyShopWeekCommonItemName[i]:SetText("")
		g_WeekLyShopWeekCommonItemBuy[i]:Hide()
		g_WeekLyShopWeekCommonItemPrice[i]:SetText("")
		g_WeekLyShopWeekCommonItemZheKou[i]:SetText("")
		if  nbCanBuy == 0 then
			g_WeekLyShopWeekCommonItemMask[i]:Show()
		--	g_WeeklyShop_WeekItem[i]:Disable()
		else
			g_WeekLyShopWeekCommonItemMask[i]:Hide()
		--	g_WeeklyShop_WeekItem[i]:Enable()
		end		
		if nId ~= nil then
			local	theAction = DataPool:CreateActionItemForShow(nItemId, nCount)
			if theAction:GetID() ~= 0 then
				g_WeekLyShopWeekCommonItemPic[i]:SetActionItem(theAction:GetID())
				local itemName =  ScriptGlobal_Format("#{ZXSD_20250117_48}",theAction:GetName()) 
				g_WeekLyShopWeekCommonItemName[i]:SetText(itemName)
				local msg = ScriptGlobal_Format("#{ZXSD_20250117_10}",nPirce)
				g_WeekLyShopWeekCommonItemPrice[i]:SetText(msg)

				-- 已购买标签
				if nBuyCount >= nMaxBuy then
					g_WeekLyShopWeekCommonItemBuy[i]:Show()
				end
				g_WeekLyShopWeekCommonItemZheKou[i]:SetText( string.format("%.1f",nZheKou/10))
			end	
			g_WeeklyShop_WeekItem[i]:Show()
		end

		WeeklyShop_UpdataInfo(1,i-1,nId,nBuyCount,nItemId,nCount,nPirce,nMaxBuy)
	end

	WeeklyShop_ItemClient_2:Show()
end

function WeeklyShop_HideCommonInfo()
	-- 标题
	WeeklyShop_WeeklyShop_ItemList_2_Title:Hide()
	WeeklyShop_WeeklyShop_ItemList_2_Title_Tips:Hide()
	
	-- 下方信息
	WeeklyShop_UpPage:Hide()
	WeeklyShop_CurrentlyPage:Hide()
	WeeklyShop_DownPage:Hide()
	WeeklyShop_ItemClient_2_Tips:Hide()

	--物品信息
	for i = 1 , table.getn(g_WeeklyShop_WeekItem) do
		g_WeeklyShop_WeekItem[i]:Hide()
	end

	WeeklyShop_ItemClient_2:Hide()
end

-- 显示珍宝阁
function WeeklyShop_ShowSpecialInfo()
	g_WeekLyShopSpecialInfo = {}

	WeeklyShop_Info:SetText("#{ZXSD_20250117_20}")

	local nSpecialTime, nCloseTime, nCommonBuy, nRedPoint1,nRedPoint2,nRedPoint3 = DataPool:GetWeekShopInfo()
	if nSpecialTime == 0 then
		WeeklyShop_LockTips_2:Show()
		WeeklyShop_LockTips_1:Show()
		local msg = ScriptGlobal_Format("#{ZXSD_20250117_22}",nCommonBuy)
		WeeklyShop_LockTips_2:SetText(msg)
		WeeklyShop_ItemClient_3_Tips:Hide()
		--物品信息
		for i = 1 ,table.getn(g_WeeklyShop_SpeicalItem) do 
			g_WeeklyShop_SpeicalItem[i]:Hide()
		end
		WeeklyShop_ItemClient_3:Show()
		WeeklyShop_LockTipsClient:Show()
		return
	end

	WeeklyShop_LockTips_2:Hide()
	WeeklyShop_LockTips_1:Hide()

	local nMinu = math.floor(nCloseTime/60)
	local msg = ScriptGlobal_Format("#{ZXSD_20250117_23}",math.floor(nMinu/60) ,math.mod(nMinu, 60))
	WeeklyShop_ItemClient_3_Tips:SetText(msg)
	WeeklyShop_ItemClient_3_Tips:Show()
	--道具信息
	local nCommonCount =DataPool:GetWeekShopSpecialCount()

	for i = 1,  nCommonCount do 
		local nId,nBuyCount,nItemId,nCount,nPirce,nZheKou,nMaxBuy = DataPool:GetWeekShopSpecialInfo(i-1, g_WeeklyShopCommonPage-1)

		g_WeeklyShop_SpeicalItem[i]:Hide()
		g_WeekLyShopWeekSpecialItemPic[i]:SetActionItem(-1)
		g_WeekLyShopWeekSpecialItemName[i]:SetText("")
		g_WeekLyShopWeekSpecialItemBuy[i]:Hide()
		g_WeekLyShopWeekSpecialItemPrice[i]:SetText("")
		g_WeekLyShopWeekSpecialItemZheKou[i]:SetText("")
		g_WeekLyShopWeekSpecialItemMask[i]:Hide()
		if nId ~= nil then
			local	theAction = DataPool:CreateActionItemForShow(nItemId, nCount)
			if theAction:GetID() ~= 0 then
				g_WeekLyShopWeekSpecialItemPic[i]:SetActionItem(theAction:GetID())
				local itemName =  ScriptGlobal_Format("#{ZXSD_20250117_48}",theAction:GetName()) 
				g_WeekLyShopWeekSpecialItemName[i]:SetText(itemName)
				local msg = ScriptGlobal_Format("#{ZXSD_20250117_10}",nPirce)
				g_WeekLyShopWeekSpecialItemPrice[i]:SetText(msg)

				-- 已购买标签
				if nBuyCount >= nMaxBuy then
					g_WeekLyShopWeekSpecialItemBuy[i]:Show()
				end
				g_WeekLyShopWeekSpecialItemZheKou[i]:SetText( string.format("%.1f",nZheKou/10))
			end	
			g_WeeklyShop_SpeicalItem[i]:Show()
		end
		WeeklyShop_UpdataInfo(2,i-1,nId,nBuyCount,nItemId,nCount,nPirce,nMaxBuy)
	end
	WeeklyShop_ItemClient_3:Show()
	WeeklyShop_LockTipsClient:Hide()
end

function WeeklyShop_HideSpecialInfo()
	WeeklyShop_LockTips_2:Hide()
	WeeklyShop_LockTips_1:Hide()
	WeeklyShop_ItemClient_3_Tips:Hide()

	--物品信息
	for i = 1 , table.getn(g_WeeklyShop_SpeicalItem)  do
		g_WeeklyShop_SpeicalItem[i]:Hide()
	end
	WeeklyShop_ItemClient_3:Hide()
	WeeklyShop_LockTipsClient:Hide()
end

function WeeklyShop_UpdataInfo(nType,nIndex, nId,nBuyCount, nItem,nCount,nPrice, nMaxBuy)
	if nType == 0 then
		if g_WeekLyShopDayInfo[nIndex] == nil then
			g_WeekLyShopDayInfo[nIndex] = {}
		end

		local ShopInfo = g_WeekLyShopDayInfo[nIndex]

		ShopInfo["id"] = nId
		ShopInfo["buyCount"] = nBuyCount
		ShopInfo["itemid"] = nItem
		ShopInfo["count"] = count
		ShopInfo["price"] = nPrice
		ShopInfo["maxBuy"] = nMaxBuy
	elseif nType == 1 then
		
		if g_WeekLyShopCommonInfo[nIndex] == nil then
			g_WeekLyShopCommonInfo[nIndex] = {}
		end

		local ShopInfo = g_WeekLyShopCommonInfo[nIndex]

		ShopInfo["id"] = nId
		ShopInfo["buyCount"] = nBuyCount
		ShopInfo["itemid"] = nItem
		ShopInfo["count"] = count
		ShopInfo["price"] = nPrice
		ShopInfo["maxBuy"] = nMaxBuy
	elseif nType == 2 then
		if g_WeekLyShopSpecialInfo[nIndex] == nil then
			g_WeekLyShopSpecialInfo[nIndex] = {}
		end
		local ShopInfo = g_WeekLyShopSpecialInfo[nIndex]

		ShopInfo["id"] = nId
		ShopInfo["buyCount"] = nBuyCount
		ShopInfo["itemid"] = nItem
		ShopInfo["count"] = count
		ShopInfo["price"] = nPrice
		ShopInfo["maxBuy"] = nMaxBuy
	end
end	

--================================================
-- 恢复好礼界面的默认相对位置
--================================================
function WeeklyShop_ResetPos()
	WeeklyShop_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	WeeklyShop_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

-- 窗口关闭
function WeeklyShop_OnClose()
	WeeklyShop_StopCareObject()
	this:Hide();
end


-- 页签选择
function WeeklyShop_Tab_Click(nPage)
	g_WeeklyShopSelecetPage = nPage
	WeeklyShop_InIt(nPage)
end

-- 日商店点击
function WeeklyShop_List1_Clicked(nCurl)
	-- 客户端等级限制
	if  Player:GetData("LEVEL") < 60 then
		PushDebugMessage("#{ZXSD_20250117_24}")
		return
	end

	local nHaveYB = Player:GetData("YUANBAO")
	if nHaveYB < g_WeekLyShopDayInfo[0].price then
		PushDebugMessage("#{ZXSD_20250117_28}")
		return
	end
		
	if g_WeekLyShopDayInfo[0].buyCount >= g_WeekLyShopDayInfo[0].maxBuy then
		PushDebugMessage("#{ZXSD_20250117_25}")
		return
	end

	local nConfirm = 0
	if g_WeeklyShop_Shop_BuyConfirm == 0 then
		nConfirm = 1
	end

	-- 向服务器发送抽奖消息
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnBuyWeekShopItem")
		Set_XSCRIPT_ScriptID(999632)
		Set_XSCRIPT_Parameter(0,0)     --类型
		Set_XSCRIPT_Parameter(1,0) 	   --当前档
		Set_XSCRIPT_Parameter(2,g_WeekLyShopDayInfo[0].id) --当前id
		Set_XSCRIPT_Parameter(3,nConfirm)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
	
end

-- 普通商店点击
function WeeklyShop_Clicked(nCurl)
	-- 客户端等级限制
	if  Player:GetData("LEVEL") < 60 then
		PushDebugMessage("#{ZXSD_20250117_24}")
		return
	end

	if g_WeekLyShopCommonInfo[nCurl-1] == nil then
		return
	end

	local nHaveYB = Player:GetData("YUANBAO")
	if nHaveYB < g_WeekLyShopCommonInfo[nCurl-1].price then
		PushDebugMessage("#{ZXSD_20250117_28}")
		return
	end
		
	if g_WeekLyShopCommonInfo[nCurl-1].buyCount >= g_WeekLyShopCommonInfo[nCurl-1].maxBuy then
		PushDebugMessage("#{ZXSD_20250117_25}")
		return
	end

	local nConfirm = 0
	if g_WeeklyShop_Shop_BuyConfirm == 0 then
		nConfirm = 1
	end
		
	-- 向服务器发送抽奖消息
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnBuyWeekShopItem")
		Set_XSCRIPT_ScriptID(999632)
		Set_XSCRIPT_Parameter(0,1)     --类型
		Set_XSCRIPT_Parameter(1,g_WeeklyShopCommonPage-1) 	   --当前档
		Set_XSCRIPT_Parameter(2, g_WeekLyShopCommonInfo[nCurl-1].id) --当前id
		Set_XSCRIPT_Parameter(3,nConfirm)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT();
end


-- 珍宝阁商店点击
function WeeklyShop_List3_Clicked(nCurl)
	-- 客户端等级限制
	if  Player:GetData("LEVEL") < 60 then
		PushDebugMessage("#{ZXSD_20250117_24}")
		return
	end

	if g_WeekLyShopSpecialInfo[nCurl-1] == nil then
		return
	end

	local nHaveYB = Player:GetData("YUANBAO")
	if nHaveYB < g_WeekLyShopSpecialInfo[nCurl-1].price then
		PushDebugMessage("#{ZXSD_20250117_28}")
		return
	end
		
	if g_WeekLyShopSpecialInfo[nCurl-1].buyCount >= g_WeekLyShopSpecialInfo[nCurl-1].maxBuy then
		PushDebugMessage("#{ZXSD_20250117_25}")
		return
	end
		
	local nConfirm = 0
	if g_WeeklyShop_Shop_BuyConfirm == 0 then
		nConfirm = 1
	end

	-- 向服务器发送抽奖消息
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnBuyWeekShopItem")
		Set_XSCRIPT_ScriptID(999632)
		Set_XSCRIPT_Parameter(0,2)     --类型
		Set_XSCRIPT_Parameter(1,0) 	   --当前档
		Set_XSCRIPT_Parameter(2, g_WeekLyShopSpecialInfo[nCurl-1].id) --当前id
		Set_XSCRIPT_Parameter(3,nConfirm)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT();
end

-- 上页
function WeeklyShop_PageUp()
	if g_WeeklyShopCommonPage == 1 then
		return
	end	

	g_WeeklyShopCommonPage = g_WeeklyShopCommonPage-1
	WeeklyShop_ShowCommonInfo()
end

--下页
function WeeklyShop_PageDown()
	if g_WeeklyShopCommonPage == 3 then
		return
	end	

	g_WeeklyShopCommonPage = g_WeeklyShopCommonPage+1
	WeeklyShop_ShowCommonInfo()
end

function WeeklyShop_querengoumai_Clicked()
	if g_WeeklyShop_Shop_BuyConfirm == 0 then
		Variable:SetVariable("WeeklyShopBuyConfirm","1",0)
		g_WeeklyShop_Shop_BuyConfirm = 1
	else
		Variable:SetVariable("WeeklyShopBuyConfirm","0",0)
		g_WeeklyShop_Shop_BuyConfirm = 0
	end
end

--=========================================================
--开始关心NPC
--=========================================================
function WeeklyShop_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "WeeklyShop");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "WeeklyShop")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function WeeklyShop_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "WeeklyShop");
		g_Object = -1;
	end
end
