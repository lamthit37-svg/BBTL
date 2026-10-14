
local Reputation_Progress1={};
local Reputation_Progress2={};
local Reputation_Progress3={};
local Reputation_CurLevel = {};
local Reputation_Text		= {};
local Reputation_Name = {};
local Reputation_TextName ={};
local Reputation_Back ={};
local Reputation_RelationType ={};

local Reputation_Page = 0;

-- 界面的默认相对位置
local g_Reputation_Frame_UnifiedXPosition;
local g_Reputation_Frame_UnifiedYPosition;

function Reputation_PreLoad()

	this:RegisterEvent("OPEN_WINDOW", true);

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end


function Reputation_OnLoad()

	Reputation_TextName = { "少林",
							"明教",
							"丐帮",
							"武当",
							"峨嵋",
							"星宿",
							"天龙",
							"天山",
							"逍遥",
							"大宋朝廷",
							"大宋端王府",
							"大宋民间",
							"大辽朝廷",
							"大辽民间",
							"大理",
							"西夏",
							"番邦",
							"莽盖",
							"遗民",
							"流放者",
							"白苗",
							"黑苗",
							"修罗",
							"山越女祭司",
							"山越男护法",
							"鳄鱼帮",
							"野兽",
							"绿林",
							"妖魔",
							"箱子",
							"竞技场宝箱",
							"慕容",
							"钧天",
							"罗浮",
							"潮京",
							"可攻击城门",
							"唐门",
							"38",
							"39",
							"40",
							"41",
							"42",
							"43",
							"44",
							"45",
							"46",
							"47",
							"48",
							"49",
							"50",
							"51",
							"52",
							"鬼谷", 
							"桃花岛",
							"绝情谷",
							"56",
							"57",
							"恶人谷",--menpai15 mptodo reputationtable
							};

	Reputation_Progress1[ 1 ] = Reputation_Value_Menpai1_Value_Pic1;
	Reputation_Progress1[ 2 ] = Reputation_Value_Menpai2_Value_Pic1;
	Reputation_Progress1[ 3 ] = Reputation_Value_Menpai3_Value_Pic1;
	Reputation_Progress1[ 4 ] = Reputation_Value_Menpai4_Value_Pic1;
	Reputation_Progress1[ 5 ] = Reputation_Value_Menpai5_Value_Pic1;
	Reputation_Progress1[ 6 ] = Reputation_Value_Menpai6_Value_Pic1;
	Reputation_Progress1[ 7 ] = Reputation_Value_Menpai7_Value_Pic1;
	Reputation_Progress1[ 8 ] = Reputation_Value_Menpai8_Value_Pic1;
	Reputation_Progress1[ 9 ] = Reputation_Value_Menpai9_Value_Pic1;
	Reputation_Progress1[ 10 ] = Reputation_Value_Menpai10_Value_Pic1;
	Reputation_Progress1[ 11 ] = Reputation_Value_Menpai11_Value_Pic1;
	Reputation_Progress1[ 12 ] = Reputation_Value_Menpai12_Value_Pic1;
	Reputation_Progress1[ 13 ] = Reputation_Value_Menpai13_Value_Pic1;
	Reputation_Progress1[ 14 ] = Reputation_Value_Menpai14_Value_Pic1;
	Reputation_Progress1[ 15 ] = Reputation_Value_Menpai15_Value_Pic1;--menpai15 mptodo
	
	Reputation_Progress2[ 1 ] = Reputation_Value_Menpai1_Value_Pic2;
	Reputation_Progress2[ 2 ] = Reputation_Value_Menpai2_Value_Pic2;
	Reputation_Progress2[ 3 ] = Reputation_Value_Menpai3_Value_Pic2;
	Reputation_Progress2[ 4 ] = Reputation_Value_Menpai4_Value_Pic2;
	Reputation_Progress2[ 5 ] = Reputation_Value_Menpai5_Value_Pic2;
	Reputation_Progress2[ 6 ] = Reputation_Value_Menpai6_Value_Pic2;
	Reputation_Progress2[ 7 ] = Reputation_Value_Menpai7_Value_Pic2;
	Reputation_Progress2[ 8 ] = Reputation_Value_Menpai8_Value_Pic2;
	Reputation_Progress2[ 9 ] = Reputation_Value_Menpai9_Value_Pic2;
	Reputation_Progress2[ 10 ] = Reputation_Value_Menpai10_Value_Pic2;
	Reputation_Progress2[ 11 ] = Reputation_Value_Menpai11_Value_Pic2;
	Reputation_Progress2[ 12 ] = Reputation_Value_Menpai12_Value_Pic2;
	Reputation_Progress2[ 13 ] = Reputation_Value_Menpai13_Value_Pic2;
	Reputation_Progress2[ 14 ] = Reputation_Value_Menpai14_Value_Pic2;
	Reputation_Progress2[ 15 ] = Reputation_Value_Menpai15_Value_Pic2;--menpai15 mptodo
	
	Reputation_Progress3[ 1 ] = Reputation_Value_Menpai1_Value_Pic3;
	Reputation_Progress3[ 2 ] = Reputation_Value_Menpai2_Value_Pic3;
	Reputation_Progress3[ 3 ] = Reputation_Value_Menpai3_Value_Pic3;
	Reputation_Progress3[ 4 ] = Reputation_Value_Menpai4_Value_Pic3;
	Reputation_Progress3[ 5 ] = Reputation_Value_Menpai5_Value_Pic3;
	Reputation_Progress3[ 6 ] = Reputation_Value_Menpai6_Value_Pic3;
	Reputation_Progress3[ 7 ] = Reputation_Value_Menpai7_Value_Pic3;
	Reputation_Progress3[ 8 ] = Reputation_Value_Menpai8_Value_Pic3;
	Reputation_Progress3[ 9 ] = Reputation_Value_Menpai9_Value_Pic3;
	Reputation_Progress3[ 10 ] = Reputation_Value_Menpai10_Value_Pic3;
	Reputation_Progress3[ 11 ] = Reputation_Value_Menpai11_Value_Pic3;
	Reputation_Progress3[ 12 ] = Reputation_Value_Menpai12_Value_Pic3;
	Reputation_Progress3[ 13 ] = Reputation_Value_Menpai13_Value_Pic3;
	Reputation_Progress3[ 14 ] = Reputation_Value_Menpai14_Value_Pic3;
	Reputation_Progress3[ 15 ] = Reputation_Value_Menpai15_Value_Pic3;--menpai15 mptodo

	Reputation_CurLevel[ 1 ] = Reputation_Value_Menpai1_CurrentLevel;
	Reputation_CurLevel[ 2 ] = Reputation_Value_Menpai2_CurrentLevel;
	Reputation_CurLevel[ 3 ] = Reputation_Value_Menpai3_CurrentLevel;
	Reputation_CurLevel[ 4 ] = Reputation_Value_Menpai4_CurrentLevel;
	Reputation_CurLevel[ 5 ] = Reputation_Value_Menpai5_CurrentLevel;
	Reputation_CurLevel[ 6 ] = Reputation_Value_Menpai6_CurrentLevel;
	Reputation_CurLevel[ 7 ] = Reputation_Value_Menpai7_CurrentLevel;
	Reputation_CurLevel[ 8 ] = Reputation_Value_Menpai8_CurrentLevel;
	Reputation_CurLevel[ 9 ] = Reputation_Value_Menpai9_CurrentLevel;
	Reputation_CurLevel[ 10 ] = Reputation_Value_Menpai10_CurrentLevel;
	Reputation_CurLevel[ 11 ] = Reputation_Value_Menpai11_CurrentLevel;
	Reputation_CurLevel[ 12 ] = Reputation_Value_Menpai12_CurrentLevel;
	Reputation_CurLevel[ 13 ] = Reputation_Value_Menpai13_CurrentLevel;
	Reputation_CurLevel[ 14 ] = Reputation_Value_Menpai14_CurrentLevel;
	Reputation_CurLevel[ 15 ] = Reputation_Value_Menpai15_CurrentLevel;--menpai15 mptodo

	Reputation_Text[ 1 ] = Reputation_Value_Menpai1_Value_Number;
	Reputation_Text[ 2 ] = Reputation_Value_Menpai2_Value_Number;
	Reputation_Text[ 3 ] = Reputation_Value_Menpai3_Value_Number;
	Reputation_Text[ 4 ] = Reputation_Value_Menpai4_Value_Number;
	Reputation_Text[ 5 ] = Reputation_Value_Menpai5_Value_Number;
	Reputation_Text[ 6 ] = Reputation_Value_Menpai6_Value_Number;
	Reputation_Text[ 7 ] = Reputation_Value_Menpai7_Value_Number;
	Reputation_Text[ 8 ] = Reputation_Value_Menpai8_Value_Number;
	Reputation_Text[ 9 ] = Reputation_Value_Menpai9_Value_Number;
	Reputation_Text[ 10 ] = Reputation_Value_Menpai10_Value_Number;
	Reputation_Text[ 11 ] = Reputation_Value_Menpai11_Value_Number;
	Reputation_Text[ 12 ] = Reputation_Value_Menpai12_Value_Number;
	Reputation_Text[ 13 ] = Reputation_Value_Menpai13_Value_Number;
	Reputation_Text[ 14 ] = Reputation_Value_Menpai14_Value_Number;
	Reputation_Text[ 15 ] = Reputation_Value_Menpai15_Value_Number;--menpai15 mptodo

	Reputation_Name[ 1 ] = Reputation_Value_Menpai1_Name;
	Reputation_Name[ 2 ] = Reputation_Value_Menpai2_Name;
	Reputation_Name[ 3 ] = Reputation_Value_Menpai3_Name;
	Reputation_Name[ 4 ] = Reputation_Value_Menpai4_Name;
	Reputation_Name[ 5 ] = Reputation_Value_Menpai5_Name;
	Reputation_Name[ 6 ] = Reputation_Value_Menpai6_Name;
	Reputation_Name[ 7 ] = Reputation_Value_Menpai7_Name;
	Reputation_Name[ 8 ] = Reputation_Value_Menpai8_Name;
	Reputation_Name[ 9 ] = Reputation_Value_Menpai9_Name;
	Reputation_Name[ 10 ] = Reputation_Value_Menpai10_Name;
	Reputation_Name[ 11 ] = Reputation_Value_Menpai11_Name;
	Reputation_Name[ 12 ] = Reputation_Value_Menpai12_Name;
	Reputation_Name[ 13 ] = Reputation_Value_Menpai13_Name;
	Reputation_Name[ 14 ] = Reputation_Value_Menpai14_Name;
	Reputation_Name[ 15 ] = Reputation_Value_Menpai15_Name;--menpai15 mptodo

	Reputation_Back[ 1 ] = Reputation_Value_Menpai1_Back;
	Reputation_Back[ 2 ] = Reputation_Value_Menpai2_Back;
	Reputation_Back[ 3 ] = Reputation_Value_Menpai3_Back;
	Reputation_Back[ 4 ] = Reputation_Value_Menpai4_Back;
	Reputation_Back[ 5 ] = Reputation_Value_Menpai5_Back
	Reputation_Back[ 6 ] = Reputation_Value_Menpai6_Back;
	Reputation_Back[ 7 ] = Reputation_Value_Menpai7_Back;
	Reputation_Back[ 8 ] = Reputation_Value_Menpai8_Back;
	Reputation_Back[ 9 ] = Reputation_Value_Menpai9_Back;
	Reputation_Back[ 10 ] = Reputation_Value_Menpai10_Back;
	Reputation_Back[ 11 ] = Reputation_Value_Menpai11_Back;
	Reputation_Back[ 12 ] = Reputation_Value_Menpai12_Back;
	Reputation_Back[ 13 ] = Reputation_Value_Menpai13_Back;
	Reputation_Back[ 14 ] = Reputation_Value_Menpai14_Back;
	Reputation_Back[ 15 ] = Reputation_Value_Menpai15_Back;--menpai15 mptodo

	Reputation_RelationType[ 1 ] = Reputation_Value_Menpai1_Relation;
	Reputation_RelationType[ 2 ] = Reputation_Value_Menpai2_Relation;
	Reputation_RelationType[ 3 ] = Reputation_Value_Menpai3_Relation;
	Reputation_RelationType[ 4 ] = Reputation_Value_Menpai4_Relation;
	Reputation_RelationType[ 5 ] = Reputation_Value_Menpai5_Relation
	Reputation_RelationType[ 6 ] = Reputation_Value_Menpai6_Relation;
	Reputation_RelationType[ 7 ] = Reputation_Value_Menpai7_Relation;
	Reputation_RelationType[ 8 ] = Reputation_Value_Menpai8_Relation;
	Reputation_RelationType[ 9 ] = Reputation_Value_Menpai9_Relation;
	Reputation_RelationType[ 10 ] = Reputation_Value_Menpai10_Relation;
	Reputation_RelationType[ 11 ] = Reputation_Value_Menpai11_Relation;
	Reputation_RelationType[ 12 ] = Reputation_Value_Menpai12_Relation;
	Reputation_RelationType[ 13 ] = Reputation_Value_Menpai13_Relation;
	Reputation_RelationType[ 14 ] = Reputation_Value_Menpai14_Relation;
	Reputation_RelationType[ 15 ] = Reputation_Value_Menpai15_Relation;--menpai15 mptodo

	-- 保存界面的默认相对位置
	g_Reputation_Frame_UnifiedXPosition	= Reputation_Frame : GetProperty("UnifiedXPosition");
	g_Reputation_Frame_UnifiedYPosition	= Reputation_Frame : GetProperty("UnifiedYPosition");

