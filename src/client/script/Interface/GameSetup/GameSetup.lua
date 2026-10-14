local g_PreAlpha = "0.8";
local g_Track_PreAlpha = "1.0";

--- 保存当前设置
local curGameSetupBackup = {}

--===============================================
-- PreLoad()
--===============================================
function GameSetup_PreLoad()

	this:RegisterEvent("TOGLE_GAMESETUP",true);

	this:RegisterEvent("TOGLE_INPUTSETUP",false);
	this:RegisterEvent("TOGLE_SYSTEMFRAME",false);
	this:RegisterEvent("TOGLE_SOUNDSETUP",false);
	this:RegisterEvent("TOGLE_VIEWSETUP",false);
	this:RegisterEvent("TOGLE_CONTROLMODE",false)
	this:RegisterEvent("SHOW_TRANSFIGURATION_SKILL",true);

	this:RegisterEvent("CHANGE_GAME_SETUP",false);
	this:RegisterEvent("CLOSE_SETUP_WINDOW",false);

	--TiuSong - 唯美版配置
	this:RegisterEvent("TOGLE_VIEWSETUP_WM",false);
	this:RegisterEvent("TOGLE_INPUTSETUP_WM",false)
end

--===============================================
-- OnLoad()
--===============================================
function GameSetup_OnLoad()
	GameSetup_ChatBkg_Slider:SetProperty( "DocumentSize","1" );
	GameSetup_ChatBkg_Slider:SetProperty( "PageSize","0.1" );
	GameSetup_ChatBkg_Slider:SetProperty( "StepSize","0.1" );
	GameSetup_TrackBkg_Slider:SetProperty( "DocumentSize","1" );
	GameSetup_TrackBkg_Slider:SetProperty( "PageSize","0.0" );
	GameSetup_TrackBkg_Slider:SetProperty( "StepSize","0.1" );
end

--===============================================
-- OnEvent()
--===============================================
function GameSetup_OnEvent(event)

	if ( event == "TOGLE_GAMESETUP" ) then
		local setupUnionPos = Variable:GetVariable("SetupUnionPos");
		if(setupUnionPos ~= nil) then
			GameSetup_Frame:SetProperty("UnifiedPosition", setupUnionPos);
		end

        --- 每次打开该界面，都先对当前显示设置进行一下备份
        GameSetup_Save_Cur_Setup()

		GameSetup_MenuButtons_Reset()
		this:Show();
		local old = {SystemSetup:GameGetData()};
		g_PreAlpha = tostring(old[10]);
		g_Track_PreAlpha = tostring(old[17]);
		GameSetup_UpdateFrame();

        --- 设置没有任何数据的修改
        GameSetup_Set_Setup_UnChanged()

	elseif(event == "TOGLE_VIEWSETUP" and this:IsVisible()) then
		SystemSetup:SetIsConfigChanged( 0 )
		GameSetup_Cancel_Clicked();
	elseif(event == "TOGLE_VIEWSETUP_WM" and this:IsVisible()) then
		SystemSetup:SetIsConfigChanged( 0 )
		GameSetup_Cancel_Clicked();

	elseif(event == "TOGLE_SYSTEMFRAME" and this:IsVisible()) then
        SystemSetup:SetIsConfigChanged( 0 )
		GameSetup_Cancel_Clicked();

	elseif(event == "TOGLE_SOUNDSETUP" and this:IsVisible()) then
        SystemSetup:SetIsConfigChanged( 0 )
		GameSetup_Cancel_Clicked();

	elseif(event == "TOGLE_INPUTSETUP" and this:IsVisible() ) then
        SystemSetup:SetIsConfigChanged( 0 )
		GameSetup_Cancel_Clicked();
	elseif(event == "TOGLE_INPUTSETUP_WM" and this:IsVisible()) then
		SystemSetup:SetIsConfigChanged( 0 )
		GameSetup_Cancel_Clicked()

	elseif (event == "TOGLE_CONTROLMODE") then
		SystemSetup:SetIsConfigChanged( 0 )
		GameSetup_Cancel_Clicked()

	elseif event == "SHOW_TRANSFIGURATION_SKILL" then
		if arg0 == "2" then
			GameSetup_FunctionBar_2:SetCheck(0)
			GameSetup_FunctionBar_2:Disable()
			GameSetup_FunctionBar_3:SetCheck(0)
			GameSetup_FunctionBar_3:Disable()
		elseif arg0 == "0" then
			local n1,n2,n3,n4,n5,n6,n7,n8,n9,f10,n11,n12,n13,n14,n15,n16,f17,n18,n19,n20,n21,n22,n23,n24,n25,n26,n27,n28,n29,n30,n31,n32,n33,n34,n35,n36,n37,n38,n39 = SystemSetup:GameGetData();
			GameSetup_FunctionBar_2:Enable()
			GameSetup_FunctionBar_2:SetCheck(n24)
			GameSetup_FunctionBar_3:Enable()
			GameSetup_FunctionBar_3:SetCheck(n28)
		end
	elseif event == "RETRIEVE_GAME_SETUP" then
        GameSetup_Retrieve_Setup()
    elseif event == "CHANGE_GAME_SETUP" then
        if ( tonumber(arg0) == 0 ) then
            GameSetup_YingYong_Clicked()
        else
            GameSetup_Retrieve_Setup()
        end
    elseif event == "CLOSE_SETUP_WINDOW" then
        this:Hide()
	end

