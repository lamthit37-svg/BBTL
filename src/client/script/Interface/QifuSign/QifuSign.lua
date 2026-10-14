-- QifuSign 祈愿签到 新活跃 2021-7-13 lishilong
-- !!!reloadscript =QifuSign

local g_QifuSign_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 0
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= 0

local g_nUICommandID		= 79007001

local g_nLastWeek 				= -1
local g_nActNumWeek 			= -1
local g_bIsGetedFlag			= -1
local g_nCurWeek 				= -1
local g_nCurDay					= -1
local g_nActNumDay				= -1
local g_nNumOfGiveWine 			= -1
local g_nBufIndex				= -1
local g_bGetedBuf 				= -1
local g_bShowHotPoin			= -1
local g_nWeekAnimateShowIndex	= -1
local g_nWeekRewardDetailInfo2	= -1
local g_nWeekRewardDetailInfo3	= -1
local g_nRefreshBufNum			= -1

local g_controlWeekRewardButton1	= {}
-- local g_controlWeekRewardName		= {}
-- local g_controlWeekRewardNum		= {}
local g_controlWeekRewardDisable1	= {}
local g_controlWeekRewardAnimate1	= {}
local g_controlWeekRewardButton2	= {}
local g_controlWeekRewardDisable2	= {}
local g_controlWeekRewardAnimate2	= {}

local g_controlAllBufPic			= {}
local g_controlAllBufName			= {}
local g_controlAllBufAnimate		= {}

local g_controlNeedHideWhenBufShow	= {}

-- 祈愿奖励
local g_nBaseRewardID				= 38005366
local g_nAdvancedRewardID			= 38005367
-- local g_strBaseRewardPic			= "set:Buff31 image:Red_1"
-- local g_strAdvancedRewardPic		= "set:Buff31 image:Red_2"

local g_strPicTodayItemCommon		= "set:QiFuSign image:QiFuSign01"
local g_strPicTodayItemAdvance		= "set:QiFuSign image:QiFuSign02"

-- 二次祈愿概率 基础值 这个改了客户端也一起改一下，用来区分一个显示逻辑的字典
local g_nSecondQiYuanBaseRate		= 0
-- 赠酒最大次数
local g_nMaxNumOfGiveWine			= 5

-- 道具	数量	概率
-- 离火	1	20%
-- 	3	20%
-- 	5	10%
-- 精金石	1	20%
-- 	2	10%
-- 	3	5%
-- 经验回溯令	1	5%
-- 内息回溯令	1	5%
-- 流火镶金令	1	5%

-- 周奖励 随机表
local g_tabWeekRewardItemInfo			=
{
	[1] = {nItemID = 20700063, nItemNum = 1, nWeight = 200, bAct = 1, nNeedBagSpace = 0, nNeedMatSpace = 1, nLayNum = 200, },
	[2] = {nItemID = 20700063, nItemNum = 3, nWeight = 200, bAct = 1, nNeedBagSpace = 0, nNeedMatSpace = 1, nLayNum = 200, },
	[3] = {nItemID = 20700063, nItemNum = 5, nWeight = 100, bAct = 1, nNeedBagSpace = 0, nNeedMatSpace = 1, nLayNum = 200, },
	[4] = {nItemID = 20700055, nItemNum = 1, nWeight = 200, bAct = 1, nNeedBagSpace = 0, nNeedMatSpace = 1, nLayNum = 200, },
	[5] = {nItemID = 20700055, nItemNum = 2, nWeight = 100, bAct = 1, nNeedBagSpace = 0, nNeedMatSpace = 1, nLayNum = 200, },
	[6] = {nItemID = 20700055, nItemNum = 3, nWeight = 50, 	bAct = 1, nNeedBagSpace = 0, nNeedMatSpace = 1, nLayNum = 200, },
	[7] = {nItemID = 38005097, nItemNum = 1, nWeight = 50, 	bAct = 1, nNeedBagSpace = 1, nNeedMatSpace = 0, nLayNum = 1, },
	[8] = {nItemID = 38005096, nItemNum = 1, nWeight = 50, 	bAct = 1, nNeedBagSpace = 1, nNeedMatSpace = 0, nLayNum = 1, },
	[9] = {nItemID = 38005108, nItemNum = 1, nWeight = 50, 	bAct = 1, nNeedBagSpace = 1, nNeedMatSpace = 0, nLayNum = 1, },
}

local g_nBindYuanBaoShowItemID 	= 39920961
local g_nBindYuanBaoNumPerAct 	= 20

