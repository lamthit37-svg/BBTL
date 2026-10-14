--SVIP生日礼盒
--时装礼盒界面
--二选一

--选择idex
local m_ItemIndexSel = 0

local m_ItemBagePos = -1

--界面位置
local g_UnifiedPosition = ""

--控件控制
local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}

--奖励列表
local g_LiHeId = 38005655
local g_PrizeItem = {	10124643, 10126636}

function SVIPItemGift_YiFu_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
		
end

function SVIPItemGift_YiFu_OnLoad()

	g_UnifiedPosition = SVIPGift_YiFu_Frame:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = SVIPGift_YiFu_Page_Lace1Item
	g_ActionItem[2] = SVIPGift_YiFu_Page_Lace2Item
	
	g_ActionMask[1] = SVIPGift_YiFu_Page_Lace1Item_Mask
	g_ActionMask[2] = SVIPGift_YiFu_Page_Lace2Item_Mask
	
	g_ItemNameText[1] = SVIPGift_YiFu_Page_Lace1Item_Tip
	g_ItemNameText[2] = SVIPGift_YiFu_Page_Lace2Item_Tip
	
end										

function SVIPItemGift_YiFu_OnEvent(event)

	--界面打开
	if event == "UI_COMMAND" and tonumber(arg0) == 88888001 then		

		SVIPItemGift_YiFu_CleanUp()
		m_ItemBagePos = Get_XParam_INT(0)
		m_ItemIndexSel = 0

		LifeAbility:Lock_Packet_Item(m_ItemBagePos,1)

		this:Show()
		SVIPItemGift_YiFu_Update()
		return
		
	end

	--界面关闭
	if event == "UI_COMMAND" and tonumber(arg0) == 88888002 then		
		SVIPItemGift_YiFu_CleanUp()	
		this:Hide()
		return
		
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		SVIPItemGift_YiFu_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		SVIPItemGift_YiFu_CleanUp()	
		this:Hide()
		return
	end
	
	
	
end

function SVIPItemGift_YiFu_CleanUp()	
	
	for i = 1, 2 do	
		g_ActionItem[i]:SetActionItem(-1)
		g_ItemNameText[i]:SetText("")
		g_ActionMask[i]:Hide()
	end
	
	if m_ItemBagePos >= 0 then
		LifeAbility:Lock_Packet_Item(m_ItemBagePos,0)
	end
	
	m_ItemBagePos = -1
	m_ItemIndexSel = 0
	
end

function SVIPItemGift_YiFu_Update()

	if m_ItemBagePos < 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(m_ItemBagePos)	
	if item_table_index == nil or item_table_index ~= g_LiHeId then
		return
	end
	
	for i = 1, 2 do
		local itemAction = DataPool:CreateActionItemForShow(g_PrizeItem[i], 1)
		if itemAction:GetID() ~= 0 then
			g_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		local strName = DataPool:Lua_GetItemNameByIndex(g_PrizeItem[i])
		g_ItemNameText[i]:SetText(ScriptGlobal_Format("#{SVIP_212114_10}",strName))
		
	end
	
end

function SVIPGift_YiFu_OnHidden()
	SVIPItemGift_YiFu_CleanUp()	
	this:Hide()
end

function SVIPItemGift_YiFu_OnActionItemClicked(index)

	if m_ItemIndexSel == index then
		return
	end
	
	m_ItemIndexSel = index
	
	for i = 1, 2 do	
		g_ActionItem[i]:SetPushed(0)
		g_ActionMask[i]:Hide()
	end
	g_ActionItem[m_ItemIndexSel]:SetPushed(1)
	g_ActionMask[m_ItemIndexSel]:Show()
	
	
end

function SVIPItemGift_YiFu_CloseClicked()
	SVIPItemGift_YiFu_CleanUp()	
	this:Hide()
end


function SVIPItemGift_YiFu_OKClicked()
	
	if m_ItemBagePos < 0 then
		return
	end
	
	if m_ItemIndexSel <= 0 then
		PushDebugMessage("#{SVIP_212114_11}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PickOne")
		Set_XSCRIPT_ScriptID(888880)
		Set_XSCRIPT_Parameter(0, m_ItemBagePos)
		Set_XSCRIPT_Parameter(1, m_ItemIndexSel)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
	this:Hide()
		
end

function SVIPItemGift_YiFu_Frame_On_ResetPos()
	if g_UnifiedPosition ~= nil then
		SVIPGift_YiFu_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition)
	end
end