local	g_MingshiShop_CurPage		=	0		--当前所在的页面
local	g_MingshiShop_CommodityNums_PerPage	=	15	--每个页面展示的商品的数量
local	g_MingshiShop_ControlsTable	=	{}		--界面上的控件表
local	g_MingshiShop_MaxCommodityType	=	32		--最多商品的数量
local	g_MingshiShop_IfBuyConfirm	=	1		
local	g_MingShiShop_Frame_UnifiedPosition
local	g_MSD_MD = 1595
local	objCared = -1;

local	g_MingShiShop_BeginTime = 20200320
local	g_MingShiShop_EndTime = 20200720

--===============================================
-- OnLoad()
--===============================================
function MingshiShop_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--逻辑相关的事件
	this:RegisterEvent("UI_COMMAND");	
	this:RegisterEvent("OBJECT_CARED_EVENT");		

end

function MingshiShop_OnLoad()
	g_MingshiShop_ControlsTable	=	{
		[0]={ ActionItem = MingShiShop_Item1,CommodityName = MingShiShop_ItemInfo1_Name, CommodityPrize = MingShiShop_ItemInfo1_Text },
		[1]={ ActionItem = MingShiShop_Item2,CommodityName = MingShiShop_ItemInfo2_Name, CommodityPrize = MingShiShop_ItemInfo2_Text },
		[2]={ ActionItem = MingShiShop_Item3,CommodityName = MingShiShop_ItemInfo3_Name, CommodityPrize = MingShiShop_ItemInfo3_Text },
		[3]={ ActionItem = MingShiShop_Item4,CommodityName = MingShiShop_ItemInfo4_Name, CommodityPrize = MingShiShop_ItemInfo4_Text },
		[4]={ ActionItem = MingShiShop_Item5,CommodityName = MingShiShop_ItemInfo5_Name, CommodityPrize = MingShiShop_ItemInfo5_Text },
		[5]={ ActionItem = MingShiShop_Item6,CommodityName = MingShiShop_ItemInfo6_Name, CommodityPrize = MingShiShop_ItemInfo6_Text },
		[6]={ ActionItem = MingShiShop_Item7,CommodityName = MingShiShop_ItemInfo7_Name, CommodityPrize = MingShiShop_ItemInfo7_Text },
		[7]={ ActionItem = MingShiShop_Item8,CommodityName = MingShiShop_ItemInfo8_Name, CommodityPrize = MingShiShop_ItemInfo8_Text },
		[8]={ ActionItem = MingShiShop_Item9,CommodityName = MingShiShop_ItemInfo9_Name, CommodityPrize = MingShiShop_ItemInfo9_Text },
		[9]={ ActionItem = MingShiShop_Item10,CommodityName = MingShiShop_ItemInfo10_Name, CommodityPrize = MingShiShop_ItemInfo10_Text },
		[10]={ ActionItem = MingShiShop_Item11,CommodityName = MingShiShop_ItemInfo11_Name, CommodityPrize = MingShiShop_ItemInfo11_Text },
		[11]={ ActionItem = MingShiShop_Item12,CommodityName = MingShiShop_ItemInfo12_Name, CommodityPrize = MingShiShop_ItemInfo12_Text },
		[12]={ ActionItem = MingShiShop_Item13,CommodityName = MingShiShop_ItemInfo13_Name, CommodityPrize = MingShiShop_ItemInfo13_Text },
		[13]={ ActionItem = MingShiShop_Item14,CommodityName = MingShiShop_ItemInfo14_Name, CommodityPrize = MingShiShop_ItemInfo14_Text },
		[14]={ ActionItem = MingShiShop_Item15,CommodityName = MingShiShop_ItemInfo15_Name, CommodityPrize = MingShiShop_ItemInfo15_Text },
	}
	g_MingShiShop_Frame_UnifiedPosition = MingShiShop_Frame:GetProperty("UnifiedPosition")
	g_MingshiShop_CurPage		=	0
end

--===============================================
-- OnEvent()
--===============================================
function MingshiShop_OnEvent( event )
	if (event == "UI_COMMAND" and tonumber(arg0) == 892850) then		
		local nType = Get_XParam_INT(0)
		if nType == 0 then
			MingshiShop_FreshWindow()
			local xx = Get_XParam_INT(1)
			objCared = DataPool:GetNPCIDByServerID(xx)			
			this:CareObject(objCared, 1, "MingshiShop");
			this:Show()
		elseif nType == 1 then --刷新名仕点
			local nMSD = Get_XParam_INT(1)
			MingShiShop_Text1:SetText("#{MSSD_180529_10}"..tostring(DataPool:GetPlayerMission_DataRound(g_MSD_MD)))
		end
	elseif event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		MingShiShop_Frame_On_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			PaoShang_OnClose()
		end				
	end
end

