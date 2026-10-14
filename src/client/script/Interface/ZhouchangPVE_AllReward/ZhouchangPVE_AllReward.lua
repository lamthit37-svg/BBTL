-- 排行榜界面

-- 保存UI默认位置
local ZhouchangPVE_AllReward_UnifiedPosition = nil

local g_nLevelInfo = {
	[1] = {pointmin = 400, pointmax = 1199, text = "#{FHCL_240708_497}"},
	[2] = {pointmin = 1200, pointmax = 3499, text = "#{FHCL_240708_498}"},
	[3] = {pointmin = 3500, pointmax = 4999, text = "#{FHCL_240708_499}"},
	[4] = {pointmin = 5000, pointmax = 9999999, text = "#{FHCL_240708_500}"},
}


local g_nDaiBiInfo = {
	--60-89
	[1] = { 
		--	简单
		[0] = {
			[1] = {[1] = {id = 39924621, num = 50}, [2] = {id = 39923715, num = 15}, [3] = {id = -1, num = -1}, [4] = {id = -1, num = -1}, [5] = {id = -1, num = -1}},
			[2] = {[1] = {id = 39924621, num = 100}, [2] = {id = 39923715, num = 30}, [3] = {id = -1, num = -1}, [4] = {id = -1, num = -1}, [5] = {id = -1, num = -1}},
			[3] = {[1] = {id = 39924621, num = 300}, [2] = {id = 39923715, num = 90}, [3] = {id = -1, num = -1}, [4] = {id = -1, num = -1}, [5] = {id = -1, num = -1}},
			[4] = {[1] = {id = 39924621, num = 500}, [2] = {id = 39924622, num = 5}, [3] = {id = 39923715, num = 150}, [4] = {id = 39923714, num = 1}, [5] = {id = -1, num = -1}},
		},
		--	困难
		[1] = {
			[1] = {[1] = {id = 39924621, num = 200}, [2] = {id = 39923715, num = 60}, [3] = {id = -1, num = -1}, [4] = {id = -1, num = -1}, [5] = {id = -1, num = -1}},
			[2] = {[1] = {id = 39924621, num = 400}, [2] = {id = 39924622, num = 5}, [3] = {id = 39923715, num = 120}, [4] = {id = 39923714, num = 1}, [5] = {id = 39923930, num = 3}},
			[3] = {[1] = {id = 39924621, num = 500}, [2] = {id = 39924622, num = 10}, [3] = {id = 39923715, num = 150}, [4] = {id = 39923714, num = 1}, [5] = {id = 39923930, num = 4}},
			[4] = {[1] = {id = 39924621, num = 500}, [2] = {id = 39924622, num = 20}, [3] = {id = 39923715, num = 150}, [4] = {id = 39923714, num = 2}, [5] = {id = 39923930, num = 5}},
		},
	},
	--90-109
	[2] = {
		--	简单
		[0] = {
			[1] = {[1] = {id = 39924621, num = 50}, [2] = {id = 39923715, num = 20}, [3] = {id = -1, num = -1}, [4] = {id = -1, num = -1}, [5] = {id = -1, num = -1}},
			[2] = {[1] = {id = 39924621, num = 100}, [2] = {id = 39923715, num = 40}, [3] = {id = -1, num = -1}, [4] = {id = -1, num = -1}, [5] = {id = -1, num = -1}},
			[3] = {[1] = {id = 39924621, num = 300}, [2] = {id = 39923715, num = 120}, [3] = {id = -1, num = -1}, [4] = {id = -1, num = -1}, [5] = {id = -1, num = -1}},
			[4] = {[1] = {id = 39924621, num = 500}, [2] = {id = 39924622, num = 5}, [3] = {id = 39923715, num = 200}, [4] = {id = 39923714, num = 1}, [5] = {id = -1, num = -1}},
		},
		--	困难
		[1] = {
			[1] = {[1] = {id = 39924621, num = 200}, [2] = {id = 39923715, num = 80}, [3] = {id = -1, num = -1}, [4] = {id = -1, num = -1}, [5] = {id = -1, num = -1}},
			[2] = {[1] = {id = 39924621, num = 400}, [2] = {id = 39924622, num = 5}, [3] = {id = 39923715, num = 160}, [4] = {id = 39923714, num = 1}, [5] = {id = 39923930, num = 3}},
			[3] = {[1] = {id = 39924621, num = 500}, [2] = {id = 39924622, num = 10}, [3] = {id = 39923715, num = 200}, [4] = {id = 39923714, num = 2}, [5] = {id = 39923930, num = 4}},
			[4] = {[1] = {id = 39924621, num = 500}, [2] = {id = 39924622, num = 20}, [3] = {id = 39923715, num = 200}, [4] = {id = 39923714, num = 4}, [5] = {id = 39923930, num = 5}},
		},
	},
	--110-129
	[3] = {
		--	简单
		[0] = {
			[1] = {[1] = {id = 39924621, num = 50}, [2] = {id = 39923715, num = 25}, [3] = {id = -1, num = -1}, [4] = {id = -1, num = -1}, [5] = {id = -1, num = -1}},
			[2] = {[1] = {id = 39924621, num = 100}, [2] = {id = 39923715, num = 50}, [3] = {id = -1, num = -1}, [4] = {id = -1, num = -1}, [5] = {id = -1, num = -1}},
			[3] = {[1] = {id = 39924621, num = 300}, [2] = {id = 39923715, num = 150}, [3] = {id = -1, num = -1}, [4] = {id = -1, num = -1}, [5] = {id = -1, num = -1}},
			[4] = {[1] = {id = 39924621, num = 500}, [2] = {id = 39924622, num = 5}, [3] = {id = 39923715, num = 250}, [4] = {id = 39923714, num = 2}, [5] = {id = -1, num = -1}},
		},
		--	困难
		[1] = {
			[1] = {[1] = {id = 39924621, num = 200}, [2] = {id = 39923715, num = 100}, [3] = {id = -1, num = -1}, [4] = {id = -1, num = -1}, [5] = {id = -1, num = -1}},
			[2] = {[1] = {id = 39924621, num = 400}, [2] = {id = 39924622, num = 5}, [3] = {id = 39923715, num = 200}, [4] = {id = 39923714, num = 2}, [5] = {id = 39923930, num = 3}},
			[3] = {[1] = {id = 39924621, num = 500}, [2] = {id = 39924622, num = 10}, [3] = {id = 39923715, num = 250}, [4] = {id = 39923714, num = 3}, [5] = {id = 39923930, num = 4}},
			[4] = {[1] = {id = 39924621, num = 500}, [2] = {id = 39924622, num = 20}, [3] = {id = 39923715, num = 250}, [4] = {id = 39923714, num = 6}, [5] = {id = 39923930, num = 5}},
		},
	},
}

