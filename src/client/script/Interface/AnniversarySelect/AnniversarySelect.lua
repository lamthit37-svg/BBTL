-- 2021周年预热活动
-- 五选一木偶礼盒界面

local g_Frame_UnifiedPosition

local g_curIndex = -1
local g_bagIndex = -1
local g_flag = {0,0,0,0,0}
local g_Count = 5

-- 控件
local g_ActionBtns = {}
local g_ItemNames = {}
local g_ImageFlags = {}
local g_ImageMasks = {}

-- 数据
local g_Data = 
{	
	[1] = 38005267, 
	[2] = 38005268, 
	[3] = 38005269, 
	[4] = 38005270, 
	[5] = 38005271, 
}

--=========
-- PreLoad()
--=========
function AnniversarySelect_PreLoad()
		this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function AnniversarySelect_OnLoad()	
		g_Frame_UnifiedPosition = AnniversarySelectFrame_BK:GetProperty("UnifiedPosition")
		
		g_ActionBtns[1] = AnniversarySelectPage_Lace1Item
		g_ActionBtns[2] = AnniversarySelectPage_Lace2Item
		g_ActionBtns[3] = AnniversarySelectPage_Lace3Item
		g_ActionBtns[4] = AnniversarySelectPage_Lace4Item
		g_ActionBtns[5] = AnniversarySelectPage_Lace5Item
		
		g_ItemNames[1] = AnniversarySelectPage_Lace1Item_Tip
		g_ItemNames[2] = AnniversarySelectPage_Lace2Item_Tip
		g_ItemNames[3] = AnniversarySelectPage_Lace3Item_Tip
		g_ItemNames[4] = AnniversarySelectPage_Lace4Item_Tip
		g_ItemNames[5] = AnniversarySelectPage_Lace5Item_Tip
		
		g_ImageFlags[1] = AnniversarySelectPage_Lace1Item_Conermark
		g_ImageFlags[2] = AnniversarySelectPage_Lace2Item_Conermark
		g_ImageFlags[3] = AnniversarySelectPage_Lace3Item_Conermark
		g_ImageFlags[4] = AnniversarySelectPage_Lace4Item_Conermark
		g_ImageFlags[5] = AnniversarySelectPage_Lace5Item_Conermark
		
		g_ImageMasks[1] = AnniversarySelectPage_Lace1Item_Mask
		g_ImageMasks[2] = AnniversarySelectPage_Lace2Item_Mask
		g_ImageMasks[3] = AnniversarySelectPage_Lace3Item_Mask
		g_ImageMasks[4] = AnniversarySelectPage_Lace4Item_Mask
		g_ImageMasks[5] = AnniversarySelectPage_Lace5Item_Mask
		
end

--=========
-- Event
--=========
function AnniversarySelect_OnEvent(event)
		if (event == "UI_COMMAND" and tonumber(arg0) == 88840501) then
				g_bagIndex = Get_XParam_INT(0)
				for i=1,g_Count do
						g_flag[i] = Get_XParam_INT(i)
				end
				this:Show()-- 显示界面
				AnniversarySelect_Update()		
		elseif event == "HIDE_ON_SCENE_TRANSED" then	
				AnniversarySelect_OnHidden()	
		elseif event == "VIEW_RESOLUTION_CHANGED" then		
				AnniversarySelect_On_ResetPos()	
		elseif event == "ADJEST_UI_POS" then	
				AnniversarySelect_On_ResetPos()	
		end
end

--=========
-- 重置
--=========
function AnniversarySelect_On_ResetPos()
		AnniversarySelectFrame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 关闭界面
--=========
function AnniversarySelect_OnHidden()
		LifeAbility:Lock_Packet_Item(g_bagIndex, 0)
		g_curIndex = -1
		this:Hide()
end

--=========
-- 刷新界面
--=========
function AnniversarySelect_Update()
		for i=1, g_Count do
        local tAction = DataPool:CreateActionItemForShow(g_Data[i], 1)
				if tAction:GetID() ~= 0 then
						-- 道具
            g_ActionBtns[i]:SetActionItem(tAction:GetID())
						-- 名字
            local itemName = PlayerPackage:GetItemName(g_Data[i])
            g_ItemNames[i]:SetText("#L" .. itemName)
						-- 拥有
            if g_flag[i] > 0 then
                g_ImageFlags[i]:Show()
            else
            		g_ImageFlags[i]:Hide()
            end
						-- 选中
						g_ImageMasks[i]:Hide()
				end
		end
		LifeAbility:Lock_Packet_Item(g_bagIndex, 1)
end	

--=========
-- 点击领取
--=========
function AnniversarySelect_OKClicked()
		if g_curIndex <= 0 or g_curIndex > g_Count then
				PushDebugMessage("#{ZNYR_20210326_15}")
				return
		end
		Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnChoice")
				Set_XSCRIPT_ScriptID(888405)
				Set_XSCRIPT_Parameter( 0, g_bagIndex )
				Set_XSCRIPT_Parameter( 1, g_curIndex )
				Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		AnniversarySelect_OnHidden()
end

--=========
-- 点击选中
--=========
function AnniversarySelect_OnActionItemClicked(nIndex)
		if nIndex == nil or nIndex <= 0 or nIndex > g_Count then
				return
		end
		if g_curIndex > 0 and g_curIndex <= g_Count then-- 原有选中
				if g_curIndex == nIndex then--选中当前
						g_ImageMasks[g_curIndex]:Hide()
						g_curIndex = -1
				else-- 选中其他
						g_ImageMasks[g_curIndex]:Hide()
						g_curIndex = nIndex
						g_ImageMasks[g_curIndex]:Show()
				end
		else--未选中
				g_curIndex = nIndex
				g_ImageMasks[g_curIndex]:Show()
		end	
end
