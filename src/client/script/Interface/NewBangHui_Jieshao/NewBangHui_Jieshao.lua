

g_NewBangHui_Ctrl = {}

local g_SelectId = 3 --县衙的ID

local g_NewBangHui_Jieshao_Frame_UnifiedPosition = nil
local g_MatchTestBeginTime = 20141218			--点击雄霸天下按钮时进行以下判断,当前时间是否处于2014年12月18日0点之后
local g_MatchTestBeg_LM	= 20141128				-- 龙门测试赛开始时间

-- 城战轮换（霸者天下）助战操作时间
local NewBangHui_Jieshao_AssistOpTime =
{
    [1] = {weekday = 5, begintime = 213000},
    [2] = {weekday = 6, endtime = 202000},
} -- end NewBangHui_Jieshao_AssistOpTime

function NewBangHui_Jieshao_PreLoad()
	this:RegisterEvent("OPEN_BUILD_INTRODUCE")
	this:RegisterEvent( "GUILD_SHOW_DETAILINFO" )
	this:RegisterEvent("UPDATE_GUILD_LEAGUE_INFO")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("GUILD_SHOW_MEMBERINFO")
	this:RegisterEvent("GUILD_SHOW_ENEMYLIST")
	this:RegisterEvent("GUILD_LEAGUE_INFO")
	this:RegisterEvent("OPEN_GUILD_GIFT")
	this:RegisterEvent("GUILD_ZHANTUAN_OP")
	
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("SHOW_GUILDWAR_ANIMI")
	this:RegisterEvent("ZHANTUAN_LIST_DATA");
	this:RegisterEvent("OPENMYALLIANCE");
	this:RegisterEvent("GUILD_BIDDING_SHOWLIST")
	--this:RegisterEvent("TCITYWARLIMIT_OPENCANDIDATE")
end

function NewBangHui_Jieshao_OnLoad()

	g_NewBangHui_Jieshao_Frame_UnifiedPosition = NewBangHui_Jieshao_Frame:GetProperty("UnifiedPosition");

	g_NewBangHui_Ctrl = {
		info = NewBangHui_Jieshao_Frame2_Lace2_P1_List;
		
		[1] = { button = NewBangHui_Jieshao_Tiangongfang_Pic,	--天工坊
					str = "#{BHJZJS_140526_15}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Tiangongfang_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Tiangongfang_Normal"},
		[2] = { button = NewBangHui_Jieshao_Duantai_Pic,		--段太
					str = "#{BHJZJS_140526_06}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Duantai_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Duantai_Normal"},
		[3] = { button = NewBangHui_Jieshao_Xianya_Pic, --县衙
					str = "#{BHJZJS_140526_03}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Xianya_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Xianya_Normal"},
		[4] = { button = NewBangHui_Jieshao_Wufang_Pic,	--武坊
					str = "#{BHJZJS_140526_09}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Wufang_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Wufang_Normal"},		
		[5] = { button = NewBangHui_Jieshao_Baibaofang_Pic, --百宝坊
					str = "#{BHJZJS_140526_13}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Baibaofang_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Baibaofang_Normal"},
		[6] = { button = NewBangHui_Jieshao_Xiangfang_Pic, --厢房
					str = "#{BHJZJS_140526_04}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Xiangfang_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Xiangfang_Normal"},
		[7] = { button = NewBangHui_Jieshao_Qianzhuang_Pic, --钱庄
					str = "#{BHJZJS_140526_05}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Qianzhuang_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Qianzhuang_Normal"},
		[8] = { button = NewBangHui_Jieshao_Jiusi_Pic, --酒肆
					str = "#{BHJZJS_140526_16}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Jiusi_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Jiusi_Normal"},
		[9] = { button = NewBangHui_Jieshao_Shufang_Pic, --书房
					str = "#{BHJZJS_140526_10}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Shufang_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Shufang_Normal"},
		[10] = { button = NewBangHui_Jieshao_Micang_Pic, --米仓
					str = "#{BHJZJS_140526_07}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Micang_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Micang_Normal"},
		[11] = { button = NewBangHui_Jieshao_Jifang_Pic, --集坊
					str = "#{BHJZJS_140526_08}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Jifang_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Jifang_Normal"},
		[12] = { button = NewBangHui_Jieshao_Yishe_Pic, --衣舍
					str = "#{BHJZJS_140526_17}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Yishe_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Yishe_Normal"},
		[13] = { button = NewBangHui_Jieshao_Jiaochang_Pic, --校场
					str = "#{BHJZJS_140526_11}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Jiaochang_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Jiaochang_Normal"},
		[14] = { button = NewBangHui_Jieshao_Lianjinfang_Pic, --炼金坊
					str = "#{BHJZJS_140526_12}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Lianjinfang_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Lianjinfang_Normal"},
		[15] = { button = NewBangHui_Jieshao_Shenbingge_Pic, --神兵阁
					str = "#{BHJZJS_140526_14}",
					HoverImage = "set:BHJS_01 image:BHJS_01_Shenbingge_Hover",
					NormalImage = "set:BHJS_01 image:BHJS_01_Shenbingge_Normal"},
					
		
	}
					 
	
	
