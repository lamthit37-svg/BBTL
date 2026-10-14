local g_strWndName = "KVKJianghumingrentang"
local g_Statue_Type = -1 --标识雕像类型
local g_clientNpcId = -1
--借鉴组队平台里面的
local g_Timers = {0, 0, 0, 0, 0}; -- 冷却时间分组
local g_strWaitClickTipText = "#{ZYPT_081127_2}"
local TIMER_COMMONBTN = 1;				-- 一般按钮
local MIN_COMMON_TIME = 0.5; --点功能按钮的间隔 （秒）
local MIN_SHUAXIN_TIME = 1; --点功能按钮的间隔 （秒） -- 到服务器端拉数据的按钮时间长一些
-- 界面的默认位置
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_MenPaiTitleList =
{
	[1]  ={Title="#{XY_0110_42}"},
	[2]  ={Title="#{XY_0110_43}"},
	[3]  ={Title="#{XY_0110_44}"},
	[4]  ={Title="#{XY_0110_45}"},
	[5]  ={Title="#{XY_0110_46}"},
	[6]  ={Title="#{XY_0110_47}"},
	[7]  ={Title="#{XY_0110_48}"},
	[8]  ={Title="#{XY_0110_49}"},
	[9]  ={Title="#{XY_0110_50}"},
	[10] ={Title="#{XY_0110_51}"}
}
local g_MenPaiNameList =
{
	[0]  ={Name="#{XQ_MP_1}"},
	[1]  ={Name="#{XQ_MP_2}"},
	[2]  ={Name="#{XQ_MP_3}"},
	[3]  ={Name="#{XQ_MP_4}"},
	[4]  ={Name="#{XQ_MP_5}"},
	[5]  ={Name="#{XQ_MP_6}"},
	[6]  ={Name="#{XQ_MP_7}"},
	[7]  ={Name="#{XQ_MP_8}"},
	[8]  ={Name="#{XQ_MP_9}"},
	[10] ={Name="#{XQ_MP_10}"},
	[11] ={Name="#{XMPTM_130123_05}"},
	[12] ={Name="#{XMPGG_160524_02}"},
	[13] ={Name="#{XQ_MP_15}"}, --桃花岛
	[14] ={Name="#{XMPHM_210604_01}"},   
	[15] ={Name="#{TWDYR_210709_09}"},  --MENPAI15
}

function KVKJianghumingrentang_PreLoad()
	this:RegisterEvent("OPEN_WINDOW");
	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function KVKJianghumingrentang_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= KVKJianghumingrentang_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= KVKJianghumingrentang_Frame:GetProperty("UnifiedYPosition");
end
function KVKJianghumingrentang_OnOpen(strOpt)

end
function KVKJianghumingrentang_OnEvent(event)

	if(event == "OPEN_WINDOW") then
		--KVKJianghumingrentang_OnOpen( arg0 );
	elseif( event == "ADJEST_UI_POS" ) then
		KVKJianghumingrentang_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		KVKJianghumingrentang_ResetPos()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "KVKJianghumingrentang") then
			this:Hide();
		end
	elseif(event == "UI_COMMAND") then
	  if tonumber(arg0) == 20151225 then
		g_Statue_Type = Get_XParam_INT(0)
		g_clientNpcId = Get_XParam_INT(1);
		g_clientNpcId = Target:GetServerId2ClientId(g_clientNpcId);

 	    KVKJianghumingrentang_DragTitle:SetText("#Y"..ScriptGlobal_Format("#{TWDYR_151223_14}" , g_MenPaiNameList[g_Statue_Type].Name ) )--门派名人堂
	  	KVKJianghumingrentang_UpdateUserInfoList(g_Statue_Type)
		this:CareObject(g_clientNpcId, 1, "KVKJianghumingrentang");

		this:Show();
	  end
	elseif(event == "SCENE_TRANSED")	 then
		this:Hide();
	end

end

