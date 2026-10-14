local g_NewBangHui_RankingList_Frame_UnifiedPosition;
local g_positionInfo = {
	"#G待批准　",
	"帮众　　",
	"精英　　",
	"商人　　",
	"弘化使　",
	"工务使　",
	"内务使　",
	"副帮主　",
	"帮主　　",
};

local g_xzTypeInfo = {
	"(宣战)",
	"(应战)", 
};

local g_GuildIndex = -1 --当前选中的帮会 

local g_NewBangHui_RankingList_Button = {
}

local g_NewBangHui_RankingList_ServerButton = {
}

local g_CtrlNewBanHui_RL ={
}

local g_NewBangHui_RankingList_LaceButton = {
}
local g_CurSearchType = -1 --当前选中的哪一方 敌方 己方
local g_CurServerTYpe = -1 --当前查看的是哪个服  k服 还是 原服
local g_ButtonLastTime= 0;
local g_ButtonCDTime 	= 2; --按钮冷却时间
local g_ButtonNum 		= 6; --按钮最大数量
local g_ButtonNum_K 	= 2; --按钮冷却时间
local g_NormalServer 	= 0; --本服
local g_KServer 			= 1; --K服
local g_CurSearchSelf	= 1; --己方
local g_CurSearchRival= 2; --敌方

--===============================================
-- PreLoad()
--===============================================
function NewBangHui_RankingList_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)											-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)														-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        				-- 游戏分辨率发生了变化    
	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED" )									-- 进入游戏世界
	this:RegisterEvent("NEW_BANGHUI_XZRL_OPEN" )									--                 
	this:RegisterEvent("GUILD_SHOW_GUILDBATTLERANKLIST" )					--                 
	this:RegisterEvent("GUILD_SHOW_GUILDBATTLERANKLIST_RIVAL" )		--                 
	this:RegisterEvent("GUILD_UPDATE_GUILDBATTLERANKLIST" )				--                 
	this:RegisterEvent("GUILD_SHOW_GUILDBATTLERANKLIST_K" )				--                 
	this:RegisterEvent("GUILD_UPDATE_GUILDBATTLERANKLIST_K" )				--                 
	
end

--===============================================
-- OnEvent()
--===============================================
function NewBangHui_RankingList_OnEvent(event)
	-- 打开这个界面最先显示的是本服的数据  所以这里会先请求
	if event == "NEW_BANGHUI_XZRL_OPEN" then
		g_GuildIndex = 0;
		g_NewBangHui_RankingList_Button[g_GuildIndex+1]:SetCheck(1)
		g_NewBangHui_RankingList_ServerButton[g_KServer+1]:Disable();  
		NewBangHui_RankingList_Top_KVKLeague_tips:Show();
		--g_NewBangHui_RankingList_ServerButton[g_KServer+1]:SetToolTip("#{BHXZ_150831_46}");  
		
		--如果玩家在K服,还需要请求跨服宣战和跨服帮会的信息
		if KVKInterface:IsInKVKServer() == 1 or IsInTServer() == 1 then
			--向K服获取整个大世界所有服务器组的帮会信息列表
			City:AskKServerGuildList();
			--重新获取跨服宣战和应战的帮会信息
			City:AskKServerGuildEnemyList();
			g_NewBangHui_RankingList_ServerButton[g_KServer+1]:Enable();
			NewBangHui_RankingList_Top_KVKLeague_tips:Hide();
		end		 
		City:GetGuildListWithCity(); 
		City:AskBattleRankListGeneral( g_GuildIndex , g_NormalServer );
		NewBangHui_RankingList_InitDlg_Normal(); 	 
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		NewBangHui_RankingList_Close()
	elseif (event == "ADJEST_UI_POS") then
		NewBangHui_RankingList_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewBangHui_RankingList_On_ResetPos()   
	--  总概数据及user
	elseif event == "GUILD_SHOW_GUILDBATTLERANKLIST" then
		NewBangHui_RankingList_InitDlg_Normal(); 
		local retIndex = tonumber(arg0) 
		g_GuildIndex = retIndex
		-- 当前Index 与 应该显示的Index 是否一致
		--if g_GuildIndex ~= retIndex then
		--	PushDebugMessage("GUILD_SHOW_GUILDBATTLERANKLIST g_GuildIndex:"..g_GuildIndex); 
		--	PushDebugMessage("GUILD_SHOW_GUILDBATTLERANKLIST retIndex:"..retIndex); 
		--	PushDebugMessage("GUILD_SHOW_GUILDBATTLERANKLIST Current Index Not UserSelect Index "); 
		--	return;
		--end
		-- 当前查看的服 是K服还是原服
		if g_CurServerTYpe ~= g_NormalServer then
--			PushDebugMessage("GUILD_SHOW_GUILDBATTLERANKLIST Current Tab Not KSERVER  "); 
			return;
		end
		-- 当前查看是哪一方的user列表
		if g_CurSearchType ~= g_CurSearchSelf then
