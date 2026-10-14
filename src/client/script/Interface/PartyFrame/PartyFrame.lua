--***********************************************************************************************************************************************
--***********************************************************************************************************************************************
--
-- 组队列表框的主要脚本事件
--
--
--
--************************************************************************************************************************************************
--************************************************************************************************************************************************



--------------------------------------------------------------------------------------------------------------------------------------------------
--
-- 局部变量的定义.
--
local PARTYFRAMEs = {};
local PARTY_HP = {};
local PARTY_MP = {};
local PARTY_FRAME = {};
local PARTY_HDSandBoxHP = {};
local PARTY_HDSandBoxHPBK = {};

local PARTY_NAME  = {};
local Portrait_ToolTips = {};
local UnLink_flag = {};					-- 掉线标记
local Porttrait_Mask = {};			-- 灰掉蒙子
local Porttrait_Head = {};			-- 队友头像
local PartyFrame_BK ={}
local PartyFrame_Buff_Frame={}
local Porttrait_Head_Parent={}
local Party_Flags={}
local Party_HeadFrame={}
local Party_HeadFrameAnimate = {}

local TeamFakeObjNeedUpdate = 1;
local RatioFakeObjNeedUpdate = 1;
-- 显示hp的text
local HP_Text_Tip = {};

local	MemberName;
local strIconIndex;
local HPValue;
local HPMax;
local MPValue;
local MPMax;
local Fammily;
local Level;
local Anger;
local DeadLink;
local Dead;
local sex;

-- 显示队友所中的buf
local PARTY_BUFF_MAX = 6;
local PARTY_IMPACT_CTL = {};

local PARTY_IMPACT_NUM = 40; --查询时要从20个里面选出优先级最高的6个

-- 队友出战珍兽按钮
local Team_Member_Pet_Button = {};
-- 队友的出战珍兽显示信息
local PetPortrait_ToolTips = {};

local Raid_Flags = {}

--***********************************************************************************************************************************************
--
--
--
--
--************************************************************************************************************************************************
function PartyFrame_PreLoad()


	this:RegisterEvent("TEAM_ENTER_MEMBER",true);				-- 注册队员加入事件
	this:RegisterEvent("TEAM_UPDATE_MEMBER",true);				-- 注册队员更新事件
	this:RegisterEvent("TEAM_HIDE_ALL_PLAYER",false);			-- 隐藏所有队员事件
	this:RegisterEvent("TEAM_REFRESH_DATA",true);				-- 更新某一个队员的事件
	this:RegisterEvent("ON_TEAM_UPDATE_PARTYFRAME",true);			-- 更新PartyFrame界面			add by WTT

	this:RegisterEvent("RAID_UPDATE_SQUAD_FRAME",true)
	this:RegisterEvent("RAID_CLOSE_SQUAD_FRAME",false)
	this:RegisterEvent("UI_SHOW_2DHEAD",false)	--显示2D头像
	this:RegisterEvent("UPDATE_FAKE_OBJECT",false)

end

