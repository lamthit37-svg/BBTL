----------------------
-- PayTopList ---
----------------------
local g_Cardlist = {}
local g_PayTopList_UnifiedPosition =nil;
local g_CurJifenData = 1057;
local g_TotalJifenData = 1058;
local g_PayTopList_TWorld_TabCtrl={}

local g_UpdataCooldown = 4*1000;	--4s冷却
local g_InCooldown = 0;

local g_FwinerName = "";
local g_SwinerName = "";
local g_State = 1;
local g_page_cur = 1;
local g_tserver_awards = {}
local g_banlist = {}
local g_PayTopList_TServer_CurRankType=0	--全服榜当前榜单类型 0天 1地 2人
local g_PayTopList_TServer_RankInfo={			--三个榜的信息--总大小 及 当前页码
	[0] = { size=45, name="#{MDJH_221102_14}", curPage=0 },
	[1] = { size=45, name="#{MDJH_221102_15}", curPage=0 },
	[2] = { size=60, name="#{MDJH_221102_16}", curPage=0 },
	}
	
--===============================================
-- PreLoad()
--===============================================
function PayTopList_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("OPEN_XIAOFEI_TOPLIST");
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("FATIE_SECCONFIRM");	
end

--===============================================
-- OnLoad()
--===============================================
function PayTopList_OnLoad()
	g_PayTopList_UnifiedPosition = PayTopList_Frame:GetProperty("UnifiedPosition")
	
	g_PayTopList_TWorld_TabCtrl[1] = PayTopList_Laypage1;
	g_PayTopList_TWorld_TabCtrl[2] = PayTopList_Laypage2;
	g_PayTopList_TWorld_TabCtrl[3] = PayTopList_Laypage3;
	
	g_tserver_awards.itemcount = {
		255,140,110,90,75,60,45,35,25,15,
	}

	g_banlist[0] = 5143

end

--===============================================
-- OnEvent()
--===============================================
function PayTopList_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		return
	end
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 20130512) then
		local state = Get_XParam_INT(0)
		local ntype = Get_XParam_INT(1)
		local ndate = Get_XParam_INT(2)
		local ntype2 = Get_XParam_INT(3)
		local ndate2 = Get_XParam_INT(4)

		PayTopList_SetLeaveTime(state,ntype,ndate,ntype2,ndate2)

	elseif (event == "ADJEST_UI_POS") then
		PayTopList_ResetPos()
	elseif (event == "OPEN_XIAOFEI_TOPLIST") then
		PushEvent("CLOSE_BOOTH") --关闭批量购买窗口Shop_MBuy
		
		if tonumber(arg0) ~= 0 then
			g_page_cur = tonumber(arg0)
		else
			if g_InCooldown == 0 then
				PayTopList_InitData()
				if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(49) > 0 then  --卡级
					PayTopList_Intro:SetText("#{MDJH_260625_28}")
					PayTopList_Intro2:SetText("#{MDJH_141014_08}")
					PayTopList_Button1:SetProperty("UnifiedPosition", "{{0.000000,320.000000},{0.000000,91.000000}}")
					PayTopList_Intro_Help:SetProperty("UnifiedPosition", "{{0.000000,724.000000},{0.000000,180.000000}}")
					PayTopList_Intro_Help:Show();
				elseif Player:GetData("IsOriginalJD") == 1 then--删减服
					PayTopList_Intro:SetText("#{MDJH_260625_29}")
					PayTopList_Intro2:SetText("#{MDJH_260625_40}")
					PayTopList_Button1:SetProperty("UnifiedPosition", "{{0.000000,320.000000},{0.000000,100.000000}}")
					PayTopList_Intro_Help:Hide();
				else
					PayTopList_Intro:SetText("#{MDJH_130507_37}")
					PayTopList_Intro2:SetText("#{MDJH_141014_08}")
					PayTopList_Button1:SetProperty("UnifiedPosition", "{{0.000000,320.000000},{0.000000,91.000000}}")					
					PayTopList_Intro_Help:Hide();
				end
		
				PayTopList_SetCheckBox(g_page_cur)
				this:Show();
			else
				PushDebugMessage("#{MDJH_130507_33}")
			end
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PayTopList_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		PayTopList_Close()
	elseif (event == "FATIE_SECCONFIRM") then		
		if arg0 == "PayTopList_BenQu_Open" then	
			PayTopList_SetCheckBox(1)
			local curJifen =  DataPool:GetPlayerMission_DataRound(g_CurJifenData);
			local curJifenStr = ScriptGlobal_Format("#{MDJH_130507_41}", curJifen)
			PayTopList_AvailNumText:SetText(curJifenStr)			
			this:Show();
		elseif arg0 == "PayTopList_ZhanQu_Open" then
			PayTopList_SetCheckBox(2)
			local curJifen =  DataPool:GetPlayerMission_DataRound(g_CurJifenData);
			local curJifenStr = ScriptGlobal_Format("#{MDJH_130507_41}", curJifen)
			PayTopList_AvailNumText:SetText(curJifenStr)			
			this:Show();
		end
	end
