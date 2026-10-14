-- 战队信息查看
-- 界面的默认位置
local g_Frame_UnifiedXpostition;
local g_Frame_UnifiedYpostition;
local g_clientNpcId = -1
local g_isGuessOpen = 0

local g_MenPaiNameList =
{
	[0]  ="#{XQ_MP_1}",
	[1]  ="#{XQ_MP_2}",
	[2]  ="#{XQ_MP_3}",
	[3]  ="#{XQ_MP_4}",
	[4]  ="#{XQ_MP_5}",
	[5]  ="#{XQ_MP_6}",
	[6]  ="#{XQ_MP_7}",
	[7]  ="#{XQ_MP_8}",
	[8]  ="#{XQ_MP_9}",
	[9]  ="#{ZBS16_160511_55}",
	[10] ="#{XQ_MP_10}",
	[11] ="#{XMPTM_130123_05}",
	[12] ="#{XMPGG_160524_02}",
	[13] ="#{XQ_MP_15}", --桃花岛
	[14] ="#{XMPHM_210604_01}",
	[15] ="#{GMGameInterface_Script_DataPool_Info_ERenGu}",--menpai15 mptodo
}
--g_MemberList和g_WTeamMatchInfoList中的数据，每次INIT需要清空
--二者的数据非只读；也可以读，也可以写

local g_MemberList =  --post:1队员 2队长
{
	[1]  ={Name="",MP=9,Level=0,post=0,Guid="",dw3=9,eqhh=0},
	[2]  ={Name="",MP=9,Level=0,post=0,Guid="",dw3=9,eqhh=0},
	[3]  ={Name="",MP=9,Level=0,post=0,Guid="",dw3=9,eqhh=0},
	[4]  ={Name="",MP=9,Level=0,post=0,Guid="",dw3=9,eqhh=0},
	[5]  ={Name="",MP=9,Level=0,post=0,Guid="",dw3=9,eqhh=0},
	[6]  ={Name="",MP=9,Level=0,post=0,Guid="",dw3=9,eqhh=0},
}

local g_TeamInfo_Pictures ={}
local g_TeamInfo_Name = {}
local g_TeamInfo_Menpai = {}
local g_TeamInfo_Level = {}
local g_TeamInfo_Dw3 = {}
local g_TeamInfo_DragItems = {}
local g_TeamInfo_DragTargets = {}

local g_MaxWTeamMemCount = 6
local g_AtcalWTeamMemCount = 0
local g_SelectIndex = 0

function BS_TeamInfo_PreLoad()

	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND")
	--显示战队信息
	this:RegisterEvent("TXBW_WTEAM_INFO_SHOW")
	this:RegisterEvent("TXBW_WTEAM_INFO_SHOW_FORGUESS")
	--战队相关的UI都要关闭
	this:RegisterEvent("TXBW_ALL_UI_CLOSED")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_post",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BS_TeamInfo_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXpostition	= BS_TeamInfo_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYpostition	= BS_TeamInfo_Frame:GetProperty("UnifiedYPosition");

    g_TeamInfo_Pictures[1] = BS_TeamInfo_List1_Pic;
	g_TeamInfo_Pictures[2] = BS_TeamInfo_List2_Pic;
	g_TeamInfo_Pictures[3] = BS_TeamInfo_List3_Pic;
	g_TeamInfo_Pictures[4] = BS_TeamInfo_List4_Pic;
	g_TeamInfo_Pictures[5] = BS_TeamInfo_List5_Pic;
	g_TeamInfo_Pictures[6] = BS_TeamInfo_List6_Pic;

	--玩家名字
	g_TeamInfo_Name = {BS_TeamInfo_List1_1, BS_TeamInfo_List2_1, BS_TeamInfo_List3_1, BS_TeamInfo_List4_1,
									BS_TeamInfo_List5_1, BS_TeamInfo_List6_1,}

	--门派
	g_TeamInfo_Menpai = {BS_TeamInfo_List1_2, BS_TeamInfo_List2_2, BS_TeamInfo_List3_2, BS_TeamInfo_List4_2,
										BS_TeamInfo_List5_2, BS_TeamInfo_List6_2,}

	--等级
	g_TeamInfo_Level = {BS_TeamInfo_List1_3, BS_TeamInfo_List2_3, BS_TeamInfo_List3_3, BS_TeamInfo_List4_3,
										BS_TeamInfo_List5_3, BS_TeamInfo_List6_3, }

	--段位
	g_TeamInfo_Dw3 = {BS_TeamInfo_List1_4, BS_TeamInfo_List2_4, BS_TeamInfo_List3_4, BS_TeamInfo_List4_4,
										BS_TeamInfo_List5_4, BS_TeamInfo_List6_4, }

	g_TeamInfo_DragItems = {BS_TeamInfo_List1_Btn, BS_TeamInfo_List2_Btn, BS_TeamInfo_List3_Btn, BS_TeamInfo_List4_Btn,
										BS_TeamInfo_List5_Btn, BS_TeamInfo_List6_Btn,}

	g_TeamInfo_DragTargets = {BS_TeamInfo_List1_Bk, BS_TeamInfo_List2_Bk, BS_TeamInfo_List3_Bk, BS_TeamInfo_List4_Bk,
										BS_TeamInfo_List5_Bk, BS_TeamInfo_List6_Bk,}
