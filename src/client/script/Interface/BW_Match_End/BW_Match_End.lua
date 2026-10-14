-- 新比武大会结算界面

local g_Frame_UnifiedPosition ={}
-- star3 就不存了，感觉一个存了有点傻
local g_Star1 = {}
local g_Star2 = {}
local g_Star3 = {}
local g_Star4 = {}
local g_Star5 = {}
local g_StarAnim1 = {}
local g_StarAnim2 = {}
local g_StarAnim3 = {}
local g_StarAnim4 = {}
local g_StarAnim5 = {}

local g_Image_Duanwei = {
	[0] = { 
		[1] = "set:BW_Match20 image:BW_que1",
		[2] = "set:BW_Match20 image:BW_que2",
		[3] = "set:BW_Match20 image:BW_que3",
		[4] = "set:BW_Match20 image:BW_que4",
		[5] = "set:BW_Match20 image:BW_que5",
	--	[6] = "set:BW_Match20 image:BW_que6",
		[6] = "set:BW_Match20 image:BW_que7",
	},
	
	[1] = {
		[1] = "set:BW_Match5 image:Match_Eagle1",
		[2] = "set:BW_Match5 image:Match_Eagle2",
		[3] = "set:BW_Match4 image:Match_Eagle3",
		[4] = "set:BW_Match4 image:Match_Eagle4",
		[5] = "set:BW_Match4 image:Match_Eagle5",
	--	[6] = "set:BW_Match4 image:Match_Eagle6",
		[6] = "set:BW_Match3 image:Match_Eagle7",
	},

	-- [2] = {
		-- [1] = "set:BW_Match3 image:Match_Tiger1",
		-- [2] = "set:BW_Match3 image:Match_Tiger2",
		-- [3] = "set:BW_Match3 image:Match_Tiger3",
		-- [4] = "set:BW_Match2 image:Match_Tiger4",
		-- [5] = "set:BW_Match2 image:Match_Tiger5",
	-- --	[6] = "set:BW_Match1 image:Match_Tiger6",
		-- [6] = "set:BW_Match1 image:Match_Tiger7",
	-- },

	[2] = {
		[1] = "set:BW_Match7 image:Match_Dragon1",
		[2] = "set:BW_Match6 image:Match_Dragon2",
		[3] = "set:BW_Match6 image:Match_Dragon3",
		[4] = "set:BW_Match6 image:Match_Dragon4",
		[5] = "set:BW_Match6 image:Match_Dragon5",
	--	[6] = "set:BW_Match5 image:Match_Dragon6",
		[6] = "set:BW_Match5 image:Match_Dragon7",
	},
	
	[3] = {
		[1] = "set:BW_Match21 image:BW_Kun1",
		[2] = "set:BW_Match21 image:BW_Kun2",
		[3] = "set:BW_Match21 image:BW_Kun3",
		[4] = "set:BW_Match21 image:BW_Kun4",
		[5] = "set:BW_Match21 image:BW_Kun5",
	--	[6] = "set:BW_Match21 image:BW_Kun6",
		[6] = "set:BW_Match21 image:BW_Kun7",
	},
}


local g_Image_Number = {
	[1] = "set:BW_Match1 image:Number1", 
	[2] = "set:BW_Match1 image:Number2",	
	[3] = "set:BW_Match1 image:Number3", 
	[4] = "set:BW_Match1 image:Number4",	
	[5] = "set:BW_Match1 image:Number5", 
	[6] = "set:BW_Match1 image:Number6",
}

-- 
local g_ImageStar = {
						[1] = "set:BW_Match1 image:Bright_Stars", --亮星星
						[2] = "set:BW_Match1 image:Gray_Stars",	--灰星星
}

local g_Timer = -1
local g_BigUpTimer = -1
local g_BigDownTimer = -1
local g_EndLineTimer = -1
local g_SecondEndLineTimer = -1
local g_EndLineMark = -1
local g_EndLineMax = -1
local g_CurStarFor6 = -1
local g_CurMajorRank = -1
local g_UpType = -1
local g_SecondLineNum = -1
local g_SecondLineMax = -1
local g_NeedSecond = -1
local g_WhichLight = -1
local g_UpTimer = -1
local g_DownTimer = -1
local g_CurStar = -1 
local g_StarUpTime = 2
local g_StarKongTime1 = 2 --升小段动画时间
local g_StarKongTime2 = 2 --升大段动画时间
local g_AllTime1 = g_StarUpTime + g_StarKongTime1 + g_StarUpTime
local g_AllTime2 = g_StarUpTime + g_StarKongTime2 + g_StarUpTime
-- 没有办法 全局不够用了 都塞一起了
local g_DuanWei1 = {
	-- 大段
	[1] = "#{BWDH_180804_131}",
	[2] = "#{BWDH_180804_132}",
	[3] = "#{BWDH_180804_133}",
	[4] = "#{BWDH_180804_134}",
	[5] = "#{BWDH_180804_135}",
	[6] = "#{BWDH_180804_136}",
	-- 小段
	[7] = "#{BWDH_180804_141}",
	[8] = "#{BWDH_180804_140}",
	[9] = "#{BWDH_180804_139}",
	[10] = "#{BWDH_180804_138}",
	[11] = "#{BWDH_180804_137}",
	-- 分组
	[12] = "#{BWDH_180804_144}",
	[13] = "#{BWDH_180804_145}",
	[14] = "#{BWDH_180804_146}",
	[15] = "#{BWDH_250113_03}",
}

