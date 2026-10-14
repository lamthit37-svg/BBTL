-- 风云联动 收藏（采集）物品展示UI
-- 默认位置
local FengYun_PVE_Collect_UnifiedPosition = nil



function FengYun_PVE_Collect_PreLoad()
	this:RegisterEvent("FYPVE_TRYTOOPENCOLLECT", true)
	this:RegisterEvent("FYPVE_COLLECTOPEN", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func FengYun_PVE_Collect_PreLoad()

function FengYun_PVE_Collect_OnEvent(event)
    if (event == "FYPVE_TRYTOOPENCOLLECT") then
		AskServerTimeAgain()
	elseif (event == "FYPVE_COLLECTOPEN") then
		FengYun_PVE_Collect_UpdateItemInfo()
		FengYun_PVE_Collect_Show()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FengYun_PVE_Collect_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_PVE_Collect_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		FengYun_PVE_Collect_UnifiedPos()
	end
end -- end func FengYun_PVE_Collect_OnEvent()

function FengYun_PVE_Collect_OnLoad()
	FengYun_PVE_Collect_UnifiedPosition = FengYun_PVE_Collect_Frame:GetProperty("UnifiedPosition")
end -- end func FengYun_PVE_Collect_OnLoad()

-- 界面默认位置
function FengYun_PVE_Collect_UnifiedPos()
	if (FengYun_PVE_Collect_UnifiedPosition ~= nil) then
		FengYun_PVE_Collect_Frame:SetProperty("UnifiedPosition", FengYun_PVE_Collect_UnifiedPosition)
	end
end -- end func FengYun_PVE_Collect_UnifiedPos()

function FengYun_PVE_Collect_Show()
    this:Show()
end -- end func FengYun_PVE_Collect_Show()

function FengYun_PVE_Collect_Hide()
    this:Hide()
end -- end func FengYun_PVE_Collect_Hide()

--*************************************************************************************************
--
--*************************************************************************************************

-- 关闭按钮点击事件
function FengYun_PVE_Collect_OnHiden()
	FengYun_PVE_Collect_Hide()
end -- end func FengYun_PVE_Collect_OnHiden()

--*************************************************************************************************
--
--*************************************************************************************************

-- 物品收藏信息
function FengYun_PVE_Collect_UpdateItemInfo()
	FengYun_PVE_Collect_List:Clear()
	local itemNum = FYPVE:GetTableItemNum()
	if (itemNum > 0) then
		for i=1, itemNum, 1 do
			local itemID, itemShowID, itemName = FYPVE:GetTableItemData(i)
			if (itemID ~= nil) then
				local bar = FengYun_PVE_Collect_List:AddChild("FengYun_PVE_Collect_ListItem")
				if (bar ~= nil) then
					local theAction = DataPool:CreateActionItemForShow(itemShowID, 0)
					if (theAction ~= nil and theAction:GetID() ~= 0) then
						local collectId, collectType, collectState, collectNum = FYPVE:GetCollectionDataByIndex(itemID-1)
						bar:GetSubItem("FengYun_PVE_Collect_ListItem_Icon"):SetActionItem(theAction:GetID())
						if (collectId ~= nil and collectNum > 0) then
							bar:GetSubItem("FengYun_PVE_Collect_ListItem_Mask"):Hide()
							bar:GetSubItem("FengYun_PVE_Collect_ListItem_Name"):SetText(itemName)
							local numStr = ScriptGlobal_Format("#{FYPVE_260108_24}", collectNum)
							bar:GetSubItem("FengYun_PVE_Collect_ListItem_Text"):SetText(numStr)
						else
							bar:GetSubItem("FengYun_PVE_Collect_ListItem_Mask"):Show()
							bar:GetSubItem("FengYun_PVE_Collect_ListItem_Name"):SetText(itemName)
							bar:GetSubItem("FengYun_PVE_Collect_ListItem_Text"):SetText("#{FYPVE_260108_25}")
						end
					end
				end
			end
		end -- end for
	end
end -- end func FengYun_PVE_Collect_UpdateItemInfo()