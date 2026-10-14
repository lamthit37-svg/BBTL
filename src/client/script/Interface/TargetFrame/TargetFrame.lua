local strMenPaiName =
{
	"少林",
	"明教",
	"丐帮",
	"武当",
	"峨嵋",
	"星宿",
	"天龙",
	"天山",
	"逍遥",
	"新手",
	--10
	"慕容",
	"唐门", 
	"大宋",--14
	"大宋",
	"大宋",
	"大辽",
	"大辽",
	"大理",
	"西夏",
	"番邦",
	--20
	"莽盖",
	"遗民",
	"狼人",
	"白苗",
	"黑苗",
	"修罗",
	"越女",
	"越男",
	"鳄神",
	"野兽",
	--30
	"绿林",
	"妖魔",
	"箱子",
	"宝箱", --竞技场宝箱
	"",
	"",
	"",
	"",
	"子女",
	"",
	--40
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"千秋殿",
	"不归林",
	"无涯海",
	--50
	"炎罗天",
	"玉皇山",
	"西夏",
	"鬼谷",
	"桃花岛",
	"绝情谷",
	"",
	"",
	"恶人谷",--menpai15 这个表得和reputationtable.txt对应上,不然NPC的显示会出问题
	"大宋",
};


	--女神称号id
	local nNvShenTitleID = 289
	local nNvShenTitleIDEx = 290

local g_NowZMBossHp = 1
local g_NowZMBossHpCoe = 1
local g_NowWDBossHp = 1
local g_ERenGuTargetUI = {}
local g_ERenGuSHTargetUI = {}
local g_ERenGuSHLPTargetUI = {}

function TargetFrame_PreLoad()
	this:RegisterEvent("MAINTARGET_CHANGED",true)
	this:RegisterEvent("UNIT_HP",false);
	this:RegisterEvent("UNIT_MP",false);
	this:RegisterEvent("UNIT_TRANSFER_ENERGY",false);
	this:RegisterEvent("UNIT_RAGE",false);
	this:RegisterEvent("UNIT_LEVEL",false);
	this:RegisterEvent("UNIT_RELATIVE",false);
	this:RegisterEvent("MAINTARGET_OPEN",true)
	this:RegisterEvent("TARGETFRAME_GETTUJIAN",false);
	this:RegisterEvent("UI_SHOW_2DHEAD",false)	--显示2D头像
	this:RegisterEvent("MAINTARGET_BUFF_REFRESH",false);
	this:RegisterEvent("UPDATE_FAKE_OBJECT",false)
	this:RegisterEvent("NVSHEN_UI_SHOW_2DHEAD",false)
	this:RegisterEvent("UNIT_ENG",false);			-- 注册能量
	this:RegisterEvent("UNIT_MAX_ENG",false);			-- 注册能量
	this:RegisterEvent("UPDATE_YWBOSS_INFO",false);
	this:RegisterEvent("UPDATE_XIAKE_BOSS_INFO",false);
	this:RegisterEvent("UI_COMMAND");			
	
	this:RegisterEvent("UNIT_HSANDBOX_HP",false);			-- 注册沙盒血量
	this:RegisterEvent("UNIT_HSANDBOX_MAX_HP",false);			-- 注册沙盒最大血量
end

local g_TargetID = -1

function TargetFrame_OnLoad()
		g_ERenGuTargetUI = {
	{impactId = 9101, UI=TargetFrame_ERenSoulHit1, brightImage="set:CommonFrame39 image:ERenSoulHitTianDis",grayImage="set:CommonFrame39 image:ERenSoulHitTian",grayToolTip="#{ERJN_240902_10}",brightToolTip="#{ERJN_240902_07}"},
	{impactId = 9094, UI=TargetFrame_ERenSoulHit2, brightImage="set:CommonFrame39 image:ERenSoulHitDiDis",grayImage="set:CommonFrame39 image:ERenSoulHitDi",grayToolTip="#{ERJN_240902_11}",brightToolTip="#{ERJN_240902_08}"},
	{impactId = 9099, UI=TargetFrame_ERenSoulHit3, brightImage="set:CommonFrame39 image:ERenSoulHitMingDis",grayImage="set:CommonFrame39 image:ERenSoulHitMing",grayToolTip="#{ERJN_240902_12}",brightToolTip="#{ERJN_240902_09}"},
	{impactId = 9113, UI=TargetFrame_ERenSoulHit4, brightImage="set:UIIcons image:LeaderOpening",brightToolTip="#{ERJN_240902_13}"},
	{impactId = 9114, UI=TargetFrame_ERenSoulHit4, brightImage="set:CommonStaticImage image:MinimapZoomOut_Hover",brightToolTip="#{ERJN_240902_14}"},
	}

	for x=1,4 do   	
		g_ERenGuTargetUI[x].UI:Hide()		
	end

end

function TargetFrame_OnEvent(event)

--	local ct = Target:GetData("CHAR_TYPE");
	-- 是否玩家的角色
--	if (ct == 0 or ct == 1) then
		-- 是否有DIY头像
