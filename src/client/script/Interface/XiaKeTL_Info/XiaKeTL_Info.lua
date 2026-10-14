-- XiaKeTL_Info 侠客Boss信息 2025-2-12 lishilong
-- !!!reloadscript =XiaKeTL_Info
--

local g_XiaKeTL_Info_Frame_UnifiedPosition
-- local g_XiaKeTL_Info_Frame_UnifiedXPosition
-- local g_XiaKeTL_Info_Frame_UnifiedYPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 0
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= 0
-- MD_XIAKE_BOSS_REWARD_INFO=3179		--侠客Boss 大Boss的奖励id
-- MD_XIAKE_BOSS_REWARD_02_INFO=3195	--侠客Boss 小Boss的奖励id
-- MD_XIAKE_BOSS_REWARD_03_INFO=3196	--侠客Boss 草的奖励次数
local g_nBigBossRewardMD			= 3179
local g_nSmallBossRewardMD			= 3195
local g_nFlowerRewardMD				= 3196
local g_nHardXiaKeBossSceneID		= 1134
local g_nNormalXiaKeBossSceneID		= 1139

local g_bShowAll			= 0
local g_nBossFullHPPercent	= 100
local g_nMiniShowYDec		= 150
local g_nShowTeamNum		= 3
local g_cTeamName			= {}
local g_cTeamDamage			= {}

-- nBossType 1 莽牯毒蛤王boss群 2 玄击金刚boss群 3 千年冰魄boss群 4 白冥启boss群 5 大龙
local g_tabCommonBossData = 
{
	-- 莽牯毒蛤王boss群
	[1] = { strName = "#{YWXK_250113_04}", strBossInfo = "#{YWXK_250113_52}", strNormalBossInfo = "#{YWXK_250113_134}", }, 

	-- 玄击金刚boss群
	[2] = { strName = "#{YWXK_250113_05}", strBossInfo = "#{YWXK_250113_54}", strNormalBossInfo = "#{YWXK_250113_136}", },

	-- 千年冰魄boss群
	[3] = { strName = "#{YWXK_250113_07}", strBossInfo = "#{YWXK_250113_55}", strNormalBossInfo = "#{YWXK_250113_137}", },

	-- 白冥启boss群 
	[4] = { strName = "#{YWXK_250113_08}", strBossInfo = "#{YWXK_250113_53}", strNormalBossInfo = "#{YWXK_250113_135}", },

	-- 大龙
	[5] = { strName = "#{YWXK_250113_06}", strBossInfo = "#{YWXK_250113_56}", strNormalBossInfo = "#{YWXK_250113_138}", },
}

-- -- 允许UI显示的时间 开始 服务器 15分进人 这里放宽了一点
-- local g_nUIShowStartTime		= 201000
-- -- 允许UI显示的时间 结束 对应服务器的强制踢人时间
-- local g_nUIShowEndTime		= 210100
-- -- Boss Create的时间
-- local g_nBossCreateTime		= 203000
-- local g_nBossCreateMinute	= 30
-- local g_nHuoDongEndTime		= 210000
-- local g_nHuoDongEndMinute	= 60
-- local g_nKickHumanMinute		= 1

local g_tabTimeInfo		= 
{
	[11] = 
	{
		nUIShowStartTime 	= 111000,
		nUIShowEndTime		= 120100,
		nBossCreateTime		= 113000,
		nBossCreateMinute	= 30,
		nHuoDongEndTime		= 120000,
		nHuoDongEndMinute	= 60,
		nKickHumanMinute	= 1,
		nFLowerWave2Time	= 114000,
		nFLowerWave2Minute	= 40,
		nFLowerWave3Time	= 115000,
		nFLowerWave3Minute	= 50,
		strShowStartMin		= "30",
	},

	[14] = 
	{
		nUIShowStartTime 	= 141000,
		nUIShowEndTime		= 150100,
		nBossCreateTime		= 143000,
		nBossCreateMinute	= 30,
		nHuoDongEndTime		= 150000,
		nHuoDongEndMinute	= 60,
		nKickHumanMinute	= 1,
		nFLowerWave2Time	= 144000,
		nFLowerWave2Minute	= 40,
		nFLowerWave3Time	= 145000,
		nFLowerWave3Minute	= 50,
		strShowStartMin		= "30",
	},

	[20] = 
	{
		nUIShowStartTime 	= 194000,
		nUIShowEndTime		= 203100,
		nBossCreateTime		= 200000,
		nBossCreateMinute	= 60,
		nHuoDongEndTime		= 203000,
		nHuoDongEndMinute	= 30,
		nKickHumanMinute	= 31,
		nFLowerWave2Time	= 201000,
		nFLowerWave2Minute	= 10,
		nFLowerWave3Time	= 202000,
		nFLowerWave3Minute	= 20,
		strShowStartMin		= "00",
	},

	[22] = 
	{
		nUIShowStartTime 	= 221000,
		nUIShowEndTime		= 230100,
		nBossCreateTime		= 223000,
		nBossCreateMinute	= 30,
		nHuoDongEndTime		= 230000,
		nHuoDongEndMinute	= 60,
		nKickHumanMinute	= 1,
		nFLowerWave2Time	= 224000,
		nFLowerWave2Minute	= 40,
		nFLowerWave3Time	= 225000,
		nFLowerWave3Minute	= 50,
		strShowStartMin		= "30",
	},
}
-- local g_nUICommandID		= 79003501

