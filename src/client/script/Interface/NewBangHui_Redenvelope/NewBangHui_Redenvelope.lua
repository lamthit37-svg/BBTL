

local m_LeftGiftState = 0			--0 左边发红包状态 1 查看记录状态
local m_RightGiftState = 0			--0 右边发红包状态 1 常看记录状态

local m_LeftLogIndex = 0			--0 左边最近的日志 1 前一个	2	最后一个
local m_RightLogIndex = 0 			--0 右边最近的日志 1 前一个	2 	最后一个

local m_LeftLogList
local m_RightLogList

local m_Last_Left
local m_Last_Right

local m_Next_Left
local m_Next_Right

local m_Back_Left
local m_Back_Right

local m_BigLuckyValue_TEXT
local m_RGDIC_TEXT

local m_MaxLogCountLeft = 0
local m_MaxLogCountRight = 0

local m_LogFrame_L
local m_LogFrame_R
local m_DeliverFrame_L
local m_DeliverFrame_R

local m_LogTitle_L
local m_LogTitle_R

local m_MaxBigLuckyValue = 50000

local g_MatchTestBeginTime = 20141218			--点击雄霸天下按钮时进行以下判断,当前时间是否处于2014年12月18日0点之后
local g_MatchTestBeg_LM	= 20141128				-- 龙门测试赛开始时间

-- 城战轮换（霸者天下）助战操作时间
local NewBangHui_Redenvelope_AssistOpTime =
{
    [1] = {weekday = 5, begintime = 213000},
    [2] = {weekday = 6, endtime = 202000},
} -- end NewBangHui_Redenvelope_AssistOpTim

function NewBangHui_Redenvelope_PreLoad()

	this:RegisterEvent("OPEN_GUILD_GIFT")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("GUILD_FORCE_CLOSE")
	this:RegisterEvent("SHOW_GUILDWAR_ANIMI")
	
	this:RegisterEvent("GUILD_SHOW_MEMBERINFO")
	this:RegisterEvent("GUILD_SHOW_DETAILINFO")
	this:RegisterEvent("GUILD_LEAGUE_INFO")	
	this:RegisterEvent("GUILD_SHOW_ENEMYLIST")
	this:RegisterEvent("ZHANTUAN_LIST_DATA")
	this:RegisterEvent("OPENMYALLIANCE")
	this:RegisterEvent("OPEN_BUILD_INTRODUCE")
	this:RegisterEvent("BLV_CHANGE")
	this:RegisterEvent("RGDIC_CHANGE")
	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("REFRESH_GUILDGIFT_TAKETIMES")
	this:RegisterEvent("OPEN_GUILD_GIFT_LOG")
	this:RegisterEvent("GUILD_BIDDING_SHOWLIST")
	this:RegisterEvent("GUILD_ZHANTUAN_OP")
	--this:RegisterEvent("TCITYWARLIMIT_OPENCANDIDATE")
end

function NewBangHui_Redenvelope_OnLoad()
	
	m_LeftLogList = NewBangHui_Redenvelope_Frame2_Lace2_List
	m_RightLogList = NewBangHui_Redenvelope_Frame2_Lace3_List

	m_Last_Left = NewBangHui_Redenvelope_Frame2_Button
	m_Last_Right = NewBangHui_Redenvelope_Frame2_Button3

	m_Next_Left = NewBangHui_Redenvelope_Frame2_Button1
	m_Next_Right = NewBangHui_Redenvelope_Frame2_Button4

	m_Back_Left = NewBangHui_Redenvelope_Frame2_Button2
	m_Back_Right = NewBangHui_Redenvelope_Frame2_Button5
	
	m_BigLuckyValue_TEXT = NewBangHui_Redenvelope_Frame2_Lace3_Text
	m_RGDIC_TEXT = NewBangHui_Redenvelope_Frame2_Lace3_Text1
	
	m_LogFrame_L = NewBangHui_Redenvelope_Frame2_Lace2
	m_LogFrame_R = NewBangHui_Redenvelope_Frame2_Lace3
	m_DeliverFrame_L = NewBangHui_Redenvelope_Frame2_Lace4
	m_DeliverFrame_R = NewBangHui_Redenvelope_Frame2_Lace5
	
	m_LogTitle_L = NewBangHui_Redenvelope_Frame2_Lace2_Title_Text
	m_LogTitle_R = NewBangHui_Redenvelope_Frame2_Lace3_Title_Text
