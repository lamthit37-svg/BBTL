-- 好友界面的默认位置
local g_Friend_Frame_UnifiedXPosition;
local g_Friend_Frame_UnifiedYPosition;


local g_PagePosTop = 0
local g_StepSize = 20
local g_Pages = {}

local g_CurPage = 0
local g_ListHeight = 0

local g_IsTeamOutLine = {}
local g_TeamOutLineStr = {}

local g_BigWorldLineStr = {}

local g_imgStar = {}
local g_AllStarLevelNum = 28

local g_CurStatus = 0

local g_imgStatus = {}

local g_FriendSpin = "  "	--2个空格缩进
local g_IconSpin = "    "	--4个空格缩进

local g_Current_Clicked = -1


local MIN_PASS_TIME = 2; --冷却时间
local g_Timer = -1;

--召唤好友的时间

local g_GroupTitleColor_WM = "#ce6c3a7#e4e3014"
local g_GroupTitleColor = "#gFE7E82 "

local g_FriendBorderColor = "#e010101"

--经典版的VIP图标素材
local g_VIP_Image = {	--VIP图标
	[1] = "set:CommonFrame19 image:VIPLevel_1",
	[2] = "set:CommonFrame19 image:VIPLevel_2",
	[3] = "set:CommonFrame19 image:VIPLevel_3",
	[4] = "set:CommonFrame19 image:VIPLevel_4",
	[5] = "set:CommonFrame19 image:VIPLevel_5",
	[6] = "set:CommonFrame19 image:VIPLevel_6",
	[7] = "set:CommonFrame19 image:VIPLevel_7",
	[8] = "set:CommonFrame19 image:VIPLevel_8",
	[9] = "set:CommonFrame19 image:VIPLevel_9",
--	[10] = "set:CommonFrame19 image:VIPLevel_10",
--	[11] = "set:CommonFrame19 image:VIPLevel_11",
--	[12] = "set:CommonFrame19 image:VIPLevel_12",
--	[13] = "set:CommonFrame19 image:VIPLevel_13",
--	[14] = "set:CommonFrame19 image:VIPLevel_14",
--	[15] = "set:CommonFrame19 image:VIPLevel_15",
--	[16] = "set:CommonFrame19 image:VIPLevel_16",
--	[17] = "set:CommonFrame19 image:VIPLevel_17",
--	[18] = "set:CommonFrame19 image:VIPLevel_18",
--	[19] = "set:CommonFrame19 image:VIPLevel_19",
--	[20] = "set:CommonFrame19 image:VIPLevel_20",
}

local g_SpecialFriendOutLine = {}

local g_BrotherOrderStr = {
	"#{JBLC_150528_193}",
	"#{JBLC_150528_194}",
	"#{JBLC_150528_195}",
	"#{JBLC_150528_196}",
	"#{JBLC_150528_197}",
	"#{JBLC_150528_198}"
}

local m_PosName = {
	"#{JBYH_161011_1}",
	"#{JBYH_161011_2}",
	"#{JBYH_161011_3}",
	"#{JBYH_161011_4}",
	"#{JBYH_161011_5}",
	"#{JBYH_161011_10}"
	
}

local m_OldName = {"#{JBYH_161011_7}","#{JBYH_161011_6}"} -- 姐、哥
local m_YoungName = {"#{JBYH_161011_9}","#{JBYH_161011_8}"} -- 妹、弟
 
--===============================================
-- OnLoad()
--===============================================
function Friend_PreLoad()

	this:RegisterEvent("TOGLE_FRIEND",true);

	this:RegisterEvent("UPDATE_FRIEND",false);

	this:RegisterEvent("UPDATE_BGFRIEND",false);

	this:RegisterEvent("UPDATE_FRIEND_INFO",false);

	this:RegisterEvent("FRIENDSEARCH_RESULT",false);
	this:RegisterEvent("UPDATE_GROUPLIST",false);

	this:RegisterEvent("IMONLINETIME_CHANGE",false)

	this:RegisterEvent("UPDATE_RECENT",false)
	this:RegisterEvent("UPDATE_GROUPINGNAME",false)

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("RESET_ALLUI",true)

	-- 这里写的无语，赶工程， 不要复制这样的写法
	-- this:RegisterEvent("GAMELOGIN_CLEAR_ACCOUNT",true)

	this:RegisterEvent("GS_FRIENDREFRESH_NEW",false)

	this:RegisterEvent("UNIT_LEVEL",false)
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	this:RegisterEvent("CHAT_SIGN_RED_POINT",false)
end

function Friend_OnLoad()
	if SystemSetup:IsClassic() == 0 then	--唯美版重新设置VIP图标图片素材
		g_VIP_Image = {
		[1] = "set:WM_Button2 image:VIP1",
		[2] = "set:WM_Button2 image:VIP2",
		[3] = "set:WM_Button2 image:VIP3",
		[4] = "set:WM_Button2 image:VIP4",
		[5] = "set:WM_Button2 image:VIP5",
		[6] = "set:WM_Button2 image:VIP6",
		[7] = "set:WM_Button2 image:VIP7",
		[8] = "set:WM_Button2 image:VIP8",
		[9] = "set:WM_Button2 image:VIP9",
		}
	end

	-- 保存好友界面的默认相对位置
	g_Friend_Frame_UnifiedXPosition	= Friend_Frame:GetProperty("UnifiedXPosition");
	g_Friend_Frame_UnifiedYPosition	= Friend_Frame:GetProperty("UnifiedYPosition");

	g_Pages = {
				Friend_List_Page1 ,
				Friend_List_Page5 ,
				Friend_List_Page2 ,
				Friend_List_Page3 ,
				Friend_List_Page4	,
				Friend_List_Page6	,
			}

	g_PagePosTop = Friend_List_Page1:GetProperty("AbsoluteYPosition")
	g_CurPage = 0
	g_ListHeight = Friend_List:GetProperty("AbsoluteHeight")

	g_IsTeamOutLine = {0,0,0,0,0,0,0,0,0,0,0,0,1}
	g_TeamOutLineStr = {
							"#{LTQH_XML_79}"	,
							"#{LTQH_XML_80}"	,
							"#{LTQH_XML_81}" 	,
							"#{LTQH_XML_82}"	,
							"黑名单"	,
							"仇人"		,
							"仇敌",
							[13] = "临时好友",
							[9] = "畅游精灵"

						}
	g_BigWorldLineStr = {
							[8] = "#{LTQH_XML_79}"	,
							[9] = "#{LTQH_XML_80}"	,
							[10] = "#{INTERFACE_XML_320}"	,
							[11] = "仇人"	,
							[14] = "#{GMDP_Struct_Relation_Desc_TempFriend}"	,
						}

	g_imgStar = {Friend_LevelIcons_1 ,
				Friend_LevelIcons_2,
				Friend_LevelIcons_3,
				Friend_LevelIcons_4,
				Friend_LevelIcons_5,
				Friend_LevelIcons_6,
				Friend_LevelIcons_7,}

	Friend_SelfState:AddTextItem("空闲" ,0)	--在线
	Friend_SelfState:AddTextItem("忙碌" ,1)	--忙碌
	Friend_SelfState:AddTextItem("离开" ,2)	--离开

	Friend_SelfState:SetCurrentSelect(0)

	g_imgStatus = {
			[0] = { [0] = "#-27" ,[1] = "#-29" ,[2] = "#-30"} ,
			[1] = { [0] = "#-23" ,[1] = "#-25" ,[2] = "#-26"} ,
		}

	g_Current_Clicked = -1

	if SystemSetup:IsClassic() == 0 then
		g_FriendBorderColor = "#e253b48"
	end
	
	g_SpecialFriendOutLine = {0,0,0,0}

end

--===============================================
-- OnEvent()
--===============================================
function Friend_OnEvent( event )
	if ( event == "TOGLE_FRIEND" ) then
		if( arg0 == "2" ) then
			if( this:IsVisible() ) then
				Friend_Hide();
			else
				Friend_Show();
			end
		elseif ( arg0 == "1" ) then
			Friend_Show();
		else
			Friend_Hide();
		end
	elseif (event == "GAMELOGIN_CLEAR_ACCOUNT") then
		-- GE_GAMELOGIN_CLEAR_ACCOUNT, 这里用这个事件详细说明：
		-- 目前没有一个好的事件表示第一次登陆，甚至连GCStopPadding都是不准的。
		-- 本来以为抓到了一根救命草  "UPDATE_FRIEND", 因为只有第一次登陆
		-- 才会触发请求好友列表， 最终会调用 PushEvent("UPDATE_FRIEND", "0")
		-- 这个经过严格查阅代码， 是没有这个问题的，  当接收到"UPDATE_FRIEND"事件后
		-- 并且判断arg0是否是"0", 杯具诞生了~·
		-- 这个问题是设计上的一个BUG.  我们知道UI_CEGUI回调脚本的XX_OnEvent时，
		-- 会设置arg0, arg1等变量， 如果本次update_friend没有参数呢？？？？？
		-- arg0, arg1还会是原来的值！！  这个玩家的切换场景导致了一次普通的不带参数的
		-- UPDATE_FRIEND, 而之前的arg0确实为"0", 就错误的以为出问题了~~~
		-- 在其他时候收到无参数的UPDATE_FRIEND时， 也会有概率的收到arg0为"0"
		-- 2010-9-10. 本想改掉这个BUG。 不知道会不会有人抓住这个”特性“错误的调用呢？？？？

	elseif( event == "UPDATE_FRIEND" ) then
			if g_CurPage == 1 then
				g_Current_Clicked = Friend_List:GetCurrentFirstItem();
				Friend_Update();
			else

			end
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
			Friend_Hide()
			return	
	elseif( event == "UPDATE_BGFRIEND" ) then
			if g_CurPage == 2 then
			if arg0 and tonumber(arg0) >= 8 and tonumber(arg0) <= 14 then
					Friend_List_BigWorld();
				else
				end
			end
	elseif( event == "UPDATE_RECENT" ) then
			if g_CurPage == 4 then
				g_Current_Clicked = Friend_List : GetCurrentFirstItem();
				Friend_Recent_List();
			else

			end
	elseif( event == "UPDATE_FRIEND_INFO" ) then
		if g_CurPage == 1 or g_CurPage == 2 then
			UpdateFriendInfo( tonumber( arg0 ), tonumber( arg1 ) );
		elseif g_CurPage == 4 then

			local id = DataPool:GetFriend( tonumber( arg0 ), tonumber( arg1 ), "ID" );
			local nIndex = DataPool:GetIMRecentByGUID(id)
			Friend_Update_Recent(nIndex)

		elseif g_CurPage == 5 then

			local id = DataPool:GetFriend( tonumber( arg0 ), tonumber( arg1 ), "ID" );
			local nIndex = DataPool:GetSearchResultByGUID(id)
			Friend_Update_SearchResult(nIndex)

		end
	elseif (event == "UPDATE_GROUPLIST") then
		if this:IsVisible() and g_CurPage == 3 then
				g_Current_Clicked = Friend_List : GetCurrentFirstItem();
				Friend_Group_List()
		elseif this:IsVisible() and g_CurPage == 4 then
				g_Current_Clicked = Friend_List : GetCurrentFirstItem();
				Friend_Recent_List()
		end
	elseif (event == "RESET_ALLUI") then
		Friend_SelfState:SetCurrentSelect(0)
	elseif (event == "IMONLINETIME_CHANGE") then
		local strTime = Player:GetData("IM_ONLINE_TIME")
		if this:IsVisible() then
			Friend_ShowStar();
		end
	elseif (event == "UPDATE_GROUPINGNAME") then
		if this:IsVisible() then
			Friend_SetGroupingName();
			if g_CurPage == 1 then
				g_Current_Clicked = Friend_List:GetCurrentFirstItem()
				Friend_Update();
			else

			end
		end
	elseif( event == "ADJEST_UI_POS" ) then
		-- 更新好友界面位置
		Friend_ResetPos()
	-- 游戏分辨率发生了变化
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 更新好友界面位置
		Friend_ResetPos()
	elseif( event == "CHAT_SIGN_RED_POINT" ) then
		Friend_ChatSign_Tips:Show()
	elseif( event == "FRIENDSEARCH_RESULT" ) then
		--好友搜索结果
		if g_CurPage == 5 then
			g_Current_Clicked = -1;
			Friend_List_SearchResult()
		else
			Friend_SwitchPage(5)
		end
	elseif( event == "GS_FRIENDREFRESH_NEW" and g_CurPage==6) then
			Friend_List:ClearListBoxEx();
			local mGSState = Talk:GetNewGSState()
			local mGSName = Talk:GetNewGSName()
			local col = "#G"
			local statename = ""
			if mGSState ==0 then  --在线
				 col = "#G"
				 statename = " [在线]"
			elseif mGSState ==1 then
			   col = "#cff0000"
			   statename = " [忙碌]"
			elseif mGSState ==2 then
				 col = "#Y"
				 statename = " [离开]"
			elseif mGSState ==3 then
				 col = "#c787777"
				 statename = " [离线]"
			end
				local temp =" "
				local listName = temp..col.."#-38"..mGSName..statename
				Friend_List:AddItemExWithoutLayout( listName, 10001 ,0, "FFFFFFFF", 4 );	 
	end
