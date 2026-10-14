-- 战队管理UI
-- 界面的默认位置
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_clientNpcId = -1

--标记当前战队是否有副队长
local g_CorpsHaveAssist = 0
--这个变量用的时候，要+1；保证跟g_MemberList里面的索引对应
local g_CorpsMemListIndex = -1
local g_MaxCropsMemCount = 6
local g_MinCropsMemCount = 3
local g_AtcalCropsMemCount = 0
local g_TimersInviteCorps = 0;

local g_MenPaiNameList =
{
	[0]  ="#{WCBZ_180128_59}",	--少林
	[1]  ="#{WCBZ_180128_65}",	--明教
	[2]  ="#{WCBZ_180128_67}",	--丐帮
	[3]  ="#{WCBZ_180128_61}",	--武当
	[4]  ="#{WCBZ_180128_68}",	--峨嵋
	[5]  ="#{WCBZ_180128_66}",	--星宿
	[6]  ="#{WCBZ_180128_60}",	--天龙
	[7]  ="#{WCBZ_180128_63}",	--天山
	[8]  ="#{WCBZ_180128_64}",	--逍遥
	[9]  ="#{WCBZ_180128_57}",	--无门派
	[10] ="#{WCBZ_180128_62}",	--慕容
	[11] ="#{WCBZ_180128_69}",	--唐门
	[12] ="#{WCBZ_180128_70}",	--鬼谷
	[13] ="#{WCBZ_180516_646}",	--桃花岛
	[14] ="#{XMPHM_210604_01}",
	[15] ="#{GMGameInterface_Script_DataPool_Info_ERenGu}", --menpai15 mptodo
}
--g_MemberList中的数据，每次INIT需要清空
--二者的数据非只读；也可以读，也可以写

local g_MemberList =  --pos:1队员 2副队长 3队长
{
	[1]  ={Name="",MP=9,Level=0,pos=0,Guid="",TarMp=9},
	[2]  ={Name="",MP=9,Level=0,pos=0,Guid="",TarMp=9},
	[3]  ={Name="",MP=9,Level=0,pos=0,Guid="",TarMp=9},
	[4]  ={Name="",MP=9,Level=0,pos=0,Guid="",TarMp=9},
	[5]  ={Name="",MP=9,Level=0,pos=0,Guid="",TarMp=9},
	[6]  ={Name="",MP=9,Level=0,pos=0,Guid="",TarMp=9},
}

--权限细分
--权限是这样：
--1、邀请战队——队长+副队长可以
--2、任命/解除副队长——只有队长可以
--3、解散战队——只有队长可以
--4、请离战队——队长
--5、退出战队——副队长+队员

--
local g_CorpsAuthShowList =
{
	[1] = {InviteCorps=0,Assign=0,Dismiss=0,Kick=0,Leave=1,ChangeMp=0},	--1代表队员
	[2] = {InviteCorps=1,Assign=0,Dismiss=0,Kick=0,Leave=1,ChangeMp=1},	--2代表副队长
	[3] = {InviteCorps=1,Assign=1,Dismiss=1,Kick=1,Leave=0,ChangeMp=1},	--3代表队长
}


local g_CorpsMem_Name = {}
local g_CorpsMem_Captain = {}
local g_CorpsMem_Menpai = {}
local g_CorpsMem_Level = {}
local g_CorpsMem_TarMp = {}
local g_CorpsMem_ChooseMp = {}
local g_CorpsMemDragItems = {}
local g_CorpsMemDragTargets = {}

local g_CorpsLeaderIcon = "set:Union1 image:Union_LeaderIcon_L"
local g_CorpsAssistantIcon = "set:Union1 image:Union_MemberIcon_L"

local g_ChangeMenpai_Clicked = 0

