--- 帮会管理信息。Added By David Gao. 2011.07.12
--
local g_NewMembersCtl = {};
local g_TabSel = -1;
local g_ListToMember;
local g_MemberSel = {};


local GUILD_REQUIRES_INFO = 1;	--全部申请成员信息
local GUILD_MEMBERS_INFO = 2;		--全部成员信息
local GUILD_MANAGE_TAB_TEXT = {};
local g_ShowMsgFlag = false;

local g_AssChiefPos = 8;
local g_MemberSortOrder = 1;   --排序方式，正式成员列表使用
local g_NewBangHui_Hygl_Frame_UnifiedPosition = nil
local g_MatchTestBeginTime = 20141218			--点击雄霸天下按钮时进行以下判断,当前时间是否处于2014年12月18日0点之后
local g_MatchTestBeg_LM	= 20141128				-- 龙门测试赛开始时间

local g_Timers = 0
local g_Seconds = 4

local g_positionInfo = {
	"#G待批准　",
	"帮众　　",
	"精英　　",
	"商人　　",
	"弘化使　",
	"工务使　",
	"内务使　",
	"副帮主　",
	"帮主　　",
};

local g_menpaiInfo = {
	"少林",
	"明教",
	"丐帮",
	"武当",
	"峨嵋",
	"星宿",
	"天龙",
	"天山",
	"逍遥",
	"无门派",
	"慕容",
	"唐门",
	"鬼谷",
	"#{XQ_MP_15}", --桃花岛
	"#{XMPHM_210604_01}",
	"#{GMGameInterface_Script_DataPool_Info_ERenGu}",--menpai15 mptodo
};

-- 城战轮换（霸者天下）助战操作时间
local NewBangHui_Hygl_AssistOpTime =
{
    [1] = {weekday = 5, begintime = 213000},
    [2] = {weekday = 6, endtime = 202000},
} -- end NewBangHui_Hygl_AssistOpTime

function NewBangHui_Hygl_PreLoad()
    this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("GUILD_SHOW_MEMBERINFO");
	this:RegisterEvent("GUILD_UPDATE_MEMBERINFO");
	this:RegisterEvent("GUILD_FORCE_CLOSE");
	this:RegisterEvent("ACCELERATE_KEYSEND");
	this:RegisterEvent("GUILD_SELFEQUIP_CLICK");
	this:RegisterEvent("GUILD_ClOSE");
	this:RegisterEvent("SHOW_GUILDWAR_ANIMI");
	this:RegisterEvent("OPEN_GUILD_GIFT")
	this:RegisterEvent("GUILD_ZHANTUAN_OP")


    this:RegisterEvent( "GUILD_SHOW_DETAILINFO" )
    this:RegisterEvent( "GUILD_LEAGUE_INFO" )
    this:RegisterEvent( "GUILDWAR_YXSSCHANGE" )
	
	this:RegisterEvent("ZHANTUAN_LIST_DATA");

	this:RegisterEvent("GUILD_SHOW_ENEMYLIST")
	this:RegisterEvent("OPEN_BUILD_INTRODUCE")
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("HYGL_ITEM_RIGHT_CLICKED")
	-- 请求刷新装备评分
    this:RegisterEvent("GUILDWAR_REFLASHEP")
	this:RegisterEvent("OPENMYALLIANCE");
	--界面互斥
	this:RegisterEvent("ONOPENBIEYEFURCREATE")
	this:RegisterEvent("GUILD_BIDDING_SHOWLIST")
	--this:RegisterEvent("TCITYWARLIMIT_OPENCANDIDATE")
end

