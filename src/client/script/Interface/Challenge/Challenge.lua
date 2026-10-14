local g_iRoleSel = 0;

local g_Challenge_FakeObject = {};
local g_Challenge_Name   = {};
local g_Challenge_Level  = {};
local g_Challenge_MenPai = {};

local g_Challenge_close = 0

function Challenge_PreLoad()

	-- 打开界面
	this:RegisterEvent("OPEN_CHALLENGE_DLG", true);

	this:RegisterEvent("CLOSE_CHALLENGE_DLG", false);

end

-- 注册onLoad事件
function Challenge_OnLoad()

	g_Challenge_FakeObject[0] = Challenge_FakeObject1;
	g_Challenge_FakeObject[1] = Challenge_FakeObject2;
	g_Challenge_FakeObject[2] = Challenge_FakeObject3;
	g_Challenge_FakeObject[3] = Challenge_FakeObject4;
	g_Challenge_FakeObject[4] = Challenge_FakeObject5;
	g_Challenge_FakeObject[5] = Challenge_FakeObject6;

	g_Challenge_Name[0]   = Challenge_PlayerInfo1_Name;
	g_Challenge_Name[1]   = Challenge_PlayerInfo2_Name;
	g_Challenge_Name[2]   = Challenge_PlayerInfo3_Name;
	g_Challenge_Name[3]   = Challenge_PlayerInfo4_Name;
	g_Challenge_Name[4]   = Challenge_PlayerInfo5_Name;
	g_Challenge_Name[5]   = Challenge_PlayerInfo6_Name;

	g_Challenge_Level[0]  = Challenge_PlayerInfo1_Level;
	g_Challenge_Level[1]  = Challenge_PlayerInfo2_Level;
	g_Challenge_Level[2]  = Challenge_PlayerInfo3_Level;
	g_Challenge_Level[3]  = Challenge_PlayerInfo4_Level;
	g_Challenge_Level[4]  = Challenge_PlayerInfo5_Level;
	g_Challenge_Level[5]  = Challenge_PlayerInfo6_Level;

	g_Challenge_MenPai[0] = Challenge_PlayerInfo1_School;
	g_Challenge_MenPai[1] = Challenge_PlayerInfo2_School;
	g_Challenge_MenPai[2] = Challenge_PlayerInfo3_School;
	g_Challenge_MenPai[3] = Challenge_PlayerInfo4_School;
	g_Challenge_MenPai[4] = Challenge_PlayerInfo5_School;
	g_Challenge_MenPai[5] = Challenge_PlayerInfo6_School;

	Challenge_Die_Icon1:Hide();
	Challenge_Die_Icon2:Hide();
	Challenge_Die_Icon3:Hide();
	Challenge_Die_Icon4:Hide();
	Challenge_Die_Icon5:Hide();
	Challenge_Die_Icon6:Hide();

	Challenge_Downline_Icon1:Hide();
	Challenge_Downline_Icon2:Hide();
	Challenge_Downline_Icon3:Hide();
	Challenge_Downline_Icon4:Hide();
	Challenge_Downline_Icon5:Hide();
	Challenge_Downline_Icon6:Hide();

end

-- OnEvent
function Challenge_OnEvent(event)

	-- 打开界面事件.
	--
	if ( event == "OPEN_CHALLENGE_DLG" ) then

			Challenge_GetChallengeInfo();
			this:Show();
		return;
	end;


	if ( event == "CLOSE_CHALLENGE_DLG" ) then

			this:Hide();
		return;
	end;

end