function NoDiffMatch_CreateManger_PreLoad()

	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND")
	--显示战队信息
	this:RegisterEvent("CORPS_INFO_SHOW_2018")
	--战队踢人确认
	this:RegisterEvent("CORPS_KICK_MEMBER_CONFIRMED_2018")
	--战队离开确认
	this:RegisterEvent("CORPS_MEMBER_LEAVE_CONFIRMED_2018")
	--战队信息刷新
	this:RegisterEvent("CORPS_INFO_LIST_REFRESH_2018")
	this:RegisterEvent("DISMISS_CORPS_CONFIRMED_2018")
	--战队相关的UI都要关闭
	this:RegisterEvent("CORPS_ALL_UI_CLOSED_2018")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function NoDiffMatch_CreateManger_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_CreateManger_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_CreateManger_Frame:GetProperty("UnifiedYPosition");


	--玩家名字
	g_CorpsMem_Name = {NoDiffMatch_CreateManger_List1_1, NoDiffMatch_CreateManger_List2_1, NoDiffMatch_CreateManger_List3_1, NoDiffMatch_CreateManger_List4_1,
									NoDiffMatch_CreateManger_List5_1, NoDiffMatch_CreateManger_List6_1, }

	--是否是队长
	g_CorpsMem_Captain = {NoDiffMatch_CreateManger_List1_Pic, NoDiffMatch_CreateManger_List2_Pic, NoDiffMatch_CreateManger_List3_Pic, NoDiffMatch_CreateManger_List4_Pic,
										NoDiffMatch_CreateManger_List5_Pic, NoDiffMatch_CreateManger_List6_Pic, }

	--门派
	g_CorpsMem_Menpai = {NoDiffMatch_CreateManger_List1_2, NoDiffMatch_CreateManger_List2_2, NoDiffMatch_CreateManger_List3_2, NoDiffMatch_CreateManger_List4_2,
										NoDiffMatch_CreateManger_List5_2, NoDiffMatch_CreateManger_List6_2, }

	--等级
	g_CorpsMem_Level = {NoDiffMatch_CreateManger_List1_3, NoDiffMatch_CreateManger_List2_3, NoDiffMatch_CreateManger_List3_3, NoDiffMatch_CreateManger_List4_3,
										NoDiffMatch_CreateManger_List5_3, NoDiffMatch_CreateManger_List6_3, }


	--目标门派
	g_CorpsMem_TarMp = {NoDiffMatch_CreateManger_List1_4, NoDiffMatch_CreateManger_List2_4, NoDiffMatch_CreateManger_List3_4, NoDiffMatch_CreateManger_List4_4,
										NoDiffMatch_CreateManger_List5_4, NoDiffMatch_CreateManger_List6_4, }

	--选择门派
	g_CorpsMem_ChooseMp = {NoDiffMatch_CreateManger_MPCPlay1_Choice, NoDiffMatch_CreateManger_MPCPlay2_Choice, NoDiffMatch_CreateManger_MPCPlay3_Choice, NoDiffMatch_CreateManger_MPCPlay4_Choice,
										NoDiffMatch_CreateManger_MPCPlay5_Choice, NoDiffMatch_CreateManger_MPCPlay6_Choice,}

	g_CorpsMemDragItems = {NoDiffMatch_CreateManger_List1_Btn, NoDiffMatch_CreateManger_List2_Btn, NoDiffMatch_CreateManger_List3_Btn, NoDiffMatch_CreateManger_List4_Btn,
							NoDiffMatch_CreateManger_List5_Btn, NoDiffMatch_CreateManger_List6_Btn, }
							
	g_CorpsMemDragTargets = {NoDiffMatch_CreateManger_List1_Bk, NoDiffMatch_CreateManger_List2_Bk, NoDiffMatch_CreateManger_List3_Bk, NoDiffMatch_CreateManger_List4_Bk,
							NoDiffMatch_CreateManger_List5_Bk, NoDiffMatch_CreateManger_List6_Bk, }
							
	--初始化
	NoDiffMatch_CreateManger_InitUIData();
end

