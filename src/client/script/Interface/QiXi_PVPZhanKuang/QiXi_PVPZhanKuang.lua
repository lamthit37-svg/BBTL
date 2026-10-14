-- 保存UI默认位置
local QiXi_PVPZhanKuang_Frame_UnifiedPosition = nil

local g_QiXi_PVPZhanKuang_TeamUI = {}

local g_QiXi_PVPZhanKuang_YequUI = {}

local g_QiXi_PVPZhanKuang_MyScoreUI = ""
local g_QiXi_PVPZhanKuang_CountDownUI = ""
local g_Qixi_PVPZhanKuang_warindex = -1


local g_QiXi_PVPZhanKuang_TeamUIImageList = 
{
	[1] = {		
		smAOn = "set:QiXi_PVP image:QixiPVP_HanXin2",
		smAOff = "set:QiXi_PVP image:QixiPVP_HanXin2Die",
		smBOn = "set:QiXi_PVP image:QixiPVP_ZhangLiang2",
		smBOff = "set:QiXi_PVP image:QixiPVP_ZhangLiang2Die",
	},
	
	[2] = {		
		smAOn = "set:QiXi_PVP image:QixiPVP_YuJi2",
		smAOff = "set:QiXi_PVP image:QixiPVP_YuJi2Die",
		smBOn = "set:QiXi_PVP image:QixiPVP_FanZeng2",
		smBOff = "set:QiXi_PVP image:QixiPVP_FanZeng2Die",
	},
}

local g_QiXi_PVPZhanKuang_YequUIImageList = 
{
	[1] = {	NT = "set:QiXi_PVP image:QixiPVP_PaoHuang",T1 = "set:QiXi_PVP image:QixiPVP_PaoLan",T2 = "set:QiXi_PVP image:QixiPVP_PaoHong",},
	[2] = {	NT = "set:QiXi_PVP image:QixiPVP_CheHuang",T1 = "set:QiXi_PVP image:QixiPVP_CheLan",T2 = "set:QiXi_PVP image:QixiPVP_CheHong",},	
	[3] = {	NT = "set:QiXi_PVP image:QixiPVP_CheHuang",T1 = "set:QiXi_PVP image:QixiPVP_CheLan",T2 = "set:QiXi_PVP image:QixiPVP_CheHong",},
	[4] = {	NT = "set:QiXi_PVP image:QixiPVP_PaoHuang",T1 = "set:QiXi_PVP image:QixiPVP_PaoLan",T2 = "set:QiXi_PVP image:QixiPVP_PaoHong",},	
}

function QiXi_PVPZhanKuang_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("QXPVP_BIG",true)     -- 窗口分辨率发生变化

end -- end func QiXi_PVPZhanKuang_Frame_PreLoad()