--===============================================
--刷新界面信息
--===============================================
function MingshiShop_FreshWindow()
	g_MingshiShop_MaxCommodityType = KMSDShop:GetCommodityTypesNum()
	for i = 0, g_MingshiShop_CommodityNums_PerPage - 1 do
		local	index = i + g_MingshiShop_CommodityNums_PerPage * g_MingshiShop_CurPage 
		if index >= g_MingshiShop_MaxCommodityType then
			g_MingshiShop_ControlsTable[i].CommodityName:Hide()
			g_MingshiShop_ControlsTable[i].CommodityPrize:Hide()
			g_MingshiShop_ControlsTable[i].ActionItem:SetActionItem(-1)
			g_MingshiShop_ControlsTable[i].ActionItem:Disable()

		else
			local	nItemType, nMaxNum, nPrize, CommodityName = KMSDShop:EnumKMSDShopCommodityInfo(index)
			local theAction = DataPool:CreateActionItemForShowWithMaxNum(nItemType, 1, nMaxNum)
			if theAction:GetID() ~= 0 then
				g_MingshiShop_ControlsTable[i].ActionItem:SetActionItem(theAction:GetID())
			end
			g_MingshiShop_ControlsTable[i].CommodityName:SetText("#cfff263"..CommodityName)
			g_MingshiShop_ControlsTable[i].CommodityPrize:SetText("#{MSSD_180529_9}".."#cfff263"..nPrize)
			g_MingshiShop_ControlsTable[i].CommodityName:Show()
			g_MingshiShop_ControlsTable[i].CommodityPrize:Show()
		end
	end
	MingShiShop_Text1:SetText("#{MSSD_180529_10}"..tostring(DataPool:GetPlayerMission_DataRound(g_MSD_MD)))

	MingShiShop_querengoumaiBind:SetCheck(g_MingshiShop_IfBuyConfirm)
end

function MingshiShop_BuyItem_Clicked(nPos)
	
	--增加时间判断
	if MingshiShop_CheckTime() == 0 then  --不在活动时间
		PushDebugMessage("#{TWSC_200817_15}")
		return 0
	end	
	
	local	nIndex = nPos + g_MingshiShop_CommodityNums_PerPage * g_MingshiShop_CurPage 
	local	nItemType, nMaxNum, nPrize, CommodityName = KMSDShop:EnumKMSDShopCommodityInfo(nIndex)
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	
	local nIsMulBuy = KMSDShop:CheckIsMultiBuy(nIndex)
	if nIsMulBuy >= 1 then
		return
	else
		if DataPool:GetPlayerMission_DataRound(g_MSD_MD) < nPrize then
			--战盟贡献度不够
			PushDebugMessage("#{MSSD_180529_16}")
			return
		end
			
		if g_MingshiShop_IfBuyConfirm ~=  1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("BuyItem")
				Set_XSCRIPT_ScriptID(892850)
				Set_XSCRIPT_Parameter(0,nIndex);
				Set_XSCRIPT_Parameter(1,1);				
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		else
			KMSDShop:OpenBuyConfirmMessageBox(nIndex)
		end
	end
end

function MingshiShop_CheckTime()
	--local curDayTime = tonumber(DataPool:GetServerDayTime())
	--if curDayTime >= g_MingShiShop_BeginTime and curDayTime <= g_MingShiShop_EndTime then
		return 1  --在活动时间
	--else
	--	return 0  --不在活动时间
	--end
end

function MingshiShop_MultiBuyClicked()
	--增加时间判断
	if MingshiShop_CheckTime() == 0 then  --不在活动时间
		PushDebugMessage("#{TWSC_200817_15}")
		return 0
	end
	if IsWindowShow("MingshiShop_MBuy") then
		CloseWindow("MingshiShop_MBuy",true)
	end
	PrepearBuyMult()
end

function MingshiShop_OnHiden()
	if IsWindowShow("MingshiShop_MBuy") then
		CloseWindow("MingshiShop_MBuy",true)
	end

	--重新打开界面,默认显示第一页
	--默认选中购买确认
	this:CareObject(objCared, 0, "MingshiShop");	
	MingShiShop_querengoumaiBind:SetCheck(1)
	g_MingshiShop_CurPage	=	0
	SetDefaultMouse()
	this:Hide()
end

function MingshiShop_BuyConfirm_Clicked()
	g_MingshiShop_IfBuyConfirm = MingShiShop_querengoumaiBind:GetCheck()
end

--获取商品最多有多少页
function MingshiShop_GetMaxPages()
	return	math.ceil(g_MingshiShop_MaxCommodityType/g_MingshiShop_CommodityNums_PerPage)
end

function MingShiShop_Frame_On_ResetPos()
	 MingShiShop_Frame:SetProperty("UnifiedPosition", g_MingShiShop_Frame_UnifiedPosition)
end

