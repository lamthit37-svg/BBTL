local g_XSM_Frame_UnifiedXPosition
local g_XSM_Frame_UnifiedYPosition

local g_purpleCount 
local g_orangeCount
local g_TargetId 
local g_OpenType 
local g_RecvCount 

local MAX_OBJ_DISTANCE = 5.0
local XSM_Reward_Icon1 = {}
local XSM_Reward_Icon2 = {}
local XSM_Btn = {}
local XSM_RecvedImage = {}
local XSM_CompImage = {}
local XSM_NeedTeamCnt = {}
local XSM_MissionDesc = {}
local XSM_MissionRecv = {}
local XSM_MissionId = 1957
local g_Xuanshang_Mission_ClientObjid = -1

local XSM_RewardDisplayItem ={
	[1] = {item1=39923218,count1=10,item2=nil,count2=nil,},
	[2] = {item1=39923218,count1=20,item2={39923215,39923216,39923217},count2={1,1,1},},
	[3] = {item1=39923218,count1=20,item2={39923215,39923216,39923217},count2={2,2,2},},
	[4] = {item1=39923218,count1=20,item2={39923215,39923216,39923217},count2={2,2,2},},
}

local XSM_TeamStr ={
	"#{XFXS_201231_261}",
	"#{XFXS_201231_262}",
	"#{XFXS_201231_263}",
	"#{XFXS_201231_264}",
}

function Xuanshang_Mission_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("SCENE_TRANSED",false)
end


function Xuanshang_Mission_OnLoad()
	g_XSM_Frame_UnifiedXPosition	= Xuanshang_Mission_Frame : GetProperty("UnifiedXPosition")
	g_XSM_Frame_UnifiedYPosition	= Xuanshang_Mission_Frame : GetProperty("UnifiedYPosition")
	g_purpleCount = 0
	g_orangeCount = 0
	g_TargetId = -1
	g_OpenType = 0
	g_RecvCount = 0	
	
	XSM_Reward_Icon1[1] = Xuanshang_Mission_GetCondition1_Icon1
	XSM_Reward_Icon1[2] = Xuanshang_Mission_GetCondition2_Icon1
	XSM_Reward_Icon1[3] = Xuanshang_Mission_GetCondition3_Icon1
	XSM_Reward_Icon1[4] = Xuanshang_Mission_GetCondition4_Icon1

	XSM_Reward_Icon2[1] = Xuanshang_Mission_GetCondition1_Icon2
	XSM_Reward_Icon2[2] = Xuanshang_Mission_GetCondition2_Icon2
	XSM_Reward_Icon2[3] = Xuanshang_Mission_GetCondition3_Icon2
	XSM_Reward_Icon2[4] = Xuanshang_Mission_GetCondition4_Icon2
	
	
	XSM_Btn[1] =Xuanshang_Mission_GetCondition1_Btn
	XSM_Btn[2] =Xuanshang_Mission_GetCondition2_Btn
	XSM_Btn[3] =Xuanshang_Mission_GetCondition3_Btn
	XSM_Btn[4] =Xuanshang_Mission_GetCondition4_Btn
	
	XSM_RecvedImage[1] = Xuanshang_Mission_GetCondition1_BtnImage
	XSM_RecvedImage[2] = Xuanshang_Mission_GetCondition2_BtnImage
	XSM_RecvedImage[3] = Xuanshang_Mission_GetCondition3_BtnImage
	XSM_RecvedImage[4] = Xuanshang_Mission_GetCondition4_BtnImage
	
	XSM_CompImage[1] = Xuanshang_Mission_GetCondition1_BtnImage2
	XSM_CompImage[2] = Xuanshang_Mission_GetCondition2_BtnImage2
	XSM_CompImage[3] = Xuanshang_Mission_GetCondition3_BtnImage2
	XSM_CompImage[4] = Xuanshang_Mission_GetCondition4_BtnImage2
	
	XSM_NeedTeamCnt[1] = Xuanshang_Mission_GetNum1
	XSM_NeedTeamCnt[2] = Xuanshang_Mission_GetNum2
	XSM_NeedTeamCnt[3] = Xuanshang_Mission_GetNum3
	XSM_NeedTeamCnt[4] = Xuanshang_Mission_GetNum4	
	
	XSM_MissionDesc[1] = Xuanshang_Mission_GetMission1_1
	XSM_MissionDesc[2] = Xuanshang_Mission_GetMission2_1
	XSM_MissionDesc[3] = Xuanshang_Mission_GetMission3_1
	XSM_MissionDesc[4] = Xuanshang_Mission_GetMission4_1
	
	XSM_MissionRecv[1] = Xuanshang_Mission_GetMission1_2
	XSM_MissionRecv[2] = Xuanshang_Mission_GetMission2_2
	XSM_MissionRecv[3] = Xuanshang_Mission_GetMission3_2
	XSM_MissionRecv[4] = Xuanshang_Mission_GetMission4_2
