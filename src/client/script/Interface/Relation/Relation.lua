
local Relation_NpcInfo1 ={
						 	{id=1,name="萧峰",index=99,head="set:CommonNPCHeader12 image:CommonNPCHeader12_2"},
							{id=2,name="段誉",index=95,head="set:CommonNPCHeader12 image:CommonNPCHeader12_3"},
							{id=3,name="虚竹",index=102,head="set:CommonNPCHeader12 image:CommonNPCHeader12_1"},
						}
local Relation_NpcInfo2 ={
						 	{id=1,name="木婉清",index=92,head="set:CommonNPCHeader12 image:CommonNPCHeader12_9"},
							{id=2,name="钟灵",index=93,head="set:CommonNPCHeader12 image:CommonNPCHeader12_13"},
							{id=3,name="阿朱",index=96,head="set:CommonNPCHeader12 image:CommonNPCHeader12_11"},
							{id=4,name="王语嫣",index=98,head="set:CommonNPCHeader12 image:CommonNPCHeader12_8"},
							{id=5,name="阿碧",index=97,head="set:CommonNPCHeader12 image:CommonNPCHeader12_12"},
							{id=6,name="阿紫",index=100,head="set:CommonNPCHeader12 image:CommonNPCHeader12_10"},
							{id=7,name="银川公主",index=104,head="set:CommonNPCHeader12 image:CommonNPCHeader12_7"},
						}
local Relation_NpcInfo3 ={
						 	{id=1,name="段延庆",index=94,head="set:CommonNPCHeader12 image:CommonNPCHeader12_4"},
							{id=2,name="鸠摩智",index=103,head="set:CommonNPCHeader12 image:CommonNPCHeader12_6"},
							{id=3,name="慕容复",index=101,head="set:CommonNPCHeader12 image:CommonNPCHeader12_5"},
						}

local Relation_NpcInfoNumber = { 3, 7, 3, };
local Relation_CurrentPage = 0;
local Relation_NumPerPage = 4;
local Relation_CurType = 0;
local RELATION_NPC_BACK = {};
local RELATION_NPC_NAME = {};
local RELATION_NPC_HEAD = {};
local RELATION_NPC_CURRENT = {};
local RELATION_NPC_PROGRESS1 = {};
local RELATION_NPC_PROGRESS2 = {};
local RELATION_NPC_PROGRESS3 = {};

--仇敌相关
local RELATION_CHAR_CHOUDI = {};
local RELATION_CHAR_PROGRESS_BACK = {};
local RELATION_CHAR_PROGRESS_VALUE= {};
local RELATION_CHAR_NAME = {};
local RELATION_CHAR_CURRENT = {};
-- 界面的默认相对位置
local g_Relation_Frame_UnifiedXPosition;
local g_Relation_Frame_UnifiedYPosition;

--仇敌数量
local Relation_FoeNum = 0;

--===============================================
-- PreLoad
--===============================================
function Relation_PreLoad()
	this:RegisterEvent("CHANGE_SWEAR_TITLE");
	this:RegisterEvent("OPEN_WINDOW");

	this:RegisterEvent("SHOW_FOE_RELATION");
	this:RegisterEvent("UPDATE_RELATION_FOE_INHIBIT");
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