end


--===============================================
-- UpdateFrame()
--===============================================
function GameSetup_UpdateFrame()

	local n1,n2,n3,n4,n5,n6,n7,n8,n9,f10,n11,n12,n13,n14,n15,n16,f17,n18,n19,n20,n21,n22,n23,n24,n25,n26,n27,n28,n29,n30,n31,n32,n33,n34,n35,n36,n37,n38,n39 = SystemSetup:GameGetData();

	GameSetup_Item1					:SetCheck(n1);				-- 拒绝所有信件
	GameSetup_Item2					:SetCheck(n2);				-- 拒绝加我好友
	GameSetup_Item3					:SetCheck(n3);				-- 拒绝默认生信件
	GameSetup_Item4					:SetCheck(n4);				-- 拒绝交易
	GameSetup_Item5					:SetCheck(n5);				-- 拒绝队伍邀请
	GameSetup_Item6					:SetCheck(n6);				-- 关闭当前泡泡框
	GameSetup_Item7					:SetCheck(n7);				-- 拒绝查看配偶
	GameSetup_Item8					:SetCheck(n8);				-- 角色显示帽子
	GameSetup_Item9					:SetCheck(n9);				-- 非聊天模式
	GameSetup_ChatBkg_Slider		:SetPosition(f10);			-- 聊天背景透明度
	GameSetup_Item11				:SetCheck(n11);				-- 关闭快捷栏提示
	GameSetup_Lock					:SetCheck(n12);				-- 锁定快捷栏
																-- 关闭玩家的时装显示
	GameSetup_ChatItem				:SetCheck(n15);				-- 快捷键查看链接
	GameSetup_TeamFollow			:SetCheck(n16);				-- 自动接受组队跟随
	GameSetup_TrackBkg_Slider		:SetPosition(f17);			-- 任务活动追踪背景透明度
	GameSetup_Item12				:SetCheck(n18);				-- 拒绝聊天动作
	GameSetup_EquipCompare			:SetCheck(n19);				--装备比较
	GameSetup_EquipCompareAttr		:SetCheck(n20);				--装备属性比较
