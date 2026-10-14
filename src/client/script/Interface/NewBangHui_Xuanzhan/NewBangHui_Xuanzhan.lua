
local g_NewBangHui_Xuanzhan_Frame_UnifiedPosition

local g_CtrlNewBanHui = {}
--脚本全局变量，用来标识当前玩家是否选择跨服的帮会信息
local g_IsAcrossServer = 0 ;
--服务器帮会列表显示的相关全局变量定义
local g_GuildNumPerPage = 5;
--本服帮会列表显示的相关全局变量定义
local g_GuildCurPageIndex = 0;
local g_GuildTotalPageNum = 0;
--跨服帮会列表显示的相关全局变量定义
local g_GuildCurPageIndex_KServer = 0;
local g_GuildTotalPageNum_KServer = 0;

--跨服宣战界面当前选择的服务器的ZoneWorldID(此变量在玩家跨服宣战时作为参数调用相应C++接口)
local g_CurrentSelectedServer = 0;
local g_MatchTestBeginTime = 20141218			--点击雄霸天下按钮时进行以下判断,当前时间是否处于2014年12月18日0点之后
local g_MatchTestBeg_LM	= 20141128				-- 龙门测试赛开始时间

--===============================================
-- OnLoad()
--===============================================
function NewBangHui_Xuanzhan_PreLoad()
	this:RegisterEvent("NEW_BANGHUI_BHXZ_OPEN")
	this:RegisterEvent("GUILD_SHOW_GUILDBATTLE")
	this:RegisterEvent("GUILD_SHOW_ENEMYLIST");
	this:RegisterEvent("GUILD_UPDATE_ENEMYLIST");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("GUILD_SHOW_MEMBERINFO")
	this:RegisterEvent("GUILD_SHOW_DETAILINFO")
	this:RegisterEvent("GUILD_LEAGUE_INFO")
	this:RegisterEvent("OPEN_BUILD_INTRODUCE")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("SHOW_GUILDWAR_ANIMI")
	this:RegisterEvent("ZHANTUAN_LIST_DATA");
	this:RegisterEvent("OPENMYALLIANCE");
	this:RegisterEvent("OPEN_GUILD_GIFT")
	this:RegisterEvent("GUILD_BIDDING_SHOWLIST")
	--this:RegisterEvent("TCITYWARLIMIT_OPENCANDIDATE")
end

function NewBangHui_Xuanzhan_OnLoad()
	g_CtrlNewBanHui = {	xuanzhan_name=NewBangHui_Xuanzhan_Frame2_Lace1_Title1_Text,
									list=NewBangHui_Xuanzhan_BenfuMember_List1,
									banghuilist = NewBangHui_Xuanzhan_BenfuMember_List,
									KListText = NewBangHui_Xuanzhan_XuanFuYD,
									KComboList = NewBangHui_Xuanzhan_Xuanfu,
									xuanzhanid = NewBangHui_Xuanzhan_Id,

	};
	g_NewBangHui_Xuanzhan_Frame_UnifiedPosition = NewBangHui_Xuanzhan_Frame:GetProperty("UnifiedPosition");
end

