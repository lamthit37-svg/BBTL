
local g_NewBangHui_Tmxx_Frame_UnifiedPosition = nil
local g_NewBH_Ctrl = {}
local g_MatchTestBeginTime = 20141218			--点击雄霸天下按钮时进行以下判断,当前时间是否处于2014年12月18日0点之后
local g_MatchTestBeg_LM	= 20141128				-- 龙门测试赛开始时间

-- 城战轮换（霸者天下）助战操作时间
local NewBangHui_Tmxx_AssistOpTime =
{
    [1] = {weekday = 5, begintime = 213000},
    [2] = {weekday = 6, endtime = 202000},
} -- end NewBangHui_Tmxx_AssistOpTim

--===============================================
-- OnLoad()
--===============================================
function NewBangHui_Tmxx_PreLoad()

	this:RegisterEvent("UI_COMMAND");
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
	this:RegisterEvent("GUILD_ZHANTUAN_OP")
	--this:RegisterEvent("TCITYWARLIMIT_OPENCANDIDATE")
end

function NewBangHui_Tmxx_OnLoad()
	g_NewBangHui_Tmxx_Frame_UnifiedPosition = NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition")
	g_NewBH_Ctrl = { name = NewBangHui_Tmxx_Frame2_TMMC_Lace_Text,
								learder = NewBangHui_Tmxx_Frame2_XRBZ_Lace_Text,
								ID = NewBangHui_Tmxx_Frame2_TMID_Lace_Text,
								MemberNum = NewBangHui_Tmxx_Frame2_TMRS_Lace_Text,
								Creator = NewBangHui_Tmxx_Frame2_TMCSR_Lace_Text,
								CreatorTime = NewBangHui_Tmxx_Frame2_CJSJ_Lace_Text,
								desc = NewBangHui_Tmxx_Desc,
								descedit = NewBangHui_Tmxx_Desc_Edit,
								list = NewBangHui_Tmxx_Member_List,
								changeButton = NewBangHui_Tmxx_ChangeDesc_Button,
								applylistButton = NewBangHui_Tmxx_ApplyList,
								quitButton = NewBangHui_Tmxx_Quit,
								OutButton = NewBangHui_Tmxx_Out,
	}
end