---	GameSetup_DynamicView			:SetCheck(n21);				-- 拒绝给别人发送SNS信息
---	GameSetup_DynamicRemind			:SetCheck(n22);				-- 拒绝接受SNS
	GameSetup_ClosePetPaoPao		:SetCheck(n23);				-- 关闭珍兽泡泡
	GameSetup_FunctionBar_2			:SetCheck(n24);				--开启右边第二动作条
	GameSetup_FunctionBar_3			:SetCheck(n28)
	if DataPool:GetTrans() == 1 then
		GameSetup_FunctionBar_2:SetCheck(0) ;
		GameSetup_FunctionBar_2:Disable()
		GameSetup_FunctionBar_3:SetCheck(0)
		GameSetup_FunctionBar_3:Disable()
	end
	--GameSetup_CloseSceneView:SetCheck(n25);     --摄像机漫游开关
	--GameSetup_2DHead:SetCheck(n26);						--2D头像模式
	-- GameSetup_MenPaiJinJie:SetCheck(n27)   --门派进阶动作
	GameSetup_HuoDongTiShi:SetCheck(n29)
	GameSetup_WeaponOnBack:SetCheck(n30)
	GameSetup_cooltime:SetCheck(n31)
	GameSetup_leverup:SetCheck(n32)

	GameSetup_Aggregate:SetCheck(n33)
	--GameSetup_ShowNotice:SetCheck(n34)
	GameSetup_BugSubmit:SetCheck(n35)
	
	---GameSetup_AciontSet:SetCheck(n36)
	
	GameSetup_FlyRide:SetCheck(n37)
	GameSetup_AutoMount:SetCheck(n38)
	GameSetup_Important:SetCheck(n39)

	--唯美版中隐藏"聊天模式"设置项,由操作模式界面控制,仅经典版可用
	--唯美版中不在区分进阶动作和普通动作,统一为一套动作
	if 0 == SystemSetup:IsClassic() then
		GameSetup_Item9_Text:Hide()
		GameSetup_Item9:Hide()
		GameSetup_Scene_MenPaiJinJie_Text:Hide()
		-- GameSetup_MenPaiJinJie:Hide()
	else
		GameSetup_WeaponOnBack:Hide()
		GameSetup_WeaponOnBack_Text:Hide()
	end
end

--===============================================
-- GameSetup_Accept
-- 确定
--===============================================
function GameSetup_Accept_Clicked()
	GameSetup_YingYong_Clicked()
	this:Hide();
end

--===============================================
-- GameSetup_Cancel
-- 取消
--===============================================
function GameSetup_Cancel_Clicked()

	GameSetup_ChatBkg_Slider:SetPosition(g_PreAlpha);
	Talk:HandleMainBarAction("chatbkg",g_PreAlpha);
	DataPool:HandleGameSetupAction(g_Track_PreAlpha);

    GameSetup_Close_Clicked()

end

