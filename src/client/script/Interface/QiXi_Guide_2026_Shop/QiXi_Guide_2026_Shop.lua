
local g_Frame_QiXi_UnifiedPosition
local g_QiXi_Guide_2026_Shop_listitem = {} 
local g_QiXi_Guide_2026_Shop_DaiBi = 0
local g_QiXi_Guide_2026_Shop_IsShow = 0

--=========
-- PreLoad()
--=========
function QiXi_Guide_2026_Shop_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("QIXI_GUIDE_SHOP")
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	this:RegisterEvent("ADJEST_UI_POS")
	
end

--=========
-- OnLoad()
--=========
function QiXi_Guide_2026_Shop_OnLoad()

	g_Frame_QiXi_UnifiedPosition = QiXi_Guide_2026_Shop_Frame:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function QiXi_Guide_2026_Shop_OnEvent(event)

	if event == "QIXI_GUIDE_SHOP" then

		g_QiXi_Guide_2026_Shop_IsShow = tonumber (arg0)
				
		g_QiXi_Guide_2026_Shop_DaiBi = tonumber (arg1)
		
		QiXi_Guide_2026_Shop_Update()
		
		if g_QiXi_Guide_2026_Shop_IsShow == 1 or g_QiXi_Guide_2026_Shop_IsShow == 2 then
			this:Show ()
		end
				
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89377701 ) then
	
		if this:IsVisible() and Get_XParam_INT(2) and Get_XParam_INT(2) > 0 then
			g_QiXi_Guide_2026_Shop_DaiBi = Get_XParam_INT(2)
			QiXi_Guide_2026_Shop_UpdateDaiBi()
		end
			
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		QiXi_Guide_2026_Shop_OnClose()
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		QiXi_Guide_2026_Shop_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
		QiXi_Guide_2026_Shop_On_ResetPos()
		
	end
end

-- 帮助按钮
function QiXi_Guide_2026_Shop_HelpClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenShopHelpUI")
		Set_XSCRIPT_ScriptID(893777)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
end

--=========
-- 重置
--=========
function QiXi_Guide_2026_Shop_On_ResetPos()

	QiXi_Guide_2026_Shop_Frame:SetProperty("UnifiedPosition", g_Frame_QiXi_UnifiedPosition)
	
end

--=========
-- 关闭
--=========
function QiXi_Guide_2026_Shop_OnClose()

	this:Hide()
	
end

-- 更新代币数量
function QiXi_Guide_2026_Shop_UpdateDaiBi()
	
	local strtip = ScriptGlobal_Format("#{QXZH_250528_87}", g_QiXi_Guide_2026_Shop_DaiBi)
	QiXi_Guide_2026_Shop_Currency:SetText( strtip )
	
	if g_QiXi_Guide_2026_Shop_IsShow >= 2 then
		QiXi_Guide_2026_Shop_CurrencyBuy:Show()
	else
		QiXi_Guide_2026_Shop_CurrencyBuy:Hide()
	end
	
end