--===============================================
-- OnEvent()
--===============================================
function NewBangHui_Xuanzhan_OnEvent( event )

	if event == "NEW_BANGHUI_BHXZ_OPEN" then
		NewBangHui_Xuanzhan_Bhxz:SetCheck(1)
		City:AskBattleList(0);
		City:AskBattleList(1);
		--如果玩家在K服,还需要请求跨服宣战和跨服帮会的信息
		if KVKInterface:IsInKVKServer() == 1 or IsInTServer() == 1 then
			--向K服获取整个大世界所有服务器组的帮会信息列表
			City:AskKServerGuildList();
			--重新获取跨服宣战和应战的帮会信息
			City:AskKServerGuildEnemyList();
		end
		City:AskEnemyList(0);
		City:AskEnemyList(1);
		City:GetGuildListWithCity();
		Guild:CloseKickGuildBox();

		NewBangHui_Xuanzhan_InitDlg()
		NewBangHui_Xuanzhan_SetTitle()
	elseif event == "GUILD_SHOW_GUILDBATTLE" then
		local nType = tonumber(arg0)
		if nType == 1 then
			NewBangHui_Xuanzhan_UpDate(nType)
		elseif nType == 0 then
			NewBangHui_Xuanzhan_UpDate(nType)
		end
	elseif event == "GUILD_SHOW_ENEMYLIST"	then
		NewBangHui_Xuanzhan_SetDynamic_Pos()
		if KVKInterface:IsInKVKServer() == 1 or (IsInTServer() == 1 and 1 == IsInFengMingServer()) then
			if KaJi:LuaFnIsKaJiServer() == 1 or DataPool:Lua_IsNewServerPlayer() == 1 then
				NewBangHui_Xuanzhan_Kuafu:Disable()
			else
				NewBangHui_Xuanzhan_Kuafu:Enable()
			end


		else
			NewBangHui_Xuanzhan_Kuafu:Disable();
			if g_IsAcrossServer == 1 then
				g_IsAcrossServer=0;
			end
		end

		NewBangHui_Xuanzhan_UpdateEnemylist()
		this:Show()

		-- -- 霸者天下小红点
		-- local bztxApplyNum = DataPool:TCWLGetAssistApplyNum()
		-- if (bztxApplyNum <= 0) then
		-- 	NewBangHui_Xuanzhan_BZTX_Tips:Hide()
		-- else
		-- 	local isChiefOrAss = Guild:IsChieforAss()
		-- 	if (isChiefOrAss ~= 1) then
		-- 		NewBangHui_Xuanzhan_BZTX_Tips:Hide()
		-- 	else
		-- 		NewBangHui_Xuanzhan_BZTX_Tips:Show()
		-- 	end
		-- end
	elseif event == "GUILD_UPDATE_ENEMYLIST" then
		if( this:IsVisible() ) then
			NewBangHui_Xuanzhan_UpdateEnemylist();
		end
	elseif event == "GUILD_SHOW_MEMBERINFO" then
		NewBangHui_Xuanzhan_Closed()
	elseif event == "GUILD_SHOW_DETAILINFO" then
		NewBangHui_Xuanzhan_Closed()
	elseif event == "GUILD_LEAGUE_INFO" then
		NewBangHui_Xuanzhan_Closed()
	elseif event == "OPEN_BUILD_INTRODUCE" then
		NewBangHui_Xuanzhan_Closed()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		NewBangHui_Xuanzhan_Closed()
	elseif event == "ADJEST_UI_POS" then
		NewBangHui_Xuanzhan_Frame_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		NewBangHui_Xuanzhan_Frame_On_ResetPos()
	elseif ( event == "ZHANTUAN_LIST_DATA" ) then
		this:Hide();
	elseif (event == "SHOW_GUILDWAR_ANIMI" ) then
		local type = arg0;
		if (arg0 == "show") then
			NewBangHui_Xuanzhan_Bhxz:SetText("#g0071BF#{BHJM_140520_04}")
			NewBangHui_Xuanzhan_Bhxz:SetToolTip("你的帮会正在帮战");
		else
		    NewBangHui_Xuanzhan_Bhxz:SetText("#{BHJM_140520_04}");
			NewBangHui_Xuanzhan_Bhxz:SetToolTip("");
		end
	elseif (event == "OPENMYALLIANCE") then
		NewBangHui_Xuanzhan_Closed()
	elseif (event == "OPEN_GUILD_GIFT" ) then
		NewBangHui_Xuanzhan_Closed()
	elseif event == "GUILD_BIDDING_SHOWLIST" then
		NewBangHui_Xuanzhan_Closed()
	elseif event == "TCITYWARLIMIT_OPENCANDIDATE" then
		NewBangHui_Xuanzhan_Closed()
	end
end

function NewBangHui_Xuanzhan_KVKLeague_Clicked()
	local alliancemark = 0;
end

function NewBangHui_Xuanzhan_UpdateEnemylist()
	NewBangHui_Xuanzhan_Id:SetText("");
	if g_IsAcrossServer==0 then
		NewBangHui_Xuanzhan_RefreshInterface_LocalServer();
	else
		NewBangHui_Xuanzhan_RefreshInterface_KServer();
	end
end