--===============================================
-- GameSetup_DefaultSetting
-- 恢复默认
--===============================================
function GameSetup_Default_Clicked()

	GameSetup_Item1						:SetCheck(0);							-- 拒绝所有信件
	GameSetup_Item2						:SetCheck(0);             -- 拒绝加我好友
	GameSetup_Item3						:SetCheck(1);             -- 拒绝默认人信件
	GameSetup_Item4						:SetCheck(0);             -- 拒绝交易
	GameSetup_Item5						:SetCheck(0);             -- 拒绝队伍邀请
	GameSetup_Item6						:SetCheck(0);             -- 关闭当前泡泡框
	GameSetup_Item7						:SetCheck(0);             -- 拒绝查看配偶
	GameSetup_Item8						:SetCheck(0);             -- 角色显示帽子
	GameSetup_Item9						:SetCheck(0);             -- 非聊天模式
	GameSetup_ChatBkg_Slider	:SetPosition(1);       		-- 聊天背景透明度
	GameSetup_Item11					:SetCheck(0);							-- 关闭快捷栏提示
	GameSetup_Lock						:SetCheck(0);             -- 锁定快捷栏
	GameSetup_ChatItem				:SetCheck(0);             -- 快捷键查看链接
	GameSetup_TeamFollow			:SetCheck(0);							-- 自动接受组队跟随
	GameSetup_TrackBkg_Slider	:SetPosition(1);					-- 任务活动追踪背景透明度
	GameSetup_Item12					:SetCheck(0);							-- 拒绝聊天动作
	GameSetup_EquipCompare		:SetCheck(1) ;
	GameSetup_EquipCompareAttr	:SetCheck(1);				--装备属性比较
	---GameSetup_DynamicView:SetCheck(0);
	---GameSetup_DynamicRemind:SetCheck(0);
	GameSetup_ClosePetPaoPao:SetCheck(0);							-- 关闭珍兽泡泡
	GameSetup_FunctionBar_2:SetCheck(0)
	GameSetup_FunctionBar_3:SetCheck(0)
	--GameSetup_CloseSceneView:SetCheck(0)							-- 摄像机漫游
	--GameSetup_2DHead:SetCheck(1)											-- 2D头像模式
	-- GameSetup_MenPaiJinJie:SetCheck(0)                       --门派进阶动作显示
	GameSetup_HuoDongTiShi:SetCheck(1)                          --限时活动提示
	GameSetup_cooltime:SetCheck(0)
	GameSetup_leverup:SetCheck(0)

	GameSetup_Aggregate:SetCheck(1)      --夫妻时装特效
	--GameSetup_ShowNotice:SetCheck(1)
	GameSetup_BugSubmit:SetCheck(1)
	---GameSetup_AciontSet:SetCheck(1)
	GameSetup_FlyRide:SetCheck(0)
	GameSetup_AutoMount:SetCheck(1)
	GameSetup_Important:SetCheck(0)
	
    GameSetup_Set_Setup_Changed()
end

--===============================================
-- GameSetup_ChatBkg_Slider
-- 设置聊天背景透明度
--===============================================
function GameSetup_ChatBkg_Change()
	local pos = GameSetup_ChatBkg_Slider:GetPosition();
	Talk:HandleMainBarAction("chatbkg",pos);
    GameSetup_Set_Setup_Changed()
end

function GameSetup_TrackBkg_Change()
	local pos = GameSetup_TrackBkg_Slider:GetPosition();
	DataPool:HandleGameSetupAction(pos);
    GameSetup_Set_Setup_Changed()
end

function GameSetup_ViewSetup_Clicked()
	Variable:SetVariable("SetupUnionPos", GameSetup_Frame:GetProperty("UnifiedPosition"), 1);

    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 2, 0, "#{XTSZYH_111220_05}" )
    else
        SystemSetup:ViewSetup()
    end

end

function GameSetup_SoundSetup_Clicked()
	Variable:SetVariable("SetupUnionPos", GameSetup_Frame:GetProperty("UnifiedPosition"), 1);

    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 2, 1, "#{XTSZYH_111220_05}" )
    else
        SystemSetup:SoundSetup();
    end

end

function GameSetup_GameSetup_Clicked()

end

function GameSetup_AcceSetup_Clicked()
	Variable:SetVariable("SetupUnionPos", GameSetup_Frame:GetProperty("UnifiedPosition"), 1);

    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 2, 3, "#{XTSZYH_111220_05}" )
    else
        SystemSetup:InputSetup();
    end

end

function GameSetup_WASD_Clicked()

	Variable:SetVariable("SetupUnionPos", GameSetup_Frame:GetProperty("UnifiedPosition"), 1);
    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 2, 4, "#{XTSZYH_111220_05}" )
    else
        SystemSetup:ControlModeSetup();
    end
end

function GameSetup_MenuButtons_Reset()
	GameSetup_MenuBox_ViewSetup	:SetCheck(0)
	GameSetup_MenuBox_SoundSetup:SetCheck(0)
	GameSetup_MenuBox_GameSetup	:SetCheck(1)
	GameSetup_MenuBox_AcceSetup	:SetCheck(0)
    if SystemSetup:IsClassic() == 0 then
    	GameSetup_MenuBox_WASD:SetCheck(0)
    else
		GameSetup_MenuBox_WASD:Hide()
	end
