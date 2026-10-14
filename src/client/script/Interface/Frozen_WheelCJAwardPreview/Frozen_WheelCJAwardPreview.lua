--Frozen_WheelCJAwardPreview
local g_Frozen_WheelCJAwardPreview_UnifiedPosition;


local Frozen_WheelCJAwardPreview_List1_Item = {}
local Frozen_WheelCJAwardPreview_List2_Item = {}


function Frozen_WheelCJAwardPreview_PreLoad()
	this:RegisterEvent("OPEN_SNOW_WhEElPREVIEW",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function Frozen_WheelCJAwardPreview_OnLoad()
	
	for i = 1, 8 do
		Frozen_WheelCJAwardPreview_List1_Item[i] = _G["Frozen_WheelCJAwardPreview_Icon1_"..i]	
		Frozen_WheelCJAwardPreview_List2_Item[i] = _G["Frozen_WheelCJAwardPreview_Icon2_"..i]
	end
	

	g_Frozen_WheelCJAwardPreview_UnifiedPosition = Frozen_WheelCJAwardPreview_Frame:GetProperty("UnifiedPosition")
	
end


function Frozen_WheelCJAwardPreview_OnEvent(event)

	if ( event == "OPEN_SNOW_WhEElPREVIEW" ) then
		Frozen_WheelCJAwardPreview_Update()
	
	elseif (event == "ADJEST_UI_POS" ) then
		Frozen_WheelCJAwardPreview_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Frozen_WheelCJAwardPreview_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()

	end

end

--=========================================================
--更新界面
--=========================================================
function Frozen_WheelCJAwardPreview_Update()
	local nList1Num = 1
	local nList2Num = 1

	for i = 1, 8 do
		local nShowItemId,nItemNum,nIsBind = DataPool:LuaFnGetSnowShopCJItemInfo(0, i)
		if nShowItemId ~= nil and nShowItemId > 0 then
			local theAction = nil
			if nIsBind == 1 then
				theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
			else
				theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
			end
			if theAction ~= nil then
				Frozen_WheelCJAwardPreview_List1_Item[i]:SetActionItem(theAction:GetID())
			end			
		end
	end
	
	for i = 1, 8 do
		local nShowItemId,nItemNum,nIsBind = DataPool:LuaFnGetSnowShopCJItemInfo(20, i)
		if nShowItemId ~= nil and nShowItemId > 0 then
			local theAction = nil
			if nIsBind == 1 then
				theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
			else
				theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
			end
			if theAction ~= nil then
				Frozen_WheelCJAwardPreview_List2_Item[i]:SetActionItem(theAction:GetID())
			end			
		end
	end
	this:Show()
end

--=========================================================
--刷新位置
--=========================================================
function Frozen_WheelCJAwardPreview_On_ResetPos()
	Frozen_WheelCJAwardPreview_Frame:SetProperty("UnifiedPosition", g_Frozen_WheelCJAwardPreview_UnifiedPosition);
end

--=========================================================
--关闭
--=========================================================
function Frozen_WheelCJAwardPreview_Close()
	this:Hide()
end