function BW_Match_End_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("BWTROOPS_RESULT_SHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function BW_Match_End_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedPosition[1]	= BW_Match_End_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedPosition[2]	= BW_Match_End_Frame:GetProperty("UnifiedYPosition");

	--把界面上的空间都存到数组里
	g_Star1={
			[0] = BW_Match_End_Star1,
			[1] = BW_Match_End_Star2,
			[2] = BW_Match_End_Star3,
			[3] = BW_Match_End_Star4,
	}
	
	g_Star2={
			[0] = BW_Match_End_Star1_1,
			[1] = BW_Match_End_Star1_2,
			[2] = BW_Match_End_Star1_3,
			[3] = BW_Match_End_Star1_4,
			[4] = BW_Match_End_Star1_5,
	}
	
	g_Star3={
			[0] = BW_Match_End_Star2_1,
			[1] = BW_Match_End_Star2_2,
			[2] = BW_Match_End_Star2_3,
	}
	
	g_Star4={
			[0] = BW_Match_End_Star6_1,
			[1] = BW_Match_End_Star6_2,
			[2] = BW_Match_End_Star6_3,
			[3] = BW_Match_End_Star6_4,
			[4] = BW_Match_End_Star6_5,
			[5] = BW_Match_End_Star6_6,
	}
	
	g_Star5={
			[0] = BW_Match_End_Star8_1,
			[1] = BW_Match_End_Star8_2,
			[2] = BW_Match_End_Star8_3,
			[3] = BW_Match_End_Star8_4,
			[4] = BW_Match_End_Star8_5,
			[5] = BW_Match_End_Star8_6,
			
	}
	
	g_StarAnim1={
			[0] = BW_Match_End_Star1Animate,
			[1] = BW_Match_End_Star2Animate,
			[2] = BW_Match_End_Star3Animate,
			[3] = BW_Match_End_Star4Animate,
	}
	
	g_StarAnim2={
			[0] = BW_Match_End_Star1_1Animate,
			[1] = BW_Match_End_Star1_2Animate,
			[2] = BW_Match_End_Star1_3Animate,
			[3] = BW_Match_End_Star1_4Animate,
			[4] = BW_Match_End_Star1_5Animate,
	}
	
	g_StarAnim3={
			[0] = BW_Match_End_Star2_1Animate,
			[1] = BW_Match_End_Star2_2Animate,
			[2] = BW_Match_End_Star2_3Animate,
	}
	
	g_StarAnim4={
			[0] = BW_Match_End_Star6_1Animate,
			[1] = BW_Match_End_Star6_2Animate,
			[2] = BW_Match_End_Star6_3Animate,
			[3] = BW_Match_End_Star6_4Animate,
			[4] = BW_Match_End_Star6_5Animate,
			[5] = BW_Match_End_Star6_6Animate,
	}
	
	g_StarAnim5={
			[0] = BW_Match_End_Star8_1Animate,
			[1] = BW_Match_End_Star8_2Animate,
			[2] = BW_Match_End_Star8_3Animate,
			[3] = BW_Match_End_Star8_4Animate,
			[4] = BW_Match_End_Star8_5Animate,
			[5] = BW_Match_End_Star8_6Animate,
			
	}
	
	--初始化各个控件
	BW_Match_End_CtrlList_InitData()
end

-- 清空
function BW_Match_End_CtrlList_InitData()

	BW_Match_End_RightBK_Text1:SetText("")
	BW_Match_End_Progress:SetProgress(0,100000)
	BW_Match_End_RightBK_Text2:SetText("")
	BW_Match_End_RightBK_Text3:SetText("")
	--BW_Match_End_RightBK_Text4:SetText("")
	BW_Match_End_RightBK_Text5:SetText("")
	BW_Match_End_StageBK_Text2:SetText("")
	--BW_Match_End_StageBK_Button:Disable()
	g_Timer = 30
	g_BigDownTimer = 2
	g_DownTimer = 2
	g_CurStar = 0
	g_EndLineTimer = 100
	g_SecondEndLineTimer = 100
	g_SecondLineNum = -1
	g_SecondLineMax = -1
	g_NeedSecond = -1
	g_WhichLight = -1
	g_UpType = -1
	g_StarUpTime = 2
	g_StarKongTime1 = 2
	g_StarKongTime2 = 2
	g_AllTime1 = g_StarUpTime + g_StarKongTime1 + g_StarUpTime
	g_AllTime2 = g_StarUpTime + g_StarKongTime2 + g_StarUpTime
	g_UpTimer = g_AllTime1
	g_BigUpTimer = g_AllTime2
	for i=0, 2 do
		g_Star3[i]:Hide()
		g_Star3[i]:SetProperty("Image", g_ImageStar[2])
		g_StarAnim3[i]:Hide()
		g_StarAnim3[i]:Play(false)
	end
	for i=0, 3 do
		g_Star1[i]:Hide()
		g_Star1[i]:SetProperty("Image", g_ImageStar[2])
		g_StarAnim1[i]:Hide()
		g_StarAnim1[i]:Play(false)
	end
	for i=0, 4 do
		g_Star2[i]:Hide()
		g_Star2[i]:SetProperty("Image", g_ImageStar[2])
		g_StarAnim2[i]:Hide()
		g_StarAnim2[i]:Play(false)
	end
	for i=0, 5 do
		g_Star4[i]:Hide()
		g_Star4[i]:SetProperty("Image", g_ImageStar[2])
		g_StarAnim4[i]:Hide()
		g_StarAnim4[i]:Play(false)
	end
	for i=0, 5 do
		g_Star5[i]:Hide()
		g_Star5[i]:SetProperty("Image", g_ImageStar[2])
		g_StarAnim5[i]:Hide()
		g_StarAnim5[i]:Play(false)
	end
	BW_Match_End_Star3_1:Hide()
	BW_Match_End_Star3_1Animate:Hide()
	BW_Match_End_Star3_1Animate:Play(false)
	BW_Match_End_Star3Text:SetText("")
	BW_Match_End_Client_Frame_Victory:Hide()
	BW_Match_End_GoupAnimate:Hide()
	BW_Match_End_StageBK_Image1Animate:Hide()
	BW_Match_End_StageBK_Image1Animate:Play(false)
	BW_Match_End_StageBK_Text1:Hide()
	BW_Match_End_Line1:Hide()
	BW_Match_End_Line2:Hide()
	BW_Match_End_Line3:Hide()
	BW_Match_End_Line4:Hide()
	BW_Match_End_RightBK_Text2:Hide()
	BW_Match_End_RightBK_Text6:Hide()
	BW_Match_End_RightBK_Text2_1:SetText("")
	--BW_Match_End_RightBK_Text2_2:SetText("")
	--BW_Match_End_RightBK_Text2_3:SetText("")
	--BW_Match_End_RightBK_Text2_4:SetText("")
	BW_Match_End_RightBK_Text6_1:SetText("")
	BW_Match_End_RightBK_Text6_2:SetText("")
	--BW_Match_End_RightBK_Text6_3:SetText("")
	BW_Match_End_ProgressWindowText:SetText("")
	BW_Match_End_ProgressWindowText1:SetText("")
	BW_Match_End_RightBK_Lace_Text:SetText("")
	--BW_Match_End_RightBK_Lace_TextBk:Hide()
	--BW_Match_End_RightBK_Text2_1Bk:Hide()
	--BW_Match_End_RightBK_Text3Bk:Hide()
	--BW_Match_End_RightBK_Text6_1Bk:Hide()
	--BW_Match_End_RightBK_Text6_2Bk:Hide()
	BW_Match_End_RightBK_Lace_TextNum:SetText("")
	BW_Match_End_RightBK_Text2_1Num:SetText("")
	BW_Match_End_RightBK_Text3Num:SetText("")
	BW_Match_End_RightBK_Text6_1Num:SetText("")
	BW_Match_End_RightBK_Text6_2Num:SetText("")
	BW_Match_End_Shuangbei_Image:Hide()
	
end

function BW_Match_End_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BW_Match_End_ResetPos()
	elseif ( event == "BWTROOPS_RESULT_SHOW" ) then
		if 1 == Player:GetData("Is2606S") then
			return
		end
		BW_Match_End_CtrlList_InitData()
		g_Timer = 30
		BW_Match_End_RightBK_Text5:SetText(ScriptGlobal_Format("#{SCGZ_180816_88}", g_Timer))
		SetTimer("BW_Match_End","BW_Match_End_Timer()", 1*1000)
		BW_Match_End_Frame_FullFill_Data()
		this:Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
	
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BW_Match_End_ResetPos()
	BW_Match_End_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedPosition[1]);
	BW_Match_End_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedPosition[2]);
end
-- 关闭函数
function BW_Match_EndFrame_CloseWindow()
	this:Hide()
end

