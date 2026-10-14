
local g_FubenID = {};
local g_FubenName = {};
local g_FubenDesc = {};
local g_FubentoLinenum = {};

local g_ZhengZhaoCtrl_Name = {};
local g_ZhengZhaoCtrl_Level = {};
local g_ZhengZhaoCtrl_MemberCount = {};
local g_ZhengZhaoCtrl_Select = {};
local g_ZhengZhaoCtrl_Button = {};

local g_CurFubenId = 0;
local g_iCurZhengZhaoIndex = 0;	--当前信息中第一个信息的序号
local g_iZhengZhaoCount = 0;		--征召总个数
local g_iCurPageZZCount = 0;		--当前页

local g_iPageCount = 0;			--页个数，用于显示
local g_iCurPageIndex = 0;	--当前页序号，用于显示
local g_lastClickTime = 0;	--上次点击时间

local MAX_COUNT_PER_PAGE	= 8		--每页显示征召的最大个数

function EnlistTeammate_PreLoad()

	-- 打开窗口界面
	this:RegisterEvent("ENLISTTEAMMATE_OPEN");

	-- 关闭窗口界面
	this:RegisterEvent("ENLISTTEAMMATE_CLOSE");

	-- 刷新队员信息
	this:RegisterEvent("ENLISTTEAMMATE_UPDATE_MEMBER");

end

