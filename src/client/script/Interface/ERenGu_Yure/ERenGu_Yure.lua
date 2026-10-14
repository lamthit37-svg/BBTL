--!!!reloadscript =ERenGu_Yure

local g_ERenGu_Yure_Frame_UnifiedPosition = ""
local g_UICOMMAND = 99939101
local g_CloseCaseUICOMMAND = 99939102
local g_MissionScrpitID = 999380
local g_ClueClickBackup    = -1 
local g_CurQuestPhrase   = -1
local g_CurActivityPhrase = -1
local g_IsHaveMissionState = -1
local g_IsMissionComplete = -1
local g_ChosenNpcData = 0
local g_CurClurPage 	= -1
local g_IsIntergtation  = 0
local g_IsCloseCase     = 0	--任务是否进行到查案第四期的断案部分
local g_CloseCasePhase	= 0 --查案四期时的动画index
local g_CluePageContent = {}
local g_ClueIntergrations = {}
local g_CloseCase_Component = {}
local g_IntergrationLock = {}
local g_Clue = {}
local g_ClueTips = {}
local g_CluePaging = {}
local g_CluePageTips = {}
local g_Client = {}
local g_Client1_Info = {}
local g_Client_Finished_ArtComponent = {}
function ERenGu_Yure_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	
	this:RegisterEvent("OPEN_FASHION_LOTTERY")
	this:RegisterEvent("REFRESH_FASHION_LOTTERY")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function ERenGu_Yure_OnLoad()
	g_ERenGu_Yure_Frame_UnifiedPosition = ERenGu_Yure_Frame:GetProperty("UnifiedPosition")
	g_CluePageContent = {
		[1] = { Getclues = {"#{ERYR_240701_41}","#{ERYR_240701_42}","#{ERYR_240701_43}","#{ERYR_240701_44}","#{ERYR_240701_45}","#{ERYR_240701_46}"}, 
				UnknownClue = "#{ERYR_240701_313}"},
		[2] = { Getclues = {"#{ERYR_240701_47}","#{ERYR_240701_48}","#{ERYR_240701_49}","#{ERYR_240701_50}","#{ERYR_240701_51}","#{ERYR_240701_52}"}, 
				UnknownClue = "#{ERYR_240701_313}"},
		--[3] = { Getclues = {"#{ERYR_240701_53}","#{ERYR_240701_54}","#{ERYR_240701_55}","#{ERYR_240701_56}","#{ERYR_240701_57}","#{ERYR_240701_58}"}, 
		--		UnknownClue = "#{ERYR_240701_313}"},
		[3] = { Getclues = {"#{ERYR_240701_59}","#{ERYR_240701_60}","#{ERYR_240701_61}","#{ERYR_240701_62}","#{ERYR_240701_63}","#{ERYR_240701_64}"}, 
				UnknownClue = "#{ERYR_240701_313}"},
	}
	g_ClueIntergrations = {
		Flag = {0,0,0},
		Component = {
			ERenGu_Yure_Client2_Clue_AnswerText1,
			ERenGu_Yure_Client2_Clue_AnswerText2,
			ERenGu_Yure_Client2_Clue_AnswerText3,
		},
		Content = {	--一共六条线索，两两对应以下三种线索内容，根据六条线索的下标直接查找此处下标，即整合内容1为线索2和6，则在index=2/6位置放置对应的字符
			[1] = { "#{ERYR_240701_70}","#{ERYR_240701_69}","#{ERYR_240701_71}","#{ERYR_240701_70}","#{ERYR_240701_69}","#{ERYR_240701_71}" },
			[2] = { "#{ERYR_240701_73}","#{ERYR_240701_74}","#{ERYR_240701_72}","#{ERYR_240701_74}","#{ERYR_240701_72}","#{ERYR_240701_73}" },
			--[3] = { "#{ERYR_240701_77}","#{ERYR_240701_76}","#{ERYR_240701_77}","#{ERYR_240701_75}","#{ERYR_240701_76}","#{ERYR_240701_75}" },
			[3] = { "#{ERYR_240701_80}","#{ERYR_240701_78}","#{ERYR_240701_80}","#{ERYR_240701_79}","#{ERYR_240701_78}","#{ERYR_240701_79}" },
		}
	}
	g_CloseCase_Component = {
		EvidenceText_Component = {
			ERenGu_Yure_Client2_CluePage_CloseCase_EvidenceText1,
			ERenGu_Yure_Client2_CluePage_CloseCase_EvidenceText2,
			ERenGu_Yure_Client2_CluePage_CloseCase_EvidenceText3,
			--ERenGu_Yure_Client2_CluePage_CloseCase_EvidenceText4
		},
		EvideneceNote_Component = {
			ERenGu_Yure_Client2_CluePage_CloseCase_NewEvidence1,
			ERenGu_Yure_Client2_CluePage_CloseCase_NewEvidence2,
			ERenGu_Yure_Client2_CluePage_CloseCase_NewEvidence3,
			--ERenGu_Yure_Client2_CluePage_CloseCase_NewEvidence4
		},
		GotoBtn = {State = 0 , },--Component = ERenGu_Yure_Client2_CluePage_CloseCase_GotoBtn },
		AnimateComponent = ERenGu_Yure_Client2_CluePage_CloseCase_SuspectAnimate

	}
	g_IntergrationLock = ERenGu_Yure_Client2_Clue_LockText1
	g_Clue = {
		Num  = 0, 
		Flag = { 0,0,0,0,0,0 },
		Btn = {	
			ERenGu_Yure_Client2_CluePage_ClueBtn1,
			ERenGu_Yure_Client2_CluePage_ClueBtn2,
			ERenGu_Yure_Client2_CluePage_ClueBtn3,
			ERenGu_Yure_Client2_CluePage_ClueBtn4,
			ERenGu_Yure_Client2_CluePage_ClueBtn5,
			ERenGu_Yure_Client2_CluePage_ClueBtn6,
			},
		ClueMatch = {
			[1] = { {[2] = 5,[5] = 2},{[1] = 4,[4] = 1},{[3] = 6, [6] = 3} },
			[2] = { {[5] = 3,[3] = 5},{[6] = 1,[1] = 6},{[4] = 2, [2] = 4} },
			--[3] = { {[4] = 6,[6] = 4},{[2] = 5,[5] = 2},{[1] = 3, [3] = 1} },
			[3] = { {[2] = 5,[5] = 2},{[4] = 6,[6] = 4},{[3] = 1, [1] = 3} },
		},
		SelectBKTXTConponent = {
			[1] = { ERenGu_Yure_Client2_CluePage_SelectInfo3,ERenGu_Yure_Client2_CluePage_SelectInfo1,
					ERenGu_Yure_Client2_CluePage_SelectInfo5,ERenGu_Yure_Client2_CluePage_SelectInfo4,
					ERenGu_Yure_Client2_CluePage_SelectInfo2,ERenGu_Yure_Client2_CluePage_SelectInfo6},

			[2] = { ERenGu_Yure_Client2_CluePage_SelectInfo4,ERenGu_Yure_Client2_CluePage_SelectInfo6,
					ERenGu_Yure_Client2_CluePage_SelectInfo2,ERenGu_Yure_Client2_CluePage_SelectInfo5,
					ERenGu_Yure_Client2_CluePage_SelectInfo1,ERenGu_Yure_Client2_CluePage_SelectInfo3},

			[3] = { ERenGu_Yure_Client2_CluePage_SelectInfo6,ERenGu_Yure_Client2_CluePage_SelectInfo1,
					ERenGu_Yure_Client2_CluePage_SelectInfo5,ERenGu_Yure_Client2_CluePage_SelectInfo3,
					ERenGu_Yure_Client2_CluePage_SelectInfo2,ERenGu_Yure_Client2_CluePage_SelectInfo4},
		},
		g_ClueTips = {
			--第一次收集齐线索时候的tips
			ERenGu_Yure_Client2_CluePage_ClueBtn1_Animate,ERenGu_Yure_Client2_CluePage_ClueBtn2_Animate,ERenGu_Yure_Client2_CluePage_ClueBtn3_Animate,
			ERenGu_Yure_Client2_CluePage_ClueBtn4_Animate,ERenGu_Yure_Client2_CluePage_ClueBtn5_Animate,ERenGu_Yure_Client2_CluePage_ClueBtn6_Animate,
		}
	}
	g_CluePaging = {
		ERenGu_Yure_Client2_Clue_FenYe1,
		ERenGu_Yure_Client2_Clue_FenYe2,
		ERenGu_Yure_Client2_Clue_FenYe3,
		--ERenGu_Yure_Client2_Clue_FenYe4
	}
	g_CluePageTips = {Component = {ERenGu_Yure_Client2_Clue_FenYe2Tips,ERenGu_Yure_Client2_Clue_FenYe3Tips} , tipsText = {"#{ERYR_240701_345}","#{ERYR_240701_348}"},DebugMessage = {"#{ERYR_240701_346}","#{ERYR_240701_347}"}}
	g_Client = { ERenGu_Yure_Client1 , ERenGu_Yure_Client2 , ERenGu_Yure_Client3}
	g_Client1_Info = {
		Component = ERenGu_Yure_Client1_Info,
		InfoText = {
			"set:ERenGu_Yure_02 image:Letter_Day1",
			"set:ERenGu_Yure_02 image:Letter_Day2",
			"set:ERenGu_Yure_02 image:Letter_Day3",
			"set:ERenGu_Yure_02 image:Letter_Day4"
		}
	}
	g_Client_Finished_ArtComponent = {ERenGu_Yure_Client3_Finished1,ERenGu_Yure_Client3_Finished2}