--================================================
-- 填充数据
--================================================
function BW_Match_End_Frame_FullFill_Data()
	
	-- 取了一裤兜子数据，难受的亚比
	local nPreYZScore,nYZScore,nMaxYZScore,nCurMajorRank,nCurMinorRank,nCurStar,nCurWeekAddMJB,nCurWeekMaxMJB,nAddMJB,nPreMaxYZScore,nPreMajorRank,nPreMinorRank,nPreStar,nBaseWinScore,nBaseLoseScore,nSw3GapScore,nConWinScore,nBWResult,bChongCi= BWDH2018:GetResultData()
	g_CurStarFor6 = nCurStar
	g_CurStar = nCurStar
	local Text = ScriptGlobal_Format("#{SCGZ_180816_107}", nYZScore)
	--PushDebugMessage(nYZScore)
	BW_Match_End_RightBK_Text1:SetText(Text)
	BW_Match_End_RightBK_Text1:Hide()
	BW_Match_End_ProgressWindow:Hide()
	BW_Match_End_Progress:Hide()
	BW_Match_End_ProgressBK:Hide()
	BW_Match_End_ProgressWindowText:Hide()
	BW_Match_End_ProgressWindowText1:Hide()
	BW_Match_End_RightBK_LaceTitleBK:Hide()
	BW_Match_End_RightBK_Lace:Hide()
	BW_Match_End_Shuangbei_Image:Hide()
	
	g_EndLineMark = nYZScore
	g_EndLineMax = nMaxYZScore
	if nBWResult == nil then
		return
	end
	if nAddMJB > 0 then
		BW_Match_End_RightBK_Text2:Hide()
		if nBWResult == 0 then
			BW_Match_End_RightBK_Text2_1:SetText("#{SCGZ_180816_87}")
			local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", nBaseWinScore+nConWinScore+nSw3GapScore)
			if bChongCi == 1 then
				Text = Text.."#{SJCC_191011_33}"
				BW_Match_End_Shuangbei_Image:Hide()
			end
			BW_Match_End_RightBK_Text2_1Num:SetText(Text)
			--local Text = ScriptGlobal_Format("#{SCGZ_180816_103}", nBaseWinScore)
			--BW_Match_End_RightBK_Text2_2:SetText(Text)
			BW_Match_End_Client_Frame_Victory:Show()
			BW_Match_End_Client_Frame_Victory:SetProperty("Image", "set:BW_Match7 image:Victory")
		elseif nBWResult == 1 then
			BW_Match_End_RightBK_Text2_1:SetText("#{SCGZ_180816_87}")
			local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", nBaseLoseScore+nConWinScore+nSw3GapScore)
			if bChongCi == 1 then
				Text = Text.."#{SJCC_191011_33}"
				BW_Match_End_Shuangbei_Image:Hide()
			end
			BW_Match_End_RightBK_Text2_1Num:SetText(Text)
			--local Text = ScriptGlobal_Format("#{SCGZ_180816_103}", nBaseLoseScore)
			--BW_Match_End_RightBK_Text2_2:SetText(Text)
			BW_Match_End_Client_Frame_Victory:Show()
			BW_Match_End_Client_Frame_Victory:SetProperty("Image", "set:BW_Match9 image:Fail")
		end
		-- if nConWinScore ~= -1 then
			-- local Text = ScriptGlobal_Format("#{SCGZ_180816_104}", nConWinScore)
			-- BW_Match_End_RightBK_Text2_3:SetText(Text)
		-- else
			-- local Text = ScriptGlobal_Format("#{SCGZ_180816_104}", 0)
			-- BW_Match_End_RightBK_Text2_3:SetText(Text)
		-- end
		-- if nSw3GapScore ~= -1 then
			-- local Text = ScriptGlobal_Format("#{SCGZ_180816_105}", nSw3GapScore)
			-- BW_Match_End_RightBK_Text2_4:SetText(Text)
		-- else
			-- local Text = ScriptGlobal_Format("#{SCGZ_180816_105}", 0)
			-- BW_Match_End_RightBK_Text2_4:SetText(Text)
		-- end
		BW_Match_End_RightBK_Text3:SetText("#{SCGZ_180816_62}")
		local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", nAddMJB)
		BW_Match_End_RightBK_Text3Num:SetText(Text)
	elseif nAddMJB == 0 then
		BW_Match_End_RightBK_Text6:Hide()
		if nBWResult == 0 then
			BW_Match_End_RightBK_Text6_2:SetText("#{SCGZ_180816_87}")
			local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", nBaseWinScore+nConWinScore+nSw3GapScore)
			if bChongCi == 1 then
				Text = Text.."#{SJCC_191011_33}"
				BW_Match_End_Shuangbei_Image:Hide()
			end
			BW_Match_End_RightBK_Text6_2Num:SetText(Text)
			-- local Text = ScriptGlobal_Format("#{SCGZ_180816_103}", nBaseWinScore)
			-- BW_Match_End_RightBK_Text6_2:SetText(Text)
			BW_Match_End_Client_Frame_Victory:Show()
			BW_Match_End_Client_Frame_Victory:SetProperty("Image", "set:BW_Match7 image:Victory")
		elseif nBWResult == 1 then
			BW_Match_End_RightBK_Text6_2:SetText("#{SCGZ_180816_87}")
			local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", nBaseLoseScore+nConWinScore+nSw3GapScore)
			if bChongCi == 1 then
				Text = Text.."#{SJCC_191011_33}"
				BW_Match_End_Shuangbei_Image:Hide()
			end
			BW_Match_End_RightBK_Text6_2Num:SetText(Text)
			-- local Text = ScriptGlobal_Format("#{SCGZ_180816_103}", nBaseLoseScore)
			-- BW_Match_End_RightBK_Text6_2:SetText(Text)
			BW_Match_End_Client_Frame_Victory:Show()
			BW_Match_End_Client_Frame_Victory:SetProperty("Image", "set:BW_Match9 image:Fail")
		end
		-- if nConWinScore ~= -1 then
			-- local Text = ScriptGlobal_Format("#{SCGZ_180816_104}", nConWinScore)
			-- BW_Match_End_RightBK_Text6_3:SetText(Text)
		-- else
			-- local Text = ScriptGlobal_Format("#{SCGZ_180816_104}", 0)
			-- BW_Match_End_RightBK_Text6_3:SetText(Text)
		-- end
		-- if nSw3GapScore ~= -1 then
			-- local Text = ScriptGlobal_Format("#{SCGZ_180816_105}", nSw3GapScore)
			-- BW_Match_End_RightBK_Text2_4:SetText(Text)
		-- else
			-- local Text = ScriptGlobal_Format("#{SCGZ_180816_105}", 0)
			-- BW_Match_End_RightBK_Text2_4:SetText(Text)
		-- end
	end
	-- 只有名剑币不等于0的时候才显示
	-- if nAddMJB ~= 0 then
		-- local Text = ScriptGlobal_Format("#{SCGZ_180816_62}", nAddMJB)
		-- BW_Match_End_RightBK_Text3:SetText(Text)
	-- end
	--local Text = ScriptGlobal_Format("#{SCGZ_180816_82}", nCurWeekAddMJB,nCurWeekMaxMJB)
	--BW_Match_End_RightBK_Text4:SetText(Text)
	BW_Match_End_RightBK_Text5:SetText("")
	--BW_Match_End_StageBK_Button:Disable()
	
	--设置图片 数组序号前面的数字是偏移量= =，
	local MatchId = BWDH2018:GetMatchId()
	-- 不掉段
	if nCurMajorRank == nPreMajorRank and nCurMinorRank == nPreMinorRank then
		BW_Match_End_StageBK_Image:SetProperty("Image", g_Image_Duanwei[MatchId][nCurMajorRank])
		
		if nCurMajorRank ~= 6 then
			BW_Match_End_StageBK_Text1:Show()
			BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[nCurMinorRank])
			-- 填充左边的数据
			local text2 = ScriptGlobal_Format("#{BWDH_180804_154}", g_DuanWei1[nCurMajorRank], g_DuanWei1[nCurMinorRank+6])
			BW_Match_End_StageBK_Text2:SetText(text2)
		else
			--BW_Match_End_StageBK_Text1:Show()
			-- 填充左边的数据
			local text2 = ScriptGlobal_Format("#{BWDH_180804_155}", g_DuanWei1[nCurMajorRank])
			BW_Match_End_StageBK_Text2:SetText(text2)--..g_DuanWei1[nCurMinorRank+6].."阶")
		end
		if nCurStar > nPreStar then
			if nCurStar - nPreStar == 2 then
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 2)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			elseif nCurStar - nPreStar ==  1 then
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 1)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			end
		elseif nCurStar == nPreStar then
			--BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_113}")
			if nAddMJB > 0 then 
				BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_113}")
				BW_Match_End_RightBK_Lace_TextNum:SetText("#{SCGZ_180816_118}")
			elseif nAddMJB == 0 then
				BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_113}")
				BW_Match_End_RightBK_Text6_1Num:SetText("#{SCGZ_180816_118}")
			end
		elseif nCurStar < nPreStar then
			--BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_112}")
			if nAddMJB > 0 then 
				BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_112}")
				BW_Match_End_RightBK_Lace_TextNum:SetText("#{SCGZ_180816_117}")
			elseif nAddMJB == 0 then
				BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_112}")
				BW_Match_End_RightBK_Text6_1Num:SetText("#{SCGZ_180816_117}")
			end
		end
	elseif nCurMajorRank < nPreMajorRank then --掉大段
		BW_Match_End_StageBK_Image:SetProperty("Image", g_Image_Duanwei[MatchId][nPreMajorRank])
		
		if nCurMajorRank ~= 6 then
			BW_Match_End_StageBK_Text1:Show()
			BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[nPreMinorRank])
			-- 填充左边的数据
			local text2 = ScriptGlobal_Format("#{BWDH_180804_154}",g_DuanWei1[nPreMajorRank], g_DuanWei1[nPreMinorRank+6])
			BW_Match_End_StageBK_Text2:SetText(text2)
		else
			--BW_Match_End_StageBK_Text1:Hide()
			-- 填充左边的数据
			local text2 = ScriptGlobal_Format("#{BWDH_180804_155}",  g_DuanWei1[nPreMajorRank])
			BW_Match_End_StageBK_Text2:SetText(text2)--..g_DuanWei1[nCurMinorRank+6].."阶")
		end
		--BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_112}")
		if nAddMJB > 0 then 
			BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_112}")
			BW_Match_End_RightBK_Lace_TextNum:SetText("#{SCGZ_180816_117}")
		elseif nAddMJB == 0 then
			BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_112}")
			BW_Match_End_RightBK_Text6_1Num:SetText("#{SCGZ_180816_117}")
		end
		
	elseif nCurMajorRank == nPreMajorRank and nCurMinorRank < nPreMinorRank then --升小段
		BW_Match_End_StageBK_Image:SetProperty("Image", g_Image_Duanwei[MatchId][nPreMajorRank])
		
		BW_Match_End_StageBK_Text1:Show()
		BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[nPreMinorRank])
		-- 填充左边的数据
		local text2 = ScriptGlobal_Format("#{BWDH_180804_154}",g_DuanWei1[nPreMajorRank], g_DuanWei1[nPreMinorRank+6])
		BW_Match_End_StageBK_Text2:SetText(text2)
		if nCurMajorRank == 1 then
			if nCurStar == 2 or nPreStar == 1 then
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 2)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			else
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 1)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			end
		elseif nCurMajorRank == 2 or nCurMajorRank == 3 then
			if nCurStar == 2 or nPreStar == 2 then
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 2)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			else
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 1)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			end
		elseif nCurMajorRank == 4 or nCurMajorRank == 5 then
			if nCurStar == 2 or nPreStar == 3 then
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 2)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			else
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 1)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			end
		end
		
	elseif nCurMajorRank == nPreMajorRank and nCurMinorRank > nPreMinorRank then -- 掉小段
		BW_Match_End_StageBK_Image:SetProperty("Image", g_Image_Duanwei[MatchId][nCurMajorRank])
		
		BW_Match_End_StageBK_Text1:Show()
		BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[nPreMinorRank])
		-- 填充左边的数据
		local text2 = ScriptGlobal_Format("#{BWDH_180804_154}", g_DuanWei1[nPreMajorRank], g_DuanWei1[nPreMinorRank+6])
		BW_Match_End_StageBK_Text2:SetText(text2)
		--BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_112}")
		if nAddMJB > 0 then 
			BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_112}")
			BW_Match_End_RightBK_Lace_TextNum:SetText("#{SCGZ_180816_117}")
		elseif nAddMJB == 0 then
			BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_112}")
			BW_Match_End_RightBK_Text6_1Num:SetText("#{SCGZ_180816_117}")
		end
		
	elseif nCurMajorRank > nPreMajorRank then --升大段
		BW_Match_End_StageBK_Image:SetProperty("Image", g_Image_Duanwei[MatchId][nPreMajorRank])
		
		BW_Match_End_StageBK_Text1:Show()
		BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[nPreMinorRank])
		-- 填充左边的数据
		local text2 = ScriptGlobal_Format("#{BWDH_180804_154}", g_DuanWei1[nPreMajorRank], g_DuanWei1[nPreMinorRank+6])
		BW_Match_End_StageBK_Text2:SetText(text2)
		if nCurMajorRank == 2 then
			if nCurStar == 2 or nPreStar == 1 then
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 2)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			else
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 1)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			end
		elseif nCurMajorRank == 3 or nCurMajorRank == 4 then
			if nCurStar == 2 or nPreStar == 2 then
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 2)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			else
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 1)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			end
		elseif nCurMajorRank == 5 or nCurMajorRank == 6 then
			if nCurStar == 2 or nPreStar == 3 then
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 2)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			else
				local Text = ScriptGlobal_Format("#{SCGZ_180816_115}", 1)
				--BW_Match_End_RightBK_Lace_Text:SetText(Text)
				if nAddMJB > 0 then 
					BW_Match_End_RightBK_Lace_Text:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Lace_TextNum:SetText(Text)
				elseif nAddMJB == 0 then
					BW_Match_End_RightBK_Text6_1:SetText("#{SCGZ_180816_111}")
					BW_Match_End_RightBK_Text6_1Num:SetText(Text)
				end
			end
		end
	end
	--没升段
	if nCurMajorRank == nPreMajorRank and nCurMinorRank == nPreMinorRank then
		--青铜
		if nCurMajorRank == 1 then
			for i = 0,2 do
				g_Star3[i]:Show()
			end
			--升星了,先把星星都点亮，然后再新加的那个上面来个可爱的特效
			if nCurStar > nPreStar then
				if nCurStar-nPreStar == 1 then
					for i = 0,nCurStar-1 do
						g_Star3[i]:SetProperty("Image", g_ImageStar[1])
					end
					for i=nPreStar,nCurStar-1 do
						g_StarAnim3[i]:Show()
						g_StarAnim3[i]:SetProperty("Animate","LevelupStrars")
						g_StarAnim3[i]:Play(true)
						
					end
				end
			elseif nCurStar == nPreStar then --没加也没减
				for i = 0,nCurStar-1 do
					g_Star3[i]:SetProperty("Image", g_ImageStar[1])
				end
				
			end
		elseif nCurMajorRank == 2 then -- 白银
			for i = 0,3 do
				g_Star1[i]:Show()
				--PushDebugMessage(i)
			end
				--升星了,先把星星都点亮，然后再新加的那个上面来个可爱的特效
			if nCurStar > nPreStar then
				if nCurStar-nPreStar == 1 then
					for i = 0,nCurStar-1 do
						g_Star1[i]:SetProperty("Image", g_ImageStar[1])
					end
					for i=nPreStar,nCurStar-1 do
						g_StarAnim1[i]:Show()
						g_StarAnim1[i]:SetProperty("Animate","LevelupStrars")
						g_StarAnim1[i]:Play(true)
						
					end
				end
			elseif nCurStar == nPreStar then --没加也没减
				for i = 0,nCurStar-1 do
					g_Star1[i]:SetProperty("Image", g_ImageStar[1])
				end
				
			end
		elseif nCurMajorRank == 3 then -- 黄金
			for i = 0,4 do
				g_Star2[i]:Show()
			end
			--升星了,先把星星都点亮，然后再新加的那个上面来个可爱的特效
			if nCurStar > nPreStar then
				if nCurStar-nPreStar == 1 then
					for i = 0,nCurStar-1 do
						g_Star2[i]:SetProperty("Image", g_ImageStar[1])
					end
					for i=nPreStar,nCurStar-1 do
						g_StarAnim2[i]:Show()
						g_StarAnim2[i]:SetProperty("Animate","LevelupStrars")
						g_StarAnim2[i]:Play(true)
						
					end
				end
			elseif nCurStar == nPreStar then --没加也没减
				for i = 0,nCurStar-1 do
					g_Star2[i]:SetProperty("Image", g_ImageStar[1])
				end
				
			end
		elseif nCurMajorRank == 4 then -- 铂金
			for i = 0,5 do
				g_Star4[i]:Show()
			end
			--升星了,先把星星都点亮，然后再新加的那个上面来个可爱的特效
			if nCurStar > nPreStar then
				if nCurStar-nPreStar == 1 then
					for i = 0,nCurStar-1 do
						g_Star4[i]:SetProperty("Image", g_ImageStar[1])
					end
					for i=nPreStar,nCurStar-1 do
						g_StarAnim4[i]:Show()
						g_StarAnim4[i]:SetProperty("Animate","LevelupStrars")
						g_StarAnim4[i]:Play(true)
					end				
				end
			elseif nCurStar == nPreStar then --没加也没减
				for i = 0,nCurStar-1 do
					g_Star4[i]:SetProperty("Image", g_ImageStar[1])
				end
			end
		elseif nCurMajorRank == 5 then -- 钻石
			for i = 0,5 do
				g_Star5[i]:Show()
			end
			--升星了,先把星星都点亮，然后再新加的那个上面来个可爱的特效
			if nCurStar > nPreStar then
				if nCurStar-nPreStar == 1 then
					for i = 0,nCurStar-1 do
						g_Star5[i]:SetProperty("Image", g_ImageStar[1])
					end
					for i=nPreStar,nCurStar-1 do
						g_StarAnim5[i]:Show()
						g_StarAnim5[i]:SetProperty("Animate","LevelupStrars")
						g_StarAnim5[i]:Play(true)
					end				
				end
			elseif nCurStar == nPreStar then --没加也没减
				for i = 0,nCurStar-1 do
					g_Star5[i]:SetProperty("Image", g_ImageStar[1])
				end
			end
		elseif nCurMajorRank == 6 then
			if nCurStar > nPreStar then
				if nCurStar-nPreStar == 1 then
					BW_Match_End_Star3_1:Show()
					BW_Match_End_Star3_1:SetProperty("Image", g_ImageStar[1])
					BW_Match_End_Star3Text:SetText("#L"..nCurStar.."#L".."星")
					
					
					
				end
			elseif nCurStar == nPreStar then --没加也没减
				BW_Match_End_Star3_1:Show()
				BW_Match_End_Star3_1:SetProperty("Image", g_ImageStar[1])
				BW_Match_End_Star3Text:SetText("#L"..nCurStar.."#L".."星")
				
			end
		end
	--升段
	elseif nCurMajorRank > nPreMajorRank or (nCurMinorRank < nPreMinorRank and nCurMajorRank == nPreMajorRank) then
		g_CurMajorRank = nCurMajorRank
		-- 升到白银
			-- 升到白银
		if nCurMajorRank == 2 and nCurMajorRank > nPreMajorRank then
		
			g_UpType = 3
			-- 先给这小老弟儿的星星都加特效
			for i = 0,2 do
				g_Star3[i]:Show()
				g_Star3[i]:SetProperty("Image", g_ImageStar[1])
				g_StarAnim3[i]:Show()
				g_StarAnim3[i]:SetProperty("Animate","LevelupStrars")
				g_StarAnim3[i]:Play(true)
			end
			SetTimer("BW_Match_End","BW_Match_End_1to2Timer()", 1000)
		elseif nCurMajorRank == 3 and nCurMajorRank > nPreMajorRank then --升到黄金
			
			g_UpType = 3
			-- 先给这小老弟儿的星星都加特效
			for i = 0,3 do
				g_Star1[i]:Show()
				g_Star1[i]:SetProperty("Image", g_ImageStar[1])
				g_StarAnim1[i]:Show()
				g_StarAnim1[i]:SetProperty("Animate","LevelupStrars")
				g_StarAnim1[i]:Play(true)
			end
			SetTimer("BW_Match_End","BW_Match_End_2to3Timer()", 1000)
		elseif nCurMajorRank == 4 and nCurMajorRank > nPreMajorRank then	--升到白金
			
			g_UpType = 3
			-- 先给这小老弟儿的星星都加特效
			for i = 0,4 do
				g_Star2[i]:Show()
				g_Star2[i]:SetProperty("Image", g_ImageStar[1])
				g_StarAnim2[i]:Show()
				g_StarAnim2[i]:SetProperty("Animate","LevelupStrars")
				g_StarAnim2[i]:Play(true)
			end
			SetTimer("BW_Match_End","BW_Match_End_3to4Timer()", 1000)
		elseif nCurMajorRank == 5 and nCurMajorRank > nPreMajorRank then --升到钻石
			
			g_UpType = 3
			-- 先给这小老弟儿的星星都加特效
			for i = 0,5 do
				g_Star4[i]:Show()
				g_Star4[i]:SetProperty("Image", g_ImageStar[1])
				g_StarAnim4[i]:Show()
				g_StarAnim4[i]:SetProperty("Animate","LevelupStrars")
				g_StarAnim4[i]:Play(true)
			end
			SetTimer("BW_Match_End","BW_Match_End_4to5Timer()", 1000)
		elseif nCurMajorRank == 6 and nCurMajorRank > nPreMajorRank then --升到王者
			
			g_UpType = 3
			-- 先给这小老弟儿的星星都加特效
			for i = 0,5 do
				g_Star5[i]:Show()
				g_Star5[i]:SetProperty("Image", g_ImageStar[1])
				g_StarAnim5[i]:Show()
				g_StarAnim5[i]:SetProperty("Animate","LevelupStrars")
				g_StarAnim5[i]:Play(true)
			end
			SetTimer("BW_Match_End","BW_Match_End_5to6Timer()", 1000)
		-- 只升阶不升段，
		else
		
			if nCurMajorRank == 1 then
				g_CurMajorRank = nCurMajorRank
				
				g_UpType = 3
				-- 先给这小老弟儿的星星都加特效
				for i = 0,2 do
					g_Star3[i]:Show()
					g_Star3[i]:SetProperty("Image", g_ImageStar[1])
					g_StarAnim3[i]:Show()
					g_StarAnim3[i]:SetProperty("Animate","LevelupStrars")
					g_StarAnim3[i]:Play(true)
				end
				SetTimer("BW_Match_End","BW_Match_End_UpTimer()", 1000)
				
			elseif nCurMajorRank == 2  then
				g_CurMajorRank = nCurMajorRank
				
				g_UpType = 3
				-- 先给这小老弟儿的星星都加特效
				for i = 0,3 do
					g_Star1[i]:Show()
					g_Star1[i]:SetProperty("Image", g_ImageStar[1])
					g_StarAnim1[i]:Show()
					g_StarAnim1[i]:SetProperty("Animate","LevelupStrars")
					g_StarAnim1[i]:Play(true)
				end
				SetTimer("BW_Match_End","BW_Match_End_UpTimer()", 1000)
				
			elseif nCurMajorRank == 3  then
				g_CurMajorRank = nCurMajorRank
				
				g_UpType = 3
				-- 先给这小老弟儿的星星都加特效
				for i = 0,4 do
					g_Star2[i]:Show()
					g_Star2[i]:SetProperty("Image", g_ImageStar[1])
					g_StarAnim2[i]:Show()
					g_StarAnim2[i]:SetProperty("Animate","LevelupStrars")
					g_StarAnim2[i]:Play(true)
				end
				SetTimer("BW_Match_End","BW_Match_End_UpTimer()", 1000)	
				
			elseif nCurMajorRank == 4  then
				g_CurMajorRank = nCurMajorRank
				
				g_UpType = 3
				-- 先给这小老弟儿的星星都加特效
				for i = 0,5 do
					g_Star4[i]:Show()
					g_Star4[i]:SetProperty("Image", g_ImageStar[1])
					g_StarAnim4[i]:Show()
					g_StarAnim4[i]:SetProperty("Animate","LevelupStrars")
					g_StarAnim4[i]:Play(true)
				end
				SetTimer("BW_Match_End","BW_Match_End_UpTimer()", 1000)
				
			elseif nCurMajorRank == 5  then
				g_CurMajorRank = nCurMajorRank
				
				g_UpType = 3
				-- 先给这小老弟儿的星星都加特效
				for i = 0,5 do
					g_Star5[i]:Show()
					g_Star5[i]:SetProperty("Image", g_ImageStar[1])
					g_StarAnim5[i]:Show()
					g_StarAnim5[i]:SetProperty("Animate","LevelupStrars")
					g_StarAnim5[i]:Play(true)
				end
				SetTimer("BW_Match_End","BW_Match_End_UpTimer()", 1000)
			end
			
		
		end
	
	end
	
	