--			PushDebugMessage("GUILD_SHOW_GUILDBATTLERANKLIST Current User Not MySelf  "); 
			return;
		end 
		NewBangHui_RankingList_UpdateData( );  
	elseif event == "GUILD_SHOW_GUILDBATTLERANKLIST_K" then
		NewBangHui_RankingList_InitDlg_KServer(); 
		local retIndex = tonumber(arg0) 
--		PushDebugMessage("tonumber(arg0) "..tonumber(arg0) ); 
--		PushDebugMessage("g_GuildIndex"..tonumber(g_GuildIndex) ); 
		-- 当前Index 与 应该显示的Index 是否一致
		if g_GuildIndex ~= retIndex then
--			PushDebugMessage("GUILD_SHOW_GUILDBATTLERANKLIST_K Current Index Not UserSelect Index "); 
			return;
		end
		-- 当前查看的服 是K服还是原服
		if g_CurServerTYpe ~= g_KServer then
--			PushDebugMessage("GUILD_SHOW_GUILDBATTLERANKLIST_K Current Tab Not KSERVER  "); 
			return;
		end
		-- 当前查看是哪一方的user列表
		if g_CurSearchType ~= g_CurSearchSelf then
--			PushDebugMessage("GUILD_SHOW_GUILDBATTLERANKLIST_K Current User Not MySelf  "); 
			return;
		end
		NewBangHui_RankingList_UpdateData_K( ); 
	--  显示敌方数据
	elseif event == "GUILD_SHOW_GUILDBATTLERANKLIST_RIVAL" then 
		if g_CurSearchType ~= g_CurSearchRival then
--			PushDebugMessage("GUILD_SHOW_GUILDBATTLERANKLIST_RIVAL Current User Not RivalSelf  "); 
			return;
		end 
		NewBangHui_RankingList_UpdateData_Rival( );
	--  tick相关 为了更新倒计时用到的Event
	elseif event == "GUILD_UPDATE_GUILDBATTLERANKLIST" then      
		if( this:IsVisible() and g_CurServerTYpe == g_NormalServer )  then
			NewBangHui_RankingList_UpdateData_ButtonList(); 
		end
	elseif event == "GUILD_UPDATE_GUILDBATTLERANKLIST_K" then      
		if( this:IsVisible() and g_CurServerTYpe == g_KServer ) then
			NewBangHui_RankingList_UpdateData_ButtonList_K(); 
		end
	end	 
end

--===============================================
-- OnLoad()
--===============================================
function NewBangHui_RankingList_OnLoad()
	g_NewBangHui_RankingList_Button[1] = NewBangHui_RankingList_Button
	g_NewBangHui_RankingList_Button[2] = NewBangHui_RankingList_Button1
	g_NewBangHui_RankingList_Button[3] = NewBangHui_RankingList_Button2
	g_NewBangHui_RankingList_Button[4] = NewBangHui_RankingList_Button3
	g_NewBangHui_RankingList_Button[5] = NewBangHui_RankingList_Button4
	g_NewBangHui_RankingList_Button[6] = NewBangHui_RankingList_Button5
	g_NewBangHui_RankingList_Button[7] = NewBangHui_RankingList_Button6
	g_NewBangHui_RankingList_Button[8] = NewBangHui_RankingList_Button7  
	
	g_NewBangHui_RankingList_LaceButton[1] = NewBangHui_RankingList_Frame1_Lace2_Button
	g_NewBangHui_RankingList_LaceButton[2] = NewBangHui_RankingList_Frame1_Lace2_Button2
	
	g_NewBangHui_RankingList_ServerButton[1] = NewBangHui_RankingList_Top_Banghui
	g_NewBangHui_RankingList_ServerButton[2] = NewBangHui_RankingList_Top_KVKLeague
	
	g_CtrlNewBanHui_RL = {	
									XuanZhanRank_Time						= NewBangHui_RankingList_Frame1_Lace1_Time_Text,
									XuanZhanRank_SelfGuildName	= NewBangHui_RankingList_Frame1_Lace1_BB_Text,
									XuanZhanRank_SelfKillNum 		= NewBangHui_RankingList_Frame1_Lace1_BB_Text1_1,
									XuanZhanRank_RivalGuildName = NewBangHui_RankingList_Frame1_Lace1_DD_Text,
									XuanZhanRank_RivalKillNum 	= NewBangHui_RankingList_Frame1_Lace1_DD_Text1_1,
									XuanZhanRank_List 					= NewBangHui_RankingList_Frame1_Lace2_List,
									XuanZhanRank_SelfResultctl 	= NewBangHui_RankingList_Frame1_Lace1_BB_Left,
									XuanZhanRank_RivalResultctl = NewBangHui_RankingList_Frame1_Lace1_BB_Right,
									
	};
	
	g_NewBangHui_RankingList_Frame_UnifiedPosition = NewBangHui_RankingList_Frame:GetProperty("UnifiedPosition")
	 
 
	
end

