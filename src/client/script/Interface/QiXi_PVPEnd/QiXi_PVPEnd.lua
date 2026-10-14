-- 保存UI默认位置
local QiXi_PVPEnd_Frame_UnifiedPosition = nil
local g_Timer = 0
local g_QiXi_PVPEnd_MyScoreUI = ""

local g_QiXi_PVPEnd_CountDownUI = ""

local g_QiXi_PVPEnd_BoxPrizeUI = ""
local g_QiXi_PVPEnd_DaibiPrizeUI = ""

local g_QiXi_ActionItemID1 = 0
local g_QiXi_ActionItemID2 = 0

local g_QiXi_PVPEnd_BoxPrize = {39925423,39925424}
local g_QiXi_PVPEnd_DaibiPrize = 
{
	[1] = {id = 39925425, limit = 100, num = 0,},
	[2] = {id = 39925425, limit = 300, num = 15,},
	[3] = {id = 39925425, limit = 500, num = 25,},	
	[4] = {id = 39925425, limit = 800, num = 30,},
}

local g_QiXi_PVPEnd_BoxPrizeKj = {39925474,39925475}
local g_QiXi_PVPEnd_DaibiPrizeKj = 
{
	[1] = {id = 39925425, limit = 100, num = 0,},
	[2] = {id = 39925425, limit = 300, num = 15,},
	[3] = {id = 39925425, limit = 500, num = 25,},	
	[4] = {id = 39925425, limit = 800, num = 30,},
}

local g_QiXi_PVPEnd_BoxPrizeSj = {39925476,39925477}
local g_QiXi_PVPEnd_DaibiPrizeSj = 
{
	[1] = {id = 39925425, limit = 100, num = 0,},
	[2] = {id = 39925425, limit = 300, num = 15,},
	[3] = {id = 39925425, limit = 500, num = 25,},	
	[4] = {id = 39925425, limit = 800, num = 30,},
}

local g_QiXi_PVPEnd_BoxPrizeQx = {39925478,39925479}
local g_QiXi_PVPEnd_DaibiPrizeQx = 
{
	[1] = {id = 39925425, limit = 100, num = 0,},
	[2] = {id = 39925425, limit = 300, num = 15,},
	[3] = {id = 39925425, limit = 500, num = 25,},	
	[4] = {id = 39925425, limit = 800, num = 30,},
}
local g_QiXi_PVPEnd_PrizeLimit = 100

local g_QiXi_PVPEnd_WinTypeStr = 
{
	[1] = "#{XQPVP_260526_171}",   --士气
	[2] = "#{XQPVP_260526_172}",   --击败
	[3] = "#{XQPVP_260526_173}",   --血量
}

function QiXi_PVPEnd_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")

end -- end func QiXi_PVPEnd_Frame_PreLoad()

function QiXi_PVPEnd_OnLoad()
    QiXi_PVPEnd_Frame_UnifiedPosition = QiXi_PVPEnd_Frame:GetProperty("UnifiedPosition")
	
	g_QiXi_PVPEnd_CountDownUI = QiXi_PVPEnd_Text2
	
	g_QiXi_PVPEnd_BoxPrizeUI = QiXi_PVPEnd_RewardAward1
	g_QiXi_PVPEnd_DaibiPrizeUI = QiXi_PVPEnd_RewardAward2
	
	g_QiXi_PVPEnd_MyScore = QiXi_PVPEnd_MyNum

end -- end func QiXi_PVPEnd_Frame_OnLoad()