function NoDiffMatch_CreateManger_InitOperButtons()

	local pos = CorpsUI_2018:GetCorpsMemberPost()
	if pos == nil or g_CorpsAuthShowList[pos] == nil then --这是查看别人战队的情况
        return
	end


	local hasAssist = CorpsUI_2018:Corps_HasAssist()
	if hasAssist and hasAssist == 1 then
		g_CorpsHaveAssist = 1
	end

	if g_CorpsAuthShowList[pos].InviteCorps == 1 then
		NoDiffMatch_CreateManger_AddMember:Enable()
	end

	if g_CorpsAuthShowList[pos].Assign == 1 then
		if g_CorpsHaveAssist == 0 then --副队长不存在则显示：任命；否则：解除
			NoDiffMatch_CreateManger_ViceLeader:SetText("#{ZBS16_160511_58}")
		else
			NoDiffMatch_CreateManger_ViceLeader:SetText("#{ZBS16_160511_59}")
		end
		NoDiffMatch_CreateManger_ViceLeader:Enable()
	end

	if g_CorpsAuthShowList[pos].Dismiss == 1 then
		NoDiffMatch_CreateManger_Dissolve:Enable()
	end

	if g_CorpsAuthShowList[pos].Kick == 1 then
		NoDiffMatch_CreateManger_Fire:Enable()
	end

	if g_CorpsAuthShowList[pos].Leave == 1 then
		NoDiffMatch_CreateManger_Leave:Enable()
	end

	if g_CorpsAuthShowList[pos].ChangeMp == 1 then
		NoDiffMatch_CreateManger_MenPaiChange:Enable()
	end
	NoDiffMatch_CreateManger_MenPaiChange:SetText("#{WCBZ_180128_96}")
end

--初始化控件数据
function NoDiffMatch_CreateManger_InitUIData()

	NoDiffMatch_CreateManger_PageHeader_Name:SetText("")
	
	local szEqhhSumTips = ScriptGlobal_Format("#{WCBZ_180128_616}", 0 );
	NoDiffMatch_CreateManger_TeamScore:SetText(szEqhhSumTips)
	
	g_CorpsMemListIndex = -1
	g_AtcalCropsMemCount = 0
	g_ChangeMenpai_Clicked = 0

	--战队操作相关按钮
	NoDiffMatch_CreateManger_AddMember:Disable() --邀请加入
	NoDiffMatch_CreateManger_ViceLeader:Disable() --任命副队长
	NoDiffMatch_CreateManger_Dissolve:Disable() --解散战队
	NoDiffMatch_CreateManger_Fire:Disable() --请离战队
	NoDiffMatch_CreateManger_Leave:Disable() --退出战队
	NoDiffMatch_CreateManger_MenPaiChange:Disable() --更改目标门派

	g_CorpsHaveAssist = 0

	for i=1, g_MaxCropsMemCount do

		g_CorpsMem_Name[i]:SetText("")
		g_CorpsMem_Captain[i]:Hide()
		g_CorpsMem_Menpai[i]:SetText("")
		g_CorpsMem_Level[i]:SetText("")
		g_CorpsMem_TarMp[i]:SetText("")
		g_CorpsMem_TarMp[i]:Show()
		g_CorpsMem_ChooseMp[i]:ResetList()
		g_CorpsMem_ChooseMp[i]:Hide()
		g_CorpsMemDragTargets[i]:SetProperty("HoverState", "False")
		g_CorpsMemDragItems[i]:SetProperty("DraggingEnabled", "False")
		g_CorpsMemDragItems[i]:SetProperty("DragAlpha", 0)
		
		g_MemberList[i].Name = ""
		g_MemberList[i].Guid = ""
		g_MemberList[i].pos = 0
		g_MemberList[i].TarMp = 9
	end

	NoDiffMatch_CreateManger_MenPaiChangeClient:Hide()
end

