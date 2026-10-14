
local  g_TeamOutLineStr = {}
local  g_BGTeamOutLineStr = {}

local  g_Name = ""
local  g_Friend_IMGrouping_ZoneWorldId = -1
local  g_strFellowTitle = ""
function Friend_IMGrouping_PreLoad()
	this:RegisterEvent("OPEN_ADDFRIEND_GROUPING");

end

function Friend_IMGrouping_OnLoad()
	g_TeamOutLineStr = {
							{str = "#{LTQH_XML_79}"	, nIndex = 1},
							{str = "#{LTQH_XML_80}"	, nIndex = 2},
							{str = "#{LTQH_XML_81}" , nIndex = 3},
							{str = "#{LTQH_XML_82}"	, nIndex = 4},
							{str = "临时好友"		, nIndex = 13},
						}
	g_BGTeamOutLineStr = {
							{str = "#{KVKGZ_110620_122}"	, nIndex = 8},
							{str = "#{KVKGZ_110620_123}"	, nIndex = 9},
							{str = "#{KVKGZ_110620_124}"		, nIndex = 14},
						}

end

function Friend_IMGrouping_OnEvent(event)
	if event == "OPEN_ADDFRIEND_GROUPING" then
		g_Name = tostring(arg0)
		
		-- 废弃，改为所有加好友都判断是否为同门，不再只针对同门界面
		--if arg1 and (0 ~= tonumber(arg1)) and (1 ~= tonumber(arg1)) then
		--	g_strFellowTitle = tostring(arg1)
		--else
		--	g_strFellowTitle = ""
		--end
		
		if arg1 and (1 == tonumber(arg1)) then
			if arg2 then
				g_Friend_IMGrouping_ZoneWorldId = tonumber(arg2)
			end
			Friend_IMGrouping_Show(1)
		else
			g_Friend_IMGrouping_ZoneWorldId = -1
			Friend_IMGrouping_Show(0)
		end
	end
end