--=========
-- 更新界面
--=========
function QiXi_Guide_2026_Shop_Update()

	local g_ShopTbl_info = DataPool:Lua_GetQiXiGuideShopTable()
	
	QiXi_Guide_2026_Shop_ItemList:Clear()  
	
	for i, one in ipairs (g_ShopTbl_info or {}) do
		
		local bCanShow = 0
		if Player : GetData("Is2606S") == 1 then
			if one.mShopId == 4 then
				bCanShow = 1			
			end
		elseif Player : GetData("IsOriginalJD") == 1 then
			if one.mShopId == 3 then
				bCanShow = 1
			end
		elseif KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(183) > 0 then
			if one.mShopId == 2 then
				bCanShow = 1
			end
		else
			if one.mShopId == 1 then
				bCanShow = 1
			end
		end
		
		if bCanShow == 1 then		
			local bar = QiXi_Guide_2026_Shop_ItemList:AddChild("QiXi_Guide_2026_Shop_ItemFrame")
			if not bar then
				break
			end
			
			-- 道具展示区域
			local mActionItem = DataPool:CreateBindActionItemForShow(one.mItemId, one.mItemNum)
			if mActionItem and mActionItem:GetID() ~= 0 then
				bar:GetSubItem ("QiXi_Guide_2026_Shop_Item"):SetActionItem(mActionItem:GetID())
				bar:GetSubItem("QiXi_Guide_2026_Shop_Item"):SetEvent("Clicked", string.format("QiXi_Guide_2026_Shop_BuyClicked(%d)", one.mId))
			end
			
			bar:GetSubItem("QiXi_Guide_2026_Shop_Item_Eye"):Hide() 
						
			-- 道具名
			local name = DataPool:Lua_GetItemNameByIndex(one.mItemId)
			local strname = "#L"..name
			bar:GetSubItem("QiXi_Guide_2026_Shop_ItemText"):SetText(strname)
					  
			bar:GetSubItem("QiXi_Guide_2026_Shop_ItemInfo_CostNum"):SetText(ScriptGlobal_Format("#{QXZH_250528_89}", one.mCost)) 
					
			local vis = true
			 
			bar:GetSubItem("QiXi_Guide_2026_Shop_Item_BuyLimitNumBK"):Hide()   
			bar:GetSubItem("QiXi_Guide_2026_Shop_ItemInfo_IconMark1"):Hide()   
			bar:GetSubItem("QiXi_Guide_2026_Shop_ItemInfo_IconMark2"):Hide()   
			bar:GetSubItem("QiXi_Guide_2026_Shop_ItemInfo_IconMark3"):Hide()
			if one.mLimitId >= 0 then
				local _1, limittype, _3, nummax = DataPool:lua_GetLimitShopConfOne(one.mLimitId)
				if nummax then
					local remain = nummax - one.mPurchased
					vis = remain > 0
					
					if remain > 0 then
						bar:GetSubItem("QiXi_Guide_2026_Shop_Item_BuyLimitNum"):SetText(tostring(remain))  
						bar:GetSubItem("QiXi_Guide_2026_Shop_Item_BuyLimitNumBK"):Show()  
					end
				else
					vis = true
				end  
				if limittype == 3 then
					bar:GetSubItem("QiXi_Guide_2026_Shop_ItemInfo_IconMark3"):Show()
				end
				if limittype == 2 then
					bar:GetSubItem("QiXi_Guide_2026_Shop_ItemInfo_IconMark2"):Show()
				end
				if limittype == 1 then
					bar:GetSubItem("QiXi_Guide_2026_Shop_ItemInfo_IconMark1"):Show()
				end
			else
				vis = true
			end
			
			-- 是否可以购买
			if vis then 
				bar:GetSubItem("QiXi_Guide_2026_Shop_Item_Mask"):Hide()  
			else
				bar:GetSubItem("QiXi_Guide_2026_Shop_Item_Mask"):Show()
			end

			g_QiXi_Guide_2026_Shop_listitem[i] = bar
		end
	end
	
	QiXi_Guide_2026_Shop_UpdateDaiBi()
	
end

-- 用 Update 关闭子界面
function QiXi_Guide_2026_Shop_Hidden()

	if(IsWindowShow("QiXi_Guide_2026_Shop_CurrencyBuy")) then
		CloseWindow("QiXi_Guide_2026_Shop_CurrencyBuy", true)
	end
	
	-- 用这个关闭 打开的二次确认界面
	--PushEvent ("OPEN_SHOP_CONFIRM", -1, -1)
	
end

function QiXi_Guide_2026_Shop_BuyClicked( idx )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnQiXiShopExchange")
		Set_XSCRIPT_ScriptID(893777)
        Set_XSCRIPT_Parameter(0, idx)
        Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
end

function QiXi_Guide_2026_Shop_CurrencyBuy_Clicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnQiXiShopOpenDaibiBuy")
		Set_XSCRIPT_ScriptID(893777)
        Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

function QiXi_Guide_2026_Shop_ReviewClicked( nItem )

end


