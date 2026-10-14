--SpringFestival_Pre2.lua
local g_Frame_UnifiedPosition
local g_StartTime = 20210125
local g_EndTime = 20210131
local g_LimitLevel = 30
local g_WenXinYinQuest = {
	[1] = "#{SYCY_201225_100}",
	[2] = "#{SYCY_201225_101}",
	[3] = "#{SYCY_201225_102}",
	[4] = "#{SYCY_201225_103}",
	[5] = "#{SYCY_201225_104}",
}

local g_BingLiJieNPC = {
	[1] = "燕如云",
	[2] = "阿里",
	[3] = "范统",
	[4] = "周敦颐",
	[5] = "梁师成",
}

local g_BingLiJieNPCQuest = {
	[1] = "#{SYCY_201225_105}",
	[2] = "#{SYCY_201225_106}",
	[3] = "#{SYCY_201225_107}",
	[4] = "#{SYCY_201225_108}",
	[5] = "#{SYCY_201225_109}",
}

local g_ImageWeapon = {

	[1] = "set:Spring33  image:MiQingYin_Pipa_Large",
	[2] = "set:Spring33  image:MiQingYin_Erhu_Large",
	[3] = "set:Spring33  image:MiQingYin_Dizi_Large",
	[4] = "set:Spring33  image:MiQingYin_Guqin_Large",
	[5] = "set:Spring33  image:MiQingYin_Gu_Large",
		
}

local g_ImageWeaponText = {

	[1] = "set:Spring33  image:MiQingYin_YYS_Large",
	[2] = "set:Spring33  image:MiQingYin_MCW_Large",
	[3] = "set:Spring33  image:MiQingYin_WZL_Large",
	[4] = "set:Spring33  image:MiQingYin_LBB_Large",
	[5] = "set:Spring33  image:MiQingYin_JFL_Large",
		
}
local g_JianTou = {}
local g_JianTouDisAble = {}
local g_JianTouText = {}

local g_WanLiStr = {
	[1] = "#{SYCY_201225_120}",
	[2] = "#{SYCY_201225_121}",
	[3] = "#{SYCY_201225_122}",
	[4] = "#{SYCY_201225_123}",
	--[5] = "#{SYCY_201225_114}",
	[5] = "#{SYCY_201225_115}",
	[6] = "#{SYCY_201225_116}",
	[7] = "#{SYCY_201225_117}",
	[8] = "#{SYCY_201225_118}",
	--[10] = "#{SYCY_201225_119}",
	[9] = "#{SYCY_201225_110}",
	[10] = "#{SYCY_201225_111}",
	[11] = "#{SYCY_201225_112}",
	[12] = "#{SYCY_201225_113}",
	--[15] = "#{SYCY_201225_124}",
	[13] = "#{SYCY_201225_125}",
	[14] = "#{SYCY_201225_126}",
	[15] = "#{SYCY_201225_127}",
	[16] = "#{SYCY_201225_128}",
	--[20] = "#{SYCY_201225_129}",
	[17] = "#{SYCY_201225_130}",
	[18] = "#{SYCY_201225_131}",
	[19] = "#{SYCY_201225_132}",
	[20] = "#{SYCY_201225_133}",
	--[25] = "#{SYCY_201225_134}",
}

local g_WanLiItem = {
	[1] = 38005155,
	[2] = 38005156,
	[3] = 38005157,
	[4] = 38005158,
	--[5] = 38005149,
	[5] = 38005150,
	[6] = 38005151,
	[7] = 38005152,
	[8] = 38005153,
	--[10] = 38005154,
	[9] = 38005145,
	[10] = 38005146,
	[11] = 38005147,
	[12] = 38005148,
	--[15] = 38005159,
	[13] = 38005160,
	[14] = 38005161,
	[15] = 38005162,
	[16] = 38005163,
	--[20] = 38005164,
	[17] = 38005149,
	[18] = 38005154,
	[19] = 38005159,
	[20] = 38005164,
--[25] = 38005169,
}