function NewBangHui_Hygl_OnLoad()
    g_MemberSel[GUILD_REQUIRES_INFO] = -1;
	g_MemberSel[GUILD_MEMBERS_INFO] = -1;
	
		GUILD_MANAGE_TAB_TEXT = {
		"会员",
		"#{BHJM_140520_08}",
	};

	
	g_NewBangHui_Hygl_Frame_UnifiedPosition = NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition");
	
    NewBangHui_Hygl_SearchMode:AddTextItem("#{BHGL_XML_01}" ,1)			--默认：职位+姓名+是否在线
	NewBangHui_Hygl_SearchMode:AddTextItem("#{BHGL_XML_02}" ,2)			--离线时间从近至远
	NewBangHui_Hygl_SearchMode:AddTextItem("#{BHGL_XML_03}" ,3)			--离线时间从远到近
	NewBangHui_Hygl_SearchMode:AddTextItem("#{BHGL_XML_04}" ,4)			--贡献度从大到小
	NewBangHui_Hygl_SearchMode:AddTextItem("#{BHGL_XML_05}" ,5)			--贡献度从小到大
	NewBangHui_Hygl_SearchMode:AddTextItem("#{BHGL_XML_06}" ,6)			--等级从高到低
	NewBangHui_Hygl_SearchMode:AddTextItem("#{BHGL_XML_07}" ,7)			--等级从低到高
	NewBangHui_Hygl_SearchMode:AddTextItem("#{BHJM_140520_23}",8)		--周贡献度从大到小
	NewBangHui_Hygl_SearchMode:AddTextItem("#{BHJM_140520_24}",9)		--周贡献度从小到大
	NewBangHui_Hygl_SearchMode:AddTextItem("#{BHZL_140812_03}",10)		--装备评分从高到低
	NewBangHui_Hygl_SearchMode:AddTextItem("#{BHZL_140812_04}",11)		--装备评分从低到高
	NewBangHui_Hygl_SearchMode:AddTextItem("#{BHKF_140909_441}" ,16)			--门派顺序
	NewBangHui_Hygl_SearchMode:SetCurrentSelect(0)
	
		g_NewMembersCtl = {
									-- list = NewBangHui_Hygl_SQJRList,
									header = NewBangHui_Hygl_PageHeader,
									count = NewBangHui_Hygl_Online_Text,
									name = NewBangHui_Hygl_Info1_Text,
									info = {
														{txt = NewBangHui_Hygl_Chengyuanmingcheng_Text1, msg = NewBangHui_Hygl_Chengyuanmingcheng_Text2,},
														{txt = NewBangHui_Hygl_GUID_Text1, msg = NewBangHui_Hygl_GUID_Text2,},
														{txt = NewBangHui_Hygl_Gongxian_Text1, msg = NewBangHui_Hygl_Gongxian_Text2,},
														{txt = NewBangHui_Hygl_ZhongDubi_Text1, msg = NewBangHui_Hygl_ZhongDubi_Text2,},
														{txt = NewBangHui_Hygl_RubangDate_Text1, msg = NewBangHui_Hygl_RubangDate_Text2,},
														{txt = NewBangHui_Hygl_ShangxianDate_Text1, msg = NewBangHui_Hygl_ShangxianDate_Text2,},
														{txt = NewBangHui_Hygl_EquipPoint_Text1, msg = NewBangHui_Hygl_EquipPoint_Text2,},
												 },
									desc = NewBangHui_Hygl_BHCY_ZhongzhiText,
									edit = NewBangHui_Hygl_BHCY_ZhongzhiEidit,

									btn = {
												[1]	= NewBangHui_Hygl_RenMing_Button,
												[2]	= NewBangHui_Hygl_ZhuChu_Button,
												[3]	= NewBangHui_Hygl_ShanRang_Button,
                                                    --- TODO: 这里说一下，新的界面没有配置解散和离开，所以这里临时写个数值
										            --NewBangHui_Hygl_1，    --- ConfraternityManage_4,  --- 解散
												[5]	= NewBangHui_Hygl_XiugaiZhongzhi_Button,
                                                    --NewBangHui_Hygl_1，    --- ConfraternityManage_6,  --- 离开
												[7]	= NewBangHui_Hygl_Bhxz,
												[8]	= NewBangHui_Hygl_8,		--add by xindefeng
												[9]	= NewBangHui_Hygl_JieShou_Button,
												[10]	= NewBangHui_Hygl_Jujue_Button,
											  },

								NewBangHui_Hygl_SQRB_Button,
								NewBangHui_Hygl_BHCY_Button,

									combo = NewBangHui_Hygl_SearchMode,
									combodesc = NewBangHui_Hygl_Paixu,
								 };
								 
								 
					 
	
	
end


function NewBangHui_Hygl_SetCtl()

								 
	

	
end