-- 福源buf
local g_tabBufInfo					=
{
	[1] 	= {nBufID = 50543, nBufRate = 1, strBufName = "#{MRQD_210708_106}",	strBufTips = "#{MRQD_210708_96}",	strBufPic = "set:Buff31 image:Buff31_3", },
	[2] 	= {nBufID = 50544, nBufRate = 1, strBufName = "#{MRQD_210708_107}",	strBufTips = "#{MRQD_210708_97}",	strBufPic = "set:Buff31 image:Buff31_5", },
	[3] 	= {nBufID = 50545, nBufRate = 1, strBufName = "#{MRQD_210708_108}",	strBufTips = "#{MRQD_210708_98}",	strBufPic = "set:Buff31 image:Buff31_2", },
	[4] 	= {nBufID = 50546, nBufRate = 1, strBufName = "#{MRQD_210708_89}",	strBufTips = "#{MRQD_210708_99}",	strBufPic = "set:Buff31 image:Buff31_4", },
	[5] 	= {nBufID = 50547, nBufRate = 1, strBufName = "#{MRQD_210708_90}",	strBufTips = "#{MRQD_210708_100}",	strBufPic = "set:Buff31 image:Buff31_8", },
	[6] 	= {nBufID = 50548, nBufRate = 1, strBufName = "#{MRQD_210708_91}",	strBufTips = "#{MRQD_210708_101}",	strBufPic = "set:Buff31 image:Buff31_7", },
	[7] 	= {nBufID = 50549, nBufRate = 1, strBufName = "#{MRQD_210708_92}",	strBufTips = "#{MRQD_210708_102}",	strBufPic = "set:Buff31 image:Buff31_6", },
	[8] 	= {nBufID = 50550, nBufRate = 1, strBufName = "#{MRQD_210708_93}",	strBufTips = "#{MRQD_210708_103}",	strBufPic = "set:Buff31 image:Buff31_9", },
	-- [9] 	= {nBufID = 50551, nBufRate = 1, strBufName = "#{MRQD_210708_94}",	strBufTips = "#{MRQD_210708_104}",	strBufPic = "set:Buff31 image:Red_9", },
	-- [10] 	= {nBufID = 50552, nBufRate = 1, strBufName = "#{MRQD_210708_95}",	strBufTips = "#{MRQD_210708_105}",	strBufPic = "set:Buff31 image:Red_0", },
}

-- -- 祈福次数的图片 0-5 用的时候+1
-- local g_tabQiFuNumPic				=
-- {
-- 	[1] = "set:QiFuSign image:QifuSend0", 
-- 	[2] = "set:QiFuSign image:QifuSend1", 
-- 	[3] = "set:QiFuSign image:QifuSend2", 
-- 	[4] = "set:QiFuSign image:QifuSend3", 
-- 	[5] = "set:QiFuSign image:QifuSend4", 
-- 	[6] = "set:QiFuSign image:QifuSend5", 
-- }

-- 消耗单位G
local g_tabRefreshBufInfo			=
{
	[1] 	= {nCostMoney = 0, },
	[2] 	= {nCostMoney = 5, },
	[3] 	= {nCostMoney = 10, },
	[4] 	= {nCostMoney = 30, },
	[5] 	= {nCostMoney = 50, },
	[6] 	= {nCostMoney = 50, },
}

--=========================================================
-- PreLoad
--=========================================================
function QifuSign_PreLoad()
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

	this:RegisterEvent("QIYUAN_GIVE_WINE_SELECTED")
end