--===============================================
-- OnLoad
--===============================================
function Relation_OnLoad()
	RELATION_NPC_BACK[1]= Relation_NPC1_Back;
	RELATION_NPC_BACK[2]= Relation_NPC2_Back;
	RELATION_NPC_BACK[3]= Relation_NPC3_Back;
	RELATION_NPC_BACK[4]= Relation_NPC4_Back;

	RELATION_NPC_NAME[1]= Relation_NPC1_Name;
	RELATION_NPC_NAME[2]= Relation_NPC2_Name;
	RELATION_NPC_NAME[3]= Relation_NPC3_Name;
	RELATION_NPC_NAME[4]= Relation_NPC4_Name;

	RELATION_NPC_HEAD[1]= Relation_Head1;
	RELATION_NPC_HEAD[2]= Relation_Head2;
	RELATION_NPC_HEAD[3]= Relation_Head3;
	RELATION_NPC_HEAD[4]= Relation_Head4;

	RELATION_NPC_CURRENT[1]= Relation_NPC1_Current;
	RELATION_NPC_CURRENT[2]= Relation_NPC2_Current;
	RELATION_NPC_CURRENT[3]= Relation_NPC3_Current;
	RELATION_NPC_CURRENT[4]= Relation_NPC4_Current;
	
	RELATION_NPC_PROGRESS1[1]= Relation_NPC1_Pic1;
	RELATION_NPC_PROGRESS1[2]= Relation_NPC2_Pic1;
	RELATION_NPC_PROGRESS1[3]= Relation_NPC3_Pic1;
	RELATION_NPC_PROGRESS1[4]= Relation_NPC4_Pic1;

	RELATION_NPC_PROGRESS2[1]= Relation_NPC1_Pic2;
	RELATION_NPC_PROGRESS2[2]= Relation_NPC2_Pic2;
	RELATION_NPC_PROGRESS2[3]= Relation_NPC3_Pic2;
	RELATION_NPC_PROGRESS2[4]= Relation_NPC4_Pic2;

	RELATION_NPC_PROGRESS3[1]= Relation_NPC1_Pic3;
	RELATION_NPC_PROGRESS3[2]= Relation_NPC2_Pic3;
	RELATION_NPC_PROGRESS3[3]= Relation_NPC3_Pic3;
	RELATION_NPC_PROGRESS3[4]= Relation_NPC4_Pic3;

	--仇敌页
	RELATION_CHAR_CHOUDI[1]= Relation_ChouDi01_Back;
	RELATION_CHAR_CHOUDI[2]= Relation_ChouDi02_Back;
	RELATION_CHAR_CHOUDI[3]= Relation_ChouDi03_Back;
	RELATION_CHAR_CHOUDI[4]= Relation_ChouDi04_Back;

	RELATION_CHAR_PROGRESS_BACK[1]= Relation_ChouDi01_Pic02;
	RELATION_CHAR_PROGRESS_BACK[2]= Relation_ChouDi02_Pic02;
	RELATION_CHAR_PROGRESS_BACK[3]= Relation_ChouDi03_Pic02;
	RELATION_CHAR_PROGRESS_BACK[4]= Relation_ChouDi04_Pic02;

	RELATION_CHAR_PROGRESS_VALUE[1]= Relation_ChouDi01_Pic01;
	RELATION_CHAR_PROGRESS_VALUE[2]= Relation_ChouDi02_Pic01;
	RELATION_CHAR_PROGRESS_VALUE[3]= Relation_ChouDi03_Pic01;
	RELATION_CHAR_PROGRESS_VALUE[4]= Relation_ChouDi04_Pic01;

	RELATION_CHAR_NAME[1]= Relation_ChouDi01_Name01;
	RELATION_CHAR_NAME[2]= Relation_ChouDi02_Name01;
	RELATION_CHAR_NAME[3]= Relation_ChouDi03_Name01;
	RELATION_CHAR_NAME[4]= Relation_ChouDi04_Name01;

	RELATION_CHAR_CURRENT[1]= Relation_ChouDi01_Current01;
	RELATION_CHAR_CURRENT[2]= Relation_ChouDi02_Current01;
	RELATION_CHAR_CURRENT[3]= Relation_ChouDi03_Current01;
	RELATION_CHAR_CURRENT[4]= Relation_ChouDi04_Current01;

	-- 保存界面的默认相对位置
	g_Relation_Frame_UnifiedXPosition	= Relation_Frame : GetProperty("UnifiedXPosition");
	g_Relation_Frame_UnifiedYPosition	= Relation_Frame : GetProperty("UnifiedYPosition");

end

--===============================================
-- OnEvent
--===============================================
function Relation_OnEvent(event)

	if( event =="OPEN_WINDOW" ) then

		if( arg0 == "Relation" ) then

			--Added	by	lx	for：个人仇敌
			if Relation_CurType >= 3 then
				DataPool:ShowFoeRelation();
			end
			--lx	add	end
			Relation_Update();
			this:Show();
		end
	end

	if (event == "SHOW_FOE_RELATION") then
		--设置界面下方按钮状态
		Relation_ZhuJue:SetCheck(0);
		Relation_Meinv:SetCheck(0);
		Relation_XiaoXiong:SetCheck(0);
		Relation_ChouDi:SetCheck(1);

		Relation_OnPageClick(4);
		
		this:Show();
	end

	if (event == "UPDATE_RELATION_FOE_INHIBIT") then
		local curType = tonumber(Relation_CurType)
		if curType == 4 then
			Relation_UpdateChar();
		end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		Relation_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置	
		Relation_Frame_On_ResetPos()
	end

end

function Relation_Update()
	local curType = tonumber(Relation_CurType)
	Relation_HideAll();
	if curType < 3 then
		Relation_UpdateNPC();
	else 
		Relation_UpdateChar();
	end
end