------外框
--===============================================
-- Close()
--===============================================
function NewBangHui_RankingList_Close()
	g_EventIndex = -1
	this:Hide()
end

function NewBangHui_RankingList_Close_Clicked()
	NewBangHui_RankingList_Close()
end

function NewBangHui_RankingList_On_ResetPos()
	NewBangHui_RankingList_Frame:SetProperty("UnifiedPosition", g_NewBangHui_RankingList_Frame_UnifiedPosition)
end
 
-- 初始化控件状态 原服
function NewBangHui_RankingList_InitDlg_Normal() 
	NewBangHui_RankingList_Initbutton()
	--己方敌方初始化
	g_NewBangHui_RankingList_LaceButton[g_CurSearchSelf]:SetCheck(1);   
	g_NewBangHui_RankingList_LaceButton[g_CurSearchRival]:SetCheck(0);
	g_CurSearchType = g_CurSearchSelf;  -- 默认己方
	--本服k服初始化
	g_NewBangHui_RankingList_ServerButton[g_NormalServer+1]:SetCheck(1);
	g_NewBangHui_RankingList_ServerButton[g_KServer+1]:SetCheck(0); 
	g_CurServerTYpe = g_NormalServer;  -- 默认原服	
	
	g_CtrlNewBanHui_RL.XuanZhanRank_Time:SetText( "" );  
	g_CtrlNewBanHui_RL.XuanZhanRank_SelfGuildName:SetText( "" ); 
	g_CtrlNewBanHui_RL.XuanZhanRank_SelfKillNum:SetText( "" );  
	g_CtrlNewBanHui_RL.XuanZhanRank_RivalGuildName:SetText( "" ); 
	g_CtrlNewBanHui_RL.XuanZhanRank_RivalKillNum:SetText( "" );
end 
-- 初始化控件状态 原服
function NewBangHui_RankingList_InitDlg_KServer() 
	NewBangHui_RankingList_Initbutton()
	--己方敌方初始化
	g_NewBangHui_RankingList_LaceButton[g_CurSearchSelf]:SetCheck(1);   
	g_NewBangHui_RankingList_LaceButton[g_CurSearchRival]:SetCheck(0);
	g_CurSearchType = g_CurSearchSelf;  -- 默认己方
	--本服k服初始化
	g_NewBangHui_RankingList_ServerButton[g_KServer+1]:SetCheck(1);
	g_NewBangHui_RankingList_ServerButton[g_NormalServer+1]:SetCheck(0); 
	g_CurServerTYpe = g_KServer;  -- K服	
	
	g_CtrlNewBanHui_RL.XuanZhanRank_Time:SetText( "" );  
	g_CtrlNewBanHui_RL.XuanZhanRank_SelfGuildName:SetText( "" ); 
	g_CtrlNewBanHui_RL.XuanZhanRank_SelfKillNum:SetText( "" );  
	g_CtrlNewBanHui_RL.XuanZhanRank_RivalGuildName:SetText( "" ); 
	g_CtrlNewBanHui_RL.XuanZhanRank_RivalKillNum:SetText( "" );
end

--隐藏左侧Button 通过数量来显示出来
function NewBangHui_RankingList_Initbutton() 
	g_NewBangHui_RankingList_Button[1] :Hide();
	g_NewBangHui_RankingList_Button[2] :Hide();
	g_NewBangHui_RankingList_Button[3] :Hide();
	g_NewBangHui_RankingList_Button[4] :Hide();
	g_NewBangHui_RankingList_Button[5] :Hide();
	g_NewBangHui_RankingList_Button[6] :Hide();
	g_NewBangHui_RankingList_Button[7] :Hide();
	g_NewBangHui_RankingList_Button[8] :Hide();  
	g_CtrlNewBanHui_RL.XuanZhanRank_SelfResultctl : Hide()
	g_CtrlNewBanHui_RL.XuanZhanRank_RivalResultctl : Hide()	
end   

--全部隐藏
function NewBangHui_RankingList_HideAll() 
end

--查看己方战绩榜
function NewBangHui_RankingList_Self() 
	local curTime = OSAPI:GetTickCount(); 
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then 
  	PushDebugMessage("#{ZYPT_081127_2}"); --不可连续点击，请稍等片刻后再点击 
  	g_NewBangHui_RankingList_LaceButton[g_CurSearchSelf]:SetCheck(0);
  	g_NewBangHui_RankingList_LaceButton[g_CurSearchType]:SetCheck(1); 
		return
	end
		
	g_CurSearchType = g_CurSearchSelf;  
  g_NewBangHui_RankingList_LaceButton[g_CurSearchSelf]:SetCheck(1); 
  g_NewBangHui_RankingList_LaceButton[g_CurSearchRival]:SetCheck(0);
  
 	-- 如果是当前在原服页签 请求原服自己帮会的数据
 	if g_CurServerTYpe == g_NormalServer then
 		 City:AskBattleRankListByIndex( g_GuildIndex ); 
 	end
	
	if g_CurServerTYpe == g_KServer then
 		 City:AskBattleRankListByIndex_K( g_GuildIndex ); 
 	end
 	
	g_ButtonLastTime = curTime;