end

function PayTopList_SetLeaveTime(state,ntype,ndate,ntype2,ndate2)
	local nowstate = tonumber(state)
	local nowtype = tonumber(ntype)
	local nowdate = tonumber(ndate)
	
	local nowtype2 = tonumber(ntype2)
	local nowdate2 = tonumber(ndate2)
	
	local strneed = ""
	local strneed2 = ""
	if(nowstate == 1) then
		strneed = PayTopList_SetTimetipsData("#{MDJH_130507_53}", nowtype, nowdate)
		strneed2 = PayTopList_SetTimetipsData("#{MDJH_141014_29}", nowtype2, nowdate2)
	elseif( nowstate == 2) then
		strneed = PayTopList_SetTimetipsData("#{MDJH_130507_54}", nowtype, nowdate)
		strneed2 = PayTopList_SetTimetipsData("#{MDJH_141014_29}", nowtype2, nowdate2)
	elseif( nowstate == 3) then
		strneed = PayTopList_SetTimetipsData("#{MDJH_130507_55}", nowtype, nowdate)
		strneed2 = PayTopList_SetTimetipsData("#{MDJH_141014_29}", nowtype2, nowdate2)
	elseif( nowstate == 4) then
		strneed = "#{MDJH_130507_56}"
		strneed2 = "#{MDJH_141014_30}"
	elseif( nowstate == 5) then		--多修改一条字典
		strneed = "#{MDJH_130507_56}"
		strneed2 = "#{MDJH_141014_30}"
	end
	--PayTopList_LastTime:SetText(strneed)
	PayTopList_LastTime2:SetText(strneed)
	g_State = nowstate;
end

function PayTopList_SetWinerName()

	g_FwinerName =""
	g_SwinerName =""

	local fwinername = DataPool:Lua_GetYBTopListWinerName(0)
	local swinername = DataPool:Lua_GetYBTopListWinerName(1)

	if(g_State == 1) then
		g_FwinerName="#{MDJH_130507_59}".."#{MDJH_130507_57}";
		g_SwinerName="#{MDJH_130507_59}".."#{MDJH_130507_57}";
	elseif( g_State == 2) then
		if(fwinername == "") then
			g_FwinerName="#{MDJH_130507_58}";
		else
			g_FwinerName="#{MDJH_130507_59}"..fwinername;
		end
		g_SwinerName="#{MDJH_130507_59}".."#{MDJH_130507_57}";
	elseif( g_State == 3) then
		if(fwinername == "") then
			g_FwinerName="#{MDJH_130507_58}";
		else
			g_FwinerName="#{MDJH_130507_59}"..fwinername;
		end
		if(swinername == "") then
			g_SwinerName="#{MDJH_130507_58}";
		else
			g_SwinerName="#{MDJH_130507_59}"..swinername;
		end
	elseif( g_State == 4 or g_State == 5 ) then
		if(fwinername == "") then
			g_FwinerName="#{MDJH_130507_58}";
		else
			g_FwinerName="#{MDJH_130507_59}"..fwinername;
		end
		if(swinername == "") then
			g_SwinerName="#{MDJH_130507_58}";
		else
			g_SwinerName="#{MDJH_130507_59}"..swinername;
		end
	end

	PayTopList_PlayerNameText1:SetText(g_FwinerName)
	PayTopList_PlayerNameText2:SetText(g_SwinerName)
end

function PayTopList_SetTimetipsData(DirStr, nowtype,nowdate)
	local lstrneed = ""
		if(nowtype == 1) then
			lstrneed = ScriptGlobal_Format(DirStr,nowdate.."天")
		elseif(nowtype == 2) then
			lstrneed = ScriptGlobal_Format(DirStr,nowdate.."小时")
		elseif(nowtype == 3) then
			lstrneed = ScriptGlobal_Format(DirStr,nowdate.."分")
		elseif(nowtype == 4) then
			lstrneed = ScriptGlobal_Format(DirStr,"不足一分钟")
		end
		return lstrneed