end
--===============================================
-- UpdateFrame()
--===============================================
function UpdateFriendInfo( nChannel, nIndex )
	if( this:IsVisible() ) then

		local name = DataPool:GetFriend( nChannel, nIndex, "NAME" );
		local remark = Friend_GetSpecialRemark( nChannel, nIndex )
		local emotion = DataPool:GetFriend( nChannel, nIndex, "MOOD" );
		local friendship = DataPool:GetFriend( nChannel, nIndex, "FRIENDSHIP" );
		local relationtype = DataPool:GetFriend( nChannel, nIndex, "RELATION_TYPE" );
		local imOnlineTime = DataPool:GetFriend( nChannel, nIndex, "IM_ONLINE_TIME" );
		local IMst = DataPool:GetFriend( nChannel, nIndex, "IM_STATUS" );
		local Sex = DataPool:GetFriend( nChannel, nIndex, "SEX" );
		local haveMsg = DataPool:GetFriend( nChannel, nIndex, "MSG" );
		local guid = DataPool:GetFriend( nChannel, nIndex, "ID" );
		local namecolor = "#cC4B299";
		if SystemSetup:IsClassic() == 0 then
				namecolor = "#c9e9e9d"
		end
		local bShine = ""
		if haveMsg == 1 then
			bShine = "#b";
		end
		local moodColor = "#cFFCC7A";
		local playerIcon = g_IconSpin

		if( DataPool:GetFriend( nChannel, nIndex, "ONLINE" ) ) then
			if( nChannel == 6 or nChannel == 11) then
				namecolor="#cFF0000";					--[2007/11/26 liboyu] #c800000----->#cFF0000
			else
				if( relationtype == 7 or relationtype == 8) then
					namecolor = "#cFF6600";
				elseif( relationtype == 3 ) then
					namecolor = "#cF246F0";
				elseif( relationtype == 2 ) then
					namecolor = "#c007EFF";
					local isSpouse = DataPool:GetFriend( nChannel, nIndex, "IS_SPOUSE" )
					if isSpouse == 1 then
						namecolor = "#cF246F0"					--结拜 并且在配偶列
					end
				elseif( friendship >= 10 ) then  --[2007/08/28 YangJun]
						namecolor = "#c00FF00";
				elseif( friendship >= 1 ) then	--[2007/08/28 YangJun]
					if SystemSetup:IsClassic() == 1 then
						namecolor = "#c00C800";
					else
						namecolor = "#c00cd00";
					end
				elseif( friendship == 0 ) then	--[2007/08/28 YangJun]
						namecolor = "#cFFFFFF";
				end
			end
			if IMst >= 0 and IMst <=2 and Sex >=0 and Sex <= 1 then
				playerIcon = g_imgStatus[Sex][IMst]
			end
			local idx = Friend_List:GetItemNumByItemId(nChannel*10000 + nIndex + 1)
			if idx ~= -1 then
				local zoneWorldID = DataPool:GetFriend(nChannel, nIndex, "ZONEWORLDID" )
				local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
				if zoneWorldID ~= nil and zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
					name = name.."@"..DataPool:GetServerName(zoneWorldID)
				end
				local listName = ""
				if( remark ~=nil and remark ~= "" ) then
					listName = g_FriendSpin..playerIcon..bShine..namecolor..name.."#r"..g_FriendSpin..g_IconSpin..namecolor.."("..remark..")"
				else
					listName = g_FriendSpin..playerIcon..bShine..namecolor..name
				end
				local listmood = g_FriendSpin..g_IconSpin..moodColor..emotion
				if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
					--大世界好友不加tips
					if( remark ~=nil and remark ~= "" ) then
						listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
					else
						listName = playerIcon..bShine..namecolor..name
					end
					listmood = g_IconSpin..moodColor..emotion
				end
				Friend_List:SetListItemText( idx,g_FriendBorderColor..listName.."#r"..listmood);
				if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
					--大世界好友不加tips
				else
					local iconStr = Friend_GetOnlineTimeIconStr(imOnlineTime)
					if imOnlineTime ~= "" then
						Friend_List:SetItemTooltip(idx , tostring(iconStr))
					end
				end
			end
		else
			if( nChannel == 6 or nChannel == 11) then
				namecolor="#cc7b299";
			end
			local zoneWorldID = DataPool:GetFriend(nChannel, nIndex, "ZONEWORLDID" )
			local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
			if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
				name = name.."@"..DataPool:GetServerName(zoneWorldID)
			end
			local idx = Friend_List:GetItemNumByItemId(nChannel*10000 + nIndex + 1)
			if idx ~= -1 then
				local listName = ""
				if( remark ~=nil and remark ~= "" ) then
					listName = g_FriendSpin..playerIcon..bShine..namecolor..name.."#r"..g_FriendSpin..g_IconSpin..namecolor.."("..remark..")"
				else
					listName = g_FriendSpin..playerIcon..bShine..namecolor..name
				end
				if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
					if( remark ~=nil and remark ~= "" ) then
						listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
					else
						listName = playerIcon..bShine..namecolor..name
					end
				end

				Friend_List:SetListItemText( idx,g_FriendBorderColor..listName);
			end
		end
	end
end

function Friend_AddFriendItem( nChannel, nIndex )
	local name = DataPool:GetFriend( nChannel, nIndex, "NAME" );
	local remark =  Friend_GetSpecialRemark( nChannel, nIndex )
	local emotion = DataPool:GetFriend( nChannel, nIndex, "MOOD" );
	local friendship = DataPool:GetFriend( nChannel, nIndex, "FRIENDSHIP" );
	local relationtype = DataPool:GetFriend( nChannel, nIndex, "RELATION_TYPE" );
	local imOnlineTime = DataPool:GetFriend( nChannel, nIndex, "IM_ONLINE_TIME" );
	local IMst = DataPool:GetFriend( nChannel, nIndex, "IM_STATUS" );
	local Sex = DataPool:GetFriend( nChannel, nIndex, "SEX" );
	local haveMsg = DataPool:GetFriend( nChannel, nIndex, "MSG" );
	local guid =  DataPool:GetFriend( nChannel, nIndex, "ID" );
	local havePresent = DataPool:GetFriend(nChannel, nIndex, "FRIEND_PRESENT" );

	local nLevel = DataPool:GetFriend(nChannel, nIndex, "LEVEL");	

	
	local namecolor = "#cC4B299";
	if SystemSetup:IsClassic() == 0 then
			namecolor = "#c9e9e9d"
	end
	local bShine = ""
	if haveMsg == 1 then
		bShine = "#b";
	end
	local playerIcon = g_IconSpin
	local moodColor = "#cFFCC7A";
	local zoneWorldID = DataPool:GetFriend(nChannel, nIndex, "ZONEWORLDID" )
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
		name = name .. "@" .. DataPool:GetServerName(zoneWorldID)
	end
	
	local isbindapp = DataPool:GetFriend( nChannel, nIndex, "FRIEND_ISAPPBIND"); --0未绑定，1绑定
	
	if Friend_ShowInCommonFriendGroup( nChannel, nIndex ) == 0 then			--  7:师傅 8：徒弟 3：结婚 2：结拜
		return
	end
	
	if( DataPool:GetFriend( nChannel, nIndex, "ONLINE" ) ) then
		if( nChannel == 6 or nChannel == 7 or nChannel == 11) then
			namecolor="#cFF0000";					--[2007/11/26 liboyu] #c800000----->#cFF0000
		else
			if( relationtype == 7 or relationtype == 8) then			--  7:师傅 8：徒弟
				namecolor = "#cFF6600"
			elseif( relationtype == 3 ) then					-- 3：结婚
				namecolor = "#cF246F0"
			elseif( relationtype == 2 ) then					-- 2：结拜
				namecolor = "#c007EFF"
				local isSpouse = DataPool:GetFriend( nChannel, nIndex, "IS_SPOUSE" )
				if isSpouse == 1 then
					namecolor = "#cF246F0"					--结拜 并且在配偶列
				end
			elseif( friendship >= 10 ) then
					namecolor = "#c00FF00"
			elseif( friendship >= 1 ) then
				if SystemSetup:IsClassic() == 1 then
					namecolor = "#c00C800"
				else
					namecolor = "#c00cd00";
				end
			elseif( friendship == 0 ) then	--[2007/08/28 YangJun]
					namecolor = "#cFFFFFF";
			end
		end
		if IMst >= 0 and IMst <=2  and Sex >=0 and Sex <= 1 then
			playerIcon = g_imgStatus[Sex][IMst]
		end
		local listName = ""
		if( remark ~=nil and remark ~= "" ) then
			listName = g_FriendSpin..playerIcon..bShine..namecolor..name.."#r"..g_FriendSpin..g_IconSpin..namecolor.."("..remark..")"
		else
			listName = g_FriendSpin..playerIcon..bShine..namecolor..name
		end
		local listmood = g_FriendSpin..g_IconSpin..moodColor..emotion
		if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
			if( remark ~=nil and remark ~= "" ) then
				listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
			else
				listName = playerIcon..bShine..namecolor..name
			end
			listmood = g_IconSpin..moodColor..emotion
		end
		
		if nChannel > 0 and nChannel < 5 and nIndex >= 0 then
			
			Friend_List:AddItemExWithoutLayout(g_FriendBorderColor..listName.."#r"..listmood , nChannel*10000 + nIndex + 1 ,4, "FFFFFFFF", 4, havePresent,isbindapp,0);
			
		else
			Friend_List:AddItem( g_FriendBorderColor..listName.."#r"..listmood , nChannel*10000 + nIndex + 1 , "FFFFFFFF", 4 );
		end
		if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
		--大世界好友不加tips
		else
			local idx = Friend_List:GetItemNumByItemId(nChannel*10000 + nIndex + 1)
			if idx >= 0 then
				local iconStr = Friend_GetOnlineTimeIconStr(imOnlineTime)
				if imOnlineTime ~= "" then
					Friend_List:SetItemTooltip(idx , tostring(iconStr))
				end
			end
		end
	else
		if( nChannel == 6 or nChannel == 11) then
			namecolor="#cc7b299";
		end
		local listName = ""
		if( remark ~=nil and remark ~= "" ) then
			listName = g_FriendSpin..playerIcon..bShine..namecolor..name.."#r"..g_FriendSpin..g_IconSpin..namecolor.."("..remark..")"
		else
			listName = g_FriendSpin..playerIcon..bShine..namecolor..name
		end
		if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
			if( remark ~=nil and remark ~= "" ) then
				listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
			else
				listName = playerIcon..bShine..namecolor..name
			end
		end

		if( nChannel == 1 or nChannel == 2 or nChannel == 3 or nChannel == 4 ) then
			Friend_List:AddItemExWithoutLayout( g_FriendBorderColor..listName, nChannel*10000 + nIndex + 1 ,8, "FFFFFFFF", 4, 0,isbindapp,0,0,0,0 );
		else
			Friend_List:AddItemExWithoutLayout( g_FriendBorderColor..listName, nChannel*10000 + nIndex + 1 ,8, "FFFFFFFF", 4, 0,0,0,0,3,0 );
		end
	end

end