end
--查看敌方个人战绩榜
function NewBangHui_RankingList_Rival()  
	local curTime = OSAPI:GetTickCount();  
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then 
  	PushDebugMessage("#{ZYPT_081127_2}"); --不可连续点击，请稍等片刻后再点击
  	g_NewBangHui_RankingList_LaceButton[g_CurSearchRival]:SetCheck(0);
  	g_NewBangHui_RankingList_LaceButton[g_CurSearchType]:SetCheck(1); 
		return
	end
	g_CurSearchType = g_CurSearchRival; 
	g_NewBangHui_RankingList_LaceButton[g_CurSearchSelf]:SetCheck(0);  
	g_NewBangHui_RankingList_LaceButton[g_CurSearchRival]:SetCheck(1); 
	
	 	-- 如果是当前在原服页签 请求原服自己帮会的数据
 	if g_CurServerTYpe == g_NormalServer then
 		 City:AskBattleRankListRival( g_GuildIndex ); 
 	end
	
	if g_CurServerTYpe == g_KServer then
 		 City:AskBattleRankListRival_K( g_GuildIndex ); 
 	end
 	
	g_ButtonLastTime = curTime; 
end
 
--左侧Button Click
function NewBangHui_RankingList_Show( ClickId ) 
  local curTime = OSAPI:GetTickCount(); 
  if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then 
  	PushDebugMessage("#{ZYPT_081127_2}"); --不可连续点击，请稍等片刻后再点击
  	g_NewBangHui_RankingList_Button[ClickId+1]:SetCheck(0);
  	g_NewBangHui_RankingList_Button[g_GuildIndex+1]:SetCheck(1);  
  	
  	if g_CurSearchType == g_CurSearchSelf then
  		g_NewBangHui_RankingList_LaceButton[g_CurSearchSelf]:SetCheck(1);
  		g_NewBangHui_RankingList_LaceButton[g_CurSearchRival]:SetCheck(0);
  	elseif g_CurSearchType == g_CurSearchRival then
  		g_NewBangHui_RankingList_LaceButton[g_CurSearchRival]:SetCheck(1);
  		g_NewBangHui_RankingList_LaceButton[g_CurSearchSelf]:SetCheck(0);
  	end
  	return;
  end		 
	
	--当前选中左侧帮战列表Button
	g_GuildIndex 		= ClickId;
	--当前选中的查看哪方user列表 
	g_CurSearchType	= g_CurSearchSelf;
	
	-- 如果是当前在原服页签 请求原服自己帮会的数据
 	if g_CurServerTYpe == g_NormalServer then
 		 City:AskBattleRankListByIndex( g_GuildIndex ); 
 	end
	
	if g_CurServerTYpe == g_KServer then
 		 City:AskBattleRankListByIndex_K( g_GuildIndex ); 
 	end
 	
	g_NewBangHui_RankingList_Button[g_GuildIndex+1]:SetCheck(1) 
	g_ButtonLastTime = curTime;
end
 
--查看原服数据
function NewBangHui_RankingList_Top_Banghui_Click() 
	local curTime = OSAPI:GetTickCount(); 
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then 
  	PushDebugMessage("#{ZYPT_081127_2}"); --不可连续点击，请稍等片刻后再点击 
  	-- 先恢复左侧Button
  	g_NewBangHui_RankingList_Button[1]:SetCheck(0); 
  	g_NewBangHui_RankingList_Button[g_GuildIndex+1]:SetCheck(1); 
  	-- 在恢复查看服务器类别Button
  	g_NewBangHui_RankingList_ServerButton[g_NormalServer+1]:SetCheck(0); 
  	g_NewBangHui_RankingList_ServerButton[g_CurServerTYpe+1]:SetCheck(1); 
  	-- 最后回复查看User类别
  	if g_CurSearchType == g_CurSearchSelf then
  		g_NewBangHui_RankingList_LaceButton[g_CurSearchSelf]:SetCheck(1);
  		g_NewBangHui_RankingList_LaceButton[g_CurSearchRival]:SetCheck(0);
  	elseif g_CurSearchType == g_CurSearchRival then
  		g_NewBangHui_RankingList_LaceButton[g_CurSearchRival]:SetCheck(1);
  		g_NewBangHui_RankingList_LaceButton[g_CurSearchSelf]:SetCheck(0);
  	end
		return;
	end
	--初始化原服控件
	NewBangHui_RankingList_InitDlg_Normal();	
	--查看User类型
	g_CurSearchType = g_CurSearchSelf;  
	--查看服务器类型
	g_CurServerTYpe = g_NormalServer;  
	--初始化索引 默认显示第一个
	g_GuildIndex 		= 0;
  g_NewBangHui_RankingList_LaceButton[g_CurSearchSelf]:SetCheck(1); 
  g_NewBangHui_RankingList_LaceButton[g_CurSearchRival]:SetCheck(0);
  
 	-- 如果是当前在原服页签 请求原服自己帮会的数据
  City:AskBattleRankListGeneral( g_GuildIndex , g_NormalServer );
  
	g_ButtonLastTime = curTime;
