

local g_Word_Group1 = {
	[1] = {
		skillname="#{FQRC_150605_301}", s = 1,
		iconbase = "set:CoupleQuest1 image:CoupleQuest_1",
	},
	[2] = {
		skillname="#{FQRC_150605_304}", s = 0,
		iconbase = "set:CoupleQuest1 image:CoupleQuest_2",
	},
	[3] = {
		skillname="#{FQRC_150605_305}", s = 0,
		iconbase = "set:CoupleQuest1 image:CoupleQuest_3",
	},
	[4] = {
		skillname="#{FQRC_150605_302}", s = 1,
		iconbase = "set:CoupleQuest2 image:CoupleQuest_4",
	},
	[5] = {
		skillname="#{FQRC_150605_303}", s = 1,
		iconbase = "set:CoupleQuest2 image:CoupleQuest_5",
	},
	[6] = {
		skillname="#{FQRC_150605_306}", s = 0,
		iconbase = "set:CoupleQuest2 image:CoupleQuest_6",
	},
}


local g_mission_id = 1356
local g_buf_set = { 39951,39950 }

local g_Word_Buttons = {}
local g_Word_Flashes = {}


local g_last_team_state = 0


function CoupleQuest_PreLoad()
	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("UPDATE_MISSION_TRACK")
	this:RegisterEvent("NEW_MISSION")
end

function CoupleQuest_OnLoad()
	for i=1,6 do
		g_Word_Buttons[i] = _G[ string.format("CoupleQuest_Word%d_Image",i) ]
		g_Word_Flashes[i] = _G[ string.format("CoupleQuest_Word%d_AnimateImage",i) ]
	end
end

function CoupleQuest_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 8913591 then
		CoupleQuest_UpdateState()
	end
	if event == "UPDATE_MISSION_TRACK" or event == "NEW_MISSION" then
		CoupleQuest_TimerUpdate()
	end
end

function CoupleQuest_TimerHandler()
	--时间紧，沿用这种奇怪的方式

	local bNotify = 0
	if Player:IsInTeam() == 0 then
		if g_last_team_state ~= 0 then
			bNotify = 1
		end
		g_last_team_state = 0
	else
		local n = DataPool:GetTeamMemberCount()
		if n < g_last_team_state then
			bNotify = 1
		end
		g_last_team_state = n
	end

	if bNotify == 1 and this:IsVisible() then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("UpdateQteStatus")
			Set_XSCRIPT_ScriptID(891359)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end

function CoupleQuest_TimerUpdate()
	KillTimer("CoupleQuest_TimerHandler()")
	if DataPool:Lua_IsHaveMission(g_mission_id) == 1 then
		SetTimer( "CoupleQuest", "CoupleQuest_TimerHandler()", 300 )
	end
end

function CoupleQuest_OnOkClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnUserClickFinish")
		Set_XSCRIPT_ScriptID(891359)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function CoupleQuest_GetBit( n , b , l )
	return math.floor( math.mod( n , math.pow(2, b+l ) ) / math.pow( 2, b ) )
end

function CoupleQuest_MakeWordStates( n )
	local set = {}
	for i = 1, 6 do
		set[i] = CoupleQuest_GetBit( n , i-1, 1 )
	end
	return set
end


function CoupleQuest_TimerHandler1()
	this:Hide()
	KillTimer("CoupleQuest_TimerHandler1()")
end


function CoupleQuest_UpdateState()

	CoupleQuest_TimerUpdate()

	local nGroup = Get_XParam_INT(0)
	local nNext = Get_XParam_INT(1)
	local States = CoupleQuest_MakeWordStates( Get_XParam_INT( 2 ) )
	local usrName = Get_XParam_STR(0)

	if nGroup == 0 then
		if nNext == 0 then --nGroup==0的情况下，nNext表示是否需要延迟关闭
			this:Hide()
			return
		else
			KillTimer("CoupleQuest_TimerHandler1()")
			if DataPool:Lua_IsHaveMission(g_mission_id) == 1 then
				SetTimer( "CoupleQuest", "CoupleQuest_TimerHandler1()", 2000 )
			end
			return
		end
	end

	local GroupData = g_Word_Group1
	if not this:IsVisible() then
		this:Show()
	end

--	for i = 1, 6 do
--		if nNext > i then
--			if States[i] == 1 then
--				g_Word_Buttons[i]:SetProperty( "Image", GroupData[i].iconbase .. "_Hover" )
--				if GroupData[i].s == 0 then
--					g_Word_Flashes[i]:SetProperty("Animate","ValentinePoem_pinkstar")
--				else
--					g_Word_Flashes[i]:SetProperty("Animate","ValentinePoem_bluestar")
--				end
--				g_Word_Flashes[i]:Show()
--			else
--				g_Word_Buttons[i]:SetProperty( "Image", GroupData[i].iconbase .. "_Disable" )
--				g_Word_Flashes[i]:Hide()
--			end
--		elseif nNext == i then
--			g_Word_Buttons[i]:SetProperty( "Image", GroupData[i].iconbase .. "_Pushed" )
--			CoupleQuest_Explain:SetText( ScriptGlobal_Format( "#{YDSS_15018_99}", usrName, GroupData[i].skillname ) )
--			if GroupData[i].s == 0 then
--				g_Word_Flashes[i]:SetProperty("Animate","ValentinePoem_pink")
--			else
--				g_Word_Flashes[i]:SetProperty("Animate","ValentinePoem_blue")
--			end
--			g_Word_Flashes[i]:Show()
--		else
--			g_Word_Buttons[i]:SetProperty( "Image", GroupData[i].iconbase .. "_Normal" )
--			g_Word_Flashes[i]:Hide()
--		end
--	end


	for i = 1, 6 do
		if nNext > i then
			if States[i] == 1 then
				g_Word_Buttons[i]:SetProperty( "Image", GroupData[i].iconbase .. "_Hover" ) --已做过的正确的
				if GroupData[i].s == 0 then
					g_Word_Flashes[i]:SetProperty("Animate","ValentinePoem_pinkstar")
				else
					g_Word_Flashes[i]:SetProperty("Animate","ValentinePoem_bluestar")
				end
				g_Word_Flashes[i]:Show()
			else
				g_Word_Buttons[i]:SetProperty( "Image", GroupData[i].iconbase .. "_Disabled" ) --已做过的错误的
				g_Word_Flashes[i]:Hide()
			end
		elseif nNext == i then--当前那个
			g_Word_Buttons[i]:SetProperty( "Image", GroupData[i].iconbase .. "_Normal" )
			CoupleQuest_Explain:SetText( ScriptGlobal_Format( "#{FQRC_150605_300}", usrName, GroupData[i].skillname ) )
			if GroupData[i].s == 0 then
				g_Word_Flashes[i]:SetProperty("Animate","ValentinePoem_pink")
			else
				g_Word_Flashes[i]:SetProperty("Animate","ValentinePoem_blue")
			end
			g_Word_Flashes[i]:Show()
		else--初始
			g_Word_Buttons[i]:SetProperty( "Image", GroupData[i].iconbase .. "_Normal" )
			g_Word_Flashes[i]:Hide()
		end
	end

end
