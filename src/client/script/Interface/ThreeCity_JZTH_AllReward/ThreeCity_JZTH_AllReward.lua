
--ThreeCity_JZTH_AllReward
local g_ThreeCity_JZTH_AllReward_UnifiedPosition;

local ThreeCity_JZTH_AllReward_BarList = {}
local ThreeCity_JZTH_AllReward_AwardNum = 0

local ThreeCity_JZTH_AllReward_Text = {
	[1] = "#{DBXH_220811_57}",
	[2] = "#{DBXH_220811_86}",
	[3] = "#{DBXH_220811_87}",
	[4] = "#{DBXH_220811_88}",
	[5] = "#{DBXH_220811_89}",
	[6] = "#{DBXH_220811_90}",
	[7] = "#{DBXH_220811_91}",
	[8] = "#{DBXH_220811_92}",
}

function ThreeCity_JZTH_AllReward_PreLoad()

	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
end

function ThreeCity_JZTH_AllReward_OnLoad()	

	g_ThreeCity_JZTH_AllReward_UnifiedPosition = ThreeCity_JZTH_AllReward_Frame:GetProperty("UnifiedPosition")
		
end

function ThreeCity_JZTH_AllReward_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99824402 ) then
	
		local operator = tonumber(arg1)
		if operator == 1 then			
			ThreeCity_JZTH_AllReward_Open()
		else
			ThreeCity_JZTH_AllReward_Close()
		end

	elseif (event == "ADJEST_UI_POS" ) then
		ThreeCity_JZTH_AllReward_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ThreeCity_JZTH_AllReward_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ThreeCity_JZTH_AllReward_Close()
		
	end

end

--=========================================================
--更新界面
--=========================================================
function ThreeCity_JZTH_AllReward_Open()
		
	ThreeCity_JZTH_AllReward_CleanUp()

	ThreeCity_JZTH_AllReward_AwardNum = Lua_GetJianZhiTianHuangInfoCount()
	if ThreeCity_JZTH_AllReward_AwardNum <= 0 then
		return
	end
	for Awardidx = 1, ThreeCity_JZTH_AllReward_AwardNum do
		local bar = ThreeCity_JZTH_AllReward_List:AddChild("ThreeCity_JZTH_AllReward_List_Content")
		if bar ~= nil then
			-- 先隐藏
			local oActionBtn = nil
			for i = 1, 9 do
				oActionBtn = bar:GetSubItem("ThreeCity_JZTH_AllReward_RewardItem"..i);
				if oActionBtn ~= nil then
					oActionBtn:Hide()
				end
			end
			
			-- 战场场地
			if ThreeCity_JZTH_AllReward_Text[Awardidx] ~= nil then
				bar:GetSubItem("ThreeCity_JZTH_AllReward_RewardText"):SetText(ThreeCity_JZTH_AllReward_Text[Awardidx])
			end
			
			-- 道具填充
			local nItemCount = Lua_GetJianZhiTianHuangItemCount(Awardidx)
			if nItemCount > 1 then
				for i = 1, nItemCount do	
					oActionBtn = bar:GetSubItem("ThreeCity_JZTH_AllReward_RewardItem"..i)
					local nItemId, nItemCnt, nItemShowId, nItemBind = Lua_GetJianZhiTianHuangItemInfo(Awardidx, i)				
					if nItemId > 0 and nItemCnt > 0 then
						if oActionBtn ~= nil then
							if nItemBind == 1 then
								local theAction = DataPool:CreateBindActionItemForShow(nItemShowId, nItemCnt)
								if theAction:GetID() ~= 0 then
									oActionBtn:SetActionItem( theAction:GetID() )
									oActionBtn:Show()
								end
							else
								local theAction = DataPool:CreateActionItemForShow(nItemShowId, nItemCnt)
								if theAction:GetID() ~= 0 then
									oActionBtn:SetActionItem( theAction:GetID() )
									oActionBtn:Show()
								end
							end
						end
					end
				end				
			end
			table.insert(ThreeCity_JZTH_AllReward_BarList, bar)
		end
		
	end

	this:Show()
	this:Activate()
end	

function ThreeCity_JZTH_AllReward_CleanUp()

	ThreeCity_JZTH_AllReward_AwardNum = 0

	for Awardidx = 1, ThreeCity_JZTH_AllReward_AwardNum do
		if ThreeCity_JZTH_AllReward_BarList[Awardidx] ~= nil then
			for i = 1, 9 do
				local ctrlAction = ThreeCity_JZTH_AllReward_BarList[Awardidx]:GetSubItem("ThreeCity_JZTH_AllReward_RewardItem"..i)	
				if ctrlAction then
					ctrlAction:SetActionItem(-1)
				end
			end
		end
	end
	
	ThreeCity_JZTH_AllReward_BarList = {}
	
	ThreeCity_JZTH_AllReward_List:Clear()
	
end

--=========================================================
--关闭
--=========================================================
function ThreeCity_JZTH_AllReward_Close()

	ThreeCity_JZTH_AllReward_CleanUp()
	
	this:Hide()
	
end

function ThreeCity_JZTH_AllReward_OnHiden()

	ThreeCity_JZTH_AllReward_Close()
	
end

--=========================================================
--刷新位置
--=========================================================
function ThreeCity_JZTH_AllReward_On_ResetPos()

	ThreeCity_JZTH_AllReward_Frame:SetProperty("UnifiedPosition", g_ThreeCity_JZTH_AllReward_UnifiedPosition);
	
end

