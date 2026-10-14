-- [段位商店] add by DuanXiaoTong_2015/04/13
-- PushDebugMessage
-- ScriptGlobal_Format
-- !!!reloadscript =Sancai_s
---------------------------------------------------------------------------
local g_Controls = {};						-- 控件
local g_nFBStage = -1;						-- 副本阶段
local g_bMini = 0;							-- 是否打开mini界面
local g_TransferSection = {					-- 副本章节转换(章节0~5)
	[ 0 ] 	= { nSection = 0, nIndex = -1, Tip = "" };
	[ 1 ] 	= { nSection = 0, nIndex = -1, Tip = "" };
	[ 2 ] 	= { nSection = 1, nIndex = 01, Tip = "#{LSHDR_150203_104}" };
	[ 3 ] 	= { nSection = 1, nIndex = 02, Tip = "#{LSHDR_150203_105}" };
	[ 4 ] 	= { nSection = 1, nIndex = 03, Tip = "#{LSHDR_150203_106}" };
	[ 5 ] 	= { nSection = 1, nIndex = 04, Tip = "#{LSHDR_150203_107}" };
	[ 6 ] 	= { nSection = 1, nIndex = 05, Tip = "#{LSHDR_150203_108}" };
	[ 7 ] 	= { nSection = 2, nIndex = 01, Tip = "#{LSHDR_150203_111}" };
	[ 8 ] 	= { nSection = 2, nIndex = 02, Tip = "#{LSHDR_150203_112}" };
	[ 9 ] 	= { nSection = 3, nIndex = 01, Tip = "#{LSHDR_150203_115}" };
	[ 10 ] 	= { nSection = 4, nIndex = -1, Tip = "" };
	[ 11 ] 	= { nSection = 5, nIndex = -1, Tip = "" };
};
local g_Position = "{{1.000000,-300.000000},{1.000000,-500.000000}}";
---------------------------------------------------------------------------


--*********************************
-- PreLoad
--*********************************
function Sancai_s_PreLoad()
	this : RegisterEvent( "UI_COMMAND" );								-- UI_COMMAND
	this : RegisterEvent( "OPEN_SINGLESANCAIXIAGU_ORIGINAL_UI" );		-- mini窗口
	this : RegisterEvent( "ADJEST_UI_POS" );							-- 窗口改变
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED" );					-- 游戏分辨率发生了变化
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED" );						-- 离开场景
end


--*********************************
-- OnLoad
--*********************************
function Sancai_s_OnLoad()
	--
	g_Controls = {
		-- 框架
		Framework = Sancai_s_Frame;
		-- 章节
		Sections = {
			[ 1 ] = {
				-- 背景
				BackGround = Sancai_s_BK1;
				-- 任务
				Mission = {
					[ 1 ] = Sancai_s_Image1Info2;
					[ 2 ] = Sancai_s_Image1Info3;
					[ 3 ] = Sancai_s_Image1Info4;
					[ 4 ] = Sancai_s_Image1Info5;
					[ 5 ] = Sancai_s_Image1Info6;
				};
			};
			[ 2 ] = {
				-- 背景
				BackGround = Sancai_s_BK2;
				-- 任务
				Mission = {
					[ 1 ] = Sancai_s_Image2Info2;
					[ 2 ] = Sancai_s_Image2Info3;
				};
			};
			[ 3 ] = {
				-- 背景
				BackGround = Sancai_s_BK3;
				-- 任务
				Mission = {
					[ 1 ] =Sancai_s_Image3Info2;
				};
			};
		};
	};
end