function Friend_IMGrouping_Show(bBigWorld)

	-- 获得师门数据，判断被加玩家是否是自己的同门，并获得该同门对“我”的称呼
	local bIsFellow = 0
	local tabTitles = {"大","二","三","四","五","六","七","八"}
	local strSelfFellowTitlePrefix = ""		-- 同门对自己的称呼前缀
	local strSelfFellowTitleSuffix = ""		-- 同门对自己的称呼后缀
	local strFellowTitle = ""				-- 自己对同门的称呼
	local strFellowTitlePrefix = ""			-- 自己对同门的称呼前缀
	local strFellowTitleSuffix = ""			-- 自己对同门的称呼后缀
	local nMyrank = 8						-- 自己在师门的排序
	
	PushEvent("ASK_SHIMENINFO")
	PushEvent("UPDATE_FRIEND")
	
	-- 遍历师门获得信息
	for i=0,8 do
		local nGUID,
		szCharName,
		nType,
		nSex,
		nLevel,
		szGuildName,
		nQinmi,
		nGongfeng,
		nStartDay,
		nIsOnline	= WenDingUI:GetShiMenInfoByIdx(i, 1)
		
		if nil ~= szCharName and nil ~= g_Name and nil ~= nType then
			if 2 == nType and "" ~= szCharName then
				if szCharName == Player:GetName() then
					-- 获得自己的师门排序
					nMyrank = i
					-- 获得同门对自己称呼前缀
					strSelfFellowTitlePrefix = tabTitles[i]
				end
				if szCharName == g_Name then
					local BigstrSuffixes = "师姐"
					local SmallstrSuffixes = "师妹"
					if 1 == Player:GetMySex() then
						BigstrSuffixes = "师兄"
						SmallstrSuffixes = "师弟"
					end 
					if nSex == 1 then
						if i > nMyrank then
							strSelfFellowTitleSuffix = BigstrSuffixes
							strFellowTitleSuffix = "师弟"
						else
							strSelfFellowTitleSuffix = SmallstrSuffixes
							strFellowTitleSuffix = "师兄"
						end
					else
						if i > nMyrank then
							strSelfFellowTitleSuffix = BigstrSuffixes
							strFellowTitleSuffix = "师妹"
						else
							strSelfFellowTitleSuffix = SmallstrSuffixes
							strFellowTitleSuffix = "师姐"
						end
					end
					-- 获得自己对同门称号前缀
					strFellowTitlePrefix = tabTitles[i]
					bIsFellow = 1
				end
			end
		end
	end
	
	if 1 == bIsFellow then
		-- 被加玩家是同门
		g_strFellowTitle = strSelfFellowTitlePrefix..strSelfFellowTitleSuffix
		strFellowTitle = strFellowTitlePrefix..strFellowTitleSuffix
	else
		g_strFellowTitle = ""
		strFellowTitle = ""
	end
	
	-- 同世界玩家
	if bBigWorld == 0 then
		--如果不满足条件则不显示
		local iTmp = 1;
		local currentList = 0
		local friendnumber = 0
		for iTmp = 1, 4 do
		  currentList = iTmp; -- friend
		 	local number = DataPool:GetFriendNumber( tonumber( currentList ) );
		 	local index = 0;
		 	while index < number  do
		 		local name =  DataPool:GetFriend( currentList, tonumber( index ), "NAME" );
		 		if (name == g_Name) then
		 		    PushDebugMessage("#{GCRelationHandler_Info_Is_Firend}"); --("该玩家已经是您的好友。");
		 			return;
		 		end
		 		index = index + 1;
		  end
		  friendnumber = friendnumber + number
		end
		if friendnumber >= 80 then--好友已达上限
			PushDebugMessage("#{LTQH_XML_105}"); --("您目前的好友已达上限，请整理好友列表后再选择添加好友");
			return
		end
		Friend_IMGrouping_Select:ResetList()
		local strGroupName = ""
		for i = 0 , 3 do
			strGroupName = DataPool:GetGroupingName(i)
			if strGroupName ~= "" then
				Friend_IMGrouping_Select:AddTextItem(strGroupName  , i + 1);
			else
				Friend_IMGrouping_Select:AddTextItem(g_TeamOutLineStr[i+1].str  , g_TeamOutLineStr[i+1].nIndex);
			end
		end
		
		Friend_IMGrouping_Select:AddTextItem(g_TeamOutLineStr[5].str  , g_TeamOutLineStr[5].nIndex);
		
		Friend_IMGrouping_Select:SetCurrentSelect(0)
		--Friend_IMGrouping_Text:SetText("  #cFFF263你已经确定将#G"..tostring(g_Name).."#cFFF263加为好友，请选择其分组")
		
		-- 显示同门提示 by lishilong 2016-10-9
		local strMsg =  ""
		if 1 == bIsFellow then
			Friend_IMGrouping_Tips:SetText("#{STYH_161009_14}")
			strMsg = ScriptGlobal_Format("#{STYH_161009_16}", strFellowTitle, g_Name)
		else
			Friend_IMGrouping_Tips:SetText("")
			strMsg = ScriptGlobal_Format("#{STYH_161009_15}", g_Name)
		end
		
		Friend_IMGrouping_Text:SetText(strMsg)
		
		this:Show();
	-- 不同世界玩家
	elseif bBigWorld == 1 then
		local iTmp = 1;
		local currentList = 0
		local friendnumber = 0
		for iTmp = 8, 9 do
		  currentList = iTmp; -- friend
		 	local number = DataPool:GetFriendNumber( tonumber( currentList ) );
		 	local index = 0;
		 	while index < number  do
		 		local name =  DataPool:GetFriend( currentList, tonumber( index ), "NAME" );
		 		local zoneworldID =  DataPool:GetFriend( currentList, tonumber( index ), "ZONEWORLDID" );
		 		if (name == g_Name) and (tonumber(zoneworldID) == g_Friend_IMGrouping_ZoneWorldId) then
		 		    PushDebugMessage("#{GCRelationHandler_Info_Is_Firend}"); --("该玩家已经是您的好友。");
		 			return;
		 		end
		 		index = index + 1;
		  end
		  friendnumber = friendnumber + number
		end
		if friendnumber >= 40 then--好友已达上限
			PushDebugMessage("#{LTQH_XML_105}"); --("您目前的好友已达上限，请整理好友列表后再选择添加好友");
			return
		end
		Friend_IMGrouping_Select:ResetList()
		local strGroupName = ""
		for i = 0 , 2 do
			Friend_IMGrouping_Select:AddTextItem(g_BGTeamOutLineStr[i+1].str  , g_BGTeamOutLineStr[i+1].nIndex);
		end
		
		Friend_IMGrouping_Select:SetCurrentSelect(0)
		local name = tostring(g_Name)
		if g_Friend_IMGrouping_ZoneWorldId ~= -1 and g_Friend_IMGrouping_ZoneWorldId ~= DataPool:GetSelfZoneWorldID() then
			name = name.."@"..DataPool:GetServerName(g_Friend_IMGrouping_ZoneWorldId)
		end
		
		-- Friend_IMGrouping_Text:SetText("  #cFFF263你已经确定将#G"..name.."#cFFF263加为好友，请选择其分组")	
		local strMsg = ScriptGlobal_Format("#{STYH_161009_15}", name)
		Friend_IMGrouping_Text:SetText(strMsg)
		
		this:Show();
	end
end


function Friend_IMGrouping_Hide()
	g_Name = ""
	g_Friend_IMGrouping_ZoneWorldId = -1
	this:Hide()
end

function Friend_IMGrouping_OK_Clicked()
	local str , nIndex = Friend_IMGrouping_Select:GetCurrentSelect()
	if g_Name ~= "" then
		if "" ~= g_strFellowTitle then
			-- 同门加好友，arg2为同门对“我”的称呼 by lishilong 2016-8-1
			DataPool:AddFriend(tonumber(nIndex) , g_Name, -1, g_strFellowTitle)
		else
			DataPool:AddFriend(tonumber(nIndex) , g_Name, g_Friend_IMGrouping_ZoneWorldId)
		end
	end
	Friend_IMGrouping_Hide();	
end