--=========================================================
-- OnLoad
--=========================================================
function QifuSign_OnLoad()
	g_QifuSign_Frame_UnifiedPosition = QifuSign_Frame:GetProperty("UnifiedPosition")

	-- QifuSign_OK_Button : SetEvent("Clicked", "QifuSign_ConfirmClick()")

	g_controlWeekRewardButton1[1] 	= QifuSign_LastWeekItem1
	g_controlWeekRewardButton1[2] 	= QifuSign_LastWeekItem2
	g_controlWeekRewardButton1[3] 	= QifuSign_LastWeekItem3
	g_controlWeekRewardButton1[4] 	= QifuSign_LastWeekItem4
	g_controlWeekRewardButton1[5] 	= QifuSign_LastWeekItem5
	g_controlWeekRewardButton1[6] 	= QifuSign_LastWeekItem6
	g_controlWeekRewardButton1[7] 	= QifuSign_LastWeekItem7

	g_controlWeekRewardButton2[1] 	= QifuSign_LastWeekItem11
	g_controlWeekRewardButton2[2] 	= QifuSign_LastWeekItem21
	g_controlWeekRewardButton2[3] 	= QifuSign_LastWeekItem31
	g_controlWeekRewardButton2[4] 	= QifuSign_LastWeekItem41
	g_controlWeekRewardButton2[5] 	= QifuSign_LastWeekItem51
	g_controlWeekRewardButton2[6] 	= QifuSign_LastWeekItem61
	g_controlWeekRewardButton2[7] 	= QifuSign_LastWeekItem71

	-- g_controlWeekRewardName[1] 		= QifuSign_LastWeekName1
	-- g_controlWeekRewardName[2] 		= QifuSign_LastWeekName2
	-- g_controlWeekRewardName[3] 		= QifuSign_LastWeekName3
	-- g_controlWeekRewardName[4] 		= QifuSign_LastWeekName4
	-- g_controlWeekRewardName[5] 		= QifuSign_LastWeekName5
	-- g_controlWeekRewardName[6] 		= QifuSign_LastWeekName6

	-- g_controlWeekRewardNum[1] 		= QifuSign_LastWeekNumber1
	-- g_controlWeekRewardNum[2] 		= QifuSign_LastWeekNumber2
	-- g_controlWeekRewardNum[3] 		= QifuSign_LastWeekNumber3
	-- g_controlWeekRewardNum[4] 		= QifuSign_LastWeekNumber4
	-- g_controlWeekRewardNum[5] 		= QifuSign_LastWeekNumber5
	-- g_controlWeekRewardNum[6] 		= QifuSign_LastWeekNumber6

	-- g_controlNeedHideWhenBufShow[1]	= QifuSign_LastWeekNumber2
	-- g_controlNeedHideWhenBufShow[2]	= QifuSign_LastWeekNumber3
	-- g_controlNeedHideWhenBufShow[3]	= QifuSign_LastWeekNumber4
	-- g_controlNeedHideWhenBufShow[4]	= QifuSign_LastWeekNumber5
	-- g_controlNeedHideWhenBufShow[5]	= QifuSign_TodayBuff_Get
	-- g_controlNeedHideWhenBufShow[6]	= QifuSign_TodayBuff_Refresh
	-- g_controlNeedHideWhenBufShow[7]	= QifuSign_LastWeekName2
	-- g_controlNeedHideWhenBufShow[8]	= QifuSign_LastWeekName3
	-- g_controlNeedHideWhenBufShow[9]	= QifuSign_LastWeekName4
	-- g_controlNeedHideWhenBufShow[10]= QifuSign_LastWeekName5

	g_controlWeekRewardDisable1[1] 	= QifuSign_LastWeekItem1_Mask
	g_controlWeekRewardDisable1[2] 	= QifuSign_LastWeekItem2_Mask
	g_controlWeekRewardDisable1[3] 	= QifuSign_LastWeekItem3_Mask
	g_controlWeekRewardDisable1[4] 	= QifuSign_LastWeekItem4_Mask
	g_controlWeekRewardDisable1[5] 	= QifuSign_LastWeekItem5_Mask
	g_controlWeekRewardDisable1[6] 	= QifuSign_LastWeekItem6_Mask
	g_controlWeekRewardDisable1[7] 	= QifuSign_LastWeekItem7_Mask

	g_controlWeekRewardDisable2[1] 	= QifuSign_LastWeekItem11_Mask
	g_controlWeekRewardDisable2[2] 	= QifuSign_LastWeekItem21_Mask
	g_controlWeekRewardDisable2[3] 	= QifuSign_LastWeekItem31_Mask
	g_controlWeekRewardDisable2[4] 	= QifuSign_LastWeekItem41_Mask
	g_controlWeekRewardDisable2[5] 	= QifuSign_LastWeekItem51_Mask
	g_controlWeekRewardDisable2[6] 	= QifuSign_LastWeekItem61_Mask
	g_controlWeekRewardDisable2[7] 	= QifuSign_LastWeekItem71_Mask

	g_controlWeekRewardAnimate1[1] 	= QifuSign_LastWeekItem1_Animate
	g_controlWeekRewardAnimate1[2] 	= QifuSign_LastWeekItem2_Animate
	g_controlWeekRewardAnimate1[3] 	= QifuSign_LastWeekItem3_Animate
	g_controlWeekRewardAnimate1[4] 	= QifuSign_LastWeekItem4_Animate
	g_controlWeekRewardAnimate1[5] 	= QifuSign_LastWeekItem5_Animate
	g_controlWeekRewardAnimate1[6] 	= QifuSign_LastWeekItem6_Animate
	g_controlWeekRewardAnimate1[7] 	= QifuSign_LastWeekItem7_Animate

	g_controlWeekRewardAnimate2[1] 	= QifuSign_LastWeekItem11_Animate
	g_controlWeekRewardAnimate2[2] 	= QifuSign_LastWeekItem21_Animate
	g_controlWeekRewardAnimate2[3] 	= QifuSign_LastWeekItem31_Animate
	g_controlWeekRewardAnimate2[4] 	= QifuSign_LastWeekItem41_Animate
	g_controlWeekRewardAnimate2[5] 	= QifuSign_LastWeekItem51_Animate
	g_controlWeekRewardAnimate2[6] 	= QifuSign_LastWeekItem61_Animate
	g_controlWeekRewardAnimate2[7] 	= QifuSign_LastWeekItem71_Animate

	g_controlAllBufPic[1] 			= QifuSign_Buff1
	g_controlAllBufPic[2] 			= QifuSign_Buff2
	g_controlAllBufPic[3] 			= QifuSign_Buff3
	g_controlAllBufPic[4] 			= QifuSign_Buff4
	g_controlAllBufPic[5] 			= QifuSign_Buff5
	g_controlAllBufPic[6] 			= QifuSign_Buff6
	g_controlAllBufPic[7] 			= QifuSign_Buff7
	g_controlAllBufPic[8] 			= QifuSign_Buff8
	-- g_controlAllBufPic[9] 			= QifuSign_Buff9
	-- g_controlAllBufPic[10] 			= QifuSign_Buff10

	g_controlAllBufName[1] 			= QifuSign_Buff1_Name
	g_controlAllBufName[2] 			= QifuSign_Buff2_Name
	g_controlAllBufName[3] 			= QifuSign_Buff3_Name
	g_controlAllBufName[4] 			= QifuSign_Buff4_Name
	g_controlAllBufName[5] 			= QifuSign_Buff5_Name
	g_controlAllBufName[6] 			= QifuSign_Buff6_Name
	g_controlAllBufName[7] 			= QifuSign_Buff7_Name
	g_controlAllBufName[8] 			= QifuSign_Buff8_Name
	-- g_controlAllBufName[9] 			= QifuSign_Buff9_Name
	-- g_controlAllBufName[10] 		= QifuSign_Buff10_Name

	g_controlAllBufAnimate[1] 		= QifuSign_Buff1_Animate
	g_controlAllBufAnimate[2] 		= QifuSign_Buff2_Animate
	g_controlAllBufAnimate[3] 		= QifuSign_Buff3_Animate
	g_controlAllBufAnimate[4] 		= QifuSign_Buff4_Animate
	g_controlAllBufAnimate[5] 		= QifuSign_Buff5_Animate
	g_controlAllBufAnimate[6] 		= QifuSign_Buff6_Animate
	g_controlAllBufAnimate[7] 		= QifuSign_Buff7_Animate
	g_controlAllBufAnimate[8] 		= QifuSign_Buff8_Animate
	-- g_controlAllBufAnimate[9] 		= QifuSign_Buff9_Animate
	-- g_controlAllBufAnimate[10] 		= QifuSign_Buff10_Animate

