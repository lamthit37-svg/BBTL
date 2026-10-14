-- 战队管理UI
-- 界面的默认位置
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_clientNpcId = -1
local g_ServerNpcId = -1
local g_MaxCropsMemCount = 12

local g_TimersInviteTeam = 0;
local g_CorpsMemListIndex = -1

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
	[15] ="#{GMGameInterface_Script_DataPool_Info_ERenGu}",--menpai15 mptodo
}


--权限细分
--权限是这样：
--1、邀请战队——只有队长可以
--2、任命/解除副队长——只有队长可以
--3、解散战队——只有队长可以
--4、请离战队——队长+副队长
--5、退出战队——副队长+队员
--6、邀请入团——所有人
--
local g_CorpsAuthShowList =
{
	[1] = {InviteTeam=0, Assign=0},	--1代表队员
	[2] = {InviteTeam=1, Assign=0},	--2代表副队长
	[3] = {InviteTeam=1, Assign=1},	--3代表队长

}


local g_BarList = {}

local g_CorpsLeaderIcon = "set:Union1 image:Union_LeaderIcon_L"
local g_CorpsAssistantIcon = "set:Union1 image:Union_MemberIcon_L"

function NoDiffMatch_TeamManger_PreLoad()

	this:RegisterEvent("CLOSE_WINDOW",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND")
	--显示战队信息
	this:RegisterEvent("CORPS_INFO_SHOW_2018")
	--战队信息刷新
	this:RegisterEvent("CORPS_INFO_LIST_REFRESH_2018")
	
	--战队相关的UI都要关闭
	this:RegisterEvent("CORPS_ALL_UI_CLOSED_2018",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function NoDiffMatch_TeamManger_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_TeamManger_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_TeamManger_Frame:GetProperty("UnifiedYPosition");

end


function NoDiffMatch_TeamManger_InitOperButtons()

	local pos = CorpsUI_2018:GetCorpsMemberPost()
	if pos == nil or g_CorpsAuthShowList[pos] == nil then --这是查看别人战队的情况
        return
	end

	if g_CorpsAuthShowList[pos].InviteTeam == 1 then
		NoDiffMatch_TeamManger_InviteRaid:Enable()
	end
	
	local hasAssist = CorpsUI_2018:Corps_HasAssist()
	if g_CorpsAuthShowList[pos].Assign == 1 then
		if hasAssist and hasAssist == 1 then --副队长不存在则显示：任命；否则：解除
			NoDiffMatch_TeamManger_DecVice:Enable()
		else
			NoDiffMatch_TeamManger_NomVice:Enable()
		end
	end
end

--初始化控件数据
function NoDiffMatch_TeamManger_InitUIData()

	NoDiffMatch_TeamManger_PageHeader_Name:SetText("")

	--战队操作相关按钮
	NoDiffMatch_TeamManger_InviteRaid:Disable() --邀请入团
	NoDiffMatch_TeamManger_NomVice:Disable() --任命副队长
	NoDiffMatch_TeamManger_DecVice:Disable() --解除副队长
	
	--g_BarList
	for i = 1, table.getn(g_BarList) do 
		if g_BarList[i] ~= nil then
			g_BarList[i] = nil
		end
	end
	
	NoDiffMatch_TeamManger_ListClient:Clear()
	
	g_CorpsMemListIndex = -1
end

function NoDiffMatch_TeamManger_InitMemberListData()
	
	--战队名字
	local CorpsName = CorpsUI_2018:GetDetailCorpsInfo("Name")
	if CorpsName ==nil then
		return 0
	end
	local colorname = ScriptGlobal_Format("#{ZBS16_160511_47}" , CorpsName );
	NoDiffMatch_TeamManger_PageHeader_Name:SetText( colorname )
	
	local eqhhsum = CorpsUI_2018:GetDetailCorpsInfo("EqhhSum")
	if eqhhsum ==nil then
		eqhhsum = 0
	end
	local szEqhhTips = ScriptGlobal_Format("#{WCBZ_180128_610}", eqhhsum );
	NoDiffMatch_TeamManger_TopText2:SetText(szEqhhTips)
	
	local nMemCount = CorpsUI_2018:GetCorpsMemberCount()
	for i=1, nMemCount do
		NoDiffMatch_TeamManger_AddMemberItem(i)
	end

	--控制显示操作按钮
	NoDiffMatch_TeamManger_InitOperButtons()

	return 1

end

--增加一个成员
function NoDiffMatch_TeamManger_AddMemberItem( index )

	local post, name, level, menpai, guid, tarmenpai, eqhh = CorpsUI_2018:GetCorpsMemberInfoByIdx(index - 1)
	if post == nil or post <= 0 then
		return --没有数据
	end
	
	local bar = NoDiffMatch_TeamManger_ListClient:AddChild("NoDiffMatch_TeamManger_List_Frame")
	if not bar then
    	return
	end
	
	bar:GetSubItem("NoDiffMatch_TeamManger_List1_Turn"):Hide()
	
	--名字
	bar:GetSubItem("NoDiffMatch_TeamManger_List1_1"):SetText(name)
	
	local leaderButton = bar:GetSubItem("NoDiffMatch_TeamManger_List1_Pic")
	if post == 3 then --队长
		leaderButton:SetProperty("Image", g_CorpsLeaderIcon)
		leaderButton:Show()
	elseif post == 2 then --副队长
		leaderButton:SetProperty("Image", g_CorpsAssistantIcon)
		leaderButton:Show()
	else
		leaderButton:Hide()
	end
			
	bar:GetSubItem("NoDiffMatch_TeamManger_List1_2"):SetText(g_MenPaiNameList[tarmenpai])
	bar:GetSubItem("NoDiffMatch_TeamManger_List1_3"):SetText(tostring(level))
	bar:GetSubItem("NoDiffMatch_TeamManger_List1_4"):SetText(tostring(eqhh))
	
	bar:SetEvent("MouseLClick", string.format("NoDiffMatch_TeamManger_Clicked(%d)", index))
	
	g_BarList[index] = bar
end


function NoDiffMatch_TeamManger_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_TeamManger_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		NoDiffMatch_TeamManger_ResetPos()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "NoDiffMatch_TeamManger") then
			NoDiffMatch_TeamManger_CloseClicked()
		end
		
	elseif(event == "UI_COMMAND") then
	  if tonumber(arg0) == 8927012 then
			g_clientNpcId = -1
			g_ServerNpcId = -1
			
			if Get_XParam_INT(0) > 0 then
				g_ServerNpcId = Get_XParam_INT(0);
			else
				g_ServerNpcId = tonumber(arg1);
			end	
			g_clientNpcId = Target:GetServerId2ClientId(g_ServerNpcId);
		end
		
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		NoDiffMatch_TeamManger_CloseClicked()
		
	elseif(event == "CORPS_INFO_SHOW_2018") then
		
		local pos = CorpsUI_2018:GetCorpsMemberPost()
		if pos == nil then --这是查看别人战队的情况
			return
		end
		
		local stage = CorpsUI_2018:GetZbsStage()
		if stage <= 3 then
			return
		end
		
		--先初始化一下
		NoDiffMatch_TeamManger_InitUIData()
		--填充战队信息
		if 1 == NoDiffMatch_TeamManger_InitMemberListData() then
		    if g_clientNpcId and g_clientNpcId > 0 then
			    this:CareObject(g_clientNpcId, 1, "NoDiffMatch_TeamManger")
			end
			this:Show()
		end

	elseif(event == "CORPS_INFO_LIST_REFRESH_2018")	then
		--刷新操作；重新清除+填充
		if (this:IsVisible() == true) then --如果当前窗体打开着才刷新，否则不刷新UI，更不能弹出来
			NoDiffMatch_TeamManger_InitUIData()
			NoDiffMatch_TeamManger_InitMemberListData()
		end
		
	elseif (event == "CORPS_ALL_UI_CLOSED_2018") then
		NoDiffMatch_TeamManger_CloseClicked()
		
	end

end
--================================================
--关闭
--================================================
function NoDiffMatch_TeamManger_CloseClicked()
   this:Hide();
end


--================================================
--邀请入团
--================================================
function NoDiffMatch_TeamManger_InviteRaid_Clicked()

	local IsLeader = CorpsUI_2018:IsCorpsLeader()
	local IsAssitant = CorpsUI_2018:IsCorpsAssist()
	if (IsLeader == nil or IsLeader <=0) and (IsAssitant==nil or IsAssitant<=0) then
		PushDebugMessage("#{ZBS16_160511_73}")
		return
	end

	if Player:IsInTeam() ~= 1 then
		PushDebugMessage("#{ZBS16_160511_74}")
		return
	end

	if Player:IsLeader() ~= 1 then
		PushDebugMessage("#{ZBS16_160511_75}")
		return
	end

	local iCur = FindFriendDataPool:GetTickCount()
	local pass = iCur - g_TimersInviteTeam
	if pass <= 60*1000 then
		local tips = ScriptGlobal_Format("#{ZBS16_160511_76}", math.floor((60*1000 - pass)/1000) + 1 );
		PushDebugMessage(tips);
		return
	end

	g_TimersInviteTeam = iCur
	
	CorpsUI_2018:AskCorpsMemberJoinTeam()
end


--================================================
--任命逻辑
--================================================
function NoDiffMatch_TeamManger_NomVice_Clicked()

	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	if g_CorpsMemListIndex <= 0 or g_CorpsMemListIndex > g_MaxCropsMemCount  then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end
	
	local post, name, level, menpai, guid, tarmenpai, eqhh = CorpsUI_2018:GetCorpsMemberInfoByIdx(g_CorpsMemListIndex - 1)
	if guid == "" then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	if post == 3 then
		PushDebugMessage("#{ZBS16_160511_87}")
		return
	end

	local nRet = CorpsUI_2018:CorpsOper_AssignAssist(guid)
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
function NoDiffMatch_TeamManger_DecVice_Clicked()
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	if g_CorpsMemListIndex <= 0 or g_CorpsMemListIndex > g_MaxCropsMemCount  then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	local post, name, level, menpai, guid, tarmenpai, eqhh = CorpsUI_2018:GetCorpsMemberInfoByIdx(g_CorpsMemListIndex - 1)
	if guid == "" then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	local nRet = CorpsUI_2018:CorpsOper_CancelAssist(guid)
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


function NoDiffMatch_TeamManger_Clicked(index)
	
	local bar = g_BarList[index]
	if not bar then
    	return
	end
	
	g_CorpsMemListIndex = index
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_TeamManger_ResetPos()
	NoDiffMatch_TeamManger_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_TeamManger_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end