end

--初始化控件数据
function BS_TeamInfo_InitUIData()

	BS_TeamInfo_part1:SetText("");
	local text = ScriptGlobal_Format("#{BWJH_181102_159}", 0 );
	BS_TeamInfo_part2:SetText(text);

	for i=1,g_MaxWTeamMemCount do
		g_TeamInfo_Pictures[i]:Hide()
		g_TeamInfo_Name[i]:SetText("")
		g_TeamInfo_Menpai[i]:SetText("")
		g_TeamInfo_Level[i]:SetText("")
		g_TeamInfo_Dw3[i]:SetText("")
		g_TeamInfo_DragItems[i]:SetProperty("DraggingEnabled", "False")
		g_TeamInfo_DragTargets[i]:SetProperty("HoverState", "False")
	end

	for i=1, g_MaxWTeamMemCount do
		g_MemberList[i].Name = ""
		g_MemberList[i].MP=9
		g_MemberList[i].Level=0
		g_MemberList[i].post=0
		g_MemberList[i].Guid=""
		g_MemberList[i].dw3=1
		g_MemberList[i].eqhh=0
	end

end
--!!!reloadscript =BS_TeamInfo
function BS_TeamInfo_InitMemberListData()
	--战队名字
	local WTeamName = BWDH2018:GetDetailWTeamInfo("Name")
	if WTeamName ==nil then
		return 0
	end
	local nZoneWorldId = BWDH2018:GetDetailWTeamInfo("ZoneWorldId")
	if nZoneWorldId == nil then
		return 0
	end
	local nServerName = DataPool:GetServerName(nZoneWorldId)
	if nServerName == nil then
		nServerName = ""
	end

	local szWTeamNameTips = ScriptGlobal_Format("#{BWJH_181102_158}", WTeamName, nServerName );
	BS_TeamInfo_part1:SetText( szWTeamNameTips )
	--战队人数
	local WTeamCount = BWDH2018:GetDetailWTeamInfo("MemCount")
	if WTeamCount == nil then
		return 0
	end
	local szMemTips = ScriptGlobal_Format("#{BWJH_181102_159}", WTeamCount );
	BS_TeamInfo_part2:SetText(szMemTips)

	local nDw3Sum = BWDH2018:GetDetailWTeamInfo("Dw3Sum")
	if nDw3Sum == nil then
		return 0
	end
	local szDw3Tips = ScriptGlobal_Format("#{BWJH_181102_166}", nDw3Sum );
	BS_TeamInfo_BasicInfo2:SetText(szDw3Tips)


	g_AtcalWTeamMemCount = BWDH2018:GetWTeamMemberCount()

	local index = 1;
	for i=1, g_MaxWTeamMemCount do
		local post, name, level, menpai, guid, eqhh, dw3 = BWDH2018:GetWTeamMemberInfoByIdx(i-1)
		if post == nil or post <= 0 then
			continue --没有数据
		else
			g_TeamInfo_Name[index]:SetText(name)
			if post == 2 then --队长
				g_TeamInfo_Pictures[index]:Show()
			else
				g_TeamInfo_Pictures[index]:Hide()
			end
			g_TeamInfo_Menpai[index]:SetText(g_MenPaiNameList[menpai])
			g_TeamInfo_Level[index]:SetText(tostring(level))

			local dwText = ScriptGlobal_Format("#{BWJH_181102_84}", dw3)
			g_TeamInfo_Dw3[index]:SetText(dwText)

			g_MemberList[index].Name 	= name
			g_MemberList[index].MP 		= menpai
			g_MemberList[index].Level 	= level
			g_MemberList[index].post     = post
			g_MemberList[index].Guid    = guid
			g_MemberList[index].dw3   = dw3
			g_MemberList[index].eqhh   = eqhh

			index = index + 1
		end
	end


	--控制显示操作按钮
	if g_isGuessOpen == 1 then
		BS_TeamInfo_ViewInfo:Hide()
    	BS_TeamInfo_PrivateChat:Hide()
    	g_isGuessOpen = 0
	else
		BS_TeamInfo_ViewInfo:Show()
   		BS_TeamInfo_PrivateChat:Show()
	end
	

	return 1
