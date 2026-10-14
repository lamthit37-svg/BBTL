local 	g_nContentButton = {}

local campaign_today_timelimited 	= 1
local campaign_today_timeallday 	= 2
local campaign_today_timefestival	= 3
local campaign_today_timexieke  	= 4

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
local g_TodayCampaignListNew_Frame_UnifiedPosition;

local g_SameSceneId = {
	[0] = 242,
	[242] = 0,
}
--是否是豪侠路打开界面
local g_IsOpenByHXL = 0

--赏枫活动
local g_FrostBeginTime = 20180903	--开始领取时间
local g_FrostEndTime = 20180916	--结束领取时间
local g_tips_status_day  = {0,0,0,0}
local g_tips_status_week = {0,0,}
local g_tips_control_day = {}
local g_tips_control_week = {}
local g_button_today = {}
local g_button_week = {}
local g_button_today_tipsctl = {}
local g_button_week_tipsctl = {}

local g_BaoXiangHYDayButtonTips = {
	[0] = {
		[1] = "#{HYHL_101230_29}",
		[2] = "#{HYHL_101230_30}",
		[3] = "#{HYHL_101230_31}",
		[4] = "#{HYHL_101230_32}",
	},
	[1] = {
		[1] = "#{KJFTS_210818_92}",
		[2] = "#{KJFTS_210818_93}",
		[3] = "#{KJFTS_210818_94}",
		[4] = "#{KJFTS_210818_95}",
	},
}
local g_BaoXiangHYDayButtonTips_OriginalJD = {
	[0] = {
		[1] = "#{HYHL_101230_29}",
		[2] = "#{HYHL_101230_30}",
		[3] = "#{SJF_251024_8}",
		[4] = "#{SJF_251024_9}",
	},
	[1] = {
		[1] = "#{KJFTS_210818_92}",
		[2] = "#{KJFTS_210818_93}",
		[3] = "#{KJFTS_210818_94}",
		[4] = "#{KJFTS_210818_95}",
	},
}

local g_BaoXiangHYDayButtonTips_2606S = {
	[0] = {
		[1] = "#{HYHL_101230_29}",
		[2] = "#{QXF_260623_106}",
		[3] = "#{QXF_260623_16}",
		[4] = "#{QXF_260623_17}",
	},
	[1] = {
		[1] = "#{KJFTS_210818_92}",
		[2] = "#{KJFTS_210818_93}",
		[3] = "#{KJFTS_210818_94}",
		[4] = "#{KJFTS_210818_95}",
	},
}
-- local g_BaoXiangHYDayButtonTips_ZhouNianJiangHongFu = {
-- 	[0] = {
-- 		[1] = "#{HYHL_101230_29}",
-- 		[2] = "#{HYHL_220322_50}",
-- 		[3] = "#{HYHL_220322_51}",
-- 		[4] = "#{HYHL_220322_53}",
-- 	},
-- 	[1] = {
-- 		[1] = "#{KJFTS_210818_92}",
-- 		[2] = "#{HYHL_220322_54}",
-- 		[3] = "#{HYHL_220322_55}",
-- 		[4] = "#{HYHL_220322_56}",
-- 	},
-- }

-- local g_ZhouNianJiangHongFu_BeginTime = 20220422
-- local g_ZhouNianJiangHongFu_EndTime   = 20220515

local g_BaoXiangHYWeekButtonTips = {
	[0] = {
		[1] = "#{HYCT_20210629_86}",
		[2] = "#{HYCT_20210629_91}", 
	},
	[1] = {
		[1] = "#{KJFTS_210818_96}",
		[2] = "#{KJFTS_210818_97}", 
	},
}

local g_BaoXiangHYWeekButtonTips80 = {
	[0] = {
		[1] = "#{ZHYBX_220322_01}",
		[2] = "#{ZHYBX_220322_04}", 
	},
	[1] = {
		[1] = "#{KJFTS_210818_96}",
		[2] = "#{KJFTS_210818_97}", 
	},
}

local g_BaoXiangHYWeekButtonTips80_129 = {
	[0] = {
		[1] = "#{SBDD_260104_05}",
		[2] = "#{SBDD_260104_06}", 
	},
	[1] = {
		[1] = "#{KJFTS_210818_96}",
		[2] = "#{KJFTS_210818_97}", 
	},
}

local g_BaoXiangHYWeekButtonTips_OriginalJD = {
	[0] = {
		[1] = "#{SJF_251024_10}",
		[2] = "#{SJF_251024_11}", 
	},
	[1] = {
		[1] = "#{KJFTS_210818_96}",
		[2] = "#{KJFTS_210818_97}", 
	}, 
} 

local g_BaoXiangHYWeekButtonTips80_OriginalJD = {
	[0] = {
		[1] = "#{SJF_251024_12}",
		[2] = "#{SJF_251024_13}", 
	},
	[1] = {
		[1] = "#{KJFTS_210818_96}",
		[2] = "#{KJFTS_210818_97}", 
	}, 
} 
local g_BaoXiangHYWeekButtonTips80_OriginalJD_129 = {
	[0] = {
		[1] = "#{SBDD_260104_07}",
		[2] = "#{SBDD_260104_08}", 
	},
	[1] = {
		[1] = "#{KJFTS_210818_96}",
		[2] = "#{KJFTS_210818_97}", 
	}, 
} 
local g_BaoXiangHYWeekButtonTips_2606S = {
	[0] = {
		[1] = "#{QXF_260623_19}",
		[2] = "#{QXF_260623_21}", 
	},
	[1] = {
		[1] = "#{KJFTS_210818_96}",
		[2] = "#{KJFTS_210818_97}", 
	}, 
} 
  
function TodayCampaignListNew_PreLoad()
	this:RegisterEvent("SHOW_TODAY_NEWCAMPAIGN_LIST")
	this:RegisterEvent("OPEN_CAMPAINLISTNEW",true);
	this:RegisterEvent("TODAY_ACTIVE_POINT");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)  
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND",true)
end

