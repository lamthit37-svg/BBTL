--******************************************
--周常肉鸽爬塔副本	排行榜
--create by  limengyue 
--2024-01-03
--******************************************

local g_RouGe_RankingList_Frame_UnifiedPosition = nil 
local g_IsPre = 0 --默认本期
local g_NpcId =-1;
local objCared = -1
local g_RankingList_Type = 3 --默认是双周排行榜
local g_RankingList_TypePre = 4 --默认上周是单周排行榜
local g_nType = 0;
local g_State = 0;

function RouGe_RankingList_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OPEN_ROUGEPATA_RANKINGLIST",true)
	this:RegisterEvent("UPDATE_ROUGEPATA_RANKINGLIST",true)
	this:RegisterEvent("OPEN_ROUGEPATA_RANKINGLIST_SING",true)
	this:RegisterEvent("UPDATE_ROUGEPATA_RANKINGLIST_SING",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)

end

function RouGe_RankingList_OnLoad()
	g_RouGe_RankingList_Frame_UnifiedPosition = RouGe_RankingList_Frame:GetProperty("UnifiedPosition")
end

function RouGe_RankingList_OnEvent(event)

	if event == "OPEN_ROUGEPATA_RANKINGLIST" then
		g_nType = tonumber(arg0);
		g_NpcId = tonumber(arg1);
		objCared = DataPool:GetNPCIDByServerID(g_NpcId);

		if objCared == -1 then
		--	return
		end
		RouGe_RankingList_BeginCareObject(objCared)
		if g_IsPre == 1 then
			g_RankingList_Type = 4
			g_RankingList_TypePre = 3
			RouGe_RankingList_OnPreShow()
		else
			g_RankingList_Type = 3
			g_RankingList_TypePre = 4
			RouGe_RankingList_OnShow()
		end
		
	elseif event == "OPEN_ROUGEPATA_RANKINGLIST_SING" then

		g_nType = tonumber(arg0);
		g_NpcId = tonumber(arg1);
		
		objCared = DataPool:GetNPCIDByServerID(g_NpcId);

		if objCared == -1 then
		--	return
		end
		RouGe_RankingList_BeginCareObject(objCared)

		if g_IsPre == 1 then
			g_RankingList_Type = 3
			g_RankingList_TypePre = 4
			RouGe_RankingList_OnPreShow()
		else
			g_RankingList_Type = 4
			g_RankingList_TypePre = 3
			RouGe_RankingList_OnShow()
		end
		
	elseif (event == "UPDATE_ROUGEPATA_RANKINGLIST" or event == "UPDATE_ROUGEPATA_RANKINGLIST_SING" )and this:IsVisible() then
		g_nType = tonumber(arg0);
		local nCheck = RouGe_RankingList_Check1:GetCheck()
		if nCheck == 1 then
			--本期
			RouGe_RankingList_OnShow()
		else
			--上期
			RouGe_RankingList_OnPreShow()
		end
	elseif(event == "ADJEST_UI_POS") then
		RouGe_RankingList_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		RouGe_RankingList_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		RouGe_RankingList_CloseClicked()	
	end

end

function RouGe_RankingList_On_ResetPos()
	RouGe_RankingList_Frame:SetProperty("UnifiedPosition", g_RouGe_RankingList_Frame_UnifiedPosition)
