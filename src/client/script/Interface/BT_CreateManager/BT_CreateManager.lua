-- 战队管理UI
-- 界面的默认位置
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_clientNpcId = -1


--这个变量用的时候，要+1；保证跟g_MemberList里面的索引对应
local g_WTeamMemListIndex = -1
local g_MaxWTeamMemCount = 6
local g_AtcalWTeamMemCount = 0
local g_TimersInvite = 0;

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
	[9]  ="#{WCBZ_180128_57}",
	[10] ="#{XQ_MP_10}",
	[11] ="#{XMPTM_130123_05}",
	[12] ="#{XMPGG_160524_02}",
	[13] ="#{XQ_MP_15}", --桃花岛
	[14] ="#{XMPHM_210604_01}",
	[15] ="#{GMGameInterface_Script_DataPool_Info_ERenGu}",--menpai15 mptodo
}
--g_MemberList中的数据，每次INIT需要清空
--二者的数据非只读；也可以读，也可以写

local g_MemberList =  --pos:1队员 2队长
{
	[1]  ={Name="",MP=9,Level=0,pos=0,Guid="",eqhh=0},
	[2]  ={Name="",MP=9,Level=0,pos=0,Guid="",eqhh=0},
	[3]  ={Name="",MP=9,Level=0,pos=0,Guid="",eqhh=0},
	[4]  ={Name="",MP=9,Level=0,pos=0,Guid="",eqhh=0},
	[5]  ={Name="",MP=9,Level=0,pos=0,Guid="",eqhh=0},
	[6]  ={Name="",MP=9,Level=0,pos=0,Guid="",eqhh=0},
	[7]  ={Name="",MP=9,Level=0,pos=0,Guid="",eqhh=0},
	[8]  ={Name="",MP=9,Level=0,pos=0,Guid="",eqhh=0},
	[9]  ={Name="",MP=9,Level=0,pos=0,Guid="",eqhh=0},
	[10]  ={Name="",MP=9,Level=0,pos=0,Guid="",eqhh=0},
}

--权限细分
--权限是这样：
--1、邀请战队——队长+副队长可以
--3、解散战队——只有队长可以
--4、请离战队——队长
--5、退出战队——副队长+队员

--
local g_WTeamAuthShowList =
{
	[1] = {Invite=0,Dismiss=0,Kick=0,Leave=1},	--1代表队员
	[2] = {Invite=1,Dismiss=1,Kick=1,Leave=0},	--2代表队长
}


local g_WTeamMem_Name = {}
local g_WTeamMem_Captain = {}
local g_WTeamMem_Menpai = {}
local g_WTeamMem_Level = {}
local g_WTeamMem_Eqhh = {}
local g_CreateManger_DragItems = {}
local g_CreateManger_DragTargets = {}

local g_WTeamLeaderIcon = "set:Union1 image:Union_LeaderIcon_L"
local g_WTeamAssistantIcon = "set:Union1 image:Union_MemberIcon_L"