--===============================================
-- OnEvent()
--===============================================
function NewBangHui_Tmxx_OnEvent( event )

	if event == "UPDATE_GUILD_LEAGUE_INFO" then
		NewBangHui_Tmxx_SetDynamic_Pos()
		NewBangHui_Tmxx_Tmxx:SetCheck(1) 
		NewBangHui_Tmxx_SetTitle()
		this:Show()
		NewBangHui_Tmxx_DoUpdate()

		-- -- 霸者天下小红点
		-- local bztxApplyNum = DataPool:TCWLGetAssistApplyNum()
		-- local bztxIsInTime = NewBangHui_Tmxx_Check_BZTXAssistEnrollTime()
		-- if (bztxIsInTime > 0) then
		-- 	if (bztxApplyNum <= 0) then
		-- 		NewBangHui_Tmxx_BZTX_Tips:Hide()
		-- 	else
		-- 		local isChiefOrAss = Guild:IsChieforAss()
		-- 		if (isChiefOrAss ~= 1) then
		-- 			NewBangHui_Tmxx_BZTX_Tips:Hide()
		-- 		else
		-- 			NewBangHui_Tmxx_BZTX_Tips:Show()
		-- 		end
		-- 	end
		-- else
		-- 	NewBangHui_Tmxx_BZTX_Tips:Hide()
		-- end
	elseif event == "GUILD_LEAGUE_INFO" or
	(event == "UI_COMMAND" and tonumber(arg0)==1208) then
		NewBangHui_Tmxx_SetTitle()
		NewBangHui_Tmxx_Desc_Edit:Disable()
		g_NewBH_Ctrl.applylistButton:Disable()
		g_NewBH_Ctrl.quitButton:Disable()
		g_NewBH_Ctrl.changeButton:Disable()
		g_NewBH_Ctrl.OutButton:Disable()
		NewBangHui_Tmxx_SetDynamic_Pos()
		NewBangHui_Tmxx_DoReset()
		this:Show()
		GuildLeague:RequestInfo()

		-- -- 霸者天下小红点
		-- local bztxApplyNum = DataPool:TCWLGetAssistApplyNum()
		-- local bztxIsInTime = NewBangHui_Tmxx_Check_BZTXAssistEnrollTime()
		-- if (bztxIsInTime > 0) then
		-- 	if (bztxApplyNum <= 0) then
		-- 		NewBangHui_Tmxx_BZTX_Tips:Hide()
		-- 	else
		-- 		local isChiefOrAss = Guild:IsChieforAss()
		-- 		if (isChiefOrAss ~= 1) then
		-- 			NewBangHui_Tmxx_BZTX_Tips:Hide()
		-- 		else
		-- 			NewBangHui_Tmxx_BZTX_Tips:Show()
		-- 		end
		-- 	end
		-- else
		-- 	NewBangHui_Tmxx_BZTX_Tips:Hide()
		-- end
	elseif event == "GUILD_SHOW_ENEMYLIST" then
		NewBangHui_Tmxx_Closed()
	elseif event == "GUILD_SHOW_MEMBERINFO" then
		NewBangHui_Tmxx_Closed()
	elseif event == "GUILD_SHOW_DETAILINFO" then
		NewBangHui_Tmxx_Closed()
	elseif event == "OPEN_BUILD_INTRODUCE" then
		NewBangHui_Tmxx_Closed()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		NewBangHui_Tmxx_Closed()
	elseif ( event == "ZHANTUAN_LIST_DATA" ) then
		NewBangHui_Tmxx_Closed()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		NewBangHui_Tmxx_Frame_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		NewBangHui_Tmxx_Frame_On_ResetPos()
	elseif (event == "SHOW_GUILDWAR_ANIMI" ) then
		local type = arg0;
		if (arg0 == "show") then
			NewBangHui_Tmxx_Bhxz:SetText("#g0071BF#{BHJM_140520_04}")
			NewBangHui_Tmxx_Bhxz:SetToolTip("你的帮会正在帮战");
		else
		    NewBangHui_Tmxx_Bhxz:SetText("#{BHJM_140520_04}");
			NewBangHui_Tmxx_Bhxz:SetToolTip("");
		end
	elseif (event == "OPENMYALLIANCE") then
		NewBangHui_Tmxx_Closed()
	elseif (event == "OPEN_GUILD_GIFT" ) then
		NewBangHui_Tmxx_Closed()
	elseif event == "GUILD_BIDDING_SHOWLIST" then
		NewBangHui_Tmxx_Closed()
	elseif event == "TCITYWARLIMIT_OPENCANDIDATE" then
		NewBangHui_Tmxx_Closed()
	elseif event == "GUILD_ZHANTUAN_OP" then
		NewBangHui_Tmxx_Closed()
	end
end

function NewBangHui_Tmxx_Frame_On_ResetPos()
	NewBangHui_Tmxx_Frame:SetProperty("UnifiedPosition", g_NewBangHui_Tmxx_Frame_UnifiedPosition)
end

function NewBangHui_Tmxx_DoReset()
	NewBangHui_Tmxx_Desc_Edit:Hide()
	
end

function NewBangHui_Tmxx_DoUpdate()

	g_NewBH_Ctrl.name:SetText(GuildLeague:GetName())
	g_NewBH_Ctrl.learder:SetText(GuildLeague:GetChieftain())
	g_NewBH_Ctrl.ID:SetText(tostring(GuildLeague:GetID()))
	local ct=GuildLeague:GetUserCount()
	g_NewBH_Ctrl.MemberNum:SetText(tostring(ct))
	g_NewBH_Ctrl.Creator:SetText(GuildLeague:GetCreator())
	g_NewBH_Ctrl.CreatorTime:SetText(GuildLeague:GetCreateTime())
	
	g_NewBH_Ctrl.desc:SetText(GuildLeague:GetDescription())
	g_NewBH_Ctrl.descedit:SetText(GuildLeague:GetDescription())
	g_NewBH_Ctrl.descedit:Enable()
	
	
	g_NewBH_Ctrl.list:RemoveAllItem()
	
	local isGuildChieftain=0
	for i = 0, GuildLeague:GetMemberCount()-1 do
		g_NewBH_Ctrl.list:AddNewItem( GuildLeague:GetMemberName(i), 0, i )
		g_NewBH_Ctrl.list:AddNewItem( GuildLeague:GetMemberID(i), 1, i )
		g_NewBH_Ctrl.list:AddNewItem( GuildLeague:GetMemberChieftain(i), 2, i )
		g_NewBH_Ctrl.list:AddNewItem( tostring(GuildLeague:GetMemberUserCount(i)), 3, i )

		g_NewBH_Ctrl.list:AddNewItem( GuildLeague:GetMemberCityLevel(i), 4, i )
		-- g_NewBH_Ctrl.list:AddNewItem( GuildLeague:GetMemberCityName(i), 4, i )
		g_NewBH_Ctrl.list:AddNewItem( GuildLeague:GetMemberCityScene(i), 5, i )
		g_NewBH_Ctrl.list:AddNewItem( GuildLeague:GetMemberCreateTime(i), 6, i )
		g_NewBH_Ctrl.list:AddNewItem( GuildLeague:GetMemberEnterTime(i), 7, i )
		
		if GuildLeague:GetMemberChieftainGUID(i)==Player:GetGUID() then
			isGuildChieftain=1
		end
		
	end
	
	if GuildLeague:GetChieftainGUID()==Player:GetGUID() then
		g_NewBH_Ctrl.changeButton:Enable()
		g_NewBH_Ctrl.applylistButton:Enable()
		g_NewBH_Ctrl.quitButton:Enable()
		g_NewBH_Ctrl.OutButton:Enable()
	end
	
	
	if isGuildChieftain>0 then
		g_NewBH_Ctrl.quitButton:Enable()
	end
	
	