end

--=========================================================
-- OnEvent
--=========================================================
function QifuSign_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- PushDebugMessage("UI_COMMAND nOpType"..nOpType)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				QifuSign_OnClosed()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- PushDebugMessage("打开界面")
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						QifuSign_OnClosed()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_QifuSign()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	QifuSign_OnClosed()
			-- end
			QifuSign_Reset()
			QifuSign_Frame_On_ResetPos()
			this:Show()
			QifuSign_ParamInit()
			QifuSign_MoneyUpdate()
			QifuSign_YuanBaoUpdate()
			QifuSign_Update(1)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						QifuSign_OnClosed()
					end
				end
			end
			if this:IsVisible() then
				QifuSign_ParamInit()
				QifuSign_Update(0)

				-- 关掉二次确认框
				PushEvent( "MESSAGE_BOX_SELF3_CLOSE" )
			end
		end

		-- 二次确认框
		if 3 == nOpType then
			local strMsg = Get_XParam_STR(0)
			g_nComfirmParam1 = Get_XParam_INT(1)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("QifuSign_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
		end

		-- 服务器要求客户端激活鼠标选人状态 
		if 4 == nOpType then
			-- PushDebugMessage("服务器要求客户端激活鼠标选人状态")
			MouseEnterQiYuanGiveWine()
			-- if this:IsVisible() then
			-- 	QifuSign_OnClosed()
			-- end
		end

	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_nObjCaredIDClient) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			QifuSign_OnClosed()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			QifuSign_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		QifuSign_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		QifuSign_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		QifuSign_OnClosed()
	
	elseif (event == "ADJEST_UI_POS" ) then
		QifuSign_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		QifuSign_Frame_On_ResetPos()

	elseif (event == "QIYUAN_GIVE_WINE_SELECTED") then
		-- 鼠标选中了一个玩家
		local targetID = tonumber(arg0)
		Clear_XSCRIPT()
		-- nOpType 类型1 道具使用 类型2 界面祝福 类型3 客户端鼠标动作选中
		-- nOpType, bJustCheck, nSelectedTargetID
			Set_XSCRIPT_Function_Name( "OnZhuFuOhterPlayer" )
			Set_XSCRIPT_ScriptID(790070)
			Set_XSCRIPT_Parameter(0, 3)								
			Set_XSCRIPT_Parameter(1, 0)								
			Set_XSCRIPT_Parameter(2, targetID)								
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function QifuSign_ParamInit()
	
	g_nLastWeek 				= Get_XParam_INT(1)
	g_nActNumWeek 				= Get_XParam_INT(2)
	g_bIsGetedFlag 				= Get_XParam_INT(3)
	g_nCurWeek 					= Get_XParam_INT(4)
	g_nCurDay					= Get_XParam_INT(5)
	g_nActNumDay				= Get_XParam_INT(6)
	g_nNumOfGiveWine 			= Get_XParam_INT(7)
	g_nBufIndex 				= Get_XParam_INT(8)
	g_bGetedBuf 				= Get_XParam_INT(9)
	g_bShowHotPoint				= Get_XParam_INT(10)
	g_nWeekAnimateShowIndex		= Get_XParam_INT(11)
	g_nWeekRewardDetailInfo2	= Get_XParam_INT(12)
	g_nWeekRewardDetailInfo3	= Get_XParam_INT(13)
	g_nRefreshBufNum			= Get_XParam_INT(14)