function NewBangHui_Hygl_OnEvent(event)
	-- NewBangHui_Hygl_SetCtl()
	if (event == "GUILD_SHOW_MEMBERINFO") then
		if TLCJ:IsInTLCJScene() > 0 then
			PushDebugMessage("#{TLCJ_20240709_69}")
			return 
		end
		NewBangHui_Hygl_SetDynamic_Pos()
		NewBangHui_Hygl_Hygl:SetCheck(1)
		--每次打开界面,重置排序
		if 1 ~= g_MemberSortOrder then
	        g_MemberSortOrder = 1
	        NewBangHui_Hygl_SearchMode:SetCurrentSelect(0)
	    end
        --准备数据
		Guild:PrepareMembersInfomation(g_MemberSortOrder);		
		
		NewBangHui_Hygl_SelectTab(GUILD_MEMBERS_INFO);
		NewBangHui_Hygl_SetTitle()
		this:Show();

		-- -- 霸者天下小红点
		-- local bztxApplyNum = DataPool:TCWLGetAssistApplyNum()
		-- local bztxIsInTime = NewBangHui_Hygl_Check_BZTXAssistEnrollTime()
		-- if (bztxIsInTime > 0) then
		-- 	if (bztxApplyNum <= 0) then
		-- 		NewBangHui_Hygl_BZTX_Tips:Hide()
		-- 	else
		-- 		local isChiefOrAss = Guild:IsChieforAss()
		-- 		if (isChiefOrAss ~= 1) then
		-- 			NewBangHui_Hygl_BZTX_Tips:Hide()
		-- 		else
		-- 			NewBangHui_Hygl_BZTX_Tips:Show()
		-- 		end
		-- 	end
		-- else
		-- 	NewBangHui_Hygl_BZTX_Tips:Hide()
		-- end
	elseif ( event == "UI_COMMAND" ) then
		if(tonumber(arg0) == 31 and this:IsVisible()) then
			NewBangHui_Hygl_Closed();
		elseif(tonumber(arg0) == 30) then
			Guild:AskGuildMembersInfo();	--必须每次打开界面的时候都向服务器要数据
		end
	elseif (event == "GUILD_FORCE_CLOSE" ) then
		NewBangHui_Hygl_Closed();
	elseif (event == "GUILD_SELFEQUIP_CLICK") then
		Guild:AskGuildMembersInfo();	--必须每次打开界面的时候都向服务器要数据
	elseif ( event == "GUILD_ClOSE" ) then
		NewBangHui_Hygl_Closed();
	elseif ( event == "ACCELERATE_KEYSEND") then
		NewBangHui_Hygl_HandleAccKey(arg0);
	elseif( event == "GUILD_SHOW_DETAILINFO" ) then
        this:Hide()	--只Hide
	elseif (event == "GUILD_LEAGUE_INFO") then
		this:Hide()
	elseif (event == "ADJEST_UI_POS" ) then
		-- 游戏窗口尺寸发生了变化
		NewBangHui_Hygl_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewBangHui_Hygl_Frame_On_ResetPos()
	elseif ( event == "GUILDWAR_YXSSCHANGE" ) then
		this:Hide()
	elseif ( event == "ZHANTUAN_LIST_DATA" ) then
		this:Hide();
	elseif event == "GUILD_UPDATE_MEMBERINFO" then
		--准备数据
		Guild:PrepareMembersInfomation(g_MemberSortOrder);
		NewBangHui_Hygl_SelectTab(g_TabSel);
	elseif event == "GUILD_SHOW_ENEMYLIST" then
		this:Hide()
	elseif event == "OPEN_BUILD_INTRODUCE" then
		this:Hide()
	elseif event == "OPEN_GUILD_GIFT" then
		this:Hide()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "HYGL_ITEM_RIGHT_CLICKED" then
		local rowid = tonumber(arg0)
		NewBangHui_Hygl_Show_PopMenu(rowid)
	elseif (event == "SHOW_GUILDWAR_ANIMI" ) then
		local type = arg0;
		if (arg0 == "show") then
			NewBangHui_Hygl_Bhxz:SetText("#g0071BF#{BHJM_140520_04}")
			NewBangHui_Hygl_Bhxz:SetToolTip("你的帮会正在帮战");
		else
		    NewBangHui_Hygl_Bhxz:SetText("#{BHJM_140520_04}");
			NewBangHui_Hygl_Bhxz:SetToolTip("");
		end
	elseif (event == "GUILDWAR_REFLASHEP" ) then		-- 请求刷新装备评分 by wangbin
		NewBangHui_Hygl_Update();	--刷新列表
	elseif (event == "OPENMYALLIANCE") then
		this:Hide()
	elseif(event == "ONOPENBIEYEFURCREATE" and this:IsVisible()) then
		NewBangHui_Hygl_Closed()
	elseif event == "GUILD_BIDDING_SHOWLIST" then
		this:Hide()
	elseif event == "TCITYWARLIMIT_OPENCANDIDATE" then
		this:Hide()
	elseif event == "GUILD_ZHANTUAN_OP" then
		NewBangHui_Hygl_Closed()
	end

end



function NewBangHui_Hygl_Bhxz_Clicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition"), 1);
	City:OpenNewGuildWarDlg();
	Guild:CloseKickGuildBox();
	NewBangHui_Hygl_Hygl:SetCheck(1)
end

-- function NewBangHui_Hygl_SelectTab(idx)
	-- if(idx <= 0 or idx == nil or idx > 2) then
		-- return;
	-- end
	
	
	

	-- g_TabSel = idx;
	
	-- if g_TabSel == GUILD_MEMBERS_INFO then
		-- NewBangHui_Hygl_BHCYList:Show()
		-- NewBangHui_Hygl_SQJRList:Hide()
	-- end
	
	-- NewBangHui_Hygl_Update()
	
	
-- end


