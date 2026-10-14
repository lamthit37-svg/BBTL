--争霸赛战队投票结果
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_IndexCorpsID = {}
local 	g_nContentButton = {}
--npcid
local g_TargetId = -1
local g_RefreashTime = 0


function NoDiffMatch_VoteResult_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("CORPS_UPDATE_RANKLISTVOTE2_2018")
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NoDiffMatch_VoteResult_OnLoad()
    --NoDiffMatch_VoteResult_ResetControl()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_VoteResult_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_VoteResult_Frame:GetProperty("UnifiedYPosition");
end

function NoDiffMatch_VoteResult_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "UI_COMMAND" then
	    if tonumber(arg0) ~= 8927062 then
	        return
	    end

		NoDiffMatch_VoteResult_ResetControl()

		g_TargetId = Get_XParam_INT(0)
        local npcid = Target:GetServerId2ClientId(g_TargetId)
        if not npcid or npcid < 0 then
            return
        end
		this:CareObject(npcid, 1)
		this:Show()

	elseif event == "CORPS_UPDATE_RANKLISTVOTE2_2018" then
	    if not this:IsVisible() then
	        return
	    end
	    NoDiffMatch_VoteResult_Update()
		
	elseif( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_VoteResult_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		NoDiffMatch_VoteResult_ResetPos()
		
	end
end


function NoDiffMatch_VoteResult_Update()

    NoDiffMatch_VoteResult_ResetControl()
	
    g_IndexCorpsID = {}
	g_nContentButton = {}
	
	local count = CorpsUI_2018:GetRankNodeCount()
	local toptext = ScriptGlobal_Format("#{WCTP_180211_68}" , count );
	NoDiffMatch_VoteResult_ExplainText:SetText(toptext)
	
	local szGuid = GetSelfGUID();
	local myPos = -1
    local j = 1 
	for i = 0, count-1 do
	    local nCorpsID, szCorpsName, szLeaderName, lGuid, aGuid, nGoldBoxTotalNum, nGoldBoxTodayNum, nSliverBoxTotalNum, nSliverBoxTodayNum, nVoteNum = CorpsUI_2018:GetRankNodeVoteInfo(i)
	    if nCorpsID and nCorpsID ~= -1 then

	        --战队Id 战队名字 战队队长 战队人数
			local ItemBar = NoDiffMatch_VoteResult_List1:AddItemElement( "NoDiffMatchResultButton", "LEFT", "NoDiffMatch_VoteResult","" ,"")
			ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
	
			if j <= 20 then
				ItemBar:SetImage1Show()
				ItemBar:SetImage1("Ach1",string.format("WDTXPMBtn_%d_Normal",j))
			elseif j>=21 and j <= 40 then
				ItemBar:SetImage1Show()
				ItemBar:SetImage1("Ach2",string.format("WDTXPMBtn_%d_Normal",j))
			end
			
			local childImgLeader = ItemBar:GetChildItem("NoDiffMatch_VoteResult","__auto_SuperBarImage5__")
			if childImgLeader then
				childImgLeader:SetImage("Union1", "Union_LeaderIcon_L")
				childImgLeader:Show()
			end
			
			--ItemBar:SetImage2Show()
			
			--ItemBar:SetText2( tostring(nCorpsID) )
			ItemBar:SetText2( string.format("%03d", nCorpsID) )
			ItemBar:SetText3( tostring(szCorpsName) )
			ItemBar:SetText4( tostring(szLeaderName) )
			
			local votetips = ScriptGlobal_Format("#{WCTP_180211_30}" , nVoteNum );
			ItemBar:SetText5( tostring(votetips) )
			
			ItemBar:SetButton1Text("#{WCTP_180211_31}"); 
		  	ItemBar:SetButton1Show(); 
  
			table.insert( g_nContentButton, ItemBar )
			
            g_IndexCorpsID[j] = nCorpsID
            j = j + 1
        end
	end

	if table.getn( g_nContentButton) == 0 then
		NoDiffMatch_VoteResult_List1:Hide()
	else
		NoDiffMatch_VoteResult_List1:Show()
		NoDiffMatch_VoteResult_List1:Flash()
	end
	
end


function NoDiffMatch_VoteResult_ResetControl()
	NoDiffMatch_VoteResult_List1:CleanAllElement("NoDiffMatch_VoteResult")
	local toptext = ScriptGlobal_Format("#{WCTP_180211_68}" , 0 );
	NoDiffMatch_VoteResult_ExplainText:SetText(toptext)
	NoDiffMatch_VoteResult_Num:SetText("")
end


function NoDiffMatch_VoteResult_CloseClicked()
    this:Hide()
    g_TargetId = -1
end

function NoDiffMatch_VoteResult_OnItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if not nIndex then
		return
	end
	for i,v in ipairs(g_nContentButton) do
		v:SetBarButtonSelected(false)
	end
end

--查看战队信息
function NoDiffMatch_VoteResult_OnButton1Click()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if not nIndex then
		return
	end
	
	if CorpsUI_2018:CanQueryRankingAgain() ~= 1 then
	    PushDebugMessage("#{ZBS_YXS_120301_86}")
	    return
	end
	
    local CorpsID = g_IndexCorpsID[nIndex + 1]
	if CorpsID and tonumber(CorpsID) > 0 then
		PushEvent("UI_COMMAND", 8927012, g_TargetId)
		CorpsUI_2018:RequsetCorpsInfo(tonumber(CorpsID))
	end
end


function NoDiffMatch_VoteResult_OnCheckMe()
	local nCorpsId = CorpsUI_2018:GetDetailCorpsInfo("CorpsID")
	if nCorpsId <= 0 then
		PushDebugMessage("#{WCTP_180211_72}")
		return
	end
	local viewPos = 0
	for i,v in ipairs(g_nContentButton) do
		if nCorpsId == g_IndexCorpsID[i] then
			v:SetBarButtonSelected(true)
			viewPos = i - 1
		else
			v:SetBarButtonSelected(false)
		end
	end
	NoDiffMatch_VoteResult_List1:SetVertScrollbarPosition(60.0*viewPos)
end


function NoDiffMatch_VoteResult_OnSearch()
	local nCorpsId = tonumber(NoDiffMatch_VoteResult_Num:GetText());
	if nCorpsId == nil then
		return
	end
	
	if nCorpsId > 400 then
		nCorpsId = 400
		NoDiffMatch_VoteResult_Num:SetText("400")
	end
	
	local isFind = 0
	local viewPos = 0
	for i,v in ipairs(g_nContentButton) do
		if nCorpsId == g_IndexCorpsID[i] then
			v:SetBarButtonSelected(true)
			viewPos = i - 1
			isFind = 1
		else
			v:SetBarButtonSelected(false)
		end
	end
	NoDiffMatch_VoteResult_List1:SetVertScrollbarPosition(60.0*viewPos)
	
	if isFind == 0 then
		PushDebugMessage("#{WCTP_180211_73}")
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_VoteResult_ResetPos()
	NoDiffMatch_VoteResult_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_VoteResult_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

