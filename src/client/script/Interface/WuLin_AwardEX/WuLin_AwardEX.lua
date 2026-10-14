-- 武林之巅 首通奖励

-- 保存UI默认位置
local WuLin_AwardEX_UnifiedPosition = nil

-- 关注NPC
local WuLin_AwardEX_CareObjId = -1
local WuLin_AwardEX_CareObjSvrId = -1
local WuLin_AwardEX_MAX_OBJ_DISTANCE = 5.0

local g_WuLin_AwardEX_CurWeekAwardList_Content = {}
local g_WuLin_AwardEX_LastWeekAwardList_Content = {}

local g_WuLin_AwardEX_CurWeek =
{
	"WuLin_AwardEX_Lace2CoinAItemOption1",
	"WuLin_AwardEX_Lace2CoinAItemOption2",
	"WuLin_AwardEX_Lace2CoinAItemOption3",
	"WuLin_AwardEX_Lace2CoinAItemOption4",
	"WuLin_AwardEX_Lace2CoinAItemOption5",
	"WuLin_AwardEX_Lace2CoinAItemOption6",
	"WuLin_AwardEX_Lace2CoinAItemOption7",
} -- end g_WuLin_AwardEX_CurWeek

local g_WuLin_AwardEX_LastWeek =
{
	"WuLin_AwardEX_LaceCoinAItemOption1",
	"WuLin_AwardEX_LaceCoinAItemOption2",
	"WuLin_AwardEX_LaceCoinAItemOption3",
	"WuLin_AwardEX_LaceCoinAItemOption4",
	"WuLin_AwardEX_LaceCoinAItemOption5",
	"WuLin_AwardEX_LaceCoinAItemOption6",
	"WuLin_AwardEX_LaceCoinAItemOption7",
	"WuLin_AwardEX_LaceCoinAItemOption8",
	"WuLin_AwardEX_LaceCoinAItemOption9",
	"WuLin_AwardEX_LaceCoinAItemOption10",
	"WuLin_AwardEX_LaceCoinAItemOption11",
	"WuLin_AwardEX_LaceCoinAItemOption12",
	"WuLin_AwardEX_LaceCoinAItemOption13",
	"WuLin_AwardEX_LaceCoinAItemOption14",
	"WuLin_AwardEX_LaceCoinAItemOption15",
} -- end g_WuLin_AwardEX_LastWeek

local g_WuLin_AwardEX_Str =
{
	{1,9},
	{10,19},
	{20,29},
	{30,39},
	{40,49},
	{50,59},
	{60,69},
	{70,79},
	{80,89},
	{90,99},
	{100,100},
} -- end g_WuLin_AwardEX_Str