function ZhouchangPVE_AllReward_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
end -- end func ZhouchangPVE_AllReward_PreLoad()

function ZhouchangPVE_AllReward_OnLoad()
    ZhouchangPVE_AllReward_UnifiedPosition = ZhouchangPVE_AllReward_Frame:GetProperty("UnifiedPosition")	
	

end -- end func ZhouchangPVE_AllReward_OnLoad()

function ZhouchangPVE_AllReward_OnEvent(event)
    if (event == "UI_COMMAND") and (tonumber(arg0) == 331105012) then
		local nMode = Get_XParam_INT(0)	
		ZhouchangPVE_AllReward_UpdateRankList(nMode)
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
		
			ZhouchangPVE_AllReward_Hide()

    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        ZhouchangPVE_AllReward_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        ZhouchangPVE_AllReward_UnifiedPos()
	
    end
end -- end func ZhouchangPVE_AllReward_OnEvent()

-- 界面默认位置
function ZhouchangPVE_AllReward_UnifiedPos()
    if (this:IsVisible()) then
        if (ZhouchangPVE_AllReward_UnifiedPosition ~= nil) then
            ZhouchangPVE_AllReward_Frame:SetProperty("UnifiedPosition", ZhouchangPVE_AllReward_UnifiedPosition)
        end
    end
end -- end func ZhouchangPVE_AllReward_UnifiedPos()

function ZhouchangPVE_AllReward_Show()
    if (not this:IsVisible()) then
        this:Show()
    end
end -- end func ZhouchangPVE_AllReward_Show()

function ZhouchangPVE_AllReward_Hide()
    this:Hide()