end

function BW_Match_End_Timer()
	g_Timer = g_Timer - 1 
	--PushDebugMessage(g_Timer)
	if g_Timer == 0 then
		KillTimer("BW_Match_End_Timer()")
		this:Hide()
	end
	BW_Match_End_RightBK_Text5:SetText(ScriptGlobal_Format("#{SCGZ_180816_88}", g_Timer))
end

function BW_Match_End_1to2Timer()
	g_BigUpTimer = g_BigUpTimer - 1 
	if g_BigUpTimer == 0 then
		
		KillTimer("BW_Match_End_1to2Timer()")
		return
	end
	if g_BigUpTimer == g_AllTime2 - g_StarUpTime then --播放升段动画,星星置为空星
		BW_Match_End_GoupAnimate:Show()
		BW_Match_End_StageBK_Image1Animate:Show()
		BW_Match_End_GoupAnimate:SetProperty("Animate","GoupFlash")
		BW_Match_End_StageBK_Image1Animate:SetProperty("Animate","LightUpFlash")
		BW_Match_End_GoupAnimate:Play(true)
		BW_Match_End_StageBK_Image1Animate:Play(true)	
	end
	
	-- 给星星播特效留x秒
	if g_BigUpTimer > g_AllTime2 - g_StarUpTime then
		return 
	elseif g_BigUpTimer > g_AllTime2 - g_StarUpTime - g_StarKongTime2 then --给升小段动画留时间
		if g_BigUpTimer == g_AllTime2 - g_StarUpTime then --播放升段动画,星星置为空星
			-- 把上个段位的都隐掉，调用新的控件
			for i = 0,2 do
				g_StarAnim3[i]:Hide()
				g_Star3[i]:Hide()
			end
			for i = 0,3 do
				g_Star1[i]:SetProperty("Image", g_ImageStar[2])
				g_Star1[i]:Show()
			end
		end
		return
	elseif g_BigUpTimer == g_AllTime2 - g_StarUpTime - g_StarKongTime2 then --给加的第一个星星加特效。
		g_Star1[0]:SetProperty("Image", g_ImageStar[1])
		g_StarAnim1[0]:Show()
		g_StarAnim1[0]:SetProperty("Animate","LevelupStrars")
		g_StarAnim1[0]:Play(true)
		
		KillTimer("BW_Match_End_1to2Timer()")
	end
	
	--切换段位图
	if g_BigUpTimer == g_AllTime2 - g_StarUpTime - g_StarKongTime2 then
		local MatchId = BWDH2018:GetMatchId()
		BW_Match_End_StageBK_Image:SetProperty("Image", g_Image_Duanwei[MatchId][2])
		
		BW_Match_End_StageBK_Text1:Show()
		BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[3]) -- 后面的数字是偏移量，前面的数字是当前的小段位
		-- 填充左边的数据
		local text2 = ScriptGlobal_Format("#{BWDH_180804_154}",  g_DuanWei1[2], g_DuanWei1[3+6])
		BW_Match_End_StageBK_Text2:SetText(text2)
	end
