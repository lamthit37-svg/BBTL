--FindExpInfo.lua
local g_FindExpInfo_Frame_UnifiedPosition

local g_FindExpInfo_MD_PKEXP_NUMS=3230;
local g_FindExpInfo_ExpMD={3316,3317,3318,3319,3320,3321,3322,3323,3324,3325,3326,3327,3328,3329,3330,3331,3332,3333,3334,3335};
local g_FindExpInfo_MaxFindCount=20

--预加载函数，可以而且只能在这里注册脚本关心的事件
function FindExpInfo_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("PKEXP_REGAIN_OPEN");
	this:RegisterEvent("UNIT_LEVEL");

	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")	--进场景关闭界面
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function FindExpInfo_OnLoad()
	g_FindExpInfo_Frame_UnifiedPosition = FindExpInfo_Frame:GetProperty("UnifiedPosition")

end

--响应事件的函数，当注册的事件发生时会调用的函数
function FindExpInfo_OnEvent(event)
	if (event == "PKEXP_REGAIN_OPEN" ) then
		if( tonumber(arg0) == 0 ) then
			FindExpInfo_Update()	
			this:Show()
			FindExpInfo_On_SetLastPos()
		end
		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89027701 ) then  --刷新
		FindExpInfo_Update()	
		
	elseif event == "UNIT_LEVEL" and arg0 == "player" then
		FindExpInfo_Update_Level()
					
	elseif (event == "ADJEST_UI_POS" ) then
		FindExpInfo_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FindExpInfo_Frame_On_ResetPos()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FindExpInfo_OnClose()
	end
end

function FindExpInfo_Update()

	FindExpInfo_Update_Level();

	local nMDCount = DataPool:GetPlayerMission_DataRound(g_FindExpInfo_MD_PKEXP_NUMS)
	nMDCount = math.mod(nMDCount, 1000000);
	--当日扣经验次数||找回次数
	local nPenaltyCount = math.floor(nMDCount / 10000);
	local nFindExpCount = math.mod( nMDCount, 100 );
	FindExpInfo_TodayTimeNum:SetText( tostring(nPenaltyCount) );
	FindExpInfo_RemainTimeNum:SetText( ScriptGlobal_Format("#{PKPK_20251021_34}", tostring(g_FindExpInfo_MaxFindCount - nFindExpCount), g_FindExpInfo_MaxFindCount ) );
	local nNextFindExp = 0;
	if nFindExpCount >= 0 and nFindExpCount < g_FindExpInfo_MaxFindCount then
		nNextFindExp = DataPool:GetPlayerMission_DataRound( g_FindExpInfo_ExpMD[nFindExpCount+1] )
	end
	FindExpInfo_NextTimeExpNum:SetText( tostring(nNextFindExp) );

end

function FindExpInfo_Update_Level()

	local nLevel = Player:GetData( "LEVEL" );
	FindExpInfo_LevelMaxNum:SetText(tostring(nLevel));
	
end

function FindExpInfo_OK_Clicked()
	PushEvent("PKEXP_REGAIN_OPEN", 1);
end

function FindExpInfo_HelpClicked()
	PushEvent("QUEST_HELPINFO", "#{PKPK_20251119_2}")
end

function FindExpInfo_OnClose()
	this:Hide()
end

function FindExpInfo_OnHidden()
end

function FindExpInfo_Frame_On_ResetPos()
  FindExpInfo_Frame:SetProperty("UnifiedPosition", g_FindExpInfo_Frame_UnifiedPosition);
end

function FindExpInfo_On_SetLastPos()
	FindExpInfo_Frame:SetProperty("UnifiedPosition", g_FindExpInfo_Frame_UnifiedPosition);
end