local g_WuLin_AwardEX_CurWeekAwardList =
{
	-- 1 ~ 9层
	[1] =
	{
		[1] = {itemid = 39922475, itemnum = 1},
		[2] = {itemid = 39922174, itemnum = 2},
		[3] = {itemid = 39922175, itemnum = 8},
		[4] = {itemid = 39922466, itemnum = 100},
		[5] = {itemid = 39922431, itemnum = 1},
		[6] = {itemid = 39922441, itemnum = 1},
	},
	-- 10 ~ 19层
	[2] =
	{
		[1] = {itemid = 39922476, itemnum = 1},
		[2] = {itemid = 39922174, itemnum = 3},
		[3] = {itemid = 39922175, itemnum = 3},
		[4] = {itemid = 39922466, itemnum = 120},
		[5] = {itemid = 39922431, itemnum = 5},
		[6] = {itemid = 39922442, itemnum = 1},
	},
	-- 20 ~ 29层
	[3] =
	{
		[1] = {itemid = 39922477, itemnum = 1},
		[2] = {itemid = 39922174, itemnum = 3},
		[3] = {itemid = 39922175, itemnum = 3},
		[4] = {itemid = 39922466, itemnum = 140},
		[5] = {itemid = 39922431, itemnum = 10},
		[6] = {itemid = 39922443, itemnum = 1},
	},
	-- 30 ~ 39层
	[4] =
	{
		[1] = {itemid = 39922478, itemnum = 1},
		[2] = {itemid = 39922174, itemnum = 3},
		[3] = {itemid = 39922175, itemnum = 7},
		[4] = {itemid = 39922466, itemnum = 160},
		[5] = {itemid = 39922431, itemnum = 12},
		[6] = {itemid = 39922444, itemnum = 1},
	},
	-- 40 ~ 49层
	[5] =
	{
		[1] = {itemid = 39922479, itemnum = 1},
		[2] = {itemid = 39922174, itemnum = 3},
		[3] = {itemid = 39922175, itemnum = 7},
		[4] = {itemid = 39922466, itemnum = 200},
		[5] = {itemid = 39922431, itemnum = 12},
		[6] = {itemid = 39922445, itemnum = 1},
	},
	-- 50 ~ 59层
	[6] =
	{
		[1] = {itemid = 39922480, itemnum = 1},
		[2] = {itemid = 39922174, itemnum = 4},
		[3] = {itemid = 39922466, itemnum = 240},
		[4] = {itemid = 39922431, itemnum = 12},
		[5] = {itemid = 39922446, itemnum = 1},
	},
	-- 60 ~ 69层
	[7] =
	{
		[1] = {itemid = 39922481, itemnum = 1},
		[2] = {itemid = 39922174, itemnum = 4},
		[3] = {itemid = 39922466, itemnum = 240},
		[4] = {itemid = 39922431, itemnum = 12},
		[5] = {itemid = 39922447, itemnum = 1},
	},
	-- 70 ~ 79层
	[8] =
	{
		[1] = {itemid = 39922482, itemnum = 1},
		[2] = {itemid = 39922174, itemnum = 4},
		[3] = {itemid = 39922175, itemnum = 1},
		[4] = {itemid = 39922466, itemnum = 240},
		[5] = {itemid = 39922431, itemnum = 12},
		[6] = {itemid = 39922448, itemnum = 1},
	},
	-- 80 ~ 89层
	[9] =
	{
		[1] = {itemid = 39922483, itemnum = 1},
		[2] = {itemid = 39922174, itemnum = 4},
		[3] = {itemid = 39922175, itemnum = 1},
		[4] = {itemid = 39922466, itemnum = 240},
		[5] = {itemid = 39922431, itemnum = 12},
		[6] = {itemid = 39922449, itemnum = 1},
	},
	-- 90 ~ 99层
	[10] =
	{
		[1] = {itemid = 39922484, itemnum = 1},
		[2] = {itemid = 39922174, itemnum = 4},
		[3] = {itemid = 39922175, itemnum = 3},
		[4] = {itemid = 39922466, itemnum = 240},
		[5] = {itemid = 39922431, itemnum = 12},
		[6] = {itemid = 39922450, itemnum = 1},
	},
	-- 100层
	[11] =
	{
		[1] = {itemid = 39922485, itemnum = 1},
		[2] = {itemid = 39922174, itemnum = 4},
		[3] = {itemid = 39922175, itemnum = 3},
		[4] = {itemid = 39922466, itemnum = 240},
		[5] = {itemid = 39922431, itemnum = 12},
		[6] = {itemid = 39922451, itemnum = 1},
	},
} -- end g_WuLin_AwardEX_CurWeekAwardList

