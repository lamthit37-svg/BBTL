-- XiGuaDraw_Shop

-- 保存UI默认位置
local g_XiGuaDraw_Shop_UnifiedPosition = nil

local XiGuaDraw_Shop_ItemButton_Frame = {}
local XiGuaDraw_Shop_ItemButton_Icon = {}
local XiGuaDraw_Shop_ItemButton_Name = {}
local XiGuaDraw_Shop_ItemButton_Prize = {}
local XiGuaDraw_Shop_ItemButton_Discount = {}
local XiGuaDraw_Shop_ItemButton_Discountbk = {}
local XiGuaDraw_Shop_ItemButton_Eyesign = {}
local XiGuaDraw_Shop_ItemButton_UnBind = {}
local XiGuaDraw_Shop_ItemButton_Animate = {}

local XiGuaDraw_Shop_RewardButton_Btn = {}
local XiGuaDraw_Shop_RewardButton_Tips = {}
local XiGuaDraw_Shop_RewardButton_Get = {}
local XiGuaDraw_Shop_RewardButton_Text = {}

local g_XiGuaShopRoundItemIndex = {0,0,0,0,0,0,0,0}
local g_XiGuaShopRoundItemFlag = {0,0,0,0,0,0,0,0}
local g_XiGuaShopTotalFlag = {0,0,0,0,0,0}

local g_nTodayCount = 0
local g_nTodayFreeCount = 0
local g_nTotalYBCost = 0

local g_NeedCostYB = {
	[1] = 4000,
	[2] = 12000,
	[3] = 24000,
	[4] = 40000,
	[5] = 60000,
	[6] = 80000,
}

local g_costYBTips = {
	[1] = "#{XGJSD_230526_44}",
	[2] = "#{XGJSD_230526_45}",
	[3] = "#{XGJSD_230526_46}",
	[4] = "#{XGJSD_230526_47}",
	[5] = "#{XGJSD_230526_48}",
	[6] = "#{XGJSD_230526_49}",
}

local g_costYBTips_KJ = {
	[1] = "#{XGJSD_230526_44}",
	[2] = "#{XGJSD_230526_45}",
	[3] = "#{XGJSD_230526_46}",
	[4] = "#{XGJSD_250714_1}",
	[5] = "#{XGJSD_230526_48}",
	[6] = "#{XGJSD_231027_01}",
}
function XiGuaDraw_Shop_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end 

function XiGuaDraw_Shop_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 99857401 ) then

		local operator = Get_XParam_INT(0)
		for i = 1, 8 do
			g_XiGuaShopRoundItemIndex[i] = Get_XParam_INT(i)
		end
			
		g_nTodayCount = Get_XParam_INT(9)
		g_nTodayFreeCount = Get_XParam_INT(10)
		g_nTotalYBCost = Get_XParam_INT(11)	
		
		if operator == 1 then
			XiGuaDraw_Shop_Update()
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99857402 ) then 
		for i = 1, 8 do
			g_XiGuaShopRoundItemFlag[i] = Get_XParam_INT(i-1)
		end
		XiGuaDraw_Shop_Update()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99857405 ) then 
		for i = 1, 6 do
			g_XiGuaShopTotalFlag[i] = Get_XParam_INT(i-1)
		end
		XiGuaDraw_Shop_Update()
	elseif (event == "ADJEST_UI_POS" ) then
		XiGuaDraw_Shop_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XiGuaDraw_Shop_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()

	end
end