end
--===============================================
-- 本期排行榜
--===============================================
function RouGe_RankingList_OnShow()
	g_IsPre = 0
	RouGe_RankingList_ListInfo:Clear()
	--PushDebugMessage("RouGe_RankingList_OnShow g_RankingList_Type="..g_RankingList_Type)
	
	--分页信息
	RouGe_RankingList_Check1:SetCheck(1)
	RouGe_RankingList_Check2:SetCheck(0)
	RouGe_RankingList_AItem_MyRank:SetText("")
	RouGe_RankingList_AItem_MyName:SetText("")
	RouGe_RankingList_AItem_MyTime:SetText("")

	local nDataCount = DataPool:lua_GetJSRankingListDataCount(g_RankingList_Type)

	if nDataCount <= 0 then
		RouGe_RankingList_FillMyInfoNone()
	end
	
	local nRank,name,curPoint,usetime,state = DataPool:lua_GetRougepataRankingListInfo(g_RankingList_Type,0);
	g_State = state
	local myRank = -1
	local myRankTime = 0
	local myRankPoint = 0
	for i = 0, nDataCount-1 do
		local nRank,name,curPoint,usetime,state = DataPool:lua_GetRougepataRankingListInfo(g_RankingList_Type,i);
		for j = 1,6 do
			local bValid,memguid,membname,menpai,level,score = DataPool:lua_GetJSRankingListMemberInfo(g_RankingList_Type,i,j-1);
			if bValid == 1 and myRank < 0 then
				if memguid == Player:GetGUID() then
					myRank = nRank
					myRankTime = usetime
					myRankPoint = curPoint
				end
			end
		end
		
		local ItemBar = RouGe_RankingList_ListInfo:AddChild("RouGe_RankingList_AItem")
		ItemBar:GetSubItem("RouGe_RankingList_AItem_Rank"):SetText(nRank+1)
		ItemBar:GetSubItem("RouGe_RankingList_AItem_Name"):SetText(name)
		ItemBar:GetSubItem("RouGe_RankingList_Score"):SetText(curPoint)
		ItemBar:GetSubItem("RouGe_RankingList_Time"):SetText(RouGe_RankingList_FormatTime(usetime))


		local nShowItemId = DataPool:lua_GetJSRankingListRewardInfo(g_RankingList_Type, nRank*3+2)
	
		local theAction = DataPool:CreateBindActionItemForShow( nShowItemId, 1 )
		if theAction ~= nil then
			ItemBar:GetSubItem("RouGe_RankingList_AItem_Giftimage"):SetActionItem(theAction:GetID())
		end
		
		ItemBar:SetEvent( "MouseLClick", "RouGe_RankingList_OnClick("..i..")" )
	end	
	
	if myRank >= 0 then --上榜
		RouGe_RankingList_FillMyInfo(myRank,myRankPoint,myRankTime)
	else --未上榜
		RouGe_RankingList_FillMyInfoNone()
	end
	--状态信息
	if g_State == 1 then
		RouGe_RankingList_RefreshText:SetText("#{RGPT_231130_246}")
	elseif g_State == 2 then
		RouGe_RankingList_RefreshText:SetText("#{RGPT_231130_247}")
	else
		RouGe_RankingList_RefreshText:SetText("")
	end
	RouGe_RankingList_GetRewards:Hide()
	RouGe_RankingList_GetRewards_ButtonTip:Hide()
	this:Show()
end

--===============================================
-- 上期排行榜
--===============================================
function RouGe_RankingList_OnPreShow()
	g_IsPre = 0
	RouGe_RankingList_ListInfo:Clear()
	--PushDebugMessage("RouGe_RankingList_OnPreShow g_RankingList_TypePre="..g_RankingList_TypePre)
	--分页信息
	RouGe_RankingList_Check1:SetCheck(0)
	RouGe_RankingList_Check2:SetCheck(1)
	RouGe_RankingList_AItem_MyRank:SetText("")
	RouGe_RankingList_AItem_MyName:SetText("")
	RouGe_RankingList_AItem_MyTime:SetText("")

	local nDataCount = DataPool:lua_GetJSRankingListDataCount(g_RankingList_TypePre)
	--PushDebugMessage("nDataCount="..nDataCount)
	if nDataCount <= 0 then
		RouGe_RankingList_FillMyInfoNonePre()
	end
	
	local nRank,name,curPoint,usetime,state = DataPool:lua_GetRougepataRankingListInfo(g_RankingList_TypePre,0);
	g_State = state
	local myRank = -1
	local myRankTime = 0
	local myRankPoint = 0
	for i = 0, nDataCount-1 do
		local nRank,name,curPoint,usetime,state = DataPool:lua_GetRougepataRankingListInfo(g_RankingList_TypePre,i);
		for j = 1,6 do
			local bValid,memguid,membname,menpai,level,score = DataPool:lua_GetJSRankingListMemberInfo(g_RankingList_TypePre,i,j-1);
			if bValid == 1 and myRank < 0 then
				if memguid == Player:GetGUID() then
					myRank = nRank
					myRankTime = usetime
					myRankPoint = curPoint
				end
			end
		end
		
		local ItemBar = RouGe_RankingList_ListInfo:AddChild("RouGe_RankingList_AItem")
		ItemBar:GetSubItem("RouGe_RankingList_AItem_Rank"):SetText(nRank+1)
		ItemBar:GetSubItem("RouGe_RankingList_AItem_Name"):SetText(name)
		ItemBar:GetSubItem("RouGe_RankingList_Score"):SetText(curPoint)
		ItemBar:GetSubItem("RouGe_RankingList_Time"):SetText(RouGe_RankingList_FormatTime(usetime))


		local nShowItemId = DataPool:lua_GetJSRankingListRewardInfo(g_RankingList_TypePre, nRank*3+2)
	
		local theAction = DataPool:CreateBindActionItemForShow( nShowItemId, 1 )
		if theAction ~= nil then
			ItemBar:GetSubItem("RouGe_RankingList_AItem_Giftimage"):SetActionItem(theAction:GetID())
		end
		
		ItemBar:SetEvent( "MouseLClick", "RouGe_RankingList_OnClickPre("..i..")" )
	end	
	
	--PushDebugMessage("myRank="..myRank)
	RouGe_RankingList_GetRewards:Show()
	if myRank >= 0 then --上榜
		RouGe_RankingList_FillMyInfoPre(myRank,myRankPoint,myRankTime)
	else --未上榜
		RouGe_RankingList_FillMyInfoNonePre()
	end
	--状态信息
	if g_State == 1 then
		RouGe_RankingList_RefreshText:SetText("#{RGPT_231130_246}")
	elseif g_State == 2 then
		RouGe_RankingList_RefreshText:SetText("#{RGPT_231130_247}")
	else
		RouGe_RankingList_RefreshText:SetText("")
	end
	this:Show()