function TodayCampaignListNew_OnLoad()
	-- 保存界面的默认相对位置
	g_TodayCampaignListNew_Frame_UnifiedPosition	= TodayCampaignListNew : GetProperty("UnifiedPosition"); 

	g_ItemActionButtonList[1] = TodayCampaignListNew_Item1
	g_ItemActionButtonList[2] = TodayCampaignListNew_Item2
	g_ItemActionButtonList[3] = TodayCampaignListNew_Item3
	g_ItemActionButtonList[4] = TodayCampaignListNew_Item4
	g_ItemActionButtonList[5] = TodayCampaignListNew_Item5
	g_ItemActionButtonList[6] = TodayCampaignListNew_Item6
	g_ItemActionButtonList[7] = TodayCampaignListNew_Item7
	g_ItemActionButtonList[8] = TodayCampaignListNew_Item8
	g_ItemActionButtonList[9] = TodayCampaignListNew_Item9
	g_ItemActionButtonList[10]= TodayCampaignListNew_Item10
	g_tips_control_day[1] = TodayCampaignListNew_Icon2Tip
	g_tips_control_day[2] = TodayCampaignListNew_Icon4Tip
	g_tips_control_day[3] = TodayCampaignListNew_Icon6Tip
	g_tips_control_day[4] = TodayCampaignListNew_Icon8Tip
	g_tips_control_week[1] = TodayCampaignListNew_WeeklyGift1Tip
	g_tips_control_week[2] = TodayCampaignListNew_WeeklyGift2Tip

	g_button_today[1] = TodayCampaignListNew_Icon2
	g_button_today[2] = TodayCampaignListNew_Icon4
	g_button_today[3] = TodayCampaignListNew_Icon6
	g_button_today[4] = TodayCampaignListNew_Icon8

	g_button_week[1] = TodayCampaignListNew_WeeklyGift1
	g_button_week[2] = TodayCampaignListNew_WeeklyGift2

	g_button_today_tipsctl[1] = TodayCampaignListNew_Icon2Disabled
	g_button_today_tipsctl[2] = TodayCampaignListNew_Icon4Disabled
	g_button_today_tipsctl[3] = TodayCampaignListNew_Icon6Disabled
	g_button_today_tipsctl[4] = TodayCampaignListNew_Icon8Disabled
	g_button_week_tipsctl[1] = TodayCampaignListNew_WeeklyGift1Disabled
	g_button_week_tipsctl[2] = TodayCampaignListNew_WeeklyGift2Disabled

end

-- OnEvent
function TodayCampaignListNew_OnEvent(event)
	if ( event == "SHOW_TODAY_NEWCAMPAIGN_LIST" ) then
		if not this:IsVisible() and g_Flag == 0 then
			g_Flag = 1
			SendCampaignCountMsg()
		elseif not this:IsVisible() and g_Flag == 1 then
			g_Flag = 0
			this:Show()
			TodayCampaignListNew_Init(-1)
			if g_IsOpenByHXL == 1 then
				TodayCampaignListNew_SwitchPage(2)

			end
		elseif this:IsVisible() then
			g_Flag = 0
			this:Hide()
		end
		if g_IsOpenByHXL ==  1 then
			g_IsOpenByHXL=0
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2018012302 then
		--豪侠路打开界面
		g_IsOpenByHXL = 1		
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88933601 then	 
		for i = 1, table.getn(g_tips_status_day) do
			g_tips_status_day[i] = Get_XParam_INT(i-1)
		end
		for i = 1, table.getn(g_tips_status_week) do
			g_tips_status_week[i] = Get_XParam_INT(i-1+4)
		end
		TodayCampaignListNew_RefreshTips()
		
		TodayCampaignListNew_RefreshIcon8Tips()
	elseif ( event == "SHOW_TODAY_CAMPAIGN_LIST_FROM_TRACK") then
		if not this:IsVisible() and g_Flag == 0 then
			g_Flag = 1
			SendCampaignCountMsg()
		elseif not this:IsVisible() and g_Flag == 1 then
			g_Flag = 0
			this:Show()
			local level = Player:GetData( "LEVEL" );
			if level < 10 then
				TodayCampaignListNew_Init(1)
				TodayCampaignListNew_Fenye3:SetCheck(1)
				TodayCampaignListNew_OnSwitchPage(3)
			else
				TodayCampaignListNew_Init(-1)
			end
		elseif this:IsVisible() then
			g_Flag = 0
			this:Hide()
		end
	elseif ( event == "OPEN_CAMPAINLISTNEW" ) then
		if arg0 == nil then	 
			PushDebugMessage("arg0 == nil")
			return
		end
		local CamID = tonumber(arg0) 
		if CamID == nil then 
			PushDebugMessage("CamID == nil")
			return
		end 
		
		this:Show()
		TodayCampaignListNew_Init(-1)
		local CampaignType,CurrentSelect = GetCampaingTypeByCamID(tonumber(CamID)) 
		if CampaignType == -1 then
			CampaignType,CurrentSelect = IsInLimitCampaingTableByCamID(tonumber(CamID))   -- 针对装备评分的 限时提醒 因为那里Push过来的是固定ID  
			if CampaignType == -1 then
				return
			end
		end
		
		local campaignIndex =  CampaignType + 1
		TodayCampaignListNew_OnSwitchPage(campaignIndex)  
		 
		TodayCampaignListNew_SetButtonSelected(CurrentSelect + 1)
		TodayCampaignListNew_List1:Flash()
		g_CurrentSelect = CurrentSelect
		TodayCampaignListNew_List_OnSelectionChanged()  
		local curPos = TodayCampaignListNew_CalcListScrollPos(CurrentSelect + 1)
		TodayCampaignListNew_List1:SetVertScrollbarPosition(curPos)
	elseif ( event == "TODAY_ACTIVE_POINT" ) then
		if this:IsVisible() then
			local nTodayActivePoint = Player:GetData("TODAYACTIVEPOINT")
			local nTodayActivePoint_week = Player:GetData("WEEKACTIVEPOINT")

			if nTodayActivePoint == nil then
				nTodayActivePoint = 0
			end

			local str = ScriptGlobal_Format("#{HDRCYH_130118_01}", tostring(nTodayActivePoint))
			TodayCampaignListNew_Huoyue_Text0:SetText(str)

			str = ScriptGlobal_Format("#{HDRCYH_130118_03}", tostring(nTodayActivePoint))
			TodayCampaignListNew_Huoyue:SetToolTip( str)

			TodayCampaignListNew_Huoyue:SetProgress(tonumber(nTodayActivePoint) , 500)
			
			TodayCampaignListNew_SetBoxImage(nTodayActivePoint) 

			str = ScriptGlobal_Format("#{HYCT_20210629_80}", tostring(nTodayActivePoint_week),2000)
			TodayCampaignListNew_WeeklyHuoyue_Text0:SetText(str)

			local nDaiBi_H, nDaiBi_L, nDaiBi_H_week, nDaiBi_L_Day  = Player:GetData("ACTIVEPOINT_DAIBI")
			str = ScriptGlobal_Format("#{HYCT_20210629_81}", tostring(nDaiBi_H_week),1000)
			TodayCampaignListNew_WeeklyShopCurrency:SetText(str)			
			str = ScriptGlobal_Format("#{HYCT_20210629_121}", tostring(nDaiBi_H))
			TodayCampaignListNew_AllShopCurrency:SetText(str)
			
			TodayCampaignListNew_RefreshIcon8Tips()
			TodayCampaignListNew_RefreshTips()
		end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		TodayCampaignListNew_Frame_On_ResetPos() 
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		TodayCampaignListNew_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	end
end

