-- 儿童节打地鼠活动（露荷撷香） 队长队员选择确认界面

-- 服务器脚本id
local ErtongjieHoudong_SvrScriptId = 998022

-- 保存UI默认位置
local ErtongjieHoudong_UnifiedPosition = nil
-- 控件列表
local ErtongjieHoudong_UITalbe = nil

-- NPC关注
local ErtongjieHoudong_CareObjId = -1
local ErtongjieHoudong_CareObjSvrId = -1
local ErtongjieHoudong_MAX_OBJ_DISTANCE = 5.0

-- 玉莲子玩法开关
local ErtongjieHoudong_YuLianZiOpenFlag = 0

-- 代币最大值
local ErtongjieHoudong_HonhLianZi_Max = 15
local ErtongjieHoudong_YuLianZi_Max = 200
-- 低级（红莲子）局消耗
local ErtongjieHoudong_Cost_HongLianZi = 15
-- 高级（玉莲子）局消耗
local ErtongjieHoudong_Cost_YuLianZi = -1
-- 当前选择的类型
local ErtongjieHoudong_CurChooseType = -1
-- 计时器ID
local ErtongjieHoudong_TimerID = -1
local ErtongjieHoudong_CountdownTimerID = -1
-- 倒计时时间（毫秒）
local ErtongjieHoudong_CountdownTime = 1000
-- 倒计时计数
local ErtongjieHoudong_CountdownTick = 30
-- 确认标记
local ErtongjieHoudong_ConfirmFlag = 0
-- 取消标记
local ErtongjieHoudong_AbortFlag = 0
-- 关闭标记 避免hide和onhidden之间循环调用
local ErtongjieHoudong_HideFlag = 0


-- 游戏类型 低级（红莲子）、高级（玉莲子）
local ErtongjieHoudong_GameType =
{
	honglianzi = 0,		-- 红莲子局
	yulianiz = 1,		-- 玉莲子局
} -- end ErtongjieHoudong_GameType

-- 状态值
local ErtongjieHoudong_State =
{
	wait = 0,		-- 等待
	confirm = 1,	-- 已确认
	cancel = 2,		-- 取消
	input = 3,		-- 输入
} -- end ErtongjieHoudong_State

-- 状态图标
local ErtongjieHoudong_StateImge =
{
	-- 等待
	[ErtongjieHoudong_State.wait] = "set:ErtongjieHoudong image:dengdai",
	-- 已确认
	[ErtongjieHoudong_State.confirm] = "set:ErtongjieHoudong image:queren",
	-- 取消（这个资源没有给 目前使用观山海的资源）
	[ErtongjieHoudong_State.cancel] = "set:GuanShanHai13 image:jujue",
	-- 正在输入
	[ErtongjieHoudong_State.input] = "set:ErtongjieHoudong image:zhengzaixuanze",
} -- end ErtongjieHoudong_StateImge



function ErtongjieHoudong_PreLoad()
	this:RegisterEvent("ETJFUBEN_2022_OPEN", true)
	this:RegisterEvent("ETJFUBEN_2022_START", true)
	this:RegisterEvent("ETJFUBEN_2022_ABORT", true)
	this:RegisterEvent("ETJFUBEN_2022_CONFIRM", true)
	this:RegisterEvent("ETJFUBEN_2022_CONFIRMFAILED", true)
	this:RegisterEvent("ETJFUBEN_2022_STARTFAILED", true)
	this:RegisterEvent("TEAM_MEMBER_LEAVE", true)
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end -- end func ErtongjieHoudong_PreLoad()

function ErtongjieHoudong_OnLoad()
	ErtongjieHoudong_UnifiedPosition = ErtongjieHoudong_Frame_BK:GetProperty("UnifiedPosition")
	
	ErtongjieHoudong_InitUITable()
end -- end func ErtongjieHoudong_OnLoad()

function ErtongjieHoudong_OnEvent(event)
	if (event == "ETJFUBEN_2022_OPEN") then
		ErtongjieHoudong_BeginCareObject(arg0, arg1)
		ErtongjieHoudong_Show(arg2)
		ErtongjieHoudong_UpdateMemberList()
	elseif (event == "ETJFUBEN_2022_START") then
		ErtongjieHoudong_OnStartGame()
	elseif (event == "ETJFUBEN_2022_ABORT") then
		ErtongjieHoudong_OnPlayerAbort()
		--ErtongjieHoudong_UpdateMemberList()
	elseif (event == "ETJFUBEN_2022_CONFIRM") then
		ErtongjieHoudong_MemberConfirmed(arg0, arg1, arg2, arg3)
	elseif (event == "ETJFUBEN_2022_CONFIRMFAILED") then
		ErtongjieHoudong_ConfirmFailed(arg0, arg1)
	elseif (event == "ETJFUBEN_2022_STARTFAILED") then
		ErtongjieHoudong_OnStartFailed(arg0)
	elseif (event == "TEAM_MEMBER_LEAVE") then
		ErtongjieHoudong_OnTeamMemberLeave()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= ErtongjieHoudong_CareObjId) then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2)>ErtongjieHoudong_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			--取消关心
			ErtongjieHoudong_Hide()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ErtongjieHoudong_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		ErtongjieHoudong_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ErtongjieHoudong_Hide()
	end
end -- end func ErtongjieHoudong_OnEvent()

function ErtongjieHoudong_On_ResetPos()
	ErtongjieHoudong_Frame_BK:SetProperty("UnifiedPosition", ErtongjieHoudong_UnifiedPosition)
end -- end func ErtongjieHoudong_On_ResetPos()