end -- end func ZhouchangPVE_AllReward_Hide()

-- 关闭按钮点击事件
function ZhouchangPVE_AllReward_OnClosed_Clicked()
    ZhouchangPVE_AllReward_Hide()
end  -- end func ZhouchangPVE_AllReward_Close_Clicked()




-- 刷新排行榜
function ZhouchangPVE_AllReward_UpdateRankList(mode)
 
	

    -- 更新排行榜
    ZhouchangPVE_AllReward_List:Clear()
	
	local nLevel = Player:GetData("LEVEL_CompatPKLV")
	local nLevelIndex = -1
	if nLevel >= 60 and nLevel <= 89 then
		nLevelIndex = 1
	elseif nLevel >= 90 and nLevel <= 109 then
		nLevelIndex = 2
	elseif nLevel >= 110 and nLevel <= 129 then
		nLevelIndex = 3
	end
	
	local nCoe = 1
	if 1 == Player:GetData("Is2606S") then
		nCoe = 2
	end
	
	local nAwardInfo = {}
	
	nAwardInfo = g_nDaiBiInfo[nLevelIndex]
   
	for i=1, table.getn(g_nLevelInfo) do
		
		-- 添加排行榜表项
		local child = ZhouchangPVE_AllReward_List:AddChild("ZhouchangPVE_AllReward_List_Content")
		if (child ~= nil ) then				
			child:GetSubItem("ZhouchangPVE_AllReward_RewardText"):SetText(g_nLevelInfo[i].text) 
			
			
			if nAwardInfo[mode][i][1].id ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(nAwardInfo[mode][i][1].id, 1)
				if theAction:GetID() ~= 0 then
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem1"):SetActionItem(theAction:GetID());
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem1"):Show();
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem1_Num"):SetText("#Y"..nAwardInfo[mode][i][1].num*nCoe);
				end
			else
				child:GetSubItem("ZhouchangPVE_AllReward_RewardItem1"):Hide();
			end
			
			if nAwardInfo[mode][i][2].id ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(nAwardInfo[mode][i][2].id, 1)
				if theAction:GetID() ~= 0 then
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem2"):SetActionItem(theAction:GetID());
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem2"):Show();
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem2_Num"):SetText("#Y"..nAwardInfo[mode][i][2].num*nCoe);
				end
			else
				child:GetSubItem("ZhouchangPVE_AllReward_RewardItem2"):Hide();
			end
			
			if nAwardInfo[mode][i][3].id ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(nAwardInfo[mode][i][3].id, 1)
				if theAction:GetID() ~= 0 then
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem3"):SetActionItem(theAction:GetID());
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem3"):Show();
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem3_Num"):SetText("#Y"..nAwardInfo[mode][i][3].num*nCoe);
				end
			else
				child:GetSubItem("ZhouchangPVE_AllReward_RewardItem3"):Hide();
			end
			
			if nAwardInfo[mode][i][4].id ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(nAwardInfo[mode][i][4].id, 1)
				if theAction:GetID() ~= 0 then
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem4"):SetActionItem(theAction:GetID());
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem4"):Show();
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem4_Num"):SetText("#Y"..nAwardInfo[mode][i][4].num*nCoe);
				end
			else
				child:GetSubItem("ZhouchangPVE_AllReward_RewardItem4"):Hide();
			end
			
			if nAwardInfo[mode][i][5].id ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(nAwardInfo[mode][i][5].id, 1)
				if theAction:GetID() ~= 0 then
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem5"):SetActionItem(theAction:GetID());
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem5"):Show();
					child:GetSubItem("ZhouchangPVE_AllReward_RewardItem5_Num"):SetText("#Y"..nAwardInfo[mode][i][5].num);
				end
			else
				child:GetSubItem("ZhouchangPVE_AllReward_RewardItem5"):Hide();
			end
			
			
		end
			

    end
	ZhouchangPVE_AllReward_Show()
    
end -- end func ZhouchangPVE_AllReward_UpdateRankList()

function ZhouchangPVE_AllReward_Help_Clicked()
    --PushEvent("CCSHOP_HELP", 206)
end -- end func CampPVP2023_Progress_Help()


function ZhouchangPVE_AllReward_Close()
	ZhouchangPVE_AllReward_Hide()
end