end

function NewBangHui_Redenvelope_OnEvent(event)

	if event == "OPEN_GUILD_GIFT" then
		NewBangHui_Redenvelope_Show()
	end
	
	if event == "BLV_CHANGE" and this:IsVisible() then
		
		local nBLV =  Player:GetData("BLV")
		local strTemp = ScriptGlobal_Format("#{BHHB_160516_09}", tostring(nBLV) , tostring(m_MaxBigLuckyValue))
		m_BigLuckyValue_TEXT:SetText(strTemp)

		return
	end
	
	if event == "RGDIC_CHANGE" and this:IsVisible() then
		
		local nRGDIC =  Player:GetData("RGDIC")
		
		if tonumber(nRGDIC) == 0 then
			m_RGDIC_TEXT:SetText("#{BHHB_160516_86}")
		else
			local strTemp = ScriptGlobal_Format("#{BHHB_160516_10}", tostring(nRGDIC))
			m_RGDIC_TEXT:SetText(strTemp)
		end
		return
	end
	
	if event == "GUILD_SHOW_MEMBERINFO" then
		this:Hide()
		return
	end
	--互斥
	if event == "GUILD_SHOW_DETAILINFO" then
		this:Hide()
		return	
	end
	--互斥
	if event == "GUILD_LEAGUE_INFO" then
		this:Hide()
		return
	end
	--互斥
	if event == "GUILD_SHOW_ENEMYLIST" then
		this:Hide()
		return
	end
	--互斥
	if event == "ZHANTUAN_LIST_DATA" then
		this:Hide()
		return
	end
	--互斥
	if event == "OPENMYALLIANCE" then
		this:Hide()
		return
	end
	--互斥
	if event == "OPEN_BUILD_INTRODUCE" then
		this:Hide()
		return
	end
	if event == "GUILD_FORCE_CLOSE" then
		this:Hide()
		return
	end
		
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end

	if event == "SHOW_GUILDWAR_ANIMI" then
		local type = arg0
		if arg0 == "show" then
			NewBangHui_Redenvelope_Bhxz:SetText("#g0071BF#{BHJM_140520_04}")
			NewBangHui_Redenvelope_Bhxz:SetToolTip("你的帮会正在帮战")
		else
		    NewBangHui_Redenvelope_Bhxz:SetText("#{BHJM_140520_04}")
			NewBangHui_Redenvelope_Bhxz:SetToolTip("")
		end
	end

	if (event == "UI_COMMAND" and tonumber(arg0) == 20160701) then
		m_guildname = Get_XParam_STR(0)
		local szName = Guild:GetMyGuildName("Name");
		if szName == "" or szName == nil then
			Guild:SaveMyGuildName(m_guildname)
		end
		Guild:OpentGuildGiftUI()
	end
	
	if event == "REFRESH_GUILDGIFT_TAKETIMES" then
		NewBangHui_Redenvelope_RefreshTakeTimes(tonumber(arg0),tonumber(arg1))
		return
	end
	
	if event == "OPEN_GUILD_GIFT_LOG" then
		if tonumber(arg0) == 0 then
			NewBangHui_Redenvelope_Log_Left_Show()
		elseif tonumber(arg0) == 1 then
			NewBangHui_Redenvelope_Log_Right_Show()
		end
		return
	end
	
	if event == "GUILD_BIDDING_SHOWLIST" then
		this:Hide()
		return
	end

	if event == "TCITYWARLIMIT_OPENCANDIDATE" then
		this:Hide()
		return
	end
	if event == "GUILD_ZHANTUAN_OP" then
		this:Hide()
		return
	end
