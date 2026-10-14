
local g_NewMembersCtl = {};
local g_TabSel = -1;
local g_ListToMember;
local g_MemberSel = {};
local g_Position = 3;
--local g_Yuanbao = 0;
--local g_AddYuanbao = 0;
local g_ZTLGUID = "";
local g_ZTLPosition = -1;
local g_MemberSortOrder = 1;   --排序方式
local g_Timers = 0;
local g_Seconds = 2;
local g_Seconds5 = 5;
local g_MAX_DUANWEI = 10;
local g_MAX_ZhanQiLevel = 9;
local g_GuildPosition = 0;
local g_MAX_ALL_TUANZHAN_COUNT = 260;
local g_ZCYuanBao_Button_PH = 0

local g_guildpositionInfo = {
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

local g_duanweiInfo = {
	"#{BHKF_140909_394}",
	"#{BHKF_140909_393}",
	"#{BHKF_140909_392}",
	"#{BHKF_140909_391}",
	"#{BHKF_140909_390}",
	"#{BHKF_140909_389}",
	"#{BHKF_140909_388}",
	"#{BHKF_140909_387}",
	"#{BHKF_140909_386}",
	"#{BHKF_140909_385}",
};

local g_positionInfo = {
	"团长",
	"统帅",
	"成员",
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
local g_ZhanqiName = {
	"玄素",
	"玄武",
	"朱雀",
	"白虎",
	"青龙"
};

local g_SelZhanQi =0;
----------帮会团战类型Start----------
local ZT_GET_ZHANTUAN			= 0;				-- 获取列表
local ZT_ZHANTUAN_CREATE		= 1;				-- 创建
local ZT_ZHANTUAN_QUIT			= 2;				-- 解散
local ZT_APPOINT				= 3;				-- 任命
local ZT_ADD_USER				= 4;				-- 添加
local ZT_DELETE_USER			= 5;				-- 移出
--local ZT_SAVE_YUANBAO			= 6;				-- 战场元宝储备
--local ZT_GET_YUANBAO			= 7;				-- 战场元宝取出
--local ZT_SAVE_YUANBAO_TO_WORLD	= 8;				-- 战场元宝储备去World上先进行判断
----------帮会团战类型End----------
-------帮会团战职位类型Start-------
local ZT_POS_TUANZHANG 			= 1;				--团长
local ZT_POS_FUTUANZHANG 		= 2;				--副团长
local ZT_POS_MEMBER	 			= 3;				--成员
-------帮会团战职位类型End----------

local g_MatchTestBeginTime = 20141215			-- [帮会跨服测试赛]期间屏蔽
local g_MatchTestEndTime = 20141228

local g_MatchTestBeg_LM	= 20141128
local g_MatchTestEnd_LM = 20141204

function NewBangHui_Bhls_PreLoad()

	this:RegisterEvent("ZHANTUAN_LIST_DATA");
	this:RegisterEvent("ZHANTUAN_UPDATE_DATA");

	this:RegisterEvent("GUILD_SHOW_DETAILINFO");
	this:RegisterEvent("GUILD_LEAGUE_INFO");
	this:RegisterEvent("GUILDWAR_YXSSCHANGE");
	this:RegisterEvent("GUILD_SHOW_ENEMYLIST");
	this:RegisterEvent("OPEN_BUILD_INTRODUCE");--打开帮会建筑物介绍
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("GUILD_SHOW_MEMBERINFO");
	this:RegisterEvent("BHZT_ITEM_RIGHT_CLICKED");
	this:RegisterEvent("GUILD_FORCE_CLOSE");
	this:RegisterEvent("ZHANTUAN_UPDATE_ZHANQIDATA");
	this:RegisterEvent("UPDATE_YUANBAO");
	this:RegisterEvent("SHOW_GUILDWAR_ANIMI");
	this:RegisterEvent("OPENMYALLIANCE");
	this:RegisterEvent("OPEN_GUILD_GIFT")
end


function NewBangHui_Bhls_OnLoad()

	--wangbin
	NewBangHui_Bhls_List:AddTextItem("#{BHKF_140909_355}" ,1)						--默认：
	NewBangHui_Bhls_List:AddTextItem("#{BHKF_140909_356}" ,2)				--等级从高到低
	NewBangHui_Bhls_List:AddTextItem("#{BHKF_140909_357}" ,3)				--等级从低到高
	NewBangHui_Bhls_List:AddTextItem("#{BHKF_140909_358}" ,4)			--装备评分从高到低
	NewBangHui_Bhls_List:AddTextItem("#{BHKF_140909_359}" ,5)			--装备评分从低到高
	NewBangHui_Bhls_List:SetCurrentSelect(0);


	g_NewMembersCtl = {
						-- list = NewBangHui_Hygl_SQJRList,
						--header = NewBangHui_Bhls_PageHeader,
						--info = {
						--					--{txt = "", msg = NewBangHui_Bhls_WarInfo_Info_Frame_Name,},
						--					{txt = "", msg = NewBangHui_Bhls_WarInfo_Info_Frame_Fight,},
						--					{txt = "", msg = NewBangHui_Bhls_WarInfo_Info_Frame_Num,},
						--					{txt = "", msg = NewBangHui_Bhls_WarInfo_Info_Frame_Level,},
						--					{txt = "", msg = NewBangHui_Bhls_WarInfo_Info_Frame_Score,},
						--					{txt = "", msg = NewBangHui_Bhls_WarInfo_Info_Frame_Up,},
						--					{txt = "", msg = NewBangHui_Bhls_WarInfo_Info_Frame_Down,},
						--					{txt = "", msg = NewBangHui_Bhls_WarInfo_Info_Frame_Result,},
                        --
						--					--{txt = "", msg = NewBangHui_Bhls_GoodsInfo_Info_Frame_Goods,},
						--					--{txt = "", msg = NewBangHui_Bhls_GoodsInfo_Info_Frame_Have,},
						--					{txt = "", msg = NewBangHui_Bhls_Num,},
                        --
						--			 },
					--NewBangHui_Bhls_War_Button,
					--NewBangHui_Bhls_Flag_Button,
						combo = NewBangHui_Bhls_List,
						combodesc = NewBangHui_Bhls_ListText,
					 };

end


function NewBangHui_Bhls_OnEvent(event)

	if ( event == "ZHANTUAN_LIST_DATA" ) then
		if(arg0 == "0") then
			--PushDebugMessage("NewBangHui_Bhls_InitClick...");
			NewBangHui_Bhls_SetDynamic_Pos();
			NewBangHui_Bhls_Update();
			this:Show();
		elseif(arg0 == "1") then
			NewBangHui_Bhls_InitClick();
			--local nTZID = ZhanTuanInterface:GetLocalZhanTuanInfo("TZID");
			--PushDebugMessage("NewBangHui_Bhls_OnEvent...TZID:"..nTZID);
			ZhanTuanInterface:GetMenberOrder(g_MemberSortOrder);
		end
	elseif ( event == "ZHANTUAN_UPDATE_DATA" ) then
		NewBangHui_Bhls_ZhanTuan_Update()
	elseif( event == "GUILD_SHOW_DETAILINFO" ) then
        this:Hide()
	elseif (event == "GUILD_LEAGUE_INFO") then
		this:Hide()
	elseif ( event == "GUILDWAR_YXSSCHANGE" ) then
		this:Hide()
	elseif event == "GUILD_SHOW_ENEMYLIST" then
		this:Hide()
	elseif event == "OPEN_BUILD_INTRODUCE" then
		this:Hide()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		--NewBangHui_Bhls_StoreBottom_Input:SetText("")
		this:Hide()
	elseif (event == "GUILD_SHOW_MEMBERINFO") then
		this:Hide()
	elseif event == "BHZT_ITEM_RIGHT_CLICKED" then
		NewBangHui_Bhls_Show_PopMenu()
	elseif ( event == "GUILD_FORCE_CLOSE" ) then
		NewBangHui_Bhls_Closed()
	elseif( event == "SHOW_GUILDWAR_ANIMI" ) then	--帮战改变“帮会宣战”文字颜色 使用播放帮战动画的事件，如果以后这个显示和帮战动画不同步，那么需要建立新的事件。
		local type = arg0;
		if (arg0 == "show") then
			NewBangHui_Bhls_Bhxz:SetText("#g0071BF#{BHJM_140520_04}")
			NewBangHui_Bhls_Bhxz:SetToolTip("你的帮会正在帮战");
		else
		    NewBangHui_Bhls_Bhxz:SetText("#{BHJM_140520_04}");
			NewBangHui_Bhls_Bhxz:SetToolTip("");
		end
	elseif ( event == "ZHANTUAN_UPDATE_ZHANQIDATA" ) then
		NewBangHui_Bhls_Update();
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		if ZhanTuanInterface:IsFinalCompetitor() >= 1 then
			local YuanBao	= Player:GetData("YUANBAO")
			NewBangHui_Bhls_WarInfo_Info_Frame_YYyuanbao:SetText(tostring(YuanBao))
		end
	elseif event == "OPENMYALLIANCE" then
		NewBangHui_Bhls_Closed()
	elseif (event == "OPEN_GUILD_GIFT" ) then
		NewBangHui_Bhls_Closed()
	end
end

--初始化按钮
function NewBangHui_Bhls_InitClick()

	--local myPos = Guild:GetMyPosition();
	--PushDebugMessage(myPos.."NewBangHui_Bhls_InitClick..."..g_Position);
	g_GuildPosition = Guild:IsChieforAss();

	NewBangHui_Bhls_Appoint_Button:Disable();
	NewBangHui_Bhls_Add_Button:Disable();
	NewBangHui_Bhls_Remove_Button:Disable();
	if g_GuildPosition == 1 then				-- 帮主、副帮主
		NewBangHui_Bhls_Appoint_Button:Enable();
		NewBangHui_Bhls_Add_Button:Enable();
		NewBangHui_Bhls_Remove_Button:Enable();
	elseif(2 == g_Position) then	-- 副团长
		NewBangHui_Bhls_Add_Button:Enable();
	end

	--g_Yuanbao = 0;
	--g_Yuanbao = Player:GetData("YUANBAO");
	NewBangHui_Bhls_SetTitle();
	NewBangHui_Bhls_Bhls:SetCheck(1)
	g_MemberSortOrder = 1;
	NewBangHui_Bhls_SelectTab(1)
	NewBangHui_Bhls_War_Button:SetText("#G".."#{BHKF_140909_42}");
	NewBangHui_Bhls_Flag_Button:SetText("#{BHKF_140909_43}");
	NewBangHui_Bhls_Help_Button:SetText("#{TFJM_141201_1}");
	
	--NewBangHui_Bhls_GoodsInfo_Bottom_EditBox:SetText("");
	if ( SystemSetup:IsClassic() == 0 ) then	-- 唯美
		NewBangHui_Bhls_WarClient_BK:Show()
		NewBangHui_Bhls_WarClient:Show()
		NewBangHui_Bhls_FlagClient_BK:Hide()
		NewBangHui_Bhls_FlagClient:Hide()
		NewBangHui_Bhls_HelpClient:Hide();
	end
end

function NewBangHui_Bhls_Update()

	g_ListToMember = {};
	local listidx = 0;
	local nOnlineCount = 0;
	local nAllEquipPoint = 0;
	local nWinCount = 0;
	local nAllCount = 0;
	local nProbability = 0;
	local nTZID = 0;
	local strTZDuanWei = 0;
	local nTZDuanWei = 0;
	local nTZDuanWeiSuccess = 0;
	local nTZDuanWeiFail = 0;
	local nTZDuanWeiGrow = 0;
	local nRanking = 0;
	--local nZhanChangYuanbao = 0;
	local List;
	local aSDuanWei = {1,1,1,1,1,1,2,2,2,3};	-- 胜利
	local aFDuanWei = {1,2,2,2,2,2,3,3,3,3};	-- 失败

	if (1 == g_TabSel ) then			-- wangbin
		NewBangHui_Bhls_List_Frame:Show();
		List = NewBangHui_Bhls_WarList;
		List:RemoveAllItem();
		local i = 0;
		local nZTLGUID = "";
		nTZID = ZhanTuanInterface:GetLocalZhanTuanInfo("TZID");
		local nTZIsvalid = ZhanTuanInterface:GetLocalZhanTuanInfo("TZIsvalid");
		
		--local nTZName = ZhanTuanInterface:GetLocalZhanTuanInfo("TZName");
		nTZDuanWei = ZhanTuanInterface:GetLocalZhanTuanInfo("TZDuanWei");
		if(nTZDuanWei>g_MAX_DUANWEI) then
			nTZDuanWei = g_MAX_DUANWEI;
		end
		nTZDuanWeiSuccess = ZhanTuanInterface:GetLocalZhanTuanInfo("TZDuanWeiSuccess");
		nTZDuanWeiFail = ZhanTuanInterface:GetLocalZhanTuanInfo("TZDuanWeiFail");
		nTZDuanWeiGrow = ZhanTuanInterface:GetLocalZhanTuanInfo("TZDuanWeiGrow");
		nRanking = ZhanTuanInterface:GetLocalZhanTuanInfo("Rank");
		--当前帮会战团在本赛季的胜利场数
		nWinCount = ZhanTuanInterface:GetLocalZhanTuanInfo("WinCount");
		--当前帮会战团在本赛季的总场数
		nAllCount = ZhanTuanInterface:GetLocalZhanTuanInfo("AllCount");
		if(0 < nAllCount) then
			nProbability = math.floor(nWinCount/nAllCount*100);
		end
		--if("" == nTZName) then
		--	nTZName = "#{BHKF_140909_328}";
		--end
		--g_NewMembersCtl.info[1].msg:SetText(nTZName);
		if(0 < nTZIsvalid) then
			NewBangHui_Bhls_Build_Button:Hide();
		else
			NewBangHui_Bhls_Build_Button:Show();
		end
		--g_NewMembersCtl.info[2].msg:SetText(nTZID);
		--local totalNum = Guild:GetMembersNum(4);
		g_Position = 3;
		while i < g_MAX_ALL_TUANZHAN_COUNT do
			local nZTLGUID = ZhanTuanInterface:GetMembersInfo(i, "ZTLGUID");
			if ("" == nZTLGUID) then
				i = i + 1;
				continue
			end

			local color = "#cC1C087";
			local nZTLPosition = ZhanTuanInterface:GetMembersInfo(i, "ZTLPosition")
			local nZTLName = ZhanTuanInterface:GetMembersInfo(i, "ZTLName")
			local nZTLLevel = ZhanTuanInterface:GetMembersInfo(i, "ZTLLevel")
			local nZTLMenpai = ZhanTuanInterface:GetMembersInfo(i, "ZTLMenpai")
			local nZTLEquipPoint = ZhanTuanInterface:GetMembersInfo(i, "ZTLEquipPoint")
			--local nZTLYuanbao = ZhanTuanInterface:GetMembersInfo(i, "ZTLYuanbao")
			local nZTLIsvalid = ZhanTuanInterface:GetMembersInfo(i, "ZTLIsvalid")
			local nIsOnline = ZhanTuanInterface:GetMembersInfo(i, "IsOnline") -- 是否在线

			if(nZTLIsvalid ~= 0 and nZTLName ~= "") then
				--local nGuildIndex = Guild:GetMemInfoIndexByGUID(nZTLGUID)	--帮会的Index
				--if(nGuildIndex == -1) then
				--	i = i + 1;
				--	continue
				--end
				--local color1,strTips = Guild:GetMembersInfo(nGuildIndex, "ShowColor");
				if(0 < nIsOnline) then
					color = "#W";
				end
				-- 当前用户的职位
				if(Player:GetGUID() == nZTLGUID) then
					g_Position = nZTLPosition;
					--nZhanChangYuanbao = nZTLYuanbao;
				end
				nAllEquipPoint = nAllEquipPoint + nZTLEquipPoint;
				if(0 < nIsOnline) then
					nOnlineCount = nOnlineCount + 1;
					if(ZT_POS_FUTUANZHANG == nZTLPosition) then
						color = "#cCDA76E";
					end
				else	-- 离线
					if(ZT_POS_FUTUANZHANG == nZTLPosition) then
						color = "#cC1C087";
					end
				end
				List:AddNewItem(color..g_positionInfo[nZTLPosition], 0, listidx);
				List:AddNewItem(color..nZTLName, 1, listidx);
				List:AddNewItem(color..nZTLLevel, 2, listidx);
				List:AddNewItem(color..g_menpaiInfo[nZTLMenpai+1], 3, listidx);
				List:AddNewItem(color..nZTLEquipPoint, 4, listidx);
				--List:AddNewItem(color..nZTLYuanbao, 5, listidx);
				--List:SetRowTooltip(listidx,strTips);
				g_ListToMember[listidx] = i;
				listidx = listidx + 1;
			end
			i = i + 1;
		end
		List:SetSelectItem(0)
		local strZhanTuanCount = ScriptGlobal_Format("#{BHKF_140909_63}", tostring(nOnlineCount), tostring(listidx), "40");
		NewBangHui_Bhls_Num:SetText(strZhanTuanCount);
		NewBangHui_Bhls_Num:Show();
	elseif(2 == g_TabSel) then
		NewBangHui_Bhls_List_Frame:Show();
		NewBangHui_Bhls_Num:Hide();
		List = NewBangHui_Bhls_FlagList;
		List:RemoveAllItem();
		local totalNum = Guild:GetMembersNum(4);
		local i = 0;
		while i < totalNum do

			local guildIdx = Guild:GetShowMembersIdx(i);
			local szMsg = Guild:GetMembersInfo(guildIdx, "Name");
			local tPos = Guild:GetMembersInfo(guildIdx, "Position")
			local level = Guild:GetMembersInfo(guildIdx, "Level")
			local nItemcount = Guild:GetMembersInfo(guildIdx, "itemcount")
			local nItemWeekcount = Guild:GetMembersInfo(guildIdx, "itemWeekcount")
			local color,strTips = Guild:GetMembersInfo(guildIdx, "ShowColor");
			if level >= 85 then
				List:AddNewItem(color..g_guildpositionInfo[tPos], 0, listidx);
				List:AddNewItem(color..szMsg, 1, listidx);
				List:AddNewItem(color..level, 2, listidx);
				List:AddNewItem(color..nItemWeekcount, 3, listidx);
				List:AddNewItem(color..nItemcount, 4, listidx);
				List:SetRowTooltip(listidx,strTips);
				g_ListToMember[listidx] = guildIdx;
				listidx = listidx + 1;
			end
			i = i + 1;
		end
  
		--PushDebugMessage("NewBangHui_Bhls_Update")
		NewBangHui_Bhls_RefreshZhanQi() -- 刷新战旗界面
		--if (0 == nZhanQiYCZAll) then
		--	NewBangHui_Bhls_FlagInfo_Info_Frame_Pro:Hide();
		--	NewBangHui_Bhls_FlagInfo_Info_Frame_Text:Hide();
		--elseif (5 == nZhanQiLevel) then
		--	NewBangHui_Bhls_FlagInfo_Info_Frame_Pro:Hide();
		--	NewBangHui_Bhls_FlagInfo_Info_Frame_Text:Show();
		--else
		--	NewBangHui_Bhls_FlagInfo_Info_Frame_Pro:Show();
		--	NewBangHui_Bhls_FlagInfo_Info_Frame_Pro:SetText(strZhanQiYCZ);
		--	NewBangHui_Bhls_FlagInfo_Info_Frame_Text:Hide();
		--end
	elseif(3 == g_TabSel) then
		NewBangHui_Bhls_Num:Hide(); 
		NewBangHui_Bhls_List_Frame:Hide();
	end

	NewBangHui_Bhls_WarInfo_Info_Frame_Fight:SetText(nAllEquipPoint);
	if(0 == nRanking) then
		nRanking = "#{BHKF_140909_59}";
	end
	NewBangHui_Bhls_WarInfo_Info_Frame_Num:SetText(tostring(nRanking));
	if(0 >= nTZDuanWei) then
		strTZDuanWei = "#{BHKF_140909_342}";
	else
		strTZDuanWei = g_duanweiInfo[nTZDuanWei];
	end
	NewBangHui_Bhls_WarInfo_Info_Frame_Level:SetText(tostring(strTZDuanWei));
	NewBangHui_Bhls_WarInfo_Info_Frame_Score:SetText(tostring(nTZDuanWeiGrow));
	if(0 < nTZDuanWei and nTZDuanWei <= g_MAX_DUANWEI) then
		local szWarInfoUp = ScriptGlobal_Format("#{BHKF_140909_421}", tostring(nTZDuanWeiSuccess), tostring(aSDuanWei[nTZDuanWei]));
		NewBangHui_Bhls_WarInfo_Info_Frame_Up:SetText(szWarInfoUp);
		local szWarInfoDown = ScriptGlobal_Format("#{BHKF_140909_421}", tostring(nTZDuanWeiFail), tostring(aFDuanWei[nTZDuanWei]));
		NewBangHui_Bhls_WarInfo_Info_Frame_Down:SetText(szWarInfoDown);
		--NewBangHui_Bhls_WarInfo_Info_Frame_Up:SetProperty("Image", "set:Bhls_Mark image:Bhls_Mark_Up_"..nTZDuanWei.."_"..nTZDuanWeiSuccess);
	end
	
	local szTextWarInfoDown = ScriptGlobal_Format("#{BHKF_140909_410}", tostring(strTZDuanWei), tostring(aFDuanWei[nTZDuanWei]), tostring(nTZDuanWeiFail));
	if(nTZDuanWei < g_MAX_DUANWEI) then
		--NewBangHui_Bhls_WarInfo_Info_Frame_Up:SetProperty("Tooltip", "");
		local szTextWarInfoUp = ScriptGlobal_Format("#{BHKF_140909_408}", tostring(strTZDuanWei), tostring(aSDuanWei[nTZDuanWei]), tostring(nTZDuanWeiSuccess));
		NewBangHui_Bhls_WarInfo_Info_Frame_UpText:SetToolTip(szTextWarInfoUp)
		NewBangHui_Bhls_WarInfo_Info_Frame_DownText:SetToolTip(szTextWarInfoDown)
	elseif(nTZDuanWei == g_MAX_DUANWEI) then
		--NewBangHui_Bhls_WarInfo_Info_Frame_Up:SetToolTip("#{BHKF_140909_368}")
		NewBangHui_Bhls_WarInfo_Info_Frame_UpText:SetToolTip("#{BHKF_140909_409}")
		NewBangHui_Bhls_WarInfo_Info_Frame_Up:SetText("#{BHKF_140909_377}");
		NewBangHui_Bhls_WarInfo_Info_Frame_DownText:SetToolTip(szTextWarInfoDown)
	end
	
	--帮会申请参战后，即可通过获取比赛一定数量的比赛胜利提升帮会段位，在相应段位失利一定数量的比赛后，帮会段位将会降低.
	if(1 == g_TabSel and 0 == nTZID) then
		NewBangHui_Bhls_WarInfo_Info_Frame_Up:SetText("");
		NewBangHui_Bhls_WarInfo_Info_Frame_Down:SetText("");
		NewBangHui_Bhls_WarInfo_Info_Frame_UpText:SetToolTip("#{BHKF_140909_433}")
		NewBangHui_Bhls_WarInfo_Info_Frame_DownText:SetToolTip("#{BHKF_140909_434}")
	end

	if(1 == nTZDuanWei) then
		NewBangHui_Bhls_WarInfo_Info_Frame_DownText:SetToolTip("#{BHKF_140909_411}")
		NewBangHui_Bhls_WarInfo_Info_Frame_Down:SetText("#{BHKF_140909_412}");
	end
	--if(0 < nTZDuanWei and nTZDuanWei <= g_MAX_DUANWEI) then
	--	--NewBangHui_Bhls_WarInfo_Info_Frame_Down:SetProperty("Image", "set:Bhls_Mark image:Bhls_Mark_Down_"..nTZDuanWei.."_"..nTZDuanWeiFail);
	--end
	local tmpTZScore = ScriptGlobal_Format("#{BHKF_140909_61}", tostring(nWinCount), tostring(nAllCount), tostring(nProbability).."%");
	NewBangHui_Bhls_WarInfo_Info_Frame_Result:SetText(tmpTZScore);
	
	--if ZhanTuanInterface:IsFinalCompetitor() >= 1 then
		--local ZCYuanBao = ZhanTuanInterface:GetZCYuanBaoAmount() 
		--NewBangHui_Bhls_WarInfo_Info_Frame_ZCyuanbao:SetText(tostring(ZCYuanBao))
		--local YuanBao	= Player:GetData("YUANBAO")
		--NewBangHui_Bhls_WarInfo_Info_Frame_YYyuanbao:SetText(tostring(YuanBao))

		--NewBangHui_Bhls_WarInfo_Info_Frame1:Show()
		--NewBangHui_Bhls_StoreBottom:Show()
		--NewBangHui_Bhls_WarInfo_Yuanbao_Frame:Show()
	--else
		NewBangHui_Bhls_WarInfo_Info_Frame1:Hide()
		NewBangHui_Bhls_StoreBottom:Hide()
		NewBangHui_Bhls_WarInfo_Yuanbao_Frame:Hide()
	--end
	

	--local tmpZTLYuanbao = ScriptGlobal_Format("#{BHKF_140909_71}", tostring(nZhanChangYuanbao));
	--g_NewMembersCtl.info[9].msg:SetText(tmpZTLYuanbao);
	--local strYuanBao = ScriptGlobal_Format("#{BHKF_140909_73}", g_Yuanbao);
	--g_NewMembersCtl.info[10].msg:SetText(strYuanBao);


end

-- 排序方式
function NewBangHui_Bhls_List_Changed()

	if not this:IsVisible() then
		return
	end

	local _, nIndex = g_NewMembersCtl.combo:GetCurrentSelect();

	g_MemberSortOrder = nIndex;
	--PushDebugMessage("排序方式..."..g_MemberSortOrder);

	if(1 == g_TabSel) then
		ZhanTuanInterface:GetMenberOrder(g_MemberSortOrder);
	elseif(2 == g_TabSel) then
		Guild:PrepareMembersInfomation(nIndex);
		NewBangHui_Bhls_FlagClient:Show();
		NewBangHui_Bhls_WarClient:Hide();
		NewBangHui_Bhls_Update();
		return;
	end

end

function NewBangHui_Bhls_SelectChanged()
	local listidx = NewBangHui_Bhls_WarList:GetSelectItem();
	if g_ListToMember[listidx] == nil then
		--PushDebugMessage("......."..g_ZTLGUID);
		g_ZTLGUID = "";
		return
	end
	g_ZTLGUID = ZhanTuanInterface:GetMembersInfo(g_ListToMember[listidx], "ZTLGUID");
	g_ZTLPosition = ZhanTuanInterface:GetMembersInfo(g_ListToMember[listidx], "ZTLPosition")
	--PushDebugMessage(g_ZTLPosition.."......."..g_ZTLGUID);
	--if(2 == g_ZTLPosition and 1 == g_Position) then
	--	NewBangHui_Bhls_Appoint_Button:Enable();
	--	NewBangHui_Bhls_Remove_Button:Enable();
	--	NewBangHui_Bhls_Appoint_Button:SetText("#{BHKF_140909_302}");
	--elseif(3 == g_ZTLPosition and 1 == g_Position) then
	--	NewBangHui_Bhls_Appoint_Button:Enable();
	--	NewBangHui_Bhls_Remove_Button:Enable();
	--	NewBangHui_Bhls_Appoint_Button:SetText("#{BHKF_140909_69}");
	--elseif(3 == g_ZTLPosition and 2 == g_Position) then
	--	NewBangHui_Bhls_Add_Button:Enable();
	--	NewBangHui_Bhls_Remove_Button:Enable();
	--	NewBangHui_Bhls_Appoint_Button:Disable();
	--elseif(1 == g_Position) then
	--	NewBangHui_Bhls_Add_Button:Enable();
	--	NewBangHui_Bhls_Remove_Button:Disable();
	--	NewBangHui_Bhls_Appoint_Button:Disable();
	--PushDebugMessage(g_GuildPosition.."......."..g_Position);
	NewBangHui_Bhls_Add_Button:Disable();
	NewBangHui_Bhls_Remove_Button:Disable();
	NewBangHui_Bhls_Appoint_Button:Disable();
	if(2 == g_Position) then
		NewBangHui_Bhls_Add_Button:Enable();
		NewBangHui_Bhls_Remove_Button:Enable();
		NewBangHui_Bhls_Appoint_Button:Disable();
	end
	if((1 == g_GuildPosition or 2 == g_GuildPosition)) then
		if(2 == g_ZTLPosition) then
			NewBangHui_Bhls_Appoint_Button:SetText("#{BHKF_140909_302}");
		elseif(3 == g_ZTLPosition) then
			NewBangHui_Bhls_Appoint_Button:SetText("#{BHKF_140909_69}");
		end
		NewBangHui_Bhls_Add_Button:Enable();
		NewBangHui_Bhls_Remove_Button:Enable();
		NewBangHui_Bhls_Appoint_Button:Enable();
	end
end

function NewBangHui_Bhls_SelectTab(idx)
	if(idx <= 0 or idx == nil or idx > 3) then
		return;
	end
	g_TabSel = idx;
	if(1 == g_TabSel) then
		NewBangHui_Bhls_FlagClient:Hide();
		NewBangHui_Bhls_HelpClient:Hide();
		NewBangHui_Bhls_WarClient:Show(); 
		NewBangHui_Bhls_List_Frame:Show();
		g_NewMembersCtl.combo:ResetList();
		g_NewMembersCtl.combo:AddTextItem("#{BHKF_140909_355}" ,1)						--默认：
		g_NewMembersCtl.combo:AddTextItem("#{BHKF_140909_356}" ,2)				--等级从高到低
		g_NewMembersCtl.combo:AddTextItem("#{BHKF_140909_357}" ,3)				--等级从低到高
		g_NewMembersCtl.combo:AddTextItem("#{BHKF_140909_358}" ,4)			--装备评分从高到低
		g_NewMembersCtl.combo:AddTextItem("#{BHKF_140909_359}" ,5)			--装备评分从低到高
		g_NewMembersCtl.combo:SetCurrentSelect(0);
	elseif(2 == g_TabSel) then
		NewBangHui_Bhls_FlagClient:Show();
		NewBangHui_Bhls_WarClient:Hide();
		NewBangHui_Bhls_HelpClient:Hide();
		NewBangHui_Bhls_List_Frame:Show();
		g_NewMembersCtl.combo:ResetList();
		g_NewMembersCtl.combo:AddTextItem("#{BHKF_140909_355}" ,1)						--默认：
		g_NewMembersCtl.combo:AddTextItem("#{BHKF_140909_362}" ,14)		--本周提交数量从多到少
		g_NewMembersCtl.combo:AddTextItem("#{BHKF_140909_363}" ,15)		--本周提交数量从少到多
		g_NewMembersCtl.combo:AddTextItem("#{BHKF_140909_364}" ,12)		--历史提交数量从多到少
		g_NewMembersCtl.combo:AddTextItem("#{BHKF_140909_365}" ,13)		--历史提交数量从少到多
		g_NewMembersCtl.combo:SetCurrentSelect(0);
	elseif(3 == g_TabSel) then
		NewBangHui_Bhls_HelpClient:Show();
		NewBangHui_Bhls_FlagClient:Hide();
		NewBangHui_Bhls_WarClient:Hide(); 
		NewBangHui_Bhls_List_Frame:Hide();
	end
	NewBangHui_Bhls_Update();
end

function NewBangHui_Bhls_ZhanTuan_Update()
	--local nChangeYuanBao = 0;
	local strTips = "";
	if(tonumber(arg0) == ZT_ZHANTUAN_CREATE) then
		PushDebugMessage("#{BHKF_140909_98}");
	elseif(tonumber(arg0) == ZT_ZHANTUAN_QUIT) then
		PushDebugMessage("解散成功...");
	elseif(tonumber(arg0) == ZT_APPOINT) then
		if(ZT_POS_FUTUANZHANG == g_ZTLPosition) then
			PushDebugMessage("#{BHKF_140909_128}");
		else
			PushDebugMessage("#{BHKF_140909_120}");
		end
	elseif(tonumber(arg0) == ZT_ADD_USER) then
		PushDebugMessage("#{BHKF_140909_137}");
	elseif(tonumber(arg0) == ZT_DELETE_USER) then
		PushDebugMessage("#{BHKF_140909_146}");
	--elseif(tonumber(arg0) == ZT_SAVE_YUANBAO) then
	--	nChangeYuanBao = ZhanTuanInterface:GetLocalZhanTuanInfo("ChangeYuanBao");
	--	g_Yuanbao = 0;
	--	g_Yuanbao = Player:GetData("YUANBAO");
	--	strTips = ScriptGlobal_Format("#{BHKF_140909_170}", tostring(nChangeYuanBao));
	--	PushDebugMessage(strTips);
	--elseif(tonumber(arg0) == ZT_GET_YUANBAO) then
	--	nChangeYuanBao = ZhanTuanInterface:GetLocalZhanTuanInfo("ChangeYuanBao");
	--	g_Yuanbao = 0;
	--	g_Yuanbao = Player:GetData("YUANBAO");
	--	strTips = ScriptGlobal_Format("#{BHKF_140909_179}", tostring(nChangeYuanBao));
	--	PushDebugMessage(strTips);
	end
	--刷新数据
	NewBangHui_Bhls_Update();
end

function NewBangHui_Bhls_SetTitle()
	local szName = Guild:GetMyGuildName("Name");
	local title = ScriptGlobal_Format("#{BHJM_140520_01}", szName)
	NewBangHui_Bhls_PageHeader:SetText(title)
end

function NewBangHui_Bhls_Closed()
	g_MemberSel[1] = -1;
	g_MemberSel[2] = -1;
	this:Hide();
end

--组建
function NewBangHui_Bhls_Bottom_Clicked()
	--PushDebugMessage("组建..."..nGuildID);
	ZhanTuanInterface:ModifyZhanTuan(ZT_ZHANTUAN_CREATE,"","",0);
end

--解散
function NewBangHui_Bhls_Dismiss_Button_Clicked()
	--PushDebugMessage("解散..."..nGuildID);
	ZhanTuanInterface:ModifyZhanTuan(50,"","",0);
end

--任命
function NewBangHui_Bhls_Appoint_Button_Clicked()
	if IsTBFinalServer() >= 1 then
		--总决赛特殊服务器不允许进行该操作
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end
	if("" ~= g_ZTLGUID) then
		if(ZT_POS_FUTUANZHANG == g_ZTLPosition) then	--撤销副团长
			--PushDebugMessage("撤销副团长..."..g_ZTLGUID.." Position: "..g_ZTLPosition);
			ZhanTuanInterface:ModifyZhanTuan(ZT_APPOINT, "", g_ZTLGUID, tonumber(ZT_POS_MEMBER));
		elseif(ZT_POS_MEMBER == g_ZTLPosition) then		--任命副团长
			--PushDebugMessage("任命副团长..."..g_ZTLGUID.." Position: "..g_ZTLPosition);
			ZhanTuanInterface:ModifyZhanTuan(ZT_APPOINT, "", g_ZTLGUID, tonumber(ZT_POS_FUTUANZHANG));
		end
	else
		if(ZT_POS_FUTUANZHANG == g_ZTLPosition) then	--撤销副团长
			PushDebugMessage("#{BHKF_140909_414}");
		elseif(ZT_POS_MEMBER == g_ZTLPosition) then		--任命副团长
			PushDebugMessage("#{BHKF_140909_413}");
		end
		return
	end
end

--添加
function NewBangHui_Bhls_Add_Button_Clicked()
	if IsTBFinalServer() >= 1 then
		--总决赛特殊服务器不允许进行该操作
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end

	local nResult = ZhanTuanInterface:ShowInfoWindow(3);
	if(0 == nResult) then
		PushDebugMessage("#{BHKF_140909_133}");
	end
end

--移出
function NewBangHui_Bhls_Remove_Button_Clicked()
	if IsTBFinalServer() >= 1 then
		--总决赛特殊服务器不允许进行该操作
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end
	local listidx = NewBangHui_Bhls_WarList:GetSelectItem()
	--CD时间
	if not NewBangHui_PassTime(g_Seconds) then
		PushDebugMessage("#{ZYPT_081127_2}");
		return
	end
	if(-1 == listidx or "" == g_ZTLGUID) then
		PushDebugMessage("#{BHKF_140909_402}");
		return
	end
	local ZTLGUID = ZhanTuanInterface:GetMembersInfo(g_ListToMember[listidx], "ZTLGUID");
	--PushDebugMessage("移出..."..ZTLGUID);
	ZhanTuanInterface:ModifyZhanTuan(ZT_DELETE_USER,"",ZTLGUID,0);

end

--邀请入团
function NewBangHui_Bhls_Invite_Button_Clicked()
	--CD时间
	if not NewBangHui_PassTime(g_Seconds5) then
		PushDebugMessage("#{BHKF_140909_446}");
		return
	end
	ZhanTuanInterface:AskInviteAddTuan(0);
end

--储备
--function NewBangHui_Bhls_GoodsInfo_Bottom_Add_Clicked()
--	local nYuanBao = NewBangHui_Bhls_GoodsInfo_Bottom_EditBox:GetText();
--	--PushDebugMessage("储备..."..nYuanBao);
--	--CD时间
--	if not NewBangHui_PassTime(g_Seconds) then
--		PushDebugMessage("#{ZYPT_081127_2}");
--		return
--	end
--	if("" ~= nYuanBao) then
--		g_AddYuanbao = nYuanBao;
--		ZhanTuanInterface:ModifyZhanTuan(ZT_SAVE_YUANBAO,"","",tonumber(nYuanBao));
--	else
--		PushDebugMessage("#{BHKF_140909_167}");
--	end
--end

--取出
--function NewBangHui_Bhls_GoodsInfo_Bottom_Sub_Clicked()
--	local nYuanBao = NewBangHui_Bhls_GoodsInfo_Bottom_EditBox:GetText();
--	--PushDebugMessage("取出..."..nYuanBao);
--	--CD时间
--	if not NewBangHui_PassTime(g_Seconds) then
--		PushDebugMessage("#{ZYPT_081127_2}");
--		return
--	end
--	if("" ~= nYuanBao) then
--		ZhanTuanInterface:ModifyZhanTuan(ZT_GET_YUANBAO,"","",tonumber(nYuanBao));
--	else
--		PushDebugMessage("#{BHKF_140909_176}");
--	end
--end

--帮会战团
function NewBangHui_Bhls_War_Button_Clicked()
	ZhanTuanInterface:GetZhanTuanInfo();
	NewBangHui_Bhls_War_Button:SetText("#G".."#{BHKF_140909_42}");
	NewBangHui_Bhls_Flag_Button:SetText("#{BHKF_140909_43}");
	NewBangHui_Bhls_Help_Button:SetText("#{TFJM_141201_1}");
	
	if ( SystemSetup:IsClassic() == 0 ) then	-- 唯美
		NewBangHui_Bhls_WarClient_BK:Show()
		NewBangHui_Bhls_WarClient:Show()
		NewBangHui_Bhls_FlagClient_BK:Hide()
		NewBangHui_Bhls_FlagClient:Hide()
		NewBangHui_Bhls_HelpClient:Hide();
	end
end

--帮会战绩
function NewBangHui_Bhls_Flag_Button_Clicked()
	if IsTBFinalServer() >= 1 then
		--总决赛特殊服务器不允许进行该操作
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end
	local nCurTime = tonumber( DataPool:GetServerDayTime() );
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID();
	--如果龙门分支 时间不同
	if selfZoneWorldID == 9031 or selfZoneWorldID == 9015 then
		if ( nCurTime >= g_MatchTestBeg_LM and nCurTime <= g_MatchTestEnd_LM ) then
			PushDebugMessage( "#{KFCSS_141110_24}" );
			return
		end
	else
		if ( nCurTime >= g_MatchTestBeginTime and nCurTime <= g_MatchTestEndTime ) then
			PushDebugMessage( "#{KFCSS_141110_18}" );
			return
		end
	end



	--PushDebugMessage("NewBangHui_Bhls_Flag_Button_Clicked...");
	NewBangHui_Bhls_SelectTab(2)
	NewBangHui_Bhls_Flag_Button:SetText("#G".."#{BHKF_140909_43}");
	NewBangHui_Bhls_War_Button:SetText("#{BHKF_140909_42}");
	NewBangHui_Bhls_Help_Button:SetText("#{TFJM_141201_1}");
	
	if ( SystemSetup:IsClassic() == 0 ) then	-- 唯美
		NewBangHui_Bhls_WarClient_BK:Hide()
		NewBangHui_Bhls_WarClient:Hide()
		NewBangHui_Bhls_FlagClient_BK:Show()
		NewBangHui_Bhls_FlagClient:Show()
		NewBangHui_Bhls_HelpClient:Hide();
	end
end

function NewBangHui_Bhls_Hygl_Clicked()
	--在跨服总决赛服务器上不允许打开相应的界面
	if IsTBFinalServer() >= 1 then
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhls_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ToggleGuildDetailInfo()
end

function NewBangHui_Bhls_Bhxx_Clicked()
	if IsTBFinalServer() >= 1 then
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhls_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:AskGuildDetailInfo();
	Guild:CloseKickGuildBox();
end

function NewBangHui_Bhls_Tmxx_Clicked()
	--在跨服总决赛服务器上不允许打开相应的界面
	if IsTBFinalServer() >= 1 then
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end
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
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhls_Frame:GetProperty("UnifiedPosition"), 1);
    GuildLeague:ShowInfoWindow()
end

function NewBangHui_Bhls_Bhxz_Clicked()
	--在跨服总决赛服务器上不允许打开相应的界面
	if IsTBFinalServer() >= 1 then
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhls_Frame:GetProperty("UnifiedPosition"), 1);
	City:OpenNewGuildWarDlg();
	Guild:CloseKickGuildBox();
	NewBangHui_Bhls_Bhxz:SetCheck(1)