--		local styleId;
--		if (Target:IsTargetTeamMember() ~= 0) then
--			styleId = Target:TargetFrame_Update_DIYFrame_Team();
--		else
--			styleId = Target:GetData("DIYFRAME");
--		end
--		if styleId > 0 then
--			this:Hide();
--			return;
--		end;
--	end;

	local nMenpai = Target:GetMenPai();
	if 13 == nMenpai then
		TargetFrame_SP:Hide()
		TargetFrame_GQ:Show()
	else
		TargetFrame_SP:Show()
		TargetFrame_GQ:Hide()
	end

	if 1 == XRZPVP:IsInBattleSceneAndTransfer_TargetID() then
		TargetFrame_HPHDSandBoxHP:Show()
		TargetFrame_HPHDSandBoxHPBK:Show()
	else
		TargetFrame_HPHDSandBoxHP:Hide()
		TargetFrame_HPHDSandBoxHPBK:Hide()
	end

	if ( event == "MAINTARGET_OPEN" ) then
		Shoujitujian_Icon:Hide()
		Shoujitujian_Animate:Hide()
		TargetFrame_Update_Buff()
		if Target:IsTransferMode() == 1 then
			TargetFrame_MP:Hide()
			TargetFrame_TP:Show()
		else
			TargetFrame_MP:Show()
			TargetFrame_TP:Hide()
		end

		if 1 == Target:IsTargetRaidMember() then
			TargetFrame_DataBack:Show()
			TargetFrame_DataBack2:Hide()
			TargetFrame_Update_Name_Raid()
			TargetFrame_Update_HP_Raid()
			TargetFrame_Update_MP_Raid()
			TargetFrame_Update_TP_Raid()
			TargetFrame_Update_Rage_Raid()
			TargetFrame_Update_Eng_Raid()
			TargetFrame_Update_Level_Raid()
		else
			
			TargetFrame_DataBack:Show();
			TargetFrame_DataBack2:Hide();
			TargetFrame_Update_Name_Team();
			TargetFrame_Update_HP_Team();
			TargetFrame_Update_MP_Team();
			TargetFrame_Update_TP_Team();
			TargetFrame_Update_Rage_Team();
			TargetFrame_Update_Eng_Team();
			TargetFrame_Update_Level_Team();
		end

		TargetFrame_UpdateShow2DHead()

		this:Show();
		return;
	end;


	if ( event == "NVSHEN_UI_SHOW_2DHEAD" ) then

		if(0 == tonumber(arg0)) then
			
			TargetFrame_UpdateNvShenShow2DHead()
			TargetFrame_UpdateHeadFrame()
		end
		
	end
	
	
	if ( event == "MAINTARGET_CHANGED" ) then
		TargetFrame_Update_Buff()
		if(-1 == tonumber(arg0)) then
			g_TargetID = -1
			this:Hide();
			return;
		end;

		Shoujitujian_Icon:Hide()
		Shoujitujian_Animate:Hide()


		if Target:IsTransferMode() == 1 then
			TargetFrame_MP:Hide()
			TargetFrame_TP:Show()
		else
			TargetFrame_MP:Show()
			TargetFrame_TP:Hide()
		end

		if( Target:IsPresent()) then
			this:Show();
			TargetFrame_Update_Name();
			TargetFrame_Update_HP();
			TargetFrame_Update_MP();
			TargetFrame_Update_TP();
			TargetFrame_Update_Rage();
			TargetFrame_Update_Eng();
			TargetFrame_Update_Level();
			TargetFrame_Update_Head();
			TargetFrame_UpdateShow2DHead()
			TargetFrame_Update_HDSandBoxHp();

		else

			if(Target:IsTargetTeamMember() ~= 0) then

				this:Show();
				TargetFrame_DataBack:Show();
				TargetFrame_DataBack2:Hide();
				TargetFrame_UpdateShow2DHead()
			else
				g_TargetID = -1
				TargetFrame_Update_Buff()
				this:Hide();
			end;

		end
		return;
	end

	if( (event == "TARGETFRAME_GETTUJIAN") and Target:IsPresent()) then
		TargetFrame_Update_ShoujiTuJian();
		return;
	end

	if( (event == "UNIT_MP") and Target:IsPresent()) then
		TargetFrame_Update_MP();
		return;
	end

	if( (event == "UNIT_TRANSFER_ENERGY") and Target:IsPresent()) then
		TargetFrame_Update_TP();
		return;
	end

	if( (event == "UNIT_HP") and Target:IsPresent()) then
		TargetFrame_Update_HP();
		return;
	end

	if( (event == "UNIT_RAGE") and Target:IsPresent()) then
		TargetFrame_Update_Rage();
		return;
	end

	if( (event == "UNIT_ENG") and Target:IsPresent()) then
		TargetFrame_Update_Eng();
		return;
	end
	if( (event == "UNIT_MAX_ENG") and Target:IsPresent() ) then

		----AxTrace( 0,0, "UNIT_ENG");
		TargetFrame_Update_Eng();
		return;
	end
	
	if( (event == "UNIT_LEVEL") and Target:IsPresent()) then
		TargetFrame_Update_Level();
		return;
	end

	if( (event == "UNIT_RELATIVE") and Target:IsPresent()) then
		TargetFrame_Update_Name();
		return;
	end

	if ( event == "UI_SHOW_2DHEAD" ) then
		TargetFrame_UpdateShow2DHead()
		return
	end

	if ( event == "MAINTARGET_BUFF_REFRESH" ) then
		if Target:IsTransferMode() == 1 then
			TargetFrame_MP:Hide()
			TargetFrame_TP:Show()
		else
			TargetFrame_MP:Show()
			TargetFrame_TP:Hide()
		end
		TargetFrame_Update_Buff()
		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 999029009 then
		g_NowZMBossHp = Get_XParam_INT(0)	
		g_NowZMBossHpCoe = Get_XParam_INT(1)	
		if Target:IsPresent() then
			TargetFrame_Update_HP();
		end
	end

	if ( event == "UPDATE_YWBOSS_INFO" ) then
		if Target:IsPresent() then
			TargetFrame_Update_HP();
		end
	end

	if ( event == "UPDATE_XIAKE_BOSS_INFO" ) then
		if Target:IsPresent() then
			TargetFrame_Update_HP();
		end
	end

	if event == "UI_COMMAND" and tonumber(arg0) == 890391001 then
		g_NowWDBossHp = Get_XParam_INT(0)	
		if Target:IsPresent() then
			TargetFrame_Update_HP();
		end
	end

	-------------------------------------------------------------------------------------------------
	--
	-- 当target是自己的时候无法刷新。
	--

	--if( (event == "UNIT_MP") and (arg0 == "target") and Target:IsPresent()) then
	--	TargetFrame_Update_MP();
	--	return;
	--end

	--if( (event == "UNIT_HP") and (arg0 == "target") and Target:IsPresent()) then
	--	TargetFrame_Update_HP();
	--	return;
	--end

	--if( (event == "UNIT_RAGE") and (arg0 == "target") and Target:IsPresent()) then
	--	TargetFrame_Update_Rage();
	--	return;
	--end

	--if( (event == "UNIT_LEVEL") and (arg0 == "target") and Target:IsPresent()) then
	--	TargetFrame_Update_Level();
	--	return;
	--end

	--if( (event == "UNIT_RELATIVE") and (arg0 == "target") and Target:IsPresent()) then
	--	TargetFrame_Update_Name();
	--	return;
	--end
	if( (event == "UNIT_HSANDBOX_HP") and Target:IsPresent()) then
		TargetFrame_Update_HDSandBoxHp();
		return;
	end
	if( (event == "UNIT_HSANDBOX_MAX_HP") and Target:IsPresent()) then
		TargetFrame_Update_HDSandBoxHp();
		return;
	end

