local g_Frame_UnifiedPosition = nil
local g_Index = -1
local g_CheckRoom = -1
local g_Timer = -1
local g_Timer1 = -1
local g_CDTime = 0

local g_FlashIndex = -1

local g_Star = {}
local g_Over = {}
local g_Check = {}
local g_Team1 = {}
local g_Team2 = {}
local g_Team3 = {}
local g_Self = {}
local g_Active = {}

local g_RoomNumMax = 61

local g_Stage = 0

local g_Image1 = {
	[1] = "set:FengYun_PVP image:FengYun_PVP_ZM", 
	[2] = "set:FengYun_PVP image:FengYun_PVP_WN",	
	[3] = "set:FengYun_PVP image:FengYun_PVP_JSHJ", 
	[4] = "set:FengYun_PVP image:FengYun_PVP_LY",	
	[5] = "set:FengYun_PVP image:FengYun_PVP_JM2", 
}

local g_Image2 = {
	[1] = "set:FengYun_PVP image:FengYun_PVP_ZMP", 
	[2] = "set:FengYun_PVP image:FengYun_PVP_WNP",	
	[3] = "set:FengYun_PVP image:FengYun_PVP_JSHJP", 
	[4] = "set:FengYun_PVP image:FengYun_PVP_LYP",	
	[5] = "set:FengYun_PVP image:FengYun_PVP_JM2P", 
} 


--=========
-- PreLoad()
--=========
function FengYun_JianJiSceneFb_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--	
	this:RegisterEvent("OPEN_FYJCPVPMAP", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function FengYun_JianJiSceneFb_OnLoad()

	for i = 1, 61 do
		g_Star[i] = _G[string.format("FengYun_JianJiSceneFb_Room%d_Start",i)]
		g_Over[i] = _G[string.format("FengYun_JianJiSceneFb_Room%d_Select",i)]
		g_Check[i] = _G[string.format("FengYun_JianJiSceneFb_Room%d_Hover",i)]
		g_Team1[i] = _G[string.format("FengYun_JianJiSceneFb_Room%d_Team",i)]
		g_Team2[i] = _G[string.format("FengYun_JianJiSceneFb_Room%d_Team2",i)]
		g_Team3[i] = _G[string.format("FengYun_JianJiSceneFb_Room%d_Team3",i)]
		g_Self[i] = _G[string.format("FengYun_JianJiSceneFb_Room%d_Self",i)]
		g_Active[i] = _G[string.format("FengYun_JianJiSceneFb_Room%d_Pushed",i)]
	end
	
	

end

--=========
-- Event
--=========
function FengYun_JianJiSceneFb_OnEvent(event)

	if(event == "OPEN_FYJCPVPMAP")  then
		
		FengYun_JianJiSceneFb_Open()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		FengYun_JianJiSceneFb_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		FengYun_JianJiSceneFb_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		FengYun_JianJiSceneFb_On_ResetPos()
		
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331200001) then	--服务端传数据
		if g_Timer > 0 then
			KillTimer("FengYun_JianJiSceneFb_Timer()")
		end
		g_Timer = 15
		SetTimer("FengYun_JianJiSceneFb","FengYun_JianJiSceneFb_Timer()", 1*1000)
		local nIndex = Get_XParam_INT(0)
		if g_Active[g_FlashIndex] ~= nil then
			g_Active[g_FlashIndex]:Hide()
		end
		g_FlashIndex = nIndex
		if g_Active[nIndex] ~= nil then
			g_Active[nIndex]:Show()
		end
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331200004) then	--服务端传数据
		
		g_Stage = Get_XParam_INT(8) 	
		
	end
	
	
end


function FengYun_JianJiSceneFb_Close()
	
	this:Hide()
end