function Friend_Update()
	Friend_List:ClearListBoxEx()
	
	Friend_SpecialFriendUpdate()
	
	--一共7组 ，临时好友单独处理
	--添加仇敌后变为8；添加KVK后，大世界中的关系组需要改变这个值，功能制作的时候没有注意到这里，大世界的临时好友，需要再考虑修改内部代码了。
	--暂时改为12，后续会通知相关人员修改by	lx
	for i = 1 , 8 do
		local j = i
		--delete	by	lx	暂时只能屏蔽掉这里，防止KVK相关大世界关系捣乱
		if i == 8 then
			j = 13
		end
		--if i <= 8 then	--	这个if是为了屏蔽KVK相关大世界关系添加的，后续功能开放的时候需要去掉	by	lx
		-- by cys 统计好友在线人数
		--===================================================================================
			local FriendCount = 0 --好友总数
			local FriendInfo = {} --分组好友人数和在线好友人数
			FriendInfo[j] = ""
			for iTmp = 1, 4 do
				FriendCount = FriendCount + DataPool:GetFriendNumber( tonumber( iTmp ) );
				local groupCount = DataPool:GetFriendNumberCommon( tonumber( iTmp ) );--每组人数
				local onlienCount= DataPool:GetFriendOnlineNumberCommon( tonumber( iTmp ) );--每组在线人数
				FriendInfo[iTmp] = "(" .. onlienCount .."/" ..groupCount ..")"
			end
			g_Pages[1]:SetText("#{LTQH_XML_11}".."（"..FriendCount.."/" .."80" .."）" )
		--===================================================================================


			local strOutlineName = ""
			if g_IsTeamOutLine[j] == 1 then
				if SystemSetup:IsClassic() == 1 then
					strOutlineName = g_GroupTitleColor.."- " .. g_TeamOutLineStr[j] .. FriendInfo[j]
				else
					strOutlineName = g_GroupTitleColor_WM.."- " .. g_TeamOutLineStr[j] .. FriendInfo[j]
				end
			else
				if SystemSetup:IsClassic() == 1 then
					strOutlineName = g_GroupTitleColor.."+ " .. g_TeamOutLineStr[j] .. FriendInfo[j]
				else
					strOutlineName = g_GroupTitleColor_WM.."+ " .. g_TeamOutLineStr[j] .. FriendInfo[j]
				end
			end

			if( strOutlineName ~= "" or strOutlineName ~= 0 ) then
				local iStart = j*10000;
				local friendnumber = DataPool:GetFriendNumberCommon( tonumber( j ) )
				local relealFriendNumber = DataPool:GetFriendNumber( tonumber( j ) )
				if friendnumber < 1 then
					if SystemSetup:IsClassic() == 1 then
						strOutlineName = g_GroupTitleColor.."- " .. g_TeamOutLineStr[j] .. FriendInfo[j]
					else
						strOutlineName = g_GroupTitleColor_WM.."- " .. g_TeamOutLineStr[j] .. FriendInfo[j]
					end
				end
				

				Friend_List:AddItem( strOutlineName, iStart )
				if( 1 == g_IsTeamOutLine[ j ] ) then
					local index=0;
					while index < relealFriendNumber  do
						Friend_AddFriendItem(j , index)
						index = index + 1;
					end
				end
			end
		--end
	end

	--畅游精灵
	Friend_Spirit()

	if g_Current_Clicked ~= -1 then
		Friend_List:SetCurrentFirstItem(g_Current_Clicked);
		g_Current_Clicked = -1
	end

	local isConnectGS = Talk:IsInGSService()
	if isConnectGS > 0 then
		 Friend_List_Page6:SetProperty("Visible","True")
	else
		 Friend_List_Page6:SetProperty("Visible","False")
	end
end

--单独畅游精灵，不和原有的好友关系发生混乱
--由于不走网络消息包，所幸就在此添加
--不要模仿
--By cys
function Friend_Spirit()
	local SpiritIndex = 9
	local strOutlineName = ""
	if g_IsTeamOutLine[SpiritIndex] == 1 then
		if SystemSetup:IsClassic() == 1 then
			strOutlineName = g_GroupTitleColor.."- " .. g_TeamOutLineStr[SpiritIndex]
		else
			strOutlineName = g_GroupTitleColor_WM.."- " .. g_TeamOutLineStr[SpiritIndex]
		end
	else
		if SystemSetup:IsClassic() == 1 then
			strOutlineName = g_GroupTitleColor.."+ " .."#G".. g_TeamOutLineStr[SpiritIndex]
		else
			strOutlineName = g_GroupTitleColor_WM.."+ " .."#G".. g_TeamOutLineStr[SpiritIndex]
		end
	end
	local iStart = SpiritIndex*10000
	Friend_List:AddItem( strOutlineName, iStart )

	if (1 == g_IsTeamOutLine[SpiritIndex])then
		local temp =" "
		local listName = temp.."#G".."#-38"..g_TeamOutLineStr[SpiritIndex]
		local listmood = g_IconSpin..temp..g_GroupTitleColor.."畅游精灵为您服务"
		if SystemSetup:IsClassic() == 0 then
			listmood = g_IconSpin..temp..g_GroupTitleColor_WM.."畅游精灵为您服务"
		end
		Friend_List:AddItemExWithoutLayout( g_FriendBorderColor..listName .."#r"..listmood, SpiritIndex*10000 + 1 ,0, "FFFFFFFF", 4 );
	end
end

function Friend_Show()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	if g_CurPage == 2 and Lua_GetAnonymousBySceneType(6071) == 1 then
		Friend_SwitchPage(1)
		g_CurPage = 1
	end
	
	this:Show();

	local isShowChatSignRedPoint = DataPool:GetIsShowChatSignRedPoint() 
	if isShowChatSignRedPoint == 1 then
		Friend_ChatSign_Tips:Show()
	else
		Friend_ChatSign_Tips:Hide()
	end

	local strHead = Player:GetData("PORTRAIT")
	local strName = Player:GetName()
	Friend_SelfHead:SetProperty("Image" , strHead) ;
	Friend_SelfName:SetText(strName) ;
	Friend_ShowStar()
	Friend_SetGroupingName()

	-- 边框
	local MyHeadFrameType = Player:GetData("HEADFRAMETYPE")
	if MyHeadFrameType == 1 then
		Friend_SelfHeadFrame:SetProperty("Image", "")
		Friend_SelfHeadFrame:Hide()

		Friend_SelfHeadFrame_Animate:Show()
		local MyHeadFrameAnimate = Player:GetData("HEADFRAMEANIMATE")
		Friend_SelfHeadFrame_Animate:SetProperty("Animate", tostring(MyHeadFrameAnimate))
	else
		Friend_SelfHeadFrame_Animate:SetProperty("Animate", "")
		Friend_SelfHeadFrame_Animate:Hide()

		Friend_SelfHeadFrame:Show()
		local MyHeadFrameImage = Player:GetData("HEADFRAMEIMAGE")
		local IconFile = GetIconFullName(MyHeadFrameImage)
		Friend_SelfHeadFrame:SetProperty("Image", IconFile)
	end
		
	local vipLevel = DataPool:GetAccVipLevel()
	if vipLevel ~= nil and g_VIP_Image[vipLevel] ~= nil then
		local UnifiedXPos = string.format("{0,%f}", 65+tonumber(string.len(strName))*(215-139)/12)	--65是名字的UnifiedXPosition，(215-139)/6是每个汉字的宽度
		Friend_VIP:SetProperty("UnifiedXPosition", UnifiedXPos)
		Friend_VIP:SetProperty("Image" , g_VIP_Image[vipLevel])
		Friend_VIP:SetToolTip(ScriptGlobal_Format("#{VIPTQ_110908_16}", tostring(vipLevel)))
		Friend_VIP:Show()
	else
		Friend_VIP:Hide()
	end

	--记录原来的位置
	g_Current_Clicked = Friend_List : GetCurrentFirstItem();
	if g_CurPage ~= 2 then
		Friend_List_BigWorld()
	end

	if g_CurPage == 1 then
		Friend_Update()
	elseif g_CurPage == 3 then
		Friend_Group_List()
	elseif g_CurPage == 4 then
		Friend_Recent_List()
	elseif g_CurPage == 5 then
		Friend_List_SearchResult()
	elseif g_CurPage == 2 then
		Friend_List_BigWorld()
	else
		Friend_SwitchPage(1)
	end
	
	local isConnectGS = Talk:IsInGSService()
	if isConnectGS > 0 then
		 Friend_List_Page6:SetProperty("Visible","True")
	else
		 Friend_List_Page6:SetProperty("Visible","False")
	end
	
	--local isbindapp = IsAppWareProtectSetup()
	local isappattention = DataPool:GetCharIsAppAttention()
	if isappattention > 0 then 
		Friend_ChangYou:Show();
	else
		Friend_ChangYou:Hide();
	end
	
	--结拜引导任务显示 有任务未完成的时候 显示旋转按钮
	if DataPool:Lua_IsHaveMission(1361) > 0 and DataPool:Lua_IsMissionHaveDone(1361) <= 0 then
		local fX, fY = this:GetChildOffset("Friend_SearchBtn01")
    OpenFreshManGuide(1, 75, fX, fY, "Friend", "northeast")
		SetTimer("Friend", "CloseFreshManGuide()", 10000)
		Friend_SearchBtn01_Animate:Play(true)
		Friend_SearchBtn01:SetText("#{JBZY_150629_125}") ;
	else
		CloseFreshManGuide()
		Friend_SearchBtn01_Animate:Play(false)
		Friend_SearchBtn01:SetText("#{XST_110831_20}")
	end
	local isSocialServer = DataPool:LuaFnOpenSocialServerFlag()
	if isSocialServer == 1 then
		Friend_veriface:Show()
	else
		Friend_veriface:Hide()
	end
end

function Friend_SetGroupingName()
	local strGroupName = ""
	for i = 0 , 3 do
		strGroupName = DataPool:GetGroupingName(i)
		if strGroupName ~= "" then
			g_TeamOutLineStr[i+1] = strGroupName
		end
	end
	
	CloseFreshManGuide()
	Friend_SearchBtn01_Animate:Play(false)
	Friend_SearchBtn01:SetText("#{XST_110831_20}")

end


function Friend_Hide()
	this:Hide();
end

function Friend_ShowStar()
	local strTime = Player:GetData("IM_ONLINE_TIME")

	local level , sunNum ,moonNum , starNum = DataPool:GetIMIconNum(tonumber(strTime))

	local strTips = ""
	Friend_LevelIcons:SetToolTip("#{LTQH_XML_98}"..tostring(level).."#r#{LTQH_XML_99}")
	if sunNum + moonNum + starNum <= 7 then
		for i = 1 , 7 do
			if i <= sunNum then
				g_imgStar[i]:SetProperty("Image" , "set:Button8 image:IM_Sun")
				g_imgStar[i]:Show()
			elseif i <= sunNum + moonNum then
				g_imgStar[i]:SetProperty("Image" , "set:Button8 image:IM_Moon")
				g_imgStar[i]:Show()
			elseif i <= sunNum + moonNum + starNum then
				g_imgStar[i]:SetProperty("Image" , "set:Button8 image:IM_Star")
				g_imgStar[i]:Show()
			else
				g_imgStar[i]:Hide()
			end
			strTips = DataPool:GetIMOnlinetimeTips(tonumber(strTime))
			--g_imgStar[i]:SetToolTip("#{LTQH_XML_98}"..tostring(level).."#r#{LTQH_XML_99}")
			g_imgStar[i]:SetToolTip(tostring(strTips))
		end
	end
	Friend_LevelIcons:SetToolTip(tostring(strTips))
end

