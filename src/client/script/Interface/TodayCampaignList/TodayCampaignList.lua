local 	g_nContentButton = {}

local campaign_today_recommended = 8
local campaign_today_timelimited = 9
local campaign_today_allday	= 10

local g_TodalCampaignCount = 0;		--今天的活动数目

-- 界面控件
local g_CurrentCampaignID = {};		--当前活动ID
local g_AllCampaignID = {};         --记录下所有活动ID

--请求数据标志
local g_Flag = 0
--当前分页
local g_PageNum = 1
--当前选中的项
local g_CurrentSelect = 0

local g_ItemActionButtonList = {}
local g_ItemActionNum = 10
-- 界面的默认相对位置
local g_TodayCampaignList_Frame_UnifiedXPosition;
local g_TodayCampaignList_Frame_UnifiedYPosition;

function TodayCampaignList_PreLoad()
	this:RegisterEvent("SHOW_TODAY_CAMPAIGN_LIST",true)
	this:RegisterEvent("SHOW_TODAY_CAMPAIGN_LIST_FROM_TRACK",true);
--	this:RegisterEvent("UPDATE_CAMPAGIN_BY_TRACK");
	this:RegisterEvent("OPEN_CAMPAINLIST",true);
	this:RegisterEvent("TODAY_ACTIVE_POINT",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function TodayCampaignList_OnLoad()
	-- 保存界面的默认相对位置
	g_TodayCampaignList_Frame_UnifiedXPosition	= TodayCampaignList_Frame : GetProperty("UnifiedXPosition");
	g_TodayCampaignList_Frame_UnifiedYPosition	= TodayCampaignList_Frame : GetProperty("UnifiedYPosition");

	g_ItemActionButtonList[1] = TodayCampaignList_Item1
	g_ItemActionButtonList[2] = TodayCampaignList_Item2
	g_ItemActionButtonList[3] = TodayCampaignList_Item3
	g_ItemActionButtonList[4] = TodayCampaignList_Item4
	g_ItemActionButtonList[5] = TodayCampaignList_Item5
	g_ItemActionButtonList[6] = TodayCampaignList_Item6
	g_ItemActionButtonList[7] = TodayCampaignList_Item7
	g_ItemActionButtonList[8] = TodayCampaignList_Item8
	g_ItemActionButtonList[9] = TodayCampaignList_Item9
	g_ItemActionButtonList[10] = TodayCampaignList_Item10
end

-- OnEvent
function TodayCampaignList_OnEvent(event)
	if ( event == "SHOW_TODAY_CAMPAIGN_LIST" ) then
		if not this:IsVisible() and g_Flag == 0 then
			g_Flag = 1
			SendCampaignCountMsg()
		elseif not this:IsVisible() and g_Flag == 1 then
			g_Flag = 0
			this:Show() 
			local level = Player:GetData( "LEVEL" );
			if level < 10 then
				TodayCampaignList_Init(1)
				TodayCampaignList_Fenye3:SetCheck(1)
				TodayCampaignList_OnSwitchPage(3)
			else
				TodayCampaignList_Init(-1)
			end
			
		elseif this:IsVisible() then
			g_Flag = 0
			this:Hide()
		end

	elseif ( event == "SHOW_TODAY_CAMPAIGN_LIST_FROM_TRACK") then
		if not this:IsVisible() and g_Flag == 0 then
			g_Flag = 1
			SendCampaignCountMsg()
		elseif not this:IsVisible() and g_Flag == 1 then
			g_Flag = 0
			this:Show()
			local level = Player:GetData( "LEVEL" );
			if level < 10 then
				TodayCampaignList_Init(1)
				TodayCampaignList_Fenye3:SetCheck(1)
				TodayCampaignList_OnSwitchPage(3)
			else
				TodayCampaignList_Init(-1)
			end
		elseif this:IsVisible() then
			g_Flag = 0
			this:Hide()
		end
	elseif ( event == "OPEN_CAMPAINLIST" ) then
		this:Show()
		if arg0 == nil then
			return
		end
		
		TodayCampaignList_Init(1)
		local campaignIndex = GetIndexInTodayCampaignList(GetCurCampaignID()) + 1
		if ( campaignIndex > 0 ) then
			TodayCampaignList_OnSwitchPage(2)
		else
			campaignIndex = GetIndexInTodayCampaignListWholeday(GetCurCampaignID()) + 1
			TodayCampaignList_OnSwitchPage(3)
			if ( campaignIndex < 1 ) then
				campaignIndex = 1
			end
		end
		
		TodayCampaignList_SetButtonSelected(campaignIndex)
	    TodayCampaignList_List1:Flash()
	    TodayCampaignList_List1:SetElementsInView(campaignIndex)
		g_CurrentSelect = campaignIndex-1
	    TodayCampaignList_List_OnSelectionChanged()
		local curPos = TodayCampaignList_CalcListScrollPos(campaignIndex)
		TodayCampaignList_List1:SetVertScrollbarPosition(curPos)
	elseif ( event == "TODAY_ACTIVE_POINT" ) then
		if this:IsVisible() then
			local nTodayActivePoint = Player:GetData("TODAYACTIVEPOINT")

			if nTodayActivePoint == nil then
				nTodayActivePoint = 0
			end

			local str = ScriptGlobal_Format("#{HDRCYH_130118_01}", tostring(nTodayActivePoint))
			TodayCampaignList_Detailtips_text:SetText(str)

			str = ScriptGlobal_Format("#{HDRCYH_130118_03}", tostring(nTodayActivePoint))
			TodayCampaignList_Huoyue:SetToolTip( str)

			TodayCampaignList_Huoyue:SetProgress(tonumber(nTodayActivePoint) , 500)
			
			TodayCampaignList_SetBoxImage(nTodayActivePoint)
		end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		TodayCampaignList_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		TodayCampaignList_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	end
end

function TodayCampaignList_Init( nSelectID )
	--获得今日活跃值
	local nTodayActivePoint = Player:GetData("TODAYACTIVEPOINT")

	if nTodayActivePoint == nil then
		nTodayActivePoint = 0
	end

	local str = ScriptGlobal_Format("#{HDRCYH_130118_01}", tostring(nTodayActivePoint))
	TodayCampaignList_Detailtips_text:SetText(str)

	str = ScriptGlobal_Format("#{HDRCYH_130118_03}", tostring(nTodayActivePoint))
	TodayCampaignList_Huoyue:SetToolTip( str)

	TodayCampaignList_Huoyue:SetProgress(tonumber(nTodayActivePoint) , 500)

	TodayCampaignList_SetBoxImage(nTodayActivePoint)

	if nSelectID ~= 1 then
	    TodayCampaignList_Fenye1:SetCheck(1)
	    TodayCampaignList_OnSwitchPage(1)
    end
end

-- 鼠标点击具体活动后的相应函数
function TodayCampaignList_List_OnSelectionChanged()

	local campaignlistnum = -1
	if g_PageNum == 1 then
		campaignlistnum = campaign_today_recommended
	elseif g_PageNum == 2 then
		campaignlistnum = campaign_today_timelimited
	elseif g_PageNum == 3 then
		campaignlistnum = campaign_today_allday
	else
		return
	end

	TodayCampaignList_Info1:SetText("#{HDRC_XML_02}")
	TodayCampaignList_Info2:SetProperty("Image" , "")
	TodayCampaignList_text1:SetText("")
	TodayCampaignList_text2:SetText("")
	for i = 1 , g_ItemActionNum do
		g_ItemActionButtonList[i]:SetActionItem(-1);
	end

	local g_CurrentCampaignCount = GetCampaignCount( tonumber(campaignlistnum) )

	if g_CurrentSelect < g_CurrentCampaignCount then

		-- 活动名
		local strHuodong = EnumCampaign( tonumber(campaignlistnum), g_CurrentSelect, "name" )
		-- 活动介绍
		local strIntro = EnumCampaign( tonumber(campaignlistnum), g_CurrentSelect, "detailDesc" )
		-- 活动奖励
		local strBonus = EnumCampaign( tonumber(campaignlistnum), g_CurrentSelect, "Bonus" )
		-- 活动图片
		local  strImage = EnumCampaign( tonumber(campaignlistnum), g_CurrentSelect, "ImageString" )

		if strHuodong~= nil then
			TodayCampaignList_Info1:SetText(tostring(strHuodong))
		end

		if strIntro ~= nil then
			TodayCampaignList_text1:SetText( tostring(strIntro ) )
		end
		if strBonus ~= nil then
			TodayCampaignList_text2:SetText( tostring(strBonus ) )
		end
		if strImage ~= nil then
			TodayCampaignList_Info2:SetProperty("Image" , tostring(strImage))
		end

		DataPool:Lua_UpdateActivityItemListForShow(tonumber(campaignlistnum),g_CurrentSelect);
		for i = 1 , g_ItemActionNum do
			local theAction = EnumAction(i-1, "activityitemshow");
			if theAction:GetID() ~= 0 then
				g_ItemActionButtonList[i]:SetActionItem(theAction:GetID());
			end
		end
	end
end

function TodayCampaignList_OnItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		TodayCampaignList_SetButtonSelected(nIndex + 1)
		TodayCampaignList_List1:Flash()
		g_CurrentSelect = nIndex
		TodayCampaignList_List_OnSelectionChanged()
	end
end
function TodayCampaignList_OnButtonClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		local campaignlistnum = -1
		if g_PageNum == 1 then
			campaignlistnum = campaign_today_recommended
		elseif g_PageNum == 2 then
			campaignlistnum = campaign_today_timelimited
		elseif g_PageNum == 3 then
			campaignlistnum = campaign_today_allday
		else
			return
		end

		local g_CurrentCampaignCount = GetCampaignCount( tonumber(campaignlistnum) )
		if nIndex < g_CurrentCampaignCount then
			local nZhengZhaoFubenID = EnumCampaign( tonumber(campaignlistnum), nIndex, "ZhengZhaoFuben" );
			if nZhengZhaoFubenID ~= nil then
				if nZhengZhaoFubenID > 0 then
					DataPool:ApplyZhengZhaoMsg( nZhengZhaoFubenID );
				end
			end
		end

		TodayCampaignList_SetButtonSelected(nIndex + 1)
		TodayCampaignList_List1:Flash()
		g_CurrentSelect = nIndex
		TodayCampaignList_List_OnSelectionChanged()
	end
end
function TodayCampaignList_OnCheckClick()

--	local sPos,ePos = string.find(arg0, "_auto_element")
--	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

--	if nIndex >= 0 then
--		local campaignlistnum = -1
--		if g_PageNum == 1 then
--			campaignlistnum = campaign_today_recommended
--		elseif g_PageNum == 2 then
--			campaignlistnum = campaign_today_timelimited
--		elseif g_PageNum == 3 then
--			campaignlistnum = campaign_today_allday
--		else
--			return
--		end

--		local nCurrentCampaignCount = GetCampaignCount( tonumber(campaignlistnum) )
--		if nIndex < nCurrentCampaignCount then
--			local nCampaignID = EnumCampaign( tonumber(campaignlistnum), nIndex, "id" )
--			if ( DataPool:IsCampaignCanTrack(nCampaignID) > 0 ) then
--				if ( DataPool:IsCampaignTrackOpen(nCampaignID) > 0 ) then
--					DataPool:SetCampaignTrackOpen( nCampaignID, 0 )
--				else
--					if ( DataPool:IsTrackFuncShow(2) == 0 ) then
--						OpenWindow( "CampaignTrack" )
--						DataPool:SetTrackFuncShow(2, 1)
--					end
--					DataPool:SetCampaignTrackOpen(nCampaignID, 1)
--				end
--				DataPool:UpdateCampaignTrack()
--			end
--		end
--	end
end

function TodayCampaignList_SetButtonSelected(nIndex)
	for nButtonIndex = 1,table.getn(g_nContentButton) do
		if nil ~= g_nContentButton[nButtonIndex] then
			if nButtonIndex ~= nIndex then
				g_nContentButton[nButtonIndex]:SetBarButtonSelected(false)
			else
				g_nContentButton[nButtonIndex]:SetBarButtonSelected(true)
			end
		end
	end
end

-- 关闭
function TodayCampaignList_OnClosed()
		
	this:Hide();
end

function TodayCampaignList_SwitchToOld()
	SetOpenCampaignType(1)	
	--关闭窗口
	TodayCampaignList_OnClosed()
	--打开旧版活动日程
	PushEvent("SHOW_TODAY_NEWCAMPAIGN_LIST")
end
function TodayCampaignList_SwitchPage(idx)
	if idx == 1 then
		local level = Player:GetData( "LEVEL" );
		if level < 10 then
			PushDebugMessage("#{HDRCYH_130118_30}")
			return
		end
	end
	TodayCampaignList_OnSwitchPage(idx)
end

function TodayCampaignList_OnSwitchPage(idx)
	local campaignlistnum = -1
	if idx == 1 then
		g_PageNum = 1
		TodayCampaignList_Fenye1:SetCheck(1)
		TodayCampaignList_Fenye2:SetCheck(0)
		TodayCampaignList_Fenye3:SetCheck(0)
		campaignlistnum = campaign_today_recommended
	elseif idx == 2 then
		g_PageNum = 2
		TodayCampaignList_Fenye1:SetCheck(0)
		TodayCampaignList_Fenye2:SetCheck(1)
		TodayCampaignList_Fenye3:SetCheck(0)
		campaignlistnum = campaign_today_timelimited
	elseif idx == 3 then
		g_PageNum = 3
		TodayCampaignList_Fenye1:SetCheck(0)
		TodayCampaignList_Fenye2:SetCheck(0)
		TodayCampaignList_Fenye3:SetCheck(1)
		campaignlistnum = campaign_today_allday
	else
		return
	end

	ResetNewCurrentCampainList()

	TodayCampaignList_List1:CleanAllElement("TodayCampaignList")
	g_nContentButton = {}

	local nPageCampaignCount = GetCampaignCount( campaignlistnum )

	-- 当天活动列表
	for i = 0, nPageCampaignCount - 1 do
		-- 时间
		local strStartTime = EnumCampaign(campaignlistnum, i, "starttime" )
		local strEndTime = EnumCampaign( campaignlistnum, i, "endtime" )
		local strTime = strStartTime.."--"..strEndTime
		if strStartTime == "00:00" and strEndTime == "23:59" then
			strTime = "#{HDRCYH_130118_14}"
		end

		--推荐度
		local nCommendedValue = EnumCampaign( campaignlistnum, i, "CommendedValue" )

		--是否追踪
		--local isTrace = EnumCampaign(campaignlistnum, i, "TrackIsOrNot" )

		-- 活动名
		local strHuodong = EnumCampaign( campaignlistnum, i, "name" )

		--每天活动次数
		local nCampaignCount = EnumCampaign( campaignlistnum, i, "PlayNum" )

		--最低参加等级
		local nLevel = EnumCampaign( campaignlistnum, i, "MinLevel" )

		--组队形式
		local nTeamType = EnumCampaign( campaignlistnum, i, "TeamType" )

		local strIconString = EnumCampaign( campaignlistnum, i, "IconString" )

		local nCampaignID = EnumCampaign( campaignlistnum, i, "id" )
		local nZhengZhaoFubenID = EnumCampaign( campaignlistnum, i, "ZhengZhaoFuben" );

		-- 参加时间
		local time_temp = GetTime2Minite()

		local tshour = string.sub( strStartTime, 1, 2 )
		local tsminite = string.sub( strStartTime, 4, 5 )

		local tehour = string.sub( strEndTime, 1, 2 )
		local teminite = string.sub( strEndTime, 4, 5 )

		local tmpSTime = tonumber(tshour) * 100 + tonumber(tsminite)
		local tmpETime = tonumber(tehour) * 100 + tonumber(teminite)

		local ItemBar = TodayCampaignList_List1:AddItemElement( "SuperBarButton", "LEFT", "TodayCampaignList","" ,"")
		ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")

		if strIconString ~= nil and strIconString ~= "" then
		local sPos,_ = string.find(strIconString," ");
		local IconImageSet = string.sub(strIconString,5,sPos-1);
		local IconIamge = string.sub(strIconString,sPos+7)
		if nil ~= IconImageSet and nil ~= IconIamge then
			ItemBar:SetImage1(IconImageSet,IconIamge)
		--	ItemBar:SetImage2("CommonFrame20","Item_Hot")
		end

		if nCommendedValue >= 10 then
			ItemBar:SetImage2Show()
		else
			ItemBar:SetImage2Hide()
		end

		if time_temp >= tmpSTime and time_temp <= tmpETime then
			ItemBar:SetText1( "#G"..strHuodong )
			ItemBar:SetText2( "#G"..strTime )
			ItemBar:SetText3( "#G"..tostring(nLevel) )
			ItemBar:SetText4( "#G"..tostring(nTeamType) )
			if nCampaignCount ~= 0 then
				local nMyCount = GetCampaignCountNum( nCampaignID )
				ItemBar:SetText5( "#G"..tostring(nMyCount).."/"..tostring(nCampaignCount) )
			else
				ItemBar:SetText5( "" )
			end
			ItemBar:SetText6( "#G".."#{HDRCYH_130118_24}" )
		else
			ItemBar:SetText1( strHuodong )
			ItemBar:SetText2( strTime )
			ItemBar:SetText3( tostring(nLevel) )
			ItemBar:SetText4( tostring(nTeamType) )
			if nCampaignCount ~= 0 then
				local nMyCount = GetCampaignCountNum( nCampaignID )
				ItemBar:SetText5( tostring(nMyCount).."/"..tostring(nCampaignCount) )
			else
				ItemBar:SetText5( "" )
			end
			ItemBar:SetText6( "#{HDRCYH_130118_25}" )
		end

		ItemBar:SetCheckButton1Hide()
		if nZhengZhaoFubenID ~= nil and nZhengZhaoFubenID > 0 then
			ItemBar:SetButton1Show();
			--ItemBar:SetButton1Text("#{ZZDY_130131_01}");
		else
			ItemBar:SetButton1Hide();
		end

	end
		table.insert(g_nContentButton,ItemBar);
	end

	g_CurrentSelect = 0
	TodayCampaignList_SetButtonSelected(g_CurrentSelect + 1)
	TodayCampaignList_List1:Flash()
	TodayCampaignList_List_OnSelectionChanged()
end

function TodayCampaignList_CalcListScrollPos(SelectIdx)
	local BtlIdx = 1
	local ShowIdx = 0
	local ShowCount = 0
	if SelectIdx > table.getn(g_nContentButton) then
		return 0
	end

	for BtlIdx = 1, table.getn(g_nContentButton) do
		if true == g_nContentButton[BtlIdx]:IsVisible() then
			if BtlIdx <= SelectIdx then
				ShowIdx = ShowIdx + 1
			end
			ShowCount = ShowCount + 1
		end
	end
	if ShowCount * 40 < 400 then
		return 0
	else
		return (ShowCount * 40 - 400) * ((ShowIdx - 1) / (ShowCount - 1))
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function TodayCampaignList_Frame_On_ResetPos()

	TodayCampaignList_Frame : SetProperty("UnifiedXPosition", g_TodayCampaignList_Frame_UnifiedXPosition);
	TodayCampaignList_Frame : SetProperty("UnifiedYPosition", g_TodayCampaignList_Frame_UnifiedYPosition);

end

function TodayCampaignList_CurListReset( nSelectedRow )

end

function TodayCampaignList_TodayListReset( nSelectedRow )

end

function TodayCampaignList_HuoYueHaoLiFunc()
	OpenHuoYueHaoLi()
end

function TodayCampaignList_SetBoxImage(nTodayActivePoint)
	
	local nDataRound = DataPool:GetPlayerMission_DataRound(579)
	
	if nTodayActivePoint > 0 then
		local ret = math.mod(nDataRound , 10)
		if ret >= 1 then
			TodayCampaignList_Icon2:SetProperty("Image" , "set:Button10 image:Qingtong_kong_Normal")
		else
			TodayCampaignList_Icon2:SetProperty("Image" , "set:Button9 image:Qingtong_Normal")
		end
	else
		TodayCampaignList_Icon2:SetProperty("Image" , "set:Button9 image:Qingtong_Disable")
	end

	if nTodayActivePoint >= 50 then
		local ret = math.mod(nDataRound , 100)
		if ret >= 10 then
			TodayCampaignList_Icon4:SetProperty("Image" , "set:Button10 image:Baiyin_kong_Normal")
		else
			TodayCampaignList_Icon4:SetProperty("Image" , "set:Button9 image:Baiyin_Normal")
		end
	else
		TodayCampaignList_Icon4:SetProperty("Image" , "set:Button9 image:Baiyin_Disable")
	end

	if nTodayActivePoint >= 150 then
		local ret = math.mod(nDataRound , 1000)
		if ret >= 100 then
			TodayCampaignList_Icon6:SetProperty("Image" , "set:Button10 image:Huangjin_kong_Normal")
		else
			TodayCampaignList_Icon6:SetProperty("Image" , "set:Button9 image:Huangjin_Normal")
		end
	else
		TodayCampaignList_Icon6:SetProperty("Image" , "set:Button9 image:Huangjin_Disable")
	end

	if nTodayActivePoint >= 450 then
		local ret = math.mod(nDataRound , 10000)
		if ret >= 1000 then
			TodayCampaignList_Icon8:SetProperty("Image" , "set:Button10 image:Feicui_kong_Normal")
		else
			TodayCampaignList_Icon8:SetProperty("Image" , "set:Button9 image:Feicui_Normal")
		end
	else
		TodayCampaignList_Icon8:SetProperty("Image" , "set:Button9 image:Feicui_Disable")
	end

		TodayCampaignList_Icon2:SetToolTip("#{HDRCYH_130118_04}")
		TodayCampaignList_Icon4:SetToolTip("#{HDRCYH_130118_05}")
		TodayCampaignList_Icon6:SetToolTip("#{HDRCYH_130118_06}")
		TodayCampaignList_Icon8:SetToolTip("#{HDRCYH_130118_07}")

end
