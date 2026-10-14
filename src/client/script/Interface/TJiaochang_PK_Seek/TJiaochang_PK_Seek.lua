--筛选界面
--!!!reloadscript =TJiaochang_PK_Seek
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_menpai_button= {}; --门派单选
local g_menpai_num = 15; --门派个数 menpai15

local g_level_button= {}; --等级单选
local g_level_num = 7; --等级个数



function TJiaochang_PK_Seek_PreLoad()
	this:RegisterEvent("SHOW_CHALLENGE_ROOM_FILTER");
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function TJiaochang_PK_Seek_OnLoad()
	g_Frame_UnifiedXPosition	= TJiaochang_PK_Seek_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= TJiaochang_PK_Seek_Frame:GetProperty("UnifiedYPosition");
	
	g_menpai_button[1] = TJiaochang_PK_Seek_SlInfo;
	g_menpai_button[2] = TJiaochang_PK_Seek_MjInfo;
	g_menpai_button[3] = TJiaochang_PK_Seek_GbInfo;
	g_menpai_button[4] = TJiaochang_PK_Seek_WdInfo;
	g_menpai_button[5] = TJiaochang_PK_Seek_EmInfo;
	g_menpai_button[6] = TJiaochang_PK_Seek_XxInfo;
	g_menpai_button[7] = TJiaochang_PK_Seek_TlInfo;
	g_menpai_button[8] = TJiaochang_PK_Seek_TsInfo;
	g_menpai_button[9] = TJiaochang_PK_Seek_XyInfo;
	g_menpai_button[10] = TJiaochang_PK_Seek_GsInfo;
	g_menpai_button[11] = TJiaochang_PK_Seek_TmInfo;
	g_menpai_button[12] = TJiaochang_PK_Seek_GgInfo;
	g_menpai_button[13] = TJiaochang_PK_Seek_KunlunInfo; --桃花岛
	g_menpai_button[14] = TJiaochang_PK_Seek_HongMingInfo;
	g_menpai_button[15] = TJiaochang_PK_Seek_ErenInfo;--menpai15 mptodo

	g_level_button[1] = TJiaochang_PK_Seek_60Info;
	g_level_button[2] = TJiaochang_PK_Seek_70Info;
	g_level_button[3] = TJiaochang_PK_Seek_80Info;
	g_level_button[4] = TJiaochang_PK_Seek_90Info;
	g_level_button[5] = TJiaochang_PK_Seek_100Info;
	g_level_button[6] = TJiaochang_PK_Seek_110Info;
	g_level_button[7] = TJiaochang_PK_Seek_120Info;
end


function TJiaochang_PK_Seek_OnEvent( event )
	if(event == "SHOW_CHALLENGE_ROOM_FILTER") then
		--如果已经显示就应该关掉
		if ( this:IsVisible() ) then
			this:Hide();
			return;
		end
		TJiaochang_PK_Seek_InitWindow();
		TJiaochang_PK_Seek_FillData()
		this:Show();
		
	elseif (event == "ADJEST_UI_POS") then
		TJiaochang_PK_Seek_ResetPos()	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TJiaochang_PK_Seek_ResetPos()		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
	end
end


--初始化窗口的一些参数
function TJiaochang_PK_Seek_InitWindow()
	TJiaochang_PK_Seek_RenYiInfo:SetCheck(1)
	TJiaochang_PK_Seek_RenyiInfo:SetCheck(1)
	
	for i=1, g_menpai_num do
		g_menpai_button[i]:SetCheck(0);
	end
	
	for i=1, g_level_num do
		g_level_button[i]:SetCheck(0);
	end 
end


--填充数据
function TJiaochang_PK_Seek_FillData()
	local levelData, menpaiData = DataPool:Lua_GetChallengeRoomFilter()
	
	for i=1, g_level_num do
		if levelData[i] == nil then
			continue
		end
		
		if levelData[i] == 0 then
			g_level_button[i]:SetCheck(0);
		else
			g_level_button[i]:SetCheck(1);
		end
	end 
	
	if levelData.isPick_AllLevel == 0 then
		TJiaochang_PK_Seek_RenYiInfo:SetCheck(0)
	else
		TJiaochang_PK_Seek_RenYiInfo:SetCheck(1)
	end
	
	for i=1, g_menpai_num do
		if menpaiData[i] == nil then
			continue
		end
		
		if menpaiData[i] == 0 then
			g_menpai_button[i]:SetCheck(0);
		else
			g_menpai_button[i]:SetCheck(1);
		end
	end 
	
	if menpaiData.isPick_AllMenPai == 0 then
		TJiaochang_PK_Seek_RenyiInfo:SetCheck(0)
	else
		TJiaochang_PK_Seek_RenyiInfo:SetCheck(1)
	end
