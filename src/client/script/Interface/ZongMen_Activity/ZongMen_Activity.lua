--ZongMen_Activity
local g_ZongMen_Activity_UnifiedPosition;

local ZongMen_Activity_Button= {}
local ZongMen_Activity_Text= {}
local ZongMen_Activity_Reward_Btn = {}
local ZongMen_Activity_Reward_Tip = {}
local ZongMen_Activity_Reward_Finish = {}
local ZongMen_Activity_Reward_Text = {}

local g_TodayOnlineTime = 0
local g_mymission = 0
local g_isBaiFang = 0
local g_getrewardflag = {0,0}
local g_todaycount = 0
local g_totalcount = 0
local g_rewarddata = 0

local g_NPCNameText = {
	[1] = "#{ZMHD_230801_28}",
	[2] = "#{ZMHD_230801_29}",
	[3] = "#{ZMHD_230801_30}",
	[4] = "#{ZMHD_230801_31}",
	[5] = "#{ZMHD_230801_32}",
	[6] = "#{ZMHD_230801_33}",
	[7] = "#{ZMHD_230801_34}",
	[8] = "#{ZMHD_230801_35}",
	[9] = "#{ZMHD_230801_36}",
	[10] = "#{ZMHD_230801_37}",
	[11] = "#{ZMHD_230801_38}",
	[12] = "#{ZMHD_230801_39}",
	[13] = "#{ZMHD_230801_40}",
	[14] = "#{ZMHD_230801_41}",
	[15] = "#{ZMHD_250826_01}",
}

local g_NPCPosText = {
	[1] = "#{ZMHD_230801_106}",
	[2] = "#{ZMHD_230801_107}",
	[3] = "#{ZMHD_230801_108}",
	[4] = "#{ZMHD_230801_109}",
	[5] = "#{ZMHD_230801_110}",
	[6] = "#{ZMHD_230801_111}",
	[7] = "#{ZMHD_230801_112}",
	[8] = "#{ZMHD_230801_113}",
	[9] = "#{ZMHD_230801_114}",
	[10] = "#{ZMHD_230801_115}",
	[11] = "#{ZMHD_230801_116}",
	[12] = "#{ZMHD_230801_117}",
	[13] = "#{ZMHD_230801_118}",
	[14] = "#{ZMHD_230801_119}",
	[15] = "#{ZMHD_250826_02}",
}

local g_LijiTijiao = {1,3,5,7,10}

function ZongMen_Activity_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("TODAY_ACTIVE_POINT",false)

end

function ZongMen_Activity_OnLoad()

	ZongMen_Activity_Button[1] = ZongMen_Activity_Button1
	--ZongMen_Activity_Button[2] = ZongMen_Activity_Button2
	ZongMen_Activity_Button[2] = ZongMen_Activity_Button3
	
	ZongMen_Activity_Text[1] = ZongMen_Activity_Lace1_Text
	--ZongMen_Activity_Text[2] = ZongMen_Activity_Lace2_Text
	ZongMen_Activity_Text[2] = ZongMen_Activity_Lace3_Text
	
	ZongMen_Activity_Reward_Btn[1] = ZongMen_Activity_Reward1Btn
	ZongMen_Activity_Reward_Btn[2] = ZongMen_Activity_Reward2Btn
	ZongMen_Activity_Reward_Btn[3] = ZongMen_Activity_Reward3Btn
	ZongMen_Activity_Reward_Btn[4] = ZongMen_Activity_Reward4Btn
	ZongMen_Activity_Reward_Btn[5] = ZongMen_Activity_Reward5Btn
	
	ZongMen_Activity_Reward_Tip[1] = ZongMen_Activity_Reward1_tips
	ZongMen_Activity_Reward_Tip[2] = ZongMen_Activity_Reward2_tips
	ZongMen_Activity_Reward_Tip[3] = ZongMen_Activity_Reward3_tips
	ZongMen_Activity_Reward_Tip[4] = ZongMen_Activity_Reward4_tips
	ZongMen_Activity_Reward_Tip[5] = ZongMen_Activity_Reward5_tips
	
	ZongMen_Activity_Reward_Finish[1] = ZongMen_Activity_Reward1BtnOK
	ZongMen_Activity_Reward_Finish[2] = ZongMen_Activity_Reward2BtnOK
	ZongMen_Activity_Reward_Finish[3] = ZongMen_Activity_Reward3BtnOK
	ZongMen_Activity_Reward_Finish[4] = ZongMen_Activity_Reward4BtnOK
	ZongMen_Activity_Reward_Finish[5] = ZongMen_Activity_Reward5BtnOK
	
	ZongMen_Activity_Reward_Text[1] = ZongMen_Activity_Reward1Text
	ZongMen_Activity_Reward_Text[2] = ZongMen_Activity_Reward2Text
	ZongMen_Activity_Reward_Text[3] = ZongMen_Activity_Reward3Text
	ZongMen_Activity_Reward_Text[4] = ZongMen_Activity_Reward4Text
	ZongMen_Activity_Reward_Text[5] = ZongMen_Activity_Reward5Text
	
	g_ZongMen_Activity_UnifiedPosition = ZongMen_Activity_Frame:GetProperty("UnifiedPosition")
	