function TodayCampaignListNew_Init( nSelectID )
	--获得今日活跃值
	local nTodayActivePoint = Player:GetData("TODAYACTIVEPOINT")
	local nTodayActivePoint_week = Player:GetData("WEEKACTIVEPOINT")
	if nTodayActivePoint == nil then
		nTodayActivePoint = 0
	end

	local str = ScriptGlobal_Format("#{HDRCYH_130118_01}", tostring(nTodayActivePoint))
	TodayCampaignListNew_Huoyue_Text0:SetText(str)

	str = ScriptGlobal_Format("#{HYCT_20210629_80}", tostring(nTodayActivePoint_week),2000)
	TodayCampaignListNew_WeeklyHuoyue_Text0:SetText(str)

	local nDaiBi_H, nDaiBi_L, nDaiBi_H_week, nDaiBi_L_Day  = Player:GetData("ACTIVEPOINT_DAIBI")
	str = ScriptGlobal_Format("#{HYCT_20210629_81}", tostring(nDaiBi_H_week),1000)
	TodayCampaignListNew_WeeklyShopCurrency:SetText(str)
	str = ScriptGlobal_Format("#{HYCT_20210629_121}", tostring(nDaiBi_H))
	TodayCampaignListNew_AllShopCurrency:SetText(str)
	str = ScriptGlobal_Format("#{HDRCYH_130118_03}", tostring(nTodayActivePoint))
	TodayCampaignListNew_Huoyue:SetToolTip( str)

	TodayCampaignListNew_Huoyue:SetProgress(tonumber(nTodayActivePoint) , 500)

	TodayCampaignListNew_SetBoxImage(nTodayActivePoint)
	
	TodayCampaignListNew_WeeklyHuoyue_Text1:SetText("1200")
	TodayCampaignListNew_WeeklyHuoyue_Text2:SetText("2000")

	local campaignlistnum = -1
	if g_PageNum == 1 then
		campaignlistnum = campaign_today_timelimited
	elseif g_PageNum == 2 then
		campaignlistnum = campaign_today_timeallday
	elseif g_PageNum == 3 then
		campaignlistnum = campaign_today_timefestival
	elseif g_PageNum == 4 then
		campaignlistnum = campaign_today_timexieke
	else
		return
	end
	
	local isXiaKe = Player : GetData("IsXiaKe") 
	if isXiaKe == 1 then
		TodayCampaignListNew_Fenye4:Show()
	else
		TodayCampaignListNew_Fenye4:Hide()
	end

	if nSelectID ~= 1 then
	    TodayCampaignListNew_Fenye1:SetCheck(1)
	    TodayCampaignListNew_OnSwitchPage(1)
	end
	 
	TodayCampaignListNew_RefreshTips()
	
	TodayCampaignListNew_RefreshIcon8Tips()
end