--双击
function Friend_FriendSelect()
	if g_CurPage == 1 then
		local index = Friend_List:GetFirstSelectItem();
		if index == -1 then
			return
		end
		local iMod = math.mod( index, 10000 )
		local iFloor = math.floor( index / 10000 );
		if( iFloor == 5 ) then
			return;
		end
		
		if( iFloor == 6 ) then
			PushDebugMessage("与对方为仇人关系，仅可以使用右键菜单。")
			return;
		end

		if(iFloor == 7) then
			return;
		end

		if(iFloor == 9 )then --畅游精灵
			local enable = Player:GetData("OPEN_CYJL")  --此处是GM的开关
			if enable == 0 then
				PushDebugMessage("#{CYJL_101102_01}")
				return;
			else
				OpenCustomerService( 1 )
				return;
			end 
		end
		
		Friend:SetCurrentSelect( iMod - 1);
		Friend:SetCurrentTeam( iFloor );
		DataPool:Open1On1Chat(iFloor , iMod - 1)
	elseif g_CurPage == 2 then
		local index = Friend_List:GetFirstSelectItem();
		if index == -1 then
			return
		end
		local iMod = math.mod( index, 10000 )
		local iFloor = math.floor( index / 10000 );
		if( iFloor < 8 ) or ( iFloor > 14 )then
			return;
		end
		if( iFloor == 11 ) then
			PushDebugMessage("与对方为仇人关系，仅可以使用右键菜单。")
			return;
		end

		if(iFloor == 10) then
			return;
		end
		if(iFloor == 12) then
			return;
		end

		Friend:SetCurrentSelect( iMod - 1);
		Friend:SetCurrentTeam( iFloor );
		DataPool:Open1On1Chat(iFloor , iMod - 1)
	elseif g_CurPage == 3 then
		local nIndex = Friend_List:GetFirstSelectItem();
		DataPool:OpenGroupChat(nIndex)
	elseif g_CurPage == 4 then
		local nIndex = Friend_List:GetFirstSelectItem();
		local isGroup , sID , sName = DataPool:GetIMRecentByIndex(nIndex)
		if isGroup == 1 then
			DataPool:OpenGroupChat(sID)
		elseif isGroup == 0 then
			local nChannel , nIndex = DataPool:GetFriendByName(sName)

			if (nChannel > 0 and nChannel < 5 and nIndex >= 0) or (nChannel > 7 and nChannel < 10 and nIndex >= 0) then
				DataPool:Open1On1Chat(nChannel , nIndex)
			end
		end
	elseif g_CurPage == 5 then
		local index = Friend_List:GetFirstSelectItem();
		if( index == -1 ) then
			return;
		end
		local sGuid , sName = DataPool:GetSearchResultByIndex(index)
		if sGuid ~= "" and sName ~= "" then
			local nChannel , nIndex = DataPool:GetFriendByName(sName)
			if (nChannel > 0 and nChannel < 5 and nIndex >= 0) or (nChannel > 7 and nChannel < 10 and nIndex >= 0) then
				DataPool:Open1On1Chat(nChannel , nIndex)
			end
		end
	elseif g_CurPage == 6 then
		local isConnectGS = Talk:IsInGSService()
		if isConnectGS == 1 then
			PushEvent("OPEN_GSIM",1)
		elseif isConnectGS == 2 then
			local isRet = Talk:GetGSInfoIsRetNew()
			if isRet == 0 then
				Talk:AskGSInfoNew()
			else
				PushEvent("OPEN_GSIM_NEW",1)
			end
		end
	end
end

--打开菜单
function Friend_OpenMenu()
	if g_CurPage == 1 then
		local index = Friend_List:GetFirstSelectItem()
		if( index == -1 ) then
			return;
		end
		local iMod = math.mod( index, 10000 )
		local iFloor = math.floor( index / 10000 );

		Friend:SetCurrentSelect( iMod - 1);
		Friend:SetCurrentTeam( iFloor );
		if( index > -1 and iFloor ~= 9 ) then
			Friend:OpenMenu( tostring( iFloor), tostring( iMod - 1 ) );
		end
	elseif g_CurPage == 2 then
		local index = Friend_List:GetFirstSelectItem();
		if( index == -1 ) then
			return;
		end
		local iMod = math.mod( index, 10000 )
		local iFloor = math.floor( index / 10000 );

		Friend:SetCurrentSelect( iMod - 1);
		Friend:SetCurrentTeam( iFloor );
		if( index > -1 and iFloor > 7 ) then
			Friend:OpenMenu( tostring( iFloor), tostring( iMod - 1 ) );
		end
	elseif g_CurPage == 3 then
		local index = Friend_List:GetFirstSelectItem();
		if( index > -1 ) then
			Friend:OpenGroupListMenu( tostring( index) );
		end
	elseif g_CurPage == 4 then
		local nIndex = Friend_List:GetFirstSelectItem();
		local isGroup , sID , sName = DataPool:GetIMRecentByIndex(nIndex)
		if isGroup == 1 then
			Friend:OpenGroupListMenu( tostring( sID) )
		elseif isGroup == 0 then
			local nChannel , nIndex = DataPool:GetFriendByName(sName)

			if nChannel > 0 and nIndex >= 0 then
				Friend:SetCurrentSelect( nIndex);
				Friend:SetCurrentTeam( nChannel );
				Friend:OpenMenu( tostring(nChannel), tostring(nIndex) );
			end
		end
	elseif g_CurPage == 5 then
		local index = Friend_List:GetFirstSelectItem();
		if( index == -1 ) then
			return;
		end
		local sGuid , sName = DataPool:GetSearchResultByIndex(index)
		if sGuid ~= "" and sName ~= "" then
			local nChannel , nIndex = DataPool:GetFriendByName(sName)
			if nChannel > 0 and nIndex >= 0 then
				Friend:SetCurrentSelect( nIndex);
				Friend:SetCurrentTeam( nChannel );
				Friend:OpenMenu( tostring(nChannel), tostring(nIndex) );
			end
		end
	end
end



--============================
--编辑心情
function Friend_EditMood()
	DataPool:EditMood();
end

--显示自己的心情
function Friend_ViewMood_Clicked()
	Friend:ViewFeel();
end

--鼠标进入按钮
function Friend_ViewMood_MouseEnter()
		--显示tooltips
		if( Friend:IsMoodInHead() == 1)   then
			Friend_ViewMood:SetToolTip("点击后将隐藏您在头顶显示的心情。");
		else
			Friend_ViewMood:SetToolTip("点击后将在您的头顶显示心情的内容。");
		end
end
--搜索
function Friend_Search()
	local nNumber = Player:GetData( "LEVEL" );
	if(nNumber~=nil and nNumber>=10) then
		FriendSearcher:OpenFriendSearch();
	else
		PushDebugMessage("您的等级不够，到了10级您就能使用好友搜索功能了。");
	end;

end
--邮件消息
function Friend_SystemInfo()
	DataPool:OpenSystemHistroy();
end
--帮助
function Friend_OnHelp()
	Helper:GotoHelper("*Friend" );
end
--消息球历史
function Friend_NewMsgBallHistory_Clicked()
	ToggleMsgHistory();
end
--信任伙伴
function Friend_TrustFriendBtn_OnClicked()
	DataPool:ToggleTrustFriendWindow();
end
--================================================
-- 恢复好友界面的默认相对位置
--================================================
function Friend_ResetPos()
	Friend_Frame:SetProperty("UnifiedXPosition", g_Friend_Frame_UnifiedXPosition);
	Friend_Frame:SetProperty("UnifiedYPosition", g_Friend_Frame_UnifiedYPosition);
	Helper:SendMessage(95788)
end

function Friend_SwitchPage(page)

	if page < 1 or page > 6 then
		return
	end
	
	if page == 2 and Lua_GetAnonymousBySceneType(6071) == 1 then
		PushDebugMessage("#{YCXX_20220712_09}")
		return
	end
	
	-- TT96544 好友列表界面缩、放制作
	-- 点击【联系人 XX/80】的时候每列好友列表能全部展开，再次点击能全部收起。
	if g_CurPage == page then
		if page ~= 1 then
			return
		end
		local nTeamOutLineValue = 0
		for i = 1 , 9 do
			local j = i
			if j == 8 then
				j = 13
			end
			if g_IsTeamOutLine[j] == 0 then
				nTeamOutLineValue = 1
				break
			end
		end
		
		for i = 1 , 4 do
			if g_SpecialFriendOutLine[i] == 0 then
				nTeamOutLineValue = 1
				break
			end
		end
		
		for i = 1 , 9 do
			local j = i
			if j == 8 then
				j = 13
			end
			g_IsTeamOutLine[j] = nTeamOutLineValue
		end
		
		for i = 1 , 4 do
			g_SpecialFriendOutLine[i] = nTeamOutLineValue
		end
		
		Friend_Update()
		return
	end

	g_CurPage = page


	local pos = 0
	for i = 1, 6 do
		pos = tonumber(g_PagePosTop) + tonumber(g_StepSize) * (i - 1)
		if i > page then
			pos = pos + (tonumber(g_ListHeight))
		end
		g_Pages[i]:SetProperty("AbsoluteYPosition"  , tostring(pos))
		if i == page then
			Friend_List:SetProperty("AbsoluteYPosition"  , tostring(pos + g_StepSize) )
		end
	end
	--页面切换归位
	g_Current_Clicked = -1;

	if page == 1 then
		Friend_Update()
	elseif page == 3 then
		Friend_Group_List()
	elseif page == 4 then
		Friend_Recent_List()
	elseif page == 5 then
		Friend_List_SearchResult()
	elseif page == 2 then
		Friend_List_BigWorld()
	elseif page == 6 then
		Friend_GS()
	end
end

--搜索结果页面
function Friend_List_SearchResult()
	Friend_List:ClearListBoxEx()
	local rtNum = DataPool:GetSearchResultNum() ;
	local nChannel , nIndex ;
	local sGuid , sName ;
	for i = 0 , rtNum do
		sGuid , sName = DataPool:GetSearchResultByIndex(i)
		if sGuid ~= "" and sName ~= "" then
			nChannel , nIndex = DataPool:GetFriendByGUID(sGuid)
			if (nChannel > 0 and nChannel < 5 and nIndex >= 0) or (nChannel > 7 and nChannel < 10 and nIndex >= 0) then
				local name = DataPool:GetFriend( nChannel, nIndex, "NAME" );
				local remark =  Friend_GetSpecialRemark( nChannel, nIndex )
				local emotion = DataPool:GetFriend( nChannel, nIndex, "MOOD" );
				local friendship = DataPool:GetFriend( nChannel, nIndex, "FRIENDSHIP" );
				local relationtype = DataPool:GetFriend( nChannel, nIndex, "RELATION_TYPE" );
				local haveMsg = DataPool:GetFriend( nChannel, nIndex, "MSG" );
				local imOnlineTime = DataPool:GetFriend( nChannel, nIndex, "IM_ONLINE_TIME" );
				local namecolor = "#cC4B299";
				if SystemSetup:IsClassic() == 0 then
						namecolor = "#c9e9e9d"
				end
				local bShine = ""
				if haveMsg == 1 then
					bShine = "#b";
				end
				local moodColor = "#cFFCC7A";
				if nChannel > 7 and nChannel < 10 then
					local idZoneWorld = DataPool:GetFriend( nChannel, nIndex, "ZONEWORLDID" );
					local selfZoneWorld = DataPool:GetSelfZoneWorldID()
					if idZoneWorld ~= -1 and idZoneWorld ~= selfZoneWorld then
						name = name .. "@" ..DataPool:GetServerName(idZoneWorld)
					end
				end

				local IMst = DataPool:GetFriend( nChannel, nIndex, "IM_STATUS" );
				local Sex = DataPool:GetFriend( nChannel, nIndex, "SEX" );
				local playerIcon = g_IconSpin

				if( DataPool:GetFriend( nChannel, nIndex, "ONLINE" ) ) then
					if( nChannel == 6 or nChannel == 11) then
						namecolor="#cFF0000";
					else
						if( relationtype == 7 or relationtype == 8) then
							namecolor = "#cFF6600";
						elseif( relationtype == 3 ) then
							namecolor = "#cF246F0";
						elseif( relationtype == 2 ) then
							namecolor = "#c007EFF";
							local isSpouse = DataPool:GetFriend( nChannel, nIndex, "IS_SPOUSE" )
							if isSpouse == 1 then
								namecolor = "#cF246F0"					--结拜 并且在配偶列
							end
						elseif( friendship >= 10 ) then
								namecolor = "#c00FF00";
						elseif( friendship >= 1 ) then
							if SystemSetup:IsClassic() == 1 then
								namecolor = "#c00C800";
							else
								namecolor = "#c00cd00";
							end
						elseif( friendship == 0 ) then
								namecolor = "#cFFFFFF";
						end
					end
					if IMst >= 0 and IMst <=2  and Sex >=0 and Sex <= 1 then
						playerIcon = g_imgStatus[Sex][IMst]
					end
					local listName = ""
					if( remark ~=nil and remark ~= "" ) then
						listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
					else
						listName = playerIcon..bShine..namecolor..name
					end
					local listmood = g_IconSpin..moodColor..emotion
					Friend_List:AddItem(g_FriendBorderColor..listName.."#r"..listmood ,i,"FFFFFFFF", 4);
					local zoneWorldID = DataPool:GetFriend(nChannel, nIndex, "ZONEWORLDID" )
					local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
					if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
						--大世界好友不加tips
					else
						local idx = Friend_List:GetItemNumByItemId( i )
						if idx >= 0 then
							local iconStr = Friend_GetOnlineTimeIconStr(imOnlineTime)
							if imOnlineTime ~= "" then
								Friend_List:SetItemTooltip(idx , tostring(iconStr))
							end
						end
					end
				else
					if( nChannel == 6 or nChannel == 11 ) then
						namecolor="#cc7b299";
					end
					local listName = ""
					if( remark ~=nil and remark ~= "" ) then
						listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
					else
						listName = playerIcon..bShine..namecolor..name
					end
					Friend_List:AddItem( g_FriendBorderColor..listName ,i ,"FFFFFFFF", 4);
				end
			end
		end
	end
	if g_Current_Clicked ~= -1 then
		Friend_List:SetCurrentFirstItem(g_Current_Clicked);
		g_Current_Clicked = -1
	end