end

function TargetFrame_Update_ShoujiTuJian()

	local bIsNpc = Target:GetData( "ISNPC" );
	if bIsNpc == false then
		Shoujitujian_Icon:Hide()
		Shoujitujian_Animate:Hide()
		return
	end

	local bTujianLabel = Target:GetData( "TUJIANLABEL" );
	if bTujianLabel == false then
		Shoujitujian_Icon:Hide()
		Shoujitujian_Animate:Hide()
		return
	end

	local occupation = Target:GetData("OCCUPATION_TUJIAN")
	if(occupation ~= 1) then
		Shoujitujian_Icon:Hide()
		Shoujitujian_Animate:Hide()
		return
	end

	local nTujian = Target:GetData( "TujianIndex" );
	if nTujian < 0 then
		Shoujitujian_Icon:Hide()
		Shoujitujian_Animate:Hide()
		return
	end

	local ClassIndex, TaotuIndex, CardIndex = DataPool:GetDirectory_TujianCard( tonumber(nTujian) )
	if ClassIndex ~= 0 then
		Shoujitujian_Icon:Hide()
		Shoujitujian_Animate:Hide()
		return
	end

	local bhavetujian = DataPool:GetTujianBit( tonumber(nTujian) )
	if bhavetujian == true then
		Shoujitujian_Icon:Hide()
		Shoujitujian_Animate:Hide()
		return
	end

	local HPPercent = Target:GetHPPercent();
	if HPPercent < 0.5 and HPPercent > 0 then
		Shoujitujian_Animate:Show()
		Shoujitujian_Icon:Show()
	else
		Shoujitujian_Animate:Hide()
		Shoujitujian_Icon:Hide()
	end
end

function TargetFrame_Update_Name()
	local txtColor="#cFFFFFF";
--or Target:GetData("ISNPC") == 0
--以前玩家统一显示为白色，根据阮枚5月27日文档更改，玩家和NPC走同一规则。
	if Target:GetData( "RELATIVE" ) == 2  then
		txtColor = "#W"
	else
		txtColor = "#R"
	end
	TargetFrame_NameBar : Show();
	local occupation = Target:GetData("OCCUPATION")


	if(occupation == -1) then
		TargetFrame_NameBar : SetImageColor("FF00FF00")
	elseif(occupation == 0) then
		TargetFrame_NameBar : SetImageColor("FFFFFFFF")
	elseif(occupation == 1) then
		TargetFrame_NameBar : SetImageColor("FFFF0000")
	end

	TargetFrame_Name:SetText( txtColor..Target:GetFullName());
	TargetFrame_Name:Show();

	local szIcon = Target : GetData("PORTRAIT");
	
	TargetFrame_Head_2D:SetProperty("Image", szIcon);
--添加判断目标属性的设计
	--“宠”“人”“傀”“兽”“莽”“修”“妖”
	local nNpcType = Target:GetData( "TYPE" );
	TargetFrame_TypeIcon:SetProperty( "SetCurrentImage", "TypeName"..tostring( nNpcType ) );

	--1.友好
	--2.中立
	--3.珍兽
	--4.普通敌人
	--5.精英敌人
	--6.敌方boss
	--local nNpcRelation = Target:GetData( "RELATION" );
   -- if SystemSetup:IsClassic() == 1 then
   	--	PushDebugMessage(tostring( nNpcRelation ))
    	--TargetFrame_TypeFrame:SetProperty( "SetCurrentImage", "TypeFrame"..tostring( nNpcRelation ) );
	    --TargetFrame_TypeFrame_2D:SetProperty( "SetCurrentImage", "TypeFrame"..tostring( nNpcRelation ) );
   -- end

	TargetFrame_UpdateNvShenShow2DHead()
	TargetFrame_UpdateHeadFrame()
	--跟新门派
	local nNpcReputation = Target:GetData( "MEMPAI_TargetFrame" );
	if( nNpcReputation == -1 ) then
        if SystemSetup:IsClassic() == 1 then
		    TargetFrame_CampFrame1:Hide();
        end
	else
        if SystemSetup:IsClassic() == 1 then
		    TargetFrame_CampFrame1:Show();
        end
		--注意：这里是很无奈的特写，具体数值请参考客户端代码中
		--Client\Game\Interface\GMGameInterface_Script_Character.cpp
		--INT Character::GetData(LuaPlus::LuaState* state) 函数
		local npcReputationImageIndex = nNpcReputation
		if npcReputationImageIndex == 10 then
			npcReputationImageIndex = 32
		elseif npcReputationImageIndex == 11 then
			npcReputationImageIndex = 33
		elseif npcReputationImageIndex >= 12 and npcReputationImageIndex <= 33 then
			npcReputationImageIndex = npcReputationImageIndex - 2
		elseif npcReputationImageIndex == 38 then
			npcReputationImageIndex = 34
		elseif npcReputationImageIndex >= 47 and npcReputationImageIndex <= 51 then
			npcReputationImageIndex = npcReputationImageIndex - 12
		elseif	npcReputationImageIndex == 52 then
			npcReputationImageIndex	= 16
		elseif  npcReputationImageIndex == 53 then
			npcReputationImageIndex	= 40
		elseif  npcReputationImageIndex >= 39 and npcReputationImageIndex <= 46 then
			npcReputationImageIndex	= 30
			nNpcReputation	= 40 
		elseif  npcReputationImageIndex == 54 then
			npcReputationImageIndex	= 41
		elseif  npcReputationImageIndex == 55 then
			npcReputationImageIndex	= 42
		elseif  npcReputationImageIndex == 58 then--menpai15  接口Target:GetData( "MEMPAI_TargetFrame" )返回值配合strMenPaiName
			npcReputationImageIndex	= 43--menpai15  targetframe.layout.xml里childimage要注册reputation43
		elseif  npcReputationImageIndex == 59 then
			npcReputationImageIndex	= 44
		end

		TargetFrame_CampFrame:SetProperty( "SetCurrentImage", "Reputation"..tostring( npcReputationImageIndex ) );
		TargetFrame_CampFrame:SetToolTip( strMenPaiName[ nNpcReputation + 1 ] );

		local nRaceId = Target:GetRaceId() 

		--为啥分身要特写，因为summoner 已经特写成鬼谷了，并且12也是错的！！！根本不是鬼谷，坑。为了不影响之前的逻辑，跟测试商量，也采用特写的方式。
		--case OBJECT_TYPE_SUMMONER:
		--{
		--	state->PushInteger(MATTRIBUTE_GUIGU);
		--}

		if nRaceId == 16933 or nRaceId == 16934 then 
			TargetFrame_CampFrame:SetProperty( "SetCurrentImage", "Reputation"..tostring( 33 ) );
			TargetFrame_CampFrame:SetToolTip( strMenPaiName[ 12 ] );
		end

	end