end

-- OnEvent

function Reputation_OnEvent(event)
	if( event =="OPEN_WINDOW" ) then

		if( arg0 == "Reputation" ) then

			Reputation_UpdateData();
			this:Show();
		end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		Reputation_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		Reputation_Frame_On_ResetPos()
	end
end

function Reputation_UpdateData()

	local i = 1;
	for i = 1, 15 do--menpai15 mptodo
		Reputation_Back[ i ]:Hide();
	end
	if( Reputation_Page == 0 ) then
		for i = 1, 9 do
			Reputation_Update( i, i );
		end
		Reputation_Update( 10, 32 );	--慕容需要特殊处理，势力ID为32
		
		local selfzoneid = DataPool:GetSelfZoneWorldID()
		if Lua_IsCJDingZhiMenPaiOpen(selfzoneid, 11) == 1 then
			Reputation_Update( 11, 37 );	--唐门需要特殊处理，势力ID为37
		end
		if Lua_IsCJDingZhiMenPaiOpen(selfzoneid, 12) == 1 then
			Reputation_Update( 12, 53 );	--鬼谷需要特殊处理，势力ID为53
		end
		if Lua_IsCJDingZhiMenPaiOpen(selfzoneid, 13) == 1 then
			Reputation_Update( 13, 54 );	
		end
		if Lua_IsCJDingZhiMenPaiOpen(selfzoneid, 14) == 1 then
			Reputation_Update( 14, 55 );
		end
		if Lua_IsCJDingZhiMenPaiOpen(selfzoneid, 15) == 1 then
			Reputation_Update( 15, 58 );	--menpai15 mptodo reputationtable id
		end
	elseif( Reputation_Page == 1 ) then
		Reputation_Update( 1, 10 );
		Reputation_Update( 2, 13 );
		Reputation_Update( 3, 15 );
		Reputation_Update( 4, 16 );
		Reputation_Update( 5, 17 );
	elseif( Reputation_Page == 2 ) then
		Reputation_Update( 1, 19 );
		Reputation_Update( 2, 20 );
		Reputation_Update( 3, 26 );
	end