end

function NewBangHui_Bhls_YXSS_Clicked()
	--在跨服总决赛服务器上不允许打开相应的界面
	if IsTBFinalServer() >= 1 then
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end
  Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhls_Frame:GetProperty("UnifiedPosition"), 1);
  Guild:AskGuildYXSSInfo();
end

function NewBangHui_Bhls_Jzwjs_Clicked()
	--在跨服总决赛服务器上不允许打开相应的界面
	if IsTBFinalServer() >= 1 then
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhls_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ShowCityBuildIntroduce()
end

function NewBangHui_PassTime(iSeconds)
   local iCur = FindFriendDataPool:GetTickCount()
   if ( iCur - g_Timers < iSeconds * 1000) then
      return false;
   else
      g_Timers = iCur;
   	  return true;
   end
end

function NewBangHui_Bhls_Show_PopMenu()
	local nGuildIndex = -1;
	if("" ~= g_ZTLGUID) then
		local totalNum = Guild:GetMembersNum(4);
		local i = 0;
		while i < totalNum do
			local guildIdx = Guild:GetShowMembersIdx(i);
			local nGUID = Guild:GetMembersInfo(guildIdx, "GUID");
			if(g_ZTLGUID == nGUID) then
				nGuildIndex = i;
			end
			i = i + 1;
		end
		if( nGuildIndex > -1 ) then
			Guild:Show_PopMemu(tonumber(nGuildIndex),tonumber(2));
		end
	end