function XiGuaDraw_Shop_OnLoad()

	for i = 1, 8 do
		XiGuaDraw_Shop_ItemButton_Frame[i] = _G["XiGuaDraw_Shop_Item"..i]
		XiGuaDraw_Shop_ItemButton_Icon[i]= _G["XiGuaDraw_Shop_Item"..i.."_Icon"]
		XiGuaDraw_Shop_ItemButton_Name[i] = _G["XiGuaDraw_Shop_Item"..i.."_Text1"]
		XiGuaDraw_Shop_ItemButton_Prize[i] = _G["XiGuaDraw_Shop_Item"..i.."_Text2"]
		XiGuaDraw_Shop_ItemButton_Discount[i] = _G["XiGuaDraw_Shop_Item"..i.."_DiscountText"]
		XiGuaDraw_Shop_ItemButton_Discountbk[i] = _G["XiGuaDraw_Shop_Item"..i.."_DiscountBK"]
		XiGuaDraw_Shop_ItemButton_Eyesign[i] = _G["XiGuaDraw_Shop_Item"..i.."_EyeSign"]
		XiGuaDraw_Shop_ItemButton_UnBind[i] = _G["XiGuaDraw_Shop_Item"..i.."_Icon_Feibang"]
		XiGuaDraw_Shop_ItemButton_Animate[i] = _G["XiGuaDraw_Shop_Item"..i.."_Icon_Animate"]
		XiGuaDraw_Shop_ItemButton_Eyesign[i]:SetEvent("Clicked", "XiGuaDraw_Shop_OpenDressPreview("..i..")")
	end


	for i = 1, 6 do
		XiGuaDraw_Shop_RewardButton_Btn[i] = _G["XiGuaDraw_Shop_Progress_Icon"..i]
		XiGuaDraw_Shop_RewardButton_Tips[i] = _G["XiGuaDraw_Shop_Progress_Icon"..i.."_Tips"]
		XiGuaDraw_Shop_RewardButton_Get[i] = _G["XiGuaDraw_Shop_Progress_Icon"..i.."_Get"]
		XiGuaDraw_Shop_RewardButton_Text[i] = _G["XiGuaDraw_Shop_ProgressNumber_Text"..i]
	end
	
	g_XiGuaDraw_Shop_UnifiedPosition = XiGuaDraw_Shop_FrameNULL:GetProperty("UnifiedPosition")
end 

--=========================================================
--刷新位置
--=========================================================
function XiGuaDraw_Shop_On_ResetPos()
	XiGuaDraw_Shop_FrameNULL:SetProperty("UnifiedPosition", g_XiGuaDraw_Shop_UnifiedPosition);
end

