-- 战队信息查看
-- 界面的默认位置
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_clientNpcId = -1

local g_MaxCropsMemCount = 6

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
--g_MemberList和g_CorpsMatchInfoList中的数据，每次INIT需要清空
--二者的数据非只读；也可以读，也可以写

local g_MemberList =  --pos:1队员 2副队长 3队长
{
	[1]  ={Name="",MP=9,Level=0,pos=0,Guid="",TarMP=9},
	[2]  ={Name="",MP=9,Level=0,pos=0,Guid="",TarMP=9},
	[3]  ={Name="",MP=9,Level=0,pos=0,Guid="",TarMP=9},
	[4]  ={Name="",MP=9,Level=0,pos=0,Guid="",TarMP=9},
	[5]  ={Name="",MP=9,Level=0,pos=0,Guid="",TarMP=9},
	[6]  ={Name="",MP=9,Level=0,pos=0,Guid="",TarMP=9},
}

local g_CorpsMem_Name = {}
local g_CorpsMem_Captain = {}
local g_CorpsMem_Menpai = {}
local g_CorpsMem_Level = {}
local g_CorpsMem_SelectMp = {}
local g_CorpsMemDragTargets = {}

local g_SelectIndex = -1

function NoDiffMatch_CreateTeamInfo_PreLoad()

	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND")
	--显示战队信息
	this:RegisterEvent("CORPS_INFO_SHOW_2018")
	--战队相关的UI都要关闭
	this:RegisterEvent("CORPS_ALL_UI_CLOSED_2018")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NoDiffMatch_CreateTeamInfo_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_CreateTeamInfo_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_CreateTeamInfo_Frame:GetProperty("UnifiedYPosition");

    g_CorpsMem_Captain[1] = NoDiffMatch_CreateTeamInfo_List1_Pic;
	g_CorpsMem_Captain[2] = NoDiffMatch_CreateTeamInfo_List2_Pic;
	g_CorpsMem_Captain[3] = NoDiffMatch_CreateTeamInfo_List3_Pic;
	g_CorpsMem_Captain[4] = NoDiffMatch_CreateTeamInfo_List4_Pic;
	g_CorpsMem_Captain[5] = NoDiffMatch_CreateTeamInfo_List5_Pic;
	g_CorpsMem_Captain[6] = NoDiffMatch_CreateTeamInfo_List6_Pic;

	g_CorpsMem_Name[1] = NoDiffMatch_CreateTeamInfo_List1_1;
	g_CorpsMem_Name[2] = NoDiffMatch_CreateTeamInfo_List2_1;
	g_CorpsMem_Name[3] = NoDiffMatch_CreateTeamInfo_List3_1;
	g_CorpsMem_Name[4] = NoDiffMatch_CreateTeamInfo_List4_1;
	g_CorpsMem_Name[5] = NoDiffMatch_CreateTeamInfo_List5_1;
	g_CorpsMem_Name[6] = NoDiffMatch_CreateTeamInfo_List6_1;
	
	g_CorpsMem_Menpai[1] = NoDiffMatch_CreateTeamInfo_List1_2;
	g_CorpsMem_Menpai[2] = NoDiffMatch_CreateTeamInfo_List2_2;
	g_CorpsMem_Menpai[3] = NoDiffMatch_CreateTeamInfo_List3_2;
	g_CorpsMem_Menpai[4] = NoDiffMatch_CreateTeamInfo_List4_2;
	g_CorpsMem_Menpai[5] = NoDiffMatch_CreateTeamInfo_List5_2;
	g_CorpsMem_Menpai[6] = NoDiffMatch_CreateTeamInfo_List6_2;
	
	g_CorpsMem_Level[1] = NoDiffMatch_CreateTeamInfo_List1_3;
	g_CorpsMem_Level[2] = NoDiffMatch_CreateTeamInfo_List2_3;
	g_CorpsMem_Level[3] = NoDiffMatch_CreateTeamInfo_List3_3;
	g_CorpsMem_Level[4] = NoDiffMatch_CreateTeamInfo_List4_3;
	g_CorpsMem_Level[5] = NoDiffMatch_CreateTeamInfo_List5_3;
	g_CorpsMem_Level[6] = NoDiffMatch_CreateTeamInfo_List6_3;
	
	g_CorpsMem_SelectMp[1] = NoDiffMatch_CreateTeamInfo_List1_4;
	g_CorpsMem_SelectMp[2] = NoDiffMatch_CreateTeamInfo_List2_4;
	g_CorpsMem_SelectMp[3] = NoDiffMatch_CreateTeamInfo_List3_4;
	g_CorpsMem_SelectMp[4] = NoDiffMatch_CreateTeamInfo_List4_4;
	g_CorpsMem_SelectMp[5] = NoDiffMatch_CreateTeamInfo_List5_4;
	g_CorpsMem_SelectMp[6] = NoDiffMatch_CreateTeamInfo_List6_4;
	
	--
	g_CorpsMemDragTargets[1] = NoDiffMatch_CreateTeamInfo_List1;
	g_CorpsMemDragTargets[2] = NoDiffMatch_CreateTeamInfo_List2;
	g_CorpsMemDragTargets[3] = NoDiffMatch_CreateTeamInfo_List3;
	g_CorpsMemDragTargets[4] = NoDiffMatch_CreateTeamInfo_List4;
	g_CorpsMemDragTargets[5] = NoDiffMatch_CreateTeamInfo_List5;
	g_CorpsMemDragTargets[6] = NoDiffMatch_CreateTeamInfo_List6;