end


function NewBangHui_Jieshao_Tiangongfang_PicClick()
	NewBangHui_Jieshao_ButtonClick(1)
end

function NewBangHui_Jieshao_Duantai_PicClick()
	NewBangHui_Jieshao_ButtonClick(2)
end

function NewBangHui_Jieshao_Xianya_PicClick()
	NewBangHui_Jieshao_ButtonClick(3)
end

function NewBangHui_Jieshao_Wufang_PicClick()
	NewBangHui_Jieshao_ButtonClick(4)
end

function NewBangHui_Jieshao_Baibaofang_PicClick()
	NewBangHui_Jieshao_ButtonClick(5)
end

function NewBangHui_Jieshao_Xiangfang_PicClick()
	NewBangHui_Jieshao_ButtonClick(6)
end

function NewBangHui_Jieshao_Qianzhuang_PicClick()
	NewBangHui_Jieshao_ButtonClick(7)
end

function NewBangHui_Jieshao_Jiusi_PicClick()
	NewBangHui_Jieshao_ButtonClick(8)
end

function NewBangHui_Jieshao_Shufang_PicClick()
	NewBangHui_Jieshao_ButtonClick(9)
end

function NewBangHui_Jieshao_Micang_PicClick()
	NewBangHui_Jieshao_ButtonClick(10)
end

function NewBangHui_Jieshao_Jifang_PicClick()
	NewBangHui_Jieshao_ButtonClick(11)
end

function NewBangHui_Jieshao_Yishe_PicClick()
	NewBangHui_Jieshao_ButtonClick(12)
end

function NewBangHui_Jieshao_Jiaochang_PicClick()
	NewBangHui_Jieshao_ButtonClick(13)
end

function NewBangHui_Jieshao_Lianjinfang_PicClick()
	NewBangHui_Jieshao_ButtonClick(14)
end

function NewBangHui_Jieshao_Shenbingge_PicClick()
	NewBangHui_Jieshao_ButtonClick(15)
end