end

function NewBangHui_Redenvelope_Clear()

	m_LeftGiftState = 0	
	m_RightGiftState = 0
	m_LeftLogIndex = 0
	m_RightLogIndex = 0
	
	m_BigLuckyValue_TEXT:SetText("")
	m_RGDIC_TEXT:SetText("")

end

function NewBangHui_Redenvelope_Show()
	
	local selfGuildClanUnionPos = Variable:GetVariable("SelfGuildClanUnionPos")
	if( selfGuildClanUnionPos ~= nil) then
	    NewBangHui_Redenvelope_Frame:SetProperty("UnifiedPosition", selfGuildClanUnionPos )
	end
	
	NewBangHui_Redenvelope_Clear()
	
	m_LeftLogList:CleanAllElement("NewBangHui_Redenvelope")
	m_RightLogList:CleanAllElement("NewBangHui_Redenvelope")

	NewBangHui_Redenvelope_Refresh_Left()
	NewBangHui_Redenvelope_Refresh_Right()
	
	NewBangHui_Redenvelope_SetTitle()
	NewBangHui_Redenvelope_HB:SetCheck(1)
	
	local nBLV =  Player:GetData("BLV")
	local nRGDIC =  Player:GetData("RGDIC")
	local strTemp = ScriptGlobal_Format("#{BHHB_160516_09}", tostring(nBLV),tostring(m_MaxBigLuckyValue))
	m_BigLuckyValue_TEXT:SetText(strTemp)
	
	if tonumber(nRGDIC) == 0 then
		m_RGDIC_TEXT:SetText("#{BHHB_160516_86}")
	else
		local strTemp = ScriptGlobal_Format("#{BHHB_160516_10}", tostring(nRGDIC))
		m_RGDIC_TEXT:SetText(strTemp)
	end
	
	local bStopMsg = Variable:GetVariable("StopGuildGiftMsg")
	if bStopMsg == "1" then
		NewBangHui_Redenvelope_Check:SetCheck(1)
	else
		NewBangHui_Redenvelope_Check:SetCheck(0)
	end

	if Player:GetData("Is2606S") == 1 then
		NewBangHui_Redenvelope_Text1:SetText("#{QXF_260623_158}")
	else
		NewBangHui_Redenvelope_Text1:SetText("#{BHHB_160516_03}")
	end
	this:Show()

	-- -- 霸者天下小红点
	-- local bztxApplyNum = DataPool:TCWLGetAssistApplyNum()
	-- local bztxIsInTime = NewBangHui_Redenvelope_Check_BZTXAssistEnrollTime()
	-- if (bztxIsInTime > 0) then
	-- 	if (bztxApplyNum <= 0) then
	-- 		NewBangHui_Redenvelope_BZTX_Tips:Hide()
	-- 	else
	-- 		local isChiefOrAss = Guild:IsChieforAss()
	-- 		if (isChiefOrAss ~= 1) then
	-- 			NewBangHui_Redenvelope_BZTX_Tips:Hide()
	-- 		else
	-- 			NewBangHui_Redenvelope_BZTX_Tips:Show()
	-- 		end
	-- 	end
	-- else
	-- 	NewBangHui_Redenvelope_BZTX_Tips:Hide()
	-- end
end