function QiXi_PVPZhanKuang_OnLoad()
    QiXi_PVPZhanKuang_Frame_UnifiedPosition = QiXi_PVPZhanKuang_Frame:GetProperty("UnifiedPosition")
	
	g_QiXi_PVPZhanKuang_TeamUI[1] = {}

	g_QiXi_PVPZhanKuang_TeamUI[1].HPText1 = QiXi_PVPZhanKuang_TextNum_2
	g_QiXi_PVPZhanKuang_TeamUI[1].HPText2 = QiXi_PVPZhanKuang_TextNum
	g_QiXi_PVPZhanKuang_TeamUI[1].smA = QiXi_PVPZhanKuang_ChuBing2
	g_QiXi_PVPZhanKuang_TeamUI[1].smB = QiXi_PVPZhanKuang_ChuBing
	g_QiXi_PVPZhanKuang_TeamUI[1].HPProgress = QiXi_PVPZhanKuang_Progress
	g_QiXi_PVPZhanKuang_TeamUI[1].score = QiXi_PVPZhanKuang_ChuNum
	g_QiXi_PVPZhanKuang_TeamUI[1].state = QiXi_PVPZhanKuang_Chu_Buff
	g_QiXi_PVPZhanKuang_TeamUI[1].isMe = QiXi_PVPZhanKuang_ChuMy
	g_QiXi_PVPZhanKuang_TeamUI[2] = {}

	g_QiXi_PVPZhanKuang_TeamUI[2].HPText1 = QiXi_PVPZhanKuang_TextNum2_2
	g_QiXi_PVPZhanKuang_TeamUI[2].HPText2 = QiXi_PVPZhanKuang_TextNum2
	g_QiXi_PVPZhanKuang_TeamUI[2].smA = QiXi_PVPZhanKuang_HanBing
	g_QiXi_PVPZhanKuang_TeamUI[2].smB = QiXi_PVPZhanKuang_HanBing2
	g_QiXi_PVPZhanKuang_TeamUI[2].HPProgress = QiXi_PVPZhanKuang_Progress2
	g_QiXi_PVPZhanKuang_TeamUI[2].score = QiXi_PVPZhanKuang_HanNum
	g_QiXi_PVPZhanKuang_TeamUI[2].state = QiXi_PVPZhanKuang_Han_Buff
	g_QiXi_PVPZhanKuang_TeamUI[2].isMe = QiXi_PVPZhanKuang_HanMy
	
	g_QiXi_PVPZhanKuang_YequUI[1] = {}
	g_QiXi_PVPZhanKuang_YequUI[1].icon = QiXi_PVPZhanKuang_ChuChe
	g_QiXi_PVPZhanKuang_YequUI[1].state = QiXi_PVPZhanKuang_Chu_Text1
	g_QiXi_PVPZhanKuang_YequUI[1].timer = QiXi_PVPZhanKuang_Chu_Time1
	g_QiXi_PVPZhanKuang_YequUI[2] = {}
	g_QiXi_PVPZhanKuang_YequUI[2].icon = QiXi_PVPZhanKuang_ChuPao
	g_QiXi_PVPZhanKuang_YequUI[2].state = QiXi_PVPZhanKuang_Chu_Text2
	g_QiXi_PVPZhanKuang_YequUI[2].timer = QiXi_PVPZhanKuang_Chu_Time2
	g_QiXi_PVPZhanKuang_YequUI[3] = {}
	g_QiXi_PVPZhanKuang_YequUI[3].icon = QiXi_PVPZhanKuang_HanChe
	g_QiXi_PVPZhanKuang_YequUI[3].state = QiXi_PVPZhanKuang_Han_Text1
	g_QiXi_PVPZhanKuang_YequUI[3].timer = QiXi_PVPZhanKuang_Han_Time1
	g_QiXi_PVPZhanKuang_YequUI[4] = {}
	g_QiXi_PVPZhanKuang_YequUI[4].icon = QiXi_PVPZhanKuang_HanPao
	g_QiXi_PVPZhanKuang_YequUI[4].state = QiXi_PVPZhanKuang_Han_Text2
	g_QiXi_PVPZhanKuang_YequUI[4].timer = QiXi_PVPZhanKuang_Han_Time2

	
	g_QiXi_PVPZhanKuang_MyScoreUI = QiXi_PVPZhanKuang_MyNum
	g_QiXi_PVPZhanKuang_CountDownUI = QiXi_PVPZhanKuang_Countdown_Time

end -- end func QiXi_PVPZhanKuang_Frame_OnLoad()

function QiXi_PVPZhanKuang_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        QiXi_PVPZhanKuang_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        QiXi_PVPZhanKuang_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        QiXi_PVPZhanKuang_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 56004101) then	--服务端传数据

		local myTeamIdBaseOne = Get_XParam_INT(0)	
		
		if myTeamIdBaseOne == 99999 then
			this:Hide()
			return 
		end
		
		local myScore = Get_XParam_INT(1) 
		--local bossAlive1 = Get_XParam_INT(2) 
		local bossPercentHp1 = Get_XParam_INT(3) 
		local smallAAlive1 = Get_XParam_INT(4) 

		local smallBAlive1 = Get_XParam_INT(5)	
		local gatePercentHp1 = Get_XParam_INT(6) 
		--local bossAlive2 = Get_XParam_INT(7) 
		local bossPercentHp2 = Get_XParam_INT(8) 
		local smallAAlive2 = Get_XParam_INT(9) 

		local smallBAlive2 = Get_XParam_INT(10) 
		local gatePercentHp2  = Get_XParam_INT(11) 
		local redTdsq  = Get_XParam_INT(12) 
		local blueTdsq  = Get_XParam_INT(13) 
		local leftTime  = Get_XParam_INT(14)  
		g_Qixi_PVPZhanKuang_warindex  = Get_XParam_INT(15)  
		
		local yqInfo12  = Get_XParam_INT(2) 
		local yqInfo34  = Get_XParam_INT(7) 

		QiXi_PVPZhanKuang_Frame_Update(myTeamIdBaseOne,myScore,bossPercentHp1,smallAAlive1,smallBAlive1,gatePercentHp1,bossPercentHp2,smallAAlive2,smallBAlive2,gatePercentHp2,redTdsq,blueTdsq,leftTime,yqInfo12,yqInfo34)															
		
		--打开界面
		if(IsWindowShow("QiXi_PVPZhanKuangMini")) then
			
		else
			this:Show()
		end 		
		
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 56004105) then	--服务端传数据
		local myTeamIdBaseOne = Get_XParam_INT(0)	
		local myScore = Get_XParam_INT(1) 
		local redTdsq  = Get_XParam_INT(2) 
		local blueTdsq  = Get_XParam_INT(3) 
		local leftTime  = Get_XParam_INT(4) 
		g_Qixi_PVPZhanKuang_warindex  = Get_XParam_INT(5)  
		QiXi_PVPZhanKuang_Frame_UpdateSimple(myTeamIdBaseOne,myScore,redTdsq,blueTdsq,leftTime)
		
		--打开界面
		if(IsWindowShow("QiXi_PVPZhanKuangMini")) then
			
		else
			this:Show()
		end 
	elseif (event == "QXPVP_BIG") then
		this:Show()

	end