--得到挑战队伍信息。
function Challenge_GetChallengeInfo()

	local iCount = DataPool:GetChallengeTeamMemberCount();
	local strName = "";
	local strModelName = "";
	local iLevel  = 0;
	local menpai = 0;
	local strMenPai = ""
	local zoneworldId = -1;

	-- 清除挑战信息。
	Challenge_ClearChallengeInfo();

	for i = 0, iCount - 1 do

		-- 得到ui模型信息
		strModelName
		, strName
		, iLevel
		, menpai
		, zoneworldId = DataPool:GetChallengeTeamMemberInfo(i);

		-- 显示模型
		g_Challenge_FakeObject[i]:SetFakeObject(strModelName);

		local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
		if selfZoneWorldID > 0 and selfZoneWorldID ~= zoneworldId then
			local world_name = DataPool:GetServerName(tonumber(zoneworldId))
			strName = strName.."@"..world_name
		end
		-- 显示名字
		g_Challenge_Name[i]:SetText(strName);


		-- 显示等级
		g_Challenge_Level[i]:SetText(tostring(iLevel));

		-- 得到门派名称.
		if(0 == menpai) then
			strMenPai = "少林";

		elseif(1 == menpai) then
			strMenPai = "明教";

		elseif(2 == menpai) then
			strMenPai = "丐帮";

		elseif(3 == menpai) then
			strMenPai = "武当";

		elseif(4 == menpai) then
			strMenPai = "峨嵋";

		elseif(5 == menpai) then
			strMenPai = "星宿";

		elseif(6 == menpai) then
			strMenPai = "天龙";

		elseif(7 == menpai) then
			strMenPai = "天山";

		elseif(8 == menpai) then
			strMenPai = "逍遥";

		elseif(10 == menpai) then
			strMenPai = "慕容";

		elseif(11 == menpai) then
			strMenPai = "唐门";
			
		elseif(12 == menpai) then
			strMenPai = "鬼谷";
		elseif(13 == menpai) then
			strMenPai = "#{XQ_MP_15}"; --桃花岛
		elseif(14 == menpai) then
			strMenPai = "#{XMPHM_210604_01}"; 
		elseif(15 == menpai) then--menpai15 mptodo
			strMenPai = "#{GMGameInterface_Script_DataPool_Info_ERenGu}"; 
		else
			strMenPai = "无门派";
		end

		-- 显示门派
		g_Challenge_MenPai[i]:SetText(strMenPai);

	end;

end



--得到挑战队伍信息。
function Challenge_ClearChallengeInfo()

	g_Challenge_FakeObject[0]:SetFakeObject("");
	g_Challenge_FakeObject[1]:SetFakeObject("");
	g_Challenge_FakeObject[2]:SetFakeObject("");
	g_Challenge_FakeObject[3]:SetFakeObject("");
	g_Challenge_FakeObject[4]:SetFakeObject("");
	g_Challenge_FakeObject[5]:SetFakeObject("");

	g_Challenge_Name[0]:SetText("");
	g_Challenge_Name[1]:SetText("");
	g_Challenge_Name[2]:SetText("");
	g_Challenge_Name[3]:SetText("");
	g_Challenge_Name[4]:SetText("");
	g_Challenge_Name[5]:SetText("");

	g_Challenge_Level[0]:SetText("");
	g_Challenge_Level[1]:SetText("");
	g_Challenge_Level[2]:SetText("");
	g_Challenge_Level[3]:SetText("");
	g_Challenge_Level[4]:SetText("");
	g_Challenge_Level[5]:SetText("");

	g_Challenge_MenPai[0]:SetText("");
	g_Challenge_MenPai[1]:SetText("");
	g_Challenge_MenPai[2]:SetText("");
	g_Challenge_MenPai[3]:SetText("");
	g_Challenge_MenPai[4]:SetText("");
	g_Challenge_MenPai[5]:SetText("");

end;


-- 同意挑战
function Challenge_Yes_Click()

	DataPool:RespondChallenge(1);
	g_Challenge_close = 1
	this:Hide();
end;


-- 拒绝挑战。
function Challenge_No_Click()
	if g_Challenge_close == 1 then
		g_Challenge_close = 0
		return
	end
	if g_Challenge_close == 0 then
		DataPool:RespondChallenge(0);
		this:Hide();
	end
end;