function NewBangHui_Xuanzhan_BenfuMember_Button( Index )
		local nCount 	 = g_CtrlNewBanHui.list:GetItemCount();
		if nCount <= Index then
			return
		end
		local nGuildID = 0;
		if g_IsAcrossServer==0 then
			nGuildID  = g_CtrlNewBanHui.list:GetItemText(Index, 0 );
		else
			nGuildID  = NewBangHui_Xuanzhan_Xuanfu:GetItemText(Index, 0 );
		end
		--local nGulidid = City:EnumCityEnemy(0,0,"guildid");
		--PushDebugMessage(nGuildID)
		nGuildID = nGuildID + 0 ;
		City:AskBattleRankListByGuild(nGuildID);
end


function NewBangHui_Xuanzhan_RefreshInterface_LocalServer()
	--设置两个按钮的显示效果,两个只有一个是按下的效果
	NewBangHui_Xuanzhan_Kuafu:SetProperty("Selected","False");
	NewBangHui_Xuanzhan_Benfu:SetProperty("Selected","True");

	g_CtrlNewBanHui.xuanzhan_name:SetText("#{BHJM_140520_110}");
	g_CtrlNewBanHui.list:RemoveAllItem();

	NewBangHui_Xuanzhan_Help2:Show()
	NewBangHui_Xuanzhan_Initiator:SetToolTip("#{BHJM_140520_182}")

	local nNum = City:GetEnemyNum(0);
	local ListIndex = nNum;
	local ButtonIndex;
	for i = 0, nNum-1 do
		local nGulidid = City:EnumCityEnemy(0,i,"guildid");
		local szGuildName = City:EnumCityEnemy(0,i,"name");
		local szLeftTime = City:EnumCityEnemy(0,i,"lefttime");

		--在帮会ID之前需要加两个空格,这样子界面会好看一些
		g_CtrlNewBanHui.list:AddNewItem("  "..nGulidid, 0, i);
		g_CtrlNewBanHui.list:AddNewItem(szGuildName, 1, i);
		g_CtrlNewBanHui.list:AddNewItem("宣战", 2, i);
		g_CtrlNewBanHui.list:AddNewItem(szLeftTime, 3, i);

		ButtonIndex = i+1;


	end

	nNum = City:GetEnemyNum(1);
	for j=0 , nNum-1 do
		local nGulidid = City:EnumCityEnemy(1,j,"guildid");
		local szGuildName = City:EnumCityEnemy(1,j,"name");
		local szLeftTime = City:EnumCityEnemy(1,j,"lefttime");

		--在帮会ID之前需要加两个空格,这样子界面会好看一些
		g_CtrlNewBanHui.list:AddNewItem("  "..nGulidid, 0, ListIndex+j);
		g_CtrlNewBanHui.list:AddNewItem(szGuildName, 1, ListIndex+j);
		g_CtrlNewBanHui.list:AddNewItem("应战", 2, ListIndex+j);
		g_CtrlNewBanHui.list:AddNewItem(szLeftTime, 3, ListIndex+j);
		ButtonIndex = j+1;

	end

	g_CtrlNewBanHui.banghuilist:RemoveAllItem();

	local TotalGuildNum = Guild:GetGuildNum();

	local PageStart = g_GuildCurPageIndex * g_GuildNumPerPage;
	local PageEnd
	if	( PageStart + g_GuildNumPerPage - 1 ) < ( TotalGuildNum - 1 ) then
		PageEnd = PageStart + g_GuildNumPerPage - 1;
	else
		PageEnd = TotalGuildNum - 1;
	end

	for i = PageStart, PageEnd do
		local GuildName 		= Guild:GetGuildInfo(i, "Name");
		local GuildId			= Guild:GetGuildInfo(i, "ID");
		local GuildChiefName 	= Guild:GetGuildInfo(i, "ChiefName");
		local GuildCityName 	= Guild:GetGuildInfo(i, "CityName");

		--在帮会ID之前需要加两个空格,这样子界面会好看一些
		g_CtrlNewBanHui.banghuilist:AddNewItem("  "..GuildId, 0, i - PageStart);
		g_CtrlNewBanHui.banghuilist:AddNewItem(GuildName, 1, i - PageStart);
		g_CtrlNewBanHui.banghuilist:AddNewItem(GuildChiefName, 2, i - PageStart);
	end

	g_GuildTotalPageNum = math.floor((TotalGuildNum-1)/g_GuildNumPerPage) + 1;

	--防止出现没有帮会的时候,页面指示"1/0"的情况
	--照理说本服不会出现这个情况,因为玩家没有帮会的话打不开该界面
	if g_GuildTotalPageNum == 0 then
		g_GuildTotalPageNum = 1;
	end

	NewBangHui_Xuanzhan_CurrentlyPage:SetText((g_GuildCurPageIndex+1).."/"..g_GuildTotalPageNum);


	if g_GuildCurPageIndex <= 0 then
		NewBangHui_Xuanzhan_UpPage:Disable();
	else
		NewBangHui_Xuanzhan_UpPage:Enable();
	end

	if g_GuildCurPageIndex >= g_GuildTotalPageNum-1 then
		NewBangHui_Xuanzhan_DownPage:Disable();
	else
		NewBangHui_Xuanzhan_DownPage:Enable();
	end

	g_CtrlNewBanHui.KListText:Hide()
	g_CtrlNewBanHui.KComboList:Hide()