function NewBangHui_Hygl_Update()

	if(g_TabSel <= 0 or g_TabSel > 2) then
		return;
	end
	
	--自己帮会的宗旨
	local szMsg = Guild:GetMyGuildInfo("Desc");
	g_NewMembersCtl.desc:SetText(szMsg);
	
	
	--人数
	g_NewMembersCtl.count:SetText(Guild:GetMembersNum(3).."/"..Guild:GetMembersNum(1).."/"..Guild:GetMembersNum(2));

	g_ListToMember = {};
	local listidx = 0;
	local List;
	
	if (g_TabSel == GUILD_MEMBERS_INFO ) then
		List = NewBangHui_Hygl_BHCYList;
		List:RemoveAllItem();
		local totalNum = Guild:GetMembersNum(4);
		local i = 0;
		while i < totalNum do

			local guildIdx = Guild:GetShowMembersIdx(i);
			local color,strTips = Guild:GetMembersInfo(guildIdx, "ShowColor");
			szMsg = Guild:GetMembersInfo(guildIdx, "Name");
			local FirstManGuid = Guild:GetMembersInfo(guildIdx, "FirstManGuid");
			local tPos = Guild:GetMembersInfo(guildIdx, "Position")
			local level = Guild:GetMembersInfo(guildIdx, "Level")
			local nMenpai = Guild:GetMembersInfo(guildIdx, "MenPai")
			local nContriPerWeek = Guild:GetMembersInfo(guildIdx, "ContriPerWeek")
			local nEquipPoint = Guild:GetMembersInfo(guildIdx, "EquipPoint")
			
			if FirstManGuid == Guild:GetMembersInfo(guildIdx, "GUID") and tPos == g_AssChiefPos then
				List:AddNewItem("#P"..g_positionInfo[tPos], 0, listidx);
				List:AddNewItem("#P"..szMsg, 1, listidx);
				List:AddNewItem("#P"..level, 2, listidx);
				List:AddNewItem("#P"..g_menpaiInfo[nMenpai+1], 3, listidx);
				List:AddNewItem("#P"..nContriPerWeek, 4, listidx);
				List:AddNewItem("#P"..nEquipPoint, 5, listidx);
			else
				List:AddNewItem(color..g_positionInfo[tPos],0, listidx);
				List:AddNewItem(color..szMsg, 1, listidx);
				List:AddNewItem(color..level, 2, listidx);
				List:AddNewItem(color..g_menpaiInfo[nMenpai+1], 3, listidx);
				List:AddNewItem(color..nContriPerWeek, 4, listidx);
				List:AddNewItem(color..nEquipPoint, 5, listidx);
			end
			List:SetRowTooltip(listidx,strTips);
			g_ListToMember[listidx] = guildIdx;
			
			listidx = listidx + 1;
			i = i + 1;
		end
		NewBangHui_Hygl_BHCY_Xinxi_Text_lace:Show()
	elseif(g_TabSel == GUILD_REQUIRES_INFO) then
		List = NewBangHui_Hygl_SQJRList;
		List:RemoveAllItem();
		local totalNum = Guild:GetMembersNum(5);
		local i = 0;
		while i < totalNum do

			local guildIdx = Guild:GetShowTraineesIdx(i);
			local color,strTips = Guild:GetMembersInfo(guildIdx, "ShowColor");
			szMsg = Guild:GetMembersInfo(guildIdx, "Name");
			local szlevel = Guild:GetMembersInfo(guildIdx, "Level");
			local nMenpai = Guild:GetMembersInfo(guildIdx, "MenPai")
			local nEquipPoint = Guild:GetMembersInfo(guildIdx, "EquipPoint")
			local szId = Guild:GetMembersInfo(guildIdx, "GUID");
			szId = ConvertGuidToShow(szId)
			List:AddNewItem(color..szMsg.."("..szId..")",0,listidx)
			List:AddNewItem(color..szlevel,1,listidx)
			--List:AddNewItem(color..nEquipPoint,2,listidx)
			List:AddNewItem(color..g_menpaiInfo[nMenpai+1],2,listidx)
			List:AddNewItem(color..nEquipPoint,3,listidx)
			g_ListToMember[listidx] = guildIdx;

			listidx = listidx + 1;
			i = i + 1;
		end	

		NewBangHui_Hygl_BHCY_Xinxi_Text_lace:Hide()
	end
	
	NewBangHui_Hygl_JudgeSelectMember(List);
	if DataPool:Lua_IsPaoShangSvr() == 1 then
		NewBangHui_Hygl_LuXian_Button:Show()
	else
		NewBangHui_Hygl_LuXian_Button:Hide()
	end
end


function NewBangHui_Hygl_JudgeSelectMember(List)
	if ( g_MemberSel[g_TabSel] < 0 or nil == g_ListToMember[g_MemberSel[g_TabSel]]
		or g_MemberSel[g_TabSel] >= List:GetItemCount() ) then
		
		g_MemberSel[g_TabSel] = -1;

		
		if( nil ~= g_ListToMember[0] ) then
			List:SetSelectItem(0)
			NewBangHui_Hygl_Selected()
		end		
	else
		List:SetSelectItem(g_MemberSel[g_TabSel])
		NewBangHui_Hygl_Selected()
	end	
end

function NewBangHui_Hygl_Selected()
	
	local List;
	
	if g_TabSel == GUILD_MEMBERS_INFO then

		List = NewBangHui_Hygl_BHCYList;	
		g_MemberSel[g_TabSel] = List:GetSelectItem();
		NewBangHui_Hygl_SetMembersInfo(g_MemberSel[g_TabSel]);
	elseif g_TabSel == GUILD_REQUIRES_INFO then
		
		List = NewBangHui_Hygl_SQJRList;
		g_MemberSel[g_TabSel] = List:GetSelectItem();
	end
	local temp = NewBangHui_Hygl_BHCYList:GetSelectItem()
	
	
	
	-- PushDebugMessage("g_MemberSel[g_TabSel]="..g_MemberSel[g_TabSel] .. "temp="..temp)
	-- NewBangHui_Hygl_SetMembersInfo(g_MemberSel[g_TabSel]);
	Guild:CloseKickGuildBox();
end


