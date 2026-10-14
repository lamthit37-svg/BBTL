local g_BW_Match_StageOther_Frame_UnifiedPosition;

local g_BW_Match_StageOther_Star3 = {} --3颗星星
local g_BW_Match_StageOther_Star4 = {} --4颗星星
--local g_BW_Match_StageOther_Star2 = {} --2颗星星
local g_BW_Match_StageOther_Star6 = {} --6颗星星
local g_BW_Match_StageOther_Star8 = {} --8颗星星
local g_BW_Match_StageOther_Star5 = {} --5颗星星

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
	[0] = {nameNoColor = "#{BWDH_210908_01}", image="set:BW_Match20 image:queLevel"},
	[1] = {nameNoColor = "#{BWDH_180804_13}", image="set:BW_Match6 image:EagleLevle"},
	[2] = {nameNoColor = "#{BWDH_180804_14}", image="set:BW_Match6 image:DragonLevel"},
	[3] = {nameNoColor = "#{BWDH_250113_06}", image="set:BW_Match21 image:KunLevel"},
	}


local g_Bright_Stars = "set:BW_Match1 image:Bright_Stars"
local g_Gray_Stars = "set:BW_Match1 image:Gray_Stars"

local g_DuanWei_Value =
{
	ShiJian = 1, -- 试剑
	TingJian = 2, -- 听剑
	DouJian = 3, -- 斗剑
	YuJian = 4, -- 御剑
	YiJian = 5, -- 意剑
	ShenJian = 6, -- 神剑
}

function BW_Match_StageOther_PreLoad()
	this:RegisterEvent("XBW_OTHER_DETAIL_UPDATE_2018", true)

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BW_Match_StageOther_OnLoad()
	g_BW_Match_StageOther_Frame_UnifiedPosition = BW_Match_StageOther_Frame:GetProperty("UnifiedPosition");

	g_BW_Match_StageOther_Star3[1] = BW_Match_StageOther_Star1
	g_BW_Match_StageOther_Star3[2] = BW_Match_StageOther_Star2
	g_BW_Match_StageOther_Star3[3] = BW_Match_StageOther_Star3

	g_BW_Match_StageOther_Star4[1] = BW_Match_StageOther_Star1_1
	g_BW_Match_StageOther_Star4[2] = BW_Match_StageOther_Star1_2
	g_BW_Match_StageOther_Star4[3] = BW_Match_StageOther_Star1_3
	g_BW_Match_StageOther_Star4[4] = BW_Match_StageOther_Star1_4

  -- g_BW_Match_StageOther_Star2[1] = BW_Match_StageOther_Star2_1
  -- g_BW_Match_StageOther_Star2[2] = BW_Match_StageOther_Star2_2

	g_BW_Match_StageOther_Star6[1] = BW_Match_StageOther_Star6_1
	g_BW_Match_StageOther_Star6[2] = BW_Match_StageOther_Star6_2
	g_BW_Match_StageOther_Star6[3] = BW_Match_StageOther_Star6_3
	g_BW_Match_StageOther_Star6[4] = BW_Match_StageOther_Star6_4
	g_BW_Match_StageOther_Star6[5] = BW_Match_StageOther_Star6_5
	g_BW_Match_StageOther_Star6[6] = BW_Match_StageOther_Star6_6

	g_BW_Match_StageOther_Star8[1] = BW_Match_StageOther_Star8_1
	g_BW_Match_StageOther_Star8[2] = BW_Match_StageOther_Star8_2
	g_BW_Match_StageOther_Star8[3] = BW_Match_StageOther_Star8_3
	g_BW_Match_StageOther_Star8[4] = BW_Match_StageOther_Star8_4
	g_BW_Match_StageOther_Star8[5] = BW_Match_StageOther_Star8_5
	g_BW_Match_StageOther_Star8[6] = BW_Match_StageOther_Star8_6
	g_BW_Match_StageOther_Star8[7] = BW_Match_StageOther_Star8_7
	g_BW_Match_StageOther_Star8[8] = BW_Match_StageOther_Star8_8

	g_BW_Match_StageOther_Star5[1] = BW_Match_StageOther_Star5_1
	g_BW_Match_StageOther_Star5[2] = BW_Match_StageOther_Star5_2
	g_BW_Match_StageOther_Star5[3] = BW_Match_StageOther_Star5_3
	g_BW_Match_StageOther_Star5[4] = BW_Match_StageOther_Star5_4
	g_BW_Match_StageOther_Star5[5] = BW_Match_StageOther_Star5_5
end

