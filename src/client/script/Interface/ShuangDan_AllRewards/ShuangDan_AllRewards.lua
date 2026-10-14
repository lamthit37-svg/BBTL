--双旦系列 奖励界面

local g_ShuangDan_AllRewards_Frame_UnifiedPosition

local g_ShuangDan_AllRewards_Button ={}

local g_ShuangDan_AllRewards_ItemList = {
--浮花拾晓
--[1] = { {itemid = 39923645, itemnum =1, },
		--{itemid = 39923630, itemnum =1, },
		--{itemid = 39923351, itemnum =1, },
		--{itemid = 39920397, itemnum =1, },
		--{itemid = 39920396, itemnum =1, },
--		},
--踏雪寻芳
[1] = {	{itemid = 39924532, itemnum =1, },
		{itemid = 39924533, itemnum =1, }, 	
		},
--东君有信
[2] = { {itemid = 39924532, itemnum =1, },
		{itemid = 39924533, itemnum =1, },
		{itemid = 39924033, itemnum =1, },
		{itemid = 39920397, itemnum =1, },
		{itemid = 39920396, itemnum =1, },
		},
--清欢百味
[3] = { {itemid = 39924532, itemnum =1, },
		{itemid = 39924533, itemnum =1, },
		{itemid = 39920394, itemnum =1, },
		{itemid = 39921051, itemnum =1, },
		{itemid = 39924029, itemnum =1, },
		},
--寒梅生香
[4] = { {itemid = 39924530, itemnum =1, },
		{itemid = 39924507, itemnum =1, },
		{itemid = 39924534, itemnum =1, },
		{itemid = 39922008, itemnum =1, },
		{itemid = 39923649, itemnum =1, },
		},
--寒香满衣
--[6] = { {itemid = 39924037, itemnum =1, },
--		{itemid = 39924040, itemnum =1, },
--		{itemid = 39924041, itemnum =1, },
--		},
}

local g_ShuangDan_AllRewards_KJItemList = {
--浮花拾晓
--[1] = { {itemid = 39923645, itemnum =1, },
		--{itemid = 39923630, itemnum =1, },
		--{itemid = 39923351, itemnum =1, },
		--{itemid = 39920397, itemnum =1, },
		--{itemid = 39920396, itemnum =1, },
--		},
--踏雪寻芳
[1] = {	{itemid = 39924532, itemnum =1, },
		{itemid = 39924533, itemnum =1, }, 	
		},
--东君有信
[2] = { {itemid = 39924532, itemnum =1, },
		{itemid = 39924533, itemnum =1, },
		{itemid = 39924033, itemnum =1, },
		{itemid = 39920397, itemnum =1, },
		{itemid = 39920396, itemnum =1, },
		},
--清欢百味
[3] = { {itemid = 39924532, itemnum =1, },
		{itemid = 39924533, itemnum =1, },
		{itemid = 39920394, itemnum =1, },
		{itemid = 39921051, itemnum =1, },
		{itemid = 39924029, itemnum =1, },
		},
--飞花解意
[4] = { {itemid = 39924530, itemnum =1, },
		{itemid = 39924507, itemnum =1, },
		{itemid = 39924534, itemnum =1, },
		{itemid = 39922008, itemnum =1, },
		{itemid = 39923649, itemnum =1, },
		},
--寒香满衣
--[6] = { {itemid = 39924037, itemnum =1, },
--		{itemid = 39924040, itemnum =1, },
--		{itemid = 39924041, itemnum =1, },
--		},
}

function ShuangDan_AllRewards_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	
end

function ShuangDan_AllRewards_OnLoad()

	ShuangDan_AllRewards_LoadControl()
	
	g_ShuangDan_AllRewards_Frame_UnifiedPosition = ShuangDan_AllRewards_Frame:GetProperty("UnifiedPosition") 
	
end