function ErtongjieHoudong_InitUITable()
	-- 初始化UI控件列表
	ErtongjieHoudong_UITalbe = {}

	-- 说明
	ErtongjieHoudong_UITalbe.tip = ErtongjieHoudong_Right_Text

	-- 代币信息
	ErtongjieHoudong_UITalbe.honglianzitext = ErtongjieHoudong_Right_HongText
	ErtongjieHoudong_UITalbe.yulianzitext = ErtongjieHoudong_Right_YuText

	-- 队伍成员信息
	ErtongjieHoudong_UITalbe.playerinfo = {}
	ErtongjieHoudong_UITalbe.playerinfo[1] =
	{
		frame = ErtongjieHoudong_Player1ClientBK,
		head = ErtongjieHoudong_Player1Head,
		name = ErtongjieHoudong_Player1Name,
		daibi = ErtongjieHoudong_Player1Num,
		state = ErtongjieHoudong_Player1_Choose,
	}
	ErtongjieHoudong_UITalbe.playerinfo[2] =
	{
		frame = ErtongjieHoudong_Player2ClientBK,
		head = ErtongjieHoudong_Player2Head,
		name = ErtongjieHoudong_Player2Name,
		daibi = ErtongjieHoudong_Player2Num,
		state = ErtongjieHoudong_Player2_Choose,
	}
	ErtongjieHoudong_UITalbe.playerinfo[3] =
	{
		frame = ErtongjieHoudong_Player3ClientBK,
		head = ErtongjieHoudong_Player3Head,
		name = ErtongjieHoudong_Player3Name,
		daibi = ErtongjieHoudong_Player3Num,
		state = ErtongjieHoudong_Player3_Choose,
	}
	ErtongjieHoudong_UITalbe.playerinfo[4] =
	{
		frame = ErtongjieHoudong_Player4ClientBK,
		head = ErtongjieHoudong_Player4Head,
		name = ErtongjieHoudong_Player4Name,
		daibi = ErtongjieHoudong_Player4Num,
		state = ErtongjieHoudong_Player4_Choose,
	}
	ErtongjieHoudong_UITalbe.playerinfo[5] =
	{
		frame = ErtongjieHoudong_Player5ClientBK,
		head = ErtongjieHoudong_Player5Head,
		name = ErtongjieHoudong_Player5Name,
		daibi = ErtongjieHoudong_Player5Num,
		state = ErtongjieHoudong_Player5_Choose,
	}
	ErtongjieHoudong_UITalbe.playerinfo[6] =
	{
		frame = ErtongjieHoudong_Player6ClientBK,
		head = ErtongjieHoudong_Player6Head,
		name = ErtongjieHoudong_Player6Name,
		daibi = ErtongjieHoudong_Player6Num,
		state = ErtongjieHoudong_Player6_Choose,
	}

	-- 队长选择UI
	ErtongjieHoudong_UITalbe.leaderctrl =
	{
		choosetip = ErtongjieHoudong_Right_InfoText1,
		typetip = ErtongjieHoudong_Right_Info1Text2,
		typeinfo = 
		{
			frame = ErtongjieHoudong_Right_Captain,
			junior =
			{
				frame = ErtongjieHoudong_Item1,
				mask = ErtongjieHoudong_Item1_Mask,
			},
			senior =
			{
				frame = ErtongjieHoudong_Item2,
				mask = ErtongjieHoudong_Item2_Mask,
			},
		},
		daibiinfo =
		{
			frame = ErtongjieHoudong_Right_NumBK,
			tip = ErtongjieHoudong_Right_Num_Text,
			num = ErtongjieHoudong_Right_InputNumBK,
			numtext = ErtongjieHoudong_Right_Num_Text2,
		},
	}

	-- 队员选择UI
	ErtongjieHoudong_UITalbe.memberctrl =
	{
		choosetip = ErtongjieHoudong_Right_InfoText1,
		typetip = ErtongjieHoudong_Right_Info1Text2,
		choosetext1 = ErtongjieHoudong_Right_member1,
		choosetext2 = ErtongjieHoudong_Right_member2,
		daibiinfo =
		{
			frame = ErtongjieHoudong_Right_NumBK,
			tip = ErtongjieHoudong_Right_Num_Text,
			num = ErtongjieHoudong_Right_InputNumBK,
			numtext = ErtongjieHoudong_Right_Num_Text2,
		},
	}

	-- 选择提示
	ErtongjieHoudong_UITalbe.choosetip1 = ErtongjieHoudong_Right_member3
	ErtongjieHoudong_UITalbe.choosetip2 = ErtongjieHoudong_Right_member4
	ErtongjieHoudong_UITalbe.choosetip3 = ErtongjieHoudong_Right_member5

	-- 队长标记
	ErtongjieHoudong_UITalbe.leaderflag = ErtongjieHoudong_Player1_Captain

	-- 确定、取消按钮
	ErtongjieHoudong_UITalbe.confirm = ErtongjieHoudong_Right_Info1_Choose
	ErtongjieHoudong_UITalbe.cancel = ErtongjieHoudong_Right_Info1_Waive
end -- end func ErtongjieHoudong_InitUITable()

function ErtongjieHoudong_Show(nType)
	local showType = tonumber(nType)

	if (not this:IsVisible()) then
		if (showType == ErtongjieHoudong_State.cancel) then
			return
		end

		this:Show()
			
		ErtongjieHoudong_AbortFlag = 0
		ErtongjieHoudong_ConfirmFlag = 0
		ErtongjieHoudong_HideFlag = 0

		ErtongjieHoudong_CurChooseType = -1

		if (ErtongjieHoudong_TimerID >= 0) then
			KillTimer(ErtongjieHoudong_TimerID)
			ErtongjieHoudong_TimerID = -1
		end
	end

	-- 设置关闭倒计时
	KillTimer("ErtongjieHoudong_Timeout()")
	if (ErtongjieHoudong_CountdownTimerID >= 0) then
		KillTimer(ErtongjieHoudong_CountdownTimerID)
		ErtongjieHoudong_CountdownTimerID = -1
	end
	ErtongjieHoudong_CountdownTimerID = SetTimer("ErtongjieHoudong", "ErtongjieHoudong_Timeout()", ErtongjieHoudong_CountdownTime)
	ErtongjieHoudong_CountdownTick = 30
