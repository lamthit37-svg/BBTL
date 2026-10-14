local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

local g_NpcId = -1
local g_CheckType = -1
local g_GoodsIndex = -1
local g_MaxNum = 1

local g_itemIndex = {[1] = 38005316,
						[2] = 38005317}


function Miji_Shop_Mbuy_PreLoad()
	this:RegisterEvent("CANYESHOP_OPENMUTLBUY")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--离开场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Miji_Shop_Mbuy_OnLoad()
	g_Frame_UnifiedXPosition	= Miji_Shop_MBuy_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= Miji_Shop_MBuy_Frame:GetProperty("UnifiedYPosition")
end

function Miji_Shop_Mbuy_OnEvent(event)
	if (event == "CANYESHOP_OPENMUTLBUY") then
		g_CheckType = tonumber(arg0)
		g_GoodsIndex = tonumber(arg1)
		g_NpcId = tonumber(arg2)
		this:CareObject( g_NpcId, 1, "Miji_Shop_Mbuy" )
		Miji_Shop_Mbuy_OnOpen()
		this:Show()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Miji_Shop_Mbuy_OnClose()
		
	elseif (event == "ADJEST_UI_POS") then
		Miji_Shop_Mbuy_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Miji_Shop_Mbuy_ResetPos()

	elseif event == "PACKAGE_ITEM_CHANGED_EX" then
		local nItemCount = PlayerPackage:Lua_GetUnLockItemCount(g_itemIndex[g_CheckType])
		if nItemCount >= 50 then
			g_MaxNum = 50
		elseif nItemCount == 0 then
			g_MaxNum = 1
		else
			g_MaxNum = nItemCount
		end
		Miji_Shop_Mbuy_TextChanged()
	end
end

function Miji_Shop_Mbuy_ResetPos()
	Miji_Shop_MBuy_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Miji_Shop_MBuy_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Miji_Shop_Mbuy_OnHidden()
	this:CareObject( g_NpcId, 0, "Miji_Shop_Mbuy" )
	Miji_Shop_MBuy_InputNum:SetProperty("DefaultEditBox", "False");
end

function Miji_Shop_Mbuy_OnOpen()
	local nItemId, nItemShowId, nNeedItemId, nNeedItemNum, szItemName, szNeedItemName = DataPool:LuaFnGetCanYeShopGoodsInfo( g_CheckType, g_GoodsIndex-1)
	if nItemId == -1 then
		return
	end
	
	local theAction = DataPool:CreateBindActionItemForShow(nItemShowId, 1)
	if theAction:GetID() == 0 then
		return
	end
	
	
	Miji_Shop_MBuy_But:SetActionItem(theAction:GetID())
	Miji_Shop_MBuy_ItemInfo_Text:SetText("#cfff263"..szItemName)
	local nItemCount = PlayerPackage:Lua_GetUnLockItemCount(g_itemIndex[g_CheckType])
	Miji_Shop_MBuy_ItemInfo_Lilianzhi:SetText(ScriptGlobal_Format("#{MJDH_210511_20}", szNeedItemName, nNeedItemNum))
	
	Miji_Shop_MBuy_Price:SetText(ScriptGlobal_Format("#{MJDH_210511_23}", szNeedItemName))
	Miji_Shop_MBuy_Price_Lilianzhi:SetText(ScriptGlobal_Format("#{MJDH_210511_24}", nNeedItemNum))
	Miji_Shop_MBuy_Cash:SetText(ScriptGlobal_Format("#{MJDH_210511_25}", szNeedItemName))
	if nItemCount >= nNeedItemNum then
		Miji_Shop_MBuy_Cash_Lilianzhi:SetText(ScriptGlobal_Format("#{MJDH_210511_27}", nItemCount))
	else
		Miji_Shop_MBuy_Cash_Lilianzhi:SetText(ScriptGlobal_Format("#{MJDH_210511_26}", nItemCount))
	end


	if nItemCount >= 50 then
		g_MaxNum = 50
	elseif nItemCount == 0 then
		g_MaxNum = 1
	else
		g_MaxNum = nItemCount
	end
	Miji_Shop_MBuy_InputNum:SetProperty("DefaultEditBox", "True");
	Miji_Shop_MBuy_InputNum:SetText(tostring(1))
	Miji_Shop_MBuy_InputNum:SetSelected( 0, -1 );
end

function Miji_Shop_Mbuy_TextChanged()

	if g_GoodsIndex == -1 then
		return
	end
	
	local num = tonumber(Miji_Shop_MBuy_InputNum:GetText())
	if num == nil then
		local nItemId, nItemShowId, nNeedItemId, nNeedItemNum, szItemName, szNeedItemName = DataPool:LuaFnGetCanYeShopGoodsInfo( g_CheckType, g_GoodsIndex-1)
		if nItemId == -1 then
			return
		end
		
		local totalNum = 0 * nNeedItemNum
		Miji_Shop_MBuy_Price_Lilianzhi:SetText(ScriptGlobal_Format("#{MJDH_210511_24}", totalNum))
		local nItemCount = PlayerPackage:Lua_GetUnLockItemCount(g_itemIndex[g_CheckType])
		if nItemCount >= totalNum then
			Miji_Shop_MBuy_Cash_Lilianzhi:SetText(ScriptGlobal_Format("#{MJDH_210511_27}", nItemCount))
		else
			Miji_Shop_MBuy_Cash_Lilianzhi:SetText(ScriptGlobal_Format("#{MJDH_210511_26}", nItemCount))
		end
		return
	end
	
	if num > g_MaxNum then
		Miji_Shop_MBuy_InputNum:SetText(tostring(g_MaxNum))
		
	elseif num < 1 then
		Miji_Shop_MBuy_InputNum:SetText("1")
		
	else
		local nItemId, nItemShowId, nNeedItemId, nNeedItemNum, szItemName, szNeedItemName = DataPool:LuaFnGetCanYeShopGoodsInfo( g_CheckType, g_GoodsIndex-1)
		if nItemId == -1 then
			return
		end
		
		local totalNum = num * nNeedItemNum
		Miji_Shop_MBuy_Price_Lilianzhi:SetText(ScriptGlobal_Format("#{MJDH_210511_24}", totalNum))
		local nItemCount = PlayerPackage:Lua_GetUnLockItemCount(g_itemIndex[g_CheckType])
		if nItemCount >= totalNum then
			Miji_Shop_MBuy_Cash_Lilianzhi:SetText(ScriptGlobal_Format("#{MJDH_210511_27}", nItemCount))
		else
			Miji_Shop_MBuy_Cash_Lilianzhi:SetText(ScriptGlobal_Format("#{MJDH_210511_26}", nItemCount))
		end
		
	end
end

function Miji_Shop_Mbuy_OnMax()
	Miji_Shop_MBuy_InputNum:SetText(tostring(g_MaxNum))
end

function Miji_Shop_Mbuy_OnClose()
	this:Hide()
end


function Miji_Shop_Mbuy_OnOK()
	local num = tonumber(Miji_Shop_MBuy_InputNum:GetText());
	if num == nil then
		PushDebugMessage("#{MJDH_210511_31}")
		this:Hide()
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnByItem" )
		Set_XSCRIPT_ScriptID(888435)
		Set_XSCRIPT_Parameter(0, g_CheckType) 
		Set_XSCRIPT_Parameter(1, g_GoodsIndex) 
		Set_XSCRIPT_Parameter(2, num) 
		Set_XSCRIPT_Parameter(3, 1) 
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
	this:Hide()
end