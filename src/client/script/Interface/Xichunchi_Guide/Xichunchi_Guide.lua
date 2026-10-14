--新服整合界面逻辑

local g_Xichunchi_Guide_Frame_UnifiedPosition
local g_Xichunchi_Guide_UIRed = {}			--功能按钮小红点

local g_Xichunchi_Guide_BoxUIButton = {}	--服务器进度领奖按钮
local g_Xichunchi_Guide_BoxUIDone = {}		--服务器进度已领奖图片
local g_Xichunchi_Guide_BoxUINotYet = {}	--服务器进度不可领奖图片

local g_Xichunchi_Guide_AwardNum = {
	[1] = 20000,
	[2] = 50000,
	[3] = 100000,
	[4] = 170000,
	[5] = 240000,
	[6] = 320000,
	[7] = 400000,
	[8] = 500000,
	[9] = 600000,
	[10] = 700000,
}

local g_Xichunchi_Guide_RewardActionItem = {
	[1] = {39923218,30008127},
	[2] = {39923218,38000831,39923221},
	[3] = {39923218,30008127,39923222},
	[4] = {39923218,38000831,39923220},
	[5] = {39923218,30008127},
	[6] = {39923218,38000831,39923267},
	[7] = {39923218,38001197},
	[8] = {39923218,30008130,39923268},
	[9] = {39923218,38001197},
	[10] = {39923218,30008130},
}

local g_Xichunchi_Guide_RewardActionItemNum = {
	[1] = {60,1},
	[2] = {60,1,1},
	[3] = {60,1,1},
	[4] = {60,1,1},
	[5] = {60,2},
	[6] = {60,2,1},
	[7] = {60,1},
	[8] = {60,1,1},
	[9] = {60,2},
	[10] = {60,2},
}

local g_Xichunchi_Guide_UIRedInd = {
	[1] = 31,
	[2] = 32,
	[3] = 33,
}

local g_Xichunchi_Box_Count = 10			--箱子数量				
local g_Xichunchi_Progress = 0				--服务器进度值
local g_Xichunchi_Page_Index = 1			--当前页面
local g_Xichunchi_Box_State = {}			--箱子状态　0表示不可领取，1表示可以领取未领取，2表示可以领取已经领取

local g_Xichunchi_ActionButton = {}
--=========
-- PreLoad
--=========
function Xichunchi_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI",false)
	
end