function Relation_UpdateChar()
	
	local curType = tonumber(Relation_CurType)
	
	if curType < 3 then
		return;
	end

	Relation_FoeNum = DataPool:GetFriendNumber(7);
	local curMax = Relation_FoeNum - 1;
	local curIndex = (Relation_CurrentPage * Relation_NumPerPage);
	if (curIndex + Relation_NumPerPage < Relation_FoeNum) then
		curMax = curIndex + Relation_NumPerPage - 1;
	end

	for i = curIndex, curMax do
		local j = i - Relation_CurrentPage * Relation_NumPerPage;

		RELATION_CHAR_CHOUDI[j + 1]:Show();
		RELATION_CHAR_PROGRESS_BACK[j + 1]:Show();
		--设置名字
		local selfName = tostring(Player:GetName());
		local targetName = tostring(DataPool:GetFriend(7, i, "NAME"));
		RELATION_CHAR_NAME[j + 1]:SetText(selfName .. " VS " .. targetName);
		RELATION_CHAR_NAME[j + 1]:Show();

		--显示压制值相关
		local selfPoint = DataPool:GetFriend(7, i, "FRIENDSHIP");
		local targetPoint = 1000 - selfPoint;
		RELATION_CHAR_PROGRESS_VALUE[j + 1]:Show();
		RELATION_CHAR_PROGRESS_VALUE[j + 1]:SetProgress(tonumber(selfPoint), 1000);

		if (selfPoint <= 100) then
			RELATION_CHAR_CURRENT[j + 1]:SetText("" .. tostring(selfPoint) .. "/" .. tostring(targetPoint) .. "(#{CDXT_110503_14})");
		elseif (selfPoint <= 200) then
			RELATION_CHAR_CURRENT[j + 1]:SetText("" .. tostring(selfPoint) .. "/" .. tostring(targetPoint) .. "(#{CDXT_110503_15})");
		elseif (selfPoint <= 300) then
			RELATION_CHAR_CURRENT[j + 1]:SetText("" .. tostring(selfPoint) .. "/" .. tostring(targetPoint) .. "(#{CDXT_110503_16})");
		elseif (selfPoint <= 400) then
			RELATION_CHAR_CURRENT[j + 1]:SetText("" .. tostring(selfPoint) .. "/" .. tostring(targetPoint) .. "(#{CDXT_110503_17})");
		elseif (selfPoint <= 500) then
			RELATION_CHAR_CURRENT[j + 1]:SetText("" .. tostring(selfPoint) .. "/" .. tostring(targetPoint) .. "(#{CDXT_110503_18})");
		elseif (selfPoint <= 600) then
			RELATION_CHAR_CURRENT[j + 1]:SetText("" .. tostring(selfPoint) .. "/" .. tostring(targetPoint) .. "(#{CDXT_110503_19})");
		elseif (selfPoint <= 700) then
			RELATION_CHAR_CURRENT[j + 1]:SetText("" .. tostring(selfPoint) .. "/" .. tostring(targetPoint) .. "(#{CDXT_110503_20})");
		elseif (selfPoint <= 800) then
			RELATION_CHAR_CURRENT[j + 1]:SetText("" .. tostring(selfPoint) .. "/" .. tostring(targetPoint) .. "(#{CDXT_110503_21})");
		elseif (selfPoint <= 900) then
			RELATION_CHAR_CURRENT[j + 1]:SetText("" .. tostring(selfPoint) .. "/" .. tostring(targetPoint) .. "(#{CDXT_110503_22})");
		else
			RELATION_CHAR_CURRENT[j + 1]:SetText("" .. tostring(selfPoint) .. "/" .. tostring(targetPoint) .. "(#{CDXT_110503_23})");
		end

		RELATION_CHAR_CURRENT[j + 1]:Show();
	end

	--向下按钮可用判断
	if (curIndex + Relation_NumPerPage < Relation_FoeNum) then
		Relation_UPdata2:Enable();
	else
		Relation_UPdata2:Disable();
	end

	--向上按钮可用判断
	if( Relation_CurrentPage > 0 ) then
		Relation_UPdata1:Enable();
	else
		Relation_UPdata1:Disable();
	end

end

function Relation_HideAll()
	for i = 1, 4 do
		RELATION_NPC_BACK[i]:Hide();
		RELATION_NPC_NAME[i]:Hide();
		RELATION_NPC_HEAD[i]:Hide();
		RELATION_NPC_CURRENT[i]:Hide();
		RELATION_NPC_PROGRESS1[i]:Hide();
		RELATION_NPC_PROGRESS2[i]:Hide();
		RELATION_NPC_PROGRESS3[i]:Hide();

		RELATION_CHAR_CHOUDI[i]:Hide();
		RELATION_CHAR_PROGRESS_BACK[i]:Hide();
		RELATION_CHAR_PROGRESS_VALUE[i]:Hide();
		RELATION_CHAR_NAME[i]:Hide();
		RELATION_CHAR_CURRENT[i]:Hide();
	end
end