function BT_CreateManager_PreLoad()

	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND")
	--显示战队信息
	this:RegisterEvent("DFS_WTEAM_INFO_SHOW")
	--战队踢人确认
	this:RegisterEvent("DFS_WTEAM_KICK_MEMBER_CONFIRM")
	--战队离开确认
	this:RegisterEvent("DFS_WTEAM_MEMBER_LEAVE_CONFIRM")
	--战队信息刷新
	this:RegisterEvent("DFS_WTEAM_INFO_LIST_REFRESH")
	this:RegisterEvent("DFS_WTEAM_DISMISS_CONFIRM")
	
	--战队相关的UI都要关闭
	this:RegisterEvent("DFS_ALL_UI_CLOSED")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function BT_CreateManager_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BT_CreateManager_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BT_CreateManager_Frame:GetProperty("UnifiedYPosition");


	--玩家名字
	g_WTeamMem_Name = {BT_CreateManager_List1_1, BT_CreateManager_List2_1, BT_CreateManager_List3_1, BT_CreateManager_List4_1,
									BT_CreateManager_List5_1, BT_CreateManager_List6_1,}

	--是否是队长
	g_WTeamMem_Captain = {BT_CreateManager_List1_Pic, BT_CreateManager_List2_Pic, BT_CreateManager_List3_Pic, BT_CreateManager_List4_Pic,
										BT_CreateManager_List5_Pic, BT_CreateManager_List6_Pic,}

	--门派
	g_WTeamMem_Menpai = {BT_CreateManager_List1_2, BT_CreateManager_List2_2, BT_CreateManager_List3_2, BT_CreateManager_List4_2,
										BT_CreateManager_List5_2, BT_CreateManager_List6_2,}

	--等级
	g_WTeamMem_Level = {BT_CreateManager_List1_3, BT_CreateManager_List2_3, BT_CreateManager_List3_3, BT_CreateManager_List4_3,
										BT_CreateManager_List5_3, BT_CreateManager_List6_3, }

	--装备评分
	g_WTeamMem_Eqhh = {BT_CreateManager_List1_4, BT_CreateManager_List2_4, BT_CreateManager_List3_4, BT_CreateManager_List4_4,
										BT_CreateManager_List5_4, BT_CreateManager_List6_4, }
										
	g_CreateManger_DragItems = {BT_CreateManager_List1_Btn, BT_CreateManager_List2_Btn, BT_CreateManager_List3_Btn, BT_CreateManager_List4_Btn,
										BT_CreateManager_List5_Btn, BT_CreateManager_List6_Btn,}

	g_CreateManger_DragTargets = {BT_CreateManager_List1_Bk, BT_CreateManager_List2_Bk, BT_CreateManager_List3_Bk, BT_CreateManager_List4_Bk,
										BT_CreateManager_List5_Bk, BT_CreateManager_List6_Bk,}
end

function BT_CreateManager_InitOperButtons()

	local pos = DFS:GetMyPost()
	if pos == nil or g_WTeamAuthShowList[pos] == nil then --这是查看别人战队的情况
        return
	end


	if g_WTeamAuthShowList[pos].Invite == 1 then
		BT_CreateManager_AddMember:Enable()
	end


	if g_WTeamAuthShowList[pos].Dismiss == 1 then
		BT_CreateManager_Dissolve:Enable()
	end

	if g_WTeamAuthShowList[pos].Kick == 1 then
		BT_CreateManager_Fire:Enable()
	end

	if g_WTeamAuthShowList[pos].Leave == 1 then
		BT_CreateManager_Leave:Enable()
	end

end

--初始化控件数据
function BT_CreateManager_InitUIData()
	
	g_WTeamMemListIndex = -1
	g_AtcalWTeamMemCount = 0

	--战队操作相关按钮
	BT_CreateManager_AddMember:Disable() --邀请加入
	BT_CreateManager_Dissolve:Disable() --解散战队
	BT_CreateManager_Fire:Disable() --请离战队
	BT_CreateManager_Leave:Disable() --退出战队


	for i=1, g_MaxWTeamMemCount do

		g_WTeamMem_Name[i]:SetText("")
		g_WTeamMem_Captain[i]:Hide()
		g_WTeamMem_Menpai[i]:SetText("")
		g_WTeamMem_Level[i]:SetText("")
		g_WTeamMem_Eqhh[i]:SetText("")
		
		g_CreateManger_DragItems[i]:SetProperty("DraggingEnabled", "False")
		g_CreateManger_DragTargets[i]:SetProperty("HoverState", "False")
		
		g_MemberList[i].Name = ""
		g_MemberList[i].Guid = ""
		g_MemberList[i].pos = 0
		g_MemberList[i].eqhh = 0
	end

end

