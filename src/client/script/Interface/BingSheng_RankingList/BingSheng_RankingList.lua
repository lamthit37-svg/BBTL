-- BingSheng_RankingList

local g_BingSheng_RankingList_Frame_UnifiedPosition = nil 

local g_NpcId =-1;
local objCared = -1
local g_RankingList_Type = 2
local g_nType = 0;
local g_State = 0;


function BingSheng_RankingList_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OPEN_BINGSHENG_RANKINGLIST",true)
	this:RegisterEvent("UPDATE_BINGSHENG_RANKINGLIST",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)

end

function BingSheng_RankingList_OnLoad()
	g_BingSheng_RankingList_Frame_UnifiedPosition = BingSheng_RankingList_Frame:GetProperty("UnifiedPosition")
end

function BingSheng_RankingList_OnEvent(event)

	if event == "OPEN_BINGSHENG_RANKINGLIST" then
		if this:IsVisible() then	-- 如果界面开着，则不处理
			return
		end
		g_nType = tonumber(arg0);
		g_NpcId = tonumber(arg1);
		
		objCared = DataPool:GetNPCIDByServerID(g_NpcId);

		if objCared == -1 then
		--	return
		end
		BingSheng_RankingList_BeginCareObject(objCared)

		BingSheng_RankingList_OnShow()
	elseif event == "UPDATE_BINGSHENG_RANKINGLIST" and this:IsVisible() then
		g_nType = tonumber(arg0);

		BingSheng_RankingList_OnShow()
	elseif(event == "ADJEST_UI_POS") then
		BingSheng_RankingList_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		BingSheng_RankingList_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		BingSheng_RankingList_CloseClicked()	
	end

end

function BingSheng_RankingList_On_ResetPos()
	BingSheng_RankingList_Frame:SetProperty("UnifiedPosition", g_BingSheng_RankingList_Frame_UnifiedPosition)
end

function BingSheng_RankingList_OnShow()
	BingSheng_RankingList_ListInfo:Clear()

	BingSheng_RankingList_AItem_MyRank:SetText("")
	BingSheng_RankingList_AItem_MyName:SetText("")
	BingSheng_RankingList_AItem_MyTime:SetText("")

	local nDataCount = DataPool:lua_GetJSRankingListDataCount(g_RankingList_Type)

	if nDataCount <= 0 then
		BingSheng_RankingList_FillMyInfoNone()
	end
	
	local nRank,name,usetime,state = DataPool:lua_GetJSRankingListInfo(g_RankingList_Type,0);
	g_State = state
	local myRank = -1
	local myRankTime = 0
	for i = 0, nDataCount-1 do
		local nRank,name,usetime,state = DataPool:lua_GetJSRankingListInfo(g_RankingList_Type,i);
		for j = 1,12 do
			local bValid,memguid,membname,menpai,level,score = DataPool:lua_GetJSRankingListMemberInfo(g_RankingList_Type,i,j-1);
			if bValid == 1 and myRank < 0 then
				if memguid == Player:GetGUID() then
					myRank = nRank
					myRankTime = usetime
				end
			end
		end
		
		local ItemBar = BingSheng_RankingList_ListInfo:AddChild("BingSheng_RankingList_AItem")
		ItemBar:GetSubItem("BingSheng_RankingList_AItem_Rank"):SetText(nRank+1)
		ItemBar:GetSubItem("BingSheng_RankingList_AItem_Name"):SetText(name)
		ItemBar:GetSubItem("BingSheng_RankingList_Time"):SetText(BingSheng_RankingList_FormatTime(usetime))

		local nShowItemId = DataPool:lua_GetJSRankingListRewardInfo(g_RankingList_Type, nRank*3+2)
	
		local theAction = DataPool:CreateBindActionItemForShow( nShowItemId, 1 )
		if theAction ~= nil then
			ItemBar:GetSubItem("BingSheng_RankingList_AItem_Giftimage"):SetActionItem(theAction:GetID())
		end
		ItemBar:SetEvent( "MouseLClick", "BingSheng_RankingList_OnClick("..i..")" )
	end	

	BingSheng_RankingList_GetRewards_ButtonTip:Hide()
	if myRank >= 0 then --上榜
		BingSheng_RankingList_FillMyInfo(myRank,myRankTime)
	else --未上榜
		BingSheng_RankingList_FillMyInfoNone()
	end
	--状态信息
	if g_State == 1 then
		BingSheng_RankingList_RefreshText:SetText("#{BSQZ_210714_72}")
	elseif g_State == 2 then
		BingSheng_RankingList_RefreshText:SetText("#{BSQZ_210714_73}")
	else
		BingSheng_RankingList_RefreshText:SetText("")
	end	
	this:Show()
end

function BingSheng_RankingList_FillMyInfoNone()
	BingSheng_RankingList_AItem_MyRank:SetText("#{PTFB_191228_166}")
	BingSheng_RankingList_AItem_MyName:SetText(Player:GetName())
	local myusetime = DataPool:lua_GetBingShengRankingListMyvalue()
	if myusetime <= 0 then
		BingSheng_RankingList_AItem_MyTime:SetText("--:--")
	else
		BingSheng_RankingList_AItem_MyTime:SetText(BingSheng_RankingList_FormatTime(myusetime))
	end
	BingSheng_RankingList_AItem_MyGiftimage:Hide()
end

function BingSheng_RankingList_FillMyInfo(myRank,myRankTime)
	BingSheng_RankingList_AItem_MyRank:SetText(myRank+1)
	BingSheng_RankingList_AItem_MyName:SetText(Player:GetName())
	BingSheng_RankingList_AItem_MyTime:SetText(BingSheng_RankingList_FormatTime(myRankTime))
	BingSheng_RankingList_AItem_MyGiftimage:Show()
	
	if myRank >= 0 and myRank < 3 then
		local nShowItemId = DataPool:lua_GetJSRankingListRewardInfo(g_RankingList_Type, myRank*3+2)
		local theAction = DataPool:CreateBindActionItemForShow( nShowItemId, 1 )
		if theAction ~= nil then
			BingSheng_RankingList_AItem_MyGiftimage:SetActionItem(theAction:GetID())
		end
		
		--可领奖
		local myusetime,isGet = DataPool:lua_GetJSRankingListMyInfo(g_RankingList_Type)
		if g_State == 2 and isGet == 0 then --红点
			BingSheng_RankingList_GetRewards_ButtonTip:Show()
		end
	end
end

--团队信息
function BingSheng_RankingList_OnClick(index)
	PushEvent("OPEN_BINGSHENG_RANKINGLIST_TEAM",index,g_NpcId)
end

--领奖
function BingSheng_RankingList_GetRewards_Clicked()
	DataPool:lua_GetJSRankingListGetReward(g_RankingList_Type)
end

function BingSheng_RankingList_FormatTime(nSec)
	local min = math.floor(nSec/60)
	local sec = math.mod(nSec,60)
	
	if min < 10 then
		return string.format("%02d:%02d",min,sec)
	else
		return string.format("%d:%02d",min,sec)
	end
	
end
function BingSheng_RankingList_CloseClicked()
	BingSheng_RankingList_StopCareObject()
	this:Hide()
end
--=========================================================
--开始关心NPC
--=========================================================
function BingSheng_RankingList_BeginCareObject(objCaredId)
	if objCared ~= -1 then
		this:CareObject(objCaredId, 0, "BingSheng_RankingList");
	end
	objCared = objCaredId
	this:CareObject(objCared, 1, "BingSheng_RankingList")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function BingSheng_RankingList_StopCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "BingSheng_RankingList");
		objCared = -1;
	end
end