end -- end func QiXi_PVPZhanKuang_Frame_OnEvent()

---!!!reloadscript =QiXi_PVPZhanKuang
---!!!reloadscript =QiXi_PVPZhanKuangMini
function QiXi_PVPZhanKuang_Frame_Update(myTeamIdBaseOne,myScore,bossPercentHp1,smallAAlive1,smallBAlive1,gatePercentHp1,bossPercentHp2,smallAAlive2,smallBAlive2,gatePercentHp2,redTdsq,blueTdsq,leftTime,yqInfo12,yqInfo34)	

	if myTeamIdBaseOne == 99999 then
		this:Hide()
		return
	end
	
	local teamInfo = {}
	teamInfo[1] = {}
	teamInfo[1].bigbossHP = math.floor(bossPercentHp1/100)
	if teamInfo[1].bigbossHP == 0 and bossPercentHp1 > 0 then
		teamInfo[1].bigbossHP = 1
	end
	teamInfo[1].smA = smallAAlive1
	teamInfo[1].smB = smallBAlive1
	teamInfo[1].gateHP = math.floor(gatePercentHp1/100)
	if teamInfo[1].gateHP == 0 and gatePercentHp1 > 0 then
		teamInfo[1].gateHP = 1
	end
	teamInfo[1].score = redTdsq
	teamInfo[2] = {}
	teamInfo[2].bigbossHP = math.floor(bossPercentHp2/100)
	if teamInfo[2].bigbossHP == 0 and bossPercentHp2 > 0 then
		teamInfo[2].bigbossHP = 1
	end
	teamInfo[2].smA = smallAAlive2
	teamInfo[2].smB = smallBAlive2
	teamInfo[2].gateHP = math.floor(gatePercentHp2/100)
	if teamInfo[2].gateHP == 0 and gatePercentHp2 > 0 then
		teamInfo[2].gateHP = 1
	end
	teamInfo[2].score = blueTdsq
	local yqInfo = {}
	yqInfo[1] = math.mod(yqInfo12,10000)
	yqInfo[2] = math.floor(yqInfo12/10000)
	yqInfo[3] = math.mod(yqInfo34,10000)
	yqInfo[4] = math.floor(yqInfo34/10000)

	if myTeamIdBaseOne ~= 1 and myTeamIdBaseOne ~=2 then
		myTeamIdBaseOne = 1
	end

	g_QiXi_PVPZhanKuang_TeamUI[1].isMe:Hide()
	g_QiXi_PVPZhanKuang_TeamUI[2].isMe:Hide()
	g_QiXi_PVPZhanKuang_TeamUI[myTeamIdBaseOne].isMe:Show()

	for i = 1, 2 do
		
		if teamInfo[i].bigbossHP > 0 then
		---	g_QiXi_PVPZhanKuang_TeamUI[i].bigboss:SetProperty("Image",g_QiXi_PVPZhanKuang_TeamUIImageList[i].bigBossOn)
			g_QiXi_PVPZhanKuang_TeamUI[i].HPText1:Show()
			g_QiXi_PVPZhanKuang_TeamUI[i].HPText2:Show()
			---local bossHp = ScriptGlobal_Format("#{XQPVP_260526_73}",teamInfo[i].bigbossHP)
			g_QiXi_PVPZhanKuang_TeamUI[i].HPText1:SetText("#{XQPVP_260526_73}")		
			g_QiXi_PVPZhanKuang_TeamUI[i].HPText2:SetText(ScriptGlobal_Format("#{XQPVP_260526_185}",teamInfo[i].bigbossHP))		
			g_QiXi_PVPZhanKuang_TeamUI[i].HPProgress:SetProgress(teamInfo[i].bigbossHP, 100)
		else
		---	g_QiXi_PVPZhanKuang_TeamUI[i].bigboss:SetProperty("Image",g_QiXi_PVPZhanKuang_TeamUIImageList[i].bigBossOff)
			--g_QiXi_PVPZhanKuang_TeamUI[i].bigbossHP:Hide()
			---local bossHp = ScriptGlobal_Format("#{XQPVP_260526_73}",0)
			g_QiXi_PVPZhanKuang_TeamUI[i].HPText1:SetText("#{XQPVP_260526_73}")
			g_QiXi_PVPZhanKuang_TeamUI[i].HPText2:SetText(ScriptGlobal_Format("#{XQPVP_260526_185}",0))
			g_QiXi_PVPZhanKuang_TeamUI[i].HPProgress:SetProgress(0, 100)
		end
		
		if teamInfo[i].smA == 1 then
			g_QiXi_PVPZhanKuang_TeamUI[i].smA:SetProperty("Image",g_QiXi_PVPZhanKuang_TeamUIImageList[i].smAOn)
		else
			g_QiXi_PVPZhanKuang_TeamUI[i].smA:SetProperty("Image",g_QiXi_PVPZhanKuang_TeamUIImageList[i].smAOff)
		end
		if teamInfo[i].smB == 1 then
			g_QiXi_PVPZhanKuang_TeamUI[i].smB:SetProperty("Image",g_QiXi_PVPZhanKuang_TeamUIImageList[i].smBOn)
		else
			g_QiXi_PVPZhanKuang_TeamUI[i].smB:SetProperty("Image",g_QiXi_PVPZhanKuang_TeamUIImageList[i].smBOff)
		end
		
		local powerBoss = {}
		powerBoss[i] = teamInfo[i].smA + teamInfo[i].smB
		if powerBoss[i] > 0 then
			g_QiXi_PVPZhanKuang_TeamUI[i].state:SetText("#{XQPVP_260526_165}")
		else
			g_QiXi_PVPZhanKuang_TeamUI[i].state:SetText("#{XQPVP_260526_166}")
		end
		
		if teamInfo[i].gateHP > 0 then
		---	local gateHP = ScriptGlobal_Format("#{XQPVP_260526_160}",teamInfo[i].gateHP)
			g_QiXi_PVPZhanKuang_TeamUI[i].HPText1:SetText("#{XQPVP_260526_160}")
			g_QiXi_PVPZhanKuang_TeamUI[i].HPText2:SetText(ScriptGlobal_Format("#{XQPVP_260526_185}",teamInfo[i].gateHP))
			g_QiXi_PVPZhanKuang_TeamUI[i].HPProgress:SetProgress(teamInfo[i].gateHP, 100)
		end
	
	end	
	
	for i = 1, 4 do
		if yqInfo[i] == 9999 then
			g_QiXi_PVPZhanKuang_YequUI[i].icon:SetProperty("Image",g_QiXi_PVPZhanKuang_YequUIImageList[i].NT)
			g_QiXi_PVPZhanKuang_YequUI[i].state:SetText("#{XQPVP_260526_168}")
			g_QiXi_PVPZhanKuang_YequUI[i].state:Show()
			g_QiXi_PVPZhanKuang_YequUI[i].timer:Hide()
		elseif yqInfo[i] >= 1000 then
			g_QiXi_PVPZhanKuang_YequUI[i].icon:SetProperty("Image",g_QiXi_PVPZhanKuang_YequUIImageList[i].NT)
			if yqInfo[i] == 1001 then
				g_QiXi_PVPZhanKuang_YequUI[i].icon:SetProperty("Image",g_QiXi_PVPZhanKuang_YequUIImageList[i].T1)
			elseif yqInfo[i] == 1002 then
				g_QiXi_PVPZhanKuang_YequUI[i].icon:SetProperty("Image",g_QiXi_PVPZhanKuang_YequUIImageList[i].T2)
			end
			
			g_QiXi_PVPZhanKuang_YequUI[i].state:SetText("#{XQPVP_260526_167}")
			g_QiXi_PVPZhanKuang_YequUI[i].state:Show()
			g_QiXi_PVPZhanKuang_YequUI[i].timer:Hide()
		elseif yqInfo[i] > 0 then
			g_QiXi_PVPZhanKuang_YequUI[i].icon:SetProperty("Image",g_QiXi_PVPZhanKuang_YequUIImageList[i].NT)
			g_QiXi_PVPZhanKuang_YequUI[i].state:Hide()
			g_QiXi_PVPZhanKuang_YequUI[i].timer:Show()
			g_QiXi_PVPZhanKuang_YequUI[i].timer:SetProperty("Timer", yqInfo[i])
		else
			g_QiXi_PVPZhanKuang_YequUI[i].icon:SetProperty("Image",g_QiXi_PVPZhanKuang_YequUIImageList[i].NT)
			g_QiXi_PVPZhanKuang_YequUI[i].state:SetText("#{XQPVP_260526_167}")
			g_QiXi_PVPZhanKuang_YequUI[i].state:Show()
			g_QiXi_PVPZhanKuang_YequUI[i].timer:Hide()
		end
		
	end
	
	local teamScore1 = ScriptGlobal_Format("#{XQPVP_260526_74}",teamInfo[1].score)
	g_QiXi_PVPZhanKuang_TeamUI[1].score:SetText(teamScore1)

	local teamScore2 = ScriptGlobal_Format("#{XQPVP_260526_75}",teamInfo[2].score)
	g_QiXi_PVPZhanKuang_TeamUI[2].score:SetText(teamScore2)

	g_QiXi_PVPZhanKuang_MyScoreUI:SetText(ScriptGlobal_Format("#{XQPVP_260526_76}",myScore))
	g_QiXi_PVPZhanKuang_CountDownUI:SetProperty("Timer", leftTime)
	
