-- !!!reloadscript =MonthPVP_Result
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

local g_MonthPVP_Score_MyTeamPic = {};
local g_MonthPVP_Score_TeamScore = {};
local g_MonthPVP_Score_TeamDaiBi = {};
local g_MonthPVP_Score_TeamRankPic = {};
local g_MonthPVP_Score_ItemIcon = {};

local g_MonthPVP_Score_DaiBiNum = {10,8,5}
--阵营图片
local g_MonthPVP_Result_TeamPIC = 
{
	[1] = {image = "set:DaHua_PVP image:DaHua_PVP_Bai"}, --白晶晶
	[2] = {image = "set:DaHua_PVP image:DaHua_PVP_Zi"},	 --紫霞
	[3] = {image = "set:DaHua_PVP image:DaHua_PVP_Niu"}, --牛夫人
}
local g_MonthPVP_Score_ItemList = 
{
	[1] = { itemid = 39924686, itemnum = 1},
	[2] = { itemid = 39924687, itemnum = 1},
	[3] = { itemid = 39924688, itemnum = 1},
}
local g_MonthPVP_Score_ItemList_KaJi = 
{
	[1] = { itemid = 39924740, itemnum = 1},
	[2] = { itemid = 39924741, itemnum = 1},
	[3] = { itemid = 39924742, itemnum = 1},
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function MonthPVP_Result_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");

end

--加载窗口的时候调用的函数，加载窗口时调用一次
function MonthPVP_Result_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= MonthPVP_Result_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= MonthPVP_Result_Frame:GetProperty("UnifiedYPosition");

	g_MonthPVP_Score_MyTeamPic[1] = MonthPVP_Result_Camp2_My
	g_MonthPVP_Score_MyTeamPic[2] = MonthPVP_Result_Camp1_My
	g_MonthPVP_Score_MyTeamPic[3] = MonthPVP_Result_Camp3_My

	--积分
	g_MonthPVP_Score_TeamScore[1] = MonthPVP_Result_Camp2_Text1
	g_MonthPVP_Score_TeamScore[2] = MonthPVP_Result_Camp1_Text1
	g_MonthPVP_Score_TeamScore[3] = MonthPVP_Result_Camp3_Text1

	--代币 2 1 3 
	-- g_MonthPVP_Score_TeamDaiBi[1] = MonthPVP_Result_Camp2_Text2
	-- g_MonthPVP_Score_TeamDaiBi[2] = MonthPVP_Result_Camp1_Text2
	-- g_MonthPVP_Score_TeamDaiBi[3] = MonthPVP_Result_Camp3_Text2

	--排名图片
	g_MonthPVP_Score_TeamRankPic[1] = MonthPVP_Result_Camp2_Title
	g_MonthPVP_Score_TeamRankPic[2] = MonthPVP_Result_Camp1_Title
	g_MonthPVP_Score_TeamRankPic[3] = MonthPVP_Result_Camp3_Title

	--奖励
	g_MonthPVP_Score_ItemIcon[1] = MonthPVP_Result_Camp2_Item
	g_MonthPVP_Score_ItemIcon[2] = MonthPVP_Result_Camp1_Item
	g_MonthPVP_Score_ItemIcon[3] = MonthPVP_Result_Camp3_Item

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function MonthPVP_Result_ResetPos()
	MonthPVP_Result_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	MonthPVP_Result_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function MonthPVP_Result_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 82003005) then
		local nTeam = 
		{
			[1] = {nRanking=0,nScore=0},
			[2] = {nRanking=0,nScore=0},
			[3] = {nRanking=0,nScore=0},
		}
		for i=0,2 do --0,1 2,3 4,5
			nTeam[i+1].nRanking = Get_XParam_INT(2*i)
			nTeam[i+1].nScore = Get_XParam_INT(2*i+1)
		end
		local nBelong = Get_XParam_INT(6)
		local nTime = Get_XParam_INT(7)
		local nPlayerScore = Get_XParam_INT(8)

		MonthPVP_Result_Show()
		MonthPVP_Result_Update(nTeam,nBelong,nTime,nPlayerScore)
	elseif event=="HIDE_ON_SCENE_TRANSED" or event=="SCENE_TRANSED" or event=="PLAYER_LEAVE_WORLD" then
		MonthPVP_Result_Hide()
	end

	if this:IsVisible() then
        if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
			MonthPVP_Result_ResetPos()
        end
	end
end

--显示UI
function MonthPVP_Result_Show()
	MonthPVP_Result_ClearData()
	this:Show()
end

--隐藏UI
function MonthPVP_Result_Hide()
	MonthPVP_Result_ClearData()
	this:Hide()
end

--清除数据
function MonthPVP_Result_ClearData()

end

--更新
function MonthPVP_Result_Update(nTeam,nBelong,nTime,nPlayerScore)

	for i=1,3 do
		local nWhich = nTeam[i].nRanking
		if nWhich >= 1 and nWhich <= 3 then
			g_MonthPVP_Score_TeamScore[i]:SetText(ScriptGlobal_Format("#{LLKC_240517_139}",nTeam[i].nScore))
			--g_MonthPVP_Score_TeamDaiBi[i]:SetText(ScriptGlobal_Format("#{LLKC_240517_219}",g_MonthPVP_Score_DaiBiNum[i]))
			g_MonthPVP_Score_TeamRankPic[i]:SetProperty("Image",g_MonthPVP_Result_TeamPIC[nWhich].image)
	
			if nWhich == nBelong then
				g_MonthPVP_Score_MyTeamPic[i]:Show()
			else
				g_MonthPVP_Score_MyTeamPic[i]:Hide()
			end
		end
	end

	-- 展示奖励
	for i = 1, table.getn(g_MonthPVP_Score_ItemList) do
		-- info
		local GiftItemID = g_MonthPVP_Score_ItemList[i].itemid
		local GiftCount = g_MonthPVP_Score_ItemList[i].itemnum

		--卡级服
		if KaJi:LuaFnIsKaJiServer() == 1 then
			GiftItemID = g_MonthPVP_Score_ItemList_KaJi[i].itemid
			GiftCount = g_MonthPVP_Score_ItemList_KaJi[i].itemnum
		end

		-- icon
		local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftCount)
		if theAction:GetID() ~= 0 then
			g_MonthPVP_Score_ItemIcon[i]:SetActionItem( theAction:GetID() );
		end
	end

	MonthPVP_Result_TopList_info:SetText(ScriptGlobal_Format("#{LLKC_240517_150}",nPlayerScore))
	MonthPVP_Result_TopList_Time:SetProperty("Timer",tostring(nTime))
end

function MonthPVP_Result_Help()

end

function MonthPVP_Result_Close()
	MonthPVP_Result_Hide()
end