end -- end func ErtongjieHoudong_Show()

function ErtongjieHoudong_Hide()
	if (ErtongjieHoudong_HideFlag <= 0 and ErtongjieHoudong_AbortFlag <= 0) then
		-- 直接关闭按取消处理
		ErtongjieHoudong_Clicked_Waive()
	end

	ErtongjieHoudong_StopCareObject(ErtongjieHoudong_CareObjId)

	if (ErtongjieHoudong_TimerID >= 0) then
		KillTimer(ErtongjieHoudong_TimerID)
	end
	if (ErtongjieHoudong_CountdownTimerID >= 0) then
		KillTimer(ErtongjieHoudong_CountdownTimerID)
	end
	ErtongjieHoudong_CountdownTick = 30

	KillTimer("ErtongjieHoudong_Hide()")
	KillTimer("ErtongjieHoudong_Timeout()")
	ErtongjieHoudong_TimerID = -1
	ErtongjieHoudong_CountdownTimerID = -1

	ErtongjieHoudong_CurChooseType = -1
	ErtongjieHoudong_ConfirmFlag = 0
	ErtongjieHoudong_AbortFlag = 0
	ErtongjieHoudong_HideFlag = 1

	this:Hide()
end -- end func ErtongjieHoudong_Hide()

function ErtongjieHoudong_OnHidden()
	if (ErtongjieHoudong_HideFlag <= 0) then
		if (ErtongjieHoudong_AbortFlag <= 0) then
			-- 直接关闭按取消处理
			ErtongjieHoudong_Clicked_Waive()
		end
	end

	if (ErtongjieHoudong_TimerID >= 0) then
		KillTimer(ErtongjieHoudong_TimerID)
	end
	if (ErtongjieHoudong_CountdownTimerID >= 0) then
		KillTimer(ErtongjieHoudong_CountdownTimerID)
	end
	ErtongjieHoudong_CountdownTick = 30

	KillTimer("ErtongjieHoudong_Hide()")
	KillTimer("ErtongjieHoudong_Timeout()")
	ErtongjieHoudong_TimerID = -1
	ErtongjieHoudong_CountdownTimerID = -1

	ErtongjieHoudong_ConfirmFlag = 0
	ErtongjieHoudong_AbortFlag = 0
end -- end func ErtongjieHoudong_OnHidden

--*************************************************************************************************
-- UI倒计时时间到 超时关闭
--*************************************************************************************************
function ErtongjieHoudong_Timeout()
	if (not this:IsVisible()) then
		KillTimer("ErtongjieHoudong_Timeout()")
		ErtongjieHoudong_CountdownTimerID = -1
		return
	end

	ErtongjieHoudong_CountdownTick = ErtongjieHoudong_CountdownTick - 1
	if (ErtongjieHoudong_CountdownTick >= 0) then
		if (ErtongjieHoudong_UITalbe.choosetip1:IsVisible()) then
			local msg = ScriptGlobal_Format("#{ETDDS_220406_106}", ErtongjieHoudong_CountdownTick)
			ErtongjieHoudong_UITalbe.choosetip1:SetText(msg)
		elseif (ErtongjieHoudong_UITalbe.choosetip2:IsVisible()) then
			local msg = ScriptGlobal_Format("#{ETDDS_220406_107}", ErtongjieHoudong_CountdownTick)
			ErtongjieHoudong_UITalbe.choosetip2:SetText(msg)
		elseif (ErtongjieHoudong_UITalbe.choosetip3:IsVisible()) then
			local msg = ScriptGlobal_Format("#{ETDDS_220406_115}", ErtongjieHoudong_CountdownTick)
			ErtongjieHoudong_UITalbe.choosetip3:SetText(msg)
		end

		if (ErtongjieHoudong_CountdownTick == 0) then
			-- 倒计时时间到
			-- 当前正在选择的队员
			local curChoose = LuHeXieXiang:GetCurChoose()
			-- 玩家自己的信息
			local myIndex, myLeaderflag, myDaibiNum1, myDaibiNum2, myDaibiCost, myState, myHead, myName = LuHeXieXiang:GetMySelfInfo()
			if (myIndex >= 0 and myIndex == curChoose) then
				-- 如果是轮到自己正在选择 置灰确认和取消按钮 关闭UI
				ErtongjieHoudong_UITalbe.confirm:Disable()
				ErtongjieHoudong_UITalbe.cancel:Disable()
				-- 关闭UI
				ErtongjieHoudong_AbortFlag = 1
				ErtongjieHoudong_Hide()

				-- 提示
				PushDebugMessage("#{ETDDS_220406_116}")
			end
		end
	elseif (ErtongjieHoudong_CountdownTick <= -1) then
		-- 到这里说明不是自己在选择 延时1秒关闭 防止玩家卡点确认 新的数据还没同步下来
		-- 置灰确认和取消按钮
		ErtongjieHoudong_UITalbe.confirm:Disable()
		ErtongjieHoudong_UITalbe.cancel:Disable()
		-- 关闭UI
		ErtongjieHoudong_AbortFlag = 1
		ErtongjieHoudong_Hide()

		-- 提示
		PushDebugMessage("#{ETDDS_220406_116}")
	end
end -- end func ErtongjieHoudong_Timeout()