function NewBangHui_Hygl_SetMembersInfo(lidx)
	if(lidx < 0 or lidx == nil) then
		return;
	end
	
	NewBangHui_Hygl_ClearInfo()
	
	--ID
	local szId = Guild:GetMembersInfo(g_ListToMember[lidx], "GUID");
	local szMsg = Guild:GetMembersInfo(g_ListToMember[lidx], "Name");
	local szIdText = ConvertGuidToShow(szId)
	
	g_NewMembersCtl.info[1].msg:SetText(szMsg)
	g_NewMembersCtl.info[2].msg:SetText(szIdText)	
	local  szMsg = Guild:GetMembersInfo(g_ListToMember[lidx], "CurCon").."/"..Guild:GetMembersInfo(g_ListToMember[lidx], "MaxCon")
	g_NewMembersCtl.info[3].msg:SetText(szMsg)
	
	if szId ~= Player:GetGUID() then
		g_NewMembersCtl.info[4].txt:SetToolTip("")
		g_NewMembersCtl.info[4].txt:SetText("#{INTERFACE_XML_577}")	
		g_NewMembersCtl.info[4].msg:SetText(Guild:GetMembersInfo(g_ListToMember[lidx], "JoinTime"))
		
		g_NewMembersCtl.info[5].txt:SetText("#{BHJM_140520_30}")	
		g_NewMembersCtl.info[5].msg:SetText(Guild:GetMembersInfo(g_ListToMember[lidx], "LastLoginTime"))
		
		g_NewMembersCtl.info[6].txt:SetText("")
		g_NewMembersCtl.info[6].msg:SetText("")
		
		g_NewMembersCtl.info[7].txt:SetText("")
		g_NewMembersCtl.info[7].msg:SetText("")
	else
		local nHaveToken = Player:LuaFnGetT3ShopToken()
		--g_NewMembersCtl.info[4].txt:SetToolTip("#{LDSD_200805_86}")
		g_NewMembersCtl.info[4].txt:SetText("#{LDSD_200805_85}")	
		g_NewMembersCtl.info[4].msg:SetText(tostring(nHaveToken))
		
		g_NewMembersCtl.info[5].txt:SetText("#{INTERFACE_XML_577}")	
		g_NewMembersCtl.info[5].msg:SetText(Guild:GetMembersInfo(g_ListToMember[lidx], "JoinTime"))
		
		g_NewMembersCtl.info[6].txt:SetText("#{BHJM_140520_30}")	
		g_NewMembersCtl.info[6].msg:SetText(Guild:GetMembersInfo(g_ListToMember[lidx], "LastLoginTime"))
		
		g_NewMembersCtl.info[7].txt:SetText("")
		g_NewMembersCtl.info[7].msg:SetText("")
	end
end

function NewBangHui_Hygl_ClearInfo()
	local i = 1;
	while g_NewMembersCtl.info[i] ~= nil do
		-- g_NewMembersCtl.info[i].txt:SetText("");
		g_NewMembersCtl.info[i].msg:SetText("");
		i=i+1;
	end
end


function NewBangHui_Hygl_Clear()
	g_NewMembersCtl.count:SetText("");

	
	g_ListToMember = nil;
	
	g_NewMembersCtl.desc:SetText("");
	g_NewMembersCtl.desc:Show();

	g_NewMembersCtl.edit:SetText("");
	g_NewMembersCtl.edit:SetProperty("CaratIndex", 1024);
	g_NewMembersCtl.edit:Hide();
end


function NewBangHui_Hygl_Closed()
	g_MemberSel[GUILD_REQUIRES_INFO] = -1;
	g_MemberSel[GUILD_MEMBERS_INFO] = -1;
	this:Hide();
end


function NewBangHui_Hygl_SearchMode_Changed()
	if not this:IsVisible() then
		return
	end
	
	local _, nIndex = g_NewMembersCtl.combo:GetCurrentSelect()
	
	g_MemberSortOrder = nIndex
    Guild:PrepareMembersInfomation(g_MemberSortOrder);	
	NewBangHui_Hygl_SelectTab(GUILD_MEMBERS_INFO);
	
end

function NewBangHui_Hygl_Bhxx_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:AskGuildDetailInfo();
	Guild:CloseKickGuildBox();	
end

function NewBangHui_Hygl_Tmxx_Clicked()
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
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition"), 1);
    GuildLeague:ShowInfoWindow()
end


function NewBangHui_Hygl_JZWJS_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ShowCityBuildIntroduce()
end

--帮会联赛 by wangbin
function NewBangHui_Hygl_BHLS_Clicked()
	local nCurTime = tonumber(DataPool:GetServerDayTime());
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID();
	if selfZoneWorldID == 9031 or selfZoneWorldID == 9015 then
		if ( nCurTime < g_MatchTestBeg_LM ) then
			PushDebugMessage( "#{BHKF_140909_419}" );
			NewBangHui_Hygl_Hygl:SetCheck(1);
			Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition"), 1);
			return
		end
	else
		if ( nCurTime < g_MatchTestBeginTime ) then
			PushDebugMessage( "#{BHKF_140909_419}" );
			NewBangHui_Hygl_Hygl:SetCheck(1);
			Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition"), 1);
			return
		end
	end
	
	local nStatus = ZhanTuanInterface:GetZhanTuanInfo();
	if(0 == tonumber(nStatus)) then
		NewBangHui_Hygl_Hygl:SetCheck(1)
	end
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition"), 1);
end

--快捷键
function NewBangHui_Hygl_HandleAccKey(op)
	if( op == "acc_guild") then
		if(this:IsVisible()) then
			NewBangHui_Hygl_Closed();
		else
			Guild:AskGuildMembersInfo();
		end
	end
end

function NewBangHui_Hygl_Frame_On_ResetPos()
	 NewBangHui_Hygl_Frame:SetProperty("UnifiedPosition", g_NewBangHui_Hygl_Frame_UnifiedPosition)