end

function BW_Match_End_2to3Timer()
	g_BigUpTimer = g_BigUpTimer - 1 
	if g_BigUpTimer == 0 then
		
		KillTimer("BW_Match_End_2to3Timer()")
		return
	end
	if g_BigUpTimer == g_AllTime2 - g_StarUpTime then --播放升段动画,星星置为空星
		BW_Match_End_GoupAnimate:Show()
		BW_Match_End_StageBK_Image1Animate:Show()
		BW_Match_End_GoupAnimate:SetProperty("Animate","GoupFlash")
		BW_Match_End_StageBK_Image1Animate:SetProperty("Animate","LightUpFlash")
		BW_Match_End_GoupAnimate:Play(true)
		BW_Match_End_StageBK_Image1Animate:Play(true)	
	end
	
	-- 给星星播特效留x秒
	if g_BigUpTimer > g_AllTime2 - g_StarUpTime then
		return 
	elseif g_BigUpTimer > g_AllTime2 - g_StarUpTime - g_StarKongTime2 then --给升小段动画留时间
		if g_BigUpTimer == g_AllTime2 - g_StarUpTime then --播放升段动画,星星置为空星
			-- 把上个段位的都隐掉，调用新的控件
			for i = 0,3 do
				g_StarAnim1[i]:Hide()
				g_Star1[i]:Hide()
			end
			for i = 0,4 do
				g_Star2[i]:SetProperty("Image", g_ImageStar[2])
				g_Star2[i]:Show()
			end
		end
		return
	elseif g_BigUpTimer == g_AllTime2 - g_StarUpTime - g_StarKongTime2 then --给加的第一个星星加特效。
		g_Star2[0]:SetProperty("Image", g_ImageStar[1])
		g_StarAnim2[0]:Show()
		g_StarAnim2[0]:SetProperty("Animate","LevelupStrars")
		g_StarAnim2[0]:Play(true)
		
		KillTimer("BW_Match_End_2to3Timer()")
	end
	
	--切换段位图
	if g_BigUpTimer == g_AllTime2 - g_StarUpTime - g_StarKongTime2 then
		local MatchId = BWDH2018:GetMatchId()
		BW_Match_End_StageBK_Image:SetProperty("Image", g_Image_Duanwei[MatchId][3])
		
		BW_Match_End_StageBK_Text1:Show()
		BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[3]) -- 后面的数字是偏移量，前面的数字是当前的小段位
		-- 填充左边的数据
		local text2 = ScriptGlobal_Format("#{BWDH_180804_154}",  g_DuanWei1[3], g_DuanWei1[3+6])
		BW_Match_End_StageBK_Text2:SetText(text2)
		--BW_Match_End_StageBK_Text2:SetText(g_DuanWei1[MatchId+12].." "..g_DuanWei1[3]..g_DuanWei1[3+6].."阶")
	end
	