--*************************************************************************************************
-- 游戏类型（低级、高级）选择事件
--*************************************************************************************************
function ErtongjieHoudong_Choose(index)
	local checkIndex = tonumber(index)
	if (checkIndex == 1) then
		-- 点击低级代币
		ErtongjieHoudong_CurChooseType = ErtongjieHoudong_GameType.honglianzi
		ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.junior.mask:Show()
		ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.senior.mask:Hide()
	elseif (checkIndex == 2) then
		-- 点击高级代币
		ErtongjieHoudong_CurChooseType = ErtongjieHoudong_GameType.yulianiz
		ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.junior.mask:Hide()
		ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.senior.mask:Show()
	else
		-- 按说不应该这样 那就默认选低级吧
		ErtongjieHoudong_CurChooseType = ErtongjieHoudong_GameType.honglianzi
		ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.junior.mask:Show()
		ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.senior.mask:Hide()
	end

	if (ErtongjieHoudong_YuLianZiOpenFlag <= 0) then
		-- 玉莲子玩法关闭时只有红莲子玩法
		ErtongjieHoudong_CurChooseType = ErtongjieHoudong_GameType.honglianzi
	end

	if (ErtongjieHoudong_CurChooseType == ErtongjieHoudong_GameType.honglianzi) then
		-- 红莲子局消耗固定 不允许填
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.tip:Hide()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:Hide()

		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.numtext:Show()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.numtext:SetText("#{ETDDS_220406_123}")
	else
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.tip:Show()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:Show()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.numtext:Hide()

		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:Enable()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetText("1")
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetProperty("DefaultEditBox", "True")
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetSelected(0, -1)
	end
end -- end func ErtongjieHoudong_Choose()

--*************************************************************************************************
-- 代币数量输入事件
--*************************************************************************************************
function ErtongjieHoudong_Right_TextChanged()
	local numText = ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:GetText()
	local gameType = -1
	if (ErtongjieHoudong_CurChooseType >= 0) then
		gameType = ErtongjieHoudong_CurChooseType
	else
		gameType = LuHeXieXiang:GetFBLevel()
	end

	if (ErtongjieHoudong_YuLianZiOpenFlag <= 0) then
		-- 玉莲子玩法关闭时只有红莲子玩法
		gameType = ErtongjieHoudong_GameType.honglianzi
	end

	if (gameType == ErtongjieHoudong_GameType.honglianzi) then
		-- 红莲子局		
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.tip:Hide()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:Hide()

		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.numtext:Show()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.numtext:SetText("#{ETDDS_220406_123}")
	elseif (gameType == ErtongjieHoudong_GameType.yulianiz) then
		-- 玉莲子局
		if (numText ~= nil and numText ~= "") then
			local inputNum = tonumber(numText)
			local maxNum = ErtongjieHoudong_YuLianZi_Max

			if (numText == "00") then
				ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetText("0")
				ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetSelected(0, -1)
			elseif (numText == "000") then
				ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetText("0")
				ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetSelected(0, -1)
			else
				if (maxNum >= 0 and inputNum > 0) then
					local curCost = LuHeXieXiang:GetDaiBiCost()
					local maxValidNum = maxNum - curCost
					if (maxValidNum < 0) then
						maxValidNum = 0
					end
	
					if (inputNum > maxValidNum) then
						ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetText(tostring(maxValidNum))
						ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetSelected(0, -1)

						if (maxValidNum == 0) then
							PushDebugMessage("#{ETDDS_220406_121}")
						else
							local tipMsg = ScriptGlobal_Format("#{ETDDS_220406_122}", maxValidNum)
							PushDebugMessage(tipMsg)
						end
					end
				end
			end
		else
			ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetText("0")
			ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetSelected(0, -1)
		end
	end
end -- end func ErtongjieHoudong_Right_TextChanged()

--*************************************************************************************************
-- 隐藏队长相关UI
--*************************************************************************************************
function ErtongjieHoudong_Leader_ControlsHide()
	ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.frame:Hide()
	ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.frame:Hide()
end -- end func ErtongjieHoudong_Leader_ControlsHide()

--*************************************************************************************************
-- 显示队长相关UI
--*************************************************************************************************
function ErtongjieHoudong_Leader_ControlsShow()
	ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.frame:Show()
	ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.frame:Show()
end -- end func ErtongjieHoudong_Leader_ControlsShow()

--*************************************************************************************************
-- 隐藏队员相关UI
--*************************************************************************************************
function ErtongjieHoudong_Member_ControlsHide()
	ErtongjieHoudong_UITalbe.memberctrl.choosetext1:Hide()
	ErtongjieHoudong_UITalbe.memberctrl.choosetext2:Hide()
	ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.frame:Hide()
end -- end func ErtongjieHoudong_Member_ControlsHide()

--*************************************************************************************************
-- 显示队员相关UI
--*************************************************************************************************
function ErtongjieHoudong_Member_ControlsShow()
	ErtongjieHoudong_UITalbe.memberctrl.choosetext1:Show()
	ErtongjieHoudong_UITalbe.memberctrl.choosetext2:Hide()
	ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.frame:Show()
end -- end func ErtongjieHoudong_Member_ControlsShow()

--*************************************************************************************************
-- 队长 队长选择中
--*************************************************************************************************
function ErtongjieHoudong_Leader_Choosing()
	ErtongjieHoudong_Member_ControlsHide()
	ErtongjieHoudong_Leader_ControlsShow()

	-- 玩家自己的信息
	local myIndex, myLeaderflag, myDaibiNum1, myDaibiNum2, myDaibiCost, myState, myHead, myName = LuHeXieXiang:GetMySelfInfo()
	if (myIndex < 0) then
		return
	end

	-- 说明
	ErtongjieHoudong_UITalbe.tip:SetText("#{ETDDS_220406_33}")

	-- 代币信息
	local honglianziNum = ScriptGlobal_Format("#{ETDDS_220406_103}", myDaibiNum1)
	ErtongjieHoudong_UITalbe.honglianzitext:SetText(honglianziNum)
	local yulianziNum = ScriptGlobal_Format("#{ETDDS_220406_104}", myDaibiNum2)
	ErtongjieHoudong_UITalbe.yulianzitext:SetText(yulianziNum)

	-- 游戏类型选择
	ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.junior.frame:Enable()
	ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.senior.frame:Enable()
	-- 低级（红莲子局） 默认
	ErtongjieHoudong_CurChooseType = ErtongjieHoudong_GameType.honglianzi
	ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.junior.mask:Show()
	-- 高级（玉莲子局）
	ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.senior.mask:Hide()

	-- 投入代币数量
	if (ErtongjieHoudong_CurChooseType == ErtongjieHoudong_GameType.honglianzi) then
		-- 红莲子局消耗固定 不允许填
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.tip:Hide()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:Hide()

		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.numtext:Show()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.numtext:SetText("#{ETDDS_220406_123}")
	else
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.tip:Show()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:Show()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.numtext:Hide()

		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:Enable()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetText("0")
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetProperty("DefaultEditBox", "True")
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetSelected(0, -1)
	end

	-- 选择提示
	ErtongjieHoudong_UITalbe.choosetip1:Hide()
	ErtongjieHoudong_UITalbe.choosetip2:Hide()
	ErtongjieHoudong_UITalbe.choosetip3:Show()
	local msg = ScriptGlobal_Format("#{ETDDS_220406_115}", ErtongjieHoudong_CountdownTick)
	ErtongjieHoudong_UITalbe.choosetip3:SetText(msg)
	

	-- 确认、取消按钮
	if (ErtongjieHoudong_AbortFlag > 0) then
		ErtongjieHoudong_UITalbe.confirm:Disable()
		ErtongjieHoudong_UITalbe.cancel:Disable()
	else
		ErtongjieHoudong_UITalbe.confirm:Enable()
		ErtongjieHoudong_UITalbe.cancel:Enable()
	end
