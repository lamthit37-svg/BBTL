--武意经验找回界面

local g_Martial_ZhaoHui_Frame_UnifiedXPosition
local g_Martial_ZhaoHui_Frame_UnifiedYPosition
local g_Martial_ZhaoHui_CurPage = 0
local g_Martial_ZhaoHui_MaxMartialLevel = 150



local g_Martial_ZhaoHui_ScriptId = 507010

local g_Martial_ZhaoHui_ExpTable = 
{
	[1] = {[1] = 1450,[2] = 2900},
	[2] = {[1] = 1500,[2] = 3000},
	[3] = {[1] = 1550,[2] = 3100},
	[4] = {[1] = 1600,[2] = 3200},
	[5] = {[1] = 1650,[2] = 3300},
}

local g_Martial_ZhaoHui_MaxMonsterNum = 3000
local g_Martial_ZhaoHui_MartialZhaoHuiJiaozi = 600000
local g_Martial_ZhaoHui_YuanBao = 360

local g_Martial_ZhaoHui_MaxLevelExp = 0
local g_Martial_ZhaoHui_ZhaoHuiBeginDay = 20171120
--===============================================
-- OnLoad()
--===============================================
function Martial_ZhaoHui_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("SHOW_MARTIAL_ZHAOHUI")
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("MARTIAL_UPDATE")
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("UPDATE_YUANBAO",false)
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)
	this:RegisterEvent("MARTIAL_ZHAOHUI_SUCCESS",false)
	

end

function Martial_ZhaoHui_OnLoad()
	-- 保存界面的默认相对位置
	g_Martial_ZhaoHui_Frame_UnifiedXPosition	= Martial_ZhaoHui_Frame : GetProperty("UnifiedXPosition");
	g_Martial_ZhaoHui_Frame_UnifiedYPosition	= Martial_ZhaoHui_Frame : GetProperty("UnifiedYPosition");
end