-- 鼠标点击具体活动后的相应函数
function TodayCampaignListNew_List_OnSelectionChanged()

	local campaignlistnum = -1
	if g_PageNum == 1 then
		campaignlistnum = campaign_today_timelimited
	elseif g_PageNum == 2 then
		campaignlistnum = campaign_today_timeallday
	elseif g_PageNum == 3 then
		campaignlistnum = campaign_today_timefestival
	elseif g_PageNum == 4 then
		campaignlistnum = campaign_today_timexieke
	else
		return
	end
 
	for i = 1 , g_ItemActionNum do
		g_ItemActionButtonList[i]:SetActionItem(-1);
		g_ItemActionButtonList[i]:Show()
	end
	
	PushEvent("CLOSE_CAMPAIGN_TIMENEW")
	
	local g_CurrentCampaignCount = GetNewCampaignCount( tonumber(campaignlistnum) )

	if g_CurrentSelect < g_CurrentCampaignCount then

		-- 活动名
		local strHuodong = EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "name" )
		-- 活动介绍
		local strIntro = EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "detailDesc" )
		-- 活动奖励
		local strBonus = EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "Bonus" ) 
		-- 活动时间
		local strStartTime 	= EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "starttime" )
		local strEndTime 		= EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "endtime" )
		--征召
		local nZhengZhaoFubenID = EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "ZhengZhaoFuben" ); 
		-- 活动图片
		local  strImage = EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "ImageString" )
		local strTime = strStartTime.."--"..strEndTime
		if strStartTime == "00:00" and strEndTime == "23:59" then
			strTime = "#{HDRCYH_130118_14}"
		end
		local strdesc1 = EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "decs1" )
		local strdesc2 = EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "decs2" )
    --组队形式
		local nTeamType = EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "TeamType" ) 
		--最低参加等级
		local nLevel = EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "MinLevel" ) 
		--心法级别
		local nXinfaLevel 	= EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "XinFaLevel" )
		local StrXinFa = ""
		if nXinfaLevel == nil or nXinfaLevel == 0 then
			StrXinFa = ""
		else
			StrXinFa = "#cfff263（心法#cfff263"..nXinfaLevel.."#cfff263）"
		end
		--
		local nClass = EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "nClass" ) 
		local nIsViewAll 	= EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "IsViewAll" )
		
		TodayCampaignListNew_text1:SetText(strTime) 
		TodayCampaignListNew_text4:SetText(strIntro)
		TodayCampaignListNew_text5:SetText(nTeamType)
		TodayCampaignListNew_text7:SetText(strdesc1)
		TodayCampaignListNew_text8:SetText(strdesc2)
		if strImage ~= nil then
			TodayCampaignListNew_Image:SetProperty("Image" , tostring(strImage))
		end
		if nIsViewAll == 0 then
			TodayCampaignListNew_Alltime:Hide()
		else
			TodayCampaignListNew_Alltime:Show()
		end 
		
		DataPool:Lua_UpdateActivityItemListForCampaginShow(tonumber(campaignlistnum),g_CurrentSelect);
		for i = 1 , g_ItemActionNum do
			local theAction = EnumAction(i-1, "activityitemshow");
			if theAction:GetID() ~= 0 then
				g_ItemActionButtonList[i]:SetActionItem(theAction:GetID());
				g_ItemActionButtonList[i]:Show()
			end
		end
		if nZhengZhaoFubenID ~= nil and nZhengZhaoFubenID > 0 then 
			TodayCampaignListNew_Zhengzhao:Show()
		else 
			TodayCampaignListNew_Zhengzhao:Hide()
		end 

		
	end
end

function TodayCampaignListNew_OnItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		TodayCampaignListNew_SetButtonSelected(nIndex + 1)
		TodayCampaignListNew_List1:Flash()
		g_CurrentSelect = nIndex
		TodayCampaignListNew_List_OnSelectionChanged()
	end
end

--前往
function TodayCampaignListNew_OnButton1Click()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
  
	if nIndex >= 0 then
		local campaignlistnum = -1
		if g_PageNum == 1 then
			campaignlistnum = campaign_today_timelimited
		elseif g_PageNum == 2 then
			campaignlistnum = campaign_today_timeallday
		elseif g_PageNum == 3 then
			campaignlistnum = campaign_today_timefestival
		elseif g_PageNum == 4 then
			campaignlistnum = campaign_today_timexieke
		else
			return
		end
  
		local g_CurrentCampaignCount = GetNewCampaignCount( tonumber(campaignlistnum) )
		if nIndex < g_CurrentCampaignCount then
			local PosOrTips = EnumNewCampaign( tonumber(campaignlistnum), nIndex, "PosOrTips" );
			local nJoinType = EnumNewCampaign( tonumber(campaignlistnum), nIndex, "JoinType" );
			
			if PosOrTips ~= nil then
				if nJoinType == 0 then	--自动寻路  随机一个地方
					PosOrTips = string.sub(PosOrTips,1,string.len(PosOrTips) ) 
					--PushDebugMessage("PosOrTips"..PosOrTips)
					local PosTipsVec,Spliteindex = TodayCampaignListNew_SplitStr(PosOrTips,"、")
					local nPosStr = ""
					if Spliteindex > 1 then
						nPosStr = PosTipsVec[ math.random( 1, Spliteindex ) ] 
					else
						nPosStr = PosTipsVec[1]
					end				
					--PushDebugMessage(nPosStr)
					--截一下 括号	 
					nPosStr = string.sub(nPosStr,2,string.len(nPosStr)-1 ) 
					--PushDebugMessage(nPosStr)
					local Posvec,posindex=  TodayCampaignListNew_SplitStr(nPosStr,",")
					if posindex ~= 4 then
						PushDebugMessage("posindex Error")
						return
					else 
						curSceneID = GetSceneID()
						if g_SameSceneId[ tonumber(Posvec[3]) ] and g_SameSceneId[ tonumber(Posvec[3]) ]  == curSceneID then
							AutoRunToTarget(tonumber(Posvec[1]),tonumber(Posvec[2]))
						else
							AutoRunToTargetEx(tonumber(Posvec[1]),tonumber(Posvec[2]),tonumber(Posvec[3]))
						end
						SetAutoRunTargetNPCName(tostring(Posvec[4]))
					end
				end
				if nJoinType == 1 then	--醒目提示
					PushDebugMessage(PosOrTips)
				end
			end
		end
  
		TodayCampaignListNew_SetButtonSelected(nIndex + 1)
		TodayCampaignListNew_List1:Flash()
		g_CurrentSelect = nIndex
		TodayCampaignListNew_List_OnSelectionChanged()
	end
end

--征召
function TodayCampaignListNew_Zhengzhao_Clicked()  
	local campaignlistnum = -1
	if g_PageNum == 1 then
		campaignlistnum = campaign_today_timelimited
	elseif g_PageNum == 2 then
		campaignlistnum = campaign_today_timeallday
	elseif g_PageNum == 3 then
		campaignlistnum = campaign_today_timefestival
	elseif g_PageNum == 4 then
		campaignlistnum = campaign_today_timexieke
	else
		return
	end
  
	local g_CurrentCampaignCount = GetNewCampaignCount( tonumber(campaignlistnum) )

	if g_CurrentSelect < g_CurrentCampaignCount then
		--征召
		local nZhengZhaoFubenID = EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "ZhengZhaoFuben" );  
		if nZhengZhaoFubenID ~= nil then
			if nZhengZhaoFubenID > 0 then
				DataPool:ApplyZhengZhaoMsg( nZhengZhaoFubenID );
			end
		end
	end