end


--初始化控件数据
function NoDiffMatch_CreateTeamInfo_InitUIData()

	NoDiffMatch_CreateTeamInfo_part1:SetText("");
	local text = ScriptGlobal_Format("#{ZBS16_160505_05}", 0 );
	NoDiffMatch_CreateTeamInfo_part2:SetText(text);

	local text2 = ScriptGlobal_Format("#{WCBZ_180128_616}", 0 );
	NoDiffMatch_CreateTeamInfo_BasicInfo2:SetText(text2);
	
	for i=1, g_MaxCropsMemCount do
		g_CorpsMem_Captain[i]:Hide()
		g_CorpsMem_Name[i]:SetText("")
		g_CorpsMem_Menpai[i]:SetText("")
		g_CorpsMem_Level[i]:SetText("")
		g_CorpsMem_SelectMp[i]:SetText("")
		g_CorpsMemDragTargets[i]:SetProperty("HoverState", "False")
	end

	for i=1, g_MaxCropsMemCount do
		g_MemberList[i].Name = ""
		g_MemberList[i].MP=9
		g_MemberList[i].Level=0
		g_MemberList[i].pos=0
		g_MemberList[i].Guid=""
		g_MemberList[i].TarMP=9
	end

	g_SelectIndex = -1
end
--!!!reloadscript =NoDiffMatch_CreateTeamInfo
function NoDiffMatch_CreateTeamInfo_InitMemberListData()
	--战队名字
	local CorpsName = CorpsUI_2018:GetDetailCorpsInfo("Name")
	if CorpsName ==nil then
		return 0
	end
	NoDiffMatch_CreateTeamInfo_part1:SetText( CorpsName )
	--战队人数
	local CorpsCount = CorpsUI_2018:GetDetailCorpsInfo("MemCount")
	if CorpsCount == nil then
		return 0
	end
	local szMemTips = ScriptGlobal_Format("#{ZBS16_160505_05}", CorpsCount );
	NoDiffMatch_CreateTeamInfo_part2:SetText(szMemTips)
	
	local eqhhSum = CorpsUI_2018:GetDetailCorpsInfo("EqhhSum")
	local szEqhhSumTips = ScriptGlobal_Format("#{WCBZ_180128_616}", eqhhSum );
	NoDiffMatch_CreateTeamInfo_BasicInfo2:SetText(szEqhhSumTips)


	local cropsMemCount = CorpsUI_2018:GetCorpsMemberCount()
	for i=1, cropsMemCount do
		local post, name, level, menpai, guid, tarmenpai = CorpsUI_2018:GetCorpsMemberInfoByIdx(i-1)
		if post == nil or post <= 0 then
			break --没有数据
		else
			g_MemberList[i].Name 	= name
			g_MemberList[i].MP 		= menpai
			g_MemberList[i].Level 	= level
			g_MemberList[i].pos     = post
			g_MemberList[i].Guid    = guid
			g_MemberList[i].TarMP   = tarmenpai
		end
	end
	
	--最多6个人
	for i = 1, g_MaxCropsMemCount do
		--后面没有战队成员了，那么就跳出
		if g_MemberList[i].Name == "" then
			break
		end
		
		g_CorpsMem_Name[i]:SetText( g_MemberList[i].Name )
		g_CorpsMem_Menpai[i]:SetText( g_MenPaiNameList[g_MemberList[i].MP] )
		g_CorpsMem_Level[i]:SetText( g_MemberList[i].Level )
		g_CorpsMem_SelectMp[i]:SetText( g_MenPaiNameList[g_MemberList[i].TarMP] )

		if g_MemberList[i].pos ==  3 then --副队长对应图片也显示，先跟队长弄一个
			g_CorpsMem_Captain[i]:SetProperty("Image", "set:Union1 image:Union_LeaderIcon_L");
			g_CorpsMem_Captain[i]:Show()
		elseif g_MemberList[i].pos == 2 then --副队长对应图片也显示，先跟队长弄一个
			g_CorpsMem_Captain[i]:SetProperty("Image", "set:Union1 image:Union_MemberIcon_L");
			g_CorpsMem_Captain[i]:Show()
		end
	end

	--控制显示操作按钮
	NoDiffMatch_CreateTeamInfo_ViewInfo:Show()
    NoDiffMatch_CreateTeamInfo_PrivateChat:Show()

	return 1