--=========================================================
-- PreLoad
--=========================================================
function XiaKeTL_Info_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	if 1 == bCaredItem then
		this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	end
	if 1 == bCaredMoney then
		this:RegisterEvent("MONEY_CHANGE_EX", false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	end
	if 1 == bCaredYuanBao then
		this:RegisterEvent("UPDATE_YUANBAO", false)
	end
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	this:RegisterEvent("UPDATE_XIAKE_BOSS_INFO");
end

--=========================================================
-- OnLoad
--=========================================================
function XiaKeTL_Info_OnLoad()
	g_XiaKeTL_Info_Frame_UnifiedPosition = XiaKeTL_Info_Frame:GetProperty("UnifiedPosition")

	-- g_XiaKeTL_Info_Frame_UnifiedXPosition	= XiaKeTL_Info_Frame:GetProperty("UnifiedXPosition");
	-- g_XiaKeTL_Info_Frame_UnifiedYPosition	= XiaKeTL_Info_Frame:GetProperty("UnifiedYPosition");

	g_cTeamName[1]		= XiaKeTL_Info_Team1NameText
	g_cTeamName[2]		= XiaKeTL_Info_Team2NameText
	g_cTeamName[3]		= XiaKeTL_Info_Team3NameText

	g_cTeamDamage[1]	= XiaKeTL_Info_Team1DamageText
	g_cTeamDamage[2]	= XiaKeTL_Info_Team2DamageText
	g_cTeamDamage[3]	= XiaKeTL_Info_Team3DamageText

	-- XiaKeTL_Info_OK_Button : SetEvent("Clicked", "XiaKeTL_Info_ConfirmClick()")
end

--=========================================================
-- OnEvent
--=========================================================
function XiaKeTL_Info_OnEvent(event)
	if event == "UPDATE_XIAKE_BOSS_INFO" then

		-- 显示界面
		-- 为了解决界面被遮挡的问题，先把界面关了
		if this:IsVisible() then
			-- XiaKeTL_Info_OnClose()
		else
			g_bShowAll = 1
		end
		XiaKeTL_Info_Reset()
		-- XiaKeTL_Info_Frame_On_ResetPos()
		this:Show()
		XiaKeTL_Info_ParamInit()
		XiaKeTL_Info_MoneyUpdate()
		XiaKeTL_Info_YuanBaoUpdate()
		XiaKeTL_Info_Update(1)

	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_nObjCaredIDClient) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			XiaKeTL_Info_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			XiaKeTL_Info_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		XiaKeTL_Info_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		XiaKeTL_Info_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		XiaKeTL_Info_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		XiaKeTL_Info_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XiaKeTL_Info_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function XiaKeTL_Info_ParamInit()
	local nServerObjID 	= Get_XParam_INT(1)
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function XiaKeTL_Info_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then

	end

	if "No" == strRet then
		
	end
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =XiaKeTL_Info
function XiaKeTL_Info_Update(bOpen)

	-- PushDebugMessage("XiaKeTL_Info_Update")
	local nBigBossRewardMDValue = DataPool:GetPlayerMission_DataRound(g_nBigBossRewardMD)
	local nSmallBossRewardMDValue = DataPool:GetPlayerMission_DataRound(g_nSmallBossRewardMD)
	local nFlowerRewardMDValue = DataPool:GetPlayerMission_DataRound(g_nFlowerRewardMD)

	local nXiaKeBossShamHpPercent100 = DataPool : Lua_GetXiaKeBossShamHpPercent100()	
	local nCurXiaKeBossType = DataPool : Lua_GetCurXiaKeBossType()
	local nCurTimeWaveMarkNum = DataPool : Lua_GetCurTimeWaveMarkNum()
	-- 这里DataId不一定存在 Boss可能还没刷新 也可能死了
	local nCurShamHpXiaKeBossDataId = DataPool : Lua_GetShamHpXiaKeBossDataId()
	-- local strBossName = TServerUI:GetMonsterNamebyDataID(nCurYwBossMonsterDataId)

	local tInfo = g_tabCommonBossData[nCurXiaKeBossType]
	if nil == tInfo then
		-- PushDebugMessage("nil == tInfo")
		XiaKeTL_Info_OnClose()
		return
	end
	local tCurTimeInfo = g_tabTimeInfo[nCurTimeWaveMarkNum]
	if nil == tCurTimeInfo then
		-- PushDebugMessage("nil == tCurTimeInfo")
		XiaKeTL_Info_OnClose()
		return
	end

	local strBossName 		= tInfo.strName
	local strBossInfo 		= tInfo.strBossInfo
	local strNormalBossInfo = tInfo.strNormalBossInfo

	local nServerSceneID = GetSceneServerID()

	-- PushDebugMessage("nServerSceneID"..nServerSceneID)

	-- if g_nNormalXiaKeBossSceneID == nServerSceneID then
	-- 	XiaKeTL_Info_OtherTextBK 			: Hide()
	-- 	XiaKeTL_Info_ZhanKuang_CountdownBK1	: Hide()
	-- 	XiaKeTL_Info_OtherTextBK2 			: Show()
	-- 	XiaKeTL_Info_ZhanKuang_CountdownBK2	: Show()
	-- else
	-- 	XiaKeTL_Info_OtherTextBK 			: Show()
	-- 	XiaKeTL_Info_ZhanKuang_CountdownBK1	: Show()
	-- 	XiaKeTL_Info_OtherTextBK2 			: Hide()
	-- 	XiaKeTL_Info_ZhanKuang_CountdownBK2	: Hide()
	-- end

	-- 改为永远显示普通场的信息
	XiaKeTL_Info_OtherTextBK 			: Hide()
	XiaKeTL_Info_ZhanKuang_CountdownBK1	: Hide()
	XiaKeTL_Info_OtherTextBK2 			: Show()
	XiaKeTL_Info_ZhanKuang_CountdownBK2	: Show()

	-- 界面标题
	-- XiaKeTL_Info_DragTitle : SetText( ScriptGlobal_Format("#{YFYW_240806_5}", strBossName ))

	-- 是否最小化
	if 1 == g_bShowAll then
		XiaKeTL_Info_MainClient : Show()
		XiaKeTL_Info_Frame : SetProperty("AbsoluteSize", "w:320 h:264");
	else
		XiaKeTL_Info_MainClient : Hide()
		XiaKeTL_Info_Frame : SetProperty("AbsoluteSize", "w:320 h:30");
	end

	-- 经过客户端自校验的服务器秒格式时间 = 时 * 10000 + 分 * 100 + 秒
	local nCurServerSecondTime, nCurHour, nCurMinute, nCurSecond = DataPool:GetServerMinuteTimeEx()

	-- PushDebugMessage("nCurXiaKeBossType:"..nCurXiaKeBossType..",nCurServerSecondTime:"..nCurServerSecondTime..",nCurHour:"..nCurHour..",nCurMinute:"..nCurMinute..",nCurSecond:"..nCurSecond)

	local nUIShowStartTime 	= tCurTimeInfo.nUIShowStartTime
	local nUIShowEndTime 	= tCurTimeInfo.nUIShowEndTime
	local nBossCreateTime 	= tCurTimeInfo.nBossCreateTime
	local nBossCreateMinute = tCurTimeInfo.nBossCreateMinute
	local nHuoDongEndTime 	= tCurTimeInfo.nHuoDongEndTime
	local nHuoDongEndMinute = tCurTimeInfo.nHuoDongEndMinute
	local nKickHumanMinute 	= tCurTimeInfo.nKickHumanMinute

	local nFLowerWave2Time	 = tCurTimeInfo.nFLowerWave2Time	
	local nFLowerWave2Minute = tCurTimeInfo.nFLowerWave2Minute
	local nFLowerWave3Time	 = tCurTimeInfo.nFLowerWave3Time	
	local nFLowerWave3Minute = tCurTimeInfo.nFLowerWave3Minute
	
	local strShowStartMin = tCurTimeInfo.strShowStartMin

	if nCurServerSecondTime < nUIShowStartTime or nCurServerSecondTime >= nUIShowEndTime then
		XiaKeTL_Info_OnClose()
		return
	end
	
	-- Boss刷新前
	if nCurServerSecondTime < nBossCreateTime then

		XiaKeTL_Info_InfoBK_Client1 : Show()
		XiaKeTL_Info_InfoBK_Client2 : Hide()
		XiaKeTL_Info_InfoBK_Client3 : Hide()

		-- 计算时间差 前面有判断 这里是21点
		local nCountdownTime = 60 * ( nBossCreateMinute - nCurMinute ) - nCurSecond
		if nCountdownTime < 0 then
			nCountdownTime = 0
		end
		-- 刷新倒计时显示
		XiaKeTL_Info_Time_CountdownInfo_Time : SetProperty("Timer", nCountdownTime)

		-- 显示Boss信息
		-- local strMsg = ScriptGlobal_Format(strBossInfo, nCurTimeWaveMarkNum ) 
		-- if g_nNormalXiaKeBossSceneID == nServerSceneID then
		-- 	strMsg = ScriptGlobal_Format(strNormalBossInfo, nCurTimeWaveMarkNum ) 
		-- end

		-- 改为永远显示普通场的信息
		local strMsg = ScriptGlobal_Format(strNormalBossInfo, nCurTimeWaveMarkNum, strShowStartMin ) 

		XiaKeTL_Info_Time_CountdownInfo_TimeFinish : SetText( strMsg )

		return
	end

	-- 后面都是Boss刷新以后的逻辑了
	XiaKeTL_Info_InfoBK_Client1 : Hide()
	XiaKeTL_Info_InfoBK_Client2 : Show()
	XiaKeTL_Info_InfoBK_Client3 : Show()

	-- 活动倒计时显示
	if nCurServerSecondTime < nHuoDongEndTime then
		-- 计算时间差 前面有判断 这里是21点
		local nCountdownTime = 60 * ( nHuoDongEndMinute - nCurMinute ) - nCurSecond
		if nCountdownTime < 0 then
			nCountdownTime = 0
		end
		XiaKeTL_Info_ZhanKuang_Countdown : SetText( "#{YWXK_250113_57}")
		XiaKeTL_Info_ZhanKuang_Countdown_Time : SetProperty("Timer", nCountdownTime)

		XiaKeTL_Info_ZhanKuang_Countdown : SetToolTip( "#{YWXK_250113_59}")
		XiaKeTL_Info_ZhanKuang_Countdown_Time : SetToolTip( "#{YWXK_250113_59}")

		XiaKeTL_Info_ZhanKuang_Countdown2 : SetText( "#{YWXK_250113_57}")
		XiaKeTL_Info_ZhanKuang_Countdown2_Time : SetProperty("Timer", nCountdownTime)

		XiaKeTL_Info_ZhanKuang_Countdown2 : SetToolTip( "#{YWXK_250113_59}")
		XiaKeTL_Info_ZhanKuang_Countdown2_Time : SetToolTip( "#{YWXK_250113_59}")
	else
		-- 计算时间差 前面有判断 这里是22点
		local nCountdownTime = 60 * ( nKickHumanMinute - nCurMinute ) - nCurSecond
		if nCountdownTime < 0 then
			nCountdownTime = 0
		end
		XiaKeTL_Info_ZhanKuang_Countdown : SetText( "#{YWXK_250113_58}")
		XiaKeTL_Info_ZhanKuang_Countdown_Time : SetProperty("Timer", nCountdownTime)

		XiaKeTL_Info_ZhanKuang_Countdown : SetToolTip( "")
		XiaKeTL_Info_ZhanKuang_Countdown_Time : SetToolTip( "")

		XiaKeTL_Info_ZhanKuang_Countdown2 : SetText( "#{YWXK_250113_58}")
		XiaKeTL_Info_ZhanKuang_Countdown2_Time : SetProperty("Timer", nCountdownTime)

		XiaKeTL_Info_ZhanKuang_Countdown2 : SetToolTip( "")
		XiaKeTL_Info_ZhanKuang_Countdown2_Time : SetToolTip( "")
	end

	-- 灵草倒计时显示
	if nCurServerSecondTime < nFLowerWave2Time then
		local nCountdownTime = 60 * ( nFLowerWave2Minute - nCurMinute ) - nCurSecond
		if nCountdownTime < 0 then
			nCountdownTime = 0
		end
		XiaKeTL_Info_ZhanKuang_Countdown3 : SetText( "#{YWXK_250113_139}")
		XiaKeTL_Info_ZhanKuang_Countdown3_Time : SetProperty("Timer", nCountdownTime)
		XiaKeTL_Info_ZhanKuang_Countdown3_Time : Show()

		XiaKeTL_Info_ZhanKuang_Countdown3 : SetToolTip( "#{YWXK_250113_141}")
		XiaKeTL_Info_ZhanKuang_Countdown3_Time : SetToolTip( "#{YWXK_250113_141}")

	elseif nCurServerSecondTime < nFLowerWave3Time then
		local nCountdownTime = 60 * ( nFLowerWave3Minute - nCurMinute ) - nCurSecond
		if nCountdownTime < 0 then
			nCountdownTime = 0
		end

		XiaKeTL_Info_ZhanKuang_Countdown3 : SetText( "#{YWXK_250113_139}")
		XiaKeTL_Info_ZhanKuang_Countdown3_Time : SetProperty("Timer", nCountdownTime)
		XiaKeTL_Info_ZhanKuang_Countdown3_Time : Show()

		XiaKeTL_Info_ZhanKuang_Countdown3 : SetToolTip( "#{YWXK_250113_141}")
		XiaKeTL_Info_ZhanKuang_Countdown3_Time : SetToolTip( "#{YWXK_250113_141}")
	else
		XiaKeTL_Info_ZhanKuang_Countdown3 : SetText( "#{YWXK_250113_140}")
		XiaKeTL_Info_ZhanKuang_Countdown3_Time : Hide()

		XiaKeTL_Info_ZhanKuang_Countdown3 : SetToolTip( "#{YWXK_250113_141}")
		XiaKeTL_Info_ZhanKuang_Countdown3_Time : SetToolTip( "#{YWXK_250113_141}")
	end

	-- 首领信息显示
	if nXiaKeBossShamHpPercent100 > 0 then
		XiaKeTL_Info_ZhanKuang_PersonalInfo_Level : SetText( ScriptGlobal_Format("#{YWXK_250113_60}", nXiaKeBossShamHpPercent100 ) )
	else
		XiaKeTL_Info_ZhanKuang_PersonalInfo_Level : SetText( "#{YWXK_250113_61}")
	end
	XiaKeTL_Info_ZhanKuang_PersonalInfo_Level : SetToolTip( "#{YWXK_250113_62}")

	-- 精英奖励
	if nSmallBossRewardMDValue > 0 or nBigBossRewardMDValue > 0 then
		local strMsg = ScriptGlobal_Format("#{YWXK_250113_142}", 1 )
		XiaKeTL_Info_OtherText 	: SetText( strMsg )
		XiaKeTL_Info_OtherText2 : SetText( strMsg )	
	else
		local strMsg = ScriptGlobal_Format("#{YWXK_250113_142}", 0 )
		XiaKeTL_Info_OtherText 	: SetText( strMsg )
		XiaKeTL_Info_OtherText2 : SetText( strMsg )
		-- XiaKeTL_Info_OtherText 	: SetText( "#{YWXK_250113_143}")
		-- XiaKeTL_Info_OtherText2 : SetText( "#{YWXK_250113_143}")
	end

	XiaKeTL_Info_OtherText 	: SetToolTip( "#{YWXK_250113_144}")
	XiaKeTL_Info_OtherText2 : SetToolTip( "#{YWXK_250113_144}")

	-- 灵草奖励
	-- 改成一直显示了 2025-4-8
	if nFlowerRewardMDValue >= 0 then
		local strMsg = ScriptGlobal_Format("#{YWXK_250113_145}", nFlowerRewardMDValue )
		XiaKeTL_Info_OtherText3 : SetText( strMsg )
	else
		XiaKeTL_Info_OtherText3 : SetText( "#{YWXK_250113_146}")
	end

	XiaKeTL_Info_OtherText3 : SetToolTip( "#{YWXK_250113_147}")

	-- 精英信息显示
	-- local nSmallXiaKeBossNum = DataPool : Lua_GetSmallXiaKeBossNum()	
	-- XiaKeTL_Info_ZhanKuang_PersonalInfo_EXP : SetText( ScriptGlobal_Format("#{YWXK_250113_63}", nSmallXiaKeBossNum ) )
	-- XiaKeTL_Info_ZhanKuang_PersonalInfo_EXP : SetToolTip( "#{YWXK_250113_64}")

	-- 榜单显示
	for i = 1, g_nShowTeamNum do
		local nTeamIndexOrRank, nTeamScore, strShowName = DataPool : Lua_GetXiaKeBossDamageInfoByIndex(i -1)
		g_cTeamName[i] 		: SetText( "#{YWXK_250113_105}")
		g_cTeamDamage[i] 	: SetText( ScriptGlobal_Format("#{YWXK_250113_70}", 0 ))
		if nTeamScore > 0 then
			g_cTeamName[i] 		: SetText( ScriptGlobal_Format("#{YWXK_250113_68}", strShowName ))
			g_cTeamDamage[i] 	: SetText( ScriptGlobal_Format("#{YWXK_250113_70}", nTeamScore ))
		end
	end	
	
	-- 个人信息显示
	local nTeamIndexOrRank, nTeamScore, strShowName = DataPool : Lua_GetXiaKeBossDamageInfoByIndex(g_nShowTeamNum)
	XiaKeTL_Info_MyTeamText : SetText( ScriptGlobal_Format("#{YWXK_250113_66}", nTeamIndexOrRank ))
	XiaKeTL_Info_MyTeamNameText : SetText( ScriptGlobal_Format("#{YWXK_250113_68}", strShowName ))
	XiaKeTL_Info_MyTeamDamageText : SetText( ScriptGlobal_Format("#{YWXK_250113_70}", nTeamScore ))

	if 0 == nTeamScore then
		XiaKeTL_Info_MyTeamText : SetText( "#{YWXK_250113_71}")
	end
