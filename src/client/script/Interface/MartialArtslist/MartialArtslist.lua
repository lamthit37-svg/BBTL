--******************************
--比武招亲榜
--******************************

local g_nObjID = -1
local g_arrCtrl_Order ={}
local g_arrCtrl_Name ={}
local g_arrCtrl_Level ={}
local g_arrCtrl_MenPai ={}
local g_arrCtrl_Guild ={}
local g_arrCtrl_Equiphh ={}
local g_arrCtrl_Button={}
local g_arrCtrl_BK={}
local g_arrCtrl_Time={}
local g_arrDataRow={
[0]=-1,
[1]=-1,
[2]=-1,
[3]=-1,
[4]=-1,
}

local g_MenPaiNameList =
{
	[0]  ="#{XQ_MP_1}",
	[1]  ="#{XQ_MP_2}",
	[2]  ="#{XQ_MP_3}",
	[3]  ="#{XQ_MP_4}",
	[4]  ="#{XQ_MP_5}",
	[5]  ="#{XQ_MP_6}",
	[6]  ="#{XQ_MP_7}",
	[7]  ="#{XQ_MP_8}",
	[8]  ="#{XQ_MP_9}",
	[9]  ="#{BWZQ_160623_102}",--无
	[10] ="#{XQ_MP_10}",
	[11] ="#{XQ_MP_13}",
	[12] ="#{XQ_MP_14}",--鬼谷
	[13] ="#{XQ_MP_15}",--桃花岛
	[14] ="#{XMPHM_210604_01}",
	[15] ="#{GMGameInterface_Script_DataPool_Info_ERenGu}",--menpai15 mptodo
}

local g_MartialArtslist_Frame_UnifiedPosition

function MartialArtslist_PreLoad()
	 this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OPEN_COMPEMARRY_WINDOW")
end

function MartialArtslist_OnLoad()
	g_arrCtrl_Order ={
	[0]=MartialArtslist_Bk1_Order,
	[1]=MartialArtslist_Bk2_Order,
	[2]=MartialArtslist_Bk3_Order,
	[3]=MartialArtslist_Bk4_Order,
	[4]=MartialArtslist_Bk5_Order
	}
	g_arrCtrl_Name ={
	[0]=MartialArtslist_Bk1_Name,
	[1]=MartialArtslist_Bk2_Name,
	[2]=MartialArtslist_Bk3_Name,
	[3]=MartialArtslist_Bk4_Name,
	[4]=MartialArtslist_Bk5_Name
	}
	g_arrCtrl_Level ={
	[0]=MartialArtslist_Bk1_Level,
	[1]=MartialArtslist_Bk2_Level,
	[2]=MartialArtslist_Bk3_Level,
	[3]=MartialArtslist_Bk4_Level,
	[4]=MartialArtslist_Bk5_Level
	}
	g_arrCtrl_MenPai ={
	[0]=MartialArtslist_Bk1_United,
	[1]=MartialArtslist_Bk2_United,
	[2]=MartialArtslist_Bk3_United,
	[3]=MartialArtslist_Bk4_United,
	[4]=MartialArtslist_Bk5_United
	}
	g_arrCtrl_Guild ={
	[0]=MartialArtslist_Bk1_Gang,
	[1]=MartialArtslist_Bk2_Gang,
	[2]=MartialArtslist_Bk3_Gang,
	[3]=MartialArtslist_Bk4_Gang,
	[4]=MartialArtslist_Bk5_Gang
	}
	g_arrCtrl_Time={
	[0]=MartialArtslist_Bk1_Time,
	[1]=MartialArtslist_Bk2_Time,
	[2]=MartialArtslist_Bk3_Time,
	[3]=MartialArtslist_Bk4_Time,
	[4]=MartialArtslist_Bk5_Time,
	}
	g_arrCtrl_Equiphh ={
	[0]=MartialArtslist_Bk1_Score,
	[1]=MartialArtslist_Bk2_Score,
	[2]=MartialArtslist_Bk3_Score,
	[3]=MartialArtslist_Bk4_Score,
	[4]=MartialArtslist_Bk5_Score
	}
	g_arrCtrl_Button={
	[0]=MartialArtslist_Bk1_Button,
	[1]=MartialArtslist_Bk2_Button,
	[2]=MartialArtslist_Bk3_Button,
	[3]=MartialArtslist_Bk4_Button,
	[4]=MartialArtslist_Bk5_Button
	}
	g_arrCtrl_BK={
	[0]=MartialArtslist_Bk1,
	[1]=MartialArtslist_Bk2,
	[2]=MartialArtslist_Bk3,
	[3]=MartialArtslist_Bk4,
	[4]=MartialArtslist_Bk5,
	}

	g_MartialArtslist_Frame_UnifiedPosition=MartialArtslist_Frame:GetProperty("UnifiedPosition");