end

function TargetFrame_Update_HP()
	local nNpcRelation = Target:GetData( "RELATION" );
	if( tonumber( nNpcRelation ) == 6 ) then
		local nRaceId = Target:GetRaceId()
		local nCurYwBossMonsterDataId = DataPool : Lua_GetShamHpBossDataId()
		local nCurXiaKeBossMonsterDataId = DataPool : Lua_GetShamHpXiaKeBossDataId()
		if (nRaceId == 51916 or nRaceId == 51917 or nRaceId == 51918) and ((GetSceneID() >= 952 and GetSceneID() <= 965) or (GetSceneID() == 1004))then
			TargetFrame_DataBack:Hide();
			TargetFrame_DataBack2:Show();
			local hp = 1-(0.01*g_NowZMBossHp*(g_NowZMBossHpCoe/100))
			TargetFrame_HP_Boss1:SetProgress( hp * 3, 1 );
			TargetFrame_HP_Boss2:SetProgress( ( hp - 0.33333 ) * 3, 1 );
			TargetFrame_HP_Boss3:SetProgress( ( hp - 0.66666 ) * 3, 1 );

		-- 野外Boss的特殊刷新
		elseif nCurYwBossMonsterDataId == nRaceId then
			local nCurBossShamHpPercent100 = DataPool : Lua_GetBossShamHpPercent100()
			TargetFrame_DataBack:Hide();
			TargetFrame_DataBack2:Show();
			local hp = nCurBossShamHpPercent100 / 100
			TargetFrame_HP_Boss1:SetProgress( hp * 3, 1 );
			TargetFrame_HP_Boss2:SetProgress( ( hp - 0.33333 ) * 3, 1 );
			TargetFrame_HP_Boss3:SetProgress( ( hp - 0.66666 ) * 3, 1 );

		-- 侠客Boss的特殊刷新
		elseif nCurXiaKeBossMonsterDataId == nRaceId then
			local nCurBossShamHpPercent100 = DataPool : Lua_GetXiaKeBossShamHpPercent100()
			-- !!!reloadscript =TargetFrame
			-- PushDebugMessage("nCurBossShamHpPercent100"..nCurBossShamHpPercent100)
			TargetFrame_DataBack:Hide();
			TargetFrame_DataBack2:Show();
			local hp = nCurBossShamHpPercent100 / 100
			TargetFrame_HP_Boss1:SetProgress( hp * 3, 1 );
			TargetFrame_HP_Boss2:SetProgress( ( hp - 0.33333 ) * 3, 1 );
			TargetFrame_HP_Boss3:SetProgress( ( hp - 0.66666 ) * 3, 1 );

		elseif ( nRaceId == 52333 or nRaceId == 52346 ) and ( GetSceneID() == 937 ) then
			TargetFrame_DataBack:Hide();
			TargetFrame_DataBack2:Show();
			local hp = 1-(0.01*g_NowWDBossHp)
			TargetFrame_HP_Boss1:SetProgress( hp * 3, 1 );
			TargetFrame_HP_Boss2:SetProgress( ( hp - 0.33333 ) * 3, 1 );
			TargetFrame_HP_Boss3:SetProgress( ( hp - 0.66666 ) * 3, 1 );
		elseif (nRaceId == 51786 or nRaceId == 51787 and GetSceneID() == 1040) or ( nRaceId == 52706 and GetSceneID() == 985) then
			TargetFrame_DataBack:Hide();
			TargetFrame_DataBack2:Show();
			local hp = 1-(0.01*g_NowWDBossHp)
			TargetFrame_HP_Boss1:SetProgress( hp * 3, 1 );
			TargetFrame_HP_Boss2:SetProgress( ( hp - 0.33333 ) * 3, 1 );
			TargetFrame_HP_Boss3:SetProgress( ( hp - 0.66666 ) * 3, 1 );
		
		elseif ( nRaceId == 54951 ) and ( GetSceneID() == 1064 ) then
			TargetFrame_DataBack:Hide();
			TargetFrame_DataBack2:Show();
			local hp = 1-(0.0001*g_NowWDBossHp)
			TargetFrame_HP_Boss1:SetProgress( hp * 3, 1 );
			TargetFrame_HP_Boss2:SetProgress( ( hp - 0.33333 ) * 3, 1 );
			TargetFrame_HP_Boss3:SetProgress( ( hp - 0.66666 ) * 3, 1 );		
		else
			TargetFrame_DataBack:Hide();
			TargetFrame_DataBack2:Show();
			local hp = Target:GetHPPercent();
			TargetFrame_HP_Boss1:SetProgress( hp * 3, 1 );
			TargetFrame_HP_Boss2:SetProgress( ( hp - 0.33333 ) * 3, 1 );
			TargetFrame_HP_Boss3:SetProgress( ( hp - 0.66666 ) * 3, 1 );
		end
	else
		TargetFrame_DataBack:Show();
		TargetFrame_DataBack2:Hide();
		TargetFrame_HP:SetProgress(Target:GetHPPercent(), 1);
		TargetFrame_Update_Name();
	end

	--图鉴收藏显示
	TargetFrame_Update_ShoujiTuJian()