end -- end func ErtongjieHoudong_Leader_Choosing()

--*************************************************************************************************
-- 队长 队员选择中
--*************************************************************************************************
function ErtongjieHoudong_Leader_Wait()
	ErtongjieHoudong_Member_ControlsHide()
	ErtongjieHoudong_Leader_ControlsShow()

	local gameType = LuHeXieXiang:GetFBLevel()
	-- 玩家自己的信息
	local myIndex, myLeaderflag, myDaibiNum1, myDaibiNum2, myDaibiCost, myState, myHead, myName = LuHeXieXiang:GetMySelfInfo()
	if (myIndex < 0) then
		return
	end

	-- 说明
	ErtongjieHoudong_UITalbe.tip:SetText("#{ETDDS_220406_102}")
	
	-- 代币信息
	local honglianziNum = ScriptGlobal_Format("#{ETDDS_220406_103}", myDaibiNum1)
	ErtongjieHoudong_UITalbe.honglianzitext:SetText(honglianziNum)
	local yulianziNum = ScriptGlobal_Format("#{ETDDS_220406_104}", myDaibiNum2)
	ErtongjieHoudong_UITalbe.yulianzitext:SetText(yulianziNum)

	-- 游戏类型
	if (gameType == ErtongjieHoudong_GameType.honglianzi) then
		ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.junior.mask:Show()
		ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.senior.mask:Hide()
	else
		ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.junior.mask:Hide()
		ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.senior.mask:Show()
	end
	ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.junior.frame:Disable()
	ErtongjieHoudong_UITalbe.leaderctrl.typeinfo.senior.frame:Disable()

	-- 投入代币
	ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.frame:Show()
	if (gameType == ErtongjieHoudong_GameType.honglianzi) then
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.tip:Hide()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:Hide()

		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.numtext:Show()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.numtext:SetText("#{ETDDS_220406_123}")
	else
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.tip:Show()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:Show()
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.numtext:Hide()

		if (myDaibiCost ~= nil and myDaibiCost >= 0) then
			ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetText(tostring(myDaibiCost))
		else
			ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetText("0")
		end

		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetProperty("DefaultEditBox", "False")
		ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:Disable()
	end

	-- 选择提示
	ErtongjieHoudong_UITalbe.choosetip1:Hide()
	ErtongjieHoudong_UITalbe.choosetip2:Show()
	local msg = ScriptGlobal_Format("#{ETDDS_220406_107}", ErtongjieHoudong_CountdownTick)
	ErtongjieHoudong_UITalbe.choosetip2:SetText(msg)
	ErtongjieHoudong_UITalbe.choosetip3:Hide()

	-- 确认、取消按钮
	if (ErtongjieHoudong_AbortFlag > 0) then
		ErtongjieHoudong_UITalbe.confirm:Disable()
		ErtongjieHoudong_UITalbe.cancel:Disable()
	else
		ErtongjieHoudong_UITalbe.confirm:Disable()
		--ErtongjieHoudong_UITalbe.cancel:Disable()
		ErtongjieHoudong_UITalbe.cancel:Enable()
	end
end -- end func ErtongjieHoudong_Leader_Wait()

--*************************************************************************************************
-- 队员 自己选择中
--*************************************************************************************************
function ErtongjieHoudong_Member_Choosing()
	ErtongjieHoudong_Leader_ControlsHide()
	ErtongjieHoudong_Member_ControlsShow()

	local gameType = LuHeXieXiang:GetFBLevel()
	-- 玩家自己的信息
	local myIndex, myLeaderflag, myDaibiNum1, myDaibiNum2, myDaibiCost, myState, myHead, myName = LuHeXieXiang:GetMySelfInfo()
	if (myIndex < 0) then
		return
	end

	-- 说明
	ErtongjieHoudong_UITalbe.tip:SetText("#{ETDDS_220406_102}")

	-- 代币信息
	local honglianziNum = ScriptGlobal_Format("#{ETDDS_220406_103}", myDaibiNum1)
	ErtongjieHoudong_UITalbe.honglianzitext:SetText(honglianziNum)
	local yulianziNum = ScriptGlobal_Format("#{ETDDS_220406_104}", myDaibiNum2)
	ErtongjieHoudong_UITalbe.yulianzitext:SetText(yulianziNum)
	
	-- 选择类型提示
	local typeStr = ""
	if (gameType == ErtongjieHoudong_GameType.honglianzi) then
		typeStr = "#{ETDDS_220406_38}"
	else
		typeStr = "#{ETDDS_220406_39}"
	end
	ErtongjieHoudong_UITalbe.memberctrl.choosetext1:SetText(typeStr)
	ErtongjieHoudong_UITalbe.memberctrl.choosetext2:Hide()

	-- 投入代币
	ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.frame:Show()
	if (gameType == ErtongjieHoudong_GameType.honglianzi and ErtongjieHoudong_Cost_HongLianZi > 0) then
		-- 红莲子局消耗固定 不允许填
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.tip:Hide()
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:Hide()

		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.numtext:Show()
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.numtext:SetText("#{ETDDS_220406_123}")
	else
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.tip:Show()
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:Show()
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.numtext:Hide()

		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:Enable()
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:SetText("0")
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:SetProperty("DefaultEditBox", "True")
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:SetSelected(0, -1)
	end

	-- 选择提示
	ErtongjieHoudong_UITalbe.choosetip1:Hide()
	ErtongjieHoudong_UITalbe.choosetip2:Hide()
	ErtongjieHoudong_UITalbe.choosetip3:Show()
	local msg = ScriptGlobal_Format("#{ETDDS_220406_115}", ErtongjieHoudong_CountdownTick)
	ErtongjieHoudong_UITalbe.choosetip3:SetText(msg)

	-- 确认 取消按钮
	if (ErtongjieHoudong_AbortFlag > 0) then
		ErtongjieHoudong_UITalbe.confirm:Disable()
		ErtongjieHoudong_UITalbe.cancel:Disable()
	else
		ErtongjieHoudong_UITalbe.confirm:Enable()
		ErtongjieHoudong_UITalbe.cancel:Enable()
	end