end

function NewBangHui_Xuanzhan_UpDate(nType)
	if nType == 0 then
		NewBangHui_Xuanzhan_Zhengtao_List:RemoveAllItem();
		local nNum = City:GetBattleNum(nType)

		for i = 0 , nNum - 1 do
			local nGulidid 		= City:EnumBattleGuild(nType,i,"guildid");
			local szGuildName = City:EnumBattleGuild(nType,i,"name");
			local szLeftTime 	= City:EnumBattleGuild(nType,i,"lefttime");
			NewBangHui_Xuanzhan_Zhengtao_List:AddNewItem(nGulidid, 0, i);
			NewBangHui_Xuanzhan_Zhengtao_List:AddNewItem(szGuildName, 1, i);
			NewBangHui_Xuanzhan_Zhengtao_List:AddNewItem(szLeftTime, 2, i);
		end

	elseif nType == 1 then
		NewBangHui_Xuanzhan_ZhengtaoYingzhan_List:RemoveAllItem();
		local nNum = City:GetBattleNum(nType)

		for i = 0 , nNum - 1 do
			local nGulidid 		= City:EnumBattleGuild(nType,i,"guildid");
			local szGuildName = City:EnumBattleGuild(nType,i,"name");
			local szLeftTime 	= City:EnumBattleGuild(nType,i,"lefttime");
			NewBangHui_Xuanzhan_ZhengtaoYingzhan_List:AddNewItem(nGulidid, 0, i);
			NewBangHui_Xuanzhan_ZhengtaoYingzhan_List:AddNewItem(szGuildName, 1, i);
			NewBangHui_Xuanzhan_ZhengtaoYingzhan_List:AddNewItem(szLeftTime, 2, i);
		end

	end
end

function NewBangHui_Xuanzhan_Zhengtao_Click()

	local guid = NewBangHui_Xuanzhan_Zhengtao_Id:GetText();
	if(tonumber(guid)==nil)then
		PushDebugMessage("帮会id不能为空！");
		return;
	end
	City:SendAddGuildBattleMsg(tonumber(guid));
end

function NewBangHui_Xuanzhan_InitDlg()
	-- NewBangHui_Xuanzhan_Id:SetProperty("DefaultEditBox", "True");
	g_CtrlNewBanHui.xuanzhanid:SetText("");
end

function NewBangHui_Xuanzhan_Member_List_On_SelectionChanged()
	--获取当前选择的选项的Index
	local selectedIndex = NewBangHui_Xuanzhan_BenfuMember_List:GetSelectItem()
	--错误处理
	if selectedIndex < 0 then
		return
	end

	local guildIndex 	= 0
	local guildID		= 0
	if g_IsAcrossServer == 0 then		--当前选择的是本服帮会列表
		guildIndex 	=	g_GuildCurPageIndex * g_GuildNumPerPage + selectedIndex;
		guildID    	=	Guild:GetGuildInfo(guildIndex, "ID");
	else								--当前选择的是跨服帮会列表
		guildIndex	=	g_GuildCurPageIndex_KServer * g_GuildNumPerPage + selectedIndex;
		guildID		= 	City:GetGuildInfoBigWorld(g_CurrentSelectedServer, guildIndex, "GuildID");
	end
	g_CtrlNewBanHui.xuanzhanid:SetText(guildID);