end


function BS_TeamInfo_OnEvent(event)

	if( event == "ADJEST_UI_post" ) then
		BS_TeamInfo_Resetpost()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		BS_TeamInfo_Resetpost()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "BS_TeamInfo") then
			this:Hide();
		end
	elseif(event == "UI_COMMAND") then
		if tonumber(arg0) == 8928452 then
			g_clientNpcId = -1
			local serverNpcId = -1

			if Get_XParam_INT(0) > 0 then
				serverNpcId = Get_XParam_INT(0);
			else
				serverNpcId = tonumber(arg1);
			end
			g_clientNpcId = Target:GetServerId2ClientId(serverNpcId);
		end
		if tonumber(arg0) == 20181207 then
			BS_TeamInfo_gotoWeb()
		end
		if tonumber(arg0) == 89306004 then
			g_isGuessOpen = 1
			g_clientNpcId = -1
			local serverNpcId = -1

			if Get_XParam_INT(0) > 0 then
				g_clientNpcId = Get_XParam_INT(0);
			else
				g_clientNpcId = tonumber(arg1);
			end
			this:Hide()
		end
	elseif(event == "HIDE_ON_SCENE_TRANSED")	 then
		this:Hide();
	elseif(event == "TXBW_WTEAM_INFO_SHOW") then

		local post = BWDH2018:GetWTeamMemberPost()
		if post ~= nil then --这是查看自己战队的情况
			return
		end

		--先初始化一下
		BS_TeamInfo_InitUIData()
		--填充战队信息
		if 1 == BS_TeamInfo_InitMemberListData() then
		    if g_clientNpcId and g_clientNpcId > 0 then
			    this:CareObject(g_clientNpcId, 1, "BS_TeamInfo")
			end
			this:Show()
		end
	elseif (event == "TXBW_WTEAM_INFO_SHOW_FORGUESS") then
		local curTime2Day = tonumber(DataPool:GetServerDayTime())
		local finalDay = BWDH2018:GetFinalDayByIndex(5)
		if curTime2Day > finalDay then
			SetNotifyTip("#{JHSJC_190120_93}")
			return 
		end
		
		g_isGuessOpen = 1
		--先初始化一下
		BS_TeamInfo_InitUIData()
		--填充战队信息
		if 1 == BS_TeamInfo_InitMemberListData() then
		    if g_clientNpcId and g_clientNpcId > 0 then
			    this:CareObject(g_clientNpcId, 1, "BS_TeamInfo")
			end
			this:Show()
		end
	elseif (event == "TXBW_ALL_UI_CLOSED") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	end

end
--================================================
--关闭
--================================================
function BS_TeamInfo_CloseClicked()
	g_isGuessOpen = 0
   	this:Hide();
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function BS_TeamInfo_Resetpost()
	BS_TeamInfo_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXpostition);
	BS_TeamInfo_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYpostition);
end

function BS_TeamInfo_Clicked(index)
	if index < 1 or index > g_AtcalWTeamMemCount then
		return
	end

	for i = 1, table.getn(g_TeamInfo_DragTargets) do
		g_TeamInfo_DragTargets[i]:SetProperty("HoverState", "False")
	end
	g_TeamInfo_DragTargets[index]:SetProperty("HoverState", "True")

	g_SelectIndex = index
end

--右键
function BS_TeamInfo_ToggleMemberMenu(index)

end

function BS_TeamInfo_PrivateChat_Clicked()
	if g_SelectIndex <= 0 or g_SelectIndex > g_AtcalWTeamMemCount then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	local szName = g_MemberList[g_SelectIndex].Name
	if nil ~= szName then
        Talk:ContexMenuTalk(szName)
    end
end

function BS_TeamInfo_ViewInfo_Clicked()
	if g_SelectIndex <= 0 or g_SelectIndex > g_AtcalWTeamMemCount then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	local szName = g_MemberList[g_SelectIndex].Name
	if nil ~= szName then
		if Friend:IsPlayerIsFriend(szName) == 1  then
			DataPool:ShowFriendInfo(szName)
		else
			DataPool:ShowChatInfo(szName)
		end
	end
end



function BS_TeamInfo_gotoWeb()
	GameProduceLogin:OpenURL(GetWeblink("WEB_BWJH_ZJSZK"))
end

function BS_TeamInfo_DragStarted()
	
end