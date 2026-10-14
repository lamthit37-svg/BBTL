--争霸赛战队投票
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_IndexCorpsID = {}
local 	g_nContentButton = {}
--npcid
local g_TargetId = -1
local g_RefreashTime = 0
local g_GoldenBoxTotalNum = 0
local g_SilverBoxTotalNum = 0
local g_GoldenBoxNum = 0
local g_SilverBoxNum = 0
local g_CanSetPrize = 0

function NoDiffMatch_Vote_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("CORPS_UPDATE_RANKLISTVOTE_2018")
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NoDiffMatch_Vote_OnLoad()
    --NoDiffMatch_Vote_ResetControl()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_Vote_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_Vote_Frame:GetProperty("UnifiedYPosition");
end

function NoDiffMatch_Vote_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "UI_COMMAND" then
	    if tonumber(arg0) ~= 8927061 then
	        return
	    end

		NoDiffMatch_Vote_ResetControl()

		g_TargetId = Get_XParam_INT(0)
        local npcid = Target:GetServerId2ClientId(g_TargetId)
        if not npcid or npcid < 0 then
            return
        end
		this:CareObject(npcid, 1)
		this:Show()

	elseif event == "CORPS_UPDATE_RANKLISTVOTE_2018" then
	    if not this:IsVisible() then
	        return
	    end
	    NoDiffMatch_Vote_Update()
		
	elseif( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_Vote_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		NoDiffMatch_Vote_ResetPos()
	end
end


function NoDiffMatch_Vote_Update()

    NoDiffMatch_Vote_ResetControl()
	
    g_IndexCorpsID = {}
	g_nContentButton = {}
	
	local count = CorpsUI_2018:GetRankNodeCount()
	local toptext = ScriptGlobal_Format("#{WCTP_180211_12}" , count );
	NoDiffMatch_Vote_ExplainText:SetText(toptext)
	
	local szGuid = GetSelfGUID();
	local myPos = -1
    local j = 1 
	for i = 0, count-1 do
	    local nCorpsID, szCorpsName, szLeaderName, lGuid, aGuid, nGoldBoxTotalNum, nGoldBoxTodayNum, nSliverBoxTotalNum, nSliverBoxTodayNum, nVoteNum = CorpsUI_2018:GetRankNodeVoteInfo(i)
	    if nCorpsID and nCorpsID ~= -1 then

	        --战队Id 战队名字 战队队长 战队人数
			local ItemBar = NoDiffMatch_Vote_List1:AddItemElement( "NoDiffMatchButton", "LEFT", "NoDiffMatch_Vote","" ,"")
			ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
	
			if j <= 20 then
				ItemBar:SetImage1Show()
				ItemBar:SetImage1("Ach1",string.format("WDTXPMBtn_%d_Normal",j))
				--ItemBar:SetText1Hide()
			elseif j>=21 and j <= 40 then
				ItemBar:SetImage1Show()
				ItemBar:SetImage1("Ach2",string.format("WDTXPMBtn_%d_Normal",j))
				--ItemBar:SetText1Hide()
			else
				ItemBar:SetImage1Hide()
				ItemBar:SetText1( tostring(j) )
				--ItemBar:SetText1Show()
			end
			local childImgLeader = ItemBar:GetChildItem("NoDiffMatch_Vote","__auto_SuperBarImage5__")
			if childImgLeader then
				childImgLeader:SetImage("Union1", "Union_LeaderIcon_L")
				childImgLeader:Show()
			end
			
			ItemBar:SetImage2Hide()
			
			local childbutton3 = ItemBar:GetChildItem("NoDiffMatch_Vote","__auto_SuperBarButton3__")
			if childbutton3 then
				childbutton3:Hide()
			end
			
			local childbutton4 = ItemBar:GetChildItem("NoDiffMatch_Vote","__auto_SuperBarButton4__")
			if childbutton4 then
				childbutton4:Hide()
			end
			
			local childbutton5 = ItemBar:GetChildItem("NoDiffMatch_Vote","__auto_SuperBarButton5__")
			if childbutton5 then
				childbutton5:Hide()
			end
			
			local childbutton6 = ItemBar:GetChildItem("NoDiffMatch_Vote","__auto_SuperBarButton6__")
			if childbutton6 then
				childbutton6:Hide()
			end
			
			if nGoldBoxTotalNum > 0 and nSliverBoxTotalNum > 0 and childbutton3 ~= nil and childbutton5 ~= nil then
				childbutton5:Show()
				childbutton5:SetToolTip("#{WCTP_180211_80}")
				childbutton3:Show()
				childbutton3:SetToolTip("#{WCTP_180211_81}")
			elseif nGoldBoxTotalNum > 0 and childbutton4 ~= nil then
				childbutton4:Show()
				childbutton4:SetToolTip("#{WCTP_180211_80}")
			elseif nSliverBoxTotalNum > 0 and childbutton6 ~= nil then
				childbutton6:Show()
				childbutton6:SetToolTip("#{WCTP_180211_81}")
			end
			
			--ItemBar:SetText2( tostring(nCorpsID) )
			ItemBar:SetText2( string.format("%03d", nCorpsID) )
			ItemBar:SetText3( tostring(szCorpsName) )
			ItemBar:SetText4( tostring(szLeaderName) )
			
			local votetips = ScriptGlobal_Format("#{WCTP_180211_30}" , nVoteNum );
			ItemBar:SetText5( tostring(votetips) )
			
			ItemBar:SetButton1Text("#{WCTP_180211_31}"); 
		  	ItemBar:SetButton1Show(); 
			
			ItemBar:SetButton2Text("#{WCTP_180211_32}"); 
		  	ItemBar:SetButton2Show(); 
			--ItemBar:SetButton2Tips("#{WCTP_180211_32}")
  
			table.insert( g_nContentButton, ItemBar )

			if szGuid == lGuid then
				g_CanSetPrize = 1
				g_GoldenBoxNum = nGoldBoxTodayNum
				g_SilverBoxNum = nSliverBoxTodayNum
				
				g_GoldenBoxTotalNum = nGoldBoxTotalNum
				g_SilverBoxTotalNum = nSliverBoxTotalNum
			end
			
            g_IndexCorpsID[j] = nCorpsID
            j = j + 1
        end
	end

	if table.getn( g_nContentButton) == 0 then
		NoDiffMatch_Vote_List1:Hide()
	else
		NoDiffMatch_Vote_List1:Show()
		NoDiffMatch_Vote_List1:Flash()
	end
	
	if g_CanSetPrize > 0 then
		NoDiffMatch_Vote_Fangzhi:Show()
	end
	
	
end


function NoDiffMatch_Vote_ResetControl()
	NoDiffMatch_Vote_List1:CleanAllElement("NoDiffMatch_Vote")
    NoDiffMatch_Vote_Fangzhi:Hide()
	local toptext = ScriptGlobal_Format("#{WCTP_180211_12}" , 0 );
	NoDiffMatch_Vote_ExplainText:SetText(toptext)
	NoDiffMatch_Vote_Num:SetText("")
	
	g_RefreashTime = 0
	g_GoldenBoxTotalNum = 0
	g_SilverBoxTotalNum = 0
	g_GoldenBoxNum = 0
	g_SilverBoxNum = 0
	g_CanSetPrize = 0

end


function NoDiffMatch_Vote_CloseClicked()
    this:Hide()
end

function NoDiffMatch_Vote_OnItemClick()
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
function NoDiffMatch_Vote_OnButton1Click()
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

--投票
function NoDiffMatch_Vote_OnButton2Click()
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
		return
	end
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{KPWFS_131112_20}")
		return
	end
	
	
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if not nIndex then
		PushDebugMessage("#{WCTP_180211_36}")
		return
	end
	
	local CorpsID = g_IndexCorpsID[nIndex + 1]
	if CorpsID <= 0 then
		PushDebugMessage("#{WCTP_180211_36}")
		return
	end
	
	CorpsUI_2018:VoteToCorps( CorpsID )
end

function NoDiffMatch_Vote_OnCheckMe()
	local nCorpsId = CorpsUI_2018:GetDetailCorpsInfo("CorpsID")
	if nCorpsId <= 0 then
		PushDebugMessage("#{WCTP_180211_22}")
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
	NoDiffMatch_Vote_List1:SetVertScrollbarPosition(60.0*viewPos)
end

function NoDiffMatch_Vote_OnFangzhi()
	local nCorpsId = CorpsUI_2018:GetDetailCorpsInfo("CorpsID")
	if nCorpsId <= 0 then
		PushDebugMessage("#{WCTP_180211_45}")
		return
	end
	
	if g_CanSetPrize ~= 1 then
		--您不是战队的队长或副队长，不可进行该操作
		PushDebugMessage("#{WCTP_180211_45}")
		return
	end
	
	--if g_GoldenBoxNum >= 100 and g_SilverBoxNum >= 100 then
	--	PushDebugMessage("#{WCTP_180211_46}")
	--	return
	--end
	
	if IsWindowShow( "NoDiffMatch_Setprize" ) == true then
		CloseWindow( "NoDiffMatch_Setprize", true )
	end
	
	PushEvent("CORPS_SHOW_VOTEPRIZE_2018", g_TargetId, g_GoldenBoxNum, g_GoldenBoxTotalNum, g_SilverBoxNum, g_SilverBoxTotalNum)
end


function NoDiffMatch_Vote_OnRefresh()
	local curTime = tonumber(DataPool:GetServerMinuteTime());
	if curTime - g_RefreashTime < 5 then
		PushDebugMessage("#{WCTP_180211_26}")
		return
	end
	
	g_RefreashTime = curTime
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("QueryRankingCharts")
		Set_XSCRIPT_ScriptID(892706)
		Set_XSCRIPT_Parameter(0, g_TargetId )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

function NoDiffMatch_Vote_OnSearch()
	local nCorpsId = tonumber(NoDiffMatch_Vote_Num:GetText());
	if nCorpsId == nil then
		return
	end
	
	if nCorpsId > 400 then
		nCorpsId = 400
		NoDiffMatch_Vote_Num:SetText("400")
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
	NoDiffMatch_Vote_List1:SetVertScrollbarPosition(60.0*viewPos)
	
	if isFind == 0 then
		PushDebugMessage("#{WCTP_180211_27}")
	end
end

function NoDiffMatch_Vote_Rule_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientAskNpcTalk")
		Set_XSCRIPT_ScriptID(892694)
		Set_XSCRIPT_Parameter(0, g_TargetId )
		Set_XSCRIPT_Parameter(1, 4 )
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_Vote_ResetPos()
	NoDiffMatch_Vote_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_Vote_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end