function NewBangHui_Redenvelope_Refresh_Left()
	
	if m_LeftGiftState == 0 then
	
		m_LogFrame_L:Hide()
		m_DeliverFrame_L:Show()
		
	else
	
		m_LogFrame_L:Show()
		m_DeliverFrame_L:Hide()
		
		NewBangHui_Redenvelope_Frame2_Lace2_List_Image:Hide()

		if m_MaxLogCountLeft > 0 then
			
			local str_log_index = ScriptGlobal_Format("#{BHHB_160516_79}", tostring(m_LeftLogIndex + 1),tostring(m_MaxLogCountLeft))
			NewBangHui_Redenvelope_Frame2_Lace2_Title_Text1:SetText(str_log_index)
			
			if m_LeftLogIndex <= 0 then
				m_Next_Left:Disable()
			else
				m_Next_Left:Enable()
			end
			
			if m_LeftLogIndex >= m_MaxLogCountLeft - 1 then
				m_Last_Left:Disable()
			else
				m_Last_Left:Enable()
			end
			
			m_LeftLogList:Show()
			
			m_LeftLogList:CleanAllElement("NewBangHui_Redenvelope")
			
			local num = 0
			for i = 1, 20 do
				local _,szName,nType,nItemID,nCount,nBest,nLogTime = Guild:GetGuildGiftLog(0,m_LeftLogIndex , i - 1)				
				if szName ~= nil then
					local ItemBar = m_LeftLogList:AddItemElement( "RedenvelopeLogButton", "LEFT", "NewBangHui_Redenvelope","" ,"")
					ItemBar:SetText1( "#c2ebeff"..tostring(szName) )
					
					if nType == 1 then

					elseif nType == 2 then
						local item_name = DataPool:Lua_GetItemNameByIndex(nItemID)
						if nBest == 1 then
							ItemBar:SetImage1Show()	
						else
							ItemBar:SetImage1Hide()
						end	
						ItemBar:SetText2( "#cfff263"..tostring(item_name) )			
					end
					num = num + 1
				end
			end
			
			m_LeftLogList:Flash()
			
			if num == 0 then
				NewBangHui_Redenvelope_Frame2_Lace2_ListText:Show()
				m_LeftLogList:Hide()
			else
				NewBangHui_Redenvelope_Frame2_Lace2_ListText:Hide()
			end
			
			local owner_name = Guild:GetGuildGiftLogOwnerName(0 , m_LeftLogIndex)
			if owner_name ~= nil then
				local str_title = ScriptGlobal_Format("#{BHHB_160516_19}", tostring(owner_name))
				m_LogTitle_L:SetText(str_title)
			end

		else
			m_Last_Left:Disable()
			m_Next_Left:Disable()
			m_LeftLogList:Hide()	
		end

	end
end

function NewBangHui_Redenvelope_Refresh_Right()
	
	if m_RightGiftState == 0 then
	
		m_LogFrame_R:Hide()
		m_DeliverFrame_R:Show()
		
	else
		
		m_LogFrame_R:Show()
		m_DeliverFrame_R:Hide()
		
		NewBangHui_Redenvelope_Frame2_Lace3_List_Image:Hide()
		
		if m_MaxLogCountRight > 0 then
			
			local str_log_index = ScriptGlobal_Format("#{BHHB_160516_80}", tostring(m_RightLogIndex + 1),tostring(m_MaxLogCountRight))
			NewBangHui_Redenvelope_Frame2_Lace3_Title_Text1:SetText(str_log_index)
			
			if m_RightLogIndex <= 0 then
				m_Next_Right:Disable()
			else
				m_Next_Right:Enable()
			end
			
			if m_RightLogIndex >= m_MaxLogCountRight - 1 then
				m_Last_Right:Disable()
			else
				m_Last_Right:Enable()
			end
			
			m_RightLogList:Show()
			
			m_RightLogList:CleanAllElement("NewBangHui_Redenvelope")
			
			local num = 0
			for i = 1, 20 do
				local _,szName,nType,nItemID,nCount,nBest,nLogTime = Guild:GetGuildGiftLog(1 , m_RightLogIndex , i - 1)
				if szName ~= nil then
					local ItemBar = m_RightLogList:AddItemElement( "RedenvelopeLogButton", "LEFT", "NewBangHui_Redenvelope","" ,"")
					ItemBar:SetText1( "#c2ebeff"..tostring(szName) )
					
					if nType == 1 then

					elseif nType == 2 then
						local item_name = DataPool:Lua_GetItemNameByIndex(nItemID)
						if nBest == 1 then
							ItemBar:SetImage1Show()	
						else
							ItemBar:SetImage1Hide()
						end
						ItemBar:SetText2( "#cfff263"..tostring(item_name) )					
					end
					num = num + 1
				end
			end
			
			m_RightLogList:Flash()
			
			if num == 0 then
				NewBangHui_Redenvelope_Frame2_Lace3_ListText:Show()
				m_RightLogList:Hide()
			else
				NewBangHui_Redenvelope_Frame2_Lace3_ListText:Hide()
			end
			
			local owner_name = Guild:GetGuildGiftLogOwnerName(1 , m_RightLogIndex)
			if owner_name ~= nil then
				local str_title = ScriptGlobal_Format("#{BHHB_160516_39}", tostring(owner_name))
				m_LogTitle_R:SetText(str_title)
			end
		else
			m_Last_Right:Disable()
			m_Next_Right:Disable()
			m_RightLogList:Hide()		
		end
	end	