end

--拍卖
function NewBangHui_Hygl_Auction_Clicked()
  --if KaJi:LuaFnIsKaJiServer() == 1 then
  --	PushDebugMessage("#{SCBHPM_20220815_143}")
--	return
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
  Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition"), 1);
  Guild:AskGuildBiddingInfo(0, 1, -1)
end

function NewBangHui_Hygl_BZZT_Clicked()
	local selfzoneid = DataPool:GetSelfZoneWorldID()
	if (KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(181) > 0) or 
		DataPool:Lua_IsNewServerPlayerByZWID(selfzoneid) == 1 or
		Player:GetData("IsOriginalJD")  == 1 or
		Player:GetData("Is2606S")  == 1 or 
		Player:GetData("SPECKAJI89") > 0 then
	  PushDebugMessage("#{ZTXT_260511_151}")
	  return
	end
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("GUILD_ZHANTUAN_OP", 1)
end

function NewBangHui_Hygl_YXSS_Clicked()
  Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition"), 1);
  Guild:AskGuildYXSSInfo();
end

function NewBangHui_Hygl_BHCY_Button_Clicked()
	NewBangHui_Hygl_SelectTab(2)
end

function NewBangHui_Hygl_SQRB_Button_Clicked()
	NewBangHui_Hygl_SelectTab(1)
end

function NewBangHui_Hygl_SelectTab(idx)
	if(idx <= 0 or idx == nil or idx > 2) then
		return;
	end
	Guild:CloseKickGuildBox();
	NewBangHui_Hygl_SetTabColor(idx);
		--清空界面显示
	NewBangHui_Hygl_Clear();
	--开始更新界面
	if( Guild:GetMembersNum(5) == 0 ) then
		g_TabSel = 2;		--之所以要这样做是因为策划要求Tab2不能显示高亮状态
	end
	g_TabSel = idx;
	

	NewBangHui_Hygl_BtnSet();
	NewBangHui_Hygl_Update()	
	
	
end

function NewBangHui_Hygl_SetTabColor(idx)
	if(idx == nil or idx <= 0 or idx > 2) then
		return;
	end

	local i = 1;
	local selColor = "#e010101#Y";
	local noselColor = "#e010101";
	local tab = {
								NewBangHui_Hygl_SQRB_Button,
								NewBangHui_Hygl_BHCY_Button,
							};
	if( idx ==2 ) then
		if( Guild:GetMembersNum(5) == 0 ) then
				tab[1] : SetText( "#cbbbbbb" .. GUILD_MANAGE_TAB_TEXT[2]);
			else
				tab[1] : SetText( "#G" .. GUILD_MANAGE_TAB_TEXT[2]);
		end
	  tab[2] : SetText( noselColor..GUILD_MANAGE_TAB_TEXT[1] );
	else
		tab[2] : SetText( selColor..GUILD_MANAGE_TAB_TEXT[1] );
		if( Guild:GetMembersNum(5) == 0 ) then
			tab[1] : SetText( "#cbbbbbb" .. GUILD_MANAGE_TAB_TEXT[2]);
		else
			tab[1] : SetText( "#G" .. GUILD_MANAGE_TAB_TEXT[2]);
		end
	end
end

function NewBangHui_Hygl_BtnSet()
	if g_TabSel == GUILD_MEMBERS_INFO then
		NewBangHui_Hygl_BHCYList:Show()
		NewBangHui_Hygl_SQJRList:Hide()
		NewBangHui_Hygl_Frame3:Show()
		NewBangHui_Hygl_Frame4:Hide()
	elseif g_TabSel == GUILD_REQUIRES_INFO then
		NewBangHui_Hygl_BHCYList:Hide()
		NewBangHui_Hygl_SQJRList:Show()	
		NewBangHui_Hygl_Frame4:Show()
		NewBangHui_Hygl_Frame3:Hide()
	end
	
	local szPower = Guild:GetMyGuildPower(); --"1111111111" 这10个位置代表10种权力
	if(g_TabSel == GUILD_MEMBERS_INFO) then
		--职务调动权1
		NewBangHui_Hygl_BtnEnableDisable(szPower,1,1);
		--权限调整权2
		--开除帮众权4
		NewBangHui_Hygl_BtnEnableDisable(szPower,4,2);
		--禅让权5
		NewBangHui_Hygl_BtnEnableDisable(szPower,5,3);

		--修改帮会宗旨权10
		NewBangHui_Hygl_BtnEnableDisable(szPower,10,5);
	elseif(g_TabSel == GUILD_REQUIRES_INFO) then
		if( Guild:GetMembersNum(5) == 0 ) then --如果没有申请加入者
			if g_ShowMsgFlag == false then
				PushDebugMessage("本帮当前没有预备会员");
			else
				g_ShowMsgFlag = false;
			end
			g_TabSel = GUILD_MEMBERS_INFO;
			NewBangHui_Hygl_BtnSet(g_TabSel);
			g_NewMembersCtl[1] : Disable();
			NewBangHui_Hygl_SQRB_Button_Tips:Show()
			return;
		else
			g_NewMembersCtl[1] : Enable();
			g_NewMembersCtl[1] : SetToolTip("#{BHJM_140520_10}")
			NewBangHui_Hygl_SQRB_Button_Tips:Hide()
		end		
		--接收帮众权3
		NewBangHui_Hygl_BtnEnableDisable(szPower,3,9);
		NewBangHui_Hygl_BtnEnableDisable(szPower,3,10);
	end	
	
	if (Guild:GetMembersNum(5) == 0) then
		g_NewMembersCtl[1]:Disable();
		NewBangHui_Hygl_SQRB_Button_Tips:Show()
	else
		g_NewMembersCtl[1]:Enable();
		g_NewMembersCtl[1] : SetToolTip("#{BHJM_140520_10}")
		NewBangHui_Hygl_SQRB_Button_Tips:Hide()
	end