function NoDiffMatch_CreateManger_InitMemberListData()

	--战队名字
	local CorpsName = CorpsUI_2018:GetDetailCorpsInfo("Name")
	if CorpsName ==nil then
		return 0
	end
	local colorname = ScriptGlobal_Format("#{ZBS16_160511_47}" , CorpsName );
	NoDiffMatch_CreateManger_PageHeader_Name:SetText( colorname )
	
	local eqhhSum = CorpsUI_2018:GetDetailCorpsInfo("EqhhSum")
	local szEqhhSumTips = ScriptGlobal_Format("#{WCBZ_180128_616}", eqhhSum );
	NoDiffMatch_CreateManger_TeamScore:SetText(szEqhhSumTips)

	g_AtcalCropsMemCount = CorpsUI_2018:GetCorpsMemberCount()
	for i=1, g_AtcalCropsMemCount do
		local post, name, level, menpai, guid, tarmenpai = CorpsUI_2018:GetCorpsMemberInfoByIdx(i-1)
		if post == nil or post <= 0 then
			break --没有数据
		else
			g_CorpsMem_Name[i]:SetText(name)
			if post == 3 then --队长
				g_CorpsMem_Captain[i]:SetProperty("Image", g_CorpsLeaderIcon)
				g_CorpsMem_Captain[i]:Show()
			elseif post == 2 then --副队长
				g_CorpsMem_Captain[i]:SetProperty("Image", g_CorpsAssistantIcon)
				g_CorpsMem_Captain[i]:Show()
			else
				g_CorpsMem_Captain[i]:Hide()
			end
			g_CorpsMem_Menpai[i]:SetText(g_MenPaiNameList[menpai])
			g_CorpsMem_Level[i]:SetText(tostring(level))
			g_CorpsMem_TarMp[i]:SetText(g_MenPaiNameList[tarmenpai])

			g_MemberList[i].Name = name
			g_MemberList[i].Guid = guid
			g_MemberList[i].pos = post
			g_MemberList[i].TarMp = tarmenpai

			CorpsUI_2018:SelectMpInfo(i-1, guid, tarmenpai)
		end
	end

	--控制显示操作按钮
	NoDiffMatch_CreateManger_InitOperButtons()

	return 1

end


function NoDiffMatch_CreateManger_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_CreateManger_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		NoDiffMatch_CreateManger_ResetPos()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "NoDiffMatch_CreateManger") then
			this:Hide();
		end
	elseif(event == "UI_COMMAND") then
	  if tonumber(arg0) == 8927012 then
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
	elseif(event == "CORPS_INFO_SHOW_2018") then
		local pos = CorpsUI_2018:GetCorpsMemberPost()
		if pos == nil then --这是查看别人战队的情况
			return
		end
		
		local stage = CorpsUI_2018:GetZbsStage()
		if stage ~= 1 then
			return
		end
		--先初始化一下
		NoDiffMatch_CreateManger_InitUIData()
		--填充战队信息
		if 1 == NoDiffMatch_CreateManger_InitMemberListData() then
		    if g_clientNpcId and g_clientNpcId > 0 then
			    this:CareObject(g_clientNpcId, 1, "NoDiffMatch_CreateManger")
			end
			this:Show()
		end
	elseif(event == "CORPS_KICK_MEMBER_CONFIRMED_2018") then
	    if g_MemberList[g_CorpsMemListIndex] then
		    CorpsUI_2018:Corps_KickCorpsMember(g_MemberList[g_CorpsMemListIndex].Guid)
		end
	elseif(event == "CORPS_MEMBER_LEAVE_CONFIRMED_2018") then
		CorpsUI_2018:Corps_LeaveCorps()
	elseif(event == "DISMISS_CORPS_CONFIRMED_2018") then
		CorpsUI_2018:Corps_DismissCorps()
	elseif(event == "CORPS_INFO_LIST_REFRESH_2018")	then
		--刷新操作；重新清除+填充
		if (this:IsVisible()) then --如果当前窗体打开着才刷新，否则不刷新UI，更不能弹出来
			NoDiffMatch_CreateManger_InitUIData()
			NoDiffMatch_CreateManger_InitMemberListData()
		end
	elseif (event == "CORPS_ALL_UI_CLOSED_2018") then
		if( this:IsVisible() ) then
			this:Hide()
		end

	end

end
--================================================
--关闭
--================================================
function NoDiffMatch_CreateManger_CloseClicked()
   this:Hide();
end

