-- ChiGua_RankingList.lua

local g_ChiGua_RankingList_Frame_UnifiedPosition;
local g_MaxNum = 10;
local g_RandListName ={}
local g_RandListScore ={}
local g_RankListBestName = ""
local g_RankListBestScore = 0
local g_IsCanGetBouns = 0
local g_IsCanGetTopBouns = 0

local g_NpcId =-1;
local objCared = -1


function ChiGua_RankingList_PreLoad()
	this : RegisterEvent( "UI_COMMAND",true )
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OPEN_EAT_WATERMELON_RANKLIST",true)
end

function ChiGua_RankingList_OnLoad()

	g_ChiGua_RankingList_Frame_UnifiedPosition=ChiGua_RankingList_FrameNULL:GetProperty("UnifiedPosition");

	g_RankListBestName = ChiGua_RankingList_ListInfo1_Name
	g_RankListBestScore = ChiGua_RankingList_ListInfo1_Score

	g_RandListName[1] = ChiGua_RankingList_ListInfo2_Name
	g_RandListName[2] = ChiGua_RankingList_ListInfo3_Name
	g_RandListName[3] = ChiGua_RankingList_ListInfo4_Name
	g_RandListName[4] = ChiGua_RankingList_ListInfo5_Name
	g_RandListName[5] = ChiGua_RankingList_ListInfo6_Name
	g_RandListName[6] = ChiGua_RankingList_ListInfo7_Name
	g_RandListName[7] = ChiGua_RankingList_ListInfo8_Name
	g_RandListName[8] = ChiGua_RankingList_ListInfo9_Name
	g_RandListName[9] = ChiGua_RankingList_ListInfo10_Name
	g_RandListName[10] = ChiGua_RankingList_ListInfo11_Name

	g_RandListScore[1] = ChiGua_RankingList_ListInfo2_Score
	g_RandListScore[2] = ChiGua_RankingList_ListInfo3_Score
	g_RandListScore[3] = ChiGua_RankingList_ListInfo4_Score
	g_RandListScore[4] = ChiGua_RankingList_ListInfo5_Score
	g_RandListScore[5] = ChiGua_RankingList_ListInfo6_Score
	g_RandListScore[6] = ChiGua_RankingList_ListInfo7_Score
	g_RandListScore[7] = ChiGua_RankingList_ListInfo8_Score
	g_RandListScore[8] = ChiGua_RankingList_ListInfo9_Score
	g_RandListScore[9] = ChiGua_RankingList_ListInfo10_Score
	g_RandListScore[10] = ChiGua_RankingList_ListInfo11_Score

	ChiGua_RankingList_Clear()

end

function ChiGua_RankingList_OnEvent(event)


	if event == "OPEN_EAT_WATERMELON_RANKLIST"  then	-- 打开界面
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

		ChiGua_RankingList_BeginCareObject(objCared)


		ChiGua_RankingList_Open()
		return
	end

	if (event == "ADJEST_UI_POS" ) then
		ChiGua_RankingList_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ChiGua_RankingList_Frame_On_ResetPos()
	end


end



function ChiGua_RankingList_Clear()
	for i = 1,g_MaxNum do
		g_RandListName[i]:SetText("")
		g_RandListScore[i]:SetText("")
	end

	g_RankListBestName:SetText("")
	g_RankListBestScore:SetText("")


end

function ChiGua_RankingList_Open()


	ChiGua_RankingList_Clear()

	local sTopName,nTopScore =DataPool:Lua_GetWatermelonScoreTop()

	if nTopScore > 0 then
		g_RankListBestName:SetText("#c6a3906"..sTopName)
		g_RankListBestScore:SetText("#c6a3906"..nTopScore)
	end


	for i = 1,g_MaxNum do
		local sName,nScore =DataPool:Lua_GetWatermelonScoreRank(i-1)
		if nScore > 0 then
			g_RandListName[i]:SetText("#c6a3906"..sName)
			g_RandListScore[i]:SetText("#c6a3906"..nScore)
		end
	end

	if g_IsCanGetBouns == 1 then
		ChiGua_RankingList_Prize1_Text:SetText("#{XGDS_180608_91}")
		ChiGua_RankingList_Prize2_Text:SetText("#{XGDS_180608_91}")
	else
		ChiGua_RankingList_Prize1_Text:SetText("#{XGDS_180608_90}")
		ChiGua_RankingList_Prize2_Text:SetText("#{XGDS_180608_90}")
	end

	if g_IsCanGetTopBouns == 1 then
		ChiGua_RankingList_Prize3_Text:SetText("#{XGDS_180608_93}")
	else
		ChiGua_RankingList_Prize3_Text:SetText("#{XGDS_180608_92}")
	end


	this:Show()
end

function ChiGua_RankingList_Prize1_Clicked()
	if g_IsCanGetBouns == 0 then
		PushDebugMessage("#{ETJHD_180503_250}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RandListGetBouns" )
		Set_XSCRIPT_ScriptID( 892852 )
		Set_XSCRIPT_Parameter( 0, 1 )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

function ChiGua_RankingList_Prize2_Clicked()
	if g_IsCanGetBouns == 0 then
		PushDebugMessage("#{ETJHD_180503_250}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RandListGetBouns" )
		Set_XSCRIPT_ScriptID( 892852 )
		Set_XSCRIPT_Parameter( 0, 2 )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

function ChiGua_RankingList_Prize3_Clicked()
	if g_IsCanGetTopBouns == 0 then
		PushDebugMessage("#{ETJHD_180503_250}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RandListGetBouns" )
		Set_XSCRIPT_ScriptID( 892852 )
		Set_XSCRIPT_Parameter( 0, 3 )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

function ChiGua_RankingList_Close()
	ChiGua_RankingList_FrameNULL:SetProperty("UnifiedPosition", g_ChiGua_RankingList_Frame_UnifiedPosition);
	ChiGua_RankingList_StopCareObject()
	this:Hide()
end

function ChiGua_RankingList_Frame_On_ResetPos()
  ChiGua_RankingList_FrameNULL:SetProperty("UnifiedPosition", g_ChiGua_RankingList_Frame_UnifiedPosition);
end

--=========================================================
--开始关心NPC
--=========================================================
function ChiGua_RankingList_BeginCareObject(objCaredId)
	if objCared ~= -1 then
		this:CareObject(objCaredId, 0, "ChiGua_RankingList");
	end
	objCared = objCaredId
	this:CareObject(objCared, 1, "ChiGua_RankingList")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function ChiGua_RankingList_StopCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "ChiGua_RankingList");
		objCared = -1;
	end
end