--=========
-- 装载控件
--=========
function ShuangDan_AllRewards_LoadControl()

	g_ShuangDan_AllRewards_Button[1] = {
		ShuangDan_AllRewards_Reward1_Item1, 
		ShuangDan_AllRewards_Reward1_Item2, 
		ShuangDan_AllRewards_Reward1_Item3,
		ShuangDan_AllRewards_Reward1_Item4,
		ShuangDan_AllRewards_Reward1_Item5,
	}
	g_ShuangDan_AllRewards_Button[2] = {
		ShuangDan_AllRewards_Reward2_Item1, 
		ShuangDan_AllRewards_Reward2_Item2, 
		ShuangDan_AllRewards_Reward2_Item3,
		ShuangDan_AllRewards_Reward2_Item4,
		ShuangDan_AllRewards_Reward2_Item5,
	} 
	g_ShuangDan_AllRewards_Button[3] = {
		ShuangDan_AllRewards_Reward3_Item1, 
		ShuangDan_AllRewards_Reward3_Item2, 
		ShuangDan_AllRewards_Reward3_Item3,
		ShuangDan_AllRewards_Reward3_Item4,
		ShuangDan_AllRewards_Reward3_Item5,
	}
	g_ShuangDan_AllRewards_Button[4] = {
		ShuangDan_AllRewards_Reward4_Item1, 
		ShuangDan_AllRewards_Reward4_Item2, 
		ShuangDan_AllRewards_Reward4_Item3,
		ShuangDan_AllRewards_Reward4_Item4,
		ShuangDan_AllRewards_Reward4_Item5,
	}
	g_ShuangDan_AllRewards_Button[5] = {
		ShuangDan_AllRewards_Reward5_Item1, 
		ShuangDan_AllRewards_Reward5_Item2, 
		ShuangDan_AllRewards_Reward5_Item3,
		ShuangDan_AllRewards_Reward5_Item4,
		ShuangDan_AllRewards_Reward5_Item5,
	}
	g_ShuangDan_AllRewards_Button[6] = {
		ShuangDan_AllRewards_Reward6_Item1, 
		ShuangDan_AllRewards_Reward6_Item2, 
		ShuangDan_AllRewards_Reward6_Item3,
		ShuangDan_AllRewards_Reward6_Item4,
		ShuangDan_AllRewards_Reward6_Item5,
	}
	
end

--=========
-- Event
--=========
function ShuangDan_AllRewards_OnEvent(event) 

	if(event == "UI_COMMAND" and tonumber(arg0) == 88882002) then
	
		if this:IsVisible() then
			ShuangDan_AllRewards_Close()
			return
		end
		
		ShuangDan_AllRewards_Open() 
		
		this:Show()
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		ShuangDan_AllRewards_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		ShuangDan_AllRewards_Close()

	elseif event == "ADJEST_UI_POS" then

		ShuangDan_AllRewards_On_ResetPos()
		
	end

end
 
--=========
-- 重置
--=========
function ShuangDan_AllRewards_On_ResetPos()

	ShuangDan_AllRewards_Frame:SetProperty("UnifiedPosition", g_ShuangDan_AllRewards_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function ShuangDan_AllRewards_Close() 
	this:Hide()
end

--=========
-- 打开
--=========
function ShuangDan_AllRewards_Open() 
	
	for i = 1, table.getn(g_ShuangDan_AllRewards_Button) do
		for j = 1, table.getn(g_ShuangDan_AllRewards_Button[i]) do
			g_ShuangDan_AllRewards_Button[i][j]:Hide()
			
			local kajiType = KaJi:LuaFnGetKaJiType(34)
			if kajiType == 1 then
				if g_ShuangDan_AllRewards_KJItemList[i] ~= nil and g_ShuangDan_AllRewards_KJItemList[i][j] ~= nil then
					local theAction = DataPool:CreateActionItemForShow(g_ShuangDan_AllRewards_KJItemList[i][j].itemid, g_ShuangDan_AllRewards_KJItemList[i][j].itemnum)
					if theAction:GetID() ~= 0 then
						g_ShuangDan_AllRewards_Button[i][j]:SetActionItem(theAction:GetID());
						g_ShuangDan_AllRewards_Button[i][j]:Show();
					end
				end
			else
				if g_ShuangDan_AllRewards_ItemList[i] ~= nil and g_ShuangDan_AllRewards_ItemList[i][j] ~= nil then
					local theAction = DataPool:CreateActionItemForShow(g_ShuangDan_AllRewards_ItemList[i][j].itemid, g_ShuangDan_AllRewards_ItemList[i][j].itemnum)
					if theAction:GetID() ~= 0 then
						g_ShuangDan_AllRewards_Button[i][j]:SetActionItem(theAction:GetID());
						g_ShuangDan_AllRewards_Button[i][j]:Show();
					end
				end
			end
		end
	end
	
end

