
local FlashPoint = 1/5;
local PlayerHP = 0;
local PlayerMaxHP = 0;

local PlayerMP = 0;
local PlayerMaxMP = 0;

local PlayerRage = 0;
local PlayerMaxRage = 100;

local PlayerEng = 0;
local PlayerMaxEng = 100;

local PlayerTEP = 0;
local PlayerMaxTEP = 0;

local PlayerHDSandBoxHP = 0;
local PlayerHDSandBoxMaxHp = 100;


local iMouseInPos = 0;	-- 0 :空白处
												-- 1 : 在血条处
												-- 2 : 在法力条处
                        -- 3 : 在怒气条处
local DoubleHit = {}
local CongRenHit = {}
local GuiguPoint = {}

--local PetFlashTime = 10*1000			--珍兽按钮闪烁时间10秒钟，单位是毫秒，所以乘以1000转换为秒
local HuoDongTime  = 30*1000      --活动按钮闪烁时间30秒钟


local LEVEL_LIMIT = 10;						--10级以下无法打开

local nIsWeekOrMonthCard = 0;

local g_InfantCardGiftflashdown = 10*1000; 	--10s闪烁

	--女神称号id
	local nNvShenTitleID = 289
	local nNvShenTitleIDEx = 290
	
local g_ERenGuUI = {}
local PlayerFrame_MiniBuff = {};
local PlayerFrame_ButtonShowIndex = {};

										
--OnLoad