function NewBangHui_Jieshao_OnEvent(event)
	if (event == "OPEN_BUILD_INTRODUCE") then
		NewBangHui_Jieshao_SetDynamic_Pos()
		NewBangHui_Jieshao_JZWJS:SetCheck(1)
		NewBangHui_Jieshao_ButtonClick(g_SelectId)
		g_NewBangHui_Ctrl.info:SetText("#{BHJZJS_140526_02}")
		NewBangHui_Jieshao_SetTitle()
		this:Show()

		-- -- 霸者天下小红点
		-- local bztxApplyNum = DataPool:TCWLGetAssistApplyNum()
		-- local bztxIsInTime = NewBangHui_Jieshao_Check_BZTXAssistEnrollTime()
		-- if (bztxIsInTime > 0) then
		-- 	if (bztxApplyNum <= 0) then
		-- 		NewBangHui_Jieshao_BZTX_Tips:Hide()
		-- 	else
		-- 		local isChiefOrAss = Guild:IsChieforAss()
		-- 		if (isChiefOrAss ~= 1) then
		-- 			NewBangHui_Jieshao_BZTX_Tips:Hide()
		-- 		else
		-- 			NewBangHui_Jieshao_BZTX_Tips:Show()
		-- 		end
		-- 	end
		-- else
		-- 	NewBangHui_Jieshao_BZTX_Tips:Hide()
		-- end
	elseif (event == "GUILD_SHOW_DETAILINFO") or
		(event == "UI_COMMAND" and tonumber(arg0)==1208) then

		NewBangHui_Jieshao_Close()
	elseif (event == "GUILD_SHOW_MEMBERINFO") then
		NewBangHui_Jieshao_Close()
	elseif (event == "GUILD_SHOW_ENEMYLIST") then
		NewBangHui_Jieshao_Close()
	elseif (event == "GUILD_LEAGUE_INFO") then
		NewBangHui_Jieshao_Close()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		NewBangHui_Jieshao_Close()
	elseif ( event == "ZHANTUAN_LIST_DATA" ) then
		NewBangHui_Jieshao_Close()
	elseif (event == "ADJEST_UI_POS") then
		NewBangHui_Jieshao_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewBangHui_Jieshao_Frame_On_ResetPos()
	elseif (event == "SHOW_GUILDWAR_ANIMI" ) then
		local type = arg0;
		if (arg0 == "show") then
			NewBangHui_Jieshao_Bhxz:SetText("#g0071BF#{BHJM_140520_04}")
			NewBangHui_Jieshao_Bhxz:SetToolTip("你的帮会正在帮战");
		else
		    NewBangHui_Jieshao_Bhxz:SetText("#{BHJM_140520_04}");
			NewBangHui_Jieshao_Bhxz:SetToolTip("");
		end
	elseif event == "OPENMYALLIANCE" then
		NewBangHui_Jieshao_Close()
	elseif (event == "OPEN_GUILD_GIFT" ) then
		NewBangHui_Jieshao_Close()
	elseif event == "GUILD_BIDDING_SHOWLIST" then
		NewBangHui_Jieshao_Close()
	elseif event == "TCITYWARLIMIT_OPENCANDIDATE" then
		NewBangHui_Jieshao_Close()
	elseif event == "GUILD_ZHANTUAN_OP" then
		NewBangHui_Hygl_Closed()
	end
end

function NewBangHui_Jieshao_KVKLeague_Clicked()
	local alliancemark = 0;
end

function NewBangHui_Jieshao_ButtonClick(idx)
	NewBangHui_Jieshao_Frame2_Lace2_P2_List:SetText(g_NewBangHui_Ctrl[idx].str)
	for i = 1, 15 do
		if idx == i then
			g_NewBangHui_Ctrl[i ].button:SetProperty("NormalImage", g_NewBangHui_Ctrl[i ].HoverImage)
		else
			g_NewBangHui_Ctrl[i ].button:SetProperty("NormalImage", g_NewBangHui_Ctrl[i ].NormalImage)
		end	
	end
	g_SelectId = idx
end

function NewBangHui_Jieshao_Szxx_Close_Clicked()
	NewBangHui_Jieshao_Close()
end

function NewBangHui_Jieshao_Close()
	this:Hide()
end
function NewBangHui_Jieshao_Hygl_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Jieshao_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ToggleGuildDetailInfo()
end

function NewBangHui_Jieshao_JZWJS_Clicked()

end

function NewBangHui_Jieshao_Bhxx_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Jieshao_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:AskGuildDetailInfo();
	Guild:CloseKickGuildBox();	
end

function NewBangHui_Jieshao_Tmxx_Clicked()
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
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Jieshao_Frame:GetProperty("UnifiedPosition"), 1);
    GuildLeague:ShowInfoWindow()
end

function NewBangHui_Jieshao_Bhxz_Clicked()
   Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Jieshao_Frame:GetProperty("UnifiedPosition"), 1);
	City:OpenNewGuildWarDlg();
	Guild:CloseKickGuildBox();
	NewBangHui_Jieshao_JZWJS:SetCheck(1)
end

--拍卖
function NewBangHui_Jieshao_Auction_Clicked()
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
  Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Jieshao_Frame:GetProperty("UnifiedPosition"), 1);
  Guild:AskGuildBiddingInfo(0, 1, -1)
end

function NewBangHui_Jieshao_BZZT_Clicked()
	local selfzoneid = DataPool:GetSelfZoneWorldID()
	if (KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(181) > 0) or 
		DataPool:Lua_IsNewServerPlayerByZWID(selfzoneid) == 1 or
		Player:GetData("IsOriginalJD")  == 1 or
		Player:GetData("Is2606S")  == 1 or 
		Player:GetData("SPECKAJI89") > 0 then
	  PushDebugMessage("#{ZTXT_260511_151}")
	  return
	end
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Jieshao_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("GUILD_ZHANTUAN_OP", 1)
 end