function EnlistTeammate_OnLoad()

	--队长名
	g_ZhengZhaoCtrl_Name[1] = EnlistTeammate_ClientFrame_Left_info1_name;
	g_ZhengZhaoCtrl_Name[2] = EnlistTeammate_ClientFrame_Left_info2_name;
	g_ZhengZhaoCtrl_Name[3] = EnlistTeammate_ClientFrame_Left_info3_name;
	g_ZhengZhaoCtrl_Name[4] = EnlistTeammate_ClientFrame_Left_info4_name;
	g_ZhengZhaoCtrl_Name[5] = EnlistTeammate_ClientFrame_Left_info5_name;
	g_ZhengZhaoCtrl_Name[6] = EnlistTeammate_ClientFrame_Left_info6_name;
	g_ZhengZhaoCtrl_Name[7] = EnlistTeammate_ClientFrame_Left_info7_name;
	g_ZhengZhaoCtrl_Name[8] = EnlistTeammate_ClientFrame_Left_info8_name;

	--队长等级
	g_ZhengZhaoCtrl_Level[1] = EnlistTeammate_ClientFrame_Left_info1_level;
	g_ZhengZhaoCtrl_Level[2] = EnlistTeammate_ClientFrame_Left_info2_level;
	g_ZhengZhaoCtrl_Level[3] = EnlistTeammate_ClientFrame_Left_info3_level;
	g_ZhengZhaoCtrl_Level[4] = EnlistTeammate_ClientFrame_Left_info4_level;
	g_ZhengZhaoCtrl_Level[5] = EnlistTeammate_ClientFrame_Left_info5_level;
	g_ZhengZhaoCtrl_Level[6] = EnlistTeammate_ClientFrame_Left_info6_level;
	g_ZhengZhaoCtrl_Level[7] = EnlistTeammate_ClientFrame_Left_info7_level;
	g_ZhengZhaoCtrl_Level[8] = EnlistTeammate_ClientFrame_Left_info8_level;

	--队伍数量
	g_ZhengZhaoCtrl_MemberCount[1] = EnlistTeammate_ClientFrame_Left_info1_num;
	g_ZhengZhaoCtrl_MemberCount[2] = EnlistTeammate_ClientFrame_Left_info2_num;
	g_ZhengZhaoCtrl_MemberCount[3] = EnlistTeammate_ClientFrame_Left_info3_num;
	g_ZhengZhaoCtrl_MemberCount[4] = EnlistTeammate_ClientFrame_Left_info4_num;
	g_ZhengZhaoCtrl_MemberCount[5] = EnlistTeammate_ClientFrame_Left_info5_num;
	g_ZhengZhaoCtrl_MemberCount[6] = EnlistTeammate_ClientFrame_Left_info6_num;
	g_ZhengZhaoCtrl_MemberCount[7] = EnlistTeammate_ClientFrame_Left_info7_num;
	g_ZhengZhaoCtrl_MemberCount[8] = EnlistTeammate_ClientFrame_Left_info8_num;

	--队伍选中状态
	g_ZhengZhaoCtrl_Select[1] = EnlistTeammate_ClientFrame_Left_info1_Select;
	g_ZhengZhaoCtrl_Select[2] = EnlistTeammate_ClientFrame_Left_info2_Select;
	g_ZhengZhaoCtrl_Select[3] = EnlistTeammate_ClientFrame_Left_info3_Select;
	g_ZhengZhaoCtrl_Select[4] = EnlistTeammate_ClientFrame_Left_info4_Select;
	g_ZhengZhaoCtrl_Select[5] = EnlistTeammate_ClientFrame_Left_info5_Select;
	g_ZhengZhaoCtrl_Select[6] = EnlistTeammate_ClientFrame_Left_info6_Select;
	g_ZhengZhaoCtrl_Select[7] = EnlistTeammate_ClientFrame_Left_info7_Select;
	g_ZhengZhaoCtrl_Select[8] = EnlistTeammate_ClientFrame_Left_info8_Select;

	--申请入队按钮
	g_ZhengZhaoCtrl_Button[1] = EnlistTeammate_ClientFrame_Left_info1_Button;
	g_ZhengZhaoCtrl_Button[2] = EnlistTeammate_ClientFrame_Left_info2_Button;
	g_ZhengZhaoCtrl_Button[3] = EnlistTeammate_ClientFrame_Left_info3_Button;
	g_ZhengZhaoCtrl_Button[4] = EnlistTeammate_ClientFrame_Left_info4_Button;
	g_ZhengZhaoCtrl_Button[5] = EnlistTeammate_ClientFrame_Left_info5_Button;
	g_ZhengZhaoCtrl_Button[6] = EnlistTeammate_ClientFrame_Left_info6_Button;
	g_ZhengZhaoCtrl_Button[7] = EnlistTeammate_ClientFrame_Left_info7_Button;
	g_ZhengZhaoCtrl_Button[8] = EnlistTeammate_ClientFrame_Left_info8_Button;

	for iSel=1, MAX_COUNT_PER_PAGE do
		g_ZhengZhaoCtrl_Select[iSel]:Hide();
	end

	local iFubenCount = DataPool:GetZhengZhaoFubenCount();
	local linenum = 1
	for i=0, iFubenCount-1 do
		local FubenId, FubenName, FubenDesc, is2606SHide = DataPool:GetZhengZhaoFubenInfo( i );
		if is2606SHide == 1 and Player:GetData("Is2606S") == 1 then
			continue
		end
		if FubenId ~= nil and g_FubenID[FubenId] == nil then 
			g_FubenID[FubenId] = FubenId;
			g_FubenName[FubenId] = FubenName;
			g_FubenDesc[FubenId] = FubenDesc;
			g_FubentoLinenum[FubenId] = linenum
			EnlistTeammate_HeadFrame_select:AddTextItem( g_FubenName[FubenId], g_FubenID[FubenId] );
			linenum = linenum + 1
		end
	end
end

function EnlistTeammate_OnEvent(event)

	if ( event == "ENLISTTEAMMATE_OPEN" ) then
		this:Show();

		EnlistTeammate_UpdateData();
	end

	if ( event == "ENLISTTEAMMATE_CLOSE" ) then
		this:Hide();
	end

	if ( event == "ENLISTTEAMMATE_UPDATE_MEMBER" ) then
		if nil ~= arg0  then
			EnlistTeammate_UpdateMemberInfo( tonumber(arg0), 1 );	--参数为征召Index和是否刷新队伍信息
		end

	end