end

--更新搜索结果页面某一个玩家
function Friend_Update_SearchResult(nIndex)
	local idx = Friend_List:GetItemNumByItemId(nIndex)
	if idx == -1 then
		return
	end
	local	sGuid , sName = DataPool:GetSearchResultByIndex(nIndex)
	if sGuid ~= "" and sName ~= "" then
		local nChannel , nIndex = DataPool:GetFriendByName(sName)
		if nChannel > 0 and nChannel < 5 and nIndex >= 0 then
			local name = DataPool:GetFriend( nChannel, nIndex, "NAME" );
			local remark =  Friend_GetSpecialRemark( nChannel, nIndex )
			local emotion = DataPool:GetFriend( nChannel, nIndex, "MOOD" );
			local friendship = DataPool:GetFriend( nChannel, nIndex, "FRIENDSHIP" );
			local relationtype = DataPool:GetFriend( nChannel, nIndex, "RELATION_TYPE" );
			local haveMsg = DataPool:GetFriend( nChannel, nIndex, "MSG" );
			local imOnlineTime = DataPool:GetFriend( nChannel, nIndex, "IM_ONLINE_TIME" );
			local namecolor = "#cC4B299";
			if SystemSetup:IsClassic() == 0 then
					namecolor = "#c9e9e9d"
			end
			local bShine = ""
			if haveMsg == 1 then
				bShine = "#b";
			end
			local moodColor = "#cFFCC7A";

			local IMst = DataPool:GetFriend( nChannel, nIndex, "IM_STATUS" );
			local Sex = DataPool:GetFriend( nChannel, nIndex, "SEX" );
			local playerIcon = g_IconSpin

			if( DataPool:GetFriend( nChannel, nIndex, "ONLINE" ) ) then
				if( nChannel == 6 or nChannel == 11 ) then
					namecolor="#cFF0000";
				else
					if( relationtype == 7 or relationtype == 8) then
						namecolor = "#cFF6600";
					elseif( relationtype == 3 ) then
						namecolor = "#cF246F0";
					elseif( relationtype == 2 ) then
						namecolor = "#c007EFF";
						local isSpouse = DataPool:GetFriend( nChannel, nIndex, "IS_SPOUSE" )
						if isSpouse == 1 then
							namecolor = "#cF246F0"					--结拜 并且在配偶列
						end
					elseif( friendship >= 10 ) then
							namecolor = "#c00FF00";
					elseif( friendship >= 1 ) then
						if SystemSetup:IsClassic() == 1 then
							namecolor = "#c00C800";
						else
							namecolor = "#c00cd00";
						end
					elseif( friendship == 0 ) then
							namecolor = "#cFFFFFF";
					end
				end
				if IMst >= 0 and IMst <=2  and Sex >=0 and Sex <= 1 then
					playerIcon = g_imgStatus[Sex][IMst]
				end
				local listName = ""
				if( remark ~=nil and remark ~= "" ) then
					listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
				else
					listName = playerIcon..bShine..namecolor..name
				end
				local listmood = g_IconSpin..moodColor..emotion
				Friend_List:SetListItemText(idx ,g_FriendBorderColor..listName.."#r"..listmood);
				local zoneWorldID = DataPool:GetFriend(nChannel, nIndex, "ZONEWORLDID" )
				local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
				if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
					--大世界好友不加tips
				else
					local iconStr = Friend_GetOnlineTimeIconStr(imOnlineTime)
					if imOnlineTime ~= "" then
						Friend_List:SetItemTooltip(idx , tostring(iconStr))
					end
				end
			else
				if( nChannel == 6 or nChannel == 11 ) then
					namecolor="#cc7b299";
				end
				local listName = ""
				if( remark ~=nil and remark ~= "" ) then
					listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
				else
					listName = playerIcon..bShine..namecolor..name
				end
				Friend_List:SetListItemText(idx, g_FriendBorderColor..listName );
			end
		end
	end
end

--群列表界面
function Friend_Group_List()
	Friend_List:ClearListBoxEx()
	for i = 0 ,19 do
		local id , name ,count ,ownerid = DataPool:GetChatGroupInfoByIndex(i)
		if id ~= -1 then
			local bShine = DataPool:IsChatGroupHaveMsg(id) ;
			if bShine == 1 then
				Friend_List:AddItem( g_FriendBorderColor.."#-31#b"..name ,id ,"FFFFFFFF", 4);
			else
				Friend_List:AddItem( g_FriendBorderColor.."#-31"..name ,id ,"FFFFFFFF", 4);
			end
		end
	end

	if g_Current_Clicked ~= -1 then
		Friend_List:SetCurrentFirstItem(g_Current_Clicked);
		g_Current_Clicked = -1
	end
end

--大世界好友
function Friend_List_BigWorld()
	Friend_List:ClearListBoxEx();
	for i = 8 , 12 do
		local j = i
		if i == 12 then
			j = 14
		end

		-- by cys 统计好友在线人数
		--===================================================================================
		local FriendCount = 0 --好友总数
		local FriendInfo = {} --分组好友人数和在线好友人数
		FriendInfo[j] = ""
		for iTmp = 8, 9 do
			FriendCount = FriendCount + DataPool:GetFriendNumber( tonumber( iTmp ) );
			local groupCount = DataPool:GetFriendNumber( tonumber( iTmp ) );--每组人数
			local onlienCount= DataPool:GetFriendOnlineNumber( tonumber( iTmp ) );--每组在线人数
			FriendInfo[iTmp] = "(" .. onlienCount .."/" ..groupCount ..")"
		end
		g_Pages[2]:SetText("天外联系人".."（"..FriendCount.."/" .."40" .."）" )
		--===================================================================================


		local strOutlineName = ""
		if g_IsTeamOutLine[j] == 1 then
			if SystemSetup:IsClassic() == 1 then
				strOutlineName = g_GroupTitleColor.."- " .. g_BigWorldLineStr[j] .. FriendInfo[j]
			else
				strOutlineName = g_GroupTitleColor_WM.."- " .. g_BigWorldLineStr[j] .. FriendInfo[j]
			end
		else
			if SystemSetup:IsClassic() == 1 then
				strOutlineName = g_GroupTitleColor.."+ " .. g_BigWorldLineStr[j] .. FriendInfo[j]
			else
				strOutlineName = g_GroupTitleColor_WM.."+ " .. g_BigWorldLineStr[j] .. FriendInfo[j]
			end
		end

		if( strOutlineName ~= "" or strOutlineName ~= 0 ) then
			local iStart = j*10000;
			local friendnumber = DataPool:GetFriendNumber( tonumber( j ) );
			if friendnumber < 1 then
				if SystemSetup:IsClassic() == 1 then
					strOutlineName = g_GroupTitleColor.."- " .. g_BigWorldLineStr[j] .. FriendInfo[j]
				else
					strOutlineName = g_GroupTitleColor_WM.."- " .. g_BigWorldLineStr[j] .. FriendInfo[j]
				end
			end
			Friend_List:AddItem( strOutlineName, iStart )
			if( 1 == g_IsTeamOutLine[ j ] ) then
				local index=0;
				while index < friendnumber  do
					Friend_AddFriendItem(j , index )
					index = index + 1;
				end
			end
		end
	end

	if g_Current_Clicked ~= -1 then
		Friend_List:SetCurrentFirstItem(g_Current_Clicked);
		g_Current_Clicked = -1
	end
end

--最近联系人界面
function Friend_Recent_List()
	Friend_List:ClearListBoxEx()
	for i = 0 ,19 do
		local isGroup , sID , sName, idZoneWorld = DataPool:GetIMRecentByIndex(i)
		if  isGroup ~= -1 and sID ~= -1 then
			if isGroup == 1 then
				local bShine = DataPool:IsChatGroupHaveMsg(sID) ;
				if bShine == 1 then
					Friend_List:AddItem( g_FriendBorderColor.."#-31#b"..sName ,i ,"FFFFFFFF", 4);
				else
					Friend_List:AddItem( g_FriendBorderColor.."#-31"..sName ,i ,"FFFFFFFF", 4);
				end
			elseif isGroup == 0 then
				local nChannel , nIndex = DataPool:GetFriendByName(sName)
				if nChannel ~= -1 and nIndex ~= -1 then
					local name = DataPool:GetFriend( nChannel, nIndex, "NAME" );
					local remark =  Friend_GetSpecialRemark( nChannel, nIndex )
					local emotion = DataPool:GetFriend( nChannel, nIndex, "MOOD" );
					local friendship = DataPool:GetFriend( nChannel, nIndex, "FRIENDSHIP" );
					local relationtype = DataPool:GetFriend( nChannel, nIndex, "RELATION_TYPE" );
					local haveMsg = DataPool:GetFriend( nChannel, nIndex, "MSG" );
					local imOnlineTime = DataPool:GetFriend( nChannel, nIndex, "IM_ONLINE_TIME" );
					local namecolor = "#cC4B299";
					if SystemSetup:IsClassic() == 0 then
							namecolor = "#c9e9e9d"
					end
					local bShine = ""
					if haveMsg == 1 then
						bShine = "#b";
					end
					local moodColor = "#cFFCC7A";
					local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
					if idZoneWorld ~= -1 and idZoneWorld ~= selfZoneWorldID then
						name = name .. "@" .. DataPool:GetServerName(idZoneWorld)
					end

					local IMst = DataPool:GetFriend( nChannel, nIndex, "IM_STATUS" );
					local Sex = DataPool:GetFriend( nChannel, nIndex, "SEX" );
					local playerIcon = g_IconSpin

					if( DataPool:GetFriend( nChannel, nIndex, "ONLINE" ) ) then
						if( nChannel == 6 or nChannel == 11 ) then
							namecolor="#cFF0000";
						else
							if( relationtype == 7 or relationtype == 8) then
								namecolor = "#cFF6600";
							elseif( relationtype == 3 ) then
								namecolor = "#cF246F0";
							elseif( relationtype == 2 ) then
								namecolor = "#c007EFF";
								local isSpouse = DataPool:GetFriend( nChannel, nIndex, "IS_SPOUSE" )
								if isSpouse == 1 then
									namecolor = "#cF246F0"					--结拜 并且在配偶列
								end
							elseif( friendship >= 10 ) then
									namecolor = "#c00FF00";
							elseif( friendship >= 1 ) then
								if SystemSetup:IsClassic() == 1 then
									namecolor = "#c00C800";
								else
									namecolor = "#c00cd00";
								end
							elseif( friendship == 0 ) then
									namecolor = "#cFFFFFF";
							end
						end
						if IMst >= 0 and IMst <=2  and Sex >=0 and Sex <= 1 then
							playerIcon = g_imgStatus[Sex][IMst]
						end
						local listName = ""
						if( remark ~=nil and remark ~= "" ) then
							listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
						else
							listName = playerIcon..bShine..namecolor..name
						end
						local listmood = g_IconSpin..moodColor..emotion
						Friend_List:AddItem( g_FriendBorderColor..listName.."#r"..listmood ,i,"FFFFFFFF", 4);
						local zoneWorldID = DataPool:GetFriend(nChannel, nIndex, "ZONEWORLDID" )
						local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
						if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
							--大世界好友不加tips
						else
							local idx = Friend_List:GetItemNumByItemId( i )
							if idx >= 0 then
								local iconStr = Friend_GetOnlineTimeIconStr(imOnlineTime)
								if imOnlineTime ~= "" then
									Friend_List:SetItemTooltip(idx , tostring(iconStr))
								end
							end
						end
					else
						if( nChannel == 6 or nChannel == 11 ) then
							namecolor="#cc7b299";
						end
						local listName = ""
						if( remark ~=nil and remark ~= "" ) then
							listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
						else
							listName = playerIcon..bShine..namecolor..name
						end
						Friend_List:AddItem( g_FriendBorderColor..listName ,i);
					end
				end
			end
		end
	end
	if g_Current_Clicked ~= -1 then
		Friend_List:SetCurrentFirstItem(g_Current_Clicked);
		g_Current_Clicked = -1
	end
