local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_CurrentPage = 1
local m_ActionButton
local m_EquipBagIndex
local m_Item = 0

function BieYeCutePet_IN_PreLoad()

	this:RegisterEvent("SCENE_DATA_READY")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)


	this:RegisterEvent("MENGCHONG_BUHUO_UPDATE")

	this:RegisterEvent("MENGCHONG_BUHUO_OPEN")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("BIEYE_UPDATE_MENGCHONG_BANK")
	this:RegisterEvent("UPDATE_BUHUO_EQUIPINDEX")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")
end

function BieYeCutePet_IN_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BieYeCutePet_IN_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BieYeCutePet_IN_Frame:GetProperty("UnifiedYPosition");
	
	m_ActionButton = BieYeCutePet_IN_Item
	m_EquipBagIndex = -1
end



function BieYeCutePet_IN_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BieYeCutePet_IN_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BieYeCutePet_IN_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif( event == "SCENE_DATA_READY" ) then
		--if ( BieYeFurniture:IsBieYeScene() ) then

	elseif( event == "RESUME_ENCHASE_GEM_EX" )  and this:IsVisible() then
			if arg0 then
				if tonumber(arg0) == 1 then
					BieYeCutePet_IN_CleanUp()
				end
			end
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20160620 then

		local nType = tonumber(Get_XParam_INT(0))

		if nType == 30 then --打开界面
			BieYeFurnitureBank_OnHiden()
		end			

	elseif( event == "MENGCHONG_BUHUO_OPEN" ) then
		if( this:IsVisible() ) then
			return
		else
			BieYeCutePet_IN_FreshDescText(0)

			BieYeCutePet_IN_FreshButton()

			this:Show()
		end
	elseif( event == "MENGCHONG_BUHUO_UPDATE"  and this:IsVisible() ) then

		if arg0 ~= nil then

			BieYeCutePet_IN_FreshDescText(0)
			BieYeCutePet_IN_UpdateFame(tonumber(arg0) )
			BieYeCutePet_IN_FreshButton()
		end
	elseif( event == "BIEYE_UPDATE_MENGCHONG_BANK"  and this:IsVisible() ) then
			if arg0 then
				if tonumber(arg0) ~= 1 then
					BieYeCutePet_IN_FreshButton()
				end
			end
	elseif( event == "UPDATE_BUHUO_EQUIPINDEX"  and this:IsVisible() ) then
			g_CurrentPage = tonumber(arg0)
	
	end		
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYeCutePet_IN_ResetPos()
	BieYeCutePet_IN_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BieYeCutePet_IN_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BieYeCutePet_IN_UpdateFame(index)

	BieYeCutePet_IN_CleanUp()
	
	if index >= 0 then
		m_EquipBagIndex = index
		local theAction = EnumAction(m_EquipBagIndex, "packageitem")
		if theAction:GetID() == 0 then
			
			BieYeCutePet_IN_CleanUp()
			return
			
		end
		m_ActionButton:SetActionItem(theAction:GetID())
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,1)
	end

end
--Window清空
function BieYeCutePet_IN_CleanUp()

	m_ActionButton:SetActionItem(-1)
		--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
		BieYeCutePet_IN_FreshDescText(0)
	end
	m_EquipBagIndex = -1
	BieYeCutePet_IN_FreshButton()
	
end
--Window清空
function BieYeCutePet_IN_Close()
	
	BieYeCutePet_IN_CleanUp()
	this:Hide()

end

--点击"X"
function BieYeCutePet_IN_OnCloseClicked()

	BieYeCutePet_IN_CleanUp()
	this:Hide()
	
end

function BieYeCutePet_IN_OnHiden()

	BieYeCutePet_IN_CleanUp()
	
end
function BieYeCutePet_IN_BuyEvent()

	if m_EquipBagIndex == -1 then
		return
	end
	
	--0是院子  1是居室
	local tmpItem = BieYeCutePet_IN_Item:GetActionItem();

	BieYeCutePet_IN_FreshButton()
	if m_EquipBagIndex == -1 then
		return
	end
	BieYeMengChong:BuyBieYeMengChong(m_EquipBagIndex);

end


function BieYeCutePet_IN_FreshButton()
	local tmpItem = BieYeCutePet_IN_Item:GetActionItem();
	if tmpItem > 0 then
		BieYeCutePet_IN_Buy:SetProperty("Disabled", "False");
	else
		BieYeCutePet_IN_Buy:SetProperty("Disabled", "True");
		
	end
	
	if m_EquipBagIndex >= 0 then 
		local theAction = EnumAction(m_EquipBagIndex, "packageitem")
		if theAction:GetID() == 0 then
			BieYeCutePet_IN_CleanUp()
			return
		end
		local nNum = theAction:GetNum();
		m_Item = PlayerPackage : GetItemTableIndex( m_EquipBagIndex ) 
		local WuZhong = BieYeMengChong:GetBieYeMengChongInfo(m_Item,5)
		local nCount =  BieYeMengChong:GetBieYeMengChongTypeSize(WuZhong)
		local nCountLimit = BieYeMengChong:GetBieYeMengChongLimitByBieYeLevel()
		local nResultCount = nNum + nCount


		if nResultCount > nCountLimit then
				BieYeCutePet_IN_Buy:SetProperty("Disabled", "True");	
				BieYeCutePet_IN_FreshDescText(1)		
		else
				BieYeCutePet_IN_Buy:SetProperty("Disabled", "False");
				BieYeCutePet_IN_FreshDescText(0)	

		end
	end
	
	


end

function BieYeCutePet_IN_FreshDescText(Index)
	if Index == 1 then 
		m_Item = PlayerPackage : GetItemTableIndex( m_EquipBagIndex ) 
		local WuZhong = BieYeMengChong:GetBieYeMengChongInfo(m_Item,5)
		local nCount =  BieYeMengChong:GetBieYeMengChongTypeSize(WuZhong)
		local nCountLimit = BieYeMengChong:GetBieYeMengChongLimitByBieYeLevel()

		PushDebugMessage("#{MCJC_170727_117}")
	end
end

