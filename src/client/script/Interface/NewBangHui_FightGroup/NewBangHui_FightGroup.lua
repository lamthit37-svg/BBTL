-- !!!reloadscript =NewBangHui_FightGroup
local m_Frame_UnifiedPosition

local m_curZhanTuanPage = 0 --当前战团页
local m_MemberSortOrder = 0 --排序方式
local m_ListToMember = {}
local m_curSelectMem = -1
local m_ZhanTuanPageUI =  nil

local m_myZhanTuanID = 0
local m_myZhanTuanPos = 0

local m_ZhanTuanPossionInfo = 
{
	[0] = "#{ZTXT_260511_22}",[1] = "#{ZTXT_260511_21}",
}
-- local m_ZhanTuanNameText = 
-- {
-- 	"#{ZTXT_260511_02}","#{ZTXT_260511_03}","#{ZTXT_260511_04}","#{ZTXT_260511_05}","#{ZTXT_260511_06}",
-- }
-- local m_ZhanTuanPointText = 
-- {
-- 	"#{ZTXT_260511_08}","#{ZTXT_260511_09}","#{ZTXT_260511_10}","#{ZTXT_260511_11}","#{ZTXT_260511_12}",
-- }
local m_menpaiInfo = {
	"#{XQ_MP_1}",    --少林
	"#{XQ_MP_2}",    --明教
	"#{XQ_MP_3}",    --丐帮
	"#{XQ_MP_4}",    --武当
	"#{XQ_MP_5}",    --峨眉
	"#{XQ_MP_6}",    --星宿
	"#{XQ_MP_7}",    --天龙
	"#{XQ_MP_8}",    --天山
	"#{XQ_MP_9}",    --逍遥
	"#{WCBZ_180128_57}",  --无门派
	"#{XQ_MP_10}",  
	"#{XQ_MP_13}",   
	"#{XMPGG_160524_02}",   --鬼谷
	"#{XQ_MP_15}",   --桃花岛
	"#{XMPHM_210604_01}",   
	"#{GMGameInterface_Script_DataPool_Info_ERenGu}",   
};
--预加载函数，可以而且只能在这里注册脚本关心的事件
function NewBangHui_FightGroup_PreLoad()
	this:RegisterEvent("GUILD_ZHANTUAN_OP", true)
	this:RegisterEvent("GUILD_ZHANTUAN_OP_UPDATE", false)
	this:RegisterEvent("GUILD_LEAGUE_INFO")
	this:RegisterEvent("UPDATE_GUILD_LEAGUE_INFO")
    this:RegisterEvent("ACCELERATE_KEYSEND")
    this:RegisterEvent("SHOW_GUILDWAR_ANIMI");
	this:RegisterEvent("OPEN_GUILD_GIFT")


    this:RegisterEvent( "GUILD_SHOW_DETAILINFO" )
    this:RegisterEvent( "GUILD_SHOW_MEMBERINFO" )
	this:RegisterEvent("GUILD_SHOW_ENEMYLIST")
	this:RegisterEvent("OPEN_BUILD_INTRODUCE")
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	this:RegisterEvent("ZHANTUAN_LIST_DATA");
	this:RegisterEvent("OPENMYALLIANCE");
	this:RegisterEvent("GUILD_BIDDING_SHOWLIST")
	--this:RegisterEvent("TCITYWARLIMIT_OPENCANDIDATE")
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function NewBangHui_FightGroup_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedPosition	= NewBangHui_FightGroup_Frame:GetProperty("UnifiedPosition");
	
	NewBangHui_FightGroup_Filter_SearchMode:AddTextItem("#{ZTXT_260511_16}" ,1)			--默认：姓名
	NewBangHui_FightGroup_Filter_SearchMode:AddTextItem("#{ZTXT_260511_17}" ,2)			-- 等级
	NewBangHui_FightGroup_Filter_SearchMode:AddTextItem("#{ZTXT_260511_18}" ,3)			--装备评分
	NewBangHui_FightGroup_Filter_SearchMode:AddTextItem("#{ZTXT_260511_19}" ,4)			--门派
	NewBangHui_FightGroup_Filter_SearchMode:SetCurrentSelect(0)

	m_ZhanTuanPageUI = {}
	for i = 1, GuildZhanTuanUI:LuaFnGetZhanTuanMaxNum() do
		m_ZhanTuanPageUI[i] = _G['NewBangHui_FightGroup_Frame2_PageBtn'..i]
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NewBangHui_FightGroup_ResetPos()
	NewBangHui_FightGroup_Frame:SetProperty("UnifiedPosition", m_Frame_UnifiedPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function NewBangHui_FightGroup_OnEvent(event)
	if( event == "GUILD_ZHANTUAN_OP" ) then--
		NewBangHui_FightGroup_Filter_SearchMode:SetCurrentSelect(0)
		GuildZhanTuanUI:LuaFnInitZhanTuanData()
		if (this:IsVisible()) then
			NewBangHui_FightGroup_Update()
			return
		end
		NewBangHui_FightGroup_Show()
		NewBangHui_FightGroup_SetPageBtn(1)
		NewBangHui_FightGroup_Update()
	elseif event == "GUILD_ZHANTUAN_OP_UPDATE" then
		local opType = tonumber(arg0)
		if opType ~= 1 and
			opType ~= 2 and
			opType ~= 3 and
			opType ~= 4 then
			return
		end
		if (this:IsVisible()) then
			--GuildZhanTuanUI:LuaFnInitZhanTuanData()
			NewBangHui_FightGroup_Update()
			return
		end
	elseif event == "ADJEST_UI_POS" then
		NewBangHui_FightGroup_ResetPos()
	elseif (event == "GUILD_SHOW_DETAILINFO") or
		(event == "UI_COMMAND" and tonumber(arg0)==1208) then

		NewBangHui_FightGroup_Hide()
	elseif (event == "GUILD_SHOW_MEMBERINFO") then
		NewBangHui_FightGroup_Hide()
	elseif (event == "GUILD_SHOW_ENEMYLIST") then
		NewBangHui_FightGroup_Hide()
	elseif (event == "GUILD_LEAGUE_INFO") then
		NewBangHui_FightGroup_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		NewBangHui_FightGroup_Hide()
	elseif ( event == "ZHANTUAN_LIST_DATA" ) then
		NewBangHui_FightGroup_Hide()
	elseif (event == "SHOW_GUILDWAR_ANIMI" ) then
		local type = arg0;
		if (arg0 == "show") then
			NewBangHui_FightGroup_Bhxz:SetText("#g0071BF#{BHJM_140520_04}")
			NewBangHui_FightGroup_Bhxz:SetToolTip("你的帮会正在帮战");
		else
			NewBangHui_FightGroup_Bhxz:SetText("#{BHJM_140520_04}");
			NewBangHui_FightGroup_Bhxz:SetToolTip("");
		end
	elseif (event == "OPENMYALLIANCE") then
		NewBangHui_FightGroup_Hide()
	elseif (event == "OPEN_GUILD_GIFT" ) then
		NewBangHui_FightGroup_Hide()
	elseif event == "GUILD_BIDDING_SHOWLIST" then
		NewBangHui_FightGroup_Hide()
	elseif event == "TCITYWARLIMIT_OPENCANDIDATE" then
		NewBangHui_FightGroup_Hide()
	end
end

--显示UI
function NewBangHui_FightGroup_Show()
	NewBangHui_FightGroup_ClearData()
	this:Show()
	
end
--隐藏UI
function NewBangHui_FightGroup_Hide()
	NewBangHui_FightGroup_ClearData()

	this:Hide()
end

--清除数据
function NewBangHui_FightGroup_ClearData()
	m_MemberSortOrder = 0
end

--更新
function NewBangHui_FightGroup_Update()

	GuildZhanTuanUI:LuaFnSortGuildZhanTuanData(m_curZhanTuanPage, m_MemberSortOrder)

	NewBangHui_FightGroup_BZZT:SetCheck(1)
	NewBangHui_FightGroup_SetTitle()

	m_myZhanTuanPos = 0
	m_myZhanTuanID = 0
	for zhanTuanIndex = 1, 5 do
		for memIdx = 0, GuildZhanTuanUI:LuaFnGetZhanTuanMemMaxNum()-1 do
			local IsValid,IsMe,MemIndex,Name,Level,MenPai,EquipPoint,Pos,ZhanTuanID,IsOnline,Guid = GuildZhanTuanUI:LuaFnGuildZhanTuanData(zhanTuanIndex, memIdx)
			if IsValid == 1 and IsMe == 1 then
				m_myZhanTuanID = ZhanTuanID
				m_myZhanTuanPos = Pos
				break
			end
		end
		if m_myZhanTuanID > 0 then
			break
		end
	end

	-- if nil ~= m_ZhanTuanNameText[m_myZhanTuanID] then
	-- 	local zhanTuanName = ScriptGlobal_Format("#{ZTXT_260511_146}", m_ZhanTuanNameText[m_myZhanTuanID])
	-- 	NewBangHui_FightGroup_Info:SetText("#{ZTXT_260511_07}"..zhanTuanName)
	-- else
	-- 	NewBangHui_FightGroup_Info:SetText("#{ZTXT_260511_07}".."#{ZTXT_260511_145}")
	-- end

	NewBangHui_FightGroup_MultiColumnList:RemoveAllItem()

	local listidx = 0
	m_ListToMember = {}
	local curZhanTuanNum = 0
	local curOnlineNum = 0
	local isHaveTuanZhang = 0
	for memIdx = 0, GuildZhanTuanUI:LuaFnGetZhanTuanMemMaxNum()-1 do
		local IsValid,IsMe,MemIndex,Name,Level,MenPai,EquipPoint,Pos,ZhanTuanID,IsOnline,Guid = GuildZhanTuanUI:LuaFnGuildZhanTuanData(m_curZhanTuanPage, memIdx)
		if IsValid == 1 then--
			if nil == m_ZhanTuanPossionInfo[Pos] then
				Pos = 0
			end
			local onlineColor = "#c808080"
			if IsOnline == 1 then
				onlineColor = "#W"
				curOnlineNum = curOnlineNum + 1
			end
			curZhanTuanNum = curZhanTuanNum + 1

			NewBangHui_FightGroup_MultiColumnList:AddNewItem(onlineColor..m_ZhanTuanPossionInfo[Pos], 0, listidx)
			NewBangHui_FightGroup_MultiColumnList:AddNewItem(onlineColor..Name, 1, listidx)
			NewBangHui_FightGroup_MultiColumnList:AddNewItem(onlineColor..Level, 2, listidx)
			NewBangHui_FightGroup_MultiColumnList:AddNewItem(onlineColor..m_menpaiInfo[MenPai+1], 3, listidx)
			NewBangHui_FightGroup_MultiColumnList:AddNewItem(onlineColor..EquipPoint, 4, listidx)

			m_ListToMember[listidx] = MemIndex
			listidx = listidx + 1

			if Pos == 1 then
				isHaveTuanZhang = 1
				NewBangHui_FightGroup_GroupLeader:SetText(ScriptGlobal_Format("#{ZTXT_260511_27}",Name))
				NewBangHui_FightGroup_GroupLeaderInfo1:SetText(m_menpaiInfo[MenPai+1])
				NewBangHui_FightGroup_GroupLeaderInfo2:SetText(Level)
			end
		end
	end
	if listidx > 0 then
		NewBangHui_FightGroup_MultiColumnList:SetSelectItem(0)
	end
	if isHaveTuanZhang == 1 then
		NewBangHui_FightGroup_NoGroupLeader:Hide()
		NewBangHui_FightGroup_GroupLeader:Show()
		NewBangHui_FightGroup_GroupLeaderInfo:Show()
	else
		NewBangHui_FightGroup_NoGroupLeader:Show()
		NewBangHui_FightGroup_GroupLeader:Hide()
		NewBangHui_FightGroup_GroupLeaderInfo:Hide()
	end
	NewBangHui_FightGroup_GroupInfo:SetText(ScriptGlobal_Format("#{ZTXT_260511_30}", curOnlineNum, curZhanTuanNum))
end

function NewBangHui_FightGroup_SetTitle()
	local szName = Guild:GetMyGuildName("Name");
	local title = ScriptGlobal_Format("#{BHJM_140520_01}", szName)
	NewBangHui_FightGroup_PageHeader:SetText(title)
end

function NewBangHui_FightGroup_SetPageBtn(selectPage)
	if not this:IsVisible() then
		return	
	end
	-- PushDebugMessage(m_curZhanTuanPage.." "..selectPage)
	if m_curZhanTuanPage == selectPage  then
		return
	end
	-- for page = 1, GuildZhanTuanUI:LuaFnGetZhanTuanMaxNum() do
	-- 	if page == selectPage then
	-- 		m_ZhanTuanPageUI[page]:SetCheck(1)
	-- 	else		
	-- 		m_ZhanTuanPageUI[page]:SetCheck(0)
	-- 	end
	-- end
	-- if nil ~= m_ZhanTuanPointText[selectPage] then
	-- 	NewBangHui_FightGroup_PointText:SetText(m_ZhanTuanPointText[selectPage])
	-- end
	
	m_curZhanTuanPage = 1

	NewBangHui_FightGroup_Update()
end

--##############点击事件##############
function NewBangHui_FightGroup_CloseClicked()
	NewBangHui_FightGroup_Hide()
end
function NewBangHui_FightGroup_PageBtn1_Clicked()
	-- NewBangHui_FightGroup_SetPageBtn(1)
end
function NewBangHui_FightGroup_PageBtn2_Clicked()
	-- NewBangHui_FightGroup_SetPageBtn(2)
end

function NewBangHui_FightGroup_PageBtn3_Clicked()
	-- NewBangHui_FightGroup_SetPageBtn(3)
end

function NewBangHui_FightGroup_PageBtn4_Clicked()
	-- NewBangHui_FightGroup_SetPageBtn(4)
end

function NewBangHui_FightGroup_PageBtn5_Clicked()
	-- NewBangHui_FightGroup_SetPageBtn(5)
end
--一键组团
function NewBangHui_FightGroup_GroupButton_Clicked()
	if m_myZhanTuanID <= 0 then
		PushDebugMessage("#{ZTXT_260511_148}")
		return
	end
	if m_myZhanTuanID ~= m_curZhanTuanPage then
		PushDebugMessage("#{ZTXT_260511_72}")
		return
	end
	if m_myZhanTuanPos ~= 1 then
		PushDebugMessage("#{ZTXT_260511_72}")
		return
	end
	GuildZhanTuanUI:LuaFnZhanTuanSendRaidInvitation(m_curZhanTuanPage)
end
function NewBangHui_FightGroup_Filter_SearchMode_Changed()
	if not this:IsVisible() then
		return	
	end
	
	local _, nIndex = NewBangHui_FightGroup_Filter_SearchMode:GetCurrentSelect()
	if m_MemberSortOrder == nIndex then
		return
	end
	m_MemberSortOrder = nIndex
	
	NewBangHui_FightGroup_Update()
end
function NewBangHui_FightGroup_SelectChanged()
	m_curSelectMem = NewBangHui_FightGroup_MultiColumnList:GetSelectItem();

	--m_ListToMember[m_curSelectMem]
end
--任命团长
function NewBangHui_FightGroup_GroupLeaderButton_Clicked()
	local myPos = Guild:GetMyPosition()
	if myPos ~= 9 then
		PushDebugMessage("#{ZTXT_260511_44}")
		return
	end
	PushEvent("GUILD_ZHANTUAN_OP_UPDATE", 10000, m_curZhanTuanPage)
end
--添加成员
function NewBangHui_FightGroup_AddMember_Clicked()
	local myPos = Guild:GetMyPosition()
	if myPos ~= 9 and m_myZhanTuanPos ~= 1 then
		PushDebugMessage("#{ZTXT_260511_58}")
		return
	end
	PushEvent("GUILD_ZHANTUAN_OP_UPDATE", 10001, m_curZhanTuanPage)
end
--移除成员
function NewBangHui_FightGroup_DeleteMember_Clicked()
	local myPos = Guild:GetMyPosition()
	-- PushDebugMessage(myPos.." "..m_myZhanTuanPos)
	if myPos ~= 9 and m_myZhanTuanPos ~= 1 then
		PushDebugMessage("#{ZTXT_260511_67}")
		return
	end
	if nil == m_ListToMember[m_curSelectMem] then
		PushDebugMessage("#{ZTXT_260511_68}")
		return
	end
	GuildZhanTuanUI:LuaFnGuildZhanTuanRemove(m_curZhanTuanPage, m_ListToMember[m_curSelectMem])
end
--成员对比
function NewBangHui_FightGroup_GroupButton2_Clicked()
	if m_myZhanTuanID ~= m_curZhanTuanPage then
		PushDebugMessage("#{ZTXT_260511_116}")
		return
	end
	if Player:IsInRaid() ~= 1 then
		PushDebugMessage("#{ZTXT_260511_117}")
		return
	end
	PushEvent("GUILD_ZHANTUAN_OP_UPDATE", 20000, m_curZhanTuanPage, m_myZhanTuanID, m_myZhanTuanPos)
end

function NewBangHui_FightGroup_ZTTopListBtn_Clicked()
	-- GuildZhanTuanUI:LuaFnOpenGuildZhanTuanRank()
end
---下面是通用界面的一些点击事件
function NewBangHui_FightGroup_Hygl_Clicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_FightGroup_Frame:GetProperty("UnifiedPosition"), 1);
	Guild:ToggleGuildDetailInfo()