end
function NewBangHui_Bhls_RefreshZhanQi()
		--PushDebugMessage("111111")
		local nCurZhanQI = Guild:GetMyGuildDetailInfo("CURZhanQiYCZ")
		local nTZhanQiYCZAll = 0;
		local nTZhanQiLevel = Guild:GetMyGuildDetailInfo("TZhanQiLevel")
		local nTZhanQiYCZ = Guild:GetMyGuildDetailInfo("TZhanQiYCZ");

		local nFZhanQiYCZAll = 0;
		local nFZhanQiLevel = Guild:GetMyGuildDetailInfo("FZhanQiLevel")
		local nFZhanQiYCZ = Guild:GetMyGuildDetailInfo("FZhanQiYCZ");

		local nKZhanQiYCZAll = 0;
		local nKZhanQiLevel = Guild:GetMyGuildDetailInfo("KZhanQiLevel")
		local nKZhanQiYCZ = Guild:GetMyGuildDetailInfo("KZhanQiYCZ");

		local nNZhanQiYCZAll = 0;
		local nNZhanQiLevel = Guild:GetMyGuildDetailInfo("NZhanQiLevel")
		local nNZhanQiYCZ = Guild:GetMyGuildDetailInfo("NZhanQiYCZ");

		local nSZhanQiYCZAll = 0;
		local nSZhanQiLevel = Guild:GetMyGuildDetailInfo("SZhanQiLevel")
		local nSZhanQiYCZ = Guild:GetMyGuildDetailInfo("SZhanQiYCZ");
		--PushDebugMessage("2222")

		nRet = Guild:ZhanQiIsReached();
		if nRet == 1 then
		--	PushDebugMessage("#{BHZQ_140820_47}");				--满级
			--NewBangHui_Bhls_SituationInfo_Title:SetText("#{BHZQ_140820_34}");
		else
			--PushDebugMessage("2222"..tostring(g_ZhanqiName[nCurZhanQI]))
			local strCurZhanQiInfo = ScriptGlobal_Format("#{BHZQ_140820_33}",g_ZhanqiName[nCurZhanQI+1]);
			--NewBangHui_Bhls_SituationInfo_Title:SetText(strCurZhanQiInfo);
		end