function PartyFrame_OnLoad()


	PARTYFRAMEs[1] = PartyFrame1;
	PARTYFRAMEs[2] = PartyFrame2;
	PARTYFRAMEs[3] = PartyFrame3;
	PARTYFRAMEs[4] = PartyFrame4;
	PARTYFRAMEs[5] = PartyFrame5;

	PartyFrame_BK[1] = PartyFrame1_BK;
	PartyFrame_BK[2] = PartyFrame2_BK;
	PartyFrame_BK[3] = PartyFrame3_BK;
	PartyFrame_BK[4] = PartyFrame4_BK;
	PartyFrame_BK[5] = PartyFrame5_BK;

	PARTY_HP[1] = PartyFrame_HP1;
	PARTY_HP[2] = PartyFrame_HP2;
	PARTY_HP[3] = PartyFrame_HP3;
	PARTY_HP[4] = PartyFrame_HP4;
	PARTY_HP[5] = PartyFrame_HP5;

	PARTY_HDSandBoxHP[1] = PartyFrame_HP1_HDSandBoxHP
	PARTY_HDSandBoxHP[2] = PartyFrame_HP2_HDSandBoxHP
	PARTY_HDSandBoxHP[3] = PartyFrame_HP3_HDSandBoxHP
	PARTY_HDSandBoxHP[4] = PartyFrame_HP4_HDSandBoxHP
	PARTY_HDSandBoxHP[5] = PartyFrame_HP5_HDSandBoxHP

	PARTY_HDSandBoxHPBK[1] = PartyFrame_HP1_HDSandBoxHPBK
	PARTY_HDSandBoxHPBK[2] = PartyFrame_HP2_HDSandBoxHPBK
	PARTY_HDSandBoxHPBK[3] = PartyFrame_HP3_HDSandBoxHPBK
	PARTY_HDSandBoxHPBK[4] = PartyFrame_HP4_HDSandBoxHPBK
	PARTY_HDSandBoxHPBK[5] = PartyFrame_HP5_HDSandBoxHPBK


	PartyFrame_Buff_Frame[1] = PartyFrame_1_Buff_Frame;
	PartyFrame_Buff_Frame[2] = PartyFrame_2_Buff_Frame;
	PartyFrame_Buff_Frame[3] = PartyFrame_3_Buff_Frame;
	PartyFrame_Buff_Frame[4] = PartyFrame_4_Buff_Frame;
	PartyFrame_Buff_Frame[5] = PartyFrame_5_Buff_Frame;

	--PARTY_MP[1] = PartyFrame_MP1;
	--PARTY_MP[2] = PartyFrame_MP2;
	--PARTY_MP[3] = PartyFrame_MP3;
	--PARTY_MP[4] = PartyFrame_MP4;
	--PARTY_MP[5] = PartyFrame_MP5;

	PARTY_FRAME[1] = PartyFrame_Party1;
	PARTY_FRAME[2] = PartyFrame_Party2;
	PARTY_FRAME[3] = PartyFrame_Party3;
	PARTY_FRAME[4] = PartyFrame_Party4;
	PARTY_FRAME[5] = PartyFrame_Party5;

	--PARTY_NAME[1] = Name1;
	--PARTY_NAME[2] = Name2;
	--PARTY_NAME[3] = Name3;
	--PARTY_NAME[4] = Name4;
	--PARTY_NAME[5] = Name5;

	Portrait_ToolTips[1] = PartyFrame1_Head_2D;
	Portrait_ToolTips[2] = PartyFrame2_Head_2D;
	Portrait_ToolTips[3] = PartyFrame3_Head_2D;
	Portrait_ToolTips[4] = PartyFrame4_Head_2D;
	Portrait_ToolTips[5] = PartyFrame5_Head_2D;

	Porttrait_Head[1] = PartyFrame1_Head_3D;
	Porttrait_Head[2] = PartyFrame2_Head_3D;
	Porttrait_Head[3] = PartyFrame3_Head_3D;
	Porttrait_Head[4] = PartyFrame4_Head_3D;
	Porttrait_Head[5] = PartyFrame5_Head_3D;

	Porttrait_Head_Parent[1] = PartyFrame1_Head_3D_Parent;
	Porttrait_Head_Parent[2] = PartyFrame2_Head_3D_Parent;
	Porttrait_Head_Parent[3] = PartyFrame3_Head_3D_Parent;
	Porttrait_Head_Parent[4] = PartyFrame4_Head_3D_Parent;
	Porttrait_Head_Parent[5] = PartyFrame5_Head_3D_Parent;

	HP_Text_Tip[1] = PartyFrame_HP_Text1;
	HP_Text_Tip[2] = PartyFrame_HP_Text2;
	HP_Text_Tip[3] = PartyFrame_HP_Text3;
	HP_Text_Tip[4] = PartyFrame_HP_Text4;
	HP_Text_Tip[5] = PartyFrame_HP_Text5;

	--2006年5月20日, 修改掉线信息功能
	UnLink_flag[1] = Team_Leader_Flag2;
	UnLink_flag[2] = Team_Leader2_Flag2;
	UnLink_flag[3] = Team_Leader3_Flag2;
	UnLink_flag[4] = Team_Leader4_Flag2;
	UnLink_flag[5] = Team_Leader5_Flag2;


	--2006年5月20日, 修改死亡蒙子
	Porttrait_Mask[1] = Portrait_Icon1_Mask;
	Porttrait_Mask[2] = Portrait_Icon2_Mask;
	Porttrait_Mask[3] = Portrait_Icon3_Mask;
	Porttrait_Mask[4] = Portrait_Icon4_Mask;
	Porttrait_Mask[5] = Portrait_Icon5_Mask;


	PARTY_IMPACT_CTL[1] = {
												PartyFrame_1_Buff1,
												PartyFrame_1_Buff2,
												PartyFrame_1_Buff3,
												PartyFrame_1_Buff4,
												PartyFrame_1_Buff5,
												PartyFrame_1_Buff6,
											};
	PARTY_IMPACT_CTL[2] = {
												PartyFrame_2_Buff1,
												PartyFrame_2_Buff2,
												PartyFrame_2_Buff3,
												PartyFrame_2_Buff4,
												PartyFrame_2_Buff5,
												PartyFrame_2_Buff6,
											};
	PARTY_IMPACT_CTL[3] = {
												PartyFrame_3_Buff1,
												PartyFrame_3_Buff2,
												PartyFrame_3_Buff3,
												PartyFrame_3_Buff4,
												PartyFrame_3_Buff5,
												PartyFrame_3_Buff6,
											};
	PARTY_IMPACT_CTL[4] = {
												PartyFrame_4_Buff1,
												PartyFrame_4_Buff2,
												PartyFrame_4_Buff3,
												PartyFrame_4_Buff4,
												PartyFrame_4_Buff5,
												PartyFrame_4_Buff6,
											};
	PARTY_IMPACT_CTL[5] = {
												PartyFrame_5_Buff1,
												PartyFrame_5_Buff2,
												PartyFrame_5_Buff3,
												PartyFrame_5_Buff4,
												PartyFrame_5_Buff5,
												PartyFrame_5_Buff6,
											};


	Team_Leader2_Flag:Hide();
	Team_Leader3_Flag:Hide();
	Team_Leader4_Flag:Hide();
	Team_Leader5_Flag:Hide();

	-- 第1至5号队友的出战宠物按钮
	-- add by WTT
	Team_Member_Pet_Button[1] = Team_Pet_Button;
	Team_Member_Pet_Button[2] = Team_Pet2_Button;
	Team_Member_Pet_Button[3] = Team_Pet3_Button;
	Team_Member_Pet_Button[4] = Team_Pet4_Button;
	Team_Member_Pet_Button[5] = Team_Pet5_Button;

	-- 珍兽头像上的浮动信息
	-- add by WTT
	PetPortrait_ToolTips[1]= Team_Pet_Button;
	PetPortrait_ToolTips[2]= Team_Pet2_Button;
	PetPortrait_ToolTips[3]= Team_Pet3_Button;
	PetPortrait_ToolTips[4]= Team_Pet4_Button;
	PetPortrait_ToolTips[5]= Team_Pet5_Button;

	Raid_Flags[1] = Team_Leader_Flag3
	Raid_Flags[2] = Team_Leader2_Flag3
	Raid_Flags[3] = Team_Leader3_Flag3
	Raid_Flags[4] = Team_Leader4_Flag3
	Raid_Flags[5] = Team_Leader5_Flag3

	Party_Flags[1] = Team_Leader_Flag
	Party_Flags[2] = Team_Leader2_Flag
	Party_Flags[3] = Team_Leader3_Flag
	Party_Flags[4] = Team_Leader4_Flag
	Party_Flags[5] = Team_Leader5_Flag

	Party_HeadFrame[1] = PartyFrame1_SelectCharHeadFrame
	Party_HeadFrame[2] = PartyFrame2_SelectCharHeadFrame
	Party_HeadFrame[3] = PartyFrame3_SelectCharHeadFrame
	Party_HeadFrame[4] = PartyFrame4_SelectCharHeadFrame
	Party_HeadFrame[5] = PartyFrame5_SelectCharHeadFrame

	Party_HeadFrameAnimate[1] = PartyFrame1_Head_Animate
	Party_HeadFrameAnimate[2] = PartyFrame2_Head_Animate
	Party_HeadFrameAnimate[3] = PartyFrame3_Head_Animate
	Party_HeadFrameAnimate[4] = PartyFrame4_Head_Animate
	Party_HeadFrameAnimate[5] = PartyFrame5_Head_Animate