end

--===============================================
-- 本期排行榜个人信息
--===============================================
function RouGe_RankingList_FillMyInfoNone()
	RouGe_RankingList_AItem_MyRank:SetText("#{RGPT_231130_258}")
	RouGe_RankingList_AItem_MyName:SetText(Player:GetName())
	local myPoint = DataPool:lua_GetRougepataRankingListMyvalue()
	if g_RankingList_Type == 4 then
		myPoint = DataPool:lua_GetRougepataRankingListMySingular()
	end
	if myPoint <= 0 then
		RouGe_RankingList_MyScore:SetText("--:--")
		RouGe_RankingList_AItem_MyTime:SetText("--:--")
	else
		RouGe_RankingList_MyScore:SetText(myPoint)
		RouGe_RankingList_AItem_MyTime:SetText("--:--")
	end
	RouGe_RankingList_AItem_MyGiftimage:Hide()
end

--===============================================
-- 上期排行榜个人信息
--===============================================
function RouGe_RankingList_FillMyInfoNonePre()
	RouGe_RankingList_AItem_MyRank:SetText("#{RGPT_231130_258}")
	RouGe_RankingList_AItem_MyName:SetText(Player:GetName())
	local myPoint = DataPool:lua_GetRougepataRankingListMyvalue()
	if g_RankingList_TypePre == 3 then
		myPoint = DataPool:lua_GetRougepataRankingListMySingular()
	end
	if myPoint <= 0 then
		RouGe_RankingList_MyScore:SetText("--:--")
		RouGe_RankingList_AItem_MyTime:SetText("--:--")
	else
		RouGe_RankingList_MyScore:SetText(myPoint)
		RouGe_RankingList_AItem_MyTime:SetText("--:--")
	end
	RouGe_RankingList_AItem_MyGiftimage:Hide()
end
--===============================================
-- 本期排行榜个人信息
--===============================================
function RouGe_RankingList_FillMyInfo(myRank,myRankPoint,myRankTime)
	RouGe_RankingList_AItem_MyRank:SetText(myRank+1)
	RouGe_RankingList_AItem_MyName:SetText(Player:GetName())
	RouGe_RankingList_MyScore:SetText(myRankPoint)
	RouGe_RankingList_AItem_MyTime:SetText(RouGe_RankingList_FormatTime(myRankTime))
	RouGe_RankingList_AItem_MyGiftimage:Show()
	
	if myRank >= 0 and myRank < 3 then
		local nShowItemId = DataPool:lua_GetJSRankingListRewardInfo(g_RankingList_Type, myRank*3+2)
		local theAction = DataPool:CreateBindActionItemForShow( nShowItemId, 1 )
		if theAction ~= nil then
			RouGe_RankingList_AItem_MyGiftimage:SetActionItem(theAction:GetID())
		end
		
		--可领奖
		local myusetime,isGet = DataPool:lua_GetJSRankingListMyInfo(g_RankingList_Type)
		if g_State == 2 and isGet == 0 then --红点
			RouGe_RankingList_GetRewards_ButtonTip:Show()
		end
	end