end

--更新最近联系人里的一个玩家信息
function Friend_Update_Recent(nIndex)
	local idx = Friend_List:GetItemNumByItemId(nIndex)
	if idx == -1 then
		return
	end

	local isGroup , sID , sName, idZoneWorld = DataPool:GetIMRecentByIndex(nIndex)
	if  isGroup ~= -1 and sID ~= -1 then
		if isGroup == 1 then
			local bShine = DataPool:IsChatGroupHaveMsg(sID) ;
			if bShine == 1 then
				Friend_List:SetListItemText( idx , g_FriendBorderColor.."#-31#b"..sName ,nIndex );
			else
				Friend_List:SetListItemText( idx , g_FriendBorderColor.."#-31"..sName ,nIndex);
			end

		elseif isGroup == 0 then
			local nChannel , nIndex = DataPool:GetFriendByName(sName)
			if nChannel ~= -1 and nIndex ~= -1 then
				local name = DataPool:GetFriend( nChannel, nIndex, "NAME" );
				local remark =  Friend_GetSpecialRemark( nChannel, nIndex )
				local emotion = DataPool:GetFriend( nChannel, nIndex, "MOOD" );
				local friendship = DataPool:GetFriend( nChannel, nIndex, "FRIENDSHIP" );
				local relationtype = DataPool:GetFriend( nChannel, nIndex, "RELATION_TYPE" );
				local haveMsg = DataPool:GetFriend( nChannel, nIndex, "MSG" );
				local imOnlineTime = DataPool:GetFriend( nChannel, nIndex, "IM_ONLINE_TIME" );
				local namecolor = "#cC4B299";
				if SystemSetup:IsClassic() == 0 then
						namecolor = "#c9e9e9d"
				end
				local bShine = ""
				if haveMsg == 1 then
					bShine = "#b";
				end
				local moodColor = "#cFFCC7A";
				local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
				if idZoneWorld ~= -1 and idZoneWorld ~= selfZoneWorldID then
					name = name .. "@" .. DataPool:GetServerName(idZoneWorld)
				end

				local IMst = DataPool:GetFriend( nChannel, nIndex, "IM_STATUS" );
				local Sex = DataPool:GetFriend( nChannel, nIndex, "SEX" );
				local playerIcon = g_IconSpin

				if( DataPool:GetFriend( nChannel, nIndex, "ONLINE" ) ) then
					if( nChannel == 6 or nChannel == 11 ) then
						namecolor="#cFF0000";
					else
						if( relationtype == 7 or relationtype == 8) then
							namecolor = "#cFF6600";
						elseif( relationtype == 3 ) then
							namecolor = "#cF246F0";
						elseif( relationtype == 2 ) then
							namecolor = "#c007EFF";
							local isSpouse = DataPool:GetFriend( nChannel, nIndex, "IS_SPOUSE" )
							if isSpouse == 1 then
								namecolor = "#cF246F0"					--结拜 并且在配偶列
							end
						elseif( friendship >= 10 ) then
								namecolor = "#c00FF00";
						elseif( friendship >= 1 ) then
							if SystemSetup:IsClassic() == 1 then
								namecolor = "#c00C800";
							else
								namecolor = "#c00cd00";
							end
						elseif( friendship == 0 ) then
								namecolor = "#cFFFFFF";
						end
					end
					if IMst >= 0 and IMst <=2  and Sex >=0 and Sex <= 1 then
						playerIcon = g_imgStatus[Sex][IMst]
					end
					local listName = ""
					if( remark ~=nil and remark ~= "" ) then
						listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
					else
						listName = playerIcon..bShine..namecolor..name
					end
					local listmood = g_IconSpin..moodColor..emotion
					Friend_List:SetListItemText(idx, g_FriendBorderColor..listName.."#r"..listmood );
					local zoneWorldID = DataPool:GetFriend(nChannel, nIndex, "ZONEWORLDID" )
					local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
					if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
						--大世界好友不加tips
					else
						local iconStr = Friend_GetOnlineTimeIconStr(imOnlineTime)
						if imOnlineTime ~= "" then
							Friend_List:SetItemTooltip(idx , tostring(iconStr))
						end
					end
				else
					if( nChannel == 6 or nChannel == 11 ) then
						namecolor="#cc7b299";
					end
					local listName = ""
					if( remark ~=nil and remark ~= "" ) then
						listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
					else
						listName = playerIcon..bShine..namecolor..name
					end
					Friend_List:SetListItemText(idx, g_FriendBorderColor..listName ,i);
				end
			end
		end
	end

end
function Friend_List_SelectChanged()

	if g_CurPage == 1 or g_CurPage == 2 then
		local nSelIndex = Friend_List:GetFirstSelectItem();

		local iMod = math.mod( nSelIndex, 10000 )
		local iFloor = math.floor( nSelIndex / 10000 )
		if( 0 == iMod ) then
			
			if iFloor > 100 then
				local iFloorMode = math.mod( iFloor, 100 ) 
				
				if( 0 == g_SpecialFriendOutLine[ iFloorMode ] ) then
					g_SpecialFriendOutLine[ iFloorMode ] = 1
				else
					g_SpecialFriendOutLine[ iFloorMode ] = 0
				end
				
			else
			
				if( 0 == g_IsTeamOutLine[ iFloor ] ) then
					g_IsTeamOutLine[ iFloor ] = 1
				else
					g_IsTeamOutLine[ iFloor ] = 0
				end
				
			end
			
			g_Current_Clicked = Friend_List:GetCurrentFirstItem()
			if g_CurPage == 1 then
				Friend_Update()
			elseif g_CurPage == 2 then
				Friend_List_BigWorld()
			end
			return

		end
	else

	end

end
--点击搜索按钮
function Friend_Search_Friends()

	local strText = Friend_SearchEdit:GetText() ;
	if strText == nil or tostring(strText)== ""  then
		return
	end
	DataPool:SearchFriends(tostring(strText))
end

function Friend_CreateGroup_Clicked()
	ToggleCreateGroup()
end

function Friend_IMSet_Clicked()
	PushEvent("OPEN_IM_SETTING");
end

function Friend_ViewHistory()
	PushEvent("OPEN_IM_CHAT_HISTORY",0,0);
end

--状态改变
function Friend_SelfState_Changed()
	local str , nIndex = Friend_SelfState:GetCurrentSelect()
	if g_CurStatus ~= nIndex then
		g_CurStatus = nIndex
		DataPool:ModifyIMStatus(tonumber(nIndex))
	end
end

function Friend_GetOnlineTimeIconStr(nTime)
	local iconStr = ""
	if nTime ~= nil and nTime >=0 then
		local level , sunNum ,moonNum , starNum = DataPool:GetIMIconNum(tonumber(nTime))
		iconStr = "#{LTQH_XML_98}"..tostring(level).."#r"
		for i = 1 , sunNum + moonNum + starNum do
			if i <= sunNum then
				iconStr = iconStr.."#-37"
			elseif i <= sunNum + moonNum then
				iconStr = iconStr.."#-36"
			elseif i <= sunNum + moonNum + starNum then
				iconStr = iconStr.."#-35"
			end
		end
	end
	return iconStr
end

function Friend_Sns_Clicked()
	
end

function Friend_ButtonClickedForSns()
	
end

function Friend_OpenIMDressChest()

-- 	if IsInTServer() == 1 then
-- --		PushDebugMessage("#{BHKF_140909_327}")
-- 		return
-- 	end
	
	if(IsWindowShow("XuanFitting")) then
		CloseWindow("XuanFitting", true);
	else
		PushEvent("OPEN_IMDRESS_CHEST")
		SendAskIMDressChestPacket()
	end
end

--[天龙家园,20120510]
function Friend_Flash()
	OpenFlash()
end


function Friend_ButtonClickedForSjsl()
	local index = Friend_List:GetClickedButtonItem();
	local nIndex = math.mod(index, 10000) - 1;
	local nChannel = math.floor(index / 10000);
	local Guid = DataPool:GetFriend(nChannel, nIndex, "ID");
	local havePresent = DataPool:GetFriend(nChannel, nIndex, "FRIEND_PRESENT" );

	if havePresent == 1 then
		PushEvent("OPEN_FRIEND_PRESENT", Guid);
	else
		PushDebugMessage("#{SJSL_110507_08}");
		PushEvent("UPDATE_FRIEND");
	end
end

function Friend_JianghuRelation()
	
	CloseFreshManGuide()
	Friend_SearchBtn01_Animate:Play(false)
	Friend_SearchBtn01:SetText("#{XST_110831_20}")
	--默认打开结拜界面
	if (IsWindowShow( "NewFriend_Jiebai")) then
		CloseWindow( "NewFriend_Jiebai", true );
	elseif (IsWindowShow( "Friend_MaritalRelations")) then
		CloseWindow( "Friend_MaritalRelations", true );
	elseif ( IsWindowShow( "NewFriend_ST" ) ) then
		CloseWindow( "NewFriend_ST", true );
	else
		PushEvent("NEWFRIEND_JIEBAI_OPEN")
	end	
	
end

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- hjj 2010/9/26
-- 注意下面的写法 tostring(guid)
-- 这里并不是多此一举
-- 这源自一个"BUG"
-- 我们知道 table[key] = val 给一个表格赋值， key也是一个val,
-- 可以任意取LUA的类型值， 当然可以用guid, 这也是没问题的。
-- 但是：
-- 当index = hashnum(guid),  table.node[index]时:
--
-- static Node *hashnum (const Table *t, lua_Number n) {
--   unsigned int a[numints];
--   int i;
--   n += 1;  /* normalize number (avoid -0) */
--   lua_assert(sizeof(a) <= sizeof(n));
--   memcpy(a, &n, sizeof(a));
--   for (i = 1; i < numints; i++) a[0] += a[i];
--   return hashmod(t, cast(lu_hash, a[0]));
-- }
--
-- 这里会 n+= 1,  double类型在24bit的精度和32bit的精度计算出来的结果不一样的（当为guid时，超过24bit有效位)
-- 这样在出现hash碰撞时， hashnum( table.node[index] ) 看他原来的位置，如果不一致则需要摘链.
--
--       while (othern->next != mp) othern = othern->next;  /* find previous */
--
-- 这里因为精度变了， 可能hash到一个从来没用过的table.node[index_new]上， 然后一直不能==mp，（其实应该肯定会相等的)
-- 所以没判断，导致+18内存访问  --
--
-- 所以：用来做table的key， 不能是guid这种超过24
-- 改为转字符串（这里没有浮点数运算操作，所以没有精度丢失，存储是不丢失精度的，即便只有24BIT）
-- intel指令手册表明， 当有add, sub, inc, dec, mul, div, arc等运算操作才有丢失的， printf是没有的
-- 字符串的hashstr更是安全， 他是用了一个int在构造的时候就算出来了hash值， 全int从操作，绝对安全
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