end

--****************************************************************************************************************
--
-- 事件入口
--
--****************************************************************************************************************
function PartyFrame_OnEvent(event)


	----------------------------------------------------------------------------------------------------------------
	--
	-- 隐藏所有队友界面
	if ( event == "TEAM_HIDE_ALL_PLAYER" ) then


		Hide_All_Play_Func();
		return;
	end


	-----------------------------------------------------------------------------------------------------------------
	--
	-- 更新所有队友界面.
	if( event == "TEAM_REFRESH_DATA" ) then

		Refresh_All_Member_Info_Func();
			return;
	end



	------------------------------------------------------------------------------------------------------------------
	--
	-- 有新的队员进入
	if ( event == "TEAM_ENTER_MEMBER" ) then
		Refresh_All_Member_Info_Func();
		return;

	end



	--------------------------------------------------------------------------------------------------------------------
	--
	-- 更新队员信息.
	if ( event == "TEAM_UPDATE_MEMBER" ) then
		local nIndex = tonumber( arg0 )
		TeamFakeObjNeedUpdate = tonumber( arg1 )
		Refresh_All_Member_Info_Func();
		TeamFakeObjNeedUpdate = 1
		return;

	end

	--------------------------------------------------------------------------------------------------------------------
	--
	-- 更新PartyFrame界面
	-- add by WTT
	if ( event == "ON_TEAM_UPDATE_PARTYFRAME" ) then
		Refresh_All_Member_Info_Func();
		return;
	end

	if (event == "RAID_UPDATE_SQUAD_FRAME") then
		RatioFakeObjNeedUpdate = tonumber( arg2 )
		Refresh_All_RaidMember_Info()
		RatioFakeObjNeedUpdate = 1
		return
	end

	if (event == "RAID_CLOSE_SQUAD_FRAME") then
		Hide_All_Play_Func()
		return
	end

	if ( event == "UI_SHOW_2DHEAD" ) then
		PartyFrame_UpdateShow2DHead()
		return
	end

	if(	event == "UPDATE_FAKE_OBJECT" ) then

	end

end


--***********************************************************************************************************************************************
--
-- 显示一个新加入的队员
--
--************************************************************************************************************************************************
function PartyFrame_UpdatePage(index)



	if((index < 1) or (index > 5)) then

			return;
	end

	this:Show();

	--显示新加入队友的头像
	PARTYFRAMEs[index]:Show();

	--显示新加入队友的珍兽按钮
	PetButton_Show (index);

	PARTY_HDSandBoxHPBK[index]:Hide()
	PARTY_HDSandBoxHP[index]:Hide()

	PartyFrame_UpdateShow2DHead()



end



--***********************************************************************************************************************************************
--
-- 当右键点击窗口的时候, 弹出菜单
--
--************************************************************************************************************************************************
function Show_Team_Func(index)
	PartyFrame_SelectAsTarget(index)
	if Player:IsInRaid() == 1 then
		local sIdx, mIdx = Raid:GetMySquadMemIdxByUIIdx(index - 1)
		Raid:ShowMemberContMenu("PartyFrame", sIdx, mIdx)
	else
		Show_Team_Func_Menu(index)
	end
end


--***********************************************************************************************************************************************
--
-- 隐藏队列窗口
--
--************************************************************************************************************************************************
function Hide_All_Play_Func()

	local index = 1;
	while (index < 6) do
			PARTYFRAMEs[index]:Hide();
			Team_Member_Pet_Button[index]:Hide();
			Raid_Flags[index]:Hide()
			if( TeamFakeObjNeedUpdate == 1 and RatioFakeObjNeedUpdate == 1 ) then
				Porttrait_Head[index]:SetFakeObject("");
			end
			index = index + 1;
	end

	Team_Leader_Flag:Hide();
	PartyFrame_ClerAllBufInfo();

end