local g_WuLin_AwardEX_LastWeekAwardList =
{
	-- 1 ~ 9层
	[1] =
	{
		-- 固定奖励展示道具
		[1] =
		{
			[1] = {itemid = 39922486, itemnum = 1},
			[2] = {itemid = 39922452, itemnum = 1},
			[3] = {itemid = 39922441, itemnum = 1}, 
		},
		-- 随机奖励展示道具
		[2] =
		{
			[1] = {itemid = 39920397, itemnum = 1},
			[2] = {itemid = 39920396, itemnum = 1},
		},
	},
	-- 10 ~ 19层
	[2] =
	{
		-- 固定奖励展示道具
		[1] =
		{
			[1] = {itemid = 39922487, itemnum = 1},
			[2] = {itemid = 39922453, itemnum = 1},
			[3] = {itemid = 39922442, itemnum = 1},
		},
		-- 随机奖励展示道具
		[2] =
		{
			[1] = {itemid = 39920397, itemnum = 1}, 
			[2] = {itemid = 39920396, itemnum = 1},
			[3] = {itemid = 39921545, itemnum = 1},
		},
	},
	-- 20 ~ 29层
	[3] =
	{
		-- 固定奖励展示道具
		[1] =
		{
			[1] = {itemid = 39922488, itemnum = 1},
			[2] = {itemid = 39922454, itemnum = 1},
			[3] = {itemid = 39922443, itemnum = 1}, 
		},
		-- 随机奖励展示道具
		[2] =
		{
			[1] = {itemid = 39920397, itemnum = 1}, 
			[2] = {itemid = 39920396, itemnum = 1},
			[3] = {itemid = 39921545, itemnum = 1}, 
		},
	},
	-- 30 ~ 39层
	[4] =
	{
		-- 固定奖励展示道具
		[1] =
		{
			[1] = {itemid = 39922489, itemnum = 1},
			[2] = {itemid = 39922455, itemnum = 1},
			[3] = {itemid = 39922444, itemnum = 1}, 
		},
		-- 随机奖励展示道具
		[2] =
		{
			[1] = {itemid = 39920397, itemnum = 1}, 
			[2] = {itemid = 39920396, itemnum = 1},
			[3] = {itemid = 39921545, itemnum = 1}, 
		},
	},
	-- 40 ~ 49层
	[5] =
	{
		-- 固定奖励展示道具
		[1] =
		{
			[1] = {itemid = 39922490, itemnum = 1},
			[2] = {itemid = 39922456, itemnum = 1},
			[3] = {itemid = 39922445, itemnum = 1},
		},
		-- 随机奖励展示道具
		[2] =
		{
			[1] = {itemid = 39920397, itemnum = 1}, 
			[2] = {itemid = 39920396, itemnum = 1},
			[3] = {itemid = 39921545, itemnum = 1},
		},
	},
	-- 50 ~ 59层
	[6] =
	{
		-- 固定奖励展示道具
		[1] =
		{
			[1] = {itemid = 39922491, itemnum = 1},
			[2] = {itemid = 39922457, itemnum = 1},
			[3] = {itemid = 39922446, itemnum = 1}, 
			[4] = {itemid = 39924312, itemnum = 1}, 
		},
		-- 随机奖励展示道具
		[2] =
		{
			[1] = {itemid = 39920397, itemnum = 1},
			[2] = {itemid = 39920396, itemnum = 1}, 
			[3] = {itemid = 39921545, itemnum = 1},
			[4] = {itemid = 39922463, itemnum = 1},
		},
	},
	-- 60 ~ 69层
	[7] =
	{
		-- 固定奖励展示道具
		[1] =
		{
			[1] = {itemid = 39922492, itemnum = 1},
			[2] = {itemid = 39922458, itemnum = 1},
			[3] = {itemid = 39922447, itemnum = 1},
			[4] = {itemid = 39924312, itemnum = 1}, 
		},
		-- 随机奖励展示道具
		[2] =
		{
			[1] = {itemid = 39920397, itemnum = 1},
			[2] = {itemid = 39920396, itemnum = 1}, 
			[3] = {itemid = 39921545, itemnum = 1},
			[4] = {itemid = 39922463, itemnum = 1},
		},
	},
	-- 70 ~ 79层
	[8] =
	{
		-- 固定奖励展示道具
		[1] =
		{
			[1] = {itemid = 39922493, itemnum = 1},
			[2] = {itemid = 39922459, itemnum = 1},
			[3] = {itemid = 39922448, itemnum = 1},
			[4] = {itemid = 39924312, itemnum = 1}, 
		},
		-- 随机奖励展示道具
		[2] =
		{
			[1] = {itemid = 39920397, itemnum = 1},
			[2] = {itemid = 39920396, itemnum = 1},
			[3] = {itemid = 39921545, itemnum = 1}, 
			[4] = {itemid = 39922463, itemnum = 1},
			[5] = {itemid = 39922422, itemnum = 1},
		},
	},
	-- 80 ~ 89层
	[9] =
	{
		-- 固定奖励展示道具
		[1] =
		{
			[1] = {itemid = 39922494, itemnum = 1},
			[2] = {itemid = 39922460, itemnum = 1},
			[3] = {itemid = 39922449, itemnum = 1},
			[4] = {itemid = 39924313, itemnum = 1}, 
		},
		-- 随机奖励展示道具
		[2] =
		{
			[1] = {itemid = 39920397, itemnum = 1},
			[2] = {itemid = 39920396, itemnum = 1}, 
			[3] = {itemid = 39921545, itemnum = 1}, 
			[4] = {itemid = 39922463, itemnum = 1},
			[5] = {itemid = 39922422, itemnum = 1},
			[6] = {itemid = 39922423, itemnum = 2},
		},
	},
	-- 90 ~ 99层
	[10] =
	{
		-- 固定奖励展示道具
		[1] =
		{
			[1] = {itemid = 39922495, itemnum = 1},
			[2] = {itemid = 39922461, itemnum = 1},
			[3] = {itemid = 39922450, itemnum = 1},
			[4] = {itemid = 39924313, itemnum = 1}, 
		},
		-- 随机奖励展示道具
		[2] =
		{
			[1] = {itemid = 39920397, itemnum = 1},
			[2] = {itemid = 39920396, itemnum = 1},
			[3] = {itemid = 39921545, itemnum = 1}, 
			[4] = {itemid = 39922463, itemnum = 1},
			[5] = {itemid = 39922422, itemnum = 2},
			[6] = {itemid = 39922423, itemnum = 3},
		},
	},
	[11] =
	{
		-- 固定奖励展示道具
		[1] =
		{
			[1] = {itemid = 39922496, itemnum = 1},
			[2] = {itemid = 39922462, itemnum = 1},
			[3] = {itemid = 39922451, itemnum = 1},
			[4] = {itemid = 39924314, itemnum = 1}, 
		},
		-- 随机奖励展示道具
		[2] =
		{
			[1] = {itemid = 39920397, itemnum = 1},
			[2] = {itemid = 39920396, itemnum = 1},
			[3] = {itemid = 39921545, itemnum = 1}, 
			[4] = {itemid = 39922463, itemnum = 1},
			[5] = {itemid = 39922422, itemnum = 3},
			[6] = {itemid = 39922423, itemnum = 5},
			[7] = {itemid = 39922464, itemnum = 1},
			[8] = {itemid = 39922465, itemnum = 1},
		},
	},
} -- end g_WuLin_AwardEX_LastWeekAwardList

