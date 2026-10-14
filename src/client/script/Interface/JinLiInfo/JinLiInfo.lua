-- JinLiInfo 2020 巅峰赛锦鲤细节展示界面 2020-8-10 lishilong
-- 主界面的协同界面，同主界面一起初始化所有参数
-- !!!reloadscript =JinLiInfo
--
local MAX_OBJ_DISTANCE 	= 3.0
local g_objCared 		= -1
local g_npcObjId 		= -1
local g_JinLiInfo_Frame_UnifiedPosition
local bCaredObj 		= 0
local bCaredMoney 		= 0

-- 当前服务器时间天数
local g_nCurDayServer   = 0
-- 活动开启时间 废弃 不用了
-- local g_nDayStart   	= 0
-- 今天是否用过月饼
local g_bIsUseYueBing		= 0
-- 是否已经过了帮会锦鲤传递时间
local g_bFinishBangHuiLucky	= 0

-- 本界面特有参数 显示第几个蒙版
local g_nShowMengBanIndex 	= 0
-- 本界面特有参数 蒙版控件
local g_controlMengBan		= {}

-- 锦鲤数量
local g_nMaxJinLiNum		= 7

-- 活动时间
-- 第一阶段 抽取锦鲤
local g_TimeStart					= 20210924		-- 20201116		-- 20190905
local g_TimeStep1End				= 20210930		-- 20201122		-- 20190911
-- 第二阶段 传递锦鲤
local g_TimeStep2Start				= 20211001		-- 20201123		-- 20190912
local g_TimeEnd						= 20211007		-- 20201129		-- 20190918
-- 领奖阶段是一个活动时间的延续。
local g_RewardTimeStart				= 20211008		-- 20201130		-- 20190919
local g_RewardTimeEnd				= 20211010		-- 20201202		-- 20190925
-- 帮会锦鲤开启时间
local g_TimeBangHuiDay				= 20211001		-- 20201123		-- 20190913

-- 为了避免跨月计算 增加活动第x天的数组
local g_tabTimeStep1				=
{
	[1] = 20210924,			-- [1] = 20201116,			-- [1] = 20190905,
	[2] = 20210925,			-- [2] = 20201117,			-- [2] = 20190906,
	[3] = 20210926,			-- [3] = 20201118,			-- [3] = 20190907,
	[4] = 20210927,			-- [4] = 20201119,			-- [4] = 20190908,
	[5] = 20210928,			-- [5] = 20201120,			-- [5] = 20190909,
	[6] = 20210929,			-- [6] = 20201121,			-- [6] = 20190910,
	[7] = 20210930,			-- [7] = 20201122,			-- [7] = 20190911,
}

local g_tabTimeStep2				=
{
	[1] = 20211001,			-- [1] = 20201123,			-- [1] = 20190912,
	[2] = 20211002,			-- [2] = 20201124,			-- [2] = 20190913,
	[3] = 20211003,			-- [3] = 20201125,			-- [3] = 20190914,
	[4] = 20211004,			-- [4] = 20201126,			-- [4] = 20190915,
	[5] = 20211005,			-- [5] = 20201127,			-- [5] = 20190916,
	[6] = 20211006,			-- [6] = 20201128,			-- [6] = 20190917,
	[7] = 20211007,			-- [7] = 20201129,			-- [7] = 20190918,
}

-------------- 控件
-- 阶段2 的全服幸运儿名字控件
local g_controlStep2Lucky2Name	= {}
-- 阶段2 帮会幸运儿信息1 控件
local g_controlStep2Lucky3T1	= {}
-- 阶段2 帮会幸运儿信息2 控件
local g_controlStep2Lucky3T2	= {}
-- 阶段2 帮会幸运儿信息3 控件
local g_controlStep2Lucky3T3	= {}
-- 阶段2 好友幸运儿信息1 控件
local g_controlStep2Lucky4T1	= {}
-- 阶段2 好友幸运儿信息2 控件
local g_controlStep2Lucky4T2	= {}