--***********************************************************************************************************************************************
--
-- 显示队员信息
--
--************************************************************************************************************************************************
function Show_Team_Member_Info_Func(index)


		-- 得到队员的个数
		local iMemCount = DataPool:GetTeamMemberCount();


		if((iMemCount < 1)and(iMemCount > 5)) then


			return;
		end

		-- 得到队员的详细信息
		MemberName
		, strIconIndex
		, HPValue
		, HPMax
		, MPValue
		, MPMax
		, Fammily
		, Level
		, Anger
		, DeadLink
		, Dead
		, sex
		, ScenceName
		, HeadFrameType
		, HeadFrame
		, Eg
		, MemBerSceneID
		= DataPool:GetTeamMemberInfo( index );


		-- 设置名字.
		--PARTY_NAME[index]:SetText(MemberName);

		-- 设置hp
		if(-1 ~= HPValue) then
			PARTY_HP[index]:SetProgress(tonumber(HPValue), tonumber(HPMax));
		else
			PARTY_HP[index]:SetProgress(1, 1);
		end;

		if 1 == XRZPVP:IsInBattleScene() then
			local sandBoxHp, sandBoxMaxHp = DataPool:GetTeamMemSandBoxHPInfo(index)
			if(sandBoxMaxHp > 0) then
				if(-1 ~= sandBoxHp) then
					PARTY_HP[index]:SetProgress(sandBoxHp, sandBoxMaxHp)
				else
					PARTY_HP[index]:SetProgress(1, 1)
				end
		 	 end
		end


		-- 设置mp
		--PARTY_MP[index]:SetProgress(tonumber(MPValue), tonumber(MPMax));

		-- 设置边框
		if HeadFrameType == 1 then
			Party_HeadFrame[index]:SetProperty("Image", "")
			Party_HeadFrame[index]:Hide()

			Party_HeadFrameAnimate[index]:Show()
			Party_HeadFrameAnimate[index]:SetProperty("Animate", tostring(HeadFrame))
		else
			Party_HeadFrameAnimate[index]:SetProperty("Animate", "")
			Party_HeadFrameAnimate[index]:Hide()

			Party_HeadFrame[index]:Show()
			local IconFile = GetIconFullName(HeadFrame)
			Party_HeadFrame[index]:SetProperty("Image", IconFile)
		end

		Show_Leader_Flag_Func();

		-- 设置tooltips
		local bDead = "否";
		local bDeadLink = "否";

		Portrait_ToolTips[index]:SetProperty("Image", "set:PlayerFrame_Icon image:Icon_xiaoyao");
		Portrait_ToolTips[index]:SetProperty("Image", strIconIndex);

		if (TeamFakeObjNeedUpdate == 1) then
		end

		--if(0 ~= Dead) then
		--	bDead = "是"
		--	Portrait_ToolTips[index]:SetProperty("Image", "set:TeamFrame5 image:Die_Icon");
		--end

		--if(0 ~= DeadLink) then
		--	bDeadLink = "是"

		--	Portrait_ToolTips[index]:SetProperty("Image", "set:TeamFrame5 image:Downline_Icon");
		--end


		if(0 ~= Dead) then
			bDead = "是"
			--Portrait_ToolTips[tonumber(index)]:Disable();
			Porttrait_Mask[index]:Show();
		else

			--Portrait_ToolTips[tonumber(index)]:Eable();
			Porttrait_Mask[index]:Hide();
		end

		if(0 == DeadLink) then

			UnLink_flag[tonumber(index)]:Hide();
		else

			bDeadLink = "是"
			UnLink_flag[tonumber(index)]:Show();
		end


		--local strInfo = "\n 名字: "
		--								.. tostring(MemberName)
		--      					.. "\n 门派:"
		--								.. tostring(Fammily)
		--								.. "\n 等级:"
		--								.. tostring(Level)
		--								.. " \n hp:"
		--								.. tostring(HPValue) .. "/" .. tostring(HPMax)
		--								.. " \n mp:"
		--								.. tostring(MPValue) .. "/" .. tostring(MPMax)
		--								.. " \n 怒气:"
		--								.. tostring(Anger)
		--								.. " \n 断线:"
		--								.. tostring(bDeadLink)
		--								.. " \n 死亡:"
		--								.. tostring(bDead);


		local strMenPai = "";
		-- 得到门派名称.
		if(0 == Fammily) then
			strMenPai = "少林";

		elseif(1 == Fammily) then
			strMenPai = "明教";

		elseif(2 == Fammily) then
			strMenPai = "丐帮";

		elseif(3 == Fammily) then
			strMenPai = "武当";

		elseif(4 == Fammily) then
			strMenPai = "峨嵋";

		elseif(5 == Fammily) then
			strMenPai = "星宿";

		elseif(6 == Fammily) then
			strMenPai = "天龙";

		elseif(7 == Fammily) then
			strMenPai = "天山";

		elseif(8 == Fammily) then
			strMenPai = "逍遥";

		elseif(9 == Fammily) then
			strMenPai = "无门派";

		elseif(10== Fammily) then
			strMenPai = "慕容";

		elseif(11== Fammily) then
			strMenPai = "唐门";

		elseif(12== Fammily) then
			strMenPai = "鬼谷";
		elseif(13== Fammily) then
			strMenPai = "#{XQ_MP_15}"; --桃花岛
		elseif(14== Fammily) then
			strMenPai = "#{XMPHM_210604_01}";
		elseif(15== Fammily) then--menpai15 mptodo
			strMenPai = "#{GMGameInterface_Script_DataPool_Info_ERenGu}";
		end

		local strInfo = tostring(MemberName)
		      					.. "\n"
										.. tostring(strMenPai).."  "
										.. tostring(Level).. "级"
										.. "\n所在地："
										.. ScenceName;

		Portrait_ToolTips[index]:SetToolTip(strInfo);
		Porttrait_Head[index]:SetToolTip(strInfo);


		if(-1 == HPValue) then

			-- 跨场景的情况。
			PARTY_HP[index]:SetToolTip("未知");
		else

			PARTY_HP[index]:SetToolTip(tostring(HPValue).."/"..tostring(HPMax));
		end;

		if 1 == XRZPVP:IsInBattleScene() and DataPool:TeamMemIsSnowMan(index) == 1 then
			local sandBoxHp, sandBoxMaxHp = DataPool:GetTeamMemSandBoxHPInfo(index)
			if(sandBoxMaxHp > 0) then
				if(-1 ~= sandBoxHp) then
					PARTY_HP[index]:SetToolTip("未知")
				else
					PARTY_HP[index]:SetToolTip(tostring(sandBoxHp).."/"..tostring(sandBoxMaxHp));
				end
			end
		end


		PartyFrame_ClerBufInfo(index);
		PartyFrame_UpdateBufInfo(index);

		-- 显示队员出战珍兽图标
		PetButton_Show(index);

