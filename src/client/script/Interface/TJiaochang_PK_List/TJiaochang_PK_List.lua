local g_Timers = 0
local g_Seconds = 2

local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_List_PageCount = 20;
local g_Challenge_CurPage = 0;


local CHALLENGE_TYPE_ICON_LEFT = {};		--	比赛类型图标
local CHALLENGE_TYPE_ICON_RIGHT = {};

local g_MenPaiCount = 15; --桃花岛 menpai15 mptodo

local CHALLENGE_MENPAISTRINFO = 
{
[0]="#{FBTZ_130125_269}",--"少林",
[1]="#{FBTZ_130125_270}",--"明教",
[2]="#{FBTZ_130125_271}",--"丐帮",
[3]="#{FBTZ_130125_272}",--"武当",
[4]="#{FBTZ_130125_273}",--"峨眉",
[5]="#{FBTZ_130125_274}",--"星宿",
[6]="#{FBTZ_130125_275}",--"天龙",
[7]="#{FBTZ_130125_276}",--"天山",
[8]="#{FBTZ_130125_277}",--"逍遥",
[9]="#{FBTZ_130125_279}",--"无门派"
[10]="#{FBTZ_130125_278}",--"慕容",
[11]="#{XMPTM_130123_01}",--"唐门",
[12]="#{XMPGG_160524_02}",--"鬼谷",
[13]="#{XQ_MP_15}",--"桃花岛",
[14]="#{XMPHM_210604_01}",
[15]="#{GMGameInterface_Script_DataPool_Info_ERenGu}",--menpai15 mptodo
}

local g_SceneType = 1; --T服休息室

function TJiaochang_PK_List_PreLoad()
    this:RegisterEvent("SHOW_CHALLENGE_LIST")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function TJiaochang_PK_List_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= TJiaochang_PK_List_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= TJiaochang_PK_List_Frame:GetProperty("UnifiedYPosition");
	
	CHALLENGE_TYPE_ICON_LEFT[1] = TJiaochang_TeamImage1_1
	CHALLENGE_TYPE_ICON_LEFT[2] = TJiaochang_TeamImage2_1
	CHALLENGE_TYPE_ICON_LEFT[3] = TJiaochang_TeamImage3_1
	CHALLENGE_TYPE_ICON_LEFT[4] = TJiaochang_TeamImage4_1
	CHALLENGE_TYPE_ICON_LEFT[5] = TJiaochang_TeamImage5_1
	CHALLENGE_TYPE_ICON_LEFT[6] = TJiaochang_TeamImage6_1
	CHALLENGE_TYPE_ICON_LEFT[7] = TJiaochang_TeamImage7_1
	CHALLENGE_TYPE_ICON_LEFT[8] = TJiaochang_TeamImage8_1
	CHALLENGE_TYPE_ICON_LEFT[9] = TJiaochang_TeamImage9_1
	CHALLENGE_TYPE_ICON_LEFT[10] = TJiaochang_TeamImage10_1
	CHALLENGE_TYPE_ICON_LEFT[11] = TJiaochang_TeamImage11_1
	CHALLENGE_TYPE_ICON_LEFT[12] = TJiaochang_TeamImage12_1
	CHALLENGE_TYPE_ICON_LEFT[13] = TJiaochang_TeamImage13_1
	CHALLENGE_TYPE_ICON_LEFT[14] = TJiaochang_TeamImage14_1
	CHALLENGE_TYPE_ICON_LEFT[15] = TJiaochang_TeamImage15_1
	CHALLENGE_TYPE_ICON_LEFT[16] = TJiaochang_TeamImage16_1
	CHALLENGE_TYPE_ICON_LEFT[17] = TJiaochang_TeamImage17_1
	CHALLENGE_TYPE_ICON_LEFT[18] = TJiaochang_TeamImage18_1
	CHALLENGE_TYPE_ICON_LEFT[19] = TJiaochang_TeamImage19_1
	CHALLENGE_TYPE_ICON_LEFT[20] = TJiaochang_TeamImage20_1
	
	CHALLENGE_TYPE_ICON_RIGHT[1] = TJiaochang_TeamImage1_2
	CHALLENGE_TYPE_ICON_RIGHT[2] = TJiaochang_TeamImage2_2
	CHALLENGE_TYPE_ICON_RIGHT[3] = TJiaochang_TeamImage3_2
	CHALLENGE_TYPE_ICON_RIGHT[4] = TJiaochang_TeamImage4_2
	CHALLENGE_TYPE_ICON_RIGHT[5] = TJiaochang_TeamImage5_2
	CHALLENGE_TYPE_ICON_RIGHT[6] = TJiaochang_TeamImage6_2
	CHALLENGE_TYPE_ICON_RIGHT[7] = TJiaochang_TeamImage7_2
	CHALLENGE_TYPE_ICON_RIGHT[8] = TJiaochang_TeamImage8_2
	CHALLENGE_TYPE_ICON_RIGHT[9] = TJiaochang_TeamImage9_2
	CHALLENGE_TYPE_ICON_RIGHT[10] = TJiaochang_TeamImage10_2
	CHALLENGE_TYPE_ICON_RIGHT[11] = TJiaochang_TeamImage11_2
	CHALLENGE_TYPE_ICON_RIGHT[12] = TJiaochang_TeamImage12_2
	CHALLENGE_TYPE_ICON_RIGHT[13] = TJiaochang_TeamImage13_2
	CHALLENGE_TYPE_ICON_RIGHT[14] = TJiaochang_TeamImage14_2
	CHALLENGE_TYPE_ICON_RIGHT[15] = TJiaochang_TeamImage15_2
	CHALLENGE_TYPE_ICON_RIGHT[16] = TJiaochang_TeamImage16_2
	CHALLENGE_TYPE_ICON_RIGHT[17] = TJiaochang_TeamImage17_2
	CHALLENGE_TYPE_ICON_RIGHT[18] = TJiaochang_TeamImage18_2
	CHALLENGE_TYPE_ICON_RIGHT[19] = TJiaochang_TeamImage19_2
	CHALLENGE_TYPE_ICON_RIGHT[20] = TJiaochang_TeamImage20_2