end

function TargetFrame_Update_MP()
	TargetFrame_MP:SetProgress(Target:GetMPPercent(), 1);
end

function TargetFrame_Update_TP()
	TargetFrame_TP:SetProgress(Target:GetTPPercent(), 1);
end

function TargetFrame_Update_Rage()
	TargetFrame_SP:SetProgress(Target:GetRagePercent(), 1);

end

function TargetFrame_Update_Eng()

	TargetFrame_GQ:SetProgress(Target:GetEngPercent(), 1);

end

function TargetFrame_Update_HDSandBoxHp()

	TargetFrame_HPHDSandBoxHP:SetProgress(Target:GetHdSandBoxPercent(), 1);

end
function TargetFrame_Update_Level()

	local txtColor="#cFFFFFF";
	local level =  Target:GetData( "LEVEL" ) - Player:GetData( "LEVEL" );


--根据阮枚5月27日策划文档修改
--	if( level > 12 ) then
--		txtColor = "#R";
--	elseif( level > 4 ) then
--		txtColor = "#cff9000";
--		--以前是c9ccf00，根据杨耀提供的.jpg修改
--	elseif( level > -4 ) then
--		txtColor="#Y";
--	elseif( level > -12 ) then
--		txtColor="#G"
--	else
--		txtColor="#c4b4b4b";
--根据杨耀口述修改
--		txtColor="#c240c0c";
--	end

--根据阮枚5月27日策划文档修改如下
	if( level > 5 ) then
		txtColor = "#R";
	elseif( level > 2 ) then
		txtColor = "#cff9000";
		--以前是c9ccf00，根据杨耀提供的.jpg修改
	elseif( level >= -2 ) then
		txtColor="#Y";
	elseif( level >= -5 ) then
		txtColor="#W"
	else
--		txtColor="#c4b4b4b";
--根据杨耀口述修改
		txtColor="#W";
	end


	if( tonumber( Target:GetData( "LEVEL" ) ) >= 200 ) then
		TargetFrame_LevelText:SetText(txtColor .."?");
	else
		local nTargetLevel = Target:GetData( "LEVEL" )
		local nTargetIsPlayer = Target:GetData( "ISPLAYER" )
		local nTargetCompatPKLevel = Target:GetData( "LEVEL_CompatPKLV" )
		local isCompatPKServer = Player:GetData("IsPKServer_JD")
		if isCompatPKServer == 1 and nTargetIsPlayer == 1 and nTargetCompatPKLevel < nTargetLevel then
			TargetFrame_LevelText:SetText(txtColor .. tostring(nTargetCompatPKLevel));
		else
			TargetFrame_LevelText:SetText(txtColor .. tostring(nTargetLevel));
		end
	end
	local checkHaveMaskBuff = Lua_CheckMainTargetHaveMaskBuff()
	if checkHaveMaskBuff == 1 then
		TargetFrame_LevelText:SetText(txtColor .."?");
	end
	if Target:GetData( "IsWuXiang" ) > 0 then
		TargetFrame_LevelText:SetText("#W" .."#{WXG_250812_01}");
	end

end

function TargetFrame_ArtLayout_Click()
	ShowContexMenu("other_player");
end

-- 显示右键菜单
function TargetFrame_Show_Menu_Func()


	OpenTargetMenu();
end


function TargetFrame_Update_Name_Team()

	local strName = Target:TargetFrame_Update_Name_Team();
	local nMenpai = Target:TargetFrame_Update_Menpai_Team();
	TargetFrame_Name:SetText(strName);
	if( tonumber(nMenpai) == -1 ) then
        if SystemSetup:IsClassic() == 1 then
    		TargetFrame_CampFrame1:Hide();
        end
	else
        if SystemSetup:IsClassic() == 1 then
		    TargetFrame_CampFrame1:Show();
        end