-- OnEvent
function BW_Match_StageOther_OnEvent(event)
	--
	if ( event == "XBW_OTHER_DETAIL_UPDATE_2018" ) then
		local obj_id = CachedTarget:GetData("NPCID", 1)
		-- if (type(obj_id) ~= "number") then
		-- 	PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
		-- 	return
		-- end
		-- this:CareObject(obj_id, 1)

		local levelIndex = Player:Lua_GetOtherXbwData_2018( "LevelIndex" )
		if levelIndex < 0 or levelIndex >= BWDH2018:GetMaxLevelIndex() then
			return
		end

		BW_Match_StageOther_UpdateTarget_Top( )
		BW_Match_StageOther_UpdateTarget_Other( )
		this:Show()


	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		BW_Match_StageOtherFrame_CloseWindow()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		BW_Match_StageOther_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BW_Match_StageOther_Frame_On_ResetPos()
	end
end

function BW_Match_StageOther_Init( )
	BW_Match_StageOther_DragTitleBK:SetText("")

	BW_Match_StageOther_StageLeft_Text1:SetText("")
	BW_Match_StageOther_StageLeft_Text2:SetText("")
	BW_Match_StageOther_StarSet:Hide()
	BW_Match_StageOther_StarSet1:Hide()
	BW_Match_StageOther_StarSet3:Hide()
	--BW_Match_StageOther_StarSet2:Hide()
	BW_Match_StageOther_StarSet6:Hide()
	BW_Match_StageOther_StarSet8:Hide()
	BW_Match_StageOther_StarSet5:Hide()

	BW_Match_StageOther_StageRight_Text1_1:SetText("")
	BW_Match_StageOther_StageRight_Text2_1:SetText("")
	BW_Match_StageOther_StageRight_Text3_1:SetText("")
	BW_Match_StageOther_StageRight_Text4_1:SetText("")
end


function BW_Match_StageOther_UpdateTarget_Top(  )

	--BW_Match_StageOther_StageRight_Image7:Hide()
	--BW_Match_StageOther_StageRight_Image8:Show()

	BW_Match_StageOther_Client_FrameTitle:SetText("")
	BW_Match_StageOther_StageRight_Text7:SetText("")
	--BW_Match_StageOther_StageRight_Text8_1:SetText("")
	--BW_Match_StageOther_StageRightTop_Help:Hide()
	--BW_Match_StageOther_Have:Hide()

	--本赛季将于x年x月x日结束
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nIndex,seasonBeg,weekAwardExEnd,seasonEnd = BWDH2018:GetXbwGetRecentSeasonInfo2018(curDay)

	if nIndex == nil then
		local textTitle = ScriptGlobal_Format("#{BWDH_180804_192}", tostring(1))
		BW_Match_StageOther_Client_FrameTitle:SetText(textTitle)
		BW_Match_StageOther_StageRight_Text7:SetText("#{BWDH_180804_184}")

	elseif curDay <= seasonEnd then
		local year = math.floor(seasonEnd/10000)
		local month = math.mod( math.floor( seasonEnd / 100 ), 100 )
		local day = math.mod( seasonEnd, 100 )

		local textTitle = ScriptGlobal_Format("#{BWDH_180804_192}", tostring(nIndex+1))
		BW_Match_StageOther_Client_FrameTitle:SetText(textTitle)

		local text3 = ScriptGlobal_Format("#{BWDH_180804_27}", tostring(year), tostring(month), tostring(day))
		BW_Match_StageOther_StageRight_Text7:SetText(text3)
		--BW_Match_StageOther_StageRight_Text7:SetText("")
	else
		local textTitle = ScriptGlobal_Format("#{BWDH_180804_192}", tostring(nIndex+1))
		BW_Match_StageOther_Client_FrameTitle:SetText(textTitle)

		local text4 = ScriptGlobal_Format("#{BWDH_180804_156}", tostring(nIndex+1))
		BW_Match_StageOther_StageRight_Text7:SetText(text4)
	end
end