end


--***********************************************************************************************************************************************
--
-- 更新所有队员信息
--
--************************************************************************************************************************************************
function Refresh_All_Member_Info_Func()

		-- 先隐藏掉所有的队员.
		Hide_All_Play_Func();

		-- 得到队员的个数
		local iMemCount = DataPool:GetTeamMemberCount();


		--
		if((iMemCount < 1)or(iMemCount > 6)) then


			return;
		end

		for index = 1, iMemCount - 1 do

				-- 显示一个队员
				PartyFrame_UpdatePage(index);

				-- 显示队员的详细信息
				Show_Team_Member_Info_Func(index);

				-- 显示队员的珍兽按钮
				PetButton_Show(index);

		end

		Show_Leader_Flag_Func();

		PartyFrame_UpdateShow2DHead()

end


--***********************************************************************************************************************************************
--
-- 显示队长信息
--
--************************************************************************************************************************************************
function Show_Leader_Flag_Func()
	-- 显示队长标记
	local iIsLeader = DataPool:IsTeamLeader();
	if (1 == iIsLeader) then
		Team_Leader_Flag:Show();
	end
end


--***********************************************************************************************************************************************
--
-- 选择队友作为target(同游戏中, 右键点击一个模型效果一样)
--
--************************************************************************************************************************************************
function PartyFrame_SelectAsTarget(UIIndex)
	if Player:IsInRaid() == 1 then
		local sIdx, mIdx = Raid:GetMySquadMemIdxByUIIdx(UIIndex - 1)
		Raid:SelectAsTargetByIdx(sIdx, mIdx)
	else
		DataPool:SelectAsTargetByUIIndex(UIIndex);
	end
end;


--***********************************************************************************************************************************************
--
-- 鼠标移入事件
--
--************************************************************************************************************************************************

function PartyFrame_HP_Text_MouseEnter(UIIndex)


		-- 得到队员的详细信息
		--MemberName
		--, strIconIndex
		--, HPValue
		--, HPMax
		--, MPValue
		--, MPMax
		--, Fammily
		--, Level
		--, Anger
		--, DeadLink
		--, Dead
		--, sex
		--= DataPool:GetTeamMemberInfo( UIIndex );

	--local ShowHpTipText = "";

	--if(-1 == HPValue) then

	--	ShowHpTipText = "未知";
	--else

	--	ShowHpTipText = tostring(HPValue).."/"..tostring(HPMax);
	--end;
	--HP_Text_Tip[UIIndex]:SetText(ShowHpTipText);

end;

--***********************************************************************************************************************************************
--
-- 鼠标移出事件
--
--************************************************************************************************************************************************

function PartyFrame_HP_Text_MouseLeave(UIIndex)


	--HP_Text_Tip[UIIndex]:SetText("");
end;

function PartyFrame_ClerAllBufInfo()
	local i;
	for i = 1, 5 do
		PartyFrame_ClerBufInfo( i );
	end
end

function PartyFrame_ClerBufInfo( idx )
	if(idx == nil) then return; end
	if(idx < 1 or idx > 5) then return; end

	local i = 0;
	while i < PARTY_BUFF_MAX do

		PARTY_IMPACT_CTL[idx][i+1]:SetToolTip("");
		PARTY_IMPACT_CTL[idx][i+1]:Hide();
		i = i + 1;
	end
end