end

function NewBangHui_Xuanzhan_Closed()
	g_CurrentSelectedServer = 0
	this:Hide()
end

function NewBangHui_Xuanzhan_XuanzhanBtn_Click()
	local guid = NewBangHui_Xuanzhan_Id:GetText();
	if(tonumber(guid)==nil)then
		PushDebugMessage("帮会id不能为空！");
		return;
	end

	if g_IsAcrossServer==0 then
		--City:SendAddEnemyMsg(tonumber(guid));
		City:OpenAddEnemyDlg("BenFu",tonumber(guid));
	else
		--调用客户端C++接口,进行跨服宣战
		--City:AddKServerEnemyList(g_CurrentSelectedServer, tonumber(guid));
		City:OpenAddEnemyDlg("KuaFu",tonumber(guid),g_CurrentSelectedServer);
	end
end

function NewBangHui_Xuanzhan_Hygl_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Xuanzhan_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ToggleGuildDetailInfo()
end

function NewBangHui_Xuanzhan_Bhxx_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Xuanzhan_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:AskGuildDetailInfo();
	Guild:CloseKickGuildBox();
end

function NewBangHui_Xuanzhan_Bhxz_Clicked()

end

function NewBangHui_Xuanzhan_Tmxx_Clicked()
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
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Xuanzhan_Frame:GetProperty("UnifiedPosition"), 1);
    GuildLeague:ShowInfoWindow()
end

function NewBangHui_Xuanzhan_JZWJS_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Xuanzhan_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ShowCityBuildIntroduce()
end

function NewBangHui_Xuanzhan_DownPage_Click()
	--如果是在本服帮会对应的"下一页按钮"
	if g_IsAcrossServer == 0 then
		if g_GuildCurPageIndex >= g_GuildTotalPageNum - 1 then
			return
		else
			g_GuildCurPageIndex = g_GuildCurPageIndex + 1
			if g_GuildCurPageIndex >= g_GuildTotalPageNum - 1 then
				NewBangHui_Xuanzhan_DownPage:Disable()
			end
			if g_GuildCurPageIndex > 0 then
				NewBangHui_Xuanzhan_UpPage:Enable()
			end
		end
	else
		if g_GuildCurPageIndex_KServer >= g_GuildTotalPageNum_KServer - 1 then
			return
		else
			g_GuildCurPageIndex_KServer = g_GuildCurPageIndex_KServer + 1
			if g_GuildCurPageIndex_KServer >= g_GuildTotalPageNum_KServer - 1 then
				NewBangHui_Xuanzhan_DownPage:Disable()
			end
			if g_GuildCurPageIndex_KServer > 0 then
				NewBangHui_Xuanzhan_UpPage:Enable()
			end
		end
	end
	NewBangHui_Xuanzhan_UpdateEnemylist();
end

function NewBangHui_Xuanzhan_UpPage_Click()
	--如果是在本服帮会对应的"上一页按钮"
	if g_IsAcrossServer == 0 then
		if g_GuildCurPageIndex <= 0 then
			return
		else
			g_GuildCurPageIndex = g_GuildCurPageIndex - 1
			if g_GuildCurPageIndex <= 0 then
				NewBangHui_Xuanzhan_UpPage:Disable();
			end
			if g_GuildCurPageIndex < g_GuildTotalPageNum - 1 then
				NewBangHui_Xuanzhan_DownPage:Enable();
			end
		end
	else
		if g_GuildCurPageIndex_KServer <= 0 then
			return
		else
			g_GuildCurPageIndex_KServer = g_GuildCurPageIndex_KServer - 1
			if	g_GuildCurPageIndex_KServer <=0 then
				NewBangHui_Xuanzhan_UpPage:Disable();
			end
			if g_GuildCurPageIndex_KServer < g_GuildTotalPageNum_KServer - 1 then
				NewBangHui_Xuanzhan_DownPage:Enable();
			end
		end
	end
	NewBangHui_Xuanzhan_UpdateEnemylist();
end

