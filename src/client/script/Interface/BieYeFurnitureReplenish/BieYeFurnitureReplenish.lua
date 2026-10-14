local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_CurrentPage = 1
local m_ActionButton
local m_EquipBagIndex
local m_Item = 0
local   g_DescriptionOuter= {
						[1] = "庭院桌",
						[2] = "庭院凳",
						[3] = "喷泉",
						[4] = "影壁",
						[5] = "风灯",
						[6] = "鼎",
						[7] = "奇石",
						[8] = "树木",
						[9] = "植栽",
						[10] = "玩物",
						[11] = "栏杆",				
						[12] = "花草",		
						[13] = "奇珍",											
																}
local  g_DescriptionInner= {
						[1] = "床帐",
						[2] = "居室桌",
						[3] = "条案",
						[4] = "茶几",
						[5] = "椅",
						[6] = "居室凳",
						[7] = "柜架",
						[8] = "屏风",
						[9] = "灯烛",
						[10] = "装饰",
						[11] = "隔断",
						[12] = "地毯",
						[13] = "瑰宝",
																	
																}
function BieYeFurnitureReplenish_PreLoad()

	this:RegisterEvent("SCENE_DATA_READY")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)


	this:RegisterEvent("FURNITURE_TEMP_OPEN")

	this:RegisterEvent("FURNITURE_TEMP_UPDATE")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("UPDATE_BIEYEFURNITURE_LIST")
	this:RegisterEvent("UPDATE_BUHUO_EQUIPINDEX")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")
end

function BieYeFurnitureReplenish_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BieYeFurnitureReplenish_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BieYeFurnitureReplenish_Frame:GetProperty("UnifiedYPosition");
	
	m_ActionButton = BieYeFurnitureReplenish_Item
	m_EquipBagIndex = -1
end



function BieYeFurnitureReplenish_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BieYeFurnitureReplenish_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BieYeFurnitureReplenish_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif( event == "SCENE_DATA_READY" ) then
		--if ( BieYeFurniture:IsBieYeScene() ) then
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20160620 then
		local nType = Get_XParam_INT(0)
		
		if nType == 30 then --打开界面
			BieYeFurnitureReplenish_Close()
		end
		this:Hide()
	elseif( event == "RESUME_ENCHASE_GEM_EX" )  and this:IsVisible() then
			if arg0 then
				if tonumber(arg0) == 0 then
					BieYeFurnitureReplenish_CleanUp()
				end
			end
			

	elseif( event == "FURNITURE_TEMP_OPEN" ) then

		if( this:IsVisible() ) then
			return
		else
			g_CurrentPage = tonumber(arg0)
			BieYeFurnitureReplenish_FreshDescText(0)

			BieYeFurnitureReplenish_FreshButton(0)

			
			this:Show()
		end
	elseif( event == "FURNITURE_TEMP_UPDATE"  and this:IsVisible() ) then

		if arg0 ~= nil then
			BieYeFurnitureReplenish_FreshDescText(0)
			BieYeFurnitureReplenish_UpdateFame(tonumber(arg0) )
			BieYeFurnitureReplenish_FreshButton()
		end
	elseif( event == "UPDATE_BIEYEFURNITURE_LIST"  and this:IsVisible() ) then
			BieYeFurnitureReplenish_FreshButton()
	elseif( event == "UPDATE_BUHUO_EQUIPINDEX"  and this:IsVisible() ) then
			g_CurrentPage = tonumber(arg0)
	end		
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYeFurnitureReplenish_ResetPos()
	BieYeFurnitureReplenish_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BieYeFurnitureReplenish_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BieYeFurnitureReplenish_UpdateFame(index)

	if index ~= -1 then
		BieYeFurnitureReplenish_CleanUp()	
	end

	
	if index >= 0 then
		m_EquipBagIndex = index
		local theAction = EnumAction(m_EquipBagIndex, "packageitem")
		if theAction:GetID() == 0 then
			
			BieYeFurnitureReplenish_CleanUp()
			return
			
		end
		m_ActionButton:SetActionItem(theAction:GetID())
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,1)
	end

end
--Window清空
function BieYeFurnitureReplenish_CleanUp()

	m_ActionButton:SetActionItem(-1)
		--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
		BieYeFurnitureReplenish_FreshDescText(0)
	end
	m_EquipBagIndex = -1
	BieYeFurnitureReplenish_FreshButton()
	
end
--Window清空
function BieYeFurnitureReplenish_Close()
	
	BieYeFurnitureReplenish_CleanUp()
	this:Hide()

end

--点击"X"
function BieYeFurnitureReplenish_OnCloseClicked()

	BieYeFurnitureReplenish_CleanUp()
	this:Hide()
	
end

function BieYeFurnitureReplenish_OnHiden()

	BieYeFurnitureReplenish_CleanUp()
	
end
function BieYeFurnitureReplenish_BuyEvent()

	if m_EquipBagIndex == -1 then
		return
	end
	
	--0是院子  1是居室
	local bIsInner = BieYeFurniture:GetCurInner() 
	local tmpItem = BieYeFurnitureReplenish_Item:GetActionItem();

	BieYeFurnitureReplenish_FreshButton()

	BieYeFurniture:BuyBieYeFurniture(bIsInner,m_EquipBagIndex);

end