end

function Xuanshang_Mission_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 5061011) then
		if tonumber(arg1) == 7 then
			Xuanshang_Mission_Close()
			return
		end
		Xuanshang_Mission_Open()	
	elseif (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" ) then
		Xuanshang_Mission_On_ResetPos()
	elseif ( event == "SCENE_TRANSED") then
		Xuanshang_Mission_Close()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_Xuanshang_Mission_ClientObjid) then
			return
		end

		if arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy" then
			Xuanshang_Mission_Cancel_Clicked()
		end
	end
	
end

function Xuanshang_Mission_Open()	
	SetTimer( "Xuanshang_Mission", "Xuanshang_Mission_Auto_Timer()", 1000 )
	g_OpenType = Get_XParam_INT(0)
	g_TargetId = Get_XParam_INT(1)
	
	g_Xuanshang_Mission_ClientObjid = DataPool : GetNPCIDByServerID(g_TargetId)
	this:CareObject(g_Xuanshang_Mission_ClientObjid, 1, "Xuanshang_Mission")
	
	for x=1,4 do
		Xuanshang_Mission_ShowLine(x)	
	end
	
	local nData = DataPool:GetPlayerMission_DataRound(2233)
	local compCnt = 0
	if math.floor(nData/10) ~= DataPool:GetServerDayTime() then
		compCnt = 0
	else
		compCnt = math.mod(nData,10)
	end
	if compCnt < 2 then
		Xuanshang_Mission_Description_Text1:SetText(ScriptGlobal_Format("#{XFXS_201231_226}", tostring(compCnt)))
	else
		Xuanshang_Mission_Description_Text1:SetText("#{XFXS_201231_320}")
	end
	
	PushEvent("UI_COMMAND", 1000)
	this:Show()
end

function Xuanshang_Mission_On_ResetPos()
	Xuanshang_Mission_Frame : SetProperty("UnifiedXPosition", g_XSM_Frame_UnifiedXPosition)
	Xuanshang_Mission_Frame : SetProperty("UnifiedYPosition", g_XSM_Frame_UnifiedYPosition)
end

function Xuanshang_Mission_Cancel_Clicked()
	Xuanshang_Mission_Close()
end

function Xuanshang_Mission_Close()
	KillTimer("Xuanshang_Mission_Auto_Timer()")
	this : CareObject( g_Xuanshang_Mission_ClientObjid, 0, "Xuanshang_Mission" )
	this:Hide()
end

function Xuanshang_Mission_OnHidden()
	Xuanshang_Mission_Close()
end

function Xuanshang_Mission_Item_Clicked(idx)
	local curCount = 0
	if idx==3 then
		curCount=math.mod(g_RecvCount,10000)
		if curCount >= 1200 then
			PushDebugMessage("#{XFXS_201231_54}")
			return
		end
	elseif idx==4 then
		local nCurDay = DataPool:GetServerDayTime()
		local ds,dt,taskNum,itemID,displayID,forceBind,itemCount,uiSeq,precious = ZhanTuanInterface:GetBountyTaskInfo(nCurDay)
		
		curCount=math.mod(math.floor(g_RecvCount/10000),10000)
		if taskNum == nil then
			PushDebugMessage("#{XFXS_201231_45}")
			return
		end
		if curCount >= taskNum then
			PushDebugMessage("#{XFXS_201231_54}")
			return
		end
	end
		
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RecvMission_PopSecConfirm" )
		Set_XSCRIPT_ScriptID(506100)
		Set_XSCRIPT_Parameter( 0, idx )
		Set_XSCRIPT_Parameter( 1, g_TargetId )
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function Xuanshang_Mission_Description_Clicked()
	PushEvent("CCSHOP_HELP", 180)