end  

function TodayCampaignListNew_SetButtonSelected(nIndex)
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
function TodayCampaignListNew_OnClosed()
	--PushDebugMessage("TodayCampaignListNew_OnClosed")
	TodayCampaignListNew_List1:CleanAllElement("TodayCampaignListNew")
	for i = 1 , 10 do
		g_ItemActionButtonList[i]:SetActionItem(-1);
	end 
	
	PushEvent("CLOSE_CAMPAIGN_TIMENEW")
	this:Hide();
end
-- 关闭
function TodayCampaignListNew_OnHiden()
	--PushDebugMessage("TodayCampaignListNew_OnHiden")
	TodayCampaignListNew_List1:CleanAllElement("TodayCampaignListNew")
	--for i = 1 , 10 do
	--	g_ItemActionButtonList[i]:SetActionItem(-1);
	--end
	this:Hide();
end
function TodayCampaignListNew_SwitchPage(idx)
	if idx == 1 then
		local level = Player:GetData( "LEVEL" );
		if level < 10 then
			PushDebugMessage("#{HDRCYH_130118_30}")
			return
		end
	end
	
	TodayCampaignListNew_OnSwitchPage(idx)
end

function TodayCampaignListNew_OnSwitchPage(idx)
	InitNewCampainList()
	local campaignlistnum = -1
	if idx == 1 then
		g_PageNum = 1
		TodayCampaignListNew_Fenye1:SetCheck(1)
		TodayCampaignListNew_Fenye2:SetCheck(0)
		TodayCampaignListNew_Fenye3:SetCheck(0)
		TodayCampaignListNew_Fenye4:SetCheck(0)
		campaignlistnum = campaign_today_timelimited
	elseif idx == 2 then
		g_PageNum = 2
		TodayCampaignListNew_Fenye1:SetCheck(0)
		TodayCampaignListNew_Fenye2:SetCheck(1)
		TodayCampaignListNew_Fenye3:SetCheck(0)
		TodayCampaignListNew_Fenye4:SetCheck(0)
		campaignlistnum = campaign_today_timeallday
	elseif idx == 3 then
		local FesCampaignCount = GetNewCampaignCount( tonumber(campaign_today_timefestival) )
		if FesCampaignCount == 0 then 
			PushDebugMessage("#{HDRC_170722_28}")
			TodayCampaignListNew_Fenye3:SetCheck(0)
			return
	 	end 
		g_PageNum = 3
		TodayCampaignListNew_Fenye1:SetCheck(0)
		TodayCampaignListNew_Fenye2:SetCheck(0)
		TodayCampaignListNew_Fenye3:SetCheck(1)
		TodayCampaignListNew_Fenye4:SetCheck(0)
		campaignlistnum = campaign_today_timefestival
	elseif idx == 4 then
		local XiaKeCampaignCount = GetNewCampaignCount( tonumber(campaign_today_timexieke) )
		if XiaKeCampaignCount == 0 then 
			PushDebugMessage("#{HDRC_170722_28}")
		TodayCampaignListNew_Fenye4:SetCheck(0)
			return
	 	end 
		g_PageNum = 4
		TodayCampaignListNew_Fenye1:SetCheck(0)
		TodayCampaignListNew_Fenye2:SetCheck(0)
		TodayCampaignListNew_Fenye3:SetCheck(0)
		TodayCampaignListNew_Fenye4:SetCheck(1)
		campaignlistnum = campaign_today_timexieke
	else
		return
	end  
	PushEvent("CLOSE_CAMPAIGN_TIMENEW")
	 
	TodayCampaignListNew_List1:CleanAllElement("TodayCampaignListNew")
	g_nContentButton = {} 
	 
	local nPageCampaignCount = GetNewCampaignCount( campaignlistnum ) 
	 
	-- 当天活动列表
	for i = 0, nPageCampaignCount - 1 do 
		-- 时间
		local strStartTime = EnumNewCampaign(campaignlistnum, i, "starttime" ) 
		local strEndTime = EnumNewCampaign( campaignlistnum, i, "endtime" ) 
		local strTime = strStartTime.."--"..strEndTime
		if strStartTime == "00:00" and strEndTime == "23:59" then
			strTime = "#{HDRCYH_130118_14}"
		end

		--推荐度
		local nCommendedValue = EnumNewCampaign( campaignlistnum, i, "CommendedValue" )  
		--是否追踪
		--local isTrace = EnumNewCampaign(campaignlistnum, i, "TrackIsOrNot" ) 
		-- 活动名
		local strHuodong = EnumNewCampaign( campaignlistnum, i, "name" )  
		--每天活动次数
		local nCampaignCount = EnumNewCampaign( campaignlistnum, i, "PlayNum" )  
		--最低参加等级
		local nLevel = EnumNewCampaign( campaignlistnum, i, "MinLevel" )  
		--组队形式
		local nTeamType = EnumNewCampaign( campaignlistnum, i, "TeamType" )  
		--参与形式
		local nJoinType = EnumNewCampaign( campaignlistnum, i, "JoinType" ) 
		--图标
		local strIconString = EnumNewCampaign( campaignlistnum, i, "IconString" ) 
		--CamPaignID
		local nCampaignID = EnumNewCampaign( campaignlistnum, i, "id" )
		--征召
		local nZhengZhaoFubenID = EnumNewCampaign( campaignlistnum, i, "ZhengZhaoFuben" ); 
		--PosTips
		local strPosTips = EnumNewCampaign( campaignlistnum, i, "PosOrTips" ); 
		
		local HuoYueCount = EnumNewCampaign( campaignlistnum, i, "huoyuecount" ); 
		
		local nMyCount = EnumNewCampaign( campaignlistnum, i, "MyCampaingCount" );  
				
		--//0当天未到  1 当天活动中  2 当天已结束 3 已完成 4 距离几天未到 5 级别不够
		local nTimeType,nRemainDay = EnumNewCampaign( campaignlistnum, i, "IsToday" );
		  
		-- 参加时间
		local time_temp = GetTime2Minite() 
		local tshour = string.sub( strStartTime, 1, 2 )
		local tsminite = string.sub( strStartTime, 4, 5 ) 
		local tehour = string.sub( strEndTime, 1, 2 )
		local teminite = string.sub( strEndTime, 4, 5 ) 
		local tmpSTime = tonumber(tshour) * 100 + tonumber(tsminite)
		local tmpETime = tonumber(tehour) * 100 + tonumber(teminite)
 		
		local ItemBar = TodayCampaignListNew_List1:AddItemElement( "SuperBarButton_New", "LEFT", "TodayCampaignListNew","" ,"")
		ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			  
	  local level = Player:GetData( "LEVEL" ); 
	  if level < nLevel then
	  	nTimeType = 5
		 end		 
		 
		if nTimeType == 1 then
			ItemBar:SetText1("#G"..strHuodong )
			ItemBar:SetText2( "#G"..tonumber(nLevel) ) 
			ItemBar:SetText3( "#G"..nTeamType ) 
			if nCampaignCount == 0 then
				ItemBar:SetText4() 
			else
				ItemBar:SetText4( "#G"..tostring(nMyCount).."/"..tostring(nCampaignCount) ) 
			end
			if HuoYueCount == 0 then				
				ItemBar:SetText7()
			else				
				ItemBar:SetText7( "#G"..tostring(HuoYueCount) )
			end
		else
			ItemBar:SetText1(strHuodong )
			ItemBar:SetText2( tonumber(nLevel) ) 
			ItemBar:SetText3( nTeamType ) 
			if nCampaignCount == 0 then
				ItemBar:SetText4() 
			else
				ItemBar:SetText4( tostring(nMyCount).."/"..tostring(nCampaignCount) ) 
			end
			if HuoYueCount == 0 then				
				ItemBar:SetText7()
			else				
				ItemBar:SetText7( tostring(HuoYueCount) )
			end
		end 
		
		if strIconString ~= nil and strIconString ~= "" then
		  local sPos,_ = string.find(strIconString," ");
		  local IconImageSet = string.sub(strIconString,5,sPos-1);
		  local IconIamge = string.sub(strIconString,sPos+7) 
		  if nil ~= IconImageSet and nil ~= IconIamge then
		  	ItemBar:SetImage1(IconImageSet,IconIamge) 
		  end
      
		  if nCommendedValue == 18 or nCommendedValue == 19 or nCommendedValue == 20 then
		  	ItemBar:SetImage2Show()
		  else
		  	ItemBar:SetImage2Hide()
		  end    
				
		  ItemBar:SetButton2Hide();
		  	
		  if nTimeType == 0 then -- 当天未到
		  	if campaignlistnum == campaign_today_timelimited or campaignlistnum == campaign_today_timexieke then
		  		ItemBar:SetText5( tostring(strStartTime).."-"..tostring(strEndTime) )
		  	end
		  	ItemBar:SetButton1Hide();
		  	--ItemBar:SetButton2Hide();
		  elseif nTimeType == 1 then -- 正在发生
		  	--前往参与 征召队友  
		  	if nJoinType ~= nil and ( nJoinType == 0 or nJoinType == 1 ) then 
		  		if SystemSetup:IsClassic() == 0 then
						 ItemBar:SetButton1Text("#{RCTX_150129_26}");
					end  
		  		ItemBar:SetButton1Show();
		  	end
		  	if nJoinType ~= nil and ( nJoinType == 2 ) then  
		  		ItemBar:SetButton1Hide();
		  		ItemBar:SetText5("#G"..strPosTips); 
		  	end
		  	
		  	
		  elseif nTimeType == 2 then -- 已结束
		  	local childImg3 = ItemBar:GetChildItem("TodayCampaignListNew","__auto_SuperBarImage3__")
				if childImg3 then
					childImg3:Show()
					if SystemSetup:IsClassic() == 0 then
						childImg3:SetImage("WM_MainFrame14","CampaignNew_TedEnd") 
					else
						childImg3:SetImage("CampaignNew2","CampaignNew_TedEnd") 
					end
				end
		  	ItemBar:SetButton1Hide();
		  	ItemBar:SetButton2Hide();
		  elseif nTimeType == 3 then -- 已完成
		  	local childImg3 = ItemBar:GetChildItem("TodayCampaignListNew","__auto_SuperBarImage3__")
				if childImg3 then
					childImg3:Show()
					childImg3:SetImage("CommonFrame14","Memo_Finish")
				end  
		  	ItemBar:SetButton1Hide();
		  	ItemBar:SetButton2Hide();
		  elseif nTimeType == 4 then -- 距离多少天
		  	ItemBar:SetText5( tostring(nRemainDay).."天后开启" )
		  	ItemBar:SetButton1Hide();
		  	--ItemBar:SetButton2Hide();
		  elseif nTimeType == 5 then -- 距离多少天
		  	ItemBar:SetText5( tostring(nLevel).."级开启" )
		  	ItemBar:SetButton1Hide();
		  	--ItemBar:SetButton2Hide();
		  end 
			 
		end
		table.insert(g_nContentButton,ItemBar);
	end

	g_CurrentSelect = 0
	TodayCampaignListNew_SetButtonSelected(g_CurrentSelect + 1)
	TodayCampaignListNew_List1:Flash()
	TodayCampaignListNew_List_OnSelectionChanged()