--=========
-- OnLoad()
--=========
function Xichunchi_Guide_OnLoad()
	g_Xichunchi_Guide_Frame_UnifiedPosition = Xichunchi_Guide_Frame:GetProperty("UnifiedPosition")
	
	g_Xichunchi_Guide_UIRed[1] = Xichunchi_Guide_Btn2_Tips
	g_Xichunchi_Guide_UIRed[2] = Xichunchi_Guide_Btn5_Tips
	g_Xichunchi_Guide_UIRed[3] = Xichunchi_Guide_Btn3_Tips
	
	g_Xichunchi_Guide_BoxUIButton[1] = Xichunchi_Guide_Reward1_Btn1
	g_Xichunchi_Guide_BoxUIButton[2] = Xichunchi_Guide_Reward2_Btn1
	g_Xichunchi_Guide_BoxUIButton[3] = Xichunchi_Guide_Reward3_Btn1
	g_Xichunchi_Guide_BoxUIButton[4] = Xichunchi_Guide_Reward4_Btn1
	g_Xichunchi_Guide_BoxUIButton[5] = Xichunchi_Guide_Reward5_Btn1
	g_Xichunchi_Guide_BoxUIButton[6] = Xichunchi_Guide_Reward6_Btn1
	g_Xichunchi_Guide_BoxUIButton[7] = Xichunchi_Guide_Reward7_Btn1
	g_Xichunchi_Guide_BoxUIButton[8] = Xichunchi_Guide_Reward8_Btn1
	g_Xichunchi_Guide_BoxUIButton[9] = Xichunchi_Guide_Reward9_Btn1
	g_Xichunchi_Guide_BoxUIButton[10] = Xichunchi_Guide_Reward10_Btn1
	
	g_Xichunchi_Guide_BoxUIDone[1] = Xichunchi_Guide_Reward1_Pic1
	g_Xichunchi_Guide_BoxUIDone[2] = Xichunchi_Guide_Reward2_Pic1
	g_Xichunchi_Guide_BoxUIDone[3] = Xichunchi_Guide_Reward3_Pic1
	g_Xichunchi_Guide_BoxUIDone[4] = Xichunchi_Guide_Reward4_Pic1
	g_Xichunchi_Guide_BoxUIDone[5] = Xichunchi_Guide_Reward5_Pic1
	g_Xichunchi_Guide_BoxUIDone[6] = Xichunchi_Guide_Reward6_Pic1
	g_Xichunchi_Guide_BoxUIDone[7] = Xichunchi_Guide_Reward7_Pic1
	g_Xichunchi_Guide_BoxUIDone[8] = Xichunchi_Guide_Reward8_Pic1
	g_Xichunchi_Guide_BoxUIDone[9] = Xichunchi_Guide_Reward9_Pic1
	g_Xichunchi_Guide_BoxUIDone[10] = Xichunchi_Guide_Reward10_Pic1
	
	g_Xichunchi_Guide_BoxUINotYet[1] = Xichunchi_Guide_Reward1_Pic2
	g_Xichunchi_Guide_BoxUINotYet[2] = Xichunchi_Guide_Reward2_Pic2
	g_Xichunchi_Guide_BoxUINotYet[3] = Xichunchi_Guide_Reward3_Pic2
	g_Xichunchi_Guide_BoxUINotYet[4] = Xichunchi_Guide_Reward4_Pic2
	g_Xichunchi_Guide_BoxUINotYet[5] = Xichunchi_Guide_Reward5_Pic2
	g_Xichunchi_Guide_BoxUINotYet[6] = Xichunchi_Guide_Reward6_Pic2
	g_Xichunchi_Guide_BoxUINotYet[7] = Xichunchi_Guide_Reward7_Pic2
	g_Xichunchi_Guide_BoxUINotYet[8] = Xichunchi_Guide_Reward8_Pic2
	g_Xichunchi_Guide_BoxUINotYet[9] = Xichunchi_Guide_Reward9_Pic2
	g_Xichunchi_Guide_BoxUINotYet[10] = Xichunchi_Guide_Reward10_Pic2
	
	
	g_Xichunchi_Box_State[1] = 0
	g_Xichunchi_Box_State[2] = 0
	g_Xichunchi_Box_State[3] = 0
	g_Xichunchi_Box_State[4] = 0
	g_Xichunchi_Box_State[5] = 0
	g_Xichunchi_Box_State[6] = 0
	g_Xichunchi_Box_State[7] = 0
	g_Xichunchi_Box_State[8] = 0
	g_Xichunchi_Box_State[9] = 0
	g_Xichunchi_Box_State[10] = 0

	g_Xichunchi_ActionButton[1] = {Xichunchi_Guide_Reward1_BasicItem1,Xichunchi_Guide_Reward1_BasicItem2}
	g_Xichunchi_ActionButton[2] = {Xichunchi_Guide_Reward2_BasicItem1,Xichunchi_Guide_Reward2_BasicItem2,Xichunchi_Guide_Reward2_BasicItem3}
	g_Xichunchi_ActionButton[3] = {Xichunchi_Guide_Reward3_BasicItem1,Xichunchi_Guide_Reward3_BasicItem2,Xichunchi_Guide_Reward3_BasicItem3}
	g_Xichunchi_ActionButton[4] = {Xichunchi_Guide_Reward4_BasicItem1,Xichunchi_Guide_Reward4_BasicItem2,Xichunchi_Guide_Reward4_BasicItem3}
	g_Xichunchi_ActionButton[5] = {Xichunchi_Guide_Reward5_BasicItem1,Xichunchi_Guide_Reward5_BasicItem2}
	g_Xichunchi_ActionButton[6] = {Xichunchi_Guide_Reward6_BasicItem1,Xichunchi_Guide_Reward6_BasicItem2,Xichunchi_Guide_Reward6_BasicItem3}
	g_Xichunchi_ActionButton[7] = {Xichunchi_Guide_Reward7_BasicItem1,Xichunchi_Guide_Reward7_BasicItem2}
	g_Xichunchi_ActionButton[8] = {Xichunchi_Guide_Reward8_BasicItem1,Xichunchi_Guide_Reward8_BasicItem2,Xichunchi_Guide_Reward8_BasicItem3}
	g_Xichunchi_ActionButton[9] = {Xichunchi_Guide_Reward9_BasicItem1,Xichunchi_Guide_Reward9_BasicItem2}
	g_Xichunchi_ActionButton[10] = {Xichunchi_Guide_Reward10_BasicItem1,Xichunchi_Guide_Reward10_BasicItem2}

end

--=========
-- Event
--=========
function Xichunchi_Guide_OnEvent(event)
	if event == "UI_COMMAND" then
		local commandIndex = tonumber(arg0)
 		if commandIndex == 8883411 then
			Xichunchi_Guide_FlashUIRedPoint()
			this:Show()
		elseif commandIndex == 8883412 then
			g_Xichunchi_Progress = Get_XParam_INT(0)
			
			for i = 1, g_Xichunchi_Box_Count do
				g_Xichunchi_Box_State[i] = Get_XParam_INT(i)
			end
			
			Xichunchi_Guide_FlashUIBoxState()
		elseif commandIndex == 88834701 then
			Xichunchi_Guide_AutoRun(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2))
		end
	elseif event == "UPDATE_REDPOINT_IN_UI" then
		Xichunchi_Guide_FlashUIRedPoint()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Xichunchi_Guide_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Xichunchi_Guide_On_ResetPos()
	end

end


--=========
-- 重置
--=========
function Xichunchi_Guide_On_ResetPos()

	Xichunchi_Guide_Frame:SetProperty("UnifiedPosition", g_Xichunchi_Guide_Frame_UnifiedPosition)

end

function Xichunchi_Guide_Close()
	this:Hide()
end

