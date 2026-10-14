local g_strWndName = "Jianghumingrentang"
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
	[12] ={Name="#{XMPGG_160524_02}"}, --鬼谷  
	[13] ={Name="#{XQ_MP_15}"}, --桃花岛  
	[14] ={Name="#{XMPHM_210604_01}"},   
	[15] ={Name="#{GMGameInterface_Script_DataPool_Info_ERenGu}"},   
}

function Jianghumingrentang_PreLoad()
	this:RegisterEvent("OPEN_WINDOW");
	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Jianghumingrentang_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Jianghumingrentang_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Jianghumingrentang_Frame:GetProperty("UnifiedYPosition");
end
function Jianghumingrentang_OnOpen(strOpt)

end
function Jianghumingrentang_OnEvent(event)

	if(event == "OPEN_WINDOW") then
		--Jianghumingrentang_OnOpen( arg0 );
	elseif( event == "ADJEST_UI_POS" ) then
		Jianghumingrentang_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Jianghumingrentang_ResetPos()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "Jianghumingrentang") then
			this:Hide();
		end
	elseif(event == "UI_COMMAND") then
	  if tonumber(arg0) == 20110101 then
		g_Statue_Type = Get_XParam_INT(0)
		g_clientNpcId = Get_XParam_INT(1);
		g_clientNpcId = Target:GetServerId2ClientId(g_clientNpcId);

 	    Jianghumingrentang_PageHeader:SetText("#Y"..g_MenPaiNameList[g_Statue_Type].Name.."#{XY_0110_99}")--门派名人堂
	  	Jianghumingrentang_UpdateUserInfoList(g_Statue_Type)
		this:CareObject(g_clientNpcId, 1, "Jianghumingrentang");

		this:Show();
	  end
	elseif(event == "HIDE_ON_SCENE_TRANSED")	 then
		this:Hide();
	end

end

function Jianghumingrentang_UpdateUserInfoList(MenPai)

	Jianghumingrentang_List:RemoveAllItem()
	Jianghumingrentang_ClearPlayerMsg()
	--都显示10个名次
	local iRow = 0
	for i=1, 10 do

		local nGuid            = GetShowOffGuidByID(i-1)
		local nName            = GetShowOffNameByID(i-1)
		local nMenPai          = GetShowOffMenpaiByID(i-1)
		local nLevel           = GetShowOffLevelByID(i-1)
		local nSex             = GetShowOffSexByID(i-1)
		local nGuildName       = GetShowOffGuildNameByID(i-1)
		--local nGuildLeagueName = GetShowOffGuildLeagueNameByID(i-1)
		local nTitle           = GetShowOffTitleByID(i-1)
		local nMood            = GetShowOffMoodByID(i-1)
		local nPortrait        = GetShowOffImageNameByID(i-1)

		if nGuid == nil or nName == "" then --如果没有玩家直接跳出循环
			break
		end

		if (iRow == 0) then
			Jianghumingrentang_List:AddNewItem("#Y"..nName,0,iRow)--第一的名字设置成黄色
			Jianghumingrentang_List:AddNewItem("#Y"..nMenPai,1,iRow)
			Jianghumingrentang_List:AddNewItem("#Y"..nLevel,2,iRow)
			if( tonumber( nSex ) == 0 ) then
				Jianghumingrentang_List:AddNewItem( "#Y#{XY_0110_63}", 3, iRow );--女
			else
				Jianghumingrentang_List:AddNewItem( "#Y#{XY_0110_62}", 3, iRow );--男
			end
			
			if nGuildName == "" then
				Jianghumingrentang_List:AddNewItem("#Y",4,iRow)
			else
				Jianghumingrentang_List:AddNewItem("#Y"..nGuildName,4,iRow)
			end
	
			local nRemark = g_MenPaiTitleList[i].Title
			Jianghumingrentang_List:AddNewItem("#Y"..nRemark,5,iRow)
		else
			Jianghumingrentang_List:AddNewItem(nName,0,iRow)
			Jianghumingrentang_List:AddNewItem(nMenPai,1,iRow)
			Jianghumingrentang_List:AddNewItem(nLevel,2,iRow)
			if( tonumber( nSex ) == 0 ) then
				Jianghumingrentang_List:AddNewItem( "#{XY_0110_63}", 3, iRow );--女
			else
				Jianghumingrentang_List:AddNewItem( "#{XY_0110_62}", 3, iRow );--男
			end
			
			if nGuildName == "" then
				Jianghumingrentang_List:AddNewItem("",4,iRow)
			else
				Jianghumingrentang_List:AddNewItem(nGuildName,4,iRow)
			end
	
			local nRemark = g_MenPaiTitleList[i].Title
			Jianghumingrentang_List:AddNewItem(nRemark,5,iRow)
		end
		if iRow == 0 then
			Jianghumingrentang_ShowDefaultPlayerMsg(nGuid,nName,nLevel,nMenPai,nPortrait,nGuildName,nMood,nTitle)
		end
		iRow = iRow + 1
	end

end

--关闭
function OnJianghumingrentang_CloseClicked()
   this:Hide();
end

function Jianghumingrentang_BtnCheck_OnClicked(iType)

end

function OnJianghumingrentang_RefreshClicked()
	if not Jianghumingrentang_PassTime(TIMER_COMMONBTN, MIN_SHUAXIN_TIME) then
		PushDebugMessage(g_strWaitClickTipText);
		return
	end
	RefreshShowOffMsg(g_Statue_Type)
	Jianghumingrentang_UpdateUserInfoList(g_Statue_Type)
end

function Jianghumingrentang_YaoQingTeam()
		local nIndex = Jianghumingrentang_List:GetSelectItem()
		if nIndex == -1 then
			PushDebugMessage("#{XY_0110_65}")
			return
		end
		ShowOffRequestTeam(nIndex)