end

function ERenGu_Yure_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND ) then
		g_CurQuestPhrase   = Get_XParam_INT(0)
		g_CurActivityPhrase  = Get_XParam_INT(1)
		g_IsHaveMissionState = Get_XParam_INT(2)
		g_IsMissionComplete = Get_XParam_INT(3)
		g_ChosenNpcData = Get_XParam_INT(4)
		ERenGu_Yure_Init()
		KillTimer("ERenGu_Yure_CloseCaseTimer()");
		KillTimer("ERenGu_Yure_CloseAnimateTimer()");
		if g_CurQuestPhrase == 0 and g_IsHaveMissionState < 1 then
			ERenGu_Yure_UIPhase(1)	--阶段一界面显示
			ERenGu_Yure_SetImage(1)
			this:Show()
			return 
		end
		--记录玩家任务进度
		if (g_CurQuestPhrase >= 0 and g_CurQuestPhrase < 3) or (g_CurQuestPhrase == 3 and g_IsHaveMissionState < 1) then
		--完成至少一个任务且未持有任务时
			if g_IsHaveMissionState < 1 then
				if g_CurQuestPhrase > g_CurActivityPhrase then

					g_CurQuestPhrase = g_CurActivityPhrase
			ERenGu_Yure_UIPhase(2)	--阶段二界面显示
			ERenGu_Yure_Client2_CluePage_Init()
					ERenGu_Yure_Client2_PageClick(g_CurQuestPhrase)
				else
					ERenGu_Yure_UIPhase(1)	--阶段二界面显示
					g_CurQuestPhrase = math.min(3,g_CurQuestPhrase)
					ERenGu_Yure_SetImage(g_CurQuestPhrase+1)
				end
			this:Show()
			return
		end
			ERenGu_Yure_UIPhase(2)	--阶段二界面显示
			g_Clue.Num 	   = Get_XParam_INT(5)
			g_Clue.Flag[1] = Get_XParam_INT(6)
			g_Clue.Flag[2] = Get_XParam_INT(7)
			g_Clue.Flag[3] = Get_XParam_INT(8)
			g_Clue.Flag[4] = Get_XParam_INT(9)
			g_Clue.Flag[5] = Get_XParam_INT(10)
			g_Clue.Flag[6] = Get_XParam_INT(11)
			g_IsIntergtation = Get_XParam_INT(12)
		else
			if g_IsHaveMissionState >= 1 then
				ERenGu_Yure_UIPhase(3)	--阶段三界面显示
				if g_IsMissionComplete == 1 then
					ERenGu_Yure_Client3_GotoBtn:Disable()
					g_Client_Finished_ArtComponent[math.min(g_CurQuestPhrase-2,2)]:Show()
				end
			else
				if g_CurQuestPhrase > g_CurActivityPhrase then
					if g_CurQuestPhrase == 3 then
						--还未正式进入追凶阶段
						ERenGu_Yure_UIPhase(2)	--阶段二界面显示
						ERenGu_Yure_Client2_CluePage_Init()
						ERenGu_Yure_Client2_PageClick(g_CurQuestPhrase)
					else
						--进入追凶阶段(即最起码完成了一个追凶任务)
						ERenGu_Yure_UIPhase(3)	--阶段三界面显示
						g_Client_Finished_ArtComponent[g_CurQuestPhrase-3]:Show()
						-- PushDebugMessage("追凶阶段"..(g_CurQuestPhrase-3).."已完成")
						ERenGu_Yure_Client3_GotoBtn:Disable()
					end
				else
					ERenGu_Yure_UIPhase(1)	--阶段二界面显示
					g_CurQuestPhrase = math.min(3,g_CurQuestPhrase)
					ERenGu_Yure_SetImage(g_CurQuestPhrase+1)
				end
			end
			this:Show()
			return
		end
		ERenGu_Yure_Client2_CluePage_Init()
		ERenGu_Yure_Client2_PageClick( g_CurQuestPhrase)
		this:Show()
		return
	elseif (event == "UI_COMMAND" and tonumber(arg0) == g_CloseCaseUICOMMAND) then
		g_CloseCase_Component.AnimateComponent:Hide()
		g_CurQuestPhrase   = Get_XParam_INT(0)
		g_CurActivityPhrase  = Get_XParam_INT(1)
		g_IsHaveMissionState = Get_XParam_INT(2)
		g_IsIntergtation     = Get_XParam_INT(3)
		g_ChosenNpcData = Get_XParam_INT(4)
		g_IsCloseCase        = Get_XParam_INT(5)
		--阶段二的第二阶段，直接在函数里做特判，所以这里就不区分UIPhase了
		KillTimer("ERenGu_Yure_CloseCaseTimer()");
		KillTimer("ERenGu_Yure_CloseAnimateTimer()");
		ERenGu_Yure_UIPhase(2)
		ERenGu_Yure_Phase2CloseCase_Init()
		this:Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ERenGu_Yure_CloseFunc()
	end