end

function GameSetup_YingYong_Clicked()
    if 0 == SystemSetup:GetIsConfigChanged( ) then
        return
    end

    local n1,n2,n3,n4,n5,n6,n7,n8,n9,f10,n11,n12,n13,n14,n15,n16,f17,n18,n19,n20,n21,n22,n23,n24,n25,n26,n27,n28,n29,n30,n31,n32,n33,n34,n35,n36,n37,n38,n39 = SystemSetup:GameGetData();

	n1 = GameSetup_Item1:GetCheck();									-- 拒绝所有信件
	n2 = GameSetup_Item2:GetCheck();                  -- 拒绝加我好友
	n3 = GameSetup_Item3:GetCheck();                  -- 拒绝默认生信件
	n4 = GameSetup_Item4:GetCheck();                  -- 拒绝交易
	n5 = GameSetup_Item5:GetCheck();                  -- 拒绝队伍邀请
	n6 = GameSetup_Item6:GetCheck();                  -- 关闭当前泡泡框
	n7 = GameSetup_Item7:GetCheck();                  -- 拒绝查看配偶
	n8 = GameSetup_Item8:GetCheck();                  -- 角色显示帽子
	n9 = GameSetup_Item9:GetCheck();                  -- 非聊天模式
	f10 = GameSetup_ChatBkg_Slider:GetPosition();     -- 聊天背景透明度
	n11 = GameSetup_Item11:GetCheck();                -- 关闭快捷栏提示
	n12 = GameSetup_Lock:GetCheck();                  -- 锁定快捷栏
	n15 = GameSetup_ChatItem:GetCheck();              -- 快捷键查看链接
	n16 = GameSetup_TeamFollow:GetCheck();				-- 自动接受组队跟随
	f17 = GameSetup_TrackBkg_Slider:GetPosition();		-- 任务活动追踪背景透明度
	n18 = GameSetup_Item12:GetCheck();					-- 拒绝聊天动作
	n19 = GameSetup_EquipCompare:GetCheck() ;
	n20 = GameSetup_EquipCompareAttr:GetCheck();
	n21 = 0 ---GameSetup_DynamicView:GetCheck();
	n22 = 0 ---GameSetup_DynamicRemind:GetCheck();
	n23 = GameSetup_ClosePetPaoPao:GetCheck();
	if DataPool:GetTrans() ~= 1 then
		n24	= GameSetup_FunctionBar_2:GetCheck()
		n28 = GameSetup_FunctionBar_3:GetCheck()
	end

	--n25 = GameSetup_CloseSceneView:GetCheck()
	n26 = 1 --GameSetup_2DHead:GetCheck()
	n27 = 0 --GameSetup_MenPaiJinJie:GetCheck()  --门派进阶
	n29 = GameSetup_HuoDongTiShi:GetCheck()  --限时活动提示
	n30	= GameSetup_WeaponOnBack:GetCheck()	 --关闭武器背持
	n31 = GameSetup_cooltime:GetCheck()  --冷却计时
	n32 = GameSetup_leverup:GetCheck()  --升级二次确认
	n33 = GameSetup_Aggregate:GetCheck() --夫妻时装特效
	n34 = 0 --GameSetup_ShowNotice:GetCheck()
	n35 = GameSetup_BugSubmit:GetCheck()
	n36 = 0 ----GameSetup_AciontSet:GetCheck()
	n37 = GameSetup_FlyRide:GetCheck()
	n38 = GameSetup_AutoMount:GetCheck()
	n39 = GameSetup_Important:GetCheck()
	SystemSetup:SaveGameSetup ( n1,n2,n3,n4,n5,n6,n7,n8,n9,tonumber(f10),n11,n12,n13,n14,n15,n16,f17, n18,n19,n20,n21,n22,n23,n24,n25,n26,n27,n28,n29,n30,n31,n32,n33,n34,n35,n36,n37,n38,n39 );

	g_PreAlpha = f10;
	g_Track_PreAlpha = f17;

    GameSetup_YingYong:Disable()
    SystemSetup:SetIsConfigChanged( 0 )

    PushDebugMessage( "#{XTSZYH_111220_10}" )