end

function NewBangHui_Tmxx_DoApplyList()
	GuildLeague:ShowApplyListWindow()
end

function NewBangHui_Tmxx_DoQuit()
	GuildLeague:ShowQuitConfirmWindow()
	this:Hide()
end

function NewBangHui_Tmxx_Fire()
	local index=g_NewBH_Ctrl.list:GetSelectItem()
	if index==-1 then
		PushDebugMessage("请先选择一个同盟成员！")
		return
	end

	GuildLeague:FireGuild( GuildLeague:GetID(), GuildLeague:GetMemberID(index) )
end



function NewBangHui_Tmxx_Tmxx_Clicked()
	--在K服只有服务器配置保留原服"帮会同盟"信息的时候,才响应对应的点击按钮的事件
	if KVKInterface:IsInKVKServer() == 1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
		PushDebugMessage("#{KVKBH_140124_66}")
		return;
	end
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition"), 1);
    GuildLeague:ShowInfoWindow()
end

function NewBangHui_Tmxx_Hygl_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ToggleGuildDetailInfo()
end


function NewBangHui_Tmxx_Hygl_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ToggleGuildDetailInfo()
end

function NewBangHui_Tmxx_ClickChangeDesc_Button()
	if NewBangHui_Tmxx_Desc:IsVisible() then
		local txt=GuildLeague:GetDescription()
		NewBangHui_Tmxx_Desc_Edit:SetText(txt)
		
		NewBangHui_Tmxx_Desc:Hide()
		NewBangHui_Tmxx_Desc_Edit:Show()
		
		g_NewBH_Ctrl.changeButton:SetText("#{TM_20080331_04}")
	else
		local txt=NewBangHui_Tmxx_Desc_Edit:GetText()
		NewBangHui_Tmxx_Desc:SetText(txt)
		
		if txt==nil or txt=="" then
			PushDebugMessage("您没有输入同盟宣言")
			return
		end		
		
		local r=GuildLeague:ChangeDescription(txt)
		
		if r==-1 then
			PushDebugMessage("#{TM_20080311_07}")
			return
		end

		NewBangHui_Tmxx_Desc_Edit:Hide()
		NewBangHui_Tmxx_Desc:Show()
		
		NewBangHui_Tmxx_Desc_Edit:Disable()
		g_NewBH_Ctrl.changeButton:Disable()
		GuildLeague:RequestInfo()
		
		g_NewBH_Ctrl.changeButton:SetText("#{TM_20080318_10}")
		
		
		
	end
		
		
end

function NewBangHui_Tmxx_Closed()
	this:Hide()
end

function NewBangHui_Tmxx_Bhxx_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:AskGuildDetailInfo();
	Guild:CloseKickGuildBox();	
end

function NewBangHui_Tmxx_Bhxz_Clicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition"), 1);
	City:OpenNewGuildWarDlg();
	Guild:CloseKickGuildBox();
	NewBangHui_Tmxx_Tmxx:SetCheck(1) 
end

function NewBangHui_Tmxx_JZWJS_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ShowCityBuildIntroduce()
end
function NewBangHui_Tmxx_Member_List_OnMouseRClick()

