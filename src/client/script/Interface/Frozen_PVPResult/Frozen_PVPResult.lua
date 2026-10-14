-- 雪人大作战，分数界面
local g_unifiedposistion


local g_camp_info = 
{
	{name="#{BXDZ_240918_182}",},
	{name="#{BXDZ_240918_183}",},
	{name="#{BXDZ_240918_184}",},
	{name="#{BXDZ_240918_185}",},
	{name="#{BXDZ_240918_186}",},
	{name="#{BXDZ_240918_186}",},
}

local g_reward_info = 
{
	level = 
	{
		[1] = { item=nil, num=nil, item2=nil, num2=nil, },
		[2] = { item=nil, num=nil, item2=nil, num2=nil, },
		[3] = { item=nil, num=nil, item2=nil, num2=nil, },
		[4] = { item=nil, num=nil, item2=nil, num2=nil, },
		[5] = { item=39924853, num=1, item2=nil, num2=nil, },
		[6] = { item=39924853, num=1, item2=nil, num2=nil, },
		[7] = { item=39924854, num=1, item2=nil, num2=nil, },
		[8] = { item=39924854, num=1, item2=nil, num2=nil, },
		[9] = { item=39924855, num=1, item2=nil, num2=nil, },
		[10] = { item=39924855, num=1, item2=nil, num2=nil, },
	},
	rank = 
	{
		[1] = { item=39925091, num=6, item2=nil, num2=nil, },
		[2] = { item=39925091, num=5, item2=nil, num2=nil, },
		[3] = { item=39925091, num=4, item2=nil, num2=nil, },
		[4] = { item=nil, num=nil, item2=nil, num2=nil, },
		[5] = { item=nil, num=nil, item2=nil, num2=nil, },
	},
	level_kj = 
	{
		[1] = { item=nil, num=nil, item2=nil, num2=nil, },
		[2] = { item=nil, num=nil, item2=nil, num2=nil, },
		[3] = { item=nil, num=nil, item2=nil, num2=nil, },
		[4] = { item=nil, num=nil, item2=nil, num2=nil, },
		[5] = { item=39924856, num=1, item2=nil, num2=nil, },
		[6] = { item=39924856, num=1, item2=nil, num2=nil, },
		[7] = { item=39924857, num=1, item2=nil, num2=nil, },
		[8] = { item=39924857, num=1, item2=nil, num2=nil, },
		[9] = { item=39924858, num=1, item2=nil, num2=nil, },
		[10] = { item=39924858, num=1, item2=nil, num2=nil, },
	},
	rank_kj = 
	{
		[1] = { item=39925091, num=6, item2=nil, num2=nil, },
		[2] = { item=39925091, num=5, item2=nil, num2=nil, },
		[3] = { item=39925091, num=4, item2=nil, num2=nil, },
		[4] = { item=nil, num=nil, item2=nil, num2=nil, },
		[5] = { item=nil, num=nil, item2=nil, num2=nil, },
	},
}