--=========================================================
-- PreLoad
--=========================================================
function JinLiInfo_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	if 1 == bCaredMoney then
		this:RegisterEvent("MONEY_CHANGE_EX", false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	end
	this:RegisterEvent("ADJEST_UI_POS")
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
    
    this:RegisterEvent("OPEN_JINLI_UI")
    this:RegisterEvent("REFRESH_JINLI_UI")
    this:RegisterEvent("CLOSE_JINLI_UI")
end

--=========================================================
-- OnLoad
--=========================================================
function JinLiInfo_OnLoad()
	g_JinLiInfo_Frame_UnifiedPosition = JinLiInfo_MainFrame:GetProperty("UnifiedPosition")

	-- 本界面特有的蒙版控件
	g_controlMengBan[1]			= JinLiInfo_About_Reward
	g_controlMengBan[2]			= JinLiInfo_FullService_Reward
	g_controlMengBan[3]			= JinLiInfo_BangHui_Reward
	g_controlMengBan[4]			= JinLiInfo_Friend_Reward

	-- 展示界面只用下面的控件

	-- 阶段2 的全服幸运儿名字控件
	g_controlStep2Lucky2Name[1]	= JinLiInfo_FullService_Text3
	g_controlStep2Lucky2Name[2]	= JinLiInfo_FullService_Text4
	g_controlStep2Lucky2Name[3]	= JinLiInfo_FullService_Text5
	g_controlStep2Lucky2Name[4]	= JinLiInfo_FullService_Text6
	g_controlStep2Lucky2Name[5]	= JinLiInfo_FullService_Text7
	g_controlStep2Lucky2Name[6]	= JinLiInfo_FullService_Text8
	g_controlStep2Lucky2Name[7]	= JinLiInfo_FullService_Text9

	-- 阶段2 帮会幸运儿信息1 控件
	g_controlStep2Lucky3T1[1]	= JinLiInfo_BangHui_Text1
	g_controlStep2Lucky3T1[2]	= JinLiInfo_BangHui_Text2
	g_controlStep2Lucky3T1[3]	= JinLiInfo_BangHui_Text3
	g_controlStep2Lucky3T1[4]	= JinLiInfo_BangHui_Text4
	g_controlStep2Lucky3T1[5]	= JinLiInfo_BangHui_Text5
	g_controlStep2Lucky3T1[6]	= JinLiInfo_BangHui_Text6
	g_controlStep2Lucky3T1[7]	= JinLiInfo_BangHui_Text7

	-- 阶段2 帮会幸运儿信息2 控件
	g_controlStep2Lucky3T2[1]	= JinLiInfo_BangHui_Text1_1
	g_controlStep2Lucky3T2[2]	= JinLiInfo_BangHui_Text2_1
	g_controlStep2Lucky3T2[3]	= JinLiInfo_BangHui_Text3_1
	g_controlStep2Lucky3T2[4]	= JinLiInfo_BangHui_Text4_1
	g_controlStep2Lucky3T2[5]	= JinLiInfo_BangHui_Text5_1
	g_controlStep2Lucky3T2[6]	= JinLiInfo_BangHui_Text6_1
	g_controlStep2Lucky3T2[7]	= JinLiInfo_BangHui_Text7_1

	-- 阶段2 帮会幸运儿信息3 控件
	g_controlStep2Lucky3T3[1]	= JinLiInfo_BangHui_Text1_Null
	g_controlStep2Lucky3T3[2]	= JinLiInfo_BangHui_Text2_Null
	g_controlStep2Lucky3T3[3]	= JinLiInfo_BangHui_Text3_Null
	g_controlStep2Lucky3T3[4]	= JinLiInfo_BangHui_Text4_Null
	g_controlStep2Lucky3T3[5]	= JinLiInfo_BangHui_Text5_Null
	g_controlStep2Lucky3T3[6]	= JinLiInfo_BangHui_Text6_Null
	g_controlStep2Lucky3T3[7]	= JinLiInfo_BangHui_Text7_Null

	-- 阶段2 好友幸运儿信息1 控件
	g_controlStep2Lucky4T1[1]	= JinLiInfo_Friend_Text1
	g_controlStep2Lucky4T1[2]	= JinLiInfo_Friend_Text2
	g_controlStep2Lucky4T1[3]	= JinLiInfo_Friend_Text3
	g_controlStep2Lucky4T1[4]	= JinLiInfo_Friend_Text4
	g_controlStep2Lucky4T1[5]	= JinLiInfo_Friend_Text5
	g_controlStep2Lucky4T1[6]	= JinLiInfo_Friend_Text6
	g_controlStep2Lucky4T1[7]	= JinLiInfo_Friend_Text7

	-- 阶段2 好友幸运儿信息2 控件
	g_controlStep2Lucky4T2[1]	= JinLiInfo_Friend_Text1_1
	g_controlStep2Lucky4T2[2]	= JinLiInfo_Friend_Text2_1
	g_controlStep2Lucky4T2[3]	= JinLiInfo_Friend_Text3_1
	g_controlStep2Lucky4T2[4]	= JinLiInfo_Friend_Text4_1
	g_controlStep2Lucky4T2[5]	= JinLiInfo_Friend_Text5_1
	g_controlStep2Lucky4T2[6]	= JinLiInfo_Friend_Text6_1
	g_controlStep2Lucky4T2[7]	= JinLiInfo_Friend_Text7_1	
end

--=========================================================
-- OnEvent
--=========================================================
function JinLiInfo_OnEvent(event)
    if event == "OPEN_JINLI_UI" or event == "REFRESH_JINLI_UI" then
		-- 0 关闭，1打开， 2刷新
        local nOpType 	= 1
        if event == "REFRESH_JINLI_UI" then
            nOpType = 2
        end

		local objid = tonumber(arg0)
		
		if 1 == bCaredObj then
			if objid == nil or objid < 0 then
				if this:IsVisible() then
					JinLiInfo_OnClose()
				end
			end
		end
		
		if 1 == nOpType then
			-- 打开界面
			-- 关注npc
			if 1 == bCaredObj then
				g_npcObjId = objid
				g_objCared = DataPool : GetNPCIDByServerID(tonumber(objid))
				BeginCareObject_JinLiInfo()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	JinLiInfo_OnClose()
			-- end
			-- JinLiInfo_Reset()
			-- JinLiInfo_Frame_On_ResetPos()
			-- this:Show()
			JinLiInfo_ParamInit()
			JinLiInfo_MoneyUpdate()
			JinLiInfo_Update(1)
			
		elseif 2 == nOpType then
			-- 刷新界面
			if this:IsVisible() then
				JinLiInfo_ParamInit()
				JinLiInfo_Update(0)
			end
		end
    
    elseif ( event == "CLOSE_JINLI_UI" ) and this:IsVisible() then
		JinLiInfo_OnClose()

	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 79002006 ) then
		
		if this:IsVisible() then
			JinLiInfo_OnClose()
		end

		g_nShowMengBanIndex = tonumber(arg1)
		-- PushDebugMessage("79002006UI_COMMAND"..g_nShowMengBanIndex)

		JinLiInfo_Frame_On_ResetPos()
		this:Show()
		JinLiInfo_Update(0)
	
	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			JinLiInfo_OnClose()
		end	
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		JinLiInfo_OnClose()
	
	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
	-- elseif event == "MONEYJZ_CHANGE_EX" then
		JinLiInfo_MoneyUpdate()
	
	elseif (event == "ADJEST_UI_POS" ) then
		JinLiInfo_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JinLiInfo_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function JinLiInfo_ParamInit()
	g_nCurDayServer 		= tonumber(arg1)
	-- g_nDayStart 			= tonumber(arg2)
	g_bIsUseYueBing 		= tonumber(arg3)
	g_bFinishBangHuiLucky 	= tonumber(arg4)

	-- PushDebugMessage("JinLiInfo_ParamInit".."g_nCurDayServer"..g_nCurDayServer.."g_nDayStart"..g_nDayStart.."g_bIsUseYueBing"..g_bIsUseYueBing.."g_bFinishBangHuiLucky"..g_bFinishBangHuiLucky )
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =JinLiInfo
function JinLiInfo_Update(bOpen)
	-- PushDebugMessage("g_nShowMengBanIndex"..g_nShowMengBanIndex)
	
	-- if 0 == JinLiInfo_GetHuoDongStep() then
	-- 	JinLiInfo_OnClose()
	-- end

	-- 处理显示的蒙版
	for i = 1, table.getn(g_controlMengBan) do
		if i == g_nShowMengBanIndex then
			g_controlMengBan[i]  : Show()
		else
			g_controlMengBan[i]  : Hide()
		end
	end

	-- 填充所有信息

	-- local nDayIndex = g_nCurDayServer - g_nMaxJinLiNum - g_nDayStart + 1
	-- 返回0 表示不处于第二阶段
	local nDayIndex = JinLiInfo_GetDayIndex(2, g_nCurDayServer)
	local nHuoDongStep = JinLiInfo_GetHuoDongStep()

	-- PushDebugMessage("nDayIndex"..nDayIndex.."g_nCurDayServer"..g_nCurDayServer)

	for i = 1, g_nMaxJinLiNum do

		local bRet, bSet, nSelfGUIDH, nSelfGUIDL, nValue4, strPlayerName, strGuildName = DataPool:Lua_GetJinLiInfoByIndex(i)

		local bRet2, bSet2, nSelfGUIDH2, nSelfGUIDL2, nValue42, strPlayerName2, strGuildName2 = DataPool:Lua_GetJinLiInfoByIndex(i + g_nMaxJinLiNum)

		local bRet3, bSet3, nSelfGUIDH3, nSelfGUIDL3, nValue43, strPlayerName3, strGuildName3 = DataPool:Lua_GetJinLiInfoByIndex(i + g_nMaxJinLiNum * 2)

		local bRet4, bSet4, nSelfGUIDH4, nSelfGUIDL4, nValue44, strPlayerName4, strGuildName4 = DataPool:Lua_GetJinLiInfoByIndex(i + g_nMaxJinLiNum * 3)

		-- 底部中奖名单 全服
		if 1 == nHuoDongStep then
			-- 一阶段全部未开奖
			g_controlStep2Lucky2Name[i] : SetText("#{ZQJL_190725_195}")	
		elseif nil ~= bRet2 and 1 == bRet2 and 1 == bSet2 then
			-- 确定开奖了
			g_controlStep2Lucky2Name[i] : SetText(ScriptGlobal_Format("#{ZQJL_190725_218}", strPlayerName2))
		elseif nDayIndex > i or 0 == nDayIndex then 
			-- 开奖时间过了，但是锦鲤没来
			g_controlStep2Lucky2Name[i] : SetText("#{ZQJL_190725_196}")
		else
			-- 还没开
			g_controlStep2Lucky2Name[i] : SetText("#{ZQJL_190725_195}")	
		end
	
		-- 底部中奖名单 帮会
		g_controlStep2Lucky3T1[i] : Hide()
		g_controlStep2Lucky3T2[i] : Hide()
		g_controlStep2Lucky3T3[i] : Hide()
		if nil ~= bRet3 and 1 == bRet3 and 1 == bSet3 then
			g_controlStep2Lucky3T1[i] : SetText(ScriptGlobal_Format("#{ZQJL_190725_203}", strGuildName3))
			-- g_controlStep2Lucky3T1[i] : SetProperty("HorzFormatting", "WordWrapLeftAligned")
			g_controlStep2Lucky3T2[i] : SetText(ScriptGlobal_Format("#{ZQJL_190725_218}", strPlayerName3))

			g_controlStep2Lucky3T1[i] : Show()
			g_controlStep2Lucky3T2[i] : Show()
		elseif 1 == g_bFinishBangHuiLucky then 
			-- 开奖时间过了，但是锦鲤没来
			g_controlStep2Lucky3T3[i] : SetText("#{ZQJL_190725_196}")
			-- g_controlStep2Lucky3T3[i] : SetProperty("HorzFormatting", "WordWrapCentred")
			g_controlStep2Lucky3T3[i] : Show()
		else
			g_controlStep2Lucky3T3[i] : SetText("#{ZQJL_190725_195}")		
			-- g_controlStep2Lucky3T3[i] : SetProperty("HorzFormatting", "WordWrapCentred")	
			g_controlStep2Lucky3T3[i] : Show()
		end

		-- 底部中奖名单 好友
		if nil ~= bRet and 1 == bRet and 1 == bSet then
			g_controlStep2Lucky4T1[i] : SetText(ScriptGlobal_Format("#{ZQJL_190725_218}", strPlayerName))
		else
			g_controlStep2Lucky4T1[i] : SetText("#{ZQJL_190725_39}")		
		end
		if nil ~= bRet4 and 1 == bRet4 and 1 == bSet4 then
			g_controlStep2Lucky4T2[i] : SetText(ScriptGlobal_Format("#{ZQJL_190725_218}", strPlayerName4))
		else
			g_controlStep2Lucky4T2[i] : SetText("#{ZQJL_190725_204}")		
		end
		
	end

	-- 今日抽奖设置 全服
	JinLiInfo_FullService_Text1 : Hide()
	JinLiInfo_FullService_Text1_1 : Hide()
	JinLiInfo_FullService_TextFin : Hide()
	JinLiInfo_FullService_Text0 : Hide()

	if 3 == nHuoDongStep then
		JinLiInfo_FullService_TextFin : Show()
	elseif 1 == nHuoDongStep then
		JinLiInfo_FullService_Text0 : Show()
	else
		local bRetToday, bSetToday, nSelfGUIDHToday, nSelfGUIDLToday, nValue4Today, strPlayerNameToday, strGuildNameToday = DataPool:Lua_GetJinLiInfoByIndex(nDayIndex + g_nMaxJinLiNum)
		if nil ~= bRetToday and 1 == bRetToday and 1 == bSetToday then
			JinLiInfo_FullService_Text1_1 : SetText(ScriptGlobal_Format("#{ZQJL_190725_218}", strPlayerNameToday))
			-- PushDebugMessage("11111nDayIndex"..nDayIndex)
		else
			JinLiInfo_FullService_Text1_1 : SetText("#{ZQJL_190725_195}")
			-- PushDebugMessage("22222nDayIndex"..nDayIndex)
		end

		JinLiInfo_FullService_Text1 : Show()
		JinLiInfo_FullService_Text1_1 : Show()
	end

