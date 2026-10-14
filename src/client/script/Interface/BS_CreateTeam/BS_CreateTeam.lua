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
local g_Duanwei ={}

local g_MemDw3 ={0,0,0,0,0,0,}

function BS_CreateTeam_PreLoad()

	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BS_CreateTeam_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BS_CreateTeam_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BS_CreateTeam_Frame:GetProperty("UnifiedYPosition");

end

--初始化控件数据
function BS_CreateTeam_InitUIData()

	BS_CreateTeam_Top_NameInput:SetText("");

	g_Pictures[1] = BS_CreateTeam_List1_Pic;
	g_Pictures[2] = BS_CreateTeam_List2_Pic;
	g_Pictures[3] = BS_CreateTeam_List3_Pic;
	g_Pictures[4] = BS_CreateTeam_List4_Pic;
	g_Pictures[5] = BS_CreateTeam_List5_Pic;
	g_Pictures[6] = BS_CreateTeam_List6_Pic;

	g_Name[1] = BS_CreateTeam_List1_1;
	g_Name[2] = BS_CreateTeam_List2_1;
	g_Name[3] = BS_CreateTeam_List3_1;
	g_Name[4] = BS_CreateTeam_List4_1;
	g_Name[5] = BS_CreateTeam_List5_1;
	g_Name[6] = BS_CreateTeam_List6_1;

	g_Menpai[1] = BS_CreateTeam_List1_2;
	g_Menpai[2] = BS_CreateTeam_List2_2;
	g_Menpai[3] = BS_CreateTeam_List3_2;
	g_Menpai[4] = BS_CreateTeam_List4_2;
	g_Menpai[5] = BS_CreateTeam_List5_2;
	g_Menpai[6] = BS_CreateTeam_List6_2;

	g_Level[1] = BS_CreateTeam_List1_3;
	g_Level[2] = BS_CreateTeam_List2_3;
	g_Level[3] = BS_CreateTeam_List3_3;
	g_Level[4] = BS_CreateTeam_List4_3;
	g_Level[5] = BS_CreateTeam_List5_3;
	g_Level[6] = BS_CreateTeam_List6_3;

	g_Duanwei[1] = BS_CreateTeam_List1_4;
	g_Duanwei[2] = BS_CreateTeam_List2_4;
	g_Duanwei[3] = BS_CreateTeam_List3_4;
	g_Duanwei[4] = BS_CreateTeam_List4_4;
	g_Duanwei[5] = BS_CreateTeam_List5_4;
	g_Duanwei[6] = BS_CreateTeam_List6_4;

	for i=1,6 do
		g_Pictures[i]:Hide()
		g_Name[i]:SetText("")
		g_Menpai[i]:SetText("")
		g_Level[i]:SetText("")
		g_Duanwei[i]:SetText("")
		g_MemDw3[i] = 0
	end

	g_clientNpcId = -1
end

function BS_CreateTeam_InitMemberListData()
	local memCount = DataPool:GetTeamMemberCount()
	-- 如果队伍个数是零, 不显示界面.
	if(memCount <= 0) then
		return 0
	end

	local text = ScriptGlobal_Format("#{BWJH_181102_81}", memCount)
	BS_CreateTeam_Top_Text2:SetText(text)

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

		g_Name[index+1]:SetText(szNick)
		g_Menpai[index+1]:SetText(g_MenPaiNameList[iFamily])
		g_Level[index+1]:SetText(tostring(iLevel))

		local dwText = ScriptGlobal_Format("#{BWJH_181102_84}", g_MemDw3[index+1])
		g_Duanwei[index+1]:SetText(dwText)
	end

	return 1
end

function BS_CreateTeam_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BS_CreateTeam_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		BS_CreateTeam_ResetPos()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "BS_CreateTeam") then
			this:Hide();
		end
	elseif(event == "UI_COMMAND") then
	  if tonumber(arg0) == 8928451 then
	    --先初始化
		BS_CreateTeam_InitUIData()

		local nServerNpcId = Get_XParam_INT(0);
		g_clientNpcId = Target:GetServerId2ClientId(nServerNpcId);
		g_MemDw3[1] = Get_XParam_INT(1)
		g_MemDw3[2] = Get_XParam_INT(2)
		g_MemDw3[3] = Get_XParam_INT(3)
		g_MemDw3[4] = Get_XParam_INT(4)
		g_MemDw3[5] = Get_XParam_INT(5)
		g_MemDw3[6] = Get_XParam_INT(6)

		if 1 == BS_CreateTeam_InitMemberListData() then
    		this:CareObject(g_clientNpcId, 1, "BS_CreateTeam");
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
function BS_CreateTeam_CloseClicked()
   this:Hide();
end

--================================================
--取消
--================================================
function BS_CreateTeam_Cancel_Clicked()
	this:Hide();
end

--================================================
--确定创建
--================================================
function BS_CreateTeam_Accept_Clicked()
	local curDay = tonumber(DataPool:GetServerDayTime());
	local stage = BWDH2018:GetTXbwStage(curDay)
	if stage ~= 1 then
		PushDebugMessage("#{BWJH_181102_14}")
		return
	end

	local szWTeamName = BS_CreateTeam_Top_NameInput:GetText()
	if szWTeamName == "" then
		PushDebugMessage("#{BWJH_181102_55}")
		return
	end
	
	BWDH2018:CreateWTeam(szWTeamName)
	this:Hide()
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function BS_CreateTeam_ResetPos()
	BS_CreateTeam_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BS_CreateTeam_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BS_CreateTeam_DragStarted()
	
end
