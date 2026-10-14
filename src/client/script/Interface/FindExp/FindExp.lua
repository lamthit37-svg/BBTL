--FindExp.lua
local g_FindExp_Frame_UnifiedPosition

local g_FindExp_MD_PKEXP_NUMS=3230;
local g_FindExp_ExpMD={3316,3317,3318,3319,3320,3321,3322,3323,3324,3325,3326,3327,3328,3329,3330,3331,3332,3333,3334,3335};
local g_FindExp_MaxFindCount=20
local g_FindExp_CurFindCount=0

local g_FindExp_Config={
	[1]={currency=0, count=100000},
	[2]={currency=0, count=200000},
	[3]={currency=0, count=300000},
	[4]={currency=0, count=400000},
	[5]={currency=1, count=50},
	[6]={currency=1, count=60},
	[7]={currency=1, count=70},
	[8]={currency=1, count=80},
	[9]={currency=1, count=90},
	[10]={currency=1,count=100},
	[11]={currency=1, count=120},
	[12]={currency=1, count=140},
	[13]={currency=1, count=160},
	[14]={currency=1, count=180},
	[15]={currency=1, count=200},
	[16]={currency=1, count=240},
	[17]={currency=1, count=280},
	[18]={currency=1, count=320},
	[19]={currency=1, count=360},
	[20]={currency=1, count=400},
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function FindExp_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("PKEXP_REGAIN_OPEN");
	this:RegisterEvent("PKEXP_REGAIN_OPEN");
	this:RegisterEvent("UNIT_MONEY")
	this:RegisterEvent("MONEYJZ_CHANGE")	
	this:RegisterEvent("UPDATE_YUANBAO");

	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")	--进场景关闭界面
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function FindExp_OnLoad()
	g_FindExp_Frame_UnifiedPosition = FindExp_Frame:GetProperty("UnifiedPosition")

end

--响应事件的函数，当注册的事件发生时会调用的函数
function FindExp_OnEvent(event)
	if (event == "PKEXP_REGAIN_OPEN" ) then
		if( tonumber(arg0) == 1 ) then --打开
			FindExp_Update()				
			this:Show()
			FindExp_On_SetLastPos()
		end
				
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89027701 ) then --刷新
		FindExp_Update()				
				
	elseif (event == "UNIT_MONEY" or event =="MONEYJZ_CHANGE" or event == "UPDATE_YUANBAO") then
		FindExp_Update_Money()
		
	elseif (event == "ADJEST_UI_POS" ) then
		FindExp_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FindExp_Frame_On_ResetPos()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FindExp_OnClose()
	end
end

function FindExp_Update()
		
	FindExp_JiaoziFrame:Hide();
	FindExp_YuanbaoFrame:Hide();
	FindExp_Info:SetText( ScriptGlobal_Format("#{PKPK_20251021_5}", g_FindExp_MaxFindCount) );
	
	local nMDCount = DataPool:GetPlayerMission_DataRound(g_FindExp_MD_PKEXP_NUMS)
	nMDCount = math.mod(nMDCount, 1000000);
	--当日扣经验次数||找回次数
	local nPenaltyCount = math.floor(nMDCount / 10000);
	local nFindExpCount = math.mod( nMDCount, 100 );
	FindExp_TimeNum:SetText( ScriptGlobal_Format("#{PKPK_20251021_34}", tostring(g_FindExp_MaxFindCount - nFindExpCount), g_FindExp_MaxFindCount ) );
	
	local nNextFindExp = 0;
	if nFindExpCount >= 0 and nFindExpCount < g_FindExp_MaxFindCount then
		nNextFindExp = DataPool:GetPlayerMission_DataRound( g_FindExp_ExpMD[nFindExpCount+1] )
	end
	FindExp_NowFindNum:SetText( tostring(nNextFindExp) );
		
	if ( g_FindExp_Config[nFindExpCount+1] ~= nil ) then
		if g_FindExp_Config[nFindExpCount+1].currency == 0 then
			FindExp_JiaoziFrame:Show();
			FindExp_DemandMoney:SetProperty("MoneyNumber", g_FindExp_Config[nFindExpCount+1].count)
		else
			FindExp_YuanbaoFrame:Show();
			FindExp_NeedYuanbao:SetText(g_FindExp_Config[nFindExpCount+1].count)
		end
	else
		FindExp_YuanbaoFrame:Show();
		FindExp_NeedYuanbao:SetText(tostring(0))
	end
	g_FindExp_CurFindCount = nFindExpCount+1;
	
	FindExp_Update_Money();
end

function FindExp_Update_Money()
	FindExp_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	FindExp_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	FindExp_SelfYuanbao:SetText( tostring(Player:GetData("YUANBAO")))
end

function FindExp_OK_Clicked()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnFindExp");
		Set_XSCRIPT_ScriptID(890277);
		Set_XSCRIPT_Parameter(0,g_FindExp_CurFindCount);
		Set_XSCRIPT_Parameter(1,0);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end

function FindExp_OnClose()
	this:Hide()
end

function FindExp_OnHidden()
end

function FindExp_Frame_On_ResetPos()
  FindExp_Frame:SetProperty("UnifiedPosition", g_FindExp_Frame_UnifiedPosition);
end

function FindExp_On_SetLastPos()
	FindExp_Frame:SetProperty("UnifiedPosition", g_FindExp_Frame_UnifiedPosition);
end