end

function BW_Match_End_3to4Timer()
	g_BigUpTimer = g_BigUpTimer - 1 
	if g_BigUpTimer == 0 then
		
		KillTimer("BW_Match_End_3to4Timer()")
		return
	end
	if g_BigUpTimer == g_AllTime2 - g_StarUpTime then --播放升段动画,星星置为空星
		BW_Match_End_GoupAnimate:Show()
		BW_Match_End_StageBK_Image1Animate:Show()
		BW_Match_End_GoupAnimate:SetProperty("Animate","GoupFlash")
		BW_Match_End_StageBK_Image1Animate:SetProperty("Animate","LightUpFlash")
		BW_Match_End_GoupAnimate:Play(true)
		BW_Match_End_StageBK_Image1Animate:Play(true)	
	end

	-- 给星星播特效留x秒
	if g_BigUpTimer > g_AllTime2 - g_StarUpTime then
		return 
	elseif g_BigUpTimer > g_AllTime2 - g_StarUpTime - g_StarKongTime2 then --给升小段动画留时间
		if g_BigUpTimer == g_AllTime2 - g_StarUpTime then --播放升段动画,星星置为空星
			-- 把上个段位的都隐掉，调用新的控件
			for i = 0,4 do
				g_StarAnim2[i]:Hide()
				g_Star2[i]:Hide()
			end
			for i = 0,5 do
				g_Star4[i]:SetProperty("Image", g_ImageStar[2])
				g_Star4[i]:Show()
			end
		end
		return
	elseif g_BigUpTimer == g_AllTime2 - g_StarUpTime - g_StarKongTime2 then --给加的第一个星星加特效。
		g_Star4[0]:SetProperty("Image", g_ImageStar[1])
		g_StarAnim4[0]:Show()
		g_StarAnim4[0]:SetProperty("Animate","LevelupStrars")
		g_StarAnim4[0]:Play(true)
		
		KillTimer("BW_Match_End_3to4Timer()")
	end
	
	--切换段位图
	if g_BigUpTimer == g_AllTime2 - g_StarUpTime - g_StarKongTime2 then
		local MatchId = BWDH2018:GetMatchId()
		BW_Match_End_StageBK_Image:SetProperty("Image", g_Image_Duanwei[MatchId][4])
		
		BW_Match_End_StageBK_Text1:Show()
		BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[4]) -- 后面的数字是偏移量，前面的数字是当前的小段位
		-- 填充左边的数据
		--BW_Match_End_StageBK_Text2:SetText(g_DuanWei1[MatchId+12].." "..g_DuanWei1[4]..g_DuanWei1[3+6].."阶")
		local text2 = ScriptGlobal_Format("#{BWDH_180804_154}", g_DuanWei1[4], g_DuanWei1[4+6])
		BW_Match_End_StageBK_Text2:SetText(text2)
	end
	
end

function BW_Match_End_4to5Timer()
	g_BigUpTimer = g_BigUpTimer - 1 
	if g_BigUpTimer == 0 then
		
		KillTimer("BW_Match_End_4to5Timer()")
		return
	end
	if g_BigUpTimer == g_AllTime2 - g_StarUpTime then --播放升段动画,星星置为空星
		BW_Match_End_GoupAnimate:Show()
		BW_Match_End_StageBK_Image1Animate:Show()
		BW_Match_End_GoupAnimate:SetProperty("Animate","GoupFlash")
		BW_Match_End_StageBK_Image1Animate:SetProperty("Animate","LightUpFlash")
		BW_Match_End_GoupAnimate:Play(true)
		BW_Match_End_StageBK_Image1Animate:Play(true)	
	end
	
		-- 给星星播特效留x秒
		if g_BigUpTimer > g_AllTime2 - g_StarUpTime then
			return 
		elseif g_BigUpTimer > g_AllTime2 - g_StarUpTime - g_StarKongTime2 then --给升小段动画留时间
			if g_BigUpTimer == g_AllTime2 - g_StarUpTime then --播放升段动画,星星置为空星
				-- 把上个段位的都隐掉，调用新的控件
				for i = 0,5 do
					g_StarAnim4[i]:Hide()
					g_Star4[i]:Hide()
				end
				for i = 0,5 do
					g_Star5[i]:SetProperty("Image", g_ImageStar[2])
					g_Star5[i]:Show()
				end
			end
			return
		elseif g_BigUpTimer == g_AllTime2 - g_StarUpTime - g_StarKongTime2 then --给加的第一个星星加特效。
			g_Star5[0]:SetProperty("Image", g_ImageStar[1])
			g_StarAnim5[0]:Show()
			g_StarAnim5[0]:SetProperty("Animate","LevelupStrars")
			g_StarAnim5[0]:Play(true)
			
			KillTimer("BW_Match_End_4to5Timer()")
		end
	
	--切换段位图
	if g_BigUpTimer == g_AllTime2 - g_StarUpTime - g_StarKongTime2 then
		local MatchId = BWDH2018:GetMatchId()
		BW_Match_End_StageBK_Image:SetProperty("Image", g_Image_Duanwei[MatchId][5])
		
		BW_Match_End_StageBK_Text1:Show()
		BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[4]) -- 后面的数字是偏移量，前面的数字是当前的小段位
		-- 填充左边的数据
		--BW_Match_End_StageBK_Text2:SetText(g_DuanWei1[MatchId+12].." "..g_DuanWei1[5]..g_DuanWei1[4+6].."阶")
		local text2 = ScriptGlobal_Format("#{BWDH_180804_154}",  g_DuanWei1[5], g_DuanWei1[4+6])
		BW_Match_End_StageBK_Text2:SetText(text2)
	end
	