end 
function EnlistTeammate_UpdateData()

	local iFubenId = DataPool:GetZhengZhaoFubenID();
	--先清空
	for _i=1, MAX_COUNT_PER_PAGE do
		g_ZhengZhaoCtrl_Name[_i]:SetText( "" );
		g_ZhengZhaoCtrl_Level[_i]:SetText( "" );
		g_ZhengZhaoCtrl_MemberCount[_i]:SetText( "" );
		g_ZhengZhaoCtrl_Button[_i]:Hide();
	end
	EnlistTeammate_BottomFrame_Up:Disable();
	EnlistTeammate_BottomFrame_Down:Disable();
	EnlistTeammate_ClearSelected();

	--重置队伍信息
	EnlistTeammate_ClientFrame_RightTitle:RemoveAllItem();

	local Comlinenum = g_FubenID[iFubenId] 
	--选择副本名称
	if g_FubenID[iFubenId] ~= nil then
		EnlistTeammate_HeadFrame_select:SetCurrentSelect( g_FubentoLinenum[g_FubenID[iFubenId]]-1 );
	end

	--显示进入条件
	if g_FubenDesc[iFubenId] ~= nil then
		EnlistTeammate_HeadFrame_info:SetText( g_FubenDesc[iFubenId] );
	end

	--显示页信息
	g_iCurZhengZhaoIndex = DataPool:GetZhengZhaoCurIndex();	--当前信息中第一个信息的序号
	g_iZhengZhaoCount = DataPool:GetZhengZhaoAllCount();		--征召总个数
	g_iCurPageZZCount = DataPool:GetZhengZhaoCurPageCount();
	g_iPageCount = math.floor(g_iZhengZhaoCount/MAX_COUNT_PER_PAGE);
	if math.mod(g_iZhengZhaoCount, MAX_COUNT_PER_PAGE) > 0 then
		g_iPageCount = g_iPageCount + 1;
	end
	g_iCurPageIndex = math.floor( g_iCurZhengZhaoIndex / MAX_COUNT_PER_PAGE) + 1;
	if g_iCurPageIndex <= 0 then
		g_iCurPageIndex = 1;
	end
	if g_iPageCount <= 0 then
		g_iPageCount = 1;
	end
	EnlistTeammate_BottomFrame_num:SetText( g_iCurPageIndex.."/"..g_iPageCount );	--显示的是页数
	if g_iCurPageIndex > 1 then
		EnlistTeammate_BottomFrame_Up:Enable();
	end
	if g_iCurPageIndex < g_iPageCount then
		EnlistTeammate_BottomFrame_Down:Enable();
	end

	--更新征召队伍信息
	if g_iCurPageZZCount > MAX_COUNT_PER_PAGE then
		g_iCurPageZZCount = MAX_COUNT_PER_PAGE;
	end

	local iSelZhengZhao = 1;
	for iZhengZhao=0, g_iCurPageZZCount-1 do
		local strLeaderName = DataPool:GetZhengZhaoInfo( iZhengZhao, "CharName" );
		local iLevel = DataPool:GetZhengZhaoInfo( iZhengZhao, "CharLevel" );
		local iMemberCount = DataPool:GetZhengZhaoInfo( iZhengZhao, "MemberCount" );
		local iNeedCount = DataPool:GetZhengZhaoInfo( iZhengZhao, "NeedCount" );

		g_ZhengZhaoCtrl_Name[iZhengZhao+1]:SetText( strLeaderName );
		g_ZhengZhaoCtrl_Level[iZhengZhao+1]:SetText( tostring(iLevel) );
		g_ZhengZhaoCtrl_MemberCount[iZhengZhao+1]:SetText( tostring(iMemberCount).."/"..tostring(iNeedCount) );
		g_ZhengZhaoCtrl_Button[iZhengZhao+1]:Show();

		if DataPool:GetZhengZhaoInfo( iZhengZhao, "IsSelected" ) == 1 then
			iSelZhengZhao = iZhengZhao+1;
		end

	end

	EnlistTeammate_OnItemClicked( iSelZhengZhao );
	EnlistTeammate_UpdateMemberInfo( iSelZhengZhao-1, 0 );

	g_CurFubenId = iFubenId;