end

function TodayCampaignListNew_CalcListScrollPos(SelectIdx)
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
	if ShowCount * 43 < 400 then
		return 0
	else
		return (ShowCount * 43 - 400) * ((ShowIdx - 1) / (ShowCount - 1))
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function TodayCampaignListNew_Frame_On_ResetPos()

	TodayCampaignListNew : SetProperty("UnifiedPosition", g_TodayCampaignListNew_Frame_UnifiedPosition); 

end

function TodayCampaignListNew_CurListReset( nSelectedRow )

end

function TodayCampaignListNew_TodayListReset( nSelectedRow )

end
 
 
function TodayCampaignListNew_SetBoxImage(nTodayActivePoint)
	
	local nDataRound = DataPool:GetPlayerMission_DataRound(579)
	
	if nTodayActivePoint > 0 then
		local ret = math.mod(nDataRound , 10)
		if ret >= 1 then
			TodayCampaignListNew_Icon2:SetProperty("Image" , "set:Button10 image:Qingtong_kong_Normal")
		else
			TodayCampaignListNew_Icon2:SetProperty("Image" , "set:Button9 image:Qingtong_Normal")
		end
	else
		TodayCampaignListNew_Icon2:SetProperty("Image" , "set:Button9 image:Qingtong_Disable")
	end

	if nTodayActivePoint >= 50 then
		local ret = math.mod(nDataRound , 100)
		if ret >= 10 then
			TodayCampaignListNew_Icon4:SetProperty("Image" , "set:Button10 image:Baiyin_kong_Normal")
		else
			TodayCampaignListNew_Icon4:SetProperty("Image" , "set:Button9 image:Baiyin_Normal")
		end
	else
		TodayCampaignListNew_Icon4:SetProperty("Image" , "set:Button9 image:Baiyin_Disable")
	end

	if nTodayActivePoint >= 150 then
		local ret = math.mod(nDataRound , 1000)
		if ret >= 100 then
			TodayCampaignListNew_Icon6:SetProperty("Image" , "set:Button10 image:Huangjin_kong_Normal")
		else
			TodayCampaignListNew_Icon6:SetProperty("Image" , "set:Button9 image:Huangjin_Normal")
		end
	else
		TodayCampaignListNew_Icon6:SetProperty("Image" , "set:Button9 image:Huangjin_Disable")
	end

	if nTodayActivePoint >= 450 then
		local ret = math.mod(nDataRound , 10000)
		if ret >= 1000 then
			TodayCampaignListNew_Icon8:SetProperty("Image" , "set:Button10 image:Feicui_kong_Normal")
		else
			TodayCampaignListNew_Icon8:SetProperty("Image" , "set:Button9 image:Feicui_Normal")
		end
	else
		TodayCampaignListNew_Icon8:SetProperty("Image" , "set:Button9 image:Feicui_Disable")
	end
	 
	local weektip1200 = "#{HYCT_20210629_86}" 
	local weektip2000 = "#{HYCT_20210629_91}"   
	TodayCampaignListNew_WeeklyGift1:SetToolTip(weektip1200)
	TodayCampaignListNew_WeeklyGift2:SetToolTip(weektip2000) 