end
--发红包 左
function NewBangHui_Redenvelope_Deliver_Left_Clicked()
	
	Guild:DeliverGuildGift(0)

end
--查看记录 左
function NewBangHui_Redenvelope_Log_Left_Clicked()
	Guild:AskGuildGiftLog(0)
end

function NewBangHui_Redenvelope_Log_Left_Show()

	local nGiftCount = Guild:GetGuildGiftCount(0)
	if nGiftCount > 0 then
		
		m_LeftGiftState = 1
		m_LeftLogIndex = 0
		m_MaxLogCountLeft = nGiftCount
		NewBangHui_Redenvelope_Refresh_Left()
		
	else
		PushDebugMessage("#{BHHB_160516_62}")
	end

end
--上一页 左
function NewBangHui_Redenvelope_Last_Left_Clicked()

	if m_LeftLogIndex < m_MaxLogCountLeft - 1 then
		m_LeftLogIndex = m_LeftLogIndex + 1
		NewBangHui_Redenvelope_Refresh_Left()
	end

end
--下一页 左
function NewBangHui_Redenvelope_Next_Left_Clicked()
	
	if m_LeftLogIndex > 0 then
		m_LeftLogIndex = m_LeftLogIndex - 1
		NewBangHui_Redenvelope_Refresh_Left()
	end

end
--发红包 右
function NewBangHui_Redenvelope_Deliver_Right_Clicked()

	Guild:DeliverGuildGift(1)

end
--查看记录 右
function NewBangHui_Redenvelope_Log_Right_Clicked()
	Guild:AskGuildGiftLog(1)
end

function NewBangHui_Redenvelope_Log_Right_Show()

	local nGiftCount = Guild:GetGuildGiftCount(1)
	if nGiftCount > 0 then
		
		m_RightGiftState = 1
		m_RightLogIndex = 0
		m_MaxLogCountRight = nGiftCount	
		NewBangHui_Redenvelope_Refresh_Right()
		
	else
		PushDebugMessage("#{BHHB_160516_63}")
	end

end
--上一页 右
function NewBangHui_Redenvelope_Last_Right_Clicked()

	if m_RightLogIndex < m_MaxLogCountRight - 1 then
		m_RightLogIndex = m_RightLogIndex + 1
		NewBangHui_Redenvelope_Refresh_Right()
	end

end
--下一页 右
function NewBangHui_Redenvelope_Next_Right_Clicked()

	if m_RightLogIndex > 0 then

		m_RightLogIndex = m_RightLogIndex - 1
		NewBangHui_Redenvelope_Refresh_Right()
	end

end
--返回 左
function NewBangHui_Redenvelope_Back_Left_Clicked()
	if m_LeftGiftState == 1 then
	
		--返回
		m_LeftGiftState = 0
		NewBangHui_Redenvelope_Refresh_Left()
	end
end
--返回 右
function NewBangHui_Redenvelope_Back_Right_Clicked()
	if m_RightGiftState == 1 then
	
		--返回
		m_RightGiftState = 0
		NewBangHui_Redenvelope_Refresh_Right()
	end
end

function NewBangHui_Redenvelope_OnHidden()

	NewBangHui_Redenvelope_Clear()
	m_LeftLogList:CleanAllElement("NewBangHui_Redenvelope")
	m_RightLogList:CleanAllElement("NewBangHui_Redenvelope")