end
--设置client1显示的书信内容
function ERenGu_Yure_SetImage(Index)
	ERenGu_Yure_Client1_InfoImage: SetProperty("Image",g_Client1_Info.InfoText[Index])
end
function ERenGu_Yure_Init()
	ERenGu_Yure_Client3_GotoBtn:Enable()
	for i = 1 , 2 do
		g_Client_Finished_ArtComponent[i]:Hide()
	end
	ERenGu_Yure_Client2_Clue_Answer_GotoBtn:Show()
	ERenGu_Yure_Client2_Clue_Answer_GotoBtn:SetToolTip("")
end
function ERenGu_Yure_CloseFunc()
	KillTimer("ERenGu_Yure_CloseCaseTimer()");
	KillTimer("ERenGu_Yure_CloseAnimateTimer()");
	g_ClueClickBackup    = -1 
	g_CurQuestPhrase   = -1
	g_IsHaveMissionState = -1
	g_CurClurPage 		 = -1
	g_IsIntergtation  	 = 0
	g_IsCloseCase     	 = 0
	g_CloseCasePhase	 = 0
	this:Hide()
	return 
end
function ERenGu_Yure_Client1_Goto_Clicked()
	AutoRuntoTargetExWithName(232, 278, 1, "闻人语")
	PushDebugMessage("#{ERYR_240701_34}")
	ERenGu_Yure_CloseFunc()