end


function TodayCampaignListNew_SwitchToOld()
	--切换视图
	SetOpenCampaignType( 0 )	
	--关闭窗口
	TodayCampaignListNew_OnClosed()
	--打开旧版活动日程
	PushEvent("SHOW_TODAY_CAMPAIGN_LIST")
end
function TodayCampaignListNew_FindStr(strOrg, strSeparator, nFindStartIndex)
	for i=nFindStartIndex, string.len(strOrg),1 do
		local j = 1;
		local k = i;
		while ( string.byte(strOrg,k) == string.byte(strSeparator,j)  and k<=string.len(strOrg) and j<=string.len(strSeparator) )do
			k= k+1
			j= j+1
		end
		if j == string.len(strSeparator)+1 then
			return i;
		end
	end
	return nil;
end

function TodayCampaignListNew_SplitStr(szFullString, szSeparator)
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}

	while true do
		local nFindLastIndex = TodayCampaignListNew_FindStr(szFullString, szSeparator, nFindStartIndex)

		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
    		break
		end
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1

	end

	return nSplitArray,nSplitIndex
end

function TodayCampaignListNew_Alltime_Click()
	local campaignlistnum = -1
	if g_PageNum == 1 then
		campaignlistnum = campaign_today_timelimited
	elseif g_PageNum == 2 then
		campaignlistnum = campaign_today_timeallday
	elseif g_PageNum == 3 then
		campaignlistnum = campaign_today_timefestival
	elseif g_PageNum == 4 then
		campaignlistnum = campaign_today_timexieke
	else
		return
	end 

	local g_CurrentCampaignCount = GetNewCampaignCount( tonumber(campaignlistnum) )

	if g_CurrentSelect < g_CurrentCampaignCount then 
		local strHuodong 	= EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "name" ) 
		local strInfo 	= EnumNewCampaign( tonumber(campaignlistnum), g_CurrentSelect, "ViewAllInfo" ) 
		PushEvent("OPEN_CAMPAIGN_TIMENEW",strInfo,strHuodong)
	else
		PushEvent("CLOSE_CAMPAIGN_TIMENEW")
	end
end

function TodayCampaignListNew_WeeklyShop_Clicked()
	if(IsWindowShow("ActivitySchedule_Shop2")) then
		CloseWindow("ActivitySchedule_Shop2", true)
		return
	end
	if(IsWindowShow("ActivitySchedule_Shop")) then
		CloseWindow("ActivitySchedule_Shop", true)
		return
	end
	if(IsWindowShow("Fenzheng_Shop")) then
		CloseWindow("Fenzheng_Shop", true)
		return
	end
	if(IsWindowShow("FengmingShop")) then
		CloseWindow("FengmingShop", true)
		return
	end
	if(IsWindowShow("Xiake_Shop")) then
		CloseWindow("Xiake_Shop", true)
		return
	end
	PushEvent("OPEN_HUOYUESHOP_H")

	-- Clear_XSCRIPT()
	-- 	Set_XSCRIPT_Function_Name( "OnAskData_L" ); 	    -- 函数名
	-- 	Set_XSCRIPT_ScriptID( 888393 );						-- 脚本编号
	-- 	Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	-- Send_XSCRIPT()
end