function KVKJianghumingrentang_UpdateUserInfoList(MenPai)

	KVKJianghumingrentang_List:RemoveAllItem()
	KVKJianghumingrentang_ClearPlayerMsg()
	--都显示10个名次
	local iRow = 0
	for i=1, 10 do

		local nGuid            = GetKvkShowOffGuidByID(i-1)
		local nName            = GetKvkShowOffNameByID(i-1)
		local nMenPai          = GetKvkShowOffMenpaiByID(i-1)
		local nLevel           = GetKvkShowOffLevelByID(i-1)
		local nSex             = GetKvkShowOffSexByID(i-1)
		local nGuildName       = GetKvkShowOffGuildNameByID(i-1)
		--local nGuildLeagueName = GetKvkShowOffGuildLeagueNameByID(i-1)
		local nTitle           = GetKvkShowOffTitleByID(i-1)
		local nMood            = GetKvkShowOffMoodByID(i-1)
		local nPortrait        = GetKvkShowOffImageNameByID(i-1)
		local nPortrait        = GetKvkShowOffImageNameByID(i-1)
		local nServerName      = GetKvkShowOffServerName(i-1)
		local nZMName      		 = GetKvkShowOffZMName(i-1)
		local nScoreHH	       = GetKvkShowOffScoreHH(i-1) 
		 
		if nGuid == nil or nName == "" then --如果没有玩家直接跳出循环
			break
		end
		
		if (iRow == 0) then
		
			
			KVKJianghumingrentang_List:AddNewItem("#Y"..nName.."@"..nServerName,0,iRow)--第一的名字设置成黄色
			KVKJianghumingrentang_List:AddNewItem("#Y"..nMenPai,1,iRow)
			KVKJianghumingrentang_List:AddNewItem("#Y"..nLevel,2,iRow)
			if( tonumber( nSex ) == 0 ) then
				KVKJianghumingrentang_List:AddNewItem( "#Y#{XY_0110_63}", 3, iRow );--女
			else
				KVKJianghumingrentang_List:AddNewItem( "#Y#{XY_0110_62}", 3, iRow );--男
			end
			

			 
			KVKJianghumingrentang_List:AddNewItem("#Y"..nScoreHH,4,iRow)
			local nRemark = g_MenPaiTitleList[i].Title
			KVKJianghumingrentang_List:AddNewItem("#Y"..nRemark,5,iRow)
			
		else
			KVKJianghumingrentang_List:AddNewItem(nName.."@"..nServerName,0,iRow)
			KVKJianghumingrentang_List:AddNewItem(nMenPai,1,iRow)
			KVKJianghumingrentang_List:AddNewItem(nLevel,2,iRow)
			if( tonumber( nSex ) == 0 ) then
				KVKJianghumingrentang_List:AddNewItem( "#{XY_0110_63}", 3, iRow );--女
			else
				KVKJianghumingrentang_List:AddNewItem( "#{XY_0110_62}", 3, iRow );--男
			end
			
			if nZMName == "" then
				KVKJianghumingrentang_List:AddNewItem("",4,iRow)
			else
				KVKJianghumingrentang_List:AddNewItem(nZMName,4,iRow)
			end
			
			KVKJianghumingrentang_List:AddNewItem(nScoreHH,4,iRow)
			
			local nRemark = g_MenPaiTitleList[i].Title
			KVKJianghumingrentang_List:AddNewItem(nRemark,5,iRow)
			 
		end
		if iRow == 0 then
			KVKJianghumingrentang_ShowDefaultPlayerMsg(nGuid,nName,nLevel,nMenPai,nPortrait,nGuildName,nMood,nTitle,nZMName)
		end
		iRow = iRow + 1
	end

end

--关闭
function OnKVKJianghumingrentang_CloseClicked()
   this:Hide();
end

function KVKJianghumingrentang_BtnCheck_OnClicked(iType)

end

function OnKVKJianghumingrentang_RefreshClicked()
	if not KVKJianghumingrentang_PassTime(TIMER_COMMONBTN, MIN_SHUAXIN_TIME) then
		PushDebugMessage(g_strWaitClickTipText);
		return
	end
	RefreshKvkShowOffMsg(g_Statue_Type)
	KVKJianghumingrentang_UpdateUserInfoList(g_Statue_Type)
end

function KVKJianghumingrentang_YaoQingTeam()
		local nIndex = KVKJianghumingrentang_List:GetSelectItem()
		if nIndex == -1 then
			PushDebugMessage("#{XY_0110_65}")
			return
		end
		KvkShowOffRequestTeam(nIndex)
end

function KVKJianghumingrentang_ShengQingTeam()
		local nIndex = KVKJianghumingrentang_List:GetSelectItem()
		if nIndex == -1 then
			PushDebugMessage("#{XY_0110_65}")
			return
		end
		KvkShowOffApplyTeam(nIndex)
end

function KVKJianghumingrentang_AddFriend()
		local nIndex = KVKJianghumingrentang_List:GetSelectItem()
		if nIndex == -1 then
			PushDebugMessage("#{XY_0110_65}")
			return
		end
		local nName;
		nName = GetKvkShowOffNameByID(nIndex)
		
		if(nName == nil or nName == "") then
			return
		end
		local nzoneworldid = GetKvkShowOffZoneWorldID(nIndex)
		if(nzoneworldid == nil or nzoneworldid == -1) then
			return
		end 
		DataPool:AddFriendAndGrouping(nName, nzoneworldid); 
end

function KVKJianghumingrentang_SetPrivateName()
	local nIndex = KVKJianghumingrentang_List:GetSelectItem()
	if nIndex == -1 then
		PushDebugMessage("#{XY_0110_65}")
		return
	end

	local nName;
	nName = GetKvkShowOffNameByID(nIndex)
	local nzoneworldid = GetKvkShowOffZoneWorldID(nIndex)
	if(nzoneworldid == nil or nzoneworldid == -1) then
			return
	end
	if(nil ~= nName and "" ~= nName) then
		Talk:ContexMenuTalk(nName,nzoneworldid);
	end
end