function PartyFrame_UpdateBufInfo( idx )
	if(idx < 1 or idx > 5) then return; end
	local nBuffNum = DataPool:GetTeamMemBufNum(idx);
	local nFindNum = nBuffNum --在修正nBuffNum之前获得它的值
	if(nFindNum > PARTY_IMPACT_NUM) then nFindNum = PARTY_IMPACT_NUM; end
	if(nBuffNum > PARTY_BUFF_MAX) then nBuffNum = PARTY_BUFF_MAX; end

	--从最多40个里面选取6个
	local BUFFINDEX_LIST = {} --这个list做局部变量即可
	do
		for jj=1,PARTY_BUFF_MAX do
			BUFFINDEX_LIST[jj] = -1;
		end
		
		local BuffPriority = {}
		local _,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,n39 = SystemSetup:GameGetData()
		if n39 ~= 1 then
				for jj=1,nFindNum do --最大40
					BuffPriority[jj] = {}
					BuffPriority[jj].key = jj-1;
					BuffPriority[jj].val = DataPool:GetTeamMemBufPriority(idx, jj-1);
				end
		
				for jj=nFindNum,1,-1 do --最大40
					for kk=1,jj-1 do --最大40
						if BuffPriority[kk].val < BuffPriority[kk+1].val then
							BuffPriority[kk],BuffPriority[kk+1] = BuffPriority[kk+1],BuffPriority[kk]
						end
					end
				end
		
				for jj=1,nBuffNum do --最大6
					BUFFINDEX_LIST[jj] = BuffPriority[jj].key;
				end

		else
				local PreShowBuff = {}
				local count1 =0 
				local count2 =0 
				for jj=1,nFindNum do --最大40
					local isPre = DataPool:IsPreShowBuff(idx, jj-1)
					if isPre > 0 then
						count1 = count1 + 1
						PreShowBuff[count1] = {}
						PreShowBuff[count1].key = jj-1
						PreShowBuff[count1].val = isPre
					else
						count2 = count2 + 1
						BuffPriority[count2] = {}
						BuffPriority[count2].key = jj-1;
						BuffPriority[count2].val = DataPool:GetTeamMemBufPriority(idx, jj-1);
					end
				end
		
				for jj=count1,1,-1 do 
					for kk=1,jj-1 do 
						if PreShowBuff[kk].val < PreShowBuff[kk+1].val then
							PreShowBuff[kk],PreShowBuff[kk+1] = PreShowBuff[kk+1],PreShowBuff[kk]
						end
					end
				end
		
				for jj=count2,1,-1 do 
					for kk=1,jj-1 do 
						if BuffPriority[kk].val < BuffPriority[kk+1].val then
							BuffPriority[kk],BuffPriority[kk+1] = BuffPriority[kk+1],BuffPriority[kk]
						end
					end
				end
		
				-- for jj=1,nBuffNum do --最大6
				-- 	if jj<=count1 then
				-- 		BUFFINDEX_LIST[jj] = PreShowBuff[jj].key
				-- 	else
				-- 		BUFFINDEX_LIST[jj] = BuffPriority[jj].key
				-- 	end
				-- end
				local jk = 1
				for jj=1,nBuffNum do --最大6
					if jj<=count1 then
						BUFFINDEX_LIST[jj] = PreShowBuff[jj].key
					else
						BUFFINDEX_LIST[jj] = BuffPriority[jk].key
						jk = jk + 1
					end
				end

		end

	end

	local i = 0;
	while i < nBuffNum do
		local szIconName;
		local szTipInfo;

		szIconName,szTipInfo = DataPool:GetTeamMemBufInfo(idx, BUFFINDEX_LIST[i+1]);
		--有图标则显示，没有图标则不显示，适用于没有图标的buff。
		--由于没有图标的buff根据优先级都排到最后去了，所以实际效果是最后几个没图标的buff不显示出来 62434~62437
		if szIconName and szTipInfo then
			PARTY_IMPACT_CTL[idx][i+1]:SetProperty("ShortImage", szIconName);
			PARTY_IMPACT_CTL[idx][i+1]:Show();
			PARTY_IMPACT_CTL[idx][i+1]:SetToolTip(szTipInfo);
		else
			PARTY_IMPACT_CTL[idx][i+1]:SetToolTip("");
			PARTY_IMPACT_CTL[idx][i+1]:Hide();
		end

		i = i + 1;
	end

	while i < PARTY_BUFF_MAX do
		PARTY_IMPACT_CTL[idx][i+1]:SetToolTip("");
		PARTY_IMPACT_CTL[idx][i+1]:Hide();
		i = i + 1;
	end
end

--***********************************************************************************************************************************************
--
-- 显示队员的珍兽按钮
-- add by WTT
--
--************************************************************************************************************************************************
function PetButton_Show(UIIndex)
----------------------------------------------------------------------------------------------------
--TODO:
--团队暂时用珍兽替代团长图标，策划资源配好后再改回去
	Team_Member_Pet_Button[UIIndex]:SetProperty("Image", "set:UIIcons image:Icon_Pet_Normal")
----------------------------------------------------------------------------------------------------

	-- 显示珍兽按钮
	Team_Member_Pet_Button[UIIndex]:Show();

	return

end

--***********************************************************************************************************************************************
--
-- 鼠标左键单击：选中队友的当前出战珍兽
-- add by WTT
--
--************************************************************************************************************************************************
function PetButton_SetFightPetAsTarget(UIIndex)

	-- 首先通过UI索引来选中队友的珍兽作为当前选中目标
	local iFindFightingPet = DataPool:SelectTeamMemPetAsTargetByUIIndex(UIIndex);

	-- 如果找不到队友的出战珍兽
	if (iFindFightingPet == -1) then

		PushDebugMessage ("#{ZSAN_90311_2}");			-- 队友不在附近，或者无出战珍兽，无法查看珍兽信息。

	end

	-- 更新当前的PartyFrame界面
	Update_PartyFrame_Menu ();

end

--***********************************************************************************************************************************************
--
-- 鼠标右键单击：打开队友的出战珍兽的选项菜单
-- add by WTT
--
--************************************************************************************************************************************************
function PetButton_ToggleTargetPetPage(UIIndex)

	-- 首先通过UI索引来选中队友的珍兽作为当前选中目标
	local iFindFightingPet = DataPool:SelectTeamMemPetAsTargetByUIIndex(UIIndex);

	-- 如果找不到队友的出战珍兽
	if (iFindFightingPet == -1) then

		PushDebugMessage ("#{ZSAN_90311_2}");			-- 队友不在附近，或者无出战珍兽，无法查看珍兽信息。

	-- 如果能找到队友的出战珍兽
	else

		-- 弹出队友珍兽按钮的右键菜单
		Show_Team_Member_Pet_Menu ();

	end

	-- 更新当前的PartyFrame界面
	Update_PartyFrame_Menu ();

end