end

function NewBangHui_Redenvelope_Closed()

	this:Hide()
end

function NewBangHui_Redenvelope_SetTitle()
	local szName = Guild:GetMyGuildName("Name");
	local title = ScriptGlobal_Format("#{BHJM_140520_01}", szName)
	NewBangHui_Redenvelope_DragTitle:SetText(title)
end

function NewBangHui_Redenvelope_StopMsg_Clicked()
	
	local bStopMsg = Variable:GetVariable("StopGuildGiftMsg")
	if bStopMsg == nil or bStopMsg == "0" then
		Variable:SetVariable("StopGuildGiftMsg" , "1" , 0)
	else
		Variable:SetVariable("StopGuildGiftMsg" , "0" , 0)
	end
	
end

function NewBangHui_Redenvelope_KVKLeague_Clicked()
	local alliancemark = 0;
end
--成员管理
function NewBangHui_Redenvelope_Hygl_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Redenvelope_Frame:GetProperty("UnifiedPosition"), 1)
    Guild:ToggleGuildDetailInfo()
end
--帮会信息
function NewBangHui_Redenvelope_Bhxx_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Redenvelope_Frame:GetProperty("UnifiedPosition"), 1)
    Guild:AskGuildDetailInfo()
	Guild:CloseKickGuildBox()
end
--帮会同盟
function NewBangHui_Redenvelope_Tmxx_Clicked()
	--在K服只有服务器配置保留原服"帮会同盟"信息的时候,才响应相应的按钮事件
	if KVKInterface:IsInKVKServer() == 1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
		PushDebugMessage("#{KVKBH_140124_66}")
		return
	end
	
    local id=Player:GetData("GUILDLEAGUE")
	if id == nil or id < 0 then
        PushDebugMessage( "#{KVKSL_110628_305}" )
        return
	end
	
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Redenvelope_Frame:GetProperty("UnifiedPosition"), 1)
    GuildLeague:ShowInfoWindow()
end
--帮会宣战
function NewBangHui_Redenvelope_Bhxz_Clicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Redenvelope_Frame:GetProperty("UnifiedPosition"), 1)
	City:OpenNewGuildWarDlg()
	Guild:CloseKickGuildBox()
	NewBangHui_Redenvelope_HB:SetCheck(1)
end
--拍卖
function NewBangHui_Redenvelope_Auction_Clicked()
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
  Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Redenvelope_Frame:GetProperty("UnifiedPosition"), 1);
  Guild:AskGuildBiddingInfo(0, 1, -1)
end
--
function NewBangHui_Redenvelope_BZZT_Clicked()
	local selfzoneid = DataPool:GetSelfZoneWorldID()
	if (KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(181) > 0) or 
		DataPool:Lua_IsNewServerPlayerByZWID(selfzoneid) == 1 or
		Player:GetData("IsOriginalJD")  == 1 or
		Player:GetData("Is2606S")  == 1 or 
		Player:GetData("SPECKAJI89") > 0 then
	  PushDebugMessage("#{ZTXT_260511_151}")
	  return
	end
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Redenvelope_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("GUILD_ZHANTUAN_OP", 1)
end

--雄霸天下
function NewBangHui_Redenvelope_BHLS_Clicked()
	local nCurTime = tonumber(DataPool:GetServerDayTime())
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	if selfZoneWorldID == 9031 or selfZoneWorldID == 9015 then
		if ( nCurTime < g_MatchTestBeg_LM ) then
			PushDebugMessage( "#{BHKF_140909_419}" )
			NewBangHui_Redenvelope_HB:SetCheck(1)
			Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Redenvelope_Frame:GetProperty("UnifiedPosition"), 1)
			return
		end
	else
		if ( nCurTime < g_MatchTestBeginTime ) then
			PushDebugMessage( "#{BHKF_140909_419}" )
			NewBangHui_Redenvelope_HB:SetCheck(1)
			Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Redenvelope_Frame:GetProperty("UnifiedPosition"), 1)
			return
		end
	end
	
	local nStatus = ZhanTuanInterface:GetZhanTuanInfo()
	if(0 == tonumber(nStatus)) then
		NewBangHui_Redenvelope_HB:SetCheck(1)
	end
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Redenvelope_Frame:GetProperty("UnifiedPosition"), 1)
end
--建筑物介绍
function NewBangHui_Redenvelope_JZWJS_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Redenvelope_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ShowCityBuildIntroduce()
end