end -- end func ErtongjieHoudong_Member_Choosing()

--*************************************************************************************************
-- 队员 等待队长选择中
--*************************************************************************************************
function ErtongjieHoudong_Member_WaitLeaderChoosing()
	ErtongjieHoudong_Leader_ControlsHide()
	ErtongjieHoudong_Member_ControlsShow()

	-- 玩家自己的信息
	local myIndex, myLeaderflag, myDaibiNum1, myDaibiNum2, myDaibiCost, myState, myHead, myName = LuHeXieXiang:GetMySelfInfo()
	if (myIndex < 0) then
		return
	end

	-- 说明
	ErtongjieHoudong_UITalbe.tip:SetText("#{ETDDS_220406_33}")

	-- 代币信息
	local honglianziNum = ScriptGlobal_Format("#{ETDDS_220406_103}", myDaibiNum1)
	ErtongjieHoudong_UITalbe.honglianzitext:SetText(honglianziNum)
	local yulianziNum = ScriptGlobal_Format("#{ETDDS_220406_104}", myDaibiNum2)
	ErtongjieHoudong_UITalbe.yulianzitext:SetText(yulianziNum)

	-- 选择类型提示
	ErtongjieHoudong_UITalbe.memberctrl.choosetext1:SetText("#{ETDDS_220406_37}")
	ErtongjieHoudong_UITalbe.memberctrl.choosetext2:Hide()

	-- 投入代币
	ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.frame:Hide()

	-- 选择提示
	ErtongjieHoudong_UITalbe.choosetip1:Show()
	local msg = ScriptGlobal_Format("#{ETDDS_220406_106}", ErtongjieHoudong_CountdownTick)
	ErtongjieHoudong_UITalbe.choosetip1:SetText(msg)
	ErtongjieHoudong_UITalbe.choosetip2:Hide()
	ErtongjieHoudong_UITalbe.choosetip3:Hide()

	-- 确认、取消按钮
	if (ErtongjieHoudong_AbortFlag > 0) then
		ErtongjieHoudong_UITalbe.confirm:Disable()
		ErtongjieHoudong_UITalbe.cancel:Disable()
	else
		ErtongjieHoudong_UITalbe.confirm:Disable()
		--ErtongjieHoudong_UITalbe.cancel:Disable()
		ErtongjieHoudong_UITalbe.cancel:Enable()
	end
end -- end func ErtongjieHoudong_Member_WaitLeaderChoosing()

--*************************************************************************************************
-- 队员 等待其他队员选择中
--*************************************************************************************************
function ErtongjieHoudong_Member_WaitMemberChoosing()
	ErtongjieHoudong_Leader_ControlsHide()
	ErtongjieHoudong_Member_ControlsShow()

	local gameType = LuHeXieXiang:GetFBLevel()
	-- 玩家自己的信息
	local myIndex, myLeaderflag, myDaibiNum1, myDaibiNum2, myDaibiCost, myState, myHead, myName = LuHeXieXiang:GetMySelfInfo()
	if (myIndex < 0) then
		return
	end

	-- 说明
	ErtongjieHoudong_UITalbe.tip:SetText("#{ETDDS_220406_102}")

	-- 代币信息
	local honglianziNum = ScriptGlobal_Format("#{ETDDS_220406_103}", myDaibiNum1)
	ErtongjieHoudong_UITalbe.honglianzitext:SetText(honglianziNum)
	local yulianziNum = ScriptGlobal_Format("#{ETDDS_220406_104}", myDaibiNum2)
	ErtongjieHoudong_UITalbe.yulianzitext:SetText(yulianziNum)

	-- 选择类型提示
	local typeStr = ""
	if (gameType == ErtongjieHoudong_GameType.honglianzi) then
		typeStr = "#{ETDDS_220406_38}"
	else
		typeStr = "#{ETDDS_220406_39}"
	end
	ErtongjieHoudong_UITalbe.memberctrl.choosetext1:SetText(typeStr)
	ErtongjieHoudong_UITalbe.memberctrl.choosetext2:Hide()

	-- 投入代币
	ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.frame:Show()
	if (gameType == ErtongjieHoudong_GameType.honglianzi) then
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.tip:Hide()
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:Hide()
		
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.numtext:Show()
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.numtext:SetText("#{ETDDS_220406_123}")
	else
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.tip:Show()
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:Show()
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.numtext:Hide()

		if (myDaibiCost > 0) then
			ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:SetText(tostring(myDaibiCost))
		else
			ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:SetText("0")
		end

		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:SetProperty("DefaultEditBox", "False")
		ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:Disable()
	end

	-- 选择提示
	ErtongjieHoudong_UITalbe.choosetip1:Hide()
	ErtongjieHoudong_UITalbe.choosetip2:Show()
	local msg = ScriptGlobal_Format("#{ETDDS_220406_107}", ErtongjieHoudong_CountdownTick)
	ErtongjieHoudong_UITalbe.choosetip2:SetText(msg)
	ErtongjieHoudong_UITalbe.choosetip3:Hide()

	-- 确认、取消按钮
	if (ErtongjieHoudong_AbortFlag > 0) then
		ErtongjieHoudong_UITalbe.confirm:Disable()
		ErtongjieHoudong_UITalbe.cancel:Disable()
	else
		ErtongjieHoudong_UITalbe.confirm:Disable()
		--ErtongjieHoudong_UITalbe.cancel:Disable()
		ErtongjieHoudong_UITalbe.cancel:Enable()
	end