end 
 
--查看K数据
function NewBangHui_RankingList_Top_KVKLeague_Click() 
	local curTime = OSAPI:GetTickCount(); 
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then 
  	PushDebugMessage("#{ZYPT_081127_2}"); --不可连续点击，请稍等片刻后再点击 
  	-- 先恢复左侧Button
  	g_NewBangHui_RankingList_Button[1]:SetCheck(0); 
  	g_NewBangHui_RankingList_Button[g_GuildIndex+1]:SetCheck(1); 
  	-- 在恢复查看服务器类别Button
  	g_NewBangHui_RankingList_ServerButton[g_KServer+1]:SetCheck(0); 
  	g_NewBangHui_RankingList_ServerButton[g_CurServerTYpe+1]:SetCheck(1); 
  	-- 最后回复查看User类别
  	if g_CurSearchType == g_CurSearchSelf then
  		g_NewBangHui_RankingList_LaceButton[g_CurSearchSelf]:SetCheck(1);
  		g_NewBangHui_RankingList_LaceButton[g_CurSearchRival]:SetCheck(0);
  	elseif g_CurSearchType == g_CurSearchRival then
  		g_NewBangHui_RankingList_LaceButton[g_CurSearchRival]:SetCheck(1);
  		g_NewBangHui_RankingList_LaceButton[g_CurSearchSelf]:SetCheck(0);
  	end
		return;
	end
	--初始化原服控件
	NewBangHui_RankingList_InitDlg_KServer();	
	--查看User类型
	g_CurSearchType = g_CurSearchSelf;  
	--查看服务器类型
	g_CurServerTYpe = g_KServer;  
	--初始化索引 默认显示第一个
	g_GuildIndex 		= 0;
  g_NewBangHui_RankingList_LaceButton[g_CurSearchSelf]:SetCheck(1); 
  g_NewBangHui_RankingList_LaceButton[g_CurSearchRival]:SetCheck(0);
  
 	-- 如果是当前在原服页签 请求原服自己帮会的数据
  City:AskBattleRankListGeneral( g_GuildIndex , g_KServer );
  
	g_ButtonLastTime = curTime;
end 
--填充User数据 原服数据
function NewBangHui_RankingList_UpdateData()  
	
	--先把Button 隐藏
	NewBangHui_RankingList_Initbutton();
	--清空User列表
	g_CtrlNewBanHui_RL.XuanZhanRank_List:RemoveAllItem(); 
	--至空各个控件数值
	NewBangHui_RankingList_InitDlg_Normal();
	--往里面塞数值
	NewBangHui_RankingList_UpdateData_ButtonList(); 
	local nRankListNum = City:GetBattleRankListNum(); 
	if nRankListNum == 0 then 
		this:Show();
		return;
	end  
	 
	if g_GuildIndex > nRankListNum then
--		PushDebugMessage("newBangHui_RankingList_UpdateData g_GuildIndex Error"); 
		return;
	end 
	 
	local nSelfKillNum 			= City:EnumBattleRankList(g_GuildIndex,"SelfKillNum");
	local nSelfGuildName		= City:EnumBattleRankList(g_GuildIndex,"SelfGuildName");
	local nRivalGuildName		= City:EnumBattleRankList(g_GuildIndex,"RivalGuildName");
	local nIsKserver 				= City:EnumBattleRankList(g_GuildIndex,"IsKserver");
	local nRivalKillNum 		= City:EnumBattleRankList(g_GuildIndex,"RivalKillNum");
	local nRemianTime 			= City:EnumBattleRankList(g_GuildIndex,"RemianTime");
	local nUserListNum 			= City:EnumBattleRankList(g_GuildIndex,"UserListNum");
   
 	for i = 0, nUserListNum-1 do 
		local szUserName 	= City:EnumBattleRankUserList(g_GuildIndex,i,"UserName");
		local szKillNum 	= City:EnumBattleRankUserList(g_GuildIndex,i,"KillNum"); 
		local szDeadNum 	= City:EnumBattleRankUserList(g_GuildIndex,i,"DeadNum");
		local szEquipPoint= City:EnumBattleRankUserList(g_GuildIndex,i,"EquipPoint");
		local szPostion 	= City:EnumBattleRankUserList(g_GuildIndex,i,"Postion");
		if szPostion < 1 and szPostion > table.getn(g_positionInfo) then
			return
		end 
		--在帮会ID之前需要加两个空格,这样子界面会好看一些
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem("  "..i+1, 0, i);
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(szUserName, 1, i);
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(szKillNum,  2, i); 
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(szDeadNum,  3, i);
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(szEquipPoint, 4, i);
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(g_positionInfo[szPostion],5, i); 
	end 
	this:Show();
end 