--    PushDebugMessage( "nMenpai:"..tostring(nMenpai) )
		--慕容之后的需要特写 menpai
		local reputationImageIndex = nMenpai
		local tooltipStrIndex = nMenpai+1
		if nMenpai == 10 then--慕容
			reputationImageIndex = 32
			tooltipStrIndex = 11
		elseif nMenpai == 11 then--唐门
			reputationImageIndex = 33
			tooltipStrIndex = 12
		elseif nMenpai == 12 then--鬼谷
			reputationImageIndex = 40
			tooltipStrIndex = 54
		elseif nMenpai == 13 then--桃花岛
			reputationImageIndex = 41
			tooltipStrIndex = 55
		elseif nMenpai == 14 then--绝情谷
			reputationImageIndex = 42
			tooltipStrIndex = 56
		elseif nMenpai == 15 then--恶人谷
			reputationImageIndex = 43
			tooltipStrIndex = 59
		end
		TargetFrame_CampFrame:SetProperty( "SetCurrentImage", "Reputation"..tostring( reputationImageIndex ) );
		TargetFrame_CampFrame:SetToolTip( strMenPaiName[ tooltipStrIndex ] );
	end

	if 13 == nMenpai then
		TargetFrame_SP:Hide()
		TargetFrame_GQ:Show()
	else
		TargetFrame_SP:Show()
		TargetFrame_GQ:Hide()
	end

	local strIcon = Target:TargetFrame_Update_Icon_Team();
	TargetFrame_Head_2D:SetProperty("Image", strIcon);

    if SystemSetup:IsClassic() == 1 then
	    TargetFrame_TypeFrame:SetProperty( "SetCurrentImage", "TypeFrame1" );
    	TargetFrame_TypeFrame_2D:SetProperty( "SetCurrentImage", "TypeFrame"..tostring( nNpcRelation ) );
    end

	TargetFrame_TypeIcon:SetProperty( "SetCurrentImage", "TypeName2" );

	g_TargetID = -1
	Target:TargetFrame_Update_Model_Team();

	
	local iType, TargetHeadFrame = Target:TargetFrame_Update_HeadFrame_Team()
	if iType == 1 then
		TargetFrame_SelectCharHeadFrame:SetProperty("Image", "")
		TargetFrame_SelectCharHeadFrame:Hide()
		
		TargetFrame_Head_Animate:Show()
		TargetFrame_Head_Animate:SetProperty("Animate", tostring(TargetHeadFrame))
	else
		TargetFrame_Head_Animate:SetProperty("Animate", "")
		TargetFrame_Head_Animate:Hide()
		
		TargetFrame_SelectCharHeadFrame:Show()
		local IconFile = GetIconFullName(TargetHeadFrame)
		TargetFrame_SelectCharHeadFrame:SetProperty("Image", IconFile)
	end
	
	TargetFrame_TypeFrame_2D:SetProperty("SetCurrentImage", "")
	
	TargetFrame_UpdateShow2DHead()
end;

function TargetFrame_Update_HP_Team()

	local TeamHP = Target:TargetFrame_Update_HP_Team();
	TargetFrame_HP:SetProgress(TeamHP, 1);
end;

function TargetFrame_Update_MP_Team()

	local TeamMp = Target:TargetFrame_Update_MP_Team();

	TargetFrame_MP:SetProgress(TeamMp, 1);
end;

function TargetFrame_Update_TP_Team()

	local TeamTp = Target:TargetFrame_Update_TP_Team();
	TargetFrame_TP:SetProgress(TeamTp, 1);
end;

function TargetFrame_Update_Rage_Team()

	local TeamRange = Target:TargetFrame_Update_Rage_Team();
	TargetFrame_SP:SetProgress(TeamRange, 1000);
	
end;
function TargetFrame_Update_Eng_Team()

	local TeamEng = Target:TargetFrame_Update_Eng_Team();
	TargetFrame_GQ:SetProgress(TeamEng, 1000);
	
end;
function TargetFrame_Update_Level_Team()

	local TeamLevel = Target:TargetFrame_Update_Level_Team();
	TargetFrame_LevelText:SetText(tostring(TeamLevel));
end;

function TargetFrame_Select_TargetOfTarget_Func()
         SelectTargetOfTarget();
end;

function TargetFrame_Shoujitujian_Func()
         ShoujiTargetTujian();
end;

function TargetFrame_OnShow()
	PushEvent("SHOW_PHOENIXPLAINWAR_SCORE_S",2)
end

function	TargetFrame_Update_Name_Raid()
	local strName = Target:TargetFrame_Update_Name_Raid();
	local nMenpai = Target:TargetFrame_Update_Menpai_Raid();
	TargetFrame_Name:SetText(strName);
	if( tonumber(nMenpai) == -1 ) then
        if SystemSetup:IsClassic() == 1 then
		    TargetFrame_CampFrame1:Hide();
        end
	else
        if SystemSetup:IsClassic() == 1 then
		    TargetFrame_CampFrame1:Show();
        end
--    PushDebugMessage( "nMenpai:"..tostring(nMenpai) )
		--慕容之后的需要特写 menpai
		local reputationImageIndex = nMenpai
		local tooltipStrIndex = nMenpai+1
		if nMenpai == 10 then--慕容
			reputationImageIndex = 32
			tooltipStrIndex = 11
		elseif nMenpai == 11 then--唐门
			reputationImageIndex = 33
			tooltipStrIndex = 12
		elseif nMenpai == 12 then--鬼谷
			reputationImageIndex = 40
			tooltipStrIndex = 54
		elseif nMenpai == 13 then--桃花岛
			reputationImageIndex = 41
			tooltipStrIndex = 55
		elseif nMenpai == 14 then--绝情谷
			reputationImageIndex = 42
			tooltipStrIndex = 56
		elseif nMenpai == 15 then--恶人谷
			reputationImageIndex = 43
			tooltipStrIndex = 59
		end
		TargetFrame_CampFrame:SetProperty( "SetCurrentImage", "Reputation"..tostring( reputationImageIndex ) );
		TargetFrame_CampFrame:SetToolTip( strMenPaiName[ tooltipStrIndex ] );
	end
	local strIcon = Target:TargetFrame_Update_Icon_Raid();
	TargetFrame_Head_2D:SetProperty("Image", strIcon);
    if SystemSetup:IsClassic() == 1 then
	    TargetFrame_TypeFrame:SetProperty( "SetCurrentImage", "TypeFrame1" );
    	TargetFrame_TypeFrame_2D:SetProperty( "SetCurrentImage", "TypeFrame1" );
    end
	TargetFrame_TypeIcon:SetProperty( "SetCurrentImage", "TypeName2" );

	g_TargetID = -1
	
	--更新边框
	local iType, TargetHeadFrame = Target:TargetFrame_Update_HeadFrame_Raid()
	if iType == 1 then
		TargetFrame_SelectCharHeadFrame:SetProperty("Image", "")
		TargetFrame_SelectCharHeadFrame:Hide()
		
		TargetFrame_Head_Animate:Show()
		TargetFrame_Head_Animate:SetProperty("Animate", tostring(TargetHeadFrame))
	else
		TargetFrame_Head_Animate:SetProperty("Animate", "")
		TargetFrame_Head_Animate:Hide()
		
		TargetFrame_SelectCharHeadFrame:Show()
		local IconFile = GetIconFullName(TargetHeadFrame)
		TargetFrame_SelectCharHeadFrame:SetProperty("Image", IconFile)
	end
	TargetFrame_TypeFrame_2D:SetProperty( "SetCurrentImage", "" );
	
	TargetFrame_UpdateShow2DHead()