function BW_Match_StageOther_UpdateTarget_Other(  )

	BW_Match_StageOther_Init()

	local name = CachedTarget:GetName();
	local text = ScriptGlobal_Format("#{BWDH_180804_26}", name)
	BW_Match_StageOther_DragTitle:SetText(text)

	local levelIndex = Player:Lua_GetOtherXbwData_2018( "LevelIndex" )
	BW_Match_StageOther_Client_FrameLeftTitle:SetProperty("Image", g_FightLevel[levelIndex].image)

	--大段位
	local nCurDuanWei1 = Player:Lua_GetOtherXbwData_2018( "CuruanWei1" )
	BW_Match_StageOther_StageLeft_Image:SetProperty("Image", g_Duanwei1_Image[levelIndex][nCurDuanWei1])

	--小段位
	local nCurDuanWei2 = Player:Lua_GetOtherXbwData_2018( "CuruanWei2" )
	if nCurDuanWei1 ~= g_DuanWei_Value.ShenJian then
		BW_Match_StageOther_StageLeft_Text1:SetProperty("Image", g_Duanwei2_Info[nCurDuanWei2].image)
		BW_Match_StageOther_StageLeft_Text1:Show()
	else
		BW_Match_StageOther_StageLeft_Text1:Hide()
	end

	local text2 = ""
	if nCurDuanWei1 < g_DuanWei_Value.ShenJian then
		text2 = ScriptGlobal_Format("#{BWDH_180804_154}", g_Duanwei1_name[nCurDuanWei1], g_Duanwei2_Info[nCurDuanWei2].name)
	else
		text2 = "#{BWDH_180804_155}"
	end
	BW_Match_StageOther_StageLeft_Text2:SetText(text2)

	--星星
	local nCurDuanWei3 = Player:Lua_GetOtherXbwData_2018( "CuruanWei3" )
	if nCurDuanWei3 == nil then
		return
	end

	local nMaxDuanWei3 = BWDH2018:GetXbwDuanweinfo2018(nCurDuanWei1, nCurDuanWei2)
	if  nCurDuanWei1 == g_DuanWei_Value.ShenJian then --王者
		BW_Match_StageOther_StarSet3:Show()
		BW_Match_StageOther_Star3_1:SetProperty("Image", g_Bright_Stars)
		BW_Match_StageOther_Star3_1:SetToolTip("#{BWDH_180804_31}")
		BW_Match_StageOther_Star3Text:SetText(tostring(nCurDuanWei3))

	-- elseif nMaxDuanWei3 == 2 then
		-- BW_Match_StageOther_StarSet2:Show()
		-- for i=1,nMaxDuanWei3 do
			-- if i <= nCurDuanWei3 then
				-- g_BW_Match_StageOther_Star2[i]:SetProperty("Image", g_Bright_Stars)
			-- else
				-- g_BW_Match_StageOther_Star2[i]:SetProperty("Image", g_Gray_Stars)
			-- end
			-- g_BW_Match_StageOther_Star2[i]:SetToolTip("#{BWDH_180804_31}")
		-- end

	elseif nMaxDuanWei3 == 3 then
		BW_Match_StageOther_StarSet:Show()
		for i=1,nMaxDuanWei3 do
			if i <= nCurDuanWei3 then
				g_BW_Match_StageOther_Star3[i]:SetProperty("Image", g_Bright_Stars)
			else
				g_BW_Match_StageOther_Star3[i]:SetProperty("Image", g_Gray_Stars)
			end
			g_BW_Match_StageOther_Star3[i]:SetToolTip("#{BWDH_180804_31}")
		end

	elseif nMaxDuanWei3 == 4 then
		BW_Match_StageOther_StarSet1:Show()
		for i=1,nMaxDuanWei3 do
			if i <= nCurDuanWei3 then
				g_BW_Match_StageOther_Star4[i]:SetProperty("Image", g_Bright_Stars)
			else
				g_BW_Match_StageOther_Star4[i]:SetProperty("Image", g_Gray_Stars)
			end
			g_BW_Match_StageOther_Star4[i]:SetToolTip("#{BWDH_180804_31}")
		end

	elseif nMaxDuanWei3 == 6 then
		BW_Match_StageOther_StarSet6:Show()
		for i=1,nMaxDuanWei3 do
			if i <= nCurDuanWei3 then
				g_BW_Match_StageOther_Star6[i]:SetProperty("Image", g_Bright_Stars)
			else
				g_BW_Match_StageOther_Star6[i]:SetProperty("Image", g_Gray_Stars)
			end
			g_BW_Match_StageOther_Star6[i]:SetToolTip("#{BWDH_180804_31}")
		end

	elseif nMaxDuanWei3 == 8 then
		BW_Match_StageOther_StarSet8:Show()
		for i=1,nMaxDuanWei3 do
			if i <= nCurDuanWei3 then
				g_BW_Match_StageOther_Star8[i]:SetProperty("Image", g_Bright_Stars)
			else
				g_BW_Match_StageOther_Star8[i]:SetProperty("Image", g_Gray_Stars)
			end
			g_BW_Match_StageOther_Star8[i]:SetToolTip("#{BWDH_180804_31}")
		end

	elseif nMaxDuanWei3 == 5 then
		BW_Match_StageOther_StarSet5:Show()
		for i=1,nMaxDuanWei3 do
			if i <= nCurDuanWei3 then
				g_BW_Match_StageOther_Star5[i]:SetProperty("Image", g_Bright_Stars)
			else
				g_BW_Match_StageOther_Star5[i]:SetProperty("Image", g_Gray_Stars)
			end
			g_BW_Match_StageOther_Star5[i]:SetToolTip("#{BWDH_180804_31}")
		end
	end

	--本周参与次数
	local nCurWeekTotalCnt = Player:Lua_GetOtherXbwData_2018( "CurWeekTotalCnt" )
	local text = ScriptGlobal_Format("#{SXTZ_210510_24}", nCurWeekTotalCnt)
	BW_Match_StageOther_StageRight_Text1_1:SetText( text )

	--赛季的参与次数
	local nSeasonPartCnt = Player:Lua_GetOtherXbwData_2018( "SeasonPartCnt" )
	local text = ScriptGlobal_Format("#{SXTZ_210510_24}", nSeasonPartCnt)
	BW_Match_StageOther_StageRight_Text2_1:SetText( text )

	--赛季胜率
	if nSeasonPartCnt == 0 then
		local text = ScriptGlobal_Format("#{SXTZ_210510_24}", "无")
		BW_Match_StageOther_StageRight_Text3_1:SetText(text)
	else
		local nSeasonWinCnt = Player:Lua_GetOtherXbwData_2018( "SeasonWinCnt" )
		local result = math.floor( (nSeasonWinCnt/nSeasonPartCnt) * 100 )
		local text6 = ScriptGlobal_Format("#{BWDH_180804_35}", tostring(result))
		BW_Match_StageOther_StageRight_Text3_1:SetText(text6)
	end

	--赛季最高连胜场次
	local nSeasonConWinCnt = Player:Lua_GetOtherXbwData_2018( "SeasonConWinCnt" )
	local text = ScriptGlobal_Format("#{SXTZ_210510_24}", nSeasonConWinCnt)
	BW_Match_StageOther_StageRight_Text4_1:SetText(text)

	--名剑币
	local nDaiBi = 0
	if nCurDuanWei1 == g_DuanWei_Value.ShenJian then
		if nCurDuanWei3 >= 3 then
			nDaiBi = math.floor(nCurDuanWei3/3)
		end
	end
	local textDaiBi = ScriptGlobal_Format("#{BWDH_240315_50}", tostring(nDaiBi))
	BW_Match_StageOther_StageRight_Text6:SetText(textDaiBi)