function Friend_GS()
	local isConnectGS = Talk:IsInGSService()
	if isConnectGS <= 0 then
		 PushDebugMessage("#{GS_130923_11}")
		 return
	end
	
	if isConnectGS == 1 then
			Friend_List:ClearListBoxEx();
			local mGSState = Talk:GetGSState()
			local mGSName = Talk:GetGSName() 
			local col = "#G"
			local statename = ""
			if mGSState ==0 then  --在线
				 col = "#G"
				 statename = " [空闲]"
			elseif mGSState ==1 then
			   col = "#R"
			   statename = " [忙碌]"
			elseif mGSState ==2 then
				 col = "#c808080"
				 statename = " [离线]"
			end
				local temp =" "
				local listName = temp..col.."#-38"..mGSName..statename
				Friend_List:AddItemExWithoutLayout( listName, 10001 ,0, "FFFFFFFF", 4 );
	elseif isConnectGS == 2 then
			Friend_List:ClearListBoxEx();
			local isRet = Talk:GetGSInfoIsRetNew()
			if isRet == 0 then
				Talk:AskGSInfoNew()
			elseif isRet == 1 then
				Friend_List:ClearListBoxEx();
				local mGSState = Talk:GetNewGSState()
				local mGSName = Talk:GetNewGSName()
				local col = "#G"
				local statename = ""
				if mGSState ==0 then  --在线
					 col = "#G"
					 statename = " [在线]"
				elseif mGSState ==1 then
				   col = "#cff0000"
				   statename = " [忙碌]"
				elseif mGSState ==2 then
					 col = "#Y"
					 statename = " [离开]"
				elseif mGSState ==3 then
					 col = "#c787777"
					 statename = " [离线]"
				end
					local temp =" "
					local listName = temp..col.."#-38"..mGSName..statename
					Friend_List:AddItemExWithoutLayout( listName, 10001 ,0, "FFFFFFFF", 4 );	
			end
	end
end

function Friend_SpecialFriendUpdate()

	--婚姻组
	local isHaveSpouse , spouseGuid = Friend:Lua_GetSpouseGuid()
	if isHaveSpouse == 1 then
	
		local strOutlineName = "我的婚姻"
		if g_SpecialFriendOutLine[ 1 ] == 1 then
			if SystemSetup:IsClassic() == 1 then
				strOutlineName = g_GroupTitleColor.."- " .. strOutlineName
			else
				strOutlineName = g_GroupTitleColor_WM.."- " .. strOutlineName
			end
		else
			if SystemSetup:IsClassic() == 1 then
				strOutlineName = g_GroupTitleColor.."+ " .. strOutlineName
			else
				strOutlineName = g_GroupTitleColor_WM.."+ " .. strOutlineName
			end
		end
		
		local isOnline = Friend:Lua_IsSpouseInFriendOnline()
		strOutlineName = strOutlineName.."(" ..tostring(isOnline).."/1)"
		
		local iStart = 101*10000
		Friend_List:AddItem( strOutlineName, iStart )
		if g_SpecialFriendOutLine[ 1 ] == 1 then
			local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(spouseGuid)
			if nGroup ~= nil and nIndex ~= nil then
				if nGroup >= 0 and nIndex >= 0 then
					local Sex = GetMySelfRaceId()
					if Sex == 1 then
						Friend_AddSpecialFriendItem( nGroup, nIndex , "我的娘子" )
					elseif Sex == 0 then
						Friend_AddSpecialFriendItem( nGroup, nIndex , "我的夫君" )
					end
				end
			end
		end
	end
	
	--结拜组 ，不包括已经出现在婚姻组的成员
	local nBrotherCount = DataPool:GetBrotherCount()
	local nBrotherListNum = Friend:Lua_GetBrotherNumExceptSpouse()
	local nOnlineBrotherListNum = Friend:Lua_GetOnlineBrotherNumExceptSpouse()
	
	if nBrotherListNum > 0 then
	
		local strOutlineName = "我的结拜"
		if g_SpecialFriendOutLine[ 2 ] == 1 then
			if SystemSetup:IsClassic() == 1 then
				strOutlineName = g_GroupTitleColor.."- " .. strOutlineName
			else
				strOutlineName = g_GroupTitleColor_WM.."- " .. strOutlineName
			end
		else
			if SystemSetup:IsClassic() == 1 then
				strOutlineName = g_GroupTitleColor.."+ " .. strOutlineName
			else
				strOutlineName = g_GroupTitleColor_WM.."+ " .. strOutlineName
			end
		end
		
		strOutlineName = strOutlineName.."(" ..tostring(nOnlineBrotherListNum).."/"..tostring(nBrotherListNum)..")"
		
		local iStart = 102*10000
		Friend_List:AddItem( strOutlineName, iStart )
		if g_SpecialFriendOutLine[ 2 ] == 1 then
			local selfPos = DataPool:GetSelfBrotherInfo("CharPos")

			for ind = 1, nBrotherCount do
				local charPos = DataPool:GetBrotherInfoByInd(ind - 1, "CharPos")
				local nBrotherGuid = DataPool:GetBrotherInfoByInd(ind - 1, "CharGuid")
				local charSex = DataPool:GetBrotherInfoByInd(ind - 1, "CharSex")
				if charPos >= 0 and charPos <= 5 and charPos ~= selfPos then
					if nBrotherGuid ~= nil and nBrotherGuid ~= spouseGuid then
						local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nBrotherGuid)
						if nGroup ~= nil and nIndex ~= nil then
							if nGroup >= 0 and nIndex >= 0 then
								if( DataPool:GetFriend( nGroup, nIndex, "ONLINE" ) ) then
									local remark = g_BrotherOrderStr[ charPos + 1 ] 
									if selfPos ~= nil then
										if charSex == 0 or charSex == 1 then
											if charPos < selfPos then
												remark = m_PosName[charPos + 1]..m_OldName[charSex + 1]
											else
												remark = m_PosName[charPos + 1]..m_YoungName[charSex + 1]
											end
										end
									end
									Friend_AddSpecialFriendItem( nGroup, nIndex , remark )
								end
							end
						end
					end
				end
			end

			for ind = 1, nBrotherCount do
				local charPos = DataPool:GetBrotherInfoByInd(ind - 1, "CharPos")
				local nBrotherGuid = DataPool:GetBrotherInfoByInd(ind - 1, "CharGuid")
				local charSex = DataPool:GetBrotherInfoByInd(ind - 1, "CharSex")
				if charPos >= 0 and charPos <= 5 and charPos ~= selfPos then
					if nBrotherGuid ~= nil and nBrotherGuid ~= spouseGuid then
						local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nBrotherGuid)
						if nGroup ~= nil and nIndex ~= nil then
							if nGroup >= 0 and nIndex >= 0 then
								if( not ( DataPool:GetFriend( nGroup, nIndex, "ONLINE" ) ) ) then
									local remark = g_BrotherOrderStr[ charPos + 1 ] 
									if selfPos ~= nil then
										if charSex == 0 or charSex == 1 then
											if charPos < selfPos then
												remark = m_PosName[charPos + 1]..m_OldName[charSex + 1]
											else
												remark = m_PosName[charPos + 1]..m_YoungName[charSex + 1]
											end
										end
									end
									Friend_AddSpecialFriendItem( nGroup, nIndex , remark )
								end
							end
						end
					end
				end
			end

		end
	end
	
	--师门组 ，不包括已经出现在婚姻组和结拜组的成员
	local nShimenMemberNumExceptSpouseAndBrother= Friend:Lua_GetShimenMemberNumExceptSpouseAndBrother()
	local nOnlineShimenMemberNumExceptSpouseAndBrother= Friend:Lua_GetOnlineShimenMemberNumExceptSpouseAndBrother()
	if nShimenMemberNumExceptSpouseAndBrother > 0 then
	
		local strOutlineName = "我的师门"
		if g_SpecialFriendOutLine[ 3 ] == 1 then
			if SystemSetup:IsClassic() == 1 then
				strOutlineName = g_GroupTitleColor.."- " .. strOutlineName
			else
				strOutlineName = g_GroupTitleColor_WM.."- " .. strOutlineName
			end
		else
			if SystemSetup:IsClassic() == 1 then
				strOutlineName = g_GroupTitleColor.."+ " .. strOutlineName
			else
				strOutlineName = g_GroupTitleColor_WM.."+ " .. strOutlineName
			end
		end
		
		strOutlineName = strOutlineName.."(" ..tostring(nOnlineShimenMemberNumExceptSpouseAndBrother).."/"..tostring(nShimenMemberNumExceptSpouseAndBrother)..")"
		
		local iStart = 103*10000
		Friend_List:AddItem( strOutlineName, iStart )
		if g_SpecialFriendOutLine[ 3 ] == 1 then
			local titles = {"大","二","三","四","五","六","七","八"}
			local myrank = 8
			for i=0,8 do
				local nGUID,	szCharName,nType,nSex,nLevel,szGuildName,nQinmi,nGongfeng,nStartDay,nIsOnline = WenDingUI:GetShiMenInfoByIdx( i ,1)
				local remark = ""
				if i == 0 and nType == 1 and szCharName ~= "" then							
					remark = "师父"
				elseif nType == 2 and szCharName ~= "" then				
					if szCharName == Player:GetName() then
						myrank = i
					else
						if nSex == 1 then
							if i > myrank then
								remark = titles[i].."师弟"
							else
								remark = titles[i].."师兄"
							end
						else
							if i > myrank then
								remark = titles[i].."师妹"
							else
								remark = titles[i].."师姐"
							end
						end
					end
				end
				if nGUID ~= nil and nGUID ~= spouseGuid then	--不是配偶
					local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nGUID)
					if nGroup ~= nil and nIndex ~= nil then
						if nGroup >= 1 and nGroup <= 4 and nIndex >= 0 then
							if DataPool:GetFriend( nGroup, nIndex, "RELATION_TYPE" ) ~= 2 then -- 不是结拜
								if( DataPool:GetFriend( nGroup, nIndex, "ONLINE" ) ) then
									Friend_AddSpecialFriendItem( nGroup, nIndex , remark)
								end
							end
						end
					end
				end
			end
			
			myrank = 8
			for i=0,8 do
				local nGUID,	szCharName,nType,nSex,nLevel,szGuildName,nQinmi,nGongfeng,nStartDay,nIsOnline = WenDingUI:GetShiMenInfoByIdx( i ,1)
				local remark = ""
				if i == 0 and nType == 1 and szCharName ~= "" then							
					remark = "师父"
				elseif nType == 2 and szCharName ~= "" then				
					if szCharName == Player:GetName() then
						myrank = i
					else
						if nSex == 1 then
							if i > myrank then
								remark = titles[i].."师弟"
							else
								remark = titles[i].."师兄"
							end
						else
							if i > myrank then
								remark = titles[i].."师妹"
							else
								remark = titles[i].."师姐"
							end
						end
					end
				end
				if nGUID ~= nil and nGUID ~= spouseGuid then
					local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nGUID)
					if nGroup ~= nil and nIndex ~= nil then
						if nGroup >= 1 and nGroup <= 4 and nIndex >= 0 then
							if DataPool:GetFriend( nGroup, nIndex, "RELATION_TYPE" ) ~= 2 then -- 不是结拜
								if( not (DataPool:GetFriend( nGroup, nIndex, "ONLINE" ) ) ) then
									Friend_AddSpecialFriendItem( nGroup, nIndex , remark)
								end
							end
						end
					end
				end
			end	
		end
	end
	
	--徒弟组
	local nRecruitNum = Friend:Lua_GetRecruitNum()
	local nOnlineRecruitNum = Friend:Lua_GetOnlineRecruitNum()
	if nRecruitNum > 0 then
	
		local strOutlineName = "我的徒弟"
		if g_SpecialFriendOutLine[ 4 ] == 1 then
			if SystemSetup:IsClassic() == 1 then
				strOutlineName = g_GroupTitleColor.."- " .. strOutlineName
			else
				strOutlineName = g_GroupTitleColor_WM.."- " .. strOutlineName
			end
		else
			if SystemSetup:IsClassic() == 1 then
				strOutlineName = g_GroupTitleColor.."+ " .. strOutlineName
			else
				strOutlineName = g_GroupTitleColor_WM.."+ " .. strOutlineName
			end
		end
		
		strOutlineName = strOutlineName.."(" ..tostring(nOnlineRecruitNum).."/"..tostring(nRecruitNum)..")"
		
		local iStart = 104*10000
		Friend_List:AddItem( strOutlineName, iStart )
		if g_SpecialFriendOutLine[ 4 ] == 1 then
			local titles = {"大","二","三","四","五","六","七","八"}	

			for i=0,8 do
				local nGUID,szCharName,nType,nSex,nLevel,szGuildName,nQinmi,nGongfeng,nStartDay,nIsOnline = WenDingUI:GetShiMenInfoByIdx( i ,2)
				local remark = ""
				if nType == 2 and szCharName ~= "" then
					remark = titles[i].."徒弟"
					if nGUID ~= nil then
						local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nGUID)
						if nGroup ~= nil and nIndex ~= nil then
							if nGroup >= 0 and nIndex >= 0 then
								if( DataPool:GetFriend( nGroup, nIndex, "ONLINE" ) ) then
									Friend_AddSpecialFriendItem( nGroup, nIndex , remark )
								end
							end
						end
					end
				end
			end

			for i=0,8 do
				local nGUID,szCharName,nType,nSex,nLevel,szGuildName,nQinmi,nGongfeng,nStartDay,nIsOnline = WenDingUI:GetShiMenInfoByIdx( i ,2)
				local remark = ""
				if nType == 2 and szCharName ~= "" then
					remark = titles[i].."徒弟"
					if nGUID ~= nil then
						local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nGUID)
						if nGroup ~= nil and nIndex ~= nil then
							if nGroup >= 0 and nIndex >= 0 then
								if( not ( DataPool:GetFriend( nGroup, nIndex, "ONLINE" ) ) ) then
									Friend_AddSpecialFriendItem( nGroup, nIndex , remark )
								end
							end
						end
					end
				end
			end			
		end
	end
	