end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function QifuSign_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		if 1 == g_nComfirmParam1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "RefreshFuYuanBuf" )
				Set_XSCRIPT_ScriptID(790070)							
				Set_XSCRIPT_Parameter(0, 1)	
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end

		if 2 == g_nComfirmParam1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnGetFuYuanBuf" )
				Set_XSCRIPT_ScriptID(790070)
				Set_XSCRIPT_Parameter(0, 1)								
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end
		
	end

	if "No" == strRet then
		
	end
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =QifuSign
function QifuSign_Update(bOpen)

	-- 祈愿按钮的显隐
	QifuSign_Today_Sign_Animate : Hide()
	QifuSign_Today_ReSign_Animate : Hide()

	if g_nActNumDay <= 0 then
		QifuSign_Today_Sign : Show()
		QifuSign_Today_ReSign : Hide()
	else
		QifuSign_Today_Sign : Hide()
		QifuSign_Today_ReSign : Show()
	end

	-- 祈愿按钮的Tips
	if g_nActNumDay >= 2 then
		QifuSign_Today_Sign : SetToolTip("#{MRQD_210708_05}")
		QifuSign_Today_ReSign : SetToolTip("#{MRQD_210708_05}")
	elseif g_nActNumDay <= 0 then
		QifuSign_Today_Sign : SetToolTip("#{MRQD_210708_04}")
		QifuSign_Today_ReSign : SetToolTip("#{MRQD_210708_04}")
	else
		QifuSign_Today_Sign : SetToolTip("#{MRQD_210708_55}")
		QifuSign_Today_ReSign : SetToolTip("#{MRQD_210708_55}")
	end

	-- 祈愿按钮的红点逻辑
	if 1 == g_bShowHotPoint then
		QifuSign_Today_SignTips : Show()
	else
		QifuSign_Today_SignTips : Hide()
	end

	-- 祈福次数显示
	-- QifuSign_Today_Signtime : SetText(ScriptGlobal_Format("#{MRQD_210708_06}", g_nActNumDay))

	local tabItemID 	= {}
	local tabItemNum 	= {}

	-- 上周奖励显全部蒙红 全部动画都不显示 道具全部清空 绑定元宝全部显示
	for i = 1, 7 do
		g_controlWeekRewardButton1[i] : SetActionItem(-1)
		local theAction = DataPool:CreateBindActionItemForShow(g_nBindYuanBaoShowItemID, g_nBindYuanBaoNumPerAct)
		g_controlWeekRewardButton2[i] : SetActionItem(theAction:GetID())

		g_controlWeekRewardDisable1[i] : Show()
		g_controlWeekRewardDisable2[i] : Show()

		g_controlWeekRewardAnimate1[i] : Hide()
		g_controlWeekRewardAnimate2[i] : Hide()
	end

	-- 有上周奖励或者本周奖励 则奖励存储有效
	if g_nLastWeek + 1 == g_nCurWeek or g_nLastWeek == g_nCurWeek then
		-- 对应填入逻辑
		-- for i = 1, 7 do
		-- 	-- 道具
		-- 	local nItemIndex = QifuSign_GetWeekRewardItemIndex(i, g_nWeekRewardDetailInfo2, g_nWeekRewardDetailInfo3)
		-- 	local bActBindYB = QifuSign_GetWeekRewardBindYB(i, g_nWeekRewardDetailInfo2, g_nWeekRewardDetailInfo3)
		-- 	if nItemIndex > 0 and nItemIndex <= table.getn(g_tabWeekRewardItemInfo) then
		-- 		local subTableItem = g_tabWeekRewardItemInfo[nItemIndex]
		-- 		local theAction = DataPool:CreateBindActionItemForShow(subTableItem.nItemID, subTableItem.nItemNum)
		-- 		g_controlWeekRewardButton1[i] : SetActionItem(theAction:GetID())
		-- 		g_controlWeekRewardDisable1[i] : Hide()
		-- 	end
		-- 	-- 元宝
		-- 	if 1 == bActBindYB then
		-- 		g_controlWeekRewardDisable2[i] : Hide()
		-- 	end
		-- end

		-- 依次填入逻辑
		local nShowIndex = 0
		for i = 1, 7 do
			-- 道具
			-- local nItemIndex = QifuSign_GetWeekRewardItemIndex(i, 67633664, 590339)
			-- PushDebugMessage("nItemIndex"..nItemIndex.."i"..i)
			local nItemIndex = QifuSign_GetWeekRewardItemIndex(i, g_nWeekRewardDetailInfo2, g_nWeekRewardDetailInfo3)
			if nItemIndex > 0 and nItemIndex <= table.getn(g_tabWeekRewardItemInfo) then
				local subTableItem = g_tabWeekRewardItemInfo[nItemIndex]
				local theAction = DataPool:CreateBindActionItemForShow(subTableItem.nItemID, subTableItem.nItemNum)

				nShowIndex = nShowIndex + 1
				g_controlWeekRewardButton1[nShowIndex] : SetActionItem(theAction:GetID())
				g_controlWeekRewardDisable1[nShowIndex] : Hide()
				
			end
			
			-- 元宝
			if i <= g_nActNumWeek then
				g_controlWeekRewardDisable2[i] : Hide()
			end

		end

		-- 道具 上周累计奖励动画显示
		if 1 == g_nWeekAnimateShowIndex then
			g_controlWeekRewardAnimate1[nShowIndex] : Show()
		end

		-- 元宝 上周累计奖励动画显示
		if 2 == g_nWeekAnimateShowIndex then
			g_controlWeekRewardAnimate2[g_nActNumWeek] : Show()
		end
	end

	-- 上周领取按钮
	if g_nLastWeek + 1 == g_nCurWeek and (g_nActNumWeek > 0 or g_nWeekRewardDetailInfo2 > 0 or g_nWeekRewardDetailInfo3 > 0) and 0 == g_bIsGetedFlag then
		-- 有上周可以领取的奖励
		QifuSign_LastWeekGet : SetToolTip("#{MRQD_210708_08}")
		QifuSign_LastWeekGet : Show()
		QifuSign_LastWeekGetTips : Show()
		QifuSign_LastWeekGetText : Hide()
	else
		-- 显示下周领取
		-- QifuSign_LastWeekGet : SetToolTip(ScriptGlobal_Format("#{MRQD_210708_09}", 0, 0))
		QifuSign_LastWeekGetText : SetText("#{MRQD_210713_5}")
		QifuSign_LastWeekGetText : Show()
		QifuSign_LastWeekGetTips : Hide()
		QifuSign_LastWeekGet : Hide()
	end

	-- if 1 == 1 then
	-- 	return
	-- end
	-- PushDebugMessage("debug 01")

	-- 赠酒次数
	if g_nActNumDay <= 0 then
		QifuSign_Today_Sendtime : Show()
		QifuSign_Today_Sendtime : SetText("#{MRQD_210901_1}")
	elseif g_nActNumDay >= 2 then
		QifuSign_Today_Sendtime : SetText("#{MRQD_210901_2}")
		QifuSign_Today_Sendtime : Show()
	else
		-- QifuSign_Today_Sendtime : SetProperty("Image", g_tabQiFuNumPic[g_nNumOfGiveWine + 1])
		local nNeedNum = g_nMaxNumOfGiveWine - g_nNumOfGiveWine
		if nNeedNum <= 0 then
			QifuSign_Today_Sendtime : SetText("#{MRQD_210831_3}")
			QifuSign_Today_Sendtime : SetToolTip("")
		else
			QifuSign_Today_Sendtime : SetText(ScriptGlobal_Format("#{MRQD_210713_3}", nNeedNum))
			QifuSign_Today_Sendtime : SetToolTip("#{MRQD_210831_5}")
		end

		QifuSign_Today_Sendtime : Show()
	end
	
	-- if g_nActNumDay <= 0 then
	-- 	QifuSign_InfoText : SetText("#{MRQD_210708_47}")
	-- elseif g_nActNumDay >= 2 then
	-- 	QifuSign_InfoText : SetText("#{MRQD_210713_4}")
	-- elseif g_nNumOfGiveWine == g_nSecondQiYuanBaseRate then
	-- 	QifuSign_InfoText : SetText(ScriptGlobal_Format("#{MRQD_210713_2}", g_nNumOfGiveWine))
	-- else
	-- 	QifuSign_InfoText : SetText(ScriptGlobal_Format("#{MRQD_210713_3}", g_nNumOfGiveWine))
	-- end

	-- 送出祝福按钮
	QifuSign_Item_Pick : SetToolTip("#{MRQD_210708_11}")

	-- 当前奖励信息
	if g_nActNumDay <= 0 then
		-- 首次祈福前
		QifuSign_TodayItem : SetToolTip("#{MRQD_210708_56}")
		-- QifuSign_TodayItem_Animate  : Hide()
	elseif 1 == g_nActNumDay then
		if g_nNumOfGiveWine < g_nMaxNumOfGiveWine then
			-- 二次祈福前 概率不到100
			QifuSign_TodayItem : SetToolTip("#{MRQD_210708_57}")
			-- QifuSign_TodayItem_Animate  : Hide()
		else
			-- -- 二次祈福前 满概率
			-- QifuSign_TodayItem : SetToolTip("#{MRQD_210708_58}")
			-- QifuSign_TodayItem_Animate  : Show()
		end	
	else
		-- 祈福完了
		QifuSign_TodayItem : SetToolTip("")
		-- QifuSign_TodayItem_Animate : Hide()
	end

	-- 葫芦图片的显示规则 
	if g_nActNumDay <= 0 then
		QifuSign_TodayItem : SetProperty("Image", g_strPicTodayItemCommon)
	else
		QifuSign_TodayItem : SetProperty("Image", g_strPicTodayItemAdvance)
	end

	-- PushDebugMessage("debug 02")

	-- 当天buf
	QifuSign_TodayBuff_Animate : Hide()

	if g_nBufIndex > 0 and g_nBufIndex <= table.getn(g_tabBufInfo) then
		local subItem = g_tabBufInfo[g_nBufIndex]
		if nil ~= subItem then
			local strBufPic = subItem.strBufPic
			QifuSign_TodayBuff : SetProperty("Image", strBufPic)

			local strBufTips = subItem.strBufTips
			QifuSign_TodayBuff : SetToolTip(strBufTips)
		end
	end
	
	-- 所有buf展示
	for i = 1, table.getn(g_tabBufInfo) do
		local subItem = g_tabBufInfo[i]
		local strBufPic = subItem.strBufPic
		local strBufTips = subItem.strBufTips
		local strBufName = subItem.strBufName

		g_controlAllBufPic[i] : SetProperty("Image", strBufPic)
		g_controlAllBufPic[i] : SetToolTip(strBufTips)
		g_controlAllBufName[i] : SetText(ScriptGlobal_Format("#{MRQD_210902_1}", strBufName))
		g_controlAllBufAnimate[i] : Hide()
	end

	-- PushDebugMessage("debug 03")

	-- 按钮tips
	QifuSign_TodayBuff_Get 		: SetToolTip("#{MRQD_210708_86}")
	QifuSign_TodayBuff_Refresh 	: SetToolTip("#{MRQD_210708_85}")

	-- 刷新消耗文本
	local subTableItem = g_tabRefreshBufInfo[g_nRefreshBufNum + 1]
	if nil ~= subTableItem then
		local nCostMoney = g_tabRefreshBufInfo[g_nRefreshBufNum + 1].nCostMoney
		QifuSign_TodayBuff_RefreshText : SetText(ScriptGlobal_Format("#{MRQD_210831_7}", nCostMoney))
	end
	
	-- PushDebugMessage("debug 04")

	-- 整个buf区的显隐
	QifuSign_TodayBuffBK : Hide()
	if g_nActNumDay > 0 then
		QifuSign_TodayBuffBK : Show()
	end

	-- buf区红点
	QifuSign_TodayBuff_Tips : Hide()
	if g_nActNumDay > 0 and g_bGetedBuf <= 0 then
		QifuSign_TodayBuff_Tips : Show()
	end

	-- 是否领取buf导致的某些控件的显隐逻辑
	if g_bGetedBuf <= 0 then
		QifuSign_TodayBuff_Get 					: Show()
		QifuSign_TodayBuff_RefreshText 			: Show()
		QifuSign_TodayBuff_Refresh 				: Show()
		QifuSign_TodayBuff_Refresh_JiaoZiIcon 	: Show()
		QifuSign_TodayBuff_RefreshText2			: Hide()
		QifuSign_TodayBuff_GetImage 			: Hide()

		-- 不消耗金钱的第一次特殊显示一下。。。。。
		if  0 == g_nRefreshBufNum then
			QifuSign_TodayBuff_Refresh_JiaoZiIcon 	: Hide()
			QifuSign_TodayBuff_RefreshText 			: Hide()
			QifuSign_TodayBuff_RefreshText2			: Show()
		end
	else
		QifuSign_TodayBuff_Get 					: Hide()
		QifuSign_TodayBuff_RefreshText 			: Hide()
		QifuSign_TodayBuff_Refresh 				: Hide()
		QifuSign_TodayBuff_Refresh_JiaoZiIcon 	: Hide()
		QifuSign_TodayBuff_RefreshText2			: Hide()
		QifuSign_TodayBuff_GetImage 			: Show()
	end

	-- 成功烟花特效显示
	if g_nWeekAnimateShowIndex > 0  then
		QifuSign_TodayItem_Animate : Show()
		QifuSign_Today_Animate1 : Play(true)
		QifuSign_Today_Animate2 : Play(true)
		QifuSign_Today_Animate3 : Play(true)
		QifuSign_Today_Animate4 : Play(true)
	else
		QifuSign_TodayItem_Animate : Hide()
		QifuSign_Today_Animate1 : Play(false)
		QifuSign_Today_Animate2 : Play(false)
		QifuSign_Today_Animate3 : Play(false)
		QifuSign_Today_Animate4 : Play(false)
	end

	-- PushDebugMessage("debug 05")