function NewBangHui_Xuanzhan_RefreshInterface_KServer()

	g_CtrlNewBanHui.KListText:Show()
	g_CtrlNewBanHui.KComboList:Show()

	g_CtrlNewBanHui.xuanzhan_name:SetText("#{BHJM_140520_101}");

	NewBangHui_Xuanzhan_Help2:Hide()
	NewBangHui_Xuanzhan_Initiator:SetToolTip("#{BHJM_180623_188}")
	--1.设置并刷新界面中服务器选择部分
	--第一次打开界面，没有选择需要查看的服务器组，则默认选择第一个

	local WorldNum = City:GetKServerWorldNum();

	--如果没有其他服务器组(当然,按照正常逻辑时不可能出现这种情况的),则将整个页面刷为空
	if WorldNum == 0 then
		NewBangHui_Xuanzhan_Xuanfu:Show()
		NewBangHui_Xuanzhan_Xuanfu:ResetList();
		NewBangHui_Xuanzhan_BenfuMember_List1:RemoveAllItem();
		NewBangHui_Xuanzhan_BenfuMember_List:RemoveAllItem();
		NewBangHui_Xuanzhan_CurrentlyPage:SetText("0/0");
		NewBangHui_Xuanzhan_UpPage:Disable();
		NewBangHui_Xuanzhan_DownPage:Disable();
		return
	end

	if g_CurrentSelectedServer == 0 then
		NewBangHui_Xuanzhan_Xuanfu:ResetList();
		for i= 0, WorldNum - 1 do
			local WorldName = City:GetKServerZoneWorldNameByIndex(i);
			NewBangHui_Xuanzhan_Xuanfu:AddTextItem(WorldName ,i + 1)
		end
		g_CurrentSelectedServer = City:GetKServerZoneWorldIdByIndex(0);
		NewBangHui_Xuanzhan_Xuanfu:SetCurrentSelect(0)
	end

	--2.设置界面中帮会宣战列表部分
	NewBangHui_Xuanzhan_BenfuMember_List1:RemoveAllItem();

		--先添加宣战帮会
	local szGuildName = City:GetKServerEnemyInfo("xuanzhan", "GuildName");
	local szLeftTime  = City:GetKServerEnemyInfo("xuanzhan", "LeftTime");
	local szGuildID   = City:GetKServerEnemyInfo("xuanzhan", "GuildID");

	local Index = 0;
	if( szGuildID ~= -1 ) then
		--在帮会ID之前需要加两个空格,这样子界面会好看一些
		NewBangHui_Xuanzhan_BenfuMember_List1:AddNewItem("  "..szGuildID, 0, Index);
		NewBangHui_Xuanzhan_BenfuMember_List1:AddNewItem(szGuildName, 1, Index);
		NewBangHui_Xuanzhan_BenfuMember_List1:AddNewItem("宣战", 2, Index);
		NewBangHui_Xuanzhan_BenfuMember_List1:AddNewItem(szLeftTime, 3, Index);
		Index = Index + 1;
	end
		--再添加应战帮会
	szGuildName = City:GetKServerEnemyInfo("yingzhan", "GuildName");
	szLeftTime  = City:GetKServerEnemyInfo("yingzhan", "LeftTime");
	szGuildID   = City:GetKServerEnemyInfo("yingzhan", "GuildID");
	if( szGuildID ~= -1) then
		--在帮会ID之前需要加两个空格,这样子界面会好看一些
		NewBangHui_Xuanzhan_BenfuMember_List1:AddNewItem("  "..szGuildID, 0, Index);
		NewBangHui_Xuanzhan_BenfuMember_List1:AddNewItem(szGuildName, 1, Index);
		NewBangHui_Xuanzhan_BenfuMember_List1:AddNewItem("应战", 2, Index);
		NewBangHui_Xuanzhan_BenfuMember_List1:AddNewItem(szLeftTime, 3, Index);
	end
	--3.添加刷新帮会信息列表
	NewBangHui_Xuanzhan_BenfuMember_List:RemoveAllItem();
	local TotalGuildNum = City:GetGuildNumByZoneWorldId( g_CurrentSelectedServer );
	local PageStart = g_GuildCurPageIndex_KServer * g_GuildNumPerPage;
	local PageEnd
	if	( PageStart + g_GuildNumPerPage - 1 ) < ( TotalGuildNum - 1 ) then
		PageEnd = PageStart + g_GuildNumPerPage - 1;
	else
		PageEnd = TotalGuildNum - 1;
	end

	for i = PageStart, PageEnd do
		local GuildName 		= City:GetGuildInfoBigWorld(g_CurrentSelectedServer, i, "GuildName");
		local GuildId 			= City:GetGuildInfoBigWorld(g_CurrentSelectedServer, i, "GuildID");
		local GuildChiefName 	= City:GetGuildInfoBigWorld(g_CurrentSelectedServer, i, "ChiefName");
		--在帮会ID之前需要加两个空格,这样子界面会好看一些
		NewBangHui_Xuanzhan_BenfuMember_List:AddNewItem("  "..GuildId, 0, i-PageStart);
		NewBangHui_Xuanzhan_BenfuMember_List:AddNewItem(GuildName, 1, i-PageStart);
		NewBangHui_Xuanzhan_BenfuMember_List:AddNewItem(GuildChiefName, 2, i-PageStart);
	end

	g_GuildTotalPageNum_KServer = math.floor((TotalGuildNum-1)/g_GuildNumPerPage) + 1;

		--防止出现没有帮会的时候,页面指示"1/0"的情况
	if g_GuildTotalPageNum_KServer == 0 then
		g_GuildTotalPageNum_KServer = 1;
	end

	NewBangHui_Xuanzhan_CurrentlyPage:SetText((g_GuildCurPageIndex_KServer+1).."/"..g_GuildTotalPageNum_KServer);

	if g_GuildCurPageIndex_KServer <= 0 then
		NewBangHui_Xuanzhan_UpPage:Disable();
	else
		NewBangHui_Xuanzhan_UpPage:Enable();
	end

	if g_GuildCurPageIndex_KServer >= g_GuildTotalPageNum_KServer-1 then
		NewBangHui_Xuanzhan_DownPage:Disable();
	else
		NewBangHui_Xuanzhan_DownPage:Enable();
	end

	--显示服务器选择控件
	NewBangHui_Xuanzhan_Xuanfu:Show();
	--显示服务器选择控件提示语
	NewBangHui_Xuanzhan_XuanFuYD:Show();