--=========
-- 问号帮助
--=========
function Xichunchi_Guide_Description_Clicked()
	PushEvent("CCSHOP_HELP", 130)
end

--=========
-- 打开界面
--=========
function Xichunchi_Guide_Clicked( ind )
	if IsInTServer() == 1 then
		PushDebugMessage("#{GQKJ_190722_22}")
		return
	end
	
	if ind == 1 then
		--砸金蛋
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenXiChunChiUI")
		Set_XSCRIPT_ScriptID(888342)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif ind == 2 then
		--悬赏
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenBountyMissionUI")
		Set_XSCRIPT_ScriptID(506100)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif ind == 3 then
		--撒箱子
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnJoinActivity")
		Set_XSCRIPT_ScriptID(888347)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end

--===================
-- 服务器进度点击领奖
--===================
function Xichunchi_Guide_Reward_Clicked( ind )
	if IsInTServer() == 1 then
		PushDebugMessage("#{GQKJ_190722_22}")
		return
	end
	
	-- 领取礼包
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CallByClient")
		Set_XSCRIPT_ScriptID(888267)
		Set_XSCRIPT_Parameter(0, ind)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=========
-- 分页切换
--=========
function Xichunchi_Guide_PageClick( ind )
	g_Xichunchi_Page_Index = ind
	Xichunchi_Guide_FlashUIBoxState()
end

--===========
-- 刷新UI红点
--===========
function Xichunchi_Guide_FlashUIRedPoint()
	for i = 1, table.getn(g_Xichunchi_Guide_UIRedInd) do
		local nUIInd = g_Xichunchi_Guide_UIRedInd[i]
		if DataPool:Lua_IsRedPointInUIShow( nUIInd ) == 1 then
			g_Xichunchi_Guide_UIRed[i]:Show()
		else
			g_Xichunchi_Guide_UIRed[i]:Hide()
		end
	end
end

--=============
-- 刷新宝箱状态
--=============
function Xichunchi_Guide_FlashUIBoxState()
	if g_Xichunchi_Page_Index == 2 then
		Xichunchi_Guide_Reward_Page1 : Hide()
		Xichunchi_Guide_Reward_Page2 : Show()
	else
		Xichunchi_Guide_Reward_Page1 : Show()
		Xichunchi_Guide_Reward_Page2 : Hide()
	end

	--清空ActionButton
	Xichunchi_Guide_ClearAllActionItem()
	
	--刷新进度
	Xichunchi_Guide_ServerProgress_Text:SetText("#I" .. g_Xichunchi_Progress)
	
	--刷箱子状态
	--local pageBoxCount = table.getn(g_Xichunchi_Box_State)/2
	for boxInd = 1, g_Xichunchi_Box_Count do
		--刷状态
		local boxState = g_Xichunchi_Box_State[boxInd]
		g_Xichunchi_Guide_BoxUIButton[boxInd]:Hide()
		g_Xichunchi_Guide_BoxUIDone[boxInd]:Hide()
		g_Xichunchi_Guide_BoxUINotYet[boxInd]:Hide()
		if boxState == 1 then
			g_Xichunchi_Guide_BoxUIButton[boxInd]:Show()
		elseif boxState == 2 then
			g_Xichunchi_Guide_BoxUIDone[boxInd]:Show()
		elseif boxState == 0 then
			g_Xichunchi_Guide_BoxUINotYet[boxInd]:Show()
			local sTip = ScriptGlobal_Format("#{FWQJD_210114_22}", g_Xichunchi_Guide_AwardNum[boxInd])
			g_Xichunchi_Guide_BoxUINotYet[boxInd]:SetToolTip(sTip)
		end
		
		--刷actionbutton
		local rewardItemBuf =  g_Xichunchi_Guide_RewardActionItem[boxInd]
		local actionBtBuf = g_Xichunchi_ActionButton[boxInd]
		local rewardItemNumBuf = g_Xichunchi_Guide_RewardActionItemNum[boxInd]
		for j = 1, table.getn(rewardItemBuf) do
			local rewardItemid = rewardItemBuf[j]
			local actionBtn = actionBtBuf[j]
			local rewardItemNum = rewardItemNumBuf[j]
			
			local theAction = DataPool:CreateActionItemForShow(rewardItemid, rewardItemNum)
			if theAction:GetID() ~= 0 then
				actionBtn:SetActionItem(theAction:GetID())
				actionBtn:Show()
			end	
		end
	end	
end

--==================
-- 清空actionbutton
--==================
function Xichunchi_Guide_ClearAllActionItem()
	for i = 1, table.getn(g_Xichunchi_ActionButton) do
		local btBuf = g_Xichunchi_ActionButton[i]
		for j = 1, table.getn(btBuf) do
			btBuf[j]:Hide()
		end
	end
	
	for i = 1, table.getn(g_Xichunchi_Guide_BoxUINotYet) do
		g_Xichunchi_Guide_BoxUINotYet[i]:SetToolTip("")
	end
end



--====================
-- 寻路到撒箱子地点
--====================
function Xichunchi_Guide_AutoRun(clientSceneId,posX,posZ)
	AutoRunToTargetEx(posX,posZ,clientSceneId)
end