--=========
-- PreLoad()
--=========
function SpringFestival_Pre2_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function SpringFestival_Pre2_OnLoad()
	
	g_Frame_UnifiedPosition = SpringFestival_Pre2_FrameNULL:GetProperty("UnifiedPosition")
	SpringFestival_Pre2_Tip:Hide()
	SpringFestival_Pre2_RewardBtnTip:Hide()
	
	g_JianTou[1] = SpringFestival_Pre2Head1;
	g_JianTou[2] = SpringFestival_Pre2Head2;
	g_JianTou[3] = SpringFestival_Pre2Head3;
	
	g_JianTouDisAble[1] = SpringFestival_Pre2Head1_Disable;
	g_JianTouDisAble[2] = SpringFestival_Pre2Head2_Disable;
	g_JianTouDisAble[3] = SpringFestival_Pre2Head3_Disable;
	
	g_JianTouText[1] = SpringFestival_Pre2_Clinet1_Text;
	g_JianTouText[2] = SpringFestival_Pre2_Clinet2_Text;
	g_JianTouText[3] = SpringFestival_Pre2_Clinet3_Text;
	
end

--=========
-- Event
--=========
function SpringFestival_Pre2_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88833405) then
	
	
		local nSYCY_NOW_STAGE = Get_XParam_INT(0) -- 当前进度
		local nSYCY_NOW_STAGE_STATE = Get_XParam_INT(1) -- 当前进度完成度
		local nTalkMessageId = Get_XParam_INT(2)
		local nTalkNpcId = Get_XParam_INT(3)
		local nJinNangId = Get_XParam_INT(4)
		local nNeedItemId = Get_XParam_INT(5)
		local nJinNangHotPot = Get_XParam_INT(6)
		local nSYCY_INDEX = Get_XParam_INT(7)
		local nAwardHotPot = Get_XParam_INT(8)
		SpringFestival_Pre2_Open(nSYCY_NOW_STAGE, nSYCY_NOW_STAGE_STATE, nTalkMessageId, nTalkNpcId, nJinNangId, nNeedItemId, nJinNangHotPot, nSYCY_INDEX, nAwardHotPot)
		
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		SpringFestival_Pre2_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_Pre2_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		SpringFestival_Pre2_On_ResetPos()

	end
end


function SpringFestival_Pre2_Close()
	
	this:Hide()
end