end

--副本名称变化
function EnlistTeammate_OnFubenLineChanged()

	local str, iFubenId = EnlistTeammate_HeadFrame_select:GetCurrentSelect()

	--刷新征召队伍信息
	EnlistTeammate_ApplyZhengZhaoInfo( iFubenId, 0, 0, 0 );	--请求选定副本的第一个

end

--申请入队 index(1~6)
function EnlistTeammate_OnApply( index )
	if index < 1 or index > g_iCurPageZZCount then
		return;
	end
	if IsInTServer() == 1 then
		PushDebugMessage("#{BHKF_140909_327}")
		return
	end
	DataPool:ApplyZhengZhaoTeam( g_CurFubenId, index-1 );	--参数还不确定
end

--选中某一个征召项
function EnlistTeammate_OnItemClicked( index )
	if index < 1 or index > g_iCurPageZZCount then
		return;
	end

	EnlistTeammate_ClearSelected();
	DataPool:AskZhengZhaoMemberInfo( index-1 );
	g_ZhengZhaoCtrl_Select[index]:Show();

end

function EnlistTeammate_UpdateMemberInfo( iZhengZhaoIndex, bUpdateTeam )

	if iZhengZhaoIndex < 0 or iZhengZhaoIndex >= g_iCurPageZZCount then
		return;
	end

	local iCount = DataPool:GetZZMemberInfoCount( iZhengZhaoIndex );

	--更新队伍信息
	if bUpdateTeam == 1 then
		local strLeaderName = DataPool:GetZhengZhaoInfo( iZhengZhaoIndex, "CharName" );
		local iLevel = DataPool:GetZhengZhaoInfo( iZhengZhaoIndex, "CharLevel" );
		local iMemberCount = DataPool:GetZhengZhaoInfo( iZhengZhaoIndex, "MemberCount" );
		local iNeedCount = DataPool:GetZhengZhaoInfo( iZhengZhaoIndex, "NeedCount" );

		g_ZhengZhaoCtrl_Name[iZhengZhaoIndex+1]:SetText( strLeaderName );
		g_ZhengZhaoCtrl_Level[iZhengZhaoIndex+1]:SetText( tostring(iLevel) );
		g_ZhengZhaoCtrl_MemberCount[iZhengZhaoIndex+1]:SetText( tostring(iMemberCount).."/"..tostring(iNeedCount) );

		if iCount <= 0 then
			PushDebugMessage("#{ZZDY_130131_92}" );
		end
	end

	--右侧显示队员信息
	EnlistTeammate_ClientFrame_RightTitle:RemoveAllItem();
	for i=0, iCount-1 do
		local strCharName = DataPool:GetZZMemberInfo( iZhengZhaoIndex, i, "CharName" );
		local iLevel = DataPool:GetZZMemberInfo( iZhengZhaoIndex, i, "CharLevel" );
		local iMenpai = DataPool:GetZZMemberInfo( iZhengZhaoIndex, i, "CharMempai" );
		local strMenpai = EnlistTeammate_GetMenpaiString( iMenpai );
		if strCharName == nil or iLevel == nil or iMenpai == nil or strMenpai == "" then
			break;
		end

		EnlistTeammate_ClientFrame_RightTitle:AddNewItem( strCharName, 0, i );
		EnlistTeammate_ClientFrame_RightTitle:AddNewItem( tostring(iLevel), 1, i );
		EnlistTeammate_ClientFrame_RightTitle:AddNewItem( strMenpai, 2, i );
	end