end;

function TargetFrame_Update_HP_Raid()

	local RaidHP = Target:TargetFrame_Update_HP_Raid();
	TargetFrame_HP:SetProgress(RaidHP, 1);
end;

function TargetFrame_Update_MP_Raid()

	local RaidMp = Target:TargetFrame_Update_MP_Raid();
	TargetFrame_MP:SetProgress(RaidMp, 1);
end;

function TargetFrame_Update_TP_Raid()

	local RaidTp = Target:TargetFrame_Update_TP_Raid();
	TargetFrame_TP:SetProgress(RaidTp, 1);
end;

function	TargetFrame_Update_Rage_Raid()

	local RaidRange = Target:TargetFrame_Update_Rage_Raid();
	TargetFrame_SP:SetProgress(RaidRange, 1000);
end;

function	TargetFrame_Update_Eng_Raid()

	local RaidEng = Target:TargetFrame_Update_Eng_Raid();
	TargetFrame_GQ:SetProgress(RaidEng, 1000);
end;

function	TargetFrame_Update_Level_Raid()

	local RaidLevel = Target:TargetFrame_Update_Level_Raid();
	TargetFrame_LevelText:SetText(tostring(RaidLevel));
end;

function	TargetFrame_Update_Head()

	local npcID = Target:GetData("MODELID");
	local tempNpcID = Target:GetData("NPCID");
	if (type(tempNpcID) == "number") then
			if (g_TargetID ~= tempNpcID) then
				g_TargetID = tempNpcID
			end

		TargetFrame_UpdateShow2DHead()
	end
end


function  TargetFrame_UpdateNvShenShow2DHead()
	
	--1.友好
	--2.中立
	--3.珍兽
	--4.普通敌人
	--5.精英敌人
	--6.敌方boss
		local nNpcRelation = Target:GetData( "RELATION" );
    if SystemSetup:IsClassic() == 1 then
   		if Target:TargetFrame_GetTitleType() == nNvShenTitleID or Target:TargetFrame_GetTitleType() == nNvShenTitleIDEx then
	   			nNpcRelation = 7
	   	end
   		
    	TargetFrame_TypeFrame:SetProperty( "SetCurrentImage", "TypeFrame"..tostring( nNpcRelation ) );
	    TargetFrame_TypeFrame_2D:SetProperty( "SetCurrentImage", "TypeFrame"..tostring( nNpcRelation ) );
	    
	  else
	  	if Target:TargetFrame_GetTitleType() == nNvShenTitleID or Target:TargetFrame_GetTitleType() == nNvShenTitleIDEx then
	   			TargetFrame_TypeFrame_2D:SetProperty( "SetCurrentImage", "TypeFrame7" );
	   			TargetFrame_TypeFrame_2D:Show()
	   	else
	   			TargetFrame_TypeFrame_2D:Hide()
	   	end
	  	
    end
end




function  TargetFrame_UpdateShow2DHead()

	-- 头像类型
	local ct = Target:GetData("CHAR_TYPE");

		TargetFrame_Head_2D:Show()
		TargetFrame_Head_3D_ParentWindow:Hide()
        if SystemSetup:IsClassic() == 1 then
		    TargetFrame_TypeFrame:Hide()
    		TargetFrame_TypeFrame_2D:Show()
	    	if ( ct == 0 or ct == 1 ) then
		    	TargetFrame:SetProperty("UnifiedSize", "{{0.000000,303.000000},{0.000000,107.000000}");
			    TargetFrame2:SetProperty("UnifiedSize", "{{0.000000,303.000000},{0.000000,95.000000}");
    			TargetFrame2_BG:SetProperty("UnifiedPosition", "{{1.000000,-268.000000},{0.000000,1.000000}}");
				TargetFrame_UpdateHeadFrame()
	    	else
		    	TargetFrame:SetProperty("UnifiedSize", "{{0.000000,314.000000},{0.000000,107.000000}");
			    TargetFrame2:SetProperty("UnifiedSize", "{{0.000000,314.000000},{0.000000,95.000000}");
    			TargetFrame2_BG:SetProperty("UnifiedPosition", "{{1.000000,-279.000000},{0.000000,1.000000}}");
	    	end
		    TargetFrame2_BG:SetProperty("Image", "set:CommonFrame18 image:TragetFrame");
    		TargetFrame2_Image:SetProperty("UnifiedPosition", "{{0.000000,0.000000},{0.000000,12.000000}}");
            TargetFrame_DataBack:SetProperty("UnifiedPosition", "{{0.000000,24.000000},{0.000000,28.000000}}");
            TargetFrame_DataBack2:SetProperty("UnifiedPosition", "{{0.000000,24.000000},{0.000000,28.000000}}");
            TargetFrame_NameBar:SetProperty("UnifiedPosition", "{{0.000000,27.000000},{0.000000,14.000000}}");
            TargetFrame_CampFrame:SetProperty("UnifiedPosition", "{{0.000000,100.000000},{0.000000,57.000000}}");
            TargetFrame_LevelText:SetProperty("UnifiedPosition", "{{0.000000,160.000000},{0.000000,56.000000}}");
            TargetFrame_TypeIcon:SetProperty("UnifiedPosition", "{{0.000000,192.000000},{0.000000,55.000000}}");
        end

