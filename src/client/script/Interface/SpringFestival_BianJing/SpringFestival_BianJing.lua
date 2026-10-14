-- 2020q4汴京氛围主界面

local g_Frame_UnifiedPosition

local g_BJFW_AnimateFlag={
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
}
local g_ListInfo_PageIndex = 0

local g_BJFW_ListCtrl1={}
local g_BJFW_ListCtrl2={}
local g_BJFW_ListCtrl3={}

local g_nAwardDate = -1

local g_nClueIdx = 1

local g_BJFW_ClueMF = {
	3041,        --汴京氛围线索1
	3042,        --汴京氛围线索2
	3043,        --汴京氛围线索3
	3044,        --汴京氛围线索4
	3045,        --汴京氛围线索5
	3046,        --汴京氛围线索6
	3047,        --汴京氛围线索7
	3048,        --汴京氛围线索8
	3049,        --汴京氛围线索9
	3050,        --汴京氛围线索10
	3051,        --汴京氛围线索11
	3052,        --汴京氛围线索12
	3053,        --汴京氛围线索13
	3054,        --汴京氛围线索14
	3055,        --汴京氛围线索15
	3056,        --汴京氛围线索16
}

--=========
-- PreLoad
--=========
function SpringFestival_BianJing_PreLoad()
	