end
--分页初始化
function ERenGu_Yure_Client2_CluePage_Init()
	for i = 1 , 3 do
		g_CluePaging[i]:Disable()
	end
	for i = 1 , (math.min(3,g_CurQuestPhrase+1)) do
		g_CluePaging[i]:Enable()
	end
	for i = 1 , 6 do 
		g_Clue.g_ClueTips[i]:Hide()
	end
	--修改分页上方空按钮的显隐和tips
	for i = 1 , 2 do 
		g_CluePageTips.Component[i]:Hide()
	end
	--当玩家任务进度小于查案3期时（未接任务）
	if (g_CurQuestPhrase+1) < 3 then
		-- g_CurQuestPhrase+1 = 1 时 ，两个都显示 2
		-- g_CurQuestPhrase+1 = 2 时 ，1个显示    1
		-- g_CurQuestPhrase+1 = 3 时 ，不个显示   
		for i = 2, (g_CurQuestPhrase+1),-1 do 
			g_CluePageTips.Component[i]:Show()
		end 
		-- g_CurActivityPhrase + 1 = 1 时 两个都不改
		-- g_CurActivityPhrase + 1 = 2 时 第一个改
		-- g_CurActivityPhrase + 1 = 3 时 两个都改改
		if (g_CurActivityPhrase+1) > 1 then
			for i = 1, math.min(2,(g_CurActivityPhrase+1)-1) do
				g_CluePageTips.Component[i]:SetToolTip(g_CluePageTips.tipsText[i])
			end
		end
	end