function BT_CreateManager_InitMemberListData()

	--战队名字
	local WTeamName = DFS:GetDetailWTeamInfo("Name")
	if WTeamName ==nil then
		return
	end
	local szWTeamNameTips = ScriptGlobal_Format("#{DFSZ_190613_189}", WTeamName );
	BT_CreateManager_Top_Text1:SetText(szWTeamNameTips)
	
	--战队id
	local WTeamId = DFS:GetDetailWTeamInfo("WTeamId")
	if WTeamId == nil then
		return
	end
	local szIdTips = ScriptGlobal_Format("#{DFSZ_190613_190}", WTeamId );
	BT_CreateManager_Top_Text2:SetText(szIdTips)
	
	--战队人数
	local WTeamCount = DFS:GetDetailWTeamInfo("MemCount")
	if WTeamCount == nil then
		return
	end
	local szMemTips = ScriptGlobal_Format("#{DFSZ_190613_191}", WTeamCount );
	BT_CreateManager_Top_Text3:SetText(szMemTips)
	
	g_AtcalWTeamMemCount = DFS:GetWTeamMemberCount()
	
	local index = 1;
	for i=1, g_MaxWTeamMemCount do
		local post, name, level, menpai, guid, eqhh = DFS:GetWTeamMemberInfoByIdx(i-1)
		if post == nil or post <= 0 then
			continue --没有数据
		else
			g_WTeamMem_Name[index]:SetText(name)
			if post == 2 then --队长
				g_WTeamMem_Captain[index]:SetProperty("Image", g_WTeamLeaderIcon)
				g_WTeamMem_Captain[index]:Show()
			else
				g_WTeamMem_Captain[index]:Hide()
			end
			g_WTeamMem_Menpai[index]:SetText(g_MenPaiNameList[menpai])
			g_WTeamMem_Level[index]:SetText(tostring(level))
			
			g_WTeamMem_Eqhh[index]:SetText(tostring(eqhh))

			g_MemberList[index].Name = name
			g_MemberList[index].Guid = guid
			g_MemberList[index].pos = post
			g_MemberList[index].eqhh = eqhh
			index = index + 1
		end
	end

	--控制显示操作按钮
	BT_CreateManager_InitOperButtons()

	return 1

end


function BT_CreateManager_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BT_CreateManager_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		BT_CreateManager_ResetPos()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "BT_CreateManager") then
			this:Hide();
		end
	elseif(event == "UI_COMMAND") then
	  if tonumber(arg0) == 2915232 then
			g_clientNpcId = -1
			local serverNpcId = -1

			if Get_XParam_INT(0) > 0 then
				serverNpcId = Get_XParam_INT(0);
			else
				serverNpcId = tonumber(arg1);
			end
			g_clientNpcId = Target:GetServerId2ClientId(serverNpcId);
		end
	elseif(event == "HIDE_ON_SCENE_TRANSED")	 then
		this:Hide();
	elseif(event == "DFS_WTEAM_INFO_SHOW") then
		local pos = DFS:GetMyPost()
		if pos == nil then --这是查看别人战队的情况
			return
		end
		

		--先初始化一下
		BT_CreateManager_InitUIData()
		--填充战队信息
		if 1 == BT_CreateManager_InitMemberListData() then
		    if g_clientNpcId and g_clientNpcId > 0 then
			    this:CareObject(g_clientNpcId, 1, "BT_CreateManager")
			end
			this:Show()
		end
	elseif(event == "DFS_WTEAM_KICK_MEMBER_CONFIRM") then
	    if g_MemberList[g_WTeamMemListIndex] then
		    DFS:WTeam_KickMember(g_MemberList[g_WTeamMemListIndex].Guid)
		end
	elseif(event == "DFS_WTEAM_MEMBER_LEAVE_CONFIRM") then
		DFS:WTeam_Leave()
	elseif(event == "DFS_WTEAM_DISMISS_CONFIRM") then
		DFS:WTeam_Dismiss()
	elseif(event == "DFS_WTEAM_INFO_LIST_REFRESH")	then
		--刷新操作；重新清除+填充
		if (this:IsVisible() == true) then --如果当前窗体打开着才刷新，否则不刷新UI，更不能弹出来
			BT_CreateManager_InitUIData()
			BT_CreateManager_InitMemberListData()
		end
	elseif (event == "DFS_ALL_UI_CLOSED") then
		if( this:IsVisible() ) then
			this:Hide()
		end

	end

end
--================================================
--关闭
--================================================
function BT_CreateManager_CloseClicked()
   this:Hide();
end