------------铁匠铺  begin
		if(0 == nTZhanQiLevel) then
			nTZhanQiYCZAll = 500;
		elseif(1 == nTZhanQiLevel) then
			nTZhanQiYCZAll = 500;
		elseif(2 == nTZhanQiLevel) then
			nTZhanQiYCZAll = 500;
		elseif(3 == nTZhanQiLevel) then
			nTZhanQiYCZAll = 1000;
		elseif(4 == nTZhanQiLevel) then
			nTZhanQiYCZAll = 1000;
		elseif(5 == nTZhanQiLevel) then
			nTZhanQiYCZAll = 1000;
		elseif(6 == nTZhanQiLevel) then
			nTZhanQiYCZAll = 1500;
		elseif(7 == nTZhanQiLevel) then
			nTZhanQiYCZAll = 2000;
		elseif(8 == nTZhanQiLevel) then
			nTZhanQiYCZAll = 2000;
		elseif(9 == nTZhanQiLevel) then
			nTZhanQiYCZAll = 2000;
		end
		
		local nZhanqiItemCount = Guild:GetMyGuildDetailInfo("ZhanqiItemCount");
		--local mdTransfer = DataPool:GetPlayerMission_DataRound(1429);
		--local freeTransfer = math.mod(mdTransfer,100)
		--local mdRelive = DataPool:GetPlayerMission_DataRound(1428);
		--local freeRelive = math.mod(mdRelive,100)
		
		local nLastWeekZhanqiItemCount = Guild:GetMyGuildDetailInfo("LastWeekZhanqiItemCount");
		local freeTransfer = 0
		local freeRelive  = 0
		if(nLastWeekZhanqiItemCount < 1000) then
			freeTransfer = 0
			freeRelive = 0
		elseif(nLastWeekZhanqiItemCount < 1500) then
			freeTransfer = 2
			freeRelive = 2
		elseif(nLastWeekZhanqiItemCount < 2000) then
			freeTransfer = 4
			freeRelive = 4
		elseif(nLastWeekZhanqiItemCount < 2500) then 
			freeTransfer = 6
			freeRelive = 6
		else 
			freeTransfer = 8
			freeRelive = 8
		end
		if nZhanqiItemCount > 2500 then
			nZhanqiItemCount = 2500
		end
		
		local strZhanhunText = ScriptGlobal_Format("#{BHZQ_140820_32}",nZhanqiItemCount, freeRelive, freeTransfer);		
		NewBangHui_Bhls_FlagInfo_Info_Frame_text:SetText(strZhanhunText);
		
		local strTZhanQiDetailInfo = ScriptGlobal_Format("#{BHZQ_140820_41}",
						 tostring(nTZhanQiYCZ), tostring(nTZhanQiYCZAll)  );

		local strTZhanQiName = 		ScriptGlobal_Format("#{BHZQ_140820_36}" , tostring(nTZhanQiLevel) );
		--NewBangHui_Bhls_SituationInfo_Info_Frame_1_Pro:SetText(strTZhanQiDetailInfo);
		--NewBangHui_Bhls_SituationInfo_Info_Frame_1_Name:SetText(strTZhanQiName);

		if nTZhanQiLevel == g_MAX_ZhanQiLevel then
			--NewBangHui_Bhls_SituationInfo_Info_Frame_1_LevelUp:Hide();
			--NewBangHui_Bhls_SituationInfo_Info_Frame_1_ProText:SetText("#{BHZQ_140820_43}");
			--NewBangHui_Bhls_SituationInfo_Info_Frame_1_ProText:Show();
			strTZhanQiDetailInfo = ScriptGlobal_Format("#{BHZQ_140820_41}",
						 tostring(nTZhanQiYCZAll), tostring(nTZhanQiYCZAll) );
			--NewBangHui_Bhls_SituationInfo_Info_Frame_1_Pro:SetText(strTZhanQiDetailInfo);
		else
			if nCurZhanQI == 0 then
				--NewBangHui_Bhls_SituationInfo_Info_Frame_1_LevelUp:Hide();
				--NewBangHui_Bhls_SituationInfo_Info_Frame_1_ProText:SetText("#{BHZQ_140820_42}");
				--NewBangHui_Bhls_SituationInfo_Info_Frame_1_ProText:Show();
			else
				--NewBangHui_Bhls_SituationInfo_Info_Frame_1_LevelUp:Show();
				--NewBangHui_Bhls_SituationInfo_Info_Frame_1_ProText:Hide();
			end
		end