function NewBangHui_Jieshao_Frame_On_ResetPos()
	 NewBangHui_Jieshao_Frame:SetProperty("UnifiedPosition", g_NewBangHui_Jieshao_Frame_UnifiedPosition)
end

function NewBangHui_Jieshao_SetDynamic_Pos()
    local selfGuildClanUnionPos = Variable:GetVariable("SelfGuildClanUnionPos")
	if( selfGuildClanUnionPos ~= nil) then
	    NewBangHui_Jieshao_Frame:SetProperty("UnifiedPosition", selfGuildClanUnionPos )
	end
end

function NewBangHui_Jieshao_SetTitle()
	local szName = Guild:GetMyGuildName("Name");
	local title = ScriptGlobal_Format("#{BHJM_140520_01}", szName)
	NewBangHui_Jieshao_PageHeader:SetText(title)
end

--帮会联赛 by wangbin
function NewBangHui_Jieshao_BHLS_Clicked()
	local nCurTime = tonumber(DataPool:GetServerDayTime());
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID();
	if selfZoneWorldID == 9031 or selfZoneWorldID == 9015 then
		if ( nCurTime < g_MatchTestBeg_LM ) then
			PushDebugMessage( "#{BHKF_140909_419}" );
			NewBangHui_Jieshao_JZWJS:SetCheck(1);
			Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Jieshao_Frame:GetProperty("UnifiedPosition"), 1);
			return
		end
	else
		if ( nCurTime < g_MatchTestBeginTime ) then
			PushDebugMessage( "#{BHKF_140909_419}" );
			NewBangHui_Jieshao_JZWJS:SetCheck(1);
			Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Jieshao_Frame:GetProperty("UnifiedPosition"), 1);
			return
		end
	end
	
	local nStatus = ZhanTuanInterface:GetZhanTuanInfo();
	if(0 == tonumber(nStatus)) then
		NewBangHui_Jieshao_JZWJS:SetCheck(1)
	end
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Jieshao_Frame:GetProperty("UnifiedPosition"), 1);
end


function NewBangHui_Jieshao_HB_OnClicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Jieshao_Frame:GetProperty("UnifiedPosition"), 1)
	Guild:OpentGuildGiftUI()
end

function NewBangHui_Jieshao_BZTX_Clicked()
	-- if (Player:GetData("TCWLSvrOpenFlag") < 0) then
	-- 	NewBangHui_Jieshao_BZTX:SetCheck(0)
	-- 	NewBangHui_Jieshao_JZWJS:SetCheck(1)

	-- 	PushDebugMessage("#{GCQH_240429_161}")
	-- elseif (Player:GetData("TCWLSvrOpenFlag") == 0) then
	-- 	NewBangHui_Jieshao_BZTX:SetCheck(0)
	-- 	NewBangHui_Jieshao_JZWJS:SetCheck(1)
		
	-- 	PushDebugMessage("#{GCQH_240429_154}")
	-- else
	-- 	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Jieshao_Frame:GetProperty("UnifiedPosition"), 1)
	-- 	Guild:TCWLOpenLCandidateUI()
	-- end
end -- end func NewBangHui_Jieshao_BZTX_Clicked()

--*****************************************************************************
-- 城战轮换（霸者天下）是否在助战申请时间内
--*****************************************************************************
function NewBangHui_Jieshao_Check_BZTXAssistEnrollTime()
	local curWeekDay = DataPool:GetServerWeekDay()
	if (curWeekDay == 0) then
		-- 星期天特殊处理一下
		curWeekDay = 7
	end

	local beginDay = NewBangHui_Jieshao_AssistOpTime[1].weekday
	local beginTime = NewBangHui_Jieshao_AssistOpTime[1].begintime
	local endDay = NewBangHui_Jieshao_AssistOpTime[2].weekday
	local endTime = NewBangHui_Jieshao_AssistOpTime[2].endtime

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
end -- end func NewBangHui_Jieshao_Check_BZTXAssistEnrollTime()