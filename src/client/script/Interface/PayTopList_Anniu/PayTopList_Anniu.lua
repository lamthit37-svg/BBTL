

local g_globals = {}
local g_banlist = {}
function PayTopList_Anniu_PreLoad()
	this:RegisterEvent("UI_COMMAND")
end

function PayTopList_Anniu_OnLoad()
	g_globals.MingDongInCooldown = 0
	g_globals.MingDongCooldown = 4 * 1000
	this:Hide()

	g_banlist[0] = 5143
end

function PayTopList_Anniu_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		return
	end
	if (event == "UI_COMMAND") and (arg0 == "20131114") then
		if Get_XParam_INT(0) == 1 then
			this:Show()
		else
			this:Hide()
		end
	end
	if (event == "UI_COMMAND") and (arg0 == "20130823") then
		this:Hide()
	end
	if (event == "UI_COMMAND") and (arg0 == "20130509") then
		SetTimer("PayTopList_Anniu", "PayTopList_Anniu_Delay_Show_Tips()",1000)
	end
end

function PayTopList_Anniu_Delay_Show_Tips()
	local fX = 0
	local fY = 0
	fX, fY = this:GetChildOffset("PayTopList_Anniu_Icon2")
	fX = fX + 10
	fY = fY - 10
	OpenFreshManGuide(1, 49, fX, fY, "PayTopList_Anniu", "southwest")
	KillTimer("PayTopList_Anniu_Delay_Show_Tips()")
end

function PayTopList_Anniu_MingDongCooldown()
	g_globals.MingDongInCooldown = 0
	KillTimer("PayTopList_Anniu_MingDongCooldown()");
end


function PayTopList_Anniu_OnClick_MyServer()
	CloseFreshManGuide()
	local nNumber = Player:GetData( "LEVEL" );
	if( nNumber < 15 ) then
		PushDebugMessage("#{MDJH_130507_34}")
		return
	end
	if g_globals.MingDongInCooldown == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientAskTopList" )
			Set_XSCRIPT_ScriptID( 890084 )
			Set_XSCRIPT_Parameter(0,0)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		g_globals.MingDongInCooldown =1
		SetTimer("PayTopList_Anniu", "PayTopList_Anniu_MingDongCooldown()",g_globals.MingDongCooldown)
		PushEvent( "OPEN_XIAOFEI_TOPLIST", 1 )
	else
		PushDebugMessage("#{MDJH_130507_33}")
	end
end

function PayTopList_Anniu_OnClick2_TServer()
	local id = DataPool:GetSelfZoneWorldID();
	for i,worldid in g_banlist do
		if worldid == id then
			PushDebugMessage("#{MDJH_141014_32}")
			return
		end
	
	end

	CloseFreshManGuide()
	local nNumber = Player:GetData( "LEVEL" );
	if( nNumber < 15 ) then
		PushDebugMessage("#{MDJH_130507_34}")
		return
	end
	if g_globals.MingDongInCooldown == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientAskTopList" )
			Set_XSCRIPT_ScriptID( 890084 )
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		g_globals.MingDongInCooldown =1
		SetTimer("PayTopList_Anniu", "PayTopList_Anniu_MingDongCooldown()",g_globals.MingDongCooldown)
		PushEvent( "OPEN_XIAOFEI_TOPLIST", 2 )
	else
		PushDebugMessage("#{MDJH_130507_33}")
	end
end