end -- end func ErtongjieHoudong_Member_WaitMemberChoosing()

--*************************************************************************************************
-- 刷新玩家列表
--*************************************************************************************************
function ErtongjieHoudong_UpdateMemberList()
	-- 队员人数
	local curMemberCount = LuHeXieXiang:GetMemberCount()
	-- 当前正在选择的队员
	local curChoose = LuHeXieXiang:GetCurChoose()
	-- 副本类型 红莲子局（低级） 玉莲子局（高级）
	local gameType = LuHeXieXiang:GetFBLevel()
	-- 玩家自己的信息
	local myIndex, myLeaderflag, myDaibiNum1, myDaibiNum2, myDaibiCost, myState, myHead, myName = LuHeXieXiang:GetMySelfInfo()
	if (myIndex < 0) then
		return
	end

	-- 需要消耗的代币总数
	local totalDaibi = 0

	ErtongjieHoudong_UITalbe.leaderflag:Hide()
	-- 队员列表
	for i = 1, 6, 1 do
		local index, leaderflag, daibiCost, state, head, name = LuHeXieXiang:GetMemberInfo(i-1)
		if (index >= 0) then
			ErtongjieHoudong_UITalbe.playerinfo[i].frame:Show()
			-- 头像
			ErtongjieHoudong_UITalbe.playerinfo[i].head:SetProperty("Image", head)
			-- 名字
			ErtongjieHoudong_UITalbe.playerinfo[i].name:SetText("#L" .. name)
			-- 代币
			local msg = ScriptGlobal_Format("#{ETDDS_220406_34}", daibiCost)
			ErtongjieHoudong_UITalbe.playerinfo[i].daibi:SetText(msg)
			-- 状态
			if (state == ErtongjieHoudong_State.wait) then
				if (index == curChoose) then
					ErtongjieHoudong_UITalbe.playerinfo[i].state:SetProperty("Image", ErtongjieHoudong_StateImge[ErtongjieHoudong_State.input])
				else
					ErtongjieHoudong_UITalbe.playerinfo[i].state:SetProperty("Image", ErtongjieHoudong_StateImge[state])
				end
			else
				ErtongjieHoudong_UITalbe.playerinfo[i].state:SetProperty("Image", ErtongjieHoudong_StateImge[state])
			end

			-- 队长标记
			if (leaderflag > 0) then
				ErtongjieHoudong_UITalbe.leaderflag:Show()
			end

			totalDaibi = totalDaibi + daibiCost
		else
			ErtongjieHoudong_UITalbe.playerinfo[i].frame:Hide()
		end
	end -- end for

	-- 选择信息显示
	if (myIndex == 0 or (myLeaderflag ~= nil and myLeaderflag > 0)) then
		-- 自己是队长或单人玩家
		if (myIndex == curChoose) then
			-- 队长自己选择中
			ErtongjieHoudong_Leader_Choosing()
		else
			-- 队长等待
			ErtongjieHoudong_Leader_Wait()
		end
	else
		-- 自己不是队长并且不是单人玩家
		if (curChoose == 0) then
			-- 等待队长选择中
			ErtongjieHoudong_Member_WaitLeaderChoosing()
		else
			if (myIndex == curChoose) then
				-- 自己选择中
				ErtongjieHoudong_Member_Choosing()
			else
				-- 等待其他队员选择中
				ErtongjieHoudong_Member_WaitMemberChoosing()
			end
		end
	end
end -- end func ErtongjieHoudong_UpdateMemberList()

--*************************************************************************************************
-- 玩家确认
--*************************************************************************************************
function ErtongjieHoudong_MemberConfirmed(nIndex, nType, nCost, nCurChoose)
	-- local memberIndex = tonumber(nIndex)
	-- local failedType = tonumber(nType)
	-- local memberCost = tonumber(nCost)
	-- local curChoose = tonumber(nCurChoose)
end -- end func ErtongjieHoudong_MemberConfirmed()

--*************************************************************************************************
-- 确认失败 可能是代币不够吧
--*************************************************************************************************
function ErtongjieHoudong_ConfirmFailed(nIndex, nType)
	-- local memberIndex = tonumber(nIndex)
	-- local failedType = tonumber(nType)

	ErtongjieHoudong_ConfirmFlag = 0

	-- 失败了 把确认按钮打开
	ErtongjieHoudong_UITalbe.confirm:Enable()
	ErtongjieHoudong_UITalbe.cancel:Enable()
end -- end func ErtongjieHoudong_ConfirmFailed()