function PlayerFrame_PreLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD",true);
	this:RegisterEvent("UNIT_NAME",false);
	this:RegisterEvent("UNIT_HP",false);
	this:RegisterEvent("UNIT_MANA",false);
	this:RegisterEvent("UNIT_HP_PERCENT",false);
	this:RegisterEvent("UNIT_MP_PERCENT",false);
	this:RegisterEvent("UNIT_RAGE",false);			-- 注册怒气

	this:RegisterEvent("UNIT_MAX_HP",false);
	this:RegisterEvent("UNIT_MP",false);
	this:RegisterEvent("UNIT_MAX_MP",false);
	this:RegisterEvent("UNIT_TRANSFER_ENERGY",false);

	this:RegisterEvent("UNIT_STRIKEPOINT",false);
	this:RegisterEvent("UNIT_CONGRENPOINT",false);
	this:RegisterEvent("UNIT_GUIGUPOINT",false);

	this:RegisterEvent("UNIT_FACE_IMAGE",false);

	this:RegisterEvent("TEAM_REFRESH_MEMBER",false);
	this:RegisterEvent("TEAM_NOTIFY_APPLY",false);
	--this:RegisterEvent("UPDATE_PETINVITEFRIEND",false);
	this:RegisterEvent("FLAH_MINIMAP",false);

	this:RegisterEvent("STOP_FLAH_MINIMAP",false);
	this:RegisterEvent("UPDATE_BTN_FLASH",false);	--zchw
	this:RegisterEvent("SHOW_UPDATE_UI",false);	--zchw

	this:RegisterEvent("RAID_UPDATE_RAID_ICON",false);
	this:RegisterEvent("HIDE_TLBB_MAIN",false)
	this:RegisterEvent("UI_SHOW_2DHEAD",false)	--显示2D头像
	this:RegisterEvent("SHOW_VIP_BUTTON",true)
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("TOGGLE_TEP",false)
	this:RegisterEvent("SHOW_WEEKCARD_BUTTON",true) --显示便捷服务按钮
	this:RegisterEvent("HIDE_WEEKCARD_BUTTON",true) --隐藏便捷服务按钮
	this:RegisterEvent("FLASH_VIP_BUTTON",false)
	this:RegisterEvent("UPDATE_NOTIFY",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UPDATE_FAKE_OBJECT",false)
	this:RegisterEvent("HIDE_THIS_UI",true)
	this:RegisterEvent("UNIT_LEVEL",false)
	this:RegisterEvent("JOIN_NEW_MENPAI",false)
	this:RegisterEvent("RESET_ALLUI",false)
	this:RegisterEvent("SHOW_EXCHANGE_MONEY",false)
	this:RegisterEvent("NVSHEN_UI_SHOW_2DHEAD",false)
	this:RegisterEvent("UNIT_HEADFRAME",false);
	this:RegisterEvent("UNIT_ENG",false);			-- 注册能量
	this:RegisterEvent("UNIT_MAX_ENG",false);			-- 注册能量
	this:RegisterEvent("TLCJ_BASEATTRUPDATE",false);			-- 等级
	this:RegisterEvent("IMPACT_SELF_UPDATE",true);
	this:RegisterEvent("UNIT_MENPAI",false);
	this:RegisterEvent("UNIT_HSANDBOX_HP",false);			-- 注册沙盒血量
	this:RegisterEvent("UNIT_HSANDBOX_MAX_HP",false);			-- 注册沙盒最大血量
	this:RegisterEvent("PVPSTATE_TRUE",true);
	this:RegisterEvent("PVPSTATE_FALSE",true);
end

function PlayerFrame_OnLoad()
	DoubleHit[1] = PlayerFrame_DoubleHit1;
	DoubleHit[2] = PlayerFrame_DoubleHit2;
	DoubleHit[3] = PlayerFrame_DoubleHit3;
	DoubleHit[4] = PlayerFrame_DoubleHit4;
	DoubleHit[5] = PlayerFrame_DoubleHit5;
	DoubleHit[6] = PlayerFrame_DoubleHit6;
	DoubleHit[7] = PlayerFrame_DoubleHit7;
	DoubleHit[8] = PlayerFrame_DoubleHit8;
	DoubleHit[9] = PlayerFrame_DoubleHit9;

	CongRenHit[1] = PlayerFrame_DaoyiIcon1;
	CongRenHit[2] = PlayerFrame_DaoyiIcon2;
	CongRenHit[3] = PlayerFrame_DaoyiIcon3;
	CongRenHit[4] = PlayerFrame_DaoyiIcon4;
	
	GuiguPoint[1] = PlayerFrame_XingLingDianIcon1;
	GuiguPoint[2] = PlayerFrame_XingLingDianIcon2;
	GuiguPoint[3] = PlayerFrame_XingLingDianIcon3;
	
	g_ERenGuUI = {
	{impactId = 9100, UI=PlayerFrame_ERenSoulHit1, grayImage="set:CommonFrame39 image:ERenSoulHitTianDis",brightImage="set:CommonFrame39 image:ERenSoulHitTian",grayToolTip="#{ERJN_240902_01}",brightToolTip="#{ERJN_240902_04}"},
	{impactId = 9093, UI=PlayerFrame_ERenSoulHit2, grayImage="set:CommonFrame39 image:ERenSoulHitDiDis",brightImage="set:CommonFrame39 image:ERenSoulHitDi",grayToolTip="#{ERJN_240902_02}",brightToolTip="#{ERJN_240902_05}"},
	{impactId = 9098, UI=PlayerFrame_ERenSoulHit3, grayImage="set:CommonFrame39 image:ERenSoulHitMingDis",brightImage="set:CommonFrame39 image:ERenSoulHitMing",grayToolTip="#{ERJN_240902_03}",brightToolTip="#{ERJN_240902_06}"},
	}

	PlayerFrame_Captain:Hide();
	--PlayerFrame_ZhengShouZhenYouFlash:Hide();
	PlayerFrame_UpdateBtnFlash:Hide();
	--PlayerFrame_MenpaiExplain:Hide();
	--PlayerFrame_WuLinChartsFlash:Hide()
	--应该策划写到字典和xml布局文件里 PlayerFrame_ZhenShouZhengYou:SetToolTip("打开征友交互界面");
	--PlayerFrame_ZhenShouZhengYou:SetToolTip("#{ZYPT_081103_001}");
	--PlayerFrame_VIPBtn:Hide()
	--PlayerFrame_VIPBtn2:Hide()
	PlayerFrame_YouLongKaBtn2:Hide()
    PlayerFrame_YouLongKaBtn:Hide()
    PlayerFrame_LevelBtn:Hide();

   PlayerFrame_SongjincansiFlash:Hide()
   PlayerFrame_SongjincansiButton:Hide();
   
   --典籍回顾功能暂时屏蔽
   PlayerFrame_InfantCard:Hide()
   PlayerFrame_InfantCardFlash:Hide();
   
	for x=1,3 do   	
		g_ERenGuUI[x].UI:Hide()		
	end
	PlayerFrame_MiniBuff[1] = PlayerFrame_PVPPK
	PlayerFrame_ButtonShowIndex[1] = 0
end

function PlayerFrame_OnEvent(event)

	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		this:Hide()
		return
	end
	
   if IsZbs2018SpeicalServer() >= 1 then
		PlayerFrame_DuiHuan:Hide()
		PlayerFrame_ChongZhi1:Hide()
   end
   
   	if ZBS:IsViewerWatching() > 0 then
		this:Hide()
		return
	end
	
	if ( event == "PLAYER_ENTERING_WORLD" ) then


		----AxTrace( 0,0, "enter word!");
		this:Show();

		--PlayerFrame_HP_Text:SetClippedByParent(0);
		--PlayerFrame_MP_Text:SetClippedByParent(0);
		--PlayerFrame_SP_Text:SetClippedByParent(0);

		PlayerFrame_Update();
		-- 更新头像信息.

		--AxTrace( 0,0, "enter word!");
		--AxTrace( 0,0, "更新头像");
		PlayerFrame_Update_Image();
		PlayerFrame_UpdateShow2DHead();
		--PlayerFrame_Update_VIP_Button();

		return;
	end

	if event == "TOGGLE_TEP" then
		if arg0 == "0" then
			PlayerFrame_MP:Show()
			PlayerFrame_TEP:Hide()
		else
			PlayerFrame_MP:Hide()
			PlayerFrame_TEP:Show()
		end
	end

	if event == "NVSHEN_UI_SHOW_2DHEAD" then
		if 1 == tonumber(arg0) then
			--PlayerFrame_UpdateNvShenShow2DHead()
			--PlayerFrame_Update_HeadFrame()
		end		
	end
	
	if( event == "UPDATE_FAKE_OBJECT" ) then
		if( arg0 == "Player_3DHead" and this:IsVisible() ) then
			PlayerFrame_Update_Image()
		end
	end

	if (event == "UI_COMMAND") and (arg0 == "20061126") then
		local param0 = Get_XParam_INT(0)
		if param0 == 0 then
			local param1 = Get_XParam_INT(1)
			if param1 == 0 then
				PlayerFrame_MP:Show()
				PlayerFrame_TEP:Hide()
			else
				PlayerFrame_MP:Hide()
				PlayerFrame_TEP:Show()
			end
		end
	end

	if (event == "UI_COMMAND") and (arg0 == "20120846") then

		--local fX, fY = this:GetChildOffset("PlayerFrame_WuLinCharts")
		--fX = fX + PlayerFrame_WuLinCharts:GetProperty("AbsoluteWidth") / 2
        --fY = fY + PlayerFrame_WuLinCharts:GetProperty("AbsoluteHeight") / 2
		--local param0 = Get_XParam_INT(0)
		--local param1 = Get_XParam_INT(1)
		--if param0 == 0 then
			--PlayerFrame_WuLinChartsFlash:Show();
			--Lua_SetFengyunluInt(param1)
			--OpenFreshManGuide(1,35, fX, fY, "PlayerFrame", "southeast")
		--else
			--OpenFreshManGuide(1,36, fX, fY, "PlayerFrame", "southeast")
		--end

	end

	if (event == "UI_COMMAND") and (arg0 == "20120314") then
	    --开启tips
		local fX = 0
		local fY = 0

		fX, fY = this:GetChildOffset("PlayerFrame_YouLongKaBtn")

		fX = fX + 10
		fY = fY + 10
		OpenFreshManGuide(1, 23, fX, fY, "PlayerFrame", "southeast")
	end

	if (event == "UI_COMMAND") and (arg0 == "20120319") then
	    PlayerFrame_YouLongKaBtn2:Show()
	end

	if (event == "UI_COMMAND") and (arg0 == "201205142") then
	    --显示和隐藏便捷按钮
	    if Get_XParam_INT(0) == 1 then
			if (true ~= PlayerFrame_YouLongKaBtn:IsVisible()) then
				PlayerFrame_YouLongKaBtn:Show()
				PlayerFrame_UpdateShow2DHead()
		    end
		else
			--if PlayerFrame_YouLongKaBtn:IsVisible() then
				PlayerFrame_YouLongKaBtn:Hide()
				PlayerFrame_UpdateShow2DHead()
				--PushDebugMessage("PlayerFrame_YouLongKaBtn:Hide")
		    --end
	    end
	end

	if (event == "UI_COMMAND") and (arg0 == "201205143") then
		nIsWeekOrMonthCard = Get_XParam_INT(1)
	end

	-- if (event == "UI_COMMAND") and (arg0 == "201512031") then
	
		-- if Get_XParam_INT(0) == 3 then	
			-- PlayerFrame_InfantCard:Show()		
			-- PlayerFrame_InfantCardFlash:Hide();	
			-- --PlayerFrame_InfantCardFlash:Show();
			-- --SetTimer("PlayerFrame", "PlayerFrame_InfantCard_Flashdown()",g_InfantCardGiftflashdown)
		-- elseif 	( Get_XParam_INT(0) == 1 or Get_XParam_INT(0) == 2 ) then	
			-- local textId = 90
			-- if Get_XParam_INT(0) == 2 then	
				-- textId = 91
			-- end
			-- --开启tips
			-- local fX = 0
			-- local fY = 0
	
			-- fX, fY = this:GetChildOffset("PlayerFrame_InfantCard")
	
			-- fX = fX + 45
			-- fY = fY + 12
			-- OpenFreshManGuide(1, textId, fX, fY, "PlayerFrame", "southeast")
			-- PlayerFrame_InfantCard:Show()		
			-- PlayerFrame_InfantCardFlash:Show();
			-- SetTimer("PlayerFrame", "PlayerFrame_InfantCard_Flashdown()",g_InfantCardGiftflashdown)
		-- else
			-- PlayerFrame_InfantCard:Hide()
			-- PlayerFrame_InfantCardFlash:Hide();
		-- end		
	-- end
	
		
--	if (event == "UI_COMMAND") and (arg0 == "2015052701") then
--		local nParam = Get_XParam_INT(0);
--		if nParam == 1 or nParam == 2 or nParam == 3 then
		
			--开启tips
--			local fX = 0
--			local fY = 0

--			fX, fY = this:GetChildOffset("PlayerFrame_BaoDianZJHB2Button")

--			fX = fX + 40
--			fY = fY + 10
--			if nParam == 1 then
--				OpenFreshManGuide(1, 69, fX, fY, "PlayerFrame", "southeast")
				--PlayerFrame_BaoDianZJHB2Button:SetToolTip( "#{KPLS_150527_4}" );
--			elseif nParam == 2 then
--				OpenFreshManGuide(1, 70, fX, fY, "PlayerFrame", "southeast")
				--PlayerFrame_BaoDianZJHB2Button:SetToolTip( "#{KPLS_150527_6}" );
--			elseif nParam == 3 then
--				local nMeiLiValue = Get_XParam_INT(1);
--				DataPool:Lua_SetMeiLiValue(nMeiLiValue);
--				OpenFreshManGuide(1, 72, fX, fY, "PlayerFrame", "southeast")
				--PlayerFrame_BaoDianZJHB2Button:SetToolTip( ScriptGlobal_Format("#{KPLS_150527_10}", nMeiLiValue) );
--			end
--			PlayerFrame_BaoDianZJHB2Flash:Show();
--			SetTimer("PlayerFrame", "PlayerFrame_BaoDianZJHB2Flashdown()",g_BaoDianZJHB2flashdown)
		
--			PlayerFrame_BaoDianZJHB2Button:Show()
--		else
--			PlayerFrame_BaoDianZJHB2Flash:Hide();
--			PlayerFrame_BaoDianZJHB2Button:Hide();
--		end		
--	end
	
	--AxTrace( 0,0, tostring(event));
	if( (event == "UNIT_NAME") and (arg0 == "player")) then
		PlayerFrame_Update();
		return;
	end
	if( (event == "UNIT_MAX_MP") and (arg0 == "player")) then

		----AxTrace( 0,0, "UNIT_MAX_MP");
		PlayerFrame_Update();
		return;
	end
	if( (event == "UNIT_MAX_HP") and (arg0 == "player")) then

		----AxTrace( 0,0, "UNIT_MAX_HP");
		PlayerFrame_Update();
		return;
	end
	if( (event == "UNIT_MP") and (arg0 == "player")) then

		----AxTrace( 0,0, "UNIT_MP");
		PlayerFrame_Update();
		return;
	end
	if( (event == "UNIT_HP") and (arg0 == "player")) then

		----AxTrace( 0,0, "UNIT_HP");
		PlayerFrame_Update();
		return;
	end

	if( (event == "UNIT_MANA") and (arg0 == "player")) then

		----AxTrace( 0,0, "UNIT_MANA");
		PlayerFrame_Update();
		return;
	end

	if( (event == "UNIT_TRANSFER_ENERGY") and (arg0 == "player")) then

		----AxTrace( 0,0, "UNIT_TRANSFER_ENERGY");
		PlayerFrame_Update();
		return;
	end

	if( (event == "UNIT_MP_PERCENT") and (arg0 == "player") ) then

		----AxTrace( 0,0, "UNIT_MP_PERCENT");
		PlayerFrame_Update();
		return;
	end

	if( (event == "UNIT_RAGE") and (arg0 == "player") ) then

		----AxTrace( 0,0, "UNIT_RAGE");
		PlayerFrame_Update();
		return;
	end

	if( (event == "UNIT_ENG") and (arg0 == "player") ) then

		----AxTrace( 0,0, "UNIT_ENG");
		PlayerFrame_Update();
		return;
	end


	if( (event == "UNIT_MAX_ENG") and (arg0 == "player") ) then

		----AxTrace( 0,0, "UNIT_ENG");
		PlayerFrame_Update();
		return;
	end
	if( (event == "UNIT_HP_PERCENT") and (arg0 == "player") ) then

		----AxTrace( 0,0, "UNIT_HP_PERCENT");
		PlayerFrame_Update();
		return;
	end

	if( (event == "UNIT_STRIKEPOINT") and (arg0 == "player") ) then

		----AxTrace( 0,0, "UNIT_STRIKEPOINT");
		PlayerFrame_Update();
		return;
	end


	if( (event == "UNIT_CONGRENPOINT") and (arg0 == "player") ) then

		----AxTrace( 0,0, "UNIT_STRIKEPOINT");
		PlayerFrame_Update();
		return;
	end
	
	if( (event == "UNIT_GUIGUPOINT") and (arg0 == "player") ) then
		PlayerFrame_UpdateGuiguPoint()
		return;
	end

	if( (event == "TLCJ_BASEATTRUPDATE") and (arg0 == "level") ) then
		PlayerFrame_Update()
		return;
	end
	
	if (event == "PVPSTATE_TRUE")  then
		PlayerFrame_ButtonShowIndex[1] = 1
		PlayerFrame_Update();
		return;
	end
	if (event == "PVPSTATE_FALSE")  then
		PlayerFrame_ButtonShowIndex[1] = 0
		PlayerFrame_Update();
		return;
	end
	


	--AxTrace( 0,0, "开始得到头像");
	-- 头像信息改变
	if( (event == "UNIT_FACE_IMAGE") and (arg0 == "player") ) then

		--AxTrace( 0,0, "UNIT_FACE_IMAGE");
		PlayerFrame_Update_Image();
		return;
	end

	if( event == "TEAM_REFRESH_MEMBER" ) then
		if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版,设置唯美版图片素材
			PlayerFrame_Captain:SetProperty("Image", "set:WM_MainFrame02 image:LeaderOpening")
		else
			PlayerFrame_Captain:SetProperty("Image", "set:UIIcons image:LeaderOpening")
		end
		if( tonumber( Player:IsLeader() ) == 1 ) then
			PlayerFrame_Captain:Show();
		else
			PlayerFrame_Captain:Hide();
		end
		PlayerFrame_Update();
	end
	if( event == "TEAM_NOTIFY_APPLY" ) then
		if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版,设置唯美版图片素材
			PlayerFrame_Captain:SetProperty("Image", "set:WM_MainFrame02 image:LeaderOpening")
		else
			PlayerFrame_Captain:SetProperty("Image", "set:UIIcons image:LeaderOpening")
		end
		if( tonumber( Player:IsLeader() ) == 1 ) then
			PlayerFrame_Captain:Show();
		else
			PlayerFrame_Captain:Hide();
		end
		PlayerFrame_Update();
	end
	--if( event == "UPDATE_PETINVITEFRIEND" ) then
	--	if( arg0 == "notifynew" ) then
	--		PlayerFrame_Flash_PetFriend(0);
	--		SetTimer( "PlayerFrame", "PlayerFrame_Flash_PetFriend(1)",PetFlashTime);
	--	end
	--end

	if (event == "UPDATE_BTN_FLASH") then
		PlayerFrame_UpdateBtnFlash:Show();
	end

	if (event == "SHOW_UPDATE_UI") then
		Helper:GotoRecUpdate();
	end
	
	if(event == "SHOW_EXCHANGE_MONEY")	then
		Helper:GotoExchangeMoney()
	end

	if (event == "HIDE_ON_SCENE_TRANSED") then
		PlayerFrame_UpdateBtnFlash:Hide();
		--if "PlayerFrame" == GetFreshManGuideOwner() then
		--	CloseFreshManGuide()
		--end
	end

	if (event == "RAID_UPDATE_RAID_ICON") then
		--显示团队和助理图标
		if Player:IsRaidLeader() == 1 then
			PlayerFrame_Captain:SetProperty("Image", "set:Union1 image:Union_LeaderIcon_S")
			PlayerFrame_Captain:Show()
		elseif Player:IsRaidAssitant() == 1 then
			PlayerFrame_Captain:SetProperty("Image", "set:Union1 image:Union_MemberIcon_S")
			PlayerFrame_Captain:Show()
		else
			PlayerFrame_Captain:Hide()
		end
	end

	if ( event == "HIDE_TLBB_MAIN" ) then
		this:Hide()
	end

	if ( event == "UI_SHOW_2DHEAD" ) then
		PlayerFrame_UpdateShow2DHead()
		return
	end

	if event == "SHOW_VIP_BUTTON" then
		--PlayerFrame_Update_VIP_Button()
	end

	if event == "SHOW_WEEKCARD_BUTTON" then
	    if (true ~= PlayerFrame_YouLongKaBtn:IsVisible()) then
	    		nIsWeekOrMonthCard = 0;
				PlayerFrame_YouLongKaBtn:Show()
				PlayerFrame_UpdateShow2DHead()
		end
	end

	if event == "HIDE_WEEKCARD_BUTTON" then
	    --if PlayerFrame_YouLongKaBtn:IsVisible() then
			--PushDebugMessage("HIDE_WEEKCARD_BUTTON")
		    PlayerFrame_YouLongKaBtn:Hide()
		    PlayerFrame_UpdateShow2DHead()
		    if arg0 == 0 then
		        local str = "#{YLK_120307_07}"
		        PushDebugMessage(str)
		    end
		--end
	end

	if event == "FLASH_VIP_BUTTON" then
		--if PlayerFrame_VIPBtn:IsVisible() then
			--PlayerFrame_VIPBtn2:Show()
		--end
	end
	
	if event == "HIDE_THIS_UI" then
		if this:IsVisible() then
			this:Hide()
		else
			this:Show()
		end
	end
	
	if event == "RESET_ALLUI" then
		PlayerFrame_SongjincansiFlash:Hide()
		PlayerFrame_SongjincansiButton:Hide()
	end
	
	if( (event == "UNIT_HEADFRAME") and (arg0 == "player") ) then
		PlayerFrame_Update_HeadFrame();
		return;
	end
	
	if (event == "IMPACT_SELF_UPDATE" or "UNIT_MENPAI" == event ) then
		PlayerFrame_UpdateJuHunImage()
		PlayerFrame_UpdateGuiguPoint()
		return;
	end
	if( (event == "UNIT_HSANDBOX_HP") and (arg0 == "player") ) then

		----AxTrace( 0,0, "UNIT_HSANDBOX_HP");
		PlayerFrame_Update();
		return;
	end

	if( (event == "UNIT_HSANDBOX_MAX_HP") and (arg0 == "player") ) then

		----AxTrace( 0,0, "UNIT_HSANDBOX_MAX_HP");
		PlayerFrame_Update();
		return;
	end
	
end

function PlayerFrame_UpdateBtnOnClicked()
	PlayerFrame_UpdateBtnFlash:Hide();
--	CloseFreshManGuide()
	Player:ClearUpdateBtnFlashFlag();
	OpenWindow("UpdatetransitionWindow")
end

function PlayerFrame_Flash_PetFriend( who )
--    if KVKInterface:IsInKVKServer() == 1 then
--       return
--   end

	--who == 0 开始闪烁 ，否则停止闪烁
--	if( who == 0 ) then
--		PlayerFrame_ZhengShouZhenYouFlash:Show();
--	else
--		PlayerFrame_ZhengShouZhenYouFlash:Hide();
--		KillTimer("PlayerFrame_Flash_PetFriend(1)");
--	end
end

function PlayerFrame_Update()
	local nC = table.getn( PlayerFrame_ButtonShowIndex )
	for i = 1, nC do
		if PlayerFrame_ButtonShowIndex[i] == 1 then
			PlayerFrame_MiniBuff[i]:Show()
		else
			PlayerFrame_MiniBuff[i]:Hide()
		end
	end

	--AxTrace( 0,0, "1");
	PlayerFrame_HPHDSandBoxHPBK:Hide()
	PlayerFrame_HPHDSandBoxHP:Hide()
	
	PlayerHP= Player:GetData( "HP" );
	PlayerMaxHP = Player:GetData("MAXHP");
	if(0 == PlayerMaxHP) then
		PlayerMaxHP = 1;
	end;
	PlayerFrame_HP:SetProgress(PlayerHP, PlayerMaxHP);
	if( PlayerHP / PlayerMaxHP > FlashPoint ) then
		PlayerFrame_Mask:Hide();
		PlayerFrame_HP_Flash:Play( false );
	else
		local Width ,Height= PlayerFrame_HP:GetWindowSize();
		Width =Width * PlayerHP / PlayerMaxHP;
		PlayerFrame_HP_Flash:SetWindowSize(Width,Height)
		PlayerFrame_HP_Flash:Play( true );
		PlayerFrame_Mask:Show();
	end

	PlayerMP = Player:GetData( "MP" );
	PlayerMaxMP = Player:GetData("MAXMP");
	if(0 == PlayerMaxMP) then

		PlayerMaxMP = 1;
	end;
	PlayerFrame_MP:SetProgress(PlayerMP, PlayerMaxMP);
	

	-- 显示怒气
	PlayerRage = Player:GetData( "RAGE" );
  PlayerMaxRage = Player:GetData( "MAXRAGE" );
  if(0 == PlayerMaxRage) then

  	PlayerMaxRage = 1;
  end;
 	PlayerFrame_SP:SetProgress(PlayerRage, PlayerMaxRage);
	

	--AxTrace( 0,0, "4");
	-- 显示名字
	local strName = Player:GetName();

	strName = "#cDED784"..strName;
	PlayerFrame_Name:SetText( strName );

	--AxTrace( 0,0, "5");
	local CongRenPoint = 0;
	local StrikePoint = 0;

	local pMenpai = Player:GetData("MEMPAI");	
	if 14 == pMenpai then
		strName = Player:GetData("CONGRENPOINT");
		CongRenPoint = tonumber(strName);
	elseif 2 == pMenpai then
		strName = Player:GetData("STRIKEPOINT");
		StrikePoint = tonumber(strName);
	end

--	----AxTrace(0,1,"StrikePoint="..StrikePoint);

	--AxTrace( 0,0, "6");

	for	i=1, 9 do
		if i <= StrikePoint and pMenpai == 2 and TLCJ:IsInTLCJScene() < 1 then
--			DoubleHit[i] : SetImageColor("FF00FF00");
			DoubleHit[i] : Show();
        else
--			DoubleHit[i] : SetImageColor("FFFFFFFF");
			DoubleHit[i] : Hide();
		end
	end

	for	i=1, 4 do
		if i <= CongRenPoint and pMenpai == 14 and TLCJ:IsInTLCJScene() < 1 then
--			DoubleHit[i] : SetImageColor("FF00FF00");
			CongRenHit[i] : Show();
        else
--			DoubleHit[i] : SetImageColor("FFFFFFFF");
			CongRenHit[i] : Hide();
		end
	end
	
	if 13 == pMenpai then
		PlayerEng = Player:GetData( "ENG" );
		PlayerMaxEng = Player:GetData( "MAXENG" );
		if(0 == PlayerMaxEng) then
			PlayerMaxEng = 1;
		end;
		PlayerFrame_SP:Hide()
		PlayerFrame_GQ:Show()
		
		PlayerFrame_GQ:SetProgress(PlayerEng, PlayerMaxEng);
	else
		PlayerFrame_SP:Show()
		PlayerFrame_GQ:Hide()
	end

	PlayerFrame_LevelBtn:Hide();
	if Player:GetData("Is2606S") == 1 then
		local nOpenDate, nDayCount = Lua_Get2606SOpenDayCount()
		local nFileCnt = Lua_Get2606SLevelInfoCount();
		if nOpenDate ~= nil and nDayCount ~= nil and nFileCnt ~= nil then
			local nTblDayCount, nTblLevel, nYear, nMonth, nDay = Lua_Get2606SLevelPhaseInfo( nOpenDate, nFileCnt-1 )
			if nTblDayCount ~= nil and nDayCount < nTblDayCount + 7 then
				PlayerFrame_LevelBtn:Show();
			end	
		end
	end

	PlayerTEP = Player:GetData( "TEP" );
	PlayerMaxTEP = Player:GetData("MAXTEP");
	if(0 == PlayerMaxTEP) then

		PlayerMaxTEP = 1;
	end;
	PlayerFrame_TEP:SetProgress(PlayerTEP, PlayerMaxTEP);

	--AxTrace( 0,0, "7");
	--显示等级
	if TLCJ:IsInTLCJScene() > 0 then
		local nNumber = TLCJ:GetData( "LEVEL" )
		PlayerFrame_Level:SetText("#cDED784"..tostring(nNumber))
	else
		local nNumber = Player:GetData( "LEVEL" );
		local isCompatPKServer = Player:GetData("IsPKServer_JD")
		local nCompatPKLevel = Player:GetData( "LEVEL_CompatPKLV" )
		if isCompatPKServer == 1 and nCompatPKLevel < nNumber then
			nNumber = nCompatPKLevel
		end
		PlayerFrame_Level:SetText("#cDED784"..tostring(nNumber));
	end


	if 1 == XRZPVP:IsInBattleSceneAndTransfer() then
		PlayerHDSandBoxHP = Player:GetData( "HDSANDBOXHP" );
		PlayerHDSandBoxMaxHp = Player:GetData( "HDSANDBOXMAXHP" );
		if(0 == PlayerHDSandBoxMaxHp) then
			PlayerHDSandBoxMaxHp = 1;
		end;
	    PlayerFrame_HP:SetProgress(PlayerHDSandBoxHP, PlayerHDSandBoxMaxHp);
    end

end

function PlayerFrame_ChongZhi()
	Chongzhi()
end

--用户单击了征友平台的按钮 modified by dun.liu
function PlayerFrame_HitZhengShou()
 --   if KVKInterface:IsInKVKServer() == 1 then
 --     	PushDebugMessage("#{KVKGZ_110620_125}")
 --       return
 --   end
	
--	if Bank:CheckIsInTServer() == 1 then
--		PushDebugMessage("#{HCYL_150304_44}")
--		return
--	end
	
--	local level = Player:GetData("LEVEL");
--	if level < LEVEL_LIMIT then
--		PushDebugMessage("#{ZYPT_081103_002}");
--		return;
--	end
--	OpenWindow("ZhengyouWindow")
--	RequestServerNoteLog(0);      --向server发送请求，记录一条日志
end

function PlayerFrame_HP_Text_MouseEnter()
	PlayerFrame_HP_Text:SetText( tostring( PlayerHP ) .. "/" .. tostring( PlayerMaxHP) );
	iMouseInPos = 1;
end

function PlayerFrame_HP_Text_MouseLeave()
	PlayerFrame_HP_Text:SetText("");
	iMouseInPos = 0;
end

function PlayerFrame_MP_Text_MouseEnter()

	PlayerFrame_MP_Text:SetText( tostring( PlayerMP ) .. "/" .. tostring( PlayerMaxMP) );
	iMouseInPos = 2;
end

function PlayerFrame_MP_Text_MouseLeave()
	PlayerFrame_MP_Text:SetText("");
	iMouseInPos = 0;
end


function PlayerFrame_SP_Text_MouseEnter()
	PlayerFrame_SP_Text:SetText( tostring( PlayerRage ) .. "/" .. tostring( 1000) );
	iMouseInPos = 3;
end

function PlayerFrame_SP_Text_MouseLeave()
	PlayerFrame_SP_Text:SetText("");
	iMouseInPos = 0;
end


function PlayerFrame_Update_Image()

	local strFaceImage = Player:GetData( "PORTRAIT" );

	--AxTrace( 0,0, "头像信息!" .. tostring(strFaceImage));
	-- 设置头像信息
	PlayerFrame_Head_2D:SetProperty("Image", tostring(strFaceImage));
	--PlayerFrame_Icon_Action:SetProperty("NormalImage", tostring(strFaceImage));
	--PlayerFrame_Icon_Action:SetProperty("HoverImage", tostring(strFaceImage));
	--PlayerFrame_Icon_Action:SetProperty("PushedImage", tostring(strFaceImage));

	-- PlayerFrame_Head_3D:SetFakeObject("");
end

-- 右键菜单
function PlayerFrame_Show_Menu_Func()

	--AxTrace( 0,0, "Player 右键菜单!");
	--OpenTargetMenu();
	Player:ShowMySelfContexMenu();
end

-- 左键选中自己
function PlayerFrame_SelectMyselfAsTarget()
	Player:SelectMyselfAsTarget();

end
function PlayerFrame_ShowTooltip( type )
	local pMenpai = Player:GetData("MEMPAI");	
	PlayerMaxRage = 1000
	if 13 ==pMenpai then
		PlayerRage = PlayerEng
		PlayerMaxRage = PlayerMaxEng
	end

	local strTooltip = "血:"..tostring( PlayerHP ) .. "/" .. tostring( PlayerMaxHP).."#r".."气:"..tostring( PlayerMP ) .. "/" .. tostring( PlayerMaxMP).."#r".."怒:"..tostring( PlayerRage ) .. "/" .. tostring( PlayerMaxRage);
	if PlayerFrame_TEP:IsVisible() then
		strTooltip = "血:"..tostring( PlayerHP ) .. "/" .. tostring( PlayerMaxHP).."#r".."能:"..tostring( PlayerTEP ) .. "/" .. tostring( PlayerMaxTEP).."#r".."怒:"..tostring( PlayerRage ) .. "/" .. tostring( PlayerMaxRage);
	end

	if 13 ==pMenpai then
		strTooltip = "血:"..tostring( PlayerHP ) .. "/" .. tostring( PlayerMaxHP).."#r".."气:"..tostring( PlayerMP ) .. "/" .. tostring( PlayerMaxMP).."#r".."共情:"..tostring( PlayerRage ) .. "/" .. tostring( PlayerMaxRage);
		if PlayerFrame_TEP:IsVisible() then
			strTooltip = "血:"..tostring( PlayerHP ) .. "/" .. tostring( PlayerMaxHP).."#r".."能:"..tostring( PlayerTEP ) .. "/" .. tostring( PlayerMaxTEP).."#r".."共情:"..tostring( PlayerRage ) .. "/" .. tostring( PlayerMaxRage);
		end
	end


	if 1 == XRZPVP:IsInBattleSceneAndTransfer() then	
	    PlayerHDSandBoxHP = Player:GetData( "HDSANDBOXHP" );
	    PlayerHDSandBoxMaxHp = Player:GetData( "HDSANDBOXMAXHP" );
		strTooltip = "血:"..tostring( PlayerHDSandBoxHP ) .. "/" .. tostring( PlayerHDSandBoxMaxHp).."#r".."气:"..tostring( PlayerMP ) .. "/" .. tostring( PlayerMaxMP).."#r".."怒:"..tostring( PlayerRage ) .. "/" .. tostring( PlayerMaxRage);
		if PlayerFrame_TEP:IsVisible() then
			strTooltip = "血:"..tostring( PlayerHDSandBoxHP ) .. "/" .. tostring( PlayerHDSandBoxMaxHp).."#r".."能:"..tostring( PlayerTEP ) .. "/" .. tostring( PlayerMaxTEP).."#r".."怒:"..tostring( PlayerRage ) .. "/" .. tostring( PlayerMaxRage);
		end
	
		if 13 ==pMenpai then
			strTooltip = "血:"..tostring( PlayerHDSandBoxHP ) .. "/" .. tostring( PlayerHDSandBoxMaxHp).."#r".."气:"..tostring( PlayerMP ) .. "/" .. tostring( PlayerMaxMP).."#r".."共情:"..tostring( PlayerRage ) .. "/" .. tostring( PlayerMaxRage);
			if PlayerFrame_TEP:IsVisible() then
				strTooltip = "血:"..tostring( PlayerHDSandBoxHP ) .. "/" .. tostring( PlayerHDSandBoxMaxHp).."#r".."能:"..tostring( PlayerTEP ) .. "/" .. tostring( PlayerMaxTEP).."#r".."共情:"..tostring( PlayerRage ) .. "/" .. tostring( PlayerMaxRage);
			end
		end
	end
	if( type == 1 )	then
		PlayerFrame_HP:SetToolTip( strTooltip );
	elseif( type == 2 ) then
		PlayerFrame_MP:SetToolTip( strTooltip );
	elseif(type == 3) then
		PlayerFrame_SP:SetToolTip( strTooltip );
	elseif(type == 5) then
		PlayerFrame_GQ:SetToolTip( strTooltip );	
	else
		PlayerFrame_TEP:SetToolTip( strTooltip );
	end

end

function PlayerFrame_HideTooltip()

end

 --女神称号特殊显示
function PlayerFrame_UpdateNvShenShow2DHead()
	if SystemSetup:IsClassic() == 1 then
		PlayerFrame_TypeFrame:SetProperty("SetCurrentImage", "TypeFrame8")  	
		PlayerFrame_TypeFrame_2D:SetProperty("SetCurrentImage", "TypeFrame8")	   	
		PlayerFrame_TypeFrame:Hide()
    	PlayerFrame_TypeFrame_2D:Show()			
   else
    	PlayerFrame_TypeFrame_2D:SetProperty("SetCurrentImage", "TypeFrame8")
  		PlayerFrame_TypeFrame_2D:Show()
   end
   PlayerFrame_SelectCharHeadFrame:SetProperty("Image", "")
   PlayerFrame_Head_Animate:SetProperty("Animate", "")
   PlayerFrame_Head_Animate:Hide()
end

function PlayerFrame_UpdateShow2DHead()

		PlayerFrame_Head_2D:Show()
		--PlayerFrame_Icon_Action:Show()
		PlayerFrame_Head_3D:Hide()
        if SystemSetup:IsClassic() == 1 then
		    PlayerFrame:SetProperty("UnifiedSize", "{{0.000000,276.000000},{0.000000,128.000000}}");
    		PlayerFrame_BG:SetProperty("Image", "set:CommonFrame18 image:PlayerFrame");
	    	PlayerFrame_BG:SetProperty("UnifiedSize", "{{0.000000,233.000000},{0.000000,73.000000}}");
		    PlayerFrame_BG:SetProperty("UnifiedPosition", "{{0.000000,0.000000},{0.000000,2.000000}}");
    		PlayerFrame_Name:SetProperty("UnifiedPosition", "{{0.000000,74.000000},{0.000000,14.000000}}");
	    	PlayerFrame_Level:SetProperty("UnifiedPosition", "{{0.000000,64.000000},{0.000000,56.000000}}");
		    PlayerFrame_DataBack:SetProperty("UnifiedPosition", "{{0.000000,64.000000},{0.000000,29.000000}}");
			PlayerFrame_DoubleHitBack:SetProperty("UnifiedPosition", "{{0.000000,115.000000},{0.000000,61.000000}}");
			PlayerFrame_DaoYi:SetProperty("UnifiedPosition", "{{0.000000,115.000000},{0.000000,61.000000}}");
			PlayerFrame_XingLingDian:SetProperty("UnifiedPosition", "{{0.000000,115.000000},{0.000000,61.000000}}");
			PlayerFrame_ERenSoulHit:SetProperty("UnifiedPosition", "{{0.000000,115.000000},{0.000000,61.000000}}");
	    	PlayerFrame_Captain:SetProperty("UnifiedPosition", "{{0.000000,42.000000},{0.000000,53.000000}}");
            --PlayerFrame_ZhenShouZhengYou:SetProperty("UnifiedPosition", "{{0.000000,2.000000},{0.000000,77.000000}}");
            PlayerFrame_UpdateBtn:SetProperty("UnifiedPosition", "{{0.000000,2.000000},{0.000000,77.000000}}");
			--PlayerFrame_VIPBtn:SetProperty("UnifiedPosition", "{{0.000000,48.000000},{0.000000,77.000000}}");
			PlayerFrame_SongjincansiButton:SetProperty("UnifiedPosition", "{{0.000000,3.000000},{0.000000,101.000000}}")
    		--PlayerFrame_WuLinCharts:SetProperty("UnifiedPosition", "{{0.000000,2.000000},{0.000000,100.000000}}");
			--if PlayerFrame_VIPBtn:IsVisible() then
			--PlayerFrame_YouLongKaBtn:SetProperty("UnifiedPosition", "{{0.000000,71.000000},{0.000000,77.000000}}");
			--else
			PlayerFrame_YouLongKaBtn:SetProperty("UnifiedPosition", "{{0.000000,25.000000},{0.000000,77.000000}}");
			if PlayerFrame_YouLongKaBtn:IsVisible() then
				PlayerFrame_LevelBtn:SetProperty("UnifiedPosition", "{{0.000000,47.000000},{0.000000,77.000000}}");
			else
				PlayerFrame_LevelBtn:SetProperty("UnifiedPosition", "{{0.000000,25.000000},{0.000000,77.000000}}");
			end
			--end
    		PlayerFrame_ChongZhi1:SetProperty("UnifiedPosition", "{{1.000000,-43.000000},{0.000000,12.000000}}");
	    	PlayerFrame_DuiHuan:SetProperty("UnifiedPosition", "{{1.000000,-43.000000},{0.000000,33.000000}}");
	    	--PlayerFrame_InfantCard:SetProperty("UnifiedPosition", "{{0.000000,3.000000},{0.000000,100.000000}}")
        end
	
	PlayerFrame_Update_HeadFrame()
end

--VIP功能按钮
--function PlayerFrame_Update_VIP_Button()
	--PlayerFrame_VIPBtn:Hide()
	--PlayerFrame_VIPBtn2:Hide()

	--K服不显示VIP按钮
	--if (KVKInterface:IsInKVKServer() == 1) then
	--	return
	--end

	--local vipLevel = DataPool:GetVipLevel()
	--if vipLevel == 0 then
		--PlayerFrame_VIPBtn:Hide()
	--elseif vipLevel == -1 then	--未激活
		--PlayerFrame_VIPBtn:Show()
		--PlayerFrame_VIPBtn2:Show()
	--else
		--PlayerFrame_VIPBtn:Show()
		--PlayerFrame_VIPBtn2:Hide()
	--end

    --PlayerFrame_UpdateShow2DHead()
--end

--function PlayerFrame_VIP_Clicked()
	--local vipLevel = DataPool:GetVipLevel()
	--if vipLevel == 0 then	--不可能显示VIP按钮的，咋会触发点击事件呢~~
		--PlayerFrame_VIPBtn:Hide()
		--PlayerFrame_VIPBtn2:Hide()
	--else
		--PushEvent("OPEN_VIP_SHOP", vipLevel)
		--PlayerFrame_VIPBtn2:Hide()
	--end
--end

function PlayerFrame_YouLongKa_Clicked()
   PlayerFrame_YouLongKaBtn2:Hide()
   Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("StopBtnFlash")  --脚本接口
		Set_XSCRIPT_ScriptID(889678) --脚本编号
		Set_XSCRIPT_ParamCount(0)
   Send_XSCRIPT()

   if "PlayerFrame" == GetFreshManGuideOwner() then
        CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
   end

   if nIsWeekOrMonthCard == 0 then  --当前使用的是周卡
	   AskYoulongkaInfo()
   else                             --当前使用的是月卡
	   Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetMonthCardInfo")  --脚本接口
			Set_XSCRIPT_ScriptID(889678) --脚本编号
			Set_XSCRIPT_ParamCount(0)
       Send_XSCRIPT()
   end
end

--随身兑换元宝
function PlayerFrame_SuiShenExangeyuanbao()
	   local bflg =YuanbaoExange()
	   if bflg~= 1 then
	  	 return ;
	   end
		Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("AskOpenDuihuanWindow");
		Set_XSCRIPT_ScriptID(181000);
		--Set_XSCRIPT_Parameter(2,shopB);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end

--function PlayerFrame_WuLinCharts_Clicked()
	--JDZY_120806_875
	--local menpai = Player:GetData("MEMPAI");
	--if menpai >= 0 and menpai <= 11 and menpai ~= 9 then
		--Lua_ToggleFengyunlu()
		--PlayerFrame_WuLinChartsFlash:Hide()
		--CloseFreshManGuide()
		--CloseWindow("Exchange" ,true)
		--Clear_XSCRIPT()
			--Set_XSCRIPT_Function_Name("OnClientBnClicked")  --脚本接口
			--Set_XSCRIPT_ScriptID(290099) --脚本编号
			--Set_XSCRIPT_ParamCount(0)
		--Send_XSCRIPT()
	--else
		--PushDebugMessage("#{JDZY_120806_875}")
	--end

--end

function PlayerFrame_ZhizunhaoliClick()

	CloseFreshManGuide()
	local nNumber = Player:GetData( "LEVEL" );
	if( nNumber < 15 ) then
		PushDebugMessage("#{ZZQH_140606_04}")
		return
	end
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ClientAskOpenFrame");
		Set_XSCRIPT_ScriptID(890890);
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT();		
end


function PlayerFrame_InfantCard_Click()

	-- CloseFreshManGuide()
	-- PlayerFrame_InfantCard_Flashdown()
	
	-- local nNumber = Player:GetData( "LEVEL" );
	-- if( nNumber < 15 ) then	
		-- PushDebugMessage("#{ZNHK_151201_05}")
		-- return
	-- end

	-- Clear_XSCRIPT()
		-- Set_XSCRIPT_Function_Name( "OpenInfantCardGift" )
		-- Set_XSCRIPT_ScriptID( 891726 )
		-- Set_XSCRIPT_ParamCount(0)
	-- Send_XSCRIPT()
end

function PlayerFrame_InfantCard_Flashdown()
	-- PlayerFrame_InfantCardFlash:Hide();
	-- KillTimer("PlayerFrame_InfantCard_Flashdown()");
end



function PlayerFrame_OnJincansiClick()

end

function PlayerFrame_Jincansi_StartFlash()

end

function PlayerFrame_Jincansi_Flashdown()
end

--消费返卡牌升阶道具
--function PlayerFrame_BaoDianZJH2Click()

--	CloseFreshManGuide()
--	PlayerFrame_BaoDianZJHB2Flashdown()
	
--	local nNumber = Player:GetData( "LEVEL" );
--	if( nNumber < 15 ) then	
--		PushDebugMessage("#{KPLS_150527_5}")
--		return
--	end
	
--	Clear_XSCRIPT()
--		Set_XSCRIPT_Function_Name( "OpenMingYangSHUI" )
--		Set_XSCRIPT_ScriptID( 891141 )
--		Set_XSCRIPT_ParamCount(0)
--	Send_XSCRIPT()

--end

--function PlayerFrame_BaoDianZJHB2Flashdown()
--	PlayerFrame_BaoDianZJHB2Flash:Hide();
--	KillTimer("PlayerFrame_BaoDianZJHB2Flashdown()");
--end

function PlayerFrame_Update_HeadFrame()

	if Player:GetData("HEADFRAMEID") == 2 then
		PlayerFrame_UpdateNvShenShow2DHead()
		return	
	end
	
	local MyHeadFrameType = Player:GetData("HEADFRAMETYPE")
	if MyHeadFrameType == 1 then
		PlayerFrame_SelectCharHeadFrame:SetProperty("Image", "")
		PlayerFrame_SelectCharHeadFrame:Hide()
		
		PlayerFrame_Head_Animate:Show()
		local MyHeadFrameAnimate = Player:GetData("HEADFRAMEANIMATE")
		PlayerFrame_Head_Animate:SetProperty("Animate", tostring(MyHeadFrameAnimate))
	else
		PlayerFrame_Head_Animate:SetProperty("Animate", "")
		PlayerFrame_Head_Animate:Hide()

		PlayerFrame_SelectCharHeadFrame:Show()
		local MyHeadFrameImage = Player:GetData("HEADFRAMEIMAGE")
		local IconFile = GetIconFullName(MyHeadFrameImage)
		PlayerFrame_SelectCharHeadFrame:SetProperty("Image", IconFile)
	end
	PlayerFrame_TypeFrame_2D:Hide()
end

function PlayerFrame_UpdateJuHunImage()
	local selfMenpai = Player:GetData("MEMPAI")
	if selfMenpai ~= 15 or TLCJ:IsInTLCJScene() > 0 then
		for x=1,3 do   	
			g_ERenGuUI[x].UI:Hide()		
		end
		return
	end	
	
	for x=1,3 do
		local lifeTime = Player:CheckBuffImpactExist(g_ERenGuUI[x].impactId)
		g_ERenGuUI[x].UI:Show()
		if(lifeTime ~= nil and lifeTime > 0) then
			g_ERenGuUI[x].UI:SetProperty("Image", g_ERenGuUI[x].brightImage)
			g_ERenGuUI[x].UI:SetToolTip(g_ERenGuUI[x].brightToolTip)
		else
			g_ERenGuUI[x].UI:SetProperty("Image", g_ERenGuUI[x].grayImage)
			g_ERenGuUI[x].UI:SetToolTip(g_ERenGuUI[x].grayToolTip)
		end
	end
end


function PlayerFrame_UpdateGuiguPoint()
	local buffExist = Player:CheckBuffImpactExist(9127)
	local ggpt = Player:GetData( "GUIGUPOINT" )
	if(buffExist ~= nil and buffExist > 0) then
		ggpt = ggpt + 1
	end
	local pMenpai = Player:GetData("MEMPAI");	
	if ggpt == nil then
		return
	end
	
	for	x=1, 3 do
		if x <= ggpt and pMenpai == 12 then
			GuiguPoint[x]:SetProperty("Image","set:CommonFrame39 image:GGJG_XLD2")
			if(buffExist ~= nil and buffExist > 0 and x == ggpt) then
				GuiguPoint[x]:SetProperty("Image","set:CommonFrame39 image:GGJG_XLD3")
			end
			GuiguPoint[x] : Show()
		else
			GuiguPoint[x] : Hide()
		end
	end
end

function PlayerFrame_Level_Clicked()
	PushEvent("OPEN_2606S_HELP")
end