function Frozen_PVPResult_PreLoad()
	this:RegisterEvent("XRZPVP_BATTLERESULT_SHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Frozen_PVPResult_OnLoad()

	-- 保存界面的默认相对位置
	g_unifiedposistion = Frozen_PVPResult_Frame:GetProperty("UnifiedPosition")
end

function Frozen_PVPResult_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		Frozen_PVPResult_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Frozen_PVPResult_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED")	 then
		Frozen_PVPResult_CloseClicked()
	elseif(event == "XRZPVP_BATTLERESULT_SHOW") then
		Frozen_PVPResult_OnShow()
	end
end

function Frozen_PVPResult_OnShow()
	local ret = Frozen_PVPResult_InitUIData()
	if ret > 0 then
		this:Show()
	else
		this:Hide()
	end
end

-- 初始化控件数据
function Frozen_PVPResult_InitUIData(lastTime)

	local data = XRZPVP:GetBattleBaseInfo()
	if data == nil or type(data) ~= "table" then
		this:Hide()
		return -1
	end

	-- 显示剩余时间
	if data.lefttime ~= nil and data.lefttime > 0 then
		Frozen_PVPResult_TopList_Time:SetProperty("Timer", data.lefttime)
	else
		Frozen_PVPResult_TopList_Time:SetProperty("Timer", 0)
	end
	Frozen_PVPResult_TopList_Time:SetProperty("TextColor", "FF00FF00")

	-- 获取自己的阵营信息
	local camp,level,exp,max,camppos = XRZPVP:GetBattleRankInfo("campinfo")

	-- 刷新阵营信息
	local teamCount = XRZPVP:GetBattleRankInfo("teamnum")
	Frozen_PVPResult_TopList_ListFrame:Clear()
	if (teamCount > 0) then
		for i=1, teamCount, 1 do
			local snowDataValid = XRZPVP:GetBattleRankInfo("isvalid", i-1)
			if snowDataValid ~= nil and snowDataValid > 0 then
				local child = Frozen_PVPResult_TopList_ListFrame:AddChild("Frozen_PVPResult_TopList_List_Item")
				if (child ~= nil) then
					-- 是否是自己的阵营
					if i == camp then
					end
					local snowStackScore,playerCamp = XRZPVP:GetBattleRankInfo("rankinfo", i-1)
					local maxlevel = XRZPVP:GetBattleRankInfo("maxlevel", i-1)

					local strRank = tostring(i)
					local strCampName = g_camp_info[i].name
					if g_camp_info[playerCamp+1] ~= nil then
						strCampName = g_camp_info[playerCamp+1].name
					end
					local strScore = ScriptGlobal_Format("#{BXDZ_240918_187}", snowStackScore)
					local strLevel = tostring(maxlevel)

					child:GetSubItem("Frozen_PVPResult_TopList_List_Rank"):SetText("#cfff263"..strRank)
					child:GetSubItem("Frozen_PVPResult_TopList_List_Camp"):SetText(strCampName)
					child:GetSubItem("Frozen_PVPResult_TopList_List_SnowManNum"):SetText(strScore)
					child:GetSubItem("Frozen_PVPResult_TopList_List_SnowManLevel"):SetText("#cfff263"..strLevel)

					child:GetSubItem("Frozen_PVPResult_TopList_RankAward1"):SetActionItem(-1)
					child:GetSubItem("Frozen_PVPResult_TopList_RankAward2"):SetActionItem(-1)
					child:GetSubItem("Frozen_PVPResult_TopList_LevelAward1"):SetActionItem(-1)
					child:GetSubItem("Frozen_PVPResult_TopList_LevelAward2"):SetActionItem(-1)

					if playerCamp == camppos then
						child:GetSubItem("Frozen_PVPResult_TopList_List_ItemBK"):Show()
					else
						child:GetSubItem("Frozen_PVPResult_TopList_List_ItemBK"):Hide()
					end
					
					local rankReward = nil
					if KaJi:LuaFnIsKaJiServer() ~= 1 then
						rankReward = g_reward_info.rank[i]
					else
						rankReward = g_reward_info.rank_kj[i]
					end
					if snowStackScore > 0 and rankReward ~= nil then
						if rankReward.item ~= nil then
							local action = DataPool:CreateActionItemForShow(rankReward.item, rankReward.num)
							if action:GetID() ~= 0 then
								child:GetSubItem("Frozen_PVPResult_TopList_RankAward1"):SetActionItem(action:GetID())
							end
						end
						if rankReward.item2 ~= nil then
							local action = DataPool:CreateActionItemForShow(rankReward.item2, rankReward.num2)
							if action:GetID() ~= 0 then
								child:GetSubItem("Frozen_PVPResult_TopList_RankAward2"):SetActionItem(action:GetID())
							end
						end
					end

					local levelReward = nil
					if KaJi:LuaFnIsKaJiServer() ~= 1 then
						levelReward = g_reward_info.level[maxlevel]
					else
						levelReward = g_reward_info.level_kj[maxlevel]
					end
					if snowStackScore > 0 and levelReward ~= nil then
						if levelReward.item ~= nil then
							local action = DataPool:CreateActionItemForShow(levelReward.item, levelReward.num)
							if action:GetID() ~= 0 then
								child:GetSubItem("Frozen_PVPResult_TopList_LevelAward1"):SetActionItem(action:GetID())
							end
						end
						if levelReward.item2 ~= nil then
							local action = DataPool:CreateActionItemForShow(levelReward.item2, levelReward.num2)
							if action:GetID() ~= 0 then
								child:GetSubItem("Frozen_PVPResult_TopList_LevelAward2"):SetActionItem(action:GetID())
							end
						end
					end
				end
			end
		end
	end
	
	return 1
end

function Frozen_PVPResult_OK()
	
end

function Frozen_PVPResult_TransformName(name, zoneid)
	if zoneid < 0 then
		return name
	end

	local retname = name
	if g_trasname > 0 then
		local selfzoneid = DataPool:GetSelfZoneWorldID()
		if selfzoneid ~= zoneid then
			local serverName = DataPool:GetServerName( zoneid )
			retname = name.."@"..tostring(serverName)
		end
	end

	return retname
end

--================================================
-- 开启个人榜
--================================================
function Frozen_PVPResult_TopList()
	PushEvent("XRZPVP_BATTLERANK_SHOW")
end

--================================================
-- 最小化
--================================================
function Frozen_PVPResult_Mini()
	
end

--================================================
-- 关闭
--================================================
function Frozen_PVPResult_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_PVPResult_ResetPos()
	Frozen_PVPResult_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