--	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("BJFW_MAINWINDOW", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad
--=========
function SpringFestival_BianJing_OnLoad()

	g_Frame_UnifiedPosition = SpringFestival_BianJing_Frame:GetProperty("UnifiedPosition") 
	g_BJFW_ListCtrl1 = {
		{btn=SpringFestival_BianJing_Actor_1_HeroBK, infoimg=SpringFestival_BianJing_Actor_1Info,
			tipimg=SpringFestival_BianJing_Status1Tips, animate=SpringFestival_BianJing_Status1Anim, finishbtn=SpringFestival_BianJing_Actor_1_HeroBK_F},
		{btn=SpringFestival_BianJing_Actor_2_HeroBK, infoimg=SpringFestival_BianJing_Actor_2Info,
			tipimg=SpringFestival_BianJing_Status2Tips, animate=SpringFestival_BianJing_Status2Anim, finishbtn=SpringFestival_BianJing_Actor_2_HeroBK_F},
		{btn=SpringFestival_BianJing_Actor_3_HeroBK, infoimg=SpringFestival_BianJing_Actor_3Info,
			tipimg=SpringFestival_BianJing_Status3Tips, animate=SpringFestival_BianJing_Status3Anim, finishbtn=SpringFestival_BianJing_Actor_3_HeroBK_F},
		{btn=SpringFestival_BianJing_Actor_4_HeroBK, infoimg=SpringFestival_BianJing_Actor_4Info,
			tipimg=SpringFestival_BianJing_Status4Tips, animate=SpringFestival_BianJing_Status4Anim, finishbtn=SpringFestival_BianJing_Actor_4_HeroBK_F},
		{btn=SpringFestival_BianJing_Actor_5_HeroBK, infoimg=SpringFestival_BianJing_Actor_5Info,
			tipimg=SpringFestival_BianJing_Status5Tips, animate=SpringFestival_BianJing_Status5Anim, finishbtn=SpringFestival_BianJing_Actor_5_HeroBK_F},
		{btn=SpringFestival_BianJing_Actor_6_HeroBK, infoimg=SpringFestival_BianJing_Actor_6Info,
			tipimg=SpringFestival_BianJing_Status6Tips, animate=SpringFestival_BianJing_Status6Anim, finishbtn=SpringFestival_BianJing_Actor_6_HeroBK_F},
	}
	g_BJFW_ListCtrl2 = {
		{btn=SpringFestival_BianJing_Actor1_1_HeroBK, infoimg=SpringFestival_BianJing_Actor1_1Info,
			tipimg=SpringFestival_BianJing_StatusTips1_1, animate=SpringFestival_BianJing_StatusAnim1_1, finishbtn=SpringFestival_BianJing_Actor1_1_HeroBK_F},
		{btn=SpringFestival_BianJing_Actor1_2_HeroBK, infoimg=SpringFestival_BianJing_Actor1_2Info,
			tipimg=SpringFestival_BianJing_StatusTips1_2, animate=SpringFestival_BianJing_StatusAnim1_2, finishbtn=SpringFestival_BianJing_Actor1_2_HeroBK_F},
		{btn=SpringFestival_BianJing_Actor1_3_HeroBK, infoimg=SpringFestival_BianJing_Actor1_3Info,
			tipimg=SpringFestival_BianJing_StatusTips1_3, animate=SpringFestival_BianJing_StatusAnim1_3, finishbtn=SpringFestival_BianJing_Actor1_3_HeroBK_F},
		{btn=SpringFestival_BianJing_Actor1_4_HeroBK, infoimg=SpringFestival_BianJing_Actor1_4Info,
			tipimg=SpringFestival_BianJing_StatusTips1_4, animate=SpringFestival_BianJing_StatusAnim1_4, finishbtn=SpringFestival_BianJing_Actor1_4_HeroBK_F},
		{btn=SpringFestival_BianJing_Actor1_5_HeroBK, infoimg=SpringFestival_BianJing_Actor1_5Info,
			tipimg=SpringFestival_BianJing_StatusTips1_5, animate=SpringFestival_BianJing_StatusAnim1_5, finishbtn=SpringFestival_BianJing_Actor1_5_HeroBK_F},
		{btn=SpringFestival_BianJing_Actor1_6_HeroBK, infoimg=SpringFestival_BianJing_Actor1_6Info,
			tipimg=SpringFestival_BianJing_StatusTips1_6, animate=SpringFestival_BianJing_StatusAnim1_6, finishbtn=SpringFestival_BianJing_Actor1_6_HeroBK_F},
	}
	g_BJFW_ListCtrl3 = {
		{btn=SpringFestival_BianJing_Actor2_1_HeroBK, infoimg=SpringFestival_BianJing_Actor2_1Info,
			tipimg=SpringFestival_BianJing_StatusTips2_1, animate=SpringFestival_BianJing_StatusAnim2_1, finishbtn=SpringFestival_BianJing_Actor2_1_HeroBK_F},
		{btn=SpringFestival_BianJing_Actor2_2_HeroBK, infoimg=SpringFestival_BianJing_Actor2_2Info,
			tipimg=SpringFestival_BianJing_StatusTips2_2, animate=SpringFestival_BianJing_StatusAnim2_2, finishbtn=SpringFestival_BianJing_Actor2_2_HeroBK_F},
		{btn=SpringFestival_BianJing_Actor2_3_HeroBK, infoimg=SpringFestival_BianJing_Actor2_3Info,
			tipimg=SpringFestival_BianJing_StatusTips2_3, animate=SpringFestival_BianJing_StatusAnim2_3, finishbtn=SpringFestival_BianJing_Actor2_3_HeroBK_F},
		{btn=SpringFestival_BianJing_Actor2_4_HeroBK, infoimg=SpringFestival_BianJing_Actor2_4Info,
			tipimg=SpringFestival_BianJing_StatusTips2_4, animate=SpringFestival_BianJing_StatusAnim2_4, finishbtn=SpringFestival_BianJing_Actor2_4_HeroBK_F},

	}
	g_BJFW_AnimateFlag={
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	}
	for i=1,6 do
		g_BJFW_ListCtrl1[i].animate:Play(false)
	end
	for i=1,6 do
		g_BJFW_ListCtrl2[i].animate:Play(false)
	end
	for i=1,4 do
		g_BJFW_ListCtrl3[i].animate:Play(false)
	end
	g_nClueIdx = 1
end

--=========
-- OnEvent
--=========
function SpringFestival_BianJing_OnEvent(event)

	if event == "BJFW_MAINWINDOW" then
		local bOpenFlag=tonumber(arg0)
		if bOpenFlag==0 then
			--关闭
			SpringFestival_BianJing_Close()
			return
		elseif bOpenFlag==1 then
			--打开
			if tonumber(arg1)>0 and g_BJFW_AnimateFlag[tonumber(arg1)]~=nil then
				g_BJFW_AnimateFlag[tonumber(arg1)]=1
				g_nClueIdx = tonumber(arg1)
			end
			g_nAwardDate = tonumber(arg2)
			SpringFestival_BianJing_Update()
			this:Show()
		elseif bOpenFlag==2 then
			if tonumber(arg1)>0 and g_BJFW_AnimateFlag[tonumber(arg1)]~=nil then
				g_BJFW_AnimateFlag[tonumber(arg1)]=1
				g_nClueIdx = tonumber(arg1)
			end
			if (this:IsVisible()) then
				g_nAwardDate = tonumber(arg2)
				SpringFestival_BianJing_Update()
			end
			
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_BianJing_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		SpringFestival_BianJing_On_ResetPos()

	end

end

--=========
-- 重置
--=========
function SpringFestival_BianJing_On_ResetPos()

	SpringFestival_BianJing_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 打开
--=========
function SpringFestival_BianJing_Update()
	local nCurPage = math.floor((g_nClueIdx+5)/6)
	if nCurPage==1 then

		SpringFestival_BianJing_List:Show()
		SpringFestival_BianJing_List1:Hide()
		SpringFestival_BianJing_List2:Hide()
--		PushDebugMessage(g_BJFW_AnimateFlag[1].." "..g_BJFW_AnimateFlag[2].." "..g_BJFW_AnimateFlag[3].." "..g_BJFW_AnimateFlag[4].." "..g_BJFW_AnimateFlag[5].." "..g_BJFW_AnimateFlag[6].." "..g_BJFW_AnimateFlag[7].." "..g_BJFW_AnimateFlag[8].." "..g_BJFW_AnimateFlag[9].." "..g_BJFW_AnimateFlag[10].." "..g_BJFW_AnimateFlag[11].." "..g_BJFW_AnimateFlag[12].." "..g_BJFW_AnimateFlag[13].." "..g_BJFW_AnimateFlag[14].." "..g_BJFW_AnimateFlag[15].." "..g_BJFW_AnimateFlag[16])
		--每页6个
		local IndexBegin=6*(nCurPage-1)
		for i=1,6 do
			if Pneuma:GetMF(g_BJFW_ClueMF[IndexBegin+i]) == 0 then
				--未完成
				g_BJFW_ListCtrl1[i].tipimg:Hide()
				g_BJFW_ListCtrl1[i].btn:Show()
				g_BJFW_ListCtrl1[i].finishbtn:Hide()
			else
				if g_BJFW_AnimateFlag[IndexBegin+i]==0 then
					--已完成
					g_BJFW_ListCtrl1[i].tipimg:Show()
					g_BJFW_ListCtrl1[i].btn:Hide()
					g_BJFW_ListCtrl1[i].finishbtn:Show()
				else
					--未完成
					g_BJFW_ListCtrl1[i].tipimg:Hide()
					g_BJFW_ListCtrl1[i].btn:Show()
					g_BJFW_ListCtrl1[i].finishbtn:Hide()
				end
			end
			if g_BJFW_AnimateFlag[IndexBegin+i]==1 then
				g_BJFW_ListCtrl1[i].animate:Play(true)
				SetTimer("SpringFestival_BianJing","SpringFestival_BianJing_Animate_Close()", 750)
				g_BJFW_AnimateFlag[IndexBegin+i] = 0
			end
		end
	elseif nCurPage==2 then
		SpringFestival_BianJing_List:Hide()
		SpringFestival_BianJing_List1:Show()
		SpringFestival_BianJing_List2:Hide()
--		PushDebugMessage(g_BJFW_AnimateFlag[1].." "..g_BJFW_AnimateFlag[2].." "..g_BJFW_AnimateFlag[3].." "..g_BJFW_AnimateFlag[4].." "..g_BJFW_AnimateFlag[5].." "..g_BJFW_AnimateFlag[6].." "..g_BJFW_AnimateFlag[7].." "..g_BJFW_AnimateFlag[8].." "..g_BJFW_AnimateFlag[9].." "..g_BJFW_AnimateFlag[10].." "..g_BJFW_AnimateFlag[11].." "..g_BJFW_AnimateFlag[12].." "..g_BJFW_AnimateFlag[13].." "..g_BJFW_AnimateFlag[14].." "..g_BJFW_AnimateFlag[15].." "..g_BJFW_AnimateFlag[16])
		--每页6个
		local IndexBegin=6*(nCurPage-1)
		for i=1,6 do
			if Pneuma:GetMF(g_BJFW_ClueMF[IndexBegin+i]) == 0 then
				--未完成
				g_BJFW_ListCtrl2[i].tipimg:Hide()
				g_BJFW_ListCtrl2[i].btn:Show()
				g_BJFW_ListCtrl2[i].finishbtn:Hide()
			else
				if g_BJFW_AnimateFlag[IndexBegin+i]==0 then
					--已完成
					g_BJFW_ListCtrl2[i].tipimg:Show()
					g_BJFW_ListCtrl2[i].btn:Hide()
					g_BJFW_ListCtrl2[i].finishbtn:Show()
				else
					--未完成
					g_BJFW_ListCtrl2[i].tipimg:Hide()
					g_BJFW_ListCtrl2[i].btn:Show()
					g_BJFW_ListCtrl2[i].finishbtn:Hide()
				end
			end
			if g_BJFW_AnimateFlag[IndexBegin+i]==1 then
				g_BJFW_ListCtrl2[i].animate:Play(true)
				SetTimer("SpringFestival_BianJing","SpringFestival_BianJing_Animate_Close()", 750)
				g_BJFW_AnimateFlag[IndexBegin+i] = 0
			end
		end
	else
		--剩余4个
		SpringFestival_BianJing_List:Hide()
		SpringFestival_BianJing_List1:Hide()
		SpringFestival_BianJing_List2:Show()
		local IndexBegin=6*(nCurPage-1)
		for i=1,4 do
			if Pneuma:GetMF(g_BJFW_ClueMF[IndexBegin+i]) == 0 then
				--未完成
				g_BJFW_ListCtrl3[i].tipimg:Hide()
				g_BJFW_ListCtrl3[i].btn:Show()
				g_BJFW_ListCtrl3[i].finishbtn:Hide()
			else
				--已完成
				if g_BJFW_AnimateFlag[IndexBegin+i]==0 then
					--已完成
					g_BJFW_ListCtrl3[i].tipimg:Show()
					g_BJFW_ListCtrl3[i].btn:Hide()
					g_BJFW_ListCtrl3[i].finishbtn:Show()
				else
					--未完成
					g_BJFW_ListCtrl3[i].tipimg:Hide()
					g_BJFW_ListCtrl3[i].btn:Show()
					g_BJFW_ListCtrl3[i].finishbtn:Hide()
				end
			end
			if g_BJFW_AnimateFlag[IndexBegin+i]==1 then
				g_BJFW_ListCtrl3[i].animate:Play(true)
				SetTimer("SpringFestival_BianJing","SpringFestival_BianJing_Animate_Close()", 750)
				g_BJFW_AnimateFlag[IndexBegin+i] = 0
			end
		end
	end
	-- 线索
	local nClueCount = 0
	for i=1,16 do
		if Pneuma:GetMF(g_BJFW_ClueMF[i]) == 1 then
			nClueCount = nClueCount+1
		end
	end
	local clueMsg = ScriptGlobal_Format("#{BJFW_210105_09}", nClueCount)
	SpringFestival_BianJing_TotalJindu_Text:SetText(clueMsg)
	--奖励贴图
--	local theAction = DataPool:CreateActionItemForShow(39920503, 1)
--	if theAction:GetID() ~= 0 then
--		SpringFestival_BianJing_JiangLi:SetActionItem(theAction:GetID());
--	end
	local bRewardFlag = math.mod(g_nAwardDate,10)
	if bRewardFlag==0 then
		SpringFestival_BianJing_FourChoices_GetButton:Show()--领取按钮
		SpringFestival_BianJing_Actor_BasicItemReceived:Hide()--已领取
		if nClueCount>=14 then
			SpringFestival_BianJing_Actor_GetButton_RedDot:Show()
		else
			SpringFestival_BianJing_Actor_GetButton_RedDot:Hide()
		end
	else
		SpringFestival_BianJing_FourChoices_GetButton:Hide()--领取按钮
		SpringFestival_BianJing_Actor_BasicItemReceived:Show()--已领取
		SpringFestival_BianJing_Actor_GetButton_RedDot:Hide()
	end
	-- 显示
	this:Show()
	
end

--=========
-- 关闭
--=========
function SpringFestival_BianJing_Close()

	SpringFestival_BianJing_OnHiden()
	this:Hide()
	
end

--=========
-- 隐藏
--=========
function SpringFestival_BianJing_OnHiden()

end

--=========
-- 确定
--=========
function SpringFestival_BianJing_Clicked()
	
end

function SpringFestival_BianJing_HelpClicked()
	PushEvent("QUEST_HELP_MSG","#{BJFW_210105_06}")
end

function SpringFestival_BianJing_Choose_Clicked(nIndex)
	local nCurPage = math.floor((g_nClueIdx+5)/6)
	local nSelectIndex=(nCurPage-1)*6+nIndex
	PushEvent("BJFW_CLUEUI",nSelectIndex)
end

function SpringFestival_BianJing_PrePage_Clicked()
	local nCurPage = math.floor((g_nClueIdx+5)/6)
	--page1:1-6 page2:7-12 page3:13-16
	if nCurPage==2 then
		g_nClueIdx=1
		KillTimer("SpringFestival_BianJing_Animate_Close()")
		SpringFestival_BianJing_AnimatePlayFalse()
		SpringFestival_BianJing_Update()
	elseif nCurPage==3 then
		g_nClueIdx=7
		KillTimer("SpringFestival_BianJing_Animate_Close()")
		SpringFestival_BianJing_AnimatePlayFalse()
		SpringFestival_BianJing_Update()
	end
end

function SpringFestival_BianJing_NextPage_Clicked()
	local nCurPage = math.floor((g_nClueIdx+5)/6)
	--page1:1-6 page2:7-12 page3:13-16
	if nCurPage==1 then
		g_nClueIdx=7
		KillTimer("SpringFestival_BianJing_Animate_Close()")
		SpringFestival_BianJing_AnimatePlayFalse()
		SpringFestival_BianJing_Update()
	elseif nCurPage==2 then
		g_nClueIdx=13
		KillTimer("SpringFestival_BianJing_Animate_Close()")
		SpringFestival_BianJing_AnimatePlayFalse()
		SpringFestival_BianJing_Update()
	end

end
function SpringFestival_BianJing_OnCloseClick()

	this:Hide()
end
function SpringFestival_BianJing_OnHidden()

end

function SpringFestival_BianJing_GetAwardClicked()
	Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("OnGetBJFWAward")
    Set_XSCRIPT_ScriptID(806030)
--    Set_XSCRIPT_Parameter(0, 1)
    Set_XSCRIPT_ParamCount(0)
   Send_XSCRIPT()
end
function SpringFestival_BianJing_AnimatePlayFalse()
	local nCurPage = math.floor((g_nClueIdx+5)/6)
	if nCurPage==1 then
		for i=1,6 do
			g_BJFW_ListCtrl1[i].animate:Play(false)
		end
	elseif nCurPage==2 then
		for i=1,6 do
			g_BJFW_ListCtrl2[i].animate:Play(false)
		end
	else
		for i=1,4 do
			g_BJFW_ListCtrl3[i].animate:Play(false)
		end
	end
end

function SpringFestival_BianJing_Animate_Close()
--PushDebugMessage("Kill SpringFestival_BianJing_Animate_Close")
	KillTimer("SpringFestival_BianJing_Animate_Close()")
	SpringFestival_BianJing_AnimatePlayFalse()
	
	local nCurPage = math.floor((g_nClueIdx+5)/6)
	local IndexBegin=6*(nCurPage-1)

	if nCurPage==1 then
		for nIndex=1,6 do
			if Pneuma:GetMF(g_BJFW_ClueMF[IndexBegin+nIndex]) == 0 then
				--未完成
				g_BJFW_ListCtrl1[nIndex].tipimg:Hide()
				g_BJFW_ListCtrl1[nIndex].btn:Show()
				g_BJFW_ListCtrl1[nIndex].finishbtn:Hide()
			else
				--已完成
				g_BJFW_ListCtrl1[nIndex].tipimg:Show()
				g_BJFW_ListCtrl1[nIndex].btn:Hide()
				g_BJFW_ListCtrl1[nIndex].finishbtn:Show()
			end
		end
	elseif nCurPage==2 then
		for nIndex=1,6 do
			if Pneuma:GetMF(g_BJFW_ClueMF[IndexBegin+nIndex]) == 0 then
				--未完成
				g_BJFW_ListCtrl2[nIndex].tipimg:Hide()
				g_BJFW_ListCtrl2[nIndex].btn:Show()
				g_BJFW_ListCtrl2[nIndex].finishbtn:Hide()
			else
				--已完成
				g_BJFW_ListCtrl2[nIndex].tipimg:Show()
				g_BJFW_ListCtrl2[nIndex].btn:Hide()
				g_BJFW_ListCtrl2[nIndex].finishbtn:Show()
			end
		end
	else
		for nIndex=1,4 do
			if Pneuma:GetMF(g_BJFW_ClueMF[IndexBegin+nIndex]) == 0 then
				--未完成
				g_BJFW_ListCtrl3[nIndex].tipimg:Hide()
				g_BJFW_ListCtrl3[nIndex].btn:Show()
				g_BJFW_ListCtrl3[nIndex].finishbtn:Hide()
			else
				--已完成
				g_BJFW_ListCtrl3[nIndex].tipimg:Show()--SetProperty("Image", "set:T3WarmUp_Guide3 image:T3WarmUp_Finished" )
				g_BJFW_ListCtrl3[nIndex].btn:Hide()
				g_BJFW_ListCtrl3[nIndex].finishbtn:Show()
			end
		end
	end
end
function SpringFestival_BianJing_StatusAnimEnd(nIndex)
end