------------铁匠铺		end

------------伐木场    begin
	  if(0 == nFZhanQiLevel) then
			nFZhanQiYCZAll = 500;
		elseif(1 == nFZhanQiLevel) then
			nFZhanQiYCZAll = 500;
		elseif(2 == nFZhanQiLevel) then
			nFZhanQiYCZAll = 500;
		elseif(3 == nFZhanQiLevel) then
			nFZhanQiYCZAll = 1000;
		elseif(4 == nFZhanQiLevel) then
			nFZhanQiYCZAll = 1000;
		elseif(5 == nFZhanQiLevel) then
			nFZhanQiYCZAll = 1000;
		elseif(6 == nFZhanQiLevel) then
			nFZhanQiYCZAll = 1500;
		elseif(7 == nFZhanQiLevel) then
			nFZhanQiYCZAll = 2000;
		elseif(8 == nFZhanQiLevel) then
			nFZhanQiYCZAll = 2000;
		elseif(9 == nFZhanQiLevel) then
			nFZhanQiYCZAll = 2000;
		end

		local strFZhanQiDetailInfo = ScriptGlobal_Format("#{BHZQ_140820_41}",
						 tostring(nFZhanQiYCZ), tostring(nFZhanQiYCZAll) );
		local strFZhanQiName = 		ScriptGlobal_Format("#{BHZQ_140820_37}" , tostring(nFZhanQiLevel) );
		--NewBangHui_Bhls_SituationInfo_Info_Frame_2_Pro:SetText(strFZhanQiDetailInfo);
		--NewBangHui_Bhls_SituationInfo_Info_Frame_2_Name:SetText(strFZhanQiName);

		if nFZhanQiLevel == g_MAX_ZhanQiLevel then
			--NewBangHui_Bhls_SituationInfo_Info_Frame_2_LevelUp:Hide();
			--NewBangHui_Bhls_SituationInfo_Info_Frame_2_ProText:SetText("#{BHZQ_140820_43}");
			--NewBangHui_Bhls_SituationInfo_Info_Frame_2_ProText:Show();
			strFZhanQiDetailInfo = ScriptGlobal_Format("#{BHZQ_140820_41}",
						 tostring(nFZhanQiYCZAll), tostring(nFZhanQiYCZAll) );
			--NewBangHui_Bhls_SituationInfo_Info_Frame_2_Pro:SetText(strFZhanQiDetailInfo);
		else
			if nCurZhanQI == 1 then
				--NewBangHui_Bhls_SituationInfo_Info_Frame_2_LevelUp:Hide();
				--NewBangHui_Bhls_SituationInfo_Info_Frame_2_ProText:SetText("#{BHZQ_140820_42}");
				--NewBangHui_Bhls_SituationInfo_Info_Frame_2_ProText:Show();

			else
				--NewBangHui_Bhls_SituationInfo_Info_Frame_2_LevelUp:Show();
				--NewBangHui_Bhls_SituationInfo_Info_Frame_2_ProText:Hide();
			end

		end


