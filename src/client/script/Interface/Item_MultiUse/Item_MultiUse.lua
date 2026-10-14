--批量使用通用界面
--Author:XiongJiaCheng
--Time:2021-05-12
--注意：
--1.请在自己物品脚本中加入自己的回调函数xXXXXXX_MultiUseConfirm(sceneId, selfId, g_ItemID, defaultNum)
--2.调用此界面请传入3个参数g_ItemID,g_max,g_MultiIseUse_ScriptId
--g_ItemID:物品ID
--g_max：当前背包中g_ItemID最大数量
--g_MultiIseUse_ScriptId：g_ItemID的脚本号

--控件列表
local m_Controls = {} 				--控件列表
local g_Frame_UnifiedPosition
local g_MultiIseUse_ScriptId = -1
local g_nItemBagPos = -1

local g_ItemID = -1

local g_max = 1 --最大使用数量
local defaultNum = 1 --默认使用数量


function Item_MultiUse_PreLoad()

    this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("ADJEST_UI_POS",false)           -- 游戏窗口尺寸发生了变化
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		    -- 离开场景
    this:RegisterEvent("UPDATE_Item_MultiUse_NAME",false )

end

function Item_MultiUse_OnLoad()

    m_Controls = 
    {
		m_Frame = Item_MultiUse_Frame,
	}
    
    g_Frame_UnifiedPosition=m_Controls.m_Frame:GetProperty("UnifiedPosition")

end

function Item_MultiUse_OnEvent(event)

    if ( event == "UI_COMMAND" and tonumber(arg0) == 20210512 ) then
		g_ItemID = Get_XParam_INT(0) --批量使用物品ID
		g_max = Get_XParam_INT(1)	--可以使用最大数
		g_MultiIseUse_ScriptId = Get_XParam_INT(2) --脚本号
		g_nItemBagPos = Get_XParam_INT(3) -- 道具背包位置
		defaultNum = g_max --默认使用数量
		Item_MultiUse_InputNum:SetText(defaultNum)

		-- 增加界面互斥关闭逻辑MessageBox_Self
		if(IsWindowShow("MessageBox_Self")) then
			CloseWindow("MessageBox_Self", true)
		end
		
		Item_MultiUse_Open(g_ItemID, 1, g_max)

    elseif (event == "ADJEST_UI_POS") then
		Item_MultiUse_Frame_On_ResetPos()    
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
        Item_MultiUse_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        Item_MultiUse_Close_Clicked()
    end
    
end

--===============================================
-- ResetPos()
--===============================================
function Item_MultiUse_Frame_On_ResetPos()
    m_Controls.m_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--===============================================
-- Show()
--===============================================
function Item_MultiUse_Open(g_ItemID, g_ItemCount, g_max)

	local theAction1 = DataPool:CreateActionItemForShow(g_ItemID, 1)
	local g_ActionItemID = theAction1:GetID()
	if g_ActionItemID ~= 0 then
        Item_MultiUse_Item:SetActionItem(g_ActionItemID) --展示道具
    end

	local g_ActionItemName = theAction1:GetName()
	
	Item_MultiUse_ItemInfo_Text:SetText(g_ActionItemName) --道具名字
	Item_MultiUse_ItemInfo_GB:SetText(ScriptGlobal_Format("#{CLDHDB_210510_48}",g_max)) --拥有最大数量

	Item_MultiUse_InputNum:SetProperty("DefaultEditBox", "True")
	Item_MultiUse_InputNum:SetSelected(0, -1)

	this:Show()
end

--===============================================
-- Max按键()
--===============================================
function Item_MultiUse_CalMax()
	Item_MultiUse_InputNum:SetText(g_max)
end

--===============================================
-- 确定按键（回调各自函数）
--===============================================
function Item_MultiUse_BuyMulti_Clicked()

	if defaultNum <= 0 then
        PushDebugMessage("#{YHBSY_210518_07}")
        return
	end
	this:Hide()
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnItemBatchUseFromClient")
		Set_XSCRIPT_ScriptID(790059)
		Set_XSCRIPT_Parameter(0, g_ItemID)
		Set_XSCRIPT_Parameter(1, defaultNum)
		Set_XSCRIPT_Parameter(2, g_MultiIseUse_ScriptId)
		Set_XSCRIPT_Parameter(3, g_nItemBagPos)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT();
	
	return

end

--===============================================
-- Close()
--===============================================
function Item_MultiUse_Close_Clicked()
	
	this:Hide()
end

--===============================================
-- TextChanged()
--===============================================
function Item_MultiUse_TextChanged()
	local nString = Item_MultiUse_InputNum:GetText()
	
	--默认为MAX
    if nString == nil or nString == "" then
		defaultNum = 0
		--Item_MultiUse_InputNum:SetText(defaultNum)
		return
	end

	local nBuysNum = tonumber(nString)
    if nBuysNum == nil then
		defaultNum = 0
		--Item_MultiUse_InputNum:SetText(defaultNum)
		return
	end

	--小于0时
	if nBuysNum <= 0 then
		defaultNum = 1
		Item_MultiUse_InputNum:SetText(defaultNum)
		return
	end
	
	--大于最大使用数量
    if nBuysNum > g_max then
        defaultNum = g_max
        Item_MultiUse_InputNum:SetText(defaultNum)
        return
    end

	defaultNum = nBuysNum
	
end