--填充User数据 k服数据
function NewBangHui_RankingList_UpdateData_K()  
	
	--先把Button 隐藏
	NewBangHui_RankingList_Initbutton();
	--清空User列表
	g_CtrlNewBanHui_RL.XuanZhanRank_List:RemoveAllItem();
	--初始化各个控件数值
	NewBangHui_RankingList_InitDlg_KServer();
	--往里面塞数值
	NewBangHui_RankingList_UpdateData_ButtonList_K(); 
	local nRankListNum = City:GetBattleRankListNum_K(); 
	if nRankListNum == 0 then 
		this:Show();
		return;
	end  
	 
	if g_GuildIndex > nRankListNum then
--		PushDebugMessage("NewBangHui_RankingList_UpdateData_K g_GuildIndex Error"); 
		return;
	end 
	 
	local nSelfKillNum 			= City:EnumBattleRankList_K(g_GuildIndex,"SelfKillNum");
	local nSelfGuildName		= City:EnumBattleRankList_K(g_GuildIndex,"SelfGuildName");
	local nRivalGuildName		= City:EnumBattleRankList_K(g_GuildIndex,"RivalGuildName");
	local nIsKserver 				= City:EnumBattleRankList_K(g_GuildIndex,"IsKserver");
	local nRivalKillNum 		= City:EnumBattleRankList_K(g_GuildIndex,"RivalKillNum");
	local nRemianTime 			= City:EnumBattleRankList_K(g_GuildIndex,"RemianTime");
	local nUserListNum 			= City:EnumBattleRankList_K(g_GuildIndex,"UserListNum");
   
 	for i = 0, nUserListNum-1 do 
		local szUserName 	= City:EnumBattleRankUserList_K(g_GuildIndex,i,"UserName");
		local szKillNum 	= City:EnumBattleRankUserList_K(g_GuildIndex,i,"KillNum"); 
		local szDeadNum 	= City:EnumBattleRankUserList_K(g_GuildIndex,i,"DeadNum");
		local szEquipPoint= City:EnumBattleRankUserList_K(g_GuildIndex,i,"EquipPoint");
		local szPostion 	= City:EnumBattleRankUserList_K(g_GuildIndex,i,"Postion");
		if szPostion < 1 and szPostion > table.getn(g_positionInfo) then
			return
		end 
		--在帮会ID之前需要加两个空格,这样子界面会好看一些
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem("  "..i+1, 0, i);
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(szUserName, 1, i);
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(szKillNum,  2, i); 
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(szDeadNum,  3, i);
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(szEquipPoint, 4, i);
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(g_positionInfo[szPostion],5, i); 
	end 
	this:Show();
end

--填充敌方数据
function NewBangHui_RankingList_UpdateData_Rival() 
	g_CtrlNewBanHui_RL.XuanZhanRank_List:RemoveAllItem();   
	
	local nRankListNum = City:GetBattleRankRivalListNum();  
	if nRankListNum <= 0 then
		return;
	end		 
 	for i = 0, nRankListNum-1 do 
		local szUserName 	= City:EnumBattleRankRivalUserList(i,"UserName");
		local szKillNum 	= City:EnumBattleRankRivalUserList(i,"KillNum"); 
		local szDeadNum 	= City:EnumBattleRankRivalUserList(i,"DeadNum");
		local szEquipPoint= City:EnumBattleRankRivalUserList(i,"EquipPoint");
		local szPostion 	= City:EnumBattleRankRivalUserList(i,"Postion"); 
		--在帮会ID之前需要加两个空格,这样子界面会好看一些 
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem("  "..i+1, 0, i);
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(szUserName, 1, i);
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(szKillNum,  2, i); 
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(szDeadNum,  3, i);
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(szEquipPoint, 4, i);
		g_CtrlNewBanHui_RL.XuanZhanRank_List:AddNewItem(g_positionInfo[szPostion],5, i); 
	end 
	this:Show();
end