end

function GameSetup_Save_Cur_Setup()
    curGameSetupBackup[1],
    curGameSetupBackup[2],
    curGameSetupBackup[3],
    curGameSetupBackup[4],
    curGameSetupBackup[5],
    curGameSetupBackup[6],
    curGameSetupBackup[7],
    curGameSetupBackup[8],
    curGameSetupBackup[9],
    curGameSetupBackup[10],
    curGameSetupBackup[11],
    curGameSetupBackup[12],
    curGameSetupBackup[13],
    curGameSetupBackup[14],
    curGameSetupBackup[15],
    curGameSetupBackup[16],
    curGameSetupBackup[17],
    curGameSetupBackup[18],
    curGameSetupBackup[19],
    curGameSetupBackup[20],
    curGameSetupBackup[21],
    curGameSetupBackup[22],
    curGameSetupBackup[23],
    curGameSetupBackup[24],
    curGameSetupBackup[25],
    curGameSetupBackup[26],
    curGameSetupBackup[27],
    curGameSetupBackup[28],
	curGameSetupBackup[29],
	curGameSetupBackup[30],
	curGameSetupBackup[31],
	curGameSetupBackup[32],
	curGameSetupBackup[33], 
	curGameSetupBackup[34], 
	curGameSetupBackup[35],
	curGameSetupBackup[36],
	curGameSetupBackup[37],
	curGameSetupBackup[38],
	curGameSetupBackup[39] = SystemSetup:GameGetData()
end

function GameSetup_Retrieve_Setup()
    SystemSetup:SaveGameSetup(
    curGameSetupBackup[1],
    curGameSetupBackup[2],
    curGameSetupBackup[3],
    curGameSetupBackup[4],
    curGameSetupBackup[5],
    curGameSetupBackup[6],
    curGameSetupBackup[7],
    curGameSetupBackup[8],
    curGameSetupBackup[9],
    curGameSetupBackup[10],
    curGameSetupBackup[11],
    curGameSetupBackup[12],
    curGameSetupBackup[13],
    curGameSetupBackup[14],
    curGameSetupBackup[15],
    curGameSetupBackup[16],
    curGameSetupBackup[17],
    curGameSetupBackup[18],
    curGameSetupBackup[19],
    curGameSetupBackup[20],
    curGameSetupBackup[21],
    curGameSetupBackup[22],
    curGameSetupBackup[23],
    curGameSetupBackup[24],
    curGameSetupBackup[25],
    curGameSetupBackup[26],
    curGameSetupBackup[27],
    curGameSetupBackup[28],
    curGameSetupBackup[29],
	curGameSetupBackup[30],
	curGameSetupBackup[31],
	curGameSetupBackup[32],
	curGameSetupBackup[33],
	curGameSetupBackup[34],
	curGameSetupBackup[35],
	curGameSetupBackup[36],
	curGameSetupBackup[37],
	curGameSetupBackup[38],
	curGameSetupBackup[39])
end

function GameSetup_Set_Setup_Changed()
    SystemSetup:SetIsConfigChanged( 1 )
	GameSetup_YingYong:Enable()
end

function GameSetup_Close_Clicked()
    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 2, -1, "#{XTSZYH_111220_05}" )
    else
        this:Hide()
    end
end

--- index 这里只是提供个接口便于以后扩展而已
function GameSetup_CheckSetting_Clicked(index)
    GameSetup_Set_Setup_Changed()
end

function GameSetup_Set_Setup_UnChanged()
    --- 设置当前没有任何修改
    SystemSetup:SetIsConfigChanged( 0 )
	--- 灰化掉应用按钮
	GameSetup_YingYong:Disable()
end