end

function ZongMen_Activity_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99883001 ) then
		
		ZongMen_Activity_Reset()
		local operator = Get_XParam_INT(0)
			
		--g_TodayOnlineTime = Get_XParam_INT(1)
		g_mymission = Get_XParam_INT(1)
		g_isBaiFang = Get_XParam_INT(2)
		for i = 1, 2 do
			g_getrewardflag[i] = Get_XParam_INT(2+i)
		end
		g_todaycount = Get_XParam_INT(5)
		g_totalcount = Get_XParam_INT(6)
		g_rewarddata = Get_XParam_INT(7)
		
		if operator == 1 then
			ZongMen_Activity_Update()
		elseif operator == 2 and this:IsVisible() then
			ZongMen_Activity_Update()		
		end

	elseif (event == "ADJEST_UI_POS" ) then
		ZongMen_Activity_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ZongMen_Activity_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif ( event == "TODAY_ACTIVE_POINT" ) then
		ZongMen_Activity_Update() 
	end

end
--=========================================================
--reset
--=========================================================
function ZongMen_Activity_Reset()
	--g_TodayOnlineTime= 0
	g_mymission = 0
	g_isBaiFang = 0
	for i = 1, 2 do
		g_getrewardflag[i] = 0
	end
	g_todaycount = 0
	g_totalcount = 0