end

--**********************************
-- 内部函数 获得展示顺序的第x个index的物品的信息
--**********************************
-- function QifuSign_GetShowOrGiveItemInfobyIndex(nIndex, nSaveInt01)

-- 	-- PushDebugMessage("QifuSign_GetShowOrGiveItemInfobyIndex"..",nIndex:"..nIndex..",nSaveInt01:"..nSaveInt01)

-- 	if nIndex <= 0 or nIndex > table.getn(g_tabWeekRewardShwoOrGiveInfo) then
-- 		return 0, 0
-- 	end

-- 	local nRetItemID 	= g_tabWeekRewardShwoOrGiveInfo[nIndex].nItemID
-- 	local nRetItemNum 	= 0

-- 	for i = 1, table.getn(g_tabWeekRewardItemInfo) do
-- 		local subItem = g_tabWeekRewardItemInfo[i]
-- 		if subItem.nItemID == nRetItemID then
-- 			nRetItemNum = nRetItemNum + subItem.nItemNum * math.mod( math.floor(nSaveInt01 / math.pow(10, i - 1)), 10)
-- 		end
-- 	end

-- 	return nRetItemID, nRetItemNum
	
-- end

--**********************************
-- 内部函数 获得周奖励的每天的绑定元宝奖励是否激活
--**********************************
function QifuSign_GetWeekRewardBindYB(nWeekDay, nSaveInt01, nSaveInt02)
	if nWeekDay < 1 or nWeekDay > 7 then
		return 0
	end

	return math.mod( math.floor(nSaveInt01 / math.pow(2, nWeekDay - 1)), 2)