end

function NewBangHui_Hygl_Hygl_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ToggleGuildDetailInfo()
end

function NewBangHui_Hygl_ZDYSelf_Button_Clicked()
	if(g_TabSel < 0) then
		return;
	end

	Guild:CloseKickGuildBox();
	Guild:AskCurCustomPositionName()
end

function NewBangHui_Hygl_RenMing_Button_Clicked()
	if(g_TabSel < 0) then
		return;
	end

	Guild:CloseKickGuildBox();
	local iMember = g_ListToMember[g_MemberSel[g_TabSel]];
	if(nil ~= iMember) then		
		Guild:AskGuildAppointPosInfo(iMember);
	end
	
end

function NewBangHui_Hygl_ZhuChu_Button_Clicked()
	if(g_TabSel < 0) then
		return;
	end

	Guild:CloseKickGuildBox();
	local iMember = g_ListToMember[g_MemberSel[g_TabSel]];
	if(nil ~= iMember) then
		Guild:KickGuild(iMember);
	end
end


function NewBangHui_Hygl_ShanRang_Button_Clicked()
	if(g_TabSel < 0) then
		return;
end

	Guild:CloseKickGuildBox();
	Guild:DemisGuild();
end

function NewBangHui_Hygl_XiugaiZhongzhi_Button_Clicked()
	NewBangHui_Hygl_ChangeDesc();
end

-- 刷新装备评分 wangbin
function NewBangHui_Hygl_Tuichu_ShuaXin_Button_Clicked()
	--CD时间
	if not ShuaXin_PassTime(g_Seconds) then
		PushDebugMessage("#{ZYPT_081127_2}");
		return
	end
	Guild:ReflashEquipPoint();
end

function NewBangHui_Hygl_DingWei_Clicked()
	local totalNum = Guild:GetMembersNum(4);
	local i = 0;
	while i < totalNum do
		local guildIdx = Guild:GetShowMembersIdx(i);
		local guid = Guild:GetMembersInfo(guildIdx, "GUID");
		if(Player:GetGUID() == guid) then
			NewBangHui_Hygl_BHCYList:SetSelectItem(i)
			NewBangHui_Hygl_BHCYSelectChanged()
			NewBangHui_Hygl_BHCYList:SetVertScollPosition(i);
		end
		i = i + 1;
	end
end

function ShuaXin_PassTime(iSeconds)
   local iCur = FindFriendDataPool:GetTickCount()
   if ( iCur - g_Timers < iSeconds * 1000) then
      return false;
   else
      g_Timers = iCur;
   	  return true;
   end
end

function NewBangHui_Hygl_ChangeDesc()
	if(g_NewMembersCtl.edit:IsVisible()) then
		NewBangHui_Hygl_ChangeDescFin();
	elseif(g_NewMembersCtl.desc:IsVisible()) then
		NewBangHui_Hygl_ChangeDescBegin();
	end
end

function NewBangHui_Hygl_ChangeDescFin()
	local szMsg = g_NewMembersCtl.edit:GetText();
	g_NewMembersCtl.edit:SetProperty("DefaultEditBox", "False");
	g_NewMembersCtl.edit:Hide();


	g_NewMembersCtl.desc:Show();

	Guild:FixGuildInfo("Desc", szMsg);
	NewBangHui_Hygl_XiugaiZhongzhi_Button:SetText("#{BHJM_140520_06}");
end

function NewBangHui_Hygl_ChangeDescBegin()
	--如果没输入过二级密码则输入一次，注意：Player:IsLocked() == 0表示锁定
	if CheckPhoneMibaoAndMinorPassword() == 0 then
		return
	end

	local szMsg = Guild:GetMyGuildInfo("Desc");

	g_NewMembersCtl.edit:SetText(szMsg);
	g_NewMembersCtl.edit:SetProperty("CaratIndex", 1024);
	g_NewMembersCtl.edit:SetProperty("DefaultEditBox", "True");
	g_NewMembersCtl.edit:Show();

	g_NewMembersCtl.desc:Hide();
	NewBangHui_Hygl_XiugaiZhongzhi_Button:SetText("修改完成");
end


function NewBangHui_Hygl_JieShou_Button_Clicked()
	if(g_TabSel < 0) then
		return;
	end

	Guild:CloseKickGuildBox();
	local iMember = g_ListToMember[g_MemberSel[g_TabSel]];
	if iMember ~= nil then
		Guild:RecruitGuild(iMember);
		g_ShowMsgFlag = true;
	end
end