end

function NewBangHui_Xuanzhan_ZY_SelectionChanged()
end

function NewBangHui_Xuanzhan_Zhengtao_List_On_SelectionChanged()
end

function NewBangHui_Xuanzhan_Tiaozhan_ButtonClick()
	local nSelected = NewBangHui_Xuanzhan_ZhengtaoYingzhan_List:GetSelectItem();
	if(nSelected >= 0) then
		City:SelectGuildBattle(nSelected);
	end
end

function NewBangHui_Xuanzhan_KuafuBtn_Click()
	if DataPool:Lua_IsNewServerPlayer() == 1 or KaJi:LuaFnIsKaJiServer() == 1 then
		PushDebugMessage( "#{XFZQ_220120_02}" )
		return
	end

	if  Lua_GetAnonymousSceneInfo() == 1 then
		NewBangHui_Xuanzhan_Kuafu:SetProperty("Selected", "False");
		NewBangHui_Xuanzhan_Benfu:SetProperty("Selected", "True");
		PushDebugMessage( "#{YCXX_20220712_09}" )
		return
	end

	g_IsAcrossServer=1;
	g_GuildCurPageIndex_KServer = 0

	NewBangHui_Xuanzhan_UpdateEnemylist();
end

function NewBangHui_Xuanzhan_CurrentSelectedServer__Changed()
	--获取玩家选择的服务器组的索引Index
	local _, nIndex = NewBangHui_Xuanzhan_Xuanfu:GetCurrentSelect()
	--根据获取的索引,设置当前选择的服务器组ID
	g_CurrentSelectedServer = City:GetKServerZoneWorldIdByIndex(nIndex-1);
	--重新设置当前K服显示的帮会页面为首页
	g_GuildCurPageIndex_KServer = 0;
	--刷新页面
	NewBangHui_Xuanzhan_UpdateEnemylist();
end

function NewBangHui_Xuanzhan_BenfuBtn_Click()
	g_IsAcrossServer=0;
	g_GuildCurPageIndex = 0;

	NewBangHui_Xuanzhan_UpdateEnemylist();
end

function NewBangHui_Xuanzhan_Frame_On_ResetPos()
	 NewBangHui_Xuanzhan_Frame:SetProperty("UnifiedPosition", g_NewBangHui_Xuanzhan_Frame_UnifiedPosition)