end

function Jianghumingrentang_ShengQingTeam()
		local nIndex = Jianghumingrentang_List:GetSelectItem()
		if nIndex == -1 then
			PushDebugMessage("#{XY_0110_65}")
			return
		end
		ShowOffApplyTeam(nIndex)
end

function Jianghumingrentang_AddFriend()
		local nIndex = Jianghumingrentang_List:GetSelectItem()
		if nIndex == -1 then
			PushDebugMessage("#{XY_0110_65}")
			return
		end
		local nName;
		nName = GetShowOffNameByID(nIndex)

		if(nName == nil or nName == "") then
			return
		end
		DataPool:AddFriendAndGrouping(nName);
end

function Jianghumingrentang_SetPrivateName()
	local nIndex = Jianghumingrentang_List:GetSelectItem()
	if nIndex == -1 then
		PushDebugMessage("#{XY_0110_65}")
		return
	end

	local nName;
	nName = GetShowOffNameByID(nIndex)
	if(nil ~= nName and "" ~= nName) then
		Talk:ContexMenuTalk(nName);
	end
end

function Jianghumingrentang_ClearPlayerMsg()
		Jianghumingrentang_ID:SetText("ID:")
		Jianghumingrentang_Name:SetText("#{INTERFACE_XML_773}")
		Jianghumingrentang_Level:SetText("#{INTERFACE_XML_344}")
		Jianghumingrentang_MenPai:SetText("#{INTERFACE_XML_449}")
		Jianghumingrentang_PlayerHead:SetProperty("Image", "")
		Jianghumingrentang_Confraternity:SetText("#{INTERFACE_XML_127}")
		--Jianghumingrentang_GuildLeague:SetText("#{TM_20080311_30}")
		Jianghumingrentang_Explain:SetText("#{SNS_XML_100805_12}:")--字典里面没有冒号，我加上
		Jianghumingrentang_Agname:SetText("#{INTERFACE_XML_174}")
end

function Jianghumingrentang_ShowDefaultPlayerMsg(nGuid,nName,nLevel,nMenPai,nPortrait,nGuildName,nMood,nTitle)
		local GuidText = ConvertGuidToShow(nGuid)
		Jianghumingrentang_ID:SetText("ID:" .. GuidText)
		Jianghumingrentang_Name:SetText("#{INTERFACE_XML_773}" .. nName)
		Jianghumingrentang_Level:SetText("#{INTERFACE_XML_344}" .. nLevel)
		Jianghumingrentang_MenPai:SetText("#{INTERFACE_XML_449}" .. nMenPai)
		Jianghumingrentang_PlayerHead:SetProperty("Image", nPortrait)
		if nGuildName ==nil or nGuildName == ""  then
			-- nGuildName="#{INTERFACE_XML_720}"
			nGuildName=""
		end
		Jianghumingrentang_Confraternity:SetText("#{INTERFACE_XML_127}" .. nGuildName)

		if nMood==nil or nMood =="" then
			nMood ="#{XY_0110_64}"
		end
		Jianghumingrentang_Explain:SetText("#{SNS_XML_100805_12}:" .. nMood)
		if nTitle ==nil or nTitle == ""  then
			-- nTitle="#{INTERFACE_XML_720}"
			nTitle=""
		end
		Jianghumingrentang_Agname:SetText("#{INTERFACE_XML_174}" .. nTitle)
end

function Jianghumingrentang_List_OnSelectionChanged()

		local nIndex = Jianghumingrentang_List:GetSelectItem()

		if nIndex == -1 then
			return
		end

		Jianghumingrentang_ClearPlayerMsg()--先把原来的给清掉

		local nGuid            = GetShowOffGuidByID(nIndex)
		local nName            = GetShowOffNameByID(nIndex)
		local nLevel           = GetShowOffLevelByID(nIndex)
		local nMenPai          = GetShowOffMenpaiByID(nIndex)
		local nPortrait        = GetShowOffImageNameByID(nIndex)
		local nGuildName       = GetShowOffGuildNameByID(nIndex)
		--local nGuildLeagueName = GetShowOffGuildLeagueNameByID(nIndex)
		local nMood            = GetShowOffMoodByID(nIndex)
		local nTitle           = GetShowOffTitleByID(nIndex)

		local nGuidText	= ConvertGuidToShow(nGuid)
		Jianghumingrentang_ID:SetText("ID:" .. nGuidText)
		Jianghumingrentang_Name:SetText("#{INTERFACE_XML_773}" .. nName)
		Jianghumingrentang_Level:SetText("#{INTERFACE_XML_344}" .. nLevel)
		Jianghumingrentang_MenPai:SetText("#{INTERFACE_XML_449}" .. nMenPai)
		Jianghumingrentang_PlayerHead:SetProperty("Image", nPortrait)
		if nGuildName ==nil or nGuildName == ""  then
			-- nGuildName="#{INTERFACE_XML_720}"--无
			nGuildName=""
		end
		Jianghumingrentang_Confraternity:SetText("#{INTERFACE_XML_127}" .. nGuildName)

		if nMood==nil or nMood =="" then
			nMood ="#{XY_0110_64}"
		end
		Jianghumingrentang_Explain:SetText("#{SNS_XML_100805_12}:" .. nMood)
		if nTitle ==nil or nTitle == ""  then
			--nTitle="#{INTERFACE_XML_720}"
			nTitle=""
		end

		Jianghumingrentang_Agname:SetText("#{INTERFACE_XML_174}" .. nTitle)
end

function Jianghumingrentang_PassTime(iIdx, iSeconds)
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
function Jianghumingrentang_ResetPos()
	Jianghumingrentang_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Jianghumingrentang_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