function BieYeFurnitureReplenish_FreshButton()
	local tmpItem = BieYeFurnitureReplenish_Item:GetActionItem();
	if tmpItem > 0 then
		BieYeFurnitureReplenish_Buy:SetProperty("Disabled", "False");
	else
		BieYeFurnitureReplenish_Buy:SetProperty("Disabled", "True");
		
	end
	
	if m_EquipBagIndex >= 0 then 
		local theAction = EnumAction(m_EquipBagIndex, "packageitem")
		if theAction:GetID() == 0 then
			BieYeFurnitureReplenish_CleanUp()
			return
		end
		local nNum = theAction:GetNum();
		local nCount = BieYeFurniture:GetBieYeFurnitureTypeCount()
		local nCountLimit = BieYeFurniture:GetBieYeFurnitureLimitByBieYeLevel()	
		local nResultCount = nNum + nCount

		local bChecknTypeEqualCurType = true;
		m_Item = PlayerPackage : GetItemTableIndex( m_EquipBagIndex ) 
		if m_Item > 0 then
			local nType,nLevel = BieYeUI:GetFurnitureTypeByItemID(tonumber(m_Item))
			if nType > 0 then
				local nCurType = BieYeFurniture:GetBieYeFurnitureType(m_Item)
				if nType ~=  nCurType then
					bChecknTypeEqualCurType = false
				end
			end
		end		

		if nResultCount > nCountLimit then
			if bChecknTypeEqualCurType == true then
				--BieYeFurnitureReplenish_Buy:SetProperty("Disabled", "True");	
			
				--BieYeFurnitureReplenish_FreshDescText(1)		
			end
		else

				--BieYeFurnitureReplenish_Buy:SetProperty("Disabled", "False");
				--BieYeFurnitureReplenish_FreshDescText(0)	

		end

	end
	
	


end

function BieYeFurnitureReplenish_FreshDescText(Index)
	--0是院子  1是居室

	local bIsInner = BieYeFurniture:GetCurInner() 

	local nCount = BieYeFurniture:GetBieYeFurnitureTypeCount()
	local nCountLimit = BieYeFurniture:GetBieYeFurnitureLimitByBieYeLevel()

	if Index == 1 then 

		if bIsInner == 1 then
			local strCount = ScriptGlobal_Format("#{BYFUR_160531_111}", nCountLimit)
			local strCount1 = ScriptGlobal_Format("#{BYFUR_160531_236}",g_DescriptionInner[g_CurrentPage],nCount,nCountLimit - nCount)				
			local strCount2 = ScriptGlobal_Format("#{BYFUR_160531_237}",g_DescriptionInner[g_CurrentPage])				
			local str = strCount.."#{BYFUR_160531_238}"	
			BieYeFurnitureReplenish_Explain_Text:SetText(str)
			BieYeFurnitureReplenish_Item:SetToolTip("#{BYFUR_160531_113}")
			BieYeFurnitureReplenish_DragTitle:SetText("#{BFYH_170209_31}")
			BieYeFurnitureReplenish_Item_Text:SetText("#{BFYH_170209_33}")
			BieYeFurnitureReplenish_Item_Text1:SetText(strCount2)
		else
			local strCount = ScriptGlobal_Format("#{BYFUR_160531_98}", nCountLimit)
			local strCount1 = ScriptGlobal_Format("#{BYFUR_160531_233}",g_DescriptionOuter[g_CurrentPage],nCount,nCountLimit - nCount)				
			local strCount2 = ScriptGlobal_Format("#{BYFUR_160531_234}",g_DescriptionOuter[g_CurrentPage])				
			local str = strCount.."#{BYFUR_160531_235}"	
			BieYeFurnitureReplenish_Explain_Text:SetText(str)
			BieYeFurnitureReplenish_Item:SetToolTip("#{BYFUR_160531_100}")
			BieYeFurnitureReplenish_DragTitle:SetText("#{BFYH_170209_31}")
			BieYeFurnitureReplenish_Item_Text:SetText("#{BFYH_170209_33}")
			BieYeFurnitureReplenish_Item_Text1:SetText(strCount2)
		end

		BieYeFurnitureReplenish_Item_Text1:SetProperty("Visible", "True");
	else
		
		if bIsInner == 1 then
			local strCount = ScriptGlobal_Format("#{BYFUR_160531_111}", nCountLimit)
			local strCount1 = ScriptGlobal_Format("#{BYFUR_160531_236}",g_DescriptionInner[g_CurrentPage],nCount,nCountLimit - nCount)				
			local strCount2 = ScriptGlobal_Format("#{BYFUR_160531_237}",g_DescriptionInner[g_CurrentPage])				
			local str = strCount.."#{BYFUR_160531_238}"	
			--BieYeFurnitureReplenish_Explain_Text:SetText(str)
			BieYeFurnitureReplenish_Explain_Text:SetText("#{BFYH_170209_32}")
			BieYeFurnitureReplenish_Item:SetToolTip("#{BYFUR_160531_113}")
			BieYeFurnitureReplenish_DragTitle:SetText("#{BFYH_170209_31}")
			BieYeFurnitureReplenish_Item_Text:SetText("#{BFYH_170209_33}")
		else
			local strCount = ScriptGlobal_Format("#{BYFUR_160531_98}", nCountLimit)
			local strCount1 = ScriptGlobal_Format("#{BYFUR_160531_233}",g_DescriptionOuter[g_CurrentPage],nCount,nCountLimit - nCount)				
			local strCount2 = ScriptGlobal_Format("#{BYFUR_160531_234}",g_DescriptionOuter[g_CurrentPage])				
			local str = strCount.."#{BYFUR_160531_235}"
			--BieYeFurnitureReplenish_Explain_Text:SetText(str)
			BieYeFurnitureReplenish_Explain_Text:SetText("#{BFYH_170209_32}")
			BieYeFurnitureReplenish_Item:SetToolTip("#{BYFUR_160531_100}")
			BieYeFurnitureReplenish_DragTitle:SetText("#{BFYH_170209_31}")
			BieYeFurnitureReplenish_Item_Text:SetText("#{BFYH_170209_33}")
		end		

		BieYeFurnitureReplenish_Item_Text1:SetProperty("Visible", "False");
		
	end
	


end