--================================================
--邀请加入
--================================================
function BT_CreateManager_Invite_Clicked( )

	local iCur = FindFriendDataPool:GetTickCount(  )
	local pass = iCur - g_TimersInvite
	if pass <= 10*1000 then
		PushDebugMessage("#{DFSZ_190613_224}");
		return
	end

	g_TimersInvite = iCur

	local nRet = DFS:WTeamOper_Invite()
	if nRet == nil then
		return
	end
	--0、没队伍
	if nRet == -1 then
		PushDebugMessage("#{DFSZ_190613_219}")
		return
	end
	--1、只有战队的队长或副队长作为队长时，才可邀请队员加入战队
	if nRet == -2 then
		PushDebugMessage("#{DFSZ_190613_219}")
		return
	end
	-- 一次只能邀请一名成员加入战队，请调整队伍后再邀请
	if nRet == -3 then
		PushDebugMessage("#{DFSZ_190613_221}")
		return
	end
	
	if nRet == -4 then
		PushDebugMessage("#{DFSZ_190613_219}")
		return
	end
	
	if nRet == -5 then
		PushDebugMessage("#{DFSZ_190613_218}")
		return
	end
	
	--邀请的队员已经加入其它战队 服务器判断
end



--================================================
--踢出战队 这几个click为啥不在代码里面判断呢，因为要有二次确认框。
--================================================
function BT_CreateManager_PickOut_Clicked()

	local IsLeader = DFS:IsWTeamLeader()
	--逻辑上两个变量可能为nil，有一为ni说明guid错误了。不执行下面逻辑
	if IsLeader ==nil then
		return
	end
	--如果二者都不为1
	if IsLeader ~=1 then
		--您不是战队的队长或副队长，不可进行该操作
		PushDebugMessage("#{DFSZ_190613_201}")
		return
	end

	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end


	if g_WTeamMemListIndex<=0 or g_WTeamMemListIndex>g_MaxWTeamMemCount then
		PushDebugMessage("#{DFSZ_190613_202}")
		return
	end

	local IsLeaderGuid = DFS:IsWTeamLeaderGuid(g_MemberList[g_WTeamMemListIndex].Guid)
	if IsLeaderGuid == nil or IsLeaderGuid == 1 then
	--无法请离战队队长
		PushDebugMessage("#{DFSZ_190613_203}")
		return
	end

	local MemCount = DFS:GetWTeamMemberCount()
	--再踢人就不到3人了，强制解散队伍
	if MemCount ~=nil and MemCount <= 3 then
		PushEvent("DFS_WTEAM_KICK_MEMBER", 0,g_MemberList[g_WTeamMemListIndex].Name)
	else
		PushEvent("DFS_WTEAM_KICK_MEMBER", 1,g_MemberList[g_WTeamMemListIndex].Name)
	end
end

--================================================
--离开战队
--================================================
function BT_CreateManager_OutTeam_Clicked()

	local IsLeader = DFS:IsWTeamLeader()
	if IsLeader and IsLeader ==1 then
		--战队队长不可离开战队
		PushDebugMessage("#{DFSZ_190613_238}")
		return
	end

	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end


	local MemCount = DFS:GetWTeamMemberCount()
	--再踢人就不到3人了，强制解散队伍
	if MemCount ~=nil and MemCount <= 3 then
		PushEvent("DFS_WTEAM_MEMBER_LEAVE",0)
	else
		local WTeamName = DFS:GetDetailWTeamInfo("Name")
		PushEvent("DFS_WTEAM_MEMBER_LEAVE",1, WTeamName)
	end

end

--================================================
--解散战队
--================================================
function BT_CreateManager_Dismiss_Clicked()
	
	local IsLeader = DFS:IsWTeamLeader()
	if (IsLeader == nil or IsLeader <=0) then
		PushDebugMessage("#{DFSZ_190613_213}")
		return
	end

	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	PushEvent("DFS_WTEAM_DISMISS")
end


function BT_CreateManager_Clicked(index)
	if index==nil or index<1 or index>g_AtcalWTeamMemCount then
		return
	end

	for i = 1, table.getn(g_CreateManger_DragTargets) do
		g_CreateManger_DragTargets[i]:SetProperty("HoverState", "False")
	end
	g_CreateManger_DragTargets[index]:SetProperty("HoverState", "True")
	
	g_WTeamMemListIndex = index

end



--================================================
-- 恢复界面的默认相对位置
--================================================
function BT_CreateManager_ResetPos()
	BT_CreateManager_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BT_CreateManager_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end