------------伐木场    end

------------矿洞 begin
		if(0 == nKZhanQiLevel) then
			nKZhanQiYCZAll = 500;
		elseif(1 == nKZhanQiLevel) then
			nKZhanQiYCZAll = 500;
		elseif(2 == nKZhanQiLevel) then
			nKZhanQiYCZAll = 500;
		elseif(3 == nKZhanQiLevel) then
			nKZhanQiYCZAll = 1000;
		elseif(4 == nKZhanQiLevel) then
			nKZhanQiYCZAll = 1000;
		elseif(5 == nKZhanQiLevel) then
			nKZhanQiYCZAll = 1000;
		elseif(6 == nKZhanQiLevel) then
			nKZhanQiYCZAll = 1500;
		elseif(7 == nKZhanQiLevel) then
			nKZhanQiYCZAll = 2000;
		elseif(8 == nKZhanQiLevel) then
			nKZhanQiYCZAll = 2000;
		elseif(9 == nKZhanQiLevel) then
			nKZhanQiYCZAll = 2000;
		end

		local strKZhanQiDetailInfo = ScriptGlobal_Format("#{BHZQ_140820_41}",
						 tostring(nKZhanQiYCZ), tostring(nKZhanQiYCZAll)  );
		local strKZhanQiName = 		ScriptGlobal_Format("#{BHZQ_140820_38}" , tostring(nKZhanQiLevel) );
		--NewBangHui_Bhls_SituationInfo_Info_Frame_3_Pro:SetText(strKZhanQiDetailInfo);
		--NewBangHui_Bhls_SituationInfo_Info_Frame_3_Name:SetText(strKZhanQiName);

		if nKZhanQiLevel == g_MAX_ZhanQiLevel then
			--NewBangHui_Bhls_SituationInfo_Info_Frame_3_LevelUp:Hide();
			--NewBangHui_Bhls_SituationInfo_Info_Frame_3_ProText:SetText("#{BHZQ_140820_43}");
			--NewBangHui_Bhls_SituationInfo_Info_Frame_3_ProText:Show();
			strKZhanQiDetailInfo = ScriptGlobal_Format("#{BHZQ_140820_41}",
						 tostring(nKZhanQiYCZAll), tostring(nKZhanQiYCZAll)  );
			--NewBangHui_Bhls_SituationInfo_Info_Frame_3_Pro:SetText(strKZhanQiDetailInfo);
		else
			if nCurZhanQI == 2 then
				--NewBangHui_Bhls_SituationInfo_Info_Frame_3_LevelUp:Hide();
				--NewBangHui_Bhls_SituationInfo_Info_Frame_3_ProText:SetText("#{BHZQ_140820_42}");
				--NewBangHui_Bhls_SituationInfo_Info_Frame_3_ProText:Show();
			else
				--NewBangHui_Bhls_SituationInfo_Info_Frame_3_LevelUp:Show();
				--NewBangHui_Bhls_SituationInfo_Info_Frame_3_ProText:Hide();
			end
		end