function NewBangHui_Hygl_Jujue_Button_Clicked()
	if(g_TabSel < 0) then
		return;
	end

	Guild:CloseKickGuildBox();
	local iMember = g_ListToMember[g_MemberSel[g_TabSel]];
	if iMember ~= nil then
		Guild:KickGuild(iMember);
		g_ShowMsgFlag = true;
	end
end

function NewBangHui_Hygl_Tuichu_Button_Clicked()
	Guild:QuitGuild();
end

function NewBangHui_Hygl_BtnEnableDisable(szPower, szidx, btnidx)
	local iPower = string.byte(szPower,szidx);
	if(iPower == 48) then			--'0'
		g_NewMembersCtl.btn[btnidx]:Disable();
	elseif(iPower == 49) then  --'1'
		g_NewMembersCtl.btn[btnidx]:Enable();
	end
end

function NewBangHui_Hygl_BHCYSelectChanged()
	g_MemberSel[g_TabSel] = NewBangHui_Hygl_BHCYList:GetSelectItem();
	NewBangHui_Hygl_SetMembersInfo(g_MemberSel[g_TabSel])
	Guild:CloseKickGuildBox();
end

function NewBangHui_Hygl_SQJRSelectChanged()
	g_MemberSel[g_TabSel] = NewBangHui_Hygl_SQJRList:GetSelectItem();
	-- NewBangHui_Hygl_SetMembersInfo(g_MemberSel[g_TabSel])
	Guild:CloseKickGuildBox();
end

function NewBangHui_Hygl_Show_PopMenu(rowid)
	local index = -1;
	if (g_TabSel == GUILD_MEMBERS_INFO) then
		NewBangHui_Hygl_BHCYList:SetSelectItem(rowid)
		NewBangHui_Hygl_BHCYSelectChanged()
		index = NewBangHui_Hygl_BHCYList:GetSelectItem();
	elseif ( g_TabSel == GUILD_REQUIRES_INFO ) then
		NewBangHui_Hygl_SQJRList:SetSelectItem(rowid)
		NewBangHui_Hygl_SQJRSelectChanged()
		index = NewBangHui_Hygl_SQJRList:GetSelectItem();
	end
	if( index > -1 ) then
		if(g_TabSel>0 and g_TabSel<3)then
			Guild:Show_PopMemu(tonumber(index),tonumber(g_TabSel));
		end
	end	
end

function NewBangHui_Hygl_SetDynamic_Pos()
    local selfGuildClanUnionPos = Variable:GetVariable("SelfGuildClanUnionPos")
	if( selfGuildClanUnionPos ~= nil) then
	    NewBangHui_Hygl_Frame:SetProperty("UnifiedPosition", selfGuildClanUnionPos )
	end
end
function NewBangHui_Hygl_SetTitle()
	local szName = Guild:GetMyGuildName("Name");
	local title = ScriptGlobal_Format("#{BHJM_140520_01}", szName)
	NewBangHui_Hygl_PageHeader:SetText(title)
end

function NewBangHui_Hygl_KVKLeague_Clicked()
	local alliancemark = 0;
end

function NewBangHui_Hygl_HB_OnClicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition"), 1)
	Guild:OpentGuildGiftUI()
end

function NewBangHui_Hygl_BZTX_Clicked()
	-- if (Player:GetData("TCWLSvrOpenFlag") < 0) then
	-- 	NewBangHui_Hygl_BZTX:SetCheck(0)
	-- 	NewBangHui_Hygl_Hygl:SetCheck(1)

	-- 	PushDebugMessage("#{GCQH_240429_161}")
	-- elseif (Player:GetData("TCWLSvrOpenFlag") == 0) then
	-- 	NewBangHui_Hygl_BZTX:SetCheck(0)
	-- 	NewBangHui_Hygl_Hygl:SetCheck(1)

	-- 	PushDebugMessage("#{GCQH_240429_154}")
	-- else
	-- 	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Hygl_Frame:GetProperty("UnifiedPosition"), 1)
	-- 	Guild:TCWLOpenLCandidateUI()
	-- end
end -- end func NewBangHui_Hygl_BZTX_Clicked()

--*****************************************************************************
-- 城战轮换（霸者天下）是否在助战申请时间内
--*****************************************************************************
function NewBangHui_Hygl_Check_BZTXAssistEnrollTime()
	local curWeekDay = DataPool:GetServerWeekDay()
	if (curWeekDay == 0) then
		-- 星期天特殊处理一下
		curWeekDay = 7
	end

	local beginDay = NewBangHui_Hygl_AssistOpTime[1].weekday
	local beginTime = NewBangHui_Hygl_AssistOpTime[1].begintime
	local endDay = NewBangHui_Hygl_AssistOpTime[2].weekday
	local endTime = NewBangHui_Hygl_AssistOpTime[2].endtime

	if (curWeekDay >= beginDay and curWeekDay <= endDay) then
		local curMinTime = DataPool:GetServerMinuteTime()
		if (curWeekDay == beginDay) then
			if (curMinTime >= beginTime) then
				return 1
			else
				return -1
			end
		elseif (curWeekDay == endDay) then
			if (curMinTime < endTime) then
				return 1
			else
				return -1
			end
		else
			return 1
		end
	end

    return -1
end -- end func NewBangHui_Hygl_Check_BZTXAssistEnrollTime()


function NewBangHui_Hygl_DoCommerceNet()
	City:AskCityRoad(1);
end