end

function Xuanshang_Mission_ShowLine(x)
	
	local theAction1 = DataPool:CreateActionItemForShow(XSM_RewardDisplayItem[x].item1, XSM_RewardDisplayItem[x].count1)
	if theAction1:GetID() ~= 0 then
		XSM_Reward_Icon1[x]:SetActionItem(theAction1:GetID())
	end
	if x > 1 then
		local week1end,week2end = DataPool:Lua_XinFuXuanShangWeekEndDate()
		local weekidx = 1
		local nCurDay = DataPool:GetServerDayTime()
		if nCurDay <= week1end then
			weekidx = 1
		elseif nCurDay <= week2end then
			weekidx = 2
		else
			weekidx = 3
		end
		local theAction2 = DataPool:CreateActionItemForShow(XSM_RewardDisplayItem[x].item2[weekidx], XSM_RewardDisplayItem[x].count2[weekidx])
		if theAction2:GetID() ~= 0 then
			XSM_Reward_Icon2[x]:SetActionItem(theAction2:GetID())
		end
	else
		--XSM_Reward_Icon2[1]:Hide()
	end
	
	if x == 3 then
		local theAction3 = DataPool:CreateActionItemForShow(39923265, 1)
		Xuanshang_Mission_GetCondition3_Extra:SetActionItem(theAction3:GetID())
	end
	
	
	if x == 4 then
		local theAction4 = DataPool:CreateActionItemForShow(39923266, 1)
		Xuanshang_Mission_GetCondition4_Extra:SetActionItem(theAction4:GetID())
	end
	
	local minuteTime = DataPool:GetServerMinuteTime()
	local sttime,endTiem = DataPool:Lua_XinFuZhengHeTime()
	local nCurDay = DataPool:GetServerDayTime()

	if( g_OpenType == 1 ) then
		XSM_Btn[x]:Show()
		XSM_Btn[x]:Disable()
		XSM_RecvedImage[x]:Hide()
		XSM_CompImage[x]:Hide()
		XSM_MissionDesc[x]:SetText("#{XFXS_201231_41}")
		XSM_MissionRecv[x]:SetText("")
	elseif( g_OpenType == 2 ) then
		local iHave = DataPool:Lua_IsHaveMission(XSM_MissionId)
		if(iHave > 0) then
			XSM_Btn[x]:Hide()
			local missionIndex = DataPool:GetPlayerMissionIndexByID(XSM_MissionId)
			local comp = DataPool:GetPlayerMission_Variable(missionIndex, 0)
			local mid = DataPool:GetPlayerMission_Variable(missionIndex, 1)
			local tq,taskType,uiDesc,accDesc,p1,p2,p3,p4,p5,p6,taskDesc,compDesc = ZhanTuanInterface:GetBountyTaskDesc(mid)
			if comp == 1 and x == tq then
				XSM_RecvedImage[x]:Hide()
				XSM_CompImage[x]:Show()
				XSM_Btn[x]:Hide()
			elseif comp == 0 and x == tq then
				XSM_RecvedImage[x]:Show()
				XSM_CompImage[x]:Hide()
				XSM_Btn[x]:Hide()
			else
				XSM_RecvedImage[x]:Hide()
				XSM_CompImage[x]:Hide()
				XSM_Btn[x]:Show()
				XSM_Btn[x]:Disable()
			end
		else
			XSM_Btn[x]:Show()
			XSM_Btn[x]:Enable()
			XSM_RecvedImage[x]:Hide()
			XSM_CompImage[x]:Hide()
		end
		local bountyType = tonumber(Get_XParam_INT(2))
		g_RecvCount = tonumber(Get_XParam_INT(3))
		local typeCount = 0
		local nCurDay = DataPool:GetServerDayTime()
		local ds,dt,taskNum,itemID,displayID,forceBind,itemCount,uiSeq,precious = ZhanTuanInterface:GetBountyTaskInfo(nCurDay)
		if taskNum==nil then
			taskNum = 100
		end
		if x == 3 then
			typeCount = math.mod(g_RecvCount,10000)
			if 1200 - typeCount > 0 then
				XSM_MissionRecv[x]:SetText(ScriptGlobal_Format("#{XFXS_201231_39}",tostring(1200 - typeCount), 1200))
			else
				XSM_MissionRecv[x]:SetText(ScriptGlobal_Format("#{XFXS_201231_40}",tostring(1200 - typeCount), 1200))
			end
		elseif x == 4 then
			typeCount = math.floor(g_RecvCount/10000)
			if taskNum - typeCount > 0 then
				XSM_MissionRecv[x]:SetText(ScriptGlobal_Format("#{XFXS_201231_39}",tostring(taskNum - typeCount), taskNum))
			else
				XSM_MissionRecv[x]:SetText(ScriptGlobal_Format("#{XFXS_201231_40}",tostring(taskNum - typeCount), taskNum))
			end
		else
			XSM_MissionRecv[x]:SetText("")
		end
		
		local missId = 1
		local divParam = math.pow( 100, x - 1 )
		missId = math.mod( math.floor(bountyType/divParam), 100)		
		local tq,taskType,uiDesc,accDesc,p1,p2,p3,p4,p5,p6,taskDesc,compDesc = ZhanTuanInterface:GetBountyTaskDesc(missId)
		--if missId == 10 or missId == 24 then
			--uiDesc = Xuanshang_Mission_GetUIDesc(missId)
		--end
		XSM_MissionDesc[x]:SetText(uiDesc)
		
	end
	if nCurDay > endTiem or (nCurDay == endTiem and minuteTime >= 220000) then
		XSM_MissionDesc[x]:SetText("#{XFXS_201231_42}")
	end
	
	XSM_NeedTeamCnt[x]:SetText(XSM_TeamStr[x])