end
--切换查案分页
function ERenGu_Yure_Client2_PageClick(cluePageIndex)
	cluePageIndex = cluePageIndex + 1
	cluePageIndex = math.min(3,cluePageIndex)
	-- if g_CurClurPage == cluePageIndex then
	-- 	return
	-- end

	--点到还没接取或完成的任务时，撤回操作
	if cluePageIndex > g_CurQuestPhrase+1 then
		return 
	end

	g_ClueClickBackup = -1
	g_IntergrationLock:Hide()
	ERenGu_Yure_Client2_Clue_Answer_GotoBtn:Show()
	ERenGu_Yure_Client2_Clue_Answer_GotoBtn:Enable()
	ERenGu_Yure_Client2_Clue_Answer_Finished:Show()
	ERenGu_Yure_Client2_SuspectImage1:Hide()
	ERenGu_Yure_Client2_SuspectImage2:Hide()
	for i = 1 , 6 do 
		g_Clue.Btn[i]:SetProperty("Selected", "False");
	end
	--选中按钮效果
	g_CluePaging[cluePageIndex]:SetProperty("Selected", "True");
	g_CurClurPage = cluePageIndex
	-- 当选择的分页为当前进行中的任务页面时
	if cluePageIndex-1 == g_CurQuestPhrase and g_IsHaveMissionState >= 1 then
		--当期任务不显示案情已梳理
		ERenGu_Yure_Client2_Clue_Answer_Finished:Hide()
		--整合结束（即任务完成）
		if g_IsIntergtation == 1 then
			--当前分页对应的线索
			for i = 1 , 6 do 
				if g_Clue.Flag[i] >= 1 then
					g_Clue.Btn[i]:SetText(g_CluePageContent[cluePageIndex].Getclues[i])
					g_Clue.Btn[i]:Disable()
					g_Clue.SelectBKTXTConponent[cluePageIndex][i]:Show()
					g_Clue.SelectBKTXTConponent[cluePageIndex][i]:SetText(g_CluePageContent[cluePageIndex].Getclues[i])
				end
			end
			--整合线索显示
			local content = ""
			for i = 1 ,3 do
				g_ClueIntergrations.Component[i]:Show()
				g_ClueIntergrations.Flag[i] = 1
				for j = 1,6 do
					--整合线索（三条）对应的线索序号
					if g_Clue.ClueMatch[cluePageIndex][i][j]~= nil then
							content = g_ClueIntergrations.Content[cluePageIndex][j]
							g_ClueIntergrations.Component[i]:SetText(content)
						break
					end
				end
			end
		else
			ERenGu_Yure_Client2_Clue_Answer_GotoBtn:Disable()
			ERenGu_Yure_Client2_Clue_Answer_GotoBtn:SetToolTip("#{ERYR_240701_37}")
			--ERenGu_Yure_Client2_Clue_Answer_Finished:Hide()
			g_IntergrationLock:Show()
			--任务进行中
			--当前分页对应的线索
			for i = 1 , 6 do 
				--如果线索没集齐六个，则按钮锁定
				if g_Clue.Num < 6 then
					g_Clue.Btn[i]:Disable()
				else
					g_Clue.Btn[i]:Enable()
				end
				if g_Clue.Flag[i] < 1 then
					g_Clue.Btn[i]:SetText(g_CluePageContent[cluePageIndex].UnknownClue)
				else
					g_Clue.Btn[i]:SetText(g_CluePageContent[cluePageIndex].Getclues[i])
				end
				g_Clue.SelectBKTXTConponent[cluePageIndex][i]:Hide()
			end
			--整合线索隐藏（让其默认隐藏（重置））
			--整合线索显示
			for i = 1 ,3 do
				g_ClueIntergrations.Component[i]:Hide()
				g_ClueIntergrations.Flag[i] = 0
			end
		end
	else
		--当选择分页为往期分页时
		for i = 1 , 6 do 
			g_Clue.Btn[i]:SetText(g_CluePageContent[cluePageIndex].Getclues[i])
			g_Clue.Btn[i]:Disable()
			g_Clue.SelectBKTXTConponent[cluePageIndex][i]:Show()
			g_Clue.SelectBKTXTConponent[cluePageIndex][i]:SetText(g_CluePageContent[cluePageIndex].Getclues[i])
		end
		--显示整合线索
		for i = 1 ,3 do
			g_ClueIntergrations.Component[i]:Show()
			g_ClueIntergrations.Flag[i] = 1
			for j = 1,6 do
				--整合线索（三条）对应的线索序号
				if g_Clue.ClueMatch[cluePageIndex][i][j]~= nil then
						local content = g_ClueIntergrations.Content[cluePageIndex][j]
						g_ClueIntergrations.Component[i]:SetText(content)
					break
				end
			end
		end
		--显示玩家选择的NPC
		local divisor = math.pow(10,cluePageIndex-1)
		local shiftednumber = math.floor(g_ChosenNpcData/divisor)
		local getPlayerChosen = shiftednumber - math.floor(shiftednumber/10)*10
		if getPlayerChosen == 1 then
			ERenGu_Yure_Client2_SuspectImage1:Show()
		elseif getPlayerChosen == 2 then
			ERenGu_Yure_Client2_SuspectImage2:Show()
		end
		ERenGu_Yure_Client2_Clue_Answer_GotoBtn:Hide()
	end