function NewBangHui_Redenvelope_RefreshTakeTimes(nNormalTakeTimes , nRareTakeTimes)
	
	if nNormalTakeTimes == 3 then
		NewBangHui_Redenvelope_JL_HY:SetText("#{BHHB_160516_82}")
		local strTemp = ScriptGlobal_Format("#{BHHB_160516_84}", tostring(nNormalTakeTimes))
		NewBangHui_Redenvelope_JL_HY:SetToolTip(strTemp)
	else
		local strTemp = ScriptGlobal_Format("#{BHHB_160516_69}", tostring(nNormalTakeTimes))
		NewBangHui_Redenvelope_JL_HY:SetText(strTemp)
		
		strTemp = ScriptGlobal_Format("#{BHHB_160516_84}", tostring(nNormalTakeTimes))
		NewBangHui_Redenvelope_JL_HY:SetToolTip(strTemp)
	end
	
	if nRareTakeTimes == 3 then
		NewBangHui_Redenvelope_JL_HF:SetText("#{BHHB_160516_83}")
		local strTemp = ScriptGlobal_Format("#{BHHB_160516_85}", tostring(nRareTakeTimes))
		NewBangHui_Redenvelope_JL_HF:SetToolTip(strTemp)
	else
		local strTemp = ScriptGlobal_Format("#{BHHB_160516_70}", tostring(nRareTakeTimes))
		NewBangHui_Redenvelope_JL_HF:SetText(strTemp)
		
		strTemp = ScriptGlobal_Format("#{BHHB_160516_85}", tostring(nRareTakeTimes))
		NewBangHui_Redenvelope_JL_HF:SetToolTip(strTemp)
	end

end

function NewBangHui_Redenvelope_BZTX_Clicked()
	-- if (Player:GetData("TCWLSvrOpenFlag") < 0) then
	-- 	NewBangHui_Redenvelope_BZTX:SetCheck(0)
	-- 	NewBangHui_Redenvelope_HB:SetCheck(1)

	-- 	PushDebugMessage("#{GCQH_240429_161}")
	-- elseif (Player:GetData("TCWLSvrOpenFlag") == 0) then
	-- 	NewBangHui_Redenvelope_BZTX:SetCheck(0)
	-- 	NewBangHui_Redenvelope_HB:SetCheck(1)
		
	-- 	PushDebugMessage("#{GCQH_240429_154}")
	-- else
	-- 	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Redenvelope_Frame:GetProperty("UnifiedPosition"), 1);
	-- 	Guild:TCWLOpenLCandidateUI()
	-- end
end -- end func NewBangHui_Redenvelope_BZTX_Clicked()

--*****************************************************************************
-- 城战轮换（霸者天下）是否在助战申请时间内
--*****************************************************************************
function NewBangHui_Redenvelope_Check_BZTXAssistEnrollTime()
	local curWeekDay = DataPool:GetServerWeekDay()
	if (curWeekDay == 0) then
		-- 星期天特殊处理一下
		curWeekDay = 7
	end

	local beginDay = NewBangHui_Redenvelope_AssistOpTime[1].weekday
	local beginTime = NewBangHui_Redenvelope_AssistOpTime[1].begintime
	local endDay = NewBangHui_Redenvelope_AssistOpTime[2].weekday
	local endTime = NewBangHui_Redenvelope_AssistOpTime[2].endtime

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
end -- end func NewBangHui_Redenvelope_Check_BZTXAssistEnrollTime()