end

function Xuanshang_Mission_Auto_Timer()
	local minuteTime = DataPool:GetServerMinuteTime()
	local sttime,endTiem = DataPool:Lua_XinFuZhengHeTime()
	local nCurDay = DataPool:GetServerDayTime()	
	
	local curHour = math.floor(minuteTime/10000)
	if( curHour < 12) then
		Xuanshang_Mission_Description_Text2:SetText("#{XFXS_201231_229}")
	elseif(curHour>12 and curHour<18) then
		Xuanshang_Mission_Description_Text2:SetText("#{XFXS_201231_31}")
	elseif(curHour>18 and curHour<20) then
		Xuanshang_Mission_Description_Text2:SetText("#{XFXS_201231_32}")
	elseif(curHour>20) then
		Xuanshang_Mission_Description_Text2:SetText("#{XFXS_201231_30}")
	else	
		local curMinute = math.mod(math.floor(minuteTime/100), 100)
		local curSec = math.mod(minuteTime, 100)
		local leftMinute = 60 - curMinute - 1
		local leftSec = 60 - curSec
		local timeStr = ""
		if leftMinute > 0 then
			timeStr = leftMinute.."分"..leftSec.."秒"
		else
			timeStr = leftSec.."秒"
		end
		Xuanshang_Mission_Description_Text2:SetText("#{XFXS_201231_29}"..timeStr)
	end
	
	if nCurDay > endTiem or (nCurDay == endTiem and minuteTime >= 210000) then
		Xuanshang_Mission_Description_Text2:SetText("")
	end

end

function Xuanshang_Mission_GetUIDesc(missId)
	local retStr=""
	if missId == 10 or missId == 24 then
		local tq,taskType,uiDesc,accDesc,p1,p2,p3,p4,p5,p6,taskDesc,compDesc = ZhanTuanInterface:GetBountyTaskDesc(missId)
			
		local misIndex = DataPool:GetPlayerMissionIndexByID(XSM_MissionId)
		local itemid = DataPool:GetPlayerMission_Variable(missionIndex, 3)
		local itemCount = DataPool:GetPlayerMission_Variable(missionIndex, 4)
		local itemName = DataPool:Lua_GetItemNameByIndex(itemid)
		retStr = ScriptGlobal_Format(uiDesc,itemName, tostring(itemCount))
		return retStr
	end

end