end

-- 上一页
function EnlistTeammate_OnPrevPage()

	--请求本副本的上一页
	if g_iCurZhengZhaoIndex-MAX_COUNT_PER_PAGE >= 0 then
		EnlistTeammate_ApplyZhengZhaoInfo( g_CurFubenId, g_iCurZhengZhaoIndex-MAX_COUNT_PER_PAGE, 0, 1 );
	else
		EnlistTeammate_ApplyZhengZhaoInfo( g_CurFubenId, 0, 0, 1 );
	end

end

-- 下一页
function EnlistTeammate_OnNextPage()
	--请求本副本的下一页
	if g_iCurZhengZhaoIndex+MAX_COUNT_PER_PAGE < g_iZhengZhaoCount then
		EnlistTeammate_ApplyZhengZhaoInfo( g_CurFubenId, g_iCurZhengZhaoIndex+MAX_COUNT_PER_PAGE, 1, 1 );
	else
		EnlistTeammate_ApplyZhengZhaoInfo( g_CurFubenId, g_iCurZhengZhaoIndex, 1, 1 );
	end

end

-- 刷新
function EnlistTeammate_OnUpdate()

	--重新请求本副本的当前页
	EnlistTeammate_ApplyZhengZhaoInfo( g_CurFubenId, g_iCurZhengZhaoIndex, 0, 1 );

end

-- 关闭
function EnlistTeammate_OnClosed()
	this:Hide();
end

function EnlistTeammate_ClearSelected()
	for i=1, MAX_COUNT_PER_PAGE do
		g_ZhengZhaoCtrl_Select[i]:Hide();
	end
end

function EnlistTeammate_ApplyZhengZhaoInfo( iFubenId, iIndex, bNextPage, delay )

	if delay == 1 then
		local iCur = FindFriendDataPool:GetTickCount();
		if iCur - g_lastClickTime < 4000 then
			PushDebugMessage("#{ZZDY_130131_88}");
			return;
		else
			g_lastClickTime = iCur;
		end
	end

	for _i=1, MAX_COUNT_PER_PAGE do
		g_ZhengZhaoCtrl_Name[_i]:SetText( "" );
		g_ZhengZhaoCtrl_Level[_i]:SetText( "" );
		g_ZhengZhaoCtrl_MemberCount[_i]:SetText( "" );
		g_ZhengZhaoCtrl_Button[_i]:Hide();
	end
	EnlistTeammate_ClientFrame_RightTitle:RemoveAllItem();
	EnlistTeammate_ClearSelected();

	DataPool:ApplyZhengZhaoInfo( iFubenId, iIndex, bNextPage );

end

function EnlistTeammate_GetMenpaiString( menpai )
	local strName = "";

	-- 得到门派名称.
	if(0 == menpai) then
		strName = "少林";

	elseif(1 == menpai) then
		strName = "明教";

	elseif(2 == menpai) then
		strName = "丐帮";

	elseif(3 == menpai) then
		strName = "武当";

	elseif(4 == menpai) then
		strName = "峨嵋";

	elseif(5 == menpai) then
		strName = "星宿";

	elseif(6 == menpai) then
		strName = "天龙";

	elseif(7 == menpai) then
		strName = "天山";

	elseif(8 == menpai) then
		strName = "逍遥";

	elseif(9 == menpai) then
		strName = "无门派";

	elseif(10== menpai) then
		strName = "慕容";

	elseif(11== menpai) then
		strName = "唐门";
		
	elseif(12== menpai) then
		strName = "鬼谷";
	elseif(13== menpai) then
		strName = "#{XQ_MP_15}"; --桃花岛
	elseif(14== menpai) then
		strName = "#{XMPHM_210604_01}"; 
	elseif(15== menpai) then--menpai15 mptodo
		strName = "#{GMGameInterface_Script_DataPool_Info_ERenGu}"; 
	end

	return strName;
end