function Refresh_All_RaidMember_Info()

		-- 先隐藏掉所有的队员.
		Hide_All_Play_Func()
		local iMemCount = Raid:GetMySquadMemCount()
		if((iMemCount < 1)or(iMemCount > 6)) then
			return;
		end

		for index = 1, iMemCount - 1 do
			PARTYFRAMEs[index]:Show()

			local sIdx, mIdx = Raid:GetMySquadMemIdxByUIIdx(index - 1)
			local MemberName, strIconIndex, HPValue, HPMax, MPValue, MPMax, Fammily, Level, Anger, DeadLink, Dead, sex, ScenceName, HeadFrame
			= Raid:GetMemberDetailByIdx(sIdx,mIdx);

			local pos = Raid:IsLeaderByIdx(sIdx, mIdx)
			if pos == 1 then
				Raid_Flags[index]:SetProperty("Image", "set:Union1 image:Union_LeaderIcon_S")
				Raid_Flags[index]:Show()
			elseif pos == 2 then
				Raid_Flags[index]:SetProperty("Image", "set:Union1 image:Union_MemberIcon_S")
				Raid_Flags[index]:Show()
			else
				Raid_Flags[index]:Hide()
			end

			if(-1 ~= HPValue) then
				PARTY_HP[index]:SetProgress(tonumber(HPValue), tonumber(HPMax))
			else
				PARTY_HP[index]:SetProgress(1, 1)
			end

			PARTY_HDSandBoxHP[index]:Hide()
			PARTY_HDSandBoxHPBK[index]:Hide()

			Portrait_ToolTips[index]:SetProperty("Image", "set:PlayerFrame_Icon image:Icon_xiaoyao");
			Portrait_ToolTips[index]:SetProperty("Image", strIconIndex);

			-- 设置边框
			local IconFile = GetIconFullName(HeadFrame)
			Party_HeadFrame[index]:SetProperty("Image", IconFile)

			if(RatioFakeObjNeedUpdate == 1) then
				-- -- 得到head ui模型信息
				-- local strModelName = Raid:SetModelHeadLookByIdx(sIdx, mIdx);
				-- -- 显示模型
				-- Porttrait_Head[index]:SetFakeObject(strModelName);
				-- local strMaskImg = Target:AdjustHeadCamera(strModelName, 2)
				-- if strMaskImg ~= "" then
				-- 	Porttrait_Head_Parent[index]:SetProperty("MaskImage", strMaskImg)
				-- end
			end

			if(0 ~= Dead) then
				Porttrait_Mask[index]:Show();
			else
				Porttrait_Mask[index]:Hide();
			end

			if(0 == DeadLink) then
				UnLink_flag[index]:Hide();
			else
				UnLink_flag[index]:Show();
			end

			local strMenPai = "";
			if(0 == Fammily) then
				strMenPai = "少林";
			elseif(1 == Fammily) then
				strMenPai = "明教";
			elseif(2 == Fammily) then
				strMenPai = "丐帮";
			elseif(3 == Fammily) then
				strMenPai = "武当";
			elseif(4 == Fammily) then
				strMenPai = "峨嵋";
			elseif(5 == Fammily) then
				strMenPai = "星宿";
			elseif(6 == Fammily) then
				strMenPai = "天龙";
			elseif(7 == Fammily) then
				strMenPai = "天山";
			elseif(8 == Fammily) then
				strMenPai = "逍遥";
			elseif(9 == Fammily) then
				strMenPai = "无门派";
			elseif(10== Fammily) then
				strMenPai = "慕容";
			elseif(11== Fammily) then
				strMenPai = "唐门";
			elseif(12== Fammily) then
				strMenPai = "鬼谷";
			elseif(13== Fammily) then
				strMenPai = "#{XQ_MP_15}"; --桃花岛
			elseif(14== Fammily) then
				strMenPai = "#{XMPHM_210604_01}";
			elseif(15== Fammily) then--menpai15 mptpdp
				strMenPai = "#{GMGameInterface_Script_DataPool_Info_ERenGu}";
			end

			local strInfo = tostring(MemberName) .. "\n" .. tostring(strMenPai) .. "  " .. tostring(Level).. "级" .. "\n所在地：" .. ScenceName;
			Portrait_ToolTips[index]:SetToolTip(strInfo);
			Porttrait_Head[index]:SetToolTip(strInfo);

			if(-1 == HPValue) then
				-- 跨场景的情况。
				PARTY_HP[index]:SetToolTip("未知");
			else
				PARTY_HP[index]:SetToolTip(tostring(HPValue).."/"..tostring(HPMax));
			end;

			PartyFrame_ClerBufInfo(index);

			local nBuffNum = Raid:GetMemberBufNumByIdx(sIdx, mIdx)
			local nFindNum = nBuffNum --在修正nBuffNum之前获得它的值
			if(nFindNum > PARTY_IMPACT_NUM) then
				nFindNum = PARTY_IMPACT_NUM
			end
			if(nBuffNum > PARTY_BUFF_MAX) then
				nBuffNum = PARTY_BUFF_MAX
			end

			--从最多20个里面选取6个
			local BUFFINDEX_LIST = {} --这个list做局部变量即可
			do
				for jj=1,PARTY_BUFF_MAX do
					BUFFINDEX_LIST[jj] = -1;
				end

				local BuffPriority = {}

				local _,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,n39 = SystemSetup:GameGetData()
				if n39 ~= 1 then
					--以前的方式
					for jj=1,nFindNum do --最大40
						BuffPriority[jj] = {}
						BuffPriority[jj].key = jj-1;
						BuffPriority[jj].val = Raid:GetMemberBufPriorityByIdx(sIdx, mIdx, jj-1);
					end
	
					for jj=nFindNum,1,-1 do --最大40
						for kk=1,jj-1 do --最大40
							if BuffPriority[kk].val < BuffPriority[kk+1].val then
								BuffPriority[kk],BuffPriority[kk+1] = BuffPriority[kk+1],BuffPriority[kk]
							end
						end
					end
	
					for jj=1,nBuffNum do --最大6
						BUFFINDEX_LIST[jj] = BuffPriority[jj].key;
					end

				else
					local PreShowBuff ={}
					local count1 = 0
					local count2 = 0
					for jj=1,nFindNum do --最大40
						local isPre =  Raid:IsPreShowBuff(sIdx, mIdx, jj-1)
						if isPre > 0 then
							count1 = count1 + 1
							PreShowBuff[count1] = {}
							PreShowBuff[count1].key = jj - 1
							PreShowBuff[count1].val = isPre
						else
							count2 = count2 + 1
							BuffPriority[count2] = {}
							BuffPriority[count2].key = jj-1;
							BuffPriority[count2].val = Raid:GetMemberBufPriorityByIdx(sIdx, mIdx, jj-1);
						end
					end

					for jj=count1,1,-1 do --最大40
						for kk=1,jj-1 do 
							if PreShowBuff[kk].val < PreShowBuff[kk+1].val then
								PreShowBuff[kk],PreShowBuff[kk+1] = PreShowBuff[kk+1],PreShowBuff[kk]
							end
						end
					end

					for jj=count2,1,-1 do --最大40
						for kk=1,jj-1 do 
							if BuffPriority[kk].val < BuffPriority[kk+1].val then
								BuffPriority[kk],BuffPriority[kk+1] = BuffPriority[kk+1],BuffPriority[kk]
							end
						end
					end

					-- for jj=1,nBuffNum do --最大6
					-- 	if jj<=count1 then
					-- 		BUFFINDEX_LIST[jj] = PreShowBuff[jj].key
					-- 	else
					-- 		BUFFINDEX_LIST[jj] = BuffPriority[jj].key
					-- 	end
					-- end

					local jk = 1
					for jj=1,nBuffNum do --最大6
						if jj<=count1 then
							BUFFINDEX_LIST[jj] = PreShowBuff[jj].key
						else
							BUFFINDEX_LIST[jj] = BuffPriority[jk].key
							jk = jk + 1
						end
					end

				end
				
			end

			local i = 0;
			while i < nBuffNum do
				local szIconName;
				local szTipInfo;

				szIconName,szTipInfo = Raid:GetMemberBufInfoByIdx(sIdx, mIdx, BUFFINDEX_LIST[i+1]);
				--有图标则显示，没有图标则不显示，适用于没有图标的buff。
				--由于没有图标的buff根据优先级都排到最后去了，所以实际效果是最后几个没图标的buff不显示出来 62434~62437
				if szIconName and szTipInfo then
					PARTY_IMPACT_CTL[index][i+1]:SetProperty("ShortImage", szIconName);
					PARTY_IMPACT_CTL[index][i+1]:Show();
					PARTY_IMPACT_CTL[index][i+1]:SetToolTip(szTipInfo);
				else
					PARTY_IMPACT_CTL[index][i+1]:SetToolTip("");
					PARTY_IMPACT_CTL[index][i+1]:Hide();
				end

				i = i + 1;
			end

			while i < PARTY_BUFF_MAX do
				PARTY_IMPACT_CTL[index][i+1]:SetToolTip("");
				PARTY_IMPACT_CTL[index][i+1]:Hide();
				i = i + 1;
			end

			--PetButton_Show(index);
		end

		PartyFrame_UpdateShow2DHead()

		this:Show()