--=========
-- 重置
--=========
function SpringFestival_Pre2_On_ResetPos()

	SpringFestival_Pre2_FrameNULL:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function SpringFestival_Pre2_Open(nSYCY_NOW_STAGE, nSYCY_NOW_STAGE_STATE, nTalkMessageId, nTalkNpcId, nJinNangId, nNeedItemId, nJinNangHotPot, nSYCY_INDEX, nAwardHotPot)

	SpringFestival_Pre2_Reward_ButtonGoto1:Hide()
	SpringFestival_Pre2_Reward_ButtonReceive1:Hide()
	SpringFestival_Pre2_Reward_Received1:Hide()
	SpringFestival_Pre2_Reward_ButtonGoto2:Hide()
	SpringFestival_Pre2_Reward_ButtonReceive2:Hide()
	SpringFestival_Pre2_Reward_Received2:Hide()
	SpringFestival_Pre2_Reward_ButtonGoto3:Hide()
	SpringFestival_Pre2_Reward_ButtonReceive3:Hide()
	SpringFestival_Pre2_Reward_Received3:Hide()
	SpringFestival_Pre2_Instrument:SetProperty("Image", g_ImageWeapon[nSYCY_INDEX])		
	SpringFestival_Pre2_InstrName:SetProperty("Image", g_ImageWeaponText[nSYCY_INDEX])	
	if nJinNangHotPot == 1 then
		SpringFestival_Pre2_Tip:Show()
	end
	if nAwardHotPot == 1 then
		SpringFestival_Pre2_RewardBtnTip:Show()
		SpringFestival_Pre2_Reward_Button:Enable()	
	elseif nAwardHotPot == 0 and nSYCY_NOW_STAGE == 3 and nSYCY_NOW_STAGE_STATE == 4 then
		SpringFestival_Pre2_RewardBtnTip:Hide()
		SpringFestival_Pre2_Reward_Button:Disable()	
	end
	if nSYCY_NOW_STAGE == 1 then
		g_JianTou[1]:Show()
		g_JianTou[2]:Hide()
		g_JianTou[3]:Hide()
		
		g_JianTouDisAble[1]:Hide()
		g_JianTouDisAble[2]:Show()
		g_JianTouDisAble[3]:Show()
	elseif nSYCY_NOW_STAGE == 2 then
		g_JianTou[1]:Hide()
		g_JianTou[2]:Show()
		g_JianTou[3]:Hide()
		
		g_JianTouDisAble[1]:Show()
		g_JianTouDisAble[2]:Hide()
		g_JianTouDisAble[3]:Show()
	elseif nSYCY_NOW_STAGE == 3 then
		g_JianTou[1]:Hide()
		g_JianTou[2]:Hide()
		g_JianTou[3]:Show()
		
		g_JianTouDisAble[1]:Show()
		g_JianTouDisAble[2]:Show()
		g_JianTouDisAble[3]:Hide()
	end
	-- 警心1
	if nSYCY_NOW_STAGE == 1 and nSYCY_NOW_STAGE_STATE == 1 then
	
		g_JianTouText[1]:SetText("#{SYCY_201225_09}")
		g_JianTouText[2]:SetText("#{SYCY_201225_196}")
		g_JianTouText[3]:SetText("#{SYCY_201225_196}")
		SpringFestival_Pre2_Reward_ButtonGoto1:Show()
	
		
	elseif nSYCY_NOW_STAGE == 1 and nSYCY_NOW_STAGE_STATE == 2 then -- 警心2
	
		g_JianTouText[1]:SetText(ScriptGlobal_Format("#{SYCY_201225_10}",g_WenXinYinQuest[nTalkMessageId]))
		g_JianTouText[2]:SetText("#{SYCY_201225_196}")
		g_JianTouText[3]:SetText("#{SYCY_201225_196}")
		SpringFestival_Pre2_Reward_ButtonGoto1:Show()
		
	elseif nSYCY_NOW_STAGE == 1 and nSYCY_NOW_STAGE_STATE == 3 then -- 警心演奏
	
		g_JianTouText[1]:SetText("#{SYCY_201225_11}")
		g_JianTouText[2]:SetText("#{SYCY_201225_196}")
		g_JianTouText[3]:SetText("#{SYCY_201225_196}")
		SpringFestival_Pre2_Reward_ButtonReceive1:Show()	
		
	elseif nSYCY_NOW_STAGE == 2 and nSYCY_NOW_STAGE_STATE == 1 then -- 问学1
	
		g_JianTouText[2]:SetText("#{SYCY_201225_12}")
		g_JianTouText[1]:SetText("#{SYCY_201225_195}")
		g_JianTouText[3]:SetText("#{SYCY_201225_196}")
		SpringFestival_Pre2_Reward_ButtonGoto2:Show()
		SpringFestival_Pre2_Reward_Received1:Show()
		
	elseif nSYCY_NOW_STAGE == 2 and nSYCY_NOW_STAGE_STATE == 2 then -- 问学2
	
		g_JianTouText[2]:SetText(ScriptGlobal_Format("#{SYCY_201225_13}",g_BingLiJieNPCQuest[nTalkNpcId]))
		g_JianTouText[1]:SetText("#{SYCY_201225_195}")
		g_JianTouText[3]:SetText("#{SYCY_201225_196}")
		SpringFestival_Pre2_Reward_ButtonGoto2:Show()
		SpringFestival_Pre2_Reward_Received1:Show()
		
	elseif nSYCY_NOW_STAGE == 2 and nSYCY_NOW_STAGE_STATE == 3 then -- 问学演奏
	
		g_JianTouText[2]:SetText("#{SYCY_201225_14}")
		g_JianTouText[1]:SetText("#{SYCY_201225_195}")
		g_JianTouText[3]:SetText("#{SYCY_201225_196}")
		SpringFestival_Pre2_Reward_ButtonReceive2:Show()
		SpringFestival_Pre2_Reward_Received1:Show()
		
	elseif nSYCY_NOW_STAGE == 3 and nSYCY_NOW_STAGE_STATE == 1 then -- 万礼1
	
		g_JianTouText[3]:SetText("#{SYCY_201225_15}")
		g_JianTouText[1]:SetText("#{SYCY_201225_195}")
		g_JianTouText[2]:SetText("#{SYCY_201225_195}")
		SpringFestival_Pre2_Reward_Received1:Show()
		SpringFestival_Pre2_Reward_Received2:Show()
		SpringFestival_Pre2_Reward_ButtonGoto3:Show()
		
	elseif nSYCY_NOW_STAGE == 3 and nSYCY_NOW_STAGE_STATE == 2 then -- 万礼2
	
		g_JianTouText[3]:SetText(ScriptGlobal_Format("#{SYCY_201225_16}",g_WanLiStr[nNeedItemId]))
		g_JianTouText[1]:SetText("#{SYCY_201225_195}")
		g_JianTouText[2]:SetText("#{SYCY_201225_195}")
		SpringFestival_Pre2_Reward_Received1:Show()
		SpringFestival_Pre2_Reward_Received2:Show()
		SpringFestival_Pre2_Reward_ButtonGoto3:Show()
		
	elseif nSYCY_NOW_STAGE == 3 and nSYCY_NOW_STAGE_STATE == 3 then -- 万礼演奏
	
		g_JianTouText[3]:SetText("#{SYCY_201225_17}")
		g_JianTouText[1]:SetText("#{SYCY_201225_195}")
		g_JianTouText[2]:SetText("#{SYCY_201225_195}")
		SpringFestival_Pre2_Reward_Received1:Show()
		SpringFestival_Pre2_Reward_Received2:Show()
		SpringFestival_Pre2_Reward_ButtonReceive3:Show()
		
	else
		g_JianTouText[3]:SetText("#{SYCY_201225_195}")
		g_JianTouText[1]:SetText("#{SYCY_201225_195}")
		g_JianTouText[2]:SetText("#{SYCY_201225_195}")
		SpringFestival_Pre2_Reward_Received1:Show()
		SpringFestival_Pre2_Reward_Received2:Show()
		SpringFestival_Pre2_Reward_Received3:Show()
	end
	this:Show()