function XiGuaDraw_Shop_Update()
	
	--剩余免费次数
	XiGuaDraw_Shop_Text:SetText(ScriptGlobal_Format("#{XGJSD_230526_38}",g_nTodayFreeCount))
	--今日次数
	XiGuaDraw_Shop_Text1:SetText(ScriptGlobal_Format("#{XGJSD_230526_41}", g_nTodayCount))
	
	if g_nTodayFreeCount > 0 then
		XiGuaDraw_Shop_But_Text:SetText("#{XGJSD_230526_70}")
	else
		XiGuaDraw_Shop_But_Text:SetText("#{XGJSD_230526_71}")
	end
	
	local kajiType = KaJi:LuaFnGetKaJiType(137)
	if kajiType == 1 then
		XiGuaDraw_Shop_Text:SetToolTip("#{XGJSD_230526_40}")
	else
		XiGuaDraw_Shop_Text:SetToolTip("#{XGJSD_230526_39}")
	end
	--刷新确认
	local bConfirm = tonumber(NpcShop:GetXiGuaShopDirectly())
	if ( bConfirm == 1 ) then
		XiGuaDraw_Shop_Shuaxin_Bind:SetCheck( 0 );
	elseif ( bConfirm == 0 ) then
		XiGuaDraw_Shop_Shuaxin_Bind:SetCheck( 1 );
	end
	
	--累计消费
	XiGuaDraw_Shop_Progress_Text:SetText(ScriptGlobal_Format("#{XGJSD_230526_42}",g_nTotalYBCost))
	--商品展示
	local isPreview = 0
	for i = 1, 8 do
		if g_XiGuaShopRoundItemIndex ~= nil and g_XiGuaShopRoundItemFlag ~= nil then
			local ItemIndex = g_XiGuaShopRoundItemIndex[i]
			local curBuyFlag = g_XiGuaShopRoundItemFlag[i]
			
			local nShowItemId,nType,nItemNum,nIsBind,nPrize,nDisCount,nQuality = DataPool:LuaFnGet2023XiGuaShopInfo(ItemIndex)
			if nShowItemId ~= nil and nShowItemId > 0 then
				if nIsBind == 1 then
					local theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
					XiGuaDraw_Shop_ItemButton_Icon[i]:SetActionItem(theAction:GetID())
					XiGuaDraw_Shop_ItemButton_UnBind[i]:Hide()
				else
					local theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
					XiGuaDraw_Shop_ItemButton_Icon[i]:SetActionItem(theAction:GetID())
					XiGuaDraw_Shop_ItemButton_UnBind[i]:Show()
				end
				
				--稀有物品
				if nQuality > 0 then
					XiGuaDraw_Shop_ItemButton_Animate[i]:Show()
				else
					XiGuaDraw_Shop_ItemButton_Animate[i]:Hide()
				end
				--本轮商品已购买
				if curBuyFlag > 0 then
					XiGuaDraw_Shop_ItemButton_Icon[i]:Disable()
				else
					XiGuaDraw_Shop_ItemButton_Icon[i]:Enable()
				end
				--商品名
				XiGuaDraw_Shop_ItemButton_Name[i]:SetText("#cfff263" .. DataPool:Lua_GetItemNameByIndex(nShowItemId))
				--商品价格
				XiGuaDraw_Shop_ItemButton_Prize[i]:SetText("#{XGJSD_230526_17}"..ScriptGlobal_Format("#{XGJSD_230526_18}",nPrize))
				--折扣
				if nDisCount > 0 then
					XiGuaDraw_Shop_ItemButton_Discount[i]:Show()
					XiGuaDraw_Shop_ItemButton_Discountbk[i]:Show()
					local intPart = math.floor(nDisCount)
					local floatPart = math.mod(math.floor(nDisCount*10),10)
					if floatPart == 0 then
						XiGuaDraw_Shop_ItemButton_Discount[i]:SetText(ScriptGlobal_Format("#{XGJSD_230526_19}", tostring(intPart)))
					else
						XiGuaDraw_Shop_ItemButton_Discount[i]:SetText(ScriptGlobal_Format("#{XGJSD_230526_19}", tostring(intPart).."."..tostring(floatPart)))
					end
				else
					XiGuaDraw_Shop_ItemButton_Discountbk[i]:Hide()
					XiGuaDraw_Shop_ItemButton_Discount[i]:Hide()
				end
				--时装预览
				if nShowItemId == 38008644 or nShowItemId == 38008053 then
					isPreview = 1
				else
					isPreview = 0
				end
				
				if isPreview == 1 then
					XiGuaDraw_Shop_ItemButton_Eyesign[i]:Show()
				else
					XiGuaDraw_Shop_ItemButton_Eyesign[i]:Hide()
				end
			end
		end
	end
	
	--累计领奖
	local costYBTips = nil
	local kajiType = KaJi:LuaFnGetKaJiType(137)
	if Player:GetData("IsOriginalJD") == 1 then
		costYBTips = g_costYBTips_KJ
	else
		if kajiType == 1 then
			costYBTips = g_costYBTips_KJ
		else
			costYBTips = g_costYBTips
		end		
	end
	for i = 1, 6 do
		XiGuaDraw_Shop_RewardButton_Text[i]:SetText(ScriptGlobal_Format("#{XGJSD_230526_43}", g_NeedCostYB[i]))
		if g_XiGuaShopTotalFlag[i] == 0 then --未领取
			XiGuaDraw_Shop_RewardButton_Btn[i]:Enable()
			XiGuaDraw_Shop_RewardButton_Btn[i]:SetToolTip(costYBTips[i])
			XiGuaDraw_Shop_RewardButton_Get[i]:Hide()
			if g_nTotalYBCost >= g_NeedCostYB[i] then --可领取
				XiGuaDraw_Shop_RewardButton_Tips[i]:Show()
			else
				XiGuaDraw_Shop_RewardButton_Tips[i]:Hide()
			end
		else --已领取
			XiGuaDraw_Shop_RewardButton_Btn[i]:Disable()
			XiGuaDraw_Shop_RewardButton_Get[i]:Show()
			XiGuaDraw_Shop_RewardButton_Tips[i]:Hide()
		end
	end
	
	this:Show()