end

function MartialArtslist_OnEvent(event)
	if event == "UI_COMMAND" then
    if tonumber(arg0) ~= 5090820 then
        return
    end
		local targetId=Get_XParam_INT(0)
    g_nObjID = Target:GetServerId2ClientId(targetId)
    if not g_nObjID or g_nObjID < 0 then
        return
    end
		this:CareObject(g_nObjID, 1)
		this:Show()

	elseif event == "OPEN_COMPEMARRY_WINDOW" then
		if not this:IsVisible() then
			return
		end
    MartialArtslist_CleanUp()
    MartialArtslist_Update()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		MartialArtslist_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		MartialArtslist_ResetPos()
	end
end

function MartialArtslist_ResetPos()
	MartialArtslist_Frame:SetProperty("UnifiedPosition", g_MartialArtslist_Frame_UnifiedPosition);
end

--cleanup
function MartialArtslist_CleanUp()
	for i=0,4 do
		g_arrDataRow[i]=-1
	end
end

function MartialArtslist_Update()
	local ExplainText="#{BWZQ_160623_34}"
	local tipMsg=""
	local nOrder=0
	for i = 0, 4 do
	    local szName, nLevel, nMenPai, szGuildName, nEquipHH, nTime = BWDH:GetCompeMarrySponsorInfo(i)
	    if szName~=nil and szName ~= "" then
	    	g_arrCtrl_BK[i]:Show()
	    	g_arrDataRow[i]=i
	    	g_arrCtrl_Order[nOrder]:SetText(nOrder+1)
	    	g_arrCtrl_Name[nOrder]:SetText(szName)
	    	g_arrCtrl_Level[nOrder]:SetText(nLevel)
	    	g_arrCtrl_MenPai[nOrder]:SetText(g_MenPaiNameList[nMenPai])
	    	if szGuildName=="" then
	    		g_arrCtrl_Guild[nOrder]:SetText("#{BWZQ_160623_102}")
	    	else
	    		g_arrCtrl_Guild[nOrder]:SetText(szGuildName)
	    	end
	    	g_arrCtrl_Time[nOrder]:SetText(nTime)
	    	g_arrCtrl_Equiphh[nOrder]:SetText(nEquipHH)
	    	tipMsg=ScriptGlobal_Format("#{BWZQ_160623_42}",szName)
	    	g_arrCtrl_Button[nOrder]:SetToolTip(tipMsg)
	    	if nOrder==0 then
	    		ExplainText=ExplainText..szName
	    	else
	    		ExplainText=ExplainText.."#{BWZQ_160623_211}"..szName
	    	end
	    	nOrder=nOrder+1
	    end
	end
	ExplainText=ExplainText.."#{BWZQ_160623_212}"..nOrder.."#{BWZQ_160623_6}"
	MartialArtslist_Explain:SetText(ExplainText)
	for j=nOrder,4 do
		g_arrCtrl_BK[j]:Hide()
	end
end

function MartialArtslist_GetScnIdx(nIdx)
	local cnt=-1
	for i=0,4 do
		if g_arrDataRow[i]>=0 then
			cnt=cnt+1
		end
		if cnt==nIdx then
			return i
		end
	end
	return -1
end

function MartialArtslist_GoClicked(nIdx)
	local myIdx=MartialArtslist_GetScnIdx(nIdx)
	if myIdx == -1 then
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ParticipateGoScn");
		Set_XSCRIPT_ScriptID(509082);
		Set_XSCRIPT_Parameter(0, myIdx)
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
end

function MartialArtslist_OnClosed()
	this:Hide()
end