--*********************************
-- OnEvent
--*********************************
function Sancai_s_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber( arg0 ) == 40212301 ) then
		--
		g_nFBStage = tonumber( Get_XParam_INT( 0 ) );
		local nKillObjNum = tonumber( Get_XParam_INT( 1 ) );
		local leftTime = Get_XParam_INT( 2 )
		if ( g_nFBStage ~=-1 and nKillObjNum ) then
			--
			Sancai_s_OnUpdateUIData( g_nFBStage, nKillObjNum, leftTime );
		end
	elseif ( event == "OPEN_SINGLESANCAIXIAGU_ORIGINAL_UI" ) then
		g_bMini = 0;
		this:Show();
	elseif ( event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 恢复默认位置
		g_Controls.Framework:SetProperty( "UnifiedPosition", g_Position );
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		--
		g_bMini = 0;
		this:Hide();
	end
end


--*********************************
-- 清空控件
--*********************************
function Sancai_s_CleanupUIControls()
	-- 背景
	g_Controls.Sections[ 1 ].BackGround:Hide();
	g_Controls.Sections[ 2 ].BackGround:Hide();
	g_Controls.Sections[ 3 ].BackGround:Hide();
	-- 第一章: 任务
	g_Controls.Sections[ 1 ].Mission[ 1 ]:SetText( ScriptGlobal_Format( g_TransferSection[ 2 ].Tip, 0 ) );
	g_Controls.Sections[ 1 ].Mission[ 2 ]:SetText( ScriptGlobal_Format( g_TransferSection[ 3 ].Tip, 0 ) );
	g_Controls.Sections[ 1 ].Mission[ 3 ]:SetText( ScriptGlobal_Format( g_TransferSection[ 4 ].Tip, 0 ) );
	g_Controls.Sections[ 1 ].Mission[ 4 ]:SetText( ScriptGlobal_Format( g_TransferSection[ 5 ].Tip, 0 ) );
	g_Controls.Sections[ 1 ].Mission[ 5 ]:SetText( ScriptGlobal_Format( g_TransferSection[ 6 ].Tip, 0 ) );
	-- 第二章: 任务
	g_Controls.Sections[ 2 ].Mission[ 1 ]:SetText( ScriptGlobal_Format( g_TransferSection[ 7 ].Tip, 0 ) );
	g_Controls.Sections[ 2 ].Mission[ 2 ]:SetText( ScriptGlobal_Format( g_TransferSection[ 8 ].Tip, 0 ) );
	-- 第三章: 任务
	g_Controls.Sections[ 3 ].Mission[ 1 ]:SetText( ScriptGlobal_Format( g_TransferSection[ 9 ].Tip, 0 ) );
end


--*********************************
-- 更新界面
--*********************************
function Sancai_s_OnUpdateUIData( nFBStage, nKillObjNum, leftTime )
	-- 参数
	if ( nFBStage == nil or nKillObjNum == nil or leftTime == nil) then
		return
	end
	-- 副本阶段 转换 副本章节
	if ( nFBStage < 0 or nFBStage > table.getn( g_TransferSection ) ) then
		return
	end

	-- 章节
	local nSection = g_TransferSection[ nFBStage ].nSection;
	if ( nSection == 0 ) then
		-- 清除界面数据
		Sancai_s_CleanupUIControls();
	elseif ( nSection >= 1 and nSection <= 3 ) then
		-- 显示章节
		for i = 1, table.getn( g_Controls.Sections ) do
			if ( i == nSection ) then
				g_Controls.Sections[ i ].BackGround:Show();
			else
				g_Controls.Sections[ i ].BackGround:Hide();
			end
		end
		-- 任务
		local nIndex = g_TransferSection[ nFBStage ].nIndex;
		if ( nIndex < 1 or nIndex > table.getn( g_Controls.Sections[ nSection ].Mission ) ) then
			return
		end
		local Tip = ScriptGlobal_Format( g_TransferSection[ nFBStage ].Tip, nKillObjNum );
		g_Controls.Sections[ nSection ].Mission[ nIndex ]:SetText( Tip );
		-- 显示界面
		if ( g_bMini == 0 ) then
			this:Show();
		elseif ( g_bMini == 1 ) then
			PushEvent( "OPEN_SINGLESANCAIXIAGU_MINI_UI", 1, nSection );
		end
	elseif ( nSection == 4 ) then
		--
	elseif ( nSection == 5 ) then
		-- 隐藏界面
		g_bMini = 0;
		this:Hide();
	end
	
	-- 倒计时
	if leftTime > 0 then
		Sancai_s_StopWatchText:SetText( "#{LSHDR_150203_124}" )
		Sancai_s_StopWatch:SetProperty("Timer", tostring(leftTime))
	else
		Sancai_s_StopWatchText:SetText( "" )
		Sancai_s_StopWatch:SetProperty("Timer", tostring(0))
	end
end


--==========================================================================--
-- 响应事件
--==========================================================================--
--*********************************
-- 最小化
--*********************************
function Sancai_s_Frame_Mini_Clicked()
	-- 章节
	if ( g_nFBStage >= 1 and g_nFBStage <= table.getn( g_TransferSection ) ) then
		local nSection = g_TransferSection[ g_nFBStage ].nSection;
		if ( nSection >= 1 and nSection <= 3 ) then
			PushEvent( "OPEN_SINGLESANCAIXIAGU_MINI_UI", 1, nSection );
		elseif ( nSection > 3 ) then
			PushEvent( "OPEN_SINGLESANCAIXIAGU_MINI_UI", 1, 3 );
		end
		g_bMini = 1;
		this:Hide();
	end
end

--*********************************
-- 计时结束
--*********************************
function Sancai_s_TimeOut()
	Sancai_s_StopWatchText:SetText( "" )
	Sancai_s_StopWatch:SetProperty("Timer", tostring(0))
end