--================================================
--邀请加入
--================================================
function NoDiffMatch_CreateManger_Invite_Clicked( type )

	if g_ChangeMenpai_Clicked >= 1 then
		PushDebugMessage("#{WCBZ_180128_364}");
		return
	end

	local iCur = FindFriendDataPool:GetTickCount(  )
	local pass = iCur - g_TimersInviteCorps
	if pass <= 10*1000 then
		PushDebugMessage("#{WCBZ_180128_122}");
		return
	end

	g_TimersInviteCorps = iCur

	local nRet = CorpsUI_2018:CorpsOper_InviteCorps(1)
	if nRet == nil then
		return
	end
	--0、没队伍
	if nRet == 0 then
		PushDebugMessage("#{WCBZ_180128_115}")
		return
	end
	--1、只有战队的队长或副队长作为队长时，才可邀请队员加入战队
	if nRet == 1 then
		PushDebugMessage("#{WCBZ_180128_115}")
		return
	end
	-- 只有战队的队长或副队长作为队长时，才可邀请队员加入战队
	if nRet == 2 then
		PushDebugMessage("#{WCBZ_180128_115}")
		return
	end
	
	if nRet == 3 then
		PushDebugMessage("#{WCBZ_180128_116}")
		return
	end
	
	-- 不足2人
	if nRet == 4 then
		PushDebugMessage("#{WCBZ_180128_118}")
		return
	end
	
	--5、邀请的队员已经加入其它战队 服务器判断
end


--================================================
-- 取消/任命副队长
--================================================
function NoDiffMatch_CreateManger_Leader_Clicked()
	if g_ChangeMenpai_Clicked >= 1 then
		PushDebugMessage("#{WCBZ_180128_364}");
		return
	end

	if g_CorpsHaveAssist == 0 then
		NoDiffMatch_CreateManger_Leader_Clicked1()
	else
		NoDiffMatch_CreateManger_Leader_Clicked2()
	end
end
--================================================
--任命逻辑
--================================================
function NoDiffMatch_CreateManger_Leader_Clicked1()

	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	if g_CorpsMemListIndex<=0 or g_CorpsMemListIndex>g_MaxCropsMemCount  then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end
	if g_MemberList[g_CorpsMemListIndex] == nil then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	local nTarGuid = g_MemberList[g_CorpsMemListIndex].Guid
	if nTarGuid == "" then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	if g_MemberList[g_CorpsMemListIndex].pos == 3 then
		PushDebugMessage("#{ZBS16_160511_87}")
		return
	end

	local nRet = CorpsUI_2018:CorpsOper_AssignAssist(nTarGuid)
	if nRet == nil then
		return
	end

	if nRet == 1 then
		PushDebugMessage("#{ZBS16_160511_79}")
		return
	end

	if nRet == 2 then
		PushDebugMessage("#{ZBS16_160511_85}")
		return
	end

end
--================================================
--解除逻辑
--================================================
function NoDiffMatch_CreateManger_Leader_Clicked2()
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	if g_CorpsMemListIndex<=0 or g_CorpsMemListIndex>g_MaxCropsMemCount  then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	if g_MemberList[g_CorpsMemListIndex] == nil then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	local nTarGuid = g_MemberList[g_CorpsMemListIndex].Guid
	if nTarGuid == "" then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	local nRet = CorpsUI_2018:CorpsOper_CancelAssist(nTarGuid)
	if nRet == nil then
		return
	end

	if nRet == 1 then
		PushDebugMessage("#{ZBS16_160511_79}")
		return
	end

	if nRet == 2 then
		PushDebugMessage("#{ZBS16_160511_89}")
		return
	end

	if nRet == 3 then
		PushDebugMessage("#{ZBS16_160511_90}")
		return
	end
end