end

function  TargetFrame_UpdateHeadFrame()
	if Target:TargetFrame_GetTitleType() == nNvShenTitleID or Target:TargetFrame_GetTitleType() == nNvShenTitleIDEx then
		TargetFrame_SelectCharHeadFrame:SetProperty("Image", "")
		TargetFrame_Head_Animate:SetProperty("Animate", "")
		TargetFrame_Head_Animate:Hide()
		return
   	end
	
	local ct = Target:GetData("CHAR_TYPE");
	if ct == 1 then
		local isYF = Lua_CheckMainTargetAndMyselfFromYF()
		if isYF == 1 then
			TargetFrame_SelectCharHeadFrame:SetProperty("Image", "")
			TargetFrame_Head_Animate:SetProperty("Animate", "")
			TargetFrame_Head_Animate:Hide()
			return
		end
		local isZBS = Lua_CheckMainTargetAndMyselfFromZBS()
		if isZBS == 1 then
			TargetFrame_SelectCharHeadFrame:SetProperty("Image", "")
			TargetFrame_Head_Animate:SetProperty("Animate", "")
			TargetFrame_Head_Animate:Hide()
			return
		end	
		local isACS = ANS:Lua_CheckMainTargetAndMyselfFromAnonymousCommon()
		if isACS == 1 then
			TargetFrame_SelectCharHeadFrame:SetProperty("Image", "")
			TargetFrame_Head_Animate:SetProperty("Animate", "")
			TargetFrame_Head_Animate:Hide()
			TargetFrame_TypeFrame_2D:Hide()

			return
		end	
		local checkHaveMaskBuff = Lua_CheckMainTargetHaveMaskBuff()
		if checkHaveMaskBuff == 1 then
			TargetFrame_SelectCharHeadFrame:SetProperty("Image", "")
			TargetFrame_Head_Animate:SetProperty("Animate", "")
			TargetFrame_Head_Animate:Hide()
			TargetFrame_TypeFrame_2D:Hide()

			return
		end
	end
	if ( ct == 0 or ct == 1 ) then	-- 判断是否选中自己或其他玩家
	
		local TargetHeadFrameType = Target:GetData("HEADFRAMETYPE")
		if TargetHeadFrameType == 1 then
			TargetFrame_SelectCharHeadFrame:SetProperty("Image", "")
			TargetFrame_SelectCharHeadFrame:Hide()
			
			TargetFrame_Head_Animate:Show()
			local TargetHeadFrameAnimate = Target:GetData("HEADFRAMEANIMATE")
			TargetFrame_Head_Animate:SetProperty("Animate", tostring(TargetHeadFrameAnimate))
		else
			TargetFrame_Head_Animate:SetProperty("Animate", "")
			TargetFrame_Head_Animate:Hide()
			
			TargetFrame_SelectCharHeadFrame:Show()
			local TargetHeadFrameImage = Target:GetData( "HEADFRAMEIMAGE" )
			local IconFile = GetIconFullName(TargetHeadFrameImage)
			TargetFrame_SelectCharHeadFrame:SetProperty("Image", IconFile)
		end
		
		TargetFrame_TypeFrame_2D:Hide()
		return
	end
	
	TargetFrame_SelectCharHeadFrame:SetProperty("Image", "")
	TargetFrame_Head_Animate:SetProperty("Animate", "")
	TargetFrame_Head_Animate:Hide()
end

function TargetFrame_Update_Buff()
	local selfMenpai = Player:GetData("MEMPAI")
	if selfMenpai ~= 15 or TLCJ:IsInTLCJScene() > 0 then
		for x=1,4 do
			g_ERenGuTargetUI[x].UI:Hide()
		end
		return
	end
	Target:UpdateActionButton()
		
	local haveImpact5 = Target:CheckBuffImpactExist(g_ERenGuTargetUI[5].impactId)
	local haveImpact4 = Target:CheckBuffImpactExist(g_ERenGuTargetUI[4].impactId)
	if haveImpact5 ~= nil and haveImpact5 == 1 then
		g_ERenGuTargetUI[5].UI:Show()
		g_ERenGuTargetUI[5].UI:SetProperty("Image", g_ERenGuTargetUI[5].brightImage)
		g_ERenGuTargetUI[5].UI:SetToolTip(g_ERenGuTargetUI[5].brightToolTip)
	elseif haveImpact4 ~= nil and haveImpact4 == 1 then
		g_ERenGuTargetUI[4].UI:Show()
		g_ERenGuTargetUI[4].UI:SetProperty("Image", g_ERenGuTargetUI[4].brightImage)
		g_ERenGuTargetUI[4].UI:SetToolTip(g_ERenGuTargetUI[4].brightToolTip)
	else
		g_ERenGuTargetUI[4].UI:Hide()
		g_ERenGuTargetUI[5].UI:Hide()
	end	
	
	for x=1,3 do
		local haveImpact = Target:CheckBuffImpactExist(g_ERenGuTargetUI[x].impactId)
		if(haveImpact ~= nil and haveImpact == 2) then 
			g_ERenGuTargetUI[x].UI:Hide()
			continue
		end
		g_ERenGuTargetUI[x].UI:Show()
		if(haveImpact ~= nil and haveImpact > 0) then
			g_ERenGuTargetUI[x].UI:SetProperty("Image", g_ERenGuTargetUI[x].grayImage)
			g_ERenGuTargetUI[x].UI:SetToolTip(g_ERenGuTargetUI[x].grayToolTip)
		else
			g_ERenGuTargetUI[x].UI:SetProperty("Image", g_ERenGuTargetUI[x].brightImage)
			g_ERenGuTargetUI[x].UI:SetToolTip(g_ERenGuTargetUI[x].brightToolTip)
		end
	end
end