end
function NewBangHui_FightGroup_Bhxx_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_FightGroup_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:AskGuildDetailInfo();
	Guild:CloseKickGuildBox();	
end
function NewBangHui_FightGroup_Tmxx_Clicked()
	--在K服只有服务器配置保留原服"帮会同盟"信息的时候,才响应相应的按钮事件
	if KVKInterface:IsInKVKServer() == 1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
		PushDebugMessage("#{KVKBH_140124_66}")
		return;
	end
	local id=Player:GetData("GUILDLEAGUE")
	if id == nil or id < 0 then
		PushDebugMessage( "#{KVKSL_110628_305}" )
		return
	end
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_FightGroup_Frame:GetProperty("UnifiedPosition"), 1);
	GuildLeague:ShowInfoWindow()
end

function NewBangHui_FightGroup_Bhxz_Clicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_FightGroup_Frame:GetProperty("UnifiedPosition"), 1);
    City:OpenNewGuildWarDlg();
	Guild:CloseKickGuildBox();
	NewBangHui_FightGroup_Bhxz:SetCheck(1)
end

function NewBangHui_FightGroup_JZWJS_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_FightGroup_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ShowCityBuildIntroduce()
end

function NewBangHui_FightGroup_HB_OnClicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_FightGroup_Frame:GetProperty("UnifiedPosition"), 1)
	Guild:OpentGuildGiftUI()
end
function NewBangHui_FightGroup_YXSS_Clicked()
  Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_FightGroup_Frame:GetProperty("UnifiedPosition"), 1);
  Guild:AskGuildYXSSInfo();
end
--拍卖
function NewBangHui_FightGroup_Auction_Clicked()
	--if KaJi:LuaFnIsKaJiServer() == 1 then
	--	PushDebugMessage("#{SCBHPM_20220815_143}")
	  --return
	--end
	if GetSceneID() ~= 850 then
	  PushDebugMessage("#{SCBHPM_20220815_02}")
	  return
	end
	  
	if Player:GetLevel() < 85 then
	  PushDebugMessage("#{SCBHPM_20220815_03}")
	  return
	end
	  
	if( -1 == Player:GetData("GUILD")) then
	  PushDebugMessage("#{SCBHPM_20220815_04}")
	  return
	end
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_FightGroup_Frame:GetProperty("UnifiedPosition"), 1);
	Guild:AskGuildBiddingInfo(0, 1, -1)
end
function NewBangHui_FightGroup_BZZT_Clicked()
	
end
--####################################