--================================================
--踢出战队 这几个click为啥不在代码里面判断呢，因为要有二次确认框。
--================================================
function NoDiffMatch_CreateManger_PickOut_Clicked()

	if g_ChangeMenpai_Clicked >= 1 then
		PushDebugMessage("#{WCBZ_180128_364}");
		return
	end

	local IsLeader = CorpsUI_2018:IsCorpsLeader()
	--逻辑上两个变量可能为nil，有一为ni说明guid错误了。不执行下面逻辑
	if IsLeader ==nil then
		return
	end
	--如果二者都不为1
	if IsLeader ~=1 then
		--您不是战队的队长或副队长，不可进行该操作
		PushDebugMessage("#{ZBS16_160511_93}")
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


	if g_CorpsMemListIndex<=0 or g_CorpsMemListIndex>g_MaxCropsMemCount then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	local IsLeaderGuid = CorpsUI_2018:IsCorpsLeaderGuid(g_MemberList[g_CorpsMemListIndex].Guid)
	if IsLeaderGuid == nil or IsLeaderGuid == 1 then
	--无法请离战队队长
		PushDebugMessage("#{ZBS16_160511_92}")
		return
	end
	local IsAssistGuid = CorpsUI_2018:IsCorpsAssistGuid(g_MemberList[g_CorpsMemListIndex].Guid)
	if IsAssistGuid ==nil or IsAssistGuid == 1 then
	--请先解除该队员的副队长职务后，再进行请离战队操作
		PushDebugMessage("#{ZBS16_160511_96}")
		return
	end
	local MemCount = CorpsUI_2018:GetCorpsMemberCount()
	--再踢人就不到7人了，强制解散队伍
	if MemCount ~=nil and MemCount <= g_MinCropsMemCount then
		PushEvent("CORPS_KICK_MEMBER_2018",0,g_MemberList[g_CorpsMemListIndex].Name)
	else
		PushEvent("CORPS_KICK_MEMBER_2018",1,g_MemberList[g_CorpsMemListIndex].Name)
	end
end

--================================================
--离开战队
--================================================
function NoDiffMatch_CreateManger_OutTeam_Clicked()

	if g_ChangeMenpai_Clicked >= 1 then
		PushDebugMessage("#{WCBZ_180128_364}");
		return
	end

	local IsLeader = CorpsUI_2018:IsCorpsLeader()
	if IsLeader and IsLeader ==1 then
		--战队队长不可离开战队
		PushDebugMessage("#{ZBS16_160511_105}")
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


	local MemCount = CorpsUI_2018:GetCorpsMemberCount()
	--再踢人就不到7人了，强制解散队伍
	if MemCount ~=nil and MemCount <= g_MinCropsMemCount then
		PushEvent("CORPS_MEMBER_LEAVE_2018",0)
	else
		local CorpsName = CorpsUI_2018:GetDetailCorpsInfo("Name")
		PushEvent("CORPS_MEMBER_LEAVE_2018",1, CorpsName)
	end

end

--================================================
--解散战队
--================================================
function NoDiffMatch_CreateManger_Dismiss_Clicked()

	if g_ChangeMenpai_Clicked >= 1 then
		PushDebugMessage("#{WCBZ_180128_364}");
		return
	end

	local IsLeader = CorpsUI_2018:IsCorpsLeader()
	if (IsLeader == nil or IsLeader <=0) then
		PushDebugMessage("#{ZBS16_160511_93}")
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

	PushEvent("DISMISS_CORPS_2018")
end