end

--=========================================================
-- 获取活动的阶段 1 一阶段；2 二阶段；0 活动关闭
--=========================================================
function JinLiInfo_GetHuoDongStep()

	if nil == g_nCurDayServer or g_nCurDayServer <= 0 then
		return 0 
	end

	if g_nCurDayServer >= g_TimeStart and g_nCurDayServer <= g_TimeStep1End then
		return 1
	end

	if g_nCurDayServer >= g_TimeStep2Start and g_nCurDayServer <= g_TimeEnd then
		return 2
	end

	if g_nCurDayServer >= g_RewardTimeStart and g_nCurDayServer <= g_RewardTimeEnd then
		return 3
	end

	return 0 
end

--**********************************
-- 辅助函数 获取当前是活动阶段x的第几天 返回0 非法
--**********************************
function JinLiInfo_GetDayIndex(nStep, nDay)
	if nStep < 1 or nStep > 2 then
		return 0
	end

	local tableDay = g_tabTimeStep1
	if 2 == nStep then
		tableDay = g_tabTimeStep2
	end

	for i = 1, table.getn(tableDay) do
		if nDay == tableDay[i] then
			return i
		end
	end

	return 0
end

--=========================================================
--帮助按钮
--=========================================================
function JinLiInfo_HelpClick(nParam)
	-- 借用一下别人的通道
	-- 一阶段主界面的问号
	if 1 == nParam then 
		PushEvent("CCSHOP_HELP", 71)
	end

	-- 二阶段主界面的问号
	if 2 == nParam then 
		PushEvent("CCSHOP_HELP", 72)
	end 

	-- 奖励的问号
	if 3 == nParam then 
		PushEvent("CCSHOP_HELP", 73)
	end 
	if 4 == nParam then 
		PushEvent("CCSHOP_HELP", 74)
	end 
	if 5 == nParam then 
		PushEvent("CCSHOP_HELP", 75)
	end 
end

--=========================================================
-- 重置界面
--=========================================================
function JinLiInfo_Reset()
	g_nShowMengBanIndex = 0
end

--=========================================================
-- 界面确认按钮
--=========================================================
function JinLiInfo_ConfirmClick()

end

--=========================================================
-- 关闭界面
--=========================================================
function JinLiInfo_OnClose()	
	this:Hide()
	StopCareObject_JinLiInfo()
	-- 重置
	JinLiInfo_Reset()
end

--=========================================================
-- 界面隐藏
--=========================================================
function JinLiInfo_OnHiden()
	StopCareObject_JinLiInfo()
	-- 重置
	JinLiInfo_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_JinLiInfo()
	-- 关心
	this:CareObject(g_objCared, 1, "JinLiInfo")
end

function StopCareObject_JinLiInfo()
	-- 取消关心
	if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "JinLiInfo")
	end
	g_npcObjId = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function JinLiInfo_MoneyUpdate()
end

--=========================================================
-- 界面位置
--=========================================================
function JinLiInfo_Frame_On_ResetPos()
	JinLiInfo_MainFrame:SetProperty("UnifiedPosition", g_JinLiInfo_Frame_UnifiedPosition)
end