------------矿洞 end

------------农场    begin
		if(0 == nNZhanQiLevel) then
			nNZhanQiYCZAll = 500;
		elseif(1 == nNZhanQiLevel) then
			nNZhanQiYCZAll = 500;
		elseif(2 == nNZhanQiLevel) then
			nNZhanQiYCZAll = 500;
		elseif(3 == nNZhanQiLevel) then
			nNZhanQiYCZAll = 1000;
		elseif(4 == nNZhanQiLevel) then
			nNZhanQiYCZAll = 1000;
		elseif(5 == nNZhanQiLevel) then
			nNZhanQiYCZAll = 1000;
		elseif(6 == nNZhanQiLevel) then
			nNZhanQiYCZAll = 1500;
		elseif(7 == nNZhanQiLevel) then
			nNZhanQiYCZAll = 2000;
		elseif(8 == nNZhanQiLevel) then
			nNZhanQiYCZAll = 2000;
		elseif(9 == nNZhanQiLevel) then
			nNZhanQiYCZAll = 2000;
		end

		local strNZhanQiDetailInfo = ScriptGlobal_Format("#{BHZQ_140820_41}",
						 tostring(nNZhanQiYCZ), tostring(nNZhanQiYCZAll) );
		local strNZhanQiName = 		ScriptGlobal_Format("#{BHZQ_140820_39}" , tostring(nNZhanQiLevel) );
		--NewBangHui_Bhls_SituationInfo_Info_Frame_4_Pro:SetText(strNZhanQiDetailInfo);
		--NewBangHui_Bhls_SituationInfo_Info_Frame_4_Name:SetText(strNZhanQiName);

		if nNZhanQiLevel == g_MAX_ZhanQiLevel then
			--NewBangHui_Bhls_SituationInfo_Info_Frame_4_LevelUp:Hide();
			--NewBangHui_Bhls_SituationInfo_Info_Frame_4_ProText:SetText("#{BHZQ_140820_43}");
			--NewBangHui_Bhls_SituationInfo_Info_Frame_4_ProText:Show();
			strNZhanQiDetailInfo = ScriptGlobal_Format("#{BHZQ_140820_41}",
						 tostring(nNZhanQiYCZAll), tostring(nNZhanQiYCZAll)  );
			--NewBangHui_Bhls_SituationInfo_Info_Frame_4_Pro:SetText(strNZhanQiDetailInfo);
		else
			if nCurZhanQI == 3 then
				--NewBangHui_Bhls_SituationInfo_Info_Frame_4_LevelUp:Hide();
				--NewBangHui_Bhls_SituationInfo_Info_Frame_4_ProText:SetText("#{BHZQ_140820_42}");
				--NewBangHui_Bhls_SituationInfo_Info_Frame_4_ProText:Show();
			else
				--NewBangHui_Bhls_SituationInfo_Info_Frame_4_LevelUp:Show();
				--NewBangHui_Bhls_SituationInfo_Info_Frame_4_ProText:Hide();
			end
		end


------------农场 end

------------兽栏 begin
		if(0 == nSZhanQiLevel) then
			nSZhanQiYCZAll = 500;
		elseif(1 == nSZhanQiLevel) then
			nSZhanQiYCZAll = 500;
		elseif(2 == nSZhanQiLevel) then
			nSZhanQiYCZAll = 500;
		elseif(3 == nSZhanQiLevel) then
			nSZhanQiYCZAll = 1000;
		elseif(4 == nSZhanQiLevel) then
			nSZhanQiYCZAll = 1000;
		elseif(5 == nSZhanQiLevel) then
			nSZhanQiYCZAll = 1000;
		elseif(6 == nSZhanQiLevel) then
			nSZhanQiYCZAll = 1500;
		elseif(7 == nSZhanQiLevel) then
			nSZhanQiYCZAll = 2000;
		elseif(8 == nSZhanQiLevel) then
			nSZhanQiYCZAll = 2000;
		elseif(9 == nSZhanQiLevel) then
			nSZhanQiYCZAll = 2000;
		end

		local strSZhanQiDetailInfo = ScriptGlobal_Format("#{BHZQ_140820_41}",
						 tostring(nSZhanQiYCZ), tostring(nSZhanQiYCZAll) );
		local strSZhanQiName = 		ScriptGlobal_Format("#{BHZQ_140820_40}" , tostring(nSZhanQiLevel) );
		--NewBangHui_Bhls_SituationInfo_Info_Frame_5_Pro:SetText(strSZhanQiDetailInfo);
		--NewBangHui_Bhls_SituationInfo_Info_Frame_5_Name:SetText(strSZhanQiName);

		if nSZhanQiLevel == g_MAX_ZhanQiLevel then
			--NewBangHui_Bhls_SituationInfo_Info_Frame_5_LevelUp:Hide();
			--NewBangHui_Bhls_SituationInfo_Info_Frame_5_ProText:SetText("#{BHZQ_140820_43}");
			--NewBangHui_Bhls_SituationInfo_Info_Frame_5_ProText:Show();
			strSZhanQiDetailInfo = ScriptGlobal_Format("#{BHZQ_140820_41}",
						 tostring(nSZhanQiYCZAll), tostring(nSZhanQiYCZAll)  );
			--NewBangHui_Bhls_SituationInfo_Info_Frame_5_Pro:SetText(strSZhanQiDetailInfo);
		else
			if nCurZhanQI == 4 then
				--NewBangHui_Bhls_SituationInfo_Info_Frame_5_LevelUp:Hide();
				--NewBangHui_Bhls_SituationInfo_Info_Frame_5_ProText:SetText("#{BHZQ_140820_42}");
				--NewBangHui_Bhls_SituationInfo_Info_Frame_5_ProText:Show();
			else
				--NewBangHui_Bhls_SituationInfo_Info_Frame_5_LevelUp:Show();
				--NewBangHui_Bhls_SituationInfo_Info_Frame_5_ProText:Hide();
			end

		end
------------兽栏 end
end

--function --NewBangHui_Bhls_SituationInfo_Info_Frame_1_LevelUp_Clicked()
--	g_SelZhanQi = 0;
--	NewBangHui_Bhls_ModifyCurZhanQi( g_SelZhanQi );
--end

--function --NewBangHui_Bhls_SituationInfo_Info_Frame_2_LevelUp_Clicked()
--	g_SelZhanQi = 1;
--	NewBangHui_Bhls_ModifyCurZhanQi( g_SelZhanQi );
--end


--function --NewBangHui_Bhls_SituationInfo_Info_Frame_3_LevelUp_Clicked()
--	g_SelZhanQi = 2;
--	NewBangHui_Bhls_ModifyCurZhanQi( g_SelZhanQi );
--end


--function --NewBangHui_Bhls_SituationInfo_Info_Frame_4_LevelUp_Clicked()
--	g_SelZhanQi = 3;
--	NewBangHui_Bhls_ModifyCurZhanQi( g_SelZhanQi );
--end


--function --NewBangHui_Bhls_SituationInfo_Info_Frame_5_LevelUp_Clicked()
--	g_SelZhanQi = 4;
--	NewBangHui_Bhls_ModifyCurZhanQi( g_SelZhanQi );
--end