function NoDiffMatch_CreateManger_MenPaiChange_Clicked()
	local IsLeader = CorpsUI_2018:IsCorpsLeader()
	local IsAssitant = CorpsUI_2018:IsCorpsAssist()
	--逻辑上两个变量可能为nil，有一为ni说明guid错误了。不执行下面逻辑
	if IsLeader ~=1 and IsAssitant ~= 1 then
		--您不是战队的队长或副队长，不可进行该操作
		PushDebugMessage("#{ZBS16_160511_93}")
		return
	end

	if g_ChangeMenpai_Clicked == 0 then
		g_ChangeMenpai_Clicked = 1
		NoDiffMatch_CreateManger_MenPaiChange:SetText("#{WCBZ_180128_98}")
		for i=1, g_AtcalCropsMemCount do
			g_CorpsMem_TarMp[i]:Hide()
		end
		NoDiffMatch_CreateManger_MenPaiChangeClient:Show()
		
		for i=1, g_AtcalCropsMemCount do
			g_CorpsMem_ChooseMp[i]:ResetList();
			
			local tarmenpai = g_MemberList[i].TarMp
			g_CorpsMem_ChooseMp[i]:SetText(g_MenPaiNameList[tarmenpai])
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("少林", 0 );
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("明教", 1 );
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("丐帮", 2 );
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("武当", 3 );
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("峨嵋", 4 );
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("星宿", 5 );
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("天龙", 6 );
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("天山", 7 );
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("逍遥", 8 );
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("慕容", 10);
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("唐门", 11);
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("鬼谷", 12);
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("桃花岛", 13);
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("绝情谷", 14);
			g_CorpsMem_ChooseMp[i]:ComboBoxAddItem("恶人谷", 15);--menpai15 mptodo
			if tarmenpai >= 9 then
				g_CorpsMem_ChooseMp[i]:SetCurrentSelect( tarmenpai - 1 );
			else
				g_CorpsMem_ChooseMp[i]:SetCurrentSelect( tarmenpai );
			end
			g_CorpsMem_ChooseMp[i]:Show()
		end

	else
		g_ChangeMenpai_Clicked = 0
		NoDiffMatch_CreateManger_MenPaiChange:SetText("#{WCBZ_180128_96}")
		for i=1, g_AtcalCropsMemCount do
			g_CorpsMem_TarMp[i]:Show()
		end
		NoDiffMatch_CreateManger_MenPaiChangeClient:Hide()
		local nRet = CorpsUI_2018:Corps_ChangeMenpai()
		if nRet == 0 then --成功
			return
		end	
		
		--恢复到之前的数据
		for i=1, g_AtcalCropsMemCount do
			local post, name, level, menpai, guid, tarmenpai = CorpsUI_2018:GetCorpsMemberInfoByIdx(i-1)
			if post == nil or post <= 0 then
				break --没有数据
			end

			CorpsUI_2018:SelectMpInfo(i-1, guid, tarmenpai)
		end
	
		if nRet == nil then --不能出现
			return
		end
		
		if nRet == 1 then
			PushDebugMessage("#{WCBZ_180128_139}")
			return
		end

		if nRet == 2 then
			PushDebugMessage("有的队员没有门派")
			return
		end
	end

end

function NoDiffMatch_CreateManger_MPCPlay_Choice_Clicked(index)

	if index < 1 or index > g_MaxCropsMemCount then
		return
	end

	local _name,ComIdx = g_CorpsMem_ChooseMp[index]:GetCurrentSelect()

	if ComIdx >= 0 and ComIdx <= 15 and ComIdx ~= 9 then--menpai15 mptodo
		g_CorpsMem_ChooseMp[index]:SetText(g_MenPaiNameList[ComIdx])
		CorpsUI_2018:SelectMpInfo(index-1, g_MemberList[index].Guid, ComIdx)
	end

end

function NoDiffMatch_CreateManger_ToggleMemberMenu(memIdx)
	--memIdx是当前位置
	if memIdx==nil or memIdx<1 or memIdx>g_AtcalCropsMemCount then
		return
	end

	NoDiffMatch_CreateManger_Clicked(memIdx)
	--CorpsUI_2018:OpenMenu(tonumber(memIdx))
end

function NoDiffMatch_CreateManger_Clicked(index)
	if index==nil or index<1 or index>g_AtcalCropsMemCount then
		return
	end

	g_CorpsMemListIndex = index

	for i = 1, table.getn(g_CorpsMemDragTargets) do
		g_CorpsMemDragTargets[i]:SetProperty("HoverState", "False")
	end
	g_CorpsMemDragTargets[index]:SetProperty("HoverState", "True")
end



--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_CreateManger_ResetPos()
	NoDiffMatch_CreateManger_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_CreateManger_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function NoDiffMatch_CreateManger_DragStarted()
	--for i = 1, table.getn(g_CorpsMemDragTargets) do
	--	g_CorpsMemDragTargets[i]:SetProperty("HoverState", "False")
	--end
end