end
--点击线索按钮
function ERenGu_Yure_Client2_CluePage_ClueCheck_Clicked(clueIndex)
	local matchClue = nil
	local clueMatch = g_Clue.ClueMatch[g_CurClurPage]
	if g_ClueClickBackup == -1 then
	--查找当前按的按钮对应的线索按钮
	for i = 1 ,3 do 
		if clueMatch[i][clueIndex] ~=nil then
			matchClue = g_Clue.g_ClueTips[clueMatch[i][clueIndex]]
		end
	end
		if matchClue~=nil then
		--显示提示效果
		matchClue:Show()
		end
		g_ClueClickBackup = clueIndex
		g_Clue.SelectBKTXTConponent[g_CurClurPage][clueIndex]:Show()
		g_Clue.SelectBKTXTConponent[g_CurClurPage][clueIndex]:SetText(g_CluePageContent[g_CurClurPage].Getclues[clueIndex])
	else
		--查找已选按钮对应的线索按钮
		for i = 1 ,3 do 
			if clueMatch[i][g_ClueClickBackup] ~=nil then
				matchClue = g_Clue.g_ClueTips[clueMatch[i][g_ClueClickBackup]]
			end
		end
		if matchClue~=nil then
		--第二次点击，不管点击的按钮是否正确，先隐藏提示效果
		matchClue:Hide()
		end
		--重复点击同一个
		if g_ClueClickBackup == clueIndex then
			g_Clue.Btn[g_ClueClickBackup]:SetProperty("Selected", "False");
			g_Clue.SelectBKTXTConponent[g_CurClurPage][g_ClueClickBackup]:Hide()
			g_ClueClickBackup = -1
			return 
		end
		--初始化失败
		if g_CurQuestPhrase == -1 then
			g_Clue.Btn[g_ClueClickBackup]:SetProperty("Selected", "False");
			g_Clue.SelectBKTXTConponent[g_CurClurPage][g_ClueClickBackup]:Hide()
			g_ClueClickBackup = -1
			return
		end
		--非当前进行中分页
		if g_CurClurPage < g_CurQuestPhrase then
			g_Clue.Btn[g_ClueClickBackup]:SetProperty("Selected", "False");
			g_Clue.SelectBKTXTConponent[g_CurClurPage][g_ClueClickBackup]:Hide()
			g_ClueClickBackup = -1
			return 
		end
		--点击了两个不同的按钮，先给后一个点击的按钮取消选中，再进行线索判定
		g_Clue.Btn[clueIndex]:SetProperty("Selected", "False");
		g_Clue.Btn[g_ClueClickBackup]:SetProperty("Selected", "False");

		if g_CurClurPage == g_CurQuestPhrase+1 then
			local isTrueMatch = false
			--一对线索选择成功，按钮选中重置，进行线索匹配判定
			local clueMatch = g_Clue.ClueMatch[g_CurClurPage]
			for i = 1 ,3 do 
				if clueMatch[i][g_ClueClickBackup] ~=nil and clueMatch[i][g_ClueClickBackup] == clueIndex then
					g_ClueIntergrations.Component[i]:Show()
					g_ClueIntergrations.Flag[i] = 1
					local content = g_ClueIntergrations.Content[g_CurClurPage][clueIndex]
					g_ClueIntergrations.Component[i]:SetText(content)
					g_Clue.Btn[g_ClueClickBackup]:Disable()
					g_Clue.Btn[clueIndex]:Disable()
					g_Clue.SelectBKTXTConponent[g_CurClurPage][clueIndex]:Show()
					g_Clue.SelectBKTXTConponent[g_CurClurPage][clueIndex]:SetText(g_CluePageContent[g_CurClurPage].Getclues[clueIndex])
					isTrueMatch = true
					g_IntergrationLock:Hide()
					PushDebugMessage("#{ERYR_240701_81}")
					break
				end
			end
			--没有线索匹配项
			if isTrueMatch ~= true then
				PushDebugMessage("#{ERYR_240701_83}")
				g_Clue.SelectBKTXTConponent[g_CurClurPage][g_ClueClickBackup]:Hide()
			end
			--查看是否已经完成三个线索的整合行为，如果已完成则界面显示任务完成，并通知服务器更新任务进度
			local isFinishIntergration = true
			for i = 1,3 do
				if g_ClueIntergrations.Flag[i] ~= 1 then
					isFinishIntergration = false
					break
				end 
			end 
			--任务完成，更新界面并通知任务更新
			if isFinishIntergration then
				g_IsIntergtation = 1
				PushDebugMessage("#{ERYR_240701_82}")
				ERenGu_Yure_Client2_Clue_Answer_GotoBtn:Enable()

				ERenGu_Yure_Phase2UpdateQuest()

				-- ERenGu_Yure_Client2_PageClick( g_CurQuestPhrase)
			end
			-- g_Clue.Btn[g_ClueClickBackup]:SetProperty("Selected", "False");
			g_ClueClickBackup = -1
		end
	end
