local g_BW_NewPlay_Frame_UnifiedPosition;

local g_BW_NewPlay_Star3 = {} --3颗星星
local g_BW_NewPlay_Star4 = {} --4颗星星
local g_BW_NewPlay_Star2 = {} --2颗星星

local g_Duanwei1_Image = {
	[0] = { 
		[1] = "set:BW_Match20 image:BW_que1",
		[2] = "set:BW_Match20 image:BW_que2",
		[3] = "set:BW_Match20 image:BW_que3",
		[4] = "set:BW_Match20 image:BW_que4",
		[5] = "set:BW_Match20 image:BW_que5",
		--[6] = "set:BW_Match20 image:BW_que6",
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

local g_Duanwei1_name = {
	[1] = "#{BWDH_180804_131}",
	[2] = "#{BWDH_180804_132}",
	[3] = "#{BWDH_180804_133}",
	[4] = "#{BWDH_180804_134}",
	[5] = "#{BWDH_180804_135}",
	[6] = "#{BWDH_180804_136}",
}

local g_Duanwei2_Info = {
	[1] = {image="set:BW_Match1 image:Number1", name="#{BWDH_180804_153}"},
	[2] = {image="set:BW_Match1 image:Number2", name="#{BWDH_180804_152}"},
	[3] = {image="set:BW_Match1 image:Number3", name="#{BWDH_180804_151}"},
	[4] = {image="set:BW_Match1 image:Number4", name="#{BWDH_180804_150}"},
	[5] = {image="set:BW_Match1 image:Number5", name="#{BWDH_180804_149}"},
}

local g_FightLevel = {
	[0] = {image="set:BW_Match19 image:CraneLevel"},
	[1] = {image="set:BW_Match6 image:EagleLevle"},
	[2] = {image="set:BW_Match6 image:DragonLevel"},
	[3] = {image="set:BW_Match21 image:KunLevel"},
	}

local g_Bright_Stars = "set:BW_Match1 image:Bright_Stars"
local g_Gray_Stars = "set:BW_Match1 image:Gray_Stars"

local g_DwWangzhe = 6

local g_PrizeInfo = {}

local g_ActionBtn = {}
local g_BarList = {}

function BW_NewPlay_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BW_NewPlay_OnLoad()
  g_BW_NewPlay_Frame_UnifiedPosition = BW_NewPlay_Frame:GetProperty("UnifiedPosition");

  g_BW_NewPlay_Star3[1] = BW_NewPlay_Star1
  g_BW_NewPlay_Star3[2] = BW_NewPlay_Star2
  g_BW_NewPlay_Star3[3] = BW_NewPlay_Star3

  g_BW_NewPlay_Star4[1] = BW_NewPlay_Star1_1
  g_BW_NewPlay_Star4[2] = BW_NewPlay_Star1_2
  g_BW_NewPlay_Star4[3] = BW_NewPlay_Star1_3
  g_BW_NewPlay_Star4[4] = BW_NewPlay_Star1_4

  g_BW_NewPlay_Star2[1] = BW_NewPlay_Star2_1
  g_BW_NewPlay_Star2[2] = BW_NewPlay_Star2_2
end

-- OnEvent
function BW_NewPlay_OnEvent(event)
	--
	if ( event == "UI_COMMAND"  and tonumber( arg0 ) == 29153002) then

		if (this:IsVisible()) then
			BW_NewPlay_CloseWindow()
		end
			
		local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
		if levelIndex < 0 or levelIndex >= BWDH2018:GetMaxLevelIndex() then
			return
		end

		BW_NewPlay_Init()
		BW_NewPlay_Update_Left( )
		BW_NewPlay_Update_Right( )

		this:Show()

	elseif ( event == "UI_COMMAND"  and tonumber( arg0 ) == 29153003 ) then --更新界面

		if (this:IsVisible() == false) then
			return
		end
			
		BW_NewPlay_Update_Award( )
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		BW_NewPlay_CloseWindow()

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		BW_NewPlay_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BW_NewPlay_Frame_On_ResetPos()
	end
end

function BW_NewPlay_Init( )

	--左侧数据初始化
	BW_NewPlay_Left_Text1:SetText("")
	BW_NewPlay_Left_Text2:SetText("")
	BW_NewPlay_StarSet:Hide()
	BW_NewPlay_StarSet1:Hide()
	BW_NewPlay_StarSet3:Hide()
	BW_NewPlay_StarSet2:Hide()

	BW_NewPlay_Line1:Hide()
	BW_NewPlay_Line2:Hide()
	BW_NewPlay_Line3:Hide()
	BW_NewPlay_Line4:Hide()
	
	--右侧数据初始化
	BW_NewPlay_Right_Text2:SetText("")
	BW_NewPlay_Right_Button_tips:Hide()
	
	for i = 1, table.getn(g_ActionBtn) do 
		if g_ActionBtn[i] ~= nil then
			g_ActionBtn[i]:SetActionItem(-1)
			g_ActionBtn[i] = nil
		end
	end
	
	--g_BarList
	for i = 1, table.getn(g_BarList) do 
		if g_BarList[i] ~= nil then
			g_BarList[i] = nil
		end
	end
	
	BW_NewPlay_Right_Lace:Clear()
	
	BW_NewPlay_Right_Button_Image:Hide()

end


function BW_NewPlay_Update_Left(  )
	
	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )	
	BW_NewPlay_Client_FrameLeftTitle:SetProperty("Image", g_FightLevel[levelIndex].image)
	
	--大段位
	local nCurDuanWei1 = Player:Lua_GetXbwData_2018( "CuruanWei1" )
	BW_NewPlay_Left_Image:SetProperty("Image", g_Duanwei1_Image[levelIndex][nCurDuanWei1])

	--小段位
	local nCurDuanWei2 = Player:Lua_GetXbwData_2018( "CuruanWei2" )
	if nCurDuanWei1 ~= g_DwWangzhe then
		BW_NewPlay_Left_Text1:SetProperty("Image", g_Duanwei2_Info[nCurDuanWei2].image)
		BW_NewPlay_Left_Text1:Show()
	else
		BW_NewPlay_Left_Text1:Hide()
	end

	local text2 = ""
	if nCurDuanWei1 < g_DwWangzhe then
		text2 = ScriptGlobal_Format("#{BWDH_180804_154}", g_Duanwei1_name[nCurDuanWei1], g_Duanwei2_Info[nCurDuanWei2].name)
	else
		text2 = "#{BWDH_180804_155}"
	end
	BW_NewPlay_Left_Text2:SetText(text2)

	--星星
	local nCurDuanWei3 = Player:Lua_GetXbwData_2018( "CuruanWei3" )
	if nCurDuanWei3 == nil then
		return
	end

	local nMaxDuanWei3 = BWDH2018:GetXbwDuanweinfo2018(nCurDuanWei1, nCurDuanWei2)
	if  nCurDuanWei1 == g_DwWangzhe then --王者
		BW_NewPlay_StarSet3:Show()
		BW_NewPlay_Star3_1:SetProperty("Image", g_Bright_Stars)
		BW_NewPlay_Star3_1:SetToolTip("#{BWDH_180804_31}")
		BW_NewPlay_Star3Text:SetText(tostring(nCurDuanWei3))

	elseif nMaxDuanWei3 == 2 then
		BW_NewPlay_StarSet2:Show()
		for i=1,nMaxDuanWei3 do
			if i <= nCurDuanWei3 then
				g_BW_NewPlay_Star2[i]:SetProperty("Image", g_Bright_Stars)
			else
				g_BW_NewPlay_Star2[i]:SetProperty("Image", g_Gray_Stars)
			end
			g_BW_NewPlay_Star2[i]:SetToolTip("#{BWDH_180804_31}")
		end

	elseif nMaxDuanWei3 == 3 then
		BW_NewPlay_StarSet:Show()
		for i=1,nMaxDuanWei3 do
			if i <= nCurDuanWei3 then
				g_BW_NewPlay_Star3[i]:SetProperty("Image", g_Bright_Stars)
			else
				g_BW_NewPlay_Star3[i]:SetProperty("Image", g_Gray_Stars)
			end
			g_BW_NewPlay_Star3[i]:SetToolTip("#{BWDH_180804_31}")
		end

	elseif nMaxDuanWei3 == 4 then
		BW_NewPlay_StarSet1:Show()
		for i=1,nMaxDuanWei3 do
			if i <= nCurDuanWei3 then
				g_BW_NewPlay_Star4[i]:SetProperty("Image", g_Bright_Stars)
			else
				g_BW_NewPlay_Star4[i]:SetProperty("Image", g_Gray_Stars)
			end
			g_BW_NewPlay_Star4[i]:SetToolTip("#{BWDH_180804_31}")
		end

	end

	--武誉值
	-- local nDuanWeiScore = Player:Lua_GetXbwData_2018( "DuanWeiScore" )
	-- local text7 = ScriptGlobal_Format("#{SCGZ_180816_107}", tostring(nDuanWeiScore))
	-- BW_NewPlay_RightBK_Text1:SetText(text7)


	-- if nMaxScore == 120 then
		-- BW_NewPlay_Line1:Show()
	-- elseif nMaxScore == 240 or nMaxScore == 450 then
		-- BW_NewPlay_Line2:Show()
	-- elseif nMaxScore == 1000 then
		-- BW_NewPlay_Line3:Show()
	-- elseif nMaxScore == 1500 then
		-- BW_NewPlay_Line4:Show()
	-- end

	-- BW_NewPlay_Progress:SetProgress(nDuanWeiScore, nMaxScore)

	-- BW_NewPlay_ProgressWindowText:SetText(0)
	-- BW_NewPlay_ProgressWindowText1:SetText(nMaxScore)

	-- if nDuanWeiScore >= nThresHold then
		-- local tips = ScriptGlobal_Format("#{BWDH_180804_202}", nThresHold)
		-- BW_NewPlay_Progress:SetToolTip(tips)
	-- else
		-- local tips = ScriptGlobal_Format("#{BWDH_180804_203}", nThresHold)
		-- BW_NewPlay_Progress:SetToolTip(tips)
	-- end
end


function BW_NewPlay_Update_Right(  )
	
	--段位奖励
	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	local nSeasonHighDuanWei = Player:Lua_GetXbwSeasonHighDuanWei_2018(1, levelIndex, 0)
		
	local bGetGift0 = Get_XParam_INT(0) --神剑奖励
	if nSeasonHighDuanWei >= g_DwWangzhe then
		BW_NewPlay_Right_Text2:SetText("#{SJCC_191011_10}")
		if bGetGift0 <= 0 then
			BW_NewPlay_Right_Button_tips:Show()
			BW_NewPlay_Right_Button:Enable()
		else
			BW_NewPlay_Right_Button_Image:Show()
			BW_NewPlay_Right_Button:Disable()
		end
	elseif bGetGift0 >= 1 then
		BW_NewPlay_Right_Text2:SetText("#{SJCC_191011_10}")
		BW_NewPlay_Right_Button_Image:Show()
		BW_NewPlay_Right_Button:Disable()
	else
		BW_NewPlay_Right_Text2:SetText("#{SJCC_191011_09}")
	end
	BW_NewPlay_Right_Button:SetToolTip("#{SJCC_191011_11}")
	
	--参与奖励
	g_PrizeInfo = {}
	
	g_PrizeInfo = 
	{
		[1] = {
			id = 1,
			key = "totalWin",
			title = "#{SJCC_191011_18}",
			desc = "#{SJCC_191011_19}",
			count = 1,
			awardItem = 38002595,
			awardNum = 1,
		},
	
		[2] = {
			id = 2,
			key = "totalWin",
			title = "#{SJCC_191011_20}",
			desc = "#{SJCC_191011_21}",
			count = 3,
			awardItem = 38002595,
			awardNum = 2,
		},
	
		[3] = {
			id = 3,
			key = "totalWin",
			title = "#{SJCC_191011_22}",
			desc = "#{SJCC_191011_23}",
			count = 7,
			awardItem = 38002595,
			awardNum = 3,
		},
	
		[4] = {
			id = 4,
			key = "continueWin",
			title = "#{SJCC_191011_24}",
			desc = "#{SJCC_191011_25}",
			count = 3,
			awardItem = 39920565,
			awardNum = 2,
		},
	
		[5] = {
			id = 5,
			key = "continueWin",
			title = "#{SJCC_191011_26}",
			desc = "#{SJCC_191011_27}",
			count = 7,
			awardItem = 38004039,
			awardNum = 1,
		},
	
		[6] = {
			id = 6,
			key = "parCnt",
			title = "#{SJCC_191011_28}",
			desc = "#{SJCC_191011_29}",
			count = 10,
			awardItem = 38004040,
			awardNum = 1,
		},
	}
	
	--	排序规则：
		--已完成且未领取奖励的任务置顶
		--已领取奖励的任务置于底部
		--其余按照默认的任务顺序排序
	
	--排序
	local tableLen = table.getn(g_PrizeInfo)
	for index = 1, tableLen - 1 do
		
		for j = 1, tableLen - index do
	
			local bGetGiftI = Get_XParam_INT( g_PrizeInfo[j].id )	
			local bGetGiftII = Get_XParam_INT( g_PrizeInfo[j + 1].id )
			
			--已领取奖励的任务置于底部
			if bGetGiftI >= 1 and bGetGiftII <= 0 then
				BW_NewPlay_OnSwitchPrize( j, j + 1 );
			end
			
			--已完成且未领取奖励的任务置顶
			if bGetGiftI <= 0 and bGetGiftII <= 0 then
				
				local parCntI = 0
				local conditionI = g_PrizeInfo[j]
				if conditionI.key == "totalWin" then
					parCntI = Player:Lua_GetXbwData_2018( "CurWeekWinCnt" )
				end
	
				if conditionI.key == "continueWin" then
					parCntI = Player:Lua_GetXbwData_2018( "CurWeekHighConWinCnt" )
				end

				if conditionI.key == "parCnt" then
					parCntI = Player:Lua_GetXbwData_2018( "CurWeekTotalCnt" )
				end
		
				local haveFinishI = 0
				if parCntI >= conditionI.count then
					haveFinishI = 1
				end
			
				local parCntII = 0
				local conditionII = g_PrizeInfo[j + 1]
				if conditionII.key == "totalWin" then
					parCntII = Player:Lua_GetXbwData_2018( "CurWeekWinCnt" )
				end
	
				if conditionII.key == "continueWin" then
					parCntII = Player:Lua_GetXbwData_2018( "CurWeekHighConWinCnt" )
				end

				if conditionII.key == "parCnt" then
					parCntII = Player:Lua_GetXbwData_2018( "CurWeekTotalCnt" )
				end
				
				local haveFinishII = 0
				if parCntII >= conditionII.count then
					haveFinishII = 1
				end
		
				if haveFinishI <= 0 and haveFinishII >= 1 then
					BW_NewPlay_OnSwitchPrize( j, j + 1 );
				end
			end
			
		end
	end
	
	--显示
	for index=1, table.getn(g_PrizeInfo) do
		BW_NewPlay_AddAwardItem( index )
	end
end

-- 交换
function BW_NewPlay_OnSwitchPrize( i, j )
	local PrizeData = g_PrizeInfo[i];
	g_PrizeInfo[i] = g_PrizeInfo[j];
	g_PrizeInfo[j] = PrizeData;
end

--增加一个奖励项
function BW_NewPlay_AddAwardItem( index )
	if g_PrizeInfo[index] == nil then
		return
	end
	
	local bar = BW_NewPlay_Right_Lace:AddChild("BW_NewPlay_RightAItem1")
	if not bar then
    	return
	end
	
	--参与次数
	local parCnt = 0
	local condition = g_PrizeInfo[index]
	if condition.key == "totalWin" then
		parCnt = Player:Lua_GetXbwData_2018( "CurWeekWinCnt" )
	end
	
	if condition.key == "continueWin" then
		parCnt = Player:Lua_GetXbwData_2018( "CurWeekHighConWinCnt" )
	end

	if condition.key == "parCnt" then
		parCnt = Player:Lua_GetXbwData_2018( "CurWeekTotalCnt" )
	end
	
	--进度显示
	bar:GetSubItem("BW_NewPlay_RightProgress"):SetProgress(parCnt, g_PrizeInfo[index].count)
	
	local jinduText = ScriptGlobal_Format( "#{SJCC_191011_30}", parCnt, g_PrizeInfo[index].count )
	bar:GetSubItem("BW_NewPlay_RightProgress_Jindu"):SetText(jinduText)
	
	bar:GetSubItem("BW_NewPlay_RightAItem1_Name"):SetText( g_PrizeInfo[index].title )
	bar:GetSubItem("BW_NewPlay_RightAItem1_Con"):SetText( g_PrizeInfo[index].desc )
	
	local theAction = DataPool:CreateActionItemForShow(g_PrizeInfo[index].awardItem, g_PrizeInfo[index].awardNum)
	if theAction:GetID() ~= 0 then
		local oActionBtn = bar:GetSubItem("BW_NewPlay_RightAItem1_Icon")
		if oActionBtn ~= nil then
			oActionBtn:SetActionItem( theAction:GetID() )
			oActionBtn:SetEvent("Clicked", string.format("BW_NewPlay_GetAward(%d)", g_PrizeInfo[index].id))
			g_ActionBtn[index] = oActionBtn
		end
	end

	--红点/对勾
	local redButton = bar:GetSubItem("BW_NewPlay_RightAItem1_IconMark_tips")
	local haveGetButton = bar:GetSubItem("BW_NewPlay_RightAItem1_IconMark")
	
	local bGetGift = Get_XParam_INT( g_PrizeInfo[index].id )
	if parCnt >= g_PrizeInfo[index].count then
		if bGetGift <= 0 then
			redButton:Show()
			haveGetButton:Hide()
		else
			redButton:Hide()
			haveGetButton:Show()
		end
	else
		redButton:Hide()
		haveGetButton:Hide()
	end
	
	g_BarList[index] = bar
end


--更新一个奖励项
function BW_NewPlay_UpdateAwardItem( index )
	if g_PrizeInfo[index] == nil then
		return
	end
	
	local bar = g_BarList[index]
	if not bar then
    	return
	end
	
	--参与次数
	local parCnt = 0
	local condition = g_PrizeInfo[index]
	if condition.key == "totalWin" then
		parCnt = Player:Lua_GetXbwData_2018( "CurWeekWinCnt" )
	end
	
	if condition.key == "continueWin" then
		parCnt = Player:Lua_GetXbwData_2018( "CurWeekHighConWinCnt" )
	end

	if condition.key == "parCnt" then
		parCnt = Player:Lua_GetXbwData_2018( "CurWeekTotalCnt" )
	end

	--红点/对勾
	local redButton = bar:GetSubItem("BW_NewPlay_RightAItem1_IconMark_tips")
	local haveGetButton = bar:GetSubItem("BW_NewPlay_RightAItem1_IconMark")
	
	local bGetGift = Get_XParam_INT( g_PrizeInfo[index].id )
	if parCnt >= g_PrizeInfo[index].count then
		if bGetGift <= 0 then
			redButton:Show()
			haveGetButton:Hide()
		else
			redButton:Hide()
			haveGetButton:Show()
		end
	else
		redButton:Hide()
		haveGetButton:Hide()
	end
	
	g_BarList[index] = bar
end

--更新领奖部分
function BW_NewPlay_Update_Award()
	
	--段位奖励
	local levelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	local nSeasonHighDuanWei = Player:Lua_GetXbwSeasonHighDuanWei_2018(1, levelIndex, 0)
		
	local bGetGift0 = Get_XParam_INT(0) --神剑奖励
	if nSeasonHighDuanWei >= g_DwWangzhe then
		BW_NewPlay_Right_Text2:SetText("#{SJCC_191011_10}")
		if bGetGift0 <= 0 then
			BW_NewPlay_Right_Button_tips:Show()
			BW_NewPlay_Right_Button_Image:Hide()
			BW_NewPlay_Right_Button:Enable()
		else
			BW_NewPlay_Right_Button_tips:Hide()
			BW_NewPlay_Right_Button_Image:Show()
			BW_NewPlay_Right_Button:Disable()
		end
	elseif bGetGift0 >= 1 then
		BW_NewPlay_Right_Text2:SetText("#{SJCC_191011_10}")
		BW_NewPlay_Right_Button_tips:Hide()
		BW_NewPlay_Right_Button_Image:Show()
		BW_NewPlay_Right_Button:Disable()
	else
		BW_NewPlay_Right_Text2:SetText("#{SJCC_191011_09}")
	end
	BW_NewPlay_Right_Button:SetToolTip("#{SJCC_191011_11}")
	
	for index=1, table.getn(g_PrizeInfo) do
		BW_NewPlay_UpdateAwardItem(index)
	end
	
end

--领奖
function BW_NewPlay_GetAward( index )
	if index == nil then
		return
	end
	
	--- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{FCMX_90609_22}" )
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TryToTakePrize")
		Set_XSCRIPT_ScriptID(291530)
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

function BW_NewPlay_CloseWindow()
  this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BW_NewPlay_Frame_On_ResetPos()
  BW_NewPlay_Frame:SetProperty("UnifiedPosition", g_BW_NewPlay_Frame_UnifiedPosition);
end



function BW_NewPlay_HelpInfo_Clicked()
	PushEvent( "OPEN_HUODONGTEXT_HELP", "BW_NewPlay_Help", "#{SJCC_191011_05}" )
end


function BW_NewPlay_HelpScore_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientCallFunction")
		Set_XSCRIPT_ScriptID(892895)
		Set_XSCRIPT_Parameter(0, -1)
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function BW_NewPlay_HelpLevel_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientCallFunction")
		Set_XSCRIPT_ScriptID(892895)
		Set_XSCRIPT_Parameter(0, -1)
		Set_XSCRIPT_Parameter(1, 3)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