--=========
-- 重置
--=========
function FengYun_JianJiSceneFb_On_ResetPos()

	FengYun_JianJiSceneFb_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function FengYun_JianJiSceneFb_Open()

	for i = 1, g_RoomNumMax do
		g_Star[i]:Show()
		g_Over[i]:Hide()
		g_Check[i]:Hide()
		g_Team1[i]:Hide()
		g_Team2[i]:Hide()
		g_Team3[i]:Hide()
		g_Self[i]:Hide()
		g_Active[i]:Hide()
	end
	
	if g_Active[g_FlashIndex] ~= nil and g_Timer > 0 then
		g_Active[g_FlashIndex]:Show()
	end
	
	if g_Stage == 1 then
		FengYun_JianJiSceneFb_Room17_Start:SetProperty("Image", g_Image1[1])
		FengYun_JianJiSceneFb_Room19_Start:SetProperty("Image", g_Image1[2])
		FengYun_JianJiSceneFb_Room25_Start:SetProperty("Image", g_Image1[3])
		FengYun_JianJiSceneFb_Room31_Start:SetProperty("Image", g_Image1[4])
		FengYun_JianJiSceneFb_Room33_Start:SetProperty("Image", g_Image1[5])
		
		FengYun_JianJiSceneFb_Room17_Select:SetProperty("Image", g_Image2[1])
		FengYun_JianJiSceneFb_Room19_Select:SetProperty("Image", g_Image2[2])
		FengYun_JianJiSceneFb_Room25_Select:SetProperty("Image", g_Image2[3])
		FengYun_JianJiSceneFb_Room31_Select:SetProperty("Image", g_Image2[4])
		FengYun_JianJiSceneFb_Room33_Select:SetProperty("Image", g_Image2[5])
	end

	
	local nMySelfRoomIndex, nGameStage = AskFYJCPVPMapBaseInfo()
	if g_Self[nMySelfRoomIndex] ~= nil then
		g_Self[nMySelfRoomIndex]:Show()
	end
	-- roomtype:0出生点 1草 2矿 3小boss 4大boss
	for i = 1, g_RoomNumMax do
		local nRet, nRoomType, nRoomTeamNum, nRoomMonsterNum =  AskFYJCPVPMapInfo(i-1)
		
		--显示每个房间队伍数
		if nGameStage == 0 then
			if nRoomType == 1 then
				if nRoomTeamNum == 1 then
					g_Team1[i]:Show()
				elseif nRoomTeamNum == 2 then
					g_Team3[i]:Show()
				end
			elseif nRoomType == 2 then
				if nRoomTeamNum == 1 then
					g_Team1[i]:Show()
				elseif nRoomTeamNum == 2 then
					g_Team2[i]:Show()
				elseif nRoomTeamNum == 3 then
					g_Team3[i]:Show()
				end
			else
				if nRoomTeamNum == 1 then
					g_Team1[i]:Show()
				elseif nRoomTeamNum >= 2 then
					g_Team2[i]:Show()
				end
			end
			FengYun_JianJiSceneFb_Room25_StartBK:Show()
			FengYun_JianJiSceneFb_Info1_Text2:SetText("#{FYPVP_260106_245}")
		elseif nGameStage == 1 then
			if nRoomTeamNum == 1 then
				g_Team1[i]:Show()
			elseif nRoomTeamNum >= 2 then
				g_Team2[i]:Show()
			end
			FengYun_JianJiSceneFb_Room25_StartBK:Hide()
			FengYun_JianJiSceneFb_Info1_Text2:SetText("#{FYPVP_260106_246}")
		end
		
		--怪没了
		if nRoomType == 1 or nRoomType == 2 or nRoomType == 3 or nRoomType == 4 then
			if nRoomMonsterNum == 0 then
				g_Star[i]:Hide()
				g_Over[i]:Show()
			end
		end
	end
	
	
	this:Show()
end	

function FengYun_JianJiSceneFb_Timer()
	g_Timer = g_Timer - 1 
	if g_Timer == 0 then
		KillTimer("FengYun_JianJiSceneFb_Timer()")
		if g_Active[g_FlashIndex] ~= nil then
			g_Active[g_FlashIndex]:Hide()
		end
	end
end



function FengYun_JianJiSceneFb_Room_Clicked(index)
	
	if index < 1 or index > 49 then
		return 0
	end	
	if g_Check[g_CheckRoom] ~= nil then
		g_Check[g_CheckRoom]:Hide()
	end
	g_CheckRoom = index
	g_Check[g_CheckRoom]:Show()
		
	
end

function FengYun_JianJiSceneFb_GO()
	
	if g_CheckRoom == -1 then
		PushDebugMessage("#{FYPVP_260106_144}")
		return 0
	end
	--点错了惩罚0.2秒
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_CDTime < 15000) then
		PushDebugMessage(ScriptGlobal_Format("#{FYPVP_260106_145}",  math.floor((15000-(curTime - g_CDTime))/1000)))
   		return;
   	end
	g_CDTime = curTime
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "PlayerGo" )
		Set_XSCRIPT_ScriptID(331200)
		Set_XSCRIPT_Parameter(0, g_CheckRoom);	
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	

end