-- 最大层数
local WuLin_AwardEX_MaxStage = 100

----------多倍历练-----------------
local g_DuoBeiLiLian_StartTime = 20260813
local g_DuoBeiLiLian_EndTime = 20260912

local g_DuoBeiLiLian_TimeList = {
	[1] = {BeginTime=20260817, tips="#{DBLL_200628_39}"},
	[2] = {BeginTime=20260824, tips="#{DBLL_200628_64}"},
	[3] = {BeginTime=20260831, tips="#{DBLL_200628_65}"},
	[4] = {BeginTime=20260907, tips="#{DBLL_200628_66}"},
	--[5] = {BeginTime=20201207, tips="#{DBLL_200628_70}"},
}

function WuLin_AwardEX_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("WLZD_OPEN_WEEKAWARD", true)
	this:RegisterEvent("WLZD_CLOSE_ALL", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func WuLin_AwardEX_PreLoad()

function WuLin_AwardEX_OnLoad()
	WuLin_AwardEX_UnifiedPosition = WuLin_AwardEX_Frame:GetProperty("UnifiedPosition")
end -- end func WuLin_AwardEX_OnLoad()

function WuLin_AwardEX_OnEvent(event)
	if (event == "WLZD_OPEN_WEEKAWARD") then
		if (this:IsVisible()) then
			WuLin_AwardEX_Hide()
		end
		
		WuLin_AwardEX_BeginCareObject(arg0, arg1)		
	
		WuLin_AwardEX_Show()
		
	elseif (event == "WLZD_CLOSE_ALL") then
		WuLin_AwardEX_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		WuLin_AwardEX_Hide()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= WuLin_AwardEX_CareObjId) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2)>WuLin_AwardEX_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			--取消关心
			WuLin_AwardEX_Hide()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_AwardEX_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		WuLin_AwardEX_UnifiedPos()
	end