end
--=========================================================
--更新界面
--=========================================================
function ZongMen_Activity_Update()
	
	--任务一
	if g_mymission >= 1 and g_mymission <= 15 then
		ZongMen_Activity_Lace1_Title:SetText(ScriptGlobal_Format("#{ZMHD_230801_27}",g_NPCNameText[g_mymission]))
	end
	ZongMen_Activity_Button1_tips:Hide()
	if g_isBaiFang == 1 then
		ZongMen_Activity_Lace1_Text:SetText("#{ZMHD_230801_46}")
		if g_getrewardflag[1] == 0 then
			ZongMen_Activity_Button1_tips:Show()
		end
		ZongMen_Activity_Mission1_UnfinshTips:Hide()
		ZongMen_Activity_Mission1_FinshTips:Show()
	else
		if g_mymission >= 1 and g_mymission <= 15 then
			ZongMen_Activity_Lace1_Text:SetText(g_NPCPosText[g_mymission])
		end
		ZongMen_Activity_Mission1_UnfinshTips:Show()
		ZongMen_Activity_Mission1_FinshTips:Hide()
	end
	
	--任务二
	--ZongMen_Activity_Button2_tips:Hide()
	--if g_TodayOnlineTime >= 60 then
	--	ZongMen_Activity_Lace2_Text:SetText("#{ZMHD_230801_49}")
	--	if g_getrewardflag[2] == 0 then
	--		ZongMen_Activity_Button2_tips:Show()
	--	end
	--else
	--	ZongMen_Activity_Lace2_Text:SetText(ScriptGlobal_Format("#{ZMHD_230801_47}",tostring(g_TodayOnlineTime)))
	--end
	
	--任务三
	ZongMen_Activity_Button3_tips:Hide()
	local nTodayPoint = Player:GetData("TODAYACTIVEPOINT")
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(138) > 0 then  --卡级
		ZongMen_Activity_Lace3_Title:SetText("#{ZMHD_230801_44}")
		if nTodayPoint >= 150 then
			ZongMen_Activity_Lace3_Text:SetText("#{ZMHD_230801_51}")
			if g_getrewardflag[2] == 0 then
				ZongMen_Activity_Button3_tips:Show()
			end
			ZongMen_Activity_Mission2_UnfinshTips:Hide()
			ZongMen_Activity_Mission2_FinshTips:Show()
		else
			ZongMen_Activity_Lace3_Text:SetText(ScriptGlobal_Format("#{ZMHD_230801_50}",nTodayPoint))
			ZongMen_Activity_Mission2_UnfinshTips:Show()
			ZongMen_Activity_Mission2_FinshTips:Hide()
		end
	else
		ZongMen_Activity_Lace3_Title:SetText("#{ZMHD_230801_43}")
		if nTodayPoint >= 450 then
			ZongMen_Activity_Lace3_Text:SetText("#{ZMHD_230801_51}")
			if g_getrewardflag[2] == 0 then
				ZongMen_Activity_Button3_tips:Show()
			end
			ZongMen_Activity_Mission2_UnfinshTips:Hide()
			ZongMen_Activity_Mission2_FinshTips:Show()
		else
			ZongMen_Activity_Lace3_Text:SetText(ScriptGlobal_Format("#{ZMHD_230801_50}",nTodayPoint))
			ZongMen_Activity_Mission2_UnfinshTips:Show()
			ZongMen_Activity_Mission2_FinshTips:Hide()
		end
	end
	
	for i =1, 2 do
		if g_getrewardflag[i] == 1 then
			ZongMen_Activity_Button[i]:Disable()
			ZongMen_Activity_Text[i]:SetText("#{ZMHD_230801_93}")
		else
			ZongMen_Activity_Button[i]:Enable()
		end
	end

	-------累计奖励
	ZongMen_Activity_RewardText:SetText(ScriptGlobal_Format("#{ZMHD_230801_61}",g_totalcount))
	
	for i = 1, table.getn(g_LijiTijiao) do
		ZongMen_Activity_Reward_Text[i]:SetText(ScriptGlobal_Format("#{ZMHD_230801_92}",g_LijiTijiao[i]))
		local rewardflag =  DataPool:Lua_GetBinaryData(g_rewarddata, i-1 );
		if rewardflag == 1 then --已领取
			ZongMen_Activity_Reward_Btn[i]:Disable()
			ZongMen_Activity_Reward_Finish[i]:Show()
			ZongMen_Activity_Reward_Tip[i]:Hide()
		else
			ZongMen_Activity_Reward_Btn[i]:Enable()
			ZongMen_Activity_Reward_Finish[i]:Hide()
			if g_totalcount >= g_LijiTijiao[i] then
				ZongMen_Activity_Reward_Tip[i]:Show()
			else
				ZongMen_Activity_Reward_Tip[i]:Hide()
			end
		end
		
	end
	this:Show()
end


--========================================================
--关闭
--=========================================================
function ZongMen_Activity_Close()
	ZongMen_Activity_Reset()
	this:Hide()
end

function ZongMen_Activity_OnHiden()
	ZongMen_Activity_Close()
end
--=========================================================
--刷新位置
--=========================================================
function ZongMen_Activity_On_ResetPos()
	ZongMen_Activity_Frame:SetProperty("UnifiedPosition", g_ZongMen_Activity_UnifiedPosition);
end


function ZongMen_Activity_Help()
	PushEvent("CCSHOP_HELP", 200)
end

function ZongMen_Activity_OnClick(nIndex)
	if nIndex < 1 or nIndex > 2 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 998830 )
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()		
end

function ZongMen_Activity_GetReward(nIndex)
	if nIndex < 1 or nIndex > 5 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetTijiaoPrize" )
		Set_XSCRIPT_ScriptID( 998831 )
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()		
end

function ZongMen_Activity_AutoGo()
	local bRet = AutoRuntoTargetExWithName(268, 269, 0, "扫地僧")
	if 0 == bRet then
		PushDebugMessage("无法自动寻路")
		return
	end
	--PushDebugMessage("#{ZMHD_230801_121}")	
end