end

function PayTopList_ResetPos()
	PayTopList_Frame:SetProperty("UnifiedPosition",g_PayTopList_UnifiedPosition)
end

function PayTopList_InitData()

	local bBanned = 0
	local id = DataPool:GetSelfZoneWorldID();
	for i,worldid in g_banlist do
		if worldid == id then
			bBanned = 1
			break
		end
	end	
	
	local g_awardtips = {}

	g_awardtips[1] = "#{MDJH_130507_43}"
	g_awardtips[2] = "#{MDJH_130507_44}"
	g_awardtips[3] = "#{MDJH_130507_45}"
	g_awardtips[4] = "#{MDJH_130507_46}"
	g_awardtips[5] = "#{MDJH_130507_47}"
	g_awardtips[6] = "#{MDJH_130507_48}"
	g_awardtips[7] = "#{MDJH_130507_49}"
	g_awardtips[8] = "#{MDJH_130507_50}"
	g_awardtips[9] = "#{MDJH_130507_51}"
	g_awardtips[10] = "#{MDJH_130507_52}"

	local curJifen =  DataPool:GetPlayerMission_DataRound(g_CurJifenData);
	local totalJifen =  DataPool:GetPlayerMission_DataRound(g_TotalJifenData);

	local curJifenStr = ScriptGlobal_Format("#{MDJH_130507_41}", curJifen)
	local totalJifenStr = ScriptGlobal_Format("#{MDJH_130507_40}", totalJifen)
	PayTopList_GetNumText:SetText(totalJifenStr)
	PayTopList_AvailNumText:SetText(curJifenStr)
	PayTopList_TopList:RemoveAllItem()
	for i=0,9 do
		local index,name,menpai,level,cost = DataPool:Lua_GetYBTopListInfo(i)
		local menpaistr = PayTopList_GetMenpai(menpai)
		if(index ~= nil and index >= 0) then
			local szAwardTips=g_awardtips[i+1];
			
			local bHasExItem=1
			if ( KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(49) > 0 ) or Player:GetData("IsOriginalJD") == 1 then  --卡级 or 删减 
				bHasExItem=0
			end
			
			if bHasExItem > 0 then
				if cost >= 4000000 then
					szAwardTips = szAwardTips .. "#{MDJH_250530_2}"
				else
					szAwardTips = szAwardTips .. "#{MDJH_250530_15}"
				end
			end
			if name ~= "" then
				-- local menpainame = GetShowOffMenpaiByID(menpai)
				PayTopList_TopList:AddNewItem("    #cfff263"..tostring(i+1),0,i)
				PayTopList_TopList:AddNewItem("#cfff263"..name,1,i)
				PayTopList_TopList:AddNewItem("#cfff263"..menpaistr,2,i)
				PayTopList_TopList:AddNewItem("#cfff263"..level,3,i)
				PayTopList_TopList:AddNewItem("#cfff263"..cost,4,i)
				PayTopList_TopList:AddNewItem(szAwardTips,5,i)
			else
				PayTopList_TopList:AddNewItem("    #cfff263"..tostring(i+1),0,i)
				PayTopList_TopList:AddNewItem("#{MDJH_130507_42}",1,i)
				PayTopList_TopList:AddNewItem("",2,i)
				PayTopList_TopList:AddNewItem("",3,i)
				PayTopList_TopList:AddNewItem("",4,i)
				PayTopList_TopList:AddNewItem(szAwardTips,5,i) 
			end

		end
	end
	
	g_InCooldown = 1;
	PayTopList_SetWinerName()
	SetTimer("PayTopList","PayTopList_g_UpdataCooldown()",g_UpdataCooldown);
end

function PayTopList_g_UpdataCooldown()
	g_InCooldown = 0;
	KillTimer("PayTopList_g_UpdataCooldown()");
end