function QiXi_PVPEnd_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        QiXi_PVPEnd_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        QiXi_PVPEnd_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        QiXi_PVPEnd_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 56004106) then	--服务端传数据
		
		local winnerTeamId = Get_XParam_INT(0) 
		local myTeamIdBaseOne = Get_XParam_INT(1)	
		local myScore = Get_XParam_INT(2) 
		local myRank = Get_XParam_INT(3) 
		local redTdsq = Get_XParam_INT(4) 
		local blueTdsq = Get_XParam_INT(5) 
		local winType = Get_XParam_INT(6) 

		QiXi_PVPEnd_Frame_Update(winnerTeamId,myTeamIdBaseOne,myScore,myRank,redTdsq,blueTdsq,winType)	
		
		SetTimer("QiXi_PVPEnd", "QiXi_PVPEnd_Timer()", 1000)
		g_Timer = 30
		g_QiXi_PVPEnd_CountDownUI:SetText(ScriptGlobal_Format("#{XQPVP_260526_93}",g_Timer))
		this:Show()

	end
end -- end func QiXi_PVPEnd_Frame_OnEvent()

---!!!reloadscript =QiXi_PVPEnd
---!!!reloadscript =QiXi_PVPEndMini
function QiXi_PVPEnd_Frame_Update(winnerTeamId,myTeamIdBaseOne,myScore,myRank,redTdsq,blueTdsq,winType)	

	if winnerTeamId == 1 then
		QiXi_PVPEnd_PlayerA_Win:Show()
		QiXi_PVPEnd_PlayerAText:Show()
		QiXi_PVPEnd_PlayerB_Win:Hide()
		QiXi_PVPEnd_PlayerBText:Hide()
	elseif winnerTeamId == 2 then
		QiXi_PVPEnd_PlayerB_Win:Show()
		QiXi_PVPEnd_PlayerBText:Show()
		QiXi_PVPEnd_PlayerA_Win:Hide()
		QiXi_PVPEnd_PlayerAText:Hide()
	else
		QiXi_PVPEnd_PlayerA_Win:Hide()
		QiXi_PVPEnd_PlayerB_Win:Hide()
		QiXi_PVPEnd_PlayerAText:Hide()
		QiXi_PVPEnd_PlayerBText:Hide()
	end
	
	if myTeamIdBaseOne == 1 then
		QiXi_PVPEnd_IsMe:Show()
		QiXi_PVPEnd_IsEnemy:Hide()
		QiXi_PVPEnd_Black_IsEnemy:Show()
		QiXi_PVPEnd_Black_IsMe:Hide()
	elseif myTeamIdBaseOne == 2 then
		QiXi_PVPEnd_IsMe:Hide()
		QiXi_PVPEnd_IsEnemy:Show()
		QiXi_PVPEnd_Black_IsEnemy:Hide()
		QiXi_PVPEnd_Black_IsMe:Show()
	else
		QiXi_PVPEnd_IsMe:Hide()
		QiXi_PVPEnd_IsEnemy:Hide()
		QiXi_PVPEnd_Black_IsEnemy:Hide()
		QiXi_PVPEnd_Black_IsMe:Hide()
	end
	
	local iwin = 2
	if winnerTeamId == myTeamIdBaseOne then
		iwin = 1
	end
	
	QiXi_PVPEnd_MySelfText:SetText(ScriptGlobal_Format("#{XQPVP_260526_90}",myScore))
	
	if winType <= 0 or winType > 3 then
		winType = 1
	end

	QiXi_PVPEnd_PlayerAText:SetText(g_QiXi_PVPEnd_WinTypeStr[winType])
	QiXi_PVPEnd_PlayerBText:SetText(g_QiXi_PVPEnd_WinTypeStr[winType])

	local boxPrizeData = g_QiXi_PVPEnd_BoxPrize
	local daibiPrizeData = g_QiXi_PVPEnd_DaibiPrize
	
	if KaJi:LuaFnIsKaJiServer() == 1 then	
		boxPrizeData = g_QiXi_PVPEnd_BoxPrizeKj
		daibiPrizeData = g_QiXi_PVPEnd_DaibiPrizeKj
	elseif (Player:GetData("IsOriginalJD") == 1) then
		boxPrizeData = g_QiXi_PVPEnd_BoxPrizeSj
		daibiPrizeData = g_QiXi_PVPEnd_DaibiPrizeSj
	elseif (Player:GetData("Is2606S") == 1) then
		boxPrizeData = g_QiXi_PVPEnd_BoxPrizeQx
		daibiPrizeData = g_QiXi_PVPEnd_DaibiPrizeQx
	end

	local theAction1 = DataPool:CreateBindActionItemForShow(boxPrizeData[iwin], 1)
	local g_QiXi_ActionItemID1 = theAction1:GetID()
	if g_QiXi_ActionItemID1 ~= 0 then
		g_QiXi_PVPEnd_BoxPrizeUI:SetActionItem(g_QiXi_ActionItemID1) --展示道具
		g_QiXi_PVPEnd_BoxPrizeUI:Show()
	else
		g_QiXi_PVPEnd_BoxPrizeUI:Hide()
	end

	local daibiLevel = -1
	for i = 1, table.getn(daibiPrizeData) do
		if myScore >= daibiPrizeData[i].limit then
			daibiLevel = i
		end
	end
	
	if daibiPrizeData[daibiLevel] ~= nil and daibiPrizeData[daibiLevel].num > 0 then
		
		local theAction2 = DataPool:CreateBindActionItemForShow(daibiPrizeData[daibiLevel].id, daibiPrizeData[daibiLevel].num)
		local g_QiXi_ActionItemID2 = theAction2:GetID()
		if g_QiXi_ActionItemID2 ~= 0 then
			g_QiXi_PVPEnd_DaibiPrizeUI:SetActionItem(g_QiXi_ActionItemID2) --展示道具
			g_QiXi_PVPEnd_DaibiPrizeUI:Show()
		else
			g_QiXi_PVPEnd_DaibiPrizeUI:Hide()
		end
	else 	
		g_QiXi_ActionItemID2 = -1
		g_QiXi_PVPEnd_DaibiPrizeUI:SetActionItem(-1) --展示道具
	end
	
	if myScore < g_QiXi_PVPEnd_PrizeLimit then
		g_QiXi_PVPEnd_BoxPrizeUI:Hide()
		g_QiXi_PVPEnd_DaibiPrizeUI:Hide()
	else 
		g_QiXi_PVPEnd_BoxPrizeUI:Show()
		g_QiXi_PVPEnd_DaibiPrizeUI:Show()
	end
	
