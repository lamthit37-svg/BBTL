--******************************************
--周常凤凰陵墓副本	排行榜
--******************************************

local g_ZhouchangPVE_RankingList_Frame_UnifiedPosition = nil 
local g_RequestType = 0 -- 0 本期 1 上期
local g_NpcId = -1
local objCared = -1
local g_State = 0

local g_RANKINGLIST_TYPE_FHLM_EVEN = 36 -- 双周排行榜
local g_RANKINGLIST_TYPE_FHLM_ODD = 37 -- 单周排行榜
local g_newRankingListType -- 新榜单类型
local g_oldRankingListType -- 旧榜单类型
local g_currentRankingListType -- 当前榜单类型

function ZhouchangPVE_RankingList_PreLoad()
	this:RegisterEvent("OPEN_FHLM_RANKINGLIST", true)
	this:RegisterEvent("UPDATE_FHLM_RANKINGLIST", true)

	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
end

function ZhouchangPVE_RankingList_OnLoad()
	g_ZhouchangPVE_RankingList_Frame_UnifiedPosition = ZhouchangPVE_RankingList_Frame:GetProperty("UnifiedPosition")
end

function ZhouchangPVE_RankingList_On_ResetPos()
	ZhouchangPVE_RankingList_Frame:SetProperty("UnifiedPosition", g_ZhouchangPVE_RankingList_Frame_UnifiedPosition)
end

function ZhouchangPVE_RankingList_OnEvent(event)
	if event == "OPEN_FHLM_RANKINGLIST" then
		local type = tonumber(arg0)

		g_NpcId = tonumber(arg1)
		objCared = DataPool:GetNPCIDByServerID(g_NpcId)
		ZhouchangPVE_RankingList_BeginCareObject(objCared)

		ZhouchangPVE_RankingList_OnShow(type)
	elseif event == "UPDATE_FHLM_RANKINGLIST" and this:IsVisible() then
		local type = tonumber(arg0)
		ZhouchangPVE_RankingList_OnShow(type)
	elseif(event == "ADJEST_UI_POS") then
		ZhouchangPVE_RankingList_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		ZhouchangPVE_RankingList_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		ZhouchangPVE_RankingList_CloseClicked()	
	end
end

--===============================================
-- 排行榜
--===============================================
function ZhouchangPVE_RankingList_OnShow(type)
	-- 分别记录本期和上期的排行榜类型
	if (g_RequestType == 0 and type == g_RANKINGLIST_TYPE_FHLM_EVEN)
	or (g_RequestType == 1 and type == g_RANKINGLIST_TYPE_FHLM_ODD) then
		g_newRankingListType = g_RANKINGLIST_TYPE_FHLM_EVEN
		g_oldRankingListType = g_RANKINGLIST_TYPE_FHLM_ODD
	else
		g_newRankingListType = g_RANKINGLIST_TYPE_FHLM_ODD
		g_oldRankingListType = g_RANKINGLIST_TYPE_FHLM_EVEN
	end
	-- 设置当前页签的排行榜类型
	g_currentRankingListType = type

	-- 页签和领奖按钮显示
	if g_RequestType == 0 then
		ZhouchangPVE_RankingList_Check1:SetCheck(1)
		ZhouchangPVE_RankingList_Check1:Disable()
		ZhouchangPVE_RankingList_Check2:SetCheck(0)
		ZhouchangPVE_RankingList_Check2:Enable()
		ZhouchangPVE_RankingList_GetRewards:Hide()
		ZhouchangPVE_RankingList_GetRewards_ButtonTip:Hide()
		ZhouchangPVE_RankingList_Check2_ButtonTip:Hide()
	else
		ZhouchangPVE_RankingList_Check1:SetCheck(0)
		ZhouchangPVE_RankingList_Check1:Enable()
		ZhouchangPVE_RankingList_Check2:SetCheck(1)
		ZhouchangPVE_RankingList_Check2:Disable()
		ZhouchangPVE_RankingList_GetRewards:Show()
		ZhouchangPVE_RankingList_GetRewards_ButtonTip:Hide()
		ZhouchangPVE_RankingList_Check2_ButtonTip:Hide()
	end
	-- 清空请求类型
	g_RequestType = 0
	
	ZhouchangPVE_RankingList_ListInfo:Clear()
	ZhouchangPVE_RankingList_AItem_MyRank:SetText("")
	ZhouchangPVE_RankingList_AItem_MyName:SetText("")

	local nDataCount = DataPool:lua_GetJSRankingListDataCount(g_currentRankingListType)
	if nDataCount <= 0 then
		ZhouchangPVE_RankingList_AItem_NotListed:Show()
	else
		ZhouchangPVE_RankingList_AItem_NotListed:Hide()
	end
	
	local myRank = -1
	local myRankPoint = 0
	for i = 0, nDataCount - 1 do
		local nRank, name, rankingValue, state = DataPool:lua_GetJSRankingListInfo(g_currentRankingListType, i)
		g_State = state
		for j = 1, 6 do
			local bValid, memguid, membname, menpai, level, score = DataPool:lua_GetJSRankingListMemberInfo(g_currentRankingListType, i, j - 1)
			if bValid == 1 and myRank < 0 then
				if memguid == Player:GetGUID() then
					myRank = nRank
					myRankPoint = rankingValue
				end
			end
		end
		
		local ItemBar = ZhouchangPVE_RankingList_ListInfo:AddChild("ZhouchangPVE_RankingList_AItem")
		ItemBar:GetSubItem("ZhouchangPVE_RankingList_AItem_Rank"):SetText(nRank + 1)
		ItemBar:GetSubItem("ZhouchangPVE_RankingList_AItem_Name"):SetText(name)
		ItemBar:GetSubItem("ZhouchangPVE_RankingList_Score"):SetText(rankingValue)

		local nShowItemId = DataPool:lua_GetJSRankingListRewardInfo(g_currentRankingListType, nRank * 3 + 2)
		local theAction = DataPool:CreateBindActionItemForShow(nShowItemId, 1)
		if theAction ~= nil then
			ItemBar:GetSubItem("ZhouchangPVE_RankingList_AItem_Giftimage"):SetActionItem(theAction:GetID())
		end
		ItemBar:SetEvent("MouseLClick", "ZhouchangPVE_RankingList_OnClick("..i..")")
	end	
	
	if myRank >= 0 then --上榜
		ZhouchangPVE_RankingList_FillMyInfo(myRank, myRankPoint, g_State)
	else --未上榜
		ZhouchangPVE_RankingList_FillMyInfoNone()
	end
	--可领奖
	local _, isGet = DataPool:lua_GetJSRankingListMyInfo(g_currentRankingListType)
	if isGet == 0 then --红点 这里不判断state是否为2，因为不管是本期还是上期，都要处理这个红点
		ZhouchangPVE_RankingList_Check2_ButtonTip:Show()
	else
		ZhouchangPVE_RankingList_Check2_ButtonTip:Hide()
	end
	
	--状态信息
	if g_State == 1 then -- 排名中
		ZhouchangPVE_RankingList_RefreshText:SetText("#{FHCL_240708_124}") -- 榜单将于下周一2点进行结算。
	elseif g_State == 2 then -- 已结算
		ZhouchangPVE_RankingList_RefreshText:SetText("#{FHCL_240708_125}") -- 榜单已结算，榜单将于下周一0点重置。
	else
		ZhouchangPVE_RankingList_RefreshText:SetText("")
	end
	this:Show()
