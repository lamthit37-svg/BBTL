-- 端午节虎虎生威

local g_Frame_UnifiedPosition

local g_curIndex = -1
local g_bagIndex = -1
local g_flag = {0,0,0}
local g_Count = 3

-- 控件
local g_ActionBtns = {}
local g_ItemNames = {}
local g_ImageFlags = {}
local g_ImageMasks = {}
local g_functionActionFlg = "HuhuShengweiBox"
-- 数据

local g_Datas = 
{	
	["HuhuShengweiBox"] ={
		[1] = 38005325, 
		[2] = 38005326, 
		[3] = 38005327, 
	},
	["2021xiguajielibao_huanyulibao"] ={
		[1] = 38005344, 
		[2] = 38005346, 
		[3] = 38005348, 
	}
}

local g_Data = g_Datas[g_functionActionFlg]

--=========
-- PreLoad()
--=========
function ChildrenDaySelect_PreLoad()
		this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function ChildrenDaySelect_OnLoad()	
		g_Frame_UnifiedPosition = ChildrenDaySelectFrame_BK:GetProperty("UnifiedPosition")
		
		g_ActionBtns[1] = ChildrenDaySelectPage_Lace1Item
		g_ActionBtns[2] = ChildrenDaySelectPage_Lace2Item
		g_ActionBtns[3] = ChildrenDaySelectPage_Lace3Item

		g_ItemNames[1] = ChildrenDaySelectPage_Lace1Item_Tip
		g_ItemNames[2] = ChildrenDaySelectPage_Lace2Item_Tip
		g_ItemNames[3] = ChildrenDaySelectPage_Lace3Item_Tip
		
		g_ImageFlags[1] = ChildrenDaySelectPage_Lace1Item_Conermark
		g_ImageFlags[2] = ChildrenDaySelectPage_Lace2Item_Conermark
		g_ImageFlags[3] = ChildrenDaySelectPage_Lace3Item_Conermark
		
		g_ImageMasks[1] = ChildrenDaySelectPage_Lace1Item_Mask
		g_ImageMasks[2] = ChildrenDaySelectPage_Lace2Item_Mask
		g_ImageMasks[3] = ChildrenDaySelectPage_Lace3Item_Mask

		g_ChildrenDaySelectDragTitle  = ChildrenDaySelectDragTitle
		g_ChildrenDaySelectPage_Info1  = ChildrenDaySelectPage_Info
		g_ChildrenDaySelectPage_Info2 = ChildrenDaySelectPage_Info2
		
end

--=========
-- Event
--=========
function ChildrenDaySelect_OnEvent(event)
		if (event == "UI_COMMAND" and tonumber(arg0) == 88843401) then
				ChildrenDaySelect_Clear()
				g_bagIndex = Get_XParam_INT(0)
				for i=1,g_Count do
					g_flag[i] = Get_XParam_INT(i)
				end
				this:Show()-- 显示界面
				g_functionActionFlg = Get_XParam_STR(0)
				g_Data = g_Datas[g_functionActionFlg]
		
				ChildrenDaySelect_Update()
		elseif event == "HIDE_ON_SCENE_TRANSED" then	
				ChildrenDaySelect_OnHidden()	
		elseif event == "VIEW_RESOLUTION_CHANGED" then		
				ChildrenDaySelect_On_ResetPos()	
		elseif event == "ADJEST_UI_POS" then	
				ChildrenDaySelect_On_ResetPos()	
		end
end

--=========
-- 重置
--=========
function ChildrenDaySelect_On_ResetPos()
		ChildrenDaySelectFrame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 关闭界面
--=========
function ChildrenDaySelect_OnHidden()
	ChildrenDaySelect_Clear()
	this:Hide()
end

function ChildrenDaySelect_Clear()
	LifeAbility:Lock_Packet_Item(g_bagIndex, 0)
	g_curIndex = -1
end

--=========
-- 刷新界面
--=========
function ChildrenDaySelect_Update()
 
	for i=1, g_Count do
		local id = g_Data[i]
		local tAction = DataPool:CreateActionItemForShow(id, 1)
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

	if  g_functionActionFlg =="HuhuShengweiBox" then
		g_ChildrenDaySelectDragTitle:SetText("#{DWWJ_210514_06}")
		g_ChildrenDaySelectPage_Info1:SetText("#{DWWJ_210514_07}")
		g_ChildrenDaySelectPage_Info2:SetText("#{DWWJ_210514_12}")
	elseif g_functionActionFlg =="2021xiguajielibao_huanyulibao" then
		
		g_ChildrenDaySelectDragTitle:SetText("#{YHGMHY_210609_05}")
		g_ChildrenDaySelectPage_Info1:SetText("#{YHGMHY_210609_06}")
		g_ChildrenDaySelectPage_Info2:SetText("#{YHGMHY_210609_10}")
	end


end	

--=========
-- 点击领取
--=========
function ChildrenDaySelect_OKClicked()
		if g_curIndex <= 0 or g_curIndex > g_Count then
				PushDebugMessage("#{ZNYR_20210326_15}")
				return
		end
		if g_functionActionFlg =="HuhuShengweiBox" then
			Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name("OnChoice")
					Set_XSCRIPT_ScriptID(888434)
					Set_XSCRIPT_Parameter( 0, g_bagIndex )
					Set_XSCRIPT_Parameter( 1, g_curIndex )
					Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		elseif g_functionActionFlg =="2021xiguajielibao_huanyulibao" then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnChoice")
				Set_XSCRIPT_ScriptID(888447)
				Set_XSCRIPT_Parameter( 0, g_bagIndex )
				Set_XSCRIPT_Parameter( 1, g_curIndex )
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		end

		ChildrenDaySelect_OnHidden()
end

--=========
-- 点击选中
--=========
function ChildrenDaySelect_OnActionItemClicked(nIndex)
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