end
	

--确认按钮
function TJiaochang_PK_Seek_OK_Clicked()
	local levelData={}
	local menpaiData={}

	local bCheckLevelNum = 0;
	for i=1, g_level_num do
		if 1 == g_level_button[i]:GetCheck() then
			bCheckLevelNum = bCheckLevelNum + 1;
			levelData[i] = 1
		else
			levelData[i] = 0
		end
	end

	local nRenYiCheck = TJiaochang_PK_Seek_RenYiInfo:GetCheck()
	levelData.isPick_AllLevel = nRenYiCheck

	if bCheckLevelNum<=0 and nRenYiCheck<=0 then
		--所有的按钮都没按下
		PushDebugMessage("#{TFXC_20220921_90}")
		return
	end
	
	local bCheckMenPaiNum = 0;
	for i=1, g_menpai_num do
		if 1 == g_menpai_button[i]:GetCheck() then
			bCheckMenPaiNum = bCheckMenPaiNum + 1;
			menpaiData[i] = 1
		else
			menpaiData[i] = 0
		end
	end

	local nRenYiCheck = TJiaochang_PK_Seek_RenyiInfo:GetCheck()
	menpaiData.isPick_AllMenPai = nRenYiCheck
	
	if bCheckMenPaiNum<=0 and nRenYiCheck<=0 then
		--所有的按钮都没按下
		PushDebugMessage("#{TFXC_20220921_92}")
		return
	end

	--todo
	local ret_level,ret_menpai = DataPool:Lua_SetChallengeRoomFilter(levelData, menpaiData)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnSaveChallengeFilter" )
		Set_XSCRIPT_ScriptID( 999847 )
		Set_XSCRIPT_Parameter(0, ret_level); 
		Set_XSCRIPT_Parameter(1, ret_menpai); 
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
		
	DataPool:Lua_PickChallengeRoomMember()
	PushEvent("SHOW_CHALLENGE_ROOM_FILTERMEMBER_LIST")
	this:Hide();
end

--取消按钮
function TJiaochang_PK_Seek_Cancel_Clicked()
	this:Hide();
end

--关闭按钮
function TJiaochang_PK_Seek_Close_Clicked()
	this:Hide();
end


--点击任意
--注意：这里是button down的事件，button down的时候，还没触发按钮切换状态，所以是反的
function TJiaochang_PK_Seek_Renyi_MenPai_Click()
	local nCheck = TJiaochang_PK_Seek_RenyiInfo:GetCheck()
	if(0 == nCheck) then
		--马上会切换回True
		for i=1, g_menpai_num do
			g_menpai_button[i]:SetCheck(0);
		end
	end
end

--点击其他门派
function TJiaochang_PK_Seek_MenPai_Click(nButtonIndex)
	if g_menpai_button[nButtonIndex] == nil then
		return
	end
	
	local nCheck = g_menpai_button[nButtonIndex]:GetCheck()
	if(1 == nCheck) then
		return
	end
	
	if(1 == TJiaochang_PK_Seek_RenyiInfo:GetCheck() ) then
		TJiaochang_PK_Seek_RenyiInfo:SetCheck(0)
	end
end


--点击任意
--注意：这里是button down的事件，button down的时候，还没触发按钮切换状态，所以是反的
function TJiaochang_PK_Seek_Renyi_Level_Click()
	local nCheck = TJiaochang_PK_Seek_RenYiInfo:GetCheck()
	if(0 == nCheck) then
		--马上会切换回True
		for i=1, g_level_num do
			g_level_button[i]:SetCheck(0);
		end
	end
end

--点击其他等级
function TJiaochang_PK_Seek_Level_Click(nButtonIndex)
	if g_level_button[nButtonIndex] == nil then
		return
	end
	
	local nCheck = g_level_button[nButtonIndex]:GetCheck()
	if(1 == nCheck) then
		return
	end
	
	if(1 == TJiaochang_PK_Seek_RenYiInfo:GetCheck() ) then
		TJiaochang_PK_Seek_RenYiInfo:SetCheck(0)
	end
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function TJiaochang_PK_Seek_ResetPos()
	TJiaochang_PK_Seek_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	TJiaochang_PK_Seek_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