--===============================================
-- OnEvent()
--===============================================
function Martial_ZhaoHui_OnEvent(event)

	if(event == "SHOW_MARTIAL_ZHAOHUI") then
		this:Hide()
		g_Martial_ZhaoHui_MaxLevelExp = tonumber(arg0)
		Maritial_ZhaoHui_Refresh()
	elseif(event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" or event == "UPDATE_YUANBAO") then
		Maritial_ZhaoHui_RefreshMyMoney()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		Martial_ZhaoHui_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		Martial_ZhaoHui_Frame_On_ResetPos()
	elseif (event == "PLAYER_ENTERING_WORLD" or event == "MARTIAL_ZHAOHUI_SUCCESS") then
		Martial_ZhaoHui_Frame_OnHiden()
	end
end

--===============================================
-- OnHiden
--===============================================
function Martial_ZhaoHui_Frame_OnHiden()
	this:Hide()
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Martial_ZhaoHui_Frame_On_ResetPos()

	Martial_ZhaoHui_Frame : SetProperty("UnifiedXPosition", g_Martial_ZhaoHui_Frame_UnifiedXPosition);
	Martial_ZhaoHui_Frame : SetProperty("UnifiedYPosition", g_Martial_ZhaoHui_Frame_UnifiedYPosition);

end
function Martial_ZhaoHui_OnMoved()
	return
end

function Martial_ZhaoHui_OnClosed()
	Martial_ZhaoHui_Frame_OnHiden()
end

function Maritial_ZhaoHui_BaseCheck()
	--安全时间内不能操作
	if(DataPool:GetForeverLock() == true or DataPool:GetLeftProtectTime() > 0 ) then
		PushDebugMessage("#{BYFUR_160531_48}")
		return 0
	end
	--密保 二级密码
	if(CheckPhoneMibaoAndMinorPassword() == 0) then
		return 0
	end
	--是否完成武意突破
	if(MaritialSys:HasFinishWuYiMisson() ~= 1) then
		PushDebugMessage("#{WYXT_20170803_21}")
		return 0
	end
	return 1
end

function Martial_ZhaoHui_ZhaoHuiClick(nType)
	if(Maritial_ZhaoHui_BaseCheck() ~= 1 ) then
		return
	end
	--开服当天不允许找回
	local curDay = tonumber(DataPool:GetServerDayTime());
	if(curDay <= g_Martial_ZhaoHui_ZhaoHuiBeginDay) then
		PushDebugMessage("#{WYXT_20170907_432}")
		return
	end
	--检查是否满级
	local lvl = MaritialSys:GetMaritiaLevel()
	if(lvl >= g_Martial_ZhaoHui_MaxMartialLevel) then
		PushDebugMessage("#{WYXT_20170907_420}")
		return
	end
	--检查是否可以找回
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	if(nMonsterNum <= 0) then
		PushDebugMessage("#{WYXT_20170907_398}")
		return
	end
	if(nReward >= 1) then
		PushDebugMessage( "#{WYXT_20170907_397}")
		return
	end
	local nLevelIndex = Maritial_ZhaoHui_PlayerLevel2Index()
	local RealMonsterNum1 = nMonsterNum
	local RealMonsterNum2 = nMonsterNum
	local nMonsterRealNum = nMonsterNum
	local nCostNum = 0
	local nRewardExp = 0
	local RewardExp1 = g_Martial_ZhaoHui_ExpTable[nLevelIndex][1] * nMonsterNum;
	local RewardExp2 = g_Martial_ZhaoHui_ExpTable[nLevelIndex][2] * nMonsterNum;
	if(lvl + 1 == g_Martial_ZhaoHui_MaxMartialLevel and g_Martial_ZhaoHui_MaxLevelExp > 0) then
		local nCurExp = MaritialSys:GetMaritiaExp()
		local nMaxNeedExp = g_Martial_ZhaoHui_MaxLevelExp - nCurExp
		if(nMaxNeedExp > 0) then
			if(RewardExp1 > nMaxNeedExp) then
				RealMonsterNum1 =  math.ceil(nMaxNeedExp / g_Martial_ZhaoHui_ExpTable[nLevelIndex][1])
				RewardExp1 = nMaxNeedExp
			end
			if(RewardExp2 > nMaxNeedExp) then
				RealMonsterNum2 =  math.ceil(nMaxNeedExp / g_Martial_ZhaoHui_ExpTable[nLevelIndex][2])
				RewardExp2 = nMaxNeedExp
			end
		end
	end
	--检查金钱
	if(1 == nType ) then
		local money = Player:GetData("MONEY")+Player:GetData("MONEY_JZ");
		local nNeedMoney = math.ceil((g_Martial_ZhaoHui_MartialZhaoHuiJiaozi / g_Martial_ZhaoHui_MaxMonsterNum) * RealMonsterNum1)
		if money < nNeedMoney then
			PushDebugMessage(ScriptGlobal_Format("#{WYXT_20170907_414}",nNeedMoney))
			return
		end
		nCostNum = nNeedMoney
		nMonsterRealNum = RealMonsterNum1
		nRewardExp = RewardExp1
		
		--增加二次确认
		PushEvent("MARTIAL_ZHAOHUI_COMFIRM",nType,nMonsterRealNum,nCostNum,nRewardExp,nMonsterNum)
	
	elseif(2 == nType) then
		
		-- 直接向服务器发送消息 --元宝找回
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "MartialLastDayMonsterReward" )
			Set_XSCRIPT_ScriptID( 507010 )
			Set_XSCRIPT_Parameter(0,nType)
			Set_XSCRIPT_Parameter(1,0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	else
		return
	end
	return
	-- Clear_XSCRIPT()
		-- Set_XSCRIPT_Function_Name( "MartialLastDayMonsterReward" )
		-- Set_XSCRIPT_ScriptID( g_Martial_ZhaoHui_ScriptId )
		-- Set_XSCRIPT_Parameter(0,nType)
		-- Set_XSCRIPT_ParamCount(1)
	-- Send_XSCRIPT()
end

function Maritial_ZhaoHui_RefreshText()
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nExpalain = ScriptGlobal_Format("#{WYXT_20170907_399}",nMonsterNum)
	local nLevelIndex = Maritial_ZhaoHui_PlayerLevel2Index()
	local lvl = MaritialSys:GetMaritiaLevel()
	local RealMonsterNum1 = nMonsterNum
	local RealMonsterNum2 = nMonsterNum
	local RewardExp1 = g_Martial_ZhaoHui_ExpTable[nLevelIndex][1] * nMonsterNum;
	local RewardExp2 = g_Martial_ZhaoHui_ExpTable[nLevelIndex][2] * nMonsterNum;
	
	if(lvl + 1 == g_Martial_ZhaoHui_MaxMartialLevel and nReward == 0 and g_Martial_ZhaoHui_MaxLevelExp > 0) then
		local nCurExp = MaritialSys:GetMaritiaExp()
		local nMaxNeedExp = g_Martial_ZhaoHui_MaxLevelExp - nCurExp
		if(nMaxNeedExp > 0) then
			if(RewardExp1 > nMaxNeedExp) then
				RealMonsterNum1 =  math.ceil(nMaxNeedExp / g_Martial_ZhaoHui_ExpTable[nLevelIndex][1])
				RewardExp1 = nMaxNeedExp
			end
			if(RewardExp2 > nMaxNeedExp) then
				RealMonsterNum2 =  math.ceil(nMaxNeedExp / g_Martial_ZhaoHui_ExpTable[nLevelIndex][2])
				RewardExp2 = nMaxNeedExp
			end
		end
	end
	
	local RightText = ""
	Martial_ZhaoHuiBasicInfo_Explain:SetText(nExpalain)
	
	--需要金钱
	local nNeedMoney = math.ceil((g_Martial_ZhaoHui_MartialZhaoHuiJiaozi / g_Martial_ZhaoHui_MaxMonsterNum) * RealMonsterNum1)
	RightText = RightText..ScriptGlobal_Format("#{WYXT_20170907_403}",nNeedMoney)

	--金钱内息
	RightText = RightText.."#r"..ScriptGlobal_Format("#{WYXT_20170907_401}",RewardExp1)
	Martial_ZhaoHuiContent2_Right:SetText(RightText)
	local LeftText = ""
	--需要元宝
	local nNeedYuanBao = math.ceil((g_Martial_ZhaoHui_YuanBao / g_Martial_ZhaoHui_MaxMonsterNum) * RealMonsterNum2)
	LeftText = LeftText .. ScriptGlobal_Format("#{WYXT_20170907_400}",nNeedYuanBao)

	--元宝内息
	LeftText = LeftText .."#r".. ScriptGlobal_Format("#{WYXT_20170907_401}",RewardExp2)
	Martial_ZhaoHuiContent2_Left:SetText(LeftText)
end

function Maritial_ZhaoHui_RefreshMyMoney()
	--交子
	local nJiaozi = tostring(Player:GetData("MONEY_JZ"))
	Martial_ZhaoHui_SelfJiaozi:SetProperty("MoneyNumber",""..nJiaozi)
	--金币
	local nGold = tostring(Player:GetData("MONEY"))
	Martial_ZhaoHui_SelfMoney:SetProperty("MoneyNumber",""..nGold)
	--元宝
	Martial_ZhaoHui_SelfYuanbao:SetText(tostring(Player:GetData("YUANBAO")))
end

function Maritial_ZhaoHui_Refresh()
	Maritial_ZhaoHui_RefreshText()
	Maritial_ZhaoHui_RefreshMyMoney()
	this:Show()
end

function Maritial_ZhaoHui_PlayerLevel2Index()
	local nLevel = Player:GetLevel()
	if(nLevel >= 85 and nLevel < 90) then
		return 1;
	elseif (nLevel >= 90 and nLevel < 100) then
		return 2;
	elseif (nLevel >= 100 and nLevel < 110) then
		return 3;
	elseif (nLevel >= 110 and nLevel < 120) then
		return 4;
	elseif (nLevel >= 120 and nLevel < 130) then
		return 5;
	else
		return 1;
	end
end