end -- end func QiXi_PVPEnd_Frame_Updata()


-- 界面默认位置
function QiXi_PVPEnd_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (QiXi_PVPEnd_Frame_UnifiedPosition ~= nil) then
            QiXi_PVPEnd_Frame:SetProperty("UnifiedPosition", QiXi_PVPEnd_Frame_UnifiedPosition)
        end
    end
end -- end func QiXi_PVPEnd_Frame_UnifiedPos()

function QiXi_PVPEnd_Timer()
	if g_Timer < 0 then
		KillTimer("QiXi_PVPEnd_Timer()")
		QiXi_PVPEnd_Hide()
	else 
		g_Timer = g_Timer - 1
		if g_Timer >= 0 then
			g_QiXi_PVPEnd_CountDownUI:SetText(ScriptGlobal_Format("#{XQPVP_260526_93}",g_Timer))
		end
	end
end



function QiXi_PVPEnd_Hide()
    this:Hide()
end -- end func QiXi_PVPEnd_Hide()


function QiXi_PVPEnd_Close_Clicked()
    this:Hide()
end -- end func QiXi_PVPEnd_Frame_Help()



function QiXi_PVPEnd_Quit()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "QuitGobackToCity" )
		Set_XSCRIPT_ScriptID(560041)
		Set_XSCRIPT_Parameter(0, 0);	
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end


function QiXi_PVPEnd_FormatTime(nSec)

	local min = math.floor(nSec/60)
	local sec = math.mod(nSec,60)
	
	if min < 10 then
		return string.format("%02d:%02d",min,sec)
	else
		return string.format("%d:%02d",min,sec)
	end
	
end