end

function BW_Match_End_5to6Timer()
	g_BigUpTimer = g_BigUpTimer - 1 
	if g_BigUpTimer == 0 then
		
		KillTimer("BW_Match_End_5to6Timer()")
		return
	end
	if g_BigUpTimer == g_AllTime2 - g_StarUpTime then --播放升段动画,星星置为空星
		BW_Match_End_GoupAnimate:Show()
		BW_Match_End_StageBK_Image1Animate:Show()
		BW_Match_End_GoupAnimate:SetProperty("Animate","GoupFlash")
		BW_Match_End_StageBK_Image1Animate:SetProperty("Animate","LightUpFlash")
		BW_Match_End_GoupAnimate:Play(true)
		BW_Match_End_StageBK_Image1Animate:Play(true)	
	end
	
	-- 给星星播特效留x秒
	if g_BigUpTimer > g_AllTime2 - g_StarUpTime then
		return 
	elseif g_BigUpTimer > g_AllTime2 - g_StarUpTime - g_StarKongTime2 then --给升小段动画留时间
		if g_BigUpTimer == g_AllTime2 - g_StarUpTime then --播放升段动画,星星置为空星
			-- 把上个段位的都隐掉，调用新的控件
			for i = 0,5 do
				g_StarAnim5[i]:Hide()
				g_Star5[i]:Hide()
			end
			BW_Match_End_Star3_1:Show()
			BW_Match_End_Star3_1:SetProperty("Image", g_ImageStar[2])
		end
		return
	elseif g_BigUpTimer == g_AllTime2 - g_StarUpTime - g_StarKongTime2 then --给加的第一个星星加特效。
		BW_Match_End_Star3_1:SetProperty("Image", g_ImageStar[1])
		BW_Match_End_Star3Text:SetText("#L".."1".."#L".."星")
		BW_Match_End_Star3_1Animate:Show()
		BW_Match_End_Star3_1Animate:SetProperty("Animate","LevelupStrars")
		BW_Match_End_Star3_1Animate:Play(true)
		
		KillTimer("BW_Match_End_5to6Timer()")
	end
	
	--切换段位图
	if g_BigUpTimer == g_AllTime2 - g_StarUpTime - g_StarKongTime2 then
		local MatchId = BWDH2018:GetMatchId()
		BW_Match_End_StageBK_Image:SetProperty("Image", g_Image_Duanwei[MatchId][6])
		
		BW_Match_End_StageBK_Text1:Hide()
		--BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[4]) -- 后面的数字是偏移量，前面的数字是当前的小段位
		-- 填充左边的数据
		--BW_Match_End_StageBK_Text2:SetText(g_DuanWei1[MatchId+12].." "..g_DuanWei1[6])--..g_DuanWei1[4+6].."阶")
		local text2 = ScriptGlobal_Format("#{BWDH_180804_155}",  g_DuanWei1[6])
		BW_Match_End_StageBK_Text2:SetText(text2)--..g_DuanWei1[nCurMinorRank+6].."阶")
	end
	
end





