-- 战队组建UI
-- 界面的默认位置
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_clientNpcId = -1

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
	[9]  ="",
	[10] ="#{XQ_MP_10}",
	[11] ="#{XMPTM_130123_05}",
	[12] ="#{XMPGG_160524_02}", -- 鬼谷
	[13] ="#{XQ_MP_15}", -- 桃花岛
	[14] ="#{XMPHM_210604_01}",
	[15] ="#{GMGameInterface_Script_DataPool_Info_ERenGu}",--menpai15 mptodo
}


local g_Pictures ={}
local g_Name ={}
local g_Menpai ={}
local g_Level ={}
local g_Eqhh ={}


function BT_CreateTeam_PreLoad()

	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BT_CreateTeam_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BT_CreateTeam_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BT_CreateTeam_Frame:GetProperty("UnifiedYPosition");

end

--初始化控件数据
function BT_CreateTeam_InitUIData()

	BT_CreateTeam_Top_NameInput:SetText("");

	g_Pictures[1] = BT_CreateTeam_List1_Pic;
	g_Pictures[2] = BT_CreateTeam_List2_Pic;
	g_Pictures[3] = BT_CreateTeam_List3_Pic;
	g_Pictures[4] = BT_CreateTeam_List4_Pic;
	g_Pictures[5] = BT_CreateTeam_List5_Pic;
	g_Pictures[6] = BT_CreateTeam_List6_Pic;

	g_Name[1] = BT_CreateTeam_List1_1;
	g_Name[2] = BT_CreateTeam_List2_1;
	g_Name[3] = BT_CreateTeam_List3_1;
	g_Name[4] = BT_CreateTeam_List4_1;
	g_Name[5] = BT_CreateTeam_List5_1;
	g_Name[6] = BT_CreateTeam_List6_1;

	g_Menpai[1] = BT_CreateTeam_List1_2;
	g_Menpai[2] = BT_CreateTeam_List2_2;
	g_Menpai[3] = BT_CreateTeam_List3_2;
	g_Menpai[4] = BT_CreateTeam_List4_2;
	g_Menpai[5] = BT_CreateTeam_List5_2;
	g_Menpai[6] = BT_CreateTeam_List6_2;

	g_Level[1] = BT_CreateTeam_List1_3;
	g_Level[2] = BT_CreateTeam_List2_3;
	g_Level[3] = BT_CreateTeam_List3_3;
	g_Level[4] = BT_CreateTeam_List4_3;
	g_Level[5] = BT_CreateTeam_List5_3;
	g_Level[6] = BT_CreateTeam_List6_3;

	g_Eqhh[1] = BT_CreateTeam_List1_4;
	g_Eqhh[2] = BT_CreateTeam_List2_4;
	g_Eqhh[3] = BT_CreateTeam_List3_4;
	g_Eqhh[4] = BT_CreateTeam_List4_4;
	g_Eqhh[5] = BT_CreateTeam_List5_4;
	g_Eqhh[6] = BT_CreateTeam_List6_4;

	for i=1,6 do
		g_Pictures[i]:Hide()
		g_Name[i]:SetText("")
		g_Menpai[i]:SetText("")
		g_Level[i]:SetText("")
		g_Eqhh[i]:SetText("")
	end

	g_clientNpcId = -1
end

function BT_CreateTeam_InitMemberListData()
	local memCount = DataPool:GetTeamMemberCount()
	-- 如果队伍个数是零, 不显示界面.
	if(memCount <= 0) then
		return 0
	end

	local text = ScriptGlobal_Format("#{DFSZ_190613_167}", memCount)
	BT_CreateTeam_Top_Text2:SetText(text)

	local szNick;		-- 昵称
	local iFamily;	-- 门派
	local iLevel;	  -- 等级
	local bDeadlink;
	local bDead;
	local bSex;
    local sZoneWorldID  --- 服务器名
	local iFightScore
	local szGuildName


	for index = 0, memCount - 1 do
		-- 得到队员的详细信息
		szNick
		,iFamily
		,iLevel
		,bDead
		,bDeadlink
		,bSex
		,sZoneWorldID
		,iFightScore
		,szGuildName
		= DataPool:GetTeamMemInfoByIndex( index );

		if index == 0 then
			g_Pictures[index+1]:Show()
		else
			g_Pictures[index+1]:Hide()
		end

		g_Name[index+1]:SetText( szNick )
		g_Menpai[index+1]:SetText( g_MenPaiNameList[iFamily] )
		g_Level[index+1]:SetText( tostring(iLevel) )
		g_Eqhh[index+1]:SetText( tostring(Get_XParam_INT(index + 1)) )
	end

	return 1
end

function BT_CreateTeam_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BT_CreateTeam_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		BT_CreateTeam_ResetPos()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "BT_CreateTeam") then
			this:Hide();
		end
	elseif(event == "UI_COMMAND") then
	  if tonumber(arg0) == 2915231 then
	    --先初始化
		BT_CreateTeam_InitUIData()

		local nServerNpcId = Get_XParam_INT(0);
		g_clientNpcId = Target:GetServerId2ClientId(nServerNpcId);

		if 1 == BT_CreateTeam_InitMemberListData() then
    		this:CareObject(g_clientNpcId, 1, "BT_CreateTeam");
    		this:Show();
        end
	  end
	elseif(event == "HIDE_ON_SCENE_TRANSED")	 then
		this:Hide();
	end

end
--================================================
--关闭
--================================================
function BT_CreateTeam_CloseClicked()
   this:Hide();
end

--================================================
--取消
--================================================
function BT_CreateTeam_Cancel_Clicked()
	this:Hide();
end

--================================================
--确定创建
--================================================
function BT_CreateTeam_Accept_Clicked()
	local szWTeamName = BT_CreateTeam_Top_NameInput:GetText()
	if szWTeamName == "" then
		PushDebugMessage("#{DFSZ_190613_173}")
		return
	end
	
	DFS:CreateWTeam(szWTeamName)
	this:Hide()
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function BT_CreateTeam_ResetPos()
	BT_CreateTeam_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BT_CreateTeam_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