function PayTopList_GetMenpai(menpai)
	-- 得到门派名称.
	if(0 == menpai) then
		strName = "少林";

	elseif(1 == menpai) then
		strName = "明教";

	elseif(2 == menpai) then
		strName = "丐帮";

	elseif(3 == menpai) then
		strName = "武当";

	elseif(4 == menpai) then
		strName = "峨嵋";

	elseif(5 == menpai) then
		strName = "星宿";

	elseif(6 == menpai) then
		strName = "天龙";

	elseif(7 == menpai) then
		strName = "天山";

	elseif(8 == menpai) then
		strName = "逍遥";

	elseif(9 == menpai) then
		strName = "无门派";

	elseif(10== menpai) then
		strName = "慕容";

	elseif(11== menpai) then
		strName = "唐门";
		
	elseif(12== menpai) then
		strName = "鬼谷";
	elseif(13== menpai) then
		strName = "#{XQ_MP_15}"; --桃花岛
	elseif(14== menpai) then
		strName = "#{XMPHM_210604_01}";
	elseif(15== menpai) then--menpai15 mptodo
		strName = "#{GMGameInterface_Script_DataPool_Info_ERenGu}";
	end
	return strName;
end

--===============================================
-- Close()
--===============================================
function PayTopList_Close()
	return this:Hide()
end

function PayTopList_CloseClicked()
	PayTopList_Close()
end

function PayTopList_GetFirstLoopPrize()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientPrize" )
		Set_XSCRIPT_ScriptID( 890084 )
		Set_XSCRIPT_Parameter(0,1);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function PayTopList_GetSecondLoopPrize()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientPrize" )
		Set_XSCRIPT_ScriptID( 890084 )
		Set_XSCRIPT_Parameter(0,2);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function PayTopList_GetFinalLoopPrize()

	if g_State < 4  then
		PushDebugMessage("#{MDJH_130507_61}")
		return
	end
	local binlist = 0
	local index = 0
	local myGuid = Player:GetGUID();
	for i=0,9 do
		local _,_,_,_,_,nGuid = DataPool:Lua_GetYBTopListInfo(i)
		if myGuid == nGuid then
			binlist = 1
			index = i
		end		
	end
	
	if binlist == 0  then
		PushDebugMessage("#{MDJH_130507_63}")
		return
	end
	--打开选择界面
	-- index = index+1
	--PushEvent("OPEN_SHENGMINGXIANHE",index)
	
	Clear_XSCRIPT()
		 Set_XSCRIPT_Function_Name( "ClientPrize" )
		 Set_XSCRIPT_ScriptID( 890084 )
		 Set_XSCRIPT_Parameter(0,3);
		 Set_XSCRIPT_ParamCount(1)
	 Send_XSCRIPT()
end