end -- end func QiXi_PVPZhanKuang_Frame_Updata()


function QiXi_PVPZhanKuang_Frame_UpdateSimple(myTeamIdBaseOne,myScore,redTdsq,blueTdsq,leftTime)
	g_QiXi_PVPZhanKuang_TeamUI[1].score:SetText(ScriptGlobal_Format("#{XQPVP_260526_74}",redTdsq))
	g_QiXi_PVPZhanKuang_TeamUI[2].score:SetText(ScriptGlobal_Format("#{XQPVP_260526_75}",blueTdsq))
	g_QiXi_PVPZhanKuang_MyScoreUI:SetText(ScriptGlobal_Format("#{XQPVP_260526_76}",myScore))
	g_QiXi_PVPZhanKuang_CountDownUI:SetProperty("Timer", leftTime)
end

-- 界面默认位置
function QiXi_PVPZhanKuang_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (QiXi_PVPZhanKuang_Frame_UnifiedPosition ~= nil) then
            QiXi_PVPZhanKuang_Frame:SetProperty("UnifiedPosition", QiXi_PVPZhanKuang_Frame_UnifiedPosition)
        end
    end
end -- end func QiXi_PVPZhanKuang_Frame_UnifiedPos()

function QiXi_PVPZhanKuang_Frame_Hide()
    this:Hide()
end -- end func QiXi_PVPZhanKuang_Frame_Hide()


function QiXi_PVPZhanKuang_Help()
    PushEvent("CCSHOP_HELP", 250)
end -- end func QiXi_PVPZhanKuang_Frame_Help()


function QiXi_PVPZhanKuang_Open()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenPlayerKillRank")
		Set_XSCRIPT_ScriptID(507140)
		Set_XSCRIPT_Parameter(0,tonumber(g_Qixi_PVPZhanKuang_warindex))
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
   
end -- end func QiXi_PVPZhanKuang_Open()

function QiXi_PVPZhanKuang_OpenMini()
	QiXi_PVPZhanKuang_Frame_Hide()
	PushEvent("QXPVP_SMALL")
end

function QiXi_PVPZhanKuang_FormatTime(nSec)

	local min = math.floor(nSec/60)
	local sec = math.mod(nSec,60)
	
	if min < 10 then
		return string.format("%02d:%02d",min,sec)
	else
		return string.format("%d:%02d",min,sec)
	end
	
end