end -- end func WuLin_AwardEX_OnEvent()

-- 界面默认位置
function WuLin_AwardEX_UnifiedPos()
	if (WuLin_AwardEX_UnifiedPosition ~= nil) then
		WuLin_AwardEX_Frame:SetProperty("UnifiedPosition", WuLin_AwardEX_UnifiedPosition)
	end
end -- end func WuLin_AwardEX_UnifiedPos()

-- 开启UI
function WuLin_AwardEX_Show()
	-- 测试、调试用 用于清除替代奖励物品的
	--DataPool:ClearActionItemForShow()
	
	this:Show()
	
	WuLin_AwardEX_FenYe( 1 )
		
	-- 单次奖励
	WuLin_AwardEX_UpdateCurWeekAward()	
	
	-- 周结算
	WuLin_AwardEX_UpdateLastWeekAward()	
end -- end func WuLin_AwardEX_Show()

-- 关闭UI
function WuLin_AwardEX_Hide()
	-- 测试、调试用 用于清除替代奖励物品的
	--DataPool:ClearActionItemForShow()
	WuLin_AwardEX_StopCareObject(WuLin_AwardEX_CareObjId)	
	
	for i = 1, table.getn(g_WuLin_AwardEX_CurWeekAwardList) do
		for j = 1, table.getn(g_WuLin_AwardEX_CurWeekAwardList[i]) do
			if (g_WuLin_AwardEX_CurWeekAwardList_Content[i] ~= nil) then
				g_WuLin_AwardEX_CurWeekAwardList_Content[i]:GetSubItem(g_WuLin_AwardEX_CurWeek[j]):SetActionItem(-1)
			end
		end
	end	
	WuLin_AwardEX_Lace2:Clear()
	g_WuLin_AwardEX_CurWeekAwardList_Content = {}
	
	for i = 1, table.getn(g_WuLin_AwardEX_LastWeekAwardList) do
		for j = 1, table.getn(g_WuLin_AwardEX_LastWeekAwardList[i]) do
			if (g_WuLin_AwardEX_LastWeekAwardList_Content[i] ~= nil) then
				g_WuLin_AwardEX_LastWeekAwardList_Content[i]:GetSubItem(g_WuLin_AwardEX_LastWeek[j]):SetActionItem(-1)
			end
		end
	end	
	WuLin_AwardEX_Lace:Clear()
	g_WuLin_AwardEX_LastWeekAwardList_Content = {}				
	
	this:Hide()
end -- end func WuLin_AwardEX_Hide()