function NewBangHui_Bhls_ModifyCurZhanQi( idx )

	local nRet = Guild:IsChieforAss();
	if nRet == 0 then
		PushDebugMessage("#{BHZQ_140820_55}")
		return;
	end
	nRet = Guild:ZhanQiIsReached();
	if nRet == 1 then
		PushDebugMessage("#{BHZQ_140820_47}")				--满级
		return;
	end

	if idx ==  Guild:GetMyGuildDetailInfo("CURZhanQiYCZ") then
		PushDebugMessage("#{BHZQ_140820_46}")				--当前
		return;
	end
	local nRet = Guild:ModifyCurZhanQi( idx , 0);
	local msg = ScriptGlobal_Format("#{BHZQ_140820_48}",g_ZhanqiName[idx+1] );
	MessageBoxCommon("#{BHZQ_140820_66}", msg, "NewBangHui_Bhls", "OnBtnConfirmOK()", "OnBtnBuyCancel()");

end
--二次确认框 确认
function NewBangHui_Bhls_OnBtnConfirmOK()
	local nRet = Guild:ModifyCurZhanQi( g_SelZhanQi , 1 );
	NewBangHui_Bhls_Update();
	local nCurZhanQI = Guild:GetMyGuildDetailInfo("CURZhanQiYCZ")
	local msg = ScriptGlobal_Format("#{BHZQ_140820_51}",g_ZhanqiName[nCurZhanQI+1]);
	PushDebugMessage(msg)				--当前
end

--取消
function NewBangHui_Bhls_OnBtnBuyCancel()

end

function NewBangHui_Bhls_SituationInfo_Info_Frame_View_Clicked()
	PushEvent( "OPEN_BHLS_BATTLEFIELDINFO_DLG")
end

function NewBangHui_Bhls_SetDynamic_Pos()
    local selfGuildClanUnionPos = Variable:GetVariable("SelfGuildClanUnionPos")
	if( selfGuildClanUnionPos ~= nil) then
	    NewBangHui_Bhls_Frame:SetProperty("UnifiedPosition", selfGuildClanUnionPos )
	end
end

function NewBangHui_Bhls_SituationInfo_Info_Frame_Help_Clicked()
	OpenYBShopReference("#{BHZQ_140820_68}")
end

function NewBangHui_Bhls_Help_Button_Clicked()
	NewBangHui_Bhls_SelectTab(3)
	NewBangHui_Bhls_Flag_Button:SetText("#{BHKF_140909_43}");
	NewBangHui_Bhls_War_Button:SetText("#{BHKF_140909_42}");
	NewBangHui_Bhls_Help_Button:SetText("#G".."#{TFJM_141201_1}");
	NewBangHui_Bhls_HelpFrame1:Show();		--默认申请参战显示
	NewBangHui_Bhls_HelpFrame2:Hide();		--进入战场
	NewBangHui_Bhls_HelpFrame3:Hide();		--赢取胜利
	NewBangHui_Bhls_HelpFrame4:Hide();		--段位积分
	NewBangHui_Bhls_HelpFrame5:Hide();		--战功威望
	NewBangHui_Bhls_HelpClient_list_Bottom1:SetCheck(1); 
	if ( SystemSetup:IsClassic() == 0 ) then	-- 唯美
		NewBangHui_Bhls_WarClient_BK:Hide()
		NewBangHui_Bhls_WarClient:Hide()
		NewBangHui_Bhls_FlagClient_BK:Hide()
		NewBangHui_Bhls_FlagClient:Hide()
		NewBangHui_Bhls_HelpClient:Show();
		
	end
end
function NewBangHui_Bhls_HelpClient_list_Bottom1_Clicked()

	NewBangHui_Bhls_HelpFrame1:Show();		--默认申请参战显示
	NewBangHui_Bhls_HelpFrame2:Hide();		--进入战场
	NewBangHui_Bhls_HelpFrame3:Hide();		--赢取胜利
	NewBangHui_Bhls_HelpFrame4:Hide();		--段位积分
	NewBangHui_Bhls_HelpFrame5:Hide();		--战功威望
	NewBangHui_Bhls_HelpClient_list_Bottom1:SetCheck(1); 
end
function NewBangHui_Bhls_HelpClient_list_Bottom2_Clicked()

	NewBangHui_Bhls_HelpFrame1:Hide();		--默认申请参战显示
	NewBangHui_Bhls_HelpFrame2:Show();		--进入战场
	NewBangHui_Bhls_HelpFrame3:Hide();		--赢取胜利
	NewBangHui_Bhls_HelpFrame4:Hide();		--段位积分
	NewBangHui_Bhls_HelpFrame5:Hide();		--战功威望
	NewBangHui_Bhls_HelpClient_list_Bottom2:SetCheck(1); 
end
function NewBangHui_Bhls_HelpClient_list_Bottom3_Clicked()

	NewBangHui_Bhls_HelpFrame1:Hide();		--默认申请参战显示
	NewBangHui_Bhls_HelpFrame2:Hide();		--进入战场
	NewBangHui_Bhls_HelpFrame3:Show();		--赢取胜利
	NewBangHui_Bhls_HelpFrame4:Hide();		--段位积分
	NewBangHui_Bhls_HelpFrame5:Hide();		--战功威望
	NewBangHui_Bhls_HelpClient_list_Bottom3:SetCheck(1); 
end
function NewBangHui_Bhls_HelpClient_list_Bottom4_Clicked()

	NewBangHui_Bhls_HelpFrame1:Hide();		--默认申请参战显示
	NewBangHui_Bhls_HelpFrame2:Hide();		--进入战场
	NewBangHui_Bhls_HelpFrame3:Hide();		--赢取胜利
	NewBangHui_Bhls_HelpFrame4:Show();		--段位积分
	NewBangHui_Bhls_HelpFrame5:Hide();		--战功威望
	NewBangHui_Bhls_HelpClient_list_Bottom4:SetCheck(1); 
end
function NewBangHui_Bhls_HelpClient_list_Bottom5_Clicked() 
	NewBangHui_Bhls_HelpFrame1:Hide();		--默认申请参战显示
	NewBangHui_Bhls_HelpFrame2:Hide();		--进入战场
	NewBangHui_Bhls_HelpFrame3:Hide();		--赢取胜利
	NewBangHui_Bhls_HelpFrame4:Hide();		--段位积分
	NewBangHui_Bhls_HelpFrame5:Show();		--战功威望
	NewBangHui_Bhls_HelpClient_list_Bottom5:SetCheck(1); 
end
 
function NewBangHui_Bhls_StoreButton_CunRu_Clicked()

	local nCurTick = FindFriendDataPool:GetTickCount()

	if nCurTick - g_ZCYuanBao_Button_PH <= 4000 then
		--操作太频繁
		PushDebugMessage("#{BHKF_150323_65}");
		return
	end
	g_ZCYuanBao_Button_PH = nCurTick

	if KVKInterface:IsInKVKServer() >= 1 then
		--K服不允许操作
		PushDebugMessage("#{BHKF_150323_66}")
		return
	end

	if IsInTServer() >= 1 then
		--T服不允许操作
		PushDebugMessage("#{BHKF_150323_67}")
		return
	end

	if ZhanTuanInterface:IsFinalCompetitor() <= 0 then
		return
	end

	if IsTBFinalServer() >= 1 then
		--总决赛特殊服务器不允许操作
		PushDebugMessage("#{BHKF_140909_162}")
		return
	end

	--local AmountText = NewBangHui_Bhls_StoreBottom_Input:GetText()
	--if AmountText  == "" then
		--PushDebugMessage("#{BHKF_140909_167}")
		--return
	--end
	--local Amount = tonumber(AmountText)
	--ZhanTuanInterface:SaveZCYuanBao(Amount)
end

function NewBangHui_Bhls_StoreButton_QuChu_Clicked()

	local nCurTick = FindFriendDataPool:GetTickCount()

	if nCurTick - g_ZCYuanBao_Button_PH <= 4000 then
		--操作太频繁
		PushDebugMessage("#{BHKF_150323_65}");
		return
	end
	g_ZCYuanBao_Button_PH = nCurTick

	if KVKInterface:IsInKVKServer() >= 1 then
		--K服不允许操作
		PushDebugMessage("#{BHKF_150323_66}")
		return
	end

	if IsInTServer() >= 1 then
		--T服不允许操作
		PushDebugMessage("#{BHKF_150323_67}")
		return
	end


	if ZhanTuanInterface:IsFinalCompetitor() <= 0 then
		return
	end
	
	if IsTBFinalServer() >= 1 then
		--总决赛特殊服务器不允许操作
		PushDebugMessage("#{BHKF_140909_172}")
		return
	end
	--local AmountText = NewBangHui_Bhls_StoreBottom_Input:GetText()
	--if AmountText  == "" then
		--PushDebugMessage("#{BHKF_140909_176}")
		--return
	--end
	--local Amount = tonumber(NewBangHui_Bhls_StoreBottom_Input:GetText())
	--ZhanTuanInterface:TakeOutZCYuanBao(Amount)
end


function NewBangHui_Bhls_Top_KVKLeague_Clicked()
	local alliancemark = 0;
end

function NewBangHui_Bhls_HB_OnClicked()
	if IsTBFinalServer() >= 1 then
		--总决赛特殊服务器不允许进行该操作
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhls_Frame:GetProperty("UnifiedPosition"), 1)
	Guild:OpentGuildGiftUI()
end