end

function Friend_AddSpecialFriendItem( nChannel, nIndex , remark )

	local name = DataPool:GetFriend( nChannel, nIndex, "NAME" );
	local emotion = DataPool:GetFriend( nChannel, nIndex, "MOOD" );
	local friendship = DataPool:GetFriend( nChannel, nIndex, "FRIENDSHIP" );
	local relationtype = DataPool:GetFriend( nChannel, nIndex, "RELATION_TYPE" );
	local imOnlineTime = DataPool:GetFriend( nChannel, nIndex, "IM_ONLINE_TIME" );
	local IMst = DataPool:GetFriend( nChannel, nIndex, "IM_STATUS" );
	local Sex = DataPool:GetFriend( nChannel, nIndex, "SEX" );
	local haveMsg = DataPool:GetFriend( nChannel, nIndex, "MSG" );
	local guid =  DataPool:GetFriend( nChannel, nIndex, "ID" );
	local havePresent = DataPool:GetFriend(nChannel, nIndex, "FRIEND_PRESENT" );
	local nLevel = DataPool:GetFriend(nChannel, nIndex, "LEVEL");	

	
	local namecolor = "#cC4B299";
	if SystemSetup:IsClassic() == 0 then
			namecolor = "#c9e9e9d"
	end
	local bShine = ""
	if haveMsg == 1 then
		bShine = "#b";
	end
	local playerIcon = g_IconSpin
	local moodColor = "#cFFCC7A";
	local zoneWorldID = DataPool:GetFriend(nChannel, nIndex, "ZONEWORLDID" )
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
		name = name .. "@" .. DataPool:GetServerName(zoneWorldID)
	end
	local isbindapp = DataPool:GetFriend( nChannel, nIndex, "FRIEND_ISAPPBIND"); --0未绑定，1绑定

	if( DataPool:GetFriend( nChannel, nIndex, "ONLINE" ) ) then
		if( nChannel == 6 or nChannel == 7 or nChannel == 11) then
			namecolor="#cFF0000";					
		else
			if( relationtype == 7 or relationtype == 8) then			--  7:师傅 8：徒弟
				namecolor = "#cFF6600";
			elseif( relationtype == 3 ) then					-- 3：结婚
				namecolor = "#cF246F0";
			elseif( relationtype == 2 ) then					-- 2：结拜
				namecolor = "#c007EFF"
				local isSpouse = DataPool:GetFriend( nChannel, nIndex, "IS_SPOUSE" )
				if isSpouse == 1 then
					namecolor = "#cF246F0"					--结拜 并且在配偶列
				end
			elseif( friendship >= 10 ) then  						--[2007/08/28 YangJun]
					namecolor = "#c00FF00";
			elseif( friendship >= 1 ) then							--[2007/08/28 YangJun]
				if SystemSetup:IsClassic() == 1 then
					namecolor = "#c00C800";
				else
					namecolor = "#c00cd00";
				end
			elseif( friendship == 0 ) then	--[2007/08/28 YangJun]
					namecolor = "#cFFFFFF";
			end
		end
		if IMst >= 0 and IMst <=2  and Sex >=0 and Sex <= 1 then
			playerIcon = g_imgStatus[Sex][IMst]
		end
		local listName = ""
		if( remark ~=nil and remark ~= "" ) then
			listName = g_FriendSpin..playerIcon..bShine..namecolor..name.."#r"..g_FriendSpin..g_IconSpin..namecolor.."("..remark..")"
		else
			listName = g_FriendSpin..playerIcon..bShine..namecolor..name
		end
		local listmood = g_FriendSpin..g_IconSpin..moodColor..emotion
		if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
			if( remark ~=nil and remark ~= "" ) then
				listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
			else
				listName = playerIcon..bShine..namecolor..name
			end
			listmood = g_IconSpin..moodColor..emotion
		end
		if nChannel > 0 and nChannel < 5 and nIndex >= 0 then
			
			Friend_List:AddItemExWithoutLayout(g_FriendBorderColor..listName.."#r"..listmood , nChannel*10000 + nIndex + 1 ,4, "FFFFFFFF", 4, havePresent,isbindapp,0);
			
		else
			Friend_List:AddItem( g_FriendBorderColor..listName.."#r"..listmood , nChannel*10000 + nIndex + 1 , "FFFFFFFF", 4 );
		end
		if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
		--大世界好友不加tips
		else
			local idx = Friend_List:GetItemNumByItemId(nChannel*10000 + nIndex + 1)
			if idx >= 0 then
				local iconStr = Friend_GetOnlineTimeIconStr(imOnlineTime)
				if imOnlineTime ~= "" then
					Friend_List:SetItemTooltip(idx , tostring(iconStr))
				end
			end
		end
	else
		if( nChannel == 6 or nChannel == 11) then
			namecolor="#cc7b299";
		end
		local listName = ""
		if( remark ~=nil and remark ~= "" ) then
			listName = g_FriendSpin..playerIcon..bShine..namecolor..name.."#r"..g_FriendSpin..g_IconSpin..namecolor.."("..remark..")"
		else
			listName = g_FriendSpin..playerIcon..bShine..namecolor..name
		end
		if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
			if( remark ~=nil and remark ~= "" ) then
				listName = playerIcon..bShine..namecolor..name.."#r"..g_IconSpin..namecolor.."("..remark..")"
			else
				listName = playerIcon..bShine..namecolor..name
			end
		end

		if( nChannel == 1 or nChannel == 2 or nChannel == 3 or nChannel == 4 ) then
			Friend_List:AddItemExWithoutLayout( g_FriendBorderColor..listName, nChannel*10000 + nIndex + 1 ,8, "FFFFFFFF", 4, 0,isbindapp,0,0,0,0 );
		else
			Friend_List:AddItemExWithoutLayout( g_FriendBorderColor..listName, nChannel*10000 + nIndex + 1 ,8, "FFFFFFFF", 4, 0,0,0,0,0,0 );
		end
	end

end

function Friend_ShowInCommonFriendGroup(  nChannel, nIndex )
	
	if nChannel < 1 or nChannel > 4 then
		return 1
	end
	
	local nRelationType = DataPool:GetFriend( nChannel, nIndex, "RELATION_TYPE" )
	local guid =  DataPool:GetFriend( nChannel, nIndex, "ID" )
	
	if nRelationType == 7 and Friend:Lua_IsShimenMemberInfoValid() == 1 then		--师傅
		return 0
	end
	
	if nRelationType == 8 then		--徒弟
		return 0
	end
	
	if nRelationType == 3 then		--配偶
		return 0
	end 
	
	if nRelationType == 2 then		--结拜
		return 0
	end 
	
	if Friend:Lua_IsShimenMemberInfoValid() == 1 and Friend:Lua_IsSameMasterWithMe(guid) == 1 then
		return 0
	end
	
	return 1

end

function Friend_GetSpecialRemark( nChannel, nIndex )

	local remark = DataPool:GetFriend( nChannel, nIndex, "REMARK" )
	local guid =  DataPool:GetFriend( nChannel, nIndex, "ID" )
	if guid == nil or guid == "" then
		return remark
	end
	
	local isHaveSpouse , spouseGuid = Friend:Lua_GetSpouseGuid()
	if isHaveSpouse == 1 then
		if spouseGuid == guid then
			local Sex = GetMySelfRaceId()
			if Sex == 1 then
				remark = "我的娘子" 
			elseif Sex == 0 then
				remark = "我的夫君" 
			end
			return  remark
		end
	end

	local nBrotherCount = DataPool:GetBrotherCount()
	if nBrotherCount > 1 then
		local selfPos = DataPool:GetSelfBrotherInfo("CharPos")
		if nBrotherCount > 1 then
			for ind = 1, nBrotherCount do
				local charPos = DataPool:GetBrotherInfoByInd(ind - 1, "CharPos")
				local nBrotherGuid = DataPool:GetBrotherInfoByInd(ind - 1, "CharGuid")
				local charSex = DataPool:GetBrotherInfoByInd(ind - 1, "CharSex")
				if charPos >= 0 and charPos <= 5 and charPos ~= selfPos then
					if nBrotherGuid == guid then
						remark = g_BrotherOrderStr[ charPos + 1 ] 
						if selfPos ~= nil then
							if charSex == 0 or charSex == 1 then
								if charPos < selfPos then
									remark = m_PosName[charPos + 1]..m_OldName[charSex + 1]
								else
									remark = m_PosName[charPos + 1]..m_YoungName[charSex + 1]
								end
							end
						end
						return remark
					end
				end
			end	
		end
	end
	
	local nShimenMemberNumExceptSpouseAndBrother= Friend:Lua_GetShimenMemberNumExceptSpouseAndBrother()
	if nShimenMemberNumExceptSpouseAndBrother > 0 then

		local titles = {"大","二","三","四","五","六","七","八"}
		local myrank = 8
		for i=0,8 do
			local nGUID,	szCharName,nType,nSex,nLevel,szGuildName,nQinmi,nGongfeng,nStartDay,nIsOnline = WenDingUI:GetShiMenInfoByIdx( i ,1)
			if i == 0 and nType == 1 and szCharName ~= "" then							
				
				if nGUID == guid then
					remark = "师父"
					return remark
				end
				
			elseif nType == 2 and szCharName ~= "" then				
				if szCharName == Player:GetName() then
					myrank = i
				else
					if nGUID == guid then
						if nSex == 1 then
							if i > myrank then
								remark = titles[i].."师弟"
							else
								remark = titles[i].."师兄"
							end
						else
							if i > myrank then
								remark = titles[i].."师妹"
							else
								remark = titles[i].."师姐"
							end
						end
						return remark
					end
				end
			end
		end		
	end
	
	local nRecruitNum = Friend:Lua_GetRecruitNum()
	if nRecruitNum > 0 then
			
		local titles = {"大","二","三","四","五","六","七","八"}	
		for i=0,8 do
			local nGUID,szCharName,nType,nSex,nLevel,szGuildName,nQinmi,nGongfeng,nStartDay,nIsOnline = WenDingUI:GetShiMenInfoByIdx( i ,2)
			if nGUID == guid then
				if nType == 2 and szCharName ~= "" then
					remark = titles[i].."徒弟"
				end
				return remark
			end
		end	
	end
	
	
	return remark
end

function Friend_ChatSignClicked()
	DataPool:SetIsShowChatSignRedPoint() 
	Friend_ChatSign_Tips:Hide()
	Lua_OpenChatSymbol()
	PushEvent("HIDE_CHATSIGN_REDPOINT")
end
function Friend_veriface_Clicked()
	Clear_XSCRIPT()
	Set_XSCRIPT_ScriptID(999099)
	Set_XSCRIPT_Function_Name("OpenAuthFaceUI")
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