end

--===============================================
-- 排行榜个人信息--未上榜
--===============================================
function ZhouchangPVE_RankingList_FillMyInfoNone()
	ZhouchangPVE_RankingList_AItem_MyRank:SetText("#{FHCL_240708_133}")
	ZhouchangPVE_RankingList_AItem_MyName:SetText(Player:GetName())
	local myPoint
	if g_currentRankingListType == g_RANKINGLIST_TYPE_FHLM_EVEN then
		myPoint = DataPool:lua_GetFHLMRankingListEvenWeekMyValue()
	else
		myPoint = DataPool:lua_GetFHLMRankingListOddWeekMyValue()
	end
	if myPoint <= 0 then
		ZhouchangPVE_RankingList_MyScore:SetText("0")
	else
		ZhouchangPVE_RankingList_MyScore:SetText(myPoint)
	end
	ZhouchangPVE_RankingList_AItem_MyGiftimage:Hide()
end

--===============================================
-- 排行榜个人信息--上榜
--===============================================
function ZhouchangPVE_RankingList_FillMyInfo(myRank, myRankPoint, state)
	ZhouchangPVE_RankingList_AItem_MyRank:SetText(myRank + 1)
	ZhouchangPVE_RankingList_AItem_MyName:SetText(Player:GetName())
	ZhouchangPVE_RankingList_MyScore:SetText(myRankPoint)
	ZhouchangPVE_RankingList_AItem_MyGiftimage:Show()
	
	if myRank >= 0 and myRank < 3 then
		local nShowItemId = DataPool:lua_GetJSRankingListRewardInfo(g_currentRankingListType, myRank * 3 + 2)
		local theAction = DataPool:CreateBindActionItemForShow(nShowItemId, 1)
		if theAction ~= nil then
			ZhouchangPVE_RankingList_AItem_MyGiftimage:SetActionItem(theAction:GetID())
		end
		
		--可领奖
		local myValue, isGet = DataPool:lua_GetJSRankingListMyInfo(g_currentRankingListType)
		if state == 2 and isGet == 0 then --红点
			ZhouchangPVE_RankingList_GetRewards_ButtonTip:Show()
			ZhouchangPVE_RankingList_Check2_ButtonTip:Show()
		end
	end
end

--===============================================
-- 团队信息
--===============================================
function ZhouchangPVE_RankingList_OnClick(index)
	PushEvent("OPEN_FHLM_RANKINGLIST_TEAM", index, g_NpcId, g_currentRankingListType)
end

--===============================================
-- 领奖
--===============================================
function ZhouchangPVE_RankingList_GetRewards_Clicked()
	DataPool:lua_GetJSRankingListGetReward(g_oldRankingListType)
	g_RequestType = 1 -- 领奖失败时会默认刷新界面，为避免切到当前周标签，标记标签为1
end

--===============================================
-- 关闭界面
--===============================================
function ZhouchangPVE_RankingList_CloseClicked()
	ZhouchangPVE_RankingList_StopCareObject()
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function ZhouchangPVE_RankingList_BeginCareObject(objCaredId)
	if objCared ~= -1 then
		this:CareObject(objCaredId, 0, "ZhouchangPVE_RankingList")
	end
	objCared = objCaredId
	this:CareObject(objCared, 1, "ZhouchangPVE_RankingList")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function ZhouchangPVE_RankingList_StopCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "ZhouchangPVE_RankingList")
		objCared = -1
	end
end

--===============================================
-- 点击分页
--===============================================
function ZhouchangPVE_RankingList_Fenye(nIndex)
	g_RequestType = nIndex - 1
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenRankingList")
		Set_XSCRIPT_ScriptID(331105)
		Set_XSCRIPT_Parameter(0, g_NpcId)
		Set_XSCRIPT_Parameter(1, g_RequestType) -- 此处不用new/old来请求，因为可能表单重制
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end