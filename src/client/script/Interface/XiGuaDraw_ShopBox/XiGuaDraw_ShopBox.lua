-- XiGuaDraw_ShopBox

-- 保存UI默认位置
local XiGuaDraw_ShopBox_UnifiedPosition = nil

local g_CurPageType = -1

function XiGuaDraw_ShopBox_PreLoad()
    this:RegisterEvent("XIGUADRAW_SHOP_PREVIEW", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end

function XiGuaDraw_ShopBox_OnEvent(event)
    if (event == "XIGUADRAW_SHOP_PREVIEW") then
        -- 开启UI
		g_CurPageType = 1
        XiGuaDraw_ShopBox_Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		XiGuaDraw_ShopBox_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XiGuaDraw_ShopBox_On_ResetPos()
	elseif (event == "ADJEST_UI_POS") then
		XiGuaDraw_ShopBox_On_ResetPos()
	end
end

function XiGuaDraw_ShopBox_OnLoad()
	XiGuaDraw_ShopBox_UnifiedPosition = XiGuaDraw_ShopBox_FrameNULL:GetProperty("UnifiedPosition")
end

-- 界面默认位置
function XiGuaDraw_ShopBox_On_ResetPos()
	if (XiGuaDraw_ShopBox_UnifiedPosition ~= nil) then
		XiGuaDraw_ShopBox_FrameNULL:SetProperty("UnifiedPosition", XiGuaDraw_ShopBox_UnifiedPosition)
	end
end

-- 开启UI
function XiGuaDraw_ShopBox_Show()
	XiGuaDraw_ShopBox_UpdatePreview()
	this:Show()
end 

-- 关闭UI
function XiGuaDraw_ShopBox_Hide()
	this:Hide()
end

-- 关闭按钮事件
function XiGuaDraw_ShopBox_Close()
	XiGuaDraw_ShopBox_Hide()
end

--点页签
function XiGuaDraw_ShopBox_CheckClick(index)
	if index == nil then
		return
	end
	
	if index < 1 or index > 3 then
		return
	end

	g_CurPageType = index
	XiGuaDraw_ShopBox_UpdatePreview()
end 

-- 更新预览物品
function XiGuaDraw_ShopBox_UpdatePreview()
	if g_CurPageType < 1 or g_CurPageType > 3 then
		return
	end

	if (g_CurPageType == 1) then
		XiGuaDraw_ShopBox_CheckBtn1:SetCheck(1)
		XiGuaDraw_ShopBox_CheckBtn2:SetCheck(0)
		XiGuaDraw_ShopBox_CheckBtn3:SetCheck(0)
	elseif (g_CurPageType == 2) then
		XiGuaDraw_ShopBox_CheckBtn1:SetCheck(0)
		XiGuaDraw_ShopBox_CheckBtn2:SetCheck(1)
		XiGuaDraw_ShopBox_CheckBtn3:SetCheck(0)
	elseif (g_CurPageType == 3) then
		XiGuaDraw_ShopBox_CheckBtn1:SetCheck(0)
		XiGuaDraw_ShopBox_CheckBtn2:SetCheck(0)
		XiGuaDraw_ShopBox_CheckBtn3:SetCheck(1)
	end
	
	XiGuaDraw_ShopBox_SuperList:Clear()
	
	local count = DataPool:LuaFnGet2023XiGuaShopInfoCount()
	if count <= 0 then
		return
	end
	
	for i=1, count do
		local nShowItemId,nType,nItemNum,nIsBind,nPrize,nDisCount = DataPool:LuaFnGet2023XiGuaShopInfo(i)
		
		if (nShowItemId ~= nil and nShowItemId > 0 and nType == g_CurPageType) then
			local itemCtrl = XiGuaDraw_ShopBox_SuperList:AddChild("XiGuaDraw_ShopBox_CoinAItem1")
			if (itemCtrl ~= nil) then
				--道具图标
				
				if nIsBind == 1 then
					local theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
					itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem"):SetActionItem(theAction:GetID())
					itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem_Feibang"):Hide()
				else
					local theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
					itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem"):SetActionItem(theAction:GetID())
					itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem_Feibang"):Show()
				end
				-- 设置道具名称
				itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem_Acount"):SetText("#L" .. DataPool:Lua_GetItemNameByIndex(nShowItemId))
				-- 设置物品价格
				local priceText = ScriptGlobal_Format("#{XGJSD_231027_06}", nPrize)
				itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem_Price"):SetText("#{XGJSD_231027_05}"..priceText)
				-- 设置折扣率
				if (nDisCount > 0) then
					itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem_DiscountBK"):Show()
					itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem_DiscountText"):Show()
					local intPart = math.floor(nDisCount)
					local floatPart = math.mod(math.floor(nDisCount*10),10)
					local discountText = ""
					if floatPart == 0 then
						discountText = ScriptGlobal_Format("#{XGJSD_230526_19}", tostring(intPart))						
					else
						discountText = ScriptGlobal_Format("#{XGJSD_230526_19}", tostring(intPart).."."..tostring(floatPart))
					end
					itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem_DiscountText"):SetText(discountText)
				else
					itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem_DiscountBK"):Hide()
					itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem_DiscountText"):Hide()
				end
				if nShowItemId == 38006601 then
					itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem_EyeSign"):Show()
					itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem_EyeSign"):SetEvent("Clicked", "XiGuaDraw_ShopBox_Preview()")
				else
					itemCtrl:GetSubItem("XiGuaDraw_ShopBox_SuperListItem_EyeSign"):Hide()
				end
			end
		end
	end
end

-- 打开时装预览界面
function XiGuaDraw_ShopBox_Preview()

	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, 10127469)
		Set_XSCRIPT_Parameter(1, 212)
		Set_XSCRIPT_Parameter(2, 157)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end