end

function Reputation_Update( nIndex, nTragetID )
	local nReputation = Player:GetReputation( nTragetID );
	local nCurrentNumber;		--这一级的当前值
	local nCurrentMaxNumber;--这一级的最大值
	local strTypeMax;
	local nType = 1;
	if( nReputation < -550000 ) then
		nCurrentNumber = -550000 - nReputation ;
		nCurrentMaxNumber = 450000;
		strTypeMax = "痛恨";
	elseif( nReputation < -320000 ) then
		nCurrentNumber = -320000 - nReputation ;
		nCurrentMaxNumber = 230000;
		strTypeMax = "憎恶";
	elseif( nReputation < -160000 ) then
		nCurrentNumber = -160000 - nReputation ;
		nCurrentMaxNumber = 160000;
		strTypeMax = "对立";
	elseif( nReputation < -60000 ) then
		nCurrentNumber = -60000 - nReputation ;
		nCurrentMaxNumber = 100000;
		strTypeMax = "敌意";
		nType = 2;
	elseif( nReputation < 0 ) then
		nCurrentNumber = -nReputation;
		nCurrentMaxNumber = 60000;
		strTypeMax = "反感";
		nType = 2;
	elseif( nReputation < 60000 ) then
		nCurrentNumber = nReputation;
		nCurrentMaxNumber = 60000;
		strTypeMax = "漠视";
		nType = 2;
	elseif( nReputation < 160000 ) then
		nCurrentNumber = nReputation - 60000;
		nCurrentMaxNumber = 100000;
		strTypeMax = "好意";
		nType = 2;
	elseif( nReputation < 320000 ) then
		nCurrentNumber = nReputation - 160000;
		nCurrentMaxNumber = 160000;
		strTypeMax = "友善";
		nType = 2;
	elseif( nReputation < 550000 ) then
		nCurrentNumber = nReputation - 320000;
		nCurrentMaxNumber = 230000;
		strTypeMax = "尊敬";
		nType = 3;
	elseif( nReputation < 1000000 ) then
		nCurrentNumber = nReputation - 550000;
		nCurrentMaxNumber = 450000;
		strTypeMax = "信赖";
		nType = 3;
	else
		nCurrentNumber = 0;
		nCurrentMaxNumber = 0;
		strTypeMax = "敬爱";
		nType = 3;
	end
	Reputation_Back[ nIndex ]:Show();

	Reputation_Progress1[ nIndex ]:Hide();
	Reputation_Progress2[ nIndex ]:Hide();
	Reputation_Progress3[ nIndex ]:Hide();
	Reputation_CurLevel[ nIndex ]:SetText( "当前声望：".. strTypeMax );
	Reputation_Text[ nIndex ]:SetText( tostring( nCurrentNumber ).."/"..tostring( nCurrentMaxNumber ) );
	Reputation_Name[ nIndex ]:SetText( Reputation_TextName[ nTragetID ] );

	if( nType == 1 ) then
		Reputation_RelationType[ nIndex ]:SetProperty( "SetCurrentImage", "Enemy" );
		Reputation_Progress1[ nIndex ]:SetProgress( nCurrentNumber, nCurrentMaxNumber );
		Reputation_Progress1[ nIndex ]:Show();
	elseif( nType == 2 ) then
		Reputation_RelationType[ nIndex ]:SetProperty( "SetCurrentImage", "Normal" );
		Reputation_Progress2[ nIndex ]:SetProgress( nCurrentNumber, nCurrentMaxNumber );
		Reputation_Progress2[ nIndex ]:Show();
	elseif( nType == 3 ) then
		Reputation_RelationType[ nIndex ]:SetProperty( "SetCurrentImage", "Friend" );
		Reputation_Progress3[ nIndex ]:SetProgress( nCurrentNumber, nCurrentMaxNumber );
		Reputation_Progress3[ nIndex ]:Show();
	end

end

function Reputation_OnPageClick( nIndex )
	Reputation_Page = nIndex;
	Reputation_UpdateData();
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Reputation_Frame_On_ResetPos()

	Reputation_Frame : SetProperty("UnifiedXPosition", g_Reputation_Frame_UnifiedXPosition);
	Reputation_Frame : SetProperty("UnifiedYPosition", g_Reputation_Frame_UnifiedYPosition);

end