end

--**********************************
-- 内部函数 获得周奖励的每天的奖励道具
--**********************************
function QifuSign_GetWeekRewardItemIndex(nWeekDay, nSaveInt01, nSaveInt02)
	if nWeekDay < 1 or nWeekDay > 7 then
		return 0
	end

	if nWeekDay <= 3 then
		return math.mod( math.floor(nSaveInt01 / math.pow(256, nWeekDay)), 256)
	else
		return math.mod( math.floor(nSaveInt02 / math.pow(256, nWeekDay - 4)), 256)
	end
end

--=========================================================
-- 重置界面
--=========================================================
function QifuSign_Reset()
	g_nLastWeek 				= -1
	g_nActNumWeek 				= -1
	g_bIsGetedFlag 				= -1
	g_nCurWeek 					= -1
	g_nCurDay					= -1

	g_nActNumDay				= -1
	g_nNumOfGiveWine 			= -1
	g_nBufIndex 				= -1
	g_bGetedBuf 				= -1
	g_bShowHotPoint				= -1

	g_nWeekAnimateShowIndex		= -1	
	g_nWeekRewardDetailInfo2	= -1	
	g_nWeekRewardDetailInfo3	= -1	
	g_nRefreshBufNum			= -1	

	QifuSign_OnCloseAllFuYuanBuf()

	-- 关掉二次确认框
	PushEvent( "MESSAGE_BOX_SELF3_CLOSE" )
