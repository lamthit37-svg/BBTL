-- HappyETJ_RankingList.lua

local g_HappyETJ_RankingList_Frame_UnifiedPosition;
local g_MaxNum = 10;
local g_RandListName ={}
local g_RandListScore ={}
local g_RankListBestName = ""
local g_RankListBestScore = 0
local g_IsCanGetBouns = 0
local g_IsCanGetTopBouns = 0

local g_NpcId =-1;
local objCared = -1


function HappyETJ_RankingList_PreLoad()
	this : RegisterEvent( "UI_COMMAND",true )
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OPEN_CHILDREN_DAY_RANKLIST",true)
end

function HappyETJ_RankingList_OnLoad()

	g_HappyETJ_RankingList_Frame_UnifiedPosition=HappyETJ_RankingList_FrameNULL:GetProperty("UnifiedPosition");

	g_RankListBestName = HappyETJ_RankingList_ListInfo1_Name
	g_RankListBestScore = HappyETJ_RankingList_ListInfo1_Score

	g_RandListName[1] = HappyETJ_RankingList_ListInfo2_Name
	g_RandListName[2] = HappyETJ_RankingList_ListInfo3_Name
	g_RandListName[3] = HappyETJ_RankingList_ListInfo4_Name
	g_RandListName[4] = HappyETJ_RankingList_ListInfo5_Name
	g_RandListName[5] = HappyETJ_RankingList_ListInfo6_Name
	g_RandListName[6] = HappyETJ_RankingList_ListInfo7_Name
	g_RandListName[7] = HappyETJ_RankingList_ListInfo8_Name
	g_RandListName[8] = HappyETJ_RankingList_ListInfo9_Name
	g_RandListName[9] = HappyETJ_RankingList_ListInfo10_Name
	g_RandListName[10] = HappyETJ_RankingList_ListInfo11_Name

	g_RandListScore[1] = HappyETJ_RankingList_ListInfo2_Score
	g_RandListScore[2] = HappyETJ_RankingList_ListInfo3_Score
	g_RandListScore[3] = HappyETJ_RankingList_ListInfo4_Score
	g_RandListScore[4] = HappyETJ_RankingList_ListInfo5_Score
	g_RandListScore[5] = HappyETJ_RankingList_ListInfo6_Score
	g_RandListScore[6] = HappyETJ_RankingList_ListInfo7_Score
	g_RandListScore[7] = HappyETJ_RankingList_ListInfo8_Score
	g_RandListScore[8] = HappyETJ_RankingList_ListInfo9_Score
	g_RandListScore[9] = HappyETJ_RankingList_ListInfo10_Score
	g_RandListScore[10] = HappyETJ_RankingList_ListInfo11_Score

	HappyETJ_RankingList_Clear()

end

function HappyETJ_RankingList_OnEvent(event)


	if event == "OPEN_CHILDREN_DAY_RANKLIST"  then	-- 打开界面
		if this : IsVisible() then									-- 如果界面开着，则不处理
			return
		end
		g_IsCanGetBouns = tonumber(arg0);
		g_IsCanGetTopBouns = tonumber(arg1);
		g_NpcId = tonumber(arg2);

		objCared = DataPool : GetNPCIDByServerID(g_NpcId);

		if objCared == -1 then
			return
		end

		HappyETJ_RankingList_BeginCareObject(objCared)


		HappyETJ_RankingList_Open()
		return
	end

	if (event == "ADJEST_UI_POS" ) then
		HappyETJ_RankingList_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HappyETJ_RankingList_Frame_On_ResetPos()
	end


end



function HappyETJ_RankingList_Clear()
	for i = 1,g_MaxNum do
		g_RandListName[i]:SetText("")
		g_RandListScore[i]:SetText("")
	end

	g_RankListBestName:SetText("")
	g_RankListBestScore:SetText("")


end

function HappyETJ_RankingList_Open()

	HappyETJ_RankingList_Clear()

	local sTopName,nTopScore =DataPool:Lua_GetChildrenDayScoreTop()

	if nTopScore > 0 then
		g_RankListBestName:SetText("#c6a3906"..sTopName)
		g_RankListBestScore:SetText("#c6a3906"..nTopScore)
	end


	for i = 1,g_MaxNum do
		local sName,nScore =DataPool:Lua_GetChildrenDayScoreRank(i-1)
		if nScore > 0 then
			g_RandListName[i]:SetText("#c6a3906"..sName)
			g_RandListScore[i]:SetText("#c6a3906"..nScore)
		end
	end

	if g_IsCanGetBouns == 1 then
		HappyETJ_RankingList_Prize1_Text:SetText("#{ETJHD_180503_47}")
		HappyETJ_RankingList_Prize2_Text:SetText("#{ETJHD_180503_47}")
	else
		HappyETJ_RankingList_Prize1_Text:SetText("#{ETJHD_180503_46}")
		HappyETJ_RankingList_Prize2_Text:SetText("#{ETJHD_180503_46}")
	end

	if g_IsCanGetTopBouns == 1 then
		HappyETJ_RankingList_Prize3_Text:SetText("#{ETJHD_180503_249}")
	else
		HappyETJ_RankingList_Prize3_Text:SetText("#{ETJHD_180503_248}")
	end


	this:Show()
end

function HappyETJ_RankingList_Prize1_Clicked()
	if g_IsCanGetBouns == 0 then
		PushDebugMessage("#{ETJHD_180503_250}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RandListGetBouns" )
		Set_XSCRIPT_ScriptID( 892797 )
		Set_XSCRIPT_Parameter( 0, 1 )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

function HappyETJ_RankingList_Prize2_Clicked()
	if g_IsCanGetBouns == 0 then
		PushDebugMessage("#{ETJHD_180503_250}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RandListGetBouns" )
		Set_XSCRIPT_ScriptID( 892797 )
		Set_XSCRIPT_Parameter( 0, 2 )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

function HappyETJ_RankingList_Prize3_Clicked()
	if g_IsCanGetTopBouns == 0 then
		PushDebugMessage("#{ETJHD_180503_250}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RandListGetBouns" )
		Set_XSCRIPT_ScriptID( 892797 )
		Set_XSCRIPT_Parameter( 0, 3 )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

function HappyETJ_RankingList_Close()
	HappyETJ_RankingList_StopCareObject()
	this:Hide()
end

function HappyETJ_RankingList_Frame_On_ResetPos()
  HappyETJ_RankingList_FrameNULL:SetProperty("UnifiedPosition", g_HappyETJ_RankingList_Frame_UnifiedPosition);
end

--=========================================================
--开始关心NPC
--=========================================================
function HappyETJ_RankingList_BeginCareObject(objCaredId)
	if objCared ~= -1 then
		this:CareObject(objCaredId, 0, "HappyETJ_RankingList");
	end
	objCared = objCaredId
	this:CareObject(objCared, 1, "HappyETJ_RankingList")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function HappyETJ_RankingList_StopCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "HappyETJ_RankingList");
		objCared = -1;
	end
end