end

function NewBangHui_Tmxx_SetDynamic_Pos()
    local selfGuildClanUnionPos = Variable:GetVariable("SelfGuildClanUnionPos")
	if( selfGuildClanUnionPos ~= nil) then
	    NewBangHui_Tmxx_Frame:SetProperty("UnifiedPosition", selfGuildClanUnionPos )
	end
end

function NewBangHui_Tmxx_SetTitle()
	local szName = Guild:GetMyGuildName("Name");
	local title = ScriptGlobal_Format("#{BHJM_140520_01}", szName)
	NewBangHui_Tmxx_PageHeader:SetText(title)
end

--帮会联赛 by wangbin
function NewBangHui_Tmxx_BHLS_Clicked()
	local nCurTime = tonumber(DataPool:GetServerDayTime());
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID();
	if selfZoneWorldID == 9031 or selfZoneWorldID == 9015 then
		if ( nCurTime < g_MatchTestBeg_LM ) then
			PushDebugMessage( "#{BHKF_140909_419}" );
			NewBangHui_Tmxx_Tmxx:SetCheck(1);
			Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition"), 1);
			return
		end
	else
		if ( nCurTime < g_MatchTestBeginTime ) then
			PushDebugMessage( "#{BHKF_140909_419}" );
			NewBangHui_Tmxx_Tmxx:SetCheck(1);
			Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition"), 1);
			return
		end
	end
	
	local nStatus = ZhanTuanInterface:GetZhanTuanInfo();
	if(0 == tonumber(nStatus)) then
		NewBangHui_Tmxx_Tmxx:SetCheck(1)
	end
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition"), 1);
end


function NewBangHui_Tmxx_KVKLeague_Clicked()
	local alliancemark = 0;
end

function NewBangHui_Tmxx_HB_OnClicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition"), 1)
	Guild:OpentGuildGiftUI()
end

--拍卖
function NewBangHui_Tmxx_Auction_Clicked()
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
  Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition"), 1);
  Guild:AskGuildBiddingInfo(0, 1, -1)
end

function NewBangHui_Tmxx_BZZT_Clicked()
	local selfzoneid = DataPool:GetSelfZoneWorldID()
	if (KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(181) > 0) or 
		DataPool:Lua_IsNewServerPlayerByZWID(selfzoneid) == 1 or
		Player:GetData("IsOriginalJD")  == 1 or
		Player:GetData("Is2606S")  == 1 or 
		Player:GetData("SPECKAJI89") > 0 then
	  PushDebugMessage("#{ZTXT_260511_151}")
	  return
	end
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("GUILD_ZHANTUAN_OP", 1)
end

function NewBangHui_Tmxx_BZTX_Clicked()
	-- if (Player:GetData("TCWLSvrOpenFlag") < 0) then
	-- 	NewBangHui_Tmxx_BZTX:SetCheck(0)
	-- 	NewBangHui_Tmxx_Tmxx:SetCheck(1)

	-- 	PushDebugMessage("#{GCQH_240429_161}")
	-- elseif (Player:GetData("TCWLSvrOpenFlag") == 0) then
	-- 	NewBangHui_Tmxx_BZTX:SetCheck(0)
	-- 	NewBangHui_Tmxx_Tmxx:SetCheck(1)
		
	-- 	PushDebugMessage("#{GCQH_240429_154}")
	-- else
	-- 	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Tmxx_Frame:GetProperty("UnifiedPosition"), 1)
	-- 	Guild:TCWLOpenLCandidateUI()
	-- end
end -- end func NewBangHui_Tmxx_BZTX_Clicked()

--*****************************************************************************
-- 城战轮换（霸者天下）是否在助战申请时间内
--*****************************************************************************
function NewBangHui_Tmxx_Check_BZTXAssistEnrollTime()
	local curWeekDay = DataPool:GetServerWeekDay()
	if (curWeekDay == 0) then
		-- 星期天特殊处理一下
		curWeekDay = 7
	end

	local beginDay = NewBangHui_Tmxx_AssistOpTime[1].weekday
	local beginTime = NewBangHui_Tmxx_AssistOpTime[1].begintime
	local endDay = NewBangHui_Tmxx_AssistOpTime[2].weekday
	local endTime = NewBangHui_Tmxx_AssistOpTime[2].endtime

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
end -- end func NewBangHui_Tmxx_Check_BZTXAssistEnrollTime()