end

--=========================================================
-- 领取福源buf
--=========================================================
function QifuSign_OnGetFuYuanBuf()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetFuYuanBuf" )
		Set_XSCRIPT_ScriptID(790070)							
		Set_XSCRIPT_Parameter(0, 0)								
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=========================================================
-- 刷新福源buf
--=========================================================
function QifuSign_RefreshFuYuanBuf()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RefreshFuYuanBuf" )
		Set_XSCRIPT_ScriptID(790070)							
		Set_XSCRIPT_Parameter(0, 0)	
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=========================================================
-- 展示所有福源buf
--=========================================================
function QifuSign_OnShowAllFuYuanBuf()
	-- PushDebugMessage("QifuSign_OnShowAllFuYuanBuf")
	-- QifuSign_BuffAllBK : SetProperty("UnifiedPosition","{{1.000000,-500.000000},{0.000000,160.000000}}")

	QifuSign_BuffAll : Show()

	-- for i = 1, table.getn(g_controlNeedHideWhenBufShow) do
	-- 	g_controlNeedHideWhenBufShow[i] : Hide()
	-- end
end

--=========================================================
-- 关闭展示所有福源buf
--=========================================================
function QifuSign_OnCloseAllFuYuanBuf()
	-- QifuSign_BuffAllBK : SetProperty("UnifiedPosition","{{1.000000,0.000000},{0.000000,160.000000}}")

	QifuSign_BuffAll : Hide()

	-- for i = 1, table.getn(g_controlNeedHideWhenBufShow) do
	-- 	g_controlNeedHideWhenBufShow[i] : Show()
	-- end
end

--=========================================================
-- 领取上周奖励
--=========================================================
function QifuSign_GetLastWeekReward()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetWeekReward" )
		Set_XSCRIPT_ScriptID(790070)							
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--=========================================================
-- 祝福其他玩家
--=========================================================
function QifuSign_OnZhuFuOtherPlayer()
	Clear_XSCRIPT()
		-- nOpType 类型1 道具使用 类型2 界面祝福 类型3 客户端鼠标动作选中
		-- nOpType, bJustCheck, nSelectedTargetID
		Set_XSCRIPT_Function_Name( "OnZhuFuOhterPlayer" )
		Set_XSCRIPT_ScriptID(790070)
		Set_XSCRIPT_Parameter(0, 2)								
		Set_XSCRIPT_Parameter(1, 0)								
		Set_XSCRIPT_Parameter(2, -1)								
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--=========================================================
-- 祈愿
--=========================================================
function QifuSign_OnQiYuan()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnQiYuan" )
		Set_XSCRIPT_ScriptID(790070)
		Set_XSCRIPT_Parameter(0, 0)								
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=========================================================
-- 帮助
--=========================================================
function QifuSign_OnHelp()
	-- 借用一下别人的通道， 祈愿 新活跃 
    PushEvent("CCSHOP_HELP", 70)
end

--=========================================================
-- 关闭界面
--=========================================================
function QifuSign_OnClosed()	
	this:Hide()
	StopCareObject_QifuSign()
	-- 重置
	QifuSign_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="QifuSign_OnHiden();" />
--=========================================================
function QifuSign_OnHiden()
	StopCareObject_QifuSign()
	-- 重置
	QifuSign_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_QifuSign()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "QifuSign")
end

function StopCareObject_QifuSign()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "QifuSign")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function QifuSign_MoneyUpdate()
	-- QifuSign_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- QifuSign_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function QifuSign_YuanBaoUpdate()
	-- QifuSign_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function QifuSign_Frame_On_ResetPos()
	QifuSign_Frame:SetProperty("UnifiedPosition", g_QifuSign_Frame_UnifiedPosition)
end