end	

--=========
-- 点击goto和演奏按钮
--=========
function SpringFestival_Pre2_ButtonClick(index)

	local curDay = DataPool:GetServerDayTime()
	if curDay < g_StartTime or curDay > g_EndTime then
		PushDebugMessage( "#{SYCY_201225_06}" )
		return
	end
	
	if Player:GetLevel() < g_LimitLevel then
         PushDebugMessage("#{SYCY_201225_05}")
         return
    end
		
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{QLYX_100517_42}" )
		return
	end
	
	if index == 1  then
		local ret = AutoRuntoTargetExWithName(305, 253, 0, "宛晴")
        if 0 == ret then
            PushDebugMessage("无法自动寻路")
            return
        end
	elseif index == 2 then
		local ret = AutoRuntoTargetExWithName(314, 269, 0, "央乐")
        if 0 == ret then
            PushDebugMessage("无法自动寻路")
            return
        end
	elseif index == 3 then
		local ret = AutoRuntoTargetExWithName(201, 281, 0, "聆音")
        if 0 == ret then
            PushDebugMessage("无法自动寻路")
            return
        end
	elseif index == 4 then
		PushDebugMessage("#{SYCY_201225_24}")
	end
	
end

--=========
-- 点击问号
--=========
function SpringFestival_Pre2_HelpClick(  )

	PushEvent("CCSHOP_HELP", 129)
	
end

--=========
-- 点击锦囊
--=========
function SpringFestival_Pre2_JinNangClick(  )
	
	local curDay = DataPool:GetServerDayTime()
	if curDay < g_StartTime or curDay > g_EndTime then
		PushDebugMessage( "#{SYCY_201225_06}" )
		return
	end
	
	if Player:GetLevel() < g_LimitLevel then
         PushDebugMessage("#{SYCY_201225_05}")
         return
    end
		
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{QLYX_100517_42}" )
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenJingNang" )
		Set_XSCRIPT_ScriptID( 888334 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	SpringFestival_Pre2_Tip:Hide()
end

--=========
-- 点击领奖
--=========
function SpringFestival_Pre2_AwardClick(  )
	
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetAward" )
		Set_XSCRIPT_ScriptID( 888334 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	

end
	