--旧代码中的Relation_Update()方法，为了避免出问题，这里做了修改
function Relation_UpdateNPC()
	

	local CurrentNpcInfo;
	if( tonumber( Relation_CurType ) == 0 ) then
		CurrentNpcInfo = Relation_NpcInfo1;
	elseif( tonumber( Relation_CurType ) == 1 ) then
		CurrentNpcInfo = Relation_NpcInfo2;
	else
		CurrentNpcInfo = Relation_NpcInfo3;
	end
	
	local maxNumber = tonumber( Relation_NpcInfoNumber[ Relation_CurType + 1 ] );
	
	if( tonumber( Relation_CurrentPage * Relation_NumPerPage ) >= tonumber( maxNumber ) ) then
		Relation_CurrentPage = Relation_CurrentPage - 1;
	end
	for i = 1, Relation_NumPerPage do
		RELATION_NPC_BACK[i]:Hide();
	end
	
	local curPageNumber = maxNumber - Relation_CurrentPage * Relation_NumPerPage;
	local curIndex;
	if( curPageNumber > Relation_NumPerPage ) then
		curPageNumber = Relation_NumPerPage;
		Relation_UPdata2:Enable();
	else
		Relation_UPdata2:Disable();
	end
	if( Relation_CurrentPage > 0 ) then
		Relation_UPdata1:Enable();
	else
		Relation_UPdata1:Disable();
	end
		
	for i = 1, curPageNumber do
		RELATION_NPC_BACK[ i ]:Show();
		curIndex = Relation_CurrentPage * Relation_NumPerPage + i;

		nRelationPoint = DataPool:GetPlayerMission_DataRound(CurrentNpcInfo[ curIndex ].index);
--设置任务名字		
		RELATION_NPC_NAME[i]:SetText( CurrentNpcInfo[ curIndex ].name );
		--added	by	lx
		RELATION_NPC_NAME[i]:Show();
--这里设置任务头像
		RELATION_NPC_HEAD[i]:SetProperty("Image",CurrentNpcInfo[ curIndex ].head);
		RELATION_NPC_HEAD[i]:Show();
		RELATION_NPC_PROGRESS1[ i ]:Hide();
		RELATION_NPC_PROGRESS2[ i ]:Hide();
		RELATION_NPC_PROGRESS3[ i ]:Hide();
		if nRelationPoint<=999  then
			RELATION_NPC_CURRENT[i]:SetText( "一面之交(" .. tostring(nRelationPoint) .. "/999)" );
			RELATION_NPC_PROGRESS1[i]:Show();
			RELATION_NPC_PROGRESS1[i]:SetProgress( nRelationPoint,999 );
		elseif nRelationPoint<=1999  then
			RELATION_NPC_CURRENT[i]:SetText( "君子之交(" .. tostring(nRelationPoint) .. "/1999)" );
			RELATION_NPC_PROGRESS2[i]:Show();
			RELATION_NPC_PROGRESS2[i]:SetProgress( (nRelationPoint - 999 ) , 1000 );
		elseif nRelationPoint<=3999  then
			RELATION_NPC_CURRENT[i]:SetText( "莫逆之交(" .. tostring(nRelationPoint) .. "/3999)" );
			RELATION_NPC_PROGRESS3[i]:Show();
			RELATION_NPC_PROGRESS3[i]:SetProgress( (nRelationPoint - 1999 ) , 2000 );
		elseif nRelationPoint<=6499  then
			RELATION_NPC_CURRENT[i]:SetText( "八拜之交(" .. tostring(nRelationPoint) .. "/6499)" );
			RELATION_NPC_PROGRESS3[i]:Show();
			RELATION_NPC_PROGRESS3[i]:SetProgress( (nRelationPoint - 3999 ) , 2500 );
		elseif nRelationPoint<=9999  then
			RELATION_NPC_CURRENT[i]:SetText( "刎颈之交(" .. tostring(nRelationPoint) .. "/9999)" );
			RELATION_NPC_PROGRESS3[i]:Show();
			RELATION_NPC_PROGRESS3[i]:SetProgress( (nRelationPoint - 6499 ) , 3500 );
		end
		RELATION_NPC_CURRENT[i]:Show();
	end
end

function Relation_PageUp()
	Relation_CurrentPage = Relation_CurrentPage - 1;
	if( Relation_CurrentPage < 0 ) then
		Relation_CurrentPage = 0;
	end
	Relation_Update();
end

function Relation_PageDown()
	Relation_CurrentPage = Relation_CurrentPage + 1;
	Relation_Update();
end

function Relation_OnPageClick( index )
	Relation_CurType = index;
	Relation_CurrentPage = 0;
	--Added	by	lx	for:个人仇敌
	if index >= 3 then
		DataPool:ShowFoeRelation();
	end
	--lx	add	end
	Relation_Update();
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Relation_Frame_On_ResetPos()

	Relation_Frame : SetProperty("UnifiedXPosition", g_Relation_Frame_UnifiedXPosition);
	Relation_Frame : SetProperty("UnifiedYPosition", g_Relation_Frame_UnifiedYPosition);

end
