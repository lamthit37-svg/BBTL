
local g_Feihua_RankingList_UnifiedPosition
local g_RankTalbe = {}
local g_RangCount = 8

local g_XuYuanDian = 
{
	[1] = "#{FHJY_211025_56}",
	[2] = "#{FHJY_211025_57}",
	[3] = "#{FHJY_211025_58}",
}
local g_CangHuaQuanItemId = 38005568

local g_SuperCangHuaQuanItemId = 38005580

local g_Begintime = 20221215
local g_Endtime = 20230104

local g_LevelUpRewardStartDay = 20221231
local g_LevelUpRewardEndDay = 20230101

function Feihua_RankingList_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- this:RegisterEvent("Open_Feihua_RankingList",true)
	this:RegisterEvent("Refresh_Feihua_RankingList",false)
end

function Feihua_RankingList_OnLoad()
	g_Feihua_RankingList_UnifiedPosition = Feihua_RankingList_FrameNULL:GetProperty("UnifiedPosition")
	g_RankTalbe = 
	{
		[1] = 
		{
			NameLabel = Feihua_RankingList_ListInfo1_Name, 
			ItemLabel = Feihua_RankingList_ListInfo1_Gift, 
			XuYuanDianLabel = Feihua_RankingList_ListInfo1_Place,
			NoPlayerLabel = Feihua_RankingList_ListInfo1_Null,
			BestRewardLabel = Feihua_RankingList_ListInfo1_Best,
			NameBK = Feihua_RankingList_ListInfo1_NameBK,
			NullBK = Feihua_RankingList_ListInfo1_NullBK,
		},
		[2] = 
		{
			NameLabel = Feihua_RankingList_ListInfo2_Name, 
			ItemLabel = Feihua_RankingList_ListInfo2_Gift, 
			XuYuanDianLabel = Feihua_RankingList_ListInfo2_Place,
			NoPlayerLabel = Feihua_RankingList_ListInfo2_Null,
			BestRewardLabel = Feihua_RankingList_ListInfo2_Best,
			NameBK = Feihua_RankingList_ListInfo2_NameBK,
			NullBK = Feihua_RankingList_ListInfo2_NullBK,
		},
		[3] = 
		{
			NameLabel = Feihua_RankingList_ListInfo3_Name, 
			ItemLabel = Feihua_RankingList_ListInfo3_Gift, 
			XuYuanDianLabel = Feihua_RankingList_ListInfo3_Place,
			NoPlayerLabel = Feihua_RankingList_ListInfo3_Null,
			BestRewardLabel = Feihua_RankingList_ListInfo3_Best,
			NameBK = Feihua_RankingList_ListInfo3_NameBK,
			NullBK = Feihua_RankingList_ListInfo3_NullBK,
		},
		[4] = 
		{
			NameLabel = Feihua_RankingList_ListInfo4_Name, 
			ItemLabel = Feihua_RankingList_ListInfo4_Gift, 
			XuYuanDianLabel = Feihua_RankingList_ListInfo4_Place,
			NoPlayerLabel = Feihua_RankingList_ListInfo4_Null,
			BestRewardLabel = Feihua_RankingList_ListInfo4_Best,
			NameBK = Feihua_RankingList_ListInfo4_NameBK,
			NullBK = Feihua_RankingList_ListInfo4_NullBK,
		},
		[5] = 
		{
			NameLabel = Feihua_RankingList_ListInfo5_Name, 
			ItemLabel = Feihua_RankingList_ListInfo5_Gift, 
			XuYuanDianLabel = Feihua_RankingList_ListInfo5_Place,
			NoPlayerLabel = Feihua_RankingList_ListInfo5_Null,
			BestRewardLabel = Feihua_RankingList_ListInfo5_Best,
			NameBK = Feihua_RankingList_ListInfo5_NameBK,
			NullBK = Feihua_RankingList_ListInfo5_NullBK,
		},
		[6] = 
		{
			NameLabel = Feihua_RankingList_ListInfo6_Name, 
			ItemLabel = Feihua_RankingList_ListInfo6_Gift, 
			XuYuanDianLabel = Feihua_RankingList_ListInfo6_Place,
			NoPlayerLabel = Feihua_RankingList_ListInfo6_Null,
			BestRewardLabel = Feihua_RankingList_ListInfo6_Best,
			NameBK = Feihua_RankingList_ListInfo6_NameBK,
			NullBK = Feihua_RankingList_ListInfo6_NullBK,
		},
		[7] = 
		{
			NameLabel = Feihua_RankingList_ListInfo7_Name, 
			ItemLabel = Feihua_RankingList_ListInfo7_Gift, 
			XuYuanDianLabel = Feihua_RankingList_ListInfo7_Place,
			NoPlayerLabel = Feihua_RankingList_ListInfo7_Null,
			BestRewardLabel = Feihua_RankingList_ListInfo7_Best,
			NameBK = Feihua_RankingList_ListInfo7_NameBK,
			NullBK = Feihua_RankingList_ListInfo7_NullBK,
		},
		[8] = 
		{
			NameLabel = Feihua_RankingList_ListInfo8_Name, 
			ItemLabel = Feihua_RankingList_ListInfo8_Gift, 
			XuYuanDianLabel = Feihua_RankingList_ListInfo8_Place,
			NoPlayerLabel = Feihua_RankingList_ListInfo8_Null,
			BestRewardLabel = Feihua_RankingList_ListInfo8_Best,
			NameBK = Feihua_RankingList_ListInfo8_NameBK,
			NullBK = Feihua_RankingList_ListInfo8_NullBK,
		},
	
	}