end

function TJiaochang_PK_List_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		TJiaochang_PK_List_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TJiaochang_PK_List_ResetPos()
	elseif( event == "SHOW_CHALLENGE_LIST" ) then
		local curSceneID = GetSceneID(); --
		if curSceneID ~= 1062 then
			return 
		end
		TJiaochang_PK_List_FirstFillData()
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function TJiaochang_PK_List_ClearItemList()
	TJiaochang_PK_List_PkList:RemoveAllItem()
	for i = 1,20 do
		CHALLENGE_TYPE_ICON_LEFT[i]:Hide()
		CHALLENGE_TYPE_ICON_RIGHT[i]:Hide()
	end
	TJiaochang_PK_List_UpButton:Disable()
	TJiaochang_PK_List_DownButton:Disable()
end

function TJiaochang_PK_List_FirstFillData()
	TJiaochang_PK_List_ClearItemList()
	local nCount = DataPool:GetChallengeCount()
	if nCount <= 0 then
		PushDebugMessage("暂无比赛")
		g_Challenge_CurPage = 0
		TJiaochang_PK_List_ClearItemList()
		TJiaochang_PK_List_CountFenye : SetText("")
	else
		g_Challenge_CurPage = 0
		TJiaochang_PK_List_FillListData()
	end

	this:Show()
end

function TJiaochang_PK_List_NextPage()
	local nCount = DataPool:GetChallengeCount()
	if g_Challenge_CurPage * g_List_PageCount + g_List_PageCount >= nCount then
		return
	end
	g_Challenge_CurPage = g_Challenge_CurPage + 1
	TJiaochang_PK_List_FillListData()
end
function TJiaochang_PK_List_PrePage()
	if g_Challenge_CurPage <= 0 then
		return
	end
	g_Challenge_CurPage = g_Challenge_CurPage - 1
	TJiaochang_PK_List_FillListData()