-- 点击分页
function WuLin_AwardEX_FenYe( nBtn )
	if nBtn == 2 then
		WuLin_AwardEX_FenYe2:SetCheck(1)
		WuLin_AwardEX_ListFrame:Show()
		WuLin_AwardEX_List2Frame:Hide()
		WuLin_AwardEX_LeftText:Hide()
	else

		WuLin_AwardEX_FenYe1:SetCheck(1)
		WuLin_AwardEX_ListFrame:Hide()
		WuLin_AwardEX_List2Frame:Show()
		if (WuLinZhiDian:IsDoubleAwardTime() == 1) then
			-- 双倍活动期间
			WuLin_AwardEX_LeftText:Show()
		else
			WuLin_AwardEX_LeftText:Hide()
		end
		--多倍历练
		local curDay = tonumber(DataPool:GetServerDayTime())
		if curDay >= g_DuoBeiLiLian_StartTime and curDay <= g_DuoBeiLiLian_EndTime then
			local tips = ""
			for i = 1, table.getn(g_DuoBeiLiLian_TimeList) do
				if curDay >= g_DuoBeiLiLian_TimeList[i].BeginTime then
					tips = g_DuoBeiLiLian_TimeList[i].tips
				end
			end
			WuLin_AwardEX_LeftText:Show()
			WuLin_AwardEX_LeftText:SetText(tips)
		else
			WuLin_AwardEX_LeftText:Hide()
		end
	end
end

-- 更新本周次数奖励
function WuLin_AwardEX_UpdateCurWeekAward()

	for i = 1, table.getn(g_WuLin_AwardEX_CurWeekAwardList) do
		for j = 1, table.getn(g_WuLin_AwardEX_CurWeekAwardList[i]) do
			if (g_WuLin_AwardEX_CurWeekAwardList_Content[i] ~= nil) then
				g_WuLin_AwardEX_CurWeekAwardList_Content[i]:GetSubItem(g_WuLin_AwardEX_CurWeek[j]):SetActionItem(-1)
			end
		end
	end	
	
	WuLin_AwardEX_Lace2:Clear()
	g_WuLin_AwardEX_CurWeekAwardList_Content = {}
	
	for i = 1, table.getn(g_WuLin_AwardEX_CurWeekAwardList) do		
		local child = WuLin_AwardEX_Lace2:AddChild("WuLin_AwardEX_Lace2CoinAItem")
		if nil ~= child then
			if i == 11 then
				local str = ScriptGlobal_Format("#{PTFB_191228_288}", g_WuLin_AwardEX_Str[i][1])
				child:GetSubItem("WuLin_AwardEX_Lace2CoinAItemOptionText"):SetText( str )
			else
				local str = ScriptGlobal_Format("#{PTFB_191228_287}", g_WuLin_AwardEX_Str[i][1], g_WuLin_AwardEX_Str[i][2])
				child:GetSubItem("WuLin_AwardEX_Lace2CoinAItemOptionText"):SetText( str )
			end
				
			for idx = 1, table.getn(g_WuLin_AwardEX_CurWeek) do
				child:GetSubItem(g_WuLin_AwardEX_CurWeek[idx]):Hide()
			end
						
			for j = 1, table.getn(g_WuLin_AwardEX_CurWeekAwardList[i]) do
				if (g_WuLin_AwardEX_CurWeekAwardList[i][j] ~= nil) then
					local itemid = g_WuLin_AwardEX_CurWeekAwardList[i][j].itemid
					local itemnum = g_WuLin_AwardEX_CurWeekAwardList[i][j].itemnum
					local theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
					if theAction:GetID() ~= 0 then
						child:GetSubItem(g_WuLin_AwardEX_CurWeek[j]):Show()
						child:GetSubItem(g_WuLin_AwardEX_CurWeek[j]):SetActionItem(theAction:GetID())
					end
				end
			end
			
			g_WuLin_AwardEX_CurWeekAwardList_Content[i] = child
		end
	end -- end for
end -- end func WuLin_AwardEX_UpdateCurWeekAward()

