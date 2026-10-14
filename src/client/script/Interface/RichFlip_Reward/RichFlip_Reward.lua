--RichFlip_Reward
local g_RichFlip_Reward_UnifiedPosition;


local RichFlip_Reward_List1_Item = {}
local RichFlip_Reward_List2_Item = {}
local RichFlip_Reward_List3_Item = {}

function RichFlip_Reward_PreLoad()
	this:RegisterEvent("LUCKYLINE_OPEN_PREVIEW",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function RichFlip_Reward_OnLoad()
	
	for i = 1, 2 do
		RichFlip_Reward_List1_Item[i] = _G["RichFlip_Reward_Reward_List1_RewardItem"..i]	
	end
	
	for i = 1, 4 do
		RichFlip_Reward_List2_Item[i] = _G["RichFlip_Reward_Reward_List2_RewardItem"..i]	
	end
	
	for i = 1, 6 do
		RichFlip_Reward_List3_Item[i] = _G["RichFlip_Reward_Reward_List3_RewardItem"..i]
	end

	g_RichFlip_Reward_UnifiedPosition = RichFlip_Reward_Reward_Frame:GetProperty("UnifiedPosition")
	
end


function RichFlip_Reward_OnEvent(event)

	if ( event == "LUCKYLINE_OPEN_PREVIEW" ) then
		RichFlip_Reward_Update()
	
	elseif (event == "ADJEST_UI_POS" ) then
		RichFlip_Reward_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		RichFlip_Reward_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()

	end

end

--=========================================================
--更新界面
--=========================================================
function RichFlip_Reward_Update()
	local nList1Num = 1
	local nList2Num = 1
	local nList3Num = 1
	
	for i = 1, 12 do
		local nShowItemId,nItemNum,nIsBind,nFenjie,nType = DataPool:LuaFnGetLuckyLineChoujiangItemInfo(i)
		if nShowItemId ~= nil and nShowItemId > 0 then
			local theAction = nil
			if nIsBind == 1 then
				theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
			else
				theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
			end
			if theAction ~= nil then
				if nType == 2 and nList1Num <= 2 then
					RichFlip_Reward_List1_Item[nList1Num]:SetActionItem(theAction:GetID())
					nList1Num = nList1Num + 1
				elseif nType == 1 and nList2Num <= 4 then
					RichFlip_Reward_List2_Item[nList2Num]:SetActionItem(theAction:GetID())
					nList2Num = nList2Num + 1
				elseif nType == 0 and nList3Num <= 6 then
					RichFlip_Reward_List3_Item[nList3Num]:SetActionItem(theAction:GetID())
					nList3Num = nList3Num + 1
				end				
			end
			
		end
	
	end
	this:Show()
end

--=========================================================
--刷新位置
--=========================================================
function RichFlip_Reward_On_ResetPos()
	RichFlip_Reward_Reward_Frame:SetProperty("UnifiedPosition", g_RichFlip_Reward_UnifiedPosition);
end

--=========================================================
--关闭
--=========================================================
function RichFlip_Reward_Reward_Close()
	this:Hide()
end

function RichFlip_Reward_Reward_OnHiden()
	RichFlip_Reward_Reward_Close()
end