end
function TJiaochang_PK_List_FillListData()

	TJiaochang_PK_List_ClearItemList()
	local startpos = g_Challenge_CurPage * g_List_PageCount
	local endpos = startpos + 20
	local nCount = DataPool:GetChallengeCount()
	if startpos >= nCount then
		return
	end
	
	if startpos > 0 then
		TJiaochang_PK_List_UpButton:Enable()
	else	
		TJiaochang_PK_List_UpButton:Disable()
	end
	
	if endpos < nCount then
		TJiaochang_PK_List_DownButton:Enable()
	else
		TJiaochang_PK_List_DownButton:Disable()
	end
	
	local maxpages = math.ceil( tonumber(nCount/g_List_PageCount) )
	TJiaochang_PK_List_CountFenye : SetText(tostring(g_Challenge_CurPage+1).."/"..tostring(maxpages))

	TJiaochang_PK_List_PkList:SetProperty("SortDirection", "None")
	for i=startpos, endpos-1 do
	
		local curpos = i - startpos
		if curpos < 0 or curpos >= 20 then
			break
		end
		
		local ret,nameA,typeA,menpaiA,levelA,zoneWorldIdA,nameB,typeB,menpaiB,levelB,zoneWorldIdB = DataPool:GetChallengeInfo(i)
		
		if ret == 0 then
			break
		end
		
		if typeA == 2 then
			CHALLENGE_TYPE_ICON_LEFT[curpos+1]:SetProperty("Image","set:Button2 image:Icon_GoldCoin")
			CHALLENGE_TYPE_ICON_LEFT[curpos+1]:SetToolTip( "#{SJBW_130823_27}" )
			CHALLENGE_TYPE_ICON_LEFT[curpos+1]:Show()
		elseif typeA == 1 then
			CHALLENGE_TYPE_ICON_LEFT[curpos+1]:SetProperty("Image","set:UIIcons image:LeaderOpening")
			CHALLENGE_TYPE_ICON_LEFT[curpos+1]:SetToolTip( "#{SJBW_130823_31}" )
			CHALLENGE_TYPE_ICON_LEFT[curpos+1]:Show()
		end
		
		local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
		if selfZoneWorldID ~= -1 and selfZoneWorldID ~= zoneWorldIdA then
			local serverName = DataPool:GetServerName( zoneWorldIdA )
			nameA = nameA.."@"..tostring(serverName)
		end
		if selfZoneWorldID ~= -1 and Lua_GetAnonymousSceneInfo() == 1 and selfZoneWorldID ~= zoneWorldIdA  then--在需要匿名的场景并且A玩家与观战者的worldid不同
			nameA = ScriptGlobal_Format("#{YCXX_20220712_01}"," ")
		end
		
		TJiaochang_PK_List_PkList:AddNewItem("",0,curpos)
		TJiaochang_PK_List_PkList:AddNewItem(nameA,1,curpos)
		if menpaiA >= 0 and menpaiA <= g_MenPaiCount then -- 11是门派索引范围,增加新门派时要改这里
			TJiaochang_PK_List_PkList:AddNewItem(CHALLENGE_MENPAISTRINFO[menpaiA],2,curpos)
		else
			TJiaochang_PK_List_PkList:AddNewItem("",2,curpos)
		end
		TJiaochang_PK_List_PkList:AddNewItem(tostring(levelA),3,curpos)
		TJiaochang_PK_List_PkList:AddNewItem("#RVS",4,curpos)
		
		if typeB == 2 then
			CHALLENGE_TYPE_ICON_RIGHT[curpos+1]:SetProperty("Image","set:Button2 image:Icon_GoldCoin")
			CHALLENGE_TYPE_ICON_RIGHT[curpos+1]:SetToolTip( "#{SJBW_130823_27}" )
			CHALLENGE_TYPE_ICON_RIGHT[curpos+1]:Show()
		elseif typeB == 1 then
			CHALLENGE_TYPE_ICON_RIGHT[curpos+1]:SetProperty("Image","set:UIIcons image:LeaderOpening")
			CHALLENGE_TYPE_ICON_RIGHT[curpos+1]:SetToolTip( "#{SJBW_130823_31}" )
			CHALLENGE_TYPE_ICON_RIGHT[curpos+1]:Show()
		end
		
		if selfZoneWorldID ~= 0 and selfZoneWorldID ~= zoneWorldIdB then
			local serverName = DataPool:GetServerName( zoneWorldIdB )
			nameB = nameB.."@"..tostring(serverName)
		end
		if selfZoneWorldID ~= 0 and Lua_GetAnonymousSceneInfo() == 1 and selfZoneWorldID ~= zoneWorldIdB then--在需要匿名的场景并且B玩家与观战者的worldid不同
			nameB = ScriptGlobal_Format("#{YCXX_20220712_01}"," ")
		end

		TJiaochang_PK_List_PkList:AddNewItem("",5,curpos)
		TJiaochang_PK_List_PkList:AddNewItem(nameB,6,curpos)
		if menpaiB >= 0 and menpaiB <= g_MenPaiCount then -- 11是门派索引范围,增加新门派时要改这里
			TJiaochang_PK_List_PkList:AddNewItem(CHALLENGE_MENPAISTRINFO[menpaiB],7,curpos)
		else
			TJiaochang_PK_List_PkList:AddNewItem("",7,curpos)
		end
		TJiaochang_PK_List_PkList:AddNewItem(tostring(levelB),8,curpos)
	end
end

function TJiaochang_PK_List_PkList_On_SelectionChanged()

end

function TJiaochang_PK_List_CloseClicked()
    this:Hide()
end

function TJiaochang_PK_List_RefreshButtonClicked()
	if not TJiaochang_PK_List_PassTime(g_Seconds) then
		PushDebugMessage("#{SJBW_130823_52}");
		return
	end

	--this:Hide()
	--TJiaochang_PK_List_ClearItemList()
	DataPool:AskChallengeList(g_SceneType);

end

function TJiaochang_PK_List_WatchButtonClicked()
	local nIndex = TJiaochang_PK_List_PkList:GetSelectItem()
	if nIndex == -1 then
		PushDebugMessage("#{XCGZ_161028_01}")
		return
	end

	local ret = DataPool:EnterChallengeView(g_Challenge_CurPage * g_List_PageCount+nIndex)
	--if ret == 1 then
	--	this:Hide();
	--end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function TJiaochang_PK_List_ResetPos()
	TJiaochang_PK_List_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	TJiaochang_PK_List_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function TJiaochang_PK_List_PassTime(iSeconds)
   local iCur = FindFriendDataPool:GetTickCount()
   if ( iCur - g_Timers < iSeconds * 1000) then
      return false;
   else
      g_Timers = iCur;
   	  return true;
   end
end