-- 更新上周结算奖励
function WuLin_AwardEX_UpdateLastWeekAward()
	
	for i = 1, table.getn(g_WuLin_AwardEX_LastWeekAwardList) do
		for j = 1, table.getn(g_WuLin_AwardEX_LastWeekAwardList[i]) do
			if (g_WuLin_AwardEX_LastWeekAwardList_Content[i] ~= nil) then
				g_WuLin_AwardEX_LastWeekAwardList_Content[i]:GetSubItem(g_WuLin_AwardEX_LastWeek[j]):SetActionItem(-1)
			end
		end
	end		
	
	WuLin_AwardEX_Lace:Clear()
	g_WuLin_AwardEX_LastWeekAwardList_Content = {}
	
	for i = 1, table.getn(g_WuLin_AwardEX_LastWeekAwardList) do	
		local child = WuLin_AwardEX_Lace:AddChild("WuLin_AwardEX_LaceCoinAItem")
		if nil ~= child then
			if i == 11 then
				local str = ScriptGlobal_Format("#{PTFB_191228_288}", g_WuLin_AwardEX_Str[i][1])
				child:GetSubItem("WuLin_AwardEX_LaceCoinAItemOptionText"):SetText( str )
			else
				local str = ScriptGlobal_Format("#{PTFB_191228_287}", g_WuLin_AwardEX_Str[i][1], g_WuLin_AwardEX_Str[i][2])
				child:GetSubItem("WuLin_AwardEX_LaceCoinAItemOptionText"):SetText( str )
			end
			
			for idx = 1, table.getn(g_WuLin_AwardEX_LastWeek) do
				child:GetSubItem(g_WuLin_AwardEX_LastWeek[idx]):Hide()
			end

			-- 固定道具展示（最多5个展示位 1~5）
			for j = 1, 5, 1 do
				if (g_WuLin_AwardEX_LastWeekAwardList[i][1][j] ~= nil) then
					local itemid = g_WuLin_AwardEX_LastWeekAwardList[i][1][j].itemid
					local itemnum = g_WuLin_AwardEX_LastWeekAwardList[i][1][j].itemnum
					local theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
					if theAction:GetID() ~= 0 then
						child:GetSubItem(g_WuLin_AwardEX_LastWeek[j]):Show()
						child:GetSubItem(g_WuLin_AwardEX_LastWeek[j]):SetActionItem(theAction:GetID())
					end
				end
			end -- end for

			-- 随机道具展示（最多10个展示位 6~15）
			for j = 6, 15, 1 do
				if (g_WuLin_AwardEX_LastWeekAwardList[i][2][j-5] ~= nil) then
					local itemid = g_WuLin_AwardEX_LastWeekAwardList[i][2][j-5].itemid
					local itemnum = g_WuLin_AwardEX_LastWeekAwardList[i][2][j-5].itemnum
					local theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
					if theAction:GetID() ~= 0 then
						child:GetSubItem(g_WuLin_AwardEX_LastWeek[j]):Show()
						child:GetSubItem(g_WuLin_AwardEX_LastWeek[j]):SetActionItem(theAction:GetID())
					end
				end
			end -- end for
			
			g_WuLin_AwardEX_LastWeekAwardList_Content[i] = child
		end
	end -- end for
end -- end func WuLin_AwardEX_UpdateLastWeekAward()

-- 关闭按钮事件
function WuLin_AwardEX_Close()
	WuLin_AwardEX_Hide()
end -- end func WuLin_AwardEX_Close()

-- 开启NPC关注
function WuLin_AwardEX_BeginCareObject(objSvrId, objId)
	WuLin_AwardEX_CareObjId = tonumber(objId)
	WuLin_AwardEX_CareObjSvrId = tonumber(objSvrId)
	if (WuLin_AwardEX_CareObjId >= 0) then
		this:CareObject(WuLin_AwardEX_CareObjId, 1, "WuLin_AwardEX")
	end
end -- end func WuLin_Team_BeginCareObject()

-- 取消NPC关注
function WuLin_AwardEX_StopCareObject(objId)
	if (tonumber(objId) >= 0) then
		this:CareObject(objId, 0, "WuLin_AwardEX")
		WuLin_AwardEX_CareObjId = -1
		WuLin_AwardEX_CareObjSvrId = -1
	end
end -- end func WuLin_Team_StopCareObject()