end
function ERenGu_Yure_Phase2UpdateQuest()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(g_MissionScrpitID)
		Set_XSCRIPT_Function_Name("UpdateFromUI")
		Set_XSCRIPT_Parameter(0,g_CurQuestPhrase)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
--点击help按钮
function ERenGu_Yure_ClickHelp()
	PushEvent("QUEST_HELP_MSG", "#{ERYR_240701_35}")
end
function ERenGu_Yure_Phase2CloseCase_Init()
	for i = 1,3 do
		g_CloseCase_Component.EvideneceNote_Component[i]:StartFade(1,0,0)
	end
	SetTimer("ERenGu_Yure","ERenGu_Yure_CloseCaseTimer()", 1000)
	g_CloseCase_Component.GotoBtn.State = 0
	--似有蹊跷，难道
	ERenGu_Yure_Client2_CluePage_CloseCase_GotoBtn1:Show()
	ERenGu_Yure_Client2_CluePage_CloseCase_GotoBtn2:Hide()
	-- g_CloseCase_Component.GotoBtn.Component:SetText("#{ERYR_240701_85}")
end
function ERenGu_Yure_CloseCaseTimer()
	g_CloseCasePhase = g_CloseCasePhase + 1 
	--四个罪证注释一次显示
	if g_CloseCasePhase <=3 then
		g_CloseCase_Component.EvideneceNote_Component[g_CloseCasePhase]:StartFade(0,1,2)
	end
	--最后显示动画并持续四秒
	if g_CloseCasePhase == 4 then
		g_CloseCasePhase = 0
		g_CloseCase_Component.GotoBtn.State = 1
		--竟然……
		ERenGu_Yure_Client2_CluePage_CloseCase_GotoBtn2:Show()
		ERenGu_Yure_Client2_CluePage_CloseCase_GotoBtn1:Hide()
		-- g_CloseCase_Component.GotoBtn.Component:SetText("#{ERYR_240701_86}")
		KillTimer("ERenGu_Yure_CloseCaseTimer()");
	end