function TodayCampaignListNew_HuoYueHaoLiFunc_Week(index)	
	-- 向服务器发送抽奖消息
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnAugury_week");
		Set_XSCRIPT_ScriptID(889336);
		Set_XSCRIPT_Parameter(0,index);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
end


function TodayCampaignListNew_HuoYueHaoLiFunc(index)	
	-- 向服务器发送抽奖消息
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnAugury");
		Set_XSCRIPT_ScriptID(889336);
		Set_XSCRIPT_Parameter(0,index);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
end

function TodayCampaignListNew_BeiWangLu_Clicked()
	
 	-- 动态提示
 -- 	if IsInTServer() == 1 then
 -- --		PushDebugMessage("#{BHKF_140909_327}")
 -- 		return
 -- 	end
 	-- 打开UI
 	Lua_OpenMemo()
end

function TodayCampaignListNew_RefreshIcon8Tips() 
	if IsOpenMoneyRecycle() == 1 then
		local nItemId = GetMoneyRecycleItemIdByWeekDay()
		if nItemId > 0 then
			local str = ScriptGlobal_Format("#{FBJB_20220124_66}", DataPool:Lua_GetItemNameByIndex(nItemId))
			if Player:GetData("IsOriginalJD") == 1 then 
				str = ScriptGlobal_Format("#{SJF_251024_14}", DataPool:Lua_GetItemNameByIndex(nItemId))
			end
			if Player:GetData("Is2606S") == 1 then 
				str = ScriptGlobal_Format("#{QXF_260623_18}", DataPool:Lua_GetItemNameByIndex(nItemId))
			end
			TodayCampaignListNew_Icon8:SetToolTip(str)
			TodayCampaignListNew_Icon8Disabled:SetToolTip(str) 
		end
	end
	
end
local function TeQuanKaTips()
	if 1~=DataPool:Lua_TeQuanKaIsOpen()   then
		return ""
	end
	--精通加速
	local retStr = ""
	if Player:GetLevel() >= 80 then
		local state = Lua_GetTeQuanKaState("jingtong")
		if state == 1 then
			--激活普通
			retStr = "#{XFTQ_230203_01}"
		elseif state == 2  then
			--激活高级
			retStr = "#{XFTQ_230203_02}"
		end
	end

	return retStr
end

function TodayCampaignListNew_RefreshTips() 
	local kajiType = KaJi:LuaFnGetKaJiType(20)
	local kaji_type = 0
	if nil~=kajiType then
		kaji_type = kajiType
	end
	for i = 1, table.getn(g_tips_control_day) do 
		if g_BaoXiangHYDayButtonTips[kaji_type][i] ~= nil then
			local tips = g_BaoXiangHYDayButtonTips[kaji_type][i]
			if Player:GetData("IsOriginalJD") == 1 then 
				tips = g_BaoXiangHYDayButtonTips_OriginalJD[kaji_type][i] 
			   end
			if Player:GetData("Is2606S") == 1 then 
				tips = g_BaoXiangHYDayButtonTips_2606S[kaji_type][i] 
   			end
			g_button_today[i]:SetToolTip(tips)
			g_button_today_tipsctl[i]:SetToolTip(tips)			
			
		end	 
	
		if g_tips_status_day[i] == 0 then
			g_tips_control_day[i]:Hide()
			g_button_today[i]:Enable()
			g_button_today_tipsctl[i]:Hide()
		elseif g_tips_status_day[i] == 1 then
			g_tips_control_day[i]:Show()
			g_button_today[i]:Enable()
			g_button_today_tipsctl[i]:Hide()
		elseif g_tips_status_day[i] == 2 then
			g_tips_control_day[i]:Hide()
			g_button_today[i]:Disable()
			g_button_today_tipsctl[i]:Show()  
		end
	end

	local weekBoxTips = g_BaoXiangHYWeekButtonTips
	
	if Player:GetData("IsOriginalJD") == 1 then
		if Player:GetLevel() >= 120 then 
			weekBoxTips = g_BaoXiangHYWeekButtonTips80_OriginalJD_129
		elseif Player:GetLevel() >= 80 then 
			weekBoxTips = g_BaoXiangHYWeekButtonTips80_OriginalJD 
		else
			weekBoxTips = g_BaoXiangHYWeekButtonTips_OriginalJD
		end
	elseif Player:GetData("Is2606S") == 1 then 
		weekBoxTips = g_BaoXiangHYWeekButtonTips_2606S 
	else
		if Player:GetLevel() >= 120 then 
			weekBoxTips = g_BaoXiangHYWeekButtonTips80_129
		elseif Player:GetLevel() >= 80 then 
			weekBoxTips = g_BaoXiangHYWeekButtonTips80
		else
			weekBoxTips = g_BaoXiangHYWeekButtonTips 
		end
	end

	for i = 1, table.getn(g_tips_control_week) do		
		if weekBoxTips[kaji_type][i] ~= nil then
			g_button_week[i]:SetToolTip(weekBoxTips[kaji_type][i]..TeQuanKaTips())
			g_button_week_tipsctl[i]:SetToolTip(weekBoxTips[kaji_type][i]..TeQuanKaTips())
		end		
		if g_tips_status_week[i] == 0 then
			g_button_week[i]:Enable()
			g_tips_control_week[i]:Hide()
			g_button_week_tipsctl[i]:Hide()
		elseif g_tips_status_week[i] == 1 then
			g_tips_control_week[i]:Show()		
			g_button_week[i]:Enable()
			g_button_week_tipsctl[i]:Hide()
		elseif g_tips_status_week[i] == 2 then
			g_tips_control_week[i]:Hide()		
			g_button_week[i]:Disable()
			g_button_week_tipsctl[i]:Show()
		end
	end
end

-- function TodayCampaignListNew_IsZhouNianJiangHongFu()
-- 	local curDay = DataPool:GetServerDayTime()
-- 	if curDay >= g_ZhouNianJiangHongFu_BeginTime and curDay <= g_ZhouNianJiangHongFu_EndTime then
-- 		return 1
-- 	end
-- 	return 0 
-- end