--填充排行榜总概数据
function NewBangHui_RankingList_UpdateData_ButtonList() 
	 
	local nRankListNum = City:GetBattleRankListNum();
	
	-- 列表已经没有数据了
	if nRankListNum == 0 then
		return;
	end
	-- 这里需要想一想
	if g_GuildIndex > nRankListNum then
		g_GuildIndex = 0;
		City:AskBattleRankListGeneral( g_GuildIndex ,g_NormalServer );
		return;
	end 
	
	if nRankListNum > g_ButtonNum then 
		return;
	end 
	
	local	nSelfKillNum 			= City:EnumBattleRankList(g_GuildIndex,"SelfKillNum");
	local	nSelfGuildName		= City:EnumBattleRankList(g_GuildIndex,"SelfGuildName");
	local	nRivalGuildName		= City:EnumBattleRankList(g_GuildIndex,"RivalGuildName");
	local	nIsKserver 				= City:EnumBattleRankList(g_GuildIndex,"IsKserver");
	local	nRivalKillNum 		= City:EnumBattleRankList(g_GuildIndex,"RivalKillNum");
	local	nRemianTime 			= City:EnumBattleRankList(g_GuildIndex,"RemianTime");
	local	nUserListNum 			= City:EnumBattleRankList(g_GuildIndex,"UserListNum");	 
	local nIsInKserver 			= KVKInterface:IsInKVKServer();          
	if nSelfKillNum < 0 then
		nSelfKillNum = 0;
	end      
	if nRivalKillNum < 0 then
		nRivalKillNum = 0;
	end   
	if City:IsBattleOver(g_GuildIndex) == 1 then
		g_CtrlNewBanHui_RL.XuanZhanRank_SelfResultctl : Show()
		g_CtrlNewBanHui_RL.XuanZhanRank_RivalResultctl : Show()
		--g_CtrlNewBanHui_RL.XuanZhanRank_Time:Hide()
		--g_CtrlNewBanHui_RL.XuanZhanRank_Time:SetText("#cfff263帮战已结束");   
		g_CtrlNewBanHui_RL.XuanZhanRank_Time:SetText("#cfff263帮战已结束");   
		
		-- 设置胜负图标
		if  nSelfKillNum > nRivalKillNum then 
				g_CtrlNewBanHui_RL.XuanZhanRank_SelfResultctl : SetProperty("Image","set:CommonFrame18 image:EightKing_Sheng")
				g_CtrlNewBanHui_RL.XuanZhanRank_RivalResultctl : SetProperty("Image","set:CommonFrame18 image:EightKing_Fu") 
		end  
		if  nSelfKillNum == nRivalKillNum then 
				g_CtrlNewBanHui_RL.XuanZhanRank_RivalResultctl : SetProperty("Image","set:KVKLeague_UI19 image:KVKLeague_UI14_Ping")
				g_CtrlNewBanHui_RL.XuanZhanRank_SelfResultctl : SetProperty("Image","set:KVKLeague_UI19 image:KVKLeague_UI14_Ping") 
		end   
		if  nSelfKillNum < nRivalKillNum then 
				g_CtrlNewBanHui_RL.XuanZhanRank_RivalResultctl : SetProperty("Image","set:CommonFrame18 image:EightKing_Sheng")
				g_CtrlNewBanHui_RL.XuanZhanRank_SelfResultctl : SetProperty("Image","set:CommonFrame18 image:EightKing_Fu")  
		end  
	else
		g_CtrlNewBanHui_RL.XuanZhanRank_SelfResultctl : Hide()
		g_CtrlNewBanHui_RL.XuanZhanRank_RivalResultctl : Hide()	
		g_CtrlNewBanHui_RL.XuanZhanRank_Time:Show()	
		g_CtrlNewBanHui_RL.XuanZhanRank_Time:SetText( ScriptGlobal_Format("#{BHXZ_150831_07}", tostring(nRemianTime)) );
	end 
 
	                                             
	for i = 0, nRankListNum-1 do    
		local RivalGuildNameOnly = City:EnumBattleRankList(i,"RivalGuildNameOnly")
		local xzType             = City:EnumBattleRankList(i,"XuanZhanType")
		nIsKserver 							  = City:EnumBattleRankList(i,"IsKserver");
		g_NewBangHui_RankingList_Button[i+1]:SetText( "  "..RivalGuildNameOnly..g_xzTypeInfo[xzType] );
		g_NewBangHui_RankingList_Button[i+1]:Show();
		if i == g_GuildIndex then
			g_NewBangHui_RankingList_Button[i+1]:SetCheck(1);
		else
			g_NewBangHui_RankingList_Button[i+1]:SetCheck(0);
		end
		if nIsKserver == 1 and (nIsInKserver == 0 and IsInTServer() ~= 1) then
			g_NewBangHui_RankingList_Button[i+1]:Disable();
		else
			g_NewBangHui_RankingList_Button[i+1]:Enable();
		end 
	end  
	 
	  
	g_CtrlNewBanHui_RL.XuanZhanRank_SelfGuildName:SetText( nSelfGuildName ); 
	g_CtrlNewBanHui_RL.XuanZhanRank_SelfKillNum:SetText( nSelfKillNum );  
	g_CtrlNewBanHui_RL.XuanZhanRank_RivalGuildName:SetText( nRivalGuildName ); 
	g_CtrlNewBanHui_RL.XuanZhanRank_RivalKillNum:SetText( nRivalKillNum );  
	 
end