function KVKJianghumingrentang_ClearPlayerMsg()
		KVKJianghumingrentang_ID:SetText("#{TWDYR_151223_43}")
		KVKJianghumingrentang_Name:SetText("#{TWDYR_151223_44}")
		KVKJianghumingrentang_Level:SetText("#{TWDYR_151223_45}")
		KVKJianghumingrentang_MenPai:SetText("#{TWDYR_151223_46}")
		KVKJianghumingrentang_PlayerHead:SetProperty("Image", "")
		KVKJianghumingrentang_Confraternity:SetText("#{TWDYR_151223_47}") 
		--KVKJianghumingrentang_GuildLeague:SetText("#{TM_20080311_30}")
		KVKJianghumingrentang_Explain:SetText("#{TWDYR_151223_48}")--字典里面没有冒号，我加上
		KVKJianghumingrentang_Agname:SetText("#{TWDYR_151223_49}")
end

function KVKJianghumingrentang_ShowDefaultPlayerMsg(nGuid,nName,nLevel,nMenPai,nPortrait,nGuildName,nMood,nTitle,nZMName)
		local GuidText = ConvertGuidToShow(nGuid)
		KVKJianghumingrentang_ID:SetText("#{TWDYR_151223_43}" .. GuidText)
		KVKJianghumingrentang_Name:SetText("#{TWDYR_151223_44}" .. "#cfff263"..nName)
		KVKJianghumingrentang_Level:SetText("#{TWDYR_151223_45}" .. "#cfff263"..nLevel)
		KVKJianghumingrentang_MenPai:SetText("#{TWDYR_151223_46}" .."#cfff263"..nMenPai)
		KVKJianghumingrentang_PlayerHead:SetProperty("Image", nPortrait)
		if nGuildName ==nil or nGuildName == ""  then
			-- nGuildName="#{INTERFACE_XML_720}"
			nGuildName=""
		end
		KVKJianghumingrentang_Confraternity:SetText("#{TWDYR_151223_47}" .. nGuildName)

		if nMood==nil or nMood =="" then
			nMood ="#{XY_0110_64}"
		end
		KVKJianghumingrentang_Explain:SetText("#{TWDYR_151223_48}" .. nMood)
		if nTitle ==nil or nTitle == ""  then
			-- nTitle="#{INTERFACE_XML_720}"
			nTitle=""
		end
		KVKJianghumingrentang_Agname:SetText("#{TWDYR_151223_49}" .. nTitle)
end

function KVKJianghumingrentang_List_OnSelectionChanged()

		local nIndex = KVKJianghumingrentang_List:GetSelectItem()

		if nIndex == -1 then
			return
		end

		KVKJianghumingrentang_ClearPlayerMsg()--先把原来的给清掉

		local nGuid            = GetKvkShowOffGuidByID(nIndex)
		local nName            = GetKvkShowOffNameByID(nIndex)
		local nLevel           = GetKvkShowOffLevelByID(nIndex)
		local nMenPai          = GetKvkShowOffMenpaiByID(nIndex)
		local nPortrait        = GetKvkShowOffImageNameByID(nIndex)
		local nGuildName       = GetKvkShowOffGuildNameByID(nIndex)
		--local nGuildLeagueName = GetKvkShowOffGuildLeagueNameByID(nIndex)
		local nMood            = GetKvkShowOffMoodByID(nIndex)
		local nTitle           = GetKvkShowOffTitleByID(nIndex)
		local nZMName					 = GetKvkShowOffZMName(nIndex)

		local nGuidText	= ConvertGuidToShow(nGuid)
		KVKJianghumingrentang_ID:SetText("#{TWDYR_151223_43}" .. nGuidText)
		KVKJianghumingrentang_Name:SetText("#{TWDYR_151223_44}" .. nName)
		KVKJianghumingrentang_Level:SetText("#{TWDYR_151223_45}" .. nLevel)
		KVKJianghumingrentang_MenPai:SetText("#{TWDYR_151223_46}" .. nMenPai)
		KVKJianghumingrentang_PlayerHead:SetProperty("Image", nPortrait)
		if nGuildName ==nil or nGuildName == ""  then
			-- nGuildName="#{INTERFACE_XML_720}"--无
			nGuildName=""
		end
		KVKJianghumingrentang_Confraternity:SetText("#{TWDYR_151223_47}" .. nGuildName)

		if nMood==nil or nMood =="" then
			nMood ="#{XY_0110_64}"
		end
		KVKJianghumingrentang_Explain:SetText("#{TWDYR_151223_48}" .. nMood)
		if nTitle ==nil or nTitle == ""  then
			--nTitle="#{INTERFACE_XML_720}"
			nTitle=""
		end

		KVKJianghumingrentang_Agname:SetText("#{TWDYR_151223_49}" .. nTitle)
end

function KVKJianghumingrentang_PassTime(iIdx, iSeconds)
   local iCur = FindFriendDataPool:GetTickCount();--不单写接口了，用原来的即可
   if ( iCur - g_Timers[iIdx] < iSeconds * 1000) then
      return false;
   else
      g_Timers[iIdx] = iCur;
   	  return true;
   end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function KVKJianghumingrentang_ResetPos()
	KVKJianghumingrentang_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	KVKJianghumingrentang_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