end

function NewBangHui_Xuanzhan_SetDynamic_Pos()
    local selfGuildClanUnionPos = Variable:GetVariable("SelfGuildClanUnionPos")
	if( selfGuildClanUnionPos ~= nil) then
	    NewBangHui_Xuanzhan_Frame:SetProperty("UnifiedPosition", selfGuildClanUnionPos )
	end
end

function NewBangHui_Xuanzhan_SetTitle()
	local szName = Guild:GetMyGuildName("Name");
	local title = ScriptGlobal_Format("#{BHJM_140520_01}", szName)
	NewBangHui_Xuanzhan_PageHeader:SetText(title)
end

--帮会联赛 by wangbin
function NewBangHui_Xuanzhan_BHLS_Clicked()
	local nCurTime = tonumber(DataPool:GetServerDayTime());
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID();
	if selfZoneWorldID == 9031 or selfZoneWorldID == 9015 then
		if ( nCurTime < g_MatchTestBeg_LM ) then
			PushDebugMessage( "#{BHKF_140909_419}" );
			NewBangHui_Xuanzhan_Bhxz:SetCheck(1);
			Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Xuanzhan_Frame:GetProperty("UnifiedPosition"), 1);
			return
		end
	else
		if ( nCurTime < g_MatchTestBeginTime ) then
			PushDebugMessage( "#{BHKF_140909_419}" );
			NewBangHui_Xuanzhan_Bhxz:SetCheck(1);
			Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Xuanzhan_Frame:GetProperty("UnifiedPosition"), 1);
			return
		end
	end

	local nStatus = ZhanTuanInterface:GetZhanTuanInfo();
	if(0 == tonumber(nStatus)) then
		NewBangHui_Xuanzhan_Bhxz:SetCheck(1)
	end
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Xuanzhan_Frame:GetProperty("UnifiedPosition"), 1);
end

function NewBangHui_Xuanzhan_HB_OnClicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Xuanzhan_Frame:GetProperty("UnifiedPosition"), 1)
	Guild:OpentGuildGiftUI()
end

function NewBangHui_Xuanzhan_CD_OnClicked()
	PushEvent("OPEN_XUANZHANCD_HELP")
end

--拍卖
function NewBangHui_Xuanzhan_Auction_Clicked()
  --if KaJi:LuaFnIsKaJiServer() == 1 then
  --	PushDebugMessage("#{SCBHPM_20220815_143}")
--	return
 -- end
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
  Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Xuanzhan_Frame:GetProperty("UnifiedPosition"), 1);
  Guild:AskGuildBiddingInfo(0, 1, -1)
end

function NewBangHui_Xuanzhan_BZTX_Clicked()
	-- if (Player:GetData("TCWLSvrOpenFlag") < 0) then
	-- 	NewBangHui_Xuanzhan_BZTX:SetCheck(0)
	-- 	NewBangHui_Xuanzhan_Bhxz:SetCheck(1)

	-- 	PushDebugMessage("#{GCQH_240429_161}")
	-- elseif (Player:GetData("TCWLSvrOpenFlag") == 0) then
	-- 	NewBangHui_Xuanzhan_BZTX:SetCheck(0)
	-- 	NewBangHui_Xuanzhan_Bhxz:SetCheck(1)

	-- 	PushDebugMessage("#{GCQH_240429_154}")
	-- else
	-- 	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Xuanzhan_Frame:GetProperty("UnifiedPosition"), 1);
	-- 	Guild:TCWLOpenLCandidateUI()
	-- end
end -- end func NewBangHui_Xuanzhan_BZTX_Clicked()

function NewBangHui_Xuanzhan_BZZT_Clicked()
	local selfzoneid = DataPool:GetSelfZoneWorldID()
	if (KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(181) > 0) or 
		DataPool:Lua_IsNewServerPlayerByZWID(selfzoneid) == 1 or
		Player:GetData("IsOriginalJD")  == 1 or
		Player:GetData("Is2606S")  == 1 or 
		Player:GetData("SPECKAJI89") > 0 then
	  PushDebugMessage("#{ZTXT_260511_151}")
	  return
	end
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Xuanzhan_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("GUILD_ZHANTUAN_OP", 1)
end