--*************************************************************************************************
-- 确定按钮事件
--*************************************************************************************************
function ErtongjieHoudong_Clicked_Choose()
	if (ErtongjieHoudong_ConfirmFlag > 0) then
		-- 避免重复点击确认
		PushDebugMessage("#{FXDL_1210516_37}")
		return
	end

	-- 队长 队员都用同一套确定逻辑吧
	local curType = -1
	local cost = 0
	-- 玩家自己的信息
	local myIndex, myLeaderflag, myDaibiNum1, myDaibiNum2, myDaibiCost, myState, myHead, myName = LuHeXieXiang:GetMySelfInfo()
	if (myIndex < 0) then
		PushDebugMessage("#{CFKYH_120723_114}")
		return
	end

	if (myIndex == 0 or (myLeaderflag ~= nil and myLeaderflag > 0)) then
		-- 队长
		curType = ErtongjieHoudong_CurChooseType
		if (curType < 0) then
			curType = ErtongjieHoudong_GameType.honglianzi
		end

		local costText = ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:GetText()
		if (costText ~= nil and costText ~= "") then
			cost = tonumber(costText)
			if (cost < 0) then
				cost = 0
				ErtongjieHoudong_UITalbe.leaderctrl.daibiinfo.num:SetText("0")
			end
		end
	else
		-- 队员
		local costText = ErtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:GetText()
		if (costText ~= nil and costText ~= "") then
			cost = tonumber(costText)
			if (cost < 0) then
				cost = 0
				rtongjieHoudong_UITalbe.memberctrl.daibiinfo.num:SetText("0")
			end
		end
	end

	if (ErtongjieHoudong_YuLianZiOpenFlag <= 0) then
		-- 玉莲子玩法不开放时强制红莲子玩法
		curType = ErtongjieHoudong_GameType.honglianzi
	end

	ErtongjieHoudong_ConfirmFlag = 1

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnConfirm")
		Set_XSCRIPT_ScriptID(ErtongjieHoudong_SvrScriptId)
		Set_XSCRIPT_Parameter(0, ErtongjieHoudong_CareObjSvrId)
		Set_XSCRIPT_Parameter(1, curType)
		Set_XSCRIPT_Parameter(2, cost)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end -- end func ErtongjieHoudong_Clicked_Choose()

--*************************************************************************************************
-- 取消按钮事件
--*************************************************************************************************
function ErtongjieHoudong_Clicked_Waive()
	if (ErtongjieHoudong_AbortFlag > 0) then
		-- 避免重复点击取消
		PushDebugMessage("#{FXDL_1210516_37}")
		return
	end

	ErtongjieHoudong_UITalbe.confirm:Disable()
	ErtongjieHoudong_UITalbe.cancel:Disable()
	ErtongjieHoudong_AbortFlag = 1

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnAbort")
		Set_XSCRIPT_ScriptID(ErtongjieHoudong_SvrScriptId)
		Set_XSCRIPT_Parameter(0, ErtongjieHoudong_CareObjSvrId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	-- 立即关闭UI
	ErtongjieHoudong_Hide()
end -- end func ErtongjieHoudong_Clicked_Waive()



--*************************************************************************************************
-- 开始游戏
--*************************************************************************************************
function ErtongjieHoudong_OnStartGame()
	ErtongjieHoudong_HideFlag = 1
	-- 延时关闭UI
	if (ErtongjieHoudong_TimerID < 0) then
		ErtongjieHoudong_TimerID = SetTimer("ErtongjieHoudong", "ErtongjieHoudong_Hide()", 500)
	end

	if (ErtongjieHoudong_CountdownTimerID >= 0) then
		KillTimer(ErtongjieHoudong_CountdownTimerID)
		ErtongjieHoudong_CountdownTimerID = -1
	end
	ErtongjieHoudong_CountdownTick = 30

	-- 开始倒计时UI
	PushEvent("UI_COMMAND", 2022062001)
end -- end func ErtongjieHoudong_OnStartGame()

--*************************************************************************************************
-- 游戏开启失败 可能是代币不够或者消耗达到上限
--*************************************************************************************************
function ErtongjieHoudong_OnStartFailed(nType)
	local failedType = tonumber(nType)

	ErtongjieHoudong_HideFlag = 1
	-- 立即关闭UI
	ErtongjieHoudong_Hide()
end -- end func ErtongjieHoudong_OnStartFailed()

--*************************************************************************************************
-- 玩家取消
--*************************************************************************************************
function ErtongjieHoudong_OnPlayerAbort()
	ErtongjieHoudong_HideFlag = 1
	ErtongjieHoudong_AbortFlag = 1

	if (ErtongjieHoudong_TimerID < 0) then
		ErtongjieHoudong_TimerID = SetTimer("ErtongjieHoudong", "ErtongjieHoudong_Hide()", 3000)
	end

	if (ErtongjieHoudong_CountdownTimerID >= 0) then
		KillTimer(ErtongjieHoudong_CountdownTimerID)
		ErtongjieHoudong_CountdownTimerID = -1
	end
	ErtongjieHoudong_CountdownTick = 30
end -- end func ErtongjieHoudong_OnPlayerAbort()

--*************************************************************************************************
-- 队员离队
--*************************************************************************************************
function ErtongjieHoudong_OnTeamMemberLeave()
	ErtongjieHoudong_HideFlag = 1
	ErtongjieHoudong_Hide()
end -- end func ErtongjieHoudong_OnTeamMemberLeave()



--*************************************************************************************************
-- NPC关注相关
--*************************************************************************************************
-- 开启NPC关注
function ErtongjieHoudong_BeginCareObject(objSvrId, objId)
	ErtongjieHoudong_CareObjId = tonumber(objId)
	ErtongjieHoudong_CareObjSvrId = tonumber(objSvrId)
	if (ErtongjieHoudong_CareObjId >= 0) then
		this:CareObject(ErtongjieHoudong_CareObjId, 1, "ErtongjieHoudong")
	end
end -- end func ErtongjieHoudong_BeginCareObject()

-- 取消NPC关注
function ErtongjieHoudong_StopCareObject(objId)
	if (tonumber(objId) >= 0) then
		this:CareObject(objId, 0, "ErtongjieHoudong")
		ErtongjieHoudong_CareObjId = -1
		ErtongjieHoudong_CareObjSvrId = -1
	end
end -- end func ErtongjieHoudong_StopCareObject()