end

--=========================================================
-- 重置界面
--=========================================================
function XiaKeTL_Info_Reset()

end

--=========================================================
-- 帮助
--=========================================================
function XiaKeTL_Info_Help_Clicked()
	local nCurShamHpXiaKeBossDataId = DataPool : Lua_GetShamHpXiaKeBossDataId()
	-- PushDebugMessage("nCurShamHpXiaKeBossDataId"..nCurShamHpXiaKeBossDataId)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnUIClickHelp" )
		Set_XSCRIPT_ScriptID(790100)
		Set_XSCRIPT_Parameter(0, nCurShamHpXiaKeBossDataId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=========================================================
-- 最小化
--=========================================================
function XiaKeTL_Info_CloseClicked()
	if 1 == g_bShowAll then
		g_bShowAll = 0
	else
		g_bShowAll = 1
	end
	XiaKeTL_Info_Update(1)
end

-- --=========================================================
-- -- 界面确认按钮
-- --=========================================================
-- function XiaKeTL_Info_ConfirmClick()
-- 	Clear_XSCRIPT()
-- 		Set_XSCRIPT_Function_Name( "OnUIEvent" )
-- 		Set_XSCRIPT_ScriptID(060225)
-- 		Set_XSCRIPT_Parameter(0, 2)					
-- 		Set_XSCRIPT_Parameter(1, 1)				
-- 		Set_XSCRIPT_ParamCount(2)
-- 	Send_XSCRIPT()
-- end

--=========================================================
-- 关闭界面
--=========================================================
function XiaKeTL_Info_OnClose()	
	this:Hide()
	StopCareObject_XiaKeTL_Info()
	-- 重置
	XiaKeTL_Info_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="XiaKeTL_Info_OnHidden();" />
--=========================================================
function XiaKeTL_Info_OnHidden()
	StopCareObject_XiaKeTL_Info()
	-- 重置
	XiaKeTL_Info_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_XiaKeTL_Info()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "XiaKeTL_Info")
end

function StopCareObject_XiaKeTL_Info()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "XiaKeTL_Info")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function XiaKeTL_Info_MoneyUpdate()
	-- XiaKeTL_Info_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- XiaKeTL_Info_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function XiaKeTL_Info_YuanBaoUpdate()
	-- XiaKeTL_Info_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function XiaKeTL_Info_Frame_On_ResetPos()
	XiaKeTL_Info_Frame:SetProperty("UnifiedPosition", g_XiaKeTL_Info_Frame_UnifiedPosition)

	-- XiaKeTL_Info_Frame:SetProperty("UnifiedXPosition", g_XiaKeTL_Info_Frame_UnifiedXPosition);
	-- XiaKeTL_Info_Frame:SetProperty("UnifiedYPosition", g_XiaKeTL_Info_Frame_UnifiedYPosition);

end