end


function NoDiffMatch_CreateTeamInfo_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_CreateTeamInfo_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		NoDiffMatch_CreateTeamInfo_ResetPos()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "NoDiffMatch_CreateTeamInfo") then
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
		local stage = CorpsUI_2018:GetZbsStage()
		if stage >= 4 then
			return
		end
		
		if stage == 1 then
			local pos = CorpsUI_2018:GetCorpsMemberPost()
			if pos ~= nil then --这是查看自己战队的情况
				return
			end
		end
		
		--先初始化一下
		NoDiffMatch_CreateTeamInfo_InitUIData()
		--填充战队信息
		if 1 == NoDiffMatch_CreateTeamInfo_InitMemberListData() then
		    if g_clientNpcId and g_clientNpcId > 0 then
			    this:CareObject(g_clientNpcId, 1, "NoDiffMatch_CreateTeamInfo")
			end
			this:Show()
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
function NoDiffMatch_CreateTeamInfo_CloseClicked()
   this:Hide();
end

--
function NoDiffMatch_CreateTeamInfo_List_Click(index)
	local CorpsCount = CorpsUI_2018:GetDetailCorpsInfo("MemCount")
	if index <= 0 or index > CorpsCount then
		return
	end
	
	for i=1, g_MaxCropsMemCount do
		g_CorpsMemDragTargets[i]:SetProperty("HoverState", "False")
	end
	
	g_CorpsMemDragTargets[index]:SetProperty("HoverState", "True")
	
	g_SelectIndex = index
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_CreateTeamInfo_ResetPos()
	NoDiffMatch_CreateTeamInfo_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_CreateTeamInfo_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function NoDiffMatch_CreateTeamInfo_PrivateChat_Clicked()
	if g_SelectIndex < 0 then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	local szName = g_MemberList[g_SelectIndex].Name
	if nil ~= szName then
        Talk:ContexMenuTalk(szName)
    end
end

function NoDiffMatch_CreateTeamInfo_ViewInfo_Clicked()
	if g_SelectIndex < 0 then
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


