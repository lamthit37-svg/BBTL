
local g_NewMembersCtl = {};
local g_TabSel = -1;
local g_ListToMember;
local g_MemberSel = {};

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

local g_menpaiInfo = {
	"少林",
	"明教",
	"丐帮",
	"武当",
	"峨嵋",
	"星宿",
	"天龙",
	"天山",
	"逍遥",
	"无门派",
	"慕容",
	"唐门",
	"鬼谷",
	"#{XQ_MP_15}",	--桃花岛
	"#{XMPHM_210604_01}",
	"#{GMGameInterface_Script_DataPool_Info_ERenGu}",--menpai15 mptodo
};


function Bhls_TeamInfo_PreLoad()

	this:RegisterEvent("ZHANTUAN_RANK_DETAIL");
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end


function Bhls_TeamInfo_OnLoad()

	--PushDebugMessage("Bhls_TeamInfo_OnLoad...");
	g_NewMembersCtl = {
						header = Bhls_TeamInfo_DragTitle,
						info = {
									{txt = Bhls_TeamInfo_Name, msg = "",},
									{txt = Bhls_TeamInfo_ID, msg = "",},
									{txt = Bhls_TeamInfo_Num, msg = "",},
									{txt = Bhls_TeamInfo_Fight, msg = "",},
									{txt = Bhls_TeamInfo_Score, msg = "",},
									{txt = Bhls_TeamInfo_Top, msg = "",},
									{txt = Bhls_TeamInfo_Result, msg = "",},
								},
					 };
end


function Bhls_TeamInfo_OnEvent(event)
	if ( event == "ZHANTUAN_RANK_DETAIL" ) then
		--PushDebugMessage("Bhls_TeamInfo_OnEvent ZHANTUAN_RANK_DETAIL...");
		--ZhanTuanInterface:GetZhanTuanInfo();
		this:Show();
		Bhls_TeamInfo_Update();
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
end

function Bhls_TeamInfo_Update()
	--PushDebugMessage("Bhls_TeamInfo_Update...");

	g_ListToMember = {};
	local listidx = 0;
	local List;
	
	List = Bhls_TeamInfo_List;
	List:RemoveAllItem();
	local i = 0;
	local nTZID	= ZhanTuanInterface:GetZhanTuanRankInfo(0, "TZID");
	local nTZName	= ZhanTuanInterface:GetZhanTuanRankInfo(0, "TZName");
	local nTZPoint	= ZhanTuanInterface:GetZhanTuanRankInfo(0, "TZPoint");
	local nTZScore	= ZhanTuanInterface:GetZhanTuanRankInfo(0, "TZScore");
	local nAllCount	= ZhanTuanInterface:GetZhanTuanRankInfo(0, "AllCount");
	local nWinCount	= ZhanTuanInterface:GetZhanTuanRankInfo(0, "WinCount");
	local nCurrentRankPosition	= ZhanTuanInterface:GetZhanTuanRankInfo(0, "CurrentRankPosition");
	local nAllEquipPoint = ZhanTuanInterface:GetZhanTuanRankInfo(0, "AllEquipPoint")
	local nProbability	= 0;
	if(0 < nAllCount) then
		nProbability = nWinCount/nAllCount*100;
	end
	local nZTLGUID	= "";
	local strZhanJi = ScriptGlobal_Format("#{BHKF_140909_245}", tostring(nWinCount), tostring(nAllCount), tostring(nProbability));--本赛季大区赛战绩

	g_NewMembersCtl.info[1].txt:SetText(nTZName);
	g_NewMembersCtl.info[2].txt:SetText(nTZID);
	
	while i < 40 do
		nZTLGUID = ZhanTuanInterface:GetZhanTuanRankInfo(i, "ZTLGUID");
		if ( "" ~= nZTLGUID ) then
			i = i + 1;
			continue
		end
		
		local szName = ZhanTuanInterface:GetZhanTuanRankInfo(i, "ZTLName");
		local nMenpai = ZhanTuanInterface:GetZhanTuanRankInfo(i, "ZTLMenpai")
		local level = ZhanTuanInterface:GetZhanTuanRankInfo(i, "ZTLLevel")
		local nZTLPosition = ZhanTuanInterface:GetZhanTuanRankInfo(i, "ZTLPosition")
		
		local nPosition = "";
		if(1 == nZTLPosition) then
			nPosition = "★";
		elseif(2 == nZTLPosition) then
			nPosition = "●";
		else
			nPosition = "";
		end
		List:AddNewItem("#P"..nPosition, 0, listidx);
		List:AddNewItem("#P"..szName, 1, listidx);
		List:AddNewItem("#P"..g_menpaiInfo[nMenpai+1], 2, listidx);
		List:AddNewItem("#P"..level, 3, listidx);
		g_ListToMember[listidx] = listidx;
		
		listidx = listidx + 1;
		i = i + 1;
	end
	
	g_NewMembersCtl.info[4].txt:SetText(nAllEquipPoint);
	g_NewMembersCtl.info[5].txt:SetText(nCurrentRankPosition);
	g_NewMembersCtl.info[6].txt:SetText(nTZPoint);
	g_NewMembersCtl.info[7].txt:SetText(strZhanJi);
	--PushDebugMessage("Bhls_TeamInfo_Update...nTZName..."..nTZName);
	
	local strMemberCount = ScriptGlobal_Format("#{BHKF_140909_246}", listidx, "40");--战团成员数量
	g_NewMembersCtl.info[3].txt:SetText(strMemberCount);
	
end

function Bhls_TeamInfo_Add_Clicked()
	
end

function Bhls_TeamInfo_Closed()
	this:Hide();
end