function PayTopList_GetTServerPrize()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientPrize" )
		Set_XSCRIPT_ScriptID( 890084 )
		Set_XSCRIPT_Parameter(0,10);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function PayTopList_UpdataInfo()
	if g_InCooldown == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientAskTopList" )
			Set_XSCRIPT_ScriptID( 890084 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	else
		PushDebugMessage("#{MDJH_130507_33}")
	end
end

function PayTopList_Goto4()
	GameProduceLogin:OpenURL(GetWeblink("WEB_MINGDONG"))
end

function PayTopList_Button1Clicked()
	PushEvent("UI_COMMAND",20141014)
end

--全服榜初始化
function PayTopList_TServer_Init()

	--得到自己的信息
	local myGuid = Player:GetGUID();
	local nRank, nYuanbaoUse, nRankType, nWorldRank = DataPool:Lua_GetYBTopListInfo_SelfRank( myGuid );
	if nRank ~= nil and nRank >= 0 then
		PayTopList_MyRankText:SetText( ScriptGlobal_Format("#{MDJH_221102_07}", nRank+1 ) )
	else
		PayTopList_MyRankText:SetText( "#{MDJH_221102_08}" )
	end
	if nRank ~= nil and nRank >= 0 and nYuanbaoUse ~= nil and nYuanbaoUse >= 4000000 then
		PayTopList_RankStatusText:SetText( ScriptGlobal_Format("#{MDJH_221102_11}", PayTopList_GetTWorldRandTypeStr(nRank) ) )
	else
		PayTopList_RankStatusText:SetText( "#{MDJH_221102_12}" )
	end
	if nRankType ~= nil and nWorldRank ~= nil and g_PayTopList_TServer_RankInfo[nRankType]~=nil and nWorldRank >= 0 then
		PayTopList_AllSeverRankText:SetText( ScriptGlobal_Format("#{MDJH_221102_09}", tostring(g_PayTopList_TServer_RankInfo[nRankType].name), tostring(nWorldRank + 1) ) )
	else
		PayTopList_AllSeverRankText:SetText( "#{MDJH_221102_10}" )
		nRankType = 0;
		nRank = 0;
	end
	PayTopList_RankGetNumText:SetText( ScriptGlobal_Format("#{MDJH_221102_39}", DataPool:GetPlayerMission_DataRound(g_TotalJifenData) ) )	
	
	for i=1, 3 do
		g_PayTopList_TWorld_TabCtrl[i]:SetCheck(0);
		 g_PayTopList_TServer_RankInfo[i-1].curPage = 0;
	end

	PayTopList_UpdateTWorldData(nRankType, math.floor(nWorldRank/10) )
		
	if g_PayTopList_TWorld_TabCtrl[nRankType+1] ~= nil then
		g_PayTopList_TWorld_TabCtrl[nRankType+1]:SetCheck(1);
	end
	
end

function PayTopList_SetCheckBox(idx)
	if idx ~= 1 and idx ~= 2 then
		return
	end
	
	if idx == 2 then
		local id = DataPool:GetSelfZoneWorldID();
		for i,worldid in g_banlist do
			if worldid == id then
				PushDebugMessage("#{MDJH_141014_32}")
				return
			end
		
		end	
	end
	if idx == 1 then
		PayTopList_Tab1:SetCheck(1)
		PayTopList_Tab2:SetCheck(0)
		PayTopList_Tab3:SetCheck(0)			
		PayTopList_Intro:Show()
		PayTopList_ListFrame:Show()
		PayTopList_ButtonFrame:Show()
		PayTopList_Intro2:Hide()
		PayTopList_ListFrame2:Hide()
		PayTopList_ButtonFrame2:Hide()
		PayTopList_Laypage:Hide();
		PayTopList_GetNumText:Show();
		PayTopList_AvailNumText:Show();
	elseif idx == 2 then
		PayTopList_Tab1:SetCheck(0)
		PayTopList_Tab2:SetCheck(1)
		PayTopList_Tab3:SetCheck(0)			
		PayTopList_Intro:Hide()
		PayTopList_ListFrame:Hide()
		PayTopList_ButtonFrame:Hide()
		PayTopList_Intro2:Show()
		PayTopList_ListFrame2:Show()
		PayTopList_ButtonFrame2:Show()
		PayTopList_Laypage:Show();
		PayTopList_GetNumText:Hide();
		PayTopList_AvailNumText:Hide();
		
		PayTopList_TServer_Init();
	end
	g_page_cur = idx
end

--根据原服排名得到榜单类型
function PayTopList_GetTWorldRandTypeStr( nRank )
	if nRank == nil then
		--return "1."..nRank
		return ""
	end
	if nRank >=0 and nRank < 3 then
		return "#{MDJH_221102_14}"
	elseif nRank >=3 and nRank < 6 then
		return "#{MDJH_221102_15}"
	elseif nRank >=6 and nRank < 10 then
		return "#{MDJH_221102_16}"
	end
	
	return ""
end 

--根据榜单名次得到奖励数量
function PayTopList_GetTWorldAwardCount( nRankType, nRank )
	local nIndex = nRankType * 3 + math.floor(nRank / 15) + 1;
	
	if g_tserver_awards.itemcount[nIndex] == nil then
		return 0;
	end
	
	return g_tserver_awards.itemcount[nIndex];
	
end

--刷新全服榜指定榜、指定页签的数据
function PayTopList_UpdateTWorldData( nRankType, nPage )
	PayTopList_TopList2:RemoveAllItem()
	
	if g_PayTopList_TServer_RankInfo[nRankType] == nil then
		return
	end
	local nPageCount = math.ceil(g_PayTopList_TServer_RankInfo[nRankType].size / 10);
	if nPage < 0 or nPage >= nPageCount then
		nPage = 0
	end 
	
	for i=0,9 do
		local index,name,menpai,level,cost,guid64,serverid, rank = DataPool:Lua_GetYBTopListInfo_tserver( nRankType, nPage * 10 + i )
		local menpaistr = PayTopList_GetMenpai(menpai)
		if(index ~= nil and index >= 0) then
			if name ~= "" then
				PayTopList_TopList2:AddNewItem("    #cfff263"..tostring(nPage*10+i+1),0,i)
				PayTopList_TopList2:AddNewItem("#cfff263"..name.."@"..DataPool:GetServerName(serverid),1,i)
				PayTopList_TopList2:AddNewItem("#cfff263"..menpaistr,2,i)
				PayTopList_TopList2:AddNewItem("#cfff263"..level,3,i)
				PayTopList_TopList2:AddNewItem("#cfff263"..cost,4,i)
				
				PayTopList_TopList2:AddNewItem("#cfff263"..PayTopList_GetTWorldRandTypeStr(rank),5,i)
				
				PayTopList_TopList2:AddNewItem("#cfff263"..ScriptGlobal_Format("#{MDJH_141014_28}", PayTopList_GetTWorldAwardCount(nRankType, nPage * 10 + i) ), 6, i)
			else
				PayTopList_TopList2:AddNewItem("    #cfff263"..tostring(nPage*10+i+1),0,i)
				PayTopList_TopList2:AddNewItem("#{MDJH_130507_42}",1,i)
				PayTopList_TopList2:AddNewItem("",2,i)
				PayTopList_TopList2:AddNewItem("",3,i)
				PayTopList_TopList2:AddNewItem("",4,i)
				PayTopList_TopList2:AddNewItem("",5,i)
				PayTopList_TopList2:AddNewItem("#cfff263"..ScriptGlobal_Format("#{MDJH_141014_28}",PayTopList_GetTWorldAwardCount( nRankType, nPage * 10 + i ) ),6,i)
			end

		end
	end
	
	g_PayTopList_TServer_CurRankType = nRankType;
	g_PayTopList_TServer_RankInfo[g_PayTopList_TServer_CurRankType].curPage = nPage;
	PayTopList_CurrentlyPage:SetText( ScriptGlobal_Format("#{MDJH_221102_05}", nPage + 1, nPageCount) ); 
	
	--上一页、下一页状态
	if g_PayTopList_TServer_RankInfo[g_PayTopList_TServer_CurRankType].curPage <= 0 then
		PayTopList_UpPageBtn:Disable();
	else
		PayTopList_UpPageBtn:Enable();
	end
	if g_PayTopList_TServer_RankInfo[g_PayTopList_TServer_CurRankType].curPage+1 >= math.ceil(g_PayTopList_TServer_RankInfo[g_PayTopList_TServer_CurRankType].size / 10) then
		PayTopList_DownPageBtn:Disable();
	else
		PayTopList_DownPageBtn:Enable();
	end
	
end

--天、地、人三榜事件
function PayTopList_Laypage1SetCheckBox( index )
	if index < 1 or index > 3 then
		return
	end
	
	if g_PayTopList_TServer_RankInfo[index-1] == nil then
		return
	end
	
	if g_PayTopList_TServer_RankInfo[index-1].curPage < 0 then
		return
	end
	
	if g_PayTopList_TServer_RankInfo[index-1].curPage >= math.ceil(g_PayTopList_TServer_RankInfo[index-1].size / 10) then
		return
	end
	
	PayTopList_UpdateTWorldData( index-1, g_PayTopList_TServer_RankInfo[index-1].curPage );
	
	for i=1, 3 do
		g_PayTopList_TWorld_TabCtrl[i]:SetCheck(0);
	end	
	g_PayTopList_TWorld_TabCtrl[index]:SetCheck(1);
	
end

--天、地、人三榜上一页
function PayTopList_UpPage()
	if g_PayTopList_TServer_RankInfo[g_PayTopList_TServer_CurRankType] == nil then
		return
	end
	
	if g_PayTopList_TServer_RankInfo[g_PayTopList_TServer_CurRankType].curPage - 1 < 0 then
		return
	end
	
	PayTopList_UpdateTWorldData( g_PayTopList_TServer_CurRankType, g_PayTopList_TServer_RankInfo[g_PayTopList_TServer_CurRankType].curPage - 1);
end

--天、地、人三榜下一页
function PayTopList_DownPage()
	if g_PayTopList_TServer_RankInfo[g_PayTopList_TServer_CurRankType] == nil then
		return
	end
	
	if g_PayTopList_TServer_RankInfo[g_PayTopList_TServer_CurRankType].curPage + 1 >= math.ceil(g_PayTopList_TServer_RankInfo[g_PayTopList_TServer_CurRankType].size / 10) then
		return
	end
	
	PayTopList_UpdateTWorldData( g_PayTopList_TServer_CurRankType, g_PayTopList_TServer_RankInfo[g_PayTopList_TServer_CurRankType].curPage + 1);
end

function PayTopList_DuiHuan()
	PushEvent("FATIE_SECCONFIRM","PayTopList_DuiHuan_Open")
end

function PayTopList_Intro_Help_Clicked()
	PushEvent("QUEST_HELP_MSG","#{MDJH_260625_41}")
end