--填充排行榜总概数据
function NewBangHui_RankingList_UpdateData_ButtonList_K() 
	 
	local nRankListNum = City:GetBattleRankListNum_K();
	
	-- 列表已经没有数据了  直接关闭窗口
	if nRankListNum == 0 then
		return;
	end
	-- 这里需要想一想
	if g_GuildIndex > nRankListNum then
		g_GuildIndex = 0;
		City:AskBattleRankListGeneral( g_GuildIndex ,g_KServer );
		return;
	end 
	
	if nRankListNum > g_ButtonNum then 
		return;
	end 
	
	local	nSelfKillNum 			= City:EnumBattleRankList_K(g_GuildIndex,"SelfKillNum");
	local	nSelfGuildName		= City:EnumBattleRankList_K(g_GuildIndex,"SelfGuildName");
	local	nRivalGuildName		= City:EnumBattleRankList_K(g_GuildIndex,"RivalGuildName");
	local	nIsKserver 				= City:EnumBattleRankList_K(g_GuildIndex,"IsKserver");
	local	nRivalKillNum 		= City:EnumBattleRankList_K(g_GuildIndex,"RivalKillNum");
	local	nRemianTime 			= City:EnumBattleRankList_K(g_GuildIndex,"RemianTime");
	local	nUserListNum 			= City:EnumBattleRankList_K(g_GuildIndex,"UserListNum");	 
	local nIsInKserver 			= KVKInterface:IsInKVKServer();          
	if nSelfKillNum < 0 then
		nSelfKillNum = 0;
	end      
	if nRivalKillNum < 0 then
		nRivalKillNum = 0;
	end   
	
	if City:IsBattleOver_K(g_GuildIndex) == 1 then
		g_CtrlNewBanHui_RL.XuanZhanRank_SelfResultctl : Show()
		g_CtrlNewBanHui_RL.XuanZhanRank_RivalResultctl : Show()
		--PushDebugMessage( "g_CtrlNewBanHui_RL.XuanZhanRank_Time:Hide() " )
	  --g_CtrlNewBanHui_RL.XuanZhanRank_Time:SetText("#cfff263帮战已结束");   
	  --g_CtrlNewBanHui_RL.XuanZhanRank_Time:Hide()  
	  g_CtrlNewBanHui_RL.XuanZhanRank_Time:SetText(  "#{BHXZ_150831_08}" );  

		-- 设置胜负图标
		if  nSelfKillNum > nRivalKillNum then 
				g_CtrlNewBanHui_RL.XuanZhanRank_SelfResultctl : SetProperty("Image","set:CommonFrame18 image:EightKing_Sheng")
				g_CtrlNewBanHui_RL.XuanZhanRank_RivalResultctl : SetProperty("Image","set:CommonFrame18 image:EightKing_Fu") 
		end  
		if  nSelfKillNum == nRivalKillNum then 
				g_CtrlNewBanHui_RL.XuanZhanRank_RivalResultctl : SetProperty("Image","set:KVKLeague_UI19 image:KVKLeague_UI14_Ping")
				g_CtrlNewBanHui_RL.XuanZhanRank_SelfResultctl : SetProperty("Image","set:KVKLeague_UI19 image:KVKLeague_UI14_Ping") 
		end   
		if  nSelfKillNum < nRivalKillNum then 
				g_CtrlNewBanHui_RL.XuanZhanRank_RivalResultctl : SetProperty("Image","set:CommonFrame18 image:EightKing_Sheng")
				g_CtrlNewBanHui_RL.XuanZhanRank_SelfResultctl : SetProperty("Image","set:CommonFrame18 image:EightKing_Fu")  
		end  
	else
		g_CtrlNewBanHui_RL.XuanZhanRank_SelfResultctl : Hide()
		g_CtrlNewBanHui_RL.XuanZhanRank_RivalResultctl : Hide()
		g_CtrlNewBanHui_RL.XuanZhanRank_Time:Show()
		g_CtrlNewBanHui_RL.XuanZhanRank_Time:SetText( ScriptGlobal_Format("#{BHXZ_150831_07}", tostring(nRemianTime)) );  
	end   
	                                             
	for i = 0, nRankListNum-1 do    
		local RivalGuildNameOnly = City:EnumBattleRankList_K(i,"RivalGuildNameOnly")
		local xzType             = City:EnumBattleRankList_K(i,"XuanZhanType")
		nIsKserver 							  = City:EnumBattleRankList_K(i,"IsKserver");
		g_NewBangHui_RankingList_Button[i+1]:SetText( "  "..RivalGuildNameOnly..g_xzTypeInfo[xzType] );
		g_NewBangHui_RankingList_Button[i+1]:Show();
		if i == g_GuildIndex then
			g_NewBangHui_RankingList_Button[i+1]:SetCheck(1);
		else
			g_NewBangHui_RankingList_Button[i+1]:SetCheck(0);
		end
		if nIsKserver == 1 and (nIsInKserver == 0 and IsInTServer() ~= 1)then
			g_NewBangHui_RankingList_Button[i+1]:Disable();
		else
			g_NewBangHui_RankingList_Button[i+1]:Enable();
		end 
	end  
	
	

	
	g_CtrlNewBanHui_RL.XuanZhanRank_SelfGuildName:SetText( nSelfGuildName ); 
	g_CtrlNewBanHui_RL.XuanZhanRank_SelfKillNum:SetText( nSelfKillNum );  
	g_CtrlNewBanHui_RL.XuanZhanRank_RivalGuildName:SetText( nRivalGuildName ); 
	g_CtrlNewBanHui_RL.XuanZhanRank_RivalKillNum:SetText( nRivalKillNum );  
	 
end