end

function PartyFrame_UpdateShow2DHead()
	if SystemSetup:IsClassic() == 1 then
		PartyFrame:SetProperty("UnifiedSize", "{{0.000000,163.000000},{0.000000,215.000000}}");
		PartyFrame:SetProperty("UnifiedPosition", "{{0.000000,0.000000},{0.000000,128.000000}}");
		PartyFrame2:SetProperty("UnifiedPosition", "{{0.000000,0.000000},{0.000000,41.000000}}");
		PartyFrame3:SetProperty("UnifiedPosition", "{{0.000000,0.000000},{0.000000,82.000000}}");
		PartyFrame4:SetProperty("UnifiedPosition", "{{0.000000,0.000000},{0.000000,123.000000}}");
		PartyFrame5:SetProperty("UnifiedPosition", "{{0.000000,0.000000},{0.000000,164.000000}}");
	end
	for	i=1, 5 do
		Portrait_ToolTips[i]:Show()
		Party_HeadFrame[i]:Show()
		Porttrait_Head_Parent[i]:Hide()
		if SystemSetup:IsClassic() == 1 then
			PARTYFRAMEs[i]:SetProperty("UnifiedSize", "{{0.000000,163.000000},{0.000000,41.000000}}");
			PartyFrame_BK[i]:SetProperty("Image", "set:CommonFrame18 image:TeamerFrame_BK");
			PartyFrame_BK[i]:SetProperty("UnifiedSize", "{{0.000000,143.000000},{0.000000,41.000000}}");
			Team_Member_Pet_Button[i]:SetProperty("UnifiedPosition", "{{0.000000,41.000000},{0.000000,27.000000}}");
			PartyFrame_BK[i]:SetProperty("UnifiedPosition", "{{0.000000,0.000000},{0.000000,0.000000}}");
			Raid_Flags[i]:SetProperty("UnifiedPosition", "{{0.000000,53.000000},{0.000000,27.000000}}");
			Party_Flags[i]:SetProperty("UnifiedPosition", "{{0.000000,53.000000},{0.000000,27.000000}}");
			PARTY_HP[i]:SetProperty("UnifiedPosition", "{{0.000000,42.000000},{0.000000,7.000000}}");
			UnLink_flag[i]:SetProperty("UnifiedPosition", "{{0.000000,21.000000},{0.000000,21.000000}}");
			PartyFrame_Buff_Frame[i]:SetProperty("UnifiedPosition", "{{0.000000,67.000000},{0.000000,18.000000}}");
		end
    end
end