function BW_Match_End_UpTimer()
	
	g_UpTimer = g_UpTimer - 1 
	if g_UpTimer == 0 or g_UpType == -1 then
		
		KillTimer("BW_Match_End_UpTimer()")
		return
	end
	if g_CurMajorRank == 1 then
		if g_UpTimer == g_AllTime1 - g_StarUpTime then --播放升段动画,星星置为空星
			
			BW_Match_End_StageBK_Image1Animate:Show()
			BW_Match_End_StageBK_Image1Animate:SetProperty("Animate","LightUpFlash")		
			BW_Match_End_StageBK_Image1Animate:Play(true)	
		end
		
		-- 给星星播特效留x秒
		if g_UpTimer > g_AllTime1 - g_StarUpTime then
			return 
		elseif g_UpTimer > g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给升小段动画留时间
			if g_UpTimer == g_AllTime1 - g_StarUpTime then --播放升段动画,星星置为空星
				for i = 0,2 do
					g_StarAnim3[i]:Hide()
					g_Star3[i]:Hide()
				end
				for i = 0,2 do
					g_Star3[i]:SetProperty("Image", g_ImageStar[2])
					g_Star3[i]:Show()
				end
			end
			return
		elseif g_UpTimer == g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给加的第一个星星加特效。
			g_Star3[0]:SetProperty("Image", g_ImageStar[1])
			g_StarAnim3[0]:Show()
			g_StarAnim3[0]:SetProperty("Animate","LevelupStrars")
			g_StarAnim3[0]:Play(true)
			
			KillTimer("BW_Match_End_UpTimer()")
		end
		
		-- 切小段位
		if g_UpTimer == g_AllTime1 - g_StarUpTime  - g_StarKongTime1 then --给加的第一个星星加特效。
			local nPreYZScore,nYZScore,nMaxYZScore,nCurMajorRank,nCurMinorRank,nCurStar,nCurWeekAddMJB,nCurWeekMaxMJB,nAddMJB,nPreMaxYZScore,nPreMajorRank,nPreMinorRank,nPreStar,nBaseWinScore,nBaseLoseScore,nSw3GapScore,nConWinScore,nBWResult= BWDH2018:GetResultData()
			local MatchId = BWDH2018:GetMatchId()
			BW_Match_End_StageBK_Text1:Show()
			BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[nCurMinorRank]) -- 
			-- 填充左边的数据
			--BW_Match_End_StageBK_Text2:SetText(g_DuanWei1[MatchId+12].." "..g_DuanWei1[nCurMajorRank]..g_DuanWei1[nCurMinorRank+6].."阶")
			local text2 = ScriptGlobal_Format("#{BWDH_180804_154}", g_DuanWei1[nCurMajorRank], g_DuanWei1[nCurMinorRank+6])
			BW_Match_End_StageBK_Text2:SetText(text2)
		end
		
	elseif g_CurMajorRank == 2 then
		if g_UpTimer == g_AllTime1 - g_StarUpTime then --播放升段动画,星星置为空星
			
			BW_Match_End_StageBK_Image1Animate:Show()
			BW_Match_End_StageBK_Image1Animate:SetProperty("Animate","LightUpFlash")		
			BW_Match_End_StageBK_Image1Animate:Play(true)	
		end
		
		-- 给星星播特效留x秒
		if g_UpTimer > g_AllTime1 - g_StarUpTime then
			return 
		elseif g_UpTimer > g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给升小段动画留时间
			if g_UpTimer == g_AllTime1 - g_StarUpTime then --播放升段动画,星星置为空星
				for i = 0,3 do
					g_StarAnim1[i]:Hide()
					g_Star1[i]:Hide()
				end
				for i = 0,3 do
					g_Star1[i]:SetProperty("Image", g_ImageStar[2])
					g_Star1[i]:Show()
				end
			end
			return
		elseif g_UpTimer == g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给加的第一个星星加特效。
			g_Star1[0]:SetProperty("Image", g_ImageStar[1])
			g_StarAnim1[0]:Show()
			g_StarAnim1[0]:SetProperty("Animate","LevelupStrars")
			g_StarAnim1[0]:Play(true)
			
			KillTimer("BW_Match_End_UpTimer()")
		end
		
		
		-- 切小段位
		if g_UpTimer == g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给加的第一个星星加特效。
			local nPreYZScore,nYZScore,nMaxYZScore,nCurMajorRank,nCurMinorRank,nCurStar,nCurWeekAddMJB,nCurWeekMaxMJB,nAddMJB,nPreMaxYZScore,nPreMajorRank,nPreMinorRank,nPreStar,nBaseWinScore,nBaseLoseScore,nSw3GapScore,nConWinScore,nBWResult= BWDH2018:GetResultData()
			local MatchId = BWDH2018:GetMatchId()
			BW_Match_End_StageBK_Text1:Show()
			BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[nCurMinorRank]) -- 后面的数字是偏移量，前面的数字是当前的小段位
			-- 填充左边的数据
			--BW_Match_End_StageBK_Text2:SetText(g_DuanWei1[MatchId+12].." "..g_DuanWei1[nCurMajorRank]..g_DuanWei1[nCurMinorRank+6].."阶")
			local text2 = ScriptGlobal_Format("#{BWDH_180804_154}", g_DuanWei1[nCurMajorRank], g_DuanWei1[nCurMinorRank+6])
			BW_Match_End_StageBK_Text2:SetText(text2)
		end
	elseif g_CurMajorRank == 3 then
		if g_UpTimer == g_AllTime1 - g_StarUpTime then --播放升段动画,星星置为空星
			
			BW_Match_End_StageBK_Image1Animate:Show()
			BW_Match_End_StageBK_Image1Animate:SetProperty("Animate","LightUpFlash")		
			BW_Match_End_StageBK_Image1Animate:Play(true)	
		end
		
		-- 给星星播特效留x秒
		if g_UpTimer > g_AllTime1 - g_StarUpTime then
			return 
		elseif g_UpTimer > g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给升小段动画留时间
			if g_UpTimer == g_AllTime1 - g_StarUpTime then --播放升段动画,星星置为空星
				for i = 0,4 do
					g_StarAnim2[i]:Hide()
					g_Star2[i]:Hide()
				end
				for i = 0,4 do
					g_Star2[i]:SetProperty("Image", g_ImageStar[2])
					g_Star2[i]:Show()
				end
			end
			return
		elseif g_UpTimer == g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给加的第一个星星加特效。
			g_Star2[0]:SetProperty("Image", g_ImageStar[1])
			g_StarAnim2[0]:Show()
			g_StarAnim2[0]:SetProperty("Animate","LevelupStrars")
			g_StarAnim2[0]:Play(true)
			
			KillTimer("BW_Match_End_UpTimer()")
		end
		
		
		-- 切小段位
		if g_UpTimer == g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给加的第一个星星加特效。
			local nPreYZScore,nYZScore,nMaxYZScore,nCurMajorRank,nCurMinorRank,nCurStar,nCurWeekAddMJB,nCurWeekMaxMJB,nAddMJB,nPreMaxYZScore,nPreMajorRank,nPreMinorRank,nPreStar,nBaseWinScore,nBaseLoseScore,nSw3GapScore,nConWinScore,nBWResult= BWDH2018:GetResultData()
			local MatchId = BWDH2018:GetMatchId()
			BW_Match_End_StageBK_Text1:Show()
			BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[nCurMinorRank]) -- 后面的数字是偏移量，前面的数字是当前的小段位
			-- 填充左边的数据
			--BW_Match_End_StageBK_Text2:SetText(g_DuanWei1[MatchId+12].." "..g_DuanWei1[nCurMajorRank]..g_DuanWei1[nCurMinorRank+6].."阶")
			local text2 = ScriptGlobal_Format("#{BWDH_180804_154}", g_DuanWei1[nCurMajorRank], g_DuanWei1[nCurMinorRank+6])
			BW_Match_End_StageBK_Text2:SetText(text2)
		end
		
	elseif g_CurMajorRank == 4  then
		if g_UpTimer == g_AllTime1 - g_StarUpTime then --播放升段动画,星星置为空星
			
			BW_Match_End_StageBK_Image1Animate:Show()
			BW_Match_End_StageBK_Image1Animate:SetProperty("Animate","LightUpFlash")		
			BW_Match_End_StageBK_Image1Animate:Play(true)	
		end
		
		-- 给星星播特效留x秒
		if g_UpTimer > g_AllTime1 - g_StarUpTime then
			return 
		elseif g_UpTimer > g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给升小段动画留时间
			if g_UpTimer == g_AllTime1 - g_StarUpTime then --播放升段动画,星星置为空星
				for i = 0,5 do
					g_StarAnim4[i]:Hide()
					g_Star4[i]:Hide()
				end
				for i = 0,5 do
					g_Star4[i]:SetProperty("Image", g_ImageStar[2])
					g_Star4[i]:Show()
				end
			end
			return
		elseif g_UpTimer == g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给加的第一个星星加特效。
			g_Star4[0]:SetProperty("Image", g_ImageStar[1])
			g_StarAnim4[0]:Show()
			g_StarAnim4[0]:SetProperty("Animate","LevelupStrars")
			g_StarAnim4[0]:Play(true)
			
			KillTimer("BW_Match_End_UpTimer()")
		end
		
		-- 切小段位
		if g_UpTimer == g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给加的第一个星星加特效。
			local nPreYZScore,nYZScore,nMaxYZScore,nCurMajorRank,nCurMinorRank,nCurStar,nCurWeekAddMJB,nCurWeekMaxMJB,nAddMJB,nPreMaxYZScore,nPreMajorRank,nPreMinorRank,nPreStar,nBaseWinScore,nBaseLoseScore,nSw3GapScore,nConWinScore,nBWResult= BWDH2018:GetResultData()
			local MatchId = BWDH2018:GetMatchId()
			BW_Match_End_StageBK_Text1:Show()
			BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[nCurMinorRank]) -- 后面的数字是偏移量，前面的数字是当前的小段位
			-- 填充左边的数据
			--BW_Match_End_StageBK_Text2:SetText(g_DuanWei1[MatchId+12].." "..g_DuanWei1[nCurMajorRank]..g_DuanWei1[nCurMinorRank+6].."阶")
			local text2 = ScriptGlobal_Format("#{BWDH_180804_154}", g_DuanWei1[nCurMajorRank], g_DuanWei1[nCurMinorRank+6])
			BW_Match_End_StageBK_Text2:SetText(text2)
		end
	elseif g_CurMajorRank == 5  then
		if g_UpTimer == g_AllTime1 - g_StarUpTime then --播放升段动画,星星置为空星
			
			BW_Match_End_StageBK_Image1Animate:Show()
			BW_Match_End_StageBK_Image1Animate:SetProperty("Animate","LightUpFlash")		
			BW_Match_End_StageBK_Image1Animate:Play(true)	
		end
		
		-- 给星星播特效留x秒
		if g_UpTimer > g_AllTime1 - g_StarUpTime then
			return 
		elseif g_UpTimer > g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给升小段动画留时间
			if g_UpTimer == g_AllTime1 - g_StarUpTime then --播放升段动画,星星置为空星
				for i = 0,5 do
					g_StarAnim5[i]:Hide()
					g_Star5[i]:Hide()
				end
				for i = 0,5 do
					g_Star5[i]:SetProperty("Image", g_ImageStar[2])
					g_Star5[i]:Show()
				end
			end
			return
		elseif g_UpTimer == g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给加的第一个星星加特效。
			g_Star5[0]:SetProperty("Image", g_ImageStar[1])
			g_StarAnim5[0]:Show()
			g_StarAnim5[0]:SetProperty("Animate","LevelupStrars")
			g_StarAnim5[0]:Play(true)
			
			KillTimer("BW_Match_End_UpTimer()")
		end
		
		-- 切小段位
		if g_UpTimer == g_AllTime1 - g_StarUpTime - g_StarKongTime1 then --给加的第一个星星加特效。
			local nPreYZScore,nYZScore,nMaxYZScore,nCurMajorRank,nCurMinorRank,nCurStar,nCurWeekAddMJB,nCurWeekMaxMJB,nAddMJB,nPreMaxYZScore,nPreMajorRank,nPreMinorRank,nPreStar,nBaseWinScore,nBaseLoseScore,nSw3GapScore,nConWinScore,nBWResult= BWDH2018:GetResultData()
			local MatchId = BWDH2018:GetMatchId()
			BW_Match_End_StageBK_Text1:Show()
			BW_Match_End_StageBK_Text1:SetProperty("Image", g_Image_Number[nCurMinorRank]) -- 后面的数字是偏移量，前面的数字是当前的小段位
			-- 填充左边的数据
			--BW_Match_End_StageBK_Text2:SetText(g_DuanWei1[MatchId+12].." "..g_DuanWei1[nCurMajorRank]..g_DuanWei1[nCurMinorRank+6].."阶")
			local text2 = ScriptGlobal_Format("#{BWDH_180804_154}", g_DuanWei1[nCurMajorRank], g_DuanWei1[nCurMinorRank+6])
			BW_Match_End_StageBK_Text2:SetText(text2)
		end
	end
	
end