end 

function XiGuaDraw_Shop_Hide()
	this:Hide()
end

function XiGuaDraw_Shop_Close()
	if ( IsWindowShow( "XiGuaDraw_Shop_Award" ) ) then
		CloseWindow( "XiGuaDraw_Shop_Award", true );
	end 
	
	XiGuaDraw_Shop_Hide()
end

function XiGuaDraw_Shop_BoxPreview()
	PushEvent("XIGUADRAW_SHOP_PREVIEW")
end

function XiGuaDraw_Shop_Description_Help()
	PushEvent("CCSHOP_HELP", 196)
end 

--购买
function XiGuaDraw_Shop_Item_Click(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("BuyItem")
		Set_XSCRIPT_ScriptID(998574)
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_Parameter(1, 1)			
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end 

--刷新确认
function XiGuaDraw_Shop_Check_Click()
	local bConfirm = tonumber(NpcShop:GetXiGuaShopDirectly())
	if ( bConfirm == 1 ) then
		XiGuaDraw_Shop_Shuaxin_Bind:SetCheck( 1 );
		NpcShop:SetXiGuaShopDirectly( 0 );
	elseif ( bConfirm == 0 ) then
		XiGuaDraw_Shop_Shuaxin_Bind:SetCheck( 0 );
		NpcShop:SetXiGuaShopDirectly( 1 );
	end
end
--刷新
function XiGuaDraw_Shop_But_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoRefreshOnce")
		Set_XSCRIPT_ScriptID(998574)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end 

function XiGuaDraw_Shop_ProgressIcon_Click(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetTotalCostReward")
		Set_XSCRIPT_ScriptID(998574)
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

-- 打开时装预览界面
function XiGuaDraw_Shop_OpenDressPreview(index)
	if index < 1 or index > 8 then
		return
	end
	if g_XiGuaShopRoundItemIndex ~= nil then
		local ItemIndex = g_XiGuaShopRoundItemIndex[index]
		local nShowItemId,nType,nItemNum,nIsBind,nPrize,nDisCount,nQuality = DataPool:LuaFnGet2023XiGuaShopInfo(ItemIndex)
		if nShowItemId ~= nil and nShowItemId > 0 then
			if nShowItemId == 38008644 then
				Clear_XSCRIPT()
					Set_XSCRIPT_ScriptID(888051)
					Set_XSCRIPT_Function_Name("DressPreview")
					Set_XSCRIPT_Parameter(0, 10128760)
					Set_XSCRIPT_Parameter(1, 297)
					Set_XSCRIPT_Parameter(2, 215)
					Set_XSCRIPT_ParamCount(3)
				Send_XSCRIPT()			
			elseif nShowItemId == 38008053 then
				Clear_XSCRIPT()
					Set_XSCRIPT_ScriptID(888051)
					Set_XSCRIPT_Function_Name("DressPreview")
					Set_XSCRIPT_Parameter(0, 10128311)
					Set_XSCRIPT_Parameter(1, 265)
					Set_XSCRIPT_Parameter(2, 195)
					Set_XSCRIPT_ParamCount(3)
				Send_XSCRIPT()			
			end
		end
	end
end

--礼盒预览
function XiGuaDraw_Shop_Progress_Icon4_Rewards_Clicked()
	PushEvent("OPEN_GEMEFFECTPREVIEW", 50231020, 0)
end
-- 时装礼盒预览
function XiGuaDraw_Shop_Progress_Icon5_Rewards_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, 10128784)
		Set_XSCRIPT_Parameter(1, 298)
		Set_XSCRIPT_Parameter(2, 215)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--图鉴
function XiGuaDraw_Shop_Progress_Icon6_Rewards_Clicked()
	Pet:AnniversaryOpenPetJian( 36939 );
end