end

--===============================================
-- 上期排行榜个人信息
--===============================================
function RouGe_RankingList_FillMyInfoPre(myRank,myRankPoint,myRankTime)
	RouGe_RankingList_AItem_MyRank:SetText(myRank+1)
	RouGe_RankingList_AItem_MyName:SetText(Player:GetName())
	RouGe_RankingList_MyScore:SetText(myRankPoint)
	RouGe_RankingList_AItem_MyTime:SetText(RouGe_RankingList_FormatTime(myRankTime))
	RouGe_RankingList_AItem_MyGiftimage:Show()
	
	if myRank >= 0 and myRank < 3 then
		local nShowItemId = DataPool:lua_GetJSRankingListRewardInfo(g_RankingList_TypePre, myRank*3+2)
		local theAction = DataPool:CreateBindActionItemForShow( nShowItemId, 1 )
		if theAction ~= nil then
			RouGe_RankingList_AItem_MyGiftimage:SetActionItem(theAction:GetID())
		end
		
		--可领奖
		local myusetime,isGet = DataPool:lua_GetJSRankingListMyInfo(g_RankingList_TypePre)
		if g_State == 2 and isGet == 0 then --红点
			RouGe_RankingList_GetRewards_ButtonTip:Show()
		end
	end
end

--===============================================
-- 本期团队信息
--===============================================
function RouGe_RankingList_OnClick(index)
	if g_RankingList_Type == 3 then
		PushEvent("OPEN_ROUGEPATA_RANKINGLIST_TEAM",index,g_NpcId,g_RankingList_Type)
	else
		PushEvent("OPEN_ROUGEPATA_RANKINGLIST_TEAM_SING",index,g_NpcId,g_RankingList_Type)
	end

end

--===============================================
-- 上期团队信息
--===============================================
function RouGe_RankingList_OnClickPre(index)
	if g_RankingList_TypePre == 3 then
		PushEvent("OPEN_ROUGEPATA_RANKINGLIST_TEAM",index,g_NpcId,g_RankingList_TypePre)
	else
		PushEvent("OPEN_ROUGEPATA_RANKINGLIST_TEAM_SING",index,g_NpcId,g_RankingList_TypePre)
	end
end

--===============================================
-- 领奖
--===============================================
function RouGe_RankingList_GetRewards_Clicked()
	DataPool:lua_GetJSRankingListGetReward(g_RankingList_TypePre)
end

function RouGe_RankingList_FormatTime(nSec)
	local min = math.floor(nSec/60)
	local sec = math.mod(nSec,60)
	
	if min < 10 then
		return string.format("%02d:%02d",min,sec)
	else
		return string.format("%d:%02d",min,sec)
	end
	
end
function RouGe_RankingList_CloseClicked()
	RouGe_RankingList_StopCareObject()
	this:Hide()
end
--=========================================================
--开始关心NPC
--=========================================================
function RouGe_RankingList_BeginCareObject(objCaredId)
	if objCared ~= -1 then
		this:CareObject(objCaredId, 0, "RouGe_RankingList");
	end
	objCared = objCaredId
	this:CareObject(objCared, 1, "RouGe_RankingList")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function RouGe_RankingList_StopCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "RouGe_RankingList");
		objCared = -1;
	end
end


--===============================================
-- 点击分页
--===============================================
function RouGe_RankingList_Fenye(nIndex)

	if nIndex == 2 then
		g_IsPre = 1
	else
		g_IsPre = 0
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenRankingList" )
		Set_XSCRIPT_ScriptID( 998947)	
		Set_XSCRIPT_Parameter( 0 ,g_NpcId)
		Set_XSCRIPT_Parameter( 1 ,g_IsPre)
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()
	
end