end
function ERenGu_Yure_Client2_CluePage_Goto_Clicked()
	g_CloseCase_Component.AnimateComponent:Show()
	SetTimer("ERenGu_Yure","ERenGu_Yure_CloseAnimateTimer()", 4000)
	PushDebugMessage("#{ERYR_240701_87}")
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(g_MissionScrpitID)
		Set_XSCRIPT_Function_Name("CloseCaseUpdateFromUI")
		Set_XSCRIPT_Parameter(0,g_CurQuestPhrase)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	AutoRuntoTargetExWithName(232, 278, 1, "闻人语")
	local GotoBtnState = g_CloseCase_Component.GotoBtn.State
	if GotoBtnState == 1 then
		g_CloseCase_Component.AnimateComponent:Play(true)
	end
end
function ERenGu_Yure_Client3_Goto_Clicked()
	if g_IsHaveMissionState < 1 then
		-- PushDebugMessage("#{ERYR_240701_88}")
		ERenGu_Yure_CloseFunc()
	else
		if g_CurQuestPhrase == 3 then
			AutoRuntoTargetExWithName(217, 414, 1, "施浩然")
		else
			AutoRunToTargetEx(208,71,30)
			PushDebugMessage("#{ERYR_240701_328}")
		end
		ERenGu_Yure_CloseFunc()
	end
end
function ERenGu_Yure_Client2_Clue_FenYeTipsClick(Index)
	local cIndex = Index
	PushDebugMessage(g_CluePageTips.DebugMessage[cIndex]) 
end
function ERenGu_Yure_CloseAnimateTimer()
	g_CloseCase_Component.AnimateComponent:Play(false)
	g_CloseCase_Component.AnimateComponent:Hide()
	ERenGu_Yure_CloseFunc()
end
function ERenGu_Yure_UIPhase(UIPhase)
	for i = 1 , 3 do
		if UIPhase == i then
			g_Client[i]:Show();
		else
			g_Client[i]:Hide();
		end
	end
	--对阶段二做一定特判，需要把阶段二分开成两个阶段
	if UIPhase == 2 and g_IsCloseCase == 1 then
		ERenGu_Yure_Client2_CluePage_CloseCaseFrame:Show()
		ERenGu_Yure_Client2_ClueFrame:Hide()
	else
		ERenGu_Yure_Client2_CluePage_CloseCaseFrame:Hide()
		ERenGu_Yure_Client2_ClueFrame:Show()
	end
end