end



function BW_Match_StageOtherFrame_CloseWindow()
  this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BW_Match_StageOther_Frame_On_ResetPos()
  BW_Match_StageOther_Frame:SetProperty("UnifiedPosition", g_BW_Match_StageOther_Frame_UnifiedPosition);
end



-- function BW_Match_StageOther_HelpAward_Clicked()
-- 	Clear_XSCRIPT()
-- 		Set_XSCRIPT_Function_Name("ClientCallFunction")
-- 		Set_XSCRIPT_ScriptID(892895)
-- 		Set_XSCRIPT_Parameter(0, -1)
-- 		Set_XSCRIPT_Parameter(1, 2)
-- 		Set_XSCRIPT_ParamCount(2)
-- 	Send_XSCRIPT()
-- end

-- function BW_Match_StageOther_HelpScore_Clicked()
	-- Clear_XSCRIPT()
		-- Set_XSCRIPT_Function_Name("ClientCallFunction")
		-- Set_XSCRIPT_ScriptID(892895)
		-- Set_XSCRIPT_Parameter(0, -1)
		-- Set_XSCRIPT_Parameter(1, 1)
		-- Set_XSCRIPT_ParamCount(2)
	-- Send_XSCRIPT()
-- end

function BW_Match_StageOther_HelpLevel_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientCallFunction")
		Set_XSCRIPT_ScriptID(892895)
		Set_XSCRIPT_Parameter(0, -1)
		Set_XSCRIPT_Parameter(1, 3)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

-- function BW_Match_StageOther_HelpDaibi_Clicked()
-- 	Clear_XSCRIPT()
-- 		Set_XSCRIPT_Function_Name("ClientCallFunction")
-- 		Set_XSCRIPT_ScriptID(892895)
-- 		Set_XSCRIPT_Parameter(0, -1)
-- 		Set_XSCRIPT_Parameter(1, 4)
-- 		Set_XSCRIPT_ParamCount(2)
-- 	Send_XSCRIPT()
-- end