end

--点击界面上问号
function Feihua_RankingList_Help()
	PushEvent("CCSHOP_HELP", 137)
end

function Feihua_RankingList_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 2021110301) then
		Feihua_RankingList_On_ResetPos()
		Feihua_RankingList_Open()
		DataPool:Lua_AskXuYuanKaRank()
	elseif (event == "Refresh_Feihua_RankingList") then
	--显示并刷新排行榜
		Feihua_RankingList_Refresh()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Feihua_RankingList_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Feihua_RankingList_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Feihua_RankingList_Close()
	end

end

function Feihua_RankingList_On_ResetPos()
	Feihua_RankingList_FrameNULL:SetProperty("UnifiedPosition", g_Feihua_RankingList_UnifiedPosition)

end

--界面点击关闭按钮
function Feihua_RankingList_Close()
	this:Hide()
end

function Feihua_RankingList_OnHide()
	
end

--先隐藏排行榜 给服务器发消息请求排行榜的数据
function Feihua_RankingList_Open()
	this:Show()
	Feihua_RankingList_ListLace:Hide()
	
end

function Feihua_RankingList_Refresh()
	Feihua_RankingList_ListLace:Show()
	DataPool:Lua_SortXuYuanKaRankData()
	for i = 1, g_RangCount do
		local bRet, nDate, nItemId, nItemValue, nCaiJiIndex, playerName = DataPool:Lua_GetXuYuanKaRankData(i)
		-- PushDebugMessage("nDate:"..tostring(nDate))
	
		if bRet ==1 and nDate>0 then
			--显示数据 
			-- PushDebugMessage("nItemId"..nItemId)
			g_RankTalbe[i].NameBK:Show()
			g_RankTalbe[i].NullBK:Hide()

			g_RankTalbe[i].BestRewardLabel:Show()
			g_RankTalbe[i].NameLabel:Show()
			g_RankTalbe[i].ItemLabel:Show()
			g_RankTalbe[i].XuYuanDianLabel:Show()
			g_RankTalbe[i].NoPlayerLabel:Hide()
			g_RankTalbe[i].NameLabel:SetText(ScriptGlobal_Format("#{FHJY_211025_09}", playerName)) 
			g_RankTalbe[i].ItemLabel:SetText(ScriptGlobal_Format("#{FHJY_211025_10}", DataPool:Lua_GetItemNameByIndex(nItemId)))   
			g_RankTalbe[i].XuYuanDianLabel:SetText(g_XuYuanDian[nCaiJiIndex])
		else
			--显示虚位以待
			g_RankTalbe[i].NameBK:Hide()
			g_RankTalbe[i].NullBK:Show()

			g_RankTalbe[i].BestRewardLabel:Hide()
			g_RankTalbe[i].NameLabel:Hide()
			g_RankTalbe[i].ItemLabel:Hide()
			g_RankTalbe[i].XuYuanDianLabel:Hide()
			g_RankTalbe[i].NoPlayerLabel:Show()
		end
	end
end

function Feihua_RankingList_IsLevelUpReward()
	local curDay = DataPool:GetServerDayTime()
	if curDay >= g_LevelUpRewardStartDay and curDay <= g_LevelUpRewardEndDay then
		return 1
	end
	return 0 
end

function Feihua_RankingList_JudgeCondition()
	local curDay = DataPool:GetServerDayTime()
	if curDay < g_Begintime or curDay >g_Endtime then
		PushDebugMessage("#{FHJY_211025_13}")
		return 0
	end
	local nLevel = Player:GetLevel();
	if nLevel < 30  then        
		PushDebugMessage("#{FHJY_211025_03}")
		return 0
	end
	local itemcount = -1
	if Feihua_RankingList_IsLevelUpReward() == 1 then
		itemcount = PlayerPackage:CountAvailableItemByIDTable(g_SuperCangHuaQuanItemId)
		if itemcount <=0 then
			PushDebugMessage("#{FHJY_211025_71}")
			return 0
		end
	else
		itemcount = PlayerPackage:CountAvailableItemByIDTable(g_CangHuaQuanItemId)
		if itemcount <=0 then
			PushDebugMessage("#{FHJY_211025_18}")
			return 0
		end
	end
	return 1
end

--点击奖品展示按钮
-- function Feihua_RankingList_BtnGift_Click()
-- 	--判断能否打开奖品预览界面
-- 	if Feihua_RankingList_JudgeCondition() == 1 then
-- 		PushEvent("Open_Feihua_ShowGift")
-- 	end
-- end

--点击按钮红梅寻路
function Feihua_RankingList_Hongmei_Clicked()
	if Feihua_RankingList_JudgeCondition() == 0 then
		return
	end

	AutoRuntoTargetExWithName(221, 153, 2, "红梅")
	
end




--点击按钮黄梅寻路
function Feihua_RankingList_Huangmei_Clicked()
	if Feihua_RankingList_JudgeCondition() == 0 then
		return
	end

	AutoRuntoTargetExWithName(212, 161, 0, "黄梅")

end

--点击按钮白梅寻路
function Feihua_RankingList_Baimei_Clicked()
	if Feihua_RankingList_JudgeCondition() == 0 then
		return
	end

	AutoRuntoTargetExWithName(214.22, 186.93, 1, "白梅")
end