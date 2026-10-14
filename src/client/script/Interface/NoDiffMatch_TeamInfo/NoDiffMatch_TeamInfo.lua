-- 战队信息查看
-- 界面的默认位置
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_clientNpcId = -1

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

local g_CorpsLeaderIcon = "set:Union1 image:Union_LeaderIcon_L"
local g_CorpsAssistantIcon = "set:Union1 image:Union_MemberIcon_L"

local g_BarList = {}
local g_SelectIndex = -1

function NoDiffMatch_TeamInfo_PreLoad()

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

function NoDiffMatch_TeamInfo_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_TeamInfo_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_TeamInfo_Frame:GetProperty("UnifiedYPosition");
end

--初始化控件数据
function NoDiffMatch_TeamInfo_InitUIData()

	NoDiffMatch_TeamInfo_part1:SetText("");
	local text = ScriptGlobal_Format("#{ZBS16_160505_05}", 0 );
	NoDiffMatch_TeamInfo_part2:SetText(text);

	g_SelectIndex = -1
	
	--g_BarList
	for i = 1, table.getn(g_BarList) do 
		if g_BarList[i] ~= nil then
			g_BarList[i] = nil
		end
	end
	
	NoDiffMatch_TeamInfo_ListClient:Clear()
end

--!!!reloadscript =NoDiffMatch_TeamInfo
function NoDiffMatch_TeamInfo_InitMemberListData()
	--战队名字
	local CorpsName = CorpsUI_2018:GetDetailCorpsInfo("Name")
	if CorpsName ==nil then
		return 0
	end
	
	local szCorpsNameTips = ScriptGlobal_Format("#{WCBZ_180128_514}", CorpsName );
	NoDiffMatch_TeamInfo_part1:SetText( szCorpsNameTips )
	
	--战队人数
	local CorpsCount = CorpsUI_2018:GetDetailCorpsInfo("MemCount")
	if CorpsCount == nil then
		return 0
	end
	local szMemTips = ScriptGlobal_Format("#{ZBS16_160505_05}", CorpsCount );
	NoDiffMatch_TeamInfo_part2:SetText(szMemTips)

	local eqhhsum = CorpsUI_2018:GetDetailCorpsInfo("EqhhSum")
	if eqhhsum == nil then
		eqhhsum = 0
	end
	local szEqhhTips = ScriptGlobal_Format("#{WCBZ_180128_610}", eqhhsum );
	NoDiffMatch_TeamInfo_BasicInfo2:SetText(szEqhhTips)

	local cropsMemCount = CorpsUI_2018:GetCorpsMemberCount()
	for i=1, cropsMemCount do
		NoDiffMatch_TeamInfo_AddMemberItem( i )
	end

	--控制显示操作按钮
	NoDiffMatch_TeamInfo_ViewInfo:Show()
    NoDiffMatch_TeamInfo_PrivateChat:Show()

	return 1
end

--增加一个成员
function NoDiffMatch_TeamInfo_AddMemberItem( index )

	local post, name, level, menpai, guid, tarmenpai, eqhh = CorpsUI_2018:GetCorpsMemberInfoByIdx(index - 1)
	if post == nil or post <= 0 then
		return --没有数据
	end
	
	local bar = NoDiffMatch_TeamInfo_ListClient:AddChild("NoDiffMatch_TeamInfo_List_Frame")
	if not bar then
    	return
	end
	
	--名字
	bar:GetSubItem("NoDiffMatch_TeamInfo_List1_1"):SetText(name)
	
	local leaderButton = bar:GetSubItem("NoDiffMatch_TeamInfo_List1_Pic")
	if post == 3 then --队长
		leaderButton:SetProperty("Image", g_CorpsLeaderIcon)
		leaderButton:Show()
	elseif post == 2 then --副队长
		leaderButton:SetProperty("Image", g_CorpsAssistantIcon)
		leaderButton:Show()
	else
		leaderButton:Hide()
	end
			
	bar:GetSubItem("NoDiffMatch_TeamInfo_List1_2"):SetText(g_MenPaiNameList[tarmenpai])
	bar:GetSubItem("NoDiffMatch_TeamInfo_List1_3"):SetText(tostring(level))
	bar:GetSubItem("NoDiffMatch_TeamInfo_List1_4"):SetText(tostring(eqhh))
	
	bar:SetEvent("MouseLClick", string.format("NoDiffMatch_TeamInfo_Clicked(%d)", index))
	
	g_BarList[index] = bar
end

function NoDiffMatch_TeamInfo_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_TeamInfo_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		NoDiffMatch_TeamInfo_ResetPos()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "NoDiffMatch_TeamInfo") then
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
		if stage < 4 then
			return
		end
		
		local pos = CorpsUI_2018:GetCorpsMemberPost()
		if pos ~= nil then --这是查看自己战队的情况
			return
		end
			
		--先初始化一下
		NoDiffMatch_TeamInfo_InitUIData()
		--填充战队信息
		if 1 == NoDiffMatch_TeamInfo_InitMemberListData() then
		    if g_clientNpcId and g_clientNpcId > 0 then
			    this:CareObject(g_clientNpcId, 1, "NoDiffMatch_TeamInfo")
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
function NoDiffMatch_TeamInfo_CloseClicked()
   this:Hide();
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_TeamInfo_ResetPos()
	NoDiffMatch_TeamInfo_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_TeamInfo_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function NoDiffMatch_TeamInfo_Clicked(index)

	local bar = g_BarList[index]
	if not bar then
    	return
	end
	
	g_SelectIndex = index
end

function NoDiffMatch_TeamInfo_PrivateChat_Clicked()
	if g_SelectIndex < 0 then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	local post, name, level, menpai, guid, tarmenpai, eqhh = CorpsUI_2018:GetCorpsMemberInfoByIdx(g_SelectIndex - 1)
	if post == nil or post <= 0 then
		PushDebugMessage("#{ZBS16_160511_86}")
		return --没有数据
	end
	
	Talk:ContexMenuTalk(name)
end

function NoDiffMatch_TeamInfo_ViewInfo_Clicked()
	if g_SelectIndex < 0 then
		PushDebugMessage("#{ZBS16_160511_86}")
		return
	end

	local post, name, level, menpai, guid, tarmenpai, eqhh = CorpsUI_2018:GetCorpsMemberInfoByIdx(g_SelectIndex - 1)
	if post == nil or post <= 0 then
		PushDebugMessage("#{ZBS16_160511_86}")
		return --没有数据
	end
	
	if Friend:IsPlayerIsFriend(name) == 1  then
		DataPool:ShowFriendInfo(name)
	else
		DataPool:ShowChatInfo(name)
	end
end


